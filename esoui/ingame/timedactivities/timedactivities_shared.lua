ZO_TimedActivities_Shared = ZO_InitializingObject:Subclass()

function ZO_TimedActivities_Shared:Initialize(control)
    self.control = control
    self.sceneFragment = ZO_FadeSceneFragment:New(control)
end

-- Gamepad and keyboard get there from different directions, but both have a route to OnDeferredInitialize
function ZO_TimedActivities_Shared:OnDeferredInitialize()
    self:InitializeControls()
    self:InitializeRefreshGroups()

    self.availableActivityTypes = TIMED_ACTIVITIES_MANAGER:GetAvailableActivityTypes()

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

        -- eventId, currencyType, currencyLocation, delta, reason, reasonInfo
    local function OnCurrencyUpdated(_, currencyType)
        if not self.control:IsHidden() then
            if currencyType == CURT_TOME_CHALLENGE_REROLLS then
                self:OnRerollCurrencyUpdated()
            end
        end
    end

    self.control:RegisterForEvent(EVENT_CURRENCY_UPDATE, OnCurrencyUpdated)
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
    self:RefreshList(currentActivityType, activityEntries)
    self:RefreshAvailability()
    self:RefreshCurrentActivityInfo()
end

-- To be overridden and use the return to populate the platform list format
function ZO_TimedActivities_Shared:RefreshList()
    local currentActivityType = self:GetCurrentActivityType()
    local activityTypeFilters
    if currentActivityType == TIMED_ACTIVITY_TYPE_WEEKLY then
        activityTypeFilters = { ZO_TimedActivityData.IsWeeklyActivity }
    elseif currentActivityType == TIMED_ACTIVITY_TYPE_SEASONAL then
        activityTypeFilters = { ZO_TimedActivityData.IsSeasonalActivity }
    end

    local activityEntries = {}
    for index, activityData in TIMED_ACTIVITIES_MANAGER:ActivitiesIterator(activityTypeFilters) do
        table.insert(activityEntries, ZO_EntryData:New(activityData))
    end

    return currentActivityType, activityEntries
end

function ZO_TimedActivities_Shared:RefreshAvailability()
    local activityType = self:GetCurrentActivityType()
    local isAvailable = self:IsActivityTypeAvailable(activityType)
    local emptyMessage = nil
    if not isAvailable then
        local activityTypeName = GetString("SI_TIMEDACTIVITYTYPE", activityType)
        emptyMessage = zo_strformat(SI_TIMED_ACTIVITIES_EMPTY_LIST, activityTypeName)
    end
    return isAvailable, emptyMessage
end

function ZO_TimedActivities_Shared.SetupClaimProgress(timedActivityData, claimableLabel, checkboxControlPool)
    checkboxControlPool:ReleaseAllObjects()

    local isFullyClaimedOrExpired = timedActivityData:IsFullyClaimedOrExpired()
    local numTimesClaimed = timedActivityData:GetNumTimesClaimed()
    local totalNumTimesClaimable = timedActivityData:GetTotalNumTimesClaimable()
    if totalNumTimesClaimable <= 5 then
        if totalNumTimesClaimable == 0 then
            claimableLabel:SetText(GetString(SI_TIMED_ACTIVITY_INFINITELY_REPEATABLE))
        else
            claimableLabel:SetText(" ") -- Force a height so the time remaining label can anchor nicely
        end

        local previousCheckboxControl = nil
        for i = 1, totalNumTimesClaimable do
            local checkboxControl = checkboxControlPool:AcquireObject()
            checkboxControl:SetParent(claimableLabel)
            if previousCheckboxControl then
                checkboxControl:SetAnchor(BOTTOMLEFT, previousCheckboxControl, BOTTOMRIGHT, 5)
            else
                checkboxControl:SetAnchor(BOTTOMLEFT, claimableLabel)
            end

            if i <= numTimesClaimed then
                checkboxControl:SetCheckState(TRISTATE_CHECK_BUTTON_CHECKED)
            else
                checkboxControl:SetCheckState(TRISTATE_CHECK_BUTTON_UNCHECKED)
            end

            ZO_ReadonlyCheckButton_SetEnableState(checkboxControl, not isFullyClaimedOrExpired)

            previousCheckboxControl = checkboxControl
        end
    else
        local formatter = isFullyClaimedOrExpired and SI_TIMED_ACTIVITY_CLAIMED_PROGRESS_DISABLED or SI_TIMED_ACTIVITY_CLAIMED_PROGRESS
        claimableLabel:SetText(zo_strformat(formatter, numTimesClaimed, totalNumTimesClaimable))
    end

    local claimableLabelColor = isFullyClaimedOrExpired and ZO_NORMAL_TEXT:GetDim() or ZO_NORMAL_TEXT
    claimableLabel:SetColor(claimableLabelColor:UnpackRGBA())
end

function ZO_TimedActivities_Shared.RefreshTimeRemaining(timedActivityData, timeRemainingLabel)
    local timeRemainingS = timedActivityData:GetTimeRemainingS()
    if timeRemainingS then
        local isFullyClaimed = timedActivityData:IsFullyClaimed()
        local timeRemainingText
        if timeRemainingS == 0 then
            timeRemainingText = zo_strformat(SI_TIMED_ACTIVITY_TIME_REMAINING, GetString(SI_TIMED_ACTIVITY_TIME_EXPIRED))
            timeRemainingText = ZO_ERROR_COLOR:ColorizeDim(timeRemainingText)
        else
            timeRemainingText = ZO_FormatTimeLargestTwo(timeRemainingS, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL)
            if isFullyClaimed then
                timeRemainingText = ZO_WHITE:ColorizeDim(timeRemainingText)
            else
                timeRemainingText = ZO_WHITE:Colorize(timeRemainingText)
            end
        end
        local timeRemainingColor = isFullyClaimed and ZO_NORMAL_TEXT:GetDim() or ZO_NORMAL_TEXT
        timeRemainingLabel:SetColor(timeRemainingColor:UnpackRGBA())
        timeRemainingLabel:SetText(zo_strformat(SI_TIMED_ACTIVITY_TIME_REMAINING, timeRemainingText))
        timeRemainingLabel:SetHidden(false)

        if timeRemainingS > ZO_ONE_DAY_IN_SECONDS + ZO_ONE_HOUR_IN_SECONDS then
            timeRemainingLabel.nextUpdateS = GetFrameTimeSeconds() + ZO_ONE_HOUR_IN_SECONDS
        elseif timeRemainingS > ZO_ONE_HOUR_IN_SECONDS + ZO_ONE_MINUTE_IN_SECONDS then
            timeRemainingLabel.nextUpdateS = GetFrameTimeSeconds() + ZO_ONE_MINUTE_IN_SECONDS
        else
            timeRemainingLabel.nextUpdateS = GetFrameTimeSeconds() + 1
        end

        if not timeRemainingLabel:IsHandlerSet("OnUpdate") then
            timeRemainingLabel:SetHandler("OnUpdate", function(_, frameTimeS)
                if frameTimeS > timeRemainingLabel.nextUpdateS then
                    ZO_TimedActivities_Shared.RefreshTimeRemaining(timedActivityData, timeRemainingLabel)
                end
            end)
        end
    else
        timeRemainingLabel:SetHidden(true)
    end
end

ZO_TimedActivities_Shared:MUST_IMPLEMENT("RefreshCurrentActivityInfo")
ZO_TimedActivities_Shared:MUST_IMPLEMENT("InitializeControls")
ZO_TimedActivities_Shared:MUST_IMPLEMENT("OnRerollCurrencyUpdated")

function ZO_TimedActivities_Shared:OnShowing()
    self.refreshGroups:UpdateRefreshGroups()
end

function ZO_TimedActivities_Shared:OnShown()
    TriggerTutorial(TUTORIAL_TRIGGER_TAMRIEL_TOMES_CHALLENGES_OPENED)
end

function ZO_TimedActivities_Shared:OnHiding()
    -- Can be overridden
end

function ZO_TimedActivities_Shared:OnHidden()
    -- Can be overridden
end