-----------------
-- Raid Leaderboards
-----------------
RAID_LEADERBOARD_SELECT_OPTION_DEFAULT = 0
RAID_LEADERBOARD_SELECT_OPTION_SKIP_WEEKLY = 1
RAID_LEADERBOARD_SELECT_OPTION_PREFER_WEEKLY = 2

RAID_LEADERBOARD_SYSTEM_NAME = "raidLeaderboards"

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

ZO_RaidLeaderboardsManager_Shared = ZO_LeaderboardBase_Shared:Subclass()

function ZO_RaidLeaderboardsManager_Shared:New(...)
    return ZO_LeaderboardBase_Shared.New(self, ...)
end

function ZO_RaidLeaderboardsManager_Shared:Initialize(...)
    ZO_LeaderboardBase_Shared.Initialize(self, ...)

    self.raidListNodes = {}
end

function ZO_RaidLeaderboardsManager_Shared:RegisterForEvents(control)
    local function SelectCurrentRaid()
        local currentRaidId = GetCurrentParticipatingRaidId()
        if currentRaidId > 0 then
            self:SelectRaidById(currentRaidId, RAID_LEADERBOARD_SELECT_OPTION_PREFER_WEEKLY)
        end
    end

    control:RegisterForEvent(EVENT_RAID_LEADERBOARD_PLAYER_DATA_CHANGED, function() self:UpdatePlayerInfo() end)
    control:RegisterForEvent(EVENT_RAID_PARTICIPATION_UPDATE, function() SelectCurrentRaid(); self:UpdatePlayerParticipationStatus() end)
    control:RegisterForEvent(EVENT_RAID_TIMER_STATE_UPDATE, function() self:UpdatePlayerParticipationStatus() end)
    control:RegisterForEvent(EVENT_RAID_TRIAL_SCORE_UPDATE, function() self:UpdateRaidScore() end)
    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, SelectCurrentRaid)
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
                return GetTrialLeaderboardEntryInfo(categoryData.raidIndex, entryIndex)
            end
        elseif categoryData.raidCategory == RAID_CATEGORY_CHALLENGE then
            --We keep track of these gates for the info function that'll be called later
            local classId, classIndex = GetClassIdAndIndexFromTotalIndex(entryIndex, categoryData)
        
            if categoryData.isWeekly then
                return GetChallengeOfTheWeekLeaderboardEntryInfo(classId, classIndex)
            else
                return GetChallengeLeaderboardEntryInfo(categoryData.raidIndex, classId, classIndex)
            end
        end
        return nil
    end

    local function GetRaidLeaderboardTitleName(categoryData)
        if categoryData.isWeekly then
            return zo_strformat(SI_RAID_LEADERBOARDS_WEEKLY_RAID, GetRaidOfTheWeekLeaderboardInfo(categoryData.raidCategory))
        else
            return zo_strformat(SI_RAID_LEADERBOARDS_RAID_NAME, GetRaidLeaderboardInfo(categoryData.raidCategory, categoryData.raidIndex))
        end
    end

    local function GetRaidLeaderboardEntryConsoleIdRequestParams(entryIndex, categoryData)
        if categoryData.raidCategory == RAID_CATEGORY_TRIAL then
            if categoryData.isWeekly then
                return ZO_ID_REQUEST_TYPE_TRIAL_OF_THE_WEEK_LEADERBOARD, entryIndex
            else
                return ZO_ID_REQUEST_TYPE_TRIAL_LEADERBOARD, categoryData.raidIndex, entryIndex
            end
        elseif categoryData.raidCategory == RAID_CATEGORY_CHALLENGE then
            local classId, classIndex = GetClassIdAndIndexFromTotalIndex(entryIndex, categoryData)

            if categoryData.isWeekly then
                return ZO_ID_REQUEST_TYPE_CHALLENGE_OF_THE_WEEK_LEADERBOARD, classId, classIndex
            else
                return ZO_ID_REQUEST_TYPE_CHALLENGE_LEADERBOARD, categoryData.raidIndex, classId, classIndex
            end
        end
        return nil
    end

    function ZO_RaidLeaderboardsManager_Shared:AddCategoriesToParentSystem()
        self.headers = {}
        ZO_ClearNumericallyIndexedTable(self.raidListNodes)

        local function GetNumEntries(categoryData)
            self:UpdateAllInfo()

            if categoryData.raidCategory == RAID_CATEGORY_TRIAL then
                if categoryData.isWeekly then
                    return GetNumTrialOfTheWeekLeaderboardEntries()
                else
                    return GetNumTrialLeaderboardEntries(categoryData.raidIndex)
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
                        count = count + GetNumChallengeLeaderboardEntries(categoryData.raidIndex, classId)
                    end
                    table.insert(categoryData.classGates, { count = count,  classId = classId})
                end

                return count
            end

            return 0
        end

        local function AddEntry(parent, name, categoryData, leaderboardRankType)
            local node = self.leaderboardSystem:AddEntry(self, name, GetRaidLeaderboardTitleName, parent, categoryData, GetNumEntries, nil, GetSingleRaidEntryInfo, nil, GetString(SI_RAID_LEADERBOARDS_HEADER_SCORE), GetRaidLeaderboardEntryConsoleIdRequestParams, "EsoUI/Art/Leaderboards/gamepad/gp_leaderBoards_menuIcon_trial.dds", leaderboardRankType)
            if node then
                local nodeData = node.GetData and node:GetData() or node
                nodeData.raidId = categoryData.raidId
                nodeData.isWeekly = categoryData.isWeekly
                nodeData.raidCategory = categoryData.raidCategory
                nodeData.raidIndex = categoryData.raidIndex
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
                local raidName, raidId = GetRaidOfTheWeekLeaderboardInfo(raidCategory)
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
                for raidIndex = 1, numRaids do
                    local raidName, raidId = GetRaidLeaderboardInfo(raidCategory, raidIndex)
                    raidName = zo_strformat(SI_RAID_LEADERBOARDS_RAID_NAME, raidName)
                    local categoryData = 
                    {
                        raidId = raidId,
                        isWeekly = false,
                        raidCategory = raidCategory,
                        raidIndex = raidIndex,
                    }
                    AddEntry(parent, raidName, categoryData, leaderboardRankType)
                end
            end

        end
    end
end

function ZO_RaidLeaderboardsManager_Shared:SelectRaidById(raidId, selectOption, openLeaderboards)
    selectOption = selectOption or RAID_LEADERBOARD_SELECT_OPTION_DEFAULT

    local selectedNode

    for _, node in ipairs(self.raidListNodes) do
        local nodeData = node.GetData and node:GetData() or node
        if nodeData.raidId == raidId then
            if selectOption == RAID_LEADERBOARD_SELECT_OPTION_SKIP_WEEKLY then
                if not nodeData.isWeekly then
                    selectedNode = node
                    break
                end
            elseif selectOption == RAID_LEADERBOARD_SELECT_OPTION_PREFER_WEEKLY then
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
                self.timerLabelIdentifier = SI_RAID_LEADERBOARDS_CLOSES_IN_TIMER
                self.timerLabelData = ZO_FormatTime(secsUntilEnd, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
            elseif secsUntilNextStart > 0 then
                self.timerLabelIdentifier = SI_RAID_LEADERBOARDS_REOPENS_IN_TIMER
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
            rank, bestScore = GetRaidOfTheWeekLeaderboardLocalPlayerInfo(self.selectedSubType.raidCategory)
        else
            rank, bestScore = GetRaidLeaderboardLocalPlayerInfo(self.selectedSubType.raidCategory, self.selectedSubType.raidIndex)
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
        self.participating, self.credited = GetPlayerRaidParticipationInfo(self.selectedSubType.raidCategory, self.selectedSubType.raidIndex)
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
        raidInProgress, raidComplete = GetPlayerRaidProgressInfo(self.selectedSubType.raidCategory, self.selectedSubType.raidIndex)
    end

    if raidInProgress or raidComplete then
        self.currrentScoreData = GetCurrentRaidScore()
    else
        self.currrentScoreData = GetString(SI_RAID_LEADERBOARDS_NO_CURRENT_SCORE)
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