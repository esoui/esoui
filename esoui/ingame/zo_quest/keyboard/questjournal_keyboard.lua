ZO_QuestJournal_Keyboard = ZO_QuestJournal_Shared:Subclass()

function ZO_QuestJournal_Keyboard:New(...)
    local questJournalManager = ZO_QuestJournal_Shared.New(self)
    questJournalManager:Initialize(...)
    return questJournalManager
end

function ZO_QuestJournal_Keyboard:Initialize(control)
    self.control = control
    self.sceneName = "questJournal"

    self:RegisterIconTexture(INSTANCE_DISPLAY_TYPE_NONE, "EsoUI/Art/Journal/journal_Quest_Selected.dds")
    self:RegisterIconTexture(INSTANCE_DISPLAY_TYPE_SOLO, "EsoUI/Art/Journal/journal_Quest_Instance.dds")
    self:RegisterIconTexture(INSTANCE_DISPLAY_TYPE_GROUP, "EsoUI/Art/Journal/journal_Quest_Group_Instance.dds")
    self:RegisterIconTexture(INSTANCE_DISPLAY_TYPE_RAID, "EsoUI/Art/Journal/journal_Quest_Trial.dds")

    self.questCount = control:GetNamedChild("QuestCount")
    self.titleText = control:GetNamedChild("TitleText")
    self.levelText = control:GetNamedChild("LevelText")
    self.questIcon = control:GetNamedChild("QuestIcon")
    self.repeatableIcon = control:GetNamedChild("RepeatableIcon")
    self.repeatableText = control:GetNamedChild("RepeatableText")
    self.conditionTextOrLabel = control:GetNamedChild("ConditionTextOrLabel")
    self.hintTextBulletList = ZO_BulletList:New(control:GetNamedChild("HintTextBulletList"), "ZO_QuestJournal_HintBulletLabel", "ZO_QuestJournal_HintBullet")
    self.conditionTextBulletList = ZO_BulletList:New(control:GetNamedChild("ConditionTextBulletList"), "ZO_QuestJournal_ConditionBulletLabel")
    self.optionalStepTextBulletList = ZO_BulletList:New(control:GetNamedChild("OptionalStepTextBulletList"), "ZO_QuestJournal_ConditionBulletLabel")

    self:RefreshQuestMasterList()

    ZO_QuestJournal_Shared.Initialize(self, control)
            
    --Quest tracker depends on this data for finding the next quest to focus.
    self:RefreshQuestList()
end

function ZO_QuestJournal_Keyboard:InitializeQuestList()
    self.navigationTree = ZO_Tree:New(self.control:GetNamedChild("NavigationContainerScrollChild"), 40, -10, 300)

    local openTexture = "EsoUI/Art/Buttons/tree_open_up.dds"
    local closedTexture = "EsoUI/Art/Buttons/tree_closed_up.dds"
    local overOpenTexture = "EsoUI/Art/Buttons/tree_open_over.dds"
    local overClosedTexture = "EsoUI/Art/Buttons/tree_closed_over.dds"

    local function TreeHeaderSetup(node, control, name, open)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(name)

        control.icon:SetTexture(open and openTexture or closedTexture)
        control.iconHighlight:SetTexture(open and overOpenTexture or overClosedTexture)

        control.text:SetSelected(open)
    end

    self.navigationTree:AddTemplate("ZO_QuestJournalHeader", TreeHeaderSetup, nil, nil, nil, 0)

    local function TreeEntrySetup(node, control, data, open)
        control:SetText(data.name)
        control.con = GetCon(data.level)
        control.questIndex = data.questIndex
        control:SetSelected(false)
        
        local texture = GetControl(control, "Icon")
        texture.selected = false
        texture:SetTexture(self:GetIconTexture(data.displayType))
        texture.tooltipText = self:GetTooltipText(data.displayType)

        if data.displayType == INSTANCE_DISPLAY_TYPE_NONE then
            texture:SetHidden(true)
        else
            texture:SetAlpha(0.50)
            texture:SetHidden(false)
        end
    end

    local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        self:FireCallbacks("QuestSelected", data.questIndex)
        control:SetSelected(selected)
        if selected and not reselectingDuringRebuild then
            self:RefreshDetails()
            -- The quest tracker performs focus logic on quest/remove/update, only force focus if the player has clicked on the quest through the journal UI
            if SCENE_MANAGER:IsShowing(self.sceneName) then
                QUEST_TRACKER:ForceAssist(data.questIndex)
            end
        end

        local texture = GetControl(control, "Icon")
        texture.selected = selected
        if selected then
            texture:SetTexture("EsoUI/Art/Journal/journal_Quest_Selected.dds")
            texture:SetAlpha(1.00)
            texture:SetHidden(false)
        else
            texture:SetTexture(self:GetIconTexture(data.displayType))
            if data.displayType == INSTANCE_DISPLAY_TYPE_NONE then
                texture:SetHidden(true)
            else
                texture:SetAlpha(0.50)
                texture:SetHidden(false)
            end
        end
    end
    local function TreeEntryEquality(left, right)
        return left.name == right.name
    end
    self.navigationTree:AddTemplate("ZO_QuestJournalNavigationEntry", TreeEntrySetup, TreeEntryOnSelected, TreeEntryEquality)

    self.navigationTree:SetExclusive(true)
    self.navigationTree:SetOpenAnimation("ZO_TreeOpenAnimation")
end

function ZO_QuestJournal_Keyboard:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Cycle Focused Quest
        {
            name = GetString(SI_QUEST_JOURNAL_CYCLE_FOCUSED_QUEST),
            keybind = "UI_SHORTCUT_CYCLE_FOCUSED_QUEST",

            callback = function()
                local IGNORE_SCENE_RESTRICTION = true
                QUEST_TRACKER:AssistNext(IGNORE_SCENE_RESTRICTION)
                self:FocusQuestWithIndex(QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex())
            end,

            visible = function()
                return GetNumJournalQuests() >= 2
            end
        },

        -- Show On Map
        {
            name = GetString(SI_QUEST_JOURNAL_SHOW_ON_MAP),
            keybind = "UI_SHORTCUT_SHOW_QUEST_ON_MAP",

            callback = function()
                local selectedQuestIndex = self:GetSelectedQuestIndex()
                if(selectedQuestIndex) then
                    self:ShowOnMap(selectedQuestIndex)
                end
            end,

            visible = function()
                local selectedQuestIndex = self:GetSelectedQuestIndex()
                if(selectedQuestIndex) then
                    return true
                end
                return false
            end
        },

        -- Share Quest
        {
            name = GetString(SI_QUEST_JOURNAL_SHARE),
            keybind = "UI_SHORTCUT_TERTIARY",

            callback = function()
                local selectedQuestIndex = self:GetSelectedQuestIndex()
                if(selectedQuestIndex) then
                    QUEST_JOURNAL_MANAGER:ShareQuest(selectedQuestIndex)
                end
            end,

            visible = function()
                return self:CanShareQuest()
            end
        },

        -- Abandon Quest
        {
            name = GetString(SI_QUEST_JOURNAL_ABANDON),
            keybind = "UI_SHORTCUT_NEGATIVE",

            callback = function()
                local selectedData = self.navigationTree:GetSelectedData()
                if(selectedData and selectedData.questIndex) then
                    QUEST_JOURNAL_MANAGER:ConfirmAbandonQuest(selectedData.questIndex)
                end
            end,

            visible = function()
                return self:CanAbandonQuest()
            end
        },
    }
end

function ZO_QuestJournal_Keyboard:InitializeScenes()
    QUEST_JOURNAL_SCENE = ZO_Scene:New(self.sceneName, SCENE_MANAGER)
    QUEST_JOURNAL_SCENE:RegisterCallback("StateChange",
        function(oldState, newState)
            if(newState == SCENE_SHOWING) then
                if self.listDirty then
                    self:RefreshQuestCount()
                    self:RefreshQuestList()
                end

                self:FocusQuestWithIndex(QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex())

                KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            elseif(newState == SCENE_HIDDEN) then
                KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            end
        end)
end

function ZO_QuestJournal_Keyboard:GetSceneName()
    return self.sceneName
end

function ZO_QuestJournal_Keyboard:GetSelectedQuestData()
    return self.navigationTree:GetSelectedData()
end

function ZO_QuestJournal_Keyboard:FocusQuestWithIndex(index)
    local node = self.questIndexToTreeNode[index]

    if node then
        self.navigationTree:SelectNode(node)
    end
end

function ZO_QuestJournal_Keyboard:RefreshQuestCount()
    self.questCount:SetText(zo_strformat(SI_QUEST_CURRENT_MAX, GetNumJournalQuests(), MAX_JOURNAL_QUESTS))
end

function ZO_QuestJournal_Keyboard:RefreshQuestMasterList()
    local quests, categories, seenCategories = QUEST_JOURNAL_MANAGER:GetQuestListData()
    self.questMasterList = {
        quests = quests,
        categories = categories,
        seenCategories = seenCategories,
    }
end

function ZO_QuestJournal_Keyboard:RefreshQuestList()
    local quests = self.questMasterList.quests
    local categories = self.questMasterList.categories

    self.questIndexToTreeNode = {}

    -- Add items to the tree
    self.navigationTree:Reset()

    local categoryNodes = {}

    for i = 1, #categories do
        local categoryInfo = categories[i]
        categoryNodes[categoryInfo.name] = self.navigationTree:AddNode("ZO_QuestJournalHeader", categoryInfo.name, nil, SOUNDS.QUEST_BLADE_SELECTED)
    end

    local firstNode
    local lastNode
    for i = 1, #quests do
        local questInfo = quests[i]
        local parent = categoryNodes[questInfo.categoryName]
        local questNode = self.navigationTree:AddNode("ZO_QuestJournalNavigationEntry", questInfo, parent, SOUNDS.QUEST_SELECTED)
        firstNode = firstNode or questNode
        self.questIndexToTreeNode[questInfo.questIndex] = questNode

        if lastNode then
            lastNode.nextNode = questNode
        end

        if i == #quests then
            questNode.nextNode = firstNode
        end

        lastNode = questNode
    end

    self.navigationTree:Commit()

    self:RefreshDetails()

    self.listDirty = false
end

local function UpdateListAnchors(control, attachedTo, yOffset)
    control:ClearAnchors()
    control:SetAnchor(TOPLEFT, attachedTo, BOTTOMLEFT, 0, yOffset)
    control:SetAnchor(TOPRIGHT, attachedTo, BOTTOMRIGHT, 0, yOffset)
end

local EMPTY_LIST_Y_OFFSET = 0
local NON_EMPTY_LIST_Y_OFFSET = 10

function ZO_QuestJournal_Keyboard:RefreshDetails()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    local questData = self:GetSelectedQuestData()
    if not questData then
        self.questInfoContainer:SetHidden(true)
        self.questStepContainer:SetHidden(true)
        self.questIcon:SetHidden(true)
        self.repeatableIcon:SetHidden(true)
        return
    end

    self.questInfoContainer:SetHidden(false)
    self.questStepContainer:SetHidden(false)
    if QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex() == questData.questIndex then
        self.questIcon:SetHidden(false)
    else
        self.questIcon:SetHidden(true)
    end

    local questIndex = questData.questIndex
    local questName, bgText, stepText, stepType, stepOverrideText, completed, tracked, _, _, _, instanceDisplayType = GetJournalQuestInfo(questIndex)
    local conColorDef = ZO_ColorDef:New(GetConColor(questData.level))
    local repeatableType = GetJournalQuestRepeatType(questIndex)

    self.titleText:SetText(zo_strformat(SI_QUEST_JOURNAL_QUEST_NAME_FORMAT, questName))
    self.levelText:SetText(zo_strformat(SI_QUEST_JOURNAL_QUEST_LEVEL, conColorDef:Colorize(tostring(questData.level))))
    self.questIcon.tooltipText = self:GetTooltipText(instanceDisplayType)
    self.questIcon:SetTexture(self:GetIconTexture(instanceDisplayType))

    if repeatableType ~= QUEST_REPEAT_NOT_REPEATABLE then
        self.repeatableText:SetText(GetString(SI_QUEST_JOURNAL_REPEATABLE_TEXT))
        self.repeatableText:SetHidden(false)
        self.repeatableIcon:SetHidden(false)
    else
        self.repeatableText:SetHidden(true)
        self.repeatableIcon:SetHidden(true)
    end

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
        self.conditionTextOrLabel:SetText("")
        self.conditionTextBulletList:AddLine(goalCondition)
        self.optionalStepTextLabel:SetHidden(true)
        if self.hintTextLabel then
            self.hintTextLabel:SetHidden(true)
        end
    else
        self.bgText:SetText(bgText)
        self.stepText:SetText(stepText)

        self:BuildTextForStepVisibility(questIndex, QUEST_STEP_VISIBILITY_HINT)
        if self.hintTextLabel then
            self.hintTextLabel:SetHidden(#questStrings == 0)
        end
        for i = 1, #questStrings do
            self.hintTextBulletList:AddLine(questStrings[i])
        end

        local offset = #questStrings > 0 and NON_EMPTY_LIST_Y_OFFSET or EMPTY_LIST_Y_OFFSET
        UpdateListAnchors(self.conditionTextOrLabel, self.hintTextBulletList.control, offset)

        ZO_ClearNumericallyIndexedTable(questStrings)

        local showMultipleOrSteps = QUEST_JOURNAL_MANAGER:DoesShowMultipleOrSteps(stepOverrideText, stepType, questIndex)
        self.conditionTextOrLabel:SetText(showMultipleOrSteps and GetString(SI_QUEST_OR_DESCRIPTION) or "")
        QUEST_JOURNAL_MANAGER:BuildTextForTasks(stepOverrideText, questIndex, questStrings)

        for i = 1, #questStrings do
            self.conditionTextBulletList:AddLine(questStrings[i].name)
        end
        ZO_ClearNumericallyIndexedTable(questStrings) 

        self:BuildTextForStepVisibility(questIndex, QUEST_STEP_VISIBILITY_OPTIONAL)
        self.optionalStepTextLabel:SetHidden(#questStrings == 0)
        for i = 1, #questStrings do
            self.optionalStepTextBulletList:AddLine(questStrings[i])
        end
        ZO_ClearNumericallyIndexedTable(questStrings) 
    end
end

function ZO_QuestJournal_Keyboard:GetNextSortedQuestForQuestIndex(questIndex)
    if self.questMasterList and self.questMasterList.quests then
        local quests = self.questMasterList.quests
        for i, quest in ipairs(quests) do
            if quest.questIndex == questIndex then
                local nextQuest = (i == #quests) and 1 or (i + 1)
                return quests[nextQuest].questIndex
            end
        end
    end
end

--XML Handlers

do
    local function OnMouseEnter(control)
        ZO_SelectableLabel_OnMouseEnter(control.text)
        control.iconHighlight:SetHidden(false)
    end

    local function OnMouseExit(control)
        ZO_SelectableLabel_OnMouseExit(control.text)
        control.iconHighlight:SetHidden(true)
    end

    local function OnMouseUp(control, upInside)
        ZO_TreeHeader_OnMouseUp(control, upInside)
    end

    function ZO_QuestJournalHeader_OnInitialized(self)
        self.icon = self:GetNamedChild("Icon")
        self.iconHighlight = self.icon:GetNamedChild("Highlight")
        self.text = self:GetNamedChild("Text")

        self.OnMouseEnter = OnMouseEnter
        self.OnMouseExit = OnMouseExit
        self.OnMouseUp = OnMouseUp
    end
end

function ZO_QuestJournalNavigationEntry_GetTextColor(self)
    if self.selected then
        return GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED)
    elseif self.mouseover  then
        return GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_HIGHLIGHT)
    else
        return GetColorForCon(self.con)
    end
end

function ZO_QuestJournalNavigationEntry_OnMouseUp(label, button, upInside)
    if(button == MOUSE_BUTTON_INDEX_RIGHT and upInside) then

        local node = label.node
        local questIndex = node.data.questIndex
        if questIndex then
            ClearMenu()

            AddMenuItem(GetString(SI_QUEST_JOURNAL_SHOW_ON_MAP), function() ZO_WorldMap_ShowQuestOnMap(questIndex) end)
            if GetIsQuestSharable(questIndex) and IsUnitGrouped("player") then
                AddMenuItem(GetString(SI_QUEST_JOURNAL_SHARE), function() QUEST_JOURNAL_MANAGER:ShareQuest(questIndex) end)
            end
            if(node.data.questType ~= QUEST_TYPE_MAIN_STORY) then
                AddMenuItem(GetString(SI_QUEST_JOURNAL_ABANDON), function() QUEST_JOURNAL_MANAGER:ConfirmAbandonQuest(questIndex) end)
            end

            AddMenuItem(GetString(SI_QUEST_JOURNAL_REPORT_QUEST), function() ZO_FEEDBACK:OpenBrowserByType(BROWSER_TYPE_USER_QUEST_HELP, questIndex - 1) end)

            ShowMenu(label)
        end
        return
    end
    ZO_TreeEntry_OnMouseUp(label, upInside)
end

function ZO_QuestJournal_Keyboard_OnInitialized(control)
    QUEST_JOURNAL_KEYBOARD = ZO_QuestJournal_Keyboard:New(control)
    SYSTEMS:RegisterKeyboardObject("questJournal", QUEST_JOURNAL_KEYBOARD)
end

function ZO_QuestJournal_OnQuestIconMouseEnter(texture)
    if texture.tooltipText and texture.tooltipText ~= "" then
        InitializeTooltip(InformationTooltip, texture, BOTTOM, 0, 0, TOP)
        SetTooltipText(InformationTooltip, texture.tooltipText)
    end
end

function ZO_QuestJournal_OnQuestIconMouseExit()
    ClearTooltip(InformationTooltip)
end