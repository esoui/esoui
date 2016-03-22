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
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTIBLE_REQUEST_BROWSE_TO, function(eventId, ...) self:BrowseToCollectible(...) end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTIBLE_UPDATED, function(eventId, ...) self:OnCollectibleUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTION_UPDATED, function(eventId, ...) self:OnCollectionUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_COLLECTIBLE_NOTIFICATION_REMOVED, function(eventId, ...) self:OnCollectionNotificationRemoved(...) end)
    EVENT_MANAGER:RegisterForEvent("CollectionsBook_Singleton", EVENT_ACTION_UPDATE_COOLDOWNS, function(eventId, ...) self:OnUpdateCooldowns(...) end)
end

function CollectionsBook_Singleton:BrowseToCollectible(...)
    SYSTEMS:GetObject(ZO_COLLECTIONS_SYSTEM_NAME):BrowseToCollectible(...)
end

function CollectionsBook_Singleton:OnCollectibleUpdated(...)
    self:FireCallbacks("OnCollectibleUpdated", ...)
end

function CollectionsBook_Singleton:OnCollectionUpdated(...)
    self:FireCallbacks("OnCollectionUpdated", ...)
end

function CollectionsBook_Singleton:OnCollectionNotificationRemoved(...)
    self:FireCallbacks("OnCollectionNotificationRemoved", ...)
end

function CollectionsBook_Singleton:OnUpdateCooldowns(...)
    self:FireCallbacks("OnUpdateCooldowns", ...)
end

function ZO_GetCollectibleCategoryAndName(collectibleId)
    local categoryIndex = GetCategoryInfoFromCollectibleId(collectibleId)
    local categoryName = GetCollectibleCategoryInfo(categoryIndex)
    local collectibleName = GetCollectibleName(collectibleId)
    return categoryName, collectibleName
end

COLLECTIONS_BOOK_SINGLETON = CollectionsBook_Singleton:New()
