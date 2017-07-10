ZO_KEYBOARD_CURRENCY_OPTIONS =
{
    showTooltips = true,
    font = "ZoFontGameLargeBold",
    iconSide = RIGHT,
}

local DONT_SET_TO_FULL_SIZE = false
local DONT_USE_SHORT_FORMAT = false
local TOOLTIP_LINE_WIDTH = 150
local INVENTORY_ICON = zo_iconFormat("EsoUI/Art/Tooltips/icon_bag.dds", 20, 20)
local BANK_ICON = zo_iconFormat("EsoUI/Art/Tooltips/icon_bank.dds", 20, 20)
local NO_BAG_ICON = nil

ZO_KEYBOARD_CURRENCY_STANDARD_TOOLTIP_OPTIONS = ZO_ShallowTableCopy(ZO_KEYBOARD_CURRENCY_OPTIONS)
ZO_KEYBOARD_CURRENCY_STANDARD_TOOLTIP_OPTIONS.tooltipFunction = function(tooltip)
    local r, g, b = ZO_WHITE:UnpackRGB()

    for _, currencyType in ipairs(ZO_CURRENCY_DISPLAY_ORDER) do
        local carriedText = ZO_CurrencyControl_FormatCurrencyAndAppendIcon(GetCarriedCurrencyAmount(currencyType), DONT_USE_SHORT_FORMAT, currencyType)
        InformationTooltip:AddLine(carriedText, "", r, g, b, RIGHT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_RIGHT, DONT_SET_TO_FULL_SIZE, TOOLTIP_LINE_WIDTH)
    end
end

do
    local function LayoutBankTooltip(bankableCurrencies, bankCurrencyAmountLookupFunction, obfuscateFunction)
        local r, g, b = ZO_WHITE:UnpackRGB()

        for _, currencyType in ipairs(ZO_CURRENCY_DISPLAY_ORDER) do
            local carriedAmmount = ZO_CurrencyControl_FormatCurrency(GetCarriedCurrencyAmount(currencyType))
            local currencyIconMarkup = ZO_Currency_GetKeyboardFormattedCurrencyIcon(currencyType)
            local carriedText = zo_strformat(SI_GENERIC_CURRENCY_TOOLTIP_FORMAT, carriedAmmount, currencyIconMarkup, INVENTORY_ICON)
            InformationTooltip:AddLine(carriedText, "", r, g, b, RIGHT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_RIGHT, DONT_SET_TO_FULL_SIZE, TOOLTIP_LINE_WIDTH)

            if bankableCurrencies[currencyType] then
                local obfuscateAmount = obfuscateFunction and obfuscateFunction(currencyType)
                local bankedAmmount = ZO_CurrencyControl_FormatCurrency(bankCurrencyAmountLookupFunction(currencyType), DONT_USE_SHORT_FORMAT, obfuscateAmount)
                local bankedText = zo_strformat(SI_GENERIC_CURRENCY_TOOLTIP_FORMAT, bankedAmmount, currencyIconMarkup, BANK_ICON)
                InformationTooltip:SetVerticalPadding(0)
                InformationTooltip:AddLine(bankedText, "", r, g, b, RIGHT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_RIGHT, DONT_SET_TO_FULL_SIZE, TOOLTIP_LINE_WIDTH)
            end
        end
    end

    ZO_KEYBOARD_CURRENCY_BANK_TOOLTIP_OPTIONS = ZO_ShallowTableCopy(ZO_KEYBOARD_CURRENCY_OPTIONS)
    ZO_KEYBOARD_CURRENCY_BANK_TOOLTIP_OPTIONS.tooltipFunction = function(tooltip)
        LayoutBankTooltip(ZO_BANKABLE_CURRENCIES, GetBankedCurrencyAmount)
    end

    ZO_KEYBOARD_CURRENCY_GUILD_BANK_TOOLTIP_OPTIONS = ZO_ShallowTableCopy(ZO_KEYBOARD_CURRENCY_OPTIONS)
    ZO_KEYBOARD_CURRENCY_GUILD_BANK_TOOLTIP_OPTIONS.tooltipFunction = function(tooltip)
        local function ObfuscateFunction(currencyType)
            return currencyType == CURT_MONEY and not DoesPlayerHaveGuildPermission(GetSelectedGuildBankId(), GUILD_PERMISSION_BANK_VIEW_GOLD)
        end

        LayoutBankTooltip(ZO_GUILD_BANKABLE_CURRENCIES, GetGuildBankedCurrencyAmount, ObfuscateFunction)
    end
end