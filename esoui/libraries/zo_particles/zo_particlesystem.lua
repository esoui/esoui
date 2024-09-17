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
        local function Reset(particle)
            particle:Stop()
        end
        local pool = ZO_ObjectPool:New(particleClass, Reset)
        ZO_ParticleSystem.particleClassToPool[particleClass] = pool
    end
    self.particlePool = ZO_MetaPool:New(ZO_ParticleSystem.particleClassToPool[particleClass])

    self.parameters = {}
    self:SetParticlesPerSecond(0)
    self.startPrimeS = 0
end

function ZO_ParticleSystem:SetDuration(durationS)
    self.durationS = durationS
end

function ZO_ParticleSystem:SetStartPrimeS(primeS)
    self.startPrimeS = primeS
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
end

function ZO_ParticleSystem:IsBurstMode()
    return self.burstNumParticles ~= nil
end

function ZO_ParticleSystem:SetBurstEasing(easingFunction)
    self.burstEasingFunction = easingFunction
end

function ZO_ParticleSystem:SetParentControl(parentControl)
    self.parentControl = parentControl
end

--This is the sound that will play on start, or on each burst if it's a burst system
function ZO_ParticleSystem:SetSound(sound)
    self.sound = sound
end

function ZO_ParticleSystem:SetOnParticleStartCallback(callback)
   self.onParticleStartCallback = callback 
end

function ZO_ParticleSystem:SetOnParticleStopCallback(callback)
    self.onParticleStopCallback = callback
end

function ZO_ParticleSystem:SetOnStartCallback(callback)
   self.onStartCallback = callback 
end

function ZO_ParticleSystem:SetOnStopCallback(callback)
    self.onStopCallback = callback
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
        for parameterNames, _ in pairs(self.parameters) do
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
        -- With priming, we pretend like the system had started some time ago and let the system play catch up
        -- This allows for situations like an emitter seeming like it had already been emitting before we ever showed the scene,
        -- so that the player doesn't see it filling out in the beginning
        self.startTimeS = GetGameTimeSeconds() - self.startPrimeS
        self.lastUpdateS = self.startTimeS
        self.unusedDeltaS = self.startPrimeS
        self.running = true
        self.finishing = false
        if not self:IsBurstMode() then
            PlaySound(self.sound)
        end
        if self.onStartCallback then
            self:onStartCallback()
        end
    else
        self.finishing = false
    end
end

function ZO_ParticleSystem:SpawnParticles(numParticlesToSpawn, startTimeS, endTimeS, intervalS)
    if numParticlesToSpawn == 0 then
        return
    end
    
    local MAX_PARTICLES_TO_SPAWN_PER_FRAME = 300
    numParticlesToSpawn = zo_min(numParticlesToSpawn, MAX_PARTICLES_TO_SPAWN_PER_FRAME)

    if not intervalS then
        intervalS = (endTimeS - startTimeS) / numParticlesToSpawn
    end

    local nowS = GetGameTimeSeconds()
    local particleSpawnTimeS = startTimeS + intervalS
    for particleSpawnIndex = 1, numParticlesToSpawn do
        local particle, key = self.particlePool:AcquireObject()
        particle:ResetParameters()
        particle:SetKey(key)
        local isParticleAlreadyDead = false
        -- This is the prime for the individual particle, not for the system
        local spawnTimePrimeS = 0
        for parameterNames, valueGenerator in pairs(self.parameters) do
            local valueGeneratorIsObject = type(valueGenerator) == "table" and valueGenerator.GetValue ~= nil
            if valueGeneratorIsObject then
                valueGenerator:Generate()
            end
            for i, parameterName in ipairs(parameterNames) do
                if parameterName == "DurationS" then
                    local durationS = valueGeneratorIsObject and valueGenerator:GetValue(i) or valueGenerator
                    if particleSpawnTimeS + durationS < nowS then
                        -- Don't bother starting up a particle that's effectively already dead
                        isParticleAlreadyDead = true
                        break
                    end
                elseif parameterName == "PrimeS" then
                    spawnTimePrimeS = valueGeneratorIsObject and valueGenerator:GetValue(i) or valueGenerator
                end

                if valueGeneratorIsObject then
                    particle:SetParameter(parameterName, valueGenerator:GetValue(i))
                else
                    particle:SetParameter(parameterName, valueGenerator)
                end
            end
        end

        if isParticleAlreadyDead then
            self.particlePool:ReleaseObject(key)
        else
            self:StartParticle(particle, particleSpawnTimeS - spawnTimePrimeS, nowS)
        end
        
        particleSpawnTimeS = particleSpawnTimeS + intervalS
    end
end

function ZO_ParticleSystem:StartParticle(particle, startTimeS, nowS)
    particle:Start(self.parentControl, startTimeS, nowS)
    if self.onParticleStartCallback then
        self.onParticleStartCallback(particle)
    end
end

function ZO_ParticleSystem:StopParticle(particle)
    if self.onParticleStopCallback then
        self.onParticleStopCallback(particle)
    end
    self.particlePool:ReleaseObject(particle:GetKey())
end

do
    local g_removeParticles = {}

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
            if self:IsBurstMode() then
                local elapsedTimeS = timeS - self.startTimeS
                if elapsedTimeS > 0 then
                    local lastElapsedUpdateTimeS = self.lastUpdateS - self.startTimeS
                    -- How far into the current cycle are we?
                    local timeInCycleS = elapsedTimeS % self.burstCycleDurationS
                    -- When did the current cycle begin?
                    local timeCycleStartedS = timeS - timeInCycleS
                    -- New burst
                    if self.lastUpdateS <= timeCycleStartedS then
                        self.burstNumSpawned = 0
                        self.burstStartTimeS = timeCycleStartedS + self.burstPhaseS
                        self.burstStopTimeS = self.burstStartTimeS + self.burstDurationS
                    end

                    --We're after when we would have started emitting, and we haven't emitted enough particles
                    if self.burstNumSpawned < self.burstNumParticles and timeInCycleS > self.burstPhaseS then
                        local progress = 1
                        if timeS < self.burstStopTimeS then
                            progress = (timeS - self.burstStartTimeS) / self.burstDurationS
                        end
                        if self.burstEasingFunction then
                            progress = self.burstEasingFunction(progress)
                        end

                        local numParticlesThatShouldBeSpawned = zo_round(progress * self.burstNumParticles)
                        local numParticlesToSpawn = numParticlesThatShouldBeSpawned - self.burstNumSpawned

                        --Play the sound the first time particles start bursting
                        if self.burstNumSpawned == 0 and numParticlesToSpawn > 0 then
                            PlaySound(self.sound)
                        end

                        self.burstNumSpawned = numParticlesThatShouldBeSpawned
                        local startTimeS = zo_max(self.lastUpdateS, self.burstStartTimeS)
                        local endTimeS = zo_min(timeS, self.burstStopTimeS)
                        self:SpawnParticles(numParticlesToSpawn, startTimeS, endTimeS)
                    end
                end
            elseif self.particlesPerSecond > 0 then
                local secondsSinceLastParticle = deltaS + self.unusedDeltaS
                local numParticlesToSpawn = zo_floor(secondsSinceLastParticle / self.secondsBetweenParticles)
                --Any "partial" particles that are left over we store off as unused delta time and then add that into the next update.
                local processedDeltaS = numParticlesToSpawn * self.secondsBetweenParticles
                self.unusedDeltaS = secondsSinceLastParticle - processedDeltaS
                self:SpawnParticles(numParticlesToSpawn, timeS - secondsSinceLastParticle, timeS, self.secondsBetweenParticles)
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
                self:StopParticle(particle)
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
        if self.onStopCallback then
            self:onStopCallback()
        end
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

function ZO_SceneGraphParticleSystem:StartParticle(particle, startTimeS, nowS)
    particle:SetParentNode(self.parentNode)
    ZO_ParticleSystem.StartParticle(self, particle, startTimeS, nowS)
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
    self.animationTimelinePool = ZO_AnimationPool:New("ZO_ParticleAnimationTimeline")
    self.buildingAnimationTimelinePlaybackTypes = {}
    self.buildingAnimationTimelineLoopCounts = {}
    self.activeParticleSystems = {}
    EVENT_MANAGER:RegisterForUpdate("ZO_ParticleSystemManager", 0, function(timeMS) self:OnUpdate(timeMS / 1000) end)
end

function ZO_ParticleSystemManager:OnUpdate(timeS)
    for _, particleSystem in ipairs(self.activeParticleSystems) do
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

function ZO_ParticleSystemManager:GetAnimation(control, playbackInfo, animationType, easingFunction, durationS, offsetS)
    --Collect all of the timelines until FinishBuildingAnimationTimelines is called
    if not self.buildingAnimationTimelines then
        self.buildingAnimationTimelines = {}
    end

    local playbackType = ANIMATION_PLAYBACK_ONE_SHOT
    local loopCount = 1
    if playbackInfo then
        playbackType = playbackInfo.playbackType or ANIMATION_PLAYBACK_ONE_SHOT
        loopCount = playbackInfo.loopCount or 1
    end
    offsetS = offsetS or 0

    local timeline
    --One shot animations all belong to the same timeline. LOOP and PING_PONG animations use separate timelines so they can LOOP and PING_PONG at their own durations.
    if playbackType == ANIMATION_PLAYBACK_ONE_SHOT then
        for i = 1, #self.buildingAnimationTimelines do
            if self.buildingAnimationTimelinePlaybackTypes[i] == playbackType and self.buildingAnimationTimelineLoopCounts[i] == loopCount then
                timeline = self.buildingAnimationTimelines[i]
                break
            end
        end
    end

    if not timeline then
        local key
        timeline, key = self.animationTimelinePool:AcquireObject()
        timeline.key = key
        timeline:SetPlaybackType(playbackType, loopCount)
        table.insert(self.buildingAnimationTimelines, timeline)
        table.insert(self.buildingAnimationTimelinePlaybackTypes, playbackType)
        table.insert(self.buildingAnimationTimelineLoopCounts, loopCount)
    end

    local animation = timeline:GetFirstAnimationOfType(animationType)
    if not animation then
        animation = timeline:InsertAnimation(animationType, control, offsetS)
    else
        animation:SetAnimatedControl(control)
        animation:SetEnabled(true)
        timeline:SetAnimationOffset(animation, offsetS)
    end
    animation:SetDuration(durationS * 1000)
    animation:SetEasingFunction(easingFunction)

    return animation
end

function ZO_ParticleSystemManager:FinishBuildingAnimationTimelines()
    if self.buildingAnimationTimelines then
        ZO_ClearNumericallyIndexedTable(self.buildingAnimationTimelinePlaybackTypes)
        ZO_ClearNumericallyIndexedTable(self.buildingAnimationTimelineLoopCounts)
        local timelines = self.buildingAnimationTimelines
        self.buildingAnimationTimelines = nil
        return timelines
    else
        return nil
    end
end

function ZO_ParticleSystemManager:ReleaseAnimationTimelines(animationTimelines)
    for _, animationTimeline in ipairs(animationTimelines) do
        for i = 1, animationTimeline:GetNumAnimations() do
            local animation = animationTimeline:GetAnimation(i)
            animation:SetEnabled(false)
        end
        self.animationTimelinePool:ReleaseObject(animationTimeline.key)
    end
end

PARTICLE_SYSTEM_MANAGER = ZO_ParticleSystemManager:New()