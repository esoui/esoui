ZO_GAMEPAD_FLOATING_SCROLL_TOOLTIP_TOP_ICON_PADDING_Y = 35
ZO_GAMEPAD_FLOATING_SCROLL_SAFE_TOOLTIP_TOP_OFFSET = ZO_GAMEPAD_SAFE_ZONE_INSET_Y + ZO_GAMEPAD_FLOATING_SCROLL_TOOLTIP_TOP_ICON_PADDING_Y

ZO_ScrollTooltip_Gamepad = {} -- A scrolling wrapper for ZO_Tooltip

local MIN_SCROLL_VALUE = 0
local MAX_SCROLL_VALUE = 100

function ZO_ScrollTooltip_Gamepad:RefreshDisplayedKeybinds()
    local enabled = self.inputEnabled
    local shouldShowGamepadKeybinds = ZO_Keybindings_ShouldShowGamepadKeybind()
    local hideGamepad = not enabled or not self.canScroll or not shouldShowGamepadKeybinds
    local hideKeyboard = not enabled or not self.canScroll or shouldShowGamepadKeybinds
    self.scrollIndicator:SetHidden(hideGamepad)
    self.scrollKeyUp:SetHidden(hideKeyboard)
    self.scrollKeyDown:SetHidden(hideKeyboard)
end

function ZO_ScrollTooltip_Gamepad:Initialize(control, styleNamespace, style)
    local scroll = control:GetNamedChild("Scroll")
    local scrollChild = scroll:GetNamedChild("ScrollChild")
    local tooltip = scrollChild:GetNamedChild("Tooltip")
    ZO_Tooltip:Initialize(tooltip, styleNamespace, style)
    zo_mixin(control, ZO_ScrollTooltip_Gamepad)
    control.tooltip = tooltip
    
    control.scroll = scroll
    control.scrollChild = scrollChild
    control.scrollIndicator = control:GetNamedChild("ScrollIndicator")
    control.scrollKeyUp = control:GetNamedChild("ScrollKeyUp")
    control.scrollKeyDown = control:GetNamedChild("ScrollKeyDown")
    ZO_SetScrollMaxFadeGradientSize(control, 256)
    control.animation, control.timeline = ZO_CreateScrollAnimation(control)
    control.scrollValue = MIN_SCROLL_VALUE
    control.useFadeGradient = true
    ZO_ScrollAnimation_MoveWindow(control, control.scrollValue)

    control:SetHandler("OnEffectivelyShown", function() control:OnEffectivelyShown() end)
    control:SetHandler("OnEffectivelyHidden", function() control:OnEffectivelyHidden() end)
    control:SetHandler("OnUpdate", function() control:OnUpdate() end)
    scroll:SetHandler("OnScrollExtentsChanged", function(...) control:OnScrollExtentsChanged(...) end)

    local function OnInputChanged()
        if IsInGamepadPreferredMode() then
            local gamepadInput = WasLastInputGamepad()
            local hideGamepad = not gamepadInput or not control.canScroll
            local hideKeyboard = gamepadInput or not control.canScroll
            control:RefreshDisplayedKeybinds()
        end
    end

    local SHOW_UNBOUND = true
    local DEFAULT_GAMEPAD_ACTION_NAME = nil
    ZO_Keybindings_RegisterLabelForBindingUpdate(control.scrollKeyUp, "UI_SHORTCUT_RIGHT_STICK_UP", SHOW_UNBOUND, DEFAULT_GAMEPAD_ACTION_NAME, OnInputChanged)
    ZO_Keybindings_RegisterLabelForBindingUpdate(control.scrollKeyDown, "UI_SHORTCUT_RIGHT_STICK_DOWN")
    -- We only need to register one of the above with OnInputChanged because one call of that function does everything we need

    control.baseMagnitude = 0.4
    control.magnitude = 1

    control.inputEnabled = true
    control.directionalInputActivated = false
end

function ZO_ScrollTooltip_Gamepad:SetInputEnabled(enabled)
    self.inputEnabled = enabled
    local wasLastInputGamepad = WasLastInputGamepad()
    local hideGamepad = not enabled or not self.canScroll or not wasLastInputGamepad
    local hideKeyboard = not enabled or not self.canScroll or wasLastInputGamepad
    self:RefreshDisplayedKeybinds()
    self:RefreshDirectionalInputActivation()
end

function ZO_ScrollTooltip_Gamepad:OnEffectivelyShown()
    self.scroll:SetVerticalScroll(MIN_SCROLL_VALUE)
    self.scrollValue = MIN_SCROLL_VALUE
    self:RefreshDirectionalInputActivation()
end

function ZO_ScrollTooltip_Gamepad:RefreshDirectionalInputActivation()
    local _, verticalExtents = self.scroll:GetScrollExtents()
    local canScroll = verticalExtents > 0 and self.inputEnabled
    if not self:IsHidden() and canScroll then
        if not self.directionalInputActivated then
            self.directionalInputActivated = true
            ZO_SCROLL_SHARED_INPUT:Activate(self)
        end
    else
        if self.directionalInputActivated then
            self.directionalInputActivated = false
            ZO_SCROLL_SHARED_INPUT:Deactivate()
        end
    end
end

function ZO_ScrollTooltip_Gamepad:OnEffectivelyHidden()
    self:RefreshDirectionalInputActivation()
end

function ZO_ScrollTooltip_Gamepad:OnScrollExtentsChanged(scroll, horizontalExtents, verticalExtents)
    -- If our height is > 0, and our scroll child is bigger than self (which means it would have to scroll to fit)...
    self.canScroll = verticalExtents > 0 and self:GetHeight() < self.scrollChild:GetHeight() and not zo_floatsAreEqual(self:GetHeight(), self.scrollChild:GetHeight())
    local wasLastInputGamepad = WasLastInputGamepad()
    local hideGamepad = not self.canScroll or not wasLastInputGamepad
    local hideKeyboard = not self.canScroll or wasLastInputGamepad
    self:RefreshDisplayedKeybinds()

    ZO_UpdateScrollFade(self.useFadeGradient, self.scroll, ZO_SCROLL_DIRECTION_VERTICAL, ZO_GetScrollMaxFadeGradientSize(self))
    self:RefreshDirectionalInputActivation()
end

function ZO_ScrollTooltip_Gamepad:SetMagnitude(magnitude)
    self.magnitude = magnitude
end

function ZO_ScrollTooltip_Gamepad:OnUpdate()
    local scrollInput = ZO_SCROLL_SHARED_INPUT:GetY()
    if scrollInput ~= 0 and self.inputEnabled then
        ZO_ScrollRelative(self, -scrollInput * self.magnitude * self.baseMagnitude * GetFrameDeltaTimeMilliseconds())
    end
end

function ZO_ScrollTooltip_Gamepad:ResetToTop()
    self.scrollValue = MIN_SCROLL_VALUE

    ZO_ScrollAnimation_MoveWindow(self, self.scrollValue)
    ZO_UpdateScrollFade(self.useFadeGradient, self.scroll, ZO_SCROLL_DIRECTION_VERTICAL, ZO_GetScrollMaxFadeGradientSize(self))
end

function ZO_ScrollTooltip_Gamepad:ClearLines(resetScroll)
    self.tooltip:ClearLines()
    if resetScroll ~= false then -- Default to true, but allow overriding.
        self.scrollValue = MIN_SCROLL_VALUE
        ZO_ScrollAnimation_MoveWindow(self, self.scrollValue)
        ZO_UpdateScrollFade(self.useFadeGradient, self.scroll, ZO_SCROLL_DIRECTION_VERTICAL, ZO_GetScrollMaxFadeGradientSize(self))
    end
end

function ZO_ScrollTooltip_Gamepad:HasControls()
    return self.tooltip:HasControls()
end

function ZO_ScrollTooltip_Gamepad:LayoutItem(itemLink)
    return self.tooltip:LayoutItem(itemLink)
end

function ZO_ScrollTooltip_Gamepad:LayoutBagItem(bagId, slotIndex)
    return self.tooltip:LayoutBagItem(bagId, slotIndex)
end

function ZO_ScrollTooltip_Gamepad:LayoutTradeItem(tradeType, tradeIndex)
    return self.tooltip:LayoutTradeItem(tradeType, tradeIndex)
end

do
    local ANCHORS_TO_BACKGROUND = true

    local function UpdateHeight(control)
        local contentHeight = control.scrollTooltip.scrollChild:GetHeight()
        
        if not zo_floatsAreEqual(contentHeight, control.lastContentHeight) or control.forceResizeUpdate then
            control.lastContentHeight = contentHeight
            local totalHeight = contentHeight + ZO_GAMEPAD_FLOATING_SCROLL_TOOLTIP_TOP_ICON_PADDING_Y * 2
            control:SetHeight(totalHeight)
            control.forceResizeUpdate = false

            control.scrollTooltip:OnScrollExtentsChanged(control.scrollTooltip.scroll, 0, totalHeight)
        end
    end

    local function ForceResizeUpdate(control)
        control.forceResizeUpdate = true
    end

    function ZO_ResizingFloatingScrollTooltip_Gamepad_OnInitialized(control, tooltipStyles, screenResizeHandler, scrollIndicatorSide, scrollIndicatorOffsetX)
        control.icon = control:GetNamedChild("Icon")
        control.scrollTooltip = control:GetNamedChild("ContainerTip")
        ZO_ScrollTooltip_Gamepad:Initialize(control.scrollTooltip, tooltipStyles or ZO_TOOLTIP_STYLES)
        control.lastContentHeight = 0
        control.scrollTooltip.scrollChild:SetHandler("OnRectHeightChanged", function() UpdateHeight(control) end)
        control.tip = control.scrollTooltip.tooltip
        control.tip.icon = control.icon
        control.tip.gamepadTooltipContainerBorderControl = control:GetNamedChild("Border")
        if screenResizeHandler then
            control:RegisterForEvent(EVENT_SCREEN_RESIZED, function()
                screenResizeHandler(control)
                control.forceResizeUpdate = true
            end)
            control:SetHandler("OnEffectivelyShown", ForceResizeUpdate)
            control.scrollTooltip.scroll:SetHandler("OnScrollExtentsChanged", nil)
            screenResizeHandler(control)
        end

        if scrollIndicatorSide then
            ZO_Scroll_Gamepad_SetScrollIndicatorSide(control.scrollTooltip.scrollIndicator, control, scrollIndicatorSide, scrollIndicatorOffsetX, nil, ANCHORS_TO_BACKGROUND)
        end
    end
end