--[[
    The (Gamepad)AssignableActionBar shows and lets you manage you what your current pending skill assignments will be inside the Gamepad Skills UI.
    It's distinct from the "real" action bar in that only handles skills, it doesn't necessarily care about the state of each ability, and it can change
    without changing the real action bar.
]]--

ZO_AssignableActionBar = ZO_Object:Subclass()

function ZO_AssignableActionBar:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_AssignableActionBar:Initialize(control)
    self.control = control
    self.interpolator = ZO_SimpleControlScaleInterpolator:New(1.0, 1.28)
    self.headerLabel = control:GetNamedChild("Header")
    self.movementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.selectedButtonIndex = nil

    self.buttons =
    {
        ZO_GamepadAssignableActionBarButton:New(self.control:GetNamedChild("Button1"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1),
        ZO_GamepadAssignableActionBarButton:New(self.control:GetNamedChild("Button2"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 2),
        ZO_GamepadAssignableActionBarButton:New(self.control:GetNamedChild("Button3"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 3),
        ZO_GamepadAssignableActionBarButton:New(self.control:GetNamedChild("Button4"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 4),
        ZO_GamepadAssignableActionBarButton:New(self.control:GetNamedChild("Button5"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 5),

        ZO_GamepadAssignableActionBarButton:New(self.control:GetNamedChild("Button6"), ACTION_BAR_ULTIMATE_SLOT_INDEX + 1),
    }
    
    ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("SlotUpdated", function(...) self:OnSlotUpdated(...) end)
    ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("CurrentHotbarUpdated", function(...) self:OnCurrentHotbarUpdated(...) end)
end

function ZO_AssignableActionBar:OnSkillsHidden()
    self:Deactivate()
    ACTION_BAR_ASSIGNMENT_MANAGER:CancelPendingWeaponSwap()
end

function ZO_AssignableActionBar:OnCurrentHotbarUpdated()
    if not self.control:IsControlHidden() then
        self:Refresh()
    end
end

function ZO_AssignableActionBar:OnSlotUpdated(hotbarCategory, actionSlotIndex)
    if not self.control:IsControlHidden() then
        if hotbarCategory == ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbarCategory() then
            local button = self.buttons[ZO_AssignableActionBar.ConvertActionSlotIndexToButtonIndex(actionSlotIndex)]
            if button then
                button:Refresh()
            end
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

function ZO_AssignableActionBar:RefreshHeaderLabel()
    local hotbarName = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbarName()
    self.headerLabel:SetText(hotbarName)
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

function ZO_AssignableActionBar:SetOnSelectedDataChangedCallback(onSelectedDataChangedCallback)
    self.onSelectedDataChangedCallback = onSelectedDataChangedCallback
end

function ZO_AssignableActionBar:SetOnAbilityFinalizedCallback(onAbilityFinalizedCallback)
    self.onAbilityFinalizedCallback = onAbilityFinalizedCallback
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

        if self.onSelectedDataChangedCallback then
            self.onSelectedDataChangedCallback(self, oldWasUltimate ~= newIsUltimate)
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

function ZO_AssignableActionBar:DeselectButtons()
    return self:SelectButton(nil)
end

function ZO_AssignableActionBar:AssignSkill(skillData)
    internalassert(skillData, "Needs skillData")
    local selectedButton = self.buttons[self.selectedButtonIndex]
    if selectedButton then
        selectedButton:AssignSkill(skillData)
        if self.onAbilityFinalizedCallback then
            self.onAbilityFinalizedCallback()
        end
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

function ZO_AssignableActionBar:ClearAbility()
    local selectedButton = self.buttons[self.selectedButtonIndex]
    if selectedButton then
        selectedButton:ClearSlot()
        if self.onAbilityFinalizedCallback then
            self.onAbilityFinalizedCallback()
        end
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
    local selectedButton = self.buttons[self.selectedButtonIndex]
    if selectedButton then
        local slotData = selectedButton:GetSlotData()
        SetupTooltipStatusLabel(tooltipType, selectedButton:GetSlotIndex())
        slotData:LayoutGamepadTooltip(tooltipType)
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(tooltipType)
    end
end

function ZO_AssignableActionBar:LayoutAssignableSkillLineAbilityTooltip(tooltipType, skillData)
    local skillProgressionData = skillData:GetPointAllocatorProgressionData()
    local abilityId = skillProgressionData:GetAbilityId()
    -- Mark the ability as already slotted if it is
    for i = ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1, ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 do
        if abilityId == GetSlotBoundId(i) then
            SetupTooltipStatusLabel(tooltipType, i)
            break
        end
    end 
    GAMEPAD_TOOLTIPS:LayoutSkillProgression(tooltipType, skillProgressionData)
end

function ZO_AssignableActionBar:IsActive()
    return self.active
end

ZO_GamepadAssignableActionBarButton = ZO_Object:Subclass()

function ZO_GamepadAssignableActionBarButton:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_GamepadAssignableActionBarButton:Initialize(control, actionSlotIndex)
    self.control = control
    self.icon = control:GetNamedChild("Icon")
    self.highlight = control:GetNamedChild("Highlight")
    self.keybindLabel = control:GetNamedChild("KeybindLabel")
    self.frame = control:GetNamedChild("Frame")

    if self.keybindLabel then
        local HIDE_UNBOUND = false
        ZO_Keybindings_RegisterLabelForBindingUpdate(self.keybindLabel, "GAMEPAD_ACTION_BUTTON_" .. actionSlotIndex, HIDE_UNBOUND)
    end

    self.actionSlotIndex = actionSlotIndex
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
end

function ZO_GamepadAssignableActionBarButton:ClearSlot()
    if ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar():ClearSlot(self.actionSlotIndex) then
        PlaySound(SOUNDS.ABILITY_SLOT_CLEARED)
    end
end

function ZO_GamepadAssignableActionBarButton:AssignSkill(skillData)
    if ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar():AssignSkillToSlot(self.actionSlotIndex, skillData) then
        PlaySound(SOUNDS.ABILITY_SLOTTED)
    end
end
