
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

function InternalIngameRewardsManager:GetListOfRewardNamesFromLastCodeRedemption(rewardId, parentChoice)
    local rewardNames = {}
    local numRewards = GetNumRewardIdsFromLastCodeRedemption()
    for rewardIndex = 1, numRewards do
        local rewardId = GetRewardIdFromLastCodeRedemption(rewardIndex)
        local entryType = GetRewardType(rewardId)
        if entryType == REWARD_ENTRY_TYPE_REWARD_LIST then
            local rewardListId = GetRewardListIdFromReward(rewardId)
            local rewardListEntries = self:GetAllRewardInfoForRewardList(rewardListId)
            for rewardListIndex, rewardData in ipairs(rewardListEntries) do
                local displayName = rewardData:GetFormattedName()
                table.insert(rewardNames, displayName)
            end
        else
            -- we don't have a quantity so we'll assume 1, we shouldn't be getting any rewards
            -- here that require a quantity specified, those should come as part of a reward list
            local quantity = 1
            local rewardData = self:GetInfoForReward(rewardId, quantity)
            local displayName = rewardData:GetFormattedName()
            table.insert(rewardNames, displayName)
        end
    end

    return rewardNames
end

REWARDS_MANAGER = InternalIngameRewardsManager:New()