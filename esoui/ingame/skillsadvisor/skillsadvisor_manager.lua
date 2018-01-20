--
--[[ SkillsAdvisor Singleton ]]--
--

ZO_SKILLS_ABILITY_PURCHASED = 1
ZO_SKILLS_ABILITY_PURCHASEABLE = 2
ZO_SKILLS_ABILITY_NOT_PURCHASEABLE = 3

ZO_SKILLS_ABILITY_NOT_MORPHABLE = 1
ZO_SKILLS_ABILITY_MORPH_AVAILABLE = 2
ZO_SKILLS_ABILITY_MORPH_NOT_AVAILABLE = 3

ZO_SKILLS_ABILITY_NOT_UPGRADEABLE = 1
ZO_SKILLS_ABILITY_UPGRADE_AVAILABLE = 2
ZO_SKILLS_ABILITY_UPGRADE_NOT_AVAILABLE = 3


local SkillsAdvisor_Singleton = ZO_CallbackObject:Subclass()

function SkillsAdvisor_Singleton:New(...)
    local skillsAdvisorSingleton = ZO_CallbackObject.New(self)
    skillsAdvisorSingleton:Initialize(...) -- ZO_CallbackObject does not have an initialize function
    return skillsAdvisorSingleton
end

function SkillsAdvisor_Singleton:Initialize()
    self.skillBuilds = {}

    -- Data changed events
    EVENT_MANAGER:RegisterForEvent("SkillsAdvisor_Singleton", EVENT_ABILITY_PROGRESSION_RESULT, function(eventId, ...) self:LoadSkillBuildData(...) end)
    EVENT_MANAGER:RegisterForEvent("SkillsAdvisor_Singleton", EVENT_SKILL_ABILITY_PROGRESSIONS_UPDATED, function(eventId, ...) self:LoadSkillBuildData(...) end)
    EVENT_MANAGER:RegisterForEvent("SkillsAdvisor_Singleton", EVENT_SKILL_BUILD_SELECTION_UPDATED, function(eventId, ...) self:OnBuildSelectionUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("SkillsAdvisor_Singleton", EVENT_SKILL_FORCE_RESPEC, function(eventId, ...) self:LoadSkillBuildData(...) end)
    EVENT_MANAGER:RegisterForEvent("SkillsAdvisor_Singleton", EVENT_SKILL_RANK_UPDATE, function(eventId, ...) self:LoadSkillBuildData(...) end)
    EVENT_MANAGER:RegisterForEvent("SkillsAdvisor_Singleton", EVENT_SKILLS_FULL_UPDATE, function(eventId, ...) self:LoadSkillBuildData(...) end)   
    EVENT_MANAGER:RegisterForEvent("SkillsAdvisor_Singleton", EVENT_ABILITY_LIST_CHANGED, function(eventId, ...) self:LoadSkillBuildData(...) end)
    
    -- Visuals changed event
    --  SKILL_POINTS_CHANGED
    --  SKILL_LINE_ADDED
    --  SKILL_XP_UPDATE

    self:LoadSkillBuildData()
end

function SkillsAdvisor_Singleton:LoadSkillBuildData() 
    self.numAvailableSkillBuilds = GetNumAvailableSkillBuilds()
    self.selectedSkillBuildId = GetSkillBuildId()
    self.selectedSkillBuildIndex = nil
    self.isAdvancedMode = IsSkillBuildAdvancedMode()

    if self.isAdvancedMode or self.selectedSkillBuildId <= 0 then
        self.selectedSkillBuildId = nil
    end

    self.selectedSkillBuildAbilityCount = GetNumSkillBuildAbilities(self.selectedSkillBuildId)

    for skillBuildIndex = 1, self.numAvailableSkillBuilds do
        local skillBuildId = GetAvailableSkillBuildIdByIndex(skillBuildIndex)
        local name, description, isTank, isHealer, isDPS = GetSkillBuildInfo(skillBuildId)
        self.skillBuilds[skillBuildIndex] = 
        {
            id = skillBuildId,
            index = skillBuildIndex,
            name = zo_strformat(SI_SKILLS_ADVISOR_SKILL_BUILD_NAME, name),
            description = zo_strformat(SI_SKILLS_ADVISOR_SKILL_BUILD_DESCRIPTION, description),
            isTank = isTank,
            isHealer = isHealer,
            isDPS = isDPS,
            skillAbilities = {},
        }
        if skillBuildId == self.selectedSkillBuildId then
            self.selectedSkillBuildIndex = skillBuildIndex
        end
    end

    self.numSkillBuildIndicies = self.numAvailableSkillBuilds + 1
    table.insert(self.skillBuilds, {
        index = self.numSkillBuildIndicies,
        name = GetString(SI_SKILLS_ADVISOR_ADVANCED_PLAYER_NAME),
        description = GetString(SI_SKILLS_ADVISOR_ADVANCED_PLAYER_DESCRIPTION),
        isTank = false,
        isHealer = false,
        isDPS = false,
        skillAbilities = {},
    } )
    
    -- Only get SkillBuild Data for currently selected SkillBuild
    if self.selectedSkillBuildIndex ~= nil then
        for skillBuildAbilityIndex = 1, self.selectedSkillBuildAbilityCount do
            self.skillBuilds[self.selectedSkillBuildIndex].skillAbilities[skillBuildAbilityIndex] = self:SetupAbilityData(self.selectedSkillBuildId, skillBuildAbilityIndex)
        end
    end

    self:RefreshVisibleAbilityLists()

    self:FireCallbacks("OnSkillsAdvisorDataUpdated")
end

-- This function for retrieving data may be changed depending on what data we will actually need.
function SkillsAdvisor_Singleton:SetupAbilityData(skillBuildId, skillBuildAbilityIndex)
    local skillType, lineIndex, abilityIndex, isActive, skillBuildMorphChoice, skillBuildRankIndex = GetSkillBuildEntryInfo(skillBuildId, skillBuildAbilityIndex)
    local _, _, earnedRank, _, ultimate, purchased, progressionIndex, rankIndex = GetSkillAbilityInfo(skillType, lineIndex, abilityIndex)
    local _, lineRank = GetSkillLineInfo(skillType, lineIndex)
    local abilityId, rankNeeded = GetSpecificSkillAbilityInfo(skillType, lineIndex, abilityIndex, skillBuildMorphChoice, skillBuildRankIndex)
    local _, _, nextUpgradeEarnedRank = GetSkillAbilityNextUpgradeInfo(skillType, lineIndex, abilityIndex)
    local name = GetAbilityName(abilityId)
    local icon = GetAbilityIcon(abilityId)
    local currentMorphChoice
    local atMorph = false
    if progressionIndex then
        currentMorphChoice = select(2, GetAbilityProgressionInfo(progressionIndex)) 
        atMorph = select(4, GetAbilityProgressionXPInfo(progressionIndex))
    end

    local abilityData = 
    {
        abilityId = abilityId,
        skillType = skillType,
        lineIndex = lineIndex,
        abilityIndex = abilityIndex,
        name = isActive and zo_strformat(SI_ABILITY_NAME, name) or zo_strformat(SI_ABILITY_NAME_AND_RANK, name, skillBuildRankIndex),
        plainName = zo_strformat(SI_ABILITY_NAME, name),
        icon = icon,
        earnedRank = earnedRank,
        nextUpgradeEarnedRank = nextUpgradeEarnedRank,
        rankIndex = rankIndex,
        passive = not isActive,
        ultimate = ultimate,
        purchased = purchased, 
        progressionIndex = progressionIndex,
        lineRank = lineRank,
        atMorph = atMorph,
        morph = currentMorphChoice,
        skillBuildMorphChoice = skillBuildMorphChoice,
        skillBuildRankIndex = skillBuildRankIndex; 
        rankNeeded = rankNeeded
    }

    return abilityData
end

do 
    local ADVANCED_MODE_SELECTED = true
    local SKILL_BUILD_SELECTED = false
    function SkillsAdvisor_Singleton:OnSkillBuildSelected(skillBuildIndex)
        if skillBuildIndex == self.numSkillBuildIndicies then
            SelectSkillBuild(0, ADVANCED_MODE_SELECTED)
        else
            SelectSkillBuild(self.skillBuilds[skillBuildIndex].id, SKILL_BUILD_SELECTED)
        end
    end
end

function SkillsAdvisor_Singleton:OnDataUpdated()
    self:LoadSkillBuildData()
end

function SkillsAdvisor_Singleton:OnRequestSelectSkillLine()
    self:FireCallbacks("OnRequestSelectSkillLine")
end

function SkillsAdvisor_Singleton:OnBuildSelectionUpdated()
    self:OnDataUpdated()

    self:FireCallbacks("OnSelectedSkillBuildUpdated")
end

function SkillsAdvisor_Singleton:IsAdvancedModeSelected()
    return self.isAdvancedMode
end

function SkillsAdvisor_Singleton:GetNumSkillBuildOptions()
    return self.numSkillBuildIndicies
end

function SkillsAdvisor_Singleton:GetAvailableSkillBuildByIndex(index) 
    return self.skillBuilds[index]
end

function SkillsAdvisor_Singleton:GetAvailableSkillBuildById(skillBuildId, getAdvancedIfNoId)
    if skillBuildId or getAdvancedIfNoId then
        for _, data in ipairs(self.skillBuilds) do
            if data.id == skillBuildId then
                return data
            end
        end
    end
    return nil
end

function SkillsAdvisor_Singleton:GetSelectedSkillBuildId()
    return self.selectedSkillBuildId
end

function SkillsAdvisor_Singleton:GetSelectedSkillBuildIndex()
    local selectedSkillBuild = self:GetAvailableSkillBuildById(self.selectedSkillBuildId, self:IsAdvancedModeSelected())
    if selectedSkillBuild then
        return selectedSkillBuild.index
    else
        return nil
    end
end

function SkillsAdvisor_Singleton:GetSkillBuildRoleLinesById(skillBuildId)
    local skillBuild = self:GetAvailableSkillBuildById(skillBuildId)  
    local results = {}
    if skillBuild then   
        local selectedRoles = {}     
        if skillBuild.isDPS then
            table.insert(selectedRoles, LFG_ROLE_DPS)
        end
        if skillBuild.isHealer then
            table.insert(selectedRoles, LFG_ROLE_HEAL)
        end
        if skillBuild.isTank then
            table.insert(selectedRoles, LFG_ROLE_TANK)
        end

        if #selectedRoles == 1 then
            local text = zo_strformat(SI_TOOLTIP_ITEM_ROLE, GetString("SI_LFGROLE", selectedRoles[1]), zo_iconFormat(GetRoleIcon(selectedRoles[1]), "100%", "100%"))
            table.insert(results, zo_strformat(SI_TOOLTIP_ITEM_ROLE_FORMAT, text))
        elseif #selectedRoles > 1 then
            table.insert(results, GetString(SI_TOOLTIP_ITEM_ROLES_FORMAT))
            for i, role in ipairs(selectedRoles) do
                local text = zo_strformat(SI_TOOLTIP_ITEM_ROLE, GetString("SI_LFGROLE", role), zo_iconFormat(GetRoleIcon(role), "100%", "100%"))
                table.insert(results, text)
            end
        end
    end

    return results
end

function SkillsAdvisor_Singleton:GetAvailableAbilityList()
    return self.availableAbilityList
end

function SkillsAdvisor_Singleton:GetPurchasedAbilityList()
    return self.purchasedAbilityList
end

function SkillsAdvisor_Singleton:RefreshVisibleAbilityLists()
    self.availableAbilityList = {}
    self.purchasedAbilityList = {}
    if self.selectedSkillBuildId ~= nil then
        local skillBuild = self:GetAvailableSkillBuildById(self.selectedSkillBuildId)
        if skillBuild ~= nil then
            local suggestionLimit = GetSkillsAdvisorSuggestionLimit()
            local firstLockedAbilityAtLimit
            for _, skillAbility in ipairs(skillBuild.skillAbilities) do
                if skillAbility.purchased then
                    if skillAbility.passive then
                        if skillAbility.rankIndex >= skillAbility.skillBuildRankIndex then
                            table.insert(self.purchasedAbilityList, skillAbility)
                        elseif skillAbility.rankIndex + 1 == skillAbility.skillBuildRankIndex then
                            if #self.availableAbilityList < suggestionLimit then
                                local isLocked = self:IsSpecificSkillAbilityLocked(skillAbility.skillType, skillAbility.lineIndex, skillAbility.abilityIndex, skillAbility.skillBuildMorphChoice, skillAbility.skillBuildRankIndex, ZO_SKILL_ABILITY_DISPLAY_VIEW)
                                if #self.availableAbilityList < suggestionLimit - 1 or not isLocked then
                                    table.insert(self.availableAbilityList, skillAbility)
                                elseif firstLockedAbilityAtLimit == nil then
                                    firstLockedAbilityAtLimit = skillAbility
                                end
                            end
                        end  
                    else
                        if skillAbility.skillBuildMorphChoice == 0 or skillAbility.skillBuildMorphChoice == skillAbility.morph then
                            table.insert(self.purchasedAbilityList, skillAbility)
                        else
                            if #self.availableAbilityList < suggestionLimit then
                                if skillAbility.morph == 0 then
                                    local isLocked = self:IsSpecificSkillAbilityLocked(skillAbility.skillType, skillAbility.lineIndex, skillAbility.abilityIndex, skillAbility.skillBuildMorphChoice, skillAbility.skillBuildRankIndex, ZO_SKILL_ABILITY_DISPLAY_VIEW)
                                    if #self.availableAbilityList < suggestionLimit - 1 or not isLocked then
                                        table.insert(self.availableAbilityList, skillAbility)
                                    elseif firstLockedAbilityAtLimit == nil then
                                        firstLockedAbilityAtLimit = skillAbility
                                    end
                                else 
                                    local siblingSkillBuildAbilityData = self:GetSiblingAbilityDataFromSelectedSkillBuild(skillAbility.skillType, skillAbility.lineIndex, skillAbility.abilityIndex, skillAbility.skillBuildMorphChoice)
                                    if not siblingSkillBuildAbilityData or siblingSkillBuildAbilityData.skillBuildMorphChoice ~= skillAbility.morph then 
                                        local isLocked = self:IsSpecificSkillAbilityLocked(skillAbility.skillType, skillAbility.lineIndex, skillAbility.abilityIndex, skillAbility.skillBuildMorphChoice, skillAbility.skillBuildRankIndex, ZO_SKILL_ABILITY_DISPLAY_VIEW)
                                        if #self.availableAbilityList < suggestionLimit - 1 or not isLocked then
                                            table.insert(self.availableAbilityList, skillAbility)
                                        elseif firstLockedAbilityAtLimit == nil then
                                            firstLockedAbilityAtLimit = skillAbility
                                        end
                                    end
                                end
                            end
                        end
                    end    
                else
                    if #self.availableAbilityList < suggestionLimit then
                        local isLocked = self:IsSpecificSkillAbilityLocked(skillAbility.skillType, skillAbility.lineIndex, skillAbility.abilityIndex, skillAbility.skillBuildMorphChoice, skillAbility.skillBuildRankIndex, ZO_SKILL_ABILITY_DISPLAY_VIEW)
                        if #self.availableAbilityList < suggestionLimit - 1 or not isLocked then
                            if skillAbility.passive then
                                if skillAbility.rankIndex == skillAbility.skillBuildRankIndex then
                                    table.insert(self.availableAbilityList, skillAbility)
                                end
                            else
                                if skillAbility.skillBuildMorphChoice == 0 then
                                    table.insert(self.availableAbilityList, skillAbility)
                                end
                            end
                        elseif firstLockedAbilityAtLimit == nil then
                            firstLockedAbilityAtLimit = skillAbility
                        end
                    end
                end
            end

            if #self.availableAbilityList <= suggestionLimit - 1 and firstLockedAbilityAtLimit then
                table.insert(self.availableAbilityList, firstLockedAbilityAtLimit)
            end
        end
    end
end

function SkillsAdvisor_Singleton:IsPassiveRankPurchased(control)
    local data = control and control.ability and control.ability.dataEntry and control.ability.dataEntry.data
    return data and data.purchased and data.passive and data.rankIndex >= data.skillBuildRankIndex
end

function SkillsAdvisor_Singleton:IsPurchaseable(skillType, skillLineIndex, abilityIndex)
    local _, lineRank, available = GetSkillLineInfo(skillType, skillLineIndex)
    local name, _, earnedRank, _, _, purchased = GetSkillAbilityInfo(skillType, skillLineIndex, abilityIndex)

    if purchased then 
        return ZO_SKILLS_ABILITY_PURCHASED
    elseif available and lineRank >= earnedRank then
        return ZO_SKILLS_ABILITY_PURCHASEABLE
    else
        return ZO_SKILLS_ABILITY_NOT_PURCHASEABLE
    end
end

function SkillsAdvisor_Singleton:IsMorphAvailable(skillType, skillLineIndex, abilityIndex, skillBuildMorphChoice)
    local name, _, _, passive, _, purchased, progressionIndex = GetSkillAbilityInfo(skillType, skillLineIndex, abilityIndex)
    local atMorph = progressionIndex and select(4, GetAbilityProgressionXPInfo(progressionIndex))
    
    if not purchased or passive or (skillBuildMorphChoice and skillBuildMorphChoice == 0) then
        return ZO_SKILLS_ABILITY_NOT_MORPHABLE
    elseif atMorph then
        return ZO_SKILLS_ABILITY_MORPH_AVAILABLE
    else
        return ZO_SKILLS_ABILITY_MORPH_NOT_AVAILABLE
    end 
end

function SkillsAdvisor_Singleton:IsUpgradeAvailable(skillType, skillLineIndex, abilityIndex, skillBuildRankIndex)
    local _, lineRank = GetSkillLineInfo(skillType, skillLineIndex)
    local name, _, _, passive, _, purchased = GetSkillAbilityInfo(skillType, skillLineIndex, abilityIndex)
    local _, _, nextUpgradeEarnedRank = GetSkillAbilityNextUpgradeInfo(skillType, skillLineIndex, abilityIndex)
    local earnedRankIndex, maxRankIndex = GetSkillAbilityUpgradeInfo(skillType, skillLineIndex, abilityIndex)

    local skillBuildRankUnattained = earnedRankIndex and skillBuildRankIndex and skillBuildRankIndex > earnedRankIndex
    local currentRankNotMax = earnedRankIndex and maxRankIndex and earnedRankIndex < maxRankIndex
    local upgradeNeeded = skillBuildRankUnattained or currentRankNotMax
    local upgradeAccessible = nextUpgradeEarnedRank and lineRank >= nextUpgradeEarnedRank

    if not purchased or not passive or not upgradeNeeded then
        return ZO_SKILLS_ABILITY_NOT_UPGRADEABLE
    elseif (skillBuildRankIndex and not skillBuildRankUnattained) or upgradeAccessible then
        return ZO_SKILLS_ABILITY_UPGRADE_AVAILABLE
    else
        return ZO_SKILLS_ABILITY_UPGRADE_NOT_AVAILABLE
    end
end

function SkillsAdvisor_Singleton:IsMorphedOrAtMaxRank(skillType, skillLineIndex, abilityIndex)
    local name, _, _, passive, _, purchased, progressionIndex = GetSkillAbilityInfo(skillType, skillLineIndex, abilityIndex)
    if purchased then 
        if passive then
            local earnedRankIndex, maxRankIndex = GetSkillAbilityUpgradeInfo(skillType, skillLineIndex, abilityIndex)
            return earnedRankIndex == maxRankIndex
        elseif progressionIndex then
            local _, morph = GetAbilityProgressionInfo(progressionIndex)
            -- Not morphed is 0, 1 and 2 are the possible morphed values
            return morph > 0
        end
    end

    return false
end

function SkillsAdvisor_Singleton:IsSpecificSkillAbilityMorph(skillType, skillLineIndex, abilityIndex, skillBuildMorphChoice)
	local name, _, _, passive = GetSkillAbilityInfo(skillType, skillLineIndex, abilityIndex)

    return not passive and skillBuildMorphChoice > 0
end

function SkillsAdvisor_Singleton:IsSpecificSkillAbilityLocked(skillType, skillLineIndex, abilityIndex, skillBuildMorphChoice, skillBuildRankIndex)
    if self:IsMorphedOrAtMaxRank(skillType, skillLineIndex, abilityIndex) then
        return false
    elseif  self:IsPurchaseable(skillType, skillLineIndex, abilityIndex) == ZO_SKILLS_ABILITY_NOT_PURCHASEABLE then
        return true
    elseif self:IsMorphAvailable(skillType, skillLineIndex, abilityIndex, skillBuildMorphChoice) == ZO_SKILLS_ABILITY_MORPH_NOT_AVAILABLE then
        return true
    elseif self:IsUpgradeAvailable(skillType, skillLineIndex, abilityIndex, skillBuildRankIndex) == ZO_SKILLS_ABILITY_UPGRADE_NOT_AVAILABLE then
        return true
    else
        return false
    end
end

function SkillsAdvisor_Singleton:IsCurrentSkillAbilityLocked(skillType, skillLineIndex, abilityIndex)
	return self:IsPurchaseable(skillType, skillLineIndex, abilityIndex) == ZO_SKILLS_ABILITY_NOT_PURCHASEABLE
end

function SkillsAdvisor_Singleton:IsAbilityInSelectedSkillBuild(skillType, lineIndex, abilityIndex, skillBuildMorphChoice, skillBuildRankIndex)
    local abilitySkillBuildData = self:GetAbilityDataFromSelectedSkillBuild(skillType, lineIndex, abilityIndex, skillBuildMorphChoice, skillBuildRankIndex)
    return abilitySkillBuildData ~= nil
end

function SkillsAdvisor_Singleton:IsSiblingMorphInSelectedSkillBuild(skillType, lineIndex, abilityIndex, morphIndex)
    return self:GetSiblingAbilityDataFromSelectedSkillBuild(skillType, lineIndex, abilityIndex, morphIndex) ~= nil
end

function SkillsAdvisor_Singleton:GetSiblingAbilityDataFromSelectedSkillBuild(skillType, skillLineIndex, abilityIndex, morphIndex)
    local NO_MORPH = 0
    if self:IsAbilityInSelectedSkillBuild(skillType, skillLineIndex, abilityIndex, NO_MORPH) then
        local siblingMorph = 1
        if morphIndex == 1 then
            siblingMorph = 2
        end
        return self:GetAbilityDataFromSelectedSkillBuild(skillType, skillLineIndex, abilityIndex, siblingMorph)
    end
    return nil
end

function SkillsAdvisor_Singleton:GetAbilityDataFromSelectedSkillBuild(skillType, lineIndex, abilityIndex, skillBuildMorphChoice, skillBuildRankIndex)
    if self.selectedSkillBuildIndex ~= nil then
        for skillBuildAbilityIndex = 1, self.selectedSkillBuildAbilityCount do
            local skillBuildAbilityData = self.skillBuilds[self.selectedSkillBuildIndex].skillAbilities[skillBuildAbilityIndex]

            if skillType == skillBuildAbilityData.skillType and lineIndex == skillBuildAbilityData.lineIndex and abilityIndex == skillBuildAbilityData.abilityIndex then
                local _, _, _, passive, _, _, progressionIndex = GetSkillAbilityInfo(skillType, lineIndex, abilityIndex)
                if passive then
                    local currentRankIndex, maxRankIndex = GetSkillAbilityUpgradeInfo(skillType, lineIndex, abilityIndex)

                    if not skillBuildRankIndex then
                        skillBuildRankIndex = self:GetValidatedRankIndex(currentRankIndex)
                    end

                    if skillBuildRankIndex == skillBuildAbilityData.skillBuildRankIndex or skillBuildRankIndex == maxRankIndex then
                        return skillBuildAbilityData
                    end
                else
                    if progressionIndex then
                        local _, currentMorphChoice, _ = GetAbilityProgressionInfo(progressionIndex)
                        
                        -- If checking abilities displayed anywhere besides the skills advisor the skill build related fields may not be set, so default values for them must be set in that case
                        if not skillBuildMorphChoice then
                            skillBuildMorphChoice = currentMorphChoice
                        end
                    elseif not skillBuildMorphChoice then
                        skillBuildMorphChoice = 0
                    end

                    if skillBuildMorphChoice == skillBuildAbilityData.skillBuildMorphChoice then
                        return skillBuildAbilityData
                    end
                end                
            end
        end
    end
    return nil
end

function SkillsAdvisor_Singleton:GetValidatedRankIndex(rankIndex)
    if not rankIndex or rankIndex == 0 then 
        return 1
    else
        return rankIndex
    end    
end

function SkillsAdvisor_Singleton:SetupKeyboardSkillBuildTooltip(data)
    if data then
        local buildTypeTable = ZO_SKILLS_ADVISOR_SINGLETON:GetSkillBuildRoleLinesById(data.id)

        GameTooltip:AddLine(data.name, "ZoFontHeader", ZO_SELECTED_TEXT:UnpackRGBA())
        ZO_Tooltip_AddDivider(GameTooltip)
        for i, type in ipairs(buildTypeTable) do
            GameTooltip:AddLine(type, "", ZO_SELECTED_TEXT:UnpackRGBA())  
        end
        GameTooltip:AddLine(data.description, "", ZO_NORMAL_TEXT:UnpackRGBA())
        if GetDefaultSkillBuildId() == data.id then
            GameTooltip:AddLine(GetString(SI_SKILLS_ADVISOR_SKILL_BUILD_NEW_PLAYER), "", ZO_SUCCEEDED_TEXT:UnpackRGBA())
        end
    end
end

ZO_SKILLS_ADVISOR_SINGLETON = SkillsAdvisor_Singleton:New()