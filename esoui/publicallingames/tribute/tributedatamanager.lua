ZO_TRIBUTE_PATRON_PROGRESSION_REFRESH_REASON =
{
    INITIALIZED = 1,
    DATA_CHANGED = 2,
}

ZO_TributeDataManager = ZO_InitializingCallbackObject:Subclass()

function ZO_TributeDataManager:Initialize()
    TRIBUTE_DATA_MANAGER = self

    self.searchString = ""
    self.searchResultsVersion = 0

    self.patrons = {}
    self.patronCategories = {}

    self:RegisterForEvents()
    self:RebuildData()
end

function ZO_TributeDataManager:RegisterForEvents()
    local function OnAddOnLoaded(_, name)
        if name == "ZO_Ingame" then
            --TODO Tribute: Add filters like ZO_ItemSetCollectionsDataManager
            EVENT_MANAGER:UnregisterForEvent("ZO_TributeDataManager", EVENT_ADD_ON_LOADED)
        end
    end

    local function OnPatronProgressionDataChanged(_, patronId)
        if patronId then
            local patronData = self:GetTributePatronData(patronId)
            if patronData then
                patronData:RefreshProgressions(ZO_TRIBUTE_PATRON_PROGRESSION_REFRESH_REASON.DATA_CHANGED)
            end
        else
            --If no patron id was provided we need to refresh everything
            for _, patronData in pairs(self.patrons) do
                patronData:RefreshProgressions(ZO_TRIBUTE_PATRON_PROGRESSION_REFRESH_REASON.INITIALIZED)
            end
        end
    end
    EVENT_MANAGER:RegisterForEvent("ZO_TributeDataManager", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
    EVENT_MANAGER:RegisterForEvent("ZO_TributeDataManager", EVENT_COLLECTIBLES_UNLOCK_STATE_CHANGED, function(_, ...) self:OnCollectiblesUnlockStateChanged(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_TributeDataManager", EVENT_TRIBUTE_PATRON_PROGRESSION_DATA_CHANGED, OnPatronProgressionDataChanged)
    EVENT_MANAGER:RegisterForEvent("ZO_TributeDataManager", EVENT_TRIBUTE_PATRONS_SEARCH_RESULTS_READY, function() self:UpdateSearchResults() end)
end

do
    local function GetNextDirtyUnlockStateCollectibleIdIter(_, lastCollectibleId)
        return GetNextDirtyUnlockStateCollectibleId(lastCollectibleId)
    end

    function ZO_TributeDataManager:OnCollectiblesUnlockStateChanged()
        for collectibleId in GetNextDirtyUnlockStateCollectibleIdIter do
            local categoryType = GetCollectibleCategoryType(collectibleId)
            if categoryType == COLLECTIBLE_CATEGORY_TYPE_TRIBUTE_PATRON then
                self:RebuildData()
                break
            end
        end
    end
end

function ZO_TributeDataManager:MarkDataDirty()
    self.isDataDirty = true
    self:FireCallbacks("PatronsDataDirty")
end

function ZO_TributeDataManager:CleanData()
    if self.isDataDirty then
        self:RebuildData()
    end
end

function ZO_TributeDataManager:RebuildData()
    self.isDataDirty = false

    ZO_ClearTable(self.patrons)
    ZO_ClearTable(self.patronCategories)

    -- Load all TributePatrons and their associated objects
    local numPatrons = GetNumTributePatrons()
    for patronIndex = 1, numPatrons do
        local patronId = GetTributePatronIdAtIndex(patronIndex)
        self:InternalGetOrCreateTributePatronData(patronId)
    end

    self:SortCategories()
    self:OnPatronsUpdated()
end

function ZO_TributeDataManager:OnPatronsUpdated()
    self:FireCallbacks("PatronsUpdated")
end

function ZO_TributeDataManager:SortCategories()
    table.sort(self.patronCategories, ZO_TributePatronCategoryData.CompareTo)
    for _, patronCategoryData in ipairs(self.patronCategories) do
        patronCategoryData:SortTributePatronData()
    end
end

-- ZO_TributePatronData

function ZO_TributeDataManager:TributePatronIterator(filterFunctions)
    self:CleanData()
    return ZO_FilteredNonContiguousTableIterator(self.patrons, filterFunctions)
end

function ZO_TributeDataManager:TributePatronCategoryIterator(filterFunctions)
    self:CleanData()
    return ZO_FilteredNonContiguousTableIterator(self.patronCategories, filterFunctions)
end

function ZO_TributeDataManager:GetTributePatronData(patronId)
    self:CleanData()
    return self.patrons[patronId]
end

function ZO_TributeDataManager:InternalGetOrCreateTributePatronData(patronId)
    if patronId and patronId ~= 0 then
        local tributePatronData = self:GetTributePatronData(patronId)
        if not tributePatronData then
            tributePatronData = ZO_TributePatronData:New(patronId)
            self.patrons[patronId] = tributePatronData
        end
        return tributePatronData
    end
end

function ZO_TributeDataManager:GetTributePatronCategoryData(categoryId)
    self:CleanData()
    return self.patronCategories[categoryId]
end

function ZO_TributeDataManager:GetOrCreateTributePatronCategoryData(categoryId)
    if categoryId and categoryId ~= 0 then
        local tributePatronCategoryData = self:GetTributePatronCategoryData(categoryId)
        if not tributePatronCategoryData then
            tributePatronCategoryData = ZO_TributePatronCategoryData:New(categoryId)
            self.patronCategories[categoryId] = tributePatronCategoryData
        end
        return tributePatronCategoryData
    end
end

function ZO_TributeDataManager:OnProgressionUpgradeStatusChanged(patronId, changedProgressions, refreshReason)
    self:FireCallbacks("ProgressionUpgradeStatusChanged", patronId, changedProgressions, refreshReason)
end

-- Search
function ZO_TributeDataManager:GetSearchResultsVersion()
    return self.searchResultsVersion
end

function ZO_TributeDataManager:HasSearchFilter()
    return zo_strlen(self.searchString) > 1
end

function ZO_TributeDataManager:SetSearchString(searchString)
    self.searchString = searchString or ""
    StartTributePatronSearch(self.searchString)
end

function ZO_TributeDataManager:UpdateSearchResults()
    self.searchResultsVersion = self.searchResultsVersion + 1

    for i = 1, GetNumTributePatronSearchResults() do
        local patronId = GetTributePatronSearchResult(i)
        local patronData = self:GetTributePatronData(patronId)
        patronData:SetSearchResultsVersion(self.searchResultsVersion)
    end

    self:FireCallbacks("UpdateSearchResults")
end

-- Global singleton

-- The global singleton moniker is assigned by the Data Manager's constructor in order to
-- allow data objects to reference the singleton during their construction.
ZO_TributeDataManager:New()