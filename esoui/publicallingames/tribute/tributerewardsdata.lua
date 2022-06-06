-------------------------------------------
-- Tribute Rewards Data Classes and Data --
-------------------------------------------

ZO_TRIBUTE_REWARD_TYPES =
{
    SEASON_REWARDS = 1,
    LEADERBOARD_REWARDS = 2,
}

ZO_TRIBUTE_REWARD_TYPE_LIST =
{
    ZO_TRIBUTE_REWARD_TYPES.SEASON_REWARDS,
    ZO_TRIBUTE_REWARD_TYPES.LEADERBOARD_REWARDS,
}

ZO_TRIBUTE_TYPE_DATA =
{
    [ZO_TRIBUTE_REWARD_TYPES.SEASON_REWARDS] =
    {
        tierHeader = GetString(SI_TRIBUTE_FINDER_REWARDS_SEASON_TIER_HEADER),
        description = GetString(SI_TRIBUTE_FINDER_REWARDS_SEASON_INFO_TOOLTIP),
        gamepadIcon = "EsoUI/Art/Tribute/tributeTypeIcon_Season.dds",
        isSeasonType = true,
    },
    [ZO_TRIBUTE_REWARD_TYPES.LEADERBOARD_REWARDS] =
    {
        tierHeader = GetString(SI_TRIBUTE_FINDER_REWARDS_LEADERBOARD_RANK_HEADER),
        description = GetString(SI_TRIBUTE_FINDER_REWARDS_LEADERBOARD_INFO_TOOLTIP),
        gamepadIcon = "EsoUI/Art/Tribute/tributeTypeIcon_Leaderboards.dds",
    }
}

-------------------------------
-- Tribute Rewards Type Data --
-------------------------------

ZO_TributeRewardsTypeData = ZO_InitializingObject:Subclass()

function ZO_TributeRewardsTypeData:Initialize(rewardsTypeId)
    self.rewardsTypeId = rewardsTypeId
end

function ZO_TributeRewardsTypeData:GetRewardsTypeId()
    return self.rewardsTypeId
end

function ZO_TributeRewardsTypeData:GetTierHeader()
    return ZO_TRIBUTE_TYPE_DATA[self.rewardsTypeId].tierHeader
end

function ZO_TributeRewardsTypeData:GetDescription()
    return ZO_TRIBUTE_TYPE_DATA[self.rewardsTypeId].description
end

function ZO_TributeRewardsTypeData:GetGamepadIcon()
    return ZO_TRIBUTE_TYPE_DATA[self.rewardsTypeId].iconTexture
end

--------------------------
-- Tribute Rewards Data --
--------------------------

ZO_TributeRewardsData = ZO_InitializingObject:Subclass()

function ZO_TributeRewardsData:Initialize(rewardsType, rewardsTierId)
    if rewardsType and rewardsTierId then
        self:Setup(rewardsType, rewardsTierId)
    end
end

function ZO_TributeRewardsData:Setup(rewardsType, rewardsTierId)
    self.rewardsType = rewardsType
    self.rewardsTierId = rewardsTierId
end

function ZO_TributeRewardsData:GetRewardsType()
    return self.rewardsType
end

function ZO_TributeRewardsData:GetRewardsTierId()
    return self.rewardsTierId
end

function ZO_TributeRewardsData:GetRewardsTierColor()
    local rewardsTypeId = self.rewardsType:GetRewardsTypeId()
    if rewardsTypeId == ZO_TRIBUTE_REWARD_TYPES.SEASON_REWARDS then
        return GetInterfaceColor(INTERFACE_COLOR_TYPE_TRIBUTE_TIER, self:GetRewardsTierId())
    else
        -- All leaderboard tiers are the color of the top ranked tier
        return GetInterfaceColor(INTERFACE_COLOR_TYPE_TRIBUTE_TIER, TRIBUTE_TIER_PLATINUM)
    end
end

function ZO_TributeRewardsData:GetTierName()
    local rewardsTypeId = self.rewardsType:GetRewardsTypeId()
    if rewardsTypeId == ZO_TRIBUTE_REWARD_TYPES.SEASON_REWARDS then
        return GetString("SI_TRIBUTETIER", self.rewardsTierId)
    else
        return GetString("SI_TRIBUTELEADERBOARDTIER", self.rewardsTierId)
    end
end

function ZO_TributeRewardsData:GetRewardListName()
    local rewardListId = self:GetRewardListId()
    return GetRewardListDisplayName(rewardListId)
end

function ZO_TributeRewardsData:GetRewardListDescription()
    local rewardListId = self:GetRewardListId()
    return GetRewardListDescription(rewardListId)
end

function ZO_TributeRewardsData:GetRewardListId()
    local rewardsTypeId = self.rewardsType:GetRewardsTypeId()
    if rewardsTypeId == ZO_TRIBUTE_REWARD_TYPES.SEASON_REWARDS then
        return GetActiveTributeCampaignTierRewardListId(self.rewardsTierId)
    else
        return GetActiveTributeCampaignLeaderboardTierRewardListId(self.rewardsTierId)
    end
end

function ZO_TributeRewardsData:GetTierIcon()
    local rewardsTypeId = self.rewardsType:GetRewardsTypeId()
    if rewardsTypeId == ZO_TRIBUTE_REWARD_TYPES.SEASON_REWARDS then
        return string.format("EsoUI/Art/Tribute/tributeRankIcon_%d.dds", self.rewardsTierId)
    else
        return string.format("EsoUI/Art/Tribute/tributeLeaderboardRankIcon_%d.dds", self.rewardsTierId)
    end
end

function ZO_TributeRewardsData:IsAttained()
    local rewardsTypeId = self.rewardsType:GetRewardsTypeId()
    if rewardsTypeId == ZO_TRIBUTE_REWARD_TYPES.SEASON_REWARDS then
        return GetTributePlayerCampaignRank() >= self.rewardsTierId
    else
        return false
    end
end