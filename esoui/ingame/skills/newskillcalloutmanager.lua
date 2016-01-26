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
            
            local skillLineName = GetSkillLineInfo(skillType, skillLineIndex)
            local abilityList = self.currentSkillList[skillLineName]
            if abilityList then 
                for abilityIndex = 1, GetNumSkillAbilities(skillType, skillLineIndex) do
                    if abilityList[abilityIndex] then
                        abilityList[abilityIndex].isNew = false --initialize all news to false
                    end
                end
            end
        end
    end
end

function ZO_NewSkillCalloutManager:UpdateAbility(skillType, skillLineIndex, abilityIndex)
    local skillLineName, currentSkillRank = GetSkillLineInfo(skillType, skillLineIndex)
    local abilityList = self.currentSkillList[skillLineName]
    if abilityList ~= nil then
        local _,_,earnedRank,_,_,_,progressionIndex = GetSkillAbilityInfo(skillType, skillLineIndex, abilityIndex)
        local atMorph = progressionIndex and select(4, GetAbilityProgressionXPInfo(progressionIndex))

        if abilityList[abilityIndex] and not abilityList[abilityIndex].isNew then
            if atMorph and not abilityList[abilityIndex].atMorph then
                abilityList[abilityIndex].atMorph = true
                abilityList[abilityIndex].isNew = true
            end
        end
        if not abilityList[abilityIndex] and earnedRank <= currentSkillRank then
            abilityList[abilityIndex] =
            {
                atMorph = atMorph,
                isNew = true,       --new ability that came with new skill line
            }                  
        end
    end
end

function ZO_NewSkillCalloutManager:UpdateSkillLine(skillType, skillLineIndex)
    local skillLineName = GetSkillLineInfo(skillType, skillLineIndex)
    local abilityList = self.currentSkillList[skillLineName]

    if abilityList == nil then  -- add new skill line to list
        self:AddSkillLineToList(skillType, skillLineIndex)
    else                        --mark unlocked abilities new
        for abilityIndex = 1, GetNumSkillAbilities(skillType, skillLineIndex) do  
            self:UpdateAbility(skillType, skillLineIndex, abilityIndex)
        end
    end
end

function ZO_NewSkillCalloutManager:AddSkillLineToList(skillType, skillLineIndex)
    local abilityList = {}
    local skillLineName, currentSkillRank = GetSkillLineInfo(skillType, skillLineIndex)
    for abilityIndex = 1, GetNumSkillAbilities(skillType, skillLineIndex) do  

        local _,_,earnedRank,_,_,_,progressionIndex = GetSkillAbilityInfo(skillType, skillLineIndex, abilityIndex)
        local atMorph = progressionIndex and select(4, GetAbilityProgressionXPInfo(progressionIndex))
        local unlocked = earnedRank <= currentSkillRank

        if unlocked then
            abilityList[abilityIndex] =
            {
                atMorph = atMorph,
                isNew = unlocked,       --new ability that came with new skill line
            }
        end
    end
    self.currentSkillList[skillLineName] = abilityList
end

function ZO_NewSkillCalloutManager:AreAnySkillsNew()
    for skillType = 1, GetNumSkillTypes() do
        for skillLineIndex = 1, GetNumSkillLines(skillType) do
            if self:IsSkillLineNew(skillType, skillLineIndex) then
                return true
            end
        end
    end

    return false
end

function ZO_NewSkillCalloutManager:IsSkillLineNew(skillType, skillLineIndex)
    
    local skillLineName = GetSkillLineInfo(skillType, skillLineIndex)
    local abilityList = self.currentSkillList[skillLineName]

    if abilityList == nil then
        return true
    end

    for abilityIndex = 1, GetNumSkillAbilities(skillType, skillLineIndex) do
        if self:IsAbilityNew(skillType, skillLineIndex, abilityIndex) then
            return true     --a skill line got a new ability
        end
    end

    return false
end

function ZO_NewSkillCalloutManager:IsAbilityNew(skillType, skillLineIndex, abilityIndex)
    local skillLineName = GetSkillLineInfo(skillType, skillLineIndex)
    local abilityList = self.currentSkillList[skillLineName]

    if abilityList ~= nil and abilityList[abilityIndex] then
        if abilityList[abilityIndex].isNew and abilityList[abilityIndex].atMorph then
            return true -- abilities are now only new if they are at their morph stage
        end
    end

    return false
end

function ZO_NewSkillCalloutManager:ClearNewStatusOnAbilities(skillType, skillLineIndex, abilityIndex)
    local skillLineName = GetSkillLineInfo(skillType, skillLineIndex)
    local abilityList = self.currentSkillList[skillLineName]

    if abilityList ~= nil and abilityList[abilityIndex] then
        abilityList[abilityIndex].isNew = false
    end
end

NEW_SKILL_CALLOUTS = ZO_NewSkillCalloutManager:New()