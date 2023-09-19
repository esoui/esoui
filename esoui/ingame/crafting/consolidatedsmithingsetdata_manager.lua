
---------------------------------------------
-- Consolidated Smithing Set Category Data --
---------------------------------------------

ZO_ConsolidatedSmithingSetCategoryData = ZO_InitializingObject:Subclass()

function ZO_ConsolidatedSmithingSetCategoryData:Initialize(categoryId)
    self.categoryId = categoryId
    self.sets = {}
end

function ZO_ConsolidatedSmithingSetCategoryData:AddSetData(setData)
    setData:SetParentCategoryData(self)
    table.insert(self.sets, setData)
end

function ZO_ConsolidatedSmithingSetCategoryData:GetSetData()
    return self.sets
end

function ZO_ConsolidatedSmithingSetCategoryData:GetId()
    return self.categoryId
end

function ZO_ConsolidatedSmithingSetCategoryData:GetName()
    return GetItemSetCollectionCategoryName(self.categoryId)
end

function ZO_ConsolidatedSmithingSetCategoryData:GetFormattedName()
    return zo_strformat(SI_ITEM_SET_CATEGORY_NAME_FORMATTER, self:GetName())
end

function ZO_ConsolidatedSmithingSetCategoryData:GetKeyboardIcons()
    return GetItemSetCollectionCategoryKeyboardIcons(self.categoryId)
end

function ZO_ConsolidatedSmithingSetCategoryData:GetGamepadIcon()
    return GetItemSetCollectionCategoryGamepadIcon(self.categoryId)
end

function ZO_ConsolidatedSmithingSetCategoryData:GetOrder()
    return GetItemSetCollectionCategoryOrder(self.categoryId)
end

function ZO_ConsolidatedSmithingSetCategoryData:GetNumSets()
    return #self.sets
end

function ZO_ConsolidatedSmithingSetCategoryData:GetNumUnlockedSets()
    local unlockedSets = 0
    for _, setData in self:SetIterator() do
        if setData:IsUnlocked() then
            unlockedSets = unlockedSets + 1
        end
    end

    return unlockedSets
end

function ZO_ConsolidatedSmithingSetCategoryData:GetSetDataByItemSetId(itemSetId)
    for _, setData in self:SetIterator() do
        if setData:GetItemSetId() == itemSetId then
            return setData
        end
    end
end

function ZO_ConsolidatedSmithingSetCategoryData:SetIterator(filterFunctions)
    return ZO_FilteredNumericallyIndexedTableIterator(self.sets, filterFunctions)
end

function ZO_ConsolidatedSmithingSetCategoryData:AnyChildPassesFilters(filterFunctions)
    for _, setData in self:SetIterator(filterFunctions) do
        return true
    end
    return false
end

function ZO_ConsolidatedSmithingSetCategoryData:Equals(otherConsolidatedSmithingSetCategoryData)
    return self:GetId() == otherConsolidatedSmithingSetCategoryData:GetId()
end

function ZO_ConsolidatedSmithingSetCategoryData:CompareTo(otherConsolidatedSmithingSetCategoryData)
    if self:IsInstanceOf(ZO_ConsolidatedSmithingDefaultCategoryData) then
        return not otherConsolidatedSmithingSetCategoryData:IsInstanceOf(ZO_ConsolidatedSmithingDefaultCategoryData)
    end
    local order = self:GetOrder()
    local otherOrder = otherConsolidatedSmithingSetCategoryData:GetOrder()
    return order < otherOrder or (order == otherOrder and self:GetName() < otherConsolidatedSmithingSetCategoryData:GetName())
end

function ZO_ConsolidatedSmithingSetCategoryData:SortSets()
    table.sort(self.sets, ZO_ConsolidatedSmithingSetData.CompareTo)
end

function ZO_ConsolidatedSmithingSetCategoryData:SetSearchResultsVersion(searchResultsVersion)
    self.searchResultsVersion = searchResultsVersion
end

function ZO_ConsolidatedSmithingSetCategoryData:IsSearchResult()
    if self.searchResultsVersion then
        if self.searchResultsVersion == CONSOLIDATED_SMITHING_SET_DATA_MANAGER:GetSearchResultsVersion() then
            return true
        else
            -- Old search result, might as well clean it up while we're here
            self.searchResultsVersion = nil
        end
    end
    return false
end

-------------------------------------------------
-- Consolidated Smithing Default Category Data --
-------------------------------------------------

ZO_ConsolidatedSmithingDefaultCategoryData = ZO_ConsolidatedSmithingSetCategoryData:Subclass()

function ZO_ConsolidatedSmithingDefaultCategoryData:GetName()
    return GetString(SI_SMITHING_CONSOLIDATED_STATION_DEFAULT_CATEGORY_NAME)
end

function ZO_ConsolidatedSmithingDefaultCategoryData:GetKeyboardIcons()
    local UP_ICON = "EsoUI/Art/Crafting/smithing_tabIcon_creation_up.dds"
    local DOWN_ICON = "EsoUI/Art/Crafting/smithing_tabIcon_creation_down.dds"
    local OVER_ICON = "EsoUI/Art/Crafting/smithing_tabIcon_creation_over.dds"
    return UP_ICON, DOWN_ICON, OVER_ICON
end

function ZO_ConsolidatedSmithingDefaultCategoryData:GetGamepadIcon()
    return "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_create.dds"
end

function ZO_ConsolidatedSmithingDefaultCategoryData:AnyChildPassesFilters(filterFunctions)
    --Ensure that the default category appears in the list despite having no valid children.
    return true
end

--This is a special pseudo-category that represents the "No Item Set" option
local DEFAULT_CATEGORY_ID = 0
CONSOLIDATED_SMITHING_DEFAULT_CATEGORY_DATA = ZO_ConsolidatedSmithingDefaultCategoryData:New(DEFAULT_CATEGORY_ID)

------------------------------------
-- Consolidated Smithing Set Data --
------------------------------------

ZO_ConsolidatedSmithingSetData = ZO_InitializingObject:Subclass()

function ZO_ConsolidatedSmithingSetData:Initialize(setIndex)
    self.setIndex = setIndex
end

function ZO_ConsolidatedSmithingSetData:GetSetIndex()
    return self.setIndex
end

function ZO_ConsolidatedSmithingSetData:GetItemSetId()
    return GetConsolidatedSmithingItemSetIdByIndex(self.setIndex)
end

function ZO_ConsolidatedSmithingSetData:GetCategoryId()
    return GetItemSetCollectionCategoryId(self:GetItemSetId())
end

function ZO_ConsolidatedSmithingSetData:GetRawName()
    return GetItemSetName(self:GetItemSetId())
end

function ZO_ConsolidatedSmithingSetData:GetFormattedName()
    return zo_strformat(SI_ITEM_SET_NAME_FORMATTER, self:GetRawName())
end

function ZO_ConsolidatedSmithingSetData:IsUnlocked()
    return IsConsolidatedSmithingSetIndexUnlocked(self.setIndex)
end

function ZO_ConsolidatedSmithingSetData:CompareTo(otherConsolidatedSmithingSetData)
    return self:GetRawName() < otherConsolidatedSmithingSetData:GetRawName()
end

function ZO_ConsolidatedSmithingSetData:SetParentCategoryData(categoryData)
    self.parentCategoryData = categoryData
end

function ZO_ConsolidatedSmithingSetData:SetSearchResultsVersion(searchResultsVersion)
    self.searchResultsVersion = searchResultsVersion
    self.parentCategoryData:SetSearchResultsVersion(searchResultsVersion)
end

function ZO_ConsolidatedSmithingSetData:IsSearchResult()
    if self.searchResultsVersion then
        if self.searchResultsVersion == CONSOLIDATED_SMITHING_SET_DATA_MANAGER:GetSearchResultsVersion() then
            return true
        else
            -- Old search result, might as well clean it up while we're here
            self.searchResultsVersion = nil
        end
    end
    return false
end


--------------------------------------------
-- Consolidated Smithing Set Data Manager --
--------------------------------------------

ZO_ConsolidatedSmithingSetData_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_ConsolidatedSmithingSetData_Manager:Initialize()
    self.sortedCategoryData = {}
    self.categoryDataByCategoryId = {}
    self.setDataBySetId = {}
    self.searchString = ""
    self.searchResultsVersion = 0

    self:MarkDirty()
    self:RegisterForEvents()
end

function ZO_ConsolidatedSmithingSetData_Manager:RegisterForEvents()
    EVENT_MANAGER:RegisterForEvent("ConsolidatedSmithingSetDataManager", EVENT_CRAFTING_STATION_INTERACT, function() self:CleanDirty() end)
    EVENT_MANAGER:RegisterForEvent("ConsolidatedSmithingSetDataManager", EVENT_CONSOLIDATED_SMITHING_ITEM_SET_SEARCH_RESULTS_READY, function() self:UpdateSearchResults() end)
end

function ZO_ConsolidatedSmithingSetData_Manager:GetOrCreateConsolidatedSmithingSetCategoryData(categoryId)
    if categoryId and categoryId ~= 0 then
        local categoryData = self.categoryDataByCategoryId[categoryId]
        if not categoryData then
            categoryData = ZO_ConsolidatedSmithingSetCategoryData:New(categoryId)
            self.categoryDataByCategoryId[categoryId] = categoryData
            table.insert(self.sortedCategoryData, categoryData)
        end

        return categoryData
    end
end

function ZO_ConsolidatedSmithingSetData_Manager:RebuildCategories()
    ZO_ClearNumericallyIndexedTable(self.sortedCategoryData)
    ZO_ClearTable(self.categoryDataByCategoryId)
    ZO_ClearTable(self.setDataBySetId)

    --Sort each set into their proper categories
    for setIndex = 1, GetNumConsolidatedSmithingSets() do
        local setData = ZO_ConsolidatedSmithingSetData:New(setIndex)
        local categoryId = setData:GetCategoryId()

        if categoryId ~= 0 then
            local categoryData = self:GetOrCreateConsolidatedSmithingSetCategoryData(categoryId)
            categoryData:AddSetData(setData)
            self.setDataBySetId[setData:GetItemSetId()] = setData
        else
            --All crafted sets require a category in order to work
            internalassert(false, string.format("No category set for ItemSetDef %d", setData:GetItemSetId()))
        end
    end

    table.sort(self.sortedCategoryData, ZO_ConsolidatedSmithingSetCategoryData.CompareTo)

    for _, categoryData in ipairs(self.sortedCategoryData) do
        categoryData:SortSets()
    end

    --If we currently have a search filter, make sure the search results get refreshed too
    if self:HasSearchFilter() then
        self:UpdateSearchResults()
    end
end

function ZO_ConsolidatedSmithingSetData_Manager:MarkDirty()
    self.dirty = true
end

function ZO_ConsolidatedSmithingSetData_Manager:CleanDirty()
    --The data necessary to set up the categories is only available when at consolidated stations, so don't attempt to rebuild if we aren't at one
    if self.dirty and ZO_Smithing_IsConsolidatedStationCraftingMode() then
        self:RebuildCategories()
        self.dirty = false
    end
end

function ZO_ConsolidatedSmithingSetData_Manager:GetSortedCategories()
    self:CleanDirty()
    return self.sortedCategoryData
end

function ZO_ConsolidatedSmithingSetData_Manager:DoesPlayerHaveValidAttunableCraftingStationToConsume()
    local allSetsUnlocked = GetNumUnlockedConsolidatedSmithingSets() == GetNumConsolidatedSmithingSets()
    if allSetsUnlocked then
        return false
    end

    local virtualInventoryList = PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BACKPACK, CanItemBeConsumedByConsolidatedStation)
    return not ZO_IsTableEmpty(virtualInventoryList)
end

-- Search
function ZO_ConsolidatedSmithingSetData_Manager:SetSearchString(searchString)
    self.searchString = searchString or ""
    StartConsolidatedSmithingItemSetSearch(self.searchString)
end

function ZO_ConsolidatedSmithingSetData_Manager:UpdateSearchResults()
    self.searchResultsVersion = self.searchResultsVersion + 1

    for i = 1, GetNumConsolidatedSmithingItemSetSearchResults() do
        local itemSetId = GetConsolidatedSmithingItemSetSearchResult(i)
        local setData = self.setDataBySetId[itemSetId]
        if setData then
            setData:SetSearchResultsVersion(self.searchResultsVersion)
        end
    end

    self:FireCallbacks("UpdateSearchResults")
end

function ZO_ConsolidatedSmithingSetData_Manager:GetSearchResultsVersion()
    return self.searchResultsVersion
end

function ZO_ConsolidatedSmithingSetData_Manager:HasSearchFilter()
    return zo_strlen(self.searchString) > 1
end

CONSOLIDATED_SMITHING_SET_DATA_MANAGER = ZO_ConsolidatedSmithingSetData_Manager:New()