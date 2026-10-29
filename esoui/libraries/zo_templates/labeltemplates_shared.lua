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
            label:GetFonts()
        else
            label.fonts = fonts
            label.GetFonts = GetFonts
            RefreshStyle(label)
        end
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
    rollingMeterLabel:SetMaxTransitionSteps(20)

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

local RollingMeterLabelWheel = {}

function RollingMeterLabelWheel:Initialize()
    self.inLabel = self:GetNamedChild("InLabel")
    self.outLabel = self:GetNamedChild("OutLabel")
    self.defaultColor = { self.inLabel:GetColor() }
    self.defaultFont = self.inLabel:GetFont()
    self.defaultModifyTextType = self.inLabel:GetModifyTextType()
    self.owner = nil
    self.minimumWidth = 0
    self.currentText = ""
    self.isAnimating = false
    self.animationDelayMs = 0
    self.pendingStaticText = nil

    self.inLabel:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    self.outLabel:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    self.inLabel:SetAnchor(TOPLEFT)
    self.outLabel:SetAnchor(TOPLEFT)
    self.outLabel:SetHidden(true)
end

function RollingMeterLabelWheel:SetOwner(owner)
    self.owner = owner
end

function RollingMeterLabelWheel:Reset()
    self.owner = nil
    self:SetColor(unpack(self.defaultColor))
    self:SetFont(self.defaultFont)
    self:SetModifyTextType(self.defaultModifyTextType)
    self.minimumWidth = 0
    self.currentText = ""
    self.isAnimating = false
    self.animationDelayMs = 0
    self.pendingStaticText = nil
    self.inLabel:SetText("")
    self.outLabel:SetText("")
    self.outLabel:SetHidden(true)
end

function RollingMeterLabelWheel:SetColor(...)
    self.inLabel:SetColor(...)
    self.outLabel:SetColor(...)
end

function RollingMeterLabelWheel:SetFont(font)
    self.inLabel:SetFont(font)
    self.outLabel:SetFont(font)
    self:UpdateLayout()
end

function RollingMeterLabelWheel:SetModifyTextType(modifyTextType)
    self.inLabel:SetModifyTextType(modifyTextType)
    self.outLabel:SetModifyTextType(modifyTextType)
end

function RollingMeterLabelWheel:SetMinimumWidth(width)
    self.minimumWidth = width or 0
    self:UpdateLayout()
end

function RollingMeterLabelWheel:UpdateLayout()
    local width = zo_max(self.inLabel:GetWidth(), self.outLabel:GetWidth(), self.minimumWidth)
    local height = zo_max(self.inLabel:GetHeight(), self.outLabel:GetHeight())
    self:SetDimensions(width, height)
end

function RollingMeterLabelWheel:SetStaticValue(text, delayMs)
    self.pendingStaticText = nil
    if delayMs and delayMs > 0 and text ~= self.currentText then
        self.pendingStaticText = text or ""
        self.animationDelayMs = delayMs
        self.isAnimating = false
        return
    end

    self.currentText = text or ""
    self.isAnimating = false
    self.animationDelayMs = 0
    self.inLabel:SetText(self.currentText)
    self.outLabel:SetText(self.currentText)
    self.outLabel:SetHidden(true)
    self:UpdateLayout()
    self:SetHidden(self.currentText == "")
end

function RollingMeterLabelWheel:SetAnimatedValue(outgoingText, incomingText)
    self.currentText = incomingText or ""
    self.isAnimating = true
    self.animationDelayMs = 0
    self.pendingStaticText = nil
    self.inLabel:SetText(self.currentText)
    self.outLabel:SetText(outgoingText or "")
    self.outLabel:SetHidden(false)
    self:UpdateLayout()
end

function RollingMeterLabelWheel:SetAnimationDelay(delayMs)
    self.animationDelayMs = delayMs or 0
end

function RollingMeterLabelWheel:GetAnimationDelay()
    return self.animationDelayMs
end

function RollingMeterLabelWheel:HasPendingStaticValue()
    return self.pendingStaticText ~= nil
end

function RollingMeterLabelWheel:ApplyPendingStaticValue()
    if self.pendingStaticText ~= nil then
        local pendingStaticText = self.pendingStaticText
        self.pendingStaticText = nil
        self:SetStaticValue(pendingStaticText)
    end
end

function RollingMeterLabelWheel:IsAnimating()
    return self.isAnimating
end

function RollingMeterLabelWheel:UpdateAnimation(progress, direction)
    local directionMultiplier = direction == ZO_ROLLING_METER_LABEL_DIRECTION.DOWN and 1 or -1
    local inLabelOffsetCoefficient = (progress - 1) * directionMultiplier
    local outLabelOffsetCoefficient = progress * directionMultiplier

    local controlHeight = self:GetHeight()
    local inLabelOffsetY = inLabelOffsetCoefficient * controlHeight
    local outLabelOffsetY = outLabelOffsetCoefficient * controlHeight
    self.inLabel:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, inLabelOffsetY)
    self.outLabel:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, outLabelOffsetY)
end

function RollingMeterLabelWheel:CompleteAnimation()
    self.isAnimating = false
    self.outLabel:SetHidden(true)
    self.inLabel:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)
    self.outLabel:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)
    self:SetHidden(self.currentText == "")
end

function ZO_RollingMeterLabelWheel_OnInitialized(wheelControl)
    zo_mixin(wheelControl, RollingMeterLabelWheel)
    wheelControl:Initialize()
end

function ZO_RollingMeterLabelWheel_OnRectChanged(wheelLabel)
    local wheelControl = wheelLabel:GetParent()
    if wheelControl.owner then
        wheelControl.owner:OnWheelRectChanged()
    end
end

local g_rollingMeterLabelWheelSourcePool = nil

local function ResetRollingMeterLabelWheel(wheel)
    wheel:Reset()
    wheel:SetParent(nil)
end

local function GetRollingMeterLabelWheelSourcePool()
    if not g_rollingMeterLabelWheelSourcePool then
        g_rollingMeterLabelWheelSourcePool = ZO_ControlPool:New("ZO_RollingMeterLabelWheel", GuiRoot, "RollingMeterWheel")
        g_rollingMeterLabelWheelSourcePool:SetCustomResetBehavior(ResetRollingMeterLabelWheel)
    end

    return g_rollingMeterLabelWheelSourcePool
end

local RollingMeterLabel = {}

local CARRY_DELAY_INTERVAL_FRACTION = 0.2
local FALLBACK_DELAY_INTERVAL_FRACTION = 0.1

local function GetNumericValue(value)
    if value == nil then
        return nil
    end

    local numericText = tostring(value)
    numericText = string.gsub(numericText, ",", "")
    return tonumber(numericText)
end

local function IsDigitWrap(outgoingCharacter, incomingCharacter, isIncreasingMagnitude)
    local outgoingDigit = tonumber(outgoingCharacter)
    local incomingDigit = tonumber(incomingCharacter)
    if outgoingDigit == nil or incomingDigit == nil then
        return false
    end

    if isIncreasingMagnitude then
        return incomingDigit < outgoingDigit
    end

    return incomingDigit > outgoingDigit
end

local function CrossesDigitBoundary(outgoingNumericValue, incomingNumericValue, digitPlace, isIncreasingMagnitude)
    if outgoingNumericValue == nil or incomingNumericValue == nil or digitPlace == nil or digitPlace == 0 then
        return false
    end

    local placeValue = zo_pow(10, digitPlace)
    local outgoingBucket = zo_floor(zo_abs(outgoingNumericValue) / placeValue)
    local incomingBucket = zo_floor(zo_abs(incomingNumericValue) / placeValue)
    if isIncreasingMagnitude then
        return incomingBucket > outgoingBucket
    end

    return incomingBucket < outgoingBucket
end

local function IsCarryContinuation(outgoingCharacter, incomingCharacter, isIncreasingMagnitude, outgoingNumericValue, incomingNumericValue, digitPlace)
    if CrossesDigitBoundary(outgoingNumericValue, incomingNumericValue, digitPlace, isIncreasingMagnitude) then
        return true
    end

    if IsDigitWrap(outgoingCharacter, incomingCharacter, isIncreasingMagnitude) then
        return true
    end

    local outgoingDigit = tonumber(outgoingCharacter)
    local incomingDigit = tonumber(incomingCharacter)
    if isIncreasingMagnitude then
        if outgoingCharacter == "" then
            -- A newly appearing leading digit continues the carry sequence.
            return incomingDigit ~= nil
        end
    elseif incomingCharacter == "" then
        -- A newly disappearing leading digit continues the borrow sequence.
        return outgoingDigit ~= nil
    end

    local digitDelta = isIncreasingMagnitude and 1 or -1
    return outgoingDigit ~= nil
        and incomingDigit ~= nil
        and incomingDigit == outgoingDigit + digitDelta
end

function RollingMeterLabel:Initialize()
    self.animationIncrementDirection = ZO_ROLLING_METER_LABEL_DIRECTION.DOWN
    self.animationEasingFunction = ZO_EaseInOutQuadratic
    self.animationIntervalMs = 250
    self.digitAnimationStaggerMs = 50
    self.wheelContainer = self:GetNamedChild("WheelContainer")
    self.wheelPool = ZO_MetaPool:New(GetRollingMeterLabelWheelSourcePool())
    self.wheelPool:SetCustomAcquireBehavior(function(wheel)
        wheel:SetParent(self.wheelContainer)
        wheel:SetOwner(self)

        if self.color then
            wheel:SetColor(unpack(self.color))
        end
        if self.font then
            wheel:SetFont(self.font)
        end
        if self.modifyTextType ~= nil then
            wheel:SetModifyTextType(self.modifyTextType)
        end
    end)
    self.wheels = {}
    self.wheelKeys = {}
    self.visibleWheelCount = 0
    self.digitWidth = 0
    self.animationStartTimeMs = nil
    self.animationEndTimeMs = nil
    self.animationStaggerDelayMs = 0
    self.color = nil
    self.font = nil
    self.modifyTextType = nil

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

function RollingMeterLabel:SetColor(...)
    self.color = {...}
    for _, wheel in ipairs(self.wheels) do
        wheel:SetColor(...)
    end
end

function RollingMeterLabel:SetFont(font)
    self.font = font
    self.digitWidth = 0
    for _, wheel in ipairs(self.wheels) do
        wheel.minimumWidth = 0
        wheel:SetFont(font)
    end
    self:UpdateDigitWidth()
    self:SetLayoutDirty(true)
end

function RollingMeterLabel:SetModifyTextType(modifyTextType)
    self.modifyTextType = modifyTextType
    for _, wheel in ipairs(self.wheels) do
        wheel:SetModifyTextType(modifyTextType)
    end
end

function RollingMeterLabel:ResetAnimationState()
    self.animationStartTimeMs = nil
    self.animationEndTimeMs = nil
    self.animationStaggerDelayMs = 0
    self.animationNormalizedIntervalOffset = nil
    self.animationOverrideEasingFunction = nil
    self.targetAnimationNormalizedIntervalOffset = nil
    self.targetAnimationOverrideEasingFunction = nil
end

function RollingMeterLabel:SynchronizeValueState(value)
    self:ResetAnimationState()
    self:CompleteWheelAnimations()
    self.targetValue = value
    self.incomingValue = value
    self.outgoingValue = value
end

function RollingMeterLabel:CommitValueImmediately(value)
    self:SynchronizeValueState(value)

    if not self:IsControlHidden() then
        self:CommitValueText(self:GetFormattedValue(value))
    end
end

function RollingMeterLabel:SetText(text)
    self:SynchronizeValueState(text)

    if not self:IsControlHidden() then
        self:CommitValueText(tostring(text or ""))
    end
end

function RollingMeterLabel:GetText()
    local text = {}
    for index = 1, self.visibleWheelCount do
        text[index] = self.wheels[index].currentText
    end
    return table.concat(text)
end

function RollingMeterLabel:GetAnimationIncrementDirection()
    return self.animationIncrementDirection
end

function RollingMeterLabel:SetAnimationIncrementDirection(direction)
    self.animationIncrementDirection = direction
end

function RollingMeterLabel:GetDigitAnimationStagger()
    return self.digitAnimationStaggerMs
end

function RollingMeterLabel:SetDigitAnimationStagger(staggerMs)
    self.digitAnimationStaggerMs = zo_max(staggerMs or 0, 0)
end

function RollingMeterLabel:GetAnimationInterval()
    return self.animationIntervalMs
end

function RollingMeterLabel:SetAnimationInterval(intervalMs)
    if self.animationStartTimeMs then
        -- An animation is in progress; adjust the end time using the amortized remainder of the new interval.
        -- Retiming each pending wheel prevents delayed wheels from being cut off mid-transition.
        local frameTimeMs = GetFrameTimeMilliseconds()
        local animationProgress = (frameTimeMs - self.animationStartTimeMs) / self.animationIntervalMs
        local remainingIntervalTimeMs = zo_max((1 - animationProgress) * intervalMs, 0)
        local animationEndTimeMs = self.animationStartTimeMs + remainingIntervalTimeMs + self.animationStaggerDelayMs
        for index = 1, self.visibleWheelCount do
            local wheel = self.wheels[index]
            if wheel:IsAnimating() then
                local digitStartTimeMs = self.animationStartTimeMs + wheel:GetAnimationDelay()
                local digitProgress = zo_clamp((frameTimeMs - digitStartTimeMs) / self.animationIntervalMs, 0, 1)
                local digitEndTimeMs
                if frameTimeMs < digitStartTimeMs then
                    digitEndTimeMs = digitStartTimeMs + intervalMs
                else
                    digitEndTimeMs = frameTimeMs + (1 - digitProgress) * intervalMs
                end
                animationEndTimeMs = zo_max(animationEndTimeMs, digitEndTimeMs)
            end
        end
        self.animationEndTimeMs = animationEndTimeMs
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
        return
    end

    self.isUpdatingLayout = true

    local totalWidth = 0
    local height = 0
    for index, wheel in ipairs(self.wheels) do
        if index <= self.visibleWheelCount then
            local minimumWidth = self:IsDigit(wheel.currentText) and self.digitWidth or 0
            wheel:SetMinimumWidth(minimumWidth)
            totalWidth = totalWidth + wheel:GetWidth()
            height = zo_max(height, wheel:GetHeight())
        else
            wheel:SetHidden(true)
        end
    end

    self:UpdateWheelAnchors()
    self.wheelContainer:SetDimensions(totalWidth, height)
    self:SetHeight(height)

    local widthConstraint
    if self.resizeToFitLabels then
        widthConstraint = totalWidth
    else
        widthConstraint = 0
    end
    self:SetDimensionConstraints(widthConstraint, 0, widthConstraint, 0)

    self:UpdateWheelContainerAnchor()

    for index = 1, self.visibleWheelCount do
        self.wheels[index]:SetHidden(false)
    end

    self.isUpdatingLayout = nil
    self:SetLayoutDirty(false)
end

function RollingMeterLabel:UpdateWheelAnchors()
    if self.isUpdatingWheelAnchors then
        return
    end

    self.isUpdatingWheelAnchors = true

    local nextWheel = nil
    for index = self.visibleWheelCount, 1, -1 do
        local wheel = self.wheels[index]
        wheel:ClearAnchors()
        if index == self.visibleWheelCount then
            wheel:SetAnchor(RIGHT)
        else
            wheel:SetAnchor(RIGHT, nextWheel, LEFT)
        end
        nextWheel = wheel
    end

    self.isUpdatingWheelAnchors = nil
end

function RollingMeterLabel:UpdateWheelContainerAnchor()
    self.wheelContainer:ClearAnchors()

    local horizontalAlignment = self.horizontalAlignment or TEXT_ALIGN_RIGHT
    local anchorPoint
    if horizontalAlignment == TEXT_ALIGN_LEFT then
        anchorPoint = TOPLEFT
    elseif horizontalAlignment == TEXT_ALIGN_CENTER then
        anchorPoint = TOP
    else
        anchorPoint = TOPRIGHT
    end

    self.wheelContainer:SetAnchor(anchorPoint)
end

function RollingMeterLabel:CreateWheel()
    local wheel, wheelKey = self.wheelPool:AcquireObject()
    table.insert(self.wheels, 1, wheel)
    table.insert(self.wheelKeys, 1, wheelKey)
    return wheel
end

function RollingMeterLabel:GetOrCreateWheel(wheelIndex)
    while #self.wheels < wheelIndex do
        self:CreateWheel()
    end
    return self.wheels[wheelIndex]
end

function RollingMeterLabel:GetFormattedValue(value)
    if value == nil then
        return ""
    end

    if self:IsCommaDelimited() then
        return ZO_CommaDelimitNumber(value)
    end

    return tostring(value)
end

function RollingMeterLabel:IsDigit(character)
    return character ~= nil and tonumber(character) ~= nil
end

function RollingMeterLabel:IsValidOutgoingAnimationCharacter(character)
    return character == "" or self:IsDigit(character) or character == "," or character == "-" or character == "+"
end

function RollingMeterLabel:GetOutgoingAnimationText(character)
    if self:IsValidOutgoingAnimationCharacter(character) then
        return character, true
    end
    return "", false
end

function RollingMeterLabel:GetDigitAnimationDelayIncrementMs(isCarryContinuation)
    -- Carry-aware spacing is larger, while the configured stagger remains the minimum delay.
    local intervalFraction = isCarryContinuation and CARRY_DELAY_INTERVAL_FRACTION or FALLBACK_DELAY_INTERVAL_FRACTION
    local intervalDelayMs = self.animationIntervalMs * intervalFraction
    return zo_max(self.digitAnimationStaggerMs, intervalDelayMs)
end

function RollingMeterLabel:GetWheelCharacter(text, wheelIndex, wheelCount)
    -- Keep the least significant digits right-aligned as the displayed width changes.
    local textIndex = wheelIndex - (wheelCount - #text)
    if textIndex < 1 or textIndex > #text then
        return ""
    end
    return string.sub(text, textIndex, textIndex)
end

function RollingMeterLabel:UpdateDigitWidth()
    local digitWidth = self.digitWidth
    for _, wheel in ipairs(self.wheels) do
        if self:IsDigit(wheel.currentText) then
            digitWidth = zo_max(digitWidth, wheel:GetWidth())
        end
    end
    self.digitWidth = digitWidth
end

function RollingMeterLabel:CommitValueText(text)
    local wheelCount = #text
    -- Wheels are stored from left to right, so shrinking releases leading wheels first.
    local wheelsToRelease = #self.wheels - wheelCount
    for _ = 1, wheelsToRelease do
        self.wheelPool:ReleaseObject(self.wheelKeys[1])
        table.remove(self.wheels, 1)
        table.remove(self.wheelKeys, 1)
    end

    self.visibleWheelCount = wheelCount

    for wheelIndex = 1, wheelCount do
        local wheel = self:GetOrCreateWheel(wheelIndex)
        wheel:SetStaticValue(self:GetWheelCharacter(text, wheelIndex, wheelCount))
    end
    for wheelIndex = wheelCount + 1, #self.wheels do
        self.wheels[wheelIndex]:SetHidden(true)
    end

    self:UpdateDigitWidth()
    self:SetLayoutDirty(true)
end

function RollingMeterLabel:ReleaseWheels()
    if not self.wheelPool:HasActiveObjects() then
        return
    end

    if self.transitionManager and self.transitionManager:IsTransitioning() then
        self.transitionManager:SetValueImmediately(self.transitionManager.targetValue)
    else
        self:CommitValueImmediately(self.targetValue)
    end

    self.wheelPool:ReleaseAllObjects()
    self.wheels = {}
    self.wheelKeys = {}
    self.visibleWheelCount = 0
    self.digitWidth = 0
    self:SetLayoutDirty(true)
end

function RollingMeterLabel:RestoreWheels()
    if self.wheelPool:HasActiveObjects() then
        return
    end

    self:CommitValueImmediately(self.targetValue)
end

function RollingMeterLabel:GetAssociatedDigitDelay(wheelIndex, character, activeDigitDelays)
    if character == "," then
        return activeDigitDelays[wheelIndex - 1]
    elseif character == "-" or character == "+" then
        return activeDigitDelays[wheelIndex + 1]
    end
    return nil
end

function RollingMeterLabel:ApplyStaticWheelTransitions(wheelCount, wheelData, activeDigitDelays)
    for wheelIndex = 1, wheelCount do
        local wheelInfo = wheelData[wheelIndex]
        local wheel = self.wheels[wheelIndex]
        if activeDigitDelays[wheelIndex] ~= nil then
            if wheelInfo.incomingIsDigit and not wheelInfo.outgoingIsDigit then
                local associatedDelayMs = self:GetAssociatedDigitDelay(wheelIndex, wheelInfo.outgoingCharacter, activeDigitDelays)
                if associatedDelayMs ~= nil then
                    wheel:SetAnimationDelay(associatedDelayMs)
                    activeDigitDelays[wheelIndex] = associatedDelayMs
                end
            end
        elseif not (wheelInfo.incomingIsDigit and wheelInfo.outgoingIsDigit and wheelInfo.outgoingCharacter == wheelInfo.incomingCharacter) then
            local associatedCharacter = wheelInfo.incomingCharacter ~= "" and wheelInfo.incomingCharacter or wheelInfo.outgoingCharacter
            local staticValueDelayMs = self:GetAssociatedDigitDelay(wheelIndex, associatedCharacter, activeDigitDelays) or 0
            wheel:SetStaticValue(wheelInfo.incomingCharacter, staticValueDelayMs)
        end
    end
end

function RollingMeterLabel:PrepareValueTransition(outgoingText, incomingText)
    local wheelCount = zo_max(#outgoingText, #incomingText)
    local isTransitioning = self.transitionManager ~= nil and self.transitionManager:IsTransitioning()
    if isTransitioning then
        local transitionTargetText = self:GetFormattedValue(self.transitionManager.targetValue)
        wheelCount = zo_max(wheelCount, #transitionTargetText)
    end
    self.visibleWheelCount = wheelCount

    local wheelData = {}
    local outgoingDigitPlaces = {}
    local incomingDigitPlaces = {}
    local shouldRollUnchangedDigits = isTransitioning
    local higherOrderDigitChanged = {}
    local hasChangedHigherOrderDigit = false

    for wheelIndex = 1, wheelCount do
        local wheelInfo =
        {
            outgoingCharacter = self:GetWheelCharacter(outgoingText, wheelIndex, wheelCount),
            incomingCharacter = self:GetWheelCharacter(incomingText, wheelIndex, wheelCount),
        }
        wheelInfo.outgoingIsDigit = self:IsDigit(wheelInfo.outgoingCharacter)
        wheelInfo.incomingIsDigit = self:IsDigit(wheelInfo.incomingCharacter)
        local isChangedDigit = wheelInfo.outgoingIsDigit ~= wheelInfo.incomingIsDigit
            or (wheelInfo.outgoingIsDigit and wheelInfo.incomingIsDigit and wheelInfo.outgoingCharacter ~= wheelInfo.incomingCharacter)
        wheelData[wheelIndex] = wheelInfo

        wheelInfo.isChangedDigit = isChangedDigit

        if shouldRollUnchangedDigits then
            higherOrderDigitChanged[wheelIndex] = hasChangedHigherOrderDigit
            if isChangedDigit then
                hasChangedHigherOrderDigit = true
            end
        end
    end
    -- Track each digit's decimal place independently because punctuation and signs occupy wheels.
    local outgoingDigitPlace = 0
    local incomingDigitPlace = 0
    for wheelIndex = wheelCount, 1, -1 do
        local wheelInfo = wheelData[wheelIndex]
        if wheelInfo.outgoingIsDigit then
            outgoingDigitPlaces[wheelIndex] = outgoingDigitPlace
            outgoingDigitPlace = outgoingDigitPlace + 1
        end
        if wheelInfo.incomingIsDigit then
            incomingDigitPlaces[wheelIndex] = incomingDigitPlace
            incomingDigitPlace = incomingDigitPlace + 1
        end
    end

    local activeDigitDelays = {}
    local animatedDigitCount = 0
    local maximumAnimationDelayMs = 0
    local animationDelayMs = 0
    local hasChangedLowerOrderDigit = false
    local outgoingNumericValue = GetNumericValue(self.outgoingValue)
    local incomingNumericValue = GetNumericValue(self.incomingValue)
    local isIncreasingMagnitude = outgoingNumericValue ~= nil and incomingNumericValue ~= nil and zo_abs(incomingNumericValue) > zo_abs(outgoingNumericValue)
    -- Only changed digits participate by default. During stepped transitions, same-value lower
    -- digits also roll when a more significant digit changes.
    -- Process from least significant to most significant so carry and borrow timing moves leftward.
    -- The transition manager may skip intermediate values, so boundary checks detect hidden carries.
    for wheelIndex = wheelCount, 1, -1 do
        local wheelInfo = wheelData[wheelIndex]
        local wheel = self:GetOrCreateWheel(wheelIndex)
        local outgoingCharacter = wheelInfo.outgoingCharacter
        local incomingCharacter = wheelInfo.incomingCharacter
        local isUnchangedDigit = wheelInfo.incomingIsDigit and wheelInfo.outgoingIsDigit and not wheelInfo.isChangedDigit
        local outgoingAnimationText, isValidOutgoingAnimationCharacter = self:GetOutgoingAnimationText(outgoingCharacter)
        local isAnimatedDigit = wheelInfo.isChangedDigit
            and ((wheelInfo.incomingIsDigit and isValidOutgoingAnimationCharacter)
                or (incomingCharacter == "" and wheelInfo.outgoingIsDigit))
        if shouldRollUnchangedDigits and isUnchangedDigit and higherOrderDigitChanged[wheelIndex] then
            isAnimatedDigit = true
        end

        if isAnimatedDigit then
            local digitPlace = incomingDigitPlaces[wheelIndex] or outgoingDigitPlaces[wheelIndex]
            local isCarryContinuation = hasChangedLowerOrderDigit and IsCarryContinuation(outgoingCharacter, incomingCharacter, isIncreasingMagnitude, outgoingNumericValue, incomingNumericValue, digitPlace)
            if hasChangedLowerOrderDigit then
                animationDelayMs = animationDelayMs + self:GetDigitAnimationDelayIncrementMs(isCarryContinuation)
            end
            wheel:SetAnimatedValue(outgoingAnimationText, incomingCharacter)
            wheel:SetAnimationDelay(animationDelayMs)
            activeDigitDelays[wheelIndex] = animationDelayMs
            maximumAnimationDelayMs = zo_max(maximumAnimationDelayMs, animationDelayMs)
            animatedDigitCount = animatedDigitCount + 1
            if not isUnchangedDigit then
                hasChangedLowerOrderDigit = true
            end
        end
    end

    -- Apply punctuation and other static wheels after digit delays are known so they follow adjacent digits.
    self:ApplyStaticWheelTransitions(wheelCount, wheelData, activeDigitDelays)

    self:UpdateDigitWidth()
    self:SetLayoutDirty(true)
    return animatedDigitCount, maximumAnimationDelayMs
end

function RollingMeterLabel:UpdateWheelAnimations(frameTimeMs)
    -- Every digit keeps the same roll duration; its delay only shifts when that roll starts.
    for index = 1, self.visibleWheelCount do
        local wheel = self.wheels[index]
        if wheel:HasPendingStaticValue() and frameTimeMs >= self.animationStartTimeMs + wheel:GetAnimationDelay() then
            wheel:ApplyPendingStaticValue()
        end
        if wheel:IsAnimating() then
            local animationProgress = zo_clamp((frameTimeMs - self.animationStartTimeMs - wheel:GetAnimationDelay()) / self.animationIntervalMs, 0, 1)
            if self.animationOverrideEasingFunction then
                animationProgress = zo_max(self.animationOverrideEasingFunction(animationProgress), 0)
            elseif self.animationEasingFunction then
                animationProgress = zo_max(self.animationEasingFunction(animationProgress), 0)
            end
            wheel:UpdateAnimation(animationProgress, self.animationDirection)
        end
    end
end

function RollingMeterLabel:CompleteWheelAnimations()
    for index = 1, self.visibleWheelCount do
        local wheel = self.wheels[index]
        if wheel:IsAnimating() then
            wheel:CompleteAnimation()
        end
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

function RollingMeterLabel:IsCommaDelimited()
    return self.isCommaDelimited
end

function RollingMeterLabel:SetIsCommaDelimited(isCommaDelimited)
    self.isCommaDelimited = isCommaDelimited
end

function RollingMeterLabel:IsLayoutDirty()
    return self.isLayoutDirty
end

function RollingMeterLabel:SetLayoutDirty(dirty)
    self.isLayoutDirty = dirty ~= false
end

function RollingMeterLabel:OnWheelRectChanged()
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
        self:UpdateWheelAnimations(GetFrameTimeMilliseconds())
    else
        self:UpdateValue()
    end
end

function RollingMeterLabel:UpdateValue()
    if self.targetAnimationNormalizedIntervalOffset then
        self.animationNormalizedIntervalOffset = self.targetAnimationNormalizedIntervalOffset
        self.targetAnimationNormalizedIntervalOffset = nil
    end

    if self.targetAnimationOverrideEasingFunction then
        self.animationOverrideEasingFunction = self.targetAnimationOverrideEasingFunction
        self.targetAnimationOverrideEasingFunction = nil
    end

    local frameTimeMs = GetFrameTimeMilliseconds()
    local intervalOffset = self.animationNormalizedIntervalOffset
    self:CompleteWheelAnimations()
    local isFinalAnimation = self.incomingValue == self.targetValue
    if isFinalAnimation then
        self.animationEndTimeMs = nil
        self.animationStartTimeMs = nil
        self.animationStaggerDelayMs = 0
        self:CommitValueText(self:GetFormattedValue(self.incomingValue))
    else
        self.outgoingValue = self.incomingValue
        self.incomingValue = self.targetValue

        if intervalOffset then
            local animationOffsetMs = self.animationIntervalMs * intervalOffset
            self.animationStartTimeMs = frameTimeMs - animationOffsetMs
            self.animationEndTimeMs = frameTimeMs + self.animationIntervalMs - animationOffsetMs
        else
            self.animationStartTimeMs = frameTimeMs
            self.animationEndTimeMs = frameTimeMs + self.animationIntervalMs
        end

        local outgoingNumericValue = tonumber(self.outgoingValue)
        local incomingNumericValue = tonumber(self.incomingValue)
        local invertDirection = outgoingNumericValue and incomingNumericValue and outgoingNumericValue > incomingNumericValue
        if invertDirection then
            self.animationDirection = self.animationIncrementDirection == ZO_ROLLING_METER_LABEL_DIRECTION.DOWN and ZO_ROLLING_METER_LABEL_DIRECTION.UP or ZO_ROLLING_METER_LABEL_DIRECTION.DOWN
        else
            self.animationDirection = self.animationIncrementDirection
        end

        local outgoingText = self:GetFormattedValue(self.outgoingValue)
        local incomingText = self:GetFormattedValue(self.incomingValue)
        local animatedDigitCount, animationStaggerDelayMs = self:PrepareValueTransition(outgoingText, incomingText)
        self.animationStaggerDelayMs = animationStaggerDelayMs
        -- Keep each digit's roll duration intact and let the transition manager wait for the stagger tail.
        self.animationEndTimeMs = self.animationEndTimeMs + self.animationStaggerDelayMs
        self:OnUpdate()

        if animatedDigitCount > 0 and not self:IsHidden() then
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

    self.animationNormalizedIntervalOffset = nil

    if self.valueUpdatedCallback then
        self.valueUpdatedCallback(self, self.outgoingValue, self.incomingValue, self.targetValue)
    end

    return not isFinalAnimation
end

function RollingMeterLabel:SetValue(text, animationNormalizedIntervalOffset, animationOverrideEasingFunction)
    self.targetValue = text

    if self:IsControlHidden() then
        self:CommitValueImmediately(self.targetValue)
        return
    end

    if animationNormalizedIntervalOffset and animationNormalizedIntervalOffset >= 1 then
        self:CommitValueImmediately(self.targetValue)
        return
    end

    if self.animationStartTimeMs then
        self.targetAnimationNormalizedIntervalOffset = animationNormalizedIntervalOffset
        self.targetAnimationOverrideEasingFunction = animationOverrideEasingFunction
        return
    end

    self.animationNormalizedIntervalOffset = animationNormalizedIntervalOffset
    self.animationOverrideEasingFunction = animationOverrideEasingFunction
    self:UpdateValue()
end

function RollingMeterLabel:OnHide()
    self:ReleaseWheels()
end

function RollingMeterLabel:OnShow()
    self:RestoreWheels()
end

function RollingMeterLabel:SetValueUpdatedCallback(callbackFunction)
    self.valueUpdatedCallback = callbackFunction
end

function ZO_RollingMeterLabel_OnInitialized(containerControl)
    zo_mixin(containerControl, RollingMeterLabel)
    containerControl:Initialize()
end

function ZO_RollingMeterLabel_OnHide(containerControl)
    containerControl:OnHide()
end

function ZO_RollingMeterLabel_OnShow(containerControl)
    containerControl:OnShow()
end

-------------------------------
--RollingMeterLabelTransition--
-------------------------------

local BASE_TRANSITION_INTERVAL_MAX_MS = 300       -- Slowest roll over animation interval
local BASE_TRANSITION_INTERVAL_MIN_MS = 80        -- Fastest roll over animation interval
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
    self.maxTransitionSteps = 15
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

function ZO_RollingMeterLabelTransition:IsTransitioning()
    return self.currentTransitionStep ~= nil
end

function ZO_RollingMeterLabelTransition:GetTransitionEasingFunction()
    return self.transitionEasingFunction
end

function ZO_RollingMeterLabelTransition:SetTransitionEasingFunction(easingFunction)
    self.transitionEasingFunction = easingFunction or ZO_LinearEase
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
    if optionalInitialValue ~= nil then
        self.currentValue = optionalInitialValue
        self.initialValue = optionalInitialValue
    else
        self.currentValue = self.currentValue or 0
        self.initialValue = self.currentValue
    end

    if self.control:IsControlHidden() then
        self.currentValue = self.targetValue
        self.initialValue = self.targetValue
        self.currentTransitionStep = nil
        self.numTransitionSteps = nil
        local ANIMATION_NORMALIZED_INTERVAL_OFFSET = 1
        self.control:SetValue(self.targetValue, ANIMATION_NORMALIZED_INTERVAL_OFFSET)
        return
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
    local integerDelta = zo_ceil(zo_abs(self.targetValue - self.currentValue))
    local transitionSteps = zo_clamp(integerDelta, 1, self.maxTransitionSteps)
    self.numTransitionSteps = transitionSteps
    self.currentTransitionStep = 0

    if self.numTransitionSteps < self.maxTransitionSteps then
        self:SetTransitionEasingFunction(ZO_LinearEase)
    else
        -- Generate a smooth transition easing function that ensures that the first and last few
        -- transitions are in increments of 1 to reinforce the visual appearance of speeding up
        -- and slowing down respectively.
        local numTransitionStepsPerBoundary = zo_min(2, zo_floor(self.maxTransitionSteps * 0.5))
        local normalizedTransitionStepSize = 1.0 / self.numTransitionSteps -- Step size to increment per transition.
        local normalizedUnitStepSize = 1.0 / zo_max(1, integerDelta) -- Step size to increment by one.
        self:SetTransitionEasingFunction(function(progress)
            local transitionStepIndex = progress / normalizedTransitionStepSize
            local easedProgress = ZO_EaseInOutCubic(progress)

            if transitionStepIndex <= numTransitionStepsPerBoundary then
                -- Slow initial starting increments.
                local unitStepIndex = transitionStepIndex
                return zo_min(easedProgress, unitStepIndex * normalizedUnitStepSize)
            end

            if transitionStepIndex >= self.numTransitionSteps - numTransitionStepsPerBoundary then
                -- Slow final ending increments.
                local unitStepIndex = integerDelta - (self.numTransitionSteps - transitionStepIndex)
                return zo_max(easedProgress, unitStepIndex * normalizedUnitStepSize)
            end

            -- Standard, eased interval.
            return easedProgress
        end)
    end

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
    if not self:IsTransitioning() then
        return
    end

    if self.control:GetAnimationProgress() then
        -- Wait for current animation to complete.
        return
    end

    -- Increment transition step.
    local currentStep = self.currentTransitionStep + 1
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
    local easedProgress = self:GetTransitionEasingFunction()(progress)
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