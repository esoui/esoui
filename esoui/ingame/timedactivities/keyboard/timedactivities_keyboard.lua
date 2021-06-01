ZO_TimedActivities_Keyboard = ZO_TimedActivities_Shared:Subclass()

local COMPLETE_ACTIVITY_ALPHA = 0.4
local INCOMPLETE_ACTIVITY_ALPHA = 1

function ZO_TimedActivities_Keyboard:RefreshCurrentActivityInfo()
    local timeRemainingString = self:GetCurrentActivityTypeTimeRemainingString()
    if timeRemainingString ~= "" then
        self.expirationHeader:SetText(zo_strformat(SI_TIMED_ACTIVITIES_ACTIVITY_EXPIRATION_HEADER, ZO_SELECTED_TEXT:Colorize(timeRemainingString)))
    else
        self.expirationHeader:SetText("")
    end

    local currentActivityType = self:GetCurrentActivityType()
    local numActivitiesCompleted, activityLimit = TIMED_ACTIVITIES_MANAGER:GetTimedActivityTypeLimitInfo(currentActivityType)
    self.limitHeader:SetText(zo_strformat(SI_TIMED_ACTIVITIES_ACTIVITY_LIMIT_HEADER, numActivitiesCompleted, activityLimit))
end

function ZO_TimedActivities_Keyboard:AddActivityRow(activityData)
    local activityRow = self.activityRowPool:AcquireObject()
    local anchorTo = self.nextActivityAnchorTo
    if anchorTo then
        activityRow:SetAnchor(TOPLEFT, anchorTo, BOTTOMLEFT)
        activityRow:SetAnchor(TOPRIGHT, anchorTo, BOTTOMRIGHT)
    else
        activityRow:SetAnchor(TOPLEFT, self.activitiesScrollChild)
        activityRow:SetAnchor(TOPRIGHT, self.activitiesScrollChild)
    end
    self.nextActivityAnchorTo = activityRow

    activityRow.nameLabel:SetText(activityData:GetName())
    activityRow.activityDescription = activityData:GetDescription()

    local maxProgress = activityData:GetMaxProgress()
    local progress = activityData:GetProgress()
    if maxProgress < 1 or progress >= maxProgress then
        progressPercent = 1
    else
        progressPercent = progress / maxProgress
    end
    activityRow.progressStatusBar:SetValue(progressPercent)

    if progressPercent < 1 then
        local progressString = zo_strformat(SI_TIMED_ACTIVITIES_ACTIVITY_COMPLETION_VALUES, progress, maxProgress)
        activityRow.progressStatusBarLabel:SetText(progressString)
        activityRow.progressStatusBarLabel:SetHidden(false)
        activityRow.completeIcon:SetHidden(true)
    else
        activityRow.progressStatusBarLabel:SetHidden(true)
        activityRow.completeIcon:SetHidden(false)
    end

    local completed = self.isAtActivityLimit or activityData:IsCompleted()
    activityRow:SetAlpha(completed and COMPLETE_ACTIVITY_ALPHA or INCOMPLETE_ACTIVITY_ALPHA)

    local CURRENCY_FORMAT_OPTIONS =
    {
        showCap = false,
        useShortFormat = true,
    }
    local nextRewardAnchorTo = nil
    local rewardList = activityData:GetRewardList()
    for rewardIndex, rewardData in ZO_NumericallyIndexedTableReverseIterator(rewardList) do
        local activityReward = self.activityRewardPool:AcquireObject()

        activityReward:SetParent(activityRow.rewardContainer)
        if nextRewardAnchorTo then
            activityReward:SetAnchor(BOTTOMRIGHT, nextRewardAnchorTo, BOTTOMLEFT)
        else
            activityReward:SetAnchor(BOTTOMRIGHT)
        end
        nextRewardAnchorTo = activityReward

        activityReward.amountLabel:SetText(rewardData:GetAbbreviatedQuantity())
        activityReward.iconTexture:SetTexture(rewardData:GetKeyboardIcon())
        activityReward.rewardData = rewardData
    end
end

-----
-- ZO_TimedActivities_Shared
-----

function ZO_TimedActivities_Keyboard:InitializeControls()
    self.emptyMessage = self.control:GetNamedChild("EmptyMessage")
    self.listControl = self.control:GetNamedChild("List")
    self.activitiesScroll = self.listControl:GetNamedChild("Activities")
    self.activitiesScrollChild = self.activitiesScroll:GetNamedChild("ScrollChild")
    self.expirationHeader = self.listControl:GetNamedChild("ExpirationHeader")
    self.limitHeader = self.listControl:GetNamedChild("LimitHeader")

    self.activityRowPool = ZO_ControlPool:New("ZO_TimedActivityRow_Keyboard", self.activitiesScrollChild, "ActivityRow")
    self.activityRewardPool = ZO_ControlPool:New("ZO_TimedActivityReward_Keyboard", self.activitiesScrollChild, "ActivityReward")
end

function ZO_TimedActivities_Keyboard:InitializeActivityFinderCategory()
    TIMED_ACTIVITIES_FRAGMENT = self.sceneFragment

    local function OnDailyCategorySelected()
        self:SetCurrentActivityType(TIMED_ACTIVITY_TYPE_DAILY)
    end

    local function OnWeeklyCategorySelected()
        self:SetCurrentActivityType(TIMED_ACTIVITY_TYPE_WEEKLY)
    end

    local CATEGORY_PRIORITY = ZO_ACTIVITY_FINDER_SORT_PRIORITY.TIMED_ACTIVITIES
    local timedActivitiesCategoryData = 
    {
        priority = CATEGORY_PRIORITY,
        name = GetString(SI_ACTIVITY_FINDER_CATEGORY_TIMED_ACTIVITIES),
        onTreeEntrySelected = OnDailyCategorySelected,
        normalIcon = "EsoUI/Art/LFG/LFG_indexIcon_timedActivities_up.dds",
        pressedIcon = "EsoUI/Art/LFG/LFG_indexIcon_timedActivities_down.dds",
        mouseoverIcon = "EsoUI/Art/LFG/LFG_indexIcon_timedActivities_over.dds",
        children =
        {
            {
                priority = CATEGORY_PRIORITY + 10,
                name = GetString("SI_TIMEDACTIVITYTYPE", TIMED_ACTIVITY_TYPE_DAILY),
                categoryFragment = self.sceneFragment,
                onTreeEntrySelected = OnDailyCategorySelected,
            },
            {
                priority = CATEGORY_PRIORITY + 20,
                name = GetString("SI_TIMEDACTIVITYTYPE", TIMED_ACTIVITY_TYPE_WEEKLY),
                categoryFragment = self.sceneFragment,
                onTreeEntrySelected = OnWeeklyCategorySelected,
            },
        },
    }
    GROUP_MENU_KEYBOARD:AddCategory(timedActivitiesCategoryData)
end

function ZO_TimedActivities_Keyboard:Refresh()
    ZO_ClearNumericallyIndexedTable(self.activitiesData)

    local currentActivityType = self:GetCurrentActivityType()
    local activityTypeFilters
    if currentActivityType == TIMED_ACTIVITY_TYPE_DAILY then
        activityTypeFilters = { ZO_TimedActivityData.IsDailyActivity }
    elseif currentActivityType == TIMED_ACTIVITY_TYPE_WEEKLY then
        activityTypeFilters = { ZO_TimedActivityData.IsWeeklyActivity }
    end

    for index, activityData in TIMED_ACTIVITIES_MANAGER:ActivitiesIterator(activityTypeFilters) do
        table.insert(self.activitiesData, activityData)
    end

    self.activityRewardPool:ReleaseAllObjects()
    self.activityRowPool:ReleaseAllObjects()
    self.nextActivityAnchorTo = nil
    self.isAtActivityLimit = TIMED_ACTIVITIES_MANAGER:IsAtTimedActivityTypeLimit(currentActivityType)

    for index, activityData in ipairs(self.activitiesData) do
        self:AddActivityRow(activityData)
    end

    self:RefreshAvailability()
    self:RefreshCurrentActivityInfo()
end

function ZO_TimedActivities_Keyboard:RefreshAvailability()
    local activityType = self:GetCurrentActivityType()
    local isAvailable = self:IsActivityTypeAvailable(activityType)
    if not isAvailable then
        local activityTypeName = GetString("SI_TIMEDACTIVITYTYPE", activityType)
        self.emptyMessage:SetText(zo_strformat(SI_TIMED_ACTIVITIES_EMPTY_LIST, activityTypeName))
    end

    self.emptyMessage:SetHidden(isAvailable)
    self.listControl:SetHidden(not isAvailable)
end

function ZO_TimedActivities_Keyboard:OnHidden()
    EVENT_MANAGER:UnregisterForUpdate("ZO_TimedActivities_Keyboard.RefreshCurrentActivityInfo")
end

function ZO_TimedActivities_Keyboard:OnShown()
    self:RefreshCurrentActivityInfo()

    EVENT_MANAGER:RegisterForUpdate("ZO_TimedActivities_Keyboard.RefreshCurrentActivityInfo", 1000, function()
        self:RefreshCurrentActivityInfo()
    end)

    TriggerTutorial(TUTORIAL_TRIGGER_ENDEAVORS_OPENED)
end

-----
-- Global XML
-----

function ZO_TimedActivities_Keyboard_OnInitialize(control)
    TIMED_ACTIVITIES_KEYBOARD = ZO_TimedActivities_Keyboard:New(control)
end

function ZO_TimedActivityRow_Keyboard_OnInitialize(control)
    control.nameLabel = control:GetNamedChild("Name")
    control.rewardContainer = control:GetNamedChild("RewardContainer")
    control.progressStatusBar = control:GetNamedChild("ProgressBar")
    ZO_StatusBar_InitializeDefaultColors( control.progressStatusBar )
    control.progressStatusBarLabel = control.progressStatusBar:GetNamedChild("Progress")
    control.completeIcon = control:GetNamedChild("CompleteIcon")
end