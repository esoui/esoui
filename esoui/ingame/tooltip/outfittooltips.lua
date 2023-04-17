function ZO_Tooltip:LayoutClearOutfitSlot(outfitSlot)
    --Title
    local headerSection = self:AcquireSection(self:GetStyle("bodyHeader"))
    headerSection:AddLine(GetString(SI_OUTFIT_CLEAR_OPTION_TITLE), self:GetStyle("title"))
    self:AddSection(headerSection)

    --Body
    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    local bodyDescriptionStyle = self:GetStyle("bodyDescription")
    bodySection:AddLine(GetString(SI_OUTFIT_CLEAR_OPTION_DESCRIPTION), bodyDescriptionStyle)

    --Application cost
    local applyCost = GetOutfitSlotClearCost(outfitSlot)
    local applyCostString = ZO_Currency_FormatGamepad(CURT_MONEY, applyCost, ZO_CURRENCY_FORMAT_AMOUNT_ICON)
    local applyCostNarrationString = ZO_Currency_FormatGamepad(CURT_MONEY, applyCost, ZO_CURRENCY_FORMAT_AMOUNT_NAME)
    local statValuePair = bodySection:AcquireStatValuePair(self:GetStyle("statValuePair"))
    statValuePair:SetStat(GetString(SI_TOOLTIP_COLLECTIBLE_OUTFIT_STYLE_APPLICATION_COST_GAMEPAD), self:GetStyle("statValuePairStat"))
    statValuePair:SetValueWithCustomNarration(applyCostString, applyCostNarrationString, bodyDescriptionStyle, self:GetStyle("currencyStatValuePairValue"))
    bodySection:AddStatValuePair(statValuePair)

    self:AddSection(bodySection)
end
