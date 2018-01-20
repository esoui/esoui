--
--[[ CollectionsBook Singleton ]]--
--

ZO_COLLECTIONS_SYSTEM_NAME = "collections"
ZO_COLLECTIONS_SEARCH_ROOT = "root"

local CollectionsBook_Singleton = ZO_CallbackObject:Subclass()

function CollectionsBook_Singleton:New(...)
    local collectionsSingleton = ZO_CallbackObject.New(self)
    collectionsSingleton:Initialize(...) -- ZO_CallbackObject does not have an initialize function
    return collectionsSingleton
end

function CollectionsBook_Singleton:Initialize()
    self.ownedHouses = {}
    self.searchString = ""
    self.searchResults = {}
    self.searchSpecializationFilters = {}
    self.searchChecksHideWhenLocked = false

    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTIBLES_SEARCH_RESULTS_READY, function() self:UpdateSearchResults() end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTIBLE_REQUEST_BROWSE_TO, function(eventId, ...) self:BrowseToCollectible(...) end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_ACTION_UPDATE_COOLDOWNS, function(eventId, ...) self:OnUpdateCooldowns(...) end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUpdated", function(...) self:OnCollectibleUpdated(...) end)

    -- When the data is getting rebuilt, the indicies can change so our old search results are no longer any good
    local function ReevaluateSearch()
        if self:GetSearchResults() then
            local currentSearch = self.searchString
            ZO_ClearTable(self.searchResults)
            self:SetSearchString("")
            self:SetSearchString(currentSearch)
        end
    end

    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", ReevaluateSearch)

    self:RefreshOwnedHouses()
end

function CollectionsBook_Singleton:SetSearchString(searchString)
    self.searchString = searchString or ""
    StartCollectibleSearch(searchString)
end

function CollectionsBook_Singleton:SetSearchCategorySpecializationFilters(...)
    local argCount = select("#", ...)
    if argCount == NonContiguousCount(self.searchSpecializationFilters) then
        local noChange = true
        for i = 1, argCount do
            local categorySpecialization = select(i, ...)
            if not self.searchSpecializationFilters[categorySpecialization] then
                noChange = false
                break
            end
        end

        if noChange then
            return
        end
    end

    ZO_ClearTable(self.searchSpecializationFilters)
    for i = 1, argCount do
        local categorySpecialization = select(i, ...)
        self.searchSpecializationFilters[categorySpecialization] = true
    end
    self:UpdateSearchResults()
end

function CollectionsBook_Singleton:SetSearchChecksHideWhenLocked(checksHideWhenLocked)
    if self.searchChecksHideWhenLocked ~= checksHideWhenLocked then
        self.searchChecksHideWhenLocked = checksHideWhenLocked
    end
end

function CollectionsBook_Singleton:UpdateSearchResults()
    ZO_ClearTable(self.searchResults)

    local noSpecializationFilters = NonContiguousCount(self.searchSpecializationFilters) == 0
    local searchResults = self.searchResults
    local searchChecksHideWhenLocked = self.searchChecksHideWhenLocked
    for i = 1, GetNumCollectiblesSearchResults() do
        local categoryIndex, subcategoryIndex, collectibleIndex = GetCollectiblesSearchResult(i)
        local categorySpecialization = GetCollectibleCategorySpecialization(categoryIndex)
        if noSpecializationFilters or self.searchSpecializationFilters[categorySpecialization] then
            local canShowCollectible = true
            if searchChecksHideWhenLocked then
                local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataByIndicies(categoryIndex, subcategoryIndex, collectibleIndex)
                if collectibleData:IsLocked() and collectibleData:IsHiddenFromCollectionWhenLocked() then
                    canShowCollectible = false
                end
            end

            if canShowCollectible then
                if not searchResults[categoryIndex] then
                    searchResults[categoryIndex] = {}
                end
                local effectiveSubCategory = subcategoryIndex or ZO_COLLECTIONS_SEARCH_ROOT
                if not searchResults[categoryIndex][effectiveSubCategory] then
                    searchResults[categoryIndex][effectiveSubCategory] = {}
                end

                searchResults[categoryIndex][effectiveSubCategory][collectibleIndex] = true
            end
        end
    end
    self:FireCallbacks("UpdateSearchResults")
end

function CollectionsBook_Singleton:GetSearchResults()
    if zo_strlen(self.searchString) > 1 then
        return self.searchResults
    end
    return nil
end

function CollectionsBook_Singleton:BrowseToCollectible(...)
    SYSTEMS:GetObject(ZO_COLLECTIONS_SYSTEM_NAME):BrowseToCollectible(...)
end

local function IsHouseCollectible(categoryType)
    return categoryType == COLLECTIBLE_CATEGORY_TYPE_HOUSE
end

function CollectionsBook_Singleton:RefreshOwnedHouses()
    ZO_ClearTable(self.ownedHouses)
    local ownedHouses = ZO_COLLECTIBLE_DATA_MANAGER:GetAllCollectibleDataObjects(ZO_CollectibleData.IsUnlocked, ZO_CollectibleData.IsHouse)
    for _, collectibleData in ipairs(ownedHouses) do
        self.ownedHouses[collectibleData:GetId()] = { houseId = collectibleData:GetReferenceId() }
    end
end

function CollectionsBook_Singleton:RefreshOwnedHouseById(collectibleId, justUnlocked)
    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
    if collectibleData:IsHouse() and collectibleData:IsUnlocked() then
        if justUnlocked then
            self.ownedHouses[collectibleId] = { showPermissionsDialogOnEnter = true }
        end
        self.ownedHouses[collectibleId].houseId = collectibleData:GetReferenceId()
    end
end

function CollectionsBook_Singleton:OnCollectibleUpdated(collectibleId, justUnlocked)
    self:RefreshOwnedHouseById(collectibleId, justUnlocked)
end

function CollectionsBook_Singleton:OnUpdateCooldowns(...)
    self:FireCallbacks("OnUpdateCooldowns", ...)
end

function CollectionsBook_Singleton:GetOwnedHouses()
    return self.ownedHouses
end

function CollectionsBook_Singleton:DoesHousePermissionsDialogNeedToBeShownForCollectible(collectibleId)
    return self.ownedHouses[collectibleId] and self.ownedHouses[collectibleId].showPermissionsDialogOnEnter
end

function CollectionsBook_Singleton:MarkHouseCollectiblePermissionLoadDialogShown(collectibleId)
    if self.ownedHouses[collectibleId] then
        self.ownedHouses[collectibleId].showPermissionsDialogOnEnter = false
    end
end

function ZO_UpdateCollectibleEntryDataIconVisuals(entryData)
    local locked = entryData:IsLocked()
    if locked or entryData:IsBlocked() then
        entryData:SetIconDesaturation(1)
    else
        entryData:SetIconDesaturation(0)
    end

    if locked then
        entryData:SetIconSampleProcessingWeightTable(ZO_LOCKED_ICON_SAMPLE_PROCESSING_WEIGHT_TABLE)
    else
        entryData:SetIconSampleProcessingWeightTable(ZO_UNLOCKED_ICON_SAMPLE_PROCESSING_WEIGHT_TABLE)
    end
end

COLLECTIONS_BOOK_SINGLETON = CollectionsBook_Singleton:New()
