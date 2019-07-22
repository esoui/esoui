

ZO_SmithingExtractionSlot = ZO_CraftingMultiSlotBase:Subclass()

function ZO_SmithingExtractionSlot:New(...)
    return ZO_CraftingMultiSlotBase.New(self, ...)
end

function ZO_SmithingExtractionSlot:Initialize(owner, control, craftingInventory)
    local NO_EMPTY_TEXTURE = ""
    local NO_MULTIPLE_ITEMS_TEXTURE = ""
    ZO_CraftingMultiSlotBase.Initialize(self, owner, control, SLOT_TYPE_PENDING_CRAFTING_COMPONENT, NO_EMPTY_TEXTURE, NO_MULTIPLE_ITEMS_TEXTURE, craftingInventory)

    self.nameLabel = control:GetNamedChild("Name")
end

function ZO_SmithingExtractionSlot:AddItem(bagId, slotIndex)
    if ZO_CraftingMultiSlotBase.AddItem(self, bagId, slotIndex) then
        PlaySound(SOUNDS.SMITHING_ITEM_TO_EXTRACT_PLACED)
        return true
    end
    return false
end

function ZO_SmithingExtractionSlot:RemoveItem(bagId, slotIndex)
    if ZO_CraftingMultiSlotBase.RemoveItem(self, bagId, slotIndex) then
        PlaySound(SOUNDS.SMITHING_ITEM_TO_EXTRACT_REMOVED)
        return true
    end
    return false
end

function ZO_SmithingExtractionSlot:ClearItems()
    if ZO_CraftingMultiSlotBase.ClearItems(self) then
        PlaySound(SOUNDS.SMITHING_ITEM_TO_EXTRACT_REMOVED)
        return true
    end
    return false
end

function ZO_SmithingExtractionSlot:IsInRefineMode()
    return self.craftingInventory:GetCurrentFilterType() == SMITHING_FILTER_TYPE_RAW_MATERIALS
end

function ZO_SmithingExtractionSlot:Refresh()
    ZO_CraftingMultiSlotBase.Refresh(self)

    if self.nameLabel then
        if self:HasOneItem() then
            local bagId, slotIndex = self:GetItemBagAndSlot(1)
            self.nameLabel:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(bagId, slotIndex)))

            if not self:HasAnimationRefs() then
                local quality = select(8, GetItemInfo(bagId, slotIndex))
                self.nameLabel:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality))
            end
        elseif self:HasMultipleItems() then
            self.nameLabel:SetText(zo_strformat(SI_CRAFTING_SLOT_MULTIPLE_SELECTED, ZO_CommaDelimitNumber(self:GetStackCount())))
            self.nameLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        else
            self.nameLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
            if self:IsInRefineMode() then
                self.nameLabel:SetText(zo_strformat(SI_SMITHING_NEED_MORE_TO_EXTRACT, GetRequiredSmithingRefinementStackSize()))
            else
                self.nameLabel:SetText(GetString(SI_SMITHING_SELECT_ITEMS_TO_DECONSTRUCT))
            end
        end
    end

    if self:IsInRefineMode() and self:HasOneItem() then
        local ALWAYS_SHOW_STACK_COUNT = true
        local minQuantity = GetRequiredSmithingRefinementStackSize()
        ZO_ItemSlot_SetAlwaysShowStackCount(self.control, SHOW_STACK_COUNT, minQuantity)
    else
        local AUTO_SHOW_STACK_COUNT = false
        local MIN_QUANTITY = 0
        ZO_ItemSlot_SetAlwaysShowStackCount(self.control, AUTO_SHOW_STACK_COUNT, MIN_QUANTITY)
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
    self.extractionSlot:RegisterCallback("ItemsChanged", function()
        self:OnSlotChanged()
    end)
    self.slotAnimation = ZO_CraftingSmithingExtractSlotAnimation:New(sceneName, function() return not self.extractionSlotControl:IsHidden() end)
    self.slotAnimation:AddSlot(self.extractionSlot)
end

function ZO_SharedSmithingExtraction_DoesItemMeetRefinementStackRequirement(bagId, slotIndex, stackCount)
    if ZO_SharedSmithingExtraction_IsRefinableItem(bagId, slotIndex) then
        return stackCount >= GetRequiredSmithingRefinementStackSize()
    end
    return true
end

function ZO_SharedSmithingExtraction_IsExtractableItem(itemData)
    return CanItemBeDeconstructed(itemData.bagId, itemData.slotIndex, GetCraftingInteractionType()) and not IsItemPlayerLocked(itemData.bagId, itemData.slotIndex)
end

function ZO_SharedSmithingExtraction_IsRefinableItem(bagId, slotIndex)
    return CanItemBeRefined(bagId, slotIndex, GetCraftingInteractionType())
end

function ZO_SharedSmithingExtraction_IsExtractableOrRefinableItem(bagId, slotIndex)
    return CanItemBeRefined(bagId, slotIndex, GetCraftingInteractionType()) or CanItemBeDeconstructed(bagId, slotIndex, GetCraftingInteractionType())
end

function ZO_SharedSmithingExtraction_DoesItemPassFilter(bagId, slotIndex, filterType)
    return ZO_CraftingUtils_GetSmithingFilterFromItem(bagId, slotIndex) == filterType
end

function ZO_SharedSmithingExtraction:OnInventoryUpdate(validItems, filterType)
    -- since we use this class for both refinement and extraction, but the lists for each are generated in different ways
    -- we need to branch our logic when dealing with those lists so that they can be handled properly
    if filterType == SMITHING_FILTER_TYPE_RAW_MATERIALS then
        local requiredStackSize = GetRequiredSmithingRefinementStackSize()
        self.extractionSlot:ValidateItemId(validItems, function(bagId, slotIndex)
            return self.inventory:GetStackCount(bagId, slotIndex) >= requiredStackSize
        end)
    else
        self.extractionSlot:ValidateSlottedItem(validItems)
    end
end

function ZO_SharedSmithingExtraction:ShowAppropriateSlotDropCallouts()
    self.extractionSlot:ShowDropCallout(true)
end

function ZO_SharedSmithingExtraction:HideAllSlotDropCallouts()
    self.extractionSlot:HideDropCallout()
end

function ZO_SharedSmithingExtraction:OnSlotChanged()
    self:OnFilterChanged()
    self.inventory:HandleVisibleDirtyEvent()
    self.owner:OnExtractionSlotChanged()
end

function ZO_SharedSmithingExtraction:OnItemReceiveDrag(slotControl, bagId, slotIndex)
    if self:CanItemBeAddedToCraft(bagId, slotIndex) then
        self:AddItemToCraft(bagId, slotIndex)
    end
end

function ZO_SharedSmithingExtraction:IsItemAlreadySlottedToCraft(bagId, slotIndex)
    return self.extractionSlot:ContainsBagAndSlot(bagId, slotIndex)
end

function ZO_SharedSmithingExtraction:CanItemBeAddedToCraft(bagId, slotIndex)
    return self:DoesItemMeetStackRequirement(bagId, slotIndex)
end

function ZO_SharedSmithingExtraction:AddItemToCraft(bagId, slotIndex)
    local newStackCount = self.extractionSlot:GetStackCount() + zo_max(1, self.inventory:GetStackCount(bagId, slotIndex)) -- non virtual items will have a stack count of 0, but still count as 1 item
    local stackCountPerIteration = self:IsInRefineMode() and GetRequiredSmithingRefinementStackSize() or 1
    local maxStackCount = MAX_ITERATIONS_PER_DECONSTRUCTION * stackCountPerIteration

    if self.extractionSlot:GetNumItems() >= MAX_ITEM_SLOTS_PER_DECONSTRUCTION then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_TOO_MANY_CRAFTING_INPUTS))
    elseif self.extractionSlot:HasItems() and newStackCount > maxStackCount then
        -- prevent slotting if it would take us above the iteration limit, but allow it if nothing else has been slotted yet so we can support single stacks that are larger than the limit
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_TOO_MANY_CRAFTING_ITERATIONS))
    else
        self.extractionSlot:AddItem(bagId, slotIndex)
    end
end

function ZO_SharedSmithingExtraction:RemoveItemFromCraft(bagId, slotIndex)
    self.extractionSlot:RemoveItem(bagId, slotIndex)
end

function ZO_SharedSmithingExtraction:DoesItemMeetStackRequirement(bagId, slotIndex)
    if ZO_SharedSmithingExtraction_IsRefinableItem(bagId, slotIndex) then 
        return self.inventory:GetStackCount(bagId, slotIndex) >= GetRequiredSmithingRefinementStackSize()
    end
    return true
end

function ZO_SharedSmithingExtraction:IsSlotted(bagId, slotIndex)
    return self.extractionSlot:ContainsBagAndSlot(bagId, slotIndex)
end

function ZO_SharedSmithingExtraction:ExtractSingle()
    PrepareDeconstructMessage()

    local bagId, slotIndex = self.extractionSlot:GetItemBagAndSlot(1)
    local quantity = self:IsInRefineMode() and GetRequiredSmithingRefinementStackSize() or 1
    if AddItemToDeconstructMessage(bagId, slotIndex, quantity) then
        SendDeconstructMessage()
    end
end

function ZO_SharedSmithingExtraction:ExtractPartialStack(quantity)
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

    function ZO_SharedSmithingExtraction:ExtractAll()
        PrepareDeconstructMessage()

        local sortedItems = {}
        for index = 1, self.extractionSlot:GetNumItems() do
            local bagId, slotIndex = self.extractionSlot:GetItemBagAndSlot(index)
            local quantity = self.inventory:GetStackCount(bagId, slotIndex)
            local step = self:IsInRefineMode() and GetRequiredSmithingRefinementStackSize() or 1
            quantity = zo_floor(quantity / step) * step -- round quantity to next step down
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

function ZO_SharedSmithingExtraction:ConfirmExtractAll()
    if not self:IsMultiExtract() then
        -- single extracts do not need a confirmation dialog
        self:ExtractSingle()
        return
    end

    local function PerformExtract()
        self:ExtractAll()
    end

    if self:IsInRefineMode() then
        ZO_Dialogs_ShowPlatformDialog("CONFIRM_REFINE_MULTIPLE_ITEMS", {refineFn = PerformExtract}, {mainTextParams = {ZO_CommaDelimitNumber(self.extractionSlot:GetStackCount())}})
    else
        ZO_Dialogs_ShowPlatformDialog("CONFIRM_DECONSTRUCT_MULTIPLE_ITEMS", {deconstructFn = PerformExtract}, {mainTextParams = {ZO_CommaDelimitNumber(self.extractionSlot:GetNumItems())}})
    end
end

function ZO_SharedSmithingExtraction:IsExtractable()
    return self.extractionSlot:HasItems()
end

function ZO_SharedSmithingExtraction:IsMultiExtract()
    return self.extractionSlot:HasMultipleItems()
end

function ZO_SharedSmithingExtraction:HasSelections()
    return self.extractionSlot:HasItems()
end

function ZO_SharedSmithingExtraction:ClearSelections()
    self.extractionSlot:ClearItems()
end

function ZO_SharedSmithingExtraction:GetFilterType()
    return self.inventory:GetCurrentFilterType()
end

function ZO_SharedSmithingExtraction:IsInRefineMode()
    return self:GetFilterType() == SMITHING_FILTER_TYPE_RAW_MATERIALS
end

do
    local CRAFTING_TYPE_TO_DECONSTRUCTION_TYPE =
    {
       [CRAFTING_TYPE_BLACKSMITHING] = SMITHING_DECONSTRUCTION_TYPE_WEAPONS_AND_ARMOR,
       [CRAFTING_TYPE_CLOTHIER] = SMITHING_DECONSTRUCTION_TYPE_ARMOR,
       [CRAFTING_TYPE_WOODWORKING] = SMITHING_DECONSTRUCTION_TYPE_WEAPONS_AND_ARMOR,
       [CRAFTING_TYPE_JEWELRYCRAFTING] = SMITHING_DECONSTRUCTION_TYPE_JEWELRY,
    }
    function ZO_SharedSmithingExtraction:GetDeconstructionType()
        if self:IsInRefineMode() then 
            return SMITHING_DECONSTRUCTION_TYPE_RAW_MATERIALS
        else
            local craftingType = GetCraftingInteractionType()
            return CRAFTING_TYPE_TO_DECONSTRUCTION_TYPE[craftingType]
        end
    end
end

function ZO_SharedSmithingExtraction:OnFilterChanged()
    local filterType = self:GetFilterType()

    if self.extractLabel then
         self.extractLabel:SetText(GetString("SI_SMITHINGDECONSTRUCTIONTYPE", self:GetDeconstructionType()))
    end
end