local DATA_TYPE_ITEM = 1
local LIST_ENTRY_HEIGHT = 52

-----------------------------
-- Companion Equipment
-----------------------------
ZO_CompanionEquipment_Keyboard = ZO_InitializingObject:Subclass()

function ZO_CompanionEquipment_Keyboard:Initialize(control)
    self.control = control
    self.playerGoldLabel = control:GetNamedChild("InfoBarMoney")
    self.freeSlotsLabel = control:GetNamedChild("InfoBarFreeSlots")
    self.list = control:GetNamedChild("List")
    self.emptyLabel = control:GetNamedChild("Empty")
    self.sortHeadersControl = control:GetNamedChild("SortBy")
    self.sortHeaders = ZO_SortHeaderGroup:New(self.sortHeadersControl, true)
    self.tabs = control:GetNamedChild("Tabs")
    self.activeTabLabel = self.tabs:GetNamedChild("Active")

    -- gold display
    local function OnGoldUpdated(eventId, newAmount, oldAmount, reason)
        self:SetPlayerGoldAmount(newAmount)
    end

    control:RegisterForEvent(EVENT_MONEY_UPDATE, OnGoldUpdated)

    self:SetPlayerGoldAmount(GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER))

    -- inventory list
    local DEFAULT_HIDE_CALLBACK = nil
    local DEFAULT_SELECT_SOUND = nil
    ZO_ScrollList_AddDataType(self.list, DATA_TYPE_ITEM, "ZO_PlayerInventorySlot", LIST_ENTRY_HEIGHT, function(rowControl, data) self:SetupItemRow(rowControl, data) end, DEFAULT_HIDE_CALLBACK, DEFAULT_SELECT_SOUND, ZO_InventorySlot_OnPoolReset)

    -- tabs
    local FILTER_KEYS =
    {
        ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY, ITEM_TYPE_DISPLAY_CATEGORY_ARMOR, ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS, ITEM_TYPE_DISPLAY_CATEGORY_ALL,
    }

    self.filters = {}
    for _, key in ipairs(FILTER_KEYS) do
        local filterData = ZO_ItemFilterUtils.GetItemTypeDisplayCategoryFilterDisplayInfo(key)
        local filter = self:CreateNewTabFilterData(filterData.filterType, filterData.filterString, filterData.icons.up, filterData.icons.down, filterData.icons.over)
        table.insert(self.filters, filter)
        ZO_MenuBar_AddButton(self.tabs, filter)
    end

    -- sort headers
    local sortKeys = ZO_Inventory_GetDefaultHeaderSortKeys()

    self.sortFunction = function(entry1, entry2)
        local sortKey = self.currentFilter.sortKey
        local sortOrder = self.currentFilter.sortOrder

        return ZO_TableOrderingFunction(entry1.data, entry2.data, sortKey, sortKeys, sortOrder)
    end

    local function OnSortHeaderClicked(key, order)
        self.currentFilter.sortKey = key
        self.currentFilter.sortOrder = order

        self:SortData()
    end

    self.sortHeaders:RegisterCallback(ZO_SortHeaderGroup.HEADER_CLICKED, OnSortHeaderClicked)
    self.sortHeaders:AddHeadersFromContainer()
    local SUPPRESS_CALLBACKS = true
    self.sortHeaders:SelectHeaderByKey("name", SUPPRESS_CALLBACKS)

    ZO_MenuBar_SelectDescriptor(self.tabs, ITEM_TYPE_DISPLAY_CATEGORY_ALL)

    self.searchBox = control:GetNamedChild("SearchFiltersTextSearchBox");

    local function OnTextSearchTextChanged(editBox)
        ZO_EditDefaultText_OnTextChanged(editBox)
        TEXT_SEARCH_MANAGER:SetSearchText("companionEquipmentTextSearch", editBox:GetText())
    end

    self.searchBox:SetHandler("OnTextChanged", OnTextSearchTextChanged)

    local SUPPRESS_TEXT_CHANGED_CALLBACK = true
    local function OnListTextFilterComplete()
        if COMPANION_EQUIPMENT_KEYBOARD_FRAGMENT:IsShowing() then
            self.searchBox:SetText(TEXT_SEARCH_MANAGER:GetSearchText("companionEquipmentTextSearch"), SUPPRESS_TEXT_CHANGED_CALLBACK)
            self:UpdateList()
        end
    end

    TEXT_SEARCH_MANAGER:RegisterCallback("UpdateSearchResults", OnListTextFilterComplete)

    -- inventory updates
    local function HandleInventoryChanged()
        if not control:IsHidden() then
            self:UpdateList()
            self:UpdateFreeSlots()
        end
    end

    local function RefreshSlotLocked(slotIndex, locked)
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        for i, dataEntry in ipairs(scrollData) do
            local data = dataEntry.data
            if data.slotIndex == slotIndex then
                data.locked = locked
                ZO_ScrollList_RefreshVisible(self.list)
                break
            end
        end
    end

    local function HandleInventorySlotLocked(_, bagId, slotIndex)
        if bagId == BAG_BACKPACK then
            RefreshSlotLocked(slotIndex, true)
        end
    end

    local function HandleInventorySlotUnlocked(_, bagId, slotIndex)
        if bagId == BAG_BACKPACK then
            RefreshSlotLocked(slotIndex, false)
        end
    end

    control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, HandleInventoryChanged)
    control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, HandleInventoryChanged)
    control:RegisterForEvent(EVENT_INVENTORY_SLOT_LOCKED, HandleInventorySlotLocked)
    control:RegisterForEvent(EVENT_INVENTORY_SLOT_UNLOCKED, HandleInventorySlotUnlocked)
    control:RegisterForEvent(EVENT_LEVEL_UPDATE, HandleInventoryChanged)
    control:AddFilterForEvent(EVENT_LEVEL_UPDATE, REGISTER_FILTER_UNIT_TAG, "companion")

    -- inventory landing area
    self.landingAreaControl = self.list:GetNamedChild("LandingArea")

    local function HandleCursorPickup(_, cursorType)
        if cursorType == MOUSE_CONTENT_EQUIPPED_ITEM then
            ZO_InventoryLandingArea_SetHidden(self.landingAreaControl, false)
        end
    end

    local function HandleCursorCleared()
        ZO_InventoryLandingArea_SetHidden(self.landingAreaControl, true)
    end

    control:RegisterForEvent(EVENT_CURSOR_PICKUP, HandleCursorPickup)
    control:RegisterForEvent(EVENT_CURSOR_DROPPED, HandleCursorCleared)

    -- fragment
    COMPANION_EQUIPMENT_KEYBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    COMPANION_EQUIPMENT_KEYBOARD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            TEXT_SEARCH_MANAGER:ActivateTextSearch("companionEquipmentTextSearch")
            self:UpdateList()
            self:UpdateFreeSlots()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            TEXT_SEARCH_MANAGER:DeactivateTextSearch("companionEquipmentTextSearch")
        end
    end)
end

function ZO_CompanionEquipment_Keyboard:SetPlayerGoldAmount(value)
    ZO_CurrencyControl_SetSimpleCurrency(self.playerGoldLabel, CURT_MONEY, value, ZO_KEYBOARD_CURRENCY_OPTIONS)
end

function ZO_CompanionEquipment_Keyboard:UpdateFreeSlots()
    local numUsedSlots, numSlots = PLAYER_INVENTORY:GetNumSlots(INVENTORY_BACKPACK)
    if numUsedSlots < numSlots then
        self.freeSlotsLabel:SetText(zo_strformat(SI_INVENTORY_BACKPACK_REMAINING_SPACES, numUsedSlots, numSlots))
    else
        self.freeSlotsLabel:SetText(zo_strformat(SI_INVENTORY_BACKPACK_COMPLETELY_FULL, numUsedSlots, numSlots))
    end
end

function ZO_CompanionEquipment_Keyboard:SetupItemRow(control, data)
    local nameControl = control:GetNamedChild("Name")
    local displayColor = GetItemQualityColor(data.displayQuality)
    nameControl:SetText(displayColor:Colorize(data.name))

    local sellPriceControl = control:GetNamedChild("SellPrice")
    sellPriceControl:SetHidden(false)
    ZO_CurrencyControl_SetSimpleCurrency(sellPriceControl, CURT_MONEY, data.stackSellPrice, ITEM_SLOT_CURRENCY_OPTIONS)

    local inventorySlot = control:GetNamedChild("Button")
    ZO_Inventory_BindSlot(inventorySlot, data.slotType, data.slotIndex, data.bagId)
    ZO_PlayerInventorySlot_SetupSlot(control, data.stackCount, data.iconFile, data.meetsUsageRequirement, data.locked or IsUnitDead("player"))

    ZO_UpdateStatusControlIcons(control, data)
end

function ZO_CompanionEquipment_Keyboard:CreateNewTabFilterData(filterType, text, normal, pressed, highlight, extraInfo)
    local tabData =
    {
        -- Custom data
        activeTabText = text,
        tooltipText = text,
        sortKey = "name",
        sortOrder = ZO_SORT_ORDER_UP,
        extraInfo = extraInfo,

        -- Menu bar data
        descriptor = filterType,
        normal = normal,
        pressed = pressed,
        highlight = highlight,
        callback = function(filterData) self:ChangeFilter(filterData) end,
    }

    return tabData
end

function ZO_CompanionEquipment_Keyboard:ChangeFilter(filterData)
    self.currentFilter = filterData
    self.activeTabLabel:SetText(filterData.activeTabText)
    ZO_ScrollList_ResetToTop(self.list)
    self:UpdateList()

    self.sortHeaders:SelectAndResetSortForKey(filterData.sortKey)
end

function ZO_CompanionEquipment_Keyboard:SortData()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    table.sort(scrollData, self.sortFunction)
    ZO_ScrollList_Commit(self.list)
end

function ZO_CompanionEquipment_Keyboard:ShouldAddItemToList(itemData)
    return ZO_ItemFilterUtils.IsSlotInItemTypeDisplayCategoryAndSubcategory(itemData, ITEM_TYPE_DISPLAY_CATEGORY_COMPANION, self.currentFilter.descriptor) and TEXT_SEARCH_MANAGER:IsItemInSearchTextResults("companionEquipmentTextSearch", BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, itemData.bagId, itemData.slotIndex)
end

function ZO_CompanionEquipment_Keyboard:UpdateList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ScrollList_Clear(self.list)

    for slotIndex in ZO_IterateBagSlots(BAG_BACKPACK) do
        local slotData = SHARED_INVENTORY:GenerateSingleSlotData(BAG_BACKPACK, slotIndex)
        if slotData and slotData.stackCount > 0 and slotData.actorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION then
            local itemData = ZO_EntryData:New(slotData)
            itemData.slotType = SLOT_TYPE_ITEM

            if self:ShouldAddItemToList(itemData) then
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(DATA_TYPE_ITEM, itemData))
            end
        end
    end

    table.sort(scrollData, self.sortFunction)
    ZO_ScrollList_Commit(self.list)

    local isListEmpty = #scrollData == 0

    self.sortHeadersControl:SetHidden(isListEmpty)
    self.emptyLabel:SetHidden(not isListEmpty)
end

-----------------------------
-- Global XML Functions
-----------------------------

function ZO_CompanionEquipment_Keyboard_OnInitialize(control)
    COMPANION_EQUIPMENT_KEYBOARD = ZO_CompanionEquipment_Keyboard:New(control)
end
