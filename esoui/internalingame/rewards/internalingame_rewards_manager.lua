
---------------------
-- Rewards Manager
---------------------

local InternalIngameRewardsManager = ZO_RewardsManager:Subclass()

function InternalIngameRewardsManager:New(...)
    return ZO_RewardsManager.New(self)
end

function InternalIngameRewardsManager:GetCollectibleEntryInfo(rewardId, parentChoice)
    local collectibleId = GetCollectibleRewardCollectibleId(rewardId)
    if collectibleId > 0 then
        local rewardData = ZO_RewardData:New(rewardId, parentChoice)
		local collectibleName, collectibleDescription, collectibleIcon = GetCollectibleInfo(collectibleId)
        rewardData:SetFormattedName(ZO_CachedStrFormat(SI_COLLECTIBLE_NAME_FORMATTER, collectibleName))
        rewardData:SetIcon(collectibleIcon)
        rewardData:SetAnnouncementBackground(GetRewardAnnouncementBackgroundFileIndex(rewardId))

        return rewardData
    end

    return nil
end

REWARDS_MANAGER = InternalIngameRewardsManager:New()