function ZO_GamepadQuadrants_SetBackgroundArrowCenterOffsetY(background, arrowSide, offset)
    local anchorSide
    local arrow
    if arrowSide == LEFT then
        anchorSide = RIGHT
        arrow = background:GetNamedChild("LeftDividerArrow")
    else
        anchorSide = LEFT
        arrow = background:GetNamedChild("RightDividerArrow")
    end
    if arrow then
        arrow:SetAnchor(anchorSide, nil, anchorSide, 0, offset)
    end
end

function ZO_GamepadQuadrants_BackgroundTemplate_Initialize(self)
    local control = self

    local nestedBg = control:GetNamedChild("NestedBg")
    if(nestedBg) then
        control = nestedBg
    end

    self.background = control:GetNamedChild("Bg")

    self.focusTexture = "EsoUI/Art/Windows/Gamepad/panelBG_focus_512.dds"
    self.unfocusTexture = "EsoUI/Art/Windows/Gamepad/panelBG_noFocus_512.dds"
    self.highlight = control:GetNamedChild("Highlight")

    self.rightDivider = control:GetNamedChild("RightDivider")
    if(self.rightDivider) then
        self.rightDividerFadeInAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_GamepadQuadrantFadeAlphaIn", self.rightDivider)
        self.rightDividerFadeOutAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_GamepadQuadrantFadeAlphaOut", self.rightDivider)
    end
end

local BACKGROUND_SCROLL_RATE = 0.0005
local BACKGROUND_SCROLL_RATE_VARIANCE = 0.0001

function ZO_GamepadGrid_BackgroundTextureBase_OnUpdate(self, timeS)
    local left, right, top, bottom = self:GetTextureCoords()
    local rate = BACKGROUND_SCROLL_RATE + BACKGROUND_SCROLL_RATE_VARIANCE * math.sin(timeS)
    top = math.fmod(top + rate, ZO_GAMEPAD_PANEL_BG_BOTTOM_COORD)
    bottom = top + ZO_GAMEPAD_PANEL_BG_BOTTOM_COORD
    self:SetTextureCoords(left, right, top, bottom)
end

--Only attach this screen to the quadrant 1 background when it is shown. Otherwise it is moving back and forth everytime any quadrant 1 UI is shown causing a bunch of unnecessary anchor update.
function ZO_AnchoredToQuadrant1Background_OnEffectivelyShown(self)
    self:ClearAnchors()
    self:SetAnchor(TOPLEFT, ZO_SharedGamepadNavQuadrant_1_Background, TOPLEFT, 0, 0)
    self:SetAnchor(BOTTOMRIGHT, ZO_SharedGamepadNavQuadrant_1_Background, BOTTOMRIGHT, 0, 0)
end

--When hidden anchor it to a non-moving variant of the quadrant background: this way existing layout code that assumes this is well anchored will see what it wants to see.
function ZO_AnchoredToQuadrant1Background_OnEffectivelyHidden(self)
    self:ClearAnchors()
    self:SetAnchor(TOPLEFT, ZO_SharedGamepadNavQuadrant_1_StaticBackground, TOPLEFT, 0, 0)
    self:SetAnchor(BOTTOMRIGHT, ZO_SharedGamepadNavQuadrant_1_StaticBackground, BOTTOMRIGHT, 0, 0)
end 