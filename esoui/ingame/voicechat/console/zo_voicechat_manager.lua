--Global voice chat related functions and data
function ZO_VoiceChat_GetChannelDataFromName(channelName)
    local channelType, guildId, guildRoomNumber = VoiceChatGetChannelInfo(channelName)

    local channelData = {
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


local HistoryData = ZO_Object:Subclass()

function HistoryData:New()
    local obj = ZO_Object.New(self)

    obj.list = {} --entries toward the end of the list are considered newer
    obj.map = {}

    return obj
end

function HistoryData:UpdateUser(displayName)
    local newEntry = {
        displayName = displayName,
        lastTimeSpoken = GetFrameTimeMilliseconds(),
        isMuted = false,
    }

    if self.map[displayName] then
        self:RemoveUser(displayName)
    end
    
    table.insert(self.list, newEntry)

    --Maintain max size
    if #self.list > HISTORY_ENTRY_LIMIT then
        local data = self.list[1]
        self.map[data.displayName] = nil
        table.remove(self.list, 1)
    end

    self.map[displayName] = newEntry
end

function HistoryData:UpdateUserMute(displayName, isMuted)
    if self.map[displayName] then
        self.map[displayName].isMuted = isMuted
    end
end

function HistoryData:UpdateMutes(mutedUsers)
    for i = 1, #self.list do
        local speakerData = self.list[i]
        speakerData.isMuted = mutedUsers[speakerData.displayName]
    end
end

function HistoryData:RemoveUser(displayName)
    for i = 1, #self.list do
        if self.list[i].displayName == displayName then
            table.remove(self.list, i)
            break
        end
    end

    self.map[displayName] = nil
end



--------------------------------------------------------------------------------
-- VoiceChat Participants Data
--      Helper class for saving and sorting the participants of each channel.
--------------------------------------------------------------------------------

local SORT_KEYS = {
    displayName = {}
}
local SORT_BY_OCCURRENCE = true
local DONT_SORT_BY_OCCURRENCE = false

local function SortParticipantEntries(entry1, entry2)
    return ZO_TableOrderingFunction(entry1, entry2, "displayName", SORT_KEYS, ZO_SORT_ORDER_UP)
end


local ParticipantsData = ZO_Object:Subclass()

function ParticipantsData:New(sortByOccurrence)
    local obj = ZO_Object.New(self)

    obj.list = {}
    obj.map = {}
    obj.sortByOccurrence = sortByOccurrence --when true, newer entries occur first in the list

    return obj
end

function ParticipantsData:AddOrUpdateParticipant(displayName, speakStatus, isMuted)
    if self.map[displayName] then
        self:UpdateParticipantStatus(displayName, speakStatus, isMuted)
        return
    end

    table.insert(self.list, 1, {displayName = displayName, speakStatus = speakStatus, isMuted = isMuted})
    self.map[displayName] = self.list[1]

    if not self.sortByOccurrence then
        table.sort(self.list, SortParticipantEntries)
    end
end

function ParticipantsData:RemoveParticipant(displayName)
    for i = 1, #self.list do
        if self.list[i].displayName == displayName then
            table.remove(self.list, i)
            self.map[displayName] = nil
            break
        end
    end
end

function ParticipantsData:GetParticipant(displayName)
    return self.map[displayName]
end

function ParticipantsData:GetParticipantIndex(displayName)
    for i = 1, #self.list do
        if self.list[i].displayName == displayName then
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

function ParticipantsData:UpdateMutes(mutedUsers)
    for i = 1, #self.list do
        local speakerData = self.list[i]
        speakerData.isMuted = mutedUsers[speakerData.displayName]
    end
end

function ParticipantsData:Size()
    return #self.list
end

function ParticipantsData:ClearParticipants()
    self.list = {}
    self.map = {}
end



--------------------------------------------------------------------------------
--Voice Chat Manager
--  Data manager for Voice Chat. Also handles the channel joining automation
--  and 1+1 Active/Passive channel functionality.
--------------------------------------------------------------------------------

local SAVE_SETTINGS_DELAY = 2000 --the delay until the settings will save after being changed


VOICE_CHAT_MANAGER = nil

ZO_VoiceChat_Manager = ZO_CallbackObject:Subclass()

function ZO_VoiceChat_Manager:New()
    local manager = ZO_CallbackObject.New(self)
    manager:Initialize()
    return manager
end

function ZO_VoiceChat_Manager:Initialize()
    --Use a delayed callback after making a Voice Chat related server request to temporarily lock out
    --further requests. This is to give the first request a chance to complete.
    self.areRequestsAllowed = true
    self.requestDelayFunction = function()
        self.areRequestsAllowed = true
        self:FireCallbacks("RequestsAllowed")
    end

    --Use a delayed callback after changing a setting so that we can save just once for multiple changes.
    self.saveSettingsCount = 0
    self.saveSettingsFunction = function()
        self.saveSettingsCount = math.max(self.saveSettingsCount - 1, 0)

        if self.saveSettingsCount == 0 then
            ZO_SavePlayerConsoleProfile()
        end
    end
    
    self.channelData = {
        [VOICE_CHANNEL_AREA] = {
            channelType = VOICE_CHANNEL_AREA,
            guildId = 0,
            guildRoomNumber = 0,
	        name = GetString(SI_GAMEPAD_VOICECHAT_CHANNEL_AREA),
            description = GetString(SI_GAMEPAD_VOICECHAT_CHANNEL_DESCRIPTION_AREA),
            historyData = HistoryData:New(),
            hasBadReputation = DoesLocalPlayerHaveBadReputation(),
        },
        [VOICE_CHANNEL_GROUP] = {
            channelType = VOICE_CHANNEL_GROUP,
            guildId = 0,
	        guildRoomNumber = 0,
	        name = GetString(SI_GAMEPAD_VOICECHAT_CHANNEL_GROUP),
            description = GetString(SI_GAMEPAD_VOICECHAT_CHANNEL_DESCRIPTION_GROUP),
            historyData = HistoryData:New(),
        },
        [VOICE_CHANNEL_GUILD] = {}, --populates during channel retrieval
    }

    --The guild ids are dirtied and will need to be refreshed for all guild channels whenever a guild is joined or left.
    self.guildIdsDirty = false

    --The guild ids we can retrieve from engine are invalid for channels that just became unavailable. We'll need to keep
    --a local cache so we can id guilds for certain channel events.
    self.guildChannelsToIds = {}

    self.participantsData = {}
    self.participantsData[VOICE_CHANNEL_AREA] = ParticipantsData:New(SORT_BY_OCCURRENCE)
    self.participantsData[VOICE_CHANNEL_GROUP] = ParticipantsData:New(DONT_SORT_BY_OCCURRENCE)
    self.participantsData[VOICE_CHANNEL_GUILD] = {} --populates during channel retrieval

    self.mutedUsers = {}
    self:UpdateMutes()

    self.activeChannel = nil --a channel we're joined to and transmitting on
    self.passiveChannel = nil --a channel we're joined to, but only listening to
    self.desiredPassiveChannel = nil
    self.desiredActiveChannel = nil

    self:RegisterForEvents()
end

function ZO_VoiceChat_Manager:RegisterForEvents()
    local function RetrieveParticipants(channel)
        self:GetParticipantData(channel):ClearParticipants()
        VoiceChatRequestChannelUsers(channel.channelName)
    end

    local function DoLoginJoinsDefault()
        local areaChannel = self.channelData[VOICE_CHANNEL_AREA]
        local groupChannel = self.channelData[VOICE_CHANNEL_GROUP]

        if groupChannel.isAvailable then
            self:SetDesiredActiveChannel(groupChannel)
            self:SetDesiredPassiveChannel(areaChannel)
            
        elseif NonContiguousCount(self.channelData[VOICE_CHANNEL_GUILD]) > 0 then
            --Join the first iterated guild room
            for guildId, guildData in pairs(self.channelData[VOICE_CHANNEL_GUILD]) do
                for roomIndex, roomChannel in pairs(guildData.rooms) do
                    self:SetDesiredActiveChannel(roomChannel)
                    self:SetDesiredPassiveChannel(areaChannel)
                    return
                end
            end

        else
            self:SetDesiredActiveChannel(areaChannel)
        end
    end

    local function DoLoginJoinsUserPreferred()
        local function DetermineChannelFromSetting(desiredChannelSetting)
            local channelType = desiredChannelSetting.channelType

            if not channelType then
                return nil
            end

            if channelType == VOICE_CHANNEL_GUILD then
                local guildName = desiredChannelSetting.guildName
                local guildRoomNumber = desiredChannelSetting.guildRoomNumber
                return self:GetGuildChannelByName(guildName, guildRoomNumber)
            else
                local channel = self.channelData[channelType]
                return channel.isAvailable and channel or nil
            end
        end

        local desiredActiveChannel = DetermineChannelFromSetting(self.savedVars.desiredActiveChannel)
        local desiredPassiveChannel = DetermineChannelFromSetting(self.savedVars.desiredPassiveChannel)

        if not desiredActiveChannel then
            desiredActiveChannel = desiredPassiveChannel
            desiredPassiveChannel = nil
        end

        self:SetDesiredActiveChannel(desiredActiveChannel)
        self:SetDesiredPassiveChannel(desiredPassiveChannel)
    end

    local function DoLoginJoins()
        if self.savedVars.isFirstRun then
            DoLoginJoinsDefault()
            self.savedVars.isFirstRun = false
        else
            DoLoginJoinsUserPreferred()
        end
    end

    local function SwapOnLosingActiveGuildChannel()
        local groupChannel = self.channelData[VOICE_CHANNEL_GROUP]
        if groupChannel.isAvailable then
            self:SetDesiredActiveChannel(groupChannel)
        else
            self:SetDesiredActiveChannel(self.desiredPassiveChannel)
            self:SetDesiredPassiveChannel(nil)
        end
    end
    
    local function TryClearPassiveChannel(channel)
        if self.passiveChannel == channel then
            self.passiveChannel = nil
        end
    end
    
    local function TryClearActiveChannel(channel)
        if self.activeChannel == channel then
            self.activeChannel = nil
        end
    end

    --Event Handlers
    local function OnAddOnLoaded(name)
        if name == "ZO_Ingame" then
            --Load the preferred channel settings
            local defaultSettings = {
                isFirstRun = true,
                desiredActiveChannel = {},
                desiredPassiveChannel = {},
            }
            self.savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 1, "VoiceChat", defaultSettings)
            EVENT_MANAGER:UnregisterForEvent("ZO_VoiceChat_OnAddOnLoaded", EVENT_ADD_ON_LOADED)
            
            --We wait to request the list of channels until after we've loaded settings
            VoiceChatGetChannels()
        end
    end

    local function OnPlayerActivated()
        --Only automatically join channels on the first activation after logging into the game.
        if VoiceChatGetShouldDoLoginJoins() then
            --We can activate at the same time we're receiving the channel events, so delay any
            --automatic joining until we determine all the available channels.
            zo_callLater(DoLoginJoins, 1500)

            VoiceChatSetShouldDoLoginJoins(false)
        end

        --Special case for handling the group being destroyed while zoning.
        if not IsUnitGrouped("player") then
            local groupChannel = self.channelData[VOICE_CHANNEL_GROUP]
            self:ClearAndSwapChannel(groupChannel)
        end
    end
    
    local function OnGroupMemberJoined(rawCharacterName)
        if(GetRawUnitName("player") == rawCharacterName) then
            local groupChannel = self.channelData[VOICE_CHANNEL_GROUP]
            self:SetAndSwapDesiredActiveChannel(groupChannel)
        end
    end

    local function OnGroupMemberLeft(characterName, reason, isLocalPlayer, isLeader)
        if isLocalPlayer then
            local groupChannel = self.channelData[VOICE_CHANNEL_GROUP]
            self:ClearAndSwapChannel(groupChannel)
        end
    end

    local function OnSelfJoinedGuild(guildServerId, displayName, guildId)
        --We should only automatically join this guild's channel if we're not already in a group or guild channel
        local desiredActiveChannel = self.desiredActiveChannel
        if desiredActiveChannel then
            local channelType = desiredActiveChannel.channelType
            if channelType == VOICE_CHANNEL_GUILD or channelType == VOICE_CHANNEL_GROUP then
                return
            end
        end
        local desiredPassiveChannel = self.desiredPassiveChannel
        if desiredPassiveChannel then
            local channelType = desiredPassiveChannel.channelType
            if channelType == VOICE_CHANNEL_GUILD or channelType == VOICE_CHANNEL_GROUP then
                return
            end
        end

        --We'll get this guild join event and the corresponding channel available event in a nondeterminite order. Only join it when it's ready.
        local adHocChannelData = {channelType = VOICE_CHANNEL_GUILD, guildId = guildId, guildRoomNumber = 1} --just choose the first non-officer guild room to join
        if self:DoesChannelExist(adHocChannelData) then
            --The channel is initialized, so join it
            local channel = self:GetChannel(adHocChannelData)
            self:SetAndSwapDesiredActiveChannel(channel)
        else
            --The channel isn't initialized yet, so flag to join it once it is
            self.autoJoiningGuildButNotAvailable = true
        end
    end

    local function OnSelfLeftGuild(guildServerId, displayName, guildId)
        if self.desiredActiveChannel and self.desiredActiveChannel.guildId == guildId then
            SwapOnLosingActiveGuildChannel()
        elseif self.desiredPassiveChannel and self.desiredPassiveChannel.guildId == guildId then
            self:SetDesiredPassiveChannel(nil)
        end
    end

    local function OnGuildDataLoaded()
        self:RefreshGuildChannelIds()
    end

    local function OnGuildRankChanged(guildId, rankIndex)
        --We can lose permission to access a channel while in it. Leave the channel when this occurs.
        local desiredActiveChannel = self.desiredActiveChannel
        local desiredPassiveChannel = self.desiredPassiveChannel

        local hasRoomPermission = DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_CHAT)
        local hasOfficerPermission = DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_OFFICER_CHAT_WRITE)

        if desiredActiveChannel and desiredActiveChannel.guildId == guildId then
            if desiredActiveChannel.guildRoomNumber == VOICE_CHAT_OFFICERS_ROOM_NUMBER then
                if not hasOfficerPermission then
                    SwapOnLosingActiveGuildChannel()
                end
            else
                if not hasRoomPermission then
                    SwapOnLosingActiveGuildChannel()
                end
            end

        elseif desiredPassiveChannel and desiredPassiveChannel.guildId == guildId then
            if desiredPassiveChannel.guildRoomNumber == VOICE_CHAT_OFFICERS_ROOM_NUMBER then
                if not hasOfficerPermission then
                    self:SetDesiredPassiveChannel(nil)
                end
            else
                if not hasRoomPermission then
                    self:SetDesiredPassiveChannel(nil)
                end
            end
        end
    end

    local function OnGuildMemberRankChanged(guildId, displayName, rankIndex)
        if ZO_VoiceChat_IsNameLocalPlayers(displayName) then
            OnGuildRankChanged(guildId, rankIndex)
        end
    end

    --Voice Channel Event Handlers
    local function OnVoiceChannelJoined(channelName)
        local channelData = ZO_VoiceChat_GetChannelDataFromName(channelName)
        if not self:DoesChannelExist(channelData) then
            return
        end
        local channel = self:GetChannel(channelData)

        channel.isJoined = true
        
        if self.desiredPassiveChannel == channel then
            self.passiveChannel = channel
        end

        RetrieveParticipants(channel)
        self:FireCallbacks("ChannelsUpdate")
    end

    local function OnVoiceChannelLeft(channelName)
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

        TryClearPassiveChannel(channel)
        TryClearActiveChannel(channel)

        self:FireCallbacks("ChannelsUpdate")
        self:FireCallbacks("ParticipantsUpdate")
    end

    local function OnVoiceChannelAvailable(channelName, isMuted, isJoined, isTransmitting)
        local channelData = ZO_VoiceChat_GetChannelDataFromName(channelName)
        local channelType = channelData.channelType

        --Ignore invalid channels. Probably not necessary anymore, but it was a quick fix to an
        --early problem where the engine could send us invalid availability events.
        if channelType == VOICE_CHANNEL_NONE then
            return
        end

        if channelType == VOICE_CHANNEL_GUILD then
            local guildId = channelData.guildId
            local guildRoomNumber = channelData.guildRoomNumber
            self:AddGuildChannelRoom(channelName, guildId, guildRoomNumber)

            self.guildIdsDirty = true

            --Check if we tried to join the channel from the guild join event, but needed to wait
            --for this channel available event.
            if self.autoJoiningGuildButNotAvailable then
                self.autoJoiningGuildButNotAvailable = nil
                self:SetAndSwapDesiredActiveChannel(self:GetChannel(channelData))
            end
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
            else
                self.passiveChannel = channel
                self:SetDesiredPassiveChannel(channel)
            end

            RetrieveParticipants(channel)
        end

        self:FireCallbacks("ChannelsUpdate")
    end

    local function OnVoiceChannelUnavailable(channelName)
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

        TryClearPassiveChannel(channel)
        TryClearActiveChannel(channel)
        
        if channel.channelType == VOICE_CHANNEL_GUILD then
            self:RemoveGuildChannelRoom(channel.channelName, channel.guildId, channel.guildRoomNumber)
            self.guildIdsDirty = true
        end

        self:FireCallbacks("ChannelsUpdate")
    end

    local function OnVoiceTransmitChannelChanged(channelName)
        local channelData = ZO_VoiceChat_GetChannelDataFromName(channelName)
        if not self:DoesChannelExist(channelData) then
            return
        end
        local channel = self:GetChannel(channelData)

        channel.isTransmitting = true
        
        --Mark the old active channel as passive
        if self.activeChannel then
            self.activeChannel.isTransmitting = false
            self.passiveChannel = self.activeChannel
        end

        self.activeChannel = channel

        --If this was our passive channel, then we don't have a passive channel anymore since it's now active
        TryClearPassiveChannel(channel)

        self:FireCallbacks("ChannelsUpdate")
    end

    --Voice Participant Event Handlers
    local function OnVoiceUserJoinedChannel(channelName, displayName, characterName, isSpeaking)
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

    local function OnVoiceUserLeftChannel(channelName, displayName)
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

    local function OnVoiceUserSpeaking(channelName, displayName, characterName, speaking)
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
        self:UpdateMutes()

        self:FireCallbacks("ParticipantsUpdate")
        self:FireCallbacks("MuteUpdate")
    end

    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_OnAddOnLoaded", EVENT_ADD_ON_LOADED, function(event, ...) OnAddOnLoaded(...) end)

    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_OnPlayerActivated", EVENT_PLAYER_ACTIVATED, function(event, ...) OnPlayerActivated(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_OnGroupMemberJoined", EVENT_GROUP_MEMBER_JOINED, function(event, ...) OnGroupMemberJoined(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_OnGroupMemberLeft", EVENT_GROUP_MEMBER_LEFT, function(event, ...) OnGroupMemberLeft(...) end)

    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_OnSelfJoinedGuild", EVENT_GUILD_SELF_JOINED_GUILD, function(event, ...) OnSelfJoinedGuild(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_OnSelfLeftGuild", EVENT_GUILD_SELF_LEFT_GUILD, function(event, ...) OnSelfLeftGuild(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_OnGuildDataLoaded", EVENT_GUILD_DATA_LOADED, function(event, ...) OnGuildDataLoaded(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_OnGuildRankChanged", EVENT_GUILD_RANK_CHANGED, function(event, ...) OnGuildRankChanged(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_OnGuildMemberRankChanged", EVENT_GUILD_MEMBER_RANK_CHANGED, function(event, ...) OnGuildMemberRankChanged(...) end)

    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_OnVoiceChannelJoined", EVENT_VOICE_CHANNEL_JOINED, function(eventCode, ...) OnVoiceChannelJoined(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_OnVoiceChannelLeft", EVENT_VOICE_CHANNEL_LEFT, function(eventCode, ...) OnVoiceChannelLeft(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_OnVoiceChannelAvailable", EVENT_VOICE_CHANNEL_AVAILABLE, function(eventCode, ...) OnVoiceChannelAvailable(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_OnVoiceChannelUnavailable", EVENT_VOICE_CHANNEL_UNAVAILABLE, function(eventCode, ...) OnVoiceChannelUnavailable(...) end)

    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_OnVoiceTransmitChannelChanged", EVENT_VOICE_TRANSMIT_CHANNEL_CHANGED, function(eventCode, ...) OnVoiceTransmitChannelChanged(...) end)

    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_OnVoiceUserJoinedChannel", EVENT_VOICE_USER_JOINED_CHANNEL, function(eventCode, ...) OnVoiceUserJoinedChannel(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_OnVoiceUserLeftChannel", EVENT_VOICE_USER_LEFT_CHANNEL, function(eventCode, ...) OnVoiceUserLeftChannel(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_OnVoiceUserSpeaking", EVENT_VOICE_USER_SPEAKING, function(eventCode, ...) OnVoiceUserSpeaking(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChat_OnVoiceMuteListUpdated", EVENT_VOICE_MUTE_LIST_UPDATED, function(eventCode, ...) OnVoiceMuteListUpdated(...) end)
end

function ZO_VoiceChat_Manager:JoinChannel(channel)
    VoiceChatChannelJoin(channel.channelName)
    self:StartRequestDelay()
end

function ZO_VoiceChat_Manager:TransmitChannel(channel, skipDelay)
    VoiceChatChannelTransmit(channel.channelName)

    --We can skip the delay if we're trying to transmit on a channel already joined (the passive channel)
    if not skipDelay then
        self:StartRequestDelay()
    end
end

function ZO_VoiceChat_Manager:LeaveChannel(channel)
    VoiceChatChannelLeave(channel.channelName)
    self:StartRequestDelay()
end

function ZO_VoiceChat_Manager:UpdateMutes()
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
                    roomData:UpdateMutes(mutedUsers)
                end
            end
        else
            participantData:UpdateMutes(mutedUsers)
        end
    end

    --Update history data
    for channelType, channelData in pairs(self.channelData) do
        if channelType == VOICE_CHANNEL_GUILD then
            for _, guildData in pairs(channelData) do
                for _, roomData in pairs(guildData.rooms) do
                    roomData.historyData:UpdateMutes(mutedUsers)
                end
            end
        else
            channelData.historyData:UpdateMutes(mutedUsers)
        end
    end

    self.mutedUsers = mutedUsers
end

function ZO_VoiceChat_Manager:OnUpdate()
    if self.guildIdsDirty then
        self.guildIdsDirty = false
        self:RefreshGuildChannelIds()
    end

    --The desired channels are the ones the user selects from the UI, or that are automatically
    --set due to specific events occurring (ex. joining a group). The update loop will work
    --towards joining and transmitting on the desired channels while leaving the old ones.
    --It will work with the delay restriction we have between making requests, and will only allow
    --a second channel to be joined if one of them is Area (by design).

    if not self:AreRequestsAllowed() then
        return
    end

    local activeChannel = self.activeChannel
    local desiredActiveChannel = self.desiredActiveChannel
    local passiveChannel = self.passiveChannel
    local desiredPassiveChannel = self.desiredPassiveChannel

    --Update Active channel
    if not desiredActiveChannel then
        if activeChannel then
            self:LeaveChannel(activeChannel)
            return
        end
    elseif desiredActiveChannel.isAvailable and desiredActiveChannel ~= activeChannel then
        --Enforce not being able to be active and passive in two non-Area channels
        if desiredActiveChannel ~= passiveChannel and desiredActiveChannel.channelType ~= VOICE_CHANNEL_AREA then
            if activeChannel and activeChannel.channelType ~= VOICE_CHANNEL_AREA then
                self:LeaveChannel(activeChannel)
                return
            elseif passiveChannel and passiveChannel.channelType ~= VOICE_CHANNEL_AREA then
                self:LeaveChannel(passiveChannel)
                return
            end
        end

        local skipDelay = desiredActiveChannel == passiveChannel --we don't need to delay the next request if we're already joined to the channel
        self:TransmitChannel(desiredActiveChannel, skipDelay)
        return
    end

    --Update Passive channel
    if not desiredPassiveChannel then
        if passiveChannel then
            self:LeaveChannel(passiveChannel)
        end
    elseif desiredPassiveChannel.isAvailable and desiredPassiveChannel ~= passiveChannel then
        if not passiveChannel then
            self:JoinChannel(desiredPassiveChannel)
        else
            self:LeaveChannel(passiveChannel)
        end
    end
end

function ZO_VoiceChat_Manager:AddGuildChannelRoom(channelName, guildId, guildRoomNumber)
    local guildName = GetGuildName(guildId)

    local guildChannels = self.channelData[VOICE_CHANNEL_GUILD]
    if not guildChannels[guildId] then
        guildChannels[guildId] = {}
        guildChannels[guildId].header = zo_strformat(SI_GAMEPAD_VOICECHAT_CHANNEL_GUILD_HEADER, guildName)
        guildChannels[guildId].rooms = {}

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

    guildChannels[guildId].rooms[guildRoomNumber] = {
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
            newGuildId = newGuildId or select(2, VoiceChatGetChannelInfo(roomData.channelName))
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

function ZO_VoiceChat_Manager:SetDesiredPassiveChannel(channel)
    self.desiredPassiveChannel = channel

    --Update saved settings
    if channel then
        self.savedVars.desiredPassiveChannel = {
            channelType = channel.channelType,
            guildName = channel.guildName, --we have to use the name and not the id since the id changes
            guildRoomNumber = channel.guildRoomNumber,
        }
    else
        self.savedVars.desiredPassiveChannel = {}
    end
    
    --The desired channels are often changed in pairs. Delay to prevent double-saving.
    self.saveSettingsCount = self.saveSettingsCount + 1
    zo_callLater(self.saveSettingsFunction, SAVE_SETTINGS_DELAY)
end

function ZO_VoiceChat_Manager:SetDesiredActiveChannel(channel)
    self.desiredActiveChannel = channel

    --Update saved settings
    if channel then
        self.savedVars.desiredActiveChannel = {
            channelType = channel.channelType,
            guildName = channel.guildName, --we have to use the name and not the id since the id changes
            guildRoomNumber = channel.guildRoomNumber,
        }
    else
        self.savedVars.desiredActiveChannel = {}
    end
    
    --The desired channels are often changed in pairs. Delay to prevent double-saving.
    self.saveSettingsCount = self.saveSettingsCount + 1
    zo_callLater(self.saveSettingsFunction, SAVE_SETTINGS_DELAY)
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

    local groupChannel = self.channelData[VOICE_CHANNEL_GROUP]
    if groupChannel.isAvailable then
        groupData = groupChannel
    end

    local guildData = self.channelData[VOICE_CHANNEL_GUILD]

    return areaData, groupData, guildData
end

function ZO_VoiceChat_Manager:AreRequestsAllowed()
    return self.areRequestsAllowed
end

function ZO_VoiceChat_Manager:StartRequestDelay()
    if self.areRequestsAllowed then
        self.areRequestsAllowed = false
        zo_callLater(self.requestDelayFunction, VOICE_CHAT_REQUEST_DELAY)
        self:FireCallbacks("RequestsDisabled")
    end
end

function ZO_VoiceChat_Manager:HasChannelData()
    local areaData, groupData, guildData = self:GetChannelData()
    return areaData or groupData or NonContiguousCount(guildData) > 0
end

function ZO_VoiceChat_Manager:ClearAndSwapChannel(channel)
    if self.desiredActiveChannel == channel then
        self:SetDesiredActiveChannel(self.desiredPassiveChannel)
        self:SetDesiredPassiveChannel(nil)
    elseif self.desiredPassiveChannel == channel then
        self:SetDesiredPassiveChannel(nil)
    end
end

function ZO_VoiceChat_Manager:SetAndSwapDesiredActiveChannel(desiredActiveChannel)
    local previousDesiredActiveChannel = self.desiredActiveChannel

    --Check if it's already active
    if desiredActiveChannel == previousDesiredActiveChannel then
        return
    end

    --Determine if the previous active channel should be made passive rather than
    --leaving it. This is to follow the design of only allowing two joined channels
    --when one is Area.
    -- it's possible that the we hadn't set a previous active channel (for one if we don't have a VOIP server to connect to)
    if desiredActiveChannel.channelType == VOICE_CHANNEL_AREA or (previousDesiredActiveChannel ~= nil and previousDesiredActiveChannel.channelType == VOICE_CHANNEL_AREA) then
        self:SetDesiredPassiveChannel(previousDesiredActiveChannel)
    end

    self:SetDesiredActiveChannel(desiredActiveChannel)
end

function ZO_VoiceChat_Manager:GetDesiredActiveChannelType()
    if self.desiredActiveChannel then
        return self.desiredActiveChannel.channelType
    end

    return nil
end


--Globals
VOICE_CHAT_MANAGER = ZO_VoiceChat_Manager:New()

do
    EVENT_MANAGER:RegisterForUpdate("ZO_VoiceChat_Manager_OnUpdate", 0, function() VOICE_CHAT_MANAGER:OnUpdate() end)
end