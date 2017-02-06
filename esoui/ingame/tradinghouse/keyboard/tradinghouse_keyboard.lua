--[[
    Trading House Utilities (combo box, data unpacking, etc...)
--]]

local function InitializeBaseComboBox(control)
    local comboBox = ZO_ComboBox_ObjectFromContainer(control)

    if(not control.hasInitializedComboBox) then
        comboBox:SetSortsItems(false)
        comboBox:SetFont("ZoFontWinT1")
        comboBox:SetSpacing(4)
        control.hasInitializedComboBox = true
    end

    return comboBox
end

function ZO_TradingHouse_SortComboBoxEntries(entryData, sortType, sortOrder, anchorFirstEntry, anchorLastEntry)
    local firstEntry = entryData[1][ZO_RANGE_COMBO_INDEX_TEXT]
    local lastEntry = entryData[#entryData][ZO_RANGE_COMBO_INDEX_TEXT]

    local function DataSortHelper(item1, item2)
        local name1 = item1[ZO_RANGE_COMBO_INDEX_TEXT]
        local name2 = item2[ZO_RANGE_COMBO_INDEX_TEXT]

        if anchorFirstEntry then
            if name1 == firstEntry then
                return true
            elseif name2 == firstEntry then
                return false
            end
        end

        if anchorLastEntry then
            if name1 == lastEntry then
                return false
            elseif name2 == lastEntry then
                return true
            end
        end

        return (name1 < name2)
    end

    -- Sort the entries, while ensuring that the anchored entries remain where they are.
    table.sort(entryData, function(item1, item2) return DataSortHelper(item1, item2) end)
end

-- Global so that the external filter objects can use it.
function ZO_TradingHouse_InitializeRangeComboBox(control, entryData, callback, interfaceColorType, colorIndex)
    local comboBox = InitializeBaseComboBox(control)
    ZO_TradingHouse_InitializeColoredComboBox(comboBox, entryData, callback, interfaceColorType, colorIndex)
    return comboBox
end

function ZO_TradingHouse_UpdateComboBox(control, entryData, callback)
    control:SetHidden(entryData == nil)

    if(entryData) then
        local comboBox = ZO_ComboBox_ObjectFromContainer(control)
        if(comboBox) then
            comboBox:ClearItems()
            ZO_TradingHouse_InitializeRangeComboBox(control, entryData, callback)
        end
    end
end

--[[
    Trading House Filter
]]--

-- Base class for the trading house filters
ZO_TradingHouseFilter = ZO_Object:Subclass()

function ZO_TradingHouseFilter:New(...)
    local filter = ZO_Object.New(self)
    filter:Initialize(...)
    return filter
end

function ZO_TradingHouseFilter:Initialize()
end

function ZO_TradingHouseFilter:GetControl()
end

function ZO_TradingHouseFilter:SetHidden()
end

function ZO_TradingHouseFilter:ApplyToSearch()
end

function ZO_TradingHouseFilter:Reset()
end

--[[
    MultiFilter Setting Object
    This is used to drive a more complex series of filter settings where each object can access specific controls
    to set up multiple filter types.  Like searching for Armor -> Apparel -> Rings, because we want to present
    information to the user in a different way than the data is actually organized from the enums.

    This is a global object, specific modules will be defined in their own files and registered with the trading
    house filters.
--]]

ZO_TradingHouseMultiFilter = ZO_TradingHouseFilter:Subclass()

function ZO_TradingHouseMultiFilter:New(...)
    return ZO_TradingHouseFilter.New(self, ...)
end

function ZO_TradingHouseMultiFilter:Initialize(control)
    self.m_control = control
end

function ZO_TradingHouseMultiFilter:GetControl()
    return self.m_control
end

function ZO_TradingHouseMultiFilter:SetHidden(hidden)
    self:GetControl():SetHidden(hidden)
end

function ZO_TradingHouseMultiFilter:Reset()
    ZO_ComboBox_ObjectFromContainer(self.m_control:GetNamedChild("Category")):SelectFirstItem()
end

--[[
    Trading House Manager
--]]

local ZO_TradingHouseManager = ZO_TradingHouse_Shared:Subclass()

function ZO_TradingHouseManager:New(...)
    local manager = ZO_TradingHouse_Shared.New(self, ...)
    return manager
end

function ZO_TradingHouseManager:Initialize(control)
    ZO_TradingHouse_Shared.Initialize(self, control)
    self.m_initialized = false
    self.m_titleLabel = control:GetNamedChild("TitleLabel")
    TRADING_HOUSE_SCENE = ZO_InteractScene:New("tradinghouse", SCENE_MANAGER, ZO_TRADING_HOUSE_INTERACTION)
    SYSTEMS:RegisterKeyboardRootScene(ZO_TRADING_HOUSE_SYSTEM_NAME, TRADING_HOUSE_SCENE)
end

function ZO_TradingHouseManager:InitializeScene()
    local function SceneStateChange(oldState, newState)
        if(newState == SCENE_SHOWING) then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            PLAYER_INVENTORY:SetTradingHouseModeEnabled(true)
        elseif(newState == SCENE_HIDING) then
            SetPendingItemPost(BAG_BACKPACK, 0, 0)
            ClearMenu()
            PLAYER_INVENTORY:SetTradingHouseModeEnabled(false)
        elseif(newState == SCENE_HIDDEN) then
            self:ClearSearchResults()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end

    TRADING_HOUSE_SCENE:RegisterCallback("StateChange",  SceneStateChange)
end

function ZO_TradingHouseManager:InitializeKeybindDescriptor()
    local tradingHouse = self

    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Post Item
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = function()
                if(tradingHouse:IsInSearchMode()) then
                    return GetString(SI_TRADING_HOUSE_DO_SEARCH)
                elseif(tradingHouse:IsInSellMode()) then
                    return GetString(SI_TRADING_HOUSE_POST_ITEM)
                end
            end,

            callback = function()
                if(tradingHouse:CanSearch()) then
                    tradingHouse:DoSearch()
                elseif(tradingHouse:CanPostWithMoneyCheck()) then
                    tradingHouse:PostPendingItem()
                end
            end,

            visible = function()
                if(tradingHouse:IsInSearchMode()) then
                    return true
                elseif(tradingHouse:IsInSellMode()) then
                    return tradingHouse:CanPost()
                end

                return false
            end,

            enabled = function()
                if(tradingHouse:IsInSearchMode()) then
                    return tradingHouse.m_searchAllowed and (GetTradingHouseCooldownRemaining() == 0)
                elseif (tradingHouse:IsInSellMode()) then
                    return tradingHouse:HasEnoughMoneyToPostPendingItem()
                end

                return true
            end,
        },

        -- Switch Guilds
        {
            name = function()
                local selectedGuildId = GetSelectedTradingHouseGuildId()
                if(selectedGuildId) then
                    return GetGuildName(selectedGuildId) -- TODO: Incorrect...this needs to pull from the guilds that the trading house has access to.
                end
            end,
            keybind = "UI_SHORTCUT_TERTIARY",
            visible =   function()
                            return GetSelectedTradingHouseGuildId() ~= nil and GetNumTradingHouseGuilds() > 1
                        end,
            callback =  function()
                            ZO_Dialogs_ShowDialog("SELECT_TRADING_HOUSE_GUILD")
                        end,
        },

        --Reset Search
        {
            name = GetString(SI_TRADING_HOUSE_RESET_SEARCH),
            keybind = "UI_SHORTCUT_NEGATIVE",
            visible =   function()
                            return tradingHouse:IsInSearchMode()
                        end,
            callback =  function()
                            self:ResetAllSearchData()
                        end,
        }
    }
end

function ZO_TradingHouseManager:InitializeMenuBar(control)
    self.m_menuBar = control:GetNamedChild("MenuBar")
    self.m_tabLabel = self.m_menuBar:GetNamedChild("Label")

    local function HandleTabSwitch(tabData)
        self:HandleTabSwitch(tabData)
    end

    local iconData =
    {
        {
            categoryName = SI_TRADING_HOUSE_MODE_BROWSE,
            descriptor = ZO_TRADING_HOUSE_MODE_BROWSE,
            normal = "EsoUI/Art/TradingHouse/tradinghouse_browse_tabIcon_up.dds",
            pressed = "EsoUI/Art/TradingHouse/tradinghouse_browse_tabIcon_down.dds",
            disabled = "EsoUI/Art/TradingHouse/tradinghouse_browse_tabIcon_disabled.dds",
            highlight = "EsoUI/Art/TradingHouse/tradinghouse_browse_tabIcon_over.dds",
            callback = HandleTabSwitch,
        },
        {
            categoryName = SI_TRADING_HOUSE_MODE_SELL,
            descriptor = ZO_TRADING_HOUSE_MODE_SELL,
            normal = "EsoUI/Art/TradingHouse/tradinghouse_sell_tabIcon_up.dds",
            pressed = "EsoUI/Art/TradingHouse/tradinghouse_sell_tabIcon_down.dds",
            disabled = "EsoUI/Art/TradingHouse/tradinghouse_sell_tabIcon_disabled.dds",
            highlight = "EsoUI/Art/TradingHouse/tradinghouse_sell_tabIcon_over.dds",
            callback = HandleTabSwitch,
        },
        {
            categoryName = SI_TRADING_HOUSE_MODE_LISTINGS,
            descriptor = ZO_TRADING_HOUSE_MODE_LISTINGS,
            normal = "EsoUI/Art/TradingHouse/tradinghouse_listings_tabIcon_up.dds",
            pressed = "EsoUI/Art/TradingHouse/tradinghouse_listings_tabIcon_down.dds",
            disabled = "EsoUI/Art/TradingHouse/tradinghouse_listings_tabIcon_disabled.dds",
            highlight = "EsoUI/Art/TradingHouse/tradinghouse_listings_tabIcon_over.dds",
            callback = HandleTabSwitch,
        },
    }

    for _, button in ipairs(iconData) do
        ZO_MenuBar_AddButton(self.m_menuBar, button)
    end
end

function ZO_TradingHouseManager:HandleTabSwitch(tabData)
    local mode = tabData.descriptor
    self:SetCurrentMode(mode)
    self.m_tabLabel:SetText(GetString(tabData.categoryName))

    local notSellMode = mode ~= ZO_TRADING_HOUSE_MODE_SELL
    local notBrowseMode = mode ~= ZO_TRADING_HOUSE_MODE_BROWSE
    local notListingsMode = mode ~= ZO_TRADING_HOUSE_MODE_LISTINGS

    self.m_postItems:SetHidden(notSellMode)
    self.m_browseItems:SetHidden(notBrowseMode)
    self.m_searchResultsList:SetHidden(notBrowseMode)
    self.m_searchSortHeadersControl:SetHidden(notBrowseMode)
    self.m_nagivationBar:SetHidden(notBrowseMode)
    self.m_noItemsContainer:SetHidden(notBrowseMode)
    self.m_postedItemsList:SetHidden(notListingsMode)
    self.m_postedItemsHeader:SetHidden(notListingsMode)

    if(mode == ZO_TRADING_HOUSE_MODE_SELL) then
        SCENE_MANAGER:AddFragment(INVENTORY_FRAGMENT)
    else
        SCENE_MANAGER:RemoveFragment(INVENTORY_FRAGMENT)
    end

    if(mode == ZO_TRADING_HOUSE_MODE_LISTINGS) then
        self:RequestListings()
    end

    if(mode == ZO_TRADING_HOUSE_MODE_SELL) then
        self:UpdateListingCounts()
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TradingHouseManager:HasValidPendingItemPost()
    return self.m_pendingItemSlot ~= nil
end

function ZO_TradingHouseManager:HasEnoughMoneyToPostPendingItem()
    return self:HasValidPendingItemPost() and self.m_pendingSaleIsValid
end

function ZO_TradingHouseManager:CanPost()
    return self:CanDoCommonOperation() and self:IsInSellMode()
end

function ZO_TradingHouseManager:CanPostWithMoneyCheck()
    return self:CanDoCommonOperation() and self:IsInSellMode() and self:HasEnoughMoneyToPostPendingItem()
end

function ZO_TradingHouseManager:InitializePostItem(control)
    self.m_postItems = self.m_leftPane:GetNamedChild("PostItem")
    self.m_pendingItemBG = self.m_postItems:GetNamedChild("PendingBG")
    self.m_pendingItemName = self.m_postItems:GetNamedChild("FormInfoName")
    self.m_pendingItem = self.m_postItems:GetNamedChild("FormInfoItem")
    self.m_currentListings = self.m_postItems:GetNamedChild("FormInfoListingCount")
    self.m_invoice = self.m_postItems:GetNamedChild("FormInvoice")
    self.m_invoiceSellPrice = self.m_invoice:GetNamedChild("SellPriceAmount")
    self.m_invoiceListingFee = self.m_invoice:GetNamedChild("ListingFeePrice")
    self.m_invoiceTheirCut = self.m_invoice:GetNamedChild("TheirCutPrice")
    self.m_invoiceProfit = self.m_invoice:GetNamedChild("ProfitAmount")

    self:OnPendingPostItemUpdated(0, false)
end

function ZO_TradingHouseManager:InitializeBrowseItems(control)
    self:InitializeSearchTerms()
    self:InitializeSearchResults(control)
    self:InitializeSearchSortHeaders(control)
    self:InitializeSearchNavigationBar(control)
end

function ZO_TradingHouseManager:InitializeSearchSortHeaders(control)
    self.m_searchSortHeadersControl = control:GetNamedChild("ItemPaneSearchSortBy")
    local sortHeaders = ZO_SortHeaderGroup:New(self.m_searchSortHeadersControl, true)
    self.m_searchSortHeaders = sortHeaders

    local function OnSortHeaderClicked(key, order)
        self:ChangeSort(key, order)
    end

    sortHeaders:RegisterCallback(ZO_SortHeaderGroup.HEADER_CLICKED, OnSortHeaderClicked)
    sortHeaders:AddHeadersFromContainer()
    sortHeaders:SelectHeaderByKey(TRADING_HOUSE_SORT_SALE_PRICE, ZO_SortHeaderGroup.SUPPRESS_CALLBACKS)
end

function ZO_TradingHouseManager:InitializeSearchNavigationBar(control)
    self.m_nagivationBar = control:GetNamedChild("ItemPaneSearchControls")
    self.m_resultCount = self.m_nagivationBar:GetNamedChild("ResultCount")
    self.m_previousPage = self.m_nagivationBar:GetNamedChild("PreviousPage")
    self.m_nextPage = self.m_nagivationBar:GetNamedChild("NextPage")

    local moneyControl = self.m_nagivationBar:GetNamedChild("Money")
    local function UpdateMoney()
        self.m_playerMoney[CURT_MONEY] = GetCarriedCurrencyAmount(CURT_MONEY)
        ZO_CurrencyControl_SetSimpleCurrency(moneyControl, CURT_MONEY, self.m_playerMoney[CURT_MONEY], ZO_KEYBOARD_CARRIED_CURRENCY_OPTIONS)
    end

    moneyControl:RegisterForEvent(EVENT_MONEY_UPDATE, UpdateMoney)
    UpdateMoney()

    local function UpdateAlliancePoints()
        self.m_playerMoney[CURT_ALLIANCE_POINTS] = GetAlliancePoints()
    end

    moneyControl:RegisterForEvent(EVENT_ALLIANCE_POINT_UPDATE, UpdateAlliancePoints)
    UpdateAlliancePoints()

    self.m_previousPage:SetHandler("OnClicked", function() self.m_search:SearchPreviousPage() end)
    self.m_nextPage:SetHandler("OnClicked", function() self.m_search:SearchNextPage() end)
end

function ZO_TradingHouseManager:ToggleLevelRangeMode()
    if(self.m_levelRangeFilterType == TRADING_HOUSE_FILTER_TYPE_LEVEL) then
        self.m_levelRangeFilterType = TRADING_HOUSE_FILTER_TYPE_CHAMPION_POINTS
        self.m_levelRangeToggle:SetState(BSTATE_PRESSED, true)
        self.m_levelRangeLabel:SetText(GetString(SI_TRADING_HOUSE_BROWSE_CHAMPION_POINTS_RANGE_LABEL))
    else
        self.m_levelRangeFilterType = TRADING_HOUSE_FILTER_TYPE_LEVEL
        self.m_levelRangeToggle:SetState(BSTATE_NORMAL, false)
        self.m_levelRangeLabel:SetText(GetString(SI_TRADING_HOUSE_BROWSE_LEVEL_RANGE_LABEL))
    end
end

function ZO_TradingHouseManager:InitializeSearchTerms()
    local browseItems = self.m_leftPane:GetNamedChild("BrowseItems")

    self.m_browseItems = browseItems
    self.m_minPriceEdit = browseItems:GetNamedChild("CommonMinPriceBox")
    self.m_maxPriceEdit = browseItems:GetNamedChild("CommonMaxPriceBox")
    self.m_minLevelEdit = browseItems:GetNamedChild("CommonMinLevelBox")
    self.m_maxLevelEdit = browseItems:GetNamedChild("CommonMaxLevelBox")

    self.m_minPriceEdit:SetHandler("OnTextChanged", ZO_TradingHouse_SearchCriteriaChanged)
    self.m_maxPriceEdit:SetHandler("OnTextChanged", ZO_TradingHouse_SearchCriteriaChanged)
    self.m_minLevelEdit:SetHandler("OnTextChanged", ZO_TradingHouse_SearchCriteriaChanged)
    self.m_maxLevelEdit:SetHandler("OnTextChanged", ZO_TradingHouse_SearchCriteriaChanged)

    local editControlGroup = ZO_EditControlGroup:New()
    editControlGroup:AddEditControl(self.m_minPriceEdit)
    editControlGroup:AddEditControl(self.m_maxPriceEdit)
    editControlGroup:AddEditControl(self.m_minLevelEdit)
    editControlGroup:AddEditControl(self.m_maxLevelEdit)

    self.m_levelRangeLabel = browseItems:GetNamedChild("CommonLevelRangeLabel")
    self.m_levelRangeToggle = browseItems:GetNamedChild("CommonLevelRangeToggle")
    self.m_levelRangeToggle:SetState(BSTATE_NORMAL, false)
    self.m_levelRangeFilterType = TRADING_HOUSE_FILTER_TYPE_LEVEL

    self.m_search = ZO_TradingHouseSearch:New()
    self.m_search:AddSetter(ZO_TradingHouse_NumericRangeSetter:New(TRADING_HOUSE_FILTER_TYPE_PRICE, self.m_minPriceEdit, self.m_maxPriceEdit))
    self.m_search:AddSetter(ZO_TradingHouse_NumericRangeSetter:New(function() return self.m_levelRangeFilterType end, self.m_minLevelEdit, self.m_maxLevelEdit))

    self.m_qualityCombo = ZO_TradingHouse_InitializeRangeComboBox(browseItems:GetNamedChild("CommonQuality"), ZO_TRADING_HOUSE_QUALITIES, ZO_TradingHouse_ComboBoxSelectionChanged, INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, 1)
    self.m_search:AddSetter(ZO_TradingHouseComboBoxSetter:New(TRADING_HOUSE_FILTER_TYPE_QUALITY, self.m_qualityCombo))

    self.m_traitFilters = ZO_TradingHouse_TraitFilters:New(browseItems)
    self.m_enchantmentFilters = ZO_TradingHouse_EnchantmentFilters:New(browseItems)

    local comboBox = InitializeBaseComboBox(browseItems:GetNamedChild("ItemCategory"))
    self.m_categoryCombo = comboBox

    self:InitializeCategoryComboBox(self.m_categoryCombo)
end

local SEARCH_RESULTS_DATA_TYPE = 1
local ITEM_LISTINGS_DATA_TYPE = 2
local GUILD_SPECIFIC_ITEM_DATA_TYPE = 3

local ITEM_RESULT_CURRENCY_OPTIONS =
{
    showTooltips = false,
    font = "ZoFontGameShadow",
    iconSide = RIGHT,
}

function ZO_TradingHouseManager:InitializeSearchResults(control)
    local searchResultsList = control:GetNamedChild("ItemPaneSearchResults")

    self.m_searchResultsList = searchResultsList
    self.m_searchResultsControlsList = {}
    self.m_searchResultsInfoList = {}

    local function SetupBaseSearchResultRow(rowControl, result)
        self.m_searchResultsControlsList[#self.m_searchResultsControlsList+1] = rowControl
        self.m_searchResultsInfoList[#self.m_searchResultsInfoList+1] = result

        local slotIndex = result.slotIndex

        local nameControl = GetControl(rowControl, "Name")
        nameControl:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, result.name))
        local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, result.quality)
        nameControl:SetColor(r, g, b, 1)

        local sellerControl = GetControl(rowControl, "SellerName")
        sellerControl:SetText(zo_strformat(SI_TRADING_HOUSE_BROWSE_ITEM_SELLER_NAME, result.sellerName))

        local sellPriceControl = GetControl(rowControl, "SellPrice")
        ZO_CurrencyControl_SetSimpleCurrency(sellPriceControl, result.currencyType, result.purchasePrice, ITEM_RESULT_CURRENCY_OPTIONS, nil, self.m_playerMoney[result.currencyType] < result.purchasePrice)

        local resultControl = GetControl(rowControl, "Button")

        ZO_Inventory_SetupSlot(resultControl, result.stackCount, result.icon)

        -- Cached for verification when the player tries to purchase this
        resultControl.sellerName = result.sellerName
        resultControl.purchasePrice = result.purchasePrice
        resultControl.currencyType = result.currencyType

        return resultControl
    end

    local function SetupSearchResultRow(rowControl, result)
        local resultControl = SetupBaseSearchResultRow(rowControl, result)

        local timeRemainingControl = GetControl(rowControl, "TimeRemaining")
        timeRemainingControl:SetText(zo_strformat(SI_TRADING_HOUSE_BROWSE_ITEM_REMAINING_TIME, ZO_FormatTime(result.timeRemaining, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)))

        ZO_Inventory_BindSlot(resultControl, SLOT_TYPE_TRADING_HOUSE_ITEM_RESULT, result.slotIndex)
    end

    local function SetupGuildSpecificItemRow(rowControl, result)
        local resultControl = SetupBaseSearchResultRow(rowControl, result)
        ZO_Inventory_BindSlot(resultControl, SLOT_TYPE_GUILD_SPECIFIC_ITEM, result.slotIndex)
    end

    ZO_ScrollList_Initialize(searchResultsList)
    ZO_ScrollList_AddDataType(searchResultsList, SEARCH_RESULTS_DATA_TYPE, "ZO_TradingHouseSearchResult", 52, SetupSearchResultRow, nil, nil, ZO_InventorySlot_OnPoolReset)
    ZO_ScrollList_AddDataType(searchResultsList, GUILD_SPECIFIC_ITEM_DATA_TYPE, "ZO_TradingHouseSearchResult", 52, SetupGuildSpecificItemRow, nil, nil, ZO_InventorySlot_OnPoolReset)
    ZO_ScrollList_AddResizeOnScreenResize(searchResultsList)
end

function ZO_TradingHouseManager:InitializeListings(control)
    self.m_postedItemsHeader = control:GetNamedChild("PostedItemsHeader")
    local postedItemsList = control:GetNamedChild("PostedItemsList")
    self.m_postedItemsList = postedItemsList

    local function CancelListing(cancelButton)
        local postedItem = cancelButton:GetParent():GetNamedChild("Button")
        local listingIndex = ZO_Inventory_GetSlotIndex(postedItem)
        self:ShowCancelListingConfirmation(listingIndex)
    end

    local function SetupPostedItemRow(rowControl, postedItem)
        local index = postedItem.slotIndex

        local nameControl = GetControl(rowControl, "Name")
        nameControl:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, postedItem.name))
        local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, postedItem.quality)
        nameControl:SetColor(r, g, b, 1)

        local timeRemainingControl = GetControl(rowControl, "TimeRemaining")
        timeRemainingControl:SetText(zo_strformat(SI_TRADING_HOUSE_BROWSE_ITEM_REMAINING_TIME, ZO_FormatTime(postedItem.timeRemaining, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)))

        local sellPriceControl = GetControl(rowControl, "SellPrice")
        ZO_CurrencyControl_SetSimpleCurrency(sellPriceControl, CURT_MONEY, postedItem.purchasePrice, ITEM_RESULT_CURRENCY_OPTIONS)

        local postedItemControl = GetControl(rowControl, "Button")
        ZO_Inventory_BindSlot(postedItemControl, SLOT_TYPE_TRADING_HOUSE_ITEM_LISTING, index)
        ZO_Inventory_SetupSlot(postedItemControl, postedItem.stackCount, postedItem.icon)

        local cancelButton = GetControl(rowControl, "CancelSale")
        cancelButton:SetHandler("OnClicked", CancelListing)
    end

    ZO_ScrollList_Initialize(postedItemsList)
    ZO_ScrollList_AddDataType(postedItemsList, ITEM_LISTINGS_DATA_TYPE, "ZO_TradingHouseItemListing", 52, SetupPostedItemRow, nil, nil, ZO_InventorySlot_OnPoolReset)
    ZO_ScrollList_AddResizeOnScreenResize(postedItemsList)
end

function ZO_TradingHouseManager:RequestListings()
    if(self:IsAwaitingResponse()) then
        self:QueueListingRequest()
    else
        RequestTradingHouseListings()
    end
end

function ZO_TradingHouseManager:OnListingsRequestSuccess()
    local list = self.m_postedItemsList
    local scrollData = ZO_ScrollList_GetDataList(list)
    ZO_ScrollList_Clear(list)

    for i = 1, GetNumTradingHouseListings() do
        local itemData = ZO_TradingHouse_CreateItemData(i, GetTradingHouseListingItemInfo)
        if(itemData) then
            scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(ITEM_LISTINGS_DATA_TYPE, itemData)
        end
    end

    ZO_ScrollList_Commit(list)
end

function ZO_TradingHouseManager:RefreshListingsIfNecessary()
    if(GetNumTradingHouseListings() > 0) then
        self:OnListingsRequestSuccess()
    end
end

function ZO_TradingHouseManager:OnPendingPostItemUpdated(slotId, isPending)
    self.m_pendingSaleIsValid = false

    if(isPending) then
        self.m_pendingItemSlot = slotId
        self:SetupPendingPost(slotId)
    else
        self.m_pendingItemSlot = nil
        self:ClearPendingPost()
    end

    self:UpdateListingCounts()
end

function ZO_TradingHouseManager:OnPostSuccess()
    -- convenience wrapper for clearing out the pending item and updating the post count
    self:OnPendingPostItemUpdated()
end

function ZO_TradingHouseManager:UpdateListingCounts()
    local currentListings, maxListings = GetTradingHouseListingCounts()
    if(currentListings < maxListings) then
        self.m_currentListings:SetText(zo_strformat(SI_TRADING_HOUSE_LISTING_COUNT, currentListings, maxListings))
    else
        self.m_currentListings:SetText(zo_strformat(SI_TRADING_HOUSE_LISTING_COUNT_FULL, currentListings, maxListings))
    end
end

local INVOICE_CURRENCY_OPTIONS =
{
    showTooltips = false,
    font = "ZoFontWinT1",
}

function ZO_TradingHouseManager:SetInvoicePriceColors(color)
    local r, g, b = color:UnpackRGB()
    self.m_invoiceListingFee:SetColor(r, g, b)
    self.m_invoiceTheirCut:SetColor(r, g, b)
    self.m_invoiceProfit:SetColor(r, g, b)
end

-- Only called from the CURRENCY_INPUT control callback chain
function ZO_TradingHouseManager:SetPendingPostPrice(sellPrice)
    sellPrice = tonumber(sellPrice) or 0
    self.m_invoiceSellPrice.sellPrice = sellPrice

    ZO_CurrencyControl_SetSimpleCurrency(self.m_invoiceSellPrice, CURT_MONEY, sellPrice, INVOICE_CURRENCY_OPTIONS)

    self:SetInvoicePriceColors(ZO_DEFAULT_ENABLED_COLOR)

    if(self.m_pendingItemSlot) then
        local listingFee, tradingHouseCut, profit = GetTradingHousePostPriceInfo(sellPrice)

        ZO_CurrencyControl_SetSimpleCurrency(self.m_invoiceListingFee, CURT_MONEY, listingFee, INVOICE_CURRENCY_OPTIONS)
        ZO_CurrencyControl_SetSimpleCurrency(self.m_invoiceTheirCut, CURT_MONEY, tradingHouseCut, INVOICE_CURRENCY_OPTIONS)
        ZO_CurrencyControl_SetSimpleCurrency(self.m_invoiceProfit, CURT_MONEY, profit, INVOICE_CURRENCY_OPTIONS)

        -- verify the user has enough cash
        if((GetCarriedCurrencyAmount(CURT_MONEY) - listingFee) >= 0) then
            self.m_pendingSaleIsValid = true
        else
            self.m_pendingSaleIsValid = false
            self:SetInvoicePriceColors(ZO_ERROR_COLOR)
        end
    else
        self.m_invoiceListingFee:SetText("0")
        self.m_invoiceTheirCut:SetText("0")
        self.m_invoiceProfit:SetText("0")
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TradingHouseManager:GetPendingPostPrice()
    return self.m_invoiceSellPrice.sellPrice
end

function ZO_TradingHouseManager:SetupPendingPost()
    if(self.m_pendingItemSlot) then
        local icon, stackCount, sellPrice = GetItemInfo(BAG_BACKPACK, self.m_pendingItemSlot)
        ZO_Inventory_BindSlot(self.m_pendingItem, SLOT_TYPE_TRADING_HOUSE_POST_ITEM, self.m_pendingItemSlot, BAG_BACKPACK)
        ZO_ItemSlot_SetupSlot(self.m_pendingItem, stackCount, icon)
        self.m_pendingItemName:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(BAG_BACKPACK, self.m_pendingItemSlot)))

        self.m_pendingItemBG:SetHidden(false)
        self.m_invoice:SetHidden(false)

        local initialSellPrice = sellPrice * stackCount * 3 -- markup by default (gamedata?  stays in lua?)
        self:SetPendingPostPrice(initialSellPrice)

        ZO_InventorySlot_HandleInventoryUpdate(self.m_pendingItem)
    end
end

function ZO_TradingHouseManager:ClearPendingPost()
    ZO_Inventory_BindSlot(self.m_pendingItem, SLOT_TYPE_TRADING_HOUSE_POST_ITEM)
    ZO_ItemSlot_SetupSlot(self.m_pendingItem, 0, "EsoUI/Art/TradingHouse/tradinghouse_emptySellSlot_icon.dds")
    self.m_pendingItemName:SetText(GetString(SI_TRADING_HOUSE_SELECT_AN_ITEM_TO_SELL))

    self.m_pendingItemBG:SetHidden(true)
    self.m_invoice:SetHidden(true)
    self:SetPendingPostPrice(0)
    ZO_InventorySlot_HandleInventoryUpdate(self.m_pendingItem)
end

function ZO_TradingHouseManager:PostPendingItem()
    if(self.m_pendingItemSlot and self.m_pendingSaleIsValid) then
        local stackCount = ZO_InventorySlot_GetStackCount(self.m_pendingItem)
        local desiredPrice = self.m_invoiceSellPrice.sellPrice or 0
        RequestPostItemOnTradingHouse(BAG_BACKPACK, self.m_pendingItemSlot, stackCount, desiredPrice)
    end
end

function ZO_TradingHouseManager:ChangeSort(key, order)
    self.m_search:ChangeSort(key, order)
end

function ZO_TradingHouseManager:QueueListingRequest()
    if not self:IsWaitingForResponseType(TRADING_HOUSE_RESULT_LISTINGS_PENDING) then
        self.m_requestListingsOnResponseReceived = true
    end
end

function ZO_TradingHouseManager:OnAwaitingResponse(responseType)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TradingHouseManager:OnResponseReceived(responseType, result)
    local success = result == TRADING_HOUSE_RESULT_SUCCESS

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    if(responseType == TRADING_HOUSE_RESULT_POST_PENDING) then
        if(success) then
            self:OnPostSuccess()
            self:RefreshListingsIfNecessary()
        end
    elseif(responseType == TRADING_HOUSE_RESULT_SEARCH_PENDING) then
        if(success) then
            -- Hide the fictional "awaiting search results" animation?
        end
    elseif(responseType == TRADING_HOUSE_RESULT_PURCHASE_PENDING) then
        if(success) then
            self:OnPurchaseSuccess()
        end
    elseif(responseType == TRADING_HOUSE_RESULT_LISTINGS_PENDING) then
        if(success) then
            self:OnListingsRequestSuccess()
            self.m_requestListingsOnResponseReceived = nil -- make sure that we don't request again right after we get an answer.
        end
    elseif(responseType == TRADING_HOUSE_RESULT_CANCEL_SALE_PENDING) then
        if(success) then
            -- Refresh all listings when the cancel goes through
            -- This doesn't need to ensure that the listings were received because the interface to cancel a listing requires that
            -- the listings have been received from the server.
            self:OnListingsRequestSuccess()
        end
    end

    if(self.m_requestListingsOnResponseReceived) then
        self.m_requestListingsOnResponseReceived = nil
        RequestTradingHouseListings()
    end
end

function ZO_TradingHouseManager:UpdateItemsLabels(numItems)
    self.m_resultCount:SetText(zo_strformat(SI_TRADING_HOUSE_RESULT_COUNT, numItems))
end

function ZO_TradingHouseManager:RebuildSearchResultsPage()
    local list = self.m_searchResultsList
    local scrollData = ZO_ScrollList_GetDataList(list)
    ZO_ScrollList_Clear(list)
    ZO_ScrollList_ResetToTop(list)

    for i = 1, self.m_numItemsOnPage do
        local result = ZO_TradingHouse_CreateItemData(i, GetTradingHouseSearchResultItemInfo)
        if result then
            scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(SEARCH_RESULTS_DATA_TYPE, result)
        end
    end

    local numItems = #scrollData
    self:UpdateItemsLabels(numItems)

    -- If no results were returned, disallow further searches (until one or more search criteria are modified),
    -- and display a "no items found" label.
    self.m_searchAllowed = (numItems ~= 0)
    self.m_noItemsLabel:SetHidden(self.m_searchAllowed)

    ZO_ScrollList_Commit(list)
end

function ZO_TradingHouseManager:AddGuildSpecificItems(ignoreFiltering)
    local list = self.m_searchResultsList
    local scrollData = ZO_ScrollList_GetDataList(list)
    ZO_ScrollList_Clear(list)
    ZO_ScrollList_ResetToTop(list)

    for i = 1, GetNumGuildSpecificItems() do
        local result = self:CreateGuildSpecificItemData(i, GetGuildSpecificItemInfo)
        if result and ignoreFiltering or self:ShouldAddGuildSpecificItemToList(result) then
            scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(GUILD_SPECIFIC_ITEM_DATA_TYPE, result)
        end
    end

    local numItems = #scrollData
    self:UpdateItemsLabels(numItems)

    -- If no results were returned, disallow further searches (until one or more search criteria are modified),
    -- and display a "no items found" label.
    self.m_searchAllowed = (numItems ~= 0)
    self.m_noItemsLabel:SetHidden(self.m_searchAllowed)

    ZO_ScrollList_Commit(list)

    -- refresh the keybinds because it's not going to be refreshed by an event like the normal searches
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TradingHouseManager:OnSearchResultsReceived(guildId, numItemsOnPage, currentPage, hasMorePages)
    self.m_search:SetPageData(currentPage, hasMorePages)
    self.m_numItemsOnPage = numItemsOnPage

    -- Item count will get applied in RebuildSearchResultsPage
    self:UpdateItemsLabels(0)

    self:UpdatePagingButtons()
    self:UpdateSortHeaders()
    self:RebuildSearchResultsPage()
end

function ZO_TradingHouseManager:UpdatePagingButtons()
    local cooldownFinished = GetTradingHouseCooldownRemaining() == 0

    self.m_previousPage:SetHidden(not self.m_search:HasPreviousPage())
    self.m_previousPage:SetEnabled(cooldownFinished)

    self.m_nextPage:SetHidden(not self.m_search:HasNextPage())
    self.m_nextPage:SetEnabled(cooldownFinished)
end

function ZO_TradingHouseManager:UpdateSortHeaders()
    local cooldownFinished = GetTradingHouseCooldownRemaining() == 0
    self.m_searchSortHeaders:SetEnabled(cooldownFinished and self.m_searchAllowed and (self.m_numItemsOnPage ~= 0))
end

function ZO_TradingHouseManager:OnPurchaseSuccess()
    self:RebuildSearchResultsPage()
end

function ZO_TradingHouseManager:ClearSearchResults()
    ZO_ScrollList_Clear(self.m_searchResultsList)
    ZO_ScrollList_Commit(self.m_searchResultsList)

    self.m_search:ResetAllSearchData()
    self.m_previousPage:SetEnabled(false)
    self.m_nextPage:SetEnabled(false)

    self:UpdateItemsLabels(0)
end

function ZO_TradingHouseManager:ClearListedItems()
    ZO_ScrollList_Clear(self.m_postedItemsList)
    ZO_ScrollList_Commit(self.m_postedItemsList)
end

local function ResetSearchFilter(entryIndex, entryData)
    if(entryData.filterObject) then -- need to check, because some entries don't have filters
        entryData.filterObject:Reset()
    end
end

function ZO_TradingHouseManager:ResetAllSearchData()
    self:ClearSearchResults()

    self.m_minPriceEdit:SetText("")
    self.m_maxPriceEdit:SetText("")
    self.m_minLevelEdit:SetText("")
    self.m_maxLevelEdit:SetText("")
    self.m_qualityCombo:SelectFirstItem()
    self.m_categoryCombo:SelectFirstItem()
    self.m_categoryCombo:EnumerateEntries(ResetSearchFilter)
end

function ZO_TradingHouseManager:OpenTradingHouse()
    if(not self.m_initialized) then
        self:RunInitialSetup(self.m_control)
        self.m_initialized = true
    end

    self:SetCurrentMode(ZO_TRADING_HOUSE_MODE_BROWSE)
    self.m_searchAllowed = true
    ZO_MenuBar_SelectDescriptor(self.m_menuBar, self:GetCurrentMode())
    self.m_currentDisplayName = GetDisplayName()
end

function ZO_TradingHouseManager:CloseTradingHouse()
    SYSTEMS:HideScene(ZO_TRADING_HOUSE_SYSTEM_NAME)
    if self.m_initialized then
        self.m_currentDisplayName = nil
        self:SetCurrentMode(nil)
        ZO_MenuBar_ClearSelection(self.m_menuBar)
    end
end

-- Select Active Guild for Trading House Dialog
----------------------

local function SelectTradingHouseGuildDialogInitialize(dialogControl, tradingHouseManager)
    local function SelectTradingHouseGuild(selectedGuildId)
        if(selectedGuildId) then
            if(SelectTradingHouseGuildId(selectedGuildId)) then
                tradingHouseManager:UpdateForGuildChange()
            end
        end
    end

    local dialog = ZO_SelectGuildDialog:New(dialogControl, "SELECT_TRADING_HOUSE_GUILD", SelectTradingHouseGuild)
    dialog:SetTitle(SI_PROMPT_TITLE_SELECT_GUILD_STORE)
    dialog:SetPrompt(GetString(SI_SELECT_GUILD_STORE_INSTRUCTIONS))
    dialog:SetCurrentStateSource(GetSelectedTradingHouseGuildId)
end

function ZO_TradingHouseManager:UpdateStatus()
    if(not self.m_changeGuildDialog) then
        self.m_changeGuildDialog = ZO_SelectTradingHouseGuildDialog
        SelectTradingHouseGuildDialogInitialize(self.m_changeGuildDialog, self)
    end

    self:UpdateForGuildChange()
end

function ZO_TradingHouseManager:OnOperationTimeout()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    self:UpdatePagingButtons()
    self:UpdateSortHeaders()
end

function ZO_TradingHouseManager:OnSearchCooldownUpdate(cooldownMilliseconds)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    self:UpdatePagingButtons()
    self:UpdateSortHeaders()
end

function ZO_TradingHouseManager:UpdateForGuildChange()
    local guildId = GetSelectedTradingHouseGuildId()

    if not guildId then
        -- Player is using a Guild Trader
        self:UpdateListingCounts()
        self:ClearListedItems()
        self:ClearPendingPost()
        self:ClearSearchResults()

        ZO_MenuBar_SelectDescriptor(self.m_menuBar, ZO_TRADING_HOUSE_MODE_BROWSE)

        ZO_MenuBar_SetDescriptorEnabled(self.m_menuBar, ZO_TRADING_HOUSE_MODE_SELL, false)
        ZO_MenuBar_SetDescriptorEnabled(self.m_menuBar, ZO_TRADING_HOUSE_MODE_LISTINGS, false)
    elseif guildId > 0 then
        -- Player is using a regular Guild Store
        local canSell = CanSellOnTradingHouse(guildId)

        self:UpdateListingCounts()
        self:ClearListedItems()
        self:RefreshListingsIfNecessary()
        self:ClearPendingPost()
        self:ClearSearchResults()
        self:AddGuildSpecificItems(true)

        if self:IsInSellMode() and not canSell then
            ZO_MenuBar_SelectDescriptor(self.m_menuBar, ZO_TRADING_HOUSE_MODE_BROWSE)
        end

        ZO_MenuBar_SetDescriptorEnabled(self.m_menuBar, ZO_TRADING_HOUSE_MODE_SELL, canSell)
        ZO_MenuBar_SetDescriptorEnabled(self.m_menuBar, ZO_TRADING_HOUSE_MODE_LISTINGS, true)
    end

    local _, guildName = GetCurrentTradingHouseGuildDetails()
    if guildName ~= "" then
        self.m_titleLabel:SetText(guildName)
    else
        self.m_titleLabel:SetText(GetString(SI_WINDOW_TITLE_TRADING_HOUSE))
    end

    self:AllowSearch()
end

-- Utility to show a confirmation for some kind of trading house item (listing or search result)
local function SetupTradingHouseItemDialog(dialogControl, itemInfoFn, slotIndex, slotType, costLabelStringFunction)
    -- Item data is set up on the dialog control before the dialog is shown
    local icon, itemName, quality, stackCount, _, _, purchasePrice, currencyType = itemInfoFn(slotIndex)

    local nameControl = dialogControl:GetNamedChild("ItemName")
    nameControl:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, itemName))
    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality)
    nameControl:SetColor(r, g, b, 1)

    local itemControl = dialogControl:GetNamedChild("Item")
    ZO_Inventory_BindSlot(itemControl, slotType, slotIndex)
    ZO_Inventory_SetupSlot(itemControl, stackCount, icon)

    costLabelStringId = costLabelStringFunction(currencyType)
    local costControl = dialogControl:GetNamedChild("Cost")
    costControl:SetHidden(costLabelStringId == nil)
    if(costLabelStringId) then
        costControl:SetText(zo_strformat(costLabelStringId, ZO_CurrencyControl_FormatCurrency(purchasePrice)))
    end
end

local function GetPurchaseConfirmationTextString(currencyType)
    if currencyType == CURT_ALLIANCE_POINTS then
        return SI_TRADING_HOUSE_PURCHASE_ITEM_AMOUNT_ALLIANCE_POINTS
    else
        return SI_TRADING_HOUSE_PURCHASE_ITEM_AMOUNT
    end
end

local function GetSellConfirmationAmountTextString(currencyType)
    return nil
end

-- Confirm Item Purchase Dialog
local function PurchaseItemDialogInitialize(dialogControl, tradingHouseManager)
    ZO_Dialogs_RegisterCustomDialog("CONFIRM_TRADING_HOUSE_PURCHASE",
    {
        customControl = dialogControl,
        setup = function(self) SetupTradingHouseItemDialog(self, GetTradingHouseSearchResultItemInfo, self.purchaseIndex, SLOT_TYPE_TRADING_HOUSE_ITEM_RESULT, GetPurchaseConfirmationTextString) end,
        title =
        {
            text = SI_TRADING_HOUSE_PURCHASE_ITEM_DIALOG_TITLE,
        },
        buttons =
        {
            [1] =
            {
                control =   GetControl(dialogControl, "Accept"),
                text =      SI_TRADING_HOUSE_PURCHASE_ITEM_DIALOG_CONFIRM,
                callback =  function(dialog)
                                ConfirmPendingItemPurchase()
                            end,
            },

            [2] =
            {
                control =   GetControl(dialogControl, "Cancel"),
                text =      SI_TRADING_HOUSE_PURCHASE_ITEM_DIALOG_CANCEL,
                callback =  function(dialog)
                                ClearPendingItemPurchase()
                            end,
            }
        }
    })
end

function ZO_TradingHouseManager:ConfirmPendingPurchase(pendingPurchaseIndex)
    if(not self.m_purchaseDialog) then
        self.m_purchaseDialog = ZO_TradingHousePurchaseItemDialog
        PurchaseItemDialogInitialize(self.m_purchaseDialog, self)
    end

    self.m_purchaseDialog.purchaseIndex = pendingPurchaseIndex
    ZO_Dialogs_ShowDialog("CONFIRM_TRADING_HOUSE_PURCHASE")
end

-- Confirm Guild Specific Item Purchase Dialog
local function PurchaseGuildSpecificItemDialogInitialize(dialogControl, tradingHouseManager)
    ZO_Dialogs_RegisterCustomDialog("CONFIRM_TRADING_HOUSE_GUILD_SPECIFIC_PURCHASE",
    {
        customControl = dialogControl,
        setup = function(self) SetupTradingHouseItemDialog(self, GetGuildSpecificItemInfo, self.guildSpecificItemIndex, SLOT_TYPE_GUILD_SPECIFIC_ITEM, GetPurchaseConfirmationTextString) end,
        title =
        {
            text = SI_TRADING_HOUSE_PURCHASE_ITEM_DIALOG_TITLE,
        },
        buttons =
        {
            [1] =
            {
                control =   GetControl(dialogControl, "Accept"),
                text =      SI_TRADING_HOUSE_PURCHASE_ITEM_DIALOG_CONFIRM,
                callback =  function(dialog)
                                BuyGuildSpecificItem(dialog.guildSpecificItemIndex)
                                tradingHouseManager:HandleGuildSpecificPurchase(dialog.guildSpecificItemIndex)
                            end,
            },

            [2] =
            {
                control =   GetControl(dialogControl, "Cancel"),
                text =      SI_TRADING_HOUSE_PURCHASE_ITEM_DIALOG_CANCEL,
                callback =  function(dialog)
                                -- Do nothing
                            end,
            }
        }
    })
end

function ZO_TradingHouseManager:ConfirmPendingGuildSpecificPurchase(guildSpecificItemIndex)
    if(not self.m_purchaseGuildSpecificDialog) then
        self.m_purchaseGuildSpecificDialog = ZO_TradingHousePurchaseItemDialog
        PurchaseGuildSpecificItemDialogInitialize(self.m_purchaseGuildSpecificDialog, self)
    end

    self.m_purchaseGuildSpecificDialog.guildSpecificItemIndex = guildSpecificItemIndex
    ZO_Dialogs_ShowDialog("CONFIRM_TRADING_HOUSE_GUILD_SPECIFIC_PURCHASE")
end

function ZO_TradingHouseManager:HandleGuildSpecificPurchase(guildSpecificItemIndex)
    local purchasedItemValue = self.m_searchResultsInfoList[guildSpecificItemIndex].purchasePrice
    for i = 1, #self.m_searchResultsControlsList do
    
        local purchasePrice = self.m_searchResultsInfoList[i].purchasePrice
        local currencyType = self.m_searchResultsInfoList[i].currencyType

        local sellPriceControl = GetControl(self.m_searchResultsControlsList[i], "SellPrice")
        ZO_CurrencyControl_SetSimpleCurrency(sellPriceControl, currencyType, purchasePrice, ITEM_RESULT_CURRENCY_OPTIONS, nil, self.m_playerMoney[currencyType] - purchasedItemValue < purchasePrice)
    end
end

-- Cancel Listing Confirmation Dialog
local function CancelListingDialogInitialize(dialogControl, tradingHouseManager)
    ZO_Dialogs_RegisterCustomDialog("CONFIRM_TRADING_HOUSE_CANCEL_LISTING",
    {
        customControl = dialogControl,
        setup = function(self) SetupTradingHouseItemDialog(self, GetTradingHouseListingItemInfo, self.listingIndex, SLOT_TYPE_TRADING_HOUSE_ITEM_LISTING, GetSellConfirmationAmountTextString) end,
        title =
        {
            text = SI_TRADING_HOUSE_CANCEL_LISTING_DIALOG_TITLE,
        },
        buttons =
        {
            [1] =
            {
                control =   GetControl(dialogControl, "Accept"),
                text =      SI_TRADING_HOUSE_CANCEL_LISTING_DIALOG_CONFIRM,
                callback =  function(dialog)
                                CancelTradingHouseListing(dialog.listingIndex)
                                dialog.listingIndex = nil
                            end,
            },

            [2] =
            {
                control =   GetControl(dialogControl, "Cancel"),
                text =      SI_TRADING_HOUSE_CANCEL_LISTING_DIALOG_CANCEL,
                callback =  function(dialog)
                                dialog.listingIndex = nil
                            end,
            }
        }
    })

    -- Update the text on the cancel dialog (since it inherited from the purchase item dialog)
    dialogControl:GetNamedChild("Description"):SetText(GetString(SI_TRADING_HOUSE_CANCEL_LISTING_DIALOG_DESCRIPTION))
end

function ZO_TradingHouseManager:ShowCancelListingConfirmation(listingIndex)
    if(not self.m_cancelListingDialog) then
        self.m_cancelListingDialog = ZO_TradingHouseCancelListingDialog
        CancelListingDialogInitialize(self.m_cancelListingDialog, self)
    end

    self.m_cancelListingDialog.listingIndex = listingIndex
    ZO_Dialogs_ShowDialog("CONFIRM_TRADING_HOUSE_CANCEL_LISTING")
end

--[[
    End of Dialog Section
--]]

function ZO_TradingHouseManager:CanBuyItem(inventorySlot)
    if(not self:IsAtTradingHouse()) then
        return false
    end

    if(inventorySlot.sellerName == self.m_currentDisplayName) then
        return false
    end

    return true
end

function ZO_TradingHouseManager:VerifyBuyItemAndShowErrors(inventorySlot)
    if(inventorySlot.purchasePrice > self.m_playerMoney[inventorySlot.currencyType]) then
        ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, SOUNDS.PLAYER_ACTION_INSUFFICIENT_GOLD, SI_TRADING_HOUSE_ERROR_NOT_ENOUGH_GOLD)
        return false
    end

    return true
end

function ZO_TradingHouseManager:RunInitialSetup(control)
    self.m_leftPane = control:GetNamedChild("LeftPane")

    self.m_noItemsContainer = control:GetNamedChild("ItemPaneNoItemsContainer")
    self.m_noItemsContainer:SetHidden(false)
    self.m_noItemsLabel = self.m_noItemsContainer:GetChild()
    self.m_noItemsLabel:SetHidden(true)
    self.m_noItemsLabelSavedHiddenState = self.m_noItemsLabel:IsHidden()
    self.m_playerMoney = {}

    self:InitializeSharedEvents()
    self:InitializeKeybindDescriptor()
    self:InitializeMenuBar(control)
    self:InitializePostItem(control)
    self:InitializeBrowseItems(control)
    self:InitializeListings(control)
    self:InitializeScene()

    return self
end

local function SetPostPriceCallback(moneyInput, gold, eventType)
    local tradingHouse = moneyInput:GetContext()

    if(eventType == "confirm") then
        tradingHouse:SetPendingPostPrice(gold)
        tradingHouse.m_invoiceSellPrice:SetHidden(false)
    elseif(eventType == "cancel") then
        tradingHouse.m_invoiceSellPrice:SetHidden(false)
    end
end

function ZO_TradingHouseManager:BeginSetPendingPostPrice(anchorTo)
    if(self:HasValidPendingItemPost()) then
        self.m_invoiceSellPrice:SetHidden(true)
        CURRENCY_INPUT:SetContext(self)
        CURRENCY_INPUT:Show(SetPostPriceCallback, false, self:GetPendingPostPrice(), CURT_MONEY, anchorTo, 18)
    end
end

--[[ Overridden Functions ]]--

function ZO_TradingHouseManager:AllowSearch()
    self.m_searchAllowed = true

    if self.m_noItemsLabel then
        self.m_noItemsLabel:SetHidden(true)
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TradingHouse_Shared:InitializeFilterFactory(entry, filterFactory)
    entry.filterObject = filterFactory:New(self.m_browseItems)
end

--[[ Globals ]]--

function ZO_TradingHouse_OnInitialized(self)
    TRADING_HOUSE = ZO_TradingHouseManager:New(self)
    SYSTEMS:RegisterKeyboardObject(ZO_TRADING_HOUSE_SYSTEM_NAME, TRADING_HOUSE)
end