-----------------------------
--Movie Background Fragment
-----------------------------

ZO_MovieBackgroundFragment = ZO_SceneFragment:Subclass()

function ZO_MovieBackgroundFragment:New(...)
    return ZO_SceneFragment.New(self, ...)
end

function ZO_MovieBackgroundFragment:Initialize(movieFile)
    ZO_SceneFragment.Initialize(self)
    self.movieFile = movieFile
end

function ZO_MovieBackgroundFragment:Show()
    local PLAY_IMMEDIATELY = true
    local PLAY_IN_BACKGROUND = true
    local LOOP = true
    PlayVideo(self.movieFile, PLAY_IMMEDIATELY, VIDEO_SKIP_MODE_NO_SKIP, nil, PLAY_IN_BACKGROUND, LOOP)
    self:OnShown()
end

function ZO_MovieBackgroundFragment:Hide()
    CancelCurrentVideoPlayback()
    self:OnHidden()
end

ZO_MutedMovieBackgroundFragment = ZO_MovieBackgroundFragment:Subclass()

function ZO_MutedMovieBackgroundFragment:Show()
    local PLAY_IMMEDIATELY = true
    local PLAY_IN_BACKGROUND = true
    local LOOP = true
    local MUTE = true
    PlayVideo(self.movieFile, PLAY_IMMEDIATELY, VIDEO_SKIP_MODE_NO_SKIP, nil, PLAY_IN_BACKGROUND, LOOP, MUTE)
    self:OnShown()
end

----------------------------------------
--Pregame Scene State Advance From Fragment
----------------------------------------

ZO_PregameSceneStateAdvanceFromFragment = ZO_SceneFragment:Subclass()

function ZO_PregameSceneStateAdvanceFromFragment:New(...)
    return ZO_SceneFragment.New(self, ...)
end

function ZO_PregameSceneStateAdvanceFromFragment:Initialize(state)
    ZO_SceneFragment.Initialize(self)
    self:SetHideOnSceneHidden(true)
    self.advanceFromState = state
end

function ZO_PregameSceneStateAdvanceFromFragment:Show()
    self:OnShown()
end

function ZO_PregameSceneStateAdvanceFromFragment:Hide()
    --Advancing can often change scenes causing fragments to refresh and this Hide be re-run. So protect the advance until the previous advance completes.
    --also only advance if we are in an expected state
    if not self.advancing then
        self.advancing = true
        PregameStateManager_AdvanceStateFromState(self.advanceFromState)
        self:OnHidden()
    end
    self.advancing = nil
end

ACCESSIBILITY_MODE_PROMPT_ACTION_LAYER_FRAGMENT = ZO_ActionLayerFragment:New("AccessibilityModePromptActions")
PREGAME_ACCESSIBILITY_MODE_PROMPT_INTRO_ADVANCE_FRAGMENT = ZO_PregameSceneStateAdvanceFromFragment:New("ShowAccessibilityModePrompt")

PREGAME_GAMMA_ADJUST_INTRO_ADVANCE_FRAGMENT = ZO_PregameSceneStateAdvanceFromFragment:New("GammaAdjust")

SCREEN_ADJUST_ACTION_LAYER_FRAGMENT = ZO_ActionLayerFragment:New("ScreenAdjustActions")
PREGAME_SCREEN_ADJUST_INTRO_ADVANCE_FRAGMENT = ZO_PregameSceneStateAdvanceFromFragment:New("ScreenAdjustIntro")
