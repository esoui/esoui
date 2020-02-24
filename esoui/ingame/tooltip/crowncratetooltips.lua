do
    local DEPRECATED_ARG = nil
    local HIDE_PURCHASABLE = false
    local HIDE_HINT = nil

    function ZO_Tooltip:LayoutCrownCrateReward(rewardIndex)
        local rewardProductType, rewardReferenceDataId = GetCrownCrateRewardProductReferenceData(rewardIndex)

        if rewardProductType == MARKET_PRODUCT_TYPE_COLLECTIBLE then
            local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(rewardReferenceDataId)
            self:LayoutCollectible(collectibleData:GetId(), DEPRECATED_ARG, collectibleData:GetName(), collectibleData:GetNickname(), HIDE_PURCHASABLE, collectibleData:GetDescription(), HIDE_HINT, DEPRECATED_ARG, collectibleData:GetCategoryType())
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
end