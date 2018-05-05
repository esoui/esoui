local function LogPurchaseClose(dialog)
    if dialog.data then
        if not dialog.data.dontLogClose then
            if dialog.data.logPurchasedMarketId then
                OnMarketEndPurchase(dialog.data.marketProductId)
            else
                OnMarketEndPurchase()
            end
        end
        dialog.data.dontLogClose = false
        dialog.data.logPurchasedMarketId = false
    end
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
                            dialog.data.dontLogClose = true
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

ESO_Dialogs["MARKET_CROWN_STORE_PURCHASE_ERROR_GIFTING_NOT_ALLOWED"] =
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
            text = SI_MARKET_GIFTING_LOCKED_HELP_KEYBIND,
            callback = function(dialog)
                ZO_MarketDialogs_Shared_OpenGiftingLockedHelp(dialog)
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

ESO_Dialogs["MARKET_CROWN_STORE_PURCHASE_ERROR_GIFTING_GRACE_PERIOD"] =
{
    finishedCallback = LogPurchaseClose,
    updateFn = function(dialog)
        ZO_MarketDialogs_Shared_UpdateGiftingGracePeriodTimer(dialog)
    end,
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

ESO_Dialogs["MARKET_CROWN_STORE_PURCHASE_ERROR_ALREADY_HAVE_PRODUCT_IN_GIFT_INVENTORY"] =
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
            text = SI_MARKET_OPEN_GIFT_INVENTORY_KEYBIND_LABEL,
            callback = function(dialog)
                RequestShowGiftInventory()
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

ESO_Dialogs["MARKET_FREE_TRIAL_PURCHASE_CONFIRMATION"] =
{
    finishedCallback = LogPurchaseClose,
    title =
    {
        text = SI_MARKET_PURCHASE_FREE_TRIAL_TITLE
    },
    mainText =
    {
        text =  function(dialog)
                    local endTimeString = GetMarketProductEndTimeString(dialog.data.marketProductId)
                    local currencyIcon = ZO_Currency_GetPlatformFormattedCurrencyIcon(CURT_CROWNS, 24)
                    return zo_strformat(SI_MARKET_PURCHASE_FREE_TRIAL_TEXT, endTimeString, currencyIcon)
                end,
    },
    canQueue = true,
    buttons =
    {
        {
            text = SI_MARKET_CONFIRM_PURCHASE_KEYBIND_TEXT,
            callback =  function(dialog)
                            dialog.data.logPurchasedMarketId = true
                            local marketProductId = dialog.data.marketProductId
                            local presentationIndex = dialog.data.presentationIndex

                            local name, description, icon, isNew, isFeatured = GetMarketProductInfo(marketProductId)
                            local productQuality = GetMarketProductQuality(marketProductId)

                            -- set this up for the MARKET_PURCHASING dialog
                            local color = GetItemQualityColor(productQuality)
                            local productName = color:Colorize(name)
                            local hasConsumables = DoesMarketProductContainConsumables(marketProductId)
                            -- the MARKET_PURCHASING dialog will be queued to show once this one is hidden
                            ZO_Dialogs_ShowDialog("MARKET_PURCHASING", {itemName = productName, hasConsumables = hasConsumables, marketProductId = marketProductId, presentationIndex = presentationIndex})
                            BuyMarketProduct(marketProductId, presentationIndex)
                        end,
        },

        {
            text = SI_DIALOG_DECLINE,
        },
    }
}

local function MarketPurchaseConfirmationDialogSetupGiftingControls(dialog, data)
    local giftRecipientContainer = dialog:GetNamedChild("GiftRecipient")
    giftRecipientContainer:SetHidden(not data.isGift)

    local noteLabel = dialog:GetNamedChild("NoteHeader")
    local noteControl = dialog:GetNamedChild("Note")
    local noteRandomTextButton = dialog:GetNamedChild("NoteRandomText")
    noteLabel:SetHidden(not data.isGift)
    noteControl:SetHidden(not data.isGift)
    noteRandomTextButton:SetHidden(not data.isGift)

    local itemContainerControl = dialog:GetNamedChild("ItemContainer")
    local itemContainerAnchorToControl = data.isGift and noteRandomTextButton or dialog.radioButtonContainer
    itemContainerControl:ClearAnchors()
    itemContainerControl:SetAnchor(TOPLEFT, itemContainerAnchorToControl, BOTTOMLEFT, 0, 10)
    itemContainerControl:SetAnchor(TOPRIGHT, itemContainerAnchorToControl, BOTTOMRIGHT, 0, 10)

    -- prefill fields if available
    dialog:GetNamedChild("GiftRecipientEditBox"):SetText(data.recipientDisplayName or "")
    dialog:GetNamedChild("NoteEdit"):SetText(data.note or "")
end

local function UpdateConfirmRestrictions(dialogControl)
    local nameEditControl = dialogControl:GetNamedChild("GiftRecipientEditBox")
    local confirmButton = dialogControl:GetNamedChild("Confirm")
    local confirmButtonState, confirmButtonStateLocked = BSTATE_NORMAL, false

    local data = dialogControl.data
    if data.isGift then
        local recipientDisplayName = nameEditControl:GetText()
        local result = IsGiftRecipientNameValid(recipientDisplayName)
        local errorText
        if result ~= GIFT_ACTION_RESULT_SUCCESS then
            confirmButtonState, confirmButtonStateLocked = BSTATE_DISABLED, true
            if result ~= GIFT_ACTION_RESULT_RECIPIENT_EMPTY then
                errorText = zo_strformat(GetString("SI_GIFTBOXACTIONRESULT", result), recipientDisplayName)
            end
        end
        if errorText then
            InitializeTooltip(InformationTooltip, nameEditControl, RIGHT, -35, 0)
            SetTooltipText(InformationTooltip, errorText, ZO_ERROR_COLOR:UnpackRGB())
        else
            ClearTooltip(InformationTooltip)
        end
    else
        ClearTooltipImmediately(InformationTooltip)
    end

    confirmButton:SetState(confirmButtonState, confirmButtonStateLocked)
end

local ENABLE_BUTTON = true
local DISABLE_BUTTON = false

local function SetupRadioButton(radioButtonGroup, radioButton, isButtonEnabled, onMouseEnter, onMouseExit, onUpdate)
    radioButtonGroup:SetButtonIsValidOption(radioButton, isButtonEnabled)
    radioButton.label:SetHandler("OnMouseEnter", onMouseEnter)
    radioButton.label:SetHandler("OnUpdate", onUpdate)
    radioButton.label:SetHandler("OnMouseExit", onMouseExit)
end

local function MarketPurchaseConfirmationDialogSetup(dialog, data)
    local marketProductId = data.marketProductId
    local presentationIndex = data.presentationIndex

    local selectedRadioButton, otherResult, otherRadioButton, anchorToControl, anchorDirection
    if data.isGift then
        selectedRadioButton = dialog.asGiftRadioButton
        otherResult = CouldPurchaseMarketProduct(marketProductId, presentationIndex)
        otherRadioButton = dialog.forMeRadioButton
        -- draw tooltip to the left of the buttons
        anchorToControl = otherRadioButton
        anchorDirection = LEFT
    else
        selectedRadioButton = dialog.forMeRadioButton
        otherResult = CouldGiftMarketProduct(marketProductId, presentationIndex)
        otherRadioButton = dialog.asGiftRadioButton
        -- draw tooltip to the right of the buttons
        anchorToControl = otherRadioButton.label
        anchorDirection = RIGHT
    end

    SetupRadioButton(dialog.radioButtonGroup, selectedRadioButton, ENABLE_BUTTON)
    dialog.radioButtonGroup:SetClickedButton(selectedRadioButton)

    if otherResult == MARKET_PURCHASE_RESULT_SUCCESS then
        SetupRadioButton(dialog.radioButtonGroup, otherRadioButton, ENABLE_BUTTON)
    elseif otherResult == MARKET_PURCHASE_RESULT_GIFTING_GRACE_PERIOD_ACTIVE then
        local lastTimeLeftS, isTooltipShowing = nil, false
        local FORCE_UPDATE = true
        local function updateTooltipText(forceUpdate)
            local timeLeftS = GetGiftingGracePeriodTime()
            if forceUpdate or timeLeftS ~= lastTimeLeftS then
                lastTimeLeftS = timeLeftS
                InformationTooltip:ClearLines()
                local timeLeftString = ZO_FormatTime(lastTimeLeftS, TIME_FORMAT_STYLE_SHOW_LARGEST_TWO_UNITS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
                SetTooltipText(InformationTooltip, zo_strformat(SI_MARKET_GIFTING_GRACE_PERIOD_TOOLTIP, timeLeftString))
            end
        end

        local function OnMouseEnter()
            ZO_Tooltips_ShowTextTooltip(anchorToControl, anchorDirection)
            updateTooltipText(FORCE_UPDATE)
            isTooltipShowing = true
        end

        local function OnUpdate()
            if isTooltipShowing then
                updateTooltipText()
            end
        end

        local function OnMouseExit()
            ClearTooltip(InformationTooltip)
            isTooltipShowing = false
        end

        SetupRadioButton(dialog.radioButtonGroup, otherRadioButton, DISABLE_BUTTON, OnMouseEnter, OnMouseExit, OnUpdate)
    else -- generic error
        local function OnMouseEnter()
            ZO_Tooltips_ShowTextTooltip(anchorToControl, anchorDirection, GetString("SI_MARKETPURCHASABLERESULT", otherResult))
        end

        local function OnMouseExit()
            ZO_Tooltips_HideTextTooltip()
        end

        SetupRadioButton(dialog.radioButtonGroup, otherRadioButton, DISABLE_BUTTON, OnMouseEnter, OnMouseExit)
    end

    MarketPurchaseConfirmationDialogSetupGiftingControls(dialog, data)

    local name, description, icon, isNew, isFeatured = GetMarketProductInfo(marketProductId)
    local productQuality = GetMarketProductQuality(marketProductId)

    -- set this up for the MARKET_PURCHASING dialog
    local color = GetItemQualityColor(productQuality)
    data.itemName = color:Colorize(name)
    data.hasConsumables = DoesMarketProductContainConsumables(marketProductId)

    local itemContainerControl = dialog:GetNamedChild("ItemContainer")
    itemContainerControl:GetNamedChild("ItemName"):SetText(zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, data.itemName))

    local iconTextureControl = itemContainerControl:GetNamedChild("Icon")
    iconTextureControl:SetTexture(icon)

    local stackSize = GetMarketProductStackCount(marketProductId)

    local stackCountControl = iconTextureControl:GetNamedChild("StackCount")
    stackCountControl:SetText(stackSize)
    stackCountControl:SetHidden(stackSize < 2)

    local marketCurrencyType, cost, hasDiscount, costAfterDiscount, discountPercent = GetMarketProductPricingByPresentation(marketProductId, presentationIndex)

    local finalCost = cost
    if hasDiscount then
        finalCost = costAfterDiscount
    end

    local currencyType = ZO_Currency_MarketCurrencyToUICurrency(marketCurrencyType)

    local costLabel = dialog:GetNamedChild("CostContainerItemCostAmount")
    local currencyString = zo_strformat(SI_NUMBER_FORMAT, ZO_Currency_FormatKeyboard(currencyType, finalCost, ZO_CURRENCY_FORMAT_AMOUNT_ICON))
    costLabel:SetText(currencyString)

    local currentBalance = dialog:GetNamedChild("BalanceContainerCurrentBalanceAmount")
    currencyString = zo_strformat(SI_NUMBER_FORMAT, ZO_Currency_FormatKeyboard(currencyType, GetPlayerMarketCurrency(marketCurrencyType), ZO_CURRENCY_FORMAT_AMOUNT_ICON))
    currentBalance:SetText(currencyString)

    UpdateConfirmRestrictions(dialog)
end

function ZO_MarketPurchaseConfirmationDialog_OnInitialized(control)
    -- Radio buttons
    local radioButtonContainer = control:GetNamedChild("RadioButtons")
    local forMeRadioButton = radioButtonContainer:GetNamedChild("ForMe")
    forMeRadioButton.label = forMeRadioButton:GetNamedChild("Label")
    local asGiftRadioButton = radioButtonContainer:GetNamedChild("AsGift")
    asGiftRadioButton.label = asGiftRadioButton:GetNamedChild("Label")
    local radioButtonGroup = ZO_RadioButtonGroup:New()
    radioButtonGroup:Add(forMeRadioButton)
    radioButtonGroup:Add(asGiftRadioButton)
    radioButtonGroup:SetClickedButton(control.forMeRadioButton)

    control.radioButtonContainer = radioButtonContainer
    control.radioButtonGroup = radioButtonGroup
    control.forMeRadioButton = forMeRadioButton
    control.asGiftRadioButton = asGiftRadioButton

    local function OnRadioButtonSelectionChanged(buttonGroup, selectedButton, previousButton)
        local data = control.data
        if selectedButton == forMeRadioButton then
            data.isGift = false
        else
            data.isGift = true
        end

        UpdateConfirmRestrictions(control)
        MarketPurchaseConfirmationDialogSetupGiftingControls(control, data)
    end

    radioButtonGroup:SetSelectionChangedCallback(OnRadioButtonSelectionChanged)
    
    -- Name edit
    local nameEdit = control:GetNamedChild("GiftRecipientEditBox")
    ZO_PreHookHandler(nameEdit, "OnTextChanged", function(editControl)
        UpdateConfirmRestrictions(control)
    end)

    ZO_AutoComplete:New(nameEdit, { AUTO_COMPLETE_FLAG_FRIEND, AUTO_COMPLETE_FLAG_GUILD }, nil, AUTO_COMPLETION_ONLINE_OR_OFFLINE, 5, AUTO_COMPLETION_AUTOMATIC_MODE)

    -- Note edit
    local noteEdit = control:GetNamedChild("NoteEdit")
    local randomNoteButton = control:GetNamedChild("NoteRandomText"):GetNamedChild("Button")
    randomNoteButton:SetText(zo_iconFormat("EsoUI/Art/Market/Keyboard/giftMessageIcon_up.dds", "100%", "100%"))
    randomNoteButton:SetHandler("OnClicked", function()
        noteEdit:SetText(GetRandomGiftSendNoteText())
    end)

    ZO_Dialogs_RegisterCustomDialog(
        "MARKET_PURCHASE_CONFIRMATION",
        {
            customControl = control,
            setup = MarketPurchaseConfirmationDialogSetup,
            title =
            {
                text = SI_MARKET_CONFIRM_PURCHASE_TITLE,
            },
            canQueue = true,
            buttons =
            {
                {
                    control = control:GetNamedChild("Confirm"),
                    text = SI_MARKET_CONFIRM_PURCHASE_KEYBIND_TEXT,
                    callback =  function(dialog)
                                    local data = dialog.data
                                    data.logPurchasedMarketId = true
                                    local marketProductId = data.marketProductId
                                    local presentationIndex = data.presentationIndex
                                    local recipientDisplayName
                                    local note
                                    if data.isGift then
                                        recipientDisplayName = dialog:GetNamedChild("GiftRecipientEditBox"):GetText()
                                        note = dialog:GetNamedChild("NoteEdit"):GetText()
                                    end
                                    -- the MARKET_PURCHASING dialog will be queued to show once this one is hidden
                                    ZO_Dialogs_ShowDialog("MARKET_PURCHASING", {itemName = data.itemName, hasConsumables = data.hasConsumables, marketProductId = marketProductId, presentationIndex = presentationIndex, recipientDisplayName = recipientDisplayName, note = note})

                                    if data.isGift then
                                        GiftMarketProduct(marketProductId, presentationIndex, note, recipientDisplayName)
                                    else
                                        BuyMarketProduct(marketProductId, presentationIndex)
                                    end
                                end,
                },

                {
                    control = control:GetNamedChild("Cancel"),
                    text = SI_DIALOG_DECLINE,
                    callback = LogPurchaseClose,
                },
            },
            noChoiceCallback = LogPurchaseClose,
            finishedCallback = function(dialog)
                ClearTooltipImmediately(InformationTooltip)
            end,
        }
    )
end

local function OnMarketPurchaseResult(data, result, tutorialTrigger, wasGift)
    EVENT_MANAGER:UnregisterForEvent("MARKET_PURCHASING", EVENT_MARKET_PURCHASE_RESULT)
    data.result = result
    data.wasGift = wasGift

    if not wasGift then
        if tutorialTrigger ~= TUTORIAL_TRIGGER_NONE then
            data.tutorialTrigger = tutorialTrigger
        end
    end
end

local LOADING_DELAY_MS = 500
local SHOW_LOADING_ICON = true
local HIDE_LOADING_ICON = false

local MARKET_PURCHASING_STATE_DELAY = 1
local MARKET_PURCHASING_STATE_WAITING = 2
local MARKET_PURCHASING_STATE_RESULT = 3

local function OnMarketPurchasingUpdate(dialog, currentTimeInSeconds)
    local timeInMilliseconds = currentTimeInSeconds * 1000
    local data = dialog.data
    local result = data.result

    if data.loadingDelayTimeMS == nil then
        data.loadingDelayTimeMS = timeInMilliseconds + LOADING_DELAY_MS
    end

    if result ~= nil and data.currentState ~= MARKET_PURCHASING_STATE_RESULT then
        data.currentState = MARKET_PURCHASING_STATE_RESULT

        local titleText, mainText
        if result == MARKET_PURCHASE_RESULT_SUCCESS then
            titleText = GetString(SI_TRANSACTION_COMPLETE_TITLE)

            local marketProductId = data.marketProductId
            local stackCount = GetMarketProductStackCount(marketProductId)

            if data.wasGift then
                if stackCount > 1 then
                    mainText = zo_strformat(SI_MARKET_GIFTING_SUCCESS_TEXT_WITH_QUANTITY, data.itemName, stackCount, ZO_SELECTED_TEXT:Colorize(data.recipientDisplayName))
                else
                    mainText = zo_strformat(SI_MARKET_GIFTING_SUCCESS_TEXT, data.itemName, ZO_SELECTED_TEXT:Colorize(data.recipientDisplayName))
                end
            else
                local useProductInfo = ZO_Market_Shared.GetUseProductInfo(marketProductId)
                if useProductInfo then
                    if useProductInfo.transactionCompleteTitleText then
                        titleText = useProductInfo.transactionCompleteTitleText
                    end
                    mainText = zo_strformat(useProductInfo.transactionCompleteText, data.itemName, stackCount)

                    local useProductControl = dialog:GetNamedChild("UseProduct")
                    useProductControl:SetHidden(useProductInfo.visible and not useProductInfo.visible())
                    useProductControl:SetEnabled(not useProductInfo.enabled or useProductInfo.enabled())
                    useProductControl:SetText(useProductInfo.buttonText)
                else
                    if stackCount > 1 then
                        mainText = zo_strformat(SI_MARKET_PURCHASE_SUCCESS_TEXT_WITH_QUANTITY, data.itemName, stackCount)
                    elseif GetMarketProductNumCollectibles(marketProductId) > 0 then
                        mainText = zo_strformat(SI_MARKET_PURCHASE_SUCCESS_TEXT_WITH_COLLECTIBLE, data.itemName)
                    else
                        mainText = zo_strformat(SI_MARKET_PURCHASE_SUCCESS_TEXT, data.itemName)
                    end
                end
            end
        else
            titleText = GetString(SI_TRANSACTION_FAILED_TITLE)
            mainText = GetString("SI_MARKETPURCHASABLERESULT", result)
        end

        local confirmText
        if ZO_MarketDialogs_Shared_ShouldRestartGiftFlow(data.result) then
            confirmText = GetString(SI_MARKET_CONFIRM_PURCHASE_RESTART_KEYBIND_LABEL)
        else
            confirmText = GetString(SI_MARKET_CONFIRM_PURCHASE_BACK_KEYBIND_LABEL)
        end

        ZO_Dialogs_UpdateDialogTitleText(dialog, { text = titleText })
        ZO_Dialogs_UpdateDialogMainText(dialog, { text = mainText, align = TEXT_ALIGN_CENTER })

        local confirmButtonControl = dialog:GetNamedChild("Confirm")
        confirmButtonControl:SetText(confirmText) 
        confirmButtonControl:SetHidden(false)

        ZO_Dialogs_SetDialogLoadingIcon(dialog:GetNamedChild("Loading"), dialog:GetNamedChild("Text"), HIDE_LOADING_ICON)
    elseif data.currentState == MARKET_PURCHASING_STATE_DELAY and timeInMilliseconds > data.loadingDelayTimeMS then
        data.currentState = MARKET_PURCHASING_STATE_WAITING

        ZO_Dialogs_UpdateDialogMainText(dialog, { text = zo_strformat(SI_MARKET_PURCHASING_TEXT, data.itemName), TEXT_ALIGN_CENTER })
        ZO_Dialogs_SetDialogLoadingIcon(dialog:GetNamedChild("Loading"), dialog:GetNamedChild("Text"), SHOW_LOADING_ICON)
    end
end

local function MarketPurchasingDialogSetup(dialog, data)
    data.result = nil
    data.loadingDelayTimeMS = nil
    data.currentState = MARKET_PURCHASING_STATE_DELAY
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
                    control = self:GetNamedChild("Confirm"),
                    text = SI_MARKET_CONFIRM_PURCHASE_BACK_KEYBIND_LABEL,
                    keybind = "DIALOG_PRIMARY",
                    callback = function(dialog)
                                   local data = dialog.data
                                   if ZO_MarketDialogs_Shared_ShouldRestartGiftFlow(data.result) then
                                       local restartData =
                                       {
                                           isGift = true,
                                           marketProductId = data.marketProductId,
                                           presentationIndex = data.presentationIndex,
                                           recipientDisplayName = data.recipientDisplayName,
                                           note = data.note,
                                       }
                                       ZO_Dialogs_ShowDialog("MARKET_PURCHASE_CONFIRMATION", restartData)
                                       return
                                   end
                                   LogPurchaseClose(dialog)
                                   if data.wasGift == false then
                                       -- Show tutorials from a purchased item first before showing the consumable tutorial
                                       if data.tutorialTrigger then
                                           MARKET:ShowTutorial(data.tutorialTrigger)
                                       end

                                       if data.result == MARKET_PURCHASE_RESULT_SUCCESS and data.hasConsumables then
                                           MARKET:ShowTutorial(TUTORIAL_TRIGGER_CROWN_CONSUMABLE_PURCHASED)
                                       end
                                   end
                               end,
                },
            },
        }
    )
end