--[[
    This file mirrors CompanionSkillsData.lua in many ways, before editing or
    removing methods please ensure there is a stable interface between the two.
]]--

ZO_PlayerSkillProgressionData = ZO_SkillProgressionData_Base:Subclass()
ZO_PlayerSkillProgressionData:IGNORE_UNIMPLEMENTED()

-- Begin overriding methods in ZO_SkillProgressionData_Base --

function ZO_PlayerSkillProgressionData:SetAbilityId(abilityId)
    ZO_SkillProgressionData_Base.SetAbilityId(self, abilityId)
    SKILLS_DATA_MANAGER:MapAbilityIdToProgression(abilityId, self)
end

-- End overriding methods in ZO_SkillProgressionData_Base --

-- Begin implementing methods in ZO_SkillProgressionData_Base --

function ZO_PlayerSkillProgressionData:IsAdvised()
    return ZO_SKILLS_ADVISOR_SINGLETON:IsSkillProgressionDataInSelectedBuild(self)
end

-- End implementing methods in ZO_SkillProgressionData_Base --

function ZO_PlayerSkillProgressionData:GetNumSkillStyles()
    return 0
end

function ZO_PlayerSkillProgressionData:HasAnyNonHiddenSkillStyles()
    return false
end

------------------------------
-- Active Skill Progression --
------------------------------

ZO_ActiveSkillProgressionData = ZO_PlayerSkillProgressionData:Subclass()

-- Begin overriding methods in ZO_SkillProgressionData_Base --

function ZO_ActiveSkillProgressionData:Initialize()
    ZO_PlayerSkillProgressionData.Initialize(self)

    self.rankXPExtents = {}
    for rank = 1, MAX_RANKS_PER_ABILITY do
        table.insert(self.rankXPExtents, { })
    end
end

function ZO_ActiveSkillProgressionData:BuildStaticData(skillData, morphSlot)
    ZO_PlayerSkillProgressionData.BuildStaticData(self, skillData, morphSlot)

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

    self.numSkillStyles = GetNumProgressionSkillAbilityFxOverrides(progressionId)
end

function ZO_ActiveSkillProgressionData:RefreshDynamicData(...)
    ZO_PlayerSkillProgressionData.RefreshDynamicData(self, ...)

    self.currentXP = GetProgressionSkillMorphSlotCurrentXP(self:GetProgressionId(), self:GetMorphSlot())
    -- Rank can be nil if we've never purchased the skill before
    self.currentRank = GetAbilityProgressionRankFromAbilityId(self:GetAbilityId())
end

function ZO_ActiveSkillProgressionData:GetDetailedName()
    return self:GetFormattedNameWithRank()
end

function ZO_ActiveSkillProgressionData:HasRankData()
    return self.currentRank ~= nil
end

function ZO_ActiveSkillProgressionData:IsUnlocked()
    if ZO_PlayerSkillProgressionData.IsUnlocked(self) then
        if self:IsMorph() then
            return self:GetSkillData():IsAtMorph()
        end
        return true
    end
    return false
end

function ZO_ActiveSkillProgressionData:TryPickup()
    local isPurchased = self.skillData:IsPurchased()
    if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
        local skillPointAllocator = self.skillData:GetPointAllocator()
        isPurchased = skillPointAllocator:IsPurchased()
    end

    if isPurchased then
        PickupAbilityBySkillLine(self:GetIndices())
        return true
    end
    return false
end

-- End overriding methods in ZO_SkillProgressionData_Base --

-- Begin implementing methods in ZO_SkillProgressionData_Base --

function ZO_ActiveSkillProgressionData:SetKeyboardTooltip(tooltip, showSkillPointCost, showUpgradeText, showAdvised, showBadMorph, overrideRank, overrideAbilityId)
    local skillType, skillLineIndex, skillIndex = self:GetIndices()
    local isPurchased = self:GetSkillData():GetPointAllocator():IsPurchased()
    local numAvailableSkillPoints = SKILL_POINT_ALLOCATION_MANAGER:GetAvailableSkillPoints()
    tooltip:SetActiveSkill(skillType, skillLineIndex, skillIndex, self:GetMorphSlot(), isPurchased, self:IsAdvised(), self:IsBadMorph(), numAvailableSkillPoints, showSkillPointCost, showUpgradeText, showAdvised, showBadMorph, overrideRank, overrideAbilityId)
end

-- End implementing methods in ZO_SkillProgressionData_Base --

-- Begin overriding methods in ZO_PlayerSkillProgressionData --

function ZO_ActiveSkillProgressionData:GetNumSkillStyles()
    return self.numSkillStyles
end

function ZO_ActiveSkillProgressionData:HasAnyNonHiddenSkillStyles()
    for index = 1, self.numSkillStyles do
        local collectibleId = GetProgressionSkillAbilityFxOverrideCollectibleIdByIndex(self:GetProgressionId(), index)
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
        if collectibleData and not collectibleData:IsHiddenFromCollection() then
            return true
        end
    end
    return false
end

-- End overriding methods in ZO_PlayerSkillProgressionData --

function ZO_ActiveSkillProgressionData:IsSkillStyleSelected()
    if self.numSkillStyles > 0 then
        local collectibleId = GetActiveProgressionSkillAbilityFxOverrideCollectibleId(self:GetProgressionId())
        return collectibleId ~= 0
    end
    return false
end

function ZO_ActiveSkillProgressionData:GetSelectedSkillStyleCollectibleData()
    if self.numSkillStyles > 0 then
        local collectibleId = GetActiveProgressionSkillAbilityFxOverrideCollectibleId(self:GetProgressionId())
        if collectibleId ~= 0 then
            return ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
        end
    end
    return nil
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

function ZO_ActiveSkillProgressionData:GetCurrentRank()
    return self.currentRank
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

function ZO_ActiveSkillProgressionData:IsChainingAbility()
    return self.isChainingAbility
end

--------------------------------------
-- Crafted Active Skill Progression --
--------------------------------------

local CRAFTED_PROGRESSION_KEY = nil

ZO_CraftedActiveSkillProgressionData = ZO_PlayerSkillProgressionData:Subclass()

-- Begin overriding methods in ZO_SkillProgressionData_Base --

function ZO_CraftedActiveSkillProgressionData:BuildStaticData(skillData)
    ZO_PlayerSkillProgressionData.BuildStaticData(self, skillData, CRAFTED_PROGRESSION_KEY)

    local abilityId = GetAbilityIdForCraftedAbilityId(self:GetCraftedAbilityId())
    self:SetAbilityId(abilityId)
end

function ZO_CraftedActiveSkillProgressionData:RefreshDynamicData(...)
    ZO_PlayerSkillProgressionData.RefreshDynamicData(self, ...)

    -- There's one progression data for all possible combinations, so the current ability id is dynamic
    local abilityId = GetAbilityIdForCraftedAbilityId(self:GetCraftedAbilityId())
    self:SetAbilityId(abilityId)
end

function ZO_CraftedActiveSkillProgressionData:IsUnlocked()
    -- unlocked and purchased are synonymous with crafted ability skills
    return self.skillData:IsPurchased()
end

function ZO_CraftedActiveSkillProgressionData:TryPickup()
    if self.skillData:IsPurchased() then
        PickupAbilityBySkillLine(self:GetIndices())
    end
end

-- End overriding methods in ZO_SkillProgressionData_Base --

-- Begin implementing methods in ZO_SkillProgressionData_Base --

function ZO_CraftedActiveSkillProgressionData:SetKeyboardTooltip(tooltipControl, unusedShowSkillPointCost, unusedShowUpgradeText, unusedShowAdvised, unusedShowBadMorph)
    -- We always want to show the actual skill, never an override
    ResetCraftedAbilityScriptSelectionOverride()
    tooltipControl:SetAbilityId(self:GetAbilityId())
end

-- End implementing methods in ZO_SkillProgressionData_Base --

-- Begin overriding methods in ZO_PlayerSkillProgressionData --

function ZO_CraftedActiveSkillProgressionData:IsAdvised()
    return false
end

-- End overriding methods in ZO_PlayerSkillProgressionData --

function ZO_CraftedActiveSkillProgressionData:GetCraftedAbilityId()
    return self:GetSkillData():GetCraftedAbilityId()
end

-------------------------------
-- Passive Skill Progression --
-------------------------------

ZO_PassiveSkillProgressionData = ZO_PlayerSkillProgressionData:Subclass()

-- Begin overriding methods in ZO_SkillProgressionData_Base --

function ZO_PassiveSkillProgressionData:BuildStaticData(skillData, rank)
    ZO_PlayerSkillProgressionData.BuildStaticData(self, skillData, rank)

    local skillType, skillLineIndex, skillIndex = skillData:GetIndices()
    local UNUSED_MORPH_CHOICE = MORPH_SLOT_BASE
    local abilityId, lineRankNeededToUnlock = GetSpecificSkillAbilityInfo(skillType, skillLineIndex, skillIndex, UNUSED_MORPH_CHOICE, rank)

    self:SetAbilityId(abilityId)
    self.lineRankNeededToUnlock = lineRankNeededToUnlock
end

function ZO_PassiveSkillProgressionData:GetDetailedName()
    if self.skillData:GetNumRanks() > 1 then
        return self:GetFormattedNameWithUpgradeLevels()
    else
        return self:GetFormattedName()
    end
end

function ZO_PassiveSkillProgressionData:GetDetailedGamepadName()
    if self.skillData:GetNumRanks() > 1 then
        return self:GetFormattedNameWithUpgradeLevels(SI_GAMEPAD_ABILITY_NAME_AND_UPGRADE_LEVELS)
    else
        return self:GetFormattedName()
    end
end

function ZO_PassiveSkillProgressionData:IsUnlocked()
    if ZO_PlayerSkillProgressionData.IsUnlocked(self) then
        return self:MeetsLineRankUnlockRequirement()
    end
    return false
end

-- End overriding methods in ZO_SkillProgressionData_Base --

-- Begin implementing methods in ZO_SkillProgressionData_Base --

function ZO_PassiveSkillProgressionData:SetKeyboardTooltip(tooltip, showSkillPointCost)
    local skillType, skillLineIndex, skillIndex = self:GetIndices()
    local skillPointAllocator = self:GetSkillData():GetPointAllocator()
    local currentRank = skillPointAllocator:IsPurchased() and skillPointAllocator:GetSkillProgressionKey() or 0
    local numAvailableSkillPoints = SKILL_POINT_ALLOCATION_MANAGER:GetAvailableSkillPoints()
    tooltip:SetPassiveSkill(skillType, skillLineIndex, skillIndex, self:GetRank(), currentRank, numAvailableSkillPoints, showSkillPointCost)
end

-- End implementing methods in ZO_SkillProgressionData_Base --

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

function ZO_PassiveSkillProgressionData:GetNextRankData()
    local myRank = self:GetRank()
    if myRank < self:GetSkillData():GetNumRanks() then
        return self:GetSkillData():GetRankData(myRank + 1)
    end
    return nil
end

--[[
    A ZO_SkillData is an entry in a ZO_SkillLineData. A skill can be upgraded to various levels, denoted by ZO_SkillProgressionData objects.
--]]

-----------
-- Skill --
-----------

-- New Statuses for Active Skill Progression
ZO_SKILL_DATA_NEW_STATE =
{
    NONE = 0,
    SKILL_LINE = 1,
    MORPHABLE = 2,
    CRAFTED_ABILITY = 4,
    STYLE_COLLECTIBLE = 8,
}

ZO_SkillData = ZO_SkillData_Base:Subclass()
ZO_SkillData:IGNORE_UNIMPLEMENTED()

function ZO_SkillData:Initialize()
    self.skillProgressions = {}
    self.progressionObjectMetaPool = ZO_MetaPool:New(SKILLS_DATA_MANAGER:GetSkillProgressionObjectPool(self:IsPassive()))
    self:InitializeUpdateStatus()
end

function ZO_SkillData:InitializeUpdateStatus()
    self.updateStatusFlags = ZO_SKILL_DATA_NEW_STATE.NONE
end

-- Begin implementing methods in ZO_SkillData_Base --

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

function ZO_SkillData:GetSkillLineData()
    return self.skillLineData
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

function ZO_SkillData:GetProgressionData(skillProgressionKey)
    return self.skillProgressions[skillProgressionKey]
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
    return self.updateStatusFlags ~= ZO_SKILL_DATA_NEW_STATE.NONE
end

function ZO_SkillData:HasUpdatedStatusByType(statusType)
    return ZO_FlagHelpers.MaskHasFlag(self.updateStatusFlags, statusType)
end

function ZO_SkillData:SetUpdatedStatusByType(statusType, hasUpdatedStatus)
    if hasUpdatedStatus and not ZO_FlagHelpers.MaskHasFlag(self.updateStatusFlags, statusType) then
        self.updateStatusFlags = ZO_FlagHelpers.SetMaskFlag(self.updateStatusFlags, statusType)
        self.skillLineData:OnSkillDataUpdateStatusChanged(self)
    elseif not hasUpdatedStatus and ZO_FlagHelpers.MaskHasFlag(self.updateStatusFlags, statusType) then
        self.updateStatusFlags = ZO_FlagHelpers.ClearMaskFlag(self.updateStatusFlags, statusType)
        self.skillLineData:OnSkillDataUpdateStatusChanged(self)
    end
end

-- This function is MUST_IMPLEMENT so assume that it only care about the skill line state for
-- this instantiation and use SetUpdatedStatusByType for more detailed information
function ZO_SkillData:SetHasUpdatedStatus(hasUpdatedStatus)
    self:SetUpdatedStatusByType(ZO_SKILL_DATA_NEW_STATE.SKILL_LINE, hasUpdatedStatus)
end

function ZO_SkillData:ClearUpdate(suppressCallback)
    if self.updateStatusFlags ~= ZO_SKILL_DATA_NEW_STATE.NONE then
        self.updateStatusFlags = ZO_SKILL_DATA_NEW_STATE.NONE
        if not suppressCallback then
            self.skillLineData:OnSkillDataUpdateStatusChanged(self)
        end
    end
end

function ZO_SkillData:CanPointAllocationsBeAltered(isFullRespec)
    return self:MeetsLinePurchaseRequirement()
end

function ZO_SkillData:IsPlayerSkill()
    return true
end

-- End implementing methods in ZO_SkillData_Base --

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

------------------
-- Active Skill --
------------------

ZO_ActiveSkillData = ZO_SkillData:Subclass()

-- Begin overriding methods in ZO_SkillData --

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
    self:SetUpdatedStatusByType(ZO_SKILL_DATA_NEW_STATE.SKILL_LINE, false)
end

function ZO_ActiveSkillData:RefreshDynamicData(...)
    local wasAtMorph = self:IsAtMorph()

    ZO_SkillData.RefreshDynamicData(self, ...)

    self.currentMorphSlot = GetProgressionSkillCurrentMorphSlot(self.progressionId)

    if self.canBeMarkedAsUpdated then
        local isBase = self.currentMorphSlot == MORPH_SLOT_BASE
        local isPurchased = self:IsPurchased()
        if self:HasUpdatedStatusByType(ZO_SKILL_DATA_NEW_STATE.MORPHABLE) then
            if not (isBase and isPurchased) then
                self:SetUpdatedStatusByType(ZO_SKILL_DATA_NEW_STATE.MORPHABLE, false)
            end
        elseif not wasAtMorph and self:IsAtMorph() and isPurchased and isBase then
            self:SetUpdatedStatusByType(ZO_SKILL_DATA_NEW_STATE.MORPHABLE, true)
        end
    end

    self.canBeMarkedAsUpdated = true
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

-- End overriding methods in ZO_SkillData --

-- Begin implementing methods in ZO_SkillData_Base --

function ZO_ActiveSkillData:IsPassive()
    return false
end

function ZO_ActiveSkillData:IsUltimate()
    return self.isUltimate
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

function ZO_ActiveSkillData:GetHeaderText()
    if self:IsUltimate() then
        return GetString(SI_SKILLS_ULTIMATE_ABILITIES)
    else
        return GetString(SI_SKILLS_ACTIVE_ABILITIES)
    end
end

function ZO_ActiveSkillData:HasPointsToClear(clearMorphsOnly)
    if self:GetNumPointsAllocated() > 0 then
        if clearMorphsOnly then
            -- make sure there are points allocated to a morph
            return self:GetCurrentMorphSlot() ~= MORPH_SLOT_BASE
        end
        return true
    end
    return false
end

-- End implementing methods in ZO_SkillData_Base --

function ZO_ActiveSkillData:GetProgressionId()
    return self.progressionId
end

function ZO_ActiveSkillData:GetCurrentMorphSlot()
    return self.currentMorphSlot
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

--------------------------
-- Crafted Active Skill --
--------------------------

ZO_CraftedActiveSkillData = ZO_SkillData:Subclass()

-- Begin overriding methods in ZO_SkillData --

function ZO_CraftedActiveSkillData:Initialize()
    -- Overridding ZO_SkillData:Initialize cause we don't have multiple progressions or progression pools
    self:InitializeUpdateStatus()
end

function ZO_CraftedActiveSkillData:Reset()
    self.skillProgressionData = nil
end

function ZO_CraftedActiveSkillData:BuildStaticData(skillLineData, skillIndex)
    ZO_SkillData.BuildStaticData(self, skillLineData, skillIndex)

    self.skillLineData, self.skillIndex = skillLineData, skillIndex
    local skillLineId = self.skillLineData:GetId()

    local skillType, skillLineIndex = skillLineData:GetIndices()
    self.isUltimate = IsSkillAbilityUltimate(skillType, skillLineIndex, skillIndex)
    self.craftedAbilityId = GetCraftedAbilitySkillCraftedAbilityId(skillType, skillLineIndex, skillIndex)

    -- Point allocator created on demand in GetPointAllocator
    self.skillProgressionData = ZO_CraftedActiveSkillProgressionData:New()
    self.skillProgressionData:BuildStaticData(self)

    -- Don't mark a skill new during init
    self.canBeMarkedAsUpdated = false
    self:SetUpdatedStatusByType(ZO_SKILL_DATA_NEW_STATE.SKILL_LINE, false)
end

function ZO_CraftedActiveSkillData:RefreshDynamicData(refreshChildren)
    local wasPurchased = self.isPurchased
    -- Don't let base class refresh children since we have a special setup with only one progression
    local DO_NOT_REFRESH_CHILDREN = false
    ZO_SkillData.RefreshDynamicData(self, DO_NOT_REFRESH_CHILDREN)

    if self.canBeMarkedAsUpdated then
        if wasPurchased ~= self.isPurchased then
            self:SetUpdatedStatusByType(ZO_SKILL_DATA_NEW_STATE.CRAFTED_ABILITY, true)
        end
    end
    self.canBeMarkedAsUpdated = true

    if refreshChildren then
        self.skillProgressionData:RefreshDynamicData(refreshChildren)
    end
end

function ZO_CraftedActiveSkillData:IsAdvised()
    return false
end

function ZO_CraftedActiveSkillData:GetProgressionData(skillProgressionKey)
    -- there's only one progression, so key is ignored
    return self.skillProgressionData
end

function ZO_CraftedActiveSkillData:GetPointAllocator()
    if not self.noActionsPointAllocator then
        self.noActionsPointAllocator = SKILL_POINT_ALLOCATION_MANAGER:GenerateNoActionsAllocator(self)
    end
    return self.noActionsPointAllocator
end

function ZO_CraftedActiveSkillData:CanPointAllocationsBeAltered(isFullRespec)
    return false
end

-- End overriding methods in ZO_SkillData --

-- Begin implementing methods in ZO_SkillData_Base --

function ZO_CraftedActiveSkillData:IsPassive()
    return false
end

function ZO_CraftedActiveSkillData:IsUltimate()
    return self.isUltimate
end

function ZO_CraftedActiveSkillData:IsCraftedAbility()
    return true
end

function ZO_CraftedActiveSkillData:IsHidden()
    return not self:IsPurchased()
end

function ZO_CraftedActiveSkillData:HasPointsToClear()
    return false
end

function ZO_CraftedActiveSkillData:GetHeaderText()
    if self:IsUltimate() then
        return GetString(SI_SKILLS_ULTIMATE_ABILITIES)
    else
        return GetString(SI_SKILLS_ACTIVE_ABILITIES)
    end
end

function ZO_CraftedActiveSkillData:GetCurrentSkillProgressionKey()
    return CRAFTED_PROGRESSION_KEY
end

function ZO_CraftedActiveSkillData:GetNumPointsAllocated()
    return 0
end

-- End implementing methods in ZO_SkillData_Base --

function ZO_CraftedActiveSkillData:GetCraftedAbilityId()
    return self.craftedAbilityId
end

-------------------
-- Passive Skill --
-------------------

ZO_PassiveSkillData = ZO_SkillData:Subclass()

-- Begin overriding methods in ZO_SkillData --

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

-- End overriding methods in ZO_SkillData --

-- Begin implementing methods in ZO_SkillData_Base --

function ZO_PassiveSkillData:IsPassive()
    return true
end

function ZO_PassiveSkillData:IsUltimate()
    return false
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

function ZO_PassiveSkillData:GetHeaderText()
    return GetString(SI_SKILLS_PASSIVE_ABILITIES)
end

function ZO_PassiveSkillData:HasPointsToClear(clearMorphsOnly)
    if not clearMorphsOnly and self:IsPurchased() then
        return self:GetCurrentRank() > 1 or not self:IsAutoGrant()
    end
    return false
end

-- End implementing methods in ZO_SkillData_Base --

function ZO_PassiveSkillData:GetNumRanks()
    return self.numRanks
end

function ZO_PassiveSkillData:GetCurrentRank()
    return self.currentRank
end

--1 based
function ZO_PassiveSkillData:GetRankData(rank)
    -- Alias
    return self:GetProgressionData(rank)
end

--[[
    A ZO_SkillLineData is an entry in ZO_SkillTypeData. A skill line has multiple skills to purchase and upgrade, denoted by ZO_SkillData objects.
--]]

----------------
-- Skill Line --
----------------

ZO_SkillLineData = ZO_SkillLineData_Base:Subclass()

-- Begin overriding methods in ZO_SkillLineData_Base --

function ZO_SkillLineData:Initialize()
    ZO_SkillLineData_Base.Initialize(self, SKILLS_DATA_MANAGER)
    self.orderedSkills = {}
    local IS_ACTIVE = false
    local IS_PASSIVE = true
    local IS_CRAFTED = true
    local IS_NOT_CRAFTED = false
    self.activeSkillMetaPool = ZO_MetaPool:New(SKILLS_DATA_MANAGER:GetSkillObjectPool(IS_ACTIVE, IS_NOT_CRAFTED))
    self.craftedActiveSkillMetaPool = ZO_MetaPool:New(SKILLS_DATA_MANAGER:GetSkillObjectPool(IS_ACTIVE, IS_CRAFTED))
    self.passiveSkillMetaPool = ZO_MetaPool:New(SKILLS_DATA_MANAGER:GetSkillObjectPool(IS_PASSIVE))
end

function ZO_SkillLineData:Reset()
    ZO_SkillLineData_Base.Reset(self)
    ZO_ClearNumericallyIndexedTable(self.orderedSkills)
    self.activeSkillMetaPool:ReleaseAllObjects()
    self.craftedActiveSkillMetaPool:ReleaseAllObjects()
    self.passiveSkillMetaPool:ReleaseAllObjects()
end

-- unique to Player skill lines
function ZO_SkillLineData:IsPlayerSkillLine()
    return true
end

function ZO_SkillLineData:IsAdvised()
    return self.isAdvised
end

-- End overriding methods in ZO_SkillLineData_Base --

-- Begin implementing methods in ZO_SkillLineData_Base --

function ZO_SkillLineData:BuildStaticData(skillTypeData, skillLineIndex)
    self.skillTypeData, self.skillLineIndex = skillTypeData, skillLineIndex
    local skillType = self.skillTypeData:GetSkillType()

    self.id = GetSkillLineId(skillType, skillLineIndex)
    self.orderingIndex = GetSkillLineOrderingIndex(skillType, skillLineIndex)

    self.name = GetSkillLineNameById(self.id)
    self.unlockText = GetSkillLineUnlockTextById(self.id)
    self.isWerewolf = IsWerewolfSkillLineById(self.id)
    self.craftingGrowthType = GetSkillLineCraftingGrowthTypeById(self.id)

    for skillIndex = 1, GetNumSkillAbilities(skillType, skillLineIndex) do
        local skillData
        local isPassive = IsSkillAbilityPassive(skillType, skillLineIndex, skillIndex)
        if isPassive then
            skillData = self.passiveSkillMetaPool:AcquireObject()
        else
            local isCraftedAbility = IsCraftedAbilitySkill(skillType, skillLineIndex, skillIndex)
            if isCraftedAbility then
                skillData = self.craftedActiveSkillMetaPool:AcquireObject()
            else
                skillData = self.activeSkillMetaPool:AcquireObject()
            end
        end

        skillData:BuildData(self, skillIndex)
        table.insert(self.orderedSkills, skillData)
    end

    self:InitializeNewState()
end

function ZO_SkillLineData:RefreshDynamicData(refreshChildren)
    local skillType, skillLineIndex = self:GetIndices()

    local wasAvailable = self:IsAvailable()

    self.currentRank, self.isAdvised, self.isActive, self.isDiscovered = GetSkillLineDynamicInfo(skillType, skillLineIndex)
    self.lastRankXP, self.nextRankXP, self.currentXP = GetSkillLineXPInfo(skillType, skillLineIndex)

    local isAvailable = self:IsAvailable()

    if wasAvailable ~= isAvailable then
        self:TryMarkNew(isAvailable)
    end

    if refreshChildren then
        for _, skillData in ipairs(self.orderedSkills) do
            skillData:RefreshDynamicData(refreshChildren)
        end
    end

    self:AllowMarkingNew()
end

function ZO_SkillLineData:GetName()
    return self.name
end

function ZO_SkillLineData:GetFormattedName()
    return zo_strformat(SI_SKILL_LINE_TOOLTIP_NAME, self.name)
end

function ZO_SkillLineData:GetUnlockText()
    return self.unlockText
end

function ZO_SkillLineData:GetOrderingIndex()
    return self.orderingIndex
end

function ZO_SkillLineData:IsDiscovered()
    return self.isDiscovered
end

function ZO_SkillLineData:IsActive()
    return self.isActive
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

function ZO_SkillLineData:GetNumSkills()
    return #self.orderedSkills
end

function ZO_SkillLineData:GetSkillDataByIndex(skillIndex)
    return self.orderedSkills[skillIndex]
end

function ZO_SkillLineData:SkillIterator(skillFilterFunctions)
    return ZO_FilteredNumericallyIndexedTableIterator(self.orderedSkills, skillFilterFunctions)
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

-- End implementing methods in ZO_SkillLineData_Base --

function ZO_SkillLineData:IsWerewolf()
    return self.isWerewolf
end

function ZO_SkillLineData:GetCraftingGrowthType()
    return self.craftingGrowthType
end

function ZO_SkillLineData:GetFormattedNameWithNumPointsAllocated()
    local numPointsAllocated = SKILL_POINT_ALLOCATION_MANAGER:GetNumPointsAllocatedInSkillLine(self)
    if numPointsAllocated > 0 then
        return zo_strformat(SI_SKILLS_ENTRY_LINE_NAME_FORMAT_WITH_ALLOCATED_POINTS, self.name, numPointsAllocated)
    else
        return self:GetFormattedName()
    end
end

function ZO_SkillLineData:SetAdvised(advised)
    local skillType, skillLineIndex = self:GetIndices()
    SetAdviseSkillLine(skillType, skillLineIndex, advised)
end
