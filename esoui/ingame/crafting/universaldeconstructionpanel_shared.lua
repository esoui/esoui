function ZO_GetJewelryCraftingCollectibleData()
    local jewelryCraftingCollectibleId = GetJewelrycraftingCollectibleId()
    return ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(jewelryCraftingCollectibleId)
end

function ZO_IsJewelryCraftingEnabled()
    local jewelryCraftingCollectibleData = ZO_GetJewelryCraftingCollectibleData()
    return not jewelryCraftingCollectibleData or jewelryCraftingCollectibleData:IsUnlocked()
end

function ZO_GetJewelryCraftingLockedMessage(data)
    if ZO_IsJewelryCraftingEnabled() then
        return data and data.activeTabText or nil
    end
    local jewelryCraftingTradeskillName = GetString("SI_TRADESKILLTYPE", CRAFTING_TYPE_JEWELRYCRAFTING)
    return ZO_ERROR_COLOR:Colorize(zo_strformat(SI_SMITHING_CRAFTING_TYPE_LOCKED, ZO_GetJewelryCraftingCollectibleData():GetFormattedName(), jewelryCraftingTradeskillName))
end

ZO_UNIVERSAL_DECONSTRUCTION_CRAFTING_TYPES =
{
    CRAFTING_TYPE_BLACKSMITHING,
    CRAFTING_TYPE_CLOTHIER,
    CRAFTING_TYPE_ENCHANTING,
    CRAFTING_TYPE_JEWELRYCRAFTING,
    CRAFTING_TYPE_WOODWORKING,
}

ZO_UNIVERSAL_DECONSTRUCTION_FILTER_TYPES =
{
    {
        key = "enchantments",
        filter =
        {
            itemTypes =
            {
                ITEMTYPE_GLYPH_ARMOR,
                ITEMTYPE_GLYPH_JEWELRY,
                ITEMTYPE_GLYPH_WEAPON,
            },
        },
        displayName = GetString("SI_ITEMTYPEDISPLAYCATEGORY", ITEM_TYPE_DISPLAY_CATEGORY_GLYPH),
        iconUp = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_enchanting_up.dds",
        iconDown = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_enchanting_down.dds",
        iconOver = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_enchanting_over.dds",
        iconDisabled = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_enchanting_disabled.dds",
    },
    {
        key = "jewelry",
        tooltipText = ZO_GetJewelryCraftingLockedMessage,
        enabled = ZO_IsJewelryCraftingEnabled,
        filter =
        {
            itemFilterTypes =
            {
                ITEMFILTERTYPE_JEWELRY,
            },
        },
        displayName = GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_JEWELRY),
        iconUp = "EsoUI/Art/Crafting/jewelry_tabIcon_icon_up.dds",
        iconDown = "EsoUI/Art/Crafting/jewelry_tabIcon_down.dds",
        iconOver = "EsoUI/Art/Crafting/jewelry_tabIcon_icon_over.dds",
        iconDisabled = "EsoUI/Art/Crafting/jewelry_tabIcon_icon_disabled.dds",
    },
    {
        key = "armor",
        filter =
        {
            itemFilterTypes =
            {
                ITEMFILTERTYPE_ARMOR,
            },
        },
        displayName = GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_ARMOR),
        iconUp = "EsoUI/Art/Inventory/inventory_tabIcon_armor_up.dds",
        iconDown = "EsoUI/Art/Inventory/inventory_tabIcon_armor_down.dds",
        iconOver = "EsoUI/Art/Inventory/inventory_tabIcon_armor_over.dds",
        iconDisabled = "EsoUI/Art/Inventory/inventory_tabIcon_armor_disabled.dds",
    },
    {
        key = "weapons",
        filter =
        {
            itemFilterTypes =
            {
                ITEMFILTERTYPE_WEAPONS,
            },
        },
        displayName = GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_WEAPONS),
        iconUp = "EsoUI/Art/Inventory/inventory_tabIcon_weapons_up.dds",
        iconDown = "EsoUI/Art/Inventory/inventory_tabIcon_weapons_down.dds",
        iconOver = "EsoUI/Art/Inventory/inventory_tabIcon_weapons_over.dds",
        iconDisabled = "EsoUI/Art/Inventory/inventory_tabIcon_weapons_disabled.dds",
    },
    {
        key = "all",
        filter = nil, -- Show all deconstructable items
        displayName = GetString("SI_ITEMTYPEDISPLAYCATEGORY", ITEM_TYPE_DISPLAY_CATEGORY_ALL),
        iconUp = "EsoUI/Art/Inventory/inventory_tabIcon_all_up.dds",
        iconDown = "EsoUI/Art/Inventory/inventory_tabIcon_all_down.dds",
        iconOver = "EsoUI/Art/Inventory/inventory_tabIcon_all_over.dds",
        iconDisabled = "EsoUI/Art/Inventory/inventory_tabIcon_all_disabled.dds",
    },
}

function ZO_GetUniversalDeconstructionFilterType(filterKey)
    for _, filterType in ipairs(ZO_UNIVERSAL_DECONSTRUCTION_FILTER_TYPES) do
        if filterKey == filterType.key then
            return filterType
        end
    end
end

ZO_UniversalDeconstructionPanel_Shared = ZO_InitializingCallbackObject:Subclass()

function ZO_UniversalDeconstructionPanel_Shared:Initialize(control, universalDeconstructionParent, extractionSlotControl, extractLabel)
    self.control = control
    control.object = self
    self.universalDeconstructionParent = universalDeconstructionParent
    self.extractionSlotControl = extractionSlotControl
    self.extractLabel = extractLabel
end

function ZO_UniversalDeconstructionPanel_Shared:GetExtractionSlotTextures()
    local emptyTexture, multipleItemsTexture
    if IsInGamepadPreferredMode() then
        emptyTexture = "EsoUI/Art/Crafting/Gamepad/gp_smithing_weaponSlot.dds"
        multipleItemsTexture = "EsoUI/Art/Crafting/Gamepad/GP_smithing_multiple_armorWeaponSlot.dds"
    else
        emptyTexture = "EsoUI/Art/Crafting/smithing_weaponSlot.dds"
        multipleItemsTexture = "EsoUI/Art/Crafting/smithing_multiple_armorWeaponSlot.dds"
    end
    return emptyTexture, multipleItemsTexture
end

function ZO_UniversalDeconstructionPanel_Shared:InitExtractionSlot(sceneName)
    self.extractionSlot = ZO_SmithingExtractionSlot:New(self, self.extractionSlotControl, self.inventory)
    local emptyTexture, multipleItemsTexture = self:GetExtractionSlotTextures()
    self.extractionSlot:SetEmptyTexture(emptyTexture)
    self.extractionSlot:SetMultipleItemsTexture(multipleItemsTexture)
    self.extractionSlot:RegisterCallback("ItemsChanged", function()
        self:OnSlotChanged()
    end)

    self.slotAnimation = ZO_CraftingSmithingExtractSlotAnimation:New(sceneName, function()
        return not self.extractionSlotControl:IsHidden()
    end)
    self.slotAnimation:AddSlot(self.extractionSlot)
end

function ZO_UniversalDeconstructionPanel_Shared.IsDeconstructableBagItem(bagId, slotIndex, filterTypes)
    if IsItemPlayerLocked(bagId, slotIndex) then
        return false
    end

    -- No crafting filter types have been specified; just verify that the item is deconstructable.
    if filterTypes == nil or ZO_IsTableEmpty(filterTypes) then
        return CanItemBeDeconstructed(bagId, slotIndex)
    end

    -- One or more crafting filter types have been specified; verify that the item is deconstructable using at least one of those crafting types.
    for filterType in pairs(filterTypes) do
        if CanItemBeDeconstructed(bagId, slotIndex, filterType) then
            return true
        end
    end

    return false
end

function ZO_UniversalDeconstructionPanel_Shared.IsDeconstructableItem(itemData, filterTypes)
    return ZO_UniversalDeconstructionPanel_Shared.IsDeconstructableBagItem(itemData.bagId, itemData.slotIndex, filterTypes)
end

function ZO_UniversalDeconstructionPanel_Shared.DoesItemPassFilter(bagId, slotIndex, filterType)
    local itemFilterTypes = {GetItemFilterTypeInfo(bagId, slotIndex)}
    if ZO_IsElementInNumericallyIndexedTable(itemFilterTypes, ITEMFILTERTYPE_JEWELRY) and not ZO_IsJewelryCraftingEnabled() then
        return false
    end

    if filterType then
        if filterType.itemTypes then
            local itemType = GetItemType(bagId, slotIndex)
            if not ZO_AreIntersectingNumericallyIndexedTables(filterType.itemTypes, itemType) then
                return false
            end
        end

        if filterType.itemFilterTypes then
            if not ZO_AreIntersectingNumericallyIndexedTables(filterType.itemFilterTypes, itemFilterTypes) then
                return false
            end
        end
    end

    return true
end

function ZO_UniversalDeconstructionPanel_Shared:OnInventoryUpdate(validItems, filterType)
    self.extractionSlot:ValidateSlottedItem(validItems)
end

function ZO_UniversalDeconstructionPanel_Shared:ShowAppropriateSlotDropCallouts()
    self.extractionSlot:ShowDropCallout(true)
end

function ZO_UniversalDeconstructionPanel_Shared:HideAllSlotDropCallouts()
    self.extractionSlot:HideDropCallout()
end

function ZO_UniversalDeconstructionPanel_Shared:OnSlotChanged()
    self.inventory:HandleVisibleDirtyEvent()
    self.universalDeconstructionParent:OnExtractionSlotChanged()
end

-- Required by ZO_Smithing_Common
function ZO_UniversalDeconstructionPanel_Shared:CanItemBeAddedToCraft(bagId, slotIndex)
    return true
end

function ZO_UniversalDeconstructionPanel_Shared:OnItemReceiveDrag(slotControl, bagId, slotIndex)
    self:AddItemToCraft(bagId, slotIndex)
end

function ZO_UniversalDeconstructionPanel_Shared:IsItemAlreadySlottedToCraft(bagId, slotIndex)
    return self.extractionSlot:ContainsBagAndSlot(bagId, slotIndex)
end

function ZO_UniversalDeconstructionPanel_Shared:AddItemToCraft(bagId, slotIndex)
    if self.extractionSlot:HasItems() then
        if self.extractionSlot:GetNumItems() >= MAX_ITEM_SLOTS_PER_DECONSTRUCTION then
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_TOO_MANY_CRAFTING_INPUTS))
            return
        end

        local newStackCount = self.extractionSlot:GetStackCount() + self.inventory:GetStackCount(bagId, slotIndex)
        if newStackCount > MAX_ITERATIONS_PER_DECONSTRUCTION then
            -- prevent slotting if it would take us above the iteration limit, but allow it if nothing else has been slotted yet so we can support single stacks that are larger than the limit
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_TOO_MANY_CRAFTING_ITERATIONS))
            return
        end
    end

    self.extractionSlot:AddItem(bagId, slotIndex)
end

function ZO_UniversalDeconstructionPanel_Shared:RemoveItemFromCraft(bagId, slotIndex)
    self.extractionSlot:RemoveItem(bagId, slotIndex)
end

function ZO_UniversalDeconstructionPanel_Shared:IsSlotted(bagId, slotIndex)
    return self.extractionSlot:ContainsBagAndSlot(bagId, slotIndex)
end

function ZO_UniversalDeconstructionPanel_Shared:ExtractSingle()
    local QUANTITY = 1
    self:ExtractPartialStack(QUANTITY)
end

function ZO_UniversalDeconstructionPanel_Shared:ExtractPartialStack(quantity)
    PrepareDeconstructMessage()

    local bagId, slotIndex = self.extractionSlot:GetItemBagAndSlot(1)
    if AddItemToDeconstructMessage(bagId, slotIndex, quantity) then
        SendDeconstructMessage()
    end
end

do
    local function CompareExtractingItems(left, right)
        return left.quantity < right.quantity
    end

    function ZO_UniversalDeconstructionPanel_Shared:ExtractAll()
        PrepareDeconstructMessage()

        local sortedItems = {}
        for index = 1, self.extractionSlot:GetNumItems() do
            local bagId, slotIndex = self.extractionSlot:GetItemBagAndSlot(index)
            local quantity = self.inventory:GetStackCount(bagId, slotIndex)
            table.insert(sortedItems, {bagId = bagId, slotIndex = slotIndex, quantity = quantity})
        end
        table.sort(sortedItems, CompareExtractingItems)

        local addedAllItems = true
        for _, item in ipairs(sortedItems) do
            if not AddItemToDeconstructMessage(item.bagId, item.slotIndex, item.quantity) then
                addedAllItems = false
                break
            end
        end

        if addedAllItems then
            SendDeconstructMessage()
        end
    end
end

function ZO_UniversalDeconstructionPanel_Shared:ConfirmExtractAll()
    local isMultiExtract = self:IsMultiExtract()
    local numItems = isMultiExtract and self.extractionSlot:GetNumItems() or 1
    local isAnyItemInArmoryBuild = false
    for index = 1, numItems do
        local bagId, slotIndex = self.extractionSlot:GetItemBagAndSlot(index)
        if IsItemInArmory(bagId, slotIndex) then
            isAnyItemInArmoryBuild = true
            break
        end
    end

    if isAnyItemInArmoryBuild or isMultiExtract then
        local dialogData =
        {
            deconstructFn = function()
                if isMultiExtract then
                    self:ExtractAll()
                else
                    self:ExtractSingle()
                end
            end,
            verb = DECONSTRUCT_ACTION_NAME_DECONSTRUCT,
            isAnyItemInArmoryBuild = isAnyItemInArmoryBuild,
        }

        local dialogName
        if isMultiExtract then
            dialogName = (not IsInGamepadPreferredMode() and isAnyItemInArmoryBuild) and "CONFIRM_MULTI_DECONSTRUCT_ARMORY_ITEM" or "CONFIRM_DECONSTRUCT_MULTIPLE_ITEMS"
        else
            dialogName = IsInGamepadPreferredMode() and "CONFIRM_DECONSTRUCT_ARMORY_ITEM_GAMEPAD" or "CONFIRM_DECONSTRUCT_ARMORY_ITEM"
        end
        ZO_Dialogs_ShowPlatformDialog(dialogName, dialogData, { mainTextParams = { ZO_CommaDelimitNumber(self.extractionSlot:GetStackCount()) } })
    else
        -- Extraction of a single item does not require a confirmation dialog.
        self:ExtractSingle()
    end
end

function ZO_UniversalDeconstructionPanel_Shared:IsExtractable()
    return self.extractionSlot:HasItems()
end

function ZO_UniversalDeconstructionPanel_Shared:IsMultiExtract()
    return self.extractionSlot:HasMultipleItems()
end

function ZO_UniversalDeconstructionPanel_Shared:HasSelections()
    return self.extractionSlot:HasItems()
end

function ZO_UniversalDeconstructionPanel_Shared:ClearSelections()
    self.extractionSlot:ClearItems()
end

function ZO_UniversalDeconstructionPanel_Shared:GetFilterType()
    return self.inventory:GetCurrentFilterType()
end
