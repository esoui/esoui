ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_ARMOR = 1
ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_WEAPONS = 2
ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_RAW_MATERIALS = 3

ZO_SmithingExtractionSlot = ZO_CraftingSlotBase:Subclass()

function ZO_SmithingExtractionSlot:New(...)
    return ZO_CraftingSlotBase.New(self, ...)
end

function ZO_SmithingExtractionSlot:Initialize(owner, control, craftingInventory)
    ZO_CraftingSlotBase.Initialize(self, owner, control, SLOT_TYPE_PENDING_CRAFTING_COMPONENT, "EsoUI/Art/Inventory/inventory_slot.dds", craftingInventory)

    self.nameLabel = control:GetNamedChild("Name")
    self.needMoreLabel = control:GetNamedChild("NeedMoreLabel")
    self.needMoreLabel:SetText(zo_strformat(SI_SMITHING_NEED_MORE_TO_EXTRACT, GetRequiredSmithingRefinementStackSize()))
end

function ZO_SmithingExtractionSlot:SetItem(bagId, slotIndex)
    local hadItem = self:HasItem()
    local oldItemInstanceId = self:GetItemId()

    self:SetupItem(bagId, slotIndex)

    if self:HasItem() then
        if oldItemInstanceId ~= self:GetItemId() then
            PlaySound(SOUNDS.SMITHING_ITEM_TO_EXTRACT_PLACED)
        end
    elseif hadItem then
        PlaySound(SOUNDS.SMITHING_ITEM_TO_EXTRACT_REMOVED)
    end
end

function ZO_SmithingExtractionSlot:WouldBagAndSlotBeInRawMaterialMode(bagId, slotIndex)
    if bagId and slotIndex then
        return ZO_SharedSmithingExtraction_GetFilterTypeFromItem(bagId, slotIndex) == ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_RAW_MATERIALS
    end
    return self.filterType == ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_RAW_MATERIALS
end

function ZO_SmithingExtractionSlot:SetupItem(bagId, slotIndex)
    local isRawMaterial = self:WouldBagAndSlotBeInRawMaterialMode(bagId, slotIndex)
    local willHaveItem = bagId and slotIndex
    ZO_ItemSlot_SetAlwaysShowStackCount(self.control, willHaveItem and isRawMaterial, isRawMaterial and GetRequiredSmithingRefinementStackSize() or nil)

    ZO_CraftingSlotBase.SetupItem(self, bagId, slotIndex)

    self.control.meetsStackRequirement = true

    if self.nameLabel then
        self.needMoreLabel:SetHidden(not isRawMaterial)

        if bagId and slotIndex then
            local meetsStackRequirement = ZO_SharedSmithingExtraction_DoesItemMeetRefinementStackRequirement(bagId, slotIndex, self:GetStackCount())
            if meetsStackRequirement then
                self.nameLabel:SetHidden(false)
                self.nameLabel:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(bagId, slotIndex)))

                if not self:HasAnimationRefs() then
                    local quality = select(8, GetItemInfo(bagId, slotIndex))
                    self.nameLabel:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality))
                end
            else
                self.nameLabel:SetHidden(true)
            end

            self.needMoreLabel:SetHidden(meetsStackRequirement)
            if self:HasAnimationRefs() then
                self.control.meetsStackRequirement = meetsStackRequirement
            else
                ZO_ItemSlot_SetupUsableAndLockedColor(self.control, meetsStackRequirement)
            end
        else
            self.nameLabel:SetHidden(true)
        end
    end
end

function ZO_SmithingExtractionSlot:OnFilterChanged(filterType, inventoryFilerType)
    self.filterType = filterType
    self.inventoryFilerType = inventoryFilerType

    if filterType == ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_ARMOR then
        self:SetEmptyTexture("EsoUI/Art/Crafting/smithing_armorSlot.dds")
    elseif filterType == ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_WEAPONS then
        self:SetEmptyTexture("EsoUI/Art/Crafting/smithing_weaponSlot.dds")
    elseif filterType == ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_RAW_MATERIALS then
        self:SetEmptyTexture("EsoUI/Art/Crafting/smithing_refine_emptySlot.dds")
    end

    if self:HasItem() then
        self:SetItem(self:GetBagAndSlot())
    end
end

function ZO_SmithingExtractionSlot:ShowDropCallout()
    self.dropCallout:SetHidden(false)
    self.dropCallout:SetTexture("EsoUI/Art/Crafting/crafting_alchemy_goodSlot.dds")
end

ZO_SharedSmithingExtraction = ZO_Object:Subclass()

function ZO_SharedSmithingExtraction:New(...)
    local smithingExtraction = ZO_Object.New(self)
    smithingExtraction:Initialize(...)
    return smithingExtraction
end

function ZO_SharedSmithingExtraction:Initialize(extractionSlotControl, extractLabel, owner, refinementOnly)
	self.extractionSlotControl = extractionSlotControl
    self.extractLabel = extractLabel
    self.owner = owner
end

function ZO_SharedSmithingExtraction:InitExtractionSlot(sceneName)
    self.extractionSlot = ZO_SmithingExtractionSlot:New(self, self.extractionSlotControl, self.inventory)
	self.slotAnimation = ZO_CraftingSmithingExtractSlotAnimation:New(sceneName, function() return not self.extractionSlotControl:IsHidden() end)
    self.slotAnimation:AddSlot(self.extractionSlot)
end

function ZO_SharedSmithingExtraction_GetRawMaterialItemTypeForCraftingType(craftingType)
    if craftingType == CRAFTING_TYPE_BLACKSMITHING then
        return ITEMTYPE_BLACKSMITHING_RAW_MATERIAL
    elseif craftingType == CRAFTING_TYPE_CLOTHIER then
        return ITEMTYPE_CLOTHIER_RAW_MATERIAL
    elseif craftingType == CRAFTING_TYPE_WOODWORKING then
        return ITEMTYPE_WOODWORKING_RAW_MATERIAL
    end
end

function ZO_SharedSmithingExtraction_DoesItemMeetRefinementStackRequirement(bagId, slotIndex, stackCount)
    local _, itemType = GetItemCraftingInfo(bagId, slotIndex)
    if itemType == ZO_SharedSmithingExtraction_GetRawMaterialItemTypeForCraftingType(GetCraftingInteractionType()) then
        return stackCount >= GetRequiredSmithingRefinementStackSize()
    end
    return true
end

function ZO_SharedSmithingExtraction_GetPrimaryFilterType(...)
    for i = 1, select("#", ...) do
        local filterType = select(i, ...)
        if filterType == ITEMFILTERTYPE_WEAPONS then
            return ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_WEAPONS
        elseif filterType == ITEMFILTERTYPE_ARMOR then 
            return ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_ARMOR
        end
    end
    return ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_RAW_MATERIALS
end

function ZO_SharedSmithingExtraction_GetFilterTypeFromItem(bagId, slotIndex)
    return ZO_SharedSmithingExtraction_GetPrimaryFilterType(GetItemFilterTypeInfo(bagId, slotIndex))
end

function ZO_SharedSmithingExtraction_IsExtractableOrRefinableItem(bagId, slotIndex)
    return CanItemBeSmithingExtractedOrRefined(bagId, slotIndex, GetCraftingInteractionType()) and not IsItemPlayerLocked(bagId, slotIndex)
end

function ZO_SharedSmithingExtraction_DoesItemPassFilter(bagId, slotIndex, filterType)
    return ZO_SharedSmithingExtraction_GetFilterTypeFromItem(bagId, slotIndex) == filterType and not IsItemPlayerLocked(bagId, slotIndex)
end

function ZO_SharedSmithingExtraction:OnInventoryUpdate(validItemIds)
    if not self.extractionSlot:ValidateItemId(validItemIds) then
        self:OnSlotChanged()
    end
end

function ZO_SharedSmithingExtraction:ShowAppropriateSlotDropCallouts()
    self.extractionSlot:ShowDropCallout(true)
end

function ZO_SharedSmithingExtraction:HideAllSlotDropCallouts()
    self.extractionSlot:HideDropCallout()
end

function ZO_SharedSmithingExtraction:OnSlotChanged()
    self.overrideFilterType = nil

    if self.extractionSlot:HasItem() then
        local bagId, slotIndex = self.extractionSlot:GetBagAndSlot()
        local meetsStackRequirement = ZO_SharedSmithingExtraction_DoesItemMeetRefinementStackRequirement(bagId, slotIndex, self.extractionSlot:GetStackCount())

        self.canExtract = meetsStackRequirement

        self.overrideFilterType = ZO_SharedSmithingExtraction_GetFilterTypeFromItem(bagId, slotIndex)
    else
        self.canExtract = false
    end

    self:OnFilterChanged()
    self.inventory:HandleVisibleDirtyEvent()
    self.owner:OnExtractionSlotChanged()
end

function ZO_SharedSmithingExtraction:OnItemReceiveDrag(slotControl, bagId, slotIndex)
    if self.extractionSlot:HasItem() then
        PickupInventoryItem(self.extractionSlot:GetBagAndSlot())
    end
    self:SetExtractionSlotItem(bagId, slotIndex)
end

function ZO_SharedSmithingExtraction:IsItemAlreadySlottedToCraft(bagId, slotIndex)
    return self.extractionSlot:IsItemId(GetItemInstanceId(bagId, slotIndex))
end

function ZO_SharedSmithingExtraction:CanItemBeAddedToCraft(bagId, slotIndex)
    return true -- currently no requirements to meet before being able to extract
end

function ZO_SharedSmithingExtraction:AddItemToCraft(bagId, slotIndex)
    self:SetExtractionSlotItem(bagId, slotIndex)
end

function ZO_SharedSmithingExtraction:RemoveItemFromCraft(bagId, slotIndex)
    self:ClearSelections()
end

function ZO_SharedSmithingExtraction:SetExtractionSlotItem(bagId, slotIndex)
    self.extractionSlot:SetItem(bagId, slotIndex)

    self:OnSlotChanged()
end

function ZO_SharedSmithingExtraction:IsSlotted(bagId, slotIndex)
    return self.extractionSlot:IsBagAndSlot(bagId, slotIndex)
end

function ZO_SharedSmithingExtraction:Extract()
    ExtractOrRefineSmithingItem(self.extractionSlot:GetBagAndSlot())
end

function ZO_SharedSmithingExtraction:IsExtractable()
    return self.canExtract
end

function ZO_SharedSmithingExtraction:HasSelections()
    return self.extractionSlot:HasItem()
end

function ZO_SharedSmithingExtraction:ClearSelections()
    self:SetExtractionSlotItem(nil)
end

function ZO_SharedSmithingExtraction:GetFilterType()
    return self.overrideFilterType or self.inventory:GetCurrentFilterType()
end

do
    local FILTER_TO_TEXT_MAP = {
        [ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_ARMOR] = GetString(SI_SMITHING_EXTRACTION_DECONSTRUCT_ARMOR_HEADER),
        [ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_WEAPONS] = GetString(SI_SMITHING_EXTRACTION_DECONSTRUCT_WEAPON_HEADER),
        [ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_RAW_MATERIALS] = GetString(SI_SMITHING_EXTRACTION_REFINE_HEADER),
    }

    function ZO_SharedSmithingExtraction:OnFilterChanged()
        local filterType = self:GetFilterType()

        if self.extractLabel then
             self.extractLabel:SetText(FILTER_TO_TEXT_MAP[filterType])
        end

        self.extractionSlot:OnFilterChanged(filterType, self.inventory:GetCurrentFilterType())
    end
end