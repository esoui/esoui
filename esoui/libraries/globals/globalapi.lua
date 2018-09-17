-- Cached versions of the lua library functions

zo_strlower         = LocaleAwareToLower
zo_strupper         = LocaleAwareToUpper

string.lowerbybyte  = string.lower
string.upperbybyte  = string.upper

string.lower        = zo_strlower
string.upper        = zo_strupper

zo_strsub           = string.sub
zo_strgsub          = string.gsub
zo_strlen           = string.len
zo_strmatch         = string.match
zo_strgmatch        = string.gmatch
zo_strfind          = string.find
zo_plainstrfind     = PlainStringFind
zo_strsplit         = SplitString
zo_loadstring       = LoadString

zo_floor            = math.floor
zo_ceil             = math.ceil
zo_mod              = math.fmod
zo_decimalsplit     = math.modf
zo_abs              = math.abs
zo_max              = math.max
zo_min              = math.min
zo_sqrt             = math.sqrt
zo_pow              = math.pow
zo_randomseed       = math.randomseed
zo_random           = math.random
zo_insecureNext     = InsecureNext

function zo_insecurePairs(t)
    return zo_insecureNext, t, nil
end

function zo_sign(value)
    if value == 0 then
        return 0
    end
    return value > 0 and 1 or -1
end

local function DefaultComparator(left, _, right)
    return left - right
end

function zo_binarysearch(searchData, dataList, comparator)
    comparator = comparator or DefaultComparator
    local low, high = 1, #dataList
    local mid = 0
    
    while low <= high do
        mid = zo_floor( (low + high) / 2)
        local compareVal = comparator(searchData, dataList[mid], mid)        
        if(compareVal == 0) then
            return true, mid
        elseif(compareVal < 0) then
            high = mid - 1
        else
            low = mid + 1
        end
    end
    
    high = zo_max(high, 1)
    local numEntries = #dataList
    while(high <= numEntries) do
        if(comparator(searchData, dataList[high], high) < 0) then
            return false, high
        end
        high = high + 1
    end
    
    return false, high
end

function zo_binaryinsert(item, searchData, dataList, comparator)
    local _, insertPosition = zo_binarysearch(searchData, dataList, comparator)
    table.insert(dataList, insertPosition, item)
end

function zo_binaryremove(searchData, dataList, comparator)
    local found, removePosition = zo_binarysearch(searchData, dataList, comparator)
    if found then
        table.remove(dataList, removePosition)
    end
end

function zo_clamp(value, minimum, maximum)
    if(value < minimum) then return minimum end
    if(value > maximum) then return maximum end
    return value
end

function zo_saturate(value)
    return zo_clamp(value, 0.0, 1.0)
end

function zo_round(value)
    return zo_floor(value + .5)
end

function zo_roundToZero(value)
    if value > 0 then
        return zo_ceil(value - .5)
    else
        return zo_floor(value + .5)
    end
end

function zo_roundToNearest(value, nearest)
    if nearest == 0 then
        return value
    end
    return zo_roundToZero(value / nearest) * nearest
end

function zo_strjoin(separator, ...)
    return table.concat({...}, separator)
end

function zo_lerp(from, to, amount)
    return from + amount * (to - from)
end

function zo_frameDeltaNormalizedForTargetFramerate()
    return GetFrameDeltaNormalizedForTargetFramerate()
end

function zo_deltaNormalizedLerp(from, to, amount)
    return zo_lerp(from, to, zo_min(zo_frameDeltaNormalizedForTargetFramerate() * amount, 1.0))
end

function zo_percentBetween(startValue, endValue, value)
    if startValue == endValue then
        return 0.0
    end

    return (value - startValue) / (endValue - startValue);
end

function zo_clampedPercentBetween(startValue, endValue, value)
    return zo_saturate(zo_percentBetween(startValue, endValue, value))
end

function zo_floatsAreEqual(a, b, epsilon)
    epsilon = epsilon or 0.001
    return(zo_abs(a - b) <= epsilon)
end

function zo_iconFormat(path, width, height)
    return string.format("|t%s:%s:%s|t", tostring(width), tostring(height), path)
end

function zo_iconFormatInheritColor(path, width, height)
    return string.format("|t%s:%s:%s:inheritcolor|t", tostring(width), tostring(height), path)
end

function zo_iconTextFormat(path, width, height, text, inheritColor)
    local iconFormatter = zo_iconFormat
    if inheritColor then
        iconFormatter = zo_iconFormatInheritColor
    end
    return string.format("%s %s", iconFormatter(path, width, height), zo_strformat("<<1>>", text))
end

function zo_iconTextFormatNoSpace(path, width, height, text, inheritColor)
    local iconFormatter = zo_iconFormat
    if inheritColor then
        iconFormatter = zo_iconFormatInheritColor
    end
    return string.format("%s%s", iconFormatter(path, width, height), zo_strformat("<<1>>", text))
end

function zo_bulletFormat(label, text)
    local bulletSpacer = GetString(SI_FORMAT_BULLET_SPACING)
    local bulletSpacingWidth = label:GetStringWidth(bulletSpacer)
    label:SetNewLineX(bulletSpacingWidth)
    label:SetText(zo_strformat(SI_FORMAT_BULLET_TEXT, text))
end

function zo_strikethroughTextFormat(text)
   return string.format("|L0:0:0:45%%:8%%:ignore|l%s|l", text)
end

function zo_callHandler(object, handler, ...)
    local handlerFunction = object:GetHandler(handler)
    if handlerFunction then
        handlerFunction(object, ...)
        return true
    end
    return false
end

local ZO_CallLaterId = 1

function zo_callLater(func, ms)
    local id = ZO_CallLaterId
    local name = "CallLaterFunction"..id
    ZO_CallLaterId = ZO_CallLaterId + 1

    EVENT_MANAGER:RegisterForUpdate(name, ms,
        function()
            EVENT_MANAGER:UnregisterForUpdate(name)
            func(id)
        end)
    return id
end


do
    local workingTable = {}
    function zo_replaceInVarArgs(indexToReplace, itemToReplaceWith, ...)
        for i = 1, select("#", ...) do
            if i == indexToReplace then
                workingTable[i] = itemToReplaceWith
            else
                workingTable[i] = select(i, ...)
            end
        end
        return unpack(workingTable, 1, select("#", ...))
    end
end

function zo_mixin(object, ...)
    for i = 1, select("#", ...) do
        local source = select(i, ...)
        for k,v in pairs(source) do
            object[k] = v
        end
    end
end

function zo_forwardArcSize(startAngle, angle)
    return (angle - startAngle) % (2 * math.pi)
end

function zo_backwardArcSize(startAngle, angle)
    return 2 * math.pi - zo_forwardArcSize(startAngle, angle)
end

function zo_arcSize(startAngle, angle)
    return zo_min(zo_forwardArcSize(startAngle, angle), zo_backwardArcSize(startAngle, angle))
end

-- id64s are stored as lua Number type, and sometimes generate the same hash key for very similar numbers. 
-- Use this function to get unique hash key for a given id64. 
function zo_getSafeId64Key(id)
    return Id64ToString(id)
end

function zo_distance3D(x1, y1, z1, x2, y2, z2)
    local diffX = x1 - x2
    local diffY = y1 - y2
    local diffZ = z1 - z2
    return zo_sqrt(diffX * diffX + diffY * diffY + diffZ * diffZ)
end