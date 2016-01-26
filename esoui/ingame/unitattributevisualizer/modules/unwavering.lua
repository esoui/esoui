ZO_UnitVisualizer_UnwaveringModule = ZO_UnitAttributeVisualizerModuleBase:Subclass()

function ZO_UnitVisualizer_UnwaveringModule:New(...)
    return ZO_UnitAttributeVisualizerModuleBase.New(self, ...)
end

function ZO_UnitVisualizer_UnwaveringModule:Initialize(layoutData)
    self.layoutData = layoutData
end

local function GetInitialStatValue(unitTag, stat, attribute, powerType)
    return GetUnitAttributeVisualizerEffectInfo(unitTag, ATTRIBUTE_VISUAL_UNWAVERING_POWER, stat, attribute, powerType) or 0
end

function ZO_UnitVisualizer_UnwaveringModule:CreateInfoTable(control, oldBarInfo, stat, attribute, power)
    if control then
        local oldInfo = oldBarInfo and oldBarInfo[attribute]
        if oldInfo then
            oldInfo.value = GetInitialStatValue(self:GetUnitTag(), stat, attribute, power)
            return oldInfo
        end

        return { value = GetInitialStatValue(self:GetUnitTag(), stat, attribute, power), lastValue = 0 }
    end
    return nil
end

function ZO_UnitVisualizer_UnwaveringModule:OnAdded(healthBarControl, magickaBarControl, staminaBarControl)
    self.barControls =
    {
        [ATTRIBUTE_HEALTH] = healthBarControl,
    }
    if IsPlayerActivated() then
        self:InitializeBarValues()
    end

    EVENT_MANAGER:RegisterForEvent("ZO_UnitVisualizer_UnwaveringModule" .. self:GetModuleId(), EVENT_PLAYER_ACTIVATED, function() self:InitializeBarValues() end)
end

function ZO_UnitVisualizer_UnwaveringModule:InitializeBarValues()
    local healthBarControl = self.barControls[ATTRIBUTE_HEALTH]

    local oldBarInfo = self.barInfo
    self.barInfo =
    {
        [ATTRIBUTE_HEALTH] = self:CreateInfoTable(healthBarControl, oldBarInfo, STAT_MITIGATION, ATTRIBUTE_HEALTH, POWERTYPE_HEALTH),
    }

    for attribute, bar in pairs(self.barControls) do
        self:OnValueChanged(bar, self.barInfo[attribute], ANIMATION_INSTANT)
    end
end

function ZO_UnitVisualizer_UnwaveringModule:OnUnitChanged()
    self:InitializeBarValues()
end

function ZO_UnitVisualizer_UnwaveringModule:IsUnitVisualRelevant(visualType, stat, attribute, powerType)
    if visualType == ATTRIBUTE_VISUAL_UNWAVERING_POWER then
        return self.barInfo 
           and self.barInfo[attribute] ~= nil
    end
    return false
end

function ZO_UnitVisualizer_UnwaveringModule:OnUnitAttributeVisualAdded(visualType, stat, attribute, powerType, value)
    self.barInfo[attribute].value = self.barInfo[attribute].value + value
    self:OnValueChanged(self.barControls[attribute], self.barInfo[attribute])
end

function ZO_UnitVisualizer_UnwaveringModule:OnUnitAttributeVisualUpdated(visualType, stat, attribute, powerType, oldValue, newValue)
    self.barInfo[attribute].value = self.barInfo[attribute].value + (newValue - oldValue)
    self:OnValueChanged(self.barControls[attribute], self.barInfo[attribute])
end

function ZO_UnitVisualizer_UnwaveringModule:OnUnitAttributeVisualRemoved(visualType, stat, attribute, powerType, value)
    self.barInfo[attribute].value = self.barInfo[attribute].value - value
    self:OnValueChanged(self.barControls[attribute], self.barInfo[attribute])
end

local function ApplyPlatformStyleToUnwavering(control, overlay)
    ApplyTemplateToControl(control, ZO_GetPlatformTemplate(overlay))
end

function ZO_UnitVisualizer_UnwaveringModule:PlayAnimation(bar, info, instant)
    if not info.animation then
        local control = CreateControlFromVirtual("$(parent)UnwaveringOverlayContainer", bar, self.layoutData.overlayContainerTemplate)

        local overlayOffsets = self.layoutData.overlayOffsets
        local currentOffsets = IsInGamepadPreferredMode() and overlayOffsets.gamepad or overlayOffsets.keyboard
        if not currentOffsets then
            currentOffsets = overlayOffsets.shared
        end
        control:SetAnchor(TOPLEFT, bar, TOPLEFT, currentOffsets.left, currentOffsets.top)
        control:SetAnchor(BOTTOMRIGHT, bar, BOTTOMRIGHT, currentOffsets.right, currentOffsets.bottom)
        local animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("UnwaveringAnimation", control)
        info.control = control

        animation:SetHandler("OnPlay", function() 
            self:GetOwner():NotifyTakingControlOf(bar) 
            if bar.warner then
                bar.warner:SetPaused(false)
            end
        end)

        animation:SetHandler("OnStop", function()
            self:GetOwner():NotifyEndingControlOf(bar)
            if bar.warner then
                bar.warner:SetPaused(true)
            end
        end)

        for i, statusBar in ipairs(bar.barControls) do
            animation:InsertAnimationFromVirtual("UnwaveringBarAnimation", statusBar)
        end

        if bar.warnerContainer then
            animation:InsertAnimationFromVirtual("UnwaveringGlowInAnimation", bar.warnerContainer)
            animation:InsertAnimationFromVirtual("UnwaveringGlowOutAnimation", bar.warnerContainer)
        end

        info.animation = animation
    end

    ApplyPlatformStyleToUnwavering(info.control, self.layoutData.overlayContainerTemplate)

    info.animation.instant = instant
    info.animation.owner = self:GetOwner()

    if instant then
        info.control:SetAlpha(1)
        info.animation:PlayInstantlyToEnd()
    else
        info.animation:PlayForward()
    end
end

function ZO_UnitVisualizer_UnwaveringModule:OnValueChanged(bar, info, instant)
    local value = info.value
    local lastValue = info.lastValue
    info.lastValue = value

    if value > 0 and lastValue <= 0 then
        self:PlayAnimation(bar, info, instant)
    elseif value <= 0 and lastValue > 0 then
        info.animation.instant = instant
        ZO_Animation_PlayBackwardOrInstantlyToStart(info.animation, instant)
    end
end

function ZO_UnitVisualizer_UnwaveringModule:ApplyPlatformStyle()
    if self.barInfo then
        for _, info in pairs(self.barInfo) do
            if info.control then
                ApplyPlatformStyleToUnwavering(info.control, self.layoutData.overlayContainerTemplate)
            end
        end
    end
end