ZO_ItemSetCollectionsDataManager = ZO_CallbackObject:Subclass()

function ZO_ItemSetCollectionsDataManager:New(...)
    ITEM_SET_COLLECTIONS_DATA_MANAGER = ZO_CallbackObject.New(self)
    ITEM_SET_COLLECTIONS_DATA_MANAGER:Initialize(...)
    return ITEM_SET_COLLECTIONS_DATA_MANAGER
end

function ZO_ItemSetCollectionsDataManager:Initialize()
    self.itemSetCollections = {}
    self.itemSetPieces = {}
    self.itemSetCollectionCategories = {}
    self.topLevelCategories = {}

    self.reconstructionCurrencyOptionTypes = {}
    for currencyOptionIndex = 1, GetNumItemReconstructionCurrencyOptions() do
        table.insert(self.reconstructionCurrencyOptionTypes, GetItemReconstructionCurrencyOptionType(currencyOptionIndex))
    end

    self.searchString = ""
    self.searchResultsVersion = 0

    self.queuedSlotsJustUnlocked = {}

    self:RegisterForEvents()
    self:RebuildData()
end

function ZO_ItemSetCollectionsDataManager:RegisterForEvents()
    EVENT_MANAGER:RegisterForEvent("ZO_ItemSetCollectionsDataManager", EVENT_ITEM_SET_COLLECTIONS_UPDATED, function(_, ...) self:OnCollectionsUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_ItemSetCollectionsDataManager", EVENT_ITEM_SET_COLLECTION_UPDATED, function(_, ...) self:OnCollectionUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_ItemSetCollectionsDataManager", EVENT_ITEM_SET_COLLECTIONS_SEARCH_RESULTS_READY, function() self:UpdateSearchResults() end)
    EVENT_MANAGER:RegisterForEvent("ZO_ItemSetCollectionsDataManager", EVENT_ITEM_SET_COLLECTION_SLOT_NEW_STATUS_CLEARED, function(_, ...) self:OnCollectionSlotNewStatusCleared(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_ItemSetCollectionsDataManager", EVENT_LEVEL_UPDATE, function(_, ...) self:OnLevelUpdate(...) end)
    EVENT_MANAGER:AddFilterForEvent("ZO_ItemSetCollectionsDataManager", EVENT_LEVEL_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")
    EVENT_MANAGER:RegisterForEvent("ZO_ItemSetCollectionsDataManager", EVENT_CHAMPION_POINT_UPDATE, function(_, ...) self:OnChampionPointUpdate(...) end)
    EVENT_MANAGER:AddFilterForEvent("ZO_ItemSetCollectionsDataManager", EVENT_CHAMPION_POINT_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")

    local function OnAddOnLoaded(_, name)
        if name == "ZO_Ingame" then
            local DEFAULTS = { showLocked = true, equipmentFiltersTypes = {} }
            self.savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 1, "ZO_ItemSetCollectionsDataManager", DEFAULTS)
            EVENT_MANAGER:UnregisterForEvent("ZO_ItemSetCollectionsDataManager", EVENT_ADD_ON_LOADED)
            self:FireCallbacks("ShowLockedChanged", self.savedVars.showLocked)
            self:FireCallbacks("EquipmentFilterTypesChanged", self:GetEquipmentFilterTypes())
        end
    end
    EVENT_MANAGER:RegisterForEvent("ZO_ItemSetCollectionsDataManager", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
    
end

function ZO_ItemSetCollectionsDataManager:MarkDataDirty()
    self.isDataDirty = true
end

function ZO_ItemSetCollectionsDataManager:CleanData()
    if self.isDataDirty then
        self:RebuildData()
    end
end

do
    local function GetNextItemSetCollectionIdIter(_, lastItemSetId)
        return GetNextItemSetCollectionId(lastItemSetId)
    end

    function ZO_ItemSetCollectionsDataManager:RebuildData()
        self.isDataDirty = false

        ZO_ClearTable(self.itemSetCollections)
        ZO_ClearTable(self.itemSetPieces)
        ZO_ClearTable(self.itemSetCollectionCategories)
        ZO_ClearNumericallyIndexedTable(self.topLevelCategories)

        -- Load all ItemSetCollections and their associated objects.
        for itemSetId in GetNextItemSetCollectionIdIter do
            self:InternalGetOrCreateItemSetCollectionData(itemSetId)
        end

        self:SortTopLevelCategories()
        self:OnCollectionsUpdated()
    end
end

function ZO_ItemSetCollectionsDataManager:OnUpdateSlotsJustUnlocked()
    if #self.queuedSlotsJustUnlocked > 0 then
        self:FireCallbacks("SlotsJustUnlocked", self.queuedSlotsJustUnlocked)
        self:OnCollectionsUpdated()
        ZO_ClearNumericallyIndexedTable(self.queuedSlotsJustUnlocked)
    end

    EVENT_MANAGER:UnregisterForUpdate("ZO_ItemSetCollectionsDataManager_SlotsJustUnlocked")
end

function ZO_ItemSetCollectionsDataManager:GetReconstructionCurrencyOptionType(currencyOptionIndex)
    return self.reconstructionCurrencyOptionTypes[currencyOptionIndex]
end

function ZO_ItemSetCollectionsDataManager:GetReconstructionCurrencyOptionTypes()
    return self.reconstructionCurrencyOptionTypes
end

function ZO_ItemSetCollectionsDataManager:InvalidateCacheData()
    for _, itemSetCollectionCategoryData in ipairs(self.topLevelCategories) do
        itemSetCollectionCategoryData:InvalidateCacheData()
    end
end

function ZO_ItemSetCollectionsDataManager:OnCollectionsUpdated(itemSetIds)
    self:InvalidateCacheData()
    self:FireCallbacks("CollectionsUpdated", itemSetIds)
end

function ZO_ItemSetCollectionsDataManager:OnCollectionUpdated(itemSetId, slotsJustUnlockedMask)
    local slotsJustUnlocked = { GetItemSetCollectionSlotsInMask(slotsJustUnlockedMask) }
    if #slotsJustUnlocked > 0 then
        for _, slotJustUnlocked in ipairs(slotsJustUnlocked) do
            table.insert(self.queuedSlotsJustUnlocked,
            {
                itemSetId = itemSetId,
                slot = slotJustUnlocked,
            })
        end

        EVENT_MANAGER:RegisterForUpdate("ZO_ItemSetCollectionsDataManager_SlotsJustUnlocked", 100, function() self:OnUpdateSlotsJustUnlocked() end)
    end

    self:OnCollectionsUpdated({ itemSetId })
end

function ZO_ItemSetCollectionsDataManager:OnLevelUpdate()
    self:MarkAllPieceLinksDirty()
end

do
    local MAX_ITEM_CHAMPION_POINTS = 160
    local ITEM_CHAMPION_RANK_INTERVAL = 10

    function ZO_ItemSetCollectionsDataManager:OnChampionPointUpdate(_, oldChampionPoints, currentChampionPoints)
        if oldChampionPoints < MAX_ITEM_CHAMPION_POINTS or currentChampionPoints < MAX_ITEM_CHAMPION_POINTS then
            if zo_floor(oldChampionPoints / ITEM_CHAMPION_RANK_INTERVAL) ~= zo_floor(currentChampionPoints / ITEM_CHAMPION_RANK_INTERVAL) then
                self:MarkAllPieceLinksDirty()
            end
        end
    end
end

function ZO_ItemSetCollectionsDataManager:MarkAllPieceLinksDirty()
    for _, itemSetCollectionPieceData in self:ItemSetCollectionPieceIterator() do
        itemSetCollectionPieceData:MarkItemLinkDirty()
    end
    self:FireCallbacks("PieceLinksDirty")
end

function ZO_ItemSetCollectionsDataManager:SortTopLevelCategories()
    table.sort(self.topLevelCategories, ZO_ItemSetCollectionCategoryData.CompareTo)
    for _, itemSetCollectionCategoryData in ipairs(self.topLevelCategories) do
        itemSetCollectionCategoryData:SortChildren()
    end
end

-- ZO_ItemSetCollectionPiece

function ZO_ItemSetCollectionsDataManager:ItemSetCollectionPieceIterator(filterFunctions)
    self:CleanData()
    return ZO_FilteredNonContiguousTableIterator(self.itemSetPieces, filterFunctions)
end

function ZO_ItemSetCollectionsDataManager:GetItemSetCollectionPieceData(pieceId)
    self:CleanData()
    return self.itemSetPieces[pieceId]
end

function ZO_ItemSetCollectionsDataManager:GetOrCreateItemSetCollectionPieceData(pieceId, itemSetCollectionSlot)
    if pieceId and pieceId ~= 0 then
        local itemSetCollectionPieceData = self:GetItemSetCollectionPieceData(pieceId)
        if not itemSetCollectionPieceData then
            itemSetCollectionPieceData = ZO_ItemSetCollectionPieceData:New(pieceId, itemSetCollectionSlot)
            self.itemSetPieces[pieceId] = itemSetCollectionPieceData
        end
        return itemSetCollectionPieceData
    end
end

-- ZO_ItemSetCollection

function ZO_ItemSetCollectionsDataManager:ItemSetCollectionIterator(filterFunctions)
    self:CleanData()
    return ZO_FilteredNonContiguousTableIterator(self.itemSetCollections, filterFunctions)
end

function ZO_ItemSetCollectionsDataManager:GetItemSetCollectionData(itemSetId)
    self:CleanData()
    return self.itemSetCollections[itemSetId]
end

function ZO_ItemSetCollectionsDataManager:InternalGetOrCreateItemSetCollectionData(itemSetId)
    if itemSetId and itemSetId ~= 0 then
        local itemSetCollectionData = self:GetItemSetCollectionData(itemSetId)
        if not itemSetCollectionData then
            itemSetCollectionData = ZO_ItemSetCollectionData:New(itemSetId)
            self.itemSetCollections[itemSetId] = itemSetCollectionData
        end
        return itemSetCollectionData
    end
end

-- ZO_ItemSetCollectionCategory

function ZO_ItemSetCollectionsDataManager:ItemSetCollectionCategoryIterator(filterFunctions)
    self:CleanData()
    return ZO_FilteredNonContiguousTableIterator(self.itemSetCollections, filterFunctions)
end

function ZO_ItemSetCollectionsDataManager:TopLevelItemSetCollectionCategoryIterator(filterFunctions)
    self:CleanData()
    return ZO_FilteredNumericallyIndexedTableIterator(self.topLevelCategories, filterFunctions)
end

function ZO_ItemSetCollectionsDataManager:GetItemSetCollectionCategoryData(categoryId)
    self:CleanData()
    return self.itemSetCollectionCategories[categoryId]
end

function ZO_ItemSetCollectionsDataManager:GetOrCreateItemSetCollectionCategoryData(categoryId)
    if categoryId and categoryId ~= 0 then
        local itemSetCollectionCategoryData = self:GetItemSetCollectionCategoryData(categoryId)
        if not itemSetCollectionCategoryData then
            itemSetCollectionCategoryData = ZO_ItemSetCollectionCategoryData:New(categoryId)
            self.itemSetCollectionCategories[categoryId] = itemSetCollectionCategoryData
            if not itemSetCollectionCategoryData:GetParentCategoryData() then
                table.insert(self.topLevelCategories, itemSetCollectionCategoryData)
            end
        end
        return itemSetCollectionCategoryData
    end
end

-- Search
function ZO_ItemSetCollectionsDataManager:SetSearchString(searchString)
    self.searchString = searchString or ""
    StartItemSetCollectionSearch(self.searchString)
end

function ZO_ItemSetCollectionsDataManager:UpdateSearchResults()
    self.searchResultsVersion = self.searchResultsVersion + 1

    for i = 1, GetNumItemSetCollectionSearchResults() do
        local itemSetId = GetItemSetCollectionSearchResult(i)
        local itemSetCollectionData = self:GetItemSetCollectionData(itemSetId)
        itemSetCollectionData:SetSearchResultsVersion(self.searchResultsVersion)
    end

    self:FireCallbacks("UpdateSearchResults")
end

function ZO_ItemSetCollectionsDataManager:OnCollectionSlotNewStatusCleared(itemSetId, itemSetCollectionSlot)
    local itemSetCollectionData = self:GetItemSetCollectionData(itemSetId)
    local itemSetCollectionPieceData = itemSetCollectionData:GetPieceDataBySlot(itemSetCollectionSlot)
    self:FireCallbacks("PieceNewStatusCleared", itemSetCollectionPieceData)
end

function ZO_ItemSetCollectionsDataManager:OnCollectionNewStatusCleared(itemSetCollectionData)
    self:FireCallbacks("CollectionNewStatusCleared", itemSetCollectionData)
end

function ZO_ItemSetCollectionsDataManager:OnCollectionCategoryNewStatusCleared(itemSetCollectionCategoryData)
    self:FireCallbacks("CategoryNewStatusCleared", itemSetCollectionCategoryData)
end

function ZO_ItemSetCollectionsDataManager:HasAnyNewPieces()
    return DoesItemSetCollectionsHaveAnyNewPieces()
end

function ZO_ItemSetCollectionsDataManager:GetSearchResultsVersion()
    return self.searchResultsVersion
end

function ZO_ItemSetCollectionsDataManager:HasSearchFilter()
    return zo_strlen(self.searchString) > 1
end

function ZO_ItemSetCollectionsDataManager:GetShowLocked()
    return self.savedVars.showLocked
end

function ZO_ItemSetCollectionsDataManager:SetShowLocked(showLocked)
    if self.savedVars.showLocked ~= showLocked then
        self.savedVars.showLocked = showLocked
        self:FireCallbacks("ShowLockedChanged", showLocked)
    end
end

function ZO_ItemSetCollectionsDataManager:GetEquipmentFilterTypes()
    if not self.savedVars.equipmentFilterTypes then
        self.savedVars.equipmentFilterTypes = {}
    end
    return self.savedVars.equipmentFilterTypes
end

function ZO_ItemSetCollectionsDataManager:SetEquipmentFilterTypes(equipmentFilterTypes)
    if not ZO_AreNumericallyIndexedTablesEqual(self:GetEquipmentFilterTypes(), equipmentFilterTypes) then
        self.savedVars.equipmentFilterTypes = equipmentFilterTypes
        self:FireCallbacks("EquipmentFilterTypesChanged", equipmentFilterTypes)
    end
end

do
    local APPAREL_FILTER_TYPES =
    {
        EQUIPMENT_FILTER_TYPE_LIGHT,
        EQUIPMENT_FILTER_TYPE_MEDIUM,
        EQUIPMENT_FILTER_TYPE_HEAVY,
        EQUIPMENT_FILTER_TYPE_NECK,
        EQUIPMENT_FILTER_TYPE_RING,
        EQUIPMENT_FILTER_TYPE_SHIELD,
    }

    function ZO_ItemSetCollectionsDataManager.GetApparelFilterTypes()
        return APPAREL_FILTER_TYPES
    end

    local WEAPON_FILTER_TYPES =
    {
        EQUIPMENT_FILTER_TYPE_ONE_HANDED,
        EQUIPMENT_FILTER_TYPE_TWO_HANDED,
        EQUIPMENT_FILTER_TYPE_DESTRO_STAFF,
        EQUIPMENT_FILTER_TYPE_RESTO_STAFF,
        EQUIPMENT_FILTER_TYPE_BOW,
    }

    function ZO_ItemSetCollectionsDataManager.GetWeaponFilterTypes()
        return WEAPON_FILTER_TYPES
    end
end

-- Global singleton

-- The global singleton moniker is assigned by the Data Manager's constructor in order to
-- allow data objects to reference the singleton during their construction.
ZO_ItemSetCollectionsDataManager:New()