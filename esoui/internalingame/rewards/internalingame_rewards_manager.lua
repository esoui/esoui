
---------------------
-- Rewards Manager
---------------------

local InternalIngameRewardsManager = ZO_RewardsManager:Subclass()

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

function InternalIngameRewardsManager:GetListOfRewardNamesFromLastCodeRedemption()
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
            internalassert(GetNumRewardListEntries(rewardListId) == #rewardListEntries, string.format("Code Redemption: Unsupported reward type in reward list %d", rewardListId))
        else
            -- we don't have a quantity so we'll assume 1, we shouldn't be getting any rewards
            -- here that require a quantity specified, those should come as part of a reward list
            local quantity = 1
            local rewardData = self:GetInfoForReward(rewardId, quantity)
            if internalassert(rewardData, string.format("Code Redemption: Unsupported reward type for reward %d", rewardId)) then
                local displayName = rewardData:GetFormattedName()
                table.insert(rewardNames, displayName)
            end
        end
    end

    return rewardNames
end

function InternalIngameRewardsManager:GetRewardContextualTypeString(rewardId, parentChoice)
    local entryType = GetRewardType(rewardId)
    if entryType == REWARD_ENTRY_TYPE_COLLECTIBLE then
        local collectibleId = GetCollectibleRewardCollectibleId(rewardId)
        if collectibleId > 0 then
            local specializedCollectibleType = GetSpecializedCollectibleType(collectibleId)
            if specializedCollectibleType == SPECIALIZED_COLLECTIBLE_TYPE_NONE then
                return GetString("SI_COLLECTIBLECATEGORYTYPE", GetCollectibleCategoryType(collectibleId))
            else
                return GetString("SI_SPECIALIZEDCOLLECTIBLETYPE", specializedCollectibleType)
            end
        end
    end
    return ZO_RewardsManager.GetRewardContextualTypeString(self, rewardId, parentChoice)
end

REWARDS_MANAGER = InternalIngameRewardsManager:New()