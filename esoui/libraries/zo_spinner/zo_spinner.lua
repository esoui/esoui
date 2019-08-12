ZO_Spinner = ZO_CallbackObject:Subclass()

SPINNER_MODE_CLAMP = 1
SPINNER_MODE_WRAP = 2

local SMALL_INCREMENT = 1
local LARGE_INCREMENT = 10

-- Wrap for arbitrary ranges including negative numbers
-- Does *not* support floats
local function WrapInt(value, min, max)
    return (zo_floor(value) - min) % (max - min + 1) + min
end

local function ClampInt(value, min, max, step)
    value = zo_roundToNearest(value, step)
    return zo_clamp(value, min, max)
end

function ZO_Spinner:New(...)
    local spinner = ZO_CallbackObject.New(self)
    spinner:Initialize(...)
    return spinner
end

local DEFAULT_ACCELERATION_TIME_MS = 350

function ZO_Spinner:Initialize(control, min, max, isGamepad, spinnerMode, accelerationTime)
    self.control = control

    self.decreaseButton = control:GetNamedChild("Decrease")
    self.increaseButton = control:GetNamedChild("Increase")

    self.display = control:GetNamedChild("Display")
    self.enabled = true
    self.mouseEnabled = true

    self.normalColor = ZO_SELECTED_TEXT
    self.errorColor = ZO_ERROR_COLOR
    
    if(isGamepad ~= true) then
        self:InitializeHandlers()
    end

    if spinnerMode == SPINNER_MODE_WRAP then
        self.constrainRangeFunc = WrapInt
    else 
        self.constrainRangeFunc = ClampInt
    end

    self.step = 1
    self.value = math.huge
    self:SetMinMax(min, max)

    self.spinnerUpSound = SOUNDS.SPINNER_UP
    self.spinnerDownSound = SOUNDS.SPINNER_DOWN

    self.accelerationTime = accelerationTime or DEFAULT_ACCELERATION_TIME_MS
end

local DIRECTION_INCREMENT = 1
local DIRECTION_DECREMENT = -1

function ZO_Spinner:InitializeHandlers()
    local function Increment() 
        self:OnButtonDown(DIRECTION_INCREMENT) 
    end

    local function Decrement() 
        self:OnButtonDown(DIRECTION_DECREMENT)
    end
    
    local function Release()
        self:OnButtonUp()
    end

    self.increaseButton:SetHandler("OnMouseDown", Increment)
    self.increaseButton:SetHandler("OnMouseDoubleClick", Increment)
    self.increaseButton:SetHandler("OnMouseUp", Release)

    self.decreaseButton:SetHandler("OnMouseDown", Decrement)
    self.decreaseButton:SetHandler("OnMouseDoubleClick", Decrement)
    self.decreaseButton:SetHandler("OnMouseUp", Release)

    local function OnMouseWheel(_, delta)
        self:OnMouseWheel(delta) 
    end
    self.control:SetHandler("OnMouseWheel", OnMouseWheel)

    if self.display and self.display:GetType() == CT_EDITBOX then
        self.display:SetHandler("OnFocusLost", function() self:OnFocusLost() end)
        self.display:SetHandler("OnMouseWheel", OnMouseWheel)
    end
end

function ZO_Spinner:SetNormalColor(normalColor)
    self.normalColor = normalColor
    self:UpdateDisplay()
end

function ZO_Spinner:SetErrorColor(errorColor)
    self.errorColor = errorColor
    self:UpdateDisplay()
end

function ZO_Spinner:SetFont(fontString)
    self.display:SetFont(fontString)
end

function ZO_Spinner:OnMouseWheel(delta)
    if self.enabled then
        self:ModifyValue((delta > 0 and DIRECTION_INCREMENT or DIRECTION_DECREMENT) * (IsShiftKeyDown() and LARGE_INCREMENT or SMALL_INCREMENT))
    end
end

function ZO_Spinner:OnFocusLost(delta)
    local text = self.display:GetText()
    local textAsNumber = tonumber(text)
    if not textAsNumber or not self:SetValue(textAsNumber) then
        self:UpdateDisplay()
    end
end

do
    local TIME_BETWEEN_MODIFIES = 1000
    local MAX_ACCEL_FACTOR = 25

    function ZO_Spinner:GetOnUpdateFunction()
        self.onUpdate = self.onUpdate or function()
            local now = GetGameTimeMilliseconds()
            local startDelta = now - self.startTime
            local accelerationFactor = zo_min(zo_floor(startDelta / self.accelerationTime) + 1, MAX_ACCEL_FACTOR)

            self.atMaxAccelerationFactor = accelerationFactor == MAX_ACCEL_FACTOR

            local delta = now - self.lastUpdate

            self.timeUntilNextModify = self.timeUntilNextModify - delta * accelerationFactor

            if self.timeUntilNextModify < 0 then
                self.timeUntilNextModify = self.timeUntilNextModify + TIME_BETWEEN_MODIFIES

                self:ModifyValue(self.direction * (IsShiftKeyDown() and LARGE_INCREMENT or SMALL_INCREMENT))
            end

            self.lastUpdate = now
        end
        return self.onUpdate
    end

    function ZO_Spinner:OnButtonDown(direction)
        self.direction = direction
        local now = GetGameTimeMilliseconds()
        self.startTime = now
        self.lastUpdate = now
        self.timeUntilNextModify = TIME_BETWEEN_MODIFIES

        self.control:SetHandler("OnUpdate", self:GetOnUpdateFunction())

        if IsShiftKeyDown() then
            self:ModifyValue(self.direction * LARGE_INCREMENT)
        else
            self:ModifyValue(self.direction * SMALL_INCREMENT)
        end
    end

    function ZO_Spinner:IsAtMaxAccelerationFactor()
        return self.atMaxAccelerationFactor
    end
end

function ZO_Spinner:OnButtonUp(direction)
    self.control:SetHandler("OnUpdate", nil)
end

--[[A function responsible to constraining a spinner to a set of valid values.
The function takes a value and a requested delta. It should return the value
plus the delta (the target value) if that is in the valid set. Otherwise it should
return the closest valid value to the the target value]]--
function ZO_Spinner:SetValidValuesFunction(validValuesFunction)
    self.validValuesFunction = validValuesFunction
end

function ZO_Spinner:SetStep(step)
    if self.step ~= step then
        self.step = step
        if not self:SetValue(self.value) then
            self:UpdateButtons()
        end
    end
end

function ZO_Spinner:GetStep()
    return self.step
end

function ZO_Spinner:SetMinMax(min, max)
    min = min or 0
    max = max or math.huge
    if self.min ~= min or self.max ~= max then
        self.min = min
        self.max = max

        if not self:SetValue(self.value) then
            self:UpdateButtons()
        end
    end
end

function ZO_Spinner:GetMin()
    if type(self.min) == "function" then
        return self.min(self)
    end
    return self.min
end

function ZO_Spinner:GetMax()
    if type(self.max) == "function" then
        return self.max(self)
    end
    return self.max
end

function ZO_Spinner:GetControl()
    return self.control
end

function ZO_Spinner:GetValue()
    return self.value
end

function ZO_Spinner:SetSoftMax(softMax)
    self.softMax = softMax
    self:UpdateDisplay()
end

function ZO_Spinner:GetSoftMax()
    return self.softMax
end

function ZO_Spinner:UpdateButtons()
    if self.hideButtons then
        self.increaseButton:SetHidden(true)
        self.decreaseButton:SetHidden(true)
    else
        self.increaseButton:SetHidden(false)
        self.decreaseButton:SetHidden(false)
        if not self.enabled then
            self.increaseButton:SetEnabled(false)
            self.decreaseButton:SetEnabled(false)
        else
            self.increaseButton:SetEnabled(self.value + self.step <= self:GetMax())
            self.decreaseButton:SetEnabled(self.value - self.step >= self:GetMin())
        end
    end    

    if self.display then
        if self.display:GetType() == CT_EDITBOX then
            if self:GetMax() == self:GetMin() or not self.enabled then
                self.display:SetMouseEnabled(false)
            else
                self.display:SetMouseEnabled(self.mouseEnabled)
            end
        end
    end

    self.control:SetMouseEnabled(self.mouseEnabled)
    self.increaseButton:SetMouseEnabled(self.mouseEnabled)
    self.decreaseButton:SetMouseEnabled(self.mouseEnabled)
end

function ZO_Spinner:SetMouseEnabled(mouseEnabled)
    self.mouseEnabled = mouseEnabled
    self:UpdateButtons()
end

function ZO_Spinner:SetValue(value, forceSet)
    if value ~= nil then
        value = self.constrainRangeFunc(value, self:GetMin(), self:GetMax(), self.step)

        if self.validValuesFunction then
            value = self.validValuesFunction(value, 0)
        end

        if (value ~= self.value) or forceSet then
            if value == 0 then
                -- protect against -0
                self.value = 0
            else
                self.value = value
            end
            self:UpdateDisplay()
            self:UpdateButtons()
            self:FireCallbacks("OnValueChanged", value)
            return true
        end
    end
    return false
end

function ZO_Spinner:UpdateDisplay()
    if self.display then
        local valueText
        if self.displayTextOverride then
            valueText = self.displayTextOverride
        elseif self.valueFormatFunction then
            valueText = self.valueFormatFunction(self.value)
        else
            valueText = self.value
        end
        self.display:SetText(valueText)
        if self.softMax and self.value > self.softMax then
            self.display:SetColor(self.errorColor:UnpackRGBA())
        else
            self.display:SetColor(self.normalColor:UnpackRGBA())
        end
    end
end

function ZO_Spinner:SetValueFormatFunction(valueFormatFunction)
    self.valueFormatFunction = valueFormatFunction
    self:UpdateDisplay()
end

function ZO_Spinner:SetDisplayTextOverride(displayTextOverride)
    self.displayTextOverride = displayTextOverride
    self:UpdateDisplay()
end

function ZO_Spinner:ModifyValue(change)
    if self.value then
        local targetValue = self.value + change * self.step
        if self.validValuesFunction then
            targetValue = self.validValuesFunction(self.value, change * self.step)
        end

        if(self:SetValue(targetValue)) then
            if(change > 0) then
                PlaySound(self.spinnerUpSound)
            else
                PlaySound(self.spinnerDownSound)
            end
        end
    end
end

function ZO_Spinner:SetEnabled(enabled)
    self.enabled = enabled
    self:UpdateButtons()
end

function ZO_Spinner:SetButtonsHidden(hideButtons)
    self.hideButtons = hideButtons
    self:UpdateButtons()
end

function ZO_Spinner:SetSounds(upSound, downSound)
    self.spinnerUpSound = upSound
    self.spinnerDownSound = downSound
end