ZO_WorldParticles = ZO_Object:Subclass()

function ZO_WorldParticles:New()
    local obj = ZO_Object.New(self)
    obj:Initialize()
    return obj
end

function ZO_WorldParticles:Initialize()
    self.updateParticles = {}

    EVENT_MANAGER:RegisterForUpdate("ZO_WorldParticles_Update", 0, function() self:OnUpdate() end)
end

function ZO_WorldParticles:OnUpdate()
    for i, particle in ipairs(self.updateParticles) do
        particle:OnUpdate()
    end
end

function ZO_WorldParticles:AddUpdateParticle(particle)
    table.insert(self.updateParticles, particle)
end

function ZO_WorldParticles:RemoveUpdateParticle(particle)
    for i, searchParticle in ipairs(self.updateParticles) do
        if particle == searchParticle then
            table.remove(self.updateParticles, i)
            break
        end
    end
end


local g_particles = ZO_WorldParticles:New()

ZO_WorldParticle = ZO_Object:Subclass()

function ZO_WorldParticle:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_WorldParticle:Initialize(particleId)
    self.particleId = particleId    
end

function ZO_WorldParticle:Start()
    if self.particleId then
        StartWorldParticleEffect(self.particleId)
    end
end

function ZO_WorldParticle:Stop()
    if self.particleId then
        StopWorldParticleEffect(self.particleId)
    end
end

function ZO_WorldParticle:Reset()
    self:Stop()
    self:UnfollowControl()
end

function ZO_WorldParticle:SetWorldPosition(worldX, worldY, worldZ)
    if self.particleId then
        SetWorldParticleEffectPosition(self.particleId, worldX, worldY, worldZ)
    end
end

function ZO_WorldParticle:SetWorldPositionFromLocal(control, localX, localY, localZ)
    local worldX, worldY, worldZ = control:Convert3DLocalPositionToWorldPosition(localX, localY, localZ)
    self:SetWorldPosition(worldX, worldY, worldZ)
end

function ZO_WorldParticle:SetWorldPositionFromControl(control)
    local worldX, worldY, worldZ = control:Convert3DLocalPositionToWorldPosition(0, 0, 0)
    self:SetWorldPosition(worldX, worldY, worldZ)
end

function ZO_WorldParticle:SetWorldOrientation(pitchRadians, yawRadians, rollRadians)
    if self.particleId then
        SetWorldParticleEffectOrientation(self.particleId, pitchRadians, yawRadians, rollRadians)
    end
end

function ZO_WorldParticle:SetWorldOrientationFromLocal(control, localPitchRadians, localYawRadians, localRollRadians)
    local worldPitchRadians, worldYawRadians, worldRollRadians = control:Convert3DLocalPositionToWorldPosition(localPitchRadians, localYawRadians, localRollRadians)
    self:SetWorldOrientation(worldPitchRadians, worldYawRadians, worldRollRadians)
end

function ZO_WorldParticle:SetWorldOrientationFromControl(control)
    local worldPitchRadians, worldYawRadians, worldRollRadians = control:Convert3DLocalOrientationToWorldOrientation(0, 0, 0)
    self:SetWorldOrientation(worldPitchRadians, worldYawRadians, worldRollRadians)
end

function ZO_WorldParticle:FollowControl(control)
    if self.followControl then
        self:UnfollowControl()
    end
    self.followControl = control
    g_particles:AddUpdateParticle(self)
    
end

function ZO_WorldParticle:UnfollowControl()
    if self.followControl then
        g_particles:RemoveUpdateParticle(self)
        self.followControl = nil
    end
end

function ZO_WorldParticle:UpdateFollowControl()
    self:SetWorldPositionFromControl(self.followControl)
    self:SetWorldOrientationFromControl(self.followControl)
end

function ZO_WorldParticle:OnUpdate()
    if self.followControl then
        self:UpdateFollowControl()
    end
end

function ZO_WorldParticle:SetScale(scale)
    if self.particleId then
        SetWorldParticleEffectScale(self.particleId, scale)
    end
end

function ZO_WorldParticle:Delete()
    if self.particleId then
        DeleteWorldParticleEffect(self.particleId)
        self.particleId = nil
    end
end