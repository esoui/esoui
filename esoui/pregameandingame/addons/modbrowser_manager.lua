ZO_MOD_BROWSER_SEARCH_STATES =
{
    NONE = 1,
    WAITING = 2,
    COMPLETE = 3,
    FAILED = 4,
}

------------------------------------
-- Mod Browser Search Filters  -----
------------------------------------

ZO_ModBrowser_Search_Filters = ZO_InitializingObject:Subclass()

function ZO_ModBrowser_Search_Filters:Initialize(searchType)
    self.searchType = searchType
    self.searchText = ""
    self.categories = {}
end

function ZO_ModBrowser_Search_Filters:GetSearchType()
    return self.searchType
end

function ZO_ModBrowser_Search_Filters:SetSearchText(searchText)
    self.searchText = searchText
end

function ZO_ModBrowser_Search_Filters:GetSearchText()
    return self.searchText
end

function ZO_ModBrowser_Search_Filters:SetCategories(categories)
    self.categories = categories
end

function ZO_ModBrowser_Search_Filters:GetCategories()
    return self.categories
end

function ZO_ModBrowser_Search_Filters:ResetFilters()
    self.searchType = MOD_BROWSER_SEARCH_TYPE_BROWSE
    self.searchText = ""
    ZO_ClearNumericallyIndexedTable(self.categories)
end

function ZO_ModBrowser_Search_Filters:CopyFrom(filters)
    if filters:GetSearchType() == self:GetSearchType() then
        self:ResetFilters()

        self.searchText = filters:GetSearchText()
        --Copy by value instead of by reference
        ZO_ShallowTableCopy(filters:GetCategories(), self.categories)
    else
        internalassert(false, "Cannot copy filters with a search type of %d to filters with a search type of %d", filters:GetSearchType(), self:GetSearchType())
    end
end

function ZO_ModBrowser_Search_Filters:PrepareFilters()
    local success = true

    success = success and SetModBrowserSearchType(self.searchType)
    success = success and SetModBrowserTextFilter(self.searchText)
    success = success and SetModBrowserCategoryTypeFilter(unpack(self.categories))

    return success
end

------------------------------------
-- Mod Browser Search Manager ------
------------------------------------

ZO_ModBrowser_Search_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_ModBrowser_Search_Manager:Initialize()
    self.searchResultsData = {}

    self.searchFilterData = 
    {
        [MOD_BROWSER_SEARCH_TYPE_BROWSE] = ZO_ModBrowser_Search_Filters:New(MOD_BROWSER_SEARCH_TYPE_BROWSE),
        [MOD_BROWSER_SEARCH_TYPE_SUBSCRIBED] = ZO_ModBrowser_Search_Filters:New(MOD_BROWSER_SEARCH_TYPE_SUBSCRIBED),
    }

    self.searchState = ZO_MOD_BROWSER_SEARCH_STATES.NONE
    self.searchId = 0

    self:RegisterForEvents()
end

function ZO_ModBrowser_Search_Manager:RegisterForEvents()
    EVENT_MANAGER:RegisterForEvent("ModBrowser_Search_Manager", EVENT_MOD_BROWSER_SEARCH_COMPLETE, ZO_GetEventForwardingFunction(self, self.OnModBrowserSearchResults))
end

function ZO_ModBrowser_Search_Manager:OnModBrowserSearchResults(result, searchId)
    -- Don't update when the search complete event is not for our current search
    if searchId ~= self:GetSearchId() then
        return
    end

    local searchState
    if result == MOD_BROWSER_REQUEST_LISTINGS_RESULT_SUCCESS then
        searchState = ZO_MOD_BROWSER_SEARCH_STATES.COMPLETE
    else
        searchState = ZO_MOD_BROWSER_SEARCH_STATES.FAILED
    end
    local FORCE_UPDATE = true
    self:SetSearchState(searchState, FORCE_UPDATE)
end

function ZO_ModBrowser_Search_Manager:ExecuteSearch(searchType)
    self:ExecuteSearchInternal(searchType)
end

function ZO_ModBrowser_Search_Manager:ExecuteSearchInternal(searchType)
    local filters = self:GetSearchFilters(searchType)
    --Only trigger a new search if the filters were applied successfully
    if filters:PrepareFilters() then
        local searchId = RequestModsSearch()
        if searchId ~= nil then
            self.searchId = searchId
            self:SetSearchState(ZO_MOD_BROWSER_SEARCH_STATES.WAITING)
        end
    end
end

function ZO_ModBrowser_Search_Manager:RefreshSearchResults()
    local resultsData = self.searchResultsData
    ZO_ClearNumericallyIndexedTable(resultsData)

    --Do not populate the search results if there is a search in progress
    if self:IsSearchStateReady() then
        for listingIndex = 1, GetNumModListings() do
            table.insert(resultsData, ZO_ModBrowserListingSearchData:New(listingIndex))
        end
    end
end

function ZO_ModBrowser_Search_Manager:GetSearchResults(optionalSortFunction)
    local resultsData = self.searchResultsData
    if optionalSortFunction then
        local sortedResultsData = ZO_ShallowTableCopy(resultsData)
        table.sort(sortedResultsData, optionalSortFunction)
        return sortedResultsData
    else
        return resultsData
    end
end

function ZO_ModBrowser_Search_Manager:SetSearchState(searchState, forceUpdate)
    if self.searchState ~= searchState or forceUpdate then
        self.searchState = searchState
        self:RefreshSearchResults()
        self:FireCallbacks("OnSearchStateChanged", searchState)
    end
end

function ZO_ModBrowser_Search_Manager:GetSearchState()
    return self.searchState
end

function ZO_ModBrowser_Search_Manager:GetSearchId()
    return self.searchId
end

function ZO_ModBrowser_Search_Manager:IsSearchStateReady()
    return self.searchState == ZO_MOD_BROWSER_SEARCH_STATES.NONE or self.searchState == ZO_MOD_BROWSER_SEARCH_STATES.COMPLETE or self.searchState == ZO_MOD_BROWSER_SEARCH_STATES.FAILED
end

function ZO_ModBrowser_Search_Manager:GetSearchFilters(searchType)
    return self.searchFilterData[searchType]
end

MOD_BROWSER_SEARCH_MANAGER = ZO_ModBrowser_Search_Manager:New()