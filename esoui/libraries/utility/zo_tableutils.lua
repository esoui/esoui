--[[
    Counts table entries when #tableObject will not work.
    (...or would also fail on tables using non-numeric keys.)
--]]

function NonContiguousCount(t)
    local count = 0
    for _, _ in pairs(t) do
        count = count + 1
    end
    return count
end

--[[
    Description
        This is the only thing that should be used in table.sort's "comp" function.  It allows
        a data description of how to sort tables to be written, instead of writing a custom sort
        function over and over again, you just create a single table that defines the sort ordering
        for a general table type.

    Arguments:
        entry1      (table)     An entry in the table being sorted
        entry2      (table)     Another entry in the table being sorted
        sortKey     (non nil)   A key in the entry arguments (tableX[sortKey]) to be used for sorting.
        sortKeys    (table)     A table whose keys are all keys in entryX and whose values are all tables.
            sortKeys options:
                isNumeric - used if a string field should be converted to a number for comparison
                isId64 - used for id64 fields which need special comparison functions
                caseInsensitive - used for case insensitive string comparison
                tiebreaker - the next key to be used if this one is tied
                tieBreakerSortOrder - the sort order to be used with the tie breaker key
                reverseTiebreakerSortOrder - a boolean which if set to true causes the tie breaker to use the opposite of the current sort order
                                
        sortOrder   (number)    Must be ZO_SORT_ORDER_UP or ZO_SORT_ORDER_DOWN

    Return:
        When sortOrder is ZO_SORT_ORDER_UP:     entry1[sortKey] < entry2[sortKey]
        When sortOrder is ZO_SORT_ORDER_DOWN:   entry1[sortKey] > entry2[sortKey]
--]]
local validOrderingTypes =
{
    ["number"]  = true,
    ["string"]  = true,
    ["boolean"] = true
}

local function NumberFromBoolean(boolean)
    if(boolean == true) then return 1 end
    return 0
end

local type = type
local tonumber = tonumber

--[[
    Common constants and types to make sorting a little easier.
--]]

-- Sort from A - Z
ZO_SORT_ORDER_UP = true

-- Sort from Z - A
ZO_SORT_ORDER_DOWN = false

-- Sort by the name field of your entry.  Assumes the table being sorted is full of entries which are
-- also tables; those entries having a key named "name".
ZO_SORT_BY_NAME         = { ["name"] = {} }
ZO_SORT_BY_NAME_NUMERIC = { ["name"] = { isNumeric = true } }

local IS_LESS_THAN = -1
local IS_EQUAL_TO = 0
local IS_GREATER_THAN = 1

function ZO_TableOrderingFunction(entry1, entry2, sortKey, sortKeys, sortOrder)
    local value1 = entry1[sortKey]
    if type(value1) == "function" then
        value1 = value1(entry1)
    end

    local value2 = entry2[sortKey]
    if type(value2) == "function" then
        value2 = value2(entry2)
    end

    local value1Type = type(value1)

    if value1Type ~= type(value2) or not validOrderingTypes[value1Type] then
        local value1Text
        if value1 == nil then
            value1Text = "nil"
        else
            value1Text = tostring(value1)
        end
        local value2Text
        if value2 == nil then
            value2Text = "nil"
        else
            value2Text = tostring(value2)
        end
        internalassert(false, string.format("%s is not a valid sort key for this data. value1 = %s. value2 = %s.", sortKey or "[nil key]", value1Text, value2Text))
        return false
    end
    
    if value1Type == "boolean" then
        value1 = NumberFromBoolean(value1)
        value2 = NumberFromBoolean(value2)
    end

    local compareResult

    if sortKeys[sortKey].isId64 then
        compareResult = CompareId64s(value1, value2)
    else
        if sortKeys[sortKey].isNumeric then
            value1 = tonumber(value1)
            value2 = tonumber(value2)
        elseif value1Type == "string" then
            if sortKeys[sortKey].caseInsensitive then
                value1 = zo_strlower(value1)
                value2 = zo_strlower(value2)
            end
        end

        if value1 < value2 then
            compareResult = IS_LESS_THAN
        elseif value1 > value2 then
            compareResult = IS_GREATER_THAN
        else
            compareResult = IS_EQUAL_TO
        end
    end
    
    -- The two pieces of data are equal, now this needs to tiebreaker to a different key and recurse.
    -- This is so that in a list sorted by something like AllianceType, where there are only three 
    -- alliances, the tiebreaker would sort within the "name" key of the table entry.
    if compareResult == IS_EQUAL_TO then
        local tiebreaker = sortKeys[sortKey].tiebreaker

        if tiebreaker then
            local nextSortOrder
            if sortKeys[sortKey].tieBreakerSortOrder ~= nil then
                nextSortOrder = sortKeys[sortKey].tieBreakerSortOrder
            else
                nextSortOrder = sortOrder
            end

            if sortKeys[sortKey].reverseTiebreakerSortOrder then
                nextSortOrder = not nextSortOrder
            end
            return ZO_TableOrderingFunction(entry1, entry2, tiebreaker, sortKeys, nextSortOrder)
        end
    else
        if sortOrder == ZO_SORT_ORDER_UP then
            return compareResult == IS_LESS_THAN
        end

        return compareResult == IS_GREATER_THAN
    end
    
    return false
end

function ZO_ClearNumericallyIndexedTable(t)
    for i = #t, 1, -1 do
        t[i] = nil
    end
end

function ZO_ClearTable(t)
    for k in pairs(t) do
        t[k] = nil
    end
end

--Want to keep ZO_ClearTable(t) snappy, so don't bog it down with an optional callback param to if check
function ZO_ClearTableWithCallback(t, c)
    for k, v in pairs(t) do
        c(v)
        t[k] = nil
    end
end

function ZO_ShallowNumericallyIndexedTableCopy(source, dest)
    dest = dest or {}
    for k, v in ipairs(source) do
        dest[k] = v
    end
    return dest
end

function ZO_ShallowTableCopy(source, dest)
    dest = dest or {}
    for k, v in pairs(source) do
        dest[k] = v
    end
    return dest
end

function ZO_DeepTableCopy(source, dest)
    dest = dest or {}
    setmetatable(dest, getmetatable(source))
    for k, v in pairs(source) do
        if type(v) == "table" then
            dest[k] = ZO_DeepTableCopy(v)
        else
            dest[k] = v
        end
    end
    return dest
end

-- Returns true if table is nil or empty
function ZO_IsTableEmpty(t)
    return not t or next(t) == nil
end

-- Returns true if running the iterator once did not return a value. this modifies the iterator.
function ZO_IsIteratorEmpty(iteratorFunction, invariantState, controlValue)
    local nextControlValue = iteratorFunction(invariantState, controlValue)
    if nextControlValue == nil then
        return true
    end
    return false
end


-- The dest table is mutable and will take in the values of all subsequent tables.  It must be initialized.
function ZO_CombineNumericallyIndexedTables(dest, ...)
    local counter = #dest
    for sourceTableIndex = 1, select("#", ...) do
        local sourceTable = select(sourceTableIndex, ...)
        for _, data in ipairs(sourceTable) do
            counter = counter + 1
            dest[counter] = data
        end
    end
end

-- The dest table is mutable and will take in the values of all subsequent tables.  It must be initialized.
function ZO_CombineNonContiguousTables(dest, ...)
    for sourceTableIndex = 1, select("#", ...) do
        local sourceTable = select(sourceTableIndex, ...)
        for key, data in pairs(sourceTable) do
            assert(dest[key] == nil, "Cannot combine tables that share keys")
            dest[key] = data
        end
    end
end

function ZO_IsElementInNumericallyIndexedTable(t, element)
    for index, value in ipairs(t) do
        if value == element then
            return true
        end
    end
    return false
end

function ZO_IndexOfElementInNumericallyIndexedTable(t, element)
    for index, value in ipairs(t) do
        if value == element then
            return index
        end
    end
    return nil
end

function ZO_IsElementInNonContiguousTable(t, element)
    for key, value in pairs(t) do
        if value == element then
            return true
        end
    end
    return false
end

function ZO_KeyOfFirstElementInNonContiguousTable(t, element)
    for key, value in pairs(t) do
        if value == element then
            return key
        end
    end
    return nil
end

function ZO_RemoveFirstElementFromNumericallyIndexedTable(t, element)
    for index, value in ipairs(t) do
        if value == element then
            table.remove(t, index)
            return true
        end
    end
    return false
end

function ZO_TableRandomInsert(t, element)
    table.insert(t, zo_random(#t + 1), element)
end

function ZO_NumericallyIndexedTableIterator(t)
    return ipairs(t)
end

do
    local function NumericallyIndexedTableReverseIterator(t, i)
        if i > 1 then
            i = i - 1
            return i, t[i]
        end
    end

    function ZO_NumericallyIndexedTableReverseIterator(t)
        return NumericallyIndexedTableReverseIterator, t, #t + 1
    end
end

function ZO_FilteredNumericallyIndexedTableIterator(t, filterFunctions)
    local numFilters = filterFunctions and #filterFunctions or 0
    if numFilters > 0  then
        local index = 0
        local count = #t
        return function()
            index = index + 1
            while index <= count do
                local passesFilter = true
                local data = t[index]
                for filterIndex = 1, numFilters do
                    if not filterFunctions[filterIndex](data) then
                        passesFilter = false
                        break
                    end
                end

                if passesFilter then
                    return index, data
                else
                    index = index + 1
                end
            end
        end
    else
        return ipairs(t)
    end
end

function ZO_FilteredNonContiguousTableIterator(t, filterFunctions)
    local numFilters = filterFunctions and #filterFunctions or 0
    if numFilters > 0 then
        local nextKey, nextData = next(t)
        return function()
            while nextKey do
                local currentKey, currentData = nextKey, nextData
                nextKey, nextData = next(t, nextKey)

                local passesFilter = true
                for filterIndex = 1, numFilters do
                    if not filterFunctions[filterIndex](currentData) then
                        passesFilter = false
                        break
                    end
                end

                if passesFilter then
                    return currentKey, currentData
                end
            end
        end
    else
        return pairs(t)
    end
end

function ZO_DeepAcyclicTableCompare(t1, t2, maxTablesVisited)
    local visitedLeft, visitedRight = {}, {}
    local numVisited = 0

    local function visit(left, right)
        if type(left) == "table" and type(right) == "table" then
            if visitedLeft[left] or visitedRight[right] then
                internalassert(false, "Comparing tables with cycles.")
                return false
            end
            visitedLeft[left], visitedRight[right] = true, true

            numVisited = numVisited + 2
            if numVisited > maxTablesVisited then
                internalassert(false, "Max table limit reached")
                return false
            end

            for k, v in pairs(left) do
                if not visit(v, right[k]) then
                    return false
                end
            end

            for k, v in pairs(right) do
                if left[k] == nil then
                    return false
                end
            end

            if getmetatable(left) ~= getmetatable(right) then
                return false
            end

            return true
        else
            return left == right
        end
    end

    return visit(t1, t2)
end

function ZO_CreateSetFromArguments(...)
    local set = {}

    for i = 1, select('#', ...) do
        set[select(i, ...)] = true
    end

    return set
end

function ZO_AreNumericallyIndexedTablesEqual(left, right)
    if #left == #right then
        for index, value in ipairs(left) do
            if right[index] ~= value then
                return false
            end
        end
        return true
    end
    return false
end

-- Creates a non-contiguous table, the keys of which are the unique values
-- in the numerically indexed table t or, if t is scalar, the value of t.
function ZO_CreateSet(t)
    local s = {}
    local tType = type(t)
    if tType == "table" then
        for _, v in ipairs(t) do
            s[v] = true
        end
    elseif tType ~= "nil" then
        s[t] = true
    end
    return s
end

-- Returns a non-contiguous table, the keys of which are the intersecting keys
-- shared between the non-contiguous sets s1 and s2.
function ZO_IntersectSets(s1, s2)
    local s = {}
    for k in pairs(s1) do
        if s2[k] then
            s[k] = true
        end
    end
    return s
end

-- Returns true if the non-contiguous sets s1 and s2 share one or more keys.
function ZO_AreIntersectingSets(s1, s2)
    return next(ZO_IntersectSets(s1, s2)) ~= nil
end

-- Returns a non-contiguous table, the keys of which are the intersecting values
-- shared between the numerically indexed tables t1 and t2.
function ZO_IntersectNumericallyIndexedTables(t1, t2)
    local s1 = ZO_CreateSet(t1)
    local s2 = ZO_CreateSet(t2)
    return ZO_IntersectSets(s1, s2)
end

-- Returns true if the numerically indexed tables t1 and t2 share one or more values.
function ZO_AreIntersectingNumericallyIndexedTables(t1, t2)
    local s = ZO_IntersectNumericallyIndexedTables(t1, t2)
    return next(s) ~= nil
end

-- Returns true if the non-contiguous sets s1 and s2 contain the same keys.
function ZO_AreEqualSets(s1, s2)
    local size1 = NonContiguousCount(s1)
    local size2 = NonContiguousCount(s2)
    if size1 ~= size2 then
        return false
    end
    for k in pairs(s1) do
        if not s2[k] then
            return false
        end
    end
    return true
end

function ZO_CreateSortableTableFromKeys(source)
    local t = {}
    for k in pairs(source) do
        table.insert(t, k)
    end
    return t
end

function ZO_CreateSortableTableFromValues(source)
    local t = {}
    for _, v in pairs(source) do
        table.insert(t, v)
    end
    return t
end