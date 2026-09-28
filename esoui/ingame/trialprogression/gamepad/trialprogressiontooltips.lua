function ZO_Tooltip:LayoutTrialProgressionPassiveTooltip(trackIndex, passiveIndex)
    local cost, title, description = GetInfoForPassiveInTrialProgressionTrackByIndex(trackIndex, passiveIndex)
    local topSection = self:AcquireSection(self:GetStyle("topSection"))
    local pointsIcon = GetTrialProgressionTrackPointsIconByIndex(trackIndex)
    local costText = zo_iconTextFormat(pointsIcon, "100%", "100%", cost)
    topSection:AddLine(costText)
    self:AddSectionEvenIfEmpty(topSection)

    local titleTextSection = self:AcquireSection(self:GetStyle("title"))
    titleTextSection:AddLine(title)
    self:AddSection(titleTextSection)

    local descriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
    descriptionSection:AddLine(description, self:GetStyle("bodyDescription"))
    self:AddSection(descriptionSection)
end