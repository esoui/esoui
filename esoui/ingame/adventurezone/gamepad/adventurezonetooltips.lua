function ZO_Tooltip:LayoutAdventureZoneBossTooltip(boss)
    local statusSection = self:AcquireSection(self:GetStyle("bodyHeader"))
    local bossState = GetAdventureZoneBossState(boss)
    local statusText = ZO_NORMAL_TEXT:Colorize(GetString("SI_ADVENTUREZONEBOSSSTATE", bossState))
    statusSection:AddLine(statusText)
    self:AddSection(statusSection)

    local nameTextSection = self:AcquireSection(self:GetStyle("title"))
    nameTextSection:AddLine(zo_strformat(SI_TOOLTIP_UNIT_NAME, GetAdventureZoneBossName(boss)))
    self:AddSection(nameTextSection)

    local descriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
    descriptionSection:AddLine(GetAdventureZoneBossDescription(boss), self:GetStyle("bodyDescription"))
    self:AddSection(descriptionSection)
end