--[[
    ZO_VectorRange

    -- Example:
    ZO_VectorRange:New(0, 1, 0, 2, 0, 3)  -- Generates vectors in the range: {[0, 1], [0, 2], [0, 3]}
]]

ZO_VectorRange = ZO_InitializingObject:Subclass()

-- Constructor expects arguments to be specified in the order: lowerBound1, upperBound1, lowerBound2, upperBound2, ...
function ZO_VectorRange:Initialize(...)
    local values = {...}
    local numValues = #values
    if not internalassert(numValues > 0 and numValues % 2 == 0, "ZO_VectorRange: Lower and upper bounds are required.") then
        return
    end

    self.lowerBounds = {}
    self.upperBounds = {}

    for boundIndex = 1, numValues, 2 do
        local lowerBound = values[boundIndex]
        table.insert(self.lowerBounds, lowerBound)

        local upperBound = values[boundIndex + 1]
        table.insert(self.upperBounds, upperBound)
    end
end

function ZO_VectorRange:GetEasedInterval(normalizedInterval)
    if self.easingFunction then
        return self.easingFunction(normalizedInterval)
    end
    return normalizedInterval
end

function ZO_VectorRange:GetEasingFunction()
    return self.easingFunction
end

function ZO_VectorRange:SetEasingFunction(easingFunction)
    self.easingFunction = easingFunction
    return self
end

function ZO_VectorRange:GetLowerBoundsArray()
    return self.lowerBounds
end

function ZO_VectorRange:GetLowerBounds()
    return unpack(self.lowerBounds)
end

function ZO_VectorRange:GetUpperBoundsArray()
    return self.upperBounds
end

function ZO_VectorRange:GetUpperBounds()
    return unpack(self.upperBounds)
end

-- Returns a vector array whose components are interpolated between
-- the lower and upper bound by 'normalizedInterval' amount [0, 1].
function ZO_VectorRange:GetNormalizedVectorArray(normalizedInterval)
    local easedInterval = self:GetEasedInterval(normalizedInterval)
    local vector = {}
    for boundIndex = 1, #self.lowerBounds do
        local lowerBound = self.lowerBounds[boundIndex]
        local upperBound = self.upperBounds[boundIndex]
        vector[boundIndex] = zo_lerp(lowerBound, upperBound, easedInterval)
    end
    return vector
end

-- Returns the vector components interpolated between the lower and
-- upper bound by 'normalizedInterval' amount [0, 1].
function ZO_VectorRange:GetNormalizedVector(normalizedInterval)
    return unpack(self:GetNormalizedVectorArray(normalizedInterval))
end

-- Returns a vector array whose components are interpolated between
-- the lower and upper bound by a shared, random interval.
function ZO_VectorRange:GetRandomProportionalVectorArray()
    local randomNormalizedInterval = zo_random()
    return self:GetNormalizedVectorArray(randomNormalizedInterval)
end

-- Returns the vector components interpolated between the lower and
-- upper bound by a shared, random interval.
function ZO_VectorRange:GetRandomProportionalVector()
    return unpack(self:GetRandomProportionalVectorArray())
end

-- Returns a vector array whose components are interpolated between
-- the lower and upper bound by a random interval per component.
function ZO_VectorRange:GetRandomVectorArray()
    local vector = {}
    for boundIndex = 1, #self.lowerBounds do
        local lowerBound = self.lowerBounds[boundIndex]
        local upperBound = self.upperBounds[boundIndex]
        local randomNormalizedInterval = zo_random()
        local randomEasedInterval = self:GetEasedInterval(randomNormalizedInterval)
        vector[boundIndex] = zo_lerp(lowerBound, upperBound, randomEasedInterval)
    end
    return vector
end

-- Returns the vector components interpolated between the lower and
-- upper bound by a random interval per component.
function ZO_VectorRange:GetRandomVector()
    return unpack(self:GetRandomVectorArray())
end

--[[
    ZO_EasedVectorRange

    -- Example:
    ZO_EasedVectorRange:New(ZO_EaseInOutZeroToOneToZero, 0, 1, 0, 2, 0, 3)  -- Generates sinusoidally eased vectors
                                                                            -- in the range: {[0, 1], [0, 2], [0, 3]}
]]

ZO_EasedVectorRange = ZO_VectorRange:Subclass()

function ZO_EasedVectorRange:Initialize(easingFunction, ...)
    ZO_VectorRange.Initialize(self, ...)

    self.easingFunction = easingFunction
end

--[[
    ZO_VectorRangeAndWeight

    -- Example:
    local range = ZO_VectorRange:New(0, 1, 0, 1, 0, 1)
    local relativeWeight = 10
    ZO_VectorRangeAndWeight:New(range, relativeWeight) -- Represents the specified vector range weighted 10 out of
                                                       -- the total weight of a ZO_WeightedVectorRanges' vector ranges.
]]

ZO_VectorRangeAndWeight = ZO_InitializingObject:Subclass()

function ZO_VectorRangeAndWeight:Initialize(vectorRange, optionalWeight)
    self.vectorRange = vectorRange
    self.weight = optionalWeight or 1
end

function ZO_VectorRangeAndWeight:GetVectorRange()
    return self.vectorRange
end

function ZO_VectorRangeAndWeight:GetWeight()
    return self.weight
end

--[[
    ZO_WeightedVectorRanges

    -- Example:
    local weightedRanges = ZO_WeightedVectorRanges:New()
    weightedRanges:AddVectorRange(ZO_VectorRange:New(0, 1, 0, 1, 0, 1), 50) -- Relative weight of 50
    weightedRanges:AddVectorRange(ZO_VectorRange:New(10, 20, 10, 20, 10, 20), 40) -- Relative weight of 40
    weightedRanges:AddVectorRange(ZO_VectorRange:New(0.25, 0.75, 0.1, 0.4, 0.6, 1), 10) -- Relative weight of 10
    local vectorRange1 = weightedRanges:GetVectorRangeByNormalizedInterval(0.1) -- Returns the first vector range.
    local vectorRange2 = weightedRanges:GetVectorRangeByNormalizedInterval(0.5) -- Returns the first vector range.
    local vectorRange3 = weightedRanges:GetVectorRangeByNormalizedInterval(0.51) -- Returns the second vector range.
    local vectorRange4 = weightedRanges:GetVectorRangeByNormalizedInterval(0.95) -- Returns the third vector range.
]]

ZO_WeightedVectorRanges = ZO_InitializingObject:Subclass()

-- Constructor expects zero or more ZO_VectorRange instance(s).
function ZO_WeightedVectorRanges:Initialize(...)
    self.vectorRangesAndWeights = {}

    local DEFAULT_WEIGHT = 1
    local vectorRanges = {...}
    for vectorRangeIndex, vectorRange in ipairs(vectorRanges) do
        self.vectorRangesAndWeights[vectorRangeIndex] = ZO_VectorRangeAndWeight:New(vectorRange, DEFAULT_WEIGHT)
    end

    self.totalWeight = DEFAULT_WEIGHT * #self.vectorRangesAndWeights
end

-- Add a vector range with the specified relative weight.
-- When choosing a vector range using a normalized interval the
-- subinterval that returns a given vector is defined as:
--  vector range weight / total vector range weights
function ZO_WeightedVectorRanges:AddVectorRange(vectorRange, optionalWeight)
    local weight = optionalWeight or 1
    local vectorRangeAndWeight = ZO_VectorRangeAndWeight:New(vectorRange, weight)
    table.insert(self.vectorRangesAndWeights, vectorRangeAndWeight)
    self.totalWeight = self.totalWeight + weight
end

function ZO_WeightedVectorRanges:GetVectorRangeByNormalizedInterval(normalizedInterval)
    if not internalassert(#self.vectorRangesAndWeights > 0, "ZO_WeightedVectorRanges: No vector ranges have been added.") then
        return nil
    end

    normalizedInterval = zo_clamp(normalizedInterval, 0, 1)
    local targetWeight = normalizedInterval * self.totalWeight
    local currentWeight = 0
    for vectorRangeAndWeightIndex, vectorRangeAndWeight in ipairs(self.vectorRangesAndWeights) do
        currentWeight = currentWeight + vectorRangeAndWeight:GetWeight()
        if currentWeight >= targetWeight then
            return vectorRangeAndWeight:GetVectorRange()
        end
    end
    return nil
end

function ZO_WeightedVectorRanges:GetRandomVectorRange()
    local randomInterval = zo_random()
    local vectorRange = self:GetVectorRangeByNormalizedInterval(randomInterval)
    return vectorRange
end

function ZO_WeightedVectorRanges:GetRandomProportionalVectorArray()
    local vectorRange = self:GetRandomVectorRange()
    return vectorRange:GetRandomProportionalVectorArray()
end

function ZO_WeightedVectorRanges:GetRandomProportionalVector()
    local vectorRange = self:GetRandomVectorRange()
    return vectorRange:GetRandomProportionalVector()
end

function ZO_WeightedVectorRanges:GetRandomVectorArray()
    local vectorRange = self:GetRandomVectorRange()
    return vectorRange:GetRandomVectorArray()
end

function ZO_WeightedVectorRanges:GetRandomVector()
    local vectorRange = self:GetRandomVectorRange()
    return vectorRange:GetRandomVector()
end

--[[
    ZO_ColorRange

    -- Example:
    local colorRange = ZO_ColorRange:New(0, 1, 0, 1, 0, 1, 1, 1)
    local r, g, b, a = colorRange:GetRandomProportionalColor() -- Returns a shade of gray
                                                               -- (white to black) with alpha 1.
]]

ZO_ColorRange = ZO_VectorRange:Subclass()

function ZO_ColorRange:Initialize(minR, maxR, minG, maxG, minB, maxB, minA, maxA)
    minR = minR or 1
    maxR = maxR or minR
    minG = minG or 1
    maxG = maxG or minG
    minB = minB or 1
    maxB = maxB or minB
    minA = minA or 1
    maxA = maxA or minA

    ZO_VectorRange.Initialize(self, minR, maxR, minG, maxG, minB, maxB, minA, maxA)
end

--[[
    ZO_WeightedColorRanges

    -- Example:
    local weightedColors = ZO_WeightedColorRanges:New()
    weightedColors:AddColorRange(ZO_ColorRange:New(0, 1, 0, 0, 0, 0, 1, 1), 10)
    weightedColors:AddColorRange(ZO_ColorRange:New(0, 0, 0, 1, 0, 0, 1, 1), 50)
    weightedColors:AddColorRange(ZO_ColorRange:New(0, 0, 0, 0, 0, 1, 1, 1), 40)
    weightedColors:GetRandomProportionalColor() -- Returns a shade of red 10% of the time,
                                                -- a shade of green 50% of the time,
                                                -- and a shade of blue 40% of the time.
]]

ZO_WeightedColorRanges = ZO_WeightedVectorRanges:Subclass()

function ZO_WeightedColorRanges:AddColorRange(colorRange, optionalWeight)
    local weight = optionalWeight or 1
    ZO_WeightedVectorRanges.AddVectorRange(self, colorRange, weight)
end

function ZO_WeightedColorRanges:GetColorRangeByNormalizedInterval(normalizedInterval)
    return ZO_WeightedVectorRanges.GetVectorRangeByNormalizedInterval(self, normalizedInterval)
end

function ZO_WeightedColorRanges:GetRandomProportionalColorArray()
    return ZO_WeightedVectorRanges.GetRandomProportionalVectorArray(self)
end

function ZO_WeightedColorRanges:GetRandomProportionalColor()
    return ZO_WeightedVectorRanges.GetRandomProportionalVector(self)
end

function ZO_WeightedColorRanges:GetRandomColorArray()
    return ZO_WeightedVectorRanges.GetRandomVectorArray(self)
end

function ZO_WeightedColorRanges:GetRandomColor()
    return ZO_WeightedVectorRanges.GetRandomVector(self)
end

--[[
    ZO_WeightedValue

    -- Example
    ZO_WeightedValue:New(someValue, relativeWeight)
]]

ZO_WeightedValue = ZO_InitializingObject:Subclass()

function ZO_WeightedValue:Initialize(value, weight)
    weight = tonumber(weight)
    if internalassert(weight and weight > 0, "ZO_WeightedValue: weight must be numeric and greater than zero.") then
        self.value = value
        self.weight = weight
    end
end

function ZO_WeightedValue:GetValue()
    return self.value
end

function ZO_WeightedValue:GetWeight()
    return self.weight
end

--[[
    ZO_WeightedValues

    -- Example:
    ZO_WeightedValues:New(
        ZO_WeightedValue:New("This string shows up 50% of the time", 50),
        ZO_WeightedValue:New("And this string... 35%", 35),
        ZO_WeightedValue:New("...and this string appears only 15% of the time", 15))
    local randomString = ZO_WeightedValues:GetRandomValue()
]]

ZO_WeightedValues = ZO_InitializingObject:Subclass()

-- Constructor expects zero or more ZO_WeightedValue instances.
function ZO_WeightedValues:Initialize(...)
    self.values = {...}
    self:UpdateTotalWeight()
end

function ZO_WeightedValues:AddValueAndWeight(value, weight)
    local weightedValue = ZO_WeightedValue:New(value, weight)
    self:AddWeightedValue(weightedValue)
end

function ZO_WeightedValues:AddWeightedValue(weightedValue)
    if internalassert(weightedValue and weightedValue:IsInstanceOf(ZO_WeightedValue), "ZO_WeightedValues: ZO_WeightedValue instance required.") then
        table.insert(self.values, weightedValue)
        self.totalWeight = self.totalWeight + weightedValue:GetWeight()
    end
end

function ZO_WeightedValues:AddWeightedValues(...)
    local weightedValues = {...}
    for _, weightedValue in ipairs(weightedValues) do
        self:AddWeightedValue(weightedValue)
    end
end

function ZO_WeightedValues:GetValueByNormalizedInterval(normalizedInterval)
    normalizedInterval = zo_clamp(normalizedInterval, 0, 1)
    local currentWeight = 0
    local totalWeight = self.totalWeight
    for _, weightedValue in ipairs(self.values) do
        currentWeight = currentWeight + weightedValue:GetWeight()
        local currentNormalizedInterval = currentWeight / totalWeight
        if normalizedInterval <= currentNormalizedInterval then
            return weightedValue:GetValue()
        end
    end
    return nil
end

function ZO_WeightedValues:GetRandomValue()
    local randomNormalizedInterval = zo_random()
    return self:GetValueByNormalizedInterval(randomNormalizedInterval)
end

function ZO_WeightedValues:UpdateTotalWeight()
    local totalWeight = 0
    for _, weightedValue in ipairs(self.values) do
        totalWeight = totalWeight + weightedValue:GetWeight()
    end
    self.totalWeight = totalWeight
end