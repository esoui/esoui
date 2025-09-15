--------------------------------------
-- Vengeance Perk Framed Icon Keyboard
--------------------------------------

ZO_VengeancePerk_Icon_Keyboard = ZO_VengeancePerk_Icon:Subclass()

function ZO_VengeancePerk_Icon_Keyboard:Initialize(control)
    ZO_VengeancePerk_Icon.Initialize(self, control)

    -- Default Tooltip Locations
    self.tooltipAnchors =
    {
        point = LEFT,
        offsetX = 10,
        offsetY = 0,
        relativePoint = RIGHT,
    }
end

function ZO_VengeancePerk_Icon_Keyboard:SetTooltipAnchors(point, offsetX, offsetY, relativePoint)
    self.tooltipAnchors.point = point
    self.tooltipAnchors.offsetX = offsetX
    self.tooltipAnchors.offsetY = offsetY
    self.tooltipAnchors.relativePoint = relativePoint
end

function ZO_VengeancePerk_Icon_Keyboard:ShowTooltip()
    if self.perkData then
        ClearTooltip(SkillTooltip)
        InitializeTooltip(SkillTooltip, self.control, self.tooltipAnchors.point, self.tooltipAnchors.offsetX, self.tooltipAnchors.offsetY, self.tooltipAnchors.relativePoint)
        SkillTooltip:SetVengeancePerk(self.perkData:GetPerkIndex())
    end
end

-----------------------------
-- Global XML Functions
-----------------------------

function ZO_VengeancePerk_Icon_Keyboard.OnControlInitialized(control)
    ZO_VengeancePerk_Icon_Keyboard:New(control)
end

function ZO_VengeancePerk_Icon_Keyboard.VengeancePerk_OnMouseEnter(control)
    control.object:ShowTooltip()
end

function ZO_VengeancePerk_Icon_Keyboard.VengeancePerk_OnMouseExit(control)
    ClearTooltip(SkillTooltip)
end