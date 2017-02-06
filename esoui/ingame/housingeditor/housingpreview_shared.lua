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

ZO_HousingPreviewDialog_Shared = ZO_Object:Subclass()

function ZO_HousingPreviewDialog_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_HousingPreviewDialog_Shared:Initialize(control, dialogName)
    self.control = control
    self.houseImageControl = control:GetNamedChild("HouseImage")
    local detailsControl = control:GetNamedChild("Details")
    self.locationDataLabel = detailsControl:GetNamedChild("LocationData")
    self.houseTypeDataLabel = detailsControl:GetNamedChild("HouseTypeData")
    self.notAvailableLabel = control:GetNamedChild("NotAvailableText")
    self.templateContainer = control:GetNamedChild("Template")
    self.templateComboBoxControl = self.templateContainer:GetNamedChild("ComboBox")
    self.templatePreviewButton = self.templateContainer:GetNamedChild("PreviewButton")
    self.purchaseOptionsControl = control:GetNamedChild("PurchaseOptions")

    local function SetupPurchaseOptionControl(rootName)
        local purchaseOptionControl = self.purchaseOptionsControl:GetNamedChild(rootName)
        purchaseOptionControl.button = purchaseOptionControl:GetNamedChild("Button")
        purchaseOptionControl.currencyNameLabel = purchaseOptionControl:GetNamedChild("CurrencyNameLabel")
        purchaseOptionControl.errorLabel = purchaseOptionControl:GetNamedChild("ErrorLabel")
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
    }
end

function ZO_HousingPreviewDialog_Shared:RegisterForCallbacks()
    HOUSE_PREVIEW_MANAGER:RegisterCallback("OnHouseTemplateDataUpdated", function() self:RefreshTemplateComboBox() end)
    HOUSE_PREVIEW_MANAGER:RegisterCallback("OnPlayerActivated", function() self:RefreshDisplayInfo() end)
end

do
    local NO_DATA = nil

    function ZO_HousingPreviewDialog_Shared:RefreshTemplateComboBox()
        local comboBox = self.templateComboBox
    
        local currentlyPreviewedTemplateId = GetCurrentHousePreviewTemplateId()

        comboBox:ClearItems()

        local templateData = HOUSE_PREVIEW_MANAGER:GetFullHouseTemplateData()

        local function OnFilterChanged(comboBox, entryText, entry)
            self:OnFilterChanged(entry.data)
        end

        local currentlyPreviewedItemEntryIndex
        for i, data in ipairs(templateData) do
            local localizedName = zo_strformat(SI_HOUSE_TEMPLATE_NAME_FORMAT, data.name)
            local entry = comboBox:CreateItemEntry(localizedName, OnFilterChanged)
            entry.data = data
            comboBox:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
            if data.houseTemplateId == currentlyPreviewedTemplateId then
                currentlyPreviewedItemEntryIndex = i
            end
        end

        local hasTemplateEntries = NonContiguousCount(templateData) > 0
        self.notAvailableLabel:SetHidden(hasTemplateEntries)
        self.templateContainer:SetHidden(not hasTemplateEntries)
        if hasTemplateEntries then
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
    local displayInfo = HOUSE_PREVIEW_MANAGER:GetDisplayInfo()
    self.dialogInfo.title.text = displayInfo.houseName
    self.locationDataLabel:SetText(ZO_CachedStrFormat(SI_ZONE_NAME, displayInfo.houseFoundInLocation))
    self.houseTypeDataLabel:SetText(displayInfo.houseCategory)
    self.houseImageControl:SetTexture(displayInfo.backgroundImage)
end

do
    local DONT_USE_SHORT_FORMAT = false
    local NOT_GAME_CURRENCY = nil
    local NOT_MARKET_CURRENCY = nil
    local NO_ERROR = nil

    local function ResetPurchaseOptionControl(control)
        control:SetHidden(true)
        control:SetWidth(0)
    end

    function ZO_HousingPreviewDialog_Shared:SetupPurchaseOptionControl(control, price, gameCurrency, marketCurrency, errorStringId)
        control:SetHidden(false)
    
        local uiCurrency = gameCurrency or ZO_Currency_MarketCurrencyToUICurrency(marketCurrency)

        local priceText = ZO_CurrencyControl_FormatCurrencyAndAppendIcon(price, DONT_USE_SHORT_FORMAT, uiCurrency, IsInGamepadPreferredMode())
        local currencyColor = ZO_SELECTED_TEXT
        local noError = true
        if errorStringId then
            control.errorLabel:SetText(GetErrorString(errorStringId))
            noError = false
            currencyColor = ZO_DISABLED_TEXT
        elseif gameCurrency and GetCarriedCurrencyAmount(gameCurrency) < price then
            currencyColor = ZO_ERROR_COLOR
        end

        priceText = currencyColor:Colorize(priceText)

        control.button:SetEnabled(noError)
        control.currencyNameLabel:SetHidden(not noError)
        control.errorLabel:SetHidden(noError)

        control.button:SetText(priceText)
        control.button.price = price
        control.button.errorStringId = errorStringId
        control:SetWidth(self.purchaseOptionSectionWidth)
        control.errorLabel:SetWidth(self.purchaseOptionSectionWidth - (ZO_HOUSING_PREVIEW_ERROR_LABEL_PADDING_X * 2))
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
                self:SetupPurchaseOptionControl(self.goldPurchaseOptionControl, entryData.goldPrice, CURT_MONEY, NOT_MARKET_CURRENCY, entryData.requirementsToBuyErrorId)
                self.goldPurchaseOptionControl.button.goldStoreEntryIndex = entryData.goldStoreEntryIndex
                self.goldPurchaseOptionControl.button.templateName = entryData.name
            end

            if entryData.marketPurchaseOptions then
                for currencyType, purchaseData in pairs(entryData.marketPurchaseOptions) do
                    local marketControl = self.marketPurchaseOptionControlsByCurrencyType[currencyType]
                    --Currently there are no requirement failures for market options, but there could be in the future, and here is where we would handle them
                    self:SetupPurchaseOptionControl(marketControl, purchaseData.cost, NOT_GAME_CURRENCY, currencyType, NO_ERROR)
                    marketControl.button.purchaseData = purchaseData
                end
            end
        end
    end
end

function ZO_HousingPreviewDialog_Shared:ShowDialog()
    ZO_Dialogs_ShowPlatformDialog(self.dialogName)
end

function ZO_HousingPreviewDialog_Shared:OnDialogShowing()
    RequestOpenHouseStore()
    HOUSE_PREVIEW_MANAGER:RequestOpenMarket()
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
end

function ZO_HousingPreviewDialog_Shared:BuyForGold(control)
    if control.price and GetCarriedCurrencyAmount(CURT_MONEY) < control.price then
        ZO_AlertEvent(EVENT_UI_ERROR, SI_ERROR_CANT_AFFORD_OPTION)
    elseif control.errorStringId then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.GENERAL_ALERT_ERROR, GetErrorString(control.errorStringId))
    else
        self:ReleaseDialog()
        RequestOpenHouseStore()
        local priceText = ZO_CurrencyControl_FormatCurrencyAndAppendIcon(control.price, DONT_USE_SHORT_FORMAT, CURT_MONEY, IsInGamepadPreferredMode())
        local displayInfo = HOUSE_PREVIEW_MANAGER:GetDisplayInfo()
        ZO_Dialogs_ShowPlatformDialog("CONFIRM_BUY_HOUSE_FOR_GOLD", { goldStoreEntryIndex = control.goldStoreEntryIndex }, { mainTextParams={ displayInfo.houseName, control.templateName, priceText }})
    end
end

function ZO_HousingPreviewDialog_Shared:BuyFromMarket(control)
    self:ReleaseDialog()
    RequestPurchaseMarketProduct(control.purchaseData.marketProductId, control.purchaseData.presentationIndex)
end