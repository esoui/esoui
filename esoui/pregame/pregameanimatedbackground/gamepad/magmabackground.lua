local ZO_FOUR_PI = ZO_TWO_PI * 2.0

ZO_BACKGROUND_TEXTURE_FILE_HEIGHT = 2048
ZO_BACKGROUND_TEXTURE_FILE_WIDTH = 2048

ZO_BACKGROUND_TEXTURE_IMAGE_HEIGHT = 1080
ZO_BACKGROUND_TEXTURE_IMAGE_WIDTH = 1920
ZO_BACKGROUND_TEXTURE_IMAGE_ASPECT_RATIO = ZO_BACKGROUND_TEXTURE_IMAGE_WIDTH / ZO_BACKGROUND_TEXTURE_IMAGE_HEIGHT

ZO_BACKGROUND_TEXTURE_COORD_BOTTOM = ZO_BACKGROUND_TEXTURE_IMAGE_HEIGHT / ZO_BACKGROUND_TEXTURE_FILE_HEIGHT
ZO_BACKGROUND_TEXTURE_COORD_RIGHT = ZO_BACKGROUND_TEXTURE_IMAGE_WIDTH / ZO_BACKGROUND_TEXTURE_FILE_WIDTH

ZO_BACKGROUND_NUM_FOREGROUND_TEXTURES = 8
ZO_BACKGROUND_FOREGROUND_TEXTURE_INDICES =
{
    PURPLE_FLOWERS_1 = 5,
    YELLOW_MUSHROOMS_1 = 8,
}

ZO_BACKGROUND_DAY_SCENE_INDEX = 2
ZO_BACKGROUND_NIGHT_SCENE_INDEX = 1

-- Parameters

-- Scene Time
-- 24 hour clock time units
ZO_BACKGROUND_DAY_START_TIME_HOURS = 6.0
ZO_BACKGROUND_NIGHT_START_TIME_HOURS = 18.0
ZO_BACKGROUND_DAY_END_TIME_HOURS = (ZO_BACKGROUND_NIGHT_START_TIME_HOURS + 2.0) % 24.0
ZO_BACKGROUND_NIGHT_END_TIME_HOURS = (ZO_BACKGROUND_DAY_START_TIME_HOURS + 2.0) % 24.0
ZO_BACKGROUND_SCENE_TIME_HOURS_PER_SECOND = 0.03

-- Intro

-- 24 hour clock time units
ZO_BACKGROUND_INTRO_START_TIME_HOURS = 10
ZO_BACKGROUND_INTRO_SCENE_TIME_HOURS_PER_SECOND = 3
ZO_BACKGROUND_INTRO_SCENE_TIME_INTERVAL_SECONDS = 5

-- Grass

ZO_BACKGROUND_GRASS_WAVE_BOUND_X_MIN = 0.0009
ZO_BACKGROUND_GRASS_WAVE_BOUND_X_MAX = 0.0009
ZO_BACKGROUND_GRASS_WAVE_BOUND_Y_MIN = 0.0003
ZO_BACKGROUND_GRASS_WAVE_BOUND_Y_MAX = 0.0
ZO_BACKGROUND_GRASS_WAVE_ANGLE_RADIANS = 0.0
ZO_BACKGROUND_GRASS_WAVE_FREQUENCY = 4.8
ZO_BACKGROUND_GRASS_WAVE_SPEED = 16.0
ZO_BACKGROUND_GRASS_WAVE_TIME_COEFFICIENT = 0.25

ZO_BACKGROUND_FLORA_WAVE_INTERVAL_COEFFICIENT = 1.0

-- Dandelion / Allergens

ZO_BACKGROUND_DANDELION_HEIGHT = 28
ZO_BACKGROUND_DANDELION_WIDTH = 28

ZO_BACKGROUND_DANDELION_INSTANCES_MAX = 5

ZO_BACKGROUND_DANDELION_LIFETIME_SECONDS_MAX = 9
ZO_BACKGROUND_DANDELION_LIFETIME_SECONDS_MIN = 6

ZO_BACKGROUND_DANDELION_SCALE_MAX = 1.0
ZO_BACKGROUND_DANDELION_SCALE_MIN = 0.5

ZO_BACKGROUND_DANDELION_SPAWN_INTERVAL_SECONDS = 0.65

-- Ouroboros

ZO_BACKGROUND_OUROBOROS_ACTIVE_INTERVAL_SECONDS = 8
ZO_BACKGROUND_OUROBOROS_INACTIVE_INTERVAL_SECONDS = 96
ZO_BACKGROUND_OUROBOROS_MASK_THRESHOLD_MIN = 0.9
ZO_BACKGROUND_OUROBOROS_NORMALIZED_ORIGINS =
{
    { centerOffsetX = -0.19, centerOffsetY = 0.15, radiusX = 0.01, radiusY = 0.01, soundFxId = 1 },
    { centerOffsetX = 0, centerOffsetY = 0.15, radiusX = 0.03, radiusY = 0.03, soundFxId = 3 },
    { centerOffsetX = 0.4, centerOffsetY = 0.12, radiusX = 0.04, radiusY = 0.07, soundFxId = 2 },
}

-- Sky

ZO_BACKGROUND_GOD_RAY_NORMALIZED_LENGTH = 0.3
ZO_BACKGROUND_SKY_ALPHA_MAX = 0.5
ZO_BACKGROUND_SUN_ANGLE_OFFSET_RADIANS = math.rad(315)
ZO_BACKGROUND_SUN_ORIGIN_X = 0.5
ZO_BACKGROUND_SUN_ORIGIN_Y = 0.0
ZO_BACKGROUND_SUN_RADIAL_BLUR_NUM_SAMPLES = 20
ZO_BACKGROUND_SUN_RADIAL_BLUR_OFFSET = 0.0
ZO_BACKGROUND_SUN_RADIUS_AZIMUTH = 2.0
ZO_BACKGROUND_SUN_RADIUS_ZENITH = 1.0

-- Title

ZO_BACKGROUND_TITLE_ANIMATION_DELAY_SECONDS = 1.0
ZO_BACKGROUND_TITLE_ANIMATION_DURATION_SECONDS = 3.0
ZO_BACKGROUND_TITLE_BLUR_KERNEL_SIZE = 7

-- Torchbug

ZO_BACKGROUND_TORCHBUG_INSTANCES_MAX = 24

ZO_BACKGROUND_TORCHBUG_LIFETIME_SECONDS_MAX = 2
ZO_BACKGROUND_TORCHBUG_LIFETIME_SECONDS_MIN = 1.5

ZO_BACKGROUND_TORCHBUG_OFFSET_UV_MAX = 0.075

ZO_BACKGROUND_TORCHBUG_ORIGIN_X = 0.55
ZO_BACKGROUND_TORCHBUG_ORIGIN_Y = 0.5

ZO_BACKGROUND_TORCHBUG_ORIGIN_ANGLE_MAX = math.rad(45)
ZO_BACKGROUND_TORCHBUG_ORIGIN_ANGLE_MIN = math.rad(315)

ZO_BACKGROUND_TORCHBUG_ORIGIN_DISTANCE_X_MAX = 0.4
ZO_BACKGROUND_TORCHBUG_ORIGIN_DISTANCE_X_MIN = 0.2

ZO_BACKGROUND_TORCHBUG_ORIGIN_DISTANCE_Y_MAX = 0.4
ZO_BACKGROUND_TORCHBUG_ORIGIN_DISTANCE_Y_MIN = 0.25

ZO_BACKGROUND_TORCHBUG_PULSE_COEFFICIENT = 2

ZO_BACKGROUND_TORCHBUG_SAMPLING_MAX = 2
ZO_BACKGROUND_TORCHBUG_SAMPLING_MIN = 1

ZO_BACKGROUND_TORCHBUG_SCALE_MAX = 1.75
ZO_BACKGROUND_TORCHBUG_SCALE_MIN = 0.65

ZO_BACKGROUND_TORCHBUG_SPAWN_INTERVAL_SECONDS = 0.1

-- Shader Effects

ZO_BACKGROUND_ENABLE_SHADER_EFFECT_GAUSSIAN_BLUR = true
ZO_BACKGROUND_ENABLE_SHADER_EFFECT_RADIAL_BLUR = true
ZO_BACKGROUND_ENABLE_SHADER_EFFECT_WAVE = true

-- Background Animation Scene

local MagmaBackground = ZO_InitializingObject:Subclass()

function MagmaBackground:Initialize(control)
    self.control = control
    control.owner = self

    self:InitializeControls()
    self:UpdateLayout()

    PREGAME_ANIMATED_BACKGROUND_FRAGMENT = ZO_SimpleSceneFragment:New(control)
    PREGAME_ANIMATED_BACKGROUND_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:Start()
        elseif newState == SCENE_HIDDEN then
            self:Stop()
        end
    end)

    control:RegisterForEvent(EVENT_SCREEN_RESIZED, function()
        self:OnScreenResized()
    end)

    control:SetHandler("OnUpdate", function()
        if self.isLayoutDirty then
            self:UpdateLayout()
        end
    end, "UpdateLayout")
end

function MagmaBackground:InitializeControls()
    local control = self.control
    self.fullscreenTextureControls = {}
    self.standardTextureControls = {}
    self.sceneControls = {}

    local sceneNames = {"NightScene", "DayScene"}
    for sceneIndex, sceneName in ipairs(sceneNames) do
        local sceneControl = control:GetNamedChild(sceneName)
        self.sceneControls[sceneIndex] = sceneControl
        sceneControl.terrainTexture = sceneControl:GetNamedChild("Terrain")
        sceneControl.grassTexture = sceneControl:GetNamedChild("Grass")

        sceneControl.foregroundTextures = {}
        for foregroundIndex = 1, ZO_BACKGROUND_NUM_FOREGROUND_TEXTURES do
            sceneControl.foregroundTextures[foregroundIndex] = sceneControl:GetNamedChild(string.format("Foreground%u", foregroundIndex))
        end

        sceneControl.ouroboros1Texture = sceneControl:GetNamedChild("Ouroboros1")
        sceneControl.ouroboros2Texture = sceneControl:GetNamedChild("Ouroboros2")
        sceneControl.ouroborosInnerTexture = sceneControl:GetNamedChild("OuroborosInner")

        sceneControl.skyTexture = sceneControl:GetNamedChild("Sky")
        if sceneControl.skyTexture then
            sceneControl.skyTexture.preferredAnchor = ZO_Anchor:New(BOTTOM, GuiRoot, CENTER, 0, -28)
        end
        table.insert(self.standardTextureControls, sceneControl.skyTexture)

        table.insert(self.fullscreenTextureControls, sceneControl.terrainTexture)
        table.insert(self.fullscreenTextureControls, sceneControl.grassTexture)

        for foregroundTextureIndex, foregroundTexture in ipairs(sceneControl.foregroundTextures) do
            table.insert(self.fullscreenTextureControls, foregroundTexture)
        end

        table.insert(self.fullscreenTextureControls, sceneControl.ouroboros1Texture)
        table.insert(self.fullscreenTextureControls, sceneControl.ouroboros2Texture)
    end

    self.titleDayTexture = control:GetNamedChild("TitleDay")
    self.titleDayTexture.preferredAnchor = ZO_Anchor:New(CENTER, GuiRoot, CENTER, 0, -300)
    table.insert(self.standardTextureControls, self.titleDayTexture)

    self.titleNightTexture = control:GetNamedChild("TitleNight")
    self.titleNightTexture.preferredAnchor = ZO_Anchor:New(CENTER, GuiRoot, CENTER, 0, -300)
    table.insert(self.standardTextureControls, self.titleNightTexture)

    self.dandelionPool = ZO_ControlPool:New("ZO_MagmaBackgroundDandelion", control, "MagmaDandelion")
    self.torchbug1Pool = ZO_ControlPool:New("ZO_MagmaBackgroundTorchbug1", control, "MagmaTorchbug1_")
    self.torchbug2Pool = ZO_ControlPool:New("ZO_MagmaBackgroundTorchbug2", control, "MagmaTorchbug2_")
    self.torchbugPools = {self.torchbug1Pool, self.torchbug2Pool}

    self.introTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_MagmaBackgroundAnimation_Intro", control)
    self.introTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)

    self.particleLoopTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_MagmaBackgroundAnimation_ParticleLoop", control)
    self.particleLoopTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)

    self.floraLoopTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_MagmaBackgroundAnimation_FloraLoop", control)
    self.floraLoopTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)

    self.sceneTimeLoopTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_MagmaBackgroundAnimation_SceneTimeLoop", control)
    self.sceneTimeLoopTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)
end

function MagmaBackground:GetFullScreenDimensions()
    local screenWidth, screenHeight = GuiRoot:GetDimensions()
    local screenAspectRatio = screenWidth / screenHeight
    local fullScreenWidth, fullScreenHeight
    local heightScale, widthScale = 1, 1

    if screenAspectRatio < ZO_BACKGROUND_TEXTURE_IMAGE_ASPECT_RATIO then
        widthScale = screenHeight / ZO_BACKGROUND_TEXTURE_IMAGE_HEIGHT 
        fullScreenWidth, fullScreenHeight = ZO_BACKGROUND_TEXTURE_IMAGE_WIDTH * widthScale, screenHeight
    else
        heightScale = screenWidth / ZO_BACKGROUND_TEXTURE_IMAGE_WIDTH
        fullScreenWidth, fullScreenHeight = screenWidth, ZO_BACKGROUND_TEXTURE_IMAGE_HEIGHT * heightScale
    end

    return fullScreenWidth, fullScreenHeight, widthScale, heightScale
end

function MagmaBackground:InitializeParticleStates()
    self.dandelionAlphaCoefficient = 1.0
    self.torchbugAlphaCoefficient = 1.0

    self.dandelionPool:ReleaseAllObjects()
    self.nextDandelionTimeSeconds = 1.0

    self.torchbug1Pool:ReleaseAllObjects()
    self.torchbug2Pool:ReleaseAllObjects()
    self.nextTorchbugTimeSeconds = 1.0
end

function MagmaBackground:InitializeSceneStates()
    self.sceneTimeHours = ZO_BACKGROUND_INTRO_START_TIME_HOURS % 24.0
    self.introProgress = 0
    self.sunAltitude = 0.0
    self.sunAzimuth = 0.0

    local radialBlurShaderEffectType = ZO_BACKGROUND_ENABLE_SHADER_EFFECT_RADIAL_BLUR and SHADER_EFFECT_TYPE_RADIAL_BLUR or SHADER_EFFECT_TYPE_NONE
    local waveShaderEffectType = ZO_BACKGROUND_ENABLE_SHADER_EFFECT_WAVE and SHADER_EFFECT_TYPE_WAVE or SHADER_EFFECT_TYPE_NONE

    for _, sceneControl in ipairs(self.sceneControls) do
        sceneControl.sceneAlpha = 0
        sceneControl.terrainTexture:SetAlpha(0)

        sceneControl.grassTexture:SetAlpha(0)
        sceneControl.grassTexture:SetShaderEffectType(waveShaderEffectType)
        sceneControl.grassTexture:SetWaveBounds(ZO_BACKGROUND_GRASS_WAVE_BOUND_X_MIN, ZO_BACKGROUND_GRASS_WAVE_BOUND_X_MAX, ZO_BACKGROUND_GRASS_WAVE_BOUND_Y_MIN, ZO_BACKGROUND_GRASS_WAVE_BOUND_Y_MAX)
        sceneControl.grassTexture:SetWave(ZO_BACKGROUND_GRASS_WAVE_ANGLE_RADIANS, ZO_BACKGROUND_GRASS_WAVE_FREQUENCY, ZO_BACKGROUND_GRASS_WAVE_SPEED, 0)

        sceneControl.ouroboros1Texture:SetAlpha(0)
        sceneControl.ouroboros2Texture:SetAlpha(0)

        local foregroundTextureControls = sceneControl.foregroundTextures
        for _, foregroundTexture in ipairs(foregroundTextureControls) do
            foregroundTexture:SetAlpha(0)
        end

        for _, index in pairs(ZO_BACKGROUND_FOREGROUND_TEXTURE_INDICES) do
            foregroundTextureControls[index]:SetShaderEffectType(waveShaderEffectType)
        end

        if sceneControl.ouroborosInnerTexture then
            sceneControl.ouroborosInnerTexture:SetHidden(true)
        end

        if sceneControl.skyTexture then
            sceneControl.skyTexture:SetAlpha(0)
            sceneControl.skyTexture:SetShaderEffectType(radialBlurShaderEffectType)
        end
    end

    do
        local sceneControl = self.sceneControls[ZO_BACKGROUND_NIGHT_SCENE_INDEX]
        sceneControl.startHours = ZO_BACKGROUND_NIGHT_START_TIME_HOURS
        sceneControl.endHours = ZO_BACKGROUND_NIGHT_END_TIME_HOURS
    end

    do
        local sceneControl = self.sceneControls[ZO_BACKGROUND_DAY_SCENE_INDEX]
        sceneControl.startHours = ZO_BACKGROUND_DAY_START_TIME_HOURS
        sceneControl.endHours = ZO_BACKGROUND_DAY_END_TIME_HOURS
    end

    self.titleDayTexture:SetAlpha(0)
    self.titleNightTexture:SetAlpha(0)

    local introAnimation = self.introTimeline:GetAnimation(1)
    introAnimation:SetOffsetInParent(ZO_BACKGROUND_TITLE_ANIMATION_DELAY_SECONDS * 1000)
    introAnimation:SetDuration(ZO_BACKGROUND_TITLE_ANIMATION_DURATION_SECONDS * 1000)
end

function MagmaBackground:GetSceneTimeHours()
    return self.sceneTimeHours
end

function MagmaBackground:GetSceneTimeframeInterval(startHour, endHour)
    local sceneTimeHours = self.sceneTimeHours
    local elapsedHours, totalHours = nil, nil
    if startHour < endHour then
        totalHours = endHour - startHour
        elapsedHours = sceneTimeHours - startHour
    else
        totalHours = 24.0 - (startHour - endHour)
        if sceneTimeHours >= startHour then
            elapsedHours = sceneTimeHours - startHour
        else
            elapsedHours = zo_min(sceneTimeHours, endHour) + (24.0 - startHour)
        end
    end
    elapsedHours = zo_clamp(elapsedHours, 0.0, totalHours)
    return elapsedHours / totalHours
end

function MagmaBackground:UpdateLayout()
    self.isLayoutDirty = nil

    local screenWidth, screenHeight, widthScale, heightScale = self:GetFullScreenDimensions()
    self.screenWidth, self.screenHeight = screenWidth, screenHeight
    self.screenWidthScale, self.screenHeightScale = widthScale, heightScale
    
    local guiWidth, guiHeight = GuiRoot:GetDimensions()
    self.guiWidth, self.guiHeight = guiWidth, guiHeight

    self.dandelionMinX = -ZO_BACKGROUND_DANDELION_WIDTH
    self.dandelionMaxX = screenWidth
    self.dandelionMinY = -ZO_BACKGROUND_DANDELION_HEIGHT
    self.dandelionMaxY = screenHeight

    for _, textureControl in ipairs(self.fullscreenTextureControls) do
        if not textureControl:IsTextureLoaded() then
            self.isLayoutDirty = true
        end

        textureControl:SetDimensions(screenWidth, screenHeight)
        textureControl:SetTextureCoords(0, ZO_BACKGROUND_TEXTURE_COORD_RIGHT, 0, ZO_BACKGROUND_TEXTURE_COORD_BOTTOM)
    end

    local widthRatio = guiWidth / ZO_BACKGROUND_TEXTURE_IMAGE_WIDTH
    local heightRatio = guiHeight / ZO_BACKGROUND_TEXTURE_IMAGE_HEIGHT
    for _, textureControl in ipairs(self.standardTextureControls) do
        if not textureControl:IsTextureLoaded() then
            self.isLayoutDirty = true
        end

        local textureWidth, textureHeight = textureControl:GetTextureFileDimensions()
        local scale = widthRatio > heightRatio and widthRatio or heightRatio
        textureWidth = textureWidth * scale
        textureHeight = textureHeight * scale
        textureControl:SetDimensions(textureWidth, textureHeight)

        local anchor = ZO_Anchor:New(textureControl.preferredAnchor)
        local offsetX, offsetY = anchor:GetOffsetX(), anchor:GetOffsetY()
        anchor:SetOffsets(offsetX * scale, offsetY * scale)
        anchor:Set(textureControl)
    end
end

function MagmaBackground:Start()
    zo_randomseed(GetTimeStamp32())

    self:InitializeSceneStates()
    self:InitializeParticleStates()

    self.startFrameTimeSeconds = GetFrameTimeSeconds()
    self.introTimeline:PlayFromStart()
    self.floraLoopTimeline:PlayFromStart()
    self.particleLoopTimeline:PlayFromStart()
    self.sceneTimeLoopTimeline:PlayFromStart()

    PlayPregameAnimatedBackgroundSounds()
end

function MagmaBackground:Stop()
    self.startFrameTimeSeconds = nil
    self.introTimeline:Stop()
    self.floraLoopTimeline:Stop()
    self.particleLoopTimeline:Stop()
    self.sceneTimeLoopTimeline:Stop()

    StopPregameAnimatedBackgroundSounds()
    ClearPregameAnimatedBackgroundTimeOfDay()
end

function MagmaBackground:UpdateFloraAnimation(intervalSeconds)
    local waveIntervalSeconds = (intervalSeconds * ZO_BACKGROUND_FLORA_WAVE_INTERVAL_COEFFICIENT) % 3600
    local grassOffset = waveIntervalSeconds * ZO_BACKGROUND_GRASS_WAVE_TIME_COEFFICIENT
    local textureIndices = ZO_BACKGROUND_FOREGROUND_TEXTURE_INDICES

    for index, sceneControl in ipairs(self.sceneControls) do
        local parentAlpha = sceneControl.terrainTexture:GetAlpha()
        sceneControl.grassTexture:SetWaveOffset(grassOffset)

        local foregroundTextures = sceneControl.foregroundTextures
        foregroundTextures[textureIndices.PURPLE_FLOWERS_1]:SetWaveOffset(waveIntervalSeconds)
        foregroundTextures[textureIndices.YELLOW_MUSHROOMS_1]:SetWaveOffset(waveIntervalSeconds * 0.4)

        local ouroborosInnerTexture = sceneControl.ouroborosInnerTexture
        if ouroborosInnerTexture then
            local totalInnerInterval = ZO_BACKGROUND_OUROBOROS_ACTIVE_INTERVAL_SECONDS + ZO_BACKGROUND_OUROBOROS_INACTIVE_INTERVAL_SECONDS
            local normalizedInnerInterval = zo_max((intervalSeconds % totalInnerInterval) - ZO_BACKGROUND_OUROBOROS_INACTIVE_INTERVAL_SECONDS, 0) / ZO_BACKGROUND_OUROBOROS_ACTIVE_INTERVAL_SECONDS
            if zo_floatsAreEqual(normalizedInnerInterval, 0) then
                self.suppressNextMoraEyeSpawn = nil
                ouroborosInnerTexture:SetHidden(true)
            elseif not self.suppressNextMoraEyeSpawn then
                local innerCell = zo_floor(normalizedInnerInterval * 256)
                ZO_SetTextureCell(sceneControl.ouroborosInnerTexture, 16, 16, innerCell)

                local maskInterval = ZO_EaseOutQuartic(normalizedInnerInterval < 0.5 and (normalizedInnerInterval * 2) or (1.0 - (normalizedInnerInterval - 0.5) * 2))
                local maskThreshold = zo_lerp(1, ZO_BACKGROUND_OUROBOROS_MASK_THRESHOLD_MIN, zo_min(1, maskInterval * 2))
                ouroborosInnerTexture:SetMaskThresholdZeroAlphaEdge(maskThreshold)
                ouroborosInnerTexture:SetAlpha(1)

                if ouroborosInnerTexture:IsControlHidden() then
                    if parentAlpha < 0.25 then
                        -- Suppress this instance because we want these to spawn, including the accompanying audio,
                        -- only when the containing scene has not fully interpolated toward zero alpha.
                        self.suppressNextMoraEyeSpawn = true
                    else
                        local numOrigins = #ZO_BACKGROUND_OUROBOROS_NORMALIZED_ORIGINS
                        local normalizedOriginIndex = zo_clamp(zo_ceil(numOrigins * zo_random()), 1, numOrigins)
                        local normalizedOrigin = ZO_BACKGROUND_OUROBOROS_NORMALIZED_ORIGINS[normalizedOriginIndex]
                        local originOffsetX = normalizedOrigin.centerOffsetX + zo_lerp(-normalizedOrigin.radiusX, normalizedOrigin.radiusX, zo_random())
                        local originOffsetY = normalizedOrigin.centerOffsetY + zo_lerp(-normalizedOrigin.radiusY, normalizedOrigin.radiusY, zo_random())
                        local x = self.guiWidth * (0.5 + (originOffsetX * self.screenWidthScale))
                        local y = self.guiHeight * (0.5 + (originOffsetY * self.screenHeightScale))
                        ouroborosInnerTexture:ClearAnchors()
                        ouroborosInnerTexture:SetAnchor(CENTER, GuiRoot, TOPLEFT, x, y)
                        ouroborosInnerTexture:SetHidden(false)

                        PlayPregameAnimatedBackgroundSoundFX(normalizedOrigin.soundFxId)
                    end
                end
            end
        end
    end
end

function MagmaBackground:UpdateDandelionAnimation(intervalSeconds)
    if self.introProgress < 1 then
        return
    end

    local alphaCoefficient = self.dandelionAlphaCoefficient
    if alphaCoefficient > 0.2 then
        alphaCoefficient = (alphaCoefficient - 0.2) * 1.25

        if self.nextDandelionTimeSeconds <= intervalSeconds then
            if self.dandelionPool:GetActiveObjectCount() < ZO_BACKGROUND_DANDELION_INSTANCES_MAX then
                -- Spawn a new dandelion.
                local particle, objectKey = self.dandelionPool:AcquireObject()
                particle.objectKey = objectKey

                local origin = particle.origin
                if not origin then
                    origin = {x = 0, y = 0, z = 0}
                    particle.origin = origin
                end
                origin.x = zo_lerp(0.25, 0.75, zo_random())
                origin.y = zo_lerp(0.25, 0.75, zo_random())
                local z = zo_random()
                origin.z = z

                local scaleFactor = z * z * z * z
                particle.maxAlpha = zo_lerp(0.5, 0.3, scaleFactor)

                local scale = zo_lerp(ZO_BACKGROUND_DANDELION_SCALE_MIN, ZO_BACKGROUND_DANDELION_SCALE_MAX, scaleFactor)
                particle:SetScale(scale)

                local drawLevel = zo_max(origin.y, zo_min(1, z * 2)) * 90 + 30
                particle:SetDrawLevel(drawLevel)

                local forward = particle.forward
                if not forward then
                    forward = {x = 0, y = 0, z = 0}
                    particle.forward = forward
                end
                forward.x = zo_random() * 0.5 - 0.25
                forward.y = zo_random() * 0.5 - 0.25

                particle.startAxisDistance = zo_random() * 0.15 - 0.075
                particle.endAxisDistance = zo_random() * 0.15 - 0.075

                particle.startAxisAngle = zo_random() * ZO_FOUR_PI
                particle.endAxisAngle = zo_random() * ZO_FOUR_PI

                particle.startTimeSeconds = intervalSeconds
                particle.lifetimeSeconds = zo_lerp(ZO_BACKGROUND_DANDELION_LIFETIME_SECONDS_MIN, ZO_BACKGROUND_DANDELION_LIFETIME_SECONDS_MAX, zo_random())
            end

            self.nextDandelionTimeSeconds = intervalSeconds + ZO_BACKGROUND_DANDELION_SPAWN_INTERVAL_SECONDS
        end

        -- Animate active dandelions.
        local minX, minY = self.dandelionMinX, self.dandelionMinY
        local maxX, maxY = self.dandelionMaxX, self.dandelionMaxY
        local activeParticles = self.dandelionPool:GetActiveObjects()
        for _, particle in pairs(activeParticles) do
            local recycleParticle = false
            local interval = (intervalSeconds - particle.startTimeSeconds) / particle.lifetimeSeconds
            if interval >= 1.0 then
                recycleParticle = true
            else
                -- Animate this dandelion.
                local origin = particle.origin
                local forward = particle.forward
                local axisAngle = zo_lerp(particle.startAxisAngle, particle.endAxisAngle, interval)
                local axisDistance = zo_lerp(particle.startAxisDistance, particle.endAxisDistance, interval)
                local axisSine, axisCosine = zo_sin(axisAngle), zo_cos(axisAngle)
                local x = zo_clamp(origin.x + forward.x * interval + axisSine * axisDistance, 0.0, 1.0)
                local y = zo_clamp(origin.y + forward.y * interval + axisCosine * axisDistance, 0.0, 1.0)
                if x == 0.0 or x == 1.0 or y == 0.0 or y == 1.0 then
                    recycleParticle = true
                else
                    local z = origin.z
                    local scaleX, scaleY = 1 - zo_abs(axisSine), 1 - zo_abs(axisCosine)
                    scaleX = zo_clamp(1 - scaleX * scaleX, 0.5, 1.0)
                    scaleY = zo_clamp(1 - scaleY * scaleY, 0.5, 1.0)
                    ZO_ScaleAndRotateTextureCoords(particle, axisAngle, 0.5, 0.5, scaleX, scaleY)

                    local screenX = zo_lerp(minX, maxX, x)
                    local screenY = zo_lerp(minY, maxY, y)
                    particle:SetSimpleAnchorParent(screenX, screenY)

                    local alpha = zo_clamp(zo_sin(interval * ZO_PI) * 2, 0, particle.maxAlpha)
                    particle:SetAlpha(alpha * alphaCoefficient)
                end
            end

            if recycleParticle then
                -- Release and recycle this dandelion.
                self.dandelionPool:ReleaseObject(particle.objectKey)
            end
        end
    end
end

function MagmaBackground:UpdateSceneTime()
    local isIntroPlaying = self.introTimeline:IsPlaying()
    local introProgress = self.introTimeline:GetProgress()

    -- Intro scene time speed override.
    local hoursPerSecond = ZO_BACKGROUND_SCENE_TIME_HOURS_PER_SECOND
    local introIntervalSeconds = GetFrameTimeSeconds() - self.startFrameTimeSeconds
    self.introProgress = 1
    if introIntervalSeconds < ZO_BACKGROUND_INTRO_SCENE_TIME_INTERVAL_SECONDS then
        self.introProgress = introIntervalSeconds / ZO_BACKGROUND_INTRO_SCENE_TIME_INTERVAL_SECONDS
        local easedIntroInterval = 1 - self.introProgress
        easedIntroInterval = 1 - (easedIntroInterval * easedIntroInterval)
        hoursPerSecond = zo_lerp(ZO_BACKGROUND_INTRO_SCENE_TIME_HOURS_PER_SECOND, hoursPerSecond, easedIntroInterval)
    end

    -- Advance scene time.
    local sceneTimeChangeHours = hoursPerSecond * GetFrameDeltaSeconds()
    local sceneTimeHours = (self.sceneTimeHours + sceneTimeChangeHours) % 24.0
    local sceneTimeNormalized = sceneTimeHours / 24.0
    self.sceneTimeHours = sceneTimeHours

    -- Calculate sun position.
    local sunAngleRadians = (sceneTimeNormalized * ZO_TWO_PI + ZO_BACKGROUND_SUN_ANGLE_OFFSET_RADIANS) % ZO_TWO_PI
    local altitude = ZO_BACKGROUND_SUN_ORIGIN_Y + zo_cos(sunAngleRadians) * ZO_BACKGROUND_SUN_RADIUS_ZENITH
    self.sunAltitude = altitude
    local azimuth = ZO_BACKGROUND_SUN_ORIGIN_X + zo_sin(sunAngleRadians) * ZO_BACKGROUND_SUN_RADIUS_AZIMUTH
    self.sunAzimuth = azimuth

    -- Update scene alphas and sun positions.
    local sceneControls = self.sceneControls
    for index, sceneControl in ipairs(sceneControls) do
        local startHours, endHours = sceneControl.startHours, sceneControl.endHours
        local sceneInterval = self:GetSceneTimeframeInterval(startHours, endHours)
        local alpha = ZO_EaseOutQuintic(sceneInterval < 0.5 and (sceneInterval * 2.0) or (1.0 - (sceneInterval - 0.5) * 2.0))
        sceneControl.sceneAlpha = alpha

        if sceneControl.sceneAlpha > 0.001 then
            if sceneControl.skyTexture then
                -- Calculate god ray blur parameters.
                local blurCoefficient = ZO_EaseInOutQuartic(zo_max(-zo_cos(sunAngleRadians), 0.0))
                local numBlurSamples = blurCoefficient > 0.0 and ZO_BACKGROUND_SUN_RADIAL_BLUR_NUM_SAMPLES or 1

                if isIntroPlaying then
                    sceneControl.skyTexture:SetAlpha(blurCoefficient * alpha * zo_lerp(0.75, ZO_BACKGROUND_SKY_ALPHA_MAX, ZO_EaseInQuadratic(introProgress)))
                else
                    sceneControl.skyTexture:SetAlpha(blurCoefficient * zo_lerp(0.0, ZO_BACKGROUND_SKY_ALPHA_MAX, alpha))
                end

                if ZO_BACKGROUND_ENABLE_SHADER_EFFECT_RADIAL_BLUR then
                    sceneControl.skyTexture:SetRadialBlur(azimuth, altitude, numBlurSamples, ZO_BACKGROUND_GOD_RAY_NORMALIZED_LENGTH, ZO_BACKGROUND_SUN_RADIAL_BLUR_OFFSET)
                end
            end

            sceneControl.terrainTexture:SetAlpha(alpha)
            sceneControl.grassTexture:SetAlpha(alpha)
            sceneControl.ouroboros1Texture:SetAlpha(alpha)
            sceneControl.ouroboros2Texture:SetAlpha(alpha)

            for _, foregroundTexture in ipairs(sceneControl.foregroundTextures) do
                foregroundTexture:SetAlpha(alpha)
            end

            sceneControl:SetHidden(false)
        else
            sceneControl:SetHidden(true)
        end
    end

    local nightSceneAlpha = sceneControls[ZO_BACKGROUND_NIGHT_SCENE_INDEX].sceneAlpha
    -- Torchbugs use the same alpha as the night time scene.
    self.torchbugAlphaCoefficient = nightSceneAlpha

    local daySceneAlpha = sceneControls[ZO_BACKGROUND_DAY_SCENE_INDEX].sceneAlpha
    -- Dandelions use the same alpha as the day time scene.
    self.dandelionAlphaCoefficient = daySceneAlpha

    if not isIntroPlaying then
        self.titleDayTexture:SetAlpha(daySceneAlpha)
        self.titleNightTexture:SetAlpha(nightSceneAlpha)
    end

    -- Update audio with the current time of day.
    SetPregameAnimatedBackgroundTimeOfDay(self.sceneTimeHours)
end

function MagmaBackground:GenerateRandomTorchbugPosition(particle)
    local deltaX = (zo_random() * ZO_BACKGROUND_TORCHBUG_OFFSET_UV_MAX) / particle.scale
    local deltaY = (zo_random() * ZO_BACKGROUND_TORCHBUG_OFFSET_UV_MAX) / particle.scale
    local deltaXYSigns = zo_random()
    if deltaXYSigns > 0.5 then
        deltaX = -deltaX
    end
    if deltaXYSigns <= 0.25 or deltaXYSigns > 0.75 then
        deltaY = -deltaY
    end
    return deltaX, deltaY
end

function MagmaBackground:UpdateTorchbugAnimation(intervalSeconds)
    if self.introProgress < 1 then
        return
    end

    local alphaCoefficient = self.torchbugAlphaCoefficient
    if alphaCoefficient > 0.2 then
        alphaCoefficient = (alphaCoefficient - 0.2) * 1.25

        if self.nextTorchbugTimeSeconds <= intervalSeconds then
            local numTorchbugs1 = self.torchbug1Pool:GetActiveObjectCount()
            local numTorchbugs2 = self.torchbug2Pool:GetActiveObjectCount()
            if (numTorchbugs1 + numTorchbugs2) < ZO_BACKGROUND_TORCHBUG_INSTANCES_MAX then
                -- Spawn a new torchbug.
                local scaleFactor = zo_random()
                local originAngle = zo_lerp(ZO_BACKGROUND_TORCHBUG_ORIGIN_ANGLE_MIN, ZO_BACKGROUND_TORCHBUG_ORIGIN_ANGLE_MAX, scaleFactor)
                local sinAngle, cosAngle = zo_sin(originAngle), zo_cos(originAngle)
                local normalizedX = ZO_BACKGROUND_TORCHBUG_ORIGIN_X + sinAngle * zo_lerp(ZO_BACKGROUND_TORCHBUG_ORIGIN_DISTANCE_X_MIN, ZO_BACKGROUND_TORCHBUG_ORIGIN_DISTANCE_X_MAX, zo_random())
                local normalizedY = ZO_BACKGROUND_TORCHBUG_ORIGIN_Y + cosAngle * zo_lerp(ZO_BACKGROUND_TORCHBUG_ORIGIN_DISTANCE_Y_MIN, ZO_BACKGROUND_TORCHBUG_ORIGIN_DISTANCE_Y_MAX, zo_random())
                -- Ensure that the torchbug texture that includes the "spotlight" beneath it is only shown in the lower half of the scene
                -- as it illuminates the ground that is guaranteed to be below the torchbugs; use the torchbug-only texture for torchbugs
                -- in the upper half of the scene as many of these fly far above the ground.
                local pool = normalizedY > 0.5 and self.torchbug1Pool or self.torchbug2Pool
                local particle, objectKey = pool:AcquireObject()
                particle.objectKey = objectKey
                particle.startTimeSeconds = intervalSeconds
                particle.lifetimeSeconds = zo_lerp(ZO_BACKGROUND_TORCHBUG_LIFETIME_SECONDS_MAX, ZO_BACKGROUND_TORCHBUG_LIFETIME_SECONDS_MIN, scaleFactor)
                particle.pulses = zo_max(1, zo_ceil(ZO_BACKGROUND_TORCHBUG_PULSE_COEFFICIENT * zo_random()))
                particle:SetAnchor(CENTER, nil, TOPLEFT, normalizedX * self.guiWidth, normalizedY * self.guiHeight)
                particle:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, zo_lerp(ZO_BACKGROUND_TORCHBUG_SAMPLING_MIN, ZO_BACKGROUND_TORCHBUG_SAMPLING_MAX, normalizedY))
                particle:SetColor(1, 0.7 + zo_random() * 0.3, zo_random() * 0.3, 0)

                particle:SetDrawLevel(normalizedY * 90 + 30)
                particle.scale = zo_lerp(ZO_BACKGROUND_TORCHBUG_SCALE_MIN, ZO_BACKGROUND_TORCHBUG_SCALE_MAX, normalizedY * normalizedY) -- Eased scaling for perspective.

                local startX, startY = self:GenerateRandomTorchbugPosition(particle)
                particle.startOriginX, particle.startOriginY = 0.5 + startX, 0.5 + startY

                local endX, endY = self:GenerateRandomTorchbugPosition(particle)
                particle.endOriginX, particle.endOriginY = 0.5 - endX, 0.5 - endY

                self.nextTorchbugTimeSeconds = intervalSeconds + ZO_BACKGROUND_TORCHBUG_SPAWN_INTERVAL_SECONDS
            end
        end

        -- Animate active torchbugs.
        for _, pool in ipairs(self.torchbugPools) do
            local activeParticles = pool:GetActiveObjects()
            for _, particle in pairs(activeParticles) do
                local interval = (intervalSeconds - particle.startTimeSeconds) / particle.lifetimeSeconds
                if interval >= 1.0 then
                    -- Release and recycle this torchbug.
                    pool:ReleaseObject(particle.objectKey)
                else
                    -- Animate this torchbug.
                    local easedInterval = 1.0 - (interval * interval)
                    local originX = zo_lerp(particle.startOriginX, particle.endOriginX, easedInterval)
                    local originY = zo_lerp(particle.startOriginY, particle.endOriginY, easedInterval)
                    ZO_ScaleAndRotateTextureCoords(particle, 0.0, originX, originY, particle.scale, particle.scale)

                    local alpha = zo_sin((interval * ZO_PI * particle.pulses) % ZO_PI)
                    if alpha < 0.3 and interval > 0.35 and interval < 0.65 then
                        alpha = 0.3
                    end
                    particle:SetAlpha(alpha * alphaCoefficient)
                end
            end
        end
    end
end

--Events

function MagmaBackground:OnScreenResized()
    self.isLayoutDirty = true
end

function MagmaBackground:OnPlayIntroAnimation(completed)
    local effectType = ZO_BACKGROUND_ENABLE_SHADER_EFFECT_GAUSSIAN_BLUR and SHADER_EFFECT_TYPE_GAUSSIAN_BLUR or SHADER_EFFECT_TYPE_NONE
    self.titleDayTexture:SetShaderEffectType(effectType)
    self.titleNightTexture:SetShaderEffectType(effectType)
end

function MagmaBackground:OnStopIntroAnimation(completed)
    self.titleDayTexture:SetShaderEffectType(SHADER_EFFECT_TYPE_NONE)
    self.titleNightTexture:SetShaderEffectType(SHADER_EFFECT_TYPE_NONE)
end

function MagmaBackground:OnUpdateIntroAnimation(progress)
    local blur = zo_lerp(1, 0, ZO_EaseInCubic(progress))
    self.titleDayTexture:SetGaussianBlur(ZO_BACKGROUND_TITLE_BLUR_KERNEL_SIZE, blur)
    self.titleNightTexture:SetGaussianBlur(ZO_BACKGROUND_TITLE_BLUR_KERNEL_SIZE, blur)

    local sampleWeight = progress < 0.5 and (2 * ZO_EaseInQuadratic(progress * 2)) or (2 - ZO_EaseInQuadratic((progress - 0.5) * 2))
    self.titleDayTexture:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, sampleWeight)
    self.titleNightTexture:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, sampleWeight)

    local alpha = zo_min(progress * 1.25, 1)
    self.titleDayTexture:SetAlpha(alpha * self.sceneControls[ZO_BACKGROUND_DAY_SCENE_INDEX].sceneAlpha)
    self.titleNightTexture:SetAlpha(alpha * self.sceneControls[ZO_BACKGROUND_NIGHT_SCENE_INDEX].sceneAlpha)
end

function MagmaBackground:OnUpdateFloraAnimation(progress)
    local intervalSeconds = GetFrameTimeSeconds() - self.startFrameTimeSeconds
    self:UpdateFloraAnimation(intervalSeconds)
end

function MagmaBackground:OnUpdateParticleAnimations(progress)
    local intervalSeconds = GetFrameTimeSeconds() - self.startFrameTimeSeconds
    self:UpdateDandelionAnimation(intervalSeconds)
    self:UpdateTorchbugAnimation(intervalSeconds)
end

function MagmaBackground:OnUpdateSceneTime(progress)
    self:UpdateSceneTime()
end

--Global XML Handlers

function ZO_MagmaBackgroundAnimation_Intro_OnPlay(animation, control, completed)
    local owner = control.owner
    owner:OnPlayIntroAnimation(completed)
end

function ZO_MagmaBackgroundAnimation_Intro_OnStop(animation, control, completed)
    local owner = control.owner
    owner:OnStopIntroAnimation(completed)
end

function ZO_MagmaBackgroundAnimation_Intro_OnUpdate(animation, progress)
    local owner = animation:GetAnimatedControl().owner
    owner:OnUpdateIntroAnimation(progress)
end

function ZO_MagmaBackgroundAnimation_FloraLoop_OnUpdate(animation, progress)
    local owner = animation:GetAnimatedControl().owner
    owner:OnUpdateFloraAnimation(progress)
end

function ZO_MagmaBackgroundAnimation_ParticleLoop_OnUpdate(animation, progress)
    local owner = animation:GetAnimatedControl().owner
    owner:OnUpdateParticleAnimations(progress)
end

function ZO_MagmaBackgroundAnimation_SceneTimeLoop_OnUpdate(animation, progress)
    local owner = animation:GetAnimatedControl().owner
    owner:OnUpdateSceneTime(progress)
end

function ZO_MagmaBackground_OnInitialized(control)
    if IsGamepadUISupported() then
        PREGAME_ANIMATED_BACKGROUND = MagmaBackground:New(control)
    end
end