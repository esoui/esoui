function ZO_SetupInventoryItemOptionsCurrencyColor()
    if FENCE_MANAGER and SYSTEMS:GetObject("fence"):IsSellingStolenItems() and FENCE_MANAGER:HasBonusToSellingStolenItems() then
        return ZO_CURRENCY_HIGHLIGHT_TEXT
    end
end


ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT =
{
    showTooltips = false,
    font = "ZoFontGamepadHeaderDataValue",
    iconSide = RIGHT,
    isGamepad = true,
}

ZO_GAMEPAD_CURRENCY_OPTIONS = ZO_ShallowTableCopy(ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
ZO_GAMEPAD_CURRENCY_OPTIONS.useShortFormat = true

ZO_GAMEPAD_FENCE_CURRENCY_OPTIONS = ZO_ShallowTableCopy(ZO_GAMEPAD_CURRENCY_OPTIONS)
ZO_GAMEPAD_FENCE_CURRENCY_OPTIONS.color = ZO_SetupInventoryItemOptionsCurrencyColor