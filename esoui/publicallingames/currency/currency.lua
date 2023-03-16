CURRENCY_SHOW_ALL = true
CURRENCY_DONT_SHOW_ALL = false
CURRENCY_IGNORE_HAS_ENOUGH = false
CURRENCY_HAS_ENOUGH = false
CURRENCY_NOT_ENOUGH = true

local NOT_ENOUGH_COLOR = ZO_ERROR_COLOR
local DEFAULT_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_GENERAL, INTERFACE_GENERAL_COLOR_ENABLED))

ZO_CURRENCIES_DATA = {}
local g_currenciesData = ZO_CURRENCIES_DATA -- These APIs are called a lot, so let's not spam global lookup

ZO_VALID_CURRENCY_TYPES = {}

do
    for currencyType = CURT_ITERATION_BEGIN, CURT_ITERATION_END do
        if IsCurrencyValid(currencyType) then 
            table.insert(ZO_VALID_CURRENCY_TYPES, currencyType)

            local IS_PLURAL = false
            local IS_UPPER = false
            local currencyInfo =
            {
                amountLabel = GetCurrencyName(currencyType, IS_PLURAL, IS_UPPER),
                color = ZO_ColorDef:New(GetCurrencyKeyboardColor(currencyType)),
                gamepadColor = ZO_ColorDef:New(GetCurrencyGamepadColor(currencyType)),
                isDefaultLowercase = IsCurrencyDefaultNameLowercase(currencyType),
            }

            local keyboardTexture, keyboardPercentOfLineSize = GetCurrencyKeyboardIcon(currencyType)
            currencyInfo.keyboardTexture = keyboardTexture
            currencyInfo.keyboardPercentOfLineSize = keyboardPercentOfLineSize .. "%"
            currencyInfo.keyboardLootTexture = GetCurrencyLootKeyboardIcon(currencyType)

            local gamepadTexture, gamepadPercentOfLineSize = GetCurrencyGamepadIcon(currencyType)
            currencyInfo.gamepadTexture = gamepadTexture
            currencyInfo.gamepadPercentOfLineSize = gamepadPercentOfLineSize .. "%"
            currencyInfo.gamepadLootTexture = GetCurrencyLootGamepadIcon(currencyType)

            g_currenciesData[currencyType] = currencyInfo
        end
    end
end

local ICON_PADDING = 4
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
    if control.currencyArgs == nil then
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
local function DynamicSetCurrencyData(control, currencyType, amount, showAll, notEnough, displayOptions)
    if control.currencyArgs == nil then
        control.currencyArgs = {{}}
    end

    if showAll == nil then showAll = CURRENCY_SHOW_ALL end
    if notEnough == nil then notEnough = CURRENCY_IGNORE_HAS_ENOUGH end

    local displayData = control.currencyArgs[1]

    if showAll or (amount > 0) then
        control.numUsedCurrencies = 1
        displayData.type = currencyType
        displayData.amount = amount
        displayData.isUsed = true
        displayData.notEnough = notEnough
        if displayOptions then
            displayData.obfuscateAmount = displayOptions.obfuscateAmount
            displayData.currencyCapAmount = displayOptions.currencyCapAmount
            displayData.iconInheritColor = displayOptions.iconInheritColor
            displayData.color = displayOptions.color
            displayData.strikethroughCurrencyAmount = displayOptions.strikethroughCurrencyAmount
        else
            displayData.obfuscateAmount = nil
            displayData.currencyCapAmount = nil
            displayData.iconInheritColor = nil
            displayData.color = nil
            displayData.strikethroughCurrencyAmount = nil
        end
    else
        control.numUsedCurrencies = 0
        displayData.isUsed = false
    end
end

local function GetDisplayDataForCurrencyType(control, currencyType, offset)
    local currentOffset = 1 -- used for finding the right item currency type

    for _, data in ipairs(control.currencyArgs) do
        if data.type == currencyType then
            if offset ~= nil then
                if offset == currentOffset then
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
    if (control.currencyArgs == nil) or (currencyType == nil) then return end

    local displayData = GetDisplayDataForCurrencyType(control, currencyType, offset)

    if displayData then
        if showAll == nil then showAll = CURRENCY_SHOW_ALL end
        if notEnough == nil then notEnough = CURRENCY_IGNORE_HAS_ENOUGH end

        if showAll or (amount > 0) then
            displayData.type = currencyType
            displayData.amount = amount
            displayData.isUsed = true
            displayData.notEnough = notEnough

            control.numUsedCurrencies = control.numUsedCurrencies + 1

            -- NOTE: Certain currency types always determine the notEnough value automatically. This could be calculated
            -- externally...might need updates if that value can change after a currency control has been formatted.
            if currencyType == CURT_ALLIANCE_POINTS then
                displayData.notEnough = amount > GetCurrencyAmount(CURT_ALLIANCE_POINTS, CURRENCY_LOCATION_CHARACTER)
            end
        else
            displayData.isUsed = false
        end
    end
end

local CURRENCY_NO_ABBREVIATION_THRESHOLD = zo_pow(10, GetDigitGroupingSize() + 1)
local USE_UPPERCASE_NUMBER_SUFFIXES = true

function ZO_CurrencyControl_FormatCurrency(amount, useShortFormat, obfuscateAmount)
    if obfuscateAmount then
        return GetString(SI_CURRENCY_OBFUSCATE_VALUE)
    elseif useShortFormat and amount >= CURRENCY_NO_ABBREVIATION_THRESHOLD then
        return ZO_AbbreviateNumber(amount, NUMBER_ABBREVIATION_PRECISION_HUNDREDTHS, USE_UPPERCASE_NUMBER_SUFFIXES)
    else
        return ZO_CommaDelimitNumber(amount)
    end
end

function ZO_CurrencyControl_FormatAndLocalizeCurrency(...)
    local formattedCurrency = ZO_CurrencyControl_FormatCurrency(...)
    return ZO_FastFormatDecimalNumber(formattedCurrency)
end

function ZO_CurrencyControl_FormatCurrencyAndAppendIcon(amount, useShortFormat, currencyType, isGamepad, obfuscateAmount)
    local formattedCurrency = ZO_CurrencyControl_FormatAndLocalizeCurrency(amount, useShortFormat, obfuscateAmount)

    local iconMarkup
    local iconSize
    local currencyInfo = g_currenciesData[currencyType]
    if isGamepad then
        iconSize =  currencyInfo.gamepadPercentOfLineSize
        iconMarkup = currencyInfo.gamepadTexture
    else
        iconSize = currencyInfo.keyboardPercentOfLineSize
        iconMarkup = currencyInfo.keyboardTexture
    end

    iconMarkup = zo_iconFormat(iconMarkup, iconSize, iconSize)

    return string.format("%s %s", formattedCurrency, iconMarkup)
end

function ZO_CurrencyTemplate_OnMouseEnter(control)
    if control.type then
        InitializeTooltip(InformationTooltip)

        local options = control.options
        local useDefaultText = true
        if options then
            if options.tooltipFunction then
                options.tooltipFunction(InformationTooltip)
                useDefaultText = false
            elseif options.customTooltip then
                SetTooltipText(InformationTooltip, zo_strformat(SI_CURRENCY_CUSTOM_TOOLTIP_FORMAT, GetString(options.customTooltip)))
                useDefaultText = false
            end
        end
        
        if useDefaultText then
            SetTooltipText(InformationTooltip, zo_strformat(SI_CURRENCY_CUSTOM_TOOLTIP_FORMAT, g_currenciesData[control.type].amountLabel))
        end

        ZO_Tooltips_SetupDynamicTooltipAnchors(InformationTooltip, control)
    end
end

function ZO_CurrencyTemplate_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

-- displayOptions is a table of additional display options to modify how the given currencyType appears in the control
--     obfuscateAmount - will not show the passed in currency amount, but will instead show SI_CURRENCY_OBFUSCATE_VALUE
--     currencyCapAmount - if specified, the formatted currency amount will also show the currency cap in the format amount/cap
--     iconInheritColor - will make the currency icon inherit the color of the currency amount
--     color - is the color of the currency amount shown, will override the default color, but not any color specified in options.color
--     strikethroughCurrencyAmount - will add a strikethrough to the currency amount (as long as it's not obfuscated)
function ZO_CurrencyControl_SetSimpleCurrency(labelControl, currencyType, amount, options, showAll, notEnough, displayOptions)
    DynamicSetCurrencyData(labelControl, currencyType, amount, showAll, notEnough, displayOptions)
    ZO_CurrencyControl_SetCurrency(labelControl, options)
end

local g_currencyStringFormatTable = {}

function ZO_CurrencyControl_SetCurrency(self, options)
    if self.currencyArgs == nil then return end

    options = options or DEFAULT_CURRENCY_OPTIONS

    local isGamepad = options.isGamepad

    -- Show tooltips by default, only if showTooltips was explicitly set to false in options should
    -- tooltips be turned off.
    local showTooltips = true
    if options.showTooltips == false then
        showTooltips = false
    end

    if options.font then
        self:SetFont(options.font)
    end

    local iconSide = RIGHT
    if options.iconSide then
        iconSide = options.iconSide
    end

    local iconSize = nil
    if options.iconSize then
        iconSize = options.iconSize
    end

    local overrideColor = nil
    if options.color then
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
        local currencyStaticInfo = g_currenciesData[currencyType]

        if currencyData.isUsed and currencyStaticInfo then
            local color
            if currencyData.notEnough then
                color = NOT_ENOUGH_COLOR
            else
                if currencyData.color then
                    color = currencyData.color
                elseif overrideColor then
                    color = overrideColor
                else
                    color = isGamepad and currencyStaticInfo.gamepadColor or currencyStaticInfo.color or DEFAULT_COLOR
                end
            end

            -- If there are not multiple currencies then we can just set the color on the label. Otherwise, text must be colorized per currency fragment
            if self.numUsedCurrencies == 1 then
                self:SetColor(color:UnpackRGBA())
            else
                table.insert(g_currencyStringFormatTable, "|c")
                table.insert(g_currencyStringFormatTable, color:ToHex())
            end

            if not iconSize then
                iconSize = isGamepad and currencyStaticInfo.gamepadPercentOfLineSize or currencyStaticInfo.keyboardPercentOfLineSize
            end

            local currencyTexture = isGamepad and currencyStaticInfo.gamepadTexture or currencyStaticInfo.keyboardTexture
            local iconMarkup
            if currencyData.iconInheritColor then
                iconMarkup = zo_iconFormatInheritColor(currencyTexture, iconSize, iconSize)
            else
                iconMarkup = zo_iconFormat(currencyTexture, iconSize, iconSize)
            end

            local formattedAmount = ZO_CurrencyControl_FormatAndLocalizeCurrency(currencyData.amount, options.useShortFormat, currencyData.obfuscateAmount)

            if not currencyData.obfuscateAmount then
                if currencyData.currencyCapAmount then
                    local formattedCap = ZO_CurrencyControl_FormatAndLocalizeCurrency(currencyData.currencyCapAmount, options.useShortFormat)
                    formattedAmount = formattedAmount .. "/" .. formattedCap
                end
            end

            local useStrikethrough = not currencyData.obfuscateAmount and currencyData.strikethroughCurrencyAmount
            if useStrikethrough then
                formattedAmount = zo_strikethroughTextFormat(formattedAmount)
            end

            local leftPadding
            local rightPadding
            if iconSide == LEFT then
                leftPadding = ICON_PADDING
                rightPadding = multiCurrencyPad

            else -- Treat everything else as the default of going on the right
                leftPadding = multiCurrencyPad
                rightPadding = ICON_PADDING
            end

            local currencyMarkup
            if not useStrikethrough then
                currencyMarkup = string.format("|u%d:%d:currency:%s|u", leftPadding, rightPadding, formattedAmount)
            else
                -- putting line markup inside a user area doesn't work, so use two user areas on either side of the line markup to keep the padding
                local NO_PADDING = 0
                currencyMarkup = string.format("|u%d:%d:currency:|u%s|u%d:%d:currency:|u", leftPadding, NO_PADDING, formattedAmount, NO_PADDING, ICON_PADDING)
            end

            if iconSide == LEFT then
                table.insert(g_currencyStringFormatTable, iconMarkup)
                table.insert(g_currencyStringFormatTable, currencyMarkup)
            else -- RIGHT
                table.insert(g_currencyStringFormatTable, currencyMarkup)
                table.insert(g_currencyStringFormatTable, iconMarkup)
            end

            if self.numUsedCurrencies > 1 then
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
    if button == MOUSE_BUTTON_INDEX_LEFT and upInside then
        self.currencyClickHandler()
    end
end

function ZO_CurrencyControl_SetClickHandler(self, handler)
    self.currencyClickHandler = handler

    if handler then
        self:SetHandler("OnMouseUp", OnMouseUpWrapper)
    else
        self:SetHandler("OnMouseUp", nil)
    end
end

--[[

Augmented Currency API

]]--

function ZO_Currency_GetKeyboardCurrencyIcon(currencyType)
    return g_currenciesData[currencyType].keyboardTexture
end

function ZO_Currency_GetGamepadCurrencyIcon(currencyType)
    return g_currenciesData[currencyType].gamepadTexture
end

function ZO_Currency_GetPlatformCurrencyIcon(currencyType)
    if IsInGamepadPreferredMode() then
        return g_currenciesData[currencyType].gamepadTexture
    else
        return g_currenciesData[currencyType].keyboardTexture
    end
end

function ZO_Currency_GetPlatformCurrencyLootIcon(currencyType)
    if IsInGamepadPreferredMode() then
        return g_currenciesData[currencyType].gamepadLootTexture
    else
        return g_currenciesData[currencyType].keyboardLootTexture
    end
end

function ZO_Currency_GetKeyboardFormattedCurrencyIcon(currencyType, overrideIconSize, inheritColor)
    local iconFormatter = zo_iconFormat
    if inheritColor then
        iconFormatter = zo_iconFormatInheritColor
    end
    local currencyInfo = g_currenciesData[currencyType]
    local iconSize = overrideIconSize or currencyInfo.keyboardPercentOfLineSize
    return iconFormatter(currencyInfo.keyboardTexture, iconSize, iconSize)
end

function ZO_Currency_GetGamepadFormattedCurrencyIcon(currencyType, overrideIconSize, inheritColor)
    local iconFormatter = zo_iconFormat
    if inheritColor then
        iconFormatter = zo_iconFormatInheritColor
    end
    local currencyInfo = g_currenciesData[currencyType]
    local iconSize = overrideIconSize or currencyInfo.gamepadPercentOfLineSize
    return iconFormatter(g_currenciesData[currencyType].gamepadTexture, iconSize, iconSize)
end

function ZO_Currency_GetPlatformFormattedCurrencyIcon(currencyType, overrideIconSize, inheritColor)
    local iconFormatter = zo_iconFormat
    if inheritColor then
        iconFormatter = zo_iconFormatInheritColor
    end
    local currencyInfo = g_currenciesData[currencyType]
    if IsInGamepadPreferredMode() then
        local iconSize = overrideIconSize or currencyInfo.gamepadPercentOfLineSize
        return iconFormatter(g_currenciesData[currencyType].gamepadTexture, iconSize, iconSize)
    else
        local iconSize = overrideIconSize or currencyInfo.keyboardPercentOfLineSize
        return iconFormatter(g_currenciesData[currencyType].keyboardTexture, iconSize, iconSize)
    end
end

ZO_CURRENCY_FORMAT_AMOUNT_NAME = 1
ZO_CURRENCY_FORMAT_WHITE_AMOUNT_WHITE_NAME = 2
ZO_CURRENCY_FORMAT_PARENTHETICAL_AMOUNT = 3
ZO_CURRENCY_FORMAT_AMOUNT_ICON = 4
ZO_CURRENCY_FORMAT_WHITE_AMOUNT_ICON = 5
ZO_CURRENCY_FORMAT_ERROR_AMOUNT_ICON = 6
ZO_CURRENCY_FORMAT_PLURAL_NAME_ICON = 7
ZO_CURRENCY_FORMAT_STRIKETHROUGH_AMOUNT_ICON = 8

local function GetCurrencyColor(currencyType, isGamepad)
    if isGamepad then
        return g_currenciesData[currencyType].gamepadColor
    else
        return g_currenciesData[currencyType].color
    end
end

local function GetCurrencyIconMarkup(currencyType, isGamepad, iconInheritColor)
    local DONT_OVERRIDE_ICON_SIZE = nil
    if isGamepad then
        return ZO_Currency_GetGamepadFormattedCurrencyIcon(currencyType, DONT_OVERRIDE_ICON_SIZE, iconInheritColor)
    else
        return ZO_Currency_GetKeyboardFormattedCurrencyIcon(currencyType, DONT_OVERRIDE_ICON_SIZE, iconInheritColor)
    end
end

--The return of this function is intended to be already localized in terms of delimiters.  Do NOT pass the result into a <<f:1>> formatter, or the delimiters will be wrong.
-- extraOptions is a table of additional options to modify how the currency is formatted
--     showCap - if set to true, the formatted currency amount will also show the currency cap in the format amount/cap if there is a cap
--     currencyLocation - used with showCap to specify the currency location to pull the cap from
--     color - specify a color to be used for the currency amount instead of the default currency color
--     iconInheritColor - will allow the currency icon to inherit the color of the label it's displayed in
--     obfuscateAmount - will not show the passed in currency amount, but will instead show SI_CURRENCY_OBFUSCATE_VALUE
--     useShortFormat - will abbreviate the number if it's above the CURRENCY_NO_ABBREVIATION_THRESHOLD
function ZO_Currency_Format(currencyAmount, currencyType, formatType, isGamepad, extraOptions)
    local formattedAmount
    if currencyAmount then
        local useShortFormat = extraOptions and extraOptions.useShortFormat or nil
        local obfuscateAmount = extraOptions and extraOptions.obfuscateAmount or nil
        formattedAmount = ZO_CurrencyControl_FormatAndLocalizeCurrency(currencyAmount, useShortFormat, obfuscateAmount)
        if extraOptions and extraOptions.showCap then
            local currencyLocation = extraOptions.currencyLocation
            if IsCurrencyCapped(currencyType, currencyLocation) then
                local maxPossible = GetMaxPossibleCurrency(currencyType, currencyLocation)
                local formattedCap = ZO_CurrencyControl_FormatAndLocalizeCurrency(maxPossible)
                formattedAmount = formattedAmount .. "/" .. formattedCap
            end
        end
    end

    local iconInheritColor = extraOptions and extraOptions.iconInheritColor or false

    --We use string format to preserve the gender markup on currencyName.
    if formatType == ZO_CURRENCY_FORMAT_AMOUNT_NAME then
        local currencyInfo = g_currenciesData[currencyType]
        local currencyName = GetCurrencyName(currencyType, IsCountSingularForm(currencyAmount), currencyInfo.isDefaultLowercase)
        return string.format("%s %s", formattedAmount, currencyName)
    elseif formatType == ZO_CURRENCY_FORMAT_WHITE_AMOUNT_WHITE_NAME then
        local currencyInfo = g_currenciesData[currencyType]
        local currencyName = GetCurrencyName(currencyType, IsCountSingularForm(currencyAmount), currencyInfo.isDefaultLowercase)
        return string.format("|cffffff%s %s|r", formattedAmount, currencyName)
    elseif formatType == ZO_CURRENCY_FORMAT_PARENTHETICAL_AMOUNT then
        return string.format("(%s)", formattedAmount)
    elseif formatType == ZO_CURRENCY_FORMAT_AMOUNT_ICON then
        local iconMarkup = GetCurrencyIconMarkup(currencyType, isGamepad, iconInheritColor)
        local color = extraOptions and extraOptions.color or GetCurrencyColor(currencyType, isGamepad)
        return string.format("%s|u0:6%%:currency:|u%s", color:Colorize(formattedAmount), iconMarkup)
    elseif formatType == ZO_CURRENCY_FORMAT_WHITE_AMOUNT_ICON then
        local iconMarkup = GetCurrencyIconMarkup(currencyType, isGamepad, iconInheritColor)
        return string.format("|cffffff%s|r|u0:6%%:currency:|u%s", formattedAmount, iconMarkup)
    elseif formatType == ZO_CURRENCY_FORMAT_ERROR_AMOUNT_ICON then
        local iconMarkup = GetCurrencyIconMarkup(currencyType, isGamepad, iconInheritColor)
        return string.format("%s|u0:6%%:currency:|u%s", ZO_ERROR_COLOR:Colorize(formattedAmount), iconMarkup)
    elseif formatType == ZO_CURRENCY_FORMAT_PLURAL_NAME_ICON then
        local IS_PLURAL = false
        local currencyInfo = g_currenciesData[currencyType]
        local currencyName = GetCurrencyName(currencyType, IS_PLURAL, currencyInfo.isDefaultLowercase)
        local iconMarkup = GetCurrencyIconMarkup(currencyType, isGamepad, iconInheritColor)
        return string.format("|u0:6%%:currency:%s|u%s", currencyName, iconMarkup)
    elseif formatType == ZO_CURRENCY_FORMAT_STRIKETHROUGH_AMOUNT_ICON then
        local iconMarkup = GetCurrencyIconMarkup(currencyType, isGamepad, iconInheritColor)
        local color = extraOptions and extraOptions.color or GetCurrencyColor(currencyType, isGamepad)
        local strikethroughAmountString = zo_strikethroughTextFormat(formattedAmount)
        return string.format("%s|u0:6%%:currency:|u%s", color:Colorize(strikethroughAmountString), iconMarkup)
    end
end

function ZO_Currency_FormatKeyboard(currencyType, currencyAmount, formatType, extraOptions)
    local IS_KEYBOARD = false
    return ZO_Currency_Format(currencyAmount, currencyType, formatType, IS_KEYBOARD, extraOptions)
end

function ZO_Currency_FormatGamepad(currencyType, currencyAmount, formatType, extraOptions)
    local IS_GAMEPAD = true
    return ZO_Currency_Format(currencyAmount, currencyType, formatType, IS_GAMEPAD, extraOptions)
end

function ZO_Currency_FormatPlatform(currencyType, currencyAmount, formatType, extraOptions)
   return ZO_Currency_Format(currencyAmount, currencyType, formatType, IsInGamepadPreferredMode(), extraOptions)
end

function ZO_Currency_GetAmountLabel(currencyType)
    return g_currenciesData[currencyType].amountLabel
end

function ZO_Currency_GetPlayerCarriedGoldNarration()
    return ZO_Currency_FormatGamepad(CURT_MONEY, GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER), ZO_CURRENCY_FORMAT_AMOUNT_ICON)
end

function ZO_Currency_GetPlayerCarriedGoldCurrencyNameNarration()
    return ZO_Currency_FormatGamepad(CURT_MONEY, GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER), ZO_CURRENCY_FORMAT_AMOUNT_NAME)
end

function ZO_Currency_GetPlatformColor(currencyType)
    local isGamepad = IsInGamepadPreferredMode()
    return GetCurrencyColor(currencyType, isGamepad)
end

function ZO_Currency_TryShowThresholdDialog(storeItemIndex, quantity, itemData)
    local playerGold = GetCurrencyAmount(CURT_MONEY, GetCurrencyPlayerStoredLocation(CURT_MONEY))
    local playerCurrency1 = GetCurrencyAmount(itemData.currencyType1, GetCurrencyPlayerStoredLocation(itemData.currencyType1))
    local playerCurrency2 = GetCurrencyAmount(itemData.currencyType2, GetCurrencyPlayerStoredLocation(itemData.currencyType2))
    local costGold = quantity * itemData.price
    local costCurrency1 = quantity * itemData.currencyQuantity1
    local costCurrency2 = quantity * itemData.currencyQuantity2
    local confirmGold = DoesCurrencyAmountMeetConfirmationThreshold(CURT_MONEY, costGold)
    local confirmCurrency1 = DoesCurrencyAmountMeetConfirmationThreshold(itemData.currencyType1, costCurrency1)
    local confirmCurrency2 = DoesCurrencyAmountMeetConfirmationThreshold(itemData.currencyType2, costCurrency2)
    if itemData.meetsRequirementsToBuy and ((confirmGold and playerGold >= costGold) or (confirmCurrency1 and playerCurrency1 >= costCurrency1) or (confirmCurrency2 and playerCurrency2 >= costCurrency2)) then
        local itemLink = GetStoreItemLink(storeItemIndex)
        local params = {
            quantity,
            itemLink,
            costGold > 0 and ZO_Currency_FormatKeyboard(CURT_MONEY, costGold, ZO_CURRENCY_FORMAT_AMOUNT_ICON) or "",
            costCurrency1 > 0 and ZO_Currency_FormatKeyboard(itemData.currencyType1, costCurrency1, ZO_CURRENCY_FORMAT_AMOUNT_ICON) or "",
            costCurrency2 > 0 and ZO_Currency_FormatKeyboard(itemData.currencyType2, costCurrency2, ZO_CURRENCY_FORMAT_AMOUNT_ICON) or ""
        }
        ZO_Dialogs_ShowPlatformDialog("CONFIRM_PURCHASE", { buyIndex = storeItemIndex, quantity = quantity }, {mainTextParams = params})
        return true
    end
    return false
end