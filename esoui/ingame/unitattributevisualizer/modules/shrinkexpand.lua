ZO_UnitVisualizer_ShrinkExpandModule = ZO_UnitAttributeVisualizerModuleBase:Subclass()

function ZO_UnitVisualizer_ShrinkExpandModule:New(...)
    return ZO_UnitAttributeVisualizerModuleBase.New(self, ...)
end

function ZO_UnitVisualizer_ShrinkExpandModule:Initialize(normalWidth, expandedWidth, shrunkWidth)
    self.normalWidth = normalWidth
    self.expandedWidth = expandedWidth
    self.shrunkWidth = shrunkWidth
end

local function GetInitialStatValue(unitTag, stat, attribute, powerType)
    return (GetUnitAttributeVisualizerEffectInfo(unitTag, ATTRIBUTE_VISUAL_INCREASED_MAX_POWER, stat, attribute, powerType) or 0)
         + (GetUnitAttributeVisualizerEffectInfo(unitTag, ATTRIBUTE_VISUAL_DECREASED_MAX_POWER, stat, attribute, powerType) or 0)
end

function ZO_UnitVisualizer_ShrinkExpandModule:CreateAnimation(control, stat)
    local animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ShrinkExpandAnimation", control.warnerContainer)
    animation:GetAnimation(1):SetAnimatedControl(control)
    animation:GetAnimation(2):SetAnimatedControl(control.bgContainer)

    local function OnPlay()
        if control.warner then
            control.warner:SetPaused(true)
        end
        self:GetOwner():NotifyTakingControlOf(control)
    end
    animation:SetHandler("OnPlay", OnPlay)

    local function OnStop()
        local info = self.barInfo[stat]
        self:GetOwner():FireCallbacks("AttributeBarSizeChangingStopped", control, info.state)

        self:GetOwner():NotifyEndingControlOf(control)
        if control.warner then
            control.warner:SetPaused(false)
        end
    end
    animation:SetHandler("OnStop", OnStop)

    return animation
end

function ZO_UnitVisualizer_ShrinkExpandModule:CreateInfoTable(control, oldBarInfo, stat, attribute, power)
    if control then
        local oldInfo = oldBarInfo and oldBarInfo[stat]
        if oldInfo then
            oldInfo.value = GetInitialStatValue(self:GetUnitTag(), stat, attribute, power)
            return oldInfo
        end

        local animation = self:CreateAnimation(control, stat)
        return { value = GetInitialStatValue(self:GetUnitTag(), stat, attribute, power), animation = animation, state = ATTRIBUTE_BAR_STATE_NORMAL }
    end
    return nil
end

function ZO_UnitVisualizer_ShrinkExpandModule:OnAdded(healthBarControl, magickaBarControl, staminaBarControl)
    self.barControls =
    {
        [STAT_HEALTH_MAX] = healthBarControl,
        [STAT_MAGICKA_MAX] = magickaBarControl,
        [STAT_STAMINA_MAX] = staminaBarControl,
    }

    if IsPlayerActivated() then
        self:InitializeBarValues()
    end

    EVENT_MANAGER:RegisterForEvent("ZO_UnitVisualizer_ShrinkExpandModule" .. self:GetModuleId(), EVENT_PLAYER_ACTIVATED, function() self:InitializeBarValues() end)
end

function ZO_UnitVisualizer_ShrinkExpandModule:InitializeBarValues()
    local healthBarControl = self.barControls[STAT_HEALTH_MAX]
    local magickaBarControl = self.barControls[STAT_MAGICKA_MAX]
    local staminaBarControl = self.barControls[STAT_STAMINA_MAX]

    local oldBarInfo = self.barInfo
    self.barInfo =
    {
        [STAT_HEALTH_MAX] = self:CreateInfoTable(healthBarControl, oldBarInfo, STAT_HEALTH_MAX, ATTRIBUTE_HEALTH, POWERTYPE_HEALTH),
        [STAT_MAGICKA_MAX] = self:CreateInfoTable(magickaBarControl, oldBarInfo, STAT_MAGICKA_MAX, ATTRIBUTE_MAGICKA, POWERTYPE_MAGICKA),
        [STAT_STAMINA_MAX] = self:CreateInfoTable(staminaBarControl, oldBarInfo, STAT_STAMINA_MAX, ATTRIBUTE_STAMINA, POWERTYPE_STAMINA),
    }

    for stat, bar in pairs(self.barControls) do
        self:OnValueChanged(bar, self.barInfo[stat], stat, ANIMATION_INSTANT)
    end
end

function ZO_UnitVisualizer_ShrinkExpandModule:OnUnitChanged()
    self:InitializeBarValues()
end

function ZO_UnitVisualizer_ShrinkExpandModule:IsUnitVisualRelevant(visualType, stat, attribute, powerType)
    if visualType == ATTRIBUTE_VISUAL_INCREASED_MAX_POWER or visualType == ATTRIBUTE_VISUAL_DECREASED_MAX_POWER then
        return self.barInfo 
           and self.barInfo[stat] ~= nil
    end
    return false
end

function ZO_UnitVisualizer_ShrinkExpandModule:OnUnitAttributeVisualAdded(visualType, stat, attribute, powerType, value)
    self.barInfo[stat].value = self.barInfo[stat].value + value
    self:OnValueChanged(self.barControls[stat], self.barInfo[stat], stat)
end

function ZO_UnitVisualizer_ShrinkExpandModule:OnUnitAttributeVisualUpdated(visualType, stat, attribute, powerType, oldValue, newValue)
    self.barInfo[stat].value = self.barInfo[stat].value + (newValue - oldValue)
    self:OnValueChanged(self.barControls[stat], self.barInfo[stat], stat)
end

function ZO_UnitVisualizer_ShrinkExpandModule:OnUnitAttributeVisualRemoved(visualType, stat, attribute, powerType, value)
    self.barInfo[stat].value = self.barInfo[stat].value - value
    self:OnValueChanged(self.barControls[stat], self.barInfo[stat], stat)
end

function ZO_UnitVisualizer_ShrinkExpandModule:TryChangingState(bar, info)
    if info.value > 0 then
        if info.state ~= ATTRIBUTE_BAR_STATE_EXPANDED then
            return ATTRIBUTE_BAR_STATE_EXPANDED, self.expandedWidth, self.expandedWidth
        end
    elseif info.value < 0 then
        if info.state ~= ATTRIBUTE_BAR_STATE_SHRUNK then
            return ATTRIBUTE_BAR_STATE_SHRUNK, self.shrunkWidth, self.shrunkWidth
        end
    elseif info.state ~= ATTRIBUTE_BAR_STATE_NORMAL then
        return ATTRIBUTE_BAR_STATE_NORMAL, self.normalWidth, self.normalWidth
    end
end

function ZO_UnitVisualizer_ShrinkExpandModule:OnValueChanged(bar, info, stat, instant)
    local newState, targetBarWidth, targetBGWidth = self:TryChangingState(bar, info, stat)
    if targetBarWidth then           
        if instant then
            info.animation:Stop()
            info.state = newState
            self:GetOwner():FireCallbacks("AttributeBarSizeChangingStart", bar, info.state, true)
            self:GetOwner():FireCallbacks("AttributeBarSizeChangingStart", bar.bgContainer, info.state, true)
            bar:SetWidth(targetBarWidth)
            bar.bgContainer:SetWidth(targetBGWidth)
            self:GetOwner():FireCallbacks("AttributeBarSizeChangingStopped", bar, info.state)
            self:GetOwner():FireCallbacks("AttributeBarSizeChangingStopped", bar.bgContainer, info.state)
        else
            info.state = newState
            info.animation:GetAnimation(1):SetStartAndEndWidth(bar:GetWidth(), targetBarWidth)
            info.animation:GetAnimation(2):SetStartAndEndWidth(bar.bgContainer:GetWidth(), targetBGWidth)
            info.animation:PlayFromStart()
            self:GetOwner():FireCallbacks("AttributeBarSizeChangingStart", bar, info.state)
            self:GetOwner():FireCallbacks("AttributeBarSizeChangingStart", bar.bgContainer, info.state)
            self.owner:PlaySoundFromStat(stat, info.state)
        end
    end
end