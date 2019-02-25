ZO_FEATURED_PRESENTATION_INDEX = nil
ZO_INVALID_PRESENTATION_INDEX = -1

ZO_MARKET_PREVIEW_TYPE_PREVIEWABLE = 0
ZO_MARKET_PREVIEW_TYPE_BUNDLE = 1
ZO_MARKET_PREVIEW_TYPE_CROWN_CRATE = 2
ZO_MARKET_PREVIEW_TYPE_BUNDLE_HIDES_CHILDREN = 3
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

function ZO_MarketProductData:GetNumBundledProducts()
    return GetMarketProductNumBundledProducts(self.marketProductId)
end

function ZO_MarketProductData:GetNumAttachedCollectibles()
    return GetMarketProductNumCollectibles(self.marketProductId)
end

function ZO_MarketProductData:GetStackCount()
    return GetMarketProductStackCount(self.marketProductId)
end

function ZO_MarketProductData:GetQuality()
    return GetMarketProductQuality(self.marketProductId)
end

function ZO_MarketProductData:GetColorizedDisplayName()
    local color = GetItemQualityColor(self:GetQuality())
    return color:Colorize(self:GetDisplayName())
end

function ZO_MarketProductData:GetHidesChildProducts()
    if self:IsBundle() then
        return GetMarketProductBundleHidesChildProducts(self.marketProductId)
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

function ZO_MarketProductData:GetPurchaseState()
    return GetMarketProductPurchaseState(self.marketProductId)
end

function ZO_MarketProductData:IsPurchaseLocked()
    return self:GetPurchaseState() ~= MARKET_PRODUCT_PURCHASE_STATE_NOT_PURCHASED
end

function ZO_MarketProductData:CanBePurchased()
    return not (self:IsPurchaseLocked() or self:IsHouseCollectible() or self:IsPromo())
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

function ZO_MarketProductData:GetEndTimeString()
    return GetMarketProductEndTimeString(self.marketProductId)
end

function ZO_MarketProductData:CouldPurchase()
    return CouldPurchaseMarketProduct(self.marketProductId, self.presentationIndex)
end

function ZO_MarketProductData:CouldGift()
    return CouldGiftMarketProduct(self.marketProductId, self.presentationIndex)
end

function ZO_MarketProductData:RequestPurchase()
    BuyMarketProduct(self.marketProductId, self.presentationIndex)
end

function ZO_MarketProductData:RequestPurchaseAsGift(giftMessage, recipientDisplayName)
    GiftMarketProduct(self.marketProductId, self.presentationIndex, giftMessage, recipientDisplayName)
end

function ZO_MarketProductData:GetMarketProductPreviewType()
    if self:IsBundle() then
        if self:GetHidesChildProducts() then
            return ZO_MARKET_PREVIEW_TYPE_BUNDLE_HIDES_CHILDREN
        else
            return ZO_MARKET_PREVIEW_TYPE_BUNDLE
        end
    else
        local productType = self:GetMarketProductType()
        if productType == MARKET_PRODUCT_TYPE_CROWN_CRATE then
            return ZO_MARKET_PREVIEW_TYPE_CROWN_CRATE
        elseif self:IsHouseCollectible() and self:GetPurchaseState() == MARKET_PRODUCT_PURCHASE_STATE_NOT_PURCHASED then
            return ZO_MARKET_PREVIEW_TYPE_HOUSE
        else
            return ZO_MARKET_PREVIEW_TYPE_PREVIEWABLE
        end
    end
end
