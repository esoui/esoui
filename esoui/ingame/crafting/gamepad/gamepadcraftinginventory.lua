ZO_GamepadCraftingInventory = ZO_SharedCraftingInventory:Subclass()

function ZO_GamepadCraftingInventory:New(...)
    return ZO_SharedCraftingInventory.New(self, ...)
end

local SCROLL_TYPE_ITEM = 1
function ZO_GamepadCraftingInventory:Initialize(control, slotType, connectInfoFn, connectInfoControl)
    ZO_SharedCraftingInventory.Initialize(self, control, slotType, connectInfoFn, connectInfoControl)

    self:HandleDirtyEvent()
end

function ZO_GamepadCraftingInventory:InitializeList()
    self.list = ZO_GamepadVerticalItemParametricScrollList:New(self.control)
    self.list:SetAlignToScreenCenter(true)
    self:AddListDataTypes()
end

function ZO_GamepadCraftingInventory:SetNoItemLabelText(text)
    self.list:SetNoItemText(text)
end

function ZO_GamepadCraftingInventory:AddListDataTypes()
    -- intended to be overridden for custom data types
    self:AddVerticalScrollDataTypes("ZO_GamepadItemSubEntry")
end

function ZO_GamepadCraftingInventory:AddVerticalScrollDataTypes(verticalScrollCraftEntryType, setupTemplate, setupHeaderTemplate)
    self:SetVerticalScrollCraftEntryType(verticalScrollCraftEntryType)
    self.list:AddDataTemplate(self.verticalScrollCraftEntryTypeTemplate, setupTemplate or ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "Item")
    self.list:AddDataTemplateWithHeader(self.verticalScrollCraftEntryTypeTemplate, setupTemplate or ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate", setupHeaderTemplate, "Item")
end

function ZO_GamepadCraftingInventory:SetVerticalScrollDataTypes(verticalScrollCraftEntryType)
    self.verticalScrollCraftEntryType = verticalScrollCraftEntryType
end

function ZO_GamepadCraftingInventory:Activate()
    self.list:Activate()
end

function ZO_GamepadCraftingInventory:Deactivate()
    self.list:Deactivate()
end

function ZO_GamepadCraftingInventory:HandleVisibleDirtyEvent()
    if self.control:IsHidden() then
        self.dirty = true
    else
        if self.dirty then
            self:PerformFullRefresh()
        end
    end
end

function ZO_GamepadCraftingInventory:PerformFullRefresh()
    self.dirty = false
    if not self.performingFullRefresh then
        self.performingFullRefresh = true
        self.list:Clear()
        self:Refresh(self.list.dataList)
        self.list:Commit()
        self.performingFullRefresh = false
    end
end

-- This sort is appropriate for gear, like armor and weapons
local DEFAULT_GAMEPAD_CRAFTING_ITEM_SORT =
{
    customSortData = { tiebreaker = "bestItemCategoryName" },
    bestItemCategoryName = { tiebreaker = "text" },
    text = { tiebreaker = "requiredLevel" },
    requiredLevel = { tiebreaker = "requiredChampionPoints", isNumeric = true },
    requiredChampionPoints = { tiebreaker = "iconFile", isNumeric = true },
    iconFile = { tiebreaker = "uniqueId" },
    uniqueId = { isId64 = true },
}

function ZO_GamepadCraftingInventory_DefaultItemSortComparator(left, right)
    return ZO_TableOrderingFunction(left, right, "customSortData", DEFAULT_GAMEPAD_CRAFTING_ITEM_SORT, ZO_SORT_ORDER_UP)
end

function ZO_GamepadCraftingInventory:SetCustomExtraData(customExtraDataFunction)
    self.customExtraDataFunction = customExtraDataFunction
end

function ZO_GamepadCraftingInventory:SetCustomSort(customDataSortFunction)
    self.customDataSortFunction = customDataSortFunction
end

function ZO_GamepadCraftingInventory:SetCustomBestItemCategoryNameFunction(customBestItemCategoryNameFunction)
    self.customBestItemCategoryNameFunction = customBestItemCategoryNameFunction
end

function ZO_GamepadCraftingInventory:SetVerticalScrollCraftEntryType(type)
    self.verticalScrollCraftEntryType = type
    self.verticalScrollCraftEntryTypeTemplate = type .. "Template"
    self.verticalScrollCraftEntryTypeWithHeaderTemplate = type .. "TemplateWithHeader"
end

function ZO_GamepadCraftingInventory:GenerateCraftingInventoryEntryData(bagId, slotIndex, stackCount, slotData)
    local itemName = GetItemName(bagId, slotIndex)
    local icon = GetItemInfo(bagId, slotIndex)
    local name = zo_strformat(SI_TOOLTIP_ITEM_NAME, itemName)
    local customSortData = self.customDataSortFunction and self.customDataSortFunction(bagId, slotIndex) or 0

    local newData = ZO_GamepadEntryData:New(name)
    newData:InitializeCraftingInventoryVisualData(bagId, slotIndex, stackCount, customSortData, self.customBestItemCategoryNameFunction, slotData)
    ZO_InventorySlot_SetType(newData, self.baseSlotType)

    if self.customExtraDataFunction then
        self.customExtraDataFunction(bagId, slotIndex, newData)
    end

    return newData
end

function ZO_GamepadCraftingInventory:AddFilteredDataToList(filteredDataTable)
    local sortFunction = self.sortFunction or ZO_GamepadCraftingInventory_DefaultItemSortComparator

    table.sort(filteredDataTable, sortFunction)

    local lastBestItemCategoryName
    for i, itemData in ipairs(filteredDataTable) do
        if itemData.bestItemCategoryName ~= lastBestItemCategoryName then
            lastBestItemCategoryName = itemData.bestItemCategoryName
            itemData:SetHeader(zo_strformat(SI_GAMEPAD_CRAFTING_INVENTORY_HEADER, lastBestItemCategoryName))
        end

        local template = self:GetListEntryTemplate(itemData)

        self.list:AddEntry(template, itemData)
    end
end

function ZO_GamepadCraftingInventory:EnumerateInventorySlotsAndAddToScrollData(predicate, filterFunction, filterType, data)
    local list = PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BACKPACK, predicate)
    PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BANK, predicate, list)
    PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_CRAFT_BAG, predicate, list)

    ZO_ClearTable(self.itemCounts)

    local filteredDataTable = {}
    for itemId, itemInfo in pairs(list) do
        if not filterFunction or filterFunction(itemInfo.bag, itemInfo.index, filterType) then
            filteredDataTable[#filteredDataTable + 1] = self:GenerateCraftingInventoryEntryData(itemInfo.bag, itemInfo.index, itemInfo.stack)
        end
        self.itemCounts[itemId] = itemInfo.stack
    end

    self:AddFilteredDataToList(filteredDataTable)

    return list
end

function ZO_GamepadCraftingInventory:GetIndividualInventorySlotsAndAddToScrollData(predicate, filterFunction, filterType, data, useWornBag)
    local bagsToUse = useWornBag and ZO_ALL_CRAFTING_INVENTORY_BAGS_AND_WORN or ZO_ALL_CRAFTING_INVENTORY_BAGS_WITHOUT_WORN
    local list = SHARED_INVENTORY:GenerateFullSlotData(predicate, unpack(bagsToUse))

    ZO_ClearTable(self.itemCounts)

    local filteredDataTable = {}
    for i, slotData in ipairs(list) do
        local bagId = slotData.bagId
        local slotIndex = slotData.slotIndex
        if not filterFunction or filterFunction(bagId, slotIndex, filterType) then
            filteredDataTable[#filteredDataTable + 1] = self:GenerateCraftingInventoryEntryData(bagId, slotIndex, slotData.stackCount, slotData)
        end
        self.itemCounts[i] = slotData.stackCount
    end

    self:AddFilteredDataToList(filteredDataTable)

    return list
end

-- Returns the name of a template to use for a list entry.
-- Intended to be overridden if subclass wants to specify a custom template per entry.
function ZO_GamepadCraftingInventory:GetListEntryTemplate(data)
    if data.header then
        return self.verticalScrollCraftEntryTypeWithHeaderTemplate
    else
        return self.verticalScrollCraftEntryTypeTemplate
    end
end

function ZO_GamepadCraftingInventory:Show()
    self.control:SetHidden(false)
end

function ZO_GamepadCraftingInventory:Hide()
    self.control:SetHidden(true)
end

function ZO_GamepadCraftingInventory:CurrentSelection()
    return self.list:GetTargetData()
end

function ZO_GamepadCraftingInventory:CurrentSelectionBagAndSlot()
    local data = self.list:GetTargetData()
    if data then
        return data.bagId, data.slotIndex
    end
end

