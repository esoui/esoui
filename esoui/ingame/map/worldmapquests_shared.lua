--Shared Trade Window Prototype
ZO_WorldMapQuests_Shared = ZO_Object:Subclass()

function ZO_WorldMapQuests_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_WorldMapQuests_Shared:Initialize(control)
    self.control = control

    self.data = ZO_WorldMapQuestsData_Singleton_Initialize(control)

    control:RegisterForEvent(EVENT_LEVEL_UPDATE, function(eventCode, unitTag)
        if(unitTag == "player") then
            self:RefreshHeaders()
        end
    end)

    local function LayoutList(forceLayout)
        if not self.control:IsHidden() or forceLayout then
            self:LayoutList()
        end
    end

    CALLBACK_MANAGER:RegisterCallback("OnWorldMapQuestsDataRefresh", LayoutList)
end

-- Singleton shared data
ZO_WorldMapQuestsData_Singleton = ZO_Object:Subclass()

function ZO_WorldMapQuestsData_Singleton:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_WorldMapQuestsData_Singleton:Initialize(control)
    self.masterList = {}

    self.CompareQuests = function(a, b)
        local aCon = GetCon(a.level)
        local bCon = GetCon(b.level)
        if(aCon == bCon) then
            return a.name < b.name
        else
            return aCon < bCon
        end
    end

    local function OnQuestPositionRequestComplete(eventCode, taskId, pinType, xLoc, zLoc, areaRadius, insideCurrentMapWorld, isBreadcrumb)
        local insideBounds = (xLoc >= 0 and xLoc <= 1 and zLoc >= 0 and zLoc <= 1)
        local shouldAddQuest = insideCurrentMapWorld and insideBounds

        self:MarkTaskCompleted(taskId, shouldAddQuest)
    end

    local function RefreshList()
        self:RefreshList()
    end

    control:RegisterForEvent(EVENT_QUEST_ADDED, RefreshList)
    control:RegisterForEvent(EVENT_QUEST_REMOVED, RefreshList)
    control:RegisterForEvent(EVENT_LINKED_WORLD_POSITION_CHANGED, RefreshList)

    control:RegisterForEvent(EVENT_QUEST_POSITION_REQUEST_COMPLETE, OnQuestPositionRequestComplete)
    CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", RefreshList)
 end

function ZO_WorldMapQuestsData_Singleton:RefreshList()
    if(self:BuildMasterList()) then
        local FORCE_LAYOUT = true
        self:LayoutList(FORCE_LAYOUT)
    end
end

function ZO_WorldMapQuestsData_Singleton:LayoutList(forceLayout)
    CALLBACK_MANAGER:FireCallbacks("OnWorldMapQuestsDataRefresh", forceLayout)
end

function ZO_WorldMapQuestsData_Singleton:ClearPendingTasks()
    self.currentTasks = {}
    self.containedQuests = {}
    self.awaitingTasks = 0
end

function ZO_WorldMapQuestsData_Singleton:AddTask(taskId, questIndex)
    if(taskId) then
        self.currentTasks[taskId] = questIndex
        self.containedQuests[questIndex] = false
        self.awaitingTasks = self.awaitingTasks + 1
    end
end

function ZO_WorldMapQuestsData_Singleton:AddQuestToList(questIndex)
    local alreadyContainsQuest = self.containedQuests[questIndex]
    if(not alreadyContainsQuest) then
        self.containedQuests[questIndex] = true
        local questType = GetJournalQuestType(questIndex)
        local name = GetJournalQuestName(questIndex)
        local level = GetJournalQuestLevel(questIndex)
        table.insert(self.masterList, {
            questIndex = questIndex,
            name = name,
            level = level,
            questType = questType
        })
    end
end

function ZO_WorldMapQuestsData_Singleton:MarkTaskCompleted(taskId, shouldAddToList)
    if(self.currentTasks) then
        local questIndex = self.currentTasks[taskId]
        if(questIndex ~= nil and self.awaitingTasks > 0) then
            self.awaitingTasks = self.awaitingTasks - 1
            
            if(shouldAddToList) then
                self:AddQuestToList(questIndex)
            end

            if(self.awaitingTasks == 0) then
                self:LayoutList()
            end
        end
    end
end

function ZO_WorldMapQuestsData_Singleton:GetNumRemainingTasks()
    return self.awaitingTasks
end

function ZO_WorldMapQuestsData_Singleton:BuildMasterList()
    self.masterList = {}
    self:ClearPendingTasks()

    local mapType = GetMapType()
    if(mapType == MAPTYPE_WORLD or mapType == MAPTYPE_COSMIC or mapType == MAPTYPE_ALLIANCE) then return true end
    
    for questIndex = 1, MAX_JOURNAL_QUESTS do
        local hadConditionPosition = false
        if(IsValidQuestIndex(questIndex)) then
            if(GetJournalQuestIsComplete(questIndex)) then
                local taskId = RequestJournalQuestConditionAssistance(questIndex, QUEST_MAIN_STEP_INDEX, 1)                
                if(taskId) then
                    hadConditionPosition = true
                    self:AddTask(taskId, questIndex)
                end
            else        
                for stepIndex = QUEST_MAIN_STEP_INDEX, GetJournalQuestNumSteps(questIndex) do
                    for conditionIndex = 1, GetJournalQuestNumConditions(questIndex, stepIndex) do
                        local _, _, isFailCondition, isComplete = GetJournalQuestConditionValues(questIndex, stepIndex, conditionIndex)                    
                        if(not (isFailCondition or isComplete)) then
                            local taskId = RequestJournalQuestConditionAssistance(questIndex, stepIndex, conditionIndex)
                            if(taskId) then
                                hadConditionPosition = true
                                self:AddTask(taskId, questIndex)
                            end
                        end
                    end
                end            
            end

            if(not hadConditionPosition) then
                if(IsJournalQuestInCurrentMapZone(questIndex)) then
                    self:AddQuestToList(questIndex)
                end
            end
        end
    end
    
    -- If there were no quests, the list should update immediately
    return self:GetNumRemainingTasks() == 0
end

function ZO_WorldMapQuestsData_Singleton:Sort()
    table.sort(self.masterList, self.CompareQuests)
end

function ZO_WorldMapQuestsData_Singleton_Initialize(control)
    if not WORLD_MAP_QUESTS_DATA then
        WORLD_MAP_QUESTS_DATA = ZO_WorldMapQuestsData_Singleton:New(control)
    end
    return WORLD_MAP_QUESTS_DATA
end

local AddConditionLine = function(self, labels, text)
    local conditionLabel = self.labelPool:AcquireObject()
    conditionLabel:SetWidth(0)
    zo_bulletFormat(conditionLabel, text)
    table.insert(labels, conditionLabel)
end

function ZO_WorldMapQuests_Shared_SetupQuestDetails(self, questIndex)
    local labels = {}
    local questName, bgText, stepText, stepType, stepOverrideText, completed, tracked = GetJournalQuestInfo(questIndex)

    if completed then
        AddConditionLine(self, labels, GetJournalQuestEnding(questIndex))
    else
        local tasks = {}
        QUEST_JOURNAL_MANAGER:BuildTextForTasks(stepOverrideText, questIndex, tasks)

        for i = 1, #tasks do
            AddConditionLine(self, labels, tasks[i].name)
        end
    end

    local width = 0
    for i = 1, #labels do
        local labelWidth = labels[i]:GetTextDimensions() 
        width = zo_max(width, labelWidth)
    end

    local MAX_WIDTH = 250
    width = zo_min(width, MAX_WIDTH)

    return labels, width
end
