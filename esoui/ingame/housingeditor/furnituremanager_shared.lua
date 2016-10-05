ZO_SharedFurnitureManager = ZO_CallbackObject:Subclass()

local function GetNextPlacedFurnitureIdIter(state, var1)
    return GetNextPlacedHousingFurnitureId(var1)
end

ZO_PLACEABLE_TYPE_ITEM = 1
ZO_PLACEABLE_TYPE_COLLECTIBLE = 2

function ZO_SharedFurnitureManager:New(...)
    local sharedFurnitureManager = ZO_CallbackObject.New(self)
    sharedFurnitureManager:Initialize(...)
    return sharedFurnitureManager
end

function ZO_SharedFurnitureManager:Initialize()
    self.placeableFurniture = 
    {
        [ZO_PLACEABLE_TYPE_COLLECTIBLE] = {},
        [ZO_PLACEABLE_TYPE_ITEM] = {},
    }

    self.recallableFurniture = {}

    self:RegisterForEvents()
end

function ZO_SharedFurnitureManager:RegisterForEvents()
    SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", function(bagId) self:OnFullInventoryUpdate(bagId) end)
    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", function(bagId, slotIndex) self:OnSingleSlotInventoryUpdate(bagId, slotIndex) end)
    COLLECTIONS_INVENTORY_SINGLETON:RegisterCallback("FullCollectionsInventoryUpdate", function() self:OnFullCollectionUpdate() end)
    COLLECTIONS_INVENTORY_SINGLETON:RegisterCallback("SingleCollectionsInventoryUpdate", function(collectibleId) self:OnSingleCollectibleUpdate(collectibleId) end)

    local function FurniturePlaced(eventId, furnitureId, collectibleId)
        self:OnFurniturePlacedInHouse(furnitureId, collectibleId)
    end

    local function FurnitureRemoved(eventId, furnitureId, collectibleId)
        self:OnFurnitureRemovedFromHouse(furnitureId, collectibleId)
    end

    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_HOUSING_FURNITURE_PLACED, FurniturePlaced)
    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_HOUSING_FURNITURE_REMOVED, FurnitureRemoved)

    local function InitFurnitureCaches()
        self:InitializeFurnitureCaches()
    end
    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_PLAYER_ACTIVATED, InitFurnitureCaches)
end

local function PlaceableFurnitureFilter(itemData)
    return itemData.isPlaceableFurniture
end

function ZO_SharedFurnitureManager:CreatePlacedFurnitureData(furnitureId)
    local rawName, icon = GetPlacedHousingFurnitureInfo(furnitureId)
    local dataEntry =
    {
        name = zo_strformat(SI_TOOLTIP_ITEM_NAME, rawName),
        icon = icon,
        furnitureId = furnitureId,
        --probably gonna need some filter information in here since its one giant list of furniture now
    }
    return dataEntry
end

function ZO_SharedFurnitureManager:InitializeFurnitureCaches()
    --setup just the placeable collections, SharedInventory will tell us when its ready to query placeable items
    self:OnFullCollectionUpdate()

    for furnitureId in GetNextPlacedFurnitureIdIter do
        self.recallableFurniture[zo_getSafeId64Key(furnitureId)] = self:CreatePlacedFurnitureData(furnitureId)
    end
end

function ZO_SharedFurnitureManager:OnFurniturePlacedInHouse(furnitureId, collectibleId)
    if collectibleId then
        self.placeableFurniture[ZO_PLACEABLE_TYPE_COLLECTIBLE][collectibleId] = nil
    end
    --if an item just add to the recall list, SharedInventory will propagate the placeable list changes
    self.recallableFurniture[zo_getSafeId64Key(furnitureId)] = self:CreatePlacedFurnitureData(furnitureId)

    self:FireCallbacks("HousingSingleInventoryUpdate", furnitureId) 
end

function ZO_SharedFurnitureManager:OnFurnitureRemovedFromHouse(furnitureId, collectibleId)
    if collectibleId then
        self.placeableFurniture[ZO_PLACEABLE_TYPE_COLLECTIBLE][collectibleId] = ZO_PlaceableFurnitureCollectible:New(collectibleId)
    end
    --if an item just remove, the inventory update will handle the placeable list changes
    self.recallableFurniture[zo_getSafeId64Key(furnitureId)] = nil 
    self:FireCallbacks("HousingSingleInventoryUpdate", furnitureId)
end

function ZO_SharedFurnitureManager:OnFullInventoryUpdate(bagId)
    self:CreateOrUpdateItemCache(bagId)
    self:FireCallbacks("HousingFullInventoryUpdate", bagId)
end

function ZO_SharedFurnitureManager:OnSingleSlotInventoryUpdate(bagId, slotIndex)
    local slotData = SHARED_INVENTORY:GenerateSingleSlotData(bagId, slotIndex)
    if slotData and slotData.isPlaceableFurniture then
        self:CreateOrUpdateItemDataEntry(bagId, slotIndex)
    else
        --the item was deleted
        local bag = self.placeableFurniture[ZO_PLACEABLE_TYPE_ITEM][bagId]
        if bag then
            bag[slotIndex] = nil
        end
    end
    self:FireCallbacks("HousingSingleInventoryUpdate", bagId, slotIndex)
end

function ZO_SharedFurnitureManager:OnFullCollectionUpdate()
    self:CreateOrUpdateCollectibleCache()
    self:FireCallbacks("HousingFullCollectionUpdate")
end

function ZO_SharedFurnitureManager:OnSingleCollectibleUpdate(collectibleId)
    local collData = COLLECTIONS_INVENTORY_SINGLETON:GetSingleCollectibleData(collectibleId, IsCollectibleCategoryPlaceableFurniture)
    if collData then
        self:CreateOrUpdateCollectibleDataEntry(collectibleId)
    else
        --something made the collectible no longer valid
        self.placeableFurniture[ZO_PLACEABLE_TYPE_COLLECTIBLE][collectibleId] = nil
    end
    self:FireCallbacks("HousingSingleCollectibleUpdate", collectibleId)
end 


function ZO_SharedFurnitureManager:GetPlaceableFurnitureCache(type)
    return self.placeableFurniture[type]
end

function ZO_SharedFurnitureManager:GetRecallableFurnitureCache()
    return self.recallableFurniture
end

function ZO_SharedFurnitureManager:CreateOrUpdateItemCache(bagId)
    local itemCache = self.placeableFurniture[ZO_PLACEABLE_TYPE_ITEM]
    if bagId then
        local bagCache = itemCache[bagId]
        if bagCache then
            ZO_ClearTable(bagCache)
        end

        local filteredDataTable = SHARED_INVENTORY:GenerateFullSlotData(PlaceableFurnitureFilter, bagId)
        for _, itemData in pairs(filteredDataTable) do
            self:CreateOrUpdateItemDataEntry(itemData.bagId, itemData.slotIndex)
        end
    end
end

function ZO_SharedFurnitureManager:CreateOrUpdateCollectibleCache()
    local collectibleCache = self.placeableFurniture[ZO_PLACEABLE_TYPE_COLLECTIBLE]
    ZO_ClearTable(collectibleCache)
    
    local filteredDataTable = COLLECTIONS_INVENTORY_SINGLETON:GetCollectionsData(IsCollectibleCategoryPlaceableFurniture)
    for _, collectibleData in pairs(filteredDataTable) do
        self:CreateOrUpdateCollectibleDataEntry(collectibleData.collectibleId)
    end
end

function ZO_SharedFurnitureManager:CreateOrUpdateItemDataEntry(bagId, slotIndex)
    local itemCache = self.placeableFurniture[ZO_PLACEABLE_TYPE_ITEM]
    local bag = itemCache[bagId]
    if not bag then
        bag = {}
        itemCache[bagId] = bag
    end

    local placeableItem = bag[slotIndex]
    if placeableItem then
        placeableItem:Initialize(bagId, slotIndex) --reinit for whatever just took this spot
    else
        bag[slotIndex] = ZO_PlaceableFurnitureItem:New(bagId, slotIndex)
    end
end

function ZO_SharedFurnitureManager:CreateOrUpdateCollectibleDataEntry(collectibleId)
    if HousingEditorCanPlaceCollectible(collectibleId) then
        local placeableCollectible = self.placeableFurniture[ZO_PLACEABLE_TYPE_COLLECTIBLE][collectibleId]
        if placeableCollectible then
            placeableCollectible:Initialize(collectibleId) --just reinit with potentially new data
        else
            self.placeableFurniture[ZO_PLACEABLE_TYPE_COLLECTIBLE][collectibleId] = ZO_PlaceableFurnitureCollectible:New(collectibleId)
        end
    else
        self.placeableFurniture[ZO_PLACEABLE_TYPE_COLLECTIBLE][collectibleId] = nil
    end
end

SHARED_FURNITURE = ZO_SharedFurnitureManager:New()