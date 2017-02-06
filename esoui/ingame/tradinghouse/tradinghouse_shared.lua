ZO_TRADING_HOUSE_MODE_BROWSE = 1
ZO_TRADING_HOUSE_MODE_SELL = 2
ZO_TRADING_HOUSE_MODE_LISTINGS = 3

ZO_TRADING_HOUSE_SYSTEM_NAME = "tradingHouse"

ZO_TRADING_HOUSE_INTERACTION =
{
    type = "TradingHouse",
    End = function() self:CloseTradingHouse() end,
    interactTypes = { INTERACTION_TRADINGHOUSE },
}

function ZO_TradingHouse_CreateItemData(index, fn)
    local icon, name, quality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType = fn(index)
    if(name ~= "" and stackCount > 0) then
        local result =
        {
            slotIndex = index,
            icon = icon,
            name = name,
            quality = quality,
            stackCount = stackCount,
            sellerName = sellerName,
            timeRemaining = timeRemaining,
            purchasePrice = purchasePrice,
            currencyType = currencyType or CURT_MONEY
        }

        return result
    end
end

local TRADING_HOUSE_DESIRED_FILTER_ORDERING =
{
    SI_TRADING_HOUSE_BROWSE_ALL_ITEMS,
    SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_WEAPON,
    SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_APPAREL,
    SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_GLYPHS_AND_GEMS,
    SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_CRAFTING,
    SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_GUILD_ITEMS,
    SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_CONSUMABLES,
    SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_FURNISHINGS,
    SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_OTHER,
}

ZO_TRADING_HOUSE_QUALITIES =
{
    { ITEM_QUALITY_TRASH, ITEM_QUALITY_LEGENDARY, SI_TRADING_HOUSE_BROWSE_QUALITY_ANY },
    { ITEM_QUALITY_NORMAL, nil, SI_TRADING_HOUSE_BROWSE_QUALITY_NORMAL },
    { ITEM_QUALITY_MAGIC, nil, SI_TRADING_HOUSE_BROWSE_QUALITY_MAGIC },
    { ITEM_QUALITY_ARCANE, nil, SI_TRADING_HOUSE_BROWSE_QUALITY_ARCANE },
    { ITEM_QUALITY_ARTIFACT, nil, SI_TRADING_HOUSE_BROWSE_QUALITY_ARTIFACT },
    { ITEM_QUALITY_LEGENDARY, nil, SI_TRADING_HOUSE_BROWSE_QUALITY_LEGENDARY },
}
 
ZO_RANGE_COMBO_INDEX_MIN_VALUE = 1
ZO_RANGE_COMBO_INDEX_MAX_VALUE = 2
ZO_RANGE_COMBO_INDEX_TEXT = 3

--[[ 
    Trading House Singleton 
--]]

ZO_TradingHouse_Singleton = ZO_Object:Subclass()

function ZO_TradingHouse_Singleton:New(...)
    local tradingHouse = ZO_Object.New(self)
    tradingHouse:Initialize(...)
    return tradingHouse
end

function ZO_TradingHouse_Singleton:Initialize()
    ZO_TradingHouseFilter_Shared_InitializeData()

    local function OnTradingHouseOpen()
        SYSTEMS:GetObject(ZO_TRADING_HOUSE_SYSTEM_NAME):OpenTradingHouse()
        SYSTEMS:ShowScene(ZO_TRADING_HOUSE_SYSTEM_NAME)
    end

    local function OnCloseTradingHouse()
        SYSTEMS:GetObject(ZO_TRADING_HOUSE_SYSTEM_NAME):CloseTradingHouse()
    end

    EVENT_MANAGER:RegisterForEvent(ZO_TRADING_HOUSE_SYSTEM_NAME, EVENT_OPEN_TRADING_HOUSE, function() OnTradingHouseOpen() end)
    EVENT_MANAGER:RegisterForEvent(ZO_TRADING_HOUSE_SYSTEM_NAME, EVENT_CLOSE_TRADING_HOUSE, function() OnCloseTradingHouse() end)
end

ZO_TRADING_HOUSE_SINGLETON = ZO_TradingHouse_Singleton:New()

--[[
    Trading House Search Field Setter
    Other objects derive from this to call specific methods on a master search object (which then passes data in for the search)

    NOTE: When inheriting from this object, do not call obj:Initialize in your derived New function.  The base object will automatically call the derived object's
    initialize.  In the derived object's Initialize function, that's where the base init should be called; in the form: BaseObj.Initialize(self, ...)
--]]

ZO_TradingHouseSearchFieldSetter = ZO_Object:Subclass()

function ZO_TradingHouseSearchFieldSetter:New(...)
    local setter = ZO_Object.New(self)
    setter:Initialize(...)
    return setter
end

function ZO_TradingHouseSearchFieldSetter:Initialize(filterType)
    self.m_filterType = filterType
end

function ZO_TradingHouseSearchFieldSetter:ApplyToSearch(searchObject)
    local filterType = self.m_filterType
    if(type(filterType) == "function") then
        filterType = filterType()
    end

    searchObject:SetFilter(filterType, self:GetValues())
end

-- Can be overridden
function ZO_TradingHouseSearchFieldSetter:GetValues()
    return self.m_min, self.m_max
end

--[[
    Combo Box Setter
--]]

ZO_TradingHouseComboBoxSetter = ZO_TradingHouseSearchFieldSetter:Subclass()

function ZO_TradingHouseComboBoxSetter:Initialize(filterType, comboBoxObject)
    ZO_TradingHouseSearchFieldSetter.Initialize(self, filterType)
    self.m_comboBox = comboBoxObject
	self.SelectionChanged = ZO_TradingHouse_ComboBoxSelectionChanged
end

function ZO_TradingHouseComboBoxSetter:ApplyToSearch(searchObject)
    local selectedItem = self.m_comboBox:GetSelectedItemData()
    if(selectedItem) then
        self.m_min = selectedItem.minValue
        self.m_max = selectedItem.maxValue
        ZO_TradingHouseSearchFieldSetter.ApplyToSearch(self, searchObject)
    end
end

--[[
    Numeric Range Setter (for Price and Level...)
--]]
ZO_TradingHouse_NumericRangeSetter = ZO_TradingHouseSearchFieldSetter:Subclass()

function ZO_TradingHouse_NumericRangeSetter:New(...)
    return ZO_TradingHouseSearchFieldSetter.New(self, ...)
end

function ZO_TradingHouse_NumericRangeSetter:Initialize(filterType, minEditControl, maxEditControl)
    ZO_TradingHouseSearchFieldSetter.Initialize(self, filterType)
    self.m_minEdit = minEditControl
    self.m_maxEdit = maxEditControl
end

local function GetSafeNumericRange(valMin, valMax)
    if(valMin == nil) then return nil, nil end

    if(valMin == 0) then
        if(valMax ~= nil and valMax > 0) then
            valMin = 1
        end
    end

    if(valMin > 0) then
        if(valMax ~= nil and valMax > 0 and (valMin > valMax)) then
            valMin, valMax = valMax, valMin
        end
    else
        -- TODO: Make valMax the actual max...queries that specify a min without a max are treated as "exact match only"
        -- Requires that max be passed safely.  Right now price and level are the only things using this.
        -- Just return exact value for this one...
        return valMin, nil
    end

    return valMin, valMax
end

function ZO_TradingHouse_NumericRangeSetter:ApplyToSearch(searchObject)
    local minVal = tonumber(self.m_minEdit:GetText())
    local maxVal = tonumber(self.m_maxEdit:GetText())

    self.m_min, self.m_max = GetSafeNumericRange(minVal, maxVal)

    ZO_TradingHouseSearchFieldSetter.ApplyToSearch(self, searchObject)
end

--[[
    TradingHouseShared
--]]

ZO_TradingHouse_Shared = ZO_Object:Subclass()

function ZO_TradingHouse_Shared:New(...)
    local tradingHouse = ZO_Object.New(self)
    tradingHouse:Initialize(...)
    return tradingHouse
end

function ZO_TradingHouse_Shared:Initialize(control)
    self.m_control = control
    self.m_registeredFilterTypes = {}
end

function ZO_TradingHouse_Shared:IsAtTradingHouse()
    return GetInteractionType() == INTERACTION_TRADINGHOUSE
end

function ZO_TradingHouse_Shared:CanDoCommonOperation()
    return not self:IsAwaitingResponse() and self:IsAtTradingHouse()
end

function ZO_TradingHouse_Shared:CanSearch()
    return self:CanDoCommonOperation() and self:IsInSearchMode()
end

function ZO_TradingHouse_Shared:GetCurrentMode()
    return self.m_currentMode
end

function ZO_TradingHouse_Shared:SetCurrentMode(mode)
    self.m_currentMode = mode
end

function ZO_TradingHouse_Shared:IsInSellMode()
    return self.m_currentMode == ZO_TRADING_HOUSE_MODE_SELL
end

function ZO_TradingHouse_Shared:IsInSearchMode()
    return self.m_currentMode == ZO_TRADING_HOUSE_MODE_BROWSE
end

function ZO_TradingHouse_Shared:IsInListingsMode()
    return self.m_currentMode == ZO_TRADING_HOUSE_MODE_LISTINGS
end

function ZO_TradingHouse_Shared:IsAwaitingResponse()
    return self.m_awaitingResponseType ~= nil
end

function ZO_TradingHouse_Shared:IsWaitingForResponseType(responseType)
    return self.m_awaitingResponseType == responseType
end

--Event Handlers

local function ContextFilter(tradingHouse, callback)
    -- This will wrap the callback so that it gets called with the control
    return function(...)
        local activeTradingHouse = SYSTEMS:GetObject(ZO_TRADING_HOUSE_SYSTEM_NAME)

        if (activeTradingHouse == tradingHouse) then
            callback(...)
        end
    end
end

function ZO_TradingHouse_Shared:InitializeSharedEvents()    
    local function OnUpdateStatus()
        self:UpdateStatus()
    end

    local function OnOperationTimeout()
        self:OnOperationTimeout()
    end
    
    local function OnSearchCooldownUpdate(_, cooldownMilliseconds)
        self:OnSearchCooldownUpdate(cooldownMilliseconds)
    end
    
    local function OnPendingPostItemUpdated(_, slotId, isPending)
        self:OnPendingPostItemUpdated(slotId, isPending)
    end
    
    local function OnAwaitingResponse(_, responseType)
        self.m_awaitingResponseType = responseType
        self:OnAwaitingResponse(responseType)
    end
    
    local function OnResponseReceived(_, responseType, result)
        if responseType == self.m_awaitingResponseType then
            self.m_awaitingResponseType = nil
            self:OnResponseReceived(responseType, result)
        end

        if(result ~= TRADING_HOUSE_RESULT_SUCCESS) then
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString("SI_TRADINGHOUSERESULT", result))
        end
    end
    
    local function OnSearchResultsReceived(_, guildId, numItemsOnPage, currentPage, hasMorePages)
        self:OnSearchResultsReceived(guildId, numItemsOnPage, currentPage, hasMorePages)
    end

    local function OnConfirmPendingPurchase(_, pendingPurchaseIndex)
        self:ConfirmPendingPurchase(pendingPurchaseIndex)
    end

   self.m_eventCallbacks = {
        [EVENT_TRADING_HOUSE_STATUS_RECEIVED] = OnUpdateStatus,
        [EVENT_TRADING_HOUSE_OPERATION_TIME_OUT] = OnOperationTimeout,
        [EVENT_TRADING_HOUSE_SEARCH_COOLDOWN_UPDATE] = OnSearchCooldownUpdate,
        [EVENT_TRADING_HOUSE_PENDING_ITEM_UPDATE] = OnPendingPostItemUpdated,
        [EVENT_TRADING_HOUSE_AWAITING_RESPONSE] = OnAwaitingResponse,
        [EVENT_TRADING_HOUSE_RESPONSE_RECEIVED] = OnResponseReceived,
        [EVENT_TRADING_HOUSE_SEARCH_RESULTS_RECEIVED] = OnSearchResultsReceived,
        [EVENT_TRADING_HOUSE_CONFIRM_ITEM_PURCHASE] = OnConfirmPendingPurchase,
    }

    for event, callback in pairs(self.m_eventCallbacks) do
        self.m_control:RegisterForEvent(event, ContextFilter(self, callback))
    end
end

function ZO_TradingHouse_Shared:SetSearchItemCategory(_, _, entry, selectionChanged)
	ZO_TradingHouse_SearchCriteriaChanged(selectionChanged)

    if selectionChanged then
        self:SetSearchActiveFilter(entry.filterObject)
    end
end

function ZO_TradingHouse_Shared:InitializeCategoryComboBox(comboBox, callback, selectFirstItem)
    local function combinedCallback(comboBox, entryName, entry, selectionChanged)
        if callback then
            selectionChanged = callback(comboBox, entryName, entry, selectionChanged)
        end

        self:SetSearchItemCategory(comboBox, entryName, entry, selectionChanged)
    end

    for _, filterStringId in ipairs(TRADING_HOUSE_DESIRED_FILTER_ORDERING) do
        local entry = comboBox:CreateItemEntry(ZO_TradingHouse_GetComboBoxString(filterStringId), combinedCallback)
        self:InitializeEntryFilter(entry, filterStringId)
        comboBox:AddItem(entry)
    end

    if selectFirstItem ~= false then
        comboBox:SelectFirstItem()
    end
end

-- changed == false means the user selected the same combobox item that is currently selected.
-- changed == true means the user either selected a different combobox item from what is currently selected, or changed edit control text.
function ZO_TradingHouse_Shared:HandleSearchCriteriaChanged(changed)
    if changed then
        self:AllowSearch()
    end
end

function ZO_TradingHouse_Shared:RegisterSearchFilter(factory, stringId)
    self.m_registeredFilterTypes[stringId] = factory
end

function ZO_TradingHouse_Shared:InitializeEntryFilter(entry, filterStringId)
    local filterFactory = self.m_registeredFilterTypes[filterStringId]
    if(filterFactory) then
        self:InitializeFilterFactory(entry, filterFactory, filterStringId)
    end
end

function ZO_TradingHouse_Shared:GetSearchActiveFilter()
    return self.m_search:GetActiveFilter()
end

function ZO_TradingHouse_Shared:SetSearchActiveFilter(filter)
    self.m_search:SetActiveFilter(filter)
end

function ZO_TradingHouse_Shared:GetTraitFilters()
    return self.m_traitFilters
end

function ZO_TradingHouse_Shared:GetEnchantmentFilters()
    return self.m_enchantmentFilters
end

function ZO_TradingHouse_Shared:DoSearch()
    self.m_search:DoSearch()
end

function ZO_TradingHouse_Shared:CreateGuildSpecificItemData(index, fn)
    local icon, name, quality, stackCount, requiredLevel, requiredCP, purchasePrice, currencyType = fn(index)
    if(name ~= "") then
        local result =
        {
            slotIndex = index,
            icon = icon,
            name = name,
            quality = quality,
            stackCount = stackCount,
            sellerName = GetString(SI_GUILD_HERALDRY_SELLER_NAME),
            timeRemaining = 0,
            requiredLevel = requiredLevel,
            requiredCP = requiredCP,
            purchasePrice = purchasePrice,
            currencyType = currencyType
        }

        return result
    end
end

function ZO_TradingHouse_Shared:ShouldAddGuildSpecificItemToList(itemData)
    for _, setter in ipairs(self.m_search.m_setters) do
        local filterType = setter.m_filterType
        if(type(filterType) == "function") then
            filterType = filterType()
        end

        if filterType == TRADING_HOUSE_FILTER_TYPE_PRICE then
            if (setter.m_min and itemData.purchasePrice < setter.m_min) or (setter.m_max and itemData.purchasePrice > setter.m_max) then
                return false
            end
        elseif filterType == TRADING_HOUSE_FILTER_TYPE_LEVEL then
            if (setter.m_min and itemData.requiredLevel < setter.m_min) or (setter.m_max and itemData.requiredLevel > setter.m_max) then
                return false
            end
        elseif filterType == TRADING_HOUSE_FILTER_TYPE_CHAMPION_POINTS then
            if (setter.m_min and itemData.requiredCP < setter.m_min) or (setter.m_max and itemData.requiredCP > setter.m_max) then
                return false
            end
        elseif filterType == TRADING_HOUSE_FILTER_TYPE_QUALITY then
            if not setter.m_max then
                return itemData.quality == setter.m_min
            else
                return itemData.quality >= setter.m_min and itemData.quality <= setter.m_max
            end
        end
    end

    return true
end


--[[ Functions to be overridden ]]--

function ZO_TradingHouse_Shared:InitializeSearchTerms()
end

function ZO_TradingHouse_Shared:AllowSearch()
end

function ZO_TradingHouse_Shared:AddGuildSpecificItems(ignoreFiltering)
end

function ZO_TradingHouse_Shared:UpdateForGuildChange()
end

function ZO_TradingHouse_Shared:CloseTradingHouse()
end

function ZO_TradingHouse_Shared:InitializeFilterFactory(entry, filterFactory, filterStringId)
    assert(false) -- must be overridden
end

--[[ Trading House Shared Globals ]]--

function ZO_TradingHouse_FinishLocalString(sString)
	return zo_strformat(SI_DISPLAY_GUILD_STORE_ITEM_NAME, sString)
end

function ZO_TradingHouse_GetComboBoxString(stringData)
    if(type(stringData) == "number") then
        return ZO_TradingHouse_FinishLocalString(GetString(stringData))
    end

    return ZO_TradingHouse_FinishLocalString(stringData)
end

function ZO_TradingHouse_SearchCriteriaChanged(changed)
	if changed == nil then
		changed = true
	end

	SYSTEMS:GetObject(ZO_TRADING_HOUSE_SYSTEM_NAME):HandleSearchCriteriaChanged(changed)
end

function ZO_TradingHouse_InitializeCategoryComboBox(...)
    SYSTEMS:GetObject(ZO_TRADING_HOUSE_SYSTEM_NAME):InitializeCategoryComboBox(...)
end

function ZO_TradingHouse_InitializeColoredComboBox(comboBox, entryData, callback, interfaceColorType, colorIndex, selectFirstItem)
    local color = ZO_ColorDef:New()

    for _, data in ipairs(entryData) do
        local text = ZO_TradingHouse_GetComboBoxString(data[ZO_RANGE_COMBO_INDEX_TEXT])

        if(interfaceColorType ~= nil) then
            color:SetRGB(GetInterfaceColor(interfaceColorType, data[colorIndex]))
            text = color:Colorize(text)
        end

        local entry = comboBox:CreateItemEntry(text, callback)
        entry.minValue = data[ZO_RANGE_COMBO_INDEX_MIN_VALUE]
        entry.maxValue = data[ZO_RANGE_COMBO_INDEX_MAX_VALUE]
        entry.childKey = data[ZO_RANGE_COMBO_INDEX_CHILD_KEY]

        comboBox:AddItem(entry)
    end

    if selectFirstItem ~= false then
        comboBox:SelectFirstItem()
    end
end

function ZO_TradingHouse_ComboBoxSelectionChanged(_, _, _, selectionChanged)
	ZO_TradingHouse_SearchCriteriaChanged(selectionChanged)
end

--[[
    Trading House Search Helper
--]]

ZO_TradingHouseSearch = ZO_Object:Subclass()

function ZO_TradingHouseSearch:New(...)
    local search = ZO_Object.New(self)
    search:Initialize(...)
    return search
end

function ZO_TradingHouseSearch:Initialize()
    self.m_setters = {}
    self.m_filters =
    {
        [TRADING_HOUSE_FILTER_TYPE_EQUIP] = { values = {}, isRange = false, },
        [TRADING_HOUSE_FILTER_TYPE_ITEM] = { values = {}, isRange = false, },
        [TRADING_HOUSE_FILTER_TYPE_WEAPON] = { values = {}, isRange = false, },
        [TRADING_HOUSE_FILTER_TYPE_ARMOR] = { values = {}, isRange = false, },
        [TRADING_HOUSE_FILTER_TYPE_TRAIT] = { values = {}, isRange = false, },
        [TRADING_HOUSE_FILTER_TYPE_QUALITY] = { values = {}, isRange = true, },
        [TRADING_HOUSE_FILTER_TYPE_LEVEL] = { values = {}, isRange = true, },
        [TRADING_HOUSE_FILTER_TYPE_PRICE] = { values = {}, isRange = true, },
        [TRADING_HOUSE_FILTER_TYPE_CHAMPION_POINTS] = { values = {}, isRange = true, },
        [TRADING_HOUSE_FILTER_TYPE_ENCHANTMENT] = { values = {}, isRange = false, },
        [TRADING_HOUSE_FILTER_TYPE_FURNITURE_CATEGORY] = { values = {}, isRange = false, },
        [TRADING_HOUSE_FILTER_TYPE_FURNITURE_SUBCATEGORY] = { values = {}, isRange = false, },
        [TRADING_HOUSE_FILTER_TYPE_SPECIALIZED_ITEM] = { values = {}, isRange = false, },
    }

    self:ResetAllSearchData()
    self:InitializeOrderingData()
end

function ZO_TradingHouseSearch:ResetAllSearchData()
    self:ResetSearchData()
    self:ResetPageData()
end

function ZO_TradingHouseSearch:InitializeOrderingData()
    self.m_sortField = TRADING_HOUSE_SORT_SALE_PRICE
    self.m_sortOrder = ZO_SORT_ORDER_UP
end

function ZO_TradingHouseSearch:ResetSearchData()
    ClearAllTradingHouseSearchTerms()

    for _, filter in pairs(self.m_filters) do
        ZO_ClearNumericallyIndexedTable(filter.values)
    end
end

function ZO_TradingHouseSearch:SetPageData(currentPage, hasMorePages)
    self.m_page = currentPage
    self.m_hasMorePages = hasMorePages
end

function ZO_TradingHouseSearch:ResetPageData()
    self:SetPageData(0, false)
end

function ZO_TradingHouseSearch:HasPreviousPage()
    return self.m_page > 0
end

function ZO_TradingHouseSearch:HasNextPage()
    return self.m_hasMorePages
end

local function AddData(dataTable, ...)
    -- NOTE: At this point each arg must not be a table!
    for i = 1, select("#", ...) do
        dataTable[#dataTable + 1] = select(i, ...)
    end
end

local function SafeUnpack(data)
    if(type(data) == "table") then
        return unpack(data)
    else
        return data
    end
end

function ZO_TradingHouseSearch:SetFilter(filterType, ...)
    local filter = self.m_filters[filterType]
    if(filter) then
        local dataTable = filter.values
        for i = 1, select("#", ...) do
            local data = select(i, ...)
            AddData(dataTable, SafeUnpack(data))
        end
    end
end

function ZO_TradingHouseSearch:AddSetter(setterObject)
    self.m_setters[#self.m_setters + 1] = setterObject
end

function ZO_TradingHouseSearch:GetActiveFilter()
    return self.m_activeFilter
end

function ZO_TradingHouseSearch:SetActiveFilter(filterObject)
    if(self.m_activeFilter) then
        self.m_activeFilter:SetHidden(true)
    end

    if(filterObject) then
        filterObject:SetHidden(false)
    end

    self.m_activeFilter = filterObject
end

function ZO_TradingHouseSearch:DoSearch()
    self:ResetSearchData()
    self:ResetPageData()

    for _, setter in ipairs(self.m_setters) do
        setter:ApplyToSearch(self)
    end

    if(self.m_activeFilter) then
        self.m_activeFilter:ApplyToSearch(self)
    end

    self:InternalExecuteSearch()
end

function ZO_TradingHouseSearch:SearchNextPage()
    if(self.m_hasMorePages) then
        self.m_page = self.m_page + 1
        self.m_hasMorePages = false -- assume there are no more pages after this one, until the search response arrives and updates the data

        self:InternalExecuteSearch()
    end
end

function ZO_TradingHouseSearch:SearchPreviousPage()
    if(self.m_page > 0) then
        self.m_page = self.m_page - 1
        -- No need to adjust more pages...if we're going backwards, there must be more pages (unless all the items after this page got bought?)

        self:InternalExecuteSearch()
    end
end

function ZO_TradingHouseSearch:UpdateSortOption(sortKey, sortOrder)
    self.m_sortField = sortKey
    self.m_sortOrder = sortOrder
end

function ZO_TradingHouseSearch:ChangeSort(sortKey, sortOrder)
    self:UpdateSortOption(sortKey, sortOrder)
    self:InternalExecuteSearch()
end

function ZO_TradingHouseSearch:InternalExecuteSearch()
    for filterType, filter in pairs(self.m_filters) do
        if(filter.isRange) then
            SetTradingHouseFilterRange(filterType, unpack(filter.values))
        else
            SetTradingHouseFilter(filterType, unpack(filter.values))
        end
    end

    if self.m_activeFilter and self.m_activeFilter.customSearchFunction then
        self.m_activeFilter.customSearchFunction()
    else
        ExecuteTradingHouseSearch(self.m_page, self.m_sortField, self.m_sortOrder)
    end

    PlaySound(SOUNDS.TRADING_HOUSE_SEARCH_INITIATED)
end