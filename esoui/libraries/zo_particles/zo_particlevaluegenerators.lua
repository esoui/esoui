local lerp = zo_lerp
local cos = math.cos

--Particle Value Generator

ZO_ParticleValueGenerator = ZO_Object:Subclass()

function ZO_ParticleValueGenerator:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_ParticleValueGenerator:Initialize()

end

function ZO_ParticleValueGenerator:Generate()
    --For multi-value generators you can generate all of them together here
end

function ZO_ParticleValueGenerator:GetValue(i)
    --Return one or more values
    assert(false)
end

--Uniform Random Generator

ZO_UniformRangeGenerator = ZO_ParticleValueGenerator:Subclass()

function ZO_UniformRangeGenerator:New(...)
    return ZO_ParticleValueGenerator.New(self, ...)
end

--where ... is a set of pairs that we interpolate between by the random value
function ZO_UniformRangeGenerator:Initialize(...)
    for i = 1, select("#", ...) do
        self[i] = select(i, ...)
    end
end

function ZO_UniformRangeGenerator:Generate()
    self.randomValue = zo_random()
end


function ZO_UniformRangeGenerator:GetValue(i)
    return lerp(self[i * 2 - 1], self[i * 2], self.randomValue)
end

--Random Choice Generator

ZO_WeightedChoiceGenerator = ZO_ParticleValueGenerator:Subclass()

function ZO_WeightedChoiceGenerator:New(...)
    return ZO_ParticleValueGenerator.New(self, ...)
end

--where ... is a set of pairs containing a choice and its weight
function ZO_WeightedChoiceGenerator:Initialize(...)
    self.choices = {}
    self.weights = {}
    self.totalWeights = 0 
    for i = 1, select("#", ...), 2 do
        local choice = select(i, ...)
        local weight = select(i + 1, ...)
        table.insert(self.choices, choice)
        table.insert(self.weights, weight)
        self.totalWeights = self.totalWeights + weight
    end
end

function ZO_WeightedChoiceGenerator:Generate()
    self.randomValue = zo_random() * self.totalWeights
end

function ZO_WeightedChoiceGenerator:GetValue(i)
    local currentWeightTotal = 0
    local choiceIndex = 0
    local numChoices = #self.choices
    while currentWeightTotal <= self.randomValue and choiceIndex < numChoices do
        choiceIndex = choiceIndex + 1
        currentWeightTotal = currentWeightTotal + self.weights[choiceIndex]
    end
    local choice = self.choices[choiceIndex]
    if type(choice) == "table" then
        return choice[i]
    else
        return choice
    end
end

--Smooth Cycle Generator

ZO_SmoothCycleGenerator = ZO_ParticleValueGenerator:Subclass()

function ZO_SmoothCycleGenerator:New(...)
    return ZO_ParticleValueGenerator.New(self, ...)
end

--where ... is a set of pairs that we cycle between
function ZO_SmoothCycleGenerator:Initialize(...)
    self.cycleDurationS = 1
    for i = 1, select("#", ...) do
        self[i] = select(i, ...)
    end
end

function ZO_SmoothCycleGenerator:SetCycleDurationS(cycleDurationS)
    self.cycleDurationS = cycleDurationS
end

function ZO_SmoothCycleGenerator:Generate()
    local progress = zo_mod(GetGameTimeSeconds(), self.cycleDurationS) / self.cycleDurationS
    self.lerpValue = (cos(progress * ZO_TWO_PI) + 1) / 2
end

function ZO_SmoothCycleGenerator:GetValue(i)
    return lerp(self[i * 2 - 1], self[i * 2], self.lerpValue)
end