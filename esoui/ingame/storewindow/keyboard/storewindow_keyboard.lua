local ITEM_BUY_CURRENCY_OPTIONS =
{
    showTooltips = false,
    font = "ZoFontGameShadow",
    iconSide = RIGHT,
}

local MEET_BUY_REQS_FAIL_COLOR = ZO_ColorDef:New(1, 0, 0, 1)

local DATA_TYPE_STORE_ITEM = 1

local STORE_ITEMS = false

-------------------
--Store Manager
-------------------

ZO_StoreManager = ZO_SharedStoreManager:Subclass()

function ZO_StoreManager:New(...)
    return ZO_SharedStoreManager.New(self, ...)
end

function ZO_StoreManager:Initialize(control)
    ZO_SharedStoreManager.Initialize(self, control)

    STORE_FRAGMENT = ZO_FadeSceneFragment:New(control)

    STORE_FRAGMENT:RegisterCallback("StateChange",   function(oldState, newState)
                                                    if newState == SCENE_FRAGMENT_SHOWING then
                                                        self:RefreshCurrency()
                                                        self:SetupDefaultSort()
                                                        self:GetStoreItems()
                                                        self:UpdateList()
                                                        self:UpdateFreeSlots()
                                                        if self.windowMode == ZO_STORE_WINDOW_MODE_STABLE then
                                                            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
                                                        end
                                                    elseif newState == SCENE_FRAGMENT_HIDING then
                                                        if ITEM_PREVIEW_KEYBOARD:IsInteractionCameraPreviewEnabled() then
                                                            self:TogglePreviewMode()
                                                        end

                                                        if self.windowMode == ZO_STORE_WINDOW_MODE_STABLE then
                                                            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
                                                        end
                                                    end
                                                end)

    self:InitializeTabs()
    self:InitializeKeybindStripDescriptors()

    self.currency1Display = GetControl(control, "InfoBarCurrency1")
    self.currency2Display = GetControl(control, "InfoBarCurrency2")
    self.currencyMoneyDisplay = GetControl(control, "InfoBarMoney")
    self.freeSlotsLabel = GetControl(control, "InfoBarFreeSlots")

    ZO_CurrencyControl_InitializeDisplayTypes(self.currencyMoneyDisplay, CURT_MONEY)

    self.activeTab = GetControl(control, "TabsActive")

    self.multipleDialog = ZO_BuyMultipleDialog
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
                control = GetControl(self.multipleDialog, "Purchase"),
                text =  SI_DIALOG_PURCHASE,
                callback =  function(dialog)
                                STORE_WINDOW:BuyMultiplePurchase()
                            end,
            },
        
            [2] =
            {
                control =   GetControl(self.multipleDialog, "Cancel"),
                text =      SI_DIALOG_CANCEL,
            }
        }
    })

    local function GetBuyMultipleMaximum()
        local entryIndex = self.multipleDialog.index
        return zo_min(zo_max(GetStoreEntryMaxBuyable(entryIndex), 1), MAX_STORE_WINDOW_STACK_QUANTITY) -- always attempt to let one item be bought, just to show the error; ensure that the quantity can't go above 999
    end

    local spinnerControl = GetControl(ZO_BuyMultipleDialog, "Spinner")
    self.buyMultipleSpinner = ZO_Spinner:New(spinnerControl, 1, GetBuyMultipleMaximum)
    self.buyMultipleSpinner:RegisterCallback("OnValueChanged", function() self:RefreshBuyMultiple() end)

    self.list = GetControl(control, "List")
    ZO_ScrollList_AddDataType(self.list, DATA_TYPE_STORE_ITEM, "ZO_StoreEntrySlot", 52, function(control, data) self:SetUpBuySlot(control, data) end, nil, nil, ZO_InventorySlot_OnPoolReset)

    self.landingArea = GetControl(self.list, "SellToVendorArea")

    self.sortHeaderGroup = ZO_SortHeaderGroup:New(control:GetNamedChild("SortBy"), true)
    self.sortHeaderGroup:SelectHeaderByKey("name")

    local function OnSortHeaderClicked(key, order)
        self:ApplySort()
    end

    self.sortHeaderGroup:RegisterCallback(ZO_SortHeaderGroup.HEADER_CLICKED, OnSortHeaderClicked)
    self.sortHeaderGroup:AddHeadersFromContainer()
    -- We are using shared sort headers from the inventory, but store sorts its entries by value
    -- differently, so we need to swap out the sort key
    self.sortHeaderGroup:ReplaceKey("stackSellPrice", "stackBuyPrice")
    self.sortHeaderGroup:SelectHeaderByKey("name", ZO_SortHeaderGroup.SUPPRESS_CALLBACKS)

    self.tabs = GetControl(control, "Tabs")

    local typicalHiddenColumns =
    {
        ["statusSortOrder"] = true,
        ["traitInformationSortOrder"] = true,
    }

    local gearHiddenColumns =
    {
        ["statusSortOrder"] = true,
        ["traitInformationSortOrder"] = true,
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
            callback = function(tabData) self:ChangeFilter(tabData) end,
        }

        return tabData
    end

    self.storeFilters =
    {
        CreateNewTabFilterData(ITEMFILTERTYPE_MISCELLANEOUS, "EsoUI/Art/Inventory/inventory_tabIcon_misc_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_misc_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_misc_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_FURNISHING, "EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_up.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_down.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_CRAFTING, "EsoUI/Art/Inventory/inventory_tabIcon_crafting_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_crafting_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_crafting_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_CONSUMABLE, "EsoUI/Art/Inventory/inventory_tabIcon_consumables_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_consumables_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_consumables_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_JEWELRY, "EsoUI/Art/Crafting/jewelry_tabIcon_icon_up.dds", "EsoUI/Art/Crafting/jewelry_tabIcon_down.dds", "EsoUI/Art/Crafting/jewelry_tabIcon_icon_over.dds", gearHiddenColumns),
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

    ZO_MenuBar_SetData(self.tabs, menuBarData)

    self.currentFilter = ITEMFILTERTYPE_ALL
    self.hiddenColumns = typicalHiddenColumns

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
            self:RefreshCurrency()

            self:GetStoreItems()
            self:UpdateList()
        end
    end

    local function OnInventoryUpdated()
        if not STORE_FRAGMENT:IsHidden() then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

            self:UpdateFreeSlots()
        elseif not INVENTORY_FRAGMENT:IsHidden() then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

            self.modeBar:UpdateActiveKeybind()
        end
    end

    local OnBuySuccess = function(...)
        if not control:IsControlHidden() then
            ZO_StoreManager_OnPurchased(...)
        end
    end

    local function HandleCursorPickup(eventCode, cursorType)
        if cursorType == MOUSE_CONTENT_INVENTORY_ITEM then
            ZO_InventoryLandingArea_SetHidden(self.landingArea, false, SI_INVENTORY_LANDING_AREA_SELL_ITEM)
        end
    end

    local function HandleCursorCleared(eventCode, oldCursorType)
        ZO_InventoryLandingArea_SetHidden(self.landingArea, true)
    end

    local storeScene = ZO_InteractScene:New("store", SCENE_MANAGER, STORE_INTERACTION)
    storeScene:RegisterCallback("StateChange",   function(oldState, newState)
                                                    if newState == SCENE_SHOWING then
                                                        self:InitializeStore()
                                                        PLAYER_INVENTORY:SelectAndChangeSort(INVENTORY_BACKPACK, ITEMFILTERTYPE_ALL, "sellInformationSortOrder", ZO_SORT_ORDER_UP)
                                                    elseif newState == SCENE_HIDDEN then
                                                        ZO_InventorySlot_RemoveMouseOverKeybinds()
                                                        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
                                                        self.modeBar:Clear()

                                                        PLAYER_INVENTORY:SelectAndChangeSort(INVENTORY_BACKPACK, ITEMFILTERTYPE_ALL, "statusSortOrder", ZO_SORT_ORDER_DOWN)
                                                        if GetCursorContentType() == MOUSE_CONTENT_STORE_ITEM then
                                                            ClearCursor()
                                                        end
                                                    end
                                                end)

    control:RegisterForEvent(EVENT_OPEN_STORE, ShowStoreWindow)
    control:RegisterForEvent(EVENT_CLOSE_STORE, CloseStoreWindow)
    control:RegisterForEvent(EVENT_BUY_RECEIPT, OnBuySuccess)
    control:RegisterForEvent(EVENT_CURRENCY_UPDATE, RefreshStoreWindow)
    control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, OnInventoryUpdated)
    control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventoryUpdated)
    control:RegisterForEvent(EVENT_CURSOR_PICKUP, HandleCursorPickup)
    control:RegisterForEvent(EVENT_CURSOR_DROPPED, HandleCursorCleared)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", RefreshStoreWindow)

    local function OnItemRepaired(bagId, slotIndex)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end

    SHARED_INVENTORY:RegisterCallback("ItemRepaired", OnItemRepaired)
end

function ZO_StoreManager:SetupDefaultSort()
    local defaultSortField = GetStoreDefaultSortField()
    if defaultSortField == STORE_DEFAULT_SORT_FIELD_NAME then
        self.sortHeaderGroup:SelectHeaderByKey("name", ZO_SortHeaderGroup.SUPPRESS_CALLBACKS, ZO_SortHeaderGroup.FORCE_RESELECT, ZO_SORT_ORDER_UP)
    elseif defaultSortField == STORE_DEFAULT_SORT_FIELD_VALUE then
        self.sortHeaderGroup:SelectHeaderByKey("stackBuyPrice", ZO_SortHeaderGroup.SUPPRESS_CALLBACKS, ZO_SortHeaderGroup.FORCE_RESELECT, ZO_SORT_ORDER_UP)
    end
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
                    local cost = GetRepairAllCost()
                    if GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER) >= cost then
                        return zo_strformat(SI_REPAIR_ALL_KEYBIND_TEXT, ZO_Currency_FormatKeyboard(CURT_MONEY, cost, ZO_CURRENCY_FORMAT_WHITE_AMOUNT_ICON))
                    end
                    return zo_strformat(SI_REPAIR_ALL_KEYBIND_TEXT, ZO_Currency_FormatKeyboard(CURT_MONEY, cost, ZO_CURRENCY_FORMAT_AMOUNT_ERROR_ICON))
                end,
                keybind = "UI_SHORTCUT_SECONDARY",
                visible = function() return self.windowMode == ZO_STORE_WINDOW_MODE_NORMAL and CanStoreRepair() and GetRepairAllCost() > 0 end,
                callback = function()
                    ZO_Dialogs_ShowDialog("REPAIR_ALL", {cost = GetRepairAllCost()})
                end,
            },

            -- Sell All Junk
            {
                name = GetString(SI_SELL_ALL_JUNK_KEYBIND_TEXT),
                keybind = "UI_SHORTCUT_NEGATIVE",

                visible =   function()
                                return self.windowMode == ZO_STORE_WINDOW_MODE_NORMAL and HasAnyJunk(BAG_BACKPACK, DONT_COUNT_STOLEN_ITEMS)
                            end,
                callback =  function()
                                ZO_Dialogs_ShowDialog("SELL_ALL_JUNK")
                            end,
            },

            --End Preview
            {
                name = GetString(SI_CRAFTING_EXIT_PREVIEW_MODE),
                keybind = "UI_SHORTCUT_QUATERNARY",
                visible =   function()
                                return ITEM_PREVIEW_KEYBOARD:IsInteractionCameraPreviewEnabled()
                            end,
                callback =  function()
                                self:TogglePreviewMode()
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

function ZO_StoreManager:ChangeFilter(filterData)
    self.currentFilter = filterData.filterType
    self.hiddenColumns = filterData.hiddenColumns

    self.activeTab:SetText(filterData.activeTabText)

    -- Manage hiding columns that show/hide depending on the current filter.  If the sort was on a column that becomes hidden
    -- then the sort needs to pick a new column.  Currently this always falls back to the name key.
    if self.sortHeaderGroup then
        self.sortHeaderGroup:SetHeadersHiddenFromKeyList(self.hiddenColumns, true)

        if self.hiddenColumns[self.sortHeaderGroup:GetCurrentSortKey()] then
            -- User wanted to sort by a column that's gone!
            -- Fallback to name.
            self.sortHeaderGroup:SelectHeaderByKey("name")
        end
    end

    --Hide inventory capacity for collectibles since they don't take up space
    self.freeSlotsLabel:SetHidden(self.currentFilter == ITEMFILTERTYPE_COLLECTIBLE)

    self:UpdateList()
end

function ZO_StoreManager:ShouldAddItemToList(itemData)
    if self.currentFilter == ITEMFILTERTYPE_ALL then return true end

    for i = 1, #itemData.filterData do
        if itemData.filterData[i] == self.currentFilter then
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
    sellInformationSortOrder = { tiebreaker = "name", isNumeric = true },
}

function ZO_StoreManager:SortData()
    local scrollData = ZO_ScrollList_GetDataList(self.list)

    self.sortFunction = self.sortFunction or function(entry1, entry2)
        return ZO_TableOrderingFunction(entry1.data, entry2.data, self.sortHeaderGroup:GetCurrentSortKey(), sortKeys, self.sortHeaderGroup:GetSortDirection())
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
    local storeUsesGold = ZO_IsElementInNumericallyIndexedTable(self.storeUsedCurrencies, CURT_MONEY)
    local showPlayerGold = storeUsesGold or GetRepairAllCost() > 0
    local HIDE_GOLD_AMOUNT = 0 -- if showPlayerGold is false then we pass in 0 as the amount to hide the gold display
    local shownGoldAmount = showPlayerGold and GetCurrencyAmount(CURT_MONEY, GetCurrencyPlayerStoredLocation(CURT_MONEY)) or HIDE_GOLD_AMOUNT
    ZO_CurrencyControl_SetCurrencyData(self.currencyMoneyDisplay, CURT_MONEY, shownGoldAmount, showPlayerGold)
    ZO_CurrencyControl_SetCurrency(self.currencyMoneyDisplay, ZO_KEYBOARD_CURRENCY_OPTIONS)

    -- We're laying out the player alternate currency labels this way to ensure that we never display more than two labels, even if 
    -- more than two are applicable to this store, and to ensure that they maintain a consistent priority
    self.currency1Display:SetHidden(true)
    self.currency1Display.isInUse = false

    self.currency2Display:SetHidden(true)
    self.currency2Display.isInUse = false

    for i, currencyType in ipairs(self.storeUsedCurrencies) do
        if currencyType ~= CURT_MONEY then
            local playerHeldCurrencyAmount = GetCurrencyAmount(currencyType, GetCurrencyPlayerStoredLocation(currencyType))
            self:SetCurrencyControl(currencyType, playerHeldCurrencyAmount, ZO_KEYBOARD_CURRENCY_OPTIONS)
        end
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_StoreManager:UpdateFilters()
    ZO_MenuBar_ClearButtons(self.tabs)

    --The last filter added is the farthest left, so to the player it should be "first"
    local lastFilter
    for _, data in ipairs(self.storeFilters) do
        if (data.filterType == ITEMFILTERTYPE_ALL and self.showAllFilter) or self.usedFilterTypes[data.filterType] then
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

    local numUsedStoreFilters = 0
    for _, data in ipairs(self.storeFilters) do
        if self.usedFilterTypes[data.filterType] then
            numUsedStoreFilters = numUsedStoreFilters + 1
        end
    end

    -- We only want to show the all filter if we aren't showing one specific filter
    -- because then all and the specific filter would have the same contents
    self.showAllFilter = numUsedStoreFilters ~= 1 
end

function ZO_StoreManager:UpdateList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ScrollList_Clear(self.list)
    
    for index = 1, #self.items do
        local itemData = self.items[index]

        if self:ShouldAddItemToList(itemData) then
            scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(DATA_TYPE_STORE_ITEM, itemData)
        end
    end

    self:ApplySort()
end

function ZO_StoreManager:SetUpBuySlot(control, data)
    local newStatusControl = GetControl(control, "Status")
    local slotControl = GetControl(control, "Button")
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
    slotControl.meetsRequirements = data.meetsRequirementsToBuy

    ZO_InventorySlot_SetType(control, SLOT_TYPE_STORE_BUY)
    control.index = slotIndex
    control.moneyCost = data.stackBuyPrice

    local meetsReqs = data.meetsRequirementsToBuy and data.meetsRequirementsToEquip
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

    local locked = false
    if not data.meetsRequirementsToBuy and (data.buyStoreFailure == STORE_FAILURE_ALREADY_HAVE_COLLECTIBLE or data.buyStoreFailure == STORE_FAILURE_AWARDS_ALREADY_OWNED_COLLECTIBLE) then
        locked = true
    end
    ZO_PlayerInventorySlot_SetupUsableAndLockedColor(control, meetsReqs, locked)
    ZO_UpdateTraitInformationControlIcon(control, data)

    ZO_CurrencyControl_InitializeDisplayTypes(priceControl, unpack(ZO_VALID_CURRENCY_TYPES))

    local currencyType1 = data.currencyType1
    local currencyType2 = data.currencyType2

    ZO_CurrencyControl_SetCurrencyData(priceControl, CURT_MONEY, data.stackBuyPrice, CURRENCY_DONT_SHOW_ALL, not self:HasEnoughCurrencyToBuyItem(CURT_MONEY, data.stackBuyPrice))
    ZO_CurrencyControl_SetCurrencyData(priceControl, currencyType1, data.currencyQuantity1, CURRENCY_DONT_SHOW_ALL, not self:HasEnoughCurrencyToBuyItem(currencyType1, data.stackBuyPriceCurrency1), data.slotIndex, 1)
    ZO_CurrencyControl_SetCurrencyData(priceControl, currencyType2, data.currencyQuantity2, CURRENCY_DONT_SHOW_ALL, not self:HasEnoughCurrencyToBuyItem(currencyType2, data.stackBuyPriceCurrency2), data.slotIndex, 2)

    ZO_CurrencyControl_SetCurrency(priceControl, ITEM_BUY_CURRENCY_OPTIONS)
end

function ZO_StoreManager:HasEnoughCurrencyToBuyItem(currencyType, itemCost)
    return GetCurrencyAmount(currencyType, GetCurrencyPlayerStoredLocation(currencyType)) >= itemCost
end

function ZO_StoreManager:OpenBuyMultiple(entryIndex)
    self.multipleDialog.index = entryIndex
    self.buyMultipleSpinner:SetValue(1, true)
    ZO_Dialogs_ShowDialog("BUY_MULTIPLE")
end

function ZO_StoreManager:BuyMultiplePurchase()
    local storeItemIndex = self.multipleDialog.index

    local quantity = self.buyMultipleSpinner:GetValue()
    if quantity ~= 0 then
        local itemData = self.items[storeItemIndex]
        if not ZO_Currency_TryShowThresholdDialog(storeItemIndex, quantity, itemData) then
            BuyStoreItem(storeItemIndex, quantity)
        end
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

    ZO_CurrencyControl_InitializeDisplayTypes(currencyControl, unpack(ZO_VALID_CURRENCY_TYPES))

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

function ZO_StoreManager:TogglePreviewMode()
    ITEM_PREVIEW_KEYBOARD:ToggleInteractionCameraPreview(FRAME_TARGET_STORE_WINDOW_FRAGMENT, FRAME_PLAYER_ON_SCENE_HIDDEN_FRAGMENT, RIGHT_PANEL_BG_EMPTY_WORLD_ITEM_PREVIEW_OPTIONS_FRAGMENT)

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_StoreManager:PreviewStoreEntry(storeEntryIndex)
    if not ITEM_PREVIEW_KEYBOARD:IsInteractionCameraPreviewEnabled() then
        self:TogglePreviewMode()
    end

    ZO_StoreManager_DoPreviewAction(ZO_STORE_MANAGER_PREVIEW_ACTION_EXECUTE, storeEntryIndex)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

-------------------
-- Global functions
-------------------

local function GetStoreEntryIndexForPreviewFromSlot(storeEntrySlot)
    local inventorySlot, listPart, multiIconPart = ZO_InventorySlot_GetInventorySlotComponents(storeEntrySlot)

    local slotType = ZO_InventorySlot_GetType(inventorySlot)
    if slotType == SLOT_TYPE_STORE_BUY then
        local storeEntryIndex = inventorySlot.index
        if ZO_StoreManager_DoPreviewAction(ZO_STORE_MANAGER_PREVIEW_ACTION_VALIDATE, storeEntryIndex) then
            return storeEntryIndex
        end
    end

    return nil
end

function ZO_BuyMultiple_OpenBuyMultiple(entryIndex)
    STORE_WINDOW:OpenBuyMultiple(entryIndex)
end

function ZO_Store_OnEntryMouseEnter(storeEntrySlot)
    ZO_InventorySlot_OnMouseEnter(storeEntrySlot)

    local storeEntryIndex = GetStoreEntryIndexForPreviewFromSlot(storeEntrySlot)

    local cursor = MOUSE_CURSOR_DO_NOT_CARE
    if storeEntryIndex ~= nil then
        cursor = MOUSE_CURSOR_PREVIEW
    end

    WINDOW_MANAGER:SetMouseCursor(cursor)
end

function ZO_Store_OnEntryMouseExit(storeEntrySlot)
    ZO_InventorySlot_OnMouseExit(storeEntrySlot)
    WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
end

function ZO_Store_OnEntryClicked(storeEntrySlot, button)
    -- left button for an inventory slot click will only try and drag and drop, but that
    -- should be handled for us by the OnReceiveDrag handler, so if we left click
    -- we'll do our custom behavior
    if button == MOUSE_BUTTON_INDEX_LEFT then
        local storeEntryIndex = GetStoreEntryIndexForPreviewFromSlot(storeEntrySlot)
        if storeEntryIndex ~= nil then
            STORE_WINDOW:PreviewStoreEntry(storeEntryIndex)
        end
    else
        ZO_InventorySlot_OnSlotClicked(storeEntrySlot, button)
    end
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
    if upInside and GetCursorContentType() ~= MOUSE_CONTENT_EMPTY then
        PlaceInStoreWindow()
    end
end

function ZO_Store_OnReceiveDrag()
    if GetCursorContentType() ~= MOUSE_CONTENT_EMPTY then
        PlaceInStoreWindow()
    end
end

function ZO_Store_IsShopping()
    return GetInteractionType() == INTERACTION_VENDOR
end

function ZO_Store_OnInitialize(control)
    STORE_WINDOW = ZO_StoreManager:New(control)
end
