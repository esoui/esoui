local COMPLETE_ACTIVITY_ALPHA = 0.4
local INCOMPLETE_ACTIVITY_ALPHA = 1

ZO_TAMRIEL_TOMES_CHALLENGE_TILE_WIDTH_KEYBOARD = 720
ZO_TAMRIEL_TOMES_CHALLENGE_TILE_HEIGHT_KEYBOARD = 130
ZO_TAMRIEL_TOMES_CHALLENGE_TILE_SPACING_KEYBOARD = 10

local g_checkboxControlPool = nil
local function GetCheckboxControlPool()
    if not g_checkboxControlPool then
        g_checkboxControlPool = ZO_ControlPool:New("ZO_ReadOnlyCheckBox_White", ZO_TimedActivities_KeyboardTLContent, "CB")
    end
    return g_checkboxControlPool
end

-------------------
-- Activity Tile --
-------------------

ZO_TimedActivityTile_Keyboard = ZO_Object.MultiSubclass(ZO_ContextualActionsTile_Keyboard, ZO_ContextualActionsTile)

function ZO_TimedActivityTile_Keyboard:New(...)
    return ZO_ContextualActionsTile.New(self, ...)
end

function ZO_TimedActivityTile_Keyboard:InitializePlatform()
    ZO_ContextualActionsTile_Keyboard.InitializePlatform(self)

    self.progressBar = self.control:GetNamedChild("Progress")
    self.progressBarProgressLabel = self.progressBar:GetNamedChild("Progress")
    self.claimedLabel = self.control:GetNamedChild("Claimed")
    self.claimableHighlight = self.control:GetNamedChild("ClaimableHighlight")
    self.rewardCurrencyLabel = self.control:GetNamedChild("RewardCurrency")
    self.timeRemainingLabel = self.control:GetNamedChild("TimeRemaining")

    self.checkboxControlPool = ZO_MetaPool:New(GetCheckboxControlPool())
end

function ZO_TimedActivityTile_Keyboard:PostInitializePlatform()
    ZO_ContextualActionsTile_Keyboard.PostInitializePlatform(self)

    local PIN_TEXTURE = "EsoUI/Art/Buttons/radiobutton_pin_down.dds"
    local PIN_SIZE = 32
    self.pinTexture = zo_iconFormat(PIN_TEXTURE, PIN_SIZE, PIN_SIZE)

    local NEW_INDICATOR_TEXTURE = "/esoui/art/miscellaneous/new_icon.dds"
    local NEW_INDICATOR_SIZE = 32
    self.newIndicatorTexture = zo_iconFormat(NEW_INDICATOR_TEXTURE, NEW_INDICATOR_SIZE, NEW_INDICATOR_SIZE)

    ZO_StatusBar_SetGradientColor(self.progressBar, ZO_XP_BAR_GRADIENT_COLORS)

    self.keybindStripDescriptor =
    {
        -- Claim
        {
            name = GetString(SI_TAMRIEL_TOMES_CHALLENGES_ACTION_NAME_CLAIM),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self.timedActivityData:Claim()
            end,
            visible = function()
                if self.timedActivityData then
                    return self.timedActivityData:CanClaim()
                end
                return false
            end,
            -- This action cannot fail as long as the only rewards are the Tome Points currency and that currency continues to be uncapped.
            sound = SOUNDS.TAMRIEL_TOMES_CHALLENGE_REWARD_CLAIMED
        },

        -- Track
        {
            name = function()
                if self.timedActivityData:IsTracked() then
                    return GetString(SI_TAMRIEL_TOMES_CHALLENGES_ACTION_NAME_UNPIN)
                end
                return GetString(SI_TAMRIEL_TOMES_CHALLENGES_ACTION_NAME_PIN)
            end,
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                self.timedActivityData:ToggleTracking()
            end,
            visible = function()
                if self.timedActivityData then
                    return self.timedActivityData:CanTrack() 
                end
                return false
            end,
        },

        -- Reroll
        {
            name = function()
                return zo_strformat(SI_TAMRIEL_TOMES_CHALLENGES_ACTION_NAME_REROLL, ZO_TimedActivities_Manager.GetNumRemainingRerollAttempts())
            end,
            keybind = "UI_SHORTCUT_QUINARY",
            callback = function()
                self.timedActivityData:Reroll()
            end,
            visible = function()
                if self.timedActivityData then
                    return self.timedActivityData:CanReroll()
                end
                return false
            end,
            enabled = function()
                if self.timedActivityData then
                    return not self.timedActivityData:CanClaim()
                end
                return false
            end,
            sound = SOUNDS.TAMRIEL_TOMES_CHALLENGE_REROLL,
        },
    }
end

do
    local CURRENCY_OPTIONS = 
    {
        font = "ZoFontGameBold",
        iconSide = RIGHT,
        color = ZO_SELECTED_TEXT,
    }

    local CURRENCY_DISABLED_OPTIONS = 
    {
        font = "ZoFontGameBold",
        iconSide = RIGHT,
        color = ZO_DISABLED_TEXT,
    }

    function ZO_TimedActivityTile_Keyboard:LayoutPlatform(timedActivityData)
        self.timedActivityData = timedActivityData
        if not timedActivityData then
            internalassert(false, "Created timed activity tile with no activity data")
            return
        end

        local isFullyClaimedOrExpired = timedActivityData:IsFullyClaimedOrExpired()

        local titleText = timedActivityData:GetName()
        if timedActivityData:IsTracked() then
            titleText = string.format("%s%s", self.pinTexture, titleText)
        end
        if timedActivityData:CanClaim() or TIMED_ACTIVITIES_MANAGER:IsNewTimedActivity(timedActivityData) then
            titleText = string.format("%s%s", self.newIndicatorTexture, titleText)
        end
        self:SetTitle(titleText)

        local titleColor = isFullyClaimedOrExpired and ZO_NORMAL_TEXT:GetDim() or ZO_NORMAL_TEXT
        self.titleLabel:SetColor(titleColor:UnpackRGBA())

        local rewardCurrency, rewardCurrencyAmount = timedActivityData:GetCurrencyRewardInfo()
        local currencyOptions = isFullyClaimedOrExpired and CURRENCY_DISABLED_OPTIONS or CURRENCY_OPTIONS
        ZO_CurrencyControl_SetSimpleCurrency(self.rewardCurrencyLabel, rewardCurrency, rewardCurrencyAmount, currencyOptions)

        ZO_TimedActivities_Shared.SetupClaimProgress(timedActivityData, self.claimedLabel, self.checkboxControlPool)

        ZO_TimedActivities_Shared.RefreshTimeRemaining(timedActivityData, self.timeRemainingLabel)

        local maxProgress = timedActivityData:GetMaxProgress()
        self.progressBar:SetMinMax(0, maxProgress)

        if isFullyClaimedOrExpired then
            self.progressBar:SetValue(0)
            self.progressBarProgressLabel:SetHidden(true)
            ZO_StatusBar_SetOverlayColor(self.progressBar, 0.5, 0.5, 0.5, 1)
        else
            local progress = timedActivityData:GetProgress()
            self.progressBar:SetValue(progress)
            self.progressBarProgressLabel:SetText(zo_strformat(SI_TAMRIEL_TOMES_CHALLENGES_PROGRESS, progress, maxProgress))
            self.progressBarProgressLabel:SetHidden(false)
            ZO_StatusBar_SetOverlayColor(self.progressBar, 1, 1, 1, 1)
        end

        self.claimableHighlight:SetHidden(not timedActivityData:CanClaim())
    end
end

function ZO_TimedActivityTile_Keyboard:OnMouseEnter()
    ZO_ContextualActionsTile_Keyboard.OnMouseEnter(self)

    local description = self.timedActivityData:GetDescription()
    if description ~= "" then
        InitializeTooltip(InformationTooltip)
        ZO_Tooltips_SetupDynamicTooltipAnchors(InformationTooltip, self:GetControl())
        SetTooltipText(InformationTooltip, description)
    end

    self:UpdateKeybinds()
end

function ZO_TimedActivityTile_Keyboard:OnMouseExit()
    ZO_ContextualActionsTile_Keyboard.OnMouseExit(self)

    if self.timedActivityData then
        TIMED_ACTIVITIES_MANAGER:MarkTimedActivitiesAsSeen({self.timedActivityData})
    end

    ClearTooltip(InformationTooltip)

    self:UpdateKeybinds()
end

function ZO_TimedActivityTile_Keyboard:OnMouseUp(button, upInside)
    ZO_ContextualActionsTile_Keyboard.OnMouseUp(self, button, upInside)

    if upInside and button == MOUSE_BUTTON_INDEX_LEFT then
        if self.timedActivityData and self.timedActivityData:CanClaim() then
            self.timedActivityData:Claim()
        end
    end
end

function ZO_TimedActivityTile_Keyboard:Reset()
    ZO_ContextualActionsTile.Reset(self)

    self.checkboxControlPool:ReleaseAllObjects()
end

-----------------
-- Main Screen --
-----------------

ZO_TimedActivities_Keyboard = ZO_DeferredInitializingObject:MultiSubclass(ZO_TimedActivities_Shared)

function ZO_TimedActivities_Keyboard:Initialize(control)
    TIMED_ACTIVITIES_SCENE_KEYBOARD = ZO_Scene:New("TimedActivitiesKeyboard", SCENE_MANAGER)

    ZO_TimedActivities_Shared.Initialize(self, control)
    ZO_DeferredInitializingObject.Initialize(self, TIMED_ACTIVITIES_SCENE_KEYBOARD)

    TIMED_ACTIVITIES_SCENE_KEYBOARD:AddFragment(self.sceneFragment)

    SYSTEMS:RegisterKeyboardRootScene("timedActivities", TIMED_ACTIVITIES_SCENE_KEYBOARD)
    SYSTEMS:RegisterKeyboardObject("timedActivities", self)
end

function ZO_TimedActivities_Keyboard:OnDeferredInitialize()
    ZO_TimedActivities_Shared.OnDeferredInitialize(self)

    self:SetCurrentActivityType(TIMED_ACTIVITY_TYPE_WEEKLY)
end

function ZO_TimedActivities_Keyboard:InitializeControls()
    local control = self.control
    local contentControl = control:GetNamedChild("Content")
    local tabsControl = control:GetNamedChild("Tabs")
    
    self.contentControl = contentControl
    self.headerControl = contentControl:GetNamedChild("Header")
    self.titleLabel = self.headerControl:GetNamedChild("Title")
    self.resetTimeLabel = self.headerControl:GetNamedChild("ResetTime")
    self.emptyMessage = contentControl:GetNamedChild("EmptyMessage")
    self.gridListControl = contentControl:GetNamedChild("List")

    self.tabsControl = tabsControl
    self.weeklyButton = tabsControl:GetNamedChild("WeeklyButton")
    self.seasonalButton = tabsControl:GetNamedChild("SeasonalButton")
    self.currencyBalanceLabel = tabsControl:GetNamedChild("CurrencyBalance")

    self.weeklyNewIndicatorTexture = self.weeklyButton:GetNamedChild("NewIndicator")
    self.seasonalNewIndicatorTexture = self.seasonalButton:GetNamedChild("NewIndicator")

    self.weeklyButton.activityType = TIMED_ACTIVITY_TYPE_WEEKLY
    self.seasonalButton.activityType = TIMED_ACTIVITY_TYPE_SEASONAL

    local function OnTabButtonClicked(buttonControl)
        self:SetCurrentActivityType(buttonControl.activityType)
    end

    self.weeklyButton:SetHandler("OnClicked", OnTabButtonClicked)
    self.seasonalButton:SetHandler("OnClicked", OnTabButtonClicked)

    self:UpdateRerollAmount()

    self:InitializeGridList()

    self.keybindStripDescriptor =
    {
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER, 
            name = GetString(SI_TAMRIEL_TOMES_BACK_KEYBIND),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                -- Pop the scene to go back
                SCENE_MANAGER:HideCurrentScene()
            end,
            sound = SOUNDS.TAMRIEL_TOMES_NAVIGATE_BACK,
        },

        -- Claim All
        {
            name = GetString(SI_TAMRIEL_TOMES_CHALLENGES_ACTION_NAME_CLAIM_ALL),
            keybind = "UI_SHORTCUT_QUATERNARY",
            callback = function()
                TIMED_ACTIVITIES_MANAGER:ClaimAllRewards()
            end,
            visible = function()
                return TIMED_ACTIVITIES_MANAGER:HasClaimableTimedActivities()
            end,
            -- This action cannot fail as long as the only rewards are the Tome Points currency and that currency continues to be uncapped.
            sound = SOUNDS.TAMRIEL_TOMES_CHALLENGE_REWARD_CLAIMED,
        },
    }
end

function ZO_TimedActivities_Keyboard:InitializeGridList()
    self.gridList = ZO_SingleTemplateGridScrollList_Keyboard:New(self.gridListControl, ZO_GRID_SCROLL_LIST_DONT_AUTOFILL)
    local DEFAULT_HIDE_CALLBACK = nil
    self.gridList:SetGridEntryTemplate("ZO_TimedActivityTile_Keyboard_Control", ZO_TAMRIEL_TOMES_CHALLENGE_TILE_WIDTH_KEYBOARD, ZO_TAMRIEL_TOMES_CHALLENGE_TILE_HEIGHT_KEYBOARD, ZO_DefaultGridTileEntrySetup, DEFAULT_HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, ZO_TAMRIEL_TOMES_CHALLENGE_TILE_SPACING_KEYBOARD, ZO_TAMRIEL_TOMES_CHALLENGE_TILE_SPACING_KEYBOARD)
    
    local function AreActivityRowsEqual(left, right)
        return left:Equals(right)
    end
    self.gridList:SetEntryTemplateEqualityFunction("ZO_TimedActivityTile_Keyboard_Control", AreActivityRowsEqual)
end

function ZO_TimedActivities_Keyboard:SelectActivityTypeCategory(activityType)
    self:SetCurrentActivityType(activityType)
end

function ZO_TimedActivities_Keyboard:SetCurrentActivityType(activityType)
    ZO_TimedActivities_Shared.SetCurrentActivityType(self, activityType)

    local activityTypeName = self:GetCurrentActivityTypeString()
    self.titleLabel:SetText(zo_strformat(SI_TIMED_ACTIVITIES_TYPE_HEADER, activityTypeName))

    if activityType == TIMED_ACTIVITY_TYPE_WEEKLY then
        self.weeklyButton:SetNormalTexture("EsoUI/Art/TamrielTomes/timedActivityCategory_weekly_down.dds")
        self.seasonalButton:SetNormalTexture("EsoUI/Art/TamrielTomes/timedActivityCategory_seasonal_up.dds")
    else
        self.weeklyButton:SetNormalTexture("EsoUI/Art/TamrielTomes/timedActivityCategory_weekly_up.dds")
        self.seasonalButton:SetNormalTexture("EsoUI/Art/TamrielTomes/timedActivityCategory_seasonal_down.dds")
    end
end

function ZO_TimedActivities_Keyboard:UpdateKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TimedActivities_Keyboard:RefreshCurrentActivityInfo()
    local timeRemainingString = self:GetCurrentActivityTypeTimeRemainingString()
    if timeRemainingString ~= "" then
        local headerDescriptor = GetString("SI_TIMEDACTIVITYTYPE_RESETHEADER", self.currentActivityType)
        timeRemainingString = ZO_SELECTED_TEXT:Colorize(timeRemainingString)
        self.resetTimeLabel:SetText(zo_strformat(SI_TIMED_ACTIVITIES_ACTIVITY_RESET_HEADER_FORMATTER, headerDescriptor, timeRemainingString))
    else
        self.resetTimeLabel:SetText("")
    end
end

function ZO_TimedActivities_Keyboard:RefreshList()
    local _, activityEntries = ZO_TimedActivities_Shared.RefreshList(self)
    
    self.gridList:ClearGridList()
    local scrollToEntry = nil
    for _, entryData in ipairs(activityEntries) do
        self.gridList:AddEntry(entryData)
        if self.selectTimedActivityDataOnRefresh and self.selectTimedActivityDataOnRefresh:Equals(entryData) then
            scrollToEntry = entryData
            self.selectTimedActivityDataOnRefresh = nil
        end
    end

    self.gridList:CommitGridList()

    if scrollToEntry then
        local NO_CALLBACK = nil
        local ANIMATE_INSTANTLY = true
        self.gridList:ScrollDataToCenter(scrollToEntry, NO_CALLBACK, ANIMATE_INSTANTLY)
    end
end

function ZO_TimedActivities_Keyboard:RefreshAvailability()
    local isAvailable, emptyMessage = ZO_TimedActivities_Shared.RefreshAvailability(self)

    if not isAvailable then
        self.emptyMessage:SetText(emptyMessage)
    end
    self.emptyMessage:SetHidden(isAvailable)
    self.gridListControl:SetHidden(not isAvailable)
end

function ZO_TimedActivities_Keyboard:RefreshNewIndicators()
    ZO_TimedActivities_Shared.RefreshNewIndicators(self)

    self.gridList:RefreshGridList()
end

function ZO_TimedActivities_Keyboard:OnShowing()
    ZO_TimedActivities_Shared.OnShowing(self)
    
    SCENE_MANAGER:CreateStackFromScratchWithoutSceneChange("TamrielTomesSceneKeyboard")
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TimedActivities_Keyboard:OnShown()
    ZO_TimedActivities_Shared.OnShown(self)

    self:RefreshCurrentActivityInfo()

    EVENT_MANAGER:RegisterForUpdate("ZO_TimedActivities_Keyboard.RefreshCurrentActivityInfo", 1000, function()
        self:RefreshCurrentActivityInfo()
    end)

    TriggerTutorial(TUTORIAL_TRIGGER_TIMED_ACTIVITIES_OPENED)
end

function ZO_TimedActivities_Keyboard:OnHiding()
    ZO_TimedActivities_Shared.OnHiding(self)
    
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TimedActivities_Keyboard:OnHidden()
    ZO_TimedActivities_Shared.OnHidden(self)

    EVENT_MANAGER:UnregisterForUpdate("ZO_TimedActivities_Keyboard.RefreshCurrentActivityInfo")
end

do
    local CURRENCY_OPTIONS =
    {
        showTooltips = true,
        font = "ZoFontWinH2",
        iconSide = RIGHT,
        iconSize = "100%",
    }
    function ZO_TimedActivities_Keyboard:UpdateRerollAmount()
        local currencyAmount = GetPlayerStoredCurrencyAmount(CURT_TOME_CHALLENGE_REROLLS)
        ZO_CurrencyControl_SetSimpleCurrency(self.currencyBalanceLabel, CURT_TOME_CHALLENGE_REROLLS, currencyAmount, CURRENCY_OPTIONS)
    end
end

function ZO_TimedActivities_Keyboard:OnRerollCurrencyUpdated()
    self:UpdateRerollAmount()
    self:UpdateKeybinds()
end

-----
-- Global XML
-----

function ZO_TimedActivities_Keyboard.OnControlInitialized(control)
    TIMED_ACTIVITIES_KEYBOARD = ZO_TimedActivities_Keyboard:New(control)
end