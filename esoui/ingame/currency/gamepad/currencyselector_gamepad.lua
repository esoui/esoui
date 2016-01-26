ZO_CURRENCY_SELECTOR_BUTTON_ANIMATION_DURATION_GAMEPAD = 25

local DEGREE_THRESHOLD =  30 * (math.pi / 180)
local MAGNITUDE_THRESHOLD = 0.1

local g_directionalInputX, g_directionalInputY = 0, 0

-- ZO_CurrencySelector_Gamepad's horizontal movement and ZO_Spinner_Gamepad's vertical movement share a MagnitudeQuery function in order to bias sensitivity to vertical movement over horizontal movement
local function MagnitudeQuery(direction)
    if direction == GAMEPAD_SPINNER_DIRECTION_VERTICAL then
        -- Reset g_directionalInputX, g_directionalInputY when MagnitudeQuery is called from ZO_Spinner_Gamepad, values carry over for ZO_CurrencySelector_Gamepad
        g_directionalInputX, g_directionalInputY = DIRECTIONAL_INPUT:GetXY(ZO_DI_LEFT_STICK)
    end

    if direction == GAMEPAD_SPINNER_DIRECTION_VERTICAL and math.abs(g_directionalInputY) < MAGNITUDE_THRESHOLD then
        g_directionalInputY = DIRECTIONAL_INPUT:GetY(ZO_DI_DPAD)
        return g_directionalInputY
    elseif direction == MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL and math.abs(g_directionalInputX) < MAGNITUDE_THRESHOLD then
        g_directionalInputX = DIRECTIONAL_INPUT:GetX(ZO_DI_DPAD)
        return -g_directionalInputX
    end

    local angle = math.atan2(g_directionalInputY, g_directionalInputX)
    local absAngle = math.abs(angle)
    
    if direction == GAMEPAD_SPINNER_DIRECTION_VERTICAL then
        if absAngle >= DEGREE_THRESHOLD and absAngle <= math.pi - DEGREE_THRESHOLD then
            -- When there is vertical movement, the horizontal movement is consumed to ensure that pressing the L-stick at an angle doesn't cause horizontal and vertical movement
            g_directionalInputX = 0
            return g_directionalInputY
        else
            g_directionalInputY = DIRECTIONAL_INPUT:GetY(ZO_DI_DPAD)
            return g_directionalInputY
        end
    else
        if absAngle < DEGREE_THRESHOLD or absAngle > math.pi - DEGREE_THRESHOLD then
            g_directionalInputY = 0
            return -g_directionalInputX
        else
            g_directionalInputX = DIRECTIONAL_INPUT:GetX(ZO_DI_DPAD)
            return -g_directionalInputX
        end
    end
end

-----------------------
-- Digit Spinner
-----------------------

local ZO_CurrencySelectorDigitSpinner_Gamepad = ZO_Spinner_Gamepad:Subclass()

function ZO_CurrencySelectorDigitSpinner_Gamepad:New(...)
    return ZO_Spinner_Gamepad.New(self, ...)
end

function ZO_CurrencySelectorDigitSpinner_Gamepad:Initialize(control, min, max, isGamepad, spinnerMode, accelerationTime, magnitudeQueryFunction, owner)
    ZO_Spinner_Gamepad.Initialize(self, control, min, max, isGamepad, spinnerMode, accelerationTime, magnitudeQueryFunction)
    self.owner = owner
end

do
    local MOVEMENT_RELEASED = true

    function ZO_CurrencySelectorDigitSpinner_Gamepad:OnButtonUp()
        ZO_Spinner_Gamepad.OnButtonUp(self)
        self.atMaxAccelerationFactor = false
        self.owner:AnimateButtons(nil, nil, MOVEMENT_RELEASED)
    end
end

-----------------------
-- Digit
-----------------------

local ZO_CurrencySelectorDigit_Gamepad = ZO_Object:Subclass()

function ZO_CurrencySelectorDigit_Gamepad:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_CurrencySelectorDigit_Gamepad:Initialize(control, valueChangedCallback)
    self.control = control
    self.color = ZO_SELECTED_TEXT
    self.alpha = 1

    self.decrease = self.control:GetNamedChild("Decrease")
    self.increase = self.control:GetNamedChild("Increase")
    self.display = self.control:GetNamedChild("Display")

    local ACCELERATION_TIME = 250
    self.spinner = ZO_CurrencySelectorDigitSpinner_Gamepad:New(self.control, 0, 9, GAMEPAD_SPINNER_DIRECTION_VERTICAL, SPINNER_MODE_WRAP, ACCELERATION_TIME, MagnitudeQuery, self)
    self.spinner:SetValue(0)

    self.buttonUpAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_GamepadCurrencySelector_ButtonBumpUpAnimation", self.increase)
    self.buttonDownAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_GamepadCurrencySelector_ButtonBumpDownAnimation", self.decrease)
    self.playUpAnimBackwardsFunction = function() self.buttonUpAnimation:PlayBackward() end
    self.playDownAnimBackwardsFunction = function() self.buttonDownAnimation:PlayBackward() end

    self.spinner:RegisterCallback("OnValueChanged", valueChangedCallback)

    self:Deactivate()
end

function ZO_CurrencySelectorDigit_Gamepad:SetHidden(hidden)
    self.control:SetHidden(hidden)
end

function ZO_CurrencySelectorDigit_Gamepad:SetValue(value)
    self.spinner:SetValue(value)
end

function ZO_CurrencySelectorDigit_Gamepad:GetValue()
    return self.spinner:GetValue()
end

function ZO_CurrencySelectorDigit_Gamepad:SetAlpha(alpha)
    self.alpha = alpha
    self:UpdateTextColor()
end

function ZO_CurrencySelectorDigit_Gamepad:SetTextColor(color)
    self.color = color
    self:UpdateTextColor()
end

function ZO_CurrencySelectorDigit_Gamepad:UpdateTextColor()
    local r, g, b = self.color:UnpackRGB()
    self.display:SetColor(r, g, b, self.alpha)
end

function ZO_CurrencySelectorDigit_Gamepad:SetActive(active)
    self.spinner:SetButtonsHidden(not active)

    if active then
        self.spinner:Activate()
    else
        self.spinner:Deactivate()
    end

    self.display:SetFont(active and "ZoFontGamepad42" or "ZoFontGamepad34")
end

function ZO_CurrencySelectorDigit_Gamepad:Activate()
    self:SetActive(true)
end

function ZO_CurrencySelectorDigit_Gamepad:Deactivate()
    self:SetActive(false)
end

function ZO_CurrencySelectorDigit_Gamepad:AnimateButtons(previousValue, newValue, buttonReleased)
    if previousValue ~= newValue then
        if self.spinner:IsAtMaxAccelerationFactor() then
            if not self.isUpButtonAnimatedOut or not self.isDownButtonAnimatedOut then
                if g_directionalInputY > 0 then
                    self.buttonUpAnimation:PlayForward()
                    self.isUpButtonAnimatedOut = true
                elseif g_directionalInputY < 0 then
                    self.buttonDownAnimation:PlayForward()
                    self.isDownButtonAnimatedOut = true
                end
            end
        else
            if g_directionalInputY > 0 or g_directionalInputX < 0 then
                self.buttonUpAnimation:PlayForward()
                zo_callLater(self.playUpAnimBackwardsFunction, ZO_CURRENCY_SELECTOR_BUTTON_ANIMATION_DURATION_GAMEPAD)
            elseif g_directionalInputY < 0 or g_directionalInputX > 0 then
                self.buttonDownAnimation:PlayForward()
                zo_callLater(self.playDownAnimBackwardsFunction, ZO_CURRENCY_SELECTOR_BUTTON_ANIMATION_DURATION_GAMEPAD)
            end
        end
    elseif buttonReleased then
        if self.isUpButtonAnimatedOut then
            self.buttonUpAnimation:PlayBackward()
            self.isUpButtonAnimatedOut = false
        elseif self.isDownButtonAnimatedOut then
            self.buttonDownAnimation:PlayBackward()
            self.isDownButtonAnimatedOut = false
        end
    end
end

-----------------------
-- Currency Selector
-----------------------

ZO_CurrencySelector_Gamepad = ZO_CallbackObject:Subclass()

function ZO_CurrencySelector_Gamepad:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_CurrencySelector_Gamepad:Initialize(control)
    self.control = control
    self.valueIsDirty = true

    local function OnValueChangedCallback()
        local value = self:GetValue()
        local max = self:GetMaxValue()
        local hasEnough = value <= max
        
        if self.clampGreaterThanMax and (not hasEnough) then
            self:SetValue(max)
            hasEnough = true
        end
        
        self:UpdateDigits()
        if self.currentDigit then
            self.currentDigit:AnimateButtons(self.previousValue, self.value)
            self.previousValue = self.value
        end
        self.valueIsDirty = true
        self:SetTextColor(hasEnough and ZO_SELECTED_TEXT or ZO_ERROR_COLOR)
        self:FireCallbacks("OnValueChanged")
    end

    self.digits =
    {
        ZO_CurrencySelectorDigit_Gamepad:New(self.control:GetNamedChild("Ones"), OnValueChangedCallback),
        ZO_CurrencySelectorDigit_Gamepad:New(self.control:GetNamedChild("Tens"), OnValueChangedCallback),
        ZO_CurrencySelectorDigit_Gamepad:New(self.control:GetNamedChild("Hundreds"), OnValueChangedCallback),
        ZO_CurrencySelectorDigit_Gamepad:New(self.control:GetNamedChild("Thousands"), OnValueChangedCallback),
        ZO_CurrencySelectorDigit_Gamepad:New(self.control:GetNamedChild("TenThousands"), OnValueChangedCallback),
        ZO_CurrencySelectorDigit_Gamepad:New(self.control:GetNamedChild("HundredThousands"), OnValueChangedCallback),
        ZO_CurrencySelectorDigit_Gamepad:New(self.control:GetNamedChild("Millions"), OnValueChangedCallback),
        ZO_CurrencySelectorDigit_Gamepad:New(self.control:GetNamedChild("TenMillions"), OnValueChangedCallback),
        ZO_CurrencySelectorDigit_Gamepad:New(self.control:GetNamedChild("HundredMillions"), OnValueChangedCallback),
        ZO_CurrencySelectorDigit_Gamepad:New(self.control:GetNamedChild("Billions"), OnValueChangedCallback),
    }
    self.spacers =
    {
        self.control:GetNamedChild("Spacer1"),
        self.control:GetNamedChild("Spacer2"),
        self.control:GetNamedChild("Spacer3"),
    }
    self.movementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL, nil, MagnitudeQuery)

    local NUMBER_TICKS_TO_START_ACCELERATING = 2
    local ACCELERATION_MAGNITUDE_FACTOR = 5
    self.movementController:SetNumTicksToStartAccelerating(NUMBER_TICKS_TO_START_ACCELERATING)
    self.movementController:SetAccelerationMagnitudeFactor(ACCELERATION_MAGNITUDE_FACTOR)

    self.previousValue = 0
end

function ZO_CurrencySelector_Gamepad:SetTextColor(color)
    for _, digit in pairs(self.digits) do
        digit:SetTextColor(color)
    end
end

function ZO_CurrencySelector_Gamepad:SetValue(value)
    if self.clampGreaterThanMax and value > self.maxValue then
        self.value = self.maxValue
    else
        self.value = value
    end

    for i=1, #self.digits do
        local thisDigit = value % 10
        self.digits[i]:SetValue(thisDigit)
        value = (value - thisDigit) / 10
    end

    self:UpdateDigits()
end

function ZO_CurrencySelector_Gamepad:GetValue()
    if self.valueIsDirty then
        local total = 0
        local digitValue = 1
        for i=1, #self.digits do
            if self.digits[i]:GetValue() ~= 0 then
                total = total + self.digits[i]:GetValue() * digitValue
            end
            digitValue = digitValue * 10
        end
        self.value = total
    end
    return self.value
end

local ENABLED_DIGIT_ALPHA = 1
local DISABLED_DIGIT_ALPHA = 0.2

function ZO_CurrencySelector_Gamepad:UpdateDigits()
    local firstEnabledDigit = 1
    for i=#self.digits, 2, -1 do
        if self.digits[i]:GetValue() ~= 0 then
            firstEnabledDigit = i
            break
        end
    end

    for i=1, #self.digits do
        self.digits[i]:SetAlpha(firstEnabledDigit >= i and ENABLED_DIGIT_ALPHA or DISABLED_DIGIT_ALPHA)
    end

    for i=1, #self.spacers do
        local nextDigit = i * 3 + 1
        self.spacers[i]:SetColor(1, 1, 1, firstEnabledDigit >= nextDigit and ENABLED_DIGIT_ALPHA or DISABLED_DIGIT_ALPHA)
    end
end

function ZO_CurrencySelector_Gamepad:GetMaxValue()
    return self.maxValue
end

function ZO_CurrencySelector_Gamepad:SetMaxValue(maxValue)
    if self.maxValue == nil or self.maxValue ~= maxValue then
        self.maxValue = maxValue

        local numDigits = self:CalculateNumDigits()

        -- If we are showing then only update the digits if it is larger.
        -- This way we won't have to clamp which might confuse the user.
        if self.control:IsHidden() then
            self.maxDigits = numDigits
        else
            if numDigits > (self.maxDigits or 0) then
                self.maxDigits = numDigits
                self:UpdateDigitVisibility()
            end
        end
    end
end

function ZO_CurrencySelector_Gamepad:SetClampValues(clampGreaterThanMax)
    self.clampGreaterThanMax = clampGreaterThanMax
end

function ZO_CurrencySelector_Gamepad:CalculateNumDigits()
    local maxValue = self.maxValue or 0

    local numDigits = 0
    repeat
        numDigits = numDigits + 1
        maxValue = zo_floor(maxValue / 10)
    until maxValue <= 0

    return numDigits
end

function ZO_CurrencySelector_Gamepad:UpdateDigitVisibility()
    for i=1, #self.digits do
        self.digits[i]:SetHidden(i > self.maxDigits)
    end

    for i=1, #self.spacers do
        local nextDigit = i * 3 + 1
        self.spacers[i]:SetHidden(nextDigit > self.maxDigits)
    end
end

function ZO_CurrencySelector_Gamepad:Clear()
    for i=1, #self.digits do
        self.digits[i]:SetValue(0)
    end
end

function ZO_CurrencySelector_Gamepad:Activate()
    if not self.maxValue then
        self:SetMaxValue(0)
    end

    DIRECTIONAL_INPUT:Activate(self, self.control)
    self:UpdateDigitVisibility()
    self:SetActiveDigit(1)
    self:UpdateDigits()
end

function ZO_CurrencySelector_Gamepad:Deactivate()
    if self.currentDigit then
        self.currentDigit:Deactivate()
        self.currentDigit = nil
    end
    DIRECTIONAL_INPUT:Deactivate(self)
end

function ZO_CurrencySelector_Gamepad:SetActiveDigit(index)
    if index > #self.digits or index > self.maxDigits then
        if self.clampGreaterThanMax then
            self:SetValue(self.maxValue)
        end
        return
    elseif index < 1 then
        self:SetValue(0)
        return
    end

    self.currentDigitIndex = index

    if self.currentDigit then
        self.currentDigit:Deactivate()
    end
    self.currentDigit = self.digits[index]
    self.currentDigit:Activate()
end

function ZO_CurrencySelector_Gamepad:UpdateDirectionalInput()
    local result = self.movementController:CheckMovement()
    if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
        self:SetActiveDigit(self.currentDigitIndex - 1)
    elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        self:SetActiveDigit(self.currentDigitIndex + 1)
    end
end