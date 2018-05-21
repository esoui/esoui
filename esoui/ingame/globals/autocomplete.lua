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

local function IncludeOrExcludePlayersFromRecentPlayerTracker(recentPlayerTracker, results, include)
    local isDecoratedDisplayName
    local isConsoleUI = IsConsoleUI()
    for name in pairs(recentPlayerTracker:GetPlayers()) do
        isDecoratedDisplayName = IsDecoratedDisplayName(name)
        if isDecoratedDisplayName then
            name = ZO_FormatUserFacingDisplayName(name)
        end

        if not isConsoleUI or isDecoratedDisplayName then
            ZO_AutoComplete.IncludeOrExcludeResult(results, name, include)
        end
    end
end

AUTO_COMPLETE_FLAG_RECENT = ZO_AutoComplete.AddFlag(function(results, input, onlineOnly, include)
    IncludeOrExcludePlayersFromRecentPlayerTracker(g_recentInteractions, results, include)
end)

AUTO_COMPLETE_FLAG_RECENT_TARGET = ZO_AutoComplete.AddFlag(function(results, input, onlineOnly, include)
    IncludeOrExcludePlayersFromRecentPlayerTracker(g_recentTargets, results, include)
end)

AUTO_COMPLETE_FLAG_RECENT_CHAT = ZO_AutoComplete.AddFlag(function(results, input, onlineOnly, include)
    IncludeOrExcludePlayersFromRecentPlayerTracker(g_recentChat, results, include)
end)

AUTO_COMPLETE_FLAG_GUILD_NAMES = ZO_AutoComplete.AddFlag(function(results, input, onlineOnly, include)
    for i = 1, GetNumGuilds() do
        local guildId = GetGuildId(i)
        local guildName = GetGuildName(guildId)
        ZO_AutoComplete.IncludeOrExcludeResult(results, zo_strformat("<<1>>", guildName), include)
    end
end)

local function Initialize(event, name)
    if name == "ZO_Ingame" then
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

        EVENT_MANAGER:UnregisterForEvent("AutoCompleteIngame", EVENT_ADD_ON_LOADED)
    end
end

EVENT_MANAGER:RegisterForEvent("AutoCompleteIngame", EVENT_ADD_ON_LOADED, Initialize)
