local ChannelInfo = ZO_ChatSystem_GetChannelInfo()

local function FormatShutdownTime(timeRemaining)
    if timeRemaining == 0 then
        return GetString(SI_CHAT_SHUTDOWN_NOW)
    end

    return zo_strformat(SI_CHAT_SHUTDOWN_TIME, ZO_FormatTime(timeRemaining, TIME_FORMAT_STYLE_DESCRIPTIVE))
end

local function CreateChannelLink(channelInfo, overrideName)
    if channelInfo.channelLinkable then
        local channelName = overrideName or GetChannelName(channelInfo.id)
        return ZO_LinkHandler_CreateChannelLink(channelName)
    end
end

local function GetCustomerServiceIcon(isCustomerServiceAccount)
    if(isCustomerServiceAccount) then
        return "|t16:16:EsoUI/Art/ChatWindow/csIcon.dds|t"
    end

    return ""
end

local ChatEventFormatters = {
    [EVENT_SERVER_SHUTDOWN_INFO] = function(action, timeRemaining)
        if action == SERVER_SHUTDOWN_CANCELED then
            return GetString(SI_CHAT_SHUTDOWN_CANCEL)
        elseif action == SERVER_SHUTDOWN_START then
            return zo_strformat(SI_CHAT_SHUTDOWN_START, FormatShutdownTime(timeRemaining))
        elseif action == SERVER_SHUTDOWN_RESCHEDULED then
            return zo_strformat(SI_CHAT_SHUTDOWN_RESCHEDULE, FormatShutdownTime(timeRemaining))
        elseif action == SERVER_SHUTDOWN_UPDATE then
            return FormatShutdownTime(timeRemaining)
        end
    end,

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

            local fromLink = channelInfo.playerLinkable and ZO_LinkHandler_CreatePlayerLink(userFacingName) or userFacingName

            -- Channels with links will not have CS messages
            if channelLink then
                return zo_strformat(channelInfo.format, channelLink, fromLink, text), channelInfo.saveTarget, fromDisplayName, text
            end

            return zo_strformat(channelInfo.format, fromLink, text, GetCustomerServiceIcon(isFromCustomerService)), channelInfo.saveTarget, fromDisplayName, text
        end
    end,

    [EVENT_BROADCAST] = function(message)
        return zo_strformat(SI_CHAT_MESSAGE_SYSTEM, GetString("SI_CHATCHANNELCATEGORIES", CHAT_CATEGORY_SYSTEM), message)
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

        if(not IsGroupErrorIgnoreResponse(response) and ShouldShowGroupErrorInChat(response)) then
            local alertMessage = nameToDisplay ~= "" and zo_strformat(GetString("SI_GROUPINVITERESPONSE", response), nameToDisplay) or GetString(SI_PLAYER_BUSY)
    
            return alertMessage, nil, diplayName
        end
    end,

	[EVENT_SOCIAL_ERROR] = function(error)
        if(not IsSocialErrorIgnoreResponse(error) and ShouldShowSocialErrorInChat(error)) then
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
}

function ZO_ChatSystem_GetEventHandlers()
    return ChatEventFormatters
end

local function OnChatEvent(...)
    CHAT_SYSTEM:OnChatEvent(...)
end

function ZO_ChatEvent(eventId, ...)
    if IsChatSystemAvailableForCurrentPlatform() then
        OnChatEvent(eventId, ...)
    end
end

function ZO_ChatSystem_AddEventHandler(eventId, handler)
    if IsChatSystemAvailableForCurrentPlatform() then
        ChatEventFormatters[eventId] = handler
        EVENT_MANAGER:RegisterForEvent("ChatSystem_OnEventId" .. eventId, eventId, OnChatEvent)
    end
end

function ShouldShowSocialErrorInChat(error)
    return not ShouldShowSocialErrorInAlert(error)
end

function ShouldShowGroupErrorInChat(error)
    return not ShouldShowGroupErrorInAlert(error)
end