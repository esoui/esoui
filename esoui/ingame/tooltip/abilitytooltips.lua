--Section Generators

function ZO_Tooltip:AddAbilityName(abilityId, hideRank, overrideRank)
    local abilityName = GetAbilityName(abilityId)
    local rank = overrideRank
    if(overrideRank == nil) then
        rank = GetAbilityProgressionRankFromAbilityId(abilityId)
    end
    if(not hideRank and rank ~= nil and rank > 0) then
        self:AddLine(zo_strformat(SI_ABILITY_NAME_AND_RANK, abilityName, rank), self:GetStyle("title"))
    else
        self:AddLine(zo_strformat(SI_ABILITY_TOOLTIP_NAME, abilityName), self:GetStyle("title"))
    end
end

function ZO_Tooltip:AddAbilityProgressBar(currentXP, lastRankXP, nextRankXP, atMorph)
    local bar = self:AcquireStatusBar(self:GetStyle("abilityProgressBar"))
    if(nextRankXP == 0) then
        bar:SetMinMax(0, 1)
        bar:SetValue(1)
    else
        bar:SetMinMax(0, nextRankXP - lastRankXP)
        bar:SetValue(currentXP - lastRankXP)
    end
    self:AddStatusBar(bar)
end

do
    local TANK_ROLE_ICON = zo_iconFormat("EsoUI/Art/LFG/LFG_tank_down_no_glow_64.dds", 48, 48)
    local HEALER_ROLE_ICON = zo_iconFormat("EsoUI/Art/LFG/LFG_healer_down_no_glow_64.dds", 48, 48)
    local DAMAGE_ROLE_ICON = zo_iconFormat("EsoUI/Art/LFG/LFG_dps_down_no_glow_64.dds", 48, 48)
    local g_roleIconTable = {}

    function ZO_Tooltip:AddAbilityStats(abilityId)
        local statsSection = self:AcquireSection(self:GetStyle("abilityStatsSection"))

        --Cast Time
        local channeled, castTime, channelTime = GetAbilityCastInfo(abilityId)
        local castTimePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
        if(channeled) then
            castTimePair:SetStat(GetString(SI_ABILITY_TOOLTIP_CHANNEL_TIME_LABEL), self:GetStyle("statValuePairStat"))
            castTimePair:SetValue(ZO_FormatTimeMilliseconds(channelTime, TIME_FORMAT_STYLE_CHANNEL_TIME, TIME_FORMAT_PRECISION_TENTHS_RELEVANT, TIME_FORMAT_DIRECTION_NONE), self:GetStyle("statValuePairValue"))
        else
            castTimePair:SetStat(GetString(SI_ABILITY_TOOLTIP_CAST_TIME_LABEL), self:GetStyle("statValuePairStat"))
            castTimePair:SetValue(ZO_FormatTimeMilliseconds(castTime, TIME_FORMAT_STYLE_CAST_TIME, TIME_FORMAT_PRECISION_TENTHS_RELEVANT, TIME_FORMAT_DIRECTION_NONE), self:GetStyle("statValuePairValue"))
        end
        statsSection:AddStatValuePair(castTimePair)

        --Target
        local targetDescription = GetAbilityTargetDescription(abilityId)
        if(targetDescription) then
            local targetPair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            targetPair:SetStat(GetString(SI_ABILITY_TOOLTIP_TARGET_TYPE_LABEL), self:GetStyle("statValuePairStat"))
            targetPair:SetValue(targetDescription, self:GetStyle("statValuePairValue"))
            statsSection:AddStatValuePair(targetPair)
        end

        --Range
        local minRangeCM, maxRangeCM = GetAbilityRange(abilityId)
        if(maxRangeCM > 0) then
            local rangePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            rangePair:SetStat(GetString(SI_ABILITY_TOOLTIP_RANGE_LABEL), self:GetStyle("statValuePairStat"))
            if(minRangeCM == 0) then
                rangePair:SetValue(zo_strformat(SI_ABILITY_TOOLTIP_RANGE, FormatFloatRelevantFraction(maxRangeCM / 100)), self:GetStyle("statValuePairValue"))
            else
                rangePair:SetValue(zo_strformat(SI_ABILITY_TOOLTIP_MIN_TO_MAX_RANGE, FormatFloatRelevantFraction(minRangeCM / 100), FormatFloatRelevantFraction(maxRangeCM / 100)), self:GetStyle("statValuePairValue"))
            end
            statsSection:AddStatValuePair(rangePair)
        end

        --Radius/Distance
        local radiusCM = GetAbilityRadius(abilityId)
        local angleDistanceCM = GetAbilityAngleDistance(abilityId)
        if(radiusCM > 0) then
            local radiusDistancePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            if(angleDistanceCM > 0) then
                radiusDistancePair:SetStat(GetString(SI_ABILITY_TOOLTIP_AREA_LABEL), self:GetStyle("statValuePairStat"))
                -- Angle distance is the distance to the left and right of the caster, not total distance. So we're multiplying by 2 to accurately reflect that in the UI.
                radiusDistancePair:SetValue(zo_strformat(SI_ABILITY_TOOLTIP_AOE_DIMENSIONS, FormatFloatRelevantFraction(radiusCM / 100), FormatFloatRelevantFraction(angleDistanceCM * 2 / 100)), self:GetStyle("statValuePairValue"))
            else
                radiusDistancePair:SetStat(GetString(SI_ABILITY_TOOLTIP_RADIUS_LABEL), self:GetStyle("statValuePairStat"))
                radiusDistancePair:SetValue(zo_strformat(SI_ABILITY_TOOLTIP_RADIUS, FormatFloatRelevantFraction(radiusCM / 100)), self:GetStyle("statValuePairValue")) 
            end
            statsSection:AddStatValuePair(radiusDistancePair)
        end

        --Duration
        local durationMS = GetAbilityDuration(abilityId)
        if(durationMS > 0) then
            local durationPair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            durationPair:SetStat(GetString(SI_ABILITY_TOOLTIP_DURATION_LABEL), self:GetStyle("statValuePairStat"))
            durationPair:SetValue(ZO_FormatTimeMilliseconds(durationMS, TIME_FORMAT_STYLE_DURATION, TIME_FORMAT_PRECISION_TENTHS_RELEVANT, TIME_FORMAT_DIRECTION_NONE), self:GetStyle("statValuePairValue"))
            statsSection:AddStatValuePair(durationPair)
        end

        --Cost
        local cost, mechanic = GetAbilityCost(abilityId)
        if(cost > 0) then
            local costPair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            costPair:SetStat(GetString(SI_ABILITY_TOOLTIP_RESOURCE_COST_LABEL), self:GetStyle("statValuePairStat"))
            local mechanicName = GetString("SI_COMBATMECHANICTYPE", mechanic)
            local costString = zo_strformat(SI_ABILITY_TOOLTIP_RESOURCE_COST, cost, mechanicName)
            if(mechanic == POWERTYPE_MAGICKA) then
                costPair:SetValue(costString, self:GetStyle("statValuePairMagickaValue"))
            elseif(mechanic == POWERTYPE_STAMINA) then
                costPair:SetValue(costString, self:GetStyle("statValuePairStaminaValue"))
            else
                costPair:SetValue(costString, self:GetStyle("statValuePairValue"))
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
            rolesPair:SetValue(finalIconText, self:GetStyle("statValuePairValue"))
            statsSection:AddStatValuePair(rolesPair)
            ZO_ClearNumericallyIndexedTable(g_roleIconTable)
        end

        self:AddSection(statsSection)
    end
end

function ZO_Tooltip:AddAbilityDescription(abilityId, pendingChampionPoints)
    local descriptionHeader = GetAbilityDescriptionHeader(abilityId)
    local description
    if not pendingChampionPoints then
        description = GetAbilityDescription(abilityId)
    else
        description = GetChampionAbilityDescription(abilityId, pendingChampionPoints)
    end
    if(descriptionHeader ~= "" or description ~= "") then
        local descriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
        if(descriptionHeader ~= "") then
            descriptionSection:AddLine(zo_strformat(SI_ABILITY_TOOLTIP_DESCRIPTION_HEADER, descriptionHeader), self:GetStyle("bodyHeader"))
        end
        if(description ~= "") then
            descriptionSection:AddLine(zo_strformat(SI_ABILITY_TOOLTIP_DESCRIPTION, description), self:GetStyle("bodyDescription"))
        end
        self:AddSection(descriptionSection)
    end
end

function ZO_Tooltip:AddAbilityUpgrades(...)
    local numUpgradeReturns = select("#", ...)
    if(numUpgradeReturns > 0) then
        for i = 1, numUpgradeReturns, 3 do
            local label, oldValue, newValue = select(i, ...)
            local upgradeSection = self:AcquireSection(self:GetStyle("bodySection"))
            upgradeSection:AddLine(GetString(SI_ABILITY_TOOLTIP_UPGRADE), self:GetStyle("abilityUpgrade"), self:GetStyle("bodyHeader"))
            upgradeSection:AddLine(zo_strformat(SI_ABILITY_TOOLTIP_UPGRADE_FORMAT, label, oldValue, newValue), self:GetStyle("abilityUpgrade"), self:GetStyle("bodyDescription"))
            self:AddSection(upgradeSection)
        end
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

function ZO_Tooltip:LayoutAbility(abilityId, hideRank, overrideRank, pendingChampionPoints, addNewEffects)
    if(DoesAbilityExist(abilityId)) then
        local hasProgression, progressionIndex, lastRankXP, nextRankXP, currentXP, atMorph = GetAbilityProgressionXPInfoFromAbilityId(abilityId)

        self:AddAbilityName(abilityId, hideRank, overrideRank)
        if(hasProgression) then
            self:AddAbilityProgressBar(currentXP, lastRankXP, nextRankXP, atMorph)
        end
        if(not IsAbilityPassive(abilityId)) then
            self:AddAbilityStats(abilityId)
        end
        if(addNewEffects) then
            self:AddAbilityNewEffects(GetAbilityNewEffectLines(abilityId))
        end
        self:AddAbilityDescription(abilityId, pendingChampionPoints)
    end
end

function ZO_Tooltip:LayoutSkillLineAbility(skillType, skillLineIndex, abilityIndex, showNextUpgrade, hideRank, overrideRank, showPurchaseInfo)    
    local abilityId = GetSkillAbilityId(skillType, skillLineIndex, abilityIndex, false)     

    local upgradeSection = self:AcquireSection(self:GetStyle("abilityUpgradeSection"))
    if(showPurchaseInfo) then
        --Purchase Information
        local hasProgression, progressionIndex, lastRankXP, nextRankXP, currentXP, atMorph = GetAbilityProgressionXPInfoFromAbilityId(abilityId)
        local name, icon, earnedRank, passive, ultimate, purchased, progressionIndex = GetSkillAbilityInfo(skillType, skillLineIndex, abilityIndex)
        if(purchased and hasProgression and atMorph) then
            if(GetAvailableSkillPoints() == 0) then
                upgradeSection:AddLine(GetString(SI_ABILITY_AT_MORPH_POINT), self:GetStyle("failed"), self:GetStyle("abilityUpgrade"))
            else
                upgradeSection:AddLine(GetString(SI_ABILITY_AT_MORPH_POINT), self:GetStyle("succeeded"), self:GetStyle("abilityUpgrade"))
            end
        elseif(not purchased) then
            local skillLineName, skillLineRank = GetSkillLineInfo(skillType, skillLineIndex)
            if(skillLineRank < earnedRank) then
                upgradeSection:AddLine(zo_strformat(SI_ABILITY_UNLOCKED_AT, skillLineName, earnedRank), self:GetStyle("failed"), self:GetStyle("abilityUpgrade"))
            elseif(GetAvailableSkillPoints() == 0) then
                upgradeSection:AddLine(GetString(SI_ABILITY_PURCHASE), self:GetStyle("failed"), self:GetStyle("abilityUpgrade"))
            else
                upgradeSection:AddLine(GetString(SI_ABILITY_PURCHASE), self:GetStyle("succeeded"), self:GetStyle("abilityUpgrade"))
            end
        elseif(passive) then
            local currentUpgradeLevel, maxUpgradeLevel = GetSkillAbilityUpgradeInfo(skillType, skillLineIndex, abilityIndex)
            if(currentUpgradeLevel and maxUpgradeLevel and currentUpgradeLevel < maxUpgradeLevel) then
                local skillLineName, skillLineRank = GetSkillLineInfo(skillType, skillLineIndex)
                local _, _, nextUpgradeEarnedRank = GetSkillAbilityNextUpgradeInfo(skillType, skillLineIndex, abilityIndex)
                if(skillLineRank < nextUpgradeEarnedRank) then
                    upgradeSection:AddLine(zo_strformat(SI_SKILL_ABILITY_TOOLTIP_UPGRADE_UNLOCK_INFO, skillLineName, nextUpgradeEarnedRank), self:GetStyle("failed"), self:GetStyle("abilityUpgrade"))
                elseif(GetAvailableSkillPoints() == 0) then
                    upgradeSection:AddLine(GetString(SI_ABILITY_UPGRADE), self:GetStyle("failed"), self:GetStyle("abilityUpgrade"))
                else
                    upgradeSection:AddLine(GetString(SI_ABILITY_UPGRADE), self:GetStyle("succeeded"), self:GetStyle("abilityUpgrade"))
                end
            end
        end
    end
    self:AddSectionEvenIfEmpty(upgradeSection)
    self:LayoutAbility(abilityId, hideRank, overrideRank)

    --For gamepad skills tips, when you ask for showNextUpgrade we show you the regular one with the description of the new one in green
    --This mostly affects passive abilities since active ones have morphs with their own style tooltip.
    local upgradeAbilityId = showNextUpgrade and GetSkillAbilityId(skillType, skillLineIndex, abilityIndex, true)   
    if showPurchaseInfo and upgradeAbilityId then
        local newEffectSection = self:AcquireSection(self:GetStyle("bodySection"))
        newEffectSection:AddLine(GetString(SI_ABILITY_TOOLTIP_NEXT_RANK), self:GetStyle("newEffectTitle"), self:GetStyle("bodyHeader"))      
        local description = GetAbilityDescription(upgradeAbilityId)
        newEffectSection:AddLine(description, self:GetStyle("newEffectBody"), self:GetStyle("bodyDescription"))
        self:AddSection(newEffectSection)
    end
end

function ZO_Tooltip:LayoutAbilityMorph(progressionIndex, morphIndex)
    local RANK = 1
    local abilityId = GetAbilityProgressionAbilityId(progressionIndex, morphIndex, RANK)
    local upgradeSection = self:AcquireSection(self:GetStyle("abilityUpgradeSection"))
    self:AddSectionEvenIfEmpty(upgradeSection)
    local ADD_NEW_EFFECTS = true
    local HIDE_RANK = nil
    local CHAMPION_POINTS = nil
    self:LayoutAbility(abilityId, HIDE_RANK, RANK, CHAMPION_POINTS, ADD_NEW_EFFECTS)
    self:AddAbilityUpgrades(GetAbilityUpgradeLines(abilityId))
end

function ZO_Tooltip:LayoutActionBarAbility(slotId)
    local slotType = GetSlotType(slotId)
    if slotType == ACTION_TYPE_ABILITY then
        local upgradeSection = self:AcquireSection(self:GetStyle("abilityUpgradeSection"))
        self:AddSectionEvenIfEmpty(upgradeSection)
        self:LayoutAbility(GetSlotBoundId(slotId))
    end
end

function ZO_Tooltip:LayoutChampionSkillAbility(disciplineIndex, skillIndex, pendingPoints)
    local abilityId = GetChampionAbilityId(disciplineIndex, skillIndex)
    
    local HIDE_RANK = true
    local OVERRIDE_RANK = nil
    self:LayoutAbility(abilityId, HIDE_RANK, OVERRIDE_RANK, pendingPoints)

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
                upgradeSection:AddLine(zo_strformat(SI_ABILITY_TOOLTIP_DESCRIPTION, nextPointDescription), self:GetStyle("abilityUpgrade"), self:GetStyle("bodyDescription"))
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
        
            attributePair:SetStat(GetString("SI_DERIVEDSTATS", statType), self:GetStyle("statValuePairStat"))
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
