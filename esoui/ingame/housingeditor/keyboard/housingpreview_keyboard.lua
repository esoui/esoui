local HousingPreviewDialog_Keyboard = ZO_HousingPreviewDialog_Shared:Subclass()

function HousingPreviewDialog_Keyboard:New(...)
    return ZO_HousingPreviewDialog_Shared.New(self, ...)
end

function HousingPreviewDialog_Keyboard:Initialize(control)
    ZO_HousingPreviewDialog_Shared.Initialize(self, control, "HOUSE_PREVIEW_PURCHASE")

    SYSTEMS:RegisterKeyboardObject("HOUSING_PREVIEW", self)
end

function HousingPreviewDialog_Keyboard:InitializeTemplateComboBox()
    local comboBox = ZO_ComboBox:New(self.templateComboBoxControl)
    comboBox:SetSortsItems(false)
    comboBox:SetFont("ZoFontWinT1")
    comboBox:SetSpacing(4)
    self.templateComboBox = comboBox
end

function HousingPreviewDialog_Keyboard:BuyFromMarket(control)
    ZO_HousingPreviewDialog_Shared.BuyFromMarket(self, control)
end

function ZO_HousingPreviewDialog_Keyboard_OnInitialized(control)
    HOUSING_PREVIEW_DIALOG_KEYBOARD = HousingPreviewDialog_Keyboard:New(control)
end

function ZO_HousingPreviewDialog_Keyboard_PreviewButton_OnClicked(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        HOUSING_PREVIEW_DIALOG_KEYBOARD:PreviewSelectedTemplate()
    end
end

function ZO_HousingPreviewDialog_Keyboard_BuyForGoldButton_OnClicked(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        HOUSING_PREVIEW_DIALOG_KEYBOARD:BuyForGold(control)
    end
end

function ZO_HousingPreviewDialog_Keyboard_BuyFromMarketButton_OnClicked(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        HOUSING_PREVIEW_DIALOG_KEYBOARD:BuyFromMarket(control)
    end
end