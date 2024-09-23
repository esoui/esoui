ZO_ItemSetsBook_Shared = ZO_TextSearchObject:Subclass()

function ZO_ItemSetsBook_Shared:Initialize(control, scene)
    ZO_TextSearchObject.Initialize(self, "itemSetTextSearch", self.searchEditBox)

    self.control = control

    self.scene = scene or ZO_Scene:New(self:GetSceneName(), SCENE_MANAGER)
    self.fragment = ZO_FadeSceneFragment:New(control)
    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnFragmentShowing()
            if self:IsSearchSupported() then
                self:ActivateTextSearch()
            end
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            if self:IsSearchSupported() then
                self:DeactivateTextSearch()
            end
        end
    end)

    self.categoryFilters = {}
    self.setFilters = {}
    self.pieceFilters = {}

    -- Rather than having every piece sort for every player, we'll only sort the ones we look at, as an optimization since the system is so big
    self.tempUnlockedEntriesForRefresh = {}
    self.tempLockedEntriesForRefresh = {}

    self:InitializeControls()
    self:InitializeCategories()
    self:InitializeGridList()

    self:RegisterForEvents()
end

function ZO_ItemSetsBook_Shared:SetupContextTextSearch()
    if self:IsSearchSupported() then
        -- Shared search for tribute patrons
        local filterTargetDescriptor =
        {
            [BACKGROUND_LIST_FILTER_TARGET_ITEM_SET_ID] =
            {
                searchFilterList =
                {
                    BACKGROUND_LIST_FILTER_TYPE_NAME,
                    BACKGROUND_LIST_FILTER_TYPE_SEARCH_KEYWORDS,
                },
                primaryKeys = function()
                    local itemSetCollectionIdList = {}
                    for _, itemSetCollectionData in ITEM_SET_COLLECTIONS_DATA_MANAGER:ItemSetCollectionIterator() do
                        table.insert(itemSetCollectionIdList, itemSetCollectionData:GetId())
                    end
                    return itemSetCollectionIdList
                end,
            },
        }
        TEXT_SEARCH_MANAGER:SetupContextTextSearch(self.searchContext, filterTargetDescriptor)
    end
end

function ZO_ItemSetsBook_Shared:GetSceneName()
    assert(false) -- Must be overridden
end

function ZO_ItemSetsBook_Shared:GetScene()
    return self.scene
end

function ZO_ItemSetsBook_Shared:GetFragment()
    return self.fragment
end

function ZO_ItemSetsBook_Shared:InitializeControls()
    -- Can be overridden
end

function ZO_ItemSetsBook_Shared:InitializeCategories()
    -- Categories refresh group
    local categoriesRefreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_PER_FRAME)
    categoriesRefreshGroup:AddDirtyState("List", function()
        self:RefreshCategories()
    end)
    categoriesRefreshGroup:AddDirtyState("Visible", function()
        self:RefreshVisibleCategories()
        self:RefreshCategoryProgress()
    end)
    categoriesRefreshGroup:SetActive(function()
        return self:IsCategoriesRefreshGroupActive()
    end)
    categoriesRefreshGroup:MarkDirty("List")
    self.categoriesRefreshGroup = categoriesRefreshGroup

    -- Summary category refresh group
    local summaryRefreshGroup = ZO_Refresh:New()
    self.summaryRefreshGroup = summaryRefreshGroup
    local refreshGroupOptions =
    {
        RefreshAll = function()
            self:RefreshSummaryCategoryContent()
        end,
    }
    summaryRefreshGroup:AddRefreshGroup("FullUpdate", refreshGroupOptions)
    summaryRefreshGroup:RefreshAll("FullUpdate")
end

function ZO_ItemSetsBook_Shared:InitializeGridList(gridScrollListTemplate)
    -- Category content refresh group
    local categoryContentRefreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_PER_FRAME)
    categoryContentRefreshGroup:AddDirtyState("All", function()
        self:RefreshCategoryContent()
    end)
    categoryContentRefreshGroup:AddDirtyState("List", function()
        self:RefreshCategoryContentList()
    end)
    categoryContentRefreshGroup:AddDirtyState("Visible", function()
        self:RefreshVisibleCategoryContent()
    end)
    categoryContentRefreshGroup:SetActive(function()
        return self:IsCategoryContentRefreshGroupActive()
    end)
    self.categoryContentRefreshGroup = categoryContentRefreshGroup
    self.gridListPanelList = gridScrollListTemplate:New(self.gridListPanelControl, ZO_GRID_SCROLL_LIST_AUTOFILL)
end

function ZO_ItemSetsBook_Shared:SetupGridHeaderEntry(control, data, selected)
    local itemSetHeaderData = data.header
    control.nameLabel:SetText(itemSetHeaderData:GetFormattedName())
    -- API supports multiple currency options, but UI design only supports 1 for now, so hardcode to 1 for now
    local reconstructionCurrencyType, reconstructionCurrencyCost = itemSetHeaderData:GetReconstructionCurrencyOptionInfo(1)
    local obfuscateAmount = false
    if not reconstructionCurrencyCost then
        obfuscateAmount = true
        reconstructionCurrencyCost = 0
    end

    local CURRENCY_OPTIONS =
    {
        showTooltips = not IsConsoleUI(),
        useShortFormat = false,
        iconSide = RIGHT,
    }

    local SHOW_ALL = true
    local HAS_ENOUGH_CURRENCY = false
    ZO_CurrencyControl_SetSimpleCurrency(control.costLabel, reconstructionCurrencyType, reconstructionCurrencyCost, CURRENCY_OPTIONS, SHOW_ALL, HAS_ENOUGH_CURRENCY, { obfuscateAmount = obfuscateAmount })
    control.progressBar:SetValue(itemSetHeaderData:GetNumUnlockedPieces() / itemSetHeaderData:GetNumPieces())
end

function ZO_ItemSetsBook_Shared:RegisterForEvents()
    ITEM_SET_COLLECTIONS_DATA_MANAGER:RegisterCallback("CollectionsUpdated", function(...) self:OnItemSetCollectionsUpdated(...) end)
    ITEM_SET_COLLECTIONS_DATA_MANAGER:RegisterCallback("PieceLinksDirty", function(...) self:OnPieceLinksDirty(...) end)
    ITEM_SET_COLLECTIONS_DATA_MANAGER:RegisterCallback("PieceNewStatusCleared", function(...) self:OnPieceNewStatusCleared(...) end)
    ITEM_SET_COLLECTIONS_DATA_MANAGER:RegisterCallback("CollectionNewStatusCleared", function(...) self:OnCollectionNewStatusCleared(...) end)
    ITEM_SET_COLLECTIONS_DATA_MANAGER:RegisterCallback("CategoryNewStatusCleared", function(...) self:OnCategoryNewStatusCleared(...) end)
    ITEM_SET_COLLECTIONS_DATA_MANAGER:RegisterCallback("ShowLockedChanged", function(...) self:OnShowLockedOptionUpdated(...) end)
    ITEM_SET_COLLECTIONS_DATA_MANAGER:RegisterCallback("EquipmentFilterTypesChanged", function(...) self:OnEquipmentFilterTypesChanged(...) end)
end

function ZO_ItemSetsBook_Shared:OnItemSetCollectionsUpdated(itemSetIds)
    self.summaryRefreshGroup:RefreshAll("FullUpdate")

    if itemSetIds and ITEM_SET_COLLECTIONS_DATA_MANAGER:GetShowLocked() then
        for _, itemSetId in ipairs(itemSetIds) do
            local itemSetCollectionData = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetItemSetCollectionData(itemSetId)
            local itemSetCollectionCategoryData = itemSetCollectionData:GetCategoryData()
            if self:IsViewingCategory(itemSetCollectionCategoryData) then
                -- Lock state changes result in a re-sorting, so the list needs to be rebuilt
                self.categoryContentRefreshGroup:MarkDirty("List")
                break
            end
        end
        self.categoriesRefreshGroup:MarkDirty("Visible")
    else
        self.categoriesRefreshGroup:MarkDirty("List")
    end
end

function ZO_ItemSetsBook_Shared:OnPieceLinksDirty()
    self.categoryContentRefreshGroup:MarkDirty("Visible")
end

function ZO_ItemSetsBook_Shared:OnPieceNewStatusCleared(itemSetCollectionPieceData)
    local itemSetCollectionCategoryData = itemSetCollectionPieceData:GetItemSetCollectionData():GetCategoryData()
    self:RefreshCategoryNewStatus(itemSetCollectionCategoryData)
end

function ZO_ItemSetsBook_Shared:OnCollectionNewStatusCleared(itemSetCollectionData)
    local itemSetCollectionCategoryData = itemSetCollectionData:GetCategoryData()
    self:RefreshCategoryNewStatus(itemSetCollectionCategoryData)
end

function ZO_ItemSetsBook_Shared:OnCategoryNewStatusCleared(itemSetCollectionCategoryData)
    self:RefreshCategoryNewStatus(itemSetCollectionCategoryData)
end

function ZO_ItemSetsBook_Shared:RefreshCategoryNewStatus(itemSetCollectionCategoryData)
    self.categoriesRefreshGroup:MarkDirty("Visible")
    if self:IsViewingCategory(itemSetCollectionCategoryData) then
        self.categoryContentRefreshGroup:MarkDirty("Visible")
    end
end

-- Overrides ZO_TextSearchObject
function ZO_ItemSetsBook_Shared:OnUpdateSearchResults()
    self:RefreshFilters()
end

function ZO_ItemSetsBook_Shared:OnShowLockedOptionUpdated()
    self:RefreshFilters()
end

function ZO_ItemSetsBook_Shared:OnEquipmentFilterTypesChanged()
    self:RefreshFilters()
end

function ZO_ItemSetsBook_Shared:IsCategoriesRefreshGroupActive()
    return self.fragment:IsShowing()
end

function ZO_ItemSetsBook_Shared:IsCategoryContentRefreshGroupActive()
    return self.fragment:IsShowing()
end

function ZO_ItemSetsBook_Shared:GetSelectedCategory()
    assert(false) -- Must be overridden
end

function ZO_ItemSetsBook_Shared:IsViewingCategory(itemSetCollectionCategoryData)
    local categoryData = self:GetSelectedCategory()
    return categoryData and categoryData:GetId() == itemSetCollectionCategoryData:GetId()
end

function ZO_ItemSetsBook_Shared:GetGridEntryDataObjectPool()
    assert(false) -- Must be overridden
end

function ZO_ItemSetsBook_Shared:GetGridHeaderEntryDataObjectPool()
    assert(false) -- Must be overridden
end

function ZO_ItemSetsBook_Shared:IsSetHeaderCollapsed(itemSetId)
     -- Can be overridden
    return false
end

function ZO_ItemSetsBook_Shared:IsSearchSupported()
    -- Can be overridden
    return false
end

function ZO_ItemSetsBook_Shared:IsReconstructing()
    assert(false) -- Must be overridden
end

function ZO_ItemSetsBook_Shared:IsOptionsModeShowing()
    -- Can be overridden
    return false
end

function ZO_ItemSetsBook_Shared:CanReconstruct()
    -- Can be overriden
    return false
end

function ZO_ItemSetsBook_Shared:ShowReconstructOptions()
    assert(false) -- Must be overriden
end

function ZO_ItemSetsBook_Shared:RefreshSummaryCategoryContent()
    -- Can be overridden
end

function ZO_ItemSetsBook_Shared:RefreshCategoryProgress()
    -- Can be overridden
end

function ZO_ItemSetsBook_Shared:GetItemSetHeaderNarrationText(headerData)
    -- Can be overridden
end

function ZO_ItemSetsBook_Shared:RefreshFilters()
    self:RefreshPieceFilters()

    ZO_ClearNumericallyIndexedTable(self.setFilters)
    ZO_ClearNumericallyIndexedTable(self.categoryFilters)

    if #self.pieceFilters > 0 then
        local function Filter(data)
            return data:AnyChildPassesFilters(self.pieceFilters)
        end
        table.insert(self.setFilters, Filter)
        table.insert(self.categoryFilters, Filter)
    end

    self.categoriesRefreshGroup:MarkDirty("List")
end

function ZO_ItemSetsBook_Shared:RefreshPieceFilters()
    local pieceFilters = self.pieceFilters

    ZO_ClearNumericallyIndexedTable(pieceFilters)

    if self:IsSearchSupported() and self:HasSearchFilter() then
        table.insert(pieceFilters, ZO_ItemSetCollectionPieceData.IsSearchResult)
    end

    if not ITEM_SET_COLLECTIONS_DATA_MANAGER:GetShowLocked() then
        table.insert(pieceFilters, ZO_ItemSetCollectionPieceData.IsUnlocked)
    end

    local equipmentFilterTypes = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetEquipmentFilterTypes()
    if #equipmentFilterTypes > 0 then
        local function MatchesEquipmentFilterTypes(itemSetCollectionPiece)
            return itemSetCollectionPiece:MatchesEquipmentFilterTypes(equipmentFilterTypes)
        end
        table.insert(self.pieceFilters, MatchesEquipmentFilterTypes)
    end
end

-- Do not call this directly, instead call self.categoriesRefreshGroup:MarkDirty("List")
function ZO_ItemSetsBook_Shared:RefreshCategories()
    assert(false) -- Must be overridden
end

-- Do not call this directly, instead call self.categoriesRefreshGroup:MarkDirty("Visible")
function ZO_ItemSetsBook_Shared:RefreshVisibleCategories()
    assert(false) -- Must be overridden
end

-- Do not call this directly, instead call self.categoryContentRefreshGroup:MarkDirty("All")
function ZO_ItemSetsBook_Shared:RefreshCategoryContent()
    -- May be overridden if there's more than just a list being shown for a category
    self:RefreshCategoryContentList()
end

-- Do not call this directly, instead call self.categoryContentRefreshGroup:MarkDirty("List")
function ZO_ItemSetsBook_Shared:RefreshCategoryContentList()
    local gridListPanelList = self.gridListPanelList
    local entryDataObjectPool = self:GetGridEntryDataObjectPool()
    local headerEntryDataObjectPool = self:GetGridHeaderEntryDataObjectPool()
    local tempUnlockedEntriesForRefresh = self.tempUnlockedEntriesForRefresh
    local tempLockedEntriesForRefresh = self.tempLockedEntriesForRefresh

    gridListPanelList:ClearGridList()
    entryDataObjectPool:ReleaseAllObjects()
    headerEntryDataObjectPool:ReleaseAllObjects()

    local itemSetCollectionCategoryData = self:GetSelectedCategory()
    if itemSetCollectionCategoryData then
        for _, itemSetCollectionData in itemSetCollectionCategoryData:CollectionIterator(self.setFilters) do
            local headerEntryData = headerEntryDataObjectPool:AcquireObject()
            headerEntryData:SetDataSource(itemSetCollectionData)
            headerEntryData.collapsed = self:IsSetHeaderCollapsed(itemSetCollectionData:GetId())
            headerEntryData.headerNarrationFunction = function(...) return self:GetItemSetHeaderNarrationText(...) end
            ZO_ClearNumericallyIndexedTable(tempUnlockedEntriesForRefresh)
            ZO_ClearNumericallyIndexedTable(tempLockedEntriesForRefresh)
            for _, itemSetCollectionPieceData in itemSetCollectionData:PieceIterator(self.pieceFilters) do
                local entryData = entryDataObjectPool:AcquireObject()
                entryData:SetDataSource(itemSetCollectionPieceData)
                entryData.gridHeaderData = headerEntryData
                if itemSetCollectionPieceData:IsUnlocked() then
                    table.insert(tempUnlockedEntriesForRefresh, entryData)
                else
                    table.insert(tempLockedEntriesForRefresh, entryData)
                end
            end

            -- All unlocked go before all locked
            for _, entryData in ipairs(tempUnlockedEntriesForRefresh) do
                gridListPanelList:AddEntry(entryData)
            end

            for _, entryData in ipairs(tempLockedEntriesForRefresh) do
                gridListPanelList:AddEntry(entryData)
            end
        end
    end

    gridListPanelList:CommitGridList()
end

-- Do not call this directly, instead call self.categoryContentRefreshGroup:MarkDirty("Visible")
function ZO_ItemSetsBook_Shared:RefreshVisibleCategoryContent()
    self.gridListPanelList:RefreshGridList()
end

function ZO_ItemSetsBook_Shared:OnFragmentShowing()
    ITEM_SET_COLLECTIONS_DATA_MANAGER:CleanData()

    local isReconstructing = self:IsReconstructing()
    if self.wasReconstructing ~= isReconstructing then
        -- Force a refresh of the categories when switching between collection and
        -- reconstruction mode to display the appropriate categories contextually.
        self.wasReconstructing = isReconstructing
        self.categoriesRefreshGroup:MarkDirty("List")
    end

    self.categoriesRefreshGroup:TryClean()
    self.categoryContentRefreshGroup:TryClean()
end

function ZO_ItemSetsBook_Shared:MarkCategoryContentDirty(stateName)
    self.categoryContentRefreshGroup:MarkDirty(stateName)
end

function ZO_ItemSetsBook_SummaryEntry_Header_Shared_OnInitialize(control)
    control.nameLabel = control:GetNamedChild("Name")
    control.progressBar = control:GetNamedChild("Progress")
end

function ZO_ItemSetsBook_Entry_Header_Shared_OnInitialize(control)
    control.costLabel = control:GetNamedChild("Cost")
    control.nameLabel = control:GetNamedChild("Name")
    control.progressBar = control:GetNamedChild("Progress")
end