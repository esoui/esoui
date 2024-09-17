ZO_FEATURED_PRESENTATION_INDEX = nil
ZO_INVALID_PRESENTATION_INDEX = -1

ZO_MARKET_PREVIEW_TYPE_PREVIEWABLE = 0
ZO_MARKET_PREVIEW_TYPE_BUNDLE = 1
ZO_MARKET_PREVIEW_TYPE_CROWN_CRATE = 2
ZO_MARKET_PREVIEW_TYPE_BUNDLE_AS_LIST = 3
ZO_MARKET_PREVIEW_TYPE_HOUSE = 4

--
--[[ ZO_MarketProductData ]]--
--

ZO_MarketProductData = ZO_Object:Subclass()

function ZO_MarketProductData:New(...)
    local marketProduct = ZO_Object.New(self)
    marketProduct:Initialize(...)
    return marketProduct
end

function ZO_MarketProductData:Initialize(marketProductId, presentationIndex)
    self.marketProductId = marketProductId
    self.presentationIndex = presentationIndex
end

function ZO_MarketProductData:GetId()
    return self.marketProductId
end

function ZO_MarketProductData:SetId(marketProductId)
    self.marketProductId = marketProductId
end

function ZO_MarketProductData:SetPresentationIndex(presentationIndex)
    self.presentationIndex = presentationIndex
end

function ZO_MarketProductData:GetPresentationIndex()
    return self.presentationIndex
end

function ZO_MarketProductData:HasValidPresentationIndex()
    return self.presentationIndex ~= ZO_INVALID_PRESENTATION_INDEX
end

function ZO_MarketProductData:GetMarketProductInfo()
    return GetMarketProductInfo(self.marketProductId)
end

function ZO_MarketProductData:GetDisplayName()
    return GetMarketProductDisplayName(self.marketProductId)
end

function ZO_MarketProductData:GetMarketProductDescription()
    return GetMarketProductDescription(self.marketProductId)
end

function ZO_MarketProductData:GetIcon()
    return GetMarketProductIcon(self.marketProductId)
end

function ZO_MarketProductData:GetMarketProductPricingByPresentation()
    return GetMarketProductPricingByPresentation(self.marketProductId, self.presentationIndex)
end

function ZO_MarketProductData:GetMarketProductType()
    return GetMarketProductType(self.marketProductId)
end

function ZO_MarketProductData:GetNumChildren()
    return GetMarketProductNumChildren(self.marketProductId)
end

function ZO_MarketProductData:GetChildMarketProductId(childIndex)
    return GetMarketProductChildId(self.marketProductId, childIndex)
end

function ZO_MarketProductData:GetNumFacadeChildren()
    return GetMarketProductNumFacadeChildren(self.marketProductId)
end

function ZO_MarketProductData:GetFacadeChildMarketProductId(childIndex)
    return GetMarketProductFacadeChildId(self.marketProductId, childIndex)
end

function ZO_MarketProductData:GetNumBundledProducts()
    return GetMarketProductNumBundledProducts(self.marketProductId)
end

function ZO_MarketProductData:GetNumAttachedCollectibles()
    return GetMarketProductNumCollectibles(self.marketProductId)
end

function ZO_MarketProductData:GetStackCount()
    return GetMarketProductStackCount(self.marketProductId)
end

function ZO_MarketProductData:GetDisplayQuality()
    return GetMarketProductDisplayQuality(self.marketProductId)
end

function ZO_MarketProductData:GetColorizedDisplayName()
    local color = GetItemQualityColor(self:GetDisplayQuality())
    return color:Colorize(self:GetDisplayName())
end

function ZO_MarketProductData:GetMaxGiftQuantity()
    local maxQuantity = GetMarketProductMaxGiftQuantity(self.marketProductId)
    return maxQuantity
end

function ZO_MarketProductData:IsGiftQuantityValid(giftQuantity)
    local quantity = tonumber(giftQuantity)
    if not quantity or quantity < 1 or quantity ~= math.floor(quantity) then
        return false, MARKET_PURCHASE_RESULT_INVALID_QUANTITY
    end

    local maxQuantity = self:GetMaxGiftQuantity()
    if maxQuantity and maxQuantity < quantity then
        return false, MARKET_PURCHASE_RESULT_EXCEEDS_MAX_QUANTITY
    end

    return true, MARKET_PURCHASE_RESULT_SUCCESS
end

function ZO_MarketProductData:GetMaxPurchaseQuantity()
    local maxQuantity = GetMarketProductMaxPurchaseQuantity(self.marketProductId)
    return maxQuantity
end

function ZO_MarketProductData:IsPurchaseQuantityValid(purchaseQuantity)
    local quantity = tonumber(purchaseQuantity)
    if not quantity or quantity < 1 or quantity ~= math.floor(quantity) then
        return false, MARKET_PURCHASE_RESULT_INVALID_QUANTITY
    end

    local maxQuantity = self:GetMaxPurchaseQuantity()
    if maxQuantity and maxQuantity < quantity then
        return false, MARKET_PURCHASE_RESULT_EXCEEDS_MAX_QUANTITY
    end

    return true, MARKET_PURCHASE_RESULT_SUCCESS
end

function ZO_MarketProductData:GetInspectChildProductsAsList()
    if self:IsBundle() then
        return GetMarketProductBundleInspectChildProductsAsList(self.marketProductId)
    end

    return false
end

function ZO_MarketProductData:IsNew()
    return IsMarketProductNew(self.marketProductId)
end

function ZO_MarketProductData:IsFeatured()
    return IsMarketProductFeatured(self.marketProductId)
end

function ZO_MarketProductData:IsGiftable()
    if self:HasValidPresentationIndex() then
        return IsMarketProductGiftable(self.marketProductId, self.presentationIndex)
    else
        return false
    end
end

function ZO_MarketProductData:GetLTOTimeLeftInSeconds()
    return GetMarketProductLTOTimeLeftInSeconds(self.marketProductId)
end

function ZO_MarketProductData:GetSaleTimeLeftInSeconds()
    return GetMarketProductSaleTimeLeftInSeconds(self.marketProductId)
end

function ZO_MarketProductData:GetMarketProductDisplayState()
    return ZO_GetMarketProductDisplayState(self.marketProductId)
end

function ZO_MarketProductData:IsPurchaseLocked()
    return self:GetMarketProductDisplayState() ~= MARKET_PRODUCT_DISPLAY_STATE_NOT_PURCHASED
end

function ZO_MarketProductData:CanBePurchased()
    return not (self:IsPurchaseLocked() or self:IsPromo())
end

function ZO_MarketProductData:HasActivationRequirement()
    return DoesMarketProductHaveActivationRequirement(self.marketProductId)
end

function ZO_MarketProductData:IsBundle()
    return GetMarketProductType(self.marketProductId) == MARKET_PRODUCT_TYPE_BUNDLE
end

function ZO_MarketProductData:IsPromo()
    return GetMarketProductType(self.marketProductId) == MARKET_PRODUCT_TYPE_PROMO
end

function ZO_MarketProductData:IsHouseCollectible()
    return ZO_MarketProduct_IsHouseCollectible(self.marketProductId)
end

function ZO_MarketProductData:HasBeenPartiallyPurchased()
    return IsMarketProductPartiallyPurchased(self.marketProductId)
end

function ZO_MarketProductData:HasSubscriptionUnlockedAttachments()
    return DoesMarketProductHaveSubscriptionUnlockedAttachments(self.marketProductId)
end

function ZO_MarketProductData:GetNumPreviewVariations()
    return GetNumMarketProductPreviewVariations(self.marketProductId)
end

function ZO_MarketProductData:GetCrownCrateId()
    return GetMarketProductCrownCrateId(self.marketProductId)
end

function ZO_MarketProductData:GetFurnitureDataId()
    return GetMarketProductFurnitureDataId(self.marketProductId)
end

function ZO_MarketProductData:GetHouseId()
    return GetMarketProductHouseId(self.marketProductId)
end

function ZO_MarketProductData:GetInstantUnlockType()
    return GetMarketProductInstantUnlockType(self.marketProductId)
end

function ZO_MarketProductData:ContainsDLC()
    return DoesMarketProductContainDLC(self.marketProductId)
end

function ZO_MarketProductData:ContainsConsumables()
    return DoesMarketProductContainConsumables(self.marketProductId)
end

function ZO_MarketProductData:ContainsServiceToken()
    return DoesMarketProductContainServiceToken(self.marketProductId)
end

function ZO_MarketProductData:GetSpaceNeededToAcquire()
    return GetSpaceNeededToAcquireMarketProduct(self.marketProductId)
end

function ZO_MarketProductData:AreAllCollectiblesUnlocked()
    local productType = self:GetMarketProductType()
    if productType == MARKET_PRODUCT_TYPE_COLLECTIBLE then
        local owned = select(6, GetMarketProductCollectibleInfo(self.marketProductId))
        return owned
    elseif productType == MARKET_PRODUCT_TYPE_BUNDLE then
        -- Show bundles that have all their collectibles unlocked as collected
        return CouldAcquireMarketProduct(self.marketProductId) == MARKET_PURCHASE_RESULT_COLLECTIBLE_ALREADY
    end

    return false
end

function ZO_MarketProductData:IsLimitedTimeProduct()
    local remainingTime = self:GetLTOTimeLeftInSeconds()
    -- durations longer than 1 month aren't represented to the user, so it's effectively not limited time
    return remainingTime > 0 and remainingTime <= ZO_ONE_MONTH_IN_SECONDS
end

function ZO_MarketProductData:IsLimitedSaleTimeProduct()
    local remainingTime = self:GetSaleTimeLeftInSeconds()
    -- durations longer than 1 month aren't represented to the user, so it's effectively not limited time
    return remainingTime > 0 and remainingTime <= ZO_ONE_MONTH_IN_SECONDS
end

function ZO_MarketProductData:IsDeprioritizeInAnnouncements()
    return IsDeprioritizedInAnnouncements(self.marketProductId)
end

function ZO_MarketProductData:GetAnnounceSortOrder()
    return GetMarketProductAnnounceSortOrder(self.marketProductId)
end

function ZO_MarketProductData:GetEndTimeString()
    return GetMarketProductEndTimeString(self.marketProductId)
end

function ZO_MarketProductData:CouldPurchase(quantity)
    return CouldPurchaseMarketProduct(self.marketProductId, self.presentationIndex, quantity)
end

function ZO_MarketProductData:CouldGift(quantity)
    return CouldGiftMarketProduct(self.marketProductId, self.presentationIndex, quantity)
end

function ZO_MarketProductData:RequestPurchase(quantity)
    local purchaseQuantity = quantity or 1
    BuyMarketProduct(self.marketProductId, self.presentationIndex, purchaseQuantity)
end

function ZO_MarketProductData:RequestPurchaseAsGift(giftMessage, recipientDisplayName, quantity)
    local purchaseQuantity = quantity or 1
    GiftMarketProduct(self.marketProductId, self.presentationIndex, purchaseQuantity, giftMessage, recipientDisplayName)
end

function ZO_MarketProductData:GetMarketProductPreviewType()
    if self:IsBundle() then
        if self:GetInspectChildProductsAsList() then
            return ZO_MARKET_PREVIEW_TYPE_BUNDLE_AS_LIST
        else
            return ZO_MARKET_PREVIEW_TYPE_BUNDLE
        end
    else
        local productType = self:GetMarketProductType()
        if productType == MARKET_PRODUCT_TYPE_CROWN_CRATE then
            return ZO_MARKET_PREVIEW_TYPE_CROWN_CRATE
        elseif self:IsHouseCollectible() and self:GetMarketProductDisplayState() == MARKET_PRODUCT_DISPLAY_STATE_NOT_PURCHASED then
            return ZO_MARKET_PREVIEW_TYPE_HOUSE
        else
            return ZO_MARKET_PREVIEW_TYPE_PREVIEWABLE
        end
    end
end

function ZO_MarketProductData:PassesPurchasableReqList()
    return DoesMarketProductPassPurchasableReqList(self.marketProductId)
end

function ZO_MarketProductData:GetCategoryIndicesFromPresentation()
    return GetCategoryIndicesFromMarketProductPresentation(self.marketProductId, self.presentationIndex)
end
