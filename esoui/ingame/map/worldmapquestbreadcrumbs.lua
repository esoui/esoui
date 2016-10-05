ZO_WorldMapQuestBreadcrumbs = ZO_CallbackObject:Subclass()

function ZO_WorldMapQuestBreadcrumbs:New(...)
    local obj = ZO_CallbackObject.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_WorldMapQuestBreadcrumbs:Initialize()
    self.taskIdToConditionData = {}
    self.conditionDataToPosition = {}

    EVENT_MANAGER:RegisterForEvent("ZO_WorldMapQuestBreadcrumbs", EVENT_QUEST_POSITION_REQUEST_COMPLETE, function(_, ...) self:OnQuestPositionRequestComplete(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_WorldMapQuestBreadcrumbs", EVENT_QUEST_CONDITION_COUNTER_CHANGED, function(_, ...) self:OnQuestConditionCounterChanged(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_WorldMapQuestBreadcrumbs", EVENT_QUEST_ADDED, function(_, ...) self:OnQuestAdded(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_WorldMapQuestBreadcrumbs", EVENT_QUEST_REMOVED, function(_, ...) self:OnQuestRemoved(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_WorldMapQuestBreadcrumbs", EVENT_QUEST_LIST_UPDATED, function() self:OnQuestListUpdated() end)
    EVENT_MANAGER:RegisterForEvent("ZO_WorldMapQuestBreadcrumbs", EVENT_LINKED_WORLD_POSITION_CHANGED, function() self:OnLinkedWorldPositionChanged() end)
    EVENT_MANAGER:RegisterForEvent("ZO_WorldMapQuestBreadcrumbs", EVENT_QUEST_ADVANCED, function(_, ...) self:OnQuestAdvanced(...) end)
    CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", function() self:OnWorldMapChanged() end)
end

function ZO_WorldMapQuestBreadcrumbs:HasOutstandingRequests()
    return next(self.taskIdToConditionData) ~= nil
end

function ZO_WorldMapQuestBreadcrumbs:GetSteps(questIndex)
    return self.conditionDataToPosition[questIndex]
end

function ZO_WorldMapQuestBreadcrumbs:GetNumQuestStepsWithPositions(questIndex)
    local questTable = self.conditionDataToPosition[questIndex]
    if questTable then
        return NonContiguousCount(questTable)
    end
    return 0
end

function ZO_WorldMapQuestBreadcrumbs:GetNumQuestConditionPositions(questIndex, stepIndex)
    local questTable = self.conditionDataToPosition[questIndex]
    if questTable then
        local stepTable = questTable[stepIndex]
        if stepTable then
            return NonContiguousCount(stepTable)
        end
    end
end

function ZO_WorldMapQuestBreadcrumbs:GetQuestConditionPosition(questIndex, stepIndex, conditionIndex)
    local questTable = self.conditionDataToPosition[questIndex]
    if questTable then
        local stepTable = questTable[stepIndex]
        if stepTable then
            return stepTable[conditionIndex]
        end
    end
end

function ZO_WorldMapQuestBreadcrumbs:RequestConditionPosition(questIndex, stepIndex, conditionIndex)
    local conditionData =
    {
        questIndex = questIndex,
        stepIndex = stepIndex,
        conditionIndex = conditionIndex,
    }

    local NOT_ASSISTED = false
    local taskId = RequestJournalQuestConditionAssistance(questIndex, stepIndex, conditionIndex, NOT_ASSISTED)
    if taskId then
        self.taskIdToConditionData[taskId] = conditionData
        return taskId
    end
end

function ZO_WorldMapQuestBreadcrumbs:RefreshQuest(questIndex)
    local removedQuest = false
    for taskId, conditionData in pairs(self.taskIdToConditionData) do
        if conditionData.questIndex == questIndex then
            CancelRequestJournalQuestConditionAssistance(taskId)
            self.taskIdToConditionData[taskId] = nil
            removedQuest = true
        end
    end

    if self.conditionDataToPosition[questIndex] then
        self.conditionDataToPosition[questIndex] = nil
        removedQuest = true
    end

    if removedQuest  then
        self:FireCallbacks("QuestRemoved", questIndex)
    end

    local hadConditionPosition = false
    if(GetJournalQuestIsComplete(questIndex)) then
        local taskId = self:RequestConditionPosition(questIndex, QUEST_MAIN_STEP_INDEX, 1)
        hadConditionPosition = taskId ~= nil
    else
        for stepIndex = QUEST_MAIN_STEP_INDEX, GetJournalQuestNumSteps(questIndex) do
            for conditionIndex = 1, GetJournalQuestNumConditions(questIndex, stepIndex) do
                local _, _, isFailCondition, isComplete, _, isVisible = GetJournalQuestConditionValues(questIndex, stepIndex, conditionIndex)
                if(not (isFailCondition or isComplete) and isVisible) then
                    local taskId = self:RequestConditionPosition(questIndex, stepIndex, conditionIndex)
                    hadConditionPosition = hadConditionPosition or (taskId ~= nil)
                end
            end
        end
    end

    if not hadConditionPosition then
        self:FireCallbacks("QuestAvailable", questIndex)
    end
end

function ZO_WorldMapQuestBreadcrumbs:RefreshAllQuests()
    local removedQuests = {}
    
    for taskId, conditionData in pairs(self.taskIdToConditionData) do
        CancelRequestJournalQuestConditionAssistance(taskId)
        removedQuests[conditionData.questIndex] = true
    end

    for questIndex, questData in pairs(self.conditionDataToPosition) do
        removedQuests[questIndex] = true
    end

    self.taskIdToConditionData = {}
    self.conditionDataToPosition = {}

    for questIndex, _ in pairs(removedQuests) do
        self:FireCallbacks("QuestRemoved", questIndex)
    end

    for i = 1, MAX_JOURNAL_QUESTS do
        if IsValidQuestIndex(i) then
            self:RefreshQuest(i)
        end
    end
end

--Events

function ZO_WorldMapQuestBreadcrumbs:OnQuestPositionRequestComplete(taskId, pinType, xLoc, yLoc, areaRadius, insideCurrentMapWorld, isBreadcrumb)
    local positionData =
    {
        pinType = pinType,
        xLoc = xLoc,
        yLoc = yLoc,
        areaRadius = areaRadius,
        insideCurrentMapWorld = insideCurrentMapWorld,
        isBreadcrumb = isBreadcrumb,
    }

    local conditionData = self.taskIdToConditionData[taskId]
    if conditionData then
        self.taskIdToConditionData[taskId] = nil
        local questIndex, stepIndex, conditionIndex = conditionData.questIndex, conditionData.stepIndex, conditionData.conditionIndex
        if not self.conditionDataToPosition[questIndex] then
            self.conditionDataToPosition[questIndex] = {}
        end
        local questTable = self.conditionDataToPosition[questIndex]
        if not questTable[stepIndex] then
            questTable[stepIndex] = {}
        end
        local stepTable = questTable[stepIndex]
        stepTable[conditionIndex] = positionData

        local allQuestConditionsDone = true
        for searchTaskId, searchConditionData in pairs(self.taskIdToConditionData) do
            if searchConditionData.questIndex == questIndex then
                allQuestConditionsDone = false
                break
            end
        end

        if allQuestConditionsDone then
            self:FireCallbacks("QuestAvailable", questIndex)
        end
    end
end

function ZO_WorldMapQuestBreadcrumbs:OnQuestConditionCounterChanged(questIndex)
    self:RefreshQuest(questIndex)
end

function ZO_WorldMapQuestBreadcrumbs:OnQuestRemoved(isCompleted, questIndex)
    for taskId, conditionData in pairs(self.taskIdToConditionData) do
        if conditionData.questIndex == questIndex then
            CancelRequestJournalQuestConditionAssistance(taskId)
            self.taskIdToConditionData[taskId] = nil
        end
    end    
    self.conditionDataToPosition[questIndex] = nil
    self:FireCallbacks("QuestRemoved", questIndex)
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

WORLD_MAP_QUEST_BREADCRUMBS = ZO_WorldMapQuestBreadcrumbs:New()