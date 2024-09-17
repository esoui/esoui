ZO_TIMED_ACTIVITY_DATA_ROW_1_HEIGHT_GAMEPAD = 148
ZO_TIMED_ACTIVITY_DATA_ROW_2_HEIGHT_GAMEPAD = 202
ZO_TIMED_ACTIVITY_DATA_ROW_3_HEIGHT_GAMEPAD = 256
ZO_TIMED_ACTIVITY_DATA_ROW_4_HEIGHT_GAMEPAD = 310
ZO_TIMED_ACTIVITY_DATA_ROW_5_HEIGHT_GAMEPAD = 364
ZO_TIMED_ACTIVITY_DATA_ROW_NAME_WIDTH_GAMEPAD = 777

local TIMED_ACTIVITY_ROW_DATA_1 = 1
local TIMED_ACTIVITY_ROW_DATA_2 = 2
local TIMED_ACTIVITY_ROW_DATA_3 = 3
local TIMED_ACTIVITY_ROW_DATA_4 = 4
local TIMED_ACTIVITY_ROW_DATA_5 = 5

local COMPLETE_ACTIVITY_ALPHA = 0.5
local INCOMPLETE_ACTIVITY_ALPHA = 1

ZO_TimedActivities_Gamepad = ZO_Object.MultiSubclass(ZO_TimedActivities_Shared, ZO_Gamepad_ParametricList_Screen)

function ZO_TimedActivities_Gamepad:Initialize(control)
    local ACTIVATE_ON_SHOW = true
    TIMED_ACTIVITIES_SCENE_GAMEPAD = ZO_Scene:New("TimedActivitiesGamepad", SCENE_MANAGER)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_DO_NOT_CREATE_TAB_BAR, ACTIVATE_ON_SHOW, TIMED_ACTIVITIES_SCENE_GAMEPAD)
    ZO_TimedActivities_Shared.Initialize(self, control)

    self.emptyControl = self.control:GetNamedChild("Empty")
    self.activitiesControl = self.control:GetNamedChild("Activities")
    self.activitiesList = ZO_TimedActivitiesList_Gamepad:New(self.activitiesControl)
    self:SetCurrentActivityType(TIMED_ACTIVITY_TYPE_DAILY)

    local function RefreshCurrentActivityInfo()
        self:RefreshCurrentActivityInfo()
    end

    self.control:SetHandler("OnUpdate", RefreshCurrentActivityInfo, "RefreshCurrentActivityInfo")
end

function ZO_TimedActivities_Gamepad:RefreshTimedActivityTypeLimit(activityType, control)
    local numActivitiesCompleted, activityLimit = TIMED_ACTIVITIES_MANAGER:GetTimedActivityTypeLimitInfo(activityType)
    return ZO_SELECTED_TEXT:Colorize(zo_strformat(SI_GAMEPAD_TIMED_ACTIVITIES_LIMIT_FORMATTER, numActivitiesCompleted, activityLimit))
end

-- Begin ZO_TimedActivities_Shared Overrides --

function ZO_TimedActivities_Gamepad:InitializeControls()
    self.categoryList = self:GetMainList()
    self.categoryList:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.categoryList:Clear()
    do
        local entryData = ZO_GamepadEntryData:New(GetString("SI_TIMEDACTIVITYTYPE", TIMED_ACTIVITY_TYPE_DAILY))
        entryData:SetDataSource({activityType = TIMED_ACTIVITY_TYPE_DAILY})
        self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", entryData)
    end
    do
        local entryData = ZO_GamepadEntryData:New(GetString("SI_TIMEDACTIVITYTYPE", TIMED_ACTIVITY_TYPE_WEEKLY))
        entryData:SetDataSource({activityType = TIMED_ACTIVITY_TYPE_WEEKLY})
        self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", entryData)
    end
    local RESET_SELECTION_TO_TOP = true
    self.categoryList:Commit(RESET_SELECTION_TO_TOP)

    local function OnTargetDataChanged(list, targetData, oldTargetData)
        self:SetCurrentActivityType(targetData.activityType)
    end

    self.categoryList:SetOnTargetDataChangedCallback(OnTargetDataChanged)

    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Primary
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            callback = function()
                self:ActivateActivitiesList()
            end,
            enabled = function()
                return self.categoryList:GetTargetData() ~= nil
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        -- Back
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            callback = function()
                SCENE_MANAGER:HideCurrentScene()
            end,
            sound = SOUNDS.GAMEPAD_MENU_BACK,
        },
        -- Seals of Endeavor Store
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            keybind = "UI_SHORTCUT_TERTIARY",
            name = GetString(SI_TIMED_ACTIVITIES_OPEN_SEALS_STORE),
            callback = function()
                ZO_ShowSealStore()
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
    }
    self:SetListsUseTriggerKeybinds(true)
end

function ZO_TimedActivities_Gamepad:InitializeActivityFinderCategory()
    TIMED_ACTIVITIES_GAMEPAD_FRAGMENT = self.sceneFragment
    self.scene:AddFragment(self.sceneFragment)

    local primaryCurrencyType = TIMED_ACTIVITIES_MANAGER.GetPrimaryTimedActivitiesCurrencyType()
    self.categoryData =
    {
        gamepadData =
        {
            priority = ZO_ACTIVITY_FINDER_SORT_PRIORITY.TIMED_ACTIVITIES,
            name = GetString(SI_ACTIVITY_FINDER_CATEGORY_TIMED_ACTIVITIES),
            menuIcon = "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_timedActivities.dds",
            sceneName = "TimedActivitiesGamepad",
            tooltipDescription = zo_strformat(SI_GAMEPAD_ACTIVITY_FINDER_TOOLTIP_TIMED_ACTIVITIES, GetCurrencyName(primaryCurrencyType), GetString(SI_GAMEPAD_MAIN_MENU_ENDEAVOR_SEAL_MARKET_ENTRY)),
        },
    }

    local gamepadData = self.categoryData.gamepadData
    ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:AddCategory(gamepadData, gamepadData.priority)
end

function ZO_TimedActivities_Gamepad:GetCategoryData()
    return self.categoryData
end

function ZO_TimedActivities_Gamepad:RefreshCurrentActivityInfo()
    local timeRemainingString = self:GetCurrentActivityTypeTimeRemainingString() or ""
    self.activitiesList:RefreshTimeRemaining(timeRemainingString)
end

function ZO_TimedActivities_Gamepad:Refresh()
    local currentActivityType = self:GetCurrentActivityType()
    local activityTypeFilters
    if currentActivityType == TIMED_ACTIVITY_TYPE_DAILY then
        activityTypeFilters = { ZO_TimedActivityData.IsDailyActivity }
    elseif currentActivityType == TIMED_ACTIVITY_TYPE_WEEKLY then
        activityTypeFilters = { ZO_TimedActivityData.IsWeeklyActivity }
    end

    local activitiesList = {}
    for index, activityData in TIMED_ACTIVITIES_MANAGER:ActivitiesIterator(activityTypeFilters) do
        table.insert(activitiesList, activityData)
    end

    self.activitiesList:RefreshList(currentActivityType, activitiesList)
    self:RefreshAvailability()
    self:RefreshCurrentActivityInfo()
    ZO_GamepadGenericHeader_RefreshData(self.header, self.headerData)
end

function ZO_TimedActivities_Gamepad:RefreshAvailability()
    local activityType = self:GetCurrentActivityType()
    local isAvailable = self:IsActivityTypeAvailable(activityType)
    if not isAvailable then
        local activityTypeName = GetString("SI_TIMEDACTIVITYTYPE", activityType)
        self.emptyControl:GetNamedChild("Message"):SetText(zo_strformat(SI_TIMED_ACTIVITIES_EMPTY_LIST, activityTypeName))
    end

    self.emptyControl:SetHidden(isAvailable)
    self.activitiesControl:SetHidden(not isAvailable)
end

function ZO_TimedActivities_Gamepad:OnHidden()
    self:Deactivate()
    self.activitiesList:Deactivate()
end

function ZO_TimedActivities_Gamepad:OnShown()
    local targetData = self.categoryList:GetTargetData()
    local activityType = targetData and targetData.activityType or TIMED_ACTIVITY_TYPE_DAILY
    self:SetCurrentActivityType(activityType)

    TriggerTutorial(TUTORIAL_TRIGGER_ENDEAVORS_OPENED)
end

-- End ZO_TimedActivities_Shared Overrides --

-- Begin ZO_Gamepad_ParametricList_Screen Overrides --

function ZO_TimedActivities_Gamepad:OnDeferredInitialize()
    self.headerData =
    {
        titleText = GetString(SI_ACTIVITY_FINDER_CATEGORY_TIMED_ACTIVITIES),
    }

    local dataIndex = 0
    for activityType = TIMED_ACTIVITY_TYPE_ITERATION_BEGIN, TIMED_ACTIVITY_TYPE_ITERATION_END do
        dataIndex = dataIndex + 1
        local keyPrefix = string.format("data%d", dataIndex)

        self.headerData[keyPrefix.."HeaderText"] = GetString("SI_TIMEDACTIVITYTYPE_LIMITHEADER", activityType)
        self.headerData[keyPrefix.."Text"] = function(...) return self:RefreshTimedActivityTypeLimit(activityType, ...) end
    end

    local MAX_GAMEPAD_HEADER_DATA_PAIRS = 4
    internalassert(dataIndex <= MAX_GAMEPAD_HEADER_DATA_PAIRS, "The number of Timed Activity Types has exceeded the maximum number of supported Gamepad Header data pairs.")

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_TimedActivities_Gamepad:ActivateCurrentList(...)
    ZO_Gamepad_ParametricList_Screen.ActivateCurrentList(self, ...)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TimedActivities_Gamepad:DeactivateCurrentList(...)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    ZO_Gamepad_ParametricList_Screen.DeactivateCurrentList(self, ...)
end

function ZO_TimedActivities_Gamepad:ActivateActivitiesList()
    self:DeactivateCurrentList()
    self.activitiesList:Activate()
end

function ZO_TimedActivities_Gamepad:DeactivateActivitiesList()
    self.activitiesList:Deactivate()
    self:ActivateCurrentList()
end

-- End ZO_Gamepad_ParametricList_Screen Overrides --

ZO_TimedActivitiesList_Gamepad = ZO_SortFilterList_Gamepad:Subclass()

function ZO_TimedActivitiesList_Gamepad:New(...)
    return ZO_SortFilterList_Gamepad.New(self, ...)
end

function ZO_TimedActivitiesList_Gamepad:Initialize(control)
    self.control = control
    ZO_SortFilterList_Gamepad.Initialize(self, self.control)
    self.timeRemaining = self.control:GetNamedChild("TimeRemaining")
    self.activityRewardPool = ZO_ControlPool:New("ZO_TimedActivityReward_Gamepad", self.control, "TimedActivityRewardGamepad")
    self.listControl = self:GetListControl()

    local function SetupActivityRow(entryControl, data)
        self:SetupActivityRow(entryControl, data)
    end

    local function ResetActivityRow(entryControl)
        self:ResetActivityRow(entryControl)
    end

    local NO_HIDE_CALLBACK = nil
    local DEFAULT_SELECT_SOUND = nil
    ZO_ScrollList_AddDataType(self.listControl, TIMED_ACTIVITY_ROW_DATA_1, "ZO_TimedActivityRow1_Gamepad", ZO_TIMED_ACTIVITY_DATA_ROW_1_HEIGHT_GAMEPAD, SetupActivityRow, NO_HIDE_CALLBACK, DEFAULT_SELECT_SOUND, ResetActivityRow)
    ZO_ScrollList_AddDataType(self.listControl, TIMED_ACTIVITY_ROW_DATA_2, "ZO_TimedActivityRow2_Gamepad", ZO_TIMED_ACTIVITY_DATA_ROW_2_HEIGHT_GAMEPAD, SetupActivityRow, NO_HIDE_CALLBACK, DEFAULT_SELECT_SOUND, ResetActivityRow)
    ZO_ScrollList_AddDataType(self.listControl, TIMED_ACTIVITY_ROW_DATA_3, "ZO_TimedActivityRow3_Gamepad", ZO_TIMED_ACTIVITY_DATA_ROW_3_HEIGHT_GAMEPAD, SetupActivityRow, NO_HIDE_CALLBACK, DEFAULT_SELECT_SOUND, ResetActivityRow)
    ZO_ScrollList_AddDataType(self.listControl, TIMED_ACTIVITY_ROW_DATA_4, "ZO_TimedActivityRow4_Gamepad", ZO_TIMED_ACTIVITY_DATA_ROW_4_HEIGHT_GAMEPAD, SetupActivityRow, NO_HIDE_CALLBACK, DEFAULT_SELECT_SOUND, ResetActivityRow)
    ZO_ScrollList_AddDataType(self.listControl, TIMED_ACTIVITY_ROW_DATA_5, "ZO_TimedActivityRow5_Gamepad", ZO_TIMED_ACTIVITY_DATA_ROW_5_HEIGHT_GAMEPAD, SetupActivityRow, NO_HIDE_CALLBACK, DEFAULT_SELECT_SOUND, ResetActivityRow)

    local function AreActivityRowsEqual(left, right)
        return left:GetId() == right:GetId()
    end

    ZO_ScrollList_SetEqualityFunction(self.listControl, TIMED_ACTIVITY_ROW_DATA_1, AreActivityRowsEqual)
    ZO_ScrollList_SetEqualityFunction(self.listControl, TIMED_ACTIVITY_ROW_DATA_2, AreActivityRowsEqual)
    ZO_ScrollList_SetEqualityFunction(self.listControl, TIMED_ACTIVITY_ROW_DATA_3, AreActivityRowsEqual)
    ZO_ScrollList_SetEqualityFunction(self.listControl, TIMED_ACTIVITY_ROW_DATA_4, AreActivityRowsEqual)
    ZO_ScrollList_SetEqualityFunction(self.listControl, TIMED_ACTIVITY_ROW_DATA_5, AreActivityRowsEqual)

    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Back
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            callback = function()
                TIMED_ACTIVITIES_GAMEPAD:DeactivateActivitiesList()
            end,
            sound = SOUNDS.GAMEPAD_MENU_BACK,
        },
    }
end

function ZO_TimedActivitiesList_Gamepad:RefreshTimeRemaining(timeRemaining)
    self.timeRemainingText = timeRemaining
    self.timeRemaining:SetText(timeRemaining)
end

function ZO_TimedActivitiesList_Gamepad:ResetActivityRow(control)
    control:SetHidden(true)
    control.activityRewardPool:ReleaseAllObjects()
end

function ZO_TimedActivitiesList_Gamepad:SetupActivityRow(control, data)
    control.data = data.dataSource
    control.nameLabel:SetText(control.data:GetName())

    local maxProgress = control.data:GetMaxProgress()
    local progress = control.data:GetProgress()
    local progressPercent
    if maxProgress < 1 or progress >= maxProgress then
        progressPercent = 1
    else
        progressPercent = progress / maxProgress
    end
    control.progressStatusBar:SetValue(progressPercent)

    if progressPercent < 1 then
        local progressString = zo_strformat(SI_TIMED_ACTIVITIES_ACTIVITY_COMPLETION_VALUES, progress, maxProgress)
        control.progressLabel:SetText(progressString)
        control.progressLabel:SetHidden(false)
        control.completeIcon:SetHidden(true)
    else
        control.progressLabel:SetHidden(true)
        control.completeIcon:SetHidden(false)
    end

    local completed = self.isAtActivityLimit or control.data:IsCompleted()
    control:SetAlpha(completed and COMPLETE_ACTIVITY_ALPHA or INCOMPLETE_ACTIVITY_ALPHA)

    if not control.activityRewardPool then
        control.activityRewardPool = ZO_MetaPool:New(self.activityRewardPool)
    end

    local nextRewardAnchorTo = nil
    local rewardList = control.data:GetRewardList()
    for rewardIndex, rewardData in ZO_NumericallyIndexedTableReverseIterator(rewardList) do
        local activityReward = control.activityRewardPool:AcquireObject()

        activityReward:SetParent(control.rewardContainer)
        if nextRewardAnchorTo then
            activityReward:SetAnchor(BOTTOMRIGHT, nextRewardAnchorTo, BOTTOMLEFT, -10)
        else
            activityReward:SetAnchor(BOTTOMRIGHT)
        end
        nextRewardAnchorTo = activityReward

        activityReward.amountLabel:SetText(rewardData:GetAbbreviatedQuantity())
        activityReward.iconTexture:SetTexture(rewardData:GetGamepadIcon())
        activityReward.rewardData = rewardData
    end
end

function ZO_TimedActivitiesList_Gamepad:RefreshList(currentActivityType, activitiesList)
    self.isAtActivityLimit = TIMED_ACTIVITIES_MANAGER:IsAtTimedActivityTypeLimit(currentActivityType)

    local listControl = self.listControl
    ZO_ScrollList_Clear(listControl)

    local listData = ZO_ScrollList_GetDataList(listControl)
    for index, activityData in ipairs(activitiesList) do
        local entryData = ZO_EntryData:New(activityData)
        local activityName = activityData:GetName()
        local numActivityNameLines = ZO_LabelUtils_GetNumLines(activityName, "ZoFontGamepad42", ZO_TIMED_ACTIVITY_DATA_ROW_NAME_WIDTH_GAMEPAD)

        local dataType = TIMED_ACTIVITY_ROW_DATA_1
        if numActivityNameLines == 2 then
            dataType = TIMED_ACTIVITY_ROW_DATA_2
        elseif numActivityNameLines == 3 then
            dataType = TIMED_ACTIVITY_ROW_DATA_3
        elseif numActivityNameLines == 4 then
            dataType = TIMED_ACTIVITY_ROW_DATA_4
        elseif numActivityNameLines == 5 then
            dataType = TIMED_ACTIVITY_ROW_DATA_5
        end

        table.insert(listData, ZO_ScrollList_CreateDataEntry(dataType, entryData))
    end

    self:CommitScrollList()
    local isListEmpty = not ZO_ScrollList_HasVisibleData(listControl)
    listControl:SetHidden(isListEmpty)
end

function ZO_TimedActivitiesList_Gamepad:ClearActivityTooltip()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_TimedActivitiesList_Gamepad:ShowActivityTooltip(activityIndex)
    GAMEPAD_TOOLTIPS:LayoutTimedActivityTooltip(GAMEPAD_RIGHT_TOOLTIP, activityIndex)
end

-- Begin ZO_SortFilterList Overrides --

function ZO_TimedActivitiesList_Gamepad:Activate(...)
    ZO_SortFilterList_Gamepad.Activate(self, ...)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TimedActivitiesList_Gamepad:Deactivate(...)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    ZO_SortFilterList_Gamepad.Deactivate(self, ...)
end

function ZO_TimedActivitiesList_Gamepad:OnSelectionChanged(oldData, newData)
    ZO_SortFilterList_Gamepad.OnSelectionChanged(self, oldData, newData)

    if newData then
        local activityIndex = newData:GetIndex()
        self:ShowActivityTooltip(activityIndex)
    else
        self:ClearActivityTooltip()
    end
end

function ZO_TimedActivitiesList_Gamepad:GetHeaderNarration()
    local narrations = {}
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_TIMED_ACTIVITIES_ACTIVITY_TIME_REMAINING_HEADER)))
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.timeRemainingText))
    return narrations
end

-- End ZO_SortFilterList Overrides --

-- Global XML

function ZO_TimedActivities_Gamepad_OnInitialized(control)
    TIMED_ACTIVITIES_GAMEPAD = ZO_TimedActivities_Gamepad:New(control)
end

function ZO_TimedActivityRow_Gamepad_OnInitialized(control)
    control.nameLabel = control:GetNamedChild("Name")
    control.rewardContainer = control:GetNamedChild("RewardContainer")
    control.progressStatusBar = control:GetNamedChild("ProgressBar")
    ZO_StatusBar_InitializeDefaultColors(control.progressStatusBar)
    control.progressLabel = control.progressStatusBar:GetNamedChild("Progress")
    control.completeIcon = control:GetNamedChild("CompleteIcon")
end