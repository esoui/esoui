ZO_SharedFurnitureManager = ZO_CallbackObject:Subclass()

function ZO_SharedFurnitureManager:New(...)
    local sharedFurnitureManager = ZO_CallbackObject.New(self)
    sharedFurnitureManager:Initialize(...)
    return sharedFurnitureManager
end

function ZO_SharedFurnitureManager:Initialize()
    self.furnitureCache = {}

    SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", function(bagId) self:OnFullInventoryUpdate(bagId) end)
    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", function(bagId, slotIndex) self:OnSingleSlotInventoryUpdate(bagId, slotIndex) end)
end

ZO_PLACEABLE_TYPE_ITEM = 1
ZO_PLACEABLE_TYPE_COLLECTIBLE = 2
ZO_PLACEABLE_TYPE_TEST = 3

local function PlaceableFurnitureFilter(itemData)
    return itemData.isPlaceableFurniture
end

function ZO_SharedFurnitureManager:OnFullInventoryUpdate(bagId)
    self:CreateOrUpdateItemCache(bagId)
end

function ZO_SharedFurnitureManager:OnSingleSlotInventoryUpdate(bagId, slotIndex)
    self:CreateOrUpdateItemDataEntry(bagId, slotIndex)
end

function ZO_SharedFurnitureManager:GetFurnitureCache(type)
    if type == ZO_PLACEABLE_TYPE_TEST and not self.furnitureCache[type] then
        self:CreateTestCache() --lazy init test fixtures
    end  

    if self.furnitureCache[type] then
        return self.furnitureCache[type]
    end
end

function ZO_SharedFurnitureManager:CreateOrUpdateItemCache(bagId)
    if not self.furnitureCache[ZO_PLACEABLE_TYPE_ITEM] then    
        self.furnitureCache[ZO_PLACEABLE_TYPE_ITEM] = {}
    end

    local itemCache = self.furnitureCache[ZO_PLACEABLE_TYPE_ITEM]
    if bagId then
        local bagCache = itemCache[bagId]
        if bagCache then
            ZO_ClearTable(bagCache)
        end

        local filteredDataTable = SHARED_INVENTORY:GenerateFullSlotData(PlaceableFurnitureFilter, bagId)
        for _, itemData in pairs(filteredDataTable) do
            self:CreateOrUpdateItemDataEntry(bagId, itemData.slotIndex)
        end
    end
end

function ZO_SharedFurnitureManager:CreateTestCache()
    if not self.furnitureCache[ZO_PLACEABLE_TYPE_TEST] then    
        self.furnitureCache[ZO_PLACEABLE_TYPE_TEST] = {}
    end

    local numFurniture = DebugGetNumTestFurniture() --JKTODO this is just a bunch of test stuff, we'll kill this once more data exists
    for i = 1, numFurniture do
        self:CreateTestDataEntry(i)
    end
end

function ZO_SharedFurnitureManager:CreateOrUpdateItemDataEntry(bagId, slotIndex)
    local itemCache = self.furnitureCache[ZO_PLACEABLE_TYPE_ITEM]
    local bag = itemCache[bagId]

    if not bag then
        bag = {}
        itemCache[bagId] = bag
    end

    local data = bag[slotIndex]
    local slotData = SHARED_INVENTORY:GenerateSingleSlotData(bagId, slotIndex)
    if slotData then
        if not data then
            data = {}
        end

        data.name = slotData.name
        data.bagId = bagId
        data.slotIndex = slotIndex
        data.type = ZO_PLACEABLE_TYPE_ITEM

        bag[slotIndex] = data
    else
        bag[slotIndex] = nil --the item was removed
    end
end

function ZO_SharedFurnitureManager:CreateTestDataEntry(index)
    local testCache = self.furnitureCache[ZO_PLACEABLE_TYPE_TEST]
    local data = testCache[index]

    if not data then
        data = 
        {
            name="[test]Furniture "..tostring(index),
            index = index,
            type = ZO_PLACEABLE_TYPE_TEST
        }
        testCache[#testCache + 1] = data
    end
    -- no need to ever update the test data, its just hardcoded fixture id's.
end

SHARED_FURNITURE = ZO_SharedFurnitureManager:New()