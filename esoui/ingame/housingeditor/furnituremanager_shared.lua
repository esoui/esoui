ZO_FURNITURE_NEEDS_CATEGORIZATION_FAKE_CATEGORY = "NEEDS_CATEGORY"

ZO_PLACEABLE_TYPE_ITEM = 1
ZO_PLACEABLE_TYPE_COLLECTIBLE = 2

ZO_PLACEABLE_FURNITURE_BAGS =
{
    [BAG_BACKPACK] = true,
    [BAG_BANK] = true,
    [BAG_SUBSCRIBER_BANK] = true,
    [BAG_HOUSE_BANK_ONE] = true,
    [BAG_HOUSE_BANK_TWO] = true,
    [BAG_HOUSE_BANK_THREE] = true,
    [BAG_HOUSE_BANK_FOUR] = true,
    [BAG_HOUSE_BANK_FIVE] = true,
    [BAG_HOUSE_BANK_SIX] = true,
    [BAG_HOUSE_BANK_SEVEN] = true,
    [BAG_HOUSE_BANK_EIGHT] = true,
    [BAG_HOUSE_BANK_NINE] = true,
    [BAG_HOUSE_BANK_TEN] = true,
}

-- Make sure no new bags have been added since the last time we updated ZO_PLACEABLE_FURNITURE_BAGS
-- If a new bag was added and it's possible to place furniture from it add it to the table
internalassert(BAG_MAX_VALUE == 17, "Update ZO_SharedFurnitureManager to handle new bag")

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
    self.placeableFurnitureCategoryTreeData = ZO_RootFurnitureCategory:New()
    self.inProgressPlaceableFurnitureTextFilterTaskIds = { }
    self.completePlaceableFurnitureTextFilterTaskIds = { }
    self.placeableTextFilter = ""

    self.retrievableFurnitureCategoryTreeData = ZO_RootFurnitureCategory:New()
    self.retrievableFurniture = {}
    self.retrievableTextFilter = ""

    self.marketProductCategoryTreeData = ZO_RootFurnitureCategory:New()
    self.marketProducts = {}
    self.marketProductIdToMarketProduct = {}
    self.marketProductTextFilter = ""

    self.placementFurnitureTheme = FURNITURE_THEME_TYPE_ALL
    self.purchaseFurnitureTheme = FURNITURE_THEME_TYPE_ALL

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
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", function(...) self:OnCollectionUpdated(...) end)

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
            for bagId, bagEntries in pairs(itemFurnitureCache) do
                self:BuildCategoryTreeData(self.placeableFurnitureCategoryTreeData, bagEntries, self.placementFurnitureTheme)
            end
            self:BuildCategoryTreeData(self.placeableFurnitureCategoryTreeData, self:GetPlaceableFurnitureCache(ZO_PLACEABLE_TYPE_COLLECTIBLE), self.placementFurnitureTheme)
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
            self:BuildCategoryTreeData(self.marketProductCategoryTreeData, self:GetMarketProductCache(), self.purchaseFurnitureTheme)
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

            -- make sure all furniture found in house banks are populated in this manager
            for bagId = BAG_HOUSE_BANK_ONE, BAG_HOUSE_BANK_TEN do
                SHARED_INVENTORY:GetOrCreateBagCache(bagId)
            end
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
            self:BuildMarketProductCache()
        end
    end
    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_MARKET_STATE_UPDATED, function(eventId, ...) OnMarketStateUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_MARKET_PURCHASE_RESULT, function(eventId, ...) self:UpdateMarketProductCache() end)

    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_BACKGROUND_LIST_FILTER_COMPLETE, function(eventId, ...) self:OnBackgroundListFilterComplete(...) end)

    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_MAP_PING, function(eventId, ...) self:OnMapPing(...) end)
    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_HOUSING_EDITOR_MODE_CHANGED, function(eventId, ...) self:OnHousingEditorModeChanged(...) end)
end

function ZO_SharedFurnitureManager:SetPlayerWaypointTo(retrievableFurniture)
    local furnitureId = retrievableFurniture:GetRetrievableFurnitureId()
    SetHousingEditorTrackedFurnitureId(furnitureId)
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
                ResetHousingEditorTrackedFurnitureId()
            end
        end
    end
end

function ZO_SharedFurnitureManager:OnHousingEditorModeChanged(oldMode, newMode)
    --If they picked up the furniture clear the player waypoint if it was showing the location of that furniture
    if newMode == HOUSING_EDITOR_MODE_PLACEMENT and self.waypointToFurnitureId and HousingEditorGetSelectedFurnitureId() == self.waypointToFurnitureId then
        RemovePlayerWaypoint()
        ResetHousingEditorTrackedFurnitureId()
    end
end

function ZO_SharedFurnitureManager:CreatePlacedFurnitureData(furnitureId)
    return ZO_RetrievableFurniture:New(furnitureId)
end

function ZO_SharedFurnitureManager:InitializeFurnitureCaches()
    --setup just the placeable collections, SharedInventory will tell us when its ready to query placeable items
    self:CreateOrUpdateCollectibleCache()
    self:BuildMarketProductCache()

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

        --If we removed a house bank, tell the player that they need to re-place it to get those items
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
        if collectibleData and collectibleData:GetCategoryType() == COLLECTIBLE_CATEGORY_TYPE_HOUSE_BANK then
            local NO_SOUND = nil
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, NO_SOUND, zo_strformat(SI_HOUSING_FURNITURE_PUT_AWAY_HOUSE_BANK_WARNING, collectibleData:GetName()))
        end
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
            ResetHousingEditorTrackedFurnitureId()
        end
    end
end

function ZO_SharedFurnitureManager:OnFullInventoryUpdate(bagId)
    if ZO_PLACEABLE_FURNITURE_BAGS[bagId] then
        self:CreateOrUpdateItemCache(bagId)
    end
end

function ZO_SharedFurnitureManager:OnSingleSlotInventoryUpdate(bagId, slotIndex, previousSlotData)
    if ZO_PLACEABLE_FURNITURE_BAGS[bagId] then
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
end

function ZO_SharedFurnitureManager:OnCollectionUpdated(collectionUpdateType, collectiblesByNewUnlockState)
    if collectionUpdateType == ZO_COLLECTION_UPDATE_TYPE.REBUILD then
        self:CreateOrUpdateCollectibleCache()
    else
        local requestApplyPlaceableTextFilterToData = false
        local fireRetrievableFurnitureChanged = false
        for _, unlockStateTable in pairs(collectiblesByNewUnlockState) do
            for _, collectibleData in ipairs(unlockStateTable) do
                if collectibleData:IsPlaceableFurniture() then
                    local collectibleId = collectibleData:GetId()
                    if self:CreateOrUpdateCollectibleDataEntry(collectibleId) then
                        requestApplyPlaceableTextFilterToData = true
                    end
                    --Update retrievable furniture that is backed by a collectible
                    for _, furnitureData in pairs(self.retrievableFurniture) do
                        if furnitureData:GetCollectibleId() == collectibleId then
                            furnitureData:RefreshInfo(furnitureData:GetRetrievableFurnitureId())
                            fireRetrievableFurnitureChanged = true
                            break
                        end
                    end
                end
            end
        end

        if requestApplyPlaceableTextFilterToData then
            self:RequestApplyPlaceableTextFilterToData()
        end

        if fireRetrievableFurnitureChanged then
            self:FireCallbacks("RetrievableFurnitureChanged")
        end
    end
    self:UpdateMarketProductCache()
end

do
    local function AddEntryToCategory(categoryTreeData, entry)
        local categoryId, subcategoryId = entry:GetCategoryInfo()

        local categoryData = categoryTreeData:GetOrCreateMostSpecificCategory(categoryId, subcategoryId)
        categoryData:AddEntry(entry)
    end

    function ZO_SharedFurnitureManager:BuildCategoryTreeData(categoryTreeData, data, theme)
        local furnitureTheme = theme or FURNITURE_THEME_TYPE_ALL
        for _, furniture in pairs(data) do
            if furniture:GetPassesTextFilter() and furniture:PassesTheme(furnitureTheme) then
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

    local SORTED = true
    local filteredDataTable = ZO_COLLECTIBLE_DATA_MANAGER:GetAllCollectibleDataObjects({ ZO_CollectibleCategoryData.IsStandardCategory }, { ZO_CollectibleData.IsPlaceableFurniture, ZO_CollectibleData.IsUnlocked }, SORTED)
    for _, collectibleData in pairs(filteredDataTable) do
        self:CreateOrUpdateCollectibleDataEntry(collectibleData:GetId())
    end
    self.refreshGroups:RefreshAll("UpdatePlacementFurniture")
    self:RequestApplyPlaceableTextFilterToData()
end

function ZO_SharedFurnitureManager:BuildMarketProductCache()
    local productCache = self.marketProducts
    ZO_ClearNumericallyIndexedTable(productCache)
    ZO_ClearTable(self.marketProductIdToMarketProduct)
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

function ZO_SharedFurnitureManager:UpdateMarketProductCache()
    for index, marketHousingProduct in ipairs(self.marketProducts) do
        marketHousingProduct:RefreshInfo(marketHousingProduct.marketProductId, marketHousingProduct.presentationIndex)
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
    self.marketProductIdToMarketProduct[marketProductId] = marketHousingProduct
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

function ZO_SharedFurnitureManager:GetPlacementFurnitureTheme()
    return self.placementFurnitureTheme
end

function ZO_SharedFurnitureManager:SetPlacementFurnitureTheme(theme)
    if self.placementFurnitureTheme ~= theme then
        self.placementFurnitureTheme = theme
        self.refreshGroups:RefreshAll("UpdatePlacementFurniture")
        self:FireCallbacks("PlaceableFurnitureChanged")
    end
end

function ZO_SharedFurnitureManager:GetPurchaseFurnitureTheme()
    return self.purchaseFurnitureTheme
end

function ZO_SharedFurnitureManager:SetPurchaseFurnitureTheme(theme)
    if self.purchaseFurnitureTheme ~= theme then
        self.purchaseFurnitureTheme = theme
        self.refreshGroups:RefreshAll("UpdateMarketProducts")
        self:FireCallbacks("MarketProductsChanged")
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

function ZO_SharedFurnitureManager:CanFilterByText(text)
    -- Very broad searches have bad performance implications: The search itself is asynchronous (and snappy), but updating UI to reflect the search is not
    return ZoUTF8StringLength(text) >= 2
end

function ZO_SharedFurnitureManager:RequestApplyPlaceableTextFilterToData()
    --Cancel any in progress filtering so we can do a new one
    for _, taskId in pairs(self.inProgressPlaceableFurnitureTextFilterTaskIds) do
        DestroyBackgroundListFilter(taskId)
    end
        
    --If we have filter text than create the tasks
    if self:CanFilterByText(self.placeableTextFilter) then
        --Inventory Items
        local itemTaskId = CreateBackgroundListFilter(BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, self.placeableTextFilter)
        self.inProgressPlaceableFurnitureTextFilterTaskIds[ZO_PLACEABLE_TYPE_ITEM] = itemTaskId
        AddBackgroundListFilterType(itemTaskId, BACKGROUND_LIST_FILTER_TYPE_NAME)
        AddBackgroundListFilterType(itemTaskId, BACKGROUND_LIST_FILTER_TYPE_FURNITURE_KEYWORDS)
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
        AddBackgroundListFilterType(collectibleTaskId, BACKGROUND_LIST_FILTER_TYPE_FURNITURE_KEYWORDS)
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
    if self:CanFilterByText(self.retrievableTextFilter) then
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
    if self:CanFilterByText(self.marketProductTextFilter) then
        local marketProductTaskId = CreateBackgroundListFilter(BACKGROUND_LIST_FILTER_TARGET_MARKET_PRODUCT_ID, self.marketProductTextFilter)
        self.inProgressMarketProductTextFilterTaskId = marketProductTaskId
        AddBackgroundListFilterType(marketProductTaskId, BACKGROUND_LIST_FILTER_TYPE_NAME)
        AddBackgroundListFilterType(marketProductTaskId, BACKGROUND_LIST_FILTER_TYPE_DESCRIPTION)
        AddBackgroundListFilterType(marketProductTaskId, BACKGROUND_LIST_FILTER_TYPE_SEARCH_KEYWORDS)
        AddBackgroundListFilterType(marketProductTaskId, BACKGROUND_LIST_FILTER_TYPE_FURNITURE_KEYWORDS)
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

        for i = 1, GetNumBackgroundListFilterResults(taskId) do
            local marketProductId = GetBackgroundListFilterResult(taskId, i)
            local marketProductData = self.marketProductIdToMarketProduct[marketProductId]
            if marketProductData then
                marketProductData:SetPassesTextFilter(true)
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