ZO_Particles = ZO_Object:Subclass()

function ZO_Particles:New()
    local obj = ZO_Object.New(self)
    obj:Initialize()
    return obj
end

function ZO_Particles:Initialize()
    self.updateParticles = {}

    EVENT_MANAGER:RegisterForUpdate("ZO_Particles_Update", 0, function() self:OnUpdate() end)
end

function ZO_Particles:OnUpdate()
    for i, particle in ipairs(self.updateParticles) do
        particle:OnUpdate()
    end
end

function ZO_Particles:AddUpdateParticle(particle)
    table.insert(self.updateParticles, particle)
end

function ZO_Particles:RemoveUpdateParticle(particle)
    for i, searchParticle in ipairs(self.updateParticles) do
        if particle == searchParticle then
            table.remove(self.updateParticles, i)
            break
        end
    end
end


local g_particles = ZO_Particles:New()

ZO_Particle = ZO_Object:Subclass()

function ZO_Particle:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_Particle:Initialize(particleId)
    self.particleId = particleId    
end

function ZO_Particle:Start()
    if self.particleId then
        StartWorldParticleEffect(self.particleId)
    end
end

function ZO_Particle:Stop()
    if self.particleId then
        StopWorldParticleEffect(self.particleId)
    end
end

function ZO_Particle:Reset()
    self:Stop()
    self:UnfollowControl()
end

function ZO_Particle:SetWorldPosition(worldX, worldY, worldZ)
    if self.particleId then
        SetWorldParticleEffectPosition(self.particleId, worldX, worldY, worldZ)
    end
end

function ZO_Particle:SetWorldPositionFromLocal(control, localX, localY, localZ)
    local worldX, worldY, worldZ = control:Convert3DLocalPositionToWorldPosition(localX, localY, localZ)
    self:SetWorldPosition(worldX, worldY, worldZ)
end

function ZO_Particle:SetWorldPositionFromControl(control)
    local worldX, worldY, worldZ = control:Convert3DLocalPositionToWorldPosition(0, 0, 0)
    self:SetWorldPosition(worldX, worldY, worldZ)
end

function ZO_Particle:SetWorldOrientation(pitchRadians, yawRadians, rollRadians)
    if self.particleId then
        SetWorldParticleEffectOrientation(self.particleId, pitchRadians, yawRadians, rollRadians)
    end
end

function ZO_Particle:SetWorldOrientationFromLocal(control, localPitchRadians, localYawRadians, localRollRadians)
    local worldPitchRadians, worldYawRadians, worldRollRadians = control:Convert3DLocalPositionToWorldPosition(localPitchRadians, localYawRadians, localRollRadians)
    self:SetWorldOrientation(worldPitchRadians, worldYawRadians, worldRollRadians)
end

function ZO_Particle:SetWorldOrientationFromControl(control)
    local worldPitchRadians, worldYawRadians, worldRollRadians = control:Convert3DLocalOrientationToWorldOrientation(0, 0, 0)
    self:SetWorldOrientation(worldPitchRadians, worldYawRadians, worldRollRadians)
end

function ZO_Particle:FollowControl(control)
    if self.followControl then
        self:UnfollowControl()
    end
    self.followControl = control
    g_particles:AddUpdateParticle(self)
    
end

function ZO_Particle:UnfollowControl()
    if self.followControl then
        g_particles:RemoveUpdateParticle(self)
        self.followControl = nil
    end
end

function ZO_Particle:UpdateFollowControl()
    self:SetWorldPositionFromControl(self.followControl)
    self:SetWorldOrientationFromControl(self.followControl)
end

function ZO_Particle:OnUpdate()
    if self.followControl then
        self:UpdateFollowControl()
    end
end

function ZO_Particle:SetScale(scale)
    if self.particleId then
        SetWorldParticleEffectScale(self.particleId, scale)
    end
end

function ZO_Particle:Delete()
    if self.particleId then
        DeleteWorldParticleEffect(self.particleId)
        self.particleId = nil
    end
end