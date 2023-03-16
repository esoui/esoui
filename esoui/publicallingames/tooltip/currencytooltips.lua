function ZO_Tooltip:LayoutCurrency(currencyType, amount)
    if currencyType ~= CURT_NONE then
        --things added to the topSection stack upwards
        local topSection = self:AcquireSection(self:GetStyle("topSection"))
        local location = GetCurrencyPlayerStoredLocation(currencyType)
        local heldAmount = GetCurrencyAmount(currencyType, location)
        local topSubsection = topSection:AcquireSection(self:GetStyle("topSubsectionItemDetails"))
        local currencyOptions =
        {
            showCap = true,
            currencyLocation = location,
        }
        local heldCurrencyString = ZO_Currency_FormatGamepad(currencyType, heldAmount, ZO_CURRENCY_FORMAT_AMOUNT_ICON, currencyOptions)
        local heldCurrencyNarrationString = ZO_Currency_FormatGamepad(currencyType, heldAmount, ZO_CURRENCY_FORMAT_AMOUNT_NAME, currencyOptions)
        topSubsection:AddLineWithCustomNarration(zo_strformat(SI_GAMEPAD_CURRENCY_INDICATOR, heldCurrencyString), zo_strformat(SI_GAMEPAD_CURRENCY_INDICATOR, heldCurrencyNarrationString))
        topSection:AddSection(topSubsection)

        self:AddSection(topSection)

        -- Name
        local IS_UPPER = false
        local displayName
        if amount and amount > 1 then
            local IS_PLURAL = false
            local currencyName = GetCurrencyName(currencyType, IS_PLURAL, IS_UPPER)
            displayName = zo_strformat(SI_TOOLTIP_ITEM_NAME_WITH_QUANTITY, currencyName, amount)
        else
            local IS_SINGULAR = true
            local currencyName = GetCurrencyName(currencyType, IS_SINGULAR, IS_UPPER)
            displayName = zo_strformat(SI_TOOLTIP_ITEM_NAME, currencyName)
        end
        self:AddLine(displayName, self:GetStyle("title"))

        -- Description
        local bodySection = self:AcquireSection(self:GetStyle("collectionsInfoSection"))
        local description = GetCurrencyDescription(currencyType)
        bodySection:AddLine(description, self:GetStyle("bodyDescription"))
        self:AddSection(bodySection)
    end
end
