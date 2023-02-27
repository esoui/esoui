ZO_GAMEPAD_HOUSING_PREVIEW_IMAGE_TEXTURE_WIDTH = ZO_GAMEPAD_QUADRANT_2_3_WIDTH
ZO_GAMEPAD_HOUSING_PREVIEW_IMAGE_TEXTURE_HEIGHT = (ZO_GAMEPAD_HOUSING_PREVIEW_IMAGE_TEXTURE_WIDTH / ZO_HOUSING_PREVIEW_IMAGE_CANVAS_WIDTH) * ZO_HOUSING_PREVIEW_IMAGE_CANVAS_HEIGHT
ZO_GAMEPAD_HOUSING_PREVIEW_COMBO_BOX_WIDTH = 515
ZO_GAMEPAD_HOUSING_PREVIEW_COMBO_BOX_HEIGHT = 58
ZO_GAMEPAD_HOUSING_PREVIEW_BUTTON_WIDTH = 240
ZO_GAMEPAD_HOUSING_PREVIEW_BUTTON_MARGIN = 35

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
    local function OnFocusChanged()
        SCREEN_NARRATION_MANAGER:QueueDialog(self.control)
    end

    local templateComboBoxFocusData =
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
        callback = function() self.templateComboBox:Activate() end,
        narrationText = function()
            local narrations = {}
            if self.templateComboBox then
                ZO_AppendNarration(narrations, self.templateComboBox:GetNarrationText())
            end
            return narrations
        end,
    }

    local DEFAULT_MOVEMENT_CONTROLLER = nil
    self.templateContainerFocusSwitcher = ZO_GamepadFocus:New(self.templateContainer, DEFAULT_MOVEMENT_CONTROLLER, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.templateContainerFocusSwitcher:AddEntry(templateComboBoxFocusData)

    local templatePreviewButtonFocusData =
    {
        highlight = self.templatePreviewButton:GetNamedChild("Highlight"),
        control = self.templatePreviewButton,
        callback = function()
            self:PreviewSelectedTemplate()
        end,
        narrationText = function()
            local narrations = {}
            if self.templatePreviewButton.text then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.templatePreviewButton.text))
            end
            return narrations
        end,
    }

    local templateFurnitureButtonFocusData =
    {
        highlight = self.templateFurnitureButton:GetNamedChild("Highlight"),
        control = self.templateFurnitureButton,
        callback = function()
            self:PreviewSelectedTemplate()
            self:ReleaseDialog()
            HOUSING_EDITOR_SHARED:ShowFurnitureBrowser()
        end,
        narrationText = function()
            local narrations = {}
            if self.templateFurnitureButton.text then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.templateFurnitureButton.text))
            end
            return narrations
        end,
    }

    self.templateOptionsContainerFocusSwitcher = ZO_GamepadFocus:New(self.templateOptionsContainer, DEFAULT_MOVEMENT_CONTROLLER, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.templateOptionsContainerFocusSwitcher:AddEntry(templatePreviewButtonFocusData)
    self.templateOptionsContainerFocusSwitcher:AddEntry(templateFurnitureButtonFocusData)
    self.templateOptionsContainerFocusSwitcher:SetFocusChangedCallback(OnFocusChanged)

    local function CreatePurchaseOptionFocusData(control, callback, currencyType)
        local button = control.button
        control.focusData =
        {
            highlight = button:GetNamedChild("Highlight"),
            control = control,
            callback = function() callback(self, button) end,
            narrationText = function()
                local narrations = {}
                if button.price then
                    local priceText = ZO_Currency_FormatGamepad(currencyType, button.price, ZO_CURRENCY_FORMAT_AMOUNT_NAME)
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(priceText))
                    if button.errorString then
                        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_HOUSE_TEMPLATE_UNMET_REQUIREMENTS_TEXT)))
                        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:GetTooltipNarration())
                    end
                end
                return narrations
            end
        }
    end

    CreatePurchaseOptionFocusData(self.goldPurchaseOptionControl, HousingPreviewDialog_Gamepad.BuyForGold, CURT_MONEY)
    CreatePurchaseOptionFocusData(self.crownsPurchaseOptionControl, HousingPreviewDialog_Gamepad.BuyFromMarket, CURT_CROWNS)
    CreatePurchaseOptionFocusData(self.crownGemsPurchaseOptionControl, HousingPreviewDialog_Gamepad.BuyFromMarket, CURT_CROWN_GEMS)

    self.purchaseOptionsFocusSwitcher = ZO_GamepadFocus:New(self.purchaseOptionsControl, DEFAULT_MOVEMENT_CONTROLLER, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.purchaseOptionsFocusSwitcher:SetFocusChangedCallback(function(...) self:OnPurchaseSelectionChanged(...) end)

    local templateFocusData =
    {
        activate = function()
            self.templateContainerFocusSwitcher:Activate()
            SCREEN_NARRATION_MANAGER:QueueDialog(self.control)
        end,
        deactivate = function()
            self.templateContainerFocusSwitcher:Deactivate()
        end,
        control = self.templateContainer,
    }

    local templateOptionsFocusData =
    {
        activate = function()
            self.templateOptionsContainerFocusSwitcher:Activate()
            SCREEN_NARRATION_MANAGER:QueueDialog(self.control)
        end,
        deactivate = function()
            self.templateOptionsContainerFocusSwitcher:Deactivate()
        end,
        control = self.templateOptionsContainer,
    }

    local purchaseOptionsFocusData =
    {
        activate = function()
            self.purchaseOptionsFocusSwitcher:Activate()
            SCREEN_NARRATION_MANAGER:QueueDialog(self.control)
        end,
        deactivate = function()
            self.purchaseOptionsFocusSwitcher:Deactivate()
        end,
        control = self.purchaseOptionsControl,
    }

    self.sectionSwitcher = ZO_GamepadFocus:New(self.templateComboBoxControl, DEFAULT_MOVEMENT_CONTROLLER, MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)
    self.sectionSwitcher:AddEntry(templateFocusData)
    self.sectionSwitcher:AddEntry(templateOptionsFocusData)
    self.sectionSwitcher:AddEntry(purchaseOptionsFocusData)
    self.sectionSwitcher:SetFocusChangedCallback(OnFocusChanged)
end

function HousingPreviewDialog_Gamepad:InitializeTemplateComboBox()
    local comboBox = ZO_ComboBox_ObjectFromContainer(self.templateComboBoxControl:GetNamedChild("Dropdown"))
    comboBox:SetSelectedColor(ZO_DISABLED_TEXT)
    comboBox:SetSortsItems(false)
    comboBox:SetKeybindAlignment(KEYBIND_STRIP_ALIGN_CENTER)
    self.templateComboBox = comboBox
    self.templateComboBox:SetName(GetString(SI_HOUSING_TEMPLATE_HEADER))
end

function HousingPreviewDialog_Gamepad:GetNarrationText()
    local narrations = {}

    local switcher = nil
    if self.purchaseOptionsFocusSwitcher:IsActive() then
        switcher = self.purchaseOptionsFocusSwitcher
    elseif self.templateOptionsContainerFocusSwitcher:IsActive() then
        switcher = self.templateOptionsContainerFocusSwitcher
    else
        switcher = self.templateContainerFocusSwitcher
    end
    ZO_AppendNarration(narrations, switcher:GetNarrationText())

    return narrations
end

function HousingPreviewDialog_Gamepad:SelectFocusedPurchaseOption()
    local data = self.purchaseOptionsFocusSwitcher:GetFocusItem()
    if data then
        data.callback()
    end
end

function HousingPreviewDialog_Gamepad:SetupPurchaseOptionControl(control, currencyType, currencyLocation, price, priceAfterDiscount, discountPercent, requiredToBuyErrorText, getRemainingTimeFunction)
    ZO_HousingPreviewDialog_Shared.SetupPurchaseOptionControl(self, control, currencyType, currencyLocation, price, priceAfterDiscount, discountPercent, requiredToBuyErrorText, getRemainingTimeFunction)

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
    SCREEN_NARRATION_MANAGER:QueueDialog(self.control)
end

function HousingPreviewDialog_Gamepad:OnTemplatesChanged(hasTemplateEntries, currentlyPreviewedItemEntryIndex)
    ZO_HousingPreviewDialog_Shared.OnTemplatesChanged(self, hasTemplateEntries, currentlyPreviewedItemEntryIndex)

    -- Alias is required for generic gamepad dialog methods.
    self.info = self.dialogInfo
    ZO_GenericGamepadDialog_RefreshKeybinds(self)
end

function HousingPreviewDialog_Gamepad:BuildDialogInfo()
    ZO_HousingPreviewDialog_Shared.BuildDialogInfo(self)

    local function HasValidTemplates()
        return self.hasValidTemplates
    end

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
            visible = HasValidTemplates,
            callback = function(dialog)
                if self.purchaseOptionsFocusSwitcher:IsActive() then
                    self:SelectFocusedPurchaseOption()
                    return
                end
                
                local switcher = nil
                if self.templateOptionsContainerFocusSwitcher:IsActive() then
                    switcher = self.templateOptionsContainerFocusSwitcher
                else
                    switcher = self.templateContainerFocusSwitcher
                end

                local data = switcher:GetFocusItem()
                if data then
                    data.callback()
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
                self:ReleaseDialog()
                HousingEditorJumpToSafeLocation()
            end,
        },
        {
            keybind = "DIALOG_TERTIARY",
            text = SI_HOUSING_TOGGLE_PREVIEW_INSPECTION_MODE_ACTION,
            clickSound = SOUNDS.POSITIVE_CLICK,
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            visible = HasValidTemplates,
            callback = function(dialogControl)
                HousingEditorTogglePreviewInspectionEnabled()
            end,
        },
    }
end

function HousingPreviewDialog_Gamepad:OnDialogShowing()
    ZO_HousingPreviewDialog_Shared.OnDialogShowing(self)
    self.sectionSwitcher:Activate()
    self.sectionSwitcher:SetFocusToMatchingEntry(self.templateComboBox)
    SCENE_MANAGER:SetInUIMode(true)
    self.dialogInfo.narrationText = function(...) return self:GetNarrationText(...) end
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