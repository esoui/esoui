ZO_ScrollContainer_Shared = {}

local SLIDER_MIN_VALUE = 0
local MIN_SCROLL_VALUE = 0
local MAX_SCROLL_VALUE = 100

function ZO_ScrollContainer_Shared:Initialize()
    self.scroll = self:GetNamedChild("Scroll")
    self.scroll:SetHandler("OnRectHeightChanged", function(...) self:OnScrollHeightChanged(...) end)
    self.scroll:SetHandler("OnMouseWheel", function(...) self:OnScrollBarMouseWheel(...) end)
    self.scroll:SetHandler("OnScrollOffsetChanged", function(...) self:OnScrollOffsetChanged(...) end)

    self.scrollbar = self:GetNamedChild("ScrollBar")
    self.scrollUpButton = self.scrollbar:GetNamedChild("Up")
    self.scrollUpButton:SetHandler("OnMouseDown", ZO_ScrollUp_OnMouseDown)
    self.scrollDownButton = self.scrollbar:GetNamedChild("Down")
    self.scrollDownButton:SetHandler("OnMouseDown", ZO_ScrollDown_OnMouseDown)
    self.scrollbar:SetHandler("OnRectHeightChanged", function(...) self:OnScrollHeightChanged(...) end)
    self.scrollbar:SetHandler("OnMouseWheel", function(...) self:OnScrollBarMouseWheel(...) end)
    self.scrollbar:SetHandler("OnValueChanged", function(...) self:OnScrollBarValueChanged(...) end)

    self.isScrollBarEthereal = false
    self.useScrollbar = true
    self.hideScrollBarOnDisabled = true
    self.useFadeGradient = true

    self:UpdateScrollBar()

    self:SetHandler("OnUpdate", function() self:OnUpdate() end)
    self:SetHandler("OnEffectivelyShown", function() self:OnEffectivelyShown() end)
    self:SetHandler("OnEffectivelyHidden", function() self:OnEffectivelyHidden() end)
    self.scroll:SetHandler("OnScrollExtentsChanged", function(...) self:OnScrollExtentsChanged(...) end)

    self.scrollIndicator = self:GetNamedChild("ScrollIndicator")
    self.scrollKeyUp = self:GetNamedChild("ScrollKeyUp")
    self.scrollKeyDown = self:GetNamedChild("ScrollKeyDown")

    self.scrollInput = 0
    self.scrollValue = SLIDER_MIN_VALUE
    self.directionalInputActivated = false
    self.scrollIndicatorEnabled = true

    self.animation, self.timeline = ZO_CreateScrollAnimation(self)

    local function OnInputChanged()
        if IsInGamepadPreferredMode() then
            self:UpdateScrollIndicator()
        end
    end

    local SHOW_UNBOUND = true
    local DEFAULT_GAMEPAD_ACTION_NAME = nil
    ZO_Keybindings_RegisterLabelForBindingUpdate(self.scrollKeyUp, "UI_SHORTCUT_RIGHT_STICK_UP", SHOW_UNBOUND, DEFAULT_GAMEPAD_ACTION_NAME, OnInputChanged)
    ZO_Keybindings_RegisterLabelForBindingUpdate(self.scrollKeyDown, "UI_SHORTCUT_RIGHT_STICK_DOWN")
    -- We only need to register one of the above with OnInputChanged because one call of that function does everything we need

    ZO_UpdateScrollFade(self.useFadeGradient, self.scroll, ZO_SCROLL_DIRECTION_VERTICAL)

    self:RegisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function(_, ...) self:OnGamepadPreferredModeChanged(...) end)

    self:OnGamepadPreferredModeChanged(IsInGamepadPreferredMode())
end

function ZO_ScrollContainer_Shared:ResetToTop()
    self.scrollValue = SLIDER_MIN_VALUE

    ZO_ScrollAnimation_MoveWindow(self, self.scrollValue)
    ZO_UpdateScrollFade(self.useFadeGradient, self.scroll, ZO_SCROLL_DIRECTION_VERTICAL, ZO_GetScrollMaxFadeGradientSize(self))
end

function ZO_ScrollContainer_Shared:SetScrollIndicatorEnabled(enabled)
    self.scrollIndicatorEnabled = enabled
    self:UpdateScrollIndicator()
end

function ZO_ScrollContainer_Shared:UpdateScrollIndicator()
    local _, verticalExtents = self.scroll:GetScrollExtents()
    local shouldShowGamepadKeybinds = ZO_Keybindings_ShouldShowGamepadKeybind()
    local hideGamepad = not (self.scrollIndicatorEnabled and verticalExtents ~= 0 and shouldShowGamepadKeybinds)
    local hideKeyboard = not (self.scrollIndicatorEnabled and verticalExtents ~= 0 and not shouldShowGamepadKeybinds)
    self.scrollIndicator:SetHidden(hideGamepad)
    self.scrollKeyUp:SetHidden(hideKeyboard)
    self.scrollKeyDown:SetHidden(hideKeyboard)
end

function ZO_ScrollContainer_Shared:UpdateScrollBar()
    if IsInGamepadPreferredMode() then
        return
    end

    local scroll = self.scroll
    local _, verticalOffset = scroll:GetScrollOffsets()
    local _, verticalExtents = scroll:GetScrollExtents()
    local scrollbar  = self.scrollbar

    --thumb resizing
    local scale = scroll:GetScale()
    local scrollBarHeight = scrollbar:GetHeight() / scale
    local scrollAreaHeight = scroll:GetHeight() / scale
    if verticalExtents > 0 and scrollBarHeight >= 0 and scrollAreaHeight >= 0 then
        local thumbHeight = scrollBarHeight * scrollAreaHeight / (verticalExtents + scrollAreaHeight)
        scrollbar:SetThumbTextureHeight(thumbHeight)
    else
        scrollbar:SetThumbTextureHeight(scrollBarHeight)
    end

    --set mouse input enabled based on scrollability
    local scrollEnabled = verticalExtents > 0 or verticalOffset > 0
    scroll:SetMouseEnabled(scrollEnabled)

    --auto scroll bar hiding
    local wasHidden = scrollbar:IsHidden()
    local scrollbarHidden = not self.useScrollbar or (self.hideScrollBarOnDisabled and not scrollEnabled) or self.isScrollBarEthereal
    scrollbar:SetHidden(scrollbarHidden)
    local maxScrollValue = (not scrollbarHidden or self.isScrollBarEthereal) and MAX_SCROLL_VALUE or MIN_SCROLL_VALUE
    scrollbar:SetMinMax(MIN_SCROLL_VALUE, maxScrollValue)
    if wasHidden and not scrollbarHidden and scrollbar.resetScrollbarOnShow then
        ZO_Scroll_ResetToTop(self)
        self.scrollValue = MIN_SCROLL_VALUE
    end

    if verticalExtents > 0 then
        local previousScrollBarValue = scrollbar:GetValue()
        verticalOffset = self.scrollRawOffset and self.scrollRawOffset or verticalOffset
        local finalValue = MAX_SCROLL_VALUE * (verticalOffset / verticalExtents)
        if not zo_floatsAreEqual(previousScrollBarValue, finalValue) then
            scrollbar:SetValue(finalValue)
        end

        -- If the previous and current scrollBar values are the same, 
        -- the onValueChanged function will not be invoked to update the scroll child position.
        -- We need to explicitly call to recalculate our scroll child position since our extents changed.
        if previousScrollBarValue == scrollbar:GetValue() then
            scroll:SetVerticalScroll(verticalOffset)
        end
    else
        ZO_Scroll_ResetToTop(self)
    end
    self.scrollRawOffset = nil
end

function ZO_ScrollContainer_Shared:SetDisabled(disabled)
    self.disabled = disabled
    self:RefreshDirectionalInputActivation()
end

function ZO_ScrollContainer_Shared:RefreshDirectionalInputActivation()
    local _, verticalExtents = self.scroll:GetScrollExtents()
    local canScroll = verticalExtents > 0
    if not self.disabled and not self:IsHidden() and canScroll then
        if not self.directionalInputActivated then
            self.directionalInputActivated = true
            ZO_SCROLL_SHARED_INPUT:Activate(self, self)
        end
    else
        if self.directionalInputActivated then
            self.directionalInputActivated = false
            ZO_SCROLL_SHARED_INPUT:Deactivate(self)
        end
    end
end

function ZO_ScrollContainer_Shared:OnEffectivelyShown()
    self:ResetToTop()
    self:RefreshDirectionalInputActivation()

    self.inScrollArea = nil
end

function ZO_ScrollContainer_Shared:OnEffectivelyHidden()
    self:RefreshDirectionalInputActivation()

    ZO_VerticalScrollbarBase_OnScrollAreaExit(self.scrollbar)
end

function ZO_ScrollContainer_Shared:OnScrollHeightChanged()
    if IsInGamepadPreferredMode() then
        self:UpdateScrollIndicator()
    else
        self:UpdateScrollBar()
    end

    ZO_UpdateScrollFade(self.useFadeGradient, self.scroll, ZO_SCROLL_DIRECTION_VERTICAL)
end

function ZO_ScrollContainer_Shared:OnScrollExtentsChanged()
    if IsInGamepadPreferredMode() then
        self:RefreshDirectionalInputActivation()
        self:UpdateScrollIndicator()
    else
        self:UpdateScrollBar()
    end

    ZO_UpdateScrollFade(self.useFadeGradient, self.scroll, ZO_SCROLL_DIRECTION_VERTICAL)
end

function ZO_ScrollContainer_Shared:OnScrollBarMouseWheel(control, delta)
    ZO_ScrollRelative(self, -delta * 40)

    if self.onInteractWithScrollbarCallback then
        self.onInteractWithScrollbarCallback()
    end
end

function ZO_ScrollContainer_Shared:OnScrollOffsetChanged(control, delta)
    self:UpdateScrollBar()
end

function ZO_ScrollContainer_Shared:OnScrollBarValueChanged(control, value)
    local scroll = self.scroll
    local _, verticalExtents = scroll:GetScrollExtents()
    scroll:SetVerticalScroll((value/MAX_SCROLL_VALUE) * verticalExtents)
    self:UpdateScrollBar()
end

function ZO_ScrollContainer_Shared:OnUpdate()
    if IsInGamepadPreferredMode() then
        local scrollInput = ZO_SCROLL_SHARED_INPUT:GetY()
        if scrollInput ~= 0 then
            ZO_ScrollRelative(self, -scrollInput * 10)
            if self.onInteractWithScrollbarCallback then
                self.onInteractWithScrollbarCallback()
            end
        end
    else
        local inScrollArea = MouseIsOver(self)
        if inScrollArea ~= self.inScrollArea then
            self.inScrollArea = inScrollArea
            if inScrollArea then
                ZO_VerticalScrollbarBase_OnScrollAreaEnter(self.scrollbar)
            else
                ZO_VerticalScrollbarBase_OnScrollAreaExit(self.scrollbar)
            end
        end
    end
end

function ZO_ScrollContainer_Shared:OnGamepadPreferredModeChanged(isGamepadPreferred)
    if isGamepadPreferred then
        self.scrollbar:SetHidden(true)
        self:UpdateScrollIndicator()
    else
        self.scrollIndicator:SetHidden(true)
        self.scrollKeyUp:SetHidden(true)
        self.scrollKeyDown:SetHidden(true)
        self:UpdateScrollBar()
    end
end

function ZO_ScrollContainer_Shared:ScrollControlIntoView(control)
    local scroll = self.scroll
    local scrollTop = scroll:GetTop()
    local scrollBottom = scroll:GetBottom()
    local controlTop = control:GetTop()
    local controlBottom = control:GetBottom()

    if controlTop < scrollTop then
        ZO_ScrollRelative(self, controlTop - scrollTop)
    elseif controlBottom > scrollBottom then
        ZO_ScrollRelative(self, controlBottom - scrollBottom)
    end
end

function ZO_ScrollContainer_Shared:ScrollControlIntoCentralView(control)
    local scroll = self.scroll
    local scrollTop = scroll:GetTop()
    local scrollBottom = scroll:GetBottom()
    local controlTop = control:GetTop()
    local controlBottom = control:GetBottom()

    local halfControlHeight = (controlBottom - controlTop) * 0.5
    local halfScrollHeight = (scrollBottom - scrollTop) * 0.5
    local scrollDistance = controlTop + halfControlHeight - scrollTop - halfScrollHeight

    ZO_ScrollRelative(self, scrollDistance)
end

function ZO_ScrollContainer_Shared.SetScrollIndicatorAnchor(scrollContainer, anchorRelativeToControl, anchorRelativePoint, offsetX, offsetY)
    offsetX = offsetX or 0
    offsetY = offsetY or 0
    scrollContainer.scrollIndicator:SetAnchor(CENTER, anchorRelativeToControl, anchorRelativePoint, offsetX, offsetY)
end

-- Functions for XML

function ZO_ScrollContainer_Shared.InitializeFromControl(control)
    zo_mixin(control, ZO_ScrollContainer_Shared)

    control:Initialize()
end
