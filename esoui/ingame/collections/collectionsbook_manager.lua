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

function ZO_GetCollectibleCategoryAndName(collectibleId)
    local categoryIndex = GetCategoryInfoFromCollectibleId(collectibleId)
    local categoryName = GetCollectibleCategoryInfo(categoryIndex)
    local collectibleName = GetCollectibleName(collectibleId)
    return categoryName, collectibleName
end

COLLECTIONS_BOOK_SINGLETON = CollectionsBook_Singleton:New()
