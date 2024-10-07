ZO_FURNITURE_NEEDS_CATEGORIZATION_FAKE_CATEGORY = "NEEDS_CATEGORY"
ZO_FURNITURE_PATH_NODES_FAKE_CATEGORY = "PATH_NODES"

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

ZO_HOUSING_FURNITURE_LOCATION_FILTER_BAGS =
{
    [HOUSING_FURNITURE_LOCATION_FILTER_ALL] = nil, -- nil is interpreted as "match any location"
    [HOUSING_FURNITURE_LOCATION_FILTER_COLLECTIBLES] = nil,
    [HOUSING_FURNITURE_LOCATION_FILTER_BACKPACK] =
    {
        [BAG_BACKPACK] = true,
    },
    [HOUSING_FURNITURE_LOCATION_FILTER_BANK] =
    {
        [BAG_BANK] = true,
        [BAG_SUBSCRIBER_BANK] = true,
    },
    [HOUSING_FURNITURE_LOCATION_FILTER_STORAGE] =
    {
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
    },
}

-- Make sure no new bags have been added since the last time we updated ZO_PLACEABLE_FURNITURE_BAGS
-- If a new bag was added and it's possible to place furniture from it add it to the table
internalassert(BAG_MAX_VALUE == 18, "Update ZO_SharedFurnitureManager to handle new bag")

local FURNITURE_COMMAND_REMOVE = 1
local FURNITURE_COMMAND_REMOVE_PATH_NODE = 2
local FURNITURE_COMMAND_ADD_PATH_NODE = 3
local FURNITURE_COMMAND_REMOVE_PATH = 4

local function GetNextPlacedFurnitureIdIter(state, var1)
    return GetNextPlacedHousingFurnitureId(var1)
end

local function GetNextPathedFurnitureIdIter(state, var1)
    return GetNextPathedHousingFurnitureId(var1)
end

local function PlaceableFurnitureFilter(itemData)
    return itemData.isPlaceableFurniture
end

ZO_SharedFurnitureManager = ZO_InitializingCallbackObject:Subclass()

function ZO_SharedFurnitureManager:Initialize()
    self.placeableFurniture = 
    {
        [ZO_PLACEABLE_TYPE_COLLECTIBLE] = {},
        [ZO_PLACEABLE_TYPE_ITEM] = {},
    }
    self.placeableFurnitureCategoryTreeData = ZO_RootFurnitureCategory:New("placeable")
    self.isPlaceableFiltered = false

    self.retrievableFurnitureCategoryTreeData = ZO_RootFurnitureCategory:New("retrievable")
    self.retrievableFurniture = {}
    self.isRetrievableFiltered = false

    self.marketProductCategoryTreeData = ZO_RootFurnitureCategory:New("market")
    self.marketProducts = {}
    self.marketProductIdToMarketProduct = {}
    self.isMarketFiltered = false

    self.pathableFurnitureCategoryTreeData = ZO_RootFurnitureCategory:New("pathable")
    self.pathNodesPerFurniture = {}

    self.housingMarketProductPool = ZO_ObjectPool:New(ZO_HousingMarketProduct, ZO_ObjectPool_DefaultResetObject)

    local placeableItemsFilterTargetDescriptor =
    {
        [BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT] =
        {
            searchFilterList =
            {
                BACKGROUND_LIST_FILTER_TYPE_NAME,
                BACKGROUND_LIST_FILTER_TYPE_ITEM_TAGS,
                BACKGROUND_LIST_FILTER_TYPE_FURNITURE_KEYWORDS,
            },
            primaryKeys = function()
                local placebleItems = {}
                for bagId, data in pairs(self.placeableFurniture[ZO_PLACEABLE_TYPE_ITEM]) do
                    table.insert(placebleItems, bagId)
                end
                return placebleItems
            end,
        },
        [BACKGROUND_LIST_FILTER_TARGET_COLLECTIBLE_ID] =
        {
            searchFilterList =
            {
                BACKGROUND_LIST_FILTER_TYPE_NAME,
                BACKGROUND_LIST_FILTER_TYPE_FURNITURE_KEYWORDS,
            },
            primaryKeys = function()
                local placebleCollectibles = {}
                for id, data in pairs(self:GetPlaceableFurnitureCache(ZO_PLACEABLE_TYPE_COLLECTIBLE)) do
                    table.insert(placebleCollectibles, id)
                end
                return placebleCollectibles
            end,
        },
    }
    TEXT_SEARCH_MANAGER:SetupContextTextSearch("housePlaceableItemsTextSearch", placeableItemsFilterTargetDescriptor)

    local productsFilterTargetDescriptor =
    {
        [BACKGROUND_LIST_FILTER_TARGET_MARKET_PRODUCT_ID] =
        {
            searchFilterList =
            {
                BACKGROUND_LIST_FILTER_TYPE_NAME,
                BACKGROUND_LIST_FILTER_TYPE_DESCRIPTION,
                BACKGROUND_LIST_FILTER_TYPE_SEARCH_KEYWORDS,
                BACKGROUND_LIST_FILTER_TYPE_FURNITURE_KEYWORDS,
                BACKGROUND_LIST_FILTER_TYPE_ITEM_TAGS,
            },
            primaryKeys = function()
                local productIdList = {}
                for i, data in ipairs(self.marketProducts) do
                    table.insert(productIdList, data.marketProductId)
                end
                return productIdList
            end,
        },
    }
    TEXT_SEARCH_MANAGER:SetupContextTextSearch("houseProductsTextSearch", productsFilterTargetDescriptor)

    local furnitureFilterTargetDescriptor =
    {
        [BACKGROUND_LIST_FILTER_TARGET_FURNITURE_ID] =
        {
            searchFilterList =
            {
                BACKGROUND_LIST_FILTER_TYPE_NAME,
            },
            primaryKeys = function()
                local furnitureIdList = {}
                for id, furnitureData in pairs(self.retrievableFurniture) do
                    table.insert(furnitureIdList, furnitureData:GetFurnitureId())
                end
                return furnitureIdList
            end,
        },
    }
    TEXT_SEARCH_MANAGER:SetupContextTextSearch("houseFurnitureTextSearch", furnitureFilterTargetDescriptor)

    -- Order matters
    self:RegisterForEvents()
    self:ResetFurnitureFilters()
end

function ZO_SharedFurnitureManager:RegisterForEvents()
    SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", function(bagId) self:OnFullInventoryUpdate(bagId) end)
    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", function(...) self:OnSingleSlotInventoryUpdate(...) end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", function(...) self:OnCollectionUpdated(...) end)
    HOUSING_EDITOR_STATE:RegisterCallback("HouseChanged", function(...) self:OnHouseChanged(...) end)

    local function ApplyFurnitureCommand(categoryTreeData, furnitureCommand)
        if furnitureCommand.command == FURNITURE_COMMAND_REMOVE then
            self:RemoveFurnitureFromCategory(categoryTreeData, furnitureCommand.target)
        elseif furnitureCommand.command == FURNITURE_COMMAND_REMOVE_PATH_NODE then
            self:RemovePathNodeFromCategory(categoryTreeData, furnitureCommand.target, furnitureCommand.pathIndex)
        elseif furnitureCommand.command == FURNITURE_COMMAND_REMOVE_PATH then
             self:RemovePathFromCategory(categoryTreeData, furnitureCommand.target)
        elseif furnitureCommand.command == FURNITURE_COMMAND_ADD_PATH_NODE then
            self:AddPathNodeToCategory(categoryTreeData, furnitureCommand.target, furnitureCommand.pathIndex)
        end
    end

    self.refreshGroups = ZO_Refresh:New()
    self.refreshGroups:AddRefreshGroup("UpdatePlacementFurniture",
    {
        RefreshAll = function()
            self.refreshingPlacementFurniture = true
            self.placeableFurnitureCategoryTreeData:Clear()
            self.pathableFurnitureCategoryTreeData:Clear()

            local itemFurnitureCache = self:GetPlaceableFurnitureCache(ZO_PLACEABLE_TYPE_ITEM)
            for bagId, bagEntries in pairs(itemFurnitureCache) do
                self:BuildCategoryTreeData(self.placeableFurnitureCategoryTreeData, bagEntries, self.placementFurnitureTheme)
            end
            local collectibleFurnitureCache = self:GetPlaceableFurnitureCache(ZO_PLACEABLE_TYPE_COLLECTIBLE)
            self:BuildCategoryTreeData(self.placeableFurnitureCategoryTreeData, collectibleFurnitureCache, self.placementFurnitureTheme)
            self.placeableFurnitureCategoryTreeData:SortCategoriesRecursive()

            local function IsFurniturePathable(furniture)
                return furniture:IsPathable()
            end
            self:BuildCategoryTreeData(self.pathableFurnitureCategoryTreeData, collectibleFurnitureCache, FURNITURE_THEME_TYPE_ALL, IsFurniturePathable)
            self.pathableFurnitureCategoryTreeData:SortCategoriesRecursive()
            self.refreshingPlacementFurniture = false
        end,
        RefreshSingle = function(furnitureCommand)
            ApplyFurnitureCommand(self.placeableFurnitureCategoryTreeData, furnitureCommand)
            ApplyFurnitureCommand(self.pathableFurnitureCategoryTreeData, furnitureCommand)
        end,
    })

    self.refreshGroups:AddRefreshGroup("UpdateRetrievableFurniture",
    {
        RefreshAll = function()
            self.retrievableFurnitureCategoryTreeData:Clear()
            self:BuildCategoryTreeData(self.retrievableFurnitureCategoryTreeData, self:GetRetrievableFurnitureCache())
            self:AppendPathNodes(self.retrievableFurnitureCategoryTreeData)
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

    local function FurnitureMoved(eventId, furnitureId)
        self.forcePositionalDataUpdate = true
    end

    local function PathNodeAdded(eventId, furnitureId, pathIndex)
        self:OnPathNodeAddedToFurniture(furnitureId, pathIndex)
    end

    local function PathNodeRemoved(eventId, furnitureId, pathIndex)
        self:OnPathNodeRemovedFromFurniture(furnitureId, pathIndex)
    end

    local function PathNodeMoved(eventId, furnitureId, pathIndex)
        self.forcePositionalDataUpdate = true
    end

    local function PathNodesRestored(eventId, furnitureId)
        self:OnPathNodesRestoredToFurniture(furnitureId)
    end

    local function PathStartingNodeIndexChanged(eventId, furnitureId)
        self:OnPathStartingNodeIndexChanged(furnitureId)
    end

    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_HOUSING_FURNITURE_PLACED, FurniturePlaced)
    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_HOUSING_FURNITURE_REMOVED, FurnitureRemoved)
    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_HOUSING_FURNITURE_MOVED, FurnitureMoved)
    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_HOUSING_FURNITURE_PATH_NODE_ADDED, PathNodeAdded)
    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_HOUSING_FURNITURE_PATH_NODE_REMOVED, PathNodeRemoved)
    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_HOUSING_FURNITURE_PATH_NODE_MOVED, PathNodeMoved)
    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_HOUSING_FURNITURE_PATH_NODES_RESTORED, PathNodesRestored)
    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_HOUSING_FURNITURE_PATH_STARTING_NODE_INDEX_CHANGED, PathStartingNodeIndexChanged)

    local function InHouseOnUpdate()
        self:InHouseOnUpdate()
    end

    local function OnPlayerActivated()
        self:RebuildFurnitureCaches()

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

    local function OnMarketProductAvailabilityUpdated(displayGroup)
        if displayGroup == MARKET_DISPLAY_GROUP_HOUSE_EDITOR then
            self:BuildMarketProductCache()
        end
    end
    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_MARKET_PRODUCT_AVAILABILITY_UPDATED, function(eventId, ...) OnMarketProductAvailabilityUpdated(...) end)

    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_MARKET_PURCHASE_RESULT, function(eventId, ...) self:UpdateMarketProductCache() end)
    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_MAP_PING, function(eventId, ...) self:OnMapPing(...) end)
    EVENT_MANAGER:RegisterForEvent("SharedFurniture", EVENT_HOUSING_EDITOR_MODE_CHANGED, function(eventId, ...) self:OnHousingEditorModeChanged(...) end)
end

function ZO_SharedFurnitureManager:ResetFurnitureFilters()
    self.isPlaceableFiltered = false
    self.isMarketFiltered = false
    self.isRetrievableFiltered = false

    self:SetPlacementFurnitureFilters(HOUSING_FURNITURE_BOUND_FILTER_ALL, HOUSING_FURNITURE_LOCATION_FILTER_ALL, ZO_HOUSING_FURNITURE_LIMIT_TYPE_FILTER_ALL)
    self:SetPlacementFurnitureTheme(FURNITURE_THEME_TYPE_ALL)
    self:SetPurchaseFurnitureTheme(FURNITURE_THEME_TYPE_ALL)
    self:SetRetrievableFurnitureFilters(HOUSING_FURNITURE_BOUND_FILTER_ALL, ZO_HOUSING_FURNITURE_LIMIT_TYPE_FILTER_ALL)
end

function ZO_SharedFurnitureManager:SetPlayerWaypointTo(housingObject)
    if housingObject:GetDataType() == ZO_RECALLABLE_HOUSING_DATA_TYPE then
        local furnitureId = housingObject:GetRetrievableFurnitureId()
        SetHousingEditorTrackedFurnitureId(furnitureId)
        local worldX, worldY, worldZ = HousingEditorGetFurnitureWorldPosition(furnitureId)
        if SetPlayerWaypointByWorldLocation(worldX, worldY, worldZ) then
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, GetString(SI_HOUSING_FURNIUTRE_SET_WAYPOINT_SUCCESS))
            self.waypointToFurnitureId = furnitureId
            self.waypointToPathIndex = nil
            self.ourWaypointAdd = true
        end
    elseif housingObject:GetDataType() == ZO_HOUSING_PATH_NODE_DATA_TYPE then
        local furnitureId = housingObject:GetFurnitureId()
        local pathIndex = housingObject:GetPathIndex()
        SetHousingEditorTrackedPathNode(furnitureId, pathIndex)
        local worldX, worldY, worldZ = HousingEditorGetPathNodeWorldPosition(furnitureId, pathIndex)
        if SetPlayerWaypointByWorldLocation(worldX, worldY, worldZ) then
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, GetString(SI_HOUSING_FURNIUTRE_SET_WAYPOINT_SUCCESS))
            self.waypointToFurnitureId = furnitureId
            self.waypointToPathIndex = pathIndex
            self.ourWaypointAdd = true
        end
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
                self.waypointToPathIndex = nil
                ResetHousingEditorTrackedFurnitureOrNode()
            end
        end
    end
end

function ZO_SharedFurnitureManager:OnHousingEditorModeChanged(oldMode, newMode)
    --If they picked up the furniture clear the player waypoint if it was showing the location of that furniture
    if self.waypointToFurnitureId then
        local selectedFurnitureId = HousingEditorGetSelectedFurnitureId()
        local selectedPathIndex = HousingEditorGetSelectedPathNodeIndex()

        local selectedInPlacement = newMode == HOUSING_EDITOR_MODE_PLACEMENT and AreId64sEqual(selectedFurnitureId, self.waypointToFurnitureId) and self.waypointToPathIndex == nil
        local selectedInNodePlacement = newMode == HOUSING_EDITOR_MODE_NODE_PLACEMENT and selectedPathIndex == self.waypointToPathIndex and AreId64sEqual(selectedFurnitureId, self.waypointToFurnitureId)
        if selectedInPlacement or selectedInNodePlacement then
            RemovePlayerWaypoint()
            ResetHousingEditorTrackedFurnitureOrNode()
        end
    end
end

function ZO_SharedFurnitureManager:OnHouseChanged()
    self:ResetFurnitureFilters()
end

function ZO_SharedFurnitureManager:CreatePlacedFurnitureData(furnitureId)
    return ZO_RetrievableFurniture:New(furnitureId)
end

function ZO_SharedFurnitureManager:RebuildFurnitureCaches()
    --setup just the placeable collections, SharedInventory will tell us when its ready to query placeable items
    self:MarkCollectibleCacheDirty()
    self:BuildMarketProductCache()

    ZO_ClearTable(self.retrievableFurniture)

    for furnitureId in GetNextPlacedFurnitureIdIter do
        self.retrievableFurniture[zo_getSafeId64Key(furnitureId)] = self:CreatePlacedFurnitureData(furnitureId)
    end

    ZO_ClearTable(self.pathNodesPerFurniture)

    for furnitureId in GetNextPathedFurnitureIdIter do
        local numNodes = HousingEditorGetNumPathNodesForFurniture(furnitureId)
        self.pathNodesPerFurniture[zo_getSafeId64Key(furnitureId)] = numNodes
    end

    self.refreshGroups:RefreshAll("UpdateRetrievableFurniture")
end

function ZO_SharedFurnitureManager:OnFurniturePlacedInHouse(furnitureId, collectibleId)
    if collectibleId ~= 0 then
        local cache = self:GetPlaceableFurnitureCache(ZO_PLACEABLE_TYPE_COLLECTIBLE)
        local furnitureCollectible = cache[collectibleId]
        if self:CanAddFurnitureDataToRefresh(self.placeableFurnitureCategoryTreeData, furnitureCollectible) then
            self.refreshGroups:RefreshSingle("UpdatePlacementFurniture", { target=furnitureCollectible, command=FURNITURE_COMMAND_REMOVE })
        end
        cache[collectibleId] = nil
        --No need to run the text filter since this is just a remove. We can notify others immediately.
        self:FireCallbacks("PlaceableFurnitureChanged")
    end

    --if an item just add to the recall list, SharedInventory will propagate the placeable list changes
    local furnitureIdKey = zo_getSafeId64Key(furnitureId)
    self.retrievableFurniture[furnitureIdKey] = self:CreatePlacedFurnitureData(furnitureId)
    self.refreshGroups:RefreshAll("UpdateRetrievableFurniture")
    self:FireCallbacks("RetrievableFurnitureChanged")
end

function ZO_SharedFurnitureManager:OnFurnitureRemovedFromHouse(furnitureId, collectibleId)
    local furnitureIdKey = zo_getSafeId64Key(furnitureId)
    if collectibleId ~= 0 then
        self:GetPlaceableFurnitureCache(ZO_PLACEABLE_TYPE_COLLECTIBLE)[collectibleId] = ZO_PlaceableFurnitureCollectible:New(collectibleId)
        self.refreshGroups:RefreshAll("UpdatePlacementFurniture")
        self:FireCallbacks("PlaceableFurnitureChanged")

        --If we removed a house bank, tell the player that they need to re-place it to get those items
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
        if collectibleData and collectibleData:GetCategoryType() == COLLECTIBLE_CATEGORY_TYPE_HOUSE_BANK then
            local NO_SOUND = nil
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, NO_SOUND, zo_strformat(SI_HOUSING_FURNITURE_PUT_AWAY_HOUSE_BANK_WARNING, collectibleData:GetName()))
        end
    end

    --if an item just remove, the inventory update will handle the placeable list changes
    self.refreshGroups:RefreshSingle("UpdateRetrievableFurniture", { target = self.retrievableFurniture[furnitureIdKey], command = FURNITURE_COMMAND_REMOVE })
    self.retrievableFurniture[furnitureIdKey] = nil
    self.refreshGroups:RefreshSingle("UpdateRetrievableFurniture", { target = furnitureId, command = FURNITURE_COMMAND_REMOVE_PATH })
    self.pathNodesPerFurniture[furnitureIdKey] = nil
    --No need to run the text filter since this is just a remove. We can notify others immediately.
    self:FireCallbacks("RetrievableFurnitureChanged")

    --If we removed this furniture and it had a waypoint then remove the waypoint
    if self.waypointToFurnitureId then
        if AreId64sEqual(furnitureId, self.waypointToFurnitureId) then
            RemovePlayerWaypoint()
            ResetHousingEditorTrackedFurnitureOrNode()
        end
    end
end

function ZO_SharedFurnitureManager:OnPathNodeAddedToFurniture(furnitureId, pathIndex)
    local furnitureIdKey = zo_getSafeId64Key(furnitureId)
    local numNodes = HousingEditorGetNumPathNodesForFurniture(furnitureId)
    self.pathNodesPerFurniture[furnitureIdKey] = numNodes

    self.refreshGroups:RefreshSingle("UpdateRetrievableFurniture", { pathIndex = pathIndex, target = furnitureId, command = FURNITURE_COMMAND_ADD_PATH_NODE })
    self:FireCallbacks("RetrievableFurnitureChanged")
end

function ZO_SharedFurnitureManager:OnPathNodeRemovedFromFurniture(furnitureId, pathIndex)
    local furnitureIdKey = zo_getSafeId64Key(furnitureId)
    local numNodes = HousingEditorGetNumPathNodesForFurniture(furnitureId)
    if numNodes == 0 then
        self.pathNodesPerFurniture[furnitureIdKey] = nil
    else
        self.pathNodesPerFurniture[furnitureIdKey] = numNodes
    end

    --If we removed this path node and it had a waypoint then remove the waypoint
    if self.waypointToFurnitureId and self.waypointToPathIndex then
        if AreId64sEqual(furnitureId, self.waypointToFurnitureId) and self.waypointToPathIndex == pathIndex then
            RemovePlayerWaypoint()
            ResetHousingEditorTrackedFurnitureOrNode()
        end
    end

    self.refreshGroups:RefreshSingle("UpdateRetrievableFurniture", { pathIndex = pathIndex, target = furnitureId, command = FURNITURE_COMMAND_REMOVE_PATH_NODE })
    self:FireCallbacks("RetrievableFurnitureChanged")
end

function ZO_SharedFurnitureManager:OnPathNodesRestoredToFurniture(furnitureId)
    local furnitureIdKey = zo_getSafeId64Key(furnitureId)
    local numNodes = HousingEditorGetNumPathNodesForFurniture(furnitureId)
    self.pathNodesPerFurniture[furnitureIdKey] = numNodes

    self.refreshGroups:RefreshSingle("UpdateRetrievableFurniture", { pathIndex = -1, target = furnitureId, command = FURNITURE_COMMAND_ADD_PATH_NODE })
    self:FireCallbacks("RetrievableFurnitureChanged")
end

function ZO_SharedFurnitureManager:OnPathStartingNodeIndexChanged(furnitureId)
    self.refreshGroups:RefreshAll("UpdateRetrievableFurniture")
    self:FireCallbacks("RetrievableFurnitureChanged")
end

function ZO_SharedFurnitureManager:OnFullInventoryUpdate(bagId)
    if ZO_PLACEABLE_FURNITURE_BAGS[bagId] then
        self:CreateOrUpdateItemCache(bagId)
    end
end

function ZO_SharedFurnitureManager:OnSingleSlotInventoryUpdate(bagId, slotIndex, previousSlotData)
    if GetCurrentZoneHouseId() ~= 0 and ZO_PLACEABLE_FURNITURE_BAGS[bagId] then
        local slotData = SHARED_INVENTORY:GenerateSingleSlotData(bagId, slotIndex)
        if slotData and slotData.isPlaceableFurniture then
            self:CreateOrUpdateItemDataEntry(bagId, slotIndex)
            self.refreshGroups:RefreshAll("UpdatePlacementFurniture")
            self:FireCallbacks("PlaceableFurnitureChanged")
        elseif not slotData and previousSlotData and previousSlotData.isPlaceableFurniture then
            --the item was deleted
            local bag = self.placeableFurniture[ZO_PLACEABLE_TYPE_ITEM][bagId]
            if bag then
                local itemToRemove = bag[slotIndex]
                if itemToRemove then
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
end

function ZO_SharedFurnitureManager:OnCollectionUpdated(collectionUpdateType, collectiblesByNewUnlockState)
    if collectionUpdateType == ZO_COLLECTION_UPDATE_TYPE.REBUILD then
        self:MarkCollectibleCacheDirty()
    else
        self:CleanCollectibleCache()
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
            self:FireCallbacks("PlaceableFurnitureChanged")
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

    -- Returns the current furniture filter values associated with the specified category tree data reference.
    function ZO_SharedFurnitureManager:GetFurnitureFiltersForCategoryTree(categoryTreeData)
        local boundFilters = HOUSING_FURNITURE_BOUND_FILTER_ALL
        local locationFilters = HOUSING_FURNITURE_LOCATION_FILTER_ALL
        local limitFilters = ZO_HOUSING_FURNITURE_LIMIT_TYPE_FILTER_ALL

        if categoryTreeData == self.placeableFurnitureCategoryTreeData then
            boundFilters = self.placementFurnitureBoundFilters or boundFilters
            locationFilters = self.placementFurnitureLocationFilters or locationFilters
            limitFilters = self.placementFurnitureLimitFilters or limitFilters
        elseif categoryTreeData == self.retrievableFurnitureCategoryTreeData then
            boundFilters = self.retrievableFurnitureBoundFilters or boundFilters
            limitFilters = self.retrievableFurnitureLimitFilters or limitFilters
        end

        return boundFilters, locationFilters, limitFilters
    end

    function ZO_SharedFurnitureManager:BuildCategoryTreeData(categoryTreeData, data, theme, filterFunction)
        local furnitureTheme = theme or FURNITURE_THEME_TYPE_ALL
        local boundFilters, locationFilters, limitFilters = self:GetFurnitureFiltersForCategoryTree(categoryTreeData)

        for _, furniture in pairs(data) do
            local passesOptionalFilter = true
            if filterFunction then
                passesOptionalFilter = filterFunction(furniture)
            end
            if passesOptionalFilter and furniture:GetPassesTextFilter() and furniture:PassesTheme(furnitureTheme) and furniture:GetPassesFurnitureFilters(boundFilters, locationFilters, limitFilters) then
                AddEntryToCategory(categoryTreeData, furniture)
            end
        end
    end

    function ZO_SharedFurnitureManager:AddFurnitureToCategory(categoryTreeData, furniture)
        AddEntryToCategory(categoryTreeData, furniture)
    end

    function ZO_SharedFurnitureManager:RemoveFurnitureFromCategory(categoryTreeData, furniture)
        if not furniture then
            return
        end

        local isPathableFurnitureCategory = categoryTreeData == self.pathableFurnitureCategoryTreeData
        if isPathableFurnitureCategory and not furniture:IsPathable() then
            -- Non-pathable furniture could not have been added to the pathable category.
            return
        end

        local categoryId, subcategoryId = furniture:GetCategoryInfo()
        if categoryId and categoryId > 0 then
            local categoryData = categoryTreeData:GetSubcategory(categoryId)
            local couldntFindExpectedCategory = false
            if categoryData then
                if subcategoryId and subcategoryId > 0 then
                    local subcategoryData = categoryData:GetSubcategory(subcategoryId)
                    if subcategoryData then
                        subcategoryData:RemoveEntry(furniture)
                    else
                        couldntFindExpectedCategory = true
                    end
                else
                    categoryData:RemoveEntry(furniture)
                end
            else
                couldntFindExpectedCategory = true
            end

            if couldntFindExpectedCategory then
                -- some trees will have specific subsets of furniture and we expect them to not have furniture in them at times
                if not isPathableFurnitureCategory then
                    local isFiltered = (categoryTreeData == self.placeableFurnitureCategoryTreeData and self.isPlaceableFiltered)
                                or (categoryTreeData == self.retrievableFurnitureCategoryTreeData and self.isRetrievableFiltered)
                                or (categoryTreeData == self.marketProductCategoryTreeData and self.isMarketFiltered)
                    -- Only assert if the category or subcategory genuinely does not exist or if there is no filter currently being applied to the relevant category tree.
                    if not isFiltered or not GetFurnitureCategoryInfo(categoryId) or not GetFurnitureCategoryInfo(subcategoryId) then
                        internalassert(false, string.format("Removing non-existent furniture from %s.", categoryTreeData:GetRootCategoryName()))
                    end
                end
            end
        else
            local categoryData = categoryTreeData:GetSubcategory(ZO_FURNITURE_NEEDS_CATEGORIZATION_FAKE_CATEGORY)
            if internalassert(categoryData ~= nil, string.format("Uncategorized furniture has no 'needs categorization' category. Furniture is likely missing furniture data. Furniture name: %s", furniture:GetRawName())) then
                categoryData:RemoveEntry(furniture)
            end
        end
    end

    function ZO_SharedFurnitureManager:RemovePathNodeFromCategory(categoryTreeData, furnitureId, pathIndex)
        local pathNodesCategory = categoryTreeData:GetSubcategory(ZO_FURNITURE_PATH_NODES_FAKE_CATEGORY)
        if not pathNodesCategory then
            return
        end

        local furnitureIdKey = zo_getSafeId64Key(furnitureId)
        local furniturePathCategory = pathNodesCategory:GetSubcategory(furnitureIdKey)
        if not furniturePathCategory then
            return
        end

        local numNodes = self.pathNodesPerFurniture[furnitureIdKey]

        if numNodes == 0 or numNodes == nil then
            furniturePathCategory:Clear()
            pathNodesCategory:RemoveSubcategory(furniturePathCategory:GetCategoryId())
        else
            local currentNumNodes = furniturePathCategory:GetNumEntryItemsRecursive()
            if currentNumNodes ~= numNodes then
                -- if we remove from the middle we would have to update a lot of datas, so just refresh all
                furniturePathCategory:Clear()
                for i = 1, numNodes do
                    local newPathData = ZO_FurniturePathNode:New(furnitureId, i)
                    furniturePathCategory:AddEntry(newPathData)
                end
            end
        end
    end

    function ZO_SharedFurnitureManager:RemovePathFromCategory(categoryTreeData, furnitureId)
        local pathNodesCategory = categoryTreeData:GetSubcategory(ZO_FURNITURE_PATH_NODES_FAKE_CATEGORY)
        if not pathNodesCategory then
            return
        end

        local furnitureIdKey = zo_getSafeId64Key(furnitureId)
        local furniturePathCategory = pathNodesCategory:GetSubcategory(furnitureIdKey)
        if not furniturePathCategory then
            return
        end

        furniturePathCategory:Clear()
        pathNodesCategory:RemoveSubcategory(furniturePathCategory:GetCategoryId())
    end

    function ZO_SharedFurnitureManager:AddPathNodeToCategory(categoryTreeData, furnitureId, pathIndex)
        local furnitureIdKey = zo_getSafeId64Key(furnitureId)
        local numNodes = self.pathNodesPerFurniture[furnitureIdKey]
        if numNodes == nil or numNodes == 0 then
            return -- we probably removed the nodes we wanted to add, nothing to do here
        end

        local addedCategory = false
        local pathNodesCategory = categoryTreeData:GetSubcategory(ZO_FURNITURE_PATH_NODES_FAKE_CATEGORY)
        if not pathNodesCategory then
            pathNodesCategory = ZO_FurnitureCategory:New(categoryTreeData, ZO_FURNITURE_PATH_NODES_FAKE_CATEGORY)
            categoryTreeData:AddSubcategory(ZO_FURNITURE_PATH_NODES_FAKE_CATEGORY, pathNodesCategory)
            addedCategory = true
        end

        local furniturePathCategory = pathNodesCategory:GetSubcategory(furnitureIdKey)
        if not furniturePathCategory then
            furniturePathCategory = ZO_PathNodeFurnitureCategory:New(pathNodesCategory, furnitureIdKey)
            pathNodesCategory:AddSubcategory(furnitureIdKey, furniturePathCategory)
            addedCategory = true
        end

        if addedCategory then
            categoryTreeData:SortCategoriesRecursive()
        end

        -- if we insert in the middle we would have to update a lot of datas, so just refresh all
        local currentNumNodes = furniturePathCategory:GetNumEntryItemsRecursive()
        if currentNumNodes ~= numNodes then
            furniturePathCategory:Clear()
            for i = 1, numNodes do
                local newPathData = ZO_FurniturePathNode:New(furnitureId, i)
                furniturePathCategory:AddEntry(newPathData)
            end
        end
    end
end

function ZO_SharedFurnitureManager:GetPlaceableFurnitureCache(type)
    if type == ZO_PLACEABLE_TYPE_COLLECTIBLE then
        self:CleanCollectibleCache()
    end
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

function ZO_SharedFurnitureManager:GetPathableFurnitureCategoryTreeData()
    self.refreshGroups:UpdateRefreshGroups()
    return self.pathableFurnitureCategoryTreeData
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
        self:FireCallbacks("PlaceableFurnitureChanged")
    end
end

function ZO_SharedFurnitureManager:MarkCollectibleCacheDirty()
    self.placeableCollectibleCacheDirty = true
end

function ZO_SharedFurnitureManager:CleanCollectibleCache()
    if self.placeableCollectibleCacheDirty then
        self.placeableCollectibleCacheDirty = false
        self:CreateOrUpdateCollectibleCache()
    end
end

function ZO_SharedFurnitureManager:CreateOrUpdateCollectibleCache()
    local collectibleCache = self:GetPlaceableFurnitureCache(ZO_PLACEABLE_TYPE_COLLECTIBLE)
    ZO_ClearTable(collectibleCache)

    local SORTED = true
    local filteredDataTable = ZO_COLLECTIBLE_DATA_MANAGER:GetAllCollectibleDataObjects({ ZO_CollectibleCategoryData.IsStandardCategory }, { ZO_CollectibleData.IsPlaceableFurniture, ZO_CollectibleData.IsUnlocked }, SORTED)
    for _, collectibleData in pairs(filteredDataTable) do
        self:CreateOrUpdateCollectibleDataEntry(collectibleData:GetId())
    end
    -- CreateOrUpdateCollectibleCache could be called from the RefreshAll for "UpdatePlacementFurniture"
    -- so if we are in the middle of a RefreshAll, don't attempt to refresh again, it can cause data duplication
    if self.refreshingPlacementFurniture ~= true then
        self.refreshGroups:RefreshAll("UpdatePlacementFurniture")
        self:FireCallbacks("PlaceableFurnitureChanged")
    end
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
    self:FireCallbacks("MarketProductsChanged")
end

function ZO_SharedFurnitureManager:UpdateMarketProductCache()
    for index, marketHousingProduct in ipairs(self.marketProducts) do
        marketHousingProduct:RefreshInfo(marketHousingProduct.marketProductId, marketHousingProduct.presentationIndex)
    end

    self.refreshGroups:RefreshAll("UpdateMarketProducts")
    self:FireCallbacks("MarketProductsChanged")
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
    local cache = self:GetPlaceableFurnitureCache(ZO_PLACEABLE_TYPE_COLLECTIBLE)
    local existingCollectible = cache[collectibleId]
    if HousingEditorCanPlaceCollectible(collectibleId) then
        if existingCollectible then
            existingCollectible:RefreshInfo(collectibleId)
        else
            local newCollectible = ZO_PlaceableFurnitureCollectible:New(collectibleId)
            cache[collectibleId] = newCollectible
        end
        return true
    end

    if existingCollectible then
        if self:CanAddFurnitureDataToRefresh(self.placeableFurnitureCategoryTreeData, existingCollectible) then
            self.refreshGroups:RefreshSingle("UpdatePlacementFurniture", { target = existingCollectible, command = FURNITURE_COMMAND_REMOVE })
        end
        cache[collectibleId] = nil
        --No need to run the text filter since this is just a remove. We can notify others immediately.
        self:FireCallbacks("PlaceableFurnitureChanged")
    end
    return false
end

function ZO_SharedFurnitureManager:CreateMarketProductEntry(marketProductId, presentationIndex)
    local marketHousingProduct = self.housingMarketProductPool:AcquireObject()
    marketHousingProduct:RefreshInfo(marketProductId, presentationIndex)
    table.insert(self.marketProducts, marketHousingProduct)
    self.marketProductIdToMarketProduct[marketProductId] = marketHousingProduct
end

function ZO_SharedFurnitureManager:DoesPlayerHavePlaceableFurniture()
    return next(self:GetPlaceableFurnitureCache(ZO_PLACEABLE_TYPE_COLLECTIBLE)) ~= nil
        or next(self:GetPlaceableFurnitureCache(ZO_PLACEABLE_TYPE_ITEM)) ~= nil
end

function ZO_SharedFurnitureManager:DoesPlayerHavePathableFurniture()
    return next(self:GetPlaceableFurnitureCache(ZO_PLACEABLE_TYPE_COLLECTIBLE)) ~= nil
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

            --If this is the first update in the zone, we've moved far enough from our last position or if a
            --furnishing has been moved then update the retrievable furniture's position information relative to the player.
            local updateDistances = false
            if self.forcePositionalDataUpdate then
                updateDistances = true
                self.forcePositionalDataUpdate = false
            else
                if self.lastPlayerWorldX == nil then
                    updateDistances = true
                else
                    local distanceChange = zo_abs(playerWorldX - self.lastPlayerWorldX) + zo_abs(playerWorldY - self.lastPlayerWorldY) + zo_abs(playerWorldZ - self.lastPlayerWorldZ)
                    if distanceChange > DISTANCE_CHANGE_BEFORE_UPDATE then
                        updateDistances = true
                    end
                end
            end

            -- If distances require an update, capture the latest position of the player.
            if updateDistances then
                self.lastPlayerWorldX = playerWorldX
                self.lastPlayerWorldY = playerWorldY
                self.lastPlayerWorldZ = playerWorldZ
            end

            --If this is the first update or we are updating the distances (which also influences heading) or we have turned the camera far enough from
            --our last heading then update the retrievable furniture direction to the player
            local updateHeading = false
            if self.lastPlayerHeading == nil or updateDistances then
                updateHeading = true
            elseif zo_abs(self.lastPlayerHeading - playerCameraHeading) > HEADING_CHANGE_BEFORE_UPDATE_RADIANS then
                updateHeading = true
            end

            -- If the camera heading has changed significantly, capture the latest heading.
            if updateHeading then
                self.lastPlayerHeading = playerCameraHeading
            end

            --In both cases we update all the position data. This could be changed to only touch the heading for the heading case but
            --it saves very little.
            if updateDistances or updateHeading then
                for furnitureIdKey, retrievableFurniture in pairs(self.retrievableFurniture) do
                    retrievableFurniture:RefreshPositionalData(playerWorldX, playerWorldY, playerWorldZ, playerCameraHeading)
                end

                local pathNodesCategory = self.retrievableFurnitureCategoryTreeData:GetSubcategory(ZO_FURNITURE_PATH_NODES_FAKE_CATEGORY)
                if pathNodesCategory then
                    local allSubcategories = pathNodesCategory:GetAllSubcategories()
                    for _, subCategory in ipairs(allSubcategories) do
                        local allEntries = subCategory:GetAllEntries()
                        for i, entry in ipairs(allEntries) do
                            entry:RefreshPositionalData(playerWorldX, playerWorldY, playerWorldZ, playerCameraHeading)
                        end
                    end
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

function ZO_SharedFurnitureManager:RefreshPlacementFilterState()
    self.isPlaceableFiltered =
        self:GetPlacementFurnitureBoundFilters() > HOUSING_FURNITURE_BOUND_FILTER_ALL
     or self:GetPlacementFurnitureLocationFilters() > HOUSING_FURNITURE_LOCATION_FILTER_ALL
     or self:GetPlacementFurnitureLimitFilters() > ZO_HOUSING_FURNITURE_LIMIT_TYPE_FILTER_ALL
     or self:GetPlacementFurnitureTheme() ~= FURNITURE_THEME_TYPE_ALL
     or TEXT_SEARCH_MANAGER:HasSearchFilter("housePlaceableItemsTextSearch")
end

function ZO_SharedFurnitureManager:RefreshMarketFilterState()
    self.isMarketFiltered =
        self:GetPurchaseFurnitureTheme() ~= FURNITURE_THEME_TYPE_ALL
     or TEXT_SEARCH_MANAGER:HasSearchFilter("houseProductsTextSearch")
end

function ZO_SharedFurnitureManager:RefreshRetrievableFilterState()
    self.isRetrievableFiltered =
        self:GetRetrievableFurnitureBoundFilters() > HOUSING_FURNITURE_BOUND_FILTER_ALL
     or self:GetRetrievableFurnitureLimitFilters() > ZO_HOUSING_FURNITURE_LIMIT_TYPE_FILTER_ALL
     or TEXT_SEARCH_MANAGER:HasSearchFilter("houseFurnitureTextSearch")
end

function ZO_SharedFurnitureManager:GetPlacementFurnitureBoundFilters()
    return self.placementFurnitureBoundFilters or HOUSING_FURNITURE_BOUND_FILTER_ALL
end

function ZO_SharedFurnitureManager:GetPlacementFurnitureLocationFilters()
    return self.placementFurnitureLocationFilters or HOUSING_FURNITURE_LOCATION_FILTER_ALL
end

function ZO_SharedFurnitureManager:GetPlacementFurnitureLimitFilters()
    return self.placementFurnitureLimitFilters or ZO_HOUSING_FURNITURE_LIMIT_TYPE_FILTER_ALL
end

function ZO_SharedFurnitureManager:GetPlacementFurnitureTheme()
    return self.placementFurnitureTheme or FURNITURE_THEME_TYPE_ALL
end

function ZO_SharedFurnitureManager:OnPlacementFiltersChanged()
    self:RefreshPlacementFilterState()
    self.refreshGroups:RefreshAll("UpdatePlacementFurniture")
    self:FireCallbacks("PlaceableFurnitureChanged")
end

function ZO_SharedFurnitureManager:SetPlacementFurnitureFilters(boundFilters, locationFilters, limitFilters)
    local changed = false

    if boundFilters ~= nil and self.placementFurnitureBoundFilters ~= boundFilters then
        self.placementFurnitureBoundFilters = boundFilters
        changed = true
    end

    if locationFilters ~= nil and self.placementFurnitureLocationFilters ~= locationFilters then
        self.placementFurnitureLocationFilters = locationFilters
        changed = true
    end

    if limitFilters ~= nil and self.placementFurnitureLimitFilters ~= limitFilters then
        self.placementFurnitureLimitFilters = limitFilters
        changed = true
    end

    if changed then
        self:OnPlacementFiltersChanged()
    end
end

function ZO_SharedFurnitureManager:SetPlacementFurnitureTheme(theme)
    if self.placementFurnitureTheme ~= theme then
        self.placementFurnitureTheme = theme
        self:OnPlacementFiltersChanged()
    end
end

function ZO_SharedFurnitureManager:GetPurchaseFurnitureTheme()
    return self.purchaseFurnitureTheme or FURNITURE_THEME_TYPE_ALL
end

function ZO_SharedFurnitureManager:OnPurchaseFiltersChanged()
    self:RefreshMarketFilterState()
    self.refreshGroups:RefreshAll("UpdateMarketProducts")
    self:FireCallbacks("MarketProductsChanged")
end

function ZO_SharedFurnitureManager:SetPurchaseFurnitureTheme(theme)
    if self.purchaseFurnitureTheme ~= theme then
        self.purchaseFurnitureTheme = theme
        self:OnPurchaseFiltersChanged()
    end
end

function ZO_SharedFurnitureManager:GetRetrievableFurnitureBoundFilters()
    return self.retrievableFurnitureBoundFilters or HOUSING_FURNITURE_BOUND_FILTER_ALL
end

function ZO_SharedFurnitureManager:GetRetrievableFurnitureLimitFilters()
    return self.retrievableFurnitureLimitFilters or ZO_HOUSING_FURNITURE_LIMIT_TYPE_FILTER_ALL
end

function ZO_SharedFurnitureManager:OnRetrievableFiltersChanged()
    self:RefreshRetrievableFilterState()
    self.refreshGroups:RefreshAll("UpdateRetrievableFurniture")
    self:FireCallbacks("RetrievableFurnitureChanged")
end

function ZO_SharedFurnitureManager:SetRetrievableFurnitureFilters(boundFilters, limitFilters)
    local changed = false

    if boundFilters ~= nil and self.retrievableFurnitureBoundFilters ~= boundFilters then
        self.retrievableFurnitureBoundFilters = boundFilters
        changed = true
    end

    if limitFilters ~= nil and self.retrievableFurnitureLimitFilters ~= limitFilters then
        self.retrievableFurnitureLimitFilters = limitFilters
        changed = true
    end

    if changed then
        self:OnRetrievableFiltersChanged()
    end
end

function ZO_SharedFurnitureManager:CanAddFurnitureDataToRefresh(categoryTree, furnitureData)
    if not furnitureData then
        return
    end

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

function ZO_SharedFurnitureManager:CanResetFurnitureFilters()
    if TEXT_SEARCH_MANAGER:HasSearchFilter("housePlaceableItemsTextSearch")
        or TEXT_SEARCH_MANAGER:HasSearchFilter("houseProductsTextSearch")
        or TEXT_SEARCH_MANAGER:HasSearchFilter("houseFurnitureTextSearch") then
        return true
    end

    if self:GetPlacementFurnitureBoundFilters() ~= HOUSING_FURNITURE_BOUND_FILTER_ALL then
        return true
    end
    
    if self:GetPlacementFurnitureLocationFilters() ~= HOUSING_FURNITURE_LOCATION_FILTER_ALL then
        return true
    end

    if self:GetPlacementFurnitureLimitFilters() ~= ZO_HOUSING_FURNITURE_LIMIT_TYPE_FILTER_ALL then
        return true
    end

    if self:GetRetrievableFurnitureBoundFilters() ~= HOUSING_FURNITURE_BOUND_FILTER_ALL then
        return true
    end

    if self:GetRetrievableFurnitureLimitFilters() ~= ZO_HOUSING_FURNITURE_LIMIT_TYPE_FILTER_ALL then
        return true
    end

    return false
end

function ZO_SharedFurnitureManager:AppendPathNodes(rootCategory)
    if next(self.pathNodesPerFurniture) == nil then
        return
    end

    local pathNodes = ZO_FurnitureCategory:New(rootCategory, ZO_FURNITURE_PATH_NODES_FAKE_CATEGORY)
    rootCategory:AddSubcategory(ZO_FURNITURE_PATH_NODES_FAKE_CATEGORY, pathNodes)
    
    for furnitureIdKey, numNodes in pairs(self.pathNodesPerFurniture) do
        local furnitureId = StringToId64(furnitureIdKey)
        local categoryFurnitureData = ZO_PathNodeFurnitureCategory:New(pathNodes, furnitureIdKey)
        pathNodes:AddSubcategory(furnitureIdKey, categoryFurnitureData)

        for i = 1, numNodes do
            local newPathData = ZO_FurniturePathNode:New(furnitureId, i)
            categoryFurnitureData:AddEntry(newPathData)
        end
    end
end

function ZO_SharedFurnitureManager:HasAnyPathNodes()
    local pathNodesCategory = self.retrievableFurnitureCategoryTreeData:GetSubcategory(ZO_FURNITURE_PATH_NODES_FAKE_CATEGORY)
    if not pathNodesCategory then
        return false
    end

    return #pathNodesCategory:GetAllSubcategories() > 0
end

SHARED_FURNITURE = ZO_SharedFurnitureManager:New()