local ITEM_BUY_CURRENCY_OPTIONS =
{
    showTooltips = false,
    font = "ZoFontGameShadow",
    iconSide = RIGHT,
}

local MEET_BUY_REQS_FAIL_COLOR = ZO_ColorDef:New(1, 0, 0, 1)
local COMPUTE_HAS_ENOUGH = true

local DATA_TYPE_STORE_ITEM = 1

local STORE_ITEMS = false

-------------------
--Store Manager
-------------------

ZO_StoreManager = ZO_SharedStoreManager:Subclass()

function ZO_StoreManager:New(container)
    local manager = ZO_Object.New(self)
    
    STORE_FRAGMENT = ZO_FadeSceneFragment:New(container)

    STORE_FRAGMENT:RegisterCallback("StateChange",   function(oldState, newState)
                                                    if(newState == SCENE_FRAGMENT_SHOWING) then
                                                        manager:RefreshCurrency()
                                                        manager:GetStoreItems()
                                                        manager:UpdateList()
                                                        manager:UpdateFreeSlots()
                                                    end
                                                end)
    
    manager.container = container

    manager:InitializeTabs()
    manager:InitializeKeybindStripDescriptors()

    manager.currentMoney = 0
    manager.currency1Display = GetControl(container, "InfoBarCurrency1")
    manager.currency2Display = GetControl(container, "InfoBarCurrency2")
    manager.currenyMoneyDisplay = GetControl(container, "InfoBarMoney")
    manager.freeSlotsLabel = GetControl(container, "InfoBarFreeSlots")

    ZO_CurrencyControl_InitializeDisplayTypes(manager.currenyMoneyDisplay, CURT_MONEY)

    manager.activeTab = GetControl(container, "TabsActive")

    manager.multipleDialog = ZO_BuyMultipleDialog
    ZO_Dialogs_RegisterCustomDialog("BUY_MULTIPLE",
    {
        customControl = ZO_BuyMultipleDialog,
        title =
        {
            text = SI_PROMPT_TITLE_BUY_MULTIPLE,
        },
        buttons =
        {
            [1] =
            {
                control = GetControl(manager.multipleDialog, "Purchase"),
                text =  SI_DIALOG_PURCHASE,
                callback =  function(dialog)
                                STORE_WINDOW:BuyMultiplePurchase()
                            end,
            },
        
            [2] =
            {
                control =   GetControl(manager.multipleDialog, "Cancel"),
                text =      SI_DIALOG_CANCEL,
            }
        }
    })

    local function GetBuyMultipleMaximum()
        local entryIndex = manager.multipleDialog.index
        return zo_min(zo_max(GetStoreEntryMaxBuyable(entryIndex), 1), MAX_STORE_WINDOW_STACK_QUANTITY) -- always attempt to let one item be bought, just to show the error; ensure that the quantity can't go above 999
    end

    local spinnerControl = GetControl(ZO_BuyMultipleDialog, "Spinner")
    manager.buyMultipleSpinner = ZO_Spinner:New(spinnerControl, 1, GetBuyMultipleMaximum)
    manager.buyMultipleSpinner:RegisterCallback("OnValueChanged", function() manager:RefreshBuyMultiple() end)

    manager.list = GetControl(container, "List")
    ZO_ScrollList_AddDataType(manager.list, DATA_TYPE_STORE_ITEM, "ZO_PlayerInventorySlot", 52, function(control, data) manager:SetUpBuySlot(control, data) end, nil, nil, ZO_InventorySlot_OnPoolReset)

    manager.landingArea = GetControl(manager.list, "SellToVendorArea")

    manager.sortHeaders = ZO_SortHeaderGroup:New(container:GetNamedChild("SortBy"), true)

    manager.sortOrder = ZO_SORT_ORDER_UP
    manager.sortKey = "name"

    local function OnSortHeaderClicked(key, order)
        manager.sortKey = key
        manager.sortOrder = order
        manager:ApplySort()
    end

    manager.sortHeaders:RegisterCallback(ZO_SortHeaderGroup.HEADER_CLICKED, OnSortHeaderClicked)
    manager.sortHeaders:AddHeadersFromContainer()
    manager.sortHeaders:SelectHeaderByKey("name", ZO_SortHeaderGroup.SUPPRESS_CALLBACKS)

    manager.tabs = GetControl(container, "Tabs")

    local typicalHiddenColumns =
    {
        ["statValue"] = true,
    }

    local gearHiddenColumns =
    {
        -- Don't hide anything!
    }

    local function CreateNewTabFilterData(filterType, normal, pressed, highlight, hiddenColumns)
        local filterString = GetString("SI_ITEMFILTERTYPE", filterType)

        local tabData =
        {
            -- Custom data
            filterType = filterType,
            hiddenColumns = hiddenColumns,
            activeTabText = filterString,
            tooltipText = filterString,

            -- Menu bar data
            descriptor = filterType,
            normal = normal,
            pressed = pressed,
            highlight = highlight,
            callback = function(tabData) manager:ChangeFilter(tabData) end,
        }

        return tabData
    end

    manager.storeFilters =
    {
        CreateNewTabFilterData(ITEMFILTERTYPE_MISCELLANEOUS, "EsoUI/Art/Inventory/inventory_tabIcon_misc_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_misc_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_misc_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_CRAFTING, "EsoUI/Art/Inventory/inventory_tabIcon_crafting_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_crafting_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_crafting_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_CONSUMABLE, "EsoUI/Art/Inventory/inventory_tabIcon_consumables_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_consumables_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_consumables_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_ARMOR, "EsoUI/Art/Inventory/inventory_tabIcon_armor_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_over.dds", gearHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_WEAPONS, "EsoUI/Art/Inventory/inventory_tabIcon_weapons_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_over.dds", gearHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_COLLECTIBLE, "EsoUI/Art/MainMenu/menuBar_collections_up.dds", "EsoUI/Art/MainMenu/menuBar_collections_down.dds", "EsoUI/Art/MainMenu/menuBar_collections_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_ALL, "EsoUI/Art/Inventory/inventory_tabIcon_all_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_all_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_all_over.dds", typicalHiddenColumns),
    }

    local menuBarData =
    {
        initialButtonAnchorPoint = RIGHT,
        buttonTemplate = "ZO_StoreTab",
        normalSize = 51,
        downSize = 64,
        buttonPadding = -15,
        animationDuration = 180,
    }

    ZO_MenuBar_SetData(manager.tabs, menuBarData)

    manager.currentFilter = ITEMFILTERTYPE_ALL
    manager.hiddenColumns = typicalHiddenColumns

    local function ShowStoreWindow()
		if not IsInGamepadPreferredMode() then
			SCENE_MANAGER:Show("store")
		end
    end

    local function CloseStoreWindow()
        if not IsInGamepadPreferredMode() then
            -- Ensure that all dialogs related to the store also close when interaction ends
            ZO_Dialogs_ReleaseDialog("REPAIR_ALL")
            ZO_Dialogs_ReleaseDialog("BUY_MULTIPLE")
            ZO_Dialogs_ReleaseDialog("SELL_ALL_JUNK")

            SCENE_MANAGER:Hide("store")
        end
    end

    local function RefreshStoreWindow()
        if not STORE_FRAGMENT:IsHidden() then
            manager:RefreshCurrency()

            manager:GetStoreItems()
            manager:UpdateList()
        end
    end

    local function OnInventoryUpdated()
        if not STORE_FRAGMENT:IsHidden() then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(manager.keybindStripDescriptor)

            manager:UpdateFreeSlots()
        end
    end

    local OnBuySuccess = function(...)
        if not container:IsControlHidden() then
            ZO_StoreManager_OnPurchased(...)
        end
    end

    local function HandleCursorPickup(eventCode, cursorType)
        if(cursorType == MOUSE_CONTENT_INVENTORY_ITEM) then
            ZO_InventoryLandingArea_SetHidden(manager.landingArea, false, SI_INVENTORY_LANDING_AREA_SELL_ITEM)
        end
    end

    local function HandleCursorCleared(eventCode, oldCursorType)
        ZO_InventoryLandingArea_SetHidden(manager.landingArea, true)
    end

    local storeScene = ZO_InteractScene:New("store", SCENE_MANAGER, STORE_INTERACTION)
    storeScene:RegisterCallback("StateChange",   function(oldState, newState)
                                                    if(newState == SCENE_SHOWING) then
                                                        manager:InitializeStore()
                                                    elseif(newState == SCENE_HIDDEN) then
                                                        ZO_InventorySlot_RemoveMouseOverKeybinds()
                                                        KEYBIND_STRIP:RemoveKeybindButtonGroup(manager.keybindStripDescriptor)
                                                        manager.modeBar:Clear()

                                                        if(GetCursorContentType() == MOUSE_CONTENT_STORE_ITEM) then
                                                            ClearCursor()
                                                        end
                                                    end
                                                end)

    container:RegisterForEvent(EVENT_OPEN_STORE, ShowStoreWindow)
    container:RegisterForEvent(EVENT_CLOSE_STORE, CloseStoreWindow)
    container:RegisterForEvent(EVENT_MONEY_UPDATE, RefreshStoreWindow)
    container:RegisterForEvent(EVENT_BUY_RECEIPT, OnBuySuccess)
    container:RegisterForEvent(EVENT_ALLIANCE_POINT_UPDATE, RefreshStoreWindow)
    container:RegisterForEvent(EVENT_TELVAR_STONE_UPDATE, RefreshStoreWindow)
    container:RegisterForEvent(EVENT_WRIT_VOUCHER_UPDATE, RefreshStoreWindow)
    container:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, OnInventoryUpdated)
    container:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventoryUpdated)
    container:RegisterForEvent(EVENT_CURSOR_PICKUP, HandleCursorPickup)
    container:RegisterForEvent(EVENT_CURSOR_DROPPED, HandleCursorCleared)
    container:RegisterForEvent(EVENT_COLLECTION_UPDATED, RefreshStoreWindow)
    container:RegisterForEvent(EVENT_COLLECTIBLE_UPDATED, RefreshStoreWindow)

    local function OnItemRepaired(bagId, slotIndex)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(manager.keybindStripDescriptor)
    end

    SHARED_INVENTORY:RegisterCallback("ItemRepaired", OnItemRepaired)

    return manager
end

function ZO_StoreManager:InitializeStore(overrideMode)
	ZO_SharedStoreManager.InitializeStore(self)

    self.windowMode = overrideMode or ZO_STORE_WINDOW_MODE_NORMAL

    self:RebuildTabs()

    if IsStoreEmpty() then
        self.modeBar:SelectFragment(SI_STORE_MODE_SELL)
    elseif self.windowMode == ZO_STORE_WINDOW_MODE_NORMAL then
        self.modeBar:SelectFragment(SI_STORE_MODE_BUY)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    end

    ZO_ScrollList_ResetToTop(self.list)

    self:RefreshCurrency()
    self:GetStoreItems()
    self:UpdateFilters()
    self:UpdateList(STORE_ITEMS)
    self:UpdateFreeSlots()
end

function ZO_StoreManager:InitializeTabs()
    local function CreateButtonData(normal, pressed, highlight)
        return {
            normal = normal,
            pressed = pressed,
            highlight = highlight,
        }
    end
    
    self.stackAllButton =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_ITEM_ACTION_STACK_ALL),
            keybind = "UI_SHORTCUT_STACK_ALL",
            callback = function()
                StackBag(BAG_BACKPACK)
            end,
        }
    }

    self.modeBar = ZO_SceneFragmentBar:New(ZO_StoreWindowMenuBar)

    --Buy Button
    self.buyButtonData = CreateButtonData("EsoUI/Art/Vendor/vendor_tabIcon_buy_up.dds",
                                            "EsoUI/Art/Vendor/vendor_tabIcon_buy_down.dds",
                                            "EsoUI/Art/Vendor/vendor_tabIcon_buy_over.dds")

    --Sell Button
    self.sellButtonData = CreateButtonData("EsoUI/Art/Vendor/vendor_tabIcon_sell_up.dds",
                                            "EsoUI/Art/Vendor/vendor_tabIcon_sell_down.dds",
                                            "EsoUI/Art/Vendor/vendor_tabIcon_sell_over.dds")

    --Buy Back Button
    self.buyBackButtonData = CreateButtonData("EsoUI/Art/Vendor/vendor_tabIcon_buyBack_up.dds",
                                               "EsoUI/Art/Vendor/vendor_tabIcon_buyBack_down.dds",
                                               "EsoUI/Art/Vendor/vendor_tabIcon_buyBack_over.dds")

    --Repair Button
    self.repairButtonData = CreateButtonData("EsoUI/Art/Vendor/vendor_tabIcon_repair_up.dds",
                                                "EsoUI/Art/Vendor/vendor_tabIcon_repair_down.dds",
                                                "EsoUI/Art/Vendor/vendor_tabIcon_repair_over.dds")
end

function ZO_StoreManager:RebuildTabs()
    self.modeBar:RemoveAll()

    if not IsStoreEmpty() then
        self.modeBar:Add(SI_STORE_MODE_BUY, { STORE_FRAGMENT }, self.buyButtonData)
    end
    self.modeBar:Add(SI_STORE_MODE_SELL, { INVENTORY_FRAGMENT, BACKPACK_STORE_LAYOUT_FRAGMENT }, self.sellButtonData, self.stackAllButton)
    self.modeBar:Add(SI_STORE_MODE_BUY_BACK, { BUY_BACK_FRAGMENT }, self.buyBackButtonData)
    if CanStoreRepair() then
        self.modeBar:Add(SI_STORE_MODE_REPAIR, { REPAIR_FRAGMENT }, self.repairButtonData)
    end
end

do
    local DONT_COUNT_STOLEN_ITEMS = true
    function ZO_StoreManager:InitializeKeybindStripDescriptors()
        self.keybindStripDescriptor =
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,

            -- Repair All
            {
                name = function()
                    local goldIcon = zo_iconFormat("EsoUI/Art/currency/currency_gold.dds", 24, 24)
                    local cost = GetRepairAllCost()
                    if GetCarriedCurrencyAmount(CURT_MONEY) >= cost then
                        return zo_strformat(SI_REPAIR_ALL_KEYBIND_TEXT, ZO_CurrencyControl_FormatCurrency(cost), goldIcon)
                    end
                    return zo_strformat(SI_REPAIR_ALL_KEYBIND_TEXT, ZO_ERROR_COLOR:Colorize(ZO_CurrencyControl_FormatCurrency(cost)), goldIcon)
                end,
                keybind = "UI_SHORTCUT_SECONDARY",
                visible = function() return CanStoreRepair() and GetRepairAllCost() > 0 end,
                callback = function()
                    ZO_Dialogs_ShowDialog("REPAIR_ALL", {cost = GetRepairAllCost()})
                end,
            },

            -- Sell All Junk
            {
                name = GetString(SI_SELL_ALL_JUNK_KEYBIND_TEXT),
                keybind = "UI_SHORTCUT_NEGATIVE",

                visible =   function()
                                return HasAnyJunk(BAG_BACKPACK, DONT_COUNT_STOLEN_ITEMS)
                            end,
                callback =  function()
                                ZO_Dialogs_ShowDialog("SELL_ALL_JUNK")
                            end,
            },
        }
    end
end

function ZO_StoreManager:UpdateFreeSlots()
    if self.windowMode ~= ZO_STORE_WINDOW_MODE_STABLE then
        local numUsedSlots, numSlots = PLAYER_INVENTORY:GetNumSlots(INVENTORY_BACKPACK)
        if self.numUsedSlots ~= numUsedSlots or self.numSlots ~= numSlots then
            self.numUsedSlots = numUsedSlots
            self.numSlots = numSlots
            if numUsedSlots < numSlots then
                self.freeSlotsLabel:SetText(zo_strformat(SI_INVENTORY_BACKPACK_REMAINING_SPACES, numUsedSlots, numSlots))
            else
                self.freeSlotsLabel:SetText(zo_strformat(SI_INVENTORY_BACKPACK_COMPLETELY_FULL, numUsedSlots, numSlots))
            end
        end
    end
end

local filterTypeToValueColumnName =
{
    [ITEMFILTERTYPE_ARMOR] = SI_INVENTORY_SORT_TYPE_ARMOR,
    [ITEMFILTERTYPE_WEAPONS] = SI_INVENTORY_SORT_TYPE_POWER,
}

function ZO_StoreManager:UpdateColumnText()
    self.sortHeaders:SetHeaderNameForKey("statValue", GetString(filterTypeToValueColumnName[self.currentFilter]))
end

function ZO_StoreManager:ChangeFilter(filterData)
    self.currentFilter = filterData.filterType
    self.hiddenColumns = filterData.hiddenColumns

    self.activeTab:SetText(filterData.activeTabText)

    self:UpdateColumnText()

    -- Manage hiding columns that show/hide depending on the current filter.  If the sort was on a column that becomes hidden
    -- then the sort needs to pick a new column.  Currently this always falls back to the name key.
    if(self.sortHeaders) then
        self.sortHeaders:SetHeadersHiddenFromKeyList(self.hiddenColumns, true)

        if(self.hiddenColumns[self.sortKey]) then
            -- User wanted to sort by a column that's gone!
            -- Fallback to name.
            self.sortHeaders:SelectHeaderByKey("name")
        end
    end

    --Hide inventory capacity for collectibles since they don't take up space
    self.freeSlotsLabel:SetHidden(self.currentFilter == ITEMFILTERTYPE_COLLECTIBLE)

    self:UpdateList()
end

function ZO_StoreManager:ShouldAddItemToList(itemData)
    if(self.currentFilter == ITEMFILTERTYPE_ALL) then return true end

    for i = 1, #itemData.filterData do
        if(itemData.filterData[i] == self.currentFilter) then
            return true
        end
    end

    return false
end

local sortKeys =
{
    name = { },
    stackBuyPrice = { tiebreaker = "stackBuyPriceCurrency1", isNumeric = true },
    stackBuyPriceCurrency1 = { tiebreaker = "stackBuyPriceCurrency2", isNumeric = true },
    stackBuyPriceCurrency2 = { tiebreaker = "name", isNumeric = true },
    statValue = { tiebreaker = "name", isNumeric = true },
}

function ZO_StoreManager:SortData()
    local scrollData = ZO_ScrollList_GetDataList(self.list)

    self.sortFunction = self.sortFunction or function(entry1, entry2)
        return ZO_TableOrderingFunction(entry1.data, entry2.data, self.sortKey, sortKeys, self.sortOrder)
    end

    table.sort(scrollData, self.sortFunction)
end

function ZO_StoreManager:ApplySort()
    self:SortData()
    ZO_ScrollList_Commit(self.list)
end

function ZO_StoreManager:SetCurrencyControl(currencyType, currencyValue, currencyOptions)
	local control = (not self.currency1Display.isInUse and self.currency1Display) or 
					(not self.currency2Display.isInUse and self.currency2Display) or nil

	if control then
        ZO_CurrencyControl_SetSimpleCurrency(control, currencyType, currencyValue, currencyOptions)
        control:SetHidden(false)
        control.isInUse = true
	end
end

function ZO_StoreManager:RefreshCurrency()
	ZO_SharedStoreManager.RefreshCurrency(self)

    local repairAllCost = GetRepairAllCost()
    local gold = (self.storeUsesMoney or repairAllCost > 0) and self.currentMoney or 0

	ZO_CurrencyControl_SetCurrencyData(self.currenyMoneyDisplay, CURT_MONEY, gold, self.storeUsesMoney)
    ZO_CurrencyControl_SetCurrency(self.currenyMoneyDisplay, ZO_KEYBOARD_CARRIED_CURRENCY_OPTIONS)

	-- We're laying out the player alternate currency labels this way to ensure that we never display more than two labels, even if 
	-- more than two are applicable to this store, and to ensure that they maintain a consistent priority
	self.currency1Display:SetHidden(true)
    self.currency1Display.isInUse = false

	self.currency2Display:SetHidden(true)
    self.currency2Display.isInUse = false
	
	if self.storeUsesAP then
		self:SetCurrencyControl(CURT_ALLIANCE_POINTS, self.currentAP or 0, ZO_ALTERNATE_CURRENCY_OPTIONS)
	end

	if self.storeUsesTelvarStones then
		self:SetCurrencyControl(CURT_TELVAR_STONES, self.currentTelvarStones or 0, ZO_KEYBOARD_CARRIED_TELVAR_OPTIONS)
	end 

	if self.storeUsesWritVouchers then
		self:SetCurrencyControl(CURT_WRIT_VOUCHERS, self.currentWritVouchers or 0, ZO_KEYBOARD_CARRIED_WRIT_VOUCHER_OPTIONS)
	end 

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_StoreManager:UpdateFilters()
    ZO_MenuBar_ClearButtons(self.tabs)

    --The last filter added is the farthest left, so to the player it should be "first"
    local lastFilter
    for _, data in ipairs(self.storeFilters) do
        if (data.filterType == ITEMFILTERTYPE_ALL and self.multipleFilters) or self.usedFilterTypes[data.filterType] then
            ZO_MenuBar_AddButton(self.tabs, data)
            lastFilter = data.filterType
        end
    end

    if lastFilter then
        ZO_MenuBar_SelectDescriptor(self.tabs, lastFilter)
    end
end

function ZO_StoreManager:GetStoreItems()
	self.items, self.usedFilterTypes = ZO_StoreManager_GetStoreItems()
    self.multipleFilters = NonContiguousCount(self.usedFilterTypes) > 1
end

function ZO_StoreManager:UpdateList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ScrollList_Clear(self.list)
    
    for index = 1, #self.items do
        local itemData = self.items[index]

        if(self:ShouldAddItemToList(itemData))
        then
            scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(DATA_TYPE_STORE_ITEM, itemData)
        end
    end

    self:ApplySort()
end

function ZO_StoreManager:UpdateStatValueControl(control, data)
    local statControl = GetControl(control, "StatValue")

    if(statControl) then
        local showStatColumn = not self.hiddenColumns["statValue"]
        statControl:SetText((showStatColumn and (data.statValue ~= nil) and (data.statValue > 0)) and tostring(data.statValue) or "")
    end
end

function ZO_StoreManager:SetUpBuySlot(control, data)
    local newStatusControl = GetControl(control, "Status")
    local slotControl = GetControl(control, "Button")
    local iconControl = GetControl(control, "ButtonIcon")
    local quantityControl = GetControl(control, "ButtonStackCount")
    local nameControl = GetControl(control, "Name")
    local priceControl = GetControl(control, "SellPrice")

    newStatusControl:SetHidden(true)

    -- Set info about what slot this is, on the top level slot control
    ZO_InventorySlot_SetType(slotControl, SLOT_TYPE_STORE_BUY)
    local slotIndex = data.slotIndex
    slotControl.index = slotIndex
    slotControl.moneyCost = data.stackBuyPrice
    slotControl.specialCurrencyQuantity1 = data.currencyQuantity1
    slotControl.specialCurrencyQuantity2 = data.currencyQuantity2
    slotControl.specialCurrencyType1 = data.currencyType1
    slotControl.specialCurrencyType2 = data.currencyType2
    slotControl.isCollectible = data.filterData[1] == ITEMFILTERTYPE_COLLECTIBLE
    slotControl.isUnique = data.isUnique

    ZO_InventorySlot_SetType(control, SLOT_TYPE_STORE_BUY)
    control.index = slotIndex
    control.moneyCost = data.stackBuyPrice

    local meetsReqs = data.meetsRequirementsToBuy and data.meetsRequirementsToEquip
    local isLocked = false
    if slotControl.isCollectible then
        isLocked = select(2, GetStoreCollectibleInfo(slotIndex))
    end
    slotControl.locked = isLocked
    ZO_ItemSlot_SetupSlotBase(slotControl, data.stack, data.icon, meetsReqs)

    nameControl:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, data.name))
    if data.meetsRequirementsToBuy then
        if data.questNameColor then
            nameControl:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_TOOLTIP, ITEM_TOOLTIP_COLOR_QUEST_ITEM_NAME))
        elseif slotControl.isCollectible then
            nameControl:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        else
            nameControl:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, data.quality))
        end
    else
        nameControl:SetColor(MEET_BUY_REQS_FAIL_COLOR:UnpackRGBA())
    end
    ZO_PlayerInventorySlot_SetupUsableAndLockedColor(control, meetsReqs, isLocked)

    ZO_CurrencyControl_InitializeDisplayTypes(priceControl, CURT_MONEY, CURT_ALLIANCE_POINTS, CURT_TELVAR_STONES, CURT_WRIT_VOUCHERS)

    local currencyType1 = data.currencyType1
    local currencyType2 = data.currencyType2

    ZO_CurrencyControl_SetCurrencyData(priceControl, CURT_MONEY, data.stackBuyPrice, CURRENCY_DONT_SHOW_ALL, not self:HasEnoughCurrencyToBuyItem(CURT_MONEY, data.stackBuyPrice))
    ZO_CurrencyControl_SetCurrencyData(priceControl, currencyType1, data.currencyQuantity1, CURRENCY_DONT_SHOW_ALL, not self:HasEnoughCurrencyToBuyItem(currencyType1, data.stackBuyPriceCurrency1), data.slotIndex, 1)
    ZO_CurrencyControl_SetCurrencyData(priceControl, currencyType2, data.currencyQuantity2, CURRENCY_DONT_SHOW_ALL, not self:HasEnoughCurrencyToBuyItem(currencyType2, data.stackBuyPriceCurrency2), data.slotIndex, 2)

    ZO_CurrencyControl_SetCurrency(priceControl, ITEM_BUY_CURRENCY_OPTIONS)

    self:UpdateStatValueControl(control, data)
end

function ZO_StoreManager:HasEnoughCurrencyToBuyItem(currencyType, itemCost)
    if currencyType == CURT_MONEY then
        return self.currentMoney >= itemCost
    elseif currencyType == CURT_ALLIANCE_POINTS then
        return self.currentAP >= itemCost
    elseif currencyType == CURT_TELVAR_STONES then
        return self.currentTelvarStones >= itemCost
	elseif currencyType == CURT_WRIT_VOUCHERS then
        return self.currentWritVouchers >= itemCost
    end

    return false
end

function ZO_StoreManager:OpenBuyMultiple(entryIndex)
    self.multipleDialog.index = entryIndex
    self.buyMultipleSpinner:SetValue(1, true)
    ZO_Dialogs_ShowDialog("BUY_MULTIPLE")
end

function ZO_StoreManager:BuyMultiplePurchase()
    local storeItemId = self.multipleDialog.index

    local quantity = self.buyMultipleSpinner:GetValue()
    if quantity ~= 0 then
        BuyStoreItem(storeItemId, quantity)
    end
end

function ZO_StoreManager:RefreshBuyMultiple()
    local quantity = self.buyMultipleSpinner:GetValue()

    local entryIndex = self.multipleDialog.index

    local slotControl = GetControl(self.multipleDialog, "Slot")
    local iconControl = GetControl(self.multipleDialog, "SlotIcon")
    local quantityControl = GetControl(self.multipleDialog, "SlotStackCount")
    local currencyControl = GetControl(self.multipleDialog, "Currency")

    local icon, name, stack, price, _, meetsRequirementsToBuy, meetsRequirementsToEquip, _, _, currencyType1, currencyQuantity1,
            currencyType2, currencyQuantity2 = GetStoreEntryInfo(entryIndex)

    -- Set info about what slot this is, on the top level slot control
    ZO_InventorySlot_SetType(slotControl, SLOT_TYPE_BUY_MULTIPLE)
    slotControl.index = entryIndex

    -- Fill in the rest of the controls.
    iconControl:SetTexture(icon)
    if stack ~= 1 then
        quantityControl:SetText(stack)
        quantityControl:SetHidden(false)
    else
        quantityControl:SetHidden(true)
    end
    ZO_ItemSlot_SetupUsableAndLockedColor(slotControl, meetsRequirementsToBuy and meetsRequirementsToEquip)

    ZO_CurrencyControl_InitializeDisplayTypes(currencyControl, CURT_MONEY, CURT_ALLIANCE_POINTS, CURT_TELVAR_STONES, CURT_WRIT_VOUCHERS)

    local total = quantity * price
    local type1Total = quantity * currencyQuantity1
    local type2Total = quantity * currencyQuantity2

    ZO_CurrencyControl_SetCurrencyData(currencyControl, CURT_MONEY, total, CURRENCY_DONT_SHOW_ALL, not self:HasEnoughCurrencyToBuyItem(CURT_MONEY, total))
    ZO_CurrencyControl_SetCurrencyData(currencyControl, currencyType1, type1Total, CURRENCY_DONT_SHOW_ALL, not self:HasEnoughCurrencyToBuyItem(currencyType1, type1Total), entryIndex, 1)
    ZO_CurrencyControl_SetCurrencyData(currencyControl, currencyType2, type2Total, CURRENCY_DONT_SHOW_ALL, not self:HasEnoughCurrencyToBuyItem(currencyType2, type2Total), entryIndex, 2)

    ZO_CurrencyControl_SetCurrency(currencyControl, ITEM_BUY_CURRENCY_OPTIONS)
end

function ZO_StoreManager:GetWindowMode()
    return self.windowMode
end

-------------------
-- Global functions
-------------------

function ZO_BuyMultiple_OpenBuyMultiple(entryIndex)
    STORE_WINDOW:OpenBuyMultiple(entryIndex)
end

function ZO_Store_OnEntryMouseEnter(control)
    ZO_InventorySlot_OnMouseEnter(control)
end

function ZO_Store_OnEntryMouseExit(control)
    ZO_InventorySlot_OnMouseExit(control)
end

function ZO_Store_FilterButtonOnMouseEnter(self)
    ZO_MenuBarButtonTemplate_OnMouseEnter(self)
    InitializeTooltip(InformationTooltip, self, BOTTOM, 0, -10)
    SetTooltipText(InformationTooltip, ZO_MenuBarButtonTemplate_GetData(self).tooltipText)
end

function ZO_Store_FilterButtonOnMouseExit(self)
    ClearTooltip(InformationTooltip)
    ZO_MenuBarButtonTemplate_OnMouseExit(self)
end

function ZO_Store_OnMouseUp(upInside)
    if(upInside and GetCursorContentType() ~= MOUSE_CONTENT_EMPTY) then
        PlaceInStoreWindow()
    end
end

function ZO_Store_OnReceiveDrag()
    if(GetCursorContentType() ~= MOUSE_CONTENT_EMPTY) then
        PlaceInStoreWindow()
    end
end

function ZO_Store_IsShopping()
    return GetInteractionType() == INTERACTION_VENDOR
end

function ZO_Store_OnInitialize(control)
    STORE_WINDOW = ZO_StoreManager:New(control)
end
