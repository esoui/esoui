-----------------------------
-- Veterancy Rank
-----------------------------

ZO_VeterancyRankData = ZO_InitializingObject:Subclass()

function ZO_VeterancyRankData:Initialize(index)
    self.index = index
    self.rewards = {}

    self.trackType = ZO_VETERANCY_MANAGER:GetVeterancyTrackType()
    -- There should never be more than 1 active Veterancy Track
    self.veterancyTrackId = GetActiveReferenceTrackIdsForRewardTrackType(self.trackType)
    self.component = ZO_VETERANCY_MANAGER:GetVeterancyComponent()
    self.defaultRewardIndex = ZO_VETERANCY_MANAGER:GetVeterancyDefaultRewardIndex()

    self.rewardTrackId = GetRewardTrackIdFromReferenceTrackId(REWARD_TRACK_TYPE_AVA_VETERANCY, self.veterancyTrackId)
    self.veterancyTrackIndex = GetReferenceTrackIndex(self.trackType, self.veterancyTrackId)

    local numPerks = GetNumberOfPerksUnlockedAtVeterancyRank(self.index)
    for perkIndex = 1, numPerks do
        local rewardData = ZO_VeterancyRankPerkRewardData:New(self, perkIndex)
        table.insert(self.rewards, rewardData)
    end

    self.numClaimableRewards = GetNumRewardsAtRewardTrackTier(self.rewardTrackId, self.index, self.component)
    for claimableRewardIndex = 1, self.numClaimableRewards do
        local rewardIndex = numPerks + claimableRewardIndex
        local rewardData = ZO_VeterancyRankRewardData:New(self, rewardIndex, claimableRewardIndex)
        table.insert(self.rewards, rewardData)
    end

    self.isMaxRank = self.index == GetInfinitelyRepeatableTierForRewardTrack(self.rewardTrackId)

    self:UpdateClaimedState()
end

function ZO_VeterancyRankData:GetRewardTrackId()
    return self.rewardTrackId
end

function ZO_VeterancyRankData:GetIndex()
    return self.index
end

function ZO_VeterancyRankData:GetName()
    return GetVeterancyRankTitle(self.index)
end

function ZO_VeterancyRankData:GetIcon()
    return GetVeterancyRankIcon(self.index)
end

function ZO_VeterancyRankData:GetLargeIcon()
    return GetVeterancyLargeRankIcon(self.index)
end

function ZO_VeterancyRankData:GetNumRewards()
    return #self.rewards
end

function ZO_VeterancyRankData:GetNumClaimableRewards()
    return self.numClaimableRewards
end

function ZO_VeterancyRankData:GetRankRewardDataByIndex(index)
    return self.rewards[index]
end

function ZO_VeterancyRankData:GetProgressPercent()
    local progressToNextRank = self:GetRankTierProgressValue()
    local currentTierTotal = self:GetRankTierTotalValue()
    return currentTierTotal == 0 and 1 or progressToNextRank / currentTierTotal
end

function ZO_VeterancyRankData:GetRankTierProgressValue()
    local _, currentRank, progressToNextRank = GetInfoForRewardTrack(self.trackType, self.veterancyTrackIndex)
    if self.index == currentRank or self.isMaxRank then
        return progressToNextRank
    elseif self.index < currentRank then
        return self:GetRankTierTotalValue()
    else
        return 0
    end
end

function ZO_VeterancyRankData:GetRankTierTotalValue()
    return GetTotalProgressAtRewardTrackTier(self.rewardTrackId, self.index)
end

function ZO_VeterancyRankData:IsRankAttained()
    local currentRank = ZO_VETERANCY_MANAGER:GetCurrentRank()
    return currentRank >= self.index
end

function ZO_VeterancyRankData:IsRepeatableRank()
    return self.isMaxRank
end

function ZO_VeterancyRankData:IsClaimed()
    return self.isClaimed or (self.numClaimableRewards == 0 and self:IsRankAttained())
end

function ZO_VeterancyRankData:CanClaimRank()
    return self.canClaim
end

function ZO_VeterancyRankData:UpdateClaimedState()
    local oldIsClaimed = self.isClaimed
    if self.isMaxRank then
        local numTimesClaimed, numTimesStillClaimable = GetRewardTrackInfinitelyRepeatableRewardClaimedState(self.trackType, self.veterancyTrackIndex, self.index, self.component)
        self.canClaim = numTimesStillClaimable and numTimesStillClaimable > 0
        self.isClaimed = numTimesClaimed and numTimesClaimed > 0 and not self.canClaim
    else
        self.isClaimed = GetRewardTrackRewardClaimedState(self.trackType, self.veterancyTrackIndex, self.index, self.component, self.defaultRewardIndex)
        self.canClaim = self:IsRankAttained() and self.numClaimableRewards > 0 and not self.isClaimed
    end
    return self.isClaimed ~= oldIsClaimed
end

function ZO_VeterancyRankData:TryClaimRankRewards()
    ClaimRewardTrackReward(self.trackType, self.veterancyTrackIndex, self.index, self.component, self.defaultRewardIndex)
end

function ZO_VeterancyRankData:SetIsLeftTooltip(isLeftTooltip)
    self.isLeftTooltip = isLeftTooltip
end

function ZO_VeterancyRankData:IsLeftTooltip()
    return self.isLeftTooltip
end

-------------------------------
-- Veterancy Reward
-------------------------------

ZO_VeterancyRankRewardData = ZO_Object.MultiSubclass(ZO_RewardableData_Base, ZO_PreviewableRewardData)

function ZO_VeterancyRankRewardData:Initialize(rankData, rewardIndex, claimableRewardIndex)
    self.rankData = rankData
    self.rewardIndex = rewardIndex

    self.rewardId = GetVeterancyRewardDefIdAtRewardTrackTierIndex(self.rankData:GetRewardTrackId(), self.rankData:GetIndex(), claimableRewardIndex)
    self.rewardQuantity = GetVeterancyRewardQuantityAtRewardTrackTierIndex(self.rankData:GetRewardTrackId(), self.rankData:GetIndex(), claimableRewardIndex)
end

function ZO_VeterancyRankRewardData:GetRankIndex()
    return self.rankData:GetIndex()
end

function ZO_VeterancyRankRewardData:GetRankNumRewards()
    return self.rankData:GetNumRewards()
end

function ZO_VeterancyRankRewardData:GetRewardId()
    return self.rewardId
end

function ZO_VeterancyRankRewardData:GetRewardIndex()
    return self.rewardIndex
end

function ZO_VeterancyRankRewardData:IsRewardClaimed()
    return self.rankData:IsClaimed()
end

function ZO_VeterancyRankRewardData:CanClaimReward()
    return not self:IsRewardClaimed() and self.rankData:CanClaimRank()
end

function ZO_VeterancyRankRewardData:TryClaimReward()
    self.rankData:TryClaimRankRewards()
end

function ZO_VeterancyRankRewardData:CanPreviewReward()
    return CanPreviewReward(self.rewardId)
end

function ZO_VeterancyRankRewardData:GetRankData()
    return self.rankData
end

function ZO_VeterancyRankRewardData:GetRewardData()
    local rewardData = self.rewardData
    if not rewardData then
        if self.rewardId ~= 0 then
            rewardData = REWARDS_MANAGER:GetInfoForReward(self.rewardId, self.rewardQuantity)
            self.rewardData = rewardData
        end
    end
    return rewardData
end

function ZO_VeterancyRankRewardData:IsRepeatableRank()
    return self.rankData:IsRepeatableRank()
end

function ZO_VeterancyRankRewardData:IsRewardList()
    local rewardData = self:GetRewardData()
    return rewardData and rewardData.rewardType == REWARD_ENTRY_TYPE_REWARD_LIST
end

function ZO_VeterancyRankRewardData:GetRewardListData()
    if not self:IsRewardList() then
        return nil
    end

    local rewardListId = GetRewardListIdFromReward(self:GetRewardId())
    local rewardListData = REWARDS_MANAGER:GetAllRewardInfoForRewardList(rewardListId)
    return rewardListData
end

-------------------------------
-- Veterancy Perk Reward
-------------------------------

ZO_VeterancyPerkData = ZO_RewardData:Subclass()

function ZO_VeterancyPerkData:SetVeterancyRankPerkRewardData(data)
    self.veterancyRankPerkRewardData = data
end

function ZO_VeterancyPerkData:GetVeterancyRankPerkRewardData()
    return self.veterancyRankPerkRewardData
end

ZO_VeterancyRankPerkRewardData = ZO_Object.MultiSubclass(ZO_RewardableData_Base, ZO_PreviewableRewardData)

function ZO_VeterancyRankPerkRewardData:Initialize(rankData, perkRewardIndex)
    self.rankData = rankData
    self.perkRewardIndex = perkRewardIndex

    self.perkId = GetPerkDefIdForPerkAtVeterancyRank(self.rankData:GetIndex(), perkRewardIndex)

    local numSlotFlags = GetNumberOfSlotFlagsForPerkDef(self.rankData:GetIndex(), self.perkRewardIndex)
    for i = 1, numSlotFlags do
        self.slotFlags = ZO_FlagHelpers.SetMaskFlag(self.slotFlags, GetSlotFlagForPerk(self.rankData:GetIndex(), self.perkRewardIndex, i))
    end
end

function ZO_VeterancyRankPerkRewardData:GetRankIndex()
    return self.rankData:GetIndex()
end

function ZO_VeterancyRankPerkRewardData:GetRankNumRewards()
    return self.rankData:GetNumRewards()
end

function ZO_VeterancyRankPerkRewardData:GetRewardIndex()
    return self.perkRewardIndex
end

function ZO_VeterancyRankPerkRewardData:GetSlotFlags()
    return self.slotFlags
end

function ZO_VeterancyRankPerkRewardData:GetIcon()
    return self.rewardData:GetPlatformLootIcon()
end

do
    local VETERANCY_PERK_BORDER_TEXTURE =
    {
        [VENGEANCE_PERK_SLOT_RED_YELLOW_BLUE] = "EsoUI/Art/Vengeance/red_yellow_blue_perk_border.dds",
        [VENGEANCE_PERK_SLOT_RED_YELLOW] = "EsoUI/Art/Vengeance/red_yellow_perk_border.dds",
        [VENGEANCE_PERK_SLOT_RED_BLUE] = "EsoUI/Art/Vengeance/red_blue_perk_border.dds",
        [VENGEANCE_PERK_SLOT_YELLOW_BLUE] = "EsoUI/Art/Vengeance/yellow_blue_perk_border.dds",
        [VENGEANCE_PERK_SLOT_RED] = "EsoUI/Art/Vengeance/red_perk_border.dds",
        [VENGEANCE_PERK_SLOT_YELLOW] = "EsoUI/Art/Vengeance/yellow_perk_border.dds",
        [VENGEANCE_PERK_SLOT_BLUE] = "EsoUI/Art/Vengeance/blue_perk_border.dds",
    }
    function ZO_VeterancyRankPerkRewardData:GetBorderTexture()
        return VETERANCY_PERK_BORDER_TEXTURE[self.slotFlags]
    end

    local VETERANCY_PERK_BACKGROUND_TEXTURE =
    {
        [VENGEANCE_PERK_SLOT_RED_YELLOW_BLUE] = "EsoUI/Art/Vengeance/perk_background_omni.dds",
        [VENGEANCE_PERK_SLOT_RED_YELLOW] = "EsoUI/Art/Vengeance/perk_background_orange.dds",
        [VENGEANCE_PERK_SLOT_RED_BLUE] = "EsoUI/Art/Vengeance/perk_background_purple.dds",
        [VENGEANCE_PERK_SLOT_YELLOW_BLUE] = "EsoUI/Art/Vengeance/perk_background_green.dds",
        [VENGEANCE_PERK_SLOT_RED] = "EsoUI/Art/Vengeance/perk_background_red.dds",
        [VENGEANCE_PERK_SLOT_YELLOW] = "EsoUI/Art/Vengeance/perk_background_yellow.dds",
        [VENGEANCE_PERK_SLOT_BLUE] = "EsoUI/Art/Vengeance/perk_background_blue.dds",
    }
    function ZO_VeterancyRankPerkRewardData:GetBackgroundTexture()
        return VETERANCY_PERK_BACKGROUND_TEXTURE[self.slotFlags]
    end

    local VETERANCY_BORDER_ALPHA_SHADOW_TEXTURE =
    {
        [VENGEANCE_PERK_SLOT_RED_YELLOW_BLUE] = "EsoUI/Art/Vengeance/perk_border_alpha_shadow_omni.dds",
        [VENGEANCE_PERK_SLOT_RED_YELLOW] = "EsoUI/Art/Vengeance/perk_border_alpha_shadow_orange.dds",
        [VENGEANCE_PERK_SLOT_RED_BLUE] = "EsoUI/Art/Vengeance/perk_border_alpha_shadow_purple.dds",
        [VENGEANCE_PERK_SLOT_YELLOW_BLUE] = "EsoUI/Art/Vengeance/perk_border_alpha_shadow_green.dds",
        [VENGEANCE_PERK_SLOT_RED] = "EsoUI/Art/Vengeance/perk_border_alpha_shadow_red.dds",
        [VENGEANCE_PERK_SLOT_YELLOW] = "EsoUI/Art/Vengeance/perk_border_alpha_shadow_yellow.dds",
        [VENGEANCE_PERK_SLOT_BLUE] = "EsoUI/Art/Vengeance/perk_border_alpha_shadow_blue.dds",
    }
    function ZO_VeterancyRankPerkRewardData:GetLockedTexture()
        return VETERANCY_BORDER_ALPHA_SHADOW_TEXTURE[self.slotFlags]
    end

    local VETERANCY_BORDER_SELECTED_TEXTURE =
    {
        [VENGEANCE_PERK_SLOT_RED_YELLOW_BLUE] = "EsoUI/Art/Vengeance/perk_border_selected_omni.dds",
        [VENGEANCE_PERK_SLOT_RED_YELLOW] = "EsoUI/Art/Vengeance/perk_border_selected_orange.dds",
        [VENGEANCE_PERK_SLOT_RED_BLUE] = "EsoUI/Art/Vengeance/perk_border_selected_purple.dds",
        [VENGEANCE_PERK_SLOT_YELLOW_BLUE] = "EsoUI/Art/Vengeance/perk_border_selected_green.dds",
        [VENGEANCE_PERK_SLOT_RED] = "EsoUI/Art/Vengeance/perk_border_selected_red.dds",
        [VENGEANCE_PERK_SLOT_YELLOW] = "EsoUI/Art/Vengeance/perk_border_selected_yellow.dds",
        [VENGEANCE_PERK_SLOT_BLUE] = "EsoUI/Art/Vengeance/perk_border_selected_blue.dds",
    }
    function ZO_VeterancyRankPerkRewardData:GetHighlightTexture()
        return VETERANCY_BORDER_SELECTED_TEXTURE[self.slotFlags]
    end
end

function ZO_VeterancyRankPerkRewardData:IsRewardClaimed()
    return false
end

function ZO_VeterancyRankPerkRewardData:CanClaimReward()
    return false
end

function ZO_VeterancyRankPerkRewardData:TryClaimReward()
    -- Do Nothing, Perks are auto-granted
end

function ZO_VeterancyRankPerkRewardData:CanPreviewReward()
    return false
end

function ZO_VeterancyRankPerkRewardData:GetRankData()
    return self.rankData
end

function ZO_VeterancyRankPerkRewardData:GetRewardData()
    local rewardData = self.rewardData
    if not rewardData then
        if self.rewardId ~= 0 then
            rewardData = ZO_VeterancyRankPerkRewardData.GetPerkRewardEntryInfo(self.perkId, self)
            self.rewardData = rewardData
        end
    end
    return rewardData
end

function ZO_VeterancyRankPerkRewardData.GetPerkRewardEntryInfo(perkId, veterancyRankPerkRewardData)
    local icon = GetVengeancePerkIcon(perkId)
    local displayName = GetVengeancePerkName(perkId)
    local formattedDisplayName = zo_strformat(SI_TOOLTIP_ITEM_NAME, displayName)

    local rewardData = ZO_VeterancyPerkData:New(perkId)
    rewardData:SetRawName(displayName)
    rewardData:SetFormattedName(formattedDisplayName)
    rewardData:SetIcon(icon)
    rewardData:SetVeterancyRankPerkRewardData(veterancyRankPerkRewardData)

    return rewardData
end

--------------------------------------
-- Veterancy Reward List Reward Data
--------------------------------------

ZO_VeterancyRewardListRewardData = ZO_PreviewableRewardData:Subclass()

function ZO_VeterancyRewardListRewardData:Initialize(rewardData)
    self.rewardData = rewardData
end

function ZO_VeterancyRewardListRewardData:GetRewardId()
    return self.rewardData:GetRewardId()
end

function ZO_VeterancyRewardListRewardData:CanPreviewReward()
    return CanPreviewReward(self:GetRewardId())
end