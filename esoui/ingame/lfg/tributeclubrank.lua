-----------------------
-- Tribute Club Rank --
-----------------------

ZO_TributeClubRank = ZO_InitializingObject:Subclass()

function ZO_TributeClubRank:Initialize(control)
    self.control = control

    self.iconTexture = control:GetNamedChild("Icon")
    self.valueLabel = control:GetNamedChild("Rank")
    self.nameLabel = control:GetNamedChild("Name")
    self.statusBar = control:GetNamedChild("XPBar")
    ZO_StatusBar_SetGradientColor(self.statusBar, ZO_SKILL_XP_BAR_GRADIENT_COLORS)

    self:Refresh()
end

function ZO_TributeClubRank:GetTributeClubRank()
    return GetTributePlayerClubRank()
end

function ZO_TributeClubRank:Refresh()
    local clubRank = self:GetTributeClubRank()

    -- Display one higher than the clubRank used so we don't display 0 as the minimum
    self.valueLabel:SetText(clubRank + 1)
    self.nameLabel:SetText(zo_strformat(GetString("SI_TRIBUTECLUBRANK", clubRank)))
    self.iconTexture:SetTexture(string.format("EsoUI/Art/Tribute/tributeClubRank_%d.dds", clubRank))

    local currentClubExperienceForRank, maxClubExperienceForRank = GetTributePlayerExperienceInCurrentClubRank()
    self.statusBar:SetMinMax(0, maxClubExperienceForRank)
    self.statusBar:SetValue(currentClubExperienceForRank)
end