local function LogPurchaseClose(dialog)
    if not dialog.info.dontLogClose then
        if dialog.info.logPurchasedMarketId then
            OnMarketEndPurchase(dialog.data.marketProductId)
        else
            OnMarketEndPurchase()
        end
    end
    dialog.info.dontLogClose = false
    dialog.info.logPurchasedMarketId = false
end

ESO_Dialogs["MARKET_CROWN_STORE_PURCHASE_ERROR_CONTINUE"] = 
{
    finishedCallback = LogPurchaseClose,
    title =
    {
        text = SI_MARKET_PURCHASE_ERROR_TITLE_FORMATTER
    },
    mainText =
    {
        text = SI_MARKET_PURCHASE_ERROR_TEXT_FORMATTER
    },
    buttons =
    {
        [1] =
        {
            text = SI_MARKET_PURCHASE_ERROR_CONTINUE,
            callback =  function(dialog)
                            dialog.info.dontLogClose = true
                            -- the MARKET_PURCHASE_CONFIRMATION dialog will be queued to show once this one is hidden
                            ZO_Dialogs_ShowDialog("MARKET_PURCHASE_CONFIRMATION", dialog.data)
                        end,
            keybind = "DIALOG_PRIMARY",
        },
        [2] =
        {
            text = SI_DIALOG_EXIT,
            keybind = "DIALOG_NEGATIVE",
        },
    },
}

ESO_Dialogs["MARKET_CROWN_STORE_PURCHASE_ERROR_PURCHASE_CROWNS"] =
{
    finishedCallback = LogPurchaseClose,
    title =
    {
        text = SI_MARKET_PURCHASE_ERROR_TITLE_FORMATTER
    },
    mainText =
    {
        text = SI_MARKET_PURCHASE_ERROR_TEXT_FORMATTER
    },
    buttons =
    {
        [1] =
        {
            text = SI_MARKET_INSUFFICIENT_FUNDS_CONFIRM_BUTTON_TEXT,
            callback = ZO_MarketDialogs_Shared_OpenURLByType,
            keybind = "DIALOG_PRIMARY",
        },
        [2] =
        {
            text = SI_DIALOG_EXIT,
            keybind = "DIALOG_NEGATIVE",
        },
    },
}

ESO_Dialogs["MARKET_CROWN_STORE_PURCHASE_ERROR_EXIT"] =
{
    finishedCallback = LogPurchaseClose,
    title =
    {
        text = SI_MARKET_PURCHASE_ERROR_TITLE_FORMATTER
    },
    mainText =
    {
        text = SI_MARKET_PURCHASE_ERROR_TEXT_FORMATTER
    },
    buttons =
    {
        {
            text = SI_DIALOG_EXIT,
        },
    },
}

local CURRENCY_ICON_SIZE = 24
local function MarketPurchaseConfirmationDialogSetup(dialog, data)
    local marketProductId = data.marketProductId
    local presentationIndex = data.presentationIndex
    local name, description, icon, isNew, isFeatured = GetMarketProductInfo(marketProductId)

    -- set this up for the MARKET_PURCHASING dialog
    data.itemName = ZO_DEFAULT_ENABLED_COLOR:Colorize(name)
    data.hasItems = GetMarketProductNumItems(marketProductId) > 0 -- TODO: Consider consumable specific check

    dialog:GetNamedChild("ItemContainerItemName"):SetText(zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, name))

    local iconTextureControl = dialog:GetNamedChild("ItemContainerIcon")
    iconTextureControl:SetTexture(icon)

    local stackSize = GetMarketProductStackCount(marketProductId)

    local stackCountControl = iconTextureControl:GetNamedChild("StackCount")
    stackCountControl:SetText(stackSize)
    stackCountControl:SetHidden(stackSize < 2)

    local currencyType, cost, hasDiscount, costAfterDiscount, discountPercent = GetMarketProductPricingByPresentation(marketProductId, presentationIndex)

    local finalCost = cost
    if hasDiscount then
        finalCost = costAfterDiscount
    end

    local currencyIcon = ZO_Currency_GetPlatformFormattedCurrencyIcon(ZO_Currency_MarketCurrencyToUICurrency(currencyType), CURRENCY_ICON_SIZE)

    local costLabel = dialog:GetNamedChild("CostContainerItemCostAmount")
    local currencyString = zo_strformat(SI_CURRENCY_AMOUNT_WITH_ICON, ZO_CommaDelimitNumber(finalCost), currencyIcon)
    costLabel:SetText(currencyString)

    local currentBalance = dialog:GetNamedChild("BalanceContainerCurrentBalanceAmount")
    currencyString = zo_strformat(SI_CURRENCY_AMOUNT_WITH_ICON, ZO_CommaDelimitNumber(GetPlayerMarketCurrency(currencyType)), currencyIcon)
    currentBalance:SetText(currencyString)
end

function ZO_MarketPurchaseConfirmationDialog_OnInitialized(self)
    ZO_Dialogs_RegisterCustomDialog(
        "MARKET_PURCHASE_CONFIRMATION",
        {
            customControl = self,
            finishedCallback = LogPurchaseClose,
            setup = MarketPurchaseConfirmationDialogSetup,
            title =
            {
                text = SI_MARKET_CONFIRM_PURCHASE_TITLE,
            },
            canQueue = true,
            buttons =
            {
                {
                    control =   self:GetNamedChild("Confirm"),
                    text =      SI_MARKET_CONFIRM_PURCHASE_LABEL,
                    callback =  function(dialog)
                                    dialog.info.logPurchasedMarketId = true
                                    local marketProductId = dialog.data.marketProductId
                                    local presentationIndex = dialog.data.presentationIndex
                                    -- the MARKET_PURCHASING dialog will be queued to show once this one is hidden
                                    ZO_Dialogs_ShowDialog("MARKET_PURCHASING", {itemName = dialog.data.itemName, hasItems = dialog.data.hasItems, marketProductId = marketProductId, presentationIndex = presentationIndex})
                                    BuyMarketProduct(marketProductId, presentationIndex)
                                end,
                },

                {
                    control =   self:GetNamedChild("Cancel"),
                    text =      SI_DIALOG_DECLINE,
                },
            }
        }
    )
end

local function OnMarketPurchaseResult(data, result, tutorialTrigger)
    EVENT_MANAGER:UnregisterForEvent("MARKET_PURCHASING", EVENT_MARKET_PURCHASE_RESULT)
    data.result = result
    
    if tutorialTrigger ~= TUTORIAL_TRIGGER_NONE then
        data.tutorialTrigger = tutorialTrigger
    end
end

local TRANSACTION_COMPLETE_TITLE_TEXT = { text = SI_MARKET_PURCHASING_COMPLETE_TITLE }
local TRANSACTION_FAILED_TITLE_TEXT = { text = SI_MARKET_PURCHASING_FAILED_TITLE }
local g_transactionCompleteMainText = {text = "", align = TEXT_ALIGN_CENTER }
local LOADING_DELAY = 500 -- delay is in milliseconds
local SHOW_LOADING_ICON = true
local HIDE_LOADING_ICON = false
local function OnMarketPurchasingUpdate(dialog, currentTimeInSeconds)
    local timeInMilliseconds = currentTimeInSeconds * 1000
    local data = dialog.data
    if data.loadingDelayTime == nil then
        data.loadingDelayTime = timeInMilliseconds + LOADING_DELAY
    end

    local marketProductId = dialog.data.marketProductId

    local result = data.result
    local hasResult = result ~= nil
    local hideUseProductButton = true
    local enableUseProductButton = false
    local useProductControl = dialog:GetNamedChild("UseProduct")

    if hasResult then
        local titleText
        if result == MARKET_PURCHASE_RESULT_SUCCESS then
            titleText = TRANSACTION_COMPLETE_TITLE_TEXT

            local useProductInfo = ZO_Market_Shared.GetUseProductInfo(marketProductId)
            local stackCount = GetMarketProductStackCount(marketProductId)
            if useProductInfo then
                hideUseProductButton = useProductInfo.visible and not useProductInfo.visible()
                enableUseProductButton = not useProductInfo.enabled or useProductInfo.enabled()
                g_transactionCompleteMainText.text = zo_strformat(useProductInfo.transactionCompleteText, dialog.data.itemName, stackCount)
                useProductControl:SetText(useProductInfo.buttonText)
            else
                if stackCount > 1 then
                    g_transactionCompleteMainText.text = zo_strformat(SI_MARKET_PURCHASE_SUCCESS_TEXT_WITH_QUANTITY, dialog.data.itemName, stackCount)
                else
                    if GetMarketProductNumCollectibles(marketProductId) > 0 then
                        g_transactionCompleteMainText.text = zo_strformat(SI_MARKET_PURCHASE_SUCCESS_TEXT_WITH_COLLECTIBLE, dialog.data.itemName)
                    else
                        g_transactionCompleteMainText.text = zo_strformat(SI_MARKET_PURCHASE_SUCCESS_TEXT, dialog.data.itemName)
                    end
                end
            end
        else
            titleText = TRANSACTION_FAILED_TITLE_TEXT
            g_transactionCompleteMainText.text = GetString("SI_MARKETPURCHASABLERESULT", result)
        end

        ZO_Dialogs_UpdateDialogTitleText(dialog, titleText)
        ZO_Dialogs_SetDialogLoadingIcon(dialog:GetNamedChild("Loading"), dialog:GetNamedChild("Text"), HIDE_LOADING_ICON)
    else
        if timeInMilliseconds > data.loadingDelayTime then
            g_transactionCompleteMainText.text = zo_strformat(SI_MARKET_PURCHASING_TEXT, dialog.data.itemName)
            ZO_Dialogs_SetDialogLoadingIcon(dialog:GetNamedChild("Loading"), dialog:GetNamedChild("Text"), SHOW_LOADING_ICON)
        end
    end

    ZO_Dialogs_UpdateDialogMainText(dialog, g_transactionCompleteMainText)

    local buttonControl = dialog:GetNamedChild("Confirm")
    buttonControl:SetHidden(not hasResult)

    useProductControl:SetHidden(hideUseProductButton)
    useProductControl:SetEnabled(enableUseProductButton)
end

local function MarketPurchasingDialogSetup(dialog, data)
    data.result = nil
    data.loadingDelayTime = nil
    EVENT_MANAGER:RegisterForEvent("MARKET_PURCHASING", EVENT_MARKET_PURCHASE_RESULT, function(eventId, ...) OnMarketPurchaseResult(data, ...) end)
    dialog:GetNamedChild("Confirm"):SetHidden(true)
    dialog:GetNamedChild("UseProduct"):SetHidden(true)
    dialog:GetNamedChild("UseProduct"):SetEnabled(false)
end

function ZO_MarketPurchasingDialog_OnInitialized(self)
    ZO_Dialogs_RegisterCustomDialog(
        "MARKET_PURCHASING",
        {
            customControl = self,
            setup = MarketPurchasingDialogSetup,
            updateFn = OnMarketPurchasingUpdate,
            title =
            {
                text = SI_MARKET_PURCHASING_TITLE,
            },
            mainText =
            {
                text = "",
                align = TEXT_ALIGN_CENTER,
            },
            canQueue = true,
            mustChoose = true,
            buttons =
            {
                -- Use Product 
                {
                    control =   self:GetNamedChild("UseProduct"),
                    keybind =   "DIALOG_RESET",
                    callback =  function(dialog)
                                    ZO_Market_Shared.GoToUseProductLocation(dialog.data.marketProductId)
                                end,
                },
                {
                    control =   self:GetNamedChild("Confirm"),
                    text =      SI_MARKET_CONFIRM_PURCHASE_BACK_KEYBIND_LABEL,
                    keybind =   "DIALOG_PRIMARY",
                    callback =  function(dialog)
                                    -- Show tutorials from a purchased item first before showing the consumable tutorial
                                    if dialog.data.tutorialTrigger then
                                        MARKET:ShowTutorial(dialog.data.tutorialTrigger)
                                    end
                                    
                                    if dialog.data.result == MARKET_PURCHASE_RESULT_SUCCESS and dialog.data.hasItems then
                                        MARKET:ShowTutorial(TUTORIAL_TRIGGER_CROWN_CONSUMABLE_PURCHASED)
                                    end
                                end,
                },
            },
        }
    )
end