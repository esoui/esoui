local LERP_RATE = 7

ZO_LerpInterpolator = ZO_Object:Subclass()

function ZO_LerpInterpolator:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_LerpInterpolator:Initialize(initialValue)
    self.currentValue = initialValue
    self.targetBase = initialValue
    self.lerpRate = LERP_RATE
    self.initialValue = initialValue
end

function ZO_LerpInterpolator:SetLerpRate(lerpRate)
    self.lerpRate = lerpRate
end

function ZO_LerpInterpolator:SetParams(params)
    if params then
        self.targetBase = params.base
        self.fluxMagnitude = params.fluxMagnitude
        self.fluxRate = params.fluxRate
    else
        self.targetBase = nil
        self.fluxMagnitude = nil
        self.fluxRate = nil
    end
end

function ZO_LerpInterpolator:SetCurrentValue(currentValue)
    self.currentValue = currentValue
end

function ZO_LerpInterpolator:SetTargetBase(targetBase)
    self.targetBase = targetBase
end

function ZO_LerpInterpolator:Update(timeSecs, frameDeltaSecs)
    local fluxRate = self.fluxRate or 2
    local fluxMagnitude = self.fluxMagnitude or 0
    local targetBase = self.targetBase or self.initialValue

    if not (self.currentValue == targetBase and fluxMagnitude == 0) then
        local flux = 0
        if fluxMagnitude ~= 0 then
            flux = math.sin(timeSecs * fluxRate) * fluxMagnitude
        end

        local targetFinal = targetBase + flux
        self.currentValue = zo_lerp(self.currentValue, targetFinal, self.lerpRate * frameDeltaSecs)
        if zo_abs(self.currentValue - targetFinal) < 0.001 then
            self.currentValue = targetFinal
        end
    end

    return self.currentValue
end