local BACKGROUND_TEXTURE_HEIGHT = 1080
local BACKGROUND_TEXTURE_WIDTH = 1920
local BACKGROUND_TEXTURE_ASPECT_RATIO = BACKGROUND_TEXTURE_WIDTH / BACKGROUND_TEXTURE_HEIGHT
local BACKGROUND_TEXTURE_COORDINATE_BOUNDS = {0, BACKGROUND_TEXTURE_WIDTH / 2048, 0, BACKGROUND_TEXTURE_HEIGHT / 2048}

local TITLE_TEXTURE_WIDTH = 512
local TITLE_TEXTURE_HEIGHT = 128
local TITLE_TEXTURE_OFFSET_Y = -250

local REPEAT_ANIMATION_WARM_UP_SECONDS = 6
local REPEAT_GLOW_ALPHA_BOUNDS = {0.8, 1.0}
local REPEAT_SPECULAR_ALPHA_BOUNDS = {0.5, 0.8}

local DuneBackground = ZO_InitializingObject:Subclass()

function DuneBackground:Initialize(control)
    self.control = control
    control.owner = self

    self:InitializeControls()

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

    self:UpdateLayout()
end

function DuneBackground:InitializeControls()
    local control = self.control
    self.backgroundControl = control:GetNamedChild("Background")
    self.causticsControl = control:GetNamedChild("Caustics")
    self.clouds1Control = control:GetNamedChild("Clouds1")
    self.clouds2Control = control:GetNamedChild("Clouds2")
    self.clouds3Control = control:GetNamedChild("Clouds3")
    self.gemGlow1Control = control:GetNamedChild("GemGlow1")
    self.gemGlow2Control = control:GetNamedChild("GemGlow2")
    self.gemGlow3Control = control:GetNamedChild("GemGlow3")
    self.gemSpecularControl = control:GetNamedChild("GemSpecular")
    self.initialGlowControl = control:GetNamedChild("InitialGlow")
    self.titleControl = control:GetNamedChild("Title")
    self.vignetteControl = control:GetNamedChild("Vignette")

    self.fullscreenTextureControls =
    {
        self.backgroundControl,
        self.causticsControl,
        self.gemGlow1Control,
        self.gemGlow2Control,
        self.gemGlow3Control,
        self.gemSpecularControl,
        self.initialGlowControl,
        self.vignetteControl,
    }

    self.clouds1Control.startTextureCoords = {-0.3, 0, 0, 1}
    self.clouds1Control.endTextureCoords = {2.5, 3.5, 0.25, 1.4}

    self.clouds2Control.startTextureCoords = {-0.5, -0.1, 0.3, 1.1}
    self.clouds2Control.endTextureCoords = {1.0, 1.45, 0.35, 1.2}

    self.clouds3Control.startTextureCoords = {-1.0, 0.0, -1.0, 0.0}
    self.clouds3Control.endTextureCoords = {2.2, 3.0, 0, 1.0}

    self.introTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_DuneBackgroundAnimation_Intro", control)
    self.introTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)

    self.repeatTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_DuneBackgroundAnimation_Repeat", control)
    self.repeatTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)
end

function DuneBackground:RefreshFullScreenDimensions()
    local screenWidth, screenHeight = GuiRoot:GetDimensions()
    local screenAspectRatio = screenWidth / screenHeight

    local fullScreenWidth, fullScreenHeight
    if screenAspectRatio < BACKGROUND_TEXTURE_ASPECT_RATIO then
        local scale = screenHeight / BACKGROUND_TEXTURE_HEIGHT 
        fullScreenWidth, fullScreenHeight = BACKGROUND_TEXTURE_WIDTH * scale, screenHeight
    else
        local scale = screenWidth / BACKGROUND_TEXTURE_WIDTH
        fullScreenWidth, fullScreenHeight = screenWidth, BACKGROUND_TEXTURE_HEIGHT * scale
    end
    return fullScreenWidth, fullScreenHeight
end

function DuneBackground:UpdateLayout()
    local width, height = self:RefreshFullScreenDimensions()
    local x1, x2, y1, y2 = unpack(BACKGROUND_TEXTURE_COORDINATE_BOUNDS)

    for _, textureControl in ipairs(self.fullscreenTextureControls) do
        textureControl:SetDimensions(width, height)
        textureControl:SetTextureCoords(x1, x2, y1, y2)
    end

    local widthRatio = width / BACKGROUND_TEXTURE_WIDTH
    local heightRatio = height / BACKGROUND_TEXTURE_HEIGHT
    self.titleControl:SetDimensions(TITLE_TEXTURE_WIDTH * widthRatio, TITLE_TEXTURE_HEIGHT * heightRatio)
    local titleOffsetY = TITLE_TEXTURE_OFFSET_Y * heightRatio
    self.titleControl:SetAnchor(CENTER, nil, nil, 0, titleOffsetY)
end

function DuneBackground:Start()
    if self.isPlaying then
        return
    end

    self.isPlaying = true
    self.repeatWarmUpEndTimeS = GetFrameTimeSeconds() + REPEAT_ANIMATION_WARM_UP_SECONDS
    PlayPregameAnimatedBackgroundSounds()

    self.introTimeline:PlayFromStart()
    self.repeatTimeline:PlayFromStart()
end

function DuneBackground:Stop()
    self.isPlaying = nil
    StopPregameAnimatedBackgroundSounds()

    self.introTimeline:Stop()
    self.repeatTimeline:Stop()
end

--Events

function DuneBackground:OnScreenResized()
    self:UpdateLayout()
end

function DuneBackground:OnPlayIntroAnimation(completed)
    self.clouds1Control:SetHidden(false)
    self.clouds2Control:SetHidden(false)
    self.clouds3Control:SetHidden(false)
end

function DuneBackground:OnStopIntroAnimation(completed)
    self.clouds1Control:SetHidden(true)
    self.clouds2Control:SetHidden(true)
    self.clouds3Control:SetHidden(true)
end

function DuneBackground:OnUpdateIntroAnimation(progress)
    local easedProgress = zo_min(1, progress * 2)
    self.backgroundControl:SetColor(easedProgress, easedProgress, easedProgress, 1)
    self.titleControl:SetColor(easedProgress, easedProgress, easedProgress, 1)
    self.vignetteControl:SetAlpha(easedProgress)
    self.causticsControl:SetAlpha(easedProgress)

    local glowProgress
    if progress < 0.5 then
        glowProgress = zo_max(0, zo_lerp(-0.5, 0.5, progress * 2))
    elseif progress < 0.75 then
        glowProgress = 0.5
    else
        glowProgress = zo_lerp(0.5, 1, (progress - 0.75) * 4)
    end
    local glowAlpha = zo_sin(glowProgress * ZO_PI) * 0.8
    local glowFlickerTheta = progress * ZO_TWO_PI * 5
    local glowFlickerAlpha1 = zo_lerp(zo_max(0.6, progress), 1, zo_sin(glowFlickerTheta) * 0.5 + 0.5) * glowAlpha
    local glowFlickerAlpha2 = zo_lerp(zo_max(0.6, progress), 1, zo_sin(glowFlickerTheta + 0.3) * 0.5 + 0.5) * glowAlpha
    self.initialGlowControl:SetVertexColors(VERTEX_POINTS_TOPLEFT + VERTEX_POINTS_TOPRIGHT, 1, 1, 1, glowFlickerAlpha1)
    self.initialGlowControl:SetVertexColors(VERTEX_POINTS_BOTTOMLEFT + VERTEX_POINTS_BOTTOMRIGHT, 1, 1, 1, glowFlickerAlpha2)

    local cloudAlpha = easedProgress * 0.8
    local textureCoords
    textureCoords = zo_lerpVector(self.clouds1Control.startTextureCoords, self.clouds1Control.endTextureCoords, zo_lerp(0, 1.5, easedProgress))
    self.clouds1Control:SetTextureCoords(unpack(textureCoords))
    self.clouds1Control:SetAlpha(cloudAlpha)

    textureCoords = zo_lerpVector(self.clouds2Control.startTextureCoords, self.clouds2Control.endTextureCoords, zo_lerp(-0.15, 1.15, progress))
    self.clouds2Control:SetTextureCoords(unpack(textureCoords))
    self.clouds2Control:SetAlpha(cloudAlpha)

    textureCoords = zo_lerpVector(self.clouds3Control.startTextureCoords, self.clouds3Control.endTextureCoords, zo_lerp(-0.5, 1, progress))
    self.clouds3Control:SetTextureCoords(unpack(textureCoords))
    self.clouds3Control:SetAlpha(cloudAlpha)
end

function DuneBackground:OnUpdateRepeatAnimation(progress)
    local timeS = GetFrameTimeSeconds()
    local interval = timeS % 3600 -- Interval wraps at 3600 to stay within a range that works well with our shaders' maximum precision.

    self.gemGlow1Control:SetWaveOffset(interval)
    self.gemGlow2Control:SetWaveOffset(interval + 0.25)
    self.gemGlow3Control:SetWaveOffset(interval + 0.6)
    self.gemSpecularControl:SetWaveOffset(interval + 0.8)

    local waveInterval = (zo_sin(interval) + zo_sin(interval * 0.3)) * 0.25 + 0.5
    local globalAlpha = 1 - (zo_max(self.repeatWarmUpEndTimeS - timeS, 0) / REPEAT_ANIMATION_WARM_UP_SECONDS)
    local minAlpha, maxAlpha = unpack(REPEAT_GLOW_ALPHA_BOUNDS)
    local glowAlpha = zo_lerp(minAlpha, maxAlpha, waveInterval) * globalAlpha
    self.gemGlow1Control:SetAlpha(glowAlpha)
    self.gemGlow2Control:SetAlpha(glowAlpha)
    self.gemGlow3Control:SetAlpha(glowAlpha)

    local minSpecularAlpha, maxSpecularAlpha = unpack(REPEAT_SPECULAR_ALPHA_BOUNDS)
    local specularAlpha = zo_lerp(minSpecularAlpha, maxSpecularAlpha, waveInterval)
    self.gemSpecularControl:SetAlpha(specularAlpha * globalAlpha)

    self.causticsControl:SetCausticOffset(interval)
end

--Global XML Handlers

function ZO_DuneBackgroundAnimation_Intro_OnPlay(animation, control, completed)
    local owner = control.owner
    owner:OnPlayIntroAnimation(completed)
end

function ZO_DuneBackgroundAnimation_Intro_OnStop(animation, control, completed)
    local owner = control.owner
    owner:OnStopIntroAnimation(completed)
end

function ZO_DuneBackgroundAnimation_Intro_OnUpdate(animation, progress)
    local owner = animation:GetAnimatedControl().owner
    owner:OnUpdateIntroAnimation(progress)
end

function ZO_DuneBackgroundAnimation_Repeat_OnUpdate(animation, progress)
    local owner = animation:GetAnimatedControl().owner
    owner:OnUpdateRepeatAnimation(progress)
end

function ZO_DuneBackground_OnInitialized(control)
    if IsGamepadUISupported() then
        PREGAME_ANIMATED_BACKGROUND = DuneBackground:New(control)
    end
end