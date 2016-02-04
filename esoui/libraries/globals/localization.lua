ESO_NumberFormats = {}

local strArgs = {}

function zo_strformat(formatString, ...)
    ZO_ClearNumericallyIndexedTable(strArgs)
    
    for i=1, select("#", ...)
    do
        local currentArg = select(i, ...)
        if(type(currentArg) == "number")
        then
            local str = ""
            local numFmt = "d"
            local num, frac = math.modf(currentArg)
            
            local width = 0
            local digits = 1
            local unsigned = false
            if((ESO_NumberFormats[formatString] ~= nil) and (ESO_NumberFormats[formatString][i] ~= nil))
            then
                width = ESO_NumberFormats[formatString][i].width or width
                digits = ESO_NumberFormats[formatString][i].digits or digits
                unsigned = ESO_NumberFormats[formatString][i].unsigned or unsigned
            end

            if(width > 0)
            then
                str = string.format("0%d", width)
            end

            if(frac ~= 0)
            then
                numFmt = "f"
                str = str..string.format(".%d", digits)
            elseif(unsigned == true)
            then
                numFmt = "u"
            end

            str = string.format("%%%s%s", str, numFmt)

            strArgs[i] = string.format(str, currentArg)
        elseif(type(currentArg) == "string")
        then
            strArgs[i] = currentArg
        else
            strArgs[i] = ""
        end
    end

    if(type(formatString) == "number")
    then
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
    local DIGIT_GROUP_REPLACER_THRESHOLD = 1000
    local DIGIT_GROUP_DECIMAL_REPLACER = GetString(SI_DIGIT_GROUP_DECIMAL_SEPARATOR)
    
    function ZO_CommaDelimitNumber(amount)
        if(amount < DIGIT_GROUP_REPLACER_THRESHOLD) then
            return tostring(amount)
        end

        return FormatIntegerWithDigitGrouping(amount, DIGIT_GROUP_REPLACER)
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