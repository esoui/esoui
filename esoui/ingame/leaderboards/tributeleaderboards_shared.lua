---------------
-- Tribute Leaderboards
---------------
ZO_TRIBUTE_LEADERBOARD_SYSTEM_NAME = "tributeLeaderboards"

ZO_TributeLeaderboardsManager_Shared = ZO_LeaderboardBase_Shared:Subclass()

function ZO_TributeLeaderboardsManager_Shared:Initialize(...)
    ZO_LeaderboardBase_Shared.Initialize(self, ...)

    self.tributeListNodes = {}
    self.control:SetHandler("OnUpdate", function(_, currentTime) self:TimerLabelOnUpdate(currentTime) end)
end

do
    local function GetSingleTributeEntryInfo(entryIndex, tributeLeaderboardType)
        return GetTributeLeaderboardEntryInfo(tributeLeaderboardType, entryIndex)
    end

    local function GetTributeLeaderboardEntryConsoleIdRequestParams(entryIndex, tributeLeaderboardType)
        return ZO_ID_REQUEST_TYPE_TRIBUTE_LEADERBOARD, tributeLeaderboardType, entryIndex
    end

    local function GetNextTributeLeaderboardTypeIter(state, lastTributeLeaderboardType)
        return GetNextTributeLeaderboardType(lastTributeLeaderboardType)
    end

    function ZO_TributeLeaderboardsManager_Shared:AddCategoriesToParentSystem()
        ZO_ClearNumericallyIndexedTable(self.tributeListNodes)

        local function UpdatePlayerInfo()
            self:UpdatePlayerInfo()
        end

        local function GetNumEntries(tributeLeaderboardType)
            return GetNumTributeLeaderboardEntries(tributeLeaderboardType)
        end

        local function AddEntry(parent, name, tributeLeaderboardType)
            local NO_TITLE_NAME = nil
            local NO_MAX_RANK_FUNCTION = nil
            local NO_POINTS_RANK_FUNCTION = nil
            local node = self.leaderboardSystem:AddEntry(self, name, NO_TITLE_NAME, parent, tributeLeaderboardType, GetNumEntries, NO_MAX_RANK_FUNCTION, GetSingleTributeEntryInfo, NO_POINTS_RANK_FUNCTION, GetString(SI_LEADERBOARDS_HEADER_POINTS), GetTributeLeaderboardEntryConsoleIdRequestParams, ZO_TRIBUTE_ICONS_GAMEPAD.normal, LEADERBOARD_TYPE_TRIBUTE, UpdatePlayerInfo)
            if node then
                local nodeData = node.GetData and node:GetData() or node
                nodeData.tributeLeaderboardType = tributeLeaderboardType
            end
            table.insert(self.tributeListNodes, node)
            return node
        end

        local createHeader = true
        for tributeLeaderboardType in GetNextTributeLeaderboardTypeIter do
            if createHeader then
                self.header = self.leaderboardSystem:AddCategory(GetString(SI_TRIBUTE_LEADERBOARDS_CATEGORIES_HEADER), ZO_TRIBUTE_ICONS_KEYBOARD.up, ZO_TRIBUTE_ICONS_KEYBOARD.down, ZO_TRIBUTE_ICONS_KEYBOARD.over)
                createHeader = false
            end

            AddEntry(self.header, GetString("SI_TRIBUTELEADERBOARDTYPE", tributeLeaderboardType), tributeLeaderboardType)
        end
    end
end

do
    local timerLabelLastUpdateSecs = 0
    local UPDATE_INTERVAL_SECS = 1

    function ZO_TributeLeaderboardsManager_Shared:TimerLabelOnUpdate(currentTime)
        if currentTime - timerLabelLastUpdateSecs >= UPDATE_INTERVAL_SECS then
            local secsUntilEnd, secsUntilNextStart = GetTributeLeaderboardsSchedule()

            if secsUntilEnd > 0 then
                self.timerLabelIdentifier = SI_LEADERBOARDS_CLOSES_IN_TIMER
                self.timerLabelData = ZO_FormatTime(secsUntilEnd, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
            elseif secsUntilNextStart > 0 then
                self.timerLabelIdentifier = SI_LEADERBOARDS_REOPENS_IN_TIMER
                self.timerLabelData = ZO_FormatTime(secsUntilNextStart, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
            else
                self.timerLabelIdentifier = nil
                self.timerLabelData = nil
            end

            timerLabelLastUpdateSecs = currentTime

            self:RefreshHeaderTimer()
        end
    end
end

function ZO_TributeLeaderboardsManager_Shared:UpdatePlayerInfo()
    if not self.selectedSubType then
        return
    end

    local currentRank, currentScore = GetTributeLeaderboardLocalPlayerInfo(self.selectedSubType)
    local hasRank = currentRank > 0
    local hasScore = currentScore > 0

    self.currentRankData = hasRank and currentRank or nil
    self.currentScoreData = hasScore and currentScore or nil

    self:RefreshHeaderPlayerInfo()
end

function ZO_TributeLeaderboardsManager_Shared:OnSubtypeSelected(subType)
    ZO_LeaderboardBase_Shared.OnSubtypeSelected(self, subType)

    self:UpdatePlayerInfo()
end

function ZO_TributeLeaderboardsManager_Shared:SendLeaderboardQuery()
    if not self.selectedSubType then
        return
    end

    self.requestedTributeType = self.selectedSubType
    LEADERBOARD_LIST_MANAGER:QueryLeaderboardData(PENDING_LEADERBOARD_DATA_TYPE.TRIBUTE, self:GenerateRequestData())
end

function ZO_TributeLeaderboardsManager_Shared:GenerateRequestData()
    local data =
    { 
        tributeType = self.requestedTributeType,
    }
    return data
end

function ZO_TributeLeaderboardsManager_Shared:HandleFilterDropdownChanged()
    -- Returning false to signify no special handling required
    return false
end