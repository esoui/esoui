local BACKGROUND_TEXTURE_USED_HEIGHT = 1080
local BACKGROUND_TEXTURE_USED_WIDTH = 1920
local BACKGROUND_TEXTURE_COORDINATE_BOUNDS =
{
    x = BACKGROUND_TEXTURE_USED_WIDTH / 2048,
    y = BACKGROUND_TEXTURE_USED_HEIGHT / 2048
}

local REPEAT_ANIMATION_WARM_UP_SECONDS = 6
local REPEAT_GLOW_ALPHA_BOUNDS = {0.8, 1.0}
local REPEAT_SPECULAR_ALPHA_BOUNDS = {0.5, 0.8}

local DuneBackground = ZO_InitializingObject:Subclass()

function DuneBackground:Initialize(control)
    self.control = control
    control.owner = self

    self.nativeAspectRatio = BACKGROUND_TEXTURE_COORDINATE_BOUNDS.x / BACKGROUND_TEXTURE_COORDINATE_BOUNDS.y
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
    self.causticsHighlightControl = control:GetNamedChild("CausticsHighlight")
    self.cloudsControl = control:GetNamedChild("Clouds")
    self.clouds2Control = control:GetNamedChild("Clouds2")
    self.clouds3Control = control:GetNamedChild("Clouds3")
    self.gemGlow1Control = control:GetNamedChild("GemGlow1")
    self.gemGlow2Control = control:GetNamedChild("GemGlow2")
    self.gemGlow3Control = control:GetNamedChild("GemGlow3")
    self.gemSpecularControl = control:GetNamedChild("GemSpecular")
    self.initialGlowControl = control:GetNamedChild("InitialGlow")
    self.titleControl = control:GetNamedChild("Title")
    self.vignetteControl = control:GetNamedChild("Vignette")

    self.cloudsControl.startTextureCoords = {-0.3, 0, 0, 1}
    self.cloudsControl.endTextureCoords = {2.5, 3.5, 0.25, 1.4}

    self.clouds2Control.startTextureCoords = {-0.5, -0.1, 0.3, 1.1}
    self.clouds2Control.endTextureCoords = {1.0, 1.45, 0.35, 1.2}

    self.clouds3Control.startTextureCoords = {-1.0, 0.0, -1.0, 0.0}
    self.clouds3Control.endTextureCoords = {2.2, 3.0, 0, 1.0}

    self.introTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_DuneBackgroundAnimation_Intro", control)
    self.introTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)

    self.repeatTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_DuneBackgroundAnimation_Repeat", control)
    self.repeatTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)
end

function DuneBackground:UpdateLayout()
    local guiWidth, guiHeight = GuiRoot:GetDimensions()
    self.guiWidth, self.guiHeight = guiWidth, guiHeight
    self.aspectRatioX = guiWidth / BACKGROUND_TEXTURE_USED_WIDTH
    self.aspectRatioY = guiHeight / BACKGROUND_TEXTURE_USED_HEIGHT

    local aspectOverscanX = self.aspectRatioX - 1
    local aspectOverscanY = self.aspectRatioY - 1
    if aspectOverscanX < 0 then
        aspectOverscanX = 0
    else
        aspectOverscanX = aspectOverscanX * BACKGROUND_TEXTURE_COORDINATE_BOUNDS.x * 0.5
    end
    if aspectOverscanY < 0 then
        aspectOverscanY = 0
    else
        aspectOverscanY = aspectOverscanY * BACKGROUND_TEXTURE_COORDINATE_BOUNDS.y * 0.5
    end
    self.aspectOverscanX, self.aspectOverscanY = aspectOverscanX, aspectOverscanY

    local x1, x2 = -aspectOverscanX, BACKGROUND_TEXTURE_COORDINATE_BOUNDS.x * self.aspectRatioX - aspectOverscanX
    local y1, y2 = -aspectOverscanY, BACKGROUND_TEXTURE_COORDINATE_BOUNDS.y * self.aspectRatioY - aspectOverscanY
    self.backgroundControl:SetTextureCoords(x1, x2, y1, y2)
    self.causticsControl:SetTextureCoords(x1, x2, y1, y2)
    self.causticsHighlightControl:SetTextureCoords(x1, x2, y1, y2)
    self.gemGlow1Control:SetTextureCoords(x1, x2, y1, y2)
    self.gemGlow2Control:SetTextureCoords(x1, x2, y1, y2)
    self.gemGlow3Control:SetTextureCoords(x1, x2, y1, y2)
    self.gemSpecularControl:SetTextureCoords(x1, x2, y1, y2)
    self.initialGlowControl:SetTextureCoords(x1, x2, y1, y2)
    self.vignetteControl:SetTextureCoords(x1, x2, y1, y2)
end

function DuneBackground:Start()
    if self.isPlaying then
        return
    end

    self.isPlaying = true
    self.hasPlayedGemSound = nil
    self.repeatWarmUpEndTimeS = GetFrameTimeSeconds() + REPEAT_ANIMATION_WARM_UP_SECONDS
    PlayPregameAnimatedBackgroundSounds()

    self.introTimeline:PlayFromStart()
    self.repeatTimeline:PlayFromStart()
end

function DuneBackground:Stop()
    self.isPlaying = nil
    self.hasPlayedGemSound = nil
    StopPregameAnimatedBackgroundSounds()

    self.introTimeline:Stop()
    self.repeatTimeline:Stop()
end

--Events

function DuneBackground:OnScreenResized()
    self:UpdateLayout()
end

function DuneBackground:OnPlayIntroAnimation(completed)
    self.cloudsControl:SetHidden(false)
    self.clouds2Control:SetHidden(false)
    self.clouds3Control:SetHidden(false)
end

function DuneBackground:OnStopIntroAnimation(completed)
    self.cloudsControl:SetHidden(true)
    self.clouds2Control:SetHidden(true)
    self.clouds3Control:SetHidden(true)
end

function DuneBackground:OnUpdateIntroAnimation(progress)
    local easedProgress = zo_min(1, progress * 2)
    self.backgroundControl:SetColor(easedProgress, easedProgress, easedProgress, 1)
    self.titleControl:SetColor(easedProgress, easedProgress, easedProgress, 1)
    self.vignetteControl:SetAlpha(easedProgress)
    self.causticsControl:SetVertexColors(VERTEX_POINTS_TOPLEFT + VERTEX_POINTS_TOPRIGHT, 0, 0, 0, 0)
    self.causticsControl:SetVertexColors(VERTEX_POINTS_BOTTOMLEFT + VERTEX_POINTS_BOTTOMRIGHT, 1, 1, 1, easedProgress)
    self.causticsHighlightControl:SetVertexColors(VERTEX_POINTS_TOPLEFT + VERTEX_POINTS_TOPRIGHT, 0, 0, 0, 0)
    self.causticsHighlightControl:SetVertexColors(VERTEX_POINTS_BOTTOMLEFT + VERTEX_POINTS_BOTTOMRIGHT, 1, 1, 1, easedProgress)

    local glowAlpha = zo_sin(progress * ZO_PI) * 0.85
    self.initialGlowControl:SetAlpha(glowAlpha)
    if glowAlpha >= 0.25 and not self.hasPlayedGemSound then
        self.hasPlayedGemSound = true
        PlaySound(SOUNDS.PREGAME_ANIMATEDBACKGROUND_HIGHISLE_GEM_SPARKLE)
    end

    local cloudAlpha = easedProgress * 0.8
    local textureCoords
    textureCoords = zo_lerpVector(self.cloudsControl.startTextureCoords, self.cloudsControl.endTextureCoords, zo_lerp(0, 1.5, easedProgress))
    self.cloudsControl:SetTextureCoords(unpack(textureCoords))
    self.cloudsControl:SetAlpha(cloudAlpha)

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
    self.causticsHighlightControl:SetCausticOffset(interval)
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