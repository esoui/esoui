local INCREASED_POWER_TEXTURE = "ZO_IncreasedPowerTexture"
local DECREASED_POWER_TEXTURE = "ZO_DecreasedPowerTexture"

ZO_UnitVisualizer_ArmorDamage = ZO_UnitAttributeVisualizerModuleBase:Subclass()

function ZO_UnitVisualizer_ArmorDamage:New(...)
    return ZO_UnitAttributeVisualizerModuleBase.New(self, ...)
end

function ZO_UnitVisualizer_ArmorDamage:Initialize(layoutData)
    self.layoutData = layoutData
end

local function ApplyPlatformStyleToIncreasedArmorObject(object, bg, frame)
    ApplyTemplateToControl(object.increasedArmorBg, ZO_GetPlatformTemplate(bg))
    ApplyTemplateToControl(object.increasedArmorFrame, ZO_GetPlatformTemplate(frame))
end

local function ApplyPlatformStyleToDecreasedArmorObject(object, armorOverlay)
    ApplyTemplateToControl(object.decreasedArmorOverlay, ZO_GetPlatformTemplate(armorOverlay))
end

local function ApplyPlatformStyleToIncreasedPowerObject(object, glow)
    ApplyTemplateToControl(object.increasedPowerTexture, ZO_GetPlatformTemplate(INCREASED_POWER_TEXTURE))
    ApplyTemplateToControl(object.increasedPowerGlow, ZO_GetPlatformTemplate(glow))
end

local function ApplyPlatformStyleToDecreasedPowerObject(object)
    ApplyTemplateToControl(object.decreasedPowerTexture, ZO_GetPlatformTemplate(DECREASED_POWER_TEXTURE))
end

do
    local g_increasedArmorPools = {}
    local g_decreasedArmorPools = {}
    local g_increasedPowerPools = {}
    local g_decreasedPowerPool

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

    local function ResetControl(control)
        control:SetHidden(true)
        control:SetParent(nil)
        control:ClearAnchors()
    end

    function ZO_UnitVisualizer_ArmorDamage:GetOrCreateIncreaseArmorPool()
        if not g_increasedArmorPools[self.layoutData] then
            local function CreateIncreasedArmor(pool)
                local id = pool:GetNextControlId()
                local increasedArmorBg = CreateControlFromVirtual(self.layoutData.increasedArmorBgContainerTemplate, GuiRoot, self.layoutData.increasedArmorBgContainerTemplate, id)
                local increasedArmorFrame = CreateControlFromVirtual(self.layoutData.increasedArmorFrameContainerTemplate, GuiRoot, self.layoutData.increasedArmorFrameContainerTemplate, id)

                local fadeAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("IncreasedArmorFadeAnimation", increasedArmorFrame)
                fadeAnimation:GetFirstAnimation():SetAnimatedControl(increasedArmorBg)
                fadeAnimation:SetHandler("OnPlay", OnPlayControllingTimeline)
                fadeAnimation:SetHandler("OnStop", ReleaseTimelineIfReversed)

                return { increasedArmorBg = increasedArmorBg, increasedArmorFrame = increasedArmorFrame, fadeAnimation = fadeAnimation }
            end

            local function Reset(container)
                ResetControl(container.increasedArmorBg)
                ResetControl(container.increasedArmorFrame)
            end

            g_increasedArmorPools[self.layoutData] = ZO_ObjectPool:New(CreateIncreasedArmor, Reset)
        end
        return g_increasedArmorPools[self.layoutData]
    end

    function ZO_UnitVisualizer_ArmorDamage:GetOrCreateDecreaseArmorPool()
        if not g_decreasedArmorPools[self.layoutData] then
            local function OnFadeAnimationPlay(animation)
                if animation:IsPlayingBackward() then
                    animation.decreasedArmorOverlay.smallAnimation:PlayBackward()
                    animation.decreasedArmorOverlay.smallGlowAnimation:PlayBackward()

                    animation.decreasedArmorOverlay.normalAnimation:PlayBackward()
                    animation.decreasedArmorOverlay.normalGlowAnimation:PlayBackward()

                    animation.decreasedArmorOverlay.expandedAnimation:PlayBackward()
                    animation.decreasedArmorOverlay.expandedGlowAnimation:PlayBackward()
                end
                OnPlayControllingTimeline(animation)
            end
            local function CreateDecreasedArmor(pool)
                local decreasedArmorOverlay = ZO_ObjectPool_CreateControl(self.layoutData.decreasedArmorOverlayContainerTemplate, pool, GuiRoot)

                local fadeAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("DecreasedArmorFadeAnimation", decreasedArmorOverlay)
                fadeAnimation:SetHandler("OnPlay", OnFadeAnimationPlay)
                fadeAnimation:SetHandler("OnStop", ReleaseTimelineIfReversed)
                fadeAnimation.decreasedArmorOverlay = decreasedArmorOverlay

                return { decreasedArmorOverlay = decreasedArmorOverlay, fadeAnimation = fadeAnimation }
            end

            local function Reset(container)
                ResetControl(container.decreasedArmorOverlay)
            end

            g_decreasedArmorPools[self.layoutData] = ZO_ObjectPool:New(CreateDecreasedArmor, Reset)
        end
        return g_decreasedArmorPools[self.layoutData]
    end

    function ZO_UnitVisualizer_ArmorDamage:GetOrCreateIncreasePowerPool()
        if not g_increasedPowerPools[self.layoutData] then
            local function OnIncreasedPowerFadeStopped(animation)
                if animation:IsPlayingBackward() then
                    animation.loopingAnimation:Stop()
                else
                    animation.owner:NotifyEndingControlOf(animation.bar)
                end
            end

            local function CreateIncreasedPower(pool)
                local id = pool:GetNextControlId()
                local increasedPowerTexture = CreateControlFromVirtual(INCREASED_POWER_TEXTURE..self.layoutData.type, GuiRoot, INCREASED_POWER_TEXTURE, id)
                local increasedPowerGlow = CreateControlFromVirtual(self.layoutData.increasedPowerGlowTemplate, GuiRoot, self.layoutData.increasedPowerGlowTemplate, id)

                local fadeAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("IncreasedPowerFadeAnimation", increasedPowerTexture)
                fadeAnimation:GetLastAnimation():SetAnimatedControl(increasedPowerGlow)
                fadeAnimation:SetHandler("OnPlay", OnPlayControllingTimeline)
                fadeAnimation:SetHandler("OnStop", OnIncreasedPowerFadeStopped)

                local loopingAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("IncreasedPowerAnimation", increasedPowerTexture)
                fadeAnimation.loopingAnimation = loopingAnimation
                loopingAnimation:SetHandler("OnStop", ReleaseTimeline)

                return { increasedPowerTexture = increasedPowerTexture, increasedPowerGlow = increasedPowerGlow, fadeAnimation = fadeAnimation, loopingAnimation = loopingAnimation }
            end

            local function Reset(container)
                ResetControl(container.increasedPowerTexture)
                ResetControl(container.increasedPowerGlow)
            end

            g_increasedPowerPools[self.layoutData] = ZO_ObjectPool:New(CreateIncreasedPower, Reset)
        end
        return g_increasedPowerPools[self.layoutData]
    end

    function ZO_UnitVisualizer_ArmorDamage:GetOrCreateDecreasePowerPool()
        if not g_decreasedPowerPool then
            local function CreateDecreasedPower(pool)
                local decreasedPowerTexture = ZO_ObjectPool_CreateControl(DECREASED_POWER_TEXTURE, pool, GuiRoot)

                local fadeAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("DecreasedPowerFadeAnimation", decreasedPowerTexture)
                fadeAnimation:SetHandler("OnPlay", OnPlayControllingTimeline)
                fadeAnimation:SetHandler("OnStop", ReleaseTimelineIfReversed)

                return { decreasedPowerTexture = decreasedPowerTexture, fadeAnimation = fadeAnimation }
            end

            local function Reset(container)
                ResetControl(container.decreasedPowerTexture)
            end

            g_decreasedPowerPool = ZO_ObjectPool:New(CreateDecreasedPower, Reset)
        end
        return g_decreasedPowerPool
    end
end

local function GetInitialStatValue(unitTag, stat, attribute, powerType)
    return (GetUnitAttributeVisualizerEffectInfo(unitTag, ATTRIBUTE_VISUAL_INCREASED_STAT, stat, attribute, powerType) or 0)
         + (GetUnitAttributeVisualizerEffectInfo(unitTag, ATTRIBUTE_VISUAL_DECREASED_STAT, stat, attribute, powerType) or 0)
end

function ZO_UnitVisualizer_ArmorDamage:CreateInfoTable(control, stat, attribute, power, playIncreaseAnimation, playDecreaseAnimation)
    if control then
        local value = GetInitialStatValue(self:GetUnitTag(), stat, attribute, power)
        return { value = value, lastValue = value, playIncreaseAnimation = playIncreaseAnimation, playDecreaseAnimation = playDecreaseAnimation, barSizeState = ATTRIBUTE_BAR_STATE_NORMAL }
    end
    return nil
end

function ZO_UnitVisualizer_ArmorDamage:OnAdded(healthBarControl, magickaBarControl, staminaBarControl)
    self.barControls =
    {
        [STAT_ARMOR_RATING] = healthBarControl,
        [STAT_POWER] = healthBarControl,
    }

    if IsPlayerActivated() then
        self:InitializeBarValues()
    end

    local function OnSizeChanged(bar, size, instant)
        if bar == healthBarControl then
            local armorRatingInfo = self.barInfo and self.barInfo[STAT_ARMOR_RATING]
            if armorRatingInfo then
                armorRatingInfo.barSizeState = size
                if armorRatingInfo.currentAnimation and armorRatingInfo.currentAnimation.decreasedArmorOverlay then
                    self:UpdateDecreasedArmorEffect(bar, armorRatingInfo, instant)
                end
            end
        end
    end

    self:GetOwner():RegisterCallback("AttributeBarSizeChangingStart", OnSizeChanged)
    EVENT_MANAGER:RegisterForEvent("ZO_UnitVisualizer_ArmorDamage" .. self:GetModuleId(), EVENT_PLAYER_ACTIVATED, function() self:InitializeBarValues() end)
end

function ZO_UnitVisualizer_ArmorDamage:InitializeBarValues()
    local healthBarControl = self.barControls[STAT_ARMOR_RATING]

    if self.barInfo == nil then
        self.barInfo =
        {
            [STAT_ARMOR_RATING] = self:CreateInfoTable(healthBarControl, STAT_ARMOR_RATING, ATTRIBUTE_HEALTH, POWERTYPE_HEALTH, self.PlayArmorIncreaseAnimation, self.PlayArmorDecreaseAnimation),
            [STAT_POWER] = self:CreateInfoTable(healthBarControl, STAT_POWER, ATTRIBUTE_HEALTH, POWERTYPE_HEALTH, self.PlayPowerIncreaseAnimation, self.PlayPowerDecreaseAnimation),
        }
    else
        self.barInfo[STAT_ARMOR_RATING].value = GetInitialStatValue(self:GetUnitTag(), STAT_ARMOR_RATING, ATTRIBUTE_HEALTH, POWERTYPE_HEALTH)
        self.barInfo[STAT_POWER].value = GetInitialStatValue(self:GetUnitTag(), STAT_POWER, ATTRIBUTE_HEALTH, POWERTYPE_HEALTH)
    end

    for stat, bar in pairs(self.barControls) do
        self:OnValueChanged(bar, self.barInfo[stat], stat, ANIMATION_INSTANT)
    end
end

function ZO_UnitVisualizer_ArmorDamage:OnUnitChanged()
    self:InitializeBarValues()
end

function ZO_UnitVisualizer_ArmorDamage:IsUnitVisualRelevant(visualType, stat, attribute, powerType)
    if visualType == ATTRIBUTE_VISUAL_INCREASED_STAT or visualType == ATTRIBUTE_VISUAL_DECREASED_STAT then
        return self.barInfo and self.barInfo[stat] ~= nil
    end
    return false
end

function ZO_UnitVisualizer_ArmorDamage:OnUnitAttributeVisualAdded(visualType, stat, attribute, powerType, value)
    self.barInfo[stat].value = self.barInfo[stat].value + value
    self:OnValueChanged(self.barControls[stat], self.barInfo[stat], stat)
end

function ZO_UnitVisualizer_ArmorDamage:OnUnitAttributeVisualUpdated(visualType, stat, attribute, powerType, oldValue, newValue)
    self.barInfo[stat].value = self.barInfo[stat].value + (newValue - oldValue)
    self:OnValueChanged(self.barControls[stat], self.barInfo[stat], stat)
end

function ZO_UnitVisualizer_ArmorDamage:OnUnitAttributeVisualRemoved(visualType, stat, attribute, powerType, value)
    self.barInfo[stat].value = self.barInfo[stat].value - value
    self:OnValueChanged(self.barControls[stat], self.barInfo[stat], stat)
end

function ZO_UnitVisualizer_ArmorDamage:PlayArmorIncreaseAnimation(bar, info, instant)
    local pool = self:GetOrCreateIncreaseArmorPool()
    local container, key = pool:AcquireObject()
    ApplyPlatformStyleToIncreasedArmorObject(container, self.layoutData.increasedArmorBgContainerTemplate, self.layoutData.increasedArmorFrameContainerTemplate)

    local increasedArmorBg = container.increasedArmorBg
    local increasedArmorFrame = container.increasedArmorFrame
    local fadeAnimation = container.fadeAnimation

    fadeAnimation.key = key
    fadeAnimation.owner = self:GetOwner()
    fadeAnimation.pool = pool
    fadeAnimation.bar = bar
    fadeAnimation.instant = instant

    fadeAnimation:GetAnimation(2):SetAnimatedControl(bar.bgContainer)

    increasedArmorBg:SetParent(bar)
    increasedArmorBg:SetHidden(false)

    local increasedArmorOffsets = self.layoutData.increasedArmorOffsets
    local currentOffsets = IsInGamepadPreferredMode() and increasedArmorOffsets.gamepad or increasedArmorOffsets.keyboard
    if not currentOffsets then
        currentOffsets = increasedArmorOffsets.shared
    end

    increasedArmorBg:SetAnchor(TOPLEFT, bar.bgContainer, TOPLEFT, currentOffsets.left, currentOffsets.top)
    increasedArmorBg:SetAnchor(BOTTOMRIGHT, bar.bgContainer, BOTTOMRIGHT, currentOffsets.right, currentOffsets.bottom)

    increasedArmorFrame:SetParent(bar)
    increasedArmorFrame:SetHidden(false)
    
    if instant then
        increasedArmorFrame:SetAnchor(TOPLEFT, bar.bgContainer, TOPLEFT, currentOffsets.left, currentOffsets.top)
        increasedArmorFrame:SetAnchor(BOTTOMRIGHT, bar.bgContainer, BOTTOMRIGHT, currentOffsets.right, currentOffsets.bottom)
        increasedArmorFrame:SetAlpha(1)
        bar.bgContainer:SetAlpha(1)
        increasedArmorBg:SetAlpha(1)

        --this is only meant to advance the playhead to the end so that playing it backwards later works
        fadeAnimation:PlayInstantlyToEnd()
    else
        increasedArmorFrame:SetAnchor(TOPLEFT, bar.bgContainer, TOPLEFT)
        increasedArmorFrame:SetAnchor(BOTTOMRIGHT, bar.bgContainer, BOTTOMRIGHT)

        fadeAnimation:GetAnimation(4):SetTranslateOffsets(-150, -15, currentOffsets.left, currentOffsets.top)
        fadeAnimation:GetAnimation(5):SetTranslateOffsets(150, 15, currentOffsets.right, currentOffsets.bottom)

        fadeAnimation:PlayFromStart()
    end

    return fadeAnimation
end

function ZO_UnitVisualizer_ArmorDamage:PlayArmorDecreaseAnimation(bar, info, instant)
    local pool = self:GetOrCreateDecreaseArmorPool()
    local container, key = pool:AcquireObject()
    ApplyPlatformStyleToDecreasedArmorObject(container, self.layoutData.decreasedArmorOverlayContainerTemplate)

    local animation = container.fadeAnimation
    animation.key = key
    animation.owner = self:GetOwner()
    animation.pool = pool
    animation.bar = bar
    animation.instant = instant

    local decreasedArmorOverlay = container.decreasedArmorOverlay
    decreasedArmorOverlay:SetParent(bar)
    decreasedArmorOverlay:SetHidden(false)
    decreasedArmorOverlay:SetAnchor(CENTER, bar, CENTER)

    ZO_Animation_PlayFromStartOrInstantlyToEnd(animation, instant)

    self:UpdateDecreasedArmorEffect(bar, info, ANIMATION_INSTANT, decreasedArmorOverlay)

    return animation
end

local SMALL_OFFSET = 0
local NORMAL_OFFSET = 1300
local EXPAND_OFFSET = 1700

function ZO_UnitVisualizer_ArmorDamage:UpdateDecreasedArmorEffect(bar, info, instant, decreasedArmorOverlay)
    decreasedArmorOverlay = decreasedArmorOverlay or info.currentAnimation.decreasedArmorOverlay

    local barSizeState = info.barSizeState

    if instant then
        if barSizeState == ATTRIBUTE_BAR_STATE_NORMAL then
            decreasedArmorOverlay.smallAnimation:PlayInstantlyToEnd()
            decreasedArmorOverlay.smallGlowAnimation:PlayInstantlyToEnd()

            decreasedArmorOverlay.normalAnimation:PlayInstantlyToEnd()
            decreasedArmorOverlay.normalGlowAnimation:PlayInstantlyToEnd()

            decreasedArmorOverlay.expandedAnimation:PlayInstantlyToStart()
            decreasedArmorOverlay.expandedGlowAnimation:PlayInstantlyToStart()
        elseif barSizeState == ATTRIBUTE_BAR_STATE_EXPANDED then
            decreasedArmorOverlay.smallAnimation:PlayInstantlyToEnd()
            decreasedArmorOverlay.smallGlowAnimation:PlayInstantlyToEnd()

            decreasedArmorOverlay.normalAnimation:PlayInstantlyToEnd()
            decreasedArmorOverlay.normalGlowAnimation:PlayInstantlyToEnd()

            decreasedArmorOverlay.expandedAnimation:PlayInstantlyToEnd()
            decreasedArmorOverlay.expandedGlowAnimation:PlayInstantlyToEnd()
        elseif barSizeState == ATTRIBUTE_BAR_STATE_SHRUNK then
            decreasedArmorOverlay.smallAnimation:PlayInstantlyToEnd()
            decreasedArmorOverlay.smallGlowAnimation:PlayInstantlyToEnd()

            decreasedArmorOverlay.normalAnimation:PlayInstantlyToStart()
            decreasedArmorOverlay.normalGlowAnimation:PlayInstantlyToStart()

            decreasedArmorOverlay.expandedAnimation:PlayInstantlyToStart()
            decreasedArmorOverlay.expandedGlowAnimation:PlayInstantlyToStart()
        end
    else
        decreasedArmorOverlay.smallAnimation:Stop()
        decreasedArmorOverlay.smallGlowAnimation:Stop()

        decreasedArmorOverlay.normalAnimation:Stop()
        decreasedArmorOverlay.normalGlowAnimation:Stop()

        decreasedArmorOverlay.expandedAnimation:Stop()
        decreasedArmorOverlay.expandedGlowAnimation:Stop()

        if barSizeState == ATTRIBUTE_BAR_STATE_NORMAL then
            decreasedArmorOverlay.smallAnimation:PlayForward()
            decreasedArmorOverlay.smallGlowAnimation:PlayForward()

            decreasedArmorOverlay.normalAnimation:PlayForward()
            decreasedArmorOverlay.normalGlowAnimation:PlayForward()

            decreasedArmorOverlay.expandedAnimation:PlayBackward()
            decreasedArmorOverlay.expandedGlowAnimation:PlayBackward()
        elseif barSizeState == ATTRIBUTE_BAR_STATE_EXPANDED then
            decreasedArmorOverlay.smallAnimation:PlayForward()
            decreasedArmorOverlay.smallGlowAnimation:PlayForward()

            decreasedArmorOverlay.normalAnimation:PlayForward()
            decreasedArmorOverlay.normalGlowAnimation:PlayForward()

            decreasedArmorOverlay.expandedAnimation:PlayForward()
            decreasedArmorOverlay.expandedGlowAnimation:PlayForward()
        elseif barSizeState == ATTRIBUTE_BAR_STATE_SHRUNK then
            decreasedArmorOverlay.smallAnimation:PlayForward()
            decreasedArmorOverlay.smallGlowAnimation:PlayForward()

            decreasedArmorOverlay.normalAnimation:PlayBackward()
            decreasedArmorOverlay.normalGlowAnimation:PlayBackward()

            decreasedArmorOverlay.expandedAnimation:PlayBackward()
            decreasedArmorOverlay.expandedGlowAnimation:PlayBackward()
        end
    end
end


function ZO_UnitVisualizer_ArmorDamage:PlayPowerIncreaseAnimation(bar, info, instant)
    local pool = self:GetOrCreateIncreasePowerPool()
    local container, key = pool:AcquireObject()

    local increasedPowerTexture = container.increasedPowerTexture
    local increasedPowerGlow = container.increasedPowerGlow
    local loopingAnimation = container.loopingAnimation
    local fadeAnimation = container.fadeAnimation

    loopingAnimation.key = key
    loopingAnimation.owner = self:GetOwner()
    loopingAnimation.pool = pool
    loopingAnimation.bar = bar

    fadeAnimation.owner = self:GetOwner()
    fadeAnimation.bar = bar
    fadeAnimation.instant = instant

    increasedPowerTexture:SetParent(bar)
    increasedPowerTexture:SetHidden(false)
    increasedPowerTexture:SetAnchor(LEFT, bar, LEFT, -80, 0)
    increasedPowerTexture:SetAnchor(RIGHT, bar, RIGHT, 80, 0)

    increasedPowerGlow:SetParent(bar)
    increasedPowerGlow:SetHidden(false)
    increasedPowerGlow:SetAnchor(LEFT, bar, LEFT, -18)
    increasedPowerGlow:SetAnchor(RIGHT, bar, RIGHT, 18)
    ApplyPlatformStyleToIncreasedPowerObject(container, self.layoutData.increasedPowerGlowTemplate)

    loopingAnimation:PlayFromStart()
    fadeAnimation:PlayFromStart()

    return fadeAnimation
end

function ZO_UnitVisualizer_ArmorDamage:PlayPowerDecreaseAnimation(bar, info, instant)
    local pool = self:GetOrCreateDecreasePowerPool()
    local container, key = pool:AcquireObject()
    ApplyPlatformStyleToDecreasedPowerObject(container)

    local animation = container.fadeAnimation
    animation.key = key
    animation.owner = self:GetOwner()
    animation.pool = pool
    animation.bar = bar
    animation.instant = instant

    local decreasedPowerTexture = container.decreasedPowerTexture
    decreasedPowerTexture:SetParent(bar)
    decreasedPowerTexture:SetHidden(false)
    decreasedPowerTexture:SetAnchor(LEFT, bar, LEFT, -150, 0)
    decreasedPowerTexture:SetAnchor(RIGHT, bar, RIGHT, 150, 0)

    animation:PlayFromStart()

    return animation
end

function ZO_UnitVisualizer_ArmorDamage:OnValueChanged(bar, info, stat, instant)
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

        info.currentAnimation = info.playDecreaseAnimation(self, bar, info, instant)
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

        info.currentAnimation = info.playIncreaseAnimation(self, bar, info, instant)
    else
        if info.currentAnimation then
            info.currentAnimation.instant = instant

            ZO_Animation_PlayBackwardOrInstantlyToStart(info.currentAnimation, instant)
            if instant and lastValue > 0 then
                bar.bgContainer:SetAlpha(1)
            end
            info.currentAnimation = nil
        end
    end
end

function ZO_UnitVisualizer_ArmorDamage:ApplyPlatformStyle()
    local increaseArmorPool = self:GetOrCreateIncreaseArmorPool()
    local decreaseArmorPool = self:GetOrCreateDecreaseArmorPool()
    local increasePowerPool = self:GetOrCreateIncreasePowerPool()
    local decreasePowerPool = self:GetOrCreateDecreasePowerPool()

    local activeObjects = increaseArmorPool:GetActiveObjects()
    for _, object in pairs(activeObjects) do
        ApplyPlatformStyleToIncreasedArmorObject(object, self.layoutData.increasedArmorBgContainerTemplate, self.layoutData.increasedArmorFrameContainerTemplate)
    end

    activeObjects = decreaseArmorPool:GetActiveObjects()
    for _, object in pairs(activeObjects) do
        ApplyPlatformStyleToDecreasedArmorObject(object, self.layoutData.decreasedArmorOverlayContainerTemplate)
    end

    activeObjects = increasePowerPool:GetActiveObjects()
    for _, object in pairs(activeObjects) do
        ApplyPlatformStyleToIncreasedPowerObject(object, self.layoutData.increasedPowerGlowTemplate)
    end

    activeObjects = decreasePowerPool:GetActiveObjects()
    for _, object in pairs(activeObjects) do
        ApplyPlatformStyleToDecreasedPowerObject(object)
    end
end