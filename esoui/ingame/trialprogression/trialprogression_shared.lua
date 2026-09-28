ZO_TrialProgression_Shared = ZO_DeferredInitializingObject:Subclass()

local TRIAL_PROGRESSION_INTERACTION =
{
    type = "trial progression interact",
    interactTypes = { INTERACTION_TRIAL_PROGRESSION },
}

function ZO_TrialProgression_Shared:Initialize(control)
    self.control = control

    local scene = ZO_InteractScene:New(self:GetSceneName(), SCENE_MANAGER, TRIAL_PROGRESSION_INTERACTION)
    ZO_DeferredInitializingObject.Initialize(self, scene)

    self.fragment = ZO_FadeSceneFragment:New(control)
    scene:AddFragment(self.fragment)

    self:RegisterForEvents()

end

function ZO_TrialProgression_Shared:OnDeferredInitialize()
    self.trackContainer = self.control:GetNamedChild("Tracks")
    self.title = self.control:GetNamedChild("HeaderTitle")
    self.subtitle = self.control:GetNamedChild("HeaderSubtitle")
    self.numPerks = 0
    self.selectedTrackIndex = nil
    self.progressionTracks = {}

    self:InitializeControlPools()
    self:InitializeKeybindStripDescriptor()
end

function ZO_TrialProgression_Shared:InitializeKeybindStripDescriptor()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_TRIAL_PROGRESSION_KEYBIND_ATTUNE),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                ChangeAttunementForTrialProgressionTrackByIndex(self.selectedTrackIndex)
            end,
            visible = function()
                return self.selectedTrackIndex
            end,
        },
        {
            name = GetString(SI_TRIAL_PROGRESSION_KEYBIND_EXIT),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                SYSTEMS:HideScene("trialProgression")
            end,
        }
    }
end

function ZO_TrialProgression_Shared:RegisterForEvents()
    local function OnOpenTrialProgressionScreen()
        SYSTEMS:ShowScene("trialProgression")
    end

    local function OnTrialProgressionPointsChanged()
        if self:GetScene():IsShowing() then
            self:RefreshPoints()
        end
    end

    local function OnTrialProgressionAttunementChanged()
        if self:GetScene():IsShowing() then
            self:LayoutTracks()
            self:RefreshHighlights()
        end
    end

    EVENT_MANAGER:RegisterForEvent(self:GetEventNamespace(), EVENT_OPEN_TRIAL_PROGRESSION_SCREEN, ZO_GetEventForwardingFunction(self, OnOpenTrialProgressionScreen))
    EVENT_MANAGER:RegisterForEvent(self:GetEventNamespace(), EVENT_TRIAL_PROGRESSION_POINTS_CHANGED, ZO_GetEventForwardingFunction(self, OnTrialProgressionPointsChanged))
    EVENT_MANAGER:RegisterForEvent(self:GetEventNamespace(), EVENT_TRIAL_PROGRESSION_ATTUNEMENT_CHANGED, ZO_GetEventForwardingFunction(self, OnTrialProgressionAttunementChanged))
end

function ZO_TrialProgression_Shared:RefreshHeader()
    self.title:SetText(GetTrialProgressionTitle())
    self.subtitle:SetText(GetTrialProgressionSubtitle())
end

function ZO_TrialProgression_Shared:RefreshKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TrialProgression_Shared:LayoutTracks()
    self.trackControlPool:ReleaseAllObjects()
    self.trackPointsControlPool:ReleaseAllObjects()
    ZO_ClearNumericallyIndexedTable(self.progressionTracks)

    local previousTrack = nil

    --TODO Trial Progression: Figure out the upper limit of tracks where things still look good, and internal assert if we go over that
    local numTracks = GetNumTrialProgressionTracks()

    --If there are no tracks, early out
    if numTracks < 1 then
        return
    end

    local trackOffsetX = 0
    --Offset only matters if there are at least 2 tracks
    if numTracks > 1 then
        --Calculate the amount of horizontal space the tracks will take up
        --Use background texture for the width of a track as that's the widest element in the track
        local trackWidth = numTracks * self.layoutData.bgWidth

        --Calculate how big the offsets can be based on the remaining space
        trackOffsetX = (self.layoutData.maxTrackWidth - trackWidth) / (numTracks - 1)
    end

    local trackToSelect = nil
    local trackIndexToSelect = GetCurrentlyAttunedTrialProgressionTrack()

    for i = 1, numTracks do
        local trackPointsLabel = self.trackPointsControlPool:AcquireObject()

        local trackControl = self.trackControlPool:AcquireObject()
        self:SetupTrackControl(trackControl, trackPointsLabel, i)

        if (not trackToSelect) or trackIndexToSelect == i then
            trackToSelect = trackControl
        end

        if previousTrack then
            trackControl:SetAnchor(LEFT, previousTrack, RIGHT, trackOffsetX)
        else
            trackControl:SetAnchor(TOPLEFT)
        end

        trackPointsLabel:SetAnchor(TOP, trackControl, BOTTOM, 0, 10)

        table.insert(self.progressionTracks, trackControl)

        previousTrack = trackControl
    end

    self:SelectTrack(trackToSelect)
end

function ZO_TrialProgression_Shared:SetupTrackControl(trackControl, trackPointsLabel, trackIndex)
    local trackData =
    {
        numPerks = GetNumPassivesForTrialProgressionTrackByIndex(trackIndex),
        trackIndex = trackIndex,
        pointsLabel = trackPointsLabel,
        perkSize = self.layoutData.perkSize,
        maxTrackHeight = self.layoutData.maxTrackHeight,
        trackOffsetY = self.layoutData.trackOffsetY,
    }

    trackControl.object:AssignTrackData(trackData)
end

function ZO_TrialProgression_Shared:SelectTrack(trackControl)
    -- Can be overidden
end

function ZO_TrialProgression_Shared:OnShowing()
    self:RefreshHeader()
    self:LayoutTracks()
    self:RefreshHighlights()
    KEYBIND_STRIP:RemoveDefaultExit()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TrialProgression_Shared:OnHiding()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    KEYBIND_STRIP:RestoreDefaultExit()
end

function ZO_TrialProgression_Shared:SetSelectedTrackIndex(index)
    self.selectedTrackIndex = index
    self:RefreshKeybinds()
    self:RefreshHighlights()
end

function ZO_TrialProgression_Shared:RefreshHighlights()
    local currentlyAttunedTrack = GetCurrentlyAttunedTrialProgressionTrack()
    for i, track in ipairs(self.progressionTracks) do
        if  currentlyAttunedTrack == i then
            track.object.highlightTexture:SetTexture("EsoUI/Art/TrialProgression/trialProgressionHighlight_attuned.dds")
            track.object.highlightTexture:SetHidden(false)
        elseif self.selectedTrackIndex == i then
            track.object.highlightTexture:SetTexture("EsoUI/Art/TrialProgression/trialProgressionHighlight_selected.dds")
            track.object.highlightTexture:SetHidden(false)
        else
            track.object.highlightTexture:SetTexture("")
            track.object.highlightTexture:SetHidden(true)
        end
    end
end

ZO_TrialProgression_Shared:MUST_IMPLEMENT("InitializeControlPools")
ZO_TrialProgression_Shared:MUST_IMPLEMENT("GetEventNamespace")

------------------------------------
-- ZO_TrialProgression_Track_Shared
------------------------------------

ZO_TrialProgression_Track_Shared = ZO_InitializingCallbackObject:Subclass()

function ZO_TrialProgression_Track_Shared:Initialize(control)
    control.object = self
    self.control = control
    self.backgroundTexture = control:GetNamedChild("BG")
    self.highlightTexture = control:GetNamedChild("Highlight")
    self:InitializeControlPools()
end

function ZO_TrialProgression_Track_Shared:AssignTrackData(data)
    self.trackData = data

    self:LayoutPerks()
    self:RefreshPoints()

    local backgroundTexture = GetBackgroundImageForTrialProgressionTrackByIndex(data.trackIndex)
    self.backgroundTexture:SetTexture(backgroundTexture)
end

function ZO_TrialProgression_Track_Shared:LayoutPerks()
    self.progressBarControlPool:ReleaseAllObjects()
    self.perkControlPool:ReleaseAllObjects()

    --TODO Trial Progression: Figure out the upper limit of perks where things still look good, and internal assert if we go over that
    local numPerks = self.trackData.numPerks
    self.numPerks = numPerks

    --If there aren't any perks, early out
    if numPerks < 1 then
        return
    end

    local perkSize = self.trackData.perkSize
    local maxTrackHeight = self.trackData.maxTrackHeight
    local trackOffsetY = self.trackData.trackOffsetY
    local progressBarHeight = self:CalculateProgressBarHeight(numPerks, perkSize, maxTrackHeight)
    local previousPerk = nil

    for i = 1, numPerks do
        --The first perk does not get a progress bar
        local progressBarControl = nil
        if i > 1 then
            progressBarControl = self.progressBarControlPool:AcquireObject()
            self:SetupProgressBar(progressBarControl, progressBarHeight, i)

            if previousPerk then
                progressBarControl:SetAnchor(BOTTOM, previousPerk, TOP, 0, trackOffsetY)
            else
                progressBarControl:SetAnchor(BOTTOM, nil, BOTTOM)
            end
        end

        local perkControl = self.perkControlPool:AcquireObject()
        if progressBarControl then
            perkControl:SetAnchor(BOTTOM, progressBarControl, TOP, 0, trackOffsetY)
        else
            perkControl:SetAnchor(BOTTOM, nil, BOTTOM)
        end
        self:SetupPerkControl(perkControl, i)

        previousPerk = perkControl
    end
end

function ZO_TrialProgression_Track_Shared:SetupProgressBar(progressBarControl, progressBarHeight, perkIndex)
    progressBarControl.perkIndex = perkIndex

    local trackIndex = self.trackData.trackIndex
    -- Stretch gradient across all progress bars in the track
    local totalStart = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_GENERAL, INTERFACE_GENERAL_COLOR_STATUS_BAR_START))
    local totalEnd = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_GENERAL, INTERFACE_GENERAL_COLOR_STATUS_BAR_END))
    local numSegments = self.numPerks - 1
    assert(numSegments > 0, "There must be more than one perk in a tree for a progress bar to appear.")
    local startPercent = (perkIndex - 2) / numSegments
    local endPercent = (perkIndex - 1) / numSegments
    local startR, startG, startB = totalStart:GetLerpRGBA(totalEnd, startPercent)
    local endR, endG, endB = totalStart:GetLerpRGBA(totalEnd, endPercent)

    progressBarControl:SetGradientColors(startR, startG, startB, 1, endR, endG, endB, 1)

    progressBarControl:SetHeight(progressBarHeight)

    local isBarComplete = IsPassiveUnlockedInTrialProgressionTrackByIndex(trackIndex, perkIndex)
    local currentTrackPoints = GetPointsInTrialProgressionTrackByIndex(trackIndex)
    local requiredTrackPoints = GetPointsNeededForNextUnlockInTrialProgressionTrackByIndex(trackIndex)
    local progress = isBarComplete and 1 or (currentTrackPoints / requiredTrackPoints)
    progressBarControl:SetValue(progress)
end

function ZO_TrialProgression_Track_Shared:SetupPerkControl(perkControl, perkIndex)
    local trackIndex = self.trackData.trackIndex
    perkControl.trackIndex = trackIndex
    perkControl.perkIndex = perkIndex

    local iconTexture = perkControl:GetNamedChild("Icon")
    local lockTexture = iconTexture:GetNamedChild("LockIcon")
    iconTexture:SetTexture(GetIconForPassiveInTrialProgressionTrackByIndex(trackIndex, perkIndex))
    local isPerkUnlocked = IsTrialProgressionTrackAttunedByIndex(trackIndex) and IsPassiveUnlockedInTrialProgressionTrackByIndex(trackIndex, perkIndex)
    lockTexture:SetHidden(isPerkUnlocked)
    if isPerkUnlocked then
        iconTexture:SetDesaturation(0)
    else
        iconTexture:SetDesaturation(1)
    end
end

function ZO_TrialProgression_Track_Shared:CalculateProgressBarHeight(numPerks, perkSize, maxTrackHeight)
    local progressBarHeight = 0
    --Progress bar height only matters if there are at least 2 perks
    if numPerks > 1 then
        --Calculate how tall each section of progress bar will be based on the number of perks
        local totalPerkHeight = perkSize * numPerks
        local totalProgressBarHeight = maxTrackHeight - totalPerkHeight
        progressBarHeight = totalProgressBarHeight / (numPerks - 1)
    end

    return progressBarHeight
end

function ZO_TrialProgression_Track_Shared:RefreshPoints()
    local pointsLabel = self.trackData.pointsLabel
    if pointsLabel then
        local currentPoints = GetPointsInTrialProgressionTrackByIndex(self.trackData.trackIndex)
        local maxPoints = GetPointsNeededForNextUnlockInTrialProgressionTrackByIndex(self.trackData.trackIndex)

        local pointsText = zo_strformat(SI_TRIAL_PROGRESSION_TRACK_POINT_FORMAT, currentPoints, maxPoints)
        pointsLabel:SetText(pointsText)
    end
end

function ZO_TrialProgression_Track_Shared:GetTrackData()
    return self.trackData
end

function ZO_TrialProgression_Track_Shared:GetControl()
    return self.control
end

function ZO_TrialProgression_Track_Shared:Reset()
    self.trackData = nil
    self.numPerks = 0
    self.control:SetHidden(true)
    self.backgroundTexture:SetTexture("")
    self.progressBarControlPool:ReleaseAllObjects()
    self.perkControlPool:ReleaseAllObjects()
end

ZO_TrialProgression_Shared:MUST_IMPLEMENT("GetSceneName")
ZO_TrialProgression_Track_Shared:MUST_IMPLEMENT("InitializeControlPools")