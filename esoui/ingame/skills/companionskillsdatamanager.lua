------------------
-- Data Manager --
------------------

ZO_CompanionSkillsDataManager = ZO_InitializingCallbackObject:Subclass()

function ZO_CompanionSkillsDataManager:Initialize()
    COMPANION_SKILLS_DATA_MANAGER = self
    
    self.skillTypeObjectPool = ZO_ObjectPool:New(ZO_SkillTypeData, ZO_ObjectPool_DefaultResetObject)
    self.skillLineObjectPool = ZO_ObjectPool:New(ZO_CompanionSkillLineData, ZO_ObjectPool_DefaultResetObject)
    self.skillObjectPool = ZO_ObjectPool:New(ZO_CompanionSkillData, ZO_ObjectPool_DefaultResetObject)
    self.skillsByAbilityId = {}
    
    self.isDataReady = false

    self:RegisterForEvents()

    if AreCompanionSkillsInitialized() then
        self:RebuildSkillsData()
    end
end

function ZO_CompanionSkillsDataManager:RegisterForEvents()
    local function GenerateEventMethod(method)
        return function(_, ...)
            return method(self, ...)
        end
    end
    EVENT_MANAGER:RegisterForEvent("ZO_CompanionSkillsDataManager", EVENT_COMPANION_SKILLS_FULL_UPDATE, GenerateEventMethod(ZO_CompanionSkillsDataManager.OnFullSystemUpdated))
    EVENT_MANAGER:RegisterForEvent("ZO_CompanionSkillsDataManager", EVENT_COMPANION_SKILL_LINE_ADDED, GenerateEventMethod(ZO_CompanionSkillsDataManager.OnSkillLineAdded))
    EVENT_MANAGER:RegisterForEvent("ZO_CompanionSkillsDataManager", EVENT_COMPANION_SKILL_RANK_UPDATE, GenerateEventMethod(ZO_CompanionSkillsDataManager.OnSkillLineRankUpdated))
    EVENT_MANAGER:RegisterForEvent("ZO_CompanionSkillsDataManager", EVENT_COMPANION_SKILL_XP_UPDATE, GenerateEventMethod(ZO_CompanionSkillsDataManager.OnSkillLineXPUpdated))
end

function ZO_CompanionSkillsDataManager:GetSkillLineObjectPool()
    return self.skillLineObjectPool
end

function ZO_CompanionSkillsDataManager:GetSkillObjectPool()
    return self.skillObjectPool
end

function ZO_CompanionSkillsDataManager:RebuildSkillsData()
    self.skillTypeObjectPool:ReleaseAllObjects()
    self.skillLineObjectPool:ReleaseAllObjects()
    ZO_ClearTable(self.skillsByAbilityId)

    for skillType = SKILL_TYPE_ITERATION_BEGIN, SKILL_TYPE_ITERATION_END do
        local skillTypeData = self.skillTypeObjectPool:AcquireObject(skillType)
        skillTypeData:BuildData(skillType)
    end
    
    for _, skillTypeData in self:SkillTypeIterator() do
        for skillLineIndex = 1, GetNumCompanionSkillLines(skillTypeData:GetSkillType()) do
            local skillLineData = self.skillLineObjectPool:AcquireObject()
            skillLineData:BuildData(skillTypeData, skillLineIndex)
            skillTypeData:AddOrderedSkillLineData(skillLineData)
        end
    end

    self.isDataReady = true
    local NOT_INIT = false
    self:OnFullSystemUpdated(NOT_INIT)
end

-- Begin Event Handlers --
do
    local REFRESH_CHILDREN = true

    function ZO_CompanionSkillsDataManager:OnFullSystemUpdated(isInit)
        if isInit then
            -- unlike player skills, companion skills are updated through
            -- multiple messages, and can be de-initialized and re-initialized as
            -- the companion is activated/deactivated.
            -- to handle these situations we'll just rebuild everything as if it were our initial update.
            self.isDataReady = false
        end
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

    function ZO_CompanionSkillsDataManager:OnSkillLineAdded(skillLineId)
        local skillLineData = self:GetSkillLineDataById(skillLineId)
        if skillLineData then
            skillLineData:RefreshDynamicData(REFRESH_CHILDREN)
            self:FireCallbacks("SkillLineAdded", skillLineData)
        else
            local errorString = string.format("OnSkillLineAdded fired with invalid indices - skillLineId: %d", skillLineId)
            internalassert(false, errorString)
        end
    end

    function ZO_CompanionSkillsDataManager:OnSkillLineUpdated(skillLineId)
        local skillLineData = self:GetSkillLineDataById(skillLineId)
        if skillLineData then
            skillLineData:RefreshDynamicData(REFRESH_CHILDREN)
            self:FireCallbacks("SkillLineUpdated", skillLineData)
        else
            local errorString = string.format("OnSkillLineUpdated fired with invalid indices - skillLineId: %d", skillLineId)
            internalassert(false, errorString)
        end
    end
end

function ZO_CompanionSkillsDataManager:OnSkillLineRankUpdated(skillLineId)
    self:OnSkillLineUpdated(skillLineId)
    local skillLineData = self:GetSkillLineDataById(skillLineId)
    if skillLineData then
        self:FireCallbacks("SkillLineRankUpdated", skillLineData)
    end
end

function ZO_CompanionSkillsDataManager:OnSkillLineXPUpdated(skillLineId)
    self:OnSkillLineUpdated(skillLineId)
    local skillLineData = self:GetSkillLineDataById(skillLineId)
    if skillLineData then
        self:FireCallbacks("SkillLineXPUpdated", skillLineData)
    end
end

function ZO_CompanionSkillsDataManager:OnSkillLineNewStatusChanged(skillLineData)
    self:FireCallbacks("SkillLineNewStatusChanged", skillLineData)
end

function ZO_CompanionSkillsDataManager:OnCompanionSkillUpdateStatusChanged(skillData)
    self:FireCallbacks("CompanionSkillUpdateStatusChanged", skillData)
end

-- End Event Handlers --

function ZO_CompanionSkillsDataManager:IsDataReady()
    return self.isDataReady
end

function ZO_CompanionSkillsDataManager:AreAnySkillLinesNew()
    for _, skillTypeData in self:SkillTypeIterator({ ZO_SkillTypeData.AreAnySkillLinesNew } ) do
        return true
    end
    return false
end

function ZO_CompanionSkillsDataManager:GetSkillTypeData(skillType)
    return self.skillTypeObjectPool:GetActiveObject(skillType)
end

function ZO_CompanionSkillsDataManager:GetSkillLineDataById(skillLineId)
    for _, skillLineData in self.skillLineObjectPool:ActiveObjectIterator() do
        if skillLineData:GetId() == skillLineId then
            return skillLineData
        end
    end
end

function ZO_CompanionSkillsDataManager:GetSkillLineDataByIndices(skillType, skillLineIndex)
    local skillTypeData = self:GetSkillTypeData(skillType)
    if skillTypeData then
        return skillTypeData:GetSkillLineDataByIndex(skillLineIndex)
    end
end

function ZO_CompanionSkillsDataManager:SkillTypeIterator(skillTypeFilterFunctions)
    -- This only works because we use the skillTypeObjectPool like a numerically indexed table
    return ZO_FilteredNumericallyIndexedTableIterator(self.skillTypeObjectPool:GetActiveObjects(), skillTypeFilterFunctions)
end

function ZO_CompanionSkillsDataManager:MapAbilityIdToSkill(abilityId, skillData)
    self.skillsByAbilityId[abilityId] = skillData
end

function ZO_CompanionSkillsDataManager:GetSkillDataByAbilityId(abilityId)
    return self.skillsByAbilityId[abilityId]
end

ZO_CompanionSkillsDataManager:New()
