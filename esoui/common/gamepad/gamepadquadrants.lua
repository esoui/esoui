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