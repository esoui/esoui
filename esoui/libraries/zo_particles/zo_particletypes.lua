--Bent Arc Particle

local cos = math.cos
local sin = math.sin
local lerp = zo_lerp

function ZO_BentArcParticle_OnUpdate(self, timeS)
    ZO_Particle.OnUpdate(self, timeS)

    local parameters = self.parameters
    local finalMagnitude = parameters["BentArcFinalMagnitude"]
    local velocity = parameters["BentArcVelocity"]
    local AzimuthStartRadians = parameters["BentArcAzimuthStartRadians"]
    local ElevationStartRadians = parameters["BentArcElevationStartRadians"]
    local AzimuthChangeRadians = parameters["BentArcAzimuthChangeRadians"]
    local ElevationChangeRadians = parameters["BentArcElevationChangeRadians"]

    local progress = self:GetProgress(timeS)

    local magnitude
    if finalMagnitude then
        local magnitudeProgress = progress
        local easing = parameters["BentArcEasing"]
        if easing then
            magnitudeProgress = easing(progress)
        end
        magnitude = zo_lerp(0, finalMagnitude, progress)
    elseif velocity then
        magnitude = self:GetElapsedTime(timeS) * velocity
    end

    local bendProgress = progress
    local easing = parameters["BentArcBendEasing"]
    if easing then
        bendProgress = easing(progress)
    end
    local AzimuthRadians = lerp(AzimuthStartRadians, AzimuthStartRadians + AzimuthChangeRadians, bendProgress)
    local ElevationRadians = lerp(ElevationStartRadians, ElevationStartRadians + ElevationChangeRadians, bendProgress)
    
    --Spherical coordinates to Cartesian
    local h = magnitude * cos(ElevationRadians)
    local z = h * sin(AzimuthRadians)
    local y = magnitude * sin(ElevationRadians)
    local x = h * cos(AzimuthRadians)

    --X is right, Y is up, Z is toward the screen
    return x, y, z
end

ZO_BentArcParticle_SceneGraph = ZO_SceneGraphParticle:Subclass()
function ZO_BentArcParticle_SceneGraph:OnUpdate(timeS)
    self:SetPosition(ZO_BentArcParticle_OnUpdate(self, timeS))
end
function ZO_BentArcParticle_SceneGraph:New(...)
    return ZO_SceneGraphParticle.New(self, ...)
end

ZO_BentArcParticle_Control =  ZO_ControlParticle:Subclass()
function ZO_BentArcParticle_Control:OnUpdate(timeS)
    local x, y, z = ZO_BentArcParticle_OnUpdate(self, timeS)
    --Control particles expect that Y is down
    self:SetPosition(x, -y, z)
end
function ZO_BentArcParticle_Control:New(...)
    return ZO_ControlParticle.New(self, ...)
end