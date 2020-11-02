function ZO_LinearEase(progress)
    return progress
end

local function EaseIn(progress, power)
    return progress ^ power
end

local function EaseOut(progress, power)
    return 1 - ((1 - progress) ^ power)
end
local function EaseOutIn(progress, power)
    if progress < .5 then
        return ((progress * 2) ^ power) / 2
    end
    return 1 - (((1 - progress) * 2) ^ power) / 2
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
    return math.sin(math.pi * progress)
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

ZO_BounceEase = ZO_GenerateCubicBezierEase(.31,1.36,.83,1.2)
ZO_BezierInEase = ZO_GenerateCubicBezierEase(.5,.74,.38,.94)

do
    local exp = math.exp
    local P = 1.57
    local DIVISOR = exp(P) - 1
    function ZO_EaseNormalizedZoom(progress)
        --The actual zoom level we use to size things does not go linearly from min to max. Going linearly causes the zoom to feel like it is moving very fast to start
        --and then moving more and more slowly as we reach max zoom. To counteract this we treat the progression from min to max as a curve that increases more slowly to
        --start and then faster later. Research has shown that the curve y=e^px best matches human expectations of an even zoom speed with a p value of 6^0.25 ~= 1.57. We
        --normalized this curve so that y goes from 0 to 1 as x goes from 0 to 1 since we operate on a normalized value between min and max zoom.
        return (exp(P * progress) - 1) / DIVISOR
    end
end