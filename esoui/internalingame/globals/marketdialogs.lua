ESO_Dialogs["MARKET_INSUFFICIENT_CROWNS"] =
{
    title =
    {
        text = SI_MARKET_INSUFFICIENT_FUNDS_TITLE
    },
    mainText =
    {
        text = SI_MARKET_INSUFFICIENT_FUNDS_TEXT
    },
    buttons =
    {
        {
            text = SI_DIALOG_EXIT,
            keybind = "DIALOG_NEGATIVE",
        },
    },
}

ESO_Dialogs["MARKET_INSUFFICIENT_CROWNS_WITH_LINK"] =
{
    title =
    {
        text = SI_MARKET_INSUFFICIENT_FUNDS_TITLE
    },
    mainText =
    {
        text = SI_MARKET_INSUFFICIENT_FUNDS_TEXT_WITH_LINK
    },
    buttons =
    {
        [1] =
        {
            text = SI_MARKET_INSUFFICIENT_FUNDS_CONFIRM_BUTTON_TEXT,
            callback = ZO_MarketDialogs_Shared_OpenURL,
            keybind = "DIALOG_PRIMARY",
        },
        [2] =
        {
            text = SI_DIALOG_EXIT,
            keybind = "DIALOG_NEGATIVE",
        },
    },
}

ESO_Dialogs["MARKET_INVENTORY_FULL"] =
{
    title =
    {
        text = SI_MARKET_INVENTORY_FULL_TITLE,
    },
    mainText =
    {
        text = SI_MARKET_INVENTORY_FULL_TEXT,
    },
    buttons =
    {
        {
            text = SI_DIALOG_EXIT,
        },
    },
}

ESO_Dialogs["MARKET_UNABLE_TO_PURCHASE"] =
{
    title =
    {
        text = SI_MARKET_UNABLE_TO_PURCHASE_TITLE,
    },
    mainText =
    {
        text = SI_MARKET_UNABLE_TO_PURCHASE_TEXT,
    },
    buttons =
    {
        {
            text = SI_DIALOG_EXIT,
        },
    },
}

ESO_Dialogs["MARKET_PARTS_UNLOCKED"] =
{
    title =
    {
        text = SI_MARKET_BUNDLE_PARTS_UNLOCKED_TITLE
    },
    mainText =
    {
        text = SI_MARKET_BUNDLE_PARTS_UNLOCKED_TEXT
    },
    buttons =
    {
        {
            text = SI_MARKET_BUNDLE_PARTS_UNLOCKED_CONTINUE,
            callback =  function(dialog)
                            -- the MARKET_PURCHASE_CONFIRMATION dialog will be queued to show once this one is hidden
                            ZO_Dialogs_ShowDialog("MARKET_PURCHASE_CONFIRMATION", {marketProductId = dialog.data.marketProductId })
                        end,
        },
        {
            text = SI_DIALOG_EXIT,
        },
    },
}

ESO_Dialogs["MARKET_BUNDLE_PARTS_OWNED"] =
{
    title =
    {
        text = SI_MARKET_BUNDLE_PARTS_OWNED_TITLE
    },
    mainText =
    {
        text = SI_MARKET_BUNDLE_PARTS_OWNED_TEXT
    },
    buttons =
    {
        [1] =
        {
            text = SI_MARKET_BUNDLE_PARTS_OWNED_CONTINUE,
            callback =  function(dialog)
                            -- the MARKET_PURCHASE_CONFIRMATION dialog will be queued to show once this one is hidden
                            ZO_Dialogs_ShowDialog("MARKET_PURCHASE_CONFIRMATION", {marketProductId = dialog.data.marketProductId })
                        end,
        },
        [2] =
        {
            text = SI_DIALOG_EXIT,
        },
    },
}

ESO_Dialogs["MARKET_CONFIRM_OPEN_URL"] =
{
    title =
    {
        text = SI_CONFIRM_OPEN_URL_TITLE,
    },
    mainText =
    {
        text = SI_CONFIRM_OPEN_URL_TEXT,
    },
    buttons =
    {
        [1] =
        {
            text = SI_URL_DIALOG_OPEN,
            callback = ZO_MarketDialogs_Shared_OpenURL,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    }
}

local function MarketPurchaseConfirmationDialogSetup(dialog, data)
    local marketProductId = data.marketProductId
    local name, description, cost, discountedCost, discountPercent, icon, isNew, isFeatured = GetMarketProductInfo(marketProductId)
    local numCollectibles = GetMarketProductNumCollectibles(marketProductId)
    local numItems = GetMarketProductNumItems(marketProductId)
    local isBundle = numCollectibles + numItems > 1

    -- set this up for the MARKET_PURCHASING dialog
    data.itemName = ZO_DEFAULT_ENABLED_COLOR:Colorize(name)
    data.hasItems = numItems > 0

    dialog:GetNamedChild("ItemContainerItemName"):SetText(zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, name))
    
    -- Use the icon of the Item or Collectible if there is only one attached
    local productIcon = icon
    local stackSize = 0
    if not isBundle then
        if numItems == 1 then
            local icon, name, quality, requiredLevel, amount = select(2, GetMarketProductItemInfo(marketProductId, 1))
            productIcon = icon
            stackSize = amount
        elseif numCollectibles == 1 then
            productIcon = select(2, GetMarketProductCollectibleInfo(marketProductId, 1))
        end
    end

    local iconTextureControl = dialog:GetNamedChild("ItemContainerIcon")
    iconTextureControl:SetTexture(productIcon)
    local stackCountControl = iconTextureControl:GetNamedChild("StackCount")
    stackCountControl:SetText(stackSize)
    stackCountControl:SetHidden(stackSize < 2)

    local finalCost = cost

    if discountPercent > 0 then
        finalCost = discountedCost
    end

    local cost = dialog:GetNamedChild("CostContainerItemCostAmount")
    cost:SetText(zo_strformat(SI_MARKET_LABEL_CURRENCY_FORMAT, ZO_CommaDelimitNumber(finalCost)))

    local currentBalance = dialog:GetNamedChild("BalanceContainerCurrentBalanceAmount")
    currentBalance:SetText(zo_strformat(SI_MARKET_LABEL_CURRENCY_FORMAT, ZO_CommaDelimitNumber(GetMarketCurrency())))
end

function ZO_MarketPurchaseConfirmationDialog_OnInitialized(self)
    ZO_Dialogs_RegisterCustomDialog(
        "MARKET_PURCHASE_CONFIRMATION",
        {
            customControl = self,
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
                                    -- the MARKET_PURCHASING dialog will be queued to show once this one is hidden
                                    ZO_Dialogs_ShowDialog("MARKET_PURCHASING", {itemName = dialog.data.itemName, hasItems = dialog.data.hasItems})
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

local function OnMarketPurchaseResult(data, result)
    EVENT_MANAGER:UnregisterForEvent("MARKET_PURCHASING", EVENT_MARKET_PURCHASE_RESULT)
    data.result = result
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
    if hasResult then
        local titleText
        if result == MARKET_PURCHASE_RESULT_SUCCESS then
            titleText = transactionCompleteTitleText
            transactionCompleteMainText.text = zo_strformat(SI_MARKET_PURCHASE_SUCCESS_TEXT, dialog.data.itemName)
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
end

local function MarketPurchasingDialogSetup(dialog, data)
    data.result = nil
    data.loadingDelayTime = nil
    EVENT_MANAGER:RegisterForEvent("MARKET_PURCHASING", EVENT_MARKET_PURCHASE_RESULT, function(eventId, ...) OnMarketPurchaseResult(data, ...) end)
    dialog:GetNamedChild("Confirm"):SetHidden(true)
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
                [1] =
                {
                    control =   self:GetNamedChild("Confirm"),
                    text =      SI_DIALOG_EXIT,
                    callback =  function(dialog)
                                    if dialog.data.result == MARKET_PURCHASE_RESULT_SUCCESS and dialog.data.hasItems then
                                        MARKET:ShowTutorial(TUTORIAL_TRIGGER_CROWN_CONSUMABLE_PURCHASED)
                                    end
                                end,
                },
            },
        }
    )
end