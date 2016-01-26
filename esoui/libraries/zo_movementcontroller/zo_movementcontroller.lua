ZO_MovementController = ZO_Object:Subclass()

--[[ Public  API ]]--
function ZO_MovementController:New(...)
    local movementController = ZO_Object.New(self)
    movementController:Initialize(...)
    return movementController
end

MOVEMENT_CONTROLLER_DIRECTION_VERTICAL = 1
MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL = 2

local function GetStickMagnitude(direction)
    if direction == MOVEMENT_CONTROLLER_DIRECTION_VERTICAL then
        return DIRECTIONAL_INPUT:GetY(ZO_DI_LEFT_STICK, ZO_DI_DPAD)
    end
    return -DIRECTIONAL_INPUT:GetX(ZO_DI_LEFT_STICK, ZO_DI_DPAD)
end

local NUM_TICKS_TO_START_ACCELERATING = 5
local ACCELERATION_MAGNTITUDE_FACTOR = 3

function ZO_MovementController:Initialize(direction, accumulationPerSecondForChange, magnitudeQueryFunctionOverride)
    self.direction = direction or MOVEMENT_CONTROLLER_DIRECTION_VERTICAL
    self.accumulationPerSecondForChange = accumulationPerSecondForChange or 8
    self.magnitudeQueryFunction = magnitudeQueryFunctionOverride or GetStickMagnitude

    self.totalAccumulation = 0
    self.debt = 0
    self.lastMagnitude = 0
    self.allowAcceleration = true
    self.numTicksToStartAccelerating = NUM_TICKS_TO_START_ACCELERATING
    self.accelerationMagnitudeFactor = ACCELERATION_MAGNTITUDE_FACTOR
end

function ZO_MovementController:SetAllowAcceleration(allowAcceleration)
    self.allowAcceleration = allowAcceleration
end

function ZO_MovementController:SetNumTicksToStartAccelerating(numTicks)
    self.numTicksToStartAccelerating = numTicks
end

function ZO_MovementController:SetAccelerationMagnitudeFactor(accelerationMagnitudeFactor)
    self.accelerationMagnitudeFactor = accelerationMagnitudeFactor
end

MOVEMENT_CONTROLLER_NO_CHANGE = 0
MOVEMENT_CONTROLLER_MOVE_NEXT = 1
MOVEMENT_CONTROLLER_MOVE_PREVIOUS = 2

local function IsChangingDirections(previousMagnitude, newMagnitude)
    return (previousMagnitude > 0 and newMagnitude < 0)
        or (previousMagnitude < 0 and newMagnitude > 0)
end

local ACCUMULATION_DEBT_PERCENT_AFTER_FIRST_SELECT = 1
local MIN_MAGNITUDE_FOR_ACCEL = .8
function ZO_MovementController:CheckMovement()
    local magnitude = self:GetMagnitude()
    if magnitude == 0 then
        self.totalAccumulation = 0
        self.isMovingFromAccumulation = false
        self.lastMagnitude = 0
    else
        if IsChangingDirections(self.lastMagnitude, magnitude) then
            -- reset moving state when changing a direction
            self.isMovingFromAccumulation = false
            self.lastMagnitude = magnitude

            -- consume this input, some devices will "flip back" when the stick is tapped in a direction
            -- this will help, but not eliminate that effect 
            return MOVEMENT_CONTROLLER_NO_CHANGE
        end

        if zo_abs(magnitude) < MIN_MAGNITUDE_FOR_ACCEL then
            self.numAccumulationTicks = 0
        end

        if self.isMovingFromAccumulation then
            local normalizedMagnitude = magnitude * GetFrameDeltaNormalizedForTargetFramerate()
            if self.debt > 0 then
                local absNormalizedMagnitude = zo_abs(normalizedMagnitude)

                -- Consume it all, nothing to do here
                if self.debt >= absNormalizedMagnitude then
                    self.debt = self.debt - absNormalizedMagnitude
                    return MOVEMENT_CONTROLLER_NO_CHANGE
                end

                normalizedMagnitude = normalizedMagnitude - self.debt * zo_sign(normalizedMagnitude)
                self.debt = 0
            end
            
            self.totalAccumulation = self.totalAccumulation + normalizedMagnitude * self:CalculateAccelerationFactor()
        else
            self.isMovingFromAccumulation = true
            self.numAccumulationTicks = 0
            self.totalAccumulation = magnitude > 0 and self.accumulationPerSecondForChange or -self.accumulationPerSecondForChange
            self.debt = zo_abs(self.totalAccumulation * ACCUMULATION_DEBT_PERCENT_AFTER_FIRST_SELECT)
        end

        self.lastMagnitude = magnitude

        if self.totalAccumulation >= self.accumulationPerSecondForChange then
            self.totalAccumulation = self.totalAccumulation - self.accumulationPerSecondForChange
            self.numAccumulationTicks = self.numAccumulationTicks + 1
            return MOVEMENT_CONTROLLER_MOVE_PREVIOUS
        elseif self.totalAccumulation <= -self.accumulationPerSecondForChange then
            self.totalAccumulation = self.totalAccumulation + self.accumulationPerSecondForChange
            self.numAccumulationTicks = self.numAccumulationTicks + 1
            return MOVEMENT_CONTROLLER_MOVE_NEXT
        end
    end

    return MOVEMENT_CONTROLLER_NO_CHANGE
end

--[[ Private API ]]--
function ZO_MovementController:GetMagnitude()
    return self.magnitudeQueryFunction(self.direction)
end

do
    local MAX_TICKS_TO_ACCEL_ACROSS = 30

    function ZO_MovementController:CalculateAccelerationFactor()
        if self.allowAcceleration then
            return 1.0 + ZO_EaseOutQuartic(zo_clampedPercentBetween(self.numTicksToStartAccelerating, MAX_TICKS_TO_ACCEL_ACROSS, self.numAccumulationTicks)) * self.accelerationMagnitudeFactor
        end
        return 1.0
    end
end