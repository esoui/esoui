function ZO_Tooltip:LayoutGenericSelectorItemTooltip(itemIndex)
    local topSection = self:AcquireSection(self:GetStyle("topSection"))
    topSection:AddLine(GetString("SI_GENERICSELECTORCHOICECATEGORY", GetGenericSelectorChoiceCategoryAtIndex(itemIndex)))
    self:AddSectionEvenIfEmpty(topSection)

    local nameTextSection = self:AcquireSection(self:GetStyle("title"))
    nameTextSection:AddLine(zo_strformat(SI_ABILITY_TOOLTIP_NAME, GetGenericSelectorChoiceNameAtIndex(itemIndex)))
    self:AddSection(nameTextSection)

    local descriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
    descriptionSection:AddLine(GetGenericSelectorChoiceDescriptionAtIndex(itemIndex), self:GetStyle("bodyDescription"))
    self:AddSection(descriptionSection)
end

function ZO_Tooltip:LayoutGenericSelectorRewardsTooltip()
    local titleTextSection = self:AcquireSection(self:GetStyle("title"))
    titleTextSection:AddLine(GetString(SI_GENERIC_SELECTOR_REWARDS_TITLE))
    self:AddSection(titleTextSection)

    local descriptionSection = self:AcquireSection(self:GetStyle("bodySection"))

    for index = 1, GetNumGenericSelectorRewards() do
        local rewardText = GetGenericSelectorRewardDescriptionAtIndex(index)
        local colorStyle = IsGenericSelectorRewardActiveAtIndex(index) and { fontColorField = INTERFACE_TEXT_COLOR_NORMAL } or { fontColorField = INTERFACE_TEXT_COLOR_DISABLED }
        colorStyle["fontColorType"] = INTERFACE_COLOR_TYPE_TEXT_COLORS
        descriptionSection:AddLine(rewardText, self:GetStyle("bodyDescription"), colorStyle)
    end

    self:AddSection(descriptionSection)
end