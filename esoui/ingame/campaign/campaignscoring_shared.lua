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
    control:RegisterForEvent(EVENT_CAMPAIGN_LEADERBOARD_DATA_CHANGED, function() if manager.shown then manager:UpdateRewardTier() end end)
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

    local keepScore, resourceValue, outpostValue, defensiveScrollValue, offensiveScrollValue = GetCampaignHoldingScoreValues(self.campaignId)
    local underdogLeaderAlliance = GetCampaignUnderdogLeaderAlliance(self.campaignId)

    for i = 1, NUM_ALLIANCES do
        local score = GetCampaignAllianceScore(self.campaignId, i)
        local numKeeps = GetTotalCampaignHoldings(self.campaignId, HOLDINGTYPE_KEEP, i)
        local numResources = GetTotalCampaignHoldings(self.campaignId, HOLDINGTYPE_RESOURCE, i)
        local numOutposts = GetTotalCampaignHoldings(self.campaignId, HOLDINGTYPE_OUTPOST, i)
        local numDefensiveScrolls = GetTotalCampaignHoldings(self.campaignId, HOLDINGTYPE_DEFENSIVE_ARTIFACT, i)
        local numOffensiveScrolls = GetTotalCampaignHoldings(self.campaignId, HOLDINGTYPE_OFFENSIVE_ARTIFACT, i)
        local potentialScore = GetCampaignAlliancePotentialScore(self.campaignId, i)
        local isUnderpop = IsUnderpopBonusEnabled(self.campaignId, i)
        scoreInfos[i] =
        {
            alliance = i,
            score = score,
            numKeeps = numKeeps,
            numResources = numResources,
            numOutposts = numOutposts,
            numScrolls = numDefensiveScrolls + numOffensiveScrolls,
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

local ALLIANCE_SCORING_INFO =
{
    [ALLIANCE_ALDMERI_DOMINION] = 
    {
        allianceName = zo_strformat(SI_ALLIANCE_NAME, GetAllianceName(ALLIANCE_ALDMERI_DOMINION)),
        bgLeft = "EsoUI/Art/Campaign/overview_scoringBG_aldmeri_left.dds",
        bgRight = "EsoUI/Art/Campaign/overview_scoringBG_aldmeri_right.dds",
        allianceIcon = "EsoUI/Art/Campaign/overview_allianceIcon_aldmeri.dds",
        keepIcon = "EsoUI/Art/Campaign/overview_keepIcon_aldmeri.dds",
        outpostIcon = "EsoUI/Art/Campaign/overview_outpostIcon_aldmeri.dds",
        resourcesIcon = "EsoUI/Art/Campaign/overview_resourcesIcon_aldmeri.dds",
        scrollIcon = "EsoUI/Art/Campaign/overview_scrollIcon_aldmeri.dds",
    },
    [ALLIANCE_DAGGERFALL_COVENANT] = 
    {
        allianceName = zo_strformat(SI_ALLIANCE_NAME, GetAllianceName(ALLIANCE_DAGGERFALL_COVENANT)),
        bgLeft = "EsoUI/Art/Campaign/overview_scoringBG_daggerfall_left.dds",
        bgRight = "EsoUI/Art/Campaign/overview_scoringBG_daggerfall_right.dds",
        allianceIcon = "EsoUI/Art/Campaign/overview_allianceIcon_daggefall.dds",
        keepIcon = "EsoUI/Art/Campaign/overview_keepIcon_daggefall.dds",
        outpostIcon = "EsoUI/Art/Campaign/overview_outpostIcon_daggefall.dds",
        resourcesIcon = "EsoUI/Art/Campaign/overview_resourcesIcon_daggefall.dds",
        scrollIcon = "EsoUI/Art/Campaign/overview_scrollIcon_daggefall.dds",
    },
    [ALLIANCE_EBONHEART_PACT] = 
    {
        allianceName = zo_strformat(SI_ALLIANCE_NAME, GetAllianceName(ALLIANCE_EBONHEART_PACT)),
        bgLeft = "EsoUI/Art/Campaign/overview_scoringBG_ebonheart_left.dds",
        bgRight = "EsoUI/Art/Campaign/overview_scoringBG_ebonheart_right.dds",
        allianceIcon = "EsoUI/Art/Campaign/overview_allianceIcon_ebonheart.dds",
        keepIcon = "EsoUI/Art/Campaign/overview_keepIcon_ebonheart.dds",
        outpostIcon = "EsoUI/Art/Campaign/overview_outpostIcon_ebonheart.dds",
        resourcesIcon = "EsoUI/Art/Campaign/overview_resourcesIcon_ebonheart.dds",
        scrollIcon = "EsoUI/Art/Campaign/overview_scrollIcon_ebonheart.dds",
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
    scoreSection.keepIcon:SetTexture(allianceInfo.keepIcon)
    scoreSection.outpostIcon:SetTexture(allianceInfo.outpostIcon)
    scoreSection.resourcesIcon:SetTexture(allianceInfo.resourcesIcon)
    scoreSection.scrollIcon:SetTexture(allianceInfo.scrollIcon)

    scoreSection.allianceName:SetText(allianceInfo.allianceName)
    scoreSection.score:SetText(scoreInfo.score)
    scoreSection.potentialPoints:SetText(zo_strformat(SI_CAMPAIGN_SCORING_POTENTIAL_POINTS, scoreInfo.potentialScore))

    self:UpdateBonusIconVisibilities(scoreSection.potentialPoints, scoreSection.underdogScoreIcon, scoreInfo.isUnderdog, scoreSection.underdogPopIcon, scoreInfo.isUnderpop)

    scoreSection.numKeeps:SetText(zo_strformat(SI_CAMPAIGN_SCORING_HOLDING, scoreInfo.numKeeps))
    scoreSection.numOutposts:SetText(zo_strformat(SI_CAMPAIGN_SCORING_HOLDING, scoreInfo.numOutposts))
    scoreSection.numResources:SetText(zo_strformat(SI_CAMPAIGN_SCORING_HOLDING, scoreInfo.numResources))
    scoreSection.numScrolls:SetText(zo_strformat(SI_CAMPAIGN_SCORING_HOLDING, scoreInfo.numScrolls))
end

function ZO_CampaignScoringManager_Shared:OnTimeControlUpdate(control, timeFunction)
    local timeLeft = timeFunction(self.campaignId)
    control:SetText(ZO_FormatTime(timeLeft, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR))
end

--Global XML

function ZO_CampaignScoring_AllianceSection_OnInitialized(control)
    control.bgLeft = GetControl(control, "BGLeft")
    control.bgRight = GetControl(control, "BGRight")
    control.allianceIcon = GetControl(control, "AllianceIcon")
    control.allianceName = GetControl(control, "AllianceName")
    control.keepIcon = GetControl(control, "KeepIcon")
    control.keepIcon.tooltipText = GetString(SI_CAMPAIGN_SCORING_KEEPS_TOOLTIP)
    control.outpostIcon = GetControl(control, "OutpostIcon")
    control.outpostIcon.tooltipText = GetString(SI_CAMPAIGN_SCORING_OUTPOSTS_TOOLTIP)
    control.resourcesIcon = GetControl(control, "ResourcesIcon")
    control.resourcesIcon.tooltipText = GetString(SI_CAMPAIGN_SCORING_RESOURCES_TOOLTIP)
    control.scrollIcon = GetControl(control, "ScrollIcon")
    control.scrollIcon.tooltipText = GetString(SI_CAMPAIGN_SCORING_SCROLLS_TOOLTIP)

    control.score = GetControl(control, "AllianceScore")
    control.potentialPoints = GetControl(control, "PotentialPoints")
    control.underdogScoreIcon = GetControl(control, "UnderdogScoreIcon")
    control.underdogPopIcon = GetControl(control, "UnderdogPopIcon")
    control.numKeeps = GetControl(control, "NumKeeps")
    control.numOutposts = GetControl(control, "NumOutposts")
    control.numResources = GetControl(control, "NumResources")
    control.numScrolls = GetControl(control, "NumScrolls")
end















