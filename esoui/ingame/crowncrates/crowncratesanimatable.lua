ZO_CrownCratesAnimatable = ZO_Object:Subclass()

function ZO_CrownCratesAnimatable:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_CrownCratesAnimatable:Initialize(control, animationSource, ...)
    self.control = control
	self.animationSource = animationSource
    control:Create3DRenderSpace()
    self.playingAnimationTimelines = {}
    self.textureControls = {}
    self.particles = {}
    self.nextCallLaterId = 1
    self.callLaterPrefix = string.format("%sCallLater", control:GetName())
    self.callLaters = {}
end

function ZO_CrownCratesAnimatable:AddTexture(textureControl)
	table.insert(self.textureControls, textureControl)
end

function ZO_CrownCratesAnimatable:Reset()
    self:StopAllAnimations()

    self.control:SetHidden(true)
    for _, textureControl in ipairs(self.textureControls) do
        textureControl:SetAlpha(0)
        textureControl:SetMouseEnabled(false)
    end

    for _, callLaterName in pairs(self.callLaters) do
        EVENT_MANAGER:UnregisterForUpdate(callLaterName)
    end

    self:ReleaseAllParticles()
end

function ZO_CrownCratesAnimatable:GetControl()
    return self.control
end

function ZO_CrownCratesAnimatable:AcquireAndApplyAnimationTimeline(animationType, textureControl, customOnStop)
    local animationPool = self.animationSource:GetAnimationPool(animationType)
    local animationTimeline, animationTimelineKey = animationPool:AcquireObject()
    animationTimeline.animationType = animationType
    animationTimeline:SetHandler("OnStop", function(timeline, completedPlaying)
        self:OnAnimationStopped(timeline, animationTimelineKey, animationPool)
        if customOnStop then
            customOnStop(timeline, completedPlaying)
        end
    end)

    if textureControl then
        for i = 1, animationTimeline:GetNumAnimations() do
            local animation = animationTimeline:GetAnimation(i)
            animation:SetAnimatedControl(textureControl)
        end
    end
    
    return animationTimeline
end

function ZO_CrownCratesAnimatable:GetOnePlayingAnimationOfType(animationType)
    for _, animationTimeline in ipairs(self.playingAnimationTimelines) do
        if animationTimeline.animationType == animationType then
            return animationTimeline
        end
    end
end

function ZO_CrownCratesAnimatable:ReverseAnimationsOfType(animationType)
    for _, animationTimeline in ipairs(self.playingAnimationTimelines) do
        if animationTimeline.animationType == animationType then
            if animationTimeline:IsPlayingBackward() then
                animationTimeline:PlayForward()
            else
                animationTimeline:PlayBackward()
            end
        end
    end
end

function ZO_CrownCratesAnimatable:StopAllAnimations()
    if #self.playingAnimationTimelines > 0 then
        --Copy so the iteration doesn't break when we remove a timeline from the table
        local playingAnimationsCopy = {}
        ZO_ShallowTableCopy(self.playingAnimationTimelines, playingAnimationsCopy)
        for _, animationTimeline in ipairs(playingAnimationsCopy) do
            animationTimeline:Stop()
        end
    end
end

function ZO_CrownCratesAnimatable:StopAllAnimationsOfType(animationType)
    if #self.playingAnimationTimelines > 0 then
        --Copy so the iteration doesn't break when we remove a timeline from the table
        local playingAnimationsCopy = {}
        ZO_ShallowTableCopy(self.playingAnimationTimelines, playingAnimationsCopy)
        for _, animationTimeline in ipairs(playingAnimationsCopy) do
            if animationTimeline.animationType == animationType then
                animationTimeline:Stop()
            end
        end
    end
end

function ZO_CrownCratesAnimatable:EnsureAnimationsArePlayingInDirection(animationType, forward)
    local animationTimeline = self:GetOnePlayingAnimationOfType(animationType)
    local backward = not forward
    if animationTimeline then
        if animationTimeline:IsPlayingBackward() ~= backward then
            self:ReverseAnimationsOfType(animationType)
        else
            --Already playing the right direction
        end
        return true
    else
        return false
    end
end

do
    local FORWARD = true
    function ZO_CrownCratesAnimatable:StartAnimation(animationTimeline, direction)
        table.insert(self.playingAnimationTimelines, animationTimeline)
        if direction == nil or direction == FORWARD then
            animationTimeline:PlayFromStart()
        else
            animationTimeline:PlayFromEnd()
        end
    end
end

function ZO_CrownCratesAnimatable:OnAnimationStopped(animationTimeline, animationTimelineKey, animationPool)
    for i, currentAnimationTimeline in ipairs(self.playingAnimationTimelines) do
        if currentAnimationTimeline == animationTimeline then
            table.remove(self.playingAnimationTimelines, i)
            break
        end
    end
    animationPool:ReleaseObject(animationTimelineKey)
end

function ZO_CrownCratesAnimatable:SetupBezierArcBetween(translateAnimation, startX, startY, startZ, endX, endY, endZ, arcHeightInScreenPercent)
    translateAnimation:SetTranslateOffsets(startX, startY, startZ, endX, endY, endZ)

    --The control point starts at the mid point of the direct line from start to end
    local midX = 0.5 * (startX + endX)
    local midY = 0.5 * (startY + endY)
    local midZ = 0.5 * (startZ + endZ)

    --We then add to the Y a certain amount of world units that is a percentage of the screen height
    local frustumWidthMidpointWorld, frustumHeightMidpointWorld = GetWorldDimensionsOfViewFrustumAtDepth(midZ)        
    local yOffset = arcHeightInScreenPercent * frustumHeightMidpointWorld   
    translateAnimation:SetBezierControlPoint(1, midX, midY + yOffset, midZ)
    translateAnimation:SetBezierControlPoint(2, midX, midY + yOffset, midZ)
end

function ZO_CrownCratesAnimatable:AcquireCrateSpecificParticle(particleType, crownCrateParticleEffects)
    self:ReleaseParticle(particleType)
    local particlePool = self.crownCratesManager:GetCrateSpecificCardParticlePool(GetCurrentCrownCrateId(), crownCrateParticleEffects)
    local particle, particleKey = particlePool:AcquireObject()
    return particleType, particle, particlePool, particleKey
end

function ZO_CrownCratesAnimatable:AcquireTierSpecificParticle(particleType, crownCrateTierParticleEffects)
    self:ReleaseParticle(particleType)
    local particlePool = self.crownCratesManager:GetTierSpecificCardParticlePool(self.crownCrateTierId, crownCrateTierParticleEffects)
    local particle, particleKey = particlePool:AcquireObject()
    return particleType, particle, particlePool, particleKey
end

function ZO_CrownCratesAnimatable:StartCrateSpecificParticleEffects(particleType, crownCrateParticleEffects)
    self:StartParticle(self:AcquireCrateSpecificParticle(particleType, crownCrateParticleEffects))
    PlayCrownCrateSpecificParticleSoundAndVibration(GetCurrentCrownCrateId(), crownCrateParticleEffects)
end

function ZO_CrownCratesAnimatable:StartTierSpecificParticleEffects(particleType, crownCrateTierParticleEffects)
	self:StartParticle(self:AcquireTierSpecificParticle(particleType, crownCrateTierParticleEffects))
    PlayCrownCrateTierSpecificParticleSoundAndVibration(self.crownCrateTierId, crownCrateTierParticleEffects)
end

function ZO_CrownCratesAnimatable:StartParticle(particleType, particle, particlePool, particleKey)
    particle.particlePool = particlePool
    particle.particleKey = particleKey
    self.particles[particleType] = particle
    particle:FollowControl(self.control)
    particle:Start()
end

function ZO_CrownCratesAnimatable:ReleaseParticle(particleType)
    local particle = self.particles[particleType]
    if particle then
        particle.particlePool:ReleaseObject(particle.particleKey)
        particle.particlePool = nil
        particle.particleKey = nil
        self.particles[particleType] = nil
    end
end

function ZO_CrownCratesAnimatable:ReleaseAllParticles()
    for particleType in pairs(self.particles) do
        self:ReleaseParticle(particleType)
    end
end

function ZO_CrownCratesAnimatable:DestroyParticle(particleType)
    local particle = self.particles[particleType]
	if particle then
		local key = particle.particleKey
		local pool = particle.particlePool
		self:ReleaseParticle(particleType)
		pool:DestroyFreeObject(key, ZO_CrownCrates.DeleteParticle)
	end
end

function ZO_CrownCratesAnimatable:CallLater(func, ms)
    local id = self.nextCallLaterId
    local name = self.callLaterPrefix..self.nextCallLaterId
    self.nextCallLaterId = self.nextCallLaterId + 1

    EVENT_MANAGER:RegisterForUpdate(name, ms,
        function()
            self.callLaters[id] = nil
            EVENT_MANAGER:UnregisterForUpdate(name)
            func(id)
        end)
    
    self.callLaters[id] = name

    return id
end