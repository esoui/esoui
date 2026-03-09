-- Reward --

local g_PromotionalEventsKeyboard = nil

ZO_PromotionalEventReward_Keyboard = ZO_PromotionalEventReward_Shared:Subclass()

function ZO_PromotionalEventReward_Keyboard:Initialize(control)
    ZO_PromotionalEventReward_Shared.Initialize(self, control)

    control.icon = self.iconTexture -- For ZO_GridEntry_SetIconScaledUp
    control.GetRewardData = function()
        return self.displayRewardData
    end
end

function ZO_PromotionalEventReward_Keyboard:OnMouseEnter()
    ZO_Rewards_Shared_OnMouseEnter(self.control, RIGHT, LEFT, -5)
    if not self.rewardableEventData:IsRewardClaimed() then
        ZO_GridEntry_SetIconScaledUp(self.control, true)
    end
    if CanPreviewReward(self.displayRewardData:GetRewardId()) and not self.rewardableEventData:CanClaimReward() then
        WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_PREVIEW)
    end
    g_PromotionalEventsKeyboard:SetMouseOverObject(self)
end

function ZO_PromotionalEventReward_Keyboard:OnMouseExit()
    ZO_Rewards_Shared_OnMouseExit(self.control)
    ZO_GridEntry_SetIconScaledUp(self.control, false)
    WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
    g_PromotionalEventsKeyboard:SetMouseOverObject(nil)
end

function ZO_PromotionalEventReward_Keyboard:OnMouseUp(button, upInside)
    if upInside then
        local rewardId = self.displayRewardData:GetRewardId()
        if button == MOUSE_BUTTON_INDEX_LEFT then
            if self.rewardableEventData:CanClaimReward() then
                if GetRewardType(rewardId) == REWARD_ENTRY_TYPE_CHOICE then
                    local CLAIM_ONE = false
                    g_PromotionalEventsKeyboard:ShowClaimChoiceDialog(self.rewardableEventData, CLAIM_ONE)
                else
                    self.rewardableEventData:TryClaimReward()
                end
            elseif CanPreviewReward(rewardId) or GetRewardType(rewardId) == REWARD_ENTRY_TYPE_REWARD_LIST then
                g_PromotionalEventsKeyboard:BeginPreview(rewardId)
                KEYBIND_STRIP:UpdateKeybindButtonGroup(g_PromotionalEventsKeyboard.keybindStripDescriptor)
            end
        elseif button == MOUSE_BUTTON_INDEX_RIGHT then
            ClearMenu()
            local showMenu = false

            if self.rewardableEventData:CanClaimReward() then
                AddMenuItem(GetString(SI_PROMOTIONAL_EVENT_CLAIM_REWARD_ACTION), function()
                    if GetRewardType(rewardId) == REWARD_ENTRY_TYPE_CHOICE then
                        local CLAIM_ONE = false
                        g_PromotionalEventsKeyboard:ShowClaimChoiceDialog(self.rewardableEventData, CLAIM_ONE)
                    else
                        self.rewardableEventData:TryClaimReward()
                    end
                end)
                showMenu = true
            end

            local canPreviewReward = CanPreviewReward(rewardId)
            local isRewardList = GetRewardType(rewardId) == REWARD_ENTRY_TYPE_REWARD_LIST
            if canPreviewReward or isRewardList then
                local menuString = isRewardList and SI_REWARD_LIST_VIEW_ACTION or SI_REWARD_PREVIEW_ACTION
                AddMenuItem(GetString(menuString), function()
                    g_PromotionalEventsKeyboard:BeginPreview(rewardId, self.control)
                    KEYBIND_STRIP:UpdateKeybindButtonGroup(g_PromotionalEventsKeyboard.keybindStripDescriptor)
                end)
                showMenu = true
            end

            if showMenu then
                ShowMenu(self.control)
            end
        end
    end
end

function ZO_PromotionalEventReward_Keyboard.OnControlInitialized(control)
    ZO_PromotionalEventReward_Keyboard:New(control)
end

-- Activity --

local g_activityTrackButtonAnimationPool = ZO_AnimationPool:New("ZO_PromotionalEvent_Keyboard_MouseOverTrackButtonAnimation")

do
    local function OnAnimationTimelineStopped(timeline)
        if timeline:IsPlayingBackward() then
            timeline.pool:ReleaseObject(timeline.key)
        end
    end

    local function SetupTimeline(timeline, key, pool)
        timeline.key = key
        timeline.pool = pool
        timeline:SetHandler("OnStop", OnAnimationTimelineStopped)
    end

    g_activityTrackButtonAnimationPool:SetCustomFactoryBehavior(SetupTimeline)

    local function ResetTimeline(timeline)
        timeline:ApplyAllAnimationsToControl(nil)
        timeline.trackButton.mouseoverTimeline = nil
        timeline.trackButton = nil
    end

    g_activityTrackButtonAnimationPool:SetCustomResetBehavior(ResetTimeline)
end

ZO_PromotionalEventActivity_Entry_Keyboard = ZO_PromotionalEventActivity_Entry_Shared:Subclass()

function ZO_PromotionalEventActivity_Entry_Keyboard:Initialize(control)
    ZO_PromotionalEventActivity_Entry_Shared.Initialize(self, control)

    ZO_StatusBar_SetGradientColor(self.progressStatusBar, ZO_XP_BAR_GRADIENT_COLORS)
    self.trackButton = control:GetNamedChild("TrackButton")
    self.trackButton.parentObject = self
end

function ZO_PromotionalEventActivity_Entry_Keyboard:OnMouseEnter()
    if not self.isComplete then
        self.nameLabel:SetColor(ZO_HIGHLIGHT_TEXT:UnpackRGB())
    end
    local description = self.activityData:GetDescription()
    local requiredCollectibleText = ZO_PromotionalEvents_Shared.GetActivityRequiredCollectibleText(self.activityData)
    if requiredCollectibleText then
        if description == "" then
            description = requiredCollectibleText
        else
            description = string.format("%s\n\n%s", description, requiredCollectibleText)
        end
    end
    if description ~= "" then
        InitializeTooltip(SmallKeyMarkupInformationTooltip)
        ZO_Tooltips_SetupDynamicTooltipAnchors(SmallKeyMarkupInformationTooltip, self.control)
        local DEFAULT_COLOR = nil
        local DEFAULT_LINE_ANCHOR = nil
        local DEFAULT_MODIFY_TEXT_TYPE = nil
        local DEFAULT_TEXT_ALIGNMENT = nil
        local DEFAULT_SET_TO_FULL_SIZE = nil
        local DEFAULT_MIN_WIDTH = nil
        local LINE_SPACING = 5
        SetTooltipText(SmallKeyMarkupInformationTooltip, description, DEFAULT_COLOR, DEFAULT_COLOR, DEFAULT_COLOR, DEFAULT_LINE_ANCHOR, DEFAULT_MODIFY_TEXT_TYPE, DEFAULT_TEXT_ALIGNMENT, DEFAULT_SET_TO_FULL_SIZE, DEFAULT_MIN_WIDTH, LINE_SPACING)
    end
    g_PromotionalEventsKeyboard:SetMouseOverObject(self)
end

function ZO_PromotionalEventActivity_Entry_Keyboard:OnMouseExit()
    self.nameLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGB())
    ClearTooltip(SmallKeyMarkupInformationTooltip)
    g_PromotionalEventsKeyboard:SetMouseOverObject(nil)
end

function ZO_PromotionalEventActivity_Entry_Keyboard:GetOrCreateTrackButtonMouseoverTimeline()
    local mouseoverTimeline = self.trackButton.mouseoverTimeline
    if not mouseoverTimeline then
        mouseoverTimeline = g_activityTrackButtonAnimationPool:AcquireObject()
        mouseoverTimeline:ApplyAllAnimationsToControl(self.trackButton)
        self.trackButton.mouseoverTimeline = mouseoverTimeline
        mouseoverTimeline.trackButton = self.trackButton
    end
    return mouseoverTimeline
end

function ZO_PromotionalEventActivity_Entry_Keyboard:OnTrackButtonMouseEnter()
    InitializeTooltip(InformationTooltip)
    ZO_Tooltips_SetupDynamicTooltipAnchors(InformationTooltip, self.control)
    if self.activityData:IsTracked() then
        SetTooltipText(InformationTooltip, GetString(SI_PROMOTIONAL_EVENT_UNPIN_TASK_ACTION))
    else
        local mouseoverTimeline = self:GetOrCreateTrackButtonMouseoverTimeline()
        mouseoverTimeline:PlayForward()
        SetTooltipText(InformationTooltip, GetString(SI_PROMOTIONAL_EVENT_PIN_TASK_ACTION))
    end
    self.isMouseOver = true
end

function ZO_PromotionalEventActivity_Entry_Keyboard:OnTrackButtonMouseExit()
    self.isMouseOver = false
    ClearTooltip(InformationTooltip)
    if not self.activityData:IsTracked() then
        self.trackButton.mouseoverTimeline:PlayBackward()
    end
end

function ZO_PromotionalEventActivity_Entry_Keyboard:SetActivityData(activityData)
    ZO_PromotionalEventActivity_Entry_Shared.SetActivityData(self, activityData)

    self:RefreshTrackingButton()
end

function ZO_PromotionalEventActivity_Entry_Keyboard:RefreshTrackingButton()
    if self.activityData:IsComplete() or self.activityData:IsLocked() then
        self.trackButton:SetHidden(true)
    else
        self.trackButton:SetHidden(false)
        if self.activityData:IsTracked() then
            local mouseoverTimeline = self:GetOrCreateTrackButtonMouseoverTimeline()
            mouseoverTimeline:PlayInstantlyToEnd()
            if self.isMouseOver then
                InformationTooltip:ClearLines()
                SetTooltipText(InformationTooltip, GetString(SI_PROMOTIONAL_EVENT_UNPIN_TASK_ACTION))
            end
        else
            if self.isMouseOver then
                InformationTooltip:ClearLines()
                SetTooltipText(InformationTooltip, GetString(SI_PROMOTIONAL_EVENT_PIN_TASK_ACTION))
            elseif self.trackButton.mouseoverTimeline then
                self.trackButton.mouseoverTimeline:PlayBackward()
            end
        end
    end
end

function ZO_PromotionalEventActivity_Entry_Keyboard:OnProgressUpdated(previousProgress, newProgress, rewardFlags)
    ZO_PromotionalEventActivity_Entry_Shared.OnProgressUpdated(self, previousProgress, newProgress, rewardFlags)

    local completionThreshold = self.activityData:GetCompletionThreshold()
    self.trackButton:SetHidden(newProgress == completionThreshold)
end

function ZO_PromotionalEventActivity_Entry_Keyboard.OnControlInitialized(control)
    ZO_PromotionalEventActivity_Entry_Keyboard:New(control)
end

-- Screen --

ZO_PROMOTIONAL_EVENT_KEYBOARD_ACTIVITY_ENTRY_HEIGHT = 75
ZO_PROMOTIONAL_EVENT_RETURNING_PLAYER_REWARD_WIDTH_KEYBOARD = 180
ZO_PROMOTIONAL_EVENT_RETURNING_PLAYER_REWARD_HEIGHT_KEYBOARD = 150
ZO_PROMOTIONAL_EVENT_RETURNING_PLAYER_REWARD_SPACING_KEYBOARD = 30

ZO_PromotionalEvents_Keyboard = ZO_PromotionalEvents_Shared:Subclass()

function ZO_PromotionalEvents_Keyboard:OnDeferredInitialize()
    ZO_PromotionalEvents_Shared.OnDeferredInitialize(self)

    self:InitializeKeybindStripDescriptors()
end

function ZO_PromotionalEvents_Keyboard:InitializeActivityFinderCategory()
    local NO_CHILDREN = {}
    local children = {}

    local function OnSetupChildNode(node, control, categoryData, open)
        if not control.statusIcon then
            control.statusIcon = control:GetNamedChild("StatusIcon")
        end

        control.statusIcon:ClearIcons()
        if categoryData and categoryData.campaignData and categoryData.campaignData:IsAnyRewardClaimable() then
            control.statusIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
            control.statusIcon:Show()
        end
    end

    local function OnTreeEntrySelected(node, control, categoryData, open)
        if self:IsShowing() then
            self:RefreshDisplay()
        end
    end

    local function EqualityFunction(left, right)
        local leftCampaignData = left.campaignData or left
        local rightCampaignData = right.campaignData or right
        if leftCampaignData.isReturningPlayerRewardsEntry ~= nil or rightCampaignData.isReturningPlayerRewardsEntry ~= nil then
            return leftCampaignData.isReturningPlayerRewardsEntry == rightCampaignData.isReturningPlayerRewardsEntry
        end
        if leftCampaignData.IsInstanceOf and leftCampaignData:IsInstanceOf(ZO_PromotionalEventCampaignData) and rightCampaignData.IsInstanceOf and rightCampaignData:IsInstanceOf(ZO_PromotionalEventCampaignData) then
            return leftCampaignData:MatchesKeyWithCampaign(rightCampaignData)
        end
        return false
    end

    local PromotionalEventsCategoryData =
    {
        priority = ZO_ACTIVITY_FINDER_SORT_PRIORITY.PROMOTIONAL_EVENTS,
        name = GetString(SI_ACTIVITY_FINDER_CATEGORY_PROMOTIONAL_EVENTS),
        categoryFragment = self:GetFragment(),
        normalIcon = function()
            if PROMOTIONAL_EVENT_MANAGER:HasAnyUnclaimedRewards() then
                return "EsoUI/Art/LFG/LFG_indexIcon_PromotionalEvents_up.dds"
            else
                return "EsoUI/Art/LFG/LFG_indexIcon_PromotionalEvents_up_complete.dds"
            end
        end,
        pressedIcon = function()
            if PROMOTIONAL_EVENT_MANAGER:HasAnyUnclaimedRewards() then
                return "EsoUI/Art/LFG/LFG_indexIcon_PromotionalEvents_down.dds"
            else
                return "EsoUI/Art/LFG/LFG_indexIcon_PromotionalEvents_down_complete.dds"
            end
        end,
        mouseoverIcon = function()
            if PROMOTIONAL_EVENT_MANAGER:HasAnyUnclaimedRewards() then
                return "EsoUI/Art/LFG/LFG_indexIcon_PromotionalEvents_over.dds"
            else
                return "EsoUI/Art/LFG/LFG_indexIcon_PromotionalEvents_over_complete.dds"
            end
        end,
        disabledIcon = "EsoUI/Art/LFG/LFG_indexIcon_PromotionalEvents_disabled.dds",
        visible = function()
            return PROMOTIONAL_EVENT_MANAGER:HasActiveCampaign() or (IsReturningPlayer() and (PROMOTIONAL_EVENT_MANAGER:AreAnyReturningPlayerCampaignsIncomplete() or RETURNING_PLAYER_MANAGER:AreAnyDailyLoginRewardsUnclaimed()))
        end,
        getChildrenFunction = function()
            local numActiveCampaigns = PROMOTIONAL_EVENT_MANAGER:GetNumActiveCampaigns()
            if numActiveCampaigns > 1 then
                ZO_ClearNumericallyIndexedTable(children)
                local shouldShowRewardsSummary = IsReturningPlayer() and (PROMOTIONAL_EVENT_MANAGER:AreAnyReturningPlayerCampaignsIncomplete() or RETURNING_PLAYER_MANAGER:AreAnyDailyLoginRewardsUnclaimed())
                if shouldShowRewardsSummary then
                    local campaignData = ZO_PromotionalEventCampaignData:New()
                    campaignData.isReturningPlayerRewardsEntry = true
                    local child =
                    {
                        priority = 1,
                        name = GetString(SI_PROMOTIONAL_EVENT_RETURNING_PLAYER_REWARD_ENTRY_TITLE),
                        categoryFragment = self:GetFragment(),
                        campaignData = campaignData,
                        onTreeEntrySelected = OnTreeEntrySelected,
                        equalityFunction = EqualityFunction,
                    }
                    table.insert(children, child)
                end
                local returningPlayerOffset = shouldShowRewardsSummary and 1 or 0
                for i = 1, numActiveCampaigns do
                    local campaignData = PROMOTIONAL_EVENT_MANAGER:GetCampaignDataByIndex(i)
                    if campaignData:ShouldCampaignBeVisible() then
                        local child =
                        {
                            priority = i + returningPlayerOffset,
                            name = campaignData:GetDisplayName(),
                            categoryFragment = self:GetFragment(),
                            campaignData = campaignData,
                            onSetup = OnSetupChildNode,
                            onTreeEntrySelected = OnTreeEntrySelected,
                            equalityFunction = EqualityFunction,
                        }
                        table.insert(children, child)
                    end
                end
                -- Account for the possibility of technically active but completed/hidden returning player campaigns.
                return #children > 0 and children or NO_CHILDREN
            else
                return NO_CHILDREN
            end
        end,
        isLocked = IsPromotionalEventSystemLocked,
        lockedText = GetString(SI_ACTIVITY_FINDER_TOOLTIP_PROMOTIONAL_EVENT_LOCK),
        isNew = function()
            return PROMOTIONAL_EVENT_MANAGER:DoesAnyCampaignHaveCallout()
        end,
        isPromotionalEvent = true,
    }
    GROUP_MENU_KEYBOARD:AddCategory(PromotionalEventsCategoryData)
end

function ZO_PromotionalEvents_Keyboard:InitializeCampaignPanel()
    ZO_PromotionalEvents_Shared.InitializeCampaignPanel(self, "ZO_PromotionalEventMilestone_Template_Keyboard")
    ZO_StatusBar_SetGradientColor(self.campaignProgress, ZO_PROMOTIONAL_EVENT_GRADIENT_COLORS)

    self.campaignHelpButton = self.campaignPanel:GetNamedChild("Help")
end

function ZO_PromotionalEvents_Keyboard:InitializeActivityList()
    ZO_PromotionalEvents_Shared.InitializeActivityList(self, "ZO_PromotionalEventActivity_EntryTemplate_Keyboard", ZO_PROMOTIONAL_EVENT_KEYBOARD_ACTIVITY_ENTRY_HEIGHT)

    local ALLOW_UNCLICK = true
    self.trackedActivityRadioButtonGroup = ZO_RadioButtonGroup:New(ALLOW_UNCLICK)
    self.trackedActivityRadioButtonGroup:SetSelectionChangedCallback(function(_, newControl, previousControl)
        -- If there's a newControl, we'll toggle it on
        -- If not, we want to toggle the previous control off
        local controlToToggle = newControl and newControl or previousControl
        local activityData = controlToToggle.parentObject.activityData
        activityData:ToggleTracking()
    end)
end

function ZO_PromotionalEvents_Keyboard:InitializeGridList()
    ZO_PromotionalEvents_Shared.InitializeGridList(self)

    self.rewardsGridList = ZO_SingleTemplateGridScrollList_Keyboard:New(self.gridListControl, ZO_GRID_SCROLL_LIST_DONT_AUTOFILL)

    local function RewardGridEntryReset(control)
        ZO_ObjectPool_DefaultResetControl(control)
    end

    local DEFAULT_HIDE_CALLBACK = nil
    local HEADER_HEIGHT = 30
    self.rewardsGridList:SetGridEntryTemplate("ZO_PromotionalEventReturningPlayerReward_Keyboard", ZO_PROMOTIONAL_EVENT_RETURNING_PLAYER_REWARD_WIDTH_KEYBOARD, ZO_PROMOTIONAL_EVENT_RETURNING_PLAYER_REWARD_HEIGHT_KEYBOARD, self.RewardGridEntrySetup, DEFAULT_HIDE_CALLBACK, RewardGridEntryReset, ZO_PROMOTIONAL_EVENT_RETURNING_PLAYER_REWARD_SPACING_KEYBOARD, ZO_PROMOTIONAL_EVENT_RETURNING_PLAYER_REWARD_SPACING_KEYBOARD)
    self.rewardsGridList:SetHeaderTemplate(ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_KEYBOARD, HEADER_HEIGHT, ZO_DefaultGridHeaderSetup)
    self.rewardsGridList:SetHeaderPrePadding(ZO_PROMOTIONAL_EVENT_RETURNING_PLAYER_REWARD_SPACING_KEYBOARD)
end

local function GetClaimKeybindLabel(mouseOverObject)
    if not mouseOverObject then
        return
    end
    if  mouseOverObject:IsInstanceOf(ZO_PromotionalEventReward_Keyboard)
        and mouseOverObject.rewardableEventData:CanClaimReward() then
        return GetString(SI_PROMOTIONAL_EVENT_CLAIM_REWARD_ACTION)
    elseif mouseOverObject:IsInstanceOf(ZO_PromotionalEventActivity_Entry_Keyboard) then
        local campaignKey, componentType, index = GetReturningPlayerIntroGameplayData()
        if componentType == PROMOTIONAL_EVENTS_COMPONENT_TYPE_ACTIVITY then
            local activityData = mouseOverObject.activityData
            return zo_strformat(SI_PROMOTIONAL_EVENT_RETURNING_PLAYER_GO_TO_ACTION, RETURNING_PLAYER_MANAGER:GetColorizedIntroGameplayDisplayName())
        end
    elseif  mouseOverObject:IsInstanceOf(ZO_PromotionalEventReward_Keyboard) then
        local campaignKey, componentType, index = GetReturningPlayerIntroGameplayData()
        if componentType == PROMOTIONAL_EVENTS_COMPONENT_TYPE_ACTIVITY then
            local activityData = mouseOverObject.rewardableEventData
            if activityData:IsInstanceOf(ZO_PromotionalEventActivityData) then
                return zo_strformat(SI_PROMOTIONAL_EVENT_RETURNING_PLAYER_GO_TO_ACTION, RETURNING_PLAYER_MANAGER:GetColorizedIntroGameplayDisplayName())
            end
        end
    end
end

local function ShouldClaimKeybindBeVisible(mouseOverObject)
    if not mouseOverObject then
        return false
    end
    if mouseOverObject:IsInstanceOf(ZO_PromotionalEventReward_Keyboard) then
        if mouseOverObject.rewardableEventData:CanClaimReward() then
            return true
        else
            local campaignKey, componentType, index = GetReturningPlayerIntroGameplayData()
            if componentType == PROMOTIONAL_EVENTS_COMPONENT_TYPE_ACTIVITY then
                local activityData = mouseOverObject.rewardableEventData
                if activityData:IsInstanceOf(ZO_PromotionalEventActivityData) then
                    return activityData:MatchesCampaignKey(campaignKey) and activityData:GetActivityIndex() == index and not activityData:IsRewardClaimed()
                end
            end
        end
    elseif mouseOverObject:IsInstanceOf(ZO_PromotionalEventActivity_Entry_Keyboard) then
        local campaignKey, componentType, index = GetReturningPlayerIntroGameplayData()
        if componentType == PROMOTIONAL_EVENTS_COMPONENT_TYPE_ACTIVITY then
            local activityData = mouseOverObject.activityData
            if not (activityData:CanClaimReward() or activityData:IsRewardClaimed()) then
                return activityData:MatchesCampaignKey(campaignKey) and activityData:GetActivityIndex() == index
            end
        end
    end
    return false
end

function ZO_PromotionalEvents_Keyboard:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        -- Claim / Go To Hero's Return
        {
            name = function()
                return GetClaimKeybindLabel(self.mouseOverObject)
            end,

            keybind = "UI_SHORTCUT_PRIMARY",

            callback = function()
                local rewardableEventData = self.mouseOverObject.rewardableEventData
                if rewardableEventData and rewardableEventData:CanClaimReward() then
                    local rewardData = rewardableEventData:GetRewardData()
                    if rewardData:GetRewardType() == REWARD_ENTRY_TYPE_CHOICE then
                        local CLAIM_ONE = false
                        self:ShowClaimChoiceDialog(rewardableEventData, CLAIM_ONE)
                    else
                        rewardableEventData:TryClaimReward()
                    end
                elseif IsReturningPlayer() then
                    SYSTEMS:ShowScene("returningPlayerIntro")
                end
            end,

            visible = function()
                return ShouldClaimKeybindBeVisible(self.mouseOverObject)
            end,
        },

        -- Claim all
        {
            name = GetString(SI_PROMOTIONAL_EVENT_CLAIM_ALL_REWARDS_ACTION),
            keybind = "UI_SHORTCUT_QUATERNARY",

            visible = function()
                if not self:IsReturningPlayerRewardsEntrySelected() then
                    return self.currentCampaignData and self.currentCampaignData:IsAnyRewardClaimable()
                end
                return false
            end,

            callback = function()
                self.currentCampaignData:TryClaimAllAvailableRewards()
                self:CollectRemainingChoiceRewards()
                local CLAIM_ALL = true
                self:TryClaimNextChoiceReward(CLAIM_ALL)
            end,
        },

        -- Preview
        {
            name = function()
                if self.mouseOverObject and self.mouseOverObject:IsInstanceOf(ZO_PromotionalEventReward_Keyboard) then
                    local rewardId = self.mouseOverObject.displayRewardData:GetRewardId()
                    if GetRewardType(rewardId) == REWARD_ENTRY_TYPE_REWARD_LIST then
                        return GetString(SI_REWARD_LIST_VIEW_ACTION)
                    end
                end
                return GetString(SI_REWARD_PREVIEW_ACTION)
            end,
            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                if self.mouseOverObject:IsInstanceOf(ZO_PromotionalEventReward_Keyboard) then
                    self:BeginPreview(self.mouseOverObject.displayRewardData:GetRewardId())
                elseif self.mouseOverObject:IsInstanceOf(ZO_RewardData) then
                    self:BeginPreview(self.mouseOverObject:GetRewardId())
                end
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
            end,

            enabled = function()
                return IsCharacterPreviewingAvailable(), GetString(SI_PREVIEW_UNAVAILABLE_ERROR)
            end,

            visible = function()
                if self.mouseOverObject and self.mouseOverObject:IsInstanceOf(ZO_PromotionalEventReward_Keyboard) then
                    local rewardId = self.mouseOverObject.displayRewardData:GetRewardId()
                    return CanPreviewReward(rewardId) or GetRewardType(rewardId) == REWARD_ENTRY_TYPE_REWARD_LIST
                elseif self.mouseOverObject and self.mouseOverObject:IsInstanceOf(ZO_RewardData) then
                    local rewardId = self.mouseOverObject:GetRewardId()
                    return CanPreviewReward(rewardId)
                end
                return false
            end,
        },

        -- End Preview
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            name = GetString(SI_REWARD_END_PREVIEW_ACTION),
            keybind = "UI_SHORTCUT_NEGATIVE",

            callback = function()
                ITEM_PREVIEW_KEYBOARD:EndCurrentPreview()
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
            end,
            visible = IsCurrentlyPreviewing
        },

        -- Open Crown Store
        {
            name = GetString(SI_CONTENT_REQUIRES_COLLECTIBLE_OPEN_CROWN_STORE),
            keybind = "UI_SHORTCUT_TERTIARY",

            callback = function()
                local requiredCollectibleData = self.mouseOverObject.activityData:GetRequiredCollectibleData()
                if requiredCollectibleData:GetCategoryType() == COLLECTIBLE_CATEGORY_TYPE_CHAPTER then
                    ZO_ShowChapterUpgradePlatformScreen(MARKET_OPEN_OPERATION_PROMOTIONAL_EVENTS)
                else
                    local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, requiredCollectibleData:GetName())
                    ShowMarketAndSearch(searchTerm, MARKET_OPEN_OPERATION_PROMOTIONAL_EVENTS)
                end
            end,

            visible = function()
                if self.mouseOverObject and self.mouseOverObject:IsInstanceOf(ZO_PromotionalEventActivity_Entry_Keyboard) then
                    return self.mouseOverObject.activityData:IsLocked()
                end
                return false
            end,
        },
    }
end

function ZO_PromotionalEvents_Keyboard:IsReturningPlayerRewardsEntrySelected()
    local selectedNode = GROUP_MENU_KEYBOARD:GetTree():GetSelectedNode()
    if selectedNode and selectedNode.data.campaignData then
        return selectedNode.data.campaignData.isReturningPlayerRewardsEntry or false
    end
    return false
end

function ZO_PromotionalEvents_Keyboard:GetSelectedCampaignData()
    local selectedNode = GROUP_MENU_KEYBOARD:GetTree():GetSelectedNode()
    if selectedNode and selectedNode.data.campaignData then
        return selectedNode.data.campaignData
    else
        return PROMOTIONAL_EVENT_MANAGER:GetCampaignDataByIndex(1)
    end
end

function ZO_PromotionalEvents_Keyboard:RefreshActivityList(rebuild)
    ZO_PromotionalEvents_Shared.RefreshActivityList(self, rebuild)

    if self.currentCampaignData then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_PromotionalEvents_Keyboard:BeginPreview(rewardId, anchorControl)
    SYSTEMS:GetObject("itemPreview"):ClearPreviewCollection()
    if GetRewardType(rewardId) == REWARD_ENTRY_TYPE_REWARD_LIST then
        self:PreviewRewardList(rewardId, anchorControl)
    else
        SYSTEMS:GetObject("itemPreview"):PreviewReward(rewardId)
    end
end

local g_highlightAnimationProvider = ZO_ReversibleAnimationProvider:New("ShowOnMouseOverLabelAnimation")

function ZO_PromotionalEvents_Keyboard:PreviewRewardList(rewardId, anchorControl)
    local function OnMouseEnter(control)
        self:SetMouseOverObject(control.dataEntry.data)
    end

    local function OnMouseExit(control)
        self:SetMouseOverObject(nil)
    end

    local anchorControl = anchorControl or self.mouseOverObject.control
    POPUP_LIST:ShowRewardList(rewardId, OnMouseEnter, OnMouseExit, BOTTOMRIGHT, anchorControl, BOTTOMLEFT)
end

function ZO_PromotionalEvents_Keyboard:OnActivityControlSetup(control, data)
    ZO_PromotionalEvents_Shared.OnActivityControlSetup(self, control, data)

    local trackButton = control.object.trackButton
    if data:IsComplete() or data:IsLocked() then
        self.trackedActivityRadioButtonGroup:Remove(trackButton)
    else
        self.trackedActivityRadioButtonGroup:Add(trackButton)
        local IGNORE_CALLBACK = true
        self.trackedActivityRadioButtonGroup:SetButtonClickState(trackButton, data:IsTracked(), IGNORE_CALLBACK)
    end
end

function ZO_PromotionalEvents_Keyboard:SetMouseOverObject(mouseOverObject)
    self.mouseOverObject = mouseOverObject
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_PromotionalEvents_Keyboard:OnRewardsClaimed(campaignData, rewards)
    ZO_PromotionalEvents_Shared.OnRewardsClaimed(self, campaignData, rewards)

    if self:IsShowing() and self.currentCampaignData == campaignData then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_PromotionalEvents_Keyboard:OnHelpButtonMouseEnter()
    if self.currentCampaignData then
        InitializeTooltip(InformationTooltip)
        ZO_Tooltips_SetupDynamicTooltipAnchors(InformationTooltip, self.campaignHelpButton)
        SetTooltipText(InformationTooltip, self.currentCampaignData:GetDescription())
    end
end

function ZO_PromotionalEvents_Keyboard:OnHelpButtonMouseExit()
    ClearTooltip(InformationTooltip)
end

function ZO_PromotionalEvents_Keyboard:OnShowing()
    ZO_PromotionalEvents_Shared.OnShowing(self)

    if self.lastSelectedCampaignData and IsReturningPlayer() then
        if self.lastSelectedCampaignData:ShouldCampaignBeVisible() then
            GROUP_MENU_KEYBOARD:SetCategoryOnShowByData(self.lastSelectedCampaignData)
        else
            local firstVisibleCampaignData
            for _, iterCampaignData in PROMOTIONAL_EVENT_MANAGER:CampaignIterator({ ZO_PromotionalEventCampaignData.ShouldCampaignBeVisible }) do
                firstVisibleCampaignData = iterCampaignData
                break
            end
            if firstVisibleCampaignData then
                GROUP_MENU_KEYBOARD:SetCategoryOnShowByData(firstVisibleCampaignData)
            end
        end
    end

    -- The preview options fragment needs to be added before the ITEM_PREVIEW_KEYBOARD fragment
    SCENE_MANAGER:AddFragment(PROMOTIONAL_EVENTS_PREVIEW_OPTIONS_FRAGMENT)
    SCENE_MANAGER:AddFragment(ITEM_PREVIEW_KEYBOARD:GetFragment())
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    PlaySound(SOUNDS.PROMOTIONAL_EVENTS_WINDOW_OPEN)
end

function ZO_PromotionalEvents_Keyboard:OnHiding()
    ZO_PromotionalEvents_Shared.OnHiding(self)

    self.lastSelectedCampaignData = self.currentCampaignData

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    SCENE_MANAGER:RemoveFragmentImmediately(ITEM_PREVIEW_KEYBOARD:GetFragment())
    SCENE_MANAGER:RemoveFragment(PROMOTIONAL_EVENTS_PREVIEW_OPTIONS_FRAGMENT)
    ITEM_PREVIEW_KEYBOARD:OnPreviewHidden()
    POPUP_LIST:Hide()
end

function ZO_PromotionalEvents_Keyboard:RefreshCampaignList()
    GROUP_MENU_KEYBOARD:RebuildCategories()
end

function ZO_PromotionalEvents_Keyboard:ShowCapstoneDialog()
    ZO_Dialogs_ShowDialog("PROMOTIONAL_EVENT_CAPSTONE_KEYBOARD", { campaignData = self.currentCampaignData })
end

function ZO_PromotionalEvents_Keyboard:ShowClaimChoiceDialog(rewardData, isClaimingAll)
    ZO_Dialogs_ShowDialog("PROMOTIONAL_EVENT_CLAIM_CHOICE_KEYBOARD", { rewardData = rewardData, isClaimingAll = isClaimingAll })
end

function ZO_PromotionalEvents_Keyboard.GetMilestoneScale()
    return 0.85
end

function ZO_PromotionalEvents_Keyboard.GetMilestonePadding()
    return 11
end

function ZO_PromotionalEvents_Keyboard.OnControlInitialized(control)
    g_PromotionalEventsKeyboard = ZO_PromotionalEvents_Keyboard:New(control)
    PROMOTIONAL_EVENTS_KEYBOARD = g_PromotionalEventsKeyboard
end

function ZO_PromotionalEvents_Keyboard.ReturningPlayerReward_OnMouseEnter(control)
    ZO_Rewards_Shared_OnMouseEnter(control, RIGHT, LEFT, -5)
end

function ZO_PromotionalEvents_Keyboard.ReturningPlayerReward_OnMouseExit(control)
    ZO_Rewards_Shared_OnMouseExit(control)
end

-- Capstone Dialog --

ZO_PromotionalEvents_CapstoneDialog_Keyboard = ZO_PromotionalEvents_CapstoneDialog_Shared:Subclass()

function ZO_PromotionalEvents_CapstoneDialog_Keyboard:Initialize(control)
    ZO_PromotionalEvents_CapstoneDialog_Shared.Initialize(self, control)

    ZO_Dialogs_RegisterCustomDialog("PROMOTIONAL_EVENT_CAPSTONE_KEYBOARD",
    {
        customControl = control,
        setup = function(dialog, data)
            self:SetCampaignData(data.campaignData)
        end,
        canQueue = true,
        buttons =
        {
            {
                control = self.nextCampaignButton,
                text = SI_PROMOTIONAL_EVENT_CAPSTONE_DIALOG_NEXT_CAMPAIGN_KEYBIND_LABEL,
                keybind = "DIALOG_PRIMARY",
                callback = function(dialog)
                    local campaignData = dialog.data.campaignData
                    self:ShowNextCampaign(campaignData)
                end,
                visible = function(dialog)
                    local campaignData = dialog.data.campaignData
                    local nextCampaignKey = GetCampaignKeyForNextReturningPlayerCampaign(campaignData:GetId())
                    return campaignData:IsReturningPlayerCampaign() and nextCampaignKey and nextCampaignKey ~= 0
                end,
            },
            {
                control = self.viewInCollectionsButton,
                text = SI_PROMOTIONAL_EVENT_CAPSTONE_DIALOG_VIEW_IN_COLLECTIONS_KEYBIND_LABEL,
                keybind = "DIALOG_TERTIARY",
                callback = function()
                    self:ViewInCollections()
                end,
                visible = function(dialog)
                    -- This code runs before setup
                    local campaignData = dialog.data.campaignData
                    local baseRewardData = campaignData:GetRewardData()
                    local _, wasFallbackClaimed = campaignData:IsRewardClaimed()
                    local displayRewardData = wasFallbackClaimed and baseRewardData:GetFallbackRewardData() or baseRewardData
                    return displayRewardData:GetRewardType() == REWARD_ENTRY_TYPE_COLLECTIBLE
                end,
            },
            {
                control = self.closeButton,
                text = SI_DIALOG_CLOSE,
                keybind = "DIALOG_NEGATIVE",
                callback = function(dialog)
                    local campaignData = dialog.data.campaignData
                    if campaignData:IsReturningPlayerCampaign() then
                        local nextCampaignKey = GetCampaignKeyForNextReturningPlayerCampaign(campaignData:GetId())
                        local hasNextCampaign = nextCampaignKey and nextCampaignKey ~= 0
                        if campaignData:AreAllRewardsClaimed() then
                            if hasNextCampaign then
                                self:ShowNextCampaign(campaignData)
                            else
                                self:RefreshCampaignList()
                            end
                        else
                            self:RefreshCampaignList()
                            GROUP_MENU_KEYBOARD:ShowCategoryByData(campaignData)
                        end
                    end
                end,
            },
        },
        finishedCallback = function()
            PROMOTIONAL_EVENT_MANAGER:OnCapstoneDialogClosed()
        end,
    })
end

function ZO_PromotionalEvents_CapstoneDialog_Keyboard:InitializeControls()
    ZO_PromotionalEvents_CapstoneDialog_Shared.InitializeControls(self)

    self.nextCampaignButton = self.control:GetNamedChild("NextCampaignButton")
    self.viewInCollectionsButton = self.control:GetNamedChild("ViewInCollectionsButton")
    self.closeButton = self.control:GetNamedChild("CloseButton")

    local r, g, b = ZO_OFF_WHITE:UnpackRGB()
    self.overlayGlowControl:SetEdgeColor(r, g, b)
    self.overlayGlowControl:SetCenterColor(r, g, b)

    local headerIcon = self.control:GetNamedChild("HeaderIcon")
    headerIcon:SetHandler("OnMouseUp", function(control, button, upInside)
        if button == MOUSE_BUTTON_INDEX_LEFT and upInside then
            self.blastParticleSystem:Stop()
            self.blastParticleSystem:Start()
        end
    end)

    -- For ZO_PromotionalEvents_CapstoneDialog_Keyboard.OnRewardMouseEnter
    self.rewardFrameControl = self.control:GetNamedChild("RewardContainerFrame")
    self.rewardFrameControl.GetRewardData = function()
        return self.displayRewardData
    end
end

function ZO_PromotionalEvents_CapstoneDialog_Keyboard:InitializeParticleSystems()
    ZO_PromotionalEvents_CapstoneDialog_Shared.InitializeParticleSystems(self)

    local headerSparksParticleSystem = self.headerSparksParticleSystem
    headerSparksParticleSystem:SetParentControl(self.control:GetNamedChild("HeaderFade"))

    local headerStarbustParticleSystem = self.headerStarbustParticleSystem
    headerStarbustParticleSystem:SetParentControl(self.control:GetNamedChild("HeaderFade"))
end

function ZO_PromotionalEvents_CapstoneDialog_Shared:RefreshCampaignList()
    PROMOTIONAL_EVENTS_KEYBOARD:RefreshCampaignList()
end

function ZO_PromotionalEvents_CapstoneDialog_Keyboard.OnRewardMouseEnter(rewardFrameControl)
    ZO_Rewards_Shared_OnMouseEnter(rewardFrameControl, RIGHT, LEFT, -5)
end

function ZO_PromotionalEvents_CapstoneDialog_Keyboard.OnRewardMouseExit(rewardFrameControl)
    ZO_Rewards_Shared_OnMouseExit(rewardFrameControl)
end

-- Choice Reward Claim Dialog --

ZO_PROMOTIONAL_EVENTS_CLAIM_CHOICE_KEYBOARD_ROW_WIDTH = 250
ZO_PROMOTIONAL_EVENTS_CLAIM_CHOICE_KEYBOARD_ROW_HEIGHT = 52

ZO_PROMOTIONAL_EVENTS_CLAIM_CHOICE_LIST_DATA_TYPE_ITEM = 1

ZO_PromotionalEvents_ClaimChoiceDialog_Keyboard = ZO_InitializingObject:Subclass()

function ZO_PromotionalEvents_ClaimChoiceDialog_Keyboard:Initialize(control)
    self.control = control
    control.object = self
    self.parentRewardableEventData = nil
    self.currentSelectedChoice = nil

    -- Order matters for these two function calls.
    self:InitializeControls()
    self:InitializeList()

    ZO_Dialogs_RegisterCustomDialog("PROMOTIONAL_EVENT_CLAIM_CHOICE_KEYBOARD",
    {
        customControl = control,
        setup = function(dialog, data)
            self:SetRewardData(data.rewardData)
        end,
        canQueue = true,
        buttons =
        {
            {
                control =   self.confirmButton,
                text =      SI_DIALOG_CONFIRM,
                keybind =   "DIALOG_PRIMARY",
                callback =  function(dialog)
                    self.parentRewardableEventData:TryClaimReward(self.currentSelectedChoice.rewardId)
                    if dialog.data.isClaimingAll then
                        local remainingChoiceRewards = PROMOTIONAL_EVENTS_KEYBOARD:GetRemainingChoiceRewards()
                        table.remove(remainingChoiceRewards, 1)
                        if next(remainingChoiceRewards) ~= nil then
                            self.shouldTryClaimNextChoiceReward = true
                        end
                    end
                end,
                enabled = function()
                    return self.parentRewardableEventData ~= nil and self.currentSelectedChoice ~= nil
                end
            },
            {
                control =   self.closeButton,
                text =      SI_DIALOG_CLOSE,
                keybind =   "DIALOG_NEGATIVE",
            },
        },
        finishedCallback = function()
            if self.shouldTryClaimNextChoiceReward then
                self.shouldTryClaimNextChoiceReward = nil
                PROMOTIONAL_EVENTS_KEYBOARD:TryClaimNextChoiceReward()
            end
        end,
    })
end

function ZO_PromotionalEvents_ClaimChoiceDialog_Keyboard:InitializeControls()
    local control = self.control
    self.list = control:GetNamedChild("List")
    self.confirmButton = control:GetNamedChild("ConfirmButton")
    self.closeButton = control:GetNamedChild("CloseButton")
end

function ZO_PromotionalEvents_ClaimChoiceDialog_Keyboard:InitializeList()
    ZO_ScrollList_AddDataType(self.list, ZO_PROMOTIONAL_EVENTS_CLAIM_CHOICE_LIST_DATA_TYPE_ITEM, "ZO_PromotionalEventClaimChoice_RewardRow", ZO_PROMOTIONAL_EVENTS_CLAIM_CHOICE_KEYBOARD_ROW_HEIGHT, function(control, data) self:SetUpListItem(control, data) end)
end

function ZO_PromotionalEvents_ClaimChoiceDialog_Keyboard:SetUpListItem(control, data)
    control.data = data

    local nameControl = control:GetNamedChild("Name")
    nameControl:SetText(data.formattedName)

    if data.currencyType and data.currencyType ~= CURT_NONE then
        nameControl:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
    else
        if data.rewardType == REWARD_ENTRY_TYPE_COLLECTIBLE then
            nameControl:SetColor(ZO_WHITE:UnpackRGBA())
        elseif data.displayQuality then
            nameControl:SetColor(GetItemQualityColor(data.displayQuality):UnpackRGBA())
        end
    end

    control.icon = control:GetNamedChild("Icon")
    local iconControl = control.icon
    if data.icon then
        iconControl:SetTexture(data.icon)
        iconControl:SetHidden(false)
    else
        iconControl:SetHidden(true)
    end

    local stackCount = data.quantity
    local stackCountLabel = iconControl:GetNamedChild("StackCount")
    if stackCount and stackCount > 1 then
        stackCountLabel:SetText(ZO_AbbreviateAndLocalizeNumber(stackCount, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES))
    else
        stackCountLabel:SetText("")
    end

    local selectedHighlightControl = control:GetNamedChild("SelectedHighlight")
    if data == self.currentSelectedChoice then
        selectedHighlightControl:SetAlpha(1)
    else
        selectedHighlightControl:SetAlpha(0)
    end

    control:SetHidden(false)
end

function ZO_PromotionalEvents_ClaimChoiceDialog_Keyboard:SetRewardData(rewardableEventData)
    self.parentRewardableEventData = rewardableEventData
    local rewardData = self.parentRewardableEventData:GetRewardData()

    ZO_ScrollList_Clear(self.list)

    for _, reward in ipairs(rewardData:GetChoices()) do
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        local scrollEntryData = ZO_ScrollList_CreateDataEntry(ZO_PROMOTIONAL_EVENTS_CLAIM_CHOICE_LIST_DATA_TYPE_ITEM, reward)
        table.insert(scrollData, scrollEntryData)
    end

    ZO_ScrollList_Commit(self.list)
end

function ZO_PromotionalEvents_ClaimChoiceDialog_Keyboard:RefreshSelectedChoice()
    local scrollData = ZO_ScrollList_GetDataList(self.list)

    for _, entry in ipairs(scrollData) do
        if entry.control then
            local selectedHighlightControl = entry.control:GetNamedChild("SelectedHighlight")
            if entry.data == self.currentSelectedChoice then
                selectedHighlightControl:SetAlpha(1)
            else
                selectedHighlightControl:SetAlpha(0)
            end
        end
    end

    ZO_Dialogs_UpdateButtonVisibilityAndEnabledState(self.control)
end

function ZO_PromotionalEvents_ClaimChoiceDialog_Keyboard.OnListMouseEnter(control)
    local rewardData = control.data
    if rewardData then
        local rewardType = rewardData:GetRewardType()
        if rewardType then
            ZO_Rewards_Shared_OnMouseEnter(control)
        end
    end
    ZO_InventorySlot_SetHighlightHidden(control, false)
end

function ZO_PromotionalEvents_ClaimChoiceDialog_Keyboard.OnListMouseExit(control)
    ZO_Rewards_Shared_OnMouseExit(control)
    ZO_InventorySlot_SetHighlightHidden(control, true)
end

function ZO_PromotionalEvents_ClaimChoiceDialog_Keyboard:OnListRowClicked(control, button, upInside)
    if button == MOUSE_BUTTON_INDEX_LEFT and upInside then
        local rewardData = control.data
        if rewardData then
            local parentChoice = rewardData:GetParentChoice()
            if parentChoice then
                self.currentSelectedChoice = rewardData
                PlaySound(SOUNDS.DEFAULT_CLICK)
                self:RefreshSelectedChoice()
            end
        end
    end
end