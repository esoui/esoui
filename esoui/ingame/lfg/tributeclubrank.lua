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

    local function OnMouseEnter(...)
        InitializeTooltip(InformationTooltip, self.statusBar, TOP)

        local currentClubExperienceForRank, maxClubExperienceForRank = GetTributePlayerExperienceInCurrentClubRank()

        --If the maximum club experience for this rank is 0, then we are maxed out
        if maxClubExperienceForRank == 0 then
            InformationTooltip:AddLine(GetString(SI_TRIBUTE_CLUB_EXPERIENCE_LIMIT_REACHED), "", ZO_NORMAL_TEXT:UnpackRGBA())
        else
            local percentageXp = zo_floor(currentClubExperienceForRank / maxClubExperienceForRank * 100)
            local formattedRatioText = zo_strformat(SI_TRIBUTE_EXPERIENCE_CURRENT_MAX_PERCENT, ZO_CommaDelimitNumber(currentClubExperienceForRank), ZO_CommaDelimitNumber(maxClubExperienceForRank), percentageXp)
            InformationTooltip:AddLine(zo_strformat(SI_TRIBUTE_CLUB_EXPERIENCE_TOOLTIP_FORMATTER, formattedRatioText), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGBA())
        end

        InformationTooltip:AddVerticalPadding(18)

        InformationTooltip:AddLine(GetString(SI_TRIBUTE_CLUB_EXPERIENCE_DESCRIPTION), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGBA())
    end

    local function OnMouseExit(...)
        ClearTooltip(InformationTooltip)
    end

    self.statusBar:SetHandler("OnMouseEnter", OnMouseEnter)
    self.statusBar:SetHandler("OnMouseExit", OnMouseExit)

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