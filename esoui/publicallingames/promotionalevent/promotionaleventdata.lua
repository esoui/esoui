-- Activity Data --

ZO_PromotionalEventActivityData = ZO_RewardableData_Base:Subclass()

function ZO_PromotionalEventActivityData:Initialize(campaignData, activityIndex)
    self.campaignData = campaignData
    self.activityIndex = activityIndex
    local unusedDescription -- see ZO_PromotionalEventActivityData:GetDescription
    self.activityId, self.displayName, unusedDescription, self.completionThreshold, self.rewardId, self.rewardQuantity = GetPromotionalEventCampaignActivityInfo(self:GetCampaignKey(), self.activityIndex)
    -- Allows us to use this object as an entry data in a list without issues with any lazy loading data
    self.dataContainer = {}
end

function ZO_PromotionalEventActivityData:GetCampaignData()
    return self.campaignData
end

function ZO_PromotionalEventActivityData:GetCampaignKey()
    return self.campaignData:GetKey()
end

function ZO_PromotionalEventActivityData:MatchesCampaignKey(campaignKey)
    return AreId64sEqual(campaignKey, self:GetCampaignKey())
end

function ZO_PromotionalEventActivityData:GetActivityIndex()
    return self.activityIndex
end

function ZO_PromotionalEventActivityData:GetId()
    return self.activityId
end

function ZO_PromotionalEventActivityData:GetDisplayName()
    return self.displayName
end

function ZO_PromotionalEventActivityData:GetDescription()
    -- The description cp string can change depending on a number of dynamic factors, so the text isn't always static
    local description = GetPromotionalEventCampaignActivityDescription(self:GetCampaignKey(), self.activityIndex)
    return description
end

function ZO_PromotionalEventActivityData:GetCompletionThreshold()
    return self.completionThreshold
end

function ZO_PromotionalEventActivityData:GetProgress()
    local progress, rewardFlags = GetPromotionalEventCampaignActivityProgress(self:GetCampaignKey(), self.activityIndex)
    return progress, rewardFlags
end

function ZO_PromotionalEventActivityData:IsComplete()
    local progress = self:GetProgress()
    return progress == self.completionThreshold
end

function ZO_PromotionalEventActivityData:IsRewardClaimed()
    local _, rewardFlags = self:GetProgress()
    local isRewardClaimed = ZO_FlagHelpers.MaskHasFlag(rewardFlags, PROMOTIONAL_EVENTS_REWARD_FLAG_CLAIMED)
    if isRewardClaimed then
        local wasFallbackClaimed = ZO_FlagHelpers.MaskHasFlag(rewardFlags, PROMOTIONAL_EVENTS_REWARD_FLAG_FALLBACK)
        return true, wasFallbackClaimed
    end
    return false
end

function ZO_PromotionalEventActivityData:CanClaimReward()
    local progress, rewardFlags = self:GetProgress()
    local isRewardClaimed = ZO_FlagHelpers.MaskHasFlag(rewardFlags, PROMOTIONAL_EVENTS_REWARD_FLAG_CLAIMED)
    return not isRewardClaimed and progress == self.completionThreshold
end

function ZO_PromotionalEventActivityData:TryClaimReward(rewardChoiceId)
    TryClaimPromotionalEventActivityReward(self:GetCampaignKey(), self.activityIndex, rewardChoiceId)
end

function ZO_PromotionalEventActivityData:GetRewardData()
    local rewardData = self.dataContainer.rewardData
    if not rewardData then
        if self.rewardId ~= 0 then
            rewardData = REWARDS_MANAGER:GetInfoForReward(self.rewardId, self.rewardQuantity)
            self.dataContainer.rewardData = rewardData
        end
    end
    return rewardData
end

function ZO_PromotionalEventActivityData:IsTracked()
    local campaignKey, activityIndex = GetTrackedPromotionalEventActivityInfo()
    return self:MatchesCampaignKey(campaignKey) and activityIndex == self.activityIndex
end

function ZO_PromotionalEventActivityData:ToggleTracking(suppressSound)
    if self:IsTracked() then
        ClearTrackedPromotionalEventActivity()
        if not suppressSound then
            PlaySound(SOUNDS.PROMOTIONAL_EVENT_TRACK_ACTIVITY_UNCLICK)
        end
    else
        TrackPromotionalEventActivity(self:GetCampaignKey(), self.activityIndex)
        if not suppressSound then
            PlaySound(SOUNDS.PROMOTIONAL_EVENT_TRACK_ACTIVITY_CLICK)
        end
    end
end

function ZO_PromotionalEventActivityData:GetRequiredCollectibleId()
    local requiredCollectibleId = GetTimedActivityRequiredCollectible(self.activityId)
    return requiredCollectibleId
end

function ZO_PromotionalEventActivityData:GetRequiredCollectibleData()
    local requiredCollectibleId = self:GetRequiredCollectibleId()
    return ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(requiredCollectibleId)
end

function ZO_PromotionalEventActivityData:IsLocked()
    local requiredCollectibleData = self:GetRequiredCollectibleData()
    return requiredCollectibleData and requiredCollectibleData:IsLocked() or false
end

function ZO_PromotionalEventActivityData:GetMenuAssistanceInfo()
    local menuAssistanceType, referenceData = GetTimedActivityMenuAssistanceInfo(self.activityId)
    return menuAssistanceType, referenceData
end

function ZO_PromotionalEventActivityData:HasMenuAssistance()
    local menuAssistanceType, referenceData = self:GetMenuAssistanceInfo()
    return menuAssistanceType ~= MENU_ASSISTANCE_TYPE_NONE
end

function ZO_PromotionalEventActivityData:ShouldShowMenuAssistance()
    if self:IsComplete() then
        return false
    end

    local menuAssistanceType, referenceData = self:GetMenuAssistanceInfo()

    if menuAssistanceType == MENU_ASSISTANCE_TYPE_UI_SYSTEM and referenceData == UI_SYSTEM_ANNOUNCEMENT and PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:HasPersonalCampaign() then
        -- Don't bother showing the assistance if it's not going to do anything anyway.
        -- The personal campaign wants you to jump to the intro experience, but if you can't do the intro experience
        -- (e.g.: you're in a tutorial area, or already in the intro experience) then there's no point trying to take you to the menu because 
        -- it will fail to jump you.
        return PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:CanJumpToIntroGameplay()
    end

    return menuAssistanceType ~= MENU_ASSISTANCE_TYPE_NONE
end

function ZO_PromotionalEventActivityData:GetMenuAssistanceDescriptionText(keybind)
    local menuAssistanceType, referenceData = self:GetMenuAssistanceInfo()
    return ZO_UI_SYSTEM_MANAGER:GetMenuAssistanceDescriptionText(menuAssistanceType, referenceData, keybind)
end

function ZO_PromotionalEventActivityData:TriggerMenuAssistance()
    local menuAssistanceType, referenceData = self:GetMenuAssistanceInfo()
    if menuAssistanceType == MENU_ASSISTANCE_TYPE_GRAVEYARD then
        RequestJumpToTimedActivityMenuAssistanceInfo(self.activityId)
    else
        ZO_UI_SYSTEM_MANAGER:TriggerMenuAssistance(menuAssistanceType, referenceData)
    end
end

-- Milestone Data --

ZO_PromotionalEventMilestoneData = ZO_RewardableData_Base:Subclass()

function ZO_PromotionalEventMilestoneData:Initialize(campaignData, milestoneIndex)
    self.campaignData = campaignData
    self.milestoneIndex = milestoneIndex
    self.completionThreshold, self.rewardId, self.rewardQuantity = GetPromotionalEventCampaignMilestoneInfo(self:GetCampaignKey(), self.milestoneIndex)
    -- Allows us to use this object as an entry data in a list without issues with any lazy loading data
    self.dataContainer = {}
end

function ZO_PromotionalEventMilestoneData:GetCampaignData()
    return self.campaignData
end

function ZO_PromotionalEventMilestoneData:GetCampaignKey()
    return self.campaignData:GetKey()
end

function ZO_PromotionalEventMilestoneData:GetMilestoneIndex()
    return self.milestoneIndex
end

function ZO_PromotionalEventMilestoneData:GetDisplayIndex()
    return self.displayIndex or self.milestoneIndex
end

function ZO_PromotionalEventMilestoneData:SetDisplayIndex(displayIndex)
    self.displayIndex = displayIndex
end

function ZO_PromotionalEventMilestoneData:GetCompletionThreshold()
    return self.completionThreshold
end

function ZO_PromotionalEventMilestoneData:HasReachedMilestone()
   return self.campaignData:GetNumActivitiesCompleted() >= self.completionThreshold
end

function ZO_PromotionalEventMilestoneData:IsRewardClaimed()
    local rewardFlags = GetPromotionalEventCampaignMilestoneRewardFlags(self:GetCampaignKey(), self.milestoneIndex)
    local isRewardClaimed = ZO_FlagHelpers.MaskHasFlag(rewardFlags, PROMOTIONAL_EVENTS_REWARD_FLAG_CLAIMED)
    if isRewardClaimed then
        local wasFallbackClaimed = ZO_FlagHelpers.MaskHasFlag(rewardFlags, PROMOTIONAL_EVENTS_REWARD_FLAG_FALLBACK)
        return true, wasFallbackClaimed
    end
    return false
end

function ZO_PromotionalEventMilestoneData:CanClaimReward()
    return self:HasReachedMilestone() and not self:IsRewardClaimed()
end

function ZO_PromotionalEventMilestoneData:TryClaimReward(rewardChoiceId)
    TryClaimPromotionalEventMilestoneReward(self:GetCampaignKey(), self.milestoneIndex, rewardChoiceId)
end

function ZO_PromotionalEventMilestoneData:GetRewardData()
    local rewardData = self.dataContainer.rewardData
    if not rewardData then
        if self.rewardId ~= 0 then
            rewardData = REWARDS_MANAGER:GetInfoForReward(self.rewardId, self.rewardQuantity)
            self.dataContainer.rewardData = rewardData
        end
    end
    return rewardData
end


-- Campaign Data --

ZO_PromotionalEventCampaignData = ZO_RewardableData_Base:Subclass()

function ZO_PromotionalEventCampaignData:Initialize(campaignKey)
    self.campaignKey = campaignKey
    self.campaignId, self.numActivities, self.numMilestones, self.capstoneCompletionThreshold, self.capstoneRewardId, self.capstoneRewardQuantity = GetPromotionalEventCampaignInfo(self.campaignKey)
    -- Allows us to use this object as an entry data in a list without issues with any lazy loading data
    self.activities = {}
    self.milestones = {}
    self.dataContainer = {}
end

function ZO_PromotionalEventCampaignData:GetKey()
    return self.campaignKey
end

function ZO_PromotionalEventCampaignData:GetKeyString()
    return Id64ToString(self.campaignKey)
end

function ZO_PromotionalEventCampaignData:MatchesKeyWithCampaign(otherCampaignData)
    local otherKey = otherCampaignData:GetKey()
    return AreId64sEqual(self.campaignKey, otherKey)
end

function ZO_PromotionalEventCampaignData:GetId()
    return self.campaignId
end

function ZO_PromotionalEventCampaignData:GetDisplayName()
    local displayName = GetPromotionalEventCampaignDisplayName(self.campaignId)
    return displayName
end

function ZO_PromotionalEventCampaignData:GetDescription()
    local description = GetPromotionalEventCampaignDescription(self.campaignId)
    return description
end

function ZO_PromotionalEventCampaignData:GetLargeBackgroundFileIndex()
    local largeBackgroundFileIndex = GetPromotionalEventCampaignLargeBackgroundFileIndex(self.campaignId)
    return largeBackgroundFileIndex
end

function ZO_PromotionalEventCampaignData:GetAnnouncementBackgroundFileIndex()
    local announcementBackgroundFileIndex = GetPromotionalEventCampaignAnnouncementBackgroundFileIndex(self.campaignId)
    return announcementBackgroundFileIndex
end

function ZO_PromotionalEventCampaignData:GetAnnouncementBannerOverrideType()
    local announcementBannerOverrideType = GetPromotionalEventCampaignAnnouncementBannerOverrideType(self.campaignKey)
    return announcementBannerOverrideType
end

function ZO_PromotionalEventCampaignData:GetAnnouncementBannerText()
    local announcementBannerText = ""
    local announcementBannerOverrideType = self:GetAnnouncementBannerOverrideType()
    if announcementBannerOverrideType == ANNOUNCEMENT_BANNER_OVERRIDE_TYPE_NONE then
        local rewardData = self:GetRewardData()
        return rewardData:GetAnnouncementBannerText() or ""
    else
        announcementBannerText = GetString("SI_ANNOUNCEMENTBANNEROVERRIDETYPE", announcementBannerOverrideType)
    end
    return announcementBannerText
end

function ZO_PromotionalEventCampaignData:GetUIPriority()
    local uiPriority = GetPromotionalEventCampaignUIPriority(self.campaignId)
    return uiPriority
end

function ZO_PromotionalEventCampaignData:IsReturningPlayerCampaign()
    local isReturningPlayerCampaign = IsReturningPlayerPromotionalEventsCampaign(self.campaignKey)
    return isReturningPlayerCampaign
end

function ZO_PromotionalEventCampaignData:IsLowLevelPlayerCampaign()
    local isLowLevelPlayerCampaign = IsLowLevelPlayerPromotionalEventsCampaign(self.campaignKey)
    return isLowLevelPlayerCampaign
end

function ZO_PromotionalEventCampaignData:IsPersonalCampaign()
    return self:IsLowLevelPlayerCampaign() or self:IsReturningPlayerCampaign()
end

function ZO_PromotionalEventCampaignData:GetNextPersonalCampaignKey()
    if self:IsLowLevelPlayerCampaign() then
        return GetCampaignKeyForNextLowLevelPlayerCampaign(self:GetId())
    elseif self:IsReturningPlayerCampaign() then
        return GetCampaignKeyForNextReturningPlayerCampaign(self:GetId())
    end

    return nil
end

function ZO_PromotionalEventCampaignData:ShouldCampaignBeVisible()
    local shouldBeVisible = ShouldPromotionalEventCampaignBeVisible(self.campaignKey)
    return shouldBeVisible
end

function ZO_PromotionalEventCampaignData:GetNumActivities()
    return self.numActivities
end

function ZO_PromotionalEventCampaignData:GetActivities()
    if #self.activities ~= self.numActivities then
        ZO_ClearNumericallyIndexedTable(self.activities)
        for activityIndex = 1, self.numActivities do
            table.insert(self.activities, ZO_PromotionalEventActivityData:New(self, activityIndex))
        end
    end
    return self.activities
end

function ZO_PromotionalEventCampaignData:GetActivityData(activityIndex)
    if activityIndex <= self.numActivities then
        local activities = self:GetActivities()
        return activities[activityIndex]
    end
    return nil
end

function ZO_PromotionalEventCampaignData:GetNumMilestones()
    return self.numMilestones
end

function ZO_PromotionalEventCampaignData:GetMilestones()
    if #self.milestones ~= self.numMilestones then
        ZO_ClearNumericallyIndexedTable(self.milestones)
        for milestoneIndex = 1, self.numMilestones do
            table.insert(self.milestones, ZO_PromotionalEventMilestoneData:New(self, milestoneIndex))
        end

        local function MilestoneComparator(milestone1, milestone2)
            return milestone1:GetCompletionThreshold() < milestone2:GetCompletionThreshold()
        end
        table.sort(self.milestones, MilestoneComparator)

        for displayIndex, milestoneData in ipairs(self.milestones) do
            milestoneData:SetDisplayIndex(displayIndex)
        end
    end
    return self.milestones
end

function ZO_PromotionalEventCampaignData:GetMilestoneRewards()
    local rewards = {}
    local milestones = self:GetMilestones()
    for _, milestone in ipairs(milestones) do
        local reward = milestone:GetRewardData()
        table.insert(rewards, reward)
    end
    return rewards
end

function ZO_PromotionalEventCampaignData:GetMilestoneData(milestoneIndex)
    if milestoneIndex <= self.numMilestones then
        local milestones = self:GetMilestones()
        for _, milestoneData in ipairs(milestones) do
            if milestoneData:GetMilestoneIndex() == milestoneIndex then
                return milestoneData
            end
        end
    end
    return nil
end

function ZO_PromotionalEventCampaignData:GetMilestoneDataByDisplayIndex(displayIndex)
    if displayIndex <= self.numMilestones then
        local milestones = self:GetMilestones()
        return milestones[displayIndex]
    end
    return nil
end

function ZO_PromotionalEventCampaignData:GetSecondsRemaining()
    local secondsRemaining = GetSecondsRemainingInPromotionalEventCampaign(self.campaignKey)
    return secondsRemaining
end

function ZO_PromotionalEventCampaignData:GetProgress()
    local numActivitiesCompleted, capstoneRewardFlags = GetPromotionalEventCampaignProgress(self.campaignKey)
    return numActivitiesCompleted, capstoneRewardFlags
end

function ZO_PromotionalEventCampaignData:GetNumActivitiesCompleted()
    local numActivitiesCompleted = self:GetProgress()
    return numActivitiesCompleted
end

function ZO_PromotionalEventCampaignData:GetCapstoneRewardThreshold()
    return self.capstoneCompletionThreshold
end

function ZO_PromotionalEventCampaignData:IsRewardClaimed()
    local _, rewardFlags = self:GetProgress()
    local isRewardClaimed = ZO_FlagHelpers.MaskHasFlag(rewardFlags, PROMOTIONAL_EVENTS_REWARD_FLAG_CLAIMED)
    if isRewardClaimed then
        local wasFallbackClaimed = ZO_FlagHelpers.MaskHasFlag(rewardFlags, PROMOTIONAL_EVENTS_REWARD_FLAG_FALLBACK)
        return true, wasFallbackClaimed
    end
    return false
end

function ZO_PromotionalEventCampaignData:CanClaimReward()
    if self.capstoneRewardId == 0 then
        return false
    end
    local numActivitiesCompleted, rewardFlags = self:GetProgress()
    local isRewardClaimed = ZO_FlagHelpers.MaskHasFlag(rewardFlags, PROMOTIONAL_EVENTS_REWARD_FLAG_CLAIMED)
    return not isRewardClaimed and numActivitiesCompleted >= self.capstoneCompletionThreshold
end

function ZO_PromotionalEventCampaignData:TryClaimReward(rewardChoiceId)
    TryClaimPromotionalEventCapstoneReward(self.campaignKey, rewardChoiceId)
end

function ZO_PromotionalEventCampaignData:GetRewardData()
    local capstoneRewardData = self.dataContainer.capstoneRewardData
    if not capstoneRewardData then
        if self.capstoneRewardId ~= 0 then
            capstoneRewardData = REWARDS_MANAGER:GetInfoForReward(self.capstoneRewardId, self.capstoneRewardQuantity)
            self.dataContainer.capstoneRewardData = capstoneRewardData
        end
    end
    return capstoneRewardData
end

function ZO_PromotionalEventCampaignData:GetPromotionalEventRewardableDataByTypeAndIndex(type, index)
    if type == PROMOTIONAL_EVENTS_COMPONENT_TYPE_SCHEDULE then
        return self
    elseif type == PROMOTIONAL_EVENTS_COMPONENT_TYPE_MILESTONE_REWARD then
        return self:GetMilestoneData(index)
    elseif type == PROMOTIONAL_EVENTS_COMPONENT_TYPE_ACTIVITY then
        return self:GetActivityData(index)
    end
    return nil
end

function ZO_PromotionalEventCampaignData:IsAnyRewardClaimable()
    if not self:ShouldCampaignBeVisible() then
        return false
    end

    if self.isAnyRewardClaimable == nil then
        self.isAnyRewardClaimable = IsAnyPromotionalEventCampaignRewardClaimable(self.campaignKey)
    end
    return self.isAnyRewardClaimable
end

function ZO_PromotionalEventCampaignData:TryClaimAllAvailableRewards()
    TryClaimAllAvailablePromotionalEventCampaignRewards(self.campaignKey)
end

function ZO_PromotionalEventCampaignData:AreAllRewardsClaimed()
    if self.areAllRewardsClaimed == nil then
        self.areAllRewardsClaimed = AreAllPromotionalEventCampaignRewardsClaimed(self.campaignKey)
    end
    return self.areAllRewardsClaimed
end

function ZO_PromotionalEventCampaignData:HasAnyUnclaimedRewards()
    return not self:AreAllRewardsClaimed()
end

function ZO_PromotionalEventCampaignData:OnActivityProgressUpdated()
    -- An optimzation since we'll be calling IsAnyRewardClaimable a lot
    self.isAnyRewardClaimable = nil
end

function ZO_PromotionalEventCampaignData:OnRewardsClaimed()
    -- An optimzation since we'll be calling IsAnyRewardClaimable and AreAllRewardsClaimed a lot
    self.areAllRewardsClaimed = nil
    self.isAnyRewardClaimable = nil
end

function ZO_PromotionalEventCampaignData:HasBeenSeen()
    return PROMOTIONAL_EVENT_MANAGER:HasCampaignBeenSeen(self)
end

function ZO_PromotionalEventCampaignData:SetSeen(seen)
    return PROMOTIONAL_EVENT_MANAGER:SetCampaignSeen(self, seen)
end

function ZO_PromotionalEventCampaignData:CompareTo(otherCampaignData)
    local isReturningPlayerCampaign = self:IsReturningPlayerCampaign()
    local otherIsReturningPlayerCampaign = otherCampaignData:IsReturningPlayerCampaign()
    if isReturningPlayerCampaign ~= otherIsReturningPlayerCampaign then
        return isReturningPlayerCampaign
    end

    local uiPriority = self:GetUIPriority()
    local otherUIPriority = otherCampaignData:GetUIPriority()
    if uiPriority ~= otherUIPriority then
        return uiPriority > otherUIPriority
    end

    local secondsRemaining = self:GetSecondsRemaining()
    local otherSecondsRemaining = otherCampaignData:GetSecondsRemaining()
    if secondsRemaining ~= otherSecondsRemaining then
        return secondsRemaining < otherSecondsRemaining
    end

    local displayName = self:GetDisplayName()
    local otherDisplayName = otherCampaignData:GetDisplayName()
    if displayName ~= otherDisplayName then
        return self:GetDisplayName() < otherCampaignData:GetDisplayName()
    end

    return self.campaignId < otherCampaignData:GetId()
end
