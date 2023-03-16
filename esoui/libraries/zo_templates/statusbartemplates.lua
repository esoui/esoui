function ZO_StatusBar_SetGradientColor(statusBar, gradientColorTable)
    if statusBar and gradientColorTable then
        local r, g, b, a = gradientColorTable[1]:UnpackRGBA()
        local r1, g1, b1, a1 = gradientColorTable[2]:UnpackRGBA()
        statusBar:SetGradientColors(r, g, b, a, r1, g1, b1, a1)
    end
end

function ZO_StatusBar_InitializeDefaultColors(statusBar)
    local startR, startG, startB = GetInterfaceColor(INTERFACE_COLOR_TYPE_GENERAL, INTERFACE_GENERAL_COLOR_STATUS_BAR_START)
    local endR, endG, endB = GetInterfaceColor(INTERFACE_COLOR_TYPE_GENERAL, INTERFACE_GENERAL_COLOR_STATUS_BAR_END)
    statusBar:SetGradientColors(startR, startG, startB, 1, endR, endG, endB, 1)
end

local function ZO_GetOrCreateArrowBarGlowAnimationTimeline(control)
    if not control.glowAnimation then
        control.glowAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ArrowBarGlowAnimation", control:GetNamedChild("Glow"))
    end
    return control.glowAnimation
end

function ZO_ResponsiveArrowBar_OnMouseEnter(control)
    ZO_GetOrCreateArrowBarGlowAnimationTimeline(control):PlayForward()
end

function ZO_ResponsiveArrowBar_OnMouseExit(control)
    ZO_GetOrCreateArrowBarGlowAnimationTimeline(control):PlayBackward()
end

FORCE_INIT_SMOOTH_STATUS_BAR = true

do
    local g_animationPool
    local DEFAULT_ANIMATION_TIME_MS = 500

    local function OnAnimationTransitionUpdate(animation, progress)
        local bar = animation.bar
        local initialValue = animation.initialValue
        local endValue = animation.endValue
        local newBarValue = zo_lerp(initialValue, endValue, progress)
        bar:SetValue(newBarValue)
    end

    local function OnStopAnimation(animation, completedPlaying)
        local animationKey = animation.key
        local bar = animation:GetFirstAnimation().bar
        bar.animation = nil
        g_animationPool:ReleaseObject(animationKey)
        if bar.onStopCallback then
            bar.onStopCallback(bar, completedPlaying)
        end
    end

    local function AcquireAnimation()
        if not g_animationPool then
            local function Factory(objectPool)
                local animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_StatusBarGrowTemplate")
                animation:GetFirstAnimation():SetUpdateFunction(OnAnimationTransitionUpdate)
                animation:SetHandler("OnStop", function(...) OnStopAnimation(...)  end)
                return animation
            end

            local function Reset(object)
                local customAnimation = object:GetFirstAnimation()
                customAnimation.bar = nil
                customAnimation.initialValue = nil
                customAnimation.endValue = nil
            end

            g_animationPool = ZO_ObjectPool:New(Factory, Reset)
        end

        local animation, key = g_animationPool:AcquireObject()
        animation.key = key
        return animation
    end

    function ZO_StatusBar_SmoothTransition(self, value, max, forceInit, onStopCallback, customApproachAmountMs)
        local oldValue = self:GetValue()
        self:SetMinMax(0, max)
        local oldMax = self.max or max
        self.max = max
        self.onStopCallback = onStopCallback

        if forceInit or max <= 0 then
            self:SetValue(value)
            if self.animation then
                self.animation:Stop()
            end

            if onStopCallback then
                onStopCallback(self)
            end
        else
            if oldMax > 0 and oldMax ~= max then
                local maxChange = max / oldMax
                oldValue = oldValue * maxChange
                self:SetValue(oldValue)
            end

            if not self.animation then
                local updateAnimation = AcquireAnimation()
                self.animation = updateAnimation
            end

            local customAnimation = self.animation:GetFirstAnimation()
            customAnimation:SetDuration(customApproachAmountMs or DEFAULT_ANIMATION_TIME_MS)
            customAnimation.bar = self
            customAnimation.initialValue = oldValue
            customAnimation.endValue = value
            
            self.animation:PlayFromStart()
        end
    end

    function ZO_StatusBar_GetTargetValue(statusBar)
        return (statusBar.animation and statusBar.animation:GetFirstAnimation().endValue) or statusBar:GetValue()
    end
end

ZO_WrappingStatusBar = ZO_Object:Subclass()

function ZO_WrappingStatusBar:New(...)
    local wrappingStatusBar = ZO_Object.New(self)
    wrappingStatusBar:Initialize(...)
    return wrappingStatusBar
end

function ZO_WrappingStatusBar:Initialize(statusBar, onLevelChangedCallback)
    self.statusBar = statusBar
    self:SetOnLevelChangeCallback(onLevelChangedCallback)

    self.onAnimationFinishedCallback = function(timeline, completedPlaying)
        self:OnAnimationFinished(completedPlaying)
    end
end

function ZO_WrappingStatusBar:SetOnLevelChangeCallback(onLevelChangedCallback)
    self.onLevelChangedCallback = onLevelChangedCallback
end

function ZO_WrappingStatusBar:SetOnCompleteCallback(onCompleteCallback)
    self.onCompleteCallback = onCompleteCallback
end

function ZO_WrappingStatusBar:GetControl()
    return self.statusBar
end

function ZO_WrappingStatusBar:SetHidden(hidden)
    self.statusBar:SetHidden(hidden)
end

function ZO_WrappingStatusBar:GetValue()
    return ZO_StatusBar_GetTargetValue(self.statusBar)
end

function ZO_WrappingStatusBar:Reset()
    self.level = nil
    self.noWrap = nil
end

function ZO_WrappingStatusBar:SetAnimationTime(time)
    self.customAnimationTime = time
end

function ZO_WrappingStatusBar:SetValue(level, value, max, noWrap, animateInstantly)
    if noWrap == nil then
        noWrap = false
    end
    local forceInit = false
    if self.level ~= level or self.noWrap ~= noWrap then
        if self.level and level then
            if level > self.level and not noWrap then
                self.pendingLevels = (self.pendingLevels or 0) + level - self.level
            else
                self.pendingLevels = nil
            end
        else
            self.pendingLevels = nil
            forceInit = true
            noWrap = true
        end

        self.level = level
        self.noWrap = noWrap
        
        if self.pendingLevels == nil and self.onLevelChangedCallback then
            self.onLevelChangedCallback(self, self.level)
        end
    end

    forceInit = forceInit or animateInstantly

    if self.pendingLevels and not forceInit and not noWrap then
        self.pendingValue = value
        self.pendingMax = max
        
        ZO_StatusBar_SmoothTransition(self.statusBar, max, max, nil, self.onAnimationFinishedCallback, self.customAnimationTime)
    else
        if forceInit then
            ZO_StatusBar_SmoothTransition(self.statusBar, value, max, true)
        else
            ZO_StatusBar_SmoothTransition(self.statusBar, value, max, false, self.onCompleteCallback, self.customAnimationTime)
        end

        self.pendingValue = nil
        self.pendingMax = nil
    end
end

function ZO_WrappingStatusBar:OnAnimationFinished(completedPlaying)
    if completedPlaying then
        self.pendingLevels = self.pendingLevels - 1
        if self.pendingLevels == 0 then
            ZO_StatusBar_SmoothTransition(self.statusBar, 0, self.pendingMax, FORCE_INIT_SMOOTH_STATUS_BAR)
            ZO_StatusBar_SmoothTransition(self.statusBar, self.pendingValue, self.pendingMax, nil, self.onCompleteCallback, self.customAnimationTime)

            self.pendingLevels = nil
            self.pendingValue = nil
            self.pendingMax = nil

            if self.onLevelChangedCallback then
                self.onLevelChangedCallback(self, self.level)
            end
        else
            ZO_StatusBar_SmoothTransition(self.statusBar, 0, self.pendingMax, FORCE_INIT_SMOOTH_STATUS_BAR)
            ZO_StatusBar_SmoothTransition(self.statusBar, self.pendingMax, self.pendingMax, nil, self.onAnimationFinishedCallback, self.customAnimationTime)

            if self.onLevelChangedCallback then
                self.onLevelChangedCallback(self, self.level - self.pendingLevels)
            end
        end
    end
end

function ZO_WrappingStatusBar:GetLevel()
    return self.level
end

function ZO_WrappingStatusBar:GetNarrationText()
    local narration = SCREEN_NARRATION_MANAGER:CreateNarratableObject()
    local barMax = self.statusBar.max
    if barMax then
        local barMin = self.statusBar.min or 0
        if barMax > barMin then
            local barValue = self:GetValue()
            local range = barMax - barMin
            local percentage = (barValue - barMin) / range
            percentage = string.format("%.2f", percentage * 100)
            narration:AddNarrationText(zo_strformat(SI_SCREEN_NARRATION_PROGRESS_BAR_PERCENT_FORMATTER, percentage))
        end
    end
    return { SCREEN_NARRATION_MANAGER:CreateNarratableObject(self:GetLevel()), narration }
end

--[[
    Inventory Item Improvement Status Bar Mix In
--]]

ZO_InventoryItemImprovementStatusBar = {}

function ZO_InventoryItemImprovementStatusBar:Initialize(control)
    zo_mixin(control, ZO_InventoryItemImprovementStatusBar)
    control.currentBar = control:GetNamedChild("Bar")
    control.improvementBar = control:GetNamedChild("Underlay")
end

function ZO_InventoryItemImprovementStatusBar:SetMinMax(min, max)
    self.currentBar:SetMinMax(min, max)
    self.improvementBar:SetMinMax(min, max)
    self.min, self.max = min, max
end

function ZO_InventoryItemImprovementStatusBar:SetValueAndPreviewValue(value, previewValue)
    ZO_StatusBar_SmoothTransition(self.improvementBar, previewValue, self.max)
    self.currentBar:SetValue(value)
end

function ZO_InventoryItemImprovementStatusBar:SetGradientColors(...)
    self.currentBar:SetGradientColors(...)
end

--[[
    Stable Training Skill Status Bar Mix In
--]]

ZO_StableTrainingBar_Gamepad = {}

function ZO_StableTrainingBar_Gamepad:Initialize(control)
    zo_mixin(control, ZO_StableTrainingBar_Gamepad)
    control.bar = control:GetNamedChild("StatusBar"):GetNamedChild("Bar")
    control.value = control:GetNamedChild("Value")
    self.min, self.max = 0, 0
    self.valueFormat = nil
end

function ZO_StableTrainingBar_Gamepad:SetMinMax(min, max)
    self.min, self.max = min, max
end

function ZO_StableTrainingBar_Gamepad:SetValueFormatString(valueFormat)
    self.valueFormat = valueFormat
end

function ZO_StableTrainingBar_Gamepad:SetValue(value)
    local FORCE_VALUE = true
    ZO_StatusBar_SmoothTransition(self.bar, value, self.max, FORCE_VALUE)

    if self.valueFormat then
        self.value:SetText(zo_strformat(self.valueFormat, value))
    end
end

function ZO_StableTrainingBar_Gamepad:SetGradientColors(...)
    self.bar:SetGradientColors(...)
end

--[[
    Champion Skill Status Bar Mix In
--]]

ZO_ChampionSkillBar_Gamepad = {}

function ZO_ChampionSkillBar_Gamepad:Initialize()
    self.mask = self:GetNamedChild("Mask")
    self.bar = self.mask:GetNamedChild("Bar")
    self.notchPool = ZO_ControlPool:New("ZO_ChampionSkillBarNotch_Gamepad", self:GetNamedChild("Overlay"), "Notch")
    self.minResultLabel = self:GetNamedChild("MinResult")
    self.maxResultLabel = self:GetNamedChild("MaxResult")
    self.min, self.max = 0, 0
end

function ZO_ChampionSkillBar_Gamepad:Reset()
    self.notchPool:ReleaseAllObjects()
end

function ZO_ChampionSkillBar_Gamepad:SetMinMax(min, max)
    self.min, self.max = min, max
    self.bar:SetMinMax(min, max)
end

function ZO_ChampionSkillBar_Gamepad:SetMinMaxText(minText, maxText)
    self.minResultLabel:SetText(minText)
    self.maxResultLabel:SetText(maxText)
end

function ZO_ChampionSkillBar_Gamepad:SetValue(value)
    local FORCE_VALUE = true
    ZO_StatusBar_SmoothTransition(self.bar, value, self.max, FORCE_VALUE)
end

function ZO_ChampionSkillBar_Gamepad:AddNotch(value)
    local offsetX = self.bar:CalculateSizeWithoutLeadingEdgeForValue(value)
    local notchControl = self.notchPool:AcquireObject()
    local PADDING_Y = 5
    notchControl:SetAnchor(TOP, self.bar, TOPLEFT, offsetX, PADDING_Y)
    notchControl:SetAnchor(BOTTOM, self.bar, BOTTOMLEFT, offsetX, -PADDING_Y)
end

function ZO_ChampionSkillBar_Gamepad:SetMaskValue(value)
    if value ~= self.max then
        local maskOffsetX = self.bar:CalculateSizeWithoutLeadingEdgeForValue(value)
        self.mask:SetAnchor(TOPLEFT, self.bar, TOPLEFT)
        self.mask:SetAnchor(BOTTOMRIGHT, self.bar, BOTTOMLEFT, maskOffsetX)
    else
        self.mask:SetAnchor(TOPLEFT, self.bar, TOPLEFT)
        self.mask:SetAnchor(BOTTOMRIGHT, self.bar, BOTTOMRIGHT)
    end
end

function ZO_ChampionSkillBar_Gamepad:SetGradientColors(...)
    self.bar:SetGradientColors(...)
end

--[[
    Sliding Status Bar
]]--
ZO_SlidingStatusBar = ZO_InitializingObject:Subclass()

local DEFAULT_MIN_VALUE = 0
local DEFAULT_MAX_VALUE = 1

local SLIDING_STATUS_BAR_INDICATOR_LAYOUTS =
{
    keyboard = 
    { 
        icon = "EsoUI/Art/Miscellaneous/slidingStatusBar_indicator.dds",
        offsetY = 0,
    },
    gamepad = 
    {
        icon = "EsoUI/Art/Buttons/Gamepad/gp_upArrow.dds",
        offsetY = -15,
    },
}

function ZO_SlidingStatusBar:Initialize(control)
    self.control = control
    self.statusBarLeft = control:GetNamedChild("BarLeft")
    self.statusBarRight = control:GetNamedChild("BarRight")
    self.backgroundContainer = control:GetNamedChild("BgContainer")
    self.valueIndicator = control:GetNamedChild("ValuePointer")
    self.valueIndicatorRelativeControl = control:GetNamedChild("FrameCenter")

    self.min = DEFAULT_MIN_VALUE
    self.max = DEFAULT_MAX_VALUE
    self.value = DEFAULT_MIN_VALUE

    self:ApplyStyle()

    control:RegisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() self:ApplyStyle() end)
end

function ZO_SlidingStatusBar:ApplyStyle()
    ApplyTemplateToControl(self.backgroundContainer:GetNamedChild("BgLeft"), ZO_GetPlatformTemplate("ZO_PlayerAttributeBgLeftArrow"))
    ApplyTemplateToControl(self.backgroundContainer:GetNamedChild("BgRight"), ZO_GetPlatformTemplate("ZO_PlayerAttributeBgRightArrow"))
    ApplyTemplateToControl(self.backgroundContainer:GetNamedChild("BgCenter"), ZO_GetPlatformTemplate("ZO_PlayerAttributeBgCenter"))

    ApplyTemplateToControl(self.control:GetNamedChild("FrameLeft"), ZO_GetPlatformTemplate("ZO_PlayerAttributeFrameLeftArrow"))
    ApplyTemplateToControl(self.control:GetNamedChild("FrameRight"), ZO_GetPlatformTemplate("ZO_PlayerAttributeFrameRightArrow"))
    ApplyTemplateToControl(self.control:GetNamedChild("FrameCenter"), ZO_GetPlatformTemplate("ZO_PlayerAttributeFrameCenter"))

    ApplyTemplateToControl(self.statusBarRight, ZO_GetPlatformTemplate("ZO_PlayerAttributeStatusBar"))
    ApplyTemplateToControl(self.statusBarRight, ZO_GetPlatformTemplate("ZO_PlayerAttributeHealthBarAnchorRight"))
    ApplyTemplateToControl(self.statusBarRight:GetNamedChild("Gloss"), ZO_GetPlatformTemplate("ZO_PlayerAttributeStatusBarGloss"))
    ApplyTemplateToControl(self.statusBarLeft, ZO_GetPlatformTemplate("ZO_PlayerAttributeStatusBar"))
    ApplyTemplateToControl(self.statusBarLeft, ZO_GetPlatformTemplate("ZO_PlayerAttributeHealthBarAnchorLeft"))
    ApplyTemplateToControl(self.statusBarLeft:GetNamedChild("Gloss"), ZO_GetPlatformTemplate("ZO_PlayerAttributeStatusBarGloss"))

    local indicatorLayout = IsInGamepadPreferredMode() and SLIDING_STATUS_BAR_INDICATOR_LAYOUTS.gamepad or SLIDING_STATUS_BAR_INDICATOR_LAYOUTS.keyboard

    self.valueIndicator:SetTexture(indicatorLayout.icon)
    self.indicatorOffsetY = indicatorLayout.offsetY

    local FORCE_REFRESH = true
    self:SetValue(self.value, FORCE_REFRESH)
end

function ZO_SlidingStatusBar:SetGradientColors(startColor, endColor, middleColor)
    --If a middle color has been given, we need to set the gradient up a little differently
    if middleColor then
        ZO_StatusBar_SetGradientColor(self.statusBarLeft, {middleColor, startColor})
        ZO_StatusBar_SetGradientColor(self.statusBarRight, {middleColor, endColor})
    else
        ZO_StatusBar_SetGradientColor(self.statusBarLeft, {startColor, endColor})
        ZO_StatusBar_SetGradientColor(self.statusBarRight, {startColor, endColor})
    end
end

function ZO_SlidingStatusBar:SetMinMax(minValue, maxValue)
    if minValue < maxValue and (minValue ~= self.min or maxValue ~= self.max) then
        self.min = minValue
        self.max = maxValue
        --Either the minimum or the maximum has changed, so we need to reapply the value in case it is no longer within bounds
        local FORCE_REFRESH = true
        self:SetValue(self.value, FORCE_REFRESH)
    end
end

function ZO_SlidingStatusBar:SetValue(value, forceRefresh)
    --First clamp the value between the minimum and maximum
    local clampedValue = zo_clamp(value, self.min, self.max)
    if clampedValue ~= self.value or forceRefresh then
        self.value = clampedValue
        --How far between the min and the max is the value?
        local percentProgress = zo_percentBetween(self.min, self.max, clampedValue)
        --Determine the x offset of the value indicator based on the percent progress calculated above
        local sliderOffsetX = zo_lerp(0, self.valueIndicatorRelativeControl:GetWidth(), percentProgress)
        self.valueIndicator:ClearAnchors()
        self.valueIndicator:SetAnchor(TOP, self.valueIndicatorRelativeControl, BOTTOMLEFT, sliderOffsetX, self.indicatorOffsetY)
    end
end