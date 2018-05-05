local HOUSING_LEADERBOARD_FRAGMENT

local ZO_HousingLeaderboardsManager_Keyboard = ZO_HousingLeaderboardsManager_Shared:Subclass()

function ZO_HousingLeaderboardsManager_Keyboard:New(...)
    return ZO_HousingLeaderboardsManager_Shared.New(self, ...)
end

function ZO_HousingLeaderboardsManager_Keyboard:Initialize(control)
    HOUSING_LEADERBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)

    self.currentScoreLabel = GetControl(control, "CurrentScore")
    self.currentRankLabel = GetControl(control, "CurrentRank")
    self.timerLabel = GetControl(control, "Timer")
    
    ZO_HousingLeaderboardsManager_Shared.Initialize(self, control, LEADERBOARDS, LEADERBOARDS_SCENE, HOUSING_LEADERBOARD_FRAGMENT)
    
    HOUSING_LEADERBOARD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
                                                 if newState == SCENE_FRAGMENT_SHOWING then
                                                     self:UpdateAllInfo()
                                                     QueryHomeShowLeaderboardData()
                                                 end
                                             end)

    SYSTEMS:RegisterKeyboardObject(HOUSING_LEADERBOARD_SYSTEM_NAME, self)
    LEADERBOARDS:UpdateCategories()
end

function ZO_HousingLeaderboardsManager_Keyboard:RefreshHeaderPlayerInfo()
    local displayedScore = self.currentScoreData or GetString(SI_LEADERBOARDS_NO_SCORE_RECORDED)
    self.currentScoreLabel:SetText(zo_strformat(SI_LEADERBOARDS_BEST_SCORE, displayedScore))

    local rankingTypeText = GetString("SI_LEADERBOARDTYPE", LEADERBOARD_LIST_MANAGER.leaderboardRankType)
    local displayedRank = self.currentRankData or GetString(SI_LEADERBOARDS_NOT_RANKED)
    self.currentRankLabel:SetText(zo_strformat(SI_LEADERBOARDS_CURRENT_RANK, rankingTypeText, displayedRank))
end

function ZO_HousingLeaderboardsManager_Keyboard:RefreshHeaderTimer()
    if self.timerLabelData then
        self.timerLabel:SetText(zo_strformat(self.timerLabelIdentifier, self.timerLabelData))
    else
        self.timerLabel:SetText("")
    end
end

function ZO_HousingLeaderboardsInformationArea_OnInitialized(self)
    HOUSING_LEADERBOARDS = ZO_HousingLeaderboardsManager_Keyboard:New(self)
end