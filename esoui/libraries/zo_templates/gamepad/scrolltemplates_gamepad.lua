function ZO_ScrollAreaBarBehavior_OnEffectivelyShown_Gamepad(self)
    self.inScrollArea = nil
    ZO_VerticalScrollbarBase_OnScrollAreaEnter(GetControl(self, "ScrollBar"))
end

function ZO_ScrollAreaBarBehavior_OnEffectivelyHidden_Gamepad(self)
    ZO_VerticalScrollbarBase_OnScrollAreaExit(GetControl(self, "ScrollBar"))
end

ZO_ScrollSharedInput_Gamepad = ZO_Object:Subclass() --class for sharing directional input between all scrolling controls

function ZO_ScrollSharedInput_Gamepad:New()
    local object = ZO_Object.New(self)
    object:Initialize()
    return object
end

function ZO_ScrollSharedInput_Gamepad:Initialize()
    self.scrollInput = 0
end

function ZO_ScrollSharedInput_Gamepad:Activate(control)
    DIRECTIONAL_INPUT:Activate(self, control)
    self.consumed = false
end

function ZO_ScrollSharedInput_Gamepad:Deactivate()
   DIRECTIONAL_INPUT:Deactivate(self)
end

function ZO_ScrollSharedInput_Gamepad:Consume()
    self.consumed = true
end

function ZO_ScrollSharedInput_Gamepad:UpdateDirectionalInput()
    if DIRECTIONAL_INPUT:IsAvailable(ZO_DI_RIGHT_STICK) then
        self.scrollInput = DIRECTIONAL_INPUT:GetY(ZO_DI_RIGHT_STICK)
        self.consumed = false
    end
end

function ZO_ScrollSharedInput_Gamepad:GetY()
    local scrollInput = self.scrollInput
    if self.consumed then
        self.scrollInput = 0
    end
    return scrollInput
end

ZO_SCROLL_SHARED_INPUT = ZO_ScrollSharedInput_Gamepad:New()

-- Scroll Panel
ZO_ScrollContainer_Gamepad = {} -- A wrapper for ZO_ScrollContainer_Gamepad

function ZO_Scroll_Initialize_Gamepad(control)
    ZO_Scroll_Initialize(control)

    zo_mixin(control, ZO_ScrollContainer_Gamepad)

    control:Initialize()
end

do
    local SLIDER_MIN_VALUE = 0

    function ZO_ScrollContainer_Gamepad:Initialize()
        self:SetHandler("OnEffectivelyShown", function() self:OnEffectivelyShown() end)
        self:SetHandler("OnEffectivelyHidden", function() self:OnEffectivelyHidden() end)
        self.scroll:SetHandler("OnScrollExtentsChanged", function(...) self:OnScrollExtentsChanged(...) end)
        self:SetHandler("OnUpdate", function() self:OnUpdate() end)

        self.scrollIndicator = GetControl(self, "ScrollIndicator")
        self.scrollIndicator:SetTexture(ZO_GAMEPAD_RIGHT_SCROLL_ICON)

        self.scrollInput = 0
        self.animation, self.timeline = ZO_CreateScrollAnimation(self)
        self.scrollValue = SLIDER_MIN_VALUE
        self.directionalInputActivated = false

        ZO_UpdateScrollFade(self.useFadeGradient, self.scroll, ZO_SCROLL_DIRECTION_VERTICAL)
    end

    function ZO_ScrollContainer_Gamepad:ResetToTop()
        self.scrollValue = SLIDER_MIN_VALUE

        ZO_ScrollAnimation_MoveWindow(self, self.scrollValue)
        ZO_UpdateScrollFade(self.useFadeGradient, self.scroll, ZO_SCROLL_DIRECTION_VERTICAL, ZO_GetScrollMaxFadeGradientSize(self))
    end
end

function ZO_ScrollContainer_Gamepad:DisableUpdateHandler()
    self:SetHandler("OnUpdate", nil)
end

function ZO_ScrollContainer_Gamepad:RefreshDirectionalInputActivation()
    local _, verticalExtents = self.scroll:GetScrollExtents()
    local canScroll = verticalExtents > 0
    if not self:IsHidden() and canScroll then
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

function ZO_ScrollContainer_Gamepad:OnEffectivelyShown()
    self:ResetToTop()
    self:RefreshDirectionalInputActivation()
end

function ZO_ScrollContainer_Gamepad:OnEffectivelyHidden()
    self:RefreshDirectionalInputActivation()
end

function ZO_ScrollContainer_Gamepad:OnScrollExtentsChanged(control, horizontalExtents, verticalExtents)
    self:RefreshDirectionalInputActivation()
    --Gamepad Mode is a safety check for shared controls between Gamepad/Keyboard that 
    --use Gamepad Scroll containers such as Death Recap.
    self.scrollIndicator:SetHidden(not (IsInGamepadPreferredMode() and verticalExtents ~= 0))
    ZO_UpdateScrollFade(self.useFadeGradient, self.scroll, ZO_SCROLL_DIRECTION_VERTICAL)
end

do
    local INPUT_VERTICAL_DELTA_MULTIPLIER = 10

    function ZO_ScrollContainer_Gamepad:OnUpdate()
        local scrollInput = ZO_SCROLL_SHARED_INPUT:GetY()
        if scrollInput ~= 0 then
            ZO_ScrollRelative(self, -scrollInput * INPUT_VERTICAL_DELTA_MULTIPLIER)
        end
    end
end

function ZO_Scroll_Gamepad_SetScrollIndicatorSide(scrollIndicator, background, anchorSide, customOffsetX, customOffsetY, anchorsToBackground)
    scrollIndicator:ClearAnchors()

    local anchorRelativePos = anchorsToBackground and RIGHT or TOPRIGHT
    local offsetY = customOffsetY or 0
    local offsetX = customOffsetX or -ZO_GAMEPAD_PANEL_BG_VERTICAL_DIVIDER_HALF_WIDTH
    if anchorSide == LEFT then
        anchorRelativePos = anchorsToBackground and LEFT or TOPLEFT
        offsetX = customOffsetX or ZO_GAMEPAD_PANEL_BG_VERTICAL_DIVIDER_HALF_WIDTH
    end

    -- Tooltip templates and generic dialogs use "Bg" as child background name while shared quadrant templates use "NestedBg"
    local bgControl = background:GetNamedChild("NestedBg")
    if not bgControl then
        bgControl = background:GetNamedChild("Bg")
    end

    if bgControl then
        local anchorControl = anchorsToBackground and bgControl or bgControl:GetNamedChild("BackgroundAtScreenCenterHeight")
        scrollIndicator:SetAnchor(CENTER, anchorControl, anchorRelativePos, offsetX, offsetY)
    end
end