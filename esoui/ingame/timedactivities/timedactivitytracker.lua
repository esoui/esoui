ZO_TimedActivityTracker = ZO_HUDTracker_Base:Subclass()

function ZO_TimedActivityTracker:Initialize(control)
    ZO_HUDTracker_Base.Initialize(self, control)

    self.headerIcon = self.headerLabel:GetNamedChild("Icon")
    self.assistedKeybindButton = self.container:GetNamedChild("HeaderAssisted")
    self.progressBar = self.container:GetNamedChild("ProgressBar")
    ZO_StatusBar_SetGradientColor(self.progressBar, ZO_XP_BAR_GRADIENT_COLORS)

    local HIDE_UNBOUND = false
    local DONT_PREFER_GAMEPAD = false
    local SHOW_AS_HOLD =
    {
        keyboard = true,
        gamepad = false,
    }
    self.assistedKeybindButton:SetKeybind("ASSIST_NEXT_TRACKED_QUEST", HIDE_UNBOUND, "GAMEPAD_CYCLE_PINNED_HUD_ACTION", DONT_PREFER_GAMEPAD, SHOW_AS_HOLD)

    TIMED_ACTIVITY_TRACKER_FRAGMENT = self:GetFragment()
    -- ESO-894612: This may not be necessary or the fix for the bug, but some players reported the tutorial firing when it shouldn't have
    -- (see ZO_TimedActivityTracker:OnShowing). Best guess is that it's not yet marked hidden via an Update call by the time the
    -- fragment gets shown via the scene. Not sure how though, and we don't have a reliable repro.
    local INSTANT = 0
    TIMED_ACTIVITY_TRACKER_FRAGMENT:SetHiddenForReason("NoTrackedTimedActivity", true, INSTANT, INSTANT)
end

function ZO_TimedActivityTracker:InitializeStyles()
    self.styles =
    {
        keyboard =
        {
            PROGRESS_BAR_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, self.subLabel, BOTTOMRIGHT, 0, 2),

            HEADER_ICON_SIZE = 25,
            HEADER_ICON_OFFSET = -2,
        },
        gamepad =
        {
            PROGRESS_BAR_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, self.subLabel, BOTTOMRIGHT, 0, 5),
            
            HEADER_ICON_SIZE = 48,
            HEADER_ICON_OFFSET = -10,
        }
    }

    ZO_HUDTracker_Base.InitializeStyles(self)
end

do
    local DISPLAY_NAME = GetString(SI_HUD_EDITOR_ASPIRATION_TRACKER)

    function ZO_TimedActivityTracker:GetHUDElementInfo()
        return DISPLAY_NAME
    end

    function ZO_TimedActivityTracker:GetHUDElementOptionKeys()
        local KEY = "Aspiration"
        return KEY, DISPLAY_NAME
    end
end

function ZO_TimedActivityTracker:RegisterEvents()
    ZO_HUDTracker_Base.RegisterEvents(self)

    local function Update()
        self:Update()
    end

    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("CampaignsUpdated", Update)
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("RewardsClaimed", Update)
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("ActivityProgressUpdated", Update)

    TIMED_ACTIVITIES_MANAGER:RegisterCallback("OnRefreshAvailability", Update)
    TIMED_ACTIVITIES_MANAGER:RegisterCallback("OnActivitiesUpdated", Update)
    TIMED_ACTIVITIES_MANAGER:RegisterCallback("OnActivityUpdated", Update)

    local achievementTrackerContainer = ACHIEVEMENT_TRACKER:GetContainerControl()
    local function AdjustHUDElementHeight()
        local assistedAspiration = HUD_TRACKER_MANAGER:GetAssistedAspiration()
        local height = 0
        if assistedAspiration == ZO_HUD_TRACKER_ASPIRATION.ACHIEVEMENT then
            height = achievementTrackerContainer:GetHeight()
        else
            height = self.container:GetHeight()
        end

        self.hudElementRef:SetHeight(height)
    end

    self.container:SetHandler("OnRectHeightChanged", AdjustHUDElementHeight)
    achievementTrackerContainer:SetHandler("OnRectHeightChanged", AdjustHUDElementHeight)

    HUD_TRACKER_MANAGER:RegisterCallback("AssistedAspirationChanged", function()
        self:Update()
        AdjustHUDElementHeight()
    end)
end

function ZO_TimedActivityTracker:Update()
    self.showingPromotionalEvent = false

    local headerText = nil
    local headerIcon = nil
    local activityName = nil
    local progress, completionThreshold = nil, nil
    local isAssisted = false
    local isTracked = false

    local promotionalEventActivityData = self:GetTrackedPromotionalEventActivityData()
    local timedActivityData = self:GetTrackedTimedActivityData()

    local assistedAspiration = HUD_TRACKER_MANAGER:GetAssistedAspiration()
    if assistedAspiration == ZO_HUD_TRACKER_ASPIRATION.PROMOTIONAL_EVENT then
        if promotionalEventActivityData then
            headerText = GetString(SI_PROMOTIONAL_EVENT_TRACKER_HEADER)
            headerIcon = "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_PromotionalEvents.dds"
            activityName = promotionalEventActivityData:GetDisplayName()
            progress, completionThreshold = promotionalEventActivityData:GetProgress(), promotionalEventActivityData:GetCompletionThreshold()
            self.showingPromotionalEvent = true
            isTracked = true
            isAssisted = true
        end
    elseif assistedAspiration == ZO_HUD_TRACKER_ASPIRATION.TIMED_ACTIVITY then
        if timedActivityData then
            headerText = GetString(SI_TAMRIEL_TOMES_TRACKER_HEADER)
            headerIcon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_tamrielTomes.dds"
            activityName = timedActivityData:GetName()
            progress, completionThreshold = timedActivityData:GetProgress(), timedActivityData:GetMaxProgress()
            isTracked = true
            isAssisted = true
        end
    else
        -- Fallback for tracked but not assisted
        isTracked = self:GetTrackedPromotionalEventActivityData() or self:GetTrackedTimedActivityData()
    end

    if headerText then
        self:SetHeaderText(headerText)
        self.headerIcon:SetTexture(headerIcon)
        self:SetSubLabelText(activityName)

        local progressBar = self.progressBar
        if completionThreshold == 1 then
            progressBar:SetHidden(true)
        else
            progressBar:SetMinMax(0, completionThreshold)
            progressBar:SetValue(progress)
            progressBar.progressBarLabel:SetText(zo_strformat(SI_CURRENT_AND_MAX_VALUES_FORMATTER, progress, completionThreshold))
            progressBar:SetHidden(false)
        end

        local trackedAchievementId = GetTrackedAchievement()
        local showAssistedKeybind = (promotionalEventActivityData and timedActivityData) or trackedAchievementId ~= 0
        self.assistedKeybindButton:SetHidden(not showAssistedKeybind)
    end

    local fragment = self:GetFragment()
    local FADE_INSTANT_MS = 0
    fragment:SetHiddenForReason("NotAssisted", not isAssisted, FADE_INSTANT_MS, FADE_INSTANT_MS)
    fragment:SetHiddenForReason("NoTrackedTimedActivity", not isTracked, DEFAULT_HUD_DURATION, DEFAULT_HUD_DURATION)

    ZO_HUDTracker_Base.Update(self)
end

function ZO_TimedActivityTracker:GetTrackedPromotionalEventActivityData()
    if not IsPromotionalEventSystemLocked() then
        local campaignKey, activityIndex = GetTrackedPromotionalEventActivityInfo()
        local campaignData = PROMOTIONAL_EVENT_MANAGER:GetCampaignDataByKey(campaignKey)
        if campaignData and campaignData:ShouldCampaignBeVisible() then
            return campaignData:GetActivityData(activityIndex)
        end
    end
    return nil
end

function ZO_TimedActivityTracker:GetTrackedTimedActivityData()
    if IsTimedActivitySystemAvailable() then
        local index = GetTrackedTimedActivityInfo()
        local activityData = index and TIMED_ACTIVITIES_MANAGER:GetActivityDataByIndex(index) or nil
        return activityData
    end
    return nil
end

function ZO_TimedActivityTracker:IsAnythingTracked()
    return self:GetTrackedPromotionalEventActivityData() ~= nil or self:GetTrackedTimedActivityData() ~= nil
end

function ZO_TimedActivityTracker:ApplyPlatformStyle(style)
    ZO_HUDTracker_Base.ApplyPlatformStyle(self, style)

    self.headerIcon:SetDimensions(style.HEADER_ICON_SIZE, style.HEADER_ICON_SIZE)
    self.headerIcon:SetAnchor(RIGHT, nil, LEFT, style.HEADER_ICON_OFFSET)
    ZO_ApplyPlatformTemplateToControl(self.assistedKeybindButton, "ZO_KeybindButton")
    ZO_ApplyPlatformTemplateToControl(self.progressBar, "ZO_HUDTracker_Base_ProgressBar")
end

function ZO_TimedActivityTracker:RefreshAnchors()
    -- ZO_HUDTracker_Base override.
    ZO_HUDTracker_Base.RefreshAnchors(self)

    local style = self.currentStyle
    self:RefreshAnchorSetOnControl(self.progressBar, style.PROGRESS_BAR_PRIMARY_ANCHOR)
end

function ZO_TimedActivityTracker:OnShowing()
    ZO_HUDTracker_Base.OnShowing(self)

    if self.showingPromotionalEvent then
        TriggerTutorial(TUTORIAL_TRIGGER_PROMOTIONAL_EVENTS_HUD_TRACKER_SHOWN)
    end
end

function ZO_TimedActivityTracker:GetPriority()
    return ZO_HUD_TRACKER_PRIORITY.TIMED_ACTIVITY
end

function ZO_TimedActivityTracker.OnControlInitialized(control)
    TIMED_ACTIVITY_TRACKER = ZO_TimedActivityTracker:New(control)
end

HUD_TRACKER_MANAGER:RegisterTracker("ZO_TimedActivityTracker_Template", "ZO_TimedActivityTracker_TL")