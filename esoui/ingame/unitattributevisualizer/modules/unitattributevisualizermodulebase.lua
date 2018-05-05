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

function ZO_UnitAttributeVisualizerModuleBase:GetMostRecentUpdate(visualType, stat, attribute, powerType)
    if self.updateRecencyInfo then
        local visualTypeInfo = self.updateRecencyInfo[visualType]
        if visualTypeInfo then
            local statInfo = visualTypeInfo[stat]
            if statInfo then
                local attributeInfo = statInfo[attribute]
                if attributeInfo then
                    local existingSequenceId = attributeInfo[powerType]
                    return existingSequenceId
                end
            end
        end    
    end
end


function ZO_UnitAttributeVisualizerModuleBase:GetInitialValueAndMarkMostRecent(visualType, stat, attribute, powerType)
    local value, maxValue, sequenceId = GetUnitAttributeVisualizerEffectInfo(self:GetUnitTag(), visualType, stat, attribute, powerType)
    if value then
        --if there is an active UAV of this type return its info and mark that we updated to that sequenceId so we can ignore any older events
        self:SetMostRecentUpdate(visualType, stat, attribute, powerType, sequenceId)
        return value, maxValue
    else
        --otherwise clear out the UAV sequenceId since there is no active effect
        self:SetMostRecentUpdate(visualType, stat, attribute, powerType, nil)
        return 0, 0
    end
end

function ZO_UnitAttributeVisualizerModuleBase:SetMostRecentUpdate(visualType, stat, attribute, powerType, sequenceId)
    if not self.updateRecencyInfo then
        self.updateRecencyInfo = {}
    end

    local visualTypeInfo = self.updateRecencyInfo[visualType]
    if not visualTypeInfo then
        visualTypeInfo = {}
        self.updateRecencyInfo[visualType] = visualTypeInfo
    end

    local statInfo = visualTypeInfo[stat]
    if not statInfo then
        statInfo = {}
        visualTypeInfo[stat] = statInfo
    end

    local attributeInfo = statInfo[attribute]
    if not attributeInfo then
        attributeInfo = {}
        statInfo[attribute] = attributeInfo
    end

    attributeInfo[powerType] = sequenceId
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