----------------------------------
-- Tribute Rewards Data Manager --
----------------------------------

ZO_TributeRewardsDataManager = ZO_InitializingCallbackObject:Subclass()

function ZO_TributeRewardsDataManager:Initialize()
    TRIBUTE_REWARDS_DATA_MANAGER = self

    self.rewardsTypeList = {}
    self.rewardsDataList = {}

    self:RegisterForEvents()
    self:RebuildData()
end

function ZO_TributeRewardsDataManager:RegisterForEvents()
    -- TODO Tribute: Implement
end

function ZO_TributeRewardsDataManager:MarkDataDirty()
    self.isDataDirty = true
end

function ZO_TributeRewardsDataManager:CleanData()
    if self.isDataDirty then
        self:RebuildData()
    end
end

function ZO_TributeRewardsDataManager:RebuildData()
    self.isDataDirty = false

    ZO_ClearTable(self.rewardsTypeList)
    ZO_ClearTable(self.rewardsDataList)

    for typeIndex, typeTable in pairs(ZO_TRIBUTE_TYPE_DATA) do
        self:InternalGetOrCreateTributeRewardsTypeData(typeIndex)
        if typeTable then
            if typeTable.isSeasonType then
                for tierIndex = TRIBUTE_TIER_ITERATION_BEGIN, TRIBUTE_TIER_ITERATION_END do
                    self:InternalGetOrCreateTributeRewardsData(typeIndex, tierIndex)
                end
            else
                for tierIndex = TRIBUTE_LEADERBOARD_TIER_ITERATION_BEGIN, TRIBUTE_LEADERBOARD_TIER_ITERATION_END do
                    self:InternalGetOrCreateTributeRewardsData(typeIndex, tierIndex)
                end
            end
        end
    end
end

function ZO_TributeRewardsDataManager:GetNumTiersForTributeRewardsType(rewardsTypeId)
    return NonContiguousCount(self.rewardsDataList[rewardsTypeId])
end

function ZO_TributeRewardsDataManager:TributeRewardsTypeIterator(rewardsTypeId, filterFunctions)
    self:CleanData()
    if self.rewardsDataList[rewardsTypeId] then
        return ZO_FilteredNonContiguousTableIterator(self.rewardsDataList[rewardsTypeId], filterFunctions)
    end
    return nil
end

function ZO_TributeRewardsDataManager:GetTributeRewardsData(rewardsTypeId, rewardsTierId)
    self:CleanData()
    return self.rewardsDataList[rewardsTypeId] and self.rewardsDataList[rewardsTypeId][rewardsTierId]
end

function ZO_TributeRewardsDataManager:GetTributeRewardsTypeData(rewardsTypeId)
    self:CleanData()
    return self.rewardsTypeList[rewardsTypeId]
end

function ZO_TributeRewardsDataManager:InternalGetOrCreateTributeRewardsData(rewardsTypeId, rewardsTierId)
    if rewardsTypeId and rewardsTypeId > 0 then
        local tributeRewardsData = self:GetTributeRewardsData(rewardsTypeId, rewardsTierId)
        if not tributeRewardsData then
            tributeRewardsData = ZO_TributeRewardsData:New(self:GetTributeRewardsTypeData(rewardsTypeId), rewardsTierId)

            if not self.rewardsDataList[rewardsTypeId] then
                self.rewardsDataList[rewardsTypeId] = {}
            end

            self.rewardsDataList[rewardsTypeId][rewardsTierId] = tributeRewardsData
        end
        return tributeRewardsData
    end
end

function ZO_TributeRewardsDataManager:InternalGetOrCreateTributeRewardsTypeData(rewardsTypeId)
    if rewardsTypeId and rewardsTypeId > 0 then
        local tributeRewardsTypeData = self:GetTributeRewardsTypeData(rewardsTypeId)
        if not tributeRewardsTypeData then
            tributeRewardsTypeData = ZO_TributeRewardsTypeData:New(rewardsTypeId)

            self.rewardsTypeList[rewardsTypeId] = tributeRewardsTypeData
        end
        return tributeRewardsTypeData
    end
end

-- Global singleton

-- The global singleton moniker is assigned by the Data Manager's constructor in order to
-- allow data objects to reference the singleton during their construction.
ZO_TributeRewardsDataManager:New()