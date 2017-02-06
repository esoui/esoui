local ZO_HousingLeaderboardsManager_Gamepad = ZO_HousingLeaderboardsManager_Shared:Subclass()

function ZO_HousingLeaderboardsManager_Gamepad:New(...)
    return ZO_HousingLeaderboardsManager_Shared.New(self, ...)
end

function ZO_HousingLeaderboardsManager_Gamepad:Initialize(control)
    GAMEPAD_HOUSING_LEADERBOARD_FRAGMENT = ZO_SimpleSceneFragment:New(control)

    ZO_HousingLeaderboardsManager_Shared.Initialize(self, control, GAMEPAD_LEADERBOARDS, GAMEPAD_LEADERBOARDS_SCENE, GAMEPAD_HOUSING_LEADERBOARD_FRAGMENT)

    GAMEPAD_HOUSING_LEADERBOARD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
                                                 if newState == SCENE_FRAGMENT_SHOWING then
                                                    self:UpdateAllInfo()
                                                    local NO_NAME, NO_ICON
                                                    GAMEPAD_LEADERBOARDS:SetActiveCampaign(NO_NAME, NO_ICON)
                                                 end
                                             end)

    SYSTEMS:RegisterGamepadObject(HOUSING_LEADERBOARD_SYSTEM_NAME, self)
    GAMEPAD_LEADERBOARDS:UpdateCategories()
end

function ZO_HousingLeaderboardsManager_Gamepad:RefreshHeaderPlayerInfo()
    local headerData = GAMEPAD_LEADERBOARD_LIST:GetContentHeaderData()
    
    headerData.data1HeaderText = GetString(SI_GAMEPAD_HOUSING_LEADERBOARDS_BEST_SCORE_LABEL)
    headerData.data1Text = self.currentScoreData or GetString(SI_LEADERBOARDS_NO_SCORE_RECORDED)

    local rankingTypeText = GetString("SI_LEADERBOARDTYPE", LEADERBOARD_LIST_MANAGER.leaderboardRankType)
    headerData.data2HeaderText = zo_strformat(SI_GAMEPAD_LEADERBOARDS_CURRENT_RANK_LABEL, rankingTypeText)
    headerData.data2Text = self.currentRankData or GetString(SI_LEADERBOARDS_NOT_RANKED)
end

function ZO_HousingLeaderboardsManager_Gamepad:RefreshHeaderTimer()
    local headerData = GAMEPAD_LEADERBOARD_LIST:GetContentHeaderData()

    if self.timerLabelData then
        headerData.data4HeaderText = GetString(SI_GAMEPAD_LEADERBOARDS_UPDATES_IN_TIMER_LABEL)
        headerData.data4Text = zo_strformat(SI_GAMEPAD_LEADERBOARDS_TIMER, self.timerLabelData)
    else
        headerData.data4HeaderText = ""
        headerData.data4Text = ""
    end

    ZO_GamepadGenericHeader_RefreshData(GAMEPAD_LEADERBOARD_LIST.contentHeader, headerData)
end

function ZO_HousingLeaderboardsInformationArea_Gamepad_OnInitialized(self)
    GAMEPAD_HOUSING_LEADERBOARDS = ZO_HousingLeaderboardsManager_Gamepad:New(self)
end