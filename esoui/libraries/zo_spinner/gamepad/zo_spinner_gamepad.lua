ZO_Spinner_Gamepad = ZO_Spinner:Subclass()

function ZO_Spinner_Gamepad:New(...)
    return ZO_Spinner.New(self, ...)
end


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
end

function ZO_Spinner_Gamepad:SetActive(active)
    ZO_Spinner.SetEnabled(self, active)

    if self.active ~= active then
        self.active = active

        if self.active then
            DIRECTIONAL_INPUT:Activate(self, self.control)
        else
            if(self.lastInput ~= nil) then
                self:OnButtonUp()
                self.lastInput = nil
            end
            DIRECTIONAL_INPUT:Deactivate(self)
        end
    end
end

function ZO_Spinner_Gamepad:Activate()
    self:SetActive(true)
end

function ZO_Spinner_Gamepad:Deactivate()
    self:SetActive(false)
end

local DIRECTION_INCREMENT = 1
local DIRECTION_DECREMENT = -1

local MAGNITUDE_THRESHOLD = 0.1

function ZO_Spinner_Gamepad:UpdateDirectionalInput()
    local magnitude = self.magnitudeQueryFunction(self.stickDirection)

    local input = nil
    if(magnitude > MAGNITUDE_THRESHOLD) then
        input = DIRECTION_INCREMENT
    elseif(magnitude < -MAGNITUDE_THRESHOLD) then
        input = DIRECTION_DECREMENT
    end

    if(input ~= self.lastInput) then
        if(self.lastInput ~= nil) then
            self:OnButtonUp()
        end

        if(input ~= nil) then
            self:OnButtonDown(input)
        end

        self.lastInput = input
    end
end




