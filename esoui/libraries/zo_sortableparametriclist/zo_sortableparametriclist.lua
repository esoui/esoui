--[[
This class allows a parametric list to have sort headers to allow the user to change how the list is sorted

To setup, your main control needs to have a "Headers" child that has all the sort headers and 
a "List" child that defines the scroll list

The children of "Headers" should have their OnInitialized call ZO_SortableParametricList_InitSortHeader 
(or other init sort header function) passing in the sortKey that header will use
ex: ZO_SortableParametricList_InitSortHeader(self, SI_LABEL_GOES_HERE, TEXT_ALIGN_LEFT, MY_SORT_KEY_NAME)

To associate the data in the list with the sortKeys in the header, the function SetSortOptions needs to be called,
passing in a table where the sortKeys used to initialize the headers are the table key and the value is a table
the defines the list's sort options for that key

in this ex. both name and price are members of the list data

local NAME_SORT_KEYS =
{
    name = {tiebreaker = "price"},
    price = {}
}

local PRICE_SORT_KEYS =
{
    price = {tiebreaker = "name"},
    name = {}
}

local tradingHouseSortOptions = {
    [MY_SORT_KEY_NAME] = NAME_SORT_KEYS,
    [MY_SORT_KEY_PRICE] = PRICE_SORT_KEYS,
}

self:SetSortOptions(tradingHouseSortOptions)

Once the sorting is setup, you just need to create a BuildList() function in your derived class to populate the list

]]

ZO_SortableParametricList = ZO_SortFilterListBase:Subclass()

function ZO_SortableParametricList:New(...)
    return ZO_SortFilterListBase.New(self, ...)
end

function ZO_SortableParametricList:Initialize(control, useHighlight)
    ZO_SortFilterListBase.Initialize(self, control, useHighlight)
    self.control = control

    local headerContainer = GetControl(control, "Headers")
    self.sortHeaderGroup = ZO_SortHeaderGroup:New(headerContainer, true)
    self.sortHeaderGroup:RegisterCallback(ZO_SortHeaderGroup.HEADER_CLICKED, function(key, order) self:OnSortHeaderClicked(key, order) end)
    if useHighlight then
        self.sortHeaderGroup:EnableHighlight("ZO_Gamepad_TradingHouse_Highlight")
    end
    self.sortHeaderGroup:AddHeadersFromContainer()

    self.listControl = GetControl(control, "List")
    self.itemList = ZO_GamepadVerticalItemParametricScrollList:New(self.listControl)
    self:InitializeList()
end

function ZO_SortableParametricList:SetSortOptions(sortOptions)
    self.sortOptions = sortOptions
    self:UpdateSortOption()
end

function ZO_SortableParametricList:Activate()
    self.sortHeaderGroup:SetDirectionalInputEnabled(true)
    self.sortHeaderGroup:EnableSelection(true)
    self.itemList:Activate()
end

function ZO_SortableParametricList:Deactivate()
   self.sortHeaderGroup:SetDirectionalInputEnabled(false)
   self.sortHeaderGroup:EnableSelection(false)
   self.itemList:Deactivate()
end

function ZO_SortableParametricList:OnSortHeaderClicked(key, order)
    self:RefreshSort()
end

function ZO_SortableParametricList:SortFunc(data1, data2)
    return ZO_TableOrderingFunction(data1, data2, self.sortKey, self.currentSortOption, self.sortOrder)
end

function ZO_SortableParametricList:UpdateListSortFunction()
    if self.currentSortOption then
        if not self.itemList.sortFunction then
            self.itemList:SetSortFunction(function(data1, data2) return self:SortFunc(data1, data2) end)
        end
    else
        self.itemList:SetSortFunction(nil)
    end
end

function ZO_SortableParametricList:UpdateSortOption()
    self.currentSortOption = nil
    if self.sortOptions then
        self.sortKey = self.sortHeaderGroup:GetCurrentSortKey()
        if self.sortKey then
            self.sortOrder = self.sortHeaderGroup:GetSortDirection()
            self.currentSortOption = self.sortOptions[self.sortKey]
        end
    end

    self:UpdateListSortFunction()
end

function ZO_SortableParametricList:GetList()
    return self.itemList
end

-- Funtions that wrap functions in ZO_SortHeaderGroup

function ZO_SortableParametricList:SortBySelected()
    self.sortHeaderGroup:SortBySelected()
end

function ZO_SortableParametricList:SelectHeaderByKey(key)
    self.sortHeaderGroup:SelectHeaderByKey(key)
end

function ZO_SortableParametricList:SelectAndResetSortForKey(key)
    self.sortHeaderGroup:SelectAndResetSortForKey(key)
end

function ZO_SortableParametricList:SetHeaderNameForKey(key, name)
    return self.sortHeaderGroup:SetHeaderNameForKey(key, name)
end

function ZO_SortableParametricList:ReplaceKey(curKey, newKey, newText, selectNewKey)
    self.sortHeaderGroup:ReplaceKey(curKey, newKey, newText, selectNewKey)
end

-- Functions that wrap functions in ZO_ParametricScrollList

function ZO_SortableParametricList:CommitList(dontReselect)
    if dontReselect == nil then
        dontReselect = true
    end

    self.itemList:Commit(dontReselect)
end

function ZO_SortableParametricList:ClearList()
    self.itemList:Clear()
end

-- ZO_SortFilterListBase overridden functions

function ZO_SortableParametricList:RefreshVisible()
    self.itemList:RefreshVisible()
end

function ZO_SortableParametricList:RefreshSort()
    self:UpdateSortOption()
    if self.currentSortOption then
        self:CommitList()
    end
end

function ZO_SortableParametricList:RefreshFilters()
    --- No Filters
end

function ZO_SortableParametricList:RefreshData(dontReselect)
    self:ClearList()
    self:BuildList()
    self:CommitList(dontReselect)
end

-- Functions to be overridden

function ZO_SortableParametricList:InitializeList()
    --- should be overridden to call AddDataTemplate & handle needed callbacks
end

function ZO_SortableParametricList:BuildList()
    -- intended to be overridden
    -- should populate the itemList by calling AddEntry
end

-- Globals

function ZO_SortableParametricList_InitSortHeader(header, stringId, textAlignment, sortKey)
    ZO_SortHeader_Initialize(header, GetString(stringId), sortKey, ZO_SORT_ORDER_UP, textAlignment or TEXT_ALIGN_LEFT)
end