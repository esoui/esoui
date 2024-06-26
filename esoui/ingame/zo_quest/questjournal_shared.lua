---------------------
--Quest Journal Shared
---------------------

-- Used for indexing into icon/tooltip tables if we don't care what the quest or instance display types are
ZO_ANY_QUEST_TYPE = "all_quests"
ZO_ANY_ZONE_DISPLAY_TYPE = "all_instances"

ZO_QuestJournal_Shared = ZO_CallbackObject:Subclass()

function ZO_QuestJournal_Shared:New()
    local newObject = ZO_CallbackObject.New(self)

    return newObject
end

function ZO_QuestJournal_Shared:Initialize(control)
    self.control = control
    self.listDirty = true

    self.questStrings = {}
    self.icons = {}
    self.tooltips = {}

    self:RegisterIcons()
    self:RegisterTooltips()

    self:InitializeQuestList(control)
    self:InitializeKeybindStripDescriptors()
    self:RefreshQuestList()
    self:RefreshQuestCount()
    self:InitializeScenes()

    QUEST_JOURNAL_MANAGER:RegisterCallback("QuestListUpdated", function() self:OnQuestsUpdated() end)

    control:RegisterForEvent(EVENT_QUEST_ADVANCED, function(eventCode, questIndex) self:OnQuestAdvanced(questIndex) end)
    control:RegisterForEvent(EVENT_QUEST_CONDITION_COUNTER_CHANGED, function(eventCode, ...) self:OnQuestConditionInfoChanged(...) end)
    control:RegisterForEvent(EVENT_QUEST_CONDITION_OVERRIDE_TEXT_CHANGED, function(eventCode, index) self:OnQuestConditionInfoChanged(index) end)
    control:RegisterForEvent(EVENT_LEVEL_UPDATE, function(eventCode, unitTag) self:OnLevelUpdated(unitTag) end)
    control:AddFilterForEvent(EVENT_LEVEL_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")
end

local function QuestJournal_Shared_RegisterDataInTable(table, questType, zoneDisplayType, data)
    local questTableIndex = questType or ZO_ANY_QUEST_TYPE
    table[questTableIndex] = table[questTableIndex] or {}

    table[questTableIndex][zoneDisplayType or ZO_ANY_ZONE_DISPLAY_TYPE] = data
end

local function QuestJournal_Shared_GetDataFromTable(table, questType, zoneDisplayType)
    local data

    -- Attempt to pull data specifically for this quest type first
    if table[questType] then
        data = table[questType][zoneDisplayType] or table[questType][ZO_ANY_ZONE_DISPLAY_TYPE]
    end

    -- If we didn't find specific data for this quest type, try to fetch it for any quest type
    if data == nil and table[ZO_ANY_QUEST_TYPE] then
        data = table[ZO_ANY_QUEST_TYPE][zoneDisplayType] or table[ZO_ANY_QUEST_TYPE][ZO_ANY_ZONE_DISPLAY_TYPE]
    end

    return data
end

--TODO: Get ride of this exstensibility.  The icon should only be controlled by the display type.
function ZO_QuestJournal_Shared:RegisterIconTexture(questType, zoneDisplayType, texturePath)
    QuestJournal_Shared_RegisterDataInTable(self.icons, questType, zoneDisplayType, texturePath)
end

function ZO_QuestJournal_Shared:GetIconTexture(questType, zoneDisplayType)
    return QuestJournal_Shared_GetDataFromTable(self.icons, questType, zoneDisplayType)
end

function ZO_QuestJournal_Shared:RegisterTooltipText(questType, zoneDisplayType, stringIdOrText, paramsFunction)
    local tooltipText = type(stringIdOrText) == "number" and GetString(stringIdOrText) or stringIdOrText

    local data = tooltipText
    if paramsFunction then 
        data =
        {
            text = tooltipText,
            paramsFunction = paramsFunction,
        }
    end

    QuestJournal_Shared_RegisterDataInTable(self.tooltips, questType, zoneDisplayType, data)
end

function ZO_QuestJournal_Shared:GetTooltipText(questType, zoneDisplayType, questIndex)
    local data = QuestJournal_Shared_GetDataFromTable(self.tooltips, questType, zoneDisplayType)
    local text = data
    if type(data) == "table" then
        text = zo_strformat(data.text, data.paramsFunction(questIndex))
    end
    return text
end

function ZO_QuestJournal_Shared:InitializeQuestList()
    -- Should be overridden
end

function ZO_QuestJournal_Shared:InitializeKeybindStripDescriptors()
    -- Should be overridden
end

function ZO_QuestJournal_Shared:InitializeScenes()
    -- Should be overridden
end

function ZO_QuestJournal_Shared:GetSelectedQuestData()
    -- Should be overridden
end

function ZO_QuestJournal_Shared:RefreshQuestList()
    -- Should be overridden
end

function ZO_QuestJournal_Shared:RegisterIcons()
    -- Should be overridden
end

function ZO_QuestJournal_Shared:RegisterTooltips()
    -- Should be overridden
end

function ZO_QuestJournal_Shared:OnLevelUpdated(unitTag)
    if self.control:IsHidden() then
        self.listDirty = true
    else
        self:RefreshQuestList()
    end
end

function ZO_QuestJournal_Shared:BuildTextForStepVisibility(questIndex, visibilityType)
    local numSteps = GetJournalQuestNumSteps(questIndex)
    local questStrings = self.questStrings
    for stepIndex = 2, numSteps do
        local stepJournalText, visibility, _, stepOverrideText, _ = GetJournalQuestStepInfo(questIndex, stepIndex)

        if visibility == visibilityType then
            if stepJournalText ~= "" then
                table.insert(questStrings, zo_strformat(SI_QUEST_JOURNAL_TEXT, stepJournalText))
            end
            
            if stepOverrideText and (stepOverrideText ~= "") then
                table.insert(questStrings, stepOverrideText)
            end
        end
    end
end

function ZO_QuestJournal_Shared:GetSelectedQuestIndex()
    local selectedData = self:GetSelectedQuestData()
    return selectedData and selectedData.questIndex
end

function ZO_QuestJournal_Shared:CanAbandonQuest()
    local selectedData = self:GetSelectedQuestData()
    if selectedData and selectedData.questIndex and selectedData.questType ~= QUEST_TYPE_MAIN_STORY then
        return true
    end
    return false
end

function ZO_QuestJournal_Shared:CanShareQuest()
    local selectedQuestIndex = self:GetSelectedQuestIndex()
    if selectedQuestIndex then
        return GetIsQuestSharable(selectedQuestIndex) and IsUnitGrouped("player")
    end
    return false
end

function ZO_QuestJournal_Shared:RefreshDetails()
    --to be overridden
end

function ZO_QuestJournal_Shared:RefreshQuestCount()
    -- This function is overridden by sub-classes.
end

function ZO_QuestJournal_Shared:OnQuestsUpdated()
    if self.control:IsHidden() then
        self.listDirty = true
    else
        self:RefreshQuestCount()
        self:RefreshQuestList()
    end
end

function ZO_QuestJournal_Shared:OnQuestAdvanced(questIndex)
    local selectedQuestIndex = self:GetSelectedQuestIndex()
    if questIndex == selectedQuestIndex then
        self:RefreshDetails()
    end
end

function ZO_QuestJournal_Shared:OnQuestConditionInfoChanged(questIndex, questName, conditionText, conditionType, curCondtionVal, newConditionVal, conditionMax, isFailCondition, stepOverrideText, isPushed, isQuestComplete, isConditionComplete, isStepHidden, isConditionCompleteStatusChanged, isConditionCompletableBySiblingStatusChanged)
    local selectedQuestIndex = self:GetSelectedQuestIndex()
    if questIndex == selectedQuestIndex then
        self:RefreshDetails()
    end
end

function ZO_QuestJournal_Shared:ShowOnMap()
   local selectedQuestIndex = self:GetSelectedQuestIndex()
   if selectedQuestIndex then
        ZO_WorldMap_ShowQuestOnMap(selectedQuestIndex)
    end
end

function ZO_QuestJournal_Shared:GetNextSortedQuestForQuestIndex(questIndex)
    return QUEST_JOURNAL_MANAGER:GetNextSortedQuestForQuestIndex(questIndex)
end

function ZO_QuestJournal_Shared:GetSceneName()
    -- Should be overridden
end

function ZO_QuestJournal_Shared:OpenQuestJournalToQuest()
    -- Should be overridden
end

-- When the next Quest Journal screen opens, it will open to this quest.
function ZO_QuestJournal_Shared:QueuePendingJournalQuestIndex(questIndex)
    self.pendingJournalQuestIndex = questIndex
end

function ZO_QuestJournal_Shared:GetPendingJournalQuestIndex()
    return self.pendingJournalQuestIndex
end

function ZO_QuestJournal_Shared:ClearPendingJournalQuestIndex()
    self.pendingJournalQuestIndex = nil
end
