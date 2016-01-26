ZO_AssignableActionBar = ZO_GamepadActionBar:Subclass()

ASSIGNABLE_ACTION_BAR_LOCK_MODE_NONE = 1
ASSIGNABLE_ACTION_BAR_LOCK_MODE_ULTIMATE = 2
ASSIGNABLE_ACTION_BAR_LOCK_MODE_ACTIVE = 3

function ZO_AssignableActionBar:New(...)
    return ZO_GamepadActionBar.New(self, ...)
end

function ZO_AssignableActionBar:Initialize(control)
    ZO_GamepadActionBar.Initialize(self, control)

    self.movementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)

    self.selectedButtonIndex = nil
    self.lockMode = ASSIGNABLE_ACTION_BAR_LOCK_MODE_NONE

    self.actionButtonSlotAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("GamepadActionBarAbilitySlotted")
    self.actionButtonSlotAnimation:SetHandler("OnStop", function()
        self.hasPendingAbilityChangeRequest = nil
        if self.onAbilityFinalizedCallback then
            self.onAbilityFinalizedCallback()
        end
    end)

    local function OnHotBarResult(eventCode, reason)
        if reason == HOT_BAR_RESULT_NO_COMBAT_SWAP then
            self.hasPendingAbilityChangeRequest = nil
        end
    end

    EVENT_MANAGER:RegisterForEvent("GamepadAssignableActionBar", EVENT_HOT_BAR_RESULT, OnHotBarResult)
end

function ZO_AssignableActionBar:UpdateActionButtonSlotAnimation()
    if self.hasPendingAbilityChangeRequest and not self.actionButtonSlotAnimation:IsPlaying() then
        self.actionButtonSlotAnimation:ApplyAllAnimationsToControl(self.hasPendingAbilityChangeRequest:GetControl())
        self.actionButtonSlotAnimation:PlayFromStart()
    end
end

function ZO_AssignableActionBar:OnSkillsChanged()
    ZO_GamepadActionBar.OnSkillsChanged(self)
    self:UpdateActionButtonSlotAnimation()
end

function ZO_AssignableActionBar:RefreshDirtyButtons()
    ZO_GamepadActionBar.RefreshDirtyButtons(self)
    self:UpdateActionButtonSlotAnimation()
end

function ZO_AssignableActionBar:Activate()    
    if not self.active then
        ZO_GamepadActionBar.Activate(self)
        DIRECTIONAL_INPUT:Activate(self, self.control)
        self.active = true
    end
end

function ZO_AssignableActionBar:Deactivate()
    if self.active then 
        ZO_GamepadActionBar.Deactivate(self)
        DIRECTIONAL_INPUT:Deactivate(self)
        self.active = false
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
    local moveSuccess = false
    if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
        moveSuccess = self:SetSelectedButton(self.selectedButtonIndex + 1)
    elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        moveSuccess = self:SetSelectedButton(self.selectedButtonIndex - 1)
    end

    if moveSuccess then
        PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED)
    end
end

function ZO_AssignableActionBar:SetSelectedButton(buttonIndex)
    if buttonIndex then
        buttonIndex = zo_clamp(buttonIndex, 1, #self.buttons)

        if self.lockMode == ASSIGNABLE_ACTION_BAR_LOCK_MODE_ULTIMATE then
            if not self.buttons[buttonIndex]:IsUltimateSlot()  then
                return false
            end
        elseif self.lockMode == ASSIGNABLE_ACTION_BAR_LOCK_MODE_ACTIVE then
            if self.buttons[buttonIndex]:IsUltimateSlot() then
                return false
            end
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

function ZO_AssignableActionBar:SetSelectedButtonBySlotId(slotId)
    for i, button in ipairs(self.buttons) do
        if button:GetSlotId() == slotId then
            self:SetSelectedButton(i)
            break
        end
    end
end

function ZO_AssignableActionBar:SetLockMode(lockMode)
    if self.lockMode ~= lockMode then
        self.lockMode = lockMode

        if self.lockMode == ASSIGNABLE_ACTION_BAR_LOCK_MODE_ULTIMATE then
            if not self:IsUltimateSelected() then
                self:SetSelectedButtonBySlotId(ACTION_BAR_ULTIMATE_SLOT_INDEX + 1)
            end
        elseif self.lockMode == ASSIGNABLE_ACTION_BAR_LOCK_MODE_ACTIVE then
            if self:IsUltimateSelected() then
                self:SetSelectedButtonBySlotId(ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1)
            end
        end
    end
end

function ZO_AssignableActionBar:SetAbility(skillType, skillLineIndex, abilityIndex)
    if not self.hasPendingAbilityChangeRequest then
        local selectedButton = self.buttons[self.selectedButtonIndex]
        if selectedButton then
            selectedButton:SetAbility(skillType, skillLineIndex, abilityIndex)
            self.hasPendingAbilityChangeRequest = selectedButton
        end
    end
end

function ZO_AssignableActionBar:ClearAbility()
    if not self.hasPendingAbilityChangeRequest then
        local selectedButton = self.buttons[self.selectedButtonIndex]
        if selectedButton then
            selectedButton:ClearSlot()
            self.hasPendingAbilityChangeRequest = selectedButton
        end
    end
end

function ZO_AssignableActionBar:GetSelectedSlotId()
    local selectedButton = self.buttons[self.selectedButtonIndex]
    if selectedButton then
        return selectedButton:GetSlotId()
    end
end