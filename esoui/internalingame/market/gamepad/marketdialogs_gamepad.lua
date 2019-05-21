local FLOW_UNINITIALIZED = 0
local FLOW_WARNING = 1
local FLOW_CONFIRMATION = 2
local FLOW_CONFIRMATION_ESO_PLUS = 3
local FLOW_PURCHASING = 4
local FLOW_SUCCESS = 5
local FLOW_FAILED = 6

local DIALOG_FLOW =
{
    [FLOW_WARNING] = "GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_CONTINUE",
    [FLOW_CONFIRMATION] = "GAMEPAD_MARKET_PURCHASE_CONFIRMATION",
    [FLOW_CONFIRMATION_ESO_PLUS] = "GAMEPAD_MARKET_FREE_TRIAL_PURCHASE_CONFIRMATION",
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
    isGamepad = true,
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

local function GetProductCostHeaderData(cost, marketCurrencyType, hasEsoPlusCost)

    return  {
                value = function(control)
                    local displayOptions
                    if hasEsoPlusCost then
                        displayOptions =
                        {
                            iconInheritColor = true,
                            color = ZO_DEFAULT_TEXT,
                            strikethroughCurrencyAmount = true,
                        }
                    end
                    ZO_CurrencyControl_SetSimpleCurrency(control, ZO_Currency_MarketCurrencyToUICurrency(marketCurrencyType), cost, ZO_GAMEPAD_MARKET_CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, CURRENCY_IGNORE_HAS_ENOUGH, displayOptions)
                    return true
                end,
                header = function(control)
                    if hasEsoPlusCost then
                        return GetString(SI_GAMEPAD_MARKET_CONFIRM_PURCHASE_NORMAL_COST_LABEL)
                    else
                        return GetString(SI_GAMEPAD_MARKET_CONFIRM_PURCHASE_COST_LABEL)
                    end
                end,
            }
end

local function GetProductEsoPlusCostHeaderData(cost, marketCurrencyType)
    return  {
                value = function(control)
                    local displayOptions =
                    {
                        iconInheritColor = true,
                        color = ZO_MARKET_PRODUCT_ESO_PLUS_COLOR,
                    }
                    ZO_CurrencyControl_SetSimpleCurrency(control, ZO_Currency_MarketCurrencyToUICurrency(marketCurrencyType), cost, ZO_GAMEPAD_MARKET_CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, CURRENCY_IGNORE_HAS_ENOUGH, displayOptions)
                    return true
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
        local NO_AMOUNT = nil
        g_buyCrownsTextParams = { mainTextParams = { ZO_Currency_FormatKeyboard(CURT_CROWNS, NO_AMOUNT, ZO_CURRENCY_FORMAT_PLURAL_NAME_ICON), consoleStoreName } }
        
        local OpenConsoleStoreToPurchaseCrowns = function()
            ShowConsoleESOCrownPacksUI()
            self:EndPurchase()
        end

        insufficientFundsButtons[1] =
        {
            text = zo_strformat(SI_OPEN_FIRST_PARTY_STORE_KEYBIND, consoleStoreName),
            callback = OpenConsoleStoreToPurchaseCrowns
        }

        buyCrownsButtons[1] =
        {
            text = zo_strformat(SI_OPEN_FIRST_PARTY_STORE_KEYBIND, consoleStoreName),
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
            text = SI_MARKET_PURCHASE_ERROR_WITH_CONTINUE_TEXT_FORMATTER
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

    ESO_Dialogs["GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_JOIN_ESO_PLUS"] =
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
            {
                text = SI_MARKET_JOIN_ESO_PLUS_CONFIRM_BUTTON_TEXT,
                callback = function()
                    ZO_GamepadMarket_ShowBuyPlusDialog(EndPurchase)
                end,
            },
            defaultMarketBackButton,
        },
        noChoiceCallback = EndPurchaseNoChoice,
        finishedCallback =  function()
                                OnMarketEndPurchase()
                            end,
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
                                self:EndPurchaseFromErrorDialog()
                            end,
    }

    ESO_Dialogs["GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_GIFTING_GRACE_PERIOD"] =
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
            text = SI_MARKET_GIFTING_GRACE_PERIOD_TEXT
        },
        buttons =
        {
            [1] =
            {
                text = SI_MARKET_GIFTING_LOCKED_HELP_KEYBIND,
                callback = function(dialog)
                    ZO_MarketDialogs_Shared_OpenGiftingLockedHelp(dialog)
                    EndPurchase()
                end,
                keybind = "DIALOG_SECONDARY",
            },
            [2] = defaultMarketBackButton,
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
                text = SI_MARKET_GIFTING_LOCKED_HELP_KEYBIND,
                callback = function(dialog)
                    ZO_MarketDialogs_Shared_OpenGiftingLockedHelp(dialog)
                    EndPurchase()
                end,
                keybind = "DIALOG_SECONDARY",
            },
            [2] = defaultMarketBackButton,
        },
        noChoiceCallback = EndPurchaseNoChoice,
        finishedCallback = function()
            OnMarketEndPurchase()
            self:EndPurchaseFromErrorDialog()
        end,
    }

    ESO_Dialogs["GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_ALREADY_HAVE_PRODUCT_IN_GIFT_INVENTORY"] =
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
                text = SI_MARKET_OPEN_GIFT_INVENTORY_KEYBIND_LABEL,
                callback = function(dialog)
                    RequestShowGiftInventory()
                    EndPurchase()
                end,
                keybind = "DIALOG_SECONDARY",
            },
            [2] = defaultMarketBackButton,
        },
        noChoiceCallback = EndPurchaseNoChoice,
        finishedCallback = function()
            OnMarketEndPurchase()
            self:EndPurchaseFromErrorDialog()
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
        },
        title =
        {
            text = SI_MARKET_CONFIRM_PURCHASE_TITLE,
        },
        mainText =
        {
            text = function()
                local stackCount = self.marketProductData:GetStackCount()
                if stackCount > 1 then
                    return zo_strformat(SI_TOOLTIP_ITEM_NAME_WITH_QUANTITY, self.itemName, stackCount)
                else
                    return zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, self.itemName)
                end
            end
        },
        canQueue = true,
        parametricList = {}, --we'll generate the entries on setup
        blockDialogReleaseOnPress = true, -- We need to manually control when we release so we can use the select keybind to activate entries
        mustChoose = true,
        buttons =
        {
            -- Select Button
            {
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_GAMEPAD_SELECT_OPTION),
                enabled = function(dialog)
                    local platform = GetUIPlatform()
                    if platform == UI_PLATFORM_PS4 or platform == UI_PLATFORM_XBOX then
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
                    if targetData.dropdownEntry then
                        local dropdown = targetControl.dropdown
                        dropdown:Activate()
                    elseif targetData.messageEntry and targetControl then
                        targetControl.editBoxControl:TakeFocus()
                    elseif targetData.recipientNameEntry and targetControl then
                        local platform = GetUIPlatform()
                        if platform == UI_PLATFORM_PS4 then
                            --On PS4 the primary action opens the first party dialog to get a playstation id since it can select any player on PS4
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
                                OnMarketEndPurchase()
                                local NOT_NO_CHOICE_CALLBACK = false
                                self:EndPurchase(NOT_NO_CHOICE_CALLBACK)
                                ZO_Dialogs_ReleaseDialogOnButtonPress(DIALOG_FLOW[FLOW_CONFIRMATION])
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
                        if result == GIFT_ACTION_RESULT_SUCCESS then
                            return true
                        else
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
                    else
                        return true
                    end
                end,
                callback =  function(dialog)
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
                                targetControl.editBoxControl:SetText(displayName)
                            end
                        end
                        local INCLUDE_ONLINE_FRIENDS = true
                        local INCLUDE_OFFLINE_FRIENDS = true
                        PLAYER_CONSOLE_INFO_REQUEST_MANAGER:RequestIdFromUserListDialog(OnUserChosen, GetString(SI_GAMEPAD_CONSOLE_SELECT_FOR_SEND_GIFT), INCLUDE_ONLINE_FRIENDS, INCLUDE_OFFLINE_FRIENDS)
                    elseif targetData.messageEntry and targetControl then
                        targetControl.editBoxControl:SetText(GetRandomGiftSendNoteText())
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
            text =  function(dialog)
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
                callback =  function(dialog)
                                OnMarketEndPurchase(self.marketProductData:GetId())
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
        canQueue = true,
        title =
        {
            text = SI_GAMEPAD_MARKET_BUY_PLUS_TITLE
        },
        mainText =
        {
            text = buyPlusMainText
        },
        buttons = buyPlusButtons,
        noChoiceCallback = EndPurchaseNoChoice,
    })

    local LOADING_DELAY_MS = 500 -- delay is in milliseconds
    local function OnMarketPurchaseResult(dialog, result, tutorialTrigger, wasGift)
        EVENT_MANAGER:UnregisterForEvent("GAMEPAD_MARKET_PURCHASING", EVENT_MARKET_PURCHASE_RESULT)

        internalassert(wasGift == self.isGift)

        self.useProductInfo = nil
        local purchaseSucceeded = result == MARKET_PURCHASE_RESULT_SUCCESS
        if not wasGift then
            if tutorialTrigger ~= TUTORIAL_TRIGGER_NONE then
                self.triggerTutorialOnPurchase = tutorialTrigger
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
        EVENT_MANAGER:RegisterForEvent("GAMEPAD_MARKET_PURCHASING", EVENT_MARKET_PURCHASE_RESULT, function(eventId, ...) OnMarketPurchaseResult(dialog, ...) end)
        if not self.isGift then
            self.marketProductData:RequestPurchase()
        else
            self.marketProductData:RequestPurchaseAsGift(self.giftMessage, self.recipientDisplayName)
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
                        local stackCount = self.marketProductData:GetStackCount()
                        if stackCount > 1 then
                            return zo_strformat(SI_MARKET_PURCHASING_TEXT_WITH_QUANTITY, self.itemName, stackCount)
                        else
                            return zo_strformat(SI_MARKET_PURCHASING_TEXT, self.itemName)
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
            text =  function()
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
                local stackCount = self.marketProductData:GetStackCount()
                if self.isGift then
                    if stackCount > 1 then
                        return zo_strformat(SI_MARKET_GIFTING_SUCCESS_TEXT_WITH_QUANTITY, self.itemName, stackCount, ZO_SELECTED_TEXT:Colorize(self.recipientDisplayName))
                    else
                        return zo_strformat(SI_MARKET_GIFTING_SUCCESS_TEXT, self.itemName, ZO_SELECTED_TEXT:Colorize(self.recipientDisplayName))
                    end
                else
                    local mainText
                    if self.useProductInfo then
                        mainText = zo_strformat(self.useProductInfo.transactionCompleteText, self.itemName, stackCount)
                    else
                        if stackCount > 1 then
                            mainText = zo_strformat(SI_MARKET_PURCHASE_SUCCESS_TEXT_WITH_QUANTITY, self.itemName, stackCount)
                        else
                            if not self.isGift and self.marketProductData:GetNumAttachedCollectibles() > 0 then
                                mainText = zo_strformat(SI_MARKET_PURCHASE_SUCCESS_TEXT_WITH_COLLECTIBLE, self.itemName)
                            else
                                mainText = zo_strformat(SI_MARKET_PURCHASE_SUCCESS_TEXT, self.itemName)
                            end
                        end
                    end

                    -- append ESO Plus savings, if any
                    local esoPlusSavingsString = ZO_MarketDialogs_Shared_GetEsoPlusSavingsString(self.marketProductData)
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
                text =  function()
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
                    local marketProductData = self.marketProductData -- cache off the productData, because reset state will clear it
                    -- since we are trying to logout/go to another scene we don't want to trigger any of the scene changes
                    -- or try to show tutorials, however we want to clean up after ourselves
                    -- in case we don't actually logout
                    self:ResetState()
                    ZO_Market_Shared.GoToUseProductLocation(marketProductData)
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
        buttons = {
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
end

function ZO_GamepadMarketPurchaseManager:GetMarketProductPricingHeaderData()
    local currencyType, cost, costAfterDiscount, discountPercent, esoPlusCost = self.marketProductData:GetMarketProductPricingByPresentation()
    local hasNormalCost = cost ~= nil

    local hasEsoPlusCost
    if self.isGift then
        hasEsoPlusCost = false -- gifts aren't eligible for ESO Plus pricing
    else
        hasEsoPlusCost = esoPlusCost ~= nil and IsEligibleForEsoPlusPricing()
    end

    local data1 = GetAvailableCurrencyHeaderData(currencyType)

    local data2
    local data3
    if hasNormalCost then
        data2 = GetProductCostHeaderData(costAfterDiscount, currencyType, hasEsoPlusCost)
        if hasEsoPlusCost then
            data3 = GetProductEsoPlusCostHeaderData(esoPlusCost, currencyType)
        end
    elseif hasEsoPlusCost then
        data2 = GetProductEsoPlusCostHeaderData(esoPlusCost, currencyType)
    end

    return data1, data2, data3
end

function ZO_GamepadMarketPurchaseManager:MarketPurchaseConfirmationDialogSetup(dialog)
    self:BuildMarketPurchaseConfirmationDialogEntries(dialog)

    local data1, data2, data3 = self:GetMarketProductPricingHeaderData()

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
                    ZO_GenericGamepadDialog_HideTooltip(parametricDialog)
                end)
            end
        end
        return chooseAsGiftDropdownEntryData
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

                local platform = ZO_GetPlatformAccountLabel()
                local instructions = zo_strformat(SI_REQUEST_DISPLAY_NAME_INSTRUCTIONS, platform)
                ZO_EditDefaultText_Initialize(control.editBoxControl, instructions)
                if self.recipientDisplayName then
                    control.editBoxControl:SetText(self.recipientDisplayName)
                end
            end
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

                ZO_EditDefaultText_Initialize(control.editBoxControl, GetString(SI_GIFT_INVENTORY_REQUEST_GIFT_MESSAGE_TEXT))
                control.editBoxControl:SetMaxInputChars(GIFT_NOTE_MAX_LENGTH)
                control.editBoxControl:SetText(self.giftMessage)
            end
        end
        return giftMessageEntryData
    end
end

function ZO_GamepadMarketPurchaseManager:BuildMarketPurchaseConfirmationDialogEntries(dialog)
    local parametricListEntries = dialog.info.parametricList
    ZO_ClearNumericallyIndexedTable(parametricListEntries)

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
        self:BeginPurchaseBase(marketProductData, AS_PURCHASE, isPurchaseFromIngame, onPurchaseSuccessCallback, onPurchaseEndCallback)
        self:StartPurchaseFlow(GetPurchaseErrorInfo)
    end
end

do
    local AS_GIFT = true
    local function GetGiftErrorInfo(...)
        return ZO_MARKET_MANAGER:GetMarketProductGiftErrorInfo(...)
    end

    function ZO_GamepadMarketPurchaseManager:BeginGiftPurchase(marketProductData, isPurchaseFromIngame, onPurchaseSuccessCallback, onPurchaseEndCallback)
        self:BeginPurchaseBase(marketProductData, AS_GIFT, isPurchaseFromIngame, onPurchaseSuccessCallback, onPurchaseEndCallback)
        self:StartPurchaseFlow(GetGiftErrorInfo)
    end
end

do
    local NO_DIALOG_DATA = nil
    function ZO_GamepadMarketPurchaseManager:StartPurchaseFlow(errorInfoFunction)
        local hasErrors, dialogParams, allowContinue, expectedPurchaseResult = errorInfoFunction(self.marketProductData)

        if expectedPurchaseResult == MARKET_PURCHASE_RESULT_REQUIRES_ESO_PLUS then
            self:ShowFlowDialog("GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_JOIN_ESO_PLUS", NO_DATA, dialogParams)
        elseif expectedPurchaseResult == MARKET_PURCHASE_RESULT_NOT_ENOUGH_VC then
            self:ShowFlowDialog("GAMEPAD_MARKET_CROWN_STORE_PURCHASE_ERROR_PURCHASE_CROWNS", ZO_BUY_CROWNS_URL_TYPE, dialogParams)
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
end

function ZO_GamepadMarketPurchaseManager:SetFlowPosition(position, dialogData, dialogParams)
    self.flowPosition = position

    local dialogName = DIALOG_FLOW[position]

    if position == FLOW_UNLOCKED then
        local name = self.marketProductData:GetDisplayName()
        dialogParams = {titleParams = {name}, mainTextParams = {ZO_SELECTED_TEXT:Colorize(name)}}
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
        self.queuedDialogInfo = {
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
        [FLOW_PURCHASING] = FLOW_SUCCESS,
    }
    function ZO_GamepadMarketPurchaseManager:MoveToNextFlowPosition()
        if self.doMoveToNextFlowPosition then
            local nextPosition = FLOW_MAPPING[self.flowPosition] or self.flowPosition + 1
            self:SetFlowPosition(nextPosition)
            self.doMoveToNextFlowPosition = false
        end
    end
end

function ZO_GamepadMarketPurchaseManager:ShowBuyCrownsDialog(isFromIngame)
    OnMarketPurchaseMoreCrowns()
    self.purchaseFromIngame = isFromIngame
    self:ShowFlowDialog("GAMEPAD_MARKET_BUY_CROWNS", g_buyCrownsData, g_buyCrownsTextParams)
end

function ZO_GamepadMarket_ShowBuyPlusDialog(finishedCallback)
    local uiPlatform = GetUIPlatform()
    if uiPlatform == UI_PLATFORM_PC then
        local dialogData =
        {
            urlType = APPROVED_URL_ESO_ACCOUNT_SUBSCRIPTION,
            finishedCallback = finishedCallback,
        }
        ZO_Dialogs_ShowGamepadDialog("CONFIRM_OPEN_URL_BY_TYPE", dialogData, ZO_BUY_SUBSCRIPTION_FRONT_FACING_ADDRESS)
    else
        ZO_Dialogs_ShowGamepadDialog("GAMEPAD_MARKET_BUY_PLUS")
    end
end