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
    local g_customApproachAmounts = {}

    function ZO_StatusBar_SmoothTransition(self, value, max, forceInit, onStopCallback, customApproachAmount)
        local oldValue = self:GetValue()
        self:SetMinMax(0, max)
        local oldMax = self.max or max
        self.max = max
        self.onStopCallback = onStopCallback

        if forceInit or max <= 0 then
            self:SetValue(value)
            g_updatingBars[self] = nil
            if onStopCallback then
                onStopCallback(self)
            end
        else
            if oldMax > 0 and oldMax ~= max then
                local maxChange = max / oldMax
                self:SetValue(oldValue * maxChange)
            end

            g_updatingBars[self] = value
            g_customApproachAmounts[self] = customApproachAmount
        end
    end

    function ZO_StatusBar_IsSmoothTransitionPlaying(statusBar)
        return g_updatingBars[statusBar] ~= nil
    end

    function ZO_StatusBar_GetTargetValue(statusBar)
        return g_updatingBars[statusBar] or statusBar:GetValue()
    end

    local MIN_PERCENT_BEFORE_FINISHING = .0025
    local APPROACH_AMOUNT_PER_NORMALIZED_FRAME = .085

    local function OnSmoothTransitionsUpdate()
        for bar, target in pairs(g_updatingBars) do
            local current = bar:GetValue()

            if zo_abs(target - current) / bar.max < MIN_PERCENT_BEFORE_FINISHING then
                bar:SetValue(target)
                g_updatingBars[bar] = nil
                g_customApproachAmounts[bar] = nil
                if bar.onStopCallback then
                    bar.onStopCallback(bar)
                end
            else
                local approachAmount = g_customApproachAmounts[bar] or APPROACH_AMOUNT_PER_NORMALIZED_FRAME
                bar:SetValue(zo_deltaNormalizedLerp(current, target, approachAmount))
            end
        end
    end

    EVENT_MANAGER:RegisterForUpdate("ZO_StatusBar_SmoothTransition", 0, OnSmoothTransitionsUpdate)
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

    self.onAnimationFinishedCallback = function()
        self:OnAnimationFinished()
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
end

function ZO_WrappingStatusBar:SetValue(level, value, max, noWrap)
    local forceInit = false
    if self.level ~= level then
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
        if self.pendingLevels == nil and self.onLevelChangedCallback then
            self.onLevelChangedCallback(self, self.level)
        end
    end

    if self.pendingLevels and not forceInit and not noWrap then
        self.pendingValue = value
        self.pendingMax = max
        
        ZO_StatusBar_SmoothTransition(self.statusBar, max, max, nil, self.onAnimationFinishedCallback)
    else
        if forceInit then
            ZO_StatusBar_SmoothTransition(self.statusBar, value, max, true)
        else
            ZO_StatusBar_SmoothTransition(self.statusBar, value, max, false, self.onCompleteCallback)
        end

        self.pendingValue = nil
        self.pendingMax = nil
    end
end

function ZO_WrappingStatusBar:OnAnimationFinished()
    self.pendingLevels = self.pendingLevels - 1
    if self.pendingLevels == 0 then
        ZO_StatusBar_SmoothTransition(self.statusBar, 0, self.pendingMax, FORCE_INIT_SMOOTH_STATUS_BAR)
        ZO_StatusBar_SmoothTransition(self.statusBar, self.pendingValue, self.pendingMax, nil, self.onCompleteCallback)

        self.pendingLevels = nil
        self.pendingValue = nil
        self.pendingMax = nil

        if self.onLevelChangedCallback then
            self.onLevelChangedCallback(self, self.level)
        end
    else
        ZO_StatusBar_SmoothTransition(self.statusBar, 0, self.pendingMax, FORCE_INIT_SMOOTH_STATUS_BAR)
        ZO_StatusBar_SmoothTransition(self.statusBar, self.pendingMax, self.pendingMax, nil, self.onAnimationFinishedCallback)

        if self.onLevelChangedCallback then
            self.onLevelChangedCallback(self, self.level - self.pendingLevels)
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
end

function ZO_StableTrainingBar_Gamepad:SetMinMax(min, max)
    self.currentBar:SetMinMax(min, max)
    self.improvementBar:SetMinMax(min, max)
    self.min, self.max = min, max
end

local FORCE_VALUE = true
function ZO_StableTrainingBar_Gamepad:SetValue(value, maxValue, format)
    ZO_StatusBar_SmoothTransition(self.bar, value, maxValue, FORCE_VALUE)
    self.value:SetText(zo_strformat(format, value))
end

function ZO_StableTrainingBar_Gamepad:SetGradientColors(...)
    self.bar:SetGradientColors(...)
end