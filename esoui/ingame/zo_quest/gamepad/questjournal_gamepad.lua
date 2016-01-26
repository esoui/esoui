local QUEST_TEMPLATE = "ZO_QuestJournal_Gamepad_MenuEntryTemplate"
local QUEST_HEADER_TEMPLATE = "ZO_GamepadMenuEntryHeaderTemplate"
local SELECTED_QUEST_TEXTURE = "EsoUI/Art/Journal/Gamepad/gp_trackedQuestIcon.dds"

ZO_QuestJournal_Gamepad = ZO_Object.MultiSubclass(ZO_QuestJournal_Shared, ZO_Gamepad_ParametricList_Screen)

function ZO_QuestJournal_Gamepad:New(...)
    local questJournalManager = ZO_QuestJournal_Shared.New(self)
    questJournalManager:Initialize(...)
    return questJournalManager
end

function ZO_QuestJournal_Gamepad:Initialize(control)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control)

    self.control = control
    self.sceneName = "gamepad_quest_journal"
    self.optionsSceneName = "gamepad_quest_journal_options"

    self:RegisterIconTexture(QUEST_TYPE_AVA, "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_AvA.dds")
    self:RegisterIconTexture(QUEST_TYPE_AVA_GRAND, "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_normal.dds")
    self:RegisterIconTexture(QUEST_TYPE_AVA_GROUP, "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_AvAGroup.dds")
    self:RegisterIconTexture(QUEST_TYPE_CLASS, "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_normal.dds")
    self:RegisterIconTexture(QUEST_TYPE_CRAFTING, "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_crafting.dds")
    self:RegisterIconTexture(QUEST_TYPE_DUNGEON, "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_dungeon.dds")
    self:RegisterIconTexture(QUEST_TYPE_GROUP, "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_group.dds")
    self:RegisterIconTexture(QUEST_TYPE_GUILD, "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_guild.dds")
    self:RegisterIconTexture(QUEST_TYPE_MAIN_STORY, "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_mainStory.dds")
    self:RegisterIconTexture(QUEST_TYPE_NONE, "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_normal.dds")
    self:RegisterIconTexture(QUEST_TYPE_QA_TEST, "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_normal.dds")
    self:RegisterIconTexture(QUEST_TYPE_RAID, "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_raid.dds")

    self.questList = self:GetMainList()
    self.questList:SetNoItemText(GetString(SI_GAMEPAD_QUEST_JOURNAL_NO_QUESTS))
    self.optionsList = self:AddList("Options")
    self:SetupOptionsList(self.optionsList)
    self.rightPane = control:GetNamedChild("RightPane")
    self.middlePane = control:GetNamedChild("MiddlePane")
    self.contentHeader = self.middlePane:GetNamedChild("Container").header

    self.conditionTextLabel = control:GetNamedChild("ConditionTextLabel")
    self.hintTextLabel = control:GetNamedChild("HintTextLabel")
    self.hintTextBulletList = ZO_BulletList:New(control:GetNamedChild("HintTextBulletList"), "ZO_QuestJournal_HintBulletLabel_Gamepad")
    self.conditionTextBulletList = ZO_BulletList:New(control:GetNamedChild("ConditionTextBulletList"), "ZO_QuestJournal_ConditionBulletLabel_Gamepad", nil, "ZO_QuestJournal_CompletedTaskIcon_Gamepad")
    self.optionalStepTextBulletList = ZO_BulletList:New(control:GetNamedChild("OptionalStepTextBulletList"), "ZO_QuestJournal_ConditionBulletLabel_Gamepad")

    local LINE_PADDING_Y = 11
    self.hintTextBulletList:SetLinePaddingY(LINE_PADDING_Y)
    self.conditionTextBulletList:SetLinePaddingY(LINE_PADDING_Y)
    self.optionalStepTextBulletList:SetLinePaddingY(LINE_PADDING_Y)

    local BULLET_PADDING_X = 34
    self.hintTextBulletList:SetBulletPaddingX(BULLET_PADDING_X)
    self.conditionTextBulletList:SetBulletPaddingX(BULLET_PADDING_X)
    self.optionalStepTextBulletList:SetBulletPaddingX(BULLET_PADDING_X)

    GAMEPAD_QUEST_JOURNAL_OPTIONS_FRAGMENT = self:GetListFragment(self.optionsList)

    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_SEPARATE)
    self.headerData =
    {
        titleText = GetString(SI_QUEST_JOURNAL_MENU_JOURNAL),
        data1HeaderText = GetString(SI_GAMEPAD_MAIN_MENU_JOURNAL_QUESTS),
        data1Text = function() return zo_strformat(SI_GAMEPAD_QUEST_JOURNAL_CURRENT_MAX, GetNumJournalQuests(), MAX_JOURNAL_QUESTS) end,
    }

    ZO_GamepadGenericHeader_Initialize(self.contentHeader, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ZO_GAMEPAD_HEADER_LAYOUTS.CONTENT_HEADER_DATA_PAIRS_LINKED)

    local FORMATTED_SELECTED_QUEST_ICON = zo_iconFormat(SELECTED_QUEST_TEXTURE, 32, 32)
    self.contentHeaderData =
    {
        titleText = function()
            local questData = self:GetSelectedQuestData()
            if questData then
                local questName, _, _, _, _, _, _, _, _, questType = GetJournalQuestInfo(questData.questIndex)

                local conColorDef = ZO_ColorDef:New(GetConColor(questData.level))
                questName = conColorDef:Colorize(questName)
                local questIcon = zo_iconFormat(self:GetIconTexture(questType), 48, 48)
                if QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex() == questData.questIndex then
                    questName = zo_strformat(SI_GAMEPAD_SELECTED_QUEST_JOURNAL_QUEST_NAME_FORMAT, FORMATTED_SELECTED_QUEST_ICON, questIcon, questName)
                else
                    questName = zo_strformat(SI_GAMEPAD_QUEST_JOURNAL_QUEST_NAME_FORMAT, questIcon, questName)
                end

                return questName
            end
        end,

        data1HeaderText = GetString(SI_GAMEPAD_QUEST_JOURNAL_QUEST_LEVEL),
        data1Text = function()
            local questData = self:GetSelectedQuestData()
            if questData then
                return tostring(questData.level)
            end
        end,

        data2Text = function()
            local repeatableText, instanceDisplayTypeText = self:GetQuestDataString()
            return repeatableText or instanceDisplayTypeText
        end,

        data3Text = function()
            local repeatableText, instanceDisplayTypeText = self:GetQuestDataString()
            if repeatableText == nil then
                return nil -- data2Text will already be showing the instance type info
            else
                return instanceDisplayTypeText
            end
        end,
    }

    --Quest tracker depends on this data for finding the next quest to focus.
    self:RefreshQuestMasterList()
    self.listDirty = true

    ZO_QuestJournal_Shared.Initialize(self, control)
end

do
    local ICON_SIZE = 48
    local groupIcon = zo_iconFormat("EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_group.dds", ICON_SIZE, ICON_SIZE)
    local raidIcon = zo_iconFormat("EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_raid.dds", ICON_SIZE, ICON_SIZE)
    local soloIcon = zo_iconFormat("EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_normal.dds", ICON_SIZE, ICON_SIZE)

    local instanceDisplayStrings = {
        [INSTANCE_DISPLAY_TYPE_GROUP] = zo_strformat(SI_GAMEPAD_QUEST_JOURNAL_INSTANCE_TYPE_GROUP, groupIcon),
        [INSTANCE_DISPLAY_TYPE_GROUP_DELVE] = "",
        [INSTANCE_DISPLAY_TYPE_NONE] = "",
        [INSTANCE_DISPLAY_TYPE_RAID] = zo_strformat(SI_GAMEPAD_QUEST_JOURNAL_INSTANCE_TYPE_RAID, raidIcon),
        [INSTANCE_DISPLAY_TYPE_SOLO] = zo_strformat(SI_GAMEPAD_QUEST_JOURNAL_INSTANCE_TYPE_SOLO, soloIcon),
    }

    function ZO_QuestJournal_Gamepad:GetQuestDataString()
        local repeatableText, instanceDisplayTypeText
        local questData = self:GetSelectedQuestData()

        if questData then
            local repeatableType = GetJournalQuestRepeatType(questData.questIndex)
            if repeatableType ~= QUEST_REPEAT_NOT_REPEATABLE then
                repeatableText = GetString(SI_GAMEPAD_QUEST_JOURNAL_REPEATABLE_TEXT)
            end

            if questData.dataSource then
                local instanceDisplayType = questData.dataSource.displayType
                instanceDisplayTypeText = instanceDisplayStrings[instanceDisplayType]
            end
        end

        return repeatableText, instanceDisplayTypeText
    end
end

function ZO_QuestJournal_Gamepad:PerformDeferredInitialization()
    if self.initialized then return end

    -- TODO.

    self.initialized = true
end

function ZO_QuestJournal_Gamepad:OnTargetChanged(...)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.mainKeybindStripDescriptor)
    self:RefreshDetails()
end

function ZO_QuestJournal_Gamepad:SetupList(list)
    local function QuestEntryTemplateSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)

        local conColorDef = ZO_ColorDef:New(GetConColor(data.level))
        control.label:SetColor(conColorDef:UnpackRGBA())

        control.selectedIcon:SetTexture(SELECTED_QUEST_TEXTURE)
        control.selectedIcon:SetHidden(QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex() ~= data.questIndex)
    end

    list:AddDataTemplate(QUEST_TEMPLATE, QuestEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader(QUEST_TEMPLATE, QuestEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, QUEST_HEADER_TEMPLATE, nil, "HeaderEntry")
end

function ZO_QuestJournal_Gamepad:SetupOptionsList(list)
    list:SetOnTargetDataChangedCallback(function(list, selectedData)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.optionsKeybindStripDescriptor)
    end)

    list:AddDataTemplate("ZO_GamepadSubMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup)
end

function ZO_QuestJournal_Gamepad:InitializeKeybindStripDescriptors()
    -- Main keybind strip
    self.mainKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",

            callback = function()
                local selectedQuestIndex = self:GetSelectedQuestIndex()
                self:FocusQuestWithIndex(selectedQuestIndex)
            end,

            visible = function()
                local selectedQuestIndex = self:GetSelectedQuestIndex()
                if selectedQuestIndex then
                    return true
                end
                return false
            end
        },

        -- Map
        {
            name = GetString(SI_QUEST_JOURNAL_SHOW_ON_MAP),
            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                local selectedQuestIndex = self:GetSelectedQuestIndex()
                if selectedQuestIndex then
                    self:ShowOnMap(selectedQuestIndex)
                end
            end,

            visible = function()
                local selectedQuestIndex = self:GetSelectedQuestIndex()
                if selectedQuestIndex then
                    return true
                end
                return false
            end
        },

        -- Options
        {
            name = GetString(SI_GAMEPAD_QUEST_JOURNAL_OPTIONS),
            keybind = "UI_SHORTCUT_TERTIARY",

            callback = function()
                self:DeactivateCurrentList()
                SCENE_MANAGER:Push(self.optionsSceneName)
            end,

            visible = function()
                local selectedQuestIndex = self:GetSelectedQuestIndex()
                if selectedQuestIndex and (self:CanAbandonQuest() or self:CanShareQuest()) then
                    return true
                end
                return false
            end
        },
    }

    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.mainKeybindStripDescriptor, self.questList)
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.mainKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)

    -- Options keybind strip
    self.optionsKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Do action
        {
            keybind = "UI_SHORTCUT_PRIMARY",

            name = function()
                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end,
            
            callback = function()
                local selectedData = self.optionsList:GetTargetData()
                if selectedData then
                    selectedData.action()
                end
            end,

            visible = function()
                local selectedData = self.optionsList:GetTargetData()
                return selectedData ~= nil
            end
        },
    }

    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.optionsKeybindStripDescriptor, self.optionsList)
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.optionsKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

function ZO_QuestJournal_Gamepad:InitializeScenes()
    local returningFromOptions = false
    
    GAMEPAD_QUEST_JOURNAL_ROOT_SCENE = ZO_Scene:New(self.sceneName, SCENE_MANAGER)
    GAMEPAD_QUEST_JOURNAL_ROOT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:PerformDeferredInitialization()
            
            if self.listDirty then
                self:RefreshQuestCount()
                self:RefreshQuestMasterList()
                self:RefreshQuestList()
            end
            
            self:FocusQuestWithIndex(QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex())

            self:SetCurrentList(self.questList)
            ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
            ZO_GamepadGenericHeader_Refresh(self.contentHeader, self.contentHeaderData)

            if not returningFromOptions then
                local questListEmpty = self.questList:IsEmpty()

                if questListEmpty then
                    self:RefreshDetails()
                elseif QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex() then
                    self:SelectFocusedQuest()
                elseif not questListEmpty then
                    self.questList:SetSelectedIndexWithoutAnimation(1)
                end
            else
                returningFromOptions = false
            end

            self:SetKeybindButtonGroup(self.mainKeybindStripDescriptor)
        elseif newState == SCENE_HIDDEN then
            self.questList:Deactivate()

            self:SetKeybindButtonGroup(nil)
        end
    end)

    GAMEPAD_QUEST_JOURNAL_OPTIONS_SCENE = ZO_Scene:New(self.optionsSceneName, SCENE_MANAGER)
    GAMEPAD_QUEST_JOURNAL_OPTIONS_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:RefreshOptionsList()
            self:SetCurrentList(self.optionsList)
            self:SetKeybindButtonGroup(self.optionsKeybindStripDescriptor)
        elseif newState == SCENE_HIDDEN then
            if SCENE_MANAGER:IsShowingNext(self.sceneName) then
                returningFromOptions = true
            end

            self.optionsList:Deactivate()

            self:SetKeybindButtonGroup(nil)
        end
    end)
end

function ZO_QuestJournal_Gamepad:GetSceneName()
    return self.sceneName
end

function ZO_QuestJournal_Gamepad:GetSelectedQuestData()
    return self.questList:GetTargetData()
end

function ZO_QuestJournal_Gamepad:SelectFocusedQuest()
    self.questList:EnableAnimation(false)
    self.questList:SetSelectedDataByEval(function(data)
        return data.questIndex == QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex()
    end)
    self.questList:EnableAnimation(true)
end

function ZO_QuestJournal_Gamepad:PerformUpdate()
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
    self.dirty = false
end

function ZO_QuestJournal_Gamepad:RefreshQuestCount()
    self:Update()
end

local function UpdateListAnchors(control, attachedTo)
    control:ClearAnchors()
    control:SetAnchor(TOPLEFT, attachedTo, BOTTOMLEFT, 50, yOffset)
    control:SetAnchor(TOPRIGHT, attachedTo, BOTTOMRIGHT, 0, 21)
end

function ZO_QuestJournal_Gamepad:RefreshDetails()
    if not SCENE_MANAGER:IsShowing(self.sceneName) then
        self.listDirty = true
        return
    end
    
    ZO_GamepadGenericHeader_Refresh(self.contentHeader, self.contentHeaderData)

    local questData = self:GetSelectedQuestData()

    local hasQuestData = (questData ~= nil)
    if hasQuestData then
        GAMEPAD_QUEST_JOURNAL_ROOT_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
        GAMEPAD_QUEST_JOURNAL_ROOT_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT)
    else
        GAMEPAD_QUEST_JOURNAL_ROOT_SCENE:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
        GAMEPAD_QUEST_JOURNAL_ROOT_SCENE:RemoveFragment(GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT)
    end

    local hideWindows = not hasQuestData
    self.rightPane:SetHidden(hideWindows)
    self.middlePane:SetHidden(hideWindows)
    self.questInfoContainer:SetHidden(hideWindows)
    self.questStepContainer:SetHidden(hideWindows)

    if hasQuestData then
        local _, bgText, stepText, stepType, stepOverrideText, completed = GetJournalQuestInfo(questData.questIndex)

        self.conditionTextBulletList:Clear()
        self.optionalStepTextBulletList:Clear()
        self.hintTextBulletList:Clear()

        local questIndex = questData.questIndex
        local questStrings = self.questStrings
        ZO_ClearNumericallyIndexedTable(questStrings)

        if completed then
            local goalCondition, _, _, _, goalBackgroundText, goalDescription = GetJournalQuestEnding(questIndex)
       
            self.bgText:SetText(goalBackgroundText)
            self.stepText:SetText(goalDescription)
            self.conditionTextBulletList:AddLine(goalCondition)
            self.optionalStepTextLabel:SetHidden(true)
            if self.hintTextLabel then
                self.hintTextLabel:SetHidden(true)
            end
        else
            self.bgText:SetText(bgText)
            self.stepText:SetText(stepText)

            local showMultipleOrSteps = QUEST_JOURNAL_MANAGER:DoesShowMultipleOrSteps(stepOverrideText, stepType, questIndex)
            self.conditionTextLabel:SetText(showMultipleOrSteps and GetString(SI_GAMEPAD_QUEST_JOURNAL_QUEST_OR_DESCRIPTION) or GetString(SI_QUEST_JOURNAL_QUEST_TASKS))
            QUEST_JOURNAL_MANAGER:BuildTextForTasks(stepOverrideText, questIndex, questStrings)

            for k, v in ipairs(questStrings) do
                self.conditionTextBulletList:AddLine(v.name, v.isComplete)
            end

            ZO_ClearNumericallyIndexedTable(questStrings)

            self:BuildTextForStepVisibility(questIndex, QUEST_STEP_VISIBILITY_OPTIONAL)
            self.optionalStepTextLabel:SetHidden(#questStrings == 0)
            for i = 1, #questStrings do
                self.optionalStepTextBulletList:AddLine(questStrings[i])
            end

            ZO_ClearNumericallyIndexedTable(questStrings)

            local anchorToControl = self.optionalStepTextLabel:IsControlHidden() and self.conditionTextBulletList.control or self.optionalStepTextBulletList.control
            UpdateListAnchors(self.hintTextLabel, anchorToControl, 0)

            self:BuildTextForStepVisibility(questIndex, QUEST_STEP_VISIBILITY_HINT)
            if self.hintTextLabel then
                self.hintTextLabel:SetHidden(#questStrings == 0)
            end
            for i = 1, #questStrings do
                self.hintTextBulletList:AddLine(questStrings[i])
            end
        end
    end
    self.listDirty = false
end

function ZO_QuestJournal_Gamepad:RefreshOptionsList()
    self.optionsList:Clear()

    local options = {}
    if self:CanShareQuest() then
        local shareQuest = ZO_GamepadEntryData:New(GetString(SI_QUEST_JOURNAL_SHARE))
        shareQuest.action = function()
                    local selectedQuestIndex = self:GetSelectedQuestIndex()
                    if selectedQuestIndex then
                        QUEST_JOURNAL_MANAGER:ShareQuest(selectedQuestIndex)
                    end
                end
        table.insert(options, shareQuest)
    end
    
    if self:CanAbandonQuest() then
        local abandonQuest = ZO_GamepadEntryData:New(GetString(SI_QUEST_JOURNAL_ABANDON))
        abandonQuest.action = function()
                    local selectedQuestIndex = self:GetSelectedQuestIndex()
                    if selectedQuestIndex then
                        QUEST_JOURNAL_MANAGER:ConfirmAbandonQuest(selectedQuestIndex)
                    end
                end
        table.insert(options, abandonQuest)
    end

    if IsConsoleUI() then
        local reportQuest = ZO_GamepadEntryData:New(GetString(SI_ITEM_ACTION_REPORT_ITEM))
        reportQuest.action = function()
                    local selectedQuestIndex = self:GetSelectedQuestIndex()
                    if selectedQuestIndex then
                        local questName = GetJournalQuestInfo(selectedQuestIndex)
                        self:SetKeybindButtonGroup(nil)
                        ZO_Help_Customer_Service_Gamepad_SetupQuestIssueTicket(questName)
                        SCENE_MANAGER:Push("helpCustomerServiceGamepad")
                    end
                end
        table.insert(options, reportQuest)
    end

    for _, option in pairs(options) do
        self.optionsList:AddEntry("ZO_GamepadSubMenuEntryTemplate", option)
    end

    self.optionsList:Commit()
    self.options = options
end

function ZO_QuestJournal_Gamepad:RefreshQuestMasterList()
    self.questMasterList = QUEST_JOURNAL_MANAGER:GetQuestListData()

    -- If we're showing the options menu, make sure we still have the quest that we're viewing options for
    if SCENE_MANAGER:IsShowing(self.optionsSceneName) then
        local hasQuest = false
        for i, quest in ipairs(self.questMasterList) do
            if quest.questIndex == self:GetSelectedQuestIndex() then
                hasQuest = true
            end
        end

        if not hasQuest then
            -- Quest is no longer available...back out of the options menu
            SCENE_MANAGER:HideCurrentScene()
        end
    end
end

function ZO_QuestJournal_Gamepad:RefreshQuestList()
    self.questList:Clear()

    local lastCategoryName
    for i, quest in ipairs(self.questMasterList) do
        local entry = ZO_GamepadEntryData:New(quest.name, self:GetIconTexture(quest.questType))
        entry:SetDataSource(quest)
        entry:SetIconTintOnSelection(true)

        if quest.categoryName ~= lastCategoryName then
            lastCategoryName = quest.categoryName
            entry:SetHeader(quest.categoryName)
            self.questList:AddEntryWithHeader(QUEST_TEMPLATE, entry)
        else
            self.questList:AddEntry(QUEST_TEMPLATE, entry)
        end
    end

    self.questList:Commit()

    self:RefreshDetails()
end

function ZO_QuestJournal_Gamepad:GetNextSortedQuestForQuestIndex(questIndex)
    if self.questMasterList then
        for i, quest in ipairs(self.questMasterList) do
            if quest.questIndex == questIndex then
                local nextQuest = (i == #self.questMasterList) and 1 or (i + 1)
                return self.questMasterList[nextQuest].questIndex
            end
        end
    end
end

function ZO_QuestJournal_Gamepad:FocusQuestWithIndex(index)
    self:FireCallbacks("QuestSelected", index)
    -- The quest tracker performs focus logic on quest/remove/update, only force focus if the player has clicked on the quest through the journal UI
    if SCENE_MANAGER:IsShowing(self.sceneName) then
        QUEST_TRACKER:ForceAssist(index)
    end

    self:RefreshQuestMasterList()
    self:RefreshQuestList()
end

function ZO_QuestJournal_Gamepad:SetKeybindButtonGroup(descriptor)
    if self.currentKeybindButtonGroup then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentKeybindButtonGroup)
    end

    if descriptor then
        KEYBIND_STRIP:AddKeybindButtonGroup(descriptor)
    end

    self.currentKeybindButtonGroup = descriptor
end

function ZO_QuestJournal_Gamepad_OnInitialized(control)
    QUEST_JOURNAL_GAMEPAD = ZO_QuestJournal_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject("questJournal", QUEST_JOURNAL_GAMEPAD)
end
