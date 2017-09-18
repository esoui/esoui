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
    self.categoriesWithNewCollectibles = {}
    self.searchString = ""
    self.searchResults = {}
    self.searchSpecializationFilters = {}

    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTIBLES_SEARCH_RESULTS_READY, function() self:UpdateSearchResults() end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTIBLE_REQUEST_BROWSE_TO, function(eventId, ...) self:BrowseToCollectible(...) end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTIBLE_UPDATED, function(eventId, ...) self:OnCollectibleUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTION_UPDATED, function(eventId, ...) self:OnCollectionUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTIBLES_UPDATED, function(eventId, ...) self:OnCollectiblesUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTIBLE_NOTIFICATION_REMOVED, function(eventId, ...) self:OnCollectionNotificationRemoved(...) end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTIBLE_NEW_STATUS_CLEARED, function(eventId, ...) self:OnCollectibleNewStatusRemoved(...) end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_ACTION_UPDATE_COOLDOWNS, function(eventId, ...) self:OnUpdateCooldowns(...) end)

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

function CollectionsBook_Singleton:UpdateSearchResults()
    ZO_ClearTable(self.searchResults)

    local numResults = GetNumCollectiblesSearchResults()
    for i = 1, numResults do
        local categoryIndex, subcategoryIndex, collectibleIndex = GetCollectiblesSearchResult(i)
        local categorySpecialization = GetCollectibleCategorySpecialization(categoryIndex)
        if self.searchSpecializationFilters[categorySpecialization] or NonContiguousCount(self.searchSpecializationFilters) == 0 then
            if not self.searchResults[categoryIndex] then
                self.searchResults[categoryIndex] = {}
            end
            local effectiveSubCategory = subcategoryIndex or ZO_COLLECTIONS_SEARCH_ROOT
            if not self.searchResults[categoryIndex][effectiveSubCategory] then
                self.searchResults[categoryIndex][effectiveSubCategory] = {}
            end

            self.searchResults[categoryIndex][effectiveSubCategory][collectibleIndex] = true
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

function CollectionsBook_Singleton:RefreshOwnedHouses()
    ZO_ClearTable(self.ownedHouses)
    local numAllHouses = GetTotalCollectiblesByCategoryType(COLLECTIBLE_CATEGORY_TYPE_HOUSE)
    for houseIndex = 1, numAllHouses do
        local collectibleId = GetCollectibleIdFromType(COLLECTIBLE_CATEGORY_TYPE_HOUSE, houseIndex)
        local houseId = GetCollectibleReferenceId(collectibleId)
        local isUnlocked = IsCollectibleUnlocked(collectibleId)
        if isUnlocked then
            self.ownedHouses[collectibleId] = { houseId = houseId }
        end
    end
end

function CollectionsBook_Singleton:RefreshOwnedHouseById(collectibleId, justUnlocked)
    local isUnlocked, _, _, categoryType = select(5, GetCollectibleInfo(collectibleId))
    if categoryType == COLLECTIBLE_CATEGORY_TYPE_HOUSE and isUnlocked then
        local houseId = GetCollectibleReferenceId(collectibleId)
        if justUnlocked then
            self.ownedHouses[collectibleId] = { showPermissionsDialogOnEnter = true }
        end
        self.ownedHouses[collectibleId].houseId = houseId
    end
end

function CollectionsBook_Singleton:OnCollectibleUpdated(collectibleId, justUnlocked)
    self:RefreshOwnedHouseById(collectibleId, justUnlocked)
    self:ClearCachedNewStatusForCollectible(collectibleId)
    self:FireCallbacks("OnCollectibleUpdated", collectibleId, justUnlocked)
end

function CollectionsBook_Singleton:OnCollectionUpdated(...)
    self:ClearCachedNewStatusForAllCollectibles()
    self:FireCallbacks("OnCollectionUpdated", ...)
end

function CollectionsBook_Singleton:OnCollectiblesUpdated(...)
    self:ClearCachedNewStatusForAllCollectibles()
    self:FireCallbacks("OnCollectiblesUpdated", ...)
end

function CollectionsBook_Singleton:OnCollectionNotificationRemoved(...)
    self:FireCallbacks("OnCollectionNotificationRemoved", ...)
end

function CollectionsBook_Singleton:OnCollectibleNewStatusRemoved(collectibleId)
    self:ClearCachedNewStatusForCollectible(collectibleId)
    self:FireCallbacks("OnCollectibleNewStatusRemoved", collectibleId)
end

function CollectionsBook_Singleton:OnUpdateCooldowns(...)
    self:FireCallbacks("OnUpdateCooldowns", ...)
end

function CollectionsBook_Singleton:IsCategoryIndexDLC(categoryIndex)
    return GetCollectibleCategorySpecialization(categoryIndex) == COLLECTIBLE_CATEGORY_SPECIALIZATION_DLC
end

function CollectionsBook_Singleton:GetOwnedHouses()
    return self.ownedHouses
end

function CollectionsBook_Singleton:IsOwnedHouseCollectibleUnlocked(collectibleId)
    return self.ownedHouses[collectibleId] ~= nil
end

function CollectionsBook_Singleton:DoesHousePermissionsDialogNeedToBeShownForCollectible(collectibleId)
    return self.ownedHouses[collectibleId] and self.ownedHouses[collectibleId].showPermissionsDialogOnEnter
end

function CollectionsBook_Singleton:MarkHouseCollectiblePermissionLoadDialogShown(collectibleId)
    if self.ownedHouses[collectibleId] then
        self.ownedHouses[collectibleId].showPermissionsDialogOnEnter = false
    end
end

function CollectionsBook_Singleton:IsCategoryIndexHousing(categoryIndex)
    return GetCollectibleCategorySpecialization(categoryIndex) == COLLECTIBLE_CATEGORY_SPECIALIZATION_HOUSING
end

function CollectionsBook_Singleton.DoesCollectibleListHaveVisibleCollectible(...)
    for i = 1, select("#", ...) do
        local id = select(i, ...)

        if DoesCollectibleHaveVisibleAppearance(id) then
            local isActive = select(7, GetCollectibleInfo(id))
            if isActive and not WouldCollectibleBeHidden(id) then
                return true
            end
        end
    end

    return false
end

function CollectionsBook_Singleton.DoesCollectibleListHaveNewCollectible(...)
    for i = 1, select("#", ...) do
        local id = select(i, ...)

        if IsCollectibleNew(id) then
            return true
        end
    end

    return false
end

function CollectionsBook_Singleton.GetCategoryCollectibleIds(categoryIndex, subCategoryIndex, index, ...)
    if index >= 1 then
        local id = GetCollectibleId(categoryIndex, subCategoryIndex, index)
        index = index - 1
        return CollectionsBook_Singleton.GetCategoryCollectibleIds(categoryIndex, subCategoryIndex, index, id, ...)
    end
    return ...
end

function CollectionsBook_Singleton:ClearCachedNewStatusForAllCollectibles()
    ZO_ClearTable(self.categoriesWithNewCollectibles)
end

function CollectionsBook_Singleton:ClearCachedNewStatusForCollectible(collectibleId)
    local categoryIndex, subcategoryIndex, collectibleIndex = GetCategoryInfoFromCollectibleId(collectibleId)
    if categoryIndex then
        if subcategoryIndex then
            local categoryNewData = self.categoriesWithNewCollectibles[categoryIndex]
            if categoryNewData and categoryNewData.subcategories then
                categoryNewData.subcategories[subcategoryIndex] = nil
                categoryNewData.categoryOrSubcategoriesHaveAnyNew = nil
            end
        else
            self.categoriesWithNewCollectibles[categoryIndex] = nil
        end
    end
end

function CollectionsBook_Singleton:DoesCategoryHaveAnyNewCollectibles(categoryIndex, subcategoryIndex)
    if subcategoryIndex == nil then
        local categoryHasAnyNew
        local numSubCategories, numCollectibles, unlockedCollectibles = select(2, GetCollectibleCategoryInfo(categoryIndex))

        local categoryNewData = self.categoriesWithNewCollectibles[categoryIndex]

        if categoryNewData then
            if categoryNewData.categoryOrSubcategoriesHaveAnyNew ~= nil then
                return categoryNewData.categoryOrSubcategoriesHaveAnyNew
            elseif categoryNewData.hasAnyNew ~= nil then
                categoryHasAnyNew = categoryNewData.hasAnyNew
            else
                categoryHasAnyNew = CollectionsBook_Singleton.DoesCollectibleListHaveNewCollectible(CollectionsBook_Singleton.GetCategoryCollectibleIds(categoryIndex, subcategoryIndex, numCollectibles))
                categoryNewData.hasAnyNew = categoryHasAnyNew
            end
        else
            categoryHasAnyNew = CollectionsBook_Singleton.DoesCollectibleListHaveNewCollectible(CollectionsBook_Singleton.GetCategoryCollectibleIds(categoryIndex, subcategoryIndex, numCollectibles))
            categoryNewData = { hasAnyNew = categoryHasAnyNew }
            self.categoriesWithNewCollectibles[categoryIndex] = categoryNewData
        end

        local categoryOrSubcategoriesHaveAnyNew = false
        if categoryHasAnyNew then
            categoryOrSubcategoriesHaveAnyNew = true
        else
            for i = 1, numSubCategories do
                if self:DoesCategoryHaveAnyNewCollectibles(categoryIndex, i) then
                    categoryOrSubcategoriesHaveAnyNew = true
                    break
                end
            end
        end
        
        categoryNewData.categoryOrSubcategoriesHaveAnyNew = categoryOrSubcategoriesHaveAnyNew
        return categoryOrSubcategoriesHaveAnyNew
    else
        local categoryNewData = self.categoriesWithNewCollectibles[categoryIndex]
        if categoryNewData == nil then
            local NO_SUBCATEGORY = nil
            local numCollectibles = select(2, GetCollectibleSubCategoryInfo(categoryIndex, NO_SUBCATEGORY))
            categoryHasAnyNew = CollectionsBook_Singleton.DoesCollectibleListHaveNewCollectible(CollectionsBook_Singleton.GetCategoryCollectibleIds(categoryIndex, NO_SUBCATEGORY, numCollectibles))
            categoryNewData = { hasAnyNew = categoryHasAnyNew }
            self.categoriesWithNewCollectibles[categoryIndex] = categoryNewData
        end
        if categoryNewData.subcategories == nil then
            categoryNewData.subcategories = {}
        end
        local subcategoryHasAnyNew = categoryNewData.subcategories[subcategoryIndex]
        if subcategoryHasAnyNew == nil then
            local numCollectibles = select(2, GetCollectibleSubCategoryInfo(categoryIndex, subcategoryIndex))
            subcategoryHasAnyNew = CollectionsBook_Singleton.DoesCollectibleListHaveNewCollectible(CollectionsBook_Singleton.GetCategoryCollectibleIds(categoryIndex, subcategoryIndex, numCollectibles))
            categoryNewData.subcategories[subcategoryIndex] = subcategoryHasAnyNew
        end
        return subcategoryHasAnyNew
    end

    return false
end

do
    local ANY_SUBCATEGORY = nil
    function CollectionsBook_Singleton.HasAnyNewCollectibles()
        if getCollectiblesFunction == nil then
            getCollectiblesFunction = CollectionsBook_Singleton.GetCategoryCollectibleIds
        end
        local numCategories = GetNumCollectibleCategories()

        for categoryIndex = 1, numCategories do
            if COLLECTIONS_BOOK_SINGLETON:DoesCategoryHaveAnyNewCollectibles(categoryIndex, ANY_SUBCATEGORY) then
                return true
            end
        end

        return false
    end
end

do
    local function ShouldAddCollectibleToList(topLevelCategoryIndex, subCategoryIndex, entryIndex, ...)
        local collectibleId = GetCollectibleId(topLevelCategoryIndex, subCategoryIndex, entryIndex)
        if not IsCollectibleUnlocked(collectibleId) then
            return false
        end
        local collectibleCategoryType = GetCollectibleCategoryType(collectibleId)
        for i = 1, select("#", ...) do
            local filterFunction = select(i, ...)
            if not filterFunction(collectibleCategoryType) then
                return false
            end
        end

        return true
    end

    function CollectionsBook_Singleton.GetCollectibleIdsFromTopLevelCategory(topLevelCategoryIndex, ...) --... are filter functions that takes COLLECTIBLE_CATEGORY_TYPE as an argument
        local foundCollectibleIds = {}
        local _, numSubCategories, numCollectibles = GetCollectibleCategoryInfo(topLevelCategoryIndex)
        for entryIndex = 1, numCollectibles do
            if ShouldAddCollectibleToList(topLevelCategoryIndex, nil, entryIndex, ...) then
                local collectibleId = GetCollectibleId(topLevelCategoryIndex, nil, entryIndex)
                table.insert(foundCollectibleIds, collectibleId)
            end
        end

        for subCategoryIndex = 1, numSubCategories do
            local _, subCategoryEntries = GetCollectibleSubCategoryInfo(topLevelCategoryIndex, subCategoryIndex)
            for entryIndex = 1, subCategoryEntries do
                if ShouldAddCollectibleToList(topLevelCategoryIndex, subCategoryIndex, entryIndex, ...) then
                    local collectibleId = GetCollectibleId(topLevelCategoryIndex, subCategoryIndex, entryIndex)
                    table.insert(foundCollectibleIds, collectibleId)
                end
            end
        end

        return foundCollectibleIds
    end
end

function ZO_GetCollectibleCategoryAndName(collectibleId)
    local categoryIndex, subcategoryIndex = GetCategoryInfoFromCollectibleId(collectibleId)
    local categoryName
    if subcategoryIndex then
        categoryName = GetCollectibleSubCategoryInfo(categoryIndex, subcategoryIndex)
    else
        categoryName = GetCollectibleCategoryInfo(categoryIndex)
    end
    local collectibleName = GetCollectibleName(collectibleId)
    return categoryName, collectibleName
end

function ZO_ShowChapterUpgradePlatformDialog()
    if IsConsoleUI() then
        ZO_Dialogs_ShowGamepadDialog("CHAPTER_UPGRADE_STORE_CONSOLE")
    else
        ZO_Dialogs_ShowPlatformDialog("CHAPTER_UPGRADE_STORE")
    end
end

COLLECTIONS_BOOK_SINGLETON = CollectionsBook_Singleton:New()
