-- Reward Data --

ZO_TamrielTomesRewardData = ZO_InitializingObject:Subclass()

function ZO_TamrielTomesRewardData:Initialize(tamrielTomeId, rewardTrackId, tierIndex, rewardComponent, rewardIndex)
    self.tamrielTomeId = tamrielTomeId
    self.rewardTrackId = rewardTrackId
    self.tierIndex = tierIndex
    self.rewardComponent = rewardComponent
    self.rewardIndex = rewardIndex
    self.rewardData = nil

    self.tamrielTomeIndex = GetReferenceTrackIndex(REWARD_TRACK_TYPE_TAMRIEL_TOMES, tamrielTomeId)
    self.rewardId, self.rewardQuantity, self.rewardCost, self.rewardDisplayQuality, self.hideRewardQuality = GetTamrielTomesRewardInfo(rewardTrackId, tierIndex, rewardComponent, rewardIndex)
    self:Update()
end

function ZO_TamrielTomesRewardData:Equals(rewardTrackId, rewardTrackTier, rewardTrackComponent, rewardIndex)
    return self:GetRewardTrackId() == rewardTrackId and self:GetTierIndex() == rewardTrackTier and self:GetRewardComponent() == rewardTrackComponent and self:GetRewardIndex() == rewardIndex
end

function ZO_TamrielTomesRewardData:GetRewardData()
    local rewardData = self.rewardData
    if not rewardData then
        if self.rewardId ~= 0 then
            rewardData = REWARDS_MANAGER:GetInfoForReward(self.rewardId, self.rewardQuantity)
            self.rewardData = rewardData
        end
    end
    return rewardData
end

function ZO_TamrielTomesRewardData:GetRewardListId()
    local rewardListId = GetRewardListIdFromReward(self:GetRewardId())
    return rewardListId
end

function ZO_TamrielTomesRewardData:GetRewardListData()
    local rewardListId = self:GetRewardListId()
    if rewardListId == 0 then
        return nil
    end

    local rewardListData = REWARDS_MANAGER:GetAllRewardInfoForRewardList(rewardListId)
    return rewardListData
end

function ZO_TamrielTomesRewardData:GetRewardListRewardDataByIndex(rewardIndex)
    local rewardListData = self:GetRewardListData()
    if not rewardListData then
        return nil
    end

    return rewardListData[rewardIndex]
end

function ZO_TamrielTomesRewardData:GetHideRewardQuality()
    return self.hideRewardQuality
end

function ZO_TamrielTomesRewardData:GetRewardComponent()
    return self.rewardComponent
end

function ZO_TamrielTomesRewardData:GetRewardCost()
    return self.rewardCost
end

function ZO_TamrielTomesRewardData:GetRewardDisplayQuality()
    return self.rewardDisplayQuality
end

function ZO_TamrielTomesRewardData:GetRewardId()
    return self.rewardId
end

function ZO_TamrielTomesRewardData:GetRewardIndex()
    return self.rewardIndex
end

function ZO_TamrielTomesRewardData:GetPlatformIcon()
    local rewardData = self:GetRewardListRewardDataByIndex(1)
    if not rewardData then
        rewardData = self:GetRewardData()
    end

    if rewardData then
        return rewardData:GetPlatformIcon()
    end

    return nil
end

function ZO_TamrielTomesRewardData:GetRewardQuantity()
    return self.rewardQuantity
end

function ZO_TamrielTomesRewardData:GetRewardTrackId()
    return self.rewardTrackId
end

function ZO_TamrielTomesRewardData:GetRewardType()
    local rewardData = self:GetRewardData()
    if rewardData then
        return rewardData:GetRewardType()
    end
    return nil
end

function ZO_TamrielTomesRewardData:IsRewardList()
    local rewardType = self:GetRewardType()
    return rewardType == REWARD_ENTRY_TYPE_REWARD_LIST
end

function ZO_TamrielTomesRewardData:GetTierIndex()
    return self.tierIndex
end

function ZO_TamrielTomesRewardData:GetTamrielTomeId()
    return self.tamrielTomeId
end

function ZO_TamrielTomesRewardData:GetTamrielTomeIndex()
    return self.tamrielTomeIndex
end

function ZO_TamrielTomesRewardData:IsRewardClaimed()
    return self.isClaimed
end

function ZO_TamrielTomesRewardData:IsRewardFallback()
    return self.isFallback
end

function ZO_TamrielTomesRewardData:IsRewardInfinitelyRepeatable()
    return self.isInfinitelyRepeatable
end

function ZO_TamrielTomesRewardData:CanClaimReward()
    return not self:IsRewardClaimed()
end

function ZO_TamrielTomesRewardData:TryClaimReward()
    local trackIndex = self:GetTamrielTomeIndex()
    local tierIndex = self:GetTierIndex()
    local component = self:GetRewardComponent()
    local rewardIndex = self:GetRewardIndex()
    ClaimRewardTrackReward(REWARD_TRACK_TYPE_TAMRIEL_TOMES, trackIndex, tierIndex, component, rewardIndex)
end

function ZO_TamrielTomesRewardData:CanPreviewReward()
    return CanPreviewReward(self:GetRewardId()) or self:IsRewardList()
end

function ZO_TamrielTomesRewardData:IsLocked()
    -- TODO Tamriel Tomes
    return false
end

function ZO_TamrielTomesRewardData:Update()
    local trackIndex = self:GetTamrielTomeIndex()
    local tierIndex = self:GetTierIndex()
    local component = self:GetRewardComponent()
    local index = self:GetRewardIndex()
    self.isClaimed, self.isFallback, self.isInfinitelyRepeatable = GetRewardTrackRewardClaimedState(REWARD_TRACK_TYPE_TAMRIEL_TOMES, trackIndex, tierIndex, component, index)
end


-- Tamriel Tome Data --

ZO_TamrielTomeData = ZO_InitializingObject:Subclass()

function ZO_TamrielTomeData:Initialize(tamrielTomeId)
    self.tamrielTomeId = tamrielTomeId
    self.tamrielTomeIndex = GetReferenceTrackIndex(REWARD_TRACK_TYPE_TAMRIEL_TOMES, tamrielTomeId)

    self:Update()
end

function ZO_TamrielTomeData:GetTamrielTomeId()
    return self.tamrielTomeId
end

function ZO_TamrielTomeData:GetTamrielTomeIndex()
    return self.tamrielTomeIndex
end

function ZO_TamrielTomeData:GetRewardTrackId()
    return self.rewardTrackId
end

function ZO_TamrielTomeData:GetCurrentTier()
    return self.currentTier
end

function ZO_TamrielTomeData:GetProgressToNextTier()
    return self.progressToNextTier
end

function ZO_TamrielTomeData:GetEndTime()
    return self.endTime
end

function ZO_TamrielTomeData:GetDisplayFlags()
    return self:GetRewardData():GetDisplayFlags()
end

function ZO_TamrielTomeData:GetDisplayName()
    return GetRewardTrackDisplayName(self.rewardTrackId)
end

function ZO_TamrielTomeData:GetRewardTrackBackgroundFile()
    return GetRewardTrackBackgroundFileIndex(self.rewardTrackId)
end

function ZO_TamrielTomeData:GetIntroBackgroundFile()
    return GetTamrielTomeIntroBackgroundFileIndex(self.tamrielTomeId)
end

function ZO_TamrielTomeData:GetPremiumUpgradeBackgroundFile()
    return GetTamrielTomePremiumUpgradeBackgroundFileIndex(self.tamrielTomeId)
end

function ZO_TamrielTomeData:GetNumRewards()
    -- TODO Tamriel Tomes
end

function ZO_TamrielTomeData:GetNumClaimedRewards()
    -- TODO Tamriel Tomes
end

function ZO_TamrielTomeData:GetNumHighlights()
    return GetNumTamrielTomeHighlights(self.tamrielTomeId)
end

function ZO_TamrielTomeData:GetHighlightInfo(highlightIndex)
    return GetTamrielTomeHighlightInfo(self.tamrielTomeId, highlightIndex)
end

function ZO_TamrielTomeData:GetNumFeaturedRewards()
    return GetNumTamrielTomeFeaturedRewards(self.tamrielTomeId)
end

function ZO_TamrielTomeData:GetFeaturedRewardInfo(rewardIndex)
    return GetTamrielTomeFeaturedRewardInfo(self.tamrielTomeId, rewardIndex)
end

function ZO_TamrielTomeData:Update()
    self.rewardTrackId, self.currentTier, self.progressToNextTier, self.endTime = GetInfoForRewardTrack(REWARD_TRACK_TYPE_TAMRIEL_TOMES, self.tamrielTomeIndex)
end