local DEFAULT_FROM_DISPLAY_NAME = nil
local DEFAULT_RAW_MESSAGE_TEXT = nil
local DEFAULT_TARGET_CHANNEL = nil

local g_pvpKillFeedDeathRecurrenceTracker = nil
do
    -- The PvP Kill Feed uses ZO_RecurrenceTracker to track whether any given
    -- killer/victim message has been shown within the last 10 seconds from a
    -- given source (local vs. kill location). Note that the instance count
    -- tracked by ZO_RecurrenceTracker is irrelevant here for the purpose of
    -- the kill feed.
    local EXPIRATION_MS = 10000 -- 10 seconds
    local EXTENSION_MS = 10000 -- 10 seconds
    g_pvpKillFeedDeathRecurrenceTracker = ZO_RecurrenceTracker:New(EXPIRATION_MS, EXTENSION_MS)
end

local ChannelInfo = ZO_ChatSystem_GetChannelInfo()

local function CreateChannelLink(channelInfo, overrideName)
    if channelInfo.channelLinkable then
        local channelName = overrideName or GetChannelName(channelInfo.id)
        return ZO_LinkHandler_CreateChannelLink(channelName)
    end
end

local function GetCustomerServiceIcon(isCustomerServiceAccount)
    if isCustomerServiceAccount then
        return "|t16:16:EsoUI/Art/ChatWindow/csIcon.dds|t"
    end

    return ""
end

local function ShouldShowSocialErrorInChat(error)
    return not ShouldShowSocialErrorInAlert(error)
end

local function ShouldShowGroupErrorInChat(error)
    return not ShouldShowGroupErrorInAlert(error)
end

-- message formatting events can be keyed off of anything, including strings, but numbers will be assumed to be EVENT_MANAGER events and will automatically be registered.
local BUILTIN_MESSAGE_FORMATTERS = {
    [EVENT_CHAT_MESSAGE_CHANNEL] = function(messageType, fromName, text, isFromCustomerService, fromDisplayName)
        local channelInfo = ChannelInfo[messageType]

        if channelInfo and channelInfo.format then
            local channelLink = CreateChannelLink(channelInfo)

            local userFacingName
            if not IsDecoratedDisplayName(fromName) and fromDisplayName ~= "" then
                --We have a character name and a display name, so follow the setting
                userFacingName = ZO_ShouldPreferUserId() and fromDisplayName or fromName
            else
                --We either have two display names, or we weren't given a guaranteed display name, so just use the default fromName
                userFacingName = fromName
            end

            userFacingName = zo_strformat(SI_CHAT_MESSAGE_PLAYER_FORMATTER, userFacingName)
            local fromLink = channelInfo.playerLinkable and ZO_LinkHandler_CreatePlayerLink(userFacingName) or userFacingName

            if channelInfo.formatMessage then
                text = zo_strformat(SI_CHAT_MESSAGE_FORMATTER, text)
            end

            local channelInfoFormat
            if type(channelInfo.format) == "function" then
                channelInfoFormat = channelInfo.format()
            else
                channelInfoFormat = GetString(channelInfo.format)
            end

            local channelInfoNarrationFormat
            if channelInfo.narrationFormat then
                if type(channelInfo.narrationFormat) == "function" then
                    channelInfoNarrationFormat = channelInfo.narrationFormat()
                else
                    channelInfoNarrationFormat = GetString(channelInfo.narrationFormat)
                end
            end

            -- Channels with links will not have CS messages
            local formattedText
            local formattedNarrationText
            if channelLink then
                formattedText = string.format(channelInfoFormat, channelLink, fromLink, text)
                if channelInfoNarrationFormat then
                    formattedNarrationText = string.format(channelInfoNarrationFormat, channelLink, fromLink, text)
                end
            else
                if channelInfo.supportCSIcon then
                    formattedText = string.format(channelInfoFormat, GetCustomerServiceIcon(isFromCustomerService), fromLink, text)
                    if channelInfoNarrationFormat then
                        formattedNarrationText = string.format(channelInfoNarrationFormat, GetCustomerServiceIcon(isFromCustomerService), fromLink, text)
                    end
                else
                    formattedText = string.format(channelInfoFormat, fromLink, text)
                    if channelInfoNarrationFormat then
                        formattedNarrationText = string.format(channelInfoNarrationFormat, fromLink, text)
                    end
                end
            end

            return formattedText, channelInfo.saveTarget, fromDisplayName, text, formattedNarrationText
        end
    end,

    [EVENT_BROADCAST] = function(message)
        return string.format(GetString(SI_CHAT_MESSAGE_SYSTEM), GetString("SI_CHATCHANNELCATEGORIES", CHAT_CATEGORY_SYSTEM), message)
    end,

    [EVENT_FRIEND_PLAYER_STATUS_CHANGED] = function(displayName, characterName, oldStatus, newStatus)
        local wasOnline = oldStatus ~= PLAYER_STATUS_OFFLINE
        local isOnline = newStatus ~= PLAYER_STATUS_OFFLINE

        if wasOnline ~= isOnline then
            local text
            local displayNameLink = ZO_LinkHandler_CreateDisplayNameLink(displayName)
            local characterNameLink = ZO_LinkHandler_CreateCharacterLink(characterName)
            if isOnline then
                if characterName ~= "" then
                    text = zo_strformat(SI_FRIENDS_LIST_FRIEND_CHARACTER_LOGGED_ON, displayNameLink, characterNameLink)
                else
                    text = zo_strformat(SI_FRIENDS_LIST_FRIEND_LOGGED_ON, displayNameLink)
                end
            else
                if characterName ~= "" then
                    text = zo_strformat(SI_FRIENDS_LIST_FRIEND_CHARACTER_LOGGED_OFF, displayNameLink, characterNameLink)
                else
                    text = zo_strformat(SI_FRIENDS_LIST_FRIEND_LOGGED_OFF, displayNameLink)
                end
            end

            return text, nil, displayName
        end
    end,

    [EVENT_IGNORE_ADDED] = function(displayName)
        local link = ZO_LinkHandler_CreateDisplayNameLink(displayName)
        return zo_strformat(SI_FRIENDS_LIST_IGNORE_ADDED, link), nil, displayName
    end,

    [EVENT_IGNORE_REMOVED] = function(displayName)
        local link = ZO_LinkHandler_CreateDisplayNameLink(displayName)
        return zo_strformat(SI_FRIENDS_LIST_IGNORE_REMOVED, link), nil, displayName
    end,

    [EVENT_GROUP_TYPE_CHANGED] = function(largeGroup)
        if largeGroup then
            return GetString(SI_CHAT_ANNOUNCEMENT_IN_LARGE_GROUP)
        else
            return GetString(SI_CHAT_ANNOUNCEMENT_IN_SMALL_GROUP)
        end
    end,

    [EVENT_GROUP_INVITE_RESPONSE] = function(characterName, response, displayName)
        -- Only one name will be sent here, so use that and do not use special formatting since this appears in chat
        local nameToDisplay
        if characterName ~= "" then
            nameToDisplay = IsConsoleUI() and ZO_FormatUserFacingCharacterName(characterName) or characterName
        else
            nameToDisplay = ZO_FormatUserFacingDisplayName(displayName)
        end

        if not IsGroupErrorIgnoreResponse(response) and ShouldShowGroupErrorInChat(response) then
            local alertMessage = nameToDisplay ~= "" and zo_strformat(GetString("SI_GROUPINVITERESPONSE", response), nameToDisplay) or GetString(SI_PLAYER_BUSY)

            return alertMessage, nil, displayName
        end
    end,

    [EVENT_SOCIAL_ERROR] = function(error)
        if not IsSocialErrorIgnoreResponse(error) and ShouldShowSocialErrorInChat(error) then
            return zo_strformat(GetString("SI_SOCIALACTIONRESULT", error))
        end
    end,

    [EVENT_TRIAL_FEATURE_RESTRICTED] = function(restrictionType)
        if ZO_ChatSystem_GetTrialEventMappings()[restrictionType] then
            return GetString("SI_TRIALACCOUNTRESTRICTIONTYPE", restrictionType)
        end
    end,

    [EVENT_GROUP_MEMBER_LEFT] = function(characterName, reason, isLocalPlayer, isLeader, displayName, actionRequiredVote)
        if reason == GROUP_LEAVE_REASON_KICKED and isLocalPlayer and actionRequiredVote then
            return GetString(SI_GROUP_ELECTION_KICK_PLAYER_PASSED)
        end
    end,

    [EVENT_BATTLEGROUND_INACTIVITY_WARNING] = function()
        return GetString(SI_BATTLEGROUND_INACTIVITY_WARNING)
    end,

    [EVENT_GUILD_KEEP_ATTACK_UPDATE] = function(channel, numGuardsKilled, numAttackers, location)
        if tonumber(GetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_AVA_NOTIFICATIONS)) ~= AVA_NOTIFICATIONS_SETTING_CHOICE_DONT_SHOW and
            tonumber(GetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_GUILD_KEEP_NOTICES)) == GUILD_KEEP_NOTICES_SETTING_CHOICE_CHAT then
            local channelInfo = ChannelInfo[channel]

            if channelInfo then
                local text
                if numGuardsKilled > 0 then
                    text = zo_strformat(SI_GUILD_KEEP_ATTACK_UPDATE, numGuardsKilled, location, numAttackers)
                else
                    text = zo_strformat(SI_GUILD_KEEP_ATTACK_END, location)
                end
                local channelInfoFormat = GetString(SI_CHAT_MESSAGE_GUILD_NO_SENDER)
                local channelLink = CreateChannelLink(channelInfo)
                local formattedText = string.format(channelInfoFormat, channelLink, text)

                return formattedText
            end
        end
    end,

    [EVENT_PVP_KILL_FEED_DEATH] = function(killLocation, killerDisplayName, killerCharacterName, killerAlliance, killerRank, victimDisplayName, victimCharacterName, victimAlliance, victimRank, isKillLocation)
        local showKillFeedNotifications = GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_PVP_KILL_FEED_NOTIFICATIONS)
        if not showKillFeedNotifications then
            return nil
        end

        local messageKeySuffix = string.format("%s___%s", killerDisplayName, victimDisplayName)
        local messageKeyLocal = "L" .. messageKeySuffix
        local messageKeyKillLocation = "B" .. messageKeySuffix
        if isKillLocation then
            -- This message was kill location sourced.
            if g_pvpKillFeedDeathRecurrenceTracker:RemoveValue(messageKeyLocal) ~= nil then
                -- The same message was already shown as a result of a local message;
                -- remove the original message from the tracker and suppress this message.
                return nil
            end
            -- Track this kill location sourced message.
            g_pvpKillFeedDeathRecurrenceTracker:AddValue(messageKeyKillLocation)
        else
            -- This message was locally sourced.
            if g_pvpKillFeedDeathRecurrenceTracker:RemoveValue(messageKeyKillLocation) ~= nil then
                -- The same message was already shown as a result of a kill location message;
                -- remove the original message from the tracker and suppress this message.
                return nil
            end
            -- Track this locally sourced message.
            g_pvpKillFeedDeathRecurrenceTracker:AddValue(messageKeyLocal)
        end

        local isBattleground = IsActiveWorldBattleground()
        local killerAllianceColor
        local victimAllianceColor
        if isBattleground then
            killerAllianceColor = GetBattlegroundAllianceColor(killerAlliance):GetBright()
            victimAllianceColor = GetBattlegroundAllianceColor(victimAlliance):GetBright()
        else
            killerAllianceColor = GetAllianceColor(killerAlliance):GetBright()
            victimAllianceColor = GetAllianceColor(victimAlliance):GetBright()
        end

        local ICON_SIZE = 24
        local killerIcon
        local victimIcon
        if isBattleground then
            killerIcon = ZO_GetBattlegroundIconMarkup(killerAlliance, ICON_SIZE)
            victimIcon = ZO_GetBattlegroundIconMarkup(victimAlliance, ICON_SIZE)
        else
            killerIcon = ZO_GetColoredAvARankIconMarkup(killerRank, killerAlliance, ICON_SIZE)
            victimIcon = ZO_GetColoredAvARankIconMarkup(victimRank, victimAlliance, ICON_SIZE)
        end

        local killerAllianceName
        local victimAllianceName
        if isBattleground then
            killerAllianceName = GetString("SI_BATTLEGROUNDALLIANCE", killerAlliance)
            victimAllianceName = GetString("SI_BATTLEGROUNDALLIANCE", victimAlliance)
        else
            killerAllianceName = ZO_CachedStrFormat(SI_ALLIANCE_NAME, GetAllianceName(killerAlliance))
            victimAllianceName = ZO_CachedStrFormat(SI_ALLIANCE_NAME, GetAllianceName(victimAlliance))
        end

        local killerName = ZO_GetPrimaryPlayerName(killerDisplayName, killerCharacterName)
        local victimName = ZO_GetPrimaryPlayerName(victimDisplayName, victimCharacterName)

        local killerGender = GetGenderFromNameDescriptor(killerCharacterName)
        local victimGender = GetGenderFromNameDescriptor(victimCharacterName)

        local killerRankName = GetAvARankName(killerGender, killerRank)
        local victimRankName = GetAvARankName(victimGender, victimRank)

        local hasLocation = killLocation and killLocation ~= ""
        local messageStringId = hasLocation and SI_PVP_KILL_FEED_DEATH_AND_LOCATION or SI_PVP_KILL_FEED_DEATH
        local message = zo_strformat(messageStringId, killerAllianceColor:Colorize(killerName), killerIcon, victimAllianceColor:Colorize(victimName), victimIcon, killLocation)

        local narrationStringId = hasLocation and SI_PVP_KILL_FEED_DEATH_AND_LOCATION_NARRATION or SI_PVP_KILL_FEED_DEATH_NARRATION
        local narrationMessage = zo_strformat(narrationStringId, killerAllianceName, killerRankName, killerName, victimAllianceName, victimRankName, victimName, killLocation)
        return message, DEFAULT_TARGET_CHANNEL, DEFAULT_FROM_DISPLAY_NAME, DEFAULT_RAW_MESSAGE_TEXT, narrationMessage, ZO_WHITE
    end,

    ["AddSystemMessage"] = function(messageText)
        -- System messages will already be formatted by the time they get here
        return messageText
    end,

    ["AddTranscriptMessage"] = function(messageText)
        -- Transcript messages will already be formatted by the time they get here
        return messageText
    end,
}

-----------------
-- Chat Router --
-----------------

--[[
    The chat router's job is to format chat events and route them to the multiple chat subsystems that exist.
    All methods should be safely callable without checking if the chat system is available or not
]]--

local ZO_ChatRouter = ZO_CallbackObject:Subclass()
function ZO_ChatRouter:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_ChatRouter:Initialize()
    if not IsChatSystemAvailableForCurrentPlatform() then
        return
    end

    self.registeredMessageFormatters = {}
    self.hasRegisteredEvent = {}
    for eventCode, messageFormatter in pairs(BUILTIN_MESSAGE_FORMATTERS) do
        self:RegisterMessageFormatter(eventCode, messageFormatter)
    end

    local function SetTranscriptForwardingEnabled()
        local enableTranscriptForwarding = GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_SEND_TRANSCRIPT_TO_TEXT_CHAT)
        self:SetTranscriptForwardingEnabled(enableTranscriptForwarding)
    end

    EVENT_MANAGER:RegisterForEvent("ChatRouter", EVENT_VOICE_CHAT_ACCESSIBILITY_SETTING_CHANGED, SetTranscriptForwardingEnabled)
    EVENT_MANAGER:RegisterForEvent("ChatRouter", EVENT_FORWARD_TRANSCRIPT_TO_TEXT_CHAT_ACCESSIBILITY_SETTING_CHANGED, SetTranscriptForwardingEnabled)

    local function OnTryInsertLink(...)
        return ZO_GetChatSystem():HandleTryInsertLink(...)
    end
    LINK_HANDLER:RegisterCallback(LINK_HANDLER.INSERT_LINK_EVENT, OnTryInsertLink)

    local function OnLinkClicked(...)
        return ZO_GetChatSystem():OnLinkClicked(...)
    end
    LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_CLICKED_EVENT, OnLinkClicked)
    LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_MOUSE_UP_EVENT, OnLinkClicked)

    -- FlashTaskbarWindow is a private function: to keep it from tainting the normal event handler we'll register for it seperately
    local function OnChatMessageChannel(_, chatChannel)
        if chatChannel == CHAT_CHANNEL_WHISPER then
            local NUM_FLASHES_BEFORE_SOLID = 7
            FlashTaskbarWindow("WHISPER", NUM_FLASHES_BEFORE_SOLID)
        end
    end
    EVENT_MANAGER:RegisterForEvent("ChatRouterNotification", EVENT_CHAT_MESSAGE_CHANNEL, OnChatMessageChannel)
end

function ZO_ChatRouter:GetRegisteredMessageFormatters()
    return self.registeredMessageFormatters
end

do
    local function OnChatEvent(eventCode, ...)
        CHAT_ROUTER:FormatAndAddChatMessage(eventCode, ...)
    end

    function ZO_ChatRouter:RegisterMessageFormatter(eventKey, messageFormatter)
        if not IsChatSystemAvailableForCurrentPlatform() then
            return
        end

        self.registeredMessageFormatters[eventKey] = messageFormatter

        if type(eventKey) == "number" and not self.hasRegisteredEvent[eventKey] then
            local eventCode = eventKey
            EVENT_MANAGER:RegisterForEvent("ChatRouter", eventCode, OnChatEvent)
            self.hasRegisteredEvent[eventCode] = true
        end
    end
end

do
    local MultiLevelEventToCategoryMappings, SimpleEventToCategoryMappings = ZO_ChatSystem_GetEventCategoryMappings()
    function ZO_ChatRouter:FormatAndAddChatMessage(eventKey, ...)
        if not IsChatSystemAvailableForCurrentPlatform() then
            return
        end

        local eventCategory = nil
        if SimpleEventToCategoryMappings[eventKey] then
            eventCategory = SimpleEventToCategoryMappings[eventKey]
        elseif MultiLevelEventToCategoryMappings[eventKey] then
            local messageType = select(1, ...)
            eventCategory = MultiLevelEventToCategoryMappings[eventKey][messageType]
        end

        local messageFormatter = self.registeredMessageFormatters[eventKey]
        if messageFormatter then
            local formattedEventText, targetChannel, fromDisplayName, rawMessageText, formattedNarrationText, overrideColorDef = messageFormatter(...)
            if formattedEventText then
                if targetChannel then
                    local target = select(2, ...)
                    self:FireCallbacks("TargetAddedToChannel", targetChannel, target)
                end

                self:FireCallbacks("FormattedChatMessage", formattedEventText, eventCategory, targetChannel, fromDisplayName, rawMessageText, formattedNarrationText, overrideColorDef)
            end
        end
    end
end

function ZO_ChatRouter:AddSystemMessage(messageText)
    self:FormatAndAddChatMessage("AddSystemMessage", messageText)
end

function ZO_ChatRouter:AddDebugMessage(messageText)
    self:AddSystemMessage(messageText)
end

function ZO_ChatRouter:AddTranscriptMessage(messageText)
    self:FormatAndAddChatMessage("AddTranscriptMessage", messageText)
end

local function AddTranscriptMessage(...)
    CHAT_ROUTER:AddTranscriptMessage(...) 
end

function ZO_ChatRouter:SetTranscriptForwardingEnabled(enabled)
    if enabled then
        VOICE_CHAT_MANAGER:RegisterCallback("VoiceChatTranscript", AddTranscriptMessage)
    else
        VOICE_CHAT_MANAGER:UnregisterCallback("VoiceChatTranscript", AddTranscriptMessage)
    end
end

function ZO_ChatRouter:AddCommandPrefix(prefixCharacter, callback)
    self:FireCallbacks("AddCommandPrefix", prefixCharacter, callback)
end

function ZO_ChatRouter:SetCurrentChannelData(channelData, channelTarget)
    self.currentChannel = channelData
    self.currentTarget = channelTarget
    CALLBACK_MANAGER:FireCallbacks("OnChatChannelUpdated")
end

function ZO_ChatRouter:GetCurrentChannelData()
    return self.currentChannel, self.currentTarget
end

CHAT_ROUTER = ZO_ChatRouter:New()

--- Global functions ---

function ZO_ChatSystem_DoesPlatformUseGamepadChatSystem()
    return IsGamepadUISupported()
end

function ZO_ChatSystem_DoesPlatformUseKeyboardChatSystem()
    return IsKeyboardUISupported()
end

function ZO_ChatSystem_ShouldUseKeyboardChatSystem()
    if not IsKeyboardUISupported() then
        return false
    end

    local useKeyboardChat = GetSetting_Bool(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_USE_KEYBOARD_CHAT)
    return IsInGamepadPreferredMode() == false or useKeyboardChat == true
end

function ZO_GetChatSystem()
    if ZO_ChatSystem_ShouldUseKeyboardChatSystem() then
        return SYSTEMS:GetKeyboardObject("ChatSystem")
    else
        return SYSTEMS:GetGamepadObject("ChatSystem")
    end
end