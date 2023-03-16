--
--[[ SkillsAdvisor Singleton ]]--
--

local SkillsAdvisor_Manager = ZO_CallbackObject:Subclass()

function SkillsAdvisor_Manager:New(...)
    ZO_SKILLS_ADVISOR_SINGLETON = ZO_CallbackObject.New(self)
    ZO_SKILLS_ADVISOR_SINGLETON:Initialize(...) -- ZO_CallbackObject does not have an initialize function
    return ZO_SKILLS_ADVISOR_SINGLETON
end

function SkillsAdvisor_Manager:Initialize()
    self.skillBuilds = {}
    self.availableAbilityList = {}
    self.purchasedAbilityList = {}
    self.numSkillBuildIndicies = 0
    self.numAvailableSkillBuilds = 0

    self.advancedSkillBuildData =
    {
        name = GetString(SI_SKILLS_ADVISOR_ADVANCED_PLAYER_NAME),
        description = GetString(SI_SKILLS_ADVISOR_ADVANCED_PLAYER_DESCRIPTION),
        isTank = false,
        isHealer = false,
        isDPS = false,
        skillAbilities = {},
    }

    local function UpdateSkillBuildData()
        self:UpdateSkillBuildData()
    end

    local function RefreshVisibleAbilityLists()
        local BROADCAST = true
        self:RefreshVisibleAbilityLists(BROADCAST)
    end

    SKILLS_DATA_MANAGER:RegisterCallback("FullSystemUpdated", UpdateSkillBuildData)
    SKILLS_DATA_MANAGER:RegisterCallback("SkillLineRankUpdated", RefreshVisibleAbilityLists)
    SKILL_POINT_ALLOCATION_MANAGER:RegisterCallback("OnSkillsCleared", RefreshVisibleAbilityLists)
    SKILL_POINT_ALLOCATION_MANAGER:RegisterCallback("PurchasedChanged", RefreshVisibleAbilityLists)
    SKILL_POINT_ALLOCATION_MANAGER:RegisterCallback("SkillProgressionKeyChanged", RefreshVisibleAbilityLists)
    SKILLS_AND_ACTION_BAR_MANAGER:RegisterCallback("SkillPointAllocationModeChanged", RefreshVisibleAbilityLists)
    SKILLS_AND_ACTION_BAR_MANAGER:RegisterCallback("RespecStateReset", RefreshVisibleAbilityLists)

    EVENT_MANAGER:RegisterForEvent("SkillsAdvisor_Manager", EVENT_SKILL_BUILD_SELECTION_UPDATED, function(eventId, ...) self:OnBuildSelectionUpdated(...) end)

    --TODO: Support def changes

    self:UpdateSkillBuildData()
end

function SkillsAdvisor_Manager:UpdateSkillBuildData()
    if not SKILLS_DATA_MANAGER:IsDataReady() then
        --If we don't have skills data, the rest of this is pretty useless, so wait until the data becomes ready
        return
    end

    self.numAvailableSkillBuilds = GetNumAvailableSkillBuilds()
    self.isAdvancedMode = IsSkillBuildAdvancedMode()

    local selectedSkillBuildId = GetSkillBuildId()

    if self.isAdvancedMode or selectedSkillBuildId <= 0 then
        selectedSkillBuildId = nil
    end

    self.selectedSkillBuildId = selectedSkillBuildId
    self.selectedSkillBuildIndex = nil

    for skillBuildIndex = 1, self.numAvailableSkillBuilds do
        local skillBuildId = GetAvailableSkillBuildIdByIndex(skillBuildIndex)
        local oldSkillBuild = self.skillBuilds[skillBuildIndex]
        -- Builds don't change, so we only need to load when IDs are different
        if oldSkillBuild == nil or oldSkillBuild.id ~= skillBuildId then
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
        end

        if skillBuildId == selectedSkillBuildId then
            self.selectedSkillBuildIndex = skillBuildIndex
        end
    end

    self.numSkillBuildIndicies = self.numAvailableSkillBuilds + 1
    self.skillBuilds[self.numSkillBuildIndicies] = self.advancedSkillBuildData
    self.advancedSkillBuildData.index = self.numSkillBuildIndicies

    -- Remove remaining stale entries, if any
    for i = self.numSkillBuildIndicies + 1, #self.skillBuilds do
        self.skillBuilds[i] = nil
    end
    
    -- Only get SkillBuild Data for currently selected SkillBuild
    if self.selectedSkillBuildIndex ~= nil then
        local skillAbilities = self.skillBuilds[self.selectedSkillBuildIndex].skillAbilities
        ZO_ClearNumericallyIndexedTable(skillAbilities)
        for skillBuildAbilityIndex = 1, GetNumSkillBuildAbilities(selectedSkillBuildId) do
            local skillProgressionData = self:GetSkillProgressionData(selectedSkillBuildId, skillBuildAbilityIndex)
            if skillProgressionData then
                table.insert(skillAbilities, skillProgressionData)
            end
        end
    end

    local DONT_BROADCAST = false
    self:RefreshVisibleAbilityLists(DONT_BROADCAST)

    self:FireCallbacks("OnSkillsAdvisorDataUpdated")
end

function SkillsAdvisor_Manager:GetSkillProgressionData(skillBuildId, skillBuildAbilityIndex)
    local skillType, skillLineIndex, skillIndex, _, skillBuildMorphChoice, skillBuildRank = GetSkillBuildEntryInfo(skillBuildId, skillBuildAbilityIndex)

    local skillData = SKILLS_DATA_MANAGER:GetSkillDataByIndices(skillType, skillLineIndex, skillIndex)
    if not skillData then
        -- ESO-566272 / ESO-581396: We added logging but it didn't really help us narrow down why this can happen.
        -- Best guess is a timing issue between getting the skills info and the actual C++ progression data populated.
        -- Removed the logging that was here because it was flooding our reports for no real benefit.
        -- TODO: A refactor to separate progression from static data would probably solve this, but that's not going to be something we'll do anytime soon
        return nil
    end

    local skillProgressionData = skillData:IsPassive() and skillData:GetRankData(skillBuildRank) or skillData:GetMorphData(skillBuildMorphChoice)
    return skillProgressionData
end

do 
    local ADVANCED_MODE_SELECTED = true
    local SKILL_BUILD_SELECTED = false
    function SkillsAdvisor_Manager:OnSkillBuildSelected(skillBuildIndex)
        if skillBuildIndex == self.numSkillBuildIndicies then
            SelectSkillBuild(0, ADVANCED_MODE_SELECTED)
        else
            SelectSkillBuild(self.skillBuilds[skillBuildIndex].id, SKILL_BUILD_SELECTED)
        end
    end
end

function SkillsAdvisor_Manager:OnRequestSelectSkillLine()
    self:FireCallbacks("OnRequestSelectSkillLine")
end

function SkillsAdvisor_Manager:OnBuildSelectionUpdated()
    self:UpdateSkillBuildData()

    self:FireCallbacks("OnSelectedSkillBuildUpdated")
end

function SkillsAdvisor_Manager:IsAdvancedModeSelected()
    return self.isAdvancedMode
end

function SkillsAdvisor_Manager:GetNumSkillBuildOptions()
    return self.numSkillBuildIndicies
end

function SkillsAdvisor_Manager:GetAvailableSkillBuildByIndex(index) 
    return self.skillBuilds[index]
end

function SkillsAdvisor_Manager:GetAvailableSkillBuildById(skillBuildId, getAdvancedIfNoId)
    if skillBuildId or getAdvancedIfNoId then
        for _, data in ipairs(self.skillBuilds) do
            if data.id == skillBuildId then
                return data
            end
        end
    end
    return nil
end

function SkillsAdvisor_Manager:GetSelectedSkillBuildId()
    return self.selectedSkillBuildId
end

function SkillsAdvisor_Manager:GetSelectedSkillBuildIndex()
    local selectedSkillBuild = self:GetAvailableSkillBuildById(self.selectedSkillBuildId, self:IsAdvancedModeSelected())
    if selectedSkillBuild then
        return selectedSkillBuild.index
    else
        return nil
    end
end

function SkillsAdvisor_Manager:GetSkillBuildRoleLinesById(skillBuildId)
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
            local text = zo_strformat(SI_TOOLTIP_ITEM_ROLE, GetString("SI_LFGROLE", selectedRoles[1]), zo_iconFormat(ZO_GetRoleIcon(selectedRoles[1]), "100%", "100%"))
            table.insert(results, zo_strformat(SI_TOOLTIP_ITEM_ROLE_FORMAT, text))
        elseif #selectedRoles > 1 then
            table.insert(results, GetString(SI_TOOLTIP_ITEM_ROLES_FORMAT))
            for i, role in ipairs(selectedRoles) do
                local text = zo_strformat(SI_TOOLTIP_ITEM_ROLE, GetString("SI_LFGROLE", role), zo_iconFormat(ZO_GetRoleIcon(role), "100%", "100%"))
                table.insert(results, text)
            end
        end
    end

    return results
end

function SkillsAdvisor_Manager:GetAvailableAbilityList()
    return self.availableAbilityList
end

function SkillsAdvisor_Manager:GetPurchasedAbilityList()
    return self.purchasedAbilityList
end

function SkillsAdvisor_Manager:RefreshVisibleAbilityLists(broadcast)
    ZO_ClearNumericallyIndexedTable(self.availableAbilityList)
    ZO_ClearNumericallyIndexedTable(self.purchasedAbilityList)

    if self.selectedSkillBuildId ~= nil then
        local skillBuild = self:GetAvailableSkillBuildById(self.selectedSkillBuildId)
        if skillBuild ~= nil then
            local suggestionLimit = GetSkillsAdvisorSuggestionLimit()
            local firstLockedAbilityAtLimit
            for _, skillProgressionData in ipairs(skillBuild.skillAbilities) do
                local skillData = skillProgressionData:GetSkillData()
                local skillPointAllocator = skillData:GetPointAllocator()
                local isUnlocked = skillProgressionData:IsUnlocked()

                if skillPointAllocator:IsPurchased() then
                    if skillData:IsPassive() then
                        local entryRank = skillProgressionData:GetRank()
                        local allocatedRank = skillPointAllocator:GetRank()

                        if allocatedRank >= entryRank then
                            table.insert(self.purchasedAbilityList, skillProgressionData)
                        elseif allocatedRank + 1 == entryRank then
                            -- This data is the next rank to purchased
                            if #self.availableAbilityList < suggestionLimit then
                                if #self.availableAbilityList < suggestionLimit - 1 or isUnlocked then
                                    table.insert(self.availableAbilityList, skillProgressionData)
                                elseif firstLockedAbilityAtLimit == nil then
                                    firstLockedAbilityAtLimit = skillProgressionData
                                end
                            end
                        end  
                    else
                        local entryMorphSlot = skillProgressionData:GetMorphSlot()
                        local allocatedMorphSlot = skillPointAllocator:GetMorphSlot()

                        if skillProgressionData:IsBase() or entryMorphSlot == allocatedMorphSlot then
                            table.insert(self.purchasedAbilityList, skillProgressionData)
                        elseif #self.availableAbilityList < suggestionLimit then
                            if allocatedMorphSlot == MORPH_SLOT_BASE then
                                -- If we're currently at base, any advised morph is acceptable to display
                                if #self.availableAbilityList < suggestionLimit - 1 or isUnlocked then
                                    table.insert(self.availableAbilityList, skillProgressionData)
                                elseif firstLockedAbilityAtLimit == nil then
                                    firstLockedAbilityAtLimit = skillProgressionData
                                end
                            else
                                -- If we've already morphed, only continue to show this morph as advised if the other morph is NOT advised
                                local siblingMorphData = skillProgressionData:GetSiblingMorphData()
                                if not siblingMorphData:IsAdvised() then 
                                    if #self.availableAbilityList < suggestionLimit - 1 or isUnlocked then
                                        table.insert(self.availableAbilityList, skillProgressionData)
                                    elseif firstLockedAbilityAtLimit == nil then
                                        firstLockedAbilityAtLimit = skillProgressionData
                                    end
                                end
                            end
                        end
                    end
                elseif #self.availableAbilityList < suggestionLimit then
                    if #self.availableAbilityList < suggestionLimit - 1 or isUnlocked then
                        if skillData:IsPassive() then
                            if skillProgressionData:GetRank() == 1 then
                                table.insert(self.availableAbilityList, skillProgressionData)
                            end
                        else
                            if skillProgressionData:IsBase() then
                                table.insert(self.availableAbilityList, skillProgressionData)
                            end
                        end
                    elseif firstLockedAbilityAtLimit == nil then
                        firstLockedAbilityAtLimit = skillProgressionData
                    end
                end
            end

            if #self.availableAbilityList <= suggestionLimit - 1 and firstLockedAbilityAtLimit then
                table.insert(self.availableAbilityList, firstLockedAbilityAtLimit)
            end
        end
    end

    if broadcast then
        self:FireCallbacks("RefreshVisibleAbilityLists")
    end
end

function SkillsAdvisor_Manager:IsSkillDataInSelectedBuild(skillData)
    local skillType, skillLineIndex, skillIndex = skillData:GetIndices()
    local skillProgressionData
    if skillData:IsPassive() then
        skillProgressionData = skillData:GetRankData(1)
    else
        skillProgressionData = skillData:GetMorphData(MORPH_SLOT_BASE)
    end

    return self:IsSkillProgressionDataInSelectedBuild(skillProgressionData)
end

function SkillsAdvisor_Manager:IsSkillProgressionDataInSelectedBuild(skillProgressionData)
    if self.selectedSkillBuildIndex ~= nil then
        local skillAbilities = self.skillBuilds[self.selectedSkillBuildIndex].skillAbilities
        for _, skillBuildProgressionData in ipairs(skillAbilities) do
            if skillBuildProgressionData == skillProgressionData then
                return true
            end
        end
    end

    return false
end

function SkillsAdvisor_Manager:GetValidatedRankIndex(rankIndex)
    if not rankIndex or rankIndex == 0 then 
        return 1
    else
        return rankIndex
    end    
end

function SkillsAdvisor_Manager:SetupKeyboardSkillBuildTooltip(data)
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

SkillsAdvisor_Manager:New()