local ElsweyrBackground = ZO_Object:Subclass()

ZO_ELSWEYR_BACKGROUND_FADE_DURATION_MS = 500

local GROUND_TEXTURE_WIDTH = 2048
local GROUND_TEXTURE_HEIGHT = 2048
local GROUND_TEXTURE_USED_WIDTH = 1920
local GROUND_TEXTURE_USED_HEIGHT = 1080
local GROUND_TEXTURE_MAX_U = GROUND_TEXTURE_USED_WIDTH / GROUND_TEXTURE_WIDTH
local GROUND_TEXTURE_MAX_V = GROUND_TEXTURE_USED_HEIGHT / GROUND_TEXTURE_HEIGHT

--Background

function ElsweyrBackground:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function ElsweyrBackground:Initialize(control)
    self.control = control
    self.containerControl = control:GetNamedChild("Container")
    self.groundTexture = self.containerControl:GetNamedChild("Ground")
    self.groundTexture:SetTextureCoords(0, GROUND_TEXTURE_MAX_U, 0, GROUND_TEXTURE_MAX_V)
    
    PREGAME_ANIMATED_BACKGROUND_FRAGMENT = ZO_SimpleSceneFragment:New(control)
    PREGAME_ANIMATED_BACKGROUND_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:Start()
        elseif newState == SCENE_HIDDEN then
            self:Stop()
        end
    end)

    control:RegisterForEvent(EVENT_SCREEN_RESIZED, function() self:OnScreenResized() end)

    self.particleSystems = {}
    self:InitializeAnimations()
    self:InitializeParticleSystems()
    self:ResizeSizes()
end

function ElsweyrBackground:InitializeAnimations()
    self.showTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ElsweyrBackgroundShowAnimation", self.containerControl)
end

local STORM_DURATION_S = 12
local STORM_CYCLE_DURATION_S = 12

local SAND_MIN_WIDTH = 200
local SAND_MAX_WIDTH = 400
local SAND_MIN_SCALE = 2
local SAND_MAX_SCALE = 4
local SAND_MAX_SCALED_WIDTH = SAND_MAX_WIDTH * SAND_MAX_SCALE
local SAND_MAX_OFFSET_X_FROM_CENTER = 1000
local SAND_MAX_TRAVEL_DISTANCE_TO_LEAVE_SCREEN = SAND_MAX_OFFSET_X_FROM_CENTER + 1920/2 + SAND_MAX_SCALED_WIDTH
local SAND_MIN_SPEED = 600
local SAND_MAX_SPEED = 900
local SAND_FADE_IN_OVER_PERCENT = 0.2

function ElsweyrBackground:CreateSandParticleSystem(waveDurationS, waveMagnitudeDegrees, numParticlesPerCycle, bandTopY, bandHeight)
    local function AlphaEasing(progress)
        if progress < SAND_FADE_IN_OVER_PERCENT then
            return ZO_EaseInQuadratic(progress / SAND_FADE_IN_OVER_PERCENT)
        else
            return 1
        end
    end

    local sandParticleSystem = ZO_ControlParticleSystem:New(ZO_BentArcParticle_Control)
    sandParticleSystem:SetParentControl(self.containerControl)
    sandParticleSystem:SetBurst(numParticlesPerCycle * STORM_DURATION_S, STORM_DURATION_S, 0, STORM_CYCLE_DURATION_S)
    sandParticleSystem:SetBurstEasing(ZO_EaseInOutQuadratic)
    sandParticleSystem:SetParticleParameter("Width", ZO_UniformRangeGenerator:New(SAND_MIN_WIDTH, SAND_MAX_WIDTH))
    sandParticleSystem:SetParticleParameter("Height", ZO_UniformRangeGenerator:New(20, 40))
    sandParticleSystem:SetParticleParameter("StartScale", SAND_MIN_SCALE)
    sandParticleSystem:SetParticleParameter("EndScale", SAND_MAX_SCALE)
    sandParticleSystem:SetParticleParameter("Texture", "EndAlpha", "DrawLevel", ZO_WeightedChoiceGenerator:New(
        {"EsoUI/Art/PregameAnimatedBackground/elsweyrSand.dds", 0.08, 1}, 0.7,
        {"EsoUI/Art/PregameAnimatedBackground/elsweyrSandShadow.dds", 0.16, 0}, 0.3))
    sandParticleSystem:SetParticleParameter("StartAlpha", 0)
    sandParticleSystem:SetParticleParameter("AlphaEasing", AlphaEasing)
    sandParticleSystem:SetParticleParameter("AnchorPoint", RIGHT)
    local angleGenerator = ZO_SmoothCycleGenerator:New(math.rad(-waveMagnitudeDegrees), math.rad(waveMagnitudeDegrees))
    angleGenerator:SetCycleDurationS(waveDurationS)
    sandParticleSystem:SetParticleParameter("BentArcElevationStartRadians", math.rad(0))
    sandParticleSystem:SetParticleParameter("BentArcElevationChangeRadians", angleGenerator)
    sandParticleSystem:SetParticleParameter("BentArcAzimuthStartRadians", 0)
    sandParticleSystem:SetParticleParameter("BentArcAzimuthChangeRadians", 0)
    sandParticleSystem:SetParticleParameter("BentArcVelocity", "DurationS", ZO_UniformRangeGenerator:New(SAND_MIN_SPEED, SAND_MAX_SPEED, SAND_MAX_TRAVEL_DISTANCE_TO_LEAVE_SCREEN/SAND_MIN_SPEED, SAND_MAX_TRAVEL_DISTANCE_TO_LEAVE_SCREEN/SAND_MAX_SPEED))
    sandParticleSystem:SetParticleParameter("BentArcOrientWithMotion", true)
    sandParticleSystem:SetParticleParameter("StartOffsetX", ZO_UniformRangeGenerator:New(-SAND_MAX_OFFSET_X_FROM_CENTER/2, -SAND_MAX_OFFSET_X_FROM_CENTER))
    sandParticleSystem:SetParticleParameter("StartOffsetY", ZO_UniformRangeGenerator:New(bandTopY, bandTopY + bandHeight))

    return sandParticleSystem
end

function ElsweyrBackground:CreateStoneParticleSystem()    
    local stoneParticleSystem = ZO_ControlParticleSystem:New(ZO_FlowParticle_Control)
    stoneParticleSystem:SetParentControl(self.containerControl)
    stoneParticleSystem:SetBurst(55 * STORM_DURATION_S, STORM_DURATION_S, 0, STORM_CYCLE_DURATION_S)
    stoneParticleSystem:SetBurstEasing(ZO_EaseInOutQuadratic)
    stoneParticleSystem:SetParticleParameter("Size", ZO_UniformRangeGenerator:New(4, 5))
    stoneParticleSystem:SetParticleParameter("StartAlpha", 0.43)
    stoneParticleSystem:SetParticleParameter("Texture", "EsoUI/Art/PregameAnimatedBackground/elsweyrDust.dds")
    stoneParticleSystem:SetParticleParameter("AnchorPoint", CENTER)
    stoneParticleSystem:SetParticleParameter("AnchorRelativePoint", TOPLEFT)
    stoneParticleSystem:SetParticleParameter("DrawLayer", DL_OVERLAY)
    stoneParticleSystem:SetParticleParameter("DurationS", ZO_UniformRangeGenerator:New(3, 4))
    stoneParticleSystem:SetParticleParameter("FlowAreaTop", 0)
    stoneParticleSystem:SetParticleParameter("FlowAreaBottom", 1080)
    stoneParticleSystem:SetParticleParameter("FlowAreaLeft", -200)
    stoneParticleSystem:SetParticleParameter("FlowAreaRight", 2020)
    --Verical ranges that map to the sand area in the background image. Evenly distributed across the screen horizontally.
    stoneParticleSystem:SetParticleParameter("FlowNormalizedPosts", {        
        {0.32, 0.75},
        {0.31, 0.80},
        {0.34, 0.82},
        {0.36, 0.88},
        {0.34, 0.87},
        {0.32, 0.8},
        {0.32, 0.75},
        {0.35, 0.77},
        {0.33, 0.85},
    })
    return stoneParticleSystem
end

local LIGHT_EMITTERS_CENTER_X = { -1000, -670, 340, 670, 1000 }
local LIGHT_EMITTER_RANGE_X = 50
local LIGHT_DURATION_S = 12

function ElsweyrBackground:CreateLightParticleSystem(index, offsetX)
    local lightParticleSystem = ZO_ControlParticleSystem:New(ZO_StationaryParticle_Control)
    lightParticleSystem:SetParentControl(self.containerControl)
    lightParticleSystem:SetParticlesPerSecond(1 / LIGHT_DURATION_S)
    lightParticleSystem:SetStartPrimeS((index / #LIGHT_EMITTERS_CENTER_X) * LIGHT_DURATION_S)
    lightParticleSystem:SetParticleParameter("Width", 80, 140)
    lightParticleSystem:SetParticleParameter("EndAlpha", 0.85)
    lightParticleSystem:SetParticleParameter("Height", 1400)
    lightParticleSystem:SetParticleParameter("Texture", "EsoUI/Art/PregameAnimatedBackground/lightShaft.dds")
    lightParticleSystem:SetParticleParameter("BlendMode", TEX_BLEND_MODE_ADD)
    lightParticleSystem:SetParticleParameter("DrawLayer", DL_OVERLAY)
    lightParticleSystem:SetParticleParameter("DurationS", LIGHT_DURATION_S)
    lightParticleSystem:SetParticleParameter("StartOffsetX", ZO_UniformRangeGenerator:New(offsetX - LIGHT_EMITTER_RANGE_X, offsetX + LIGHT_EMITTER_RANGE_X))
    lightParticleSystem:SetParticleParameter("StartOffsetY", ZO_UniformRangeGenerator:New(-450, -550))
    lightParticleSystem:SetParticleParameter("StartAlpha", 0)
    lightParticleSystem:SetParticleParameter("AlphaEasing", ZO_EaseInOutZeroToOneToZero)
    lightParticleSystem:SetParticleParameter("AnchorPoint", TOP)
    lightParticleSystem:SetParticleParameter("AnchorRelativePoint", TOP)
    lightParticleSystem:SetParticleParameter("StartRotationRadians", math.rad(30))
    lightParticleSystem:SetParticleParameter("StartColorR", 1)
    lightParticleSystem:SetParticleParameter("StartColorG", 1)
    lightParticleSystem:SetParticleParameter("StartColorB", 0.95)
    lightParticleSystem:SetParticleParameter("StartScale", 0.9)
    lightParticleSystem:SetParticleParameter("EndScale", 1)

    return lightParticleSystem
end

local DRAGON_FLIP_BOOK_PLAYBACK_INFO = { playbackType = ANIMATION_PLAYBACK_LOOP, loopCount = LOOP_INDEFINITELY }
local SECONDS_PER_DRAGON = 10
local FIRST_DRAGON_OFFSET_S = 2
local DRAGON_EMITTERS =
{
    { offsetX = ZO_UniformRangeGenerator:New(-900, 900), offsetY = 1300, startRadians = ZO_UniformRangeGenerator:New(math.rad(80), math.rad(100)) },
    { offsetX = -1800, offsetY = ZO_UniformRangeGenerator:New(-500, 500), startRadians = ZO_UniformRangeGenerator:New(math.rad(-10), math.rad(10)) },
    { offsetX = ZO_UniformRangeGenerator:New(-900, 900), offsetY = -1300, startRadians = ZO_UniformRangeGenerator:New(math.rad(260), math.rad(280)) },
    { offsetX = 1800, offsetY = ZO_UniformRangeGenerator:New(-500, 500), startRadians = ZO_UniformRangeGenerator:New(math.rad(170), math.rad(190)) },
}

function ElsweyrBackground:CreateDragonShadowParticleSystem(index, offsetX, offsetY, startRadians)
    local shadowParticleSystem = ZO_ControlParticleSystem:New(ZO_BentArcParticle_Control)
    shadowParticleSystem:SetParentControl(self.containerControl)
    shadowParticleSystem:SetBurst(1, 1, SECONDS_PER_DRAGON * (index - 1) + FIRST_DRAGON_OFFSET_S, SECONDS_PER_DRAGON * #DRAGON_EMITTERS)
    shadowParticleSystem:SetParticleParameter("Width", 1600)
    shadowParticleSystem:SetParticleParameter("Height", 1600)
    shadowParticleSystem:SetParticleParameter("Texture", "EsoUI/Art/PregameAnimatedBackground/elsweyrDragonShadow.dds")
    shadowParticleSystem:SetParticleParameter("StartAlpha", 0.3)
    shadowParticleSystem:SetParticleParameter("AnchorPoint", CENTER)
    shadowParticleSystem:SetParticleParameter("BentArcElevationStartRadians", startRadians)
    shadowParticleSystem:SetParticleParameter("BentArcElevationChangeRadians", 0)
    shadowParticleSystem:SetParticleParameter("BentArcAzimuthStartRadians", 0)
    shadowParticleSystem:SetParticleParameter("BentArcAzimuthChangeRadians", 0)
    shadowParticleSystem:SetParticleParameter("BentArcVelocity", 2000)
    shadowParticleSystem:SetParticleParameter("BentArcOrientWithMotion", true)
    shadowParticleSystem:SetParticleParameter("BentArcOrientWithMotionTextureRotationRadians", math.rad(90))
    shadowParticleSystem:SetParticleParameter("StartOffsetX", offsetX)
    shadowParticleSystem:SetParticleParameter("StartOffsetY", offsetY)
    shadowParticleSystem:SetParticleParameter("DurationS", 4)

    return shadowParticleSystem
end

local PARTICLES_PER_BAND =
{
    2,
    7,
    10,
    7,
    2
}

function ElsweyrBackground:InitializeParticleSystems()
    local BAND_HEIGHT = 200
    for i = 1, #PARTICLES_PER_BAND do
        local offsetY = -500 + (i - 1) * BAND_HEIGHT
        table.insert(self.particleSystems, self:CreateSandParticleSystem(12, 2, PARTICLES_PER_BAND[i], offsetY, BAND_HEIGHT))
        table.insert(self.particleSystems, self:CreateSandParticleSystem(12, 5, PARTICLES_PER_BAND[i], offsetY, BAND_HEIGHT))
    end
    table.insert(self.particleSystems, self:CreateStoneParticleSystem())

    for i, dragonInfo in ipairs(DRAGON_EMITTERS) do
        table.insert(self.particleSystems, self:CreateDragonShadowParticleSystem(i, dragonInfo.offsetX, dragonInfo.offsetY, dragonInfo.startRadians))
    end

    for i, centerX in ipairs(LIGHT_EMITTERS_CENTER_X) do
        table.insert(self.particleSystems, self:CreateLightParticleSystem(i, centerX))
    end
end

function ElsweyrBackground:StartParticleSystems()
    for _, particleSystem in ipairs(self.particleSystems) do
        particleSystem:Start()
    end
end

function ElsweyrBackground:StopParticleSystems()
    for _, particleSystem in ipairs(self.particleSystems) do
        particleSystem:Stop()
    end
end

function ElsweyrBackground:ResizeSizes()
    local guiWidth, guiHeight = GuiRoot:GetDimensions()
    local GROUND_ASPECT_RATIO = GROUND_TEXTURE_USED_WIDTH / GROUND_TEXTURE_USED_HEIGHT
    local groundWidth = GROUND_ASPECT_RATIO * guiHeight
    if groundWidth < guiWidth then
        groundWidth = guiWidth
    end
    self.groundTexture:SetWidth(groundWidth) 
end

function ElsweyrBackground:Start()
    self.containerControl:SetAlpha(0)
    self.showTimeline:PlayFromStart()
    self:StartParticleSystems()
end

function ElsweyrBackground:Stop()
    self.showTimeline:Stop()
    self:StopParticleSystems()
end

--Events

function ElsweyrBackground:OnScreenResized()
    self:ResizeSizes()
end

--Global XML Handlers

function ZO_ElsweyrBackground_OnInitialized(self)
    if IsGamepadUISupported() then
        PREGAME_ANIMATED_BACKGROUND = ElsweyrBackground:New(self)
    end
end