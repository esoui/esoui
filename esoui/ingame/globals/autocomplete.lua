AUTO_COMPLETE_FLAG_NONE = 0
AUTO_COMPLETE_FLAG_FRIEND = 1
AUTO_COMPLETE_FLAG_GUILD = 2
AUTO_COMPLETE_FLAG_RECENT = 3
AUTO_COMPLETE_FLAG_RECENT_TARGET = 4
AUTO_COMPLETE_FLAG_RECENT_CHAT = 5
AUTO_COMPLETE_FLAG_GUILD_NAMES = 6
AUTO_COMPLETE_FLAG_ALL = 7

local g_currentPlayerName
local g_currentPlayerUserId

local RecentPlayerTracker = ZO_Object:Subclass()

function RecentPlayerTracker:New(...)
    local recentPlayerTracker = ZO_Object.New(self)
    recentPlayerTracker:Initialize(...)
    return recentPlayerTracker
end

function RecentPlayerTracker:Initialize(maxPlayers, optTableToUse)
    self.maxPlayers = maxPlayers
    self.recentPlayers = optTableToUse or {}
    self.numRecentPlayers = NonContiguousCount(self.recentPlayers)
end

function RecentPlayerTracker:GetPlayers()
    return self.recentPlayers
end

function RecentPlayerTracker:RemoveOldPlayers()
    local entriesToRemove = self.numRecentPlayers - self.maxPlayers
    local currentTimeStamp = GetTimeStamp()
    while entriesToRemove > 0 do
        local oldestName, oldestTimestampDifference
        for name, timestamp in pairs(self.recentPlayers) do
            local difference = GetDiffBetweenTimeStamps(currentTimeStamp, timestamp)
            if not oldestTimestampDifference or difference > oldestTimestampDifference then
                oldestName = name
                oldestTimestampDifference = difference
            end
        end
        assert(oldestName)
        self.recentPlayers[oldestName] = nil
        entriesToRemove = entriesToRemove - 1
    end

    self.numRecentPlayers = self.maxPlayers
end

function RecentPlayerTracker:AddRecentPlayer(name)
    if name and name ~= g_currentPlayerName and name ~= g_currentPlayerUserId then
        if self.recentPlayers[name] then
            --Already exists, just update the timestamp
            self.recentPlayers[name] = GetTimeStamp()
        else
            --Didn't exist, add it, then check if there's too many entries
            self.recentPlayers[name] = GetTimeStamp()
            self.numRecentPlayers = self.numRecentPlayers + 1
            if self.numRecentPlayers > self.maxPlayers then
                self:RemoveOldPlayers()
            end
        end
    end
end

local g_recentInteractions -- created below from saved variables
local g_recentTargets = RecentPlayerTracker:New(15) -- not persisted
local g_recentChat = RecentPlayerTracker:New(30) -- not persisted

local INCLUDE = true
local EXCLUDE = false

local function IncludeOrExcludeResult(results, result, include)
    if result ~= g_currentPlayerName and result ~= g_currentPlayerUserId then
        local lowerResult = zo_strlower(result)
        if include then
            results[lowerResult] = result
        else
            results[lowerResult] = nil
        end
    end
end

local function IncludeOrExcludePlayersFromRecentPlayerTracker(recentPlayerTracker, results, include)
    local isDecoratedDisplayName
    local isConsoleUI = IsConsoleUI()
    for name in pairs(recentPlayerTracker:GetPlayers()) do
        isDecoratedDisplayName = IsDecoratedDisplayName(name)
        if isDecoratedDisplayName then
            name = ZO_FormatUserFacingDisplayName(name)
        end

        if not isConsoleUI or isDecoratedDisplayName then
            IncludeOrExcludeResult(results, name, include)
        end
    end
end

local FlagHandlers = {
    [AUTO_COMPLETE_FLAG_FRIEND] = function(results, input, onlineOnly, include)
        for i=1, GetNumFriends() do
            local displayName, _, playerStatus = GetFriendInfo(i)
            if not onlineOnly or playerStatus ~= PLAYER_STATUS_OFFLINE then
                --No @ symbols and no character names on console
                IncludeOrExcludeResult(results, ZO_FormatUserFacingDisplayName(displayName), include)

                if not IsConsoleUI() then
                    local hasCharacter, characterName = GetFriendCharacterInfo(i)
                    if hasCharacter then
                        IncludeOrExcludeResult(results, zo_strformat("<<1>>", characterName), include)
                    end
                end
            end
        end
    end,

    [AUTO_COMPLETE_FLAG_GUILD] = function(results, input, onlineOnly, include)
        for i = 1, GetNumGuilds() do
            local guildId = GetGuildId(i)
            local numMembers = GetNumGuildMembers(guildId)
            for memberIndex = 1, numMembers do
                local displayName, _, _, playerStatus = GetGuildMemberInfo(guildId, memberIndex)
                if not onlineOnly or playerStatus ~= PLAYER_STATUS_OFFLINE then
                    --No @ symbols and no character names on console
                    IncludeOrExcludeResult(results, ZO_FormatUserFacingDisplayName(displayName), include)

                    if not IsConsoleUI() then
                        local hasCharacter, characterName = GetGuildMemberCharacterInfo()
                        if hasCharacter then
                            IncludeOrExcludeResult(results, zo_strformat("<<1>>", characterName), include)
                        end
                    end
                end
            end
        end
    end,

    [AUTO_COMPLETE_FLAG_RECENT] = function(results, input, onlineOnly, include)
        IncludeOrExcludePlayersFromRecentPlayerTracker(g_recentInteractions, results, include)
    end,

    [AUTO_COMPLETE_FLAG_RECENT_TARGET] = function(results, input, onlineOnly, include)
        IncludeOrExcludePlayersFromRecentPlayerTracker(g_recentTargets, results, include)
    end,

    [AUTO_COMPLETE_FLAG_RECENT_CHAT] = function(results, input, onlineOnly, include)
        IncludeOrExcludePlayersFromRecentPlayerTracker(g_recentChat, results, include)
    end,

    [AUTO_COMPLETE_FLAG_GUILD_NAMES] = function(results, input, onlineOnly, include)
        for i = 1, GetNumGuilds() do
            local guildId = GetGuildId(i)
            local guildName = GetGuildName(guildId)
            IncludeOrExcludeResult(results, zo_strformat("<<1>>", guildName), include)
        end
    end,
}

do
    local ComputeStringDistance = ComputeStringDistance

    local function ComputeSubStringMatchScore(source, startIndex, trimmedTextToScore)
        local startIndex, endIndex = source:find(trimmedTextToScore, startIndex, true)
        if startIndex then
            return ((endIndex - startIndex) / (#source * .1)) * 10
        end
        return 0
    end

    function ComputeScore(source, scoringText, startIndex, trimmedTextToScore)
        return ComputeStringDistance(source, scoringText) - ComputeSubStringMatchScore(source, startIndex, trimmedTextToScore)
    end

    local POOR_MATCH_RATIO = .75
    local POOR_MATCH_MIN = 1

    local scores = {}
    local function BinaryInsertComparer(leftScore, _, rightIndex)
        return leftScore - scores[rightIndex]
    end

    local zo_binarysearch = zo_binarysearch
    function GetTopMatchesByLevenshteinSubStringScore(stringsToScore, scoringText, startingIndex, maxResults, noMinScore)
        maxResults = maxResults or 10
        if maxResults == 0 then return end

        startIndex = startingIndex or 1
        scoringText = zo_strlower(scoringText)
        local trimmedTextToScore = scoringText:sub(startingIndex, 20)

        local results = {}
        ZO_ClearNumericallyIndexedTable(scores)

        local minScore = POOR_MATCH_RATIO * (zo_min(#scoringText, 10 + startIndex) - startIndex - POOR_MATCH_MIN)
        for lowerSource, source in pairs(stringsToScore) do
            local score = ComputeScore(lowerSource, scoringText, startIndex, trimmedTextToScore)
            if noMinScore or (score <= minScore) then
                local _, insertPosition = zo_binarysearch(score, results, BinaryInsertComparer)
                table.insert(results, insertPosition, source)
                table.insert(scores, insertPosition, score)

                results[maxResults + 1] = nil
                scores[maxResults + 1] = nil
            end
        end

        return results
    end
end

local function TryCallFlagHandler(flag, possibleMatches, input, onlineOnly, include)
    local handler = FlagHandlers[flag]
    if handler then
        handler(possibleMatches, input, onlineOnly, include)
    end
end

local function GenerateAutoCompletionResults(input, maxResults, onlineOnly, includeFlags, excludeFlags, noMinScore)
    local possibleMatches = {}

    if not includeFlags or includeFlags[1] == AUTO_COMPLETE_FLAG_ALL then
        for flag = 1, AUTO_COMPLETE_FLAG_ALL - 1 do
            TryCallFlagHandler(flag, possibleMatches, input, onlineOnly, INCLUDE)
        end
    else
        for i, flag in ipairs(includeFlags) do
            TryCallFlagHandler(flag, possibleMatches, input, onlineOnly, INCLUDE)
        end
    end

    if excludeFlags then
        if excludeFlags[1] == AUTO_COMPLETE_FLAG_ALL then
            return
        end
        for i, flag in ipairs(excludeFlags) do
            TryCallFlagHandler(flag, possibleMatches, input, onlineOnly, EXCLUDE)
        end
    end 

    local results = GetTopMatchesByLevenshteinSubStringScore(possibleMatches, input, 1, maxResults, noMinScore)
    if results then
        return unpack(results)
    end
end

function GetAutoCompletion(input, maxResults, onlineOnly, includeFlags, excludeFlags, noMinScore)
    maxResults = maxResults or 10
    input = input:lower()

    return GenerateAutoCompletionResults(input, maxResults, onlineOnly, includeFlags, excludeFlags, noMinScore)
end

local function Initialize(event, name)
    if name == "ZO_Ingame" then
        g_currentPlayerName = GetUnitName("player")
        g_currentPlayerUserId = GetDisplayName()

        local function OnChatMessage(event, messageType, name)
            if not IsDecoratedDisplayName(name) then
                name = zo_strformat("<<1>>", name)
            end
            if messageType == CHAT_CHANNEL_WHISPER then
                g_recentInteractions:AddRecentPlayer(name)
            else
                g_recentChat:AddRecentPlayer(name)
            end
        end

        local function OnUnitCreated(event, tag)
            g_recentInteractions:AddRecentPlayer(GetUnitName(tag))
        end

        local function OnInboxUpdate()
            for mailId in ZO_GetNextMailIdIter do
                local senderDisplayName, senderCharacterName = GetMailSender(mailId)
                local _, _, fromSystem, fromCustomerService = GetMailFlags(mailId)
                if not fromSystem and not fromCustomerService then
                    g_recentInteractions:AddRecentPlayer(senderDisplayName)
                    g_recentInteractions:AddRecentPlayer(zo_strformat("<<1>>", senderCharacterName))
                end
            end
        end

        local function OnTradeWindowInviteAccepted()
            g_recentInteractions:AddRecentPlayer(zo_strformat(SI_GAMEPAD_TRADE_USERNAME, TRADE_WINDOW.target))
        end

        local function TryAddRecentTarget(unitTag)
            if IsUnitPlayer(unitTag) and AreUnitsCurrentlyAllied("player", unitTag) then
                g_recentTargets:AddRecentPlayer(GetUnitName(unitTag))
            end
        end

        local function OnReticleTargetChanged()
            TryAddRecentTarget("reticleover")
        end

        local function OnReticleTargetPlayerChanged()
            TryAddRecentTarget("reticleoverplayer")
        end

        EVENT_MANAGER:RegisterForEvent("AutoComplete", EVENT_CHAT_MESSAGE_CHANNEL, OnChatMessage)
        EVENT_MANAGER:RegisterForEvent("AutoComplete", EVENT_UNIT_CREATED, OnUnitCreated)
        EVENT_MANAGER:RegisterForEvent("AutoComplete", EVENT_MAIL_INBOX_UPDATE, OnInboxUpdate)
        EVENT_MANAGER:RegisterForEvent("AutoComplete", EVENT_TRADE_INVITE_ACCEPTED, OnTradeWindowInviteAccepted)
        EVENT_MANAGER:RegisterForEvent("AutoComplete", EVENT_RETICLE_TARGET_CHANGED, OnReticleTargetChanged)
        EVENT_MANAGER:RegisterForEvent("AutoComplete", EVENT_RETICLE_TARGET_PLAYER_CHANGED, OnReticleTargetPlayerChanged)

        local defaults = {
            RecentInteractions = {}
        }
        local db = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 3, "AutoComplete", defaults)

        g_recentInteractions = RecentPlayerTracker:New(45, db.RecentInteractions)

        EVENT_MANAGER:UnregisterForEvent("AutoComplete", EVENT_ADD_ON_LOADED)
    end
end

EVENT_MANAGER:RegisterForEvent("AutoComplete", EVENT_ADD_ON_LOADED, Initialize)
