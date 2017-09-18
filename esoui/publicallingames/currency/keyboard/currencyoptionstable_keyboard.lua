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

do
    local function LayoutBankTooltip(currencyBankLocation, obfuscateFunction)
        local r, g, b = ZO_WHITE:UnpackRGB()

        for currencyType = CURT_ITERATION_BEGIN, CURT_ITERATION_END do
            if CanCurrencyBeStoredInLocation(currencyType, currencyBankLocation) then
                local carriedAmmount = ZO_CurrencyControl_FormatCurrency(GetCurrencyAmount(currencyType, CURRENCY_LOCATION_CHARACTER))
                local currencyIconMarkup = ZO_Currency_GetKeyboardFormattedCurrencyIcon(currencyType)
                local carriedText = zo_strformat(SI_GENERIC_CURRENCY_TOOLTIP_FORMAT, carriedAmmount, currencyIconMarkup, INVENTORY_ICON)
                InformationTooltip:AddLine(carriedText, "", r, g, b, RIGHT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_RIGHT, DONT_SET_TO_FULL_SIZE, TOOLTIP_LINE_WIDTH)

                local obfuscateAmount = obfuscateFunction and obfuscateFunction(currencyType)
                local bankedAmmount = ZO_CurrencyControl_FormatCurrency(GetCurrencyAmount(currencyType, currencyBankLocation), DONT_USE_SHORT_FORMAT, obfuscateAmount)
                local bankedText = zo_strformat(SI_GENERIC_CURRENCY_TOOLTIP_FORMAT, bankedAmmount, currencyIconMarkup, BANK_ICON)
                InformationTooltip:SetVerticalPadding(0)
                InformationTooltip:AddLine(bankedText, "", r, g, b, RIGHT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_RIGHT, DONT_SET_TO_FULL_SIZE, TOOLTIP_LINE_WIDTH)
            end
        end
    end

    ZO_KEYBOARD_CURRENCY_BANK_TOOLTIP_OPTIONS = ZO_ShallowTableCopy(ZO_KEYBOARD_CURRENCY_OPTIONS)
    ZO_KEYBOARD_CURRENCY_BANK_TOOLTIP_OPTIONS.tooltipFunction = function(tooltip)
        LayoutBankTooltip(CURRENCY_LOCATION_BANK)
    end

    ZO_KEYBOARD_CURRENCY_GUILD_BANK_TOOLTIP_OPTIONS = ZO_ShallowTableCopy(ZO_KEYBOARD_CURRENCY_OPTIONS)
    ZO_KEYBOARD_CURRENCY_GUILD_BANK_TOOLTIP_OPTIONS.tooltipFunction = function(tooltip)
        local function ObfuscateFunction(currencyType)
            return currencyType == CURT_MONEY and not DoesPlayerHaveGuildPermission(GetSelectedGuildBankId(), GUILD_PERMISSION_BANK_VIEW_GOLD)
        end

        LayoutBankTooltip(CURRENCY_LOCATION_GUILD_BANK, ObfuscateFunction)
    end
end