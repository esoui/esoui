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
            gridPaddingY = 0,
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

     local infoContainerControl = control:GetNamedChild("InfoContainer")
    ZO_TributePatronBook_Shared.Initialize(self, control, infoContainerControl, TEMPLATE_DATA)

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
    ZO_TributePatronBook_Shared.OnFragmentShowing(self)
end

function ZO_TributePatronBook_Keyboard:AddCategory(tributePatronCategoryData, categoryFilters)
    local tree = self.categoryTree

    local entryData = ZO_EntryData:New(tributePatronCategoryData)
    entryData.node = tree:AddNode("ZO_TributePatronBook_StatusIconHeader", entryData)

    for _, patronData in tributePatronCategoryData:PatronIterator(categoryFilters) do
        self:AddPatron(patronData, entryData.node, categoryFilters)
    end
end

function ZO_TributePatronBook_Keyboard:AddPatron(tributePatronData, parentNode, categoryFilters)
    local tree = self.categoryTree

    local entryData = ZO_EntryData:New(tributePatronData)
    entryData.node = tree:AddNode("ZO_TributePatronBook_PatronEntry", entryData, parentNode)
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

        local function TreeEntryOnSelected(control, categoryData, selected, reselectingDuringRebuild)
            control:SetSelected(selected)

            if selected then
                self.patronId = categoryData.patronId
                self:BuildGridList()
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
    self.categoryTree:Reset()

    local categoryList = {}
    local categoryFilters = self.categoryFilters
    for _, tributePatronCategoryData in TRIBUTE_DATA_MANAGER:TributePatronCategoryIterator() do
        table.insert(categoryList, tributePatronCategoryData)
    end

    local selectedCategory = self:GetSelectedCategory()
    if #categoryList == 0 and not TRIBUTE_DATA_MANAGER:HasSearchFilter() then
        -- Add all categories, regardless of current filters, if no categories are visible and a search is not in progress.
        categoryFilters = nil
        for _, tributePatronCategoryData in TRIBUTE_DATA_MANAGER:TributePatronCategoryIterator() do
            table.insert(categoryList, tributePatronCategoryData)
        end
    end

    local function CompareCategories(category1, category2)
        return category1:GetFormattedName() < category2:GetFormattedName()
    end
    table.sort(categoryList, CompareCategories)

    for _, tributePatronCategoryData in ipairs(categoryList) do
        self:AddCategory(tributePatronCategoryData, categoryFilters)
    end

    self.categoryTree:Commit()
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

        self.gridList:CommitGridList()

        self.gridList:ResetToTop()
    end
end

-- End ZO_TributePatronBook_Shared Overrides --

--[[Global functions]]--
------------------------

function ZO_TributePatronBook_Keyboard_OnSearchTextChanged(editBox)
    ZO_EditDefaultText_OnTextChanged(editBox)
    TRIBUTE_DATA_MANAGER:SetSearchString(editBox:GetText())
end

function ZO_TributePatronBook_Keyboard_OnInitialize(control)
    TRIBUTE_PATRON_BOOK_KEYBOARD = ZO_TributePatronBook_Keyboard:New(control)
end