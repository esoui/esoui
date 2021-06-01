-- Helper object for object pool data --

ZO_PooledSkillDataObject = ZO_InitializingObject:Subclass()

function ZO_PooledSkillDataObject:Reset()
    -- Can be overridden
end

function ZO_PooledSkillDataObject:BuildData(...)
    self:BuildStaticData(...)
    self:RefreshDynamicData()
end

function ZO_PooledSkillDataObject:BuildStaticData(...)
    assert(false) -- Must be overridden
end

function ZO_PooledSkillDataObject:RefreshDynamicData(...)
    -- Can be overridden
end

--[[
    A ZO_SkillProgressionData_Base is an entry in a ZO_SkillData_Base. Each one describes a step in the progression for upgrading the skill.
--]]

-----------------------
-- Skill Progression --
-----------------------

ZO_SkillProgressionData_Base = ZO_PooledSkillDataObject:Subclass()

function ZO_SkillProgressionData_Base:New(...)
    return ZO_PooledSkillDataObject.New(self, ...)
end

function ZO_SkillProgressionData_Base:Reset()
    self.abilityId = nil
end

function ZO_SkillProgressionData_Base:BuildStaticData(skillData, skillProgressionKey)
    self.skillData, self.skillProgressionKey = skillData, skillProgressionKey
end

function ZO_SkillProgressionData_Base:RefreshDynamicData(...)
    --Nothing to refresh, for now
end

function ZO_SkillProgressionData_Base:GetIndices()
    local skillType, skillLineIndex, skillIndex = self.skillData:GetIndices()
    return skillType, skillLineIndex, skillIndex, self.skillProgressionKey
end

-- Actives and passives progress differently.
-- In actives, progression key corresponds to morph slots.
-- In passives, progression key corresponds to rank.
function ZO_SkillProgressionData_Base:GetSkillProgressionKey()
    return self.skillProgressionKey
end

function ZO_SkillProgressionData_Base:GetSkillData()
    return self.skillData
end

function ZO_SkillProgressionData_Base:GetAbilityId()
    return self.abilityId
end

function ZO_SkillProgressionData_Base:SetAbilityId(abilityId)
    self.abilityId = abilityId
    self.name = GetAbilityName(abilityId)
    self.icon = GetAbilityIcon(abilityId)
end

function ZO_SkillProgressionData_Base:GetName()
    return self.name
end

function ZO_SkillProgressionData_Base:GetFormattedName(formatter)
    return ZO_CachedStrFormat(formatter or SI_ABILITY_NAME, self.name)
end

function ZO_SkillProgressionData_Base:GetDetailedName()
    assert(false) -- Must be overridden
end

function ZO_SkillProgressionData_Base:GetDetailedGamepadName()
    return self:GetDetailedName() -- can be overridden to change how the name is formatted in the gamepad UI
end

function ZO_SkillProgressionData_Base:GetIcon()
    return self.icon
end

function ZO_SkillProgressionData_Base:IsPassive()
    return self:GetSkillData():IsPassive()
end

function ZO_SkillProgressionData_Base:IsActive()
    return not self:IsPassive()
end

function ZO_SkillProgressionData_Base:IsUltimate()
    return self:GetSkillData():IsUltimate()
end

function ZO_SkillProgressionData_Base:IsUnlocked()
    return self.skillData:MeetsLinePurchaseRequirement()
end

function ZO_SkillProgressionData_Base:IsLocked()
    return not self:IsUnlocked()
end

function ZO_SkillProgressionData_Base:IsAdvised()
    assert(false) -- Must be overridden
end

function ZO_SkillProgressionData_Base:HasRankData()
    assert(false) -- Must be overridden
end

function ZO_SkillProgressionData_Base:SetKeyboardTooltip()
    assert(false) -- Must be overridden
end

function ZO_SkillProgressionData_Base:TryPickup()
    -- can be overridden, return true if the skill is picked up
    return false
end


--[[
    A ZO_SkillData_Base is an entry in a ZO_SkillLineData. A skill can be upgraded to various levels, denoted by ZO_SkillProgressionData objects.
    ZO_SkillData_Base, unlike some other skill data objects, is implemented as
    a pure interface. avoid putting any logic in here, if you can avoid it.
--]]

-----------
-- Skill --
-----------

ZO_SkillData_Base = ZO_PooledSkillDataObject:Subclass()

function ZO_SkillData_Base:Reset()
    assert(false)
end

function ZO_SkillData_Base:BuildStaticData(skillLineData, skillIndex)
    assert(false)
end

function ZO_SkillData_Base:RefreshDynamicData(refreshChildren)
    assert(false)
end

function ZO_SkillData_Base:GetSkillLineData()
    assert(false)
end

function ZO_SkillData_Base:IsPassive()
    assert(false)
end

function ZO_SkillData_Base:IsActive()
    assert(false)
end

function ZO_SkillData_Base:IsUltimate()
    assert(false)
end

function ZO_SkillData_Base:GetLineRankNeededToPurchase()
    assert(false)
end

function ZO_SkillData_Base:MeetsLinePurchaseRequirement()
    assert(false)
end

function ZO_SkillData_Base:IsAutoGrant()
    assert(false)
end

function ZO_SkillData_Base:IsPurchased()
    assert(false)
end

function ZO_SkillData_Base:IsAdvised()
    assert(false)
end

function ZO_SkillData_Base:HasPointsToClear(clearMorphsOnly)
    assert(false) -- Must be overridden
end

function ZO_SkillData_Base:GetProgressionData(skillProgressionKey)
    assert(false)
end

function ZO_SkillData_Base:GetHeaderText()
    assert(false) -- Must be overridden
end

function ZO_SkillData_Base:GetCurrentSkillProgressionKey()
    assert(false) -- Must be overridden
end

function ZO_SkillData_Base:GetNumPointsAllocated()
    assert(false) -- Must be overridden
end

function ZO_SkillData_Base:GetCurrentProgressionData()
    assert(false)
end

function ZO_SkillData_Base:GetPointAllocator()
    assert(false)
end

function ZO_SkillData_Base:GetPointAllocatorProgressionData()
    assert(false)
end

function ZO_SkillData_Base:HasUpdatedStatus()
    assert(false)
end

function ZO_SkillData_Base:SetHasUpdatedStatus(hasUpdatedStatus)
    assert(false)
end

function ZO_SkillData_Base:ClearUpdate()
    assert(false)
end

function ZO_SkillData_Base:CanPointAllocationsBeAltered(isFullRespec)
    assert(false)
end

-- Optional overrides
function ZO_SkillData_Base:IsPlayerSkill()
    return false
end

function ZO_SkillData_Base:IsCompanionSkill()
    return false
end

-- convenience methods
function ZO_SkillData_Base:GetSlotOnCurrentHotbar()
    return ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar():FindSlotMatchingSkill(self)
end


--[[
    A ZO_SkillLineData_Base is an entry in ZO_SkillTypeData. A skill line has multiple skills to purchase and upgrade, denoted by ZO_SkillData objects.
--]]

----------------
-- Skill Line --
----------------

ZO_SkillLineData_Base = ZO_PooledSkillDataObject:Subclass()

-- abstract methods (must be overridden)
function ZO_SkillLineData_Base:BuildStaticData(skillTypeData, skillLineIndex)
    assert(false)
end

function ZO_SkillLineData_Base:RefreshDynamicData(refreshChildren)
    assert(false)
end

function ZO_SkillLineData_Base:GetId()
    return self.id
end

function ZO_SkillLineData_Base:GetName()
    assert(false)
end

function ZO_SkillLineData_Base:GetUnlockText()
    assert(false)
end

function ZO_SkillLineData_Base:GetOrderingIndex()
    assert(false)
end

function ZO_SkillLineData_Base:GetAnnounceIcon()
    return GetSkillLineAnnouncementIconById(self.id)
end

function ZO_SkillLineData_Base:GetDetailedIcon()
    return GetSkillLineDetailedIconById(self.id)
end

function ZO_SkillLineData_Base:IsDiscovered()
    assert(false)
end

function ZO_SkillLineData_Base:IsActive()
    assert(false)
end

function ZO_SkillLineData_Base:GetCurrentRank()
    assert(false)
end

function ZO_SkillLineData_Base:GetLastRankXP()
    assert(false)
end

function ZO_SkillLineData_Base:GetNextRankXP()
    assert(false)
end

function ZO_SkillLineData_Base:GetCurrentRankXP()
    assert(false)
end

function ZO_SkillLineData_Base:GetNumSkills()
    assert(false)
end

function ZO_SkillLineData_Base:GetSkillDataByIndex(skillIndex)
    assert(false)
end

function ZO_SkillLineData_Base:SkillIterator(skillFilterFunctions)
    assert(false)
end

function ZO_SkillLineData_Base:AnySkillHasUpdatedStatus()
    assert(false)
end

-- optional methods (can be overidden)
function ZO_SkillLineData_Base:IsPlayerSkillLine()
    return false
end

function ZO_SkillLineData_Base:IsCompanionSkillLine()
    return false
end

function ZO_SkillLineData_Base:IsAdvised()
    return false
end

-- additional state
function ZO_SkillLineData_Base:Initialize(dataManager)
    self.dataManager = dataManager
    self.skillsWithUpdatesCache = {}
end

function ZO_SkillLineData_Base:Reset()
    ZO_ClearTable(self.skillsWithUpdatesCache)
end

function ZO_SkillLineData_Base:InitializeNewState()
    self.isNew = false
    self.canMarkNew = false -- prevent the first refresh from marking a skill line as "new"
end

function ZO_SkillLineData_Base:IsNew()
    return self.isNew
end

function ZO_SkillLineData_Base:SetNew(isNew)
    if self.isNew ~= isNew then
        self.isNew = isNew
        self.dataManager:OnSkillLineNewStatusChanged(self)
    end
end

function ZO_SkillLineData_Base:TryMarkNew(isNew)
    if self.canMarkNew then
        self:SetNew(isNew)
    end
end

function ZO_SkillLineData_Base:AllowMarkingNew()
    self.canMarkNew = true
end

function ZO_SkillLineData_Base:ClearNew()
    self:SetNew(false)
end

function ZO_SkillLineData_Base:OnSkillDataUpdateStatusChanged(skillData)
    local hasUpdatedStatus = skillData:HasUpdatedStatus()
    self.skillsWithUpdatesCache[skillData] = hasUpdatedStatus or nil
    self.dataManager:OnSkillLineNewStatusChanged(self)
end

function ZO_SkillLineData_Base:AnySkillHasUpdatedStatus()
    return not ZO_IsTableEmpty(self.skillsWithUpdatesCache)
end

-- helpers

function ZO_SkillLineData_Base:GetFormattedName()
    return ZO_CachedStrFormat(SI_SKILLS_ENTRY_LINE_NAME_FORMAT, self:GetName())
end

function ZO_SkillLineData_Base:IsAvailable()
    return self:IsDiscovered() and self:IsActive()
end

function ZO_SkillLineData_Base:IsAvailableOrAdvised()
    return self:IsAvailable() or self:IsAdvised()
end

function ZO_SkillLineData_Base:GetRankXPValues()
    return self:GetLastRankXP(), self:GetNextRankXP(), self:GetCurrentRankXP()
end

function ZO_SkillLineData_Base:IsSkillLineOrAbilitiesNew()
    return self:IsNew() or self:AnySkillHasUpdatedStatus()
end

--[[
    A ZO_SkillTypeData is the overarching categorization of skill lines. A skill type can be subcategorized down into multiple skill lines, denoted by ZO_SkillLineData_Base objects.
--]]

----------------
-- Skill Type --
----------------

ZO_SkillTypeData = ZO_PooledSkillDataObject:Subclass()

function ZO_SkillTypeData:Initialize()
    self.orderedSkillLines = {}
end

function ZO_SkillTypeData:GetNumSkillLines()
    -- override me
    assert(false)
end

function ZO_SkillTypeData:Reset()
    ZO_ClearNumericallyIndexedTable(self.orderedSkillLines)
    -- skill line datas should be released on the data manager level
end

do
    assert(SKILL_TYPE_MAX_VALUE == 9, "Update this table")

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
    end
end

function ZO_SkillTypeData:AddOrderedSkillLineData(skillLineData)
    table.insert(self.orderedSkillLines, skillLineData)
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

function ZO_SkillTypeData:GetSkillLineDataByIndex(skillLineIndex)
    return self.orderedSkillLines[skillLineIndex]
end

function ZO_SkillTypeData:SkillLineIterator(skillLineFilterFunctions)
    return ZO_FilteredNumericallyIndexedTableIterator(self.orderedSkillLines, skillLineFilterFunctions)
end

function ZO_SkillTypeData:AreAnySkillLinesNew()
    for _, skillLineData in self:SkillLineIterator({ ZO_SkillLineData_Base.IsNew }) do
        return true
    end
    return false
end

function ZO_SkillTypeData:AreAnySkillLinesOrAbilitiesNew()
    for _, skillLineData in self:SkillLineIterator({ ZO_SkillLineData_Base.IsSkillLineOrAbilitiesNew } ) do
        return true
    end
    return false
end


