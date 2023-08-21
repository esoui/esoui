--showRankNeededLine: adds a line with the skill line rank needed to unlock the specific progression
--showPointSpendLine: adds a line telling the user they can spend a skill point to purchase/upgrade/morph the ability
--showAdvisedLine: adds a line if the skill progression is advised
--showRespecToFixBadMorphLine: adds a line telling the player to respec if the player has chosen the incorrect (not-advised) morph
--showUpgradeInfoBlock: adds a block of text explaining what upgrading the skill does. For passives it adds the next rank description below the current. For morphs it adds text explaining what the morph changes.
--shouldOverrideRankForComparison: changes the tooltip to reference rank 1 instead of the rank the player has and removes the skill XP bar.
function ZO_Tooltip:LayoutSkillProgression(skillProgressionData, showRankNeededLine, showPointSpendLine, showAdvisedLine, showRespecToFixBadMorphLine, showUpgradeInfoBlock, shouldOverrideRankForComparison)
    local skillData = skillProgressionData:GetSkillData()
    local skillLineData = skillData:GetSkillLineData()
    local isPassive = skillData:IsPassive()
    local isActive = not isPassive
    local skillPointAllocator = skillData:GetPointAllocator()
    local isPurchased = skillPointAllocator:IsPurchased()
    local headerSection = self:AcquireSection(self:GetStyle("abilityHeaderSection"))

    --Rank Needed Line
    local hadRankNeededLineToShow = false
    if showRankNeededLine then
        if not isPurchased then
            --Skill progression data is the skill progression data that would be isPurchased
            local isLocked = skillProgressionData:IsLocked()
            if isLocked then
                local skillLineName = skillLineData:GetName()
                local lineRankNeededToPurchase = skillData:GetLineRankNeededToPurchase()
                headerSection:AddLine(zo_strformat(SI_ABILITY_UNLOCKED_AT, skillLineName, lineRankNeededToPurchase), self:GetStyle("failed"), self:GetStyle("abilityHeader"))
                hadRankNeededLineToShow = true
            end
        else
            if isPassive then
                --Skill progression data is the skill progression data that is being upgraded from
                local nextSkillProgressionData = skillProgressionData:GetNextRankData()
                if nextSkillProgressionData then
                    local isLocked = nextSkillProgressionData:IsLocked()
                    if isLocked then
                        local skillLineName = skillLineData:GetName()
                        local lineRankNeededToUnlock = nextSkillProgressionData:GetLineRankNeededToUnlock()
                        headerSection:AddLine(zo_strformat(SI_SKILL_ABILITY_TOOLTIP_UPGRADE_UNLOCK_INFO, skillLineName, lineRankNeededToUnlock), self:GetStyle("failed"), self:GetStyle("abilityHeader"))
                        hadRankNeededLineToShow = true
                    end
                end
            end
        end
    end

    --Skill Point Spending Line
    if showPointSpendLine and not hadRankNeededLineToShow and skillPointAllocator:GetProgressionData() == skillProgressionData then
        local hasAvailableSkillPoint = SKILL_POINT_ALLOCATION_MANAGER:GetAvailableSkillPoints() > 0
        if not isPurchased then
            --Skill progression data is the skill progression data that would be isPurchased
            local isLocked = skillProgressionData:IsLocked()
            if not isLocked then
                if hasAvailableSkillPoint then
                    headerSection:AddLine(GetString(SI_ABILITY_PURCHASE), self:GetStyle("succeeded"), self:GetStyle("abilityHeader"))
                else
                    headerSection:AddLine(GetString(SI_ABILITY_PURCHASE), self:GetStyle("failed"), self:GetStyle("abilityHeader"))
                end
            end
        else
            if isActive then
                if skillProgressionData:IsBase() and skillData:IsAtMorph()  then
                    if hasAvailableSkillPoint then
                        headerSection:AddLine(GetString(SI_ABILITY_AT_MORPH_POINT), self:GetStyle("succeeded"), self:GetStyle("abilityHeader"))
                    else
                        headerSection:AddLine(GetString(SI_ABILITY_AT_MORPH_POINT), self:GetStyle("failed"), self:GetStyle("abilityHeader"))
                    end
                end
            else
                --Skill progression data is the skill progression data that is being upgrade from
                local nextSkillProgressionData = skillProgressionData:GetNextRankData()
                if nextSkillProgressionData then
                    local isLocked = nextSkillProgressionData:IsLocked()
                    if not isLocked then
                        if hasAvailableSkillPoint then
                            headerSection:AddLine(GetString(SI_ABILITY_UPGRADE), self:GetStyle("succeeded"), self:GetStyle("abilityHeader"))
                        else
                            headerSection:AddLine(GetString(SI_ABILITY_UPGRADE), self:GetStyle("failed"), self:GetStyle("abilityHeader"))
                        end
                    end
                end
            end
        end
    end

    --Advised Line
    if showAdvisedLine then
        if isActive then
            if skillProgressionData:IsMorph() then
                local morphSiblingProgressionData = skillProgressionData:GetSiblingMorphData()
                local morphSiblingInSelectedSkillBuild = morphSiblingProgressionData:IsAdvised()
                if skillProgressionData:IsAdvised() and not morphSiblingInSelectedSkillBuild then
                    headerSection:AddLine(GetString(SI_SKILLS_ADVISOR_GAMEPAD_ADVISED_SKILL), self:GetStyle("succeeded"), self:GetStyle("abilityHeader"))
                end
            elseif skillProgressionData:IsAdvised() then
                headerSection:AddLine(GetString(SI_SKILLS_ADVISOR_GAMEPAD_ADVISED_SKILL), self:GetStyle("succeeded"), self:GetStyle("abilityHeader"))
            end
        else
            if skillProgressionData:IsAdvised() then
                headerSection:AddLine(GetString(SI_SKILLS_ADVISOR_GAMEPAD_ADVISED_SKILL), self:GetStyle("succeeded"), self:GetStyle("abilityHeader"))
            end
        end
    end

    --Respec To Fix Bad Morph Line
    if showRespecToFixBadMorphLine then
        if isActive and skillProgressionData:IsBadMorph() then
            headerSection:AddLine(GetString(SI_ABILITY_TOOLTIP_NOT_ADVISED_SUGGESTION), self:GetStyle("bodyHeader"), self:GetStyle("abilityHeader"))
        end
    end
        
    --Passives and actives can both show a block of text that explains what upgrading or morphing them will change but they are done different ways.
    local passiveUpgradeSectionSkillProgressionData
    local addNewEffects = false
    if showUpgradeInfoBlock then
        if isPassive then
            if isPurchased then
                local passiveRank = skillProgressionData:GetRank()
                if passiveRank < skillData:GetNumRanks() then
                    passiveUpgradeSectionSkillProgressionData = skillData:GetRankData(passiveRank + 1)
                end
            end
        else
            addNewEffects = true
        end
    end

    --Morphed From Header
    if isActive and skillProgressionData:IsMorph() then
        local baseMorphProgressionData = skillData:GetMorphData(MORPH_SLOT_BASE)
        headerSection:AddLine(zo_strformat(SI_ABILITY_TOOLTIP_MORPHS_FROM, baseMorphProgressionData:GetName()), self:GetStyle("abilityHeader"))
    end

    self:AddSectionEvenIfEmpty(headerSection)

    --Ability Tooltip
    local nameRank
    local activeRank
    if shouldOverrideRankForComparison then
        if isActive then
            activeRank = 1
        end
        nameRank = 1
    else
        if isActive then
            activeRank = skillProgressionData:GetCurrentRank()
            nameRank = activeRank
        else
            nameRank = skillProgressionData:GetRank()
        end
    end
    
    --if you have never owned an active then the rank is nil and we show no rank in the title
    if nameRank == nil then
        self:AddLine(skillProgressionData:GetFormattedName(), self:GetStyle("title"))
    else
        local name = skillProgressionData:GetName()
        local formattedNameAndRank = ZO_CachedStrFormat(SI_ABILITY_NAME_AND_RANK, name, nameRank)
        self:AddLine(formattedNameAndRank, self:GetStyle("title"))
    end
    
    if isActive then
        --No point in showing the current XP if we overriding the rank anyway
        if not shouldOverrideRankForComparison then
            local currentRank = skillProgressionData:GetCurrentRank()
            --if you have never owned an active then the rank is nil and we don't show an XP bar
            if currentRank then
                local currentXP = skillProgressionData:GetCurrentXP()
                local lastRankXP, nextRankXP = skillProgressionData:GetRankXPExtents(currentRank)
                self:AddAbilityProgressBar(currentXP, lastRankXP, nextRankXP)
            end
        end

        self:AddAbilityStats(skillProgressionData:GetAbilityId(), activeRank)
    end
    
    if addNewEffects then
        self:AddAbilityNewEffects(GetAbilityNewEffectLines(skillProgressionData:GetAbilityId()))
    end
    local descriptionText = GetAbilityDescription(skillProgressionData:GetAbilityId(), activeRank)
    self:AddAbilityDescription(skillProgressionData:GetAbilityId(), descriptionText)

    --Passive Upgrade Section

    if passiveUpgradeSectionSkillProgressionData then
        local newEffectSection = self:AcquireSection(self:GetStyle("bodySection"))
        newEffectSection:AddLine(GetString(SI_ABILITY_TOOLTIP_NEXT_RANK), self:GetStyle("newEffectTitle"), self:GetStyle("bodyHeader"))      
        local description = GetAbilityDescription(passiveUpgradeSectionSkillProgressionData:GetAbilityId())
        newEffectSection:AddLine(description, self:GetStyle("newEffectBody"), self:GetStyle("bodyDescription"))
        self:AddSection(newEffectSection)
    end
end

-- In most cases, you should prefer LayoutSkillProgressionData(), which carries inside of it the abilityId associated with that progression.
-- This is for cases where we might want to show an ability that is indirectly associated with a progression, like for example a chain ability.
function ZO_Tooltip:LayoutAbilityWithSkillProgressionData(abilityId, skillProgressionData)
    local abilityName = GetAbilityName(abilityId)
    local currentRank = skillProgressionData:GetCurrentRank()
    if currentRank then
        local headerSection = self:AcquireSection(self:GetStyle("abilityHeaderSection"))

        --Morphed From Header
        local skillData = skillProgressionData:GetSkillData()
        local isActive = not skillData:IsPassive()
        if isActive and skillProgressionData:IsMorph() then
            local baseMorphProgressionData = skillData:GetMorphData(MORPH_SLOT_BASE)
            headerSection:AddLine(zo_strformat(SI_ABILITY_TOOLTIP_MORPHS_FROM, baseMorphProgressionData:GetName()), self:GetStyle("abilityHeader"))
        end

        self:AddSectionEvenIfEmpty(headerSection)

        local formattedNameAndRank = ZO_CachedStrFormat(SI_ABILITY_NAME_AND_RANK, abilityName, currentRank)
        self:AddLine(formattedNameAndRank, self:GetStyle("title"))

        local currentXP = skillProgressionData:GetCurrentXP()
        local lastRankXP, nextRankXP = skillProgressionData:GetRankXPExtents(currentRank)
        self:AddAbilityProgressBar(currentXP, lastRankXP, nextRankXP)

        self:AddAbilityStats(abilityId, currentRank)
        local descriptionText = GetAbilityDescription(abilityId, currentRank)
        self:AddAbilityDescription(abilityId, descriptionText)
    else
        self:LayoutSimpleAbility(abilityId)
    end
end

do
    local ATTRIBUTE_DESCRIPTIONS =
    {
        [ATTRIBUTE_HEALTH] = SI_ATTRIBUTE_TOOLTIP_HEALTH,
        [ATTRIBUTE_MAGICKA] = SI_ATTRIBUTE_TOOLTIP_MAGICKA,
        [ATTRIBUTE_STAMINA] = SI_ATTRIBUTE_TOOLTIP_STAMINA,
    }

    function ZO_Tooltip:LayoutAttributeInfo(attributeType, pendingBonus)
        -- We don't show any attribute stat increases while in battle leveled zones because
        -- it doesn't make any sense based on how battle leveling now works
        if not (IsUnitChampionBattleLeveled("player") or IsUnitBattleLeveled("player")) then
            local statType = STAT_TYPES[attributeType]
            local statsSection = self:AcquireSection(self:GetStyle("attributeStatsSection"))
            local attributePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
        
            attributePair:SetStat(zo_strformat(SI_STAT_NAME_FORMAT, GetString("SI_DERIVEDSTATS", statType)), self:GetStyle("statValuePairStat"))
            attributePair:SetValue(GetPlayerStat(statType) + pendingBonus, self:GetStyle("statValuePairValue"))
            statsSection:AddStatValuePair(attributePair)
            if pendingBonus > 0 then
                local upgradePair = statsSection:AcquireStatValuePair(self:GetStyle("attributeUpgradePair"))
                upgradePair:SetStat(zo_strformat(SI_GAMEPAD_LEVELUP_PENDING_BONUS_LABEL, GetString("SI_ATTRIBUTES", attributeType)), self:GetStyle("statValuePairStat"))
                upgradePair:SetValue(zo_strformat(SI_STAT_PENDING_BONUS_FORMAT, pendingBonus), self:GetStyle("succeeded"), self:GetStyle("statValuePairValue"))
                statsSection:AddStatValuePair(upgradePair)
            end
            self:AddSection(statsSection)
        end
        local descriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
        descriptionSection:AddLine(GetString(ATTRIBUTE_DESCRIPTIONS[attributeType]), self:GetStyle("bodyDescription"))
        self:AddSection(descriptionSection)
    end
end

function ZO_Tooltip:LayoutCompanionSkillProgression(skillProgressionData)
    local abilityId = skillProgressionData:GetAbilityId()

    local headerSection = self:AcquireSection(self:GetStyle("abilityHeaderSection"))
    --Unlocks at rank X
    if not skillProgressionData:IsUnlocked() then
        local skillData = skillProgressionData:GetSkillData()
        local skillLineData = skillData:GetSkillLineData()
        local skillLineName = skillLineData:GetName()
        local lineRankNeededToUnlock = skillData:GetSkillLineRankRequired()
        headerSection:AddLine(zo_strformat(SI_ABILITY_UNLOCKED_AT, skillLineName, lineRankNeededToUnlock), self:GetStyle("failed"), self:GetStyle("abilityHeader"))
    end
    self:AddSectionEvenIfEmpty(headerSection)

    local formattedAbilityName = ZO_CachedStrFormat(SI_ABILITY_NAME, GetAbilityName(abilityId))
    self:AddLine(formattedAbilityName, self:GetStyle("title"))

    local NO_OVERRIDE_RANK = nil
    if not IsAbilityPassive(abilityId) then
        self:AddAbilityStats(abilityId, NO_OVERRIDE_RANK, "companion")
    end
    local NO_OVERRIDE_DESCRIPTION = nil
    self:AddAbilityDescription(abilityId, NO_OVERRIDE_DESCRIPTION, "companion")
end

function ZO_Tooltip:LayoutSkillLinePreview(skillLineData)
    if skillLineData:IsAvailable() then
        local skillsSection = self:AcquireSection(self:GetStyle("skillLinePreviewBodySection"))
        local lastHeader = nil
        for _, skillData in skillLineData:SkillIterator() do
            local currentHeader = skillData:GetHeaderText()
            if lastHeader ~= currentHeader then
                local headerSection = self:AcquireSection(self:GetStyle("skillLineEntryHeaderSection"))
                headerSection:AddLine(currentHeader, self:GetStyle("skillLineEntryHeader"))
                skillsSection:AddSection(headerSection)
                lastHeader = currentHeader
            end
            local rowControl = self:AcquireCustomControl(self:GetStyle("skillLineEntryRow"))
            ZO_GamepadSkillEntryPreviewRow_Setup(rowControl, skillData)
            skillsSection:AddCustomControl(rowControl)
        end
        self:AddSection(skillsSection)
    elseif skillLineData:IsAdvised() then
        self:LayoutTitleAndMultiSectionDescriptionTooltip(skillLineData:GetFormattedName(), skillLineData:GetUnlockText())
    end
end

function ZO_Tooltip:LayoutCompanionSkillLinePreview(skillLineData)
    if skillLineData:IsAvailable() then
        local skillsSection = self:AcquireSection(self:GetStyle("skillLinePreviewBodySection"))
        local lastHeader = nil
        for _, skillData in skillLineData:SkillIterator() do
            local currentHeader = skillData:GetHeaderText()
            if lastHeader ~= currentHeader then
                local headerSection = self:AcquireSection(self:GetStyle("companionSkillLineEntryHeaderSection"))
                headerSection:AddLine(currentHeader, self:GetStyle("skillLineEntryHeader"))
                skillsSection:AddSection(headerSection)
                lastHeader = currentHeader
            end
            local rowControl = self:AcquireCustomControl(self:GetStyle("companionSkillLineEntryRow"))
            ZO_GamepadSkillEntryPreviewRow_Setup(rowControl, skillData)
            skillsSection:AddCustomControl(rowControl)
        end
        self:AddSection(skillsSection)
    elseif skillLineData:IsAdvised() then
        self:LayoutTitleAndMultiSectionDescriptionTooltip(skillLineData:GetFormattedName(), skillLineData:GetUnlockText())
    end
end

do
    local COMPANION_SKILLS_FILTER =
    {
        function(actionSlotData)
            return actionSlotData:GetSlottableActionType() == ZO_SLOTTABLE_ACTION_TYPE_COMPANION_SKILL
        end,
    }
    function ZO_Tooltip:LayoutEquippedCompanionSkillsPreview()
        local skillSection = self:AcquireSection(self:GetStyle("bodySection"))
        local hotbar = ACTION_BAR_ASSIGNMENT_MANAGER:GetHotbar(HOTBAR_CATEGORY_COMPANION)
        for slotIndex, slotData in hotbar:SlotIterator(COMPANION_SKILLS_FILTER) do
            local rowControl = self:AcquireCustomControl(self:GetStyle("companionSkillLineEntryRow"))
            ZO_GamepadSkillEntryPreviewRow_Setup(rowControl, slotData:GetCompanionSkillData())
            skillSection:AddCustomControl(rowControl)
        end
        self:AddSection(skillSection)
    end
end
