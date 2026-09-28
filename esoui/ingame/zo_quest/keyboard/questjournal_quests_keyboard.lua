ZO_QuestJournal_Quests_Keyboard = ZO_QuestJournal_Shared:Subclass()

function ZO_QuestJournal_Quests_Keyboard:Initialize(control, owner)
    self.control = control
    self.owner = owner

    self.questCount = control:GetNamedChild("QuestCount")

    self.questInfoContainer = control:GetNamedChild("QuestInfoContainer")
    local questInfoScrollChildControl = self.questInfoContainer:GetNamedChild("ScrollChild")
    self.titleText = questInfoScrollChildControl:GetNamedChild("TitleText")
    self.levelText = questInfoScrollChildControl:GetNamedChild("LevelText")
    self.questIcon = questInfoScrollChildControl:GetNamedChild("QuestIcon")
    self.repeatableIcon = questInfoScrollChildControl:GetNamedChild("RepeatableIcon")
    self.repeatableText = questInfoScrollChildControl:GetNamedChild("RepeatableText")
    self.bgText = questInfoScrollChildControl:GetNamedChild("BGText")
    self.stepText = questInfoScrollChildControl:GetNamedChild("StepText")

    self.questStepContainer = control:GetNamedChild("QuestStepContainer")
    local questStepScrollChildControl = self.questStepContainer:GetNamedChild("ScrollChild")
    self.conditionTextOrLabel = questStepScrollChildControl:GetNamedChild("ConditionTextOrLabel")
    self.hintTextBulletList = ZO_BulletList:New(questStepScrollChildControl:GetNamedChild("HintTextBulletList"), "ZO_QuestJournal_HintBulletLabel", "ZO_QuestJournal_HintBullet")
    self.conditionTextBulletList = ZO_BulletList:New(questStepScrollChildControl:GetNamedChild("ConditionTextBulletList"), "ZO_QuestJournal_ConditionBulletLabel")
    self.optionalStepTextBulletList = ZO_BulletList:New(questStepScrollChildControl:GetNamedChild("OptionalStepTextBulletList"), "ZO_QuestJournal_ConditionBulletLabel")
    self.optionalStepTextLabel = questStepScrollChildControl:GetNamedChild("OptionalStepTextLabel")

    self.showOnMapKeybindButton = control:GetNamedChild("ShowOnMap")

    self:InitializeQuestList(control)

    self.fragment = ZO_SimpleSceneFragment:New(control)
    QUEST_JOURNAL_QUESTS_FRAGMENT_KEYBOARD = self.fragment
    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == ZO_STATE.SHOWING then
            if self.listDirty then
                self:RefreshQuestCount()
                self:RefreshQuestList()
            end

            -- Quest items in inventory can link via "Show in Journal" to here.
            local questToFocus = self:GetPendingJournalQuestIndex() or QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex()
            -- We only need to open this once.
            self:ClearPendingJournalQuestIndex()
            self:FocusQuestWithIndex(questToFocus)
        end
    end)

    ZO_QuestJournal_Shared.Initialize(self, control)

    --Quest tracker depends on this data for finding the next quest to focus.
    self:RefreshQuestList()
end

internalassert(ZONE_DISPLAY_TYPE_MAX_VALUE == 14, "A zone display type has been added. Please add it to RegisterIcons and RegisterTooltips")

function ZO_QuestJournal_Quests_Keyboard:RegisterIcons()
    self:RegisterIconTexture(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_SOLO,             "EsoUI/Art/Journal/journal_Quest_Instance.dds")
    self:RegisterIconTexture(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_DUNGEON,          "EsoUI/Art/Journal/journal_Quest_Group_Instance.dds")
    self:RegisterIconTexture(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_GROUP_DELVE,      "EsoUI/Art/Journal/journal_Quest_Group_Delve.dds")
    self:RegisterIconTexture(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_GROUP_AREA,       "EsoUI/Art/Journal/journal_Quest_Group_Area.dds")
    self:RegisterIconTexture(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_RAID,             "EsoUI/Art/Journal/journal_Quest_Trial.dds")
    self:RegisterIconTexture(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_PUBLIC_DUNGEON,   "EsoUI/Art/Journal/journal_Quest_Dungeon.dds")
    self:RegisterIconTexture(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_DELVE,            "EsoUI/Art/Journal/journal_Quest_Delve.dds")
    self:RegisterIconTexture(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_HOUSING,          "EsoUI/Art/Journal/journal_Quest_Housing.dds")
    self:RegisterIconTexture(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_ZONE_STORY,       "EsoUI/Art/Journal/journal_Quest_ZoneStory.dds")
    self:RegisterIconTexture(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_COMPANION,        "EsoUI/Art/Journal/journal_Quest_Companion.dds")
    self:RegisterIconTexture(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_ENDLESS_DUNGEON,  "EsoUI/Art/Journal/journal_Quest_EndlessDungeon.dds")
    self:RegisterIconTexture(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_ADVENTURE_ZONE,   "EsoUI/Art/Journal/journal_Quest_AdventureZone.dds")
    self:RegisterIconTexture(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_SOLO_DUNGEON,     "EsoUI/Art/Journal/journal_Quest_Solo_Dungeon.dds")
end

function ZO_QuestJournal_Quests_Keyboard:RegisterTooltips()
    local function ZoneStoryParamFunction(questIndex)
        if questIndex then
            local zoneId = GetJournalQuestZoneStoryZoneId(questIndex)
            return GetZoneNameById(zoneId)
        end
        return ""
    end

    self:RegisterTooltipText(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_SOLO,             SI_QUEST_JOURNAL_SOLO_TOOLTIP)
    self:RegisterTooltipText(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_DUNGEON,          SI_QUEST_JOURNAL_DUNGEON_TOOLTIP)
    self:RegisterTooltipText(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_RAID,             SI_QUEST_JOURNAL_RAID_TOOLTIP)
    -- nothing should be marked as GROUP_DELVE, but just in case treat it like GROUP      
    self:RegisterTooltipText(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_GROUP_DELVE,      SI_QUEST_JOURNAL_GROUP_TOOLTIP)
    self:RegisterTooltipText(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_GROUP_AREA,       SI_QUEST_JOURNAL_GROUP_TOOLTIP)
    self:RegisterTooltipText(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_PUBLIC_DUNGEON,   SI_QUEST_JOURNAL_PUBLIC_DUNGEON_TOOLTIP)
    self:RegisterTooltipText(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_DELVE,            SI_QUEST_JOURNAL_DELVE_TOOLTIP)
    self:RegisterTooltipText(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_HOUSING,          SI_QUEST_JOURNAL_HOUSING_TOOLTIP)
    self:RegisterTooltipText(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_ZONE_STORY,       SI_QUEST_JOURNAL_ZONE_STORY_TOOLTIP, ZoneStoryParamFunction)
    self:RegisterTooltipText(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_COMPANION,        SI_QUEST_JOURNAL_COMPANION_TOOLTIP)
    self:RegisterTooltipText(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_ENDLESS_DUNGEON,  SI_QUEST_JOURNAL_ENDLESS_DUNGEON_TOOLTIP)
    self:RegisterTooltipText(ZO_ANY_QUEST_TYPE, ZONE_DISPLAY_TYPE_SOLO_DUNGEON,     SI_QUEST_JOURNAL_SOLO_DUNGEON_TOOLTIP)
end

function ZO_QuestJournal_Quests_Keyboard:SetIconTexture(iconControl, iconData, selected)
    local texture = iconControl:GetNamedChild("Icon")
    texture.selected = selected

    local tooltipText = nil
    local texturePath = self:GetIconTexture(iconData.questType, iconData.displayType)
    if not texturePath and iconData.repeatable then
        texturePath = "EsoUI/Art/Journal/journal_Quest_Repeat.dds"
        tooltipText = GetString(SI_QUEST_JOURNAL_REPEATABLE_TOOLTIP)
    end

    if selected then
        if texturePath then
            texture:SetTexture(texturePath)
        else
            texture:SetTexture("EsoUI/Art/Journal/journal_Quest_Selected.dds")
        end

        texture:SetAlpha(1)
        texture:SetHidden(false)
    else
        if texturePath then
            texture:SetTexture(texturePath)
            texture.tooltipText = tooltipText or self:GetTooltipText(iconData.questType, iconData.displayType, iconData.questIndex)

            texture:SetAlpha(0.50)
            texture:SetHidden(false)
        else
            texture:SetHidden(true)
        end
    end
end

function ZO_QuestJournal_Quests_Keyboard:InitializeQuestList()
    self.navigationTree = ZO_Tree:New(self.control:GetNamedChild("NavigationContainerScrollChild"), 60, -10, 300)

    local function TreeHeaderSetup(node, control, name, open)
        control:SimpleArrowSetup(name, open)

        ZO_IconHeader_UpdateSize(control)
    end

    self.navigationTree:AddTemplate("ZO_SimpleArrowIconHeader", TreeHeaderSetup, nil, nil, nil, 0)

    local function TreeEntrySetup(node, control, data, open)
        control:SetText(data.name)
        control.con = GetCon(data.level)
        control.questIndex = data.questIndex

        local NOT_SELECTED = false
        control:SetSelected(NOT_SELECTED)
        self:SetIconTexture(control, data, NOT_SELECTED)
    end

    local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        self:FireCallbacks("QuestSelected", data.questIndex)
        control:SetSelected(selected)
        if selected and not reselectingDuringRebuild then
            self:RefreshDetails()
            -- The quest tracker performs focus logic on quest/remove/update, only force focus if the player has clicked on the quest through the journal UI
            if self.fragment:IsShowing() then
                FOCUSED_QUEST_TRACKER:ForceAssist(data.questIndex)
            end
        end

        self:SetIconTexture(control, data, selected)
    end

    local function TreeEntryEquality(left, right)
        return left.name == right.name
    end
    self.navigationTree:AddTemplate("ZO_QuestJournalNavigationEntry", TreeEntrySetup, TreeEntryOnSelected, TreeEntryEquality)

    self.navigationTree:SetExclusive(true)
    self.navigationTree:SetOpenAnimation("ZO_TreeOpenAnimation")
end

function ZO_QuestJournal_Quests_Keyboard:InitializeKeybindStripDescriptors()
    self.showOnMapDescriptor =
    {
        name = GetString(SI_QUEST_JOURNAL_SHOW_ON_MAP),
        keybind = "UI_SHORTCUT_SHOW_QUEST_ON_MAP",
        ethereal = true,
        callback = function()
            local selectedQuestIndex = self:GetSelectedQuestIndex()
            self:ShowOnMap(selectedQuestIndex)
        end,
        visible = function()
            local selectedQuestIndex = self:GetSelectedQuestIndex()
            if selectedQuestIndex then
                return true
            end
            return false
        end
    }

    ApplyTemplateToControl(self.showOnMapKeybindButton, "ZO_KeybindButton_Keyboard_Template")
    self.showOnMapKeybindButton:SetKeybindButtonDescriptor(self.showOnMapDescriptor)

    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Cycle Focused Quest
        {
            name = GetString(SI_QUEST_JOURNAL_CYCLE_FOCUSED_QUEST),
            keybind = "UI_SHORTCUT_QUATERNARY",
            callback = function()
                local IGNORE_SCENE_RESTRICTION = true
                local SKIP_ZONE_STORY = true
                FOCUSED_QUEST_TRACKER:AssistNext(IGNORE_SCENE_RESTRICTION, SKIP_ZONE_STORY)
                self:FocusQuestWithIndex(QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex())
            end,
            visible = function()
                return GetNumJournalQuests() >= 2
            end
        },

        -- Share Quest
        {
            name = GetString(SI_QUEST_JOURNAL_SHARE),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                local selectedQuestIndex = self:GetSelectedQuestIndex()
                if selectedQuestIndex then
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
                if selectedData and selectedData.questIndex then
                    QUEST_JOURNAL_MANAGER:ConfirmAbandonQuest(selectedData.questIndex)
                end
            end,
            visible = function()
                return self:CanAbandonQuest()
            end
        },

        self.showOnMapDescriptor,
    }
end

function ZO_QuestJournal_Quests_Keyboard:GetKeybindStripDescriptor()
    return self.keybindStripDescriptor
end

function ZO_QuestJournal_Quests_Keyboard:GetSelectedQuestData()
    return self.navigationTree:GetSelectedData()
end

function ZO_QuestJournal_Quests_Keyboard:FocusQuestWithIndex(index)
    local node = self.questIndexToTreeNode[index]

    if node then
        self.navigationTree:SelectNode(node)
    end
end

function ZO_QuestJournal_Quests_Keyboard:RefreshQuestCount()
    self.questCount:SetText(zo_strformat(SI_QUEST_CURRENT_MAX, GetNumJournalQuests(), MAX_JOURNAL_QUESTS))
end

function ZO_QuestJournal_Quests_Keyboard:RefreshQuestList()
    self.questIndexToTreeNode = {}

    ClearTooltip(InformationTooltip)

    -- Add items to the tree
    self.navigationTree:Reset()

    local categoryNodes = {}

    local categories = QUEST_JOURNAL_MANAGER:GetQuestCategories()
    for i, categoryInfo in ipairs(categories) do
        categoryNodes[categoryInfo.name] = self.navigationTree:AddNode("ZO_SimpleArrowIconHeader", categoryInfo.name)
    end

    local firstNode
    local lastNode
    local assistedNode

    local questList = QUEST_JOURNAL_MANAGER:GetQuestList()
    for i, questInfo in ipairs(questList) do
        local parent = categoryNodes[questInfo.categoryName]
        local questNode = self.navigationTree:AddNode("ZO_QuestJournalNavigationEntry", questInfo, parent)
        firstNode = firstNode or questNode
        self.questIndexToTreeNode[questInfo.questIndex] = questNode

        if lastNode then
            lastNode.nextNode = questNode
        end

        if i == #questList then
            questNode.nextNode = firstNode
        end

        if assistedNode == nil and GetTrackedIsAssisted(TRACK_TYPE_QUEST, questInfo.questIndex) then
            assistedNode = questNode
        end

        lastNode = questNode
    end

    self.navigationTree:Commit(assistedNode)

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

function ZO_QuestJournal_Quests_Keyboard:RefreshDetails()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    self.showOnMapKeybindButton:UpdateVisibility()

    local questData = self:GetSelectedQuestData()
    if not questData then
        self.questInfoContainer:SetHidden(true)
        self.questStepContainer:SetHidden(true)
        self.questIcon:SetHidden(true)
        self.repeatableIcon:SetHidden(true)
        ClearTooltip(InformationTooltip)
        return
    end

    self.questInfoContainer:SetHidden(false)
    self.questStepContainer:SetHidden(false)

    local questIndex = questData.questIndex
    local questName, bgText, stepText, stepType, stepOverrideText, completed, tracked, _, _, questType, zoneDisplayType = GetJournalQuestInfo(questIndex)
    local conColorDef = ZO_ColorDef:New(GetConColor(questData.level))
    local repeatableType = GetJournalQuestRepeatType(questIndex)

    self.titleText:SetText(zo_strformat(SI_QUEST_JOURNAL_QUEST_NAME_FORMAT, questName))
    self.levelText:SetText(zo_strformat(SI_QUEST_JOURNAL_QUEST_LEVEL, conColorDef:Colorize(tostring(questData.level))))

    local texturePath = self:GetIconTexture(questType, zoneDisplayType)
    if texturePath then
        self.questIcon:SetHidden(false)
        self.questIcon.tooltipText = self:GetTooltipText(questType, zoneDisplayType, questIndex)
        self.questIcon:SetTexture(texturePath)
    else
        self.questIcon:SetHidden(true)
    end

    local repeatable = repeatableType ~= QUEST_REPEAT_NOT_REPEATABLE
    if repeatable then
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

--XML Handlers

function ZO_QuestJournal_Quests_Keyboard.GetJournalNavigationEntryTextColor(control)
    if control.selected then
        return GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED)
    elseif control.mouseover  then
        return GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_HIGHLIGHT)
    else
        return GetColorForCon(control.con)
    end
end

function ZO_QuestJournal_Quests_Keyboard.QuestJournalNavigationEntry_OnMouseUp(label, button, upInside)
    if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then
        local node = label.node
        local questIndex = node.data.questIndex
        if questIndex then
            ClearMenu()

            AddMenuItem(GetString(SI_QUEST_JOURNAL_SHOW_ON_MAP), function() ZO_WorldMap_ShowQuestOnMap(questIndex) end)

            if GetIsQuestSharable(questIndex) and IsUnitGrouped("player") then
                AddMenuItem(GetString(SI_QUEST_JOURNAL_SHARE), function() QUEST_JOURNAL_MANAGER:ShareQuest(questIndex) end)
            end

            if node.data.canAbandon then
                AddMenuItem(GetString(SI_QUEST_JOURNAL_ABANDON), function() QUEST_JOURNAL_MANAGER:ConfirmAbandonQuest(questIndex) end)
            end

            AddMenuItem(GetString(SI_QUEST_JOURNAL_REPORT_QUEST), function()
                                                                    HELP_CUSTOMER_SUPPORT_KEYBOARD:OpenScreen(HELP_CUSTOMER_SERVICE_QUEST_ASSISTANCE_KEYBOARD:GetFragment())
                                                                    HELP_CUSTOMER_SERVICE_QUEST_ASSISTANCE_KEYBOARD:SetDetailsText(node.data.name)
                                                                end)

            ShowMenu(label)
        end
        return
    end

    ZO_ZoneStories_Manager.SetTrackedZoneStoryAssisted(false)

    ZO_TreeEntry_OnMouseUp(label, upInside)
end

function ZO_QuestJournal_Quests_Keyboard.QuestIcon_OnMouseEnter(texture)
    if texture.tooltipText and texture.tooltipText ~= "" then
        InitializeTooltip(InformationTooltip, texture, BOTTOM, 0, 0, TOP)
        SetTooltipText(InformationTooltip, texture.tooltipText)
    end
end

function ZO_QuestJournal_Quests_Keyboard.QuestIcon_OnMouseExit()
    ClearTooltip(InformationTooltip)
end
