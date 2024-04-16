local HUDTracker_Manager = ZO_CallbackObject:Subclass()

function HUDTracker_Manager:New(...)
    local manager = ZO_CallbackObject.New(self)
    manager:Initialize(...)
    return manager
end

function HUDTracker_Manager:Initialize()
    local function UpdateVisibility()
        self:UpdateVisibility()
    end

    EVENT_MANAGER:RegisterForEvent("HUDTrackerManager", EVENT_ZONE_STORY_ACTIVITY_TRACKED, UpdateVisibility)
    EVENT_MANAGER:RegisterForEvent("HUDTrackerManager", EVENT_ZONE_STORY_ACTIVITY_UNTRACKED, UpdateVisibility)
    EVENT_MANAGER:RegisterForEvent("HUDTrackerManager", EVENT_ZONE_STORY_ACTIVITY_TRACKING_INIT, UpdateVisibility)

    self:UpdateVisibility()
end

function HUDTracker_Manager:UpdateVisibility()
    local isZoneStoryAssisted = IsZoneStoryAssisted()
    
    local FADE_INSTANT_MS = 0
    FOCUSED_QUEST_TRACKER:GetFragment():SetHiddenForReason("TrackingZoneStory", isZoneStoryAssisted, FADE_INSTANT_MS, FADE_INSTANT_MS)
    ZONE_STORY_TRACKER:GetFragment():SetHiddenForReason("NoTrackedZoneStory", not isZoneStoryAssisted, FADE_INSTANT_MS, FADE_INSTANT_MS)
end

HUD_TRACKER_MANAGER = HUDTracker_Manager:New()