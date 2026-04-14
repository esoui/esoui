-----------------------
-- Veterancy Rank --
-----------------------

ZO_VeterancyRank = ZO_InitializingObject:Subclass()

function ZO_VeterancyRank:Initialize(control)
    self.control = control

    self.iconTexture = control:GetNamedChild("Icon")
    self.valueLabel = control:GetNamedChild("Rank")
    self.nameLabel = control:GetNamedChild("Name")
    self.statusBar = control:GetNamedChild("XPBar")
    ZO_StatusBar_SetGradientColor(self.statusBar, ZO_SKILL_XP_BAR_GRADIENT_COLORS)

    local function OnMouseEnter(...)
        InitializeTooltip(InformationTooltip, self.statusBar, TOP)

        if ZO_VETERANCY_MANAGER:IsOnMaxRank() then
            InformationTooltip:AddLine(zo_strformat(SI_VETERANCY_ACTIVE_MAX_RANK_TOOLTIP, ZO_VETERANCY_MANAGER:GetCurrentRank())
                , "ZoFontGameMedium", r, g, b, TOPLEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, FULL_WIDTH)
        else
            InformationTooltip:AddLine(zo_strformat(SI_VETERANCY_ACTIVE_TOOLTIP
                , ZO_VETERANCY_MANAGER:GetCurrentRank()
                , ZO_VETERANCY_MANAGER:GetCurrentRankName()
                , ZO_CommaDelimitNumber(ZO_VETERANCY_MANAGER:GetCurrentTierProgress())
                , ZO_CommaDelimitNumber(ZO_VETERANCY_MANAGER:GetCurrentTierTotal()))
                , "ZoFontGameMedium", r, g, b, TOPLEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, FULL_WIDTH)
        end
    end

    local function OnMouseExit(...)
        ClearTooltip(InformationTooltip)
    end

    self.statusBar:SetHandler("OnMouseEnter", OnMouseEnter)
    self.statusBar:SetHandler("OnMouseExit", OnMouseExit)

    self:Refresh()
end

function ZO_VeterancyRank:Refresh()
    ZO_VETERANCY_MANAGER:RefreshRankData()
    local veterancyRankData = ZO_VETERANCY_MANAGER:GetCurrentRankData()

    if veterancyRankData then
        if veterancyRankData == ZO_VETERANCY_MANAGER:GetRepeatableRankData() then
            local maxRankData = ZO_VETERANCY_MANAGER:GetRankDataByIndex(ZO_VETERANCY_MANAGER:GetNumRanks())
            if maxRankData then
                veterancyRankData = maxRankData
            end
        end

        self.valueLabel:SetText(veterancyRankData:GetIndex())
        self.nameLabel:SetText(veterancyRankData:GetName())
        self.iconTexture:SetTexture(veterancyRankData:GetIcon())
        self.statusBar:SetValue(veterancyRankData:GetProgressPercent())
    end
end