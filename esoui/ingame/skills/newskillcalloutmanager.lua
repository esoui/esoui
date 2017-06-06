ZO_NewSkillCalloutManager = ZO_CallbackObject:Subclass()

function ZO_NewSkillCalloutManager:New(...)
    local newSkillCalloutManager = ZO_CallbackObject.New(self)
    newSkillCalloutManager:Initialize(...)
    return newSkillCalloutManager
end

function ZO_NewSkillCalloutManager:Initialize()
    local namespace = tostring(self)

    self:InitializeSkillList()

    local function OnSkillLineUpdate(eventCode, skillType, skillLineIndex)
        self:UpdateSkillLine(skillType, skillLineIndex)
        self:FireCallbacks("NewSkillsUpdate")
    end

    local function OnAbilityRankUpdate(eventCode, progressionIndex, rank, maxRank, morph)
        local skillType,skillLineIndex,abilityIndex = GetSkillAbilityIndicesFromProgressionIndex(progressionIndex)
        self:UpdateAbility(skillType, skillLineIndex, abilityIndex)
        self:FireCallbacks("NewSkillsUpdate")
    end

    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_SKILL_LINE_ADDED, OnSkillLineUpdate)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_SKILL_RANK_UPDATE, OnSkillLineUpdate)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_ABILITY_PROGRESSION_RANK_UPDATE, OnAbilityRankUpdate)
end

function ZO_NewSkillCalloutManager:InitializeSkillList()
    self.currentSkillList = {}

    for skillType = 1, GetNumSkillTypes() do
        for skillLineIndex = 1, GetNumSkillLines(skillType) do 
            self:AddSkillLineToList(skillType, skillLineIndex)
            
            -- Initialize all "recently updated" flags to false
            local skillLineName = GetSkillLineInfo(skillType, skillLineIndex)
            local entry = self:GetSkillLineEntry(skillLineName)
            if entry then
                entry.isNew = false

                if entry.abilityList then
                    for abilityIndex = 1, GetNumSkillAbilities(skillType, skillLineIndex) do
                        if entry.abilityList[abilityIndex] then
                            entry.abilityList[abilityIndex].isNewlyAvailable = false
                        end
                    end
                end
            end
        end
    end
end

function ZO_NewSkillCalloutManager:UpdateAbility(skillType, skillLineIndex, abilityIndex)
    local skillLineName, currentSkillRank = GetSkillLineInfo(skillType, skillLineIndex)
    local abilityList = self:GetAbilityList(skillLineName)
    if abilityList ~= nil then
        local _,_,earnedRank,_,_,_,progressionIndex = GetSkillAbilityInfo(skillType, skillLineIndex, abilityIndex)
        local atMorph = progressionIndex and select(4, GetAbilityProgressionXPInfo(progressionIndex))

        if abilityList[abilityIndex] then
            if atMorph and not abilityList[abilityIndex].atMorph then
                abilityList[abilityIndex].atMorph = true
                abilityList[abilityIndex].isNewlyAvailable = true  -- remark this as updated to better highlight that a morph is now available
            end
        end
        if not abilityList[abilityIndex] and earnedRank <= currentSkillRank then
            abilityList[abilityIndex] =
            {
                atMorph = atMorph,
                isNewlyAvailable = true,       --new ability that came with new skill line
            }                  
        end
    end
end

function ZO_NewSkillCalloutManager:UpdateSkillLine(skillType, skillLineIndex)
    local skillLineName = GetSkillLineInfo(skillType, skillLineIndex)
    local abilityList = self:GetAbilityList(skillLineName)

    if abilityList == nil then  -- add new skill line to list
        self:AddSkillLineToList(skillType, skillLineIndex)
    else                        --mark unlocked abilities new
        for abilityIndex = 1, GetNumSkillAbilities(skillType, skillLineIndex) do  
            self:UpdateAbility(skillType, skillLineIndex, abilityIndex)
        end
    end
end

function ZO_NewSkillCalloutManager:AddSkillLineToList(skillType, skillLineIndex)
    local skillLineName, currentSkillRank, discovered = GetSkillLineInfo(skillType, skillLineIndex)
    if not discovered then
        return
    end

    local abilityList = {}
    for abilityIndex = 1, GetNumSkillAbilities(skillType, skillLineIndex) do  

        local _,_,earnedRank,_,_,_,progressionIndex = GetSkillAbilityInfo(skillType, skillLineIndex, abilityIndex)
        local atMorph = progressionIndex and select(4, GetAbilityProgressionXPInfo(progressionIndex))
        local unlocked = earnedRank <= currentSkillRank

        if unlocked then
            abilityList[abilityIndex] =
            {
                atMorph = atMorph,
                isNewlyAvailable = unlocked,       --new ability that came with new skill line
            }
        end
    end

    self.currentSkillList[skillLineName] = {abilityList = abilityList, isNew = true}
end

function ZO_NewSkillCalloutManager:AreAnySkillLinesNew(includeAbilities)
    for skillType = 1, GetNumSkillTypes() do
        for skillLineIndex = 1, GetNumSkillLines(skillType) do
            if self:IsSkillLineNew(skillType, skillLineIndex, includeAbilities) then
                return true
            end
        end
    end

    return false
end

function ZO_NewSkillCalloutManager:AreAnySkillLinesInTypeNew(skillType, includeAbilities)
    for skillLineIndex = 1, GetNumSkillLines(skillType) do
        if self:IsSkillLineNew(skillType, skillLineIndex, includeAbilities) then
            return true
        end
    end

    return false
end

function ZO_NewSkillCalloutManager:IsSkillLineNew(skillType, skillLineIndex, includeAbilities)
    
    local skillLineName = GetSkillLineInfo(skillType, skillLineIndex)
    local entry = self:GetSkillLineEntry(skillLineName)

    if entry == nil then
        return false
    end

    if entry.isNew then
        return true
    end

    if includeAbilities then
        if entry.abilityList then
            for abilityIndex = 1, GetNumSkillAbilities(skillType, skillLineIndex) do
                if self:DoesAbilityHaveUpdates(skillType, skillLineIndex, abilityIndex) then
                    return true     --a skill line got a newly updated ability
                end
            end
        end
    end

    return false
end

function ZO_NewSkillCalloutManager:DoesAbilityHaveUpdates(skillType, skillLineIndex, abilityIndex)
    local skillLineName = GetSkillLineInfo(skillType, skillLineIndex)
    local abilityList = self:GetAbilityList(skillLineName)

    if abilityList ~= nil and abilityList[abilityIndex] then
        -- To be considered updated, the ability must be both newly available (unlocked) and morphable.  We don't treat as updated when first unlocked
        -- because that feels too spammy.
        if abilityList[abilityIndex].isNewlyAvailable and abilityList[abilityIndex].atMorph then
            return true
        end
    end

    return false
end

function ZO_NewSkillCalloutManager:ClearAbilityUpdatedStatus(skillType, skillLineIndex, abilityIndex)
    local skillLineName = GetSkillLineInfo(skillType, skillLineIndex)
    local abilityList = self:GetAbilityList(skillLineName)

    if abilityList ~= nil and abilityList[abilityIndex] and abilityList[abilityIndex].isNewlyAvailable then
        abilityList[abilityIndex].isNewlyAvailable = false
        self:FireCallbacks("OnAbilityUpdatedStatusChanged", skillType, skillLineIndex, abilityIndex)
    end
end

function ZO_NewSkillCalloutManager:ClearSkillLineNewStatus(skillType, skillLineIndex)
    local skillLineName = GetSkillLineInfo(skillType, skillLineIndex)
    local entry = self:GetSkillLineEntry(skillLineName)

    if entry ~= nil and entry.isNew then
        entry.isNew = false
        self:FireCallbacks("OnSkillLineNewStatusChanged", skillType, skillLineIndex)
    end
end

function ZO_NewSkillCalloutManager:GetSkillLineEntry(skillLineName)
    return self.currentSkillList[skillLineName]
end

function ZO_NewSkillCalloutManager:GetAbilityList(skillLineName)
    local skillLineEntry = self:GetSkillLineEntry(skillLineName)
    if skillLineEntry then
        return skillLineEntry.abilityList
    end

    return nil
end

NEW_SKILL_CALLOUTS = ZO_NewSkillCalloutManager:New()