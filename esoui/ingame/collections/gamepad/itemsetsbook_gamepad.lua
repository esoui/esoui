-- Base (For collections and reconstruction) --

ZO_GAMEPAD_ITEM_SET_COLLECTION_PIECE_GRID_ENTRY_DIMENSIONS = 87

ZO_ItemSetsBook_Gamepad_Base = ZO_Object.MultiSubclass(ZO_ItemSetsBook_Shared, ZO_Gamepad_ParametricList_Screen)

function ZO_ItemSetsBook_Gamepad_Base:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_ItemSetsBook_Gamepad_Base:Initialize(control, ...)
    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW)
    ZO_ItemSetsBook_Shared.Initialize(self, control, ...)
    ZO_Gamepad_ParametricList_Screen.SetScene(self, self:GetScene())

    self:InitializeHeader()
end

function ZO_ItemSetsBook_Gamepad_Base:InitializeHeader()
    local function GetInventoryCapacity(control)
        control:SetText(zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK)))
        return true
    end

    local function GetInventoryCapacityNarration()
        return zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK))
    end

    local currencyType = CURT_CHAOTIC_CREATIA
    local currencyLocation = GetCurrencyPlayerStoredLocation(currencyType)
    local IS_ENOUGH = false
    local CURRENCY_OPTIONS =
    {
        currencyCapAmount = GetMaxPossibleCurrency(currencyType, currencyLocation),
    }

    local function GetCurrencyBalance(control)
        local currentBalance = GetCurrencyAmount(currencyType, currencyLocation)
        ZO_CurrencyControl_SetSimpleCurrency(control, currencyType, currentBalance, ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT, CURRENCY_SHOW_ALL, IS_ENOUGH, CURRENCY_OPTIONS)
        return true
    end

    local CURRENCY_NARRATION_OPTIONS = 
    {
        showCap = true,
        currencyLocation = currencyLocation,
    }
    
    local function GetCurrencyBalanceNarration()
        local currentBalance = GetCurrencyAmount(currencyType, currencyLocation)
        return ZO_Currency_FormatGamepad(currencyType, currentBalance, ZO_CURRENCY_FORMAT_AMOUNT_ICON, CURRENCY_NARRATION_OPTIONS)
    end

    local IS_PLURAL = false
    local currencyName = GetCurrencyName(currencyType, IS_PLURAL)

    self.headerData =
    {
        data1HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
        data1Text = GetInventoryCapacity,
        data1TextNarration = GetInventoryCapacityNarration,
        data2HeaderText = currencyName,
        data2Text = GetCurrencyBalance,
        data2TextNarration = GetCurrencyBalanceNarration,
    }
end

function ZO_ItemSetsBook_Gamepad_Base:RefreshHeader()
    if self.currentListDescriptor then
        self.headerData.titleText = self.currentListDescriptor.titleText
    end

    ZO_GamepadGenericHeader_RefreshData(self.header, self.headerData)
end

function ZO_ItemSetsBook_Gamepad_Base:RefreshCategoryProgress()
    local currentList = self:GetCurrentList()
    if currentList then
        local numEntries = currentList:GetNumItems()
        for entryIndex = 1, numEntries do
            local entryData = currentList:GetEntryData(entryIndex)
            local numCategoryUnlockedPieces, numCategoryPieces = entryData:GetDataSource():GetNumUnlockedAndTotalPieces()
            local MIN_PIECES = 0
            entryData:SetBarValues(MIN_PIECES, numCategoryPieces, numCategoryUnlockedPieces)
        end
    end

    local numUnlockedPieces, numPieces = 0, 0
    local categoryName
    if self:IsViewingCategories() then
        -- Summary progress
        categoryName = GetString(SI_ITEM_SETS_BOOK_TITLE)
        numUnlockedPieces, numPieces = ITEM_SET_COLLECTIONS_SUMMARY_CATEGORY_DATA:GetNumUnlockedAndTotalPieces()
    elseif self:IsViewingSubcategories() then
        local categoryData = self:GetSelectedTopLevelCategory()
        if categoryData then
            -- Category progress
            categoryName = categoryData:GetFormattedName()
            numUnlockedPieces, numPieces = categoryData:GetDataSource():GetNumUnlockedAndTotalPieces()
        end
    end

    local footerControl = ZO_ItemSetsBook_Gamepad_Footer
    footerControl.name:SetText(categoryName)
    footerControl.value:SetText(numUnlockedPieces)
    local MIN_POINTS = 0
    footerControl.progress:SetMinMax(MIN_POINTS, numPieces)
    footerControl.progress:SetValue(numUnlockedPieces)
end

function ZO_ItemSetsBook_Gamepad_Base:RefreshGridEntryMultiIcon(control, data)
    local statusControl = control.statusMultiIcon
    if statusControl == nil then
        return
    end
    statusControl:ClearIcons()

    data.isMarkedNew = not data.isEmptyCell and data:IsNew() -- So we don't need to keep calling into C to run the check
    if data.isMarkedNew then
        statusControl:AddIcon(ZO_GAMEPAD_NEW_ICON_32)
        statusControl:Show()
    end
end

function ZO_ItemSetsBook_Gamepad_Base:OnGridListSelectedDataChanged(previousData, newData)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_RIGHT_TOOLTIP)

    if previousData and previousData.isMarkedNew then
        previousData:ClearNew()
    end

    if newData and not newData.isEmptyCell then
        local HIDE_TRAIT = true
        GAMEPAD_TOOLTIPS:LayoutItemSetCollectionPieceLink(GAMEPAD_RIGHT_TOOLTIP, newData:GetItemLink(), HIDE_TRAIT)
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.gridKeybindStripDescriptor)
end

function ZO_ItemSetsBook_Gamepad_Base:BuildSubcategoryList(parentCategoryData)
    if not parentCategoryData then
        parentCategoryData = self.categoryListDescriptor.list:GetTargetData()
        if not parentCategoryData then
            internalassert(false, "Trying to view an invalid parentCategoryData")
        end
    end

    local subcategoryListDescriptor = self.subcategoryListDescriptor
    local subcategoryList = subcategoryListDescriptor.list

    subcategoryList:Clear()

    subcategoryListDescriptor.titleText = parentCategoryData:GetFormattedName()

    -- Add the category entries
    for subcategoryIndex, subcategoryData in parentCategoryData:SubcategoryIterator(self.categoryFilters) do
        local entryData = ZO_GamepadEntryData:New(subcategoryData:GetFormattedName())
        entryData:SetDataSource(subcategoryData)
        entryData:SetIconTintOnSelection(true)

        local numUnlockedPieces, numPieces = subcategoryData:GetNumUnlockedAndTotalPieces()
        local MIN_PIECES = 0
        entryData:SetBarValues(MIN_PIECES, numPieces, numUnlockedPieces)

        subcategoryList:AddEntry("ZO_ItemSetsBook_Summary_Gamepad", entryData)
    end

    subcategoryList:Commit()
    subcategoryListDescriptor.lastParentCategoryData = parentCategoryData

    KEYBIND_STRIP:UpdateKeybindButtonGroup(subcategoryListDescriptor.keybindDescriptor)
end

function ZO_ItemSetsBook_Gamepad_Base:SelectTopLevelCategory(itemSetCollectionCategoryData)
    if internalassert(itemSetCollectionCategoryData:IsTopLevel(), "Attempting to select a subcategory with the SelectTopLevelCategory function") then
        local index = self.categoryListDescriptor.list:GetIndexForData("ZO_GamepadItemEntryTemplate", itemSetCollectionCategoryData)
        if index then
            self.categoryListDescriptor.list:SetSelectedIndexWithoutAnimation(index)
        elseif self.categoryListDescriptor.list:HasEntries() then
            -- Not found, so reset to top
            self.categoryListDescriptor.list:SetDefaultIndexSelected()
        end
    end
end

function ZO_ItemSetsBook_Gamepad_Base:SelectSubcategory(itemSetCollectionCategoryData)
    if internalassert(itemSetCollectionCategoryData:IsSubcategory(), "Attempting to select a top level category with the SelectSubcategory function") then
        local index = self.subcategoryListDescriptor.list:GetIndexForData("ZO_GamepadItemEntryTemplate", itemSetCollectionCategoryData)
        if index then
            self.subcategoryListDescriptor.list:SetSelectedIndexWithoutAnimation(index)
        elseif self.subcategoryListDescriptor.list:HasEntries() then
            -- Not found, so reset to top
            self.subcategoryListDescriptor.list:SetDefaultIndexSelected()
        end
    end
end

do
    local function GetTopLevelCategoryAndSubcategory(itemSetCollectionCategoryData)
        local parentCategoryData = nil
        local subcategoryData = nil
        if itemSetCollectionCategoryData then
            parentCategoryData = itemSetCollectionCategoryData:GetParentCategoryData()
            if parentCategoryData then
                subcategoryData = itemSetCollectionCategoryData
            else
                parentCategoryData = itemSetCollectionCategoryData
            end
        end

        return parentCategoryData, subcategoryData
    end

    -- Select the given category/subcategory in the lists, but don't change which list is being viewed
    function ZO_ItemSetsBook_Gamepad_Base:SelectCategory(itemSetCollectionCategoryData)
        local parentCategoryData, subcategoryData = GetTopLevelCategoryAndSubcategory(itemSetCollectionCategoryData)

        if parentCategoryData then
            self:SelectTopLevelCategory(parentCategoryData)
        end

        if subcategoryData then
            self:BuildSubcategoryList()
            self:SelectSubcategory(subcategoryData)
        end
    end

    -- Opens up the provided category, or the current category if no itemSetCollectionCategoryData is provided.
    function ZO_ItemSetsBook_Gamepad_Base:ViewCategory(itemSetCollectionCategoryData)
        local parentCategoryData, subcategoryData = GetTopLevelCategoryAndSubcategory(itemSetCollectionCategoryData)
        if itemSetCollectionCategoryData then
            self:SelectCategory(itemSetCollectionCategoryData)
        else
            parentCategoryData = self.categoryListDescriptor.list:GetTargetData()
        end

        if parentCategoryData:HasSubcategories() then
            if not subcategoryData then
                -- SelectCategory only builds the subcategory list if it's attempting to select a specific subcategory
                self:BuildSubcategoryList()
            end
            self:ShowListDescriptor(self.subcategoryListDescriptor)
        else
            -- There are no subcategories, so simply show the category view with the category selected
            self:ShowListDescriptor(self.categoryListDescriptor)
        end
    end
end

function ZO_ItemSetsBook_Gamepad_Base:EnterGridList()
    self:DeactivateCurrentListDescriptor()
    self.gridListPanelList:Activate()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.gridKeybindStripDescriptor)
end

function ZO_ItemSetsBook_Gamepad_Base:ExitGridList()
    self.gridListPanelList:Deactivate()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.gridKeybindStripDescriptor)
    self:ActivateCurrentListDescriptor()
end

function ZO_ItemSetsBook_Gamepad_Base:ShowListDescriptor(listDescriptor)
    if self.currentListDescriptor == listDescriptor then
        return
    end

    if self.gridListPanelList:IsActive() then
        self:ExitGridList()
    end

    self:HideCurrentListDescriptor()

    self.currentListDescriptor = listDescriptor
    if listDescriptor then
        self:SetCurrentList(listDescriptor.list)
        KEYBIND_STRIP:AddKeybindButtonGroup(listDescriptor.keybindDescriptor)
        self:UpdateGridPanelVisibility()
        self:RefreshHeader()
    end

    self:RefreshCategoryProgress()
end

function ZO_ItemSetsBook_Gamepad_Base:HideCurrentListDescriptor()
    if self.currentListDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentListDescriptor.keybindDescriptor)
        self:DisableCurrentList()
        self.currentListDescriptor = nil
    end
end

function ZO_ItemSetsBook_Gamepad_Base:ActivateCurrentListDescriptor()
    if self.currentListDescriptor then
        self:ActivateCurrentList()
        KEYBIND_STRIP:AddKeybindButtonGroup(self.currentListDescriptor.keybindDescriptor)
    end
end

function ZO_ItemSetsBook_Gamepad_Base:DeactivateCurrentListDescriptor()
    if self.currentListDescriptor then
        self:DeactivateCurrentList()
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentListDescriptor.keybindDescriptor)
    end
end

function ZO_ItemSetsBook_Gamepad_Base:GetCurrentListTargetData()
    local currentList = self:GetCurrentList()
    return currentList and currentList:GetTargetData()
end

function ZO_ItemSetsBook_Gamepad_Base:IsViewingCategories()
    return self.currentListDescriptor == self.categoryListDescriptor
end

function ZO_ItemSetsBook_Gamepad_Base:IsViewingSubcategories()
    return self.currentListDescriptor == self.subcategoryListDescriptor
end

function ZO_ItemSetsBook_Gamepad_Base:UpdateGridPanelVisibility()
    local categoryData = self:GetSelectedCategory()
    local isSummaryCategory = categoryData and categoryData:IsInstanceOf(ZO_ItemSetCollectionSummaryCategoryData) or false

    if isSummaryCategory then
        self:ShowSummaryTooltip()
    else
        self:HideSummaryTooltip()
    end

    if self:IsViewingCategories() or not categoryData or isSummaryCategory then
        SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
        SCENE_MANAGER:RemoveFragment(self.gridListFragment)
    elseif categoryData:GetNumCollections() > 0 and not self:IsOptionsModeShowing() then
        self.categoryContentRefreshGroup:MarkDirty("List")

        SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
        SCENE_MANAGER:AddFragment(self.gridListFragment)
    end
end

function ZO_ItemSetsBook_Gamepad_Base:ShowSummaryTooltip()
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:LayoutItemSetCollectionSummary(GAMEPAD_LEFT_TOOLTIP)
end

function ZO_ItemSetsBook_Gamepad_Base:HideSummaryTooltip()
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
end

-- Begin ZO_ItemSetsBook_Shared Overrides --

function ZO_ItemSetsBook_Gamepad_Base:InitializeControls()
    ZO_ItemSetsBook_Shared.InitializeControls(self)

    self.gridListPanelControl = self.control:GetNamedChild("GridListPanel")
end

function ZO_ItemSetsBook_Gamepad_Base:InitializeCategories()
    ZO_ItemSetsBook_Shared.InitializeCategories(self)

    self.categoryListDescriptor =
    {
        list = self:GetMainList(),
        keybindDescriptor = self.categoryKeybindStripDescriptor,
        titleText = GetString(SI_ITEM_SETS_BOOK_TITLE),
        isCategoriesDescriptor = true,
    }

    self.subcategoryListDescriptor =
    {
        list = self:AddList("Subcategory"),
        keybindDescriptor = self.subcategoryKeybindStripDescriptor,
        -- The title text will be updated to the name of the collections category
        isCategoriesDescriptor = true,
    }
end

function ZO_ItemSetsBook_Gamepad_Base:InitializeGridList()
    ZO_ItemSetsBook_Shared.InitializeGridList(self, ZO_SingleTemplateGridScrollList_Gamepad)

    local gridListPanelList = self.gridListPanelList
    self.entryDataObjectPool = ZO_EntryDataPool:New(ZO_GridSquareEntryData_Shared)
    self.headerEntryDataObjectPool = ZO_EntryDataPool:New(ZO_EntryData)

    local function ItemSetCollectionPieceGridEntrySetup(control, data, list)
        ZO_DefaultGridEntrySetup(control, data, list)
        self:RefreshGridEntryMultiIcon(control, data)

        if data.isEmptyCell then
            control:SetAlpha(0.4)
        else
            control:SetAlpha(1)
            if control.icon then
                ZO_SetDefaultIconSilhouette(control.icon, data:IsLocked())
            end
        end
    end

    local HIDE_CALLBACK = nil
    local RESET_CONTROL_FUNC = nil
    local HEADER_HEIGHT = 70
    local SPACING_X = 6
    gridListPanelList:SetGridEntryTemplate("ZO_ItemSetCollectionPiece_GridEntry_Template_Gamepad", ZO_GAMEPAD_ITEM_SET_COLLECTION_PIECE_GRID_ENTRY_DIMENSIONS, ZO_GAMEPAD_ITEM_SET_COLLECTION_PIECE_GRID_ENTRY_DIMENSIONS, ItemSetCollectionPieceGridEntrySetup, HIDE_CALLBACK, RESET_CONTROL_FUNC, SPACING_X, ZO_GRID_SCROLL_LIST_DEFAULT_SPACING_GAMEPAD)

    local function HeaderSetup(...)
        self:SetupGridHeaderEntry(...)
    end
    gridListPanelList:SetHeaderTemplate("ZO_ItemSetsBook_Entry_Header_Gamepad", HEADER_HEIGHT, HeaderSetup)
    gridListPanelList:SetHeaderPrePadding(ZO_GRID_SCROLL_LIST_DEFAULT_SPACING_GAMEPAD)
    gridListPanelList:SetOnSelectedDataChangedCallback(function(previousData, newData) self:OnGridListSelectedDataChanged(previousData, newData) end)
    local ALWAYS_ANIMATE = true
    self.gridListFragment = ZO_FadeSceneFragment:New(self.gridListPanelControl, ALWAYS_ANIMATE)
    self.gridListFragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self.categoryContentRefreshGroup:TryClean()
        end
    end)
end

function ZO_ItemSetsBook_Gamepad_Base:IsCategoryContentRefreshGroupActive()
    if ZO_ItemSetsBook_Shared.IsCategoryContentRefreshGroupActive(self) then
        return self.gridListFragment:IsShowing()
    end
    return false
end

function ZO_ItemSetsBook_Gamepad_Base:GetSelectedCategory()
    if self.currentListDescriptor and self.currentListDescriptor.isCategoriesDescriptor then
        return self:GetCurrentListTargetData()
    end
    return nil
end

function ZO_ItemSetsBook_Gamepad_Base:GetSelectedTopLevelCategory()
    local categoryList = self.categoryListDescriptor
    if categoryList then
        return categoryList.list:GetTargetData()
    end
end

function ZO_ItemSetsBook_Gamepad_Base:GetGridEntryDataObjectPool()
    return self.entryDataObjectPool
end

function ZO_ItemSetsBook_Gamepad_Base:GetGridHeaderEntryDataObjectPool()
    return self.headerEntryDataObjectPool
end

function ZO_ItemSetsBook_Gamepad_Base:GetItemSetHeaderNarrationText(headerData)
    local narrations = {}
    --Narrate the name of the set
    table.insert(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(headerData:GetFormattedName()))

    --Narrate the percent completion of the set
    local percentage = headerData:GetNumUnlockedPieces() / headerData:GetNumPieces()
    percentage = string.format("%.2f", percentage * 100)
    table.insert(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_PROGRESS_BAR_PERCENT_FORMATTER, percentage)))

    -- API supports multiple currency options, but UI design only supports 1 for now, so hardcode to 1 for now
    local reconstructionCurrencyType, reconstructionCurrencyCost = headerData:GetReconstructionCurrencyOptionInfo(1)
    if reconstructionCurrencyCost then
        --Narrate the cost to reconstruct if applicable
        table.insert(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_ITEM_RECONSTRUCTION_COST_HEADER)))
        local formattedCost = ZO_Currency_FormatGamepad(reconstructionCurrencyType, reconstructionCurrencyCost, ZO_CURRENCY_FORMAT_AMOUNT_NAME)
        table.insert(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(formattedCost))
    end
    return narrations
end

-- Do not call this directly, instead call self.categoriesRefreshGroup:MarkDirty("List")
function ZO_ItemSetsBook_Gamepad_Base:RefreshCategories()
    local categoryList = self.categoryListDescriptor.list
    categoryList:Clear()

    local entryList = {}
    local MIN_PIECES = 0

    for _, categoryData in ITEM_SET_COLLECTIONS_DATA_MANAGER:TopLevelItemSetCollectionCategoryIterator(self.categoryFilters) do
        local categoryName = categoryData:GetFormattedName()
        local gamepadIcon = categoryData:GetGamepadIcon()
        local entryData = ZO_GamepadEntryData:New(categoryName, gamepadIcon)
        local numUnlockedPieces, numPieces = categoryData:GetNumUnlockedAndTotalPieces()
        entryData:SetBarValues(MIN_PIECES, numPieces, numUnlockedPieces)
        entryData:SetDataSource(categoryData)
        entryData:SetIconTintOnSelection(true)
        table.insert(entryList, entryData)
    end

    if not self:IsReconstructing() then
        local categoryData = ITEM_SET_COLLECTIONS_SUMMARY_CATEGORY_DATA
        local categoryName = categoryData:GetFormattedName()
        local gamepadIcon = categoryData:GetGamepadIcon()
        local entryData = ZO_GamepadEntryData:New(categoryName, gamepadIcon)
        local numUnlockedPieces, numPieces = categoryData:GetNumUnlockedAndTotalPieces()
        entryData:SetBarValues(MIN_PIECES, numPieces, numUnlockedPieces)
        entryData:SetDataSource(categoryData)
        entryData:SetIconTintOnSelection(true)
        table.insert(entryList, 1, entryData)
    end

    for _, entryData in ipairs(entryList) do
        categoryList:AddEntry("ZO_ItemSetsBook_Summary_Gamepad", entryData)
    end

    categoryList:Commit()

    if self.currentListDescriptor then
        if self:IsViewingSubcategories() then
            self:BuildSubcategoryList()
        end
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentListDescriptor.keybindDescriptor)
    end

    self:RefreshCategoryProgress()
end

-- Do not call this directly, instead call self.categoriesRefreshGroup:MarkDirty("Visible")
function ZO_ItemSetsBook_Gamepad_Base:RefreshVisibleCategories()
    self.categoryListDescriptor.list:RefreshVisible()
    self.subcategoryListDescriptor.list:RefreshVisible()
end

-- End ZO_ItemSetsBook_Shared Overrides --

-- Begin ZO_Gamepad_ParametricList_Screen Overrides --

function ZO_ItemSetsBook_Gamepad_Base:InitializeKeybindStripDescriptors()
    local FILTERS_KEYBIND =
    {
        name = GetString(SI_GAMEPAD_ITEM_SETS_BOOK_OPTIONS_KEYBIND),

        keybind = "UI_SHORTCUT_TERTIARY",

        callback = function()
            local selectedItemSetCollectionPieceData = nil
            local selectedData = self.gridListPanelList:GetSelectedData()
            if selectedData and not selectedData.isEmptyCell and self.gridListPanelList:IsActive() then
                selectedItemSetCollectionPieceData = selectedData
            end
            ZO_Dialogs_ShowGamepadDialog("GAMEPAD_ITEM_SETS_BOOK_OPTIONS_DIALOG", { selectedItemSetCollectionPieceData = selectedItemSetCollectionPieceData })
        end,
    }

    -- Category Keybind
    self.categoryKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select Category
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),

            keybind = "UI_SHORTCUT_PRIMARY",

            callback = function()
                local categoryData = self:GetSelectedCategory()
                if categoryData:GetNumSubcategories() > 0 then
                    self:ViewCategory()
                else
                    self:EnterGridList()
                end
            end,

            visible = function()
                if self.currentListDescriptor then
                    -- A category won't exist if it doesn't have subcategories or collections
                    local categoryData = self:GetSelectedCategory()
                    return categoryData ~= nil and not categoryData:IsInstanceOf(ZO_ItemSetCollectionSummaryCategoryData)
                end
                return false
            end,

            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },

        FILTERS_KEYBIND,
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.categoryKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)

    -- Subcategory Keybind
    self.subcategoryKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select Subcategory
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),

            keybind = "UI_SHORTCUT_PRIMARY",

            callback = function()
                self:EnterGridList()
            end,

            visible = function()
                local categoryData = self:GetSelectedCategory()
                return categoryData ~= nil
            end,

            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },

        FILTERS_KEYBIND,
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.subcategoryKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        self:ShowListDescriptor(self.categoryListDescriptor)
    end)

    -- Grid Keybind
    self.gridKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        FILTERS_KEYBIND,

        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_ITEM_RECONSTRUCTION_SELECT),
            callback = function()
                self:ShowReconstructOptions()
            end,
            enabled = function()
                return self:CanReconstruct()
            end,
            visible = function()
                return self:IsReconstructing()
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.gridKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:ExitGridList() end)

    self:SetListsUseTriggerKeybinds(true)
end

function ZO_ItemSetsBook_Gamepad_Base:PerformUpdate()
    -- Must be overridden
    self.dirty = false
end

function ZO_ItemSetsBook_Gamepad_Base:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)

    self:ShowListDescriptor(self.categoryListDescriptor)
end

function ZO_ItemSetsBook_Gamepad_Base:OnHide()
    ZO_Gamepad_ParametricList_Screen.OnHide(self)

    if self.gridListPanelList:IsActive() then
        self:ExitGridList()
    end
    self:HideCurrentListDescriptor()
    self:HideSummaryTooltip()
end

function ZO_ItemSetsBook_Gamepad_Base:OnTargetChanged(list, targetData, oldTargetData)
    if self.currentListDescriptor then
        if list == self:GetCurrentList() then
            self:UpdateGridPanelVisibility()
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentListDescriptor.keybindDescriptor)
        elseif targetData:IsTopLevel() and self:IsViewingSubcategories() and not self.subcategoryListDescriptor.lastParentCategoryData:Equals(targetData) then
            -- We're viewing the subcategory list but the selected category changed, so we should move back to the category list
            self:ShowListDescriptor(self.categoryListDescriptor)
        end
    end
end

function ZO_ItemSetsBook_Gamepad_Base:SetupList(list)
    local function CategoryEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)

        if data:HasAnyNewPieces() then
            control.icon:ClearIcons()
            if data:IsTopLevel() then
                control.icon:AddIcon(data:GetGamepadIcon())
            end
            control.icon:AddIcon(ZO_GAMEPAD_NEW_ICON_64)
            control.icon:Show()
        end
    end

    list:AddDataTemplateWithHeader("ZO_GamepadMenuEntryTemplate", CategoryEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate", ZO_ItemSetCollectionCategoryData.Equals)
    list:AddDataTemplate("ZO_ItemSetsBook_Summary_Gamepad", CategoryEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, ZO_ItemSetCollectionCategoryData.Equals, "Summary")
    list:SetReselectBehavior(ZO_PARAMETRIC_SCROLL_LIST_RESELECT_BEHAVIOR.MATCH_OR_RESET_TO_DEFAULT)
end

-- End ZO_Gamepad_ParametricList_Screen Overrides --

-- ItemSetsBook (Collections) --

ZO_ItemSetsBook_Gamepad = ZO_ItemSetsBook_Gamepad_Base:Subclass()

function ZO_ItemSetsBook_Gamepad:New(...)
    return ZO_ItemSetsBook_Gamepad_Base.New(self, ...)
end

function ZO_ItemSetsBook_Gamepad:Initialize(control)
    ZO_ItemSetsBook_Gamepad_Base.Initialize(self, control)

    GAMEPAD_ITEM_SETS_BOOK_SCENE = self:GetScene()
    GAMEPAD_ITEM_SETS_BOOK_FRAGMENT = self:GetFragment()
end

function ZO_ItemSetsBook_Gamepad:OnShowing()
    ZO_ItemSetsBook_Gamepad_Base.OnShowing(self)
    ZO_ItemSetsBook_Gamepad_Footer:SetHidden(false)
end

function ZO_ItemSetsBook_Gamepad:OnHide()
    ZO_ItemSetsBook_Gamepad_Base.OnHide(self)
    ZO_ItemSetsBook_Gamepad_Footer:SetHidden(true)
end

-- Begin ZO_ItemSetsBook_Shared Overrides --

function ZO_ItemSetsBook_Gamepad:GetSceneName()
    return "gamepadItemSetsBook"
end

function ZO_ItemSetsBook_Gamepad:IsReconstructing()
    return false
end

-- End ZO_ItemSetsBook_Shared Overrides --

-- Begin ZO_ItemSetsBook_Gamepad_Base Overrides --

function ZO_ItemSetsBook_Gamepad:IsReconstructing()
    return false
end

-- End ZO_ItemSetsBook_Gamepad_Base Overrides --

--[[Global functions]]--
------------------------
function ZO_ItemSetsBook_Gamepad_OnInitialized(control)
    GAMEPAD_ITEM_SETS_BOOK = ZO_ItemSetsBook_Gamepad:New(control)
end

function ZO_ItemSetsBook_Entry_Header_Gamepad_OnInitialize(control)
    control.progressBar.gloss = control.progressBar:GetNamedChild("Gloss")
    ZO_StatusBar_SetGradientColor(control.progressBar, ZO_SKILL_XP_BAR_GRADIENT_COLORS)
end

function ZO_ItemSetsBook_Gamepad_Footer_OnInitialized(control)
    control.name = control:GetNamedChild("Name")
    control.value = control:GetNamedChild("Rank")
    control.progress = control:GetNamedChild("XPBar")
end