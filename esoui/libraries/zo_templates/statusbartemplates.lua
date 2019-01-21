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

FORCE_INIT_SMOOTH_STATUS_BAR = true

do
    local g_updatingBars = {}
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
        return statusBar.animation:GetFirstAnimation().endValue or statusBar:GetValue()
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

function ZO_WrappingStatusBar:SetValue(level, value, max, noWrap)
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

local FORCE_VALUE = true
function ZO_StableTrainingBar_Gamepad:SetValue(value)
    ZO_StatusBar_SmoothTransition(self.bar, value, self.max, FORCE_VALUE)

    if self.valueFormat then
        self.value:SetText(zo_strformat(self.valueFormat, value))
    end
end

function ZO_StableTrainingBar_Gamepad:SetGradientColors(...)
    self.bar:SetGradientColors(...)
end