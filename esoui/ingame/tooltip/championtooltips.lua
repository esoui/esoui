function ZO_Tooltip:LayoutChampionConstellation(attributeName, attributeIcon, constellationName, constellationDescription, numPointsAvailable, numSpentPoints)
    local attributeTitleSection = self:AcquireSection(self:GetStyle("attributeTitleSection"))
    attributeTitleSection:AddLine(attributeName, self:GetStyle("attributeTitle"))
    attributeTitleSection:AddTexture(attributeIcon, self:GetStyle("attributeIcon"))
    attributeTitleSection:AddTexture(ZO_GAMEPAD_HEADER_DIVIDER_TEXTURE, self:GetStyle("dividerLine"))
    self:AddSection(attributeTitleSection)

    local availablePointsSection = self:AcquireSection(self:GetStyle("championPointsSection"))
    availablePointsSection:AddLine(GetString(SI_GAMEPAD_CHAMPION_AVAILABLE_POINTS_LABEL), self:GetStyle("pointsHeader"))
    availablePointsSection:AddLine(numPointsAvailable, self:GetStyle("pointsValue"))
    self:AddSection(availablePointsSection)

    local constellationTitleSection = self:AcquireSection(self:GetStyle("championTitleSection"), self:GetStyle("title"))
    constellationTitleSection:AddLine(constellationName, self:GetStyle("championTitle"))
    constellationTitleSection:AddTexture(ZO_GAMEPAD_HEADER_DIVIDER_TEXTURE, self:GetStyle("dividerLine"))
    self:AddSection(constellationTitleSection)

    local spentPointsSection = self:AcquireSection(self:GetStyle("championPointsSection"))
    spentPointsSection:AddLine(GetString(SI_GAMEPAD_CHAMPION_ALLOCATED_POINTS_LABEL), self:GetStyle("pointsHeader"))
    spentPointsSection:AddLine(numSpentPoints, self:GetStyle("pointsValue"))
    self:AddSection(spentPointsSection)

    local bodySection = self:AcquireSection(self:GetStyle("championBodySection"), self:GetStyle("bodySection"))
    bodySection:AddLine(constellationDescription, self:GetStyle("bodyDescription"))
    self:AddSection(bodySection)
end