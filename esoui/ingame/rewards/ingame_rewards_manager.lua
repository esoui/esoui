
---------------------
-- Rewards Manager
---------------------

local IngameRewardsManager = ZO_RewardsManager:Subclass()

function IngameRewardsManager:GetCollectibleEntryInfo(rewardId, parentChoice)
    local collectibleId = GetCollectibleRewardCollectibleId(rewardId)
    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
    if collectibleData then
        local rewardData = ZO_RewardData:New(rewardId, parentChoice)
        rewardData:SetRawName(collectibleData:GetName())
        rewardData:SetFormattedName(collectibleData:GetFormattedName())
        rewardData:SetIcon(collectibleData:GetIcon())
        rewardData:SetAnnouncementBackground(GetRewardAnnouncementBackgroundFileIndex(rewardId))

        return rewardData
    end

    return nil
end

function IngameRewardsManager:GetRewardContextualTypeString(rewardId, parentChoice)
    local entryType = GetRewardType(rewardId)
    if entryType == REWARD_ENTRY_TYPE_COLLECTIBLE then
        local collectibleId = GetCollectibleRewardCollectibleId(rewardId)
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
        if collectibleData then
            return collectibleData:GetCategoryTypeDisplayName()
        end
    end
    return ZO_RewardsManager.GetRewardContextualTypeString(self, rewardId, parentChoice)
end

REWARDS_MANAGER = IngameRewardsManager:New()
