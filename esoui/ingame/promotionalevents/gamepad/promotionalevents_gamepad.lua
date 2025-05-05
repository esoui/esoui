-- Reward --

ZO_PromotionalEventReward_Gamepad = ZO_PromotionalEventReward_Shared:Subclass()

function ZO_PromotionalEventReward_Gamepad:Initialize(control)
    ZO_PromotionalEventReward_Shared.Initialize(self, control)

    self.highlight = control:GetNamedChild("Highlight")
end

function ZO_PromotionalEventReward_Gamepad.OnControlInitialized(control)
    ZO_PromotionalEventReward_Gamepad:New(control)
end

-- Activity --

ZO_PromotionalEventActivity_Entry_Gamepad = ZO_PromotionalEventActivity_Entry_Shared:Subclass()

function ZO_PromotionalEventActivity_Entry_Gamepad:Initialize(control)
    ZO_PromotionalEventActivity_Entry_Shared.Initialize(self, control)

    self.progressStatusBar.gloss = self.progressStatusBar:GetNamedChild("Gloss")
    ZO_StatusBar_InitializeDefaultColors(self.progressStatusBar)
end

function ZO_PromotionalEventActivity_Entry_Gamepad:SetActivityData(activityData)
    ZO_PromotionalEventActivity_Entry_Shared.SetActivityData(self, activityData)

    if activityData:IsTracked() then
        local trackedName = zo_iconTextFormat("EsoUI/Art/Buttons/Gamepad/gp_trackingPin.dds", 40, 40, activityData:GetDisplayName())
        self.nameLabel:SetText(trackedName)
    end
end

function ZO_PromotionalEventActivity_Entry_Gamepad.OnControlInitialized(control)
    ZO_PromotionalEventActivity_Entry_Gamepad:New(control)
end

-- Focus Overview --

local PromotionalEvents_GamepadFocus_Overview = ZO_GamepadMultiFocusArea_Base:Subclass()

-- Focus Milestones --

local PromotionalEvents_GamepadFocus_Milestones = ZO_GamepadMultiFocusArea_Base:Subclass()

function PromotionalEvents_GamepadFocus_Milestones:CanBeSelected()
    local currentCampaignData = self.manager:GetCurrentCampaignData()
    return currentCampaignData:GetNumMilestones() > 0
end

function PromotionalEvents_GamepadFocus_Milestones:HandleMovement(horizontalResult, verticalResult)
    if horizontalResult == MOVEMENT_CONTROLLER_MOVE_NEXT then
        if self.manager:TrySelectNextMilestone() then
            self:UpdateKeybinds()
            return true
        else
            -- Go to capstone
            return self:HandleMoveNext()
        end
    elseif horizontalResult == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        if self.manager:TrySelectPreviousMilestone() then
            self:UpdateKeybinds()
            return true
        end
    end
    return false
end

-- Focus Capstone --

local PromotionalEvents_GamepadFocus_Capstone = ZO_GamepadMultiFocusArea_Base:Subclass()

function PromotionalEvents_GamepadFocus_Capstone:HandleMovement(horizontalResult, verticalResult)
    if horizontalResult == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        if self.manager:TrySelectLastMilestone() then
            return self:HandleMovePrevious()
        end
    end
    return false
end

function PromotionalEvents_GamepadFocus_Capstone:HandleMoveNext()
    if self.manager:HasEntries() then
        return ZO_GamepadMultiFocusArea_Base.HandleMoveNext(self)
    end
    -- Always consume
    return true
end

-- Focus Activities --

local PromotionalEvents_GamepadFocus_Activities = ZO_GamepadMultiFocusArea_Base:Subclass()

function PromotionalEvents_GamepadFocus_Activities:HandleMovement(horizontalResult, verticalResult)
    if verticalResult == MOVEMENT_CONTROLLER_MOVE_NEXT then
        self.manager:MoveNext()
        return true
    elseif verticalResult == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        self.manager:MovePrevious()
        return true
    end
    return false
end

function PromotionalEvents_GamepadFocus_Activities:HandleMovePrevious()
    if ZO_ScrollList_AtTopOfList(self.manager.activityList) then
        return ZO_GamepadMultiFocusArea_Base.HandleMovePrevious(self)
    end
    return false
end

function PromotionalEvents_GamepadFocus_Activities:CanBeSelected()
    return self.manager:HasEntries()
end

-- Screen --

ZO_PROMOTIONAL_EVENT_GAMEPAD_ACTIVITY_ENTRY_HEIGHT = 120
ZO_PROMOTIONAL_EVENT_RETURNING_PLAYER_REWARD_WIDTH_GAMEPAD = 180
ZO_PROMOTIONAL_EVENT_RETURNING_PLAYER_REWARD_HEIGHT_GAMEPAD = 170
ZO_PROMOTIONAL_EVENT_RETURNING_PLAYER_REWARD_SPACING_GAMEPAD = 30

ZO_PromotionalEvents_Gamepad = ZO_Object.MultiSubclass(ZO_PromotionalEvents_Shared, ZO_GamepadMultiFocusArea_Manager, ZO_SortFilterList_Gamepad)

function ZO_PromotionalEvents_Gamepad:Initialize(control)
    ZO_PromotionalEvents_Shared.Initialize(self, control)

    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("CampaignsUpdated", function()
        self.lastSelectedData = nil
        self.lastSelectedMilestoneIndex = nil
        if self.activityList then
            ZO_ScrollList_ResetToTop(self.activityList)
        end
    end)
    self:InitializePreview()
end

function ZO_PromotionalEvents_Gamepad:OnDeferredInitialize()
    ZO_PromotionalEvents_Shared.OnDeferredInitialize(self)
    ZO_GamepadMultiFocusArea_Manager.Initialize(self)

    self:InitializeFoci()
    self:InitializeNarrationInfo()
end

function ZO_PromotionalEvents_Gamepad:InitializeActivityFinderCategory()
    self.categoryData =
    {
        gamepadData =
        {
            priority = ZO_ACTIVITY_FINDER_SORT_PRIORITY.PROMOTIONAL_EVENTS,
            name = GetString(SI_ACTIVITY_FINDER_CATEGORY_PROMOTIONAL_EVENTS),
            menuIcon = function()
                if PROMOTIONAL_EVENT_MANAGER:HasAnyUnclaimedRewards() then
                    return "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_PromotionalEvents.dds"
                else
                    return "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_PromotionalEvents_complete.dds"
                end
            end,
            disabledMenuIcon = "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_PromotionalEvents_disabled.dds",
            categoryFragment = function()
                if PROMOTIONAL_EVENT_MANAGER:GetNumActiveCampaigns() == 1 then
                    return self:GetFragment()
                end
                return nil
            end,
            sceneName = function()
                if PROMOTIONAL_EVENT_MANAGER:GetNumActiveCampaigns() > 1 then
                    return "PromotionalEventsListGamepad"
                end
                return nil
            end,
            activateCategory = function()
                self:Activate()
            end,
            visible = function()
                return PROMOTIONAL_EVENT_MANAGER:HasActiveCampaign() and (PROMOTIONAL_EVENT_MANAGER:AreAnyReturningPlayerCampaignsIncomplete() or RETURNING_PLAYER_MANAGER:AreAnyDailyLoginRewardsUnclaimed())
            end,
            tooltipFunction = function(data, lockedText)
                if not lockedText and PROMOTIONAL_EVENT_MANAGER:GetNumActiveCampaigns() > 1 then
                    GAMEPAD_TOOLTIPS:LayoutPromotionalEventCampaigns(GAMEPAD_LEFT_TOOLTIP)
                    return true
                end
                return false
            end,
            isPromotionalEvent = true,
        },
    }

    local gamepadData = self.categoryData.gamepadData
    ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:AddCategory(gamepadData, gamepadData.priority)
end

function ZO_PromotionalEvents_Gamepad:GetCategoryData()
    return self.categoryData
end

function ZO_PromotionalEvents_Gamepad:InitializeCampaignPanel()
    ZO_PromotionalEvents_Shared.InitializeCampaignPanel(self, "ZO_PromotionalEventMilestone_Template_Gamepad")
    ZO_StatusBar_SetGradientColor(self.campaignProgress, ZO_PROMOTIONAL_EVENT_GRADIENT_COLORS)

    self.campaignPanelHighlight = self.campaignPanel:GetNamedChild("Highlight")
end

function ZO_PromotionalEvents_Gamepad:InitializeActivityList()
    ZO_PromotionalEvents_Shared.InitializeActivityList(self, "ZO_PromotionalEventActivity_EntryTemplate_Gamepad", ZO_PROMOTIONAL_EVENT_GAMEPAD_ACTIVITY_ENTRY_HEIGHT)
    ZO_SortFilterList_Gamepad.Initialize(self, self.control)
end

function ZO_PromotionalEvents_Gamepad:InitializeGridList()
    ZO_PromotionalEvents_Shared.InitializeGridList(self)

    self.rewardsGridList = ZO_SingleTemplateGridScrollList_Gamepad:New(self.gridListControl, ZO_GRID_SCROLL_LIST_DONT_AUTOFILL)

    local function RewardGridEntryReset(control)
        ZO_ObjectPool_DefaultResetControl(control)
    end

    local DEFAULT_HIDE_CALLBACK = nil
    local HEADER_HEIGHT = 30
    self.rewardsGridList:SetGridEntryTemplate("ZO_PromotionalEventReturningPlayerReward_Gamepad", ZO_PROMOTIONAL_EVENT_RETURNING_PLAYER_REWARD_WIDTH_GAMEPAD, ZO_PROMOTIONAL_EVENT_RETURNING_PLAYER_REWARD_HEIGHT_GAMEPAD, self.RewardGridEntrySetup, DEFAULT_HIDE_CALLBACK, RewardGridEntryReset, ZO_PROMOTIONAL_EVENT_RETURNING_PLAYER_REWARD_SPACING_GAMEPAD, ZO_PROMOTIONAL_EVENT_RETURNING_PLAYER_REWARD_SPACING_GAMEPAD)
    self.rewardsGridList:SetHeaderTemplate(ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_GAMEPAD, HEADER_HEIGHT, ZO_DefaultGridHeaderSetup)
    self.rewardsGridList:SetHeaderPrePadding(ZO_PROMOTIONAL_EVENT_RETURNING_PLAYER_REWARD_SPACING_GAMEPAD)
    self.rewardsGridList:SetOnSelectedDataChangedCallback(function(...) self:OnGridListSelectedDataChanged(...) end)

    local function GetRewardsGridListBackButtonDescriptor()
        return KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function()
            if ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:IsShowing() or PROMOTIONAL_EVENTS_LIST_GAMEPAD:IsShowing() then
                self:Deactivate()
            end
        end)
    end
    self.rewardsGridListKeybindStripDesciptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        GetRewardsGridListBackButtonDescriptor()
    }
end

-- Overriding from ZO_SortFilterList_Gamepad and ZO_SortFilterList because it makes some assumptions about the control layout
-- that are inconsistent with this screen
function ZO_PromotionalEvents_Gamepad:InitializeSortFilterList(control, highlightTemplate)
    -- ZO_SortFilterList wants it referred to as self.list
    self.list = self.activityList
    ZO_ScrollList_AddResizeOnScreenResize(self.list)
    highlightTemplate = highlightTemplate or "ZO_GamepadInteractiveSortFilterDefaultHighlight"
    ZO_ScrollList_EnableSelection(self.list, highlightTemplate, function(oldData, newData) self:OnSelectionChanged(oldData, newData) end)
end

function ZO_PromotionalEvents_Gamepad:InitializeFoci()
    local function BackKeybindCallback()
        if ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:IsShowing() or PROMOTIONAL_EVENTS_LIST_GAMEPAD:IsShowing() then
            self:Deactivate()
        end
    end

    local CLAIM_ALL_DESCRIPTOR =
    {
        name = GetString(SI_PROMOTIONAL_EVENT_CLAIM_ALL_REWARDS_ACTION),
        keybind = "UI_SHORTCUT_QUINARY",

        visible = function()
            if not self:IsReturningPlayerRewardsEntrySelected() then
                return self.currentCampaignData:IsAnyRewardClaimable()
            end
            return false
        end,

        callback = function()
            self.currentCampaignData:TryClaimAllAvailableRewards()
            self:CollectRemainingChoiceRewards()
            self:TryClaimNextChoiceReward()
        end,
    }

    -- Overview
    local function ActivateOverviewCallback()
        self.campaignPanelHighlight:SetHidden(false)
        local campaignName = ZO_PROMOTIONAL_EVENT_SELECTED_COLOR:Colorize(self.currentCampaignData:GetDisplayName())
        GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_RIGHT_TOOLTIP, campaignName, self.currentCampaignData:GetDescription())
        self.focusedRewardData = nil
        SCREEN_NARRATION_MANAGER:QueueCustomEntry("promotionalEventsOverview")
    end

    local function DeactivateOverviewCallback()
        self.campaignPanelHighlight:SetHidden(true)
    end
    self.overviewFocalArea = PromotionalEvents_GamepadFocus_Overview:New(self, ActivateOverviewCallback, DeactivateOverviewCallback)
    self:AddNextFocusArea(self.overviewFocalArea)

    local overviewKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        CLAIM_ALL_DESCRIPTOR,
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(overviewKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, BackKeybindCallback)
    self.overviewFocalArea:SetKeybindDescriptor(overviewKeybindStripDescriptor)

    -- Milestones
    local function ActivateMilestonesCallback()
        if self.lastSelectedMilestoneIndex then
            self:SelectMilestone(self.lastSelectedMilestoneIndex)
            self.lastSelectedMilestoneIndex = nil
        end

        if self.selectedMilestone then
            self.focusedRewardData = self.selectedMilestone.rewardObject.displayRewardData
            GAMEPAD_TOOLTIPS:LayoutRewardData(GAMEPAD_RIGHT_TOOLTIP, self.focusedRewardData)
            SCREEN_NARRATION_MANAGER:QueueCustomEntry("promotionalEventsMilestone")
        else
            self:TrySelectFirstMilestone()
        end
    end

    local function DeactivateMilestonesCallback()
        self:SelectMilestone(nil)
    end
    self.milestonesFocalArea = PromotionalEvents_GamepadFocus_Milestones:New(self, ActivateMilestonesCallback, DeactivateMilestonesCallback)
    self:AddNextFocusArea(self.milestonesFocalArea)

    local milestonesKeybindStripDescriptor =
    {
        -- Claim
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_PROMOTIONAL_EVENT_CLAIM_REWARD_ACTION),
            keybind = "UI_SHORTCUT_PRIMARY",

            visible = function()
                return self.selectedMilestone.rewardObject.rewardableEventData:CanClaimReward()
            end,

            callback = function()
                local rewardableEventData = self.selectedMilestone.rewardObject.rewardableEventData
                if rewardableEventData.rewardId ~= 0 then
                    if GetRewardType(rewardableEventData.rewardId) == REWARD_ENTRY_TYPE_CHOICE then
                        self:ShowClaimChoiceDialog(rewardableEventData)
                    else
                        rewardableEventData:TryClaimReward()
                        SCREEN_NARRATION_MANAGER:QueueCustomEntry("promotionalEventsMilestone")
                    end
                end
            end,
        },
        -- Claim all
        CLAIM_ALL_DESCRIPTOR,
         -- Preview
        {
            name = GetString(SI_PROMOTIONAL_EVENT_REWARD_PREVIEW_ACTION),
            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                self.previewRewardData = self.selectedMilestone.rewardObject.displayRewardData
                self.lastSelectedMilestoneIndex = self.selectedMilestone.displayIndex
                self:BeginPreview()
            end,

            enabled = function()
                return IsCharacterPreviewingAvailable(), GetString(SI_PREVIEW_UNAVAILABLE_ERROR)
            end,

            visible = function()
                local rewardId = self.selectedMilestone.rewardObject.displayRewardData:GetRewardId()
                local isRewardList = GetRewardType(rewardId) == REWARD_ENTRY_TYPE_REWARD_LIST
                return CanPreviewReward(rewardId) or isRewardList
            end,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(milestonesKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, BackKeybindCallback)
    self.milestonesFocalArea:SetKeybindDescriptor(milestonesKeybindStripDescriptor)

    -- Capstone
    local function ActivateCapstoneCallback()
        self.capstoneRewardObject.highlight:SetHidden(false)
        self.focusedRewardData = self.capstoneRewardObject.displayRewardData
        GAMEPAD_TOOLTIPS:LayoutRewardData(GAMEPAD_RIGHT_TOOLTIP, self.focusedRewardData)
        SCREEN_NARRATION_MANAGER:QueueCustomEntry("promotionalEventsCapstone")
    end

    local function DeactivateCapstoneCallback()
        self.capstoneRewardObject.highlight:SetHidden(true)
    end
    self.capstoneFocalArea = PromotionalEvents_GamepadFocus_Capstone:New(self, ActivateCapstoneCallback, DeactivateCapstoneCallback)
    self:AddNextFocusArea(self.capstoneFocalArea)

    local capstoneKeybindStripDescriptor =
    {
        -- Claim
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_PROMOTIONAL_EVENT_CLAIM_REWARD_ACTION),
            keybind = "UI_SHORTCUT_PRIMARY",

            visible = function()
                return self.capstoneRewardObject.rewardableEventData:CanClaimReward()
            end,

            callback = function()
                local rewardableEventData = self.capstoneRewardObject.rewardableEventData
                if rewardableEventData.capstoneRewardId ~= 0 then
                    if GetRewardType(rewardableEventData.capstoneRewardId) == REWARD_ENTRY_TYPE_CHOICE then
                        self:ShowClaimChoiceDialog(rewardableEventData)
                    else
                        rewardableEventData:TryClaimReward()
                        SCREEN_NARRATION_MANAGER:QueueCustomEntry("promotionalEventsCapstone")
                    end
                end
            end,
        },
        -- Claim all
        CLAIM_ALL_DESCRIPTOR,
        -- Preview
        {
            name = GetString(SI_PROMOTIONAL_EVENT_REWARD_PREVIEW_ACTION),
            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                self.previewRewardData = self.capstoneRewardObject.displayRewardData
                self:BeginPreview()
            end,

            enabled = function()
                return IsCharacterPreviewingAvailable(), GetString(SI_PREVIEW_UNAVAILABLE_ERROR)
            end,

            visible = function()
                local rewardId = self.capstoneRewardObject.displayRewardData:GetRewardId()
                local isRewardList = GetRewardType(rewardId) == REWARD_ENTRY_TYPE_REWARD_LIST
                return CanPreviewReward(rewardId) or isRewardList
            end,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(capstoneKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, BackKeybindCallback)
    self.capstoneFocalArea:SetKeybindDescriptor(capstoneKeybindStripDescriptor)

    -- Activities
    local function ActivateActivitiesCallback()
        -- Every other focus always has a tooltip except activities.
        -- So it's only when going to activities that we might need to clear it and not show it again.
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
        self.focusedRewardData = nil
        local ANIMATE_INSTANTLY = true
        if self.lastSelectedData then
            ZO_ScrollList_SelectData(self.activityList, self.lastSelectedData)
            self.lastSelectedData = nil
        else
            ZO_ScrollList_AutoSelectData(self.activityList, ANIMATE_INSTANTLY)
        end
    end

    local function DeactivateActivitiesCallback()
        ZO_ScrollList_SelectData(self.activityList, nil)
        ZO_ScrollList_ResetAutoSelectIndex(self.activityList)
    end
    self.activitiesFocalArea = PromotionalEvents_GamepadFocus_Activities:New(self, ActivateActivitiesCallback, DeactivateActivitiesCallback)
    self:AddNextFocusArea(self.activitiesFocalArea)

    local activitiesKeybindStripDescriptor =
    {
        -- Claim / Go To Hero's Return
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = function()
                local selectedActivityEntry = self:GetSelectedActivity()
                if selectedActivityEntry:CanClaimReward() then
                    return GetString(SI_PROMOTIONAL_EVENT_CLAIM_REWARD_ACTION)
                else
                    local campaignKey, componentType, index = GetReturningPlayerIntroGameplayData()
                    if componentType == PROMOTIONAL_EVENTS_COMPONENT_TYPE_ACTIVITY then
                        if selectedActivityEntry:MatchesCampaignKey(campaignKey) and selectedActivityEntry:GetActivityIndex() == index then
                            return zo_strformat(SI_PROMOTIONAL_EVENT_RETURNING_PLAYER_GO_TO_ACTION, RETURNING_PLAYER_MANAGER:GetColorizedIntroGameplayDisplayName())
                        end
                    end
                end
            end,

            keybind = "UI_SHORTCUT_PRIMARY",

            visible = function()
                local selectedActivityEntry = self:GetSelectedActivity()
                if selectedActivityEntry:CanClaimReward() then
                    return true
                elseif not selectedActivityEntry:IsRewardClaimed() then
                    local campaignKey, componentType, index = GetReturningPlayerIntroGameplayData()
                    if componentType == PROMOTIONAL_EVENTS_COMPONENT_TYPE_ACTIVITY then
                        return selectedActivityEntry:MatchesCampaignKey(campaignKey) and selectedActivityEntry:GetActivityIndex() == index
                    end
                end
            end,

            callback = function()
                local selectedActivityEntry = self:GetSelectedActivity()
                if selectedActivityEntry:CanClaimReward() then
                    if selectedActivityEntry.rewardId ~= 0 then
                        if GetRewardType(selectedActivityEntry.rewardId) == REWARD_ENTRY_TYPE_CHOICE then
                            self:ShowClaimChoiceDialog(selectedActivityEntry)
                        else
                            selectedActivityEntry:TryClaimReward()
                            SCREEN_NARRATION_MANAGER:QueueSortFilterListEntry(self)
                        end
                    end
                else
                    SYSTEMS:ShowScene("returningPlayerIntro")
                end
            end,
        },
        -- Claim all
        CLAIM_ALL_DESCRIPTOR,
        -- Preview
        {
            name = GetString(SI_PROMOTIONAL_EVENT_REWARD_PREVIEW_ACTION),
            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                local selectedActivityEntry = self:GetSelectedActivity()
                local rewardObject = self:GetActivityRewardObject(selectedActivityEntry)
                self.previewRewardData = rewardObject.displayRewardData
                self.lastSelectedData = selectedActivityEntry
                self:BeginPreview()
            end,

            enabled = function()
                return IsCharacterPreviewingAvailable(), GetString(SI_PREVIEW_UNAVAILABLE_ERROR)
            end,

            visible = function()
                local selectedActivityEntry = self:GetSelectedActivity()
                if selectedActivityEntry then
                    local rewardObject = self:GetActivityRewardObject(selectedActivityEntry)
                    local displayRewardData = rewardObject and rewardObject.displayRewardData
                    if displayRewardData then
                        local rewardId = displayRewardData:GetRewardId()
                        local isRewardList = GetRewardType(rewardId) == REWARD_ENTRY_TYPE_REWARD_LIST
                        return (CanPreviewReward(rewardId) or isRewardList)
                    end
                    return false
                end
                return false
            end,
        },
        -- Track
        {
            name = function()
                if self:GetSelectedActivity():IsTracked() then
                    return GetString(SI_PROMOTIONAL_EVENT_UNPIN_TASK_ACTION)
                else
                    return GetString(SI_PROMOTIONAL_EVENT_PIN_TASK_ACTION)
                end
            end,

            keybind = "UI_SHORTCUT_TERTIARY",

            visible = function()
                local selectedActivityEntry = self:GetSelectedActivity()
                return selectedActivityEntry and not selectedActivityEntry:IsComplete() and not selectedActivityEntry:IsLocked()
            end,

            callback = function()
                return self:GetSelectedActivity():ToggleTracking()
            end,
        },
        -- Open Crown Store
        {
            name = GetString(SI_CONTENT_REQUIRES_COLLECTIBLE_OPEN_CROWN_STORE),
            keybind = "UI_SHORTCUT_RIGHT_STICK",

            callback = function()
                local requiredCollectibleData = self:GetSelectedActivity():GetRequiredCollectibleData()
                if requiredCollectibleData:GetCategoryType() == COLLECTIBLE_CATEGORY_TYPE_CHAPTER then
                    ZO_ShowChapterUpgradePlatformScreen(MARKET_OPEN_OPERATION_PROMOTIONAL_EVENTS)
                else
                    local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, requiredCollectibleData:GetName())
                    ShowMarketAndSearch(searchTerm, MARKET_OPEN_OPERATION_PROMOTIONAL_EVENTS)
                end
            end,

            visible = function()
                local selectedActivityEntry = self:GetSelectedActivity()
                return selectedActivityEntry and selectedActivityEntry:IsLocked()
            end,
        },
        -- Toggle tooltip preference
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            name = GetString(SI_GAMEPAD_PROMOTIONAL_EVENT_ACTIVITY_TOGGLE_INFO),
            keybind = "UI_SHORTCUT_QUATERNARY",

            callback = function()
                self.preferActivityDescriptionTooltip = not self.preferActivityDescriptionTooltip
                self:UpdateActivityTooltip()
                SCREEN_NARRATION_MANAGER:QueueSortFilterListEntry(self)
            end,

            visible = function()
                local selectedActivityEntry = self:GetSelectedActivity()
                return selectedActivityEntry and selectedActivityEntry:GetRewardData() ~= nil
                    and (selectedActivityEntry:GetDescription() ~= "" or selectedActivityEntry:IsLocked())
            end,
        },
        -- Triggers
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Promotional Events Previous Section in List",
            keybind = "UI_SHORTCUT_LEFT_TRIGGER",
            ethereal = true,
            callback = function()
                if ZO_ScrollList_CanScrollUp(self.activityList) then
                    ZO_ScrollList_SelectFirstIndexInCategory(self.activityList, ZO_SCROLL_SELECT_CATEGORY_PREVIOUS)
                    PlaySound(ZO_PARAMETRIC_SCROLL_MOVEMENT_SOUNDS[ZO_PARAMETRIC_MOVEMENT_TYPES.JUMP_PREVIOUS])
                end
            end,
        },
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Promotional Events Next Section in List",
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
            ethereal = true,
            callback = function()
                if ZO_ScrollList_CanScrollDown(self.activityList) then
                    ZO_ScrollList_SelectFirstIndexInCategory(self.activityList, ZO_SCROLL_SELECT_CATEGORY_NEXT)
                    PlaySound(ZO_PARAMETRIC_SCROLL_MOVEMENT_SOUNDS[ZO_PARAMETRIC_MOVEMENT_TYPES.JUMP_NEXT])
                end
            end,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(activitiesKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, BackKeybindCallback)
    self.activitiesFocalArea:SetKeybindDescriptor(activitiesKeybindStripDescriptor)
    self.preferActivityDescriptionTooltip = false
end

function ZO_PromotionalEvents_Gamepad:InitializeNarrationInfo()
    local overviewNarrationData =
    {
        canNarrate = function()
            return self.overviewFocalArea:IsFocused() and self.currentCampaignData
        end,
        selectedNarrationFunction = function()
            local narrations = {}
            local durationText = ZO_FormatTimeLargestTwo(self.currentCampaignData:GetSecondsRemaining(), TIME_FORMAT_STYLE_DESCRIPTIVE)
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_EVENT_ANNOUNCEMENT_TIME, durationText)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.currentCampaignData:GetDisplayName()))

            local capstoneThreshold = self.currentCampaignData:GetCapstoneRewardThreshold()
            local progress = self.currentCampaignData:GetNumActivitiesCompleted()
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_PROGRESS_BAR_FRACTION_FORMATTER, progress, capstoneThreshold)))

            return narrations
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("promotionalEventsOverview", overviewNarrationData)
    local milestonesNarrationData =
    {
        canNarrate = function()
            return self.milestonesFocalArea:IsFocused() and self.selectedMilestone
        end,
        selectedNarrationFunction = function()
            return SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.selectedMilestone.rewardObject.rewardableEventData:GetCompletionThreshold())
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("promotionalEventsMilestone", milestonesNarrationData)
    local capstoneNarrationData =
    {
        canNarrate = function()
            return self.capstoneFocalArea:IsFocused()
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("promotionalEventsCapstone", capstoneNarrationData)
    local previewNarrationData =
    {
        canNarrate = function()
            return IsCurrentlyPreviewing()
        end,
        selectedNarrationFunction = function()
            return ITEM_PREVIEW_GAMEPAD:GetPreviewSpinnerNarrationText()
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("promotionalEventsPreview", previewNarrationData)
end

function ZO_PromotionalEvents_Gamepad:InitializePreview()
    local function GetPreviewBackButtonDescriptor()
        return KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function()
            SCENE_MANAGER:HideCurrentScene()
            self:Activate()
        end)
    end
    self.previewKeybindStripDesciptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        GetPreviewBackButtonDescriptor()
    }

    GAMEPAD_PROMOTIONAL_EVENTS_PREVIEW_SCENE = ZO_Scene:New("promotionalEventsPreview_Gamepad", SCENE_MANAGER)
    GAMEPAD_PROMOTIONAL_EVENTS_PREVIEW_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:OnPreviewShowing()
        elseif newState == SCENE_SHOWN then
            self:OnPreviewShown()
        elseif newState == SCENE_HIDING then
            self:OnPreviewHiding()
        end
    end)
end

function ZO_PromotionalEvents_Gamepad:BeginPreview()
    local rewardId = self.previewRewardData.rewardId
    if GetRewardType(rewardId) == REWARD_ENTRY_TYPE_REWARD_LIST then
        local rewardListId = GetRewardListIdFromReward(rewardId)
        PROMOTIONAL_EVENTS_REWARD_LIST_SCREEN_GAMEPAD:SetRewardList(rewardListId)
        SCENE_MANAGER:Push("promotionalEventsRewardList_Gamepad")
    else
        SCENE_MANAGER:Push("promotionalEventsPreview_Gamepad")
    end
end

function ZO_PromotionalEvents_Gamepad:IsReturningPlayerRewardsEntrySelected()
    local selectedCampaignData = self:GetSelectedCampaignData()
    if selectedCampaignData.isReturningPlayerRewardsEntry then
        return true
    end
    return false
end

function ZO_PromotionalEvents_Gamepad:GetSelectedCampaignData()
    if PROMOTIONAL_EVENTS_LIST_GAMEPAD:GetScene():IsShowing() then
        return PROMOTIONAL_EVENTS_LIST_GAMEPAD.list:GetTargetData()
    else
        return PROMOTIONAL_EVENT_MANAGER:GetCampaignDataByIndex(1)
    end
end

function ZO_PromotionalEvents_Gamepad:TryClaimNextChoiceReward()
    if self.remainingChoiceRewards then
        local _, rewardableEventData = next(self.remainingChoiceRewards)
        if rewardableEventData then
            if PROMOTIONAL_EVENTS_CLAIM_CHOICE_DIALOG_GAMEPAD:IsShowing() then
                PROMOTIONAL_EVENTS_CLAIM_CHOICE_DIALOG_GAMEPAD:SetRewardData(rewardableEventData)
            else
                self:ShowClaimChoiceDialog(rewardableEventData)
            end
        end
    end
end

function ZO_PromotionalEvents_Gamepad:RefreshActivityList(rebuild)
    ZO_PromotionalEvents_Shared.RefreshActivityList(self, rebuild)

    if self.currentCampaignData then
        if rebuild then
            self.lastSelectedData = nil
            ZO_ScrollList_ResetToTop(self.activityList)
        end

        if self:IsCurrentFocusArea(self.activitiesFocalArea) then
            self.activitiesFocalArea:UpdateKeybinds()
        end
    end
end

function ZO_PromotionalEvents_Gamepad:OnGridListSelectedDataChanged(previousData, newData)
    if not self:IsReturningPlayerRewardsEntrySelected() then
        return
    end

    if newData then
        GAMEPAD_TOOLTIPS:LayoutRewardData(GAMEPAD_RIGHT_TOOLTIP, newData)
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    end
end

function ZO_PromotionalEvents_Gamepad:OnRewardsClaimed(campaignData, rewards, hasCapstoneReward)
    ZO_PromotionalEvents_Shared.OnRewardsClaimed(self, campaignData, rewards, hasCapstoneReward)

    if self:IsShowing() and self.currentCampaignData == campaignData then
        self:UpdateActiveFocusKeybinds()
        -- ESO-889143: We need to refresh the tooltip now that things may have changed,
        -- but we also need to delay it because some of the new information may still be on the way
        if self.focusedRewardData then
            -- Don't bother making the call later if we're not even looking at a reward
            zo_callLater(function()
                if self.focusedRewardData then
                    -- Don't refresh the tooltip if we managed to stop looking at a reward in the elapsed time
                    GAMEPAD_TOOLTIPS:LayoutRewardData(GAMEPAD_RIGHT_TOOLTIP, self.focusedRewardData)
                end
            end, 1000)
        end
    end
end

function ZO_PromotionalEvents_Gamepad:GetSelectedActivity()
    return self.selectedData
end

function ZO_PromotionalEvents_Gamepad:GetSelectedMilestone()
    return self.selectedMilestone
end

function ZO_PromotionalEvents_Gamepad:UpdateMilestoneThresholdColor(milestoneControl)
    local selected = milestoneControl == self.selectedMilestone
    local isClaimed = milestoneControl.milestoneData:IsRewardClaimed()
    local color
    if selected then
        color = isClaimed and ZO_SELECTED_TEXT or ZO_PROMOTIONAL_EVENT_SELECTED_COLOR
    else
        color = isClaimed and ZO_DEFAULT_TEXT or ZO_SELECTED_TEXT
    end
    milestoneControl.thresholdLabel:SetColor(color:UnpackRGB())
end

function ZO_PromotionalEvents_Gamepad:RefreshCampaignPanel(rebuild)
    ZO_PromotionalEvents_Shared.RefreshCampaignPanel(self, rebuild)

    if rebuild then
        self.lastSelectedMilestoneIndex = nil
    end

    for _, milestoneControl in pairs(self.milestonePool:GetActiveObjects()) do
        self:UpdateMilestoneThresholdColor(milestoneControl)
    end
end

function ZO_PromotionalEvents_Gamepad:OnMilestoneRewardClaimed(milestoneControl)
    ZO_PromotionalEvents_Shared.OnMilestoneRewardClaimed(self, milestoneControl)

    self:UpdateMilestoneThresholdColor(milestoneControl)
end

function ZO_PromotionalEvents_Gamepad:SelectMilestone(displayIndex)
    if displayIndex then
        local milestoneControl = self.milestonePool:GetActiveObject(displayIndex)
        if milestoneControl then
            local previousSelectedMilestone = self.selectedMilestone
            self.selectedMilestone = milestoneControl

            if previousSelectedMilestone then
                previousSelectedMilestone.rewardObject.highlight:SetHidden(true)
                self:UpdateMilestoneThresholdColor(previousSelectedMilestone)
            end

            milestoneControl.rewardObject.highlight:SetHidden(false)
            self:UpdateMilestoneThresholdColor(milestoneControl)
            self.focusedRewardData = milestoneControl.rewardObject.displayRewardData
            GAMEPAD_TOOLTIPS:LayoutRewardData(GAMEPAD_RIGHT_TOOLTIP, self.focusedRewardData)

            return true
        end
    else
        if self.selectedMilestone then
            local previousSelectedMilestone = self.selectedMilestone
            self.selectedMilestone = nil
            previousSelectedMilestone.rewardObject.highlight:SetHidden(true)
            self:UpdateMilestoneThresholdColor(previousSelectedMilestone)
        end
    end
    return false
end

function ZO_PromotionalEvents_Gamepad:TrySelectPreviousMilestone()
    if self.selectedMilestone and self.selectedMilestone.displayIndex > 1 then
        SCREEN_NARRATION_MANAGER:QueueCustomEntry("promotionalEventsMilestone")
        return self:SelectMilestone(self.selectedMilestone.displayIndex - 1)
    end
    return false
end

function ZO_PromotionalEvents_Gamepad:TrySelectNextMilestone()
    if self.selectedMilestone and self.selectedMilestone.displayIndex < self.currentCampaignData:GetNumMilestones() then
        SCREEN_NARRATION_MANAGER:QueueCustomEntry("promotionalEventsMilestone")
        return self:SelectMilestone(self.selectedMilestone.displayIndex + 1)
    end
    return false
end

function ZO_PromotionalEvents_Gamepad:TrySelectFirstMilestone()
    if self.currentCampaignData then
        if self.currentCampaignData:GetNumMilestones() > 0 then
            SCREEN_NARRATION_MANAGER:QueueCustomEntry("promotionalEventsMilestone")
            return self:SelectMilestone(1)
        end
    end
    return false
end

function ZO_PromotionalEvents_Gamepad:TrySelectLastMilestone()
    if self.currentCampaignData then
        local numMilestones = self.currentCampaignData:GetNumMilestones()
        if numMilestones > 0 then
            SCREEN_NARRATION_MANAGER:QueueCustomEntry("promotionalEventsMilestone")
            return self:SelectMilestone(numMilestones)
        end
    end
    return false
end

function ZO_PromotionalEvents_Gamepad:Activate()
    if ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:IsShowing() then
        ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:DeactivateCurrentList()
        ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:RemoveListKeybinds()
        GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE:RemoveFragmentGroup(FRAGMENT_GROUP.GAMEPAD_ACTIVITY_FINDER_QUEUE_DATA_DEPENDENCIES)
    elseif PROMOTIONAL_EVENTS_LIST_GAMEPAD:IsShowing() then
        PROMOTIONAL_EVENTS_LIST_GAMEPAD:DeactivateCurrentList()
        PROMOTIONAL_EVENTS_LIST_GAMEPAD:RemoveListKeybinds()
    end

    self:SetDirectionalInputEnabled(true)
    if self:IsReturningPlayerRewardsEntrySelected() then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.rewardsGridListKeybindStripDesciptor)
        self.rewardsGridList:Activate()
    else
        if not self:GetCurrentFocus() then
            self:SelectFocusArea(self.overviewFocalArea)
        end
        self:ActivateCurrentFocus()
    end
    PlaySound(SOUNDS.PROMOTIONAL_EVENTS_WINDOW_OPEN)
    self.isActive = true
end

function ZO_PromotionalEvents_Gamepad:Deactivate()
    if not self.lastSelectedMilestoneIndex then
        self.lastSelectedMilestoneIndex = self.selectedMilestone and self.selectedMilestone.displayIndex
    end
    if not self.lastSelectedData then
        self.lastSelectedData = self.selectedData
    end
    self:SetDirectionalInputEnabled(false)
    self:DeactivateCurrentFocus()
    if self.rewardsGridList:IsActive() then
        self.rewardsGridList:Deactivate()
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.rewardsGridListKeybindStripDesciptor)
    end
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    self.focusedRewardData = nil
    self.preferActivityDescriptionTooltip = false
    self.isActive = false
    GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_ACTIVITY_FINDER_QUEUE_DATA_DEPENDENCIES)
    if ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:IsShowing() then
        ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:AddListKeybinds()
        ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:ActivateCurrentList()
    elseif PROMOTIONAL_EVENTS_LIST_GAMEPAD:IsShowing() then
        PROMOTIONAL_EVENTS_LIST_GAMEPAD:AddListKeybinds()
        PROMOTIONAL_EVENTS_LIST_GAMEPAD:ActivateCurrentList()
    end
end

function ZO_PromotionalEvents_Gamepad:RefreshAll(rebuild)
    ZO_PromotionalEvents_Shared.RefreshAll(self, rebuild)

    if rebuild then
        self:SelectFocusArea(self.overviewFocalArea)
    end
end

function ZO_PromotionalEvents_Gamepad:OnSelectionChanged(previouslySelected, selected)
    ZO_SortFilterList_Gamepad.OnSelectionChanged(self, previouslySelected, selected)

    self.activitiesFocalArea:UpdateKeybinds()

    self:UpdateActivityTooltip()
end

function ZO_PromotionalEvents_Gamepad:UpdateActivityTooltip()
    self.focusedRewardData = nil
    local selectedActivityEntry = self.selectedData
    if selectedActivityEntry then
        local rewardObject = self:GetActivityRewardObject(selectedActivityEntry)
        local displayRewardData = rewardObject and rewardObject.displayRewardData
        local description = ""
        if self.preferActivityDescriptionTooltip or not displayRewardData then
            description = selectedActivityEntry:GetDescription()
            local requiredCollectibleText = ZO_PromotionalEvents_Shared.GetActivityRequiredCollectibleText(selectedActivityEntry)
            if requiredCollectibleText then
                if description == "" then
                    description = requiredCollectibleText
                else
                    description = string.format("%s\n\n%s", description, requiredCollectibleText)
                end
            end
        end

        if description ~= "" then
            local NO_TITLE = nil
            GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_RIGHT_TOOLTIP, NO_TITLE, description)
        elseif displayRewardData then
            self.focusedRewardData = displayRewardData
            GAMEPAD_TOOLTIPS:LayoutRewardData(GAMEPAD_RIGHT_TOOLTIP, displayRewardData)
        else
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
        end
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    end
end

function ZO_PromotionalEvents_Gamepad:OnShowing()
    ZO_PromotionalEvents_Shared.OnShowing(self)

    SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
end

function ZO_PromotionalEvents_Gamepad:OnHiding()
    ZO_PromotionalEvents_Shared.OnHiding(self)

    self:Deactivate()
    SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
end

function ZO_PromotionalEvents_Gamepad:OnPreviewShowing()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.previewKeybindStripDesciptor)
end

function ZO_PromotionalEvents_Gamepad:OnPreviewShown()
    local selectedRewardData = self.previewRewardData
    self:UpdatePreview(selectedRewardData)
    ITEM_PREVIEW_GAMEPAD:RegisterCallback("RefreshActions", function()
        SCREEN_NARRATION_MANAGER:QueueCustomEntry("promotionalEventsPreview")
    end)
end

function ZO_PromotionalEvents_Gamepad:UpdatePreview(rewardData)
    SYSTEMS:GetObject("itemPreview"):ClearPreviewCollection()
    SYSTEMS:GetObject("itemPreview"):PreviewReward(rewardData:GetRewardId())
    GAMEPAD_TOOLTIPS:LayoutRewardData(GAMEPAD_RIGHT_TOOLTIP, rewardData)
    SCREEN_NARRATION_MANAGER:QueueCustomEntry("promotionalEventsPreview")
end

function ZO_PromotionalEvents_Gamepad:OnPreviewHiding()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.previewKeybindStripDesciptor)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    ITEM_PREVIEW_GAMEPAD:UnregisterCallback("RefreshActions")
    self.previewRewardData = nil
end

function ZO_PromotionalEvents_Gamepad:RefreshCampaignList()
    PROMOTIONAL_EVENTS_LIST_GAMEPAD:RefreshList()
end

function ZO_PromotionalEvents_Gamepad:ShowCapstoneDialog()
    ZO_Dialogs_ShowGamepadDialog("PROMOTIONAL_EVENT_CAPSTONE_GAMEPAD", { campaignData = self.currentCampaignData })
end

function ZO_PromotionalEvents_Gamepad:ShowClaimChoiceDialog(rewardData)
    PROMOTIONAL_EVENTS_CLAIM_CHOICE_DIALOG_GAMEPAD:Show(rewardData)
end

function ZO_PromotionalEvents_Gamepad:ScrollToFirstClaimableReward()
    local claimableMilestoneData, claimableCapstoneData, claimableActivityData = ZO_PromotionalEvents_Shared.ScrollToFirstClaimableReward(self)

    if claimableMilestoneData then
        self:SelectFocusArea(self.milestonesFocalArea)
    elseif claimableCapstoneData then
        self:SelectFocusArea(self.capstoneFocalArea)
    elseif claimableActivityData then
        self:SelectFocusArea(self.activitiesFocalArea)
    end

    if claimableMilestoneData then
        self.lastSelectedMilestoneIndex = claimableMilestoneData:GetDisplayIndex()
    end

    if claimableActivityData then
        self.lastSelectedData = claimableActivityData
    end

    self:Activate()
end

-- Overridden from ZO_SortFilterList_Gamepad
function ZO_PromotionalEvents_Gamepad:GetNarrationText()
    local narrations = {}
    if self.selectedData then
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.selectedData:GetDisplayName()))
        if self.selectedData:IsComplete() then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_PROMOTIONAL_EVENT_COMPLETED_NARRATION)))
        else
            local progress = self.selectedData:GetProgress()
            local maxProgress = self.selectedData:GetCompletionThreshold()
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_PROGRESS_BAR_FRACTION_FORMATTER, progress, maxProgress)))
        end
    end
    return narrations
end

function ZO_PromotionalEvents_Gamepad.GetMilestoneScale()
    return 0.75
end

function ZO_PromotionalEvents_Gamepad.GetMilestonePadding()
    return 4
end

function ZO_PromotionalEvents_Gamepad.OnControlInitialized(control)
    PROMOTIONAL_EVENTS_GAMEPAD = ZO_PromotionalEvents_Gamepad:New(control)
end

-- Capstone Dialog --

ZO_PromotionalEvents_CapstoneDialog_Gamepad = ZO_PromotionalEvents_CapstoneDialog_Shared:Subclass()

function ZO_PromotionalEvents_CapstoneDialog_Gamepad:Initialize(control)
    ZO_PromotionalEvents_CapstoneDialog_Shared.Initialize(self, control)

    ZO_Dialogs_RegisterCustomDialog("PROMOTIONAL_EVENT_CAPSTONE_GAMEPAD",
    {
        customControl = control,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.CUSTOM,
            dontEndInWorldInteractions = true,
            allowShowOnNextScene = true,
        },
        canQueue = true,
        setup = function(dialog, data)
            self:SetCampaignData(data.campaignData)

            if self.nextCampaignButton:ShouldBeVisible() then
                self.closeButton:SetAnchor(LEFT, self.nextCampaignButton, RIGHT, 10)
            else
                self.closeButton:SetAnchor(LEFT)
            end
        end,
        narrationText = function()
            local narrations = {}
            local titleText = GetString(SI_PROMOTIONAL_EVENT_CAPSTONE_DIALOG_TITLE_FORMATTER)
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(titleText))
            local rewardName = self.displayRewardData:GetFormattedName()
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(rewardName))
            local stackCount = self.displayRewardData:GetQuantity()
            if stackCount > 1 then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(stackCount))
            end
            return narrations
        end,
        additionalInputNarrationFunction = function()
            local narrationData = {}
            local closeNarrationData =
            {
                name = GetString(SI_DIALOG_CLOSE),
                keybindName = ZO_Keybindings_GetHighestPriorityNarrationStringFromAction("DIALOG_NEGATIVE") or GetString(SI_ACTION_IS_NOT_BOUND),
                enabled = true
            }
            table.insert(narrationData, closeNarrationData)
            local viewInCollectionsNarrationData =
            {
                name = GetString(SI_PROMOTIONAL_EVENT_CAPSTONE_DIALOG_VIEW_IN_COLLECTIONS_KEYBIND_LABEL),
                keybindName = ZO_Keybindings_GetHighestPriorityNarrationStringFromAction("DIALOG_SECONDARY") or GetString(SI_ACTION_IS_NOT_BOUND),
                enabled = true
            }
            table.insert(narrationData, viewInCollectionsNarrationData)
            local nextCampaignNarrationData =
            {
                name = GetString(SI_PROMOTIONAL_EVENT_CAPSTONE_DIALOG_NEXT_CAMPAIGN_KEYBIND_LABEL),
                keybindName = ZO_Keybindings_GetHighestPriorityNarrationStringFromAction("DIALOG_PRIMARY") or GetString(SI_ACTION_IS_NOT_BOUND),
                enabled = true
            }
            table.insert(narrationData, nextCampaignNarrationData)
            return narrationData
        end,
        buttons =
        {
            self.nextCampaignDescriptor,
            self.viewInCollectionsDescriptor,
            self.closeDescriptor,
        },
        finishedCallback = function()
            PROMOTIONAL_EVENT_MANAGER:OnCapstoneDialogClosed()
        end,
    })
end

function ZO_PromotionalEvents_CapstoneDialog_Gamepad:InitializeControls(control)
    ZO_PromotionalEvents_CapstoneDialog_Shared.InitializeControls(self)

    local buttonsContainer = self.control:GetNamedChild("Buttons")

    local function HasNextCampaign()
        local campaignData = self.campaignData
        if campaignData:IsReturningPlayerCampaign() then
            local nextCampaignKey = GetCampaignKeyForNextReturningPlayerCampaign(campaignData:GetId())
            return nextCampaignKey ~= nil and nextCampaignKey ~= 0
        end
        return false
    end

    self.nextCampaignDescriptor =
    {
        keybind = "DIALOG_PRIMARY",
        name = GetString(SI_PROMOTIONAL_EVENT_CAPSTONE_DIALOG_NEXT_CAMPAIGN_KEYBIND_LABEL),
        clickSound = SOUNDS.DIALOG_ACCEPT,
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        callback = function(button)
            local campaignData = self.campaignData
            self:ShowNextCampaign(campaignData)
        end,
        visible = HasNextCampaign,
        enabled = HasNextCampaign,
        ethereal = true,
    }
    self.nextCampaignButton = buttonsContainer:GetNamedChild("NextCampaign")
    self.nextCampaignButton:SetKeybindButtonDescriptor(self.nextCampaignDescriptor)

    local function ShouldShowViewInCollectionsKeybind()
        -- This code runs before setup
        local campaignData = self.campaignData
        local baseRewardData = campaignData:GetRewardData()
        local _, wasFallbackClaimed = campaignData:IsRewardClaimed()
        local displayRewardData = wasFallbackClaimed and baseRewardData:GetFallbackRewardData() or baseRewardData
        return displayRewardData:GetRewardType() == REWARD_ENTRY_TYPE_COLLECTIBLE
    end

    self.viewInCollectionsDescriptor =
    {
        keybind = "DIALOG_SECONDARY",
        name = GetString(SI_PROMOTIONAL_EVENT_CAPSTONE_DIALOG_VIEW_IN_COLLECTIONS_KEYBIND_LABEL),
        clickSound = SOUNDS.DIALOG_ACCEPT,
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        callback = function()
            self:ViewInCollections()
        end,
        visible = ShouldShowViewInCollectionsKeybind,
        enabled = ShouldShowViewInCollectionsKeybind,
        ethereal = true,
    }
    self.viewInCollectionsButton = buttonsContainer:GetNamedChild("ViewInCollections")
    self.viewInCollectionsButton:SetKeybindButtonDescriptor(self.viewInCollectionsDescriptor)

    self.closeDescriptor =
    {
        keybind = "DIALOG_NEGATIVE",
        name = GetString(SI_DIALOG_CLOSE),
        clickSound = SOUNDS.DIALOG_DECLINE,
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        callback = function()
            ZO_Dialogs_ReleaseDialog("PROMOTIONAL_EVENT_CAPSTONE_GAMEPAD")
            local campaignData = self.campaignData
            if campaignData:IsReturningPlayerCampaign() then
                if campaignData:AreAllRewardsClaimed() then
                    if HasNextCampaign() then
                        self:ShowNextCampaign(campaignData)
                    else
                        self:RefreshCampaignList()
                        PROMOTIONAL_EVENTS_GAMEPAD:Deactivate()
                    end
                else
                    self:RefreshCampaignList()
                    PROMOTIONAL_EVENTS_LIST_GAMEPAD:SelectCampaign(campaignData)
                end
            end
        end,
        ethereal = true,
    }
    self.closeButton = buttonsContainer:GetNamedChild("Close")
    self.closeButton:SetKeybindButtonDescriptor(self.closeDescriptor)

    self.overlayGlowControl:SetColor(ZO_OFF_WHITE:UnpackRGB())
end

function ZO_PromotionalEvents_CapstoneDialog_Gamepad:InitializeParticleSystems()
    ZO_PromotionalEvents_CapstoneDialog_Shared.InitializeParticleSystems(self)

    local headerSparksParticleSystem = self.headerSparksParticleSystem
    headerSparksParticleSystem:SetParentControl(self.control:GetNamedChild("TopDivider"))

    local headerStarbustParticleSystem = self.headerStarbustParticleSystem
    headerStarbustParticleSystem:SetParentControl(self.control:GetNamedChild("TopDivider"))
end

function ZO_PromotionalEvents_CapstoneDialog_Gamepad:SetCampaignData(campaignData)
    ZO_PromotionalEvents_CapstoneDialog_Shared.SetCampaignData(self, campaignData)

    self.nextCampaignButton:UpdateVisibility()
    self.viewInCollectionsButton:UpdateVisibility()
end

function ZO_PromotionalEvents_CapstoneDialog_Gamepad:RefreshCampaignList()
    PROMOTIONAL_EVENTS_GAMEPAD:RefreshCampaignList()
end

-- Choice Reward Claim Dialog --

ZO_PromotionalEvents_ClaimChoiceDialog_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_PromotionalEvents_ClaimChoiceDialog_Gamepad:Initialize(control)
    PROMOTIONAL_EVENTS_CLAIM_CHOICE_SCENE = ZO_Scene:New("promotionalEventsClaimChoice_Gamepad", SCENE_MANAGER)
    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, PROMOTIONAL_EVENTS_CLAIM_CHOICE_SCENE)
    self.list = self:GetMainList()
    local DEFAULT_EQUALITY_FUNCTION = nil
    self.list:AddDataTemplate("ZO_PromotionalEvent_ChoiceRewardEntry_Template_GP", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, DEFAULT_EQUALITY_FUNCTION, "ChoiceRewardGP")

    self.parentRewardableEventData = nil
    self.currentSelectedChoice = nil
    self.showCapstoneDialogOnClose = false

    self:InitializeHeader()

    self.fragment = ZO_SimpleSceneFragment:New(control)
    PROMOTIONAL_EVENTS_CLAIM_CHOICE_FRAGMENT = self.fragment
    self.fragment:SetHideOnSceneHidden(true)
    self.scene:AddFragment(PROMOTIONAL_EVENTS_CLAIM_CHOICE_FRAGMENT)

    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("RewardsClaimed", ZO_GetCallbackForwardingFunction(self, self.OnRewardsClaimed))
end

function ZO_PromotionalEvents_ClaimChoiceDialog_Gamepad:InitializeHeader()
    self.headerData =
    {
        titleText = GetString(SI_PROMOTIONAL_EVENT_CHOICE_REWARD_CLAIM_HEADER),
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_PromotionalEvents_ClaimChoiceDialog_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- "Select" Keybind
        {
            name = GetString(SI_GAMEPAD_PROMOTIONAL_EVENT_SELECT_CHOICE),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local targetData = self.list:GetTargetData()
                if targetData then
                    self.currentSelectedChoice = targetData
                    self:RefreshSelectedChoice()
                end
            end,
        },
         -- "Confirm" Keybind
        {
            name = GetString(SI_DIALOG_CONFIRM),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                self.parentRewardableEventData:TryClaimReward(self.currentSelectedChoice.rewardId)
                local remainingChoiceRewards = PROMOTIONAL_EVENTS_GAMEPAD:GetRemainingChoiceRewards()
                table.remove(remainingChoiceRewards, 1)
                if next(remainingChoiceRewards) ~= nil then
                    PROMOTIONAL_EVENTS_GAMEPAD:TryClaimNextChoiceReward()
                else
                    self:Hide()
                end
            end,

            enabled = function()
                return self.parentRewardableEventData ~= nil and self.currentSelectedChoice ~= nil
            end,
        },

        -- Back
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor(),
    }
end

function ZO_PromotionalEvents_ClaimChoiceDialog_Gamepad:PerformUpdate()
    self.dirty = false
end

function ZO_PromotionalEvents_ClaimChoiceDialog_Gamepad:Show(rewardableEventData)
    self:SetRewardData(rewardableEventData)
    SCENE_MANAGER:Push(self.scene:GetName())
end

function ZO_PromotionalEvents_ClaimChoiceDialog_Gamepad:Hide()
    if self:IsShowing() then
        SCENE_MANAGER:HideCurrentScene()
    end
end

function ZO_PromotionalEvents_ClaimChoiceDialog_Gamepad:IsShowing()
    return self.scene:IsShowing()
end

function ZO_PromotionalEvents_ClaimChoiceDialog_Gamepad:OnShow()
    ZO_Gamepad_ParametricList_Screen.OnShow(self)
    local selectedData = self.list:GetSelectedData()
    self:RefreshTooltips(selectedData)
end

function ZO_PromotionalEvents_ClaimChoiceDialog_Gamepad:OnHide()
    ZO_Gamepad_ParametricList_Screen.OnHide(self)

    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)

    if self.showCapstoneDialogOnClose then
        PROMOTIONAL_EVENTS_GAMEPAD:ShowCapstoneDialog()
        self.showCapstoneDialogOnClose = false
    end
end

-- Overridden from base
function ZO_PromotionalEvents_ClaimChoiceDialog_Gamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    self:RefreshTooltips(selectedData)
end

function ZO_PromotionalEvents_ClaimChoiceDialog_Gamepad:CreateRewardEntry(rewardEntryData)
    local name = rewardEntryData:GetFormattedName()
    local icon = rewardEntryData:GetGamepadLootIcon()
    local entryData = ZO_GamepadEntryData:New(name, icon)
    entryData:SetStackCount(rewardEntryData:GetQuantity())
    entryData:SetNameColors(entryData:GetColorsBasedOnQuality(rewardEntryData:GetItemDisplayQuality()))
    entryData:SetDataSource(rewardEntryData)

    return entryData
end

function ZO_PromotionalEvents_ClaimChoiceDialog_Gamepad:RefreshSelectedChoice()
    local numRewardEntries = self.list:GetNumEntries()
    for listIndex = 1, numRewardEntries do
        local entryData = self.list:GetEntryData(listIndex)
        entryData:SetSelected(entryData == self.currentSelectedChoice)
    end

    self.list:RefreshVisible()
    self:RefreshKeybinds()
end

function ZO_PromotionalEvents_ClaimChoiceDialog_Gamepad:RefreshTooltips(selectedData)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    if selectedData then
        local rewardType = selectedData:GetRewardType()
        if rewardType then
            GAMEPAD_TOOLTIPS:LayoutRewardData(GAMEPAD_LEFT_TOOLTIP, selectedData)
            if rewardType == REWARD_ENTRY_TYPE_ITEM then
                local itemLink = selectedData:GetItemLink()
                if itemLink then
                    ZO_LayoutItemLinkEquippedComparison(GAMEPAD_RIGHT_TOOLTIP, itemLink)
                end
            end
        end
    end
end

function ZO_PromotionalEvents_ClaimChoiceDialog_Gamepad:SetRewardData(rewardableEventData)
    self.parentRewardableEventData = rewardableEventData
    local rewardData = self.parentRewardableEventData:GetRewardData()

    self.list:Clear()

    for _, reward in ipairs(rewardData:GetChoices()) do
        local entryData = self:CreateRewardEntry(reward)
        entryData:SetSelected(self.currentSelectedChoice == reward)
        self.list:AddEntry("ZO_PromotionalEvent_ChoiceRewardEntry_Template_GP", entryData)
    end

    self.list:CommitWithoutReselect()
end

function ZO_PromotionalEvents_ClaimChoiceDialog_Gamepad:OnRewardsClaimed(campaignData, rewards, hasCapstoneReward)
    -- Since ZO_PromotionalEvents_ClaimChoiceDialog_Gamepad is a separate screen from ZO_PromotionalEvents_Gamepad,
    -- we need to handle a capstone reward being claimed while we're in the process of showing or hiding this scene.
    if hasCapstoneReward and (self.scene:GetState() ~= SCENE_HIDDEN or SCENE_MANAGER:IsShowingNext("promotionalEventsClaimChoice_Gamepad")) then
        self.showCapstoneDialogOnClose = true
    end
end

function ZO_PromotionalEvents_ClaimChoiceDialog_Gamepad:ShouldShowCapstoneDialogOnClose()
    return self.showCapstoneDialogOnClose
end

function ZO_PromotionalEvents_ClaimChoiceDialog_Gamepad.OnControlInitialized(control)
    PROMOTIONAL_EVENTS_CLAIM_CHOICE_DIALOG_GAMEPAD = ZO_PromotionalEvents_ClaimChoiceDialog_Gamepad:New(control)
end

-- Reward List Scene --

ZO_PromotionalEvents_RewardList_Screen_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_PromotionalEvents_RewardList_Screen_Gamepad:Initialize(control)
    PROMOTIONAL_EVENTS_REWARD_LIST_SCENE = ZO_Scene:New("promotionalEventsRewardList_Gamepad", SCENE_MANAGER)
    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, PROMOTIONAL_EVENTS_REWARD_LIST_SCENE)
    self.list = self:GetMainList()
    self:InitializeHeader()

    self.fragment = ZO_SimpleSceneFragment:New(control)
    PROMOTIONAL_EVENTS_REWARD_LIST_FRAGMENT = self.fragment
    self.fragment:SetHideOnSceneHidden(true)
    self.scene:AddFragment(PROMOTIONAL_EVENTS_REWARD_LIST_FRAGMENT)
end

function ZO_PromotionalEvents_RewardList_Screen_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- "Preview" Keybind
        {
            name =  function()
                        if IsCurrentlyPreviewing() then
                            return GetString(SI_PROMOTIONAL_EVENT_REWARD_END_PREVIEW_ACTION)
                        else
                            return GetString(SI_PROMOTIONAL_EVENT_REWARD_PREVIEW_ACTION)
                        end
                    end,
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                self:TogglePreview()
            end,

            enabled = function()
                return IsCharacterPreviewingAvailable(), GetString(SI_PREVIEW_UNAVAILABLE_ERROR)
            end,

            visible = function()
                local targetData = self.list:GetTargetData()
                if targetData then
                    return CanPreviewReward(targetData:GetRewardId())
                end
                return false
            end,
        },

        -- Back
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor(),
    }
end

function ZO_PromotionalEvents_RewardList_Screen_Gamepad:InitializeHeader()
    self.headerData =
    {
        titleText = GetString(SI_GAMEPAD_TOOLTIPS_REWARD_LIST_HEADER),
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_PromotionalEvents_RewardList_Screen_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)
    if self.queuedRewardListId ~= nil then
        self:ShowRewardList(self.queuedRewardListId)
        self.queuedRewardListId = nil
    end
end

function ZO_PromotionalEvents_RewardList_Screen_Gamepad:OnHiding()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    self:EndPreview()
end

function ZO_PromotionalEvents_RewardList_Screen_Gamepad:SetRewardList(rewardListId)
    if SCENE_MANAGER:IsShowing(self.scene.name) then
        self:ShowRewardList(rewardListId)
    else
        self.queuedRewardListId = rewardListId
    end
end

function ZO_PromotionalEvents_RewardList_Screen_Gamepad:ShowRewardList(rewardListId)
    self.list:Clear()

    local rewards = REWARDS_MANAGER:GetAllRewardInfoForRewardList(rewardListId)

    for index, reward in ipairs(rewards) do
        local name = reward:GetFormattedName()
        local iconTextureFile = reward:GetGamepadIcon()
        local entryData = ZO_GamepadEntryData:New(name, iconTextureFile)

        entryData:SetDataSource(reward)
        entryData:SetStackCount(reward:GetQuantity())

        local displayQuality = reward:GetItemDisplayQuality()
        entryData.displayQuality = displayQuality or ITEM_DISPLAY_QUALITY_NORMAL
        entryData:SetNameColors(entryData:GetColorsBasedOnQuality(displayQuality))

        entryData.hasPreview = CanPreviewReward(reward:GetRewardId())

        self.list:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
    end

    self.list:Commit()
    self.list:SetSelectedIndexWithoutAnimation(1)
end

function ZO_PromotionalEvents_RewardList_Screen_Gamepad:OnTargetChanged(list, targetData, oldTargetData)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)

    if targetData then
        local rewardId = targetData:GetRewardId()
        if rewardId and rewardId ~= 0 then
            GAMEPAD_TOOLTIPS:LayoutReward(GAMEPAD_LEFT_TOOLTIP, rewardId, targetData:GetQuantity(), REWARD_DISPLAY_FLAGS_FROM_CROWN_STORE_CONTAINER)
        end
        self:UpdatePreview()
    end
end

function ZO_PromotionalEvents_RewardList_Screen_Gamepad:TogglePreview()
    if IsCurrentlyPreviewing() then
        self:EndPreview()
    else
        local targetData = self.list:GetTargetData()
        if targetData and targetData.hasPreview then
            local rewardId = targetData:GetRewardId()
            if rewardId then
                local previewInEmptyWorld = targetData:GetRewardType() == REWARD_TYPE_ITEM
                ITEM_PREVIEW_GAMEPAD:SetPreviewInEmptyWorld(previewInEmptyWorld)
                ITEM_PREVIEW_GAMEPAD:PreviewReward(rewardId)
            end
        end
    end
    self:RefreshKeybinds()
    SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.list)
end

function ZO_PromotionalEvents_RewardList_Screen_Gamepad:UpdatePreview()
    if IsCurrentlyPreviewing() then
        local targetData = self.list:GetTargetData()
        if targetData and targetData.hasPreview then
            local rewardId = targetData:GetRewardId()
            if rewardId then
                local previewInEmptyWorld = targetData:GetRewardType() == REWARD_TYPE_ITEM
                ITEM_PREVIEW_GAMEPAD:SetPreviewInEmptyWorld(previewInEmptyWorld)
                ITEM_PREVIEW_GAMEPAD:PreviewReward(rewardId)
            end
        else
            self:EndPreview()
        end
    end
    self:RefreshKeybinds()
end

function ZO_PromotionalEvents_RewardList_Screen_Gamepad:EndPreview()
    ITEM_PREVIEW_GAMEPAD:EndCurrentPreview()
    self:RefreshKeybinds()
end

function ZO_PromotionalEvents_RewardList_Screen_Gamepad:PerformUpdate()
    -- This function is required but unused
    self.dirty = false
end

function ZO_PromotionalEvents_RewardList_Screen_Gamepad.OnControlInitialized(control)
    PROMOTIONAL_EVENTS_REWARD_LIST_SCREEN_GAMEPAD = ZO_PromotionalEvents_RewardList_Screen_Gamepad:New(control)
end