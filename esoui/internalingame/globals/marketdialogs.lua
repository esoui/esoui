local MIN_PURCHASE_QUANTITY = 1

local function OnPurchaseResolved(dialog)
    if dialog.data then
        -- Did we come from an in-house placement preview?
        local isPreviewingMarketProductPlacement = dialog.data.isPreviewingMarketProductPlacement
        dialog.data.isPreviewingMarketProductPlacement = nil

        if dialog.data.logPurchasedMarketId then
            OnMarketEndPurchase(dialog.data.marketProductData:GetId())
        else
            OnMarketEndPurchase()
        end

        dialog.data.logPurchasedMarketId = false

        if isPreviewingMarketProductPlacement then
            -- We did come from an in-house placement preview; let's go back to the Housing Editor Browse mode.
            ZO_ReturnToHousingEditorBrowseMode()
        end
    end
end

ESO_Dialogs["MARKET_CROWN_STORE_PURCHASE_ERROR_CONTINUE"] = 
{
    canQueue = true,
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
            keybind = "DIALOG_PRIMARY",
            callback = function(dialog)
                -- the MARKET_PURCHASE_CONFIRMATION dialog will be queued to show once this one is hidden
                ZO_Dialogs_ShowDialog("MARKET_PURCHASE_CONFIRMATION", dialog.data)
            end,
        },
        {
            text = SI_DIALOG_EXIT,
            keybind = "DIALOG_NEGATIVE",
            callback = OnPurchaseResolved,
        },
    },
    noChoiceCallback = OnPurchaseResolved,
}

ESO_Dialogs["MARKET_CROWN_STORE_PURCHASE_ERROR_PURCHASE_CROWNS"] =
{
    finishedCallback = OnPurchaseResolved,
    canQueue = true,
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
                ZO_ShowBuyCrownsPlatformUI()
            end,
            keybind = "DIALOG_PRIMARY",
        },
        {
            text = SI_DIALOG_EXIT,
            keybind = "DIALOG_NEGATIVE",
        },
    },
}

ESO_Dialogs["MARKET_CROWN_STORE_PURCHASE_ERROR_JOIN_ESO_PLUS"] =
{
    finishedCallback = OnPurchaseResolved,
    canQueue = true,
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
                ZO_ShowBuySubscriptionPlatformDialog()
            end,
            keybind = "DIALOG_PRIMARY",
        },
        {
            text = SI_DIALOG_EXIT,
            keybind = "DIALOG_NEGATIVE",
        },
    },
}

ESO_Dialogs["MARKET_CROWN_STORE_PURCHASE_ERROR_GIFTING_NOT_ALLOWED"] =
{
    finishedCallback = OnPurchaseResolved,
    canQueue = true,
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
            end,
            keybind = "DIALOG_PRIMARY",
        },
        {
            text = SI_DIALOG_EXIT,
            keybind = "DIALOG_NEGATIVE",
        },
    },
}

ESO_Dialogs["MARKET_CROWN_STORE_PURCHASE_ERROR_GIFTING_GRACE_PERIOD"] =
{
    finishedCallback = OnPurchaseResolved,
    updateFn = function(dialog)
        ZO_MarketDialogs_Shared_UpdateGiftingGracePeriodTimer(dialog)
    end,
    canQueue = true,
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
            end,
            keybind = "DIALOG_PRIMARY",
        },
        {
            text = SI_DIALOG_EXIT,
            keybind = "DIALOG_NEGATIVE",
        },
    },
}

ESO_Dialogs["MARKET_CROWN_STORE_PURCHASE_ERROR_ALREADY_HAVE_PRODUCT_IN_GIFT_INVENTORY"] =
{
    finishedCallback = OnPurchaseResolved,
    canQueue = true,
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
            end,
            keybind = "DIALOG_PRIMARY",
        },
        {
            text = SI_DIALOG_EXIT,
            keybind = "DIALOG_NEGATIVE",
        },
    },
}

ESO_Dialogs["MARKET_CROWN_STORE_GIFT_PARTIALLY_OWNED_KEYBOARD"] =
{
    canQueue = true,
    title =
    {
        text = SI_MARKET_PURCHASE_ERROR_TITLE_FORMATTER
    },
    mainText =
    {
        text = SI_MARKET_GIFTING_BUNDLE_PARTS_OWNED_TEXT
    },
    buttons =
    {
        {
            text = SI_MARKET_PURCHASE_ERROR_CONTINUE,
            callback = function(dialog)
                RespondToSendPartiallyOwnedGift(true)

                local data = dialog.data
                ZO_Dialogs_ShowDialog("MARKET_PURCHASING", {itemName = data.itemName, marketProductData = data.marketProductData, recipientDisplayName = data.recipientDisplayName })
            end,
            keybind = "DIALOG_PRIMARY",
        },
        {
            text = SI_DIALOG_EXIT,
            callback = function(dialog)
                RespondToSendPartiallyOwnedGift(false)
            end,
            keybind = "DIALOG_NEGATIVE",
        },
    },
}

ESO_Dialogs["RESEND_GIFT_PARTIALLY_OWNED_KEYBOARD"] =
{
    canQueue = true,
    title =
    {
        text = SI_MARKET_PURCHASE_ERROR_TITLE_FORMATTER
    },
    mainText =
    {
        text = SI_MARKET_GIFTING_RESEND_BUNDLE_PARTS_OWNED_TEXT
    },
    buttons =
    {
        {
            text = SI_MARKET_PURCHASE_ERROR_CONTINUE,
            callback = function(dialog)
                RespondToSendPartiallyOwnedGift(true)

                local data = dialog.data
                ZO_Dialogs_ShowDialog("GIFT_SENDING_KEYBOARD", data)
            end,
            keybind = "DIALOG_PRIMARY",
        },
        {
            text = SI_DIALOG_EXIT,
            callback = function(dialog)
                RespondToSendPartiallyOwnedGift(false)
            end,
            keybind = "DIALOG_NEGATIVE",
        },
    },
}

ESO_Dialogs["MARKET_CROWN_STORE_PURCHASE_ERROR_EXIT"] =
{
    finishedCallback = OnPurchaseResolved,
    canQueue = true,
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
    finishedCallback = OnPurchaseResolved,
    title =
    {
        text = SI_MARKET_PURCHASE_FREE_TRIAL_TITLE
    },
    mainText =
    {
        text =  function(dialog)
                    local endTimeString = dialog.data.marketProductData:GetEndTimeString()
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
                            local marketProductData = dialog.data.marketProductData

                            -- set this up for the MARKET_PURCHASING dialog
                            local productName = marketProductData:GetColorizedDisplayName()
                            -- the MARKET_PURCHASING dialog will be queued to show once this one is hidden
                            ZO_Dialogs_ShowDialog("MARKET_PURCHASING", {itemName = productName, marketProductData = marketProductData})
                            marketProductData:RequestPurchase()
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

local TEXT_CALLOUT_BACKGROUND_ALPHA = 0.9
local function MarketPurchaseConfirmationDialogSetupPricingControls(dialog, data)
    local marketPurchaseData
    if data.marketProductData then
        local quantity = data.quantity or MIN_PURCHASE_QUANTITY
        local marketCurrencyType, cost, costAfterDiscount, discountPercent, esoPlusCost = data.marketProductData:GetMarketProductPricingByPresentation()
        if cost then
            cost = cost * quantity
        end
        if costAfterDiscount then
            costAfterDiscount = costAfterDiscount * quantity
        end
        if esoPlusCost then
            esoPlusCost = esoPlusCost * quantity
        end
        marketPurchaseData =
        {
            marketCurrencyType = marketCurrencyType,
            cost = cost,
            costAfterDiscount = costAfterDiscount,
            discountPercent = discountPercent,
            esoPlusCost = esoPlusCost,
        }
    elseif data.marketPurchaseOptions then
        local currencyType, options = next(data.marketPurchaseOptions)
        marketPurchaseData = options
        marketPurchaseData.marketCurrencyType = currencyType
    end

    local currencyType = GetCurrencyTypeFromMarketCurrencyType(marketPurchaseData.marketCurrencyType)

    local hasCost = marketPurchaseData.cost ~= nil
    local hasEsoPlusCost
    if data.isGift then
        hasEsoPlusCost = false -- gifts aren't eligible for ESO Plus pricing
    else
        hasEsoPlusCost = marketPurchaseData.esoPlusCost ~= nil and IsEligibleForEsoPlusPricing()
    end

    if hasCost then
        local DEFAULT_OPTIONS = nil
        local SHOW_ALL = true
        local HAS_ENOUGH_CURRENCY = false
        local extraOptions = nil
        local currencyFormat
        local costAmountLabel = dialog.costContainer.currencyAmount
        local previousCostLabel = dialog.costContainer.previousCost
        local textCalloutLabel = dialog.costContainer.textCallout

        -- layout the previous cost
        if not hasEsoPlusCost and marketPurchaseData.discountPercent > 0 and marketPurchaseData.costAfterDiscount ~= 0 then
            ZO_CurrencyControl_SetSimpleCurrency(previousCostLabel, currencyType, marketPurchaseData.cost, DEFAULT_OPTIONS, SHOW_ALL, HAS_ENOUGH_CURRENCY, { strikethroughCurrencyAmount = true })
            previousCostLabel:SetHidden(false)

            local discountPercentText = zo_strformat(SI_MARKET_DISCOUNT_PRICE_PERCENT_FORMAT, marketPurchaseData.discountPercent)
            textCalloutLabel:SetText(discountPercentText)
            textCalloutLabel:SetHidden(false)
        else
            previousCostLabel:SetHidden(true)
            textCalloutLabel:SetHidden(true)
        end

        if hasEsoPlusCost then
            extraOptions =
            {
                color = ZO_DEFAULT_TEXT,
                iconInheritColor = true,
            }

            costAmountLabel:SetColor(ZO_DEFAULT_TEXT:UnpackRGB())
            currencyFormat = ZO_CURRENCY_FORMAT_STRIKETHROUGH_AMOUNT_ICON
        else
            costAmountLabel:SetColor(ZO_HIGHLIGHT_TEXT:UnpackRGB())
            currencyFormat = ZO_CURRENCY_FORMAT_AMOUNT_ICON
        end
        ZO_CurrencyControl_SetSimpleCurrency(costAmountLabel, currencyType, marketPurchaseData.costAfterDiscount, DEFAULT_OPTIONS, SHOW_ALL, HAS_ENOUGH_CURRENCY, extraOptions)

        local labelString
        if hasEsoPlusCost then
            labelString = SI_MARKET_CONFIRM_PURCHASE_NORMAL_COST_LABEL
        else
            labelString = SI_MARKET_CONFIRM_PURCHASE_COST_LABEL
        end
        local costLabel = dialog.costContainer.currencyLabel
        costLabel:SetText(GetString(labelString))
    end
    dialog.costContainer:SetHidden(not hasCost)

    if hasEsoPlusCost then
        local extraOptions =
        {
            color = ZO_MARKET_PRODUCT_ESO_PLUS_COLOR,
            iconInheritColor = marketPurchaseData.marketCurrencyType ~= MKCT_CROWN_GEMS,
        }
        local costAmountLabel = dialog.esoPlusCostContainer.currencyAmount
        ZO_CurrencyControl_SetSimpleCurrency(costAmountLabel, currencyType, marketPurchaseData.esoPlusCost, DEFAULT_OPTIONS, SHOW_ALL, HAS_ENOUGH_CURRENCY, extraOptions)

        dialog.esoPlusCostContainer:ClearAnchors()
        local controlToAnchorCostContainerTo = hasCost and dialog.costContainer or dialog.balanceContainer
        dialog.esoPlusCostContainer:SetAnchor(TOPLEFT, controlToAnchorCostContainerTo, BOTTOMLEFT, 0, 30)
        dialog.esoPlusCostContainer:SetAnchor(TOPRIGHT, controlToAnchorCostContainerTo, BOTTOMRIGHT, 0, 30)
    end
    dialog.esoPlusCostContainer:SetHidden(not hasEsoPlusCost)

    local currentBalanceAmountLabel = dialog.balanceContainer.currencyAmount
    ZO_CurrencyControl_SetSimpleCurrency(currentBalanceAmountLabel, currencyType, GetPlayerMarketCurrency(marketPurchaseData.marketCurrencyType))
end

local function MarketPurchaseSelectTemplateDialogSetupHouseInfoControls(dialog, data)
    local index, templateData = next(data.marketPurchaseOptions)
    if templateData then
        local houseZoneId = GetHouseFoundInZoneId(templateData.houseId)
        local houseZoneName = GetZoneNameById(houseZoneId)
        local houseCategory = GetHouseCategoryType(templateData.houseId)
        local houseCategoryName = GetString("SI_HOUSECATEGORYTYPE", houseCategory)
        local houseFlags = GetHouseFlags(templateData.houseId)
        local hasWeatherControlSupport = ZO_FlagHelpers.MaskHasFlag(houseFlags, HOUSE_FLAGS_SUPPORTS_WEATHER_CONTROL)
        local hasWeatherControlSupportString = hasWeatherControlSupport and GetString(SI_YES) or GetString(SI_NO)

        local hasEsoPlusCost
        if data.isGift then
            hasEsoPlusCost = false -- gifts aren't eligible for ESO Plus pricing
        else
            hasEsoPlusCost = templateData.esoPlusCost ~= nil and IsEligibleForEsoPlusPricing()
        end

        dialog.locationContainer:ClearAnchors()
        local controlToAnchorCostContainerTo
        if hasEsoPlusCost then
            controlToAnchorCostContainerTo = dialog.esoPlusCostContainer
        else
            controlToAnchorCostContainerTo = templateData.cost ~= nil and dialog.costContainer or dialog.balanceContainer
        end

        dialog.locationContainer:SetAnchor(TOPLEFT, controlToAnchorCostContainerTo, BOTTOMLEFT, 0, 50)
        dialog.locationContainer:SetAnchor(TOPRIGHT, controlToAnchorCostContainerTo, BOTTOMRIGHT, 0, 50)

        local locationValueLabel = dialog.locationContainer.valueControl
        locationValueLabel:SetText(zo_strformat(SI_ZONE_NAME, houseZoneName))

        local houseTypeValueLabel = dialog.houseTypeContainer.valueControl
        houseTypeValueLabel:SetText(zo_strformat(SI_HOUSE_TYPE_FORMATTER, houseCategoryName))

        local weatherValueLabel = dialog.weatherContainer.valueControl
        weatherValueLabel:SetText(zo_strformat(SI_HOUSE_SUPPORTS_WEATHER_CONTROL_FORMATTER, hasWeatherControlSupportString))

        for furnishingLimitType = HOUSING_FURNISHING_LIMIT_TYPE_ITERATION_BEGIN, HOUSING_FURNISHING_LIMIT_TYPE_ITERATION_END do
            local initialFurnishingCount, furnishingLimit = GetHouseTemplateBaseFurnishingCountInfo(templateData.houseTemplateId, furnishingLimitType)
            dialog:GetNamedChild("HouseInfo" .. furnishingLimitType).labelControl:SetText(zo_strformat(SI_MARKET_SELECT_HOUSE_TEMPLATE_INFO_FORMATTER, GetString("SI_HOUSINGFURNISHINGLIMITTYPE", furnishingLimitType)))
            dialog:GetNamedChild("HouseInfo" .. furnishingLimitType).valueControl:SetText(zo_strformat(SI_HOUSE_INFORMATION_COUNT_FORMAT, initialFurnishingCount, furnishingLimit))
        end
    end
end

local function MarketPurchaseConfirmationDialogSetupQuantityControls(dialog, data)
    local marketProductData = data.marketProductData
    local maxQuantity
    if data.isGift then
        maxQuantity = marketProductData:GetMaxGiftQuantity()
    else
        maxQuantity = marketProductData:GetMaxPurchaseQuantity()
    end
    data.maxQuantity = maxQuantity

    local quantityContainer = dialog.quantityContainer
    local quantityEnabled = maxQuantity > 1
    if quantityEnabled then
        if maxQuantity == MAX_MARKET_PURCHASE_QUANTITY then
            -- No predetermined quantity limit requires input but excludes the maximum limit label.
            quantityContainer.quantityMaxLabel:SetHidden(true)
        else
            -- A maximum quantity greater than one requires input and the maximum limit label.
            quantityContainer.quantityMaxLabel:SetText(zo_strformat(SI_MARKET_CONFIRM_PURCHASE_MAXIMUM_LABEL, maxQuantity))
            quantityContainer.quantityMaxLabel:SetHidden(false)
        end
        quantityContainer.quantitySpinner:SetMinMax(MIN_PURCHASE_QUANTITY, maxQuantity)
        quantityContainer:SetHidden(false)
    else
        -- Maximum quantity of zero or one does not require input or the maximum limit label.
        quantityContainer:SetHidden(true)
    end

    local itemContainerControl = dialog:GetNamedChild("ItemContainer")
    local itemContainerTextContainer = itemContainerControl:GetNamedChild("ItemText")
    local iconTextureControl = itemContainerControl:GetNamedChild("Icon")

    itemContainerTextContainer:ClearAnchors()
    if quantityEnabled then
        itemContainerTextContainer:SetAnchor(TOPLEFT, iconTextureControl, TOPRIGHT, 10)
    else
        itemContainerTextContainer:SetAnchor(LEFT, iconTextureControl, RIGHT, 10)
    end
end

local function UpdateConfirmRestrictions(dialogControl)
    local nameEditControl = dialogControl:GetNamedChild("GiftRecipientEditBox")
    local confirmButton = dialogControl:GetNamedChild("Confirm")
    local confirmButtonState, confirmButtonStateLocked = BSTATE_NORMAL, false
    local errorText, errorControl

    local data = dialogControl.data
    if data.isGift then
        local recipientDisplayName = nameEditControl:GetText()
        local result = IsGiftRecipientNameValid(recipientDisplayName)
        if result ~= GIFT_ACTION_RESULT_SUCCESS then
            confirmButtonState, confirmButtonStateLocked = BSTATE_DISABLED, true
            if result ~= GIFT_ACTION_RESULT_RECIPIENT_EMPTY then
                errorText = zo_strformat(GetString("SI_GIFTBOXACTIONRESULT", result), recipientDisplayName)
                errorControl = nameEditControl
            end
        end
    end

    local maxQuantityLabel = dialogControl.quantityContainer.quantityMaxLabel
    maxQuantityLabel:SetColor(ZO_HIGHLIGHT_TEXT:UnpackRGB())

    MarketPurchaseConfirmationDialogSetupQuantityControls(dialogControl, data)

    if not dialogControl.quantityContainer:IsControlHidden() then
        local quantity = data.quantity
        local isValid, result
        if data.isGift then
            isValid, result = data.marketProductData:IsGiftQuantityValid(quantity)
        else
            isValid, result = data.marketProductData:IsPurchaseQuantityValid(quantity)
        end
        if not isValid then
            confirmButtonState, confirmButtonStateLocked = BSTATE_DISABLED, true
            errorControl = maxQuantityLabel
            if result == MARKET_PURCHASE_RESULT_EXCEEDS_MAX_QUANTITY then
                errorText = zo_strformat(GetString("SI_MARKETPURCHASABLERESULT", result), data.maxQuantity)
                maxQuantityLabel:SetColor(ZO_ERROR_COLOR:UnpackRGB())
            else
                errorText = GetString("SI_MARKETPURCHASABLERESULT", result)
            end
        end
    end

    if errorText then
        InitializeTooltip(InformationTooltip, errorControl, LEFT, 20, 0)
        SetTooltipText(InformationTooltip, errorText, ZO_ERROR_COLOR:UnpackRGB())
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

local function SetupRadioButtonWithBasicTextTooltip(radioButtonGroup, radioButton, isButtonEnabled, anchorToControl, anchorDirection, tooltipText)
    local function OnMouseEnter()
        ZO_Tooltips_ShowTextTooltip(anchorToControl, anchorDirection, tooltipText)
    end

    local function OnMouseExit()
        ZO_Tooltips_HideTextTooltip()
    end

    SetupRadioButton(radioButtonGroup, radioButton, isButtonEnabled, OnMouseEnter, OnMouseExit)
end

local function MarketPurchaseConfirmationDialogSetup(dialog, data)
    local marketProductData = data.marketProductData

    local quantity = MIN_PURCHASE_QUANTITY
    data.quantity = quantity
    dialog.quantityContainer.quantitySpinner:SetValue(quantity)

    local selectedRadioButton, otherRadioButtonResult, otherRadioButton, anchorToControl, anchorDirection
    local selectedRadioButtonWarningStrings = {}
    local otherRadioButtonWarningStrings = {}
    if data.isGift then
        selectedRadioButton = dialog.asGiftRadioButton
        otherRadioButton = dialog.forMeRadioButton
        otherRadioButtonResult = marketProductData:CouldPurchase()
        ZO_MARKET_MANAGER:AddMarketProductPurchaseWarningStringsToTable(marketProductData, otherRadioButtonWarningStrings)
        -- draw tooltip to the left of the buttons
        anchorToControl = otherRadioButton
        anchorDirection = LEFT
    else
        selectedRadioButton = dialog.forMeRadioButton
        otherRadioButton = dialog.asGiftRadioButton
        otherRadioButtonResult = marketProductData:CouldGift()
        ZO_MARKET_MANAGER:AddMarketProductPurchaseWarningStringsToTable(marketProductData, selectedRadioButtonWarningStrings)
        -- draw tooltip to the right of the buttons
        anchorToControl = otherRadioButton.label
        anchorDirection = RIGHT
    end

    if #selectedRadioButtonWarningStrings == 0 then
        SetupRadioButton(dialog.radioButtonGroup, selectedRadioButton, ENABLE_BUTTON)
    else
        local tooltipText = table.concat(selectedRadioButtonWarningStrings, "\n\n")
        SetupRadioButtonWithBasicTextTooltip(dialog.radioButtonGroup, selectedRadioButton, ENABLE_BUTTON, anchorToControl, anchorDirection, tooltipText)
    end

    dialog.radioButtonGroup:SetClickedButton(selectedRadioButton)

    if otherRadioButtonResult == MARKET_PURCHASE_RESULT_SUCCESS then
        if #otherRadioButtonWarningStrings == 0 then
            SetupRadioButton(dialog.radioButtonGroup, otherRadioButton, ENABLE_BUTTON)
        else
            local tooltipText = table.concat(otherRadioButtonWarningStrings, "\n\n")
            SetupRadioButtonWithBasicTextTooltip(dialog.radioButtonGroup, otherRadioButton, ENABLE_BUTTON, anchorToControl, anchorDirection, tooltipText)
        end
    elseif otherRadioButtonResult == MARKET_PURCHASE_RESULT_GIFTING_GRACE_PERIOD_ACTIVE then
        local lastTimeLeftS = nil
        local isTooltipShowing = false
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
        local tooltipText = GetString("SI_MARKETPURCHASABLERESULT", otherRadioButtonResult)
        SetupRadioButtonWithBasicTextTooltip(dialog.radioButtonGroup, otherRadioButton, DISABLE_BUTTON, anchorToControl, anchorDirection, tooltipText)
    end

    MarketPurchaseConfirmationDialogSetupGiftingControls(dialog, data)

    -- set this up for the MARKET_PURCHASING dialog
    data.itemName = marketProductData:GetColorizedDisplayName()

    local itemContainerControl = dialog:GetNamedChild("ItemContainer")
    local itemContainerTextContainer = itemContainerControl:GetNamedChild("ItemText")
    local itemNameControl = itemContainerTextContainer:GetNamedChild("ItemName")

    local houseId = GetMarketProductHouseId(data.marketProductData.marketProductId)
    if houseId > 0 then
        local houseCollectibleId = GetCollectibleIdForHouse(houseId)
        local houseDisplayName = GetCollectibleName(houseCollectibleId)
        itemNameControl:SetText(zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, houseDisplayName))
        itemContainerTextContainer:GetNamedChild("ItemDetail"):SetText(zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, data.itemName))
    else
        itemNameControl:SetText(zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, data.itemName))
        itemContainerTextContainer:GetNamedChild("ItemDetail"):SetText("")
    end

    local iconTextureControl = itemContainerControl:GetNamedChild("Icon")
    local icon = marketProductData:GetIcon()
    iconTextureControl:SetTexture(icon)

    local stackSize = marketProductData:GetStackCount()

    local stackCountControl = iconTextureControl:GetNamedChild("StackCount")
    stackCountControl:SetText(stackSize)
    stackCountControl:SetHidden(stackSize < 2)

    MarketPurchaseConfirmationDialogSetupQuantityControls(dialog, data)
    MarketPurchaseConfirmationDialogSetupPricingControls(dialog, data)
    UpdateConfirmRestrictions(dialog)
end

local function ConfirmMarketPurchaseDialog(dialog)
    local data = dialog.data
    data.logPurchasedMarketId = true

    local marketProductData = data.marketProductData
    local quantity = data.quantity
    local recipientDisplayName
    local note

    if data.isGift then
        recipientDisplayName = dialog:GetNamedChild("GiftRecipientEditBox"):GetText()
        note = dialog:GetNamedChild("NoteEdit"):GetText()
    end

    -- the MARKET_PURCHASING dialog will be queued to show once this one is hidden
    ZO_Dialogs_ShowDialog("MARKET_PURCHASING", {itemName = data.itemName, marketProductData = marketProductData, recipientDisplayName = recipientDisplayName, note = note, quantity = quantity})

    if data.isGift then
        marketProductData:RequestPurchaseAsGift(note, recipientDisplayName, quantity)
    else
        marketProductData:RequestPurchase(quantity)
    end
end

function ZO_MarketPurchaseConfirmationDialog_OnQuantityChanged(dialog, quantity)
    dialog.data.quantity = quantity
    UpdateConfirmRestrictions(dialog)
    MarketPurchaseConfirmationDialogSetupPricingControls(dialog, dialog.data)
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

    control.balanceContainer = control:GetNamedChild("BalanceContainer")
    control.costContainer = control:GetNamedChild("CostContainer")
    control.costContainer.previousCost = control.costContainer:GetNamedChild("PreviousCost")
    control.costContainer.textCallout = control.costContainer:GetNamedChild("TextCallout")
    control.esoPlusCostContainer = control:GetNamedChild("EsoPlusCostContainer")

    local function OnRadioButtonSelectionChanged(buttonGroup, selectedButton, previousButton)
        local data = control.data
        if selectedButton == forMeRadioButton then
            data.isGift = false
        else
            data.isGift = true
        end

        -- Always reset to the default quantity when toggling between gifting and purchasing.
        data.quantity = MIN_PURCHASE_QUANTITY
        control.quantityContainer.quantitySpinner:SetValue(data.quantity)

        UpdateConfirmRestrictions(control)
        MarketPurchaseConfirmationDialogSetupGiftingControls(control, data)
        MarketPurchaseConfirmationDialogSetupPricingControls(control, data)
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

    local function OnRandomNoteClicked(control, confirmed)
        local generateNote = false
        if confirmed then
            generateNote = true
        else
            local noteText = noteEdit:GetText()
            if noteText == "" or noteText == control._lastRandomNoteText then
                generateNote = true
            end
        end

        if generateNote then
            -- The note field was already empty or was populated with the last generated note text,
            -- or the player gave confirmation.
            local randomNoteText = GetRandomGiftSendNoteText()
            control._lastRandomNoteText = randomNoteText
            noteEdit:SetText(randomNoteText)

            -- Indicate that the operation was carried out.
            return true
        end

        -- Indicate that player confirmation is required.
        return false
    end

    local randomNoteButton = control:GetNamedChild("NoteRandomText"):GetNamedChild("Button")
    local randomNoteButtonLabel = string.format("%s %s", GetString(SI_MARKET_GIFTING_RANDOM_NOTE_LABEL), zo_iconFormat("EsoUI/Art/Market/Keyboard/giftMessageIcon_up.dds", "100%", "100%"))
    local randomNoteConfirmLabel = GetString(SI_MARKET_GIFTING_RANDOM_NOTE_CONFIRMATION_LABEL)
    ZO_TimedConfirmationButton_Setup(randomNoteButton, randomNoteButtonLabel, randomNoteConfirmLabel, OnRandomNoteClicked)

    -- Item Quantity
    control.itemContainer = control:GetNamedChild("ItemContainer")
    control.quantityContainer = control.itemContainer:GetNamedChild("QuantityContainer")
    control.quantityContainer.quantityMaxLabel = control.quantityContainer:GetNamedChild("Maximum")

    local quantitySpinner = ZO_Spinner:New(control.quantityContainer:GetNamedChild("Spinner"))
    control.quantityContainer.quantitySpinner = quantitySpinner

    local quantityEditControl = quantitySpinner.display
    quantityEditControl:SetSelectAllOnFocus(true)
    ZO_MarketPurchaseConfirmationDialog_RegisterEditControl(quantityEditControl)
    quantityEditControl:SetHandler("OnTab", function() ZO_MarketPurchaseConfirmationDialog_FocusNextEditControl(quantityEditControl) end)

    local function OnQuantityChanged(quantity)
        ZO_MarketPurchaseConfirmationDialog_OnQuantityChanged(control:GetOwningWindow(), quantity)
    end
    control.quantityContainer.quantitySpinner:RegisterCallback("OnValueChanged", OnQuantityChanged)

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
                    callback = ConfirmMarketPurchaseDialog,
                },

                {
                    control = control:GetNamedChild("Cancel"),
                    text = SI_DIALOG_DECLINE,
                    callback = OnPurchaseResolved,
                },
            },
            noChoiceCallback = OnPurchaseResolved,
            finishedCallback = function(dialog)
                ClearTooltipImmediately(InformationTooltip)
            end,
        }
    )
end

local function MarketPurchaseHouseTemplateSelectDialogSetup(dialog, data)
    local marketProductData = data.marketProductData
    local marketProductId = marketProductData:GetId()
    local isHouseMarketProduct, houseTemplateDataList, defaultHouseTemplateIndex = ZO_MarketProduct_GetMarketProductHouseTemplateDataList(marketProductId, function(...) return { GetActiveMarketProductListingsForHouseTemplate(...) } end)

    -- Setup House Collectible Name
    local itemContainerControl = dialog:GetNamedChild("ItemContainer")
    local itemContainerTextContainer = itemContainerControl:GetNamedChild("ItemText")
    local itemNameLabel = itemContainerTextContainer:GetNamedChild("ItemName")

    if isHouseMarketProduct then
        local houseId = GetMarketProductHouseId(marketProductId)
        local houseCollectibleId = GetCollectibleIdForHouse(houseId)
        local houseDisplayName = GetCollectibleName(houseCollectibleId)
        itemNameLabel:SetText(zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, houseDisplayName))
    else
        internalassert(false, "Market Product is not a house")
    end

    -- Setup House Collectible Icon
    local iconTextureControl = itemContainerControl:GetNamedChild("Icon")
    local icon = marketProductData:GetIcon()
    iconTextureControl:SetTexture(icon)

    -- Populate House Template Dropdown
    local function OnTemplateChanged(comboBox, entryText, entry)
        local currencyType
        local marketCurrencyType
        if entry and entry.data then
            local key, value = next(entry.data.marketPurchaseOptions)
            currencyType = GetCurrencyTypeFromMarketCurrencyType(key)
            marketCurrencyType = key

            ZO_CurrencyControl_SetSimpleCurrency(dialog.balanceContainer.currencyAmount, currencyType, GetPlayerMarketCurrency(marketCurrencyType))

            MarketPurchaseConfirmationDialogSetupPricingControls(dialog, comboBox:GetSelectedItemData().data)
            MarketPurchaseSelectTemplateDialogSetupHouseInfoControls(dialog, comboBox:GetSelectedItemData().data)
        end
    end

    local comboBox = dialog.comboBox

    comboBox:ClearItems()

    local defaultTemplateListIndex
    for index, houseTemplateData in pairs(houseTemplateDataList) do
        local currencyType, marketData = next(houseTemplateData.marketPurchaseOptions)
        if houseTemplateData.name and marketData and ((data.isGift and marketData.isGiftable) or (not data.isGift and not marketData.isHouseOwned)) then
            local formattedName = zo_strformat(SI_MARKET_PRODUCT_HOUSE_TEMPLATE_NAME_FORMAT, houseTemplateData.name)
            local entry = comboBox:CreateItemEntry(formattedName, OnTemplateChanged)
            entry.data = houseTemplateData
            comboBox:AddItem(entry, ZO_COMBOBOX_SUPPRESS_UPDATE)

            if index == defaultHouseTemplateIndex then
                defaultTemplateListIndex = comboBox:GetNumItems()
            end
        end
    end

    if comboBox:GetNumItems() > 0 then
        if defaultTemplateListIndex then
            comboBox:SelectItemByIndex(defaultTemplateListIndex)
        else
            comboBox:SelectFirstItem()
        end

        MarketPurchaseConfirmationDialogSetupPricingControls(dialog, comboBox:GetSelectedItemData().data)
        MarketPurchaseSelectTemplateDialogSetupHouseInfoControls(dialog, comboBox:GetSelectedItemData().data)
    end
end

function ZO_MarketPurchaseHouseTemplateSelectDialog_OnInitialized(control)
    control.templateComboBoxControl = control:GetNamedChild("ComboBox")
    control.comboBox = ZO_ComboBox_ObjectFromContainer(control.templateComboBoxControl)

    control.balanceContainer = control:GetNamedChild("BalanceContainer")
    control.costContainer = control:GetNamedChild("CostContainer")
    control.costContainer.previousCost = control.costContainer:GetNamedChild("PreviousCost")
    control.costContainer.textCallout = control.costContainer:GetNamedChild("TextCallout")
    control.esoPlusCostContainer = control:GetNamedChild("EsoPlusCostContainer")

    control.locationContainer = control:GetNamedChild("LocationContainer")
    control.houseTypeContainer = control:GetNamedChild("HouseTypeContainer")
    control.weatherContainer = control:GetNamedChild("WeatherContainer")

    local locationLabel = control.locationContainer:GetNamedChild("Label")
    locationLabel:SetText(zo_strformat(SI_MARKET_SELECT_HOUSE_TEMPLATE_INFO_FORMATTER, GetString(SI_MARKET_PRODUCT_HOUSING_LOCATION_LABEL)))

    local houseTypeLabel = control.houseTypeContainer:GetNamedChild("Label")
    houseTypeLabel:SetText(zo_strformat(SI_MARKET_SELECT_HOUSE_TEMPLATE_INFO_FORMATTER, GetString(SI_MARKET_PRODUCT_HOUSING_HOUSE_TYPE_LABEL)))

    local weatherLabel = control.weatherContainer:GetNamedChild("Label")
    weatherLabel:SetText(zo_strformat(SI_MARKET_SELECT_HOUSE_TEMPLATE_INFO_FORMATTER, GetString(SI_MARKET_PRODUCT_HOUSING_HOUSE_SUPPORTS_WEATHER_CONTROL_LABEL)))

    local anchorControl = control.weatherContainer
    local offsetY = 50
    for furnishingLimitType = HOUSING_FURNISHING_LIMIT_TYPE_ITERATION_BEGIN, HOUSING_FURNISHING_LIMIT_TYPE_ITERATION_END do
        local infoControl = CreateControlFromVirtual("$(parent)HouseInfo", control, "ZO_DialogLabelValueContainer_Keyboard", furnishingLimitType)

        infoControl:ClearAnchors()
        infoControl:SetAnchor(TOPLEFT, anchorControl, BOTTOMLEFT, 0, offsetY)
        infoControl:SetAnchor(TOPRIGHT, anchorControl, BOTTOMRIGHT, 0, offsetY)

        anchorControl = infoControl
        offsetY = 30
    end

    local esoPlusNoteLabel = control:GetNamedChild("EsoPlusNote")
    esoPlusNoteLabel:ClearAnchors()
    esoPlusNoteLabel:SetAnchor(TOP, anchorControl, BOTTOM, 0, offsetY)

    ZO_Dialogs_RegisterCustomDialog(
        "MARKET_PURCHASE_HOUSE_TEMPLATE_SELECTION",
        {
            customControl = control,
            setup = MarketPurchaseHouseTemplateSelectDialogSetup,
            title =
            {
                text = SI_MARKET_SELECT_HOUSE_TEMPLATE_TITLE,
            },
            canQueue = true,
            buttons =
            {
                {
                    control = control:GetNamedChild("Confirm"),
                    text = SI_MARKET_SELECT_HOUSE_TEMPLATE_REVIEW_PURCHASE,
                    callback =  function(dialog, data)
                        local selectedData = dialog.comboBox:GetSelectedItemData().data
                        local currencyType, marketData = next(selectedData.marketPurchaseOptions)
                        if marketData then
                            local marketProductData = ZO_MarketProductData:New(marketData.marketProductId)
                            if dialog.data.isGift then
                                ZO_Market_Keyboard:GiftMarketProduct(marketProductData)
                            else
                                ZO_Market_Keyboard:PurchaseMarketProduct(marketProductData)
                            end
                        end
                    end,
                },
                {
                    control = control:GetNamedChild("Cancel"),
                    text = SI_DIALOG_EXIT,
                },
            },
            finishedCallback = function(dialog)
                ClearTooltipImmediately(InformationTooltip)
            end,
        }
    )
end

local function OnMarketPurchaseResult(data, result, tutorialProductId, wasGift)
    EVENT_MANAGER:UnregisterForEvent("MARKET_PURCHASING", EVENT_MARKET_PURCHASE_RESULT)
    data.result = result
    data.wasGift = wasGift

    if result == MARKET_PURCHASE_RESULT_GIFT_COLLECTIBLE_PARTIALLY_OWNED then
        local displayName = data.marketProductData:GetDisplayName()
        local dialogParams =
        {
            titleParams = { displayName },
        }
        ZO_Dialogs_ReleaseAllDialogsOfName("MARKET_PURCHASING")
        ZO_Dialogs_ShowDialog("MARKET_CROWN_STORE_GIFT_PARTIALLY_OWNED_KEYBOARD", data, dialogParams)
    end

    if not wasGift then
        if tutorialProductId ~= 0 then
            data.tutorialTrigger =
            { 
                trigger = TUTORIAL_TRIGGER_CROWN_STORE_PRODUCT_PURCHASED,
                param = tutorialProductId
            }
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

        local titleText
        local mainText
        if result == MARKET_PURCHASE_RESULT_SUCCESS then
            titleText = GetString(SI_TRANSACTION_COMPLETE_TITLE)

            local marketProductData = data.marketProductData
            local marketProductId = marketProductData:GetId()
            local quantity = data.quantity
            local stackCount = marketProductData:GetStackCount()
            local totalStackCount = stackCount * quantity
            local itemName = data.itemName
            local color = GetItemQualityColor(GetMarketProductDisplayQuality(marketProductId))
            local houseId = GetMarketProductHouseId(marketProductId)
            if houseId > 0 then
                local houseCollectibleId = GetCollectibleIdForHouse(houseId)
                local houseDisplayName = GetCollectibleName(houseCollectibleId)
                itemName = zo_strformat(SI_MARKET_PRODUCT_HOUSE_NAME_GRAMMARLESS_FORMATTER, houseDisplayName, data.itemName)
            end

            if data.wasGift then
                if totalStackCount > 1 then
                    mainText = zo_strformat(SI_MARKET_GIFTING_SUCCESS_TEXT_WITH_QUANTITY, color:Colorize(itemName), totalStackCount, ZO_SELECTED_TEXT:Colorize(data.recipientDisplayName))
                else
                    mainText = zo_strformat(SI_MARKET_GIFTING_SUCCESS_TEXT, color:Colorize(itemName), ZO_SELECTED_TEXT:Colorize(data.recipientDisplayName))
                end
            else
                local useProductInfo = ZO_Market_Shared.GetUseProductInfo(marketProductData)
                if useProductInfo then
                    if useProductInfo.transactionCompleteTitleText then
                        titleText = useProductInfo.transactionCompleteTitleText
                    end
                    mainText = zo_strformat(useProductInfo.transactionCompleteText, color:Colorize(itemName), totalStackCount)

                    local useProductControl = dialog:GetNamedChild("UseProduct")
                    useProductControl:SetHidden(useProductInfo.visible and not useProductInfo.visible())
                    useProductControl:SetEnabled(not useProductInfo.enabled or useProductInfo.enabled())
                    useProductControl:SetText(useProductInfo.buttonText)
                else
                    if totalStackCount > 1 then
                        mainText = zo_strformat(SI_MARKET_PURCHASE_SUCCESS_TEXT_WITH_QUANTITY, color:Colorize(itemName), totalStackCount)
                    elseif marketProductData:GetNumAttachedCollectibles() > 0 then
                        mainText = zo_strformat(SI_MARKET_PURCHASE_SUCCESS_TEXT_WITH_COLLECTIBLE, color:Colorize(itemName))
                    else
                        mainText = zo_strformat(SI_MARKET_PURCHASE_SUCCESS_TEXT, color:Colorize(itemName))
                    end
                end

                -- append ESO Plus savings, if any
                local esoPlusSavingsString = ZO_MarketDialogs_Shared_GetEsoPlusSavingsString(marketProductData, quantity)
                if esoPlusSavingsString then
                    mainText = string.format("%s\n\n%s", mainText, esoPlusSavingsString)
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

        ZO_Dialogs_UpdateDialogMainText(dialog, { text = zo_strformat(SI_MARKET_PURCHASING_TEXT, data.itemName, data.quantity), TEXT_ALIGN_CENTER })
        ZO_Dialogs_SetDialogLoadingIcon(dialog:GetNamedChild("Loading"), dialog:GetNamedChild("Text"), SHOW_LOADING_ICON)
    end
end

local function MarketPurchasingDialogSetup(dialog, data)
    data.result = nil
    data.loadingDelayTimeMS = nil
    data.currentState = MARKET_PURCHASING_STATE_DELAY
    data.quantity = data.quantity or 1
    data.isPreviewingMarketProductPlacement = IsHousingEditorPreviewingMarketProductPlacement()
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
                    control = self:GetNamedChild("UseProduct"),
                    keybind = "DIALOG_RESET",
                    callback = function(dialog)
                        -- Order matters:
                        dialog.data.logPurchasedMarketId = true
                        -- Ensure that we don't try to return to Housing Editor Browse mode again when the scene hides:
                        local isPreviewingMarketProductPlacement = dialog.data.isPreviewingMarketProductPlacement
                        dialog.data.isPreviewingMarketProductPlacement = nil
                        OnPurchaseResolved(dialog)
                        ZO_Market_Shared.GoToUseProductLocation(dialog.data.marketProductData)
                        if isPreviewingMarketProductPlacement and GetHousingEditorMode() ~= HOUSING_EDITOR_MODE_PLACEMENT then
                            -- Manually return to Housing Editor Browse mode unless we are left in Placement mode;
                            -- this occurs when the relevant furnishing limit had already been reached or when this
                            -- purchase did not originate from in-house placement preview.
                            ZO_ReturnToHousingEditorBrowseMode()
                        end
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
                                marketProductData = data.marketProductData,
                                recipientDisplayName = data.recipientDisplayName,
                                note = data.note,
                            }
                            ZO_Dialogs_ShowDialog("MARKET_PURCHASE_CONFIRMATION", restartData)
                            return
                        end

                        data.logPurchasedMarketId = true
                        OnPurchaseResolved(dialog)

                        if data.wasGift == false then
                            local activeMarket = ZO_MARKET_MANAGER:GetActiveMarket()

                            -- Show tutorials from a purchased item first before showing the consumable tutorial
                            if data.tutorialTrigger then
                                TUTORIAL_MANAGER:ShowTutorial(data.tutorialTrigger)
                            end

                            if data.result == MARKET_PURCHASE_RESULT_SUCCESS and data.marketProductData:ContainsConsumables() then
                                TUTORIAL_MANAGER:ShowTutorial(TUTORIAL_TRIGGER_CROWN_CONSUMABLE_PURCHASED)
                            end
                        end
                    end,
                },
            },
        }
    )
end

do
    local editControls = {}

    function ZO_MarketPurchaseConfirmationDialog_RegisterEditControl(control)
        table.insert(editControls, control)
    end

    -- If no control is specified this gives focus to the first registered, visible edit control.
    -- If a registered edit control is specified this gives focus to the next visible edit control that follows the specified control;
    -- note that the edit control list behaves like a circular buffer.
    function ZO_MarketPurchaseConfirmationDialog_FocusNextEditControl(control)
        local numEditControls = #editControls
        if numEditControls == 0 then
            return
        end

        local controlIndex = nil
        if control then
            for index, editControl in ipairs(editControls) do
                if editControl == control then
                    controlIndex = index
                    break
                end
            end

            if not controlIndex then
                return
            end
        end

        local iterations = 0
        local index = controlIndex or 0
        repeat
            index = index + 1
            if index > numEditControls then
                index = 1
            end
            local editControl = editControls[index]
            if not editControl:IsHidden() then
                editControl:TakeFocus()
                break
            end
            iterations = iterations + 1
        until iterations == numEditControls
    end
end