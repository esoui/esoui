--
--[[ CollectionsBook Singleton ]]--
--

ZO_COLLECTIONS_SYSTEM_NAME = "collections"
ZO_COLLECTIONS_CATEGORY_DLC_INDEX = 1

local CollectionsBook_Singleton = ZO_CallbackObject:Subclass()

function CollectionsBook_Singleton:New(...)
    local collectionsSingleton = ZO_CallbackObject.New(self)
    collectionsSingleton:Initialize(...) -- ZO_CallbackObject does not have an initialize function
    return collectionsSingleton
end

function CollectionsBook_Singleton:Initialize()
    self.dlcIdToQuestIsPending = {}

    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTIBLE_REQUEST_BROWSE_TO, function(eventId, ...) self:BrowseToCollectible(...) end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTIBLE_UPDATED, function(eventId, ...) self:OnCollectibleUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTION_UPDATED, function(eventId, ...) self:OnCollectionUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTIBLE_NOTIFICATION_REMOVED, function(eventId, ...) self:OnCollectionNotificationRemoved(...) end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_ACTION_UPDATE_COOLDOWNS, function(eventId, ...) self:OnUpdateCooldowns(...) end)

    self:RefreshDLCStates()
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

function CollectionsBook_Singleton:OnCollectibleUpdated(collectibleId, justUnlocked)
    self:RefreshDLCStateById(collectibleId)
    self:FireCallbacks("OnCollectibleUpdated", collectibleId, justUnlocked)
end

function CollectionsBook_Singleton:OnCollectionUpdated(...)
    self:RefreshDLCStates()
    self:FireCallbacks("OnCollectionUpdated", ...)
end

function CollectionsBook_Singleton:OnCollectionNotificationRemoved(...)
    self:FireCallbacks("OnCollectionNotificationRemoved", ...)
end

function CollectionsBook_Singleton:OnUpdateCooldowns(...)
    self:FireCallbacks("OnUpdateCooldowns", ...)
end

function CollectionsBook_Singleton:IsCategoryIndexDLC(categoryIndex)
    return categoryIndex == ZO_COLLECTIONS_CATEGORY_DLC_INDEX
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

function ZO_GetCollectibleCategoryAndName(collectibleId)
    local categoryIndex = GetCategoryInfoFromCollectibleId(collectibleId)
    local categoryName = GetCollectibleCategoryInfo(categoryIndex)
    local collectibleName = GetCollectibleName(collectibleId)
    return categoryName, collectibleName
end

COLLECTIONS_BOOK_SINGLETON = CollectionsBook_Singleton:New()
