local COLLECTIBLE_TILE_GRID_PADDING = 10
local VISIBLE_ICON = "EsoUI/Art/Inventory/inventory_icon_visible.dds"

-----------------------------
-- Companion Collection Book
-----------------------------
ZO_CompanionCollectionBook_Keyboard = ZO_InitializingObject:Subclass()

function ZO_CompanionCollectionBook_Keyboard:Initialize(control)
    self.control = control

    self.categoryNodeLookupData = {}

    self:InitializeControls()
    self:InitializeEvents()
    self:InitializeCategories()
    self:InitializeFilters()
    self:InitializeGridListPanel()

    self.scene = ZO_InteractScene:New("companionCollectionBookKeyboard", SCENE_MANAGER, ZO_COMPANION_MANAGER:GetInteraction())
    self.scene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self.refreshGroups:UpdateRefreshGroups() --In case we need to rebuild the categories
            self:UpdateCollectionVisualLayer()
            COLLECTIONS_BOOK_SINGLETON:SetSearchString(self.contentSearchEditBox:GetText())
            COLLECTIONS_BOOK_SINGLETON:SetSearchCategorySpecializationFilters(COLLECTIBLE_CATEGORY_SPECIALIZATION_NONE)
            COLLECTIONS_BOOK_SINGLETON:SetSearchChecksHidden(true)
        elseif newState == SCENE_HIDDEN then
            self.gridListPanelList:ResetToTop()
        end
    end)

    COMPANION_COLLECTION_BOOK_KEYBOARD_SCENE = self.scene
    COMPANION_COLLECTION_BOOK_KEYBOARD_FRAGMENT = ZO_FadeSceneFragment:New(self.control)

    self.control:SetHandler("OnUpdate", function() self.refreshGroups:UpdateRefreshGroups() end)

    self:UpdateCollection()
end

function ZO_CompanionCollectionBook_Keyboard:InitializeControls()
    self.categoryFilterComboBox = self.control:GetNamedChild("Filter")
    self.contentSearchEditBox = self.control:GetNamedChild("SearchBox")
    self.noMatches = self.control:GetNamedChild("NoMatchMessage")
end

function ZO_CompanionCollectionBook_Keyboard:InitializeEvents()
    local function OnUpdateSearchResults()
        if self.scene:IsShowing() then
            self:UpdateCollection()
        end
    end

    self.control:RegisterForEvent(EVENT_VISUAL_LAYER_CHANGED, function() self:UpdateCollectionVisualLayer() end)

    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("UpdateSearchResults", OnUpdateSearchResults)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUpdated", function(...) self:OnCollectibleUpdated(...) end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", function(...) self:OnCollectionUpdated(...) end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleNewStatusCleared", function(...) self:OnCollectibleNewStatusCleared(...) end)

    self.refreshGroups = ZO_Refresh:New()
    self.refreshGroups:AddRefreshGroup("FullUpdate",
    {
        RefreshAll = function()
            self:UpdateCollection()
        end,
    })

    self.refreshGroups:AddRefreshGroup("CollectibleUpdated",
    {
        RefreshSingle = function(collectibleId)
            self:UpdateCollectible(collectibleId)
        end,
    })
end

do
    local FILTER_DATA =
    {
        SI_COLLECTIONS_BOOK_FILTER_SHOW_ALL,
        SI_COLLECTIONS_BOOK_FILTER_SHOW_NEW,
        SI_COLLECTIONS_BOOK_FILTER_SHOW_LOCKED,
        SI_COLLECTIONS_BOOK_FILTER_SHOW_UNLOCKED,
    }

    function ZO_CompanionCollectionBook_Keyboard:InitializeFilters()
        local comboBox = ZO_ComboBox_ObjectFromContainer(self.categoryFilterComboBox)
        comboBox:SetSortsItems(false)
        comboBox:SetFont("ZoFontWinT1")
        comboBox:SetSpacing(4)

        local function OnFilterChanged(_, _, entry)
            self.categoryFilterComboBox.filterType = entry.filterType
            local categoryData = self.categoryTree:GetSelectedData()
            if categoryData then
                self:BuildContentList(categoryData)
            end
        end

        for _, stringId in ipairs(FILTER_DATA) do
            local entry = comboBox:CreateItemEntry(GetString(stringId), OnFilterChanged)
            entry.filterType = stringId
            comboBox:AddItem(entry)
        end

        comboBox:SelectFirstItem()
    end
end

do
    local CHILD_INDENT = 76
    local CHILD_SPACING = 0

    function ZO_CompanionCollectionBook_Keyboard:InitializeCategories()
        self.categories = self.control:GetNamedChild("Categories")
        self.categoryTree = ZO_Tree:New(self.categories:GetNamedChild("ScrollChild"), 60, -10, 300)

        local function BaseTreeHeaderIconSetup(control, categoryData, open)
            local normalIcon, pressedIcon, mouseoverIcon = categoryData:GetKeyboardIcons()
            control.icon:SetTexture(open and pressedIcon or normalIcon)
            control.iconHighlight:SetTexture(mouseoverIcon)

            ZO_IconHeader_Setup(control, open)
        end

        local function BaseTreeHeaderSetup(node, control, categoryData, open)
            control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
            control.text:SetText(categoryData:GetFormattedName())
            BaseTreeHeaderIconSetup(control, categoryData, open)
        end

        local function TreeHeaderSetup_Child(node, control, categoryData, open, userRequested)
            BaseTreeHeaderSetup(node, control, categoryData, open)

            if open and userRequested then
                self.categoryTree:SelectFirstChild(node)
            end
        end

        local function TreeHeaderSetup_Childless(node, control, categoryData, open)
            BaseTreeHeaderSetup(node, control, categoryData, open)
        end

        local function TreeEntryOnSelected(control, categoryData, selected, reselectingDuringRebuild)
            control:SetSelected(selected)

            if selected then
                self:BuildContentList(categoryData)
            end
        end

        local function TreeEntryOnSelected_Childless(control, categoryData, selected, reselectingDuringRebuild)
            TreeEntryOnSelected(control, categoryData, selected, reselectingDuringRebuild)
            BaseTreeHeaderIconSetup(control, categoryData, selected)
        end

        local function TreeEntrySetup(node, control, categoryData, open)
            control:SetSelected(false)
            control:SetText(categoryData:GetFormattedName())
        end

        local DEFAULT_ON_SELECTED = nil
        local DEFAULT_EQUALITY = nil
        local DEFAULT_INDENT = nil
        local DEFAULT_SPACING = nil
        self.categoryTree:AddTemplate("ZO_CompanionCollectionsBook_StatusIconHeader", TreeHeaderSetup_Child, DEFAULT_ON_SELECTED, DEFAULT_EQUALITY, CHILD_INDENT, CHILD_SPACING, "StatusIconHeader")
        self.categoryTree:AddTemplate("ZO_CompanionCollectionsBook_StatusIconChildlessHeader", TreeHeaderSetup_Childless, TreeEntryOnSelected_Childless, DEFAULT_EQUALITY, DEFAULT_INDENT, DEFAULT_SPACING, "StatusIconChildlessHeader")
        self.categoryTree:AddTemplate("ZO_CompanionCollectionsBook_SubCategory", TreeEntrySetup, TreeEntryOnSelected, DEFAULT_EQUALITY, DEFAULT_INDENT, DEFAULT_SPACING, "SubCategory")

        self.categoryTree:SetExclusive(true)
        self.categoryTree:SetOpenAnimation("ZO_TreeOpenAnimation")
    end
end

function ZO_CompanionCollectionBook_Keyboard:InitializeGridListPanel()
    self.entryDataObjectPool = ZO_EntryDataPool:New(ZO_GridSquareEntryData_Shared)
    self.entryDataObjectPool:SetCustomFactoryBehavior(function(entryData)
        entryData.actorCategory = GAMEPLAY_ACTOR_CATEGORY_COMPANION
    end)

    local gridListPanel = self.control:GetNamedChild("List")
    self.gridListPanelControl = gridListPanel
    self.gridListPanelList = ZO_GridScrollList_Keyboard:New(gridListPanel, ZO_GRID_SCROLL_LIST_AUTOFILL)

    local HIDE_CALLBACK = nil
    local CENTER_ENTRIES = true --TODO: Remove this when it's the default
    local HEADER_HEIGHT = 30
    self.gridListPanelList:AddEntryTemplate("ZO_CollectibleTile_Keyboard_Control", ZO_COLLECTIBLE_TILE_KEYBOARD_DIMENSIONS_X, ZO_COLLECTIBLE_TILE_KEYBOARD_DIMENSIONS_Y, ZO_DefaultGridTileEntrySetup, HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, COLLECTIBLE_TILE_GRID_PADDING, COLLECTIBLE_TILE_GRID_PADDING, CENTER_ENTRIES)
    self.gridListPanelList:AddEntryTemplate("ZO_CollectibleImitationTile_Keyboard_Control", ZO_COLLECTIBLE_TILE_KEYBOARD_DIMENSIONS_X, ZO_COLLECTIBLE_TILE_KEYBOARD_DIMENSIONS_Y, ZO_DefaultGridTileEntrySetup, HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, COLLECTIBLE_TILE_GRID_PADDING, COLLECTIBLE_TILE_GRID_PADDING, CENTER_ENTRIES)
    self.gridListPanelList:SetAutoFillEntryTemplate("ZO_CollectibleTile_Keyboard_Control")
    self.gridListPanelList:AddHeaderTemplate(ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_KEYBOARD, HEADER_HEIGHT, ZO_DefaultGridHeaderSetup)
    self.gridListPanelList:SetHeaderPrePadding(COLLECTIBLE_TILE_GRID_PADDING * 3)
end

--[[ Refresh ]]--
-----------------

function ZO_CompanionCollectionBook_Keyboard:BuildCategories()
    self.categoryTree:Reset()
    ZO_ClearTable(self.categoryNodeLookupData)

    local function AddCategoryByCategoryIndex(categoryIndex)
        local categoryData = ZO_COLLECTIBLE_DATA_MANAGER:GetCategoryDataByIndicies(categoryIndex)
        --Some categories are handled by specialized scenes.
        if categoryData:IsStandardCategory() and categoryData:HasAnyCompanionUsableCollectibles() then
            self:AddTopLevelCategory(categoryData)
        end
    end

    local searchResults = COLLECTIONS_BOOK_SINGLETON:GetSearchResults()
    if searchResults then
        for categoryIndex, _ in pairs(searchResults) do
            AddCategoryByCategoryIndex(categoryIndex)
        end
    else
        for categoryIndex, _ in ZO_COLLECTIBLE_DATA_MANAGER:CategoryIterator({ ZO_CollectibleCategoryData.HasShownCollectiblesInCollection, ZO_CollectibleCategoryData.HasAnyCompanionUsableCollectibles }) do
            AddCategoryByCategoryIndex(categoryIndex)
        end
    end
    self.categoryTree:Commit()

    self:UpdateAllCategoryStatusIcons()
end

do
    function ZO_CompanionCollectionBook_Keyboard:AddTopLevelCategory(categoryData)
        local searchResults = COLLECTIONS_BOOK_SINGLETON:GetSearchResults()

        if not searchResults then
            local hasChildren = categoryData:GetNumSubcategories() > 0
            local nodeTemplate = hasChildren and "ZO_CompanionCollectionsBook_StatusIconHeader" or "ZO_CompanionCollectionsBook_StatusIconChildlessHeader"

            local parentNode = self:AddCategory(nodeTemplate, categoryData)

            for _, subcategoryData in categoryData:SubcategoryIterator({ ZO_CollectibleCategoryData.HasShownCollectiblesInCollection, ZO_CollectibleCategoryData.HasAnyCompanionUsableCollectibles }) do
                self:AddCategory("ZO_CompanionCollectionsBook_SubCategory", subcategoryData, parentNode)
            end
        else
            local categoryIndex = categoryData:GetCategoryIndicies()
            local hasChildren = NonContiguousCount(searchResults[categoryIndex]) > 1 or searchResults[categoryIndex][ZO_COLLECTIONS_SEARCH_ROOT] == nil
            local nodeTemplate = hasChildren and "ZO_CompanionCollectionsBook_StatusIconHeader" or "ZO_CompanionCollectionsBook_StatusIconChildlessHeader"
            local parentNode = nil

            for subcategoryIndex, _ in pairs(searchResults[categoryIndex]) do
                if subcategoryIndex ~= ZO_COLLECTIONS_SEARCH_ROOT then
                    local subcategoryData = ZO_COLLECTIBLE_DATA_MANAGER:GetCategoryDataByIndicies(categoryIndex, subcategoryIndex)
                    if subcategoryData:HasAnyCompanionUsableCollectibles() then
                        if not parentNode then
                            parentNode = self:AddCategory(nodeTemplate, categoryData)
                        end
                        self:AddCategory("ZO_CompanionCollectionsBook_SubCategory", subcategoryData, parentNode)
                    end
                end
            end
        end
    end
end

function ZO_CompanionCollectionBook_Keyboard:AddCategory(nodeTemplate, categoryData, parentNode)
    local node = self.categoryTree:AddNode(nodeTemplate, categoryData, parentNode)
    self.categoryNodeLookupData[categoryData:GetId()] = node
    return node
end

function ZO_CompanionCollectionBook_Keyboard:UpdateCategoryStatus(categoryNode)
    local categoryData = categoryNode.data

    if categoryData:IsSubcategory() then
        self:UpdateCategoryStatusIcon(categoryNode:GetParent())
    end

    self:UpdateCategoryStatusIcon(categoryNode)
end

function ZO_CompanionCollectionBook_Keyboard:UpdateAllCategoryStatusIcons()
    for _, categoryNode in pairs(self.categoryNodeLookupData) do
        self:UpdateCategoryStatusIcon(categoryNode)
    end
end

local function GetCollectiblesDataFromCategory(categoryData, sorted)
    local collectiblesData = {}

    local searchResults = COLLECTIONS_BOOK_SINGLETON:GetSearchResults()
    local searchResultsSubcategory = nil
    if searchResults then
        local categoryIndex, subcategoryIndex = categoryData:GetCategoryIndicies()
        local categoryResults = searchResults[categoryIndex]
        if categoryResults then
            local effectiveSubcategoryIndex = subcategoryIndex or ZO_COLLECTIONS_SEARCH_ROOT
            searchResultsSubcategory = categoryResults[effectiveSubcategoryIndex]
        end
    end

    local iterator = sorted and ZO_CollectibleCategoryData.SortedCollectibleIterator or ZO_CollectibleCategoryData.CollectibleIterator
    for _, collectibleData in iterator(categoryData, { ZO_CollectibleData.IsShownInCollection }) do
        if (not searchResultsSubcategory or searchResultsSubcategory[collectibleData:GetIndex()]) and collectibleData:IsCollectibleCategoryCompanionUsable() then
            table.insert(collectiblesData, collectibleData)
        end
    end

    return collectiblesData
end

function ZO_CompanionCollectionBook_Keyboard:UpdateCategoryStatusIcon(categoryNode)
    local categoryData = categoryNode.data
    local categoryControl = categoryNode.control

    if not categoryControl.statusIcon then
        categoryControl.statusIcon = categoryControl:GetNamedChild("StatusIcon")
    end

    categoryControl.statusIcon:ClearIcons()

    if categoryData:HasAnyNewCompanionCollectibles() then
        categoryControl.statusIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
    end

    local collectiblesData = GetCollectiblesDataFromCategory(categoryData)
    for _, collectibleData in ipairs(collectiblesData) do
        if collectibleData:IsVisualLayerShowing(GAMEPLAY_ACTOR_CATEGORY_COMPANION) then
            categoryControl.statusIcon:AddIcon(VISIBLE_ICON)
            break
        end
    end

    categoryControl.statusIcon:Show()
end

do
    local function ShouldAddCollectible(filterType, collectibleData)
        if not collectibleData:IsCollectibleAvailableToCompanion() then
            return false
        end

        if filterType == SI_COLLECTIONS_BOOK_FILTER_SHOW_ALL then
            return true
        end

        if collectibleData:IsUnlocked() then
            if filterType == SI_COLLECTIONS_BOOK_FILTER_SHOW_UNLOCKED then
                return true
            elseif filterType == SI_COLLECTIONS_BOOK_FILTER_SHOW_NEW then
                return collectibleData:IsNew()
            else
                return false
            end
        end
    end

    function ZO_CompanionCollectionBook_Keyboard:BuildContentList(categoryData)
        local gridListPanelList = self.gridListPanelList
        gridListPanelList:ClearGridList()
        self.entryDataObjectPool:ReleaseAllObjects()

        if categoryData then
            local SORTED = true
            local collectiblesData = GetCollectiblesDataFromCategory(categoryData, SORTED)
            local imitationTilesProcessed = false

            for _, collectibleData in ipairs(collectiblesData) do
                if ShouldAddCollectible(self.categoryFilterComboBox.filterType, collectibleData) then
                    if not imitationTilesProcessed then
                        local collectibleCategoryTypesInCategory = categoryData:GetCollectibleCategoryTypesInCategory()
                        for categoryType in pairs(collectibleCategoryTypesInCategory) do
                            local setToDefaultCollectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetSetToDefaultCollectibleData(categoryType, GAMEPLAY_ACTOR_CATEGORY_COMPANION)
                            if setToDefaultCollectibleData then
                                local defaultEntryData = self.entryDataObjectPool:AcquireObject()
                                defaultEntryData:SetDataSource(setToDefaultCollectibleData)
                                defaultEntryData.gridHeaderTemplate = ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_KEYBOARD
                                defaultEntryData.gridHeaderName = ""
                                gridListPanelList:AddEntry(defaultEntryData, "ZO_CollectibleImitationTile_Keyboard_Control")
                            end
                        end

                        if collectibleCategoryTypesInCategory[COLLECTIBLE_CATEGORY_TYPE_MOUNT] then
                            local randomMountEntryData = self.entryDataObjectPool:AcquireObject()
                            local setAnyRandomMountData = ZO_RandomMountCollectibleData:New(RANDOM_MOUNT_TYPE_ANY)
                            randomMountEntryData:SetDataSource(setAnyRandomMountData)
                            randomMountEntryData.gridHeaderTemplate = ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_KEYBOARD
                            randomMountEntryData.gridHeaderName = ""
                            gridListPanelList:AddEntry(randomMountEntryData, "ZO_CollectibleImitationTile_Keyboard_Control")
                        end

                        imitationTilesProcessed = true
                    end
                    local entryData = self.entryDataObjectPool:AcquireObject()
                    entryData:SetDataSource(collectibleData)
                    local headerState = collectibleData:IsUnlocked() and COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED or COLLECTIBLE_UNLOCK_STATE_LOCKED
                    entryData.gridHeaderTemplate = ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_KEYBOARD
                    entryData.gridHeaderName = GetString("SI_COLLECTIBLEUNLOCKSTATE", headerState)
                    gridListPanelList:AddEntry(entryData, "ZO_CollectibleTile_Keyboard_Control")
                end
            end
        end

        gridListPanelList:CommitGridList()
    end
end

function ZO_CompanionCollectionBook_Keyboard:OnCollectionUpdated()
    self:UpdateCollectionLater()
end

function ZO_CompanionCollectionBook_Keyboard:UpdateCollectionLater()
    self.refreshGroups:RefreshAll("FullUpdate")

    COMPANION_KEYBOARD:UpdateSceneGroupButtons("companionSceneGroup")
end

function ZO_CompanionCollectionBook_Keyboard:UpdateCollection()
    self:BuildCategories()
    local searchResults = COLLECTIONS_BOOK_SINGLETON:GetSearchResults()
    local searchResultsHaveCompanionUsableCollectibles = false
    if searchResults then
        for categoryIndex, _ in pairs(searchResults) do
            for subcategoryIndex, _ in pairs(searchResults[categoryIndex]) do
                if subcategoryIndex ~= ZO_COLLECTIONS_SEARCH_ROOT then
                    local subcategoryData = ZO_COLLECTIBLE_DATA_MANAGER:GetCategoryDataByIndicies(categoryIndex, subcategoryIndex)
                    if subcategoryData:HasAnyCompanionUsableCollectibles() then
                        searchResultsHaveCompanionUsableCollectibles = true
                        break
                    end
                end
            end
            if searchResultsHaveCompanionUsableCollectibles then
                break
            end
        end
    end
    local foundNoMatches = searchResults and not searchResultsHaveCompanionUsableCollectibles
    self.categoryFilterComboBox:SetHidden(foundNoMatches)
    self.noMatches:SetHidden(not foundNoMatches)
    self.gridListPanelControl:SetHidden(foundNoMatches)
end

function ZO_CompanionCollectionBook_Keyboard:OnCollectibleUpdated(collectibleId)
    self.refreshGroups:RefreshSingle("CollectibleUpdated", collectibleId)

    COMPANION_KEYBOARD:UpdateSceneGroupButtons("companionSceneGroup")
end

function ZO_CompanionCollectionBook_Keyboard:UpdateCollectible(collectibleId)
    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
    if internalassert(collectibleData, "CompanionCollectionsBook UpdateCollectible called with invalid id") then
        local categoryData = collectibleData:GetCategoryData()
        local categoryNode = self.categoryNodeLookupData[categoryData:GetId()]
        if categoryNode then
            self:UpdateCategoryStatus(categoryNode)

            local setDefaultTileRefreshed = false
            local selectedCategoryData = self.categoryTree:GetSelectedData()
            if categoryData == selectedCategoryData  then
                local gridEntry = self:GetEntryByCollectibleId(collectibleId)
                if gridEntry then
                    local tileControl = gridEntry.dataEntry.control
                    if tileControl then
                        local data =
                        {
                            collectibleId = collectibleId,
                            actorCategory = GAMEPLAY_ACTOR_CATEGORY_COMPANION,
                        }
                        tileControl.object:Layout(data)
                    end
                else
                    self:BuildContentList(categoryData)
                    setDefaultTileRefreshed = true
                end
            end

            if not setDefaultTileRefreshed then
                local setDefaultGridEntry = self:GetSetDefaultEntryByType(collectibleData:GetCategoryType())
                if setDefaultGridEntry then
                    local tileControl = setDefaultGridEntry.dataEntry.control
                    if tileControl then
                        tileControl.object:Refresh()
                    end
                end
            end
        else
            self:UpdateCollection()
        end
    end
end

function ZO_CompanionCollectionBook_Keyboard:OnCollectibleStatusUpdated(collectibleId)
    self.refreshGroups:RefreshSingle("CollectibleUpdated", collectibleId)

    COMPANION_KEYBOARD:UpdateSceneGroupButtons("companionSceneGroup")
end

function ZO_CompanionCollectionBook_Keyboard:OnCollectibleNewStatusCleared(collectibleId)
    self:OnCollectibleStatusUpdated(collectibleId)
end

function ZO_CompanionCollectionBook_Keyboard:GetSetDefaultEntryByType(categoryType)
    local entries = self.entryDataObjectPool:GetActiveObjects()
    for _, entry in pairs(entries) do
        if entry.categoryTypeToSetDefault  == categoryType then
            return entry
        end
    end
    return nil
end

function ZO_CompanionCollectionBook_Keyboard:GetEntryByCollectibleId(collectibleId)
    local entries = self.entryDataObjectPool:GetActiveObjects()
    for _, entry in pairs(entries) do
        if entry.GetId and entry:GetId() == collectibleId then
            return entry
        end
    end
    return nil
end

function ZO_CompanionCollectionBook_Keyboard:UpdateCollectionVisualLayer()
    self.gridListPanelList:RefreshGridList()
    self:UpdateAllCategoryStatusIcons()
end


-----------------------------
-- Global XML Functions
-----------------------------

function ZO_CompanionCollectionBook_Keyboard_OnInitialize(control)
    COMPANION_COLLECTION_BOOK_KEYBOARD = ZO_CompanionCollectionBook_Keyboard:New(control)
end