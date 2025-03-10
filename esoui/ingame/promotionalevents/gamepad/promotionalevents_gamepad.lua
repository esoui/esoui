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
            menuIcon = "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_PromotionalEvents.dds",
            disabledMenuIcon = "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_PromotionalEvents_disabled.dds",
            categoryFragment = self:GetFragment(),
            activateCategory = function()
                self:Activate()
            end,
            visible = function()
                return PROMOTIONAL_EVENT_MANAGER:HasActiveCampaign()
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
        if GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE:IsShowing() then
            self:Deactivate()
        end
        -- TODO Promotional Events: Add check for if there's more than one campaign to control drill in
    end

    local CLAIM_ALL_DESCRIPTOR =
    {
        name = GetString(SI_PROMOTIONAL_EVENT_CLAIM_ALL_REWARDS_ACTION),
        keybind = "UI_SHORTCUT_QUINARY",

        visible = function()
            return self.currentCampaignData:IsAnyRewardClaimable()
        end,

        callback = function()
            self.currentCampaignData:TryClaimAllAvailableRewards()
        end,
    }

    -- Overview
    local function ActivateOverviewCallback()
        self.campaignPanelHighlight:SetHidden(false)
        GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_RIGHT_TOOLTIP, self.currentCampaignData:GetDisplayName(), self.currentCampaignData:GetDescription())
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
                self.selectedMilestone.rewardObject.rewardableEventData:TryClaimReward()
                SCREEN_NARRATION_MANAGER:QueueCustomEntry("promotionalEventsMilestone")
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
                SCENE_MANAGER:Push("promotionalEventsPreview_Gamepad")
            end,

            enabled = function()
                return IsCharacterPreviewingAvailable(), GetString(SI_PREVIEW_UNAVAILABLE_ERROR)
            end,

            visible = function()
                return CanPreviewReward(self.selectedMilestone.rewardObject.displayRewardData:GetRewardId())
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
                self.capstoneRewardObject.rewardableEventData:TryClaimReward()
                SCREEN_NARRATION_MANAGER:QueueCustomEntry("promotionalEventsCapstone")
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
                SCENE_MANAGER:Push("promotionalEventsPreview_Gamepad")
            end,

            enabled = function()
                return IsCharacterPreviewingAvailable(), GetString(SI_PREVIEW_UNAVAILABLE_ERROR)
            end,

            visible = function()
                return CanPreviewReward(self.capstoneRewardObject.displayRewardData:GetRewardId())
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
        -- Claim
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_PROMOTIONAL_EVENT_CLAIM_REWARD_ACTION),
            keybind = "UI_SHORTCUT_PRIMARY",

            visible = function()
                local selectedActivityEntry = self:GetSelectedActivity()
                return selectedActivityEntry and selectedActivityEntry:CanClaimReward() or false
            end,

            callback = function()
                self:GetSelectedActivity():TryClaimReward()
                SCREEN_NARRATION_MANAGER:QueueSortFilterListEntry(self)
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
                SCENE_MANAGER:Push("promotionalEventsPreview_Gamepad")
            end,

            enabled = function()
                return IsCharacterPreviewingAvailable(), GetString(SI_PREVIEW_UNAVAILABLE_ERROR)
            end,

            visible = function()
                local selectedActivityEntry = self:GetSelectedActivity()
                if selectedActivityEntry then
                    local rewardObject = self:GetActivityRewardObject(selectedActivityEntry)
                    local displayRewardData = rewardObject and rewardObject.displayRewardData
                    return displayRewardData and CanPreviewReward(displayRewardData:GetRewardId())
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

function ZO_PromotionalEvents_Gamepad:RefreshActivityList(rebuild)
    ZO_PromotionalEvents_Shared.RefreshActivityList(self, rebuild)

    if self.currentCampaignData then
        if self:IsCurrentFocusArea(self.activitiesFocalArea) then
            self.activitiesFocalArea:UpdateKeybinds()
        end
    end
end

function ZO_PromotionalEvents_Gamepad:OnRewardsClaimed(campaignData, rewards)
    ZO_PromotionalEvents_Shared.OnRewardsClaimed(self, campaignData, rewards)

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
    if GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE:IsShowing() then
        ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:DeactivateCurrentList()
        ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:RemoveListKeybinds()
        GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE:RemoveFragmentGroup(FRAGMENT_GROUP.GAMEPAD_ACTIVITY_FINDER_QUEUE_DATA_DEPENDENCIES)
    end
    -- TODO Promotional Events: Add check for if there's more than one campaign to control drill in
    
    self:SetDirectionalInputEnabled(true)
    if not self:GetCurrentFocus() then
        self:SelectFocusArea(self.overviewFocalArea)
    end
    self:ActivateCurrentFocus()
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
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    self.focusedRewardData = nil
    self.preferActivityDescriptionTooltip = false
    self.isActive = false
    GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_ACTIVITY_FINDER_QUEUE_DATA_DEPENDENCIES)
    if ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:IsShowing() then
        ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:AddListKeybinds()
        ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:ActivateCurrentList()
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

function ZO_PromotionalEvents_Gamepad:ShowCapstoneDialog()
    ZO_Dialogs_ShowGamepadDialog("PROMOTIONAL_EVENT_CAPSTONE_GAMEPAD", { campaignData = self.currentCampaignData })
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
        },
        canQueue = true,
        setup = function(dialog, data)
            self:SetCampaignData(data.campaignData)
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
            return narrationData
        end,
        buttons =
        {
            {
                keybind = "DIALOG_SECONDARY",
                text = SI_PROMOTIONAL_EVENT_CAPSTONE_DIALOG_VIEW_IN_COLLECTIONS_KEYBIND_LABEL,
                clickSound = SOUNDS.DIALOG_ACCEPT,
                alignment = KEYBIND_STRIP_ALIGN_CENTER,
                callback = function() self:ViewInCollections() end,
                visible = function(dialog)
                    -- This code runs before setup
                    local campaignData = dialog.data.campaignData
                    local baseRewardData = campaignData:GetRewardData()
                    local _, wasFallbackClaimed = campaignData:IsRewardClaimed()
                    local displayRewardData = wasFallbackClaimed and baseRewardData:GetFallbackRewardData() or baseRewardData
                    return displayRewardData:GetRewardType() == REWARD_ENTRY_TYPE_COLLECTIBLE
                end,
                ethereal = true,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CLOSE,
                clickSound = SOUNDS.DIALOG_DECLINE,
                alignment = KEYBIND_STRIP_ALIGN_CENTER,
                ethereal = true,
            },
        },
    })
end

function ZO_PromotionalEvents_CapstoneDialog_Gamepad:InitializeControls(control)
    ZO_PromotionalEvents_CapstoneDialog_Shared.InitializeControls(self)

    local buttonsContainer = self.control:GetNamedChild("Buttons")

    local viewInCollectionsDescriptor = 
    {
        name = GetString(SI_PROMOTIONAL_EVENT_CAPSTONE_DIALOG_VIEW_IN_COLLECTIONS_KEYBIND_LABEL),
        keybind = "DIALOG_SECONDARY",
        callback = function() self:ViewInCollections() end,
    }
    self.viewInCollectionsButton = buttonsContainer:GetNamedChild("ViewInCollections")
    self.viewInCollectionsButton:SetKeybindButtonDescriptor(viewInCollectionsDescriptor)

    local closeDescriptor = 
    {
        name = GetString(SI_DIALOG_CLOSE),
        keybind = "DIALOG_NEGATIVE",
        callback = function() ZO_Dialogs_ReleaseDialog("PROMOTIONAL_EVENT_CAPSTONE_GAMEPAD") end
    }
    self.closeButton = buttonsContainer:GetNamedChild("Close")
    self.closeButton:SetKeybindButtonDescriptor(closeDescriptor)

    self.overlayGlowControl:SetColor(ZO_OFF_WHITE:UnpackRGB())
end

function ZO_PromotionalEvents_CapstoneDialog_Gamepad:InitializeParticleSystems()
    ZO_PromotionalEvents_CapstoneDialog_Shared.InitializeParticleSystems(self)
    
    local blastParticleSystem = self.blastParticleSystem

    local headerSparksParticleSystem = self.headerSparksParticleSystem
    headerSparksParticleSystem:SetParentControl(self.control:GetNamedChild("TopDivider"))

    local headerStarbustParticleSystem = self.headerStarbustParticleSystem
    headerStarbustParticleSystem:SetParentControl(self.control:GetNamedChild("TopDivider"))
end

function ZO_PromotionalEvents_CapstoneDialog_Gamepad:SetCampaignData(campaignData)
    ZO_PromotionalEvents_CapstoneDialog_Shared.SetCampaignData(self, campaignData)

    self.viewInCollectionsButton:SetHidden(self.displayRewardData:GetRewardType() ~= REWARD_ENTRY_TYPE_COLLECTIBLE)
end