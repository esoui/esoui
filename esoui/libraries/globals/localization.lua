ESO_NumberFormats = {}

local strArgs = {}

function zo_strformat(formatString, ...)
    ZO_ClearNumericallyIndexedTable(strArgs)

    for i = 1, select("#", ...) do
        local currentArg = select(i, ...)
        if type(currentArg) == "number" then
            local str = ""
            local numFmt = "d"
            local num, frac = math.modf(currentArg)
            
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
        -- start off the list with the first element in the array
        local listString = argumentTable[1]
        -- loop through the second through the second to last element adding commas in between
        -- if there are only two things in the array this loop will be skipped
        for i = 2, (numArguments - 1) do
            listString = listString .. GetString(SI_LIST_COMMA_SEPARATOR) .. argumentTable[i]
        end
        -- add the last element of the array to the list
        -- special behavior to add "and" for the last element
        if numArguments >= 2 then
            local finalSeparator = SI_LIST_COMMA_AND_SEPARATOR
            -- if there are only two it doesn't make sense to add ", and "
            if numArguments == 2 then
                finalSeparator = SI_LIST_AND_SEPARATOR
            end
            listString = listString .. GetString(finalSeparator) .. argumentTable[numArguments]
        end
        return listString
    else
        return ""
    end
end
