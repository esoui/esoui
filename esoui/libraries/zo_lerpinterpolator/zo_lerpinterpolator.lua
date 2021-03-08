local DEFAULT_APPROACH_FACTOR = 7 / 60

ZO_LerpInterpolator = ZO_InitializingObject:Subclass()

function ZO_LerpInterpolator:Initialize(initialValue)
    self.currentValue = initialValue
    self.targetBase = initialValue
    self.resetValue = initialValue
    self.approachFactor = DEFAULT_APPROACH_FACTOR
end

function ZO_LerpInterpolator:SetApproachFactor(approachFactor)
    self.approachFactor = approachFactor
end

local NO_PARAMS = {}
function ZO_LerpInterpolator:SetFluxParams(params)
    params = params or NO_PARAMS

    if params.fluxMin then
        self.targetBase = (params.fluxMin + params.fluxMax) / 2
        self.fluxMagnitude = (params.fluxMax - params.fluxMin) / 2 -- half up, half down
    else
        self.targetBase = params.base
        self.fluxMagnitude = params.fluxMagnitude
    end
    self.fluxPeriodSeconds = params.fluxPeriodSeconds
    self.fluxEasingFunction = params.fluxEasingFunction or ZO_EaseInOutZeroToOneToZero
    self.fluxPhase = params.fluxPhase
    self.useRandomFlux = params.useRandomFlux

    if self.targetBase == nil then
        self.targetBase = self.resetValue
    end
    if self.currentValue == nil then
        self.currentValue = self.targetBase
    end
end

function ZO_LerpInterpolator:SetUpdateHandler(updateHandler)
    self.updateHandler = updateHandler
end

function ZO_LerpInterpolator:SetCurrentValue(currentValue)
    self.currentValue = currentValue
end

function ZO_LerpInterpolator:SetTargetBase(targetBase)
    self.targetBase = targetBase
    if self.currentValue == nil then
        self.currentValue = self.targetBase
    end
end

function ZO_LerpInterpolator:SetFluxFunction(fluxFunction)
    self.fluxFunction = fluxFunction
end

function ZO_LerpInterpolator:Update(timeSecs)
    local fluxMagnitude = self.fluxMagnitude or 0

    if not (self.currentValue == self.targetBase and fluxMagnitude == 0) then
        local targetFinal = self.targetBase
        if fluxMagnitude ~= 0 then
            local fluxPeriodSeconds = self.fluxPeriodSeconds or 2
            local fluxPhase = self.fluxPhase or 0

            local normalizedTime = (timeSecs / fluxPeriodSeconds) + fluxPhase
            local progress = normalizedTime % 1
            local flux 
            if self.useRandomFlux then
                local period = math.floor(normalizedTime)
                -- this implements a sample-and-hold like pattern;
                -- every period we will sample a random value and hold it until the next period
                -- if you'd like something less jumpy, use the approach factor to smooth it out
                if self.lastPeriod == nil or period > self.lastPeriod then
                    flux = math.random() * 2 - 1 -- convert from 0-1 to -1-1
                    self.lastRandomFlux = flux
                    self.lastPeriod = period
                else
                    flux = self.lastRandomFlux
                end
            else
                flux = self.fluxEasingFunction(progress) * 2 - 1 -- convert from 0-1 to -1-1
            end
            targetFinal = targetFinal + flux * fluxMagnitude
        end

        self.currentValue = zo_deltaNormalizedLerp(self.currentValue, targetFinal, self.approachFactor)
        if zo_floatsAreEqual(self.currentValue, targetFinal) then
            self.currentValue = targetFinal
        end
    end

    if self.updateHandler then
        self.updateHandler(self.currentValue)
    end

    return self.currentValue
end