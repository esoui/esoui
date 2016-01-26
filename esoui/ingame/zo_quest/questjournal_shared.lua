---------------------
--Quest Journal Shared
---------------------

ZO_QuestJournal_Shared = ZO_CallbackObject:Subclass()

function ZO_QuestJournal_Shared:New()
    local newObject = ZO_CallbackObject.New(self)

    return newObject
end

function ZO_QuestJournal_Shared:Initialize(control)
    self.control = control
    self.listDirty = true

    self.questStrings = {}

    self:RegisterTooltipText(INSTANCE_DISPLAY_TYPE_NONE, "")
    self:RegisterTooltipText(INSTANCE_DISPLAY_TYPE_SOLO, SI_QUEST_JOURNAL_SOLO_TOOLTIP)
    self:RegisterTooltipText(INSTANCE_DISPLAY_TYPE_GROUP, SI_QUEST_JOURNAL_GROUP_TOOLTIP)
    self:RegisterTooltipText(INSTANCE_DISPLAY_TYPE_RAID, SI_QUEST_JOURNAL_RAID_TOOLTIP)
    -- nothing should be marked as GROUP_DELVE, but just in case treat it like GROUP
    self:RegisterTooltipText(INSTANCE_DISPLAY_TYPE_GROUP_DELVE, SI_QUEST_JOURNAL_GROUP_TOOLTIP)

    self.bgText = control:GetNamedChild("BGText")
    self.stepText = control:GetNamedChild("StepText")
    self.optionalStepTextLabel = control:GetNamedChild("OptionalStepTextLabel")
    self.questInfoContainer = control:GetNamedChild("QuestInfoContainer")
    self.questStepContainer = control:GetNamedChild("QuestStepContainer")

    self:InitializeQuestList(control)
    self:InitializeKeybindStripDescriptors()
    self:RefreshQuestList()
    self:RefreshQuestCount()
    self:InitializeScenes()

    control:RegisterForEvent(EVENT_QUEST_ADDED, function() self:OnQuestsUpdated() end)    
    control:RegisterForEvent(EVENT_QUEST_REMOVED, function() self:OnQuestsUpdated() end)
    control:RegisterForEvent(EVENT_QUEST_LIST_UPDATED, function() self:OnQuestsUpdated() end)
    control:RegisterForEvent(EVENT_QUEST_ADVANCED, function(eventCode, questIndex) self:OnQuestAdvanced(questIndex) end)
    control:RegisterForEvent(EVENT_QUEST_CONDITION_COUNTER_CHANGED, function(eventCode, questIndex) self:OnQuestConditionCounterChanged(questIndex) end)
    control:RegisterForEvent(EVENT_LEVEL_UPDATE, function(eventCode, unitTag) self:OnLevelUpdated(unitTag) end)
end

function ZO_QuestJournal_Shared:RegisterIconTexture(questType, texturePath)
    self.icons = self.icons or {}
    self.icons[questType] = texturePath
end

function ZO_QuestJournal_Shared:GetIconTexture(questType)
    return self.icons[questType]
end

function ZO_QuestJournal_Shared:RegisterTooltipText(questType, stringId)
    self.tooltips = self.tooltips or {}
    self.tooltips[questType] = GetString(stringId)
end

function ZO_QuestJournal_Shared:GetTooltipText(questType)
    return self.tooltips[questType]
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

function ZO_QuestJournal_Shared:OnLevelUpdated(unitTag)
    if (unitTag == "player") then
        if self.control:IsHidden() then
            self.listDirty = true
        else
            self:RefreshQuestList()
        end
    end
end

function ZO_QuestJournal_Shared:BuildTextForStepVisibility(questIndex, visibilityType)
    local numSteps = GetJournalQuestNumSteps(questIndex)
    local questStrings = self.questStrings
    for stepIndex = 2, numSteps do
        local stepJournalText, visibility, _, stepOverrideText, _ = GetJournalQuestStepInfo(questIndex, stepIndex)

        if visibility == visibilityType then
            if(stepJournalText ~= "") then
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

function ZO_QuestJournal_Shared:RefreshQuestMasterList()
    -- Override if necesary
end

function ZO_QuestJournal_Shared:OnQuestsUpdated()
    self:RefreshQuestMasterList()
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

function ZO_QuestJournal_Shared:OnQuestConditionCounterChanged(questIndex)
    local selectedQuestIndex = self:GetSelectedQuestIndex()
    if questIndex == selectedQuestIndex then
        self:RefreshDetails()
    end
end

function ZO_QuestJournal_Shared:ShowOnMap()
   local selectedQuestIndex = self:GetSelectedQuestIndex()
   if(selectedQuestIndex) then
        ZO_WorldMap_ShowQuestOnMap(selectedQuestIndex)
    end
end