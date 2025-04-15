-- ZO_SkillsSubclassing_ActionBar_Header_Focus_Gamepad --

ZO_SkillsSubclassing_ActionBar_Header_Focus_Gamepad = ZO_Object.MultiSubclass(ZO_AssignableActionBar, ZO_GamepadMultiFocusArea_Base)

function ZO_SkillsSubclassing_ActionBar_Header_Focus_Gamepad:Initialize(control, manager)
    ZO_AssignableActionBar.Initialize(self, control)
    ZO_GamepadMultiFocusArea_Base.Initialize(self, manager)

    local function OnSelectedActionBarButtonChanged()
        ZO_AssignableActionBar.LayoutOrClearSlotTooltip(self, GAMEPAD_LEFT_TOOLTIP)
    end

    self.keybindStripDescriptor =
    {
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = GetString(SI_BINDING_NAME_SPECIAL_MOVE_WEAPON_SWAP),
            keybind = "UI_SHORTCUT_TERTIARY",
            visible = function()
                return ACTION_BAR_ASSIGNMENT_MANAGER:ShouldShowHotbarSwap()
            end,
            enabled = function()
                return ACTION_BAR_ASSIGNMENT_MANAGER:CanCycleHotbars()
            end,
            callback = function()
                ACTION_BAR_ASSIGNMENT_MANAGER:CycleCurrentHotbar()
            end,
        }
    }

    local function BackNavigationCallback()
        if SKILLS_SUBCLASSING_GAMEPAD:IsCurrentList(SKILLS_SUBCLASSING_GAMEPAD.skillLinesList) then
            SKILLS_SUBCLASSING_GAMEPAD:ShowClassList()
        elseif SKILLS_SUBCLASSING_GAMEPAD:IsCurrentList(SKILLS_SUBCLASSING_GAMEPAD.skillsList) then
            SKILLS_SUBCLASSING_GAMEPAD:ShowClassSkillLines(SKILLS_SUBCLASSING_GAMEPAD.selectedClassId)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        else
            SCENE_MANAGER:HideCurrentScene()
        end
    end

    local function BackNavigationName()
        if SKILLS_SUBCLASSING_GAMEPAD and SKILLS_SUBCLASSING_GAMEPAD:IsCurrentList(SKILLS_SUBCLASSING_GAMEPAD.skillsList) then
            return GetString(SI_SKILLS_SUBCLASSING_EXIT_PREVIEW_ACTION)
        else
            return GetString(SI_GAMEPAD_BACK_OPTION)
        end
    end

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, BackNavigationCallback, BackNavigationName)

    self:RegisterCallback("SelectedButtonChanged", OnSelectedActionBarButtonChanged)
end

function ZO_SkillsSubclassing_ActionBar_Header_Focus_Gamepad:Activate()
    ZO_AssignableActionBar.SelectMostRecentlySelectedButton(self)
    ZO_AssignableActionBar.Activate(self)
    ZO_AssignableActionBar.LayoutOrClearSlotTooltip(self, GAMEPAD_LEFT_TOOLTIP)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_SkillsSubclassing_ActionBar_Header_Focus_Gamepad:Deactivate()
    ZO_AssignableActionBar.DeselectButtons(self)
    ZO_AssignableActionBar.Deactivate(self)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_SkillsSubclassing_ActionBar_Header_Focus_Gamepad:IsFocused()
    return ZO_GamepadMultiFocusArea_Base.IsFocused(self)
end

-- ZO_SkillsSubclassing_Training_Header_Focus_Gamepad --

ZO_SkillsSubclassing_Training_Header_Focus_Gamepad = ZO_Object.MultiSubclass(ZO_Gamepad_ParametricList_Header, ZO_GamepadMultiFocusArea_Base)

function ZO_SkillsSubclassing_Training_Header_Focus_Gamepad:Initialize(control, manager)
    ZO_Gamepad_ParametricList_Header.Initialize(self, control)
    ZO_GamepadMultiFocusArea_Base.Initialize(self, manager)
    self.label = control:GetNamedChild("ContentRatio")

    self.keybindStripDescriptor =
    {
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = GetString(SI_BINDING_NAME_SPECIAL_MOVE_WEAPON_SWAP),
            keybind = "UI_SHORTCUT_TERTIARY",
            visible = function()
                return ACTION_BAR_ASSIGNMENT_MANAGER:ShouldShowHotbarSwap()
            end,
            enabled = function()
                return ACTION_BAR_ASSIGNMENT_MANAGER:CanCycleHotbars()
            end,
            callback = function()
                ACTION_BAR_ASSIGNMENT_MANAGER:CycleCurrentHotbar()
            end,
        }
    }

    local function BackNavigationCallback()
        if SKILLS_SUBCLASSING_GAMEPAD:IsCurrentList(SKILLS_SUBCLASSING_GAMEPAD.skillLinesList) then
            SKILLS_SUBCLASSING_GAMEPAD:ShowClassList()
        elseif SKILLS_SUBCLASSING_GAMEPAD:IsCurrentList(SKILLS_SUBCLASSING_GAMEPAD.skillsList) then
            SKILLS_SUBCLASSING_GAMEPAD:ShowClassSkillLines(SKILLS_SUBCLASSING_GAMEPAD.selectedClassId)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        else
            SCENE_MANAGER:HideCurrentScene()
        end
    end

    local function BackNavigationName()
        if SKILLS_SUBCLASSING_GAMEPAD and SKILLS_SUBCLASSING_GAMEPAD:IsCurrentList(SKILLS_SUBCLASSING_GAMEPAD.skillsList) then
            return GetString(SI_SKILLS_SUBCLASSING_EXIT_PREVIEW_ACTION)
        else
            return GetString(SI_GAMEPAD_BACK_OPTION)
        end
    end

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, BackNavigationCallback, BackNavigationName)
end

function ZO_SkillsSubclassing_Training_Header_Focus_Gamepad:Activate()
    ZO_Gamepad_ParametricList_Header.Activate(self)

    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    PlaySound(SOUNDS.GAMEPAD_MENU_UP)

    local tooltipTitle = zo_strformat(SI_GAMEPAD_SKILLS_SUBCLASSING_TRAINING_TOOLTIP_TITLE, SKILLS_DATA_MANAGER:GetNumSkillLinesInTraining(), MAX_SKILL_LINES_IN_TRAINING)
    local tooltipBodyTable = {}

    local numTrainingSkillLines = SKILLS_DATA_MANAGER:GetNumSkillLinesInTraining()
    for i = 1, numTrainingSkillLines do
        local skillLineData = SKILLS_DATA_MANAGER:GetSkillLineInTrainingAtIndex(i)
        local skillLineText = zo_strformat(SI_SKILLS_SUBCLASSING_TRAINING_SKILL_LINE_FORMATTER, skillLineData:GetClassName(), skillLineData:GetName())
        table.insert(tooltipBodyTable, skillLineText)
    end

    table.insert(tooltipBodyTable, GetString(SI_SKILLS_SUBCLASSING_TRAINING_TOOLTIP_FORMATTER_INFO))

    GAMEPAD_TOOLTIPS:LayoutTitleAndMultiSectionDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, tooltipTitle, unpack(tooltipBodyTable))
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_SkillsSubclassing_Training_Header_Focus_Gamepad:Deactivate()
    ZO_Gamepad_ParametricList_Header.Deactivate(self)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_SkillsSubclassing_Training_Header_Focus_Gamepad:GetNarrationText()
    local narrations = {}

    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_SKILLS_SUBCLASSING_TRAINING_HEADER)))
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(SKILLS_SUBCLASSING_GAMEPAD.trainingLabel:GetText()))

    return narrations
end

-- ZO_SkillsSubclassing_Gamepad --

ZO_SkillsSubclassing_Gamepad = ZO_Gamepad_MultiFocus_ParametricList_Screen:Subclass()

function ZO_SkillsSubclassing_Gamepad:Initialize(control)
    self.control = control

    GAMEPAD_SKILLS_SUBCLASSING_ROOT_SCENE = ZO_InteractScene:New("gamepad_skills_subclassing_root", SCENE_MANAGER, ZO_SKILL_RESPEC_INTERACT_INFO)
    GAMEPAD_SKILLS_SCENE_GROUP:AddScene("gamepad_skills_subclassing_root")
    GAMEPAD_SKILLS_SUBCLASSING_ROOT_SCENE:SetHideSceneConfirmationCallback(ZO_GamepadSkills.OnConfirmHideScene)
    ZO_Gamepad_MultiFocus_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, nil, GAMEPAD_SKILLS_SUBCLASSING_ROOT_SCENE)

    local subclassingFragment = ZO_FadeSceneFragment:New(control)
    GAMEPAD_SKILLS_SUBCLASSING_ROOT_SCENE:AddFragment(subclassingFragment)

    self.playerClassId = GetUnitClassId("player")
    self.classIndexToIdList = {}

    local numClasses = GetNumClasses()
    for classIndex = 1, numClasses do
        local classId = GetClassIdByIndex(classIndex)
        table.insert(self.classIndexToIdList, classId)
        if classId == self.playerClassId then
            self.playerClassIndex = classIndex
        end
    end

    self:InitializeHeader()
    self:InitializeAssignableActionBar()
    self:InitializeLists()
    self:InitializeRefreshGroups()

    self:RefreshPointsDisplay()

    local function Refresh()
        if self:IsShowing() then
            self:RefreshClassSkillLinesList()
            self:RefreshHeader()
            self:RefreshPointsDisplay()
            GAMEPAD_SKILLS:RefreshCategoryList()
        end
    end

    SKILLS_AND_ACTION_BAR_MANAGER:RegisterCallback("SkillPointAllocationModeChanged", Refresh)
    SKILL_LINE_ASSIGNMENT_MANAGER:RegisterCallback("SkillLineRespecUpdate", Refresh)
    SKILLS_DATA_MANAGER:RegisterCallback("FullSystemUpdated", Refresh)
    SKILLS_DATA_MANAGER:RegisterCallback("SkillLineUpdated", Refresh)
end

function ZO_SkillsSubclassing_Gamepad:InitializeHeader()
    self.headerData =
    {
        titleText = GetString(SI_SKILLS_SUBCLASSING_ENTRY_NAME),
        subtitleText = function()
            if self:IsCurrentList(self.skillLinesList) then
                return GetClassName(GetUnitGender("player"), self.selectedClassId)
            elseif self:IsCurrentList(self.skillsList) and self.selectedSkillLineData then
                return zo_strformat(SI_GAMEPAD_SKILLS_SUBCLASSING_SKILL_LINE_TITLE_FORMATTER, self.selectedSkillLineData:GetName())
            else
                return ""
            end
        end,
        data1HeaderText = GetString(SI_GAMEPAD_SKILLS_AVAILABLE_POINTS),
        data2HeaderText = GetString(SI_GAMEPAD_SKILLS_SKY_SHARDS),
    }
    ZO_GamepadGenericHeader_SetDataLayout(self.header, ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_TOGETHER)

    self.trainingControl = self.header:GetNamedChild("Training")
    self.trainingLabel = self.trainingControl:GetNamedChild("ContentRatio")
    self.trainingHeaderFocus = ZO_SkillsSubclassing_Training_Header_Focus_Gamepad:New(self.trainingControl, self)

    local customNarrationKey = "skillSubclassingTrainingInfo"
    self.trainingHeaderFocus:SetCustomNarrationKey(customNarrationKey)

    --Narration info for the action bar
    local narrationInfo =
    {
        canNarrate = function()
            return GAMEPAD_SKILLS_SCENE_GROUP:IsShowing() and self.trainingHeaderFocus:IsActive()
        end,
        selectedNarrationFunction = function()
            return self.trainingHeaderFocus:GetNarrationText()
        end,
    }
    self.trainingHeaderFocus:RegisterNarrationInfo(narrationInfo)

    self:AddPreviousFocusArea(self.trainingHeaderFocus)
end

function ZO_SkillsSubclassing_Gamepad:InitializeAssignableActionBar()
    local actionBarControl = self.header:GetNamedChild("AssignableActionBar")
    local actionBarBg = self.control:GetNamedChild("Bg")
    actionBarBg:SetAnchor(TOPLEFT, actionBarControl, TOPLEFT, 0, -12)
    actionBarBg:SetAnchor(BOTTOMRIGHT, actionBarControl, BOTTOMRIGHT, 0, 30)

    self.assignableActionBar = ZO_SkillsSubclassing_ActionBar_Header_Focus_Gamepad:New(actionBarControl, self)

    self.actionBarAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_GamepadSkillsActionBarFocusAnimation")

    self.actionBarAnimation:GetAnimation(1):SetAnimatedControl(actionBarControl)
    self.actionBarAnimation:GetAnimation(2):SetAnimatedControl(actionBarBg)

    self.actionBarAnimation:PlayInstantlyToStart()

    self:AddPreviousFocusArea(self.assignableActionBar)
end

function ZO_SkillsSubclassing_Gamepad:SkillLineEntryTemplateSetup(control, data, selected, reselectingDuringRebuild, enabled, activated)
    local skillLineData = data.skillLineData
    if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
        data:SetText(skillLineData:GetFormattedNameWithNumPointsAllocated())
    else
        data:SetText(skillLineData:GetFormattedName())
    end
    if data.errorTooltips and #data.errorTooltips > 0 then
        data:SetNameColors(ZO_ERROR_COLOR, ZO_ERROR_COLOR:GetDim())
    end
    data.isSkillLineInTraining = skillLineData:IsInTraining()
    data.isEquippedInCurrentCategory = skillLineData:IsActive()

    ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, activated)
    ZO_GamepadSkillLineEntryTemplate_Setup(control, data, selected)
end

function ZO_SkillsSubclassing_Gamepad:InitializeLists()
    local function ClassEntryTemplateSetup(control, data, selected, reselectingDuringRebuild, enabled, activated)
        local numSkillLines = GetNumSkillLinesForClass(data.classId)
        for skillLineIndex = 1, numSkillLines do
            local skillLineId = GetSkillLineIdForClass(data.classId, skillLineIndex)
            local skillLineData = SKILLS_DATA_MANAGER:GetSkillLineDataById(skillLineId)
            if skillLineData:IsInTraining() or skillLineData:IsPendingTrain() then
                data.isSkillLineInTraining = true
            end
            if skillLineData:IsActive() then
                data.isEquippedInCurrentCategory = true
            end
        end
        data:SetIconTint(ZO_GAMEPAD_SELECTED_COLOR, ZO_GAMEPAD_UNSELECTED_COLOR)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, activated)
    end

    self.classList = self:AddList("ClassList")
    self.classList:SetOnSelectedDataChangedCallback(function(list, selectedData)
        self:OnSelectedClassChanged(selectedData)
    end)
    self.classList:AddDataTemplate("ZO_GamepadSubMenuEntryWithStatusTemplate", ClassEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)

    local function SetupSkillLinesList(list)
        list:SetAdditionalBottomSelectedItemOffsets(0, 20)
        list:SetHandleDynamicViewProperties(true)

        list:AddDataTemplate("ZO_GamepadSkillLineEntryTemplate", function(...) self:SkillLineEntryTemplateSetup(...) end, ZO_GamepadMenuEntryTemplateParametricListFunction)
    end

    self.skillLinesList = self:AddList("SkillLinesList", SetupSkillLinesList)
    self.skillLinesList:SetOnSelectedDataChangedCallback(function(list, selectedData)
        self:OnSelectedSkillChanged(selectedData)
    end)

    local function MenuAbilityEntryTemplateSetup(control, skillEntry, selected, reselectingDuringRebuild, enabled, activated)
        ZO_GamepadSkillEntryTemplate_SetEntryInfoFromAllocator(skillEntry)
        ZO_SharedGamepadEntry_OnSetup(control, skillEntry, selected, reselectingDuringRebuild, enabled, activated)
        ZO_GamepadSkillEntryTemplate_Setup(control, skillEntry, selected, activated, ZO_SKILL_ABILITY_DISPLAY_VIEW)
    end

    local function IsSkillEqual(leftSkillEntry, rightSkillEntry)
        return leftSkillEntry.skillData == rightSkillEntry.skillData
    end

    local function SetupSkillsList(list)
        list:SetHandleDynamicViewProperties(true)
        list:AddDataTemplate("ZO_GamepadAbilityEntryTemplate", MenuAbilityEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, IsSkillEqual)
        list:AddDataTemplateWithHeader("ZO_GamepadAbilityEntryTemplate", MenuAbilityEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, IsSkillEqual, "ZO_GamepadMenuEntryHeaderTemplate")
    end
    self.skillsList = self:AddList("SkillsList", SetupSkillsList)
    self.skillsList:SetOnSelectedDataChangedCallback(function(list, selectedData)
        self:OnSelectedSkillChanged(selectedData)
    end)
end

function ZO_SkillsSubclassing_Gamepad:InitializeRefreshGroups()
    -- Selected Tooltip
    local selectedTooltipRefreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_PER_FRAME)
    selectedTooltipRefreshGroup:AddDirtyState("Full", function()
        self:RefreshSelectedTooltip()
    end)
    self.selectedTooltipRefreshGroup = selectedTooltipRefreshGroup

    -- Skills List
    local skillsListRefreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_PER_FRAME)
    skillsListRefreshGroup:AddDirtyState("List", function()
        self:RefreshSkillsList()
    end)
    skillsListRefreshGroup:AddDirtyState("Visible", function()
        self.skillsList:RefreshVisible()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end)
    skillsListRefreshGroup:SetActive(function()
        return self:IsShowing() and self.selectedSkillLineData ~= nil
    end)
    self.skillsListRefreshGroup = skillsListRefreshGroup
end

function ZO_SkillsSubclassing_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Equip / Train / Open Crown Store / Navigation
        {
            name = function()
                if self:GetCurrentList() == self.skillLinesList then
                    local entryData = self:GetCurrentList():GetTargetData()
                    local skillLineData = entryData.skillLineData
                    if skillLineData:IsContentLocked() then
                        -- Open Crown Store
                        return GetString(SI_SKILLS_SUBCLASSING_OPEN_STORE_ACTION)
                    else
                        if skillLineData:CanActivateForRespec() then
                            -- Equip
                            return GetString(SI_SKILLS_SUBCLASSING_EQUIP_ACTION)
                        elseif skillLineData:CanTrain() then
                            -- Train
                            return GetString(SI_SKILLS_SUBCLASSING_TRAIN_ACTION)
                        end
                    end
                else
                    return GetString(SI_GAMEPAD_SELECT_OPTION)
                end
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                if self:GetCurrentList() == self.skillLinesList then
                    local entryData = self:GetCurrentList():GetTargetData()
                    local skillLineData = entryData.skillLineData
                    if skillLineData:IsContentLocked() then
                        -- Open Crown Store
                        local collectibleId = skillLineData:GetClassAccessCollectibleId()
                        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
                        if collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_CHAPTER) then
                            ZO_ShowChapterUpgradePlatformScreen(MARKET_OPEN_OPERATION_SKILLS_SUBCLASSING)
                        else
                            local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, collectibleData:GetName())
                            ShowMarketAndSearch(searchTerm, MARKET_OPEN_OPERATION_SKILLS_SUBCLASSING)
                        end
                    else
                        if skillLineData:CanActivateForRespec() then
                            -- Equip
                            ZO_Dialogs_ShowGamepadDialog("GAMEPAD_SWAP_SKILL_LINE_DIALOG", skillLineData, { mainTextParams = { skillLineData:GetFormattedName() }})
                        elseif skillLineData:CanTrain() then
                            -- Train
                            TriggerTutorial(TUTORIAL_TRIGGER_SUBCLASSING_TRAIN_SKILL_LINE)
                            skillLineData:Train()
                            PlaySound(SOUNDS.SKILLS_SUBCLASSING_TRAIN)
                        end
                    end
                else
                    self:SelectClass()
                end
            end,
            visible = function()
                local entryData = self:GetCurrentList():GetTargetData()
                if not entryData then
                    return false
                end

                if self:GetCurrentList() == self.skillLinesList then
                    if entryData.skillLineData then
                        if entryData.skillLineData:IsContentLocked() then
                            -- Open Crown Store
                            return true
                        elseif SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeAllowAccessToSubclassing() then
                            -- Equip / Train
                            return entryData.skillLineData:CanActivateForRespec() or entryData.skillLineData:CanTrain()
                        end
                    end
                else
                    -- Menu Navigation
                    return self:GetCurrentList() ~= self.skillsList
                end

                return false
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        -- Confirm Bind
        {
            name = GetString(SI_SKILL_RESPEC_CONFIRM_KEYBIND),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                self:ShowConfirmRespecDialog()
            end,
            visible = function()
                return SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave()
            end,
        },
        -- Weapon Swap
        {
            name = GetString(SI_BINDING_NAME_SPECIAL_MOVE_WEAPON_SWAP),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                ACTION_BAR_ASSIGNMENT_MANAGER:CycleCurrentHotbar()
            end,
            visible = function()
                return ACTION_BAR_ASSIGNMENT_MANAGER:ShouldShowHotbarSwap()
            end,
            enabled = function()
                return ACTION_BAR_ASSIGNMENT_MANAGER:CanCycleHotbars()
            end,
        },
        -- Preview Skill Line / Skill Style
        {
            name = function()
                local entryData = self:GetCurrentList():GetTargetData()
                local skillLineData = entryData.skillLineData
                if skillLineData then
                    -- Preview skill line
                    return GetString(SI_SKILLS_SUBCLASSING_PREVIEW_ACTION)
                else
                    -- Skill style
                    return GetString(SI_SKILL_STYLE_GAMEPAD_CHANGE_STYLE)
                end
            end,
            keybind = "UI_SHORTCUT_QUATERNARY",
            callback = function()
                local entryData = self:GetCurrentList():GetTargetData()
                local skillLineData = entryData.skillLineData
                if skillLineData then
                    -- Preview skill line
                    self:SelectSkillLine()
                else
                    -- Skill style
                    ZO_Dialogs_ShowGamepadDialog("GAMEPAD_SKILL_STYLE_SELECTION", { skillData = entryData.skillData })
                end
            end,
            visible = function()
                local entryData = self:GetCurrentList():GetTargetData()
                if not entryData then
                    return false
                end

                if self:GetCurrentList() == self.skillLinesList then
                    -- Preview skill line
                    return true
                elseif self:GetCurrentList() == self.skillsList then
                    -- Skill style
                    local skillData = entryData.skillData
                    local skillPointAllocator = skillData:GetPointAllocator()
                    local skillProgressionData = skillPointAllocator:GetProgressionData()
                    return skillData:IsActive() and skillProgressionData:HasAnyNonHiddenSkillStyles()
                        and not SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave()
                end
                return false
            end,
        },
        -- Untrain
        {
            name = GetString(SI_SKILLS_SUBCLASSING_UNTRAIN_ACTION),
            keybind = "UI_SHORTCUT_QUINARY",
            callback = function()
                local entryData = self:GetCurrentList():GetTargetData()
                entryData.skillLineData:Untrain()
                PlaySound(SOUNDS.SKILLS_SUBCLASSING_UNTRAIN)
            end,
            visible = function()
                if self:GetCurrentList() == self.skillLinesList and SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeAllowSkillLineTraining() then
                    local entryData = self:GetCurrentList():GetTargetData()
                    return entryData and entryData.skillLineData and entryData.skillLineData:CanUntrain()
                end
                return false
            end,
        },
    }

    local function BackNavigationCallback()
        if self:IsCurrentList(self.skillLinesList) then
            self:ShowClassList()
        elseif self:IsCurrentList(self.skillsList) then
            self:ShowClassSkillLines(self.selectedClassId)
        else
            SCENE_MANAGER:HideCurrentScene()
        end
    end

    local function BackNavigationName()
        if SKILLS_SUBCLASSING_GAMEPAD and SKILLS_SUBCLASSING_GAMEPAD:IsCurrentList(SKILLS_SUBCLASSING_GAMEPAD.skillsList) then
            return GetString(SI_SKILLS_SUBCLASSING_EXIT_PREVIEW_ACTION)
        else
            return GetString(SI_GAMEPAD_BACK_OPTION)
        end
    end

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, BackNavigationCallback, BackNavigationName)

    self:SetListsUseTriggerKeybinds(true)
end

function ZO_SkillsSubclassing_Gamepad:PerformUpdate()
    self.dirty = false
end

function ZO_SkillsSubclassing_Gamepad:RefreshHeader()
    SKILLS_DATA_MANAGER:RefreshSkillLinesInTraining()
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
    self.trainingLabel:SetText(zo_strformat(SI_GAMEPAD_SKILLS_SUBCLASSING_TRAINING_FORMATTER, SKILLS_DATA_MANAGER:GetNumSkillLinesInTraining(), MAX_SKILL_LINES_IN_TRAINING))
end

function ZO_SkillsSubclassing_Gamepad:RefreshPointsDisplay()
    local availablePoints = SKILL_POINT_ALLOCATION_MANAGER:GetAvailableSkillPoints()
    local skyShards = GetNumSkyShards()

    self.headerData.data1Text = availablePoints
    self.headerData.data2Text = zo_strformat(SI_GAMEPAD_SKILLS_SKY_SHARDS_FOUND, skyShards, NUM_PARTIAL_SKILL_POINTS_FOR_FULL)

    ZO_GamepadGenericHeader_RefreshData(self.header, self.headerData)
end

function ZO_SkillsSubclassing_Gamepad:GetMainList()
    if self.selectedClassId ~= nil then
        if self.selectedSkillLineData ~= nil then
            return self.skillsList
        else
            return self.skillLinesList
        end
    else
        return self.classList
    end
end

function ZO_SkillsSubclassing_Gamepad:OnListAreaActivate()
    self.selectedTooltipRefreshGroup:MarkDirty("Full")
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_SkillsSubclassing_Gamepad:OnListAreaDeactivate()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_SkillsSubclassing_Gamepad:SetCurrentList(list)
    ZO_Gamepad_ParametricList_Screen.SetCurrentList(self, list)

    -- Disable list input so that MultiFocus input can be used to navigate to the header
    list:SetDirectionalInputEnabled(false)
end

function ZO_SkillsSubclassing_Gamepad:OnShowing()
    local RESET_TO_TOP = true
    self:ShowClassList(RESET_TO_TOP)

    -- Always start on the list
    if not self:IsCurrentFocusArea(self.parametricListArea) then
        self.currentFocalArea = self.parametricListArea
    end

    ZO_Gamepad_MultiFocus_ParametricList_Screen.OnShowing(self)
    TriggerTutorial(TUTORIAL_TRIGGER_SUBCLASSING_SYSTEM)
end

function ZO_SkillsSubclassing_Gamepad:OnHide()
    ZO_Gamepad_MultiFocus_ParametricList_Screen.OnHide(self)
end

function ZO_SkillsSubclassing_Gamepad:ShowClassList(resetToTop)
    self.selectedClassId = nil
    self.selectedSkillLineData = nil
    self:SetCurrentList(self.classList)
    self:RefreshClassList(resetToTop)
    self:RefreshHeader()
    self:RefreshPointsDisplay()
    self:ResetFocusArea()
end

function ZO_SkillsSubclassing_Gamepad:RefreshClassList(resetToTop, appendToList)
    if appendToList ~= true then
        self.classList:Clear()
    end

    local classIcon = select(8, GetClassInfo(self.playerClassIndex))
    local gender = GetUnitGender("player")
    local classText = GetClassName(gender, self.playerClassId)
    local playerClassEntryData = ZO_GamepadEntryData:New(classText, classIcon)
    playerClassEntryData.classId = self.playerClassId
    self.classList:AddEntry("ZO_GamepadSubMenuEntryWithStatusTemplate", playerClassEntryData)

    for classIndex, classId in ipairs(self.classIndexToIdList) do
        if classId ~= self.playerClassId then
            local classIcon = select(8, GetClassInfo(classIndex))
            local classText = GetClassName(gender, classId)
            local classEntryData = ZO_GamepadEntryData:New(classText, classIcon)
            classEntryData.classId = classId
            self.classList:AddEntry("ZO_GamepadSubMenuEntryWithStatusTemplate", classEntryData)
        end
    end

    self.classList:Commit(resetToTop)

    self.selectedTooltipRefreshGroup:MarkDirty("Full")
end

function ZO_SkillsSubclassing_Gamepad:SelectClass()
    if self:IsCurrentList(self.classList) then
        local entryData = self:GetCurrentList():GetTargetData()
        if entryData then
            local classId = entryData.classId
            local resetToTop = classId ~= self.previousSelectedClassId
            self:ShowClassSkillLines(classId, resetToTop)
        end
    end
end

function ZO_SkillsSubclassing_Gamepad:ShowClassSkillLines(classId, resetToTop)
    self.selectedClassId = classId
    self.previousSelectedClassId = classId
    self.selectedSkillLineData = nil
    self:SetCurrentList(self.skillLinesList)
    self:RefreshClassSkillLinesList(resetToTop)
    self:RefreshHeader()
    self:ResetFocusArea()
end

function ZO_SkillsSubclassing_Gamepad:RefreshClassSkillLinesList(resetToTop)
    SKILLS_DATA_MANAGER:RefreshActiveClassSkillLines()
    self.skillLinesList:Clear()

    local numSkillLines = GetNumSkillLinesForClass(self.selectedClassId)
    for skillLineIndex = 1, numSkillLines do
        local skillLineId = GetSkillLineIdForClass(self.selectedClassId, skillLineIndex)
        local data = ZO_GamepadEntryData:New()
        data.skillLineData = SKILLS_DATA_MANAGER:GetSkillLineDataById(skillLineId)
        self.skillLinesList:AddEntry("ZO_GamepadSkillLineEntryTemplate", data)
    end

    self.skillLinesList:Commit(resetToTop)

    self.selectedTooltipRefreshGroup:MarkDirty("Full")
end

function ZO_SkillsSubclassing_Gamepad:RefreshSelectedTooltip()
    if not self:IsHeaderActive() then
        if self:GetCurrentList() == self.skillLinesList then
            local entryData = self:GetCurrentList():GetTargetData()
            if entryData and entryData.skillLineData then
                local IS_READ_ONLY = true
                GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
                GAMEPAD_TOOLTIPS:LayoutSkillLinePreview(GAMEPAD_LEFT_TOOLTIP, entryData.skillLineData, IS_READ_ONLY)
            end
        elseif self:GetCurrentList() == self.skillsList then
            local entryData = self:GetCurrentList():GetTargetData()
            if entryData and entryData.skillData then
                local SHOW_RANK_NEEDED_LINE = true
                local SHOW_POINT_SPEND_LINE = true
                local SHOW_ADVISED_LINE = true
                local SHOW_RESPEC_TO_FIX_BAD_MORPH_LINE = true
                --Morphs (the only actives with upgrade info) only show that info in the morph dialog tooltip. Passives show it all the time.
                local showUpgradeInfoBlock = entryData.skillData:IsPassive()
                GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
                GAMEPAD_TOOLTIPS:LayoutSkillProgression(GAMEPAD_LEFT_TOOLTIP, entryData.skillData:GetPointAllocatorProgressionData(), SHOW_RANK_NEEDED_LINE, SHOW_POINT_SPEND_LINE, SHOW_ADVISED_LINE, SHOW_RESPEC_TO_FIX_BAD_MORPH_LINE, showUpgradeInfoBlock)
            end
        elseif self:GetCurrentList() == self.classList then
            local entryData = self:GetCurrentList():GetTargetData()
            if entryData and entryData.classId then
                local classProgressionDescription
                if entryData.classId == self.playerClassId then
                    classProgressionDescription = zo_strformat(SI_GAMEPAD_SKILLS_SUBCLASSING_CLASS_CHARACTER_PROGRESSION, ZO_GAMEPAD_SELECTED_COLOR:Colorize(entryData.text))
                else
                    classProgressionDescription = zo_strformat(SI_GAMEPAD_SKILLS_SUBCLASSING_CLASS_ACCOUNT_PROGRESSION, ZO_GAMEPAD_SELECTED_COLOR:Colorize(entryData.text))
                end

                local classIndex = GetClassIndexById(entryData.classId)
                local _, lore = GetClassInfo(classIndex)
                GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
                GAMEPAD_TOOLTIPS:LayoutMultiSectionDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, classProgressionDescription, lore)
            end
        else
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        end
    end
end

function ZO_SkillsSubclassing_Gamepad:OnSelectedClassChanged()
    self.selectedTooltipRefreshGroup:MarkDirty("Full")
end

function ZO_SkillsSubclassing_Gamepad:OnSelectedSkillChanged()
    self.selectedTooltipRefreshGroup:MarkDirty("Full")
end

function ZO_SkillsSubclassing_Gamepad:SelectSkillLine()
    if self:IsCurrentList(self.skillLinesList) then
        local entryData = self:GetCurrentList():GetTargetData()
        if entryData and entryData.skillLineData then
            local resetToTop = entryData.skillLineData ~= self.previouslySelectedSkillLineData
            self:ShowSkillsList(entryData.skillLineData, resetToTop)
        end
    end
end

function ZO_SkillsSubclassing_Gamepad:ShowSkillsList(skillLineData, resetToTop)
    self.selectedSkillLineData = skillLineData
    self.previouslySelectedSkillLineData = skillLineData
    self:SetCurrentList(self.skillsList)
    self:RefreshSkillsList(resetToTop)
    self:RefreshHeader()
end

do
    local g_ShownHeaderTexts = {}

    function ZO_SkillsSubclassing_Gamepad:RefreshSkillsList(resetToTop)
        local list = self.skillsList
        g_ShownHeaderTexts = {}
        list:Clear()

        local function IsSkillVisible(skillData)
            return not skillData:IsHidden()
        end

        local skillLineData = self.selectedSkillLineData
        for _, skillData in skillLineData:SkillIterator({ IsSkillVisible }) do
            local skillEntry = ZO_GamepadEntryData:New()

            skillEntry:SetFontScaleOnSelection(false)
            skillEntry.skillData = skillData
            skillEntry.enabled = false

            local headerText = skillData:GetHeaderText()
            if not g_ShownHeaderTexts[headerText] then
                skillEntry:SetHeader(headerText)
                list:AddEntry("ZO_GamepadAbilityEntryTemplateWithHeader", skillEntry)
                g_ShownHeaderTexts[headerText] = true
            else
                list:AddEntry("ZO_GamepadAbilityEntryTemplate", skillEntry)
            end
        end

        list:Commit(resetToTop)

        self.selectedTooltipRefreshGroup:MarkDirty("Full")
    end
end

function ZO_SkillsSubclassing_Gamepad:ShowConfirmRespecDialog()
    if SKILLS_AND_ACTION_BAR_MANAGER:DoPendingChangesIncurCost() then
        if SKILLS_AND_ACTION_BAR_MANAGER:GetSkillRespecPaymentType() == RESPEC_PAYMENT_TYPE_GOLD then
            ZO_Dialogs_ShowGamepadDialog("SKILL_RESPEC_CONFIRM_GOLD_GAMEPAD")
        else
            ZO_Dialogs_ShowGamepadDialog("SKILL_RESPEC_CONFIRM_SCROLL")
        end
    else
        ZO_Dialogs_ShowGamepadDialog("SKILL_RESPEC_CONFIRM_FREE")
    end
end

-- Global Functions --

function ZO_SkillsSubclassing_Gamepad.OnControlInitialized(control)
    SKILLS_SUBCLASSING_GAMEPAD = ZO_SkillsSubclassing_Gamepad:New(control)
end

function ZO_SkillsSubclassing_Gamepad.OnDialogInitialized(control)
    ZO_GenericParametricListGamepadDialogTemplate_OnInitialized(control)

    local function DialogSkillLineEntryTemplateSetup(control, data, selected, reselectingDuringRebuild, enabled, activated)
        local skillLineData = data.skillLineData
        if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
            data:SetText(skillLineData:GetFormattedNameWithNumPointsAllocated())
        else
            data:SetText(skillLineData:GetFormattedName())
        end
        if data.errorTooltips and #data.errorTooltips > 0 then
            data:SetNameColors(ZO_ERROR_COLOR, ZO_ERROR_COLOR:GetDim())
        end
        data.isSkillLineInTraining = skillLineData:IsInTraining()

        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, activated)
        ZO_GamepadSkillLineEntryTemplate_Setup(control, data, selected)
    end

    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_SWAP_SKILL_LINE_DIALOG",
    {
        customControl = control,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.CUSTOM,
        },
        title =
        {
            text = SI_GAMEPAD_SKILLS_SUBCLASSING_SWAP_SKILL_LINE_TITLE
        },
        mainText =
        {
            text = SI_GAMEPAD_SKILLS_SUBCLASSING_SWAP_SKILL_LINE_FORMATTER,
        },
        setup = function(dialog, skillLineData)
            local parametricListEntries = dialog.info.parametricList
            ZO_ClearNumericallyIndexedTable(parametricListEntries)
            dialog.swapInSkillLineData = skillLineData

            local playerClassId = GetUnitClassId("player")
            local numActiveClassSkillLines = SKILLS_DATA_MANAGER:GetNumActiveClassSkillLines()
            local numPlayerClassActiveSkillLines = SKILLS_DATA_MANAGER:GetNumPlayerClassActiveSkillLines()
            local swapInSkillLineClassId = skillLineData:GetClassId()
            local swapInClassActiveSkillLine = SKILLS_DATA_MANAGER:GetFirstActiveSkillLineByClassId(swapInSkillLineClassId)
            local swapInSkillLineName = ZO_WHITE:Colorize(skillLineData:GetName())
            for i = 1, numActiveClassSkillLines do
                local currentSkillLineData = SKILLS_DATA_MANAGER:GetActiveClassSkillLine(i)
                local entryData = ZO_GamepadEntryData:New()
                entryData.skillLineData = currentSkillLineData
                entryData.errorTooltips = {}
                entryData.setup = DialogSkillLineEntryTemplateSetup
                local currentSkillLineName = ZO_WHITE:Colorize(currentSkillLineData:GetName())

                local currentSkillLineClassId = currentSkillLineData:GetClassId()
                if numPlayerClassActiveSkillLines <= 1 and currentSkillLineClassId == playerClassId and swapInSkillLineClassId ~= playerClassId then
                    table.insert(entryData.errorTooltips, { text = GetString(SI_SKILLS_SUBCLASSING_ERROR_MIN_PLAYER_CLASS_SKILL_LINE), style = "requirementFail" })
                end

                if swapInClassActiveSkillLine and currentSkillLineClassId ~= swapInSkillLineClassId and not swapInClassActiveSkillLine:IsPlayerClassSkillLine() then
                    table.insert(entryData.errorTooltips, { text = GetString(SI_SKILLS_SUBCLASSING_ERROR_MAX_SKILL_LINES_PER_CLASS), style = "requirementFail" })
                end

                local swapSkillPointDeficit = skillLineData:GetSwappingForRespecSkillPointsDeficit(currentSkillLineData)
                if swapSkillPointDeficit > 0 then
                    local IGNORE_ACTIVE_STATE = true
                    local numSkillPointsAllocatedInSkillLine = ZO_WHITE:Colorize(SKILL_POINT_ALLOCATION_MANAGER:GetNumPointsAllocatedInSkillLine(skillLineData, IGNORE_ACTIVE_STATE))
                    local deficitErrorText = zo_strformat(SI_SKILLS_SUBCLASSING_ERROR_NOT_ENOUGH_SKILL_POINTS_TO_SWAP, swapInSkillLineName, numSkillPointsAllocatedInSkillLine)
                    table.insert(entryData.errorTooltips, { text = deficitErrorText, style = "requirementFail" })
                end

                if #entryData.errorTooltips > 0 then
                    local headerErrorText = zo_strformat(SI_SKILLS_SUBCLASSING_SWAP_SKILL_LINE_GENERAL_ERROR_FORMATTER, currentSkillLineName, swapInSkillLineName)
                    table.insert(entryData.errorTooltips, 1, { text = headerErrorText, style = "requirementFail" })
                end

                local skillLineEntry =
                {
                    template = "ZO_GamepadSkillLineEntryTemplate",
                    entryData = entryData,
                }

                table.insert(parametricListEntries, skillLineEntry)
            end

            dialog:setupFunc()
        end,
        parametricList = {}, -- Generated Dynamically
        parametricListOnSelectionChangedCallback = function(dialog, list, newSelectedData, oldSelectedData)
            local targetControl = dialog.entryList:GetTargetControl()
            if newSelectedData and targetControl then
                if #newSelectedData.errorTooltips > 0 then
                    GAMEPAD_TOOLTIPS:LayoutMultiSectionDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, unpack(newSelectedData.errorTooltips))
                else
                    local IS_READ_ONLY = true
                    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
                    GAMEPAD_TOOLTIPS:LayoutSkillLinePreview(GAMEPAD_LEFT_TOOLTIP, newSelectedData.skillLineData, IS_READ_ONLY)
                end
            end
        end,
        buttons =
        {
            -- Select
            {
                text = SI_GAMEPAD_SELECT_OPTION,
                keybind = "DIALOG_PRIMARY",
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    local SUPPRESS_CALLBACK = true
                    targetData.skillLineData:DeactivateForRespec(SUPPRESS_CALLBACK)
                    dialog.swapInSkillLineData:ActivateForRespec()
                    PlaySound(SOUNDS.SKILLS_SUBCLASSING_SWAP_SKILL_LINE_CONFIRM)
                    local selectSkillData = dialog.swapInSkillLineData:GetSkillDataByIndex(1)
                    MAIN_MENU_GAMEPAD:ShowScene("gamepad_skills_root")
                    GAMEPAD_SKILLS:SelectSkillLineBySkillData(selectSkillData)
                end,
                enabled = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    -- Returning a string with a space as the second param ensures an error sound will play without showing any error text.
                    return #targetData.errorTooltips == 0, " "
                end,
                visible = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    return targetData and targetData.skillLineData and targetData.skillLineData:CanDeactivateForRespec()
                        and dialog.swapInSkillLineData and dialog.swapInSkillLineData:CanActivateForRespec()
                end,
            },

            -- Back
            {
                text = SI_DIALOG_CANCEL,
                keybind = "DIALOG_NEGATIVE",
            },
        },

        onHidingCallback = function(dialog)
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
            SKILLS_SUBCLASSING_GAMEPAD:OnSelectedSkillChanged()
        end,
    })
end