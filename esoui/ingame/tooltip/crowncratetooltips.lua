function ZO_Tooltip:LayoutCrownCrateReward(rewardIndex)
    local rewardProductType, rewardReferenceDataId = GetCrownCrateRewardProductReferenceData(rewardIndex)

    if rewardProductType == MARKET_PRODUCT_TYPE_COLLECTIBLE then
        local params =
        {
            collectibleId = rewardReferenceDataId,
            showNickname = true,
        }
        self:LayoutCollectibleWithParams(params)
    elseif rewardProductType == MARKET_PRODUCT_TYPE_ITEM then
        local itemLink = GetCrownCrateRewardItemLink(rewardIndex)
        if itemLink and itemLink ~= "" then
            self:LayoutItem(itemLink)
        end
    elseif rewardProductType == MARKET_PRODUCT_TYPE_CURRENCY then
        local stackCount = GetCrownCrateRewardStackCount(rewardIndex)
        self:LayoutCurrency(rewardReferenceDataId, stackCount)
    else
        internalassert(false, "Unsupported crown crate reward type")
    end
end