function ZO_Tooltip:LayoutRedeemCodeTooltip()
    local bodySection = self:AcquireSection(self:GetStyle("redeemCodeBodySection"))
    bodySection:AddLine(GetString(SI_GAMEPAD_CODE_REDEMPTION_TOOLTIP_CODE_DESCRIPTION), self:GetStyle("bodyDescription"))
    self:AddSection(bodySection)

    local statsSection = self:AcquireSection(self:GetStyle("redeemCodeStatsSection"))
    local statValuePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
    statValuePair:SetStat(GetString(SI_GAMEPAD_CODE_REDEMPTION_TOOLTIP_EXAMPLE_CODE_LABEL), self:GetStyle("statValuePairStat"))
    statValuePair:SetValue(GetExampleCodeForCodeRedemption(), self:GetStyle("currencyStatValuePairValue"))
    statsSection:AddStatValuePair(statValuePair)
    self:AddSection(statsSection)

    local detailsSection = self:AcquireSection(self:GetStyle("bodySection"))
    detailsSection:AddLine(GetString(SI_CODE_REDEMPTION_REDEEM_CODE_DIALOG_DETAILS), self:GetStyle("bodyDescription"))
    self:AddSection(detailsSection)
end
