--------------
-- Tome Currency Redemption Dialog
--------------

local MIN_CURRENCY_REDEMPTION_QUANTITY = 1

local function CurrencyRedemptionDialog_UpdateBalanceControls(dialog, data)
    local currencyAmount = GetPlayerStoredCurrencyAmount(CURT_TOME_POINTS)

    local currentBalanceAmountLabel = dialog.balanceContainer.currencyAmount
    ZO_CurrencyControl_SetSimpleCurrency(currentBalanceAmountLabel, CURT_TOME_POINTS, currencyAmount)

    local postBalanceAmountLabel = dialog.postBalanceContainer.currencyAmount
    local currencyPerBooster = GetTamrielTomeCurrencyPerBooster()
    local postCurrencyAmount = currencyAmount + (data.quantity * currencyPerBooster)
    ZO_CurrencyControl_SetSimpleCurrency(postBalanceAmountLabel, CURT_TOME_POINTS, postCurrencyAmount)
end

local function CurrencyRedemptionDialog_SetupQuantityControls(dialog, data)
    local maxQuantity = GetPlayerStoredCurrencyAmount(CURT_TOME_POINT_CACHES)
    data.maxQuantity = maxQuantity

    -- Only show the quantity selection if the max quantity is greater than 1
    local quantityContainer = dialog.quantityContainer
    local quantityEnabled = maxQuantity > 1
    quantityContainer:SetHidden(not quantityEnabled)
    if quantityEnabled then
        quantityContainer.quantityMaxLabel:SetText(zo_strformat(SI_TAMRIEL_TOMES_CURRENCY_REDEMPTION_MAXIMUM_LABEL, maxQuantity))
        quantityContainer.quantityMaxLabel:SetHidden(false)
        quantityContainer.quantitySpinner:SetMinMax(MIN_CURRENCY_REDEMPTION_QUANTITY, maxQuantity)
    end

    local itemContainerControl = dialog:GetNamedChild("ItemContainer")
    local itemNameLabel = itemContainerControl:GetNamedChild("ItemName")
    local iconTextureControl = itemContainerControl:GetNamedChild("Icon")

    itemNameLabel:ClearAnchors()
    if quantityEnabled then
        itemNameLabel:SetAnchor(TOPLEFT, iconTextureControl, TOPRIGHT, 10)
    else
        itemNameLabel:SetAnchor(LEFT, iconTextureControl, RIGHT, 10)
    end
end

local function CurrencyRedemptionDialog_Setup(dialog, data)
    local quantity = MIN_CURRENCY_REDEMPTION_QUANTITY
    data.quantity = quantity
    dialog.quantityContainer.quantitySpinner:SetValue(quantity)

    local itemContainerControl = dialog:GetNamedChild("ItemContainer")
    local itemNameLabel = itemContainerControl:GetNamedChild("ItemName")
    local IS_PLURAL = false
    local currencyName = GetCurrencyName(CURT_TOME_POINT_CACHES, IS_PLURAL)
    itemNameLabel:SetText(currencyName)

    local iconTextureControl = itemContainerControl:GetNamedChild("Icon")
    local icon = GetCurrencyLootKeyboardIcon(CURT_TOME_POINT_CACHES)
    iconTextureControl:SetTexture(icon)

    CurrencyRedemptionDialog_SetupQuantityControls(dialog, data)
    CurrencyRedemptionDialog_UpdateBalanceControls(dialog, data)
end

function ZO_TamrielTomeCurrencyRedemptionDialog_Keyboard_OnInitialized(control)
    control.balanceContainer = control:GetNamedChild("BalanceContainer")
    control.postBalanceContainer = control:GetNamedChild("PostBalanceContainer")

    -- Item Quantity
    control.itemContainer = control:GetNamedChild("ItemContainer")
    control.quantityContainer = control.itemContainer:GetNamedChild("QuantityContainer")
    control.quantityContainer.quantityMaxLabel = control.quantityContainer:GetNamedChild("Maximum")

    local quantitySpinner = ZO_Spinner:New(control.quantityContainer:GetNamedChild("Spinner"))
    control.quantityContainer.quantitySpinner = quantitySpinner

    local quantityEditControl = quantitySpinner.display
    quantityEditControl:SetSelectAllOnFocus(true)

    local function OnQuantityChanged(quantity)
        local dialog = control:GetOwningWindow()
        dialog.data.quantity = quantity
        CurrencyRedemptionDialog_UpdateBalanceControls(dialog, dialog.data)
    end
    quantitySpinner:RegisterCallback("OnValueChanged", OnQuantityChanged)

    ZO_Dialogs_RegisterCustomDialog("TAMRIEL_TOME_CURRENCY_REDEMPTION_KEYBOARD",
        {
            customControl = control,
            setup = CurrencyRedemptionDialog_Setup,
            title =
            {
                text = function()
                    local IS_PLURAL = false
                    local currencyName = GetCurrencyName(CURT_TOME_POINT_CACHES, IS_PLURAL)
                    return zo_strformat(SI_TAMRIEL_TOMES_CURRENCY_REDEMPTION_TITLE, currencyName)
                end,
            },
            canQueue = true,
            buttons =
            {
                {
                    control = control:GetNamedChild("Confirm"),
                    text = SI_MARKET_CONFIRM_PURCHASE_KEYBIND_TEXT,
                    callback = function(dialog)
                         -- TODO Tamriel Tomes: Redeem cache
                    end,
                },

                {
                    control = control:GetNamedChild("Cancel"),
                    text = SI_DIALOG_DECLINE,
                },
            },
        }
    )
end

--------------
-- Tome Token Redemption Dialog
--------------

local function TokenRedemptionDialog_Setup(dialog, data)
    local currencyAmount = GetPlayerStoredCurrencyAmount(CURT_TOME_TOKENS)

    local currentBalanceAmountLabel = dialog.balanceContainer.currencyAmount
    ZO_CurrencyControl_SetSimpleCurrency(currentBalanceAmountLabel, CURT_TOME_TOKENS, currencyAmount)

    local postBalanceAmountLabel = dialog.postBalanceContainer.currencyAmount
    local currencyCost = GetCurrencyCostToUpgradeTamrielTome()
    local postCurrencyAmount = currencyAmount - currencyCost
    ZO_CurrencyControl_SetSimpleCurrency(postBalanceAmountLabel, CURT_TOME_TOKENS, postCurrencyAmount)
end

function ZO_TamrielTomeTokenRedemptionDialog_Keyboard_OnInitialized(control)
    control.balanceContainer = control:GetNamedChild("BalanceContainer")
    control.postBalanceContainer = control:GetNamedChild("PostBalanceContainer")

    ZO_Dialogs_RegisterCustomDialog("TAMRIEL_TOME_TOKEN_REDEMPTION_KEYBOARD",
        {
            customControl = control,
            setup = TokenRedemptionDialog_Setup,
            title =
            {
                text = GetString(SI_TAMRIEL_TOMES_TOKEN_REDEMPTION_TITLE),
            },
            mainText =
            {
                text = function()
                    local currencyCost = GetCurrencyCostToUpgradeTamrielTome()
                    local currencyString = ZO_Currency_FormatKeyboard(CURT_TOME_TOKENS, currencyCost, ZO_CURRENCY_FORMAT_WHITE_AMOUNT_WHITE_NAME)
                    return zo_strformat(SI_TAMRIEL_TOMES_TOKEN_REDEMPTION_TEXT, currencyString)
                end,
            },
            canQueue = true,
            buttons =
            {
                {
                    control = control:GetNamedChild("Confirm"),
                    text = SI_MARKET_CONFIRM_PURCHASE_KEYBIND_TEXT,
                    callback = function(dialog)
                         TryPurchaseTamrielTomePremiumPlus(dialog.data.tomeId)
                    end,
                },

                {
                    control = control:GetNamedChild("Cancel"),
                    text = SI_DIALOG_DECLINE,
                },
            },
        }
    )
end

--------------
-- Tome Insufficient Token Redemption Dialog
--------------

local function InsufficientTokenRedemptionDialog_Setup(dialog, data)
    local currencyAmount = GetPlayerStoredCurrencyAmount(CURT_TOME_TOKENS)
    local currentBalanceAmountLabel = dialog.balanceContainer.currencyAmount
    ZO_CurrencyControl_SetSimpleCurrency(currentBalanceAmountLabel, CURT_TOME_TOKENS, currencyAmount)
end

function ZO_TamrielTomeInsufficientTokenRedemptionDialog_Keyboard_OnInitialized(control)
    control.balanceContainer = control:GetNamedChild("BalanceContainer")

    ZO_Dialogs_RegisterCustomDialog("TAMRIEL_TOME_INSUFFICIENT_TOKEN_REDEMPTION_KEYBOARD",
        {
            customControl = control,
            setup = InsufficientTokenRedemptionDialog_Setup,
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
                    local currencyString = ZO_Currency_FormatKeyboard(CURT_TOME_TOKENS, currencyCost, ZO_CURRENCY_FORMAT_WHITE_AMOUNT_WHITE_NAME)
                    return zo_strformat(SI_TAMRIEL_TOMES_INSUFFICIENT_TOKENS_DIALOG_TEXT, currencyString)
                end,
            },
            canQueue = true,
            buttons =
            {
                {
                    control = control:GetNamedChild("Cancel"),
                    text = SI_DIALOG_CANCEL,
                },
            },
        }
    )
end
