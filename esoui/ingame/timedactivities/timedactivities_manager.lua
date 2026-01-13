local PRIMARY_SYSTEM_CURRENCY = CURT_SEALS

-- Timed Activity Data --

ZO_TimedActivityData = ZO_InitializingObject:Subclass()

function ZO_TimedActivityData:Initialize(index)
    self.index = index
    -- For troubleshooting purposes only
    self.timedActivityId = GetTimedActivityId(index)
    self.encodedId = GetTimedActivityEncodedId(index)
end

function ZO_TimedActivityData:GetIndex()
    return self.index
end

function ZO_TimedActivityData:GetId()
    return self.timedActivityId
end

function ZO_TimedActivityData:GetEncodedId()
    return self.encodedId
end

function ZO_TimedActivityData:GetName()
    return GetTimedActivityName(self.index)
end

function ZO_TimedActivityData:GetDescription()
    return GetTimedActivityDescription(self.index)
end

function ZO_TimedActivityData:GetType()
    return GetTimedActivityType(self.index)
end

function ZO_TimedActivityData:IsDailyActivity()
    return self:GetType() == TIMED_ACTIVITY_TYPE_DAILY
end

function ZO_TimedActivityData:IsWeeklyActivity()
    return self:GetType() == TIMED_ACTIVITY_TYPE_WEEKLY
end

function ZO_TimedActivityData:IsSeasonalActivity()
    return self:GetType() == TIMED_ACTIVITY_TYPE_SEASONAL
end

function ZO_TimedActivityData:GetDifficulty()
    return GetTimedActivityDifficulty(self.index)
end

function ZO_TimedActivityData:GetNumRewards()
    return GetNumTimedActivityRewards(self.index)
end

function ZO_TimedActivityData:GetRewardInfo(rewardIndex)
    local rewardId, rewardQuantity = GetTimedActivityRewardInfo(self.index, rewardIndex)
    return rewardId, rewardQuantity
end

function ZO_TimedActivityData:GetCurrencyRewardInfo()
    local rewardCurrency, rewardCurrencyAmount = GetTimedActivityCurrencyRewardInfo(self.index)
    return rewardCurrency, rewardCurrencyAmount
end

function ZO_TimedActivityData:GetProgress()
    return GetTimedActivityProgress(self.index)
end

function ZO_TimedActivityData:GetMaxProgress()
    return GetTimedActivityMaxProgress(self.index)
end

function ZO_TimedActivityData:IsCompleted()
    -- IsCompleted here means that the current progress is at maximum. It may or may not also be claimable or (CanClaim) fully claimed (IsFullyClaimed).
    -- This definition of complete differs from the backend, which considers fully claimed activities to be "complete".
    return self:GetProgress() >= self:GetMaxProgress()
end

function ZO_TimedActivityData:GetEndTimeS()
    return GetTimedActivityEndTimeS(self.index)
end

function ZO_TimedActivityData:GetTimeRemainingS()
    local activeSeasonEndTimeS = TIMED_ACTIVITIES_MANAGER:GetActiveSeasonEndTimeS()
    if activeSeasonEndTimeS then
        local endTimeS = self:GetEndTimeS()
        -- Any activity that ends when the season ends we don't want to show the time for
        if endTimeS > 0 and endTimeS ~= activeSeasonEndTimeS then
            return zo_max(0, endTimeS - GetTimeStamp())
        end
    end
    return nil -- No end time, so time remaining is infinite
end

do
    local function TimedActivityRewardComparator(left, right)
        local leftRewardId = left:GetRewardId()
        local rightRewardId = right:GetRewardId()
        local leftQuanitity = left:GetQuantity()
        local rightQuanitity = right:GetQuantity()

        if leftRewardId == rightRewardId then
            -- Same rewards fall back to quantity (shouldn't happen)
            return leftQuanitity > rightQuanitity
        end

        local leftRewardType = left:GetRewardType()
        local rightRewardType = right:GetRewardType()

        if leftRewardType ~= rightRewardType then
            if leftRewardType == REWARD_ENTRY_TYPE_ADD_CURRENCY then
                -- Currency reward before non-currnecy reward
                return true
            elseif rightRewardType == REWARD_ENTRY_TYPE_ADD_CURRENCY then
                -- Non-currency reward after currency rewards
                return false
            else
                -- Order non-currencies by reward type
                return leftRewardType < rightRewardType
            end
        end

        -- Same type of reward
        if leftRewardType == REWARD_ENTRY_TYPE_ADD_CURRENCY then
            local leftCurrencyType = left:GetCurrencyType()
            local rightCurrencyType = right:GetCurrencyType()

            if leftCurrencyType ~= rightCurrencyType then
                if leftCurrencyType == PRIMARY_SYSTEM_CURRENCY then
                    -- The system's primary currency before secondary currencies
                    return true
                elseif rightCurrencyType == PRIMARY_SYSTEM_CURRENCY then
                    -- Secondary currencies after the system's primary currency
                    return false
                else
                    -- Fall back to currency type order
                    return leftCurrencyType < rightCurrencyType
                end
            end
            -- Fall back to default behavior (shouldn't happen)
        elseif leftRewardType == REWARD_ENTRY_TYPE_SKILL_LINE_EXPERIENCE then
            local leftSkillLineId = left:GetSkillLineId()
            local rightSkillLineId = right:GetSkillLineId()
            if leftSkillLineId ~= rightSkillLineId then
                -- Order by skill line id
                return leftSkillLineId < rightSkillLineId
            end
            -- Fall back to default behavior (shouldn't happen)
        elseif leftRewardType == REWARD_ENTRY_TYPE_EXPERIENCE then
            -- Fall back to default behavior (shouldn't happen)
        else
            -- Report unsupported type, fall back to default behavior
            internalassert(false, string.format("Unsupported reward type %d for Timed Activities", leftRewardType))
        end

        -- Default behavior
        if leftQuanitity == rightQuanitity then
            -- Ultimate fall back to reward id
            return leftRewardId > rightRewardId
        else
            -- Fall back to quantity
            return leftQuanitity > rightQuanitity
        end
    end

    function ZO_TimedActivityData:GetRewardList()
        if not self.rewardList then
            self.rewardList = {}
            local numRewards = self:GetNumRewards()
            if numRewards > 0 then
                for rewardIndex = 1, numRewards do
                    local rewardId, quantity = self:GetRewardInfo(rewardIndex)
                    local rewardData = REWARDS_MANAGER:GetInfoForReward(rewardId, quantity)
                    table.insert(self.rewardList, rewardData)
                end

                table.sort(self.rewardList, TimedActivityRewardComparator)
            end
        end
        return self.rewardList
    end
end

function ZO_TimedActivityData:GetTotalNumTimesClaimable()
    return GetTimedActivityTotalNumTimesClaimable(self.index)
end

function ZO_TimedActivityData:GetNumTimesClaimed()
    return GetTimedActivityNumTimesClaimed(self.index)
end

function ZO_TimedActivityData:IsFullyClaimed()
    -- TODO Tamriel Tomes: Account for infinitely repeatable activities (TotalNumTimesClaimable of 0)
    return self:GetNumTimesClaimed() == self:GetTotalNumTimesClaimable()
end

function ZO_TimedActivityData:CanClaim()
    return not self:IsFullyClaimed() and self:IsCompleted()
end

function ZO_TimedActivityData:Claim()
    ClaimTimedActivityReward(self.index)
end

function ZO_TimedActivityData:CanReroll()
    return self:GetNumTimesClaimed() == 0 and not self:IsSeasonalActivity()
end

function ZO_TimedActivityData:Reroll()
    local result = RerollTimedActivity(self.index)
    return result
end

function ZO_TimedActivityData:CanTrack()
    local numTimesClaimed = self:GetNumTimesClaimed()
    local numTimesClaimable = self:GetTotalNumTimesClaimable()
    local numClaimsRemaining = numTimesClaimable - numTimesClaimed
    if numClaimsRemaining > 1 then
        return true
    elseif numClaimsRemaining == 1 then
        return not self:IsCompleted()
    end
    return false
end

function ZO_TimedActivityData:IsTracked()
    local index = GetTrackedTimedActivityInfo()
    return self.index == index
end

function ZO_TimedActivityData:ToggleTracking(suppressSound)
    if self:IsTracked() then
        ClearTrackedTimedActivity()
        if not suppressSound then
            PlaySound(SOUNDS.TRACK_TIMED_ACTIVITY_UNCLICK)
        end
    else
        TrackTimedActivity(self.index)
        if not suppressSound then
            PlaySound(SOUNDS.TRACK_TIMED_ACTIVITY_CLICK)
        end
    end
end

function ZO_TimedActivityData:Equals(otherData)
    return AreId64sEqual(self:GetEncodedId(), otherData:GetEncodedId())
end

-- Timed Activities Manager --

ZO_TimedActivities_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_TimedActivities_Manager:Initialize()
    self.availableActivityTypes = {}
    self.activitiesData = {}

    self:RefreshMasterList()
    self:RegisterEvents()
end

function ZO_TimedActivities_Manager:RefreshAvailability()
    local isSystemAvailable = IsTimedActivitySystemAvailable()

    for activityType = TIMED_ACTIVITY_TYPE_MIN_VALUE, TIMED_ACTIVITY_TYPE_MAX_VALUE do
        self.availableActivityTypes[activityType] = isSystemAvailable and self:GetNumTimedActivities(activityType) > 0
    end

    self:FireCallbacks("OnRefreshAvailability", self.availableActivityTypes)
end

function ZO_TimedActivities_Manager:GetAvailableActivityTypes()
    return self.availableActivityTypes
end

function ZO_TimedActivities_Manager:RefreshMasterList()
    ZO_ClearNumericallyIndexedTable(self.activitiesData)

    local numTimedActivities = GetNumTimedActivities()
    for index = 1, numTimedActivities do
        local timedActivityData = ZO_TimedActivityData:New(index)
        table.insert(self.activitiesData, timedActivityData)
    end

    self:RefreshAvailability()
    self:FireCallbacks("OnActivitiesUpdated")
end

function ZO_TimedActivities_Manager:RefreshSingleMasterListItem(index)
    self.activitiesData[index] = ZO_TimedActivityData:New(index)

    self:RefreshAvailability()
    self:FireCallbacks("OnActivityUpdated", index)
end

function ZO_TimedActivities_Manager:RegisterEvents()
    local function OnActivitiesUpdated()
        self:RefreshMasterList()
    end

    local function OnActivityUpdated(_, index)
        self:RefreshSingleMasterListItem(index)
    end

    local function OnSystemStatusUpdated()
        self:RefreshAvailability()
    end

    local function UpdateSeasonEndTime()
        local endTimeS = GetActiveTamrielTomeSeasonEndTimeS()
        self.activeSeasonEndTimeS = endTimeS > 0 and endTimeS or nil
    end

    local function OnPlayerActivated()
        self:RefreshMasterList()
        UpdateSeasonEndTime()
    end

    EVENT_MANAGER:RegisterForEvent("TimedActivitiesManager", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
    EVENT_MANAGER:RegisterForEvent("TimedActivitiesManager", EVENT_TIMED_ACTIVITIES_UPDATED, OnActivitiesUpdated)
    EVENT_MANAGER:RegisterForEvent("TimedActivitiesManager", EVENT_TIMED_ACTIVITY_TRACKING_UPDATED, OnActivitiesUpdated)
    EVENT_MANAGER:RegisterForEvent("TimedActivitiesManager", EVENT_TIMED_ACTIVITY_PROGRESS_UPDATED, OnActivityUpdated)
    EVENT_MANAGER:RegisterForEvent("TimedActivitiesManager", EVENT_TIMED_ACTIVITY_SYSTEM_STATUS_UPDATED, OnSystemStatusUpdated)
    EVENT_MANAGER:RegisterForEvent("TimedActivitiesManager", EVENT_OPEN_TIMED_ACTIVITIES, ZO_ShowTimedActivities)


    EVENT_MANAGER:RegisterForEvent("TimedActivitiesManager", EVENT_HOLIDAYS_CHANGED, UpdateSeasonEndTime)
end

function ZO_TimedActivities_Manager:ActivitiesIterator(filterFunctions)
    return ZO_FilteredNumericallyIndexedTableIterator(self.activitiesData, filterFunctions)
end

function ZO_TimedActivities_Manager:GetFirstActivityDataByFilter(filterFunctions)
    for index, activityData in TIMED_ACTIVITIES_MANAGER:ActivitiesIterator(filterFunctions) do
        return activityData
    end
    return nil
end

function ZO_TimedActivities_Manager:GetActivityDataByTypeAndId(timedActivityType, timedActivityId)
    local function ActivityMatches(activityData)
        return activityData:GetType() == timedActivityType and activityData:GetId() == timedActivityId
    end
    return self:GetFirstActivityDataByFilter({ ActivityMatches })
end

function ZO_TimedActivities_Manager:GetActivityDataByIndex(activityIndex)
    return self.activitiesData[activityIndex]
end

function ZO_TimedActivities_Manager.GetPrimaryTimedActivitiesCurrencyType()
    return PRIMARY_SYSTEM_CURRENCY
end

function ZO_TimedActivities_Manager:GetTimedActivityTypeTimeRemainingSeconds(timedActivityType)
    local endTimeS = GetTimedActivityTypeResetTimeS(timedActivityType)
    return zo_max(0, endTimeS - GetTimeStamp())
end

function ZO_TimedActivities_Manager:GetNumTimedActivities(activityType)
    local numActivities = 0
    for _, timedActivity in self:ActivitiesIterator() do
        if timedActivity:GetType() == activityType then
            numActivities = numActivities + 1
        end
    end
    return numActivities
end

function ZO_TimedActivities_Manager.GetNumRemainingRerollAttempts()
    local currencyAmount = GetPlayerStoredCurrencyAmount(CURT_TOME_CHALLENGE_REROLLS)
    return currencyAmount
end

function ZO_TimedActivities_Manager:GetActiveSeasonEndTimeS()
    return self.activeSeasonEndTimeS
end

function ZO_ShowTimedActivities()
    local scene = IsInGamepadPreferredMode() and "TimedActivitiesGamepad" or "TimedActivitiesKeyboard"
    SCENE_MANAGER:Push(scene)
end

function ZO_ShowSealStore()
    if IsInGamepadPreferredMode() then
        SYSTEMS:GetObject("mainMenu"):SelectMenuEntryAndSubEntry(ZO_MENU_MAIN_ENTRIES.CROWN_STORE, ZO_MENU_CROWN_STORE_ENTRIES.ENDEAVOR_SEAL_STORE, "gamepad_endeavor_seal_market_pre_scene")
    else
        SYSTEMS:GetObject("mainMenu"):ShowSceneGroup("marketSceneGroup", "endeavorSealStoreSceneKeyboard")
    end
end

TIMED_ACTIVITIES_MANAGER = ZO_TimedActivities_Manager:New()