-- Ground Constants --
ZO_BADLANDS_SHOW_GROUND_FADE_DURATION_MS = 500
ZO_BADLANDS_GROUND_DARK_FADE_DELAY_MS = 1800
ZO_BADLANDS_GROUND_DARK_FADE_DURATION_MS = 800
ZO_BADLANDS_GROUND_CORRUPTION_UNMASK_DELAY_MS = 2300
ZO_BADLANDS_GROUND_CORRUPTION_UNMASK_DURATION_MS = 1000
ZO_BADLANDS_GROUND_CORRUPTION_MASK_THRESHOLD_EDGE = 1.0
ZO_BADLANDS_GROUND_CORRUPTION_MASK_THRESHOLD_THICKNESS = 0.2
ZO_BADLANDS_BURNT_LEAVES_UNMASK_DELAY_MS = 2500
ZO_BADLANDS_BURNT_LEAVES_UNMASK_DURATION_MS = 333
ZO_BADLANDS_BURNT_LEAVES_MASK_THRESHOLD_EDGE = 1.0
ZO_BADLANDS_BURNT_LEAVES_MASK_THRESHOLD_THICKNESS = 0.2
ZO_BADLANDS_BURNT_LEAVES_HIGHLIGHT_MIN_FADE_DURATION_MS = 333
ZO_BADLANDS_BURNT_LEAVES_HIGHLIGHT_MAX_FADE_DURATION_MS = 666

local GROUND_TEXTURE_WIDTH = 2048
local GROUND_TEXTURE_HEIGHT = 2048
local GROUND_TEXTURE_USED_WIDTH = 1920
local GROUND_TEXTURE_USED_HEIGHT = 1080
local GROUND_TEXTURE_MAX_U = GROUND_TEXTURE_USED_WIDTH / GROUND_TEXTURE_WIDTH
local GROUND_TEXTURE_MAX_V = GROUND_TEXTURE_USED_HEIGHT / GROUND_TEXTURE_HEIGHT

-- Title Constants --
ZO_BADLANDS_SHOW_TITLE_FADE_DELAY_MS = 0
ZO_BADLANDS_SHOW_TITLE_FADE_DURATION_MS = 750
ZO_BADLANDS_TITLE_DARK_FADE_DELAY_MS = 1666
ZO_BADLANDS_TITLE_DARK_FADE_DURATION_MS = 1000
ZO_BADLANDS_TITLE_CORRUPT_FADE_DELAY_MS = 2300
ZO_BADLANDS_TITLE_CORRUPT_FADE_DURATION_MS = 666

local TITLE_TEXTURE_WIDTH = 512
local TITLE_TEXTURE_HEIGHT = 256
local TITLE_TO_GROUND_WIDTH_RATIO = TITLE_TEXTURE_WIDTH / GROUND_TEXTURE_USED_WIDTH
local TITLE_TO_GROUND_HEIGHT_RATIO = TITLE_TEXTURE_HEIGHT / GROUND_TEXTURE_USED_HEIGHT
local TITLE_OFFSET_FROM_TOP_BASE_Y = 140

-- Logo Constants --
ZO_BADLANDS_LOGO_DARK_FADE_DELAY_MS = 1666
ZO_BADLANDS_LOGO_DARK_FADE_DURATION_MS = 1000
ZO_BADLANDS_LOGO_CORRUPT_FADE_DELAY_MS = 1730
ZO_BADLANDS_LOGO_CORRUPT_FADE_DURATION_MS = 1666
ZO_BADLANDS_LOGO_RUNES_UNMASK_DELAY_MS = 1750
ZO_BADLANDS_LOGO_RUNES_UNMASK_DURATION_MS = 1500
ZO_BADLANDS_LOGO_RUNES_MASK_THRESHOLD_EDGE = 1.0
ZO_BADLANDS_LOGO_RUNES_MASK_THRESHOLD_THICKNESS = 0.1
ZO_BADLANDS_LOGO_RUNES_HIGHLIGHT_MIN_FADE_DURATION_MS = 1500
ZO_BADLANDS_LOGO_RUNES_HIGHLIGHT_MAX_FADE_DURATION_MS = 1500

local LOGO_TEXTURE_WIDTH = 1024
local LOGO_TEXTURE_HEIGHT = 1024
local LOGO_TO_GROUND_WIDTH_RATIO = LOGO_TEXTURE_WIDTH / GROUND_TEXTURE_USED_WIDTH
local LOGO_TO_GROUND_HEIGHT_RATIO = LOGO_TEXTURE_HEIGHT / GROUND_TEXTURE_USED_HEIGHT

local IGNORE_ANIMATION_CALLBACKS = true

local function RandomizeFadeTimelineAndRestart(animationTimeline)
    -- Bounce back and forth between a random high alpha and a random low alpha
    local alphaAnimation = animationTimeline:GetAnimation(1)
    local oldEndAlpha = alphaAnimation:GetEndAlpha()
    alphaAnimation:SetStartAlpha(oldEndAlpha)
    if oldEndAlpha < 0.5 then
        alphaAnimation:SetEndAlpha(1.0)
    else
        alphaAnimation:SetEndAlpha(zo_randomDecimalRange(0.0, 0.5))
    end
    local minDuration, maxDuration = animationTimeline.GetFadeDurationValues()
    alphaAnimation:SetDuration(zo_random(minDuration, maxDuration))
    animationTimeline:PlayFromStart()
end

local function ResetRandomizedFadeTimeline(animationTimeline)
    local alphaAnimation = animationTimeline:GetAnimation(1)
    alphaAnimation:SetStartAlpha(1.0)
    alphaAnimation:SetEndAlpha(1.0)
    animationTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
end

local BadlandsBackground = ZO_InitializingObject:Subclass()

function BadlandsBackground:Initialize(control)
    self.control = control
    self.containerControl = control:GetNamedChild("Container")
    self.groundControl = self.containerControl:GetNamedChild("Ground")
    self.groundCleanTexture = self.groundControl:GetNamedChild("Clean")
    self.groundDarkTexture = self.groundControl:GetNamedChild("Dark")
    self.groundCorruptTexture = self.groundControl:GetNamedChild("Corrupt")
    self.groundBurntLeavesTexture = self.groundControl:GetNamedChild("BurntLeaves")
    self.groundBurntLeavesHighlightTexture = self.groundBurntLeavesTexture:GetNamedChild("Highlight")
    self.groundCleanTexture:SetTextureCoords(0, GROUND_TEXTURE_MAX_U, 0, GROUND_TEXTURE_MAX_V)
    self.groundDarkTexture:SetTextureCoords(0, GROUND_TEXTURE_MAX_U, 0, GROUND_TEXTURE_MAX_V)
    self.groundCorruptTexture:SetTextureCoords(0, GROUND_TEXTURE_MAX_U, 0, GROUND_TEXTURE_MAX_V)
    self.groundBurntLeavesTexture:SetTextureCoords(0, GROUND_TEXTURE_MAX_U, 0, GROUND_TEXTURE_MAX_V)
    self.groundBurntLeavesHighlightTexture:SetTextureCoords(0, GROUND_TEXTURE_MAX_U, 0, GROUND_TEXTURE_MAX_V)

    self.logoControl = self.containerControl:GetNamedChild("Logo")
    self.logoRunesHighlightTexture = self.logoControl:GetNamedChild("RunesHighlight")
    self.titleControl = self.containerControl:GetNamedChild("Title")

    PREGAME_ANIMATED_BACKGROUND_FRAGMENT = ZO_SimpleSceneFragment:New(control)
    PREGAME_ANIMATED_BACKGROUND_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:Start()
        elseif newState == SCENE_HIDDEN then
            self:Stop()
        end
    end)

    control:RegisterForEvent(EVENT_SCREEN_RESIZED, function() self:OnScreenResized() end)

    self:InitializeAnimations()
    self:ResizeSizes()
end

function BadlandsBackground:InitializeAnimations()
    self.showTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_BadlandsBackgroundShowAnimation", self.containerControl)
    self.showTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)

    self.logoRunesHighlightTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_BadlandsBackgroundLogoRunesHighlightAnimation", self.logoRunesHighlightTexture)
    self.logoRunesHighlightTimeline.GetFadeDurationValues = function()
        return ZO_BADLANDS_LOGO_RUNES_HIGHLIGHT_MIN_FADE_DURATION_MS, ZO_BADLANDS_LOGO_RUNES_HIGHLIGHT_MAX_FADE_DURATION_MS
    end
    self.burntLeavesHighlightTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_BadlandsBackgroundBurntLeavesHighlightAnimation", self.groundBurntLeavesHighlightTexture)
    self.burntLeavesHighlightTimeline.GetFadeDurationValues = function()
        return ZO_BADLANDS_BURNT_LEAVES_HIGHLIGHT_MIN_FADE_DURATION_MS, ZO_BADLANDS_BURNT_LEAVES_HIGHLIGHT_MAX_FADE_DURATION_MS
    end
    self:ResetAnimations()
end

function BadlandsBackground:ResetAnimations()
    ResetRandomizedFadeTimeline(self.burntLeavesHighlightTimeline)
    ResetRandomizedFadeTimeline(self.logoRunesHighlightTimeline)
    self.showTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
end

function BadlandsBackground:ResizeSizes()
    local guiWidth, guiHeight = GuiRoot:GetDimensions()
    local GROUND_ASPECT_RATIO = GROUND_TEXTURE_USED_WIDTH / GROUND_TEXTURE_USED_HEIGHT
    local groundWidth = GROUND_ASPECT_RATIO * guiHeight
    if groundWidth < guiWidth then
        groundWidth = guiWidth
    end
    self.groundControl:SetWidth(groundWidth)

    local groundHeight = self.groundControl:GetHeight()
    self.logoControl:SetWidth(groundWidth * LOGO_TO_GROUND_WIDTH_RATIO)
    self.logoControl:SetHeight(groundHeight * LOGO_TO_GROUND_HEIGHT_RATIO)

    self.titleControl:SetWidth(groundWidth * TITLE_TO_GROUND_WIDTH_RATIO)
    self.titleControl:SetHeight(groundHeight * TITLE_TO_GROUND_HEIGHT_RATIO)
    local titleOffsetY = TITLE_OFFSET_FROM_TOP_BASE_Y * (groundHeight / GROUND_TEXTURE_USED_HEIGHT)
    self.titleControl:SetAnchor(TOP, self.containerControl, TOP, 0, titleOffsetY)
end

function BadlandsBackground:Start()
    self.showTimeline:PlayFromStart()
    PlayPregameAnimatedBackgroundSounds()
end

function BadlandsBackground:Stop()
    StopPregameAnimatedBackgroundSounds()
    self:ResetAnimations()
end

--Events

function BadlandsBackground:OnScreenResized()
    self:ResizeSizes()
end

function BadlandsBackground:OnGroundBurntLeavesAnimationStop(_, completedPlaying)
    if completedPlaying then
        RandomizeFadeTimelineAndRestart(self.burntLeavesHighlightTimeline)
    end
end

function BadlandsBackground:OnLogoCorruptAnimationStop(_, completedPlaying)
    if completedPlaying then
        RandomizeFadeTimelineAndRestart(self.logoRunesHighlightTimeline)
    end
end

--Global XML Handlers

function ZO_BadlandsBackground_OnInitialized(self)
    if IsGamepadUISupported() then
        PREGAME_ANIMATED_BACKGROUND = BadlandsBackground:New(self)
    end
end

function ZO_BadlandsBackground_Unmask_SetProgress(animation, progress)
    local control = animation:GetAnimatedControl()
    local edge = zo_lerp(-control:GetMaskThresholdThickness(), 1, 1 - progress)
    control:SetMaskThresholdZeroAlphaEdge(edge)
end

function ZO_BadlandsBackground_GroundBurntLeavesAnimation_OnStop(...)
    PREGAME_ANIMATED_BACKGROUND:OnGroundBurntLeavesAnimationStop(...)
end

function ZO_BadlandsBackground_LogoCorruptAnimation_OnStop(...)
    PREGAME_ANIMATED_BACKGROUND:OnLogoCorruptAnimationStop(...)
end