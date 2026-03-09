local CURRENCY_REDEMPTION_CURRENCY_OPTIONS =
{
    showTooltips = false,
    useShortFormat = false,
    font = "ZoFontGamepadHeaderDataValue",
    iconSide = RIGHT,
    iconSize = 28,
    isGamepad = true,
}

--------------
-- Tome Currency Redemption Dialog
--------------

local function CurrencyRedemptionDialog_GetHeaderData(quantity)
    quantity = quantity or 1

    local data1 =
    {
        value = function(control)
            ZO_CurrencyControl_SetSimpleCurrency(control, CURT_TOME_POINTS, GetPlayerStoredCurrencyAmount(CURT_TOME_POINTS), CURRENCY_REDEMPTION_CURRENCY_OPTIONS)
            return true
        end,
        valueNarration = function()
            return ZO_Currency_FormatGamepad(CURT_TOME_POINTS, GetPlayerStoredCurrencyAmount(CURT_TOME_POINTS), ZO_CURRENCY_FORMAT_AMOUNT_NAME)
        end,
        header = GetString(SI_TAMRIEL_TOMES_CURRENCY_REDEMPTION_CURRENT_BALANCE_LABEL_GAMEPAD),
    }

    local currencyPerBooster = GetTamrielTomeCurrencyPerBooster()
    local postCurrencyAmount = GetPlayerStoredCurrencyAmount(CURT_TOME_POINTS) + (quantity * currencyPerBooster)
    local data2 =
    {
        value = function(control)
            ZO_CurrencyControl_SetSimpleCurrency(control, CURT_TOME_POINTS, postCurrencyAmount, CURRENCY_REDEMPTION_CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, CURRENCY_IGNORE_HAS_ENOUGH)
            return true
        end,
        valueNarration = function()
            return ZO_Currency_FormatGamepad(CURT_TOME_POINTS, postCurrencyAmount, ZO_CURRENCY_FORMAT_AMOUNT_NAME)
        end,
        header = function(control)
            return GetString(SI_TAMRIEL_TOMES_CURRENCY_REDEMPTION_POST_REDEMPTION_BALANCE_LABEL_GAMEPAD)
        end,
    }

    return data1, data2
end

local CurrencyRedemptionDialog_GetOrCreateItemQuantityEntryData
do
    local itemQuantityEntryData
    CurrencyRedemptionDialog_GetOrCreateItemQuantityEntryData = function()
        if itemQuantityEntryData then
            return itemQuantityEntryData
        end

        itemQuantityEntryData = ZO_GamepadEntryData:New()
        itemQuantityEntryData.quantityEntry = true

        itemQuantityEntryData.textChangedCallback = function(control)
            local dialog = itemQuantityEntryData.dialog
            local data = dialog.data
            data.quantity = tonumber(control:GetText())

            local data1, data2 = CurrencyRedemptionDialog_GetHeaderData(data.quantity)
            local headerData =
            {
                data1 = data1,
                data2 = data2,
            }
            ZO_GenericGamepadDialog_RefreshHeaderData(itemQuantityEntryData.dialog, headerData)

            ZO_GenericGamepadDialog_RefreshKeybinds(itemQuantityEntryData.dialog)
        end

        itemQuantityEntryData.focusLostCallback = function()
            --Editing the quantity can impact the price, so re-narrate the header when we're done
            local NARRATE_HEADER = true
            SCREEN_NARRATION_MANAGER:QueueDialog(itemQuantityEntryData.dialog, NARRATE_HEADER)
        end

        itemQuantityEntryData.setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
            itemQuantityEntryData.control = control

            local dialog = itemQuantityEntryData.dialog
            local dialogData = dialog.data
            control.highlight:SetHidden(not selected)
            control.editBoxControl.textChangedCallback = data.textChangedCallback
            control.editBoxControl:SetText(dialogData.quantity)
            control.editBoxControl.focusLostCallback = data.focusLostCallback
            local maxQuantity = dialogData.maxQuantity
            control.maximumControl:SetText(zo_strformat(SI_TAMRIEL_TOMES_CURRENCY_REDEMPTION_MAXIMUM_LABEL, maxQuantity))
        end

        itemQuantityEntryData.narrationText = function(entryData, entryControl)
            local dialog = itemQuantityEntryData.dialog
            local data = dialog.data
            local editBoxText = ZO_FormatEditBoxNarrationText(entryControl.editBoxControl)
            return { editBoxText, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_TAMRIEL_TOMES_CURRENCY_REDEMPTION_MAXIMUM_LABEL, data.maxQuantity)) }
        end

        return itemQuantityEntryData
    end
end

local function CurrencyRedemptionDialog_Setup(dialog, data)
    local parametricListEntries = dialog.info.parametricList
    ZO_ClearNumericallyIndexedTable(parametricListEntries)

    data.quantity = 1
    local maxQuantity = GetPlayerStoredCurrencyAmount(CURT_TOME_POINT_CACHES)
    data.maxQuantity = maxQuantity

    if maxQuantity > 1 then
        local itemQuantityEntry =
        {
            header = GetString(SI_TAMRIEL_TOMES_CURRENCY_REDEMPTION_QUANTITY_LABEL),
            headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",
            template = "ZO_TamrielTomeCurrencyRedemptionDialog_Gamepad_Quantity",
            entryData = CurrencyRedemptionDialog_GetOrCreateItemQuantityEntryData(),
        }

        table.insert(parametricListEntries, itemQuantityEntry)
    end

    local data1, data2 = CurrencyRedemptionDialog_GetHeaderData(data.quantity)

    local displayData =
    {
        data1 = data1,
        data2 = data2,
    }
    local DONT_LIMIT_NUM_ENTRIES = nil
    dialog:setupFunc(DONT_LIMIT_NUM_ENTRIES, displayData)
end

ZO_Dialogs_RegisterCustomDialog("TAMRIEL_TOME_CURRENCY_REDEMPTION_GAMEPAD",
    {
        setup = CurrencyRedemptionDialog_Setup,
        canQueue = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            allowRightStickPassThrough = true,
        },
        title =
        {
            text = function()
                local IS_PLURAL = false
                local currencyName = GetCurrencyName(CURT_TOME_POINT_CACHES, IS_PLURAL)
                return zo_strformat(SI_TAMRIEL_TOMES_CURRENCY_REDEMPTION_TITLE, currencyName)
            end,
        },
        mainText =
        {
            text = function()
                local IS_PLURAL = false
                local currencyName = GetCurrencyName(CURT_TOME_POINT_CACHES, IS_PLURAL)
                currencyName = ZO_SELECTED_TEXT:Colorize(currencyName)

                local currencyIcon = ZO_Currency_GetGamepadCurrencyIcon(CURT_TOME_POINT_CACHES)
                local iconMarkup = zo_iconFormat(currencyIcon, "100%", "100%")

                return string.format("%s %s", iconMarkup, currencyName)
            end,
        },
        parametricList = {}, -- we'll generate the entries on setup
        blockDialogReleaseOnPress = true, -- We need to manually control when we release so we can use the select keybind to activate entries
        baseNarrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
        buttons =
        {
            -- Select Button
            {
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_GAMEPAD_SELECT_OPTION),
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    local targetControl = dialog.entryList:GetTargetControl()
                    if targetData.quantityEntry and targetControl then
                        targetControl.editBoxControl:TakeFocus()
                    end
                end,

                visible = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    return targetData ~= nil
                end,
            },
            --Back
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_DECLINE,
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("TAMRIEL_TOME_CURRENCY_REDEMPTION_GAMEPAD")
                end,
            },
            --Confirm
            {
                keybind = "DIALOG_SECONDARY",
                text = SI_DIALOG_CONFIRM,
                clickSound = SOUNDS.DIALOG_ACCEPT,
                enabled = function(dialog)
                    local data = dialog.data
                    if data.quantity > data.maxQuantity then
                        local errorText = zo_strformat(SI_TAMRIEL_TOMES_CURRENCY_REDEMPTION_EXCEEDS_MAX_QUANTITY_ERROR, data.maxQuantity)
                        return false, errorText
                    end

                    return true
                end,
                callback = function(dialog)
                    local quantity = tonumber(dialog.data.quantity)
                    if quantity and quantity > 0 then
                        local maxQuantity = GetPlayerStoredCurrencyAmount(CURT_TOME_POINT_CACHES)
                        if quantity <= maxQuantity then
                            TryRedeemCachesForTomePoints(quantity)
                            ZO_Dialogs_ReleaseDialogOnButtonPress("TAMRIEL_TOME_CURRENCY_REDEMPTION_GAMEPAD")
                        end
                    end
                end,
            },
        },
    }
)

--------------
-- Tome Token Redemption Dialog
--------------

local function TokenRedemptionDialog_GetHeaderData()
    local currencyAmount = GetPlayerStoredCurrencyAmount(CURT_TOME_TOKENS)

    local data1 =
    {
        value = function(control)
            ZO_CurrencyControl_SetSimpleCurrency(control, CURT_TOME_TOKENS, currencyAmount, CURRENCY_REDEMPTION_CURRENCY_OPTIONS)
            return true
        end,
        valueNarration = function()
            return ZO_Currency_FormatGamepad(CURT_TOME_TOKENS, currencyAmount, ZO_CURRENCY_FORMAT_AMOUNT_NAME)
        end,
        header = GetString(SI_TAMRIEL_TOMES_TOKEN_REDEMPTION_PRE_REDEMPTION_BALANCE_LABEL_GAMEPAD),
    }

    local currencyCost = GetCurrencyCostToUpgradeTamrielTome()
    local postCurrencyAmount = currencyAmount - currencyCost
    local data2 =
    {
        value = function(control)
            ZO_CurrencyControl_SetSimpleCurrency(control, CURT_TOME_TOKENS, postCurrencyAmount, CURRENCY_REDEMPTION_CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, CURRENCY_IGNORE_HAS_ENOUGH)
            return true
        end,
        valueNarration = function()
            return ZO_Currency_FormatGamepad(CURT_TOME_TOKENS, postCurrencyAmount, ZO_CURRENCY_FORMAT_AMOUNT_NAME)
        end,
        header = function(control)
            return GetString(SI_TAMRIEL_TOMES_TOKEN_REDEMPTION_POST_REDEMPTION_BALANCE_LABEL_GAMEPAD)
        end,
    }

    return data1, data2
end

local function TokenRedemptionDialog_Setup(dialog, data)
    local data1, data2 = TokenRedemptionDialog_GetHeaderData(data.quantity)

    local headerData =
    {
        data1 = data1,
        data2 = data2,
    }
    dialog:setupFunc(headerData)
end

local function ShowResultDialog(tomeId, result)
    -- TODO Tamriel Tomes: Refactor dialogs to support a universal setup function
    if result == TAMRIEL_TOME_PURCHASE_RESULT_SUCCESS then
        PlaySound(SOUNDS.TAMRIEL_TOMES_PASS_PURCHASED)
    end

    ZO_Dialogs_ShowGamepadDialog("TAMRIEL_TOME_PURCHASE_RESULT", { tomeId = tomeId, result = result })
end

ZO_Dialogs_RegisterCustomDialog("TAMRIEL_TOME_TOKEN_REDEMPTION_GAMEPAD",
{
    setup = TokenRedemptionDialog_Setup,
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = GetString(SI_TAMRIEL_TOMES_TOKEN_REDEMPTION_TITLE),
    },
    mainText =
    {
        text = function()
            local currencyCost = GetCurrencyCostToUpgradeTamrielTome()
            local currencyString = ZO_Currency_FormatGamepad(CURT_TOME_TOKENS, currencyCost, ZO_CURRENCY_FORMAT_WHITE_AMOUNT_WHITE_NAME_ICON)
            return zo_strformat(SI_TAMRIEL_TOMES_TOKEN_REDEMPTION_TEXT, currencyString)
        end,
    },
    buttons =
    {
        {
            keybind = "DIALOG_PRIMARY",
            text = GetString(SI_MARKET_CONFIRM_PURCHASE_KEYBIND_TEXT),
            callback = function(dialog)
                local pendingDialogData =
                {
                    title = GetString(SI_TAMRIEL_TOMES_TOKEN_REDEMPTION_TITLE),
                    loadingText = GetString(SI_DIALOG_PROCESSING_PURCHASE),
                    onSetup = function()
                        TryPurchaseTamrielTomePremiumPlus(dialog.data.tomeId)
                    end,
                    onTimeout = function()
                        ShowResultDialog(tomeId, TAMRIEL_TOME_PURCHASE_RESULT_TIMED_OUT)
                    end,
                    events =
                    {
                        {
                            event = EVENT_TAMRIEL_TOME_PURCHASE_RESULT,
                            callback = function(_, tomeId, result)
                                ShowResultDialog(tomeId, result)
                            end
                        },
                    }
                }
                ZO_Dialogs_ShowGamepadDialog("GAMEPAD_PENDING_RESULT_DIALOG", pendingDialogData)
            end,
        },
        {
            keybind = "DIALOG_NEGATIVE",
            text = SI_DIALOG_DECLINE,
        },
    },
})

--------------
-- Tome Insufficient Token Redemption Dialog
--------------

local function InsufficientTokenRedemptionDialog_GetHeaderData()
    local data1 =
    {
        value = function(control)
            ZO_CurrencyControl_SetSimpleCurrency(control, CURT_TOME_TOKENS, GetPlayerStoredCurrencyAmount(CURT_TOME_TOKENS), CURRENCY_REDEMPTION_CURRENCY_OPTIONS)
            return true
        end,
        valueNarration = function()
            return ZO_Currency_FormatGamepad(CURT_TOME_TOKENS, GetPlayerStoredCurrencyAmount(CURT_TOME_TOKENS), ZO_CURRENCY_FORMAT_AMOUNT_NAME)
        end,
        header = GetString(SI_TAMRIEL_TOMES_CURRENCY_REDEMPTION_CURRENT_BALANCE_LABEL_GAMEPAD),
    }

    return data1
end

local function InsufficientTokenRedemptionDialog_Setup(dialog, data)
    local data1 = InsufficientTokenRedemptionDialog_GetHeaderData(data.quantity)

    local headerData =
    {
        data1 = data1,
    }
    dialog:setupFunc(headerData)
end

ZO_Dialogs_RegisterCustomDialog("TAMRIEL_TOME_INSUFFICIENT_TOKEN_REDEMPTION_GAMEPAD",
    {
        setup = InsufficientTokenRedemptionDialog_Setup,
        canQueue = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = function()
                local IS_PLURAL = false
                local currencyName = GetCurrencyName(CURT_TOME_TOKENS, IS_PLURAL)
                return zo_strformat(SI_TAMRIEL_TOMES_INSUFFICIENT_TOKENS_DIALOG_TITLE, currencyName)
            end,
        },
        mainText =
        {
            text = function()
                local currencyCost = GetCurrencyCostToUpgradeTamrielTome()
                local currencyString = ZO_Currency_FormatGamepad(CURT_TOME_TOKENS, currencyCost, ZO_CURRENCY_FORMAT_WHITE_AMOUNT_WHITE_NAME_ICON)
                return zo_strformat(SI_TAMRIEL_TOMES_INSUFFICIENT_TOKENS_DIALOG_TEXT, currencyString)
            end,
        },
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },
        },
    }
)
