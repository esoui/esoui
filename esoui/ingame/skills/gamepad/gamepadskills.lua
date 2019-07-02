ZO_GamepadSkills = ZO_Gamepad_ParametricList_Screen:Subclass()


ZO_GAMEPAD_SKILLS_SKILL_LIST_BROWSE_MODE = 1
ZO_GAMEPAD_SKILLS_BUILD_PLANNER_ASSIGN_MODE = 2
ZO_GAMEPAD_SKILLS_ABILITY_LIST_BROWSE_MODE = 3
ZO_GAMEPAD_SKILLS_SINGLE_ABILITY_ASSIGN_MODE = 4

function ZO_GamepadSkills:New(...)
    local gamepadSkills = ZO_Gamepad_ParametricList_Screen.New(self, ...)
    return gamepadSkills
end

function ZO_GamepadSkills:Initialize(control)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)

    self.trySetClearUpdatedAbilityFlagCallback = function(callId)
        self:TrySetClearUpdatedAbilityFlag(callId)
    end

    self.trySetClearNewSkillLineFlagCallback = function(callId)
        self:TrySetClearNewSkillLineFlag(callId)
    end

    -- Used to select a desired skill ability after a lineFilterList refresh
    self.selectSkillData = nil

    self.skillLineXPBarFragment = ZO_FadeSceneFragment:New(ZO_GamepadSkillsTopLevelSkillInfo)

    GAMEPAD_SKILLS_ROOT_SCENE = ZO_InteractScene:New("gamepad_skills_root", SCENE_MANAGER, ZO_SKILL_RESPEC_INTERACT_INFO)
    GAMEPAD_SKILLS_ROOT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        ZO_Gamepad_ParametricList_Screen.OnStateChanged(self, oldState, newState)
        if newState == SCENE_SHOWING then
            self:SetMode(ZO_GAMEPAD_SKILLS_SKILL_LIST_BROWSE_MODE)
            self:RefreshHeader(GetString(SI_MAIN_MENU_SKILLS))
            self.categoryListRefreshGroup:TryClean()
            self.assignableActionBar:Refresh()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.categoryKeybindStripDescriptor)

            if self.returnToAdvisor then
                local previousSceneName = SCENE_MANAGER:GetPreviousSceneName()
                if previousSceneName == "gamepad_skills_line_filter" then
                    -- first entry is always the skills advisor
                    self.categoryList:SetSelectedIndexWithoutAnimation(1)
                    self:DeactivateCurrentList()
                    ZO_GAMEPAD_SKILLS_ADVISOR_SUGGESTIONS_WINDOW:Activate()
                end
                self.returnToAdvisor = false
            end

            TriggerTutorial(TUTORIAL_TRIGGER_COMBAT_SKILLS_OPENED)
            
            local level = GetUnitLevel("player")
            if level >= GetSkillBuildTutorialLevel() then
                TriggerTutorial(TUTORIAL_TRIGGER_SKILL_BUILD_SELECTION)
            end
            
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
            if self.mode == ZO_GAMEPAD_SKILLS_SKILL_LIST_BROWSE_MODE then
                if self.assignableActionBar:IsActive() then
                    self:ActivateAssignableActionBarFromList()
                end
            end
        elseif newState == SCENE_HIDING then
            --Disable now so it's not possible to change the selected skill live/skills advisor entry as the scene is hiding since the line filter list depends on it being a skill line
            self:DisableCurrentList()
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.categoryKeybindStripDescriptor)
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_RIGHT_TOOLTIP)
        end
    end)

    GAMEPAD_SKILLS_LINE_FILTER_SCENE = ZO_InteractScene:New("gamepad_skills_line_filter", SCENE_MANAGER, ZO_SKILL_RESPEC_INTERACT_INFO)
    GAMEPAD_SKILLS_LINE_FILTER_SCENE:AddFragment(self.skillLineXPBarFragment)
    GAMEPAD_SKILLS_LINE_FILTER_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        ZO_Gamepad_ParametricList_Screen.OnStateChanged(self, oldState, newState)
        if newState == SCENE_SHOWING then
            local targetSkillLineData = self.categoryList:GetTargetData().skillLineData
            self:SetMode(ZO_GAMEPAD_SKILLS_ABILITY_LIST_BROWSE_MODE)
            self:RefreshHeader(targetSkillLineData:GetFormattedName())
            self.assignableActionBar:Refresh()
            --To pick up the new skill line that was just selected
            self.lineFilterListRefreshGroup:MarkDirty("List")
            self.lineFilterListRefreshGroup:TryClean()
            
            -- If there was a skill data to select, find it and select it now that the skill list is showing
            local setSelectedIndex = false
            if self.selectSkillData then
                for i = 1, self.lineFilterList:GetNumEntries() do
                    local data = self.lineFilterList:GetDataForDataIndex(i)
                    if data.skillData == self.selectSkillData then
                        self.lineFilterList:SetSelectedIndexWithoutAnimation(i)
                        setSelectedIndex = true
                        break
                    end
                end
                self.selectSkillData = nil
            end
            if not setSelectedIndex then
                self.lineFilterList:SetSelectedIndexWithoutAnimation(1)
            end

            ACTION_BAR_ASSIGNMENT_MANAGER:UpdateWerewolfBarStateInCycle(targetSkillLineData)
            
            KEYBIND_STRIP:AddKeybindButtonGroup(self.lineFilterKeybindStripDescriptor)
        elseif newState == SCENE_HIDDEN then
            local NO_SKILL_LINE_SELECTED = nil
            ACTION_BAR_ASSIGNMENT_MANAGER:UpdateWerewolfBarStateInCycle(NO_SKILL_LINE_SELECTED)
            self:DisableCurrentList()
            self:TryClearSkillUpdatedStatus()
            self:TryClearSkillLineNewStatus()
            self.clearSkillUpdatedStatusCallId = nil
            self.clearSkillUpdatedStatusSkillData = nil
            self.clearSkillLineNewStatusCallId = nil
            self.clearSkillLineNewStatusSkillLineData = nil
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.lineFilterKeybindStripDescriptor)
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_RIGHT_TOOLTIP)
             if self.mode == ZO_GAMEPAD_SKILLS_SINGLE_ABILITY_ASSIGN_MODE then
                self.actionBarAnimation:PlayInstantlyToStart()
            end
        end
    end)

    local ALWAYS_ANIMATE = true
    GAMEPAD_SKILLS_BUILD_PLANNER_FRAGMENT = ZO_FadeSceneFragment:New(self.control:GetNamedChild("BuildPlannerContainer"), ALWAYS_ANIMATE)
    GAMEPAD_SKILLS_BUILD_PLANNER_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self.modeBeforeBuildPlannerShow = self.mode
            if self.modeBeforeBuildPlannerShow == ZO_GAMEPAD_SKILLS_SKILL_LIST_BROWSE_MODE then
                KEYBIND_STRIP:RemoveKeybindButtonGroup(self.categoryKeybindStripDescriptor)
            elseif self.modeBeforeBuildPlannerShow == ZO_GAMEPAD_SKILLS_ABILITY_LIST_BROWSE_MODE then
                KEYBIND_STRIP:RemoveKeybindButtonGroup(self.lineFilterKeybindStripDescriptor)
            end

            self:SetMode(ZO_GAMEPAD_SKILLS_BUILD_PLANNER_ASSIGN_MODE)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.buildPlannerKeybindStripDescriptor)
            self.buildPlannerListRefreshGroup:TryClean()
        elseif newState == SCENE_FRAGMENT_HIDING then
            self.assignableActionBar:ClearTargetSkill()

        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self.buildPlannerList:Deactivate()

            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.buildPlannerKeybindStripDescriptor)
         
            if self.modeBeforeBuildPlannerShow == ZO_GAMEPAD_SKILLS_SKILL_LIST_BROWSE_MODE then
                KEYBIND_STRIP:AddKeybindButtonGroup(self.categoryKeybindStripDescriptor)
            elseif self.modeBeforeBuildPlannerShow == ZO_GAMEPAD_SKILLS_ABILITY_LIST_BROWSE_MODE then
                KEYBIND_STRIP:AddKeybindButtonGroup(self.lineFilterKeybindStripDescriptor)
            end
            self:SetMode(self.modeBeforeBuildPlannerShow)
            self.modeBeforeBuildPlannerShow = nil
        end
    end)

    GAMEPAD_SKILLS_LINE_PREVIEW_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadSkillsLinePreview)
    GAMEPAD_SKILLS_LINE_PREVIEW_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self.lineFilterPreviewListRefreshGroup:MarkDirty("List")
            self.lineFilterPreviewListRefreshGroup:TryClean()
        end
    end)

    GAMEPAD_SKILLS_SCENE_GROUP = ZO_SceneGroup:New("gamepad_skills_root", "gamepad_skills_line_filter")
    GAMEPAD_SKILLS_SCENE_GROUP:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_GROUP_SHOWING then
            self:PerformDeferredInitialization()
            self.showAttributeDialog = GetAttributeUnspentPoints() > 0 and not SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave()
        elseif newState == SCENE_GROUP_HIDDEN then
            self.assignableActionBar:OnSkillsHidden()
            SKILLS_AND_ACTION_BAR_MANAGER:ResetInterface()
        end
    end)

    GAMEPAD_SKILLS_ROOT_SCENE:SetHideSceneConfirmationCallback(ZO_GamepadSkills.OnConfirmHideScene)
    GAMEPAD_SKILLS_LINE_FILTER_SCENE:SetHideSceneConfirmationCallback(ZO_GamepadSkills.OnConfirmHideScene)

    --Init the weapon swap descriptors here because OnWeaponSwap is private and cannot be initialized on a scene show if an addon does the show
    self.categoryKeybindStripDescriptor = { alignment = KEYBIND_STRIP_ALIGN_LEFT }
    self:AddWeaponSwapDescriptor(self.categoryKeybindStripDescriptor)
    self:AddSkillsAdvisorDescriptor(self.categoryKeybindStripDescriptor)
    self.lineFilterKeybindStripDescriptor = { alignment = KEYBIND_STRIP_ALIGN_LEFT }
    self:AddWeaponSwapDescriptor(self.lineFilterKeybindStripDescriptor)
    self.buildPlannerKeybindStripDescriptor = {}
    self:AddWeaponSwapDescriptor(self.buildPlannerKeybindStripDescriptor)
end

function ZO_GamepadSkills.OnConfirmHideScene(scene, nextSceneName, bypassHideSceneConfirmationReason)
    if bypassHideSceneConfirmationReason == nil and 
        SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() and
        not GAMEPAD_SKILLS_SCENE_GROUP:HasScene(nextSceneName) then
        
        ZO_Dialogs_ShowGamepadDialog("CONFIRM_REVERT_CHANGES",
        {
            confirmCallback = function() scene:AcceptHideScene() end,
            declineCallback = function() scene:RejectHideScene() end,
        })        
    else
        scene:AcceptHideScene()
    end
end

function ZO_GamepadSkills:OnPlayerDeactivated()
    --If we are deactivated we might be jumping somewhere else. We also might be in the respec interaction which will not be valid when we get where we are going. So just clear out the respec here.
    if GAMEPAD_SKILLS_SCENE_GROUP:IsShowing() and SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
        local DEFAULT_PUSH = nil
        local DEFAULT_NEXT_SCENE_CLEARS_SCENE_STACK = nil
        local DEFAULT_NUM_SCENES_NEXT_SCENE_POPS = nil
        SCENE_MANAGER:Show(SCENE_MANAGER:GetBaseScene():GetName(), DEFAULT_PUSH, DEFAULT_NEXT_SCENE_CLEARS_SCENE_STACK, DEFAULT_NUM_SCENES_NEXT_SCENE_POPS, ZO_BHSCR_SKILLS_PLAYER_DEACTIVATED)
    end
end

function ZO_GamepadSkills:PerformUpdate()
    -- Include update functionality here if the screen uses self.dirty to track needing to update
    self.dirty = false
end

function ZO_GamepadSkills:PerformDeferredInitialization()
    if self.fullyInitialized then return end
    self.fullyInitialized = true

    self:InitializeHeader()
    self:InitializeAssignableActionBar()
    self:InitializeCategoryList()
    self:InitializeLineFilterList()
    self:InitializeLineFilterPreviewList()
    self:InitializeMorphDialog()
    self:InitializePurchaseAndUpgradeDialog()
    self:InitializeAttributeDialog()
    self:InitializeRespecConfirmationGoldDialog()
    self:InitializeConfirmClearAllDialog()
    self:InitializeBuildPlanner()
    self:InitializeCategoryKeybindStrip()
    self:InitializeLineFilterKeybindStrip()
    self:InitializeBuildPlannerKeybindStrip()

    self:InitializeRefreshGroups()
    self:InitializeEvents()

    self:RefreshPointsDisplay()
    self:RefreshRespecModeBindingsDisplay()
end

local ACTION_NONE = 1
local ACTION_PURCHASE = 2
local ACTION_SELL = 3
local ACTION_INCREASE_RANK = 4
local ACTION_DECREASE_RANK = 5
local ACTION_MORPH = 6
local ACTION_UNMORPH = 7
local ACTION_REMORPH = 8

local POINT_ACTION_TEXTURES =
{
    [ACTION_PURCHASE] = "EsoUI/Art/Progression/Gamepad/gp_purchase.dds",
    [ACTION_SELL] = "EsoUI/Art/Buttons/Gamepad/gp_minus.dds",
    [ACTION_INCREASE_RANK] = "EsoUI/Art/Progression/Gamepad/gp_purchase.dds",
    [ACTION_DECREASE_RANK] = "EsoUI/Art/Buttons/Gamepad/gp_minus.dds",
    [ACTION_MORPH] = "EsoUI/Art/Progression/Gamepad/gp_morph.dds",
    [ACTION_UNMORPH] = "EsoUI/Art/Buttons/Gamepad/gp_minus.dds",
    [ACTION_REMORPH] = "EsoUI/Art/Progression/Gamepad/gp_remorph.dds",
}

local function GetIncreaseSkillAction(skillData)
    local skillPointAllocator = skillData:GetPointAllocator()
    if skillPointAllocator:CanPurchase() then
        return ACTION_PURCHASE
    elseif skillPointAllocator:CanMorph() then
        local skillProgressionData = skillPointAllocator:GetProgressionData()
        if skillProgressionData:IsMorph() then
            return ACTION_REMORPH
        else
            return ACTION_MORPH
        end
    elseif skillPointAllocator:CanIncreaseRank() then
        return ACTION_INCREASE_RANK
    else
        return ACTION_NONE
    end
end

local function GetDecreaseSkillAction(skillData)
    local skillPointAllocator = skillData:GetPointAllocator()
    if skillPointAllocator:CanSell() then
        return ACTION_SELL
    elseif skillPointAllocator:CanUnmorph() then
        return ACTION_UNMORPH
    elseif skillPointAllocator:CanDecreaseRank() then
        return ACTION_DECREASE_RANK
    else
        return ACTION_NONE
    end
end

function ZO_GamepadSkills:InitializeHeader()
    local selectedSkillBuild = ZO_SKILLS_ADVISOR_SINGLETON:GetAvailableSkillBuildById(ZO_SKILLS_ADVISOR_SINGLETON:GetSelectedSkillBuildId())
    self.headerData =
    {
        titleText = GetString(SI_MAIN_MENU_SKILLS),
        subtitleText = selectedSkillBuild and zo_strformat(SI_SKILLS_ADVISOR_GAMEPAD_SELECTED_BUILD_SUBTITLE, selectedSkillBuild.name) or "",
        data1HeaderText = GetString(SI_GAMEPAD_SKILLS_AVAILABLE_POINTS),       
        data2HeaderText = GetString(SI_GAMEPAD_SKILLS_SKY_SHARDS),               
    }
    ZO_GamepadGenericHeader_SetDataLayout(self.header, ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_TOGETHER)
end

function ZO_GamepadSkills:RefreshHeader(headerTitle)
    self.headerData.titleText = headerTitle

    local selectedSkillBuild = ZO_SKILLS_ADVISOR_SINGLETON:GetAvailableSkillBuildById(ZO_SKILLS_ADVISOR_SINGLETON:GetSelectedSkillBuildId())
    self.headerData.subtitleText = selectedSkillBuild and zo_strformat(SI_SKILLS_ADVISOR_GAMEPAD_SELECTED_BUILD_SUBTITLE, selectedSkillBuild.name) or ""

    ZO_GamepadGenericHeader_RefreshData(self.header, self.headerData)
end

local function IsEntryHeader(data)
    return data.header
end

local function AreSkillLineEntriesEqual(left, right)
    return left.skillLineData == right.skillLineData
end

function ZO_GamepadSkills:GetSkillLineEntryIndex(skillLineData)
    for i = 1, self.categoryList:GetNumEntries() do
        local categoryEntry = self.categoryList:GetDataForDataIndex(i)
        if not categoryEntry.isSkillsAdvisor then
            if categoryEntry.skillLineData == skillLineData then
                return i
            end
        end
    end
end

function ZO_GamepadSkills:SelectSkillLineFromAdvisor()
    local skillAdvisorSelectedData = ZO_GAMEPAD_SKILLS_ADVISOR_SUGGESTIONS_WINDOW:GetSelectedData()
    if skillAdvisorSelectedData then
        self.returnToAdvisor = true

        local skillAdvisorProgressionData = skillAdvisorSelectedData.skillProgressionData
        local skillData = skillAdvisorProgressionData:GetSkillData()
        local skillLineData = skillData:GetSkillLineData()
        -- Set the category index to the category where clicked skill ability can be found 
        local categoryIndex = self:GetSkillLineEntryIndex(skillLineData)
        if categoryIndex then 
            self.categoryList:SetSelectedIndexWithoutAnimation(categoryIndex)
        
            if skillLineData:IsAvailable() then
                -- Since the ability we want to select won't be available until after the lineFilterList is refreshed,
                -- store ability we want to select as a member var and use it to select the abilty after list is ready
                self.selectSkillData = skillData

                -- Prevent input while transitioning from skills advisor to selected skill ability in skill line
                self:DisableCurrentList()

                -- Open the skill line filter view
                SCENE_MANAGER:Push("gamepad_skills_line_filter")
            else
                self:SetCurrentList(self.categoryList)
            end
        else
            -- SkillLine not known or yet advised
            ZO_GAMEPAD_SKILLS_ADVISOR_SUGGESTIONS_WINDOW:SetSelectSkillData(skillData)
            skillLineData:SetAdvised(true)
            self:SetCurrentList(self.categoryList)
        end
    end
end

function ZO_GamepadSkills:InitializeCategoryKeybindStrip()
    table.insert(self.categoryKeybindStripDescriptor,
    {
        name = function() --name
            if self.assignableActionBar:IsActive() then
                return GetString(SI_GAMEPAD_SKILLS_BUILD_PLANNER)
            end
            return GetString(SI_GAMEPAD_SELECT_OPTION)
        end,

        keybind = "UI_SHORTCUT_PRIMARY",

        callback =  function()
            --Here we determine what fragment to load, but we're going to wait until it loads to decide how to populate it
            --So we'll prevent any further movement and proceed based on what we expect the selected data to be by the time we need it.
            --We may already be in the process of a scroll, so "current data" isn't reliable.
            local targetData = self.categoryList:GetTargetData()
            if self.assignableActionBar:IsActive() then
                self:DeactivateCurrentList()
                self.selectedTooltipRefreshGroup:MarkDirty("Full")
                SCENE_MANAGER:AddFragment(GAMEPAD_SKILLS_BUILD_PLANNER_FRAGMENT)
                PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
            elseif targetData and targetData.isSkillsAdvisor then
                self:DeactivateCurrentList()
                if ZO_SKILLS_ADVISOR_SINGLETON:GetSelectedSkillBuildId() then
                    ZO_GAMEPAD_SKILLS_ADVISOR_SUGGESTIONS_WINDOW:Activate()
                else
                    SCENE_MANAGER:Push("gamepad_skills_advisor_build_selection_root")
                end
            elseif targetData and not targetData.advised then 
                self:DeactivateCurrentList()
                SCENE_MANAGER:Push("gamepad_skills_line_filter")
            end
        end,
    })

    --Confirm Bind
    table.insert(self.categoryKeybindStripDescriptor,
    {
        name = GetString(SI_SKILL_RESPEC_CONFIRM_KEYBIND),
        keybind = "UI_SHORTCUT_SECONDARY",
        visible = function()
            return SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave()
        end,
        callback = function()
            self:ShowConfirmRespecDialog()
        end,
    })

    --Clear All Bind
    table.insert(self.categoryKeybindStripDescriptor,
    {
        name = function()
            return GetString("SI_SKILLPOINTALLOCATIONMODE_CLEARKEYBIND", SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode())
        end,
        keybind = "UI_SHORTCUT_RIGHT_STICK",
        visible = function()
            if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeAllowDecrease() and not self.assignableActionBar:IsActive() then
                 local targetData = self.categoryList:GetTargetData()
                 return not targetData.isSkillsAdvisor
            end
        end,
        callback = function()
            local skillLineEntry = self.categoryList:GetTargetData()
            self:ShowConfirmClearAllDialog(skillLineEntry.skillLineData)
        end,
    })

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.categoryKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.categoryKeybindStripDescriptor, self.categoryList, IsEntryHeader)
end

function ZO_GamepadSkills:InitializeLineFilterKeybindStrip()
    local function EnableWhileNotActionBarLocked()
        local lockedReason = GetActionBarLockedReason()
        if lockedReason == ACTION_BAR_LOCKED_REASON_COMBAT then
            return false, GetString("SI_RESPECRESULT", RESPEC_RESULT_IS_IN_COMBAT)
        elseif lockedReason == ACTION_BAR_LOCKED_REASON_NOT_RESPECCABLE then
            return false, GetString("SI_RESPECRESULT", RESPEC_RESULT_ACTIVE_HOTBAR_NOT_RESPECCABLE)
        end
        return true
    end

    table.insert(self.lineFilterKeybindStripDescriptor,
    {
        name = function()
            --This is confirm when respecing and assign otherwise
            if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
                return GetString(SI_SKILL_RESPEC_CONFIRM_KEYBIND)
            else
                return GetString(SI_GAMEPAD_SKILLS_ASSIGN)
            end
        end,

        keybind = "UI_SHORTCUT_SECONDARY",

        visible = function()
            if self.mode ~= ZO_GAMEPAD_SKILLS_ABILITY_LIST_BROWSE_MODE or self.assignableActionBar:IsActive() then
                return false
            end
            --This is confirm when respecing and assign otherwise
            if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
                return true
            else
                local skillEntry = self.lineFilterList:GetTargetData()
                if skillEntry then
                    local skillData = skillEntry.skillData
                    return skillData:IsActive() and skillData:GetPointAllocator():IsPurchased()
                end
            end
        end,

        enabled = EnableWhileNotActionBarLocked,

        callback = function()
            --This is confirm when respecing and assign otherwise
            if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
                self:ShowConfirmRespecDialog()
            else
                local skillEntry = self.lineFilterList:GetTargetData()
                local skillData = skillEntry.skillData
                self:DeactivateCurrentList()
                self:StartSingleAbilityAssignment(skillData)
                PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
            end
        end,
    })

    local function IsInSkillPointAllocationMode()
        return not (self.mode == ZO_GAMEPAD_SKILLS_SINGLE_ABILITY_ASSIGN_MODE or self.assignableActionBar:IsActive())
    end

    local function IncreaseSkillKeybindName()
        local skillEntry = self.lineFilterList:GetTargetData()
        local actionType = GetIncreaseSkillAction(skillEntry.skillData)
        if actionType == ACTION_PURCHASE or actionType == ACTION_INCREASE_RANK then
            return GetString(SI_GAMEPAD_SKILLS_PURCHASE)
        elseif actionType == ACTION_MORPH or actionType == ACTION_REMORPH then
            return GetString(SI_GAMEPAD_SKILLS_MORPH)
        end
    end

    local function IncreaseSkillKeybindVisible()
        local skillEntry = self.lineFilterList:GetTargetData()
        if skillEntry then
            return GetIncreaseSkillAction(skillEntry.skillData) ~= ACTION_NONE
        else
            return false
        end
    end

    local function IncreaseSkillKeybindCallback()
        local skillEntry = self.lineFilterList:GetTargetData()
        local skillData = skillEntry.skillData
        local skillProgressionData = skillData:GetPointAllocatorProgressionData()

        local actionType = GetIncreaseSkillAction(skillData)
        local availablePoints = GetAvailableSkillPoints()

        local name = skillProgressionData:GetFormattedNameWithRank()

        if actionType == ACTION_PURCHASE then
            if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeConfirmOnPurchase() then
                local labelData = { titleParams = { availablePoints }, mainTextParams = { name } }
                local dialogData = { purchaseSkillProgressionData = skillProgressionData, }

                ZO_Dialogs_ShowGamepadDialog("GAMEPAD_SKILLS_PURCHASE_CONFIRMATION", dialogData, labelData)
            else
                skillData:GetPointAllocator():Purchase()
            end
        elseif actionType == ACTION_INCREASE_RANK then
            if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeConfirmOnIncreaseRank() then
                local labelData = { titleParams = { availablePoints }, mainTextParams = { name } }
                local dialogData = { currentSkillProgressionData = skillProgressionData }

                ZO_Dialogs_ShowGamepadDialog("GAMEPAD_SKILLS_UPGRADE_CONFIRMATION", dialogData, labelData)
            else
                skillData:GetPointAllocator():IncreaseRank()
            end
        elseif actionType == ACTION_MORPH or actionType == ACTION_REMORPH then
            local morphSkillData = skillProgressionData:GetSkillData()
            local baseMorphSkillProgressionData = morphSkillData:GetMorphData(MORPH_SLOT_BASE)
            local mainTextData = { titleParams = { availablePoints } }
            local dialogData = { morphSkillData = morphSkillData }

            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
            ZO_Dialogs_ShowGamepadDialog("GAMEPAD_SKILLS_MORPH_CONFIRMATION", dialogData, mainTextData)
        end
    end

    local function DecreaseSkillKeybindEnabled()
        local skillEntry = self.lineFilterList:GetTargetData()
        if skillEntry then
            local skillData = skillEntry.skillData
            local actionType = GetDecreaseSkillAction(skillData)
            if actionType ~= ACTION_NONE then
                return true
            elseif SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode() == SKILL_POINT_ALLOCATION_MODE_MORPHS_ONLY and skillData:IsActive() then
                local skillPointAllocator = skillData:GetPointAllocator()
                if skillPointAllocator:IsPurchased() and skillPointAllocator:GetMorphSlot() == MORPH_SLOT_BASE and not skillPointAllocator:CanSell() then
                    return false, GetString(SI_SKILL_RESPEC_MORPHS_ONLY_CANNOT_SELL_BASE_ABILITY)
                end
            end
        end
        return false
    end

    local function DecreaseSkillKeybindCallback()
        local skillEntry = self.lineFilterList:GetTargetData()
        local skillData = skillEntry.skillData
        local skillPointAllocator = skillData:GetPointAllocator()

        local actionType = GetDecreaseSkillAction(skillData)

        if actionType == ACTION_SELL then
            skillPointAllocator:Sell()
        elseif actionType == ACTION_DECREASE_RANK then
            skillPointAllocator:DecreaseRank()
        elseif actionType == ACTION_UNMORPH then
            skillPointAllocator:Unmorph()
        end
    end

    --Decrease Skill Bind
    table.insert(self.lineFilterKeybindStripDescriptor,
    {
        name = function()
            local skillEntry = self.lineFilterList:GetTargetData()
            local action = GetDecreaseSkillAction(skillEntry.skillData)
            return zo_iconFormat(POINT_ACTION_TEXTURES[action], "100%", "100%")
        end,

        keybind = "UI_SHORTCUT_LEFT_SHOULDER",

        visible = function()
            if IsInSkillPointAllocationMode() and SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
                return DecreaseSkillKeybindEnabled()
            else
                return false
            end
        end,

        callback = DecreaseSkillKeybindCallback,
    })

    --Increase Skill Only Bind
    table.insert(self.lineFilterKeybindStripDescriptor,
    {
        name = function()
            local skillEntry = self.lineFilterList:GetTargetData()
            local action = GetIncreaseSkillAction(skillEntry.skillData)
            return zo_iconFormat(POINT_ACTION_TEXTURES[action], "100%", "100%")
        end,

        keybind = "UI_SHORTCUT_RIGHT_SHOULDER",

        visible = function()
            if IsInSkillPointAllocationMode() and SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
                return IncreaseSkillKeybindVisible()
            else
                return false
            end
        end,

        callback = IncreaseSkillKeybindCallback,
    })

    --Single Ability Assign/Assignable Action Bar/Increase Skill Bind
    table.insert(self.lineFilterKeybindStripDescriptor,
    {
        name = function()
            if self.mode == ZO_GAMEPAD_SKILLS_SINGLE_ABILITY_ASSIGN_MODE then
                return GetString(SI_GAMEPAD_SKILLS_ASSIGN)
            elseif self.assignableActionBar:IsActive() then
                return GetString(SI_GAMEPAD_SKILLS_BUILD_PLANNER)
            else
                return IncreaseSkillKeybindName()
            end
        end,

        keybind = "UI_SHORTCUT_PRIMARY",

        visible = function()
            if IsInSkillPointAllocationMode() then
                return not SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() and IncreaseSkillKeybindVisible()
            else
                return true
            end
        end,

        enabled = EnableWhileNotActionBarLocked,

        callback = function()
            if self.mode == ZO_GAMEPAD_SKILLS_SINGLE_ABILITY_ASSIGN_MODE then
                self:DeactivateCurrentList()
                self.assignableActionBar:AssignTargetSkill()
                self.actionBarAnimation:PlayBackward()
                self.assignableActionBar:Deactivate()
                GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
                PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
                --Don't set mode back to ZO_GAMEPAD_SKILLS_ABILITY_LIST_BROWSE_MODE til OnAbilityFinalizedCallback says everything worked
            elseif self.assignableActionBar:IsActive() then
                self:DeactivateCurrentList()
                SCENE_MANAGER:AddFragment(GAMEPAD_SKILLS_BUILD_PLANNER_FRAGMENT)
                PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
            else
                IncreaseSkillKeybindCallback()
            end
        end,
    })

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.lineFilterKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        if self.mode == ZO_GAMEPAD_SKILLS_SINGLE_ABILITY_ASSIGN_MODE then
            self.actionBarAnimation:PlayBackward()
            self.assignableActionBar:Deactivate()
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
            self:SetMode(ZO_GAMEPAD_SKILLS_ABILITY_LIST_BROWSE_MODE)
            PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
        else
            SCENE_MANAGER:HideCurrentScene()
        end
    end)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.lineFilterKeybindStripDescriptor, self.lineFilterList, IsEntryHeader)
end

function ZO_GamepadSkills:InitializeBuildPlannerKeybindStrip()
    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.buildPlannerKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON,
        function() --callback
            self:AssignSelectedBuildPlannerAbility()
        end,
        GetString(SI_GAMEPAD_SKILLS_ASSIGN) --name
    )
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.buildPlannerKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, 
        function()
            SCENE_MANAGER:RemoveFragment(GAMEPAD_SKILLS_BUILD_PLANNER_FRAGMENT)
            PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
        end)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.buildPlannerKeybindStripDescriptor, self.buildPlannerList)
end

function ZO_GamepadSkills:AddWeaponSwapDescriptor(descriptor)
    descriptor[#descriptor + 1] =
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
end

function ZO_GamepadSkills:AddSkillsAdvisorDescriptor(descriptor)
    descriptor[#descriptor + 1] =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,
        name = GetString(SI_SKILLS_ADVISOR_GAMEPAD_OPEN_ADVISOR_SETTINGS),
        keybind = "UI_SHORTCUT_LEFT_STICK",
        sound = SOUNDS.SKILLS_ADVISOR_SELECT,
        visible =   function()
                        local targetData = self.categoryList:GetTargetData()
                        return targetData and targetData.isSkillsAdvisor
                    end,
        callback = function() 
                        SCENE_MANAGER:Push("gamepad_skills_advisor_build_selection_root")
                    end,
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
    self.assignableActionBar:SetOnAbilityFinalizedCallback(function()
        if self.mode == ZO_GAMEPAD_SKILLS_SINGLE_ABILITY_ASSIGN_MODE then
            self.assignableActionBar:ClearTargetSkill()
            self:SetMode(ZO_GAMEPAD_SKILLS_ABILITY_LIST_BROWSE_MODE)
        end
    end)

    self:SetupHeaderFocus(self.assignableActionBar)

    local function OnSelectedActionBarButtonChanged(actionBar, didSlotTypeChange)
        self.selectedTooltipRefreshGroup:MarkDirty("Full")
        if actionBar:GetSelectedSlotIndex() then
            self.assignableActionBarSelectedIndex = actionBar:GetSelectedSlotIndex()
        end
        if self.mode == ZO_GAMEPAD_SKILLS_BUILD_PLANNER_ASSIGN_MODE then
            if didSlotTypeChange then
                self.buildPlannerListRefreshGroup:MarkDirty("List")
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
        if self.assignableActionBarSelectedIndex then
            self.assignableActionBar:SelectButton(self.assignableActionBarSelectedIndex)
        else
            self.assignableActionBar:SelectFirstNormalButton()
        end
        self.assignableActionBar:Activate()
    end
end

function ZO_GamepadSkills:OnEnterHeader()
    self:ActivateAssignableActionBarFromList()
    self:UpdateKeybinds()
    PlaySound(SOUNDS.GAMEPAD_MENU_UP)
end

function ZO_GamepadSkills:OnLeaveHeader()
    self.assignableActionBar:Deactivate()
    self:UpdateKeybinds()
    PlaySound(SOUNDS.GAMEPAD_MENU_DOWN)
end

function ZO_GamepadSkills:UpdateKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.categoryKeybindStripDescriptor)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.lineFilterKeybindStripDescriptor)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.buildPlannerKeybindStripDescriptor)
end

function ZO_GamepadSkills:InitializeCategoryList()
    self.skillInfo = self.control:GetNamedChild("SkillInfo")

    local function SkillLineEntryTemplateSetup(control, data, selected, reselectingDuringRebuild, enabled, activated)
        local skillLineData = data.skillLineData
        if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
            data:SetText(skillLineData:GetFormattedNameWithNumPointsAllocated())
        else
            data:SetText(skillLineData:GetFormattedName())
        end        
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, activated)
        ZO_GamepadSkillLineEntryTemplate_Setup(control, data, selected)
        if selected then
            GAMEPAD_SKILLS_ROOT_SCENE:AddFragment(self.skillLineXPBarFragment)
            ZO_GamepadSkillLineXpBar_Setup(data.skillLineData, self.skillInfo.xpBar, self.skillInfo.name, true)
        end
    end

    local function MenuEntryTemplateSetup(control, data, selected, reselectingDuringRebuild, enabled, activated)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, activated)
        if selected then
            GAMEPAD_SKILLS_ROOT_SCENE:RemoveFragment(self.skillLineXPBarFragment)
        end
    end

    local function SetupCategoryList(list)
        list:SetAdditionalBottomSelectedItemOffsets(0, 20)
        list:SetValidateGradient(true)

        list:AddDataTemplate("ZO_GamepadSkillLineEntryTemplate", SkillLineEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, AreSkillLineEntriesEqual)
        list:AddDataTemplateWithHeader("ZO_GamepadSkillLineEntryTemplate", SkillLineEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, AreSkillLineEntriesEqual, "ZO_GamepadMenuEntryHeaderTemplate")
        list:AddDataTemplate("ZO_GamepadMenuEntryTemplate", MenuEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    end

    self.categoryList = self:AddList("Category", SetupCategoryList)

    self.categoryList:SetOnSelectedDataChangedCallback(
    function(_, selectedData)
        self:OnSelectedSkillLineChanged(selectedData)
    end)
end

local function MenuAbilityEntryTemplateSetup(control, skillEntry, selected, reselectingDuringRebuild, enabled, activated)
    local skillData = skillEntry.skillData
    
    --Derive the progression specific info from the point allocator progression. This is done here so we can just do a RefreshVisible when the point allocator changes.
    local skillPointAllocator = skillData:GetPointAllocator()
    local skillProgressionData = skillPointAllocator:GetProgressionData()
    local name 
    if skillData:IsPassive() then
        if skillData:GetNumRanks() > 1 then
            name = skillProgressionData:GetFormattedNameWithUpgradeLevels(SI_GAMEPAD_ABILITY_NAME_AND_UPGRADE_LEVELS)
        else
            name = skillProgressionData:GetFormattedName()
        end
    else
        name = skillProgressionData:GetFormattedNameWithRank()
    end
    skillEntry:SetText(name)
    skillEntry:ClearIcons()
    skillEntry:AddIcon(skillProgressionData:GetIcon())
    if skillEntry.isPreview then
        local color = skillPointAllocator:IsPurchased() and ZO_SELECTED_TEXT or ZO_DISABLED_TEXT
        skillEntry:SetNameColors(color, color)
    end

    ZO_SharedGamepadEntry_OnSetup(control, skillEntry, selected, reselectingDuringRebuild, enabled, activated)
    ZO_GamepadSkillEntryTemplate_Setup(control, skillEntry, selected, activated, ZO_SKILL_ABILITY_DISPLAY_INTERACTIVE)
end

local function IsSkillEqual(leftSkillEntry, rightSkillEntry)
    return leftSkillEntry.skillData == rightSkillEntry.skillData
end

function ZO_GamepadSkills:InitializeLineFilterList()
    local function SetupLineFilterList(list)
        list:SetValidateGradient(true)
        list:AddDataTemplate("ZO_GamepadAbilityEntryTemplate", MenuAbilityEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, IsSkillEqual)
        list:AddDataTemplateWithHeader("ZO_GamepadAbilityEntryTemplate", MenuAbilityEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, IsSkillEqual, "ZO_GamepadMenuEntryHeaderTemplate")
    end
    self.lineFilterList = self:AddList("LineFilter", SetupLineFilterList)
    self.lineFilterList:SetOnSelectedDataChangedCallback(function(list, selectedData)
        self:OnSelectedSkillChanged(selectedData)
    end)

    local lineFilterListControl = self.lineFilterList:GetControl()
    local lineFilterListContainer = lineFilterListControl:GetParent()
    local lineFilterRespecBindingsControl = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)RespecBindings", lineFilterListContainer, "ZO_GamepadSkills_RespecBindings")
    lineFilterRespecBindingsControl:SetAnchor(BOTTOMLEFT, lineFilterListControl, TOPLEFT, 0, 0)
    lineFilterRespecBindingsControl:SetAnchor(BOTTOMRIGHT, lineFilterListControl, TOPRIGHT, 0, 0)
    self.lineFilterRespecBindingsControl = lineFilterRespecBindingsControl
end

function ZO_GamepadSkills:InitializeLineFilterPreviewList()
    local lineFilterPreviewContainer = ZO_GamepadSkillsLinePreview:GetNamedChild("ScrollContainer")
    local lineFilterPreviewList = ZO_ParametricScrollList:New(lineFilterPreviewContainer:GetNamedChild("List"), PARAMETRIC_SCROLL_LIST_VERTICAL)
    lineFilterPreviewList:SetHeaderPadding(GAMEPAD_HEADER_DEFAULT_PADDING, 0)
    lineFilterPreviewList:SetUniversalPostPadding(5)
    lineFilterPreviewList:SetSelectedItemOffsets(0, 0)
    lineFilterPreviewList:SetAlignToScreenCenter(true)
    lineFilterPreviewList:SetGradient(1, 0)
    lineFilterPreviewList:SetGradient(2, 0)
    
    -- this isn't a list that we will interact with and selecting entries on it
    -- causes sounds effects to play (and we select entries in the list in RefreshLineFilterList)
    lineFilterPreviewList:SetSoundEnabled(false)

    lineFilterPreviewList:AddDataTemplate("ZO_GamepadSingleLineAbilityEntryTemplate", MenuAbilityEntryTemplateSetup, nil, IsSkillEqual)
    lineFilterPreviewList:AddDataTemplateWithHeader("ZO_GamepadSingleLineAbilityEntryTemplate", MenuAbilityEntryTemplateSetup, nil, IsSkillEqual, "ZO_GamepadMenuEntryHeaderTemplate")

    self.lineFilterPreviewList = lineFilterPreviewList
end

local function MenuEntryHeaderTemplateSetup(control, skillEntry, selected, selectedDuringRebuild, enabled, activated)
    control.header:SetText(skillEntry:GetHeader())
    local skillData = skillEntry.skillData
    control.skillRankHeader:SetText(skillData:GetSkillLineData():GetCurrentRank())
end

function ZO_GamepadSkills:InitializeBuildPlanner()
    local buildPlannerControl = self.control:GetNamedChild("BuildPlanner"):GetNamedChild("Container"):GetNamedChild("List")

    self.buildPlannerList = ZO_GamepadVerticalParametricScrollList:New(buildPlannerControl)
    self.buildPlannerList:SetAlignToScreenCenter(true)
    self.buildPlannerList:SetValidateGradient(true)

    self.buildPlannerList:SetNoItemText(GetString(SI_GAMEPAD_SKILLS_NO_ABILITIES))

    self.buildPlannerList:AddDataTemplate("ZO_GamepadSimpleAbilityEntryTemplate", MenuAbilityEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, IsSkillEqual)
    self.buildPlannerList:AddDataTemplateWithHeader("ZO_GamepadSimpleAbilityEntryTemplate", MenuAbilityEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, IsSkillEqual, "ZO_GamepadSimpleAbilityEntryHeaderTemplate", MenuEntryHeaderTemplateSetup)

    local function RefreshSelectedTooltip()
        self.selectedTooltipRefreshGroup:MarkDirty("Full")
    end

    self.buildPlannerList:SetOnSelectedDataChangedCallback(RefreshSelectedTooltip)

    local X_OFFSET = 30
    local Y_OFFSET = 15
    buildPlannerControl:ClearAnchors()
    buildPlannerControl:SetAnchor(TOPLEFT, self.header, BOTTOMLEFT, -X_OFFSET, Y_OFFSET)
    buildPlannerControl:SetAnchor(BOTTOMRIGHT, buildPlannerControl:GetParent(), BOTTOMRIGHT, X_OFFSET, 0)
end

function ZO_GamepadSkills:InitializeRefreshGroups()
    --Category List
    local categoryListRefreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_PER_FRAME)
    categoryListRefreshGroup:AddDirtyState("List", function()
        self:RefreshCategoryList()
    end)
    categoryListRefreshGroup:AddDirtyState("Visible", function()
        self.categoryList:RefreshVisible()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.categoryKeybindStripDescriptor)
    end)
    categoryListRefreshGroup:SetActive(function()
        return GAMEPAD_SKILLS_ROOT_SCENE:IsShowing()
    end)
    categoryListRefreshGroup:MarkDirty("List")
    self.categoryListRefreshGroup = categoryListRefreshGroup

    --Line Filter List
    local lineFilterListRefreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_PER_FRAME)
    lineFilterListRefreshGroup:AddDirtyState("List", function()
        self:RefreshLineFilterList(false)
    end)
    lineFilterListRefreshGroup:AddDirtyState("Visible", function()
        self.lineFilterList:RefreshVisible()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.lineFilterKeybindStripDescriptor)
    end)
    lineFilterListRefreshGroup:SetActive(function()
        return GAMEPAD_SKILLS_LINE_FILTER_SCENE:IsShowing()
    end)
    self.lineFilterListRefreshGroup = lineFilterListRefreshGroup

    --Line Filter Preview List
    local lineFilterPreviewListRefreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_PER_FRAME)
    lineFilterPreviewListRefreshGroup:AddDirtyState("List", function()
        self:RefreshLineFilterList(true)
    end)
    lineFilterPreviewListRefreshGroup:AddDirtyState("Visible", function()
        self.lineFilterPreviewList:RefreshVisible()
    end)
    lineFilterPreviewListRefreshGroup:SetActive(function()
        return GAMEPAD_SKILLS_LINE_PREVIEW_FRAGMENT:IsShowing()
    end)
    self.lineFilterPreviewListRefreshGroup = lineFilterPreviewListRefreshGroup

    --Build Planner List
    local buildPlannerListRefreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_PER_FRAME)
    buildPlannerListRefreshGroup:AddDirtyState("List", function()
        self:RefreshBuildPlannerList()
    end)
    buildPlannerListRefreshGroup:AddDirtyState("Visible", function()
        self.buildPlannerList:RefreshVisible()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.buildPlannerKeybindStripDescriptor)
    end)
    buildPlannerListRefreshGroup:SetActive(function()
        return GAMEPAD_SKILLS_BUILD_PLANNER_FRAGMENT:IsShowing()
    end)
    self.buildPlannerListRefreshGroup = buildPlannerListRefreshGroup

    --Selected Tooltip
    local selectedTooltipRefreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_PER_FRAME)
    selectedTooltipRefreshGroup:AddDirtyState("Full", function()
        self:RefreshSelectedTooltip()
    end)
    self.selectedTooltipRefreshGroup = selectedTooltipRefreshGroup
end

function ZO_GamepadSkills:InitializeEvents()
    --Skill and Point Updates

    --Systems that could need a refresh:
    --categoryList (RefreshCategoryList)
    --lineFilterList (RefreshLineFilterList(false))
    --lineFilterPreviewList (RefreshLineFilterList(true))
    --buildPlannerList (RefreshBuildPlannerList)
    --Selected Tooltip (RefreshSelectedTooltip)
    --Points Display (RefreshPointsDisplay)

    local function FullRebuild()
        self.categoryListRefreshGroup:MarkDirty("List")
        self.lineFilterListRefreshGroup:MarkDirty("List")
        self.lineFilterPreviewListRefreshGroup:MarkDirty("List")
        self.buildPlannerListRefreshGroup:MarkDirty("List")
        self:RefreshPointsDisplay()
        self.selectedTooltipRefreshGroup:MarkDirty("Full")
    end

    local function OnSkillLineUpdated(skillLineData)
        --For the skill line rank on each entry and the skill line XP bar on the selected entry
        self.categoryListRefreshGroup:MarkDirty("Visible")
        --For the locked/unlocked display on a skill
        self.lineFilterListRefreshGroup:MarkDirty("Visible", skillLineData)
        --For the locked/unlocked display on a skill
        self.lineFilterPreviewListRefreshGroup:MarkDirty("Visible", skillLineData)
        --For the skill line rank in the header of each section
        self.buildPlannerListRefreshGroup:MarkDirty("Visible")
        self.selectedTooltipRefreshGroup:MarkDirty("Full")
    end

    local function OnSkillLineAdded(skillLineData)
        --To add the new skill line to the list
        self.categoryListRefreshGroup:MarkDirty("List")
        --To add the skills in the new skill line to the combined planner list
        self.buildPlannerListRefreshGroup:MarkDirty("List")
        self.selectedTooltipRefreshGroup:MarkDirty("Full")
    end

    local function OnSkillProgressionUpdated(skillData)
        local skillLineData = skillData:GetSkillLineData()
        --For the name of an active skill entry
        self.lineFilterListRefreshGroup:MarkDirty("Visible", skillLineData)
        --For the name of an active skill entry
        self.lineFilterPreviewListRefreshGroup:MarkDirty("Visible", skillLineData)
        --For the name of an active skill entry
        self.buildPlannerListRefreshGroup:MarkDirty("Visible")
        self.selectedTooltipRefreshGroup:MarkDirty("Full")
    end

    local function OnPointAllocatorPurchasedChanged(skillPointAllocator)
        local skillLineData = skillPointAllocator:GetSkillData():GetSkillLineData()
        --For the number of allocated points after the skill line name
        self.categoryListRefreshGroup:MarkDirty("Visible")
        --For the purchased state and name of skills
        self.lineFilterListRefreshGroup:MarkDirty("Visible", skillLineData)
        --For the purchased state and name of skills
        self.lineFilterPreviewListRefreshGroup:MarkDirty("Visible", skillLineData)
        --To add or remove skills from the combined planner list
        self.buildPlannerListRefreshGroup:MarkDirty("List")
        self.selectedTooltipRefreshGroup:MarkDirty("Full")
    end

    local function OnPointAllocatorProgressionKeyChanged(skillPointAllocator)
        local skillLineData = skillPointAllocator:GetSkillData():GetSkillLineData()
        --For the number of allocated points after the skill line name
        self.categoryListRefreshGroup:MarkDirty("Visible")
        --For the name of skills
        self.lineFilterListRefreshGroup:MarkDirty("Visible", skillLineData)
        --For the name of skills
        self.lineFilterPreviewListRefreshGroup:MarkDirty("Visible", skillLineData)
        self.selectedTooltipRefreshGroup:MarkDirty("Full")
    end

    local function OnSkillsCleared(skillLineData)
        --Skill Line Data is only defined if a single skill line was cleared
        --For the number of allocated points after the skill line name
        self.categoryListRefreshGroup:MarkDirty("Visible")
        --For the purchased state and name of skills
        self.lineFilterListRefreshGroup:MarkDirty("Visible", skillLineData)
        --For the purchased state and name of skills
        self.lineFilterPreviewListRefreshGroup:MarkDirty("Visible", skillLineData)
        --To add or remove skills from the combined planner list
        self.buildPlannerListRefreshGroup:MarkDirty("List")
        self.selectedTooltipRefreshGroup:MarkDirty("Full")
    end

    local function OnSkillPointsChanged()
        --For the number of allocated points after the skill line name
        self.categoryListRefreshGroup:MarkDirty("Visible")
        --For the point spending action icons
        self.lineFilterListRefreshGroup:MarkDirty("Visible")
        --For the point spending action icons
        self.lineFilterPreviewListRefreshGroup:MarkDirty("Visible")
        self.selectedTooltipRefreshGroup:MarkDirty("Full")
        self:RefreshPointsDisplay()
    end

    local function OnSkillPointAllocationModeChanged()
        --For the number of allocated points after the skill line name
        self.categoryListRefreshGroup:MarkDirty("Visible")
        --For the purchased state and name of skills
        self.lineFilterListRefreshGroup:MarkDirty("Visible")
        --For the purchased state and name of skills
        self.lineFilterPreviewListRefreshGroup:MarkDirty("Visible")
        --To add or remove skills from the combined planner list
        self.buildPlannerListRefreshGroup:MarkDirty("List")
        --For the number of used skill points changing
        self:RefreshPointsDisplay()
        --To show or hide the respec mode bindings
        self:RefreshRespecModeBindingsDisplay()
        --To refresh showing the commit/clear all binds
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.categoryKeybindStripDescriptor)
        self.selectedTooltipRefreshGroup:MarkDirty("Full")
    end

    local function OnCurrentHotbarUpdated()
        --To add or remove skills from the combined planner list to match hotbar-specific rules
        self.buildPlannerListRefreshGroup:MarkDirty("List")
        --To refresh tooltip if an action slot is selected
        self.selectedTooltipRefreshGroup:MarkDirty("Full")
    end

    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, FullRebuild)
    SKILLS_DATA_MANAGER:RegisterCallback("FullSystemUpdated", FullRebuild)
    SKILLS_DATA_MANAGER:RegisterCallback("SkillLineUpdated", OnSkillLineUpdated)
    SKILLS_DATA_MANAGER:RegisterCallback("SkillLineAdded", OnSkillLineAdded)
    SKILLS_DATA_MANAGER:RegisterCallback("SkillProgressionUpdated", OnSkillProgressionUpdated)
    SKILL_POINT_ALLOCATION_MANAGER:RegisterCallback("PurchasedChanged", OnPointAllocatorPurchasedChanged)
    SKILL_POINT_ALLOCATION_MANAGER:RegisterCallback("SkillProgressionKeyChanged", OnPointAllocatorProgressionKeyChanged)
    SKILL_POINT_ALLOCATION_MANAGER:RegisterCallback("OnSkillsCleared", OnSkillsCleared)
    SKILL_POINT_ALLOCATION_MANAGER:RegisterCallback("SkillPointsChanged", OnSkillPointsChanged)
    SKILLS_AND_ACTION_BAR_MANAGER:RegisterCallback("SkillPointAllocationModeChanged", OnSkillPointAllocationModeChanged)
    SKILLS_AND_ACTION_BAR_MANAGER:RegisterCallback("RespecStateReset", FullRebuild)
    ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("CurrentHotbarUpdated", OnCurrentHotbarUpdated)

    --Weapon Swap
    local function OnHotbarSwapVisibleStateChanged()
        if not self.control:IsHidden() then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.categoryKeybindStripDescriptor)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.lineFilterKeybindStripDescriptor)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.buildPlannerKeybindStripDescriptor)
        end
    end
    ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("HotbarSwapVisibleStateChanged", OnHotbarSwapVisibleStateChanged)

    --Skill Advisor
    ZO_SKILLS_ADVISOR_SINGLETON:RegisterCallback("OnRequestSelectSkillLine", function() self:SelectSkillLineFromAdvisor() end)

    self.control:RegisterForEvent(EVENT_PLAYER_DEACTIVATED, function() self:OnPlayerDeactivated() end)

    local function OnPurchaseLockStateChanged()
        -- Refresh state of purchase/morph/assign keybinds
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.lineFilterKeybindStripDescriptor)
    end
    self.control:RegisterForEvent(EVENT_ACTION_BAR_LOCKED_REASON_CHANGED, OnPurchaseLockStateChanged)
end

function ZO_GamepadSkills:TryClearSkillUpdatedStatus()
    if self.clearAbilityStatusOnSelectionChanged then
        self.clearAbilityStatusOnSelectionChanged = false
        self.clearSkillUpdatedStatusSkillData:ClearUpdate()
        self.lineFilterList:RefreshVisible()
    end
end

function ZO_GamepadSkills:TryClearSkillLineNewStatus()
    if self.clearSkillLineStatusOnSelectionChanged then
        self.clearSkillLineStatusOnSelectionChanged = false
        self.clearSkillLineNewStatusSkillLineData:ClearNew()
        self.categoryList:RefreshVisible()
    end
end

function ZO_GamepadSkills:TrySetClearUpdatedAbilityFlag(callId)
    if self.clearSkillUpdatedStatusCallId == callId then
        self.clearAbilityStatusOnSelectionChanged = true
    end
end

function ZO_GamepadSkills:TrySetClearNewSkillLineFlag(callId)
    if self.clearSkillLineNewStatusCallId == callId then
        self.clearSkillLineStatusOnSelectionChanged = true
    end
end

function ZO_GamepadSkills:RefreshCategoryList()
    self.categoryList:Clear()

    local skillsAdvisorEntryData = ZO_GamepadEntryData:New(zo_strformat(SI_SKILLS_ENTRY_NAME_FORMAT, GetString(SI_SKILLS_ADVISOR_TITLE)))
    skillsAdvisorEntryData.isSkillsAdvisor = true
    self.categoryList:AddEntry("ZO_GamepadMenuEntryTemplate", skillsAdvisorEntryData)

    for _, skillTypeData in SKILLS_DATA_MANAGER:SkillTypeIterator() do
        local isHeader = true
        for _, skillLineData in skillTypeData:SkillLineIterator() do
            if skillLineData:IsAvailable() or skillLineData:IsAdvised() then
                local function IsSkillLineNew()
                    return skillLineData:IsSkillLineOrAbilitiesNew()
                end

                local data = ZO_GamepadEntryData:New()
                data:SetNew(IsSkillLineNew)
                data.skillLineData = skillLineData

                if isHeader then
                    data:SetHeader(skillTypeData:GetName())  
                    self.categoryList:AddEntry("ZO_GamepadSkillLineEntryTemplateWithHeader", data)
                else
                    self.categoryList:AddEntry("ZO_GamepadSkillLineEntryTemplate", data)
                end

                isHeader = false
            end
        end
    end
    self.categoryList:Commit()

    local selectSkillData = ZO_GAMEPAD_SKILLS_ADVISOR_SUGGESTIONS_WINDOW:GetSelectSkillData()
    if selectSkillData then 
        local categoryEntryIndex = self:GetSkillLineEntryIndex(selectSkillData:GetSkillLineData())
        if categoryEntryIndex then 
            self.categoryList:SetSelectedIndexWithoutAnimation(categoryEntryIndex)
        end
        ZO_GAMEPAD_SKILLS_ADVISOR_SUGGESTIONS_WINDOW:SetSelectSkillData(nil)
    end
end

do
    local g_ShownHeaderTexts = {}

    function ZO_GamepadSkills:RefreshLineFilterList(refreshPreviewList)
        local list = refreshPreviewList and self.lineFilterPreviewList or self.lineFilterList
        list:Clear()
        ZO_ClearTable(g_ShownHeaderTexts)

        local skillLineEntry = self.categoryList:GetTargetData()
        if skillLineEntry.isSkillsAdvisor then
            return
        end

        local skillLineData = skillLineEntry.skillLineData
        for _, skillData in skillLineData:SkillIterator() do
            local skillEntry = ZO_GamepadEntryData:New()

            if refreshPreviewList then
                skillEntry.isPreview = true
            end

            skillEntry:SetFontScaleOnSelection(false)
            skillEntry.skillData = skillData

            local headerText = skillData:GetHeaderText()
            if not refreshPreviewList and not g_ShownHeaderTexts[headerText] then                
                skillEntry:SetHeader(headerText)
                if refreshPreviewList then
                    list:AddEntry("ZO_GamepadSingleLineAbilityEntryTemplateWithHeader", skillEntry)
                else
                    list:AddEntry("ZO_GamepadAbilityEntryTemplateWithHeader", skillEntry)
                end
                g_ShownHeaderTexts[headerText] = true
            else
                if refreshPreviewList then
                    list:AddEntry("ZO_GamepadSingleLineAbilityEntryTemplate", skillEntry)
                else
                    list:AddEntry("ZO_GamepadAbilityEntryTemplate", skillEntry)
                end
            end
        end

        list:Commit()

        if refreshPreviewList then
            -- attempt to vertically center the preview list so that all abilities in the skill line should be visible
            list:SetSelectedIndexWithoutAnimation(zo_floor(#list.dataList / 2) + 1)
        end
    end
end

do
    local SkillDataFilters = 
    {
        function(skillData)
            return skillData:GetPointAllocator():IsPurchased() and skillData:IsActive()
        end,
    }

    function ZO_GamepadSkills:RefreshBuildPlannerList()
        self.buildPlannerList:Clear()

        local skillLineFilters = { ZO_SkillLineData.IsAvailable }
        if ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbarCategory() == HOTBAR_CATEGORY_WEREWOLF then
            table.insert(skillLineFilters, ZO_SkillLineData.IsWerewolf)
        end

        for _, skillTypeData in SKILLS_DATA_MANAGER:SkillTypeIterator() do
            for _, skillLineData in skillTypeData:SkillLineIterator(skillLineFilters) do
                local newSkillLine = true
                for _, skillData in skillLineData:SkillIterator(SkillDataFilters) do
                    if self.assignableActionBar:IsUltimateSelected() == skillData:IsUltimate() then
                        local skillEntry = ZO_GamepadEntryData:New()
                        skillEntry:SetFontScaleOnSelection(false)
                        skillEntry.skillData = skillData

                        if newSkillLine then
                            skillEntry:SetHeader(skillLineData:GetFormattedName())
                            self.buildPlannerList:AddEntry("ZO_GamepadSimpleAbilityEntryTemplateWithHeader", skillEntry)
                        else
                            self.buildPlannerList:AddEntry("ZO_GamepadSimpleAbilityEntryTemplate", skillEntry)
                        end

                        newSkillLine = false
                    end
                end
            end
        end

        self.buildPlannerList:Commit()
    end
end

function ZO_GamepadSkills:RefreshPointsDisplay()
    local availablePoints = SKILL_POINT_ALLOCATION_MANAGER:GetAvailableSkillPoints()
    local skyShards = GetNumSkyShards()

    self.headerData.data1Text = availablePoints
    self.headerData.data2Text = zo_strformat(SI_GAMEPAD_SKILLS_SKY_SHARDS_FOUND, skyShards, NUM_PARTIAL_SKILL_POINTS_FOR_FULL)

    ZO_GamepadGenericHeader_RefreshData(self.header, self.headerData)
end

function ZO_GamepadSkills:RefreshRespecModeBindingsDisplay()
    local showBindings = SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave()
    self.lineFilterRespecBindingsControl:SetHidden(not showBindings)
    local listTopOffsetY = showBindings and 50 or 0
    local lineFilterListControl = self.lineFilterList:GetControl()
    local lineFilterListContainer = lineFilterListControl:GetParent()
    local skillsContainer = lineFilterListContainer:GetParent()
    local headerContainer = skillsContainer:GetNamedChild("HeaderContainer")
    lineFilterListControl:ClearAnchors()
    lineFilterListControl:SetAnchor(TOPLEFT, headerContainer, BOTTOMLEFT, 0, listTopOffsetY)
    lineFilterListControl:SetAnchor(BOTTOMRIGHT, nil, BOTTOMRIGHT, 0, 0)
end

do
    local g_purchaseAndUpgradeHeaderData =
    {
        data1 =
        {
            header = GetString(SI_GAMEPAD_SKILLS_AVAILABLE_POINTS),
        },
    }
    local function SetupFunction(control)
        local availablePoints = GetAvailableSkillPoints()
   
        g_purchaseAndUpgradeHeaderData.data1.value = availablePoints
        control.setupFunc(control, g_purchaseAndUpgradeHeaderData)
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
            warning = 
            {
                text = function(dialog)
                    if not ZO_SKILLS_ADVISOR_SINGLETON:IsAdvancedModeSelected() and dialog.data.purchaseSkillProgressionData:IsAdvised() then
                        ZO_GenericGamepadDialog_SetDialogWarningColor(dialog, ZO_SKILLS_ADVISOR_ADVISED_COLOR)
                        return GetString(SI_SKILLS_ADVISOR_PURCHASE_ADVISED)
                    end
                    return ""
                end
            },
            buttons =
            {
                [1] =
                {
                    text =      SI_GAMEPAD_SKILLS_PURCHASE,
                    callback =  function(dialog)
                                    local purchaseSkillProgressionData = dialog.data.purchaseSkillProgressionData
                                    local skillData = purchaseSkillProgressionData:GetSkillData()
                                    skillData:GetPointAllocator():Purchase()
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
            warning = 
            {
                text = function(dialog)
                    local currentSkillProgressionData = dialog.data.currentSkillProgressionData
                    local upgradeSkillProgressionData = currentSkillProgressionData:GetNextRankData()
                    if not ZO_SKILLS_ADVISOR_SINGLETON:IsAdvancedModeSelected() and upgradeSkillProgressionData:IsAdvised() then
                        ZO_GenericGamepadDialog_SetDialogWarningColor(dialog, ZO_SKILLS_ADVISOR_ADVISED_COLOR)
                        return GetString(SI_SKILLS_ADVISOR_PURCHASE_ADVISED)
                    end
                    return ""
                end
            },
            buttons =
            {
                [1] =
                {
                    text =      SI_GAMEPAD_SKILLS_PURCHASE,
                    callback =  function(dialog)
                                    local currentSkillProgressionData = dialog.data.currentSkillProgressionData
                                    local skillData = currentSkillProgressionData:GetSkillData()
                                    skillData:GetPointAllocator():IncreaseRank()
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
        local morphSkillData = parametricDialog.data.morphSkillData
        local specificMorphSkillProgressionData = morphSkillData:GetProgressionData(data.morphSlot)

        data:SetText(specificMorphSkillProgressionData:GetFormattedName())
        data:ClearIcons()
        data:AddIcon(specificMorphSkillProgressionData:GetIcon())
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)

        local skillEntry = {
            skillProgressionData = specificMorphSkillProgressionData,
            isMorphDialog = true,
        }
        ZO_GamepadSkillEntryTemplate_Setup(control, skillEntry, selected, active, ZO_SKILL_ABILITY_DISPLAY_VIEW)
    end

    local function MorphConfirmCallback(dialog)
        local morphSkillData = dialog.data.morphSkillData
        local morphEntry = dialog.entryList:GetTargetData()
        morphSkillData:GetPointAllocator():Morph(morphEntry.morphSlot)
    end

    local g_morphHeaderData =
    {
        data1 =
        {
            header = GetString(SI_GAMEPAD_SKILLS_AVAILABLE_POINTS),
        },
        data2 =
        {
            header = GetString(SI_GAMEPAD_SKILLS_MORPH_COST_HEADER),
            value = 1,
        },
    }

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

                g_morphHeaderData.data1.value = availablePoints
                ZO_GenericGamepadDialog_ShowTooltip(dialog)
                dialog:setupFunc(nil, g_morphHeaderData)

                --Select the currently chosen morph if a morph is chosen, or pick the first one
                local morphSkillData = dialog.data.morphSkillData
                local selectedMorphSkillProgressionData = morphSkillData:GetPointAllocatorProgressionData()
                if selectedMorphSkillProgressionData:GetMorphSlot() == MORPH_SLOT_MORPH_2 then
                    dialog.entryList:SetSelectedIndexWithoutAnimation(2)
                else
                    dialog.entryList:SetSelectedIndexWithoutAnimation(1)
                end 
            end,

            title =
            {
                text = GetString(SI_GAMEPAD_SKILLS_MORPH_TITLE),
            },

            parametricList =
            {
                -- Morph 1
                {
                    template = "ZO_GamepadSimpleAbilityEntryTemplate",
                    templateData =
                    {
                        setup = MorphConfirmSetup,
                        morphSlot = MORPH_SLOT_MORPH_1,
                    },
                },
                -- Morph 2
                {
                    template = "ZO_GamepadSimpleAbilityEntryTemplate",
                    templateData =
                    {
                        setup = MorphConfirmSetup,
                        morphSlot = MORPH_SLOT_MORPH_2,
                    },
                },
            },

            parametricListOnSelectionChangedCallback = function(dialog, list)
                                                            local targetData = list:GetTargetData()
                                                            local morphSkillData = parametricDialog.data.morphSkillData
                                                            local morphSkillProgressionData = morphSkillData:GetMorphData(targetData.morphSlot)
                                                            local SHOW_RANK_NEEDED_LINE = true
                                                            local SHOW_POINT_SPEND_LINE = true
                                                            local SHOW_ADVISED_LINE = true
                                                            local DONT_SHOW_RESPEC_TO_FIX_BAD_MORPH_LINE = false
                                                            local SHOW_UPGRADE_INFO_BLOCK = true
                                                            local SHOULD_OVERRIDE_RANK_FOR_COMPARISON = true                               
                                                            GAMEPAD_TOOLTIPS:LayoutSkillProgression(GAMEPAD_LEFT_DIALOG_TOOLTIP, morphSkillProgressionData, SHOW_RANK_NEEDED_LINE, SHOW_POINT_SPEND_LINE, SHOW_ADVISED_LINE, DONT_SHOW_RESPEC_TO_FIX_BAD_MORPH_LINE, SHOW_UPGRADE_INFO_BLOCK, SHOULD_OVERRIDE_RANK_FOR_COMPARISON)
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
                                    self.selectedTooltipRefreshGroup:MarkDirty("Full")
                                end,
                },
            },
        })
    end
end

function ZO_GamepadSkills:InitializeRespecConfirmationGoldDialog()
    local dialogData =
    {
        data1 =
        {
            header = GetString(SI_GAMEPAD_SKILL_RESPEC_CONFIRM_DIALOG_BALANCE_HEADER),
        },
        data2 = 
        {
            header = GetString(SI_GAMEPAD_SKILL_RESPEC_CONFIRM_DIALOG_COST_HEADER),
        },
    }

    ZO_Dialogs_RegisterCustomDialog("SKILL_RESPEC_CONFIRM_GOLD_GAMEPAD",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_SKILL_RESPEC_CONFIRM_DIALOG_TITLE,
        },
        mainText = 
        {
            text = SI_SKILL_RESPEC_CONFIRM_DIALOG_BODY_INTRO,
        },
        setup = function(dialog)
            local balance = GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)
            local cost = GetSkillRespecCost(SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode())
            local IS_GAMEPAD = true
            dialogData.data1.value = ZO_Currency_Format(balance, CURT_MONEY, ZO_CURRENCY_FORMAT_AMOUNT_ICON, IS_GAMEPAD)
            dialogData.data2.value = ZO_Currency_Format(cost, CURT_MONEY, balance > cost and ZO_CURRENCY_FORMAT_AMOUNT_ICON or ZO_CURRENCY_FORMAT_ERROR_AMOUNT_ICON, IS_GAMEPAD)
            dialog.setupFunc(dialog, dialogData)
        end,
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_DIALOG_CONFIRM,
                callback = function()
                    SKILLS_AND_ACTION_BAR_MANAGER:ApplyChanges()
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },
        },
    })
end

function ZO_GamepadSkills:ShowConfirmRespecDialog()
    if SKILL_POINT_ALLOCATION_MANAGER:DoPendingChangesIncurCost() then
        if SKILLS_AND_ACTION_BAR_MANAGER:GetSkillRespecPaymentType() == SKILL_RESPEC_PAYMENT_TYPE_GOLD then
            ZO_Dialogs_ShowGamepadDialog("SKILL_RESPEC_CONFIRM_GOLD_GAMEPAD")
        else
            ZO_Dialogs_ShowGamepadDialog("SKILL_RESPEC_CONFIRM_SCROLL")
        end
    else
        ZO_Dialogs_ShowGamepadDialog("SKILL_RESPEC_CONFIRM_FREE")
    end
end

function ZO_GamepadSkills:InitializeConfirmClearAllDialog()
    local clearSkillLineEntry =
    {
        template = "ZO_GamepadMenuEntryTemplate",
        templateData =
        {
            setup = ZO_SharedGamepadEntry_OnSetup,
        }
    }

    ZO_Dialogs_RegisterCustomDialog("SKILL_RESPEC_CONFIRM_CLEAR_ALL_GAMEPAD",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        title =
        {
            text = function()
                return GetString("SI_SKILLPOINTALLOCATIONMODE_CLEARKEYBIND", SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode())
            end,
        },
        setup = function(dialog, skillLineData)
            clearSkillLineEntry.header = GetString("SI_SKILLPOINTALLOCATIONMODE_CLEARCHOICEHEADERGAMEPAD", SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode())
            local clearSkillLineEntryTemplateData = clearSkillLineEntry.templateData
            clearSkillLineEntryTemplateData.text = skillLineData:GetFormattedName()
            clearSkillLineEntryTemplateData.skillLineData = skillLineData
            dialog.setupFunc(dialog, nil , skillLineData)
        end,
        parametricList =
        {
            -- Clear Skill Line
            clearSkillLineEntry,
            -- Clear All
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData =
                {
                    text = GetString(SI_SKILL_RESPEC_CONFIRM_CLEAR_ALL_DIALOG_ALL_OPTION),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                },
            },
        },
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_DIALOG_CONFIRM,
                callback = function(dialog)
                    local entry = dialog.entryList:GetTargetData()
                    if entry.skillLineData then
                        SKILL_POINT_ALLOCATION_MANAGER:ClearPointsOnSkillLine(entry.skillLineData)
                    else
                        SKILL_POINT_ALLOCATION_MANAGER:ClearPointsOnAllSkillLines()
                    end
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },
        },
    })
end

function ZO_GamepadSkills:ShowConfirmClearAllDialog(skillLineData)
    ZO_Dialogs_ShowGamepadDialog("SKILL_RESPEC_CONFIRM_CLEAR_ALL_GAMEPAD", skillLineData)
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
                    end,
                },
            },

            finishedCallback = function(dialog)
                                --Setup Skills Scene
                                DisableSpinner(dialog)
                                ZO_GenericGamepadDialog_HideTooltip(dialog)
                                self.showAttributeDialog = false
                                self.selectedTooltipRefreshGroup:MarkDirty("Full")
                                self:ResetAttributeData()                                
                            end,
        })
    end
end

local TIME_NEW_PERSISTS_WHILE_SELECTED = 1000

function ZO_GamepadSkills:OnSelectedSkillChanged(skillEntry)
    self.selectedTooltipRefreshGroup:MarkDirty("Full")
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.lineFilterKeybindStripDescriptor)

    self:TryClearSkillUpdatedStatus()

    if skillEntry and not self.assignableActionBar:IsActive() then
        local skillData = skillEntry.skillData
        if skillData:HasUpdatedStatus() then
            self.clearSkillUpdatedStatusSkillData = skillData
            self.clearSkillUpdatedStatusCallId = zo_callLater(self.trySetClearUpdatedAbilityFlagCallback, TIME_NEW_PERSISTS_WHILE_SELECTED)
        else
            self.clearSkillUpdatedStatusCallId = nil
        end
    else
        self.clearSkillUpdatedStatusCallId = nil
    end
end

function ZO_GamepadSkills:OnSelectedSkillLineChanged(selectedData)
    self.selectedTooltipRefreshGroup:MarkDirty("Full")
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.categoryKeybindStripDescriptor)

    self:TryClearSkillLineNewStatus()

    if selectedData and not self.assignableActionBar:IsActive() then
        local skillLineData = selectedData.skillLineData
        if skillLineData and skillLineData:IsSkillLineOrAbilitiesNew() then
            self.clearSkillLineNewStatusSkillLineData = skillLineData
            self.clearSkillLineNewStatusCallId = zo_callLater(self.trySetClearNewSkillLineFlagCallback, TIME_NEW_PERSISTS_WHILE_SELECTED)
        else
            self.clearSkillLineNewStatusCallId = nil
        end
    else
        self.clearSkillLineNewStatusCallId = nil
    end
end

function ZO_GamepadSkills:RefreshSelectedTooltip()
    --don't setup tooltip til dialog is gone.
    if self.showAttributeDialog or (not GAMEPAD_SKILLS_ROOT_SCENE:IsShowing() and not GAMEPAD_SKILLS_LINE_FILTER_SCENE:IsShowing()) then
        return
    end
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    SCENE_MANAGER:RemoveFragment(SKILLS_ADVISOR_SUGGESTIONS_GAMEPAD_FRAGMENT)
    SCENE_MANAGER:RemoveFragment(GAMEPAD_SKILLS_LINE_PREVIEW_FRAGMENT)

    SCENE_MANAGER:AddFragment(GAMEPAD_LEFT_TOOLTIP_BACKGROUND_FRAGMENT)

    if self.mode == ZO_GAMEPAD_SKILLS_SKILL_LIST_BROWSE_MODE then
        local selectedData = self.categoryList:GetTargetData()
        if selectedData and self.assignableActionBar:IsActive() then
            self.assignableActionBar:LayoutOrClearSlotTooltip(GAMEPAD_LEFT_TOOLTIP)
        elseif selectedData and selectedData.isSkillsAdvisor then
            if not (ZO_SKILLS_ADVISOR_SINGLETON:GetSelectedSkillBuildId() or ZO_SKILLS_ADVISOR_SINGLETON:IsAdvancedModeSelected()) then
                -- No Skill Build yet selected
                GAMEPAD_TOOLTIPS:LayoutTitleAndMultiSectionDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, selectedData.text, GetString(SI_SKILLS_ADVISOR_GAMEPAD_DESCRIPTION))
            elseif ZO_SKILLS_ADVISOR_SINGLETON:IsAdvancedModeSelected() then
                -- Advanced Player selected
                GAMEPAD_TOOLTIPS:LayoutTitleAndMultiSectionDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, GetString(SI_SKILLS_ADVISOR_ADVANCED_PLAYER_NAME), GetString(SI_SKILLS_ADVISOR_GAMEPAD_ADVANCED_SELECTED_DESCRIPTION))
            elseif ZO_SKILLS_ADVISOR_SINGLETON:GetSelectedSkillBuildId() then
                -- Skill Build selected
                SCENE_MANAGER:AddFragment(SKILLS_ADVISOR_SUGGESTIONS_GAMEPAD_FRAGMENT)
            end
        elseif selectedData then 
            local skillLineData = selectedData.skillLineData
            if skillLineData:IsAvailable() then
                SCENE_MANAGER:AddFragment(GAMEPAD_SKILLS_LINE_PREVIEW_FRAGMENT)
            elseif skillLineData:IsAdvised() then
                GAMEPAD_TOOLTIPS:LayoutTitleAndMultiSectionDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, skillLineData:GetFormattedName(), skillLineData:GetUnlockText())
            end
        end
    elseif self.mode == ZO_GAMEPAD_SKILLS_BUILD_PLANNER_ASSIGN_MODE then
        local skillEntry = self.buildPlannerList:GetTargetData()
        if skillEntry then
            self.assignableActionBar:LayoutAssignableSkillLineAbilityTooltip(GAMEPAD_LEFT_TOOLTIP, skillEntry.skillData)
        else
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        end

        self.assignableActionBar:LayoutOrClearSlotTooltip(GAMEPAD_RIGHT_TOOLTIP)
    else
        local skillEntry = self.lineFilterList:GetTargetData()
        if skillEntry and not self.assignableActionBar:IsActive() then
            local skillData = skillEntry.skillData
            local SHOW_RANK_NEEDED_LINE = true
            local SHOW_POINT_SPEND_LINE = true
            local SHOW_ADVISED_LINE = true
            local SHOW_RESPEC_TO_FIX_BAD_MORPH_LINE = true
            --Morphs (the only actives with upgrade info) only show that info in the morph dialog tooltip. Passives show it all the time.
            local showUpgradeInfoBlock = skillData:IsPassive()
            GAMEPAD_TOOLTIPS:LayoutSkillProgression(GAMEPAD_LEFT_TOOLTIP, skillData:GetPointAllocatorProgressionData(), SHOW_RANK_NEEDED_LINE, SHOW_POINT_SPEND_LINE, SHOW_ADVISED_LINE, SHOW_RESPEC_TO_FIX_BAD_MORPH_LINE, showUpgradeInfoBlock)
            if self.mode == ZO_GAMEPAD_SKILLS_SINGLE_ABILITY_ASSIGN_MODE then
                self.assignableActionBar:LayoutOrClearSlotTooltip(GAMEPAD_RIGHT_TOOLTIP)
            end 
        elseif self.assignableActionBar:IsActive() then
            self.assignableActionBar:LayoutOrClearSlotTooltip(GAMEPAD_LEFT_TOOLTIP)
        end
    end
end

function ZO_GamepadSkills:SetMode(mode)
    self.mode = mode
    self.selectedTooltipRefreshGroup:MarkDirty("Full")
    if self.mode == ZO_GAMEPAD_SKILLS_SKILL_LIST_BROWSE_MODE then
        if self:IsCurrentList(self.categoryList) then
            if not self.assignableActionBar:IsActive() then
                self.categoryList:Activate()
            end
        else
            self:SetCurrentList(self.categoryList)
        end
    elseif self.mode == ZO_GAMEPAD_SKILLS_BUILD_PLANNER_ASSIGN_MODE then
        self.buildPlannerList:Activate()
        self.buildPlannerListRefreshGroup:MarkDirty("List")
    elseif self.mode == ZO_GAMEPAD_SKILLS_ABILITY_LIST_BROWSE_MODE then
        if self:IsCurrentList(self.lineFilterList) then
            if not self.assignableActionBar:IsActive() then
                self.lineFilterList:Activate()
            end
        else
            self:SetCurrentList(self.lineFilterList)
        end
        self.lineFilterListRefreshGroup:MarkDirty("Visible")
    elseif self.mode == ZO_GAMEPAD_SKILLS_SINGLE_ABILITY_ASSIGN_MODE then
        self:DisableCurrentList()
        self.lineFilterListRefreshGroup:MarkDirty("Visible") -- The action bar reuses line filter list keybinds, so refresh those
    end
end

function ZO_GamepadSkills:AssignSelectedBuildPlannerAbility()
    local skillEntry = self.buildPlannerList:GetTargetData()
    if skillEntry then
        self.assignableActionBar:AssignSkill(skillEntry.skillData)
    end
end

function ZO_GamepadSkills:StartSingleAbilityAssignment(skillData)
    self.assignableActionBar:SetTargetSkill(skillData)
    self.assignableActionBar:Activate()
    self.actionBarAnimation:PlayForward()
    self:SetMode(ZO_GAMEPAD_SKILLS_SINGLE_ABILITY_ASSIGN_MODE)
    self.selectedTooltipRefreshGroup:MarkDirty("Full")
end

function ZO_GamepadSkills_OnInitialize(control)
    GAMEPAD_SKILLS = ZO_GamepadSkills:New(control)
end

--[[ Skill Templates ]]--

function ZO_GamepadSkillLineXpBar_Setup(skillLineData, xpBar, nameControl, noWrap)
    local formattedName = skillLineData:GetFormattedName()
    local advised = skillLineData:IsAdvised()

    local lastXP, nextXP, currentXP = skillLineData:GetRankXPValues() 
    if advised then
        local RANK_NOT_SHOWN = 1
        local CURRENT_XP_NOT_SHOWN = 0
        ZO_SkillInfoXPBar_SetValue(xpBar, RANK_NOT_SHOWN, lastXP, nextXP, CURRENT_XP_NOT_SHOWN, noWrap)
    else
        local skillLineRank = skillLineData:GetCurrentRank()
        ZO_SkillInfoXPBar_SetValue(xpBar, skillLineRank, lastXP, nextXP, currentXP, noWrap)
    end
    if nameControl then
        nameControl:SetText(formattedName)
    end
end

function ZO_GamepadSkillLineEntryTemplate_Setup(control, skillLineEntry, selected, activated)
    local skillLineData = skillLineEntry.skillLineData
    local isTheSame = control.barContainer.xpBar.skillLineData == skillLineData
    if not isTheSame then
        control.barContainer.xpBar.skillLineData = skillLineData
        control.barContainer.xpBar:Reset()
    end

    ZO_GamepadSkillLineXpBar_Setup(skillLineData, control.barContainer.xpBar, nil, not isTheSame)

    control.barContainer:SetHidden(not selected)
end

function ZO_GamepadSkillLineEntryTemplate_OnLevelChanged(xpBar, rank)
    xpBar:GetControl():GetParent().rank:SetText(rank)
end

function ZO_GamepadSkillEntryTemplate_Setup(control, skillEntry, selected, activated, displayView)
    --Some skill entries want to target a specific progression data (such as the morph dialog showing two specific morphs). Otherwise they use the skill progression that matches the current point spending.
    local skillData = skillEntry.skillData or skillEntry.skillProgressionData:GetSkillData()
    local skillProgressionData = skillEntry.skillProgressionData or skillData:GetPointAllocatorProgressionData()
    local skillPointAllocator = skillData:GetPointAllocator()
    local isUnlocked = skillProgressionData:IsUnlocked()
    local isMorph = skillData:IsActive() and skillProgressionData:IsMorph()
    local isPurchased = skillPointAllocator:IsPurchased()
    local isInSkillBuild = skillProgressionData:IsAdvised()

    --Icon
    local iconTexture = control.icon
    if displayView == ZO_SKILL_ABILITY_DISPLAY_INTERACTIVE then
        if isPurchased then
            iconTexture:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
        else
            iconTexture:SetColor(ZO_DEFAULT_DISABLED_COLOR:UnpackRGBA())
        end
    end

    local DOUBLE_FRAME_THICKNESS = 9
    local SINGLE_FRAME_THICKNESS = 5
    --Circle Frame (Passive)
    local circleFrameTexture = control.circleFrame
    if circleFrameTexture then
        if skillData:IsPassive() then
            circleFrameTexture:SetHidden(false)
            local frameOffsetFromIcon
            if isInSkillBuild then
                frameOffsetFromIcon = DOUBLE_FRAME_THICKNESS
                circleFrameTexture:SetTexture("EsoUI/Art/SkillsAdvisor/gamepad/gp_passiveDoubleFrame_64.dds")
            else
                frameOffsetFromIcon = SINGLE_FRAME_THICKNESS
                circleFrameTexture:SetTexture("EsoUI/Art/Miscellaneous/Gamepad/gp_passiveFrame_64.dds")
            end
            circleFrameTexture:ClearAnchors()
            circleFrameTexture:SetAnchor(TOPLEFT, iconTexture, TOPLEFT, -frameOffsetFromIcon, -frameOffsetFromIcon)
            circleFrameTexture:SetAnchor(BOTTOMRIGHT, iconTexture, BOTTOMRIGHT, frameOffsetFromIcon, frameOffsetFromIcon)
        else
            control.circleFrame:SetHidden(true)
        end
    end

    --Edge Frame (Active)
    local SKILLS_ADVISOR_ACTIVE_DOUBLE_FRAME_WIDTH = 128
    local SKILLS_ADVISOR_ACTIVE_DOUBLE_FRAME_HEIGHT = 16
    local edgeFrameBackdrop = control.edgeFrame
    if skillData:IsActive() then
        edgeFrameBackdrop:SetHidden(false)
        local frameOffsetFromIcon
        if isInSkillBuild then 
            frameOffsetFromIcon = DOUBLE_FRAME_THICKNESS
            edgeFrameBackdrop:SetEdgeTexture("EsoUI/Art/SkillsAdvisor/gamepad/edgeDoubleframeGamepadBorder.dds", SKILLS_ADVISOR_ACTIVE_DOUBLE_FRAME_WIDTH, SKILLS_ADVISOR_ACTIVE_DOUBLE_FRAME_HEIGHT)
        else
            frameOffsetFromIcon = SINGLE_FRAME_THICKNESS
            edgeFrameBackdrop:SetEdgeTexture("EsoUI/Art/Miscellaneous/Gamepad/edgeframeGamepadBorder.dds", SKILLS_ADVISOR_ACTIVE_DOUBLE_FRAME_WIDTH, SKILLS_ADVISOR_ACTIVE_DOUBLE_FRAME_HEIGHT)
        end
        edgeFrameBackdrop:SetAnchor(TOPLEFT, iconTexture, TOPLEFT, -frameOffsetFromIcon, -frameOffsetFromIcon)
        edgeFrameBackdrop:SetAnchor(BOTTOMRIGHT, iconTexture, BOTTOMRIGHT, frameOffsetFromIcon, frameOffsetFromIcon)
    else
        edgeFrameBackdrop:SetHidden(true)
    end

    --Label Color
    if displayView == ZO_SKILL_ABILITY_DISPLAY_INTERACTIVE then
        if not skillEntry.isPreview and isPurchased then
            control.label:SetColor((selected and PURCHASED_COLOR or PURCHASED_UNSELECTED_COLOR):UnpackRGBA())
        end
    else
        control.label:SetColor(PURCHASED_COLOR:UnpackRGBA())
    end    

    --Lock Icon
    if control.lock then
        control.lock:SetHidden(isUnlocked)
    end

    local leftIndicator = control.leftIndicator
    local rightIndicator = control.rightIndicator
    local increaseMultiIcon
    local decreaseMultiIcon
    local hasIndicators = leftIndicator ~= nil
    if hasIndicators then
        increaseMultiIcon = SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() and rightIndicator or leftIndicator
        decreaseMultiIcon = increaseMultiIcon == rightIndicator and leftIndicator or rightIndicator
        leftIndicator:ClearIcons()
        rightIndicator:ClearIcons()

        --Increase (Morph, Purchase, Increase Rank) Icon
        if displayView == ZO_SKILL_ABILITY_DISPLAY_VIEW then
            if isMorph then
                increaseMultiIcon:AddIcon(POINT_ACTION_TEXTURES[ACTION_MORPH])
            end
        else
            if skillPointAllocator:CanPurchase() then
                increaseMultiIcon:AddIcon(POINT_ACTION_TEXTURES[ACTION_PURCHASE])
            elseif skillPointAllocator:CanMorph() then
                if isMorph then
                    increaseMultiIcon:AddIcon(POINT_ACTION_TEXTURES[ACTION_REMORPH])
                else
                    increaseMultiIcon:AddIcon(POINT_ACTION_TEXTURES[ACTION_MORPH])
                end
            elseif skillPointAllocator:CanIncreaseRank() then
                increaseMultiIcon:AddIcon(POINT_ACTION_TEXTURES[ACTION_PURCHASE])
            end
        end

        --New Indicator
        if displayView == ZO_SKILL_ABILITY_DISPLAY_INTERACTIVE then
            if skillData:HasUpdatedStatus() then
                control.leftIndicator:AddIcon("EsoUI/Art/Inventory/newItem_icon.dds")
            end
        end
    end
    
    local labelWidth = 289
    if displayView == ZO_SKILL_ABILITY_DISPLAY_INTERACTIVE then
        --Decrease (Unmorph, Sell, Decrease Rank)
        if hasIndicators then
            local decreaseTextureFile
            decreaseMultiIcon:ClearIcons()

            if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeAllowDecrease() then                
                if skillPointAllocator:CanSell() then
                    decreaseTextureFile = POINT_ACTION_TEXTURES[ACTION_SELL]
                elseif skillPointAllocator:CanUnmorph() then
                    decreaseTextureFile = POINT_ACTION_TEXTURES[ACTION_UNMORPH]
                elseif skillPointAllocator:CanDecreaseRank() then
                    decreaseTextureFile = POINT_ACTION_TEXTURES[ACTION_DECREASE_RANK]
                end

                --Always carve out space for the decrease icon even if it isn't active so the name doesn't dance around as it appears and disappears
                labelWidth = labelWidth - 40
            end
            
            if decreaseTextureFile then
                decreaseMultiIcon:AddIcon(decreaseTextureFile)
            end
        end

        --Current Binding Text
        if control.keybind then
            local hasBinding = false

            --The spot where the keybind goes is occupied by the decrease button in the respec modes
            if SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode() == SKILL_POINT_ALLOCATION_MODE_PURCHASE_ONLY and skillData:IsActive() then
                local slot = skillData:GetSlotOnCurrentHotbar()
                if slot then
                    hasBinding = true
                    local bindingText = ZO_Keybindings_GetHighestPriorityBindingStringFromAction("GAMEPAD_ACTION_BUTTON_".. slot, KEYBIND_TEXT_OPTIONS_FULL_NAME, KEYBIND_TEXTURE_OPTIONS_EMBED_MARKUP, true)                    
                    local layerIndex, categoryIndex, actionIndex = GetActionIndicesFromName("GAMEPAD_ACTION_BUTTON_".. slot)
                    if layerIndex then
                        local key = GetActionBindingInfo(layerIndex, categoryIndex, actionIndex, 1)
                        if IsKeyCodeChordKey(key) then 
                            labelWidth = labelWidth - 90   --width minus double keybind width (RB+LB)
                        else
                            labelWidth = labelWidth - 50   --width minus single keybind
                        end
                    end
                    control.keybind:SetText(bindingText)
                end
            end

            if hasBinding then
                control.keybind:SetHidden(false)
            else
                control.keybind:SetHidden(true)
                control.keybind:SetText("") --resizes rect for when control is reused and hidden since other controls depend on it's width
            end
        end                
    end

    if hasIndicators then
        leftIndicator:Show()
        rightIndicator:Show()
    end

    --Size the label to allow space for the keybind and decrease icon
    control.label:SetWidth(labelWidth)
end

function ZO_GamepadSkills_RespecBindingsBinding_OnInitialized(self, binding)
    ZO_KeybindButtonTemplate_OnInitialized(self)
    ApplyTemplateToControl(self, "ZO_KeybindButton_Gamepad_Template")
    local DONT_SHOW_UNBOUND = false
    local PREFER_GAMEPAD = true
    self:SetKeybind(binding, DONT_SHOW_UNBOUND, binding, PREFER_GAMEPAD)
end