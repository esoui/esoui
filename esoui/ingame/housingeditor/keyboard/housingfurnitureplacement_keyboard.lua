ZO_HousingFurniturePlacement_Keyboard = ZO_HousingFurnitureList:Subclass()

function ZO_HousingFurniturePlacement_Keyboard:New(...)
    return ZO_HousingFurnitureList.New(self, ...)
end

function ZO_HousingFurniturePlacement_Keyboard:Initialize(...)
    ZO_HousingFurnitureList.Initialize(self, ...)
    self:InitializeFiltersSelector()
end

function ZO_HousingFurniturePlacement_Keyboard:InitializeKeybindStrip()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_HOUSING_EDITOR_PLACE),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local mostRecentlySelectedData = self:GetMostRecentlySelectedData()
                self:SelectForPlacement(mostRecentlySelectedData)
            end,
            enabled = function()
                local hasSelection = self:GetMostRecentlySelectedData() ~= nil
                if not hasSelection then
                    return false, GetString(SI_HOUSING_BROWSER_MUST_CHOOSE_TO_PLACE)
                end
                return true
            end,
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
    }
end

function ZO_HousingFurniturePlacement_Keyboard:InitializeFiltersSelector()
    self.placementFiltersDropdown = self.contents:GetNamedChild("FiltersDropdown")

    local filterValues = {}
    local function OnFiltersChanged(comboBox, entryText, entry)
        -- Initialize the filter value 'buckets' for bound and location both to the 'All' value,
        -- indicating that no filter has effectively been selected for either as a baseline.
        -- Note that the bound filterValues {0, 1, 2} are being treated as a bit mask for the
        -- purpose of this all-in-one drop down.
        filterValues[ZO_HOUSING_FURNITURE_FILTER_CATEGORY.BOUND] = HOUSING_FURNITURE_BOUND_FILTER_ALL
        filterValues[ZO_HOUSING_FURNITURE_FILTER_CATEGORY.LOCATION] = HOUSING_FURNITURE_LOCATION_FILTER_ALL
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

        -- Retrieve the cumulative bitmask for each bucket and update the placement filters accordingly.
        local boundFilterValue = filterValues[ZO_HOUSING_FURNITURE_FILTER_CATEGORY.BOUND]
        local locationFilterValue = filterValues[ZO_HOUSING_FURNITURE_FILTER_CATEGORY.LOCATION]
        local limitFilterValue = filterValues[ZO_HOUSING_FURNITURE_FILTER_CATEGORY.LIMIT]
        SHARED_FURNITURE:SetPlacementFurnitureFilters(boundFilterValue, locationFilterValue, limitFilterValue)
    end

    local INCLUDE_LOCATION_FILTERS = true
    ZO_HousingSettingsFilters_SetupDropdown(self.placementFiltersDropdown, INCLUDE_LOCATION_FILTERS, OnFiltersChanged)
end

function ZO_HousingFurniturePlacement_Keyboard:InitializeThemeSelector()
    self.placementThemeDropdown = self.contents:GetNamedChild("ThemeDropdown")

    local function OnThemeChanged(comboBox, entryText, entry)
        SHARED_FURNITURE:SetPlacementFurnitureTheme(entry.furnitureTheme)
    end

    ZO_HousingSettingsTheme_SetupDropdown(self.placementThemeDropdown, OnThemeChanged)
end

function ZO_HousingFurniturePlacement_Keyboard:OnSearchTextChanged(editBox)
    SHARED_FURNITURE:SetPlaceableTextFilter(editBox:GetText())
end

function ZO_HousingFurniturePlacement_Keyboard:AddListDataTypes()
    local function IsFurnitureCollectibleBlacklisted(collectibleId)
        if collectibleId then
            local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
            return collectibleData and collectibleData:IsBlacklisted()
        end
        return false
    end

    self.PlaceableFurnitureOnMouseClickCallback = function(control, buttonIndex, upInside)
        if buttonIndex == MOUSE_BUTTON_INDEX_LEFT and upInside then
            if control.furnitureObject and IsFurnitureCollectibleBlacklisted(control.furnitureObject.collectibleId) then
                ZO_AlertEvent(EVENT_HOUSING_EDITOR_REQUEST_RESULT, HOUSING_REQUEST_RESULT_BLOCKED_BY_BLACKLISTED_COLLECTIBLE)
            else
                ZO_ScrollList_MouseClick(self:GetList(), control)
            end
        end
    end

    self.PlaceableFurnitureOnMouseDoubleClickCallback = function(control, buttonIndex)
        if buttonIndex == MOUSE_BUTTON_INDEX_LEFT then
            if control.furnitureObject and IsFurnitureCollectibleBlacklisted(control.furnitureObject.collectibleId) then
                ZO_AlertEvent(EVENT_HOUSING_EDITOR_REQUEST_RESULT, HOUSING_REQUEST_RESULT_BLOCKED_BY_BLACKLISTED_COLLECTIBLE)
            else
                local data = ZO_ScrollList_GetData(control)
                self:SelectForPlacement(data)
            end
        end
    end

    self:AddDataType(ZO_PLACEABLE_HOUSING_DATA_TYPE, "ZO_PlayerFurnitureSlot", ZO_HOUSING_FURNITURE_LIST_ENTRY_HEIGHT, function(...) self:SetupFurnitureRow(...) end, ZO_HousingFurnitureBrowser_Keyboard.OnHideFurnitureRow)
end

function ZO_HousingFurniturePlacement_Keyboard:RefreshFilters()
    -- Get the current filter state.
    local boundFilters = SHARED_FURNITURE:GetPlacementFurnitureBoundFilters()
    local limitFilters = SHARED_FURNITURE:GetPlacementFurnitureLimitFilters()
    local locationFilters = SHARED_FURNITURE:GetPlacementFurnitureLocationFilters()
    local textFilter = SHARED_FURNITURE:GetPlaceableTextFilter()
    local themeFilter = SHARED_FURNITURE:GetPlacementFurnitureTheme()

    -- Update the Text Search filter to reflect the filter state.
    self.searchEditBox:SetText(textFilter)

    -- Update the Theme filter to reflect the filter state.
    do
        local themesList = ZO_ComboBox_ObjectFromContainer(self.placementThemeDropdown)
        for _, themeItem in ipairs(themesList:GetItems()) do
            if themeItem.furnitureTheme == themeFilter then
                themesList:SelectItem(themeItem)
                break
            end
        end
    end

    -- Update the Furniture filters to reflect the filter state.
    do
        local filtersList = ZO_ComboBox_ObjectFromContainer(self.placementFiltersDropdown)
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
            elseif filterItem.filterCategory == ZO_HOUSING_FURNITURE_FILTER_CATEGORY.LOCATION then
                if ZO_FlagHelpers.MaskHasFlag(locationFilters, filterItem.filterValue) then
                    filtersList:SelectItem(filterItem)
                end
            end
        end
    end
end

function ZO_HousingFurniturePlacement_Keyboard:SelectForPlacement(data)
    ZO_HousingFurnitureBrowser_Base.SelectFurnitureForPlacement(data)
    SCENE_MANAGER:HideCurrentScene()
end

function ZO_HousingFurniturePlacement_Keyboard:SetupFurnitureRow(control, data)
    ZO_HousingFurnitureBrowser_Keyboard.SetupFurnitureRow(control, data, self.PlaceableFurnitureOnMouseClickCallback, self.PlaceableFurnitureOnMouseDoubleClickCallback)
end

--Overridden from ZO_HousingFurnitureList
function ZO_HousingFurniturePlacement_Keyboard:OnShowing()
    ZO_HousingFurnitureList.OnShowing(self)
    self:RefreshFilters()
end

--Overridden from ZO_HousingFurnitureList
function ZO_HousingFurniturePlacement_Keyboard:GetCategoryTreeData()
    return SHARED_FURNITURE:GetPlaceableFurnitureCategoryTreeData()
end

--Overridden from ZO_HousingFurnitureList
function ZO_HousingFurniturePlacement_Keyboard:GetNoItemText()
    if SHARED_FURNITURE:DoesPlayerHavePlaceableFurniture() then
        return GetString(SI_HOUSING_FURNITURE_NO_SEARCH_RESULTS)
    else
        return GetString(SI_HOUSING_FURNITURE_NO_PLACEABLE_FURNITURE)
    end
end