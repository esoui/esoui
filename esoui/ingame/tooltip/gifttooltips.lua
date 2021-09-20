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

function ZO_Tooltip:LayoutPartialClaimGiftData(data)
    local senderName = data:GetUserFacingPlayerName()
    local giftName = data:GetName()
    local giftIcon = data:GetIcon()
    local giftQuantity = data:GetQuantity()
    local claimQuantity = data:GetClaimQuantity()
    local returnQuantity = giftQuantity - claimQuantity
    self:LayoutPartialClaimGift(senderName, giftName, giftIcon, giftQuantity, claimQuantity, returnQuantity)
end

function ZO_Tooltip:LayoutPartialClaimGift(senderName, giftName, giftIcon, giftQuantity, claimQuantity, returnQuantity)
    local topSection = self:AcquireSection(self:GetStyle("bodySection"))
    topSection:AddLine(GetString(SI_CONFIRM_PARTIAL_GIFT_CLAIM_EXPLANATION_TEXT), self:GetStyle("bodyDescription"))
    self:AddSection(topSection)

    local giftSection = self:AcquireSection(self:GetStyle("giftSection"))
    local giftNameAndQuantity = zo_strformat(SI_MARKET_PRODUCT_NAME_AND_QUANTITY_FORMATTER, giftName, claimQuantity)
    giftSection:AddLine(giftNameAndQuantity, self:GetStyle("giftName"))
    self:AddSection(giftSection)

    local returnSection = self:AcquireSection(self:GetStyle("bodySection"))
    local returnString = zo_strformat(SI_CONFIRM_PARTIAL_GIFT_RETURN_EXPLANATION_TEXT, giftName, returnQuantity, senderName)
    returnSection:AddLine(returnString, self:GetStyle("bodyDescription"))
    self:AddSection(returnSection)
end