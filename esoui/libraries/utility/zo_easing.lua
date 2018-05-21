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