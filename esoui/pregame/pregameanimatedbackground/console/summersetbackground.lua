local SummersetBackground = ZO_Object:Subclass()

ZO_SUMMERSET_BACKGROUND_FADE_DURATION_MS = 500

local WALL_TEXTURE_WIDTH = 4096
local WALL_TEXTURE_HEIGHT = 2048
local WALL_TEXTURE_USED_WIDTH = 4096
local WALL_TEXTURE_USED_HEIGHT = 1080
local WALL_TEXTURE_MAX_V = WALL_TEXTURE_USED_HEIGHT / WALL_TEXTURE_HEIGHT

--Background

function SummersetBackground:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function SummersetBackground:Initialize(control)
    self.control = control
    self.containerControl = control:GetNamedChild("Container")
    self.wallTexture = self.containerControl:GetNamedChild("Wall")
    self.wallTexture:SetTextureCoords(0, 1, 0, WALL_TEXTURE_MAX_V)
    
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

function SummersetBackground:InitializeAnimations()
    self.showTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_SummersetBackgroundShowAnimation", self.containerControl)
end

local LEAF_EMITTERS =
{
    { centerX = -1400 },
    { centerX = 600 },
    { centerX = -750 },
    { centerX = -1000 },
    { centerX = 400 },
    { centerX = -800 },
    { centerX = -1200 },
    { centerX = 200 },
    { centerX = 800 },
}
local NUM_LEAF_EMITTERS = #LEAF_EMITTERS
--The X range over which an emitter can spawn leaves
local LEAF_EMITTER_RANGE = 200
local HALF_LEAF_EMITTER_RANGE = LEAF_EMITTER_RANGE * 0.5
local LEAF_EMISSION_RATE = .15
local LEAF_FLIP_BOOK_PLAYBACK_INFO = { playbackType = ANIMATION_PLAYBACK_LOOP, loopCount = LOOP_INDEFINITELY }
local LEAF_MIN_SHADOW_OFFSET = 20
local LEAF_SHADOW_OFFSET_VARIANCE = 10
local LEAF_SHADOW_SIZE_VARIANCE = 20

function SummersetBackground:OnLeafParticleStart(particle)
    local shadowTexture, key = self.leafShadowTexturePool:AcquireObject()
    --A fake normalized distance in the Z axis
    local normalizedHeight = math.random()
    local offset = LEAF_MIN_SHADOW_OFFSET + LEAF_SHADOW_OFFSET_VARIANCE * normalizedHeight
    local particleSize = particle:GetParameter("Size")
    local size = particleSize +  LEAF_SHADOW_SIZE_VARIANCE * (1 - normalizedHeight)
    shadowTexture:SetDimensions(size, size)
    --The X offset is multiplied by 0.5 to match the angle of the light shafts
    shadowTexture:SetAnchor(TOPLEFT, particle:GetTextureControl(), TOPLEFT, offset * 0.5, offset)
    self.particleToLeafShadowTexturePoolKey[particle] = key
end

function SummersetBackground:OnLeafParticleStop(particle)
    self.leafShadowTexturePool:ReleaseObject(self.particleToLeafShadowTexturePoolKey[particle])
    self.particleToLeafShadowTexturePoolKey[particle] = nil
end

function SummersetBackground:CreateLeafParticleSystem(centerOffsetX, primeS)
    local leafParticleSystem = ZO_ControlParticleSystem:New(ZO_LeafParticle_Control)
    leafParticleSystem:SetParentControl(self.containerControl)
    leafParticleSystem:SetParticlesPerSecond(LEAF_EMISSION_RATE)
    leafParticleSystem:SetStartPrimeS(primeS)
    leafParticleSystem:SetOnParticleStartCallback(self.OnLeafParticleStartClosure)
    leafParticleSystem:SetOnParticleStopCallback(self.OnLeafParticleStopClosure)
    leafParticleSystem:SetParticleParameter("Size", ZO_UniformRangeGenerator:New(36, 48))
    leafParticleSystem:SetParticleParameter("Texture", "EsoUI/Art/PregameAnimatedBackground/leafTwirl.dds")
    leafParticleSystem:SetParticleParameter("FlipBookCellsWide", 16)
    leafParticleSystem:SetParticleParameter("FlipBookCellsHigh", 4)
    leafParticleSystem:SetParticleParameter("FlipBookPlaybackInfo", LEAF_FLIP_BOOK_PLAYBACK_INFO)
    leafParticleSystem:SetParticleParameter("FlipBookDurationS", ZO_UniformRangeGenerator:New(1.5, 4))
    leafParticleSystem:SetParticleParameter("DurationS", ZO_UniformRangeGenerator:New(2, 2.5))
    leafParticleSystem:SetParticleParameter("LeafSectionTop", ZO_UniformRangeGenerator:New(0, 0.6))
    leafParticleSystem:SetParticleParameter("LeafSectionBottom", ZO_UniformRangeGenerator:New(0, -1.2))
    leafParticleSystem:SetParticleParameter("LeafDescent", ZO_UniformRangeGenerator:New(1.3, 2))
    leafParticleSystem:SetParticleParameter("LeafTextureRotationRadians", ZO_WeightedChoiceGenerator:New(math.pi * 0.25, 0.4, math.pi * 0.35, 0.3, math.pi * 0.15, 0.3))
    leafParticleSystem:SetParticleParameter("LeafTumbleRadians", ZO_UniformRangeGenerator:New(-math.pi * 2, math.pi * 2))
    leafParticleSystem:SetParticleParameter("LeafFallHeight", 1200)
    leafParticleSystem:SetParticleParameter("LeafEasing", ZO_GenerateCubicBezierEase(.5,.38,.83,.67))
    leafParticleSystem:SetParticleParameter("AnchorRelativePoint", TOP)
    leafParticleSystem:SetParticleParameter("StartOffsetX", ZO_UniformRangeGenerator:New(centerOffsetX - HALF_LEAF_EMITTER_RANGE, centerOffsetX + HALF_LEAF_EMITTER_RANGE))
    leafParticleSystem:SetParticleParameter("StartOffsetY", -50)
    leafParticleSystem:SetParticleParameter("StartColorR", 0)
    leafParticleSystem:SetParticleParameter("StartColorG", ZO_UniformRangeGenerator:New(0.6, 1))
    leafParticleSystem:SetParticleParameter("StartColorB", 0)

    return leafParticleSystem
end

local LIGHT_EMITTERS = { -1000, -900, -750, -650, -400, -200, 0, 300, 500, 800, 950, 1100, 1200 }
local LIGHT_EMITTER_RANGE_X = 250
local LIGHT_DURATION_S = 6

function SummersetBackground:CreateLightParticleSystem(index, offsetX)
    local lightParticleSystem = ZO_ControlParticleSystem:New(ZO_StationaryParticle_Control)
    lightParticleSystem:SetParentControl(self.containerControl)
    lightParticleSystem:SetParticlesPerSecond(1 / LIGHT_DURATION_S)
    lightParticleSystem:SetStartPrimeS((index / #LIGHT_EMITTERS) * LIGHT_DURATION_S)
    lightParticleSystem:SetParticleParameter("Width", "EndAlpha", ZO_UniformRangeGenerator:New(32, 64, 0.07, 0.1))
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

function SummersetBackground:InitializeParticleSystems()
    self.OnLeafParticleStartClosure = function(...) self:OnLeafParticleStart(...) end
    self.OnLeafParticleStopClosure = function(...) self:OnLeafParticleStop(...) end
    self.leafShadowTexturePool = ZO_ControlPool:New("ZO_SummersetBackground_LeafShadow", self.containerControl)
    self.particleToLeafShadowTexturePoolKey = {}

    for i, emitterInfo in ipairs(LEAF_EMITTERS) do
        local centerOffsetX = emitterInfo.centerX
        local fullCycleS = 1 / LEAF_EMISSION_RATE
        --Spread the leaf emitters evenly over a full cycle. They fire in the order they are listed in LEAF_EMITTERS.
        local primeS = (1 - ((i - 1) / (NUM_LEAF_EMITTERS - 1))) * fullCycleS
        table.insert(self.particleSystems, self:CreateLeafParticleSystem(centerOffsetX, primeS))
    end

    for i, centerX in ipairs(LIGHT_EMITTERS) do
        table.insert(self.particleSystems, self:CreateLightParticleSystem(i, centerX))
    end
end

function SummersetBackground:ResizeSizes()
    local guiWidth, guiHeight = GuiRoot:GetDimensions()
    local WALL_ASPECT_RATIO = WALL_TEXTURE_USED_WIDTH / WALL_TEXTURE_USED_HEIGHT
    local wallWidth = WALL_ASPECT_RATIO * guiHeight
    if wallWidth < guiWidth then
        wallWidth = guiWidth
    end
    self.wallTexture:SetWidth(wallWidth) 
end

function SummersetBackground:StartParticleSystems()
    for _, particleSystem in ipairs(self.particleSystems) do
        particleSystem:Start()
    end
end

function SummersetBackground:StopParticleSystems()
    for _, particleSystem in ipairs(self.particleSystems) do
        particleSystem:Stop()
    end
end

function SummersetBackground:Start()
    self.containerControl:SetAlpha(0)
    self.showTimeline:PlayFromStart()
    self:StartParticleSystems()
end

function SummersetBackground:Stop()
    self:StopParticleSystems()
    self.showTimeline:Stop()
end

--Events

function SummersetBackground:OnScreenResized()
    self:ResizeSizes()
end

--Global XML Handlers

function ZO_SummersetBackground_OnInitialized(self)
    if IsConsoleUI() then
        PREGAME_ANIMATED_BACKGROUND = SummersetBackground:New(self)
    end
end