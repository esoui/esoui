ZO_CraftingInventory = ZO_SharedCraftingInventory:Subclass()

function ZO_CraftingInventory:Initialize(control, slotType, noDragging, connectInfoFn, connectInfoControl)
    ZO_SharedCraftingInventory.Initialize(self, control, slotType, connectInfoFn, connectInfoControl)

    local sortByHeaderControl = control:GetNamedChild("SortBy")
    local sortHeaders = ZO_SortHeaderGroup:New(sortByHeaderControl, true)

    local function OnSortHeaderClicked(key, order)
        self:ChangeSort(key, order)
    end

    sortHeaders:RegisterCallback(ZO_SortHeaderGroup.HEADER_CLICKED, OnSortHeaderClicked)
    sortHeaders:AddHeadersFromContainer()
    sortHeaders:SelectHeaderByKey("name", ZO_SortHeaderGroup.SUPPRESS_CALLBACKS)

    self.sortHeaders = sortHeaders

    self.sortOrder = ZO_SORT_ORDER_UP
    self.sortKey = "name"

    self.noDragging = noDragging

    if not noDragging then
        local function HandleCursorPickup(eventCode, cursorType, ...)
            if cursorType == MOUSE_CONTENT_INVENTORY_ITEM and not control:IsHidden() then
                self:ShowAppropriateSlotDropCallouts(...)
            end
        end

        local function HandleCursorCleared()
            self:HideAllSlotDropCallouts()
        end

        control:RegisterForEvent(EVENT_CURSOR_PICKUP, HandleCursorPickup)
        control:RegisterForEvent(EVENT_CURSOR_DROPPED, HandleCursorCleared)
    end

    self:HandleDirtyEvent()
end

-- override of ZO_SharedCraftingInventory:InitializeList()
function ZO_CraftingInventory:InitializeList()
    self.list = self.control:GetNamedChild("Backpack")
    self.noItemsLabel = self.control:GetNamedChild("NoItemsLabel")
    self:AddListDataTypes()
end

function ZO_CraftingInventory:SetNoItemLabelText(text)
    self.noItemsLabel:SetText(text)
end

function ZO_CraftingInventory:SetNoItemLabelHidden(isHidden)
    self.noItemsLabel:SetHidden(isHidden)
end

function ZO_CraftingInventory:AddListDataTypes()
    -- intended to be overridden for custom data types
    ZO_ScrollList_AddDataType(self.list, self:GetScrollDataType(), "ZO_CraftingInventoryComponentRow", 52, self:GetDefaultTemplateSetupFunction(), nil, nil, ZO_InventorySlot_OnPoolReset)
end

function ZO_CraftingInventory:SetMousedOverRow(slot)
    self.mousedOverSlot = slot
end

function ZO_CraftingInventory:GetDefaultTemplateSetupFunction()
    return function(rowControl, data)
        rowControl.owner = self
        local inventorySlot = rowControl:GetNamedChild("Button")
        inventorySlot.name = inventorySlot.name or rowControl:GetNamedChild("Name")
        inventorySlot.custom = inventorySlot.custom or rowControl:GetNamedChild("Custom")

        -- data.quality is deprecated, included here for addon backwards compatibility
        local displayQuality =  data.displayQuality or data.quality
        local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, displayQuality)
        inventorySlot.name:SetText(data.name)
        inventorySlot.name:SetColor(r, g, b, 1)

        if inventorySlot.custom then
            if data.custom then
                inventorySlot.custom:SetHidden(false)
                inventorySlot.custom:SetText(data.custom)
            else
                inventorySlot.custom:SetHidden(true)
            end
        end

        local sellPrice = rowControl:GetNamedChild("SellPrice")
        if sellPrice then
            ZO_CurrencyControl_SetSimpleCurrency(rowControl:GetNamedChild("SellPrice"), CURT_MONEY, data.sellPrice * data.stackCount, ITEM_SLOT_CURRENCY_OPTIONS)
        end

        ZO_PlayerInventorySlot_SetupSlot(rowControl, data.stackCount, data.icon, data.meetsUsageRequirements, self:IsLocked(data.bagId, data.slotIndex))

        inventorySlot.tooltipAnchor = rowControl

        ZO_Inventory_BindSlot(inventorySlot, self.baseSlotType or SLOT_TYPE_CRAFTING_COMPONENT, data.slotIndex, data.bagId)
        inventorySlot.owner = self

        ZO_UpdateStatusControlIcons(rowControl, data)
        ZO_UpdateTraitInformationControlIcon(rowControl, data)

        if self.noDragging then
            rowControl:SetHandler("OnDragStart", nil)
            rowControl:SetHandler("OnReceiveDrag", nil)
        end
    end
end

function ZO_CraftingInventory:HandleVisibleDirtyEvent()
    if self.control:IsHidden() then
        self.dirty = true
    else
        if self.dirty then
            self:PerformFullRefresh()
        else
            if not self.performingFullRefresh then
                ZO_ScrollList_RefreshVisible(self.list)
            end
        end
    end
end

function ZO_CraftingInventory:PerformFullRefresh()
    self.dirty = false
    if not self.performingFullRefresh then
        self.performingFullRefresh = true
        ZO_ScrollList_Clear(self.list)
        self:RefreshFilters()
        self:Refresh(ZO_ScrollList_GetDataList(self.list))
        self:SortData()
        ZO_ScrollList_Commit(self.list)
        self.performingFullRefresh = false
    end
end

function ZO_CraftingInventory:CreateNewTabFilterData(filterType, name, normal, pressed, highlight, disabled, visible)
    return {
        activeTabText = name,
        tooltipText = name,

        descriptor = filterType,
        normal = normal,
        pressed = pressed,
        highlight = highlight,
        disabled = disabled,
        visible = visible,
        callback = function(tabData) self:ChangeFilter(tabData) end,
    }
end

function ZO_CraftingInventory:SetActiveFilterByDescriptor(descriptor)
    if descriptor then
        ZO_MenuBar_SelectDescriptor(self.tabs, descriptor)
    else
        ZO_MenuBar_ClearSelection(self.tabs)
    end
end

local MENU_BAR_DATA =
{
    initialButtonAnchorPoint = RIGHT,
    buttonTemplate = "ZO_CraftingInventoryTab",
    normalSize = 51,
    downSize = 64,
    buttonPadding = -15,
    animationDuration = 180,
}

function ZO_CraftingInventory:SetFilters(filterData)
    if not self.tabs then
        self.tabs = self.control:GetNamedChild("Tabs")
        self.activeTab = self.control:GetNamedChild("TabsActive")

        ZO_MenuBar_SetData(self.tabs, MENU_BAR_DATA)
        ZO_CraftingUtils_ConnectMenuBarToCraftingProcess(self.tabs)
    else
        ZO_MenuBar_ClearButtons(self.tabs)
    end

    for _, data in ipairs(filterData) do
        ZO_MenuBar_AddButton(self.tabs, data)
    end
end

function ZO_CraftingInventory:RefreshFilters()
    ZO_MenuBar_UpdateButtons(self.tabs)
    if not ZO_MenuBar_GetSelectedDescriptor(self.tabs) then
        ZO_MenuBar_SelectLastVisibleButton(self.tabs, true)
    end
end

function ZO_CraftingInventory:SetLevelSort(levelDataGetFunction)
    self.levelDataGetFunction = levelDataGetFunction
end

function ZO_CraftingInventory:SetCustomSort(customDataGetFunction)
    self.customDataGetFunction = customDataGetFunction
end

function ZO_CraftingInventory:SetSortColumnHidden(columns, hidden)
    self.sortHeaders:SetHeadersHiddenFromKeyList(columns, hidden)
end

function ZO_CraftingInventory:AddItemData(bagId, slotIndex, totalStack, scrollDataType, data, customDataGetFunction, slotData, levelDataGetFunction)
    local icon, _, sellPrice, meetsUsageRequirements, _, _, _, functionalQuality, displayQuality = GetItemInfo(bagId, slotIndex)
    local newData = 
    {
        name = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(bagId, slotIndex)),
        icon = icon,
        stackCount = totalStack,
        sellPrice = sellPrice,
        stackSellPrice = totalStack * sellPrice,
        functionalQuality = functionalQuality,
        displayQuality = displayQuality,
        -- quality is deprecated, included here for addon backwards compatibility
        quality = displayQuality,
        meetsUsageRequirements = meetsUsageRequirements,
        level = levelDataGetFunction and levelDataGetFunction(bagId, slotIndex),
        custom = customDataGetFunction and customDataGetFunction(bagId, slotIndex),

        bagId = bagId,
        slotIndex = slotIndex,
    }
    if slotData then
        setmetatable(newData, { __index = slotData })
    else
        newData.statusSortOrder = 0 -- default value in case there is no slotData
    end

    local newScrollData = ZO_ScrollList_CreateDataEntry(scrollDataType, newData)

    data[#data + 1] = newScrollData
end

function ZO_CraftingInventory:EnumerateInventorySlotsAndAddToScrollData(predicate, filterFunction, filterType, data)
    local list = PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BACKPACK, predicate)
    PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BANK, predicate, list)
    PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_CRAFT_BAG, predicate, list)

    ZO_ClearTable(self.itemCounts)

    for itemId, itemInfo in pairs(list) do
        if not filterFunction or filterFunction(itemInfo.bag, itemInfo.index, filterType) then
            local NO_SLOT_DATA = nil
            self:AddItemData(itemInfo.bag, itemInfo.index, itemInfo.stack, self:GetScrollDataType(itemInfo.bag, itemInfo.index), data, self.customDataGetFunction, NO_SLOT_DATA, self.levelDataGetFunction)
        end
        self.itemCounts[itemId] = itemInfo.stack
    end

    return list
end

function ZO_CraftingInventory:GetIndividualInventorySlotsAndAddToScrollData(predicate, filterFunction, filterType, data, useWornBag, excludeBankedItems)
	local bagsToUse = { BAG_BACKPACK }
	if useWornBag then
		table.insert(bagsToUse, BAG_WORN)
	end 
	-- Expressly using double-negative here to maintain compatibility
	if not excludeBankedItems then
		table.insert(bagsToUse, BAG_BANK)
		table.insert(bagsToUse, BAG_SUBSCRIBER_BANK)
	end
    
    local filteredDataTable = SHARED_INVENTORY:GenerateFullSlotData(predicate, unpack(bagsToUse))

    ZO_ClearTable(self.itemCounts)

    for itemId, slotData in pairs(filteredDataTable) do
        if not filterFunction or filterFunction(slotData.bagId, slotData.slotIndex, filterType) then
            self:AddItemData(slotData.bagId, slotData.slotIndex, slotData.stackCount, self:GetScrollDataType(slotData.bagId, slotData.slotIndex), data, self.customDataGetFunction, slotData, self.levelDataGetFunction)
        end
        self.itemCounts[itemId] = slotData.stackCount
    end

    return filteredDataTable
end

function ZO_CraftingInventory:ChangeSort(sortKey, sortOrder)
    self.sortKey = sortKey
    self.sortOrder = sortOrder
    self:SortData()
    ZO_ScrollList_Commit(self.list)
end

function ZO_CraftingInventory:Show()
    self.control:SetHidden(false)
end

function ZO_CraftingInventory:Hide()
    self.control:SetHidden(true)
end

local sortKeys =
{
    slotIndex = { isNumeric = true },
    stackCount = { tiebreaker = "slotIndex", isNumeric = true },
    name = { tiebreaker = "displayQuality" },
    displayQuality = { tiebreaker = "quality", isNumeric = true },
    -- quality is deprecated, included here for addon backwards compatibility
    quality = { tiebreaker = "stackCount", isNumeric = true },
    statusSortOrder = { tiebreaker = "name", isNumeric = true },
    stackSellPrice = { tiebreaker = "name", isNumeric = true },
    traitInformationSortOrder = { tiebreaker = "name", isNumeric = true },
    level = { tiebreaker = "name", isNumeric = true, tieBreakerSortOrder = ZO_SORT_ORDER_UP },
    custom = { tiebreaker = "name", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
}

function ZO_CraftingInventory:SortData()
    local scrollData = ZO_ScrollList_GetDataList(self.list)

    self.sortFunction = self.sortFunction or function(entry1, entry2)
        if entry1.typeId == entry2.typeId then
            return ZO_TableOrderingFunction(entry1.data, entry2.data, self.sortKey, sortKeys, self.sortOrder)
        end
        return entry1.typeId < entry2.typeId
    end

    table.sort(scrollData, self.sortFunction)
end

function ZO_CraftingInventory:ChangeFilter(filterData)
    ZO_SharedCraftingInventory.ChangeFilter(self, filterData)
    ZO_ScrollList_ResetToTop(self.list)
end

function ZO_CraftingInventory_FilterButtonOnMouseEnter(self)
    if ZO_MenuBarButtonTemplate_OnMouseEnter(self) then
        InitializeTooltip(InformationTooltip, self, BOTTOM, 0, -10)
        SetTooltipText(InformationTooltip, ZO_MenuBarButtonTemplate_GetData(self).tooltipText)
    end
end

function ZO_CraftingInventory_FilterButtonOnMouseExit(self)
    if ZO_MenuBarButtonTemplate_OnMouseExit(self) then
        ClearTooltip(InformationTooltip)
    end
end

function ZO_CraftingInventoryComponentRow_OnMouseUp(control, button, upInside)
    if upInside then
        -- The case where mouse content isn't empty is already handled in OnSlotClicked, so fall through to that.
        if button == MOUSE_BUTTON_INDEX_LEFT and GetCursorContentType() == MOUSE_CONTENT_EMPTY then
            ZO_InventorySlot_DoPrimaryAction(control)
        else
            ZO_InventorySlot_OnSlotClicked(control, button)
        end
    end
end

function ZO_CraftingInventoryTabs_OnInitialized(control)
    ZO_MenuBar_OnInitialized(control)
    local filterBarData =
    {
        initialButtonAnchorPoint = RIGHT,
        buttonTemplate = "ZO_CraftingInventoryFilterTab",
        normalSize = 40,
        downSize = 51,
        buttonPadding = -5,
        animationDuration = 180,
    }
    ZO_MenuBar_SetData(control, filterBarData)
end