-- Rewardable Data Base --
ZO_PromotionalEventRewardableData_Base = ZO_InitializingObject:Subclass()

ZO_PromotionalEventRewardableData_Base:MUST_IMPLEMENT("IsRewardClaimed")
ZO_PromotionalEventRewardableData_Base:MUST_IMPLEMENT("CanClaimReward")
ZO_PromotionalEventRewardableData_Base:MUST_IMPLEMENT("TryClaimReward")
ZO_PromotionalEventRewardableData_Base:MUST_IMPLEMENT("GetRewardData")

-- Activity Data --

ZO_PromotionalEventActivityData = ZO_PromotionalEventRewardableData_Base:Subclass()

function ZO_PromotionalEventActivityData:Initialize(campaignData, activityIndex)
    self.campaignData = campaignData
    self.activityIndex = activityIndex
    self.activityId, self.displayName, self.description, self.completionThreshold, self.rewardId, self.rewardQuantity = GetPromotionalEventCampaignActivityInfo(self:GetCampaignKey(), self.activityIndex)
    -- Allows us to use this object as an entry data in a list without issues with any lazy loading data
    self.dataContainer = {}
end

function ZO_PromotionalEventActivityData:GetCampaignData()
    return self.campaignData
end

function ZO_PromotionalEventActivityData:GetCampaignKey()
    return self.campaignData:GetKey()
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
    return self.description
end

function ZO_PromotionalEventActivityData:GetCompletionThreshold()
    return self.completionThreshold
end

function ZO_PromotionalEventActivityData:GetProgress()
    local progress, isRewardClaimed = GetPromotionalEventCampaignActivityProgress(self:GetCampaignKey(), self.activityIndex)
    return progress, isRewardClaimed
end

function ZO_PromotionalEventActivityData:IsComplete()
    local progress = self:GetProgress()
    return progress == self.completionThreshold
end

function ZO_PromotionalEventActivityData:IsRewardClaimed()
    local _, isRewardClaimed = self:GetProgress()
    return isRewardClaimed
end

function ZO_PromotionalEventActivityData:CanClaimReward()
    local progress, isRewardClaimed = GetPromotionalEventCampaignActivityProgress(self:GetCampaignKey(), self.activityIndex)
    return not isRewardClaimed and progress == self.completionThreshold
end

function ZO_PromotionalEventActivityData:TryClaimReward()
    TryClaimPromotionalEventActivityReward(self:GetCampaignKey(), self.activityIndex)
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
    return campaignKey == self:GetCampaignKey() and activityIndex == self.activityIndex
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

-- Milestone Data --

ZO_PromotionalEventMilestoneData = ZO_PromotionalEventRewardableData_Base:Subclass()

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
    local isRewardClaimed = IsPromotionalEventCampaignMilestoneRewardClaimed(self:GetCampaignKey(), self.milestoneIndex)
    return isRewardClaimed
end

function ZO_PromotionalEventMilestoneData:CanClaimReward()
    return self:HasReachedMilestone() and not self:IsRewardClaimed()
end

function ZO_PromotionalEventMilestoneData:TryClaimReward()
    TryClaimPromotionalEventMilestoneReward(self:GetCampaignKey(), self.milestoneIndex)
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

ZO_PromotionalEventCampaignData = ZO_PromotionalEventRewardableData_Base:Subclass()

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

function ZO_PromotionalEventCampaignData:GetAnnouncementBannerText()
    local announcementBannerText = GetPromotionalEventCampaignAnnouncementBannerText(self.campaignKey)
    return announcementBannerText
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

function ZO_PromotionalEventCampaignData:GetMilestoneData(milestoneIndex)
    if milestoneIndex <= self.numMilestones then
        local milestones = self:GetMilestones()
        for _, milestoneData in ipairs(self.milestones) do
            if milestoneData:GetMilestoneIndex() == milestoneIndex then
                return milestoneData
            end
        end
    end
    return nil
end

function ZO_PromotionalEventCampaignData:GetMilestoneDataByDisplayIndex(displayIndex)
    if milestoneIndex <= self.numMilestones then
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
    local numActivitiesCompleted, isCapstoneRewardClaimed = GetPromotionalEventCampaignProgress(self.campaignKey)
    return numActivitiesCompleted, isCapstoneRewardClaimed
end

function ZO_PromotionalEventCampaignData:GetNumActivitiesCompleted()
    local numActivitiesCompleted = self:GetProgress()
    return numActivitiesCompleted
end

function ZO_PromotionalEventCampaignData:GetCapstoneRewardThreshold()
    return self.capstoneCompletionThreshold
end

function ZO_PromotionalEventCampaignData:IsRewardClaimed()
    local _, isCapstoneRewardClaimed = self:GetProgress()
    return isCapstoneRewardClaimed
end

function ZO_PromotionalEventCampaignData:CanClaimReward()
    local numActivitiesCompleted, isCapstoneRewardClaimed = GetPromotionalEventCampaignProgress(self.campaignKey)
    return not isCapstoneRewardClaimed and numActivitiesCompleted >= self.capstoneCompletionThreshold
end

function ZO_PromotionalEventCampaignData:TryClaimReward()
    TryClaimPromotionalEventCapstoneReward(self.campaignKey)
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

function ZO_PromotionalEventCampaignData:IsAnyRewardClaimable()
    local IsAnyRewardClaimable = IsAnyPromotionalEventCampaignRewardClaimable(self.campaignKey)
    return IsAnyRewardClaimable
end

function ZO_PromotionalEventCampaignData:TryClaimAllAvailableRewards()
    TryClaimAllAvailablePromotionalEventCampaignRewards(self.campaignKey)
end

function ZO_PromotionalEventCampaignData:HasBeenSeen()
    return PROMOTIONAL_EVENT_MANAGER:HasCampaignBeenSeen(self)
end

function ZO_PromotionalEventCampaignData:SetSeen(seen)
    return PROMOTIONAL_EVENT_MANAGER:SetCampaignSeen(self, seen)
end
