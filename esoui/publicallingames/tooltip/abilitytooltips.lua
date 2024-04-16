--Section Generators

function ZO_Tooltip:AddAbilityProgressBar(currentXP, lastRankXP, nextRankXP)
    local bar = self:AcquireStatusBar(self:GetStyle("abilityProgressBar"))
    local maxValue = 1
    local currentValue = 1
    if nextRankXP == lastRankXP or currentXP >= nextRankXP then
        bar:SetMinMax(0, maxValue)
        bar:SetValue(currentValue)
    else
        maxValue = nextRankXP - lastRankXP
        currentValue = currentXP - lastRankXP
        bar:SetMinMax(0, maxValue)
        bar:SetValue(currentValue)
    end

    local narrationText = function()
        local range = maxValue
        local percentage = currentValue / range
        percentage = string.format("%.2f", percentage * 100)
        return zo_strformat(SI_SCREEN_NARRATION_PROGRESS_BAR_PERCENT_FORMATTER, percentage)
    end
    self:AddStatusBar(bar, narrationText)
end

do
    local TANK_ROLE_ICON = zo_iconFormat("EsoUI/Art/LFG/LFG_tank_down_no_glow_64.dds", 40, 40)
    local HEALER_ROLE_ICON = zo_iconFormat("EsoUI/Art/LFG/LFG_healer_down_no_glow_64.dds", 40, 40)
    local DAMAGE_ROLE_ICON = zo_iconFormat("EsoUI/Art/LFG/LFG_dps_down_no_glow_64.dds", 40, 40)
    local g_roleIconTable = {}
    local UNKNOWN_STAT_VALUE_TEXT = GetString(SI_ABILITY_TOOLTIP_UNKNOWN_VALUE)
    local UNKNOWN_STAT_VALUE_TYPE_TEXT = GetString(SI_ABILITY_TOOLTIP_UNKNOWN_VALUE_TYPE)
    local UNKNOWN_SECONDS_STAT_VALUE_TEXT = GetString(SI_ABILITY_TOOLTIP_UNKNOWN_SECONDS)

    local function GetNextAbilityMechanicFlagIter(abilityId)
        return function(_, lastFlag)
            return GetNextAbilityMechanicFlag(abilityId, lastFlag)
        end
    end

    function ZO_Tooltip:AddAbilityStats(abilityId, overrideActiveRank, overrideCasterUnitTag)
        overrideCasterUnitTag = overrideCasterUnitTag or "player"
        local statsSection = self:AcquireSection(self:GetStyle("abilityStatsSection"))

        --Channel/Cast Time
        local channeled, durationValue = GetAbilityCastInfo(abilityId, overrideActiveRank, overrideCasterUnitTag)
        if channeled ~= nil then
            -- Only include a line if we can determine if it's going to be definitely either channeled or cast
            local castTimePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            if channeled then
                castTimePair:SetStat(GetString(SI_ABILITY_TOOLTIP_CHANNEL_TIME_LABEL), self:GetStyle("statValuePairStat"))
                if durationValue then
                    castTimePair:SetValue(ZO_FormatTimeMilliseconds(durationValue, TIME_FORMAT_STYLE_CHANNEL_TIME, TIME_FORMAT_PRECISION_TENTHS_RELEVANT, TIME_FORMAT_DIRECTION_NONE), self:GetStyle("abilityStatValuePairValue"))
                else
                    castTimePair:SetValue(UNKNOWN_SECONDS_STAT_VALUE_TEXT)
                end
            else
                castTimePair:SetStat(GetString(SI_ABILITY_TOOLTIP_CAST_TIME_LABEL), self:GetStyle("statValuePairStat"))
                if durationValue then
                    castTimePair:SetValue(ZO_FormatTimeMilliseconds(durationValue, TIME_FORMAT_STYLE_CAST_TIME, TIME_FORMAT_PRECISION_TENTHS_RELEVANT, TIME_FORMAT_DIRECTION_NONE), self:GetStyle("abilityStatValuePairValue"))
                else
                    castTimePair:SetValue(UNKNOWN_SECONDS_STAT_VALUE_TEXT)
                end
            end
            statsSection:AddStatValuePair(castTimePair)
        end

        --Target
        local targetDescription = GetAbilityTargetDescription(abilityId, overrideActiveRank, overrideCasterUnitTag)
        if targetDescription and targetDescription ~= "" then
            local targetPair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            targetPair:SetStat(GetString(SI_ABILITY_TOOLTIP_TARGET_TYPE_LABEL), self:GetStyle("statValuePairStat"))
            targetPair:SetValue(targetDescription, self:GetStyle("abilityStatValuePairValue"))
            statsSection:AddStatValuePair(targetPair)
        end

        --Range
        local minRangeCM, maxRangeCM = GetAbilityRange(abilityId, overrideActiveRank, overrideCasterUnitTag)
        local maxRangeM = maxRangeCM and FormatFloatRelevantFraction(maxRangeCM / 100) or UNKNOWN_STAT_VALUE_TEXT
        if maxRangeM == UNKNOWN_STAT_VALUE_TEXT or maxRangeCM > 0 then
            local minRangeM = minRangeCM and FormatFloatRelevantFraction(minRangeCM / 100) or UNKNOWN_STAT_VALUE_TEXT
            local rangePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            rangePair:SetStat(GetString(SI_ABILITY_TOOLTIP_RANGE_LABEL), self:GetStyle("statValuePairStat"))
            if minRangeM == UNKNOWN_STAT_VALUE_TEXT or minRangeCM > 0 then
                rangePair:SetValue(zo_strformat(SI_ABILITY_TOOLTIP_MIN_TO_MAX_RANGE, minRangeM, maxRangeM), self:GetStyle("abilityStatValuePairValue"))
            elseif maxRangeM == UNKNOWN_STAT_VALUE_TEXT then
                rangePair:SetValue(GetString(SI_ABILITY_TOOLTIP_UNKNOWN_METERS), self:GetStyle("abilityStatValuePairValue")) 
            else
                rangePair:SetValue(zo_strformat(SI_ABILITY_TOOLTIP_RANGE, maxRangeM), self:GetStyle("abilityStatValuePairValue"))
            end
            statsSection:AddStatValuePair(rangePair)
        end

        --Radius/Distance
        local radiusCM = GetAbilityRadius(abilityId, overrideActiveRank, overrideCasterUnitTag)
        local radiusM = radiusCM and FormatFloatRelevantFraction(radiusCM / 100) or UNKNOWN_STAT_VALUE_TEXT
        if radiusM == UNKNOWN_STAT_VALUE_TEXT or radiusCM > 0 then
            local angleDistanceCM = GetAbilityAngleDistance(abilityId)
            -- Angle distance is the distance to the left and right of the caster, not total distance. So we're multiplying by 2 to accurately reflect that in the UI.
            local areaWidthM = angleDistanceCM and FormatFloatRelevantFraction(angleDistanceCM * 2 / 100) or UNKNOWN_STAT_VALUE_TEXT
            local showArea = areaWidthM == UNKNOWN_STAT_VALUE_TEXT or angleDistanceCM > 0
            local radiusDistancePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            local statLabel = showArea and GetString(SI_ABILITY_TOOLTIP_AREA_LABEL) or GetString(SI_ABILITY_TOOLTIP_RADIUS_LABEL)
            radiusDistancePair:SetStat(statLabel, self:GetStyle("statValuePairStat"))
            if showArea then
                radiusDistancePair:SetValue(zo_strformat(SI_ABILITY_TOOLTIP_AOE_DIMENSIONS, radiusM, areaWidthM), self:GetStyle("abilityStatValuePairValue"))
            elseif radiusM == UNKNOWN_STAT_VALUE_TEXT then
                radiusDistancePair:SetValue(GetString(SI_ABILITY_TOOLTIP_UNKNOWN_METERS), self:GetStyle("abilityStatValuePairValue")) 
            else
                radiusDistancePair:SetValue(zo_strformat(SI_ABILITY_TOOLTIP_RADIUS, radiusM), self:GetStyle("abilityStatValuePairValue")) 
            end
            statsSection:AddStatValuePair(radiusDistancePair)
        end

        --Duration
        local durationValue = nil
        local isAbilityDurationToggled = IsAbilityDurationToggled(abilityId, overrideCasterUnitTag)
        if isAbilityDurationToggled == nil then
            durationValue = UNKNOWN_STAT_VALUE_TYPE_TEXT
        elseif isAbilityDurationToggled then
            durationValue = GetString(SI_ABILITY_TOOLTIP_TOGGLE_DURATION)
        else
            local durationMS = GetAbilityDuration(abilityId, overrideActiveRank, overrideCasterUnitTag)
            if durationMS == nil then
                durationValue = UNKNOWN_SECONDS_STAT_VALUE_TEXT
            elseif durationMS > 0 then
                durationValue = ZO_FormatTimeMilliseconds(durationMS, TIME_FORMAT_STYLE_DURATION, TIME_FORMAT_PRECISION_TENTHS_RELEVANT, TIME_FORMAT_DIRECTION_NONE)
            end
        end

        if durationValue then
            local durationPair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            durationPair:SetStat(GetString(SI_ABILITY_TOOLTIP_DURATION_LABEL), self:GetStyle("statValuePairStat"))
            durationPair:SetValue(durationValue, self:GetStyle("abilityStatValuePairValue"))
            statsSection:AddStatValuePair(durationPair)
        end

        --Cooldown
        local cooldownMS = GetAbilityCooldown(abilityId, overrideCasterUnitTag)
        local unknownCooldown = cooldownMS == nil
        if unknownCooldown or cooldownMS > 0 then
            local cooldownPair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            cooldownPair:SetStat(GetString(SI_ABILITY_TOOLTIP_COOLDOWN), self:GetStyle("statValuePairStat"))
            local cooldownValue = unknownCooldown and UNKNOWN_SECONDS_STAT_VALUE_TEXT or ZO_FormatTimeMilliseconds(cooldownMS, TIME_FORMAT_STYLE_DURATION, TIME_FORMAT_PRECISION_TENTHS_RELEVANT, TIME_FORMAT_DIRECTION_NONE)
            cooldownPair:SetValue(cooldownValue, self:GetStyle("abilityStatValuePairValue"))
            statsSection:AddStatValuePair(cooldownPair)
        end

        -- Costs
        self:AddAbilityCosts(abilityId, overrideActiveRank, statsSection)
        self:AddAbilityCostsOverTime(abilityId, overrideActiveRank, statsSection)

        --Roles
        local isTankRole, isHealerRole, isDamageRole = GetAbilityRoles(abilityId)
        local roleNarrationText = {}
        if isTankRole then
            table.insert(g_roleIconTable, TANK_ROLE_ICON)
            table.insert(roleNarrationText, GetString("SI_LFGROLE", LFG_ROLE_TANK))
        end
        if isHealerRole then
            table.insert(g_roleIconTable, HEALER_ROLE_ICON)
            table.insert(roleNarrationText, GetString("SI_LFGROLE", LFG_ROLE_HEAL))
        end
        if isDamageRole then
            table.insert(g_roleIconTable, DAMAGE_ROLE_ICON)
            table.insert(roleNarrationText, GetString("SI_LFGROLE", LFG_ROLE_DPS))
        end
        if #g_roleIconTable > 0 then
            local rolesPair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            rolesPair:SetStat(GetString(SI_ABILITY_TOOLTIP_ROLE_LABEL), self:GetStyle("statValuePairStat"))
            local finalIconText = table.concat(g_roleIconTable, "")
            rolesPair:SetValueWithCustomNarration(finalIconText, roleNarrationText, self:GetStyle("abilityStatValuePairValue"))
            statsSection:AddStatValuePair(rolesPair)
            ZO_ClearNumericallyIndexedTable(g_roleIconTable)
        end

        self:AddSection(statsSection)
    end

    function ZO_Tooltip:GetMechanicFlagStyle(mechanicFlag)
        if mechanicFlag == COMBAT_MECHANIC_FLAGS_MAGICKA then
            return self:GetStyle("abilityStatValuePairMagickaValue")
        elseif mechanicFlag == COMBAT_MECHANIC_FLAGS_STAMINA then
            return self:GetStyle("abilityStatValuePairStaminaValue")
        elseif mechanicFlag == COMBAT_MECHANIC_FLAGS_HEALTH then
            return self:GetStyle("abilityStatValuePairHealthValue")
        end
        return self:GetStyle("abilityStatValuePairValue")
    end

    function ZO_Tooltip:AddAbilityCosts(abilityId, overrideActiveRank, statsSection)
        local costAbility = GetCurrentChainedAbility(abilityId)
        local baseCost, mechanicFlags, isCostChargedPerTick = GetAbilityBaseCostInfo(costAbility, overrideActiveRank, "player")
        if baseCost == 0 or isCostChargedPerTick == true then
            -- If cost is definitely 0 or isCostChargedPerTick is true, we don't want to show
            -- anything for cost no matter what
            return
        end

        local isUnknownCost = baseCost == nil
        local isUnknownMechanics = mechanicFlags == nil
        local isUnknownIfCostChargedPerTick = isCostChargedPerTick == nil

        if isUnknownIfCostChargedPerTick or (isUnknownCost and isUnknownMechanics) then
            -- Super generic "we know nothing about the cost" variant
            local costPair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            costPair:SetStat(GetString(SI_ABILITY_TOOLTIP_RESOURCE_COST_LABEL), self:GetStyle("statValuePairStat"))
            costPair:SetValue(UNKNOWN_STAT_VALUE_TYPE_TEXT, self:GetStyle("abilityStatValuePairValue"))
            statsSection:AddStatValuePair(costPair)
            return
        end

        if mechanicFlags then
            -- Mechanics known, add a specific line for each
            for flag in ZO_FlagHelpers.MaskHasFlagsIterator(mechanicFlags) do
                local costPair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
                costPair:SetStat(GetString(SI_ABILITY_TOOLTIP_RESOURCE_COST_LABEL), self:GetStyle("statValuePairStat"))
                -- Cost may or may not be known
                local cost = isUnknownCost and UNKNOWN_STAT_VALUE_TEXT or GetAbilityCost(costAbility, flag, overrideActiveRank, "player")
                local mechanicName = GetString("SI_COMBATMECHANICFLAGS", flag)
                local costString = zo_strformat(SI_ABILITY_TOOLTIP_RESOURCE_COST, cost, mechanicName)
                local style = self:GetMechanicFlagStyle(flag)
                costPair:SetValue(costString, style)
                statsSection:AddStatValuePair(costPair)
            end
        else
            -- Don't know the mechanics but must know the cost (see super generic case above), just add a single generic cost line
            local costPair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            costPair:SetStat(GetString(SI_ABILITY_TOOLTIP_RESOURCE_COST_LABEL), self:GetStyle("statValuePairStat"))
            local costString = zo_strformat(SI_ABILITY_TOOLTIP_RESOURCE_COST, baseCost, UNKNOWN_STAT_VALUE_TYPE_TEXT)
            costPair:SetValue(costString, self:GetStyle("abilityStatValuePairValue"))
            statsSection:AddStatValuePair(costPair)
        end
    end

    function ZO_Tooltip:AddAbilityCostsOverTime(abilityId, overrideActiveRank, statsSection)
        local costAbility = GetCurrentChainedAbility(abilityId)
        local baseCost, mechanicFlags, isCostChargedPerTick = GetAbilityBaseCostInfo(costAbility, overrideActiveRank, "player")
        if isCostChargedPerTick == nil then
            -- Do nothing, AddAbilityCosts would have already added a line for this state
            return
        end

        if baseCost == 0 or not isCostChargedPerTick then
            -- If cost is definitely 0 or isCostChargedPerTick is false, we don't want to show
            -- anything for cost over time no matter what
            return
        end

        -- If we got this far, we definitely know we're cost over time

        local frequencyMS = GetAbilityFrequencyMS(costAbility, "player")
        if frequencyMS == 0 then
            -- If frequencyMS is definitely 0 we don't want to show anything no matter what
            return
        end

        local isUnknownCost = baseCost == nil
        local isUnknownMechanics = mechanicFlags == nil
        local isUnknownFrequency = frequencyMS == nil
        local formattedFrequency = frequencyMS and ZO_FormatTimeMilliseconds(frequencyMS, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT, TIME_FORMAT_PRECISION_TENTHS_RELEVANT, TIME_FORMAT_DIRECTION_NONE) or GetString(SI_ABILITY_TOOLTIP_UNKNOWN_SECONDS_SHORT)

        if mechanicFlags then
            -- Mechanics known, add a specific line for each
            for flag in ZO_FlagHelpers.MaskHasFlagsIterator(mechanicFlags) do
                local costPair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
                costPair:SetStat(GetString(SI_ABILITY_TOOLTIP_RESOURCE_COST_LABEL), self:GetStyle("statValuePairStat"))
                -- Cost may or may not be known
                local cost = isUnknownCost and UNKNOWN_STAT_VALUE_TEXT or GetAbilityCostPerTick(costAbility, flag, overrideActiveRank)
                local mechanicName = GetString("SI_COMBATMECHANICFLAGS", flag)
                local costOverTimeString = zo_strformat(SI_ABILITY_TOOLTIP_RESOURCE_COST_OVER_TIME, cost, mechanicName, formattedFrequency)
                local style = self:GetMechanicFlagStyle(flag)
                costPair:SetValue(costOverTimeString, style)
                statsSection:AddStatValuePair(costPair)
            end
        else
            -- Don't know the mechanics, just add a single generic cost line
            local costPair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            costPair:SetStat(GetString(SI_ABILITY_TOOLTIP_RESOURCE_COST_LABEL), self:GetStyle("statValuePairStat"))
            if isUnknownCost then
                if isUnknownFrequency then
                    costPair:SetValue(GetString(SI_ABILITY_TOOLTIP_UNKNOWN_COST_OVER_UNKNOWN_TIME), self:GetStyle("abilityStatValuePairValue"))
                else
                    local costOverTimeString = zo_strformat(SI_ABILITY_TOOLTIP_UNKNOWN_COST_OVER_TIME, formattedFrequency)
                    costPair:SetValue(costOverTimeString, self:GetStyle("abilityStatValuePairValue"))
                end
            else
                local costOverTimeString = zo_strformat(SI_ABILITY_TOOLTIP_RESOURCE_COST_OVER_TIME, baseCost, UNKNOWN_STAT_VALUE_TYPE_TEXT, formattedFrequency)
                costPair:SetValue(costOverTimeString, self:GetStyle("abilityStatValuePairValue"))
            end
            statsSection:AddStatValuePair(costPair)
        end
    end
end

function ZO_Tooltip:AddAbilityDescription(abilityId, overrideDescription, overrideCasterUnitTag)
    local descriptionHeader = GetAbilityDescriptionHeader(abilityId, overrideCasterUnitTag)
    local NO_OVERRIDE_RANK = nil
    local description = overrideDescription or GetAbilityDescription(abilityId, NO_OVERRIDE_RANK, overrideCasterUnitTag)
    local bodyDescriptionStyle = self:GetStyle("bodyDescription")
    if descriptionHeader ~= "" or description ~= "" then
        local descriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
        if descriptionHeader ~= "" then
            --descriptionHeader has already been run through grammar
            descriptionSection:AddLine(descriptionHeader, self:GetStyle("bodyHeader"))
        end
        if description ~= "" then
            --description has already been run through grammar
            descriptionSection:AddLine(description, bodyDescriptionStyle)
        end
        self:AddSection(descriptionSection)
    end

    for slotType = SCRIBING_SLOT_ITERATION_BEGIN, SCRIBING_SLOT_ITERATION_END do
        local scriptDescription = GenerateCraftedAbilityScriptSlotDescriptionForAbilityDescription(abilityId, slotType, overrideCasterUnitTag)
        if scriptDescription ~= "" then
            local descriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
            descriptionSection:AddLine(scriptDescription, bodyDescriptionStyle)
            self:AddSection(descriptionSection)
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

function ZO_Tooltip:LayoutSimpleAbility(abilityId, options)
    local omitHeader = options and options.omitHeader
    if not omitHeader then
        local headerSection = self:AcquireSection(self:GetStyle("abilityHeaderSection"))
        self:AddSectionEvenIfEmpty(headerSection)
    end

    local formattedAbilityName = ZO_CachedStrFormat(SI_ABILITY_NAME, GetAbilityName(abilityId))
    self:AddLine(formattedAbilityName, self:GetStyle("title"))

    if not IsAbilityPassive(abilityId) then
        self:AddAbilityStats(abilityId)
    end
    self:AddAbilityDescription(abilityId)
end

function ZO_Tooltip:LayoutEndlessDungeonBuffAbility(buffAbilityId, includeLifetimeStacks, stackCount)
    local buffType, isAvatarVision = GetAbilityEndlessDungeonBuffType(buffAbilityId)
    local buffBucketType = GetAbilityEndlessDungeonBuffBucketType(buffAbilityId)
    local showStacks = includeLifetimeStacks or ShouldAbilityShowStacks(buffAbilityId)
    if not stackCount then
        stackCount = showStacks and GetNumStacksForEndlessDungeonBuff(buffAbilityId, includeLifetimeStacks)
    end

    local headerSection = self:AcquireSection(self:GetStyle("abilityHeaderSection"))
    local buffBucketTypeText = ZO_CachedStrFormat(SI_ENDLESS_DUNGEON_BUFF_TYPE_FORMATTER, GetString("SI_ENDLESSDUNGEONBUFFBUCKETTYPE", buffBucketType))
    headerSection:AddLine(buffBucketTypeText, self:GetStyle("abilityHeader"))
    local buffTypeText = isAvatarVision and GetString("SI_ENDLESSDUNGEONBUFFTYPE_AVATAR", buffType) or GetString("SI_ENDLESSDUNGEONBUFFTYPE", buffType)
    buffTypeText = ZO_CachedStrFormat(SI_ENDLESS_DUNGEON_BUFF_TYPE_FORMATTER, buffTypeText)
    headerSection:AddLine(buffTypeText, self:GetStyle("abilityHeader"))
    if showStacks then
        headerSection:AddLine(zo_iconTextFormat("EsoUI/Art/Tooltips/icon_moras_gift.dds", 20, 20, stackCount), self:GetStyle("abilityStack"))
    end
    self:AddSection(headerSection)

    local abilityName = GetAbilityName(buffAbilityId)
    local formattedAbilityName
    if showStacks then
        formattedAbilityName = zo_strformat(SI_ABILITY_NAME_WITH_QUANTITY, abilityName, stackCount)
    else
        formattedAbilityName = ZO_CachedStrFormat(SI_ABILITY_NAME, abilityName)
    end
    self:AddLine(formattedAbilityName, self:GetStyle("title"))
    self:AddAbilityDescription(buffAbilityId)
end
