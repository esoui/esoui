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

function ZO_Tooltip:LayoutHouseTemplateTooltip(houseId, houseTemplateId)
    local houseZoneId = GetHouseFoundInZoneId(houseId)
    local houseZoneName = GetZoneNameById(houseZoneId)
    local houseCategory = GetHouseCategoryType(houseId)
    local houseCategoryName = GetString("SI_HOUSECATEGORYTYPE", houseCategory)
    local houseFlags = GetHouseFlags(houseId)
    local hasWeatherControlSupport = ZO_FlagHelpers.MaskHasFlag(houseFlags, HOUSE_FLAGS_SUPPORTS_WEATHER_CONTROL)
    local hasWeatherControlSupportString = hasWeatherControlSupport and GetString(SI_YES) or GetString(SI_NO)

    local statsSection = self:AcquireSection(self:GetStyle("houseTemplateMainSection"))

    local zoneValuePair = statsSection:AcquireStatValuePair(self:GetStyle("houseTemplateStatValuePair"))
    zoneValuePair:SetStat(GetString(SI_MARKET_PRODUCT_HOUSING_LOCATION_LABEL), self:GetStyle("houseTemplateStatValuePairStat"))
    zoneValuePair:SetValue(zo_strformat(SI_ZONE_NAME, houseZoneName), self:GetStyle("houseTemplateStatValuePairValue"))
    statsSection:AddStatValuePair(zoneValuePair)

    local categoryValuePair = statsSection:AcquireStatValuePair(self:GetStyle("houseTemplateStatValuePair"))
    categoryValuePair:SetStat(GetString(SI_MARKET_PRODUCT_HOUSING_HOUSE_TYPE_LABEL), self:GetStyle("houseTemplateStatValuePairStat"))
    categoryValuePair:SetValue(zo_strformat(SI_HOUSE_TYPE_FORMATTER, houseCategoryName), self:GetStyle("houseTemplateStatValuePairValue"))
    statsSection:AddStatValuePair(categoryValuePair)

    local categoryValuePair = statsSection:AcquireStatValuePair(self:GetStyle("houseTemplateStatValuePair"))
    categoryValuePair:SetStat(GetString(SI_MARKET_PRODUCT_HOUSING_HOUSE_SUPPORTS_WEATHER_CONTROL_LABEL), self:GetStyle("houseTemplateStatValuePairStat"))
    categoryValuePair:SetValue(zo_strformat(SI_HOUSE_SUPPORTS_WEATHER_CONTROL_FORMATTER, hasWeatherControlSupportString), self:GetStyle("houseTemplateStatValuePairValue"))
    statsSection:AddStatValuePair(categoryValuePair)

    self:AddSection(statsSection)

    local houseInfoSection = self:AcquireSection(self:GetStyle("houseTemplateMainSection"))
    for furnishingLimitType = HOUSING_FURNISHING_LIMIT_TYPE_ITERATION_BEGIN, HOUSING_FURNISHING_LIMIT_TYPE_ITERATION_END do
        local initialFurnishingCount, furnishingLimit = GetHouseTemplateBaseFurnishingCountInfo(houseTemplateId, furnishingLimitType)
        local limitValuePair = statsSection:AcquireStatValuePair(self:GetStyle("houseTemplateStatValuePair"))
        limitValuePair:SetStat(GetString("SI_HOUSINGFURNISHINGLIMITTYPE", furnishingLimitType), self:GetStyle("houseTemplateStatValuePairStat"))
        limitValuePair:SetValue(zo_strformat(SI_HOUSE_INFORMATION_COUNT_FORMAT, initialFurnishingCount, furnishingLimit), self:GetStyle("houseTemplateStatValuePairValue"))
        houseInfoSection:AddStatValuePair(limitValuePair)
    end
    self:AddSection(houseInfoSection)

    local esoPlusInfoSection = self:AcquireSection(self:GetStyle("bodySection"))
    esoPlusInfoSection:AddLine(GetString(SI_MARKET_HOUSE_INFO_ESO_PLUS_TEXT), self:GetStyle("furnishingInfoNote"))
    self:AddSection(esoPlusInfoSection)
end