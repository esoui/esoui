local FORCE_WIND_VELOCITY_UPDATE = true

local UI_WIDTH, UI_HEIGHT = 1920, 1080
local UI_CENTER_X, UI_CENTER_Y = UI_WIDTH * 0.5, UI_HEIGHT * 0.5

local GOLD_ROAD_COLOR = ZO_ColorDef:New(1, 0.8, 0.5, 1)
local OUROBOROS_GLOW_COLOR_BASE = ZO_ColorDef:New(1, 0.95, 0.8, 1)
local OUROBOROS_GLOW_COLOR_INTENSE = ZO_ColorDef:New(1, 0.8, 0.4, 1)
local OUROBOROS_GLOW_COLOR = ZO_ColorDef:New(1, 1, 1, 0)

-- minR, maxR, minG, maxG, minB, maxB, minA, maxA
local LEAF_COLORS =
{
    RED = ZO_ColorRange:New(0.7, 0.75, 0.2, 0.25, 0, 0, 0.96, 0.96),
    BRIGHT_YELLOW = ZO_ColorRange:New(0.95, 1, 0.9, 0.95, 0, 0, 0.96, 0.96),
    BURNT_YELLOW = ZO_ColorRange:New(0.7, 0.75, 0.55, 0.6, 0, 0, 0.96, 0.96),
    BRIGHT_ORANGE = ZO_ColorRange:New(0.7, 0.8, 0.5, 0.6, 0, 0, 0.96, 0.96),
    ORANGE = ZO_ColorRange:New(0.65, 0.7, 0.4, 0.5, 0, 0, 0.96, 0.96),
    BURNT_ORANGE = ZO_ColorRange:New(0.8, 0.85, 0.4, 0.45, 0, 0, 0.96, 0.96),
}

local LEAF_ANCHOR_CONTROLS =
{
    BACKGROUND = 1,
    TREES_LEFT = 2,
    TREES_RIGHT = 3,
}

local LEAF_ANCHOR_CONTROL_REFS = {}

-- minForwardX, maxForwardX, minForwardY, maxForwardY
local LEAF_FORWARD_VECTOR_DOWN_LEFT = ZO_VectorRange:New(-100, -200, 380, 460)
local LEAF_FORWARD_VECTOR_DOWN_RIGHT = ZO_VectorRange:New(100, 200, 380, 460)
local LEAF_FORWARD_VECTOR_LEFT = ZO_VectorRange:New(-10, -40, 0, 0)
local LEAF_FORWARD_VECTOR_RIGHT = ZO_VectorRange:New(70, 100, 10, 30)
local LEAF_FORWARD_VECTOR_RIGHT_STRONG = ZO_VectorRange:New(30, 50, 10, 40)

local LEAF_SPAWNERS = ZO_WeightedValues:New(
    ZO_WeightedValue:New({
        anchorTo = LEAF_ANCHOR_CONTROLS.TREES_LEFT,
        anchorPoint = TOPRIGHT,
        colorRanges = ZO_WeightedColorRanges:New(LEAF_COLORS.BRIGHT_ORANGE, LEAF_COLORS.BURNT_ORANGE),
        drawLevel = 100,
        forwardRotationAngleCoefficient = 1,
        forwardVectorRange = LEAF_FORWARD_VECTOR_RIGHT,
        -- minX, maxX, minY, maxX, minNormalizedZ, maxNormalizedZ
        positionRanges = ZO_WeightedVectorRanges:New(
            ZO_VectorRange:New(50 - UI_CENTER_X, 150 - UI_CENTER_X, 50, 150, 0.7, 0.8),
            ZO_VectorRange:New(125 - UI_CENTER_X, 290 - UI_CENTER_X, 150, 220, 0.8, 0.9),
            ZO_VectorRange:New(420 - UI_CENTER_X, 540 - UI_CENTER_X, 160, 215, 0.9, 1))
    }, 300),
    ZO_WeightedValue:New({
        anchorTo = LEAF_ANCHOR_CONTROLS.TREES_RIGHT,
        anchorPoint = TOPRIGHT,
        colorRanges = ZO_WeightedColorRanges:New(LEAF_COLORS.ORANGE),
        drawLevel = 325, -- On top of the front right tree
        forwardRotationAngleCoefficient = 1,
        forwardVectorRange = LEAF_FORWARD_VECTOR_LEFT,
        positionRanges = ZO_WeightedVectorRanges:New(ZO_VectorRange:New(1880 - UI_WIDTH, 1970 - UI_WIDTH, 0, 40, 0.75, 1)),
    }, 100),
    ZO_WeightedValue:New({
        anchorTo = LEAF_ANCHOR_CONTROLS.TREES_RIGHT,
        anchorPoint = TOPRIGHT,
        colorRanges = ZO_WeightedColorRanges:New(LEAF_COLORS.BURNT_YELLOW),
        drawLevel = 265, -- On top of the left and back right trees
        forwardRotationAngleCoefficient = 1,
        forwardVectorRange = LEAF_FORWARD_VECTOR_LEFT,
        positionRanges = ZO_WeightedVectorRanges:New(ZO_VectorRange:New(1340 - UI_WIDTH, 1520 - UI_WIDTH, 0, 75, 0.5, 0.75)),
    }, 100),
    ZO_WeightedValue:New({
        anchorTo = LEAF_ANCHOR_CONTROLS.BACKGROUND,
        anchorPoint = TOP,
        colorRanges = ZO_WeightedColorRanges:New(LEAF_COLORS.BRIGHT_YELLOW),
        drawLevel = 275, -- On top of the left and back right trees
        forwardRotationAngleCoefficient = 1,
        forwardVectorRange = LEAF_FORWARD_VECTOR_LEFT,
        positionRanges = ZO_WeightedVectorRanges:New(ZO_VectorRange:New(1320 - UI_CENTER_X, 1400 - UI_CENTER_X, 150, 200, 0.25, 0.5)),
    }, 80),
    ZO_WeightedValue:New({
        anchorTo = LEAF_ANCHOR_CONTROLS.BACKGROUND,
        anchorPoint = TOP,
        colorRanges = ZO_WeightedColorRanges:New(LEAF_COLORS.RED),
        drawLevel = 285, -- On top of the left and back right trees
        forwardRotationAngleCoefficient = 0.1,
        forwardVectorRange = LEAF_FORWARD_VECTOR_RIGHT_STRONG,
        positionRanges = ZO_WeightedVectorRanges:New(ZO_VectorRange:New(1300 - UI_CENTER_X, 1375 - UI_CENTER_X, 350, 375, 0.0, 0.25)),
    }, 50),
    ZO_WeightedValue:New({
        anchorTo = LEAF_ANCHOR_CONTROLS.BACKGROUND,
        anchorPoint = TOP,
        colorRanges = ZO_WeightedColorRanges:New(LEAF_COLORS.ORANGE, LEAF_COLORS.BURNT_ORANGE),
        drawLevel = 4000, -- On top of all other elements.
        forwardRotationAngleCoefficient = 0.25,
        forwardVectorRange = LEAF_FORWARD_VECTOR_DOWN_RIGHT,
        positionRanges = ZO_WeightedVectorRanges:New(
            ZO_VectorRange:New(0, UI_CENTER_X * 0.5, -200, -200, 8, 40)),
    }, 30),
    ZO_WeightedValue:New({
        anchorTo = LEAF_ANCHOR_CONTROLS.BACKGROUND,
        anchorPoint = TOP,
        colorRanges = ZO_WeightedColorRanges:New(LEAF_COLORS.ORANGE, LEAF_COLORS.BURNT_ORANGE),
        drawLevel = 4010, -- On top of all other elements.
        forwardRotationAngleCoefficient = 0.25,
        forwardVectorRange = LEAF_FORWARD_VECTOR_DOWN_LEFT,
        positionRanges = ZO_WeightedVectorRanges:New(
            ZO_VectorRange:New(-UI_CENTER_X * 0.5, 0, -200, -200, 8, 40)),
    }, 30))

-- Custom parameter definitions
-- CreateBackgroundParameter* arguments: parameterKey, defaultValue, minValue, maxValue, formatString

CreateBackgroundParameterFloat("ZO_BACKGROUND_LEAF_BRIGHTNESS_MAX", 0.8, 0, 2)
CreateBackgroundParameterFloat("ZO_BACKGROUND_LEAF_BRIGHTNESS_MIN", 0.3, 0, 2)

CreateBackgroundParameterInteger("ZO_BACKGROUND_LEAF_GRAVITY_VECTOR_X", 0, -200, 200)
CreateBackgroundParameterInteger("ZO_BACKGROUND_LEAF_GRAVITY_VECTOR_Y", 120, -200, 200)

CreateBackgroundParameterInteger("ZO_BACKGROUND_LEAF_INSTANCES_MAX", 60, 0, 100)

CreateBackgroundParameterFloat("ZO_BACKGROUND_LEAF_SCALE_MAX", 0.1, 0.001, 1)
CreateBackgroundParameterFloat("ZO_BACKGROUND_LEAF_SCALE_MIN", 0.07, 0.001, 1)

CreateBackgroundParameterFloat("ZO_BACKGROUND_LEAF_SPAWN_INTERVAL_MAX_SECONDS", 1, 0, 10)
CreateBackgroundParameterFloat("ZO_BACKGROUND_LEAF_SPAWN_INTERVAL_MIN_SECONDS", 0.6, 0, 10)

CreateBackgroundParameterAngle("ZO_BACKGROUND_LEAF_FORWARD_ROTATION_ANGLE_MAX", 720, -1440, 1440)
CreateBackgroundParameterAngle("ZO_BACKGROUND_LEAF_FORWARD_ROTATION_ANGLE_MIN", -720, -1440, 1440)

CreateBackgroundParameterAngle("ZO_BACKGROUND_LEAF_ROTATION_VELOCITY_MAX", 720, -1440, 1440)
CreateBackgroundParameterAngle("ZO_BACKGROUND_LEAF_ROTATION_VELOCITY_MIN", -720, -1440, 1440)

CreateBackgroundParameterInteger("ZO_BACKGROUND_OUROBOROS_GLOW_BLUR_KERNEL_SIZE", 2, 1, 11)
CreateBackgroundParameterFloat("ZO_BACKGROUND_OUROBOROS_GLOW_BLUR_FACTOR_MAX", 10, 0, 10)

CreateBackgroundParameterFloat("ZO_BACKGROUND_OUROBOROS_GLOW_FLICKER_ALPHA_STRENGTH", 0.5, 0, 1)
CreateBackgroundParameterFloat("ZO_BACKGROUND_OUROBOROS_GLOW_FLICKER_COLOR_STRENGTH", 0, 0, 1)
CreateBackgroundParameterFloat("ZO_BACKGROUND_OUROBOROS_GLOW_FLICKER_FADE_IN_INTERVAL_SECONDS", 2, 0.01, 60, "%.2f seconds")
CreateBackgroundParameterFloat("ZO_BACKGROUND_OUROBOROS_GLOW_FLICKER_SPEED", 0.5, 0, 2)

CreateBackgroundParameterFloat("ZO_BACKGROUND_OUROBOROS_GLOW_RGB_WEIGHT_MAX", 1, 0, 2)
CreateBackgroundParameterFloat("ZO_BACKGROUND_OUROBOROS_GLOW_RGB_WEIGHT_MIN", 0.75, 0, 2)

CreateBackgroundParameterFloat("ZO_BACKGROUND_TREES_WAVE_OFFSET_X_MAX", 0.0045, 0, 0.1)
CreateBackgroundParameterFloat("ZO_BACKGROUND_TREES_WAVE_OFFSET_Y_MAX", 0.00075, 0, 0.1)
CreateBackgroundParameterFloat("ZO_BACKGROUND_TREES_WAVE_SPEED_COEFFICIENT_BASE", 1, 0, 4)

CreateBackgroundParameterFloat("ZO_BACKGROUND_WIND_MOUSE_TREE_WAVE_SPEED_COEFFICIENT", 2, 0, 10)
CreateBackgroundParameterInteger("ZO_BACKGROUND_WIND_MOUSE_VELOCITY_COEFFICIENT", 24000, 0, 20000)
CreateBackgroundParameterInteger("ZO_BACKGROUND_WIND_VELOCITY_MAX", 100, 0, 100000)

CreateBackgroundParameterInteger("ZO_BACKGROUND_WIND_TRANSITION_INTERVAL_SECONDS", 8, 0, 10)
CreateBackgroundParameterInteger("ZO_BACKGROUND_WIND_UPDATE_INTERVAL_MAX_SECONDS", 16, 1, 60, "%d seconds")
CreateBackgroundParameterInteger("ZO_BACKGROUND_WIND_UPDATE_INTERVAL_MIN_SECONDS", 3, 1, 60, "%d seconds")
CreateBackgroundParameterFloat("ZO_BACKGROUND_WIND_VELOCITY_OVERRIDE_TRANSITION_INTERVAL_SECONDS", 0.1, 0, 5, "%.1f seconds")

-- [ Required ]
-- After defining the parameters, the global table -must- be
-- updated with the current/calculated parameter values.
UpdateBackgroundParameters()

-- Pregame Animated Background

ZO_PeninsulaBackground = ZO_BaseBackground:Subclass()

-- Override Method Implementations

function ZO_PeninsulaBackground:InitializeControls(...)
    ZO_BaseBackground.InitializeControls(self, ...)

    self.leavesControl = self.control:GetNamedChild("Leaves")
    self.ouroborosGlowTexture = self.control:GetNamedChild("OuroborosGlow")
    self.sunRaysTexture = self.control:GetNamedChild("SunRays")
    self.terrainSilhouetteTexture = self.control:GetNamedChild("TerrainSilhouette")
    self.terrainTexture = self.control:GetNamedChild("Terrain")
    self.treesLeftSilhouetteTexture = self.control:GetNamedChild("TreesLeftSilhouette")
    self.treesLeftTexture = self.control:GetNamedChild("TreesLeft")
    self.treesBackRightSilhouetteTexture = self.control:GetNamedChild("TreesBackRightSilhouette")
    self.treesBackRightTexture = self.control:GetNamedChild("TreesBackRight")
    self.treesMidRightTexture = self.control:GetNamedChild("TreesMidRight")
    self.treesRightSilhouetteTexture = self.control:GetNamedChild("TreesRightSilhouette")
    self.treesRightTexture = self.control:GetNamedChild("TreesRight")

    LEAF_ANCHOR_CONTROL_REFS[LEAF_ANCHOR_CONTROLS.BACKGROUND] = self.backgroundTexture
    LEAF_ANCHOR_CONTROL_REFS[LEAF_ANCHOR_CONTROLS.TREES_LEFT] = self.treesLeftTexture
    LEAF_ANCHOR_CONTROL_REFS[LEAF_ANCHOR_CONTROLS.TREES_RIGHT] = self.treesRightTexture

    self.titleFadeInTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_PeninsulaBackgroundAnimation_TitleFadeIn", self.control)
    self.sunRaysFadeInTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_PeninsulaBackgroundAnimation_SunRaysFadeIn", self.control)

    self:InitializeControlPools()
    self:InitializeMovementControllers()
    self:ResetAnimationState()
end

function ZO_PeninsulaBackground:StartAnimation(...)
    -- Order matters
    self:ResetAnimationState()
    ZO_BaseBackground.StartAnimation(self, ...)
    DIRECTIONAL_INPUT:Activate(self, self.control)
end

function ZO_PeninsulaBackground:StopAnimation(...)
    -- Order matters
    ZO_BaseBackground.StopAnimation(self, ...)
    self:ResetAnimationState()
end

function ZO_PeninsulaBackground:UpdateLayout(...)
    if not ZO_BaseBackground.UpdateLayout(self, ...) then
        return false
    end

    return true
end

function ZO_PeninsulaBackground:OnHidden(...)
    ZO_BaseBackground.OnHidden(self, ...)

    self:ResetAnimationState()
end

function ZO_PeninsulaBackground:OnIntroAnimationPlay(animation, completed)
    ZO_BaseBackground.OnIntroAnimationPlay(self, completed)

    OUROBOROS_GLOW_COLOR:SetAlpha(0)

    self.backgroundTexture:SetMaskMode(CONTROL_MASK_MODE_THRESHOLD)
    self.backgroundTexture:SetMaskThresholdZeroAlphaEdge(1)
    self.backgroundTexture:SetColor(0, 0, 0, 1)

    self.ouroborosGlowTexture:SetAlpha(0)
    self.ouroborosGlowTexture:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, ZO_BACKGROUND_OUROBOROS_GLOW_RGB_WEIGHT_MIN)

    self.ouroborosTexture:SetColor(0, 0, 0, 0)

    self.sunRaysTexture:SetVertexColors(VERTEX_POINTS_BOTTOMLEFT + VERTEX_POINTS_BOTTOMRIGHT, 1, 1, 1, 0)
    self.sunRaysTexture:SetVertexColors(VERTEX_POINTS_TOPLEFT + VERTEX_POINTS_TOPRIGHT, 1, 1, 1, 0)

    self.terrainSilhouetteTexture:SetHidden(false)
    self.terrainTexture:SetMaskMode(CONTROL_MASK_MODE_THRESHOLD)
    self.terrainTexture:SetMaskThresholdZeroAlphaEdge(1)
    self.terrainTexture:SetColor(0, 0, 0, 1)

    self.titleTexture:SetAlpha(0)

    self.treesLeftSilhouetteTexture:SetHidden(false)
    self.treesLeftSilhouetteTexture:SetVertexUV(VERTEX_POINTS_TOPLEFT, 0, 0)
    self.treesLeftSilhouetteTexture:SetVertexUV(VERTEX_POINTS_TOPRIGHT, 1, 0)
    self.treesLeftTexture:SetMaskMode(CONTROL_MASK_MODE_THRESHOLD)
    self.treesLeftTexture:SetMaskThresholdZeroAlphaEdge(1)
    self.treesLeftTexture:SetColor(0, 0, 0, 1)
    self.treesLeftTexture:SetVertexUV(VERTEX_POINTS_TOPLEFT, 0, 0)
    self.treesLeftTexture:SetVertexUV(VERTEX_POINTS_TOPRIGHT, 1, 0)

    self.treesBackRightSilhouetteTexture:SetHidden(false)
    self.treesBackRightSilhouetteTexture:SetVertexUV(VERTEX_POINTS_TOPLEFT, 0, 0)
    self.treesBackRightSilhouetteTexture:SetVertexUV(VERTEX_POINTS_TOPRIGHT, 1, 0)
    self.treesBackRightTexture:SetMaskMode(CONTROL_MASK_MODE_THRESHOLD)
    self.treesBackRightTexture:SetMaskThresholdZeroAlphaEdge(1)
    self.treesBackRightTexture:SetColor(0, 0, 0, 1)
    self.treesBackRightTexture:SetVertexUV(VERTEX_POINTS_TOPLEFT, 0, 0)
    self.treesBackRightTexture:SetVertexUV(VERTEX_POINTS_TOPRIGHT, 1, 0)

    self.treesMidRightTexture:SetMaskMode(CONTROL_MASK_MODE_THRESHOLD)
    self.treesMidRightTexture:SetMaskThresholdZeroAlphaEdge(1)
    self.treesMidRightTexture:SetColor(0, 0, 0, 1)
    self.treesMidRightTexture:SetVertexUV(VERTEX_POINTS_TOPLEFT, 0, 0)
    self.treesMidRightTexture:SetVertexUV(VERTEX_POINTS_TOPRIGHT, 1, 0)

    self.treesRightSilhouetteTexture:SetHidden(false)
    self.treesRightSilhouetteTexture:SetVertexUV(VERTEX_POINTS_TOPLEFT, 0, 0)
    self.treesRightSilhouetteTexture:SetVertexUV(VERTEX_POINTS_TOPRIGHT, 1, 0)
    self.treesRightTexture:SetMaskMode(CONTROL_MASK_MODE_THRESHOLD)
    self.treesRightTexture:SetMaskThresholdZeroAlphaEdge(1)
    self.treesRightTexture:SetColor(0, 0, 0, 1)
    self.treesRightTexture:SetVertexUV(VERTEX_POINTS_TOPLEFT, 0, 0)
    self.treesRightTexture:SetVertexUV(VERTEX_POINTS_TOPRIGHT, 1, 0)

    FLICKER_EFFECT:RegisterControl(self.ouroborosGlowTexture, ZO_BACKGROUND_OUROBOROS_GLOW_FLICKER_SPEED, ZO_BACKGROUND_OUROBOROS_GLOW_FLICKER_ALPHA_STRENGTH, ZO_BACKGROUND_OUROBOROS_GLOW_FLICKER_COLOR_STRENGTH, ZO_BACKGROUND_OUROBOROS_GLOW_BLUR_FACTOR_MAX, OUROBOROS_GLOW_COLOR)

    self.titleFadeInTimeline:PlayFromStart()
    self.sunRaysFadeInTimeline:PlayFromStart()
end

function ZO_PeninsulaBackground:OnIntroAnimationStop(animation, completed)
    -- Suppress the default behavior of ZO_BaseBackground.OnIntroAnimationStop.
    -- This background class manages the visibility of the ouroboros and title manually.

    self.backgroundTexture:SetMaskThresholdZeroAlphaEdge(-self.backgroundTexture:GetMaskThresholdThickness())
    self.backgroundTexture:SetMaskMode(CONTROL_MASK_MODE_NONE)

    self.terrainTexture:SetMaskMode(CONTROL_MASK_MODE_NONE)
    self.terrainSilhouetteTexture:SetHidden(true)

    self.treesLeftTexture:SetMaskMode(CONTROL_MASK_MODE_NONE)
    self.treesLeftSilhouetteTexture:SetHidden(true)

    self.treesBackRightTexture:SetMaskMode(CONTROL_MASK_MODE_NONE)
    self.treesBackRightSilhouetteTexture:SetHidden(true)

    self.treesMidRightTexture:SetMaskMode(CONTROL_MASK_MODE_NONE)

    self.treesRightTexture:SetMaskMode(CONTROL_MASK_MODE_NONE)
    self.treesRightSilhouetteTexture:SetHidden(true)
end

function ZO_PeninsulaBackground:OnIntroAnimationUpdate(animation, progress)
    -- Suppress the default behavior of ZO_BaseBackground.OnIntroAnimationUpdate.

    -- Masked fade in Background, Terrain and Trees.
    local backgroundMaskThreshold = zo_lerp(1, -self.backgroundTexture:GetMaskThresholdThickness(), progress)
    self.backgroundTexture:SetMaskThresholdZeroAlphaEdge(backgroundMaskThreshold)
    self.terrainTexture:SetMaskThresholdZeroAlphaEdge(backgroundMaskThreshold)
    self.treesLeftTexture:SetMaskThresholdZeroAlphaEdge(backgroundMaskThreshold)
    self.treesBackRightTexture:SetMaskThresholdZeroAlphaEdge(backgroundMaskThreshold)
    self.treesMidRightTexture:SetMaskThresholdZeroAlphaEdge(backgroundMaskThreshold)
    self.treesRightTexture:SetMaskThresholdZeroAlphaEdge(backgroundMaskThreshold)

    -- Fade in Tree Silhouettes.
    local silhouetteAlpha = 1 - zo_pow(progress, 5)
    self.terrainSilhouetteTexture:SetAlpha(silhouetteAlpha)
    self.treesLeftSilhouetteTexture:SetAlpha(silhouetteAlpha)
    self.treesBackRightSilhouetteTexture:SetAlpha(silhouetteAlpha)
    self.treesRightSilhouetteTexture:SetAlpha(silhouetteAlpha)

    -- Transition Background from the Gold Road color to full color.
    do
        local r, g, b = ZO_ColorDef.LerpRGB(GOLD_ROAD_COLOR, ZO_WHITE, progress)
        self.backgroundTexture:SetColor(r, g, b, 1)
    end
end

function ZO_PeninsulaBackground:OnLoopAnimationUpdate(animation, progress)
    ZO_BaseBackground.OnLoopAnimationUpdate(self, animation, progress)

    local frameTimeS = GetFrameTimeSeconds() - self.startLoopFrameTimeS
    if frameTimeS <= 0 then
        return
    end

    -- Animate leaf particles.
    self:UpdateLeafAnimations(frameTimeS)

    -- Determine whether the left mouse button or left stick is, or was, engaged.
    -- Interpolate the interaction coefficient to 1 while engaged; otherwise to 0.
    local interactionCoefficient = self.interactionCoefficient
    local interactionCoefficientChanged = false
    if interactionCoefficient < 1 and (self.mouseDownX or self.movementControllerVectorX ~= 0 or self.movementControllerVectorY ~= 0) then
        interactionCoefficientChanged = true
        interactionCoefficient = zo_min(1, zo_lerp(interactionCoefficient, 1, 0.08))
    elseif self.interactionCoefficient >= 0.01 then
        interactionCoefficientChanged = true
        interactionCoefficient = zo_max(0, zo_lerp(interactionCoefficient, 0, 0.025))
    end

    -- Update audible wind intensity and direction.
    local windIntensityFromInteractionDuration = zo_lerp(0, 0.5, interactionCoefficient)
    local windIntensityFromMagnitude = zo_lerp(0, 0.5, self.windMagnitude / ZO_BACKGROUND_WIND_MOUSE_VELOCITY_COEFFICIENT)
    -- Clamp to [0, 1]
    self.audioWindIntensity = zo_clamp(windIntensityFromInteractionDuration + windIntensityFromMagnitude, 0, 1)
    local windDirectionX, windDirectionY
    if self.movementControllerVectorX ~= 0 or self.movementControllerVectorY ~= 0 then
        -- Normalize from [-1, 1] to [0, 1]
        self.audioWindDirectionX = (self.movementControllerVectorX + 1) * 0.5
        self.audioWindDirectionY = (self.movementControllerVectorY + 1) * 0.5
    else
        local windDirectionX, windDirectionY = WINDOW_MANAGER:GetUIMousePosition()
        -- Normalize to [0, 1]
        local guiWidth, guiHeight = GuiRoot:GetDimensions()
        self.audioWindDirectionX = windDirectionX / guiWidth
        self.audioWindDirectionY = windDirectionY / guiHeight
    end
    SetPregameAnimatedBackgroundWindState(self.audioWindIntensity, self.audioWindDirectionX, self.audioWindDirectionY)

    if interactionCoefficientChanged then
        -- Left mouse button or left stick is, or was, engaged;
        -- apply the interpolated wind and ouroboros glow visual states.
        self.interactionCoefficient = interactionCoefficient
        local ouroborosCoefficient = interactionCoefficient * self.introTitleProgress
        local easedOuroborosCoefficient = ZO_EaseInQuadratic(ouroborosCoefficient)

        -- Simulate wind by increasing the tree wave speed.
        self.treeWaveSpeedCoefficient = zo_lerp(ZO_BACKGROUND_TREES_WAVE_SPEED_COEFFICIENT_BASE, ZO_BACKGROUND_WIND_MOUSE_TREE_WAVE_SPEED_COEFFICIENT, interactionCoefficient)

        -- Increase ouroboros glow intensity.
        self.ouroborosGlowStrength = zo_lerp(ZO_BACKGROUND_OUROBOROS_GLOW_RGB_WEIGHT_MIN, ZO_BACKGROUND_OUROBOROS_GLOW_RGB_WEIGHT_MAX, ouroborosCoefficient)
        self.ouroborosGlowTexture:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, self.ouroborosGlowStrength)

        -- Reduce flicker strength.
        do
            local alphaFlickerStrength = zo_lerp(ZO_BACKGROUND_OUROBOROS_GLOW_FLICKER_ALPHA_STRENGTH, ZO_BACKGROUND_OUROBOROS_GLOW_FLICKER_ALPHA_STRENGTH * 0.5, easedOuroborosCoefficient)
            local colorFlickerStrength = zo_lerp(ZO_BACKGROUND_OUROBOROS_GLOW_FLICKER_COLOR_STRENGTH, ZO_BACKGROUND_OUROBOROS_GLOW_FLICKER_COLOR_STRENGTH * 0.5, easedOuroborosCoefficient)
            FLICKER_EFFECT:SetAlphaAndColorFlickerStrength(self.ouroborosGlowTexture, alphaFlickerStrength, colorFlickerStrength)
        end

        -- Change ouroboros glow to amber.
        OUROBOROS_GLOW_COLOR:SetLerpRGB(OUROBOROS_GLOW_COLOR_BASE, OUROBOROS_GLOW_COLOR_INTENSE, ouroborosCoefficient)
    end
end

function ZO_PeninsulaBackground:OnPersistentAnimationUpdate(animation, progress)
    local frameTimeS = GetFrameTimeSeconds()

    -- Fade in key elements.
    local fadeInProgress = frameTimeS - self.startFrameTimeS
    if fadeInProgress < 10 then
        fadeInProgress = zo_clamp((fadeInProgress - 1) / 6, 0, 1)
        fadeInProgress = fadeInProgress * fadeInProgress
        local color = 0.5 + 0.5 * fadeInProgress
        self.backgroundTexture:SetColor(1, 1, 1, 1)
        self.terrainTexture:SetColor(color, color, color, 1)
        self.treesBackRightTexture:SetColor(color, color, color, 1)
        self.treesLeftTexture:SetColor(color, color, color, 1)
        self.treesMidRightTexture:SetColor(color, color, color, 1)
        self.treesRightTexture:SetColor(color, color, color, 1)
    end

    -- Manipulate the vertex UV coordinates to simulate waving of the
    -- tree elements as this produces a more convincing visual effect
    -- than the wave shader effect.
    local waveTimeS = self.treeWaveOffset + GetFrameDeltaSeconds() * self.treeWaveSpeedCoefficient
    self.treeWaveOffset = waveTimeS
    local OFFSET_X_MAX = ZO_BACKGROUND_TREES_WAVE_OFFSET_X_MAX
    local OFFSET_Y_MAX = ZO_BACKGROUND_TREES_WAVE_OFFSET_Y_MAX
    local sin1, sin2 = zo_sin(waveTimeS * 0.3), zo_sin(waveTimeS * 0.8 + 2)
    local cos1, cos2 = zo_cos(waveTimeS * 0.9), zo_cos(waveTimeS * 1.3 + 4)
    local distribution1 = zo_sin(waveTimeS * 1.2) * 0.5 + 0.5
    local distribution2 = zo_sin(waveTimeS * 1.5) * 0.5 + 0.5

    -- Front left tree wave.
    local u1 = (distribution1 * sin1 + (1 - distribution1) * sin2) * OFFSET_X_MAX
    local v1 = cos1 * OFFSET_Y_MAX
    do
        local u, v = u1 * 0.2, v1 * 0.2 + OFFSET_Y_MAX
        self.treesLeftTexture:SetVertexUV(VERTEX_POINTS_TOPLEFT, u, v)
        self.treesLeftSilhouetteTexture:SetVertexUV(VERTEX_POINTS_TOPLEFT, u, v)
    end
    do
        local u, v = 1 + u1, v1 + OFFSET_Y_MAX
        self.treesLeftTexture:SetVertexUV(VERTEX_POINTS_TOPRIGHT, u, v)
        self.treesLeftSilhouetteTexture:SetVertexUV(VERTEX_POINTS_TOPRIGHT, u, v)
    end

    -- Back right tree wave.
    local u2 = (0.5 * sin1 + 0.5 * sin2) * OFFSET_X_MAX
    local v2 = 0
    do
        local u, v = u2, v2
        self.treesBackRightTexture:SetVertexUV(VERTEX_POINTS_TOPLEFT, u, v)
        self.treesBackRightSilhouetteTexture:SetVertexUV(VERTEX_POINTS_TOPLEFT, u, v)
        self.treesBackRightTexture:SetVertexUV(VERTEX_POINTS_TOPRIGHT, 1, 0)
        self.treesBackRightSilhouetteTexture:SetVertexUV(VERTEX_POINTS_TOPRIGHT, 1, 0)
    end

    do
        local u = (zo_sin(waveTimeS * 1.8 + 3) * 0.5 + sin2 * 0.5) * OFFSET_X_MAX * 2
        local v = cos2 * OFFSET_Y_MAX + OFFSET_Y_MAX
        self.treesMidRightTexture:SetVertexUV(VERTEX_POINTS_TOPLEFT, u, v)
        self.treesMidRightTexture:SetVertexUV(VERTEX_POINTS_TOPRIGHT, 1, 0)
    end

    -- Front right tree wave.
    local u3 = (distribution2 * sin2 + (1 - distribution2) * sin1) * OFFSET_X_MAX
    local v3 = (distribution2 * cos1 + (1 - distribution2) * cos2) * OFFSET_Y_MAX
    do
        local u, v = u3, v3 + OFFSET_Y_MAX
        self.treesRightTexture:SetVertexUV(VERTEX_POINTS_TOPLEFT, u, v)
        self.treesRightSilhouetteTexture:SetVertexUV(VERTEX_POINTS_TOPLEFT, u, v)
    end
    do
        local u, v = 1 + u3 * 0.2, v3 * 0.1 + OFFSET_Y_MAX
        self.treesRightTexture:SetVertexUV(VERTEX_POINTS_TOPRIGHT, u, v)
        self.treesRightSilhouetteTexture:SetVertexUV(VERTEX_POINTS_TOPRIGHT, u, v)
    end
end

-- Class-Specific Methods

function ZO_PeninsulaBackground:InitializeControlPools()
    self.leafTexturePool = ZO_ControlPool:New("ZO_PeninsulaBackgroundLeaf", self.control, "BackgroundLeaf")
    self.leafTexturePool:SetCustomAcquireBehavior(ZO_GetCallbackForwardingFunction(self, self.OnLeafTextureAcquired))
    self.leafTexturePool:SetCustomFactoryBehavior(ZO_GetCallbackForwardingFunction(self, self.OnLeafTextureCreated))
end

function ZO_PeninsulaBackground:InitializeMovementControllers()
    local function CreateMovementController(direction)
        local movementController = ZO_MovementController:New(direction)
        movementController:SetAccelerationMagnitudeFactor(3)
        movementController:SetAllowAcceleration(true)
        movementController:SetNumTicksToStartAccelerating(1)
        return movementController
    end

    self.movementControllers =
    {
        [MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL] = CreateMovementController(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL),
        [MOVEMENT_CONTROLLER_DIRECTION_VERTICAL] = CreateMovementController(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL),
    }
end

function ZO_PeninsulaBackground:GetAudioWindIntensityAndDirection()
    return self.audioWindIntensity, self.audioWindDirectionX, self.audioWindDirectionY
end

function ZO_PeninsulaBackground:GetEffectiveWindVector()
    return self.windVectorX, self.windVectorY
end

function ZO_PeninsulaBackground:GetMovementControllerVector()
    return self.movementControllerVectorX, self.movementControllerVectorY
end

function ZO_PeninsulaBackground:GetPreviousWindVelocity()
    return self.previousWindVelocityX, self.previousWindVelocityY
end

function ZO_PeninsulaBackground:GetWindVelocity()
    return self.windVelocityX, self.windVelocityY
end

function ZO_PeninsulaBackground:GetWindVelocityTransitionInterval()
    local frameTimeS = GetFrameTimeSeconds()
    local transitionIntervalElapsedS = frameTimeS - self.lastWindVelocityChangeTimeS
    local normalizedTransitionIntervalElapsed = transitionIntervalElapsedS > 0 and (transitionIntervalElapsedS / self.windVelocityTransitionIntervalS) or 0
    return normalizedTransitionIntervalElapsed
end

function ZO_PeninsulaBackground:OnLeafTextureAcquired(control, key)
    control.key = key

    -- Choose a leaf spawner randomly.
    local leafSpawner = LEAF_SPAWNERS:GetRandomValue()

    -- Initial position.
    local startX, startY, scaleFactor = leafSpawner.positionRanges:GetRandomVector()
    control.positionX, control.positionY = startX, startY
    control:ClearAnchors()
    control.anchorPoint = leafSpawner.anchorPoint
    control.anchorToControl = LEAF_ANCHOR_CONTROL_REFS[leafSpawner.anchorTo]
    control:SetAnchor(control.anchorPoint, control.anchorToControl, control.anchorPoint, self:GetScaledAnchorOffsets(startX, startY))

    -- Draw level.
    control:SetDrawLevel(leafSpawner.drawLevel)

    -- Color and scale.
    local scale = zo_lerp(ZO_BACKGROUND_LEAF_SCALE_MIN, ZO_BACKGROUND_LEAF_SCALE_MAX, scaleFactor)
    control:SetScale(scale)
    control:SetColor(leafSpawner.colorRanges:GetRandomProportionalColor())
    control.windFactor = zo_lerp(0.5, 1, zo_random())

    -- Forward vector.
    control.forwardX, control.forwardY = leafSpawner.forwardVectorRange:GetRandomVector()

    -- Rotation angle.
    local forwardRotationAngleCoefficient = leafSpawner.forwardRotationAngleCoefficient
    control.startForwardRotationAngle = zo_lerp(ZO_BACKGROUND_LEAF_FORWARD_ROTATION_ANGLE_MIN, ZO_BACKGROUND_LEAF_FORWARD_ROTATION_ANGLE_MAX, zo_random()) * forwardRotationAngleCoefficient
    control.endForwardRotationAngle = -zo_sign(control.startForwardRotationAngle) * ZO_BACKGROUND_LEAF_FORWARD_ROTATION_ANGLE_MAX * zo_random() * forwardRotationAngleCoefficient

    -- Rotation velocity.
    control.rotationVelocityY = zo_lerp(ZO_BACKGROUND_LEAF_ROTATION_VELOCITY_MIN, ZO_BACKGROUND_LEAF_ROTATION_VELOCITY_MAX, zo_random()) * forwardRotationAngleCoefficient
    control.rotationVelocityZ = zo_lerp(ZO_BACKGROUND_LEAF_ROTATION_VELOCITY_MIN, ZO_BACKGROUND_LEAF_ROTATION_VELOCITY_MAX, zo_random()) * forwardRotationAngleCoefficient
    control.rotationY = ZO_TWO_PI * zo_random() * forwardRotationAngleCoefficient
    control.rotationZ = ZO_TWO_PI * zo_random() * forwardRotationAngleCoefficient
end

function ZO_PeninsulaBackground:OnLeafTextureCreated(control, key, controlPool)
    -- Apply the current screen scale to the new leaf control.
    self:UpdateTextureControlLayout(control)
end

function ZO_PeninsulaBackground:OnTopLevelMouseDown(control, button, ctrl, alt, shift)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        -- Start wind velocity override.
        self.mouseDownX, self.mouseDownY = WINDOW_MANAGER:GetUIMousePosition()
    end
end

function ZO_PeninsulaBackground:OnTopLevelMouseUp(control, button, upInside, ctrl, alt, shift)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        -- Stop wind velocity override.
        self.mouseDownX, self.mouseDownY = nil, nil
        -- Force the generation of a new wind velocity.
        self:UpdateWindVelocity(FORCE_WIND_VELOCITY_UPDATE)
    end
end

function ZO_PeninsulaBackground:OnTitleFadeInPlay(animation, completed)
    self.introTitleProgress = 0

    -- Initialize Title.
    local START_PROGRESS = 0
    self:OnTitleFadeInUpdate(animation, START_PROGRESS)
    self.titleTexture:SetShaderEffectType(SHADER_EFFECT_TYPE_RADIAL_BLUR)
    self.titleTexture:SetAlpha(0)
    self.titleTexture:SetHidden(false)

    if not completed then
        -- Initialize Ouroboros Glow flicker.
        OUROBOROS_GLOW_COLOR:SetAlpha(0)
        FLICKER_EFFECT:RegisterControl(self.ouroborosGlowTexture, ZO_BACKGROUND_OUROBOROS_GLOW_FLICKER_SPEED, ZO_BACKGROUND_OUROBOROS_GLOW_FLICKER_ALPHA_STRENGTH, ZO_BACKGROUND_OUROBOROS_GLOW_FLICKER_COLOR_STRENGTH, ZO_BACKGROUND_OUROBOROS_GLOW_BLUR_FACTOR_MAX, OUROBOROS_GLOW_COLOR)
        self.ouroborosGlowTexture:SetHidden(false)
    end
end

function ZO_PeninsulaBackground:OnTitleFadeInStop(animation, completed)
    self.titleTexture:SetShaderEffectType(SHADER_EFFECT_TYPE_NONE)
end

function ZO_PeninsulaBackground:OnTitleFadeInUpdate(animation, progress)
    local easedProgress = ZO_EaseInQuadratic(progress)
    self.introTitleProgress = easedProgress

    local controlProgress = zo_max(0, easedProgress * 1.5 - 0.5)
    -- Title blur in.
    local blurOriginX, blurOriginY, numSamples, blurRadius, offsetRadius = self.titleTexture:GetRadialBlur()
    blurRadius = zo_lerp(0.3, 0, ZO_EaseOutQuadratic(zo_clamp(controlProgress, 0, 1)))
    self.titleTexture:SetRadialBlur(blurOriginX, blurOriginY, numSamples, blurRadius, offsetRadius)
    -- Title fade in.
    local alpha = ZO_EaseOutQuadratic(controlProgress)
    self.titleTexture:SetAlpha(alpha)
end

function ZO_PeninsulaBackground:OnSunRaysFadeInPlay(animation, completed)
    self.introSunRaysProgress = 0
    self.sunRaysTexture:SetHidden(false)

    if not completed then
        -- Initialize Ouroboros.
        self.ouroborosTexture:SetColor(0, 0, 0, 0)
        self.ouroborosTexture:SetHidden(false)

        -- Initialize Sun Rays.
        self.sunRaysTexture:SetVertexColors(VERTEX_POINTS_BOTTOMLEFT + VERTEX_POINTS_BOTTOMRIGHT, 1, 1, 1, 0)
        self.sunRaysTexture:SetVertexColors(VERTEX_POINTS_TOPLEFT + VERTEX_POINTS_TOPRIGHT, 1, 1, 1, 0)
    end
end

function ZO_PeninsulaBackground:OnSunRaysFadeInUpdate(animation, progress)
    self.introSunRaysProgress = progress

    do
        -- Slight scaling in of the Ouroboros.
        local easedProgress = ZO_EaseOutCubic(progress)
        local scale = zo_lerp(0.8, 1, easedProgress)
        local ANGLE = 0
        local ORIGIN_X, ORIGIN_Y = 0.5, 0.5
        ZO_ScaleAndRotateTextureCoords(self.ouroborosTexture, ANGLE, ORIGIN_X, ORIGIN_Y, scale, scale)
    end

    do
        -- Fade in Ouroboros with darker shading initially for higher contrast
        -- during the initial sun ray burst.
        local easedProgress = ZO_EaseInQuartic(progress)
        local color = easedProgress * 0.65 + 0.35
        local alpha = easedProgress
        self.ouroborosTexture:SetColor(color, color, color, alpha)
    end

    do
        -- Ouroboros glow fade in and/or flicker setting sync for the dev tool.
        -- Note that the fade in interval's overflow time interval is to ensure
        -- that the max alpha is ultimately applied to the flicker effect.
        local easedProgress = ZO_EaseInQuartic(progress)
        OUROBOROS_GLOW_COLOR:SetAlpha(easedProgress)
        FLICKER_EFFECT:RegisterControl(self.ouroborosGlowTexture, ZO_BACKGROUND_OUROBOROS_GLOW_FLICKER_SPEED, ZO_BACKGROUND_OUROBOROS_GLOW_FLICKER_ALPHA_STRENGTH, ZO_BACKGROUND_OUROBOROS_GLOW_FLICKER_COLOR_STRENGTH, ZO_BACKGROUND_OUROBOROS_GLOW_BLUR_FACTOR_MAX, OUROBOROS_GLOW_COLOR)
    end

    do
        -- Fade in sun rays.
        local sunRaysAlpha
        if progress <= 0.5 then
            sunRaysAlpha = ZO_EaseInQuadratic(2 * progress)
        else
            sunRaysAlpha = zo_lerp(1, 0.4, ZO_EaseInQuadratic(2 * (progress - 0.5)))
        end

        self.sunRaysTexture:SetVertexColors(VERTEX_POINTS_BOTTOMLEFT + VERTEX_POINTS_BOTTOMRIGHT, 1, 1, 1, sunRaysAlpha)
        self.sunRaysTexture:SetVertexColors(VERTEX_POINTS_TOPLEFT + VERTEX_POINTS_TOPRIGHT, 1, 1, 1, sunRaysAlpha)
    end
end

function ZO_PeninsulaBackground:ResetAnimationState()
    DIRECTIONAL_INPUT:Deactivate(self)

    self.titleFadeInTimeline:Stop()
    self.sunRaysFadeInTimeline:Stop()

    FLICKER_EFFECT:UnregisterControl(self.ouroborosGlowTexture)

    self.ouroborosGlowTexture:SetAlpha(0)
    self.ouroborosTexture:SetColor(0, 0, 0, 0)
    self.sunRaysTexture:SetVertexColors(VERTEX_POINTS_BOTTOMLEFT + VERTEX_POINTS_BOTTOMRIGHT, 1, 1, 1, 0)
    self.sunRaysTexture:SetVertexColors(VERTEX_POINTS_TOPLEFT + VERTEX_POINTS_TOPRIGHT, 1, 1, 1, 0)
    self.titleTexture:SetAlpha(0)

    self.ouroborosTexture:SetHidden(true)
    self.ouroborosGlowTexture:SetHidden(true)
    self.sunRaysTexture:SetHidden(true)
    self.titleTexture:SetHidden(true)

    self.audioWindDirectionX, self.audioWindDirectionY = 0, 0
    self.audioWindIntensity = 0
    self.interactionCoefficient = 0
    self.introTitleProgress = 0
    self.introSunRaysProgress = 0
    self.lastControllerMovementTimeS = nil
    self.lastWindVelocityChangeTimeS = 0
    self.mouseDownEndTimeS = nil
    self.mouseDownStartTimeS = nil
    self.mouseDownX, self.mouseDownY = nil, nil
    self.movementControllerVectorX, self.movementControllerVectorY = 0, 0
    self.nextLeafSpawnTimeS = 0
    self.nextWindVelocityUpdateS = 0
    self.ouroborosGlowStrength = 1
    self.previousWindVelocityX, self.previousWindVelocityY = 0, 0
    self.treeWaveOffset = 0
    self.treeWaveSpeedCoefficient = ZO_BACKGROUND_TREES_WAVE_SPEED_COEFFICIENT_BASE
    self.windMagnitude = 0
    self.windVelocityTransitionIntervalS = 0
    self.windVectorX, self.windVectorY = 0, 0
    self.windVelocityX, self.windVelocityY = 0, 0

    self.leafTexturePool:ReleaseAllObjects()
end

function ZO_PeninsulaBackground:SetWindVelocity(magnitude, x, y, overrideTransitionIntervalS)
    local frameTimeS = GetFrameTimeSeconds()
    local transitionIntervalElapsedS = frameTimeS - self.lastWindVelocityChangeTimeS
    if transitionIntervalElapsedS < self.windVelocityTransitionIntervalS then
        if not overrideTransitionIntervalS then
            -- The previous transition did not complete; interpolate the new "previous"
            -- wind velocity between the current the current and previous velocities.
            local normalizedTransitionIntervalElapsed = ZO_EaseOutQuadratic(transitionIntervalElapsedS / self.windVelocityTransitionIntervalS)
            self.previousWindVelocityX = zo_lerp(self.previousWindVelocityX, self.windVelocityX, normalizedTransitionIntervalElapsed)
            self.previousWindVelocityY = zo_lerp(self.previousWindVelocityY, self.windVelocityY, normalizedTransitionIntervalElapsed)
        end
    else
        -- Transfer the current wind velocity to the previous wind velocity.
        self.previousWindVelocityX, self.previousWindVelocityY = self.windVelocityX, self.windVelocityY
        self.lastWindVelocityChangeTimeS = frameTimeS
    end

    self.windMagnitude = magnitude
    self.windVelocityTransitionIntervalS = overrideTransitionIntervalS or ZO_BACKGROUND_WIND_TRANSITION_INTERVAL_SECONDS
    self.windVelocityX, self.windVelocityY = x, y
    self.nextWindVelocityUpdateS = frameTimeS + zo_random(ZO_BACKGROUND_WIND_UPDATE_INTERVAL_MIN_SECONDS, ZO_BACKGROUND_WIND_UPDATE_INTERVAL_MAX_SECONDS, zo_random())
end

function ZO_PeninsulaBackground:SpawnLeaf(frameTimeS)
    local nextSpawnTimeS = self.nextLeafSpawnTimeS or 0
    if nextSpawnTimeS <= frameTimeS then
        if self.leafTexturePool:GetActiveObjectCount() < ZO_BACKGROUND_LEAF_INSTANCES_MAX then
            -- Spawn a new leaf.
            local leafControl = self.leafTexturePool:AcquireObject()
            leafControl.startTimeS = frameTimeS
        end

        -- Queue the next leaf spawn.
        local intervalCoefficient = (self.mouseDownX or self.movementControllerVectorX ~= 0 or self.movementControllerVectorY ~= 0) and 0.35 or 1
        self.nextLeafSpawnTimeS = frameTimeS + (intervalCoefficient * zo_lerp(ZO_BACKGROUND_LEAF_SPAWN_INTERVAL_MIN_SECONDS, ZO_BACKGROUND_LEAF_SPAWN_INTERVAL_MAX_SECONDS, zo_random()))
    end
end

function ZO_PeninsulaBackground:UpdateDirectionalInput()
    local frameTimeS = GetFrameTimeSeconds()
    local hasMovement = false

    -- Interpolate toward -1 or 1 when the left stick is moved left or right respectively;
    -- otherwise interpolate toward 0, at a slower rate, when disengaged.
    local horizontalMovement = self.movementControllers[MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL]:CheckMovement()
    if horizontalMovement == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        hasMovement = true
        self.movementControllerVectorX = zo_clamp(self.movementControllerVectorX - 0.1, -1, 1)
    elseif horizontalMovement == MOVEMENT_CONTROLLER_MOVE_NEXT then
        hasMovement = true
        self.movementControllerVectorX = zo_clamp(self.movementControllerVectorX + 0.1, -1, 1)
    else
        self.movementControllerVectorX = zo_lerp(self.movementControllerVectorX, 0, 0.01)
    end

    -- Interpolate toward -1 or 1 when the left stick is moved up or down respectively;
    -- otherwise interpolate toward 0, at a slower rate, when disengaged.
    local verticalMovement = self.movementControllers[MOVEMENT_CONTROLLER_DIRECTION_VERTICAL]:CheckMovement()
    if verticalMovement == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        hasMovement = true
        self.movementControllerVectorY = zo_clamp(self.movementControllerVectorY - 0.1, -1, 1)
    elseif verticalMovement == MOVEMENT_CONTROLLER_MOVE_NEXT then
        hasMovement = true
        self.movementControllerVectorY = zo_clamp(self.movementControllerVectorY + 0.1, -1, 1)
    else
        self.movementControllerVectorY = zo_lerp(self.movementControllerVectorY, 0, 0.01)
    end

    if hasMovement then
        -- Track the last time that left stick movement was detected.
        self.lastControllerMovementTimeS = frameTimeS
    elseif self.lastControllerMovementTimeS then
        -- The left stick was, but is no longer, engaged.
        if frameTimeS - self.lastControllerMovementTimeS >= 0.5 then
            -- The left stick has remained idle; force the generation
            -- of a new wind velocity and vector.
            self.lastControllerMovementTimeS = nil
            self.movementControllerVectorX, self.movementControllerVectorY = 0, 0
            self:UpdateWindVelocity(FORCE_WIND_VELOCITY_UPDATE)
        end
    end
end

function ZO_PeninsulaBackground:UpdateLeafAnimations(frameTimeS)
    local frameDeltaS = GetFrameDeltaSeconds()
    local guiWidth, guiHeight = GuiRoot:GetDimensions()
    local minX, minY = -guiWidth, -guiHeight
    local maxX, maxY = guiWidth * 2, guiHeight

    -- Update wind velocity and calculate the wind vector for this frame.
    self:UpdateWindVelocity()
    self:UpdateWindVector()
    local windVectorX, windVectorY = self.windVectorX * frameDeltaS, self.windVectorY * frameDeltaS
    local normalizedWindVelocity = zo_distance(0, 0, self.windVectorX, self.windVectorY) / ZO_BACKGROUND_WIND_MOUSE_VELOCITY_COEFFICIENT
    local normalizedWindCoefficient = 1 + normalizedWindVelocity
    
    -- Spawn new leaf particles; then update all leaf particle animations.
    self:SpawnLeaf(frameTimeS)

    local maxBrightness = ZO_BACKGROUND_LEAF_BRIGHTNESS_MAX
    local minBrightness = ZO_BACKGROUND_LEAF_BRIGHTNESS_MIN
    local gravityX, gravityY = ZO_BACKGROUND_LEAF_GRAVITY_VECTOR_X, ZO_BACKGROUND_LEAF_GRAVITY_VECTOR_Y
    local minForwardY = gravityY * -0.5
    local textureReleaseQueue = nil
    for _, control in self.leafTexturePool:ActiveObjectIterator() do
        -- Calculate translated position and determine whether this leaf
        -- has traveled out of bounds.
        local releaseControl = false
        local windFactor = control.windFactor
        local translationX, translationY
        local positionX, positionY
        translationY = (gravityY + (zo_max(minForwardY, control.forwardY) * normalizedWindCoefficient) + (windVectorY * windFactor)) * frameDeltaS
        positionY = control.positionY + translationY
        if positionY > maxY or positionY < minY then
            releaseControl = true
        else
            translationX = (gravityX + (control.forwardX * normalizedWindCoefficient) + (windVectorX * windFactor)) * frameDeltaS
            positionX = control.positionX + translationX
            if positionX > maxX or positionX < minX then
                releaseControl = true
            end
        end

        if releaseControl then
            -- This leaf has moved out of bounds; queue the control
            -- for release from the pool.
            if textureReleaseQueue then
                table.insert(textureReleaseQueue, control)
            else
                textureReleaseQueue = {control}
            end
        else
            -- Apply alpha.
            local lifetimeS = frameTimeS - control.startTimeS
            local lifetimeInterpolant = zo_abs((lifetimeS % 2) - 1)
            local alpha = zo_min(1, lifetimeS * 3)
            control:SetAlpha(alpha)

            -- Move this texture control to its new position.
            control.positionX = zo_clamp(positionX, minX, maxX)
            control.positionY = zo_clamp(positionY, minY, maxY)
            control:SetAnchor(control.anchorPoint, control.anchorToControl, control.anchorPoint, self:GetScaledAnchorOffsets(control.positionX, control.positionY))

            -- Apply forward vector rotation.
            local forwardRotationAngle = zo_lerp(control.startForwardRotationAngle, control.endForwardRotationAngle, lifetimeInterpolant) * frameDeltaS
            control.forwardX, control.forwardY = ZO_Rotate2D(forwardRotationAngle, control.forwardX, control.forwardY)

            -- Apply rotation velocity.
            local progressiveFrameDeltaS = frameDeltaS * (1 - (lifetimeInterpolant * 0.75))
            control.rotationY = control.rotationY + control.rotationVelocityY * progressiveFrameDeltaS
            control.rotationZ = control.rotationZ + control.rotationVelocityZ * progressiveFrameDeltaS
            local NO_ROTATION = 0
            local normalizedScaleX, normalizedScaleY = ZO_RotateTexture3D(control, NO_ROTATION, control.rotationY, control.rotationZ)

            -- Apply lighting.
            local normalizedCameraFacing = ZO_GetNormalizedCameraFacingDirectionFromNormalizedAxisScales(normalizedScaleX, normalizedScaleY)
            ZO_SetTextureLighting(control, normalizedCameraFacing, minBrightness, maxBrightness)
        end
    end

    if textureReleaseQueue then
        for _, control in ipairs(textureReleaseQueue) do
            self.leafTexturePool:ReleaseObject(control.key)
        end
    end
end

function ZO_PeninsulaBackground:UpdateWindVelocity(forceWindVelocityUpdate)
    local frameTimeS = GetFrameTimeSeconds()
    local mouseX1, mouseY1 = self.mouseDownX, self.mouseDownY
    local controllerX, controllerY = self.movementControllerVectorX, self.movementControllerVectorY
    local hasMouseInput = mouseX1 and mouseY1
    local hasControllerInput = controllerX ~= 0 or controllerY ~= 0
    if forceWindVelocityUpdate or (not (hasMouseInput or hasControllerInput) and frameTimeS >= self.nextWindVelocityUpdateS) then
        -- Update the wind velocity vector to point in a random direction with
        -- a magnitude in the configured velocity range.
        local magnitude = ZO_BACKGROUND_WIND_VELOCITY_MAX * zo_random()
        -- Generate wind angles between 70-90 and 270-290 degrees (positive Y-axis
        -- pushes downward)
        local angle = zo_rad(20) * zo_random() + (zo_random() > 0.5 and zo_rad(70) or zo_rad(270))
        local directionX = zo_sin(angle)
        local directionY = zo_cos(angle)
        local velocityX = directionX * magnitude
        local velocityY = directionY * magnitude
        self:SetWindVelocity(magnitude, velocityX, velocityY)
    elseif hasControllerInput then
        -- Override the wind velocity in relation to the magnitude of the
        -- continuous direction of the controller left stick.
        local angle = zo_atan2(controllerX, controllerY)
        local controllerDistance = zo_distance(0, 0, controllerX, controllerY)
        local magnitude = controllerDistance * ZO_BACKGROUND_WIND_MOUSE_VELOCITY_COEFFICIENT
        local velocityX = zo_sin(angle) * magnitude
        local velocityY = zo_cos(angle) * magnitude
        self:SetWindVelocity(magnitude, velocityX, velocityY, -ZO_BACKGROUND_WIND_VELOCITY_OVERRIDE_TRANSITION_INTERVAL_SECONDS)
    elseif hasMouseInput then
        -- Override the wind velocity in relation to the distance that the mouse
        -- has traveled since the button was first pressed.
        local mouseX2, mouseY2 = WINDOW_MANAGER:GetUIMousePosition()
        local directionX, directionY = mouseX2 - mouseX1, mouseY2 - mouseY1
        if directionX ~= 0 or directionY ~= 0 then
            local angle = zo_atan2(directionX, directionY)
            local cursorDistance = zo_distance(mouseX1, mouseY1, mouseX2, mouseY2)
            local magnitude = zo_clamp(cursorDistance / 150, 0, 1) * ZO_BACKGROUND_WIND_MOUSE_VELOCITY_COEFFICIENT
            local velocityX = zo_sin(angle) * magnitude
            local velocityY = zo_cos(angle) * magnitude
            self:SetWindVelocity(magnitude, velocityX, velocityY, -ZO_BACKGROUND_WIND_VELOCITY_OVERRIDE_TRANSITION_INTERVAL_SECONDS)
        end
    end
end

function ZO_PeninsulaBackground:UpdateWindVector()
    -- Interpolate between the previous wind velocity and the current wind velocity
    -- relative to the time elapsed since the last wind velocity change.
    local frameTimeS = GetFrameTimeSeconds()
    local transitionIntervalElapsedS = frameTimeS - self.lastWindVelocityChangeTimeS
    local normalizedTransitionIntervalElapsed = ZO_EaseOutQuintic(zo_clamp(transitionIntervalElapsedS / self.windVelocityTransitionIntervalS, 0, 0.9))
    self.windVectorX = zo_lerp(self.previousWindVelocityX, self.windVelocityX, normalizedTransitionIntervalElapsed)
    self.windVectorY = zo_lerp(self.previousWindVelocityY, self.windVelocityY, normalizedTransitionIntervalElapsed)
end