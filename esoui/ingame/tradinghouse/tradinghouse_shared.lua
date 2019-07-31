ZO_TRADING_HOUSE_MODE_BROWSE = 1
ZO_TRADING_HOUSE_MODE_SELL = 2
ZO_TRADING_HOUSE_MODE_LISTINGS = 3

ZO_TRADING_HOUSE_SYSTEM_NAME = "tradingHouse"

ZO_TRADING_HOUSE_INTERACTION =
{
    type = "TradingHouse",
    End = function() SYSTEMS:GetObject(ZO_TRADING_HOUSE_SYSTEM_NAME):CloseTradingHouse() end,
    interactTypes = { INTERACTION_TRADINGHOUSE },
}

function ZO_TradingHouse_GetItemDataFormattedName(itemData)
    if not itemData.formattedName then
        itemData.formattedName = zo_strformat(SI_TOOLTIP_ITEM_NAME, itemData.name)
    end
    return itemData.formattedName
end

function ZO_TradingHouse_GetItemDataFormattedTime(itemData)
    local timeString = ZO_FormatTime(itemData.timeRemaining, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT, TIME_FORMAT_PRECISION_TWELVE_HOUR_NO_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
    return ZO_CachedStrFormat(SI_TRADING_HOUSE_BROWSE_ITEM_REMAINING_TIME, timeString)
end

function ZO_TradingHouse_CreateItemData(index, icon, name, quality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType, itemLink, itemUniqueId, purchasePricePerUnit)
    if name ~= "" and stackCount > 0 then
        local UNIT_PRICE_PRECISION = .01
        purchasePricePerUnit = zo_roundToNearest(purchasePricePerUnit, UNIT_PRICE_PRECISION)
        currencyType = currencyType or CURT_MONEY

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
            purchasePricePerUnit = purchasePricePerUnit,
            currencyType = currencyType,
            itemLink = itemLink,
            itemUniqueId = itemUniqueId,
        }

        return result
    end

    return nil
end

function ZO_TradingHouse_CreateListingItemData(index)
    local icon, name, quality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType, itemUniqueId, purchasePricePerUnit = GetTradingHouseListingItemInfo(index)
    local itemLink = GetTradingHouseListingItemLink(index)
    return ZO_TradingHouse_CreateItemData(index, icon, name, quality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType, itemLink, itemUniqueId, purchasePricePerUnit)
end

function ZO_TradingHouse_CreateSearchResultItemData(index)
    local icon, name, quality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType, itemUniqueId, purchasePricePerUnit = GetTradingHouseSearchResultItemInfo(index)
    local itemLink = GetTradingHouseSearchResultItemLink(index)
    return ZO_TradingHouse_CreateItemData(index, icon, name, quality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType, itemLink, itemUniqueId, purchasePricePerUnit)
end

function ZO_TradingHouse_CalculateItemSuggestedPostPrice(bagId, slotIndex)
    -- It would be nice if we could record historical posts made by this character, and recall those prices here.
    local SUGGESTED_VALUE_MULTIPLIER = 3
    local _, stackCount, vendorPricePerUnit = GetItemInfo(bagId, slotIndex)
    return vendorPricePerUnit * stackCount * SUGGESTED_VALUE_MULTIPLIER
end

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
    TradingHouseShared
--]]

ZO_TradingHouse_Shared = ZO_CallbackObject:Subclass()

function ZO_TradingHouse_Shared:New(...)
    local tradingHouse = ZO_CallbackObject.New(self)
    tradingHouse:Initialize(...)
    return tradingHouse
end

function ZO_TradingHouse_Shared:Initialize(control)
    self.control = control
end

function ZO_TradingHouse_Shared:GetCurrentMode()
    return self.currentMode
end

function ZO_TradingHouse_Shared:SetCurrentMode(mode)
    self.currentMode = mode
end

function ZO_TradingHouse_Shared:IsInSellMode()
    return self.currentMode == ZO_TRADING_HOUSE_MODE_SELL
end

function ZO_TradingHouse_Shared:IsInSearchMode()
    return self.currentMode == ZO_TRADING_HOUSE_MODE_BROWSE
end

function ZO_TradingHouse_Shared:IsInListingsMode()
    return self.currentMode == ZO_TRADING_HOUSE_MODE_LISTINGS
end

function ZO_TradingHouse_Shared:CreateGuildSpecificItemData(index, fn)
    local icon, name, quality, stackCount, requiredLevel, requiredCP, purchasePrice, currencyType = fn(index)
    if name ~= "" then
        local UNIT_PRICE_PRECISION = .01
        local purchasePricePerUnit = zo_roundToNearest(purchasePrice / stackCount, UNIT_PRICE_PRECISION)
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
            purchasePricePerUnit = purchasePricePerUnit,
            currencyType = currencyType,
            isGuildSpecificItem = true,
        }

        return result
    end
end

--[[ Functions to be overridden ]]--

function ZO_TradingHouse_Shared:InitializeSearchTerms()
end

function ZO_TradingHouse_Shared:UpdateForGuildChange()
end

function ZO_TradingHouse_Shared:CloseTradingHouse()
end

function ZO_TradingHouse_Shared:SearchForItemLink(itemLink)
    assert(false) -- must be overridden
end


--[[
    Trading House Search Helper
--]]

ZO_TradingHouseSearch = ZO_CallbackObject:Subclass()

function ZO_TradingHouseSearch:New(...)
    local search = ZO_CallbackObject.New(self)
    search:Initialize(...)
    return search
end

function ZO_TradingHouseSearch:Initialize()
    self.hasSearchCooldown = GetTradingHouseCooldownRemaining() > 0

    self:ResetAllSearchData()
    self:InitializeOrderingData()

    EVENT_MANAGER:RegisterForEvent("ZO_TradingHouseSearch", EVENT_TRADING_HOUSE_SEARCH_COOLDOWN_UPDATE, function(_, ...) self:OnSearchCooldownUpdate(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_TradingHouseSearch", EVENT_TRADING_HOUSE_AWAITING_RESPONSE, function(_, ...) self:OnAwaitingResponse(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_TradingHouseSearch", EVENT_TRADING_HOUSE_RESPONSE_TIMEOUT, function(_, ...) self:OnResponseTimeout(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_TradingHouseSearch", EVENT_TRADING_HOUSE_RESPONSE_RECEIVED, function(_, ...) self:OnResponseReceived(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_TradingHouseSearch", EVENT_TRADING_HOUSE_SELECTED_GUILD_CHANGED, function(_, ...) self:OnSelectedGuildChanged(...) end)
end

function ZO_TradingHouseSearch:AssociateWithSearchFeatures(features)
    self.features = features

    -- update search filter/name match state to reflect new features
    local NOT_CHANGED_BY_FEATURE = nil
    self:HandleSearchCriteriaChanged(NOT_CHANGED_BY_FEATURE)
end

function ZO_TradingHouseSearch:DisassociateWithSearchFeatures()
    self:ClearAwaitingResponseType()
    self:CancelPendingSearch()
    self:ResetAllSearchData()
    self.features = nil
end

function ZO_TradingHouseSearch:OnSearchCooldownUpdate(cooldownMilliseconds)
    self.hasSearchCooldown = cooldownMilliseconds > 0
end

function ZO_TradingHouseSearch:OnAwaitingResponse(responseType)
    self:SetAwaitingResponseType(responseType)
    self:FireCallbacks("OnAwaitingResponse", responseType)
end

function ZO_TradingHouseSearch:OnResponseTimeout()
    self.awaitingResponseTimedOut = true
    self:FireCallbacks("OnResponseTimeout")
end

function ZO_TradingHouseSearch:OnResponseReceived(responseType, result)
    if self:IsWaitingForResponseType(responseType) then
        self:ClearAwaitingResponseType()

        if responseType == TRADING_HOUSE_RESULT_PURCHASE_PENDING and result == TRADING_HOUSE_RESULT_SUCCESS then
            if AreAllTradingHouseSearchResultsPurchased() then
                self:SetSearchState(TRADING_HOUSE_SEARCH_STATE_COMPLETE, TRADING_HOUSE_SEARCH_OUTCOME_ALL_RESULTS_PURCHASED)
            end
        elseif responseType == TRADING_HOUSE_RESULT_SEARCH_PENDING and result == TRADING_HOUSE_RESULT_SUCCESS then
            self.numItemsOnPage, self.page, self.hasMorePages = GetTradingHouseSearchResultsInfo()
            local searchOutcome = (self.numItemsOnPage == 0) and TRADING_HOUSE_SEARCH_OUTCOME_NO_RESULTS or TRADING_HOUSE_SEARCH_OUTCOME_HAS_RESULTS
            self:SetSearchState(TRADING_HOUSE_SEARCH_STATE_COMPLETE, searchOutcome)
        end

        self:FireCallbacks("OnResponseReceived", responseType, result)
    end
end

function ZO_TradingHouseSearch:OnSelectedGuildChanged()
    self:ResetAllSearchData()
    self:FireCallbacks("OnSelectedGuildChanged")
end

function ZO_TradingHouseSearch:HandleSearchCriteriaChanged(changedByFeature)
    if self.features and changedByFeature ~= self.features.nameSearchFeature then
        -- Update filters so name matching can cross-reference the search text with the non-search features.
        local NOT_PERFORMING_SEARCH = false
        self:ApplyFilters(NOT_PERFORMING_SEARCH)
    end
    self:FireCallbacks("OnSearchCriteriaChanged", changedByFeature)
end

function ZO_TradingHouseSearch:GetSearchState()
    return self.searchState
end

function ZO_TradingHouseSearch:SetSearchState(searchState, searchOutcome)
    searchOutcome = searchOutcome or self.searchOutcome
    if self.searchState ~= searchState or self.searchOutcome ~= searchOutcome then
        self.searchOutcome = searchOutcome
        self.searchState  = searchState
        self:FireCallbacks("OnSearchStateChanged", searchState, searchOutcome)
    end
end

function ZO_TradingHouseSearch:GetSearchOutcome()
    return self.searchOutcome
end

function ZO_TradingHouseSearch:ResetAllSearchData()
    self:ResetAppliedSearchTerms()
    self:ResetPageData()
    self:SetSearchState(TRADING_HOUSE_SEARCH_STATE_NONE)
end

function ZO_TradingHouseSearch:InitializeOrderingData()
    self.sortField = TRADING_HOUSE_SORT_SALE_PRICE_PER_UNIT
    self.sortOrder = ZO_SORT_ORDER_UP
    self.useLastExecutedSearchFilters = false
end

function ZO_TradingHouseSearch:ResetAppliedSearchTerms()
    ClearAllTradingHouseSearchTerms()
    self:SetShouldShowGuildSpecificItems(false)
end

function ZO_TradingHouseSearch:SetFilter(filterType, filterValueArg)
    if type(filterValueArg) == "table" then
        local maxExactTerms, numExactTerms = GetMaxTradingHouseFilterExactTerms(filterType), #filterValueArg
        internalassert(maxExactTerms >= numExactTerms, "Too many filter arguments")
        SetTradingHouseFilter(filterType, unpack(filterValueArg))
    else
        SetTradingHouseFilter(filterType, filterValueArg)
    end
end

function ZO_TradingHouseSearch:SetFilterRange(filterType, minValue, maxValue)
    SetTradingHouseFilterRange(filterType, minValue, maxValue)
end

function ZO_TradingHouseSearch:SetShouldShowGuildSpecificItems(includeGuildSpecificItems)
    self.includeGuildSpecificItems = includeGuildSpecificItems
end

function ZO_TradingHouseSearch:ShouldShowGuildSpecificItems()
    return self.includeGuildSpecificItems
end

function ZO_TradingHouseSearch:LoadSearchTable(searchTable)
    for _, feature in pairs(self.features) do
        feature:LoadFromTable(searchTable)
    end
end

function ZO_TradingHouseSearch:LoadSearchItem(itemLink)
    for _, feature in pairs(self.features) do
        feature:LoadFromItem(itemLink)
    end
end

do
    local function TryInsert(numericallyIndexedTable, valueOrNil)
        if valueOrNil ~= nil then
            table.insert(numericallyIndexedTable, valueOrNil)
        end
    end

    function ZO_TradingHouseSearch:GenerateSearchTableShortDescription(searchTable)
        local nameSearchFeature = self.features.nameSearchFeature
        local categoryFeature = self.features.searchCategoryFeature

        local descriptionStrings = {}
        TryInsert(descriptionStrings, nameSearchFeature:GetDescriptionFromTable(searchTable))
        TryInsert(descriptionStrings, categoryFeature:GetCategoryDescriptionFromTable(searchTable))

        return ZO_GenerateCommaSeparatedListWithoutAnd(descriptionStrings)
    end
end

do
    local function AddFeatureDescription(feature, searchTable, featureDescriptions)
        local description = feature:GetDescriptionFromTable(searchTable)
        if description ~= nil then
            table.insert(featureDescriptions, {name = feature:GetDisplayName(), description = description})
        end
    end

    function ZO_TradingHouseSearch:GenerateSearchTableDescription(searchTable)
        local descriptions = {}
        AddFeatureDescription(self.features.nameSearchFeature, searchTable, descriptions)

        self.features.searchCategoryFeature:AddContextualFeatureDescriptionsFromTable(searchTable, descriptions)

        AddFeatureDescription(self.features.qualityFeature, searchTable, descriptions)
        AddFeatureDescription(self.features.priceRangeFeature, searchTable, descriptions)

        local descriptionLines = {}
        for _, descriptionTable in ipairs(descriptions) do
            table.insert(descriptionLines, zo_strformat(SI_TRADING_HOUSE_SEARCH_DESCRIPTION_LINE, descriptionTable.name, descriptionTable.description))
        end
        return ZO_GenerateNewlineSeparatedList(descriptionLines)
    end
end

function ZO_TradingHouseSearch:ApplyFilters(isPerformingSearch)
    self:ResetAppliedSearchTerms()

    for _, feature in pairs(self.features) do
        feature:ApplyToSearch(self, isPerformingSearch)
    end
end

function ZO_TradingHouseSearch:CreateSearchTable()
    local searchTable = {}
    for _, feature in pairs(self.features) do
        feature:SaveToTable(searchTable)
    end
    return searchTable
end

function ZO_TradingHouseSearch:ResetPageData()
    self.page = 0
    self.numItemsOnPage = 0
    self.hasMorePages = false
end

function ZO_TradingHouseSearch:HasPreviousPage()
    return self.page > 0
end

function ZO_TradingHouseSearch:HasNextPage()
    return self.hasMorePages
end

function ZO_TradingHouseSearch:GetNumItemsOnPage()
    return self.numItemsOnPage
end

function ZO_TradingHouseSearch:GetPage()
    return self.page
end

function ZO_TradingHouseSearch:GetTargetPage()
    return self.targetPage
end

function ZO_TradingHouseSearch:GetSortOptions(sortKey, sortOrder)
    return self.sortField, self.sortOrder
end

function ZO_TradingHouseSearch:SearchNextPage()
    if self.hasMorePages then
        self.targetPage = self.page + 1
        self.useLastExecutedSearchFilters = true
        self:DoSearch()
    end
end

function ZO_TradingHouseSearch:SearchPreviousPage()
    if self.page > 0 then
        self.targetPage = self.page - 1
        self.useLastExecutedSearchFilters = true
        self:DoSearch()
    end
end

function ZO_TradingHouseSearch:ChangeSort(sortKey, sortOrder)
    self.sortField = sortKey
    self.sortOrder = sortOrder
    -- Don't search unless we have already searched once
    if self:GetSearchState() ~= TRADING_HOUSE_SEARCH_STATE_NONE then
        self.useLastExecutedSearchFilters = true
        self:DoSearch()
    end
end

function ZO_TradingHouseSearch:DoSearchWhenReady()
    if not self.waitingToSearch then
        self.waitingToSearch = true
        EVENT_MANAGER:RegisterForUpdate("ZO_TradingHouseSearch", 10, function()
            if self:CanPerformSearch() then
                self.waitingToSearch = false
                EVENT_MANAGER:UnregisterForUpdate("ZO_TradingHouseSearch")

                local QUEUED_SEARCH = true
                self:DoSearch(QUEUED_SEARCH)
            end
        end)
    end
end

function ZO_TradingHouseSearch:CancelPendingSearch()
    if self.waitingToSearch then
        self.waitingToSearch = false
        EVENT_MANAGER:UnregisterForUpdate("ZO_TradingHouseSearch")
        self:FireCallbacks("OnSearchRequestCanceled")
        self:SetSearchState(TRADING_HOUSE_SEARCH_STATE_NONE)
    end
end

function ZO_TradingHouseSearch:DoSearch(isQueuedSearch)
    self:ResetPageData()

    -- Start search visually. This is unnecessary if we're executing a queued search, because we will have already started this search
    if not isQueuedSearch then
        self:FireCallbacks("OnSearchRequested")
        self:SetSearchState(TRADING_HOUSE_SEARCH_STATE_WAITING)
        PlaySound(SOUNDS.TRADING_HOUSE_SEARCH_INITIATED)
    end

    local nameSearchFeature = self.features.nameSearchFeature
    local isNameMatchValid, searchOutcome = nameSearchFeature:IsNameMatchValid()
    if not isNameMatchValid then
        -- This name match could never return any results, early out
        PlaySound(SOUNDS.GENERAL_ALERT_ERROR)
        self:SetSearchState(TRADING_HOUSE_SEARCH_STATE_COMPLETE, searchOutcome)
        return
    end

    if nameSearchFeature:IsNameMatchTruncated() then
        local NO_SOUND = nil
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, NO_SOUND, GetString(SI_TRADING_HOUSE_SEARCH_TRUNCATED))
    end

    -- Skip searches where we don't actually use the current filters, or
    -- searches that have already been saved and queued. In both of these cases
    -- the player would have already created a history entry when they first did
    -- the search.
    if not self.useLastExecutedSearchFilters and not isQueuedSearch then
        TRADING_HOUSE_SEARCH_HISTORY_MANAGER:SaveToHistory(self:CreateSearchTable())
    end

    if self:ShouldShowGuildSpecificItems() then
        -- Guild specific items are loaded when the trading house is opened, so we can skip directly to the search results without triggering a search request
        local guildItemSearchOutcome = GetNumGuildSpecificItems() == 0 and TRADING_HOUSE_SEARCH_OUTCOME_NO_RESULTS or TRADING_HOUSE_SEARCH_OUTCOME_HAS_RESULTS
        self:SetSearchState(TRADING_HOUSE_SEARCH_STATE_COMPLETE, guildItemSearchOutcome)
        return
    end

    if not self:CanPerformSearch() then
        self:DoSearchWhenReady()
    else
        --Don't need to apply current filters if we are using the last executed filters. Applying filters also wipes the last executed filters so we don't want to do that.
        if not self.useLastExecutedSearchFilters then
            local IS_PERFORMING_SEARCH = true
            self:ApplyFilters(IS_PERFORMING_SEARCH)
        end
        local page = self.targetPage or 0
        ExecuteTradingHouseSearch(page, self.sortField, self.sortOrder, self.useLastExecutedSearchFilters)
        self.targetPage = nil
        self.useLastExecutedSearchFilters = false
    end
end

function ZO_TradingHouseSearch:HasSearchCooldown()
    return self.hasSearchCooldown
end

function ZO_TradingHouseSearch:IsAtTradingHouse()
    return GetInteractionType() == INTERACTION_TRADINGHOUSE
end

function ZO_TradingHouseSearch:CanPerformSearch()
    return self:CanDoCommonOperation() and not (self:HasSearchCooldown() or self.features.nameSearchFeature:HasPendingNameMatch())
end

function ZO_TradingHouseSearch:CanDoCommonOperation()
    return (not self:IsAwaitingResponse() or self.awaitingResponseTimedOut) and self:IsAtTradingHouse()
end

function ZO_TradingHouseSearch:IsAwaitingResponse()
    return self.awaitingResponseType ~= nil
end

function ZO_TradingHouseSearch:IsWaitingForResponseType(responseType)
    return self.awaitingResponseType == responseType
end

function ZO_TradingHouseSearch:GetAwaitingResponseType()
    return self.awaitingResponseType
end

function ZO_TradingHouseSearch:SetAwaitingResponseType(responseType)
    self.awaitingResponseType = responseType
    self.awaitingResponseTimedOut = false
end

function ZO_TradingHouseSearch:ClearAwaitingResponseType()
    self.awaitingResponseType = nil
    self.awaitingResponseTimedOut = false
end

TRADING_HOUSE_SEARCH = ZO_TradingHouseSearch:New()