ZO_SharedCraftingInventory = ZO_Object:Subclass()

function ZO_SharedCraftingInventory:New(...)
    local craftingInventory = ZO_Object.New(self)
    craftingInventory:Initialize(...)
    return craftingInventory
end

local SCROLL_TYPE_ITEM = 1
function ZO_SharedCraftingInventory:Initialize(control, slotType, connectInfoFn, connectInfoControl)
    self.control = control
    self.control.owner = self
    self.baseSlotType = slotType
    self.itemCounts = {}

    self:InitializeList()

    if not connectInfoFn then connectInfoFn = ZO_InventoryInfoBar_ConnectStandardBar end
    if not connectInfoControl then connectInfoControl = control:GetNamedChild("InfoBar") end
    if connectInfoControl then connectInfoFn(connectInfoControl) end

    local function HandleInventoryChanged()
        self:HandleDirtyEvent()
    end

    control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, HandleInventoryChanged)
    control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, HandleInventoryChanged)

    local function OnCraftingAnimationStateChanged()
        self:HandleVisibleDirtyEvent()
        ClearMenu()
    end

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", OnCraftingAnimationStateChanged)
    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", OnCraftingAnimationStateChanged)

end

function ZO_SharedCraftingInventory:InitializeList()
    -- intended to be overridden
end

function ZO_SharedCraftingInventory:AddListDataTypes()
    -- intended to be overridden
end

function ZO_SharedCraftingInventory:OnShow()
    if self.dirty then
        self:PerformFullRefresh()
    end
end

function ZO_SharedCraftingInventory:IsLocked(bagId, slotIndex)
    -- intended to be overridden if the slot should appear as locked, but should call base to keep locking on craft
    return ZO_CraftingUtils_IsPerformingCraftProcess()
end

function ZO_SharedCraftingInventory:GetScrollDataType(bagId, slotIndex)
    -- intended to be overridden for custom data types
    return SCROLL_TYPE_ITEM
end

function ZO_SharedCraftingInventory:HandleDirtyEvent()
    if self.control:IsHidden() or ZO_CraftingUtils_IsPerformingCraftProcess() then
        self.dirty = true
    else
        self:PerformFullRefresh()
    end
end

function ZO_SharedCraftingInventory:PerformFullRefresh()
    -- intended to be overwritten
end

function ZO_SharedCraftingInventory:OnItemSelected(selectedData)
    -- intended to be overwritten
end

function ZO_SharedCraftingInventory:ShowAppropriateSlotDropCallouts(bagId, slotIndex)
    -- intended to be overwritten
end

function ZO_SharedCraftingInventory:HideAllSlotDropCallouts()
    -- intended to be overwritten
end

function ZO_SharedCraftingInventory:Refresh(data)
    -- intended to be overwritten
end

function ZO_SharedCraftingInventory:ChangeFilter(filterData)
    self.activeTab:SetText(filterData.activeTabText)
    -- intended to be overwritten, but should call base
end

--- When set, overrides the crafting inventory's default sort function.
function ZO_SharedCraftingInventory:SetOverrideItemSort(itemSortFunction)
    self.sortFunction = itemSortFunction
end

function ZO_SharedCraftingInventory:SetCustomExtraData(customExtraDataFunction)
    self.customExtraDataFunction = customExtraDataFunction
end

function ZO_SharedCraftingInventory:SetCustomSort(customDataSortFunction)
    self.customDataSortFunction = customDataSortFunction
end

function ZO_SharedCraftingInventory:SetVerticalScrollCraftEntryType(type)
    self.verticalScrollCraftEntryType = type
end

function ZO_SharedCraftingInventory:EnumerateInventorySlotsAndAddToScrollData(predicate, filterFunction, filterType, data)
    -- intended to be overwritten
    return nil
end

assert(17 == BAG_MAX_VALUE) -- if you add a new bag, check to see if you need to add it to crafting inventories

ZO_ALL_CRAFTING_INVENTORY_BAGS_AND_WORN = 
{
    BAG_BACKPACK, BAG_BANK, BAG_SUBSCRIBER_BANK, BAG_WORN
}

ZO_ALL_CRAFTING_INVENTORY_BAGS_WITHOUT_WORN = 
{
    BAG_BACKPACK, BAG_BANK, BAG_SUBSCRIBER_BANK
}

function ZO_SharedCraftingInventory:GetIndividualInventorySlotsAndAddToScrollData(predicate, filterFunction, filterType, data, useWornBag)
    -- intended to be overwritten
    return nil
end

function ZO_SharedCraftingInventory:GetStackCount(bagId, slotIndex)
    local itemInstanceId = GetItemInstanceId(bagId, slotIndex)
    return self.itemCounts[itemInstanceId] or 0
end

function ZO_SharedCraftingInventory:Show()
    self.control:SetHidden(false)
end

function ZO_SharedCraftingInventory:Hide()
    self.control:SetHidden(true)
end

function ZO_SharedCraftingInventory:SetNoItemLabelText(text)
    -- intended to be overwritten
end
