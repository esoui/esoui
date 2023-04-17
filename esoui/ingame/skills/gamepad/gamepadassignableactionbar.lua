--[[
    The (Gamepad)AssignableActionBar shows and lets you manage you what your current pending skill assignments will be inside the Gamepad Skills UI.
    It's distinct from the "real" action bar in that only handles skills, it doesn't necessarily care about the state of each ability, and it can change
    without changing the real action bar.
]]--

ZO_AssignableActionBar = ZO_InitializingCallbackObject:Subclass()

function ZO_AssignableActionBar:Initialize(control)
    self.control = control
    self.interpolator = ZO_SimpleControlScaleInterpolator:New(1.0, 1.28)
    self.headerLabel = control:GetNamedChild("Header")
    self.movementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.selectedButtonIndex = nil
    self.mostRecentlySelectedActionSlotIndex = nil

    self.buttons =
    {
        ZO_GamepadAssignableActionBarButton:New(self.control:GetNamedChild("Button1"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1),
        ZO_GamepadAssignableActionBarButton:New(self.control:GetNamedChild("Button2"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 2),
        ZO_GamepadAssignableActionBarButton:New(self.control:GetNamedChild("Button3"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 3),
        ZO_GamepadAssignableActionBarButton:New(self.control:GetNamedChild("Button4"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 4),
        ZO_GamepadAssignableActionBarButton:New(self.control:GetNamedChild("Button5"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 5),

        ZO_GamepadAssignableActionBarButton:New(self.control:GetNamedChild("UltimateButton"), ACTION_BAR_ULTIMATE_SLOT_INDEX + 1),
    }
    
    ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("SlotUpdated", function(...) self:OnSlotUpdated(...) end)
    ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("SlotNewStatusChanged", function(...) self:OnSlotUpdated(...) end)
    ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("CurrentHotbarUpdated", function(...) self:OnCurrentHotbarUpdated(...) end)

    self.control:SetHandler("OnEffectivelyShown", function() self:Refresh() end)
end

function ZO_AssignableActionBar:OnSkillsHidden()
    self:Deactivate()
    ACTION_BAR_ASSIGNMENT_MANAGER:CancelPendingWeaponSwap()
end

function ZO_AssignableActionBar:OnCurrentHotbarUpdated()
    if not self.control:IsHidden() then
        self:Refresh()
    end
end

function ZO_AssignableActionBar:OnSlotUpdated(hotbarCategory, actionSlotIndex)
    if not self.control:IsHidden() and hotbarCategory == ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbarCategory() then
        local button = self.buttons[ZO_AssignableActionBar.ConvertActionSlotIndexToButtonIndex(actionSlotIndex)]
        if button then
            button:Refresh()
        end
    end
end

function ZO_AssignableActionBar:GetControl()
    return self.control
end

function ZO_AssignableActionBar:Refresh()
    self:RefreshAllButtons()
    self:RefreshHeaderLabel()
end

function ZO_AssignableActionBar:RefreshAllButtons()
    for i, button in ipairs(self.buttons) do
        button:Refresh()
    end
end

function ZO_AssignableActionBar:SetHeaderNarrationOverrideName(overrideHeaderName)
    self.overrideHeaderName = overrideHeaderName
end

function ZO_AssignableActionBar:RefreshHeaderLabel()
    if self.headerLabel then
        local hotbarName = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbarName()
        self.headerLabel:SetText(hotbarName)
    end
end

function ZO_AssignableActionBar.ConvertButtonIndexToActionSlotIndex(buttonIndex)
    return buttonIndex + ACTION_BAR_FIRST_NORMAL_SLOT_INDEX
end

function ZO_AssignableActionBar.ConvertActionSlotIndexToButtonIndex(actionSlotIndex)
    return actionSlotIndex - ACTION_BAR_FIRST_NORMAL_SLOT_INDEX
end

function ZO_AssignableActionBar:Activate()
    if not self.active then
        self:RefreshAllButtons()
        DIRECTIONAL_INPUT:Activate(self, self.control)
        self.active = true
    end
end

function ZO_AssignableActionBar:Deactivate()
    if self.active then 
        self:DeselectButtons()
        self:ClearTargetSkill()
        DIRECTIONAL_INPUT:Deactivate(self)
        self.active = false
    end
end

function ZO_AssignableActionBar:SetHighlightAll(highlightAll)
    for i, button in ipairs(self.buttons) do
        button:SetSelected(highlightAll, self.interpolator)
    end
end

function ZO_AssignableActionBar:IsUltimateSelected()
    local selectedButton = self.buttons[self.selectedButtonIndex]
    if selectedButton then
        return selectedButton:IsUltimateSlot()
    end
end

function ZO_AssignableActionBar:UpdateDirectionalInput()
    local result = self.movementController:CheckMovement()
    local newActionSlotIndex
    if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
        newActionSlotIndex = ZO_AssignableActionBar.ConvertButtonIndexToActionSlotIndex(self.selectedButtonIndex + 1)
    elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        newActionSlotIndex = ZO_AssignableActionBar.ConvertButtonIndexToActionSlotIndex(self.selectedButtonIndex - 1)
    end

    if newActionSlotIndex then
        local clampedSlotIndex = zo_clamp(newActionSlotIndex, ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1, ACTION_BAR_ULTIMATE_SLOT_INDEX + 1)

        if self:SelectButton(clampedSlotIndex) then
            PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED)
        end
    end
end

function ZO_AssignableActionBar:SelectButton(actionSlotIndex)
    local buttonIndex = nil
    if actionSlotIndex then
        for index, button in ipairs(self.buttons) do
            if button:GetSlotIndex() == actionSlotIndex then
                buttonIndex = index
                break
            end
        end

        if not buttonIndex then
            internalassert(false, "Button not found")
            return false
        end

        if self.targetSkill and self.targetSkill:IsUltimate() ~= self.buttons[buttonIndex]:IsUltimateSlot() then
            return false
        end
    end

    if buttonIndex ~= self.selectedButtonIndex then
        local oldSelected = self.buttons[self.selectedButtonIndex]
        local oldWasUltimate = nil
        if oldSelected then
            oldSelected:SetSelected(false, self.interpolator)
            oldWasUltimate = oldSelected:IsUltimateSlot()
        end

        self.selectedButtonIndex = buttonIndex
        local newSelected = self.buttons[self.selectedButtonIndex]
        local newIsUltimate = nil
        if newSelected then
            newSelected:SetSelected(true, self.interpolator)
            newIsUltimate = newSelected:IsUltimateSlot()
        end

        local buttonTypeChanged = oldWasUltimate ~= newIsUltimate
        self:FireCallbacks("SelectedButtonChanged", actionSlotIndex, buttonTypeChanged)
        if actionSlotIndex then
            self.mostRecentlySelectedActionSlotIndex = actionSlotIndex
        end
        return true
    end

    return false
end

function ZO_AssignableActionBar:SelectFirstNormalButton()
    return self:SelectButton(ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1)
end

function ZO_AssignableActionBar:SelectFirstUltimateButton()
    return self:SelectButton(ACTION_BAR_ULTIMATE_SLOT_INDEX + 1)
end

function ZO_AssignableActionBar:SelectMostRecentlySelectedButton()
    if self.mostRecentlySelectedActionSlotIndex then
        self:SelectButton(self.mostRecentlySelectedActionSlotIndex)
    else
        self:SelectFirstNormalButton() -- pick a button to start out with
    end
end

function ZO_AssignableActionBar:DeselectButtons()
    return self:SelectButton(nil)
end

function ZO_AssignableActionBar:AssignSkill(skillData)
    internalassert(skillData, "Needs skillData")
    local selectedButton = self.buttons[self.selectedButtonIndex]
    if selectedButton then
        selectedButton:AssignSkill(skillData)
        self:FireCallbacks("AbilityFinalized")
    end
end

function ZO_AssignableActionBar:SetTargetSkill(skillData)
    self.targetSkill = skillData

    if not self:GetSelectedSlotIndex() then
        local actionSlotIndex = skillData:GetSlotOnCurrentHotbar() or ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar():FindEmptySlotForSkill(skillData)

        if actionSlotIndex then
            internalassert(self:SelectButton(actionSlotIndex))
        elseif skillData:IsUltimate() then
            internalassert(self:SelectFirstUltimateButton())
        else
            internalassert(self:SelectFirstNormalButton())
        end
    end
end

function ZO_AssignableActionBar:ClearTargetSkill()
    self.targetSkill = nil
end

function ZO_AssignableActionBar:AssignTargetSkill()
    self:AssignSkill(self.targetSkill)
    self:ClearTargetSkill()
end

function ZO_AssignableActionBar:IsAssigningTargetSkill()
    return self.targetSkill ~= nil
end

function ZO_AssignableActionBar:ClearAbility()
    local selectedButton = self.buttons[self.selectedButtonIndex]
    if selectedButton then
        selectedButton:ClearSlot()
        self:FireCallbacks("AbilityFinalized")
    end
end

function ZO_AssignableActionBar:GetSelectedSlotIndex()
    local selectedButton = self.buttons[self.selectedButtonIndex]
    if selectedButton then
        return selectedButton:GetSlotIndex()
    end
end

local function SetupTooltipStatusLabel(tooltipType, actionSlotIndex)
    local valueText
    if actionSlotIndex == ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 then
        valueText = zo_strformat(SI_GAMEPAD_SKILLS_TOOLTIP_STATUS_NUMBER, GetString(SI_BINDING_NAME_GAMEPAD_ACTION_BUTTON_8))
    else
        valueText = zo_strformat(SI_GAMEPAD_SKILLS_TOOLTIP_STATUS_NUMBER, ZO_AssignableActionBar.ConvertActionSlotIndexToButtonIndex(actionSlotIndex))
    end
    GAMEPAD_TOOLTIPS:SetStatusLabelText(tooltipType, GetString(SI_GAMEPAD_SKILLS_TOOLTIP_STATUS), valueText)
end

function ZO_AssignableActionBar:LayoutOrClearSlotTooltip(tooltipType)
    local hotbar = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar()
    local selectedActionSlotIndex = self:GetSelectedSlotIndex()
    if hotbar:IsSlotLocked(selectedActionSlotIndex) then
        local description = ZO_ERROR_COLOR:Colorize(hotbar:GetSlotUnlockText(selectedActionSlotIndex))
        GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(tooltipType, GetString(SI_ACTION_BAR_SLOT_LOCKED_HEADER), description)
    elseif self.buttons[self.selectedButtonIndex] then
        local selectedButton = self.buttons[self.selectedButtonIndex]
        local slotData = selectedButton:GetSlotData()
        SetupTooltipStatusLabel(tooltipType, selectedActionSlotIndex)
        slotData:LayoutGamepadTooltip(tooltipType)
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(tooltipType)
    end
end

function ZO_AssignableActionBar:LayoutAssignableSkillLineAbilityTooltip(tooltipType, skillData)
    local skillProgressionData = skillData:GetPointAllocatorProgressionData()
    local abilityId = skillProgressionData:GetAbilityId()
    local slottedActionBarIndex = nil
    -- Mark the ability as already slotted if it is
    for i = ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1, ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 do
        if abilityId == GetSlotBoundId(i) then
            slottedActionBarIndex = i
            break
        end
    end

    if slottedActionBarIndex then
        SetupTooltipStatusLabel(tooltipType, slottedActionBarIndex)
    else
        GAMEPAD_TOOLTIPS:ClearStatusLabel(tooltipType)
    end

    if skillData:IsPlayerSkill() then
        GAMEPAD_TOOLTIPS:LayoutSkillProgression(tooltipType, skillProgressionData)
    elseif skillData:IsCompanionSkill() then
        GAMEPAD_TOOLTIPS:LayoutCompanionSkillProgression(GAMEPAD_LEFT_TOOLTIP, skillProgressionData)
    end
end

function ZO_AssignableActionBar:IsActive()
    return self.active
end

--Gets the narration for the currently selected slot
function ZO_AssignableActionBar:GetSelectedSlotNarrationText()
    local selectedButton = self.buttons[self.selectedButtonIndex]
    if selectedButton then
        return selectedButton:GetNarrationText()
    end
end

--Gets the narration for the bar
function ZO_AssignableActionBar:GetNarrationText()
    local narrations = {}
    --If an overrideHeaderName was specified, use that, otherwise use the name of the current hotbar
    local headerName
    if self.overrideHeaderName then
        headerName = self.overrideHeaderName
    else
        headerName = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbarName()
    end
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(headerName))
    --Narration for the selected slot
    ZO_AppendNarration(narrations, self:GetSelectedSlotNarrationText())
    return narrations
end

ZO_GamepadAssignableActionBarButton = ZO_InitializingObject:Subclass()

function ZO_GamepadAssignableActionBarButton:Initialize(control, actionSlotIndex)
    self.control = control
    self.icon = control:GetNamedChild("Icon")
    self.lock = control:GetNamedChild("Lock")
    self.newIndicator = control:GetNamedChild("NewIndicator")
    self.newIndicatorIdle = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_GamepadAssignableActionBarNewIndicator_Idle", self.newIndicator)
    self.newIndicatorFadeout = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_GamepadAssignableActionBarNewIndicator_Fadeout", self.newIndicator)
    self.highlight = control:GetNamedChild("Highlight")
    self.keybindLabel = control:GetNamedChild("KeybindLabel")
    self.frame = control:GetNamedChild("Frame")

    self.actionSlotIndex = actionSlotIndex
    self.actionName = nil
    self.isSlotNew = false
end

function ZO_GamepadAssignableActionBarButton:GetSlotIndex()
    return self.actionSlotIndex
end

function ZO_GamepadAssignableActionBarButton:GetSlotData()
    return ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar():GetSlotData(self.actionSlotIndex)
end

function ZO_GamepadAssignableActionBarButton:IsUltimateSlot()
    return ACTION_BAR_ASSIGNMENT_MANAGER:IsUltimateSlot(self.actionSlotIndex)
end

function ZO_GamepadAssignableActionBarButton:GetControl()
    return self.control
end

function ZO_GamepadAssignableActionBarButton:GetIconControl()
    return self.icon
end

function ZO_GamepadAssignableActionBarButton:SetSelected(selected, interpolator)
    if selected then
        interpolator:ScaleUp(self:GetIconControl())
    else
        interpolator:ScaleDown(self:GetIconControl())
    end

    if self.highlight then
        self.highlight:SetHidden(not selected)
    end

    if self.frame then
        local color = selected and ZO_SELECTED_TEXT or ZO_NORMAL_TEXT
        self.frame:SetEdgeColor(color:UnpackRGBA())
    end

    if selected then
        self:ClearNewIndicator()
    end
end

function ZO_GamepadAssignableActionBarButton:Refresh()
    local slotData = self:GetSlotData()
    local slotIcon = slotData:GetIcon()
    if slotIcon then
        self.icon:SetHidden(false)
        self.icon:SetTexture(slotIcon)
    else
        self.icon:SetHidden(true)
    end

    local hotbarData = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar()
    self.lock:SetHidden(not hotbarData:IsSlotLocked(self.actionSlotIndex))
    local isNew = hotbarData:IsSlotNew(self.actionSlotIndex)
    if isNew ~= self.isSlotNew then
        self.isSlotNew = isNew
        if isNew then
            self.newIndicatorFadeout:Stop()
            self.newIndicatorIdle:PlayFromStart()
        else
            self.newIndicatorIdle:Stop()
            self.newIndicatorFadeout:PlayFromStart()
        end
    end

    if self.keybindLabel then
        local currentHotbarCategory = hotbarData:GetHotbarCategory()
        local keyboardActionName, gamepadActionName = ACTION_BAR_ASSIGNMENT_MANAGER:GetKeyboardAndGamepadActionNameForSlot(self.actionSlotIndex, currentHotbarCategory)
        local actionPriority = ACTION_BAR_ASSIGNMENT_MANAGER:GetAutomaticCastPriorityForSlot(self.actionSlotIndex, currentHotbarCategory)
        if gamepadActionName ~= self.actionName or actionPriority ~= self.actionPriority then
            ZO_Keybindings_UnregisterLabelForBindingUpdate(self.keybindLabel)
            if gamepadActionName then
                local HIDE_UNBOUND = false
                ZO_Keybindings_RegisterLabelForBindingUpdate(self.keybindLabel, keyboardActionName, HIDE_UNBOUND, gamepadActionName)
            elseif actionPriority then
                self.keybindLabel:SetText(tostring(actionPriority))
            else
                self.keybindLabel:SetText("")
            end
            self.actionName = gamepadActionName
            self.actionPriority = actionPriority
        end
    end
end

function ZO_GamepadAssignableActionBarButton:ClearNewIndicator()
    ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar():ClearSlotNew(self.actionSlotIndex)
end

function ZO_GamepadAssignableActionBarButton:ClearSlot()
    if ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar():ClearSlot(self.actionSlotIndex) then
        self:ClearNewIndicator()
        PlaySound(SOUNDS.ABILITY_SLOT_CLEARED)
    end
end

function ZO_GamepadAssignableActionBarButton:AssignSkill(skillData)
    if ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar():AssignSkillToSlot(self.actionSlotIndex, skillData) then
        self:ClearNewIndicator()
        PlaySound(SOUNDS.ABILITY_SLOTTED)
    end
end

do
    local DEFAULT_SHOW_AS_HOLD = nil
    local NOT_BOUND_ACTION_STRING = GetString(SI_ACTION_IS_NOT_BOUND)

    function ZO_GamepadAssignableActionBarButton:GetNarrationText()
        local narrations = {}

        --Get the binding narration
        if self.keybindLabel then
            local hotbarData = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar()
            local currentHotbarCategory = hotbarData:GetHotbarCategory()
            local keyboardActionName, gamepadActionName = ACTION_BAR_ASSIGNMENT_MANAGER:GetKeyboardAndGamepadActionNameForSlot(self.actionSlotIndex, currentHotbarCategory)
            local actionPriority = ACTION_BAR_ASSIGNMENT_MANAGER:GetAutomaticCastPriorityForSlot(self.actionSlotIndex, currentHotbarCategory)

            local bindingTextNarration = nil
            --If we found an action name for the slot, use that for narrating
            if gamepadActionName then
                bindingTextNarration = ZO_Keybindings_GetPreferredHighestPriorityNarrationStringFromActions(keyboardActionName, gamepadActionName, DEFAULT_SHOW_AS_HOLD) or NOT_BOUND_ACTION_STRING
            elseif actionPriority then
                --If there was no action name and we have an action priority, use that for narrating the binding text
                bindingTextNarration = tostring(actionPriority)
            end
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(bindingTextNarration))
        end

        --Narration for the slotted entry
        local slotData = self:GetSlotData()
        if slotData then
            local actionType = slotData:GetSlottableActionType()
            --The skillData lives in different spots depending on the action type
            if actionType == ZO_SLOTTABLE_ACTION_TYPE_PLAYER_SKILL then
                local skillData = slotData:GetPlayerSkillData()
                local progressionData = skillData:GetPointAllocatorProgressionData()
                if progressionData then
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(progressionData:GetFormattedName()))
                end
            elseif actionType == ZO_SLOTTABLE_ACTION_TYPE_COMPANION_SKILL then
                local skillData = slotData:GetCompanionSkillData()
                local progressionData = skillData:GetPointAllocatorProgressionData()
                if progressionData then
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(progressionData:GetFormattedName()))
                end
            else
                --If we get here, assume the slot is empty
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_ACTION_BAR_EMPTY_ENTRY_NARRATION)))
            end
        end
        return narrations
    end
end

ZO_GamepadAssignableActionBar_QuickMenu_Base = ZO_InitializingCallbackObject:Subclass()

function ZO_GamepadAssignableActionBar_QuickMenu_Base:SetupListTemplates()
    assert(false, "should be overridden")
end

function ZO_GamepadAssignableActionBar_QuickMenu_Base:ForEachSlottableSkill(visitor)
    assert(false, "should be overridden")
end

function ZO_GamepadAssignableActionBar_QuickMenu_Base:Initialize(control, assignableActionBar)
    self.control = control
    self.assignableActionBar = assignableActionBar

    self.fragment = ZO_FadeSceneFragment:New(self.control:GetNamedChild("Container"), ALWAYS_ANIMATE)
    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self.keybindStripId = KEYBIND_STRIP:PushKeybindGroupState()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStrip, self.keybindStripId)
            self.list:Activate()
            self:RefreshList()
        elseif newState == SCENE_FRAGMENT_HIDING then
            self.assignableActionBar:ClearTargetSkill()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self.list:Deactivate()
            KEYBIND_STRIP:PopKeybindGroupState()
            self.keybindStripId = nil
        end
    end)

    local listControl = self.control:GetNamedChild("ContainerList")
    self.list = ZO_GamepadVerticalParametricScrollList:New(listControl)
    self.list:SetAlignToScreenCenter(true)
    self.list:SetHandleDynamicViewProperties(true)

    self.list:SetNoItemText(GetString(SI_GAMEPAD_SKILLS_NO_ABILITIES))

    self:SetupListTemplates()

    local function RefreshSelectedTooltip()
        self:RefreshTooltip()
    end

    self.list:SetOnSelectedDataChangedCallback(RefreshSelectedTooltip)

    local keybindStrip =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_SKILLS_ASSIGN),

            keybind = "UI_SHORTCUT_PRIMARY",

            enabled = function()
                local slotIndex = self.assignableActionBar:GetSelectedSlotIndex()
                local result = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar():GetExpectedSlotEditResult(slotIndex)
                if result ~= HOT_BAR_RESULT_SUCCESS then
                    return false, GetString("SI_HOTBARRESULT", result)
                end
                return true
            end,

            callback = function()
                self:PerformAssignment()
            end,
        },
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
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(keybindStrip, GAME_NAVIGATION_TYPE_BUTTON, 
        function()
            SCENE_MANAGER:RemoveFragment(self.fragment)
            PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
        end)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(keybindStrip, self.list)
    self.keybindStrip = keybindStrip

    local function OnHotbarSwapVisibleStateChanged()
        if self:IsShowing() then
            self:RefreshKeybinds()
        end
    end
    ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("HotbarSwapVisibleStateChanged", OnHotbarSwapVisibleStateChanged)

    local function OnSlotAssignmentsChanged()
        if self:IsShowing() then
            self.list:RefreshVisible()
        end
    end
    ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("SlotUpdated", OnSlotAssignmentsChanged)
    ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("CurrentHotbarUpdated", OnSlotAssignmentsChanged)

    local function OnSelectedButtonChanged(slotIndex, didSlotTypeChange)
        if self:IsShowing() then
            if didSlotTypeChange then
                self:RefreshList()
            end
            self:RefreshTooltip()
        end
    end
    self.assignableActionBar:RegisterCallback("SelectedButtonChanged", OnSelectedButtonChanged)

    --Narrates the list
    local narrationInfo = 
    {
        canNarrate = function()
            return self.fragment:IsShowing()
        end,
        headerNarrationFunction = function()
            --Treat the associated assignable action bar as the header for this list
            return self.assignableActionBar:GetNarrationText()
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterParametricList(self.list, narrationInfo)
end

function ZO_GamepadAssignableActionBar_QuickMenu_Base:GetListControl()
    return self.control:GetNamedChild("ContainerList")
end

function ZO_GamepadAssignableActionBar_QuickMenu_Base:Show()
    internalassert(self.assignableActionBar:IsActive(), "The action bar must be active for the quick menu to work")
    SCENE_MANAGER:AddFragment(self.fragment)
end

function ZO_GamepadAssignableActionBar_QuickMenu_Base:Hide()
    -- because the action bar is assumed active, we do not need to activate any lists in the parent skills object
    SCENE_MANAGER:RemoveFragment(self.fragment)
end

function ZO_GamepadAssignableActionBar_QuickMenu_Base:IsShowing()
    return self.fragment:IsShowing()
end

function ZO_GamepadAssignableActionBar_QuickMenu_Base:RefreshVisible()
    self.list:RefreshVisible()
end

do
    local DEFAULT_SHOW_AS_HOLD = nil
    local NOT_BOUND_ACTION_STRING = GetString(SI_ACTION_IS_NOT_BOUND)

    function ZO_GamepadAssignableActionBar_QuickMenu_Base:RefreshList()
        self.list:Clear()

        local lastSkillLineData = nil
        self:ForEachSlottableSkill(function(skillTypeData, skillLineData, skillData)
            local skillEntry = ZO_GamepadEntryData:New()
            skillEntry:SetFontScaleOnSelection(false)
            skillEntry.skillData = skillData

            if skillLineData ~= lastSkillLineData then
                skillEntry:SetHeader(skillLineData:GetFormattedName())
                --Override the entry's header narration to include the rank
                skillEntry.headerNarrationFunction = function(entryData, entryControl)
                    local narrations = {}
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(skillLineData:GetCurrentRank()))
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.header))
                    return narrations
                end
                self.list:AddEntry("ZO_GamepadSimpleAbilityEntryTemplateWithHeader", skillEntry)
            else
                self.list:AddEntry("ZO_GamepadSimpleAbilityEntryTemplate", skillEntry)
            end

            skillEntry.narrationText = function(entryData, entryControl)
                local narrations = {}
                --Generate the default entry narration
                ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl))
                --Include the narration for the keybinding if applicable
                if SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode() == SKILL_POINT_ALLOCATION_MODE_PURCHASE_ONLY and skillData:IsActive() then
                    local actionSlotIndex = skillData:GetSlotOnCurrentHotbar()
                    if actionSlotIndex then
                        local keyboardActionName, gamepadActionName = ACTION_BAR_ASSIGNMENT_MANAGER:GetKeyboardAndGamepadActionNameForSlot(actionSlotIndex, ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbarCategory())
                        if gamepadActionName then
                            local bindingTextNarration = ZO_Keybindings_GetPreferredHighestPriorityNarrationStringFromActions(keyboardActionName, gamepadActionName, DEFAULT_SHOW_AS_HOLD) or NOT_BOUND_ACTION_STRING
                            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(bindingTextNarration))
                        end
                    end
                end
                return narrations
            end

            lastSkillLineData = skillLineData
        end)

        self.list:Commit()
    end
end

function ZO_GamepadAssignableActionBar_QuickMenu_Base:RefreshTooltip()
    local skillEntry = self.list:GetTargetData()
    if skillEntry then
        self.assignableActionBar:LayoutAssignableSkillLineAbilityTooltip(GAMEPAD_LEFT_TOOLTIP, skillEntry.skillData)
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    end

    self.assignableActionBar:LayoutOrClearSlotTooltip(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_GamepadAssignableActionBar_QuickMenu_Base:RefreshKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStrip)
end

function ZO_GamepadAssignableActionBar_QuickMenu_Base:PerformAssignment()
    local skillEntry = self.list:GetTargetData()
    if skillEntry then
        self.assignableActionBar:AssignSkill(skillEntry.skillData)
    end
end

