local FLOW_UNINITIALIZED = 0
local FLOW_WARNING = 1
local FLOW_CONFIRMATION = 2
local FLOW_CONFIRMATION_ESO_PLUS = 3
local FLOW_PURCHASING = 4
local FLOW_CONFIRMATION_PARTIAL_BUNDLE = 5
local FLOW_SUCCESS = 6
local FLOW_FAILED = 7

local DIALOG_FLOW =
{
    [FLOW_WARNING] = "GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_CONTINUE",
    [FLOW_CONFIRMATION] = "GAMEPAD_MARKET_PURCHASE_CONFIRMATION",
    [FLOW_CONFIRMATION_ESO_PLUS] = "GAMEPAD_MARKET_FREE_TRIAL_PURCHASE_CONFIRMATION",
    [FLOW_PURCHASING] = "GAMEPAD_MARKET_PURCHASING",
    [FLOW_CONFIRMATION_PARTIAL_BUNDLE] = "GAMEPAD_MARKET_PARTIAL_BUNDLE_CONFIRMATION",
    [FLOW_SUCCESS] = "GAMEPAD_MARKET_PURCHASE_SUCCESS",
    [FLOW_FAILED] = "GAMEPAD_MARKET_PURCHASE_FAILED",
}

local SELECT_HOUSE_TEMPLATE_DIALOG = "GAMEPAD_MARKET_PURCHASE_HOUSE_TEMPLATE_SELECTION"

ZO_GAMEPAD_MARKET_CURRENCY_OPTIONS =
{
    showTooltips = false,
    useShortFormat = false,
    font = "ZoFontGamepadHeaderDataValue",
    iconSide = RIGHT,
    iconSize = 28,
    isGamepad = true,
}

ZO_GAMEPAD_MARKET_PURCHASE_SCENE_NAME = "gamepad_market_purchase"

local function GetAvailableCurrencyHeaderData(marketCurrencyType)
    return {
        value = function(control)
            ZO_CurrencyControl_SetSimpleCurrency(control, GetCurrencyTypeFromMarketCurrencyType(marketCurrencyType), GetPlayerMarketCurrency(marketCurrencyType), ZO_GAMEPAD_MARKET_CURRENCY_OPTIONS)
            return true
        end,
        valueNarration = function()
            return ZO_Currency_FormatGamepad(GetCurrencyTypeFromMarketCurrencyType(marketCurrencyType), GetPlayerMarketCurrency(marketCurrencyType), ZO_CURRENCY_FORMAT_AMOUNT_NAME)
        end,
        header = GetString(SI_GAMEPAD_MARKET_FUNDS_LABEL),
    }
end

local g_dialogDiscountPercentParentControl = nil
local function GetProductCostHeaderData(cost, marketCurrencyType, hasEsoPlusCost, discountPercent, updateDiscountPercentParentControl)
    return {
        value = function(control)
            local displayOptions
            if hasEsoPlusCost or discountPercent ~= nil then
                displayOptions =
                {
                    iconInheritColor = true,
                    color = ZO_DEFAULT_TEXT,
                    strikethroughCurrencyAmount = true,
                }
            end
            ZO_CurrencyControl_SetSimpleCurrency(control, GetCurrencyTypeFromMarketCurrencyType(marketCurrencyType), cost, ZO_GAMEPAD_MARKET_CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, CURRENCY_IGNORE_HAS_ENOUGH, displayOptions)
            if not hasEsoPlusCost and updateDiscountPercentParentControl then
                g_dialogDiscountPercentParentControl = control
            end
            return true
        end,
        valueNarration = function()
            return ZO_Currency_FormatGamepad(GetCurrencyTypeFromMarketCurrencyType(marketCurrencyType), cost, ZO_CURRENCY_FORMAT_AMOUNT_NAME)
        end,
        header = function(control)
            if hasEsoPlusCost then
                return GetString(SI_GAMEPAD_MARKET_CONFIRM_PURCHASE_NORMAL_COST_LABEL)
            elseif discountPercent ~= nil then
                return ""
            else
                return GetString(SI_GAMEPAD_MARKET_CONFIRM_PURCHASE_COST_LABEL)
            end
        end,
    }
end

local function GetProductEsoPlusCostHeaderData(cost, marketCurrencyType)
    return {
        value = function(control)
            local displayOptions =
            {
                iconInheritColor = true,
                color = ZO_MARKET_PRODUCT_ESO_PLUS_COLOR,
            }
            ZO_CurrencyControl_SetSimpleCurrency(control, GetCurrencyTypeFromMarketCurrencyType(marketCurrencyType), cost, ZO_GAMEPAD_MARKET_CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, CURRENCY_IGNORE_HAS_ENOUGH, displayOptions)
            return true
        end,
        valueNarration = function()
            return ZO_Currency_FormatGamepad(GetCurrencyTypeFromMarketCurrencyType(marketCurrencyType), cost, ZO_CURRENCY_FORMAT_AMOUNT_NAME)
        end,
        header = GetString(SI_GAMEPAD_MARKET_CONFIRM_PURCHASE_ESO_PLUS_COST_LABEL),
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
            local queuedDialogInfo = self.queuedDialogInfo
            if queuedDialogInfo then
                ZO_Dialogs_ShowGamepadDialog(queuedDialogInfo.dialogName, queuedDialogInfo.dialogData, queuedDialogInfo.dialogParams)
            end
        elseif newState == SCENE_HIDDEN then
            if self.isPreviewingMarketProductPlacement then
                self.isPreviewingMarketProductPlacement = nil
                ZO_ReturnToHousingEditorBrowseMode()
            end
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

    local defaultMarketBackButton =
    {
        text = SI_DIALOG_EXIT,
        callback = EndPurchase,
        keybind = "DIALOG_NEGATIVE"
    }

    ESO_Dialogs["GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_CONTINUE"] = 
    {
        canQueue = true,
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
            text = SI_MARKET_PURCHASE_ERROR_WITH_CONTINUE_TEXT_FORMATTER
        },
        buttons =
        {
            {
                text = SI_MARKET_PURCHASE_ERROR_CONTINUE,
                callback = function() self.doMoveToNextFlowPosition = true end
            },
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
        end,
    }

    ESO_Dialogs["GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_JOIN_ESO_PLUS"] =
    {
        canQueue = true,
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
            {
                text = SI_MARKET_JOIN_ESO_PLUS_CONFIRM_BUTTON_TEXT,
                callback = function()
                    -- Buying crowns should happen before ending the purchase to keep it within this session
                    ZO_ShowBuySubscriptionPlatformDialog()
                    EndPurchase()
                end,
            },
            defaultMarketBackButton,
        },
        noChoiceCallback = EndPurchaseNoChoice,
        finishedCallback = function()
            OnMarketEndPurchase()
        end,
    }

    ESO_Dialogs["GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_PURCHASE_CROWNS"] =
    {
        canQueue = true,
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
            {
                text = function()
                    if DoesPlatformStoreUseExternalLinks() then
                        return GetString(SI_MARKET_INSUFFICIENT_FUNDS_CONFIRM_BUTTON_TEXT)
                    else
                        return zo_strformat(SI_OPEN_FIRST_PARTY_STORE_KEYBIND, ZO_GetPlatformStoreName())
                    end
                end,
                callback = function()
                    -- Buying crowns should happen before ending the purchase to keep it within this session
                    ZO_ShowBuyCrownsPlatformUI()
                    self:EndPurchase()
                end
            },
            defaultMarketBackButton,

        },
        noChoiceCallback = EndPurchaseNoChoice,
        finishedCallback = function()
            OnMarketEndPurchase()
            self:EndPurchaseFromErrorDialog()
        end,
    }

    ESO_Dialogs["GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_GIFTING_GRACE_PERIOD"] =
    {
        canQueue = true,
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
            text = SI_MARKET_GIFTING_GRACE_PERIOD_TEXT
        },
        buttons =
        {
            {
                text = SI_MARKET_GIFTING_LOCKED_HELP_KEYBIND,
                callback = function(dialog)
                    ZO_MarketDialogs_Shared_OpenGiftingLockedHelp(dialog)
                    EndPurchase()
                end,
                keybind = "DIALOG_SECONDARY",
            },
            defaultMarketBackButton,
        },
        noChoiceCallback = EndPurchaseNoChoice,
        finishedCallback = function()
            OnMarketEndPurchase()
            self:EndPurchaseFromErrorDialog()
        end,
        updateFn = function(dialog)
            ZO_MarketDialogs_Shared_UpdateGiftingGracePeriodTimer(dialog)
        end,

    }

    ESO_Dialogs["GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_GIFTING_NOT_ALLOWED"] =
    {
        canQueue = true,
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
            {
                text = SI_MARKET_GIFTING_LOCKED_HELP_KEYBIND,
                callback = function(dialog)
                    ZO_MarketDialogs_Shared_OpenGiftingLockedHelp(dialog)
                    EndPurchase()
                end,
                keybind = "DIALOG_SECONDARY",
            },
            defaultMarketBackButton,
        },
        noChoiceCallback = EndPurchaseNoChoice,
        finishedCallback = function()
            OnMarketEndPurchase()
            self:EndPurchaseFromErrorDialog()
        end,
    }

    ESO_Dialogs["GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_ALREADY_HAVE_PRODUCT_IN_GIFT_INVENTORY"] =
    {
        canQueue = true,
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
            {
                text = SI_MARKET_OPEN_GIFT_INVENTORY_KEYBIND_LABEL,
                callback = function(dialog)
                    RequestShowGiftInventory()
                    EndPurchase()
                end,
                keybind = "DIALOG_SECONDARY",
            },
            defaultMarketBackButton,
        },
        noChoiceCallback = EndPurchaseNoChoice,
        finishedCallback = function()
            OnMarketEndPurchase()
            self:EndPurchaseFromErrorDialog()
        end,
    }

    ESO_Dialogs["GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_EXIT"] =
    {
        canQueue = true,
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
            defaultMarketBackButton
        },
        noChoiceCallback = EndPurchaseNoChoice,
        finishedCallback = function()
            OnMarketEndPurchase()
            self:EndPurchaseFromErrorDialog()
        end,
        setup = function(dialog, ...)
            dialog.setupFunc(dialog, ...)
        end,
    }

    local confirmationDialogInfo =
    {
        setup = function(...) self:MarketPurchaseConfirmationDialogSetup(...) end,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            allowRightStickPassThrough = true,
        },
        title =
        {
            text = SI_MARKET_CONFIRM_PURCHASE_TITLE,
        },
        mainText =
        {
            text = function()
                local houseId = GetMarketProductHouseId(self.marketProductData.marketProductId)
                if houseId > 0 then
                    local houseCollectibleId = GetCollectibleIdForHouse(houseId)
                    local houseDisplayName = GetCollectibleName(houseCollectibleId)
                    return ZO_SELECTED_TEXT:Colorize(zo_strformat(SI_MARKET_PRODUCT_HOUSE_NAME_FORMATTER, houseDisplayName, self.itemName))
                else
                    local stackCount = self.marketProductData:GetStackCount()
                    if stackCount > 1 then
                        return zo_strformat(SI_TOOLTIP_ITEM_NAME_WITH_QUANTITY, self.itemName, stackCount)
                    else
                        return zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, self.itemName)
                    end
                end
            end
        },
        canQueue = true,
        parametricList = {}, --we'll generate the entries on setup
        blockDialogReleaseOnPress = true, -- We need to manually control when we release so we can use the select keybind to activate entries
        mustChoose = true,
        onHidingCallback = function(dialog)
            local targetData = dialog.entryList:GetTargetData()
            if targetData and targetData.dropdownEntry then
                local targetControl = dialog.entryList:GetTargetControl()
                local dropdown = targetControl.dropdown
                dropdown:Deactivate()
            end
        end,
        finishedCallback = function()
            if g_dialogDiscountPercentControl then
                g_dialogDiscountPercentControl:SetHidden(true)
            end
        end,
        baseNarrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
        buttons =
        {
            -- Select Button
            {
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_GAMEPAD_SELECT_OPTION),
                enabled = function(dialog)
                    if ZO_IsConsolePlatform() then
                        local targetData = dialog.entryList:GetTargetData()
                        if targetData.messageEntry then
                            if IsConsoleCommunicationRestricted() then
                                return false, GetString(SI_CONSOLE_COMMUNICATION_PERMISSION_ERROR_GLOBALLY_RESTRICTED)
                            end
                        end
                        return true
                    end
                end,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    local targetControl = dialog.entryList:GetTargetControl()
                    if targetData.quantityEntry and targetControl then
                        targetControl.editBoxControl:TakeFocus()
                    elseif targetData.dropdownEntry then
                        local dropdown = targetControl.dropdown
                        dropdown:Activate()
                    elseif targetData.messageEntry and targetControl then
                        targetControl.editBoxControl:TakeFocus()
                    elseif targetData.recipientNameEntry and targetControl then
                        if ZO_IsPlaystationPlatform() then
                            --On PlayStation the primary action opens the first party dialog to get a playstation id since it can select any player
                            local function OnUserChosen(hasResult, displayName, consoleId)
                                if hasResult then
                                    targetControl.editBoxControl:SetText(displayName)
                                end
                            end
                            local INCLUDE_ONLINE_FRIENDS = true
                            local INCLUDE_OFFLINE_FRIENDS = true
                            PLAYER_CONSOLE_INFO_REQUEST_MANAGER:RequestIdFromUserListDialog(OnUserChosen, GetString(SI_GAMEPAD_CONSOLE_SELECT_FOR_SEND_GIFT), INCLUDE_ONLINE_FRIENDS, INCLUDE_OFFLINE_FRIENDS)
                        else
                            --Otherwise (PC, Xbox) the primary action is to input the name by keyboard
                            targetControl.editBoxControl:TakeFocus()
                        end
                    end
                end,
            },
            --Back
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_MARKET_CONFIRM_PURCHASE_BACK_KEYBIND_LABEL,
                callback = function(dialog)
                    -- release the dialog first to avoid issue where the parametric list can refresh
                    -- but EndPurchase will wipe out important state, like self.marketProductData
                    ZO_Dialogs_ReleaseDialogOnButtonPress(DIALOG_FLOW[FLOW_CONFIRMATION])

                    OnMarketEndPurchase()
                    local NOT_NO_CHOICE_CALLBACK = false
                    self:EndPurchase(NOT_NO_CHOICE_CALLBACK)
                end,
            },
            --Confirm
            {
                keybind = "DIALOG_SECONDARY",
                text = SI_DIALOG_CONFIRM,
                clickSound = SOUNDS.DIALOG_ACCEPT,
                enabled = function(dialog)
                    if self.isGift then
                        local recipientDisplayName = self.recipientDisplayName
                        local result = IsGiftRecipientNameValid(recipientDisplayName)
                        if result ~= GIFT_ACTION_RESULT_SUCCESS then
                            local errorText
                            if result == GIFT_ACTION_RESULT_RECIPIENT_EMPTY then
                                -- avoid issue where we'd pass nil to zo_strformat when no displayName has been set
                                -- plus this format string doesn't require any arguments
                                errorText = GetString("SI_GIFTBOXACTIONRESULT", result)
                            else
                                errorText = zo_strformat(GetString("SI_GIFTBOXACTIONRESULT", result), recipientDisplayName)
                            end
                            return false, errorText
                        end
                    end

                    local quantity = self.quantity
                    local isValid, result
                    if self.isGift then
                        isValid, result = self.marketProductData:IsGiftQuantityValid(quantity)
                    else
                        isValid, result = self.marketProductData:IsPurchaseQuantityValid(quantity)
                    end
                    if not isValid then
                        local errorText
                        if result == MARKET_PURCHASE_RESULT_EXCEEDS_MAX_QUANTITY then
                            errorText = zo_strformat(GetString("SI_MARKETPURCHASABLERESULT", result), self.maxQuantity)
                        else
                            errorText = GetString("SI_MARKETPURCHASABLERESULT", result)
                        end
                        return false, errorText
                    end

                    return true
                end,
                callback = function(dialog)
                    OnMarketEndPurchase(self.marketProductData:GetId())
                    ZO_Dialogs_ReleaseDialogOnButtonPress(DIALOG_FLOW[FLOW_CONFIRMATION])
                    self:SetFlowPosition(FLOW_PURCHASING)
                end,
            },
            --Xbox Choose Friend/Random note
            {
                keybind = "DIALOG_TERTIARY",
                text = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData.recipientNameEntry then
                        return GetString(SI_GAMEPAD_CONSOLE_CHOOSE_FRIEND)
                    elseif targetData.messageEntry then
                        return GetString(SI_GAMEPAD_GENERATE_RANDOM_NOTE)
                    end
                end,
                visible = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    local isXbox = GetUIPlatform() == UI_PLATFORM_XBOX
                    return (isXbox and targetData.recipientNameEntry and GetNumberConsoleFriends() > 0) or targetData.messageEntry
                end,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    local targetControl = dialog.entryList:GetTargetControl()
                    if targetData.recipientNameEntry and targetControl then
                        local function OnUserChosen(hasResult, displayName, consoleId)
                            if hasResult then
                                SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                                targetControl.editBoxControl:SetText(displayName)
                            end
                        end
                        local INCLUDE_ONLINE_FRIENDS = true
                        local INCLUDE_OFFLINE_FRIENDS = true
                        PLAYER_CONSOLE_INFO_REQUEST_MANAGER:RequestIdFromUserListDialog(OnUserChosen, GetString(SI_GAMEPAD_CONSOLE_SELECT_FOR_SEND_GIFT), INCLUDE_ONLINE_FRIENDS, INCLUDE_OFFLINE_FRIENDS)
                    elseif targetData.messageEntry and targetControl then
                        targetControl.editBoxControl:SetText(GetRandomGiftSendNoteText())
                        SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                    end
                end,
            },
        },
    }

    ZO_Dialogs_RegisterCustomDialog(DIALOG_FLOW[FLOW_CONFIRMATION], confirmationDialogInfo)

    local CURRENCY_ICON_SIZE = 32
    ZO_Dialogs_RegisterCustomDialog(DIALOG_FLOW[FLOW_CONFIRMATION_ESO_PLUS],
    {
        setup = function(...) self:MarketPurchaseConfirmationFreeTrialDialogSetup(...) end,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_MARKET_PURCHASE_FREE_TRIAL_TITLE,
        },
        mainText =
        {
            text = function(dialog)
                local endTimeString = self.marketProductData:GetEndTimeString()
                local currencyIcon = ZO_Currency_GetPlatformFormattedCurrencyIcon(CURT_CROWNS, CURRENCY_ICON_SIZE)
                return zo_strformat(SI_MARKET_PURCHASE_FREE_TRIAL_TEXT, endTimeString, currencyIcon)
            end,
        },
        canQueue = true,
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_MARKET_CONFIRM_PURCHASE_BACK_KEYBIND_LABEL,
                callback = function(dialog)
                    OnMarketEndPurchase()
                    local NOT_NO_CHOICE_CALLBACK = false
                    self:EndPurchase(NOT_NO_CHOICE_CALLBACK)
                end,
            },
            {
                keybind = "DIALOG_SECONDARY",
                text = SI_MARKET_CONFIRM_PURCHASE_KEYBIND_TEXT,
                callback = function(dialog)
                    OnMarketEndPurchase(self.marketProductData:GetId())
                    self.doMoveToNextFlowPosition = true
                end,
            },
        },
        mustChoose = true,
        finishedCallback = function(dialog)
            self:MoveToNextFlowPosition()
        end,
    })

    local LOADING_DELAY_MS = 500 -- delay is in milliseconds
    local function OnMarketPurchaseResult(dialog, result, tutorialProductId, wasGift)
        EVENT_MANAGER:UnregisterForEvent("GAMEPAD_MARKET_PURCHASING", EVENT_MARKET_PURCHASE_RESULT)

        internalassert(wasGift == self.isGift)

        self.useProductInfo = nil
        local purchaseSucceeded = result == MARKET_PURCHASE_RESULT_SUCCESS
        if not wasGift then
            if tutorialProductId ~= 0 then
                self.triggerTutorialOnPurchase = 
                { 
                    trigger = TUTORIAL_TRIGGER_CROWN_STORE_PRODUCT_PURCHASED, 
                    param = tutorialProductId
                }
            end

            if purchaseSucceeded then
                self.useProductInfo = ZO_Market_Shared.GetUseProductInfo(self.marketProductData)
            end
        end

        -- we got a purchase result while showing the FLOW_PURCHASING dialog
        -- so we need to transition to the success or fail state based on the result
        -- to prevent a jarring transition when switching, we're going to delay the release
        -- of the dialog and the advancement of the flow position
        zo_callLater(function()
            ZO_Dialogs_ReleaseDialogOnButtonPress(DIALOG_FLOW[FLOW_PURCHASING])
            if purchaseSucceeded then
                self:SetFlowPosition(FLOW_SUCCESS)
            elseif result == MARKET_PURCHASE_RESULT_GIFT_COLLECTIBLE_PARTIALLY_OWNED then
                local displayName = self.marketProductData:GetDisplayName()
                local dialogData = {}
                local dialogParams =
                {
                    titleParams = { ZO_SELECTED_TEXT:Colorize(displayName) },
                }
                self:SetFlowPosition(FLOW_CONFIRMATION_PARTIAL_BUNDLE, dialogData, dialogParams)
            else
                local dialogData =
                {
                    purchaseResult = result
                }
                self:SetFlowPosition(FLOW_FAILED, dialogData)
            end
        end, LOADING_DELAY_MS)
    end

    local function MarketPurchasingDialogSetup(dialog, data)
        dialog:setupFunc()
        dialog.isPreviewingMarketProductPlacement = IsHousingEditorPreviewingMarketProductPlacement()

        EVENT_MANAGER:RegisterForEvent("GAMEPAD_MARKET_PURCHASING", EVENT_MARKET_PURCHASE_RESULT, function(eventId, ...) OnMarketPurchaseResult(dialog, ...) end)
        if data and data.shouldSendPartiallyOwnedGift then
            RespondToSendPartiallyOwnedGift(true)
        else
            if not self.isGift then
                self.marketProductData:RequestPurchase(self.quantity)
            else
                self.marketProductData:RequestPurchaseAsGift(self.giftMessage, self.recipientDisplayName, self.quantity)
            end
        end
    end

    ZO_Dialogs_RegisterCustomDialog(DIALOG_FLOW[FLOW_PURCHASING],
    {
        setup = MarketPurchasingDialogSetup,
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
                local color = GetItemQualityColor(GetMarketProductDisplayQuality(self.marketProductData.marketProductId))
                local quantity = self.quantity or 1
                local stackCount = self.marketProductData:GetStackCount()
                local totalStackCount = stackCount * quantity
                if totalStackCount > 1 then
                    return zo_strformat(SI_MARKET_PURCHASING_TEXT_WITH_QUANTITY, color:Colorize(self.itemName), totalStackCount)
                else
                    local itemName = self.itemName
                    local houseId = GetMarketProductHouseId(self.marketProductData.marketProductId)
                    if houseId > 0 then
                        local houseCollectibleId = GetCollectibleIdForHouse(houseId)
                        local houseDisplayName = GetCollectibleName(houseCollectibleId)
                        itemName = zo_strformat(SI_MARKET_PRODUCT_HOUSE_NAME_GRAMMARLESS_FORMATTER, houseDisplayName, self.itemName)
                    end
                    return zo_strformat(SI_MARKET_PURCHASING_TEXT, color:Colorize(itemName))
                end
            end,
        },
        canQueue = true,
        mustChoose = true,
    })

    ZO_Dialogs_RegisterCustomDialog(DIALOG_FLOW[FLOW_SUCCESS],
    {
        setup = function(dialog)
            if self.onPurchaseSuccessCallback then
                self.onPurchaseSuccessCallback()
                self.onPurchaseSuccessCallback = nil
            end

            if self.showRemainingBalance then
                local currencyType = self.marketProductData:GetMarketProductPricingByPresentation()
                dialog.data =
                {
                    data1 = GetAvailableCurrencyHeaderData(currencyType),
                }
            end

            dialog.setupFunc(dialog, dialog.data)
        end,
        updateFn = function(dialog)
            KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups(dialog.keybindStateIndex)
        end,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = function()
                if self.useProductInfo then
                    if self.useProductInfo.transactionCompleteTitleText then
                        return self.useProductInfo.transactionCompleteTitleText
                    end
                end

                return GetString(SI_TRANSACTION_COMPLETE_TITLE)
            end,
        },
        mainText =
        {
            text = function(dialog)
                local marketProductData = self.marketProductData
                local marketProductId = marketProductData:GetId()
                local quantity = self.quantity or 1
                local stackCount = marketProductData:GetStackCount()
                local totalStackCount = stackCount * quantity
                local itemName = self.itemName
                local color = GetItemQualityColor(GetMarketProductDisplayQuality(marketProductId))
                local houseId = GetMarketProductHouseId(marketProductId)
                if houseId > 0 then
                    local houseCollectibleId = GetCollectibleIdForHouse(houseId)
                    local houseDisplayName = GetCollectibleName(houseCollectibleId)
                    itemName = zo_strformat(SI_MARKET_PRODUCT_HOUSE_NAME_GRAMMARLESS_FORMATTER, houseDisplayName, self.itemName)
                end

                if self.isGift then
                    if totalStackCount > 1 then
                        return zo_strformat(SI_MARKET_GIFTING_SUCCESS_TEXT_WITH_QUANTITY, color:Colorize(itemName), totalStackCount, ZO_SELECTED_TEXT:Colorize(self.recipientDisplayName))
                    else
                        return zo_strformat(SI_MARKET_GIFTING_SUCCESS_TEXT, color:Colorize(itemName), ZO_SELECTED_TEXT:Colorize(self.recipientDisplayName))
                    end
                else
                    local mainText
                    if self.useProductInfo then
                        mainText = zo_strformat(self.useProductInfo.transactionCompleteText, color:Colorize(itemName), totalStackCount)
                    else
                        if totalStackCount > 1 then
                            mainText = zo_strformat(SI_MARKET_PURCHASE_SUCCESS_TEXT_WITH_QUANTITY, color:Colorize(itemName), totalStackCount)
                        else
                            if not self.isGift and self.marketProductData:GetNumAttachedCollectibles() > 0 then
                                mainText = zo_strformat(SI_MARKET_PURCHASE_SUCCESS_TEXT_WITH_COLLECTIBLE, color:Colorize(itemName))
                            else
                                mainText = zo_strformat(SI_MARKET_PURCHASE_SUCCESS_TEXT, color:Colorize(itemName))
                            end
                        end
                    end

                    -- append ESO Plus savings, if any
                    local esoPlusSavingsString = ZO_MarketDialogs_Shared_GetEsoPlusSavingsString(marketProductData, quantity)
                    if esoPlusSavingsString then
                        mainText = string.format("%s\n\n%s", mainText, esoPlusSavingsString)
                    end

                    return mainText
                end
            end
        },
        canQueue = true,
        mustChoose = true,
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                text = function()
                    if self.purchaseFromIngame then
                        return GetString(SI_MARKET_CONFIRM_PURCHASE_BACK_KEYBIND_LABEL)
                    else
                        return GetString(SI_MARKET_BACK_TO_STORE_KEYBIND_LABEL)
                    end
                end,
                callback = EndPurchase,
            },
            {
                keybind = "DIALOG_TERTIARY",
                text = function(dialog)
                    if self.useProductInfo then
                        return self.useProductInfo.buttonText
                    end
                end,
                visible = function(dialog)
                    if self.useProductInfo then
                        return not self.useProductInfo.visible or self.useProductInfo.visible()
                    end

                    return false
                end,
                enabled = function(dialog)
                    if self.useProductInfo then
                        return not self.useProductInfo.enabled or self.useProductInfo.enabled()
                    end
                end,
                callback = function()
                    -- Order matters:
                    -- Cache off the productData, because reset state will clear it:
                    local marketProductData = self.marketProductData
                    -- Since we are trying to logout/go to another scene we don't want to trigger any of the scene changes
                    -- or try to show tutorials, however we want to clean up after ourselves in case we don't actually logout
                    self:ResetState()
                    -- Ensure that we don't try to return to Housing Editor Browse mode again when the scene hides:
                    local isPreviewingMarketProductPlacement = self.isPreviewingMarketProductPlacement
                    self.isPreviewingMarketProductPlacement = nil
                    ZO_Market_Shared.GoToUseProductLocation(marketProductData)
                    if isPreviewingMarketProductPlacement and GetHousingEditorMode() ~= HOUSING_EDITOR_MODE_PLACEMENT then
                        -- Manually return to Housing Editor Browse mode unless we are left in Placement mode;
                        -- this occurs when the relevant furnishing limit had already been reached or when this
                        -- purchase did not originate from in-house placement preview.
                        ZO_ReturnToHousingEditorBrowseMode()
                    end
                end,
            },
        },
    })

    ZO_Dialogs_RegisterCustomDialog(DIALOG_FLOW[FLOW_FAILED],
    {
        setup = function(dialog)
            local data1, data2, data3 = self:GetMarketProductPricingHeaderData()
            local displayData =
            {
                data1 = data1,
                data2 = data2,
                data3 = data3,
                purchaseResult = dialog.data.purchaseResult,
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
            text = GetString(SI_TRANSACTION_FAILED_TITLE),
        },
        mainText =
        {
            text = function(dialog)
                return GetString("SI_MARKETPURCHASABLERESULT", dialog.data.purchaseResult)
            end
        },
        canQueue = true,
        mustChoose = true,
        buttons =
        {
            {
                text = function(dialog)
                    if ZO_MarketDialogs_Shared_ShouldRestartGiftFlow(dialog.data.purchaseResult) then
                        return GetString(SI_MARKET_CONFIRM_PURCHASE_RESTART_KEYBIND_LABEL)
                    else
                        return GetString(SI_MARKET_CONFIRM_PURCHASE_BACK_KEYBIND_LABEL)
                    end
                end,
                callback = function(dialog)
                    if ZO_MarketDialogs_Shared_ShouldRestartGiftFlow(dialog.data.purchaseResult) then
                        self:SetFlowPosition(FLOW_CONFIRMATION)
                    else
                        self:EndPurchase()
                    end
                end,
                keybind = "DIALOG_NEGATIVE"
            }
        },
    })

    ZO_Dialogs_RegisterCustomDialog(DIALOG_FLOW[FLOW_CONFIRMATION_PARTIAL_BUNDLE],
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
            text = SI_MARKET_GIFTING_BUNDLE_PARTS_OWNED_TEXT
        },
        canQueue = true,
        mustChoose = true,
        buttons =
        {
            {
                text = SI_MARKET_PURCHASE_ERROR_CONTINUE,
                callback = function(dialog)
                    self.doMoveToNextFlowPosition = true
                    self:MoveToNextFlowPosition({ shouldSendPartiallyOwnedGift = true })
                end,
                keybind = "DIALOG_PRIMARY",
            },
            {
                text = SI_DIALOG_EXIT,
                callback = function(dialog)
                    RespondToSendPartiallyOwnedGift(false)
                    self:EndPurchase()
                end,
                keybind = "DIALOG_NEGATIVE",
            },
        },
    })

    ZO_Dialogs_RegisterCustomDialog(SELECT_HOUSE_TEMPLATE_DIALOG,
    {
        setup = function(...) self:MarketSelectHouseTemplateDialogSetup(...) end,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        title =
        {
            text = SI_MARKET_SELECT_HOUSE_TEMPLATE_TITLE,
        },
        mainText =
        {
            text = function(dialog)
                local houseId = GetMarketProductHouseId(self.marketProductData.marketProductId)
                if houseId > 0 then
                    local houseCollectibleId = GetCollectibleIdForHouse(houseId)
                    local houseDisplayName = GetCollectibleName(houseCollectibleId)
                    return zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, ZO_SELECTED_TEXT:Colorize(houseDisplayName))
                else
                    internalassert(false, string.format("MarketProduct (%s) is not a house and should not be passed into house template selection dialog.", tostring(self.marketProductData.marketProductId) or "nil"))
                end
            end
        },
        canQueue = true,
        parametricList = {}, --we'll generate the entries on setup
        blockDialogReleaseOnPress = true, -- We need to manually control when we release so we can use the select keybind to activate entries
        mustChoose = true,
        onHidingCallback = function(dialog)
            local targetData = dialog.entryList:GetTargetData()
            if targetData and targetData.dropdownEntry then
                local targetControl = dialog.entryList:GetTargetControl()
                local dropdown = targetControl.dropdown
                dropdown:Deactivate()
            end
        end,
        finishedCallback = function()
            if g_dialogDiscountPercentControl then
                g_dialogDiscountPercentControl:SetHidden(true)
            end
        end,
        buttons =
        {
            -- Select Button
            {
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_GAMEPAD_SELECT_OPTION),
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData.dropdownEntry then
                        local targetControl = dialog.entryList:GetTargetControl()
                        local dropdown = targetControl.dropdown
                        dropdown:Activate()
                    end
                end,
            },
            --Back
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_MARKET_CONFIRM_PURCHASE_BACK_KEYBIND_LABEL,
                callback = function(dialog)
                    -- release the dialog first to avoid issue where the parametric list can refresh
                    -- but EndPurchase will wipe out important state, like self.marketProductData
                    ZO_Dialogs_ReleaseDialogOnButtonPress(SELECT_HOUSE_TEMPLATE_DIALOG)

                    -- if we have pushed the purchase scene, then we need to hide it
                    SCENE_MANAGER:Hide(ZO_GAMEPAD_MARKET_PURCHASE_SCENE_NAME)

                    self:ResetState()
                end,
            },
            --Confirm
            {
                keybind = "DIALOG_SECONDARY",
                text = SI_MARKET_SELECT_HOUSE_TEMPLATE_REVIEW_PURCHASE,
                clickSound = SOUNDS.DIALOG_ACCEPT,
                callback =  function(dialog)
                    -- release the dialog first to avoid issue where the parametric list can refresh
                    -- but EndPurchase will wipe out important state, like self.marketProductData
                    ZO_Dialogs_ReleaseDialogOnButtonPress(SELECT_HOUSE_TEMPLATE_DIALOG)

                    if self.purchaseParams then
                        local selectedTemplateData = self:GetSelectedHouseTemplateMarketProductData()
                        local marketProductData = ZO_MarketProductData:New(selectedTemplateData.marketProductId)
                        if self.isGift then
                            self:BeginGiftPurchase(marketProductData, self.purchaseParams.isPurchaseFromIngame, self.purchaseParams.onPurchaseSuccessCallback, self.purchaseParams.onPurchaseEndCallback)
                        else
                            self:BeginPurchase(marketProductData, self.purchaseParams.isPurchaseFromIngame, self.purchaseParams.onPurchaseSuccessCallback, self.purchaseParams.onPurchaseEndCallback)
                        end
                    end
                end,
            },
        },
    })
end

function ZO_GamepadMarketPurchaseManager:GetSelectedHouseTemplateMarketProductData()
    if self.houseSelectionInfo.isHouseMarketProduct then
        for index, data in pairs(self.houseSelectionInfo.houseTemplateDataList) do
            local houseTemplateData = self.houseSelectionInfo.houseTemplateDataList[index]
            local currencyType, marketData = next(houseTemplateData.marketPurchaseOptions)
            if not self.houseSelectionInfo.selectedTemplateId and index == self.houseSelectionInfo.defaultHouseTemplateIndex or self.houseSelectionInfo.selectedTemplateId and marketData and marketData.houseTemplateId == self.houseSelectionInfo.selectedTemplateId then
                return marketData
            end
        end
    end

    return nil
end

function ZO_GamepadMarketPurchaseManager:GetMarketProductPricingHeaderData(updateDiscountPercentParentControl)
    -- self.quantity must be valid if specified. (See CC#15606)
    local quantity = self.quantity or 1

    local priceData
    if self.houseSelectionInfo and self.houseSelectionInfo.isHouseMarketProduct then
        local selectedMarketData = self:GetSelectedHouseTemplateMarketProductData()
        priceData =
        {
            currencyType = selectedMarketData and selectedMarketData.currencyType,
            cost = selectedMarketData and selectedMarketData.cost,
            costAfterDiscount = selectedMarketData and selectedMarketData.costAfterDiscount,
            discountPercent = selectedMarketData and selectedMarketData.discountPercent,
            esoPlusCost = selectedMarketData and selectedMarketData.esoPlusCost,
        }
    else
        local currencyType, cost, costAfterDiscount, discountPercent, esoPlusCost = self.marketProductData:GetMarketProductPricingByPresentation()
        priceData =
        {
            currencyType = currencyType,
            cost = cost,
            costAfterDiscount = costAfterDiscount,
            discountPercent = discountPercent,
            esoPlusCost = esoPlusCost,
        }
    end

    if priceData.cost then
        priceData.cost = priceData.cost * quantity
    end
    if priceData.costAfterDiscount then
        priceData.costAfterDiscount = priceData.costAfterDiscount * quantity
    end
    if priceData.esoPlusCost then
        priceData.esoPlusCost = priceData.esoPlusCost * quantity
    end

    local hasNormalCost = priceData.cost ~= nil
    local hasEsoPlusCost
    if self.isGift then
        hasEsoPlusCost = false -- gifts aren't eligible for ESO Plus pricing
    else
        hasEsoPlusCost = priceData.esoPlusCost ~= nil and IsEligibleForEsoPlusPricing()
    end

    local data1 = GetAvailableCurrencyHeaderData(priceData.currencyType)

    local data2
    local data3
    if hasNormalCost then
        if not hasEsoPlusCost and priceData.discountPercent > 0 then
            data2 = GetProductCostHeaderData(priceData.cost, priceData.currencyType, hasEsoPlusCost, priceData.discountPercent, updateDiscountPercentParentControl)
            data3 = GetProductCostHeaderData(priceData.costAfterDiscount, priceData.currencyType, hasEsoPlusCost)
        else
            data2 = GetProductCostHeaderData(priceData.costAfterDiscount, priceData.currencyType, hasEsoPlusCost)
            if hasEsoPlusCost then
                data3 = GetProductEsoPlusCostHeaderData(priceData.esoPlusCost, priceData.currencyType)
            end
        end
    elseif hasEsoPlusCost then
        data2 = GetProductEsoPlusCostHeaderData(priceData.esoPlusCost, priceData.currencyType)
    end

    return data1, data2, data3
end

local g_dialogDiscountPercentControl = nil
function ZO_GamepadMarketPurchaseManager:UpdateDiscountPercentDisplay(discountPercent)
    if g_dialogDiscountPercentParentControl and discountPercent and discountPercent > 0 then
        if g_dialogDiscountPercentControl then
            g_dialogDiscountPercentControl:SetParent(g_dialogDiscountPercentParentControl)
        else
            g_dialogDiscountPercentControl = CreateControlFromVirtual("ZO_MarketDialogDiscountPercent", g_dialogDiscountPercentParentControl, "ZO_MarketTextCallout_Gamepad")
            g_dialogDiscountPercentControl:SetFont("ZoFontGamepad42")
            local backgroundControl = g_dialogDiscountPercentControl:GetNamedChild("Background")
            local r, g, b = ZO_MARKET_PRODUCT_ON_SALE_COLOR:UnpackRGB()
            local TEXT_CALLOUT_BACKGROUND_ALPHA = 0.9
            backgroundControl:GetNamedChild("Center"):SetColor(r, g, b, TEXT_CALLOUT_BACKGROUND_ALPHA)
            backgroundControl:GetNamedChild("Left"):SetColor(r, g, b, TEXT_CALLOUT_BACKGROUND_ALPHA)
            backgroundControl:GetNamedChild("Right"):SetColor(r, g, b, TEXT_CALLOUT_BACKGROUND_ALPHA)
        end

        g_dialogDiscountPercentControl:ClearAnchors()
        g_dialogDiscountPercentControl:SetAnchor(RIGHT, g_dialogDiscountPercentParentControl, LEFT, -20, 0)

        local discountPercentText = zo_strformat(SI_MARKET_DISCOUNT_PRICE_PERCENT_FORMAT, discountPercent)
        g_dialogDiscountPercentControl:SetText(discountPercentText)
        g_dialogDiscountPercentControl:SetHidden(false)
    else
        if g_dialogDiscountPercentControl then
            g_dialogDiscountPercentControl:SetHidden(true)
        end
    end
end

function ZO_GamepadMarketPurchaseManager:MarketPurchaseConfirmationDialogSetup(dialog)
    self.quantity = self.quantity or 1
    self:BuildMarketPurchaseConfirmationDialogEntries(dialog)

    g_dialogDiscountPercentParentControl = nil
    local UPDATE_DISCOUNT_PERCENT_PARENT = true
    local data1, data2, data3 = self:GetMarketProductPricingHeaderData(UPDATE_DISCOUNT_PERCENT_PARENT)

    local displayData =
    {
        data1 = data1,
        data2 = data2,
        data3 = data3,
    }
    local DONT_LIMIT_NUM_ENTRIES = nil
    dialog.setupFunc(dialog, DONT_LIMIT_NUM_ENTRIES, displayData)

    local discountPercent = select(4, GetMarketProductPricingByPresentation(self.marketProductData:GetId()))
    self:UpdateDiscountPercentDisplay(discountPercent)
end

function ZO_GamepadMarketPurchaseManager:MarketSelectHouseTemplateDialogSetup(dialog)
    local marketProductId = self.marketProductData:GetId()
    local isHouseMarketProduct, houseTemplateDataList, defaultHouseTemplateIndex = ZO_MarketProduct_GetMarketProductHouseTemplateDataList(marketProductId, function(...) return { GetActiveMarketProductListingsForHouseTemplate(...) } end)

    self.houseSelectionInfo =
    {
        isHouseMarketProduct = isHouseMarketProduct,
        houseTemplateDataList = houseTemplateDataList,
        defaultHouseTemplateIndex = defaultHouseTemplateIndex,
    }

    self:BuildMarketSelectHouseTemplateDialogEntries(dialog)

    g_dialogDiscountPercentParentControl = nil
    local UPDATED_DISCOUNT_PERCENT_PARENT = true
    local data1, data2, data3 = self:GetMarketProductPricingHeaderData(UPDATED_DISCOUNT_PERCENT_PARENT)

    local displayData =
    {
        data1 = data1,
        data2 = data2,
        data3 = data3,
    }
    local DONT_LIMIT_NUM_ENTRIES = nil
    dialog.setupFunc(dialog, DONT_LIMIT_NUM_ENTRIES, displayData)
end

do
    local parametricDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
    local chooseAsGiftDropdownEntryData
    function ZO_GamepadMarketPurchaseManager:GetOrCreateChooseAsGiftDropdownEntryData()
        if chooseAsGiftDropdownEntryData == nil then
            chooseAsGiftDropdownEntryData = ZO_GamepadEntryData:New()
            chooseAsGiftDropdownEntryData.dropdownEntry = true
            chooseAsGiftDropdownEntryData.setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                local dropdown = control.dropdown
                --Order matters. Make sure to register the dialog dropdown BEFORE clearing the items
                SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(chooseAsGiftDropdownEntryData.dialog, dropdown)
                dropdown:SetSortsItems(false)
                dropdown:ClearItems()

                local function SetAsGift(isGift)
                    if isGift ~= self.isGift then
                        self.isGift = isGift
                        local dialog = chooseAsGiftDropdownEntryData.dialog
                        self:BuildMarketPurchaseConfirmationDialogEntries(dialog)
                        ZO_GenericParametricListGamepadDialogTemplate_RebuildEntryList(dialog)

                        local data1, data2, data3 = self:GetMarketProductPricingHeaderData()
                        local headerData =
                        {
                            data1 = data1,
                            data2 = data2,
                            data3 = data3,
                        }
                        ZO_GenericGamepadDialog_RefreshHeaderData(dialog, headerData)

                        GAMEPAD_TOOLTIPS:LayoutMarketProductListing(GAMEPAD_LEFT_DIALOG_TOOLTIP, self.marketProductData:GetId(), self.marketProductData:GetPresentationIndex())
                        ZO_GenericGamepadDialog_ShowTooltip(parametricDialog)
                    end
                end

                local forMeEntry = dropdown:CreateItemEntry(GetString(SI_MARKET_CONFIRM_PURCHASE_FOR_ME_LABEL), function() SetAsGift(false) end)
                forMeEntry.expectedResult = self.marketProductData:CouldPurchase()
                forMeEntry.enabled = forMeEntry.expectedResult == MARKET_PURCHASE_RESULT_SUCCESS

                local purchaseWarningStrings = {}
                ZO_MARKET_MANAGER:AddMarketProductPurchaseWarningStringsToTable(self.marketProductData, purchaseWarningStrings)
                forMeEntry.warningStrings = purchaseWarningStrings
                dropdown:AddItem(forMeEntry)

                local asGiftEntry = dropdown:CreateItemEntry(GetString(SI_MARKET_CONFIRM_PURCHASE_AS_GIFT_LABEL), function() SetAsGift(true) end)
                asGiftEntry.expectedResult = self.marketProductData:CouldGift()
                asGiftEntry.enabled = asGiftEntry.expectedResult == MARKET_PURCHASE_RESULT_SUCCESS
                dropdown:AddItem(asGiftEntry)

                dropdown:UpdateItems()

                local entryToSelect = self.isGift and asGiftEntry or forMeEntry
                local IGNORE_CALLBACK = true
                dropdown:TrySelectItemByData(entryToSelect, IGNORE_CALLBACK)

                local FORCE_UPDATE = true
                local lastTimeLeftS
                local function UpdateGracePeriod(forceUpdate)
                    local timeLeftS = GetGiftingGracePeriodTime()
                    if forceUpdate or timeLeftS ~= lastTimeLeftS then
                        lastTimeLeftS = timeLeftS
                        local timeLeftString = ZO_FormatTime(lastTimeLeftS, TIME_FORMAT_STYLE_SHOW_LARGEST_TWO_UNITS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
                        local tooltipText = zo_strformat(SI_MARKET_GIFTING_GRACE_PERIOD_TOOLTIP, timeLeftString)

                         GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_DIALOG_TOOLTIP, tooltipText)
                         ZO_GenericGamepadDialog_ShowTooltip(parametricDialog)
                    end
                end

                local isGracePeriod = asGiftEntry.expectedResult == MARKET_PURCHASE_RESULT_GIFTING_GRACE_PERIOD_ACTIVE

                local OnUpdate
                if isGracePeriod then
                    function OnUpdate()
                        if parametricDialog.shouldShowTooltip then
                            UpdateGracePeriod()
                        end
                    end
                else
                    OnUpdate = nil
                end
                control:SetHandler("OnUpdate", OnUpdate)

                dropdown:RegisterCallback("OnItemSelected", function(itemControl, itemData)
                    if itemData.expectedResult ~= MARKET_PURCHASE_RESULT_SUCCESS then
                        if isGracePeriod then
                            UpdateGracePeriod(FORCE_UPDATE)
                        else
                            GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_DIALOG_TOOLTIP, GetString("SI_MARKETPURCHASABLERESULT", itemData.expectedResult))
                            ZO_GenericGamepadDialog_ShowTooltip(parametricDialog)
                        end
                    elseif itemData.warningStrings and #itemData.warningStrings > 0 then
                        local tooltipText = table.concat(itemData.warningStrings, "\n\n")
                        GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_DIALOG_TOOLTIP, tooltipText)
                        ZO_GenericGamepadDialog_ShowTooltip(parametricDialog)
                    end
                end)

                dropdown:RegisterCallback("OnItemDeselected", function(itemControl, itemData)
                    GAMEPAD_TOOLTIPS:LayoutMarketProductListing(GAMEPAD_LEFT_DIALOG_TOOLTIP, self.marketProductData:GetId(), self.marketProductData:GetPresentationIndex())
                    ZO_GenericGamepadDialog_ShowTooltip(parametricDialog)
                end)

                dropdown:SetNarrationTooltipType(function(selectedItemData)
                    if selectedItemData then
                        if selectedItemData.expectedResult ~= MARKET_PURCHASE_RESULT_SUCCESS  or (selectedItemData.warningStrings and #selectedItemData.warningStrings > 0) then
                            return GAMEPAD_LEFT_DIALOG_TOOLTIP
                        end
                    end
                end)

                local isValid, result
                if self.isGift then
                    isValid, result = self.marketProductData:IsGiftQuantityValid(self.quantity)
                else
                    isValid, result = self.marketProductData:IsPurchaseQuantityValid(self.quantity)
                end
                if isValid then
                    GAMEPAD_TOOLTIPS:LayoutMarketProductListing(GAMEPAD_LEFT_DIALOG_TOOLTIP, self.marketProductData:GetId(), self.marketProductData:GetPresentationIndex())
                    ZO_GenericGamepadDialog_ShowTooltip(self)
                else
                    local errorText
                    if result == MARKET_PURCHASE_RESULT_EXCEEDS_MAX_QUANTITY then
                        errorText = zo_strformat(GetString("SI_MARKETPURCHASABLERESULT", result), self.maxQuantity)
                    else
                        errorText = GetString("SI_MARKETPURCHASABLERESULT", result)
                    end
                    GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_DIALOG_TOOLTIP, errorText)
                    ZO_GenericGamepadDialog_ShowTooltip(self)
                    end
            end
            chooseAsGiftDropdownEntryData.narrationText = ZO_GetDefaultParametricListDropdownNarrationText
        end
        return chooseAsGiftDropdownEntryData
    end
end

do
    local parametricDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
    local selectHouseTemplateDropdownEntryData
    function ZO_GamepadMarketPurchaseManager:GetOrCreateSelectHouseTemplateDropdownEntryData()
        if selectHouseTemplateDropdownEntryData == nil then
            selectHouseTemplateDropdownEntryData = ZO_GamepadEntryData:New()
            selectHouseTemplateDropdownEntryData.dropdownEntry = true
            selectHouseTemplateDropdownEntryData.setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                local dropdown = control.dropdown
                --Order matters. Make sure to register the dialog dropdown BEFORE clearing the items
                SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(selectHouseTemplateDropdownEntryData.dialog, dropdown)
                dropdown:SetSortsItems(false)
                dropdown:ClearItems()

                local function SetSelectedTemplateId(templateId)
                    if self.houseSelectionInfo.selectedTemplateId ~= templateId then
                        self.houseSelectionInfo.selectedTemplateId = templateId
                        local dialog = selectHouseTemplateDropdownEntryData.dialog
                        self:BuildMarketSelectHouseTemplateDialogEntries(dialog)
                        ZO_GenericParametricListGamepadDialogTemplate_RebuildEntryList(dialog)

                        local data1, data2, data3 = self:GetMarketProductPricingHeaderData()
                        local headerData =
                        {
                            data1 = data1,
                            data2 = data2,
                            data3 = data3,
                        }
                        ZO_GenericGamepadDialog_RefreshHeaderData(dialog, headerData)
                        --Re-narrate the header when the price changes
                        local NARRATE_HEADER = true
                        SCREEN_NARRATION_MANAGER:QueueDialog(dialog, NARRATE_HEADER)
                    end
                end

                local selectedHouseTemplateEntryData
                for index, houseTemplateData in ipairs(self.houseSelectionInfo.houseTemplateDataList) do
                    local currencyType, marketData = next(houseTemplateData.marketPurchaseOptions)
                    if houseTemplateData.name and marketData and ((self.isGift and marketData.isGiftable) or (not self.isGift and not marketData.isHouseOwned)) then
                        local formattedName = zo_strformat(SI_MARKET_PRODUCT_HOUSE_TEMPLATE_NAME_FORMAT, houseTemplateData.name)
                        local entry = dropdown:CreateItemEntry(formattedName, function() SetSelectedTemplateId(marketData.houseTemplateId) end)
                        entry.data = houseTemplateData

                        if not self.houseSelectionInfo.selectedTemplateId and index == self.houseSelectionInfo.defaultHouseTemplateIndex or self.houseSelectionInfo.selectedTemplateId == marketData.houseTemplateId then
                            selectedHouseTemplateEntryData = entry
                        end

                        dropdown:AddItem(entry)
                    end
                end

                dropdown:UpdateItems()
                local IGNORE_CALLBACK = true
                if selectedHouseTemplateEntryData then
                    dropdown:TrySelectItemByData(selectedHouseTemplateEntryData, IGNORE_CALLBACK)
                else
                    if dropdown:GetNumItems() > 0 then
                        dropdown:SelectItemByIndex(1)
                    end
                end

                local selectedData = dropdown:GetSelectedItemData()
                if selectedData and selectedData.data and selectedData.data.marketPurchaseOptions then
                    local selectedIndex, houseData = next(selectedData.data.marketPurchaseOptions)
                    if houseData then
                        GAMEPAD_TOOLTIPS:SetStatusLabelText(GAMEPAD_LEFT_DIALOG_TOOLTIP, GetString(SI_HOUSE_INFORMATION_TITLE))
                        GAMEPAD_TOOLTIPS:LayoutHouseTemplateTooltip(GAMEPAD_LEFT_DIALOG_TOOLTIP, houseData.houseId, houseData.houseTemplateId)
                        ZO_GenericGamepadDialog_ShowTooltip(parametricDialog)

                        self:UpdateDiscountPercentDisplay(selectedData.discountPercent)
                    else
                        ZO_GenericGamepadDialog_HideTooltip(parametricDialog)
                    end
                end
            end
            selectHouseTemplateDropdownEntryData.narrationText = ZO_GetDefaultParametricListDropdownNarrationText
            selectHouseTemplateDropdownEntryData.narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP
        end
        return selectHouseTemplateDropdownEntryData
    end
end

do
    local recipientNameEntryData
    function ZO_GamepadMarketPurchaseManager:GetOrCreateRecipientNameEntryData()
        if recipientNameEntryData == nil then
            recipientNameEntryData = ZO_GamepadEntryData:New()
            recipientNameEntryData.recipientNameEntry = true

            recipientNameEntryData.textChangedCallback = function(control)
                self.recipientDisplayName = control:GetText()
                ZO_GenericGamepadDialog_RefreshKeybinds(recipientNameEntryData.dialog)
            end

            recipientNameEntryData.setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                control.highlight:SetHidden(not selected)

                control.editBoxControl.textChangedCallback = data.textChangedCallback

                control.editBoxControl:SetDefaultText(zo_strformat(SI_REQUEST_DISPLAY_NAME_INSTRUCTIONS, ZO_GetPlatformAccountLabel()))
                if self.recipientDisplayName then
                    control.editBoxControl:SetText(self.recipientDisplayName)
                end
            end

            recipientNameEntryData.narrationText = ZO_GetDefaultParametricListEditBoxNarrationText
        end
        return recipientNameEntryData
    end
end

do
    local giftMessageEntryData
    function ZO_GamepadMarketPurchaseManager:GetOrCreateGiftMessageEntryData()
        if giftMessageEntryData == nil then
            giftMessageEntryData = ZO_GamepadEntryData:New()
            giftMessageEntryData.messageEntry = true

            giftMessageEntryData.textChangedCallback = function(control)
                self.giftMessage = control:GetText()
            end

            giftMessageEntryData.setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                control.highlight:SetHidden(not selected)

                control.editBoxControl.textChangedCallback = data.textChangedCallback
                
                control.editBoxControl:SetDefaultText(GetString(SI_GIFT_INVENTORY_REQUEST_GIFT_MESSAGE_TEXT))
                control.editBoxControl:SetMaxInputChars(GIFT_NOTE_MAX_LENGTH)
                control.editBoxControl:SetText(self.giftMessage)
            end

            giftMessageEntryData.narrationText = ZO_GetDefaultParametricListEditBoxNarrationText
        end
        return giftMessageEntryData
    end
end

do
    local itemQuantityEntryData
    function ZO_GamepadMarketPurchaseManager:GetOrCreateItemQuantityEntryData()
        if itemQuantityEntryData == nil then
            itemQuantityEntryData = ZO_GamepadEntryData:New()
            itemQuantityEntryData.quantityEntry = true

            itemQuantityEntryData.textChangedCallback = function(control)
                local maximumControl = itemQuantityEntryData.control.maximumControl
                maximumControl:SetColor(ZO_DEFAULT_TEXT:UnpackRGB())
                self.quantity = tonumber(control:GetText())

                local isValid, result
                if self.isGift then
                    isValid, result = self.marketProductData:IsGiftQuantityValid(self.quantity)
                else
                    isValid, result = self.marketProductData:IsPurchaseQuantityValid(self.quantity)
                end
                if isValid then
                    GAMEPAD_TOOLTIPS:LayoutMarketProductListing(GAMEPAD_LEFT_DIALOG_TOOLTIP, self.marketProductData:GetId(), self.marketProductData:GetPresentationIndex())
                    ZO_GenericGamepadDialog_ShowTooltip(self)
                else
                    local errorText
                    if result == MARKET_PURCHASE_RESULT_EXCEEDS_MAX_QUANTITY then
                        errorText = zo_strformat(GetString("SI_MARKETPURCHASABLERESULT", result), self.maxQuantity)
                        maximumControl:SetColor(ZO_ERROR_COLOR:UnpackRGB())
                    else
                        errorText = GetString("SI_MARKETPURCHASABLERESULT", result)
                    end
                    GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_DIALOG_TOOLTIP, errorText)
                    ZO_GenericGamepadDialog_ShowTooltip(self)
                end

                local data1, data2, data3 = self:GetMarketProductPricingHeaderData()
                local headerData =
                {
                    data1 = data1,
                    data2 = data2,
                    data3 = data3,
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
                control.highlight:SetHidden(not selected)
                control.editBoxControl.textChangedCallback = data.textChangedCallback
                control.editBoxControl:SetText(self.quantity or 1)
                control.editBoxControl.focusLostCallback = data.focusLostCallback
                local maxQuantity = self.maxQuantity
                if maxQuantity then
                    -- Maximum quantity of greater than one requires input and maximum limit label.
                    -- This parametric entry is not added for market products with a maximum quantity of zero or one.
                    control.maximumControl:SetText(zo_strformat(SI_MARKET_CONFIRM_PURCHASE_MAXIMUM_LABEL, maxQuantity))
                    control.maximumControl:SetHidden(false)
                else
                    -- No maximum quantity requires input but no maximum limit label.
                    control.maximumControl:SetHidden(true)
                end
            end

            itemQuantityEntryData.narrationText = function(entryData, entryControl)
                local editBoxText = ZO_FormatEditBoxNarrationText(entryControl.editBoxControl)
                if self.maxQuantity then
                    return { editBoxText, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_MARKET_CONFIRM_PURCHASE_MAXIMUM_LABEL, self.maxQuantity)) }
                else
                    return editBoxText
                end
            end
        end

        return itemQuantityEntryData
    end
end

function ZO_GamepadMarketPurchaseManager:BuildMarketPurchaseConfirmationDialogEntries(dialog)
    local parametricListEntries = dialog.info.parametricList
    ZO_ClearNumericallyIndexedTable(parametricListEntries)

    self.quantity = 1
    if self.isGift then
        self.maxQuantity = self.marketProductData:GetMaxGiftQuantity()
    else
        self.maxQuantity = self.marketProductData:GetMaxPurchaseQuantity()
    end

    if self.maxQuantity > 1 then
        local itemQuantityEntry =
        {
            header = GetString(SI_MARKET_CONFIRM_PURCHASE_QUANTITY_LABEL),
            headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",
            template = "ZO_Gamepad_MarketDialog_Quantity",
            entryData = self:GetOrCreateItemQuantityEntryData(),
        }

        table.insert(parametricListEntries, itemQuantityEntry)
    end

    local chooseAsGiftDropdown =
    {
        header = GetString(SI_MARKET_CONFIRM_PURCHASE_RECIPIENT_SELECTOR_HEADER),
        template = "ZO_GamepadDropdownItem",
        entryData = self:GetOrCreateChooseAsGiftDropdownEntryData(),
    }

    table.insert(parametricListEntries, chooseAsGiftDropdown)

    if self.isGift then
        local recipientNameEntry =
        {
            template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem",
            entryData = self:GetOrCreateRecipientNameEntryData(),
        }

        table.insert(parametricListEntries, recipientNameEntry)

        local giftMessageEntry =
        {
            template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem_Multiline",
            entryData = self:GetOrCreateGiftMessageEntryData(),
        }

        table.insert(parametricListEntries, giftMessageEntry)
    end
end

function ZO_GamepadMarketPurchaseManager:BuildMarketSelectHouseTemplateDialogEntries(dialog)
    local parametricListEntries = dialog.info.parametricList
    ZO_ClearNumericallyIndexedTable(parametricListEntries)

    local selectHouseTemplateDropdown =
    {
        header = GetString(SI_MARKET_SELECT_HOUSE_TEMPLATE_LABEL),
        template = "ZO_GamepadDropdownItem",
        entryData = self:GetOrCreateSelectHouseTemplateDropdownEntryData(),
    }

    table.insert(parametricListEntries, selectHouseTemplateDropdown)
end

function ZO_GamepadMarketPurchaseManager:MarketPurchaseConfirmationFreeTrialDialogSetup(dialog)
    dialog.setupFunc(dialog)
end

-- onPurchaseSuccessCallback is only called on a successful transfer, onPurchaseEndCallback is called on transaction success, failure, and decline
-- onPurchaseEndCallback passes a bool value for whether the confirmation scene was reached (true) or not (false)
function ZO_GamepadMarketPurchaseManager:BeginPurchaseBase(marketProductData, isGift, isPurchaseFromIngame, onPurchaseSuccessCallback, onPurchaseEndCallback)
    self:ResetState() -- make sure nothing is carried over from the last purchase attempt

    self.marketProductData = marketProductData
    self.isGift = isGift
    self.purchaseFromIngame = isPurchaseFromIngame
    self.onPurchaseSuccessCallback = onPurchaseSuccessCallback
    self.onPurchaseEndCallback = onPurchaseEndCallback
    self.isPreviewingMarketProductPlacement = IsHousingEditorPreviewingMarketProductPlacement()
    self.itemName = marketProductData:GetColorizedDisplayName()

    local selectionSound = isGift and SOUNDS.MARKET_GIFT_SELECTED or SOUNDS.MARKET_PURCHASE_SELECTED
    PlaySound(selectionSound)
    OnMarketStartPurchase(marketProductData:GetId())
end

do
    local AS_PURCHASE = false
    local function GetPurchaseErrorInfo(...)
        return ZO_MARKET_MANAGER:GetMarketProductPurchaseErrorInfo(...)
    end

    function ZO_GamepadMarketPurchaseManager:BeginPurchase(marketProductData, isPurchaseFromIngame, onPurchaseSuccessCallback, onPurchaseEndCallback)
        if ZO_MarketProduct_IsHouseCollectible(marketProductData:GetId()) then
            self.marketProductData = marketProductData
            self.purchaseParams =
            {
                marketProductData = marketProductData,
                isPurchaseFromIngame = isPurchaseFromIngame,
                onPurchaseSuccessCallback = onPurchaseSuccessCallback,
                onPurchaseEndCallback = onPurchaseEndCallback
            }
            self.isGift = AS_PURCHASE
            self:ShowHouseTemplateSelectionDialog(SELECT_HOUSE_TEMPLATE_DIALOG)
        else
            self:BeginPurchaseBase(marketProductData, AS_PURCHASE, isPurchaseFromIngame, onPurchaseSuccessCallback, onPurchaseEndCallback)
            self:StartPurchaseFlow(GetPurchaseErrorInfo)
        end
    end
end

do
    local AS_GIFT = true
    local function GetGiftErrorInfo(...)
        return ZO_MARKET_MANAGER:GetMarketProductGiftErrorInfo(...)
    end

    function ZO_GamepadMarketPurchaseManager:BeginGiftPurchase(marketProductData, isPurchaseFromIngame, onPurchaseSuccessCallback, onPurchaseEndCallback)
        if ZO_MarketProduct_IsHouseCollectible(marketProductData:GetId()) then
            self.marketProductData = marketProductData
            self.purchaseParams =
            {
                marketProductData = marketProductData,
                isPurchaseFromIngame = isPurchaseFromIngame,
                onPurchaseSuccessCallback = onPurchaseSuccessCallback,
                onPurchaseEndCallback = onPurchaseEndCallback
            }
            self.isGift = AS_GIFT
            self:ShowHouseTemplateSelectionDialog(SELECT_HOUSE_TEMPLATE_DIALOG)
        else
            self:BeginPurchaseBase(marketProductData, AS_GIFT, isPurchaseFromIngame, onPurchaseSuccessCallback, onPurchaseEndCallback)
            self:StartPurchaseFlow(GetGiftErrorInfo)
        end
    end
end

do
    local NO_DIALOG_DATA = nil
    function ZO_GamepadMarketPurchaseManager:StartPurchaseFlow(errorInfoFunction)
        local hasErrors, dialogParams, allowContinue, expectedPurchaseResult = errorInfoFunction(self.marketProductData)

        if expectedPurchaseResult == MARKET_PURCHASE_RESULT_REQUIRES_ESO_PLUS then
            self:ShowFlowDialog("GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_JOIN_ESO_PLUS", NO_DIALOG_DATA, dialogParams)
        elseif expectedPurchaseResult == MARKET_PURCHASE_RESULT_NOT_ENOUGH_VC then
            self:ShowFlowDialog("GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_PURCHASE_CROWNS", NO_DIALOG_DATA, dialogParams)
        elseif expectedPurchaseResult == MARKET_PURCHASE_RESULT_GIFTING_GRACE_PERIOD_ACTIVE then
            self:ShowFlowDialog("GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_GIFTING_GRACE_PERIOD", {}, dialogParams)
        elseif expectedPurchaseResult == MARKET_PURCHASE_RESULT_GIFTING_NOT_ALLOWED then
            self:ShowFlowDialog("GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_GIFTING_NOT_ALLOWED", NO_DIALOG_DATA, dialogParams)
        elseif expectedPurchaseResult == MARKET_PURCHASE_RESULT_PRODUCT_ALREADY_IN_GIFT_INVENTORY then
            self:ShowFlowDialog("GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_ALREADY_HAVE_PRODUCT_IN_GIFT_INVENTORY", NO_DIALOG_DATA, dialogParams)
        elseif not allowContinue then
            self:ShowFlowDialog("GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_EXIT", NO_DIALOG_DATA, dialogParams)
        elseif hasErrors then
            self:SetFlowPosition(FLOW_WARNING, NO_DIALOG_DATA, dialogParams)
        else
            self:SetFlowPosition(FLOW_CONFIRMATION)
        end
    end
end

function ZO_GamepadMarketPurchaseManager:BeginFreeTrialPurchase(marketProductData, isPurchaseFromIngame, onPurchaseSuccessCallback, onPurchaseEndCallback)
    local AS_PURCHASE = false
    self:BeginPurchaseBase(marketProductData, AS_PURCHASE, isPurchaseFromIngame, onPurchaseSuccessCallback, onPurchaseEndCallback)

    self.showRemainingBalance = false
    self:SetFlowPosition(FLOW_CONFIRMATION_ESO_PLUS)
end

function ZO_GamepadMarketPurchaseManager:EndPurchase(isNoChoice)
    local reachedConfirmationScene = self.flowPosition >= FLOW_CONFIRMATION
    local consumablePurchaseSuccessful = self.flowPosition == FLOW_SUCCESS and self.marketProductData:ContainsConsumables()
    if self.onPurchaseEndCallback then
        self.onPurchaseEndCallback(reachedConfirmationScene, consumablePurchaseSuccessful, self.triggerTutorialOnPurchase)
    end

    -- if we have pushed the purchase scene, then we need to hide it
    SCENE_MANAGER:Hide(ZO_GAMEPAD_MARKET_PURCHASE_SCENE_NAME)

    self:ResetState()
end

function ZO_GamepadMarketPurchaseManager:EndPurchaseFromErrorDialog()
    -- if we started the purchase from ingame, then we pushed the purchase scene to avoid keybind conflicts
    SCENE_MANAGER:Hide(ZO_GAMEPAD_MARKET_PURCHASE_SCENE_NAME)

    self:ResetState()
end

function ZO_GamepadMarketPurchaseManager:ResetState()
    self.marketProductData = nil
    self.onPurchaseSuccessCallback = nil
    self.onPurchaseEndCallback = nil
    self.triggerTutorialOnPurchase = nil
    self.flowPosition = FLOW_UNINITIALIZED
    self.doMoveToNextFlowPosition = false
    self.queuedDialogInfo = {}
    self.showRemainingBalance = true
    self.purchaseFromIngame = false
    self.isGift = false
    self.giftMessage = nil
    self.recipientDisplayName = nil
    self.houseSelectionInfo = nil
    self.purchaseParams = nil
    self.quantity = 1
end

function ZO_GamepadMarketPurchaseManager:SetFlowPosition(position, dialogData, dialogParams)
    self.flowPosition = position

    local dialogName = DIALOG_FLOW[position]

    if position == FLOW_UNLOCKED then
        local name = self.marketProductData:GetDisplayName()
        dialogParams =
        {
            titleParams = { name },
            mainTextParams = { ZO_SELECTED_TEXT:Colorize(name) }
        }
    end

    self:ShowFlowDialog(dialogName, dialogData, dialogParams)
end

function ZO_GamepadMarketPurchaseManager:ShowFlowDialog(dialogName, dialogData, dialogParams)
    local shouldPushScene
    if SCENE_MANAGER:IsShowing(ZO_GAMEPAD_MARKET_PURCHASE_SCENE_NAME) then
        shouldPushScene = false
    elseif self.purchaseFromIngame then
        -- from Ingame, the first dialog of any type should push the purchase scene
        shouldPushScene = true
    elseif dialogName == DIALOG_FLOW[FLOW_CONFIRMATION] or dialogName == DIALOG_FLOW[FLOW_CONFIRMATION_ESO_PLUS] then
        -- from InternalIngame, only the first confirmation dialog should push the scene
        shouldPushScene = true
    end

    if shouldPushScene then
        SCENE_MANAGER:Push(ZO_GAMEPAD_MARKET_PURCHASE_SCENE_NAME)
        self.queuedDialogInfo =
        {
            dialogName = dialogName,
            dialogData = dialogData,
            dialogParams = dialogParams,
        }
    else
        ZO_Dialogs_ShowGamepadDialog(dialogName, dialogData, dialogParams)
    end
end

function ZO_GamepadMarketPurchaseManager:ShowHouseTemplateSelectionDialog(dialogName, dialogData, dialogParams)
    local shouldPushScene
    if SCENE_MANAGER:IsShowing(ZO_GAMEPAD_MARKET_PURCHASE_SCENE_NAME) then
        shouldPushScene = false
    else
        shouldPushScene = true
    end

    if shouldPushScene then
        SCENE_MANAGER:Push(ZO_GAMEPAD_MARKET_PURCHASE_SCENE_NAME)
        self.queuedDialogInfo =
        {
            dialogName = dialogName,
            dialogData = dialogData,
            dialogParams = dialogParams,
        }
    else
        ZO_Dialogs_ShowGamepadDialog(dialogName, dialogData, dialogParams)
    end
end

do
    local FLOW_MAPPING =
    {
        [FLOW_WARNING] = FLOW_CONFIRMATION,
        [FLOW_CONFIRMATION] = FLOW_PURCHASING,
        [FLOW_CONFIRMATION_ESO_PLUS] = FLOW_PURCHASING,
        [FLOW_CONFIRMATION_PARTIAL_BUNDLE] = FLOW_PURCHASING,
        [FLOW_PURCHASING] = FLOW_SUCCESS,
    }
    function ZO_GamepadMarketPurchaseManager:MoveToNextFlowPosition(dialogData)
        if self.doMoveToNextFlowPosition then
            local nextPosition = FLOW_MAPPING[self.flowPosition] or self.flowPosition + 1
            self:SetFlowPosition(nextPosition, dialogData)
            self.doMoveToNextFlowPosition = false
        end
    end
end
