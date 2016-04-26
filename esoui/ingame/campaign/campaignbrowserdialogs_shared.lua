function ZO_SelectHomeCampaign_GetCost()
    local endCampaignNowCost = 0
    local endCampaignAfterEndCost = 0

    if(GetNumFreeAnytimeCampaignReassigns() == 0) then
        endCampaignNowCost = GetCampaignReassignCost(CAMPAIGN_REASSIGN_TYPE_IMMEDIATE)
    end
    if(GetNumFreeEndCampaignReassigns() == 0) then
        endCampaignAfterEndCost = GetCampaignReassignCost(CAMPAIGN_REASSIGN_TYPE_ON_END)
    end

    return endCampaignNowCost, endCampaignAfterEndCost
end

function ZO_AbandonHomeCampaign_GetCost()
    local alliancePointCost = 0
    local goldCost = 0

    if(GetNumFreeAnytimeCampaignUnassigns() == 0) then
        alliancePointCost = GetCampaignUnassignCost(CAMPAIGN_UNASSIGN_TYPE_HOME_USE_ALLIANCE_POINTS)
        goldCost = GetCampaignUnassignCost(CAMPAIGN_UNASSIGN_TYPE_HOME_USE_GOLD)
    end

    return alliancePointCost, goldCost
end