local DATA_TYPE_QUICKSLOT_ITEM = 1
local DATA_TYPE_COLLECTIBLE_ITEM = 2
local DATA_TYPE_QUICKSLOT_QUEST_ITEM = 3

local STOLEN_ICON_TEXTURE = "EsoUI/Art/Inventory/inventory_stolenItem_icon.dds"

local LIST_ENTRY_HEIGHT = 52

-------------------
--Keyboard Quickslot Screen
-------------------

ZO_Quickslot_Keyboard = ZO_InitializingObject:Subclass()

function ZO_Quickslot_Keyboard:Initialize(control)
    self.control = control
    self.money = self.control:GetNamedChild("InfoBarMoney")

    self.activeTab = self.control:GetNamedChild("TabsActive")
    self.freeSlotsLabel = self.control:GetNamedChild("InfoBarFreeSlots")

    self.list = self.control:GetNamedChild("List")
    ZO_ScrollList_AddDataType(self.list, DATA_TYPE_QUICKSLOT_ITEM, "ZO_PlayerInventorySlot", LIST_ENTRY_HEIGHT, function(control, data) self:SetUpQuickSlot(control, data) end, nil, nil, ZO_InventorySlot_OnPoolReset)
    ZO_ScrollList_AddDataType(self.list, DATA_TYPE_COLLECTIBLE_ITEM, "ZO_CollectionsSlot_Keyboard_Template", LIST_ENTRY_HEIGHT, function(control, data) self:SetUpCollectionSlot(control, data) end, nil, nil, ZO_InventorySlot_OnPoolReset)
    ZO_ScrollList_AddDataType(self.list, DATA_TYPE_QUICKSLOT_QUEST_ITEM, "ZO_PlayerInventorySlot", LIST_ENTRY_HEIGHT, function(control, data) self:SetUpQuestItemSlot(control, data) end, nil, nil, ZO_InventorySlot_OnPoolReset)

    local quickslotFilterTargetDescriptor =
    {
        [BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT] =
        {
            searchFilterList =
            {
                BACKGROUND_LIST_FILTER_TYPE_NAME,
            },
            primaryKeys =
            {
                BAG_BACKPACK,
            }
        },
        [BACKGROUND_LIST_FILTER_TARGET_QUEST_ITEM_ID] =
        {
            searchFilterList =
            {
                BACKGROUND_LIST_FILTER_TYPE_NAME,
            },
            primaryKeys = ZO_FilterTargetDescriptor_GetQuestItemIdList,
        },
        [BACKGROUND_LIST_FILTER_TARGET_COLLECTIBLE_ID] =
        {
            searchFilterList =
            {
                BACKGROUND_LIST_FILTER_TYPE_NAME,
            },
            primaryKeys = function()
                local collectibleIdList = {}
                local NO_CATEGORY_FILTERS = nil
                local dataList = ZO_COLLECTIBLE_DATA_MANAGER:GetAllCollectibleDataObjects(NO_CATEGORY_FILTERS, { ZO_CollectibleData.IsUnlocked, ZO_CollectibleData.IsValidForPlayer, ZO_CollectibleData.IsSlottable })
                for _, data in ipairs(dataList) do
                    table.insert(collectibleIdList, data.collectibleId)
                end
                return collectibleIdList
            end,
        },
    }
    TEXT_SEARCH_MANAGER:SetupContextTextSearch("quickslotTextSearch", quickslotFilterTargetDescriptor)

    self.searchBox = self.control:GetNamedChild("SearchFiltersTextSearchBox");

    local function OnTextSearchTextChanged(editBox)
        TEXT_SEARCH_MANAGER:SetSearchText("quickslotTextSearch", editBox:GetText())
    end

    self.searchBox:SetHandler("OnTextChanged", OnTextSearchTextChanged)

    local SUPPRESS_TEXT_CHANGED_CALLBACK = true
    local function OnListTextFilterComplete()
        if KEYBOARD_QUICKSLOT_FRAGMENT:IsShowing() then
            self.searchBox:SetText(TEXT_SEARCH_MANAGER:GetSearchText("quickslotTextSearch"), SUPPRESS_TEXT_CHANGED_CALLBACK)
            self:UpdateList()
        end
    end

    TEXT_SEARCH_MANAGER:RegisterCallback("UpdateSearchResults", OnListTextFilterComplete)

    self.sortHeadersControl = self.control:GetNamedChild("SortBy")
    self.sortHeaders = ZO_SortHeaderGroup:New(self.sortHeadersControl, true)

    self.wheelControl = self.control:GetNamedChild("QuickSlotCircle")
    local wheelData =
    {
        hotbarCategories = { HOTBAR_CATEGORY_QUICKSLOT_WHEEL },
        numSlots = ACTION_BAR_UTILITY_BAR_SIZE,
        showCategoryLabel = true,
        --Display the accessibility keybinds on the wheel if the setting is enabled
        showKeybinds = ZO_AreTogglableWheelsEnabled,
    }
    self.wheel = ZO_AssignableUtilityWheel_Keyboard:New(self.wheelControl, wheelData)

    self.tabs = self.control:GetNamedChild("Tabs")

    self.quickslotFilters = {}

    self:InsertCollectibleCategories()

    table.insert(self.quickslotFilters, self:CreateNewTabFilterData(ITEMFILTERTYPE_QUEST_QUICKSLOT,
                          GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_QUEST_QUICKSLOT),
                          "EsoUI/Art/Inventory/inventory_tabIcon_quest_up.dds",
                          "EsoUI/Art/Inventory/inventory_tabIcon_quest_down.dds",
                          "EsoUI/Art/Inventory/inventory_tabIcon_quest_over.dds"))

    table.insert(self.quickslotFilters, self:CreateNewTabFilterData(ITEMFILTERTYPE_QUICKSLOT,
                          GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_QUICKSLOT),
                          "EsoUI/Art/Inventory/inventory_tabIcon_items_up.dds",
                          "EsoUI/Art/Inventory/inventory_tabIcon_items_down.dds",
                          "EsoUI/Art/Inventory/inventory_tabIcon_items_over.dds"))

    table.insert(self.quickslotFilters, self:CreateNewTabFilterData(ITEMFILTERTYPE_ALL,
                          GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_ALL),
                          "EsoUI/Art/Inventory/inventory_tabIcon_all_up.dds",
                          "EsoUI/Art/Inventory/inventory_tabIcon_all_down.dds",
                          "EsoUI/Art/Inventory/inventory_tabIcon_all_over.dds"))

    local menuBarData =
    {
        initialButtonAnchorPoint = RIGHT,
        buttonTemplate = "ZO_QuickSlotTab_Keyboard_Template",
        normalSize = 51,
        downSize = 64,
        buttonPadding = -15,
        animationDuration = 180,
    }

    ZO_MenuBar_SetData(self.tabs, menuBarData)

    for _, data in ipairs(self.quickslotFilters) do
        ZO_MenuBar_AddButton(self.tabs, data)
    end

    ZO_MenuBar_SelectDescriptor(self.tabs, ITEMFILTERTYPE_QUICKSLOT)

    local function OnSortHeaderClicked(key, order)
        self.currentFilter.sortKey = key
        self.currentFilter.sortOrder = order
        self:ApplySort()
    end

    self.sortHeaders:RegisterCallback(ZO_SortHeaderGroup.HEADER_CLICKED, OnSortHeaderClicked)
    self.sortHeaders:AddHeadersFromContainer()
    self.sortHeaders:SelectHeaderByKey("name")

    local function RefreshQuickslotWindow()
        if not self.control:IsHidden() then
            self:UpdateList()
            self:UpdateFreeSlots()
        end
    end

    local function OnMoneyUpdated(eventCode, newMoney, oldMoney, reason)
        self:RefreshCurrency(newMoney)
    end

    self:RefreshCurrency(GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER))

    local function HandleInventoryChanged()
        if KEYBOARD_QUICKSLOT_FRAGMENT:IsShowing() then
            RefreshQuickslotWindow()
        end
    end

    local function RefreshSlotLocked(slotIndex, locked)
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        for i = 1, #scrollData do
            local dataEntry = scrollData[i]
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

    local function HandleCooldownUpdates()
        ZO_ScrollList_RefreshVisible(self.list, nil, ZO_InventorySlot_UpdateCooldowns)
    end

    self.control:RegisterForEvent(EVENT_MONEY_UPDATE, OnMoneyUpdated)
    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, HandleInventoryChanged)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, HandleInventoryChanged)
    self.control:RegisterForEvent(EVENT_LEVEL_UPDATE, function(eventCode, unitTag) if unitTag == "player" then HandleInventoryChanged() end end)
    self.control:RegisterForEvent(EVENT_ACTION_SLOTS_ACTIVE_HOTBAR_UPDATED, function() self.wheel:UpdateAllSlots() end)
    self.control:RegisterForEvent(EVENT_INVENTORY_SLOT_LOCKED, HandleInventorySlotLocked)
    self.control:RegisterForEvent(EVENT_INVENTORY_SLOT_UNLOCKED, HandleInventorySlotUnlocked)
    self.control:RegisterForEvent(EVENT_ACTION_UPDATE_COOLDOWNS, HandleCooldownUpdates)

    KEYBOARD_QUICKSLOT_FRAGMENT = ZO_FadeSceneFragment:New(self.control)
    KEYBOARD_QUICKSLOT_FRAGMENT:RegisterCallback("StateChange",  function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWN then
            TEXT_SEARCH_MANAGER:ActivateTextSearch("quickslotTextSearch")
            self:UpdateList()
            self:UpdateFreeSlots()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            TEXT_SEARCH_MANAGER:DeactivateTextSearch("quickslotTextSearch")
        end
    end)

    KEYBOARD_QUICKSLOT_CIRCLE_FRAGMENT = ZO_FadeSceneFragment:New(self.wheelControl)
    KEYBOARD_QUICKSLOT_CIRCLE_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self.wheel:Activate()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self.wheel:Deactivate()
        end
    end)

    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", RefreshQuickslotWindow)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUpdated", RefreshQuickslotWindow)

    SHARED_INVENTORY:RegisterCallback("FullQuestUpdate", RefreshQuickslotWindow)
    SHARED_INVENTORY:RegisterCallback("SingleQuestUpdate", RefreshQuickslotWindow)
end

function ZO_Quickslot_Keyboard:AreQuickSlotsShowing()
    return KEYBOARD_QUICKSLOT_CIRCLE_FRAGMENT:IsShowing()
end

function ZO_Quickslot_Keyboard:ChangeFilter(filterData)
    self.currentFilter = filterData
    self.activeTab:SetText(filterData.activeTabText)
    self:UpdateList()
    
    self.sortHeaders:SelectAndResetSortForKey(filterData.sortKey)

    local isNotItemFilter = self.currentFilter.descriptor ~= ITEMFILTERTYPE_QUICKSLOT
    self.sortHeaders:SetHeaderHiddenForKey("stackSellPrice", isNotItemFilter)
    self.sortHeaders:SetHeaderHiddenForKey("age", isNotItemFilter)
end

function ZO_Quickslot_Keyboard:ShouldAddItemToList(itemData)
    return ZO_IsElementInNumericallyIndexedTable(itemData.filterData, ITEMFILTERTYPE_QUICKSLOT) and TEXT_SEARCH_MANAGER:IsItemInSearchTextResults("quickslotTextSearch", BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, itemData.bagId, itemData.slotIndex)
end

function ZO_Quickslot_Keyboard:ShouldAddQuestItemToList(questItemData)
    return ZO_IsElementInNumericallyIndexedTable(questItemData.filterData, ITEMFILTERTYPE_QUEST_QUICKSLOT) and TEXT_SEARCH_MANAGER:IsItemInSearchTextResults("quickslotTextSearch", BACKGROUND_LIST_FILTER_TARGET_QUEST_ITEM_ID, questItemData.questItemId)
end

local sortKeys =
{
    name = { },
    age = { tiebreaker = "name", isNumeric = true },
    stackSellPrice = { tiebreaker = "name", isNumeric = true },
}

function ZO_Quickslot_Keyboard:SortData()
    local scrollData = ZO_ScrollList_GetDataList(self.list)

    self.sortFunction = self.sortFunction or function(entry1, entry2)
        local sortKey = self.currentFilter.sortKey
        local sortOrder = self.currentFilter.sortOrder

        return ZO_TableOrderingFunction(entry1.data, entry2.data, sortKey, sortKeys, sortOrder)
    end
    table.sort(scrollData, self.sortFunction)
end

function ZO_Quickslot_Keyboard:ApplySort()
    self:SortData()
    ZO_ScrollList_Commit(self.list)
end

function ZO_Quickslot_Keyboard:RefreshCurrency(value)
    ZO_CurrencyControl_SetSimpleCurrency(self.money, CURT_MONEY, value, ZO_KEYBOARD_CURRENCY_OPTIONS)
end

function ZO_Quickslot_Keyboard:ValidateOrClearAllQuickslots()
    for i = 1, ACTION_BAR_UTILITY_BAR_SIZE do
        ZO_UtilityWheelValidateOrClearSlot(i, HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
    end
end

function ZO_Quickslot_Keyboard:UpdateList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ScrollList_Clear(self.list)
    ZO_ScrollList_ResetToTop(self.list)

    local currentFilterType = self.currentFilter.descriptor
    if currentFilterType == ITEMFILTERTYPE_ALL then
        self:AppendItemData(scrollData)
        self:AppendCollectiblesData(scrollData)
        self:AppendQuestItemData(scrollData)
    elseif currentFilterType == ITEMFILTERTYPE_QUICKSLOT then
        self:AppendItemData(scrollData)
    elseif currentFilterType == ITEMFILTERTYPE_COLLECTIBLE then
        local collectibleCategoryData = self.currentFilter.extraInfo
        self:AppendCollectiblesData(scrollData, collectibleCategoryData)
    elseif currentFilterType == ITEMFILTERTYPE_QUEST_QUICKSLOT then
        self:AppendQuestItemData(scrollData)
    end

    self.cachedSearchText = nil

    self:ApplySort()
    self:ValidateOrClearAllQuickslots()
    self.sortHeadersControl:SetHidden(#scrollData == 0)
end

function ZO_Quickslot_Keyboard:AppendItemData(scrollData)
    local bagSlots = GetBagSize(BAG_BACKPACK)
    for slotIndex = 0, bagSlots - 1 do
        local slotData = SHARED_INVENTORY:GenerateSingleSlotData(BAG_BACKPACK, slotIndex)
        if slotData and slotData.stackCount > 0 then
            local itemData =
            {
                iconFile = slotData.iconFile,
                stackCount = slotData.stackCount,
                sellPrice = slotData.sellPrice,
                stackSellPrice = slotData.stackCount * slotData.sellPrice,
                bagId = BAG_BACKPACK,
                slotIndex = slotIndex,
                meetsUsageRequirement = slotData.meetsUsageRequirement,
                locked = slotData.locked,
                functionalQuality = slotData.functionalQuality,
                displayQuality = slotData.displayQuality,
                -- slotData.quality is deprecated, included here for addon backwards compatibility
                quality = slotData.displayQuality,
                slotType = SLOT_TYPE_ITEM,
                filterData = { GetItemFilterTypeInfo(BAG_BACKPACK, slotIndex) },
                age = slotData.age,
                stolen = IsItemStolen(BAG_BACKPACK, slotIndex),
                name = slotData.name or zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(BAG_BACKPACK, slotIndex)),
                isGemmable = slotData.isGemmable,
                searchData =
                {
                    type = ZO_TEXT_SEARCH_TYPE_INVENTORY,
                    bagId = BAG_BACKPACK,
                    slotIndex = slotIndex,
                },
            }

            if self:ShouldAddItemToList(itemData) then
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(DATA_TYPE_QUICKSLOT_ITEM, itemData))
            end
        end
    end
end

function ZO_Quickslot_Keyboard:AppendCollectiblesData(scrollData, collectibleCategoryData)
    local dataObjects
    if collectibleCategoryData then
        dataObjects = collectibleCategoryData:GetAllCollectibleDataObjects({ ZO_CollectibleData.IsUnlocked, ZO_CollectibleData.IsValidForPlayer, ZO_CollectibleData.IsSlottable })
    else
        dataObjects = ZO_COLLECTIBLE_DATA_MANAGER:GetAllCollectibleDataObjects({ ZO_CollectibleCategoryData.IsStandardCategory }, { ZO_CollectibleData.IsUnlocked, ZO_CollectibleData.IsValidForPlayer, ZO_CollectibleData.IsSlottable })
    end

    for _, collectibleData in ipairs(dataObjects) do
        collectibleData.searchData =
        {
            type = ZO_TEXT_SEARCH_TYPE_COLLECTIBLE,
            collectibleId = collectibleData.collectibleId,
        }

        if TEXT_SEARCH_MANAGER:IsItemInSearchTextResults("quickslotTextSearch", BACKGROUND_LIST_FILTER_TARGET_COLLECTIBLE_ID, collectibleData.collectibleId) then
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(DATA_TYPE_COLLECTIBLE_ITEM, collectibleData))
        end
    end
end

function ZO_Quickslot_Keyboard:AppendQuestItemData(scrollData)
    local questCache = SHARED_INVENTORY:GenerateFullQuestCache()
    for _, questItems in pairs(questCache) do
        for _, questItemData in pairs(questItems) do
            if questItemData.toolIndex then
                questItemData.searchData =
                {
                    type = ZO_TEXT_SEARCH_TYPE_QUEST_TOOL,
                    questIndex = questItemData.questIndex,
                    toolIndex = questItemData.toolIndex,
                    index = questItemData.slotIndex,
                }
            else
                questItemData.searchData =
                {
                    type = ZO_TEXT_SEARCH_TYPE_QUEST_ITEM,
                    questIndex = questItemData.questIndex,
                    stepIndex = questItemData.stepIndex,
                    conditionIndex = questItemData.conditionIndex,
                    toolIndex = questItemData.toolIndex,
                    index = questItemData.slotIndex,
                }
            end

            if self:ShouldAddQuestItemToList(questItemData) then
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(DATA_TYPE_QUICKSLOT_QUEST_ITEM, questItemData))
            end
        end
    end
end

local function UpdateNewStatusControl(control, data)
    PLAYER_INVENTORY:UpdateNewStatus(INVENTORY_BACKPACK, data.slotIndex, data.bagId)
end

function ZO_Quickslot_Keyboard:SetUpQuickSlot(control, data)
    -- data.quality is deprecated, included here for addon backwards compatibility
    local displayQuality = data.displayQuality or data.quality
    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, displayQuality)
    local nameControl = GetControl(control, "Name")
    nameControl:SetText(data.name)
    nameControl:SetColor(r, g, b, 1)

    local sellPriceControl = GetControl(control, "SellPrice")
    sellPriceControl:SetHidden(false)
    ZO_CurrencyControl_SetSimpleCurrency(sellPriceControl, CURT_MONEY, data.stackSellPrice, ITEM_SLOT_CURRENCY_OPTIONS)

    local inventorySlot = GetControl(control, "Button")
    ZO_Inventory_BindSlot(inventorySlot, data.slotType, data.slotIndex, data.bagId)
    ZO_PlayerInventorySlot_SetupSlot(control, data.stackCount, data.iconFile, data.meetsUsageRequirement, data.locked)

    local statusControl = GetControl(control, "StatusTexture")
    statusControl:ClearIcons()
    if data.stolen then
        statusControl:AddIcon(STOLEN_ICON_TEXTURE)
    end
    if data.isGemmable then
        statusControl:AddIcon(ZO_Currency_GetPlatformCurrencyIcon(CURT_CROWN_GEMS))
    end
    statusControl:Show()

    UpdateNewStatusControl(control, data)
end

function ZO_Quickslot_Keyboard:SetUpCollectionSlot(control, data)
    control:GetNamedChild("Name"):SetText(data:GetNameWithNickname())
    control:GetNamedChild("ActiveIcon"):SetHidden(not data:IsActive())

    local slot = GetControl(control, "Button")
    slot.collectibleId = data:GetId()
    slot.active = data:IsActive()
    slot.categoryType = data:GetCategoryType()
    slot.inCooldown = false
    slot.cooldown = GetControl(slot, "Cooldown")
    slot.cooldown:SetTexture(data:GetIcon())
    ZO_InventorySlot_SetType(slot, SLOT_TYPE_COLLECTIONS_INVENTORY)
    ZO_ItemSlot_SetupSlotBase(slot, 1, data:GetIcon())
end

function ZO_Quickslot_Keyboard:SetUpQuestItemSlot(rowControl, questItem)
    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_TOOLTIP, ITEM_TOOLTIP_COLOR_QUEST_ITEM_NAME)
    local nameControl = GetControl(rowControl, "Name")
    nameControl:SetText(questItem.name) -- already formatted
    nameControl:SetColor(r, g, b, 1)

    GetControl(rowControl, "SellPrice"):SetHidden(true)

    local inventorySlot = GetControl(rowControl, "Button")
    ZO_InventorySlot_SetType(inventorySlot, SLOT_TYPE_QUEST_ITEM)

    questItem.slotControl = rowControl

    ZO_Inventory_SetupSlot(inventorySlot, questItem.stackCount, questItem.iconFile)
    ZO_Inventory_SetupQuestSlot(inventorySlot, questItem.questIndex, questItem.toolIndex, questItem.stepIndex, questItem.conditionIndex)

    ZO_UpdateStatusControlIcons(rowControl, questItem)
end

function ZO_Quickslot_Keyboard:UpdateFreeSlots()
    local numUsedSlots, numSlots = PLAYER_INVENTORY:GetNumSlots(INVENTORY_BACKPACK)
    if numUsedSlots < numSlots then
        self.freeSlotsLabel:SetText(zo_strformat(SI_INVENTORY_BACKPACK_REMAINING_SPACES, numUsedSlots, numSlots))
    else
        self.freeSlotsLabel:SetText(zo_strformat(SI_INVENTORY_BACKPACK_COMPLETELY_FULL, numUsedSlots, numSlots))
    end
end

function ZO_Quickslot_Keyboard:InsertCollectibleCategories()
    for categoryIndex, categoryData in ZO_COLLECTIBLE_DATA_MANAGER:CategoryIterator() do
        if DoesCollectibleCategoryContainSlottableCollectibles(categoryIndex) then
            local name = categoryData:GetName()
            local normalIcon, pressedIcon, mouseoverIcon = categoryData:GetKeyboardIcons()
            local data = self:CreateNewTabFilterData(ITEMFILTERTYPE_COLLECTIBLE, name, normalIcon, pressedIcon, mouseoverIcon, categoryData)
            table.insert(self.quickslotFilters, data)
        end
    end
end

function ZO_Quickslot_Keyboard:CreateNewTabFilterData(filterType, text, normal, pressed, highlight, extraInfo)
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
        callback = function(tabData) self:ChangeFilter(tabData) end,
    }

    return tabData
end

-------------------
-- Global functions
-------------------

function ZO_QuickSlotTab_Keyboard_FilterButtonOnMouseEnter(self)
    ZO_MenuBarButtonTemplate_OnMouseEnter(self)
    InitializeTooltip(InformationTooltip, self, BOTTOMRIGHT, 0, 32)
    SetTooltipText(InformationTooltip, ZO_MenuBarButtonTemplate_GetData(self).tooltipText)
end

function ZO_QuickSlotTab_Keyboard_FilterButtonOnMouseExit(self)
    ClearTooltip(InformationTooltip)
    ZO_MenuBarButtonTemplate_OnMouseExit(self)
end

function ZO_Quickslot_Keyboard_OnInitialize(control)
    QUICKSLOT_KEYBOARD = ZO_Quickslot_Keyboard:New(control)
end
