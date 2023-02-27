local HOUSING_PREVIEW_IMAGE_FILE_WIDTH = 1024
local HOUSING_PREVIEW_IMAGE_FILE_HEIGHT = 512
local HOUSING_PREVIEW_IMAGE_FILE_RIGHT_OFFSET = 700
local HOUSING_PREVIEW_IMAGE_FILE_BOTTOM_OFFSET = 400
ZO_HOUSING_PREVIEW_IMAGE_TEXTURE_COORDS_RIGHT = HOUSING_PREVIEW_IMAGE_FILE_RIGHT_OFFSET / HOUSING_PREVIEW_IMAGE_FILE_WIDTH
ZO_HOUSING_PREVIEW_IMAGE_TEXTURE_COORDS_BOTTOM = HOUSING_PREVIEW_IMAGE_FILE_BOTTOM_OFFSET / HOUSING_PREVIEW_IMAGE_FILE_HEIGHT

ZO_HOUSING_PREVIEW_IMAGE_CANVAS_WIDTH = 700
ZO_HOUSING_PREVIEW_IMAGE_CANVAS_HEIGHT = 400
ZO_HOUSING_PREVIEW_INFO_PADDING_X = 20
ZO_HOUSING_PREVIEW_INFO_WIDTH = ZO_HOUSING_PREVIEW_IMAGE_CANVAS_WIDTH - (ZO_HOUSING_PREVIEW_INFO_PADDING_X * 2)
ZO_HOUSING_PREVIEW_ERROR_LABEL_PADDING_X = 10

ZO_HousingPreviewDialog_Shared = ZO_InitializingObject:Subclass()

function ZO_HousingPreviewDialog_Shared:Initialize(control, dialogName)
    self.control = control
    self.houseImageControl = control:GetNamedChild("HouseImage")
    local detailsControl = control:GetNamedChild("Details")
    self.locationDataLabel = detailsControl:GetNamedChild("LocationData")
    self.houseTypeDataLabel = detailsControl:GetNamedChild("HouseTypeData")
    self.notAvailableLabel = control:GetNamedChild("NotAvailableText")
    self.templateContainer = control:GetNamedChild("Template")
    self.templateComboBoxControl = self.templateContainer:GetNamedChild("ComboBox")
    self.templateOptionsContainer = control:GetNamedChild("TemplateOptions")
    self.templatePreviewButton = self.templateOptionsContainer:GetNamedChild("PreviewButton")
    self.templateFurnitureButton = self.templateOptionsContainer:GetNamedChild("FurnitureButton")
    self.purchaseOptionsControl = control:GetNamedChild("PurchaseOptions")
    self.templatePreviewButton.text = GetString(SI_HOUSE_TEMPLATE_PREVIEW_BUTTON_TEXT)
    self.templateFurnitureButton.text = GetString(SI_HOUSING_PREVIEW_TEMPLATE_FURNISHINGS)

    local function SetupPurchaseOptionControl(rootName)
        local purchaseOptionControl = self.purchaseOptionsControl:GetNamedChild(rootName)
        purchaseOptionControl.button = purchaseOptionControl:GetNamedChild("Button")
        purchaseOptionControl.errorLabel = purchaseOptionControl:GetNamedChild("ErrorLabel")
        purchaseOptionControl.textCallout = purchaseOptionControl:GetNamedChild("TextCallout")
        return purchaseOptionControl
    end

    self.goldPurchaseOptionControl = SetupPurchaseOptionControl("Gold")
    self.crownsPurchaseOptionControl = SetupPurchaseOptionControl("Crowns")
    self.crownGemsPurchaseOptionControl = SetupPurchaseOptionControl("CrownGems")
    self.marketPurchaseOptionControlsByCurrencyType =
    {
        [MKCT_CROWNS] = self.crownsPurchaseOptionControl,
        [MKCT_CROWN_GEMS] = self.crownGemsPurchaseOptionControl,
    }

    self.dialogName = dialogName

    self:InitializeTemplateComboBox()
    self:BuildDialogInfo()
    
    ZO_Dialogs_RegisterCustomDialog(self.dialogName, self.dialogInfo)

    self:RegisterForCallbacks()

    self.control:RegisterForEvent(EVENT_PENDING_INTERACTION_CANCELLED, function() if not self.control:IsHidden() then self:ReleaseDialog() end end)
end

function ZO_HousingPreviewDialog_Shared:InitializeTemplateComboBox()
    assert(false) -- Must be overriden
end

function ZO_HousingPreviewDialog_Shared:BuildDialogInfo()
    local function OnDialogReleased()
        self:OnDialogReleased()
    end

    self.dialogInfo =
    {
        setup = function() self:OnDialogShowing() end,
        customControl = self.control,
        finishedCallback = OnDialogReleased,
        noChoiceCallback = OnDialogReleased,
        title =
        {
            text = "",
        },
        mainText =
        {
            text = "",
        },
        headerNarrationFunction = function()
            local narrations = {}

            -- Header
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.dialogInfo.title.text))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_HOUSING_LOCATION_HEADER)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(ZO_CachedStrFormat(SI_ZONE_NAME, ZO_HOUSE_PREVIEW_MANAGER.displayInfo.houseFoundInLocation)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_HOUSING_HOUSE_TYPE_HEADER)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_HOUSE_TYPE_FORMATTER, ZO_HOUSE_PREVIEW_MANAGER.displayInfo.houseCategory)))

            return narrations
        end,
    }
end

function ZO_HousingPreviewDialog_Shared:RegisterForCallbacks()
    local function OnHouseTemplateDataUpdated()
        self.houseTemplatesDirty = true

        if not self.control:IsHidden() then
            self:RefreshTemplateComboBox()
        end
    end

    local function OnPlayerActivated()
        self.displayInfoDirty = true
        self.houseTemplatesDirty = true

        if not self.control:IsHidden() then
            self:RefreshDisplayInfo()
        end
    end

    ZO_HOUSE_PREVIEW_MANAGER:RegisterCallback("OnHouseTemplateDataUpdated", OnHouseTemplateDataUpdated)
    ZO_HOUSE_PREVIEW_MANAGER:RegisterCallback("OnPlayerActivated", OnPlayerActivated)
end

do
    local NO_DATA = nil

    function ZO_HousingPreviewDialog_Shared:RefreshTemplateComboBox()
        local comboBox = self.templateComboBox
        local currentlyPreviewedTemplateId = GetCurrentHousePreviewTemplateId()

        comboBox:ClearItems()

        local function OnFilterChanged(comboBox, entryText, entry)
            self:OnFilterChanged(entry.data)
        end

        local templateData = ZO_HOUSE_PREVIEW_MANAGER:GetFullHouseTemplateData()
        local currentlyPreviewedItemEntryIndex = nil
        for i, data in ipairs(templateData) do
            local formattedName = zo_strformat(SI_MARKET_PRODUCT_HOUSE_TEMPLATE_NAME_FORMAT, data.name)
            local entry = comboBox:CreateItemEntry(formattedName, OnFilterChanged)
            entry.data = data
            comboBox:AddItem(entry, ZO_COMBOBOX_SUPPRESS_UPDATE)
            if data.houseTemplateId == currentlyPreviewedTemplateId then
                currentlyPreviewedItemEntryIndex = i
            end
        end

        local hasTemplateEntries = NonContiguousCount(templateData) > 0
        self:OnTemplatesChanged(hasTemplateEntries, currentlyPreviewedItemEntryIndex)
        self.houseTemplatesDirty = false
    end

    function ZO_HousingPreviewDialog_Shared:OnTemplatesChanged(hasTemplateEntries, currentlyPreviewedItemEntryIndex)
        self.notAvailableLabel:SetHidden(hasTemplateEntries)
        self.templateContainer:SetHidden(not hasTemplateEntries)
        self.templateOptionsContainer:SetHidden(not hasTemplateEntries)
        self.hasValidTemplates = hasTemplateEntries

        if hasTemplateEntries then
            local comboBox = self.templateComboBox
            if currentlyPreviewedItemEntryIndex then
                comboBox:SelectItemByIndex(currentlyPreviewedItemEntryIndex)
            else
                comboBox:SelectFirstItem()
            end
        else
            self:OnFilterChanged(NO_DATA)
        end
    end
end

function ZO_HousingPreviewDialog_Shared:RefreshDisplayInfo()
    local displayInfo = ZO_HOUSE_PREVIEW_MANAGER:GetDisplayInfo()
    self.dialogInfo.title.text = displayInfo.houseName
    self.locationDataLabel:SetText(ZO_CachedStrFormat(SI_ZONE_NAME, displayInfo.houseFoundInLocation))
    self.houseTypeDataLabel:SetText(zo_strformat(SI_HOUSE_TYPE_FORMATTER, displayInfo.houseCategory))
    self.houseImageControl:SetTexture(displayInfo.backgroundImage)

    self.displayInfoDirty = false
end

do
    local DONT_USE_SHORT_FORMAT = false
    local NO_ERROR = nil

    local function ResetPurchaseOptionControl(control)
        control:SetHidden(true)
        control:SetWidth(0)
    end

    function ZO_HousingPreviewDialog_Shared:SetupPurchaseOptionControl(control, currencyType, currencyLocation, price, priceAfterDiscount, discountPercent, requiredToBuyErrorText, getRemainingTimeFunction)
        control:SetHidden(false)

        local priceText = ZO_CurrencyControl_FormatCurrencyAndAppendIcon(priceAfterDiscount, DONT_USE_SHORT_FORMAT, currencyType, IsInGamepadPreferredMode())
        local currencyColor = ZO_SELECTED_TEXT
        if requiredToBuyErrorText then
            currencyColor = ZO_DISABLED_TEXT
        elseif (currencyType ~= CURT_CROWNS and currencyType ~= CURT_CROWN_GEMS) and GetCurrencyAmount(currencyType, currencyLocation) < priceAfterDiscount then
            currencyColor = ZO_ERROR_COLOR
        end

        priceText = currencyColor:Colorize(priceText)

        local noError = requiredToBuyErrorText == nil
        local onSale = discountPercent > 0
        control.errorLabel:SetHidden(noError)

        if noError and onSale then
            local calloutUpdateHandler
            self:UpdateSaleRemainingTimeCalloutText(control, discountPercent, getRemainingTimeFunction)
            local remainingTime = getRemainingTimeFunction and getRemainingTimeFunction(control, discountPercent) or 0
            if remainingTime > 0 then
                calloutUpdateHandler = function() self:UpdateSaleRemainingTimeCalloutText(control, discountPercent, getRemainingTimeFunction) end
            else
                calloutUpdateHandler = nil
            end

            control.textCallout:SetHandler("OnUpdate", calloutUpdateHandler)
        else
            control.textCallout:SetHidden(true)
        end

        local buttonControl = control.button

        local priceLabel = buttonControl:GetNamedChild("Price")
        if priceLabel then
            priceLabel:SetText(priceText)
            priceLabel:ClearAnchors()

            local previousPriceLabel = buttonControl:GetNamedChild("PreviousPrice")
            if onSale then
                local formattedAmount = zo_strformat(SI_NUMBER_FORMAT, price)
                local strikethroughAmountString = zo_strikethroughTextFormat(formattedAmount)
                previousPriceLabel:SetText(strikethroughAmountString)
                previousPriceLabel:ClearAnchors()

                -- We want to layout the two price controls so that they appear centered within the "button"
                -- so we need to offset the previousPriceLabel based on the overall width of the two controls
                local halfPriceLabelsWidth = (previousPriceLabel:GetWidth() + priceLabel:GetWidth()) / 2
                local previousPriceOffsetX = -(halfPriceLabelsWidth - previousPriceLabel:GetWidth())

                previousPriceLabel:SetAnchor(RIGHT, buttonControl, CENTER, previousPriceOffsetX)

                priceLabel:SetAnchor(LEFT, previousPriceLabel, RIGHT, 10)
            else
                priceLabel:SetAnchor(CENTER, buttonControl, CENTER)
            end

            previousPriceLabel:SetHidden(not onSale)
        end
        buttonControl.price = priceAfterDiscount
        buttonControl.errorString = requiredToBuyErrorText

        control:SetWidth(self.purchaseOptionSectionWidth)
        control.errorLabel:SetWidth(self.purchaseOptionSectionWidth - (ZO_HOUSING_PREVIEW_ERROR_LABEL_PADDING_X * 2))
    end

    function ZO_HousingPreviewDialog_Shared:GetMarketProductSaleRemainingTime(control, discountPercent)
        local purchaseData = control and control.button and control.button.purchaseData
        local marketProductId = purchaseData and purchaseData.marketProductId

        return GetMarketProductSaleTimeLeftInSeconds(marketProductId)
    end

    function ZO_HousingPreviewDialog_Shared:UpdateSaleRemainingTimeCalloutText(control, discountPercent, getRemainingTimeFunction)
        local discountPercentText = zo_strformat(SI_MARKET_DISCOUNT_PRICE_PERCENT_FORMAT, discountPercent)
        local remainingTime = getRemainingTimeFunction and getRemainingTimeFunction(control, discountPercent) or 0
        -- if there is no time left remaining then the MarketProduct is not limited time
        -- because when a limited time product reaches 0 it is removed from the store
        if remainingTime > 0 and remainingTime <= ZO_ONE_MONTH_IN_SECONDS then
            local remainingTimeText
            if remainingTime >= ZO_ONE_DAY_IN_SECONDS then
                remainingTimeText = ZO_FormatTime(remainingTime, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS)
                control.textCallout:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
            else
                remainingTimeText = ZO_FormatTimeLargestTwo(remainingTime, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL)
                control.textCallout:SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
            end
            local calloutText = string.format("%s %s", discountPercentText, remainingTimeText)
            control.textCallout:SetText(calloutText)
        else
            control.textCallout:SetText(discountPercentText)
        end

        control.textCallout:SetHidden(false)
    end

    function ZO_HousingPreviewDialog_Shared:OnFilterChanged(entryData)
        ResetPurchaseOptionControl(self.goldPurchaseOptionControl)
        ResetPurchaseOptionControl(self.crownsPurchaseOptionControl)
        ResetPurchaseOptionControl(self.crownGemsPurchaseOptionControl)

        if entryData then
            local currentHousePreviewTemplateId = GetCurrentHousePreviewTemplateId()

            if currentHousePreviewTemplateId ~= entryData.houseTemplateId then
                self.houseTemplateIdToPreview = entryData.houseTemplateId
            else
                self.houseTemplateIdToPreview =  nil
            end

            --Figure out how wide the purchase options should be
            local numShownButtons = 0
            if entryData.goldStoreEntryIndex then
                numShownButtons = numShownButtons + 1
            end
            if entryData.marketPurchaseOptions then
                numShownButtons = numShownButtons + NonContiguousCount(entryData.marketPurchaseOptions)
            end

            self.purchaseOptionSectionWidth = ZO_HOUSING_PREVIEW_INFO_WIDTH / numShownButtons

            --Setup individual options
            if entryData.goldStoreEntryIndex then
                local NO_DISCOUNT_PERCENT = 0
                self:SetupPurchaseOptionControl(self.goldPurchaseOptionControl, CURT_MONEY, CURRENCY_LOCATION_CHARACTER, entryData.goldPrice, entryData.goldPrice, NO_DISCOUNT_PERCENT, entryData.requiredToBuyErrorText)
                self.goldPurchaseOptionControl.button.goldStoreEntryIndex = entryData.goldStoreEntryIndex
                self.goldPurchaseOptionControl.button.templateName = entryData.name
            end

            if entryData.marketPurchaseOptions then
                for marketCurrencyType, purchaseData in pairs(entryData.marketPurchaseOptions) do
                    local marketControl = self.marketPurchaseOptionControlsByCurrencyType[marketCurrencyType]
                    local currencyType = GetCurrencyTypeFromMarketCurrencyType(marketCurrencyType)
                    --Currently there are no requirement failures for market options, but there could be in the future, and here is where we would handle them
                    self:SetupPurchaseOptionControl(marketControl, currencyType, CURRENCY_LOCATION_ACCOUNT, purchaseData.cost, purchaseData.costAfterDiscount, purchaseData.discountPercent, NO_ERROR, function(...) return self:GetMarketProductSaleRemainingTime(...) end)
                    marketControl.button.purchaseData = purchaseData
                end
            end
        end
    end
end

function ZO_HousingPreviewDialog_Shared:ShowDialog()
    if self.displayInfoDirty then
        self:RefreshDisplayInfo()
    end

    ZO_Dialogs_ShowPlatformDialog(self.dialogName)

    if self.houseTemplatesDirty then
        self:RefreshTemplateComboBox()
    end
end

function ZO_HousingPreviewDialog_Shared:OnDialogShowing()
    StopAllMovement()
    RequestOpenHouseStore()
    ZO_HOUSE_PREVIEW_MANAGER:RequestOpenMarket()
end

function ZO_HousingPreviewDialog_Shared:ReleaseDialog()
    ZO_Dialogs_ReleaseDialog(self.dialogName)
end

function ZO_HousingPreviewDialog_Shared:OnDialogReleased()
    OnMarketClose()
    PlaySound(SOUNDS.HOUSING_EDITOR_CLOSED)
end

function ZO_HousingPreviewDialog_Shared:IsShowing()
    return ZO_Dialogs_IsShowing(self.dialogName)
end

function ZO_HousingPreviewDialog_Shared:PreviewSelectedTemplate()
    if self.houseTemplateIdToPreview then
        HousingEditorPreviewTemplate(self.houseTemplateIdToPreview)
    end

    self:ReleaseDialog()

    -- Force the cached furniture data to refresh to reflect the new template preview, if any.
    SHARED_FURNITURE:RebuildFurnitureCaches()
end

function ZO_HousingPreviewDialog_Shared:BuyForGold(control)
    if control.price and GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER) < control.price then
        ZO_AlertEvent(EVENT_UI_ERROR, SI_ERROR_CANT_AFFORD_OPTION)
    elseif control.errorString then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.GENERAL_ALERT_ERROR, control.errorString)
    else
        self:ReleaseDialog()
        RequestOpenHouseStore()

        local displayInfo = ZO_HOUSE_PREVIEW_MANAGER:GetDisplayInfo()
        local mainTextParams =
        {
            displayInfo.houseName,
            control.templateName,
            ZO_CurrencyControl_FormatCurrencyAndAppendIcon(control.price, DONT_USE_SHORT_FORMAT, CURT_MONEY, IsInGamepadPreferredMode()),
        }
        local mainTextNarrationParams =
        {
            displayInfo.houseName,
            control.templateName,
            ZO_Currency_FormatGamepad(CURT_MONEY, control.price, ZO_CURRENCY_FORMAT_AMOUNT_NAME),
        }
        ZO_Dialogs_ShowPlatformDialog("CONFIRM_BUY_HOUSE_FOR_GOLD", { goldStoreEntryIndex = control.goldStoreEntryIndex }, { mainTextParams = mainTextParams, mainTextNarrationParams = mainTextNarrationParams })
    end
end

function ZO_HousingPreviewDialog_Shared:BuyFromMarket(control)
    self:ReleaseDialog()
    local IS_PURCHASE = false
    RequestPurchaseMarketProduct(control.purchaseData.marketProductId, control.purchaseData.presentationIndex, IS_PURCHASE)
end