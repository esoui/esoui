ZO_ItemSetsBook_Keyboard = ZO_ItemSetsBook_Shared:Subclass()

local function RefreshMainMenu()
    MAIN_MENU_KEYBOARD:RefreshCategoryBar()
    MAIN_MENU_KEYBOARD:UpdateSceneGroupButtons("collectionsSceneGroup")
end

function ZO_ItemSetsBook_Keyboard:New(...)
    return ZO_ItemSetsBook_Shared.New(self, ...)
end

function ZO_ItemSetsBook_Keyboard:Initialize(control)
    ZO_ItemSetsBook_Shared.Initialize(self, control)

    self.collapsedSetIds = {}

    ITEM_SETS_BOOK_SCENE = self:GetScene()
    ITEM_SETS_BOOK_FRAGMENT = self:GetFragment()
end

function ZO_ItemSetsBook_Keyboard:AddCategory(itemSetCollectionCategoryData, parentNode, categoryFilters)
    local tree = self.categoryTree
    local nodeTemplate = nil

    -- Identify the category's template type.
    if parentNode then
        nodeTemplate = "ZO_TreeStatusLabelSubCategory"
    else
        if itemSetCollectionCategoryData:GetNumSubcategories() > 0 then
            nodeTemplate = "ZO_StatusIconHeader"
        else
            nodeTemplate = "ZO_StatusIconChildlessHeader"
        end
    end

    local entryData = ZO_EntryData:New(itemSetCollectionCategoryData)
    entryData.node = tree:AddNode(nodeTemplate, entryData, parentNode)

    for _, subcategoryData in itemSetCollectionCategoryData:SubcategoryIterator(categoryFilters) do
        self:AddCategory(subcategoryData, entryData.node, categoryFilters)
    end
end

function ZO_ItemSetsBook_Keyboard:RefreshCategoryProgress()
    local itemSetCollectionCategoryData = self:GetSelectedCategory()
    if itemSetCollectionCategoryData and not itemSetCollectionCategoryData:IsInstanceOf(ZO_ItemSetCollectionSummaryCategoryData) then
        if self:IsReconstructing() then
            self.categoryProgress:SetHidden(true)
            self.selectReconstructItemHeaderLabel:SetHidden(false)
        else
            self.selectReconstructItemHeaderLabel:SetHidden(true)
            self.categoryProgress:SetHidden(false)
            local numUnlockedPieces, numPieces = itemSetCollectionCategoryData:GetDataSource():GetNumUnlockedAndTotalPieces()
            self.categoryProgress:SetValue(numUnlockedPieces / numPieces)
            self.categoryProgressLabel:SetText(zo_strformat(SI_ITEM_SETS_BOOK_CATEGORY_PROGRESS, numUnlockedPieces, numPieces))
        end
    end
end

function ZO_ItemSetsBook_Keyboard:SetAllHeadersCollapseState(collapsed)
    if collapsed then
        for _, itemSetCollectionData in ITEM_SET_COLLECTIONS_DATA_MANAGER:ItemSetCollectionIterator() do
            self.collapsedSetIds[itemSetCollectionData:GetId()] = true
        end
    else
        ZO_ClearTable(self.collapsedSetIds)
    end

    local dataList = self.gridListPanelList:GetData()
    for _, entryData in ipairs(dataList) do
        local header = entryData.data.header
        if header then
            header.collapsed = collapsed
        end
    end
    self.gridListPanelList:RecalculateVisibleEntries()
end

function ZO_ItemSetsBook_Keyboard:OnContentHeaderMouseUp(control, button, upInside)
    if upInside then
        local headerData = control.dataEntry.data.header
        local function ToggleHeaderExpansion()
            headerData.collapsed = not headerData.collapsed
            if headerData.collapsed then
                PlaySound(SOUNDS.ITEM_SET_COLLAPSED)
                self.collapsedSetIds[headerData:GetId()] = true
            else
                PlaySound(SOUNDS.ITEM_SET_EXPANDED)
                self.collapsedSetIds[headerData:GetId()] = nil
            end
            self.gridListPanelList:RecalculateVisibleEntries()
        end

        if button == MOUSE_BUTTON_INDEX_LEFT then
            ToggleHeaderExpansion()
        elseif button == MOUSE_BUTTON_INDEX_RIGHT then
            ClearMenu()

            if headerData.collapsed then
                AddMenuItem(GetString(SI_ITEM_SETS_BOOK_HEADER_EXPAND), ToggleHeaderExpansion)
            else
                AddMenuItem(GetString(SI_ITEM_SETS_BOOK_HEADER_COLLAPSE), ToggleHeaderExpansion)
            end

            AddMenuItem(GetString(SI_ITEM_SETS_BOOK_HEADER_EXPAND_ALL), function() self:SetAllHeadersCollapseState(false) end)
            AddMenuItem(GetString(SI_ITEM_SETS_BOOK_HEADER_COLLAPSE_ALL), function() self:SetAllHeadersCollapseState(true) end)

            ShowMenu(control)
        end
    end
end

function ZO_ItemSetsBook_Keyboard:OnContentHeaderMouseEnter(control)
    local headerData = control.dataEntry.data.header

    ClearTooltip(ItemTooltip)
    InitializeTooltip(ItemTooltip, control, RIGHT, -5, 0, LEFT)
    ItemTooltip:SetGenericItemSet(headerData:GetId())
end

function ZO_ItemSetsBook_Keyboard:OnContentHeaderMouseExit(control)
    ClearTooltip(ItemTooltip)
end

function ZO_ItemSetsBook_Keyboard:NavigateToItemSetCollectionCategoryData(itemSetCollectionCategoryData)
    if itemSetCollectionCategoryData then
        if not self:GetScene():IsShowing() then
            MAIN_MENU_KEYBOARD:ToggleSceneGroup("collectionsSceneGroup", self:GetSceneName())
        end

        local treeNode = self.categoryTree:GetTreeNodeByData(itemSetCollectionCategoryData)
        if treeNode then
            local OPEN = true
            local USER_REQUESTED = true
            self.categoryTree:SetNodeOpen(treeNode, OPEN, USER_REQUESTED)
        end
    end
end

function ZO_ItemSetsBook_Keyboard:NavigateToItemSetCollectionData(itemSetCollectionData)
    if not self:GetScene():IsShowing() then
        MAIN_MENU_KEYBOARD:ToggleSceneGroup("collectionsSceneGroup", self:GetSceneName())
    end
    -- TODO: Implement
end

function ZO_ItemSetsBook_Keyboard:SaveDropdownEquipmentFilterTypes()
    local equipmentFilterTypes = {}
    local apparelFilterTypesDropdown = self.apparelFilterTypesDropdown
    local weaponFilterTypesDropdown = self.weaponFilterTypesDropdown

    for _, item in ipairs(apparelFilterTypesDropdown:GetItems()) do
        if apparelFilterTypesDropdown:IsItemSelected(item) then
            table.insert(equipmentFilterTypes, item.equipmentFilterType)
        end
    end

    for _, item in ipairs(weaponFilterTypesDropdown:GetItems()) do
        if weaponFilterTypesDropdown:IsItemSelected(item) then
            table.insert(equipmentFilterTypes, item.equipmentFilterType)
        end
    end

    ITEM_SET_COLLECTIONS_DATA_MANAGER:SetEquipmentFilterTypes(equipmentFilterTypes)
end

-- Begin ZO_ItemSetsBook_Shared Overrides --

function ZO_ItemSetsBook_Keyboard:GetSceneName()
    return "itemSetsBook"
end

function ZO_ItemSetsBook_Keyboard:InitializeControls()
    ZO_ItemSetsBook_Shared.InitializeControls(self)

    local control = self.control

    local function BuildFilterTypesDropdown(control, noSelectionStringId, multiSelectionFormatterStringId, equipmentFilterTypes)
        local dropdown = ZO_ComboBox_ObjectFromContainer(control)
        dropdown:SetSortsItems(false)

        local function OnDropdownHidden()
            self:SaveDropdownEquipmentFilterTypes()
        end

        dropdown:ClearItems()
        dropdown:SetHideDropdownCallback(OnDropdownHidden)
        dropdown:EnableMultiSelect(multiSelectionFormatterStringId, GetString(noSelectionStringId))

        for _, equipmentFilterType in ipairs(equipmentFilterTypes) do
            local equipmentFilterTypeEntry = dropdown:CreateItemEntry(GetString("SI_EQUIPMENTFILTERTYPE", equipmentFilterType))
            equipmentFilterTypeEntry.equipmentFilterType = equipmentFilterType
            dropdown:AddItem(equipmentFilterTypeEntry)
        end

        return dropdown
    end

    local filtersContainer = control:GetNamedChild("Filters")
    self.contentSearchEditBox = filtersContainer:GetNamedChild("SearchBox")
    self.showLockedCheckBox = filtersContainer:GetNamedChild("ShowLocked")
    self.apparelFilterTypesControl = filtersContainer:GetNamedChild("ApparelFilterTypes")
    self.apparelFilterTypesDropdown = BuildFilterTypesDropdown(self.apparelFilterTypesControl, SI_ITEM_SETS_BOOK_APPAREL_TYPES_DROPDOWN_TEXT_DEFAULT, SI_ITEM_SETS_BOOK_APPAREL_TYPES_DROPDOWN_TEXT, ZO_ItemSetCollectionsDataManager.GetApparelFilterTypes())
    self.weaponFilterTypesControl = filtersContainer:GetNamedChild("WeaponFilterTypes")
    self.weaponFilterTypesDropdown = BuildFilterTypesDropdown(self.weaponFilterTypesControl, SI_ITEM_SETS_BOOK_WEAPON_TYPES_DROPDOWN_TEXT_DEFAULT, SI_ITEM_SETS_BOOK_WEAPON_TYPES_DROPDOWN_TEXT, ZO_ItemSetCollectionsDataManager.GetWeaponFilterTypes())
    self.filtersContainer = filtersContainer

    self.categories = control:GetNamedChild("Categories")
    self.categoryContentContainer = control:GetNamedChild("CategoryContent")
    self.selectReconstructItemHeaderLabel = self.categoryContentContainer:GetNamedChild("SelectReconstructItemHeader")
    self.categoryProgress = self.categoryContentContainer:GetNamedChild("CategoryProgress")
    self.categoryProgressLabel = self.categoryProgress:GetNamedChild("Progress")
    ZO_StatusBar_SetGradientColor(self.categoryProgress, ZO_XP_BAR_GRADIENT_COLORS)
    self.gridListPanelControl = self.categoryContentContainer:GetNamedChild("List")
    self.noMatchesLabel = control:GetNamedChild("NoMatchMessage")

    self.summaryContainer = control:GetNamedChild("Summary")
    local function UpdateSummary()
        self.summaryRefreshGroup:UpdateRefreshGroups()
    end
    self.summaryContainer:SetHandler("OnUpdate", UpdateSummary)
    self.summaryContentContainer = self.summaryContainer:GetNamedChild("Content")
    self.summaryScrollChild = self.summaryContentContainer:GetNamedChild("ScrollChild")

    local function UpdateShowLockedAndRefresh(button, checked)
        ITEM_SET_COLLECTIONS_DATA_MANAGER:SetShowLocked(checked)
    end
    ZO_CheckButton_SetToggleFunction(self.showLockedCheckBox, UpdateShowLockedAndRefresh)
    ZO_CheckButton_SetLabelText(self.showLockedCheckBox, GetString(SI_ITEM_SETS_BOOK_SHOW_LOCKED))
end

function ZO_ItemSetsBook_Keyboard:InitializeCategories()
    ZO_ItemSetsBook_Shared.InitializeCategories(self)

    local categoryTree = ZO_Tree:New(self.categories:GetNamedChild("ScrollChild"), 60, -10, 300)

    local function UpdateCategoryStatusIcon(control, categoryData)
        if not control.statusIcon then
            control.statusIcon = control:GetNamedChild("StatusIcon")
        end

        control.statusIcon:ClearIcons()

        if categoryData:HasAnyNewPieces() then
            control.statusIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
        end

        control.statusIcon:Show()
    end

    local function BaseTreeHeaderIconSetup(control, categoryData, open)
        local normalIcon, pressedIcon, mouseoverIcon = categoryData:GetKeyboardIcons()
        control.icon:SetTexture(open and pressedIcon or normalIcon)
        control.iconHighlight:SetTexture(mouseoverIcon)
        ZO_IconHeader_Setup(control, open, enabled)
        UpdateCategoryStatusIcon(control, categoryData)
    end

    local function BaseTreeHeaderSetup(node, control, categoryData, open)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(categoryData:GetFormattedName())
        BaseTreeHeaderIconSetup(control, categoryData, open)
    end

    local function TreeHeaderSetup_Child(node, control, categoryData, open, userRequested)
        BaseTreeHeaderSetup(node, control, categoryData, open)

        if open and userRequested then
            categoryTree:SelectFirstChild(node)
        end
    end

    local function TreeHeaderSetup_Childless(node, control, categoryData, open)
        BaseTreeHeaderSetup(node, control, categoryData, open)
    end

    local function TreeEntryOnSelected(control, categoryData, selected, reselectingDuringRebuild)
        control:SetSelected(selected)

        if selected then
            self.categoryContentRefreshGroup:MarkDirty("All")
        end
    end

    local function TreeEntryOnSelected_Childless(control, categoryData, selected, reselectingDuringRebuild)
        TreeEntryOnSelected(control, categoryData, selected, reselectingDuringRebuild)
        BaseTreeHeaderIconSetup(control, categoryData, selected)
    end

    local function TreeEntrySetup(node, control, categoryData, open)
        control:SetSelected(node.selected)
        control:SetText(categoryData:GetFormattedName())
        UpdateCategoryStatusIcon(control, categoryData)
    end

    local function EqualityFunction(leftData, rightData)
        return leftData:GetId() == rightData:GetId()
    end

    local CHILD_INDENT = 76
    local CHILD_SPACING = 0
    local NO_SELECTED_CALLBACK = nil
    categoryTree:AddTemplate("ZO_StatusIconHeader", TreeHeaderSetup_Child, NO_SELECTED_CALLBACK, EqualityFunction, CHILD_INDENT, CHILD_SPACING)
    categoryTree:AddTemplate("ZO_StatusIconChildlessHeader", TreeHeaderSetup_Childless, TreeEntryOnSelected_Childless, EqualityFunction)
    categoryTree:AddTemplate("ZO_TreeStatusLabelSubCategory", TreeEntrySetup, TreeEntryOnSelected, EqualityFunction)

    categoryTree:SetExclusive(true)
    categoryTree:SetOpenAnimation("ZO_TreeOpenAnimation")
    self.categoryTree = categoryTree
end

function ZO_ItemSetsBook_Keyboard:InitializeGridList()
    ZO_ItemSetsBook_Shared.InitializeGridList(self, ZO_SingleTemplateGridScrollList_Keyboard)

    local gridListPanelList = self.gridListPanelList
    self.entryDataObjectPool = ZO_EntryDataPool:New(ZO_EntryData)

    local HIDE_CALLBACK = nil
    local CENTER_ENTRIES = true
    local HEADER_HEIGHT = 60
    local TILE_GRID_PADDING = 5
    gridListPanelList:SetGridEntryTemplate("ZO_ItemSetCollectionPieceTile_Keyboard_Control", ZO_ITEM_SET_COLLECTION_PIECE_TILE_KEYBOARD_DIMENSIONS, ZO_ITEM_SET_COLLECTION_PIECE_TILE_KEYBOARD_DIMENSIONS, ZO_DefaultGridTileEntrySetup, HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, TILE_GRID_PADDING, TILE_GRID_PADDING, CENTER_ENTRIES)

    local function IsTileVisible(data)
        return not data.gridHeaderData.collapsed
    end
    gridListPanelList:SetGridEntryVisibilityFunction(IsTileVisible) -- Note: Order matters. This must be called after SetGridEntryTemplate

    local function HeaderSetup(...)
        self:SetupGridHeaderEntry(...)
    end
    gridListPanelList:SetHeaderTemplate("ZO_ItemSetsBook_Entry_Header_Keyboard", HEADER_HEIGHT, HeaderSetup)
    gridListPanelList:SetHeaderPrePadding(TILE_GRID_PADDING * 2)
end

function ZO_ItemSetsBook_Keyboard:InitializeSummaryCategoryContent()
    if not self.summaryCategoryControls then
        self.summaryCategoryControls = {}

        local totalControl = self.summaryScrollChild:GetNamedChild("Total")
        local previousLeftControl, previousRightControl = totalControl, totalControl
        local index = 0
        for _, categoryData in ITEM_SET_COLLECTIONS_DATA_MANAGER:TopLevelItemSetCollectionCategoryIterator() do
            local categoryId = categoryData:GetId()
            local categoryControl = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)Category", self.summaryScrollChild, "ZO_ItemSetsBook_SummaryEntry_Header_Keyboard", tostring(categoryId))

            self.summaryCategoryControls[categoryData] = categoryControl
            categoryControl.categoryData = categoryData
            categoryControl.nameLabel:SetText(categoryData:GetFormattedName())

            if index % 2 == 0 then
                categoryControl:SetAnchor(TOPLEFT, previousLeftControl, BOTTOMLEFT)
                if previousLeftControl == totalControl then
                    categoryControl:SetAnchor(TOPRIGHT, previousLeftControl, BOTTOM, -10)
                else
                    categoryControl:SetAnchor(TOPRIGHT, previousLeftControl, BOTTOMRIGHT)
                end

                previousLeftControl = categoryControl
            else
                if previousRightControl == totalControl then
                    categoryControl:SetAnchor(TOPLEFT, previousRightControl, BOTTOM, 10)
                else
                    categoryControl:SetAnchor(TOPLEFT, previousRightControl, BOTTOMLEFT)
                end
                categoryControl:SetAnchor(TOPRIGHT, previousRightControl, BOTTOMRIGHT)

                previousRightControl = categoryControl
            end

            index = index + 1
        end
    end
end

function ZO_ItemSetsBook_Keyboard:OnItemSetCollectionsUpdated(...)
    ZO_ItemSetsBook_Shared.OnItemSetCollectionsUpdated(self, ...)

    RefreshMainMenu()
end

function ZO_ItemSetsBook_Keyboard:RefreshCategoryNewStatus(...)
    ZO_ItemSetsBook_Shared.RefreshCategoryNewStatus(self, ...)

    RefreshMainMenu()
end

function ZO_ItemSetsBook_Keyboard:SetupGridHeaderEntry(control, data, selected)
    ZO_ItemSetsBook_Shared.SetupGridHeaderEntry(self, control, data, selected)

    if data.header.collapsed then
        ZO_ToggleButton_SetState(control.expandedStateButton, TOGGLE_BUTTON_CLOSED)
    else
        ZO_ToggleButton_SetState(control.expandedStateButton, TOGGLE_BUTTON_OPEN)
    end
end

function ZO_ItemSetsBook_Keyboard:OnEquipmentFilterTypesChanged(equipmentFilterTypes)
    ZO_ItemSetsBook_Shared.OnEquipmentFilterTypesChanged(self)

    local apparelFilterTypesDropdown = self.apparelFilterTypesDropdown
    apparelFilterTypesDropdown:ClearAllSelections()
    local weaponFilterTypesDropdown = self.weaponFilterTypesDropdown
    weaponFilterTypesDropdown:ClearAllSelections()
    local IGNORE_CALLBACKS = true
    for _, item in ipairs(apparelFilterTypesDropdown:GetItems()) do
        if ZO_IsElementInNumericallyIndexedTable(equipmentFilterTypes, item.equipmentFilterType) then
            apparelFilterTypesDropdown:SelectItem(item, IGNORE_CALLBACKS)
        end
    end

    for _, item in ipairs(weaponFilterTypesDropdown:GetItems()) do
        if ZO_IsElementInNumericallyIndexedTable(equipmentFilterTypes, item.equipmentFilterType) then
            weaponFilterTypesDropdown:SelectItem(item, IGNORE_CALLBACKS)
        end
    end
end

function ZO_ItemSetsBook_Keyboard:OnShowLockedOptionUpdated()
    ZO_ItemSetsBook_Shared.OnShowLockedOptionUpdated(self)

    ZO_CheckButton_SetCheckState(self.showLockedCheckBox, ITEM_SET_COLLECTIONS_DATA_MANAGER:GetShowLocked())
end

function ZO_ItemSetsBook_Keyboard:GetSelectedCategory()
    return self.categoryTree:GetSelectedData()
end

function ZO_ItemSetsBook_Keyboard:GetGridEntryDataObjectPool()
    return self.entryDataObjectPool
end

function ZO_ItemSetsBook_Keyboard:GetGridHeaderEntryDataObjectPool()
    return self.entryDataObjectPool
end

function ZO_ItemSetsBook_Keyboard:SetFiltersHidden(hidden)
    self.apparelFilterTypesControl:SetHidden(hidden)
    self.weaponFilterTypesControl:SetHidden(hidden)
    self.showLockedCheckBox:SetHidden(hidden)
end

function ZO_ItemSetsBook_Keyboard:IsSetHeaderCollapsed(itemSetId)
    return self.collapsedSetIds[itemSetId] or false
end

function ZO_ItemSetsBook_Keyboard:IsSearchSupported()
    return true
end

function ZO_ItemSetsBook_Keyboard:IsReconstructing()
    return RETRAIT_STATION_RECONSTRUCT_FRAGMENT:IsShowing()
end

-- Do not call this directly, instead call self.categoriesRefreshGroup:MarkDirty("List")
function ZO_ItemSetsBook_Keyboard:RefreshCategories()
    self.categoryTree:Reset()

    local categoryList = {}
    local categoryFilters = self.categoryFilters
    for _, topLevelCategoryData in ITEM_SET_COLLECTIONS_DATA_MANAGER:TopLevelItemSetCollectionCategoryIterator(categoryFilters) do
        table.insert(categoryList, topLevelCategoryData)
    end

    local selectedCategory = self:GetSelectedCategory()
    if #categoryList == 0 and not ITEM_SET_COLLECTIONS_DATA_MANAGER:HasSearchFilter() then
        -- Add all categories, regardless of current filters, if no categories are visible and a search is not in progress.
        categoryFilters = nil
        for _, topLevelCategoryData in ITEM_SET_COLLECTIONS_DATA_MANAGER:TopLevelItemSetCollectionCategoryIterator() do
            table.insert(categoryList, topLevelCategoryData)
        end
    end

    if not self:IsReconstructing() then
        -- Insert the special Summary category.
        table.insert(categoryList, 1, ITEM_SET_COLLECTIONS_SUMMARY_CATEGORY_DATA)
    end

    local EMPTY_PARENT_NODE = nil
    for _, topLevelCategoryData in ipairs(categoryList) do
        self:AddCategory(topLevelCategoryData, EMPTY_PARENT_NODE, categoryFilters)
    end

    self.categoryTree:Commit()

    if not selectedCategory then
        -- If no category is selected, that likely means the search had no results, so there won't be a typical selection event, so manually refresh the content.
        self.categoryContentRefreshGroup:MarkDirty("All")
    end
end

-- Do not call this directly, instead call self.categoriesRefreshGroup:MarkDirty("Visible")
function ZO_ItemSetsBook_Keyboard:RefreshVisibleCategories()
    local NOT_USER_REQUESTED = false
    self.categoryTree:RefreshVisible(NOT_USER_REQUESTED)
end

-- Do not call this directly, instead call self.categoryContentRefreshGroup:MarkDirty("All")
function ZO_ItemSetsBook_Keyboard:RefreshCategoryContent()
    local itemSetCollectionCategoryData = self:GetSelectedCategory()
    if itemSetCollectionCategoryData then
        if itemSetCollectionCategoryData:IsInstanceOf(ZO_ItemSetCollectionSummaryCategoryData) then
            -- Summary category
            self:SetFiltersHidden(true)
            self.categoryContentContainer:SetHidden(true)
            self.noMatchesLabel:SetHidden(true)
            self.summaryContainer:SetHidden(false)
            self.summaryRefreshGroup:UpdateRefreshGroups()
        else
            -- Standard category
            self:SetFiltersHidden(false)
            self.categoryContentContainer:SetHidden(false)
            self.summaryContainer:SetHidden(true)
            self:RefreshCategoryProgress()
            self:RefreshCategoryContentList()
        end
    else
        -- No category
        self.categoryContentContainer:SetHidden(true)
        self.summaryContainer:SetHidden(true)
        self.noMatchesLabel:SetHidden(false)
    end
end

-- Do not call this directly, instead call self.summaryRefreshGroup:MarkDirty("FullUpdate")
function ZO_ItemSetsBook_Keyboard:RefreshSummaryCategoryContent()
    self:InitializeSummaryCategoryContent()

    local sumUnlockedPieces, sumTotalPieces = 0, 0
    for _, categoryData in ITEM_SET_COLLECTIONS_DATA_MANAGER:TopLevelItemSetCollectionCategoryIterator() do
        local categoryControl = self.summaryCategoryControls[categoryData]
        if categoryControl then
            local unlockedPieces, totalPieces = categoryData:GetNumUnlockedAndTotalPieces()
            local progressText = zo_strformat(SI_ITEM_SETS_BOOK_CATEGORY_PROGRESS, ZO_CommaDelimitNumber(unlockedPieces), ZO_CommaDelimitNumber(totalPieces))

            categoryControl.progressBar:SetValue(unlockedPieces / totalPieces)
            categoryControl.progressBar.progress:SetText(progressText)
            sumUnlockedPieces = sumUnlockedPieces + unlockedPieces
            sumTotalPieces = sumTotalPieces + totalPieces
        end
    end

    local sumProgressText = zo_strformat(SI_ITEM_SETS_BOOK_CATEGORY_PROGRESS, ZO_CommaDelimitNumber(sumUnlockedPieces), ZO_CommaDelimitNumber(sumTotalPieces))
    local totalControl = self.summaryScrollChild:GetNamedChild("Total")
    totalControl.progressBar:SetValue(sumUnlockedPieces / sumTotalPieces)
    totalControl.progressBar.progress:SetText(sumProgressText)
end

-- Do not call this directly, instead call self.categoryContentRefreshGroup:MarkDirty("List")
function ZO_ItemSetsBook_Keyboard:RefreshCategoryContentList()
    ZO_ItemSetsBook_Shared.RefreshCategoryContentList(self)

    self.noMatchesLabel:SetHidden(self.gridListPanelList:HasEntries())
end

-- Do not call this directly, instead call self.categoryContentRefreshGroup:MarkDirty("Visible")
function ZO_ItemSetsBook_Keyboard:RefreshVisibleCategoryContent()
    ZO_ItemSetsBook_Shared.RefreshVisibleCategoryContent(self)

    self:RefreshCategoryProgress()
end

-- End ZO_ItemSetsBook_Shared Overrides --

--[[Global functions]]--
------------------------

function ZO_ItemSetsBook_Keyboard_OnSearchTextChanged(editBox)
    ITEM_SET_COLLECTIONS_DATA_MANAGER:SetSearchString(editBox:GetText())
end

function ZO_ItemSetsBook_Keyboard_OnInitialize(control)
    ITEM_SET_COLLECTIONS_BOOK_KEYBOARD = ZO_ItemSetsBook_Keyboard:New(control)
end

function ZO_ItemSetsBook_Entry_Header_Keyboard_OnInitialize(control)
    control.expandedStateButton = control:GetNamedChild("ExpandedState")
    control.progressBar.gloss = control.progressBar:GetNamedChild("Gloss")
    ZO_StatusBar_SetGradientColor(control.progressBar, ZO_XP_BAR_GRADIENT_COLORS)
end

function ZO_ItemSetsBook_Entry_Header_Keyboard_OnMouseUp(control, button, upInside)
    ITEM_SET_COLLECTIONS_BOOK_KEYBOARD:OnContentHeaderMouseUp(control, button, upInside)
end

function ZO_ItemSetsBook_Entry_Header_Keyboard_OnMouseEnter(control)
    ITEM_SET_COLLECTIONS_BOOK_KEYBOARD:OnContentHeaderMouseEnter(control)
end

function ZO_ItemSetsBook_Entry_Header_Keyboard_OnMouseExit(control)
    ITEM_SET_COLLECTIONS_BOOK_KEYBOARD:OnContentHeaderMouseExit(control)
end

function ZO_ItemSetsBook_SummaryEntry_Header_Keyboard_OnInitialize(control)
    control.progressBar.gloss = control.progressBar:GetNamedChild("Gloss")
    control.progressBar.progress = control.progressBar:GetNamedChild("Progress")
    ZO_StatusBar_SetGradientColor(control.progressBar, ZO_XP_BAR_GRADIENT_COLORS)
end

function ZO_ItemSetsBook_SummaryEntry_Header_Keyboard_OnMouseUp(control, button, upInside)
    if control.categoryData then
        ITEM_SET_COLLECTIONS_BOOK_KEYBOARD:NavigateToItemSetCollectionCategoryData(control.categoryData)
    end
end

function ZO_ItemSetsBook_SummaryEntry_Header_Keyboard_OnMouseEnter(control)
    if control.categoryData then
        control.nameLabel:SetColor(ZO_HIGHLIGHT_TEXT:UnpackRGBA())
        ZO_ResponsiveArrowBar_OnMouseEnter(control.progressBar)
    end
end

function ZO_ItemSetsBook_SummaryEntry_Header_Keyboard_OnMouseExit(control)
    if control.categoryData then
        control.nameLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        ZO_ResponsiveArrowBar_OnMouseExit(control.progressBar)
    end
end