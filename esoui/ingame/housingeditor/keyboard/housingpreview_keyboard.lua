local HousingPreviewDialog_Keyboard = ZO_HousingPreviewDialog_Shared:Subclass()

function HousingPreviewDialog_Keyboard:New(...)
    return ZO_HousingPreviewDialog_Shared.New(self, ...)
end

function HousingPreviewDialog_Keyboard:Initialize(control)
    ZO_HousingPreviewDialog_Shared.Initialize(self, control, "HOUSE_PREVIEW_PURCHASE")

    SYSTEMS:RegisterKeyboardObject("HOUSING_PREVIEW", self)
    self:InitializePurchaseButtons()
end

function HousingPreviewDialog_Keyboard:InitializeTemplateComboBox()
    local comboBox = ZO_ComboBox:New(self.templateComboBoxControl)
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

function HousingPreviewDialog_Keyboard:SetupPurchaseOptionControl(control, currencyType, currencyLocation, price, priceAfterDiscount, discountPercent, errorStringId, getRemainingTimeFunction)
    ZO_HousingPreviewDialog_Shared.SetupPurchaseOptionControl(self, control, currencyType, currencyLocation, price, priceAfterDiscount, discountPercent, errorStringId, getRemainingTimeFunction)

    local buttonEnabled = errorStringId == nil
    control.button.enabled = buttonEnabled

    if buttonEnabled then
        control.button.backgroundTextureControl:SetTexture("EsoUI/Art/Buttons/ESO_buttonLarge_normal.dds")
    else
        control.button.backgroundTextureControl:SetTexture("EsoUI/Art/Buttons/ESO_buttonLarge_disabled.dds")
    end

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
