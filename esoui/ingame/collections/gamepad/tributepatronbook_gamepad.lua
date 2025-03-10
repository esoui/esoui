-------------------------
-- Tribute Patron Book --
-------------------------

ZO_TributePatronBook_Gamepad = ZO_Object.MultiSubclass(ZO_TributePatronBook_Shared, ZO_Gamepad_ParametricList_Search_Screen)

function ZO_TributePatronBook_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Search_Screen.New(self, ...)
end

function ZO_TributePatronBook_Gamepad:Initialize(control, ...)
    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Search_Screen.Initialize(self, BACKGROUND_LIST_FILTER_TARGET_TRIBUTE_PATRON_ID, "tributePatronTextSearch", control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW)

    local TEMPLATE_DATA =
    {
        gridListClass = ZO_GridScrollList_Gamepad,
        headerEntryData =
        {
            entryTemplate = "ZO_TributePatron_GP_Header_Template",
            height = 34,
            gridPaddingY = 10,
        },
        descriptionEntryData =
        {
            entryTemplate = "ZO_TributePatron_Gamepad_Description_Label",
            gridPaddingX = 0,
            gridPaddingY = 0,
        },
        patronEntryData =
        {
            entryTemplate = "ZO_TributePatronBookTile_Gamepad_Control",
            width = ZO_TRIBUTE_PATRON_BOOK_TILE_WIDTH_GAMEPAD,
            height = ZO_TRIBUTE_PATRON_BOOK_TILE_HEIGHT_GAMEPAD,
            gridPaddingX = 15,
            gridPaddingY = 10,
        },
        cardEntryData =
        {
            entryTemplate = "ZO_TributePatronBookCardTile_Gamepad_Control",
            width = ZO_TRIBUTE_PATRON_BOOK_TILE_WIDTH_GAMEPAD,
            height = ZO_TRIBUTE_PATRON_BOOK_TILE_HEIGHT_GAMEPAD,
            gridPaddingX = 15,
            gridPaddingY = 10,
        },
    }

    local rightPane = control:GetNamedChild("RightPane")
    local infoContainerControl = rightPane:GetNamedChild("InfoContainer")
    ZO_TributePatronBook_Shared.Initialize(self, control, infoContainerControl, TEMPLATE_DATA)
    ZO_Gamepad_ParametricList_Search_Screen.SetScene(self, self:GetScene())

    self.headerLabel = infoContainerControl:GetNamedChild("Header")

    GAMEPAD_TRIBUTE_PATRON_BOOK_SCENE = self:GetScene()
    GAMEPAD_TRIBUTE_PATRON_BOOK_FRAGMENT = self:GetFragment()

    self:InitializeHeader()
end

function ZO_TributePatronBook_Gamepad:GetSceneName()
    return "gamepadTributePatronBook"
end

function ZO_TributePatronBook_Gamepad:IsSearchSupported()
    return true
end

function ZO_TributePatronBook_Gamepad:InitializeHeader()
    self.headerData = {}
end

function ZO_TributePatronBook_Gamepad:RefreshHeader()
    if self.currentListDescriptor then
        self.headerData.titleText = self.currentListDescriptor.titleText
    end

    ZO_GamepadGenericHeader_RefreshData(self.header, self.headerData)
end

function ZO_TributePatronBook_Gamepad:ViewCategory(tributePatronCategoryData)
    local patronList = self.patronListDescriptor.list
    patronList:Clear()

    -- Search calls this function to update without setting a new category.
    if tributePatronCategoryData then
        self.patronListDescriptor.titleText = tributePatronCategoryData:GetFormattedName()
        self.patronListDescriptor.lastParentCategoryData = tributePatronCategoryData
    end

    -- Add the patron entries
    for _, patronData in self.patronListDescriptor.lastParentCategoryData:PatronIterator() do
        if TEXT_SEARCH_MANAGER:IsDataInSearchTextResults(self.searchContext, BACKGROUND_LIST_FILTER_TARGET_TRIBUTE_PATRON_ID, patronData:GetId()) then
            local entryData = ZO_GamepadEntryData:New(patronData:GetFormattedName())
            entryData:SetDataSource(patronData)
            entryData:SetIconTintOnSelection(true)

            patronList:AddEntry("ZO_GamepadSubMenuEntryTemplateWithStatus", entryData)
        end
    end

    patronList:Commit()
    if patronList:GetNumEntries() == 0 then
        self.patronId = nil
        self:BuildGridList()
    end

    self:ShowListDescriptor(self.patronListDescriptor)
end

-- Begin ZO_TributePatronBook_Shared Overrides --

function ZO_TributePatronBook_Gamepad:InitializeControls()
    ZO_TributePatronBook_Shared.InitializeControls(self)
end

function ZO_TributePatronBook_Gamepad:InitializeCategories()
    ZO_TributePatronBook_Shared.InitializeCategories(self)

    self.categoryListDescriptor =
    {
        list = self:GetMainList(),
        keybindDescriptor = self.categoryKeybindStripDescriptor,
        titleText = GetString(SI_TRIBUTE_PATRON_BOOK_TITLE),
        isCategoriesDescriptor = true,
    }

    self.patronListDescriptor =
    {
        list = self:AddList("Patrons"),
        keybindDescriptor = self.patronKeybindStripDescriptor,
        -- The title text will be updated to the name of the patron category
    }

    self.categoryListDescriptor.list:SetNoItemText(GetString(SI_TRIBUTE_PATRONS_SEARCH_RESULTS_EMPTY_TEXT))
    self.patronListDescriptor.list:SetNoItemText(GetString(SI_TRIBUTE_PATRONS_SEARCH_RESULTS_EMPTY_TEXT))


    -- Grid Keybind
    self.gridKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.gridKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:ExitGridList() end)

    self:SetListsUseTriggerKeybinds(true)
end

function ZO_TributePatronBook_Gamepad:InitializeGridList()
    ZO_TributePatronBook_Shared.InitializeGridList(self)

    local ALWAYS_ANIMATE = true
    self.gridListFragment = ZO_FadeSceneFragment:New(self.gridListPanelControl, ALWAYS_ANIMATE)

    self.setupLabel = self.gridListControl:GetNamedChild("SetupLabel")

    self.gridList:SetScrollToExtent(true)
    self.gridList:SetOnSelectedDataChangedCallback(function(...) self:OnGridSelectionChanged(...) end)
end

function ZO_TributePatronBook_Gamepad:OnGridSelectionChanged(oldSelectedData, selectedData)
    -- Deselect previous tile
    if oldSelectedData and oldSelectedData.dataEntry then
        if oldSelectedData.dataEntry.control then
            oldSelectedData.dataEntry.control.object:SetSelected(false)
        end
        oldSelectedData.isSelected = false
    end

    -- Select newly selected tile.
    if selectedData and selectedData.dataEntry then
        if selectedData.dataEntry.control then
            selectedData.dataEntry.control.object:SetSelected(true)
        end
        selectedData.isSelected = true
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    end
end

function ZO_TributePatronBook_Gamepad:GetSelectedCategory()
    if self.currentListDescriptor and self.currentListDescriptor.isCategoriesDescriptor then
        return self:GetCurrentListTargetData()
    end
    return nil
end

-- Do not call this directly, instead call self.categoriesRefreshGroup:MarkDirty("List")
function ZO_TributePatronBook_Gamepad:RefreshCategories()
    local categoryList = self.categoryListDescriptor.list
    local selectedData = self.currentListDescriptor.list:GetTargetData()
    categoryList:Clear()

    local entryList = {}

    for _, categoryData in TRIBUTE_DATA_MANAGER:TributePatronCategoryIterator(self.categoryFilters) do
        local categoryName = categoryData:GetFormattedName()
        local gamepadIcon = categoryData:GetGamepadIcon()
        local entryData = ZO_GamepadEntryData:New(categoryName, gamepadIcon)
        entryData:SetDataSource(categoryData)
        entryData:SetIconTintOnSelection(true)
        table.insert(entryList, entryData)
    end

    local isSearchInactive = not TEXT_SEARCH_MANAGER:IsActiveTextSearch(self.searchContext)
    for _, entryData in ipairs(entryList) do
        if isSearchInactive or self:IsAnyEntryInCategoryActiveInSearch(entryData) then
            categoryList:AddEntry("ZO_GamepadNewMenuEntryTemplate", entryData)

            if selectedData and selectedData:GetId() == entryData:GetId() then
                selectedData = entryData
            end
        end
    end

    categoryList:Commit()
    if categoryList:GetNumEntries() == 0 then
        -- If the current list is empty, select the search header.
        -- Otherwise the user won't be able to navigate into the search box.
        self:RequestEnterHeader()
    end

    if self.currentListDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentListDescriptor.keybindDescriptor)

        if self.currentListDescriptor == self.patronListDescriptor then
            self:ViewCategory(self.patronListDescriptor.lastParentCategoryData)
        end
    end
end

function ZO_TributePatronBook_Gamepad:IsAnyEntryInCategoryActiveInSearch(tributePatronCategoryData) 
    for _, patronData in tributePatronCategoryData:PatronIterator() do
        if TEXT_SEARCH_MANAGER:IsDataInSearchTextResults(self.searchContext, BACKGROUND_LIST_FILTER_TARGET_TRIBUTE_PATRON_ID, patronData:GetId()) then
            return true
        end
    end
    return false
end

-- Do not call this directly, instead call self.categoriesRefreshGroup:MarkDirty("Visible")
function ZO_TributePatronBook_Gamepad:RefreshVisibleCategories()
    self.categoryListDescriptor.list:RefreshVisible()
end

-- This function overrides the shared version because in the design the description is placed in a
-- different order then in the base layout.
function ZO_TributePatronBook_Gamepad:BuildGridList()
    if self.gridList then
        self.gridList:ClearGridList()
        
        -- Build Patron name header
        self:AddPatronHeader()

        if self.patronId then
            -- Pre-process starter cards
            self:SetupStarterCards()

            -- Pre-process dock cards
            self:SetupDockCards()

            -- Build description entry
            self:AddDescriptionEntry()

            -- Build Patron
            self:AddPatronEntry()

            -- Build starter card entries
            self:AddStarterCardEntries()

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

function ZO_TributePatronBook_Gamepad:AddPatronHeader()
  
    local patronData = TRIBUTE_DATA_MANAGER:GetTributePatronData(self.patronId)
    if patronData ~= nil then
        self.headerLabel:SetText(patronData:GetFormattedColorizedName())
    else
        self.headerLabel:SetText("")
    end
end

-- Begin ZO_Gamepad_ParametricList_Search_Screen Overrides --

function ZO_TributePatronBook_Gamepad:InitializeKeybindStripDescriptors()
    ZO_Gamepad_ParametricList_Search_Screen.InitializeKeybindStripDescriptors(self)

    self.categoryKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local categoryData = self:GetSelectedCategory()
                self:GetScene():AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
                self:ViewCategory(categoryData)
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.categoryKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)

    self.patronKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:EnterGridList()
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.patronKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        self:GetScene():RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
        self:ShowListDescriptor(self.categoryListDescriptor)
    end)

    self:SetListsUseTriggerKeybinds(true)
end

-- Default text search back button closes the screen, but we have multiple layers here.
function ZO_TributePatronBook_Gamepad:OnBackButtonClicked()
    if self.currentListDescriptor and not self.currentListDescriptor.isCategoriesDescriptor then
        self:GetScene():RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
        self:OnLeaveHeader()
        self:ShowListDescriptor(self.categoryListDescriptor)
    else
        -- Call parent to close scene.
        ZO_Gamepad_ParametricList_Search_Screen.OnBackButtonClicked(self)
    end
end

function ZO_TributePatronBook_Gamepad:EnterGridList()
    self:DeactivateCurrentListDescriptor()
    self.gridList:Activate()
    self.keybindStripDescriptor = self.gridKeybindStripDescriptor
    KEYBIND_STRIP:AddKeybindButtonGroup(self.gridKeybindStripDescriptor)
end

function ZO_TributePatronBook_Gamepad:ExitGridList()
    self.gridList:Deactivate()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.gridKeybindStripDescriptor)
    self.keybindStripDescriptor = nil
    self:ActivateCurrentListDescriptor()
end

function ZO_TributePatronBook_Gamepad:PerformUpdate()
    -- Must be overridden
    self.dirty = false
end

function ZO_TributePatronBook_Gamepad:OnUpdateSearchResults()
    self.categoriesRefreshGroup:MarkDirty("Visible")
end

function ZO_TributePatronBook_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Search_Screen.OnShowing(self)

    if self.browseToCollectibleInfo then
        self:ClearSearchText()
        local patronId = self.browseToCollectibleInfo.patronId
        local patronData = TRIBUTE_DATA_MANAGER:GetTributePatronData(patronId)
        local tributePatronCategoryData = patronData:GetCategoryData()
        local patronList = self.patronListDescriptor.list
        self:ViewCategory(tributePatronCategoryData)
        
        local patronIndex = patronList:GetIndexForData("ZO_GamepadSubMenuEntryTemplateWithStatus", patronData)
        patronList:SetSelectedIndexWithoutAnimation(patronIndex)
        self.browseToCollectibleInfo = nil

        self:GetScene():AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
        self.categoriesRefreshGroup:MarkDirty("List")
    else
        self:ShowListDescriptor(self.categoryListDescriptor)
    end
end

function ZO_TributePatronBook_Gamepad:OnHide()
    ZO_Gamepad_ParametricList_Search_Screen.OnHide(self)

    if self.gridList:IsActive() then
        self:ExitGridList()
    end
    self:HideCurrentListDescriptor()
    self:GetScene():RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
    self:DeactivateTextSearch()
end

function ZO_TributePatronBook_Gamepad:ActivateTextSearch()
    if not TEXT_SEARCH_MANAGER:IsActiveTextSearch(self.searchContext) then
        TEXT_SEARCH_MANAGER:ActivateTextSearch(self.searchContext)

        local function OnListTextFilterComplete()
            if self.currentListDescriptor then
                if self.currentListDescriptor.isCategoriesDescriptor then
                    self:RefreshCategories()
                else
                    self:ViewCategory()
                end
            end
        end
        self.onListTextFilterCompleteCallback = OnListTextFilterComplete

        TEXT_SEARCH_MANAGER:RegisterCallback("UpdateSearchResults", self.onListTextFilterCompleteCallback)
    end
end

function ZO_TributePatronBook_Gamepad:DeactivateTextSearch()
    if TEXT_SEARCH_MANAGER:IsActiveTextSearch(self.searchContext) then
        TEXT_SEARCH_MANAGER:DeactivateTextSearch(self.searchContext)

        TEXT_SEARCH_MANAGER:UnregisterCallback("UpdateSearchResults", self.onListTextFilterCompleteCallback)
        self.onListTextFilterCompleteCallback = nil
    end
end

function ZO_TributePatronBook_Gamepad:SetupList(list)
    local function TributePatronCategoryEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        data:SetNew(data:HasAnyNewPatronCollectibles())
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    end

    local function TributePatronEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        data:SetNew(data.dataSource:IsNew())
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    end

    list:AddDataTemplateWithHeader("ZO_GamepadNewMenuEntryTemplate", TributePatronCategoryEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, ZO_TributePatronCategoryData.Equals, "ZO_GamepadMenuEntryHeaderTemplate")
    list:AddDataTemplate("ZO_GamepadNewMenuEntryTemplate", TributePatronCategoryEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, ZO_TributePatronCategoryData.Equals)
    list:AddDataTemplateWithHeader("ZO_GamepadSubMenuEntryTemplateWithStatus", TributePatronEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, ZO_TributePatronData.Equals, "ZO_GamepadMenuEntryHeaderTemplate")
    list:AddDataTemplate("ZO_GamepadSubMenuEntryTemplateWithStatus", TributePatronEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, ZO_TributePatronData.Equals)
    list:SetReselectBehavior(ZO_PARAMETRIC_SCROLL_LIST_RESELECT_BEHAVIOR.MATCH_OR_RESET_TO_DEFAULT)
end

-- End ZO_Gamepad_ParametricList_Screen Overrides --

function ZO_TributePatronBook_Gamepad:ShowListDescriptor(listDescriptor)
    if self.currentListDescriptor == listDescriptor then
        return
    end

    self:HideCurrentListDescriptor()

    self.currentListDescriptor = listDescriptor
    if listDescriptor then
        self:SetCurrentList(listDescriptor.list)
        self.keybindStripDescriptor = listDescriptor.keybindDescriptor
        KEYBIND_STRIP:AddKeybindButtonGroup(listDescriptor.keybindDescriptor)
        self:RefreshHeader()
        self.infoContainerControl:SetHidden(listDescriptor ~= self.patronListDescriptor)
    end

    self:RefreshCategories()
end

function ZO_TributePatronBook_Gamepad:HideCurrentListDescriptor()
    if self.currentListDescriptor then
        if not self.currentListDescriptor.isCategoriesDescriptor then
            local currentData = self.currentListDescriptor.list:GetTargetData()
            if currentData and currentData:IsNew() then
                ClearCollectibleNewStatus(currentData:GetPatronCollectibleId())
                self.categoriesRefreshGroup:MarkDirty("List")
            end
        end

        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentListDescriptor.keybindDescriptor)
        self.keybindStripDescriptor = nil
        self:DisableCurrentList()
        self.currentListDescriptor = nil
    end
end

function ZO_TributePatronBook_Gamepad:ActivateCurrentListDescriptor()
    if self.currentListDescriptor then
        self:ActivateCurrentList()
        self.keybindStripDescriptor = self.currentListDescriptor.keybindDescriptor
        KEYBIND_STRIP:AddKeybindButtonGroup(self.currentListDescriptor.keybindDescriptor)
    end
end

function ZO_TributePatronBook_Gamepad:DeactivateCurrentListDescriptor()
    if self.currentListDescriptor then
        self:DeactivateCurrentList()
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentListDescriptor.keybindDescriptor)
        self.keybindStripDescriptor = nil
    end
end

function ZO_TributePatronBook_Gamepad:GetCurrentListTargetData()
    local currentList = self:GetCurrentList()
    return currentList and currentList:GetTargetData()
end

function ZO_TributePatronBook_Gamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    if oldSelectedData and oldSelectedData:IsNew() and oldSelectedData.GetPatronCollectibleId then
        ClearCollectibleNewStatus(oldSelectedData:GetPatronCollectibleId())
        self.categoriesRefreshGroup:MarkDirty("List")
    end

    if selectedData and selectedData.dataSource then
        if list == self.patronListDescriptor.list then
            self.patronId = selectedData.patronId
            self:BuildGridList()
        end
    end
end

function ZO_TributePatronBook_Gamepad:BrowseToPatron(patronId)
    self.browseToCollectibleInfo =
    {
        patronId = patronId,
    }

    SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", self:GetSceneName())
end

--[[Global functions]]--
------------------------
function ZO_TributePatronBook_Gamepad_OnInitialize(control)
    GAMEPAD_TRIBUTE_PATRON_BOOK = ZO_TributePatronBook_Gamepad:New(control)
end