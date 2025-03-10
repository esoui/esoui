local PlayerConsoleInfoRequestManager = ZO_Object:Subclass()

local REQUEST_TIMEOUT_MS = 4000
local TEXT_VALIDATION_OVERRIDE_REQUEST_TIMEOUT_MS = 30000

ZO_PLAYER_CONSOLE_INFO_REQUEST_BLOCK = true
ZO_PLAYER_CONSOLE_INFO_REQUEST_DONT_BLOCK = false

local REQUEST_ID = "id"
local REQUEST_TEXT_VALIDATION = "textValidation"

function PlayerConsoleInfoRequestManager:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function PlayerConsoleInfoRequestManager:Initialize()
    self.pendingRequests = {}

    if ZO_IsIngameUI() then
        EVENT_MANAGER:RegisterForEvent("PlayerConsoleInfoRequest", EVENT_CONSOLE_INFO_RECEIVED, function(_, ...) self:OnConsoleInfoReceived(...) end)
    end

    EVENT_MANAGER:RegisterForEvent("PlayerConsoleInfoRequest", EVENT_SELECT_FROM_USER_LIST_DIALOG_RESULT, function(_, ...) self:OnSelectFromUserListDialogResult(...) end)
    EVENT_MANAGER:RegisterForEvent("PlayerConsoleInfoRequest", EVENT_CONSOLE_TEXT_VALIDATION_RESULT, function(_, ...) self:OnConsoleTextValidationResult(...) end)
    EVENT_MANAGER:RegisterForEvent("PlayerConsoleInfoRequest", EVENT_RESUME_FROM_SUSPEND, function(...) self:OnResumeFromSuspend(...) end)
    EVENT_MANAGER:RegisterForUpdate("PlayerConsoleInfoRequest", 500, function() self:OnUpdate() end)
end

function PlayerConsoleInfoRequestManager:OnResumeFromSuspend()
    local NO_RESULT = false
    self:OnSelectFromUserListDialogResult(NO_RESULT)
end

ZO_ID_REQUEST_TYPE_ACCOUNT_ID = "accountId"
ZO_ID_REQUEST_TYPE_CHARACTER_NAME = "characterName"
ZO_ID_REQUEST_TYPE_DISPLAY_NAME = "displayName"
ZO_ID_REQUEST_TYPE_GUILD_INFO = "guildInfo"
ZO_ID_REQUEST_TYPE_GUILD_APPLICATION_INFO = "guildApplicationInfo"
ZO_ID_REQUEST_TYPE_GUILD_BLACKLIST_INFO = "guildBlacklistInfo"
ZO_ID_REQUEST_TYPE_FRIEND_INFO = "friendInfo"
ZO_ID_REQUEST_TYPE_IGNORE_INFO = "ignoreInfo"
ZO_ID_REQUEST_TYPE_GROUP_INFO = "groupInfo"
ZO_ID_REQUEST_TYPE_FRIEND_REQUEST = "friendRequest"
ZO_ID_REQUEST_TYPE_MAIL_ID = "mailId"
ZO_ID_REQUEST_TYPE_CAMPAIGN_LEADERBOARD = "campaignLeaderboard"
ZO_ID_REQUEST_TYPE_CAMPAIGN_ALLIANCE_LEADERBOARD = "campaignAllianceLeaderboard"
ZO_ID_REQUEST_TYPE_TRIAL_LEADERBOARD = "trialLeaderboard"
ZO_ID_REQUEST_TYPE_TRIAL_OF_THE_WEEK_LEADERBOARD = "trialOfTheWeekLeaderboard"
ZO_ID_REQUEST_TYPE_CHALLENGE_LEADERBOARD = "challengeLeaderboard"
ZO_ID_REQUEST_TYPE_CHALLENGE_OF_THE_WEEK_LEADERBOARD = "challengeOfTheWeekLeaderboard"
ZO_ID_REQUEST_TYPE_BATTLEGROUND_LEADERBOARD = "battlegroundLeaderboard"
ZO_ID_REQUEST_TYPE_TRIBUTE_LEADERBOARD = "tributeLeaderboard"
ZO_ID_REQUEST_TYPE_ENDLESS_DUNGEON_SOLO_LEADERBOARD = "endlessDungeonSoloLeaderboard"
ZO_ID_REQUEST_TYPE_ENDLESS_DUNGEON_OF_THE_WEEK_SOLO_LEADERBOARD = "endlessDungeonSoloOfTheWeekLeaderboard"
ZO_ID_REQUEST_TYPE_ENDLESS_DUNGEON_DUO_LEADERBOARD = "endlessDungeonSoloLeaderboard"
ZO_ID_REQUEST_TYPE_ENDLESS_DUNGEON_OF_THE_WEEK_DUO_LEADERBOARD = "endlessDungeonDuoOfTheWeekLeaderboard"

local CONSOLE_INFO_FUNCTIONS = 
{
    [ZO_ID_REQUEST_TYPE_ACCOUNT_ID] = GetConsoleInfoFromAccountId, 
    [ZO_ID_REQUEST_TYPE_CHARACTER_NAME] = GetConsoleInfoFromCharName,
    [ZO_ID_REQUEST_TYPE_DISPLAY_NAME] = GetConsoleInfoFromDisplayName,
    [ZO_ID_REQUEST_TYPE_GUILD_INFO] = GetConsoleInfoFromGuildMember,
    [ZO_ID_REQUEST_TYPE_GUILD_APPLICATION_INFO] = GetConsoleInfoFromGuildApplicationIndex,
    [ZO_ID_REQUEST_TYPE_GUILD_BLACKLIST_INFO] = GetConsoleInfoFromGuildBlacklistIndex,
    [ZO_ID_REQUEST_TYPE_FRIEND_INFO] = GetConsoleInfoFromFriend,
    [ZO_ID_REQUEST_TYPE_IGNORE_INFO] = GetConsoleInfoFromIgnore,
    [ZO_ID_REQUEST_TYPE_GROUP_INFO] = GetConsoleInfoFromGroupMember,
    [ZO_ID_REQUEST_TYPE_FRIEND_REQUEST] = GetConsoleInfoFromIncomingFriendRequest,
    [ZO_ID_REQUEST_TYPE_MAIL_ID] = GetConsoleInfoFromMailId,
    [ZO_ID_REQUEST_TYPE_CAMPAIGN_LEADERBOARD] = GetConsoleInfoFromLeaderboardEntry,
    [ZO_ID_REQUEST_TYPE_CAMPAIGN_ALLIANCE_LEADERBOARD] = GetConsoleInfoFromAllianceLeaderboardEntry,
    [ZO_ID_REQUEST_TYPE_TRIAL_LEADERBOARD] = GetConsoleInfoFromTrialLeaderboardEntry,
    [ZO_ID_REQUEST_TYPE_TRIAL_OF_THE_WEEK_LEADERBOARD] = GetConsoleInfoFromTrialOfTheWeekLeaderboardEntry,
    [ZO_ID_REQUEST_TYPE_CHALLENGE_LEADERBOARD] = GetConsoleInfoFromChallengeLeaderboardEntry,
    [ZO_ID_REQUEST_TYPE_CHALLENGE_OF_THE_WEEK_LEADERBOARD] = GetConsoleInfoFromChallengeOfTheWeekLeaderboardEntry,
    [ZO_ID_REQUEST_TYPE_BATTLEGROUND_LEADERBOARD] = GetConsoleInfoFromBattlegroundLeaderboardEntry,
    [ZO_ID_REQUEST_TYPE_TRIBUTE_LEADERBOARD] = GetConsoleInfoFromTributeLeaderboardEntry,
    [ZO_ID_REQUEST_TYPE_ENDLESS_DUNGEON_SOLO_LEADERBOARD] = GetConsoleInfoFromEndlessDungeonSoloLeaderboardEntry,
    [ZO_ID_REQUEST_TYPE_ENDLESS_DUNGEON_OF_THE_WEEK_SOLO_LEADERBOARD] = GetConsoleInfoFromEndlessDungeonOfTheWeekSoloLeaderboardEntry,
    [ZO_ID_REQUEST_TYPE_ENDLESS_DUNGEON_DUO_LEADERBOARD] = GetConsoleInfoFromEndlessDungeonDuoLeaderboardEntry,
    [ZO_ID_REQUEST_TYPE_ENDLESS_DUNGEON_OF_THE_WEEK_DUO_LEADERBOARD] = GetConsoleInfoFromEndlessDungeonOfTheWeekDuoLeaderboardEntry,
}

function PlayerConsoleInfoRequestManager:RequestId(idRequestType, block, callback, ...)
    local lookupFunction = CONSOLE_INFO_FUNCTIONS[idRequestType]
    if lookupFunction then
        local displayName, consoleId, wasFound, requestKey = lookupFunction(...)
        if wasFound then
            callback(wasFound, displayName, consoleId)
        else
            local data =
            {
                requestKey = requestKey,
            }
            self:AddPendingRequest(REQUEST_ID, data, block, callback)
        end
    end
end

function PlayerConsoleInfoRequestManager:RequestIdFromAccountId(accountId, block, callback)
    self:RequestId(ZO_ID_REQUEST_TYPE_ACCOUNT_ID, block, callback, accountId)
end

function PlayerConsoleInfoRequestManager:RequestIdFromCharacterName(characterName, block, callback)
    self:RequestId(ZO_ID_REQUEST_TYPE_CHARACTER_NAME, block, callback, characterName)
end

function PlayerConsoleInfoRequestManager:RequestIdFromDisplayName(displayName, block, callback)
    if ZO_IsPlaystationPlatform() then
        --PlayStation doesn't have a console id so we can just return 0 for it immediately
        callback(true, displayName, 0)
    else
        self:RequestId(ZO_ID_REQUEST_TYPE_DISPLAY_NAME, block, callback, displayName)
    end
end

function PlayerConsoleInfoRequestManager:RequestIdFromDisplayNameOrFallbackType(displayName, block, fallbackRequestType, callback, ...)
    if ZO_IsPlaystationPlatform() then
        callback(true, displayName, 0)
    elseif GetUIPlatform() == UI_PLATFORM_XBOX then
        self:RequestId(fallbackRequestType, block, callback, ...)
    end
end

function PlayerConsoleInfoRequestManager:RequestIdFromUserListDialog(callback, titleText, includeOnlineFriends, includeOfflineFriends)
    if not self.requestingFromUserListDialog then
        self.requestingFromUserListDialog = true
        self.requestFromUserListDialogCallback = callback
        ShowSelectFromUserListDialog(titleText or "", includeOnlineFriends, includeOfflineFriends)
    end
end

function PlayerConsoleInfoRequestManager:RequestTextValidation(text, callback)
    if ZO_IsConsolePlatform() then
        local data =
        {
            validationKey = RequestConsoleTextValidation(text),
            callback = callback,
            -- Prospero sometimes has slow text validation calls lasting up to 15 seconds, so we give these a bit more time
            overrideTimeoutMS = TEXT_VALIDATION_OVERRIDE_REQUEST_TIMEOUT_MS
        }
        self:AddPendingRequest(REQUEST_TEXT_VALIDATION, data, ZO_PLAYER_CONSOLE_INFO_REQUEST_DONT_BLOCK, callback)
    else
        --for force console UI flow
        callback(true)
    end
end

function PlayerConsoleInfoRequestManager:RequestNameValidation(name, callback)
    if not IsValidName(name) then
        callback(false)
    else
        if ZO_IsConsolePlatform() then
        local data =
        {
            validationKey = RequestConsoleTextValidation(name),
            blockingDialogName = "WAIT_FOR_CONSOLE_NAME_VALIDATION",
            -- Prospero sometimes has slow text validation calls lasting up to 15 seconds, so we give these a bit more time
            overrideTimeoutMS = TEXT_VALIDATION_OVERRIDE_REQUEST_TIMEOUT_MS
        }
        self:AddPendingRequest(REQUEST_TEXT_VALIDATION, data, ZO_PLAYER_CONSOLE_INFO_REQUEST_BLOCK, callback)
        else
            --for force console UI flow
            callback(true)
        end
    end
end

--Private API

function PlayerConsoleInfoRequestManager:AddPendingRequest(requestType, data, block, callback)
    local pendingRequest = data
    pendingRequest.requestType = requestType
    pendingRequest.callback = callback
    pendingRequest.requestMadeAtMS = GetFrameTimeMilliseconds()
    
    if block then
        if self.blockingOnPendingRequest == nil then
            self.blockingOnPendingRequest = pendingRequest
            ZO_Dialogs_ShowGamepadDialog(pendingRequest.blockingDialogName or "GAMEPAD_GENERIC_WAIT")
        else
            return
        end
    end

    table.insert(self.pendingRequests, pendingRequest)
end

function PlayerConsoleInfoRequestManager:FindPendingRequestByField(fieldName, fieldValue, requestType)
    if fieldValue ~= nil then
        for i, pendingRequest in ipairs(self.pendingRequests) do
            if pendingRequest.requestType == requestType and pendingRequest[fieldName] == fieldValue then
                return pendingRequest, i
            end
        end
    end
end

function PlayerConsoleInfoRequestManager:OnUpdate()
    local i = 1
    local now = GetFrameTimeMilliseconds()
    while i <= #self.pendingRequests do
        local pendingRequest = self.pendingRequests[i]
        local timeoutMS = REQUEST_TIMEOUT_MS
        if pendingRequest.overrideTimeoutMS then
            timeoutMS = pendingRequest.overrideTimeoutMS
        end
        if now - pendingRequest.requestMadeAtMS > timeoutMS then
            self:CheckCloseBlockingDialog(pendingRequest)
            table.remove(self.pendingRequests, i)
        else
            i = i + 1
        end
    end
end

function PlayerConsoleInfoRequestManager:CheckCloseBlockingDialog(pendingRequest)
    if self.blockingOnPendingRequest == pendingRequest then
        self.blockingOnPendingRequest = nil
        local dialogName = pendingRequest.blockingDialogName or "GAMEPAD_GENERIC_WAIT"
        ZO_Dialogs_ReleaseAllDialogsOfName(dialogName)
    end
end

function PlayerConsoleInfoRequestManager:OnConsoleInfoReceived(requestKey, displayName, consoleId, success)
    local pendingRequest, index = self:FindPendingRequestByField("requestKey", requestKey, REQUEST_ID)
    if pendingRequest then
        self:CheckCloseBlockingDialog(pendingRequest)
        table.remove(self.pendingRequests, index)
        if success then
            pendingRequest.callback(success, displayName, consoleId)
        else
            pendingRequest.callback(success)
        end
    end
end

function PlayerConsoleInfoRequestManager:OnSelectFromUserListDialogResult(hasResult, displayName, consoleId)
    if self.requestingFromUserListDialog then
        self.requestingFromUserListDialog = false
        self.requestFromUserListDialogCallback(hasResult, displayName, consoleId)
        self.requestFromUserListDialogCallback = nil
    end
end

function PlayerConsoleInfoRequestManager:OnConsoleTextValidationResult(key, valid)
    local pendingRequest, index = self:FindPendingRequestByField("validationKey", key, REQUEST_TEXT_VALIDATION)
    if pendingRequest then
        self:CheckCloseBlockingDialog(pendingRequest)
        table.remove(self.pendingRequests, index)
        pendingRequest.callback(valid)
    end
end

PLAYER_CONSOLE_INFO_REQUEST_MANAGER = PlayerConsoleInfoRequestManager:New()