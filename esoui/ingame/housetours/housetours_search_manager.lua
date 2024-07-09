ZO_HOUSE_TOURS_SEARCH_STATES =
{
    NONE = 1,
    QUEUED = 2,
    WAITING = 3,
    COMPLETE = 4,
}

------------------------------------
-- House Tours Search Filters  -----
------------------------------------

ZO_HouseTours_Search_Filters = ZO_InitializingObject:Subclass()

function ZO_HouseTours_Search_Filters:Initialize(listingType)
    self.listingType = listingType
    self.displayName = ""
    self.tags = {}
    self.houseIds = {}
    self.houseCategoryTypes = {}
end

function ZO_HouseTours_Search_Filters:GetListingType()
    return self.listingType
end

function ZO_HouseTours_Search_Filters:SetDisplayName(displayName)
    --TODO House Tours: Do we want to do validation here?
    self.displayName = displayName
end

function ZO_HouseTours_Search_Filters:GetDisplayName()
    return self.displayName
end

function ZO_HouseTours_Search_Filters:SetTags(tags)
    self.tags = tags
end

function ZO_HouseTours_Search_Filters:GetTags()
    return self.tags
end

function ZO_HouseTours_Search_Filters:SetHouseIds(houseIds)
    --House ids and house category types are mutually exclusive
    if #houseIds > 0 then
        ZO_ClearNumericallyIndexedTable(self.houseCategoryTypes)
    end

    self.houseIds = houseIds
end

function ZO_HouseTours_Search_Filters:GetHouseIds()
    return self.houseIds
end

function ZO_HouseTours_Search_Filters:CanSetHouseCategoryTypes()
    return #self.houseIds == 0
end

function ZO_HouseTours_Search_Filters:SetHouseCategoryTypes(houseCategoryTypes)
    --Only set the house category types if we haven't set anything for house ids
    if self:CanSetHouseCategoryTypes() then
        self.houseCategoryTypes = houseCategoryTypes
    end
end

function ZO_HouseTours_Search_Filters:GetHouseCategoryTypes()
    return self.houseCategoryTypes
end

function ZO_HouseTours_Search_Filters:ResetFilters()
    self.displayName = ""
    ZO_ClearNumericallyIndexedTable(self.tags)
    ZO_ClearNumericallyIndexedTable(self.houseIds)
    ZO_ClearNumericallyIndexedTable(self.houseCategoryTypes)
end

function ZO_HouseTours_Search_Filters:CopyFrom(filters)
    if filters:GetListingType() == self:GetListingType() then
        self:ResetFilters()
        self.displayName = filters:GetDisplayName()
        --Copy by value instead of by reference
        ZO_ShallowTableCopy(filters:GetTags(), self.tags)
        ZO_ShallowTableCopy(filters:GetHouseIds(), self.houseIds)
        ZO_ShallowTableCopy(filters:GetHouseCategoryTypes(), self.houseCategoryTypes)
    else
        internalassert(false, "Cannot copy filters with a listing type of %d to filters with a listing type of %d", filters:GetListingType(), self:GetListingType())
    end
end

function ZO_HouseTours_Search_Filters:PrepareFilters()
    local success = true
    
    success = success and SetHouseToursDisplayNameFilter(self.listingType, self.displayName)
    success = success and SetHouseToursTagFilter(self.listingType, unpack(self.tags))
    success = success and SetHouseToursHouseIdFilter(self.listingType, unpack(self.houseIds))
    success = success and SetHouseToursCategoryTypeFilter(self.listingType, unpack(self.houseCategoryTypes))

    return success
end

------------------------------------
-- House Tours Search Manager ------
------------------------------------

ZO_HouseTours_Search_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_HouseTours_Search_Manager:Initialize()
    self.searchResultsData = 
    {
        [HOUSE_TOURS_LISTING_TYPE_RECOMMENDED] = {},
        [HOUSE_TOURS_LISTING_TYPE_BROWSE] = {},
        [HOUSE_TOURS_LISTING_TYPE_FAVORITE] = {},
    }

    self.searchFilterData  =
    {
        [HOUSE_TOURS_LISTING_TYPE_RECOMMENDED] = ZO_HouseTours_Search_Filters:New(HOUSE_TOURS_LISTING_TYPE_RECOMMENDED),
        [HOUSE_TOURS_LISTING_TYPE_BROWSE] = ZO_HouseTours_Search_Filters:New(HOUSE_TOURS_LISTING_TYPE_BROWSE),
        [HOUSE_TOURS_LISTING_TYPE_FAVORITE] = ZO_HouseTours_Search_Filters:New(HOUSE_TOURS_LISTING_TYPE_FAVORITE),
    }

    self.searchState = 
    {
        [HOUSE_TOURS_LISTING_TYPE_RECOMMENDED] = ZO_HOUSE_TOURS_SEARCH_STATES.NONE,
        [HOUSE_TOURS_LISTING_TYPE_BROWSE] = ZO_HOUSE_TOURS_SEARCH_STATES.NONE,
        [HOUSE_TOURS_LISTING_TYPE_FAVORITE] = ZO_HOUSE_TOURS_SEARCH_STATES.NONE,
    }

    self.sortTypes =
    {
        [HOUSE_TOURS_LISTING_TYPE_RECOMMENDED] = HOUSE_TOURS_LISTING_SORT_TYPE_NONE,
        [HOUSE_TOURS_LISTING_TYPE_BROWSE] = HOUSE_TOURS_LISTING_SORT_TYPE_NONE,
        [HOUSE_TOURS_LISTING_TYPE_FAVORITE] = HOUSE_TOURS_LISTING_SORT_TYPE_NONE,
    }

    self.searchIds = {}

    self:RegisterForEvents()
end

do
    --Determines the order in which we attempt to run queued listing searches once the cooldown ends. The types less likely to result in a new cooldown are prioritized first
    local LISTING_TYPE_QUEUE_ORDER =
    {
        HOUSE_TOURS_LISTING_TYPE_FAVORITE,
        HOUSE_TOURS_LISTING_TYPE_RECOMMENDED,
        HOUSE_TOURS_LISTING_TYPE_BROWSE,
    }

    function ZO_HouseTours_Search_Manager:RegisterForEvents()
        local function OnHouseToursSaveFavoriteOperationComplete(eventType, operationType, operationResult)
            if operationResult == HOUSE_TOURS_SAVE_FAVORITE_RESULT_SUCCESS then
                -- Refresh the favorites list.
                self:FireCallbacks("OnFavoritesChanged")
            end
        end

        local function OnHouseToursSearchCooldownComplete()
            -- Attempt to run deferred search(es).
            for _, listingType in ipairs(LISTING_TYPE_QUEUE_ORDER) do
                if self:GetSearchState(listingType) == ZO_HOUSE_TOURS_SEARCH_STATES.QUEUED then
                    self:ExecuteSearch(listingType)
                end
            end
        end

        EVENT_MANAGER:RegisterForEvent("HouseTours_Search_Manager", EVENT_HOUSE_TOURS_SAVE_FAVORITE_OPERATION_COMPLETE, OnHouseToursSaveFavoriteOperationComplete)
        EVENT_MANAGER:RegisterForEvent("HouseTours_Search_Manager", EVENT_HOUSE_TOURS_SEARCH_COOLDOWN_COMPLETE, OnHouseToursSearchCooldownComplete)
        EVENT_MANAGER:RegisterForEvent("HouseTours_Search_Manager", EVENT_HOUSE_TOURS_SEARCH_COMPLETE, ZO_GetEventForwardingFunction(self, self.OnHouseToursSearchResults))
    end
end

function ZO_HouseTours_Search_Manager:OnHouseToursSearchResults(listingType, result, searchId)
    -- Don't update when the search complete event is not for our current search or we are waiting to do a new search immediately
    if self:GetSearchState(listingType) == ZO_HOUSE_TOURS_SEARCH_STATES.QUEUED or searchId ~= self:GetSearchId(listingType) then
        return
    end

    local FORCE_UPDATE = true
    self:SetSearchState(ZO_HOUSE_TOURS_SEARCH_STATES.COMPLETE, listingType, FORCE_UPDATE)
end

function ZO_HouseTours_Search_Manager:ExecuteSearch(listingType)
    if self:CanSearchHouses() then
        self:ExecuteSearchInternal(listingType)
    else
        self:SetSearchState(ZO_HOUSE_TOURS_SEARCH_STATES.QUEUED, listingType)
    end
end

function ZO_HouseTours_Search_Manager:ExecuteSearchInternal(listingType)
    local filters = self:GetSearchFilters(listingType)
    --Only trigger a new search if the filters were applied successfully
    if filters:PrepareFilters() then
        local searchId = RequestHouseToursSearch(listingType)
        if searchId ~= nil then
            self.searchIds[listingType] = searchId
            self:SetSearchState(ZO_HOUSE_TOURS_SEARCH_STATES.WAITING, listingType)
        end
    end
end

function ZO_HouseTours_Search_Manager:RefreshSearchResults(listingType)
    local resultsData = self.searchResultsData[listingType]
    ZO_ClearNumericallyIndexedTable(resultsData)

    --Do not populate the search results if there is a search in progress
    if self:IsSearchStateReady(listingType) then
        for listingIndex = 1, GetNumHouseToursSearchListings(listingType) do
            table.insert(resultsData, ZO_HouseToursListingSearchData:New(listingType, listingIndex))
        end
    end
end

function ZO_HouseTours_Search_Manager:GetSearchResults(listingType, optionalSortFunction)
    local resultsData = self.searchResultsData[listingType]
    if optionalSortFunction then
        local sortedResultsData = ZO_ShallowTableCopy(resultsData)
        table.sort(sortedResultsData, optionalSortFunction)
        return sortedResultsData
    else
        return resultsData
    end
end

do
    internalassert(HOUSE_TOURS_LISTING_SORT_TYPE_ITERATION_END == 2, "A new house tours sort type has been added. Please update the SORT_FUNCTIONS table")
    local SORT_FUNCTIONS =
    {
        [HOUSE_TOURS_LISTING_SORT_TYPE_FURNITURE_COUNT] = function(left, right)
            --Treat nil as -1 so unknown values sort to the bottom
            local leftFurnitureCount = left:GetFurnitureCount() or -1
            local rightFurnitureCount = right:GetFurnitureCount() or -1

            if leftFurnitureCount == rightFurnitureCount then
                return left:GetListingIndex() < right:GetListingIndex()
            else
                return leftFurnitureCount > rightFurnitureCount
            end
        end,
        [HOUSE_TOURS_LISTING_SORT_TYPE_HOUSE_NAME] = function(left, right)
            local leftHouseName = left:GetHouseName()
            local rightHouseName = right:GetHouseName()
            if leftHouseName == rightHouseName then
                return left:GetListingIndex() < right:GetListingIndex()
            else
                return leftHouseName < rightHouseName
            end
        end,
    }

    function ZO_HouseTours_Search_Manager:GetSortedSearchResults(listingType)
        local sortType = self.sortTypes[listingType]
        local sortFunction = SORT_FUNCTIONS[sortType]
        return self:GetSearchResults(listingType, sortFunction)
    end
end

function ZO_HouseTours_Search_Manager:SetSearchState(searchState, listingType, forceUpdate)
    if self.searchState[listingType] ~= searchState or forceUpdate then
        self.searchState[listingType] = searchState
        self:RefreshSearchResults(listingType)
        self:FireCallbacks("OnSearchStateChanged", searchState, listingType)
    end
end

function ZO_HouseTours_Search_Manager:GetSearchState(listingType)
    return self.searchState[listingType]
end

function ZO_HouseTours_Search_Manager:GetSearchId(listingType)
    return self.searchIds[listingType] or 0
end

function ZO_HouseTours_Search_Manager:IsSearchStateReady(listingType)
    return self.searchState[listingType] == ZO_HOUSE_TOURS_SEARCH_STATES.NONE or self.searchState[listingType] == ZO_HOUSE_TOURS_SEARCH_STATES.COMPLETE
end

function ZO_HouseTours_Search_Manager:CanSearchHouses()
    return not IsHouseToursSearchOnCooldown()
end

function ZO_HouseTours_Search_Manager:GetSearchFilters(listingType)
    return self.searchFilterData[listingType]
end

function ZO_HouseTours_Search_Manager:SetSortType(listingType, sortType)
    self.sortTypes[listingType] = sortType
end

function ZO_HouseTours_Search_Manager:GetSortType(listingType)
    return self.sortTypes[listingType]
end

function ZO_HouseTours_Search_Manager:GetNextSortType(listingType)
    local currentSortType = self:GetSortType(listingType)
    return (currentSortType + 1) % (HOUSE_TOURS_LISTING_SORT_TYPE_ITERATION_END + 1)
end

HOUSE_TOURS_SEARCH_MANAGER = ZO_HouseTours_Search_Manager:New()