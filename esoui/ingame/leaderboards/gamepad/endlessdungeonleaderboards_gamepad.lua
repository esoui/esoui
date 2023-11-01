ZO_EndlessDungeonLeaderboardsManager_Gamepad = ZO_EndlessDungeonLeaderboardsManager_Shared:Subclass()

function ZO_EndlessDungeonLeaderboardsManager_Gamepad:Initialize(control)
    GAMEPAD_ENDLESS_DUNGEON_LEADERBOARD_FRAGMENT = ZO_SimpleSceneFragment:New(control)

    ZO_EndlessDungeonLeaderboardsManager_Shared.Initialize(self, control, GAMEPAD_LEADERBOARDS, GAMEPAD_LEADERBOARDS_SCENE, GAMEPAD_ENDLESS_DUNGEON_LEADERBOARD_FRAGMENT)

    GAMEPAD_ENDLESS_DUNGEON_LEADERBOARD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
           self:UpdateAllInfo()
           local NO_NAME = nil 
           local NO_ICON = nil
           GAMEPAD_LEADERBOARDS:SetActiveCampaign(NO_NAME, NO_ICON)
           self:SendLeaderboardQuery()
        end
    end)

    SYSTEMS:RegisterGamepadObject("endlessDungeonLeaderboards", self)
    GAMEPAD_LEADERBOARDS:RegisterLeaderboardSystemObject(self)
end

function ZO_EndlessDungeonLeaderboardsManager_Gamepad:PerformDeferredInitialization()
    if self.isInitialized then return end

    self:RegisterForEvents()

    self.isInitialized = true
end

function ZO_EndlessDungeonLeaderboardsManager_Gamepad:RefreshHeaderPlayerInfo()
    local headerData = GAMEPAD_LEADERBOARD_LIST:GetContentHeaderData()
    
    headerData.data1HeaderText = GetString(SI_GAMEPAD_LEADERBOARDS_BEST_SCORE_LABEL)
    headerData.data1Text = self.currentScoreData or GetString(SI_LEADERBOARDS_NO_SCORE_RECORDED)

    local rankingTypeText = GetString("SI_LEADERBOARDTYPE", LEADERBOARD_LIST_MANAGER.leaderboardRankType)
    headerData.data2HeaderText = zo_strformat(SI_GAMEPAD_LEADERBOARDS_CURRENT_RANK_LABEL, rankingTypeText)
    headerData.data2Text = self.currentRankData or GetString(SI_LEADERBOARDS_NOT_RANKED)
end

function ZO_EndlessDungeonLeaderboardsManager_Gamepad:RefreshHeaderTimer()
    local headerData = GAMEPAD_LEADERBOARD_LIST:GetContentHeaderData()

    if self.timerLabelData then
        if self.timerLabelIdentifier == SI_LEADERBOARDS_REOPENS_IN_TIMER then
            headerData.data4HeaderText = GetString(SI_GAMEPAD_LEADERBOARDS_REOPENS_IN_TIMER_LABEL)
        else
            headerData.data4HeaderText = GetString(SI_GAMEPAD_LEADERBOARDS_CLOSES_IN_TIMER_LABEL)
        end
        headerData.data4Text = zo_strformat(SI_GAMEPAD_LEADERBOARDS_TIMER, self.timerLabelData)
    else
        headerData.data4HeaderText = ""
        headerData.data4Text = ""
    end

    ZO_GamepadGenericHeader_RefreshData(GAMEPAD_LEADERBOARD_LIST.contentHeader, headerData)
end

function ZO_EndlessDungeonLeaderboardsManager_Gamepad:UpdateEndlessDungeonScore()
    ZO_EndlessDungeonLeaderboardsManager_Shared.UpdateEndlessDungeonScore(self)

    if not self.selectedSubType then
        return
    end

    local eligible = not self.participating or self.credited
    local headerData = GAMEPAD_LEADERBOARD_LIST:GetContentHeaderData()
    headerData.data3HeaderText = GetString(SI_GAMEPAD_LEADERBOARDS_CURRENT_SCORE_LABEL)
    headerData.data3Text = eligible and self.currentScoreData or zo_strformat(SI_GAMEPAD_LEADERBOARDS_CURRENT_SCORE_NOT_ELIGIBLE, self.currentScoreData)

    ZO_GamepadGenericHeader_RefreshData(GAMEPAD_LEADERBOARD_LIST.contentHeader, headerData)
end

function ZO_EndlessDungeonLeaderboardsManager_Gamepad:GetFragment()
    return GAMEPAD_ENDLESS_DUNGEON_LEADERBOARD_FRAGMENT
end

function ZO_EndlessDungeonLeaderboardsInformationArea_Gamepad_OnInitialized(self)
    GAMEPAD_ENDLESS_DUNGEON_LEADERBOARDS = ZO_EndlessDungeonLeaderboardsManager_Gamepad:New(self)
end