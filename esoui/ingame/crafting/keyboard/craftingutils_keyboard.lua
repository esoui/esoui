do
    local KEYBOARD_SMITHING_FILTER_TO_ITEM_SLOT_TEXTURE =
    {
       [SMITHING_FILTER_TYPE_RAW_MATERIALS] = "EsoUI/Art/Crafting/smithing_refine_emptySlot.dds",
       [SMITHING_FILTER_TYPE_WEAPONS] = "EsoUI/Art/Crafting/smithing_weaponSlot.dds",
       [SMITHING_FILTER_TYPE_ARMOR] = "EsoUI/Art/Crafting/smithing_armorSlot.dds",
       [SMITHING_FILTER_TYPE_JEWELRY] = "EsoUI/Art/Crafting/smithing_jewelrySlot.dds",
    }

    function ZO_CraftingUtils_GetItemSlotTextureFromSmithingFilter(smithingFilter)
        return internalassert(KEYBOARD_SMITHING_FILTER_TO_ITEM_SLOT_TEXTURE[smithingFilter], "No slot texture for smithing filter")
    end

    local KEYBOARD_SMITHING_DECONSTRUCTION_TYPE_TO_MULTIPLE_ITEMS_TEXTURE =
    {
       [SMITHING_DECONSTRUCTION_TYPE_RAW_MATERIALS] = "EsoUI/Art/Crafting/smithing_refine_multiple_emptySlot.dds",
       [SMITHING_DECONSTRUCTION_TYPE_WEAPONS_AND_ARMOR] = "EsoUI/Art/Crafting/smithing_multiple_armorWeaponSlot.dds",
       [SMITHING_DECONSTRUCTION_TYPE_ARMOR] = "EsoUI/Art/Crafting/smithing_multiple_armorSlot.dds",
       [SMITHING_DECONSTRUCTION_TYPE_JEWELRY] = "EsoUI/Art/Crafting/smithing_multiple_jewelrySlot.dds",
    }

    function ZO_CraftingUtils_GetMultipleItemsTextureFromSmithingDeconstructionType(deconstructionType)
        return internalassert(KEYBOARD_SMITHING_DECONSTRUCTION_TYPE_TO_MULTIPLE_ITEMS_TEXTURE[deconstructionType], "No multiple items texture for smithing deconstruction type")
    end
end

--[[ Multicraft Spinner ]]--
ZO_MultiCraftSpinner = ZO_Spinner:Subclass()

function ZO_MultiCraftSpinner:Initialize(control)
    -- init will require minMaxButton to be defined so we can safely call UpdateButtons()
    self.minMaxButton = control:GetNamedChild("MinMax")
    ZO_Spinner.Initialize(self, control, 1, 1)

    self.isMax = true

    self.minMaxButton:SetHandler("OnClicked", function()
        if self.isMax then
            self:SetValue(self:GetMax())
        else
            self:SetValue(self:GetMin())
        end
    end)
end

function ZO_MultiCraftSpinner:UpdateButtons()
    ZO_Spinner.UpdateButtons(self)

    local value = self:GetValue()
    if value < self:GetMax() or self:GetMin() >= self:GetMax() then
        self.isMax = true
        self.minMaxButton:SetText(GetString(SI_CRAFTING_QUANTITY_MAX))
    else
        self.isMax = false
        self.minMaxButton:SetText(GetString(SI_CRAFTING_QUANTITY_MIN))
    end

    self.minMaxButton:SetHidden(self.hideButtons)
    self.minMaxButton:SetEnabled(self.enabled and self:GetMin() < self:GetMax())
end

ESO_Dialogs["CRAFTING_CREATE_MULTIPLE_KEYBOARD"] =
{
    canQueue = true,
    title =
    {
        text = SI_CRAFTING_CONFIRM_CREATE_TITLE,
    },
    mainText =
    {
        text = SI_CRAFTING_CONFIRM_CREATE_MULTIPLE_DESCRIPTION,
    },
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                local craftingObject = dialog.data.craftingObject
                local numIterations = dialog.data.numIterations
                craftingObject:Create(numIterations)
            end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}
function ZO_KeyboardCraftingUtils_RequestCraftingCreate(craftingObject, numIterations)
    if numIterations <= 1 then
        craftingObject:Create(numIterations)
        return
    end

    local resultItemLink = craftingObject:GetResultItemLink()
    local nameColor = GetItemQualityColor(GetItemLinkDisplayQuality(resultItemLink))
    local colorizedItemName = nameColor:Colorize(GetItemLinkName(resultItemLink))
    local itemQuantity = craftingObject:GetMultiCraftNumResults(numIterations)

    ZO_Dialogs_ShowDialog("CRAFTING_CREATE_MULTIPLE_KEYBOARD", { craftingObject = craftingObject, numIterations = numIterations }, { mainTextParams = { colorizedItemName, itemQuantity } })
end

function ZO_CraftingModeTabs_OnInitialized(control)
    ZO_MenuBar_OnInitialized(control)
    local barData =
    {
        buttonPadding = 20,
        normalSize = 51,
        downSize = 64,
        animationDuration = DEFAULT_SCENE_TRANSITION_TIME,
        buttonTemplate = "ZO_CraftingModeButton",
    }
    ZO_MenuBar_SetData(control, barData)
end
