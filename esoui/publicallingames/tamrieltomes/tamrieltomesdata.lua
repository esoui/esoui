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

function ZO_TamrielTomesRewardData:Equals(rewardTrackIdOrData, rewardTrackTier, rewardTrackComponent, rewardIndex)
    if type(rewardTrackIdOrData) == "table" then
        local data = rewardTrackIdOrData
        if not data:IsInstanceOf(ZO_TamrielTomesRewardData) then
            return false
        end

        rewardTrackIdOrData = data:GetRewardTrackId()
        rewardTrackTier = data:GetTierIndex()
        rewardTrackComponent = data:GetRewardComponent()
        rewardIndex = data:GetRewardIndex()
    end

    return self:GetRewardTrackId() == rewardTrackIdOrData and self:GetTierIndex() == rewardTrackTier and self:GetRewardComponent() == rewardTrackComponent and self:GetRewardIndex() == rewardIndex
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

function ZO_TamrielTomesRewardData:GetPlatformLootIcon()
    local rewardData = self:GetRewardListRewardDataByIndex(1)
    if not rewardData then
        rewardData = self:GetRewardData()
    end

    if rewardData then
        return rewardData:GetPlatformLootIcon()
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

function ZO_TamrielTomesRewardData:HasAccessToComponent()
    return self.hasAccessToComponent
end

function ZO_TamrielTomesRewardData:HasAccessToReward()
    return self.hasAccessToReward
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

function ZO_TamrielTomesRewardData:CanAffordReward()
    return GetPlayerStoredCurrencyAmount(CURT_TOME_POINTS) >= self:GetRewardCost()
end

function ZO_TamrielTomesRewardData:CanClaimReward()
    return self:IsRewardInfinitelyRepeatable() or not (self:IsLocked() or self:IsRewardClaimed())
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

function ZO_TamrielTomesRewardData:CanQuickPreviewReward()
    return CanPreviewReward(self:GetRewardId()) and not self:IsRewardList()
end

function ZO_TamrielTomesRewardData:IsLocked()
    return not (self.hasAccessToComponent and self.hasAccessToReward)
end

function ZO_TamrielTomesRewardData:Update()
    local tomeIndex = self:GetTamrielTomeIndex()
    local tierIndex = self:GetTierIndex()
    local component = self:GetRewardComponent()
    local rewardIndex = self:GetRewardIndex()
    self.isClaimed, self.isFallback, self.isInfinitelyRepeatable = GetRewardTrackRewardClaimedState(REWARD_TRACK_TYPE_TAMRIEL_TOMES, tomeIndex, tierIndex, component, rewardIndex)
    self.hasAccessToComponent = HasAccessToRewardTrackComponent(REWARD_TRACK_TYPE_TAMRIEL_TOMES, tomeIndex, component)

    local _, currentTier, progressToNextTier = GetInfoForRewardTrack(REWARD_TRACK_TYPE_TAMRIEL_TOMES, tomeIndex)
    self.hasAccessToReward = currentTier >= tierIndex
end


-- Tamriel Tome Data --

ZO_TamrielTomeData = ZO_InitializingObject:Subclass()

function ZO_TamrielTomeData:Initialize(tamrielTomeId)
    self.tamrielTomeId = tamrielTomeId
    self.tamrielTomeIndex = GetReferenceTrackIndex(REWARD_TRACK_TYPE_TAMRIEL_TOMES, tamrielTomeId)
    self.rewardTrackId = GetRewardTrackIdFromReferenceTrackId(REWARD_TRACK_TYPE_TAMRIEL_TOMES, tamrielTomeId)
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
    local _, currentTier = GetInfoForRewardTrack(REWARD_TRACK_TYPE_TAMRIEL_TOMES, self.tamrielTomeIndex)
    return currentTier
end

function ZO_TamrielTomeData:GetNextTier()
    local currentTier = self:GetCurrentTier()
    local nextTier = currentTier + 1
    if nextTier <= self:GetNumTotalTiers() then
        return nextTier
    end
    return 0
end

function ZO_TamrielTomeData:GetNumBaseTiers()
    return GetNumBaseTiersForRewardTrack(self.rewardTrackId)
end

function ZO_TamrielTomeData:GetNumBonusTiers()
    return GetNumBonusTiersForRewardTrack(self.rewardTrackId)
end

function ZO_TamrielTomeData:GetNumTotalTiers()
    return GetTotalNumTiersForRewardTrack(self.rewardTrackId)
end

function ZO_TamrielTomeData:GetCostToProgressToTier(tier)
    local currentTier = self:GetCurrentTier()
    if tier <= currentTier then
        -- The requested tier has already been unlocked.
        return 0
    end

    if tier > self:GetNumTotalTiers() then
        -- The requested tier does not exist.
        return 0
    end

    -- Calculate the cost to progress to the next tier.
    local progressToNextTier = self:GetProgressToNextTier()
    local totalCostToProgress = -progressToNextTier

    -- Add the cost to progress to any subsequent tier(s) between the next tier and the requested tier.
    local maxTier = zo_max(currentTier, tier - 1)
    for nextTier = currentTier, maxTier do
        totalCostToProgress = totalCostToProgress + GetCostToProgressToNextTier(self.rewardTrackId, nextTier)
    end

    return totalCostToProgress
end

function ZO_TamrielTomeData:GetCostToProgressToNextTier()
    return self:GetCostToProgressToTier(self.rewardTrackId, self:GetCurrentTier() + 1)
end

function ZO_TamrielTomeData:GetProgressToNextTier()
    local _, _, progressToNextTier = GetInfoForRewardTrack(REWARD_TRACK_TYPE_TAMRIEL_TOMES, self.tamrielTomeIndex)
    return progressToNextTier
end

function ZO_TamrielTomeData:GetEndTime()
    local _, _, _, endTime = GetInfoForRewardTrack(REWARD_TRACK_TYPE_TAMRIEL_TOMES, self.tamrielTomeIndex)
    return endTime
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

function ZO_TamrielTomeData.GetRewardStatisticsForTamrielTome(tamrielTomeId)
    local tomeIndex = GetReferenceTrackIndex(REWARD_TRACK_TYPE_TAMRIEL_TOMES, tamrielTomeId)
    local rewardTrackId = GetRewardTrackIdFromReferenceTrackId(REWARD_TRACK_TYPE_TAMRIEL_TOMES, tamrielTomeId)
    local numTiers = GetTotalNumTiersForRewardTrack(rewardTrackId)
    local numClaimedRewards = 0
    local numRewards = 0

    for rewardComponent = REWARD_TRACK_COMPONENT_ITERATION_BEGIN, REWARD_TRACK_COMPONENT_ITERATION_END do
        for rewardTier = 1, numTiers do
            local numTierComponentRewards = GetNumRewardsAtRewardTrackTier(rewardTrackId, rewardTier, rewardComponent)
            numRewards = numRewards + numTierComponentRewards

            for rewardIndex = 1, numTierComponentRewards do
                local isClaimed = GetRewardTrackRewardClaimedState(REWARD_TRACK_TYPE_TAMRIEL_TOMES, tomeIndex, rewardTier, rewardComponent, rewardIndex)
                if isClaimed then
                    numClaimedRewards = numClaimedRewards + 1
                end
            end
        end
    end

    return numClaimedRewards, numRewards
end

function ZO_TamrielTomeData:UpdateRewardStatisticsInternal()
    local tamrielTomeId = self:GetTamrielTomeId()
    self.numClaimedRewards, self.numRewards = self.GetRewardStatisticsForTamrielTome(tamrielTomeId)
end

function ZO_TamrielTomeData:GetNumRewards()
    if not self.numRewards then
        self:UpdateRewardStatisticsInternal()
    end

    return self.numRewards
end

function ZO_TamrielTomeData:GetNumClaimedRewards()
    if not self.numClaimedRewards then
        self:UpdateRewardStatisticsInternal()
    end

    return self.numClaimedRewards
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

function ZO_TamrielTomeData:HasAccessToComponent(component)
    return HasAccessToRewardTrackComponent(REWARD_TRACK_TYPE_TAMRIEL_TOMES, self.tamrielTomeIndex, component)
end

function ZO_TamrielTomeData:Update()
    self:UpdateRewardStatisticsInternal()
end


-- SKU Data

ZO_DirectPurchaseSkuData = ZO_InitializingObject:Subclass()

function ZO_DirectPurchaseSkuData:Initialize(skuId)
    self.skuId = skuId
end

function ZO_DirectPurchaseSkuData:GetSkuId()
    return self.skuId
end

function ZO_DirectPurchaseSkuData:GetDisplayName()
    return GetSkuDisplayName(self.skuId)
end

function ZO_DirectPurchaseSkuData:IsAvailableForPurchase()
    return IsSkuAvailableForPurchase(self.skuId)
end

function ZO_DirectPurchaseSkuData:GetPricingInfo()
    local currentPrice, basePrice, currency = GetSkuPricingInfo(self.skuId)
    return currentPrice, basePrice, currency
end

-- The prices returned have been processed by grammar.
function ZO_DirectPurchaseSkuData:GetPricingInfoFormatted()
    local currentPriceString, basePriceString = GetSkuPricingInfoFormatted(self.skuId)
    return currentPriceString, basePriceString
end

-- The price(s) returned have been processed by grammar.
function ZO_DirectPurchaseSkuData:GetPricingStringFormatted()
    local currentPriceString, basePriceString = self:GetPricingInfoFormatted()
    if currentPriceString == basePriceString then
        return currentPriceString
    end

    return string.format("|DS%s|ds %s", basePriceString, currentPriceString)
end

function ZO_DirectPurchaseSkuData:GetPricingInfoWithTax()
    if GetSkuPricingInfoWithTax then
        local currentPrice, basePrice, taxPrice, totalPrice, currency, isVatIncluded = GetSkuPricingInfoWithTax(self.skuId)
        return currentPrice, basePrice, taxPrice, totalPrice, currency, isVatIncluded
    end
    return nil
end

function ZO_DirectPurchaseSkuData:GetPricingInfoWithTaxFormatted()
    if GetSkuPricingInfoWithTaxFormatted then
        local currentPriceString, basePriceString, taxPriceString, totalPriceString, isVatIncluded = GetSkuPricingInfoWithTaxFormatted(self.skuId)
        return currentPriceString, basePriceString, taxPriceString, totalPriceString, isVatIncluded
    end
    return nil
end

function ZO_DirectPurchaseSkuData:RequestPurchase()
    DIRECT_PURCHASE_MANAGER:RequestPurchase(self.skuId)
end

function ZO_DirectPurchaseSkuData:ConfirmPurchase()
    local purchaseRequestId = ConfirmPurchaseSku and ConfirmPurchaseSku(self.skuId) or 0
    return purchaseRequestId ~= 0
end


-- Tamriel Tome Direct Purchase Data

ZO_TamrielTomeDirectPurchaseData = ZO_InitializingObject:Subclass()

function ZO_TamrielTomeDirectPurchaseData:Initialize(tomeId, productType)
    self.tomeId = tomeId
    self.productType = productType

    self:Update()
end

function ZO_TamrielTomeDirectPurchaseData:GetTomeId()
    return self.tomeId
end

function ZO_TamrielTomeDirectPurchaseData:GetProductType()
    return self.productType
end

function ZO_TamrielTomeDirectPurchaseData:GetSkuData()
    return self.skuData
end

function ZO_TamrielTomeDirectPurchaseData:Update()
    local skuId = GetTamrielTomeSkuId(self.tomeId, self.productType)
    if not self.skuData or self.skuData:GetSkuId() ~= skuId then
        self.skuData = ZO_DirectPurchaseSkuData:New(skuId)
    end
end

function ZO_TamrielTomeDirectPurchaseData:IsAvailableForPurchase()
    return self.skuData:IsAvailableForPurchase()
end

function ZO_TamrielTomeDirectPurchaseData:IsOwned()
    return HasTamrielTomeProductType(self.tomeId, self.productType)
end

function ZO_TamrielTomeDirectPurchaseData:CanPurchase()
    return not self:IsOwned() and self:IsAvailableForPurchase()
end