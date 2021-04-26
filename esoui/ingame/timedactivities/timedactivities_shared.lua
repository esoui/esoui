ZO_TimedActivities_Shared = ZO_InitializingObject:Subclass()

function ZO_TimedActivities_Shared:Initialize(control)
    self.control = control
    self.activitiesData = {}

    self:InitializeControls()
    self:InitializeFragment()
    self:InitializeRefreshGroups()
    self:InitializeActivityFinderCategory()

    local function OnRefreshAvailability(availableActivityTypes)
        self.availableActivityTypes = availableActivityTypes
        self:RefreshAvailability()
    end

    local function OnActivitiesUpdated()
        self:MarkDirty()
    end

    TIMED_ACTIVITIES_MANAGER:RegisterCallback("OnRefreshAvailability", OnRefreshAvailability)
    TIMED_ACTIVITIES_MANAGER:RegisterCallback("OnActivitiesUpdated", OnActivitiesUpdated)
    TIMED_ACTIVITIES_MANAGER:RegisterCallback("OnActivityUpdated", OnActivitiesUpdated)
end

function ZO_TimedActivities_Shared:InitializeFragment()
    self.sceneFragment = ZO_FadeSceneFragment:New(self.control)
    self.sceneFragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_SHOWN then
            self:OnShown()
        elseif newState == SCENE_FRAGMENT_HIDING then
            self:OnHiding()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end)
end

function ZO_TimedActivities_Shared:InitializeRefreshGroups()
    self.refreshGroups = ZO_Refresh:New()
    self.refreshGroups:AddRefreshGroup("FullUpdate", {
        RefreshAll = function()
            self:Refresh()
        end,
    })
    self:MarkDirty()

    self.control:SetHandler("OnUpdate", function()
        self.refreshGroups:UpdateRefreshGroups()
    end, "Refresh")
end

function ZO_TimedActivities_Shared:IsActivityTypeAvailable(activityType)
    return self.availableActivityTypes[activityType]
end

function ZO_TimedActivities_Shared:GetCurrentActivityType()
    return self.currentActivityType
end

function ZO_TimedActivities_Shared:GetCurrentActivityTypeString()
    return GetString("SI_TIMEDACTIVITYTYPE", self.currentActivityType)
end

function ZO_TimedActivities_Shared:SetCurrentActivityType(activityType)
    if activityType ~= self.currentActivityType then
        -- Order matters:
        self.currentActivityType = activityType
        self:MarkDirty()
    end
end

function ZO_TimedActivities_Shared:GetCurrentActivityTypeTimeRemainingString()
    local timeRemainingS = TIMED_ACTIVITIES_MANAGER:GetTimedActivityTypeTimeRemainingSeconds(self.currentActivityType)
    if timeRemainingS > 0 then
        return ZO_FormatTime(timeRemainingS, TIME_FORMAT_STYLE_SHOW_LARGEST_TWO_UNITS, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
    end
    return ""
end

function ZO_TimedActivities_Shared:MarkDirty()
    self.refreshGroups:RefreshAll("FullUpdate")
end

function ZO_TimedActivities_Shared:Refresh()
    assert(false) -- Must be overridden
end

function ZO_TimedActivities_Shared:RefreshAvailability()
    assert(false) -- Must be overridden
end

function ZO_TimedActivities_Shared:RefreshCurrentActivityInfo()
    assert(false) -- Must be overridden
end

function ZO_TimedActivities_Shared:InitializeControls()
    assert(false) -- Must be overridden
end

function ZO_TimedActivities_Shared:InitializeActivityFinderCategory()
    assert(false) -- Must be overridden
end

function ZO_TimedActivities_Shared:OnShowing()
    self.refreshGroups:UpdateRefreshGroups()
end

function ZO_TimedActivities_Shared:OnShown()
    -- Can be overridden
end

function ZO_TimedActivities_Shared:OnHiding()
    -- Can be overridden
end

function ZO_TimedActivities_Shared:OnHidden()
    -- Can be overridden
end