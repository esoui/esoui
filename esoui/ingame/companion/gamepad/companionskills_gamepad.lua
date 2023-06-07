-------------------------------
-- Gamepad Skills quick menu --
-------------------------------

-- This is used by the action bar to display and select from any current slottable skill, across multiple skill lines
ZO_GamepadAssignableActionBar_CompanionQuickMenu = ZO_GamepadAssignableActionBar_QuickMenu_Base:Subclass()

function ZO_GamepadAssignableActionBar_CompanionQuickMenu:SetupListTemplates()
    local function MenuAbilityEntryTemplateSetup(control, skillEntry, selected, reselectingDuringRebuild, enabled, activated)
        ZO_GamepadSkillEntryTemplate_SetEntryInfoFromAllocator(skillEntry)
        ZO_SharedGamepadEntry_OnSetup(control, skillEntry, selected, reselectingDuringRebuild, enabled, activated)
        ZO_GamepadCompanionSkillEntryTemplate_Setup(control, skillEntry, selected, activated, ZO_SKILL_ABILITY_DISPLAY_INTERACTIVE)
    end

    local function MenuEntryHeaderTemplateSetup(control, skillEntry, selected, selectedDuringRebuild, enabled, activated)
        control.header:SetText(skillEntry:GetHeader())
        local skillData = skillEntry.skillData
        control.skillRankHeader:SetText(skillData:GetSkillLineData():GetCurrentRank())
    end

    local function IsSkillEqual(leftSkillEntry, rightSkillEntry)
        return leftSkillEntry.skillData == rightSkillEntry.skillData
    end

    self.list:AddDataTemplate("ZO_GamepadSimpleAbilityEntryTemplate", MenuAbilityEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, IsSkillEqual, "Skill")
    self.list:AddDataTemplateWithHeader("ZO_GamepadSimpleAbilityEntryTemplate", MenuAbilityEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, IsSkillEqual, "ZO_GamepadSimpleAbilityEntryHeaderTemplate", MenuEntryHeaderTemplateSetup, "Skill")
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
    function ZO_GamepadAssignableActionBar_CompanionQuickMenu:ForEachSlottableSkill(visitor)
        local skillLineFilters = { ZO_CompanionSkillLineData.IsAvailableOrAdvised }

        local shouldShowUltimateSkills = self.assignableActionBar:IsUltimateSelected()
        local skillDataFilters = { IsSkillPurchased, shouldShowUltimateSkills and IsSkillUltimate or IsSkillNormalActive }

        for _, skillTypeData in COMPANION_SKILLS_DATA_MANAGER:SkillTypeIterator() do
            for _, skillLineData in skillTypeData:SkillLineIterator(skillLineFilters) do
                for _, skillData in skillLineData:SkillIterator(skillDataFilters) do
                    visitor(skillTypeData, skillLineData, skillData)
                end
            end
        end
    end
end

local function IsActionBarEditable()
    local lockedReason = GetActionBarLockedReason()
    if lockedReason == ACTION_BAR_LOCKED_REASON_COMBAT then
        return false, GetString("SI_RESPECRESULT", RESPEC_RESULT_IS_IN_COMBAT)
    elseif lockedReason == ACTION_BAR_LOCKED_REASON_NOT_RESPECCABLE then
        return false, GetString("SI_RESPECRESULT", RESPEC_RESULT_ACTIVE_HOTBAR_NOT_RESPECCABLE)
    end
    return true
end

-----------------------------
-- Companion Skills
-----------------------------
ZO_CompanionSkills_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_CompanionSkills_Gamepad:Initialize(control)
    COMPANION_SKILLS_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control)

    COMPANION_SKILLS_GAMEPAD_SCENE = ZO_InteractScene:New("companionSkillsGamepad", SCENE_MANAGER, ZO_COMPANION_MANAGER:GetInteraction())
    COMPANION_SKILLS_GAMEPAD_SCENE:AddFragment(COMPANION_SKILLS_GAMEPAD_FRAGMENT)

    local DONT_ACTIVATE_ON_SHOW = false
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, DONT_ACTIVATE_ON_SHOW, COMPANION_SKILLS_GAMEPAD_SCENE)
end

function ZO_CompanionSkills_Gamepad:OnDeferredInitialize()
    self:InitializeHeader()
    self:InitializeFooter()
    self:InitializeSkillLinesList()
    self:InitializeSkillsList()
    self:SetListsUseTriggerKeybinds(true)
    self:InitializeQuickMenu()
    self:ResetSkillLineNewStatus()
    self:RegisterForEvents()
end

function ZO_CompanionSkills_Gamepad:InitializeHeader()
    local actionBarControl = self.header:GetNamedChild("AssignableActionBar")
    self.assignableActionBar = ZO_AssignableActionBar:New(actionBarControl)
    --Set override text used when narrating the header for the action bar entries.
    self.assignableActionBar:SetHeaderNarrationOverrideName(GetString(SI_COMPANION_BAR_ABILITY_PRIORITY))

    --Narration info for the action bar
    local narrationInfo =
    {
        canNarrate = function()
            return COMPANION_SKILLS_GAMEPAD_SCENE:IsShowing() and self.assignableActionBar:IsActive()
        end,
        selectedNarrationFunction = function()
            return self.assignableActionBar:GetNarrationText()
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("companionAssignableActionBar", narrationInfo)

    local actionBarBackground = self.control:GetNamedChild("ActionBarBackground")
    actionBarBackground:SetAnchor(TOPLEFT, actionBarControl, TOPLEFT, 0, 0)
    actionBarBackground:SetAnchor(BOTTOMRIGHT, actionBarControl, BOTTOMRIGHT, 0, 30)

    self.actionBarFocusAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_GamepadSkillsActionBarFocusAnimation")

    local ACTION_BAR_TRANSLATE_ANIMATION = 1
    self.actionBarFocusAnimation:GetAnimation(ACTION_BAR_TRANSLATE_ANIMATION):SetAnimatedControl(actionBarControl)
    local ACTION_BAR_BACKGROUND_FADE_ANIMATION = 2
    self.actionBarFocusAnimation:GetAnimation(ACTION_BAR_BACKGROUND_FADE_ANIMATION):SetAnimatedControl(actionBarBackground)

    self:SetupHeaderFocus(self.assignableActionBar)

    local headerKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = function()
                if self.assignableActionBar:IsAssigningTargetSkill() then
                    return GetString(SI_GAMEPAD_SKILLS_ASSIGN)
                else
                    return GetString(SI_GAMEPAD_SKILLS_BUILD_PLANNER)
                end
            end,

            keybind = "UI_SHORTCUT_PRIMARY",

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
                if self.assignableActionBar:IsAssigningTargetSkill() then
                    self.assignableActionBar:AssignTargetSkill()
                    self:LeaveSkillAssignment()
                else
                    self.quickMenu:Show()
                    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
                end
            end,
        }
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(headerKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        if self.assignableActionBar:IsAssigningTargetSkill() then
            self.assignableActionBar:ClearTargetSkill()
            self:LeaveSkillAssignment()
        else
            self.assignableActionBar:Deactivate()
            self:RequestLeaveCurrentList()
        end
    end)
    self.headerKeybindStripDescriptor = headerKeybindStripDescriptor

    self:RefreshHeader()
end

function ZO_CompanionSkills_Gamepad:RefreshHeader()
    local currentListDescriptor = self:GetCurrentListDescriptor()
    if currentListDescriptor and currentListDescriptor.headerData then
        ZO_GamepadGenericHeader_Refresh(self.header, currentListDescriptor.headerData)
    end
    self.assignableActionBar:Refresh()
end

function ZO_CompanionSkills_Gamepad:InitializeFooter()
    self.footerControl = ZO_CompanionSkills_Gamepad_Footer
    self.footerFragment = ZO_FadeSceneFragment:New(self.footerControl)
end

function ZO_CompanionSkills_Gamepad:RefreshFooter()
    local selectedSkillLineData = self:GetSelectedSkillLineData()
    if selectedSkillLineData then
        local NO_WRAP = true
        ZO_GamepadSkillLineXpBar_Setup(selectedSkillLineData, self.footerControl.xpBar, self.footerControl.name, NO_WRAP)
        SCENE_MANAGER:AddFragment(self.footerFragment)
    else
        SCENE_MANAGER:RemoveFragment(self.footerFragment)
    end
end

function ZO_CompanionSkills_Gamepad:TryClearSkillLineNewStatus()
    if self.clearSkillLineStatusOnSelectionChanged then
        self.clearSkillLineStatusOnSelectionChanged = false
        self.clearSkillLineNewStatusSkillLineData:ClearNew()
        self.skillLineListRefreshGroup:MarkDirty("Visible")
    end
end

function ZO_CompanionSkills_Gamepad:ResetSkillLineNewStatus()
    self:TryClearSkillLineNewStatus()
    self.clearSkillLineNewStatusCallId = nil
    self.clearSkillLineNewStatusSkillLineData = nil
end

function ZO_CompanionSkills_Gamepad:TrySetClearNewSkillLineFlag(callId)
    if self.clearSkillLineNewStatusCallId == callId then
        self.clearSkillLineStatusOnSelectionChanged = true
    end
end

local TIME_NEW_PERSISTS_WHILE_SELECTED = 1000
function ZO_CompanionSkills_Gamepad:CheckSkillLineNewStatus()
    self:TryClearSkillLineNewStatus()

    local selectedSkillLineData = self:GetSelectedSkillLineData()
    if selectedSkillLineData then
        if selectedSkillLineData:IsSkillLineOrAbilitiesNew() then
            -- mark the current skill line, so we can clear it after it clears the persist time
            self.clearSkillLineNewStatusSkillLineData = selectedSkillLineData
            local function MarkSkillLineReadyToClear(callId)
                if self.clearSkillLineNewStatusCallId == callId then
                    self.clearSkillLineStatusOnSelectionChanged = true
                end
            end
            self.clearSkillLineNewStatusCallId = zo_callLater(MarkSkillLineReadyToClear, TIME_NEW_PERSISTS_WHILE_SELECTED)
        else
            -- cancel last pending clear, if it has not yet fired
            self.clearSkillLineNewStatusCallId = nil
        end
    else
        -- cancel last pending clear, if it has not yet fired
        self.clearSkillLineNewStatusCallId = nil
    end
end

-- skill lines
function ZO_CompanionSkills_Gamepad:InitializeSkillLinesList()
    local function SkillLineEntryTemplateSetup(control, data, selected, reselectingDuringRebuild, enabled, activated)
        data:SetText(data.skillLineData:GetFormattedName())
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, activated)
        ZO_GamepadSkillLineEntryTemplate_Setup(control, data, selected)
    end

    local function AreSkillLineEntriesEqual(left, right)
        return left.skillLineData == right.skillLineData
    end

    local function SetupSkillLineList(list)
        list:SetAdditionalBottomSelectedItemOffsets(0, 20)
        list:SetHandleDynamicViewProperties(true)

        list:AddDataTemplate("ZO_GamepadSkillLineEntryTemplate", SkillLineEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, AreSkillLineEntriesEqual, "SkillLine")
        local DEFAULT_HEADER_SETUP = nil
        list:AddDataTemplateWithHeader("ZO_GamepadSkillLineEntryTemplate", SkillLineEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, AreSkillLineEntriesEqual, "ZO_GamepadMenuEntryHeaderTemplate", DEFAULT_HEADER_SETUP, "SkillLine")
    end

    local skillLineList = self:AddList("SkillLine", SetupSkillLineList)

    local function OnSelectedSkillLineChanged()
        self.skillListRefreshGroup:MarkDirty("List")
        self:RefreshTooltip()
        self:RefreshKeybinds()
        self:RefreshFooter()

        self:CheckSkillLineNewStatus()
    end
    skillLineList:SetOnSelectedDataChangedCallback(OnSelectedSkillLineChanged)

    -- Keybind strip
    local skillLineKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),

            keybind = "UI_SHORTCUT_PRIMARY",

            callback = function()
                local targetData = skillLineList:GetTargetData()
                if targetData and not targetData.advised then 
                    self:ShowListDescriptor(self.skillListDescriptor)
                end
            end,
            visible = function()
                return skillLineList:GetTargetData() ~= nil
            end,
        }
    }
    local function RefreshTooltipCallback(list)
        if self.assignableActionBar:IsActive() then
            self.assignableActionBar:LayoutOrClearSlotTooltip(GAMEPAD_LEFT_TOOLTIP)
            return
        end

        local selectedData = list:GetTargetData()
        if selectedData then 
            local skillLineData = selectedData.skillLineData
            GAMEPAD_TOOLTIPS:LayoutCompanionSkillLinePreview(GAMEPAD_LEFT_TOOLTIP, skillLineData)
        end
    end

    local function LeaveListCallback()
        SCENE_MANAGER:HideCurrentScene()
    end
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(skillLineKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        self:RequestLeaveCurrentList()
    end)
    self.skillLineListDescriptor =
    {
        list = skillLineList,
        keybindDescriptor = skillLineKeybindStripDescriptor,
        leaveListCallback = LeaveListCallback,
        refreshTooltipCallback = RefreshTooltipCallback,
        headerData =
        {
            titleText = GetString(SI_COMPANION_MENU_SKILLS_TITLE),
        },
    }

    local skillLineListRefreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_IMMEDIATELY)
    skillLineListRefreshGroup:AddDirtyState("List", function()
        self:BuildSkillLineList(skillLineList)
        self:RefreshTooltip()
        self:RefreshKeybinds()
    end)
    skillLineListRefreshGroup:AddDirtyState("Visible", function()
        skillLineList:RefreshVisible()
        self:RefreshTooltip()
        self:RefreshKeybinds()
    end)
    skillLineListRefreshGroup:AddDirtyState("Tooltip", function()
        self:RefreshTooltip()
        self:RefreshKeybinds()
    end)
    skillLineListRefreshGroup:SetActive(function()
        return self:IsCurrentListDescriptor(self.skillLineListDescriptor)
    end)
    self.skillLineListRefreshGroup = skillLineListRefreshGroup
end

local AVAILABLE_COMPANION_SKILLS_FILTER = { ZO_CompanionSkillLineData.IsAvailableOrAdvised }
function ZO_CompanionSkills_Gamepad:BuildSkillLineList(list)
    list:Clear()

    for _, skillTypeData in COMPANION_SKILLS_DATA_MANAGER:SkillTypeIterator() do
        local hasHeader = true
        for _, skillLineData in skillTypeData:SkillLineIterator(AVAILABLE_COMPANION_SKILLS_FILTER) do
            local function IsSkillLineNew()
                return skillLineData:IsSkillLineOrAbilitiesNew()
            end

            local data = ZO_GamepadEntryData:New()
            data:SetNew(IsSkillLineNew)
            data.skillLineData = skillLineData

            if hasHeader then
                data:SetHeader(skillTypeData:GetName())  
                list:AddEntry("ZO_GamepadSkillLineEntryTemplateWithHeader", data)
            else
                list:AddEntry("ZO_GamepadSkillLineEntryTemplate", data)
            end

            hasHeader = false
        end
    end
    list:Commit()
end

function ZO_CompanionSkills_Gamepad:GetSelectedSkillLineData()
    return self.skillLineListDescriptor.list:GetTargetData().skillLineData
end

-- skills
function ZO_CompanionSkills_Gamepad:InitializeSkillsList()
    local function MenuAbilityEntryTemplateSetup(control, skillEntry, selected, reselectingDuringRebuild, enabled, activated)
        ZO_GamepadSkillEntryTemplate_SetEntryInfoFromAllocator(skillEntry)
        ZO_SharedGamepadEntry_OnSetup(control, skillEntry, selected, reselectingDuringRebuild, enabled, activated)
        ZO_GamepadCompanionSkillEntryTemplate_Setup(control, skillEntry, selected, activated, ZO_SKILL_ABILITY_DISPLAY_INTERACTIVE)
    end

    local function IsSkillEqual(leftSkillEntry, rightSkillEntry)
        return leftSkillEntry.skillData == rightSkillEntry.skillData
    end

    local function SetupSkillList(list)
        list:SetHandleDynamicViewProperties(true)
        list:AddDataTemplate("ZO_GamepadAbilityEntryTemplate", MenuAbilityEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, IsSkillEqual, "Skill")
        local DEFAULT_HEADER_SETUP = nil
        list:AddDataTemplateWithHeader("ZO_GamepadAbilityEntryTemplate", MenuAbilityEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, IsSkillEqual, "ZO_GamepadMenuEntryHeaderTemplate", DEFAULT_HEADER_SETUP, "Skill")
    end
    local skillList = self:AddList("LineFilter", SetupSkillList)
    local function OnSelectedSkillChanged()
        self:RefreshTooltip()
        self:RefreshKeybinds()
    end
    skillList:SetOnSelectedDataChangedCallback(OnSelectedSkillChanged)

    -- Keybind strip
    local skillListKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_SKILLS_ASSIGN),

            keybind = "UI_SHORTCUT_SECONDARY",

            visible = function()
                local skillEntry = skillList:GetTargetData()
                if skillEntry then
                    local skillData = skillEntry.skillData
                    return skillData:IsActive() and skillData:GetPointAllocator():IsPurchased()
                end
                return false
            end,

            enabled = IsActionBarEditable,

            callback = function()
                local skillEntry = skillList:GetTargetData()
                self:StartAssigningSkill(skillEntry.skillData)
            end,
        }
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(skillListKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        self:RequestLeaveCurrentList()
    end)

    local function LeaveListCallback()
        self:ShowListDescriptor(self.skillLineListDescriptor)
    end
    local function RefreshTooltipCallback(list)
        local skillEntry = list:GetTargetData()
        if skillEntry then
            local skillData = skillEntry.skillData
            local skillProgressionData = skillData:GetPointAllocatorProgressionData()
            if self.assignableActionBar:IsAssigningTargetSkill() then
                GAMEPAD_TOOLTIPS:LayoutCompanionSkillProgression(GAMEPAD_LEFT_TOOLTIP, skillProgressionData)
                self.assignableActionBar:LayoutOrClearSlotTooltip(GAMEPAD_RIGHT_TOOLTIP)
                -- show comparison between slot and list skills
            elseif self.assignableActionBar:IsActive() then
                -- show slotted skill only
                self.assignableActionBar:LayoutOrClearSlotTooltip(GAMEPAD_LEFT_TOOLTIP)
            else
                -- show target skill only
                GAMEPAD_TOOLTIPS:LayoutCompanionSkillProgression(GAMEPAD_LEFT_TOOLTIP, skillProgressionData)
            end
        end
    end
    self.skillListDescriptor =
    {
        list = skillList,
        keybindDescriptor = skillListKeybindStripDescriptor,
        leaveListCallback = LeaveListCallback,
        refreshTooltipCallback = RefreshTooltipCallback,
        headerData =
        {
            titleText = function()
                return self:GetSelectedSkillLineData():GetFormattedName()
            end,
        },
    }

    local skillListRefreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_IMMEDIATELY)
    skillListRefreshGroup:AddDirtyState("List", function()
        self:BuildSkillsList(skillList)
        self:RefreshTooltip()
        self:RefreshKeybinds()
    end)
    skillListRefreshGroup:AddDirtyState("Visible", function()
        skillList:RefreshVisible()
        self:RefreshTooltip()
        self:RefreshKeybinds()
    end)
    skillListRefreshGroup:AddDirtyState("Tooltip", function()
        self:RefreshTooltip()
        self:RefreshKeybinds()
    end)
    skillListRefreshGroup:SetActive(function()
        return self:IsCurrentListDescriptor(self.skillListDescriptor)
    end)
    self.skillListRefreshGroup = skillListRefreshGroup
end

function ZO_CompanionSkills_Gamepad:BuildSkillsList(list)
    list:Clear()

    local skillLineData = self:GetSelectedSkillLineData()
    local lastHeaderText = nil

    for _, skillData in skillLineData:SkillIterator() do
        local skillEntry = ZO_GamepadEntryData:New()

        skillEntry:SetFontScaleOnSelection(false)
        skillEntry.skillData = skillData

        local headerText = skillData:GetHeaderText()
        if lastHeaderText ~= headerText then
            skillEntry:SetHeader(headerText)
            list:AddEntry("ZO_GamepadAbilityEntryTemplateWithHeader", skillEntry)
        else
            list:AddEntry("ZO_GamepadAbilityEntryTemplate", skillEntry)
        end
        lastHeaderText = headerText
    end

    list:Commit()
end

function ZO_CompanionSkills_Gamepad:InitializeQuickMenu()
    local quickMenuControl = self.control:GetNamedChild("QuickMenu")
    self.quickMenu = ZO_GamepadAssignableActionBar_CompanionQuickMenu:New(quickMenuControl, self.assignableActionBar)

    local X_OFFSET = 30
    local Y_OFFSET = 15
    local quickMenuList = self.quickMenu:GetListControl()
    quickMenuList:ClearAnchors()
    quickMenuList:SetAnchor(TOPLEFT, self.header, BOTTOMLEFT, -X_OFFSET, Y_OFFSET)
    quickMenuList:SetAnchor(BOTTOMRIGHT, self.control, BOTTOMRIGHT, X_OFFSET, 0)
end

function ZO_CompanionSkills_Gamepad:RegisterForEvents()
    local function FullRebuild()
        self.skillLineListRefreshGroup:MarkDirty("List")
        self.skillListRefreshGroup:MarkDirty("List")
    end

    local function OnSkillLineUpdated(skillLineData)
        --For the skill line rank on each entry and the skill line XP bar on the selected entry
        self.skillLineListRefreshGroup:MarkDirty("Visible")
        --For the locked/unlocked display on a skill
        self.skillListRefreshGroup:MarkDirty("Visible")
    end

    local function OnSkillLineAdded(skillLineData)
        --To add the new skill line to the list
        self.skillLineListRefreshGroup:MarkDirty("List")
    end

    local function OnCurrentHotbarUpdated()
        --Refresh slotted indicator on skill
        self.skillListRefreshGroup:MarkDirty("Visible")
        --Refresh action bar tooltips if skill line visible
        self.skillLineListRefreshGroup:MarkDirty("Tooltip")
    end

    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, FullRebuild)
    COMPANION_SKILLS_DATA_MANAGER:RegisterCallback("FullSystemUpdated", FullRebuild)
    COMPANION_SKILLS_DATA_MANAGER:RegisterCallback("SkillLineUpdated", OnSkillLineUpdated)
    COMPANION_SKILLS_DATA_MANAGER:RegisterCallback("SkillLineAdded", OnSkillLineAdded)
    ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("CurrentHotbarUpdated", OnCurrentHotbarUpdated)

    local function OnPurchaseLockStateChanged()
        self:RefreshKeybinds()
    end
    self.control:RegisterForEvent(EVENT_ACTION_BAR_LOCKED_REASON_CHANGED, OnPurchaseLockStateChanged)

    --action bar
    local function OnSelectedActionBarButtonChanged(selectedSlotIndex, didSlotTypeChange)
        -- refresh action bar tooltips and keybinds
        self:RefreshTooltip()
        self:RefreshKeybinds()
        --Re-narrate when the selection changes
        SCREEN_NARRATION_MANAGER:QueueCustomEntry("companionAssignableActionBar")
    end
    self.assignableActionBar:RegisterCallback("SelectedButtonChanged", OnSelectedActionBarButtonChanged)

    -- set initial state
    self.skillLineListRefreshGroup:MarkDirty("List")
    self.skillListRefreshGroup:MarkDirty("List")
    self.assignableActionBar:Refresh()
end

function ZO_CompanionSkills_Gamepad:TryClean()
    self.skillLineListRefreshGroup:TryClean()
    self.skillListRefreshGroup:TryClean()
end

-- Parametric scroll list overrides
function ZO_CompanionSkills_Gamepad:PerformUpdate()
    self.dirty = false
end

function ZO_CompanionSkills_Gamepad:RefreshTooltip()
    if not self:IsShowing() then
        return
    end
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)

    if self.quickMenu:IsShowing() then
        self.quickMenu:RefreshTooltip()
    elseif self.currentListDescriptor then
        self.currentListDescriptor.refreshTooltipCallback(self.currentListDescriptor.list)
    end
end

function ZO_CompanionSkills_Gamepad:IsShowing()
    return COMPANION_SKILLS_GAMEPAD_SCENE:IsShowing()
end

function ZO_CompanionSkills_Gamepad:OnShowing()
    ACTION_BAR_ASSIGNMENT_MANAGER:SetHotbarCycleOverride(HOTBAR_CATEGORY_COMPANION)
    self:ShowListDescriptor(self.skillLineListDescriptor)
    -- base class requires a list to setup the header
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)

    self.actionBarFocusAnimation:PlayInstantlyToStart()

    self:TryClean()
    self:RefreshTooltip()
    self:RefreshFooter()
end

function ZO_CompanionSkills_Gamepad:OnHide()
    ZO_Gamepad_ParametricList_Screen.OnHide(self)
    if self.assignableActionBar:IsAssigningTargetSkill() then
        self.assignableActionBar:ClearTargetSkill()
        self:LeaveSkillAssignment()
    end

    self:HideCurrentListDescriptor()
    self:ResetSkillLineNewStatus()
    ACTION_BAR_ASSIGNMENT_MANAGER:SetHotbarCycleOverride(nil)
end


function ZO_CompanionSkills_Gamepad:ShowListDescriptor(listDescriptor)
    if self.currentListDescriptor == listDescriptor then
        return
    end

    self:HideCurrentListDescriptor()

    self.currentListDescriptor = listDescriptor
    if listDescriptor then
        self:SetCurrentList(listDescriptor.list)
        self:RefreshHeader()
        self:UpdateActiveKeybindStrip()
        self:TryClean()
        self:RefreshTooltip()
    end
end

function ZO_CompanionSkills_Gamepad:HideCurrentListDescriptor()
    if self.currentListDescriptor then
        self:DisableCurrentList()
        self.currentListDescriptor = nil
        self:UpdateActiveKeybindStrip()
    end
end

function ZO_CompanionSkills_Gamepad:ActivateCurrentListDescriptor()
    if self.currentListDescriptor then
        self:UpdateActiveKeybindStrip()
        self:RefreshTooltip()
    end
end

function ZO_CompanionSkills_Gamepad:DeactivateCurrentListDescriptor()
    if self.currentListDescriptor then
        self:UpdateActiveKeybindStrip()
        self:RefreshTooltip()
    end
end

function ZO_CompanionSkills_Gamepad:GetCurrentListDescriptor()
    return self.currentListDescriptor
end

function ZO_CompanionSkills_Gamepad:IsCurrentListDescriptor(listDescriptor)
    return self.currentListDescriptor == listDescriptor
end

function ZO_CompanionSkills_Gamepad:RefreshKeybinds()
    ZO_Gamepad_ParametricList_Screen.RefreshKeybinds(self)
    if self.currentKeybindStripDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentKeybindStripDescriptor)
    end
end

function ZO_CompanionSkills_Gamepad:UpdateActiveKeybindStrip()
    -- if no keybind strip should be active, then target will be nil
    local targetKeybindStripDescriptor = nil
    if self:IsHeaderActive() then
        targetKeybindStripDescriptor = self.headerKeybindStripDescriptor
    else
        local currentListDescriptor = self:GetCurrentListDescriptor()
        if currentListDescriptor and currentListDescriptor.keybindDescriptor then
            targetKeybindStripDescriptor = currentListDescriptor.keybindDescriptor
        end
    end

    if self.currentKeybindStripDescriptor ~= targetKeybindStripDescriptor then
        if self.currentKeybindStripDescriptor then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentKeybindStripDescriptor)
        end
        if targetKeybindStripDescriptor then
            KEYBIND_STRIP:AddKeybindButtonGroup(targetKeybindStripDescriptor)
        end
        self.currentKeybindStripDescriptor = targetKeybindStripDescriptor
    end
end

function ZO_CompanionSkills_Gamepad:RequestLeaveCurrentList()
    local currentListDescriptor = self:GetCurrentListDescriptor()
    if currentListDescriptor and currentListDescriptor.leaveListCallback then
        currentListDescriptor.leaveListCallback()
    end
end

function ZO_CompanionSkills_Gamepad:ActivateAssignableActionBarFromList()
    self.assignableActionBar:SelectMostRecentlySelectedButton()
    self.assignableActionBar:Activate()
end

function ZO_CompanionSkills_Gamepad:OnEnterHeader()
    self:DeactivateCurrentListDescriptor()
    self:ActivateAssignableActionBarFromList()
    PlaySound(SOUNDS.GAMEPAD_MENU_UP)
    self:UpdateActiveKeybindStrip()
end

function ZO_CompanionSkills_Gamepad:OnLeaveHeader()
    self.assignableActionBar:Deactivate()
    self:ActivateCurrentListDescriptor()
    PlaySound(SOUNDS.GAMEPAD_MENU_DOWN)
    self:UpdateActiveKeybindStrip()
end

function ZO_CompanionSkills_Gamepad:StartAssigningSkill(skillData)
    self:HideCurrentListDescriptor()
    self.assignableActionBar:SetTargetSkill(skillData)
    self.assignableActionBar:Activate()
    self.actionBarFocusAnimation:PlayFromStart()
    self:UpdateActiveKeybindStrip()
end

function ZO_CompanionSkills_Gamepad:LeaveSkillAssignment()
    self.actionBarFocusAnimation:PlayFromEnd()
    self.assignableActionBar:Deactivate()
    self:ShowListDescriptor(self.skillListDescriptor)
    self:UpdateActiveKeybindStrip()
end

-----------------------------
-- Global XML Functions
-----------------------------

function ZO_CompanionSkills_Gamepad_OnInitialize(control)
    COMPANION_SKILLS_GAMEPAD = ZO_CompanionSkills_Gamepad:New(control)
end