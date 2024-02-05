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
    self:InitializeWheel()
    self:InitializeEvents()
    self:InitializeCategories()
    self:InitializeFilters()
    self:InitializeGridListPanel()
    self:InitializeKeybindStripDescriptors()

    local function OnRefreshActionsCallback()
        local categoryData = self.categoryTree:GetSelectedData()
        if categoryData then
            self:UpdateUtilityWheel(categoryData)
        end
        self:UpdateKeybinds()
    end

    self.control:SetHandler("OnUpdate", function() self.refreshGroups:UpdateRefreshGroups() end)

    self.scene = ZO_Scene:New("collectionsBook", SCENE_MANAGER)
    self.scene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self.refreshGroups:UpdateRefreshGroups() --In case we need to rebuild the categories
            ITEM_PREVIEW_KEYBOARD:RegisterCallback("RefreshActions", OnRefreshActionsCallback)
            self:UpdateCollectionVisualLayer()
            if self.hotbarCategory and not IsCurrentlyPreviewing() then
                self.wheelContainer:SetHidden(false)
                self.wheel:Activate()
            else
                self.wheelContainer:SetHidden(true)
            end
            COLLECTIONS_BOOK_SINGLETON:SetSearchString(self.contentSearchEditBox:GetText())
            COLLECTIONS_BOOK_SINGLETON:SetSearchCategorySpecializationFilters(COLLECTIBLE_CATEGORY_SPECIALIZATION_NONE)
            COLLECTIONS_BOOK_SINGLETON:SetSearchChecksHidden(true)
            self:AddKeybinds()
        elseif newState == SCENE_HIDING then
            if IsCurrentlyPreviewing() then
                ITEM_PREVIEW_KEYBOARD:EndCurrentPreview()
            end
        elseif newState == SCENE_HIDDEN then
            ITEM_PREVIEW_KEYBOARD:UnregisterCallback("RefreshActions", OnRefreshActionsCallback)
            self.gridListPanelList:ResetToTop()
            self.wheelContainer:SetHidden(true)
            if self.hotbarCategory then
                self.wheel:Deactivate()
            end
            self:RemoveKeybinds()
        end
    end)

    self:UpdateCollectionLater()

    SYSTEMS:RegisterKeyboardObject(ZO_COLLECTIONS_SYSTEM_NAME, self)
end

function ZO_CollectionsBook:InitializeControls()
    self.categoryFilterComboBox = self.control:GetNamedChild("Filter")
    self.contentSearchEditBox = self.control:GetNamedChild("SearchBox")
    self.noMatches = self.control:GetNamedChild("NoMatchMessage")
end

function ZO_CollectionsBook:InitializeWheel()
    self.wheelContainer = self.control:GetNamedChild("WheelContainer")
    self.wheelControl = self.wheelContainer:GetNamedChild("UtilityWheel")
    local wheelData =
    {
        hotbarCategories = { HOTBAR_CATEGORY_QUICKSLOT_WHEEL },
        numSlots = ACTION_BAR_UTILITY_BAR_SIZE,
        includeHiddenState = true,
        showCategoryLabel = true,
        --Display the accessibility keybinds on the wheel if the setting is enabled
        showKeybinds = ZO_AreTogglableWheelsEnabled,
    }
    self.wheel = ZO_AssignableUtilityWheel_Keyboard:New(self.wheelControl, wheelData)
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
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUserFlagsUpdated", function(...) self:OnCollectibleUserFlagsUpdated(...) end)

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

            if open and userRequested then
                self.categoryTree:SelectFirstChild(node)
            end
        end

        local function TreeHeaderSetup_Childless(node, control, categoryData, open)
            BaseTreeHeaderSetup(node, control, categoryData, open)
        end

        local function TreeEntryOnSelected(control, categoryData, selected, reselectingDuringRebuild)
            ITEM_PREVIEW_KEYBOARD:EndCurrentPreview()

            control:SetSelected(selected)

            if selected then
                self:UpdateUtilityWheel(categoryData)
                self:BuildContentList(categoryData)
            end

            self:UpdateKeybinds()
        end

        local function TreeEntryOnSelected_Childless(control, categoryData, selected, reselectingDuringRebuild)
            TreeEntryOnSelected(control, categoryData, selected, reselectingDuringRebuild)
            BaseTreeHeaderIconSetup(control, categoryData, selected)
        end

        local function TreeEntrySetup(node, control, categoryData, open)
            control:SetSelected(false)
            control:SetText(categoryData:GetFormattedName())
        end

        self.categoryTree:AddTemplate("ZO_CollectionsBook_StatusIconHeader", TreeHeaderSetup_Child, nil, nil, CHILD_INDENT, CHILD_SPACING)
        self.categoryTree:AddTemplate("ZO_CollectionsBook_StatusIconChildlessHeader", TreeHeaderSetup_Childless, TreeEntryOnSelected_Childless)
        self.categoryTree:AddTemplate("ZO_CollectionsBook_SubCategory", TreeEntrySetup, TreeEntryOnSelected)

        self.categoryTree:SetExclusive(true)
        self.categoryTree:SetOpenAnimation("ZO_TreeOpenAnimation")
    end
end

function ZO_CollectionsBook:InitializeGridListPanel()
    self.entryDataObjectPool = ZO_EntryDataPool:New(ZO_GridSquareEntryData_Shared)

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

function ZO_CollectionsBook:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Cancel Any Previews
        {
            name = GetString(SI_COLLECTIBLE_ACTION_END_PREVIEW),
            keybind = "UI_SHORTCUT_NEGATIVE",
            visible = function()
                return IsCurrentlyPreviewing()
            end,
            callback = function()
                ITEM_PREVIEW_KEYBOARD:EndCurrentPreview()
                local categoryData = self.categoryTree:GetSelectedData()
                if categoryData then
                    self:UpdateUtilityWheel(categoryData)
                end
                self:UpdateKeybinds()
            end,
        },
    }
end

function ZO_CollectionsBook:AddKeybinds()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_CollectionsBook:RemoveKeybinds()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
end


function ZO_CollectionsBook:UpdateKeybinds()
    if self.keybindStripDescriptor and self.scene:IsShowing() then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
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
            local nodeTemplate = hasChildren and "ZO_CollectionsBook_StatusIconHeader" or "ZO_CollectionsBook_StatusIconChildlessHeader"

            local parentNode = self:AddCategory(nodeTemplate, categoryData)
        
            for _, subcategoryData in categoryData:SubcategoryIterator({ZO_CollectibleCategoryData.HasShownCollectiblesInCollection}) do
                self:AddCategory("ZO_CollectionsBook_SubCategory", subcategoryData, parentNode)
            end
        else
            local categoryIndex = categoryData:GetCategoryIndicies()
            local hasChildren = NonContiguousCount(searchResults[categoryIndex]) > 1 or searchResults[categoryIndex][ZO_COLLECTIONS_SEARCH_ROOT] == nil
            local nodeTemplate = hasChildren and "ZO_CollectionsBook_StatusIconHeader" or "ZO_CollectionsBook_StatusIconChildlessHeader"

            local parentNode = self:AddCategory(nodeTemplate, categoryData)
        
            for subcategoryIndex, _ in pairs(searchResults[categoryIndex]) do
                if subcategoryIndex ~= ZO_COLLECTIONS_SEARCH_ROOT then
                    local subcategoryData = ZO_COLLECTIBLE_DATA_MANAGER:GetCategoryDataByIndicies(categoryIndex, subcategoryIndex)
                    self:AddCategory("ZO_CollectionsBook_SubCategory", subcategoryData, parentNode)
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
        if collectibleData:IsVisualLayerShowing(GAMEPLAY_ACTOR_CATEGORY_PLAYER) then
            categoryControl.statusIcon:AddIcon(VISIBLE_ICON)
            break
        end
    end

    categoryControl.statusIcon:Show()
end

function ZO_CollectionsBook:UpdateUtilityWheel(categoryData)
    if self.scene:IsShowing() then
        local hotbarCategory = GetHotbarForCollectibleCategoryId(categoryData.categoryId)
        if hotbarCategory then
            local hotbarCategories = {hotbarCategory, HOTBAR_CATEGORY_QUICKSLOT_WHEEL}
            if hotbarCategory ~= self.hotbarCategory then
                self.wheel:SetHotbarCategories(hotbarCategories)
            end
            --If the wheel is currently not showing, we need to show and activate it
            if IsCurrentlyPreviewing() then
                self.wheelContainer:SetHidden(true)
                self.wheel:Deactivate()
            else
                self.wheelContainer:SetHidden(false)
                self.wheel:Activate()
            end
        else
            self.wheelContainer:SetHidden(true)
            self.wheel:Deactivate()
        end

        self.hotbarCategory = hotbarCategory
    end
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
            elseif filterType == SI_COLLECTIONS_BOOK_FILTER_SHOW_NEW then
                return collectibleData:IsNew()
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
            local randomSelectionTilesProcessed = false

            for _, collectibleData in ipairs(collectiblesData) do
                if ShouldAddCollectible(self.categoryFilterComboBox.filterType, collectibleData) then
                    if not randomSelectionTilesProcessed then
                        local collectibleCategoryTypesInCategory = categoryData:GetCollectibleCategoryTypesInCategory()
                        if collectibleCategoryTypesInCategory[COLLECTIBLE_CATEGORY_TYPE_MOUNT] then
                            local randomMountEntryData = self.entryDataObjectPool:AcquireObject()
                            local setRandomFavoriteMountData = ZO_RandomMountCollectibleData:New(RANDOM_MOUNT_TYPE_FAVORITE)
                            randomMountEntryData:SetDataSource(setRandomFavoriteMountData)
                            randomMountEntryData.gridHeaderTemplate = ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_KEYBOARD
                            randomMountEntryData.gridHeaderName = ""
                            gridListPanelList:AddEntry(randomMountEntryData, "ZO_CollectibleImitationTile_Keyboard_Control")

                            randomMountEntryData = self.entryDataObjectPool:AcquireObject()
                            local setAnyRandomMountData = ZO_RandomMountCollectibleData:New(RANDOM_MOUNT_TYPE_ANY)
                            randomMountEntryData:SetDataSource(setAnyRandomMountData)
                            randomMountEntryData.gridHeaderTemplate = ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_KEYBOARD
                            randomMountEntryData.gridHeaderName = ""
                            gridListPanelList:AddEntry(randomMountEntryData, "ZO_CollectibleImitationTile_Keyboard_Control")
                        end

                        randomSelectionTilesProcessed = true
                    end

                    local entryData = self.entryDataObjectPool:AcquireObject()
                    entryData:SetDataSource(collectibleData)
                    entryData.gridHeaderTemplate = ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_KEYBOARD
                    if collectibleData:IsFavorite() then
                        entryData.gridHeaderName = GetString(SI_COLLECTIONS_FAVORITES_CATEGORY_HEADER)
                    else
                        local headerState = collectibleData:IsUnlocked() and COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED or COLLECTIBLE_UNLOCK_STATE_LOCKED
                        entryData.gridHeaderName = GetString("SI_COLLECTIBLEUNLOCKSTATE", headerState)
                    end
                    
                    if self.hotbarCategory then
                        entryData.utilityWheel = self.wheel
                    else
                        entryData.utilityWheel = nil
                    end
                    gridListPanelList:AddEntry(entryData, "ZO_CollectibleTile_Keyboard_Control")
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
                        if self.hotbarCategory then
                            data.utilityWheel = self.wheel
                        end
                        tileControl.object:Layout(data)
                    end
                else
                    self:BuildContentList(categoryData)
                end
            end
        else
            self:UpdateCollectionLater()
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

function ZO_CollectionsBook:OnCollectibleUserFlagsUpdated(collectibleId)
    -- Please update handling as further flags are added
    internalassert(COLLECTIBLE_USER_FLAG_MAX_VALUE == 1)
    
    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
    if collectibleData then
        local categoryData = collectibleData:GetCategoryData()
        local selectedCategoryData = self.categoryTree:GetSelectedData()
        if categoryData == selectedCategoryData  then
            self:BuildContentList(categoryData)
        end
    end
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
            elseif categoryData:IsTributePatronCategory() then
                TRIBUTE_PATRON_BOOK_KEYBOARD:NavigateToCollectibleData(collectibleData)
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
        if entry.GetId and entry:GetId() == collectibleId then
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
            local defaultNickname = collectibleData:GetDefaultNickname()
            --Only pre-fill the edit text if it's different from the default nickname
            local initialEditText = ""
            if nickname ~= defaultNickname then
                initialEditText = nickname
            end
            ZO_Dialogs_ShowDialog("COLLECTIONS_INVENTORY_RENAME_COLLECTIBLE", { collectibleId = collectibleId }, { initialEditText = initialEditText, initialDefaultText = defaultNickname})
        end
    end
end

--[[Global functions]]--
------------------------

function ZO_CollectionsBook_OnInitialize(control)
    COLLECTIONS_BOOK = ZO_CollectionsBook:New(control)
end

function ZO_CollectionsBook_OnSearchTextChanged(editBox)
    COLLECTIONS_BOOK_SINGLETON:SetSearchString(editBox:GetText())
end

function ZO_CollectibleRenameDialog_OnInitialized(control)
    ZO_Dialogs_RegisterCustomDialog("COLLECTIONS_INVENTORY_RENAME_COLLECTIBLE",
    {
        title =
        {
            text = SI_COLLECTIONS_INVENTORY_DIALOG_RENAME_COLLECTIBLE_TITLE,
        },
        mainText =
        {
            text = "",
        },
        setup = function(dialog, data, textParams)
            --Set up the rules for the edit box
            local editControl = dialog:GetNamedChild("ContentContainerEditBox")
            editControl:SetTextType(TEXT_TYPE_ALL)
            editControl:SetMaxInputChars(COLLECTIBLE_NAME_MAX_LENGTH)

            local defaultText = textParams.initialDefaultText or ""
            editControl:SetDefaultText(defaultText)

            if textParams.initialEditText then
                editControl:SetText(textParams.initialEditText)
            end

            editControl:SelectAll()
        end,
        customControl = control,
        buttons =
        {
            {
                noReleaseOnClick = true,
                control = control:GetNamedChild("KeybindsOk"),
                text = SI_OK,
                callback = function(dialog)
                    local editControl = dialog:GetNamedChild("ContentContainerEditBox")
                    local inputText = editControl:GetText()
                    if inputText then
                        local violations = { IsValidCollectibleName(inputText) }
                        if #violations == 0 then
                            local collectibleId = dialog.data.collectibleId
                            RenameCollectible(collectibleId, inputText)
                            ZO_Dialogs_ReleaseDialog("COLLECTIONS_INVENTORY_RENAME_COLLECTIBLE")
                        end
                    end
                end
            },
            {
                control = control:GetNamedChild("KeybindsCancel"),
                text = SI_DIALOG_CANCEL,
            },
            {
                control = control:GetNamedChild("KeybindsDefault"),
                text = SI_COLLECTIONS_INVENTORY_DIALOG_DEFAULT_NAME,
                keybind = "DIALOG_SECONDARY",
                noReleaseOnClick = true,
                callback = function(dialog)
                    local editControl = dialog:GetNamedChild("ContentContainerEditBox")
                    if editControl then
                        editControl:SetText("")
                    end
                end
            }
        }
    })
end