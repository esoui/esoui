local ICON_SIZE = 60

local HOME_TAB = {
    queryType = BGQUERY_ASSIGNED_CAMPAIGN,
    icon = zo_iconFormat("EsoUI/Art/Campaign/Gamepad/gp_overview_menuIcon_home.dds", ICON_SIZE, ICON_SIZE),
}

local LOCAL_TAB = {
    queryType = BGQUERY_LOCAL,
    icon = zo_iconFormat("EsoUI/Art/Campaign/Gamepad/gp_overview_menuIcon_guest.dds", ICON_SIZE, ICON_SIZE),
}

-----------------
-- Leaderboard Campaign Selector Gamepad
-----------------

local ZO_LeaderboardCampaignSelector_Gamepad = ZO_LeaderboardCampaignSelector_Shared:Subclass()

function ZO_LeaderboardCampaignSelector_Gamepad:New(control)
    local selector = ZO_LeaderboardCampaignSelector_Shared.New(self, control)
    return selector
end

function ZO_LeaderboardCampaignSelector_Gamepad:Initialize(control)
    ZO_LeaderboardCampaignSelector_Shared.Initialize(self, control)

    self.dataRegistration = ZO_CampaignDataRegistration:New("CampaignLeaderboardSelectorData_Gamepad", function() return self:NeedsData() end)

    self:RefreshQueryTypes()
end

function ZO_LeaderboardCampaignSelector_Gamepad:SetCampaignWindows()
    self.campaignWindows =
    {
        SYSTEMS:GetGamepadObject(CAMPAIGN_LEADERBOARD_SYSTEM_NAME),
    }
end

function ZO_LeaderboardCampaignSelector_Gamepad:NeedsData()
    return (GAMEPAD_CAMPAIGN_LEADERBOARD_FRAGMENT:IsShowing() and self.selectedQueryType == BGQUERY_ASSIGNED_CAMPAIGN)
end

function ZO_LeaderboardCampaignSelector_Gamepad:RefreshQueryTypes()
    if not self.selectedQueryType then
        if self:IsHomeSelectable() then
            self:OnQueryTypeChanged(HOME_TAB)
        elseif self:IsLocalSelectable() then
            self:OnQueryTypeChanged(LOCAL_TAB)
        end
    else
        if self.selectedQueryType == HOME_TAB.queryType then
            self:OnQueryTypeChanged(HOME_TAB)
        elseif GetCurrentCampaignId() ~= 0 and self.selectedQueryType == LOCAL_TAB.queryType then
            self:OnQueryTypeChanged(LOCAL_TAB)
        end
    end
end

function ZO_LeaderboardCampaignSelector_Gamepad:OnQueryTypeChanged(tabData)
    ZO_LeaderboardCampaignSelector_Shared.OnQueryTypeChanged(self, tabData)
    self:SetActiveCampaign(GetCampaignName(self:GetCampaignId()), tabData)
    self.selectedTabData = tabData
end

function ZO_LeaderboardCampaignSelector_Gamepad:SetActiveCampaign(campaignName, tabData)
    GAMEPAD_LEADERBOARDS:SetActiveCampaign(campaignName, tabData.icon)
end

-----------------
-- Campaign Leaderboards Gamepad
-----------------

local ZO_CampaignLeaderboardsManager_Gamepad = ZO_CampaignLeaderboardsManager_Shared:Subclass()

function ZO_CampaignLeaderboardsManager_Gamepad:New(...)    
    return ZO_CampaignLeaderboardsManager_Shared.New(self, ...)
end

function ZO_CampaignLeaderboardsManager_Gamepad:Initialize(control)
    GAMEPAD_CAMPAIGN_LEADERBOARD_FRAGMENT = ZO_SimpleSceneFragment:New(control)

    ZO_CampaignLeaderboardsManager_Shared.Initialize(self, control, GAMEPAD_LEADERBOARDS, GAMEPAD_LEADERBOARDS_SCENE, GAMEPAD_CAMPAIGN_LEADERBOARD_FRAGMENT)

    GAMEPAD_CAMPAIGN_LEADERBOARD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
                                                 if newState == SCENE_FRAGMENT_SHOWING then
                                                     self.selector.dataRegistration:Refresh()
                                                     self:SetActiveCampaign()
                                                 elseif newState == SCENE_FRAGMENT_HIDDEN then
                                                     self.selector.dataRegistration:Refresh()
                                                 end
                                             end)

    SYSTEMS:RegisterGamepadObject(CAMPAIGN_LEADERBOARD_SYSTEM_NAME, self)
    GAMEPAD_LEADERBOARDS:RegisterLeaderboardSystemObject(self)
    self.selector = ZO_LeaderboardCampaignSelector_Gamepad:New(control)
end

function ZO_CampaignLeaderboardsManager_Gamepad:PerformDeferredInitialization(control)
    if not self.isInitialized then
        self:InitializeTimer()
        self:InitializeKeybindStripDescriptor()

        self.isInitialized = true
    end
end

function ZO_CampaignLeaderboardsManager_Gamepad:RefreshHeaderPlayerInfo()
    local headerData = GAMEPAD_LEADERBOARD_LIST:GetContentHeaderData()
    local displayedScore, displayedRank = self:GetScoreAndRankTexts()
    local rankingTypeText = GetString("SI_LEADERBOARDTYPE", LEADERBOARD_LIST_MANAGER.leaderboardRankType)

    headerData.data1HeaderText = GetString(SI_GAMEPAD_CAMPAIGN_LEADERBOARDS_CURRENT_POINTS_LABEL)
    headerData.data1Text = displayedScore

    headerData.data2HeaderText = zo_strformat(SI_GAMEPAD_LEADERBOARDS_CURRENT_RANK_LABEL, rankingTypeText)
    headerData.data2Text = displayedRank
end

function ZO_CampaignLeaderboardsManager_Gamepad:RefreshHeaderTimer()
    local headerData = GAMEPAD_LEADERBOARD_LIST:GetContentHeaderData()

    if self.timerLabelData then
        if self.timerLabelIdentifier == SI_LEADERBOARDS_REOPENS_IN_TIMER then
            headerData.data3HeaderText = GetString(SI_GAMEPAD_LEADERBOARDS_REOPENS_IN_TIMER_LABEL)
        else
            headerData.data3HeaderText = GetString(SI_GAMEPAD_LEADERBOARDS_CLOSES_IN_TIMER_LABEL)
        end
        headerData.data3Text = zo_strformat(SI_GAMEPAD_LEADERBOARDS_TIMER, self.timerLabelData)
    else
        headerData.data3HeaderText = ""
        headerData.data3Text = ""
    end

    --Raid uses 4 for its timer, and might have set it, so campaign will clear it just in case
    headerData.data4HeaderText = ""
    headerData.data4Text = ""

    ZO_GamepadGenericHeader_RefreshData(GAMEPAD_LEADERBOARD_LIST.contentHeader, headerData)
end

function ZO_CampaignLeaderboardsManager_Gamepad:SetActiveCampaign()
    self.selector:SetActiveCampaign(GetCampaignName(self.selector:GetCampaignId()), self.selector.selectedTabData)
end

function ZO_CampaignLeaderboardsManager_Gamepad:InitializeKeybindStripDescriptor()
    self.keybind =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        name = GetString(SI_GAMEPAD_LEADERBOARDS_SWITCH_CAMPAIGN_LEADERBOARD),
        keybind = "UI_SHORTCUT_SECONDARY",
        callback = function()
            if self.selector.selectedQueryType == HOME_TAB.queryType then
                self.selector:OnQueryTypeChanged(LOCAL_TAB)
            else
                self.selector:OnQueryTypeChanged(HOME_TAB)
            end
        end,
        visible = function() return self.selector:IsHomeSelectable() and self.selector:IsLocalSelectable() end,
        sound = SOUNDS.DEFAULT_CLICK,
    }
end

function ZO_CampaignLeaderboardsInformationArea_Gamepad_OnInitialized(self)
    GAMEPAD_CAMPAIGN_LEADERBOARDS = ZO_CampaignLeaderboardsManager_Gamepad:New(self)
end