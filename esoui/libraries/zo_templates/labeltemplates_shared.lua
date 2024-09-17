ZO_LABEL_TEMPLATE_DUMMY_LABEL = CreateControl("ZO_LabelTemplates_DummyLabel", GuiRoot, CT_LABEL)
ZO_LABEL_TEMPLATE_DUMMY_LABEL:SetHidden(true)

-------------------
--SelectableLabel--
-------------------
do
    local function SetSelected(self, selected)
        self.selected = selected
        self:RefreshTextColor()
    end

    local function IsSelected(self)
        return self.selected
    end

    local function SetEnabled(self, enabled)
        self.enabled = enabled
        self:RefreshTextColor()
    end

    local function RefreshTextColor(self)
        self:SetColor(self:GetTextColor())
    end

    local function GetTextColor(self)
        if not self.enabled then
            return GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED)
        elseif self.selected then
            return GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED)
        elseif self.mouseover then
            return GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_HIGHLIGHT)
        else
            return self.normalColor:UnpackRGBA()
        end
    end

    function ZO_SelectableLabel_OnInitialized(label, colorFunction)
        label.selected = false
        label.enabled = true
        label.mouseoverEnabled = true
        label.normalColor = ZO_NORMAL_TEXT
        label.SetSelected = SetSelected
        label.IsSelected = IsSelected
        label.GetTextColor = colorFunction or GetTextColor
        label.RefreshTextColor = RefreshTextColor
        label.SetEnabled = SetEnabled
    end

    function ZO_SelectableLabel_OnMouseEnter(label)
        if label.mouseoverEnabled then
            label.mouseover = true
        end
        label:RefreshTextColor()
    end

    function ZO_SelectableLabel_OnMouseExit(label)
        if label.mouseoverEnabled then
            label.mouseover = false
        end
        label:RefreshTextColor()
    end

    function ZO_SelectableLabel_SetNormalColor(label, color)
        if color ~= label.normalColor and not label.normalColor:IsEqual(color) then
            label.normalColor = color
            label:RefreshTextColor()
        end
    end

    function ZO_SelectableLabel_SetMouseOverEnabled(label, enabled)
        label.mouseoverEnabled = enabled
    end

    function ZO_SelectableLabel_ResetColorFunctionToDefault(label)
        label.GetTextColor = GetTextColor
    end
end

------------------
--KeyMarkupLabel--
------------------
do
    local g_largeKeyEdgefilePool
    local g_smallKeyEdgefilePool

    local function GetOrCreateKeyEdgefile(largeSize)
        if largeSize then
            if not g_largeKeyEdgefilePool then
                g_largeKeyEdgefilePool = ZO_ControlPool:New("ZO_LargeKeyBackdrop")
                g_largeKeyEdgefilePool:SetCustomResetBehavior(   function(control)
                                                                control:SetParent(nil)
                                                            end)
            end
            return g_largeKeyEdgefilePool:AcquireObject()
        else
            if not g_smallKeyEdgefilePool then
                g_smallKeyEdgefilePool = ZO_ControlPool:New("ZO_SmallKeyBackdrop")
                g_smallKeyEdgefilePool:SetCustomResetBehavior(   function(control)
                                                                control:SetParent(nil)
                                                            end)
            end
            return g_smallKeyEdgefilePool:AcquireObject()
        end
    end

    local function UpdateEdgeFileColor(self, keyEdgeFile)
        if self.edgeFileColor then
            keyEdgeFile:SetCenterColor(self.edgeFileColor:UnpackRGBA())
            keyEdgeFile:SetEdgeColor(self.edgeFileColor:UnpackRGBA())
        else
            keyEdgeFile:SetCenterColor(1, 1, 1, 1)
            keyEdgeFile:SetEdgeColor(1, 1, 1, 1)
        end
    end

    function ZO_KeyMarkupLabel_OnNewUserAreaCreated(self, areaData, areaText, left, right, top, bottom, largeSize)
        if zo_strlower(areaData) == "key" then
            if not self.keyBackdrops then
                self.keyBackdrops = {}
            end

            local keyEdgeFile, key = GetOrCreateKeyEdgefile(largeSize)
            keyEdgeFile.key = key
            keyEdgeFile:SetParent(self)
            keyEdgeFile:SetAnchor(TOPLEFT, self, TOPLEFT, left, top)
            keyEdgeFile:SetAnchor(BOTTOMRIGHT, self, TOPLEFT, right, bottom)

            UpdateEdgeFileColor(self, keyEdgeFile)

            keyEdgeFile:SetHidden(false)

            self.keyBackdrops[#self.keyBackdrops + 1] = keyEdgeFile
        end
    end

    function ZO_SmallKeyMarkupLabel_OnNewUserAreaCreated(self, areaData, areaText, left, right, top, bottom)
        local leftOffset = left + (self.leftOffset or 2)
        local rightOffset = right + (self.rightOffset or -2)
        local topOffset = top + (self.topOffset or -2)
        local bottomOffset = bottom + (self.bottomOffset or 3)

        ZO_KeyMarkupLabel_OnNewUserAreaCreated(self, areaData, areaText, leftOffset, rightOffset, topOffset, bottomOffset, false)
    end

    function ZO_LargeKeyMarkupLabel_OnNewUserAreaCreated(self, areaData, areaText, left, right, top, bottom)
        local leftOffset = left + (self.leftOffset or 2)
        local rightOffset = right + (self.rightOffset or -2)
        local topOffset = top + (self.topOffset or -1)
        local bottomOffset = bottom + (self.bottomOffset or 1)

        ZO_KeyMarkupLabel_OnNewUserAreaCreated(self, areaData, areaText, leftOffset, rightOffset, topOffset, bottomOffset, true)
    end

    function ZO_KeyMarkupLabel_SetEdgeFileColor(self, color)
        self.edgeFileColor = color

        if self.keyBackdrops then
            for i, keyEdgeFile in ipairs(self.keyBackdrops) do
                UpdateEdgeFileColor(self, keyEdgeFile)
            end
        end
    end

    function ZO_KeyMarkupLabel_SetCustomOffsets(self, left, right, top, bottom)
        self.leftOffset = left
        self.rightOffset = right
        self.topOffset = top
        self.bottomOffset = bottom
    end

    function ZO_KeyMarkupLabel_OnTextChanged(self, largeSize)
        local pool
        if largeSize then
            pool = g_largeKeyEdgefilePool
        else
            pool = g_smallKeyEdgefilePool
        end

        if self.keyBackdrops then
            for i = #self.keyBackdrops, 1, -1 do
                pool:ReleaseObject(self.keyBackdrops[i].key)
                self.keyBackdrops[i] = nil
            end
        end
    end

    function ZO_SmallKeyMarkupLabel_OnTextChanged(self)
        ZO_KeyMarkupLabel_OnTextChanged(self, false)
    end

    function ZO_LargeKeyMarkupLabel_OnTextChanged(self)
        ZO_KeyMarkupLabel_OnTextChanged(self, true)
    end
end

--------------------------
--FontAdjustingWrapLabel--
--------------------------
do
    local function RefreshStyle(label)
        local fonts = label.fonts
        local numFonts = #fonts
        local lastFont = fonts[numFonts]
        local maxLines = lastFont.lineLimit or numFonts
        label.maxLines = maxLines
        label.dontUseMaxLinesForAdjusting = lastFont.dontUseForAdjusting
        label:SetMaxLineCount(maxLines)
    end

    local function GetFonts(label)
        return label.fonts
    end

    local function GetFontsFromFunction(label)
        label.fonts = label.fontsFunction()
        RefreshStyle(label)
        return label.fonts
    end

    -- dontUseMaxLinesForAdjusting is used when multiple fonts have fontData.lineLimit == label.maxLines
    -- With MaxLineCount non-zero the text will be truncated on the larger font so the smaller font will not be tested
    -- To see the true number of lines with the given font, we SetMaxLineCount(0) before adjusting and then set it back to label.maxLines
    local function AdjustWrappingLabelFont(label)
        local fonts = label:GetFonts()

        if label.dontUseMaxLinesForAdjusting then
            label:SetMaxLineCount(0)
        end

        for i, fontData in ipairs(fonts) do
            local fontLineLimit = fontData.lineLimit or i
            label:SetFont(fontData.font)
            local lines = label:GetNumLines()
            if lines <= fontLineLimit and not label:WasTruncated() then
                break
            end
        end

        if label.dontUseMaxLinesForAdjusting then
            label:SetMaxLineCount(label.maxLines)
        end
    end

    local function FontAdjustingWrapLabel_Update(label)
        local width = label:GetWidth()
        if label.forceUpdate or label.width ~= width then
            label.width = width
            label.forceUpdate = false
            AdjustWrappingLabelFont(label)

            if label.onUpdatedFunction then
                label.onUpdatedFunction()
            end
        end
    end

    local function MarkDirty(label)
        label.forceUpdate = true
        FontAdjustingWrapLabel_Update(label)
    end

    local function ApplyStyle(label, fonts)
        if type(fonts) == "function" then
            label.fontsFunction = fonts
            label.GetFonts = GetFontsFromFunction
        else
            label.fonts = fonts
            label.GetFonts = GetFonts
        end
        label:GetFonts()
        label.forceUpdate = true
        label.MarkDirty = MarkDirty
    end

    local function SetTextOverride(label, text)
        ZO_LABEL_TEMPLATE_DUMMY_LABEL.SetText(label, text)
        label:MarkDirty()
    end

    local function FontAdjustingWrapLabel_Initialize(label, wrapMode, onUpdatedFunction)
        label.SetText = SetTextOverride
        label.onUpdatedFunction = onUpdatedFunction
        label:SetWrapMode(wrapMode)
        label:SetHandler("OnUpdate", FontAdjustingWrapLabel_Update)
    end

    function ZO_FontAdjustingWrapLabel_OnInitialized(label, fonts, wrapMode, onUpdatedFunction)
        FontAdjustingWrapLabel_Initialize(label, wrapMode, onUpdatedFunction)
        ApplyStyle(label, fonts)
    end

    function ZO_PlatformStyleFontAdjustingWrapLabel_OnInitialized(label, keyboardFonts, gamepadFonts, wrapMode)
        FontAdjustingWrapLabel_Initialize(label, wrapMode)
        ZO_PlatformStyle:New(function(...) ApplyStyle(label, ...) end, keyboardFonts, gamepadFonts)
    end
end

function ZO_TooltipIfTruncatedLabel_OnMouseEnter(self)
    if self:WasTruncated() then
        InitializeTooltip(InformationTooltip)
        ZO_Tooltips_SetupDynamicTooltipAnchors(InformationTooltip, self)
        SetTooltipText(InformationTooltip, self:GetText())
    end
end

function ZO_TooltipIfTruncatedLabel_OnMouseExit(self)
    if self:WasTruncated() then
        ClearTooltip(InformationTooltip)
    end
end

--------------------------------
--PrefixAllianceIconLabel--
--------------------------------
do
    local function GetTexture(allianceId, forceGamepad)
        if allianceId <= ALLIANCE_MAX_VALUE then
            if forceGamepad then
                return ZO_GetLargeAllianceSymbolIcon(allianceId)
            else
                return ZO_GetPlatformAllianceSymbolIcon(allianceId)
            end
        end
    end

    function ZO_AllianceIconNameFormatter(allianceId, name, forceGamepad)
        return zo_iconTextFormatNoSpace(GetTexture(allianceId, forceGamepad), "100%", "100%", name)
    end
end

---------------------
--RollingMeterLabel--
---------------------

--[[
    Sample Usage

    -- Create a top-level window.
    local rollingMeterWindow = WINDOW_MANAGER:CreateTopLevelWindow()

    -- Create a rolling meter label control.
    local rollingMeterLabel = WINDOW_MANAGER:CreateControlFromVirtual(nil, rollingMeterWindow, "ZO_RollingMeterLabel")
    rollingMeterLabel:SetAnchor(CENTER, GuiRoot, CENTER)
    rollingMeterLabel:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
    rollingMeterLabel:SetResizeToFitLabels(true)

    local KEYBOARD_STYLE =
    {
        color = ZO_NORMAL_TEXT,
        font = "ZoFontCenterScreenAnnounceLarge",
    }
    local GAMEPAD_STYLE =
    {
        color = ZO_NORMAL_TEXT,
        font = "ZoFontGamepad42",
    }
    rollingMeterLabel:SetPlatformStyles(KEYBOARD_STYLE, GAMEPAD_STYLE)

    -- Roll a starting value into the rolling meter label.
    rollingMeterLabel:SetValue(10)

    -- Roll a new value into the rolling meter label.
    -- NOTE: This will animate 10 => 20 and SKIP the interstitial values (11-19).
    rollingMeterLabel:SetValue(20)

    -- Create a transition manager for the rolling meter label.
    -- NOTE: The transition manager automatically animates the rolling meter label
    -- in order to create smooth transitions from one value to another including
    -- some, if not all, of the interstitial values.
    local rollingMeterTransition = rollingMeterLabel:GetOrCreateTransitionManager()

    -- Initialize the rolling meter label to a starting value via the transition manager.
    rollingMeterTransition:SetValueImmediately(10)

    -- Transition from the current value to a new value.
    rollingMeterTransition:SetValue(20)

    -- OPTIONAL:
    -- Roll upward when incrementing rather than the default downward direction.
    rollingMeterLabel:SetAnimationIncrementDirection(ZO_ROLLING_METER_LABEL_DIRECTION.UP)
    -- Increase roll over animation acceleration by 50%.
    rollingMeterLabel:SetTransitionAccelerationFactor(1.5)
    -- Increase roll over animation speed by 100%.
    rollingMeterLabel:SetTransitionSpeedFactor(2)
    -- Limit transitions to, at most, 20 roll over animations regardless
    -- of the difference between the current value and the new value.
    rollingMeterLabel:SetTransitionMaxSteps(20)

    -- OPTIONAL:
    -- Register a TransitionComplete callback to be notified whenever the
    -- current transition has completed.
    local function OnTransitionComplete(transitionManager, finalValue)
        local queueTransition = function()
            local newValue = zo_random(1, 20)
            transitionManager:SetValue(newValue)
        end
        -- Queue another random transition, creating any endlessly rolling meter.
        zo_callLater(queueTransition, 2000)
    end
    rollingMeterTransition:SetTransitionCompleteCallback(OnTransitionComplete)
]]

ZO_ROLLING_METER_LABEL_DIRECTION =
{
    DOWN = 1,
    UP = 2,
}

local RollingMeterLabel = {}

function RollingMeterLabel:Initialize()
    self.animationIncrementDirection = ZO_ROLLING_METER_LABEL_DIRECTION.DOWN
    self.animationEasingFunction = ZO_EaseInOutQuadratic
    self.animationIntervalMs = 250
    self.inLabelOffsetY = 0
    self.outLabelOffsetY = 0

    -- Order matters:
    self.inLabel = self:GetNamedChild("InLabel")
    self.outLabel = self:GetNamedChild("OutLabel")
    ZO_ForwardUnimplementedMethodsForControl(self, self.inLabel, self.outLabel)

    self:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
    self:SetResizeToFitLabels(true)
    self:SetLayoutDirty(true)
end

do
    local function ApplyStyle(self, style)
        if style.color then
            self:SetColor(style.color:UnpackRGB())
        end

        if style.font then
            self:SetFont(style.font)
        end
    end

    function RollingMeterLabel:SetPlatformStyles(keyboardStyle, gamepadStyle)
        assert(not self.platformStyle, "PlatformStyles already set.")

        self.keyboardStyle = keyboardStyle
        self.gamepadStyle = gamepadStyle
        self.platformStyle = ZO_PlatformStyle:New(function(style) ApplyStyle(self, style) end, self.keyboardStyle, self.gamepadStyle)
    end
end

function RollingMeterLabel:GetAnimationIncrementDirection()
    return self.animationIncrementDirection
end

function RollingMeterLabel:SetAnimationIncrementDirection(direction)
    self.animationIncrementDirection = direction
end

function RollingMeterLabel:GetAnimationInterval()
    return self.animationIntervalMs
end

function RollingMeterLabel:SetAnimationInterval(intervalMs)
    if self.animationStartTimeMs then
        -- An animation is in progress; adjust the end time using the amortized remainder of the new interval.
        local frameTimeMs = GetFrameTimeMilliseconds()
        local animationProgress = (frameTimeMs - self.animationStartTimeMs) / self.animationIntervalMs
        local remainingIntervalTimeMs = zo_max((1 - animationProgress) * intervalMs, 0)
        self.animationEndTimeMs = self.animationStartTimeMs + remainingIntervalTimeMs
    end

    -- Update the animation interval.
    self.animationIntervalMs = zo_max(intervalMs, 1)
end

function RollingMeterLabel:GetAnimationProgress(frameTimeMs)
    local startTimeMs = self.animationStartTimeMs
    if not startTimeMs then
        -- No animation is in progress; the nil return value
        -- indicates this to the caller.
        return nil
    end

    -- Interval is calculated dynamically because it can be
    -- updated while an animation is already in progress.
    local intervalTimeMs = self.animationEndTimeMs - startTimeMs
    if intervalTimeMs > 0 then
        if not frameTimeMs then
            frameTimeMs = GetFrameTimeMilliseconds()
        end
        return zo_clamp((frameTimeMs - startTimeMs) / intervalTimeMs, 0, 1)
    end

    return 1 -- Animation is complete.
end

function RollingMeterLabel:GetAnimationSoundIds()
    return self.animationRollingDownSoundId, self.animationRollingUpSoundId
end

function RollingMeterLabel:SetAnimationSoundIds(rollingDownSoundId, rollingUpSoundId)
    self.animationRollingDownSoundId = rollingDownSoundId
    self.animationRollingUpSoundId = rollingUpSoundId
end

function RollingMeterLabel:GetIncomingValue()
    return self.incomingValue
end

function RollingMeterLabel:GetOutgoingValue()
    return self.outgoingValue
end

function RollingMeterLabel:SetHorizontalAlignment(horizontalAlignment)
    if horizontalAlignment == self.horizontalAlignment then
        return
    end

    self.horizontalAlignment = horizontalAlignment
    self:SetLayoutDirty(true)
end

function RollingMeterLabel:SetResizeToFitLabels(resizeToFitLabels)
    if resizeToFitLabels == self.resizeToFitLabels then
        return
    end

    self.resizeToFitLabels = resizeToFitLabels
    self:SetLayoutDirty(true)
end

function RollingMeterLabel:UpdateLayout()
    if self.isUpdatingLayout then
        -- Suppress recursion.
        return
    end

    self.isUpdatingLayout = true

    local inLabel = self.inLabel
    local outLabel = self.outLabel
    self:UpdateLabelAnchors()

    -- Apply the maximum height of either label to the container.
    local height = zo_max(inLabel:GetHeight(), outLabel:GetHeight())
    self:SetHeight(height)

    local widthConstraint
    if self.resizeToFitLabels then
        -- Constrain the container width to match the largest label width.
        widthConstraint = zo_max(inLabel:GetWidth(), outLabel:GetWidth())
    else
        -- Reset the width constraints of the container to return it to its
        -- derived or explicitly set width.
        widthConstraint = 0
    end
    self:SetDimensionConstraints(widthConstraint, 0, widthConstraint, 0)

    -- Apply the horizontal alignment to the labels.
    local horizontalAlignment = self.horizontalAlignment
    inLabel:SetHorizontalAlignment(horizontalAlignment)
    outLabel:SetHorizontalAlignment(horizontalAlignment)

    self.isUpdatingLayout = nil
    self:SetLayoutDirty(false)
end

function RollingMeterLabel:UpdateLabelAnchors()
    if self.isUpdatingLabelAnchors then
        -- Suppress recursion.
        return
    end

    self.isUpdatingLabelAnchors = true

    -- Reset the labels' anchors.
    self.inLabel:ClearAnchors()
    self.outLabel:ClearAnchors()
    self:UpdateLabelAnchorOffsets()

    self.isUpdatingLabelAnchors = nil
end

function RollingMeterLabel:UpdateLabelAnchorOffsets()
    if self.resizeToFitLabels then
        -- Anchor the labels to the single point on the container that
        -- is associated with the specified horizontal alignment.
        local horizontalAlignment = self.horizontalAlignment or TEXT_ALIGN_RIGHT
        local anchorPoint
        if horizontalAlignment == TEXT_ALIGN_LEFT then
            anchorPoint = TOPLEFT
        elseif horizontalAlignment == TEXT_ALIGN_CENTER then
            anchorPoint = TOP
        else
            anchorPoint = TOPRIGHT
        end

        self.inLabel:SetAnchor(anchorPoint, nil, anchorPoint, 0, self.inLabelOffsetY)
        self.outLabel:SetAnchor(anchorPoint, nil, anchorPoint, 0, self.outLabelOffsetY)
    else
        -- Anchor the labels to the top corners of the container.
        self.inLabel:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, self.inLabelOffsetY)
        self.inLabel:SetAnchor(TOPRIGHT, nil, TOPRIGHT, 0, self.inLabelOffsetY)

        self.outLabel:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, self.outLabelOffsetY)
        self.outLabel:SetAnchor(TOPRIGHT, nil, TOPRIGHT, 0, self.outLabelOffsetY)
    end
end

function RollingMeterLabel:GetTargetValue()
    return self.targetValue
end

function RollingMeterLabel:GetOrCreateTransitionManager()
    if not self.transitionManager then
        self.transitionManager = ZO_RollingMeterLabelTransition:New(self)
    end
    return self.transitionManager
end

function RollingMeterLabel:IsLayoutDirty()
    return self.isLayoutDirty
end

function RollingMeterLabel:SetLayoutDirty(dirty)
    self.isLayoutDirty = dirty ~= false
end

function RollingMeterLabel:OnLabelRectChanged(labelControl, newSize, oldSize)
    self:SetLayoutDirty(true)
end

function RollingMeterLabel:OnUpdate(frameTimeS)
    if self.transitionManager then
        self.transitionManager:Update()
    end

    if self:IsLayoutDirty() then
        self:UpdateLayout()
    end

    local animationProgress = self:GetAnimationProgress()
    if animationProgress == nil then
        -- No animation is in progress.
        return
    end

    if animationProgress < 1 then
        if self.animationOverrideEasingFunction then
            -- Apply the optional, one-time animation override easing function if any.
            animationProgress = zo_max(self.animationOverrideEasingFunction(animationProgress), 0)
        elseif self.animationEasingFunction then
            -- Apply the standard animation override easing function if any.
            animationProgress = zo_max(self.animationEasingFunction(animationProgress), 0)
        end

        -- Animate the incoming and outgoing labels.
        local inLabelOffsetCoefficient = 0
        local outLabelOffsetCoefficient = 0
        if self.animationDirection == ZO_ROLLING_METER_LABEL_DIRECTION.DOWN then
            inLabelOffsetCoefficient = animationProgress - 1
            outLabelOffsetCoefficient = animationProgress
        else
            inLabelOffsetCoefficient = -animationProgress + 1
            outLabelOffsetCoefficient = -animationProgress
        end

        local controlHeight = self:GetHeight()
        self.inLabelOffsetY = inLabelOffsetCoefficient * controlHeight
        self.outLabelOffsetY = outLabelOffsetCoefficient * controlHeight
        self:UpdateLabelAnchorOffsets()
    else
        self:UpdateValue()
    end
end

function RollingMeterLabel:UpdateValue()
    if self.targetAnimationNormalizedIntervalOffset then
        -- Promote the queued, one-time animation interval offset.
        self.animationNormalizedIntervalOffset = self.targetAnimationNormalizedIntervalOffset
        self.targetAnimationNormalizedIntervalOffset = nil
    end

    if self.targetAnimationOverrideEasingFunction then
        -- Promote the queued, one-time animation override easing function.
        self.animationOverrideEasingFunction = self.targetAnimationOverrideEasingFunction
        self.targetAnimationOverrideEasingFunction = nil
    end

    local frameTimeMs = GetFrameTimeMilliseconds()
    local intervalOffset = self.animationNormalizedIntervalOffset
    local isFinalAnimation = self.incomingValue == self.targetValue
    if isFinalAnimation then
        -- There is no pending animation; clean up the animation state.
        self.animationEndTimeMs = nil
        self.animationStartTimeMs = nil

        self.inLabelOffsetY = 0
        self.outLabelOffsetY = 0
        self.outLabel:SetHidden(true)
        self:UpdateLabelAnchorOffsets()
    else
        -- An animation is pending; initialize the animation state.
        self.outgoingValue = self.incomingValue
        self.incomingValue = self.targetValue

        if intervalOffset then
            -- Optional animation timing offset provided via SetValue.
            local animationOffsetMs = self.animationIntervalMs * intervalOffset
            self.animationStartTimeMs = frameTimeMs - animationOffsetMs
            self.animationEndTimeMs = frameTimeMs + self.animationIntervalMs - animationOffsetMs
        else
            -- Standard animation timing.
            self.animationStartTimeMs = frameTimeMs
            self.animationEndTimeMs = frameTimeMs + self.animationIntervalMs
        end

        -- Determine the animation direction based on the configured direction and
        -- the incoming and outgoing values, if numeric, relative to one another.
        local outgoingNumericValue = tonumber(self.outgoingValue)
        local incomingNumericValue = tonumber(self.incomingValue)
        local invertDirection = outgoingNumericValue and incomingNumericValue and outgoingNumericValue > incomingNumericValue
        if invertDirection then
            self.animationDirection = self.animationIncrementDirection == ZO_ROLLING_METER_LABEL_DIRECTION.DOWN and ZO_ROLLING_METER_LABEL_DIRECTION.UP or ZO_ROLLING_METER_LABEL_DIRECTION.DOWN
        else
            self.animationDirection = self.animationIncrementDirection
        end

        -- Update the animation visuals.
        self.inLabel:SetText(self.incomingValue)
        self.outLabel:SetText(self.outgoingValue)
        self:OnUpdate()
        self.outLabel:SetHidden(false)

        if not self:IsHidden() then
            -- Play the associated sound if any.
            local soundId = nil
            if self.animationDirection == ZO_ROLLING_METER_LABEL_DIRECTION.DOWN then
                soundId = self.animationRollingDownSoundId
            else
                soundId = self.animationRollingUpSoundId
            end
            if soundId then
                PlaySound(soundId)
            end
        end
    end

    -- Reset the one-time use animation offset if any was provided.
    self.animationNormalizedIntervalOffset = nil

    if self.valueUpdatedCallback then
        self.valueUpdatedCallback(self, self.outgoingValue, self.incomingValue, self.targetValue)
    end

    return not isFinalAnimation
end

function RollingMeterLabel:SetValue(text, animationNormalizedIntervalOffset, animationOverrideEasingFunction)
    self.targetValue = text

    if animationNormalizedIntervalOffset and animationNormalizedIntervalOffset >= 1 then
        -- Skip animation and display the target value immediately;
        -- this is used for initializing the control to a starting value.
        self.animationEndTimeMs = nil
        self.animationStartTimeMs = nil
        self.incomingValue = self.targetValue
        self.outgoingValue = self.targetValue
        self.targetAnimationNormalizedIntervalOffset = nil
        self.targetAnimationOverrideEasingFunction = nil
        self.inLabel:SetText(self.targetValue)
        self.inLabelOffsetY = 0
        self.outLabel:SetHidden(true)
        self.outLabel:SetText(self.targetValue)
        self.outLabelOffsetY = 0
        self:UpdateLabelAnchorOffsets()
        return
    end

    if self.animationStartTimeMs then
        -- Queue the optional parameters if an animation is already in progress.
        self.targetAnimationNormalizedIntervalOffset = animationNormalizedIntervalOffset
        self.targetAnimationOverrideEasingFunction = animationOverrideEasingFunction
        return
    end

    -- Begin the animation if one is not already in progress.
    self.animationNormalizedIntervalOffset = animationNormalizedIntervalOffset
    self.animationOverrideEasingFunction = animationOverrideEasingFunction
    self:UpdateValue()
end

function RollingMeterLabel:SetValueUpdatedCallback(callbackFunction)
    self.valueUpdatedCallback = callbackFunction
end

function ZO_RollingMeterLabel_OnInitialized(containerControl)
    zo_mixin(containerControl, RollingMeterLabel)
    containerControl:Initialize()
end

-------------------------------
--RollingMeterLabelTransition--
-------------------------------

local BASE_TRANSITION_INTERVAL_MAX_MS = 500       -- Slowest roll over animation interval
local BASE_TRANSITION_INTERVAL_MIN_MS = 100       -- Fastest roll over animation interval
local BASE_TRANSITION_RECOIL_INTERVAL_MS = 1000   -- Final "recoil" roll over animation interval
local TRANSITION_RECOIL_EASING_FUNCTION = ZO_GenerateCubicBezierEase(0.97, 0, 0.5, 1.67)

ZO_RollingMeterLabelTransition = ZO_InitializingObject:Subclass()

function ZO_RollingMeterLabelTransition:Initialize(control)
    self.control = control
    self:Reset()
end

function ZO_RollingMeterLabelTransition:Reset()
    self.currentTransitionStep = nil
    self.currentValue = 0
    self.initialValue = 0
    self.maxIntervalMs = nil
    self.maxTransitionSteps = 20
    self.minIntervalMs = nil
    self.minTransitionIntervalMs = nil
    self.numTransitionSteps = nil
    self.recoilIntervalMs = nil
    self.targetValue = 0

    self:SetTransitionAccelerationFactor(1)
    self:SetTransitionAnimationStartedCallback(nil)
    self:SetTransitionCompleteCallback(nil)
    self:SetTransitionEasingFunction(nil)
    self:SetTransitionSpeedFactor(1)
end

function ZO_RollingMeterLabelTransition:GetTransitionAccelerationFactor()
    return self.transitionAccelerationFactor
end

function ZO_RollingMeterLabelTransition:SetTransitionAccelerationFactor(factor)
    self.transitionAccelerationFactor = zo_max(factor, 0.1)
end

function ZO_RollingMeterLabelTransition:GetTransitionAnimationStartedCallback()
    return self.transitionAnimationStartedCallback
end

function ZO_RollingMeterLabelTransition:SetTransitionAnimationStartedCallback(callbackFunction)
    self.transitionAnimationStartedCallback = callbackFunction
end

function ZO_RollingMeterLabelTransition:GetMaxTransitionSteps()
    return self.maxTransitionSteps
end

function ZO_RollingMeterLabelTransition:SetMaxTransitionSteps(maxTransitionSteps)
    self.maxTransitionSteps = zo_max(maxTransitionSteps, 1)
end

function ZO_RollingMeterLabelTransition:GetTransitionCompleteCallback()
    return self.transitionCompleteCallback
end

function ZO_RollingMeterLabelTransition:SetTransitionCompleteCallback(callbackFunction)
    self.transitionCompleteCallback = callbackFunction
end

function ZO_RollingMeterLabelTransition:GetTransitionEasingFunction()
    return self.transitionEasingFunction
end

function ZO_RollingMeterLabelTransition:SetTransitionEasingFunction(easingFunction)
    self.transitionEasingFunction = easingFunction
end

function ZO_RollingMeterLabelTransition:GetTransitionSpeedFactor()
    return self.transitionSpeedFactor
end

function ZO_RollingMeterLabelTransition:SetTransitionSpeedFactor(factor)
    self.transitionSpeedFactor = zo_max(factor, 0.001)
    local ratio = 1 / self.transitionSpeedFactor
    self.minIntervalMs = zo_max(BASE_TRANSITION_INTERVAL_MIN_MS * ratio, 1)
    self.maxIntervalMs = zo_max(BASE_TRANSITION_INTERVAL_MAX_MS * ratio, self.minIntervalMs)
    self.recoilIntervalMs = zo_max(BASE_TRANSITION_RECOIL_INTERVAL_MS * ratio, 1)
end

function ZO_RollingMeterLabelTransition:GetValue()
    return self.currentValue or 0
end

function ZO_RollingMeterLabelTransition:SetValue(value, optionalInitialValue)
    -- Initialize transition state.
    self.targetValue = value
    if optionalInitialValue then
        self.currentValue = optionalInitialValue
        self.initialValue = optionalInitialValue
    else
        self.currentValue = self.currentValue or 0
        self.initialValue = self.currentValue
    end

    if self.initialValue == self.targetValue then
        -- Skip the animation and show the target value immediately.
        self.currentTransitionStep = nil
        self.numTransitionSteps = nil
        local ANIMATION_NORMALIZED_INTERVAL_OFFSET = 1
        self.control:SetValue(self.targetValue, ANIMATION_NORMALIZED_INTERVAL_OFFSET)
        return
    end

    -- Calculate the number of transition steps required for the given range.
    local integralDifference = zo_ceil(zo_abs(self.targetValue - self.currentValue))
    local transitionSteps = zo_clamp(integralDifference, 1, self.maxTransitionSteps)
    self.numTransitionSteps = transitionSteps
    self.currentTransitionStep = 0

    -- Calculate transition easing.
    local transitionEasingCoefficient = zo_max(integralDifference / transitionSteps, 1)
    self.transitionEasingFunction = ZO_CreateExponentialEaseInOutFunction(transitionEasingCoefficient)

    -- Calculate animation easing and maximum animation speed.
    local animationEasingExponent = self.transitionAccelerationFactor * zo_max(math.log(transitionSteps), 1)
    self.animationEasingFunction = ZO_CreateExponentialEaseOutInFunction(animationEasingExponent)
    local BASE_ANIMATION_MAX_SPEED_MULTIPLIER = 2
    local animationMaxSpeedCoefficient = transitionSteps / self.maxTransitionSteps
    local animationMaxSpeedInterpolant = zo_clamp(self.transitionAccelerationFactor * animationMaxSpeedCoefficient * BASE_ANIMATION_MAX_SPEED_MULTIPLIER, 0, 1)
    self.minTransitionIntervalMs = zo_lerp(self.maxIntervalMs, self.minIntervalMs, animationMaxSpeedInterpolant)
end

function ZO_RollingMeterLabelTransition:SetValueImmediately(value)
    -- Bypasses the animation and immediately updates the meter to show the specified value.
    local CURRENT_VALUE = value
    local INITIAL_VALUE = value
    self:SetValue(CURRENT_VALUE, INITIAL_VALUE)
end

function ZO_RollingMeterLabelTransition:Update()
    local currentStep = self.currentTransitionStep
    if not currentStep then
        -- No transition is in progress.
        return
    end

    if self.control:GetAnimationProgress() then
        -- Wait for current animation to complete.
        return
    end

    -- Increment transition step.
    currentStep = currentStep + 1
    self.currentTransitionStep = currentStep

    local numSteps = self.numTransitionSteps
    if currentStep > numSteps then
        -- The transition is complete.
        self.currentTransitionStep = nil
        self.numTransitionSteps = nil

        -- Notify the registered TransitionComplete callback if any.
        if self.transitionCompleteCallback then
            self.transitionCompleteCallback(self, self.currentValue)
        end

        return
    end

    -- Calculate the current value.
    local progress = currentStep / numSteps
    local easedProgress = self.transitionEasingFunction(progress)
    if currentStep < numSteps then
        self.currentValue = zo_lerp(self.initialValue, self.targetValue, easedProgress)
    else
        self.currentValue = self.targetValue
    end
    self.currentValue = (self.initialValue < self.targetValue) and zo_floor(self.currentValue) or zo_ceil(self.currentValue)

    -- Determine if the final step or target value has been reached.
    local isFinalStep = currentStep >= numSteps or zo_abs(self.targetValue - self.currentValue) <= 0.5
    if isFinalStep then
        -- End the transition if the target value has been reached or
        -- if we interpolated within less than one step from the target
        -- value.
        self.currentValue = self.targetValue
        currentStep = numSteps + 1
        self.currentTransitionStep = currentStep
    end

    -- Determine animation easing, offset and speed (interval).
    local animationIntervalMs = nil
    local animationNormalizedIntervalOffset = nil
    local animationOverrideEasingFunction = nil
    if isFinalStep then
        -- Apply recoil animation easing to the final step.
        animationIntervalMs = self.recoilIntervalMs
        animationOverrideEasingFunction = TRANSITION_RECOIL_EASING_FUNCTION
    else
        local animationProgress = 0
        if numSteps > 2 then
            -- Produce a clean [0..1..0] interpolant by deducting the final step
            -- from the interval allowing for a smooth ramp up and down followed
            -- by the recoil animation easing during the final step.
            animationProgress = (currentStep - 1) / numSteps
        end
        local easedProgress = self.animationEasingFunction(animationProgress)
        local animationIntervalProgress = ZO_LinearEaseZeroToOneToZero(easedProgress)
        animationIntervalMs = zo_lerp(self.maxIntervalMs, self.minTransitionIntervalMs, animationIntervalProgress)
        if animationIntervalMs <= self.minTransitionIntervalMs then
            -- Offset the animation by a random percentage to simulate "over-clocked"
            -- transitions for animations that use the maximum animation speed.
            local MIN_NORMALIZED_INTERVAL_OFFSET = 0.25
            local MAX_NORMALIZED_INTERVAL_OFFSET = 0.75
            animationNormalizedIntervalOffset = zo_lerp(MIN_NORMALIZED_INTERVAL_OFFSET, MAX_NORMALIZED_INTERVAL_OFFSET, zo_random())
        end
    end
    self.control:SetAnimationInterval(animationIntervalMs)

    -- Start the animation for this step.
    self.control:SetValue(self.currentValue, animationNormalizedIntervalOffset, animationOverrideEasingFunction)

    if self.transitionAnimationStartedCallback then
        self.transitionAnimationStartedCallback(self, self.currentTransitionStep, self.numTransitionSteps, self.currentValue, self.targetValue)
    end
end