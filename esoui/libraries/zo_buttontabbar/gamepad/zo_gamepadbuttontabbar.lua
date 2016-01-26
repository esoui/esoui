ZO_GamepadButtonTabBar = ZO_Object:Subclass()

function ZO_GamepadButtonTabBar:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_GamepadButtonTabBar:Initialize(control, onSelectedCallback, onUnselectedCallback, onPressedCallback)
    self.control = control
    self.onSelectedCallback = onSelectedCallback
    self.onUnselectedCallback = onUnselectedCallback
    self.onPressedCallback = onPressedCallback

    self.movementControllerHorizontal = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)

    self.isActivated = false

    self.buttons = {}
    self.selectedIndex = nil
    self.deactivatedIndex = nil
end

function ZO_GamepadButtonTabBar:AddButton(control, data)
    self.buttons[#self.buttons + 1] = control
    control.data = data
end

function ZO_GamepadButtonTabBar:Activate()
    if self.isActivated then
        return --already activated
    end

    self.isActivated = true
    DIRECTIONAL_INPUT:Activate(self, self.control)
    self:SetSelectedButton(self.deactivatedIndex or 1)
end

function ZO_GamepadButtonTabBar:Deactivate()
    if not self.isActivated then
        return --already deactivated
    end

    DIRECTIONAL_INPUT:Deactivate(self)
    self.deactivatedIndex = self.selectedIndex
    self:SetSelectedButton(nil)
    self.isActivated = false
end

function ZO_GamepadButtonTabBar:UpdateDirectionalInput()
    local horizontalResult = self.movementControllerHorizontal:CheckMovement()

    if horizontalResult == MOVEMENT_CONTROLLER_MOVE_NEXT then
        local oldIndex = self.selectedIndex
        local index = zo_clamp(self.selectedIndex + 1, 1, #self.buttons)

        self:SetSelectedButton(index)

        if oldIndex ~= index then
            PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED)
        end
    elseif horizontalResult == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        local oldIndex = self.selectedIndex
        local index = zo_clamp(self.selectedIndex - 1, 1, #self.buttons)

        self:SetSelectedButton(index)

        if oldIndex ~= index then
            PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED)
        end
    end
end

function ZO_GamepadButtonTabBar:SetSelectedButton(index)
    if index ~= self.selectedIndex then
        local oldIndex = self.selectedIndex
        if oldIndex and self.onUnselectedCallback then
            self.onUnselectedCallback(self.buttons[oldIndex])
        end

        self.selectedIndex = index
        if index then
            self.onSelectedCallback(self.buttons[index])
        end
    end
end

function ZO_GamepadButtonTabBar:IsActivated()
    return self.isActivated
end