-----------------
-- Leaderboard Campaign Selector Gamepad
-----------------

local ZO_LeaderboardCampaignSelector_Gamepad = ZO_LeaderboardCampaignSelector_Shared:Subclass()

function ZO_LeaderboardCampaignSelector_Gamepad:IsGamepad()
    return true
end

function ZO_LeaderboardCampaignSelector_Gamepad:OnQueryTypeChanged(campaignEntry)
    ZO_LeaderboardCampaignSelector_Shared.OnQueryTypeChanged(self, campaignEntry)
    self.selectedCampaignData = campaignEntry
    self:SetActiveCampaign()
end

function ZO_LeaderboardCampaignSelector_Gamepad:SetActiveCampaign()
    if self.selectedCampaignData then
        GAMEPAD_LEADERBOARDS:SetActiveCampaign(GetCampaignName(self:GetCampaignId()), self.selectedCampaignData.icon)
    else
        local NO_NAME, NO_ICON
        GAMEPAD_LEADERBOARDS:SetActiveCampaign(NO_NAME, NO_ICON)
    end
end

-----------------
-- Campaign Leaderboards Gamepad
-----------------

ZO_CampaignLeaderboardsManager_Gamepad = ZO_CampaignLeaderboardsManager_Shared:Subclass()

function ZO_CampaignLeaderboardsManager_Gamepad:Initialize(control)
    GAMEPAD_CAMPAIGN_LEADERBOARD_FRAGMENT = ZO_SimpleSceneFragment:New(control)

    ZO_CampaignLeaderboardsManager_Shared.Initialize(self, control, GAMEPAD_LEADERBOARDS, GAMEPAD_LEADERBOARDS_SCENE, GAMEPAD_CAMPAIGN_LEADERBOARD_FRAGMENT)

    GAMEPAD_CAMPAIGN_LEADERBOARD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:SetActiveCampaign()
        end
    end)

    SYSTEMS:RegisterGamepadObject(ZO_CAMPAIGN_LEADERBOARD_SYSTEM_NAME, self)
    GAMEPAD_LEADERBOARDS:RegisterLeaderboardSystemObject(self, LEADERBOARD_DATA_TYPE.CAMPAIGN)
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
    
    --Raid/Endless Archive uses 4 for its timer, and might have set it, so campaign will clear it just in case
    headerData.data4HeaderText = ""
    headerData.data4Text = ""

    ZO_GamepadGenericHeader_RefreshData(GAMEPAD_LEADERBOARD_LIST.contentHeader, headerData)
end

function ZO_CampaignLeaderboardsManager_Gamepad:SetActiveCampaign()
    self.selector:SetActiveCampaign()
end

function ZO_CampaignLeaderboardsManager_Gamepad:InitializeKeybindStripDescriptor()
    self.keybind =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        name = GetString(SI_GAMEPAD_LEADERBOARDS_SWITCH_CAMPAIGN_LEADERBOARD),
        keybind = "UI_SHORTCUT_SECONDARY",
        callback = function()
            local selectedEntry = GAMEPAD_LEADERBOARDS:GetSelectedLeaderboardData()
            GAMEPAD_LEADERBOARDS:ActivateCategoryDropdown(selectedEntry)
        end,
        visible = function()
            local selectedEntry = GAMEPAD_LEADERBOARDS:GetSelectedLeaderboardData()
            return selectedEntry and selectedEntry.addDropdownEntriesCallback
        end,
        sound = SOUNDS.DEFAULT_CLICK,
    }
end

function ZO_CampaignLeaderboardsManager_Gamepad.OnControlInitialized(control)
    GAMEPAD_CAMPAIGN_LEADERBOARDS = ZO_CampaignLeaderboardsManager_Gamepad:New(control)
end