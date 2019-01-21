-- Helper object for object pool data --

local REFRESH_CHILDREN = true

ZO_PooledSkillDataObject = ZO_Object:Subclass()

function ZO_PooledSkillDataObject:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_PooledSkillDataObject:Initialize()
    -- Can be overriden
end

function ZO_PooledSkillDataObject:Reset()
    -- Can be overriden
end

function ZO_PooledSkillDataObject:BuildData(...)
    self:BuildStaticData(...)
    self:RefreshDynamicData()
end

function ZO_PooledSkillDataObject:BuildStaticData(...)
    assert(false) -- Must be overriden
end

function ZO_PooledSkillDataObject:RefreshDynamicData(...)
    -- Can be overriden
end

--[[
    A ZO_SkillProgressionData is an entry in a ZO_SkillData. Each one describes a step in the progression for upgrading the skill.
--]]

-----------------------
-- Skill Progression --
-----------------------

ZO_SkillProgressionData = ZO_PooledSkillDataObject:Subclass()

function ZO_SkillProgressionData:New(...)
    return ZO_PooledSkillDataObject.New(self, ...)
end

function ZO_SkillProgressionData:Reset()
    self.abilityId = nil
end

function ZO_SkillProgressionData:BuildStaticData(skillData, skillProgressionKey)
    self.skillData, self.skillProgressionKey = skillData, skillProgressionKey
end

function ZO_SkillProgressionData:RefreshDynamicData(...)
    --Nothing to refresh, for now
end

function ZO_SkillProgressionData:GetIndices()
    local skillType, skillLineIndex, skillIndex = self.skillData:GetIndices()
    return skillType, skillLineIndex, skillIndex, self.skillProgressionKey
end

-- Actives and passives progress differently.
-- In actives, progression key corresponds to morph slots.
-- In passives, progression key corresponds to rank.
function ZO_SkillProgressionData:GetSkillProgressionKey()
    return self.skillProgressionKey
end

function ZO_SkillProgressionData:GetSkillData()
    return self.skillData
end

function ZO_SkillProgressionData:GetAbilityId()
    return self.abilityId
end

function ZO_SkillProgressionData:SetAbilityId(abilityId)
    self.abilityId = abilityId
    self.name = GetAbilityName(abilityId)
    self.icon = GetAbilityIcon(abilityId)
    SKILLS_DATA_MANAGER:MapAbilityIdToProgression(abilityId, self)
end

function ZO_SkillProgressionData:GetName()
    return self.name
end

function ZO_SkillProgressionData:GetFormattedName(formatter)
    return ZO_CachedStrFormat(formatter or SI_ABILITY_NAME, self.name)
end

function ZO_SkillProgressionData:GetFormattedNameWithRank()
    assert(false) -- Must be overriden
end

function ZO_SkillProgressionData:GetIcon()
    return self.icon
end

function ZO_SkillProgressionData:IsPassive()
    return self:GetSkillData():IsPassive()
end

function ZO_SkillProgressionData:IsActive()
    return not self:IsPassive()
end

function ZO_SkillProgressionData:IsUnlocked()
    return self.skillData:MeetsLinePurchaseRequirement()
end

function ZO_SkillProgressionData:IsLocked()
    return not self:IsUnlocked()
end

function ZO_SkillProgressionData:IsAdvised()
    return ZO_SKILLS_ADVISOR_SINGLETON:IsSkillProgressionDataInSelectedBuild(self)
end

function ZO_SkillProgressionData:SetKeyboardTooltip()
    assert(false) -- Must be overriden
end

------------------------------
-- Active Skill Progression --
------------------------------

ZO_ActiveSkillProgressionData = ZO_SkillProgressionData:Subclass()

function ZO_ActiveSkillProgressionData:New(...)
    return ZO_SkillProgressionData.New(self, ...)
end

function ZO_ActiveSkillProgressionData:Initialize()
    ZO_SkillProgressionData.Initialize(self)

    self.rankXPExtents = {}
    for rank = 1, MAX_RANKS_PER_ABILITY do
        table.insert(self.rankXPExtents, { })
    end
end

function ZO_ActiveSkillProgressionData:BuildStaticData(skillData, morphSlot)
    ZO_SkillProgressionData.BuildStaticData(self, skillData, morphSlot)

    local progressionId = skillData:GetProgressionId()
    local abilityId = GetProgressionSkillMorphSlotAbilityId(progressionId, morphSlot)

    self:SetAbilityId(abilityId)

    local chainedAbilityIds = {GetProgressionSkillMorphSlotChainedAbilityIds(progressionId, morphSlot)}
    for _, chainedAbilityId in ipairs(chainedAbilityIds) do
        SKILLS_DATA_MANAGER:MapAbilityIdToProgression(chainedAbilityId, self)
    end

    self.isChainingAbility = #chainedAbilityIds > 0

    for rank = 1, MAX_RANKS_PER_ABILITY do
        local startXP, endXP = GetProgressionSkillMorphSlotRankXPExtents(progressionId, morphSlot, rank)
        local xpExtents = self.rankXPExtents[rank]
        xpExtents.startXP = startXP
        xpExtents.endXP = endXP
    end
end

function ZO_ActiveSkillProgressionData:RefreshDynamicData(...)
    ZO_SkillProgressionData.RefreshDynamicData(self, ...)

    self.currentXP = GetProgressionSkillMorphSlotCurrentXP(self:GetProgressionId(), self:GetMorphSlot())
    -- Rank can be nil if we've never purchased the skill before
    self.currentRank = GetAbilityProgressionRankFromAbilityId(self:GetAbilityId())
end

function ZO_ActiveSkillProgressionData:GetMorphSlot()
    --Alias
    return self:GetSkillProgressionKey()
end

function ZO_ActiveSkillProgressionData:IsBase()
    return self:GetMorphSlot() == MORPH_SLOT_BASE
end

function ZO_ActiveSkillProgressionData:IsMorph()
    return self:GetMorphSlot() ~= MORPH_SLOT_BASE
end

function ZO_ActiveSkillProgressionData:GetSiblingMorphData()
    assert(self:IsMorph(), "GetSiblingMorphData should not be called on a base progression data")

    local siblingMorphSlot = self:GetMorphSlot() == MORPH_SLOT_MORPH_1 and MORPH_SLOT_MORPH_2 or MORPH_SLOT_MORPH_1
    return self:GetSkillData():GetMorphData(siblingMorphSlot)
end

function ZO_ActiveSkillProgressionData:IsBadMorph()
    if self:IsMorph() then
        local morphSiblingProgressionData = self:GetSiblingMorphData()
        return not self:IsAdvised() and morphSiblingProgressionData:IsAdvised()
    end
    return false
end

function ZO_ActiveSkillProgressionData:GetFormattedNameWithRank(formatter)
    if self:HasRankData() then
        return ZO_CachedStrFormat(formatter or SI_ABILITY_NAME_AND_RANK, self:GetName(), self.currentRank)
    else
        return self:GetFormattedName()
    end
end

function ZO_ActiveSkillProgressionData:IsUltimate()
    return self:GetSkillData():IsUltimate()
end

function ZO_ActiveSkillProgressionData:GetCurrentRank()
    return self.currentRank
end

function ZO_ActiveSkillProgressionData:HasRankData()
    return self.currentRank ~= nil
end

function ZO_ActiveSkillProgressionData:GetCurrentXP()
    return self.currentXP
end

function ZO_ActiveSkillProgressionData:GetRankXPExtents(rank)
    local startXP, endXP = 0, 0
    local xpExtents = self.rankXPExtents[rank]
    if xpExtents then
        startXP, endXP = xpExtents.startXP, xpExtents.endXP
    end
    return startXP, endXP
end

function ZO_ActiveSkillProgressionData:GetProgressionId()
    return self:GetSkillData():GetProgressionId()
end

function ZO_ActiveSkillProgressionData:IsUnlocked()
    if ZO_SkillProgressionData.IsUnlocked(self) then
        if self:IsMorph() then
            return self:GetSkillData():IsAtMorph()
        end
        return true
    end
    return false
end

function ZO_ActiveSkillProgressionData:IsChainingAbility()
    return self.isChainingAbility
end

function ZO_ActiveSkillProgressionData:SetKeyboardTooltip(tooltip, showSkillPointCost, showUpgradeText, showAdvised, showBadMorph, overrideRank, overrideAbilityId)
    local skillType, skillLineIndex, skillIndex = self:GetIndices()
    local isPurchased = self:GetSkillData():GetPointAllocator():IsPurchased()
    local numAvailableSkillPoints = SKILL_POINT_ALLOCATION_MANAGER:GetAvailableSkillPoints()
    tooltip:SetActiveSkill(skillType, skillLineIndex, skillIndex, self:GetMorphSlot(), isPurchased, self:IsAdvised(), self:IsBadMorph(), numAvailableSkillPoints, showSkillPointCost, showUpgradeText, showAdvised, showBadMorph, overrideRank, overrideAbilityId)
end

-------------------------------
-- Passive Skill Progression --
-------------------------------

ZO_PassiveSkillProgressionData = ZO_SkillProgressionData:Subclass()

function ZO_PassiveSkillProgressionData:New(...)
    return ZO_SkillProgressionData.New(self, ...)
end

function ZO_PassiveSkillProgressionData:BuildStaticData(skillData, rank)
    ZO_SkillProgressionData.BuildStaticData(self, skillData, rank)

    local skillType, skillLineIndex, skillIndex = skillData:GetIndices()
    local UNUSED_MORPH_CHOICE = MORPH_SLOT_BASE
    local abilityId, lineRankNeededToUnlock = GetSpecificSkillAbilityInfo(skillType, skillLineIndex, skillIndex, UNUSED_MORPH_CHOICE, rank)

    self:SetAbilityId(abilityId)
    self.lineRankNeededToUnlock = lineRankNeededToUnlock
end

function ZO_PassiveSkillProgressionData:GetFormattedNameWithRank(formatter)
    return ZO_CachedStrFormat(formatter or SI_ABILITY_NAME_AND_RANK, self:GetName(), self:GetRank())
end

function ZO_PassiveSkillProgressionData:GetFormattedNameWithUpgradeLevels(formatter)
    local skillData = self:GetSkillData()
    local currentRank = skillData:GetPointAllocator():IsPurchased() and self:GetRank() or 0

    return ZO_CachedStrFormat(formatter or SI_ABILITY_NAME_AND_UPGRADE_LEVELS, self:GetName(), currentRank, skillData:GetNumRanks())
end

function ZO_PassiveSkillProgressionData:GetRank()
    --Alias
    return self:GetSkillProgressionKey()
end

function ZO_PassiveSkillProgressionData:GetLineRankNeededToUnlock()
    return self.lineRankNeededToUnlock
end

function ZO_PassiveSkillProgressionData:MeetsLineRankUnlockRequirement()
    local skillLineData = self:GetSkillData():GetSkillLineData()
    return self:GetLineRankNeededToUnlock() <= skillLineData:GetCurrentRank()
end

function ZO_PassiveSkillProgressionData:IsUnlocked()
    if ZO_SkillProgressionData.IsUnlocked(self) then
        return self:MeetsLineRankUnlockRequirement()
    end
    return false
end

function ZO_PassiveSkillProgressionData:GetNextRankData()
    local myRank = self:GetRank()
    if myRank < self:GetSkillData():GetNumRanks() then
        return self:GetSkillData():GetRankData(myRank + 1)
    end
    return nil
end

function ZO_PassiveSkillProgressionData:SetKeyboardTooltip(tooltip, showSkillPointCost)
    local skillType, skillLineIndex, skillIndex = self:GetIndices()
    local skillPointAllocator = self:GetSkillData():GetPointAllocator()
    local currentRank = skillPointAllocator:IsPurchased() and skillPointAllocator:GetSkillProgressionKey() or 0
    local numAvailableSkillPoints = SKILL_POINT_ALLOCATION_MANAGER:GetAvailableSkillPoints()
    tooltip:SetPassiveSkill(skillType, skillLineIndex, skillIndex, self:GetRank(), currentRank, numAvailableSkillPoints, showSkillPointCost)
end

--[[
    A ZO_SkillData is an entry in a ZO_SkillLineData. A skill can be upgraded to various levels, denoted by ZO_SkillProgressionData objects.
--]]

-----------
-- Skill --
-----------

ZO_SkillData = ZO_PooledSkillDataObject:Subclass()

function ZO_SkillData:New(...)
    return ZO_PooledSkillDataObject.New(self, ...)
end

function ZO_SkillData:Initialize()
    self.skillProgressions = {}
    self.progressionObjectMetaPool = ZO_MetaPool:New(SKILLS_DATA_MANAGER:GetSkillProgressionObjectPool(self:IsPassive()))
end

function ZO_SkillData:Reset()
    ZO_ClearTable(self.skillProgressions)
    self.progressionObjectMetaPool:ReleaseAllObjects()
end

function ZO_SkillData:BuildStaticData(skillLineData, skillIndex)
    self.skillLineData, self.skillIndex = skillLineData, skillIndex
    local skillType, skillLineIndex = self.skillLineData:GetIndices()

    self.lineRankNeededToPurchase = GetSkillAbilityLineRankNeededToUnlock(skillType, skillLineIndex, skillIndex)
    self.isAutoGrant = IsSkillAbilityAutoGrant(skillType, skillLineIndex, skillIndex)
end

function ZO_SkillData:RefreshDynamicData(refreshChildren)
    self.isPurchased = IsSkillAbilityPurchased(self:GetIndices())

    if refreshChildren then
        for _, skillProgressionData in pairs(self.skillProgressions) do
            skillProgressionData:RefreshDynamicData(refreshChildren)
        end
    end
end

function ZO_SkillData:AddProgressionObject(skillProgressionKey)
    local progressionData = self.progressionObjectMetaPool:AcquireObject()
    progressionData:BuildData(self, skillProgressionKey)
    self.skillProgressions[skillProgressionKey] = progressionData
    return progressionData
end

function ZO_SkillData:GetSkillIndex()
    return self.skillIndex
end

function ZO_SkillData:GetIndices()
    local skillType, skillLineIndex = self.skillLineData:GetIndices()
    return skillType, skillLineIndex, self.skillIndex
end

function ZO_SkillData:GetSkillLineData()
    return self.skillLineData
end

function ZO_SkillData:IsPassive()
    assert(false) -- Must be overriden
end

function ZO_SkillData:IsActive()
    return not self:IsPassive()
end

function ZO_SkillData:GetLineRankNeededToPurchase()
    return self.lineRankNeededToPurchase
end

function ZO_SkillData:MeetsLinePurchaseRequirement()
    local skillLineData = self:GetSkillLineData()
    return skillLineData:IsAvailable() and self:GetLineRankNeededToPurchase() <= skillLineData:GetCurrentRank()
end

function ZO_SkillData:IsAutoGrant()
    return self.isAutoGrant
end

function ZO_SkillData:IsPurchased()
    return self.isPurchased
end

function ZO_SkillData:IsAdvised()
    return ZO_SKILLS_ADVISOR_SINGLETON:IsSkillDataInSelectedBuild(self)
end

function ZO_SkillData:HasPointsToClear(clearMorphsOnly)
    assert(false) -- Must be overriden
end

function ZO_SkillData:GetProgressionData(skillProgressionKey)
    return self.skillProgressions[skillProgressionKey]
end

function ZO_SkillData:GetHeaderText()
    assert(false) -- Must be overriden
end

function ZO_SkillData:GetCurrentSkillProgressionKey()
    assert(false) -- Must be overriden
end

function ZO_SkillData:GetNumPointsAllocated()
    assert(false) -- Must be overriden
end

function ZO_SkillData:GetCurrentProgressionData()
    return self:GetProgressionData(self:GetCurrentSkillProgressionKey())
end

function ZO_SkillData:GetPointAllocator()
    --Utility function
    return SKILL_POINT_ALLOCATION_MANAGER:GetSkillPointAllocatorForSkillData(self)
end

function ZO_SkillData:GetPointAllocatorProgressionData()
    --Utility function
    return self:GetPointAllocator():GetProgressionData()
end

function ZO_SkillData:HasUpdatedStatus()
    return self.hasUpdatedStatus
end

function ZO_SkillData:SetHasUpdatedStatus(hasUpdatedStatus)
    if self.hasUpdatedStatus ~= hasUpdatedStatus then
        self.hasUpdatedStatus = hasUpdatedStatus
        self.skillLineData:OnSkillDataUpdateStatusChanged(self)
    end
end

function ZO_SkillData:ClearUpdate()
    self:SetHasUpdatedStatus(false)
end

function ZO_SkillData:CanPointAllocationsBeAltered(isFullRespec)
    return self:MeetsLinePurchaseRequirement()
end

------------------
-- Active Skill --
------------------

ZO_ActiveSkillData = ZO_SkillData:Subclass()

function ZO_ActiveSkillData:New(...)
    return ZO_SkillData.New(self, ...)
end

function ZO_ActiveSkillData:BuildStaticData(skillLineData, skillIndex)
    ZO_SkillData.BuildStaticData(self, skillLineData, skillIndex)

    local skillType, skillLineIndex = skillLineData:GetIndices()
    self.isUltimate = IsSkillAbilityUltimate(skillType, skillLineIndex, skillIndex)
    self.progressionId = GetProgressionSkillProgressionId(skillType, skillLineIndex, skillIndex)

    for morphSlot = MORPH_SLOT_ITERATION_BEGIN, MORPH_SLOT_ITERATION_END do
        self:AddProgressionObject(morphSlot)
    end

    -- Don't mark a skill new during init
    self.canBeMarkedAsUpdated = false
    self:SetHasUpdatedStatus(false)
end

function ZO_ActiveSkillData:RefreshDynamicData(...)
    local wasAtMorph = self:IsAtMorph()

    ZO_SkillData.RefreshDynamicData(self, ...)

    self.currentMorphSlot = GetProgressionSkillCurrentMorphSlot(self.progressionId)

    if self.canBeMarkedAsUpdated then
        local isBase = self.currentMorphSlot == MORPH_SLOT_BASE
        local isPurchased = self:IsPurchased()
        if self:HasUpdatedStatus() then
            if not (isBase and isPurchased) then
                self:SetHasUpdatedStatus(false)
            end
        elseif not wasAtMorph and self:IsAtMorph() and isPurchased and isBase then
            self:SetHasUpdatedStatus(true)
        end
    end

    self.canBeMarkedAsUpdated = true
end

function ZO_ActiveSkillData:IsPassive()
    return false
end

function ZO_ActiveSkillData:IsUltimate()
    return self.isUltimate
end

function ZO_ActiveSkillData:GetProgressionId()
    return self.progressionId
end

function ZO_ActiveSkillData:GetCurrentMorphSlot()
    return self.currentMorphSlot
end

function ZO_ActiveSkillData:GetCurrentSkillProgressionKey()
    -- Generic
    return self:GetCurrentMorphSlot()
end

function ZO_ActiveSkillData:GetNumPointsAllocated()
    local pointsAllocated = 0
    if self:IsPurchased() then
        if not self:IsAutoGrant() then
            pointsAllocated = pointsAllocated + 1
        end

        if self:GetCurrentMorphSlot() ~= MORPH_SLOT_BASE then
            pointsAllocated = pointsAllocated + 1
        end
    end
    return pointsAllocated
end

function ZO_ActiveSkillData:GetMorphData(morphSlot)
    -- Alias
    return self:GetProgressionData(morphSlot)
end

function ZO_ActiveSkillData:IsAtMorph()
    local baseMorphData = self:GetMorphData(MORPH_SLOT_BASE)
    local baseMorphCurrentXP = baseMorphData:GetCurrentXP()
    local _, baseMorphEndXP = baseMorphData:GetRankXPExtents(MAX_RANKS_PER_ABILITY)
    return baseMorphCurrentXP >= baseMorphEndXP
end

function ZO_ActiveSkillData:GetHeaderText()
    if self:IsUltimate() then
        return GetString(SI_SKILLS_ULTIMATE_ABILITIES)
    else
        return GetString(SI_SKILLS_ACTIVE_ABILITIES)
    end
end

function ZO_ActiveSkillData:GetSlotOnCurrentHotbar()
    return ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar():FindSlotMatchingSkill(self)
end

function ZO_ActiveSkillData:HasPointsToClear(clearMorphsOnly)
    if self:IsPurchased() then
        if clearMorphsOnly then
            return self:GetCurrentMorphSlot() ~= MORPH_SLOT_BASE
        else
            return not self:IsAutoGrant()
        end
    end
    return false
end

function ZO_ActiveSkillData:CanPointAllocationsBeAltered(isFullRespec)
    if ZO_SkillData.CanPointAllocationsBeAltered(self, isFullRespec) then
        if self:IsPurchased() and not self:IsAtMorph() then
            return isFullRespec and not self:IsAutoGrant()
        end
        return true
    end
    return false
end

-------------------
-- Passive Skill --
-------------------

ZO_PassiveSkillData = ZO_SkillData:Subclass()

function ZO_PassiveSkillData:New(...)
    return ZO_SkillData.New(self, ...)
end

function ZO_PassiveSkillData:BuildStaticData(skillLineData, skillIndex)
    ZO_SkillData.BuildStaticData(self, skillLineData, skillIndex)

    local skillType, skillLineIndex = skillLineData:GetIndices()
    self.numRanks = GetNumPassiveSkillRanks(skillType, skillLineIndex, skillIndex)
    for rank = 1, self.numRanks do
        self:AddProgressionObject(rank)
    end
end

function ZO_PassiveSkillData:RefreshDynamicData(...)
    ZO_SkillData.RefreshDynamicData(self, ...)
    
    -- Can return nil, but we want to be at 1 when we're not purchased or we have a passive with only 1 rank and no upgrades
    self.currentRank = GetSkillAbilityUpgradeInfo(self:GetIndices())
    if not self.currentRank or self.currentRank == 0 then
        self.currentRank = 1
    end
end

function ZO_PassiveSkillData:IsPassive()
    return true
end

function ZO_PassiveSkillData:GetNumRanks()
    return self.numRanks
end

function ZO_PassiveSkillData:GetCurrentRank()
    return self.currentRank
end

function ZO_PassiveSkillData:GetCurrentSkillProgressionKey()
    -- Generic
    return self:GetCurrentRank()
end

function ZO_PassiveSkillData:GetNumPointsAllocated()
    if self:IsPurchased() then
        if self:IsAutoGrant() then
            return self:GetCurrentRank() - 1
        else
            return self:GetCurrentRank()
        end
    end
    return 0
end

--1 based
function ZO_PassiveSkillData:GetRankData(rank)
    -- Alias
    return self:GetProgressionData(rank)
end

function ZO_PassiveSkillData:GetHeaderText()
    return GetString(SI_SKILLS_PASSIVE_ABILITIES)
end

function ZO_PassiveSkillData:HasPointsToClear(clearMorphsOnly)
    if not clearMorphsOnly and self:IsPurchased() then
        return self:GetCurrentRank() > 1 or not self:IsAutoGrant()
    end
    return false
end

function ZO_PassiveSkillData:CanPointAllocationsBeAltered(isFullRespec)
    if ZO_SkillData.CanPointAllocationsBeAltered(self, isFullRespec) then
        if self:IsPurchased() then
            local currentRank = self:GetCurrentRank()
            local nextRankData = self:GetRankData(currentRank + 1)
            if nextRankData and nextRankData:MeetsLineRankUnlockRequirement() then
                return true
            end
            return isFullRespec and (currentRank > 1 or not self:IsAutoGrant())
        end
        return true
    end
    return false
end

--[[
    A ZO_SkillLineData is an entry in ZO_SkillTypeData. A skill line has multiple skills to purchase and upgrade, denoted by ZO_SkillData objects.
--]]

----------------
-- Skill Line --
----------------

ZO_SkillLineData = ZO_PooledSkillDataObject:Subclass()

function ZO_SkillLineData:New(...)
    return ZO_PooledSkillDataObject.New(self, ...)
end

function ZO_SkillLineData:Initialize()
    self.orderedSkills = {}
    self.skillsWithUpdatesCache = {}
    local IS_ACTIVE = false
    local IS_PASSIVE = true
    self.activeSkillMetaPool = ZO_MetaPool:New(SKILLS_DATA_MANAGER:GetSkillObjectPool(IS_ACTIVE))
    self.passiveSkillMetaPool = ZO_MetaPool:New(SKILLS_DATA_MANAGER:GetSkillObjectPool(IS_PASSIVE))
end

function ZO_SkillLineData:Reset()
    ZO_ClearNumericallyIndexedTable(self.orderedSkills)
    ZO_ClearTable(self.skillsWithUpdatesCache)
    self.activeSkillMetaPool:ReleaseAllObjects()
    self.passiveSkillMetaPool:ReleaseAllObjects()
end

function ZO_SkillLineData:BuildStaticData(skillTypeData, skillLineIndex)
    self.skillTypeData, self.skillLineIndex = skillTypeData, skillLineIndex
    local skillType = self.skillTypeData:GetSkillType()

    self.name = GetSkillLineName(skillType, skillLineIndex)
    self.id = GetSkillLineId(skillType, skillLineIndex)
    self.unlockText = GetSkillLineUnlockText(skillType, skillLineIndex)
    self.orderingIndex = GetSkillLineOrderingIndex(skillType, skillLineIndex)
    self.isWerewolf = IsWerewolfSkillLine(skillType, skillLineIndex)
    self.craftingGrowthType = GetSkillLineCraftingGrowthType(skillType, skillLineIndex)
    self.announceIcon = GetSkillLineAnnouncementIcon(skillType, skillLineIndex)

    for skillIndex = 1, GetNumSkillAbilities(skillType, skillLineIndex) do
        local skillData
        local isPassive = IsSkillAbilityPassive(skillType, skillLineIndex, skillIndex)
        if isPassive then
            skillData = self.passiveSkillMetaPool:AcquireObject()
        else
            skillData = self.activeSkillMetaPool:AcquireObject()
        end

        skillData:BuildData(self, skillIndex)
        table.insert(self.orderedSkills, skillData)
    end

    self.isNew = false
    self.canMarkNew = false
end

function ZO_SkillLineData:RefreshDynamicData(refreshChildren)
    local skillType, skillLineIndex = self:GetIndices()

    local wasAvailable = self:IsAvailable()

    self.currentRank, self.isAdvised, self.isActive, self.isDiscovered = GetSkillLineDynamicInfo(skillType, skillLineIndex)
    self.lastRankXP, self.nextRankXP, self.currentXP = GetSkillLineXPInfo(skillType, skillLineIndex)

    local isAvailable = self:IsAvailable()

    if self.canMarkNew and wasAvailable ~= isAvailable then
        self:SetNew(isAvailable)
    end

    if refreshChildren then
        for _, skillData in ipairs(self.orderedSkills) do
            skillData:RefreshDynamicData(refreshChildren)
        end
    end

    self.canMarkNew = true
end

function ZO_SkillLineData:GetSkillTypeData()
    return self.skillTypeData
end

function ZO_SkillLineData:GetSkillLineIndex()
    return self.skillLineIndex
end

function ZO_SkillLineData:GetIndices()
    return self.skillTypeData:GetSkillType(), self.skillLineIndex
end

function ZO_SkillLineData:GetId()
    return self.id
end

function ZO_SkillLineData:GetName()
    return self.name
end

function ZO_SkillLineData:GetFormattedName()
    return ZO_CachedStrFormat(SI_SKILLS_ENTRY_LINE_NAME_FORMAT, self.name)
end

function ZO_SkillLineData:GetFormattedNameWithNumPointsAllocated()
    local numPointsAllocated = SKILL_POINT_ALLOCATION_MANAGER:GetNumPointsAllocatedInSkillLine(self)
    if numPointsAllocated > 0 then
        return zo_strformat(SI_SKILLS_ENTRY_LINE_NAME_FORMAT_WITH_ALLOCATED_POINTS, self.name, numPointsAllocated)
    else
        return self:GetFormattedName()
    end
end

function ZO_SkillLineData:GetUnlockText()
    return self.unlockText
end

function ZO_SkillLineData:GetOrderingIndex()
    return self.orderingIndex
end

function ZO_SkillLineData:IsWerewolf()
    return self.isWerewolf
end

function ZO_SkillLineData:GetCraftingGrowthType()
    return self.craftingGrowthType
end

function ZO_SkillLineData:GetAnnounceIcon()
    return self.announceIcon
end

function ZO_SkillLineData:IsAvailable()
    return self.isDiscovered and self.isActive
end

function ZO_SkillLineData:IsDiscovered()
    return self.isDiscovered
end

function ZO_SkillLineData:IsActive()
    return self.isActive
end

function ZO_SkillLineData:IsAdvised()
    return self.isAdvised
end

function ZO_SkillLineData:SetAdvised(advised)
    local skillType, skillLineIndex = self:GetIndices()
    SetAdviseSkillLine(skillType, skillLineIndex, advised)
end

function ZO_SkillLineData:GetCurrentRank()
    return self.currentRank
end

function ZO_SkillLineData:GetLastRankXP()
    return self.lastRankXP
end

function ZO_SkillLineData:GetNextRankXP()
    return self.nextRankXP
end

function ZO_SkillLineData:GetCurrentRankXP()
    return self.currentXP
end

function ZO_SkillLineData:GetRankXPValues()
    return self.lastRankXP, self.nextRankXP, self.currentXP
end

function ZO_SkillLineData:IsNew()
    return self.isNew
end

function ZO_SkillLineData:SetNew(isNew)
    if self.isNew ~= isNew then
        self.isNew = isNew
        SKILLS_DATA_MANAGER:OnSkillLineNewStatusChanged(self)
    end
end

function ZO_SkillLineData:AnySkillHasUpdatedStatus()
    return NonContiguousCount(self.skillsWithUpdatesCache) > 0
end

function ZO_SkillLineData:IsSkillLineOrAbilitiesNew()
    return self:IsNew() or self:AnySkillHasUpdatedStatus()
end

function ZO_SkillLineData:ClearNew()
    self:SetNew(false)
end

function ZO_SkillLineData:OnSkillDataUpdateStatusChanged(skillData)
    local hasUpdatedStatus = skillData:HasUpdatedStatus()
    self.skillsWithUpdatesCache[skillData] = hasUpdatedStatus or nil
    SKILLS_DATA_MANAGER:OnSkillLineNewStatusChanged(self)
end

function ZO_SkillLineData:GetNumSkills()
    return #self.orderedSkills
end

function ZO_SkillLineData:GetSkillDataByIndex(skillIndex)
    return self.orderedSkills[skillIndex]
end

function ZO_SkillLineData:SkillIterator(skillFilterFunctions)
    return ZO_FilteredNumericallyIndexedTableIterator(self.orderedSkills, skillFilterFunctions)
end

--[[
    A ZO_SkillTypeData is the overarching categorization of skill lines. A skill type can be subcategorized down into multiple skill lines, denoted by ZO_SkillLineData objects.
--]]

----------------
-- Skill Type --
----------------

ZO_SkillTypeData = ZO_PooledSkillDataObject:Subclass()

function ZO_SkillTypeData:New(...)
    return ZO_PooledSkillDataObject.New(self, ...)
end

function ZO_SkillTypeData:Initialize()
    self.orderedSkillLines = {}
    self.skillLineMetaPool = ZO_MetaPool:New(SKILLS_DATA_MANAGER:GetSkillLineObjectPool())
end

function ZO_SkillTypeData:Reset()
    ZO_ClearNumericallyIndexedTable(self.orderedSkillLines)
    self.skillLineMetaPool:ReleaseAllObjects()
end

do
    assert(SKILL_TYPE_MAX_VALUE == 9, "Update this table");

    local SKILL_TYPE_TO_ICON_PATH_QUALIFIER = 
    {
        [SKILL_TYPE_CLASS] = "class",
        [SKILL_TYPE_WEAPON] = "weapons",
        [SKILL_TYPE_ARMOR] = "armor",
        [SKILL_TYPE_WORLD] = "world",
        [SKILL_TYPE_GUILD] = "guilds",
        [SKILL_TYPE_AVA] = "ava",
        [SKILL_TYPE_RACIAL] = "race",
        [SKILL_TYPE_TRADESKILL] = "tradeskills",
    }

    function ZO_SkillTypeData:BuildStaticData(skillType)
        self.skillType = skillType

        self.name = GetString("SI_SKILLTYPE", skillType)
        local QUALIFIER = SKILL_TYPE_TO_ICON_PATH_QUALIFIER[skillType]
        if QUALIFIER then
            self.keyboardNormalIcon = string.format("EsoUI/Art/Progression/progression_indexIcon_%s_up.dds", QUALIFIER)
            self.keyboardPressedIcon = string.format("EsoUI/Art/Progression/progression_indexIcon_%s_down.dds", QUALIFIER)
            self.keyboardMousedOverIcon = string.format("EsoUI/Art/Progression/progression_indexIcon_%s_over.dds", QUALIFIER)
            self.announceIcon = string.format("EsoUI/Art/Progression/skills_announce_%s.dds", QUALIFIER)
        end

        for skillLineIndex = 1, GetNumSkillLines(skillType) do
            local skillLineData = self.skillLineMetaPool:AcquireObject()
            skillLineData:BuildData(self, skillLineIndex)
            table.insert(self.orderedSkillLines, skillLineData)
        end
    end
end

function ZO_SkillTypeData:RefreshDynamicData(refreshChildren)
    if refreshChildren then
        for _, skillLineData in ipairs(self.orderedSkillLines) do
            skillLineData:RefreshDynamicData(refreshChildren)
        end
    end
end


function ZO_SkillTypeData:GetSkillType()
    return self.skillType
end

function ZO_SkillTypeData:GetName()
    return self.name
end

function ZO_SkillTypeData:GetKeyboardIcons()
    return self.keyboardNormalIcon, self.keyboardPressedIcon, self.keyboardMousedOverIcon
end

function ZO_SkillTypeData:GetAnnounceIcon()
    return self.announceIcon
end

do
    local SKILL_TYPE_TO_MENU_CLICK_SOUND =
    {
        [SKILL_TYPE_CLASS] = SOUNDS.SKILL_TYPE_CLASS,
        [SKILL_TYPE_WEAPON] = SOUNDS.SKILL_TYPE_WEAPON,
        [SKILL_TYPE_ARMOR] = SOUNDS.SKILL_TYPE_ARMOR,
        [SKILL_TYPE_WORLD] = SOUNDS.SKILL_TYPE_WORLD,
        [SKILL_TYPE_GUILD] = SOUNDS.SKILL_TYPE_GUILD,
        [SKILL_TYPE_AVA] = SOUNDS.SKILL_TYPE_AVA,
        [SKILL_TYPE_RACIAL] = SOUNDS.SKILL_TYPE_RACIAL,
        [SKILL_TYPE_TRADESKILL] = SOUNDS.SKILL_TYPE_TRADESKILL,
    }

    function ZO_SkillTypeData:GetMenuClickSound()
        return SKILL_TYPE_TO_MENU_CLICK_SOUND[self.skillType]
    end
end

function ZO_SkillTypeData:AreAnySkillLinesNew()
    for _, skillLineData in self:SkillLineIterator({ ZO_SkillLineData.IsNew }) do
        return true
    end
    return false
end

function ZO_SkillTypeData:AreAnySkillLinesOrAbilitiesNew()
    for _, skillLineData in self:SkillLineIterator({ ZO_SkillLineData.IsSkillLineOrAbilitiesNew } ) do
        return true
    end
    return false
end

function ZO_SkillTypeData:GetSkillLineDataByIndex(skillLineIndex)
    return self.orderedSkillLines[skillLineIndex]
end

function ZO_SkillTypeData:SkillLineIterator(skillLineFilterFunctions)
    return ZO_FilteredNumericallyIndexedTableIterator(self.orderedSkillLines, skillLineFilterFunctions)
end

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
    local function ResetData(data)
        data:Reset()
    end
    
    self.skillTypeObjectPool = ZO_ObjectPool:New(ZO_SkillTypeData, ResetData)
    self.skillLineObjectPool = ZO_ObjectPool:New(ZO_SkillLineData, ResetData)
    self.activeSkillObjectPool = ZO_ObjectPool:New(ZO_ActiveSkillData, ResetData)
    self.passiveSkillObjectPool = ZO_ObjectPool:New(ZO_PassiveSkillData, ResetData)
    self.activeSkillProgressionObjectPool = ZO_ObjectPool:New(ZO_ActiveSkillProgressionData, ResetData)
    self.passiveSkillProgressionObjectPool = ZO_ObjectPool:New(ZO_PassiveSkillProgressionData, ResetData)
    
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
    EVENT_MANAGER:RegisterForEvent("ZO_SkillsDataManager", EVENT_SKILL_RANK_UPDATE, GenerateGatedEventCallbackFunction(ZO_SkillsDataManager.OnSkillLineUpdated))
    EVENT_MANAGER:RegisterForEvent("ZO_SkillsDataManager", EVENT_SKILL_XP_UPDATE, GenerateGatedEventCallbackFunction(ZO_SkillsDataManager.OnSkillLineUpdated))
    EVENT_MANAGER:RegisterForEvent("ZO_SkillsDataManager", EVENT_ABILITY_PROGRESSION_RANK_UPDATE, GenerateGatedEventCallbackFunction(ZO_SkillsDataManager.OnSkillProgressionUpdated))
    EVENT_MANAGER:RegisterForEvent("ZO_SkillsDataManager", EVENT_ABILITY_PROGRESSION_XP_UPDATE, GenerateGatedEventCallbackFunction(ZO_SkillsDataManager.OnSkillProgressionUpdated))
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

function ZO_SkillsDataManager:GetSkillObjectPool(isPassive)
    if isPassive then
        return self.passiveSkillObjectPool
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
    ZO_ClearTable(self.abilityIdToProgressionDataMap)

    for skillType = SKILL_TYPE_ITERATION_BEGIN, SKILL_TYPE_ITERATION_END do
        local skillTypeData = self.skillTypeObjectPool:AcquireObject(skillType)
        skillTypeData:BuildData(skillType)
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

function ZO_SkillsDataManager:OnSkillProgressionUpdated(progressionIndex)
    local skillType, skillLineIndex, skillIndex = GetSkillAbilityIndicesFromProgressionIndex(progressionIndex)
    local skillData = self:GetSkillDataByIndices(skillType, skillLineIndex, skillIndex)
    if skillData then
        skillData:RefreshDynamicData(REFRESH_CHILDREN)
        self:FireCallbacks("SkillProgressionUpdated", skillData)
    end
    --There are progressions set up on dummy skill lines that can come through here, so just ignore them
end

function ZO_SkillsDataManager:OnSkillLineNewStatusChanged(skillLineData)
    self:FireCallbacks("SkillLineNewStatusChanged", skillLineData)
end

-- End Event Handlers --

function ZO_SkillsDataManager:IsDataReady()
    return self.isDataReady
end

function ZO_SkillsDataManager:GetSkillTypeData(skillType)
    return self.skillTypeObjectPool:GetExistingObject(skillType)
end

function ZO_SkillsDataManager:GetSkillLineDataByIndices(skillType, skillLineIndex)
    local skillTypeData = self:GetSkillTypeData(skillType)
    if skillTypeData then
        return skillTypeData:GetSkillLineDataByIndex(skillLineIndex)
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

function ZO_SkillsDataManager:AreAnySkillLinesNew()
    for _, skillTypeData in self:SkillTypeIterator({ ZO_SkillTypeData.AreAnySkillLinesNew } ) do
        return true
    end
    return false
end

function ZO_SkillsDataManager:AreAnySkillLinesOrAbilitiesNew()
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
    -- This only works because we use the categoryObjectPool like a numerically indexed table
    return ZO_FilteredNumericallyIndexedTableIterator(self.skillTypeObjectPool:GetActiveObjects(), skillTypeFilterFunctions)
end

ZO_SkillsDataManager:New()