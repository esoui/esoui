function ZO_Tooltip:LayoutReturnedGift(giftName, sender, note)
    self:AddLine(GetString(SI_GAMEPAD_GIFT_INVENTORY_RETURNED_GIFT_TOOLTIP_HEADER), self:GetStyle("title"))

    local formattedGiftName = zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, giftName)
    self:AddLine(formattedGiftName, self:GetStyle("giftNameHeader"))

    local statValuePair = self:AcquireStatValuePair(self:GetStyle("statValuePair"))
    statValuePair:SetStat(GetString(SI_GAMEPAD_GIFT_INVENTORY_GIFT_TOOLTIP_FROM_LABEL), self:GetStyle("statValuePairStat"))
    statValuePair:SetValue(sender, self:GetStyle("statValuePairValue"))
    self:AddStatValuePair(statValuePair)

    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    bodySection:AddLine(note, self:GetStyle("bodyDescription"))
    self:AddSection(bodySection)
end