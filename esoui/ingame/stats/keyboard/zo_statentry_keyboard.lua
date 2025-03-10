ZO_StatEntry_Keyboard = ZO_InitializingObject:Subclass()

function ZO_StatEntry_Keyboard:Initialize(control, statType, statObject)
    self.control = control
    self.control.statEntry = self
    self.statType = statType
    self.statObject = statObject
    self.tooltipAnchorSide = RIGHT
    self.currentStatDelta = 0

    self.control.name:SetText(zo_strformat(SI_STAT_NAME_FORMAT, GetString("SI_DERIVEDSTATS", statType)))
    
    local function UpdateStatValue()
        self:UpdateStatValue()
    end
    self.control:RegisterForEvent(EVENT_STATS_UPDATED, UpdateStatValue)
    self.control:AddFilterForEvent(EVENT_STATS_UPDATED, REGISTER_FILTER_UNIT_TAG, "player")
    self.control:SetHandler("OnEffectivelyShown", UpdateStatValue)

    self.nextStatsRefreshSeconds = 0
    local function OnUpdate(_, currentFrameTimeSeconds)
        if self.nextStatsRefreshSeconds < currentFrameTimeSeconds then
            self:UpdateStatValue()
        end
    end

    self.control:SetHandler("OnUpdate", OnUpdate)
end

function ZO_StatEntry_Keyboard:GetPendingStatBonuses()
    if self.statObject then
        return self.statObject:GetPendingStatBonuses(self.statType)
    end
end

function ZO_StatEntry_Keyboard:GetValue()
    return GetPlayerStat(self.statType, STAT_BONUS_OPTION_APPLY_BONUS)
end

function ZO_StatEntry_Keyboard:GetDisplayValue(targetValue)
    local value = targetValue or self:GetValue()
    local statType = self.statType

    if statType == STAT_CRITICAL_STRIKE or statType == STAT_SPELL_CRITICAL then
        return zo_strformat(SI_STAT_VALUE_PERCENT, GetCriticalStrikeChance(value))
    else
        return tostring(value)
    end
end

function ZO_StatEntry_Keyboard:SetHasMundusEffect(hasMundusEffect)
    self.hasMundusEffect = hasMundusEffect
end

function ZO_StatEntry_Keyboard:UpdateMundusIcon()
    if self.hasMundusEffect then
        if not self.mundusIcon then
            local prefix = ""
            if self.statObject and self.statObject.virtualControlPrefix then
                prefix = self.statObject.virtualControlPrefix
            end
            self.mundusIcon = CreateControlFromVirtual(prefix .. "MundusIcon" .. self.statType, self.control, "ZO_StatMundusIcon")
            self.mundusIcon:SetAnchor(RIGHT)
        end
        self.mundusIcon:SetHidden(false)
    elseif self.mundusIcon then
        self.mundusIcon:SetHidden(true)
    end
end

function ZO_StatEntry_Keyboard:UpdateStatValue()
    if not self.control:IsHidden() then
        self.nextStatsRefreshSeconds = GetFrameTimeSeconds() + ZO_STATS_REFRESH_TIME_SECONDS
        local value = self:GetValue()
        local displayValue = self:GetDisplayValue()
        local pendingBonusAmount = self:GetPendingStatBonuses()

        if pendingBonusAmount and pendingBonusAmount > 0 then
            self.control.pendingBonus:SetHidden(false)
            self.control.pendingBonus:SetText(zo_strformat(SI_STAT_PENDING_BONUS_FORMAT, pendingBonusAmount))
        else
            self.control.pendingBonus:SetHidden(true)
        end

        local valueLabel = self.control.value
        local statChanged = displayValue ~= valueLabel:GetText()

        if statChanged then
            valueLabel:SetText(displayValue)
        end
        self.control.name:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())

        self:UpdateMundusIcon()
        self:UpdateStatComparisonValue()
    end
end

function ZO_StatEntry_Keyboard:UpdateStatComparisonValue()
    if not self.control:IsHidden() and not self.control.comparisonValue:IsHidden() and self.currentStatDelta and self.currentStatDelta ~= 0 then
        local comparisonStatValue = self:GetValue()
        if not self.currentStatExcludeDelta then
            comparisonStatValue = comparisonStatValue + self.currentStatDelta
        end
        local color
        local icon
        if self.currentStatDelta > 0 then
            color = ZO_SUCCEEDED_TEXT
            icon = "EsoUI/Art/Buttons/Gamepad/gp_upArrow.dds"
        else
            color = ZO_ERROR_COLOR
            icon = "EsoUI/Art/Buttons/Gamepad/gp_downArrow.dds"
        end
        local INHERIT_COLOR = true
        local comparisonValueString = zo_iconTextFormatNoSpace(icon, 24, 24, self:GetDisplayValue(comparisonStatValue), INHERIT_COLOR)
        comparisonValueString = color:Colorize(comparisonValueString)
        self.control.comparisonValue:SetText(comparisonValueString)
    end
end

function ZO_StatEntry_Keyboard:ShowComparisonValue(statDelta, excludeDelta)
    if statDelta and statDelta ~= 0 then
        self.currentStatDelta = statDelta
        self.currentStatExcludeDelta = excludeDelta
        self.control.value:SetHidden(true)
        self.control.comparisonValue:SetHidden(false)
        self:UpdateStatComparisonValue()
    end
end

function ZO_StatEntry_Keyboard:HideComparisonValue()
    self.currentStatDelta = 0
    self.control.comparisonValue:SetText("")
    self.control.comparisonValue:SetHidden(true)
    self.control.value:SetHidden(false)
end

function ZO_StatsEntry_OnMouseEnter(control)
    local statEntry = control.statEntry
    if statEntry then
        local statType = statEntry.statType
        local description = ZO_STAT_TOOLTIP_DESCRIPTIONS[statType]
        if description then
            InitializeTooltip(InformationTooltip, control, statEntry.tooltipAnchorSide, -5)

            local value = statEntry:GetValue()
            local displayValue = statEntry:GetDisplayValue()
            local statName = zo_strformat(SI_STAT_NAME_FORMAT, GetString("SI_DERIVEDSTATS", statType))

            InformationTooltip:AddLine(statName, "", ZO_NORMAL_TEXT:UnpackRGBA())
            InformationTooltip:AddLine(zo_strformat(description, displayValue))
        end
    end
end

function ZO_StatsEntry_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_AdvancedStatsEntry_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, RIGHT, -5)
    InformationTooltip:AddLine(zo_strformat(SI_STAT_NAME_FORMAT, control.statData.displayName), "", ZO_NORMAL_TEXT:UnpackRGBA())

    if control.statData.description then
        InformationTooltip:AddLine(zo_strformat(control.statData.description))
    end

    if control.statData.flatValue then
        local flatValueText = ZO_SELECTED_TEXT:Colorize(control.statData.flatValue)
        InformationTooltip:AddLine(zo_strformat(SI_STAT_RATING_TOOLTIP_FORMAT, control.statData.displayName, flatValueText), "", ZO_NORMAL_TEXT:UnpackRGBA())
    end
end

function ZO_AdvancedStatsEntry_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

-- Mundus stats

ZO_StatsMundus_ShouldShowHelpKeybind = false

function ZO_StatsMundusEntry_OnMouseEnter(control)
    InitializeTooltip(GameTooltip, control, control.mouseOverAnchor, control.mouseOverOffsetX)
    local buffSlot = control.buffSlot
    if buffSlot then
        GameTooltip:SetBuff(buffSlot, "player")
        ZO_StatsMundus_ShouldShowHelpKeybind = false
    else
        GameTooltip:AddLine(GetString(SI_STATS_MUNDUS_NONE_TOOLTIP_TITLE), "", ZO_NORMAL_TEXT:UnpackRGBA())
        GameTooltip:AddLine(GetString(SI_STATS_MUNDUS_NONE_TOOLTIP_DESCRIPTION), "", ZO_NORMAL_TEXT:UnpackRGBA())
        ZO_StatsMundus_ShouldShowHelpKeybind = true
    end
    local statEffects = control.statEffects
    if statEffects then
        for i, data in ipairs(statEffects) do
            local EXCLUDE_DELTA = true
            STATS:ShowComparisonForDerivedStat(data.statType, data.effect, EXCLUDE_DELTA)
        end
        ZO_CharacterWindowStats_ShowMundusComparisonValues(statEffects)
    end
    KEYBIND_STRIP:UpdateKeybindButtonGroup(STATS.keybindButtons)
    ZO_CharacterWindowStats_RefreshKeybinds()
    ZO_ADVANCED_STATS_WINDOW:SetMundusMouseAbility(control.abilityId)
    ZO_ADVANCED_STATS_WINDOW:UpdateAdvancedStats()
end

function ZO_StatsMundusEntry_OnMouseExit(control)
    ZO_StatsMundus_ShouldShowHelpKeybind = false
    local statEffects = control.statEffects
    if statEffects then
        for i, data in ipairs(statEffects) do
            STATS:HideComparisonForDerivedStat(data.statType)
        end
    end
    KEYBIND_STRIP:UpdateKeybindButtonGroup(STATS.keybindButtons)
    ZO_CharacterWindowStats_RefreshKeybinds()
    ClearTooltip(GameTooltip)
    ZO_ADVANCED_STATS_WINDOW:SetMundusMouseAbility()
    ZO_ADVANCED_STATS_WINDOW:UpdateAdvancedStats()
    ZO_CharacterWindowStats_HideComparisonValues()
end

-- Shared logic functions

-- Populates mundusIconControls passed in and returns table of shown mundus names
function ZO_SharedStats_SetupMundusIconControls(mundusIconControls, mouseOverAnchor, mouseOverOffsetX, GetDerivedStatByTypeFunction)
    local mundusStoneNameList = {}
    local activeMundusStoneBuffIndices = { GetUnitActiveMundusStoneBuffIndices("player") }
    local numActiveMundusStoneBuffs = #activeMundusStoneBuffIndices
    local numMundusSlots = GetNumAvailableMundusStoneSlots()
    local isPlayerAtMundusWarningLevel = GetUnitLevel("player") >= GetMundusWarningLevel()
    local mundusStoneNameListContainsBuff = false
    for i, control in ipairs(mundusIconControls) do
        control.statEffects = {}
        control.mouseOverAnchor = mouseOverAnchor
        control.mouseOverOffsetX = mouseOverOffsetX
        if i <= numMundusSlots - numActiveMundusStoneBuffs then
            local nameText = GetString("SI_MUNDUSSTONE", MUNDUS_STONE_INVALID)
            control.buffSlot = nil
            control.icon:SetTexture(ZO_STAT_MUNDUS_ICONS[MUNDUS_STONE_INVALID])
            if isPlayerAtMundusWarningLevel then
                control.icon:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
                nameText = ZO_ERROR_COLOR:Colorize(nameText)
            else
                control.icon:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
            end
            control:SetHidden(false)
            if mundusStoneNameListContainsBuff or #mundusStoneNameList == 0 then
                table.insert(mundusStoneNameList, 1, zo_strformat(SI_STATS_MUNDUS_FORMATTER, nameText))
            end
        elseif i <= numMundusSlots then
            local buffName, _, _, buffSlot, _, _, _, _, _, _, abilityId = GetUnitBuffInfo("player", activeMundusStoneBuffIndices[i - (numMundusSlots - numActiveMundusStoneBuffs)])
            local mundusStoneIndex = GetAbilityMundusStoneType(abilityId)
            control.buffSlot = buffSlot
            control.abilityId = abilityId
            control.icon:SetTexture(ZO_STAT_MUNDUS_ICONS[mundusStoneIndex])
            control.icon:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
            control:SetHidden(false)
            table.insert(mundusStoneNameList, 1, zo_strformat(SI_STATS_MUNDUS_FORMATTER, buffName))
            mundusStoneNameListContainsBuff = true

            local numStatsForAbility = GetAbilityNumDerivedStats(abilityId)
            for i = 1, numStatsForAbility do
                local statType, effectValue = GetAbilityDerivedStatAndEffectByIndex(abilityId, i)
                local statControl = GetDerivedStatByTypeFunction(statType)
                if statControl then
                    statControl.statEntry:SetHasMundusEffect(true)
                    statControl.statEntry:UpdateStatValue()
                end
                local statEffect =
                {
                    statType = statType,
                    effect = effectValue,
                }
                table.insert(control.statEffects, statEffect)
            end
        else
            control.buffSlot = nil
            control:SetHidden(true)
        end
    end
    return mundusStoneNameList
end