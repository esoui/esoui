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
    CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", function() self:RefreshNoQuestsLabel() end)
end

function ZO_WorldMapQuests_Shared:RefreshNoQuestsLabel()
    if #self.data.masterList > 0 then
        self.noQuestsLabel:SetHidden(true)    
    else
        self.noQuestsLabel:SetHidden(false)
        if ZO_WorldMapQuestsData_Singleton.ShouldMapShowQuestsInList() then
            self.noQuestsLabel:SetText(GetString(SI_WORLD_MAP_NO_QUESTS))
        else
            self.noQuestsLabel:SetText(GetString(SI_WORLD_MAP_DOESNT_SHOW_QUESTS_DISTANCE))
        end
    end
end

-- Singleton shared data
ZO_WorldMapQuestsData_Singleton = ZO_Object:Subclass()

function ZO_WorldMapQuestsData_Singleton:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_WorldMapQuestsData_Singleton:Initialize(control)
    self.listDirty = false
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

    WORLD_MAP_QUEST_BREADCRUMBS:RegisterCallback("QuestAvailable", function(...) self:OnQuestAvailable(...) end)
    WORLD_MAP_QUEST_BREADCRUMBS:RegisterCallback("QuestRemoved", function(...) self:OnQuestRemoved(...) end)
    EVENT_MANAGER:RegisterForUpdate("ZO_WorldMapQuestsData_Singleton", 100, function()
        if self.listDirty then
            self.listDirty = false
            self:LayoutList(true)
        end
    end)
end

function ZO_WorldMapQuestsData_Singleton.ShouldMapShowQuestsInList()
    local mapType = GetMapType()
    --We don't want to track any quests when we are showing these high map levels
    if mapType == MAPTYPE_WORLD or mapType == MAPTYPE_COSMIC or mapType == MAPTYPE_ALLIANCE then
        return false
    end
    return true
end

function ZO_WorldMapQuestsData_Singleton:OnQuestAvailable(questIndex)
    if not ZO_WorldMapQuestsData_Singleton.ShouldMapShowQuestsInList() then
        return
    end
        
    if self:GetQuestMasterListIndex(questIndex) then
        -- We already have this quest in the list
        return
    end

    local questSteps = WORLD_MAP_QUEST_BREADCRUMBS:GetSteps(questIndex)
    local shouldAddQuest
    if questSteps then
        shouldAddQuest = false
        for stepIndex, questConditions in pairs(questSteps) do
            for conditionIndex, conditionData in pairs(questConditions) do
                if conditionData.xLoc >= 0 and conditionData.xLoc <= 1 and conditionData.yLoc >= 0 and conditionData.yLoc <= 1 and conditionData.insideCurrentMapWorld then
                    shouldAddQuest = true
                    break
                end
            end
        end
    else
        shouldAddQuest = IsJournalQuestInCurrentMapZone(questIndex)
    end

    if shouldAddQuest then
        local questType = GetJournalQuestType(questIndex)
        local name = GetJournalQuestName(questIndex)
        local level = GetJournalQuestLevel(questIndex)
        local displayType = GetJournalQuestInstanceDisplayType(questIndex)
        table.insert(self.masterList, {
            questIndex = questIndex,
            name = name,
            level = level,
            questType = questType,
            displayType = displayType,
        })

        self.listDirty = true
    end       
end

function ZO_WorldMapQuestsData_Singleton:OnQuestRemoved(questIndex)
    local masterListIndex = self:GetQuestMasterListIndex(questIndex)
    if masterListIndex then
        table.remove(self.masterList, masterListIndex)
        self.listDirty = true
    end
end

function ZO_WorldMapQuestsData_Singleton:GetQuestMasterListIndex(questIndex)
    for i, questData in ipairs(self.masterList) do
        if questData.questIndex == questIndex then
            return i
        end
    end
    return nil
end

function ZO_WorldMapQuestsData_Singleton:LayoutList(forceLayout)
    self:Sort()
    CALLBACK_MANAGER:FireCallbacks("OnWorldMapQuestsDataRefresh", forceLayout)
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
