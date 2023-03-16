ZO_Spinner_Gamepad = ZO_Spinner:Subclass()

GAMEPAD_SPINNER_DIRECTION_VERTICAL = 1
GAMEPAD_SPINNER_DIRECTION_HORIZONTAL = 2

local function GetMagnitude(direction)
    if direction == GAMEPAD_SPINNER_DIRECTION_VERTICAL then
        return DIRECTIONAL_INPUT:GetY(ZO_DI_LEFT_STICK, ZO_DI_DPAD)
    end
    return DIRECTIONAL_INPUT:GetX(ZO_DI_LEFT_STICK, ZO_DI_DPAD)
end

function ZO_Spinner_Gamepad:Initialize(control, min, max, stickDirection, spinnerMode, accelerationTime, magnitudeQueryFunction)
    local IS_GAMEPAD = true
    ZO_Spinner.Initialize(self, control, min, max, IS_GAMEPAD, spinnerMode, accelerationTime)
    self.stickDirection = stickDirection or GAMEPAD_SPINNER_DIRECTION_HORIZONTAL
    self:SetActive(false)
    self.magnitudeQueryFunction = magnitudeQueryFunction or GetMagnitude
    self:SetCanNarrateTooltips(true)

    local function GetDirectionalInputNarrationData()
        --Only narrate directional input if there is more than one possible value
        if self:GetMin() ~= self:GetMax() then
            if self.stickDirection == GAMEPAD_SPINNER_DIRECTION_VERTICAL then
                if self.hideButtons or self.spinnerMode == SPINNER_MODE_WRAP then
                    return ZO_GetNumericVerticalDirectionalInputNarrationData()
                else
                    --Only include enabled state if the buttons are visible
                    return ZO_GetNumericVerticalDirectionalInputNarrationData(self:IsIncreaseEnabled(), self:IsDecreaseEnabled())
                end
            else
                if self.hideButtons or self.spinnerMode == SPINNER_MODE_WRAP then
                    return ZO_GetHorizontalDirectionalInputNarrationData()
                else
                    --Only include enabled state if the buttons are visible
                    local DEFAULT_LEFT_TEXT = nil
                    local DEFAULT_RIGHT_TEXT = nil
                    return ZO_GetHorizontalDirectionalInputNarrationData(DEFAULT_LEFT_TEXT, DEFAULT_RIGHT_TEXT, self:IsDecreaseEnabled(), self:IsIncreaseEnabled())
                end
            end
        else
            return {}
        end
    end

    self.directionalInputNarrationFunction = GetDirectionalInputNarrationData
end

function ZO_Spinner_Gamepad:SetActive(active)
    ZO_Spinner.SetEnabled(self, active)

    if self.active ~= active then
        self.active = active

        if self.active then
            self:FireCallbacks("OnActivated")
            DIRECTIONAL_INPUT:Activate(self, self.control)
        else
            if self.lastInput ~= nil then
                self:OnButtonUp()
                self.lastInput = nil
            end
            DIRECTIONAL_INPUT:Deactivate(self)
        end
    end
end

--Sets the name used for screen narration
function ZO_Spinner_Gamepad:SetName(name)
    self.name = name
end

function ZO_Spinner_Gamepad:GetName()
    return self.name
end

function ZO_Spinner_Gamepad:IsActive()
    return self.active
end

function ZO_Spinner_Gamepad:Activate()
    self:SetActive(true)
end

function ZO_Spinner_Gamepad:Deactivate()
    self:SetActive(false)
end

do
    local DIRECTION_INCREMENT = 1
    local DIRECTION_DECREMENT = -1
    local MAGNITUDE_THRESHOLD = 0.1

    function ZO_Spinner_Gamepad:UpdateDirectionalInput()
        local magnitude = self.magnitudeQueryFunction(self.stickDirection)

        local input = nil
        if magnitude > MAGNITUDE_THRESHOLD then
            input = DIRECTION_INCREMENT
        elseif magnitude < -MAGNITUDE_THRESHOLD then
            input = DIRECTION_DECREMENT
        end

        if input ~= self.lastInput then
            if self.lastInput ~= nil then
                self:OnButtonUp()
            end

            if input ~= nil then
                self:OnButtonDown(input)
            end

            self.lastInput = input
        end
    end
end

function ZO_Spinner_Gamepad:SetHeaderNarrationFunction(headerNarrationFunction)
    self.headerNarrationFunction = headerNarrationFunction
end

function ZO_Spinner_Gamepad:GetHeaderNarration()
    if self.headerNarrationFunction then
        return self.headerNarrationFunction()
    end
end

--Whether or not we should narrate visible tooltips when narrating this spinner
function ZO_Spinner_Gamepad:SetCanNarrateTooltips(canNarrateTooltips)
    self.canNarrateTooltips = canNarrateTooltips
end

function ZO_Spinner_Gamepad:CanNarrateTooltips()
    return self.canNarrateTooltips
end

--Used to set a custom narration function for this spinner
function ZO_Spinner_Gamepad:SetCustomNarrationFunction(narrationFunction)
    self.customNarrationFunction = narrationFunction
end

--Returns the narration for this spinner. If self.customNarrationFunction is set, it will generate the narration using that
function ZO_Spinner_Gamepad:GetNarrationText()
    if self.customNarrationFunction then
        return self.customNarrationFunction(self)
    else
        return ZO_FormatSpinnerNarrationText(self.name, self:GetFormattedValueText())
    end
end

function ZO_Spinner_Gamepad:GetAdditionalInputNarrationFunction()
    return self.directionalInputNarrationFunction
end