ZO_UnitAttributeVisualizerModuleBase = ZO_Object:Subclass()

local g_numModulesCreated = 0
function ZO_UnitAttributeVisualizerModuleBase:New(...)
    local module = ZO_Object.New(self)
    g_numModulesCreated = g_numModulesCreated + 1
    module.moduleId = g_numModulesCreated
    module:Initialize(...)
    return module
end

function ZO_UnitAttributeVisualizerModuleBase:GetModuleId()
    return self.moduleId
end

function ZO_UnitAttributeVisualizerModuleBase:SetOwner(owner)
    self.owner = owner
end

function ZO_UnitAttributeVisualizerModuleBase:GetOwner()
    return self.owner
end

function ZO_UnitAttributeVisualizerModuleBase:GetUnitTag()
    return self.owner and self.owner:GetUnitTag() or nil
end

function ZO_UnitAttributeVisualizerModuleBase:Initialize(...)
    -- Intended to be overridden
end

function ZO_UnitAttributeVisualizerModuleBase:IsUnitVisualRelevant(visualType, stat, attribute, powerType)
    -- Intended to be overridden
    -- Should return true if this module cares about this particular combination of types 
    return false
end

function ZO_UnitAttributeVisualizerModuleBase:OnAdded(healthBarControl, magickaBarControl, staminaBarControl)
    -- Intended to be overridden
    -- Called when this module is added to a visualizer
end

function ZO_UnitAttributeVisualizerModuleBase:OnUnitAttributeVisualAdded(visualType, stat, attribute, powerType, value, maxValue)
    -- Intended to be overridden
    -- Called when a unit visual is added and this particular combination of types passes the IsUnitVisualRelevant filter
end

function ZO_UnitAttributeVisualizerModuleBase:OnUnitAttributeVisualUpdated(visualType, stat, attribute, powerType, oldValue, newValue, oldMaxValue, newMaxValue)
    -- Intended to be overridden
    -- Called when a unit visual is updated and this particular combination of types passes the IsUnitVisualRelevant filter
end

function ZO_UnitAttributeVisualizerModuleBase:OnUnitAttributeVisualRemoved(visualType, stat, attribute, powerType, value, maxValue)
    -- Intended to be overridden
    -- Called when a unit visual is removed and this particular combination of types passes the IsUnitVisualRelevant filter
end

function ZO_UnitAttributeVisualizerModuleBase:OnUnitChanged()
    -- Intended to be overridden
    -- Called when the unit the unit tag points to has changed
end

function ZO_UnitAttributeVisualizerModuleBase:ApplyPlatformStyle()
    -- Intended to be overridden
    -- Called when gamepad preferred mode changes
end