local PRIMARY_SYSTEM_CURRENCY = CURT_ENDEAVOR_SEALS

-- Timed Activity Data --

ZO_TimedActivityData = ZO_InitializingObject:Subclass()

function ZO_TimedActivityData:Initialize(index)
    self.index = index
    -- For troubleshooting purposes only
    self.timedActivityId = GetTimedActivityId(index)
end

function ZO_TimedActivityData:GetIndex()
    return self.index
end

function ZO_TimedActivityData:GetId()
    return self.timedActivityId
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

function ZO_TimedActivityData:GetNumRewards()
    return GetNumTimedActivityRewards(self.index)
end

function ZO_TimedActivityData:GetRewardInfo(rewardIndex)
    local rewardId, rewardQuantity = GetTimedActivityRewardInfo(self.index, rewardIndex)
    return rewardId, rewardQuantity
end

function ZO_TimedActivityData:GetProgress()
    return GetTimedActivityProgress(self.index)
end

function ZO_TimedActivityData:GetMaxProgress()
    return GetTimedActivityMaxProgress(self.index)
end

function ZO_TimedActivityData:IsCompleted()
    return self:GetProgress() >= self:GetMaxProgress()
end

function ZO_TimedActivityData:GetTimeRemainingS()
    return GetTimedActivityTimeRemainingSeconds(self.index)
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

-- Timed Activities Manager --

local ZO_TimedActivities_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_TimedActivities_Manager:Initialize()
    self.availableActivityTypes = {}
    self.activitiesData = {}

    self.activityTypeLimitData = {}
    for activityType = TIMED_ACTIVITY_TYPE_MIN_VALUE, TIMED_ACTIVITY_TYPE_MAX_VALUE do
        self.activityTypeLimitData[activityType] =
        {
            completed = 0,
            limit = GetTimedActivityTypeLimit(activityType),
        }
    end

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

function ZO_TimedActivities_Manager:RefreshMasterList()
    ZO_ClearNumericallyIndexedTable(self.activitiesData)

    local numTimedActivities = GetNumTimedActivities()
    for index = 1, numTimedActivities do
        local timedActivityData = ZO_TimedActivityData:New(index)
        self.activitiesData[index] = timedActivityData
    end

    self:RefreshTimedActivityTypeLimitData()
    self:RefreshAvailability()
    self:FireCallbacks("OnActivitiesUpdated")
end

function ZO_TimedActivities_Manager:RefreshSingleMasterListItem(index)
    self.activitiesData[index] = ZO_TimedActivityData:New(index)

    self:RefreshTimedActivityTypeLimitData()
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

    EVENT_MANAGER:RegisterForEvent("TimedActivitiesManager", EVENT_PLAYER_ACTIVATED, OnActivitiesUpdated)
    EVENT_MANAGER:RegisterForEvent("TimedActivitiesManager", EVENT_TIMED_ACTIVITIES_UPDATED, OnActivitiesUpdated)
    EVENT_MANAGER:RegisterForEvent("TimedActivitiesManager", EVENT_TIMED_ACTIVITY_PROGRESS_UPDATED, OnActivityUpdated)
    EVENT_MANAGER:RegisterForEvent("TimedActivitiesManager", EVENT_TIMED_ACTIVITY_SYSTEM_STATUS_UPDATED, OnSystemStatusUpdated)
    EVENT_MANAGER:RegisterForEvent("TimedActivitiesManager", EVENT_OPEN_TIMED_ACTIVITIES, ZO_ShowTimedActivities)
end

function ZO_TimedActivities_Manager:ActivitiesIterator(filterFunctions)
    return ZO_FilteredNonContiguousTableIterator(self.activitiesData, filterFunctions)
end

function ZO_TimedActivities_Manager:GetActivityDataByIndex(activityIndex)
    return self.activitiesData[activityIndex]
end

function ZO_TimedActivities_Manager.GetPrimaryTimedActivitiesCurrencyType()
    return PRIMARY_SYSTEM_CURRENCY
end

function ZO_TimedActivities_Manager:GetTimedActivityTypeTimeRemainingSeconds(timedActivityType)
    local filterFunctions
    if timedActivityType == TIMED_ACTIVITY_TYPE_DAILY then
        filterFunctions = {ZO_TimedActivityData.IsDailyActivity}
    elseif timedActivityType == TIMED_ACTIVITY_TYPE_WEEKLY then
        filterFunctions = {ZO_TimedActivityData.IsWeeklyActivity}
    else
        return 0
    end

    local minimumTimeRemainingS = nil
    for _, timedActivity in self:ActivitiesIterator(filterFunctions) do
        local timeRemainingS = timedActivity:GetTimeRemainingS()
        if timeRemainingS > 0 and (not minimumTimeRemainingS or timeRemainingS < minimumTimeRemainingS) then
            minimumTimeRemainingS = timeRemainingS
        end
    end

    return minimumTimeRemainingS or 0
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

function ZO_TimedActivities_Manager:RefreshTimedActivityTypeLimitData()
    for activityType = TIMED_ACTIVITY_TYPE_MIN_VALUE, TIMED_ACTIVITY_TYPE_MAX_VALUE do
        self.activityTypeLimitData[activityType].completed = 0
    end

    for _, timedActivity in self:ActivitiesIterator() do
        if timedActivity:IsCompleted() then
            local activityType = timedActivity:GetType()
            self.activityTypeLimitData[activityType].completed = self.activityTypeLimitData[activityType].completed + 1
        end
    end
end

function ZO_TimedActivities_Manager:GetTimedActivityTypeLimitInfo(activityType)
    local limitData = self.activityTypeLimitData[activityType]
    return limitData.completed, limitData.limit
end

function ZO_TimedActivities_Manager:IsAtTimedActivityTypeLimit(activityType)
    local numActivitiesCompleted, activityLimit = self:GetTimedActivityTypeLimitInfo(activityType)
    return numActivitiesCompleted >= activityLimit
end

function ZO_ShowTimedActivities()
    if IsInGamepadPreferredMode() then
        ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:ShowCategory(TIMED_ACTIVITIES_GAMEPAD:GetCategoryData())
    else
        GROUP_MENU_KEYBOARD:ShowCategory(TIMED_ACTIVITIES_FRAGMENT)
    end
end

function ZO_ShowSealStore()
    if IsInGamepadPreferredMode() then
        SYSTEMS:GetObject("mainMenu"):SelectMenuEntryAndSubEntry(ZO_MENU_MAIN_ENTRIES.CROWN_STORE, ZO_MENU_CROWN_STORE_ENTRIES.ENDEAVOR_SEAL_STORE, "gamepad_endeavor_seal_market_pre_scene")
    else
        SYSTEMS:GetObject("mainMenu"):ShowSceneGroup("marketSceneGroup", "endeavorSealStoreSceneKeyboard")
    end
end

TIMED_ACTIVITIES_MANAGER = ZO_TimedActivities_Manager:New()