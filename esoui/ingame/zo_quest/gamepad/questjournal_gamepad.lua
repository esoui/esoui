local QUEST_TEMPLATE = "ZO_QuestJournal_Gamepad_MenuEntryTemplate"
local QUEST_HEADER_TEMPLATE = "ZO_GamepadMenuEntryHeaderTemplate"
local SELECTED_QUEST_TEXTURE = "EsoUI/Art/Journal/Gamepad/gp_trackedQuestIcon.dds"

local QUEST_LIST = "questList"
local OPTIONS_LIST = "optionsList"

ZO_QuestJournal_Gamepad = ZO_Object.MultiSubclass(ZO_QuestJournal_Shared, ZO_Gamepad_ParametricList_Screen)

function ZO_QuestJournal_Gamepad:New(...)
    local questJournalManager = ZO_QuestJournal_Shared.New(self)
    questJournalManager:Initialize(...)
    return questJournalManager
end

function ZO_QuestJournal_Gamepad:Initialize(control)
    self.sceneName = "gamepad_quest_journal"
    GAMEPAD_QUEST_JOURNAL_ROOT_SCENE = ZO_Scene:New(self.sceneName, SCENE_MANAGER)
    local DONT_ACTIVATE_ON_SHOW = false -- we'll manually set our list
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, DONT_ACTIVATE_ON_SHOW, GAMEPAD_QUEST_JOURNAL_ROOT_SCENE)

    self.control = control

    self.questList = self:GetMainList()
    self.questList:SetNoItemText(GetString(SI_GAMEPAD_QUEST_JOURNAL_NO_QUESTS))

    self.optionsList = self:AddList("Options")
    self:SetupOptionsList(self.optionsList)

    -- Middle Pane
    self.middlePane = control:GetNamedChild("MiddlePane")
    local middlePaneContainer = self.middlePane:GetNamedChild("Container")
    self.contentHeader = middlePaneContainer.header
    local middlePaneContent = middlePaneContainer:GetNamedChild("Content")
    self.questInfoContainer = middlePaneContent:GetNamedChild("QuestInfoContainer")
    
    local questInfoContainerScroll = self.questInfoContainer:GetNamedChild("Scroll")
    local questInfoContainerScrollChild = self.questInfoContainer:GetNamedChild("ScrollChild")
    self.bgText = middlePaneContent:GetNamedChild("BGText")
    self.bgText:SetParent(questInfoContainerScrollChild)
    self.bgText:ClearAnchors()
    self.bgText:SetAnchor(TOPLEFT, questInfoContainerScrollChild, TOPLEFT)
    self.bgText:SetAnchor(TOPRIGHT, questInfoContainerScroll, TOPRIGHT)

    self.stepText = middlePaneContent:GetNamedChild("StepText")

    self.middlePaneFragment = ZO_FadeSceneFragment:New(self.middlePane)

    -- Right Pane
    self.rightPane = control:GetNamedChild("RightPane")
    local rightPaneContent = self.rightPane:GetNamedChild("ContainerContent")
    self.questStepContainer = rightPaneContent:GetNamedChild("QuestStepContainer")

    local questStepContainerScroll = self.questStepContainer:GetNamedChild("Scroll")
    local questStepContainerScrollChild = self.questStepContainer:GetNamedChild("ScrollChild")
    self.conditionTextLabel = rightPaneContent:GetNamedChild("ConditionTextLabel")
    self.conditionTextLabel:SetParent(questStepContainerScrollChild)
    self.conditionTextLabel:ClearAnchors()
    self.conditionTextLabel:SetAnchor(TOPLEFT, questStepContainerScrollChild, TOPLEFT, 50)
    self.conditionTextLabel:SetAnchor(TOPRIGHT, questStepContainerScroll, TOPRIGHT)

    self.conditionTextBulletList = ZO_BulletList:New(rightPaneContent:GetNamedChild("ConditionTextBulletList"), "ZO_QuestJournal_ConditionBulletLabel_Gamepad", nil, "ZO_QuestJournal_CompletedTaskIcon_Gamepad")

    self.optionalStepTextLabel = rightPaneContent:GetNamedChild("OptionalStepTextLabel")
    self.optionalStepTextBulletList = ZO_BulletList:New(rightPaneContent:GetNamedChild("OptionalStepTextBulletList"), "ZO_QuestJournal_ConditionBulletLabel_Gamepad")

    self.hintTextLabel = rightPaneContent:GetNamedChild("HintTextLabel")
    self.hintTextBulletList = ZO_BulletList:New(rightPaneContent:GetNamedChild("HintTextBulletList"), "ZO_QuestJournal_HintBulletLabel_Gamepad")

    self.rightPaneFragment = ZO_FadeSceneFragment:New(self.rightPane)

    local LINE_PADDING_Y = 11
    self.hintTextBulletList:SetLinePaddingY(LINE_PADDING_Y)
    self.conditionTextBulletList:SetLinePaddingY(LINE_PADDING_Y)
    self.optionalStepTextBulletList:SetLinePaddingY(LINE_PADDING_Y)

    local BULLET_PADDING_X = 34
    self.hintTextBulletList:SetBulletPaddingX(BULLET_PADDING_X)
    self.conditionTextBulletList:SetBulletPaddingX(BULLET_PADDING_X)
    self.optionalStepTextBulletList:SetBulletPaddingX(BULLET_PADDING_X)

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
                local questName, _, _, _, _, _, _, _, _, questType, instanceDisplayType = GetJournalQuestInfo(questData.questIndex)

                local conColorDef = ZO_ColorDef:New(GetConColor(questData.level))
                questName = conColorDef:Colorize(questName)
                local iconTexture = self:GetIconTexture(questType, instanceDisplayType)

                if iconTexture then
                    local questIcon = zo_iconFormat(iconTexture, 48, 48)
                    if QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex() == questData.questIndex then
                        questName = zo_strformat(SI_GAMEPAD_SELECTED_QUEST_JOURNAL_QUEST_NAME_FORMAT, FORMATTED_SELECTED_QUEST_ICON, questIcon, questName)
                    else
                        questName = zo_strformat(SI_GAMEPAD_QUEST_JOURNAL_QUEST_NAME_FORMAT, questIcon, questName)
                    end
                else
                    if QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex() == questData.questIndex then
                        questName = zo_strformat(SI_GAMEPAD_SELECTED_QUEST_JOURNAL_QUEST_NAME_FORMAT_NO_ICON, FORMATTED_SELECTED_QUEST_ICON, questName)
                    else
                        questName = zo_strformat(SI_GAMEPAD_QUEST_JOURNAL_QUEST_NAME_FORMAT_NO_ICON, questName)
                    end
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

function ZO_QuestJournal_Gamepad:OnDeferredInitialize()
    -- this needs to be deferred because the background fragments don't exist yet
    self.questInfoFragmentGroup =
        {
            GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT,
            GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT,
            self.middlePaneFragment,
            self.rightPaneFragment,
        }

    self:SetListsUseTriggerKeybinds(true)
end

-- Scene state change callbacks overriden from ZO_Gamepad_ParametricList_Screen
function ZO_QuestJournal_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)

    self:SwitchActiveList(QUEST_LIST)
end

function ZO_QuestJournal_Gamepad:OnHide()
    self:Deactivate()

    self:SwitchActiveList(nil)

    self:SetKeybindButtonGroup(nil)
end

function ZO_QuestJournal_Gamepad:SwitchActiveList(listDescriptor)
    if listDescriptor == self.currentListType then return end

    self.previousListType = self.currentListType
    self.currentListType = listDescriptor

    -- if our scene isn't showing we shouldn't actually switch the lists
    -- we'll rely on the scene showing to set the list
    if self.scene:IsShowing() then
        if listDescriptor == QUEST_LIST then
            if self.listDirty then
                self:RefreshQuestCount()
                self:RefreshQuestMasterList()
                self:RefreshQuestList()
            end

            if self.previousListType == nil then
                self:FocusQuestWithIndex(QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex())
            elseif self.previousListType == OPTIONS_LIST then
                if self.questList:IsEmpty() then
                    self:RefreshDetails()
                end
            end

            self:SetCurrentList(self.questList)
            ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
            ZO_GamepadGenericHeader_Refresh(self.contentHeader, self.contentHeaderData)

            self:SetKeybindButtonGroup(self.mainKeybindStripDescriptor)
        elseif listDescriptor == OPTIONS_LIST then
            self:RefreshOptionsList()
            self:SetCurrentList(self.optionsList)
            self:SetKeybindButtonGroup(self.optionsKeybindStripDescriptor)
        end
    end
end

function ZO_QuestJournal_Gamepad:RegisterIcons()
    self:RegisterIconTexture(ZO_ANY_QUEST_TYPE,     INSTANCE_DISPLAY_TYPE_SOLO,             "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_instance.dds")
    self:RegisterIconTexture(ZO_ANY_QUEST_TYPE,     INSTANCE_DISPLAY_TYPE_DUNGEON,          "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_groupDungeon.dds")
    self:RegisterIconTexture(ZO_ANY_QUEST_TYPE,     INSTANCE_DISPLAY_TYPE_GROUP_DELVE,      "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_groupDelve.dds")
    self:RegisterIconTexture(ZO_ANY_QUEST_TYPE,     INSTANCE_DISPLAY_TYPE_GROUP_AREA,       "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_groupArea.dds")
    self:RegisterIconTexture(ZO_ANY_QUEST_TYPE,     INSTANCE_DISPLAY_TYPE_RAID,             "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_raid.dds")
    self:RegisterIconTexture(ZO_ANY_QUEST_TYPE,     INSTANCE_DISPLAY_TYPE_PUBLIC_DUNGEON,   "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_dungeon.dds")
    self:RegisterIconTexture(ZO_ANY_QUEST_TYPE,     INSTANCE_DISPLAY_TYPE_DELVE,            "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_delve.dds")
    self:RegisterIconTexture(ZO_ANY_QUEST_TYPE,     INSTANCE_DISPLAY_TYPE_HOUSING,          "EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_housing.dds")
end

function ZO_QuestJournal_Gamepad:RegisterTooltips()
    local ICON_SIZE = 48
    local dungeonIcon = zo_iconFormat("EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_groupDungeon.dds", ICON_SIZE, ICON_SIZE)
    local raidIcon = zo_iconFormat("EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_raid.dds", ICON_SIZE, ICON_SIZE)
    local soloIcon = zo_iconFormat("EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_instance.dds", ICON_SIZE, ICON_SIZE)
    local publicDungeonIcon = zo_iconFormat("EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_dungeon.dds", ICON_SIZE, ICON_SIZE)
    local groupAreaIcon = zo_iconFormat("EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_groupArea.dds", ICON_SIZE, ICON_SIZE)
    local groupDelveIcon = zo_iconFormat("EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_groupDelve.dds", ICON_SIZE, ICON_SIZE)
    local delveIcon = zo_iconFormat("EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_delve.dds", ICON_SIZE, ICON_SIZE)
    local housingIcon = zo_iconFormat("EsoUI/Art/Journal/Gamepad/gp_questTypeIcon_housing.dds", ICON_SIZE, ICON_SIZE)

    self:RegisterTooltipText(ZO_ANY_QUEST_TYPE,     INSTANCE_DISPLAY_TYPE_SOLO,             zo_strformat(SI_GAMEPAD_QUEST_JOURNAL_INSTANCE_TYPE_SOLO, soloIcon))
    self:RegisterTooltipText(ZO_ANY_QUEST_TYPE,     INSTANCE_DISPLAY_TYPE_DUNGEON,          zo_strformat(SI_GAMEPAD_QUEST_JOURNAL_INSTANCE_TYPE_DUNGEON, dungeonIcon))
    self:RegisterTooltipText(ZO_ANY_QUEST_TYPE,     INSTANCE_DISPLAY_TYPE_RAID,             zo_strformat(SI_GAMEPAD_QUEST_JOURNAL_INSTANCE_TYPE_RAID, raidIcon))
    self:RegisterTooltipText(ZO_ANY_QUEST_TYPE,     INSTANCE_DISPLAY_TYPE_GROUP_AREA,       zo_strformat(SI_GAMEPAD_QUEST_JOURNAL_INSTANCE_TYPE_GROUP_AREA, groupAreaIcon))
    self:RegisterTooltipText(ZO_ANY_QUEST_TYPE,     INSTANCE_DISPLAY_TYPE_GROUP_DELVE,      zo_strformat(SI_GAMEPAD_QUEST_JOURNAL_INSTANCE_TYPE_GROUP_AREA, groupDelveIcon))
    self:RegisterTooltipText(ZO_ANY_QUEST_TYPE,     INSTANCE_DISPLAY_TYPE_PUBLIC_DUNGEON,   zo_strformat(SI_GAMEPAD_QUEST_JOURNAL_PUBLIC_DUNGEON, publicDungeonIcon))
    self:RegisterTooltipText(ZO_ANY_QUEST_TYPE,     INSTANCE_DISPLAY_TYPE_DELVE,            zo_strformat(SI_GAMEPAD_QUEST_JOURNAL_DELVE, delveIcon))
    self:RegisterTooltipText(ZO_ANY_QUEST_TYPE,     INSTANCE_DISPLAY_TYPE_HOUSING,          zo_strformat(SI_GAMEPAD_QUEST_JOURNAL_HOUSING, housingIcon))
end

function ZO_QuestJournal_Gamepad:GetQuestDataString()
    local repeatableText, instanceDisplayTypeText
    local questData = self:GetSelectedQuestData()

    if questData then
        local repeatableType = GetJournalQuestRepeatType(questData.questIndex)
        if repeatableType ~= QUEST_REPEAT_NOT_REPEATABLE then
            repeatableText = GetString(SI_GAMEPAD_QUEST_JOURNAL_REPEATABLE_TEXT)
        end

        if questData.dataSource then
            instanceDisplayTypeText = self:GetTooltipText(questData.dataSource.questType, questData.dataSource.displayType)
        end
    end

    return repeatableText, instanceDisplayTypeText
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
                return selectedQuestIndex ~= nil
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
                return selectedQuestIndex ~= nil
            end
        },

        -- Options
        {
            name = GetString(SI_GAMEPAD_QUEST_JOURNAL_OPTIONS),
            keybind = "UI_SHORTCUT_TERTIARY",

            callback = function()
                self:SwitchActiveList(OPTIONS_LIST)
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

    local function OptionsListBackFunction()
        self:SwitchActiveList(QUEST_LIST)
    end
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.optionsKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, OptionsListBackFunction)
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
        GAMEPAD_QUEST_JOURNAL_ROOT_SCENE:AddFragmentGroup(self.questInfoFragmentGroup)
    else
        GAMEPAD_QUEST_JOURNAL_ROOT_SCENE:RemoveFragmentGroup(self.questInfoFragmentGroup)
    end

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

    local reportQuest = ZO_GamepadEntryData:New(GetString(SI_ITEM_ACTION_REPORT_ITEM))
    reportQuest.action =    function()
                                local selectedQuestIndex = self:GetSelectedQuestIndex()
                                if selectedQuestIndex then
                                    local questName = GetJournalQuestInfo(selectedQuestIndex)
                                    self:SetKeybindButtonGroup(nil)
                                    HELP_QUEST_ASSISTANCE_GAMEPAD:InitWithDetails(questName)
                                    SCENE_MANAGER:Push(HELP_QUEST_ASSISTANCE_GAMEPAD:GetSceneName())
                                end
                            end
    table.insert(options, reportQuest)

    for _, option in pairs(options) do
        self.optionsList:AddEntry("ZO_GamepadSubMenuEntryTemplate", option)
    end

    self.optionsList:Commit()
    self.options = options
end

function ZO_QuestJournal_Gamepad:RefreshQuestMasterList()
    self.questMasterList = QUEST_JOURNAL_MANAGER:GetQuestListData()

    -- If we're showing the options list, make sure we still have the quest that we're viewing options for
    if self.currentListType == OPTIONS_LIST then
        local hasQuest = false
        for i, quest in ipairs(self.questMasterList) do
            if quest.questIndex == self:GetSelectedQuestIndex() then
                hasQuest = true
            end
        end

        if not hasQuest then
            -- Quest is no longer available...back out of the options list
            self:SwitchActiveList(QUEST_LIST)
        end
    end
end

function ZO_QuestJournal_Gamepad:RefreshQuestList()
    self.questList:Clear()

    local lastCategoryName
    for i, quest in ipairs(self.questMasterList) do
        local entry = ZO_GamepadEntryData:New(quest.name, self:GetIconTexture(quest.questType, quest.displayType))
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

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.mainKeybindStripDescriptor)
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
