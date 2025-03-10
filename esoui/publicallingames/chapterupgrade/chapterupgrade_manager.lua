-----------------
-- Data Object --
-----------------

ZO_CHAPTER_UPGRADE_REWARD_TYPE =
{
    PRE_PURCHASE = 1,
    BASIC = 2,
    PRE_ORDER = 3,
}

ZO_ChapterUpgrade_Data = ZO_InitializingObject:Subclass()

function ZO_ChapterUpgrade_Data:Initialize(chapterUpgradeId)
    local _
    self.chapterUpgradeId = chapterUpgradeId
    self.marketProductId = 0
    self.collectibleId = GetChapterCollectibleId(chapterUpgradeId)
    self.name, _, self.collectibleIcon = GetCollectibleInfo(self.collectibleId)
    local overrideName = GetChapterOverrideDisplayName(chapterUpgradeId)
    if overrideName ~= "" then
        self.name = overrideName
    end
    self.summary = GetChapterSummary(chapterUpgradeId)
    self:RefreshChapterUpgradeState()
    self.marketBackgroundImage = GetChapterMarketBackgroundFileImage(chapterUpgradeId)
    self.isContentPass = IsChapterContentPass(chapterUpgradeId)
    self.isNew = false
    self.discountPercent = 0
    self:PopulateRewardsData()
end

function ZO_ChapterUpgrade_Data:RefreshChapterUpgradeState()
    self.isPreRelease = IsChapterPreRelease(self.chapterUpgradeId)
    if self.isPreRelease then
        self.releaseDateString = GetChapterReleaseDateString(self.chapterUpgradeId)
    else
        self.releaseDateString = nil
    end
    self.isOwned = IsChapterOwned(self.chapterUpgradeId)
end

do
    local function RewardEntryComparator(leftData, rightData)
        if leftData.rewardType == rightData.rewardType then
            --Fall back to def order
            return leftData.index < rightData.index
        else
            --Secondary ordering is reward type, basic comes before preorder
            return leftData.rewardType < rightData.rewardType
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
    self.discountPercent = select(4, GetMarketProductPricingByPresentation(self.marketProductId))
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

function ZO_ChapterUpgrade_Data:IsContentPass()
    return self.isContentPass
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

function ZO_ChapterUpgrade_Data:GetDiscountPercent()
    return self.discountPercent
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

local ChapterUpgrade_Manager = ZO_InitializingCallbackObject:Subclass()

function ChapterUpgrade_Manager:Initialize()
    local currentChapterId = GetCurrentChapterUpgradeId()
    self.currentChapterData = ZO_ChapterUpgrade_Data:New(currentChapterId)

    self.chapterUpgradeDataList = {}
    self.chapterUpgradeDataById = {}

    self.marketState = GetMarketState(MARKET_DISPLAY_GROUP_CHAPTER_UPGRADE)
    self:RefreshChapterUpgradeData()

    local function OnMarketStateUpdated(eventCode, displayGroup, marketState)
        if displayGroup == MARKET_DISPLAY_GROUP_CHAPTER_UPGRADE then
            self.marketState = marketState
            self:RefreshChapterUpgradeData()
        end
    end

    local function OnCollectiblesUnlockStateChanged()
        self.currentChapterData:RefreshChapterUpgradeState()
        for _, data in ipairs(self.chapterUpgradeDataList) do
            data:RefreshChapterUpgradeState()
        end
    end

    EVENT_MANAGER:RegisterForEvent("ChapterUpgrade_Manager", EVENT_MARKET_STATE_UPDATED, OnMarketStateUpdated)
    EVENT_MANAGER:RegisterForEvent("ChapterUpgrade_Manager", EVENT_COLLECTIBLES_UNLOCK_STATE_CHANGED, OnCollectiblesUnlockStateChanged)
end

do
    local function ChapterUpgradeDataSort(left, right)
        local leftChapterUpgradeId = left:GetChapterUpgradeId()
        local rightChapterUpgradeId = right:GetChapterUpgradeId()
        local leftChapterEnum = GetChapterEnumFromUpgradeId(leftChapterUpgradeId)
        local rightChapterEnum = GetChapterEnumFromUpgradeId(rightChapterUpgradeId)
        if leftChapterEnum == rightChapterEnum then
            return leftChapterUpgradeId > rightChapterUpgradeId
        else
            return leftChapterEnum > rightChapterEnum
        end
    end

    function ChapterUpgrade_Manager:RefreshChapterUpgradeData()
        ZO_ClearNumericallyIndexedTable(self.chapterUpgradeDataList)
        ZO_ClearTable(self.chapterUpgradeDataById)

        local marketProductIds = { GetActiveChapterUpgradeMarketProductListings(MARKET_DISPLAY_GROUP_CHAPTER_UPGRADE) }

        for _, marketProductId in ipairs(marketProductIds) do
            local chapterUpgradeId = GetMarketProductChapterUpgradeId(marketProductId)
            -- Two entries for the same chapter id is undefined behavior, so just ignore duplicates
            if not self.chapterUpgradeDataById[chapterUpgradeId] then
                local chapterUpgradeData = ZO_ChapterUpgrade_Data:New(chapterUpgradeId)
                chapterUpgradeData:SetMarketProductId(marketProductId)
                table.insert(self.chapterUpgradeDataList, chapterUpgradeData)
                self.chapterUpgradeDataById[chapterUpgradeId] = chapterUpgradeData
            end
        end

        if #marketProductIds == 0 then
            --static fallback data
            table.insert(self.chapterUpgradeDataList, self.currentChapterData)
            self.chapterUpgradeDataById[self.currentChapterData:GetChapterUpgradeId()] = self.currentChapterData
        end

        table.sort(self.chapterUpgradeDataList, ChapterUpgradeDataSort)

        self:FireCallbacks("ChapterUpgradeDataUpdated")
    end
end

function ChapterUpgrade_Manager:GetChapterUpgradeDataByIndex(index)
    return self.chapterUpgradeDataList[index]
end

function ChapterUpgrade_Manager:GetChapterUpgradeDataById(chapterUpgradeId)
    return self.chapterUpgradeDataById[chapterUpgradeId]
end

function ChapterUpgrade_Manager:GetNumChapterUpgrades()
    return #self.chapterUpgradeDataList
end

function ChapterUpgrade_Manager:RequestPrepurchaseData()
    OpenMarket(MARKET_DISPLAY_GROUP_CHAPTER_UPGRADE)
end

function ChapterUpgrade_Manager:GetMarketState()
    return self.marketState
end

ZO_CHAPTER_UPGRADE_MANAGER = ChapterUpgrade_Manager:New()