function ZO_LinearEase(progress)
    return progress
end

function ZO_LinearEaseZeroToOneToZero(progress)
    return progress < 0.5 and (progress * 2) or (2 - (progress * 2))
end

local function EaseIn(progress, power)
    return progress ^ power
end

local function EaseOut(progress, power)
    return 1 - ((1 - progress) ^ power)
end

local function EaseOutIn(progress, power)
    if progress < 0.5 then
        return ((progress * 2) ^ power) * 0.5
    end
    return 1 - (((1 - progress) * 2) ^ power) * 0.5
end

function ZO_EaseInQuadratic(progress)
    return EaseIn(progress, 2)
end
function ZO_EaseOutQuadratic(progress)
    return EaseOut(progress, 2)
end
function ZO_EaseInOutQuadratic(progress)
    return EaseOutIn(progress, 2)
end

function ZO_EaseInCubic(progress)
    return EaseIn(progress, 3)
end
function ZO_EaseOutCubic(progress)
    return EaseOut(progress, 3)
end
function ZO_EaseInOutCubic(progress)
    return EaseOutIn(progress, 3)
end

function ZO_EaseInQuartic(progress)
    return EaseIn(progress, 4)
end
function ZO_EaseOutQuartic(progress)
    return EaseOut(progress, 4)
end
function ZO_EaseInOutQuartic(progress)
    return EaseOutIn(progress, 4)
end

function ZO_EaseInQuintic(progress)
    return EaseIn(progress, 5)
end
function ZO_EaseOutQuintic(progress)
    return EaseOut(progress, 5)
end
function ZO_EaseInOutQuintic(progress)
    return EaseOutIn(progress, 5)
end

function ZO_EaseInOutZeroToOneToZero(progress)
    return math.sin(ZO_PI * progress)
end

function ZO_ExponentialEaseInOut(progress, exponent)
    if progress < 0.5 then
        return ((progress * 2) ^ exponent) * 0.5
    end
    return 1 - (((1 - progress) * 2) ^ exponent) * 0.5
end

function ZO_ExponentialEaseOutIn(progress, exponent)
    if progress < 0.5 then
        return (1 - ((1 - (2 * progress)) ^ exponent)) * 0.5
    end
    return (((progress - 0.5) * 2) ^ exponent) * 0.5 + 0.5
end

function ZO_CreateExponentialEaseInOutFunction(exponent)
    if exponent == 1 then
        -- Linear interpolator.
        return ZO_LinearEase
    end

    -- Eased interpolator.
    return function(progress)
        return ZO_ExponentialEaseInOut(progress, exponent)
    end
end

function ZO_CreateExponentialEaseOutInFunction(exponent)
    if exponent == 1 then
        -- Linear interpolator.
        return ZO_LinearEase
    end

    -- Eased interpolator.
    return function(progress)
        return ZO_ExponentialEaseOutIn(progress, exponent)
    end
end

function ZO_GenerateCubicBezierEase(x1, y1, x2, y2)
    if x1 == y1 and x2 == y2 then
        return ZO_LinearEase
    end

    local CalculateCubicBezierEase = CalculateCubicBezierEase
    return function(progress)
        return CalculateCubicBezierEase(progress, x1, y1, x2, y2)
    end
end

ZO_BounceEase = ZO_GenerateCubicBezierEase(0.31, 1.36, 0.83, 1.2)
ZO_BezierInEase = ZO_GenerateCubicBezierEase(0.5, 0.74, 0.38, 0.94)

do
    local exp = math.exp
    local P = 1.57
    local DIVISOR = 1 / (exp(P) - 1)
    function ZO_EaseNormalizedZoom(progress)
        --The actual zoom level we use to size things does not go linearly from min to max. Going linearly causes the zoom to feel like it is moving very fast to start
        --and then moving more and more slowly as we reach max zoom. To counteract this we treat the progression from min to max as a curve that increases more slowly to
        --start and then faster later. Research has shown that the curve y=e^px best matches human expectations of an even zoom speed with a p value of 6^0.25 ~= 1.57. We
        --normalized this curve so that y goes from 0 to 1 as x goes from 0 to 1 since we operate on a normalized value between min and max zoom.
        return (exp(P * progress) - 1) * DIVISOR
    end
end

-- progress values must have at least two values in it:
-- {0, 1} generates a line from 0 to 1
-- {0, 1, 0} generates a line from 0 to 1 (at progress=0.5) back to 0
function ZO_GenerateLinearPiecewiseEase(progressValues)
    if not internalassert(#progressValues >= 2, "piecewise ease needs at least two values to ease between") then
        return ZO_LinearEase
    end
    local inBetweenSize = #progressValues - 1
    local inBetweenModulo = 1 / inBetweenSize
    return function(progress)
        local nextIndex = math.max(2, math.ceil(progress * inBetweenSize) + 1)
        local nextValue = progressValues[nextIndex]
        local previousValue = progressValues[nextIndex - 1]
        local percentBetweenValues = (progress % inBetweenModulo) * inBetweenSize 
        return zo_lerp(previousValue, nextValue, percentBetweenValues)
    end
end