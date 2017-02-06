ZO_ONE_MINUTE_IN_SECONDS = 60
ZO_ONE_HOUR_IN_SECONDS = 60 * ZO_ONE_MINUTE_IN_SECONDS -- = 3600
ZO_ONE_DAY_IN_SECONDS = 24 * ZO_ONE_HOUR_IN_SECONDS -- = 86400
ZO_ONE_MONTH_IN_SECONDS = 30 * ZO_ONE_DAY_IN_SECONDS -- = 2592000

ZO_ONE_MINUTE_IN_MILLISECONDS = 60000
ZO_ONE_HOUR_IN_MILLISECONDS = 60 * ZO_ONE_MINUTE_IN_MILLISECONDS -- = 3600000

function ZO_FormatTime(seconds, formatStyle, precision, direction)
   return FormatTimeSeconds(seconds, formatStyle, precision, direction or TIME_FORMAT_DIRECTION_NONE)
end

function ZO_FormatTimeMilliseconds(milliseconds, formatType, precisionType, direction)   
    return FormatTimeMilliseconds(milliseconds, formatType, precisionType, direction or TIME_FORMAT_DIRECTION_NONE)
end

function ZO_FormatCountdownTimer(seconds)
    if(seconds > 3 * ZO_ONE_MINUTE_IN_SECONDS) then
        return ZO_FormatTime(seconds, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
    else
        return ZO_FormatTime(seconds, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
    end
end

function ZO_FormatTimeLargestTwo(seconds, format)
    if(seconds > ZO_ONE_DAY_IN_SECONDS) then
        seconds = zo_round(seconds / ZO_ONE_HOUR_IN_SECONDS) * ZO_ONE_HOUR_IN_SECONDS
    elseif(seconds > ZO_ONE_HOUR_IN_SECONDS) then
        seconds = zo_round(seconds / ZO_ONE_MINUTE_IN_SECONDS) * ZO_ONE_MINUTE_IN_SECONDS
    end
    return ZO_FormatTime(seconds, format, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
end

function ZO_FormatDurationAgo(seconds)
    if(seconds < ZO_ONE_MINUTE_IN_SECONDS) then
        return GetString(SI_TIME_DURATION_NOT_LONG_AGO)
    else
        return zo_strformat(SI_TIME_DURATION_AGO, ZO_FormatTime(seconds, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS))
    end
end

function ZO_FormatRelativeTimeStamp(timestamp, precisionType)
    return ZO_FormatTimeMilliseconds(timestamp, TIME_FORMAT_STYLE_RELATIVE_TIMESTAMP, precisionType or TIME_FORMAT_PRECISION_TENTHS)
end

function ZO_FormatTimeAsDecimalWhenBelowThreshold(seconds, secondsThreshold)
    secondsThreshold = secondsThreshold or 10
    if seconds < secondsThreshold then
        return ZO_FormatTime(seconds, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL_SHOW_TENTHS_SECS, TIME_FORMAT_PRECISION_TENTHS, TIME_FORMAT_DIRECTION_DESCENDING)
    else
        return ZO_FormatTimeLargestTwo(seconds, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL)
    end
end

local CLOCK_FORMAT

function ZO_FormatClockTime()
    if(CLOCK_FORMAT == nil) then
        CLOCK_FORMAT = (GetCVar("Language.2") == "en") and TIME_FORMAT_PRECISION_TWELVE_HOUR or TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR
    end

    local localTimeSinceMidnight = GetSecondsSinceMidnight()
    local text, secondsUntilNextUpdate = ZO_FormatTime(localTimeSinceMidnight, TIME_FORMAT_STYLE_CLOCK_TIME, CLOCK_FORMAT)
    return text, secondsUntilNextUpdate
end

function ZO_SetClockFormat(clockFormat)
    -- Doesn't currently take effect until the next clock update.
    CLOCK_FORMAT = clockFormat
end

local g_normalizationTime = GetFrameTimeSeconds()

function ZO_NormalizeSecondsPositive(secs)
    return GetFrameTimeSeconds() - g_normalizationTime + secs
end

function ZO_NormalizeSecondsNegative(secs)
    return GetFrameTimeSeconds() - g_normalizationTime - secs
end

function ZO_NormalizeSecondsSince(secsSinceRequest)
    return ZO_NormalizeSecondsNegative(secsSinceRequest)
end

function ZO_NormalizeSecondsUntil(secsUntilExpiry)
    return ZO_NormalizeSecondsPositive(secsUntilExpiry)
end

do
    ZO_TIME_ESTIMATE_STYLE =
    {
        ANGLE_BRACKETS = 1,
        ARITHMETIC = 2,
    }

    local textUnknown = GetString(SI_STR_TIME_UNKNOWN)

    local textMinuteEstimate = GetString(SI_STR_TIME_LESS_THAN_MINUTE)
    local textMinuteEstimateShort = GetString(SI_STR_TIME_LESS_THAN_MINUTE_SHORT)

    local textHourEstimate = GetString(SI_STR_TIME_GREATER_THAN_HOUR)
    local textHourEstimateShort = GetString(SI_STR_TIME_GREATER_THAN_HOUR_SHORT)
    local textHourEstimatePlus = GetString(SI_STR_TIME_GREATER_THAN_HOUR_PLUS)
    local textHourEstimatePlusShort = GetString(SI_STR_TIME_GREATER_THAN_HOUR_PLUS_SHORT)

    local function GetLessThanStringId(formatType, estimateStyle)
        --Only the angle bracket style has been designed
        return formatType == TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT and textMinuteEstimateShort or textMinuteEstimate
    end

    local function GetGreaterThanStringId(formatType, estimateStyle)
        if estimateStyle == ZO_TIME_ESTIMATE_STYLE.ANGLE_BRACKETS then
            return formatType == TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT and textHourEstimateShort or textHourEstimate
        elseif estimateStyle == ZO_TIME_ESTIMATE_STYLE.ARITHMETIC then
            return formatType == TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT and textHourEstimatePlusShort or textHourEstimatePlus
        end 
    end

    function ZO_GetSimplifiedTimeEstimateText(estimatedTimeMs, formatType, precisionType, estimateStyle)
        formatType = formatType or TIME_FORMAT_STYLE_COLONS
        precisionType = precisionType or TIME_FORMAT_PRECISION_TWELVE_HOUR
        estimateStyle = estimateStyle or ZO_TIME_ESTIMATE_STYLE.ANGLE_BRACKETS
        
        if estimatedTimeMs == 0 then
            return textUnknown
        elseif estimatedTimeMs < ZO_ONE_MINUTE_IN_MILLISECONDS then
            return GetLessThanStringId(formatType, estimateStyle)
        elseif estimatedTimeMs > ZO_ONE_HOUR_IN_MILLISECONDS then
            return GetGreaterThanStringId(formatType, estimateStyle)
        else
            return ZO_FormatTimeMilliseconds(estimatedTimeMs, formatType, precisionType)
        end
    end
end