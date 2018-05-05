ZO_LevelUpRewardsUpcoming_Base = ZO_Object:Subclass()

function ZO_LevelUpRewardsUpcoming_Base:New(...)
    local rewards = ZO_Object.New(self)
    rewards:Initialize(...)
    return rewards
end

function ZO_LevelUpRewardsUpcoming_Base:Initialize(control, rewardTemplate)
    self.control = control

    self.scrollContainer = control:GetNamedChild("ScrollContainer")
    self.scrollChild = self.scrollContainer:GetNamedChild("ScrollChild")
    self.nextLevelContainer = self.scrollChild:GetNamedChild("NextLevelContainer")
    self.nextMilestoneContainer = self.scrollChild:GetNamedChild("NextMilestoneContainer")

    self.rewardPool = ZO_ControlPool:New(rewardTemplate, control, "Reward")
end

function ZO_LevelUpRewardsUpcoming_Base:LayoutUpcomingRewards()
    self:ReleaseAllRewardControls()

    local nextRewardLevel = ZO_LEVEL_UP_REWARDS_MANAGER:GetUpcomingRewardLevel()
    local nextRewards = ZO_LEVEL_UP_REWARDS_MANAGER:GetUpcomingLevelUpRewards()
    self:LayoutRewardsForLevel(nextRewardLevel, nextRewards, self.nextLevelContainer)

    -- if the next level is also the next milestone then we need the nextLevelContainer display
    -- as a milestone like nextMilestoneContainer. This avoids having to reanchor both containers
    -- and complicating the keyboard dynamic layout function.
    local isNextRewardLevelMilestone = IsLevelUpRewardMilestoneForLevel(nextRewardLevel)
    if isNextRewardLevelMilestone then
        self.nextLevelContainer.titleControl:SetText(zo_strformat(SI_LEVEL_UP_REWARDS_NEXT_MILESTONE_REWARD_HEADER, nextRewardLevel))
    else
        self.nextLevelContainer.titleControl:SetText(GetString(SI_LEVEL_UP_REWARDS_NEXT_LEVEL_REWARD_HEADER))
    end

    local nextMilestoneRewardLevel = ZO_LEVEL_UP_REWARDS_MANAGER:GetUpcomingMilestoneRewardLevel()
    if nextMilestoneRewardLevel then
        self.nextMilestoneContainer:SetHidden(false)
        self.nextMilestoneContainer.titleControl:SetText(zo_strformat(SI_LEVEL_UP_REWARDS_NEXT_MILESTONE_REWARD_HEADER, nextMilestoneRewardLevel))

        local nextMilestoneRewards = ZO_LEVEL_UP_REWARDS_MANAGER:GetUpcomingMilestoneLevelUpRewards()
        self:LayoutRewardsForLevel(nextMilestoneRewardLevel, nextMilestoneRewards, self.nextMilestoneContainer)
    else
        self.nextMilestoneContainer:SetHidden(true)
    end
end

function ZO_LevelUpRewardsUpcoming_Base:AcquireRewardControl()
    return self.rewardPool:AcquireObject()
end

function ZO_LevelUpRewardsUpcoming_Base:ReleaseAllRewardControls()
    self.rewardPool:ReleaseAllObjects()
end

function ZO_LevelUpRewardsUpcoming_Base:LayoutRewardsForLevel(level, levelRewards, rewardContainer)
    ZO_LevelUpRewardsArtTile_SetupTileForLevel(rewardContainer, level)
end
