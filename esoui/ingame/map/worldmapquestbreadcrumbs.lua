ZO_WorldMapQuestBreadcrumbs = ZO_CallbackObject:Subclass()

function ZO_WorldMapQuestBreadcrumbs:New(...)
    local obj = ZO_CallbackObject.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_WorldMapQuestBreadcrumbs:Initialize()
    self.taskIdToConditionData = {}
    self.conditionDataToPosition = {}
    self.activeQuests = {}
    self.charIdToGroupBreadcrumbingData = {}

    EVENT_MANAGER:RegisterForEvent("ZO_WorldMapQuestBreadcrumbs", EVENT_GROUP_MEMBER_POSITION_REQUEST_COMPLETE, function(_, ...) self:OnGroupMemberRequestComplete(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_WorldMapQuestBreadcrumbs", EVENT_QUEST_POSITION_REQUEST_COMPLETE, function(_, ...) self:OnQuestPositionRequestComplete(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_WorldMapQuestBreadcrumbs", EVENT_QUEST_CONDITION_COUNTER_CHANGED, function(_, ...) self:OnQuestConditionInfoChanged(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_WorldMapQuestBreadcrumbs", EVENT_QUEST_ADDED, function(_, ...) self:OnQuestAdded(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_WorldMapQuestBreadcrumbs", EVENT_QUEST_REMOVED, function(_, ...) self:OnQuestRemoved(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_WorldMapQuestBreadcrumbs", EVENT_QUEST_LIST_UPDATED, function() self:OnQuestListUpdated() end)
    EVENT_MANAGER:RegisterForEvent("ZO_WorldMapQuestBreadcrumbs", EVENT_LINKED_WORLD_POSITION_CHANGED, function() self:OnLinkedWorldPositionChanged() end)
    EVENT_MANAGER:RegisterForEvent("ZO_WorldMapQuestBreadcrumbs", EVENT_QUEST_ADVANCED, function(_, ...) self:OnQuestAdvanced(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_WorldMapQuestBreadcrumbs", EVENT_PATH_FINDING_NETWORK_LINK_CHANGED, function() self:OnPathFindingNetworkLinkChanged() end)
    CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", function() self:OnWorldMapChanged() end)
end

function ZO_WorldMapQuestBreadcrumbs:HasOutstandingRequests()
    return next(self.taskIdToConditionData) ~= nil
end

function ZO_WorldMapQuestBreadcrumbs:GetSteps(questIndex)
    return self.conditionDataToPosition[questIndex]
end

function ZO_WorldMapQuestBreadcrumbs:GetNumQuestStepsWithPositions(questIndex)
    local stepsTable = self:GetSteps(questIndex)
    return stepsTable and NonContiguousCount(stepsTable) or 0
end

function ZO_WorldMapQuestBreadcrumbs:GetQuestConditionPositions(questIndex, stepIndex)
    local stepsTable = self:GetSteps(questIndex)
    return stepsTable and stepsTable[stepIndex] or nil
end

function ZO_WorldMapQuestBreadcrumbs:GetNumQuestConditionPositions(questIndex, stepIndex)
    local positionsTable = self:GetQuestConditionPositions(questIndex, stepIndex)
    -- For backwards compatibility we return nil (instead of 0) for empty tables.
    return positionsTable and NonContiguousCount(positionsTable) or nil
end

function ZO_WorldMapQuestBreadcrumbs:GetQuestConditionPosition(questIndex, stepIndex, conditionIndex)
    local positionsTable = self:GetQuestConditionPositions(questIndex, stepIndex)
    return positionsTable and positionsTable[conditionIndex] or nil
end

function ZO_WorldMapQuestBreadcrumbs:RequestConditionPosition(questIndex, stepIndex, conditionIndex)
    local conditionData =
    {
        questIndex = questIndex,
        stepIndex = stepIndex,
        conditionIndex = conditionIndex,
    }

    local taskId = RequestJournalQuestConditionAssistance(questIndex, stepIndex, conditionIndex)
    if taskId then
        self.taskIdToConditionData[taskId] = conditionData
        return taskId
    end
end

function ZO_WorldMapQuestBreadcrumbs:RefreshQuest(questIndex)
    self:RemoveQuest(questIndex)

    if GetJournalQuestIsComplete(questIndex) then
        self:RequestConditionPosition(questIndex, QUEST_MAIN_STEP_INDEX, 1)
    else
        -- Request the position of all quest conditions that are incomplete and have not failed.
        local numSteps = GetJournalQuestNumSteps(questIndex)
        for stepIndex = QUEST_MAIN_STEP_INDEX, numSteps do
            local numConditions = GetJournalQuestNumConditions(questIndex, stepIndex)
            for conditionIndex = 1, numConditions do
                local _, _, isFailCondition, isComplete, _, isVisible = GetJournalQuestConditionValues(questIndex, stepIndex, conditionIndex)
                if isVisible and not (isFailCondition or isComplete) then
                    self:RequestConditionPosition(questIndex, stepIndex, conditionIndex)
                end
            end
        end
    end

    self:AddQuest(questIndex)
end

function ZO_WorldMapQuestBreadcrumbs:RefreshAllQuests()
    self:CancelAllPendingTasks()
    for questIndex in pairs(self.activeQuests) do
        self:RemoveQuest(questIndex)
    end

    for questIndex = 1, MAX_JOURNAL_QUESTS do
        if IsValidQuestIndex(questIndex) then
            self:RefreshQuest(questIndex)
        end
    end
end

function ZO_WorldMapQuestBreadcrumbs:CancelAllPendingTasks()
    for taskId, conditionData in pairs(self.taskIdToConditionData) do
        CancelRequestJournalQuestConditionAssistance(taskId)
        self.taskIdToConditionData[taskId] = nil
    end
    self.conditionDataToPosition = {}
end

function ZO_WorldMapQuestBreadcrumbs:CancelPendingTasksForQuest(questIndex)
    for taskId, conditionData in pairs(self.taskIdToConditionData) do
        if conditionData.questIndex == questIndex then
            CancelRequestJournalQuestConditionAssistance(taskId)
            self.taskIdToConditionData[taskId] = nil
        end
    end
    self.conditionDataToPosition[questIndex] = nil
end

function ZO_WorldMapQuestBreadcrumbs:DoesQuestHavePendingTasks(questIndex)
    for taskId, conditionData in pairs(self.taskIdToConditionData) do
        if conditionData.questIndex == questIndex then
            return true
        end
    end
    return false
end

function ZO_WorldMapQuestBreadcrumbs:IsQuestActive(questIndex)
    return self.activeQuests[questIndex] == true
end

function ZO_WorldMapQuestBreadcrumbs:AddQuestConditionPosition(conditionData, positionData)
    local questIndex, stepIndex, conditionIndex = conditionData.questIndex, conditionData.stepIndex, conditionData.conditionIndex

    local questTable = self.conditionDataToPosition[questIndex]
    if not questTable then
        questTable = {}
        self.conditionDataToPosition[questIndex] = questTable
    end

    local stepTable = questTable[stepIndex]
    if not stepTable then
        stepTable = {}
        questTable[stepIndex] = stepTable
    end
    stepTable[conditionIndex] = positionData
end

function ZO_WorldMapQuestBreadcrumbs:AddQuest(questIndex)
    if not self:IsQuestActive(questIndex) and not self:DoesQuestHavePendingTasks(questIndex) then
        self.activeQuests[questIndex] = true
        self:FireCallbacks("QuestAvailable", questIndex)
    end
end

function ZO_WorldMapQuestBreadcrumbs:RemoveQuest(questIndex)
    self:CancelPendingTasksForQuest(questIndex)
    if self.activeQuests[questIndex] then
        self.activeQuests[questIndex] = nil
        self:FireCallbacks("QuestRemoved", questIndex)
    end
end

function ZO_WorldMapQuestBreadcrumbs:GetGroupMemberBreadcrumbingData()
    return self.charIdToGroupBreadcrumbingData
end

--Events

function ZO_WorldMapQuestBreadcrumbs:OnGroupMemberRequestComplete(taskId, charId, isGroupLeader, isBreadcrumb, teleportNPCId, waypointId)
    self.charIdToGroupBreadcrumbingData[charId] =
    {
        isGroupLeader = isGroupLeader,
        teleportNPCId = teleportNPCId,
        waypointId = waypointId,
    }
end

function ZO_WorldMapQuestBreadcrumbs:OnQuestPositionRequestComplete(taskId, pinType, xLoc, yLoc, areaRadius, insideCurrentMapWorld, isBreadcrumb, teleportNPCId, waypointId, symbolicState, additionalSymbolicLocX, additionalSymbolicLocY)
    local conditionData = self.taskIdToConditionData[taskId]
    if conditionData then
        self.taskIdToConditionData[taskId] = nil
        local positionData =
        {
            pinType = pinType,
            xLoc = xLoc,
            yLoc = yLoc,
            areaRadius = areaRadius,
            insideCurrentMapWorld = insideCurrentMapWorld,
            isBreadcrumb = isBreadcrumb,
            teleportNPCId = teleportNPCId,
            waypointId = waypointId,
            symbolicState = symbolicState,
            additionalSymbolicLocX = additionalSymbolicLocX,
            additionalSymbolicLocY = additionalSymbolicLocY,
        }
        self:AddQuestConditionPosition(conditionData, positionData)
        self:AddQuest(conditionData.questIndex)
    end
end

function ZO_WorldMapQuestBreadcrumbs:OnQuestConditionInfoChanged(questIndex, questName, conditionText, conditionType, curCondtionVal, newConditionVal, conditionMax, isFailCondition, stepOverrideText, isPushed, isQuestComplete, isConditionComplete, isStepHidden, isConditionCompleteStatusChanged, isConditionCompletableBySiblingStatusChanged)
    -- Only refresh if the condition completed has changed but the quest is not complete since there is another event for a quest completing.
    -- This will reduce the number of times the pins are refreshed so that they are not refreshed unnecessarily.
    if not isQuestComplete and (isConditionCompleteStatusChanged or isConditionCompletableBySiblingStatusChanged) then
        self:RefreshQuest(questIndex)
    end
end

function ZO_WorldMapQuestBreadcrumbs:OnQuestRemoved(isCompleted, questIndex)
    self:RemoveQuest(questIndex)
end

function ZO_WorldMapQuestBreadcrumbs:OnQuestAdded(questIndex)
    self:RefreshQuest(questIndex)
end

function ZO_WorldMapQuestBreadcrumbs:OnQuestListUpdated()
    self:RefreshAllQuests()
end

function ZO_WorldMapQuestBreadcrumbs:OnLinkedWorldPositionChanged()
    self:RefreshAllQuests()
end

function ZO_WorldMapQuestBreadcrumbs:OnQuestAdvanced(questIndex)
    self:RefreshQuest(questIndex)
end

function ZO_WorldMapQuestBreadcrumbs:OnWorldMapChanged()
    self:RefreshAllQuests()
end

function ZO_WorldMapQuestBreadcrumbs:OnPathFindingNetworkLinkChanged()
    self:RefreshAllQuests()
end

WORLD_MAP_QUEST_BREADCRUMBS = ZO_WorldMapQuestBreadcrumbs:New()