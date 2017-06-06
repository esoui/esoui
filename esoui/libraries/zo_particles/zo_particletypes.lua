--Bent Arc Particle

ZO_BentArcParticle = ZO_SceneGraphParticle:Subclass()

function ZO_BentArcParticle:New(...)
    return ZO_SceneGraphParticle.New(self, ...)
end

local cos = math.cos
local sin = math.sin
local lerp = zo_lerp

function ZO_BentArcParticle:OnUpdate(timeS)
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

    self:SetPosition(x, y, z)
end