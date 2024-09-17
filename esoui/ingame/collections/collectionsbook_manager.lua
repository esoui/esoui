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
    self.unlockedHouses = {}
    self.ownedHouses = self.unlockedHouses -- Deprecated, keeping for backwards compatibility
    self.unlockedHousesNeedsInit = true
    self.primaryResidenceId = GetHousingPrimaryHouse()
    self.searchString = ""
    self.searchResults = {}
    self.searchSpecializationFilters = {}
    self.searchChecksHidden = false

    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTIBLES_SEARCH_RESULTS_READY, function() self:UpdateSearchResults() end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTIBLE_REQUEST_BROWSE_TO, function(eventId, ...) self:BrowseToCollectible(...) end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_ACTION_UPDATE_COOLDOWNS, function(eventId, ...) self:OnUpdateCooldowns(...) end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_HOUSING_PRIMARY_RESIDENCE_SET, function(eventId, ...) self:OnPrimaryResidenceSet(...) end)

    local function OnCollectionUpdated(collectionUpdateType, collectiblesByNewUnlockState)
        if collectionUpdateType == ZO_COLLECTION_UPDATE_TYPE.REBUILD then
            self:RefreshUnlockedHouses()

            -- When the data is getting rebuilt, the indices can change so our old search results are no longer any good
            if self:GetSearchResults() then
                local currentSearch = self.searchString
                ZO_ClearTable(self.searchResults)
                self:SetSearchString("")
                self:SetSearchString(currentSearch)
            end
        else
            for _, unlockStateTable in pairs(collectiblesByNewUnlockState) do
                for _, collectibleData in ipairs(unlockStateTable) do
                    if collectibleData:IsHouse() then
                        local unlockedHouses = self:GetUnlockedHouses()
                        local nowUnlocked = collectibleData:IsUnlocked()
                        local collectibleId = collectibleData:GetId()
                        local existingUnlockedHouseData = unlockedHouses[collectibleId]
                        if nowUnlocked then
                            if not existingUnlockedHouseData then
                                existingUnlockedHouseData = { houseId = collectibleData:GetReferenceId(), }
                                unlockedHouses[collectibleId] = existingUnlockedHouseData
                            end
                            existingUnlockedHouseData.showPermissionsDialogOnEnter = true
                        elseif not nowUnlocked and existingUnlockedHouseData then
                            unlockedHouses[collectibleId] = nil
                        end
                    end
                end
            end
        end
    end

    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", OnCollectionUpdated)
end

function CollectionsBook_Singleton:SetSearchString(searchString)
    self.searchString = searchString or ""
    StartCollectibleSearch(self.searchString)
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

function CollectionsBook_Singleton:SetSearchChecksHidden(searchChecksHidden)
    self.searchChecksHidden = searchChecksHidden
end

function CollectionsBook_Singleton:UpdateSearchResults()
    ZO_ClearTable(self.searchResults)

    local noSpecializationFilters = NonContiguousCount(self.searchSpecializationFilters) == 0
    local searchResults = self.searchResults
    local searchChecksHidden = self.searchChecksHidden
    for i = 1, GetNumCollectiblesSearchResults() do
        local categoryIndex, subcategoryIndex, collectibleIndex = GetCollectiblesSearchResult(i)
        local categorySpecialization = GetCollectibleCategorySpecialization(categoryIndex)
        if noSpecializationFilters or self.searchSpecializationFilters[categorySpecialization] then
            local canShowCollectible = true
            if searchChecksHidden then
                local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataByIndicies(categoryIndex, subcategoryIndex, collectibleIndex)
                if collectibleData:IsHiddenFromCollection() then
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

function CollectionsBook_Singleton:RefreshUnlockedHouses()
    ZO_ClearTable(self.unlockedHouses)
    local unlockedHouses = ZO_COLLECTIBLE_DATA_MANAGER:GetAllCollectibleDataObjects({ ZO_CollectibleCategoryData.IsHousingCategory }, { ZO_CollectibleData.IsUnlocked })
    for _, collectibleData in ipairs(unlockedHouses) do
        self.unlockedHouses[collectibleData:GetId()] = { houseId = collectibleData:GetReferenceId() }
    end
    internalassert(#unlockedHouses <= MAX_HOUSES_FOR_PERMISSIONS, "There are too many houses for permissions messaging to handle. Have an engineer update cMaxHousesPerAccount.")
end

function CollectionsBook_Singleton:OnUpdateCooldowns(...)
    self:FireCallbacks("OnUpdateCooldowns", ...)
end

function CollectionsBook_Singleton:GetUnlockedHouses()
    if self.unlockedHousesNeedsInit then
        self:RefreshUnlockedHouses()
        self.unlockedHousesNeedsInit = false
    end
    return self.unlockedHouses
end

function CollectionsBook_Singleton:DoesHousePermissionsDialogNeedToBeShownForCollectible(collectibleId)
    local unlockedHouses = self:GetUnlockedHouses()
    return unlockedHouses[collectibleId] and unlockedHouses[collectibleId].showPermissionsDialogOnEnter
end

function CollectionsBook_Singleton:MarkHouseCollectiblePermissionLoadDialogShown(collectibleId)
    local unlockedHouses = self:GetUnlockedHouses()
    if unlockedHouses[collectibleId] then
        unlockedHouses[collectibleId].showPermissionsDialogOnEnter = false
    end
end

function CollectionsBook_Singleton:OnPrimaryResidenceSet(houseId)
    self.primaryResidenceId = houseId
    self:FireCallbacks("PrimaryResidenceSet", houseId)
end

function CollectionsBook_Singleton:GetPrimaryResidence()
    return self.primaryResidenceId
end

function CollectionsBook_Singleton:SetPrimaryResidence(houseId)
    if self.primaryResidenceId == 0 then
        SetHousingPrimaryHouse(houseId)
    elseif houseId ~= self.primaryResidenceId then
        local collectibleId = GetCollectibleIdForHouse(self.primaryResidenceId)
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
        ZO_Dialogs_ShowPlatformDialog("CONFIRM_PRIMARY_RESIDENCE", { currentHouse = houseId }, { mainTextParams = { collectibleData:GetName(), collectibleData:GetNickname()}})
    end
end

-- Attempts to begin placement of the specified collectible furnishing in the current house.
function CollectionsBook_Singleton.TryPlaceCollectibleFurniture(collectibleData)
    if not (collectibleData.CanPlaceInCurrentHouse and collectibleData:CanPlaceInCurrentHouse()) then
        return false
    end

    if GetHousingEditorMode() ~= HOUSING_EDITOR_MODE_SELECTION then
        SCENE_MANAGER:ShowBaseScene()

        if HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_SELECTION) ~= HOUSING_REQUEST_RESULT_SUCCESS then
            return false
        end
    end

    local success = HousingEditorCreateCollectibleFurnitureForPlacement(collectibleData:GetId())
    return success
end

function ZO_UpdateCollectibleEntryDataIconVisuals(entryData, actorCategory)
    local locked = entryData:IsLocked()
    if locked then
        entryData:SetIconDesaturation(1)
    elseif entryData:IsBlocked(actorCategory) then
        entryData:SetIconDesaturation(1)
    else
        entryData:SetIconDesaturation(0)
    end

    if locked then
        entryData:SetIconColor(ZO_SILHOUETTE_ICON_COLOR)
        entryData:SetIconSampleProcessingWeightTable(ZO_SILHOUETTE_ICON_SAMPLE_PROCESSING_WEIGHT_TABLE)
    else
        entryData:SetIconColor(ZO_NO_SILHOUETTE_ICON_COLOR)
        entryData:SetIconSampleProcessingWeightTable(ZO_NO_SILHOUETTE_ICON_SAMPLE_PROCESSING_WEIGHT_TABLE)
    end
end

COLLECTIONS_BOOK_SINGLETON = CollectionsBook_Singleton:New()
