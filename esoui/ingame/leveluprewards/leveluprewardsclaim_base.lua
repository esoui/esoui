ZO_LevelUpRewardsClaim_Base = ZO_Object:Subclass()

function ZO_LevelUpRewardsClaim_Base:New(...)
    local rewards = ZO_Object.New(self)
    rewards:Initialize(...)
    return rewards
end

function ZO_LevelUpRewardsClaim_Base:Initialize()
    self.rewardLevel = nil

    ZO_LEVEL_UP_REWARDS_MANAGER:RegisterCallback("OnLevelUpRewardsChoiceUpdated", function() if self:IsShowing() then self:RefreshSelectedChoices() end end)
end

function ZO_LevelUpRewardsClaim_Base:ShowLevelUpRewards()
    local rewardLevel = ZO_LEVEL_UP_REWARDS_MANAGER:GetPendingRewardLevel()
    if rewardLevel then
        self.rewardLevel = rewardLevel

        self:UpdateHeader()

        local rewardEntryInfo = ZO_LEVEL_UP_REWARDS_MANAGER:GetPendingLevelUpRewards()
        self:AddRewards(rewardEntryInfo)
    else
        --It's possible in high latency that they player could claim their last available reward and then make it back to the claim menu entry before the server acknowledges that we claimed it. This can lead
        --to the pending reward info being wiped out as we are changing scenes into claim. So if this happens, we just hide claim automatically.
        self.rewardLevel = nil
        self.rewardId = nil
        self:Hide()
    end
end

function ZO_LevelUpRewardsClaim_Base:GetRewardLevel()
    return self.rewardLevel
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
    local numFreeInventorySlotsNeeded = GetNumInventorySlotsNeededForLevelUpReward(self.rewardLevel)
    if CheckInventorySpaceAndWarn(numFreeInventorySlotsNeeded) then
        ClaimPendingLevelUpReward()
        PlaySound(SOUNDS.LEVEL_UP_REWARD_CLAIM)
    end
end
