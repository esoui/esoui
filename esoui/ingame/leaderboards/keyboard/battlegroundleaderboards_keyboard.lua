ZO_BattlegroundLeaderboardsManager_Keyboard = ZO_BattlegroundLeaderboardsManager_Shared:Subclass()

function ZO_BattlegroundLeaderboardsManager_Keyboard:Initialize(control)
    BATTLEGROUND_LEADERBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)

    self.currentScoreLabel = control:GetNamedChild("CurrentScore")
    self.currentRankLabel = control:GetNamedChild("CurrentRank")
    self.timerLabel = control:GetNamedChild("Timer")
    
    ZO_BattlegroundLeaderboardsManager_Shared.Initialize(self, control, LEADERBOARDS, LEADERBOARDS_SCENE, BATTLEGROUND_LEADERBOARD_FRAGMENT)

    BATTLEGROUND_LEADERBOARD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:UpdatePlayerInfo()
        end
    end)

    SYSTEMS:RegisterKeyboardObject(ZO_BATTLEGROUND_LEADERBOARD_SYSTEM_NAME, self)
    LEADERBOARDS:RegisterLeaderboardSystemObject(self, LEADERBOARD_DATA_TYPE.BATTLEGROUND)
end

function ZO_BattlegroundLeaderboardsManager_Keyboard:RefreshHeaderPlayerInfo(isWeekly)
    local displayedScore = self.currentScoreData or GetString(SI_LEADERBOARDS_NO_CURRENT_SCORE)
    self.currentScoreLabel:SetText(zo_strformat(SI_LEADERBOARDS_CURRENT_SCORE, displayedScore))

    local rankingTypeText = GetString("SI_LEADERBOARDTYPE", LEADERBOARD_LIST_MANAGER.leaderboardRankType)
    local displayedRank = self.currentRankData or GetString(SI_LEADERBOARDS_NOT_RANKED)
    self.currentRankLabel:SetText(zo_strformat(SI_LEADERBOARDS_CURRENT_RANK, rankingTypeText, displayedRank))
end

function ZO_BattlegroundLeaderboardsManager_Keyboard:RefreshHeaderTimer()
    if self.timerLabelData then
        self.timerLabel:SetText(zo_strformat(self.timerLabelIdentifier, self.timerLabelData))
    else
        self.timerLabel:SetText("")
    end
end

function ZO_BattlegroundLeaderboardsInformationArea_OnInitialized(self)
    BATTLEGROUND_LEADERBOARDS = ZO_BattlegroundLeaderboardsManager_Keyboard:New(self)
end