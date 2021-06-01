--Global voice chat related functions and data
function ZO_VoiceChat_GetChannelDataFromName(channelName)
    local channelType, primaryId, guildRoomNumber = VoiceChatGetChannelInfo(channelName)
    local guildId
    if channelType == VOICE_CHANNEL_GUILD then
        guildId = primaryId
    end

    local channelData =
    {
        channelType = channelType,
        guildId = guildId, --this value is invalid when retrieved for a guild channel that is no longer available
        guildRoomNumber = guildRoomNumber
    }

    return channelData
end

function ZO_VoiceChat_IsNameLocalPlayers(displayName)
    return displayName == GetDisplayName()
end

VOICE_CHAT_OFFICERS_ROOM_NUMBER = 0 --The guild channel # we use to represent the special Officer's channel.

VOICE_CHAT_ICON_MUTED_PLAYER = "EsoUI/Art/VOIP/Gamepad/gp_VOIP_muted.dds"
VOICE_CHAT_ICON_LISTENING_CHANNEL = "EsoUI/Art/VOIP/Gamepad/gp_VOIP_listening.dds"

--------------------------------------------------------------------------------
-- VoiceChat History Data
--      Helper class for saving and sorting the speaker history of each channel.
--------------------------------------------------------------------------------

local HISTORY_ENTRY_LIMIT = 15


local HistoryData = ZO_InitializingObject:Subclass()

function HistoryData:Initialize()
    self.list = {} --entries toward the end of the list are considered newer
    self.displayNameToEntry = {}
end

function HistoryData:UpdateUser(displayName)
    local newEntry =
    {
        displayName = displayName,
        lastTimeSpoken = GetFrameTimeMilliseconds(),
        isMuted = false,
    }

    if self.displayNameToEntry[displayName] then
        self:RemoveUser(displayName)
    end
    
    table.insert(self.list, newEntry)

    --Maintain max size
    if #self.list > HISTORY_ENTRY_LIMIT then
        local data = self.list[1]
        self.displayNameToEntry[data.displayName] = nil
        table.remove(self.list, 1)
    end

    self.displayNameToEntry[displayName] = newEntry
end

function HistoryData:UpdateMutedUsers(mutedUsers)
    for i, speakerData in ipairs(self.list) do
        speakerData.isMuted = mutedUsers[speakerData.displayName]
    end
end

function HistoryData:RemoveUser(displayName)
    for i, speakerData in ipairs(self.list) do
        if speakerData.displayName == displayName then
            table.remove(self.list, i)
            break
        end
    end

    self.displayNameToEntry[displayName] = nil
end

--------------------------------------------------------------------------------
-- VoiceChat Participants Data
--      Helper class for saving and sorting the participants of each channel.
--------------------------------------------------------------------------------

local SORT_KEYS =
{
    displayName = {}
}
local SORT_BY_OCCURRENCE = true
local DONT_SORT_BY_OCCURRENCE = false

local function SortParticipantEntries(entry1, entry2)
    return ZO_TableOrderingFunction(entry1, entry2, "displayName", SORT_KEYS, ZO_SORT_ORDER_UP)
end

local ParticipantsData = ZO_InitializingObject:Subclass()

function ParticipantsData:Initialize(sortByOccurrence)
    self.list = {}
    self.displayNameToEntry = {}
    self.sortByOccurrence = sortByOccurrence --when true, newer entries occur first in the list
end

function ParticipantsData:AddOrUpdateParticipant(displayName, speakStatus, isMuted)
    if self.displayNameToEntry[displayName] then
        self:UpdateParticipantStatus(displayName, speakStatus, isMuted)
        return
    end

    local newEntry =
    {
        displayName = displayName,
        speakStatus = speakStatus,
        isMuted = isMuted,
    }

    table.insert(self.list, 1, newEntry)
    self.displayNameToEntry[displayName] = newEntry

    if not self.sortByOccurrence then
        table.sort(self.list, SortParticipantEntries)
    end
end

function ParticipantsData:RemoveParticipant(displayName)
    local foundIndex = self:GetParticipantIndex(displayName)
    if foundIndex then
        table.remove(self.list, foundIndex)
        self.displayNameToEntry[displayName] = nil
    end
end

function ParticipantsData:GetParticipant(displayName)
    return self.displayNameToEntry[displayName]
end

function ParticipantsData:GetParticipantIndex(displayName)
    for i, speakerData in ipairs(self.list) do
        if speakerData.displayName == displayName then
            return i
        end
    end

    return nil
end

function ParticipantsData:UpdateParticipantStatus(displayName, speakStatus, isMuted)
    local index = self:GetParticipantIndex(displayName)

    if index then
        local speakerData = self.list[index]
        if speakStatus then
            speakerData.speakStatus = speakStatus

            if speakStatus == VOICE_CHAT_SPEAK_STATE_SPEAKING then
                speakerData.lastTimeSpoken = GetFrameTimeMilliseconds()
            end
        end

        --Only update the mute status if an argument was provided
        if isMuted ~= nil then
            speakerData.isMuted = isMuted
        end
    
        if self.sortByOccurrence then
            if speakStatus == VOICE_CHAT_SPEAK_STATE_SPEAKING then
                --Move the user to the end of the list
                table.remove(self.list, index)
                table.insert(self.list, 1, speakerData)
            end
        end
    end
end

function ParticipantsData:UpdateMutedUsers(mutedUsers)
    for i, speakerData in ipairs(self.list) do
        speakerData.isMuted = mutedUsers[speakerData.displayName]
    end
end

function ParticipantsData:ClearParticipants()
    self.list = {}
    self.displayNameToEntry = {}
end

--------------------------------------------------------------------------------
-- Voice Chat Manager
--------------------------------------------------------------------------------

ZO_VoiceChat_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_VoiceChat_Manager:Initialize()
    self.channelData =
    {
        [VOICE_CHANNEL_AREA] =
        {
            channelType = VOICE_CHANNEL_AREA,
            guildId = 0,
            guildRoomNumber = 0,
            name = GetString(SI_GAMEPAD_VOICECHAT_CHANNEL_AREA),
            description = GetString(SI_GAMEPAD_VOICECHAT_CHANNEL_DESCRIPTION_AREA),
            historyData = HistoryData:New(),
            hasBadReputation = DoesLocalPlayerHaveBadReputation(),
        },
        [VOICE_CHANNEL_GROUP] =
        {
            channelType = VOICE_CHANNEL_GROUP,
            guildId = 0,
            guildRoomNumber = 0,
            name = GetString(SI_GAMEPAD_VOICECHAT_CHANNEL_GROUP),
            description = GetString(SI_GAMEPAD_VOICECHAT_CHANNEL_DESCRIPTION_GROUP),
            historyData = HistoryData:New(),
        },
        [VOICE_CHANNEL_GUILD] = {}, --populates during channel retrieval
        [VOICE_CHANNEL_BATTLEGROUP] =
        {
            channelType = VOICE_CHANNEL_BATTLEGROUP,
            guildId = 0,
            guildRoomNumber = 0,
            name = GetString(SI_GAMEPAD_VOICECHAT_CHANNEL_GROUP),
            description = GetString(SI_GAMEPAD_VOICECHAT_CHANNEL_DESCRIPTION_GROUP),
            historyData = HistoryData:New(),
        },
    }

    --The guild ids are dirtied and will need to be refreshed for all guild channels whenever a guild is joined or left.
    self.guildIdsDirty = false

    --The guild ids we can retrieve from engine are invalid for channels that just became unavailable. We'll need to keep
    --a local cache so we can id guilds for certain channel events.
    self.guildChannelsToIds = {}

    self.participantsData =
    {
        [VOICE_CHANNEL_AREA] = ParticipantsData:New(SORT_BY_OCCURRENCE),
        [VOICE_CHANNEL_GROUP] = ParticipantsData:New(DONT_SORT_BY_OCCURRENCE),
        [VOICE_CHANNEL_GUILD] = {}, --populates during channel retrieval
        [VOICE_CHANNEL_BATTLEGROUP] = ParticipantsData:New(DONT_SORT_BY_OCCURRENCE),
    }

    self.mutedUsers = {}
    self:UpdateMutedUsers()

    self.activeChannel = nil --a channel we're joined to and transmitting on
    self.desiredActiveChannel = nil

    self:RegisterForEvents()
end

function ZO_VoiceChat_Manager:RegisterForEvents()
    local function RetrieveParticipants(channel)
        self:GetParticipantData(channel):ClearParticipants()
        if channel.channelName ~= nil then
            if channel.channelName ~= "" then
                VoiceChatRequestChannelUsers(channel.channelName)
            end
        end
    end

    local function TryClearActiveChannel(channel)
        if self.activeChannel == channel then
            self.activeChannel = nil
        end
    end

    --Event Handlers
    local function OnAddOnLoaded(event, name)
        if name == "ZO_Ingame" then
            EVENT_MANAGER:UnregisterForEvent("ZO_VoiceChat_OnAddOnLoaded", EVENT_ADD_ON_LOADED)

            --We wait to request the list of channels until after we've loaded settings
            VoiceChatGetChannels()
        end
    end

    local function OnGuildDataLoaded()
        self:RefreshGuildChannelIds()
    end

    --Voice Channel Event Handlers
    local function OnVoiceChannelJoined(event, channelName)
        local channelData = ZO_VoiceChat_GetChannelDataFromName(channelName)
        if not self:DoesChannelExist(channelData) then
            return
        end

        local channel = self:GetChannel(channelData)
        channel.isJoined = true
        local transmitChannelType = VoiceChatGetTransmitChannelType()

        if transmitChannelType ~= VOICE_CHANNEL_NONE then
            if channelData.channelType == transmitChannelType then
                self.activeChannel = channel
                self.desiredActiveChannel = channel
            end
            RetrieveParticipants(channel)
        end

        self:FireCallbacks("ChannelsUpdate")
    end

    local function OnVoiceChannelLeft(event, channelName)
        local channelData = ZO_VoiceChat_GetChannelDataFromName(channelName)

        --The guild id in the channel data is invalid for this event, so use the cache
        if channelData.channelType == VOICE_CHANNEL_GUILD then
            channelData.guildId = self.guildChannelsToIds[channelName]

            if not channelData.guildId then
                return
            end
        end

        local channel = self:GetChannel(channelData)
        channel.isJoined = false
        channel.isTransmitting = false

        TryClearActiveChannel(channel)

        self:FireCallbacks("ChannelsUpdate")
        self:FireCallbacks("ParticipantsUpdate")
    end

    local function OnVoiceChannelAvailable(event, channelName, isMuted, isJoined, isTransmitting)
        local channelData = ZO_VoiceChat_GetChannelDataFromName(channelName)
        local channelType = channelData.channelType

        --Ignore invalid channels. Probably not necessary anymore, but it was a quick fix to an
        --early problem where the engine could send us invalid availability events.
        if channelType == VOICE_CHANNEL_NONE then
            return
        elseif channelType == VOICE_CHANNEL_BATTLEGROUP then
            local currentGroupChannel = self.channelData[VOICE_CHANNEL_GROUP]
            if currentGroupChannel.isAvailable then
                TryClearActiveChannel(currentGroupChannel)
            end

            self:SetDesiredActiveChannel(self:GetChannel(channelData))
        elseif channelType == VOICE_CHANNEL_GUILD then
            self:AddGuildChannelRoom(channelName, channelData)

            self.guildIdsDirty = true
        end

        local channel = self:GetChannel(channelData)
        channel.channelName = channelName
        channel.isAvailable = true
        channel.isJoined = isJoined
        channel.isTransmitting = isTransmitting

        if isJoined then
            if isTransmitting then
                self.activeChannel = channel
                self:SetDesiredActiveChannel(channel)
            end

            RetrieveParticipants(channel)
        end

        self:FireCallbacks("ChannelsUpdate")
    end

    local function OnVoiceChannelUnavailable(event, channelName)
        local channelData = ZO_VoiceChat_GetChannelDataFromName(channelName)

        --The guild id in the channel data is invalid for this event, so use the cache
        if channelData.channelType == VOICE_CHANNEL_GUILD then
            channelData.guildId = self.guildChannelsToIds[channelName]

            if not channelData.guildId then
                return
            end
        end

        local channel = self:GetChannel(channelData)
        channel.isAvailable = false
        channel.isJoined = false
        channel.isTransmitting = false

        TryClearActiveChannel(channel)

        if channel.channelType == VOICE_CHANNEL_GUILD then
            self:RemoveGuildChannelRoom(channel.channelName, channel.guildId, channel.guildRoomNumber)
            self.guildIdsDirty = true
        end

        self:FireCallbacks("ChannelsUpdate")
    end

    local function OnVoiceTransmitChannelChanged(event, channelName)
        local channelData = ZO_VoiceChat_GetChannelDataFromName(channelName)
        if not self:DoesChannelExist(channelData) then
            return
        end

        local channel = self:GetChannel(channelData)
        channel.isTransmitting = true

        self.activeChannel = channel
        self.desiredActiveChannel = channel
        self.activeChannel.isTransmitting = true

        self:FireCallbacks("ChannelsUpdate")
    end

    --Voice Participant Event Handlers
    local function OnVoiceUserJoinedChannel(event, channelName, displayName, characterName, isSpeaking)
        local channelData = ZO_VoiceChat_GetChannelDataFromName(channelName)
        if not self:DoesChannelExist(channelData) then
            return
        end

        local channel = self:GetChannel(channelData)
        local speakStatus = isSpeaking and VOICE_CHAT_SPEAK_STATE_SPEAKING or VOICE_CHAT_SPEAK_STATE_IDLE
        local isMuted = self.mutedUsers[displayName]
        self:GetParticipantData(channel):AddOrUpdateParticipant(displayName, speakStatus, isMuted)

        self:FireCallbacks("ParticipantsUpdate")
    end

    local function OnVoiceUserLeftChannel(event, channelName, displayName)
        local channelData = ZO_VoiceChat_GetChannelDataFromName(channelName)
        
        --The guild id in the channel data is invalid for this event, so use the cache
        if channelData.channelType == VOICE_CHANNEL_GUILD then
            channelData.guildId = self.guildChannelsToIds[channelName]

            if not channelData.guildId then
                return
            end
        end

        local channel = self:GetChannel(channelData)
        self:GetParticipantData(channel):RemoveParticipant(displayName)

        self:FireCallbacks("ParticipantsUpdate")
    end

    local function OnVoiceUserSpeaking(event, channelName, displayName, characterName, speaking)
        local channelData = ZO_VoiceChat_GetChannelDataFromName(channelName)

        --Speak events can occur before the channels are mapped
        if not self:DoesChannelExist(channelData) then
            return
        end

        local channel = self:GetChannel(channelData)

        local speakStatus = speaking and VOICE_CHAT_SPEAK_STATE_SPEAKING or VOICE_CHAT_SPEAK_STATE_IDLE
        self:GetParticipantData(channel):UpdateParticipantStatus(displayName, speakStatus, nil)

        --Update history
        if speaking and not ZO_VoiceChat_IsNameLocalPlayers(displayName) then
            channel.historyData:UpdateUser(displayName)
        end

        self:FireCallbacks("ParticipantsUpdate")
    end

    local function OnVoiceMuteListUpdated()
        self:UpdateMutedUsers()

        self:FireCallbacks("ParticipantsUpdate")
        self:FireCallbacks("MuteUpdate")
    end

    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_Manager", EVENT_ADD_ON_LOADED, OnAddOnLoaded)

    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_Manager", EVENT_GUILD_DATA_LOADED, OnGuildDataLoaded)

    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_Manager", EVENT_VOICE_CHANNEL_JOINED, OnVoiceChannelJoined)
    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_Manager", EVENT_VOICE_CHANNEL_LEFT, OnVoiceChannelLeft)
    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_Manager", EVENT_VOICE_CHANNEL_AVAILABLE, OnVoiceChannelAvailable)
    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_Manager", EVENT_VOICE_CHANNEL_UNAVAILABLE, OnVoiceChannelUnavailable)

    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_Manager", EVENT_VOICE_TRANSMIT_CHANNEL_CHANGED, OnVoiceTransmitChannelChanged)

    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_Manager", EVENT_VOICE_USER_JOINED_CHANNEL, OnVoiceUserJoinedChannel)
    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_Manager", EVENT_VOICE_USER_LEFT_CHANNEL, OnVoiceUserLeftChannel)
    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_Manager", EVENT_VOICE_USER_SPEAKING, OnVoiceUserSpeaking)
    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_Manager", EVENT_VOICE_MUTE_LIST_UPDATED, OnVoiceMuteListUpdated)

    EVENT_MANAGER:RegisterForUpdate("ZO_VoiceChat_Manager", 0, function() self:OnUpdate() end)
end

function ZO_VoiceChat_Manager:JoinChannel(channel)
    self.desiredActiveChannel = channel
    VoiceChatChannelJoin(channel.channelName)
end

function ZO_VoiceChat_Manager:TransmitChannel(channel)
    self.desiredActiveChannel = channel

    local transmitChannelType = VoiceChatGetTransmitChannelType()
    if channel ~= nil and channel.channelType == transmitChannelType then
        if channel.channelType ~= VOICE_CHANNEL_GUILD then
            -- if the channel to transmit to is the same channel type as the channel currently transmitting
            -- and it's not a guild channel, then it must be the active channel since the other channel types
            -- only have one channel associated with them
            self.activeChannel = channel
            return
        end
    end

    VoiceChatChannelTransmit(channel.channelName)
end

function ZO_VoiceChat_Manager:StopTransmitting()
    local NULL_CHANNEL_NAME = "N00000000#00000000"
    VoiceChatChannelTransmit(NULL_CHANNEL_NAME)
end

function ZO_VoiceChat_Manager:LeaveChannel(channel)
    VoiceChatChannelLeave(channel.channelName)
end

function ZO_VoiceChat_Manager:UpdateMutedUsers()
    local mutedUsers = {}

    local numMutedUsers = VoiceChatGetNumberMutedPlayers()
    for i = 1, numMutedUsers do
        local displayName = VoiceChatGetMutedPlayerDisplayName(i)
        mutedUsers[displayName] = true
    end

    --Update participant data
    for channelType, participantData in pairs(self.participantsData) do
        if channelType == VOICE_CHANNEL_GUILD then
            for _, guildData in pairs(participantData) do
                for _, roomData in pairs(guildData) do
                    roomData:UpdateMutedUsers(mutedUsers)
                end
            end
        else
            participantData:UpdateMutedUsers(mutedUsers)
        end
    end

    --Update history data
    for channelType, channelData in pairs(self.channelData) do
        if channelType == VOICE_CHANNEL_GUILD then
            for _, guildData in pairs(channelData) do
                for _, roomData in pairs(guildData.rooms) do
                    roomData.historyData:UpdateMutedUsers(mutedUsers)
                end
            end
        else
            channelData.historyData:UpdateMutedUsers(mutedUsers)
        end
    end

    self.mutedUsers = mutedUsers
end

function ZO_VoiceChat_Manager:OnUpdate()
    if self.guildIdsDirty then
        self.guildIdsDirty = false
        self:RefreshGuildChannelIds()
    end
end

function ZO_VoiceChat_Manager:AddGuildChannelRoom(channelName, channelData)
    local guildId = channelData.guildId
    local guildRoomNumber = channelData.guildRoomNumber
    local guildName = GetGuildName(guildId)

    local guildChannels = self.channelData[VOICE_CHANNEL_GUILD]
    if not guildChannels[guildId] then
        guildChannels[guildId] =
        {
            header = zo_strformat(SI_GAMEPAD_VOICECHAT_CHANNEL_GUILD_HEADER, guildName),
            rooms = {},
        }

        self.participantsData[VOICE_CHANNEL_GUILD][guildId] = {}
    end

    --Check for duplicates
    if self.participantsData[VOICE_CHANNEL_GUILD][guildId][guildRoomNumber] then
        return
    end

    local name
    local description
    if guildRoomNumber == VOICE_CHAT_OFFICERS_ROOM_NUMBER then
        name = GetString(SI_GAMEPAD_VOICECHAT_ROOM_NAME_OFFICERS)
        description = GetString(SI_GAMEPAD_VOICECHAT_CHANNEL_DESCRIPTION_GUILD_OFFICERS)
    else
        name = zo_strformat(SI_GAMEPAD_VOICECHAT_ROOM_NAME, guildRoomNumber)
        description = GetString(SI_GAMEPAD_VOICECHAT_CHANNEL_DESCRIPTION_GUILD)
    end

    guildChannels[guildId].rooms[guildRoomNumber] =
    {
        channelType = VOICE_CHANNEL_GUILD,
        channelName = channelName,
        guildId = guildId,
        guildRoomNumber = guildRoomNumber,
        guildName = guildName,
        name = name,
        description = description,
        fullName = zo_strformat(SI_GAMEPAD_VOICECHAT_GUILD_CHANNEL_NAME, guildName, name),
        historyData = HistoryData:New(),
    }
    self.participantsData[VOICE_CHANNEL_GUILD][guildId][guildRoomNumber] = ParticipantsData:New(DONT_SORT_BY_OCCURRENCE)

    self.guildChannelsToIds[channelName] = guildId
end

function ZO_VoiceChat_Manager:RemoveGuildChannelRoom(channelName, guildId, guildRoomNumber)
    local guildChannels = self.channelData[VOICE_CHANNEL_GUILD]
    local guildData = guildChannels[guildId]

    if guildData then
        --Destroy the room
        guildData.rooms[guildRoomNumber] = nil
        self.participantsData[VOICE_CHANNEL_GUILD][guildId][guildRoomNumber] = nil

        --Destroy the guild entry
        if NonContiguousCount(guildData.rooms) == 0 then
            guildChannels[guildId] = nil
            self.participantsData[VOICE_CHANNEL_GUILD][guildId] = nil
        end
    end

    self.guildChannelsToIds[channelName] = nil
end

function ZO_VoiceChat_Manager:RefreshGuildChannelIds()
    local guildChannels = self.channelData[VOICE_CHANNEL_GUILD]
    local guildParticipants = self.participantsData[VOICE_CHANNEL_GUILD]

    local remappedGuildChannels = {}
    for oldGuildId, guildData in pairs(guildChannels) do
        local newGuildId
        for roomNumber, roomData in pairs(guildData.rooms) do
            if not newGuildId then
                local channelData = ZO_VoiceChat_GetChannelDataFromName(roomData.channelName)
                newGuildId = channelData.guildId
            end
            roomData.guildId = newGuildId
            self.guildChannelsToIds[roomData.channelName] = newGuildId
        end

        remappedGuildChannels[newGuildId] = guildChannels[oldGuildId]
        if oldGuildId ~= newGuildId then
            guildParticipants[newGuildId] = guildParticipants[oldGuildId]
            guildParticipants[oldGuildId] = nil
        end
    end

    self.channelData[VOICE_CHANNEL_GUILD] = remappedGuildChannels
end

function ZO_VoiceChat_Manager:DoesChannelExist(channelData)
    local channelType = channelData.channelType

    if channelType == VOICE_CHANNEL_GUILD then
        local guildId = channelData.guildId
        local guildRoomNumber = channelData.guildRoomNumber

        local guildData = self.channelData[channelType]
        return guildData[guildId] ~= nil and guildData[guildId].rooms[guildRoomNumber] ~= nil
    end

    return self.channelData[channelType] ~= nil
end

function ZO_VoiceChat_Manager:GetGuildChannelByName(guildName, guildRoomNumber)
    for _, guildData in pairs(self.channelData[VOICE_CHANNEL_GUILD]) do
        for roomIndex, roomChannel in pairs(guildData.rooms) do
            if roomChannel.guildName == guildName and roomChannel.guildRoomNumber == guildRoomNumber then
                return roomChannel
            end
        end
    end

    return nil
end

function ZO_VoiceChat_Manager:SetDesiredActiveChannel(channel)
    self.desiredActiveChannel = channel
end


--Intended Public Functions
function ZO_VoiceChat_Manager:GetChannel(channelData)
    local channelType = channelData.channelType

    if channelType == VOICE_CHANNEL_GUILD then
        local guildId = channelData.guildId
        local guildRoomNumber = channelData.guildRoomNumber

        return self.channelData[channelType][guildId].rooms[guildRoomNumber]
    else
        return self.channelData[channelType]
    end
end

function ZO_VoiceChat_Manager:GetParticipantData(channel)
    local channelType = channel.channelType
    local guildId = channel.guildId
    local guildRoomNumber = channel.guildRoomNumber

    if channelType == VOICE_CHANNEL_GUILD then
        return self.participantsData[channelType][guildId][guildRoomNumber]
    else
        return self.participantsData[channelType]
    end
end

function ZO_VoiceChat_Manager:GetParticipantDataList(channel)
    return self:GetParticipantData(channel).list
end

function ZO_VoiceChat_Manager:GetChannelData()
    local areaData
    local groupData

    local areaChannel = self.channelData[VOICE_CHANNEL_AREA]
    if areaChannel.isAvailable then
        areaData = areaChannel
    end

    local bgChannel = self.channelData[VOICE_CHANNEL_BATTLEGROUP]
    if bgChannel.isAvailable then
        groupData = bgChannel
    else
        local groupChannel = self.channelData[VOICE_CHANNEL_GROUP]
        if groupChannel.isAvailable then
            groupData = groupChannel
        end
    end

    local guildData = self.channelData[VOICE_CHANNEL_GUILD]

    return areaData, groupData, guildData
end

function ZO_VoiceChat_Manager:HasChannelData()
    local areaData, groupData, guildData = self:GetChannelData()
    return areaData or groupData or NonContiguousCount(guildData) > 0
end

function ZO_VoiceChat_Manager:GetDesiredActiveChannelType()
    if self.desiredActiveChannel then
        return self.desiredActiveChannel.channelType
    end

    return nil
end

--Globals

VOICE_CHAT_MANAGER = ZO_VoiceChat_Manager:New()
