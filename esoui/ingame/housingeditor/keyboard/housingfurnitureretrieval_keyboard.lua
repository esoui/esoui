ZO_HousingFurnitureRetrieval_Keyboard = ZO_HousingFurnitureList:Subclass()

function ZO_HousingFurnitureRetrieval_Keyboard:New(...)
    return ZO_HousingFurnitureList.New(self, ...)
end

function ZO_HousingFurnitureRetrieval_Keyboard:Initialize(...)
    ZO_HousingFurnitureList.Initialize(self, ...)

    self.CompareRetrievableEntriesFunction = function(a, b)
        return a.data:CompareTo(b.data)
    end

    self:InitializeFiltersSelector()
end

function ZO_HousingFurnitureRetrieval_Keyboard:InitializeKeybindStrip()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_HOUSING_EDITOR_MODIFY),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local mostRecentlySelectedData = self:GetMostRecentlySelectedData()
                self:Retrieve(mostRecentlySelectedData)
            end,
            enabled = function()
                local isSelectionEmpty = self:GetMostRecentlySelectedData() == nil
                if isSelectionEmpty then
                    return false, GetString(SI_HOUSING_BROWSER_MUST_CHOOSE_TO_MODIFY)
                end
                return true
            end,
            visible = function()
                return HOUSING_EDITOR_STATE:CanLocalPlayerEditHouse()
            end
        },
        {
            name = function()
                local mostRecentlySelectedData = self:GetMostRecentlySelectedData()
                if mostRecentlySelectedData and mostRecentlySelectedData:GetDataType() == ZO_HOUSING_PATH_NODE_DATA_TYPE then
                    return GetString(SI_HOUSING_EDITOR_PATH_REMOVE_NODE)
                else
                    return GetString(SI_HOUSING_EDITOR_PUT_AWAY)
                end
            end,
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                local mostRecentlySelectedData = self:GetMostRecentlySelectedData()
                if mostRecentlySelectedData:GetDataType() == ZO_RECALLABLE_HOUSING_DATA_TYPE then
                    ZO_HousingFurnitureBrowser_Base.PutAwayFurniture(mostRecentlySelectedData)
                else
                    ZO_HousingFurnitureBrowser_Base.PutAwayNode(mostRecentlySelectedData)
                end
            end,
            enabled = function()
                local isSelectionEmpty = self:GetMostRecentlySelectedData() == nil
                if isSelectionEmpty then
                    return false, GetString(SI_HOUSING_BROWSER_MUST_CHOOSE_TO_PUT_AWAY)
                end
                return true
            end,
            visible = function()
                local mostRecentlySelectedData = self:GetMostRecentlySelectedData()
                if mostRecentlySelectedData and mostRecentlySelectedData:GetDataType() == ZO_HOUSING_PATH_NODE_DATA_TYPE then
                    return HOUSING_EDITOR_STATE:CanLocalPlayerEditHouse()
                else
                    return HOUSING_EDITOR_STATE:IsLocalPlayerHouseOwner()
                end
            end,
        },
        {
            name = GetString(SI_WORLD_MAP_ACTION_SET_PLAYER_WAYPOINT),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                local mostRecentlySelectedData = self:GetMostRecentlySelectedData()
                SHARED_FURNITURE:SetPlayerWaypointTo(mostRecentlySelectedData)
            end,
            enabled = function()
                local recentlySelectedData = self:GetMostRecentlySelectedData()
                local isSelectionEmpty = recentlySelectedData == nil
                if isSelectionEmpty then
                    return false, GetString(SI_HOUSING_BROWSER_MUST_CHOOSE_TO_SET_PLAYER_WAYPOINT)
                end
                local dataType = recentlySelectedData:GetDataType()
                return dataType == ZO_RECALLABLE_HOUSING_DATA_TYPE or dataType == ZO_HOUSING_PATH_NODE_DATA_TYPE
            end
        },
        {
            name = GetString(SI_HOUSING_EDITOR_PRECISION_EDIT),
            keybind = "UI_SHORTCUT_QUINARY",
            callback = function()
                local mostRecentlySelectedData = self:GetMostRecentlySelectedData()
                self:PrecisionEdit(mostRecentlySelectedData)
            end,
            enabled = function()
                local isSelectionEmpty = self:GetMostRecentlySelectedData() == nil
                if isSelectionEmpty then
                    return false, GetString(SI_HOUSING_BROWSER_MUST_CHOOSE_TO_MODIFY)
                end
                return true
            end,
            visible = function()
                return HOUSING_EDITOR_STATE:CanLocalPlayerEditHouse()
            end
        },
        {
            name = GetString(SI_CRAFTING_EXIT_PREVIEW_MODE),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                self:ClearSelection()
            end,
            visible = function()
                local hasSelection = self:GetMostRecentlySelectedData() ~= nil and IsCurrentlyPreviewing()
                return hasSelection
            end,
        },
        {
            name = GetString(SI_HOUSING_FURNITURE_SET_STARTING_NODE),
            keybind = "UI_SHORTCUT_QUATERNARY",
            callback = function()
                local recentlySelectedData = self:GetMostRecentlySelectedData()
                ZO_HousingFurnitureBrowser_Base.SetAsStartingNode(recentlySelectedData)
            end,
            visible = function()
                local recentlySelectedData = self:GetMostRecentlySelectedData()
                return recentlySelectedData and recentlySelectedData:GetDataType() == ZO_HOUSING_PATH_NODE_DATA_TYPE and not recentlySelectedData:IsStartingPathNode() and HOUSING_EDITOR_STATE:CanLocalPlayerEditHouse()
            end,
        },
    }
end

function ZO_HousingFurnitureRetrieval_Keyboard:InitializeFiltersSelector()
    self.retrievalFiltersDropdown = self.contents:GetNamedChild("FiltersDropdown")

    local filterValues = {}
    local function OnFiltersChanged(comboBox, entryText, entry)
        -- Initialize the filter value 'buckets' for bound and location both to the 'All' value,
        -- indicating that no filter has effectively been selected for either as a baseline.
        -- Note that the bound filterValues {0, 1, 2} are being treated as a bit mask for the
        -- purpose of this all-in-one drop down.
        filterValues[ZO_HOUSING_FURNITURE_FILTER_CATEGORY.BOUND] = HOUSING_FURNITURE_BOUND_FILTER_ALL
        filterValues[ZO_HOUSING_FURNITURE_FILTER_CATEGORY.LIMIT] = ZO_HOUSING_FURNITURE_LIMIT_TYPE_FILTER_ALL

        -- Iterate through the drop down items, adding each selected items' filterValues to their
        -- respective bound or location bucket.
        -- Because the initial 'All' value for either bucket acts as a non-selection, the addition
        -- operations occuring below are effectively expressions of the mathematical Identity property
        -- whereby 0 + x = x.
        local selectedItems = comboBox:GetSelectedItemData()
        for _, item in ipairs(selectedItems) do
            local filterCategory = item.filterCategory
            if filterCategory then
                filterValues[filterCategory] = filterValues[filterCategory] + item.filterValue
            end
        end

        -- Retrieve the cumulative bitmask for each bucket and update the retrievable filters accordingly.
        local boundFilterValue = filterValues[ZO_HOUSING_FURNITURE_FILTER_CATEGORY.BOUND]
        local limitFilterValue = filterValues[ZO_HOUSING_FURNITURE_FILTER_CATEGORY.LIMIT]
        SHARED_FURNITURE:SetRetrievableFurnitureFilters(boundFilterValue, limitFilterValue)
    end

    local EXCLUDE_LOCATION_FILTERS = false
    ZO_HousingSettingsFilters_SetupDropdown(self.retrievalFiltersDropdown, EXCLUDE_LOCATION_FILTERS, OnFiltersChanged)
end

function ZO_HousingFurnitureRetrieval_Keyboard:OnSearchTextChanged(editBox)
    SHARED_FURNITURE:SetRetrievableTextFilter(editBox:GetText())
end

function ZO_HousingFurnitureRetrieval_Keyboard:AddListDataTypes()
    self.RetrievableFurnitureOnMouseClick = function(control, buttonIndex, upInside)
        if buttonIndex == MOUSE_BUTTON_INDEX_LEFT and upInside then
            ZO_ScrollList_MouseClick(self:GetList(), control)
        end
    end

    self.RetrievableFurnitureOnMouseDoubleClick = function(control, buttonIndex)
        if buttonIndex == MOUSE_BUTTON_INDEX_LEFT then
        local data = ZO_ScrollList_GetData(control)
            self:Retrieve(data)
        end
    end

    self:AddDataType(ZO_RECALLABLE_HOUSING_DATA_TYPE, "ZO_RetrievableFurnitureSlot", ZO_HOUSING_FURNITURE_LIST_ENTRY_HEIGHT, function(...) self:SetupRetrievableFurnitureRow(...) end, ZO_HousingFurnitureBrowser_Keyboard.OnHideFurnitureRow)
    self:AddDataType(ZO_HOUSING_PATH_NODE_DATA_TYPE, "ZO_RetrievableFurnitureSlot", ZO_HOUSING_FURNITURE_LIST_ENTRY_HEIGHT, function(...) self:SetupRetrievableFurnitureRow(...) end, ZO_HousingFurnitureBrowser_Keyboard.OnHideFurnitureRow)
end

function ZO_HousingFurnitureRetrieval_Keyboard:RefreshFilters()
    -- Get the current filter state.
    local boundFilters = SHARED_FURNITURE:GetRetrievableFurnitureBoundFilters()
    local limitFilters = SHARED_FURNITURE:GetRetrievableFurnitureLimitFilters()
    local textFilter = SHARED_FURNITURE:GetRetrievableTextFilter()

    -- Update the Text Search filter to reflect the filter state.
    self.searchEditBox:SetText(textFilter)

    if HOUSING_EDITOR_STATE:IsHousePreview() then
        self.retrievalFiltersDropdown:SetHidden(true)
    else
        -- Update the Furniture filters to reflect the filter state.
        local filtersList = ZO_ComboBox_ObjectFromContainer(self.retrievalFiltersDropdown)
        filtersList:ClearAllSelections()
        for _, filterItem in ipairs(filtersList:GetItems()) do
            if filterItem.filterCategory == ZO_HOUSING_FURNITURE_FILTER_CATEGORY.BOUND then
                if ZO_FlagHelpers.MaskHasFlag(boundFilters, filterItem.filterValue) then
                    filtersList:SelectItem(filterItem)
                end
            elseif filterItem.filterCategory == ZO_HOUSING_FURNITURE_FILTER_CATEGORY.LIMIT then
                if ZO_FlagHelpers.MaskHasFlag(limitFilters, filterItem.filterValue) then
                    filtersList:SelectItem(filterItem)
                end
            end
        end

        self.retrievalFiltersDropdown:SetHidden(false)
    end
end

function ZO_HousingFurnitureRetrieval_Keyboard:Retrieve(data)
    if data:GetDataType() == ZO_HOUSING_PATH_NODE_DATA_TYPE then
        ZO_HousingFurnitureBrowser_Base.SelectNodeForReplacement(data)
    else
        ZO_HousingFurnitureBrowser_Base.SelectFurnitureForReplacement(data)
    end
    SCENE_MANAGER:HideCurrentScene()
end

function ZO_HousingFurnitureRetrieval_Keyboard:PrecisionEdit(data)
    if data:GetDataType() == ZO_HOUSING_PATH_NODE_DATA_TYPE then
        ZO_HousingFurnitureBrowser_Base.SelectNodeForPrecisionEdit(data)
    else
        ZO_HousingFurnitureBrowser_Base.SelectFurnitureForPrecisionEdit(data)
    end
    SCENE_MANAGER:HideCurrentScene()
end

function ZO_HousingFurnitureRetrieval_Keyboard:SetupRetrievableFurnitureRow(control, data)
    ZO_HousingFurnitureBrowser_Keyboard.SetupFurnitureRow(control, data, self.RetrievableFurnitureOnMouseClick, self.RetrievableFurnitureOnMouseDoubleClick)

    local distanceLabel = control:GetNamedChild("Distance")
    distanceLabel:SetText(zo_strformat(SI_HOUSING_BROWSER_DISTANCE_AWAY_FORMAT, data:GetDistanceFromPlayerM()))

    local directionTexture = control:GetNamedChild("Direction")
    directionTexture:SetTextureRotation(data:GetAngleFromPlayerHeadingRadians())
end

--Overridden from ZO_HousingFurnitureList
function ZO_HousingFurnitureRetrieval_Keyboard:OnShowing()
    ZO_HousingFurnitureList.OnShowing(self)
    self:RefreshFilters()
end

--Overridden from ZO_HousingFurnitureList
function ZO_HousingFurnitureRetrieval_Keyboard:GetCategoryTreeData()
    return SHARED_FURNITURE:GetRetrievableFurnitureCategoryTreeData()
end

--Overridden from ZO_HousingFurnitureList
function ZO_HousingFurnitureRetrieval_Keyboard:GetNoItemText()
    if SHARED_FURNITURE:DoesPlayerHaveRetrievableFurniture() then
        return GetString(SI_HOUSING_FURNITURE_NO_SEARCH_RESULTS)
    else
        return GetString(SI_HOUSING_FURNITURE_NO_RETRIEVABLE_FURNITURE)
    end
end

--Overridden from ZO_HousingFurnitureList
function ZO_HousingFurnitureRetrieval_Keyboard:CompareFurnitureEntries(a, b)
    return a:CompareTo(b)
end

--Overridden from ZO_HousingFurnitureList
function ZO_HousingFurnitureRetrieval_Keyboard:OnCategorySelected(data)
    local mostRecentlySelectedData = self:GetMostRecentlySelectedData()
    if mostRecentlySelectedData and mostRecentlySelectedData:GetDataType() == ZO_HOUSING_PATH_NODE_DATA_TYPE then
        self:ClearSelection()
    end
    ZO_HousingFurnitureList.OnCategorySelected(self, data)
end