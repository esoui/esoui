local POSSESSION_HALO_TEMPLATE = "ZO_PossessionHaloTexture"

ZO_UnitVisualizer_PossessionModule = ZO_UnitAttributeVisualizerModuleBase:Subclass()

function ZO_UnitVisualizer_PossessionModule:New(...)
    return ZO_UnitAttributeVisualizerModuleBase.New(self, ...)
end

function ZO_UnitVisualizer_PossessionModule:Initialize(layoutData)
    self.layoutData = layoutData
end

local function ResetControl(control)
    control:SetHidden(true)
    control:SetParent(nil)
    control:ClearAnchors()
end

local function ApplyPlatformStyleToPossessionObject(object, glow)
    ApplyTemplateToControl(object.possessionHaloTexture, ZO_GetPlatformTemplate(POSSESSION_HALO_TEMPLATE))
    ApplyTemplateToControl(object.possessionHaloGlow, ZO_GetPlatformTemplate(glow))
end

do
    local g_possessionPool

    local function OnPlayControllingTimeline(animation)
        animation.owner:NotifyTakingControlOf(animation.bar)
    end

    local function ReleaseTimeline(animation)
        animation.owner:NotifyEndingControlOf(animation.bar)
        animation.pool:ReleaseObject(animation.key)
    end

    local function ReleaseTimelineIfReversed(animation)
        if animation:IsPlayingBackward() then
            ReleaseTimeline(animation)
        else
            animation.owner:NotifyEndingControlOf(animation.bar)
        end
    end

    function ZO_UnitVisualizer_PossessionModule:GetOrCreatePossessionPool()
        if not g_possessionPool then
            local function OnPossessionFadeStopped(animation)
                if animation:IsPlayingBackward() then
                    animation.loopingAnimation:Stop()
                else
                    animation.owner:NotifyEndingControlOf(animation.bar)
                end
            end

            local function CreatePossession(pool)
                local id = pool:GetNextControlId()

                -- create halo anim controls
                local possessionHaloTextureName = POSSESSION_HALO_TEMPLATE..self.layoutData.type..id
                local possessionHaloGlowName = self.layoutData.possessionHaloGlowTemplate..id

                local possessionHaloTexture = CreateControlFromVirtual(possessionHaloTextureName, GuiRoot, POSSESSION_HALO_TEMPLATE)
                local possessionHaloGlow = CreateControlFromVirtual(possessionHaloGlowName, GuiRoot, self.layoutData.possessionHaloGlowTemplate)

                local fadeAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("PossessionFadeAnimation", possessionHaloTexture)
                fadeAnimation:GetLastAnimation():SetAnimatedControl(possessionHaloGlow)
                fadeAnimation:SetHandler("OnPlay", OnPlayControllingTimeline)
                fadeAnimation:SetHandler("OnStop", OnPossessionFadeStopped)

                local loopingAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("PossessionHaloAnimation", possessionHaloTexture)
                fadeAnimation.loopingAnimation = loopingAnimation
                loopingAnimation:SetHandler("OnStop", ReleaseTimeline)

                return { possessionHaloTexture = possessionHaloTexture, possessionHaloGlow = possessionHaloGlow, fadeAnimation = fadeAnimation, loopingAnimation = loopingAnimation }
            end

            local function Reset(container)
                ResetControl(container.possessionHaloTexture)
                ResetControl(container.possessionHaloGlow)
            end

            g_possessionPool = ZO_ObjectPool:New(CreatePossession, Reset)
        end
        return g_possessionPool
    end
end

function ZO_UnitVisualizer_PossessionModule:GetInitialStatValue(stat, attribute, powerType)
    return self:GetInitialValueAndMarkMostRecent(ATTRIBUTE_VISUAL_POSSESSION, stat, attribute, powerType)
end

function ZO_UnitVisualizer_PossessionModule:CreateInfoTable(control, stat, attribute, power, playPossessionAnimation)
    if control then
        local value = self:GetInitialStatValue(stat, attribute, power)
        return { value = value, lastValue = value, playPossessionAnimation = playPossessionAnimation, barSizeState = ATTRIBUTE_BAR_STATE_NORMAL }
    end
    return nil
end

function ZO_UnitVisualizer_PossessionModule:OnAdded(healthBarControl, magickaBarControl, staminaBarControl)
    self.barControls =
    {
        [ATTRIBUTE_HEALTH] = healthBarControl,
    }

    if IsPlayerActivated() then
        self:InitializeBarValues()
    end

    EVENT_MANAGER:RegisterForEvent("ZO_UnitVisualizer_PossessionModule" .. self:GetModuleId(), EVENT_PLAYER_ACTIVATED, function() self:InitializeBarValues() end)
end

function ZO_UnitVisualizer_PossessionModule:InitializeBarValues()
    local healthBarControl = self.barControls[ATTRIBUTE_HEALTH]

    if self.barInfo == nil then
        self.barInfo =
        {
            [ATTRIBUTE_HEALTH] = self:CreateInfoTable(healthBarControl, STAT_MITIGATION, ATTRIBUTE_HEALTH, POWERTYPE_HEALTH, self.PlayPossessionAnimation),
        }
    else
        self.barInfo[ATTRIBUTE_HEALTH].value = self:GetInitialStatValue(STAT_MITIGATION, ATTRIBUTE_HEALTH, POWERTYPE_HEALTH)
    end

    for attribute, bar in pairs(self.barControls) do
        self:OnValueChanged(bar, self.barInfo[attribute], ANIMATION_INSTANT)
    end
end

function ZO_UnitVisualizer_PossessionModule:OnUnitChanged()
    self:InitializeBarValues()
end

function ZO_UnitVisualizer_PossessionModule:IsUnitVisualRelevant(visualType, stat, attribute, powerType)
    if visualType == ATTRIBUTE_VISUAL_POSSESSION then
        return self.barInfo and self.barInfo[attribute] ~= nil
    end
    return false
end

function ZO_UnitVisualizer_PossessionModule:OnUnitAttributeVisualAdded(visualType, stat, attribute, powerType, value)
    self.barInfo[attribute].value = self.barInfo[attribute].value + value
    self:OnValueChanged(self.barControls[attribute], self.barInfo[attribute])
end

function ZO_UnitVisualizer_PossessionModule:OnUnitAttributeVisualUpdated(visualType, stat, attribute, powerType, oldValue, newValue)
    self.barInfo[attribute].value = self.barInfo[attribute].value + (newValue - oldValue)
    self:OnValueChanged(self.barControls[attribute], self.barInfo[attribute])
end

function ZO_UnitVisualizer_PossessionModule:OnUnitAttributeVisualRemoved(visualType, stat, attribute, powerType, value)
    self.barInfo[attribute].value = self.barInfo[attribute].value - value
    self:OnValueChanged(self.barControls[attribute], self.barInfo[attribute])
end

function ZO_UnitVisualizer_PossessionModule:PlayPossessionAnimation(bar, info, instant)
    local pool = self:GetOrCreatePossessionPool()
    local container, key = pool:AcquireObject()
    ApplyPlatformStyleToPossessionObject(container, self.layoutData.possessionHaloGlowTemplate)
    
    -- create bar overlay control
    if not info.barOverlayControl then
        local barOverlayControlName = "$(parent)PossessionOverlayContainer"..self.layoutData.type
        info.barOverlayControl = CreateControlFromVirtual(barOverlayControlName, bar, self.layoutData.overlayContainerTemplate)
    end

    local possessionHaloTexture = container.possessionHaloTexture
    local possessionHaloGlow = container.possessionHaloGlow
    local loopingAnimation = container.loopingAnimation
    local fadeAnimation = container.fadeAnimation

    loopingAnimation.key = key
    loopingAnimation.owner = self:GetOwner()
    loopingAnimation.pool = pool
    loopingAnimation.bar = bar

    fadeAnimation.owner = self:GetOwner()
    fadeAnimation.bar = bar
    fadeAnimation.instant = instant

    info.barOverlayControl:SetParent(bar)
    info.barOverlayControl:SetHidden(false)
    info.barOverlayControl:SetAnchor(TOPLEFT, bar, TOPLEFT, self.layoutData.overlayLeftOffset, self.layoutData.overlayTopOffset)
    info.barOverlayControl:SetAnchor(BOTTOMRIGHT, bar, BOTTOMRIGHT, self.layoutData.overlayRightOffset, self.layoutData.overlayBottomOffset)

    possessionHaloTexture:SetParent(bar)
    possessionHaloTexture:SetHidden(false)
    possessionHaloTexture:SetAnchor(LEFT, bar, LEFT, -80, 0)
    possessionHaloTexture:SetAnchor(RIGHT, bar, RIGHT, 80, 0)

    possessionHaloGlow:SetParent(bar)
    possessionHaloGlow:SetHidden(false)
    possessionHaloGlow:SetAnchor(LEFT, bar, LEFT, -18)
    possessionHaloGlow:SetAnchor(RIGHT, bar, RIGHT, 18)

    loopingAnimation:PlayFromStart()
    fadeAnimation:PlayFromStart()

    return fadeAnimation
end

function ZO_UnitVisualizer_PossessionModule:OnValueChanged(bar, info, stat, instant)
    local value = info.value
    local lastValue = info.lastValue
    info.lastValue = value

    if value < 0 then
        if info.currentAnimation then
            info.currentAnimation.instant = instant

            if lastValue > 0 then
                ZO_Animation_PlayBackwardOrInstantlyToStart(info.currentAnimation, instant)
                if instant then
                    bar.bgContainer:SetAlpha(1)
                end
            else
                if instant then
                    info.currentAnimation:PlayInstantlyToEnd()
                end
                return -- already playing the correct animation
            end
        end

        info.currentAnimation = info.playPossessionAnimation(self, bar, info, instant)
    elseif value > 0 then
        if info.currentAnimation then
            info.currentAnimation.instant = instant

            if lastValue < 0 then
                ZO_Animation_PlayBackwardOrInstantlyToStart(info.currentAnimation, instant)
            else
                if instant then
                    info.currentAnimation:PlayInstantlyToEnd()
                end
                return -- already playing the correct animation
            end
        end

        info.currentAnimation = info.playPossessionAnimation(self, bar, info, instant)
    else
        if info.currentAnimation then
            info.currentAnimation.instant = instant

            ZO_Animation_PlayBackwardOrInstantlyToStart(info.currentAnimation, instant)
            if instant and lastValue > 0 then
                bar.bgContainer:SetAlpha(1)
            end
            info.currentAnimation = nil
            ResetControl(info.barOverlayControl)
        end
    end
end

function ZO_UnitVisualizer_PossessionModule:ApplyPlatformStyle()
    local pool = self:GetOrCreatePossessionPool()
    local activeObjects = pool:GetActiveObjects()
    
    for _, object in pairs(activeObjects) do
        ApplyPlatformStyleToPossessionObject(object, self.layoutData.possessionHaloGlowTemplate)
    end
end