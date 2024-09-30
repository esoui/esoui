-- Reward --

local g_PromotionalEventsKeyboard = nil

ZO_PromotionalEventReward_Keyboard = ZO_PromotionalEventReward_Shared:Subclass()

function ZO_PromotionalEventReward_Keyboard:Initialize(control)
    ZO_PromotionalEventReward_Shared.Initialize(self, control)

    control.icon = self.iconTexture -- For ZO_GridEntry_SetIconScaledUp
    control.GetRewardData = function()
        return self.rewardData
    end
    -- TODO Promotional Events: Implement
end

function ZO_PromotionalEventReward_Keyboard:OnMouseEnter()
    ZO_Rewards_Shared_OnMouseEnter(self.control, RIGHT, LEFT, -5)
    if not self.rewardableEventData:IsRewardClaimed() then
        ZO_GridEntry_SetIconScaledUp(self.control, true)
    end
    if CanPreviewReward(self.rewardData:GetRewardId()) and not self.rewardableEventData:CanClaimReward() then
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
        if button == MOUSE_BUTTON_INDEX_LEFT then
            if self.rewardableEventData:CanClaimReward() then
                self.rewardableEventData:TryClaimReward()
            elseif CanPreviewReward(self.rewardData:GetRewardId()) then
                SYSTEMS:GetObject("itemPreview"):ClearPreviewCollection()
                SYSTEMS:GetObject("itemPreview"):PreviewReward(self.rewardData:GetRewardId())
                KEYBIND_STRIP:UpdateKeybindButtonGroup(g_PromotionalEventsKeyboard.keybindStripDescriptor)
            end
        elseif button == MOUSE_BUTTON_INDEX_RIGHT then
            ClearMenu()
            local showMenu = false

            if self.rewardableEventData:CanClaimReward() then
                AddMenuItem(GetString(SI_PROMOTIONAL_EVENT_CLAIM_REWARD_ACTION), function()
                    self.rewardableEventData:TryClaimReward()
                end)
                showMenu = true
            end

            if CanPreviewReward(self.rewardData:GetRewardId()) then
                AddMenuItem(GetString(SI_PROMOTIONAL_EVENT_REWARD_PREVIEW_ACTION), function()
                    SYSTEMS:GetObject("itemPreview"):ClearPreviewCollection()
                    SYSTEMS:GetObject("itemPreview"):PreviewReward(self.rewardData:GetRewardId())
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
    InitializeTooltip(InformationTooltip)
    ZO_Tooltips_SetupDynamicTooltipAnchors(InformationTooltip, self.control)
    SetTooltipText(InformationTooltip, description)
    g_PromotionalEventsKeyboard:SetMouseOverObject(self)
end

function ZO_PromotionalEventActivity_Entry_Keyboard:OnMouseExit()
    self.nameLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGB())
    ClearTooltip(InformationTooltip)
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

function ZO_PromotionalEventActivity_Entry_Keyboard:OnProgressUpdated(previousProgress, newProgress, isRewardClaimed)
    ZO_PromotionalEventActivity_Entry_Shared.OnProgressUpdated(self, previousProgress, newProgress, isRewardClaimed)

    local completionThreshold = self.activityData:GetCompletionThreshold()
    self.trackButton:SetHidden(newProgress == completionThreshold)
end

function ZO_PromotionalEventActivity_Entry_Keyboard.OnControlInitialized(control)
    ZO_PromotionalEventActivity_Entry_Keyboard:New(control)
end

-- Screen --

ZO_PROMOTIONAL_EVENT_KEYBOARD_ACTIVITY_ENTRY_HEIGHT = 75

ZO_PromotionalEvents_Keyboard = ZO_PromotionalEvents_Shared:Subclass()

function ZO_PromotionalEvents_Keyboard:OnDeferredInitialize()
    ZO_PromotionalEvents_Shared.OnDeferredInitialize(self)

    self:InitializeKeybindStripDescriptors()
end

function ZO_PromotionalEvents_Keyboard:InitializeActivityFinderCategory()
    local PromotionalEventsCategoryData =
    {
        priority = ZO_ACTIVITY_FINDER_SORT_PRIORITY.PROMOTIONAL_EVENTS,
        name = GetString(SI_ACTIVITY_FINDER_CATEGORY_PROMOTIONAL_EVENTS),
        categoryFragment = self:GetFragment(),
        normalIcon = "EsoUI/Art/LFG/LFG_indexIcon_PromotionalEvents_up.dds",
        pressedIcon = "EsoUI/Art/LFG/LFG_indexIcon_PromotionalEvents_down.dds",
        mouseoverIcon = "EsoUI/Art/LFG/LFG_indexIcon_PromotionalEvents_over.dds",
        disabledIcon = "EsoUI/Art/LFG/LFG_indexIcon_PromotionalEvents_disabled.dds",
        visible = function()
            return PROMOTIONAL_EVENT_MANAGER:IsCampaignActive()
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

function ZO_PromotionalEvents_Keyboard:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        -- Claim
        {
            name = GetString(SI_PROMOTIONAL_EVENT_CLAIM_REWARD_ACTION),
            keybind = "UI_SHORTCUT_PRIMARY",

            callback = function()
                self.mouseOverObject.rewardableEventData:TryClaimReward()
            end,

            visible = function()
                if self.mouseOverObject and self.mouseOverObject:IsInstanceOf(ZO_PromotionalEventReward_Keyboard) then
                    return self.mouseOverObject.rewardableEventData:CanClaimReward()
                end
                return false
            end,
        },

        -- Claim all
        {
            name = GetString(SI_PROMOTIONAL_EVENT_CLAIM_ALL_REWARDS_ACTION),
            keybind = "UI_SHORTCUT_QUATERNARY",

            visible = function()
                return self.currentCampaignData:IsAnyRewardClaimable()
            end,

            callback = function()
                self.currentCampaignData:TryClaimAllAvailableRewards()
            end,
        },

        -- Preview
        {
            name = GetString(SI_PROMOTIONAL_EVENT_REWARD_PREVIEW_ACTION),
            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                SYSTEMS:GetObject("itemPreview"):ClearPreviewCollection()
                SYSTEMS:GetObject("itemPreview"):PreviewReward(self.mouseOverObject.rewardData:GetRewardId())
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
            end,

            visible = function()
                if self.mouseOverObject and self.mouseOverObject:IsInstanceOf(ZO_PromotionalEventReward_Keyboard) then
                    return CanPreviewReward(self.mouseOverObject.rewardData:GetRewardId())
                end
                return false
            end,
        },

        -- End Preview
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            name = GetString(SI_PROMOTIONAL_EVENT_REWARD_END_PREVIEW_ACTION),
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

function ZO_PromotionalEvents_Keyboard:RefreshActivityList(rebuild)
    ZO_PromotionalEvents_Shared.RefreshActivityList(self, rebuild)

    if self.currentCampaignData then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
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

    -- The preview options fragment needs to be added before the ITEM_PREVIEW_KEYBOARD fragment
    SCENE_MANAGER:AddFragment(PROMOTIONAL_EVENTS_PREVIEW_OPTIONS_FRAGMENT)
    SCENE_MANAGER:AddFragment(ITEM_PREVIEW_KEYBOARD:GetFragment())
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    PlaySound(SOUNDS.PROMOTIONAL_EVENTS_WINDOW_OPEN)
end

function ZO_PromotionalEvents_Keyboard:OnHiding()
    ZO_PromotionalEvents_Shared.OnHiding(self)

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    SCENE_MANAGER:RemoveFragment(ITEM_PREVIEW_KEYBOARD:GetFragment())
    SCENE_MANAGER:RemoveFragment(PROMOTIONAL_EVENTS_PREVIEW_OPTIONS_FRAGMENT)
    ITEM_PREVIEW_KEYBOARD:OnPreviewHidden()
end

function ZO_PromotionalEvents_Keyboard:ShowCapstoneDialog()
    ZO_Dialogs_ShowDialog("PROMOTIONAL_EVENT_CAPSTONE_KEYBOARD", { campaignData = self.currentCampaignData })
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
        buttons =
        {
            {
                control =   self.viewInCollectionsButton,
                text =      SI_PROMOTIONAL_EVENT_CAPSTONE_DIALOG_VIEW_IN_COLLECTIONS_KEYBIND_LABEL,
                keybind =   "DIALOG_TERTIARY",
                callback =  function() self:ViewInCollections() end,
                visible =   function(dialog)
                    return dialog.data.campaignData:GetRewardData():GetRewardType() == REWARD_ENTRY_TYPE_COLLECTIBLE
                end,
            },
            {
                control =   self.closeButton,
                text =      SI_DIALOG_CLOSE,
                keybind =   "DIALOG_NEGATIVE",
            },
        }
    })
end

function ZO_PromotionalEvents_CapstoneDialog_Keyboard:InitializeControls()
    ZO_PromotionalEvents_CapstoneDialog_Shared.InitializeControls(self)

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
        return self.rewardData
    end
end

function ZO_PromotionalEvents_CapstoneDialog_Keyboard:InitializeParticleSystems()
    ZO_PromotionalEvents_CapstoneDialog_Shared.InitializeParticleSystems(self)
    
    local blastParticleSystem = self.blastParticleSystem
    blastParticleSystem:SetParticleParameter("PhysicsInitialVelocityMagnitude", ZO_UniformRangeGenerator:New(700, 1100))
    blastParticleSystem:SetParticleParameter("Size", ZO_UniformRangeGenerator:New(6, 12))
    blastParticleSystem:SetParticleParameter("PhysicsDragMultiplier", 1.5)
    blastParticleSystem:SetParticleParameter("PrimeS", .5)

    local headerSparksParticleSystem = self.headerSparksParticleSystem
    headerSparksParticleSystem:SetParentControl(self.control:GetNamedChild("HeaderFade"))
    headerSparksParticleSystem:SetParticleParameter("PhysicsInitialVelocityMagnitude", ZO_UniformRangeGenerator:New(15, 60))
    headerSparksParticleSystem:SetParticleParameter("Size", ZO_UniformRangeGenerator:New(5, 10))
    headerSparksParticleSystem:SetParticleParameter("DrawLayer", DL_OVERLAY)
    headerSparksParticleSystem:SetParticleParameter("DrawLevel", 2)

    local headerStarbustParticleSystem = self.headerStarbustParticleSystem
    headerStarbustParticleSystem:SetParentControl(self.control:GetNamedChild("HeaderFade"))
    headerStarbustParticleSystem:SetParticleParameter("Size", 256)
    headerStarbustParticleSystem:SetParticleParameter("DrawLayer", DL_OVERLAY)
    headerStarbustParticleSystem:SetParticleParameter("DrawLevel", 1)
end

function ZO_PromotionalEvents_CapstoneDialog_Keyboard.OnRewardMouseEnter(rewardFrameControl)
    ZO_Rewards_Shared_OnMouseEnter(rewardFrameControl, RIGHT, LEFT, -5)
end

function ZO_PromotionalEvents_CapstoneDialog_Keyboard.OnRewardMouseExit(rewardFrameControl)
    ZO_Rewards_Shared_OnMouseExit(rewardFrameControl)
end