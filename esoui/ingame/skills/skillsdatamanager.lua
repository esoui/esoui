------------------
-- Data Manager --
------------------

ZO_SkillsDataManager = ZO_CallbackObject:Subclass()

function ZO_SkillsDataManager:New(...)
    SKILLS_DATA_MANAGER = ZO_CallbackObject.New(self)
    SKILLS_DATA_MANAGER:Initialize(...)
    return SKILLS_DATA_MANAGER
end

function ZO_SkillsDataManager:Initialize()
    self.skillTypeObjectPool = ZO_ObjectPool:New(ZO_SkillTypeData, ZO_ObjectPool_DefaultResetObject)
    self.skillLineObjectPool = ZO_ObjectPool:New(ZO_SkillLineData, ZO_ObjectPool_DefaultResetObject)
    self.activeSkillObjectPool = ZO_ObjectPool:New(ZO_ActiveSkillData, ZO_ObjectPool_DefaultResetObject)
    self.craftedActiveSkillObjectPool = ZO_ObjectPool:New(ZO_CraftedActiveSkillData, ZO_ObjectPool_DefaultResetObject)
    self.passiveSkillObjectPool = ZO_ObjectPool:New(ZO_PassiveSkillData, ZO_ObjectPool_DefaultResetObject)
    self.activeSkillProgressionObjectPool = ZO_ObjectPool:New(ZO_ActiveSkillProgressionData, ZO_ObjectPool_DefaultResetObject)
    self.passiveSkillProgressionObjectPool = ZO_ObjectPool:New(ZO_PassiveSkillProgressionData, ZO_ObjectPool_DefaultResetObject)
    
    self.isDataReady = false
    self.skillProgressionsDirty = false
    -- In the event that we want to temporarily disable events (e.g.: until an eventual full refresh) we can turn them off with this
    self.isGatingEventUpdates = false

    self.abilityIdToProgressionDataMap = {}

    self:RegisterForEvents()

    if AreSkillsInitialized() then
        self:RebuildSkillsData()
    end
end

function ZO_SkillsDataManager:RegisterForEvents()
    local function GenerateGatedEventCallbackFunction(callbackSignature)
        return function(eventId, ...)
            if not self:IsGatingEventUpdates() then
                callbackSignature(self, ...)
            end
        end
    end

    EVENT_MANAGER:RegisterForEvent("ZO_SkillsDataManager", EVENT_SKILLS_FULL_UPDATE, GenerateGatedEventCallbackFunction(ZO_SkillsDataManager.OnFullSystemUpdated))
    EVENT_MANAGER:RegisterForEvent("ZO_SkillsDataManager", EVENT_SKILL_LINE_ADDED, GenerateGatedEventCallbackFunction(ZO_SkillsDataManager.OnSkillLineAdded))
    EVENT_MANAGER:RegisterForEvent("ZO_SkillsDataManager", EVENT_SKILL_RANK_UPDATE, GenerateGatedEventCallbackFunction(ZO_SkillsDataManager.OnSkillLineRankUpdated))
    EVENT_MANAGER:RegisterForEvent("ZO_SkillsDataManager", EVENT_SKILL_XP_UPDATE, GenerateGatedEventCallbackFunction(ZO_SkillsDataManager.OnSkillLineXPUpdated))
    EVENT_MANAGER:RegisterForEvent("ZO_SkillsDataManager", EVENT_CLEAR_NEW_ON_ALL_SKILL_LINES, GenerateGatedEventCallbackFunction(ZO_SkillsDataManager.OnClearNewOnAllSkillLines))
    EVENT_MANAGER:RegisterForEvent("ZO_SkillsDataManager", EVENT_ABILITY_PROGRESSION_RANK_UPDATE, GenerateGatedEventCallbackFunction(ZO_SkillsDataManager.OnSkillProgressionUpdated))
    EVENT_MANAGER:RegisterForEvent("ZO_SkillsDataManager", EVENT_ABILITY_PROGRESSION_XP_UPDATE, GenerateGatedEventCallbackFunction(ZO_SkillsDataManager.OnSkillProgressionUpdated))

    local function OnCollectionUpdated(collectionUpdateType, collectiblesByNewUnlockState)
        if collectionUpdateType == ZO_COLLECTION_UPDATE_TYPE.UNLOCK_STATE_CHANGED then
            for unlockedState, unlockedCollectibles in pairs(collectiblesByNewUnlockState) do
                for index, collectibleData in ipairs(unlockedCollectibles) do
                    if collectibleData:IsSkillStyle() then
                        local progressionId = collectibleData:GetSkillStyleProgressionId()
                        local skillData = SKILLS_DATA_MANAGER:GetSkillDataByProgressionId(progressionId)
                        skillData:SetUpdatedStatusByType(ZO_SKILL_DATA_NEW_STATE.STYLE_COLLECTIBLE, collectibleData:IsUnlocked())
                    end
                end
            end
        end
    end

    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", OnCollectionUpdated)
end

function ZO_SkillsDataManager:IsGatingEventUpdates()
    if IsSettingTemplate() then
        -- If class or race are changing, the indices are meaningless, so just wait until the inevitable reload of the UI
        return true
    end

    return self.isGatingEventUpdates
end

function ZO_SkillsDataManager:SetIsGatingEventUpdates(isGatingEventUpdates)
    self.isGatingEventUpdates = isGatingEventUpdates
end

function ZO_SkillsDataManager:GetSkillLineObjectPool()
    return self.skillLineObjectPool
end

function ZO_SkillsDataManager:GetSkillObjectPool(isPassive, isCrafted)
    if isPassive then
        return self.passiveSkillObjectPool
    elseif isCrafted then
        return self.craftedActiveSkillObjectPool
    else
        return self.activeSkillObjectPool
    end
end

function ZO_SkillsDataManager:GetSkillProgressionObjectPool(isPassive)
    if isPassive then
        return self.passiveSkillProgressionObjectPool
    else
        return self.activeSkillProgressionObjectPool
    end
end

function ZO_SkillsDataManager:RebuildSkillsData()
    self.skillTypeObjectPool:ReleaseAllObjects()
    self.skillLineObjectPool:ReleaseAllObjects()
    ZO_ClearTable(self.abilityIdToProgressionDataMap)

    for skillType = SKILL_TYPE_ITERATION_BEGIN, SKILL_TYPE_ITERATION_END do
        local skillTypeData = self.skillTypeObjectPool:AcquireObject(skillType)
        skillTypeData:BuildData(skillType)
    end

    for _, skillTypeData in self:SkillTypeIterator() do
        for skillLineIndex = 1, GetNumSkillLines(skillTypeData:GetSkillType()) do
            local skillLineData, key = self.skillLineObjectPool:AcquireObject()
            skillLineData:BuildData(skillTypeData, skillLineIndex)
            skillTypeData:AddOrderedSkillLineData(skillLineData)
        end
    end

    self.isDataReady = true
    self:FireCallbacks("FullSystemUpdated")
end

function ZO_SkillsDataManager:MapAbilityIdToProgression(abilityId, progressionData)
    -- Only make a map if we have a valid ID and we haven't already mapped a progression to this abilityId.
    -- This protects against the fact that we have duplicate passive abilities in the racial skill lines:
    -- The current active race is always processed first, so the skill that's actually matches the player's race will be the one mapped, and not other ones.
    if abilityId ~= 0 and self.abilityIdToProgressionDataMap[abilityId] == nil then
        self.abilityIdToProgressionDataMap[abilityId] = progressionData
    end
end

-- Begin Event Handlers --

do
    local REFRESH_CHILDREN = true

    function ZO_SkillsDataManager:OnFullSystemUpdated()
        if self.isDataReady then
            for skillType = SKILL_TYPE_ITERATION_BEGIN, SKILL_TYPE_ITERATION_END do
                local skillTypeData = self:GetSkillTypeData(skillType)
                skillTypeData:RefreshDynamicData(REFRESH_CHILDREN)
            end
            self:FireCallbacks("FullSystemUpdated")
        else
            self:RebuildSkillsData()
        end
    end

    function ZO_SkillsDataManager:OnSkillLineAdded(skillType, skillLineIndex)
        local skillLineData = self:GetSkillLineDataByIndices(skillType, skillLineIndex)
        if skillLineData then
            skillLineData:RefreshDynamicData(REFRESH_CHILDREN)
            self:FireCallbacks("SkillLineAdded", skillLineData)
        else
            local errorString = string.format("OnSkillLineAdded fired with invalid indices - skillType: %d; skillLineIndex: %d", skillType, skillLineIndex)
            internalassert(false, errorString)
        end
    end

    function ZO_SkillsDataManager:OnSkillLineUpdated(skillType, skillLineIndex)
        local skillLineData = self:GetSkillLineDataByIndices(skillType, skillLineIndex)
        if skillLineData then
            skillLineData:RefreshDynamicData(REFRESH_CHILDREN)
            self:FireCallbacks("SkillLineUpdated", skillLineData)
        else
            local errorString = string.format("OnSkillLineUpdated fired with invalid indices - skillType: %d; skillLineIndex: %d", skillType, skillLineIndex)
            internalassert(false, errorString)
        end
    end

    function ZO_SkillsDataManager:OnSkillLineRankUpdated(skillType, skillLineIndex)
        self:OnSkillLineUpdated(skillType, skillLineIndex)
        local skillLineData = self:GetSkillLineDataByIndices(skillType, skillLineIndex)
        if skillLineData then
            self:FireCallbacks("SkillLineRankUpdated", skillLineData)
        end
    end

    function ZO_SkillsDataManager:OnSkillLineXPUpdated(skillType, skillLineIndex)
        self:OnSkillLineUpdated(skillType, skillLineIndex)
        local skillLineData = self:GetSkillLineDataByIndices(skillType, skillLineIndex)
        if skillLineData then
            self:FireCallbacks("SkillLineXPUpdated", skillLineData)
        end
    end

    function ZO_SkillsDataManager:OnClearNewOnAllSkillLines()
        for _, skillTypeData in self:SkillTypeIterator() do
            for _, skillLineData in skillTypeData:SkillLineIterator() do
                skillLineData:ClearAllStatuses()
            end
        end
    end

    function ZO_SkillsDataManager:OnSkillProgressionUpdated(progressionIndex)
        local skillType, skillLineIndex, skillIndex = GetSkillAbilityIndicesFromProgressionIndex(progressionIndex)
        local skillData = self:GetSkillDataByIndices(skillType, skillLineIndex, skillIndex)
        if skillData then
            skillData:RefreshDynamicData(REFRESH_CHILDREN)
            self:FireCallbacks("SkillProgressionUpdated", skillData)
        end
        --There are progressions set up on dummy skill lines that can come through here, so just ignore them
    end

    function ZO_SkillsDataManager:OnCraftedAbilityUpdated(craftedAbilityId)
        local skillType, skillLineIndex, skillIndex = GetSkillAbilityIndicesFromCraftedAbilityId(craftedAbilityId)
        local skillData = self:GetSkillDataByIndices(skillType, skillLineIndex, skillIndex)
        if skillData then
            skillData:RefreshDynamicData(REFRESH_CHILDREN)
            self:FireCallbacks("CraftedAbilityUpdated", skillData)
        end
    end

    function ZO_SkillsDataManager:OnSkillLineNewStatusChanged(skillLineData)
        self:FireCallbacks("SkillLineNewStatusChanged", skillLineData)
    end
end

-- End Event Handlers --

function ZO_SkillsDataManager:IsDataReady()
    return self.isDataReady
end

function ZO_SkillsDataManager:GetSkillTypeData(skillType)
    return self.skillTypeObjectPool:GetActiveObject(skillType)
end

function ZO_SkillsDataManager:GetSkillLineDataByIndices(skillType, skillLineIndex)
    local skillTypeData = self:GetSkillTypeData(skillType)
    if skillTypeData then
        return skillTypeData:GetSkillLineDataByIndex(skillLineIndex)
    end
end

function ZO_SkillsDataManager:GetSkillLineDataById(skillLineId)
    for _, skillLineData in self.skillLineObjectPool:ActiveObjectIterator() do
        if skillLineData:GetId() == skillLineId then
            return skillLineData
        end
    end
end

function ZO_SkillsDataManager:GetSkillDataByIndices(skillType, skillLineIndex, skillIndex)
    local skillLineData = self:GetSkillLineDataByIndices(skillType, skillLineIndex)
    if skillLineData then
        return skillLineData:GetSkillDataByIndex(skillIndex)
    end
end

function ZO_SkillsDataManager:GetProgressionDataByAbilityId(abilityId)
    return self.abilityIdToProgressionDataMap[abilityId]
end

function ZO_SkillsDataManager:GetSkillDataByProgressionId(progressionId)
    local abilityId = GetProgressionSkillMorphSlotAbilityId(progressionId, MORPH_SLOT_BASE)
    local progressionData = self:GetProgressionDataByAbilityId(abilityId)
    if progressionData then
        return progressionData:GetSkillData()
    end
    return nil
end

function ZO_SkillsDataManager:AreAnyPlayerSkillLinesNew()
    for _, skillTypeData in self:SkillTypeIterator({ ZO_SkillTypeData.AreAnySkillLinesNew } ) do
        return true
    end
    return false
end

function ZO_SkillsDataManager:AreAnyPlayerSkillLinesOrAbilitiesNew()
    for _, skillTypeData in self:SkillTypeIterator({ ZO_SkillTypeData.AreAnySkillLinesOrAbilitiesNew } ) do
        return true
    end
    return false
end

function ZO_SkillsDataManager:GetCraftingSkillLineData(craftingSkillType)
    local skillTypeData = self:GetSkillTypeData(SKILL_TYPE_TRADESKILL)
    if skillTypeData then
        for _, skillLineData in skillTypeData:SkillLineIterator() do
            if skillLineData:GetCraftingGrowthType() == craftingSkillType then
                return skillLineData
            end
        end
    end
    return nil
end

function ZO_SkillsDataManager:GetWerewolfSkillLineData()
    local skillTypeData = self:GetSkillTypeData(SKILL_TYPE_WORLD)
    if skillTypeData then
        for _, skillLineData in skillTypeData:SkillLineIterator() do
            if skillLineData:IsWerewolf() then
                return skillLineData
            end
        end
    end
    return nil
end

function ZO_SkillsDataManager:SkillTypeIterator(skillTypeFilterFunctions)
    -- This only works because we use the skillTypeObjectPool like a numerically indexed table
    return ZO_FilteredNumericallyIndexedTableIterator(self.skillTypeObjectPool:GetActiveObjects(), skillTypeFilterFunctions)
end

function ZO_SkillsDataManager:IsAnySkillStyleOwned(data)
    local progressionId = data.skillData.progressionId
    local anyLocked = false
    for index = 1, GetNumProgressionSkillAbilityFxOverrides(progressionId) do
        local collectibleId = GetProgressionSkillAbilityFxOverrideCollectibleIdByIndex(progressionId, index)
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
        if collectibleData and not collectibleData:IsHiddenFromCollection() then
            if collectibleData:IsOwned() then
                return true
            end
            anyLocked = true
        end
    end

    return not anyLocked
end

function ZO_SkillsDataManager:GetSkillStyleWarningText(data)
    local isStyleOwned = self:IsAnySkillStyleOwned(data)

    if not data.skillData.isPurchased then
        if isStyleOwned then
            return GetString(SI_SKILL_STYLING_SKILL_NOT_PURCHASED)
        else
            return GetString(SI_SKILL_STYLING_SKILL_AND_STYLE_NOT_PURCHASED)
        end
    else
        if not isStyleOwned then
            return GetString(SI_SKILL_STYLING_STYLE_NOT_PURCHASED)
        else
            return ""
        end
    end
end

ZO_SkillsDataManager:New()