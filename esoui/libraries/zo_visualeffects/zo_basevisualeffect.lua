local g_registeredEffectUpdates = {}

ZO_BaseVisualEffect = ZO_InitializingObject:Subclass()

function ZO_BaseVisualEffect:Initialize()
    -- Numerically indexed array of registered controls.
    self.controls = {}
    -- Non-numerically indexed table for which the keys are the registered controls
    -- and the values are their corresponding parameter tables.
    self.controlParameters = {}
    -- Non-numerically indexed for which the keys are the valid ControlType values (CT_ prefixed) that this effect can manage.
    self.validControlTypes = self:GetValidControlTypes()
    self.OnUpdateCallback = ZO_GetCallbackForwardingFunction(self, self.OnUpdate)
end

function ZO_BaseVisualEffect:GetControlParameters(control)
    return self.controlParameters[control]
end

function ZO_BaseVisualEffect:GetControls()
    return self.controls
end

function ZO_BaseVisualEffect:RegisterControl(control, ...)
    local parameterTable = self:CreateParameterTable(control, ...)
    if not parameterTable then
        -- The arguments specified were invalid.
        return false
    end

    if self.controlParameters[control] then
        -- Control is already registered; just update the parameters.
        self.controlParameters[control] = parameterTable
        return true
    end

    local controlType = control:GetType()
    if not self.validControlTypes[controlType] then
        internalassert(false, string.format("%s:RegisterControl: Invalid ControlType: %d", self:GetEffectName(), controlType))
        return false
    end

    self.controlParameters[control] = parameterTable
    table.insert(self.controls, control)
    self:OnControlRegistered(control)
    return true
end

function ZO_BaseVisualEffect:UnregisterControl(control)
    if self.controlParameters[control] == nil then
        return false
    end

    self.controlParameters[control] = nil
    ZO_RemoveFirstElementFromNumericallyIndexedTable(self.controls, control)
    self:OnControlUnregistered(control)
    return true
end

function ZO_BaseVisualEffect:OnControlRegistered()
    local effectName = self:GetEffectName()
    if not g_registeredEffectUpdates[effectName] then
        g_registeredEffectUpdates[effectName] = true
        EVENT_MANAGER:RegisterForUpdate("EffectUpdate_" .. effectName, 0, self.OnUpdateCallback)
    end
end

function ZO_BaseVisualEffect:OnControlUnregistered()
    if not next(self.controlParameters) then
        local effectName = self:GetEffectName()
        g_registeredEffectUpdates[effectName] = nil
        EVENT_MANAGER:UnregisterForUpdate("EffectUpdate_" .. effectName)
    end
end

-- Abstract Method Declarations

ZO_BaseVisualEffect.CreateParameterTable = ZO_BaseVisualEffect:MUST_IMPLEMENT()
ZO_BaseVisualEffect.GetEffectName = ZO_BaseVisualEffect:MUST_IMPLEMENT()
ZO_BaseVisualEffect.GetValidControlTypes = ZO_BaseVisualEffect:MUST_IMPLEMENT()
ZO_BaseVisualEffect.OnUpdate = ZO_BaseVisualEffect:MUST_IMPLEMENT()