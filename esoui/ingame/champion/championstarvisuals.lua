ZO_CHAMPION_STAR_STATE =
{
    LOCKED = 1,
    AVAILABLE = 2,
    PURCHASED = 3,
}

ZO_CHAMPION_STAR_VISUAL_TYPE =
{
    NORMAL = 1,
    SLOTTABLE = 2,
    CLUSTER = 3,
}

local function ScaleParameterFactory(control, layerIndex)
    return function(scaleValue)
        control:SetSurfaceScale(layerIndex, scaleValue)
    end
end

local function AlphaParameterFactory(control, layerIndex)
    return function(alphaValue)
        control:SetSurfaceAlpha(layerIndex, alphaValue)
    end
end

local function RotationParameterFactory(control, layerIndex)
    return function(rotationValue)
        control:SetSurfaceTextureRotation(layerIndex, rotationValue)
    end
end

local function LinearReverseEase(progress)
    return 1 - progress
end

local STAR_TEXTURES_BY_TYPE =
{
    [ZO_CHAMPION_STAR_VISUAL_TYPE.NORMAL] = "EsoUI/Art/Champion/Stars/basic.dds",
    [ZO_CHAMPION_STAR_VISUAL_TYPE.SLOTTABLE] = "EsoUI/Art/Champion/Stars/slottable.dds",
    [ZO_CHAMPION_STAR_VISUAL_TYPE.CLUSTER] = "EsoUI/Art/Champion/Stars/cluster.dds",
}
local STAR_LAYERS_BY_TYPE_AND_STATE = {}

local ANIMATION_FRAMES = 1 / 24 -- timings based on 24fps animations

local NORMAL_STAR_LAYERS =
{
    atmoGlow = {
        texCoords = { 0, 0.5, 0, 0.25 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.55, fluxMax = 0.77, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true },
            },
        },
    },
    crossFlare =
    {
        texCoords = { 0.5, 1, 0, 0.25 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.90, fluxMax = 1.05, fluxPeriodSeconds = 4 * ANIMATION_FRAMES, useRandomFlux = true },
            },
        },
    },
    rimlight1 = 
    {
        texCoords = { 0, 0.5, 0.25, 0.5 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.95, fluxMax = 1.05, fluxPeriodSeconds = 4 * ANIMATION_FRAMES, useRandomFlux = true },
            },
        },
    },
    rimlight2 =
    {
        texCoords = { 0.5, 1, 0.25, 0.5 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.98, fluxMax = 1.02, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true },
            },
        },
    },
    rimlight3 = 
    {
        texCoords = { 0, 0.5, 0.5, 0.75 },
        interpolators = {},
    },
    starburst = {
        texCoords = { 0, 0.5, 0.75, 1 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory, 
                fluxParams = { fluxMin = 0.97, fluxMax = 1.03, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true },
            },
        },
    },
}

STAR_LAYERS_BY_TYPE_AND_STATE[ZO_CHAMPION_STAR_VISUAL_TYPE.NORMAL] =
{
    [ZO_CHAMPION_STAR_STATE.LOCKED] =
    {
        NORMAL_STAR_LAYERS.starburst,
        NORMAL_STAR_LAYERS.atmoGlow,
    },
    [ZO_CHAMPION_STAR_STATE.AVAILABLE] =
    {
        NORMAL_STAR_LAYERS.crossFlare,
        NORMAL_STAR_LAYERS.starburst,
    },
    [ZO_CHAMPION_STAR_STATE.PURCHASED] =
    {
        NORMAL_STAR_LAYERS.crossFlare,
        NORMAL_STAR_LAYERS.starburst,
        NORMAL_STAR_LAYERS.atmoGlow,
    },
}

local SLOTTABLE_STAR_LAYERS =
{
    atmoGlow = 
    {
        texCoords = { 0, 0.25, 0, 0.125 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.52, fluxMax = 0.72, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true },
            },
        },
    },
    bigRimLight =
    {
        texCoords = { 0.25, 0.5, 0, 0.125 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.95, fluxMax = 1.05, fluxPeriodSeconds = 3 * ANIMATION_FRAMES, useRandomFlux = true },
            },
            {
                parameterFactory = AlphaParameterFactory,
                fluxParams = { fluxMin = 0.95, fluxMax = 1.0, fluxPeriodSeconds = 3 * ANIMATION_FRAMES, useRandomFlux = true },
            },
        },
    },
    brightener =
    {
        texCoords = { 0.5, 0.75, 0, 0.125 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.97, fluxMax = 1.03, fluxPeriodSeconds = 4 * ANIMATION_FRAMES, useRandomFlux = true },
            },
        },
    },
    crossFlare = 
    {
        texCoords = { 0.75, 1, 0, 0.125 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 1.1, fluxMax = 1.25, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true },
            },
        },
    },
    expandingRimlight =
    {
        texCoords =  { 0, 0.25, 0.125, 0.25 },
        interpolators = {}
    },
    fourPointStarBurst = 
    {
        texCoords = { 0.25, 0.5, 0.125, 0.25 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.97, fluxMax = 1.03, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true },
            },
        },
    },
    rimlight = 
    {
        texCoords = { 0, 0.25, 0.25, 0.375 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.95, fluxMax = 1.05, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true },
            },
        },
    },
    rimlightCrescent = 
    {
        texCoords = { 0.25, 0.5, 0.25, 0.375 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.97, fluxMax = 1.03, fluxPeriodSeconds = 4 * ANIMATION_FRAMES, useRandomFlux = true },
            },
        },
    },
    sixPointFlare =
    {
        texCoords = { 0.5, 0.75, 0.25, 0.375 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.95, fluxMax = 1.05, fluxPeriodSeconds = 3 * ANIMATION_FRAMES, useRandomFlux = true },
            },
            {
                parameterFactory = AlphaParameterFactory,
                fluxParams = { fluxMin = 0.95, fluxMax = 1.0, fluxPeriodSeconds = 3 * ANIMATION_FRAMES, useRandomFlux = true },
            },
        },
    },
    starburst =
    {
        texCoords = { 0.75, 1, 0.25, 0.375 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.95, fluxMax = 1.05, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true },
            },
        },
    },
    starburstBig = 
    {
        texCoords = { 0, 0.25, 0.375, 0.5 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 1.1, fluxMax = 1.25, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true },
            },
        },
    },
    -- combat layers
    combatXFlare = 
    {
        texCoords = { 0.5, 0.75, 0.125, 0.25 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.97, fluxMax = 1.03, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true },
            },
        },
    },
    combatEnergy = 
    {
        texCoords = { 0.75, 1, 0.125, 0.25 },
        interpolators = {}
    },
    -- world layers
    worldCentralLight = 
    {
        texCoords = { 0.25, 0.5, 0.375, 0.5 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.97, fluxMax = 1.03, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true },
            },
        },
    },
    worldStarburst = {
        texCoords = { 0.5, 0.75, 0.375, 0.5 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.9, fluxMax = 1.0, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true},
            },
            {
                parameterFactory = RotationParameterFactory,
                fluxParams = { fluxMin = 0, fluxMax = ZO_TWO_PI, fluxPeriodSeconds = 1.5, fluxEasingFunction = ZO_LinearEase },
            },
        },
    },
    worldStarburstFaint = {
        texCoords = { 0.75, 1, 0.375, 0.5 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.9, fluxMax = 1.0, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true },
            },
            {
                parameterFactory = RotationParameterFactory,
                fluxParams = { fluxMin = 0, fluxMax = ZO_TWO_PI, fluxPeriodSeconds = 1, fluxEasingFunction = ZO_LinearEase },
            },
        },
    },
    -- conditioning layers
    conditioningBloodsplash =
    {
        texCoords = { 0, 0.25, 0.5, 0.625 },
        interpolators = {},
    },
    conditioningHorizontalLensFlare =
    {
        texCoords = { 0, 0.25, 0.625, 0.75 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.97, fluxMax = 1.03, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true },
            },
        },
    },
    conditioningLensFlare = 
    {
        texCoords = { 0, 0.25, 0.75, 0.875 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.97, fluxMax = 1.03, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true },
            },
        },
    },
    conditioningStarburst =
    {
        texCoords = { 0, 0.25, 0.875, 1 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.9, fluxMax = 1.0, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true },
            },
            {
                parameterFactory = RotationParameterFactory,
                fluxParams = { fluxMin = 0, fluxMax = ZO_TWO_PI, fluxPeriodSeconds = 1, fluxEasingFunction = ZO_LinearEase },
            },
        },
    },
    worldSlotted =
    {
        texCoords = { 0.5, 0.75, 0.5, 0.625 },
        setup = function(control, layerIndex)
            control:SetSurfaceScale(layerIndex, 0.35)
        end,
        useAlphaBlendMode = true,
        interpolators = {},
    },
    combatSlotted =
    {
        texCoords = { 0.25, 0.5, 0.5, 0.625 },
        setup = function(control, layerIndex)
            control:SetSurfaceScale(layerIndex, 0.35)
        end,
        useAlphaBlendMode = true,
        interpolators = {},
    },
    conditioningSlotted =
    {
        texCoords = { 0.75, 1, 0.5, 0.625 },
        setup = function(control, layerIndex)
            control:SetSurfaceScale(layerIndex, 0.35)
        end,
        useAlphaBlendMode = true,
        interpolators = {},
    },
}

STAR_LAYERS_BY_TYPE_AND_STATE[ZO_CHAMPION_STAR_VISUAL_TYPE.SLOTTABLE] =
{
    [ZO_CHAMPION_STAR_STATE.LOCKED] =
    {
        SLOTTABLE_STAR_LAYERS.fourPointStarBurst,
        SLOTTABLE_STAR_LAYERS.rimlight,
        SLOTTABLE_STAR_LAYERS.starburst,
        SLOTTABLE_STAR_LAYERS.atmoGlow,
    },
    [ZO_CHAMPION_STAR_STATE.AVAILABLE] =
    {
        SLOTTABLE_STAR_LAYERS.brightener,
        SLOTTABLE_STAR_LAYERS.rimlightCrescent,
        SLOTTABLE_STAR_LAYERS.starburstBig,
        SLOTTABLE_STAR_LAYERS.atmoGlow,
    },
    [ZO_CHAMPION_STAR_STATE.PURCHASED] =
    {
        SLOTTABLE_STAR_LAYERS.crossFlare,
        SLOTTABLE_STAR_LAYERS.starburstBig,
        SLOTTABLE_STAR_LAYERS.bigRimLight,
        SLOTTABLE_STAR_LAYERS.sixPointFlare,
        SLOTTABLE_STAR_LAYERS.rimlightCrescent,
        SLOTTABLE_STAR_LAYERS.atmoGlow,
    },
}

local SLOTTTABLE_STAR_EXTRA_LAYERS_BY_DISCIPLINE =
{
    [CHAMPION_DISCIPLINE_TYPE_WORLD] =
    {
        SLOTTABLE_STAR_LAYERS.worldCentralLight,
        SLOTTABLE_STAR_LAYERS.worldStarburst,
        SLOTTABLE_STAR_LAYERS.worldStarburstFaint,
    },
    [CHAMPION_DISCIPLINE_TYPE_COMBAT] =
    {
        SLOTTABLE_STAR_LAYERS.combatXFlare,
        SLOTTABLE_STAR_LAYERS.combatEnergy,
    },
    [CHAMPION_DISCIPLINE_TYPE_CONDITIONING] =
    {
        SLOTTABLE_STAR_LAYERS.conditioningBloodsplash,
        SLOTTABLE_STAR_LAYERS.conditioningHorizontalLensFlare,
        SLOTTABLE_STAR_LAYERS.conditioningLensFlare,
        SLOTTABLE_STAR_LAYERS.conditioningStarburst,
    },
}

local SLOTTED_STAR_LAYERS_BY_DISCIPLINE =
{
    [CHAMPION_DISCIPLINE_TYPE_WORLD] =
    {
        SLOTTABLE_STAR_LAYERS.worldSlotted,
    },
    [CHAMPION_DISCIPLINE_TYPE_COMBAT] =
    {
        SLOTTABLE_STAR_LAYERS.combatSlotted,
    },
    [CHAMPION_DISCIPLINE_TYPE_CONDITIONING] =
    {
        SLOTTABLE_STAR_LAYERS.conditioningSlotted,
    },
}

local CLUSTER_STAR_LAYERS = {
    activeRim1 = 
    {
        texCoords = { 0, 0.25, 0, 0.25 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.65, fluxMax = 1.1, fluxPeriodSeconds = 1.3},
            },
            {
                parameterFactory = AlphaParameterFactory,
                fluxParams = { fluxMin = 0.0, fluxMax = 1, fluxPeriodSeconds = 1.3},
            },
            {
                parameterFactory = RotationParameterFactory,
                fluxParams = { fluxMin = 0, fluxMax = ZO_TWO_PI, fluxPeriodSeconds = 1, fluxEasingFunction = ZO_LinearEase },
            },
        },
    },
    activeRim2 = 
    {
        texCoords = { 0, 0.25, 0.25, 0.5 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.65, fluxMax = 1.1, fluxPeriodSeconds = 1.3},
            },
            {
                parameterFactory = AlphaParameterFactory,
                fluxParams = { fluxMin = 0.0, fluxMax = 1, fluxPeriodSeconds = 1.3},
            },
            {
                parameterFactory = RotationParameterFactory,
                fluxParams = { fluxMin = 0, fluxMax = ZO_TWO_PI, fluxPeriodSeconds = 1, fluxEasingFunction = LinearReverseEase },
            },
        },
    },
    activeRim3 = 
    {
        texCoords = { 0, 0.25, 0.5, 0.75 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.65, fluxMax = 1.1, fluxPeriodSeconds = 1.3},
            },
            {
                parameterFactory = AlphaParameterFactory,
                fluxParams = { fluxMin = 0.0, fluxMax = 1, fluxPeriodSeconds = 1.3, fluxEasingFunction = ZO_GenerateLinearPiecewiseEase({0, 1, 1, 1, 0.5, 0}) },
            },
        },
    },
    cloudBgGreater =
    {
        texCoords = { 0, 0.25, 0.75, 1 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.95, fluxMax = 1, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true },
            },
            {
                parameterFactory = AlphaParameterFactory,
                fluxParams = { fluxMin = 0.97, fluxMax = 1, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true },
            },
        },
    },
    cloudBgLesser =
    {
        texCoords = { 0.25, 0.5, 0, 0.25 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.95, fluxMax = 1, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true },
            },
            {
                parameterFactory = AlphaParameterFactory,
                fluxParams = { fluxMin = 0.97, fluxMax = 1, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true },
            },
        },
    },
    nebulaGreater =
    {
        texCoords = { 0.75, 1, 0, 0.25 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.95, fluxMax = 1, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true, fluxPhase = 0.5 },
            },
            {
                parameterFactory = AlphaParameterFactory,
                fluxParams = { fluxMin = 0.99, fluxMax = 1, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true, fluxPhase = 0.5 },
            },
        },
    },
    nebulaLesser =
    {
        texCoords = { 0.25, 0.5, 0.25, 0.5 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.95, fluxMax = 1, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true, fluxPhase = 0.5 },
            },
            {
                parameterFactory = AlphaParameterFactory,
                fluxParams = { fluxMin = 0.99, fluxMax = 1, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true, fluxPhase = 0.5 },
            },
        },
    },
    redBlob = {}, -- TODO: cannot do multiply blendmode
    rimlightGreater =
    {
        texCoords = { 0.25, 0.5, 0.75, 1 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.95, fluxMax = 1.1, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true},
            },
            {
                parameterFactory = AlphaParameterFactory,
                fluxParams = { fluxMin = 0.9, fluxMax = 1, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true},
            },
        },
    },
    rimlightLesser =
    {
        texCoords = { 0.5, 0.75, 0.25, 0.5 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.95, fluxMax = 1.1, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true},
            },
            {
                parameterFactory = AlphaParameterFactory,
                fluxParams = { fluxMin = 0.9, fluxMax = 1, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true},
            },
        },
    },
    sixPointFlare =
    {
        texCoords = { 0.75, 1, 0.25, 0.5 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.95, fluxMax = 1.1, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true},
            },
            {
                parameterFactory = AlphaParameterFactory,
                fluxParams = { fluxMin = 0.9, fluxMax = 1, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true},
            },
        },
    },
    sixPointFlareLesser =
    {
        texCoords = { 0.5, 0.75, 0.75, 1 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.95, fluxMax = 1.1, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true},
            },
            {
                parameterFactory = AlphaParameterFactory,
                fluxParams = { fluxMin = 0.9, fluxMax = 1, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true},
            },
        },
    },
    sixPointFlareGreater =
    {
        texCoords = { 0.5, 0.75, 0.5, 0.75 },
        interpolators =
        {
            {
                parameterFactory = ScaleParameterFactory,
                fluxParams = { fluxMin = 0.95, fluxMax = 1.1, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true},
            },
            {
                parameterFactory = AlphaParameterFactory,
                fluxParams = { fluxMin = 0.9, fluxMax = 1, fluxPeriodSeconds = 2 * ANIMATION_FRAMES, useRandomFlux = true},
            },
        },
    },
}

STAR_LAYERS_BY_TYPE_AND_STATE[ZO_CHAMPION_STAR_VISUAL_TYPE.CLUSTER] =
{
    [ZO_CHAMPION_STAR_STATE.LOCKED] =
    {
        CLUSTER_STAR_LAYERS.sixPointFlare,
        CLUSTER_STAR_LAYERS.rimlightLesser,
        CLUSTER_STAR_LAYERS.nebulaLesser,
        CLUSTER_STAR_LAYERS.cloudBgLesser,
    },
    [ZO_CHAMPION_STAR_STATE.AVAILABLE] =
    {
        CLUSTER_STAR_LAYERS.sixPointFlare,
        CLUSTER_STAR_LAYERS.rimlightGreater,
        CLUSTER_STAR_LAYERS.nebulaGreater,
        CLUSTER_STAR_LAYERS.cloudBgGreater,
    },
    [ZO_CHAMPION_STAR_STATE.PURCHASED] =
    {
        CLUSTER_STAR_LAYERS.activeRim1,
        CLUSTER_STAR_LAYERS.activeRim2,
        CLUSTER_STAR_LAYERS.activeRim3,
        CLUSTER_STAR_LAYERS.sixPointFlareGreater,
        CLUSTER_STAR_LAYERS.rimlightGreater,
        CLUSTER_STAR_LAYERS.nebulaGreater,
        CLUSTER_STAR_LAYERS.cloudBgGreater,
    },
}

---------------------------
-- Champion Star Visuals --
---------------------------

--[[
    This can be attached to any TextureComposite control that wants to look like a champion star.
    it should not take a direct reference to a champion skill or any champion
    star state to avoid direct coupling; instead just pass in the
    data you want via the Setup() function.
]]--
ZO_ChampionStarVisuals = ZO_InitializingObject:Subclass()

function ZO_ChampionStarVisuals:Initialize(textureCompositeControl)
    self.control = textureCompositeControl
    self.alphaTextures = textureCompositeControl:GetNamedChild("AlphaTextures")
    self.interpolators = {}
end

function ZO_ChampionStarVisuals:Setup(visualType, state, disciplineType, isSlotted)
    if self.visualType == visualType and self.state == state and self.disciplineType == disciplineType and self.isSlotted == isSlotted then
        -- no change
        return
    end
    ZO_ClearNumericallyIndexedTable(self.interpolators)

    self.control:ClearAllSurfaces()
    self.control:SetTexture(STAR_TEXTURES_BY_TYPE[visualType])
    self.alphaTextures:ClearAllSurfaces()
    self.alphaTextures:SetTexture(STAR_TEXTURES_BY_TYPE[visualType])

    if visualType == ZO_CHAMPION_STAR_VISUAL_TYPE.SLOTTABLE and disciplineType then
        local layers = SLOTTTABLE_STAR_EXTRA_LAYERS_BY_DISCIPLINE[disciplineType]
        for _, layer in ipairs(layers) do
            self:AddLayer(layer)
        end

        if isSlotted then
            local layers = SLOTTED_STAR_LAYERS_BY_DISCIPLINE[disciplineType]
            for _, layer in ipairs(layers) do
                self:AddLayer(layer)
            end
        end
    end

    local layers = STAR_LAYERS_BY_TYPE_AND_STATE[visualType][state]
    for _, layer in ipairs(layers) do
        self:AddLayer(layer)
    end
    self.visualType = visualType
    self.state = state
    self.disciplineType = disciplineType
    self.isSlotted = isSlotted
end

local INSTANT_APPROACH = 1
function ZO_ChampionStarVisuals:AddLayer(layer)
    local control = layer.useAlphaBlendMode and self.alphaTextures or self.control
    local layerIndex = control:AddSurface(unpack(layer.texCoords))
    if layer.setup then
        layer.setup(control, layerIndex)
    end
    for _, interpolatorInfo in ipairs(layer.interpolators) do
        local interpolator = ZO_LerpInterpolator:New()
        interpolator:SetApproachFactor(INSTANT_APPROACH)
        interpolator:SetUpdateHandler(interpolatorInfo.parameterFactory(control, layerIndex))
        interpolator:SetFluxParams(interpolatorInfo.fluxParams)
        table.insert(self.interpolators, interpolator)
    end
end

function ZO_ChampionStarVisuals:Update(timeSeconds)
    for _, interpolator in ipairs(self.interpolators) do
        interpolator:Update(timeSeconds)
    end
end