--Camera Wander

local CameraWander = ZO_Object:Subclass()

function CameraWander:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function CameraWander:Initialize(speed, magnitude)
    self.speed = speed
    self.magnitude = magnitude
    self.startX = 0
    self.startY = 0
    self.currentX = 0
    self.currentY = 0
end

function CameraWander:Start()
    self:AcquireTarget()
end

do
    local MIN_DIFFERENCE_RADIANS = math.pi / 4
    local NEW_ANGLE_RANGE_RADIANS = math.pi
    local TWO_PI = 2 * math.pi

    function CameraWander:AcquireTarget()
        if not self.targetAngle then
            --Choose any angle the first time
            self.targetAngle = zo_random() * TWO_PI
        else
            --Subsequent times, choose angles that are at least MIN_DIFFERENCE_RADIANS away from the last angle.
            self.targetAngle = zo_mod(self.targetAngle + MIN_DIFFERENCE_RADIANS + zo_random() * NEW_ANGLE_RANGE_RADIANS, TWO_PI)
        end
        self.targetX = math.cos(self.targetAngle) * self.magnitude
        self.targetY = math.sin(self.targetAngle) * self.magnitude
        local diffX = self.targetX - self.startX
        local diffY = self.targetY - self.startY
        local distance = zo_sqrt(diffX * diffX + diffY * diffY)
        self.startTimeS = GetGameTimeMilliseconds() / 1000
        --Compute the end time from the distance and speed so the camera always moves at the same speed
        self.endTimeS = self.startTimeS + distance / self.speed
    end
end

function CameraWander:Update(timeS)
    if self.startTimeS then
        if timeS > self.endTimeS then
            --The new start is the old end
            self.startX = self.targetX
            self.startY = self.targetY
            self:AcquireTarget()
        end
        
        local timeFromStartS = timeS - self.startTimeS
        local progress = timeFromStartS / (self.endTimeS - self.startTimeS)
        progress = ZO_EaseInOutQuadratic(progress)
        self.currentX = zo_lerp(self.startX, self.targetX, progress)
        self.currentY = zo_lerp(self.startY, self.targetY, progress)
    end
    
    return self.currentX, self.currentY
end

local MorrowindBackground = ZO_Object:Subclass()

local GROUND_AREA_MIN_WIDTH = 1920
local GROUND_AREA_MAX_WIDTH = 2048
local GROUND_AREA_MIN_HEIGHT = 1080
local GROUND_AREA_MAX_HEIGHT = 1152
local GROUND_AREA_TEXTURE_SIZE = 2048
local GROUND_AREA_MIN_WIDTH_PERCENT_OF_TEXTURE_SIZE = GROUND_AREA_MIN_WIDTH / GROUND_AREA_TEXTURE_SIZE
local GROUND_AREA_MAX_WIDTH_PERCENT_OF_TEXTURE_SIZE = GROUND_AREA_MAX_WIDTH / GROUND_AREA_TEXTURE_SIZE
local GROUND_AREA_MIN_HEIGHT_PERCENT_OF_TEXTURE_SIZE = GROUND_AREA_MIN_HEIGHT / GROUND_AREA_TEXTURE_SIZE
local GROUND_AREA_MAX_HEIGHT_PERCENT_OF_TEXTURE_SIZE = GROUND_AREA_MAX_HEIGHT / GROUND_AREA_TEXTURE_SIZE
local GROUND_AREA_DEPTH = 0
local GROUND_AREA_ASPECT_RATIO = GROUND_AREA_MAX_WIDTH / GROUND_AREA_MAX_HEIGHT

local GROUND_DEPTH = GROUND_AREA_DEPTH
local SMOKE_DEPTH = -0.01
local LAVA_BURST_DEPTH = -0.01
local SMOKE_DEPTH = -0.3
local CLOUDS_DEPTH = -0.6
local CAMERA_END_DEPTH = -0.8
local CAMERA_START_DEPTH = -1

local CAMERA_WANDER_SPEED = 2
local CAMERA_WANDER_DISTANCE = 30

local SMOKE_1_ORIGIN_X = -450
local SMOKE_1_ORIGIN_Y = -420
local SMOKE_1_DELTA_X = 50
local SMOKE_1_DELTA_Y = 50
local SMOKE_1_WIDTH = 800
local SMOKE_1_HEIGHT = 700
local SMOKE_2_ORIGIN_X = 250
local SMOKE_2_ORIGIN_Y = 300
local SMOKE_2_DELTA_X = 100
local SMOKE_2_DELTA_Y = 50
local SMOKE_2_WIDTH = 700
local SMOKE_2_HEIGHT = 700
local SMOKE_SPEED_FACTOR = 0.05

local LAVA_GLOW_SLOW_SPEED_FACTOR = 1
local LAVA_GLOW_SLOW_AMOUNT = 0.2
local LAVA_GLOW_FAST_SPEED_FACTOR = 0.3
local LAVA_GLOW_FAST_AMOUNT = 0.1

ZO_MORROWIND_BACKGROUND_FADE_DURATION_MS = 500
ZO_MORROWIND_BACKGROUND_ZOOM_START_MS = 0
ZO_MORROWIND_BACKGROUND_ZOOM_DURATION_MS = 5000

--Lava Burst 

local LavaBurst = ZO_Object:Subclass()

LavaBurst.id = 0

function LavaBurst:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function LavaBurst:Initialize(sceneGraph, rootNode)
    self.sceneGraph = sceneGraph
    self.node = sceneGraph:CreateNode(string.format("lavaBurst%d", LavaBurst.id))
    LavaBurst.id = LavaBurst.id + 1
    self.node:SetParent(rootNode)
    self.node:SetZ(LAVA_BURST_DEPTH)
    self:SetSparksSize(6)

    self:InitializeSparksParticleSystem()
end

function LavaBurst:InitializeSparksParticleSystem()
    local QuickBendEasing = ZO_GenerateCubicBezierEase(0.38, 0.21, 0.75, 0.24)
    local LateBendEasing = ZO_GenerateCubicBezierEase(0.38, 0.21, 0.84, 0.24)
    local BurstEasing = ZO_GenerateCubicBezierEase(0, 0.72, 0.46, 0.98)
    local sparkStartColorGenerator = ZO_WeightedChoiceGenerator:New(
        {0.7, 0.7, 0.4}, 0.1,
        {0.8, 0.3, 0.3}, 0.3,
        {1.0, 1.0, 0.0}, 0.3,
        {1.0, 0.5, 0.0}, 0.3)

    local AlphaEasing = ZO_GenerateCubicBezierEase(0.75, 0.25, 0.75, 0.25)
    local ColorEasing = ZO_GenerateCubicBezierEase(.71,.51,.63,.89)

    local sparksParticleSystem = ZO_SceneGraphParticleSystem:New(ZO_BentArcParticle_SceneGraph, self.node)
    sparksParticleSystem:SetParentControl(self.sceneGraph:GetCanvasControl())
    sparksParticleSystem:SetBurstEasing(BurstEasing)
    sparksParticleSystem:SetParticleParameter("BlendMode", TEX_BLEND_MODE_ADD)
    sparksParticleSystem:SetParticleParameter("Texture", "EsoUI/Art/PregameAnimatedBackground/ember.dds")
    sparksParticleSystem:SetParticleParameter("StartColorR", "StartColorG", "StartColorB", sparkStartColorGenerator)
    sparksParticleSystem:SetParticleParameter("EndColorR", 0.5)
    sparksParticleSystem:SetParticleParameter("EndColorG", 0.4)
    sparksParticleSystem:SetParticleParameter("EndColorB", 0.2)
    sparksParticleSystem:SetParticleParameter("ColorEasing", ColorEasing)
    sparksParticleSystem:SetParticleParameter("StartAlpha", 0.8)
    sparksParticleSystem:SetParticleParameter("EndAlpha", 0.0)
    sparksParticleSystem:SetParticleParameter("AlphaEasing", AlphaEasing)
    sparksParticleSystem:SetParticleParameter("StartScale", "EndScale", ZO_UniformRangeGenerator:New(0.2, 0.8, 0.1, 0.5))
    sparksParticleSystem:SetParticleParameter("BentArcAzimuthStartRadians", 0)
    sparksParticleSystem:SetParticleParameter("BentArcAzimuthChangeRadians", 0)
    sparksParticleSystem:SetParticleParameter("BentArcBendEasing", ZO_WeightedChoiceGenerator:New(QuickBendEasing, 0.4, LateBendEasing, 0.6))
    sparksParticleSystem:SetParticleParameter("StartOffsetZ", 0)
    sparksParticleSystem:SetParticleParameter("EndOffsetZ", -0.1)
    self.sparksParticleSystem = sparksParticleSystem
end

function LavaBurst:SetSparksMinMaxDuration(minDurationS, maxDurationS)
    self.sparksParticleSystem:SetParticleParameter("DurationS", ZO_UniformRangeGenerator:New(minDurationS, maxDurationS))
end

function LavaBurst:SetSparksSize(sparksSize)
    self.sparksSize = sparksSize
end

function LavaBurst:SetSpawnLine(x1, y1, x2, y2)
    self.positionX = (x1 + x2) * 0.5
    self.positionY = (y1 + y2) * 0.5
    self.spawnX1 = x1 - self.positionX
    self.spawnY1 = y1 - self.positionY
    self.spawnX2 = x2 - self.positionX
    self.spawnY2 = y2 - self.positionY
end

function LavaBurst:SetSparksAngleAndSpread(angleRadians, spreadRadians)
    self.sparksParticleSystem:SetParticleParameter("BentArcElevationStartRadians", ZO_UniformRangeGenerator:New(angleRadians - spreadRadians, angleRadians + spreadRadians))
end

function LavaBurst:SetSparksBend(minBendRadians, maxBendRadians)
    self.sparksParticleSystem:SetParticleParameter("BentArcElevationChangeRadians", ZO_UniformRangeGenerator:New(minBendRadians, maxBendRadians))
end

function LavaBurst:SetBurst(numSparksParticles, durationS, phaseS, cycleDurationS)
    self.sparksParticleSystem:SetBurst(numSparksParticles, durationS, phaseS, cycleDurationS)
end

function LavaBurst:SetSparksMinMaxVelocity(minVelocity, maxVelocity)
    self.sparksMinVelocity = minVelocity
    self.sparksMaxVelocity = maxVelocity
end

function LavaBurst:UpdateMagnification(magnification)
    local sparksSize = self.node:ComputeSizeForDepth(self.sparksSize * magnification, self.sparksSize * magnification, 0, CAMERA_START_DEPTH)
    self.sparksParticleSystem:SetParticleParameter("Size", sparksSize)

    local minSparksVelocity = self.node:ComputeSizeForDepth(self.sparksMinVelocity * magnification, 0, 0, CAMERA_START_DEPTH)
    local maxSparksVelocity = self.node:ComputeSizeForDepth(self.sparksMaxVelocity * magnification, 0, 0, CAMERA_START_DEPTH)
    self.sparksParticleSystem:SetParticleParameter("BentArcVelocity", ZO_UniformRangeGenerator:New(minSparksVelocity, maxSparksVelocity))

    local spawnX1 = self.node:ComputeSizeForDepth(self.spawnX1 * magnification, 0, 0, CAMERA_START_DEPTH)
    local spawnY1 = self.node:ComputeSizeForDepth(self.spawnY1 * magnification, 0, 0, CAMERA_START_DEPTH)
    local spawnX2 = self.node:ComputeSizeForDepth(self.spawnX2 * magnification, 0, 0, CAMERA_START_DEPTH)
    local spawnY2 = self.node:ComputeSizeForDepth(self.spawnY2 * magnification, 0, 0, CAMERA_START_DEPTH)
    local offsetGenerator = ZO_UniformRangeGenerator:New(spawnX1, spawnX2, spawnY1, spawnY2)
    self.sparksParticleSystem:SetParticleParameter("StartOffsetX", "StartOffsetY", offsetGenerator)

    local offsetX, offsetY = self.node:ComputeSizeForDepth(self.positionX * magnification, self.positionY * magnification, 0, CAMERA_START_DEPTH)
    self.node:SetX(offsetX)
    self.node:SetY(offsetY)
end

function LavaBurst:Start()
    self.sparksParticleSystem:Start()
end

function LavaBurst:Stop()
    self.sparksParticleSystem:Stop()
end

--Cloud

local Cloud = ZO_Object:Subclass()

Cloud.id = 0

function Cloud:New(...)
    local cloud = ZO_Object.New(self)
    cloud:Initialize(...)
    return cloud
end

function Cloud:Initialize(sceneGraph, rootNode)
    self.sceneGraph = sceneGraph
    self.node = sceneGraph:CreateNode(string.format("cloud%d", Cloud.id))
    self.node:SetParent(rootNode)

    self.textureControl = CreateControlFromVirtual("Cloud", self.sceneGraph:GetCanvasControl(), "ZO_MorrowindBackgroundCloud", Cloud.id)
    self.node:AddControl(self.textureControl, 0, 0, 0)

    Cloud.id = Cloud.id + 1
end

function Cloud:SetStart(startX, startY)
    self.startX = startX
    self.startY = startY
end

function Cloud:SetEnd(endX, endY)
    self.endX = endX
    self.endY = endY
end

function Cloud:SetDuration(durationS)
    self.durationS = durationS
end

function Cloud:SetSize(size)
    self.size = size
end

function Cloud:SetDepth(depth)
    self.node:SetZ(depth)
end

function Cloud:SetPlayOffset(playOffsetS)
    self.playOffsetS = playOffsetS
end

function Cloud:Play()
    self.startTimeS  = (GetGameTimeMilliseconds() / 1000) - self.playOffsetS
end

function Cloud:UpdateMagnification(magnification)
    self.finalStartX = self.node:ComputeSizeForDepth(self.startX * magnification, 0, 0, CAMERA_START_DEPTH)
    self.finalEndX = self.node:ComputeSizeForDepth(self.endX * magnification, 0, 0, CAMERA_START_DEPTH)
    self.finalStartY = self.node:ComputeSizeForDepth(self.startY * magnification, 0, 0, CAMERA_START_DEPTH)
    self.finalEndY = self.node:ComputeSizeForDepth(self.endY * magnification, 0, 0, CAMERA_START_DEPTH)
    
    local finalSize = self.node:ComputeSizeForDepth(self.size * magnification, 0, 0, CAMERA_START_DEPTH)
    self.textureControl:SetDimensions(finalSize, finalSize)
end

function Cloud:OnUpdate(timeS)
    local timeInCycleS = (timeS - self.startTimeS) % self.durationS
    local progress = timeInCycleS / self.durationS
    local x = zo_lerp(self.finalStartX, self.finalEndX, progress)
    local y = zo_lerp(self.finalStartY, self.finalEndY, progress)
    self.node:SetX(x)
    self.node:SetY(y)
end

--Background

function MorrowindBackground:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function MorrowindBackground:Initialize(control)
    self.control = control
    self.canvasControl = control:GetNamedChild("Canvas")
    self.groundTexture = self.canvasControl:GetNamedChild("Ground")
    self.groundTexture2 = self.canvasControl:GetNamedChild("Ground2")
    self.smokeTexture1 = self.canvasControl:GetNamedChild("Smoke1")
    self.smokeTexture2 = self.canvasControl:GetNamedChild("Smoke2")
    
    PREGAME_ANIMATED_BACKGROUND_FRAGMENT = ZO_SimpleSceneFragment:New(control)
    PREGAME_ANIMATED_BACKGROUND_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:Start()
        elseif newState == SCENE_HIDDEN then
            self:Stop()
        end
    end)

    control:SetHandler("OnUpdate", function(_, timeS) self:OnUpdate(timeS) end)
    control:RegisterForEvent(EVENT_SCREEN_RESIZED, function() self:OnScreenResized() end)

    self:InitializeAnimations()
    self.sceneGraph = ZO_SceneGraph:New(self.canvasControl)
    self:BuildSceneGraph()
    self:ResizeSizes()

    self.cameraRootZ = CAMERA_START_DEPTH
    self.cameraWander = CameraWander:New(CAMERA_WANDER_SPEED, CAMERA_WANDER_DISTANCE)
    self.cameraWander:Start()
end

function MorrowindBackground:InitializeAnimations()
    self.showTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_MorrowindBackgroundShowAnimation")
    self.showTimeline:GetAnimation(1):SetAnimatedControl(self.canvasControl)
    self.showTimeline:GetAnimation(2):SetUpdateFunction(function(...) self:OnZoomAnimationUpdate(...) end)
end

function MorrowindBackground:OnZoomAnimationUpdate(animation, progress)
    self.cameraRootZ = zo_lerp(CAMERA_START_DEPTH, CAMERA_END_DEPTH, progress)
end

function MorrowindBackground:AddParticles(particle)
    table.insert(self.particleSystems, particle)
end

do
    local CLOUD_SIZE = 1024
    local RIGHT_X = GROUND_AREA_MAX_WIDTH * 0.5 + CLOUD_SIZE * 0.5
    local LEFT_X = -RIGHT_X
    local TOP_Y = GROUND_AREA_MAX_HEIGHT * 0.5 + CLOUD_SIZE * 0.5
    local BOTTOM_Y = -TOP_Y

    function MorrowindBackground:AddCloud(offsetS, verticalOffset)
        local cloud = Cloud:New(self.sceneGraph, self.rootNode)
        cloud:SetStart(RIGHT_X, BOTTOM_Y + verticalOffset)
        cloud:SetEnd(LEFT_X, TOP_Y + verticalOffset)
        cloud:SetDuration(30)
        cloud:SetPlayOffset(offsetS)
        cloud:SetSize(CLOUD_SIZE)
        cloud:SetDepth(CLOUDS_DEPTH)
        table.insert(self.clouds, cloud)
    end
end

function MorrowindBackground:BuildSceneGraph()
    self.rootNode = self.sceneGraph:CreateNode("root")
    self.rootNode:SetParent(self.sceneGraph:GetCameraNode())

    self.groundNode = self.sceneGraph:CreateNode("ground")
    self.groundNode:SetParent(self.rootNode)
    self.groundNode:AddControl(self.groundTexture, 0, 0, GROUND_DEPTH)

    self.groundNode2 = self.sceneGraph:CreateNode("ground2")
    self.groundNode2:SetParent(self.rootNode)
    self.groundNode2:AddControl(self.groundTexture2, 0, 0, GROUND_DEPTH - 0.001)

    self.smokeNode1 = self.sceneGraph:CreateNode("smoke1")
    self.smokeNode1:SetParent(self.rootNode)
    self.smokeNode1:AddControl(self.smokeTexture1, 0, 0, SMOKE_DEPTH)

    self.smokeNode2 = self.sceneGraph:CreateNode("smoke2")
    self.smokeNode2:SetParent(self.rootNode)
    self.smokeNode2:AddControl(self.smokeTexture2, 0, 0, SMOKE_DEPTH)

    self.particleSystems = {}
    self.clouds = {}

    --Lava Bursts

    local NUM_SPARK_PARTICLES_AVERAGE = 120
    local CYCLE_LENGTH_S = 9
    
    local lavaBurst1 = LavaBurst:New(self.sceneGraph, self.rootNode)
    lavaBurst1:SetSpawnLine(-700, -500, -450, -500)
    lavaBurst1:SetBurst(NUM_SPARK_PARTICLES_AVERAGE, 1, 0, CYCLE_LENGTH_S)
    lavaBurst1:SetSparksMinMaxDuration(0.1, 2)
    lavaBurst1:SetSparksAngleAndSpread(math.rad(90), math.rad(10))
    lavaBurst1:SetSparksBend(math.rad(-40), math.rad(40))
    lavaBurst1:SetSparksMinMaxVelocity(350, 450)
    self:AddParticles(lavaBurst1)

    local lavaBurst2 = LavaBurst:New(self.sceneGraph, self.rootNode)
    lavaBurst2:SetSpawnLine(-300, -310, -260, -270)
    lavaBurst2:SetBurst(NUM_SPARK_PARTICLES_AVERAGE, 0.825, 1.17, CYCLE_LENGTH_S)
    lavaBurst2:SetSparksMinMaxDuration(0.1, 1.5)
    lavaBurst2:SetSparksAngleAndSpread(math.rad(125), math.rad(20))
    lavaBurst2:SetSparksBend(math.rad(-80), math.rad(20))
    lavaBurst2:SetSparksMinMaxVelocity(200, 250)
    self:AddParticles(lavaBurst2)

    local lavaBurst3 = LavaBurst:New(self.sceneGraph, self.rootNode)
    lavaBurst3:SetSpawnLine(375, 273, 405, 303)
    lavaBurst3:SetBurst(NUM_SPARK_PARTICLES_AVERAGE, 0.825, 1.667, CYCLE_LENGTH_S)
    lavaBurst3:SetSparksMinMaxDuration(0.1, 1.5)
    lavaBurst3:SetSparksAngleAndSpread(math.rad(330), math.rad(10))
    lavaBurst3:SetSparksBend(math.rad(-45), math.rad(45))
    lavaBurst3:SetSparksMinMaxVelocity(100, 150)
    self:AddParticles(lavaBurst3)

    local lavaBurst4 = LavaBurst:New(self.sceneGraph, self.rootNode)
    lavaBurst4:SetSpawnLine(-195, -375, -175, -325)
    lavaBurst4:SetBurst(NUM_SPARK_PARTICLES_AVERAGE, 1.333, 3, CYCLE_LENGTH_S)
    lavaBurst4:SetSparksMinMaxDuration(0.1, 1.5)
    lavaBurst4:SetSparksAngleAndSpread(math.rad(0), math.rad(25))
    lavaBurst4:SetSparksBend(math.rad(20), math.rad(40))
    lavaBurst4:SetSparksMinMaxVelocity(250, 250)
    self:AddParticles(lavaBurst4)

    local lavaBurst5 = LavaBurst:New(self.sceneGraph, self.rootNode)
    lavaBurst5:SetSpawnLine(-110, -195, -80, -145)
    lavaBurst5:SetBurst(NUM_SPARK_PARTICLES_AVERAGE, 1, 4.333, CYCLE_LENGTH_S)
    lavaBurst5:SetSparksMinMaxDuration(0.1, 1.5)
    lavaBurst5:SetSparksAngleAndSpread(math.rad(0), math.rad(25))
    lavaBurst5:SetSparksBend(math.rad(0), math.rad(40))
    lavaBurst5:SetSparksMinMaxVelocity(250, 250)
    self:AddParticles(lavaBurst5)

    local lavaBurst6 = LavaBurst:New(self.sceneGraph, self.rootNode)
    lavaBurst6:SetSpawnLine(180, 125, 230, 145)
    lavaBurst6:SetBurst(NUM_SPARK_PARTICLES_AVERAGE, 1.333, 6.333, CYCLE_LENGTH_S)
    lavaBurst6:SetSparksMinMaxDuration(0.1, 2.5)
    lavaBurst6:SetSparksAngleAndSpread(math.rad(320), math.rad(25))
    lavaBurst6:SetSparksBend(math.rad(-40), math.rad(-10))
    lavaBurst6:SetSparksMinMaxVelocity(150, 200)
    self:AddParticles(lavaBurst6)

    local lavaBurst7 = LavaBurst:New(self.sceneGraph, self.rootNode)
    lavaBurst7:SetSpawnLine(375, 273, 405, 303)
    lavaBurst7:SetBurst(NUM_SPARK_PARTICLES_AVERAGE, 1, 6.8, CYCLE_LENGTH_S)
    lavaBurst7:SetSparksMinMaxDuration(0.1, 1.5)
    lavaBurst7:SetSparksAngleAndSpread(math.rad(330), math.rad(20))
    lavaBurst7:SetSparksBend(math.rad(-35), math.rad(35))
    lavaBurst7:SetSparksMinMaxVelocity(100, 150)
    self:AddParticles(lavaBurst7)

    --Clouds

    --AddCloud(offsetS, yOffset)

    --1st 15s
    self:AddCloud(0, 0)
    self:AddCloud(7.5, 0)
    self:AddCloud(1.875, 200)
    self:AddCloud(9.375, 200)
    self:AddCloud(3.75, -200)
    self:AddCloud(11.25, -200)    
    self:AddCloud(5.625, 400)
    self:AddCloud(13.125, 400)
    self:AddCloud(7.5, -400)
    self:AddCloud(15, -400)

    --2nd 15s
    self:AddCloud(15, 0)
    self:AddCloud(22.5, 0)
    self:AddCloud(16.875, 200)
    self:AddCloud(26.375, 200)
    self:AddCloud(18.75, -200)
    self:AddCloud(26.25, -200)    
    self:AddCloud(20.625, 400)
    self:AddCloud(28.125, 400)
    self:AddCloud(22.5, -400)
    self:AddCloud(30, -400)
end

function MorrowindBackground:ResizeSizes()
    local canvasWidth, canvasHeight = GuiRoot:GetDimensions()
    local cameraZ = 0
    local groundAreaSize = 0
    if canvasHeight > 0 then
        local canvasAspectRatio = canvasWidth / canvasHeight        
        if canvasAspectRatio > GROUND_AREA_ASPECT_RATIO then
            --If there is extra width space then start with making the map area as tall as possible (right up the the edge of the min size that has to 
            --be on screen). This will cover the most width.
            local heightPercentOfImage = GROUND_AREA_MIN_HEIGHT_PERCENT_OF_TEXTURE_SIZE
            local widthPercentOfImage = heightPercentOfImage * canvasAspectRatio
            --If the percentage of the map area that would be shown width wise is still larger than what's allowed
            if widthPercentOfImage > GROUND_AREA_MAX_WIDTH_PERCENT_OF_TEXTURE_SIZE then
                --Then size the map area to the width of the screen and compute the height from that (this will clip more into the min
                --area than desired but it can't be helped since we need to maintain the aspect ratio).
                widthPercentOfImage = GROUND_AREA_MAX_WIDTH_PERCENT_OF_TEXTURE_SIZE
                heightPercentOfImage = widthPercentOfImage / canvasAspectRatio
            end
            groundAreaSize = canvasHeight / heightPercentOfImage
        else
            --same algorithm but for extra height space
            local widthPercentOfImage = GROUND_AREA_MIN_WIDTH_PERCENT_OF_TEXTURE_SIZE
            local heightPercentOfImage = widthPercentOfImage / canvasAspectRatio
            if heightPercentOfImage > GROUND_AREA_MAX_HEIGHT_PERCENT_OF_TEXTURE_SIZE then
                heightPercentOfImage = GROUND_AREA_MAX_HEIGHT_PERCENT_OF_TEXTURE_SIZE
                widthPercentOfImage = heightPercentOfImage * canvasAspectRatio
            end
            groundAreaSize = canvasWidth / widthPercentOfImage
        end
    end

    --The ratio of the final map area to the reference size is used as a scale factor. The size of every other node is done in reference to the GROUND_AREA_TEXTURE_SIZE
    local magnification = groundAreaSize / GROUND_AREA_TEXTURE_SIZE

    self.groundTexture:SetDimensions(self.groundNode:ComputeSizeForDepth(GROUND_AREA_TEXTURE_SIZE * magnification, GROUND_AREA_TEXTURE_SIZE * magnification, GROUND_DEPTH, CAMERA_START_DEPTH))
    self.groundTexture2:SetDimensions(self.groundNode2:ComputeSizeForDepth(GROUND_AREA_TEXTURE_SIZE * magnification, GROUND_AREA_TEXTURE_SIZE * magnification, GROUND_DEPTH, CAMERA_START_DEPTH))
    self.smokeTexture1:SetDimensions(self.smokeNode1:ComputeSizeForDepth(SMOKE_1_WIDTH * magnification, SMOKE_1_HEIGHT * magnification, SMOKE_DEPTH, CAMERA_START_DEPTH))
    self.smokeTexture2:SetDimensions(self.smokeNode2:ComputeSizeForDepth(SMOKE_2_WIDTH * magnification, SMOKE_2_HEIGHT * magnification, SMOKE_DEPTH, CAMERA_START_DEPTH))
    
    for _, particleSystem in ipairs(self.particleSystems) do
        particleSystem:UpdateMagnification(magnification)
    end
    for _, cloud in ipairs(self.clouds) do
        cloud:UpdateMagnification(magnification)
    end

    self.magnification = magnification
end

function MorrowindBackground:StartParticleSystems()
    for _, particleSystem in ipairs(self.particleSystems) do
        particleSystem:Start()
    end
end

function MorrowindBackground:StopParticleSystems()
    for _, particleSystem in ipairs(self.particleSystems) do
        particleSystem:Stop()
    end
end

function MorrowindBackground:StartClouds()
    for _, cloud in ipairs(self.clouds) do
        cloud:Play()
    end
    self.cloudsStarted = true
end

function MorrowindBackground:Start()
    self.canvasControl:SetAlpha(0)
    self.showTimeline:PlayFromStart()
    self:StartParticleSystems()
    if not self.cloudsStarted then
        self:StartClouds()
    end
end

function MorrowindBackground:Stop()
    self:StopParticleSystems()
    self.lastUpdateS = nil
end

--Events

function MorrowindBackground:OnUpdate(timeS)
    if self.lastUpdateS then
        local deltaS = timeS - self.lastUpdateS

        local cameraWanderX, cameraWanderY = self.cameraWander:Update(timeS)
        self.sceneGraph:SetCameraX(cameraWanderX)
        self.sceneGraph:SetCameraY(cameraWanderY)
        self.sceneGraph:SetCameraZ(self.cameraRootZ)

        for _, cloud in ipairs(self.clouds) do
            cloud:OnUpdate(timeS)
        end

        --A faster and a slower change in the alpha combined together
        local lavaAlpha = zo_abs(math.sin(timeS * LAVA_GLOW_SLOW_SPEED_FACTOR)) * LAVA_GLOW_SLOW_AMOUNT
        lavaAlpha = lavaAlpha + zo_abs(math.sin(timeS * LAVA_GLOW_FAST_SPEED_FACTOR)) * LAVA_GLOW_FAST_AMOUNT
        self.groundTexture2:SetAlpha(lavaAlpha)

        --Bottom Right Smoke
        local smoke1X = SMOKE_1_ORIGIN_X + math.cos(timeS * SMOKE_SPEED_FACTOR) * SMOKE_1_DELTA_X
        local smoke1Y = SMOKE_1_ORIGIN_Y + math.sin(timeS * SMOKE_SPEED_FACTOR) * SMOKE_1_DELTA_Y
        self.smokeNode1:SetX(self.smokeNode1:ComputeSizeForDepth(smoke1X * self.magnification, 0, SMOKE_DEPTH, CAMERA_START_DEPTH))
        self.smokeNode1:SetY(self.smokeNode1:ComputeSizeForDepth(smoke1Y * self.magnification, 0, SMOKE_DEPTH, CAMERA_START_DEPTH))

        --Top Left Smoke
        local smoke2X = SMOKE_2_ORIGIN_X + math.cos(timeS * SMOKE_SPEED_FACTOR) * SMOKE_2_DELTA_X
        local smoke2Y = SMOKE_2_ORIGIN_Y + math.sin(timeS * SMOKE_SPEED_FACTOR) * SMOKE_2_DELTA_Y
        self.smokeNode2:SetX(self.smokeNode2:ComputeSizeForDepth(smoke2X * self.magnification, 0, SMOKE_DEPTH, CAMERA_START_DEPTH))
        self.smokeNode2:SetY(self.smokeNode2:ComputeSizeForDepth(smoke2Y * self.magnification, 0, SMOKE_DEPTH, CAMERA_START_DEPTH))
    end
    self.lastUpdateS = timeS    
end

function MorrowindBackground:OnScreenResized()
    self:ResizeSizes()
end

--Global XML Handlers

function ZO_MorrowindBackground_OnInitialized(self)
    if IsConsoleUI() then
        PREGAME_ANIMATED_BACKGROUND = MorrowindBackground:New(self)
    end
end