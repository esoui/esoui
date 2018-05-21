STAT_STATE_INCREASE_GAINED = 1
STAT_STATE_INCREASE_LOST = 2
STAT_STATE_DECREASE_GAINED = 3
STAT_STATE_DECREASE_LOST = 4

STAT_STATE_IMMUNITY_GAINED = 1
STAT_STATE_IMMUNITY_LOST = 2
STAT_STATE_SHIELD_GAINED = 3
STAT_STATE_SHIELD_LOST = 4
STAT_STATE_POSSESSION_APPLIED = 5
STAT_STATE_POSSESSION_REMOVED = 6
STAT_STATE_TRAUMA_GAINED = 7
STAT_STATE_TRAUMA_LOST = 8

ATTRIBUTE_BAR_STATE_NORMAL = 1
ATTRIBUTE_BAR_STATE_EXPANDED = 2
ATTRIBUTE_BAR_STATE_SHRUNK = 3

ZO_UnitAttributeVisualizer = ZO_CallbackObject:Subclass()

function ZO_UnitAttributeVisualizer:New(...)
    local unitAttributeVisualizer = ZO_CallbackObject.New(self)
    unitAttributeVisualizer:Initialize(...)
    return unitAttributeVisualizer
end

function ZO_UnitAttributeVisualizer:Initialize(unitTag, soundTable, healthBarControl, magickaBarControl, staminaBarControl, externalControlCallback)
    self.unitTag = unitTag
    self.soundTable = soundTable

    self.visualModules = {}

    self.healthBarControl = healthBarControl
    self.magickaBarControl = magickaBarControl
    self.staminaBarControl = staminaBarControl

    self.moduleControlledCounts = {}
    if externalControlCallback then
        self.externalControlCallback = externalControlCallback
        if healthBarControl then
            self.moduleControlledCounts[healthBarControl] = 0
        end
        if magickaBarControl then
            self.moduleControlledCounts[magickaBarControl] = 0
        end
        if staminaBarControl then
            self.moduleControlledCounts[staminaBarControl] = 0
        end
    end

    local eventNamespace = "ZO_UnitAttributeVisualizer" .. unitTag
    EVENT_MANAGER:RegisterForEvent(eventNamespace, EVENT_UNIT_ATTRIBUTE_VISUAL_ADDED, function(eventCode, ...) self:OnUnitAttributeVisualAdded(...) end)
    EVENT_MANAGER:AddFilterForEvent(eventNamespace, EVENT_UNIT_ATTRIBUTE_VISUAL_ADDED, REGISTER_FILTER_UNIT_TAG, self.unitTag)
    EVENT_MANAGER:RegisterForEvent(eventNamespace, EVENT_UNIT_ATTRIBUTE_VISUAL_UPDATED, function(eventCode, ...) self:OnUnitAttributeVisualUpdated(...) end)
    EVENT_MANAGER:AddFilterForEvent(eventNamespace, EVENT_UNIT_ATTRIBUTE_VISUAL_UPDATED, REGISTER_FILTER_UNIT_TAG, self.unitTag)
    EVENT_MANAGER:RegisterForEvent(eventNamespace, EVENT_UNIT_ATTRIBUTE_VISUAL_REMOVED, function(eventCode, ...) self:OnUnitAttributeVisualRemoved(...) end)
    EVENT_MANAGER:AddFilterForEvent(eventNamespace, EVENT_UNIT_ATTRIBUTE_VISUAL_REMOVED, REGISTER_FILTER_UNIT_TAG, self.unitTag)

    if unitTag == "reticleover" then
        local function OnReticleTargetChanged()
            self:OnUnitChanged()
        end
        EVENT_MANAGER:RegisterForEvent(eventNamespace, EVENT_RETICLE_TARGET_CHANGED, OnReticleTargetChanged)
    elseif unitTag == "target" then
        local function OnTargetChanged(evt, unitTag)
            self:OnUnitChanged()
        end

        EVENT_MANAGER:RegisterForEvent(eventNamespace, EVENT_TARGET_CHANGED, OnTargetChanged)
        EVENT_MANAGER:AddFilterForEvent(eventNamespace, EVENT_TARGET_CHANGED, REGISTER_FILTER_UNIT_TAG, "player")
    end
end

function ZO_UnitAttributeVisualizer:OnUnitChanged()
    if DoesUnitExist(self.unitTag) then
        for module in pairs(self.visualModules) do
            module:OnUnitChanged()
        end
    end
end

function ZO_UnitAttributeVisualizer:AddModule(module)
    if not self.visualModules[module] then
        module:SetOwner(self)
        module:OnAdded(self.healthBarControl, self.magickaBarControl, self.staminaBarControl)

        self.visualModules[module] = module
    end
end

function ZO_UnitAttributeVisualizer:NotifyTakingControlOf(control)
    if self.moduleControlledCounts and self.moduleControlledCounts[control] then
        self.moduleControlledCounts[control] = self.moduleControlledCounts[control] + 1
        self.externalControlCallback(control, 1, self.moduleControlledCounts[control])
    end
end

function ZO_UnitAttributeVisualizer:NotifyEndingControlOf(control)
    if self.moduleControlledCounts and self.moduleControlledCounts[control] then
        self.moduleControlledCounts[control] = self.moduleControlledCounts[control] - 1
        self.externalControlCallback(control, -1, self.moduleControlledCounts[control])
    end
end

function ZO_UnitAttributeVisualizer:GetUnitTag()
    return self.unitTag
end

function ZO_UnitAttributeVisualizer:OnUnitAttributeVisualAdded(unitTag, visualType, stat, attribute, powerType, value, maxValue, sequenceId)
    for module in pairs(self.visualModules) do
        if module:IsUnitVisualRelevant(visualType, stat, attribute, powerType) then
            local mostRecentUpdate = module:GetMostRecentUpdate(visualType, stat, attribute, powerType)
            --if we have no UAV info for this type then we can add it 
            if mostRecentUpdate == nil then
                module:OnUnitAttributeVisualAdded(visualType, stat, attribute, powerType, value, maxValue)
                module:SetMostRecentUpdate(visualType, stat, attribute, powerType, sequenceId)
            end
        end
    end
end

function ZO_UnitAttributeVisualizer:OnUnitAttributeVisualUpdated(unitTag, visualType, stat, attribute, powerType, oldValue, newValue, oldMaxValue, newMaxValue, sequenceId)
    for module in pairs(self.visualModules) do
        if module:IsUnitVisualRelevant(visualType, stat, attribute, powerType) then
            local mostRecentUpdate = module:GetMostRecentUpdate(visualType, stat, attribute, powerType)
            --make sure that we haven't already got the new state info that comes with this event as part of the UAV initializing on EVENT_PLAYER_ACTIVATED
            if mostRecentUpdate ~= nil and sequenceId > mostRecentUpdate then
                module:OnUnitAttributeVisualUpdated(visualType, stat, attribute, powerType, oldValue, newValue, oldMaxValue, newMaxValue)
                module:SetMostRecentUpdate(visualType, stat, attribute, powerType, sequenceId)
            end
        end
    end
end

function ZO_UnitAttributeVisualizer:OnUnitAttributeVisualRemoved(unitTag, visualType, stat, attribute, powerType, value, maxValue, sequenceId)
    for module in pairs(self.visualModules) do
        if module:IsUnitVisualRelevant(visualType, stat, attribute, powerType) then
            local mostRecentUpdate = module:GetMostRecentUpdate(visualType, stat, attribute, powerType)
            --make sure that we haven't already got the new state info that comes with this event as part of the UAV initializing on EVENT_PLAYER_ACTIVATED
            if mostRecentUpdate ~= nil and sequenceId > mostRecentUpdate then
                module:OnUnitAttributeVisualRemoved(visualType, stat, attribute, powerType, value, maxValue)
                module:SetMostRecentUpdate(visualType, stat, attribute, powerType, nil)
            end
        end
    end
end

function ZO_UnitAttributeVisualizer:PlaySoundFromStat(stat, state)
    if self.soundTable and self.soundTable[stat] and self.soundTable[stat][state] then
        PlaySound(self.soundTable[stat][state])
    end
end

function ZO_UnitAttributeVisualizer:ApplyPlatformStyle()
    for _, module in pairs(self.visualModules) do
        module:ApplyPlatformStyle()
    end
end