--
--[[ CollectionsBook Singleton ]]--
--

ZO_COLLECTIONS_SYSTEM_NAME = "collections"

local CollectionsBook_Singleton = ZO_CallbackObject:Subclass()

function CollectionsBook_Singleton:New(...)
    local collectionsSingleton = ZO_CallbackObject.New(self)
    collectionsSingleton:Initialize(...) -- ZO_CallbackObject does not have an initialize function
    return collectionsSingleton
end

function CollectionsBook_Singleton:Initialize()
    self.dlcIdToQuestIsPending = {}
    self.ownedHouses = {}

    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTIBLE_REQUEST_BROWSE_TO, function(eventId, ...) self:BrowseToCollectible(...) end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTIBLE_UPDATED, function(eventId, ...) self:OnCollectibleUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTION_UPDATED, function(eventId, ...) self:OnCollectionUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTIBLES_UPDATED, function(eventId, ...) self:OnCollectiblesUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTIBLE_NOTIFICATION_REMOVED, function(eventId, ...) self:OnCollectionNotificationRemoved(...) end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTIBLE_NEW_STATUS_CLEARED, function(eventId, ...) self:OnCollectibleNewStatusRemoved(...) end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_ACTION_UPDATE_COOLDOWNS, function(eventId, ...) self:OnUpdateCooldowns(...) end)

    self:RefreshDLCStates()
    self:RefreshOwnedHouses()
end

function CollectionsBook_Singleton:BrowseToCollectible(...)
    SYSTEMS:GetObject(ZO_COLLECTIONS_SYSTEM_NAME):BrowseToCollectible(...)
end

function CollectionsBook_Singleton:RefreshDLCStateById(collectibleId)
    local isActive, categoryType, _, isPlaceholder = select(7, GetCollectibleInfo(collectibleId))
    if not isPlaceholder and categoryType == COLLECTIBLE_CATEGORY_TYPE_DLC then
        local unlockState = GetCollectibleUnlockStateById(collectibleId)
        self.dlcIdToQuestIsPending[collectibleId] = (unlockState ~= COLLECTIBLE_UNLOCK_STATE_LOCKED and not isActive)
    end
end

function CollectionsBook_Singleton:RefreshDLCStates()
    ZO_ClearTable(self.dlcIdToQuestIsPending)
    for i = 1, GetTotalCollectiblesByCategoryType(COLLECTIBLE_CATEGORY_TYPE_DLC) do
        local collectibleId = GetCollectibleIdFromType(COLLECTIBLE_CATEGORY_TYPE_DLC, i)
        self:RefreshDLCStateById(collectibleId)
    end
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
    self:RefreshDLCStateById(collectibleId)
    self:RefreshOwnedHouseById(collectibleId, justUnlocked)
    self:FireCallbacks("OnCollectibleUpdated", collectibleId, justUnlocked)
end

function CollectionsBook_Singleton:OnCollectionUpdated(...)
    self:RefreshDLCStates()
    self:FireCallbacks("OnCollectionUpdated", ...)
end

function CollectionsBook_Singleton:OnCollectiblesUpdated(...)
    self:RefreshDLCStates()
    self:FireCallbacks("OnCollectiblesUpdated", ...)
end

function CollectionsBook_Singleton:OnCollectionNotificationRemoved(...)
    self:FireCallbacks("OnCollectionNotificationRemoved", ...)
end

function CollectionsBook_Singleton:OnCollectibleNewStatusRemoved(...)
    self:FireCallbacks("OnCollectibleNewStatusRemoved", ...)
end

function CollectionsBook_Singleton:OnUpdateCooldowns(...)
    self:FireCallbacks("OnUpdateCooldowns", ...)
end

function CollectionsBook_Singleton:IsCategoryIndexDLC(categoryIndex)
    return GetCollectibleCategorySpecialization(categoryIndex) == COLLECTIBLE_CATEGORY_SPECIALIZATION_DLC
end

function CollectionsBook_Singleton:IsDLCIdQuestPending(dlcId)
    return self.dlcIdToQuestIsPending[dlcId]
end

function CollectionsBook_Singleton:DoesAnyDLCHaveQuestPending()
    for _, isPending in pairs(self.dlcIdToQuestIsPending) do
        if isPending then
            return true
        end
    end
    return false
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

function CollectionsBook_Singleton.DoesCategoryHaveAnyNewCollectibles(categoryIndex, subcategoryIndex, getCollectiblesFunction)
    if getCollectiblesFunction == nil then
        getCollectiblesFunction = CollectionsBook_Singleton.GetCategoryCollectibleIds
    end

    if subcategoryIndex == nil then
        local numSubCategories, numCollectibles, unlockedCollectibles =  select(2, GetCollectibleCategoryInfo(categoryIndex))
        local hasAnyNew = COLLECTIONS_BOOK_SINGLETON.DoesCollectibleListHaveNewCollectible(getCollectiblesFunction(categoryIndex, subcategoryIndex, numCollectibles))
        if hasAnyNew then
            return true
        end
        for i = 1, numSubCategories do
            if CollectionsBook_Singleton.DoesCategoryHaveAnyNewCollectibles(categoryIndex, i, getCollectiblesFunction) then
                return true
            end
        end
    else
        local numCollectibles = select(2, GetCollectibleSubCategoryInfo(categoryIndex, subcategoryIndex))
        return COLLECTIONS_BOOK_SINGLETON.DoesCollectibleListHaveNewCollectible(getCollectiblesFunction(categoryIndex, subcategoryIndex, numCollectibles))
    end

    return false
end

do
    local ANY_SUBCATEGORY = nil
    function CollectionsBook_Singleton.HasAnyNewCollectibles(getCollectiblesFunction)
        if getCollectiblesFunction == nil then
            getCollectiblesFunction = CollectionsBook_Singleton.GetCategoryCollectibleIds
        end
        local numCategories = GetNumCollectibleCategories()

        for categoryIndex = 1, numCategories do
            if CollectionsBook_Singleton.DoesCategoryHaveAnyNewCollectibles(categoryIndex, ANY_SUBCATEGORY, getCollectiblesFunction) then
                return true
            end
        end

        return false
    end
end

function ZO_GetCollectibleCategoryAndName(collectibleId)
    local categoryIndex = GetCategoryInfoFromCollectibleId(collectibleId)
    local categoryName = GetCollectibleCategoryInfo(categoryIndex)
    local collectibleName = GetCollectibleName(collectibleId)
    return categoryName, collectibleName
end

COLLECTIONS_BOOK_SINGLETON = CollectionsBook_Singleton:New()
