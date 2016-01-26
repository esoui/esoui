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
    local textUnknown = GetString(SI_STR_TIME_UNKNOWN)
    local textShortEstimate = GetString(SI_STR_TIME_LESS_THAN_MINUTE)
    local textLongEstimate = GetString(SI_STR_TIME_GREATER_THAN_HOUR)

    function ZO_GetSimplifiedTimeEstimateText(estimatedTimeMs)
        if estimatedTimeMs == 0 then
            return textUnknown
        elseif estimatedTimeMs < ZO_ONE_MINUTE_IN_MILLISECONDS then
            return textShortEstimate
        elseif estimatedTimeMs > ZO_ONE_HOUR_IN_MILLISECONDS then
            return textLongEstimate
        else
            return ZO_FormatTimeMilliseconds(estimatedTimeMs, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
        end
    end
end