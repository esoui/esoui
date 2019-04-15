local ZO_CampaignScoringManager = ZO_CampaignScoringManager_Shared:Subclass()

function ZO_CampaignScoringManager:New(control)
    local manager = ZO_CampaignScoringManager_Shared.New(self, control)

    CAMPAIGN_SCORING_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CampaignScoring)
    CAMPAIGN_SCORING_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
                                                                    if newState == SCENE_FRAGMENT_SHOWN then
                                                                        manager.shown = true
                                                                        QueryCampaignLeaderboardData()
                                                                        manager:UpdateRewardTier()
                                                                        manager:UpdateScores()
                                                                    elseif newState == SCENE_FRAGMENT_HIDDEN then
                                                                        manager.shown = false
                                                                    end
                                                                end)

    return manager
end

--Global XML

function ZO_CampaignScoring_IconOnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
    SetTooltipText(InformationTooltip, control.tooltipText)
end

function ZO_CampaignScoring_IconOnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_CampaignScoring_OnInitialized(self)
    CAMPAIGN_SCORING = ZO_CampaignScoringManager:New(self)
end

function ZO_CampaignScoring_TimeUpdate(control, timeFunction)
    CAMPAIGN_SCORING:OnTimeControlUpdate(control, timeFunction)
end