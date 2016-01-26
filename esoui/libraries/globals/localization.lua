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
    function ZO_CommaDelimitNumber(amount)
        if(amount < 1000) then
            return tostring(amount)
        end

        return FormatIntegerWithDigitGrouping(amount, DIGIT_GROUP_REPLACER)
    end
end