local GreymoorBackground = ZO_Object:Subclass()

ZO_GREYMOOR_BACKGROUND_FADE_DURATION_MS = 500

local GROUND_TEXTURE_WIDTH = 2048
local GROUND_TEXTURE_HEIGHT = 2048
local GROUND_TEXTURE_USED_WIDTH = 1920
local GROUND_TEXTURE_USED_HEIGHT = 1080
local GROUND_TEXTURE_MAX_U = GROUND_TEXTURE_USED_WIDTH / GROUND_TEXTURE_WIDTH
local GROUND_TEXTURE_MAX_V = GROUND_TEXTURE_USED_HEIGHT / GROUND_TEXTURE_HEIGHT

--Background

function GreymoorBackground:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function GreymoorBackground:Initialize(control)
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

function GreymoorBackground:InitializeAnimations()
    self.showTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_GreymoorBackgroundShowAnimation", self.containerControl)
end

local SNOW_EMITTERS =
{
    { centerX = -1400 },
    { centerX = 600 },
    { centerX = -400 },
    { centerX = -750 },
    { centerX = -1000 },
    { centerX = 400 },
    { centerX = -800 },
    { centerX = -1200 },
    { centerX = 200 },
    { centerX = -200 },
    { centerX = 800 },
    { centerX = 0 },
    { centerX = -600 },
}
local NUM_SNOW_EMITTERS = #SNOW_EMITTERS
--The X range over which an emitter can spawn leaves
local SNOW_EMITTER_RANGE = 250
local HALF_SNOW_EMITTER_RANGE = SNOW_EMITTER_RANGE * 0.5
local SNOW_EMISSION_RATE = 5.5
local SNOW_FLIP_BOOK_PLAYBACK_INFO = { playbackType = ANIMATION_PLAYBACK_LOOP, loopCount = LOOP_INDEFINITELY }

--[[
    snowInfo =
    {
        minSize = 24,
        maxSize = 30,
        minDuration = 4.0,
        maxDuration = 3.0,
        emissionRate = SNOW_EMISSION_RATE,
        alphaRangeGenerator = ZO_UniformRangeGenerator:New(0.42, 0.28, 0.28, 0.14),
    }
]]--
function GreymoorBackground:CreateSnowParticleSystem(centerOffsetX, primeS, snowInfo)
    local snowParticleSystem = ZO_ControlParticleSystem:New(ZO_LeafParticle_Control)
    snowParticleSystem:SetParentControl(self.containerControl)
    snowParticleSystem:SetParticlesPerSecond(snowInfo.emissionRate)
    snowParticleSystem:SetStartPrimeS(primeS)
    snowParticleSystem:SetParticleParameter("Size", "DurationS", "LeafDescent", ZO_UniformRangeGenerator:New(snowInfo.minSize, snowInfo.maxSize, snowInfo.minDuration, snowInfo.maxDuration, 1.3, 3.5))
    snowParticleSystem:SetParticleParameter("Texture", "EsoUI/Art/PregameAnimatedBackground/snowTwirl.dds")
    snowParticleSystem:SetParticleParameter("FlipBookCellsWide", 16)
    snowParticleSystem:SetParticleParameter("FlipBookCellsHigh", 2)
    snowParticleSystem:SetParticleParameter("FlipBookPlaybackInfo", SNOW_FLIP_BOOK_PLAYBACK_INFO)
    snowParticleSystem:SetParticleParameter("FlipBookDurationS", ZO_UniformRangeGenerator:New(0.5, 2.5))
    snowParticleSystem:SetParticleParameter("LeafSectionTop", ZO_UniformRangeGenerator:New(0, 0.6))
    snowParticleSystem:SetParticleParameter("LeafSectionBottom", ZO_UniformRangeGenerator:New(0, -1.2))
    snowParticleSystem:SetParticleParameter("LeafTextureRotationRadians", 0)
    snowParticleSystem:SetParticleParameter("LeafTumbleRadians", 0)
    snowParticleSystem:SetParticleParameter("LeafFallHeight", 1200)
    snowParticleSystem:SetParticleParameter("LeafEasing", ZO_GenerateCubicBezierEase(0.5, 0.38, 0.83, 0.67))
    snowParticleSystem:SetParticleParameter("AnchorRelativePoint", TOP)
    snowParticleSystem:SetParticleParameter("StartOffsetX", ZO_UniformRangeGenerator:New(centerOffsetX - HALF_SNOW_EMITTER_RANGE, centerOffsetX + HALF_SNOW_EMITTER_RANGE))
    snowParticleSystem:SetParticleParameter("StartOffsetY", -50)
    snowParticleSystem:SetParticleParameter("StartColorR", "StartColorG", "StartColorB", 1, 1, 1)
    snowParticleSystem:SetParticleParameter("StartAlpha", "EndAlpha", snowInfo.alphaRangeGenerator)
    snowParticleSystem:SetParticleParameter("BlendMode", TEX_BLEND_MODE_ADD)
    snowParticleSystem:SetParticleParameter("StartScale", 1)
    snowParticleSystem:SetParticleParameter("EndScale", 0.6)

    return snowParticleSystem
end

local LIGHT_EMITTERS = { -1000, -900, -750, -650, -400, -200, 0, 300, 500, 800, 950, 1100, 1200 }
local LIGHT_EMITTER_RANGE_X = 250
local LIGHT_DURATION_S = 6

function GreymoorBackground:CreateLightParticleSystem(index, offsetX)
    local lightParticleSystem = ZO_ControlParticleSystem:New(ZO_StationaryParticle_Control)
    lightParticleSystem:SetParentControl(self.containerControl)
    lightParticleSystem:SetParticlesPerSecond(1 / LIGHT_DURATION_S)
    lightParticleSystem:SetStartPrimeS((index / #LIGHT_EMITTERS) * LIGHT_DURATION_S)
    lightParticleSystem:SetParticleParameter("Width", "EndAlpha", ZO_UniformRangeGenerator:New(32, 64, 0.2, 0.4))
    lightParticleSystem:SetParticleParameter("Height", 1400)
    lightParticleSystem:SetParticleParameter("Texture", "EsoUI/Art/PregameAnimatedBackground/lightShaft.dds")
    lightParticleSystem:SetParticleParameter("BlendMode", TEX_BLEND_MODE_ADD)
    lightParticleSystem:SetParticleParameter("DrawLayer", DL_OVERLAY)
    lightParticleSystem:SetParticleParameter("DurationS", LIGHT_DURATION_S)
    lightParticleSystem:SetParticleParameter("StartOffsetX", ZO_UniformRangeGenerator:New(offsetX - LIGHT_EMITTER_RANGE_X, offsetX + LIGHT_EMITTER_RANGE_X))
    lightParticleSystem:SetParticleParameter("StartOffsetY", ZO_UniformRangeGenerator:New(-800, -400))
    lightParticleSystem:SetParticleParameter("StartAlpha", 0)
    lightParticleSystem:SetParticleParameter("AlphaEasing", ZO_EaseInOutZeroToOneToZero)
    lightParticleSystem:SetParticleParameter("AnchorPoint", TOP)
    lightParticleSystem:SetParticleParameter("AnchorRelativePoint", TOP)
    --The light shafts get progressively less steep as we go left to right
    lightParticleSystem:SetParticleParameter("StartRotationRadians", math.rad(20 + index * 2))
    lightParticleSystem:SetParticleParameter("StartColorR", 1)
    lightParticleSystem:SetParticleParameter("StartColorG", 1)
    lightParticleSystem:SetParticleParameter("StartColorB", 0.95)
    lightParticleSystem:SetParticleParameter("StartScale", 0.9)
    lightParticleSystem:SetParticleParameter("EndScale", 1)

    return lightParticleSystem
end

function GreymoorBackground:AddPrimedSnowParticleSystem(emitterInfo, particleInfo, index)
    local fullCycleS = 1 / particleInfo.emissionRate
    --Spread the snow emitters evenly over a full cycle. They fire in the order they are listed in SNOW_EMITTERS.
    local primeS = (1 - ((index - 1) / (NUM_SNOW_EMITTERS - 1))) * fullCycleS

    table.insert(self.particleSystems, self:CreateSnowParticleSystem(emitterInfo.centerX, primeS + particleInfo.maxDuration, particleInfo))
end

function GreymoorBackground:InitializeParticleSystems()
    local smallSnowInfo =
    {
        minSize = 24,
        maxSize = 30,
        minDuration = 4.0,
        maxDuration = 3.0,
        emissionRate = SNOW_EMISSION_RATE,
        alphaRangeGenerator = ZO_UniformRangeGenerator:New(0.42, 0.28, 0.28, 0.14),
    }

    local mediumSnowInfo =
    {
        minSize = 48,
        maxSize = 60,
        minDuration = 2.5,
        maxDuration = 2.0,
        emissionRate = SNOW_EMISSION_RATE,
        alphaRangeGenerator = ZO_UniformRangeGenerator:New(0.42, 0.28, 0.28, 0.14),
    }

    local largeSnowInfo =
    {
        minSize = 80,
        maxSize = 128,
        minDuration = 1.0,
        maxDuration = 0.8,
        emissionRate = SNOW_EMISSION_RATE / 8,
        alphaRangeGenerator = ZO_UniformRangeGenerator:New(0.28, 0.14, 0.14, 0.07),
    }

    for index, emitterInfo in ipairs(SNOW_EMITTERS) do
        self:AddPrimedSnowParticleSystem(emitterInfo, smallSnowInfo, index)
        self:AddPrimedSnowParticleSystem(emitterInfo, mediumSnowInfo, index)
        self:AddPrimedSnowParticleSystem(emitterInfo, largeSnowInfo, index)
    end

    for i, centerX in ipairs(LIGHT_EMITTERS) do
        table.insert(self.particleSystems, self:CreateLightParticleSystem(i, centerX))
    end
end

function GreymoorBackground:ResizeSizes()
    local guiWidth, guiHeight = GuiRoot:GetDimensions()
    local GROUND_ASPECT_RATIO = GROUND_TEXTURE_USED_WIDTH / GROUND_TEXTURE_USED_HEIGHT
    local groundWidth = GROUND_ASPECT_RATIO * guiHeight
    if groundWidth < guiWidth then
        groundWidth = guiWidth
    end
    self.groundTexture:SetWidth(groundWidth) 
end

function GreymoorBackground:StartParticleSystems()
    for _, particleSystem in ipairs(self.particleSystems) do
        particleSystem:Start()
    end
end

function GreymoorBackground:StopParticleSystems()
    for _, particleSystem in ipairs(self.particleSystems) do
        particleSystem:Stop()
    end
end

function GreymoorBackground:Start()
    self.containerControl:SetAlpha(0)
    self.showTimeline:PlayFromStart()
    self:StartParticleSystems()
end

function GreymoorBackground:Stop()
    self:StopParticleSystems()
    self.showTimeline:Stop()
end

--Events

function GreymoorBackground:OnScreenResized()
    self:ResizeSizes()
end

--Global XML Handlers

function ZO_GreymoorBackground_OnInitialized(self)
    if IsGamepadUISupported() then
        PREGAME_ANIMATED_BACKGROUND = GreymoorBackground:New(self)
    end
end