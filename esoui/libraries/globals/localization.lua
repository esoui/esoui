ESO_NumberFormats = {}

local strArgs = {}

function zo_strformat(formatString, ...)
    ZO_ClearNumericallyIndexedTable(strArgs)

    for i = 1, select("#", ...) do
        local currentArg = select(i, ...)
        if type(currentArg) == "number" then
            local str = ""
            local numFmt = "d"
            local num, frac = zo_decimalsplit(currentArg)
            
            local width = 0
            local digits = 1
            local unsigned = false
            if ESO_NumberFormats[formatString] ~= nil and ESO_NumberFormats[formatString][i] ~= nil then
                width = ESO_NumberFormats[formatString][i].width or width
                digits = ESO_NumberFormats[formatString][i].digits or digits
                unsigned = ESO_NumberFormats[formatString][i].unsigned or unsigned
            end

            if width > 0 then
                str = string.format("0%d", width)
            end

            if frac ~= 0 then
                numFmt = "f"
                str = str..string.format(".%d", digits)
            elseif unsigned == true then
                numFmt = "u"
            end

            str = string.format("%%%s%s", str, numFmt)

            strArgs[i] = string.format(str, currentArg)
        elseif type(currentArg) == "string" then
            strArgs[i] = currentArg
        else
            strArgs[i] = ""
        end
    end

    if type(formatString) == "number" then
        formatString = GetString(formatString)
    end

    return LocalizeString(formatString, unpack(strArgs))
end

do
    -- zo_strformat elegantly handles the case where we pass in a param as the "formatter" (e.g.: collectible descriptions).
    -- However, in order to avoid having each string generate its own cache table, the ZO_CachedStrFormat function need to be explicitely told "I have no formatter"
    -- so it can add all of them to one table.  This cuts down on overhead, with the downside that it loses slight parity with zo_strformat.
    -- However, the fact that we do this whole no param thing at all is exploiting a quirk in the grammar to get around a bug in the grammar anyway so
    -- it's a relatively rare scenario

    ZO_CACHED_STR_FORMAT_NO_FORMATTER = ""

    local g_cachedStringsByFormatter = 
    {
        [ZO_CACHED_STR_FORMAT_NO_FORMATTER] = {} --Used for strings that need to run through grammar without a formatter
    }

    function ZO_CachedStrFormat(formatter, ...)
        formatter = formatter or ZO_CACHED_STR_FORMAT_NO_FORMATTER

        local formatterCache = g_cachedStringsByFormatter[formatter]
        if not formatterCache then
            formatterCache = {}
            g_cachedStringsByFormatter[formatter] = formatterCache
        end
        
        local cachedString
        if formatter == ZO_CACHED_STR_FORMAT_NO_FORMATTER then
            --"No formatter" only works with 1 param
            local rawString = ...
            local hashKey = HashString(rawString)

            cachedString = formatterCache[hashKey]
            if not cachedString then
                cachedString = zo_strformat(rawString)
                formatterCache[hashKey] = cachedString
            end
        else
            local concatParams = table.concat({ ... })
            local hashKey = HashString(concatParams)

            cachedString = formatterCache[hashKey]
            if not cachedString then
                cachedString = zo_strformat(formatter, ...)
                formatterCache[hashKey] = cachedString
            end
        end

        return cachedString
    end
end

function zo_strtrim(str)
    -- The extra parentheses are used to discard the additional return value (which is the total number of matches)
    return(zo_strgsub(str, "^%s*(.-)%s*$", "%1"))
end

do
    local DIGIT_GROUP_REPLACER = GetString(SI_DIGIT_GROUP_SEPARATOR)
    local DIGIT_GROUP_REPLACER_THRESHOLD = zo_pow(10, GetDigitGroupingSize())
    local DIGIT_GROUP_DECIMAL_REPLACER = GetString(SI_DIGIT_GROUP_DECIMAL_SEPARATOR)
    
    function ZO_CommaDelimitNumber(amount)
        if amount < DIGIT_GROUP_REPLACER_THRESHOLD then
            return tostring(amount)
        end

        return FormatIntegerWithDigitGrouping(amount, DIGIT_GROUP_REPLACER, GetDigitGroupingSize())
    end

    function ZO_LocalizeDecimalNumber(amount)
        local amountString = tostring(amount)

        if "." ~= DIGIT_GROUP_DECIMAL_REPLACER then
            amountString = zo_strgsub(amountString, "%.", DIGIT_GROUP_DECIMAL_REPLACER)
        end

        if amount >= DIGIT_GROUP_REPLACER_THRESHOLD then
            -- We have a number like 10000.5, so localize the non-decimal digit group separators (e.g., 10000 becomes 10,000)
            local decimalSeparatorIndex = zo_strfind(amountString, "%"..DIGIT_GROUP_DECIMAL_REPLACER) -- Look for the literal separator
            local decimalPartString = decimalSeparatorIndex and zo_strsub(amountString, decimalSeparatorIndex) or ""
            local wholePartString = zo_strsub(amountString, 1, decimalSeparatorIndex and decimalSeparatorIndex - 1)

            amountString = ZO_CommaDelimitNumber(tonumber(wholePartString))..decimalPartString
        end

        return amountString
    end
end

function ZO_GenerateCommaSeparatedList(argumentTable)
    if argumentTable ~= nil and #argumentTable > 0 then
        local numArguments = #argumentTable
        -- If there's only one item in the list, the string is just the first item
        if numArguments == 1 then
            return argumentTable[1]
        else
            -- loop through the first through the second to last element adding commas in between
            -- don't add the last since we will use a different separator for it
            local listString = table.concat(argumentTable, GetString(SI_LIST_COMMA_SEPARATOR), 1, numArguments - 1)

            -- add the last element of the array to the list using the ", and" separator
            local finalSeparator = SI_LIST_COMMA_AND_SEPARATOR
            -- if there are only two items in the list, we want to use "and" without a comma
            if numArguments == 2 then
                finalSeparator = SI_LIST_AND_SEPARATOR
            end
            listString = string.format('%s%s%s', listString, GetString(finalSeparator), argumentTable[numArguments])
            return listString
        end
    else
        return ""
    end
end

function ZO_GenerateCommaSeparatedListWithoutAnd(argumentTable)
    if argumentTable ~= nil then
        return table.concat(argumentTable, GetString(SI_LIST_COMMA_SEPARATOR))
    else
        return ""
    end
end
