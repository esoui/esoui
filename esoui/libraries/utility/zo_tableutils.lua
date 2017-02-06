--[[
    Counts table entries when #tableObject will not work.
    (...or would also fail on tables using non-numeric keys.)
--]]

function NonContiguousCount(tableObject)
    local count = 0
    
    for _, _ in pairs(tableObject)
    do
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
        sortKeys    (table)     A table whose keys are all keys in entryX and whose values are all tables 
                                (optionally containing tiebreaker and isNumeric)
        sortOrder   (number)    Must be ZO_SORT_ORDER_UP or ZO_SORT_ORDER_DOWN

    Return:
        When sortOrder is ZO_SORT_ORDER_UP:     entry1[sortKey] < entry2[sortKey]
        When sortOrder is ZO_SORT_ORDER_DOWN:   entry1[sortKey] > entry2[sortKey]

    Example:
        ...
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

local type      = type
local tonumber  = tonumber

--[[
    Common constants and types to make sorting a little easier.
--]]

-- Sort from A - Z
ZO_SORT_ORDER_UP        = true                      

-- Sort from Z - A
ZO_SORT_ORDER_DOWN      = false                     

-- Sort by the name field of your entry.  Assumes the table being sorted is full of entries which are
-- also tables; those entries having a key named "name".
ZO_SORT_BY_NAME         = { ["name"] = {} } 
ZO_SORT_BY_NAME_NUMERIC = { ["name"] = { isNumeric = true } }

local IS_LESS_THAN = -1
local IS_EQUAL_TO = 0
local IS_GREATER_THAN = 1

function ZO_TableOrderingFunction(entry1, entry2, sortKey, sortKeys, sortOrder)
    local value1 = entry1[sortKey]
    local value2 = entry2[sortKey]
    local value1Type = type(value1)
        
    if value1Type ~= type(value2) or not validOrderingTypes[value1Type] then
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
    for i=#t, 1, -1 do
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

function ZO_ShallowTableCopy(source, dest)
    dest = dest or {}
    
    for k, v in pairs(source) do
        dest[k] = v
    end
    
    return dest
end

function ZO_DeepTableCopy(source, dest)
    dest = dest or {}
	setmetatable (dest, getmetatable(source))
    
    for k, v in pairs(source) do
        if type(v) == "table" then
            dest[k] = ZO_DeepTableCopy(v)
        else
            dest[k] = v
        end
    end
    
    return dest
end

function ZO_IsElementInNumericallyIndexedTable(table, element)
    for index, value in ipairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function ZO_TableRandomInsert(t, element)
    table.insert(t, zo_random(#t + 1), element)
end