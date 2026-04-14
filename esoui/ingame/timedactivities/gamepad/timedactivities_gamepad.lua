ZO_TIMED_ACTIVITY_DATA_ROW_1_HEIGHT_GAMEPAD = 160
ZO_TIMED_ACTIVITY_DATA_ROW_2_HEIGHT_GAMEPAD = 210
ZO_TIMED_ACTIVITY_DATA_ROW_3_HEIGHT_GAMEPAD = 260
ZO_TIMED_ACTIVITY_DATA_ROW_4_HEIGHT_GAMEPAD = 310
ZO_TIMED_ACTIVITY_DATA_TIME_REMAINING_ROW_1_HEIGHT_GAMEPAD = 195
ZO_TIMED_ACTIVITY_DATA_TIME_REMAINING_ROW_2_HEIGHT_GAMEPAD = 245
ZO_TIMED_ACTIVITY_DATA_TIME_REMAINING_ROW_3_HEIGHT_GAMEPAD = 295
ZO_TIMED_ACTIVITY_DATA_TIME_REMAINING_ROW_4_HEIGHT_GAMEPAD = 345
ZO_TIMED_ACTIVITY_DATA_ROW_NAME_WIDTH_GAMEPAD = 777

local TIMED_ACTIVITY_ROW_DATA_1 = 1
local TIMED_ACTIVITY_ROW_DATA_2 = 2
local TIMED_ACTIVITY_ROW_DATA_3 = 3
local TIMED_ACTIVITY_ROW_DATA_4 = 4
local TIMED_ACTIVITY_TIME_REMAINING_ROW_DATA_1 = 5
local TIMED_ACTIVITY_TIME_REMAINING_ROW_DATA_2 = 6
local TIMED_ACTIVITY_TIME_REMAINING_ROW_DATA_3 = 7
local TIMED_ACTIVITY_TIME_REMAINING_ROW_DATA_4 = 8
local MAX_LINES_SUPPORTED = 4

local TIMED_ACTIVITY_CLEAR_NEW_INDICATOR_TIMER_SECONDS = 0.2

local g_checkboxControlPool = nil
local function GetCheckboxControlPool()
    if not g_checkboxControlPool then
        g_checkboxControlPool = ZO_ControlPool:New("ZO_ReadOnlyCheckBox_Gamepad", ZO_TimedActivitiesGamepadActivities, "CB")
    end
    return g_checkboxControlPool
end

ZO_TimedActivities_Gamepad = ZO_Object.MultiSubclass(ZO_TimedActivities_Shared, ZO_Gamepad_ParametricList_Screen)

function ZO_TimedActivities_Gamepad:Initialize(control)
    local ACTIVATE_ON_SHOW = true
    TIMED_ACTIVITIES_SCENE_GAMEPAD = ZO_Scene:New("TimedActivitiesGamepad", SCENE_MANAGER)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_DO_NOT_CREATE_TAB_BAR, ACTIVATE_ON_SHOW, TIMED_ACTIVITIES_SCENE_GAMEPAD)
    ZO_TimedActivities_Shared.Initialize(self, control)
    
    self.scene:AddFragment(self.sceneFragment)

    SYSTEMS:RegisterGamepadRootScene("timedActivities", TIMED_ACTIVITIES_SCENE_GAMEPAD)
    SYSTEMS:RegisterGamepadObject("timedActivities", self)
end

-- Begin ZO_TimedActivities_Shared Overrides --

function ZO_TimedActivities_Gamepad:OnDeferredInitialize()
    ZO_TimedActivities_Shared.OnDeferredInitialize(self)

    self.headerData =
    {
        titleText = GetString(SI_TIMED_ACTIVITIES_TITLES),
    }

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
    
    self.footerData =
    {
        data1Text = function()
            local currencyType = CURT_TOME_CHALLENGE_REROLLS
            local currencyAmount = ZO_Currency_FormatGamepad(currencyType, GetPlayerStoredCurrencyAmount(currencyType), ZO_CURRENCY_FORMAT_AMOUNT_ICON)
                
            local IS_PLURAL = false
            local IS_MIXED_CASE = false
            local currencyName = GetCurrencyName(currencyType, IS_PLURAL, IS_MIXED_CASE)

            return zo_strformat(SI_GAMEPAD_TAMRIEL_TOMES_REROLL_CURRENCY_FORMATTER, currencyName, currencyAmount)
        end,

        data1TextNarration = function()
            local currencyType = CURT_TOME_CHALLENGE_REROLLS
            local currencyAmount = ZO_Currency_FormatGamepad(currencyType, GetPlayerStoredCurrencyAmount(currencyType), ZO_CURRENCY_FORMAT_AMOUNT_ICON)

            local IS_PLURAL = false
            local currencyName = GetCurrencyName(currencyType, IS_PLURAL)

            return zo_strformat(SI_GAMEPAD_TAMRIEL_TOMES_REROLL_CURRENCY_FORMATTER, currencyName, currencyAmount)
        end,
    }

    self:SetCurrentActivityType(TIMED_ACTIVITY_TYPE_WEEKLY)

    local function RefreshCurrentActivityInfo()
        self:RefreshCurrentActivityInfo()
    end

    self.control:SetHandler("OnUpdate", RefreshCurrentActivityInfo, "RefreshCurrentActivityInfo")
end

function ZO_TimedActivities_Gamepad:InitializeControls()
    self.emptyControl = self.control:GetNamedChild("Empty")
    self.activitiesControl = self.control:GetNamedChild("Activities")
    self.activitiesList = ZO_TimedActivitiesList_Gamepad:New(self.activitiesControl)

    local function EqualityFunc(left, right)
        return left.activityType == right.activityType
    end

    self.categoryList = self:GetMainList()
    self.categoryList:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, EqualityFunc)
    self:RefreshCategoryList()

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
            sound = SOUNDS.TAMRIEL_TOMES_NAVIGATE_BACK,
        },
    }
    self:SetListsUseTriggerKeybinds(true)
end

function ZO_TimedActivities_Gamepad:GetCategoryData()
    return self.categoryData
end

function ZO_TimedActivities_Gamepad:RefreshCategoryList()
    self.categoryList:Clear()
    do
        local function isNewCallback()
            return TIMED_ACTIVITIES_MANAGER:HasClaimableTimedActivities(TIMED_ACTIVITY_TYPE_WEEKLY) or TIMED_ACTIVITIES_MANAGER:HasNewTimedActivities(TIMED_ACTIVITY_TYPE_WEEKLY)
        end

        local entryData = ZO_GamepadEntryData:New(GetString("SI_TIMEDACTIVITYTYPE", TIMED_ACTIVITY_TYPE_WEEKLY), "EsoUI/Art/TamrielTomes/Gamepad/gp_timedActivityCategory_weekly.dds", nil, nil, isNewCallback)
        entryData:SetDataSource({ activityType = TIMED_ACTIVITY_TYPE_WEEKLY })
        self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", entryData)
    end
    do
        local function isNewCallback()
            return TIMED_ACTIVITIES_MANAGER:HasClaimableTimedActivities(TIMED_ACTIVITY_TYPE_SEASONAL) or TIMED_ACTIVITIES_MANAGER:HasNewTimedActivities(TIMED_ACTIVITY_TYPE_SEASONAL)
        end

        local entryData = ZO_GamepadEntryData:New(GetString("SI_TIMEDACTIVITYTYPE", TIMED_ACTIVITY_TYPE_SEASONAL), "EsoUI/Art/TamrielTomes/Gamepad/gp_timedActivityCategory_seasonal.dds", nil, nil, isNewCallback)
        entryData:SetDataSource({ activityType = TIMED_ACTIVITY_TYPE_SEASONAL })
        self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", entryData)
    end
    local RESET_SELECTION_TO_TOP = true
    self.categoryList:Commit(RESET_SELECTION_TO_TOP)
end

function ZO_TimedActivities_Gamepad:SelectActivityTypeCategory(activityType)
    local categoryIndex = self.categoryList:GetIndexForData("ZO_GamepadItemEntryTemplate", { activityType = activityType })
    self.categoryList:SetSelectedIndexWithoutAnimation(categoryIndex)
end

function ZO_TimedActivities_Gamepad:RefreshList()
    local currentActivityType, activityEntries = ZO_TimedActivities_Shared.RefreshList(self)
    local autoSelectActivityData = self.selectTimedActivityDataOnRefresh
    self.selectTimedActivityDataOnRefresh = nil
    self.activitiesList:RefreshList(currentActivityType, activityEntries, autoSelectActivityData)
    if autoSelectActivityData then
        self:ActivateActivitiesList()
    end
end

function ZO_TimedActivities_Gamepad:RefreshNewIndicators()
    self.categoryList:RefreshVisible()
end

function ZO_TimedActivities_Gamepad:RefreshCurrentActivityInfo()
    local timeRemainingString = self:GetCurrentActivityTypeTimeRemainingString() or ""
    self.activitiesList:RefreshTimeRemaining(timeRemainingString)
end

function ZO_TimedActivities_Gamepad:RefreshAvailability()
    local isAvailable, emptyMessage = ZO_TimedActivities_Shared.RefreshAvailability(self)

    if not isAvailable then
        self.emptyControl:GetNamedChild("Message"):SetText(emptyMessage)
    end
    self.emptyControl:SetHidden(isAvailable)
    self.activitiesControl:SetHidden(not isAvailable)
end

function ZO_TimedActivities_Gamepad:OnRerollCurrencyUpdated()
    GAMEPAD_GENERIC_FOOTER:Refresh(self.footerData)
    self:RefreshKeybinds()
    self.activitiesList:UpdateKeybinds()
end

-- End ZO_TimedActivities_Shared Overrides --

-- Begin ZO_Gamepad_ParametricList_Screen Overrides --

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

function ZO_TimedActivities_Gamepad:PerformUpdate()
   self.dirty = false
end

function ZO_TimedActivities_Gamepad:OnShowing()
    ZO_TimedActivities_Shared.OnShowing(self)
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)

    TAMRIEL_TOMES_SCENE_GROUP_GAMEPAD:SetActiveScene("TimedActivitiesGamepad")
    SCENE_MANAGER:CreateStackFromScratchWithoutSceneChange("mainMenuGamepad", "TamrielTomesSceneGamepad")
    GAMEPAD_GENERIC_FOOTER:Refresh(self.footerData)
end

function ZO_TimedActivities_Gamepad:OnShow()
    ZO_TimedActivities_Shared.OnShown(self)
    ZO_Gamepad_ParametricList_Screen.OnShow(self)

    local targetData = self.categoryList:GetTargetData()
    local activityType = targetData and targetData.activityType or TIMED_ACTIVITY_TYPE_DAILY
    self:SetCurrentActivityType(activityType)

    TriggerTutorial(TUTORIAL_TRIGGER_TIMED_ACTIVITIES_OPENED)
end

function ZO_TimedActivities_Gamepad:OnHiding()
    ZO_TimedActivities_Shared.OnHiding(self)
    ZO_Gamepad_ParametricList_Screen.OnHiding(self)
end

function ZO_TimedActivities_Gamepad:OnHide()
    ZO_TimedActivities_Shared.OnHidden(self)
    ZO_Gamepad_ParametricList_Screen.OnHide(self)

    self:Deactivate()
    self.activitiesList:Deactivate()
end

function ZO_TimedActivities_Gamepad:GetFooterNarration()
    return GAMEPAD_GENERIC_FOOTER:GetNarrationText(self.footerData)
end

-- End ZO_Gamepad_ParametricList_Screen Overrides --

ZO_TimedActivitiesList_Gamepad = ZO_SortFilterList_Gamepad:Subclass()

function ZO_TimedActivitiesList_Gamepad:New(...)
    return ZO_SortFilterList_Gamepad.New(self, ...)
end

function ZO_TimedActivitiesList_Gamepad:Initialize(control)
    self.control = control
    ZO_SortFilterList_Gamepad.Initialize(self, self.control)
    self.timeRemainingHeaderLabel = self.control:GetNamedChild("TimeRemainingHeader")
    self.timeRemainingLabel = self.control:GetNamedChild("TimeRemaining")
    self.activityRewardPool = ZO_ControlPool:New("ZO_TimedActivityReward_Gamepad", self.control, "TimedActivityRewardGamepad")
    self.listControl = self:GetListControl()

    local PIN_TEXTURE = "EsoUI/Art/Buttons/Gamepad/gp_trackingPin.dds"
    local PIN_SIZE = 40
    self.pinTexture = zo_iconFormat(PIN_TEXTURE, PIN_SIZE, PIN_SIZE)

    local NEW_INDICATOR_TEXTURE = "/esoui/art/miscellaneous/new_icon.dds"
    local NEW_INDICATOR_SIZE = 40
    self.newIndicatorTexture = zo_iconFormat(NEW_INDICATOR_TEXTURE, NEW_INDICATOR_SIZE, NEW_INDICATOR_SIZE)

    local function SetupActivityRow(entryControl, data)
        self:SetupRow(entryControl, data)
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
    ZO_ScrollList_AddDataType(self.listControl, TIMED_ACTIVITY_TIME_REMAINING_ROW_DATA_1, "ZO_TimedActivityRow1_TimeRemaining_Gamepad", ZO_TIMED_ACTIVITY_DATA_TIME_REMAINING_ROW_1_HEIGHT_GAMEPAD, SetupActivityRow, NO_HIDE_CALLBACK, DEFAULT_SELECT_SOUND, ResetActivityRow)
    ZO_ScrollList_AddDataType(self.listControl, TIMED_ACTIVITY_TIME_REMAINING_ROW_DATA_2, "ZO_TimedActivityRow2_TimeRemaining_Gamepad", ZO_TIMED_ACTIVITY_DATA_TIME_REMAINING_ROW_2_HEIGHT_GAMEPAD, SetupActivityRow, NO_HIDE_CALLBACK, DEFAULT_SELECT_SOUND, ResetActivityRow)
    ZO_ScrollList_AddDataType(self.listControl, TIMED_ACTIVITY_TIME_REMAINING_ROW_DATA_3, "ZO_TimedActivityRow3_TimeRemaining_Gamepad", ZO_TIMED_ACTIVITY_DATA_TIME_REMAINING_ROW_3_HEIGHT_GAMEPAD, SetupActivityRow, NO_HIDE_CALLBACK, DEFAULT_SELECT_SOUND, ResetActivityRow)
    ZO_ScrollList_AddDataType(self.listControl, TIMED_ACTIVITY_TIME_REMAINING_ROW_DATA_4, "ZO_TimedActivityRow4_TimeRemaining_Gamepad", ZO_TIMED_ACTIVITY_DATA_TIME_REMAINING_ROW_4_HEIGHT_GAMEPAD, SetupActivityRow, NO_HIDE_CALLBACK, DEFAULT_SELECT_SOUND, ResetActivityRow)

    local function AreActivityRowsEqual(left, right)
        return left:Equals(right)
    end

    ZO_ScrollList_SetEqualityFunction(self.listControl, TIMED_ACTIVITY_ROW_DATA_1, AreActivityRowsEqual)
    ZO_ScrollList_SetEqualityFunction(self.listControl, TIMED_ACTIVITY_ROW_DATA_2, AreActivityRowsEqual)
    ZO_ScrollList_SetEqualityFunction(self.listControl, TIMED_ACTIVITY_ROW_DATA_3, AreActivityRowsEqual)
    ZO_ScrollList_SetEqualityFunction(self.listControl, TIMED_ACTIVITY_ROW_DATA_4, AreActivityRowsEqual)
    ZO_ScrollList_SetEqualityFunction(self.listControl, TIMED_ACTIVITY_TIME_REMAINING_ROW_DATA_1, AreActivityRowsEqual)
    ZO_ScrollList_SetEqualityFunction(self.listControl, TIMED_ACTIVITY_TIME_REMAINING_ROW_DATA_2, AreActivityRowsEqual)
    ZO_ScrollList_SetEqualityFunction(self.listControl, TIMED_ACTIVITY_TIME_REMAINING_ROW_DATA_3, AreActivityRowsEqual)
    ZO_ScrollList_SetEqualityFunction(self.listControl, TIMED_ACTIVITY_TIME_REMAINING_ROW_DATA_4, AreActivityRowsEqual)

    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Back
        {
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                TIMED_ACTIVITIES_GAMEPAD:DeactivateActivitiesList()
            end,
            sound = SOUNDS.GAMEPAD_MENU_BACK,
        },

        -- Claim
        {
            name = GetString(SI_TAMRIEL_TOMES_CHALLENGES_ACTION_NAME_CLAIM),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:GetSelectedData():Claim()
            end,
            visible = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    return selectedData:CanClaim()
                end
                return false
            end,
            -- Play the sound assuming there shouldn't be any real situation where this keybind is present but claiming fails
            sound = SOUNDS.TAMRIEL_TOMES_CHALLENGE_REWARD_CLAIMED
        },

        -- Track
        {
            name = function()
                if self:GetSelectedData():IsTracked() then
                    return GetString(SI_TAMRIEL_TOMES_CHALLENGES_ACTION_NAME_UNPIN)
                end
                return GetString(SI_TAMRIEL_TOMES_CHALLENGES_ACTION_NAME_PIN)
            end,
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                self:GetSelectedData():ToggleTracking()
            end,
            visible = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    return selectedData:CanTrack() 
                end
                return false
            end,
        },

        -- Reroll
        {
            name = function()
                return zo_strformat(SI_TAMRIEL_TOMES_CHALLENGES_ACTION_NAME_REROLL, ZO_TimedActivities_Manager.GetNumRemainingRerollAttempts())
            end,
            keybind = "UI_SHORTCUT_QUATERNARY",
            callback = function()
                self:GetSelectedData():Reroll()
            end,
            visible = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    return selectedData:CanReroll()
                end
                return false
            end,
            enabled = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    return not selectedData:CanClaim()
                end
                return false
            end,
            sound = SOUNDS.TAMRIEL_TOMES_CHALLENGE_REROLL,
        },
    }
end

function ZO_TimedActivitiesList_Gamepad:RefreshTimeRemaining(timeRemaining)
    self.timeRemainingText = timeRemaining
    if timeRemaining == "" then
        self.timeRemainingHeaderLabel:SetHidden(true)
        self.timeRemainingLabel:SetHidden(true)
    else
        self.timeRemainingHeaderLabel:SetHidden(false)
        self.timeRemainingLabel:SetHidden(false)
        self.timeRemainingHeaderLabel:SetText(GetString("SI_TIMEDACTIVITYTYPE_RESETHEADER", self.currentActivityType))
        self.timeRemainingLabel:SetText(timeRemaining)
    end
end

function ZO_TimedActivitiesList_Gamepad:ResetActivityRow(control)
    control:SetHidden(true)
    control.activityRewardPool:ReleaseAllObjects()
    control.checkboxControlPool:ReleaseAllObjects()
end

function ZO_TimedActivitiesList_Gamepad:SetupActivityRow(control, data)
    local dataSource = data.dataSource
    control.data = dataSource
    local isFullyClaimedOrExpired = dataSource:IsFullyClaimedOrExpired()

    -- TODO Tamriel Tomes: Evaluate the option of using a multi-icon for the Tracked and New/Claimable indicators.
    local name = dataSource:GetName()
    if dataSource:IsTracked() then
        name = string.format("%s%s", self.pinTexture, name)
    end
    if dataSource:CanClaim() or TIMED_ACTIVITIES_MANAGER:IsNewTimedActivity(dataSource) then
        name = string.format("%s%s", self.newIndicatorTexture, name)
    end
    control.nameLabel:SetText(name)
    local selectedTextColor = isFullyClaimedOrExpired and ZO_DISABLED_TEXT or ZO_SELECTED_TEXT
    control.nameLabel:SetColor(selectedTextColor:UnpackRGBA())

    local maxProgress = dataSource:GetMaxProgress()
    control.progressStatusBar:SetMinMax(0, maxProgress)

    if isFullyClaimedOrExpired then
        control.progressStatusBar:SetValue(0)
        control.progressLabel:SetHidden(true)
        ZO_StatusBar_SetOverlayColor(control.progressStatusBar, 0.5, 0.5, 0.5, 1)
    else
        local progress = dataSource:GetProgress()
        control.progressStatusBar:SetValue(progress)
        control.progressLabel:SetText(zo_strformat(SI_TIMED_ACTIVITIES_ACTIVITY_COMPLETION_VALUES, progress, maxProgress))
        control.progressLabel:SetHidden(false)
        ZO_StatusBar_SetOverlayColor(control.progressStatusBar, 1, 1, 1, 1)
    end

    if not control.activityRewardPool then
        control.activityRewardPool = ZO_MetaPool:New(self.activityRewardPool)
    end

    local rewardCurrencyType, rewardCurrencyQuantity = dataSource:GetCurrencyRewardInfo()
    if rewardCurrencyType ~= CURT_NONE then
        local activityReward = control.activityRewardPool:AcquireObject()

        activityReward:SetParent(control.rewardContainer)
        activityReward:SetAnchor(BOTTOMRIGHT)

        activityReward.amountLabel:SetText(ZO_AbbreviateAndLocalizeNumber(rewardCurrencyQuantity, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES))
        activityReward.amountLabel:SetColor(selectedTextColor:UnpackRGBA())
        activityReward.iconTexture:SetTexture(GetCurrencyGamepadIcon(rewardCurrencyType))
        activityReward.iconTexture:SetColor(selectedTextColor:UnpackRGBA())
    end

    ZO_TimedActivities_Shared.SetupClaimProgress(dataSource, control.claimedLabel, control.checkboxControlPool)

    if control.timeRemainingLabel then
        ZO_TimedActivities_Shared.RefreshTimeRemaining(dataSource, control.timeRemainingLabel)
    end

    control.claimableHighlight:SetHidden(not dataSource:CanClaim())
end

function ZO_TimedActivitiesList_Gamepad:RefreshList(currentActivityType, activitiesList, autoSelectActivityData)
    local lastSelectedData = self:GetSelectedData()
    local autoSelectEntryData = nil
    local listControl = self.listControl
    local lastSelectedIndex = ZO_ScrollList_GetSelectedDataIndex(listControl)
    ZO_ScrollList_Clear(listControl)

    self.currentActivityType = currentActivityType

    local listData = ZO_ScrollList_GetDataList(listControl)
    for index, entryData in ipairs(activitiesList) do
        local activityName = entryData:GetName()
        local numActivityNameLines = ZO_LabelUtils_GetNumLines(activityName, "ZoFontGamepad42", ZO_TIMED_ACTIVITY_DATA_ROW_NAME_WIDTH_GAMEPAD)

        local dataType = TIMED_ACTIVITY_ROW_DATA_1
        if numActivityNameLines > 1 then
            if numActivityNameLines == 2 then
                dataType = TIMED_ACTIVITY_ROW_DATA_2
            elseif numActivityNameLines == 3 then
                dataType = TIMED_ACTIVITY_ROW_DATA_3
            else
                dataType = TIMED_ACTIVITY_ROW_DATA_4
            end
        end

        if entryData:GetTimeRemainingS() then
            -- The time remaining variants are the same numbers shifted by however many line templates we support
            dataType = dataType + MAX_LINES_SUPPORTED
        end

        table.insert(listData, ZO_ScrollList_CreateDataEntry(dataType, entryData))

        if autoSelectActivityData and autoSelectActivityData:Equals(entryData) then
            autoSelectEntryData = entryData
            autoSelectActivityData = nil
        end
    end

    self:CommitScrollList()

    if autoSelectEntryData then
        ZO_ScrollList_SelectDataAndScrollIntoView(listControl, autoSelectEntryData)
    elseif lastSelectedData and self:IsActivated() then
        ZO_ScrollList_SelectData(listControl, lastSelectedData)
    end

    if not self:GetSelectedData() then
        -- No entry was auto selected.
        if lastSelectedIndex then
            -- Try to select the entry at the same index as, or at an index adjacent to, the previously selected entry.
            ZO_ScrollList_TrySelectIndexAndScrollIntoView(listControl, lastSelectedIndex, ZO_SCROLL_LIST_ENTRY_SEARCH_DIRECTION.BACKWARD)
        else
            -- Try to select the first entry, if any.
            self:ResetToTop()
        end
    end

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

    if oldData and self.selectedDataFrameTimeS then
        -- If the oldData remained selected for the minimum duration,
        -- mark this Timed Activity as seen.
        if GetFrameTimeSeconds() - self.selectedDataFrameTimeS >= TIMED_ACTIVITY_CLEAR_NEW_INDICATOR_TIMER_SECONDS then
            TIMED_ACTIVITIES_MANAGER:MarkTimedActivitiesAsSeen({oldData})

            local control = ZO_ScrollList_GetDataControl(self.listControl, oldData)
            if control then
                self:SetupActivityRow(control, oldData)
            end
        end

        self.selectedDataFrameTimeS = nil
    end

    if newData then
        local activityIndex = newData:GetIndex()
        self:ShowActivityTooltip(activityIndex)

        -- Track when this data was selected.
        self.selectedDataFrameTimeS = GetFrameTimeSeconds()
    else
        self:ClearActivityTooltip()
    end
end

function ZO_TimedActivitiesList_Gamepad:GetHeaderNarration()
    if self.timeRemainingText ~= "" then
        local narrations = {}
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_TIMEDACTIVITYTYPE_RESETHEADER", self.currentActivityType)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.timeRemainingText))
        return narrations
    end
    return nil
end

-- End ZO_SortFilterList Overrides --

-- Global XML

function ZO_TimedActivities_Gamepad_OnInitialized(control)
    TIMED_ACTIVITIES_GAMEPAD = ZO_TimedActivities_Gamepad:New(control)
end

function ZO_TimedActivityRow_Gamepad_OnInitialized(control)
    control.nameLabel = control:GetNamedChild("Name")
    control.timeRemainingLabel = control:GetNamedChild("TimeRemaining")
    control.claimedLabel = control:GetNamedChild("ClaimedHeader")
    control.claimableHighlight = control:GetNamedChild("ClaimableHighlight")
    control.rewardContainer = control:GetNamedChild("RewardContainer")
    control.progressStatusBar = control:GetNamedChild("ProgressBar")
    ZO_StatusBar_SetGradientColor(control.progressStatusBar, ZO_XP_BAR_GRADIENT_COLORS)
    control.progressLabel = control.progressStatusBar:GetNamedChild("Progress")
    control.checkboxControlPool = ZO_MetaPool:New(GetCheckboxControlPool())
end