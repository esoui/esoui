local HousingPreviewDialog_Keyboard = ZO_HousingPreviewDialog_Shared:Subclass()

function HousingPreviewDialog_Keyboard:Initialize(control)
    ZO_HousingPreviewDialog_Shared.Initialize(self, control, "HOUSE_PREVIEW_PURCHASE")
    self.returnToEntranceButton = control:GetNamedChild("GoToEntrance")

    self.enableInspectionCheckBox = self.templateContainer:GetNamedChild("EnableInspectionCheckBox")
    ZO_CheckButton_SetToggleFunction(self.enableInspectionCheckBox, function() HousingEditorTogglePreviewInspectionEnabled() end)
    ZO_CheckButton_SetLabelText(self.enableInspectionCheckBox, GetString(SI_HOUSING_ENABLE_PREVIEW_INSPECTION_MODE_CHECKBOX))
    ZO_CheckButton_SetTooltipEnabledState(self.enableInspectionCheckBox, true)
    ZO_CheckButton_SetTooltipAnchor(self.enableInspectionCheckBox, TOP, self.enableInspectionCheckBox)
    ZO_CheckButton_SetTooltipText(self.enableInspectionCheckBox, GetString(SI_HOUSING_ENABLE_PREVIEW_INSPECTION_MODE_TOOLTIP))
    self:OnPreviewInspectionStateChanged()

    SYSTEMS:RegisterKeyboardObject("HOUSING_PREVIEW", self)
    self:InitializePurchaseButtons()

    self.control:RegisterForEvent(EVENT_HOUSING_PREVIEW_INSPECTION_STATE_CHANGED, function() self:OnPreviewInspectionStateChanged() end)
end

function HousingPreviewDialog_Keyboard:InitializeTemplateComboBox()
    local comboBox = ZO_ComboBox_ObjectFromContainer(self.templateComboBoxControl)
    comboBox:SetSortsItems(false)
    comboBox:SetFont("ZoFontWinT1")
    comboBox:SetSpacing(4)
    self.templateComboBox = comboBox
end

function HousingPreviewDialog_Keyboard:InitializePurchaseButtons()
    self:InitializePurchaseButton(self.goldPurchaseOptionControl.button, function(control) self:BuyForGold(control) end)
    self:InitializePurchaseButton(self.crownsPurchaseOptionControl.button, function(control) self:BuyFromMarket(control) end)
    self:InitializePurchaseButton(self.crownGemsPurchaseOptionControl.button, function(control) self:BuyFromMarket(control) end)
end

function HousingPreviewDialog_Keyboard:InitializePurchaseButton(buttonControl, callback)
    buttonControl.backgroundTextureControl = buttonControl:GetNamedChild("Bg")
    buttonControl.highlightTextureControl = buttonControl:GetNamedChild("Highlight")
    buttonControl.priceControl = buttonControl:GetNamedChild("Price")
    buttonControl.clickCallback = callback
    buttonControl.enabled = true
end

function HousingPreviewDialog_Keyboard:SetupPurchaseOptionControl(control, currencyType, currencyLocation, price, priceAfterDiscount, discountPercent, requiredToBuyErrorText, getRemainingTimeFunction)
    ZO_HousingPreviewDialog_Shared.SetupPurchaseOptionControl(self, control, currencyType, currencyLocation, price, priceAfterDiscount, discountPercent, requiredToBuyErrorText, getRemainingTimeFunction)

    local buttonEnabled = requiredToBuyErrorText == nil
    control.button.enabled = buttonEnabled

    if buttonEnabled then
        control.button.backgroundTextureControl:SetTexture("EsoUI/Art/Buttons/ESO_buttonLarge_normal.dds")
    else
        control.button.backgroundTextureControl:SetTexture("EsoUI/Art/Buttons/ESO_buttonLarge_disabled.dds")
    end

end

function HousingPreviewDialog_Keyboard:RefreshTemplateComboBox()
    ZO_HousingPreviewDialog_Shared.RefreshTemplateComboBox(self)

    self.returnToEntranceButton:ClearAnchors()
    if self.notAvailableLabel:IsControlHidden() then
        self.returnToEntranceButton:SetAnchor(TOPLEFT, self.templateFurnitureButton, TOPRIGHT, 5, 0)
    else
        self.returnToEntranceButton:SetAnchor(BOTTOM, nil, nil, 0, -30)
    end
end

function HousingPreviewDialog_Keyboard:OnPreviewInspectionStateChanged()
    ZO_CheckButton_SetCheckState(self.enableInspectionCheckBox, HousingEditorIsPreviewInspectionEnabled())
end

function HousingPreviewDialog_Keyboard:OnTemplatesChanged(hasTemplateEntries, currentlyPreviewedItemEntryIndex)
    ZO_HousingPreviewDialog_Shared.OnTemplatesChanged(self, hasTemplateEntries, currentlyPreviewedItemEntryIndex)

    self.enableInspectionCheckBox:SetHidden(not hasTemplateEntries)
end

-- Global XML functions

function ZO_HousingPreviewDialog_Keyboard_OnInitialized(control)
    ZO_HOUSING_PREVIEW_DIALOG_KEYBOARD = HousingPreviewDialog_Keyboard:New(control)
end

function ZO_HousingPreviewDialog_Keyboard_PreviewButton_OnClicked(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        ZO_HOUSING_PREVIEW_DIALOG_KEYBOARD:PreviewSelectedTemplate()
    end
end

function ZO_HousingPreviewDialog_Keyboard_FurnitureButton_OnClicked(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        ZO_HOUSING_PREVIEW_DIALOG_KEYBOARD:PreviewSelectedTemplate()
        HOUSING_EDITOR_SHARED:ShowFurnitureBrowser()
    end
end

function ZO_HousingPreviewDialog_Keyboard_GoToEntrance_OnClick(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        ZO_HOUSING_PREVIEW_DIALOG_KEYBOARD:ReleaseDialog()
        HousingEditorJumpToSafeLocation()
    end
end

function ZO_HousingPreviewDialog_PurchaseOptionButton_Keyboard_OnMouseUp(control, mouseButton, upInside)
    if mouseButton == MOUSE_BUTTON_INDEX_LEFT and upInside and control.enabled then
        control.clickCallback(control)
        PlaySound(SOUNDS.DEFAULT_CLICK)
    end
end

do
    local function OnMouseEnterPurchaseOption(control)
        local purchaseButton = control.button
        if purchaseButton.errorString then
            InitializeTooltip(InformationTooltip, purchaseButton, RIGHT)
            SetTooltipText(InformationTooltip, purchaseButton.errorString)
        end
    end

    local function OnMouseExitPurchaseOption(control)
        ClearTooltip(InformationTooltip)
    end

    function ZO_HousingPreviewDialog_PurchaseOptionButton_Keyboard_OnMouseEnter(control)
        if control.enabled then
            control.highlightTextureControl:SetHidden(false)
            control.priceControl:SetColor(ZO_HIGHLIGHT_TEXT:UnpackRGBA())
        end

        OnMouseEnterPurchaseOption(control:GetParent())
    end

    function ZO_HousingPreviewDialog_PurchaseOptionButton_Keyboard_OnMouseExit(control)
        if control.enabled then
            control.highlightTextureControl:SetHidden(true)
            control.priceControl:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
        end

        OnMouseExitPurchaseOption(control:GetParent())
    end

    function ZO_HousingPreviewDialog_PurchaseOptionErrorLabel_Keyboard_OnMouseEnter(control)
        OnMouseEnterPurchaseOption(control:GetParent())
    end

    function ZO_HousingPreviewDialog_PurchaseOptionErrorLabel_Keyboard_OnMouseExit(control)
        OnMouseExitPurchaseOption(control:GetParent())
    end
end