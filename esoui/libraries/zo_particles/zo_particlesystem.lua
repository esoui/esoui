--Particle System

ZO_ParticleSystem = ZO_Object:Subclass()

ZO_ParticleSystem.particleClassToPool = {}

function ZO_ParticleSystem:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_ParticleSystem:Initialize(particleClass)
    if not ZO_ParticleSystem.particleClassToPool[particleClass] then
        local Factory = function(pool)
            return particleClass:New()
        end
        local Reset = function(object)
            object:Stop()
        end
        local pool = ZO_ObjectPool:New(Factory, Reset)
        ZO_ParticleSystem.particleClassToPool[particleClass] = pool
    end
    self.particlePool = ZO_MetaPool:New(ZO_ParticleSystem.particleClassToPool[particleClass])

    self.parameters = {}
    self:SetParticlesPerSecond(0)
end

function ZO_ParticleSystem:SetDuration(durationS)
    self.durationS = durationS
end

function ZO_ParticleSystem:SetParticlesPerSecond(particlesPerSecond)
    self.particlesPerSecond = particlesPerSecond
    if particlesPerSecond > 0 then
        self.secondsBetweenParticles = 1 / particlesPerSecond
    else
        self.secondsBetweenParticles = nil
    end
end

function ZO_ParticleSystem:SetBurst(numParticles, durationS, phaseS, cycleDurationS)
    self.burstNumParticles = numParticles
    self.burstDurationS = durationS
    self.burstPhaseS = phaseS
    self.burstCycleDurationS = cycleDurationS
    self.burstActive = false
end

function ZO_ParticleSystem:SetBurstEasing(easingFunction)
    self.burstEasingFunction = easingFunction
end

function ZO_ParticleSystem:SetParentControl(parentControl)
    self.parentControl = parentControl
end

--This function takes N parameter names and one value generator. The result of the value generator will be applied to the
--named parameters when the particle is created. A simple example is, SetParticleParameter("alpha", ZO_UniformRangeGenerator:New(0, 1)).
--This would set the parameter "alpha" to a random value between 0 and 1 on creation. For a more complex example,
--SetParticleParameter("x", "y", "z", ZO_RandomSpherePoint:New(10)). This would generate a random point on a sphere of size 10 and then
--set each of "x", "y", and "z" on the particle. This allows for one generator to produce multiple linked values. You can also use a direct
--value instead of using a generator class if you just want to use the value always. For example, SetParticle("scale", 1.5).
function ZO_ParticleSystem:SetParticleParameter(...)
    local numArguments = select("#", ...)
    if numArguments >= 2 then
        --See if we already have a generator for these parameter names. We assume that they won't do something like setting generators for
        --both "x" and "x" , "y".
        local existingKey
        for parameterNames, valueGenerator in pairs(self.parameters) do
            local match = true
            for i = 1, numArguments - 1 do
                local name = select(i, ...)
                if parameterNames[i] ~= name then
                    match = false
                    break
                end
            end
            if match then
                existingKey = parameterNames
                break
            end
        end

        local parameterNames
        if existingKey then
            parameterNames = existingKey
        else        
            parameterNames = {}
            for i = 1, numArguments - 1 do
                local name = select(i, ...)
                table.insert(parameterNames, name)
            end
        end

        local valueGenerator = select(numArguments, ...)
        self.parameters[parameterNames] = valueGenerator
    end
end

function ZO_ParticleSystem:Start()
    if not self.running then
        PARTICLE_SYSTEM_MANAGER:AddParticleSystem(self)
        self.startTimeS = GetGameTimeMilliseconds() / 1000
        self.lastUpdateS = self.startTimeS
        self.unusedDeltaS = 0
        self.running = true
        self.finishing = false
    else
        self.finishing = false
    end
end

function ZO_ParticleSystem:SpawnParticles(numParticlesToSpawn)
    if self.running then
        for particleIndex = 1, numParticlesToSpawn do
            local particle, key = self.particlePool:AcquireObject()
            particle:ResetParameters()
            particle:SetKey(key)

            for parameterNames, valueGenerator in pairs(self.parameters) do
                local valueGeneratorIsObject = type(valueGenerator) == "table" and valueGenerator.GetValue ~= nil
                if valueGeneratorIsObject then
                    valueGenerator:Generate()
                end
                for i, parameterName in ipairs(parameterNames) do
                    if valueGeneratorIsObject then
                        particle:SetParameter(parameterName, valueGenerator:GetValue(i))
                    else
                        particle:SetParameter(parameterName, valueGenerator)
                    end
                end
            end
            self:StartParticle(particle)
        end
    end
end

function ZO_ParticleSystem:StartParticle(particle)
    particle:Start(self.parentControl)
end

do
    local g_removeParticles = {}
    local MAX_PARTICLES_TO_SPAWN_PER_FRAME = 300

    function ZO_ParticleSystem:OnUpdate(timeS)
        local deltaS = timeS - self.lastUpdateS
        
        local durationS = self.durationS
        if durationS then
            if timeS - self.startTimeS > durationS then
                self:Finish()
            end
        end

        if self.finishing then
            if not next(self.particlePool:GetActiveObjects()) then
                self:Stop()
            end
        else
            --Spawn New Particles
            if self.burstNumParticles then
                if self.burstActive then
                    if timeS > self.burstStopTimeS then
                        self.burstActive = false
                        self.burstNumSpawned = nil
                        self:SetParticlesPerSecond(0)
                    end
                else
                    local begin = false
                    if deltaS < 1 then
                        local timeInCycleS = timeS % self.burstCycleDurationS
                        local lastTimeInCycleS = self.lastUpdateS % self.burstCycleDurationS
                        if timeInCycleS > lastTimeInCycleS then
                            if lastTimeInCycleS <= self.burstPhaseS and timeInCycleS >= self.burstPhaseS then
                                begin = true
                            end
                        else
                            if lastTimeInCycleS <= (self.burstPhaseS + self.burstCycleDurationS) and timeInCycleS > self.burstPhaseS then
                                begin = true
                            end
                        end
                    end

                    if begin then
                        self.burstActive = true
                        self.burstStartTimeS = timeS
                        self.burstStopTimeS = timeS + self.burstDurationS
                        self.burstNumSpawned = 0
                    end
                end

                if self.burstActive then
                    local progress = (timeS - self.burstStartTimeS) / self.burstDurationS
                    if self.burstEasingFunction then
                        progress = self.burstEasingFunction(progress)
                    end
                    local numParticlesThatShouldBeSpawned = zo_round(progress * self.burstNumParticles)
                    local numParticlesToSpawn = numParticlesThatShouldBeSpawned - self.burstNumSpawned
                    self.burstNumSpawned = numParticlesThatShouldBeSpawned
                    numParticlesToSpawn = zo_min(numParticlesToSpawn, MAX_PARTICLES_TO_SPAWN_PER_FRAME)
                    self:SpawnParticles(numParticlesToSpawn)
                end
            end

            if self.particlesPerSecond > 0 then
                local numParticlesToSpawn = (deltaS + self.unusedDeltaS) / self.secondsBetweenParticles
                local numFullParticlesToSpawn = zo_floor(numParticlesToSpawn)
                --Any "partial" particles that are left over we store off as unused delta time and then add that into the next update.
                self.unusedDeltaS = (deltaS + self.unusedDeltaS) - numFullParticlesToSpawn * self.secondsBetweenParticles
                numFullParticlesToSpawn = zo_min(numFullParticlesToSpawn, MAX_PARTICLES_TO_SPAWN_PER_FRAME)

                self:SpawnParticles(numFullParticlesToSpawn)
            end
        end

        --Update Particles
        for _, particle in pairs(self.particlePool:GetActiveObjects()) do
            if particle:IsDone(timeS) then
                table.insert(g_removeParticles, particle)
            else
                particle:OnUpdate(timeS)
            end
        end

        --Remove Dead Particles
        if #g_removeParticles then
            for _, particle in ipairs(g_removeParticles) do
                self.particlePool:ReleaseObject(particle:GetKey())
            end
            ZO_ClearNumericallyIndexedTable(g_removeParticles)
        end

        self.lastUpdateS = timeS
    end
end

--Stop and kill all particles
function ZO_ParticleSystem:Stop()
    if self.running then
        PARTICLE_SYSTEM_MANAGER:RemoveParticleSystem(self)
        self.particlePool:ReleaseAllObjects()
        self.running = false
        self.finishing = false
    end
end

--Stop making new particles but let existing particles finish
function ZO_ParticleSystem:Finish()
    if self.running then
        self.finishing = true
    end
end

--Scene Graph Particle System

ZO_SceneGraphParticleSystem = ZO_ParticleSystem:Subclass()

function ZO_SceneGraphParticleSystem:New(...)
    return ZO_ParticleSystem.New(self, ...)
end

function ZO_SceneGraphParticleSystem:Initialize(particleClass, parentNode)
    ZO_ParticleSystem.Initialize(self, particleClass)
    self.parentNode = parentNode
end

function ZO_SceneGraphParticleSystem:StartParticle(particle)
    particle:SetParentNode(self.parentNode)
    ZO_ParticleSystem.StartParticle(self, particle)
end

--Control Particle System

ZO_ControlParticleSystem = ZO_ParticleSystem

--Particle System Manager

ZO_ParticleSystemManager = ZO_Object:Subclass()

function ZO_ParticleSystemManager:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_ParticleSystemManager:Initialize()
    self.texturePool = ZO_ControlPool:New("ZO_ParticleTexture", nil, "ZO_ParticleTexture")
    self.activeParticleSystems = {}
    EVENT_MANAGER:RegisterForUpdate("ZO_ParticleSystemManager", 0, function(timeMS) self:OnUpdate(timeMS / 1000) end)
end

function ZO_ParticleSystemManager:OnUpdate(timeS)
    for i, particleSystem in ipairs(self.activeParticleSystems) do
        particleSystem:OnUpdate(timeS)
    end
end

function ZO_ParticleSystemManager:AddParticleSystem(particleSystem)
    table.insert(self.activeParticleSystems, particleSystem)
end

function ZO_ParticleSystemManager:RemoveParticleSystem(particleSystem)
    for i, searchParticleSystem in ipairs(self.activeParticleSystems) do
        if searchParticleSystem == particleSystem then
            table.remove(self.activeParticleSystems, i)
            break
        end
    end
end

function ZO_ParticleSystemManager:AcquireTexture()
    local textureControl, key = self.texturePool:AcquireObject()
    textureControl.key = key
    return textureControl
end

function ZO_ParticleSystemManager:ReleaseTexture(textureControl)
    self.texturePool:ReleaseObject(textureControl.key)
end

PARTICLE_SYSTEM_MANAGER = ZO_ParticleSystemManager:New()