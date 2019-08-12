local COLLECTIBLE_TILE_GRID_PADDING = 10
local VISIBLE_ICON = "EsoUI/Art/Inventory/inventory_icon_visible.dds"

local function RefreshMainMenu()
    MAIN_MENU_KEYBOARD:RefreshCategoryBar()
    MAIN_MENU_KEYBOARD:UpdateSceneGroupButtons("collectionsSceneGroup")
end

--[[ Collection ]]--
--------------------
--[[ Initialization ]]--
------------------------
ZO_CollectionsBook = ZO_Object:Subclass()

function ZO_CollectionsBook:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_CollectionsBook:Initialize(control)
    self.control = control

    self.categoryNodeLookupData = {}

    self:InitializeControls()
    self:InitializeEvents()
    self:InitializeCategories()
    self:InitializeFilters()
    self:InitializeGridListPanel()

    self.control:SetHandler("OnUpdate", function() self.refreshGroups:UpdateRefreshGroups() end)

    self.scene = ZO_Scene:New("collectionsBook", SCENE_MANAGER)
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

    self:UpdateCollection()

    SYSTEMS:RegisterKeyboardObject(ZO_COLLECTIONS_SYSTEM_NAME, self)
end

function ZO_CollectionsBook:InitializeControls()
    self.categoryFilterComboBox = self.control:GetNamedChild("Filter")
    self.contentSearchEditBox = self.control:GetNamedChild("SearchBox")
    self.noMatches = self.control:GetNamedChild("NoMatchMessage")
end

function ZO_CollectionsBook:InitializeEvents()
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
        SI_COLLECTIONS_BOOK_FILTER_SHOW_LOCKED,
        SI_COLLECTIONS_BOOK_FILTER_SHOW_USABLE,
        SI_COLLECTIONS_BOOK_FILTER_SHOW_UNLOCKED,
    }

    function ZO_CollectionsBook:InitializeFilters()
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

    function ZO_CollectionsBook:InitializeCategories()
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

            if(open and userRequested) then
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

        self.categoryTree:AddTemplate("ZO_StatusIconHeader", TreeHeaderSetup_Child, nil, nil, CHILD_INDENT, CHILD_SPACING)
        self.categoryTree:AddTemplate("ZO_StatusIconChildlessHeader", TreeHeaderSetup_Childless, TreeEntryOnSelected_Childless)
        self.categoryTree:AddTemplate("ZO_TreeStatusLabelSubCategory", TreeEntrySetup, TreeEntryOnSelected)

        self.categoryTree:SetExclusive(true)
        self.categoryTree:SetOpenAnimation("ZO_TreeOpenAnimation")
    end
end

function ZO_CollectionsBook:InitializeGridListPanel()
    local function CreateEntryData()
        return ZO_GridSquareEntryData_Shared:New()
    end

    local function ResetEntryData(data)
        data:SetDataSource(nil)
    end

    self.entryDataObjectPool = ZO_ObjectPool:New(CreateEntryData, ResetEntryData)

    local gridListPanel = self.control:GetNamedChild("List")
    self.gridListPanelControl = gridListPanel
    self.gridListPanelList = ZO_SingleTemplateGridScrollList_Keyboard:New(gridListPanel, ZO_GRID_SCROLL_LIST_AUTOFILL)

    local HIDE_CALLBACK = nil
    local CENTER_ENTRIES = true --TODO: Remove this when it's the default
    local HEADER_HEIGHT = 30
    self.gridListPanelList:SetGridEntryTemplate("ZO_CollectibleTile_Keyboard_Control", ZO_COLLECTIBLE_TILE_KEYBOARD_DIMENSIONS_X, ZO_COLLECTIBLE_TILE_KEYBOARD_DIMENSIONS_Y, ZO_DefaultGridTileEntrySetup, HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, COLLECTIBLE_TILE_GRID_PADDING, COLLECTIBLE_TILE_GRID_PADDING, CENTER_ENTRIES)
    self.gridListPanelList:SetHeaderTemplate(ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_KEYBOARD, HEADER_HEIGHT, ZO_DefaultGridHeaderSetup)
    self.gridListPanelList:SetHeaderPrePadding(COLLECTIBLE_TILE_GRID_PADDING * 3)
end

--[[ Refresh ]]--
-----------------

function ZO_CollectionsBook:BuildCategories()
    self.categoryTree:Reset()
    ZO_ClearTable(self.categoryNodeLookupData)
        
    local function AddCategoryByCategoryIndex(categoryIndex)
        local categoryData = ZO_COLLECTIBLE_DATA_MANAGER:GetCategoryDataByIndicies(categoryIndex)
        --Some categories are handled by specialized scenes.
        if categoryData:IsStandardCategory() then
            self:AddTopLevelCategory(categoryData)
        end
    end

    local searchResults = COLLECTIONS_BOOK_SINGLETON:GetSearchResults()
    if searchResults then
        for categoryIndex, _ in pairs(searchResults) do
            AddCategoryByCategoryIndex(categoryIndex)
        end
    else
        for categoryIndex, _ in ZO_COLLECTIBLE_DATA_MANAGER:CategoryIterator({ ZO_CollectibleCategoryData.HasShownCollectiblesInCollection }) do
            AddCategoryByCategoryIndex(categoryIndex)
        end
    end
    self.categoryTree:Commit()

    self:UpdateAllCategoryStatusIcons()
end

do
    function ZO_CollectionsBook:AddTopLevelCategory(categoryData)
        local searchResults = COLLECTIONS_BOOK_SINGLETON:GetSearchResults()

        if not searchResults then
            local hasChildren = categoryData:GetNumSubcategories() > 0
            local nodeTemplate = hasChildren and "ZO_StatusIconHeader" or "ZO_StatusIconChildlessHeader"

            local parentNode = self:AddCategory(nodeTemplate, categoryData)
        
            for _, subcategoryData in categoryData:SubcategoryIterator({ZO_CollectibleCategoryData.HasShownCollectiblesInCollection}) do
                self:AddCategory("ZO_TreeStatusLabelSubCategory", subcategoryData, parentNode)
            end
        else
            local categoryIndex = categoryData:GetCategoryIndicies()
            local hasChildren = NonContiguousCount(searchResults[categoryIndex]) > 1 or searchResults[categoryIndex][ZO_COLLECTIONS_SEARCH_ROOT] == nil
            local nodeTemplate = hasChildren and "ZO_StatusIconHeader" or "ZO_StatusIconChildlessHeader"

            local parentNode = self:AddCategory(nodeTemplate, categoryData)
        
            for subcategoryIndex, _ in pairs(searchResults[categoryIndex]) do
                if subcategoryIndex ~= ZO_COLLECTIONS_SEARCH_ROOT then
                    local subcategoryData = ZO_COLLECTIBLE_DATA_MANAGER:GetCategoryDataByIndicies(categoryIndex, subcategoryIndex)
                    self:AddCategory("ZO_TreeStatusLabelSubCategory", subcategoryData, parentNode)
                end
            end
        end
    end
end

function ZO_CollectionsBook:AddCategory(nodeTemplate, categoryData, parentNode)
    local node = self.categoryTree:AddNode(nodeTemplate, categoryData, parentNode)
    self.categoryNodeLookupData[categoryData:GetId()] = node
    return node
end

function ZO_CollectionsBook:UpdateCategoryStatus(categoryNode)
    local categoryData = categoryNode.data
    
    if categoryData:IsSubcategory() then
        self:UpdateCategoryStatusIcon(categoryNode:GetParent())
    end

    self:UpdateCategoryStatusIcon(categoryNode)
end

function ZO_CollectionsBook:UpdateAllCategoryStatusIcons()
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
        if not searchResultsSubcategory or searchResultsSubcategory[collectibleData:GetIndex()] then
            table.insert(collectiblesData, collectibleData)
        end
    end

    return collectiblesData
end

function ZO_CollectionsBook:UpdateCategoryStatusIcon(categoryNode)
    local categoryData = categoryNode.data
    local categoryControl = categoryNode.control

    if not categoryControl.statusIcon then
        categoryControl.statusIcon = categoryControl:GetNamedChild("StatusIcon")
    end

    categoryControl.statusIcon:ClearIcons()

    if categoryData:HasAnyNewCollectibles() then
        categoryControl.statusIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
    end

    local collectiblesData = GetCollectiblesDataFromCategory(categoryData)
    for _, collectibleData in ipairs(collectiblesData) do
        if collectibleData:IsVisualLayerShowing() then
            categoryControl.statusIcon:AddIcon(VISIBLE_ICON)
            break
        end
    end

    categoryControl.statusIcon:Show()
end

do
    local function ShouldAddCollectible(filterType, collectibleData)
        if filterType == SI_COLLECTIONS_BOOK_FILTER_SHOW_ALL then
            return true
        end

        if collectibleData:IsUnlocked() then
            if filterType == SI_COLLECTIONS_BOOK_FILTER_SHOW_UNLOCKED then
                return true
            elseif filterType == SI_COLLECTIONS_BOOK_FILTER_SHOW_USABLE then
                return collectibleData:IsValidForPlayer()
            else
                return false
            end
        else
            return filterType == SI_COLLECTIONS_BOOK_FILTER_SHOW_LOCKED
        end
    end

    function ZO_CollectionsBook:BuildContentList(categoryData)
        local gridListPanelList = self.gridListPanelList
        gridListPanelList:ClearGridList()
        self.entryDataObjectPool:ReleaseAllObjects()

        if categoryData then
            local SORTED = true
            local collectiblesData = GetCollectiblesDataFromCategory(categoryData, SORTED)

            for _, collectibleData in ipairs(collectiblesData) do
                if ShouldAddCollectible(self.categoryFilterComboBox.filterType, collectibleData) then
                    local entryData = self.entryDataObjectPool:AcquireObject()
                    entryData:SetDataSource(collectibleData)
                    local headerState = collectibleData:IsUnlocked() and COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED or COLLECTIBLE_UNLOCK_STATE_LOCKED
                    entryData.gridHeaderName = GetString("SI_COLLECTIBLEUNLOCKSTATE", headerState) 
                    gridListPanelList:AddEntry(entryData)
                end
            end
        end

        gridListPanelList:CommitGridList()
    end
end

function ZO_CollectionsBook:OnCollectionUpdated()
    self:UpdateCollectionLater()
end

function ZO_CollectionsBook:UpdateCollectionLater()
    self.refreshGroups:RefreshAll("FullUpdate")
    RefreshMainMenu()
end

function ZO_CollectionsBook:UpdateCollection()
    self:BuildCategories()
    local searchResults = COLLECTIONS_BOOK_SINGLETON:GetSearchResults()
    local foundNoMatches = searchResults and NonContiguousCount(searchResults) == 0
    self.categoryFilterComboBox:SetHidden(foundNoMatches)
    self.noMatches:SetHidden(not foundNoMatches)
    self.gridListPanelControl:SetHidden(foundNoMatches)
end

function ZO_CollectionsBook:OnCollectibleUpdated(collectibleId)
    self.refreshGroups:RefreshSingle("CollectibleUpdated", collectibleId)

    RefreshMainMenu()
end

function ZO_CollectionsBook:UpdateCollectible(collectibleId)
    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
    if internalassert(collectibleData, "CollectionsBook UpdateCollectible called with invalid id") then
        local categoryData = collectibleData:GetCategoryData()
        local categoryNode = self.categoryNodeLookupData[categoryData:GetId()]
        if categoryNode then
            self:UpdateCategoryStatus(categoryNode)

            local selectedCategoryData = self.categoryTree:GetSelectedData()
            if categoryData == selectedCategoryData  then
                local gridEntry = self:GetEntryByCollectibleId(collectibleId)
                if gridEntry then
                    local tileControl = gridEntry.dataEntry.control
                    if tileControl then
                        local data =
                        {
                            collectibleId = collectibleId,
                        }
                        tileControl.object:Layout(data)
                    end
                else
                    self:BuildContentList(categoryData)
                end
            end
        else
            self:UpdateCollection()
        end
    end
end

function ZO_CollectionsBook:OnCollectibleStatusUpdated(collectibleId)
    self.refreshGroups:RefreshSingle("CollectibleUpdated", collectibleId)
    RefreshMainMenu()
end

function ZO_CollectionsBook:OnCollectibleNewStatusCleared(collectibleId)
    self:OnCollectibleStatusUpdated(collectibleId)
end

function ZO_CollectionsBook:BrowseToCollectible(collectibleId)
    self.refreshGroups:UpdateRefreshGroups() --In case we need to rebuild the categories before we select a category

    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
    if collectibleData then
        local categoryData = collectibleData:GetCategoryData()
        if categoryData then
            if categoryData:IsDLCCategory() then
                DLC_BOOK_KEYBOARD:BrowseToCollectible(collectibleId)
            elseif categoryData:IsHousingCategory() then
                HOUSING_BOOK_KEYBOARD:BrowseToCollectible(collectibleId)
            elseif categoryData:IsOutfitStylesCategory() then
                ZO_OUTFIT_STYLES_BOOK_KEYBOARD:NavigateToCollectibleData(collectibleData)
            else
                --Select the category or subcategory of the collectible
                local categoryNode = self.categoryNodeLookupData[categoryData:GetId()]
                if categoryNode then
                    self.categoryTree:SelectNode(categoryNode)
                end

                local entryData = self:GetEntryByCollectibleId(collectibleId)
                if entryData then
                    local NO_CALLBACK = nil
                    local ANIMATE_INSTANTLY = true
                    self.gridListPanelList:ScrollDataToCenter(entryData, NO_CALLBACK, ANIMATE_INSTANTLY)
                end

                MAIN_MENU_KEYBOARD:ToggleSceneGroup("collectionsSceneGroup", "collectionsBook")
            end
        end
    end
end

function ZO_CollectionsBook:GetEntryByCollectibleId(collectibleId)
    local entries = self.entryDataObjectPool:GetActiveObjects()
    for _, entry in pairs(entries) do
        if entry:GetId() == collectibleId then
            return entry
        end
    end
    return nil
end

function ZO_CollectionsBook:UpdateCollectionVisualLayer()
    self.gridListPanelList:RefreshGridList()
    self:UpdateAllCategoryStatusIcons()
end

function ZO_CollectionsBook.GetShowRenameDialogClosure(collectibleId)
    return function() ZO_CollectionsBook.ShowRenameDialog(collectibleId) end
end

function ZO_CollectionsBook.ShowRenameDialog(collectibleId)
    if collectibleId ~= 0 then
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
        if collectibleData then
            local nickname = collectibleData:GetNickname()
            ZO_Dialogs_ShowDialog("COLLECTIONS_INVENTORY_RENAME_COLLECTIBLE", { collectibleId = collectibleId }, { initialEditText = nickname })
        end
    end
end

--[[Global functions]]--
------------------------

function ZO_CollectionsBook_OnInitialize(control)
    COLLECTIONS_BOOK = ZO_CollectionsBook:New(control)
end

function ZO_CollectionsBook_OnSearchTextChanged(editBox)
    ZO_EditDefaultText_OnTextChanged(editBox)
    COLLECTIONS_BOOK_SINGLETON:SetSearchString(editBox:GetText())
end