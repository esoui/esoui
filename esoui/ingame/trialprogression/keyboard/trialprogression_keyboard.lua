ZO_TRIAL_PROGRESSION_KEYBOARD_MAX_TRACK_HEIGHT = 700
ZO_TRIAL_PROGRESSION_KEYBOARD_PERK_SIZE = 56
ZO_TRIAL_PROGRESSION_KEYBOARD_MAX_TRACKS_WIDTH = 1200
ZO_TRIAL_PROGRESSION_KEYBOARD_BG_WIDTH = 200

ZO_TrialProgression_Keyboard = ZO_TrialProgression_Shared:Subclass()

function ZO_TrialProgression_Keyboard:Initialize(control)
    ZO_TrialProgression_Shared.Initialize(self, control)

    TRIAL_PROGRESSION_SCENE_KEYBOARD = self:GetScene()
    SYSTEMS:RegisterKeyboardRootScene("trialProgression", TRIAL_PROGRESSION_SCENE_KEYBOARD)

    self.layoutData =
    {
        perkSize = ZO_TRIAL_PROGRESSION_KEYBOARD_PERK_SIZE,
        bgWidth = ZO_TRIAL_PROGRESSION_KEYBOARD_BG_WIDTH,
        maxTrackWidth = ZO_TRIAL_PROGRESSION_KEYBOARD_MAX_TRACKS_WIDTH,
        maxTrackHeight = ZO_TRIAL_PROGRESSION_KEYBOARD_MAX_TRACK_HEIGHT,
        trackOffsetY = 10,
    }
end

function ZO_TrialProgression_Keyboard:InitializeControlPools()
    self.trackControlPool = ZO_ControlPool:New("ZO_TrialProgression_Keyboard_Track", self.trackContainer, "ProgressionTrack")
    self.trackControlPool:SetCustomResetBehavior(function(control)
        control.object:Reset()
    end)

    self.trackPointsControlPool = ZO_ControlPool:New("ZO_TrialProgression_Keyboard_Track_Points", self.trackContainer, "ProgressionTrackPoints")
end

function ZO_TrialProgression_Keyboard:GetSceneName()
    return "trialProgression_Keyboard"
end

function ZO_TrialProgression_Keyboard:GetEventNamespace()
    return "TrialProgression_Keyboard"
end

function ZO_TrialProgression_Keyboard.OnControlInitialized(control)
    TRIAL_PROGRESSION_KEYBOARD = ZO_TrialProgression_Keyboard:New(control)
end

------------------------------------
-- ZO_TrialProgression_Track_Keyboard
------------------------------------

ZO_TrialProgression_Track_Keyboard = ZO_TrialProgression_Track_Shared:Subclass()

function ZO_TrialProgression_Track_Keyboard:InitializeControlPools()
    self.progressBarControlPool = ZO_ControlPool:New("ZO_TrialProgression_Keyboard_ProgressBar", self.control, "ProgressBar")
    self.perkControlPool = ZO_ControlPool:New("ZO_TrialProgression_Keyboard_Perk", self.control, "Perk")
end

function ZO_TrialProgression_Track_Keyboard.OnMouseEnter(control)
    local parentControl = control:GetParent()
    local trackIndex = parentControl.object.trackData.trackIndex
    TRIAL_PROGRESSION_KEYBOARD:SetSelectedTrackIndex(trackIndex)
end

function ZO_TrialProgression_Track_Keyboard.OnMouseExit(control)
    local NO_SELECTED_INDEX = nil
    TRIAL_PROGRESSION_KEYBOARD:SetSelectedTrackIndex(NO_SELECTED_INDEX)
end

function ZO_TrialProgression_Track_Keyboard.OnPerkMouseEnter(control)
    TRIAL_PROGRESSION_KEYBOARD:SetSelectedTrackIndex(control.trackIndex)
    if control.trackIndex and control.perkIndex then
        InitializeTooltip(AbilityTooltip, control, RIGHT, -5, 0, LEFT)
        AbilityTooltip:SetTrialProgressionPassive(control.trackIndex, control.perkIndex)
    end
end

function ZO_TrialProgression_Track_Keyboard.OnPerkMouseExit(control)
    local NO_SELECTED_INDEX = nil
    TRIAL_PROGRESSION_KEYBOARD:SetSelectedTrackIndex(NO_SELECTED_INDEX)
    ClearTooltip(AbilityTooltip)
end