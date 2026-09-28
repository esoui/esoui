local TRIAL_PROGRESSION_BAR_LAYOUT_PADDING_X = 150

ZO_TRIAL_PROGRESSION_GAMEPAD_MAX_TRACK_HEIGHT = 800
ZO_TRIAL_PROGRESSION_GAMEPAD_PERK_SIZE = 50
ZO_TRIAL_PROGRESSION_GAMEPAD_MAX_HEADER_WIDTH = ZO_GAMEPAD_QUADRANT_1_2_3_CONTAINER_WIDTH
ZO_TRIAL_PROGRESSION_GAMEPAD_MAX_TRACKS_WIDTH = ZO_GAMEPAD_QUADRANT_1_2_3_CONTAINER_WIDTH - TRIAL_PROGRESSION_BAR_LAYOUT_PADDING_X
ZO_TRIAL_PROGRESSION_GAMEPAD_BG_WIDTH = 200

----------------------------------
-- Trial Progression Focus Area --
----------------------------------

ZO_TrialProgression_Gamepad_FocusArea = ZO_GamepadMultiFocusArea_Base:Subclass()

function ZO_TrialProgression_Gamepad_FocusArea:HandleMovement(horizontalResult, verticalResult)
    local consumed = false

    if horizontalResult == MOVEMENT_CONTROLLER_MOVE_NEXT then
        consumed = self:HandleMoveNext()
    elseif horizontalResult == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        consumed = self:HandleMovePrevious()
    end

    return consumed
end

function ZO_TrialProgression_Gamepad_FocusArea:Reset()
    self.previousFocus = nil
    self.nextFocus = nil
    self:Deactivate()
end

-------------------------------
-- Gamepad Trial Progression --
-------------------------------

ZO_TrialProgression_Gamepad = ZO_Object.MultiSubclass(ZO_TrialProgression_Shared, ZO_GamepadMultiFocusArea_Manager)

function ZO_TrialProgression_Gamepad:Initialize(control)
    ZO_TrialProgression_Shared.Initialize(self, control)

    TRIAL_PROGRESSION_SCENE_GAMEPAD = self:GetScene()
    SYSTEMS:RegisterGamepadRootScene("trialProgression", TRIAL_PROGRESSION_SCENE_GAMEPAD)

    self.layoutData =
    {
        perkSize = ZO_TRIAL_PROGRESSION_GAMEPAD_PERK_SIZE,
        bgWidth = ZO_TRIAL_PROGRESSION_GAMEPAD_BG_WIDTH,
        maxTrackWidth = ZO_TRIAL_PROGRESSION_GAMEPAD_MAX_TRACKS_WIDTH,
        maxTrackHeight = ZO_TRIAL_PROGRESSION_GAMEPAD_MAX_TRACK_HEIGHT,
        trackOffsetY = 20,
    }

    ZO_GamepadMultiFocusArea_Manager.Initialize(self, control)
end

function ZO_TrialProgression_Gamepad:InitializeControlPools()
    self.trackControlPool = ZO_ControlPool:New("ZO_TrialProgression_Gamepad_Track", self.trackContainer, "ProgressionTrack")

    self.trackControlPool:SetCustomResetBehavior(function(control)
        control.object:Reset()
        control.focusArea:Reset()
    end)

    self.trackControlPool:SetCustomFactoryBehavior(function(control)
        control.focusArea = ZO_TrialProgression_Gamepad_FocusArea:New(self)
    end)

    self.trackPointsControlPool = ZO_ControlPool:New("ZO_TrialProgression_Gamepad_Track_Points", self.trackContainer, "ProgressionTrackPoints")
end

--Overridden from base
function ZO_TrialProgression_Gamepad:OnShowing()
    ZO_TrialProgression_Shared.OnShowing(self)
    DIRECTIONAL_INPUT:Activate(self, self.control)
    local NARRATE_HEADER = true
    local NARRATE_SUB_HEADER = true
    SCREEN_NARRATION_MANAGER:QueueFocus(self.selectedTrack.object:GetFocus(), NARRATE_HEADER, NARRATE_SUB_HEADER)
end

--Overridden from base
function ZO_TrialProgression_Gamepad:OnHiding()
    ZO_TrialProgression_Shared.OnHiding(self)
    self:DeactivateCurrentFocus()
    self.selectedTrack = nil
    DIRECTIONAL_INPUT:Deactivate(self)
end

--Overridden from base
function ZO_TrialProgression_Gamepad:LayoutTracks()
    self:ClearFocusAreas()
    ZO_TrialProgression_Shared.LayoutTracks(self)
end

--Overridden from base
function ZO_TrialProgression_Gamepad:SetupTrackControl(trackControl, trackPointsLabel, trackIndex)
    ZO_TrialProgression_Shared.SetupTrackControl(self, trackControl, trackPointsLabel, trackIndex)
    trackControl.focusArea:SetActivateCallback(function()
        local indexToSelect = nil
        if self.selectedTrack then
            local INCLUDE_SAVED_INDEX = true
            indexToSelect = self.selectedTrack.object:GetSelectedFocusIndex(INCLUDE_SAVED_INDEX)
        end

        trackControl.object:ActivateFocus(indexToSelect)

        self.selectedTrack = trackControl

        self:SetSelectedTrackIndex(trackIndex)
    end)
    trackControl.focusArea:SetDeactivateCallback(function()
        trackControl.object:DeactivateFocus()
        local NO_SELECTED_INDEX = nil
        self:SetSelectedTrackIndex(NO_SELECTED_INDEX)
    end)

    self:AddNextFocusArea(trackControl.focusArea)
end

--Overridden from base
function ZO_TrialProgression_Gamepad:SelectTrack(trackControl)
    local focusAreaToSelect = trackControl.focusArea
    self:SelectFocusArea(focusAreaToSelect)
    self:ActivateFocusArea(focusAreaToSelect)
end


function ZO_TrialProgression_Gamepad:GetSceneName()
    return "trialProgression_Gamepad"
end

function ZO_TrialProgression_Gamepad:GetEventNamespace()
    return "TrialProgression_Gamepad"
end

function ZO_TrialProgression_Gamepad.OnControlInitialized(control)
    TRIAL_PROGRESSION_GAMEPAD = ZO_TrialProgression_Gamepad:New(control)
end

------------------------------------
-- ZO_TrialProgression_Track_Gamepad
------------------------------------

ZO_TrialProgression_Track_Gamepad = ZO_TrialProgression_Track_Shared:Subclass()

function ZO_TrialProgression_Track_Gamepad:Initialize(control)
    ZO_TrialProgression_Track_Shared.Initialize(self, control)
    self.focus = ZO_GamepadFocus:New(self.control, DEFAULT_MOVEMENT_CONTROLLER, MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)
    self.focus:SetFocusChangedCallback(function(focusItem)
        self:RefreshSelectedTooltip()
        --Re-narrate when the focus changes
        if focusItem then
            SCREEN_NARRATION_MANAGER:QueueFocus(self.focus)
        end
    end)
end

function ZO_TrialProgression_Track_Gamepad:InitializeControlPools()
    self.progressBarControlPool = ZO_ControlPool:New("ZO_TrialProgression_Gamepad_ProgressBar", self.control, "ProgressBar")
    self.perkControlPool = ZO_ControlPool:New("ZO_TrialProgression_Gamepad_Perk", self.control, "Perk")
end

--Overridden from base
function ZO_TrialProgression_Track_Gamepad:LayoutPerks()
    self.focus:ClearFocus()
    ZO_TrialProgression_Track_Shared.LayoutPerks(self)
end

--Overridden from base
function ZO_TrialProgression_Track_Gamepad:SetupPerkControl(perkControl, perkIndex)
    ZO_TrialProgression_Track_Shared.SetupPerkControl(self, perkControl, perkIndex)
    local focusData =
    {
        control = perkControl,
        trackIndex = perkControl.trackIndex,
        perkIndex = perkIndex,
        deactivate = function()
            self:RefreshSelectedTooltip()
        end,
        headerNarrationFunction = function()
            local narrations = {}
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetTrialProgressionTitle()))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetTrialProgressionSubtitle()))
            return narrations
        end,
        subHeaderNarrationFunction = function()
            local trackIndex = self.trackData.trackIndex
            local narrationString = zo_strformat(SI_SCREEN_NARRATION_CURRENT_AND_MAX_VALUES_FORMATTER,
                GetPointsInTrialProgressionTrackByIndex(trackIndex),
                GetPointsNeededForNextUnlockInTrialProgressionTrackByIndex(trackIndex))
            return SCREEN_NARRATION_MANAGER:CreateNarratableObject(narrationString)
        end,
        -- Selection narration handled by tooltip.
        highlight = perkControl:GetNamedChild("CircleFrameHighlight"),
    }
    local ADD_TO_FRONT = true
    self.focus:AddEntry(focusData, ADD_TO_FRONT)
end

function ZO_TrialProgression_Track_Gamepad:RefreshSelectedTooltip()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)

    local selectedData = self.focus:GetFocusItem()
    if selectedData and selectedData.trackIndex and selectedData.perkIndex then
        GAMEPAD_TOOLTIPS:LayoutTrialProgressionPassiveTooltip(GAMEPAD_RIGHT_TOOLTIP, selectedData.trackIndex, selectedData.perkIndex)
    end
end

function ZO_TrialProgression_Track_Gamepad:ActivateFocus(startingIndex)
    self.focus:Activate()
    if startingIndex then
        self.focus:SetFocusByIndex(startingIndex)
    else
        local count = self.focus:GetItemCount()
        self.focus:SetFocusByIndex(count)
    end
    local DONT_NARRATE_HEADER = false
    local NARRATE_SUB_HEADER = true
    SCREEN_NARRATION_MANAGER:QueueFocus(self.focus, DONT_NARRATE_HEADER, NARRATE_SUB_HEADER)
end

function ZO_TrialProgression_Track_Gamepad:DeactivateFocus()
    self.focus:Deactivate()
end

function ZO_TrialProgression_Track_Gamepad:GetFocus()
    return self.focus
end

function ZO_TrialProgression_Track_Gamepad:GetSelectedFocusIndex(includeSavedFocus)
    return self.focus:GetFocus(includeSavedFocus)
end

--Overridden from base
function ZO_TrialProgression_Track_Gamepad:Reset()
    ZO_TrialProgression_Track_Shared.Reset(self)
    self.focus:ClearFocus()
end