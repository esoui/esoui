ZO_FishFillet_Keyboard = ZO_FishFillet_Shared:Subclass()

function ZO_FishFillet_Keyboard:Initialize(control, owner)
    local slotContainer = control:GetNamedChild("SlotContainer")
    self.control = control
    ZO_FishFillet_Shared.Initialize(self, slotContainer:GetNamedChild("FilletSlot"), slotContainer:GetNamedChild("FilletLabel"), owner)

    control:SetHandler("OnEffectivelyHidden", function() self:OnHidden() end)
    control:SetHandler("OnEffectivelyShown", function() self:OnShown() end)

    self.inventory = ZO_FishFilletInventory:New(self, self.control:GetNamedChild("Inventory"))
    self:InitFilletSlot("provisioner")
    
    self.multiFilletSpinner = ZO_MultiCraftSpinner:New(control:GetNamedChild("SlotContainerSpinner"))

    -- Connect fillet spinner to crafting process
    local function UpdateMultiFilletSpinner()
        if not self.control:IsHidden() then
            self:UpdateMultiFillet()
        end
    end
    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", UpdateMultiFilletSpinner)
    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", UpdateMultiFilletSpinner)

    ZO_CraftingUtils_ConnectSpinnerToCraftingProcess(self.multiFilletSpinner)
end

function ZO_FishFillet_Keyboard_FilterOnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_FishFillet_Keyboard:SetCraftingType(craftingType, oldCraftingType, isCraftingTypeDifferent)
    self:ClearSelections()
    if isCraftingTypeDifferent then
        self.inventory:SetActiveFilterByDescriptor(nil)
    end
    self.inventory:HandleDirtyEvent()
end

function ZO_FishFillet_Keyboard:OnHidden()
    self.inventory:HandleDirtyEvent()
    CRAFTING_RESULTS:SetTooltipAnimationSounds(nil)
end

function ZO_FishFillet_Keyboard:OnShown()
    self.inventory:HandleDirtyEvent()
    CRAFTING_RESULTS:SetTooltipAnimationSounds(SOUNDS.PROVISIONING_FILLET)
end

function ZO_FishFillet_Keyboard:OnFilterChanged()
    ZO_FishFillet_Shared.OnFilterChanged(self)

    self.filletSlot:SetEmptyTexture("EsoUI/Art/Crafting/provisioner_filletSlot.dds")
    self.filletSlot:SetMultipleItemsTexture("EsoUI/Art/Crafting/provisioner_multiple_filletSlot.dds")
end

function ZO_FishFillet_Keyboard:ConfirmFillet()
    if self:IsMultiFillet() then
        self:ConfirmFilletAll()
    else
        local iterations = self.multiFilletSpinner:GetValue()
        self:FilletPartialStack(iterations)
    end
end

function ZO_FishFillet_Keyboard:UpdateMultiFillet()
    local shouldEnableSpinner = true
    local NO_OVERRIDE = nil
    if self.filletSlot:HasOneItem() then
        local bagId, slotIndex = self.filletSlot:GetItemBagAndSlot(1)
        local maxIterations = zo_min(zo_floor(self.inventory:GetStackCount(bagId, slotIndex)), MAX_ITERATIONS_PER_DECONSTRUCTION)

        self.multiFilletSpinner:SetDisplayTextOverride(NO_OVERRIDE)
        self.multiFilletSpinner:SetMinMax(1, maxIterations)
    elseif self.filletSlot:HasMultipleItems() then
        self.multiFilletSpinner:SetDisplayTextOverride(GetString(SI_CRAFTING_QUANTITY_ALL))
        shouldEnableSpinner = false
    else
        self.multiFilletSpinner:SetDisplayTextOverride(NO_OVERRIDE)
        self.multiFilletSpinner:SetMinMax(0, 0)
    end

    if ZO_CraftingUtils_IsPerformingCraftProcess() then
        shouldEnableSpinner = false
    end
    self.multiFilletSpinner:SetEnabled(shouldEnableSpinner)
    self.multiFilletSpinner:UpdateButtons()
end

function ZO_FishFillet_Keyboard:SetFilletIterationsToMax()
    if self.filletSlot:HasOneItem() then
        self.multiFilletSpinner:SetValue(self.multiFilletSpinner:GetMax())
    end
end

function ZO_FishFillet_Keyboard:OnSlotChanged()
    ZO_FishFillet_Shared.OnSlotChanged(self)
    self:UpdateMultiFillet()
    self:SetFilletIterationsToMax()
end

function ZO_FishFillet_Keyboard:OnInventoryUpdate(validItems, filterType)
    ZO_FishFillet_Shared.OnInventoryUpdate(self, validItems, filterType)
    self:UpdateMultiFillet()
end

ZO_FishFilletInventory = ZO_CraftingInventory:Subclass()

function ZO_FishFilletInventory:New(...)
    return ZO_CraftingInventory.New(self, ...)
end

function ZO_FishFilletInventory:Initialize(owner, control, ...)
    ZO_CraftingInventory.Initialize(self, control, ...)

    self.owner = owner

    self:SetFilters{
        self:CreateNewTabFilterData(PROVISIONER_SPECIAL_INGREDIENT_TYPE_FILLET, GetString("SI_ITEMTYPE", ITEMTYPE_FISH), "EsoUI/Art/Crafting/provisioner_indexIcon_fish_up.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_fish_down.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_fish_over.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_fish_disabled.dds"),
    }

    local columnData =
    {
        statusSortOrder = true,
        traitInformationSortOrder = true,
        sellInformationSortOrder = true,
    }
    self:SetSortColumnHidden(columnData, true)

    self.sortOrder = ZO_SORT_ORDER_UP
    self.sortKey = "name"

    self.sortHeaders:SelectHeaderByKey(self.sortKey, ZO_SortHeaderGroup.SUPPRESS_CALLBACKS, not ZO_SortHeaderGroup.FORCE_RESELECT, self.sortOrder)
end

function ZO_FishFilletInventory:AddListDataTypes()
    local defaultSetup = self:GetDefaultTemplateSetupFunction()

    local function RowSetup(rowControl, data)
        local inventorySlot = rowControl:GetNamedChild("Button")
        ZO_ItemSlot_SetAlwaysShowStackCount(inventorySlot, false)

        defaultSetup(rowControl, data)

        if self.filterType == PROVISIONER_SPECIAL_INGREDIENT_TYPE_FILLET then
            ZO_ItemSlot_SetupUsableAndLockedColor(inventorySlot, data.stackCount >= 1)
        end
    end

    ZO_ScrollList_AddDataType(self.list, self:GetScrollDataType(), "ZO_CraftingInventoryComponentRow", 52, RowSetup, nil, nil, ZO_InventorySlot_OnPoolReset)
end

function ZO_FishFilletInventory:IsLocked(bagId, slotIndex)
    return ZO_CraftingInventory.IsLocked(self, bagId, slotIndex) or self.owner:IsSlotted(bagId, slotIndex) or IsItemPlayerLocked(bagId, slotIndex)
end

function ZO_FishFilletInventory:ChangeFilter(filterData)
    ZO_CraftingInventory.ChangeFilter(self, filterData)

    self.filterType = filterData.descriptor

    self:SetNoItemLabelText(GetString("SI_PROVISIONERSPECIALINGREDIENTTYPE_EXTRACTNONE", self.filterType))

    self.owner:OnFilterChanged()
    self:HandleDirtyEvent()
end

function ZO_FishFilletInventory:GetCurrentFilterType()
    return self.filterType
end

function ZO_FishFilletInventory:Refresh(data)
    local validItems
    if self.filterType == PROVISIONER_SPECIAL_INGREDIENT_TYPE_FILLET then
        local NO_FILTER_FUNCTION = nil
        validItems = self:EnumerateInventorySlotsAndAddToScrollData(ZO_FishFillet_Shared_IsFilletableItem, NO_FILTER_FUNCTION, self.filterType, data)
    end
    self.owner:OnInventoryUpdate(validItems, self.filterType)

    self:SetNoItemLabelHidden(#data > 0)
end

function ZO_FishFilletInventory:ShowAppropriateSlotDropCallouts(bagId, slotIndex)
    self.owner:ShowAppropriateSlotDropCallouts()
end

function ZO_FishFilletInventory:HideAllSlotDropCallouts()
    self.owner:HideAllSlotDropCallouts()
end