ZO_LevelUpRewardsClaim_Base = ZO_Object:Subclass()

function ZO_LevelUpRewardsClaim_Base:New(...)
    local rewards = ZO_Object.New(self)
    rewards:Initialize(...)
    return rewards
end

function ZO_LevelUpRewardsClaim_Base:Initialize()
    self.rewardLevel = nil
    self.rewardId = nil

    ZO_LEVEL_UP_REWARDS_MANAGER:RegisterCallback("OnLevelUpRewardsChoiceUpdated", function() if self:IsShowing() then self:RefreshSelectedChoices() end end)
end

function ZO_LevelUpRewardsClaim_Base:ShowLevelUpRewards()
    self.rewardLevel = ZO_LEVEL_UP_REWARDS_MANAGER:GetPendingRewardLevel()
    self.rewardId = ZO_LEVEL_UP_REWARDS_MANAGER:GetPendingRewardId()

    self:UpdateHeader()

    local rewardEntryInfo = ZO_LEVEL_UP_REWARDS_MANAGER:GetPendingLevelUpRewards()
    self:AddRewards(rewardEntryInfo)
end

function ZO_LevelUpRewardsClaim_Base:GetRewardLevel()
    return self.rewardLevel
end

function ZO_LevelUpRewardsClaim_Base:GetRewardId()
    return self.rewardId
end

function ZO_LevelUpRewardsClaim_Base:UpdateHeader()
    --to be overridden
end

function ZO_LevelUpRewardsClaim_Base:AddRewards(rewards)
    --to be overridden
end

function ZO_LevelUpRewardsClaim_Base:Show()
    --to be overridden
end

function ZO_LevelUpRewardsClaim_Base:Hide()
    --to be overridden
end

function ZO_LevelUpRewardsClaim_Base:IsShowing()
    --to be overridden
end

function ZO_LevelUpRewardsClaim_Base:RefreshSelectedChoices()
    --to be overridden
end

function ZO_LevelUpRewardsClaim_Base:ClaimLevelUpRewards()
    local numFreeInventorySlotsNeeded = GetNumInventorySlotsNeededForLevelUpReward(self.rewardId)
    if CheckInventorySpaceAndWarn(numFreeInventorySlotsNeeded) then
        ClaimPendingLevelUpReward()
        PlaySound(SOUNDS.LEVEL_UP_REWARD_CLAIM)
    end
end
