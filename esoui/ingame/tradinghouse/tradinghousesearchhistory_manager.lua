local TRADING_HOUSE_SEARCH_HISTORY_MAX_SEARCHES = 50

ZO_TradingHouseSearchHistory_Manager = ZO_CallbackObject:Subclass()

function ZO_TradingHouseSearchHistory_Manager:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_TradingHouseSearchHistory_Manager:Initialize()
    local function OnAddOnLoaded(event, name)
        if name == "ZO_Ingame" then
            local DEFAULTS = { searchEntries = {}, nextSearchOrderId = 0 }
            self.savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 2, "TradingHouseSearchHistory", DEFAULTS)
            self.searchEntries = self.savedVars.searchEntries -- convenience field

            self:RemoveInvalidSearchEntries()

            EVENT_MANAGER:UnregisterForEvent("TradingHouseSearchHistory_Manager", EVENT_ADD_ON_LOADED)
        end
    end
    EVENT_MANAGER:RegisterForEvent("TradingHouseSearchHistory_Manager", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
end

do
    local function CompareSearchEntries(left, right)
        return left.searchOrderId < right.searchOrderId
    end

    function ZO_TradingHouseSearchHistory_Manager:SaveToHistory(newSearchTable)
        local nextSearchOrderId = self.savedVars.nextSearchOrderId
        self.savedVars.nextSearchOrderId = nextSearchOrderId + 1

        local oldEntryFound = false
        for searchIndex, searchEntry in ipairs(self.searchEntries) do
            if self:AreSearchTablesEqual(searchEntry.searchTable, newSearchTable) then
                searchEntry.searchOrderId = nextSearchOrderId
                oldEntryFound = true
                break
            end
        end

        if not oldEntryFound then
            table.insert(self.searchEntries, { searchTable = newSearchTable, searchOrderId = nextSearchOrderId })
        end

        table.sort(self.searchEntries, CompareSearchEntries)

        if #self.searchEntries > TRADING_HOUSE_SEARCH_HISTORY_MAX_SEARCHES then
            -- remove oldest entry
            table.remove(self.searchEntries, 1)
        end

        self:FireCallbacks("HistoryUpdated")
    end
end

function ZO_TradingHouseSearchHistory_Manager:RemoveSearchTable(searchTableToRemove)
    for searchIndex, searchEntry in ipairs(self.searchEntries) do
        if self:AreSearchTablesEqual(searchEntry.searchTable, searchTableToRemove) then
            table.remove(self.searchEntries, searchIndex)
            self:FireCallbacks("HistoryUpdated")
            return
        end
    end
end

function ZO_TradingHouseSearchHistory_Manager:ClearHistory()
    ZO_ClearNumericallyIndexedTable(self.searchEntries)
    self:FireCallbacks("HistoryUpdated")
end

function ZO_TradingHouseSearchHistory_Manager:SearchEntryIterator()
    -- Iterate from newest (top) to oldest (bottom)
    return ZO_NumericallyIndexedTableReverseIterator(self.searchEntries)
end

function ZO_TradingHouseSearchHistory_Manager:RemoveInvalidSearchEntries()
    -- Iterate in reverse to avoid skipping indexes
    for i, searchEntry in ZO_NumericallyIndexedTableReverseIterator(self.searchEntries) do
        if not self:IsSearchTableValid(searchEntry.searchTable) then
            table.remove(self.searchEntries, i)
        end
    end
end

function ZO_TradingHouseSearchHistory_Manager:IsSearchTableValid(searchTable)
    local categoryParams = ZO_TRADING_HOUSE_CATEGORY_KEY_TO_PARAMS[searchTable["SearchCategory"]]
    if categoryParams then
        local subcategoryIndex = categoryParams:GetSubcategoryIndexForKey(searchTable["SearchSubcategory"])
        if subcategoryIndex then
            return true
        end
    end
    return false
end

function ZO_TradingHouseSearchHistory_Manager:AreSearchTablesEqual(leftSearchTable, rightSearchTable)
    local MAX_TABLES = 16 -- arbitrary cap
    return ZO_DeepAcyclicTableCompare(leftSearchTable, rightSearchTable, MAX_TABLES)
end

TRADING_HOUSE_SEARCH_HISTORY_MANAGER = ZO_TradingHouseSearchHistory_Manager:New()
