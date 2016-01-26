ZO_UnitVisualizer_PowerShieldModule = ZO_UnitAttributeVisualizerModuleBase:Subclass()

function ZO_UnitVisualizer_PowerShieldModule:New(...)
    return ZO_UnitAttributeVisualizerModuleBase.New(self, ...)
end

function ZO_UnitVisualizer_PowerShieldModule:Initialize(layoutData)
    self.layoutData = layoutData
end

local function GetInitialStatValue(unitTag, stat, attribute, powerType)
    local value, maxValue =  GetUnitAttributeVisualizerEffectInfo(unitTag, ATTRIBUTE_VISUAL_POWER_SHIELDING, stat, attribute, powerType)
    return value or 0, maxValue or 0
end

function ZO_UnitVisualizer_PowerShieldModule:CreateInfoTable(control, oldBarInfo, stat, attribute, power)
    if control then
        local value, maxValue = GetInitialStatValue(self:GetUnitTag(), stat, attribute, power)
        local oldInfo = oldBarInfo and oldBarInfo[attribute]

        if oldInfo then
            oldInfo.value = value
            oldInfo.maxValue = maxValue
            return oldInfo
        end

        return { value = value, maxValue = maxValue, lastValue = 0, }
    end
    return nil
end

function ZO_UnitVisualizer_PowerShieldModule:OnAdded(healthBarControl, magickaBarControl, staminaBarControl)
    self.barControls =
    {
        [ATTRIBUTE_HEALTH] = healthBarControl,
    }

    if IsPlayerActivated() then
        self:InitializeBarValues()
    end

    local function OnSizeChanged(resizing, bar, size)
        if bar == healthBarControl then
            local info = self.barInfo and self.barInfo[ATTRIBUTE_HEALTH]
            if info then
                info.isResizing = resizing
            end
        end
    end

    local STARTING_RESIZE = true
    local STOPPING_RESIZE = false
    self:GetOwner():RegisterCallback("AttributeBarSizeChangingStart", function(...) OnSizeChanged(STARTING_RESIZE, ...) end)
    self:GetOwner():RegisterCallback("AttributeBarSizeChangingStopped", function(...) OnSizeChanged(STOPPING_RESIZE, ...) end)

    EVENT_MANAGER:RegisterForEvent("ZO_UnitVisualizer_PowerShieldModule" .. self:GetModuleId(), EVENT_PLAYER_ACTIVATED, function() self:InitializeBarValues() end)
    EVENT_MANAGER:RegisterForUpdate("ZO_UnitVisualizer_PowerShieldModule" .. self:GetModuleId(), 0, function() self:OnUpdate() end)
end

function ZO_UnitVisualizer_PowerShieldModule:InitializeBarValues()
    local healthBarControl = self.barControls[ATTRIBUTE_HEALTH]

    local oldBarInfo = self.barInfo
    self.barInfo =
    {
        [ATTRIBUTE_HEALTH] = self:CreateInfoTable(healthBarControl, oldBarInfo, STAT_MITIGATION, ATTRIBUTE_HEALTH, POWERTYPE_HEALTH),
    }

    for attribute, bar in pairs(self.barControls) do
        self:OnValueChanged(bar, self.barInfo[attribute])
    end
end

function ZO_UnitVisualizer_PowerShieldModule:OnUnitChanged()
    self:InitializeBarValues()
end

function ZO_UnitVisualizer_PowerShieldModule:OnUpdate()
    if self.barInfo then
        for stat, info in pairs(self.barInfo) do
            if info.isResizing then
                self:UpdateValue(self.barControls[stat], info)
            end
        end
    end
end

function ZO_UnitVisualizer_PowerShieldModule:IsUnitVisualRelevant(visualType, stat, attribute, powerType)
    if visualType == ATTRIBUTE_VISUAL_POWER_SHIELDING then
        return self.barInfo
           and self.barInfo[attribute] ~= nil
    end
    return false
end

function ZO_UnitVisualizer_PowerShieldModule:OnUnitAttributeVisualAdded(visualType, stat, attribute, powerType, value, maxValue)
    local info = self.barInfo[attribute]
    info.value = info.value + value
    info.maxValue = info.maxValue + maxValue
    self:OnValueChanged(self.barControls[attribute], info)
end

function ZO_UnitVisualizer_PowerShieldModule:OnUnitAttributeVisualUpdated(visualType, stat, attribute, powerType, oldValue, newValue, oldMaxValue, newMaxValue)
    local info = self.barInfo[attribute]
    info.value = info.value + (newValue - oldValue)
    info.maxValue = info.maxValue + (newMaxValue - oldMaxValue)
    self:OnValueChanged(self.barControls[attribute], info)
end

function ZO_UnitVisualizer_PowerShieldModule:OnUnitAttributeVisualRemoved(visualType, stat, attribute, powerType, value, maxValue)
    local info = self.barInfo[attribute]
    info.value = info.value - value
    info.maxValue = info.maxValue - maxValue
    self:OnValueChanged(self.barControls[attribute], info)
end

local function ApplyPlatformStyleToShield(left, right, leftOverlay, rightOverlay)
    if left then
        ApplyTemplateToControl(left, ZO_GetPlatformTemplate(leftOverlay))
    end

    if right then
        ApplyTemplateToControl(right, ZO_GetPlatformTemplate(rightOverlay))
    end
end

function ZO_UnitVisualizer_PowerShieldModule:PlayAnimation(bar, info)
    -- assumes a double health bar for now

    if not info.shieldLeftOverlay then
        local leftStatusBar = bar.barControls[1]
        local rightStatusBar = bar.barControls[2]

        local shieldColorGradient = { ZO_ColorDef:New(.5, .5, 1, .3), ZO_ColorDef:New(.25, .25, .5, .5) }

        local shieldLeftOverlay = CreateControlFromVirtual("$(parent)PowerShieldLeftOverlay", bar, self.layoutData.barLeftOverlayTemplate)
        ZO_StatusBar_SetGradientColor(shieldLeftOverlay, shieldColorGradient)
        shieldLeftOverlay:SetValue(1)
        ZO_StatusBar_SetGradientColor(shieldLeftOverlay.chunk, ZO_POWER_BAR_GRADIENT_COLORS[POWERTYPE_HEALTH])

        info.shieldLeftOverlay = shieldLeftOverlay

        local shieldRightOverlay = CreateControlFromVirtual("$(parent)PowerShieldRightOverlay", bar, self.layoutData.barRightOverlayTemplate)
        ZO_StatusBar_SetGradientColor(shieldRightOverlay, shieldColorGradient)
        shieldRightOverlay:SetValue(1)
        
        ZO_StatusBar_SetGradientColor(shieldRightOverlay.chunk, ZO_POWER_BAR_GRADIENT_COLORS[POWERTYPE_HEALTH])

        info.shieldRightOverlay = shieldRightOverlay

        ZO_PreHookHandler(leftStatusBar, "OnMinMaxValueChanged", function(_, min, max)
            info.statusMax = max
            self:OnStatusBarValueChanged(bar, info)
        end)

        ZO_PreHookHandler(leftStatusBar, "OnValueChanged", function(_, value)
            info.statusValue = value
            self:OnStatusBarValueChanged(bar, info)
        end)

        info.statusMax = select(2, leftStatusBar:GetMinMax())
        info.statusValue = leftStatusBar:GetValue()
    end

    ApplyPlatformStyleToShield(info.shieldLeftOverlay, info.shieldRightOverlay, self.layoutData.barLeftOverlayTemplate, self.layoutData.barRightOverlayTemplate)
    info.shieldLeftOverlay.chunk:SetAnchor(RIGHT, bar, CENTER)
    info.shieldRightOverlay.chunk:SetAnchor(LEFT, bar, CENTER)

    info.shieldLeftOverlay:SetHidden(false)
    info.shieldRightOverlay:SetHidden(false)

    self.owner:PlaySoundFromStat(STAT_MITIGATION, STAT_STATE_SHIELD_GAINED)
    TriggerTutorial(TUTORIAL_TRIGGER_COMBAT_STATUS_EFFECT)

    self:GetOwner():NotifyTakingControlOf(bar)
    self:GetOwner():NotifyEndingControlOf(bar)
end

function ZO_UnitVisualizer_PowerShieldModule:OnStatusBarValueChanged(bar, info)
    if info.value > 0 then
        local leftBar = bar.barControls[1]
        local rightBar = bar.barControls[2]

        local halfWidth = leftBar:GetWidth()
        local percentOfBarRequested = zo_min((info.value * .5) / info.statusMax, 1.0)
        local percentOfBarMissing = 1 - info.statusValue / info.statusMax

        local leftOffsetX = zo_max(halfWidth * percentOfBarMissing - halfWidth * percentOfBarRequested, 0)
        local rightOffsetX = zo_clamp(leftOffsetX + halfWidth * percentOfBarRequested + 11, 0, halfWidth)

        info.shieldLeftOverlay:SetAnchor(LEFT, leftBar, LEFT, leftOffsetX, 0)
        info.shieldLeftOverlay:SetAnchor(RIGHT, leftBar, LEFT, rightOffsetX, 0)

        info.shieldRightOverlay:SetAnchor(RIGHT, rightBar, RIGHT, -leftOffsetX, 0)
        info.shieldRightOverlay:SetAnchor(LEFT, rightBar, RIGHT, -rightOffsetX, 0)
    end
end

function ZO_UnitVisualizer_PowerShieldModule:UpdateValue(bar, info)
    if info.shieldLeftOverlay or info.shieldRightOverlay then
        self:OnStatusBarValueChanged(bar, info)
    end
end

function ZO_UnitVisualizer_PowerShieldModule:OnValueChanged(bar, info)
    local value = info.value
    local lastValue = info.lastValue
    info.lastValue = value

    if value > 0 and lastValue <= 0 then
        self:PlayAnimation(bar, info)
        self:UpdateValue(bar, info)
    elseif value <= 0 and lastValue > 0 then
        info.shieldLeftOverlay:SetHidden(true)
        info.shieldRightOverlay:SetHidden(true)

        self.owner:PlaySoundFromStat(STAT_MITIGATION, STAT_STATE_SHIELD_LOST)
    else
        self:UpdateValue(bar, info)
    end
end

function ZO_UnitVisualizer_PowerShieldModule:ApplyPlatformStyle()
    if self.barInfo then
        for _, info in pairs(self.barInfo) do
            ApplyPlatformStyleToShield(info.shieldLeftOverlay, info.shieldRightOverlay, self.layoutData.barLeftOverlayTemplate, self.layoutData.barRightOverlayTemplate)
        end
    end
end