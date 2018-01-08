ZO_GAMEPAD_HOUSING_PREVIEW_IMAGE_TEXTURE_WIDTH = ZO_GAMEPAD_QUADRANT_2_3_WIDTH
ZO_GAMEPAD_HOUSING_PREVIEW_IMAGE_TEXTURE_HEIGHT = (ZO_GAMEPAD_HOUSING_PREVIEW_IMAGE_TEXTURE_WIDTH / ZO_HOUSING_PREVIEW_IMAGE_CANVAS_WIDTH) * ZO_HOUSING_PREVIEW_IMAGE_CANVAS_HEIGHT
ZO_GAMEPAD_HOUSING_PREVIEW_COMBO_BOX_HEIGHT = 58

local HousingPreviewDialog_Gamepad = ZO_HousingPreviewDialog_Shared:Subclass()

function HousingPreviewDialog_Gamepad:New(...)
    return ZO_HousingPreviewDialog_Shared.New(self, ...)
end

function HousingPreviewDialog_Gamepad:Initialize(control)
    ZO_CustomCenteredGamepadDialogTemplate_OnInitialized(control)
    ZO_HousingPreviewDialog_Shared.Initialize(self, control, "HOUSE_PREVIEW_PURCHASE_GAMEPAD")

    self.houseNameLabel = control:GetNamedChild("Title")
    self.houseDescriptionLabel = control:GetNamedChild("Text")
    self:InitializeFoci()

    SYSTEMS:RegisterGamepadObject("HOUSING_PREVIEW", self)
end

function HousingPreviewDialog_Gamepad:InitializeFoci()
    self.sectionSwitcher = ZO_GamepadFocus:New(self.templateComboBoxControl, nil, MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)
    self.templateContainerFocusSwitcher = ZO_GamepadFocus:New(self.templateContainer, nil, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.purchaseOptionsFocusSwitcher = ZO_GamepadFocus:New(self.purchaseOptionsControl, nil, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.purchaseOptionsFocusSwitcher:SetFocusChangedCallback(function(...) self:OnPurchaseSelectionChanged(...) end)

    local templateFocusData =
    {
        activate = function()
            self.templateContainerFocusSwitcher:Activate()
        end,
        deactivate = function()
            self.templateContainerFocusSwitcher:Deactivate()
        end,
        control = self.templateContainer,
    }
    local purchaseOptionsFocusData =
    {
        activate = function()
            self.purchaseOptionsFocusSwitcher:Activate()
        end,
        deactivate = function()
            self.purchaseOptionsFocusSwitcher:Deactivate()
        end,
        control = self.purchaseOptionsControl,
    }
    self.sectionSwitcher:AddEntry(templateFocusData)
    self.sectionSwitcher:AddEntry(purchaseOptionsFocusData)

    templateComboBoxFocusData =
    {
        activate = function()
            self.templateComboBox:SetSelectedColor(ZO_SELECTED_TEXT)
        end,
        deactivate = function() 
            self.templateComboBox:Deactivate()
            self.templateComboBox:SetSelectedColor(ZO_DISABLED_TEXT)
        end,
        highlight = self.templateComboBoxControl:GetNamedChild("Highlight"),
        control = self.templateComboBox,
        callback = function() self.templateComboBox:Activate() end
    }

    templatePreviewButtonFocusData =
    {
        highlight = self.templatePreviewButton:GetNamedChild("Highlight"),
        control = self.templatePreviewButton,
        callback = function() self:PreviewSelectedTemplate() end
    }

    self.templateContainerFocusSwitcher:AddEntry(templateComboBoxFocusData)
    self.templateContainerFocusSwitcher:AddEntry(templatePreviewButtonFocusData)

    local function CreatePurchaseOptionFocusData(control, callback)
        local button = control.button
        control.focusData =
        {
            highlight = button:GetNamedChild("Highlight"),
            control = control,
            callback = function() callback(self, button) end
        }
    end

    CreatePurchaseOptionFocusData(self.goldPurchaseOptionControl, HousingPreviewDialog_Gamepad.BuyForGold)
    CreatePurchaseOptionFocusData(self.crownsPurchaseOptionControl, HousingPreviewDialog_Gamepad.BuyFromMarket)
    CreatePurchaseOptionFocusData(self.crownGemsPurchaseOptionControl, HousingPreviewDialog_Gamepad.BuyFromMarket)
end

function HousingPreviewDialog_Gamepad:InitializeTemplateComboBox()
    local comboBox = ZO_ComboBox_ObjectFromContainer(self.templateComboBoxControl:GetNamedChild("Dropdown"))
    comboBox:SetSelectedColor(ZO_DISABLED_TEXT)
    comboBox:SetSortsItems(false)
    comboBox:SetKeybindAlignment(KEYBIND_STRIP_ALIGN_CENTER)
    self.templateComboBox = comboBox
end

function HousingPreviewDialog_Gamepad:SelectFocusedPurchaseOption()
    local data = self.purchaseOptionsFocusSwitcher:GetFocusItem()
    if data then
        data.callback()
    end
end

function HousingPreviewDialog_Gamepad:SetupPurchaseOptionControl(control, currencyType, currencyLocation, price, priceAfterDiscount, discountPercent, errorStringId)
    ZO_HousingPreviewDialog_Shared.SetupPurchaseOptionControl(self, control, currencyType, currencyLocation, price, priceAfterDiscount, discountPercent, errorStringId)

    local highlightColor = errorStringId and ZO_DEFAULT_DISABLED_COLOR or ZO_DEFAULT_ENABLED_COLOR
    control.button:GetNamedChild("Highlight"):SetEdgeColor(highlightColor:UnpackRGB())
end

function HousingPreviewDialog_Gamepad:OnFilterChanged(entryData)
    ZO_HousingPreviewDialog_Shared.OnFilterChanged(self, entryData)

    local purchaseOptionsFocusSwitcher = self.purchaseOptionsFocusSwitcher
    purchaseOptionsFocusSwitcher:RemoveAllEntries()

    if not self.goldPurchaseOptionControl:IsControlHidden() then
        purchaseOptionsFocusSwitcher:AddEntry(self.goldPurchaseOptionControl.focusData)
    end

    if not self.crownsPurchaseOptionControl:IsControlHidden() then
        purchaseOptionsFocusSwitcher:AddEntry(self.crownsPurchaseOptionControl.focusData)
    end

    if not self.crownGemsPurchaseOptionControl:IsControlHidden() then
        purchaseOptionsFocusSwitcher:AddEntry(self.crownGemsPurchaseOptionControl.focusData)
    end

    -- if we are adding additional lines of text our combo box control may not be tall enough to fit it
    -- we we will have to adjust the height manually, but don't make it any shorter than our default height
    local comboBoxHeight = self.templateComboBox:GetHeight()
    local desiredComboBoxHeight = comboBoxHeight > ZO_GAMEPAD_HOUSING_PREVIEW_COMBO_BOX_HEIGHT and comboBoxHeight or ZO_GAMEPAD_HOUSING_PREVIEW_COMBO_BOX_HEIGHT
    self.templateComboBoxControl:SetHeight(desiredComboBoxHeight)
end

function HousingPreviewDialog_Gamepad:OnPurchaseSelectionChanged(selectionData)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_QUAD1_TOOLTIP)
    if selectionData and selectionData.control then
        local button = selectionData.control.button
        if button.errorString then
            GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_QUAD1_TOOLTIP, button.errorString)
        end
    end
end

function HousingPreviewDialog_Gamepad:BuildDialogInfo()
    ZO_HousingPreviewDialog_Shared.BuildDialogInfo(self)

    self.dialogInfo.gamepadInfo = 
    {
        dialogType = GAMEPAD_DIALOGS.CUSTOM,
        allowShowOnNextScene = true,
        dontEndInWorldInteractions = true,
    }
    self.dialogInfo.canQueue = true
    self.dialogInfo.blockDialogReleaseOnPress = true
    self.dialogInfo.buttons =
    {
        {
            keybind = "DIALOG_PRIMARY",
            text = SI_GAMEPAD_SELECT_OPTION,
            clickSound = SOUNDS.DIALOG_ACCEPT,
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            callback =  function(dialog)
                if self.purchaseOptionsFocusSwitcher:IsActive() then
                    self:SelectFocusedPurchaseOption()
                else
                    local data = self.templateContainerFocusSwitcher:GetFocusItem()
                    if data then
                        data.callback()
                    end
                end
            end,
        },
        {
            keybind = "DIALOG_NEGATIVE",
            text = SI_GAMEPAD_BACK_OPTION,
            clickSound = SOUNDS.DIALOG_DECLINE,
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            callback = function(dialog)
                self:ReleaseDialog()
            end,
        },
        {
            keybind = "DIALOG_SECONDARY",
            text = SI_HOUSING_EDITOR_SAFE_LOC,
            clickSound = SOUNDS.DIALOG_ACCEPT,
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            callback = function(dialog)
                HousingEditorJumpToSafeLocation()
            end,
        },
    }
end

function HousingPreviewDialog_Gamepad:OnDialogShowing()
    ZO_HousingPreviewDialog_Shared.OnDialogShowing(self)
    self.sectionSwitcher:Activate()
    self.sectionSwitcher:SetFocusToMatchingEntry(self.templateComboBox)
    SCENE_MANAGER:SetInUIMode(true)
end

function HousingPreviewDialog_Gamepad:OnDialogReleased()
    ZO_HousingPreviewDialog_Shared.OnDialogReleased(self)
    self.sectionSwitcher:Deactivate()
    SCENE_MANAGER:SetInUIMode(false)
end

-- Global XML functions

function ZO_HousingPreviewDialog_Gamepad_OnInitialized(control)
    ZO_HOUSING_PREVIEW_DIALOG_GAMEPAD = HousingPreviewDialog_Gamepad:New(control)
end