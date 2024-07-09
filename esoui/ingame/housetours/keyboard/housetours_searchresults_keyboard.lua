-----------------------------
--House Tours Search Results
-----------------------------

ZO_HouseToursSearchResults_Keyboard = ZO_DeferredInitializingObject:Subclass()

function ZO_HouseToursSearchResults_Keyboard:Initialize(control)
    self.control = control
    self.containerControl = self.control:GetNamedChild("Container")
    self.dirty = true
    local fragment = ZO_FadeSceneFragment:New(self.control)
    ZO_DeferredInitializingObject.Initialize(self, fragment)

    self:InitializeActivityFinderCategoryData()
end

function ZO_HouseToursSearchResults_Keyboard:OnDeferredInitialize()
    self:InitializeGridList()
    self:InitializeFilters()
    self:RegisterForEvents()
    self:InitializeKeybindStripDescriptor()
    --TODO House Tours: Implement
end

function ZO_HouseToursSearchResults_Keyboard:RegisterForEvents()
    HOUSE_TOURS_SEARCH_MANAGER:RegisterCallback("OnSearchStateChanged", function(newState, listingType)
        if listingType == self.listingType then
            if self:IsShowing() then
                self:RefreshGridList()
                self:RefreshFilters()

                if newState == ZO_HOUSE_TOURS_SEARCH_STATES.COMPLETE then
                    -- Clear any preserved scroll offset now that it has been reapplied.
                    self.autoScrollValue = nil
                end
            else
                self.dirty = true
            end
        end
    end)

    HOUSE_TOURS_SEARCH_MANAGER:RegisterCallback("OnFavoritesChanged", function()
        if self:IsShowing() then
            self.autoScrollValue = self.gridList:GetScrollValue()
            HOUSE_TOURS_SEARCH_MANAGER:ExecuteSearch(self.listingType)
        else
            self.dirty = true
        end
    end)
end

function ZO_HouseToursSearchResults_Keyboard:InitializeKeybindStripDescriptor()
    self.keybindStripDescriptor = {}
end

function ZO_HouseToursSearchResults_Keyboard:InitializeFilters()
    self.nameSearchBox = self.containerControl:GetNamedChild("DisplayNameSearchBox")
    --TODO House Tours: Is this the right text to use? How will this search work on consoles?
    self.nameSearchBox:SetDefaultText(ZO_GetPlatformAccountLabel())
    self.nameSearchBox:SetHandler("OnFocusLost", function(editControl)
        local filters = HOUSE_TOURS_SEARCH_MANAGER:GetSearchFilters(self.listingType)
        local newValue = self.nameSearchBox:GetText()
        local oldValue = filters:GetDisplayName()

        --Only run a new search if the value actually changed
        if newValue ~= oldValue then
            filters:SetDisplayName(newValue)
            HOUSE_TOURS_SEARCH_MANAGER:ExecuteSearch(self.listingType)
        end
    end)

    local function OnTagsDropdownShown()
        local filters = HOUSE_TOURS_SEARCH_MANAGER:GetSearchFilters(self.listingType)
        self.oldTags = {}
        ZO_DeepTableCopy(filters.tags, self.oldTags)
        table.sort(self.oldTags)
    end

    local function OnTagsDropdownHidden()
        local filters = HOUSE_TOURS_SEARCH_MANAGER:GetSearchFilters(self.listingType)
        table.sort(filters.tags)
        if not ZO_AreNumericallyIndexedTablesEqual(filters.tags, self.oldTags) then
            HOUSE_TOURS_SEARCH_MANAGER:ExecuteSearch(self.listingType)
        end
    end

    local function OnHouseIdsDropdownShown()
        local filters = HOUSE_TOURS_SEARCH_MANAGER:GetSearchFilters(self.listingType)
        self.oldHouseIds = {}
        ZO_DeepTableCopy(filters.houseIds, self.oldHouseIds)
        table.sort(self.oldHouseIds)
    end

    local function OnHouseIdsDropdownHidden()
        local filters = HOUSE_TOURS_SEARCH_MANAGER:GetSearchFilters(self.listingType)
        table.sort(filters.houseIds)
        if not ZO_AreNumericallyIndexedTablesEqual(filters.houseIds, self.oldHouseIds) then
            HOUSE_TOURS_SEARCH_MANAGER:ExecuteSearch(self.listingType)
        end
    end

    local function TagSelectionChanged()
        local newTags = {}
        local selectedTagsData = self.tagsDropdown:GetSelectedItemData()
        for _, item in ipairs(selectedTagsData) do
            table.insert(newTags, item.tagValue)
        end

        local filters = HOUSE_TOURS_SEARCH_MANAGER:GetSearchFilters(self.listingType)
        filters:SetTags(newTags)
    end

    self.tagsDropdownControl = self.containerControl:GetNamedChild("TagsFilter")
    self.tagsDropdown = ZO_ComboBox_ObjectFromContainer(self.tagsDropdownControl)
    self.tagsDropdown:EnableMultiSelect()
    self.tagsDropdown:SetMaxSelections(MAX_HOUSE_TOURS_LISTING_TAGS)
    self.tagsDropdown:SetNoSelectionText(GetString(SI_HOUSE_TOURS_FILTERS_TAGS_DROPDOWN_NO_SELECTION_TEXT))
    self.tagsDropdown:SetMultiSelectionTextFormatter(SI_HOUSE_TOURS_TAGS_DROPDOWN_TEXT_FORMATTER)
    for i = HOUSE_TOURS_LISTING_TAG_ITERATION_BEGIN, HOUSE_TOURS_LISTING_TAG_ITERATION_END do
        local tagEntry = self.tagsDropdown:CreateItemEntry(GetString("SI_HOUSETOURLISTINGTAG", i), TagSelectionChanged)
        tagEntry.tagValue = i
        self.tagsDropdown:AddItem(tagEntry, ZO_COMBOBOX_SUPPRESS_UPDATE)
    end
    self.tagsDropdown:UpdateItems()
    self.tagsDropdown:SetPreshowDropdownCallback(OnTagsDropdownShown)
    self.tagsDropdown:SetHideDropdownCallback(OnTagsDropdownHidden)

    local function HouseSelectionChanged()
        local newHouseIds = {}
        local selectedHouseData = self.houseDropdown:GetSelectedItemData()
        for _, item in ipairs(selectedHouseData) do
            table.insert(newHouseIds, item.houseId)
        end

        local filters = HOUSE_TOURS_SEARCH_MANAGER:GetSearchFilters(self.listingType)
        filters:SetHouseIds(newHouseIds)
    end

    self.houseDropdownControl = self.containerControl:GetNamedChild("HouseFilter")
    self.houseDropdown = ZO_ComboBox_ObjectFromContainer(self.houseDropdownControl)
    self.houseDropdown:EnableMultiSelect()
    self.houseDropdown:SetMaxSelections(MAX_HOUSE_TOURS_HOUSE_FILTERS)
    self.houseDropdown:SetNoSelectionText(GetString(SI_HOUSE_TOURS_FILTERS_HOUSE_DROPDOWN_NO_SELECTION_TEXT))
    self.houseDropdown:SetMultiSelectionTextFormatter(SI_HOUSE_TOURS_FILTERS_HOUSE_DROPDOWN_TEXT_FORMATTER)
    local allHouses = ZO_COLLECTIBLE_DATA_MANAGER:GetAllCollectibleDataObjects({ ZO_CollectibleCategoryData.IsHousingCategory })
    for _, collectibleData in ipairs(allHouses) do
        local houseEntry = self.houseDropdown:CreateItemEntry(collectibleData:GetFormattedName(), HouseSelectionChanged)
        houseEntry.houseId = collectibleData:GetReferenceId()
        self.houseDropdown:AddItem(houseEntry, ZO_COMBOBOX_SUPPRESS_UPDATE)
    end
    self.houseDropdown:UpdateItems()
    self.houseDropdown:SetPreshowDropdownCallback(OnHouseIdsDropdownShown)
    self.houseDropdown:SetHideDropdownCallback(OnHouseIdsDropdownHidden)

    local function OnConfirmFilters()
        --TODO House Tours: Is there any other logic we want to run here?
        HOUSE_TOURS_SEARCH_MANAGER:ExecuteSearch(self.listingType)
    end

    self.allFiltersButton = self.containerControl:GetNamedChild("AllFilters")
    self.allFiltersButton:SetHandler("OnClicked", function(buttonControl, button)
        if button == MOUSE_BUTTON_INDEX_LEFT then
            ZO_Dialogs_ShowDialog("HOUSE_TOURS_SEARCH_FILTERS_KEYBOARD", { filterData = HOUSE_TOURS_SEARCH_MANAGER:GetSearchFilters(self.listingType), confirmCallback = OnConfirmFilters })
        end
    end)
end

function ZO_HouseToursSearchResults_Keyboard:InitializeGridList()
    self.gridListControl = self.containerControl:GetNamedChild("GridList")
    self.gridList = ZO_GridScrollList_Keyboard:New(self.gridListControl)
    self.gridListEmptyLabel = self.containerControl:GetNamedChild("EmptyText")
    self.loadingIcon = self.containerControl:GetNamedChild("LoadingIcon")

    local HIDE_CALLBACK = nil
    local ENTRY_WIDTH = 302
    local ENTRY_HEIGHT = 200
    local ENTRY_PADDING_X = 5
    local ENTRY_PADDING_Y = 10
    self.gridList:AddEntryTemplate("ZO_HouseToursSearchResultsTile_Keyboard_Control", ENTRY_WIDTH, ENTRY_HEIGHT, ZO_DefaultGridTileEntrySetup, HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, ENTRY_PADDING_X, ENTRY_PADDING_Y)
end

function ZO_HouseToursSearchResults_Keyboard:InitializeActivityFinderCategoryData()
    self.categoryData =
    {
        [HOUSE_TOURS_LISTING_TYPE_RECOMMENDED] =
        {
            priority = ZO_ACTIVITY_FINDER_SORT_PRIORITY.HOUSE_TOURS + 10,
            name = GetString(SI_HOUSE_TOURS_RECOMMENDED),
            categoryFragment = self:GetFragment(),
            onTreeEntrySelected = function() self:OnCategorySelected(HOUSE_TOURS_LISTING_TYPE_RECOMMENDED) end,
        },
        [HOUSE_TOURS_LISTING_TYPE_BROWSE] =
        {
            priority = ZO_ACTIVITY_FINDER_SORT_PRIORITY.HOUSE_TOURS + 20,
            name = GetString(SI_HOUSE_TOURS_BROWSE_HOMES),
            categoryFragment = self:GetFragment(),
            onTreeEntrySelected = function() self:OnCategorySelected(HOUSE_TOURS_LISTING_TYPE_BROWSE) end,
        },
        [HOUSE_TOURS_LISTING_TYPE_FAVORITE] =
        {
            priority = ZO_ACTIVITY_FINDER_SORT_PRIORITY.HOUSE_TOURS + 30,
            name = GetString(SI_HOUSE_TOURS_FAVORITE_HOMES),
            categoryFragment = self:GetFragment(),
            onTreeEntrySelected = function() self:OnCategorySelected(HOUSE_TOURS_LISTING_TYPE_FAVORITE) end,
        },
    }
end

function ZO_HouseToursSearchResults_Keyboard:GetActivityFinderCategoryData(listingType)
    return self.categoryData[listingType]
end

function ZO_HouseToursSearchResults_Keyboard:OnCategorySelected(listingType)
    self.listingType = listingType
    HOUSE_TOURS_SEARCH_MANAGER:ExecuteSearch(listingType)
end

function ZO_HouseToursSearchResults_Keyboard:RefreshGridList(resetToTop)
    if self.gridList then
        self.gridList:ClearGridList(not resetToTop)
        local searchResults = HOUSE_TOURS_SEARCH_MANAGER:GetSortedSearchResults(self.listingType)
        for _, houseListingData in ipairs(searchResults) do
            local entryData = ZO_EntryData:New(houseListingData)
            self.gridList:AddEntry(entryData, "ZO_HouseToursSearchResultsTile_Keyboard_Control")
        end
        self.gridList:CommitGridList()

        if self.autoScrollValue then
            -- Scroll back to the preserved scroll offset instantly.
            local NO_CALLBACK = nil
            local SCROLL_INSTANTLY = true
            self.gridList:ScrollToValue(self.autoScrollValue, NO_CALLBACK, SCROLL_INSTANTLY)
        end

        self:RefreshSearchState()
    end
end

function ZO_HouseToursSearchResults_Keyboard:RefreshSearchState()
    local currentSearchState = HOUSE_TOURS_SEARCH_MANAGER:GetSearchState(self.listingType)
    if currentSearchState == ZO_HOUSE_TOURS_SEARCH_STATES.WAITING or currentSearchState == ZO_HOUSE_TOURS_SEARCH_STATES.QUEUED then
        self.loadingIcon:Show()
        self.gridListEmptyLabel:SetText(GetString(SI_HOUSE_TOURS_SEARCH_RESULTS_REFRESHING_RESULTS))
    elseif currentSearchState == ZO_HOUSE_TOURS_SEARCH_STATES.COMPLETE then
        self.loadingIcon:Hide()
        self.gridListEmptyLabel:SetText(GetString(SI_HOUSE_TOURS_SEARCH_RESULTS_EMPTY_TEXT))
    else
        self.loadingIcon:Hide()
    end

    self.gridListEmptyLabel:SetHidden(self.gridList:HasEntries())
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_HouseToursSearchResults_Keyboard:RefreshFilters()
    local filters = HOUSE_TOURS_SEARCH_MANAGER:GetSearchFilters(self.listingType)

    --Refresh the tags dropdown
    self.tagsDropdown:ClearAllSelections()
    local tags = filters:GetTags()
    for _, item in ipairs(self.tagsDropdown:GetItems()) do
        if ZO_IsElementInNumericallyIndexedTable(tags, item.tagValue) then
            local IGNORE_CALLBACK = true
            self.tagsDropdown:SelectItem(item, IGNORE_CALLBACK)
        end
    end

    --Refresh the house dropdown
    self.houseDropdown:ClearAllSelections()
    local houseIds = filters:GetHouseIds()
    for _, item in ipairs(self.houseDropdown:GetItems()) do
        if ZO_IsElementInNumericallyIndexedTable(houseIds, item.houseId) then
            local IGNORE_CALLBACK = true
            self.houseDropdown:SelectItem(item, IGNORE_CALLBACK)
        end
    end

    --Refresh the search box
    self.nameSearchBox:SetText(filters:GetDisplayName())
end

function ZO_HouseToursSearchResults_Keyboard:BrowseToSpecificHouse(houseId)
    if self:IsShowing() then
        --Switch the filters to use the specific house id
        local filters = HOUSE_TOURS_SEARCH_MANAGER:GetSearchFilters(HOUSE_TOURS_LISTING_TYPE_BROWSE)
        filters:ResetFilters()
        filters:SetHouseIds({houseId})

        --If we are already on browse, we need to manually refresh the filters and execute the search. Otherwise that will be triggered when category actually changes
        if self.listingType == HOUSE_TOURS_LISTING_TYPE_BROWSE then
            self:RefreshFilters()
            HOUSE_TOURS_SEARCH_MANAGER:ExecuteSearch(self.listingType)
        end
    else
        self.pendingBrowseHouseId = houseId
    end
end

function ZO_HouseToursSearchResults_Keyboard:OnShowing()
    if self.dirty then
        local RESET_TO_TOP = true
        self:RefreshGridList(RESET_TO_TOP)
        self:RefreshFilters()
        self.dirty = false
    end

    if self.pendingBrowseHouseId then
        self:BrowseToSpecificHouse(self.pendingBrowseHouseId)
        self.pendingBrowseHouseId = nil
    end
end

function ZO_HouseToursSearchResults_Keyboard:OnShown()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    
    TriggerTutorial(TUTORIAL_TRIGGER_HOUSE_TOURS_OPENED)
end

function ZO_HouseToursSearchResults_Keyboard:OnHiding()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_HouseToursSearchResults_Keyboard.OnControlInitialized(control)
    HOUSE_TOURS_SEARCH_RESULTS_KEYBOARD = ZO_HouseToursSearchResults_Keyboard:New(control)
end

-----------------------------------
--House Tours Search Results Tile
-----------------------------------

ZO_HOUSE_TOURS_SEARCH_RESULTS_TILE_KEYBOARD_DEFAULT_HIGHLIGHT_ANIMATION_PROVIDER = ZO_ReversibleAnimationProvider:New("ZO_HouseToursSearchResultsTile_Keyboard_HighlightAnimation")

ZO_HouseToursSearchResultsTile_Keyboard = ZO_Object.MultiSubclass(ZO_ContextualActionsTile_Keyboard, ZO_ContextualActionsTile)

function ZO_HouseToursSearchResultsTile_Keyboard:New(...)
    return ZO_ContextualActionsTile.New(self, ...)
end

--Overridden from base
function ZO_HouseToursSearchResultsTile_Keyboard:InitializePlatform()
    ZO_ContextualActionsTile_Keyboard.InitializePlatform(self)
    self.background = self.control:GetNamedChild("Background")
    self.nicknameLabel = self.control:GetNamedChild("Nickname")
    self.houseNameLabel = self.control:GetNamedChild("HouseName")
    self.favoriteIconTexture = self.control:GetNamedChild("FavoriteIcon")
    self.furnitureCountLabel = self.control:GetNamedChild("FurnitureCount")
    self.displayNameLabel = self.control:GetNamedChild("DisplayName")
end

--Overridden from base
function ZO_HouseToursSearchResultsTile_Keyboard:PostInitializePlatform()
    -- keybindStripDescriptor and canFocus need to be set after initialize, because ZO_ContextualActionsTile
    -- won't have finished initializing those until after InitializePlatform is called
    ZO_ContextualActionsTile_Keyboard.PostInitializePlatform(self)

    self.HandleAddRemoveFavoriteHome = function() self:AddRemoveFavoriteHome() end
    self.HandleLinkHomeToChat = function() self:LinkHomeToChat() end
    self.HandleReportHome = function() self:ReportHome() end
    self.HandleVisitHome = function() self:VisitHome() end

    --Report Listing
    table.insert(self.keybindStripDescriptor,
    {
        name = GetString(SI_HOUSE_TOURS_REPORT_LISTING),
        keybind = "UI_SHORTCUT_REPORT_PLAYER",
        callback = self.HandleReportHome,
        visible = function()
            if self.listingData then
                return self.listingData:CanReport()
            end
            return false
        end,
    })

    --Add/Remove Favorite Home
    table.insert(self.keybindStripDescriptor,
    {
        name = function()
            local listingData = self.listingData
            if listingData then
                if listingData:IsFavorite() then
                    return zo_strformat(SI_HOUSE_TOURS_REMOVE_FAVORITE_LISTING, GetNumFavoriteHouses(), MAX_HOUSE_TOURS_LISTING_FAVORITES)
                else
                    return zo_strformat(SI_HOUSE_TOURS_ADD_FAVORITE_LISTING, GetNumFavoriteHouses(), MAX_HOUSE_TOURS_LISTING_FAVORITES)
                end
            end
        end,
        keybind = "UI_SHORTCUT_SECONDARY",
        callback = self.HandleAddRemoveFavoriteHome,
        visible = function()
            if self.listingData then
                return self.listingData:CanFavorite()
            end
            return false
        end,
    })

    --Visit Home
    table.insert(self.keybindStripDescriptor,
    {
        name = GetString(SI_HOUSE_TOURS_VISIT_HOME),
        keybind = "UI_SHORTCUT_PRIMARY",
        callback = self.HandleVisitHome,
    })

    self:SetCanFocus(false)
    self:SetHighlightAnimationProvider(ZO_HOUSE_TOURS_SEARCH_RESULTS_TILE_KEYBOARD_DEFAULT_HIGHLIGHT_ANIMATION_PROVIDER)
end

--Overridden from base
function ZO_HouseToursSearchResultsTile_Keyboard:OnControlHidden()
    self:OnMouseExit()
    ZO_ContextualActionsTile.OnControlHidden(self)
end

--Overridden from base
function ZO_HouseToursSearchResultsTile_Keyboard:OnFocusChanged(isFocused)
    ZO_ContextualActionsTile.OnFocusChanged(self, isFocused)
    if self.listingData then
        if not isFocused then
            ClearTooltip(InformationTooltip)
        end
        self:RefreshMouseoverVisuals()
    end
end

do
    local FURNITURE_COUNT_TEXTURE = "EsoUI/Art/HouseTours/houseTours_furnitureCount.dds"
    local IS_FRIEND_TEXTURE = "EsoUI/Art/HouseTours/houseTours_listingIcon_friends.dds"
    local IS_GUILD_MEMBER_TEXTURE = "EsoUI/Art/HouseTours/houseTours_listingIcon_guild.dds"
    local IS_LOCAL_PLAYER_TEXTURE = "EsoUI/Art/HouseTours/houseTours_listingIcon_localPlayer.dds"

    --Overridden from base
    function ZO_HouseToursSearchResultsTile_Keyboard:LayoutPlatform(data)
        self.listingData = data
        self:SetCanFocus(true)

        self.favoriteIconTexture:SetHidden(not data:IsFavorite())
        self.nicknameLabel:SetText(self.listingData:GetFormattedNickname())
        self.background:SetTexture(self.listingData:GetBackgroundImage())
        self.houseNameLabel:SetText(self.listingData:GetFormattedHouseName())

        local formattedDisplayName = self.listingData:GetFormattedOwnerDisplayName()
        if self.listingData:IsOwnedByFriend() then
            formattedDisplayName = zo_iconTextFormat(IS_FRIEND_TEXTURE, 32, 32, formattedDisplayName)
        elseif self.listingData:IsOwnedByGuildMember() then
            formattedDisplayName = zo_iconTextFormat(IS_GUILD_MEMBER_TEXTURE, 32, 32, formattedDisplayName)
        elseif self.listingData:IsOwnedByLocalPlayer() then
            local INHERIT_COLOR = true
            formattedDisplayName = ZO_SECOND_CONTRAST_TEXT:Colorize(zo_iconTextFormat(IS_LOCAL_PLAYER_TEXTURE, 32, 32, formattedDisplayName, INHERIT_COLOR))
        end

        self.displayNameLabel:SetText(formattedDisplayName)

        local furnitureCountText
        local furnitureCount = self.listingData:GetFurnitureCount()
        if furnitureCount ~= nil then
            furnitureCountText = zo_iconTextFormat(FURNITURE_COUNT_TEXTURE, 32, 32, furnitureCount)
        else
            furnitureCountText = zo_iconTextFormat(FURNITURE_COUNT_TEXTURE, 32, 32, GetString(SI_HOUSE_TOURS_LISTING_FURNITURE_COUNT_UNKNOWN))
        end
        self.furnitureCountLabel:SetText(furnitureCountText)

        --TODO House Tours: Finish hooking up tile visuals

        self:RefreshMouseoverVisuals()
    end
end

function ZO_HouseToursSearchResultsTile_Keyboard:Reset()
    self.listingData = nil
    self:SetCanFocus(false)
    local ANIMATE_INSTANTLY = true
    self:SetHighlightHidden(true, ANIMATE_INSTANTLY)
end

function ZO_HouseToursSearchResultsTile_Keyboard:RefreshMouseoverVisuals()
    if self.listingData and self:IsMousedOver() then
        ClearTooltip(InformationTooltip)
        InitializeTooltip(InformationTooltip, self.control, RIGHT, -5)
        local DEFAULT_FONT = ""
        local tagsText = self.listingData:GetFormattedTagsText()
        InformationTooltip:AddLine(zo_strformat(SI_HOUSE_TOURS_LISTING_TAGS_TOOLTIP_FORMATTER, ZO_SELECTED_TEXT:Colorize(tagsText)), DEFAULT_FONT, ZO_NORMAL_TEXT:UnpackRGBA())
    end
end

function ZO_HouseToursSearchResultsTile_Keyboard:OnMouseUp(button, upInside)
    if upInside and button == MOUSE_BUTTON_INDEX_RIGHT then
        self:ShowContextMenu()
    end
end

function ZO_HouseToursSearchResultsTile_Keyboard:OnMouseDoubleClick(button)
    self:VisitHome()
end

function ZO_HouseToursSearchResultsTile_Keyboard:ShowContextMenu()
    if not self.listingData then
        return
    end

    ClearMenu()
    AddMenuItem(GetString(SI_HOUSE_TOURS_VISIT_HOME), self.HandleVisitHome)
    AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), self.HandleLinkHomeToChat)
    if self.listingData:CanFavorite() then
        local addRemoveFavoriteString
        if self.listingData:IsFavorite() then
            addRemoveFavoriteString = zo_strformat(SI_HOUSE_TOURS_REMOVE_FAVORITE_LISTING, GetNumFavoriteHouses(), MAX_HOUSE_TOURS_LISTING_FAVORITES)
        else
            addRemoveFavoriteString = zo_strformat(SI_HOUSE_TOURS_ADD_FAVORITE_LISTING, GetNumFavoriteHouses(), MAX_HOUSE_TOURS_LISTING_FAVORITES)
        end
        AddMenuItem(addRemoveFavoriteString, self.HandleAddRemoveFavoriteHome)
    end
    if self.listingData:CanReport() then
        AddMenuItem(GetString(SI_HOUSE_TOURS_REPORT_LISTING), self.HandleReportHome)
    end
    ShowMenu(self.control)
end

function ZO_HouseToursSearchResultsTile_Keyboard:AddRemoveFavoriteHome()
    local listingData = self.listingData
    if listingData then
        if listingData:IsFavorite() then
            listingData:RequestRemoveFavorite()
        else
            listingData:RequestAddFavorite()
        end
    end
end

function ZO_HouseToursSearchResultsTile_Keyboard:LinkHomeToChat()
    local listingData = self.listingData
    if listingData then
        local houseId = listingData:GetHouseId()
        local ownerDisplayName = listingData:GetFormattedOwnerDisplayName()
        local link = GetHousingLink(houseId, ownerDisplayName, LINK_STYLE_BRACKETS)
        ZO_LinkHandler_InsertLink(link)
    end
end

function ZO_HouseToursSearchResultsTile_Keyboard:ReportHome()
    local listingData = self.listingData
    if listingData then
        ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportHouseTourListingTicketScene(listingData)
    end
end

function ZO_HouseToursSearchResultsTile_Keyboard:VisitHome()
    local listingData = self.listingData
    if listingData then
        local FROM_HOUSE_TOURS = true
        HOUSING_SOCIAL_MANAGER:VisitHouse(listingData:GetHouseId(), listingData:GetOwnerDisplayName(), FROM_HOUSE_TOURS)
    end
end

function ZO_HouseToursSearchResultsTile_Keyboard.OnControlInitialized(control)
    ZO_HouseToursSearchResultsTile_Keyboard:New(control)
end

-----------------------------------
--House Tours Search Filters Dialog
-----------------------------------

ZO_HouseToursSearchFiltersDialog_Keyboard = ZO_InitializingObject:Subclass()

function ZO_HouseToursSearchFiltersDialog_Keyboard:Initialize(control)
    self.control = control
end

function ZO_HouseToursSearchFiltersDialog_Keyboard:PerformDeferredInitialize()
    if not self.initialized then
        self.initialized = true
        self:OnDeferredInitialize()
    end
end

function ZO_HouseToursSearchFiltersDialog_Keyboard:OnDeferredInitialize()
    local control = self.control
    self.searchBoxHeader = control:GetNamedChild("SearchHeader")
    self.searchBox = control:GetNamedChild("SearchBox")

    --TODO House Tours: Is this the right text to use? How will this search work on consoles?
    local platformAccountLabel = ZO_GetPlatformAccountLabel()
    self.searchBoxHeader:SetText(platformAccountLabel)
    self.searchBox:SetDefaultText(platformAccountLabel)
    self.searchBox:SetHandler("OnFocusLost", function(editControl)
        local newValue = self.searchBox:GetText()
        local oldValue = self.pendingFilterData:GetDisplayName()
        if newValue ~= oldValue then
            self.pendingFilterData:SetDisplayName(newValue)
        end
    end)

    local function OnHideDropdown()
        self:Refresh()
    end

    local function TagSelectionChanged()
        local newTags = {}
        local selectedTagsData = self.tagsDropdown:GetSelectedItemData()
        for _, item in ipairs(selectedTagsData) do
            table.insert(newTags, item.tagValue)
        end
        self.pendingFilterData:SetTags(newTags)
    end

    self.tagsDropdownControl = control:GetNamedChild("TagsSelector")
    self.tagsDropdown = ZO_ComboBox_ObjectFromContainer(self.tagsDropdownControl)
    self.tagsDropdown:EnableMultiSelect()
    self.tagsDropdown:SetMaxSelections(MAX_HOUSE_TOURS_LISTING_TAGS)
    self.tagsDropdown:SetNoSelectionText(GetString(SI_HOUSE_TOURS_FILTERS_TAGS_DROPDOWN_NO_SELECTION_TEXT))
    self.tagsDropdown:SetMultiSelectionTextFormatter(SI_HOUSE_TOURS_TAGS_DROPDOWN_TEXT_FORMATTER)
    for i = HOUSE_TOURS_LISTING_TAG_ITERATION_BEGIN, HOUSE_TOURS_LISTING_TAG_ITERATION_END do
        local tagEntry = self.tagsDropdown:CreateItemEntry(GetString("SI_HOUSETOURLISTINGTAG", i), TagSelectionChanged)
        tagEntry.tagValue = i
        self.tagsDropdown:AddItem(tagEntry, ZO_COMBOBOX_SUPPRESS_UPDATE)
    end
    self.tagsDropdown:UpdateItems()
    self.tagsDropdown:SetHideDropdownCallback(OnHideDropdown)

    local function HouseSelectionChanged()
        local newHouseIds = {}
        local selectedHouseData = self.houseDropdown:GetSelectedItemData()
        for _, item in ipairs(selectedHouseData) do
            table.insert(newHouseIds, item.houseId)
        end
        self.pendingFilterData:SetHouseIds(newHouseIds)
    end

    self.houseDropdownControl = control:GetNamedChild("HouseNameSelector")
    self.houseDropdown = ZO_ComboBox_ObjectFromContainer(self.houseDropdownControl)
    self.houseDropdown:EnableMultiSelect()
    self.houseDropdown:SetMaxSelections(MAX_HOUSE_TOURS_HOUSE_FILTERS)
    self.houseDropdown:SetNoSelectionText(GetString(SI_HOUSE_TOURS_FILTERS_HOUSE_DROPDOWN_NO_SELECTION_TEXT))
    self.houseDropdown:SetMultiSelectionTextFormatter(SI_HOUSE_TOURS_FILTERS_HOUSE_DROPDOWN_TEXT_FORMATTER)

    local allHouses = ZO_COLLECTIBLE_DATA_MANAGER:GetAllCollectibleDataObjects({ ZO_CollectibleCategoryData.IsHousingCategory })
    for _, collectibleData in ipairs(allHouses) do
        local houseEntry = self.houseDropdown:CreateItemEntry(collectibleData:GetFormattedName(), HouseSelectionChanged)
        houseEntry.houseId = collectibleData:GetReferenceId()
        self.houseDropdown:AddItem(houseEntry, ZO_COMBOBOX_SUPPRESS_UPDATE)
    end
    self.houseDropdown:UpdateItems()
    self.houseDropdown:SetHideDropdownCallback(OnHideDropdown)

    local function HouseCategorySelectionChanged()
        local newCategories = {}
        local selectedHouseCategoryData = self.houseCategoryDropdown:GetSelectedItemData()
        for _, item in ipairs(selectedHouseCategoryData) do
            table.insert(newCategories, item.categoryValue)
        end
        self.pendingFilterData:SetHouseCategoryTypes(newCategories)
    end

    self.houseCategoryContainerControl = control:GetNamedChild("HouseCategorySelector")
    self.houseCategoryControl = self.houseCategoryContainerControl:GetNamedChild("Dropdown")
    self.houseCategoryDropdown = ZO_ComboBox_ObjectFromContainer(self.houseCategoryControl)
    self.houseCategoryDropdown:EnableMultiSelect()
    self.houseCategoryDropdown:SetMaxSelections(MAX_HOUSE_TOURS_CATEGORY_TYPE_FILTERS)
    self.houseCategoryDropdown:SetNoSelectionText(GetString(SI_HOUSE_TOURS_FILTERS_HOUSE_CATEGORY_DROPDOWN_NO_SELECTION_TEXT))
    self.houseCategoryDropdown:SetMultiSelectionTextFormatter(SI_HOUSE_TOURS_FILTERS_HOUSE_CATEGORY_DROPDOWN_TEXT_FORMATTER)
    for i = HOUSE_CATEGORY_TYPE_ITERATION_BEGIN, HOUSE_CATEGORY_TYPE_ITERATION_END do
        local categoryEntry = self.houseCategoryDropdown:CreateItemEntry(GetString("SI_HOUSECATEGORYTYPE", i), HouseCategorySelectionChanged)
        categoryEntry.categoryValue = i
        self.houseCategoryDropdown:AddItem(categoryEntry, ZO_COMBOBOX_SUPPRESS_UPDATE)
    end
    self.houseCategoryDropdown:UpdateItems()
    self.houseCategoryDropdown:SetHideDropdownCallback(OnHideDropdown)
    self.houseCategoryContainerControl:SetHandler("OnMouseEnter", function()
        if not self.pendingFilterData:CanSetHouseCategoryTypes() then
            ClearTooltip(InformationTooltip)
            InitializeTooltip(InformationTooltip, self.houseCategoryControl, RIGHT, -5)
            InformationTooltip:AddLine(GetString(SI_HOUSE_TOURS_FILTERS_HOUSE_CATEGORY_DISABLED), DEFAULT_FONT, ZO_NORMAL_TEXT:UnpackRGBA())
        end
    end)
    self.houseCategoryContainerControl:SetHandler("OnMouseExit", function()
        ClearTooltip(InformationTooltip)
    end)
end

function ZO_HouseToursSearchFiltersDialog_Keyboard:SetFilterData(filterData)
    self.filterData = filterData
    self.pendingFilterData = ZO_HouseTours_Search_Filters:New(filterData:GetListingType())
    self.pendingFilterData:CopyFrom(self.filterData)

    self:Refresh()
end

function ZO_HouseToursSearchFiltersDialog_Keyboard:Refresh()
    --Refresh the search box
    self.searchBox:SetText(self.pendingFilterData:GetDisplayName())

    --Refresh the tags dropdown
    self.tagsDropdown:ClearAllSelections()
    local tags = self.pendingFilterData:GetTags()
    for _, item in ipairs(self.tagsDropdown:GetItems()) do
        if ZO_IsElementInNumericallyIndexedTable(tags, item.tagValue) then
            local IGNORE_CALLBACK = true
            self.tagsDropdown:SelectItem(item, IGNORE_CALLBACK)
        end
    end

    --Refresh the house dropdown
    self.houseDropdown:ClearAllSelections()
    local houseIds = self.pendingFilterData:GetHouseIds()
    for _, item in ipairs(self.houseDropdown:GetItems()) do
        if ZO_IsElementInNumericallyIndexedTable(houseIds, item.houseId) then
            local IGNORE_CALLBACK = true
            self.houseDropdown:SelectItem(item, IGNORE_CALLBACK)
        end
    end

    --Refresh the house category dropdown
    self.houseCategoryDropdown:ClearAllSelections()
    local houseCategoryTypes = self.pendingFilterData:GetHouseCategoryTypes()
    for _, item in ipairs(self.houseCategoryDropdown:GetItems()) do
        if ZO_IsElementInNumericallyIndexedTable(houseCategoryTypes, item.categoryValue) then
            local IGNORE_CALLBACK = true
            self.houseCategoryDropdown:SelectItem(item, IGNORE_CALLBACK)
        end
    end
    self.houseCategoryDropdown:SetEnabled(self.pendingFilterData:CanSetHouseCategoryTypes())
end

function ZO_HouseToursSearchFiltersDialog_Keyboard:SavePendingChanges()
    self.filterData:CopyFrom(self.pendingFilterData)
end

function ZO_HouseToursSearchFiltersDialog_Keyboard:ResetFilters()
    self.pendingFilterData:ResetFilters()
    self:Refresh()
end

function ZO_HouseToursSearchFiltersDialog_Keyboard.OnControlInitialized(control)
    control.object = ZO_HouseToursSearchFiltersDialog_Keyboard:New(control)

    ZO_Dialogs_RegisterCustomDialog("HOUSE_TOURS_SEARCH_FILTERS_KEYBOARD",
    {
        customControl = control,
        setup = function(dialog, data)
            dialog.object:PerformDeferredInitialize()
            local filterData = data.filterData
            dialog.object:SetFilterData(filterData)
        end,
        title =
        {
            text = SI_HOUSE_TOURS_ALL_FILTERS,
        },
        buttons =
        {
            {
                control = control:GetNamedChild("Reset"),
                keybind = "DIALOG_RESET",
                text = SI_HOUSE_TOURS_RESET_FILTERS_KEYBIND,
                noReleaseOnClick = true,
                callback = function(dialog)
                    dialog.object:ResetFilters()
                end,
            },
            {
                control = control:GetNamedChild("Confirm"),
                keybind = "DIALOG_PRIMARY",
                text = SI_DIALOG_CONFIRM,
                callback = function(dialog)
                    dialog.object:SavePendingChanges()
                    if dialog.data.confirmCallback then
                        dialog.data:confirmCallback()
                    end
                end,
            },
            {
                control = control:GetNamedChild("Cancel"),
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },
        }
    })
end
