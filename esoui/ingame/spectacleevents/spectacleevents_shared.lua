ZO_SpectacleEvents_Shared = ZO_DeferredInitializingObject:Subclass()

function ZO_SpectacleEvents_Shared:Initialize(control)
    self.control = control
    ZO_DeferredInitializingObject.Initialize(self, ZO_FadeSceneFragment:New(control))

    self:InitializeActivityFinderCategory()
end

function ZO_SpectacleEvents_Shared:OnDeferredInitialize()
    self:InitializeControls()
    self.activeSpectacleEventId = SPECTACLE_EVENTS_MANAGER:GetActiveSpectacleEventId()
    self:InitializeKeybindStripDescriptor()
    self:UpdateBackground()
    self:InitializeGridList()
    self:InitializeEvents()
end

function ZO_SpectacleEvents_Shared:InitializeControls()
    local infoContainerControl = self.control:GetNamedChild("InfoContainer")
    self.infoContainerControl = infoContainerControl
    self.titleControl = infoContainerControl:GetNamedChild("Title")
    self.descriptionControl = infoContainerControl:GetNamedChild("Description")
    self.gridListControl = infoContainerControl:GetNamedChild("GridList")

    self.progressBarHeaderLabel = infoContainerControl:GetNamedChild("ProgressBarHeader")
    self.progressStatusBar = infoContainerControl:GetNamedChild("ProgressBar")
    ZO_StatusBar_SetGradientColor(self.progressStatusBar, ZO_XP_BAR_GRADIENT_COLORS)
    self.progressStatusBarLabel = self.progressStatusBar:GetNamedChild("Progress")

    self.phaseCompleteLabel = infoContainerControl:GetNamedChild("PhaseCompleteLabel")
    self.nextPhaseBeginsLabel = infoContainerControl:GetNamedChild("NextPhaseBeginsLabel")
end

function ZO_SpectacleEvents_Shared:InitializeEvents()
    function UpdateProgressInfo()
        if not self:IsShowing() then
            return
        end

        self:UpdateSpectacleProgressInfo()
    end

    EVENT_MANAGER:RegisterForUpdate(self.control:GetName(), ZO_ONE_MINUTE_IN_MILLISECONDS, UpdateProgressInfo)

    -- Update the active spectacle event identifier.
    SPECTACLE_EVENTS_MANAGER:RegisterCallback("ActiveSpectacleEventUpdated", self.SetActiveSpectacleEventId, self)

    local function OnQuestUpdated()
        if not self:IsShowing() then
            return
        end

        -- Refresh event information when the quest journal changes
        -- to properly reflect whether the active spectacle event's
        -- quest has been accepted.
        self:UpdateSpectacleEventInfo()
        self:UpdateKeybinds()
    end

    self.control:RegisterForEvent(EVENT_QUEST_ADDED, OnQuestUpdated)
    self.control:RegisterForEvent(EVENT_QUEST_REMOVED, OnQuestUpdated)
end

function ZO_SpectacleEvents_Shared:OnKeybindsUpdated(active)
    -- Can be overridden
end

function ZO_SpectacleEvents_Shared:OnShowing()
    self:UpdateSpectacleEventInfo()
    self:BuildGridList()
end

function ZO_SpectacleEvents_Shared:OnHiding()
    self:RemoveKeybinds()
end

function ZO_SpectacleEvents_Shared:AddKeybinds()
    if not (self:IsShowing() and self:CanAddKeybinds()) then
        return
    end

    if self.areKeybindsActive then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    else
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    end

    self:SetKeybindsActive(true)
end

function ZO_SpectacleEvents_Shared:CanAcceptActiveSpectacleEventQuest()
    return CanAcceptActiveSpectacleEventQuest(self.activeSpectacleEventId)
end

function ZO_SpectacleEvents_Shared:CanAddKeybinds()
    -- Can be overridden
    return true
end

function ZO_SpectacleEvents_Shared:GetCategoryData()
    return self.categoryData
end

function ZO_SpectacleEvents_Shared:GetActiveSpectacleEventQuestIndex()
    return GetActiveSpectacleEventQuestIndex(self.activeSpectacleEventId)
end

function ZO_SpectacleEvents_Shared:IsSpectacleEventActive()
    return self.activeSpectacleEventId and self.activeSpectacleEventId ~= 0
end

function ZO_SpectacleEvents_Shared:RemoveKeybinds()
    if self.areKeybindsActive then
        self:SetKeybindsActive(false)
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_SpectacleEvents_Shared:RequestBestowActiveSpectacleEventQuest()
    RequestBestowActiveSpectacleEventQuest(self.activeSpectacleEventId)
end

function ZO_SpectacleEvents_Shared:SetActiveSpectacleEventId(activeSpectacleEventId)
    if self.activeSpectacleEventId ~= activeSpectacleEventId then
        self.activeSpectacleEventId = activeSpectacleEventId
        self:UpdateSpectacleEventInfo()
    end
end

function ZO_SpectacleEvents_Shared:SetKeybindsActive(active)
    self.areKeybindsActive = active
    self:OnKeybindsUpdated(active)
end

function ZO_SpectacleEvents_Shared:ShowActiveSpectacleEventQuestOnMap()
    local questIndex = self:GetActiveSpectacleEventQuestIndex()
    if questIndex then
        ZO_WorldMap_ShowQuestOnMap(questIndex)
    end
end

function ZO_SpectacleEvents_Shared:UpdateSpectacleEventInfo()
    if not self:IsShowing() then
        return
    end

    local spectacleName = GetActiveSpectacleEventDisplayName(self.activeSpectacleEventId)
    self.titleControl:SetText(spectacleName)
    local phaseDescription = GetActiveSpectacleEventPhaseDescription(self.activeSpectacleEventId)
    self.descriptionControl:SetText(phaseDescription)

    self:UpdateSpectacleProgressInfo()

    self:UpdateKeybinds()
end

function ZO_SpectacleEvents_Shared:UpdateSpectacleProgressInfo()
    local currentPhase, numPhases = GetActiveSpectacleEventPhaseInfo(self.activeSpectacleEventId)
    local isCurrentPhaseComplete = IsCurrentActiveSpectacleEventPhaseComplete(self.activeSpectacleEventId)
    self.progressBarHeaderLabel:SetHidden(isCurrentPhaseComplete)
    self.progressStatusBar:SetHidden(isCurrentPhaseComplete)
    self.phaseCompleteLabel:SetHidden(not isCurrentPhaseComplete)
    self.nextPhaseBeginsLabel:SetHidden(not isCurrentPhaseComplete)

    if isCurrentPhaseComplete then
        local phaseCompleteString = zo_strformat(SI_SPECTACLE_EVENTS_PHASE_COMPLETE_FORMATTER, currentPhase)
        self.phaseCompleteLabel:SetText(phaseCompleteString)

        local nextPhaseBeginsString = SPECTACLE_EVENTS_MANAGER:GetActiveSpectacleEventNextPhaseBeginsString(self.activeSpectacleEventId)
        if nextPhaseBeginsString then
            self.nextPhaseBeginsLabel:SetText(nextPhaseBeginsString)
        else
            self.nextPhaseBeginsLabel:SetHidden(true)
        end
    else
        local phaseDisplayName = GetActiveSpectacleEventPhaseDisplayName(self.activeSpectacleEventId)
        local phaseInfoString = zo_strformat(SI_SPECTACLE_EVENTS_ACTIVITY_FINDER_PHASE_PROGRESS, currentPhase, numPhases, phaseDisplayName)
        self.progressBarHeaderLabel:SetText(phaseInfoString)

        local progressPercentage = GetActiveSpectacleEventPhaseProgressPercentage(self.activeSpectacleEventId)
        self.progressStatusBar:SetValue(progressPercentage)

        local formattedPercentage = string.format("%.1f", (progressPercentage * 100))
        local percentageString = zo_strformat(SI_SPECTACLE_EVENTS_PROGRESS_PERCENT, formattedPercentage)
        self.progressStatusBarLabel:SetText(percentageString)
    end
end

function ZO_SpectacleEvents_Shared:UpdateKeybinds()
    if self.activeSpectacleEventId ~= 0 then
        self:AddKeybinds()
    else
        self:RemoveKeybinds()
    end
end

function ZO_SpectacleEvents_Shared:BuildGridList()
    self.gridList:ClearGridList()

    local numAchievements = GetActiveSpectacleEventNumFeaturedAchievements(self.activeSpectacleEventId)
    for i = 1, numAchievements do
        local achievementId = GetActiveSpectacleEventFeaturedAchievementsId(self.activeSpectacleEventId, i)
        local data =
        {
            achievementId = achievementId,
        }
        self:AddGridListAchievementEntry(data)
    end

    self.gridList:CommitGridList()
end

ZO_SpectacleEvents_Shared:MUST_IMPLEMENT("InitializeActivityFinderCategory")
ZO_SpectacleEvents_Shared:MUST_IMPLEMENT("InitializeKeybindStripDescriptor")
ZO_SpectacleEvents_Shared:MUST_IMPLEMENT("InitializeGridList")
ZO_SpectacleEvents_Shared:MUST_IMPLEMENT("AddGridListAchievementEntry")
ZO_SpectacleEvents_Shared:MUST_IMPLEMENT("UpdateBackground")