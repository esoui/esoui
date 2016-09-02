--
--[[ PlaceableFurnitureBase ]]--
--
ZO_PlaceableFurnitureBase = ZO_Object:Subclass()

function ZO_PlaceableFurnitureBase:New(...)
    local furniture = ZO_Object.New(self)
    furniture:Initialize(...)
    return furniture
end

function ZO_PlaceableFurnitureBase:Initialize(...)
    assert(false)  --must be overridden
end

function ZO_PlaceableFurnitureBase:Preview()
    assert(false)  --must be overridden
end

function ZO_PlaceableFurnitureBase:RequestRemove()
    assert(false)  --must be overridden
end

function ZO_PlaceableFurnitureBase:GetName()
    assert(false)  --must be overridden
end

function ZO_PlaceableFurnitureBase:GetIcon()
    assert(false)  --must be overridden
end

--
--[[ PlaceableFurnitureItem ]]--
--
ZO_PlaceableFurnitureItem = ZO_PlaceableFurnitureBase:Subclass()

function ZO_PlaceableFurnitureItem:New(...)
    return ZO_PlaceableFurnitureBase.New(self, ...)
end

function ZO_PlaceableFurnitureItem:Initialize(bagId, slotIndex)
    self.bagId = bagId
    self.slotIndex = slotIndex

    local slotData = SHARED_INVENTORY:GenerateSingleSlotData(bagId, slotIndex)
    if slotData and slotData.isPlaceableFurniture then
        self.name = slotData.name
        self.icon = slotData.iconFile
    end
end

function ZO_PlaceableFurnitureItem:Preview()
    HousingEditorPreviewItemFurniture(self.bagId, self.slotIndex)
end

function ZO_PlaceableFurnitureItem:GetName()
    return self.name
end

function ZO_PlaceableFurnitureItem:GetIcon()
    return self.icon
end

--
--[[ PlaceableFurnitureCollectible ]]--
--
ZO_PlaceableFurnitureCollectible = ZO_PlaceableFurnitureBase:Subclass()

function ZO_PlaceableFurnitureCollectible:New(...)
    return ZO_PlaceableFurnitureBase.New(self, ...)
end

function ZO_PlaceableFurnitureCollectible:Initialize(collectibleId)
    self.collectibleId = collectibleId

    local collData = COLLECTIONS_INVENTORY_SINGLETON:GetSingleCollectibleData(collectibleId, IsCollectibleCategoryPlaceableFurniture)
    if collData then
        self.name = collData.name
        self.icon = collData.iconFile
    end
end

function ZO_PlaceableFurnitureCollectible:Preview()
    HousingEditorPreviewCollectibleFurniture(self.collectibleId)
end

function ZO_PlaceableFurnitureCollectible:GetName()
    return self.name
end

function ZO_PlaceableFurnitureCollectible:GetIcon()
    return self.icon
end