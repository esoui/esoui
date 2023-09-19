ZO_GROUP_FINDER_SEARCH_STATES =
{
    NONE = 1,
    QUEUED = 2,
    WAITING = 3,
    COMPLETE = 4,
}

ZO_GroupFinder_Search_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_GroupFinder_Search_Manager:Initialize()
    self.searchResultsData = {}
    self.searchState = ZO_GROUP_FINDER_SEARCH_STATES.NONE

    self:RegisterForEvents()
end

function ZO_GroupFinder_Search_Manager:RegisterForEvents()
    local function OnGroupFinderSearchResults(_, result, searchId)
        -- Don't update when the search complete event is not for our current search or we are waiting to do a new search immediately
        if self.searchState == ZO_GROUP_FINDER_SEARCH_STATES.QUEUED or searchId ~= self.currentSearchId then
            return
        end

        local FORCE_UPDATE = true
        self:SetSearchState(ZO_GROUP_FINDER_SEARCH_STATES.COMPLETE, FORCE_UPDATE)
        self:FireCallbacks("OnGroupFinderSearchResultsReady")
    end

    local function OnGroupFinderSearchResultsUpdated(_, searchId)
        if searchId == self.currentSearchId then
            self:FireCallbacks("OnGroupFinderSearchResultsUpdated")
        end
    end

    local function OnGroupFinderSearchCooldownUpdate(_, cooldownTimeMs)
        if self:IsSearchStateReady() and cooldownTimeMs > 0 then
            self:SetSearchState(ZO_GROUP_FINDER_SEARCH_STATES.WAITING)
        elseif self.searchState == ZO_GROUP_FINDER_SEARCH_STATES.QUEUED and cooldownTimeMs == 0 then
            self:ExecuteSearchInternal()
        end
    end

    --TODO GroupFinder: Verify which additional events we need to listen for
    EVENT_MANAGER:RegisterForEvent("GroupFinder_Search_Manager", EVENT_GROUP_FINDER_SEARCH_COMPLETE, OnGroupFinderSearchResults)
    EVENT_MANAGER:RegisterForEvent("GroupFinder_Search_Manager", EVENT_GROUP_FINDER_SEARCH_UPDATED, OnGroupFinderSearchResultsUpdated)
    EVENT_MANAGER:RegisterForEvent("GroupFinder_Search_Manager", EVENT_GROUP_FINDER_SEARCH_COOLDOWN_UPDATE, OnGroupFinderSearchCooldownUpdate)
end

function ZO_GroupFinder_Search_Manager:ExecuteSearch()
    if self:CanSearchGroups() then
        self:ExecuteSearchInternal()
    else
        self:SetSearchState(ZO_GROUP_FINDER_SEARCH_STATES.QUEUED)
    end
end

function ZO_GroupFinder_Search_Manager:ExecuteSearchInternal()
    local searchId = RequestGroupFinderSearch()
    if searchId ~= nil then
        self.currentSearchId = searchId
        self:SetSearchState(ZO_GROUP_FINDER_SEARCH_STATES.WAITING)
    end
end

function ZO_GroupFinder_Search_Manager:RefreshSearchResults()
    ZO_ClearNumericallyIndexedTable(self.searchResultsData)

    --Do not populate the search results if there is a search in progress
    if self:IsSearchStateReady() then
        for listingIndex = 1, GetGroupFinderSearchNumListings() do
            table.insert(self.searchResultsData, ZO_GroupListingSearchData:New(listingIndex))
        end
    end
end

function ZO_GroupFinder_Search_Manager:GetSearchResults()
    return self.searchResultsData
end

function ZO_GroupFinder_Search_Manager:SetSearchState(searchState, forceUpdate)
    if self.searchState ~= searchState or forceUpdate then
        self.searchState = searchState
        self:RefreshSearchResults()
        self:FireCallbacks("OnSearchStateChanged", searchState)
    end
end

function ZO_GroupFinder_Search_Manager:GetSearchState()
    return self.searchState
end

function ZO_GroupFinder_Search_Manager:IsSearchStateReady()
    return self.searchState == ZO_GROUP_FINDER_SEARCH_STATES.NONE or self.searchState == ZO_GROUP_FINDER_SEARCH_STATES.COMPLETE
end

function ZO_GroupFinder_Search_Manager:CanSearchGroups()
    return not IsGroupFinderSearchOnCooldown()
end

GROUP_FINDER_SEARCH_MANAGER = ZO_GroupFinder_Search_Manager:New()