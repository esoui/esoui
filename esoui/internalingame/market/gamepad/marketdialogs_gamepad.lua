local FLOW_UNINITIALIZED = 0
local FLOW_UNLOCKED = 1
local FLOW_OWNED = 2
local FLOW_CONFIRMATION = 3
local FLOW_PURCHASING = 4
local FLOW_SUCCESS = 5
local FLOW_FAILED = 6

local DIALOG_FLOW = 
{
    [FLOW_UNLOCKED] = "GAMEPAD_MARKET_PARTS_UNLOCKED",
    [FLOW_OWNED] = "GAMEPAD_MARKET_BUNDLE_PARTS_OWNED",
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

local function GetAvailableCrownsHeaderData()
    return {
                value = function(control) 
                    ZO_CurrencyControl_SetSimpleCurrency(control, UI_ONLY_CURRENCY_CROWNS, GetMarketCurrency(), ZO_GAMEPAD_MARKET_CURRENCY_OPTIONS)
                    return true
                end,
                header = GetString(SI_GAMEPAD_MARKET_FUNDS_LABEL),
            }
end
local function GetProductCostHeaderData(cost)
    return  {
                value = function(control) 
                    ZO_CurrencyControl_SetSimpleCurrency(control, UI_ONLY_CURRENCY_CROWNS, cost, ZO_GAMEPAD_MARKET_CURRENCY_OPTIONS)
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
    local insufficientFundsMainText
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
                            ZO_MarketDialogs_Shared_OpenURL(...)
                            EndPurchase()
                        end,
        }

        insufficientFundsButtons[1] = openURLButton
        buyCrownsButtons[1] = openURLButton

        insufficientFundsMainText = SI_GAMEPAD_MARKET_INSUFFICIENT_FUNDS_TEXT_WITH_LINK
        self.insufficientCrownsData = ZO_BUY_CROWNS_URL
        self.insufficientCrownsTextParams = { mainTextParams = { ZO_PrefixIconNameFormatter("crowns", GetString(SI_CURRENCY_CROWN)), GetString(SI_MARKET_INSUFFICIENT_FUNDS_LINK_TEXT) } }
        
        buyCrownsMainText = SI_CONFIRM_OPEN_URL_TEXT
        g_buyCrownsData = ZO_BUY_CROWNS_URL
        g_buyCrownsTextParams = ZO_BUY_CROWNS_FRONT_FACING_ADDRESS

        buyPlusMainText = nil --no plans for this currently
    end

    if consoleStoreName then -- PS4/XBox insufficient crowns and buy crowns dialog data
        local consoleTextParams = { mainTextParams = { ZO_PrefixIconNameFormatter("crowns", GetString(SI_CURRENCY_CROWN)), consoleStoreName } }
        insufficientFundsMainText = SI_GAMEPAD_MARKET_INSUFFICIENT_FUNDS_TEXT_CONSOLE_LABEL
        self.insufficientCrownsTextParams = consoleTextParams

        buyCrownsMainText = SI_GAMEPAD_MARKET_BUY_CROWNS_TEXT_LABEL
        g_buyCrownsTextParams = consoleTextParams
        
        local OpenConsoleStoreToPurchaseCrowns = function()
            ShowConsoleStoreUI()
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

    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_MARKET_INSUFFICIENT_CROWNS",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_MARKET_INSUFFICIENT_FUNDS_TITLE
        },
        mainText =
        {
            text = insufficientFundsMainText
        },
        buttons = insufficientFundsButtons,
        noChoiceCallback = EndPurchaseNoChoice,
    })

    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_MARKET_INVENTORY_FULL",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        setup = function(dialog, ...)
                    dialog.setupFunc(dialog, ...)
                end,
        title =
        {
            text = SI_MARKET_INVENTORY_FULL_TITLE,
        },
        mainText =
        {
            text = SI_MARKET_INVENTORY_FULL_TEXT,
        },
        buttons = { defaultMarketBackButton },
        noChoiceCallback = EndPurchaseNoChoice,
    })

    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_MARKET_UNABLE_TO_PURCHASE",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        setup = function(dialog, ...)
                    dialog.setupFunc(dialog, ...)
                end,
        title =
        {
            text = SI_MARKET_UNABLE_TO_PURCHASE_TITLE,
        },
        mainText =
        {
            text = SI_MARKET_UNABLE_TO_PURCHASE_TEXT,
        },
        buttons = { defaultMarketBackButton },
        noChoiceCallback = EndPurchaseNoChoice,
    })

    ZO_Dialogs_RegisterCustomDialog(DIALOG_FLOW[FLOW_OWNED],
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
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
                callback = function() self.doMoveToNextFlowPosition = true end
            },
            [2] =
            {
                text = SI_DIALOG_EXIT,
                callback = EndPurchase
            },
        },
        mustChoose = true,
        finishedCallback = function() self:MoveToNextFlowPosition() end
    })

    ZO_Dialogs_RegisterCustomDialog(DIALOG_FLOW[FLOW_UNLOCKED],
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
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
            [1] =
            {
                text = SI_MARKET_BUNDLE_PARTS_UNLOCKED_CONTINUE,
                callback = function() self.doMoveToNextFlowPosition = true end
            },
            [2] =
            {
                text = SI_DIALOG_EXIT,
                callback = EndPurchase
            },
        },
        mustChoose = true,
        finishedCallback = function() self:MoveToNextFlowPosition() end
    })

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
                text = SI_GAMEPAD_MARKET_CONFIRM_PURCHASE_BACK_KEYBIND_LABEL,
                callback = EndPurchase,
            },
            {
                keybind = "DIALOG_SECONDARY",
                text = SI_GAMEPAD_MARKET_CONFIRM_PURCHASE_BUY_NOW_LABEL,
                callback =  function(dialog)
                                self.doMoveToNextFlowPosition = true
                            end,
            },
        },
        mustChoose = true,
        finishedCallback =  function()
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

    local function OnMarketPurchaseResult(_, result)
        EVENT_MANAGER:UnregisterForEvent("GAMEPAD_MARKET_PURCHASING", EVENT_MARKET_PURCHASE_RESULT)
        self.result = result
    end

    local LOADING_DELAY = 500 -- delay is in milliseconds
    local function OnMarketPurchasingUpdate(dialog, currentTimeInSeconds)
        local result = self.result
        local hasResult = result ~= nil
        
        if hasResult then
            if result == MARKET_PURCHASE_RESULT_SUCCESS then
                if self.stackCount > 1 then
                    self.purchaseResultText = zo_strformat(SI_MARKET_PURCHASE_SUCCESS_TEXT_WITH_QUANTITY, self.itemName, self.stackCount)
                else
                    if self.marketProduct:GetNumAttachedCollectibles() > 0 then
                        self.purchaseResultText = zo_strformat(SI_MARKET_PURCHASE_SUCCESS_TEXT_WITH_COLLECTIBLE, self.itemName)
                    else
                        self.purchaseResultText = zo_strformat(SI_MARKET_PURCHASE_SUCCESS_TEXT, self.itemName)
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
        dialog.setupFunc(dialog)
        EVENT_MANAGER:RegisterForEvent("GAMEPAD_MARKET_PURCHASING", EVENT_MARKET_PURCHASE_RESULT, function(eventId, ...) OnMarketPurchaseResult(data, ...) end)
        BuyMarketProduct(self.marketProductId)
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
                data1 = GetAvailableCrownsHeaderData(),
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
        },
        canQueue = true,
        mustChoose = true,
    })
    ZO_Dialogs_RegisterCustomDialog(DIALOG_FLOW[FLOW_FAILED], 
    {
        setup = function(dialog)

            local displayData =
            {
                data1 = GetAvailableCrownsHeaderData(),
                data2 = GetProductCostHeaderData(self.productCost),
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

    local function CreateMarketAttachmentListEntry(productId, attachmentType, attachmentIndex)
        local name
        if attachmentType == ATTACHMENT_TYPE_ITEM then
            local itemIcon, itemName, quality, requiredLevel, itemCount = select(2, GetMarketProductItemInfo(productId, attachmentIndex))
            if itemCount > 1 then
                name = zo_strformat(SI_TOOLTIP_ITEM_NAME_WITH_QUANTITY, itemName, itemCount)
            else
                name = zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, itemName)
            end
        elseif attachmentType == ATTACHMENT_TYPE_COLLECTIBLE then
            local collectibleIcon, collectibleName = select(2, GetMarketProductCollectibleInfo(productId, attachmentIndex))
            name = zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, collectibleName)
        elseif attachmentType == ATTACHMENT_TYPE_INSTANT_UNLOCK then
            --relying on the fact that the "name" of the instant unlock is the same as the market product (same as in the tooltip)
            name = zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, GetMarketProductInfo(productId))
        end

        local entryTable = {
                                icon = BULLET_ICON,
                                iconColor = ZO_NORMAL_TEXT,
                                iconSize = BULLET_ICON_SIZE,
                                label = name,
                                labelFont = LABEL_FONT,
                            }

        return entryTable
    end

    function ZO_GamepadMarketPurchaseManager:MarketPurchaseConfirmationDialogSetup(dialog)
        local marketProduct = self.marketProduct
        local marketProductId = self.marketProductId
        local productName, description, cost, discountedCost, discountPercent, productIcon = marketProduct:GetMarketProductInfo()
        local isBundle = marketProduct:IsBundle()
        self.hasItems = GetMarketProductNumItems(marketProductId) > 0
        self.stackCount = 0

        local formattedProductName
        if not isBundle then
            self.stackCount = select(6, GetMarketProductItemInfo(self.marketProductId, 1))
            dialog.listHeader = nil
        else
            dialog.listHeader = zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, productName)
        end

        self.itemName = productName

        local finalCost = cost
        if discountPercent > 0 then
            finalCost = discountedCost
        end
        self.productCost = finalCost

        local itemInfo = dialog.info.itemInfo
        ZO_ClearNumericallyIndexedTable(itemInfo)

        for itemIndex = 1, marketProduct:GetNumAttachedItems() do
            local entryTable = CreateMarketAttachmentListEntry(marketProductId, ATTACHMENT_TYPE_ITEM, itemIndex)

            table.insert(itemInfo, entryTable)
        end

        for collectibleIndex = 1, marketProduct:GetNumAttachedCollectibles() do
            local entryTable = CreateMarketAttachmentListEntry(marketProductId, ATTACHMENT_TYPE_COLLECTIBLE, collectibleIndex)

            table.insert(itemInfo, entryTable)
        end

        if marketProduct:HasInstantUnlock() then
            local entryTable = CreateMarketAttachmentListEntry(marketProductId, ATTACHMENT_TYPE_INSTANT_UNLOCK, 1)

            table.insert(itemInfo, entryTable)
        end

        local displayData =
        {
            data1 = GetAvailableCrownsHeaderData(),
            data2 = GetProductCostHeaderData(finalCost),
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

        PlaySound(SOUNDS.MARKET_PURCHASE_SELECTED)
        local expectedPurchaseResult = CouldPurchaseMarketProduct(self.marketProductId)
        if expectedPurchaseResult == MARKET_PURCHASE_RESULT_NOT_ENOUGH_VC then
            ZO_Dialogs_ShowGamepadDialog("GAMEPAD_MARKET_INSUFFICIENT_CROWNS", self.insufficientCrownsData, self.insufficientCrownsTextParams)
        else
            if expectedPurchaseResult == MARKET_PURCHASE_RESULT_NOT_ENOUGH_ROOM then
                local spaceNeeded = GetSpaceNeededToPurchaseMarketProduct(self.marketProductId)
                ZO_Dialogs_ShowGamepadDialog("GAMEPAD_MARKET_INVENTORY_FULL", inventoryFullData, { mainTextParams = { spaceNeeded } })
            elseif expectedPurchaseResult == MARKET_PURCHASE_RESULT_ALREADY_UNLOCKED_BACKPACK_UPGRADES or expectedPurchaseResult == MARKET_PURCHASE_RESULT_ALREADY_UNLOCKED_BANK_UPGRADES then
                ZO_Dialogs_ShowGamepadDialog("GAMEPAD_MARKET_UNABLE_TO_PURCHASE", nil, { mainTextParams = { GetString("SI_MARKETPURCHASABLERESULT", expectedPurchaseResult) } })
            elseif marketProduct:HasSubscriptionUnlockedAttachments() then
                self:SetFlowPosition(FLOW_UNLOCKED)
            elseif marketProduct:HasBeenPartiallyPurchased() then
                self:SetFlowPosition(FLOW_OWNED)
            else
                self:SetFlowPosition(FLOW_CONFIRMATION)
            end
        end
    end
end

function ZO_GamepadMarketPurchaseManager:EndPurchase(isNoChoice)
    local reachedConfirmationScene = self.flowPosition >= FLOW_CONFIRMATION
    local consumablePurchaseSuccessful = self.hasItems and self.flowPosition == FLOW_SUCCESS
    if self.onPurchaseEndCallback then
        self.onPurchaseEndCallback(reachedConfirmationScene, consumablePurchaseSuccessful)
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
    self.flowPosition = FLOW_UNINITIALIZED
    self.doMoveToNextFlowPosition = false
end

function ZO_GamepadMarketPurchaseManager:SetFlowPosition(position)
    self.flowPosition = position

    if position == FLOW_CONFIRMATION then
        SCENE_MANAGER:Push(ZO_GAMEPAD_MARKET_PURCHASE_SCENE_NAME)
    elseif position == FLOW_UNLOCKED then
        local name = self.marketProduct:GetMarketProductInfo()
        ZO_Dialogs_ShowGamepadDialog(DIALOG_FLOW[position], nil, {titleParams = {name}, mainTextParams = {ZO_SELECTED_TEXT:Colorize(name)}})
    else
        ZO_Dialogs_ShowGamepadDialog(DIALOG_FLOW[position])
    end
end

do
    local FLOW_MAPPING =
    {
        [FLOW_UNLOCKED] = FLOW_CONFIRMATION,
        [FLOW_OWNED] = FLOW_CONFIRMATION,
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
    ZO_Dialogs_ShowGamepadDialog("GAMEPAD_MARKET_BUY_CROWNS", g_buyCrownsData, g_buyCrownsTextParams)
end

function ZO_GamepadMarket_ShowBuyPlusDialog()
    ZO_Dialogs_ShowGamepadDialog("GAMEPAD_MARKET_BUY_PLUS")
end