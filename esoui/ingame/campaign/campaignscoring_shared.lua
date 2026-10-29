ZO_CampaignScoringManager_Shared = ZO_Object:Subclass()

function ZO_CampaignScoringManager_Shared:New(control)
    local manager = ZO_Object.New(self)

    manager.scoreSections = 
    {
        [1] = GetControl(control, "TopSection"),
        [2] = GetControl(control, "MiddleSection"),
        [3] = GetControl(control, "BottomSection"),
    }

    manager.tierProgressRank = GetControl(control, "TierProgressRank")
    manager.tierProgressBar = GetControl(control, "TierProgressStatusBar")
    ZO_StatusBar_SetGradientColor(manager.tierProgressBar, ZO_AVA_RANK_GRADIENT_COLORS)

    manager.campaignId = 0
    manager.shown = false
    manager:UpdateScores()

    control:RegisterForEvent(EVENT_CAMPAIGN_SCORE_DATA_CHANGED, function() if manager.shown then manager:UpdateScores() end end)
    control:RegisterForEvent(EVENT_CAMPAIGN_LEADERBOARD_DATA_RECEIVED, function() if manager.shown then manager:UpdateRewardTier() end end)
    control:RegisterForEvent(EVENT_KEEP_ALLIANCE_OWNER_CHANGED, function() if manager.shown then manager:UpdateScores() end end)
    control:RegisterForEvent(EVENT_OBJECTIVES_UPDATED, function() if manager.shown then manager:UpdateScores() end end)

    return manager
end

function ZO_CampaignScoringManager_Shared:SetCampaignAndQueryType(campaignId, queryType)
    self.campaignId = campaignId
    self:UpdateRewardTier()
    self:UpdateScores()
end

local function ScoreInfoComparator(scoreInfo1, scoreInfo2)
    return (scoreInfo1.score > scoreInfo2.score)
end

function ZO_CampaignScoringManager_Shared:UpdateScores()
    local scoreInfos = {}

    local underdogLeaderAlliance = GetCampaignUnderdogLeaderAlliance(self.campaignId)

    for i = 1, NUM_ALLIANCES do
        local holdings = {}
        local score = GetCampaignAllianceScore(self.campaignId, i)

        for holdingType = HOLDINGTYPE_ITERATION_BEGIN, HOLDINGTYPE_ITERATION_END do
            local numHoldings, possibleHoldings = GetTotalCampaignHoldings(self.campaignId, holdingType, i)
            if holdingType == HOLDINGTYPE_OFFENSIVE_ARTIFACT then
                local defensiveArtifactHoldings = holdings[HOLDINGTYPE_DEFENSIVE_ARTIFACT]
                defensiveArtifactHoldings.numHoldings = defensiveArtifactHoldings.numHoldings + numHoldings
                defensiveArtifactHoldings.possibleHoldings = defensiveArtifactHoldings.possibleHoldings + possibleHoldings
            else
                holdings[holdingType] =
                {
                    numHoldings = numHoldings,
                    possibleHoldings = possibleHoldings,
                }
            end
        end

        local potentialScore = GetCampaignAlliancePotentialScore(self.campaignId, i)
        local isUnderpop = IsUnderpopBonusEnabled(self.campaignId, i)
        scoreInfos[i] =
        {
            alliance = i,
            score = score,
            holdings = holdings,
            potentialScore = potentialScore,
            isUnderdog = underdogLeaderAlliance ~= 0 and underdogLeaderAlliance ~= i,
            isUnderpop = isUnderpop,
        }
    end

   table.sort(scoreInfos, ScoreInfoComparator)

    for i = 1, #scoreInfos do
        self:UpdateScoreSection(i, scoreInfos[i])
    end
end

function ZO_CampaignScoringManager_Shared:UpdateRewardTier()
    local currentTier, nextTierProgress, nextTierTotal = GetPlayerCampaignRewardTierInfo(self.campaignId)
    self.tierProgressRank:SetText(currentTier)
    self.tierProgressBar:SetMinMax(0, nextTierTotal)
    self.tierProgressBar:SetValue(nextTierProgress)
end

internalassert(HOLDINGTYPE_MAX_VALUE == 5, "Handle new holding type in the Scoring files.")

local ALLIANCE_SCORING_INFO =
{
    [ALLIANCE_ALDMERI_DOMINION] = 
    {
        allianceName = zo_strformat(SI_ALLIANCE_NAME, GetAllianceName(ALLIANCE_ALDMERI_DOMINION)),
        bgLeft = "EsoUI/Art/Campaign/overview_scoringBG_aldmeri_left.dds",
        bgRight = "EsoUI/Art/Campaign/overview_scoringBG_aldmeri_right.dds",
        allianceIcon = "EsoUI/Art/Campaign/overview_allianceIcon_aldmeri.dds",
        holdingIcons =
        {
            [HOLDINGTYPE_KEEP] = "EsoUI/Art/Campaign/overview_keepIcon_aldmeri.dds",
            [HOLDINGTYPE_IMPERIAL_CITY_DISTRICT] = "EsoUI/Art/Campaign/overview_imperialDistrictIcon_aldmeri.dds",
            [HOLDINGTYPE_OUTPOST] = "EsoUI/Art/Campaign/overview_outpostIcon_aldmeri.dds",
            [HOLDINGTYPE_RESOURCE] = "EsoUI/Art/Campaign/overview_resourcesIcon_aldmeri.dds",
            [HOLDINGTYPE_DEFENSIVE_ARTIFACT] = "EsoUI/Art/Campaign/overview_scrollIcon_aldmeri.dds",
        },
    },
    [ALLIANCE_DAGGERFALL_COVENANT] = 
    {
        allianceName = zo_strformat(SI_ALLIANCE_NAME, GetAllianceName(ALLIANCE_DAGGERFALL_COVENANT)),
        bgLeft = "EsoUI/Art/Campaign/overview_scoringBG_daggerfall_left.dds",
        bgRight = "EsoUI/Art/Campaign/overview_scoringBG_daggerfall_right.dds",
        allianceIcon = "EsoUI/Art/Campaign/overview_allianceIcon_daggerfall.dds",
        holdingIcons =
        {
            [HOLDINGTYPE_KEEP] = "EsoUI/Art/Campaign/overview_keepIcon_daggerfall.dds",
            [HOLDINGTYPE_IMPERIAL_CITY_DISTRICT] = "EsoUI/Art/Campaign/overview_imperialDistrictIcon_daggerfall.dds",
            [HOLDINGTYPE_OUTPOST] = "EsoUI/Art/Campaign/overview_outpostIcon_daggerfall.dds",
            [HOLDINGTYPE_RESOURCE] = "EsoUI/Art/Campaign/overview_resourcesIcon_daggerfall.dds",
            [HOLDINGTYPE_DEFENSIVE_ARTIFACT] = "EsoUI/Art/Campaign/overview_scrollIcon_daggerfall.dds",
        },
    },
    [ALLIANCE_EBONHEART_PACT] = 
    {
        allianceName = zo_strformat(SI_ALLIANCE_NAME, GetAllianceName(ALLIANCE_EBONHEART_PACT)),
        bgLeft = "EsoUI/Art/Campaign/overview_scoringBG_ebonheart_left.dds",
        bgRight = "EsoUI/Art/Campaign/overview_scoringBG_ebonheart_right.dds",
        allianceIcon = "EsoUI/Art/Campaign/overview_allianceIcon_ebonheart.dds",
        holdingIcons =
        {
            [HOLDINGTYPE_KEEP] = "EsoUI/Art/Campaign/overview_keepIcon_ebonheart.dds",
            [HOLDINGTYPE_IMPERIAL_CITY_DISTRICT] = "EsoUI/Art/Campaign/overview_imperialDistrictIcon_ebonheart.dds",
            [HOLDINGTYPE_OUTPOST] = "EsoUI/Art/Campaign/overview_outpostIcon_ebonheart.dds",
            [HOLDINGTYPE_RESOURCE] = "EsoUI/Art/Campaign/overview_resourcesIcon_ebonheart.dds",
            [HOLDINGTYPE_DEFENSIVE_ARTIFACT] = "EsoUI/Art/Campaign/overview_scrollIcon_ebonheart.dds",
        },
    },
}

function ZO_CampaignScoringManager_Shared:UpdateBonusIconVisibilities(initialControlAnchor, lowScoreIcon, isLowScoring, lowPopIcon, isLowPop)
    lowScoreIcon:SetHidden(not isLowScoring)
    lowPopIcon:SetHidden(not isLowPop)

    if isLowScoring and isLowPop then
        lowScoreIcon:SetAnchor(LEFT, initialControlAnchor, RIGHT)
        lowPopIcon:SetAnchor(LEFT, lowScoreIcon, RIGHT, -5)
    elseif isLowScoring then
        lowScoreIcon:SetAnchor(LEFT, initialControlAnchor, RIGHT)
    elseif isLowPop then
        lowPopIcon:SetAnchor(LEFT, initialControlAnchor, RIGHT)
    end
end

function ZO_CampaignScoringManager_Shared:UpdateScoreSection(index, scoreInfo)
    local scoreSection = self.scoreSections[index]
    local allianceInfo = ALLIANCE_SCORING_INFO[scoreInfo.alliance]

    scoreSection.bgLeft:SetTexture(allianceInfo.bgLeft)
    scoreSection.bgRight:SetTexture(allianceInfo.bgRight)
    scoreSection.allianceIcon:SetTexture(allianceInfo.allianceIcon)

    scoreSection.allianceName:SetText(allianceInfo.allianceName)
    scoreSection.score:SetText(scoreInfo.score)
    scoreSection.potentialPoints:SetText(zo_strformat(SI_CAMPAIGN_SCORING_POTENTIAL_POINTS, scoreInfo.potentialScore))

    self:UpdateBonusIconVisibilities(scoreSection.potentialPoints, scoreSection.underdogScoreIcon, scoreInfo.isUnderdog, scoreSection.underdogPopIcon, scoreInfo.isUnderpop)
    
    for holdingType = HOLDINGTYPE_ITERATION_BEGIN, HOLDINGTYPE_ITERATION_END do
        local container = scoreSection.holdingTypeToContainerMap[holdingType]
        if container then
            local holdings = scoreInfo.holdings[holdingType]
            if holdings.possibleHoldings > 0 then
                container:SetHidden(false)
                container.icon:SetTexture(allianceInfo.holdingIcons[holdingType])
                container.value:SetText(zo_strformat(SI_CAMPAIGN_SCORING_HOLDING, scoreInfo.holdings[holdingType].numHoldings))
            else
                container:SetHidden(true)
            end
        end
    end
end

function ZO_CampaignScoringManager_Shared:OnTimeControlUpdate(control, timeFunction)
    local timeLeft = timeFunction(self.campaignId)
    control:SetText(ZO_FormatTime(timeLeft, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR))
end

--Global XML

function ZO_CampaignScoring_AllianceSection_OnInitialized(control)
    control.bgLeft = control:GetNamedChild("BGLeft")
    control.bgRight = control:GetNamedChild("BGRight")
    control.allianceIcon = control:GetNamedChild("AllianceIcon")
    control.allianceName = control:GetNamedChild("AllianceName")

    local holdingTypeToContainerMap = {}

    control.keepsContainer = control:GetNamedChild("KeepsContainer")
    control.keepsContainer.icon.tooltipText = GetString(SI_CAMPAIGN_SCORING_KEEPS_TOOLTIP)
    holdingTypeToContainerMap[HOLDINGTYPE_KEEP] = control.keepsContainer

    control.imperialDistrictsContainer = control:GetNamedChild("ImperialDistrictsContainer")
    control.imperialDistrictsContainer.icon.tooltipText = GetString(SI_CAMPAIGN_SCORING_IMPERIAL_DISTRICTS_TOOLTIP)
    holdingTypeToContainerMap[HOLDINGTYPE_IMPERIAL_CITY_DISTRICT] = control.imperialDistrictsContainer

    control.outpostsContainer = control:GetNamedChild("OutpostsContainer")
    control.outpostsContainer.icon.tooltipText = GetString(SI_CAMPAIGN_SCORING_OUTPOSTS_TOOLTIP)
    holdingTypeToContainerMap[HOLDINGTYPE_OUTPOST] = control.outpostsContainer

    control.resourcesContainer = control:GetNamedChild("ResourcesContainer")
    control.resourcesContainer.icon.tooltipText = GetString(SI_CAMPAIGN_SCORING_RESOURCES_TOOLTIP)
    holdingTypeToContainerMap[HOLDINGTYPE_RESOURCE] = control.resourcesContainer

    control.scrollsContainer = control:GetNamedChild("ScrollsContainer")
    control.scrollsContainer.icon.tooltipText = GetString(SI_CAMPAIGN_SCORING_SCROLLS_TOOLTIP)
    holdingTypeToContainerMap[HOLDINGTYPE_DEFENSIVE_ARTIFACT] = control.scrollsContainer

    control.holdingTypeToContainerMap = holdingTypeToContainerMap

    control.score = control:GetNamedChild("AllianceScore")
    control.potentialPoints = control:GetNamedChild("PotentialPoints")
    control.underdogScoreIcon = control:GetNamedChild("UnderdogScoreIcon")
    control.underdogPopIcon = control:GetNamedChild("UnderdogPopIcon")

end















