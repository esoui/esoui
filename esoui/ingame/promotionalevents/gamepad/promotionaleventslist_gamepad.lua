ZO_PromotionalEventsList_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_PromotionalEventsList_Gamepad:Initialize(control)
    local ACTIVATE_ON_SHOW = true
    local scene = ZO_Scene:New("PromotionalEventsListGamepad", SCENE_MANAGER)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_DO_NOT_CREATE_TAB_BAR, ACTIVATE_ON_SHOW, scene)

    self.fragment = ZO_FadeSceneFragment:New(self.control)
end

function ZO_PromotionalEventsList_Gamepad:OnDeferredInitialize()
    self.headerData =
    {
        titleText = GetString(SI_ACTIVITY_FINDER_CATEGORY_PROMOTIONAL_EVENTS),
    }

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    PROMOTIONAL_EVENTS_GAMEPAD:PerformDeferredInitialize()
    self:RegisterForEvents()
end

function ZO_PromotionalEventsList_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:DeactivateCurrentList()
                PROMOTIONAL_EVENTS_GAMEPAD:Activate()
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

function ZO_PromotionalEventsList_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)

    if self.queuedCampaignData then
        self:SelectCampaign(self.queuedCampaignData)
        self.queuedCampaignData = nil
    end
end

function ZO_PromotionalEventsList_Gamepad:SetupList(list)
    ZO_Gamepad_ParametricList_Screen.SetupList(self, list)

    list:SetDataTemplateSetupFunction("ZO_GamepadMenuEntryTemplate", function(control, data, selected, reselectingDuringRebuild, enabled, active)
        if data:AreAllRewardsClaimed() then
            local DEFAULT = nil
            data:SetNameColors(DEFAULT, DEFAULT)
        else
            data:SetNameColors(ZO_PROMOTIONAL_EVENT_SELECTED_COLOR, ZO_PROMOTIONAL_EVENT_UNSELECTED_COLOR)
        end
        data:ClearIcons()
        if not data.isReturningPlayerRewardsEntry and (not data:HasBeenSeen() or data:IsAnyRewardClaimable()) then
            data:AddIcon(ZO_GAMEPAD_NEW_ICON_64)
        end

        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    end)

    self.equalityFunction = function(leftData, rightData)
        local leftCampaignData = leftData.dataSource or leftData
        local rightCampaignData = rightData.dataSource or rightData
        return leftCampaignData:MatchesKeyWithCampaign(rightCampaignData)
    end
    list:SetEqualityFunction("ZO_GamepadMenuEntryTemplate", self.equalityFunction)

    self.list = list
end

function ZO_PromotionalEventsList_Gamepad:RegisterForEvents()
    local function RefreshVisible()
        if self:IsShowing() then
            self.list:RefreshVisible()
            self.list:Commit()
        end
    end
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("RewardsClaimed", RefreshVisible)
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("CampaignSeenStateChanged", RefreshVisible)

    local function Update()
        self:Update()
    end
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("CampaignsUpdated", Update)
end

function ZO_PromotionalEventsList_Gamepad:RefreshList()
    self.list:Clear()

    local shouldShowRewardsSummary = PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:IsReturningPlayer() and (PROMOTIONAL_EVENT_MANAGER:AreAnyReturningPlayerCampaignsIncomplete() or RETURNING_PLAYER_MANAGER:AreAnyDailyLoginRewardsUnclaimed())

    if shouldShowRewardsSummary then
        local campaignData = ZO_PromotionalEventCampaignData:New()
        campaignData.isReturningPlayerRewardsEntry = true
        local entryData = ZO_GamepadEntryData:New(GetString(SI_PROMOTIONAL_EVENT_RETURNING_PLAYER_REWARD_ENTRY_TITLE))
        entryData:SetDataSource(campaignData)
        self.list:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
    end

    local numActiveCampaigns = PROMOTIONAL_EVENT_MANAGER:GetNumActiveCampaigns()
    for i = 1, numActiveCampaigns do
        local campaignData = PROMOTIONAL_EVENT_MANAGER:GetCampaignDataByIndex(i)
        if campaignData:ShouldCampaignBeVisible() then
            local entryData = ZO_GamepadEntryData:New(campaignData:GetDisplayName())
            entryData:SetDataSource(campaignData)
            self.list:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
        end
    end

    self.list:SetDefaultSelectedIndex(shouldShowRewardsSummary and 2 or 1)
    self.list:Commit()
end

function ZO_PromotionalEventsList_Gamepad:OnTargetChanged(...)
    ZO_Gamepad_ParametricList_Screen.OnTargetChanged(self, ...)

    PROMOTIONAL_EVENTS_GAMEPAD:RefreshDisplay()
end

function ZO_PromotionalEventsList_Gamepad:PerformUpdate()
    self.dirty = false
    if PROMOTIONAL_EVENT_MANAGER:HasActiveCampaign() and not IsPromotionalEventSystemLocked() then
        self:RefreshList()
    else
        SCENE_MANAGER:HideCurrentScene()
    end
end

function ZO_PromotionalEventsList_Gamepad:SelectCampaign(campaignData)
    if self:IsShowing() then
        self.list:SetSelectedDataByEval(function(data) return self.equalityFunction(data, campaignData) end)
    else
        self.queuedCampaignData = campaignData
    end
end

function ZO_PromotionalEventsList_Gamepad:GetScene()
    return self.scene
end

function ZO_PromotionalEventsList_Gamepad:GetFragment()
    return self.fragment
end

function ZO_PromotionalEventsList_Gamepad.OnControlInitialized(control)
    PROMOTIONAL_EVENTS_LIST_GAMEPAD = ZO_PromotionalEventsList_Gamepad:New(control)
end