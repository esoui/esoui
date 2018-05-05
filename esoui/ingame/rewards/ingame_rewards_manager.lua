
---------------------
-- Rewards Manager
---------------------

local IngameRewardsManager = ZO_RewardsManager:Subclass()

function IngameRewardsManager:New(...)
	return ZO_RewardsManager.New(self)
end

function IngameRewardsManager:GetCollectibleEntryInfo(rewardId, parentChoice)
    local collectibleId = GetCollectibleRewardCollectibleId(rewardId)
    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
    if collectibleData then
        local rewardData = ZO_RewardData:New(rewardId, parentChoice)
        rewardData:SetFormattedName(collectibleData:GetFormattedName())
        rewardData:SetIcon(collectibleData:GetIcon())
        rewardData:SetAnnouncementBackground(GetRewardAnnouncementBackgroundFileIndex(rewardId))

        return rewardData
    end

    return nil
end

REWARDS_MANAGER = IngameRewardsManager:New()
