--Bent Arc Particle

local cos = math.cos
local sin = math.sin
local atan = math.atan
local atan2 = math.atan2
local zo_lerp = zo_lerp
local zo_floor = zo_floor
local zo_random = zo_random

function ZO_BentArcParticle_OnUpdate(self, timeS)
    local parameters = self.parameters
    local finalMagnitude = parameters["BentArcFinalMagnitude"]
    local velocity = parameters["BentArcVelocity"]
    local azimuthStartRadians = parameters["BentArcAzimuthStartRadians"]
    local elevationStartRadians = parameters["BentArcElevationStartRadians"]
    local azimuthChangeRadians = parameters["BentArcAzimuthChangeRadians"]
    local elevationChangeRadians = parameters["BentArcElevationChangeRadians"]

    local progress = self:GetProgress(timeS)

    local magnitude
    if finalMagnitude then
        local magnitudeProgress = progress
        local easing = parameters["BentArcEasing"]
        if easing then
            magnitudeProgress = easing(progress)
        end
        magnitude = zo_lerp(0, finalMagnitude, magnitudeProgress)
    elseif velocity then
        magnitude = self:GetElapsedTime(timeS) * velocity
    end

    local bendProgress = progress
    local easing = parameters["BentArcBendEasing"]
    if easing then
        bendProgress = easing(progress)
    end
    local azimuthRadians = zo_lerp(azimuthStartRadians, azimuthStartRadians + azimuthChangeRadians, bendProgress)
    local elevationRadians = zo_lerp(elevationStartRadians, elevationStartRadians + elevationChangeRadians, bendProgress)
    
    --Spherical coordinates to Cartesian
    local h = magnitude * cos(elevationRadians)
    local z = h * sin(azimuthRadians)
    local y = magnitude * sin(elevationRadians)
    local x = h * cos(azimuthRadians)

    --X is right, Y is up, Z is toward the screen
    return x, y, z
end

ZO_BentArcParticle_SceneGraph = ZO_SceneGraphParticle:Subclass()
function ZO_BentArcParticle_SceneGraph:OnUpdate(timeS)
    ZO_SceneGraphParticle.OnUpdate(self, timeS)
    self:SetPosition(ZO_BentArcParticle_OnUpdate(self, timeS))
end
function ZO_BentArcParticle_SceneGraph:New(...)
    return ZO_SceneGraphParticle.New(self, ...)
end

ZO_BentArcParticle_Control =  ZO_ControlParticle:Subclass()
function ZO_BentArcParticle_Control:OnUpdate(timeS)
    ZO_ControlParticle.OnUpdate(self, timeS)
    local x, y, z = ZO_BentArcParticle_OnUpdate(self, timeS)
    --Control particles expect that Y is down
    y = -y
    self:SetPosition(x, y, z)

    local parameters = self.parameters
    if parameters["BentArcOrientWithMotion"] then
        --Numerical solution to orient along the spiral. We use the slope between the last two positions to compute the tangent to the spiral. The angle
        --to orient the texture's right-middle point to the spiral is the 2*PI - the tangent's angle, or alternately minus the tangent's angle.
        if self.lastX then
            local angle = atan2(y - self.lastY, x - self.lastX)
            local offsetRadians = parameters["BentArcOrientWithMotionTextureRotationRadians"] or 0
            self.textureControl:SetTextureRotation(-angle - offsetRadians)
        end
        self.lastX = x
        self.lastY = y
    end
end
function ZO_BentArcParticle_Control:New(...)
    return ZO_ControlParticle.New(self, ...)
end

-- Physics Particle

ZO_PhysicsParticle_Control =  ZO_ControlParticle:Subclass()

function ZO_PhysicsParticle_Control:New(...)
    return ZO_ControlParticle.New(self, ...)
end

local MAX_ACCELERATIONS = 5
local ACCELERATION_ELEVATION_RADIANS_PARAMETER_NAMES = {}
local ACCELERATION_MAGNITUDE_PARAMETER_NAMES = {}
for accelerationIndex = 1, MAX_ACCELERATIONS do
    table.insert(ACCELERATION_ELEVATION_RADIANS_PARAMETER_NAMES, "PhysicsAccelerationElevationRadians" .. accelerationIndex)
    table.insert(ACCELERATION_MAGNITUDE_PARAMETER_NAMES, "PhysicsAccelerationMagnitude" .. accelerationIndex)
end

function ZO_PhysicsParticle_Control:Start(...)
    ZO_ControlParticle.Start(self, ...)
    
    self.velocityX = 0
    self.velocityY = 0

    local parameters = self.parameters
    local initialVelocityElevationRadians = parameters["PhysicsInitialVelocityElevationRadians"]
    if initialVelocityElevationRadians then
        local initialVelocityMagnitude = parameters["PhysicsInitialVelocityMagnitude"]
        if initialVelocityMagnitude then
            self.velocityX = initialVelocityMagnitude * cos(initialVelocityElevationRadians)
            self.velocityY = initialVelocityMagnitude * sin(initialVelocityElevationRadians)
        end
    end

    local combinedAccelerationX = 0
    local combinedAccelerationY = 0

    for accelerationIndex = 1, MAX_ACCELERATIONS do
        local accelerationElevationRadians = parameters[ACCELERATION_ELEVATION_RADIANS_PARAMETER_NAMES[accelerationIndex]]
        if not accelerationElevationRadians then
            break
        end
        local accelerationMagnitude = parameters[ACCELERATION_MAGNITUDE_PARAMETER_NAMES[accelerationIndex]]
        if not accelerationMagnitude then
            break
        end

        local accelerationX = accelerationMagnitude * cos(accelerationElevationRadians)
        local accelerationY = accelerationMagnitude * sin(accelerationElevationRadians)
        combinedAccelerationX = combinedAccelerationX + accelerationX
        combinedAccelerationY = combinedAccelerationY + accelerationY
    end

    self.combinedAccelerationX = combinedAccelerationX
    self.combinedAccelerationY = combinedAccelerationY
end

--Numerical can do complex calculations like drag, but it does so by doing calculations in intervals, since it's not a simple equation of time
ZO_NumericalPhysicsParticle_Control =  ZO_PhysicsParticle_Control:Subclass()

function ZO_NumericalPhysicsParticle_Control:New(...)
    return ZO_PhysicsParticle_Control.New(self, ...)
end

do
    local DEFAULT_MIN_STEPS_PER_SECOND = 30
    local MAX_STEPS_FOR_UPDATE = 10

    function ZO_NumericalPhysicsParticle_Control:Start(...)
        ZO_PhysicsParticle_Control.Start(self, ...)
    
        self.lastUpdateTimeS = self.startTimeS
        self.displacementX = 0
        self.displacementY = 0

        local parameters = self.parameters
        local minStepsPerSecond = parameters["PhysicsMinStepsPerSecond"] or DEFAULT_MIN_STEPS_PER_SECOND
        self.minStepIntervalS = 1 / minStepsPerSecond
        self.maxTimeForMinStepIntervalsS = self.minStepIntervalS * MAX_STEPS_FOR_UPDATE

        self.dragMultiplier = parameters["PhysicsDragMultiplier"] or 0
    end

    function ZO_NumericalPhysicsParticle_Control:OnUpdate(timeS)
        ZO_PhysicsParticle_Control.OnUpdate(self, timeS)

        local lastUpdateTimeS = self.lastUpdateTimeS
        local timeSinceLastUpdateS = timeS - lastUpdateTimeS
    
        local stepsIntervalS = self.minStepIntervalS

        if timeSinceLastUpdateS < stepsIntervalS then
            stepsIntervalS = timeSinceLastUpdateS
        elseif timeSinceLastUpdateS > self.maxTimeForMinStepIntervalsS then
            -- If we've hit a long spike since the last update, split the delta into equal intervals looping up to MAX_STEPS_FOR_UPDATE times to catch up
            stepsIntervalS = timeSinceLastUpdateS / MAX_STEPS_FOR_UPDATE
        end

        local displacementX = self.displacementX
        local displacementY = self.displacementY
        local velocityX = self.velocityX
        local velocityY = self.velocityY

        local velocityChangePerStepX = self.combinedAccelerationX * stepsIntervalS
        local velocityChangePerStepY = self.combinedAccelerationY * stepsIntervalS

        local dragMultiplier = self.dragMultiplier

        repeat
            local dragVelocityChangeX = velocityX * dragMultiplier * stepsIntervalS
            local dragVelocityChangeY = velocityY * dragMultiplier * stepsIntervalS
            velocityX = velocityX + velocityChangePerStepX - dragVelocityChangeX
            velocityY = velocityY + velocityChangePerStepY - dragVelocityChangeY
            ----------------------------------------------------------------------
            displacementX = displacementX + (velocityX * stepsIntervalS)
            displacementY = displacementY + (velocityY * stepsIntervalS)

            lastUpdateTimeS = lastUpdateTimeS + stepsIntervalS
        until (lastUpdateTimeS + stepsIntervalS) > timeS

        self.lastUpdateTimeS = lastUpdateTimeS
        self.displacementX = displacementX
        self.displacementY = displacementY
        self.velocityX = velocityX
        self.velocityY = velocityY

        --Control particles expect that Y is down
        self:SetPosition(displacementX, -displacementY, 0)
    end
end

--Analytical calculates physics as a direct equation of elapsed time.  Does not support complex functionality like drag
ZO_AnalyticalPhysicsParticle_Control =  ZO_PhysicsParticle_Control:Subclass()

function ZO_AnalyticalPhysicsParticle_Control:New(...)
    return ZO_PhysicsParticle_Control.New(self, ...)
end

function ZO_AnalyticalPhysicsParticle_Control:OnUpdate(timeS)
    ZO_PhysicsParticle_Control.OnUpdate(self, timeS)

    local elapsedTimeS = timeS - self.startTimeS

    local velocityChangeX = self.combinedAccelerationX * elapsedTimeS
    local velocityChangeY = self.combinedAccelerationY * elapsedTimeS

    local x = (self.velocityX + velocityChangeX) * elapsedTimeS
    local y = (self.velocityY + velocityChangeY) * elapsedTimeS

    --Control particles expect that Y is down
    self:SetPosition(x, -y, 0)
end

--Stationary Paricle

ZO_StationaryParticle_Control = ZO_ControlParticle:Subclass()

function ZO_StationaryParticle_Control:New(...)
    return ZO_ControlParticle.New(self, ...)
end

function ZO_StationaryParticle_Control:OnUpdate(timeS)
    ZO_ControlParticle.OnUpdate(self, timeS)

    -- Offset is handled in the base update, and SetPosition takes that into consideration
    self:SetPosition(0, 0, 0)
end

--Leaf Particle 
--A leaf like motion to the right and down from the origin, based on following sections of a tangent curve. Specify the top and bottom (y-values) and the leaf will move through that
--section of the tangent curve. Descent is a factor on the tangent curve (0, infinity). Higher descents make a steeper curve, while lower descents mean a gentler curve. Fall height is the
--UI space height that the curve will be mapped to. The code that orients the leaf to the direction of travel assumes that the leaf point is a 0 degrees on the unit circle. If that is not true
--it can be corrected by rotating the leaf using LeafTextureRotationRadians.

ZO_LeafParticle_Control = ZO_ControlParticle:Subclass()

function ZO_LeafParticle_Control:New(...)
    return ZO_ControlParticle.New(self, ...)
end

--Inverse of y = -descent * tan(x)
local function ComputeSectionX(sectionY, descent)
    return atan(-sectionY / descent)
end

function ZO_LeafParticle_Control:Start(...)
    ZO_ControlParticle.Start(self, ...)

    local parameters = self.parameters
    self.sectionTopX = ComputeSectionX(parameters["LeafSectionTop"], parameters["LeafDescent"])
end

function ZO_LeafParticle_Control:OnUpdate(timeS)
    ZO_ControlParticle.OnUpdate(self, timeS)

    local progress = self:GetProgress(timeS)
    local parameters = self.parameters

    local easing = parameters["LeafEasing"]
    if easing then
        progress = easing(progress)
    end

    local sectionTopY = parameters["LeafSectionTop"]
    local sectionBottomY = parameters["LeafSectionBottom"]
    local descent = parameters["LeafDescent"]
    local sectionHeight = sectionTopY - sectionBottomY
    local fallHeight = parameters["LeafFallHeight"]
    local leafTextureRotationRadians = parameters["LeafTextureRotationRadians"]

    --We move linearly from 0 to fallHeight along the Y (This means that the more the curve travels in the X the faster it goes through that section. It is not constant velocity).
    local offsetY = fallHeight * progress
    --Figure out where we are vertically on the section of the tangent curve
    local sectionY = zo_lerp(sectionTopY, sectionBottomY, progress)
    --Find the X the corresponds to that Y
    local sectionX = ComputeSectionX(sectionY, descent)
    --Convert that to an offset from the starting X value
    local sectionOffsetX = sectionX - self.sectionTopX
    --Finally, scale this offset to UI coordinates using the correspondence between the section height and the fall height to determine the scaling factor
    local offsetX = (sectionOffsetX / sectionHeight) * fallHeight

    --The derivative of -descent * tan(x) is -descent/cos^2(x). Orient the texture 0 radian point to the direction of travel.
    local cosSectionX = cos(sectionX)
    local slope = -descent / (cosSectionX * cosSectionX)
    local tumbleRadians = parameters["LeafTumbleRadians"]
    self.textureControl:SetTextureRotation(math.atan(slope) + leafTextureRotationRadians + tumbleRadians * progress)

    self:SetPosition(offsetX, offsetY, 0)
end

--Flow Particle
--Sends the particle through a series of "posts" that describe a set of vertical ranges. For example:
--
--
--  *   *       *   *       *           *
--  *   *   *   *   *   *   *   *   *   *
--      *   *   *   *   *   *   *   **
--          *   *       *   *   *
--
--Particles will be assigned a normalized vertical offset and travel from post to post across where that normalized offset would lie.
--For example, if a particle was assigned 50% it would travel through the middle of each post, interpolating from middle to middle inbetween the posts.

ZO_FlowParticle_Control = ZO_ControlParticle:Subclass()

function ZO_FlowParticle_Control:New(...)
    return ZO_ControlParticle.New(self, ...)
end

function ZO_FlowParticle_Control:Start(...)
    ZO_ControlParticle.Start(self, ...)

    self.normalizedY = zo_random()
end

function ZO_FlowParticle_Control:OnUpdate(timeS)
    ZO_ControlParticle.OnUpdate(self, timeS)

    local progress = self:GetProgress(timeS)
    local parameters = self.parameters

    local areaTop = parameters["FlowAreaTop"]
    local areaBottom = parameters["FlowAreaBottom"]
    local areaLeft = parameters["FlowAreaLeft"]
    local areaRight = parameters["FlowAreaRight"]
    local normalizedPosts = parameters["FlowNormalizedPosts"]
    local numPosts = #normalizedPosts

    local temp = progress * (numPosts - 1)
    local progressBetweenPosts = temp % 1
    local previousPostIndex = zo_floor(temp) + 1
    local previousPost = normalizedPosts[previousPostIndex]
    --the or handles the case where progress is exactly 1
    local nextPost = normalizedPosts[previousPostIndex + 1] or normalizedPosts[numPosts]
    --index 1 holds the top of the post and index 2 holds the bottom of the post
    local normalizedFlowTop = zo_lerp(previousPost[1], nextPost[1], progressBetweenPosts)
    local normalizedFlowBottom = zo_lerp(previousPost[2], nextPost[2], progressBetweenPosts)
    local normalizedY = zo_lerp(normalizedFlowTop, normalizedFlowBottom, self.normalizedY)
    local offsetY = zo_lerp(areaTop, areaBottom, normalizedY)
    local offsetX = zo_lerp(areaLeft, areaRight, progress)

    self:SetPosition(offsetX, offsetY, 0)
end