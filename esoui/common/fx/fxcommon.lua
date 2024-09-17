-- Pending Loops --

ZO_PendingLoop = ZO_PooledObject:Subclass()

function ZO_PendingLoop:Initialize(objectPool)
    -- controls get re-parented when used, so it doesn't matter what the parent is here as long as it exists
    self.control = ZO_ObjectPool_CreateNamedControl("PendingLoop", "ZO_PendingLoop_Glow", objectPool, GuiRoot)
    self.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_PendingLoop_Timeline", self.control)
    self.animation.control = self.control
    self.control.animation = self.animation
end

function ZO_PendingLoop:Reset()
    self.animation:Stop()
    self.control:SetHidden(true)
    self.control:ClearAnchors()
    if self.owner then
        self.owner.pendingLoop = nil
        self.owner = nil
    end
end

do
    local DEFAULT_INSET = 0

    function ZO_PendingLoop.ApplyToControl(control, pool, inset, isLocked)
        pool = pool or ZO_Pending_LoopAnimation_Pool
        inset = inset or DEFAULT_INSET
        local pendingLoop = pool:AcquireObject()
        local loopControl = pendingLoop.control
        loopControl:SetAnchor(TOPLEFT, control, TOPLEFT, inset, inset)
        loopControl:SetAnchor(BOTTOMRIGHT, control, BOTTOMRIGHT, -inset, -inset)
        loopControl:SetParent(control)
        loopControl:SetHidden(false)
        if isLocked then
            loopControl:SetColor(0.5, 0.5, 0.5)
            loopControl:SetDesaturation(1)
        else
            loopControl:SetColor(1, 1, 1)
            loopControl:SetDesaturation(0)
        end
        pendingLoop.animation:PlayFromStart()
        pendingLoop.owner = control
        control.pendingLoop = pendingLoop
    end
end

do
    local function PendingLoopFactory(pool, key)
        local pendingLoop = ZO_PendingLoop:New(pool)
        pendingLoop:SetPoolAndKey(pool, key)
        return pendingLoop
    end

    ZO_Pending_LoopAnimation_Pool = ZO_ObjectPool:New(PendingLoopFactory, ZO_ObjectPool_DefaultResetObject)
end

-- Blast Particles --

ZO_BlastParticleSystem = ZO_Object.MultiSubclass(ZO_PooledObject, ZO_ControlParticleSystem)

function ZO_BlastParticleSystem:Initialize(objectPool)
    ZO_ControlParticleSystem.Initialize(self, ZO_NumericalPhysicsParticle_Control)

    self:SetParticlesPerSecond(600)
    self:SetDuration(.1)
    self:SetParticleParameter("Texture", "EsoUI/Art/PregameAnimatedBackground/ember.dds")
    self:SetParticleParameter("BlendMode", TEX_BLEND_MODE_ADD)
    self:SetParticleParameter("StartAlpha", 1)
    self:SetParticleParameter("EndAlpha", 0)
    self:SetParticleParameter("DurationS", ZO_UniformRangeGenerator:New(0.7, 1))
    self:SetParticleParameter("PhysicsInitialVelocityElevationRadians", ZO_UniformRangeGenerator:New(0, ZO_TWO_PI))
    self:SetParticleParameter("PhysicsAccelerationElevationRadians1", math.rad(270)) --Down; Right is 0
    self:SetParticleParameter("PhysicsAccelerationMagnitude1", 250)
    local particleR, particleG, particleB = ZO_OFF_WHITE:UnpackRGB()
    self:SetParticleParameter("StartColorR", particleR)
    self:SetParticleParameter("StartColorG", particleG)
    self:SetParticleParameter("StartColorB", particleB)
    self:SetParticleParameter("PhysicsInitialVelocityMagnitude", ZO_UniformRangeGenerator:New(400, 600))
    self:SetParticleParameter("Size", ZO_UniformRangeGenerator:New(6, 12))
    self:SetParticleParameter("PhysicsDragMultiplier", 4)
end

function ZO_BlastParticleSystem:Reset()
    self:Stop()
end

function ZO_BlastParticleSystem:SetReleaseOnStop()
    self:SetOnStopCallback(function()
        self:ReleaseObject()
        self:SetOnStopCallback(nil)
    end)
end

do
    local function BlastParticleSystemFactory(pool, key)
        local blastParticleSystem = ZO_BlastParticleSystem:New(pool)
        blastParticleSystem:SetPoolAndKey(pool, key)
        return blastParticleSystem
    end

    ZO_BlastParticleSystem_Pool = ZO_ObjectPool:New(BlastParticleSystemFactory, ZO_ObjectPool_DefaultResetObject)
end

ZO_BlastParticleSystem_MetaPool = ZO_MetaPool:Subclass()

function ZO_BlastParticleSystem_MetaPool:New()
    return ZO_MetaPool.New(self, ZO_BlastParticleSystem_Pool)
end

function ZO_BlastParticleSystem_MetaPool:AcquireForControl(control, releaseOnStop)
    local object = self:AcquireObject()
    object:SetParentControl(control)
    if releaseOnStop then
        object:SetReleaseOnStop()
    end
    return object
end