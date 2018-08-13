local QUEST_CAT_ZONE = 1
local QUEST_CAT_OTHER = 2
local QUEST_CAT_MISC = 3

----------
-- ZO_QuestJournal_Manager
----------

ZO_QuestJournal_Manager = ZO_CallbackObject:Subclass()

function ZO_QuestJournal_Manager:New(...)
    local manager = ZO_CallbackObject.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_QuestJournal_Manager:Initialize(control)
    self:RegisterForEvents()
end

function ZO_QuestJournal_Manager:RegisterForEvents()
    local function OnFocusQuestIndexChanged(eventCode, questIndex)
        self.focusedQuestIndex = questIndex
    end

    local function OnAssistChanged(unassistedData, assistedData)
        if assistedData and assistedData.arg1 then
            self.focusedQuestIndex = assistedData.arg1
        end
    end

    EVENT_MANAGER:RegisterForEvent("QuestJournal_Manager", EVENT_QUEST_SHOW_JOURNAL_ENTRY, OnFocusQuestIndexChanged)

    FOCUSED_QUEST_TRACKER:RegisterCallback("QuestTrackerAssistStateChanged", OnAssistChanged)
end

local function BuildTextHelper(questIndex, stepIndex, conditionStep, questStrings)
    local conditionText, currentCount, maxCount, isFailCondition, isComplete, _, isVisible = GetJournalQuestConditionInfo(questIndex, stepIndex, conditionStep)

    if(isVisible and not isFailCondition and conditionText ~= "") then
        if isComplete then
            conditionText = ZO_DISABLED_TEXT:Colorize(conditionText)
        end

        local taskInfo = {
            name = conditionText,
            isComplete = isComplete,
        }

        table.insert(questStrings, taskInfo)
    end
end

function ZO_QuestJournal_Manager:BuildTextForConditions(questIndex, stepIndex, numConditions, questStrings)
    for i = 1, numConditions do
        BuildTextHelper(questIndex, stepIndex, i, questStrings)
    end
end

function ZO_QuestJournal_Manager:BuildTextForTasks(stepOverrideText, questIndex, questStrings)
    if stepOverrideText and (stepOverrideText ~= "") then
        BuildTextHelper(questIndex, QUEST_MAIN_STEP_INDEX, nil, questStrings)
    else
        local conditionCount = GetJournalQuestNumConditions(questIndex, QUEST_MAIN_STEP_INDEX)
        self:BuildTextForConditions(questIndex, QUEST_MAIN_STEP_INDEX, conditionCount, questStrings)
    end
end

function ZO_QuestJournal_Manager:DoesShowMultipleOrSteps(stepOverrideText, stepType, questIndex)
    if stepOverrideText and (stepOverrideText ~= "") then
        return false
    else
        local conditionCount = GetJournalQuestNumConditions(questIndex, QUEST_MAIN_STEP_INDEX)
        if(stepType == QUEST_STEP_TYPE_OR and conditionCount > 1) then
            return true
        else
            return false
        end
    end
end

local function ZO_QuestJournal_Manager_SortQuestCategories(entry1, entry2)
    if entry1.type == entry2.type then
        return entry1.name < entry2.name
    else
        return entry1.type < entry2.type
    end
end

local function ZO_QuestJournal_Manager_SortQuestEntries(entry1, entry2)
    if entry1.categoryType == entry2.categoryType then
        if entry1.categoryName == entry2.categoryName then
            return entry1.name < entry2.name
        end

        return entry1.categoryName < entry2.categoryName
    end
    return entry1.categoryType < entry2.categoryType
end

ZO_IS_QUEST_TYPE_IN_OTHER_CATEGORY =
{
    [QUEST_TYPE_MAIN_STORY] = true,
    [QUEST_TYPE_GUILD] = true,
    [QUEST_TYPE_CRAFTING] = true,
    [QUEST_TYPE_HOLIDAY_EVENT] = true,
    [QUEST_TYPE_BATTLEGROUND] = true,
}

function ZO_QuestJournal_Manager:GetQuestCategoryNameAndType(questType, zone)
    local categoryName, categoryType
    if ZO_IS_QUEST_TYPE_IN_OTHER_CATEGORY[questType] then
        categoryName = GetString("SI_QUESTTYPE", questType)
        categoryType = QUEST_CAT_OTHER
    elseif zone ~= "" then
        categoryName = zo_strformat(SI_QUEST_JOURNAL_ZONE_FORMAT, zone)
        categoryType = QUEST_CAT_ZONE
    else
        categoryName = GetString(SI_QUEST_JOURNAL_GENERAL_CATEGORY)
        categoryType = QUEST_CAT_MISC
    end
    return categoryName, categoryType
end

function ZO_QuestJournal_Manager:AreQuestsInTheSameCategory(quest1Type, quest1Zone, quest2Type, quest2Zone)
    local quest1IsOtherCategory = ZO_IS_QUEST_TYPE_IN_OTHER_CATEGORY[quest1Type]
    local quest2IsOtherCategory = ZO_IS_QUEST_TYPE_IN_OTHER_CATEGORY[quest2Type]
    if quest1IsOtherCategory ~= quest2IsOtherCategory then
        return false
    else
        if quest1IsOtherCategory then
            return quest1Type == quest2Type
        else
            --true if they have the same zone or if they both have no zone and would end up in the general category
            return quest1Zone == quest2Zone
        end
    end
end

function ZO_QuestJournal_Manager:FindQuestWithSameCategoryAsCompletedQuest(questId)
    local _, completedQuestType = GetCompletedQuestInfo(questId)
    local completedQuestZone = GetCompletedQuestLocationInfo(questId)
    for i = 1, MAX_JOURNAL_QUESTS do
        if IsValidQuestIndex(i) then
            local questType = GetJournalQuestType(i)
            local zone = GetJournalQuestLocationInfo(i)
            if self:AreQuestsInTheSameCategory(completedQuestType, completedQuestZone, questType, zone) then
                return i
            end
        end 
    end
    return nil
end

function ZO_QuestJournal_Manager:GetQuestListData()
    local seenCategories = {}
    local categories = {}
    local quests = {}

    -- Create a table for categories and one for quests
    for i = 1, MAX_JOURNAL_QUESTS do
        if IsValidQuestIndex(i) then  
            local zone = GetJournalQuestLocationInfo(i)
            local questType = GetJournalQuestType(i)
            local name = GetJournalQuestName(i)
            local level = GetJournalQuestLevel(i)
            local instanceDisplayType = GetJournalQuestInstanceDisplayType(i)
            local categoryName, categoryType = self:GetQuestCategoryNameAndType(questType, zone)

            if not seenCategories[categoryName] then
                table.insert(categories, {name = categoryName, type = categoryType})
                seenCategories[categoryName] = true
            end

            if name == "" then
                name = GetString(SI_QUEST_JOURNAL_UNKNOWN_QUEST_NAME)
            end

            table.insert(quests,
                {
                    name = name,
                    questIndex = i,
                    level = level,
                    categoryName = categoryName,
                    categoryType = categoryType,
                    questType = questType,
                    displayType = instanceDisplayType
                }
            )
        end
    end

    -- Sort the tables
    table.sort(categories, ZO_QuestJournal_Manager_SortQuestCategories)
    table.sort(quests, ZO_QuestJournal_Manager_SortQuestEntries)

    return quests, categories, seenCategories
end

function ZO_QuestJournal_Manager:ConfirmAbandonQuest(questIndex)
    local questName = GetJournalQuestName(questIndex)
    local questLevel = GetJournalQuestLevel(questIndex)
    local conColorDef = ZO_ColorDef:New(GetConColor(questLevel))
    questName = conColorDef:Colorize(questName)
    ZO_Dialogs_ShowPlatformDialog("ABANDON_QUEST", {questIndex = questIndex}, {mainTextParams = {questName}})
end

function ZO_QuestJournal_Manager:ShareQuest(questIndex)
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.QUEST_SHARE_SENT, GetString(SI_QUEST_SHARED))
    ShareQuest(questIndex)
end

function ZO_QuestJournal_Manager:UpdateFocusedQuest()
    local focusedQuestIndex = nil
    local numTrackedQuests = GetNumTracked()
    for i=1, numTrackedQuests do
        local trackType, arg1, arg2 = GetTrackedByIndex(i)
        if GetTrackedIsAssisted(trackType, arg1, arg2) then
            focusedQuestIndex = arg1
            break
        end
    end

    self.focusedQuestIndex = focusedQuestIndex
end

function ZO_QuestJournal_Manager:GetFocusedQuestIndex()
    return self.focusedQuestIndex
end

QUEST_JOURNAL_MANAGER = ZO_QuestJournal_Manager:New()