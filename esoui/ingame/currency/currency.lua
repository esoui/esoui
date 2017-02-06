CURRENCY_SHOW_ALL = true
CURRENCY_DONT_SHOW_ALL = false
CURRENCY_IGNORE_HAS_ENOUGH = false
CURRENCY_HAS_ENOUGH = false
CURRENCY_NOT_ENOUGH = true

local NOT_ENOUGH_COLOR = ZO_ERROR_COLOR
local DEFAULT_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_GENERAL, INTERFACE_GENERAL_COLOR_ENABLED))
local DEFAULT_GAMEPAD_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_GENERAL, INTERFACE_TEXT_COLOR_SELECTED))

--These are used when we want to represent some item using the UI's currency symbols
--but they aren't "real" currencies tracked on the player object
local UI_ONLY_CURRENCY_START = 1000
UI_ONLY_CURRENCY_INSPIRATION = UI_ONLY_CURRENCY_START
UI_ONLY_CURRENCY_CROWNS = UI_ONLY_CURRENCY_INSPIRATION + 1
UI_ONLY_CURRENCY_CROWN_GEMS = UI_ONLY_CURRENCY_CROWNS + 1

local currencies =
{
    [CURT_MONEY] =
    {
        keyboardTexture = "EsoUI/Art/currency/currency_gold.dds",
        color = ZO_ColorDef:New( GetInterfaceColor(INTERFACE_COLOR_TYPE_CURRENCY, CURRENCY_COLOR_GOLD) ),
        name = GetString(SI_CURRENCY_GOLD),
        formatString = SI_MONEY_FORMAT,
        gamepadTexture = "EsoUI/Art/currency/gamepad/gp_gold.dds",
        gamepadColor = DEFAULT_GAMEPAD_COLOR
    },
    [CURT_ALLIANCE_POINTS] =
    {
        keyboardTexture = "EsoUI/Art/currency/alliancePoints.dds",
        color = ZO_ColorDef:New( GetInterfaceColor(INTERFACE_COLOR_TYPE_CURRENCY, CURRENCY_COLOR_ALLIANCE_POINTS) ),
        name = GetString(SI_CURRENCY_ALLIANCE_POINTS),
        gamepadTexture = "EsoUI/Art/currency/gamepad/gp_alliancePoints.dds",
        gamepadColor = DEFAULT_GAMEPAD_COLOR
    },
    [CURT_TELVAR_STONES] =
    {
        keyboardTexture = "EsoUI/Art/currency/currency_telvar.dds",
        color = ZO_ColorDef:New( GetInterfaceColor(INTERFACE_COLOR_TYPE_CURRENCY, CURRENCY_COLOR_TELVAR_STONES) ),
        name = GetString(SI_CURRENCY_TELVAR_STONES),
        formatString = SI_TELVAR_STONE_FORMAT,
        gamepadTexture = "EsoUI/Art/currency/gamepad/gp_telvar.dds",
        gamepadColor = DEFAULT_GAMEPAD_COLOR
    },
	[CURT_WRIT_VOUCHERS] =
    {
        keyboardTexture = "EsoUI/Art/currency/currency_writvoucher.dds",
        color = ZO_ColorDef:New( GetInterfaceColor(INTERFACE_COLOR_TYPE_CURRENCY, CURRENCY_COLOR_WRIT_VOUCHERS) ),
        name = GetString(SI_CURRENCY_WRIT_VOUCHERS),
        formatString = SI_WRIT_VOUCHER_FORMAT,
        gamepadTexture = "EsoUI/Art/currency/gamepad/gp_writvoucher.dds",
        gamepadColor = DEFAULT_GAMEPAD_COLOR
    },
    
    [UI_ONLY_CURRENCY_INSPIRATION] =
    {
        keyboardTexture = "EsoUI/Art/currency/currency_inspiration.dds",
        color = ZO_ColorDef:New( GetInterfaceColor(INTERFACE_COLOR_TYPE_CURRENCY, CURRENCY_COLOR_INSPIRATION) ),
        name = GetString(SI_CURRENCY_INSPIRATION),
        gamepadTexture = "EsoUI/Art/currency/gamepad/gp_inspiration.dds",
        gamepadColor = DEFAULT_GAMEPAD_COLOR
    },
    [UI_ONLY_CURRENCY_CROWNS] =
    {
        keyboardTexture = "EsoUI/Art/currency/currency_crown.dds",
        color = ZO_ColorDef:New( GetInterfaceColor(INTERFACE_COLOR_TYPE_CURRENCY, CURRENCY_COLOR_GOLD) ),
        name = GetString(SI_CURRENCY_CROWN),
        gamepadTexture = "EsoUI/Art/currency/gamepad/gp_crowns.dds",
        gamepadColor = DEFAULT_GAMEPAD_COLOR
    },
    [UI_ONLY_CURRENCY_CROWN_GEMS] =
    {
        keyboardTexture = "EsoUI/Art/currency/currency_crown_gems.dds",
        color = ZO_ColorDef:New( GetInterfaceColor(INTERFACE_COLOR_TYPE_CURRENCY, CURRENCY_COLOR_GOLD) ),
        name = GetString(SI_CURRENCY_CROWN_GEM),
        gamepadTexture = "EsoUI/Art/currency/gamepad/gp_crown_gems.dds",
        gamepadColor = DEFAULT_GAMEPAD_COLOR
    },
}

ZO_MARKET_CURRENCY_TO_UI_CURRENCY =
{
    [MKCT_CROWNS] = UI_ONLY_CURRENCY_CROWNS,
    [MKCT_CROWN_GEMS] = UI_ONLY_CURRENCY_CROWN_GEMS,
}

function ZO_Currency_MarketCurrencyToUICurrency(marketCurrencyType)
    return ZO_MARKET_CURRENCY_TO_UI_CURRENCY[marketCurrencyType]
end

local ICON_PADDING = 4
local KEYBOARD_TEXTURE_SIZE = 16
local GAMEPAD_TEXTURE_SIZE = 28
local ITEM_ICON_TEXTURE_SIZE = 32
local MULTI_CURRENCY_PADDING = 8 -- the amount of space between each currency type in a control

local DEFAULT_CURRENCY_OPTIONS =
{
    showTooltips = false,
    useShortFormat = false,
    font = "ZoFontGame",
    iconSide = RIGHT,
}

--[[
    Used to set up an args table on a control that will show currencies.
    This is done to prevent many reallocations of consistently used data.
    Pass in the currency types that the control will be known to use.
    (The control doesn't need to ALWAYS use them, but if you know all possible
    types ahead of time, pass then in and a display subtable will be created for
    each type.)

    When you want to show the appropriate currency call ZO_CurrencyControl_SetCurrencyData
    and set up the display parameters.
--]]
function ZO_CurrencyControl_InitializeDisplayTypes(control, ...)
    if(control.currencyArgs == nil) then
        local currencyArgs = {}

        for i = 1, select("#", ...) do
            local currencyType = select(i, ...)
            currencyArgs[i] = { type = currencyType, isUsed = false }
        end

        control.currencyArgs = currencyArgs
    else
        -- Mark all types as unused because we may not have the same data between calls
        -- (Example: go to a store, not everything that's on sale will use the same currency types,
        -- so we can only disable what we know about)
        for _, data in ipairs(control.currencyArgs) do
            data.isUsed = false
        end
    end

    control.numUsedCurrencies = 0
end

-- Use this function if you have a currency control that constantly needs to show arbitrary currency types, but only ever one (non-item) currency at a time
local function DynamicSetCurrencyData(control, currencyType, amount, showAll, notEnough)
    if(control.currencyArgs == nil) then
        control.currencyArgs = {{}}
    end

    if(showAll == nil) then showAll = CURRENCY_SHOW_ALL end
    if(notEnough == nil) then notEnough = CURRENCY_IGNORE_HAS_ENOUGH end

    local displayData = control.currencyArgs[1]

    if(showAll or (amount > 0)) then
        control.numUsedCurrencies = 1
        displayData.type = currencyType
        displayData.amount = amount
        displayData.isUsed = true
        displayData.notEnough = notEnough
    else
        control.numUsedCurrencies = 0
        displayData.isUsed = false
    end
end

local function GetDisplayDataForCurrencyType(control, currencyType, offset)
    local currentOffset = 1 -- used for finding the right item currency type

    for _, data in ipairs(control.currencyArgs) do
        if(data.type == currencyType) then
            if(offset ~= nil) then
                if(offset == currentOffset) then
                    return data
                else
                    currentOffset = currentOffset + 1
                end
            else
                return data
            end
        end
    end
end

function ZO_CurrencyControl_SetCurrencyData(control, currencyType, amount, showAll, notEnough, entryIndex, offset)
    if((control.currencyArgs == nil) or (currencyType == nil)) then return end

    local displayData = GetDisplayDataForCurrencyType(control, currencyType, offset)

    if(displayData) then
        if(showAll == nil) then showAll = CURRENCY_SHOW_ALL end
        if(notEnough == nil) then notEnough = CURRENCY_IGNORE_HAS_ENOUGH end

        if(showAll or (amount > 0)) then
            displayData.type = currencyType
            displayData.amount = amount
            displayData.isUsed = true
            displayData.notEnough = notEnough

            control.numUsedCurrencies = control.numUsedCurrencies + 1

            -- NOTE: Certain currency types always determine the notEnough value automatically.  This could be calculated
            -- externally...might need updates if that value can change after a currency control has been formatted.
            if(currencyType == CURT_ALLIANCE_POINTS) then
                displayData.notEnough = amount > GetAlliancePoints()
            end
        else
            displayData.isUsed = false
        end
    end
end

local CURRENCY_NO_ABBREVIATION_THRESHOLD = zo_pow(10, GetDigitGroupingSize() + 1)
local USE_UPPERCASE_NUMBER_SUFFIXES = true

function ZO_CurrencyControl_FormatCurrency(amount, useShortFormat)
    if useShortFormat and amount >= CURRENCY_NO_ABBREVIATION_THRESHOLD then
        return ZO_AbbreviateNumber(amount, NUMBER_ABBREVIATION_PRECISION_HUNDREDTHS, USE_UPPERCASE_NUMBER_SUFFIXES)
    else
        return ZO_CommaDelimitNumber(amount)
    end
end

function ZO_CurrencyControl_FormatCurrencyAndAppendIcon(amount, useShortFormat, currencyType, isGamepad)
    local formattedCurrency = ZO_CurrencyControl_FormatCurrency(amount, useShortFormat)

    local iconMarkup
    local iconSize
    if isGamepad then
        iconSize =  GAMEPAD_TEXTURE_SIZE
        iconMarkup = currencies[currencyType].gamepadTexture
    else
        iconSize = KEYBOARD_TEXTURE_SIZE
        iconMarkup = currencies[currencyType].keyboardTexture
    end

    iconMarkup = zo_iconFormat(iconMarkup, iconSize, iconSize)

    return zo_strformat(SI_CURRENCY_AMOUNT_WITH_ICON, formattedCurrency, iconMarkup)
end

function ZO_CurrencyControl_BuildCurrencyString(currencyType, currencyAmount)
    if currencies[currencyType].formatString then
        return zo_strformat(currencies[currencyType].formatString, ZO_CurrencyControl_FormatCurrency(currencyAmount))
    end

    return ""
end

function ZO_CurrencyTemplate_OnMouseEnter(control)
    if control.type then
        InitializeTooltip(InformationTooltip)

        if control.options and control.options.customTooltip then
            SetTooltipText(InformationTooltip, zo_strformat(SI_CURRENCY_CUSTOM_TOOLTIP_FORMAT, GetString(control.options.customTooltip)))
        else
            SetTooltipText(InformationTooltip, zo_strformat(SI_CURRENCY_CUSTOM_TOOLTIP_FORMAT, currencies[control.type].name))
        end

        ZO_Tooltips_SetupDynamicTooltipAnchors(InformationTooltip, control)
    end
end

function ZO_CurrencyTemplate_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_CurrencyControl_SetSimpleCurrency(self, currencyType, amount, options, showAll, notEnough)
    DynamicSetCurrencyData(self, currencyType, amount, showAll, notEnough)
    ZO_CurrencyControl_SetCurrency(self, options)
end

local g_currencyStringFormatTable = {}

function ZO_CurrencyControl_SetCurrency(self, options)
    if(self.currencyArgs == nil) then return end

    local showTooltips = true
    local iconSide = RIGHT
    local iconSize = nil
    local overrideColor = nil
    options = options or DEFAULT_CURRENCY_OPTIONS
    local isGamepad = options.isGamepad
    -- Show tooltips by default, only if showTooltips was explicitly set to false in options should
    -- tooltips be turned off.
    if(options.showTooltips == false) then
        showTooltips = false
    end

    if(options.font) then
        self:SetFont(options.font)
    end

    if(options.iconSide) then
        iconSide = options.iconSide
    end

    if(options.iconSize) then
        iconSize = options.iconSize
    end

    if(options.color) then
        if type(options.color) == "function" then
            overrideColor = options.color()
        else
            overrideColor = options.color
        end
    end

    self:SetMouseEnabled(showTooltips)
    self.options = options

    local multiCurrencyPad = 0

    for _, currencyData in ipairs(self.currencyArgs) do
        local currencyType = currencyData.type
        local currencyStaticInfo = currencies[currencyType]
        
        if(currencyData.isUsed and currencyStaticInfo) then
            local amount = currencyData.amount
            local formattedAmount = ZO_CurrencyControl_FormatCurrency(amount, options.useShortFormat)
            local color
            local currencyMarkup, iconMarkup

            if(currencyStaticInfo) then
                if not iconSize then
                    iconSize = isGamepad and GAMEPAD_TEXTURE_SIZE or KEYBOARD_TEXTURE_SIZE
                end
                iconMarkup = zo_iconFormat(isGamepad and currencyStaticInfo.gamepadTexture or currencyStaticInfo.keyboardTexture, iconSize, iconSize)
            else
                --unreachable without CURT_ITEM?
                iconMarkup = zo_iconFormat(tostring(currencyData.keyboardTexture), iconSize or ITEM_ICON_TEXTURE_SIZE, iconSize or ITEM_ICON_TEXTURE_SIZE)
            end

            if(currencyData.notEnough) then
                color = NOT_ENOUGH_COLOR
            else
                if(overrideColor) then
                    color = overrideColor
                elseif(currencyStaticInfo) then
                    color = isGamepad and currencyStaticInfo.gamepadColor or currencyStaticInfo.color or DEFAULT_COLOR
                else
                    color = currencyData.color or DEFAULT_COLOR
                end
            end

            -- If there are not multiple currencies then we can just set the color on the label.  Otherwise, text must be colorized per currency fragment
            if(self.numUsedCurrencies == 1) then
                self:SetColor(color:UnpackRGBA())
            else
                table.insert(g_currencyStringFormatTable, "|c")
                table.insert(g_currencyStringFormatTable, color:ToHex())
            end

            if(iconSide == LEFT) then
                currencyMarkup = string.format("|u%d:%d:currency:%s|u", ICON_PADDING, multiCurrencyPad, formattedAmount)

                table.insert(g_currencyStringFormatTable, iconMarkup)
                table.insert(g_currencyStringFormatTable, currencyMarkup)
            else -- Treat everything else as the default of going on the right
                currencyMarkup = string.format("|u%d:%d:currency:%s|u", multiCurrencyPad, ICON_PADDING, formattedAmount)

                table.insert(g_currencyStringFormatTable, currencyMarkup)
                table.insert(g_currencyStringFormatTable, iconMarkup)
            end

            if(self.numUsedCurrencies > 1) then
                table.insert(g_currencyStringFormatTable, "|r")
            end

            -- Assume that there are more currencies, this is the whitespace to insert between them
            multiCurrencyPad = MULTI_CURRENCY_PADDING

            -- Needs to be handled with a table...this is for tooltips, so we need to figure out which region the mouse is over.
            -- For now, it's last come, first serve...so if there is only a single currency type on the control this works fine.
            self.type = currencyType
        end
    end

    self:SetText(table.concat(g_currencyStringFormatTable))
    ZO_ClearNumericallyIndexedTable(g_currencyStringFormatTable)
end

local function OnMouseUpWrapper(self, button, upInside, ctrl, alt, shift)
    if(button == MOUSE_BUTTON_INDEX_LEFT and upInside) then
        self.currencyClickHandler()
    end
end

function ZO_CurrencyControl_SetClickHandler(self, handler)
    self.currencyClickHandler = handler

    if(handler) then
        self:SetHandler("OnMouseUp", OnMouseUpWrapper)
    else
        self:SetHandler("OnMouseUp", nil)
    end
end

function ZO_Currency_GetPlatformCurrencyIcon(currencyType)
    if IsInGamepadPreferredMode() then
        return currencies[currencyType].gamepadTexture
    else
        return currencies[currencyType].keyboardTexture
    end
end

function ZO_Currency_GetPlatformFormattedGoldIcon()
    if IsInGamepadPreferredMode() then
        return zo_iconFormat("EsoUI/Art/currency/gamepad/gp_gold.dds", 24, 24)
    else
        return zo_iconFormat("EsoUI/Art/currency/currency_gold.dds", 16, 16)
    end
end

function ZO_Currency_GetKeyboardFormattedCurrencyIcon(currencyType, overrideIconSize, inheritColor)
    local iconFormatter = zo_iconFormat
    if inheritColor then
        iconFormatter = zo_iconFormatInheritColor
    end
    local iconSize = overrideIconSize or KEYBOARD_TEXTURE_SIZE
    return iconFormatter(currencies[currencyType].keyboardTexture, iconSize, iconSize)
end

function ZO_Currency_GetGamepadFormattedCurrencyIcon(currencyType, overrideIconSize, inheritColor)
    local iconFormatter = zo_iconFormat
    if inheritColor then
        iconFormatter = zo_iconFormatInheritColor
    end
    local iconSize = overrideIconSize or GAMEPAD_TEXTURE_SIZE
    return iconFormatter(currencies[currencyType].gamepadTexture, iconSize, iconSize)
end

function ZO_Currency_GetPlatformFormattedCurrencyIcon(currencyType, overrideIconSize, inheritColor)
    local iconFormatter = zo_iconFormat
    if inheritColor then
        iconFormatter = zo_iconFormatInheritColor
    end
    if IsInGamepadPreferredMode() then
        local iconSize = overrideIconSize or GAMEPAD_TEXTURE_SIZE
        return iconFormatter(currencies[currencyType].gamepadTexture, iconSize, iconSize)
    else
        local iconSize = overrideIconSize or KEYBOARD_TEXTURE_SIZE
        return iconFormatter(currencies[currencyType].keyboardTexture, iconSize, iconSize)
    end
end
