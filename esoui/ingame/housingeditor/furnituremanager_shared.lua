ZO_FURNITURE_NEEDS_CATEGORIZATION_FAKE_CATEGORY = "NEEDS_CATEGORY"

ZO_PLACEABLE_TYPE_ITEM = 1
ZO_PLACEABLE_TYPE_COLLECTIBLE = 2

local FURNITURE_COMMAND_REMOVE = 1

local function GetNextPlacedFurnitureIdIter(state, var1)
    return GetNextPlacedHousingFurnitureId(var1)
end

local function PlaceableFurnitureFilter(itemData)
    return itemData.isPlaceableFurniture
end

ZO_SharedFurnitureManager = ZO_CallbackObject:Subclass()

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
    self.placeableFurnitureCategoryTreeData = ZO_FurnitureCategory:New()
    self.inProgressPlaceableFurnitureTextFilterTaskIds = { }
    self.completePlaceableFurnitureTextFilterTaskIds = { }
    self.placeableTextFilter = ""

    self.retrievableFurnitureCategoryTreeData = ZO_FurnitureCategory:New()
    self.retrievableFurniture = {}
    self.retrievableTextFilter = ""

    self.marketProductCategoryTreeData = ZO_FurnitureCategory:New()
    self.marketProducts = {}
    self.marketProductTextFilter = ""

    local function CreateMarketProduct(objectPool)
        return ZO_HousingMarketProduct:New()
    end
    
    local function ResetMarketProduct(housingMarketProduct)
        housingMarketProduct:Reset()
    end

    self.housingMarketProductPool = ZO_ObjectPool:New(CreateMarketProduct, ResetMarketProduct)

    self:RegisterForEvents()
end

function ZO_SharedFurnitureManager:RegisterForEvents()
    SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", function(bagId) self:OnFullInventoryUpdate(bagId) end)
    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", function(...) self:OnSingleSlotInventoryUpdate(...) end)
    COLLECTIONS_INVENTORY_SINGLETON:RegisterCallback("FullCollectionsInventoryUpdate", function() self:OnFullCollectionUpdate() end)
    COLLECTIONS_INVENTORY_SINGLETON:RegisterCallback("SingleCollectionsInventoryUpdate", function(collectibleId) self:OnSingleCollectibleUpdate(collectibleId) end)

    local function ApplyFurnitureCommand(categoryTreeData, furnitureCommand)
        if furnitureCommand.command == FURNITURE_COMMAND_REMOVE then
            self:RemoveFurnitureFromCategory(categoryTreeData, furnitureCommand.target)
        end
    end

    self.refreshGroups = ZO_Refresh:New()
    self.refreshGroups:AddRefreshGroup("UpdatePlacementFurniture",
    {
        RefreshAll = function()
            self.placeableFurnitureCategoryTreeData:Clear()
            local itemFurnitureCache = self:GetPlaceableFurnitureCache(ZO_PLACEABLE_TYPE_ITEM)
            local foundBankInventory = false
            for bagId, bagEntries in pairs(itemFurnitureCache) do
                self:BuildCategoryTreeData(self.placeableFurnitureCategoryTreeData, bagEntries)
                if bagId == BAG_BANK then
                    foundBankInventory = true
                end
            end
            -- it's very possible that we do not have the banks contents created at this point in the inventory cache
            -- so in the case that we did not have it yet, we need to create the data and put it in the category tree
            if not foundBankInventory then
                local filteredDataTable = SHARED_INVENTORY:GenerateFullSlotData(PlaceableFurnitureFilter, BAG_BANK)
                for _, itemData in pairs(filteredDataTable) do
                    self:CreateOrUpdateItemDataEntry(itemData.bagId, itemData.slotIndex)
                end
                -- maybe we don't actually have anything in our bank though, so only try to add bank items if there are bank items to add
                if itemFurnitureCache[BAG_BANK] then
                    --this filter operation will be late since we are already building the list and the text filter is async, but it will
                    --trigger a rebuild of the categories once it completes
                    --but only do this if we have a search string, otherwise this could cause the callback to make the placement list build twice
                    if self.placeableTextFilter ~= "" then
                        self:RequestApplyPlaceableTextFilterToData()
                    end
                    self:BuildCategoryTreeData(self.placeableFurnitureCategoryTreeData, itemFurnitureCache[BAG_BANK])
                end
            end

            self:BuildCategoryTreeData(self.placeableFurnitureCategoryTreeData, self:GetPlaceableFurnitureCache(ZO_PLACEABLE_TYPE_COLLECTIBLE))
            self.placeableFurnitureCategoryTreeData:SortCategoriesRecursive()
        end,
        RefreshSingle = function(furnitureCommand)
            ApplyFurnitureCommand(self.placeableFurnitureCategoryTreeData, furnitureCommand)
        end,
    })

    self.refreshGroups:AddRefreshGroup("UpdateRetrievableFurniture",
    {
        RefreshAll = function()
            self.retrievableFurnitureCategoryTreeData:Clear()
            self:BuildCategoryTreeData(self.retrievableFurnitureCategoryTreeData, self:GetRetrievableFurnitureCache())
            self.retrievableFurnitureCategoryTreeData:SortCategoriesRecursive()
        end,
        RefreshSingle = function(furnitureCommand)
            ApplyFurnitureCommand(self.retrievableFurnitureCategoryTreeData, furnitureCommand)
        end,
    })

    self.refreshGroups:AddRefreshGroup("UpdateMarketProducts",
    {
        RefreshAll = function()
            self.marketProductCategoryTreeData:Clear()
            self:BuildCategoryTreeData(self.marketProductCategoryTreeData, self:GetMarketProductCache())
            self.marketProductCategoryTreeData:SortCategoriesRecursive()
        end,
    })

    local function FurniturePlaced(eventId, furnitureId, collectibleId)
        self:OnFurniturePlacedInHouse(furnitureId, collectibleId)
    end

    local function FurnitureRemoved(eventId, furnitureId, collectibleId)
        self:OnFurnitureRemovedFromHouse(furnitureId, collectibleId)
    end

    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_HOUSING_FURNITURE_PLACED, FurniturePlaced)
    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_HOUSING_FURNITURE_REMOVED, FurnitureRemoved)

    local function InHouseOnUpdate()
        self:InHouseOnUpdate()
    end
    local function OnPlayerActivated()
        self:InitializeFurnitureCaches()
        if GetCurrentZoneHouseId() ~= 0 then
            EVENT_MANAGER:RegisterForUpdate("SharedFurniture", 100, InHouseOnUpdate)
        else
            EVENT_MANAGER:UnregisterForUpdate("SharedFurniture")
        end
        self.lastPlayerWorldX = nil
        self.lastPlayerWorldY = nil
        self.lastPlayerWorldZ = nil
        self.lastPlayerHeading = nil
    end
    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

    local function OnMarketStateUpdated(displayGroup, marketState)
        if displayGroup == MARKET_DISPLAY_GROUP_HOUSE_EDITOR then
            self:CreateOrUpdateMarketProductCache()
        end
    end
    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_MARKET_STATE_UPDATED, function(eventId, ...) OnMarketStateUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_MARKET_PURCHASE_RESULT, function(eventId, ...) self:CreateOrUpdateMarketProductCache() end)

    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_BACKGROUND_LIST_FILTER_COMPLETE, function(eventId, ...) self:OnBackgroundListFilterComplete(...) end)

    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_MAP_PING, function(eventId, ...) self:OnMapPing(...) end)
    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_HOUSING_EDITOR_MODE_CHANGED, function(eventId, ...) self:OnHousingEditorModeChanged(...) end)
end

function ZO_SharedFurnitureManager:SetPlayerWaypointTo(retrievableFurniture)
    local furnitureId = retrievableFurniture:GetRetrievableFurnitureId()
    local worldX, worldY, worldZ = HousingEditorGetFurnitureWorldPosition(furnitureId)
    if SetPlayerWaypointByWorldLocation(worldX, worldY, worldZ) then
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, GetString(SI_HOUSING_FURNIUTRE_SET_WAYPOINT_SUCCESS))
        self.waypointToFurnitureId = furnitureId
        self.ourWaypointAdd = true
    end
end

function ZO_SharedFurnitureManager:OnMapPing(pingEventType, pingType, pingTag, x, y, isPingOwner)
    if pingTag == "waypoint" then
        if pingEventType == PING_EVENT_ADDED then
            if self.ourWaypointAdd then
                self.ourWaypointAdd = false
            end
        elseif pingEventType == PING_EVENT_REMOVED then
            --If the remove was triggered by our own add (there is only one player waypoint so setting it removes the old one) then we can ignore this.
            --Otherwise something else removed the player waypoint so clear out our state info.
            if not self.ourWaypointAdd then
                self.waypointToFurnitureId = nil
            end
        end
    end
end

function ZO_SharedFurnitureManager:OnHousingEditorModeChanged(oldMode, newMode)
    --If they picked up the furniture clear the player waypoint if it was showing the location of that furniture
    if newMode == HOUSING_EDITOR_MODE_PLACEMENT and self.waypointToFurnitureId and HousingEditorGetSelectedFurnitureId() == self.waypointToFurnitureId then
        RemovePlayerWaypoint()
    end
end

function ZO_SharedFurnitureManager:CreatePlacedFurnitureData(furnitureId)
    return ZO_RetrievableFurniture:New(furnitureId)
end

function ZO_SharedFurnitureManager:InitializeFurnitureCaches()
    --setup just the placeable collections, SharedInventory will tell us when its ready to query placeable items
    self:OnFullCollectionUpdate()
    self:CreateOrUpdateMarketProductCache()

    ZO_ClearTable(self.retrievableFurniture)

    for furnitureId in GetNextPlacedFurnitureIdIter do
        self.retrievableFurniture[zo_getSafeId64Key(furnitureId)] = self:CreatePlacedFurnitureData(furnitureId)
    end
    self.refreshGroups:RefreshAll("UpdateRetrievableFurniture")
    self:RequestApplyRetrievableTextFilterToData()
end

function ZO_SharedFurnitureManager:OnFurniturePlacedInHouse(furnitureId, collectibleId)
    if collectibleId ~= 0 then
        local furnitureCollectible = self.placeableFurniture[ZO_PLACEABLE_TYPE_COLLECTIBLE][collectibleId]
        if self:CanAddFurnitureDataToRefresh(self.placeableFurnitureCategoryTreeData, furnitureCollectible) then
            self.refreshGroups:RefreshSingle("UpdatePlacementFurniture", { target=furnitureCollectible, command=FURNITURE_COMMAND_REMOVE })
        end
        self.placeableFurniture[ZO_PLACEABLE_TYPE_COLLECTIBLE][collectibleId] = nil
        --No need to run the text filter since this is just a remove. We can notify others immediately.
        self:FireCallbacks("PlaceableFurnitureChanged")
    end

    --if an item just add to the recall list, SharedInventory will propagate the placeable list changes
    local furnitureIdKey = zo_getSafeId64Key(furnitureId)
    self.retrievableFurniture[furnitureIdKey] = self:CreatePlacedFurnitureData(furnitureId)
    self:RequestApplyRetrievableTextFilterToData()
end

function ZO_SharedFurnitureManager:OnFurnitureRemovedFromHouse(furnitureId, collectibleId)
    local furnitureIdKey = zo_getSafeId64Key(furnitureId)
    if collectibleId ~= 0 then
        self.placeableFurniture[ZO_PLACEABLE_TYPE_COLLECTIBLE][collectibleId] = ZO_PlaceableFurnitureCollectible:New(collectibleId)
        self:RequestApplyPlaceableTextFilterToData()
    end

    --if an item just remove, the inventory update will handle the placeable list changes
    self.refreshGroups:RefreshSingle("UpdateRetrievableFurniture", { target=self.retrievableFurniture[furnitureIdKey], command=FURNITURE_COMMAND_REMOVE })
    self.retrievableFurniture[furnitureIdKey] = nil
    --No need to run the text filter since this is just a remove. We can notify others immediately.
    self:FireCallbacks("RetrievableFurnitureChanged")

    --If we removed this furniture and it had a waypoint then remove the waypoint
    if self.waypointToFurnitureId then
        if AreId64sEqual(furnitureId, self.waypointToFurnitureId) then
            RemovePlayerWaypoint()
        end
    end
end

function ZO_SharedFurnitureManager:OnFullInventoryUpdate(bagId)
    self:CreateOrUpdateItemCache(bagId)
end

function ZO_SharedFurnitureManager:OnSingleSlotInventoryUpdate(bagId, slotIndex, previousSlotData)
    local slotData = SHARED_INVENTORY:GenerateSingleSlotData(bagId, slotIndex)
    if slotData and slotData.isPlaceableFurniture then
        self:CreateOrUpdateItemDataEntry(bagId, slotIndex)
        self:RequestApplyPlaceableTextFilterToData()
    elseif not slotData and previousSlotData and previousSlotData.isPlaceableFurniture then
        --the item was deleted
        local bag = self.placeableFurniture[ZO_PLACEABLE_TYPE_ITEM][bagId]
        if bag then
            local itemToRemove = bag[slotIndex]
            if self:CanAddFurnitureDataToRefresh(self.placeableFurnitureCategoryTreeData, itemToRemove) then
                self.refreshGroups:RefreshSingle("UpdatePlacementFurniture", { target = itemToRemove, command = FURNITURE_COMMAND_REMOVE })
            end
            bag[slotIndex] = nil
            --No need to run the text filter since this is just a remove. We can notify others immediately.
            self:FireCallbacks("PlaceableFurnitureChanged")
        end
    end
end

function ZO_SharedFurnitureManager:OnFullCollectionUpdate()
    self:CreateOrUpdateCollectibleCache()
end

function ZO_SharedFurnitureManager:OnSingleCollectibleUpdate(collectibleId)
    local collectibleData = COLLECTIONS_INVENTORY_SINGLETON:GetSingleCollectibleData(collectibleId, IsCollectibleCategoryPlaceableFurniture)
    if collectibleData then
        if self:CreateOrUpdateCollectibleDataEntry(collectibleId) then
            self:RequestApplyPlaceableTextFilterToData()
        end
    else
        --something made the collectible no longer valid
        placeableCollectible = self.placeableFurniture[ZO_PLACEABLE_TYPE_COLLECTIBLE][collectibleId]
        if placeableCollectible and self:CanAddFurnitureDataToRefresh(self.placeableFurnitureCategoryTreeData, placeableCollectible) then
            self.refreshGroups:RefreshSingle("UpdatePlacementFurniture", { target=placeableCollectible, command=FURNITURE_COMMAND_REMOVE })
        end
        self.placeableFurniture[ZO_PLACEABLE_TYPE_COLLECTIBLE][collectibleId] = nil
        --No need to run the text filter since this is just a remove. We can notify others immediately.
        self:FireCallbacks("PlaceableFurnitureChanged")
    end
end 

do
    local function AddEntryToCategory(categoryTreeData, entry)
        local categoryId, subcategoryId = entry:GetCategoryInfo()
        if categoryId and categoryId > 0 then
            local categoryData = categoryTreeData:GetSubcategory(categoryId)
            if not categoryData then
                categoryTreeData:AddSubcategory(categoryId, ZO_FurnitureCategory:New(categoryTreeData, categoryId))
                categoryData = categoryTreeData:GetSubcategory(categoryId)
            end

            if subcategoryId and subcategoryId > 0 then
                local subcategoryData = categoryData:GetSubcategory(subcategoryId)
                if not subcategoryData then
                    categoryData:AddSubcategory(subcategoryId, ZO_FurnitureCategory:New(categoryData, subcategoryId))
                    subcategoryData = categoryData:GetSubcategory(subcategoryId)
                end
                subcategoryData:AddEntry(entry)
            else
                categoryData:AddEntry(entry)
            end
        else
            local categoryData = categoryTreeData:GetSubcategory(ZO_FURNITURE_NEEDS_CATEGORIZATION_FAKE_CATEGORY)
            if not categoryData then
                categoryTreeData:AddSubcategory(ZO_FURNITURE_NEEDS_CATEGORIZATION_FAKE_CATEGORY, ZO_FurnitureCategory:New(categoryTreeData, ZO_FURNITURE_NEEDS_CATEGORIZATION_FAKE_CATEGORY))
                categoryData = categoryTreeData:GetSubcategory(ZO_FURNITURE_NEEDS_CATEGORIZATION_FAKE_CATEGORY)
            end
            categoryData:AddEntry(entry)
        end
    end

    function ZO_SharedFurnitureManager:BuildCategoryTreeData(categoryTreeData, data)
        for _, furniture in pairs(data) do
            if furniture:GetPassesTextFilter() then
                AddEntryToCategory(categoryTreeData, furniture)
            end
        end
    end

    function ZO_SharedFurnitureManager:AddFurnitureToCategory(categoryTreeData, furniture)
        AddEntryToCategory(categoryTreeData, furniture)
    end

    function ZO_SharedFurnitureManager:RemoveFurnitureFromCategory(categoryTreeData, furniture)
        local categoryId, subcategoryId = furniture:GetCategoryInfo()
        if categoryId and categoryId > 0 then
            local categoryData = categoryTreeData:GetSubcategory(categoryId)

            if subcategoryId and subcategoryId > 0 then
                local subcategoryData = categoryData:GetSubcategory(subcategoryId)
                subcategoryData:RemoveEntry(furniture)
            else
                categoryData:RemoveEntry(furniture)
            end
        else
            local categoryData = categoryTreeData:GetSubcategory(ZO_FURNITURE_NEEDS_CATEGORIZATION_FAKE_CATEGORY)
            categoryData:RemoveEntry(furniture)
        end
    end
end

function ZO_SharedFurnitureManager:GetPlaceableFurnitureCache(type)
    return self.placeableFurniture[type]
end

function ZO_SharedFurnitureManager:GetRetrievableFurnitureCache()
    return self.retrievableFurniture
end

function ZO_SharedFurnitureManager:GetMarketProductCache()
    return self.marketProducts
end

function ZO_SharedFurnitureManager:GetPlaceableFurnitureCategoryTreeData()
    self.refreshGroups:UpdateRefreshGroups()
    return self.placeableFurnitureCategoryTreeData
end

function ZO_SharedFurnitureManager:GetRetrievableFurnitureCategoryTreeData()
    self.refreshGroups:UpdateRefreshGroups()
    return self.retrievableFurnitureCategoryTreeData
end

function ZO_SharedFurnitureManager:GetMarketProductCategoryTreeData()
    self.refreshGroups:UpdateRefreshGroups()
    return self.marketProductCategoryTreeData
end

function ZO_SharedFurnitureManager:CreateOrUpdateItemCache(bagId)
    if bagId then
        local itemCache = self.placeableFurniture[ZO_PLACEABLE_TYPE_ITEM]
        local bagCache = itemCache[bagId]
        if bagCache then
            ZO_ClearTable(bagCache)
        end

        local filteredDataTable = SHARED_INVENTORY:GenerateFullSlotData(PlaceableFurnitureFilter, bagId)
        for _, itemData in pairs(filteredDataTable) do
            self:CreateOrUpdateItemDataEntry(itemData.bagId, itemData.slotIndex)
        end
        self.refreshGroups:RefreshAll("UpdatePlacementFurniture")
        self:RequestApplyPlaceableTextFilterToData()
    end
end

function ZO_SharedFurnitureManager:CreateOrUpdateCollectibleCache()
    local collectibleCache = self.placeableFurniture[ZO_PLACEABLE_TYPE_COLLECTIBLE]
    ZO_ClearTable(collectibleCache)
    
    local filteredDataTable = COLLECTIONS_INVENTORY_SINGLETON:GetCollectionsData(IsCollectibleCategoryPlaceableFurniture)
    for _, collectibleData in pairs(filteredDataTable) do
        self:CreateOrUpdateCollectibleDataEntry(collectibleData.collectibleId)
    end
    self.refreshGroups:RefreshAll("UpdatePlacementFurniture")
    self:RequestApplyPlaceableTextFilterToData()
end

function ZO_SharedFurnitureManager:CreateOrUpdateMarketProductCache()
    local productCache = self.marketProducts
    ZO_ClearTable(productCache)
    self.housingMarketProductPool:ReleaseAllObjects()

    local NO_SUBCATEGORY = nil
    for categoryIndex = 1, GetNumMarketProductCategories(MARKET_DISPLAY_GROUP_HOUSE_EDITOR) do
        local _, numSubcategories, numMarketProducts = GetMarketProductCategoryInfo(MARKET_DISPLAY_GROUP_HOUSE_EDITOR, categoryIndex)
        for marketProductIndex = 1, numMarketProducts do
            local productId, presentationIndex = GetMarketProductPresentationIds(MARKET_DISPLAY_GROUP_HOUSE_EDITOR, categoryIndex, NO_SUBCATEGORY, marketProductIndex)
            self:CreateMarketProductEntry(productId, presentationIndex)
        end
        for subcategoryIndex = 1, numSubcategories do
            local _, numSubCategoryMarketProducts = GetMarketProductSubCategoryInfo(MARKET_DISPLAY_GROUP_HOUSE_EDITOR, categoryIndex, subcategoryIndex)
            for marketProductIndex = 1, numSubCategoryMarketProducts do
                local productId, presentationIndex = GetMarketProductPresentationIds(MARKET_DISPLAY_GROUP_HOUSE_EDITOR, categoryIndex, subcategoryIndex, marketProductIndex)
                self:CreateMarketProductEntry(productId, presentationIndex)
            end
        end
    end

    self.refreshGroups:RefreshAll("UpdateMarketProducts")
    self:RequestApplyMarketProductTextFilterToData()
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
        placeableItem:RefreshInfo(bagId, slotIndex)
    else
        bag[slotIndex] = ZO_PlaceableFurnitureItem:New(bagId, slotIndex)
        placeableItem = bag[slotIndex]
    end
end

function ZO_SharedFurnitureManager:CreateOrUpdateCollectibleDataEntry(collectibleId)
    local existingCollectible = self.placeableFurniture[ZO_PLACEABLE_TYPE_COLLECTIBLE][collectibleId]
    if HousingEditorCanPlaceCollectible(collectibleId) then
        if existingCollectible then
            existingCollectible:RefreshInfo(collectibleId)
        else
            local newCollectible = ZO_PlaceableFurnitureCollectible:New(collectibleId)
            self.placeableFurniture[ZO_PLACEABLE_TYPE_COLLECTIBLE][collectibleId] = newCollectible
        end
        return true
    else
        if existingCollectible and self:CanAddFurnitureDataToRefresh(self.placeableFurnitureCategoryTreeData, existingCollectible) then
            self.refreshGroups:RefreshSingle("UpdatePlacementFurniture", { target=existingCollectible, command=FURNITURE_COMMAND_REMOVE })
        end
        self.placeableFurniture[ZO_PLACEABLE_TYPE_COLLECTIBLE][collectibleId] = nil
        --No need to run the text filter since this is just a remove. We can notify others immediately.
        self:FireCallbacks("PlaceableFurnitureChanged")
        return false
    end
end

function ZO_SharedFurnitureManager:CreateMarketProductEntry(marketProductId, presentationIndex)
    local marketHousingProduct = self.housingMarketProductPool:AcquireObject()
    marketHousingProduct:RefreshInfo(marketProductId, presentationIndex)
    table.insert(self.marketProducts, marketHousingProduct)
end

function ZO_SharedFurnitureManager:DoesPlayerHavePlaceableFurniture()
    return next(self.placeableFurniture[ZO_PLACEABLE_TYPE_COLLECTIBLE]) ~= nil or
        next(self.placeableFurniture[ZO_PLACEABLE_TYPE_ITEM]) ~= nil
end

function ZO_SharedFurnitureManager:DoesPlayerHaveRetrievableFurniture()
    return next(self.retrievableFurniture) ~= nil
end

function ZO_SharedFurnitureManager:AreThereMarketProducts()
    return next(self.marketProducts) ~= nil
end

do
    local DISTANCE_CHANGE_BEFORE_UPDATE = 10
    local HEADING_CHANGE_BEFORE_UPDATE_RADIANS = math.rad(5)

    function ZO_SharedFurnitureManager:InHouseOnUpdate()
        if next(self.retrievableFurniture) then
            local playerWorldX, playerWorldY, playerWorldZ = GetPlayerWorldPositionInHouse()
            local playerCameraHeading = GetPlayerCameraHeading()

            --If this is the first update in the zone or we've moved far enough from our last position then update the retrievable furniture's
            --position information relative to the player.
            local updateDistances = false
            if self.lastPlayerWorldX == nil then
                updateDistances = true
            else
                local distanceChange = zo_abs(playerWorldX - self.lastPlayerWorldX) + zo_abs(playerWorldY - self.lastPlayerWorldY) + zo_abs(playerWorldZ - self.lastPlayerWorldZ)
                if distanceChange > DISTANCE_CHANGE_BEFORE_UPDATE then
                    updateDistances = true
                end
            end
            self.lastPlayerWorldX = playerWorldX
            self.lastPlayerWorldY = playerWorldY
            self.lastPlayerWorldZ = playerWorldZ

            --If this is the first update or we are updating the distances (which also influences heading) or we have turned the camera far enough from
            --our last heading then update the retrievable furniture direction to the player
            local updateHeading = false
            if self.lastPlayerHeading == nil or updateDistances then
                updateHeading = true
            elseif zo_abs(self.lastPlayerHeading - playerCameraHeading) > HEADING_CHANGE_BEFORE_UPDATE_RADIANS then
                updateHeading = true
            end
            self.lastPlayerHeading = playerCameraHeading

            --In both cases we update all the position data. This could be changed to only touch the heading for the heading case but
            --it saves very little.
            if updateDistances or updateHeading then
                for furnitureIdKey, retrievableFurniture in pairs(self.retrievableFurniture) do
                    retrievableFurniture:RefreshPositionalData(playerWorldX, playerWorldY, playerWorldZ, playerCameraHeading)
                end
            end

            --Notify that the distances have changed
            if updateDistances then             
                self:FireCallbacks("RetrievableFurnitureDistanceAndHeadingChanged")
            elseif updateHeading then
                self:FireCallbacks("RetrievableFurnitureHeadingChanged")
            end
        end
    end
end

function ZO_SharedFurnitureManager:GetPlaceableTextFilter()
    return self.placeableTextFilter
end

function ZO_SharedFurnitureManager:SetPlaceableTextFilter(text)
    if text ~= self.placeableTextFilter then
        self.placeableTextFilter = text    
        self:RequestApplyPlaceableTextFilterToData()    
    end
end

function ZO_SharedFurnitureManager:GetRetrievableTextFilter()
    return self.retrievableTextFilter
end

function ZO_SharedFurnitureManager:SetRetrievableTextFilter(text)
    if text ~= self.retrievableTextFilter then
        self.retrievableTextFilter = text    
        self:RequestApplyRetrievableTextFilterToData()    
    end
end

function ZO_SharedFurnitureManager:GetMarketProductTextFilter()
    return self.marketProductTextFilter
end

function ZO_SharedFurnitureManager:SetMarketProductTextFilter(text)
    if text ~= self.marketProductTextFilter then
        self.marketProductTextFilter = text    
        self:RequestApplyMarketProductTextFilterToData()    
    end
end

function ZO_SharedFurnitureManager:CanAddFurnitureDataToRefresh(categoryTree, furnitureData)
    local canAddToRefresh = true
    local categoryId, subcategoryId = furnitureData:GetCategoryInfo()
    if categoryId and categoryId > 0 then
        local categoryData = categoryTree:GetSubcategory(categoryId)
        canAddToRefresh = categoryData ~= nil

        if canAddToRefresh and subcategoryId and subcategoryId > 0 then
            local subcategoryData = categoryData:GetSubcategory(subcategoryId)
            canAddToRefresh = subcategoryData ~= nil
        end
    end

    return canAddToRefresh
end

--Starts a background task to filter the placeable list entries using the text input. This will eventually result in the category list being marked dirty
--and others being notified to update once the filter completes.
function ZO_SharedFurnitureManager:RequestApplyPlaceableTextFilterToData()
    --Cancel any in progress filtering so we can do a new one
    for _, taskId in pairs(self.inProgressPlaceableFurnitureTextFilterTaskIds) do
        DestroyBackgroundListFilter(taskId)
    end
        
    --If we have filter text than create the tasks
    if self.placeableTextFilter ~= "" then
        --Inventory Items
        local itemTaskId = CreateBackgroundListFilter(BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, self.placeableTextFilter)
        self.inProgressPlaceableFurnitureTextFilterTaskIds[ZO_PLACEABLE_TYPE_ITEM] = itemTaskId
        AddBackgroundListFilterType(itemTaskId, BACKGROUND_LIST_FILTER_TYPE_NAME)
        for bagId, slots in pairs(self.placeableFurniture[ZO_PLACEABLE_TYPE_ITEM]) do
            for slotId, slotData in pairs(slots) do
                slotData:SetPassesTextFilter(false)
                AddBackgroundListFilterEntry(itemTaskId, bagId, slotId)
            end
        end
        StartBackgroundListFilter(itemTaskId)

        --Collectibles
        local collectibleTaskId = CreateBackgroundListFilter(BACKGROUND_LIST_FILTER_TARGET_COLLECTIBLE_ID, self.placeableTextFilter)
        self.inProgressPlaceableFurnitureTextFilterTaskIds[ZO_PLACEABLE_TYPE_COLLECTIBLE] = collectibleTaskId
        AddBackgroundListFilterType(collectibleTaskId, BACKGROUND_LIST_FILTER_TYPE_NAME)
        for collectibleId, collectibleData in pairs(self.placeableFurniture[ZO_PLACEABLE_TYPE_COLLECTIBLE]) do
            collectibleData:SetPassesTextFilter(false)
            AddBackgroundListFilterEntry(collectibleTaskId, collectibleId)
        end
        StartBackgroundListFilter(collectibleTaskId)
    --If we have no search text then everything passes, so set everything to true now.
    else
        --Inventory Items
        for bagId, slots in pairs(self.placeableFurniture[ZO_PLACEABLE_TYPE_ITEM]) do
            for slotId, slotData in pairs(slots) do
                slotData:SetPassesTextFilter(true)
            end
        end

        --Collectibles
        for collectibleId, collectibleData in pairs(self.placeableFurniture[ZO_PLACEABLE_TYPE_COLLECTIBLE]) do
            collectibleData:SetPassesTextFilter(true)
        end

        --Mark the placeable furniture category data dirty and let others know about that
        self.refreshGroups:RefreshAll("UpdatePlacementFurniture")
        self:FireCallbacks("PlaceableFurnitureChanged")
    end
end

--Starts a background task to filter the retrievable list entries using the text input. This will eventually result in the category list being marked dirty
--and others being notified to update once the filter completes.
function ZO_SharedFurnitureManager:RequestApplyRetrievableTextFilterToData()
    if self.inProgressRetrievableTextFilterTaskId then
        DestroyBackgroundListFilter(self.inProgressRetrievableTextFilterTaskId)
    end

    --If we have filter text than create the task
    if self.retrievableTextFilter ~= "" then
        local furnitureTaskId = CreateBackgroundListFilter(BACKGROUND_LIST_FILTER_TARGET_FURNITURE_ID, self.retrievableTextFilter)
        self.inProgressRetrievableFurnitureTextFilterTaskId = furnitureTaskId
        AddBackgroundListFilterType(furnitureTaskId, BACKGROUND_LIST_FILTER_TYPE_NAME)
        for _, furnitureData in pairs(self.retrievableFurniture) do
            furnitureData:SetPassesTextFilter(false)
            local furnitureId = furnitureData:GetFurnitureId()
            AddBackgroundListFilterEntry64(furnitureTaskId, furnitureId) 
        end
        StartBackgroundListFilter(furnitureTaskId)
    --If we have no search text then everything passes, so set everything to true now.
    else
        for _, furnitureData in pairs(self.retrievableFurniture) do
            furnitureData:SetPassesTextFilter(true)
        end

        --Mark the retrievable furniture category data dirty and let others know about that
        self.refreshGroups:RefreshAll("UpdateRetrievableFurniture")
        self:FireCallbacks("RetrievableFurnitureChanged")
    end
end

function ZO_SharedFurnitureManager:RequestApplyMarketProductTextFilterToData()
    if self.inProgressMarketProductTextFilterTaskId then
        DestroyBackgroundListFilter(self.inProgressMarketProductTextFilterTaskId)
    end

    --If we have filter text than create the task
    if self.marketProductTextFilter ~= "" then
        local marketProductTaskId = CreateBackgroundListFilter(BACKGROUND_LIST_FILTER_TARGET_MARKET_PRODUCT_ID, self.marketProductTextFilter)
        self.inProgressMarketProductTextFilterTaskId = marketProductTaskId
        AddBackgroundListFilterType(marketProductTaskId, BACKGROUND_LIST_FILTER_TYPE_NAME)
        AddBackgroundListFilterType(marketProductTaskId, BACKGROUND_LIST_FILTER_TYPE_DESCRIPTION)
        AddBackgroundListFilterType(marketProductTaskId, BACKGROUND_LIST_FILTER_TYPE_SEARCH_KEYWORDS)
        for i, marketProductData in ipairs(self.marketProducts) do
            marketProductData:SetPassesTextFilter(false)
            AddBackgroundListFilterEntry(marketProductTaskId, marketProductData:GetMarketProductId())
        end
        StartBackgroundListFilter(marketProductTaskId)
    --If we have no search text then everything passes, so set everything to true now.
    else
        for i, marketProductData in ipairs(self.marketProducts) do
            marketProductData:SetPassesTextFilter(true)
        end

        --Mark the market product category data dirty and let others know about that
        self.refreshGroups:RefreshAll("UpdateMarketProducts")
        self:FireCallbacks("MarketProductsChanged")
    end
end

function ZO_SharedFurnitureManager:TryMarkPlaceableBackgroundListFilterComplete(placeableType, taskId)
    if self.inProgressPlaceableFurnitureTextFilterTaskIds[placeableType] == taskId then
        self.inProgressPlaceableFurnitureTextFilterTaskIds[placeableType] = nil
        self.completePlaceableFurnitureTextFilterTaskIds[placeableType] = taskId
        return true
    end
    return false
end

function ZO_SharedFurnitureManager:OnBackgroundListFilterComplete(taskId)
    local CHANGED_FROM_SEARCH = true

    --Retrievable
    if taskId == self.inProgressRetrievableFurnitureTextFilterTaskId then
        self.inProgressRetrievableFurnitureTextFilterTaskId = nil

        --Set everything that passed the filter to true
        local retrievableFurnitureDataCache = self.retrievableFurniture
        if retrievableFurnitureDataCache then
            for i = 1, GetNumBackgroundListFilterResults(taskId) do
                local furnitureId = GetBackgroundListFilterResult64(taskId, i)
                local furnitureIdKey = zo_getSafeId64Key(furnitureId)
                local furnitureData = retrievableFurnitureDataCache[furnitureIdKey]
                if furnitureData then
                    furnitureData:SetPassesTextFilter(true)
                end
            end
        end
        DestroyBackgroundListFilter(taskId)

        --Mark the retrievable furniture category data dirty and let others know about that
        self.refreshGroups:RefreshAll("UpdateRetrievableFurniture")
        self:FireCallbacks("RetrievableFurnitureChanged", CHANGED_FROM_SEARCH)
    --Market Product
    elseif taskId == self.inProgressMarketProductTextFilterTaskId then
        self.inProgressMarketProductTextFilterTaskId = nil

        local marketProductDataCache = self.marketProducts
        if marketProductDataCache then
            for i = 1, GetNumBackgroundListFilterResults(taskId) do
                local marketProductId = GetBackgroundListFilterResult(taskId, i)
                for _, marketProductData in ipairs(marketProductDataCache) do
                    if marketProductData:GetMarketProductId() == marketProductId then
                        marketProductData:SetPassesTextFilter(true)
                    end
                end
            end
        end
        DestroyBackgroundListFilter(taskId)

        --Mark the retrievable furniture category data dirty and let others know about that
        self.refreshGroups:RefreshAll("UpdateMarketProducts")
        self:FireCallbacks("MarketProductsChanged", CHANGED_FROM_SEARCH)
    --Item/Collectible that can be placed
    else
        --Mark that it was completed.
        if not self:TryMarkPlaceableBackgroundListFilterComplete(ZO_PLACEABLE_TYPE_ITEM, taskId) then
            self:TryMarkPlaceableBackgroundListFilterComplete(ZO_PLACEABLE_TYPE_COLLECTIBLE, taskId)
        end

        --We only trigger the update when all outstanding filter tasks are done. This is to
        --prevent building the categories 3 times for each letter typed in the search box and also to prevent having the
        --categories rebuilt with only some of the visibility states know.
        if next(self.inProgressPlaceableFurnitureTextFilterTaskIds) == nil then
            --Inventory Items
            local itemTaskId = self.completePlaceableFurnitureTextFilterTaskIds[ZO_PLACEABLE_TYPE_ITEM]
            local itemDataCache = self.placeableFurniture[ZO_PLACEABLE_TYPE_ITEM]
            if itemDataCache then
                for i = 1, GetNumBackgroundListFilterResults(itemTaskId) do
                    local bag, slot = GetBackgroundListFilterResult(itemTaskId, i)
                    local bagCache = itemDataCache[bag]
                    if bagCache then
                        local slotData = bagCache[slot]
                        if slotData then
                            slotData:SetPassesTextFilter(true)
                        end
                    end
                end
            end
            DestroyBackgroundListFilter(itemTaskId)

            --Collectibles
            local collectibleTaskId = self.completePlaceableFurnitureTextFilterTaskIds[ZO_PLACEABLE_TYPE_COLLECTIBLE]
            local collectibleDataCache = self.placeableFurniture[ZO_PLACEABLE_TYPE_COLLECTIBLE]
            if collectibleDataCache then
                for i = 1, GetNumBackgroundListFilterResults(collectibleTaskId) do
                    local collectibleId = GetBackgroundListFilterResult(collectibleTaskId, i)
                    local collectibleData = collectibleDataCache[collectibleId]
                    if collectibleData then
                        collectibleData:SetPassesTextFilter(true)
                    end
                end
            end
            DestroyBackgroundListFilter(collectibleTaskId)

            --Mark the placeable furniture category data dirty and let others know about that
            self.refreshGroups:RefreshAll("UpdatePlacementFurniture")
            self:FireCallbacks("PlaceableFurnitureChanged", CHANGED_FROM_SEARCH)
        end
    end
end

SHARED_FURNITURE = ZO_SharedFurnitureManager:New()