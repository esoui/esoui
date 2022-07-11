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
    self.subTabs = control:GetNamedChild("SearchFiltersSubTabs")
    self.activeTabLabel = self.tabs:GetNamedChild("Active")

    self:SetupCategoryFlashAnimation()

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
        filter.control = ZO_MenuBar_AddButton(self.tabs, filter)
        table.insert(self.filters, filter)
    end

    local IS_SUB_FILTER = true
    local function GetSearchFilters(searchFilterKeys)
        local searchFilters = {}
        for filterId, subFilters in pairs(searchFilterKeys) do
            searchFilters[filterId] = {}

            local searchFilterAtId = searchFilters[filterId]
            for _, subfilterKey in ipairs(subFilters) do
                local filterData = ZO_ItemFilterUtils.GetSearchFilterData(filterId, subfilterKey)
                local filter = self:CreateNewTabFilterData(filterData.filterType, filterData.filterString, filterData.icons.up, filterData.icons.down, filterData.icons.over, IS_SUB_FILTER)
                table.insert(searchFilterAtId, filter)
            end
        end

        return searchFilters
    end

    local SEARCH_FILTER_KEYS =
    {
        [ITEM_TYPE_DISPLAY_CATEGORY_ALL] =
        {
            ITEM_TYPE_DISPLAY_CATEGORY_ALL,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS] =
        {
            EQUIPMENT_FILTER_TYPE_RESTO_STAFF, EQUIPMENT_FILTER_TYPE_DESTRO_STAFF, EQUIPMENT_FILTER_TYPE_BOW,
            EQUIPMENT_FILTER_TYPE_TWO_HANDED, EQUIPMENT_FILTER_TYPE_ONE_HANDED, EQUIPMENT_FILTER_TYPE_NONE,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_ARMOR] =
        {
            EQUIPMENT_FILTER_TYPE_SHIELD, EQUIPMENT_FILTER_TYPE_HEAVY, EQUIPMENT_FILTER_TYPE_MEDIUM,
            EQUIPMENT_FILTER_TYPE_LIGHT, EQUIPMENT_FILTER_TYPE_NONE,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY] =
        {
            EQUIPMENT_FILTER_TYPE_RING, EQUIPMENT_FILTER_TYPE_NECK, EQUIPMENT_FILTER_TYPE_NONE,
        },
    }

    self.subFilters = GetSearchFilters(SEARCH_FILTER_KEYS, INVENTORY_BACKPACK)

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
    self.sortHeaders:SelectHeaderByKey("statusSortOrder", SUPPRESS_CALLBACKS)

    ZO_MenuBar_SelectDescriptor(self.tabs, ITEM_TYPE_DISPLAY_CATEGORY_ALL)

    self.searchBox = control:GetNamedChild("SearchFiltersTextSearchBox");

    local function OnTextSearchTextChanged(editBox)
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
            self:ClearNewStatusOnItemsThePlayerHasSeen()
            self.newItemData = {}
        end
    end)

    SHARED_INVENTORY:RegisterCallback("SlotAdded", function(bagId, slotIndex, newSlotData, suppressItemAlert)
        if bagId == BAG_BACKPACK then
            self:OnInventoryItemAdded(INVENTORY_BACKPACK, bagId, slotIndex, newSlotData, suppressItemAlert)
        end
    end)
end

function ZO_CompanionEquipment_Keyboard:OnInventoryItemAdded(inventoryType, bagId, slotIndex, newSlotData, suppressItemAlert)
    -- play a brief flash animation on all the filter tabs that match this item's filterTypes
    if COMPANION_EQUIPMENT_KEYBOARD_FRAGMENT:IsShowing() and newSlotData.brandNew then
        self:PlayItemAddedAlert(newSlotData, suppressItemAlert)
    end
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

function ZO_CompanionEquipment_Keyboard:CreateNewTabFilterData(filterType, text, normal, pressed, highlight, isSubFilter)
    local tabData =
    {
        -- Custom data
        activeTabText = text,
        tooltipText = text,
        sortKey = "statusSortOrder",
        sortOrder = ZO_SORT_ORDER_DOWN,
        isSubFilter = isSubFilter,

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
    local activeTabText
    local activeSubTabText
    local formattedTabText
    if self.currentFilter and filterData.isSubFilter then
        local currentFilter

        for _, filter in pairs(self.filters) do
            if filter.descriptor == self.currentFilter.descriptor then
                currentFilter = filter
                break
            end
        end
        self.currentFilter = currentFilter
        self.currentSubFilter = filterData
        formattedTabText = zo_strformat(SI_INVENTORY_FILTER_WITH_SUB_TAB, currentFilter.activeTabText, filterData.activeTabText)
    else
        self.currentFilter = filterData
        self.currentSubFilter = nil
        formattedTabText = filterData.activeTabText
    end

    local currentFilterType = self.currentFilter.descriptor
    if not filterData.isSubFilter then
        local menuBar = self.subTabs
        if menuBar then
            for _, button in ZO_MenuBar_ButtonControlIterator(menuBar) do
                local flash = button:GetNamedChild("Flash")
                flash:SetAlpha(0)
                self:RemoveCategoryFlashAnimationControl(flash)
            end

            ZO_MenuBar_ClearButtons(menuBar)

            if self.subFilters then
                if self.subFilters[currentFilterType] then
                    for _, data in ipairs(self.subFilters[currentFilterType]) do
                        data.control = ZO_MenuBar_AddButton(menuBar, data)
                    end

                    ZO_MenuBar_SelectDescriptor(menuBar, ITEM_TYPE_DISPLAY_CATEGORY_ALL)
                end
            end
        end
    elseif #self.flashingSlots > 0 then
        for _, flashingSlot in ipairs(self.flashingSlots) do
            for _, subFilter in pairs(self.subFilters[currentFilterType]) do
                if ZO_ItemFilterUtils.IsCompanionSlotInItemTypeDisplayCategoryAndSubcategory(flashingSlot, currentFilterType, subFilter.descriptor) then
                    self:AddCategoryFlashAnimationControl(subFilter.control:GetNamedChild("Flash"))
                end
            end
        end
    end

    ZO_ScrollList_ResetToTop(self.list)
    self:UpdateList()

    self.sortHeaders:SelectAndResetSortForKey(filterData.sortKey)
end

function ZO_CompanionEquipment_Keyboard:SortData()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    table.sort(scrollData, self.sortFunction)
    ZO_ScrollList_Commit(self.list)
end

do
    local function DoesSlotPassAdditionalFilter(slot, currentFilter, additionalFilter)
        if type(additionalFilter) == "function" then
            return additionalFilter(slot)
        elseif type(additionalFilter) == "number" then
            return ZO_ItemFilterUtils.IsCompanionSlotInItemTypeDisplayCategoryAndSubcategory(slot, currentFilter, additionalFilter)
        end

        return true
    end

    function ZO_CompanionEquipment_Keyboard:ShouldAddItemToList(itemData)
        if not DoesSlotPassAdditionalFilter(itemData, self.currentFilter.descriptor, self.currentSubFilter.descriptor) then
            return false
        end

        if not DoesSlotPassAdditionalFilter(itemData,  self.currentFilter.descriptor, self.additionalFilter) then
            return false
        end

        return ZO_ItemFilterUtils.IsCompanionSlotInItemTypeDisplayCategoryAndSubcategory(itemData, self.currentFilter.descriptor, self.currentSubFilter.descriptor) and TEXT_SEARCH_MANAGER:IsItemInSearchTextResults("companionEquipmentTextSearch", BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, itemData.bagId, itemData.slotIndex)
    end
end

function ZO_CompanionEquipment_Keyboard:UpdateList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    local newItemData = {}
    ZO_ScrollList_Clear(self.list)

    for slotIndex in ZO_IterateBagSlots(BAG_BACKPACK) do
        local slotData = SHARED_INVENTORY:GenerateSingleSlotData(BAG_BACKPACK, slotIndex)
        if slotData and slotData.stackCount > 0 and slotData.actorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION then
            local itemData = ZO_EntryData:New(slotData)
            itemData.slotType = SLOT_TYPE_ITEM

            if itemData.brandNew then
                newItemData[slotIndex] = itemData
                if self.newItemData[slotIndex] then
                    newItemData[slotIndex].clearAgeOnClose = self.newItemData[slotIndex].clearAgeOnClose
                else
                    --Only play the item added alert once
                    --If item data is already stored for this, then we've already played the alert
                    self:PlayItemAddedAlert(slotData)
                end
            end

            if self:ShouldAddItemToList(itemData) then
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(DATA_TYPE_ITEM, itemData))
            end
        end
    end

    self.newItemData = newItemData
    table.sort(scrollData, self.sortFunction)
    ZO_ScrollList_Commit(self.list)

    local isListEmpty = #scrollData == 0

    self.sortHeadersControl:SetHidden(isListEmpty)
    self.emptyLabel:SetHidden(not isListEmpty)
end

do
    local function TryClearNewStatus(slot)
        if slot and slot.clearAgeOnClose then
            slot.clearAgeOnClose = nil
            SHARED_INVENTORY:ClearNewStatus(slot.bagId, slot.slotIndex)
            return true
        else
            return false
        end
    end

    function ZO_CompanionEquipment_Keyboard:ClearNewStatusOnItemsThePlayerHasSeen(inventoryType)
        local anyNewStatusCleared = false
        for slotIndex, dataEntry in pairs(self.newItemData) do
            local newStatusCleared = TryClearNewStatus(dataEntry)
            anyNewStatusCleared = anyNewStatusCleared or newStatusCleared
        end

        if anyNewStatusCleared then
            if self.list then
                ZO_ScrollList_RefreshVisible(self.list, nil, ZO_UpdateStatusControlIcons)
            end

            COMPANION_KEYBOARD:UpdateSceneGroupButtons()
            COMPANION_CHARACTER_KEYBOARD:RefreshCategoryStatusIcons()
        end
    end
end

function ZO_CompanionEquipment_Keyboard:SetupCategoryFlashAnimation()
    self.categoryFlashAnimationTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_CompanionEquipment_Keyboard_NewItemCategory_FlashAnimation")
    self.flashingSlots = {}
    self.listeningControls = {}

    local function OnStop()
        self.flashingSlots = {}
        self.listeningControls = {}
    end
    self.categoryFlashAnimationTimeline:SetHandler("OnStop", OnStop)
end

function ZO_CompanionEquipment_Keyboard:AddCategoryFlashAnimationControl(control)
    local controlName = control:GetName()
    self.listeningControls[controlName] = control
end

function ZO_CompanionEquipment_Keyboard:RemoveCategoryFlashAnimationControl(control)
    local controlName = control:GetName()
    self.listeningControls[controlName] = nil
end

do
    local FLASH_ANIMATION_MIN_ALPHA = 0
    local FLASH_ANIMATION_MAX_ALPHA = 0.5
    function ZO_CompanionEquipment_Keyboard:UpdateCategoryFlashAnimation(timeline, progress)
        local remainingPlaybackLoops = self.categoryFlashAnimationTimeline:GetPlaybackLoopsRemaining()
        local currentAlpha
        local alphaDelta = progress * (FLASH_ANIMATION_MAX_ALPHA - FLASH_ANIMATION_MIN_ALPHA)
        if remainingPlaybackLoops % 2 then
            -- Fading out
            currentAlpha = alphaDelta + FLASH_ANIMATION_MIN_ALPHA
        else
            -- Fading in
            currentAlpha = FLASH_ANIMATION_MAX_ALPHA - alphaDelta
        end

        for _, control in pairs(self.listeningControls) do
            control:SetAlpha(currentAlpha)
        end
    end
end

function ZO_CompanionEquipment_Keyboard:PlayItemAddedAlert(slot, suppressItemAlert)
    if suppressItemAlert then
        return
    end

    local isSlotAdded = false
    for _, filter in pairs(self.filters) do
        if ZO_ItemFilterUtils.IsSlotInItemTypeDisplayCategoryAndSubcategory(slot, ITEM_TYPE_DISPLAY_CATEGORY_COMPANION, filter.descriptor) then
            self:AddCategoryFlashAnimationControl(filter.control:GetNamedChild("Flash"))
            if not self.categoryFlashAnimationTimeline:IsPlaying() then
                self.categoryFlashAnimationTimeline:PlayFromStart()
            end
            if not isSlotAdded then
                table.insert(self.flashingSlots, slot)
                isSlotAdded = true
            end
        end
    end

    local currentFilter = self.currentFilter
    for _, subFilter in pairs(self.subFilters[currentFilter.descriptor]) do
        if ZO_ItemFilterUtils.IsCompanionSlotInItemTypeDisplayCategoryAndSubcategory(slot, currentFilter.descriptor, subFilter.descriptor) then
            self:AddCategoryFlashAnimationControl(subFilter.control:GetNamedChild("Flash"))
            if not self.categoryFlashAnimationTimeline:IsPlaying() then
                self.categoryFlashAnimationTimeline:PlayFromStart()
            end
            if not isSlotAdded then
                table.insert(self.flashingSlots, slot)
                isSlotAdded = true
            end
        end
    end
end

-----------------------------
-- Global XML Functions
-----------------------------

function ZO_CompanionEquipment_Keyboard_OnInitialize(control)
    COMPANION_EQUIPMENT_KEYBOARD = ZO_CompanionEquipment_Keyboard:New(control)
end

function ZO_CompanionEquipment_Keyboard_NewItemCategory_FlashAnimation_OnUpdate(self, progress)
    COMPANION_EQUIPMENT_KEYBOARD:UpdateCategoryFlashAnimation(self, progress)
end