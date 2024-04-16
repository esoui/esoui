ZO_ATTRIBUTE_BAR_POWER_SHIELD_NO_HEALING_LEVEL = 1000
ZO_ATTRIBUTE_BAR_POWER_SHIELD_LEVEL = 2000
ZO_ATTRIBUTE_BAR_POWER_SHIELD_TRAUMA_LEVEL = 3000
ZO_ATTRIBUTE_BAR_POWER_SHIELD_TRAUMA_GLOSS_LEVEL = 3001
ZO_ATTRIBUTE_BAR_POWER_SHIELD_FAKE_HEALTH_LEVEL = 4000
ZO_ATTRIBUTE_BAR_POWER_SHIELD_FAKE_HEALTH_GLOSS_LEVEL = 4001
ZO_ATTRIBUTE_BAR_POWER_SHIELD_FAKE_NO_HEALING_OUTER_LEVEL = 5000
ZO_ATTRIBUTE_BAR_POWER_SHIELD_FAKE_NO_HEALING_INNER_LEVEL = 5001

local FULL_ALPHA_VALUE = 1
local FADED_ALPHA_VALUE = 0.3

local RELEVANT_VISUAL_TYPES =
{
    ATTRIBUTE_VISUAL_POWER_SHIELDING,
    ATTRIBUTE_VISUAL_TRAUMA,
    ATTRIBUTE_VISUAL_NO_HEALING,
}

ZO_UnitVisualizer_PowerShieldModule = ZO_UnitAttributeVisualizerModuleBase:Subclass()

function ZO_UnitVisualizer_PowerShieldModule:New(...)
    return ZO_UnitAttributeVisualizerModuleBase.New(self, ...)
end

function ZO_UnitVisualizer_PowerShieldModule:Initialize(layoutData)
    self.layoutData = layoutData
end

function ZO_UnitVisualizer_PowerShieldModule:CreateInfoTable(control, oldInfo, stat, attribute, power)
    if control then
        local info = oldInfo or { visualInfo = {} }

        for _, visualType in ipairs(RELEVANT_VISUAL_TYPES) do
            if not info.visualInfo[visualType] then
                info.visualInfo[visualType] = {}
            end
            local visualInfo = info.visualInfo[visualType]

            visualInfo.value, visualInfo.maxValue = self:GetInitialValueAndMarkMostRecent(visualType, stat, attribute, power)
            if visualInfo.lastValue == nil then
                visualInfo.lastValue = 0
            end
        end

        return info
    end
    return nil
end

function ZO_UnitVisualizer_PowerShieldModule:OnAdded(healthBarControl, magickaBarControl, staminaBarControl)
    self.attributeBarControls =
    {
        [ATTRIBUTE_HEALTH] = healthBarControl,
    }

    if IsPlayerActivated() then
        self:InitializeBarValues()
    end

    local function OnSizeChanged(resizing, bar, size)
        if bar == healthBarControl then
            local info = self.attributeInfo and self.attributeInfo[ATTRIBUTE_HEALTH]
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
    local healthBarControl = self.attributeBarControls[ATTRIBUTE_HEALTH]

    local oldBarInfo = self.attributeInfo
    self.attributeInfo =
    {
        [ATTRIBUTE_HEALTH] = self:CreateInfoTable(healthBarControl, oldBarInfo and oldBarInfo[ATTRIBUTE_HEALTH], STAT_MITIGATION, ATTRIBUTE_HEALTH, COMBAT_MECHANIC_FLAGS_HEALTH),
    }

    for attribute, bar in pairs(self.attributeBarControls) do
        local barInfo = self.attributeInfo[attribute]
        for visualType, _ in pairs(barInfo.visualInfo) do
            self:OnValueChanged(bar, barInfo, visualType)
        end
    end
end

function ZO_UnitVisualizer_PowerShieldModule:OnUnitChanged()
    self:InitializeBarValues()
end

function ZO_UnitVisualizer_PowerShieldModule:OnUpdate()
    if self.attributeInfo then
        for attribute, info in pairs(self.attributeInfo) do
            if info.isResizing then
                self:UpdateValue(self.attributeBarControls[attribute], info)
            end
        end
    end
end

function ZO_UnitVisualizer_PowerShieldModule:IsUnitVisualRelevant(visualType, stat, attribute, powerType)
    if self.attributeInfo == nil or self.attributeInfo[attribute] == nil then
        return false
    end

    for _, currentVisualType in ipairs(RELEVANT_VISUAL_TYPES) do
        if visualType == currentVisualType then
            return true
        end
    end

    return false
end

function ZO_UnitVisualizer_PowerShieldModule:OnUnitAttributeVisualAdded(visualType, stat, attribute, powerType, value, maxValue)
    local barInfo = self.attributeInfo[attribute]
    local info = barInfo.visualInfo[visualType]
    local barControl = self.attributeBarControls[attribute]
    info.value = info.value + value
    info.maxValue = info.maxValue + maxValue
    self:OnValueChanged(barControl, barInfo, visualType)
    self:DoAlphaUpdate(IsUnitInGroupSupportRange(self:GetUnitTag()))
end

function ZO_UnitVisualizer_PowerShieldModule:OnUnitAttributeVisualUpdated(visualType, stat, attribute, powerType, oldValue, newValue, oldMaxValue, newMaxValue)
    local barInfo = self.attributeInfo[attribute]
    local info = barInfo.visualInfo[visualType]
    info.value = info.value + (newValue - oldValue)
    info.maxValue = info.maxValue + (newMaxValue - oldMaxValue)
    self:OnValueChanged(self.attributeBarControls[attribute], barInfo, visualType)
end

function ZO_UnitVisualizer_PowerShieldModule:OnUnitAttributeVisualRemoved(visualType, stat, attribute, powerType, value, maxValue)
    local barInfo = self.attributeInfo[attribute]
    local info = barInfo.visualInfo[visualType]
    local barControl = self.attributeBarControls[attribute]
    info.value = info.value - value
    info.maxValue = info.maxValue - maxValue
    self:OnValueChanged(barControl, barInfo, visualType)
end

local function ApplyPlatformStyleToShield(left, right, leftOverlay, rightOverlay)
    ApplyTemplateToControl(left, ZO_GetPlatformTemplate(leftOverlay))
    if rightOverlay then
        ApplyTemplateToControl(right, ZO_GetPlatformTemplate(rightOverlay))
    end
end

local LEFT_BAR, RIGHT_BAR = 1, 2
local SHIELD_COLOR_GRADIENT = { ZO_ColorDef:New(.5, .5, 1, .3), ZO_ColorDef:New(.25, .25, .5, .5) }
local TRAUMA_COLOR_GRADIENT = { ZO_ColorDef:New("ab1c6473"), ZO_ColorDef:New("ab76bcc3") }
local NO_HEALING_FILL_COLOR_GRADIENT = { ZO_ColorDef:New("1a0909"), ZO_ColorDef:New("1a0909") }
local NO_HEALING_FILL_GROUP_FRAME_COLOR_GRADIENT = { ZO_ColorDef:New("501212"), ZO_ColorDef:New("501212") }
local NO_HEALING_BORDER_COLOR_GRADIENT = { ZO_ColorDef:New("da3030"), ZO_ColorDef:New("722323") }

function ZO_UnitVisualizer_PowerShieldModule:ShowOverlay(attributeBar, info)
    if not info.overlayControls then
        local leftStatusBar, rightStatusBar = unpack(attributeBar.barControls)

        local shieldLeftOverlay = CreateControlFromVirtual("$(parent)PowerShieldLeftOverlay", attributeBar, self.layoutData.barLeftOverlayTemplate)
        local shieldRightOverlay = (rightStatusBar and self.layoutData.barRightOverlayTemplate) and CreateControlFromVirtual("$(parent)PowerShieldRightOverlay", attributeBar, self.layoutData.barRightOverlayTemplate)

        info.overlayControls = { shieldLeftOverlay, shieldRightOverlay }

        local noHealingFillGradient
        if self.layoutData.noHealingGradientOverride then
            noHealingFillGradient = self.layoutData.noHealingGradientOverride
        elseif rightStatusBar then
            noHealingFillGradient = NO_HEALING_FILL_COLOR_GRADIENT
        else
            noHealingFillGradient = NO_HEALING_FILL_GROUP_FRAME_COLOR_GRADIENT
        end

        local fakeHealthGradient = self.layoutData.fakeHealthGradientOverride or ZO_POWER_BAR_GRADIENT_COLORS[COMBAT_MECHANIC_FLAGS_HEALTH]

        for _, overlay in ipairs(info.overlayControls) do
            ZO_StatusBar_SetGradientColor(overlay, SHIELD_COLOR_GRADIENT)
            ZO_StatusBar_SetGradientColor(overlay.traumaBar, TRAUMA_COLOR_GRADIENT)
            ZO_StatusBar_SetGradientColor(overlay.fakeHealthBar, fakeHealthGradient)
            ZO_StatusBar_SetGradientColor(overlay.noHealingInner, noHealingFillGradient)
            ZO_StatusBar_SetGradientColor(overlay.fakeNoHealingInner, noHealingFillGradient)
            if overlay.noHealingOuter and overlay.fakeNoHealingOuter then
                ZO_StatusBar_SetGradientColor(overlay.noHealingOuter, NO_HEALING_BORDER_COLOR_GRADIENT)
                ZO_StatusBar_SetGradientColor(overlay.fakeNoHealingOuter, NO_HEALING_BORDER_COLOR_GRADIENT)
            end
            overlay:SetValue(1)
        end

        leftStatusBar:SetHandler("OnMinMaxValueChanged", function(_, min, max)
            info.attributeMax = max
            self:OnStatusBarValueChanged(attributeBar, info)
        end, "PowerShield")

        leftStatusBar:SetHandler("OnValueChanged", function(_, value)
            info.attributeValue = value
            self:OnStatusBarValueChanged(attributeBar, info)
        end, "PowerShield")

        info.attributeMax = select(2, leftStatusBar:GetMinMax())
        info.attributeValue = leftStatusBar:GetValue()
    end

    ApplyPlatformStyleToShield(info.overlayControls[LEFT_BAR], info.overlayControls[RIGHT_BAR], self.layoutData.barLeftOverlayTemplate, self.layoutData.barRightOverlayTemplate)

    self:GetOwner():NotifyTakingControlOf(attributeBar)
    self:GetOwner():NotifyEndingControlOf(attributeBar)
end

function ZO_UnitVisualizer_PowerShieldModule:ShouldHideBar(barInfo)
    for _, visualInfo in pairs(barInfo.visualInfo) do
        if visualInfo.value > 0 then
            return false
        end
    end
    return true
end

function ZO_UnitVisualizer_PowerShieldModule:ApplyValueToBar(attributeBar, barInfo, leftControl, rightControl, value)
    local percentOfBarRequested = zo_clamp(value / barInfo.attributeMax, 0, 1.0)
    -- arbitrary hardcoded threshold to avoid "too-small" values
    if percentOfBarRequested <= .01 then
        leftControl:SetHidden(true)
        if rightControl then 
            rightControl:SetHidden(true)
        end
        return
    else
        leftControl:SetHidden(false)
        if rightControl then
            rightControl:SetHidden(false)
        end
    end

    local leftAttributeBar, rightAttributeBar = unpack(attributeBar.barControls)
    local halfWidth = leftAttributeBar:GetWidth()
    local leftOffsetX = halfWidth * (1 - percentOfBarRequested)

    if rightControl and rightAttributeBar then
        leftControl:ClearAnchors()
        leftControl:SetAnchor(LEFT, leftAttributeBar, LEFT, leftOffsetX, 0)
        leftControl:SetAnchor(RIGHT, leftAttributeBar, RIGHT)

        rightControl:ClearAnchors()
        rightControl:SetAnchor(RIGHT, rightAttributeBar, RIGHT, -leftOffsetX, 0)
        rightControl:SetAnchor(LEFT, rightAttributeBar, LEFT)
    else
        -- In the case that we only have a single bar, that bar grows left-to-right.
        leftControl:ClearAnchors()
        leftControl:SetAnchor(RIGHT, leftAttributeBar, RIGHT, -leftOffsetX, 0)
        leftControl:SetAnchor(LEFT, leftAttributeBar, RIGHT, -halfWidth, 0)
    end
end

function ZO_UnitVisualizer_PowerShieldModule:OnStatusBarValueChanged(attributeBar, barInfo)
    local shieldInfo, traumaInfo, noHealingInfo = barInfo.visualInfo[ATTRIBUTE_VISUAL_POWER_SHIELDING], barInfo.visualInfo[ATTRIBUTE_VISUAL_TRAUMA], barInfo.visualInfo[ATTRIBUTE_VISUAL_NO_HEALING]
    local leftOverlay, rightOverlay = unpack(barInfo.overlayControls)
    if not self:ShouldHideBar(barInfo) then
        -- This math just establishes the relationships between each bar: the clamping and scaling to turn these into actual control positions happens in ApplyValueToBar().
        -- Each bar is drawn on top of the last one in the sequence, so the actual amount of each bar the player will see will always be distance between the last bar and the next.

        -- These are the source values: we work a half-scale because we apply one half of the value's magnitude on each side of the total bar.
        -- We don't do this for health because the parent attribute bar provides us with half-values.
        -- The anti-healing status is binary; if its value is positive, the overlay is on, otherwise it's off.
        local health = barInfo.attributeValue
        local shield = shieldInfo.value
        local trauma = traumaInfo.value
        local noHealing = noHealingInfo.value

        -- In the case where we're a brand new visualizer on a unit with an already extant visualized effect, it's possible for us to not have a max health value. In that case, we'll try to grab it from the bar.
        if attributeBar.barControls[ATTRIBUTE_HEALTH].max and barInfo.attributeMax ~= attributeBar.barControls[ATTRIBUTE_HEALTH].max then
            barInfo.attributeMax = attributeBar.barControls[ATTRIBUTE_HEALTH].max
        end

        if rightOverlay then
            shield = shield * .5
            trauma = trauma * .5
        end

        -- Shields add to your original health bar, so they grow out of that value.
        -- When that amount extends beyond your max health we need shrink your fakehealth to compensate, which we carry over as shieldOverflow
        local shieldBarSize = health + shield
        self:ApplyValueToBar(attributeBar, barInfo, leftOverlay, rightOverlay, shieldBarSize)
        local shieldOverflow = zo_max(0, shieldBarSize - barInfo.attributeMax)

        -- Trauma starts at your current health value, minus any shield overflow.
        -- This means that you should perceive the size of this bar as being your "health", it just needs to be overhealed before you can benefit from extra heal.
        local traumaBarSize = health - shieldOverflow
        self:ApplyValueToBar(attributeBar, barInfo, leftOverlay.traumaBar, rightOverlay and rightOverlay.traumaBar, traumaBarSize)

        -- Then the fakehealth starts at the step 2 interpretation of health minus any trauma experienced.
        -- Sometimes trauma and shield overflow will be 0, in which case this value is the same as your actual health, otherwise it shrinks to fit each effect.
        local fakeHealthSize = traumaBarSize - trauma
        self:ApplyValueToBar(attributeBar, barInfo, leftOverlay.fakeHealthBar, rightOverlay and rightOverlay.fakeHealthBar, fakeHealthSize)

        -- The anti-healing overlay always matches the current health value if it's on.
        local noHealingSize = noHealing > 0 and health or 0
        self:ApplyValueToBar(attributeBar, barInfo, leftOverlay.noHealingInner, rightOverlay and rightOverlay.noHealingInner, noHealingSize)
        if leftOverlay.noHealingOuter then
            self:ApplyValueToBar(attributeBar, barInfo, leftOverlay.noHealingOuter, rightOverlay and rightOverlay.noHealingOuter, noHealingSize)
        end

        local fakeNoHealingSize = noHealing > 0 and fakeHealthSize or 0
        self:ApplyValueToBar(attributeBar, barInfo, leftOverlay.fakeNoHealingInner, rightOverlay and rightOverlay.fakeNoHealingInner, fakeNoHealingSize)
        if leftOverlay.fakeNoHealingOuter then
            self:ApplyValueToBar(attributeBar, barInfo, leftOverlay.fakeNoHealingOuter, rightOverlay and rightOverlay.fakeNoHealingOuter, fakeNoHealingSize)
        end
    else
        leftOverlay:SetHidden(true)
        if rightOverlay then
            rightOverlay:SetHidden(true)
        end
    end
end

function ZO_UnitVisualizer_PowerShieldModule:UpdateValue(attributeBar, info)
    if info.overlayControls then
        self:OnStatusBarValueChanged(attributeBar, info)
    end
end

local STATE_GAINED_SOUND_FOR_VISUAL_TYPE =
{
    [ATTRIBUTE_VISUAL_POWER_SHIELDING] = STAT_STATE_SHIELD_GAINED,
    [ATTRIBUTE_VISUAL_TRAUMA] = STAT_STATE_TRAUMA_GAINED,
    --TODO AntiHealing: Add sound for anti-healing?
}

local STATE_LOST_SOUND_FOR_VISUAL_TYPE =
{
    [ATTRIBUTE_VISUAL_POWER_SHIELDING] = STAT_STATE_SHIELD_LOST,
    [ATTRIBUTE_VISUAL_TRAUMA] = STAT_STATE_TRAUMA_LOST,
    --TODO AntiHealing: Add sound for anti-healing?
}

function ZO_UnitVisualizer_PowerShieldModule:OnValueChanged(attributeBar, barInfo, visualType)
    local visualInfo = barInfo.visualInfo[visualType]
    local value = visualInfo.value
    local lastValue = visualInfo.lastValue
    visualInfo.lastValue = value

    if value > 0 and lastValue <= 0 then
        self:ShowOverlay(attributeBar, barInfo)
        self.owner:PlaySoundFromStat(STAT_MITIGATION, STATE_GAINED_SOUND_FOR_VISUAL_TYPE[visualType])
        TriggerTutorial(TUTORIAL_TRIGGER_COMBAT_STATUS_EFFECT)
    elseif value <= 0 and lastValue > 0 then
        self.owner:PlaySoundFromStat(STAT_MITIGATION, STATE_LOST_SOUND_FOR_VISUAL_TYPE[visualType])
    end

    self:UpdateValue(attributeBar, barInfo)
end

function ZO_UnitVisualizer_PowerShieldModule:ApplyPlatformStyle()
    if IsPlayerActivated() then
        for attribute, bar in pairs(self.attributeBarControls) do
            local barInfo = self.attributeInfo and self.attributeInfo[attribute]
            if barInfo and barInfo.overlayControls then
                ApplyPlatformStyleToShield(barInfo.overlayControls[LEFT_BAR], barInfo.overlayControls[RIGHT_BAR], self.layoutData.barLeftOverlayTemplate, self.layoutData.barRightOverlayTemplate)
            end
            for visualType in pairs(barInfo.visualInfo) do
                self:OnValueChanged(bar, barInfo, visualType)
            end
        end
    end
end

function ZO_UnitVisualizer_PowerShieldModule:DoAlphaUpdate(isNearby)
    if IsPlayerActivated() then
        for attribute, bar in ipairs(self.attributeBarControls) do
            local barInfo = self.attributeInfo and self.attributeInfo[attribute]
            if barInfo and barInfo.overlayControls then
                for _, overlay in pairs(barInfo.overlayControls) do
                    local alpha = isNearby and FULL_ALPHA_VALUE or FADED_ALPHA_VALUE
                    overlay:SetAlpha(alpha)
                end
            end
        end
    end
end