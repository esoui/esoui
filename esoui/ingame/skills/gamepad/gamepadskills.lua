ZO_SKILL_ABILITY_DISPLAY_INTERACTIVE = 1
ZO_SKILL_ABILITY_DISPLAY_VIEW = 2

ZO_GAMEPAD_SKILLS_SKILL_LIST_BROWSE_MODE = 1
ZO_GAMEPAD_SKILLS_ABILITY_LIST_BROWSE_MODE = 2
ZO_GAMEPAD_SKILLS_SINGLE_ABILITY_ASSIGN_MODE = 3

-------------------------------
-- Gamepad Skills quick menu --
-------------------------------

-- This is used by the action bar to display and select from any current slottable skill, across multiple skill lines
ZO_GamepadAssignableActionBar_PlayerQuickMenu = ZO_GamepadAssignableActionBar_QuickMenu_Base:Subclass()

function ZO_GamepadAssignableActionBar_PlayerQuickMenu:SetupListTemplates()
    local function MenuAbilityEntryTemplateSetup(control, skillEntry, selected, reselectingDuringRebuild, enabled, activated)
        ZO_GamepadSkillEntryTemplate_SetEntryInfoFromAllocator(skillEntry)
        ZO_SharedGamepadEntry_OnSetup(control, skillEntry, selected, reselectingDuringRebuild, enabled, activated)
        ZO_GamepadSkillEntryTemplate_Setup(control, skillEntry, selected, activated, ZO_SKILL_ABILITY_DISPLAY_INTERACTIVE)
    end

    local function MenuEntryHeaderTemplateSetup(control, skillEntry, selected, selectedDuringRebuild, enabled, activated)
        control.header:SetText(skillEntry:GetHeader())
        local skillData = skillEntry.skillData
        control.skillRankHeader:SetText(skillData:GetSkillLineData():GetCurrentRank())
    end

    local function IsSkillEqual(leftSkillEntry, rightSkillEntry)
        return leftSkillEntry.skillData == rightSkillEntry.skillData
    end

    self.list:AddDataTemplate("ZO_GamepadSimpleAbilityEntryTemplate", MenuAbilityEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, IsSkillEqual)
    self.list:AddDataTemplateWithHeader("ZO_GamepadSimpleAbilityEntryTemplate", MenuAbilityEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, IsSkillEqual, "ZO_GamepadSimpleAbilityEntryHeaderTemplate", MenuEntryHeaderTemplateSetup)
end

do
    local function IsSkillPurchased(skillData)
        return skillData:GetPointAllocator():IsPurchased()
    end
    local function IsSkillNormalActive(skillData)
        return skillData:IsActive() and not skillData:IsUltimate()
    end
    local function IsSkillUltimate(skillData)
        return skillData:IsUltimate()
    end
    local function IsSkillVisible(skillData)
        return not skillData:IsHidden()
    end
    function ZO_GamepadAssignableActionBar_PlayerQuickMenu:ForEachSlottableSkill(visitor)
        local skillLineFilters = { ZO_SkillLineData.IsAvailable }
        if ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbarCategory() == HOTBAR_CATEGORY_WEREWOLF then
            table.insert(skillLineFilters, ZO_SkillLineData.IsWerewolf)
        end

        local shouldShowUltimateSkills = self.assignableActionBar:IsUltimateSelected()
        local skillDataFilters = { IsSkillPurchased, shouldShowUltimateSkills and IsSkillUltimate or IsSkillNormalActive, IsSkillVisible }

        for _, skillTypeData in SKILLS_DATA_MANAGER:SkillTypeIterator() do
            for _, skillLineData in skillTypeData:SkillLineIterator(skillLineFilters) do
                for _, skillData in skillLineData:SkillIterator(skillDataFilters) do
                    visitor(skillTypeData, skillLineData, skillData)
                end
            end
        end
    end
end

--------------------
-- Gamepad Skills --
--------------------

ZO_GamepadSkills = ZO_Gamepad_ParametricList_Screen:Subclass()

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
            KEYBIND_STRIP:AddKeybindButtonGroup(self.categoryKeybindStripDescriptor)

            local previousSceneName = SCENE_MANAGER:GetPreviousSceneName()
            if self.returnToAdvisor then
                if previousSceneName == "gamepad_skills_line_filter" then
                    -- second entry is always the skills advisor
                    self.categoryList:SetSelectedIndexWithoutAnimation(2)
                    self:DeactivateCurrentList()
                    ZO_GAMEPAD_SKILLS_ADVISOR_SUGGESTIONS_WINDOW:Activate()
                end
                self.returnToAdvisor = false
            elseif self.selectSkillData then
                if previousSceneName == "gamepad_skills_scribing_library_root" then
                    -- first entry is always scribing
                    self.categoryList:SetSelectedIndexWithoutAnimation(1)
                end
            end

            TriggerTutorial(TUTORIAL_TRIGGER_COMBAT_SKILLS_OPENED)
            TriggerTutorial(TUTORIAL_TRIGGER_SKILLS_SKILL_STYLING)

            if self.selectSkillLineBySkillDataOnInitialize then
                self:SelectSkillLineBySkillData(self.selectSkillLineBySkillDataOnInitialize)
                self.selectSkillLineBySkillDataOnInitialize = nil
            elseif self.showAttributeDialog and not self.selectSkillData then
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
            if self.selectSkillData then
                self.categoryListRefreshGroup:MarkDirty("List")
            end
        end
    end)

    GAMEPAD_SKILLS_SCENE_GROUP = ZO_SceneGroup:New("gamepad_skills_root", "gamepad_skills_line_filter")
    GAMEPAD_SKILLS_SCENE_GROUP:RegisterCallback("StateChange", function(_, newState)
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

    self:InitializeOptionsDialog()
end

function ZO_GamepadSkills.OnConfirmHideScene(scene, nextSceneName, bypassHideSceneConfirmationReason)
    if bypassHideSceneConfirmationReason == nil and 
        SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() and
        (nextSceneName == "gamepad_skills_scribing_library_root" or 
            not GAMEPAD_SKILLS_SCENE_GROUP:HasScene(nextSceneName)) then
        
        ZO_Dialogs_ShowGamepadDialog("CONFIRM_REVERT_CHANGES",
        {
            confirmCallback = function() 
                scene:AcceptHideScene()
                SKILLS_DATA_MANAGER:RebuildSkillsData()
                ACTION_BAR_ASSIGNMENT_MANAGER:ResetPlayerHotbars()
                SKILLS_AND_ACTION_BAR_MANAGER:ResetInterface()
            end,
            declineCallback = function() scene:RejectHideScene() end,
        })        
    else
        scene:AcceptHideScene()
    end
end

function ZO_GamepadSkills:OnPlayerDeactivated()
    --If we are deactivated we might be jumping somewhere else. We also might be in the respec interaction which will not be valid when we get where we are going. So just clear out the respec here.
    if GAMEPAD_SKILLS_SCENE_GROUP:IsShowing() and SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
        SCENE_MANAGER:RequestShowLeaderBaseScene(ZO_BHSCR_SKILLS_PLAYER_DEACTIVATED)
    end
end

function ZO_GamepadSkills:PerformUpdate()
    -- Include update functionality here if the screen uses self.dirty to track needing to update
    self.dirty = false
end

--TODO: Because we do not associate the parametric list screen with a scene/fragment/scene group, we need to override the ZO_Gamepad_ParametricList_Screen.IsShowing function to make sure it returns the proper thing
--We cannot assign a scene to this screen because there are two separate scenes that are managing the state change functionality. At some point, we should refactor this screen so we don't need to do this anymore
function ZO_GamepadSkills:IsShowing()
    return GAMEPAD_SKILLS_ROOT_SCENE:IsShowing() or GAMEPAD_SKILLS_LINE_FILTER_SCENE:IsShowing() or GAMEPAD_SKILLS_SCRIBING_LIBRARY_ROOT_SCENE:IsShowing()
end

function ZO_GamepadSkills:PerformDeferredInitialization()
    if self.fullyInitialized then return end
    self.fullyInitialized = true

    self:InitializeHeader()
    self:InitializeAssignableActionBar()
    self:InitializeCategoryList()
    self:InitializeLineFilterList()
    self:InitializeMorphDialog()
    self:InitializeChangeSkillStyleDialog()
    self:InitializePurchaseAndUpgradeDialog()
    self:InitializeAttributeDialog()
    self:InitializeRespecConfirmationGoldDialog()
    self:InitializeConfirmClearAllDialog()
    self:InitializeQuickMenu()
    self:InitializeCategoryKeybindStrip()
    self:InitializeLineFilterKeybindStrip()

    self:InitializeRefreshGroups()
    self:InitializeEvents()

    self:RefreshPointsDisplay()
    self:RefreshRespecModeBindingsDisplay()
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
        if not (categoryEntry.isSkillsAdvisor or categoryEntry.isScribeLibrary) then
            if categoryEntry.skillLineData == skillLineData then
                return i
            end
        end
    end
end

function ZO_GamepadSkills:SelectSkillLineBySkillData(skillData, returnToSkillsAdvisor)
    if not self.fullyInitialized or not self:IsShowing() then
        self.selectSkillLineBySkillDataOnInitialize = skillData
        return
    end

    if skillData then
        self.returnToAdvisor = returnToSkillsAdvisor
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
            if self.returnToAdvisor then
                ZO_GAMEPAD_SKILLS_ADVISOR_SUGGESTIONS_WINDOW:SetSelectSkillData(skillData)
                skillLineData:SetAdvised(true)
            end
            self:SetCurrentList(self.categoryList)
        end
    end
end

function ZO_GamepadSkills:InitializeCategoryKeybindStrip()
    table.insert(self.categoryKeybindStripDescriptor,
    {
        name = function() --name
            local targetData = self.categoryList:GetTargetData()
            if self.assignableActionBar:IsActive() then
                return GetString(SI_GAMEPAD_SKILLS_BUILD_PLANNER)
            elseif targetData and targetData.isScribeLibrary and not SCRIBING_DATA_MANAGER:IsScribingUnlocked() then
                local collectibleData = SCRIBING_DATA_MANAGER:GetScribingPurchasableCollectibleData()
                if collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_CHAPTER) then
                    return GetString(SI_SCRIBING_ACTION_UPGRADE)
                else
                    return GetString(SI_GAMEPAD_DLC_BOOK_ACTION_OPEN_CROWN_STORE)
                end
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
                self.selectedTooltipRefreshGroup:MarkDirty("Full")
                self.quickMenu:Show()
                PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
            elseif targetData and targetData.isSkillsAdvisor then
                self:DeactivateCurrentList()
                if ZO_SKILLS_ADVISOR_SINGLETON:GetSelectedSkillBuildId() then
                    ZO_GAMEPAD_SKILLS_ADVISOR_SUGGESTIONS_WINDOW:Activate()
                else
                    SCENE_MANAGER:Push("gamepad_skills_advisor_build_selection_root")
                end
            elseif targetData and targetData.isScribeLibrary then
                if SCRIBING_DATA_MANAGER:IsScribingUnlocked() then
                    SCENE_MANAGER:Push("gamepad_skills_scribing_library_root")
                else
                    local collectibleData = SCRIBING_DATA_MANAGER:GetScribingPurchasableCollectibleData()
                    if collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_CHAPTER) then
                        ZO_ShowChapterUpgradePlatformScreen(MARKET_OPEN_OPERATION_COLLECTIONS_DLC)
                    else
                        local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, collectibleData:GetName())
                        ShowMarketAndSearch(searchTerm, MARKET_OPEN_OPERATION_COLLECTIONS_DLC)
                    end
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
    local function IsActionBarEditable()
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

        enabled = IsActionBarEditable,

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

    table.insert(self.lineFilterKeybindStripDescriptor,
    {
        name = GetString(SI_SKILL_STYLE_GAMEPAD_CHANGE_STYLE),

        keybind = "UI_SHORTCUT_QUATERNARY",

        visible = function()
            if self.mode ~= ZO_GAMEPAD_SKILLS_ABILITY_LIST_BROWSE_MODE or self.assignableActionBar:IsActive() then
                return false
            end

            local skillEntry = self.lineFilterList:GetTargetData()
            if skillEntry then
                local skillData = skillEntry.skillData
                local skillPointAllocator = skillData:GetPointAllocator()
                local skillProgressionData = skillPointAllocator:GetProgressionData()
                return skillData:IsActive() and skillProgressionData:HasAnyNonHiddenSkillStyles()
            end
        end,

        callback = function()
            local skillEntry = self.lineFilterList:GetTargetData()
            if skillEntry then
                local skillData = skillEntry.skillData
                ZO_Dialogs_ShowGamepadDialog("GAMEPAD_SKILL_STYLE_SELECTION", { skillData = skillEntry.skillData })
            end
        end,
    })

    table.insert(self.lineFilterKeybindStripDescriptor,
    {
        name = GetString(SI_GAMEPAD_OPTIONS_MENU),

        keybind = "UI_SHORTCUT_QUINARY",

        callback = function()
            local skillEntry = self.lineFilterList:GetTargetData()
            if skillEntry then
                ZO_Dialogs_ShowPlatformDialog("SKILLS_OPTIONS_DIALOG_GAMEPAD", { skillData = skillEntry.skillData })
            end
        end,
    })

    local function IsInSkillPointAllocationMode()
        return not (self.mode == ZO_GAMEPAD_SKILLS_SINGLE_ABILITY_ASSIGN_MODE or self.assignableActionBar:IsActive())
    end

    local function IncreaseSkillKeybindName()
        local skillEntry = self.lineFilterList:GetTargetData()
        local actionType = skillEntry.skillData:GetPointAllocator():GetIncreaseSkillAction()
        if actionType == ZO_SKILL_POINT_ACTION.PURCHASE or actionType == ZO_SKILL_POINT_ACTION.INCREASE_RANK then
            return GetString(SI_GAMEPAD_SKILLS_PURCHASE)
        elseif actionType == ZO_SKILL_POINT_ACTION.MORPH or actionType == ZO_SKILL_POINT_ACTION.REMORPH then
            return GetString(SI_GAMEPAD_SKILLS_MORPH)
        end
    end

    local function IncreaseSkillKeybindVisible()
        local skillEntry = self.lineFilterList:GetTargetData()
        if skillEntry then
            return skillEntry.skillData:GetPointAllocator():GetIncreaseSkillAction() ~= ZO_SKILL_POINT_ACTION.NONE
        else
            return false
        end
    end

    local function IncreaseSkillKeybindCallback()
        local skillEntry = self.lineFilterList:GetTargetData()
        local skillData = skillEntry.skillData
        local skillProgressionData = skillData:GetPointAllocatorProgressionData()

        local actionType = skillData:GetPointAllocator():GetIncreaseSkillAction()
        local availablePoints = GetAvailableSkillPoints()

        local name = skillProgressionData:GetFormattedNameWithRank()

        if actionType == ZO_SKILL_POINT_ACTION.PURCHASE then
            if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeConfirmOnPurchase() then
                local labelData = { titleParams = { availablePoints }, mainTextParams = { name } }
                local dialogData = { purchaseSkillProgressionData = skillProgressionData, }

                ZO_Dialogs_ShowGamepadDialog("GAMEPAD_SKILLS_PURCHASE_CONFIRMATION", dialogData, labelData)
            else
                skillData:GetPointAllocator():Purchase()
            end
        elseif actionType == ZO_SKILL_POINT_ACTION.INCREASE_RANK then
            if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeConfirmOnIncreaseRank() then
                local labelData = { titleParams = { availablePoints }, mainTextParams = { name } }
                local dialogData = { currentSkillProgressionData = skillProgressionData }

                ZO_Dialogs_ShowGamepadDialog("GAMEPAD_SKILLS_UPGRADE_CONFIRMATION", dialogData, labelData)
            else
                skillData:GetPointAllocator():IncreaseRank()
            end
        elseif actionType == ZO_SKILL_POINT_ACTION.MORPH or actionType == ZO_SKILL_POINT_ACTION.REMORPH then
            local morphSkillData = skillProgressionData:GetSkillData()
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
            local skillPointAllocator = skillData:GetPointAllocator()
            local actionType = skillPointAllocator:GetDecreaseSkillAction()
            if actionType ~= ZO_SKILL_POINT_ACTION.NONE then
                return true
            elseif SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode() == SKILL_POINT_ALLOCATION_MODE_MORPHS_ONLY and skillData:IsActive() then
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

        local actionType = skillPointAllocator:GetDecreaseSkillAction()

        if actionType == ZO_SKILL_POINT_ACTION.SELL then
            skillPointAllocator:Sell()
        elseif actionType == ZO_SKILL_POINT_ACTION.DECREASE_RANK then
            skillPointAllocator:DecreaseRank()
        elseif actionType == ZO_SKILL_POINT_ACTION.UNMORPH then
            skillPointAllocator:Unmorph()
        end
    end

    --Decrease Skill Bind
    table.insert(self.lineFilterKeybindStripDescriptor,
    {
        name = function()
            local skillEntry = self.lineFilterList:GetTargetData()
            local action = skillEntry.skillData:GetPointAllocator():GetDecreaseSkillAction()
            return zo_iconFormat(ZO_Skills_GetGamepadSkillPointActionIcon(action), "100%", "100%")
        end,

        narrationOverrideName = function()
            local skillEntry = self.lineFilterList:GetTargetData()
            local action = skillEntry.skillData:GetPointAllocator():GetDecreaseSkillAction()
            return ZO_Skills_GetGamepadSkillPointActionIconNarrationText(action)
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
            local action = skillEntry.skillData:GetPointAllocator():GetIncreaseSkillAction()
            return zo_iconFormat(ZO_Skills_GetGamepadSkillPointActionIcon(action), "100%", "100%")
        end,

        narrationOverrideName = function()
            local skillEntry = self.lineFilterList:GetTargetData()
            local action = skillEntry.skillData:GetPointAllocator():GetIncreaseSkillAction()
            return ZO_Skills_GetGamepadSkillPointActionIconNarrationText(action)
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

        enabled = function()
            local canEdit, lockText = IsActionBarEditable()
            if not canEdit then
                return false, lockText
            end
            if self.assignableActionBar:IsActive() then
                local slotIndex = self.assignableActionBar:GetSelectedSlotIndex()
                local result = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar():GetExpectedSlotEditResult(slotIndex)
                if result ~= HOT_BAR_RESULT_SUCCESS then
                    return false, GetString("SI_HOTBARRESULT", result)
                end
            end
            return true
        end,

        callback = function()
            if self.mode == ZO_GAMEPAD_SKILLS_SINGLE_ABILITY_ASSIGN_MODE then
                self:DeactivateCurrentList()
                self.assignableActionBar:AssignTargetSkill()
                self.actionBarAnimation:PlayBackward()
                GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
                PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
                --Don't set mode back to ZO_GAMEPAD_SKILLS_ABILITY_LIST_BROWSE_MODE til OnAbilityFinalizedCallback says everything worked
            elseif self.assignableActionBar:IsActive() then
                self.quickMenu:Show()
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
            local previousSceneName = SCENE_MANAGER:GetPreviousSceneName()
            if previousSceneName == "gamepad_skills_scribing_library_root" then
                ZO_GAMEPAD_SCRIBING_CRAFTED_ABILITY_SKILLS:SetToAutoActivate()
            end
            SCENE_MANAGER:HideCurrentScene()
        end
    end)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.lineFilterKeybindStripDescriptor, self.lineFilterList, IsEntryHeader)
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
    local actionBarControl = self.header:GetNamedChild("AssignableActionBar")
    local actionBarBg = self.control:GetNamedChild("Bg")
    actionBarBg:SetAnchor(TOPLEFT, actionBarControl, TOPLEFT, 0, -12)
    actionBarBg:SetAnchor(BOTTOMRIGHT, actionBarControl, BOTTOMRIGHT, 0, 30)

    self.assignableActionBar = ZO_AssignableActionBar:New(actionBarControl)
    self:SetupHeaderFocus(self.assignableActionBar)

    self.actionBarAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_GamepadSkillsActionBarFocusAnimation")

    self.actionBarAnimation:GetAnimation(1):SetAnimatedControl(actionBarControl)
    self.actionBarAnimation:GetAnimation(2):SetAnimatedControl(actionBarBg)

    self.actionBarAnimation:PlayInstantlyToStart()
    --Narration info for the action bar
    local narrationInfo =
    {
        canNarrate = function()
            return GAMEPAD_SKILLS_SCENE_GROUP:IsShowing() and self.assignableActionBar:IsActive()
        end,
        selectedNarrationFunction = function()
            return self.assignableActionBar:GetNarrationText()
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("skillAssignableActionBar", narrationInfo)
end

function ZO_GamepadSkills:ActivateAssignableActionBarFromList()
    --Only activate the action bar if it is showing. You could start moving toward it being selected and then close the window
    --before selection happens, then the selection happens when the window is closed an the bar activates (ESO-490544).
    if not self.assignableActionBar:GetControl():IsHidden() then
        self.assignableActionBar:SelectMostRecentlySelectedButton()
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
    self.quickMenu:RefreshKeybinds()
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
        list:SetHandleDynamicViewProperties(true)

        list:AddDataTemplate("ZO_GamepadSkillLineEntryTemplate", SkillLineEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, AreSkillLineEntriesEqual)
        list:AddDataTemplateWithHeader("ZO_GamepadSkillLineEntryTemplate", SkillLineEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, AreSkillLineEntriesEqual, "ZO_GamepadMenuEntryHeaderTemplate")
        list:AddDataTemplate("ZO_GamepadMenuEntryTemplate", MenuEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    end

    self.categoryList = self:AddList("Category", SetupCategoryList)

    self.categoryList:SetOnSelectedDataChangedCallback(
    function(_, selectedData)
        self:OnSelectedSkillLineChanged(selectedData)
    end)

    self.initialCategoryListIndex = 2
end

function ZO_GamepadSkills:InitializeLineFilterList()
    local function MenuAbilityEntryTemplateSetup(control, skillEntry, selected, reselectingDuringRebuild, enabled, activated)
        ZO_GamepadSkillEntryTemplate_SetEntryInfoFromAllocator(skillEntry)
        ZO_SharedGamepadEntry_OnSetup(control, skillEntry, selected, reselectingDuringRebuild, enabled, activated)
        ZO_GamepadSkillEntryTemplate_Setup(control, skillEntry, selected, activated, ZO_SKILL_ABILITY_DISPLAY_INTERACTIVE)
    end

    local function IsSkillEqual(leftSkillEntry, rightSkillEntry)
        return leftSkillEntry.skillData == rightSkillEntry.skillData
    end

    local function SetupLineFilterList(list)
        list:SetHandleDynamicViewProperties(true)
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

function ZO_GamepadSkills:InitializeQuickMenu()
    local quickMenuControl = self.control:GetNamedChild("QuickMenu")
    self.quickMenu = ZO_GamepadAssignableActionBar_PlayerQuickMenu:New(quickMenuControl, self.assignableActionBar)

    local X_OFFSET = 30
    local Y_OFFSET = 15
    local quickMenuList = self.quickMenu:GetListControl()
    quickMenuList:ClearAnchors()
    quickMenuList:SetAnchor(TOPLEFT, self.header, BOTTOMLEFT, -X_OFFSET, Y_OFFSET)
    quickMenuList:SetAnchor(BOTTOMRIGHT, self.control, BOTTOMRIGHT, X_OFFSET, 0)
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

    --Build Planner List
    local quickMenuRefreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_PER_FRAME)
    quickMenuRefreshGroup:AddDirtyState("List", function()
        self.quickMenu:RefreshList()
    end)
    quickMenuRefreshGroup:AddDirtyState("Visible", function()
        self.quickMenu:RefreshVisible()
    end)
    quickMenuRefreshGroup:SetActive(function()
        return self.quickMenu:IsShowing()
    end)
    self.quickMenuRefreshGroup = quickMenuRefreshGroup

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
    --buildPlannerList (RefreshQuickMenuList)
    --Selected Tooltip (RefreshSelectedTooltip)
    --Points Display (RefreshPointsDisplay)

    local function FullRebuild()
        self.categoryListRefreshGroup:MarkDirty("List")
        self.lineFilterListRefreshGroup:MarkDirty("List")
        self.quickMenuRefreshGroup:MarkDirty("List")
        self:RefreshPointsDisplay()
        self.selectedTooltipRefreshGroup:MarkDirty("Full")
    end

    local function OnSkillLineUpdated(skillLineData)
        --For the skill line rank on each entry and the skill line XP bar on the selected entry
        self.categoryListRefreshGroup:MarkDirty("Visible")
        --For the locked/unlocked display on a skill
        self.lineFilterListRefreshGroup:MarkDirty("Visible", skillLineData)
        --For the skill line rank in the header of each section
        self.quickMenuRefreshGroup:MarkDirty("Visible")
        self.selectedTooltipRefreshGroup:MarkDirty("Full")
    end

    local function OnSkillLineAdded(skillLineData)
        --To add the new skill line to the list
        self.categoryListRefreshGroup:MarkDirty("List")
        --To add the skills in the new skill line to the combined planner list
        self.quickMenuRefreshGroup:MarkDirty("List")
        self.selectedTooltipRefreshGroup:MarkDirty("Full")
    end

    local function OnSkillProgressionUpdated(skillData)
        local skillLineData = skillData:GetSkillLineData()
        --For the name of an active skill entry
        self.lineFilterListRefreshGroup:MarkDirty("Visible", skillLineData)
        --For the name of an active skill entry
        self.quickMenuRefreshGroup:MarkDirty("Visible")
        self.selectedTooltipRefreshGroup:MarkDirty("Full")
    end

    local function OnPointAllocatorPurchasedChanged(skillPointAllocator)
        local skillLineData = skillPointAllocator:GetSkillData():GetSkillLineData()
        --For the number of allocated points after the skill line name
        self.categoryListRefreshGroup:MarkDirty("Visible")
        --For the purchased state and name of skills
        self.lineFilterListRefreshGroup:MarkDirty("Visible", skillLineData)
        --To add or remove skills from the combined planner list
        self.quickMenuRefreshGroup:MarkDirty("List")
        self.selectedTooltipRefreshGroup:MarkDirty("Full")
    end

    local function OnPointAllocatorProgressionKeyChanged(skillPointAllocator)
        local skillLineData = skillPointAllocator:GetSkillData():GetSkillLineData()
        --For the number of allocated points after the skill line name
        self.categoryListRefreshGroup:MarkDirty("Visible")
        --For the name of skills
        self.lineFilterListRefreshGroup:MarkDirty("Visible", skillLineData)
        self.selectedTooltipRefreshGroup:MarkDirty("Full")
    end

    local function OnSkillsCleared(skillLineData)
        --Skill Line Data is only defined if a single skill line was cleared
        --For the number of allocated points after the skill line name
        self.categoryListRefreshGroup:MarkDirty("Visible")
        --For the purchased state and name of skills
        self.lineFilterListRefreshGroup:MarkDirty("Visible", skillLineData)
        --To add or remove skills from the combined planner list
        self.quickMenuRefreshGroup:MarkDirty("List")
        self.selectedTooltipRefreshGroup:MarkDirty("Full")
    end

    local function OnSkillPointsChanged()
        --For the number of allocated points after the skill line name
        self.categoryListRefreshGroup:MarkDirty("Visible")
        --For the point spending action icons
        self.lineFilterListRefreshGroup:MarkDirty("Visible")
        self.selectedTooltipRefreshGroup:MarkDirty("Full")
        self:RefreshPointsDisplay()
    end

    local function OnSkillPointAllocationModeChanged()
        --For the number of allocated points after the skill line name
        self.categoryListRefreshGroup:MarkDirty("Visible")
        --For the purchased state and name of skills
        self.lineFilterListRefreshGroup:MarkDirty("Visible")
        --To add or remove skills from the combined planner list
        self.quickMenuRefreshGroup:MarkDirty("List")
        --For the number of used skill points changing
        self:RefreshPointsDisplay()
        --To show or hide the respec mode bindings
        self:RefreshRespecModeBindingsDisplay()
        --To refresh showing the commit/clear all binds
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.categoryKeybindStripDescriptor)
        self.selectedTooltipRefreshGroup:MarkDirty("Full")
    end

    local function OnCurrentHotbarUpdated()
        --To refresh tooltip if an action slot is selected
        self.selectedTooltipRefreshGroup:MarkDirty("Full")
        --Re-narrate when the current hotbar changes (if active)
        if self.assignableActionBar:IsActive() then
            SCREEN_NARRATION_MANAGER:QueueCustomEntry("skillAssignableActionBar")
        end
    end

    local function OnCollectionUpdated(collectionUpdateType, collectiblesByNewUnlockState)
        local scribingCollectibleData = SCRIBING_DATA_MANAGER:GetScribingUnlockCollectibleData()
        for _, unlockStateTable in pairs(collectiblesByNewUnlockState) do
            for _, collectibleData in ipairs(unlockStateTable) do
                if collectibleData == scribingCollectibleData then
                    FullRebuild()
                end
            end
        end
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
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", OnCollectionUpdated)

    --Weapon Swap
    local function OnHotbarSwapVisibleStateChanged()
        if not self.control:IsHidden() then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.categoryKeybindStripDescriptor)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.lineFilterKeybindStripDescriptor)
        end
    end
    ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("HotbarSwapVisibleStateChanged", OnHotbarSwapVisibleStateChanged)

    self.control:RegisterForEvent(EVENT_PLAYER_DEACTIVATED, function() self:OnPlayerDeactivated() end)

    local function OnPurchaseLockStateChanged()
        -- Refresh state of purchase/morph/assign keybinds
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.lineFilterKeybindStripDescriptor)
    end
    self.control:RegisterForEvent(EVENT_ACTION_BAR_LOCKED_REASON_CHANGED, OnPurchaseLockStateChanged)

    --action bar
    local function OnAbilityFinalized()
        if self.mode == ZO_GAMEPAD_SKILLS_SINGLE_ABILITY_ASSIGN_MODE then
            self.assignableActionBar:ClearTargetSkill()
            -- make sur eto deactivate the action bar before changing mode
            -- so the list can be fully activated when we switch to it
            self.assignableActionBar:Deactivate()
            self:SetMode(ZO_GAMEPAD_SKILLS_ABILITY_LIST_BROWSE_MODE)
        end
    end
    self.assignableActionBar:RegisterCallback("AbilityFinalized", OnAbilityFinalized)

    local function OnSelectedActionBarButtonChanged(selectedSlotIndex, didSlotTypeChange)
        self.selectedTooltipRefreshGroup:MarkDirty("Full")
        --Re-narrate when the selected action bar slot changes
        SCREEN_NARRATION_MANAGER:QueueCustomEntry("skillAssignableActionBar")
    end
    self.assignableActionBar:RegisterCallback("SelectedButtonChanged", OnSelectedActionBarButtonChanged)
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

do
    local function SkillLineGamepadEntryProgressBarNarrationText(entryData)
        local barMax = entryData.nextRankXP
        if barMax then
            local barMin = entryData.lastRankXP or 0
            local barValue = entryData.currentXP or 0
            return ZO_GetProgressBarNarrationText(barMin, barMax, barValue)
        end
    end
    local function IsSkillLineAvailableOrAdvised(skillLineData)
        return skillLineData:IsAvailable() or skillLineData:IsAdvised()
    end
    local SKILL_LINE_FILTERS = { IsSkillLineAvailableOrAdvised }
    function ZO_GamepadSkills:RefreshCategoryList()
        self.categoryList:Clear()

        local skillLineNarrationText = function(entryData, entryControl)
            local narrations = {}
            local skillLineData = entryData.skillLineData
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_SKILLS_GAMEPAD_RANK_NARRATION)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(skillLineData.currentRank))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.text))
            ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntrySubLabelNarrationText(entryData, entryControl))
            ZO_AppendNarration(narrations, SkillLineGamepadEntryProgressBarNarrationText(skillLineData))
            ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryStackCountNarrationText(entryData, entryControl))
            ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryStatusIndicatorNarrationText(entryData, entryControl))
            return narrations
        end

        local scribeLibraryEntryData = ZO_GamepadEntryData:New(zo_strformat(SI_SKILLS_ENTRY_NAME_FORMAT, GetString(SI_SCRIBING_TITLE)))
        scribeLibraryEntryData.isScribeLibrary = true
        self.categoryList:AddEntry("ZO_GamepadMenuEntryTemplate", scribeLibraryEntryData)

        local skillsAdvisorEntryData = ZO_GamepadEntryData:New(zo_strformat(SI_SKILLS_ENTRY_NAME_FORMAT, GetString(SI_SKILLS_ADVISOR_TITLE)))
        skillsAdvisorEntryData.isSkillsAdvisor = true
        self.categoryList:AddEntry("ZO_GamepadMenuEntryTemplate", skillsAdvisorEntryData)

        for _, skillTypeData in SKILLS_DATA_MANAGER:SkillTypeIterator() do
            local isHeader = true
            for _, skillLineData in skillTypeData:SkillLineIterator(SKILL_LINE_FILTERS) do
                local function IsSkillLineNew()
                    return skillLineData:IsSkillLineOrAbilitiesNew()
                end

                local data = ZO_GamepadEntryData:New()
                data:SetNew(IsSkillLineNew)
                data.skillLineData = skillLineData
                data.narrationText = skillLineNarrationText

                if isHeader then
                    data:SetHeader(skillTypeData:GetName())  
                    self.categoryList:AddEntry("ZO_GamepadSkillLineEntryTemplateWithHeader", data)
                else
                    self.categoryList:AddEntry("ZO_GamepadSkillLineEntryTemplate", data)
                end

                isHeader = false
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
        elseif self.initialCategoryListIndex then
            self.categoryList:SetSelectedIndexWithoutAnimation(self.initialCategoryListIndex)
            self.initialCategoryListIndex = nil
        end
    end
end

do
    local g_ShownHeaderTexts = {}

    function ZO_GamepadSkills:RefreshLineFilterList()
        local list = self.lineFilterList
        list:Clear()
        ZO_ClearTable(g_ShownHeaderTexts)

        local skillLineEntry = self.categoryList:GetTargetData()
        if skillLineEntry.isSkillsAdvisor or skillLineEntry.isScribeLibrary then
            return
        end

        local function IsSkillVisible(skillData)
            return not skillData:IsHidden()
        end

        local skillLineData = skillLineEntry.skillLineData
        for _, skillData in skillLineData:SkillIterator({ IsSkillVisible }) do
            local skillEntry = ZO_GamepadEntryData:New()

            skillEntry:SetFontScaleOnSelection(false)
            skillEntry.skillData = skillData

            local headerText = skillData:GetHeaderText()
            if not g_ShownHeaderTexts[headerText] then
                skillEntry:SetHeader(headerText)
                list:AddEntry("ZO_GamepadAbilityEntryTemplateWithHeader", skillEntry)
                g_ShownHeaderTexts[headerText] = true
            else
                list:AddEntry("ZO_GamepadAbilityEntryTemplate", skillEntry)
            end
        end

        list:Commit()
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

        local skillEntry =
        {
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
                        narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
                    },
                },
                -- Morph 2
                {
                    template = "ZO_GamepadSimpleAbilityEntryTemplate",
                    templateData =
                    {
                        setup = MorphConfirmSetup,
                        morphSlot = MORPH_SLOT_MORPH_2,
                        narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
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
                GAMEPAD_TOOLTIPS:LayoutSkillProgression(GAMEPAD_LEFT_DIALOG_TOOLTIP, morphSkillProgressionData, SHOW_RANK_NEEDED_LINE, SHOW_POINT_SPEND_LINE, SHOW_ADVISED_LINE, DONT_SHOW_RESPEC_TO_FIX_BAD_MORPH_LINE, SHOW_UPGRADE_INFO_BLOCK)
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

    function ZO_GamepadSkills:InitializeChangeSkillStyleDialog()
        ZO_Dialogs_RegisterCustomDialog("GAMEPAD_SKILL_STYLE_SELECTION",
        {
            gamepadInfo =
            {
                dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            },

            setup = function(dialog)
                local progressionId = dialog.data.skillData.progressionId
                local isSkillLinePurchased = dialog.data.skillData.isPurchased
                local parametricListEntries = dialog.info.parametricList
                ZO_ClearNumericallyIndexedTable(parametricListEntries)

                local currentCollectibleId = GetActiveProgressionSkillAbilityFxOverrideCollectibleId(progressionId)

                -- Insert Default Entry
                local defaultEntryData = ZO_GamepadEntryData:New(GetString(SI_SKILL_STYLING_DEFAULT_NAME))
                defaultEntryData.setup = ZO_SharedGamepadEntry_OnSetup
                defaultEntryData:AddIcon("EsoUI/Art/Progression/Gamepad/gp_skillStyleEmpty.dds")
                defaultEntryData.collectibleId = 0
                defaultEntryData.isCurrent = currentCollectibleId == 0
                defaultEntryData:SetSelected(defaultEntryData.isCurrent)
                defaultEntryData.narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP

                local defaultListItem =
                {
                    template = "ZO_GamepadItemEntryTemplate",
                    entryData = defaultEntryData,
                }
                table.insert(parametricListEntries, defaultListItem)

                -- Insert Available Skill Styles for Progression
                for index = 1, GetNumProgressionSkillAbilityFxOverrides(progressionId) do
                    local collectibleId = GetProgressionSkillAbilityFxOverrideCollectibleIdByIndex(progressionId, index)
                    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
                    if collectibleData and not collectibleData:IsHiddenFromCollection() then
                        local entryData = ZO_GamepadEntryData:New(collectibleData:GetFormattedName())
                        entryData.setup = ZO_SharedGamepadEntry_OnSetup
                        entryData:AddIcon(collectibleData:GetIcon())
                        entryData.iconIndex = index
                        entryData.collectibleId = collectibleId
                        entryData.collectibleData = collectibleData
                        entryData.isCurrent = function()
                            return collectibleId == currentCollectibleId
                        end

                        entryData:InitializeCollectibleVisualData(collectibleData, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
                        entryData:SetEnabled(isSkillLinePurchased and collectibleData:IsUnlocked())
                        entryData:SetSelected(entryData.isCurrent())
                        entryData:SetLocked(not collectibleData:IsOwned() or not isSkillLinePurchased)
                        entryData.narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP

                        local listItem =
                        {
                            template = "ZO_GamepadItemEntryTemplate",
                            entryData = entryData,
                        }
                        table.insert(parametricListEntries, listItem)
                    end
                end

                ZO_GenericGamepadDialog_ShowTooltip(dialog)
                dialog:setupFunc()
            end,

            finishedCallback = function()
                self.lineFilterListRefreshGroup:MarkDirty("Visible")
                self.lineFilterListRefreshGroup:TryClean()
            end,

            title =
            {
                text = function(dialog)
                    local data = dialog.data
                    local skillType = data.skillData.skillLineData.skillTypeData.skillType
                    local skillLineIndex = data.skillData.skillLineData.skillLineIndex
                    local skillIndex = data.skillData.skillIndex
                    return zo_strformat(SI_SKILL_STYLING_DIALOG_TITLE, GetProgressionSkillProgressionName(skillType, skillLineIndex, skillIndex))
                end,
            },
            mainText =
            {
                text = function(dialog)
                    return SKILLS_DATA_MANAGER:GetSkillStyleWarningText(dialog.data)
                end,
            },

            parametricList = {}, -- Generated Dynamically
            parametricListOnSelectionChangedCallback = function(dialog, list)
                local targetData = dialog.entryList:GetTargetData()
                if targetData then
                    if targetData.collectibleId == 0 then
                        GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_DIALOG_TOOLTIP, GetString(SI_SKILL_STYLING_TOOLTIP_DEFAULT_TITLE), GetString(SI_SKILL_STYLING_TOOLTIP_DEFAULT_DESCRIPTION))
                    else
                        local NO_COOLDOWN = 0
                        local SHOW_VISUAL_LAYER_INFO = true
                        local SHOW_BLOCK_REASON = true
                        GAMEPAD_TOOLTIPS:LayoutCollectibleFromData(GAMEPAD_LEFT_DIALOG_TOOLTIP, targetData.collectibleData, SHOW_VISUAL_LAYER_INFO, NO_COOLDOWN, SHOW_BLOCK_REASON)
                        ZO_GenericGamepadDialog_ShowTooltip(dialog)
                    end
                else
                    ZO_GenericGamepadDialog_HideTooltip(dialog)
                end
            end,
            buttons =
            {
                {
                    keybind = "DIALOG_PRIMARY",
                    text = SI_GAMEPAD_SELECT_OPTION,
                    enabled = function(dialog)
                        local targetData = dialog.entryList:GetTargetData()
                        if targetData then
                            return targetData:IsEnabled()
                        end
                        return false
                    end,
                    callback =  function(dialog)
                        local targetData = dialog.entryList:GetTargetData()
                        if targetData then
                            local isCurrent = targetData.isCurrent
                            if type(isCurrent) == "function" then
                                isCurrent = isCurrent()
                            end
                            if targetData.collectibleData then
                                if not isCurrent then
                                    targetData.collectibleData:Use()
                                end
                            else
                                -- We selected default, unselect current collectible by using it again
                                for i = 1, dialog.entryList:GetNumEntries() do
                                    local entryData = dialog.entryList:GetEntryData(i)
                                    local isCurrent = entryData.isCurrent
                                    if type(isCurrent) == "function" then
                                        isCurrent = isCurrent()
                                    end
                                    if entryData.collectibleData and isCurrent then
                                        entryData.collectibleData:Use()
                                    end
                                end
                            end
                        end
                    end,
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
        if SKILLS_AND_ACTION_BAR_MANAGER:GetSkillRespecPaymentType() == RESPEC_PAYMENT_TYPE_GOLD then
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

    function ZO_GamepadSkills:InitializeAttributeDialog()
        self:ResetAttributeData()

        local function OnAttributeValueChanged(entryData, entryControl)
            SCREEN_NARRATION_MANAGER:QueueDialog(entryData.dialog)
        end

        local function GetAttributeNarrationText(entryData, entryControl)
            local totalPoints = entryControl.pointLimitedSpinner:GetPoints() + entryControl.pointLimitedSpinner:GetAllocatedPoints()
            return ZO_FormatSpinnerNarrationText(entryData.text, totalPoints)
        end
        
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
                        onValueChangedCallback = OnAttributeValueChanged,
                        narrationText = GetAttributeNarrationText,
                        narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
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
                        onValueChangedCallback = OnAttributeValueChanged,
                        narrationText = GetAttributeNarrationText,
                        narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
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
                        onValueChangedCallback = OnAttributeValueChanged,
                        narrationText = GetAttributeNarrationText,
                        narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
                    },
                    text = GetString("SI_ATTRIBUTES", ATTRIBUTE_STAMINA),
                    icon = "/esoui/art/characterwindow/Gamepad/gp_characterSheet_staminaIcon.dds",
                },
            },

            parametricListOnSelectionChangedCallback = function()
                self:UpdatePendingStatBonuses()
            end,

            parametricListOnActivatedChangedCallback = function(list, isActive)
                if not isActive then
                    local selectedControl = list:GetSelectedControl()
                    if selectedControl and selectedControl.pointLimitedSpinner then
                        selectedControl.pointLimitedSpinner:SetActive(false)
                    end
                else
                    list:RefreshVisible()
                end
            end,

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
                    end,
                },
                {
                    keybind = "DIALOG_NEGATIVE",
                    text = SI_GAMEPAD_BACK_OPTION,
                },
            },

            finishedCallback = function(dialog)
                --Setup Skills Scene
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
    SCENE_MANAGER:AddFragment(GAMEPAD_LEFT_TOOLTIP_BACKGROUND_FRAGMENT)

    if self.quickMenu:IsShowing() then
        self.quickMenu:RefreshTooltip()
    elseif self.mode == ZO_GAMEPAD_SKILLS_SKILL_LIST_BROWSE_MODE then
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
        elseif selectedData and selectedData.isScribeLibrary then
            local scribingTitle = GetString(SI_SCRIBING_TITLE)
            local scribingDescription = GetString(SI_SCRIBING_LIBRARY_DESCRIPTION)
            if SCRIBING_DATA_MANAGER:IsScribingUnlocked() then
                GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, scribingTitle, scribingDescription)
            else
                local lockedText = ZO_Tooltip:GetRequiredScribingCollectibleText()
                GAMEPAD_TOOLTIPS:LayoutTitleAndMultiSectionDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, scribingTitle, scribingDescription, lockedText)
            end
        elseif selectedData then
            local skillLineData = selectedData.skillLineData

            GAMEPAD_TOOLTIPS:LayoutSkillLinePreview(GAMEPAD_LEFT_TOOLTIP, skillLineData)
        end
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
                self:ActivateCurrentList()
            end
        else
            self:SetCurrentList(self.categoryList)
        end
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

function ZO_GamepadSkills:StartSingleAbilityAssignment(skillData)
    self.assignableActionBar:SetTargetSkill(skillData)
    self.assignableActionBar:Activate()
    self.actionBarAnimation:PlayForward()
    self:SetMode(ZO_GAMEPAD_SKILLS_SINGLE_ABILITY_ASSIGN_MODE)
    self.selectedTooltipRefreshGroup:MarkDirty("Full")
end

function ZO_GamepadSkills:InitializeOptionsDialog()
    local function ReleaseDialog()
        ZO_Dialogs_ReleaseDialogOnButtonPress("SKILLS_OPTIONS_DIALOG_GAMEPAD")
    end

    local linkInChat = ZO_GamepadEntryData:New(zo_strformat(SI_ITEM_ACTION_LINK_TO_CHAT))
    linkInChat.setup = ZO_SharedGamepadEntry_OnSetup
    linkInChat.callback = function(entryData)
        local skillData = entryData.data.skillData
        local link = skillData:GetCurrentProgressionLink()
        if internalassert(link, "Unable to generate link for skill.") then
            ZO_LinkHandler_InsertLinkAndSubmit(link)
        end
        ReleaseDialog()
    end

    ZO_Dialogs_RegisterCustomDialog("SKILLS_OPTIONS_DIALOG_GAMEPAD",
    {
        blockDialogReleaseOnPress = true,

        canQueue = true,

        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            allowRightStickPassThrough = true,
        },

        setup = function(dialog)
            dialog:setupFunc()
        end,

        title =
        {
            text = SI_GAMEPAD_OPTIONS_MENU,
        },
        parametricList =
        {
            {
                template = "ZO_GamepadMenuEntryTemplate",
                entryData = linkInChat,
            },
        },
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData and targetData.callback then
                        targetData.callback(dialog)
                    end
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                callback = function()
                    ReleaseDialog()
                end,
            },
        }
    })
end

function ZO_GamepadSkills_OnInitialize(control)
    GAMEPAD_SKILLS = ZO_GamepadSkills:New(control)
end

--[[ Skill Templates ]]--

function ZO_GamepadSkills_RespecBindingsBinding_OnInitialized(self, binding)
    ZO_KeybindButtonTemplate_OnInitialized(self)
    ApplyTemplateToControl(self, "ZO_KeybindButton_Gamepad_Template")
    local DONT_SHOW_UNBOUND = false
    self:SetKeybind(binding, DONT_SHOW_UNBOUND, binding)
end