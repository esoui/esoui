ESO_NumberFormats = {}

do
    local g_strArgs = {}

    function zo_strformat(formatString, ...)
        internalassert(formatString ~= nil, "no format string passed to zo_strformat")
        ZO_ClearNumericallyIndexedTable(g_strArgs)

        for i = 1, select("#", ...) do
            local currentArg = select(i, ...)
            local currentArgType = type(currentArg)
            if currentArgType == "number" then
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

                g_strArgs[i] = string.format(str, currentArg)
            elseif currentArgType == "string" then
                g_strArgs[i] = currentArg
            else
                internalassert(false, string.format("Invalid type passed to zo_strformat: %s", currentArgType))
                g_strArgs[i] = ""
            end
        end

        if type(formatString) == "number" then
            formatString = GetString(formatString)
        end

        return LocalizeString(formatString, unpack(g_strArgs))
    end
end

do
    -- zo_strformat elegantly handles the case where we pass in a param as the "formatter" (e.g.: collectible descriptions).
    -- However, in order to avoid having each string generate its own cache table, the ZO_CachedStrFormat function need to be explicitely told "I have no formatter"
    -- so it can add all of them to one table.  This cuts down on overhead, with the downside that it loses slight parity with zo_strformat.
    -- However, the fact that we do this whole no param thing at all is exploiting a quirk in the grammar to get around a bug in the grammar anyway so
    -- it's a relatively rare scenario

    ZO_CACHED_STR_FORMAT_NO_FORMATTER = ""

    local g_onlyStoreOneByFormatter = { }

    function ZO_SetCachedStrFormatterOnlyStoreOne(formatter)
        internalassert(formatter ~= ZO_CACHED_STR_FORMAT_NO_FORMATTER)
        g_onlyStoreOneByFormatter[formatter] = true
    end

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
                if g_onlyStoreOneByFormatter[formatter] then
                    local existingKey = next(formatterCache)
                    if existingKey then
                        formatterCache[existingKey] = nil
                    end
                end
                formatterCache[hashKey] = cachedString
            end
        end

        return cachedString
    end

    function ZO_ResetCachedStrFormat(formatter)
        if g_cachedStringsByFormatter[formatter] then
            g_cachedStringsByFormatter[formatter] = nil
        end
    end
end

function zo_strtrim(str)
    -- The extra parentheses are used to discard the additional return value (which is the total number of matches)
    return(zo_strgsub(str, "^%s*(.-)%s*$", "%1"))
end

do
    -- Before passing to a formatting function, use english separators. zo_strformat() and ZO_FastFormatDecimalNumber() will automatically replace these separators with language-appropriate ones.
    local ENGLISH_DIGIT_GROUP_REPLACER = ","
    local ENGLISH_DIGIT_GROUP_DECIMAL_REPLACER = "."
    local DIGIT_GROUP_REPLACER_THRESHOLD = zo_pow(10, GetDigitGroupingSize())
    
    function ZO_CommaDelimitNumber(amount)
        if amount < DIGIT_GROUP_REPLACER_THRESHOLD then
            return tostring(amount)
        end

        return FormatIntegerWithDigitGrouping(amount, ENGLISH_DIGIT_GROUP_REPLACER, GetDigitGroupingSize())
    end

    function ZO_CommaDelimitDecimalNumber(amount)
        -- Guards against negative 0 as a displayed numeric value
        if amount == 0 then
            amount = 0
        end

        if amount < DIGIT_GROUP_REPLACER_THRESHOLD then
            -- No commas needed
            return tostring(amount)
        end

        local wholeAmount = zo_floor(amount)
        if wholeAmount == amount then
            -- This is an integer, safe to pass to ZO_CommaDelimitNumber
            return ZO_CommaDelimitNumber(amount)
        end

        -- Comma delimit whole part and then concatenate the decimal part as-is
        local amountString = tostring(amount)
        local LITERAL_MATCH = true
        local decimalSeparatorIndex = zo_strfind(amountString, ENGLISH_DIGIT_GROUP_DECIMAL_REPLACER, 1, LITERAL_MATCH)
        local decimalPartString = zo_strsub(amountString, decimalSeparatorIndex)
        return ZO_CommaDelimitNumber(wholeAmount)..decimalPartString
    end

    -- This is a replacement for zo_strformat(SI_NUMBER_FORMAT, decimalNumberString) that avoids the slow call to grammar.
    -- decimalNumberString should be a number string that contains ASCII digits, commas, periods, and/or a negative sign. It can have a non number suffix, so we can continue to support abbreviations, but it really shouldn't contain any more than that.
    -- The return value should not be used as a component of larger format strings, and an amount string should not be run through it more than once.
    local ENGLISH_DIGIT_SEPARATOR_PATTERN = "[,.]"
    local ENGLISH_DIGIT_SEPARATOR_TO_LOCALIZED_SEPARATOR =
    {
        [ENGLISH_DIGIT_GROUP_REPLACER] = GetString(SI_DIGIT_GROUP_SEPARATOR),
        [ENGLISH_DIGIT_GROUP_DECIMAL_REPLACER] = GetString(SI_DIGIT_DECIMAL_SEPARATOR),
    }
    function ZO_FastFormatDecimalNumber(decimalNumberString)
        local firstNonNumberCharacter = zo_strfind(decimalNumberString, "[^%d%.,-]")
        if firstNonNumberCharacter then
            local numberPrefix = zo_strsub(decimalNumberString, 1, firstNonNumberCharacter - 1)
            local nonNumberSuffix = zo_strsub(decimalNumberString, firstNonNumberCharacter, -1)
            return zo_strgsub(numberPrefix, ENGLISH_DIGIT_SEPARATOR_PATTERN, ENGLISH_DIGIT_SEPARATOR_TO_LOCALIZED_SEPARATOR) .. nonNumberSuffix
        else
            return zo_strgsub(decimalNumberString, ENGLISH_DIGIT_SEPARATOR_PATTERN, ENGLISH_DIGIT_SEPARATOR_TO_LOCALIZED_SEPARATOR)
        end
    end
end

do
    local NON_DIGIT = "%D"
    function ZO_CountDigitsInNumber(amount)
        local amountString = tostring(amount)
        if amountString then
            amountString = zo_strgsub(amountString, NON_DIGIT, "")
            return ZoUTF8StringLength(amountString)
        end
        return 0
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

function ZO_GenerateNewlineSeparatedList(argumentTable)
    if argumentTable ~= nil then
        return table.concat(argumentTable, "\n")
    else
        return ""
    end
end

function ZO_GenerateParagraphSeparatedList(argumentTable)
    if argumentTable ~= nil then
        return table.concat(argumentTable, "\n\n")
    else
        return ""
    end
end


function ZO_FormatFraction(numerator, denominator)
    return string.format("%d/%d", numerator, denominator)
end