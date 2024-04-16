--[[
    This file mirrors PlayerSkillsData.lua in many ways, before editing or
    removing methods please ensure there is a stable interface between the two.
]]--


local COMPANION_PROGRESSION_KEY = nil -- should we consider using a sentinel value instead?

-----------------------
-- Skill Progression --
-----------------------

ZO_CompanionSkillProgressionData = ZO_SkillProgressionData_Base:Subclass()

-- Begin overriding methods in ZO_SkillProgressionData_Base --

function ZO_CompanionSkillProgressionData:BuildStaticData(skillData)
    ZO_SkillProgressionData_Base.BuildStaticData(self, skillData, COMPANION_PROGRESSION_KEY)
    self:SetAbilityId(self.skillData:GetAbilityId())
end

function ZO_CompanionSkillProgressionData:IsUnlocked()
    -- unlocked and purchased are synonymous with companion skills
    return self.skillData:IsPurchased()
end

function ZO_CompanionSkillProgressionData:TryPickup()
    PickupCompanionAbilityById(self:GetAbilityId())
end

-- End overriding methods in ZO_SkillProgressionData_Base --

-- Begin implementing methods in ZO_SkillProgressionData_Base --

function ZO_CompanionSkillProgressionData:IsAdvised()
    return false
end

function ZO_CompanionSkillProgressionData:SetKeyboardTooltip(tooltipControl, unusedShowSkillPointCost, unusedShowUpgradeText, unusedShowAdvised, unusedShowBadMorph)
    tooltipControl:SetCompanionSkill(self:GetAbilityId())
end

-- End implementing methods in ZO_SkillProgressionData_Base --

--[[
    A ZO_CompanionSkillData is an entry in a ZO_SkillLineData. A skill can be upgraded to various levels, denoted by ZO_CompanionSkillProgressionData objects.
--]]

-----------
-- Skill --
-----------

ZO_CompanionSkillData = ZO_SkillData_Base:Subclass()

-- Begin implementing methods in ZO_SkillData_Base --

function ZO_CompanionSkillData:Reset()
    self.skillProgressionData = nil
end

function ZO_CompanionSkillData:BuildStaticData(skillLineData, skillIndex)
    self.skillLineData, self.skillIndex = skillLineData, skillIndex
    local skillLineId = self.skillLineData:GetId()
    self.abilityId = GetCompanionAbilityId(skillLineId, skillIndex)

    self.skillProgressionData = ZO_CompanionSkillProgressionData:New()
    self.skillProgressionData:BuildStaticData(self)

    -- Don't mark a skill new during init
    self.canBeMarkedAsUpdated = false
    self:SetHasUpdatedStatus(false)
end

function ZO_CompanionSkillData:RefreshDynamicData(refreshChildren)
    local wasPurchased = self.isPurchased
    self.isPurchased = IsCompanionAbilityUnlocked(self.abilityId)

    if self.canBeMarkedAsUpdated then
        if wasPurchased ~= self.isPurchased then
            self:SetHasUpdatedStatus(true)
        end
    end
    self.canBeMarkedAsUpdated = true

    if refreshChildren then
        self.skillProgressionData:RefreshDynamicData(refreshChildren)
    end
end

function ZO_CompanionSkillData:GetSkillLineData()
    return self.skillLineData
end

function ZO_CompanionSkillData:IsPassive()
    return IsAbilityPassive(self.abilityId)
end

function ZO_CompanionSkillData:IsActive()
    return not self:IsPassive()
end

function ZO_CompanionSkillData:IsUltimate()
    return IsAbilityUltimate(self.abilityId)
end

function ZO_CompanionSkillData:MeetsLinePurchaseRequirement()
    return true
end

function ZO_CompanionSkillData:IsPurchased()
    return self.isPurchased
end

function ZO_CompanionSkillData:IsAdvised()
    return false
end

function ZO_CompanionSkillData:HasPointsToClear()
    return false
end

function ZO_CompanionSkillData:GetProgressionData(skillProgressionKey)
    -- there's only one progression, so key is ignored
    return self.skillProgressionData
end

function ZO_CompanionSkillData:GetHeaderText()
    if self:IsUltimate() then
        return GetString(SI_SKILLS_ULTIMATE_ABILITIES)
    elseif self:IsPassive() then
        return GetString(SI_SKILLS_PASSIVE_ABILITIES)
    else
        return GetString(SI_SKILLS_ACTIVE_ABILITIES)
    end
end

function ZO_CompanionSkillData:GetNumPointsAllocated()
    return 0
end

function ZO_CompanionSkillData:GetCurrentSkillProgressionKey()
    return COMPANION_PROGRESSION_KEY
end

function ZO_CompanionSkillData:GetCurrentProgressionData()
    return self:GetProgressionData(self:GetCurrentSkillProgressionKey())
end

function ZO_CompanionSkillData:GetPointAllocator()
    if not self.noActionsPointAllocator then
        self.noActionsPointAllocator = SKILL_POINT_ALLOCATION_MANAGER:GenerateNoActionsAllocator(self)
    end
    return self.noActionsPointAllocator
end

function ZO_CompanionSkillData:GetPointAllocatorProgressionData()
    return self:GetPointAllocator():GetProgressionData()
end

function ZO_CompanionSkillData:HasUpdatedStatus()
    return self.hasUpdatedStatus
end

function ZO_CompanionSkillData:SetHasUpdatedStatus(hasUpdatedStatus)
    if hasUpdatedStatus then
        -- we only use updated status for a single CSA, so we don't really need
        -- to keep this state around. we'll keep the flag to match the base skills
        -- API but we'll reset it immediately after triggering the callbacks we
        -- want.
        self.hasUpdatedStatus = true
        COMPANION_SKILLS_DATA_MANAGER:OnCompanionSkillUpdateStatusChanged(self)
        self.hasUpdatedStatus = false
    end
end

function ZO_CompanionSkillData:ClearUpdate()
    self:SetHasUpdatedStatus(false)
end

function ZO_CompanionSkillData:CanPointAllocationsBeAltered(isFullRespec)
    return false
end

function ZO_CompanionSkillData:IsCompanionSkill()
    return true
end

-- End implementing methods in ZO_SkillData_Base --

function ZO_CompanionSkillData:GetAbilityId()
    return self.abilityId
end

function ZO_CompanionSkillData:GetCompanionIndices()
    return self.skillLineData:GetId(), self:GetAbilityId()
end

function ZO_CompanionSkillData:GetSkillLineRankRequired()
    return GetCompanionAbilityRankRequired(self.abilityId)
end


--[[
    A ZO_CompanionSkillLineData is an entry in ZO_SkillTypeData. A skill line has multiple skills to purchase and upgrade, denoted by ZO_CompanionSkillData objects.
--]]

----------------
-- Skill Line --
----------------

ZO_CompanionSkillLineData = ZO_SkillLineData_Base:Subclass()

-- Begin overriding methods in ZO_SkillLineData_Base --

function ZO_CompanionSkillLineData:Initialize()
    ZO_SkillLineData_Base.Initialize(self, COMPANION_SKILLS_DATA_MANAGER)
    self.orderedSkills = {}
    self.skillMetaPool = ZO_MetaPool:New(COMPANION_SKILLS_DATA_MANAGER:GetSkillObjectPool())
end

function ZO_CompanionSkillLineData:Reset()
    ZO_SkillLineData_Base.Reset(self)
    ZO_ClearNumericallyIndexedTable(self.orderedSkills)
    self.skillMetaPool:ReleaseAllObjects()
end

-- unique to Companion skill lines
function ZO_CompanionSkillLineData:IsCompanionSkillLine()
    return true
end

function ZO_CompanionSkillLineData:IsAdvised()
    -- all companion skill lines should either be available, (in which case they are visible as unlocked in the UI) or advised (so they're still in the UI, just with an unlock hint)
    -- some shared code assumes these are mutually exclusive so we'll only mark things as advised if they're not available
    return not self:IsAvailable()
end

-- End overriding methods in ZO_SkillLineData_Base --

-- Begin implementing methods in ZO_SkillLineData_Base --

function ZO_CompanionSkillLineData:BuildStaticData(skillTypeData, skillLineIndex)
    self.skillTypeData, self.skillLineIndex = skillTypeData, skillLineIndex
    self.id = GetCompanionSkillLineId(skillTypeData:GetSkillType(), skillLineIndex)

    self.name = GetCompanionSkillLineNameById(self.id)
    self.unlockText = GetSkillLineUnlockTextById(self.id)

    for skillIndex = 1, GetNumAbilitiesInCompanionSkillLine(self.id) do
        local skillData = self.skillMetaPool:AcquireObject()
        skillData:BuildStaticData(self, skillIndex)
        self.dataManager:MapAbilityIdToSkill(skillData:GetAbilityId(), skillData)
        table.insert(self.orderedSkills, skillData)
    end

    self:InitializeNewState()
end

function ZO_CompanionSkillLineData:RefreshDynamicData(refreshChildren)
    local wasAvailable = self:IsAvailable()

    self.currentRank, self.isActive, self.isDiscovered = GetCompanionSkillLineDynamicInfo(self.id)
    self.lastRankXP, self.nextRankXP, self.currentXP = GetCompanionSkillLineXPInfo(self.id)

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

function ZO_CompanionSkillLineData:GetName()
    return self.name
end

function ZO_CompanionSkillLineData:GetUnlockText()
    return self.unlockText
end

function ZO_CompanionSkillLineData:GetOrderingIndex()
    return 0
end

function ZO_CompanionSkillLineData:IsDiscovered()
    return self.isDiscovered
end

function ZO_CompanionSkillLineData:IsActive()
    return self.isActive
end

function ZO_CompanionSkillLineData:GetCurrentRank()
    return self.currentRank
end

function ZO_CompanionSkillLineData:GetLastRankXP()
    return self.lastRankXP
end

function ZO_CompanionSkillLineData:GetNextRankXP()
    return self.nextRankXP
end

function ZO_CompanionSkillLineData:GetCurrentRankXP()
    return self.currentXP
end

function ZO_CompanionSkillLineData:GetNumSkills()
    return #self.orderedSkills
end

function ZO_CompanionSkillLineData:GetSkillDataByIndex(skillIndex)
    return self.orderedSkills[skillIndex]
end

function ZO_CompanionSkillLineData:SkillIterator(skillFilterFunctions)
    return ZO_FilteredNumericallyIndexedTableIterator(self.orderedSkills, skillFilterFunctions)
end

-- End implementing methods in ZO_SkillLineData_Base --

function ZO_CompanionSkillLineData:GetSkillTypeData()
    return self.skillTypeData
end

function ZO_CompanionSkillLineData:GetSkillLineIndex()
    return self.skillLineIndex
end

function ZO_CompanionSkillLineData:GetIndices()
    return self.skillTypeData:GetSkillType(), self.skillLineIndex
end