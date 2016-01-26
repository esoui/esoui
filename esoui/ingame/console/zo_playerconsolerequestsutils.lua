--[[Gamercard Utils]]--
local function OnGamerCardInfoRequestReady(wasFound, displayName, consoleId)
    if wasFound then
        local undecoratedName = UndecorateDisplayName(displayName)
        ShowGamerCard(undecoratedName, consoleId)
    else
        ZO_Dialogs_ShowGamepadDialog("GAMERCARD_UNAVAILABLE")
    end
end

function ZO_ShowGamerCardFromCharacterName(characterName)
    PLAYER_CONSOLE_INFO_REQUEST_MANAGER:RequestIdFromCharacterName(characterName, ZO_PLAYER_CONSOLE_INFO_REQUEST_DONT_BLOCK, OnGamerCardInfoRequestReady)
end

function ZO_ShowGamerCardFromDisplayName(displayName)
    PLAYER_CONSOLE_INFO_REQUEST_MANAGER:RequestIdFromDisplayName(displayName, ZO_PLAYER_CONSOLE_INFO_REQUEST_DONT_BLOCK, OnGamerCardInfoRequestReady)
end

function ZO_ShowGamerCardFromDisplayNameOrFallback(displayName, idRequestType, ...)
    PLAYER_CONSOLE_INFO_REQUEST_MANAGER:RequestIdFromDisplayNameOrFallbackType(displayName, ZO_PLAYER_CONSOLE_INFO_REQUEST_DONT_BLOCK, idRequestType, OnGamerCardInfoRequestReady, ...)
end

--[[Friend Request Utils]]--
local function OnConsoleFriendRequestReady(wasInfoFound, displayName, consoleId)
    if wasInfoFound then
        ShowConsoleAddFriendDialog(displayName, consoleId)
    end
end

function ZO_ShowConsoleAddFriendDialog(characterName)
    PLAYER_CONSOLE_INFO_REQUEST_MANAGER:RequestIdFromCharacterName(characterName, ZO_PLAYER_CONSOLE_INFO_REQUEST_DONT_BLOCK, OnConsoleFriendRequestReady)
end

function ZO_ShowConsoleAddFriendDialogFromDisplayName(displayName)
    PLAYER_CONSOLE_INFO_REQUEST_MANAGER:RequestIdFromDisplayName(displayName, ZO_PLAYER_CONSOLE_INFO_REQUEST_DONT_BLOCK, OnConsoleFriendRequestReady)
end

function ZO_ShowConsoleAddFriendDialogFromDisplayNameOrFallback(displayName, idRequestType, ...)
    PLAYER_CONSOLE_INFO_REQUEST_MANAGER:RequestIdFromDisplayNameOrFallbackType(displayName, ZO_PLAYER_CONSOLE_INFO_REQUEST_DONT_BLOCK, idRequestType, OnConsoleFriendRequestReady, ...)
end

--[[Add Ignore Utils]]--

local function OnConsoleIgnoreReady(wasInfoFound, displayName, consoleId)
    if wasInfoFound then
        ShowConsoleIgnoreDialog(displayName, consoleId)
    end
end

function ZO_ShowConsoleIgnoreDialog(displayName)
    if ZO_DoesConsoleSupportTargetedIgnore() then
        PLAYER_CONSOLE_INFO_REQUEST_MANAGER:RequestIdFromDisplayName(displayName, ZO_PLAYER_CONSOLE_INFO_REQUEST_DONT_BLOCK, OnConsoleIgnoreReady)
    end
end

function ZO_ShowConsoleIgnoreDialogFromDisplayNameOrFallback(displayName, idRequestType, ...)
    if ZO_DoesConsoleSupportTargetedIgnore() then
        PLAYER_CONSOLE_INFO_REQUEST_MANAGER:RequestIdFromDisplayNameOrFallbackType(displayName, ZO_PLAYER_CONSOLE_INFO_REQUEST_DONT_BLOCK, idRequestType, OnConsoleIgnoreReady, ...)
    end
end

--[[Add Friend Utils]]--

local function OnUserListDialogIdSelectedForFriendAdd(hasResult, displayName, consoleId)
    if hasResult then
        ShowConsoleAddFriendDialog(displayName, consoleId)
    end
end

function ZO_ShowConsoleAddFriendDialogFromUserListSelector()
    local DONT_INCLUDE_ONLINE_FRIENDS = false
    local DONT_INCLUDE_OFFLINE_FRIENDS = false
    PLAYER_CONSOLE_INFO_REQUEST_MANAGER:RequestIdFromUserListDialog(OnUserListDialogIdSelectedForFriendAdd, GetString(SI_GAMEPAD_CONSOLE_SELECT_FOR_FRIEND_ADD), DONT_INCLUDE_ONLINE_FRIENDS, DONT_INCLUDE_OFFLINE_FRIENDS)
end

function ZO_DoesConsoleSupportTargetedIgnore()
    return GetUIPlatform() == UI_PLATFORM_PS4
end

--[[Invite to Group Utils]]--

local function OnUserListDialogIdSelectedForGroupInvite(hasResult, displayName, consoleId)
    if hasResult then
        local NOT_SENT_FROM_CHAT = false
        local DISPLAY_INVITED_MESSAGE = true
        TryGroupInviteByName(ZO_FormatManualNameEntry(displayName), NOT_SENT_FROM_CHAT, DISPLAY_INVITED_MESSAGE)
    end
end

function ZO_ShowConsoleInviteToGroupFromUserListSelector()
    local INCLUDE_ONLINE_FRIENDS = true
    local DONT_INCLUDE_OFFLINE_FRIENDS = false
    PLAYER_CONSOLE_INFO_REQUEST_MANAGER:RequestIdFromUserListDialog(OnUserListDialogIdSelectedForGroupInvite, GetString(SI_GAMEPAD_CONSOLE_SELECT_FOR_INVITE), INCLUDE_ONLINE_FRIENDS, DONT_INCLUDE_OFFLINE_FRIENDS)
end

--[[Invite to Guild Utils]]--

function ZO_ShowConsoleInviteToGuildFromUserListSelector(guildId)
    local function OnUserListDialogIdSelectedForGuildInvite(hasResult, displayName, consoleId)
        if hasResult then
            ZO_TryGuildInvite(guildId, ZO_FormatManualNameEntry(displayName))
        end
    end

    local INCLUDE_ONLINE_FRIENDS = true
    local INCLUDE_OFFLINE_FRIENDS = true
    PLAYER_CONSOLE_INFO_REQUEST_MANAGER:RequestIdFromUserListDialog(OnUserListDialogIdSelectedForGuildInvite, GetString(SI_GAMEPAD_CONSOLE_SELECT_FOR_INVITE), INCLUDE_ONLINE_FRIENDS, INCLUDE_OFFLINE_FRIENDS)
end

--[[Communication Utils]]--

ZO_CONSOLE_CAN_COMMUNICATE_RESULT_SUCCESS = 0
ZO_CONSOLE_CAN_COMMUNICATE_RESULT_NO_SUCH_PLAYER = 1
ZO_CONSOLE_CAN_COMMUNICATE_RESULT_NOT_ALLOWED = 2
ZO_CONSOLE_CAN_COMMUNICATE_RESULT_GLOBALLY_RESTRICTED = 3

ZO_CONSOLE_CAN_COMMUNICATE_ERROR_DIALOG = 1
ZO_CONSOLE_CAN_COMMUNICATE_ERROR_ALERT = 2

local function ReportCommunicationError(errorText, errorType)
    if errorType == ZO_CONSOLE_CAN_COMMUNICATE_ERROR_DIALOG then
        ZO_Dialogs_ShowGamepadDialog("CONSOLE_COMMUNICATION_PERMISSION_ERROR", nil,  { mainTextParams = { errorText } })
    elseif errorType == ZO_CONSOLE_CAN_COMMUNICATE_ERROR_ALERT then
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, errorText)
    end
end

function ZO_ConsoleAttemptInteractOrError(callback, displayName, block, errorType, idRequestType, ...)
    if IsIgnored(DecorateDisplayName(displayName)) then
        ReportCommunicationError(GetString(SI_CONSOLE_COMMUNICATION_PERMISSION_ERROR_NOT_ALLOWED), errorType)
        callback(false)
    else
        callback(true)
    end
end

function ZO_ConsoleAttemptCommunicateOrError(callback, displayName, block, errorType, idRequestType, ...)
    if IsConsoleCommunicationRestricted() then
        ReportCommunicationError(GetString(SI_CONSOLE_COMMUNICATION_PERMISSION_ERROR_GLOBALLY_RESTRICTED), errorType)
        callback(false)
        return
    end

    ZO_ConsoleAttemptInteractOrError(callback, displayName, block, errorType, idRequestType, ...)
end 