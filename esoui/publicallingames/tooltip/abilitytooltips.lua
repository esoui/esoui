--Section Generators

function ZO_Tooltip:AddAbilityProgressBar(currentXP, lastRankXP, nextRankXP)
    local bar = self:AcquireStatusBar(self:GetStyle("abilityProgressBar"))
    if nextRankXP == 0 then
        bar:SetMinMax(0, 1)
        bar:SetValue(1)
    else
        bar:SetMinMax(0, nextRankXP - lastRankXP)
        bar:SetValue(currentXP - lastRankXP)
    end
    self:AddStatusBar(bar)
end

do
    local TANK_ROLE_ICON = zo_iconFormat("EsoUI/Art/LFG/LFG_tank_down_no_glow_64.dds", 40, 40)
    local HEALER_ROLE_ICON = zo_iconFormat("EsoUI/Art/LFG/LFG_healer_down_no_glow_64.dds", 40, 40)
    local DAMAGE_ROLE_ICON = zo_iconFormat("EsoUI/Art/LFG/LFG_dps_down_no_glow_64.dds", 40, 40)
    local g_roleIconTable = {}

    function ZO_Tooltip:AddAbilityStats(abilityId, overrideActiveRank)
        local statsSection = self:AcquireSection(self:GetStyle("abilityStatsSection"))

        --Cast Time
        local channeled, castTime, channelTime = GetAbilityCastInfo(abilityId, overrideActiveRank)
        local castTimePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
        if(channeled) then
            castTimePair:SetStat(GetString(SI_ABILITY_TOOLTIP_CHANNEL_TIME_LABEL), self:GetStyle("statValuePairStat"))
            castTimePair:SetValue(ZO_FormatTimeMilliseconds(channelTime, TIME_FORMAT_STYLE_CHANNEL_TIME, TIME_FORMAT_PRECISION_TENTHS_RELEVANT, TIME_FORMAT_DIRECTION_NONE), self:GetStyle("abilityStatValuePairValue"))
        else
            castTimePair:SetStat(GetString(SI_ABILITY_TOOLTIP_CAST_TIME_LABEL), self:GetStyle("statValuePairStat"))
            castTimePair:SetValue(ZO_FormatTimeMilliseconds(castTime, TIME_FORMAT_STYLE_CAST_TIME, TIME_FORMAT_PRECISION_TENTHS_RELEVANT, TIME_FORMAT_DIRECTION_NONE), self:GetStyle("abilityStatValuePairValue"))
        end
        statsSection:AddStatValuePair(castTimePair)

        --Target
        local targetDescription = GetAbilityTargetDescription(abilityId, overrideActiveRank)
        if(targetDescription) then
            local targetPair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            targetPair:SetStat(GetString(SI_ABILITY_TOOLTIP_TARGET_TYPE_LABEL), self:GetStyle("statValuePairStat"))
            targetPair:SetValue(targetDescription, self:GetStyle("abilityStatValuePairValue"))
            statsSection:AddStatValuePair(targetPair)
        end

        --Range
        local minRangeCM, maxRangeCM = GetAbilityRange(abilityId, overrideActiveRank)
        if(maxRangeCM > 0) then
            local rangePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            rangePair:SetStat(GetString(SI_ABILITY_TOOLTIP_RANGE_LABEL), self:GetStyle("statValuePairStat"))
            if(minRangeCM == 0) then
                rangePair:SetValue(zo_strformat(SI_ABILITY_TOOLTIP_RANGE, FormatFloatRelevantFraction(maxRangeCM / 100)), self:GetStyle("abilityStatValuePairValue"))
            else
                rangePair:SetValue(zo_strformat(SI_ABILITY_TOOLTIP_MIN_TO_MAX_RANGE, FormatFloatRelevantFraction(minRangeCM / 100), FormatFloatRelevantFraction(maxRangeCM / 100)), self:GetStyle("abilityStatValuePairValue"))
            end
            statsSection:AddStatValuePair(rangePair)
        end

        --Radius/Distance
        local radiusCM = GetAbilityRadius(abilityId, overrideActiveRank)
        local angleDistanceCM = GetAbilityAngleDistance(abilityId)
        if(radiusCM > 0) then
            local radiusDistancePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            if(angleDistanceCM > 0) then
                radiusDistancePair:SetStat(GetString(SI_ABILITY_TOOLTIP_AREA_LABEL), self:GetStyle("statValuePairStat"))
                -- Angle distance is the distance to the left and right of the caster, not total distance. So we're multiplying by 2 to accurately reflect that in the UI.
                radiusDistancePair:SetValue(zo_strformat(SI_ABILITY_TOOLTIP_AOE_DIMENSIONS, FormatFloatRelevantFraction(radiusCM / 100), FormatFloatRelevantFraction(angleDistanceCM * 2 / 100)), self:GetStyle("abilityStatValuePairValue"))
            else
                radiusDistancePair:SetStat(GetString(SI_ABILITY_TOOLTIP_RADIUS_LABEL), self:GetStyle("statValuePairStat"))
                radiusDistancePair:SetValue(zo_strformat(SI_ABILITY_TOOLTIP_RADIUS, FormatFloatRelevantFraction(radiusCM / 100)), self:GetStyle("abilityStatValuePairValue")) 
            end
            statsSection:AddStatValuePair(radiusDistancePair)
        end

        --Duration
        local durationMS = GetAbilityDuration(abilityId, overrideActiveRank)
        if(durationMS > 0) then
            local durationPair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            durationPair:SetStat(GetString(SI_ABILITY_TOOLTIP_DURATION_LABEL), self:GetStyle("statValuePairStat"))
            durationPair:SetValue(ZO_FormatTimeMilliseconds(durationMS, TIME_FORMAT_STYLE_DURATION, TIME_FORMAT_PRECISION_TENTHS_RELEVANT, TIME_FORMAT_DIRECTION_NONE), self:GetStyle("abilityStatValuePairValue"))
            statsSection:AddStatValuePair(durationPair)
        end

        --Cost
        local cost, mechanic = GetAbilityCost(abilityId, overrideActiveRank)
        if(cost > 0) then
            local costPair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            costPair:SetStat(GetString(SI_ABILITY_TOOLTIP_RESOURCE_COST_LABEL), self:GetStyle("statValuePairStat"))
            local mechanicName = GetString("SI_COMBATMECHANICTYPE", mechanic)
            local costString = zo_strformat(SI_ABILITY_TOOLTIP_RESOURCE_COST, cost, mechanicName)
            if(mechanic == POWERTYPE_MAGICKA) then
                costPair:SetValue(costString, self:GetStyle("abilityStatValuePairMagickaValue"))
            elseif(mechanic == POWERTYPE_STAMINA) then
                costPair:SetValue(costString, self:GetStyle("abilityStatValuePairStaminaValue"))
            elseif(mechanic == POWERTYPE_HEALTH) then
                costPair:SetValue(costString, self:GetStyle("abilityStatValuePairHealthValue"))
            else
                costPair:SetValue(costString, self:GetStyle("abilityStatValuePairValue"))
            end
            statsSection:AddStatValuePair(costPair)
        end

        --Roles
        local isTankRole, isHealerRole, isDamageRole = GetAbilityRoles(abilityId)
        if isTankRole then
            table.insert(g_roleIconTable, TANK_ROLE_ICON)
        end
        if isHealerRole then
            table.insert(g_roleIconTable, HEALER_ROLE_ICON)
        end
        if isDamageRole then
            table.insert(g_roleIconTable, DAMAGE_ROLE_ICON)
        end
        if(#g_roleIconTable > 0) then
            local rolesPair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            rolesPair:SetStat(GetString(SI_ABILITY_TOOLTIP_ROLE_LABEL), self:GetStyle("statValuePairStat"))
            local finalIconText = table.concat(g_roleIconTable, "")
            rolesPair:SetValue(finalIconText, self:GetStyle("abilityStatValuePairValue"))
            statsSection:AddStatValuePair(rolesPair)
            ZO_ClearNumericallyIndexedTable(g_roleIconTable)
        end

        self:AddSection(statsSection)
    end
end

function ZO_Tooltip:AddAbilityDescription(abilityId, pendingChampionPoints, overrideActiveRank)
    local descriptionHeader = GetAbilityDescriptionHeader(abilityId)
    local description
    if not pendingChampionPoints then
        description = GetAbilityDescription(abilityId, overrideActiveRank)
    else
        description = GetChampionAbilityDescription(abilityId, pendingChampionPoints)
    end
    if descriptionHeader ~= "" or description ~= "" then
        local descriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
        if descriptionHeader ~= "" then
            --descriptionHeader has already been run through grammar
            descriptionSection:AddLine(descriptionHeader, self:GetStyle("bodyHeader"))
        end
        if description ~= "" then
            --description has already been run through grammar
            descriptionSection:AddLine(description, self:GetStyle("bodyDescription"))
        end
        self:AddSection(descriptionSection)
    end
end

function ZO_Tooltip:AddAbilityNewEffects(...)
    local numNewEffectReturns = select("#", ...)
    if(numNewEffectReturns > 0) then
        for i = 1, numNewEffectReturns do
            local newEffect = select(i, ...)
            local newEffectSection = self:AcquireSection(self:GetStyle("bodySection"))
            newEffectSection:AddLine(GetString(SI_ABILITY_TOOLTIP_NEW_EFFECT), self:GetStyle("newEffectTitle"), self:GetStyle("bodyHeader"))
            newEffectSection:AddLine(newEffect, self:GetStyle("newEffectBody"), self:GetStyle("bodyDescription"))
            self:AddSection(newEffectSection)
        end
    end
end

--Layout Functions

--showRankNeededLine: adds a line with the skill line rank needed to unlock the specific progression
--showPointSpendLine: adds a line telling the user they can spend a skill point to purchase/upgrade/morph the ability
--showAdvisedLine: adds a line if the skill progression is advised
--showRespecToFixBadMorphLine: adds a line telling the player to respec if the player has chosen the incorrect (not-advised) morph
--showUpgradeInfoBlock: adds a block of text explaining what upgrading the skill does. For passives it adds the next rank description below the current. For morphs it adds text explaining what the morph changes.
--shouldOverrideRankForComparison: changes the tooltip to reference rank 1 instead of the rank the player has and removes the skill XP bar to aid in morph comparison.
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
    local NO_CHAMPION_POINTS = nil
    self:AddAbilityDescription(skillProgressionData:GetAbilityId(), NO_CHAMPION_POINTS, activeRank)

    --Passive Upgrade Section

    if passiveUpgradeSectionSkillProgressionData then
        local newEffectSection = self:AcquireSection(self:GetStyle("bodySection"))
        newEffectSection:AddLine(GetString(SI_ABILITY_TOOLTIP_NEXT_RANK), self:GetStyle("newEffectTitle"), self:GetStyle("bodyHeader"))      
        local description = GetAbilityDescription(passiveUpgradeSectionSkillProgressionData:GetAbilityId())
        newEffectSection:AddLine(description, self:GetStyle("newEffectBody"), self:GetStyle("bodyDescription"))
        self:AddSection(newEffectSection)
    end
end

function ZO_Tooltip:LayoutChampionSkillAbility(disciplineIndex, skillIndex, pendingPoints)
    local abilityId = GetChampionAbilityId(disciplineIndex, skillIndex)
    
    self:AddLine(zo_strformat(SI_ABILITY_TOOLTIP_NAME, GetAbilityName(abilityId)), self:GetStyle("title"))
    self:AddAbilityDescription(abilityId, pendingPoints)

    local unlockLevel = GetChampionSkillUnlockLevel(disciplineIndex, skillIndex)
    if unlockLevel ~= nil then
        local unlockSection = self:AcquireSection(self:GetStyle("bodySection"))
        local unlockText
        local textColor
        if not WillChampionSkillBeUnlocked(disciplineIndex, skillIndex) then
            unlockText = SI_CHAMPION_TOOLTIP_LOCKED
            textColor = self:GetStyle("failed")
        else
            unlockText = SI_CHAMPION_TOOLTIP_UNLOCKED
            textColor = self:GetStyle("succeeded")
        end
        unlockSection:AddLine(zo_strformat(unlockText, GetChampionDisciplineName(disciplineIndex), unlockLevel), self:GetStyle("bodyDescription"), textColor)
        self:AddSection(unlockSection)
    else
        --if it's possible to spend more points on this skill (we haven't hit cap)
        if GetNumPointsSpentOnChampionSkill(disciplineIndex, skillIndex) + pendingPoints < GetMaxPossiblePointsInChampionSkill() then
            local upgradeSection = self:AcquireSection(self:GetStyle("bodySection"))
            local nextPointDescription = GetChampionAbilityDescription(abilityId, pendingPoints + 1)
            if nextPointDescription ~= "" then
                upgradeSection:AddLine(GetString(SI_CHAMPION_TOOLTIP_NEXT_POINT), self:GetStyle("abilityUpgrade"), self:GetStyle("bodyHeader"))
                --nextPointDescription has already been run through grammar
                upgradeSection:AddLine(nextPointDescription, self:GetStyle("abilityUpgrade"), self:GetStyle("bodyDescription"))
                self:AddSection(upgradeSection)
            end

            local attribute = GetChampionDisciplineAttribute(disciplineIndex)
            local iconPath = GetChampionPointAttributeIcon(attribute)
            local pointCostSection = self:AcquireSection(self:GetStyle("bodySection"))
            if HasAvailableChampionPointsInAttribute(attribute) then
                if CHAMPION_PERKS:GetNumAvailablePointsThatCanBeSpent(attribute) > 0 then
                    pointCostSection:AddLine(zo_strformat(SI_CHAMPION_TOOLTIP_UPGRADE, iconPath), self:GetStyle("bodyDescription"), self:GetStyle("succeeded"))
                else
                    local attributeName = ZO_Champion_GetUnformattedConstellationGroupNameFromAttribute(attribute)
                    pointCostSection:AddLine(zo_strformat(SI_CHAMPION_TOOLTIP_REACHED_MAX_SPEND_LIMIT, GetMaxSpendableChampionPointsInAttribute(), iconPath, attributeName), self:GetStyle("bodyDescription"), self:GetStyle("failed"))
                end
            else
                pointCostSection:AddLine(zo_strformat(SI_CHAMPION_TOOLTIP_POINTS_REQUIRED, iconPath), self:GetStyle("bodyDescription"), self:GetStyle("failed"))
            end
            self:AddSection(pointCostSection)
        end
    end
end

-- In most cases, you should prefer LayoutSkillProgressionData(), which carries inside of it the abilityId associated with that progression.
-- This is for cases where we might want to show an ability that is indirectly associated with a progression, like for example a chain ability.
function ZO_Tooltip:LayoutAbilityWithSkillProgressionData(abilityId, skillProgressionData)
    local abilityName = GetAbilityName(abilityId)
    local currentRank = skillProgressionData:GetCurrentRank()
    if currentRank then
        local headerSection = self:AcquireSection(self:GetStyle("abilityHeaderSection"))

        self:AddSectionEvenIfEmpty(headerSection)

        local formattedNameAndRank = ZO_CachedStrFormat(SI_ABILITY_NAME_AND_RANK, abilityName, currentRank)
        self:AddLine(formattedNameAndRank, self:GetStyle("title"))

        local currentXP = skillProgressionData:GetCurrentXP()
        local lastRankXP, nextRankXP = skillProgressionData:GetRankXPExtents(currentRank)
        self:AddAbilityProgressBar(currentXP, lastRankXP, nextRankXP)

        self:AddAbilityStats(abilityId, currentRank)
        self:AddAbilityDescription(abilityId)
    else
        self:LayoutSimpleAbility(abilityId)
    end
end

function ZO_Tooltip:LayoutSimpleAbility(abilityId)
    local headerSection = self:AcquireSection(self:GetStyle("abilityHeaderSection"))

    self:AddSectionEvenIfEmpty(headerSection)

    local formattedAbilityName = ZO_CachedStrFormat(SI_ABILITY_NAME, GetAbilityName(abilityId))
    self:AddLine(formattedAbilityName, self:GetStyle("title"))

    self:AddAbilityStats(abilityId)

    self:AddAbilityDescription(abilityId)
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
