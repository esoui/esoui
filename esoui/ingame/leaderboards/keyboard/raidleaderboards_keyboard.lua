local RAID_LEADERBOARD_FRAGMENT

local ZO_RaidLeaderboardsManager_Keyboard = ZO_RaidLeaderboardsManager_Shared:Subclass()

function ZO_RaidLeaderboardsManager_Keyboard:New(...)
    return ZO_RaidLeaderboardsManager_Shared.New(self, ...)
end

function ZO_RaidLeaderboardsManager_Keyboard:Initialize(control)
    RAID_LEADERBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)

    self.currentScoreLabel = GetControl(control, "CurrentScore")
    self.currentRankLabel = GetControl(control, "CurrentRank")
    self.scoringInfoLabel = GetControl(control, "ScoringInfo")
    self.timerLabel = GetControl(control, "Timer")
    self.activeScore = GetControl(control, "ActiveScore")

    self.scoringInfoHelpIcon = GetControl(control, "ScoringInfoHelp")
    self.scoringInfoHelpIcon:SetParent(self.scoringInfoLabel)
    
    ZO_RaidLeaderboardsManager_Shared.Initialize(self, control, LEADERBOARDS, LEADERBOARDS_SCENE, RAID_LEADERBOARD_FRAGMENT)

    self:RegisterForEvents(control)

    RAID_LEADERBOARD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
                                                 if newState == SCENE_FRAGMENT_SHOWING then
                                                     self:UpdateAllInfo()
                                                     QueryRaidLeaderboardData()
                                                 end
                                             end)

    SYSTEMS:RegisterKeyboardObject(RAID_LEADERBOARD_SYSTEM_NAME, self)
    LEADERBOARDS:UpdateCategories()
end

function ZO_RaidLeaderboardsManager_Keyboard:RefreshHeaderPlayerInfo(isWeekly)
    local displayedScore = self.currentScoreData or GetString(SI_LEADERBOARDS_NO_SCORE_RECORDED)
    self.currentScoreLabel:SetText(zo_strformat(SI_RAID_LEADERBOARDS_BEST_SCORE, displayedScore))

    local rankingTypeText = GetString("SI_LEADERBOARDTYPE", LEADERBOARD_LIST_MANAGER.leaderboardRankType)
    local displayedRank = self.currentRankData or GetString(SI_LEADERBOARDS_NOT_RANKED)
    self.currentRankLabel:SetText(zo_strformat(SI_LEADERBOARDS_CURRENT_RANK, rankingTypeText, displayedRank))

    self.timerLabel:SetHidden(not isWeekly)
end

function ZO_RaidLeaderboardsManager_Keyboard:RefreshHeaderTimer()
    if self.timerLabelData then
        self.timerLabel:SetText(zo_strformat(self.timerLabelIdentifier, self.timerLabelData))
    else
        self.timerLabel:SetText("")
    end
end

function ZO_RaidLeaderboardsManager_Keyboard:UpdateRaidScore()
    ZO_RaidLeaderboardsManager_Shared.UpdateRaidScore(self)

    local eligible = not self.participating or self.credited
    local currentScoreTextFormat = GetString(eligible and SI_RAID_LEADERBOARDS_CURRENT_SCORE or SI_RAID_LEADERBOARDS_CURRENT_SCORE_NOT_ELIGIBLE)
    self.scoringInfoLabel:SetText(zo_strformat(currentScoreTextFormat, self.currrentScoreData))
    self.scoringInfoHelpIcon:SetHidden(eligible)
end

function ZO_RaidLeaderboardsInformationArea_CurrentRankHelp_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, TOPLEFT, 5, 0)
    SetTooltipText(InformationTooltip, GetString(SI_RAID_LEADERBOARDS_RANK_HELP_TOOLTIP))
end

function ZO_RaidLeaderboardsInformationArea_CurrentRankHelp_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_RaidLeaderboardsInformationArea_ScoringInfoHelp_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, TOPRIGHT, -5, 0)
    SetTooltipText(InformationTooltip, GetString(SI_RAID_LEADERBOARDS_PARTICIPATING_NOT_ELIGIBLE_HELP_TOOLTIP))
end

function ZO_RaidLeaderboardsInformationArea_ScoringInfoHelp_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_RaidLeaderboardsInformationArea_OnInitialized(self)
    RAID_LEADERBOARDS = ZO_RaidLeaderboardsManager_Keyboard:New(self)
end