-----------------
-- Data Object --
-----------------

ZO_CHAPTER_UPGRADE_REWARD_TYPE =
{
    PRE_PURCHASE = 1,
    BASIC = 2,
    PRE_ORDER = 3,
}

ZO_ChapterUpgrade_Data = ZO_Object:Subclass()

function ZO_ChapterUpgrade_Data:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_ChapterUpgrade_Data:Initialize(chapterUpgradeId)
    local _
    self.chapterUpgradeId = chapterUpgradeId
    self.marketProductId = 0
    self.collectibleId = GetChapterCollectibleId(chapterUpgradeId)
    self.name, _, self.collectibleIcon = GetCollectibleInfo(self.collectibleId)
    self.summary = GetChapterSummary(chapterUpgradeId)
    self.isPreRelease = IsChapterPreRelease(chapterUpgradeId)
    if self.isPreRelease then
        self.releaseDateString = GetChapterReleaseDateString(chapterUpgradeId)
    end
    self.marketBackgroundImage = GetChapterMarketBackgroundFileImage(chapterUpgradeId)
    self.isOwned = IsChapterOwned(chapterUpgradeId)
    self.isNew = false
    self.hasDiscount = false
    self.discountPercent = 0
    self:PopulateRewardsData()
end

do
    local function RewardEntryComparator(leftData, rightData)
        if leftData.isStandardReward == rightData.isStandardReward and leftData.isCollectorsReward == rightData.isCollectorsReward then
            if leftData.rewardType == rightData.rewardType then
                --Fall back to def order
                return leftData.index < rightData.index
            else
                --Secondary ordering is reward type, basic comes before preorder
                return leftData.rewardType < rightData.rewardType
            end
        else
            -- Primary ordering is what edition the reward can be found in
            if (leftData.isStandardReward and leftData.isCollectorsReward) or not (rightData.isStandardReward or rightData.isCollectorsReward) then
                --If both editions are checked: first; If neither edition is checked: last
                return true
            elseif rightData.isStandardReward and rightData.isCollectorsReward then
                --If both editions are checked: first
                return false
            else
                --One has standard, the other has collector's, and collector's comes first
                return leftData.isCollectorsReward
            end
        end
    end

    local function AddRewardsData(rewardsTable, chapterUpgradeId, numRewardsFunction, rewardInfoFunction, rewardType)
        for i = 1, numRewardsFunction(chapterUpgradeId) do
            local marketProductId, isStandardReward, isCollectorsReward = rewardInfoFunction(chapterUpgradeId, i)
            local data =
            {
                index = i,
                marketProductId = marketProductId,
                displayName = zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, GetMarketProductDisplayName(marketProductId)),
                icon = GetMarketProductIcon(marketProductId),
                isStandardReward = isStandardReward,
                isCollectorsReward = isCollectorsReward,
                rewardType = rewardType,
            }
            table.insert(rewardsTable, data)
        end

        table.sort(rewardsTable, RewardEntryComparator)
    end

    function ZO_ChapterUpgrade_Data:PopulateRewardsData()
        self.prePurchaseRewards = {}
        AddRewardsData(self.prePurchaseRewards, self.chapterUpgradeId, GetNumChapterPrePurchaseRewards, GetChapterPrePurchaseRewardInfo, ZO_CHAPTER_UPGRADE_REWARD_TYPE.PRE_PURCHASE)

        self.preOrderRewards = {}
        AddRewardsData(self.preOrderRewards, self.chapterUpgradeId, GetNumChapterPreOrderRewards, GetChapterPreOrdereRewardInfo, ZO_CHAPTER_UPGRADE_REWARD_TYPE.PRE_ORDER)

        self.basicRewards = {}
        AddRewardsData(self.basicRewards, self.chapterUpgradeId, GetNumChapterBasicRewards, GetChapterBasicRewardInfo, ZO_CHAPTER_UPGRADE_REWARD_TYPE.BASIC)

        if self.isPreRelease then
            self.editionRewards = {}
            ZO_CombineNumericallyIndexedTables(self.editionRewards, self.basicRewards, self.preOrderRewards)
            table.sort(self.editionRewards, RewardEntryComparator)
        else
            self.editionRewards = self.basicRewards
        end
    end
end

function ZO_ChapterUpgrade_Data:SetMarketProductId(marketProductId)
    self.marketProductId = marketProductId
    self.isNew = select(4, GetMarketProductInfo(marketProductId))
    local _
    self.hasDiscount, _, self.discountPercent = select(3, GetMarketProductPricingByPresentation(self.marketProductId))
end

function ZO_ChapterUpgrade_Data:GetChapterUpgradeId()
    return self.chapterUpgradeId
end

function ZO_ChapterUpgrade_Data:GetName()
    return self.name
end

function ZO_ChapterUpgrade_Data:GetFormattedName()
    return ZO_CachedStrFormat(SI_COLLECTIBLE_NAME_FORMATTER, self.name)
end

function ZO_ChapterUpgrade_Data:GetCollectibleIcon()
    return self.collectibleIcon
end

function ZO_ChapterUpgrade_Data:GetCollectibleId()
    return self.collectibleId
end

function ZO_ChapterUpgrade_Data:GetSummary()
    return self.summary
end

function ZO_ChapterUpgrade_Data:IsPreRelease()
    return self.isPreRelease
end

function ZO_ChapterUpgrade_Data:GetReleaseDateText()
    return self.releaseDateString
end

function ZO_ChapterUpgrade_Data:GetMarketBackgroundImage()
    return self.marketBackgroundImage
end

function ZO_ChapterUpgrade_Data:IsOwned()
    return self.isOwned
end

function ZO_ChapterUpgrade_Data:GetPurchasedState()
    if self.isOwned then
        return CHAPTER_PURCHASE_STATE_PURCHASED
    elseif self.isPreRelease then
        return CHAPTER_PURCHASE_STATE_PRE_PURCHASE
    else
        return CHAPTER_PURCHASE_STATE_UPGRADE
    end
end

function ZO_ChapterUpgrade_Data:HasMarketProductData()
    return self.marketProductId ~= 0
end

function ZO_ChapterUpgrade_Data:GetLTOTimeLeftInSeconds()
    if self:HasMarketProductData() then
        return GetMarketProductLTOTimeLeftInSeconds(self.marketProductId)
    end
    return 0
end

function ZO_ChapterUpgrade_Data:IsLimitedTime()
    local remainingTime = self:GetLTOTimeLeftInSeconds()
    return remainingTime > 0 and remainingTime <= ZO_ONE_MONTH_IN_SECONDS
end

function ZO_ChapterUpgrade_Data:GetDiscountInfo()
    return self.hasDiscount, self.discountPercent
end

function ZO_ChapterUpgrade_Data:IsNew()
    return self.isNew
end

function ZO_ChapterUpgrade_Data:GetPrePurchaseRewards()
    return self.prePurchaseRewards
end

function ZO_ChapterUpgrade_Data:GetPreOrderRewards()
    return self.preOrderRewards
end

function ZO_ChapterUpgrade_Data:GetBasicRewards()
    return self.basicRewards
end

function ZO_ChapterUpgrade_Data:GetEditionRewards()
    return self.editionRewards
end

-------------
-- Manager --
-------------

local ChapterUpgrade_Manager = ZO_CallbackObject:Subclass()

function ChapterUpgrade_Manager:New(...)
    local manager = ZO_CallbackObject.New(self)
    manager:Initialize(...)
    return manager
end

function ChapterUpgrade_Manager:Initialize()
    local currentChapterId = GetCurrentChapterUpgradeId()
    self.currentChapterData = ZO_ChapterUpgrade_Data:New(currentChapterId)
    self.chapterUpgradeDataById =
    {
        [currentChapterId] = self.currentChapterData,
    }

    local function OnMarketStateUpdated(eventCode, displayGroup, marketState)
        if displayGroup == MARKET_DISPLAY_GROUP_CHAPTER_UPGRADE then
            self:RefreshChapterUpgradeData()
        end
    end

    EVENT_MANAGER:RegisterForEvent("ChapterUpgrade_Manager", EVENT_MARKET_STATE_UPDATED, OnMarketStateUpdated)
end

function ChapterUpgrade_Manager:RefreshChapterUpgradeData()
    ZO_ClearTable(self.chapterUpgradeDataById)

    self.chapterUpgradeDataById[self.currentChapterData:GetChapterUpgradeId()] = self.currentChapterData --static data
    
    local prepurchaseChapterId, marketProductId = self:GetPrepurchaseChapterUpgradeInfo()
    if prepurchaseChapterId ~= 0 then
        local prepurchaseChapterData = self.prepurchaseChapterData
        if prepurchaseChapterData then
            if prepurchaseChapterData:GetChapterUpgradeId() ~= prepurchaseChapterId then
                prepurchaseChapterData:Initialize(prepurchaseChapterId)
            end
        else
            prepurchaseChapterData = ZO_ChapterUpgrade_Data:New(prepurchaseChapterId)
            self.prepurchaseChapterData = prepurchaseChapterData
        end
        prepurchaseChapterData:SetMarketProductId(marketProductId)
        self.chapterUpgradeDataById[prepurchaseChapterData:GetChapterUpgradeId()] = prepurchaseChapterData
    else
        self.prepurchaseChapterData = nil
    end

    self:FireCallbacks("ChapterUpgradeDataUpdated")
end

function ChapterUpgrade_Manager:GetPrepurchaseChapterUpgradeInfo()
    local chapterUpgradeId = 0
    local marketProductId = GetActiveChapterUpgradeMarketProductListing(MARKET_DISPLAY_GROUP_CHAPTER_UPGRADE)
    if marketProductId ~= 0 then
        chapterUpgradeId = GetMarketProductChapterUpgradeId(marketProductId)
    end
    return chapterUpgradeId, marketProductId
end

function ChapterUpgrade_Manager:GetChapterUpgradeDataById(chapterUpgradeId)
    return self.chapterUpgradeDataById[chapterUpgradeId]
end

function ChapterUpgrade_Manager:GetPrepurchaseChapterUpgradeData()
    return self.prepurchaseChapterData
end

function ChapterUpgrade_Manager:GetCurrentChapterUpgradeData()
    return self.currentChapterData
end

function ChapterUpgrade_Manager:GetNumChapterUpgrades()
    return NonContiguousCount(self.chapterUpgradeDataById)
end

function ChapterUpgrade_Manager:RequestPrepurchaseData()
    OpenMarket(MARKET_DISPLAY_GROUP_CHAPTER_UPGRADE)
    local marketState = GetMarketState(MARKET_DISPLAY_GROUP_CHAPTER_UPGRADE)
    if marketState == MARKET_STATE_OPEN then
        self:RefreshChapterUpgradeData()
    end
end

ZO_CHAPTER_UPGRADE_MANAGER = ChapterUpgrade_Manager:New()