--[[ Gamepad Options Slider ]]--
ZO_GamepadSlider = {}

function ZO_GamepadSlider:Initialize()
    self.movementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.movementController:SetAllowAcceleration(true)
end

function ZO_GamepadSlider:Activate()
    self:SetActive(true)
end

function ZO_GamepadSlider:Deactivate()
    self:SetActive(false)
end

function ZO_GamepadSlider:SetActive(active)
    if self.active ~= active then
        self.active= active
        if self.active then
            DIRECTIONAL_INPUT:Activate(self, self)
        else
            DIRECTIONAL_INPUT:Deactivate(self)
        end
    end
end

function ZO_GamepadSlider:UpdateDirectionalInput()
    local result = self.movementController:CheckMovement()
    if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
        self:MoveRight()
    elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        self:MoveLeft()
    end
end

function ZO_GamepadSlider:MoveLeft()
    local oldValue = self:GetValue()
    local prevValue = oldValue - self:GetValueStep()
    self:SetValue(prevValue)
    local newValue = self:GetValue()
    if oldValue ~= newValue then
        PlaySound(SOUNDS.DEFAULT_CLICK)
    end
end

function ZO_GamepadSlider:MoveRight()
    local oldValue = self:GetValue()
    local nextValue = oldValue + self:GetValueStep()
    self:SetValue(nextValue)
    local newValue = self:GetValue()
    if oldValue ~= newValue then
        PlaySound(SOUNDS.DEFAULT_CLICK)
    end
end

function ZO_GamepadSlider_OnInitialized(control)
    zo_mixin(control, ZO_GamepadSlider)
    control:Initialize()
end

function ZO_GamepadSlider_OnValueChanged(control, value)
    if control.valueChangedCallback then
        control.valueChangedCallback(control, value)
    end
end


--[[ Paired Slider ]]--

-- Adds functionality that blocks the slider from setting values outside of a specific paired slider's range.
-- This is useful when having two sliders such as for min/max values, and not wanting them to
-- Be able to push beyond the other slider's value (Min slider blocks max slider from going to low and vice versa)

ZO_GamepadPairedSlider = {}

function ZO_GamepadPairedSlider:SetMinPair(slider)
    self.minSlider = slider
end

function ZO_GamepadPairedSlider:SetMaxPair(slider)
    self.maxSlider = slider
end

function ZO_GamepadPairedSlider:MoveLeft()
    local prevValue = self:GetValue() - self:GetValueStep()

    if self.minSlider then
        if prevValue < self.minSlider:GetValue() then return end
    end
    
    self:SetValue(prevValue)
end

function ZO_GamepadPairedSlider:MoveRight()
    local nextValue = self:GetValue() + self:GetValueStep()
    
    if self.maxSlider then
        if nextValue > self.maxSlider:GetValue() then return end
    end
    
    self:SetValue(nextValue)
end

function ZO_GamepadPairedSlider_OnInitialized(control)
    zo_mixin(control, ZO_GamepadSlider)
    zo_mixin(control, ZO_GamepadPairedSlider)
    control:Initialize()
end
