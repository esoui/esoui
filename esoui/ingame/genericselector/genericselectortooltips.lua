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
        local rewardTextColor = IsGenericSelectorRewardActiveAtIndex(index) and ZO_NORMAL_TEXT or ZO_DISABLED_TEXT
        descriptionSection:AddLine(rewardTextColor:Colorize(rewardText), self:GetStyle("bodyDescription"))
    end

    self:AddSection(descriptionSection)
end