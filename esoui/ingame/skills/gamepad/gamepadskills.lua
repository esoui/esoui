ZO_GamepadSkills = ZO_Gamepad_ParametricList_Screen:Subclass()

local ACTION_BAR_ID = 1

local GAMEPAD_ALERT_TEXTURES =
{
    [ZO_SKILLS_MORPH_STATE] = {normal = "EsoUI/Art/Progression/Gamepad/gp_morph.dds", mouseDown = "EsoUI/Art/Progression/Gamepad/gp_morph.dds", mouseover = "EsoUI/Art/Progression/Gamepad/gp_morph.dds"},
    [ZO_SKILLS_PURCHASE_STATE] = {normal = "EsoUI/Art/Progression/Gamepad/gp_purchase.dds", mouseDown = "EsoUI/Art/Progression/Gamepad/gp_purchase.dds", mouseover = "EsoUI/Art/Progression/Gamepad/gp_purchase.dds"},
}

function ZO_GamepadSkills:New(...)
    local gamepadSkills = ZO_Gamepad_ParametricList_Screen.New(self, ...)
    return gamepadSkills
end

local SKILL_LIST_BROWSE_MODE = 1
local BUILD_PLANNER_ASSIGN_MODE = 2
local ABILITY_LIST_BROWSE_MODE = 3
local SINGLE_ABILITY_ASSIGN_MODE = 4

function ZO_GamepadSkills:Initialize(control)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)

    self.trySetClearNewFlagCallback = function(callId)
        self:TrySetClearNewFlag(callId)
    end

    local skillLineXPBarFragment = ZO_FadeSceneFragment:New(ZO_GamepadSkillsTopLevelSkillInfo)

    GAMEPAD_SKILLS_ROOT_SCENE = ZO_Scene:New("gamepad_skills_root", SCENE_MANAGER)
    GAMEPAD_SKILLS_ROOT_SCENE:AddFragment(skillLineXPBarFragment)
    GAMEPAD_SKILLS_ROOT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        ZO_Gamepad_ParametricList_Screen.OnStateChanged(self, oldState, newState)
        if newState == SCENE_SHOWING then
            GAMEPAD_TOOLTIPS:SetBottomRailHidden(GAMEPAD_LEFT_TOOLTIP, true)
            GAMEPAD_TOOLTIPS:SetBottomRailHidden(GAMEPAD_RIGHT_TOOLTIP, true)

            self:SetMode(SKILL_LIST_BROWSE_MODE)
            self:RefreshHeader(GetString(SI_MAIN_MENU_SKILLS))
            self.assignableActionBar:RefreshAllButtons()
            self:RefreshCategoryList()
            self:RefreshPointsDisplay()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.categoryKeybindStripDescriptor)

            TriggerTutorial(TUTORIAL_TRIGGER_COMBAT_SKILLS_OPENED)
            if self.showAttributeDialog then
                --Defer dialog call in case we're entering the scene from the base scene. This is to
                --ensure the dialog's keybind layer is added after the other layers, and not before.
                local function ShowDialog()
                    if SCENE_MANAGER:IsShowing("gamepad_skills_root") then
                        ZO_Dialogs_ShowGamepadDialog("GAMEPAD_SKILLS_ATTRIBUTE_PURCHASE", nil, nil)
                    end
                end
                zo_callLater(ShowDialog, 20)
            end
        elseif newState == SCENE_SHOWN then
            --If we entered skills with the action bar selected make sure to activate it. We do this in shown because fragments are set to showing after
            --the scene is which means the action bar is still hidden on showing which prevents activating it.
            if self.mode == SKILL_LIST_BROWSE_MODE then
                if self.categoryList:GetSelectedData() == ACTION_BAR_ID then
                    self:ActivateAssignableActionBarFromList()
                end
            end
        elseif newState == SCENE_HIDDEN then
            self:DisableCurrentList()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.categoryKeybindStripDescriptor)
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_RIGHT_TOOLTIP)
        end
    end)

    GAMEPAD_SKILLS_LINE_FILTER_SCENE = ZO_Scene:New("gamepad_skills_line_filter", SCENE_MANAGER)
    GAMEPAD_SKILLS_LINE_FILTER_SCENE:AddFragment(skillLineXPBarFragment)
    GAMEPAD_SKILLS_LINE_FILTER_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        ZO_Gamepad_ParametricList_Screen.OnStateChanged(self, oldState, newState)
        if newState == SCENE_SHOWING then
            self:SetMode(ABILITY_LIST_BROWSE_MODE)
            self:RefreshHeader(self.categoryList:GetTargetData().text)
            self.assignableActionBar:RefreshAllButtons()
            self:RefreshLineFilterList()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.lineFilterKeybindStripDescriptor)
        elseif newState == SCENE_HIDDEN then
            self:DisableCurrentList()
            self:TryClearNewStatus()
            self.clearNewStatusCallId = nil
            self.clearNewStatusSkillType = nil
            self.clearNewStatusSkillLineIndex = nil
            self.clearNewStatusAbilityIndex = nil
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.lineFilterKeybindStripDescriptor)
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_RIGHT_TOOLTIP)
             if self.mode == SINGLE_ABILITY_ASSIGN_MODE then
                self.actionBarAnimation:PlayInstantlyToStart()
            end
        end
    end)

    local ALWAYS_ANIMATE = true
    GAMEPAD_SKILLS_BUILD_PLANNER_FRAGMENT = ZO_FadeSceneFragment:New(self.control:GetNamedChild("BuildPlannerContainer"), ALWAYS_ANIMATE)
    GAMEPAD_SKILLS_BUILD_PLANNER_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self.modeBeforeBuildPlannerShow = self.mode
            if self.modeBeforeBuildPlannerShow == SKILL_LIST_BROWSE_MODE then
                KEYBIND_STRIP:RemoveKeybindButtonGroup(self.categoryKeybindStripDescriptor)
            elseif self.modeBeforeBuildPlannerShow == ABILITY_LIST_BROWSE_MODE then
                KEYBIND_STRIP:RemoveKeybindButtonGroup(self.lineFilterKeybindStripDescriptor)
            end

            self:SetMode(BUILD_PLANNER_ASSIGN_MODE)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.buildPlannerKeybindStripDescriptor)

            self:RefreshSelectedTooltip()
        elseif newState == SCENE_HIDING then
            self.assignableActionBar:SetLockMode(ASSIGNABLE_ACTION_BAR_LOCK_MODE_NONE)

        elseif newState == SCENE_HIDDEN then
            self.buildPlannerList:Deactivate()

            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.buildPlannerKeybindStripDescriptor)
         
            if self.modeBeforeBuildPlannerShow == SKILL_LIST_BROWSE_MODE then
                KEYBIND_STRIP:AddKeybindButtonGroup(self.categoryKeybindStripDescriptor)
            elseif self.modeBeforeBuildPlannerShow == ABILITY_LIST_BROWSE_MODE then
                KEYBIND_STRIP:AddKeybindButtonGroup(self.lineFilterKeybindStripDescriptor)
            end
            self:SetMode(self.modeBeforeBuildPlannerShow)
            self.modeBeforeBuildPlannerShow = nil

            self:RefreshSelectedTooltip()
        end
    end)

    local GAMEPAD_SKILLS_SCENE_GROUP = ZO_SceneGroup:New("gamepad_skills_root", "gamepad_skills_line_filter")   
    GAMEPAD_SKILLS_SCENE_GROUP:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_GROUP_SHOWING then
            self:PerformDeferredInitialization()
            self.showAttributeDialog = GetAttributeUnspentPoints() > 0
        end
    end)

    control:SetHandler("OnUpdate", function(_, currentFrameTimeSeconds) self:OnUpdate(currentFrameTimeSeconds) end)
end

function ZO_GamepadSkills:PerformUpdate()
    -- Include update functionality here if the screen uses self.dirty to track needing to update
    self.dirty = false
end

function ZO_GamepadSkills:PerformDeferredInitialization()
    if self.categoryKeybindStripDescriptor then return end

    self:InitializeHeader()
    self:InitializeAssignableActionBar()
    self:InitializeCategoryList()
    self:InitializeLineFilterList()
    self:InitializeMorphDialog()
    self:InitializePurchaseAndUpgradeDialog()
    self:InitializeAttributeDialog()
    self:InitializeBuildPlanner()
    self:InitializeKeybindStrip()

    self:InitializeEvents()
end

local ACTION_NONE = 1
local ACTION_PURCHASE = 2
local ACTION_UPGRADE = 3
local ACTION_MORPH = 4

local function GetAbilityAction(skillType, skillLineIndex, abilityIndex)
    local availablePoints = GetAvailableSkillPoints()

    if availablePoints > 0 then
        local _, _, earnedRank, passive, ultimate, purchased, progressionIndex = GetSkillAbilityInfo(skillType, skillLineIndex, abilityIndex)
        local _, lineRank = GetSkillLineInfo(skillType, skillLineIndex)

        if not purchased then
            if lineRank >= earnedRank then
                return ACTION_PURCHASE
            end

            return ACTION_NONE
        end

        local atMorph = progressionIndex and select(4, GetAbilityProgressionXPInfo(progressionIndex))
        if atMorph then
            return ACTION_MORPH
        end

        local _, _, nextUpgradeEarnedRank = GetSkillAbilityNextUpgradeInfo(skillType, skillLineIndex, abilityIndex)

        if nextUpgradeEarnedRank and lineRank >= nextUpgradeEarnedRank then
            return ACTION_UPGRADE
        end
    end

    return ACTION_NONE
end

function ZO_GamepadSkills:InitializeHeader()
    self.headerData =
    {
        titleText = GetString(SI_MAIN_MENU_SKILLS),
        data1HeaderText = GetString(SI_GAMEPAD_SKILLS_AVAILABLE_POINTS),       
        data2HeaderText = GetString(SI_GAMEPAD_SKILLS_SKY_SHARDS),               
    }
    ZO_GamepadGenericHeader_SetDataLayout(self.header, ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_TOGETHER)
end

function ZO_GamepadSkills:RefreshHeader(headerTitle)
    self.headerData.titleText = headerTitle

    ZO_GamepadGenericHeader_RefreshData(self.header, self.headerData)
end

local function IsEntryHeader(data)
    if data == ACTION_BAR_ID then
        return true
    end
    return data.header
end

local function IsEqual(left, right)
    if left == ACTION_BAR_ID or right == ACTION_BAR_ID then
        return left == right
    end
    return left.skillType == right.skillType and left.skillLineIndex == right.skillLineIndex
end

function ZO_GamepadSkills:InitializeKeybindStrip()
    local function Back()
        self:Back()
    end

    self.categoryKeybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        {
            name =  function() --name
                local selectedData = self.categoryList:GetTargetData()
                if selectedData == ACTION_BAR_ID then
                    return GetString(SI_GAMEPAD_SKILLS_BUILD_PLANNER)
                end
                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end,

            keybind = "UI_SHORTCUT_PRIMARY",

            callback =  function()
                --Here we determine what fragment to load, but we're going to wait until it loads to decide how to populate it
                --So we'll prevent any further movement and proceed based on what we expect the selected data to be by the time we need it.
                --We may already be in the process of a scroll, so "current data" isn't reliable.
                if not IsActionBarSlottingAllowed() then
                    ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, SI_SKILLS_DISABLED_SPECIAL_ABILITIES)
                    return false
                end

                self:DeactivateCurrentList()
                local selectedData = self.categoryList:GetTargetData()
                if selectedData == ACTION_BAR_ID then
                    self:RefreshSelectedTooltip()
                    SCENE_MANAGER:AddFragment(GAMEPAD_SKILLS_BUILD_PLANNER_FRAGMENT)
                    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
                else
                    SCENE_MANAGER:Push("gamepad_skills_line_filter")
                end
            end,
        }
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.categoryKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, Back)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.categoryKeybindStripDescriptor, self.categoryList, IsEntryHeader)

    self.lineFilterKeybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        {
            name = GetString(SI_GAMEPAD_SKILLS_ASSIGN),

            keybind = "UI_SHORTCUT_SECONDARY",

            visible = function()
                if self.mode ~= ABILITY_LIST_BROWSE_MODE then
                    return false
                end
                local selectedData = self.lineFilterList:GetTargetData()
                if selectedData and selectedData ~= ACTION_BAR_ID then
                    return (selectedData.isActive or selectedData.isUltimate) and selectedData.purchased
                end
            end,

            callback = function()
                local selectedData = self.lineFilterList:GetTargetData()
                if ZO_Skills_AbilityFailsWerewolfRequirement(selectedData.skillType, selectedData.skillLineIndex) then
                    ZO_Skills_OnlyWerewolfAbilitiesAllowedAlert()
                else
                    self:DeactivateCurrentList()
                    self:StartSingleAbilityAssignment(selectedData.skillType, selectedData.skillLineIndex, selectedData.abilityIndex)
                    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
                end
            end,
        },

        {
            name = function()
                local selectedData = self.lineFilterList:GetTargetData()
                if selectedData and selectedData ~= ACTION_BAR_ID then
                    if self.mode == SINGLE_ABILITY_ASSIGN_MODE then
                        return GetString(SI_GAMEPAD_SKILLS_ASSIGN)
                    end
                    local actionType = GetAbilityAction(selectedData.skillType, selectedData.skillLineIndex, selectedData.abilityIndex)
                    if actionType == ACTION_PURCHASE or actionType == ACTION_UPGRADE then
                        return GetString(SI_GAMEPAD_SKILLS_PURCHASE)
                    elseif actionType == ACTION_MORPH then
                        return GetString(SI_GAMEPAD_SKILLS_MORPH)
                    end
                else
                    return GetString(SI_GAMEPAD_SKILLS_BUILD_PLANNER)
                end
            end,

            keybind = "UI_SHORTCUT_PRIMARY",

            visible = function()
                local selectedData = self.lineFilterList:GetTargetData()
                if self.mode == SINGLE_ABILITY_ASSIGN_MODE or selectedData == ACTION_BAR_ID then
                    return true
                end
            
                if selectedData then
                    return GetAbilityAction(selectedData.skillType, selectedData.skillLineIndex, selectedData.abilityIndex) ~= ACTION_NONE
                end
            end,

            callback = function()
                local selectedData = self.lineFilterList:GetTargetData()
                if selectedData ~= ACTION_BAR_ID  then
                    if self.mode == ABILITY_LIST_BROWSE_MODE then
                        local actionType = GetAbilityAction(selectedData.skillType, selectedData.skillLineIndex, selectedData.abilityIndex)
                        local name,icon,_,_,_,_,progressionIndex = GetSkillAbilityInfo(selectedData.skillType, selectedData.skillLineIndex, selectedData.abilityIndex)
                        local availablePoints = GetAvailableSkillPoints()
                        
                        if actionType == ACTION_PURCHASE then
                            local labelData = { titleParams = { availablePoints }, mainTextParams = { name } }
                            local callbackData = {skillType = selectedData.skillType, skillLineIndex = selectedData.skillLineIndex, abilityIndex = selectedData.abilityIndex, }

                            ZO_Dialogs_ShowGamepadDialog("GAMEPAD_SKILLS_PURCHASE_CONFIRMATION", callbackData, labelData)
                        elseif actionType == ACTION_UPGRADE then
                            local labelData = { titleParams = { availablePoints }, mainTextParams = { name } }
                            local callbackData = {skillType = selectedData.skillType, skillLineIndex = selectedData.skillLineIndex, abilityIndex = selectedData.abilityIndex, }

                            ZO_Dialogs_ShowGamepadDialog("GAMEPAD_SKILLS_UPGRADE_CONFIRMATION", callbackData, labelData)
                        elseif actionType == ACTION_MORPH then               
                            local labelData = { titleParams = { availablePoints }, mainTextParams = { name } }
                            local callbackData = {progressionIndex = progressionIndex }

                            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
                            ZO_Dialogs_ShowGamepadDialog("GAMEPAD_SKILLS_MORPH_CONFIRMATION", callbackData, labelData)
                        end
                    elseif self.mode == SINGLE_ABILITY_ASSIGN_MODE then
                        self:DeactivateCurrentList()
                        self.assignableActionBar:SetAbility(self.singleAbilitySkillType, self.singleAbilitySkillLineIndex, self.singleAbilityAbilityIndex)
                        self.actionBarAnimation:PlayBackward()
                        self.assignableActionBar:SetSelectedButton(nil)
                        self.assignableActionBar:Deactivate()
                        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
                        PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
                        --Don't set mode back to ABILITY_LIST_BROWSE_MODE til OnAbilityFinalizedCallback says everything worked
                    end
                else
                    self:DeactivateCurrentList()
                    SCENE_MANAGER:AddFragment(GAMEPAD_SKILLS_BUILD_PLANNER_FRAGMENT)
                    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
                end
            end,
        }
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.lineFilterKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, Back)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.lineFilterKeybindStripDescriptor, self.lineFilterList, IsEntryHeader)

    self.buildPlannerKeybindStripDescriptor = {}
    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.buildPlannerKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON,
        function() --callback
            self:AssignSelectedBuildPlannerAbility()
        end,
        GetString(SI_GAMEPAD_SKILLS_ASSIGN) --name
    )
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.buildPlannerKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, Back)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.buildPlannerKeybindStripDescriptor, self.buildPlannerList)

    self:AddWeaponSwapDescriptor(self.categoryKeybindStripDescriptor)
    self:AddWeaponSwapDescriptor(self.lineFilterKeybindStripDescriptor)
    self:AddWeaponSwapDescriptor(self.buildPlannerKeybindStripDescriptor)

end

function ZO_GamepadSkills:AddWeaponSwapDescriptor(descriptor)
    descriptor[#descriptor + 1] =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        name = GetString(SI_BINDING_NAME_SPECIAL_MOVE_WEAPON_SWAP),
        keybind = "UI_SHORTCUT_TERTIARY",
        visible =   function()
                        return GetUnitLevel("player") >= GetWeaponSwapUnlockedLevel()
                    end,
        enabled =   function()
                        local _, isWeaponSwapDisabled = GetActiveWeaponPairInfo()
                        return not isWeaponSwapDisabled
                    end,
        callback = OnWeaponSwap,
    }
end

function ZO_GamepadSkills:InitializeAssignableActionBar()
    local actionBarControl = CreateControlFromVirtual("$(parent)AssignableActionBar", self.header, "ZO_GamepadSkillsActionBarTemplate")
    local Y_OFFSET = 60
    actionBarControl:SetAnchor(TOP, self.header:GetNamedChild("Message"), BOTTOM, 0, Y_OFFSET)
    --Bg is child of Toplevel so it isn't cut off by scroll mask.
    local actionBarBg = self.control:GetNamedChild("Bg")
    actionBarBg:SetAnchor(TOPLEFT, actionBarControl, TOPLEFT, 0, -12)
    actionBarBg:SetAnchor(BOTTOMRIGHT, actionBarControl, BOTTOMRIGHT, 0, 30)

    self.assignableActionBar = ZO_AssignableActionBar:New(actionBarControl)
    actionBarControl:SetHandler("OnEffectivelyHidden", function() self.assignableActionBar:Deactivate() end)
    self.assignableActionBar:SetOnAbilityFinalizedCallback(function()
        if self.mode == SINGLE_ABILITY_ASSIGN_MODE then
            self.singleAbilitySkillType = nil
            self.singleAbilitySkillLineIndex = nil
            self.singleAbilityAbilityIndex = nil
            self:SetMode(ABILITY_LIST_BROWSE_MODE)
        end
    end)

    local function OnSelectedActionBarButtonChanged(actionBar, didSlotTypeChange)
        self:RefreshSelectedTooltip()
        if actionBar:GetSelectedSlotId() then
            self.assignableActionBarSelectedId = actionBar:GetSelectedSlotId()
        end
        if self.mode == BUILD_PLANNER_ASSIGN_MODE then
            if didSlotTypeChange then
                self:RefreshBuildPlannerList()
            end
        end
    end

    self.assignableActionBar:SetOnSelectedDataChangedCallback(OnSelectedActionBarButtonChanged)

    self.actionBarAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("GamepadSkillsSingleAssignActionBarAnimation")

    self.actionBarAnimation:GetAnimation(1):SetAnimatedControl(actionBarControl)
    self.actionBarAnimation:GetAnimation(2):SetAnimatedControl(actionBarBg)

    self.actionBarAnimation:PlayInstantlyToStart()
end

function ZO_GamepadSkills:ActivateAssignableActionBarFromList()
    --Only activate the action bar if it is showing. You could start moving toward it being selected and then close the window
    --before selection happens, then the selection happens when the window is closed an the bar activates (ESO-490544).
    if not self.assignableActionBar:GetControl():IsHidden() then
        if self.assignableActionBarSelectedId then
            self.assignableActionBar:SetSelectedButtonBySlotId(self.assignableActionBarSelectedId)
        else
            self.assignableActionBar:SetSelectedButton(1)
        end
        self.assignableActionBar:Activate()
    end
end

function ZO_GamepadSkills:SelectableActionBarSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    if data == ACTION_BAR_ID and selected then        
        self:ActivateAssignableActionBarFromList()
    --when weapon swapping or assigning in these mode we want the selected button to stay selected
    elseif self.mode ~= SINGLE_ABILITY_ASSIGN_MODE and self.mode ~= BUILD_PLANNER_ASSIGN_MODE  then 
        self.assignableActionBar:SetSelectedButton(nil)
        self.assignableActionBar:Deactivate()
    end
end

function ZO_GamepadSkills:InitializeCategoryList()
    self.skillInfo = self.control:GetNamedChild("SkillInfo")

    local function MenuEntryTemplateSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, activated)
        ZO_GamepadSkillLineEntryTemplate_Setup(control, data.skillType, data.skillLineIndex, selected)
        if selected then
            ZO_GamepadSkillLineXpBar_Setup(data.skillType, data.skillLineIndex, self.skillInfo.xpBar, self.skillInfo.name, true)
        end
    end

    local function ActionBarSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
        self:SelectableActionBarSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
        self.skillInfo:SetHidden(selected)
    end

	local function SetupCategoryList(list)
        list:SetAdditionalBottomSelectedItemOffsets(0, 20)

        list:AddDataTemplate("ZO_GamepadSkillLineEntryTemplate", MenuEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, IsEqual)
        list:AddDataTemplateWithHeader("ZO_GamepadSkillLineEntryTemplate", MenuEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, IsEqual, "ZO_GamepadMenuEntryHeaderTemplate")

        list:AddDataTemplate("ZO_GamepadSkillsDummyMenuEntry", ActionBarSetup)
	end

    self.categoryList = self:AddList("Category", SetupCategoryList)
    self.categoryList:SetDefaultSelectedIndex(2)--start with the first Ability selected since the first item is the action bar

    self.categoryList:SetOnSelectedDataChangedCallback(
    function(_, selectedData)
        self:RefreshSelectedTooltip()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.categoryKeybindStripDescriptor)
    end)
end

local function MenuAbilityEntryTemplateSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, activated)
    ZO_GamepadAbilityEntryTemplate_Setup(control, data, selected, activated)
end

local function IsSkillEqual(left, right)
    return left.skillType == right.skillType and left.skillLineIndex == right.skillLineIndex and left.abilityIndex == right.abilityIndex
end

function ZO_GamepadSkills:InitializeLineFilterList()
    local function ActionBarSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
        self:SelectableActionBarSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    end

    local function SetupLineFilterList(list)
        list:AddDataTemplate("ZO_GamepadAbilityEntryTemplate", MenuAbilityEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, IsSkillEqual)
        list:AddDataTemplateWithHeader("ZO_GamepadAbilityEntryTemplate", MenuAbilityEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, IsSkillEqual, "ZO_GamepadMenuEntryHeaderTemplate")
        list:AddDataTemplate("ZO_GamepadSkillsDummyMenuEntry", ActionBarSetup)
    end

    local lineFilterPreviewContainer = ZO_GamepadSkillsLinePreview:GetNamedChild("ScrollContainer")
    local lineFilterPreviewList = ZO_ParametricScrollList:New(lineFilterPreviewContainer:GetNamedChild("List"), PARAMETRIC_SCROLL_LIST_VERTICAL)
    lineFilterPreviewList:SetHeaderPadding(GAMEPAD_HEADER_DEFAULT_PADDING, 0)
    lineFilterPreviewList:SetUniversalPostPadding(GAMEPAD_DEFAULT_POST_PADDING)
    lineFilterPreviewList:SetSelectedItemOffsets(0, 0)
    lineFilterPreviewList:SetAlignToScreenCenter(true)

    lineFilterPreviewList:AddDataTemplate("ZO_GamepadAbilityEntryTemplate", MenuAbilityEntryTemplateSetup, nil, IsSkillEqual)
    lineFilterPreviewList:AddDataTemplateWithHeader("ZO_GamepadAbilityEntryTemplate", MenuAbilityEntryTemplateSetup, nil, IsSkillEqual, "ZO_GamepadMenuEntryHeaderTemplate")

    self.lineFilterPreviewList = lineFilterPreviewList
    self.lineFilterPreviewWarning = lineFilterPreviewContainer:GetNamedChild("Warning")

    self.lineFilterList = self:AddList("LineFilter", SetupLineFilterList)

    self.lineFilterList:SetDefaultSelectedIndex(2)--start with the first Ability selected since the first item is the action bar

    self.lineFilterList:SetOnSelectedDataChangedCallback(function(list, selectedData)
        self:OnSelectedAbilityChanged(selectedData)
    end)
end

local function MenuEntryHeaderTemplateSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    control.header:SetText(data.header)
    control.skillRankHeader:SetText(data.lineRank)
end

function ZO_GamepadSkills:InitializeBuildPlanner()
    local buildPlannerControl = self.control:GetNamedChild("BuildPlanner"):GetNamedChild("Container"):GetNamedChild("List")

    self.buildPlannerList = ZO_GamepadVerticalParametricScrollList:New(buildPlannerControl)
    self.buildPlannerList:SetAlignToScreenCenter(true)
    self.buildPlannerList:SetNoItemText(GetString(SI_GAMEPAD_SKILLS_NO_ABILITIES))

    self.buildPlannerList:AddDataTemplate("ZO_GamepadSimpleAbilityEntryTemplate", MenuAbilityEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, IsSkillEqual)
    self.buildPlannerList:AddDataTemplateWithHeader("ZO_GamepadSimpleAbilityEntryTemplate", MenuAbilityEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, IsSkillEqual, "ZO_GamepadSimpleAbilityEntryHeaderTemplate", MenuEntryHeaderTemplateSetup)

    local function RefreshSelectedTooltip()
        self:RefreshSelectedTooltip()
    end

    self.buildPlannerList:SetOnSelectedDataChangedCallback(RefreshSelectedTooltip)

    local X_OFFSET = 30
    local Y_OFFSET = 15
    buildPlannerControl:ClearAnchors()
    buildPlannerControl:SetAnchor(TOPLEFT, self.header, BOTTOMLEFT, -X_OFFSET, Y_OFFSET)
    buildPlannerControl:SetAnchor(BOTTOMRIGHT, buildPlannerControl:GetParent(), BOTTOMRIGHT, X_OFFSET, 0)
end

function ZO_GamepadSkills:OnUpdate(currentFrameTimeSeconds)
    if self.nextUpdateTimeSeconds and (currentFrameTimeSeconds >= self.nextUpdateTimeSeconds) then
        self:RefreshCategoryList()
        self:RefreshPointsDisplay()
        local categoryData = self.categoryList:GetTargetData()
        if categoryData and categoryData ~= ACTION_BAR_ID then
            self.dontReselect = false
            self:RefreshLineFilterList()
        end

        self.nextUpdateTimeSeconds = nil
    end

	if self.nextUpdateRefreshVisible then
		if not self.control:IsHidden() then
            if self.mode == BUILD_PLANNER_ASSIGN_MODE then
                self.buildPlannerList:RefreshVisible()
                self.lineFilterList:RefreshVisible()
                self:RefreshSelectedTooltip()
            elseif self.mode == SINGLE_ABILITY_ASSIGN_MODE or self.mode == ABILITY_LIST_BROWSE_MODE then
                self.lineFilterList:RefreshVisible()
            elseif self.mode == SKILL_LIST_BROWSE_MODE then
                self.lineFilterPreviewList:RefreshVisible()
            end
        end
		self.nextUpdateRefreshVisible = false
	end
end

do
    local GAMEPAD_SKILLS_UPDATE_DELAY = .01

    function ZO_GamepadSkills:MarkDirty()
        if(not self.nextUpdateTimeSeconds) then
            self.nextUpdateTimeSeconds = GetFrameTimeSeconds() + GAMEPAD_SKILLS_UPDATE_DELAY
        end
    end
end

function ZO_GamepadSkills:MarkForRefreshVisible()
	self.nextUpdateRefreshVisible = true
end


function ZO_GamepadSkills:InitializeEvents()
    local function FullRefresh()
        self:MarkDirty()
    end

	local function MarkForRefreshVisible()
		self:MarkForRefreshVisible()
	end

    local function OnWeaponPairLockChanged()
        if not self.control:IsHidden() then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.categoryKeybindStripDescriptor)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.lineFilterKeybindStripDescriptor)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.buildPlannerKeybindStripDescriptor)
        end
    end

    self.control:RegisterForEvent(EVENT_SKILLS_FULL_UPDATE, FullRefresh)
    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, FullRefresh)
    self.control:RegisterForEvent(EVENT_SKILL_RANK_UPDATE, FullRefresh)
    self.control:RegisterForEvent(EVENT_SKILL_XP_UPDATE, FullRefresh)
    self.control:RegisterForEvent(EVENT_SKILL_POINTS_CHANGED, FullRefresh)
    self.control:RegisterForEvent(EVENT_ABILITY_PROGRESSION_RANK_UPDATE, FullRefresh)
    self.control:RegisterForEvent(EVENT_SKILL_ABILITY_PROGRESSIONS_UPDATED, FullRefresh)    

    self.control:RegisterForEvent(EVENT_ACTION_SLOT_UPDATED, MarkForRefreshVisible)
    self.control:RegisterForEvent(EVENT_WEAPON_PAIR_LOCK_CHANGED, OnWeaponPairLockChanged)

    local function OnLevelUpdate(eventCode, unitTag, level)
        local weaponSwapLevel = GetWeaponSwapUnlockedLevel()
        if AreUnitsEqual(unitTag, "player") and level >= weaponSwapLevel then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.categoryKeybindStripDescriptor)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.lineFilterKeybindStripDescriptor)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.buildPlannerKeybindStripDescriptor)
            EVENT_MANAGER:UnregisterForEvent("SkillsLevelUpdate", EVENT_LEVEL_UPDATE, OnLevelUpdate)
        end
    end 
    

    local weaponSwapLevel = GetWeaponSwapUnlockedLevel()
    local playerLevel = GetUnitLevel("player")
    if playerLevel < weaponSwapLevel then
        EVENT_MANAGER:RegisterForEvent("SkillsLevelUpdate", EVENT_LEVEL_UPDATE, OnLevelUpdate)  -- in case you unlock weapon swap while in skills menu
    end
end

function ZO_GamepadSkills:TryClearNewStatus()
    if self.clearNewStatusOnSelectionChanged then
        self.clearNewStatusOnSelectionChanged = false
        NEW_SKILL_CALLOUTS:ClearNewStatusOnAbilities(self.clearNewStatusSkillType, self.clearNewStatusSkillLineIndex, self.clearNewStatusAbilityIndex)
        self.lineFilterList:RefreshVisible()
    end
end

function ZO_GamepadSkills:TrySetClearNewFlag(callId)
    if self.clearNewStatusCallId == callId then
        self.clearNewStatusOnSelectionChanged = true
    end
end

function ZO_GamepadSkills:RefreshCategoryList()
    self.categoryList:Clear()

    self.categoryList:AddEntry("ZO_GamepadSkillsDummyMenuEntry", ACTION_BAR_ID)

    for skillType = 1, GetNumSkillTypes() do
        local numSkillLines = GetNumSkillLines(skillType)
        if numSkillLines > 0 then
            for skillLineIndex = 1, numSkillLines do
                local isHeader = skillLineIndex == 1
                local name = GetSkillLineInfo(skillType, skillLineIndex)
                local function IsSkillLineNew()
                    return NEW_SKILL_CALLOUTS:IsSkillLineNew(skillType, skillLineIndex)
                end

                local data = ZO_GamepadEntryData:New(zo_strformat(SI_SKILLS_ENTRY_NAME_FORMAT, name))
                data:SetNew(IsSkillLineNew)
                data.skillType = skillType
                data.skillLineIndex = skillLineIndex   

                if isHeader then
                    data:SetHeader(GetString("SI_SKILLTYPE", skillType))  
                    self.categoryList:AddEntry("ZO_GamepadSkillLineEntryTemplateWithHeader", data)
                else
                    self.categoryList:AddEntry("ZO_GamepadSkillLineEntryTemplate", data)
                end
            end
        end
    end
    self.categoryList:Commit()
end


function ZO_GamepadSkills:RefreshLineFilterList(refreshPreviewList)

    local list = refreshPreviewList and self.lineFilterPreviewList or self.lineFilterList
    list:Clear()

    --Don't show the preview list if action bar slotting isn't allowed
    if refreshPreviewList then
        if not IsActionBarSlottingAllowed() then
            self.lineFilterPreviewWarning:SetHidden(false)
            self.lineFilterPreviewWarning:SetText(GetString(SI_SKILLS_DISABLED_SPECIAL_ABILITIES))
            list:Commit()
            return
        else
            self.lineFilterPreviewWarning:SetHidden(true)
        end
    end

    if not refreshPreviewList then
        list:AddEntry("ZO_GamepadSkillsDummyMenuEntry", ACTION_BAR_ID)
    end

    local selectedData = self.categoryList:GetTargetData()

    local skillType, skillLineIndex = selectedData.skillType, selectedData.skillLineIndex

    local numAbilities = GetNumSkillAbilities(skillType, skillLineIndex)

    local foundFirstActive = false
    local foundFirstPassive = false
    local foundFirstUltimate = false

    for abilityIndex = 1, numAbilities do
        local name, icon, _, passive, ultimate, purchased, progressionIndex = GetSkillAbilityInfo(skillType, skillLineIndex, abilityIndex)
        local currentUpgradeLevel, maxUpgradeLevel = GetSkillAbilityUpgradeInfo(skillType, skillLineIndex, abilityIndex)

        local isActive = (not passive and not ultimate)
        local isUltimate = (not passive and ultimate)

        local isHeader = (isActive and not foundFirstActive) or (passive and not foundFirstPassive) or (isUltimate and not foundFirstUltimate)
        local formattedName = ZO_Skills_GenerateAbilityName(SI_GAMEPAD_ABILITY_NAME_AND_UPGRADE_LEVELS, name, currentUpgradeLevel, maxUpgradeLevel, progressionIndex)

        local data = ZO_GamepadEntryData:New(formattedName, icon, nil, nil, hasAnyNewItems)

        if refreshPreviewList then
            data:SetAlphaChangeOnSelection(false) --only set for preview
            data:SetNameColors(ZO_NORMAL_TEXT, ZO_NORMAL_TEXT)
            data.isPreview = true
        end

        data:SetFontScaleOnSelection(false)
        data.purchased = purchased
        data.skillType = skillType
        data.skillLineIndex = skillLineIndex
        data.abilityIndex = abilityIndex
        data.isActive = isActive
        data.isUltimate = isUltimate

        foundFirstActive = foundFirstActive or isActive
        foundFirstPassive = foundFirstPassive or passive
        foundFirstUltimate = foundFirstUltimate or isUltimate

        if isHeader and not refreshPreviewList then
            local header
            if isActive then
                header = GetString(SI_SKILLS_ACTIVE_ABILITIES)
            elseif passive then
                header = GetString(SI_SKILLS_PASSIVE_ABILITIES)
            elseif isUltimate then
                header = GetString(SI_SKILLS_ULTIMATE_ABILITIES)
            end
            data:SetHeader(header)
            list:AddEntry("ZO_GamepadAbilityEntryTemplateWithHeader", data)
        else
            list:AddEntry("ZO_GamepadAbilityEntryTemplate", data)
        end
    end

    list:Commit(self.dontReselect)
    self.dontReselect = true -- by default we want to always select the second thing in the list, but on visible rebuilds we don't

    if refreshPreviewList then
        list:SetSelectedIndexWithoutAnimation(zo_floor(#list.dataList / 2) + 1)
    end
end

function ZO_GamepadSkills:RefreshBuildPlannerList()
    self.buildPlannerList:Clear()

    local abilityList = {}

    for skillType = 1, GetNumSkillTypes() do
        for skillLineIndex = 1, GetNumSkillLines(skillType) do
            local newSkillLine = true
            for abilityIndex = 1, GetNumSkillAbilities(skillType, skillLineIndex) do
                local name, icon, _, passive, ultimate, purchased, progressionIndex = GetSkillAbilityInfo(skillType, skillLineIndex, abilityIndex)
                local currentUpgradeLevel, maxUpgradeLevel = GetSkillAbilityUpgradeInfo(skillType, skillLineIndex, abilityIndex)
                local formattedName = ZO_Skills_GenerateAbilityName(SI_GAMEPAD_ABILITY_NAME_AND_UPGRADE_LEVELS, name, currentUpgradeLevel, maxUpgradeLevel, progressionIndex)

                if purchased and not passive then
                    if self.assignableActionBar:IsUltimateSelected() == ultimate then
                        local data = ZO_GamepadEntryData:New(formattedName, icon, nil, nil, hasAnyNewItems)
                        data:SetFontScaleOnSelection(false)
                        data.skillType = skillType
                        data.skillLineIndex = skillLineIndex
                        data.abilityIndex = abilityIndex
                        data.isActive = not passive
                        data.passive = passive
                        data.isUltimate = not passive and ultimate
                        data.purchased = purchased                    

                        if newSkillLine then
                            local header, lineRank = GetSkillLineInfo(data.skillType, data.skillLineIndex)
                            data:SetHeader(zo_strformat(SI_SKILLS_ENTRY_LINE_NAME_FORMAT, header))
                            data.lineRank = lineRank
                            self.buildPlannerList:AddEntry("ZO_GamepadSimpleAbilityEntryTemplateWithHeader", data)
                        else
                            self.buildPlannerList:AddEntry("ZO_GamepadSimpleAbilityEntryTemplate", data)
                        end

                        newSkillLine = false
                    end
                end
            end
        end
    end

    self.buildPlannerList:Commit()
end

function ZO_GamepadSkills:RefreshPointsDisplay()
    local availablePoints = GetAvailableSkillPoints()
    local skyShards = GetNumSkyShards()

    self.headerData.data1Text = availablePoints
    self.headerData.data2Text = zo_strformat(SI_GAMEPAD_SKILLS_SKY_SHARDS_FOUND, skyShards, NUM_PARTIAL_SKILL_POINTS_FOR_FULL)

    ZO_GamepadGenericHeader_RefreshData(self.header, self.headerData)
end

do
    local skillPointData =
    {
        data1 =
        {
            value = 0,
            header = GetString(SI_GAMEPAD_SKILLS_AVAILABLE_POINTS),
        },
    }
    local function SetupFunction(control)
        local availablePoints = GetAvailableSkillPoints()
   
        skillPointData.data1.value = availablePoints
        control.setupFunc(control, skillPointData)
    end

    function ZO_GamepadSkills:InitializePurchaseAndUpgradeDialog()

        ZO_Dialogs_RegisterCustomDialog("GAMEPAD_SKILLS_PURCHASE_CONFIRMATION",
        {
            setup = SetupFunction,
            gamepadInfo =
            {
                dialogType = GAMEPAD_DIALOGS.BASIC,
                allowRightStickPassThrough = true,
            },
            title = 
            {
                text = GetString(SI_GAMEPAD_SKILLS_PURCHASE_TITLE),
            },
            mainText = 
            {
                text = GetString(SI_GAMEPAD_SKILLS_PURCHASE_CONFIRM),
            },
            buttons =
            {
                [1] =
                {
                    text =      SI_GAMEPAD_SKILLS_PURCHASE,
                    callback =  function(dialog)
                                    ZO_Skills_PurchaseAbility(dialog.data.skillType, dialog.data.skillLineIndex, dialog.data.abilityIndex)
                                end,
                },
                [2] =
                {
                    text =      SI_DIALOG_CANCEL,
                },
            },
        })

        ZO_Dialogs_RegisterCustomDialog("GAMEPAD_SKILLS_UPGRADE_CONFIRMATION",
        {
            setup = SetupFunction,
            gamepadInfo =
            {
                dialogType = GAMEPAD_DIALOGS.BASIC,
                allowRightStickPassThrough = true,
            },
            title = 
            {
                text = GetString(SI_GAMEPAD_SKILLS_PURCHASE_TITLE),
            },
            mainText = 
            {
                text = GetString(SI_GAMEPAD_SKILLS_UPGRADE_CONFIRM),
            },
            buttons =
            {
                [1] =
                {
                    text =      SI_GAMEPAD_SKILLS_PURCHASE,
                    callback =  function(dialog)
                                    ZO_Skills_UpgradeAbility(dialog.data.skillType, dialog.data.skillLineIndex, dialog.data.abilityIndex)
                                end,
                },
                [2] =
                {
                    text =      SI_DIALOG_CANCEL,
                },
            },
        })
    end

    local parametricDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)

    local function MorphConfirmSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        local RANK = 1
        local name, icon = GetAbilityProgressionAbilityInfo(parametricDialog.data.progressionIndex, data.choiceIndex, RANK)
        data.text = zo_strformat(SI_ABILITY_NAME, name)
        if data:GetNumIcons() == 0 then
            data:AddIcon(icon)
        end
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    end

    local function MorphConfirmCallback(dialog)
        local data = dialog.entryList:GetTargetData()
        ZO_Skills_MorphAbility(dialog.data.progressionIndex, data.choiceIndex)
    end

    function ZO_GamepadSkills:InitializeMorphDialog()
        
        ZO_Dialogs_RegisterCustomDialog("GAMEPAD_SKILLS_MORPH_CONFIRMATION",
        {
            gamepadInfo =
            {
                dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
                allowRightStickPassThrough = true,
            },

            setup = function(dialog)
                local availablePoints = GetAvailableSkillPoints()

                skillPointData.data1.value = availablePoints
                ZO_GenericGamepadDialog_ShowTooltip(dialog)
                dialog:setupFunc(nil, skillPointData)
            end,

            title =
            {
                text = GetString(SI_GAMEPAD_SKILLS_MORPH_TITLE),
            },
            mainText =
            {
                text = GetString(SI_GAMEPAD_SKILLS_MORPH_CONFIRM),
            },

            parametricList =
            {
                -- Morph 1
                {
                    template = "ZO_GamepadSimpleAbilityEntryTemplate",
                    templateData =
                    {
                        setup = MorphConfirmSetup,
                        choiceIndex = 1,
                    },
                },
                -- Morph 2
                {
                    template = "ZO_GamepadSimpleAbilityEntryTemplate",
                    templateData =
                    {
                        setup = MorphConfirmSetup,
                        choiceIndex = 2,
                    },
                },
            },

            parametricListOnSelectionChangedCallback = function(list)
                                                            local targetData = list:GetTargetData()
                                                            GAMEPAD_TOOLTIPS:LayoutAbilityMorph(GAMEPAD_LEFT_DIALOG_TOOLTIP, parametricDialog.data.progressionIndex, targetData.choiceIndex)
                                                       end,
            buttons =
            {
                {
                    keybind = "DIALOG_PRIMARY",
                    text = SI_GAMEPAD_SKILLS_MORPH,
                    callback =  MorphConfirmCallback,
                },
                {
                    keybind = "DIALOG_NEGATIVE",
                    text = SI_DIALOG_CANCEL,
                    callback =  function(dialog)
                                    self:RefreshSelectedTooltip()
                                end,
                },
            },
        })
    end
end

do

    local parametricDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)

    function ZO_GamepadSkills:UpdatePendingStatBonuses(derivedStat, pendingBonus)
        local data = parametricDialog.entryList:GetTargetData()
        local attributeType = data.attributeType
        if not pendingBonus then
            local perPointBonus = GetAttributeDerivedStatPerPointValue(attributeType, STAT_TYPES[attributeType])
            pendingBonus = self.pendingAttributePoints[attributeType] * perPointBonus
        end
        GAMEPAD_TOOLTIPS:LayoutAttributeInfo(GAMEPAD_LEFT_DIALOG_TOOLTIP, attributeType, pendingBonus)
    end

    function ZO_GamepadSkills:SetAddedPoints(attributeType, addedPoints)
        self.pendingAttributePoints[attributeType] = addedPoints
    end

    function ZO_GamepadSkills:GetAddedPoints(attributeType)
        return self.pendingAttributePoints[attributeType]
    end

    function ZO_GamepadSkills:SetAvailablePoints(points)
        parametricDialog.headerData.data1Text = points
        ZO_GamepadGenericHeader_Refresh(parametricDialog.header, parametricDialog.headerData)
    end

    function ZO_GamepadSkills:GetAvailablePoints()
        local numPending = 0
        for i = 1, GetNumAttributes() do
            numPending = numPending + self.pendingAttributePoints[i]
        end
        return GetAttributeUnspentPoints() - numPending
    end

    function ZO_GamepadSkills:SpendAvailablePoints(points)
        self:SetAvailablePoints(self:GetAvailablePoints() - points)
    end

    function ZO_GamepadSkills:ResetAttributeData()
        self.pendingAttributePoints = {}
        for i = 1, GetNumAttributes() do
            self.pendingAttributePoints[i] = 0
        end
    end

    local attributePointData =
    {
        data1 =
        {
            value = 0,
            header = GetString(SI_STATS_GAMEPAD_AVAILABLE_POINTS),
        },
    }

    local function DisableSpinner(dialog)
        local selectedControl = dialog.entryList:GetSelectedControl()
        if selectedControl and selectedControl.pointLimitedSpinner then
            selectedControl.pointLimitedSpinner:SetActive(false)
        end
    end

    function ZO_GamepadSkills:InitializeAttributeDialog()
        self:ResetAttributeData()
        
        ZO_Dialogs_RegisterCustomDialog("GAMEPAD_SKILLS_ATTRIBUTE_PURCHASE",
        {
            canQueue = true,
            gamepadInfo = 
            {
                dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            },

            setup = function(dialog)
                attributePointData.data1.value = self:GetAvailablePoints()
                ZO_GenericGamepadDialog_ShowTooltip(dialog)
                dialog:setupFunc(nil, attributePointData)
            end,
            title =
            {
                text = GetString(SI_STATS_ATTRIBUTES_LEVEL_UP),
            },

            blockDirectionalInput = true,
            parametricList =
            {
                -- magicka
                {
                    template = "ZO_GamepadStatAttributeRow",
                    templateData = 
                    {
                        setup = ZO_GamepadStatAttributeRow_Setup,
                        attributeType = ATTRIBUTE_MAGICKA,
                        screen = self,
                    },
                    text = GetString("SI_ATTRIBUTES", ATTRIBUTE_MAGICKA),
                    icon = "/esoui/art/characterwindow/Gamepad/gp_characterSheet_magickaIcon.dds",
                },
                -- health
                {
                    template = "ZO_GamepadStatAttributeRow",
                    templateData = 
                    {
                        setup = ZO_GamepadStatAttributeRow_Setup,
                        attributeType = ATTRIBUTE_HEALTH,
                        screen = self,
                    },
                    text = GetString("SI_ATTRIBUTES", ATTRIBUTE_HEALTH),
                    icon = "/esoui/art/characterwindow/Gamepad/gp_characterSheet_healthIcon.dds",
                },
                -- stamina
                {
                    template = "ZO_GamepadStatAttributeRow",
                    templateData = 
                    {
                        setup = ZO_GamepadStatAttributeRow_Setup,
                        attributeType = ATTRIBUTE_STAMINA,
                        screen = self,
                    },
                    text = GetString("SI_ATTRIBUTES", ATTRIBUTE_STAMINA),
                    icon = "/esoui/art/characterwindow/Gamepad/gp_characterSheet_staminaIcon.dds",
                },
            },

            parametricListOnSelectionChangedCallback = function() self:UpdatePendingStatBonuses() end,

            buttons =
            {
                {
                    keybind = "DIALOG_PRIMARY",
                    text = SI_GAMEPAD_LEVELUP_DIALOG_CONFIRM,
                    callback = function(dialog)
                        local pendingHealth = self.pendingAttributePoints[ATTRIBUTE_HEALTH]
                        local pendingMagicka = self.pendingAttributePoints[ATTRIBUTE_MAGICKA]
                        local pendingStamina = self.pendingAttributePoints[ATTRIBUTE_STAMINA]
                        if pendingHealth + pendingMagicka + pendingStamina > 0 then
                            PurchaseAttributes(pendingHealth, pendingMagicka, pendingStamina)
                            PlaySound(SOUNDS.GAMEPAD_STATS_SINGLE_PURCHASE)
                        end
                        DisableSpinner(dialog)
                    end,
                },
                {
                    keybind = "DIALOG_NEGATIVE",
                    text = SI_GAMEPAD_BACK_OPTION,
                    callback = function(dialog)
                        DisableSpinner(dialog)
                        self:Back()
                    end,
                },
            },

            finishedCallback = function(dialog)
                                --Setup Skills Scene
                                DisableSpinner(dialog)
                                ZO_GenericGamepadDialog_HideTooltip(dialog)
                                self.showAttributeDialog = false
                                self:RefreshSelectedTooltip()
                                self:ResetAttributeData()                                
                            end,
        })
    end
end

local TIME_NEW_PERSISTS_WHILE_SELECTED = 1000
function ZO_GamepadSkills:OnSelectedAbilityChanged(selectedData)
    self:RefreshSelectedTooltip()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.lineFilterKeybindStripDescriptor)

    self:TryClearNewStatus()

    if selectedData and selectedData ~= ACTION_BAR_ID and NEW_SKILL_CALLOUTS:IsAbilityNew(selectedData.skillType, selectedData.skillLineIndex, selectedData.abilityIndex) then
        self.clearNewStatusSkillType = selectedData.skillType
        self.clearNewStatusSkillLineIndex = selectedData.skillLineIndex
        self.clearNewStatusAbilityIndex = selectedData.abilityIndex
        self.clearNewStatusCallId = zo_callLater(self.trySetClearNewFlagCallback, TIME_NEW_PERSISTS_WHILE_SELECTED)
    else
        self.clearNewStatusCallId = nil
    end
end

function ZO_GamepadSkills:SetupTooltipStatusLabel(tooltip, slotId)
    local valueText
    if slotId == ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 then    
        valueText = zo_strformat(SI_GAMEPAD_SKILLS_TOOLTIP_STATUS_NUMBER, GetString(SI_BINDING_NAME_GAMEPAD_ACTION_BUTTON_8))
    else
        valueText = zo_strformat(SI_GAMEPAD_SKILLS_TOOLTIP_STATUS_NUMBER, slotId - ACTION_BAR_FIRST_NORMAL_SLOT_INDEX)
    end
    GAMEPAD_TOOLTIPS:SetStatusLabelText(tooltip, GetString(SI_GAMEPAD_SKILLS_TOOLTIP_STATUS), valueText)
end

function ZO_GamepadSkills:RefreshSelectedTooltip()
    --don't setup tooltip til dialog is gone.
    if self.showAttributeDialog then return end
    GAMEPAD_TOOLTIPS:ClearStatusLabel(GAMEPAD_LEFT_TOOLTIP) --clear statusLabel on start

    if self.mode == SKILL_LIST_BROWSE_MODE then
        local selectedData = self.categoryList:GetTargetData()
        if selectedData and selectedData == ACTION_BAR_ID then
            SCENE_MANAGER:RemoveFragment(GAMEPAD_SKILLS_LINE_PREVIEW_FRAGMENT)
            SCENE_MANAGER:RemoveFragment(GAMEPAD_LEFT_TOOLTIP_BACKGROUND_FRAGMENT)
            local slotId = self.assignableActionBar:GetSelectedSlotId()
            if slotId then
                self:SetupTooltipStatusLabel(GAMEPAD_LEFT_TOOLTIP, slotId)
                GAMEPAD_TOOLTIPS:LayoutActionBarAbility(GAMEPAD_LEFT_TOOLTIP, slotId)
            end       
        else
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
            self:RefreshLineFilterList(true) --refresh previewList version
            SCENE_MANAGER:AddFragment(GAMEPAD_SKILLS_LINE_PREVIEW_FRAGMENT)
            SCENE_MANAGER:AddFragment(GAMEPAD_LEFT_TOOLTIP_BACKGROUND_FRAGMENT)
        end
    elseif self.mode == BUILD_PLANNER_ASSIGN_MODE then
        local selectedData = self.buildPlannerList:GetTargetData()
        if selectedData then
            GAMEPAD_TOOLTIPS:LayoutSkillLineAbility(GAMEPAD_LEFT_TOOLTIP, selectedData.skillType, selectedData.skillLineIndex, selectedData.abilityIndex, false)
            local abilityId = GetSkillAbilityId(selectedData.skillType, selectedData.skillLineIndex, selectedData.abilityIndex, false)
            for i = ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1, ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 do
                if abilityId == GetSlotBoundId(i) then
                    self:SetupTooltipStatusLabel(GAMEPAD_LEFT_TOOLTIP, i)
                    break
                end
            end 
        else
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        end

        local slotId = self.assignableActionBar:GetSelectedSlotId()
        if slotId then
            self:SetupTooltipStatusLabel(GAMEPAD_RIGHT_TOOLTIP, slotId)
            GAMEPAD_TOOLTIPS:LayoutActionBarAbility(GAMEPAD_RIGHT_TOOLTIP, slotId)
        else
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
        end
    else
        local selectedData = self.lineFilterList:GetTargetData()
        if selectedData and selectedData ~= ACTION_BAR_ID then
            local showNextUpgrade = GetAbilityAction(selectedData.skillType, selectedData.skillLineIndex, selectedData.abilityIndex) == ACTION_UPGRADE           
            local SHOW_PURCHASE_INFO = true
            GAMEPAD_TOOLTIPS:LayoutSkillLineAbility(GAMEPAD_LEFT_TOOLTIP, selectedData.skillType, selectedData.skillLineIndex, selectedData.abilityIndex, showNextUpgrade, nil, nil, SHOW_PURCHASE_INFO)
            if self.mode == SINGLE_ABILITY_ASSIGN_MODE then
                local slotId = self.assignableActionBar:GetSelectedSlotId()
                if slotId then
                    self:SetupTooltipStatusLabel(GAMEPAD_RIGHT_TOOLTIP, slotId)
                    GAMEPAD_TOOLTIPS:LayoutActionBarAbility(GAMEPAD_RIGHT_TOOLTIP, slotId)
                end 
            end 
        elseif selectedData == ACTION_BAR_ID then
            local slotId = self.assignableActionBar:GetSelectedSlotId()
            if slotId then
                self:SetupTooltipStatusLabel(GAMEPAD_LEFT_TOOLTIP, slotId)
                GAMEPAD_TOOLTIPS:LayoutActionBarAbility(GAMEPAD_LEFT_TOOLTIP, slotId)
            end       
        end
    end
end

function ZO_GamepadSkills:SetMode(mode)
    self.mode = mode
    self.assignableActionBar:SetLockMode(ASSIGNABLE_ACTION_BAR_LOCK_MODE_NONE)
    if self.mode == SKILL_LIST_BROWSE_MODE then
        if self:IsCurrentList(self.categoryList) then
            self.categoryList:Activate()
        else
            self:SetCurrentList(self.categoryList)
        end
    elseif self.mode == BUILD_PLANNER_ASSIGN_MODE then
        self.buildPlannerList:Activate()
        self:RefreshBuildPlannerList()  
    elseif self.mode == ABILITY_LIST_BROWSE_MODE then
        if self:IsCurrentList(self.lineFilterList) then
            self.lineFilterList:Activate()
        else
            self:SetCurrentList(self.lineFilterList)
        end
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.lineFilterKeybindStripDescriptor)
    elseif self.mode == SINGLE_ABILITY_ASSIGN_MODE then
        self.assignableActionBar:SetSelectedButtonBySlotId(self.assignableActionBarSelectedId)
        self.assignableActionBar:Activate()
        self:DisableCurrentList()
        local _, _, _, _, ultimate = GetSkillAbilityInfo(self.singleAbilitySkillType, self.singleAbilitySkillLineIndex, self.singleAbilityAbilityIndex)
        self.assignableActionBar:SetLockMode(ultimate and ASSIGNABLE_ACTION_BAR_LOCK_MODE_ULTIMATE or ASSIGNABLE_ACTION_BAR_LOCK_MODE_ACTIVE)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.lineFilterKeybindStripDescriptor)
    end
end

function ZO_GamepadSkills:AssignSelectedBuildPlannerAbility()
    local selectedData = self.buildPlannerList:GetTargetData()
    if selectedData then
        if ZO_Skills_AbilityFailsWerewolfRequirement(selectedData.skillType, selectedData.skillLineIndex) then
            ZO_Skills_OnlyWerewolfAbilitiesAllowedAlert()
        else
            self.assignableActionBar:SetAbility(selectedData.skillType, selectedData.skillLineIndex, selectedData.abilityIndex)
        end
    end
end

function ZO_GamepadSkills:StartSingleAbilityAssignment(skillType, skillLineIndex, abilityIndex)
    if not self.assignableActionBar:GetSelectedSlotId() then
        local buttonIndex = GetAssignedSlotFromSkillAbility(skillType, skillLineIndex, abilityIndex)

        if buttonIndex then
            -- Normalize the assigned slot to match the button index for the skill
            buttonIndex = buttonIndex - ACTION_BAR_FIRST_NORMAL_SLOT_INDEX
        end

        self.assignableActionBar:SetSelectedButton(buttonIndex or 1)
    end
    self.singleAbilitySkillType = skillType
    self.singleAbilitySkillLineIndex = skillLineIndex
    self.singleAbilityAbilityIndex = abilityIndex
    self.actionBarAnimation:PlayForward()
    self:SetMode(SINGLE_ABILITY_ASSIGN_MODE)
    self:RefreshSelectedTooltip()
end

function ZO_GamepadSkills:Back()
    if self.mode == SINGLE_ABILITY_ASSIGN_MODE then
        self.actionBarAnimation:PlayBackward()
        self.assignableActionBar:SetSelectedButton(nil)
        self.assignableActionBar:Deactivate()
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
        self:SetMode(ABILITY_LIST_BROWSE_MODE)
        PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
    elseif self.mode == BUILD_PLANNER_ASSIGN_MODE then
        SCENE_MANAGER:RemoveFragment(GAMEPAD_SKILLS_BUILD_PLANNER_FRAGMENT)
        PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    else
        SCENE_MANAGER:HideCurrentScene()
    end
end

function ZO_GamepadSkills_OnInitialize(control)
    GAMEPAD_SKILLS = ZO_GamepadSkills:New(control)
end

--[[ Skill Templates ]]--

function ZO_GamepadSkillLineXpBar_Setup(skillType, skillLineIndex, xpBar, nameControl, forceInit)
    local name, lineRank = GetSkillLineInfo(skillType, skillLineIndex)
    local lastXP, nextXP, currentXP = GetSkillLineXPInfo(skillType, skillLineIndex)    
    ZO_SkillInfoXPBar_SetValue(xpBar, lineRank, lastXP, nextXP, currentXP, forceInit)
    if nameControl then
        nameControl:SetText(zo_strformat(SI_SKILLS_ENTRY_LINE_NAME_FORMAT, name))
    end
end

function ZO_GamepadSkillLineEntryTemplate_Setup(control, skillType, skillLineIndex, selected, activated)
    local isTheSame = control.barContainer.xpBar.skillType == skillType and control.barContainer.xpBar.skillLineIndex == skillLineIndex
    if not isTheSame then
        control.barContainer.xpBar.skillType = skillType
        control.barContainer.xpBar.skillLineIndex = skillLineIndex

        control.barContainer.xpBar:Reset()
    end

    ZO_GamepadSkillLineXpBar_Setup(skillType, skillLineIndex, control.barContainer.xpBar, nil, not isTheSame)

    control.barContainer:SetHidden(not selected)
end

function ZO_GamepadSkillLineEntryTemplate_OnLevelChanged(xpBar, rank)
    xpBar:GetControl():GetParent().rank:SetText(rank)
end

local function SetupAbilityXpBar(control, skillType, skillLineIndex, abilityIndex, selected)
    if control.barContainer then
        local progressionIndex = select(7, GetSkillAbilityInfo(skillType, skillLineIndex, abilityIndex))
        if selected and progressionIndex then
            local xpBar = control.barContainer.xpBar
            local isTheSame = xpBar.skillType == skillType and xpBar.skillLineIndex == skillLineIndex and xpBar.abilityIndex == abilityIndex
            if not isTheSame then
                xpBar.skillType = skillType
                xpBar.skillLineIndex = skillLineIndex
                xpBar.abilityIndex = abilityIndex

                xpBar:Reset()
            end

            control.barContainer:SetHidden(false)

            local lastXP, nextXP, currentXP, atMorph = GetAbilityProgressionXPInfo(progressionIndex)
            local _, _, rank = GetAbilityProgressionInfo(progressionIndex)
            ZO_SkillInfoXPBar_SetValue(xpBar, rank, lastXP, nextXP, currentXP, not isTheSame)
        else
            control.barContainer:SetHidden(true)
        end
    end
end        

function ZO_GamepadAbilityEntryTemplate_Setup(control, abilityData, selected, activated)
    local skillType, skillLineIndex, abilityIndex = abilityData.skillType, abilityData.skillLineIndex, abilityData.abilityIndex
        
    local availablePoints = GetAvailableSkillPoints()

    local _, lineRank = GetSkillLineInfo(skillType, skillLineIndex)
    local name, _, earnedRank, passive, ultimate, purchased, progressionIndex = GetSkillAbilityInfo(skillType, skillLineIndex, abilityIndex)
    local _, _, nextUpgradeEarnedRank = GetSkillAbilityNextUpgradeInfo(skillType, skillLineIndex, abilityIndex)

    local atMorph = progressionIndex and select(4, GetAbilityProgressionXPInfo(progressionIndex))

    local isNew = NEW_SKILL_CALLOUTS:IsAbilityNew(skillType, skillLineIndex, abilityIndex)

    if control.alert then
        control.alert:ClearIcons()
    end

    if control.circleFrame then
        control.circleFrame:SetHidden(not passive)
    end
    control.edgeFrame:SetHidden(passive)

    local hasAlertAndLockStates = control.alert and control.lock

    if purchased then
        ZO_ActionSlot_SetUnusable(control.icon, false)

        if not abilityData.isPreview then
            control.label:SetColor((selected and PURCHASED_COLOR or PURCHASED_UNSELECTED_COLOR):UnpackRGBA())
        end
        
        if hasAlertAndLockStates then
            local upgradeAvailable = nextUpgradeEarnedRank and lineRank >= nextUpgradeEarnedRank
            if atMorph and availablePoints > 0 then
                control.lock:SetHidden(true)
                ZO_Skills_SetAlertButtonTextures(control.alert, GAMEPAD_ALERT_TEXTURES[ZO_SKILLS_MORPH_STATE])
            elseif upgradeAvailable and availablePoints > 0 then
                control.lock:SetHidden(true)
                ZO_Skills_SetAlertButtonTextures(control.alert, GAMEPAD_ALERT_TEXTURES[ZO_SKILLS_PURCHASE_STATE])
            else
                control.lock:SetHidden(true)
            end
        end
    else
        ZO_ActionSlot_SetUnusable(control.icon, true)

        if lineRank >= earnedRank then
            if hasAlertAndLockStates then
                control.lock:SetHidden(true)
                if availablePoints > 0 then
                    ZO_Skills_SetAlertButtonTextures(control.alert, GAMEPAD_ALERT_TEXTURES[ZO_SKILLS_PURCHASE_STATE])
                end
            end
        else
            if hasAlertAndLockStates then
                control.lock:SetHidden(false)
            end
        end
    end

    if control.keybind then
        local labelWidth = 290  --width of label without keybind
        local slot = GetAssignedSlotFromSkillAbility(skillType, skillLineIndex, abilityIndex)
        control.keybind:SetHidden(slot == nil)
        if slot then
            local bindingText = ZO_Keybindings_GetHighestPriorityBindingStringFromAction("GAMEPAD_ACTION_BUTTON_".. slot, KEYBIND_TEXT_OPTIONS_FULL_NAME, KEYBIND_TEXTURE_OPTIONS_EMBED_MARKUP, true)
                    
            local layerIndex, categoryIndex, actionIndex = GetActionIndicesFromName("GAMEPAD_ACTION_BUTTON_".. slot)
            if layerIndex then
                local key = GetActionBindingInfo(layerIndex, categoryIndex, actionIndex, 1)
                if IsKeyCodeChordKey(key) then 
                    labelWidth = labelWidth - 80   --width minus double keybind width (RB+LB)
                else
                    labelWidth = labelWidth - 40   --width minus single keybind
                end
            end
            control.keybind:SetText(bindingText)
        else
            control.keybind:SetText("") --resizes rect for when control is reused and hidden since other controls depend on it's width
        end  
        control.label:SetWidth(labelWidth)
    end

    SetupAbilityXpBar(control, skillType, skillLineIndex, abilityIndex, selected)

    if control.alert then
        if isNew then
            control.alert:AddIcon("EsoUI/Art/Inventory/newItem_icon.dds")
        end
        control.alert:Show()
    end
end