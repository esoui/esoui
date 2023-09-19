-----------------
-- Endless Dungeon Leaderboards
-----------------

ZO_ENDLESS_DUNGEON_LEADERBOARD_SELECT_OPTION =
{
    DEFAULT = 0,
    SKIP_WEEKLY = 1,
    PREFER_WEEKLY = 2,
}

local ENDLESS_DUNGEON_LEADERBOARD_MAX_RANK_ALLOWED = 200

local ENDLESS_DUNGEON_HEADER_ICONS =
{
    up = "EsoUI/Art/Journal/leaderboard_indexIcon_endlessDungeon_up.dds", 
    down = "EsoUI/Art/Journal/leaderboard_indexIcon_endlessDungeon_down.dds",
    over = "EsoUI/Art/Journal/leaderboard_indexIcon_endlessDungeon_over.dds",
}

local LEADERBOARD_RANK_MAP =
{
    [ENDLESS_DUNGEON_GROUP_TYPE_DUO] = LEADERBOARD_TYPE_ENDLESS_DUNGEON_OVERALL,
    [ENDLESS_DUNGEON_GROUP_TYPE_SOLO] = LEADERBOARD_TYPE_ENDLESS_DUNGEON_CLASS,
}

ZO_EndlessDungeonLeaderboardsManager_Shared = ZO_LeaderboardBase_Shared:Subclass()

function ZO_EndlessDungeonLeaderboardsManager_Shared:Initialize(...)
    ZO_LeaderboardBase_Shared.Initialize(self, ...)

    self.endlessDungeonListNodes = {}
end

function ZO_EndlessDungeonLeaderboardsManager_Shared:RegisterForEvents()
    local function SelectCurrentEndlessDungeon()
        if ENDLESS_DUNGEON_MANAGER:IsEndlessDungeonStarted() then
            local endlessDungeonGroupType = GetEndlessDungeonGroupType()
            self:SelectEndlessDungeonById(DEFAULT_ENDLESS_DUNGEON_ID, endlessDungeonGroupType, ZO_ENDLESS_DUNGEON_LEADERBOARD_SELECT_OPTION.PREFER_WEEKLY)
        end
    end

    local control = self.control
    control:RegisterForEvent(EVENT_ENDLESS_DUNGEON_LEADERBOARD_PLAYER_DATA_CHANGED, function() self:UpdatePlayerInfo() end)
    control:RegisterForEvent(EVENT_ENDLESS_DUNGEON_TIMER_STATE_UPDATE, function() self:UpdatePlayerParticipationStatus() end)
    control:RegisterForEvent(EVENT_ENDLESS_DUNGEON_SCORE_UPDATED, function() self:UpdateEndlessDungeonScore() end)
    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, SelectCurrentEndlessDungeon)
    control:RegisterForEvent(EVENT_ENDLESS_DUNGEON_OF_THE_WEEK_TURNOVER, function() self:HandleWeeklyTurnover() end)
    ENDLESS_DUNGEON_MANAGER:RegisterCallback(EVENT_ENDLESS_DUNGEON_STARTED, function()
        SelectCurrentEndlessDungeon()
        self:UpdatePlayerParticipationStatus()
    end)
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

    local function GetSingleEndlessDungeonEntryInfo(entryIndex, categoryData)
        if categoryData.endlessDungeonGroupType == ENDLESS_DUNGEON_GROUP_TYPE_DUO then
            if categoryData.isWeekly then
                return GetEndlessDungeonOfTheWeekDuoLeaderboardEntryInfo(entryIndex)
            else
            	return GetEndlessDungeonDuoLeaderboardEntryInfo(categoryData.endlessDungeonId, entryIndex)
            end
        elseif categoryData.endlessDungeonGroupType == ENDLESS_DUNGEON_GROUP_TYPE_SOLO then
            --We keep track of these gates for the info function that'll be called later
            local classId, classIndex = GetClassIdAndIndexFromTotalIndex(entryIndex, categoryData)
            if categoryData.isWeekly then
                return GetEndlessDungeonOfTheWeekSoloLeaderboardEntryInfo(classId, classIndex)
            else
                return GetEndlessDungeonSoloLeaderboardEntryInfo(categoryData.endlessDungeonId, classId, classIndex)
            end
        end
        return nil
    end

    local function GetEndlessDungeonLeaderboardEntryConsoleIdRequestParams(entryIndex, categoryData)
        if categoryData.endlessDungeonGroupType == ENDLESS_DUNGEON_GROUP_TYPE_DUO then
            if categoryData.isWeekly then
                return ZO_ID_REQUEST_TYPE_ENDLESS_DUNGEON_OF_THE_WEEK_DUO_LEADERBOARD, entryIndex
            else
            	return ZO_ID_REQUEST_TYPE_ENDLESS_DUNGEON_DUO_LEADERBOARD, categoryData.endlessDungeonId, entryIndex
            end
        elseif categoryData.endlessDungeonGroupType == ENDLESS_DUNGEON_GROUP_TYPE_SOLO then
            local classId, classIndex = GetClassIdAndIndexFromTotalIndex(entryIndex, categoryData)

            if categoryData.isWeekly then
                return ZO_ID_REQUEST_TYPE_ENDLESS_DUNGEON_OF_THE_WEEK_SOLO_LEADERBOARD, classId, classIndex
            else
                return ZO_ID_REQUEST_TYPE_ENDLESS_DUNGEON_SOLO_LEADERBOARD, categoryData.endlessDungeonId, classId, classIndex
            end
        end
        return nil
    end

    function ZO_EndlessDungeonLeaderboardsManager_Shared:AddCategoriesToParentSystem()
        ZO_ClearNumericallyIndexedTable(self.endlessDungeonListNodes)

        local function UpdatePlayerInfo()
            self:UpdateAllInfo()
        end

        local function GetNumEntries(categoryData)
            if categoryData.endlessDungeonGroupType == ENDLESS_DUNGEON_GROUP_TYPE_DUO then
                if categoryData.isWeekly then
                    return GetNumEndlessDungeonOfTheWeekDuoLeaderboardEntries()
                else
                    return GetNumEndlessDungeonDuoLeaderboardEntries(categoryData.endlessDungeonId)
                end
            elseif categoryData.endlessDungeonGroupType == ENDLESS_DUNGEON_GROUP_TYPE_SOLO then
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
                        count = count + GetNumEndlessDungeonOfTheWeekSoloLeaderboardEntries(classId)
                    else
                        count = count + GetNumEndlessDungeonSoloLeaderboardEntries(categoryData.endlessDungeonId, classId)
                    end
                    table.insert(categoryData.classGates, { count = count,  classId = classId})
                end

                return count
            end

            return 0
        end

        local function GetMaxRank()
            return ENDLESS_DUNGEON_LEADERBOARD_MAX_RANK_ALLOWED
        end

        local function AddEntry(parent, name, categoryData, leaderboardRankType)
            local NO_POINTS_FORMAT_FUNCTION = nil
            local node = self.leaderboardSystem:AddEntry(self, name, name, parent, categoryData, GetNumEntries, GetMaxRank, GetSingleEndlessDungeonEntryInfo, NO_POINTS_FORMAT_FUNCTION, GetString(SI_LEADERBOARDS_HEADER_SCORE), GetEndlessDungeonLeaderboardEntryConsoleIdRequestParams, "EsoUI/Art/Leaderboards/gamepad/gp_leaderBoards_menuIcon_endlessDungeon.dds", leaderboardRankType, UpdatePlayerInfo)
            if node then
                local nodeData = node.GetData and node:GetData() or node
                nodeData.endlessDungeonId = categoryData.endlessDungeonId
                nodeData.isWeekly = categoryData.isWeekly
                nodeData.endlessDungeonGroupType = categoryData.endlessDungeonGroupType
            end
            table.insert(self.endlessDungeonListNodes, node)
            return node
        end

        -- Create Endless Dungeon Category Header
        local parent = self.leaderboardSystem:AddCategory(GetString(SI_ENDLESS_DUNGEON_LEADERBOARDS_CATEGORIES_HEADER), ENDLESS_DUNGEON_HEADER_ICONS.up, ENDLESS_DUNGEON_HEADER_ICONS.down, ENDLESS_DUNGEON_HEADER_ICONS.over)

        --Set up the 4 leaderboards (Weekly solo and duo, lifetime solo and duo) for every endlessDungeon
        local entries = {}

        for endlessDungeonGroupType = ENDLESS_DUNGEON_GROUP_TYPE_ITERATION_BEGIN, ENDLESS_DUNGEON_GROUP_TYPE_ITERATION_END do
            local weeklyCategoryData = 
            {
                endlessDungeonName = GetString("SI_ENDLESSDUNGEONGROUPTYPE_WEEKLY", endlessDungeonGroupType),
                endlessDungeonId = DEFAULT_ENDLESS_DUNGEON_ID,
                isWeekly = true,
                endlessDungeonGroupType = endlessDungeonGroupType,
            }

            table.insert(entries, weeklyCategoryData)

            local lifetimeCategoryData = 
            {
                endlessDungeonName = GetString("SI_ENDLESSDUNGEONGROUPTYPE", endlessDungeonGroupType),
                endlessDungeonId = DEFAULT_ENDLESS_DUNGEON_ID,
                isWeekly = false,
                endlessDungeonGroupType = endlessDungeonGroupType,
            }

            table.insert(entries, lifetimeCategoryData)
        end

        local function SortEntries(left, right)
            if left.isWeekly ~= right.isWeekly then
                return left.isWeekly
            elseif left.endlessDungeonGroupType ~= right.endlessDungeonGroupType then
                return left.endlessDungeonGroupType == ENDLESS_DUNGEON_GROUP_TYPE_SOLO
            end
            return false
        end
        table.sort(entries, SortEntries)

        for _, categoryData in ipairs(entries) do
            local leaderboardRankType = LEADERBOARD_RANK_MAP[categoryData.endlessDungeonGroupType]
            AddEntry(parent, categoryData.endlessDungeonName, categoryData, leaderboardRankType)
        end
    end
end

function ZO_EndlessDungeonLeaderboardsManager_Shared:SelectEndlessDungeonById(endlessDungeonId, endlessDungeonGroupType, selectOption, openLeaderboards)
    selectOption = selectOption or ZO_ENDLESS_DUNGEON_LEADERBOARD_SELECT_OPTION.DEFAULT

    local selectedNode

    if #self.endlessDungeonListNodes == 0 then
        -- We've never opened the menu, so we need to populate the categories before we can select the right one
        self.leaderboardSystem:UpdateCategories()
    end

    for _, node in ipairs(self.endlessDungeonListNodes) do
        local nodeData = node.GetData and node:GetData() or node
        if nodeData.endlessDungeonId == endlessDungeonId then
            if selectOption == ZO_ENDLESS_DUNGEON_LEADERBOARD_SELECT_OPTION.SKIP_WEEKLY then
                if not nodeData.isWeekly then
                    selectedNode = node
                    break
                end
            elseif selectOption == ZO_ENDLESS_DUNGEON_LEADERBOARD_SELECT_OPTION.PREFER_WEEKLY then
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

    function ZO_EndlessDungeonLeaderboardsManager_Shared:TimerLabelOnUpdate(currentTime)
        if currentTime - timerLabelLastUpdateSecs >= UPDATE_INTERVAL_SECS then
            local secsUntilEnd, secsUntilNextStart = GetEndlessDungeonOfTheWeekTimes()

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

    function ZO_EndlessDungeonLeaderboardsManager_Shared:UpdatePlayerInfo()
        if not self.selectedSubType then
            return
        end

        local isWeekly = self.selectedSubType.isWeekly
        local rank, bestScore
        if isWeekly then
            rank, bestScore = GetEndlessDungeonOfTheWeekLeaderboardLocalPlayerInfo(self.selectedSubType.endlessDungeonGroupType)
        else
            rank, bestScore = GetEndlessDungeonLeaderboardLocalPlayerInfo(self.selectedSubType.endlessDungeonGroupType, self.selectedSubType.endlessDungeonId)
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

function ZO_EndlessDungeonLeaderboardsManager_Shared:UpdatePlayerParticipationStatus()
    if not self.selectedSubType then
        return
    end

    if self.selectedSubType.isWeekly then
        self.participating, self.credited = GetPlayerEndlessDungeonOfTheWeekParticipationInfo(self.selectedSubType.endlessDungeonGroupType)
    else
        self.participating, self.credited = GetPlayerEndlessDungeonParticipationInfo(self.selectedSubType.endlessDungeonGroupType, self.selectedSubType.endlessDungeonId)
    end

    self:UpdateEndlessDungeonScore()
end

function ZO_EndlessDungeonLeaderboardsManager_Shared:UpdateEndlessDungeonScore()
    if not self.selectedSubType then
        return
    end

    local endlessDungeonInProgress, endlessDungeonComplete
    if self.selectedSubType.isWeekly then
        endlessDungeonInProgress, endlessDungeonComplete = GetPlayerEndlessDungeonOfTheWeekProgressInfo(self.selectedSubType.endlessDungeonGroupType)
    else
        endlessDungeonInProgress, endlessDungeonComplete = GetPlayerEndlessDungeonProgressInfo(self.selectedSubType.endlessDungeonGroupType, self.selectedSubType.endlessDungeonId)
    end

    if endlessDungeonInProgress or endlessDungeonComplete then
        self.currentScoreData = GetEndlessDungeonScore()
    else
        self.currentScoreData = GetString(SI_LEADERBOARDS_NO_CURRENT_SCORE)
    end
end

function ZO_EndlessDungeonLeaderboardsManager_Shared:OnSubtypeSelected(subType)
    ZO_LeaderboardBase_Shared.OnSubtypeSelected(self, subType)

    self:UpdateAllInfo()
end

function ZO_EndlessDungeonLeaderboardsManager_Shared:UpdateAllInfo()
    self:UpdatePlayerInfo()
    self:UpdatePlayerParticipationStatus()
end

function ZO_EndlessDungeonLeaderboardsManager_Shared:SendLeaderboardQuery()
    if not self.selectedSubType then
        return
    end 

    self.requestedEndlessDungeonGroupType = self.selectedSubType.endlessDungeonGroupType
    self.requestedEndlessDungeonId = self.selectedSubType.isWeekly and 0 or self.selectedSubType.endlessDungeonId

    local readyState = nil
    if self.requestedEndlessDungeonGroupType == ENDLESS_DUNGEON_GROUP_TYPE_SOLO then
        if IsInGamepadPreferredMode() then
            self.requestedClassId = GAMEPAD_LEADERBOARDS:GetSelectedClassFilter()
        else
            self.requestedClassId = LEADERBOARDS:GetSelectedClassFilter()
        end
    else
        self.requestedClassId = nil
    end
    LEADERBOARD_LIST_MANAGER:QueryLeaderboardData(PENDING_LEADERBOARD_DATA_TYPE.ENDLESS_DUNGEON, self:GenerateRequestData())
end

function ZO_EndlessDungeonLeaderboardsManager_Shared:GenerateRequestData()
    local data =
    { 
        endlessDungeonId = self.requestedEndlessDungeonId,
        endlessDungeonGroupType = self.requestedEndlessDungeonGroupType,
        classId = self.requestedClassId
    }
    return data
end

function ZO_EndlessDungeonLeaderboardsManager_Shared:HandleWeeklyTurnover()
    if self:IsSystemShowing() and self.requestedEndlessDungeonId == 0 then
        self:SendLeaderboardQuery()
    end
end

function ZO_EndlessDungeonLeaderboardsManager_Shared:HandleFilterDropdownChanged()
    if self.selectedSubType.endlessDungeonGroupType == ENDLESS_DUNGEON_GROUP_TYPE_SOLO then
        self:SendLeaderboardQuery()
        return true
    end    
    return false
end

ZO_EndlessDungeonLeaderboardsManager_Shared.GetFragment = ZO_EndlessDungeonLeaderboardsManager_Shared:MUST_IMPLEMENT()

function ZO_EndlessDungeonLeaderboardsManager_Shared:IsSystemShowing()
    return self:GetFragment():IsShowing()
end