-------------------------
-- Tribute Patron Book --
-------------------------

ZO_TributePatronBook_Keyboard = ZO_TributePatronBook_Shared:Subclass()

local function RefreshMainMenu()
    MAIN_MENU_KEYBOARD:RefreshCategoryBar()
    MAIN_MENU_KEYBOARD:UpdateSceneGroupButtons("collectionsSceneGroup")
end

function ZO_TributePatronBook_Keyboard:Initialize(control)
    local TEMPLATE_DATA =
    {
        gridListClass = ZO_GridScrollList_Keyboard,
        headerEntryData =
        {
            entryTemplate = "ZO_TributePatron_Keyboard_Header_Template",
            height = 34,
            gridPaddingY = 10,
        },
        descriptionEntryData =
        {
            entryTemplate = "ZO_TributePatron_Keyboard_Description_Label",
            gridPaddingX = 0,
            gridPaddingY = 10,
        },
        widePatronEntryData =
        {
            entryTemplate = "ZO_TributePatronBookTile_Keyboard_Control_Wide",
            width = ZO_TRIBUTE_PATRON_BOOK_TILE_WIDE_WIDTH_KEYBOARD,
            height = ZO_TRIBUTE_PATRON_BOOK_TILE_HEIGHT_KEYBOARD,
            gridPaddingX = 10,
            gridPaddingY = 10,
        },
        patronEntryData =
        {
            entryTemplate = "ZO_TributePatronBookTile_Keyboard_Control",
            width = ZO_TRIBUTE_PATRON_BOOK_TILE_WIDTH_KEYBOARD,
            height = ZO_TRIBUTE_PATRON_BOOK_TILE_HEIGHT_KEYBOARD,
            gridPaddingX = 10,
            gridPaddingY = 10,
        },
        wideCardEntryData =
        {
            entryTemplate = "ZO_TributePatronBookCardTile_Keyboard_Control_Wide",
            width = ZO_TRIBUTE_PATRON_BOOK_TILE_WIDE_WIDTH_KEYBOARD,
            height = ZO_TRIBUTE_PATRON_BOOK_TILE_HEIGHT_KEYBOARD,
            gridPaddingX = 10,
            gridPaddingY = 10,
        },
        cardEntryData =
        {
            entryTemplate = "ZO_TributePatronBookCardTile_Keyboard_Control",
            width = ZO_TRIBUTE_PATRON_BOOK_TILE_WIDTH_KEYBOARD,
            height = ZO_TRIBUTE_PATRON_BOOK_TILE_HEIGHT_KEYBOARD,
            gridPaddingX = 10,
            gridPaddingY = 10,
        },
    }

    self.searchEditBox = control:GetNamedChild("FiltersSearchBox")

    local infoContainerControl = control:GetNamedChild("InfoContainer")
    ZO_TributePatronBook_Shared.Initialize(self, control, infoContainerControl, TEMPLATE_DATA)

    self.categoryNodeLookupData = {}

    TRIBUTE_PATRON_BOOK_SCENE = self:GetScene()
    TRIBUTE_PATRON_BOOK_FRAGMENT = self:GetFragment()
end

function ZO_TributePatronBook_Keyboard:DeferredInitialize()
    if self.hasDeferredInitialized then
        return
    end

    self.hasDeferredInitialized = true

    self:RefreshCategories()
end

function ZO_TributePatronBook_Keyboard:OnFragmentShowing()
    self:DeferredInitialize()

    if self.pendingNavigateToData then
        self:NavigateToCollectibleData(self.pendingNavigateToData)
        self.pendingNavigateToData = nil
    end

    ZO_TributePatronBook_Shared.OnFragmentShowing(self)
end

function ZO_TributePatronBook_Keyboard:AddCategory(tributePatronCategoryData, patronFilters)
    local tree = self.categoryTree

    local entryData = ZO_EntryData:New(tributePatronCategoryData)
    entryData.node = tree:AddNode("ZO_TributePatronBook_StatusIconHeader", entryData)

    for _, patronData in tributePatronCategoryData:PatronIterator(patronFilters) do
        self:AddPatron(patronData, entryData.node)
    end

    self.categoryNodeLookupData[tributePatronCategoryData:GetId()] = entryData.node
end

function ZO_TributePatronBook_Keyboard:AddPatron(tributePatronData, parentNode)
    local tree = self.categoryTree

    local entryData = ZO_EntryData:New(tributePatronData)
    entryData.node = tree:AddNode("ZO_TributePatronBook_PatronEntry", entryData, parentNode)
end

function ZO_TributePatronBook_Keyboard:NavigateToCollectibleData(collectibleData)
    if not TRIBUTE_PATRON_BOOK_SCENE:IsShowing() then
        MAIN_MENU_KEYBOARD:ToggleSceneGroup("collectionsSceneGroup", "tributePatronBook")
    end

    if TRIBUTE_PATRON_BOOK_FRAGMENT:IsShowing() then
        local patronId = collectibleData:GetReferenceId()
        local patronData = TRIBUTE_DATA_MANAGER:GetTributePatronData(patronId)
        local tributePatronCategoryData = patronData:GetCategoryData()
        local categoryNode = self.categoryNodeLookupData[tributePatronCategoryData:GetId()]
        if categoryNode then
            for _, patronNode in ipairs(categoryNode:GetChildren()) do
                local nodePatronData = patronNode:GetData():GetDataSource()
                if nodePatronData == patronData then
                    self.categoryTree:SelectNode(patronNode)
                    break
                end
            end
            self.categoriesRefreshGroup:MarkDirty("List")
        end
    else
        self.pendingNavigateToData = collectibleData
    end
end

-- Begin ZO_TributePatronBook_Shared Overrides --

function ZO_TributePatronBook_Keyboard:GetSceneName()
    return "tributePatronBook"
end

function ZO_TributePatronBook_Keyboard:InitializeControls()
    ZO_TributePatronBook_Shared.InitializeControls(self)
end

do
    local CHILD_INDENT = 76
    local CHILD_SPACING = 0

    function ZO_TributePatronBook_Keyboard:InitializeCategories()
        ZO_TributePatronBook_Shared.InitializeCategories(self)

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

        local function TreeEntryOnSelected(control, patronData, selected, reselectingDuringRebuild)
            control:SetSelected(selected)

            if selected then
                self.patronId = patronData.patronId
                self:BuildGridList()
            else
                if patronData:IsNew() then
                    ClearCollectibleNewStatus(patronData:GetPatronCollectibleId())
                    self:UpdateCategoryStatusIcon(patronData.node.parentNode)
                end
            end
        end

        local function TreeEntrySetup(node, control, entryData, open)
            control:SetSelected(false)
            control:SetText(entryData:GetFormattedName())
        end

        self.categoryTree:AddTemplate("ZO_TributePatronBook_StatusIconHeader", TreeHeaderSetup_Child, nil, nil, CHILD_INDENT, CHILD_SPACING)
        self.categoryTree:AddTemplate("ZO_TributePatronBook_PatronEntry", TreeEntrySetup, TreeEntryOnSelected)

        self.categoryTree:SetExclusive(true)
        self.categoryTree:SetOpenAnimation("ZO_TreeOpenAnimation")
    end
end

function ZO_TributePatronBook_Keyboard:InitializeGridList()
    ZO_TributePatronBook_Shared.InitializeGridList(self)

    self.setupLabel = self.gridListControl:GetNamedChild("ContainerListContentsSetupLabel")
end

function ZO_TributePatronBook_Keyboard:GetSelectedCategory()
    self.categoryTree:GetSelectedData()
end

function ZO_TributePatronBook_Keyboard:SetFiltersHidden(hidden)
    self.showLockedCheckBox:SetHidden(hidden)
end

function ZO_TributePatronBook_Keyboard:IsSearchSupported()
    return true
end

-- Do not call this directly, instead call self.categoriesRefreshGroup:MarkDirty("List")
function ZO_TributePatronBook_Keyboard:RefreshCategories()
    local selectedNode = self.categoryTree:GetSelectedNode()
    local selectedPatronId = selectedNode and selectedNode.data:GetId()
    selectedNode = nil

    self.categoryTree:Reset()
    ZO_ClearTable(self.categoryNodeLookupData)

    local categoryList = {}
    local categoryFilters = self.categoryFilters
    local patronFilters = self.patronFilters
    for _, tributePatronCategoryData in TRIBUTE_DATA_MANAGER:TributePatronCategoryIterator(categoryFilters) do
        table.insert(categoryList, tributePatronCategoryData)
    end

    local selectedCategory = self:GetSelectedCategory()
    if #categoryList == 0 then
        if not self:HasSearchFilter() then
            -- Add all categories, regardless of current filters, if no categories are visible and a search is not in progress.
            categoryFilters = nil
            for _, tributePatronCategoryData in TRIBUTE_DATA_MANAGER:TributePatronCategoryIterator() do
                table.insert(categoryList, tributePatronCategoryData)
            end
        else
            self.patronId = nil
            self:BuildGridList()
        end
    end

    for _, tributePatronCategoryData in ipairs(categoryList) do
        self:AddCategory(tributePatronCategoryData, patronFilters)

        if selectedPatronId then
            local categoryNode = self.categoryNodeLookupData[tributePatronCategoryData:GetId()]
            for _, patronNode in pairs(categoryNode.children) do
                if selectedPatronId == patronNode.data:GetId() then
                    selectedNode = patronNode
                end
            end
        end
    end

    self.categoryTree:Commit(selectedNode)

    self:UpdateAllCategoryStatusIcons()
end

function ZO_TributePatronBook_Keyboard:UpdateAllCategoryStatusIcons()
    for _, categoryNode in pairs(self.categoryNodeLookupData) do
        self:UpdateCategoryStatusIcon(categoryNode)
    end
end

function ZO_TributePatronBook_Keyboard:UpdateCategoryStatusIcon(categoryNode)
    local categoryData = categoryNode.data
    local categoryControl = categoryNode.control

    if not categoryControl.statusIcon then
        categoryControl.statusIcon = categoryControl:GetNamedChild("StatusIcon")
    end

    categoryControl.statusIcon:ClearIcons()

    if categoryData:HasAnyNewPatronCollectibles() then
        categoryControl.statusIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
    end

    for i, patronEntry in pairs(categoryData.node.children) do
        local patronStatusIcon = patronEntry.control:GetNamedChild("StatusIcon")
        patronStatusIcon:ClearIcons()

        if patronEntry.data:IsNew() then
            patronStatusIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
            patronStatusIcon:Show()

            categoryControl.statusIcon:AddIcon(VISIBLE_ICON)
        end
    end

    categoryControl.statusIcon:Show()
end

-- Do not call this directly, instead call self.categoriesRefreshGroup:MarkDirty("Visible")
function ZO_TributePatronBook_Keyboard:RefreshVisibleCategories()
    local NOT_USER_REQUESTED = false
    self.categoryTree:RefreshVisible(NOT_USER_REQUESTED)
end

-- Do not call this directly, instead call self.categoryContentRefreshGroup:MarkDirty("All")
function ZO_TributePatronBook_Keyboard:RefreshCategoryContent()
    -- TODO Tribute: Implement
end

function ZO_TributePatronBook_Keyboard:BuildGridList()
    if self.gridList then
        self.gridList:ClearGridList()
        
        if self.patronId then
            -- Pre-process starter cards
            self:SetupStarterCards()

            -- Pre-process dock cards
            self:SetupDockCards()

            -- Build Patron
            self:AddPatronEntry()

            -- Build starter card entries
            self:AddStarterCardEntries()

            -- Build description entry
            self:AddDescriptionEntry()

            -- Build card entries
            self:AddDockCardEntries()

            -- Build card upgrade entries
            self:AddCardUpgradeEntries()
        end

        self.gridList:CommitGridList()

        self.gridList:ResetToTop()
    end
end

-- End ZO_TributePatronBook_Shared Overrides --

--[[Global functions]]--
------------------------

function ZO_TributePatronBook_Keyboard_OnInitialize(control)
    TRIBUTE_PATRON_BOOK_KEYBOARD = ZO_TributePatronBook_Keyboard:New(control)
end