--------------------------------------------
-- CampaignScoringManager Gamepad
--------------------------------------------

local ZO_CampaignScoringManager_Gamepad = ZO_CampaignScoringManager_Shared:Subclass()

function ZO_CampaignScoringManager_Gamepad:New(control)
    local manager = ZO_CampaignScoringManager_Shared.New(self, control)

    manager.control = control
    CAMPAIGN_SCORING_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CampaignScoring_Gamepad)
    CAMPAIGN_SCORING_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWN then
            manager.shown = true
            -- TODO Jerall: TO maintain current behavior, ask for assigned and it will get both assigned and local.
            -- We should eventually refactor this to gracefully work based on just getting the leaderboard for what you're looking at right now.
            QueryCampaignLeaderboardData(GetAssignedCampaignId(), ALLIANCE_NONE)
            manager:UpdateRewardTier()
            manager:UpdateScores()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            manager.shown = false
        end
    end)

    return manager
end


-- ZO_CampaignScoringManager_Shared Overrides
local ALLIANCE_SCORING_INFO =
{
    [ALLIANCE_ALDMERI_DOMINION] = 
    {
        allianceName = zo_strformat(SI_ALLIANCE_NAME, GetAllianceName(ALLIANCE_ALDMERI_DOMINION)),
        allianceIcon = "EsoUI/Art/Campaign/Gamepad/gp_overview_allianceIcon_aldmeri.dds",
    },
    [ALLIANCE_DAGGERFALL_COVENANT] = 
    {
        allianceName = zo_strformat(SI_ALLIANCE_NAME, GetAllianceName(ALLIANCE_DAGGERFALL_COVENANT)),
        allianceIcon = "EsoUI/Art/Campaign/Gamepad/gp_overview_allianceIcon_daggerfall.dds",
    },
    [ALLIANCE_EBONHEART_PACT] = 
    {
        allianceName = zo_strformat(SI_ALLIANCE_NAME, GetAllianceName(ALLIANCE_EBONHEART_PACT)),
        allianceIcon = "EsoUI/Art/Campaign/Gamepad/gp_overview_allianceIcon_ebonheart.dds",
    },
}

function ZO_CampaignScoringManager_Gamepad:UpdateScoreSection(index, scoreInfo)
    local scoreSection = self.scoreSections[index]
    local alliance = scoreInfo.alliance
    local allianceInfo = ALLIANCE_SCORING_INFO[alliance]

    scoreSection.allianceIcon:SetTexture(allianceInfo.allianceIcon)
    scoreSection.allianceName:SetText(allianceInfo.allianceName)

    local r, g, b, a = GetAllianceColor(alliance):UnpackRGBA()

    scoreSection.score:SetText(scoreInfo.score)
    scoreSection.potentialPoints:SetText(zo_strformat(SI_CAMPAIGN_SCORING_POTENTIAL_POINTS, scoreInfo.potentialScore))

    self:UpdateBonusIconVisibilities(scoreSection.potentialPoints, scoreSection.underdogScoreIcon, scoreInfo.isUnderdog, scoreSection.underdogPopIcon, scoreInfo.isUnderpop)

    for holdingType = HOLDINGTYPE_ITERATION_BEGIN, HOLDINGTYPE_ITERATION_END do
        local container = scoreSection.holdingTypeToContainerMap[holdingType]
        if container then
            local holdings = scoreInfo.holdings[holdingType]
            if holdings.possibleHoldings > 0 then
                container:SetHidden(false)
                container.icon:SetColor(r, g, b, a)
                container.value:SetText(zo_strformat(SI_CAMPAIGN_SCORING_HOLDING, scoreInfo.holdings[holdingType].numHoldings))
            else
                container:SetHidden(true)
            end
        end
    end
end


-- XML Calls
function ZO_CampaignScoring_Gamepad_OnInitialized(self)
    CAMPAIGN_SCORING_GAMEPAD = ZO_CampaignScoringManager_Gamepad:New(self)
end