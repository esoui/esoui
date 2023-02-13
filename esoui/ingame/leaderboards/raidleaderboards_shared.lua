-----------------
-- Raid Leaderboards
-----------------
ZO_RAID_LEADERBOARD_SELECT_OPTION_DEFAULT = 0
ZO_RAID_LEADERBOARD_SELECT_OPTION_SKIP_WEEKLY = 1
ZO_RAID_LEADERBOARD_SELECT_OPTION_PREFER_WEEKLY = 2

local RAID_LEADERBOARD_MAX_RANK_ALLOWED = 100

ZO_RAID_LEADERBOARD_SYSTEM_NAME = "raidLeaderboards"

local HEADER_ICONS =
{
    [RAID_CATEGORY_TRIAL] =
    {
        up = "EsoUI/Art/Journal/leaderboard_indexIcon_raids_up.dds", 
        down = "EsoUI/Art/Journal/leaderboard_indexIcon_raids_down.dds", 
        over = "EsoUI/Art/Journal/leaderboard_indexIcon_raids_over.dds",
    },
    [RAID_CATEGORY_CHALLENGE] =
    {
        up = "EsoUI/Art/Journal/leaderboard_indexIcon_challenge_up.dds", 
        down = "EsoUI/Art/Journal/leaderboard_indexIcon_challenge_down.dds", 
        over = "EsoUI/Art/Journal/leaderboard_indexIcon_challenge_over.dds",
    },
}

local LEADERBOARD_RANK_MAP =
{
    [RAID_CATEGORY_TRIAL] = LEADERBOARD_TYPE_OVERALL,
    [RAID_CATEGORY_CHALLENGE] = LEADERBOARD_TYPE_CLASS,
}

function ZO_GetNextRaidLeaderboardIdIter(raidCategory)
    return function(state, lastRaidId)
        return GetNextRaidLeaderboardId(raidCategory, lastRaidId)
    end
end

ZO_RaidLeaderboardsManager_Shared = ZO_LeaderboardBase_Shared:Subclass()

function ZO_RaidLeaderboardsManager_Shared:Initialize(...)
    ZO_LeaderboardBase_Shared.Initialize(self, ...)

    self.raidListNodes = {}
end

function ZO_RaidLeaderboardsManager_Shared:RegisterForEvents()
    local function SelectCurrentRaid()
        local currentRaidId = GetCurrentParticipatingRaidId()
        if currentRaidId > 0 then
            self:SelectRaidById(currentRaidId, ZO_RAID_LEADERBOARD_SELECT_OPTION_PREFER_WEEKLY)
        end
    end
    
    local control = self.control
    control:RegisterForEvent(EVENT_RAID_LEADERBOARD_PLAYER_DATA_CHANGED, function() self:UpdatePlayerInfo() end)
    control:RegisterForEvent(EVENT_RAID_PARTICIPATION_UPDATE, function() SelectCurrentRaid(); self:UpdatePlayerParticipationStatus() end)
    control:RegisterForEvent(EVENT_RAID_TIMER_STATE_UPDATE, function() self:UpdatePlayerParticipationStatus() end)
    control:RegisterForEvent(EVENT_RAID_TRIAL_SCORE_UPDATE, function() self:UpdateRaidScore() end)
    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, SelectCurrentRaid)
    control:RegisterForEvent(EVENT_RAID_OF_THE_WEEK_TURNOVER, function() self:HandleWeeklyTurnover() end)
    control:RegisterForEvent(EVENT_RAID_OF_THE_WEEK_INFO_RECEIVED, function() self:HandleWeeklyInfoReceived() end)
end

do
    local function GetClassIdAndIndexFromTotalIndex(entryIndex, categoryData)
        local classId = 0
        local classIndex = entryIndex
        local previousGate
        for i, gate in ipairs(categoryData.classGates) do
            if entryIndex <= gate.count then
                classId = gate.classId
                if previousGate then
                    classIndex = classIndex - previousGate.count
                end
                break
            end
            previousGate = gate
        end
        return classId, classIndex
    end

    local function GetSingleRaidEntryInfo(entryIndex, categoryData)
        if categoryData.raidCategory == RAID_CATEGORY_TRIAL then
            if categoryData.isWeekly then
                return GetTrialOfTheWeekLeaderboardEntryInfo(entryIndex)
            else
                return GetTrialLeaderboardEntryInfo(categoryData.raidId, entryIndex)
            end
        elseif categoryData.raidCategory == RAID_CATEGORY_CHALLENGE then
            --We keep track of these gates for the info function that'll be called later
            local classId, classIndex = GetClassIdAndIndexFromTotalIndex(entryIndex, categoryData)
        
            if categoryData.isWeekly then
                return GetChallengeOfTheWeekLeaderboardEntryInfo(classId, classIndex)
            else
                return GetChallengeLeaderboardEntryInfo(categoryData.raidId, classId, classIndex)
            end
        end
        return nil
    end

    local function GetRaidLeaderboardTitleName(categoryData)
        if categoryData.isWeekly then
            local name = GetRaidOfTheWeekLeaderboardInfo(categoryData.raidCategory)
            if name == "" then
                return GetString(SI_RAID_LEADERBOARDS_WEEKLY)
            else
                return zo_strformat(SI_RAID_LEADERBOARDS_WEEKLY_RAID, name)
            end
        else
            return zo_strformat(SI_RAID_LEADERBOARDS_RAID_NAME, GetRaidLeaderboardName(categoryData.raidId))
        end
    end

    local function GetRaidLeaderboardEntryConsoleIdRequestParams(entryIndex, categoryData)
        if categoryData.raidCategory == RAID_CATEGORY_TRIAL then
            if categoryData.isWeekly then
                return ZO_ID_REQUEST_TYPE_TRIAL_OF_THE_WEEK_LEADERBOARD, entryIndex
            else
                return ZO_ID_REQUEST_TYPE_TRIAL_LEADERBOARD, categoryData.raidId, entryIndex
            end
        elseif categoryData.raidCategory == RAID_CATEGORY_CHALLENGE then
            local classId, classIndex = GetClassIdAndIndexFromTotalIndex(entryIndex, categoryData)

            if categoryData.isWeekly then
                return ZO_ID_REQUEST_TYPE_CHALLENGE_OF_THE_WEEK_LEADERBOARD, classId, classIndex
            else
                return ZO_ID_REQUEST_TYPE_CHALLENGE_LEADERBOARD, categoryData.raidId, classId, classIndex
            end
        end
        return nil
    end

    function ZO_RaidLeaderboardsManager_Shared:AddCategoriesToParentSystem()
        self.headers = {}
        ZO_ClearNumericallyIndexedTable(self.raidListNodes)

        local function UpdatePlayerInfo()
            self:UpdateAllInfo()
        end

        local function GetNumEntries(categoryData)
            if categoryData.raidCategory == RAID_CATEGORY_TRIAL then
                if categoryData.isWeekly then
                    return GetNumTrialOfTheWeekLeaderboardEntries()
                else
                    return GetNumTrialLeaderboardEntries(categoryData.raidId)
                end
            elseif categoryData.raidCategory == RAID_CATEGORY_CHALLENGE then
                local count = 0
                --We keep track of these gates for the info function that'll be called later
                if categoryData.classGates then
                    ZO_ClearNumericallyIndexedTable(categoryData.classGates)
                else
                    categoryData.classGates = {}
                end
            
                for i = 1, GetNumClasses() do
                    local classId = GetClassInfo(i)
                    if categoryData.isWeekly then
                        count = count + GetNumChallengeOfTheWeekLeaderboardEntries(classId)
                    else
                        count = count + GetNumChallengeLeaderboardEntries(categoryData.raidId, classId)
                    end
                    table.insert(categoryData.classGates, { count = count,  classId = classId})
                end

                return count
            end

            return 0
        end

        local function GetMaxRank()
            return RAID_LEADERBOARD_MAX_RANK_ALLOWED
        end

        local function AddEntry(parent, name, categoryData, leaderboardRankType)
            local NO_POINTS_FORMAT_FUNCTION = nil
            local node = self.leaderboardSystem:AddEntry(self, name, GetRaidLeaderboardTitleName, parent, categoryData, GetNumEntries, GetMaxRank, GetSingleRaidEntryInfo, NO_POINTS_FORMAT_FUNCTION, GetString(SI_LEADERBOARDS_HEADER_SCORE), GetRaidLeaderboardEntryConsoleIdRequestParams, "EsoUI/Art/Leaderboards/gamepad/gp_leaderBoards_menuIcon_trial.dds", leaderboardRankType, UpdatePlayerInfo)
            if node then
                local nodeData = node.GetData and node:GetData() or node
                nodeData.raidId = categoryData.raidId
                nodeData.isWeekly = categoryData.isWeekly
                nodeData.raidCategory = categoryData.raidCategory
            end
            table.insert(self.raidListNodes, node)
            return node
        end

        --Go through every category
        for raidCategory = RAID_CATEGORY_TRIAL, RAID_CATEGORY_CHALLENGE do
            local numRaids, hasWeekly = GetNumRaidLeaderboards(raidCategory)
            local leaderboardRankType = LEADERBOARD_RANK_MAP[raidCategory]

            --Create the category header
            if hasWeekly or (numRaids > 0) then
                if not self.headers[raidCategory] then
                    self.headers[raidCategory] = self.leaderboardSystem:AddCategory(GetString("SI_RAIDCATEGORY", raidCategory), HEADER_ICONS[raidCategory].up, HEADER_ICONS[raidCategory].down, HEADER_ICONS[raidCategory].over)
                end
            end

            local parent = self.headers[raidCategory]

            --Set up the weekly first
            if hasWeekly then
                local _, raidId = GetRaidOfTheWeekLeaderboardInfo(raidCategory)
                local nodeName = GetString(SI_RAID_LEADERBOARDS_WEEKLY)
                local categoryData = 
                {
                    raidId = raidId,
                    isWeekly = true,
                    raidCategory = raidCategory,
                }
                AddEntry(parent, nodeName, categoryData, leaderboardRankType)
            end

            --Set up every other regular raid for this category
            if numRaids > 0 then
                local entries = {}
                for raidId in ZO_GetNextRaidLeaderboardIdIter(raidCategory) do
                    local raidName = GetRaidLeaderboardName(raidId)
                    raidName = zo_strformat(SI_RAID_LEADERBOARDS_RAID_NAME, raidName)
                    local uiSortIndex = GetRaidLeaderboardUISortIndex(raidCategory, raidId)
                    local categoryData = 
                    {
                        raidName = raidName,
                        raidId = raidId,
                        isWeekly = false,
                        raidCategory = raidCategory,
                        uiSortIndex = uiSortIndex,
                    }

                    table.insert(entries, categoryData)
                end

                table.sort(entries, function(a,b) return a.uiSortIndex < b.uiSortIndex end)

                for _, categoryData in ipairs(entries) do
                    AddEntry(parent, categoryData.raidName, categoryData, leaderboardRankType)
                end
            end
        end
    end
end

function ZO_RaidLeaderboardsManager_Shared:SelectRaidById(raidId, selectOption, openLeaderboards)
    selectOption = selectOption or ZO_RAID_LEADERBOARD_SELECT_OPTION_DEFAULT

    local selectedNode

    for _, node in ipairs(self.raidListNodes) do
        local nodeData = node.GetData and node:GetData() or node
        if nodeData.raidId == raidId then
            if selectOption == ZO_RAID_LEADERBOARD_SELECT_OPTION_SKIP_WEEKLY then
                if not nodeData.isWeekly then
                    selectedNode = node
                    break
                end
            elseif selectOption == ZO_RAID_LEADERBOARD_SELECT_OPTION_PREFER_WEEKLY then
                selectedNode = node
                if nodeData.isWeekly then
                    break
                end
            else
                selectedNode = node
                break
            end
        end
    end

    if selectedNode then
        self.leaderboardSystem:SelectNode(selectedNode)
        if openLeaderboards then
            SCENE_MANAGER:Push(self.leaderboardScene:GetName())
        end
    end
end

do
    local timerLabelLastUpdateSecs = 0
    local UPDATE_INTERVAL_SECS = 1

    function ZO_RaidLeaderboardsManager_Shared:TimerLabelOnUpdate(currentTime)
        if currentTime - timerLabelLastUpdateSecs >= UPDATE_INTERVAL_SECS then
            local secsUntilEnd, secsUntilNextStart = GetRaidOfTheWeekTimes()

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

    function ZO_RaidLeaderboardsManager_Shared:UpdatePlayerInfo()
        if not self.selectedSubType then
            return
        end

        local isWeekly = self.selectedSubType.isWeekly
        local rank, bestScore
        if isWeekly then
            -- Not currently populating but no major changes were made to this part of the code
            -- TODO: Confirm best score population on account that has actually completed a raid.
            rank, bestScore = GetRaidOfTheWeekLeaderboardLocalPlayerInfo(self.selectedSubType.raidCategory)
        else
            rank, bestScore = GetRaidLeaderboardLocalPlayerInfo(self.selectedSubType.raidId)
        end

        self.currentRankData = rank and rank > 0 and rank
        self.currentScoreData = bestScore and bestScore > 0 and bestScore

        if isWeekly then
            self.control:SetHandler("OnUpdate", function(_, currentTime) self:TimerLabelOnUpdate(currentTime) end)
        else
            timerLabelLastUpdateSecs = 0
            self.control:SetHandler("OnUpdate", nil)
            self.timerLabelIdentifier = nil
            self.timerLabelData = nil
            self:RefreshHeaderTimer()
        end

        self:RefreshHeaderPlayerInfo(isWeekly)
    end
end

function ZO_RaidLeaderboardsManager_Shared:UpdatePlayerParticipationStatus()
    if not self.selectedSubType then
        return
    end

    if self.selectedSubType.isWeekly then
        self.participating, self.credited = GetPlayerRaidOfTheWeekParticipationInfo(self.selectedSubType.raidCategory)
    else
        self.participating, self.credited = GetPlayerRaidParticipationInfo(self.selectedSubType.raidId)
    end

    self:UpdateRaidScore()
end

function ZO_RaidLeaderboardsManager_Shared:UpdateRaidScore()
    if not self.selectedSubType then
        return
    end

    local raidInProgress, raidComplete
    if self.selectedSubType.isWeekly then
        raidInProgress, raidComplete = GetPlayerRaidOfTheWeekProgressInfo(self.selectedSubType.raidCategory)
    else
        raidInProgress, raidComplete = GetPlayerRaidProgressInfo(self.selectedSubType.raidId)
    end

    if raidInProgress or raidComplete then
        self.currentScoreData = GetCurrentRaidScore()
    else
        self.currentScoreData = GetString(SI_LEADERBOARDS_NO_CURRENT_SCORE)
    end
end

function ZO_RaidLeaderboardsManager_Shared:OnSubtypeSelected(subType)
    ZO_LeaderboardBase_Shared.OnSubtypeSelected(self, subType)

    self:UpdateAllInfo()
end

function ZO_RaidLeaderboardsManager_Shared:UpdateAllInfo()
    self:UpdatePlayerInfo()
    self:UpdatePlayerParticipationStatus()
end

function ZO_RaidLeaderboardsManager_Shared:SendLeaderboardQuery()
    if not self.selectedSubType then
        return
    end

    self.requestedRaidCategory = self.selectedSubType.raidCategory
    self.requestedRaidId = self.selectedSubType.isWeekly and 0 or self.selectedSubType.raidId

    local readyState = nil
    if self.requestedRaidCategory == RAID_CATEGORY_CHALLENGE then
        if IsInGamepadPreferredMode() then
            self.requestedClassId = GAMEPAD_LEADERBOARDS:GetSelectedClassFilter()
        else
            self.requestedClassId = LEADERBOARDS:GetSelectedClassFilter()
        end
    else
        self.requestedClassId = nil
    end
    LEADERBOARD_LIST_MANAGER:QueryLeaderboardData(PENDING_LEADERBOARD_DATA_TYPE.RAID, self:GenerateRequestData())
end

function ZO_RaidLeaderboardsManager_Shared:GenerateRequestData()
    local data =
    { 
        raidId = self.requestedRaidId,
        raidCategory = self.requestedRaidCategory,
        classId = self.requestedClassId,
    }
    return data
end

function ZO_RaidLeaderboardsManager_Shared:HandleWeeklyTurnover()
    if self:IsSystemShowing() and self.requestedRaidId == 0 then
        self:SendLeaderboardQuery()
    end
end

function ZO_RaidLeaderboardsManager_Shared:HandleWeeklyInfoReceived()
    if not self.selectedSubType then
        return
    end

    if self:IsSystemShowing() and self.selectedSubType.isWeekly then
        local name = GetRaidOfTheWeekLeaderboardInfo(self.selectedSubType.raidCategory)
        local formattedName = zo_strformat(SI_RAID_LEADERBOARDS_WEEKLY_RAID, name)
        if IsInGamepadPreferredMode() then
            GAMEPAD_LEADERBOARDS:SetActiveLeaderboardTitle(formattedName)
        else
            LEADERBOARDS:SetActiveLeaderboardTitle(formattedName)
        end
    end
end

function ZO_RaidLeaderboardsManager_Shared:HandleFilterDropdownChanged()
    if self.selectedSubType.raidCategory == RAID_CATEGORY_CHALLENGE then
        self:SendLeaderboardQuery()
        return true
    end    
    return false
end

ZO_RaidLeaderboardsManager_Shared.GetFragment = ZO_RaidLeaderboardsManager_Shared:MUST_IMPLEMENT()

function ZO_RaidLeaderboardsManager_Shared:IsSystemShowing()
    return self:GetFragment():IsShowing()
end