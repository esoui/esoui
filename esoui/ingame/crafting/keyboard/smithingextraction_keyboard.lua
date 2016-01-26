ZO_SmithingExtraction = ZO_SharedSmithingExtraction:Subclass()

function ZO_SmithingExtraction:New(...)
    return ZO_SharedSmithingExtraction.New(self, ...)
end

function ZO_SmithingExtraction:Initialize(control, owner, refinementOnly)
    local slotContainer = control:GetNamedChild("SlotContainer")
    self.control = control
	ZO_SharedSmithingExtraction.Initialize(self, slotContainer:GetNamedChild("ExtractionSlot"), slotContainer:GetNamedChild("ExtractLabel"), owner, refinementOnly)

	self.inventory = ZO_SmithingExtractionInventory:New(self, self.control:GetNamedChild("Inventory"), refinementOnly)
	self:InitExtractionSlot("smithing")
end

function ZO_SmithingExtraction:SetCraftingType(craftingType, oldCraftingType, isCraftingTypeDifferent)
    self.extractionSlot:SetItem(nil)
    self.canExtract = false

    if isCraftingTypeDifferent then
        self.inventory:SetActiveFilterByDescriptor(nil)
    end
    self.inventory:HandleDirtyEvent()
end

function ZO_SmithingExtraction:SetHidden(hidden)
    self.control:SetHidden(hidden)
    self.inventory:HandleDirtyEvent()
end

ZO_SmithingExtractionInventory = ZO_CraftingInventory:Subclass()

function ZO_SmithingExtractionInventory:New(...)
    return ZO_CraftingInventory.New(self, ...)
end

function ZO_SmithingExtractionInventory:Initialize(owner, control, refinementOnly, ...)
    ZO_CraftingInventory.Initialize(self, control, ...)

    self.owner = owner
    self.noItemsLabel = control:GetNamedChild("NoItemsLabel")

    if refinementOnly then
        self:SetFilters{
            self:CreateNewTabFilterData(ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_RAW_MATERIALS, GetString(SI_SMITHING_EXTRACTION_RAW_MATERIALS_TAB), "EsoUI/Art/Inventory/inventory_tabIcon_crafting_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_crafting_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_crafting_over.dds", "EsoUI/Art/Inventory/inventory_tabIcon_crafting_disabled.dds"),
        }
    else
        self:SetFilters{
            self:CreateNewTabFilterData(ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_ARMOR, GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_ARMOR), "EsoUI/Art/Inventory/inventory_tabIcon_armor_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_over.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_disabled.dds", CanSmithingApparelPatternsBeCraftedHere),
            self:CreateNewTabFilterData(ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_WEAPONS, GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_WEAPONS), "EsoUI/Art/Inventory/inventory_tabIcon_weapons_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_over.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_disabled.dds", CanSmithingWeaponPatternsBeCraftedHere),
        }
    end
end

function ZO_SmithingExtractionInventory:AddListDataTypes()
    local defaultSetup = self:GetDefaultTemplateSetupFunction()

    local function RowSetup(rowControl, data)
        local inventorySlot = rowControl:GetNamedChild("Button")
        ZO_ItemSlot_SetAlwaysShowStackCount(inventorySlot, false, self.filterType == ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_RAW_MATERIALS and GetRequiredSmithingRefinementStackSize())

        defaultSetup(rowControl, data)

        if self.filterType == ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_RAW_MATERIALS then
            ZO_ItemSlot_SetupUsableAndLockedColor(inventorySlot, data.stackCount >= GetRequiredSmithingRefinementStackSize())
        end
    end

    ZO_ScrollList_AddDataType(self.list, self:GetScrollDataType(), "ZO_CraftingInventoryComponentRow", 52, RowSetup, nil, nil, ZO_InventorySlot_OnPoolReset)
end

function ZO_SmithingExtractionInventory:IsLocked(bagId, slotIndex)
    return ZO_CraftingInventory.IsLocked(self, bagId, slotIndex) or self.owner:IsSlotted(bagId, slotIndex)
end

function ZO_SmithingExtractionInventory:ChangeFilter(filterData)
    ZO_CraftingInventory.ChangeFilter(self, filterData)

    self.filterType = filterData.descriptor

    if self.filterType == ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_ARMOR then
        self.noItemsLabel:SetText(GetString(SI_SMITHING_EXTRACTION_NO_ARMOR))
    elseif self.filterType == ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_WEAPONS then
        self.noItemsLabel:SetText(GetString(SI_SMITHING_EXTRACTION_NO_WEAPONS))
    elseif self.filterType == ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_RAW_MATERIALS then
        self.noItemsLabel:SetText(GetString(SI_SMITHING_EXTRACTION_NO_MATERIALS))
    end

    self.owner:OnFilterChanged()
    self:HandleDirtyEvent()
end

function ZO_SmithingExtractionInventory:GetCurrentFilterType()
    return self.filterType
end

function ZO_SmithingExtractionInventory:Refresh(data)
    local validItemIds = self:EnumerateInventorySlotsAndAddToScrollData(ZO_SharedSmithingExtraction_IsExtractableOrRefinableItem, ZO_SharedSmithingExtraction_DoesItemPassFilter, self.filterType, data)
    self.owner:OnInventoryUpdate(validItemIds)

    self.noItemsLabel:SetHidden(#data > 0)
end

function ZO_SmithingExtractionInventory:ShowAppropriateSlotDropCallouts(bagId, slotIndex)
    self.owner:ShowAppropriateSlotDropCallouts()
end

function ZO_SmithingExtractionInventory:HideAllSlotDropCallouts()
    self.owner:HideAllSlotDropCallouts()
end