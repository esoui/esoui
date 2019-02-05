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

function ZO_GamepadSlider:SetValueWithSound(targetValue)
    local oldValue = self:GetValue()
    self:SetValue(targetValue)
    local newValue = self:GetValue()
    if oldValue ~= newValue then
        PlaySound(SOUNDS.DEFAULT_CLICK)
    end
end

function ZO_GamepadSlider:MoveLeft()
    self:SetValueWithSound(self:GetValue() - self:GetValueStep())
end

function ZO_GamepadSlider:MoveRight()
    self:SetValueWithSound(self:GetValue() + self:GetValueStep())
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

--[[ Gamepad Constrained Slider ]]--

-- Adds functionality that can constrain a slider from going past a specified min or max, that is independent of the min/max values of the slider itself.
-- This is useful when having two sliders such as for min/max values, and not wanting them to
-- Be able to push beyond the other slider's value (Min slider blocks max slider from going to low and vice versa)

ZO_GamepadConstrainedSlider = {}

function ZO_GamepadConstrainedSlider:SetValueConstraints(minValueFunction, maxValueFunction)
    self.minValueFunction = minValueFunction
    self.maxValueFunction = maxValueFunction
end

function ZO_GamepadConstrainedSlider:MoveLeft()
    local prevValue = self:GetValue() - self:GetValueStep()

    if self.minValueFunction then
        prevValue = math.max(prevValue, self.minValueFunction())
    end
    
    self:SetValueWithSound(prevValue)
end

function ZO_GamepadConstrainedSlider:MoveRight()
    local nextValue = self:GetValue() + self:GetValueStep()
    
    if self.maxValueFunction then
        nextValue = math.min(nextValue, self.maxValueFunction())
    end
    
    self:SetValueWithSound(nextValue)
end

function ZO_GamepadConstrainedSlider_OnInitialized(control)
    zo_mixin(control, ZO_GamepadSlider)
    zo_mixin(control, ZO_GamepadConstrainedSlider)
    control:Initialize()
end
