local ZO_BattlegroundLeaderboardsManager_Gamepad = ZO_BattlegroundLeaderboardsManager_Shared:Subclass()

function ZO_BattlegroundLeaderboardsManager_Gamepad:New(...)
    return ZO_BattlegroundLeaderboardsManager_Shared.New(self, ...)
end

function ZO_BattlegroundLeaderboardsManager_Gamepad:Initialize(control)
    GAMEPAD_BATTLEGROUND_LEADERBOARD_FRAGMENT = ZO_SimpleSceneFragment:New(control)

    ZO_BattlegroundLeaderboardsManager_Shared.Initialize(self, control, GAMEPAD_LEADERBOARDS, GAMEPAD_LEADERBOARDS_SCENE, GAMEPAD_BATTLEGROUND_LEADERBOARD_FRAGMENT)

    GAMEPAD_BATTLEGROUND_LEADERBOARD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
                                                 if newState == SCENE_FRAGMENT_SHOWING then
                                                    self:UpdateAllInfo()
                                                    local NO_NAME, NO_ICON
                                                    GAMEPAD_LEADERBOARDS:SetActiveCampaign(NO_NAME, NO_ICON)
                                                 end
                                             end)

    SYSTEMS:RegisterGamepadObject(BATTLEGROUND_LEADERBOARD_SYSTEM_NAME, self)
    GAMEPAD_LEADERBOARDS:RegisterLeaderboardSystemObject(self)
end

function ZO_BattlegroundLeaderboardsManager_Gamepad:PerformDeferredInitialization()
    if self.isInitialized then return end

    self:RegisterForEvents()

    self.isInitialized = true
end

function ZO_BattlegroundLeaderboardsManager_Gamepad:RefreshHeaderPlayerInfo()
    local headerData = GAMEPAD_LEADERBOARD_LIST:GetContentHeaderData()
    
    headerData.data1HeaderText = GetString(SI_GAMEPAD_LEADERBOARDS_CURRENT_SCORE_LABEL)
    headerData.data1Text = self.currentScoreData or GetString(SI_LEADERBOARDS_NO_SCORE_RECORDED)

    local rankingTypeText = GetString("SI_LEADERBOARDTYPE", LEADERBOARD_LIST_MANAGER.leaderboardRankType)
    headerData.data2HeaderText = zo_strformat(SI_GAMEPAD_LEADERBOARDS_CURRENT_RANK_LABEL, rankingTypeText)
    headerData.data2Text = self.currentRankData or GetString(SI_LEADERBOARDS_NOT_RANKED)
end

function ZO_BattlegroundLeaderboardsManager_Gamepad:RefreshHeaderTimer()
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

    ZO_GamepadGenericHeader_RefreshData(GAMEPAD_LEADERBOARD_LIST.contentHeader, headerData)
end

function ZO_BattlegroundLeaderboardsInformationArea_Gamepad_OnInitialized(self)
    GAMEPAD_BATTLEGROUND_LEADERBOARDS = ZO_BattlegroundLeaderboardsManager_Gamepad:New(self)
end