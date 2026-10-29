
-----------------
-- Leaderboard Campaign Selector Keyboard
-----------------

local ZO_LeaderboardCampaignSelector_Keyboard = ZO_LeaderboardCampaignSelector_Shared:Subclass()

function ZO_LeaderboardCampaignSelector_Keyboard:Initialize(control)
    ZO_LeaderboardCampaignSelector_Shared.Initialize(self, control)

    local campaignsDropdownControl = control:GetNamedChild("Campaigns")
    local campaignsDropdown = ZO_ComboBox_ObjectFromContainer(campaignsDropdownControl)
    campaignsDropdown:SetSortsItems(true)
    self:SetCampaignsDropdown(campaignsDropdown)
end

-----------------
-- Campaign Leaderboards Keyboard
-----------------

ZO_CampaignLeaderboardsManager_Keyboard = ZO_CampaignLeaderboardsManager_Shared:Subclass()

function ZO_CampaignLeaderboardsManager_Keyboard:Initialize(control)
    CAMPAIGN_LEADERBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)

    ZO_CampaignLeaderboardsManager_Shared.Initialize(self, control, LEADERBOARDS, LEADERBOARDS_SCENE, CAMPAIGN_LEADERBOARD_FRAGMENT)

    self.currentScoreLabel = control:GetNamedChild("CurrentScore")
    self.currentRankLabel = control:GetNamedChild("CurrentRank")
    self.scoringInfoLabel = control:GetNamedChild("ScoringInfo")
    self.timerLabel = control:GetNamedChild("Timer")

    self:InitializeTimer()

    SYSTEMS:RegisterKeyboardObject(ZO_CAMPAIGN_LEADERBOARD_SYSTEM_NAME, self)
    LEADERBOARDS:RegisterLeaderboardSystemObject(self, LEADERBOARD_DATA_TYPE.CAMPAIGN)
    self.selector = ZO_LeaderboardCampaignSelector_Keyboard:New(control)
end

function ZO_CampaignLeaderboardsManager_Keyboard:RefreshHeaderPlayerInfo()
    local displayedScore, displayedRank = self:GetScoreAndRankTexts()
    local rankingTypeText = GetString("SI_LEADERBOARDTYPE", LEADERBOARD_LIST_MANAGER.leaderboardRankType)

    self.currentScoreLabel:SetText(zo_strformat(SI_CAMPAIGN_LEADERBOARDS_CURRENT_POINTS, displayedScore))
    self.currentRankLabel:SetText(zo_strformat(SI_LEADERBOARDS_CURRENT_RANK, rankingTypeText, displayedRank))
end

function ZO_CampaignLeaderboardsManager_Keyboard:RefreshHeaderTimer()
    if self.timerLabelData then
        self.timerLabel:SetText(zo_strformat(self.timerLabelIdentifier, self.timerLabelData))
    else
        self.timerLabel:SetText("")
    end

    self.scoringInfoLabel:SetText(self.scoringInfoText)
end

function ZO_CampaignLeaderboardsInformationArea_OnInitialized(self)
    CAMPAIGN_LEADERBOARDS = ZO_CampaignLeaderboardsManager_Keyboard:New(self)
end