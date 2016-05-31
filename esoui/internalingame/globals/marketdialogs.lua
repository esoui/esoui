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
                            ZO_Dialogs_ShowDialog("MARKET_PURCHASE_CONFIRMATION", {marketProductId = dialog.data.marketProductId })
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

local function MarketPurchaseConfirmationDialogSetup(dialog, data)
    local marketProductId = data.marketProductId
    local name, description, cost, discountedCost, discountPercent, icon, isNew, isFeatured = GetMarketProductInfo(marketProductId)

    -- set this up for the MARKET_PURCHASING dialog
    data.itemName = ZO_DEFAULT_ENABLED_COLOR:Colorize(name)
    data.hasItems = GetMarketProductNumItems(marketProductId) > 0 -- TODO: Consider consumable specific check

    dialog:GetNamedChild("ItemContainerItemName"):SetText(zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, name))

    local iconTextureControl = dialog:GetNamedChild("ItemContainerIcon")
    iconTextureControl:SetTexture(icon)

    local stackSize = 0
    if GetMarketProductType(marketProductId) == MARKET_PRODUCT_TYPE_ITEM then
        stackSize = GetMarketProductItemStackCount(marketProductId)
    end

    local stackCountControl = iconTextureControl:GetNamedChild("StackCount")
    stackCountControl:SetText(stackSize)
    stackCountControl:SetHidden(stackSize < 2)

    local finalCost = cost

    if discountPercent > 0 then
        finalCost = discountedCost
    end

    local costLabel = dialog:GetNamedChild("CostContainerItemCostAmount")
    costLabel:SetText(zo_strformat(SI_MARKET_LABEL_CURRENCY_FORMAT, ZO_CommaDelimitNumber(finalCost)))

    local currentBalance = dialog:GetNamedChild("BalanceContainerCurrentBalanceAmount")
    currentBalance:SetText(zo_strformat(SI_MARKET_LABEL_CURRENCY_FORMAT, ZO_CommaDelimitNumber(GetMarketCurrency())))
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
                [1] =
                {
                    control =   self:GetNamedChild("Confirm"),
                    text =      SI_MARKET_CONFIRM_PURCHASE_LABEL,
                    callback =  function(dialog)
                                    dialog.info.logPurchasedMarketId = true 
                                    -- the MARKET_PURCHASING dialog will be queued to show once this one is hidden
                                    ZO_Dialogs_ShowDialog("MARKET_PURCHASING", {itemName = dialog.data.itemName, hasItems = dialog.data.hasItems, marketProductId = dialog.data.marketProductId})
                                    BuyMarketProduct(dialog.data.marketProductId)
                                end,
                },
        
                [2] =
                {
                    control =   self:GetNamedChild("Cancel"),
                    text =      SI_DIALOG_DECLINE,
                }
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

local transactionCompleteTitleText = { text = SI_MARKET_PURCHASING_COMPLETE_TITLE }
local transactionFailedTitleText = { text = SI_MARKET_PURCHASING_FAILED_TITLE }
local transactionCompleteMainText = {text = "", align = TEXT_ALIGN_CENTER }
local LOADING_DELAY = 500 -- delay is in milliseconds
local SHOW_LOADING_ICON = true
local HIDE_LOADING_ICON = false
local function OnMarketPurchasingUpdate(dialog, currentTimeInSeconds)
    local timeInMilliseconds = currentTimeInSeconds * 1000
    local data = dialog.data
    if data.loadingDelayTime == nil then
        data.loadingDelayTime = timeInMilliseconds + LOADING_DELAY
    end

    local result = data.result
    local hasResult = result ~= nil
    local hideLogoutButton = true

    if hasResult then
        local titleText
        if result == MARKET_PURCHASE_RESULT_SUCCESS then
            local titleTextStringId = SI_MARKET_PURCHASE_SUCCESS_TEXT
            local instantUnlockType = dialog.data.marketProductId and GetMarketProductInstantUnlockType(dialog.data.marketProductId) or MARKET_INSTANT_UNLOCK_NONE

            if IsMarketInstantUnlockServiceToken(instantUnlockType) then
                titleTextStringId = SI_MARKET_PURCHASE_SUCCESS_TEXT_WITH_TOKEN_USAGE
                hideLogoutButton = false
            end

            titleText = transactionCompleteTitleText
            transactionCompleteMainText.text = zo_strformat(titleTextStringId, dialog.data.itemName)
        else
            titleText = transactionFailedTitleText
            transactionCompleteMainText.text = GetString("SI_MARKETPURCHASABLERESULT", result)
        end
        
        ZO_Dialogs_UpdateDialogTitleText(dialog, titleText)
        ZO_Dialogs_SetDialogLoadingIcon(dialog:GetNamedChild("Loading"), dialog:GetNamedChild("Text"), HIDE_LOADING_ICON)
    else
        if timeInMilliseconds > data.loadingDelayTime then
            transactionCompleteMainText.text = zo_strformat(SI_MARKET_PURCHASING_TEXT, dialog.data.itemName)
            ZO_Dialogs_SetDialogLoadingIcon(dialog:GetNamedChild("Loading"), dialog:GetNamedChild("Text"), SHOW_LOADING_ICON)
        end
    end

    ZO_Dialogs_UpdateDialogMainText(dialog, transactionCompleteMainText)

    local buttonControl = dialog:GetNamedChild("Confirm")
    buttonControl:SetHidden(not hasResult)

    local logoutControl = dialog:GetNamedChild("Logout")
    logoutControl:SetHidden(hideLogoutButton)
    logoutControl:SetEnabled(not hideLogoutButton)
end

local function MarketPurchasingDialogSetup(dialog, data)
    data.result = nil
    data.loadingDelayTime = nil
    EVENT_MANAGER:RegisterForEvent("MARKET_PURCHASING", EVENT_MARKET_PURCHASE_RESULT, function(eventId, ...) OnMarketPurchaseResult(data, ...) end)
    dialog:GetNamedChild("Confirm"):SetHidden(true)
    dialog:GetNamedChild("Logout"):SetHidden(true)
    dialog:GetNamedChild("Logout"):SetEnabled(false)
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
                -- Logout 
                {
                    control =   self:GetNamedChild("Logout"),
                    text =      SI_MARKET_LOG_OUT_TO_CHARACTER_SELECT_KEYBIND_LABEL,
                    keybind =   "DIALOG_RESET",
                    callback =  function(dialog)
                                    Logout()
                                end,
                },
                {
                    control =   self:GetNamedChild("Confirm"),
                    text =      SI_DIALOG_EXIT,
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