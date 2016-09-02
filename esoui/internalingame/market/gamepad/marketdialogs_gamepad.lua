local FLOW_UNINITIALIZED = 0
local FLOW_WARNING = 1
local FLOW_CONFIRMATION = 2
local FLOW_PURCHASING = 3
local FLOW_SUCCESS = 4
local FLOW_FAILED = 5

local DIALOG_FLOW = 
{
    [FLOW_WARNING] = "GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_CONTINUE",
    [FLOW_CONFIRMATION] = "GAMEPAD_MARKET_PURCHASE_CONFIRMATION",
    [FLOW_PURCHASING] = "GAMEPAD_MARKET_PURCHASING",
    [FLOW_SUCCESS] = "GAMEPAD_MARKET_PURCHASE_SUCCESS",
    [FLOW_FAILED] = "GAMEPAD_MARKET_PURCHASE_FAILED",
}

ZO_GAMEPAD_MARKET_CURRENCY_OPTIONS =
{
    showTooltips = false,
    useShortFormat = false,
    font = "ZoFontGamepadHeaderDataValue",
    iconSide = RIGHT,
    iconSize = 28,
}

ZO_GAMEPAD_MARKET_PURCHASE_SCENE_NAME = "gamepad_market_purchase"

local g_buyCrownsData
local g_buyCrownsTextParams

local function GetAvailableCurrencyHeaderData(marketCurrencyType)
    return {
                value = function(control)
                    ZO_CurrencyControl_SetSimpleCurrency(control, ZO_Currency_MarketCurrencyToUICurrency(marketCurrencyType), GetPlayerMarketCurrency(marketCurrencyType), ZO_GAMEPAD_MARKET_CURRENCY_OPTIONS)
                    return true
                end,
                header = GetString(SI_GAMEPAD_MARKET_FUNDS_LABEL),
            }
end
local function GetProductCostHeaderData(cost, marketCurrencyType)
    return  {
                value = function(control)
                    ZO_CurrencyControl_SetSimpleCurrency(control, ZO_Currency_MarketCurrencyToUICurrency(marketCurrencyType), cost, ZO_GAMEPAD_MARKET_CURRENCY_OPTIONS)
                    return true
                end,
                header = GetString(SI_GAMEPAD_MARKET_CONFIRM_PURCHASE_COST_LABEL),
            }
end

ZO_GamepadMarketPurchaseManager = ZO_Object:Subclass()

function ZO_GamepadMarketPurchaseManager:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_GamepadMarketPurchaseManager:Initialize()
    self.marketPurchaseScene = ZO_RemoteScene:New(ZO_GAMEPAD_MARKET_PURCHASE_SCENE_NAME, SCENE_MANAGER)
    self.marketPurchaseScene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWN then
            ZO_Dialogs_ShowGamepadDialog(DIALOG_FLOW[FLOW_CONFIRMATION])
        end
    end)

    self:ResetState()

    local function EndPurchase(_, isNoChoice)
        self:EndPurchase(isNoChoice)
    end

    local IS_NO_CHOICE = true
    local function EndPurchaseNoChoice(dialog)
        EndPurchase(dialog, IS_NO_CHOICE)
    end

    local function EndPurchaseAndClearTooltip(_, isNoChoice)
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_DIALOG_TOOLTIP)
        self:EndPurchase(isNoChoice)
    end

    local function EndPurchaseAndClearTooltipNoChoice(dialog)
        EndPurchaseAndClearTooltip(dialog, IS_NO_CHOICE)
    end

    local defaultMarketBackButton = 
    {
        text = SI_DIALOG_EXIT,
        callback = EndPurchase,
        keybind = "DIALOG_NEGATIVE"
    }

    local insufficientFundsButtons = {}
    local buyCrownsButtons = {}
    local buyPlusButtons = {}
    
    local consoleStoreName
    local buyCrownsMainText
    local buyPlusMainText

    local uiPlatform = GetUIPlatform()
    if uiPlatform == UI_PLATFORM_PS4 then
        consoleStoreName = GetString(SI_GAMEPAD_MARKET_PLAYSTATION_STORE)
    elseif uiPlatform == UI_PLATFORM_XBOX then
        consoleStoreName = GetString(SI_GAMEPAD_MARKET_XBOX_STORE)
    else -- PC Gamepad insufficient crowns and buy crowns dialog data
        local openURLButton = 
        {
            text = SI_MARKET_INSUFFICIENT_FUNDS_CONFIRM_BUTTON_TEXT,
            callback =  function(...)
                            ZO_MarketDialogs_Shared_OpenURLByType(...)
                            EndPurchase()
                        end,
        }

        insufficientFundsButtons[1] = openURLButton
        buyCrownsButtons[1] = openURLButton

        buyCrownsMainText = SI_CONFIRM_OPEN_URL_TEXT
        g_buyCrownsData = ZO_BUY_CROWNS_URL_TYPE
        g_buyCrownsTextParams = ZO_BUY_CROWNS_FRONT_FACING_ADDRESS

        buyPlusMainText = nil --no plans for this currently
    end

    if consoleStoreName then -- PS4/XBox insufficient crowns and buy crowns dialog data
        buyCrownsMainText = SI_GAMEPAD_MARKET_BUY_CROWNS_TEXT_LABEL
        g_buyCrownsTextParams = { mainTextParams = { ZO_PrefixIconNameFormatter("crowns", GetString(SI_CURRENCY_CROWN)), consoleStoreName } }
        
        local OpenConsoleStoreToPurchaseCrowns = function()
            ShowConsoleESOCrownPacksUI()
            self:EndPurchase()
        end

        insufficientFundsButtons[1] =
        {
            text = zo_strformat(SI_GAMEPAD_MARKET_OPEN_FIRST_PARTY_STORE_KEYBIND, consoleStoreName),
            callback = OpenConsoleStoreToPurchaseCrowns
        }

        buyCrownsButtons[1] =
        {
            text = zo_strformat(SI_GAMEPAD_MARKET_OPEN_FIRST_PARTY_STORE_KEYBIND, consoleStoreName),
            callback = OpenConsoleStoreToPurchaseCrowns
        }

        local OpenConsoleStoreToBuySubscription = function()
            ShowConsoleESOPlusSubscriptionUI()
            self:EndPurchase()
        end

        buyPlusMainText = SI_GAMEPAD_MARKET_BUY_PLUS_TEXT_CONSOLE

        table.insert(buyPlusButtons,
        {
            text = SI_GAMEPAD_MARKET_BUY_PLUS_DIALOG_KEYBIND_LABEL,
            callback = OpenConsoleStoreToBuySubscription,
        })
    end

    insufficientFundsButtons[2] = defaultMarketBackButton
    buyCrownsButtons[2] = defaultMarketBackButton
    table.insert(buyPlusButtons, defaultMarketBackButton)

    ESO_Dialogs["GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_CONTINUE"] = 
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
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
                callback = function() self.doMoveToNextFlowPosition = true end
            },
            [2] =
            {
                text = SI_DIALOG_EXIT,
                callback = EndPurchase
            },
        },

        finishedCallback = function() 
                                if not self.doMoveToNextFlowPosition then
                                    OnMarketEndPurchase()
                                end
                                self:MoveToNextFlowPosition() 
                           end
    }

    ESO_Dialogs["GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_PURCHASE_CROWNS"] =
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_MARKET_PURCHASE_ERROR_TITLE_FORMATTER
        },
        mainText =
        {
            text = SI_MARKET_PURCHASE_ERROR_TEXT_FORMATTER
        },
        buttons = insufficientFundsButtons,
        noChoiceCallback = EndPurchaseNoChoice,
        finishedCallback =  function()
                                OnMarketEndPurchase()
                            end,
    }

    ESO_Dialogs["GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_EXIT"] =
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_MARKET_PURCHASE_ERROR_TITLE_FORMATTER
        },
        mainText =
        {
            text = SI_MARKET_PURCHASE_ERROR_TEXT_FORMATTER
        },
        buttons = { defaultMarketBackButton },
        noChoiceCallback = EndPurchaseNoChoice,
        finishedCallback =  function()
                                OnMarketEndPurchase()
                            end,
        setup = function(dialog, ...)
                    dialog.setupFunc(dialog, ...)
                end,
    }

    ZO_Dialogs_RegisterCustomDialog(DIALOG_FLOW[FLOW_CONFIRMATION],
    {
        setup = function(...) self:MarketPurchaseConfirmationDialogSetup(...) end,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.STATIC_LIST,
        },
        title =
        {
            text = SI_MARKET_CONFIRM_PURCHASE_TITLE,
        },
        canQueue = true,
        itemInfo = {}, --we'll generate the entries on setup
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_MARKET_CONFIRM_PURCHASE_BACK_KEYBIND_LABEL,
                callback = function(dialog, isNoChoice)
                                OnMarketEndPurchase()
                                self:EndPurchase(isNoChoice)
                           end,
            },
            {
                keybind = "DIALOG_SECONDARY",
                text = SI_GAMEPAD_MARKET_CONFIRM_PURCHASE_BUY_NOW_LABEL,
                callback =  function(dialog)
                                OnMarketEndPurchase(self.marketProductId)
                                self.doMoveToNextFlowPosition = true
                            end,
            },
        },
        mustChoose = true,
        finishedCallback =  function(dialog)
                                self:MoveToNextFlowPosition()
                            end,
    })

    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_MARKET_BUY_CROWNS",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_MARKET_BUY_CROWNS
        },
        mainText =
        {
            text = buyCrownsMainText
        },
        buttons = buyCrownsButtons
    })

    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_MARKET_BUY_PLUS",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_GAMEPAD_MARKET_BUY_PLUS_TITLE
        },
        mainText =
        {
            text = buyPlusMainText
        },
        buttons = buyPlusButtons
    })

    local function OnMarketPurchaseResult(_, result, tutorialTrigger)
        EVENT_MANAGER:UnregisterForEvent("GAMEPAD_MARKET_PURCHASING", EVENT_MARKET_PURCHASE_RESULT)
        self.result = result

        if tutorialTrigger ~= TUTORIAL_TRIGGER_NONE then
            self.triggerTutorialOnPurchase = tutorialTrigger
        end
    end

    local LOADING_DELAY = 500 -- delay is in milliseconds
    local function OnMarketPurchasingUpdate(dialog, currentTimeInSeconds)
        local result = self.result
        local hasResult = result ~= nil
        
        if hasResult then
            if result == MARKET_PURCHASE_RESULT_SUCCESS then
                local useProductInfo = self.marketProduct:GetUseProductInfo()
                if useProductInfo then
                    self.purchaseResultText = zo_strformat(useProductInfo.transactionCompleteText, self.itemName, self.stackCount)
                else
                    if self.stackCount > 1 then
                        self.purchaseResultText = zo_strformat(SI_MARKET_PURCHASE_SUCCESS_TEXT_WITH_QUANTITY, self.itemName, self.stackCount)
                    else
                        if self.marketProduct:GetNumAttachedCollectibles() > 0 then
                            self.purchaseResultText = zo_strformat(SI_MARKET_PURCHASE_SUCCESS_TEXT_WITH_COLLECTIBLE, self.itemName)
                        else
                            self.purchaseResultText = zo_strformat(SI_MARKET_PURCHASE_SUCCESS_TEXT, self.itemName)
                        end
                    end
                end
            else
                self.purchaseFailed = true
                self.purchaseFailedText = GetString("SI_MARKETPURCHASABLERESULT", result)
            end

            zo_callLater(function()
                self.doMoveToNextFlowPosition = true
                ZO_Dialogs_ReleaseDialogOnButtonPress(DIALOG_FLOW[FLOW_PURCHASING])
            end, LOADING_DELAY) -- prevent jarring transition
        end
    end

    local function MarketPurchasingDialogSetup(dialog, data)
        dialog:setupFunc()
        EVENT_MANAGER:RegisterForEvent("GAMEPAD_MARKET_PURCHASING", EVENT_MARKET_PURCHASE_RESULT, function(eventId, ...) OnMarketPurchaseResult(data, ...) end)
        BuyMarketProduct(self.marketProduct:GetId(), self.marketProduct:GetPresentationIndex())
    end

    ZO_Dialogs_RegisterCustomDialog(DIALOG_FLOW[FLOW_PURCHASING], 
    {
        setup = MarketPurchasingDialogSetup,
        updateFn = OnMarketPurchasingUpdate,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.COOLDOWN,
        },
        title =
        {
            text = SI_MARKET_PURCHASING_TITLE,
        },
        mainText =
        {
            text = "",
        },
        loading = 
        {
            text =  function()
                        if self.stackCount > 1 then
                            return zo_strformat(SI_MARKET_PURCHASING_TEXT_WITH_QUANTITY, self.itemName, self.stackCount)
                        else
                            return zo_strformat(SI_MARKET_PURCHASING_TEXT, self.itemName)
                        end
                    end,
        },
        canQueue = true,
        mustChoose = true,
        finishedCallback = function() self:MoveToNextFlowPosition() end
    })

    ZO_Dialogs_RegisterCustomDialog(DIALOG_FLOW[FLOW_SUCCESS], 
    {
        setup = function(dialog)
            if self.onPurchaseSuccessCallback then
                self.onPurchaseSuccessCallback()
                self.onPurchaseSuccessCallback = nil
            end

            local displayData =
            {
                data1 = GetAvailableCurrencyHeaderData(self.productCostCurrencyType),
            }

            dialog.data = displayData
            dialog.setupFunc(dialog, displayData)
        end,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = GetString(SI_MARKET_PURCHASING_COMPLETE_TITLE)
        },
        mainText =
        {
            text = function()
                return self.purchaseResultText
            end
        },
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_MARKET_BACK_TO_STORE_KEYBIND_LABEL,
                callback = EndPurchase,
            },
            {
                keybind = "DIALOG_TERTIARY",
                text = function(dialog)
                    local useProductInfo = self.marketProduct:GetUseProductInfo()
                    return useProductInfo.buttonText
                end,
                visible = function(dialog)
                    if self.result and self.result == MARKET_PURCHASE_RESULT_SUCCESS then
                        return self.marketProduct:HasUseProductInfo()
                    else
                        return false
                    end
                end,
                callback = function()
                    -- since we are trying to logout/go to another scene we don't want to trigger any of the scene changes
                    -- or try to show tutorials, however we want to clean up after ourselves
                    -- in case we don't actually logout
                    local marketProduct = self.marketProduct
                    self:ResetState()
                    marketProduct:GoToUseProductLocation()
                end,
            },
        },
        canQueue = true,
        mustChoose = true,
    })
    ZO_Dialogs_RegisterCustomDialog(DIALOG_FLOW[FLOW_FAILED],
    {
        setup = function(dialog)

            local displayData =
            {
                data1 = GetAvailableCurrencyHeaderData(self.productCostCurrencyType),
                data2 = GetProductCostHeaderData(self.productCost, self.productCostCurrencyType),
            }

            dialog.data = displayData
            dialog.setupFunc(dialog, displayData)
        end,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = GetString(SI_MARKET_PURCHASING_FAILED_TITLE),
        },
        mainText =
        {
            text = function()
                return self.purchaseFailedText
            end
        },
        buttons = { defaultMarketBackButton },
        canQueue = true,
        mustChoose = true,
    })
end

do
    local ATTACHMENT_TYPE_ITEM = 1
    local ATTACHMENT_TYPE_COLLECTIBLE = 2
    local ATTACHMENT_TYPE_INSTANT_UNLOCK = 3

    local BULLET_ICON = "EsoUI/Art/Miscellaneous/Gamepad/gp_bullet.dds"
    local BULLET_ICON_SIZE = 32
    local LABEL_FONT = "ZoFontGamepadCondensed42"

    local function CreateMarketPurchaseListEntry(marketProductId)
        local name = GetMarketProductDisplayName(marketProductId)
        local formattedName

        local stackCount = GetMarketProductStackCount(marketProductId)
        if stackCount > 1 then
            formattedName = zo_strformat(SI_TOOLTIP_ITEM_NAME_WITH_QUANTITY, name, stackCount)
        else
            formattedName = zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, name)
        end

        local entryTable = {
                                icon = BULLET_ICON,
                                iconColor = ZO_NORMAL_TEXT,
                                iconSize = BULLET_ICON_SIZE,
                                label = formattedName,
                                labelFont = LABEL_FONT,
                            }

        return entryTable
    end

    function ZO_GamepadMarketPurchaseManager:MarketPurchaseConfirmationDialogSetup(dialog)
        local marketProduct = self.marketProduct
        local marketProductId = self.marketProductId
        local productName, description, productIcon = marketProduct:GetMarketProductInfo()
        local isBundle = marketProduct:IsBundle()
        self.hasItems = marketProduct:GetNumAttachedItems() > 0
        self.stackCount = 0

        local formattedProductName
        if not isBundle then
            self.stackCount = marketProduct:GetStackCount()
            dialog.listHeader = nil
        else
            dialog.listHeader = zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, productName)
        end

        self.itemName = productName

        local currencyType, cost, hasDiscount, costAfterDiscount, discountPercent = marketProduct:GetMarketProductPricingByPresentation()

        local finalCost = cost
        if hasDiscount then
            finalCost = costAfterDiscount
        end
        self.productCostCurrencyType = currencyType
        self.productCost = finalCost

        local itemInfo = dialog.info.itemInfo
        ZO_ClearNumericallyIndexedTable(itemInfo)

        if isBundle then
            if not marketProduct:GetHidesChildProducts() then
                local numChildren = marketProduct:GetNumChildren()
                for childIndex = 1, numChildren do
                    local childMarketProductId = marketProduct:GetChildMarketProductId(childIndex)
                    local entryTable = CreateMarketPurchaseListEntry(childMarketProductId)
                    table.insert(itemInfo, entryTable)
                end
            end
        else
            local entryTable = CreateMarketPurchaseListEntry(marketProductId)
            table.insert(itemInfo, entryTable)
        end

        local displayData =
        {
            data1 = GetAvailableCurrencyHeaderData(currencyType),
            data2 = GetProductCostHeaderData(finalCost, currencyType),
        }

        dialog.data = displayData
        dialog.setupFunc(dialog, displayData)
    end
end

do
    local function GetCapacityString()
        local usedSlots = GetNumBagUsedSlots(BAG_BACKPACK)
        local totalSlots = GetBagSize(BAG_BACKPACK)
        local capacityString = zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, usedSlots, totalSlots)
        if usedSlots == totalSlots then
            capacityString = ZO_ERROR_COLOR:Colorize(capacityString)
        end

        return capacityString
    end

     local inventoryFullData =  {
                                    data1 = 
                                    {
                                        header = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
                                        value = GetCapacityString,
                                    },
                                }

    -- onPurchaseSuccessCallback is only called on a successful transfer, onPurchaseEndCallback is called on transaction success, failure, and decline
    -- onPurchaseEndCallback passes a bool value for whether the confirmation scene was reached (true) or not (false)
    function ZO_GamepadMarketPurchaseManager:BeginPurchase(marketProduct, onPurchaseSuccessCallback, onPurchaseEndCallback)
        self:ResetState() -- make sure nothing is carried over from the last purchase attempt

        self.marketProduct = marketProduct
        self.marketProductId = marketProduct:GetId()
        self.onPurchaseSuccessCallback = onPurchaseSuccessCallback
        self.onPurchaseEndCallback = onPurchaseEndCallback

        local hasErrors, dialogParams, promptBuyCrowns, allowContinue = ZO_MARKET_SINGLETON:GetMarketProductPurchaseErrorInfo(marketProduct:GetId())

        PlaySound(SOUNDS.MARKET_PURCHASE_SELECTED)

        if promptBuyCrowns then
            ZO_Dialogs_ShowGamepadDialog("GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_PURCHASE_CROWNS", ZO_BUY_CROWNS_URL_TYPE, dialogParams)
        elseif not allowContinue then
            ZO_Dialogs_ShowGamepadDialog("GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_EXIT", nil, dialogParams)
        elseif hasErrors then
            self:SetFlowPosition(FLOW_WARNING, dialogParams)
        else
            self:SetFlowPosition(FLOW_CONFIRMATION)
        end

        OnMarketStartPurchase(self.marketProductId)
    end
end

function ZO_GamepadMarketPurchaseManager:EndPurchase(isNoChoice)
    local reachedConfirmationScene = self.flowPosition >= FLOW_CONFIRMATION
    local consumablePurchaseSuccessful = self.hasItems and self.flowPosition == FLOW_SUCCESS
    if self.onPurchaseEndCallback then
        self.onPurchaseEndCallback(reachedConfirmationScene, consumablePurchaseSuccessful, self.triggerTutorialOnPurchase)
    end

    -- Hiding the purchase scene after a no choice dialog exit results in the start button no longer working
    if reachedConfirmationScene and (not isNoChoice) then
        SCENE_MANAGER:Hide(ZO_GAMEPAD_MARKET_PURCHASE_SCENE_NAME)
    end

    self:ResetState()
end

function ZO_GamepadMarketPurchaseManager:ResetState()
    self.result = nil
    self.loadingDelayTime = nil
    self.purchaseResultText = nil
    self.purchaseFailedText = nil
    self.purchaseFailed = false
    self.marketProduct = nil
    self.marketProductId = nil
    self.onPurchaseSuccessCallback = nil
    self.onPurchaseEndCallback = nil
    self.hasItems = false
    self.triggerTutorialOnPurchase = nil
    self.flowPosition = FLOW_UNINITIALIZED
    self.doMoveToNextFlowPosition = false
end

function ZO_GamepadMarketPurchaseManager:SetFlowPosition(position, dialogParams)
    self.flowPosition = position

    if position == FLOW_CONFIRMATION then
        SCENE_MANAGER:Push(ZO_GAMEPAD_MARKET_PURCHASE_SCENE_NAME)
    elseif position == FLOW_UNLOCKED then
        local name = self.marketProduct:GetMarketProductDisplayName()
        ZO_Dialogs_ShowGamepadDialog(DIALOG_FLOW[position], nil, {titleParams = {name}, mainTextParams = {ZO_SELECTED_TEXT:Colorize(name)}})
    else
        ZO_Dialogs_ShowGamepadDialog(DIALOG_FLOW[position], nil, dialogParams)
    end
end

do
    local FLOW_MAPPING =
    {
        [FLOW_WARNING] = FLOW_CONFIRMATION,
        [FLOW_CONFIRMATION] = FLOW_PURCHASING,
        [FLOW_PURCHASING] = FLOW_SUCCESS,
    }
    function ZO_GamepadMarketPurchaseManager:MoveToNextFlowPosition()
        if self.purchaseFailed then
            self:SetFlowPosition(FLOW_FAILED)
        elseif self.doMoveToNextFlowPosition then
            local nextPosition = FLOW_MAPPING[self.flowPosition] or self.flowPosition + 1
            self:SetFlowPosition(nextPosition)
            self.doMoveToNextFlowPosition = false
        end
    end
end

function ZO_GamepadMarket_ShowBuyCrownsDialog()
    OnMarketPurchaseMoreCrowns()
    ZO_Dialogs_ShowGamepadDialog("GAMEPAD_MARKET_BUY_CROWNS", g_buyCrownsData, g_buyCrownsTextParams)
end

function ZO_GamepadMarket_ShowBuyPlusDialog()
    local uiPlatform = GetUIPlatform()
    if uiPlatform == UI_PLATFORM_PC then
        ZO_Dialogs_ShowGamepadDialog("CONFIRM_OPEN_URL_BY_TYPE", ZO_BUY_SUBSCRIPTION_URL_TYPE, ZO_BUY_SUBSCRIPTION_FRONT_FACING_ADDRESS)
    else
        ZO_Dialogs_ShowGamepadDialog("GAMEPAD_MARKET_BUY_PLUS")
    end
end