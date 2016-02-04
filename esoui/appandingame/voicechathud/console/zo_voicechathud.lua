--AppAndIngame version of ZO_FormatUserFacingDisplayName for local use
local function ZO_FormatUserFacingDisplayName(name)
    return IsConsoleUI() and UndecorateDisplayName(name) or name
end

--------------------------------------------------------------------------------
-- Speaker List
--      A helper class for generating hud speaker entries and anchoring them to
--      form a list. Allows the VoiceChat HUD to only have to deal with adding
--      to and clearing from a list.
--------------------------------------------------------------------------------

local ENTRY_TEMPLATE = "ZO_VoiceChatHUDEntry"

local CHANNEL_TO_COLOR = {
    [VOICE_CHANNEL_AREA] = VOICE_CHAT_COLORS_AREA,
    [VOICE_CHANNEL_GROUP] = VOICE_CHAT_COLORS_GROUP,
    [VOICE_CHANNEL_GUILD] = VOICE_CHAT_COLORS_GUILD,
}
local CHANNEL_TO_ICON = {
    [VOICE_CHANNEL_AREA] = "EsoUI/Art/VOIP/voip-area.dds",
    [VOICE_CHANNEL_GROUP] = "EsoUI/Art/VOIP/voip-group.dds",
    [VOICE_CHANNEL_GUILD] = "EsoUI/Art/VOIP/voip-guild.dds",
}

local SpeakerList = {}

function SpeakerList:Initialize(control)
    self.control = control
    
    self.freeList = {}
    self.activeList = {}
    self.nextControlId = 1
end

function SpeakerList:AddLine(text, channelType)
    --Initialize control
    local newEntry = next(self.freeList)
    if not newEntry then
        newEntry = GetWindowManager():CreateControlFromVirtual(self.nextControlId, self.control, ENTRY_TEMPLATE)
        self.nextControlId = self.nextControlId + 1
    end
    newEntry:SetHidden(false)
    self.freeList[newEntry] = nil
    self.activeList[newEntry] = true

    --Set text
    local textControl = newEntry:GetNamedChild("Text")
    textControl:SetText(text)
    textControl:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_VOICE_CHAT_COLORS, CHANNEL_TO_COLOR[channelType]))

    --Set anchor
    if(self.lastEntry) then
        newEntry:SetAnchor(BOTTOMRIGHT, self.lastEntry, TOPRIGHT)
    else
        newEntry:SetAnchor(BOTTOMRIGHT, nil, BOTTOMRIGHT)
    end
    self.lastEntry = newEntry
    
    --Set icon
    local icon = newEntry:GetNamedChild("Icon")
    icon:SetTexture(CHANNEL_TO_ICON[channelType])
    icon:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_VOICE_CHAT_COLORS, CHANNEL_TO_COLOR[channelType]))
end

function SpeakerList:Clear()
    self.lastEntry = nil
    
    for entry in pairs(self.activeList) do
        self.activeList[entry] = nil
        self.freeList[entry] = true
        entry:SetHidden(true)
    end
end



--------------------------------------------------------------------------------
-- VoiceChat HUD
--  Class for displaying a list of current voice chat speakers. Templated
--  outside the ingame UI layer so that we can also create one for the loading
--  screen.
--------------------------------------------------------------------------------

local LIST_ENTRY_LIMIT = 4
local CLEAR_DELAY_MS = 500 --after a user quits speaking, their HUD entry will persist for this duration before clearing

local function ChannelDataFromName(channelName)
    local channelType, guildId, guildRoomNumber = VoiceChatGetChannelInfo(channelName)

    local channelData = {
        channelName = channelName,
        channelType = channelType,
        guildId = guildId,
        guildRoomNumber = guildRoomNumber
    }

    return channelData
end


ZO_VoiceChatHUD = {}

function ZO_VoiceChatHUD:Initialize(control)
    self.control = control

    self.speakerData = {} --list of currently speaking users, including users who have stopped talking but their HUD entry is waiting to clear
    self.delayedClears = {} --table that maps users who have stopped talking to the time that their HUD entry should clear
    self.localPlayerName = ""
    
    self.speakerList = control:GetNamedChild("List")
    zo_mixin(self.speakerList, SpeakerList)
    self.speakerList:Initialize(self.speakerList)
    
    self:RegisterForEvents()
end

function ZO_VoiceChatHUD:Update()
    --Clear entries for users who haven't spoken recently
    local currentTime = GetFrameTimeMilliseconds()
    for displayName, clearTime in pairs(self.delayedClears) do
        if currentTime >= clearTime then
            self:RemoveName(displayName)
            self.delayedClears[displayName] = nil
        end
    end

    --Create the list
    self.speakerList:Clear()
    for i = 1, #self.speakerData do
        local speakerData = self.speakerData[i]
        self.speakerList:AddLine(ZO_FormatUserFacingDisplayName(speakerData.displayName), speakerData.channelData.channelType)
    end
end

function ZO_VoiceChatHUD:InsertName(channelData, displayName)
    --The list is a stack with the users who spoke most recently on the bottom. The local player is an
    --exception to this and always shows at the bottom.

    local speakerDataEntry = {
        channelData = channelData,
        displayName = displayName,
    }

    --Remove any existing entry so it can be reinserted at the bottom
    self:RemoveName(displayName)

    local insertIndex = self:IsLocalPlayerFirstListEntry() and 2 or 1
    table.insert(self.speakerData, insertIndex, speakerDataEntry)

    --Remove the oldest entry if we're over the limit
    if #self.speakerData > LIST_ENTRY_LIMIT then
        table.remove(self.speakerData)
    end

    self:Update()
end

function ZO_VoiceChatHUD:RemoveName(displayName)
    for i = 1, #self.speakerData do
        if self.speakerData[i].displayName == displayName then
            table.remove(self.speakerData, i)
            self:Update()
            break
        end
    end
end

function ZO_VoiceChatHUD:RemoveNamesForChannel(channelData)
    local newList = {}
    for i = 1, #self.speakerData do
        local data = self.speakerData[i]
        if channelData.channelName ~= data.channelData.channelName then
            table.insert(newList, data)
        end
    end

    self.speakerData = newList
    self:Update()
end

function ZO_VoiceChatHUD:IsUserLocalPlayer(displayName)
    if self.localPlayerName == "" then
        self.localPlayerName = GetDisplayName() --returns empty string "" if not yet set
    end

    return displayName == self.localPlayerName
end

function ZO_VoiceChatHUD:IsLocalPlayerFirstListEntry()
    local firstEntry = self.speakerData[1]
    if not firstEntry then
        return false
    end
    return self:IsUserLocalPlayer(firstEntry.displayName)
end

--Events
function ZO_VoiceChatHUD:RegisterForEvents()
    self.control:RegisterForEvent(EVENT_VOICE_CHANNEL_LEFT, function(eventCode, ...) self:OnVoiceChannelLeft(...) end)
    self.control:RegisterForEvent(EVENT_VOICE_CHANNEL_UNAVAILABLE, function(eventCode, ...) self:OnVoiceChannelUnavailable(...) end)
    self.control:RegisterForEvent(EVENT_VOICE_USER_SPEAKING, function(eventCode, ...) self:OnUserSpeaking(...) end)
    self.control:RegisterForEvent(EVENT_VOICE_USER_JOINED_CHANNEL, function(eventCode, ...) self:OnVoiceUserJoinedChannel(...) end)
    self.control:RegisterForEvent(EVENT_VOICE_USER_LEFT_CHANNEL, function(eventCode, ...) self:OnVoiceUserLeftChannel(...) end)
end

function ZO_VoiceChatHUD:OnVoiceChannelLeft(channelName)
    local channelData = ChannelDataFromName(channelName)
    self:RemoveNamesForChannel(channelData)
end

function ZO_VoiceChatHUD:OnVoiceChannelUnavailable(channelName)
    local channelData = ChannelDataFromName(channelName)
    self:RemoveNamesForChannel(channelData)
end

function ZO_VoiceChatHUD:OnUserSpeaking(channelName, displayName, characterName, speaking)
    local channelData = ChannelDataFromName(channelName)
    
    if speaking then
        self.delayedClears[displayName] = nil
        self:InsertName(channelData, displayName)
    else
        self.delayedClears[displayName] = GetFrameTimeMilliseconds() + CLEAR_DELAY_MS
    end
end

function ZO_VoiceChatHUD:OnVoiceUserJoinedChannel(channelName, displayName, characterName, isSpeaking)
    if isSpeaking then
        self:OnUserSpeaking(channelName, displayName, characterName, isSpeaking)
    end
end

function ZO_VoiceChatHUD:OnVoiceUserLeftChannel(channelName, displayName)
    self:RemoveName(displayName)
end
