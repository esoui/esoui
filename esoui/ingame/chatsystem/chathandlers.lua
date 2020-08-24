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

            -- Channels with links will not have CS messages
            local formattedText
            if channelLink then
                formattedText = string.format(GetString(channelInfo.format), channelLink, fromLink, text)
            else
                if channelInfo.supportCSIcon then
                    formattedText = string.format(GetString(channelInfo.format), GetCustomerServiceIcon(isFromCustomerService), fromLink, text)
                else
                    formattedText = string.format(GetString(channelInfo.format), fromLink, text)
                end
            end

            return formattedText, channelInfo.saveTarget, fromDisplayName, text
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

    ["AddSystemMessage"] = function(messageText)
        -- system messages will already be formatted by the time they get here
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

    local function OnTryInsertLink(...)
        return SYSTEMS:GetObject("ChatSystem"):HandleTryInsertLink(...)
    end
    LINK_HANDLER:RegisterCallback(LINK_HANDLER.INSERT_LINK_EVENT, OnTryInsertLink)

    local function OnLinkClicked(...)
        return SYSTEMS:GetObject("ChatSystem"):OnLinkClicked(...)
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
            local formattedEventText, targetChannel, fromDisplayName, rawMessageText = messageFormatter(...)
            if formattedEventText then
                if targetChannel then
                    local target = select(2, ...)
                    self:FireCallbacks("TargetAddedToChannel", targetChannel, target)
                end

                self:FireCallbacks("FormattedChatMessage", formattedEventText, eventCategory, targetChannel, fromDisplayName, rawMessageText)
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
    return IsHeronUI() or IsConsoleUI()
end

function ZO_ChatSystem_DoesPlatformUseKeyboardChatSystem()
    return IsKeyboardUISupported()
end
