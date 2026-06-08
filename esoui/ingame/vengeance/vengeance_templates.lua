ZO_VENGEANCE_PERK_TILE_ICON_DIMENSIONS = 52
ZO_VENGEANCE_PERK_TILE_ICON_BORDER_DIMENSIONS = 104

-----------------------------
-- Vengeance Perk Framed Icon
-----------------------------

ZO_VengeancePerk_Icon = ZO_InitializingObject:Subclass()

function ZO_VengeancePerk_Icon:Initialize(control)
    self.control = control
    control.object = self

    self.icon = control:GetNamedChild("Icon")
    self.border = control:GetNamedChild("Border")
    self.background = control:GetNamedChild("Background")
end

-- Setting this will set the border to the specified slot, otherwise the perk slot will be used.
function ZO_VengeancePerk_Icon:SetPerkSlot(slot)
    self.slot = slot
end

function ZO_VengeancePerk_Icon:SetPerkData(perkData)
    if perkData then
        self.icon:SetTexture(perkData:GetIcon())
        if self.slot then
            self.border:SetTexture(ZO_VENGEANCE_MANAGER:GetPerkBorderBySlot(self.slot))
            self.background:SetTexture(ZO_VENGEANCE_MANAGER:GetPerkBackgroundBySlot(self.slot))
        else
            self.border:SetTexture(perkData:GetBorderTexture())
            self.background:SetTexture(perkData:GetBackgroundTexture())
        end
    elseif self.slot then
        self.icon:SetTexture(ZO_VENGEANCE_MANAGER:GetEmptyPerkIconBySlot(self.slot))
        self.border:SetTexture(ZO_VENGEANCE_MANAGER:GetPerkBorderBySlot(self.slot))
        self.background:SetTexture(ZO_VENGEANCE_MANAGER:GetPerkBackgroundBySlot(self.slot))
    else
        -- Default to red if no slot
        self.icon:SetTexture(ZO_VENGEANCE_MANAGER:GetEmptyPerkIconBySlot(VENGEANCE_PERK_SLOT_RED))
        self.border:SetTexture(ZO_VENGEANCE_MANAGER:GetPerkBorderBySlot(VENGEANCE_PERK_SLOT_RED))
        self.background:SetTexture(ZO_VENGEANCE_MANAGER:GetPerkBackgroundBySlot(VENGEANCE_PERK_SLOT_RED))
    end
    self.perkData = perkData
end

function ZO_VengeancePerk_Icon:SetPerkDisabled(isDisabled)
    local desaturation = isDisabled and 1 or 0
    self.icon:SetDesaturation(desaturation)
    self.border:SetDesaturation(desaturation)
end

-----------------------------
-- Global XML Functions
-----------------------------

function ZO_VengeancePerk_Icon.OnControlInitialized(control)
    ZO_VengeancePerk_Icon:New(control)
end