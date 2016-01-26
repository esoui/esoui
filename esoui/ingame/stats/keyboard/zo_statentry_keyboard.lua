

local STAT_DESCRIPTIONS = {
    [STAT_HEALTH_MAX] = SI_STAT_TOOLTIP_HEALTH_MAX,
    [STAT_HEALTH_REGEN_IDLE] = SI_STAT_TOOLTIP_HEALTH_REGENERATION_IDLE,
    [STAT_HEALTH_REGEN_COMBAT] = SI_STAT_TOOLTIP_HEALTH_REGENERATION_COMBAT,
    [STAT_MAGICKA_MAX] = SI_STAT_TOOLTIP_MAGICKA_MAX,
    [STAT_MAGICKA_REGEN_IDLE] = SI_STAT_TOOLTIP_MAGICKA_REGENERATION_IDLE,
    [STAT_MAGICKA_REGEN_COMBAT] = SI_STAT_TOOLTIP_MAGICKA_REGENERATION_COMBAT,
    [STAT_STAMINA_MAX] = SI_STAT_TOOLTIP_STAMINA_MAX,
    [STAT_STAMINA_REGEN_IDLE] = SI_STAT_TOOLTIP_STAMINA_REGENERATION_IDLE,
    [STAT_STAMINA_REGEN_COMBAT] = SI_STAT_TOOLTIP_STAMINA_REGENERATION_COMBAT,
    [STAT_SPELL_POWER] = SI_STAT_TOOLTIP_SPELL_POWER,
    [STAT_SPELL_PENETRATION] = SI_STAT_TOOLTIP_SPELL_PENETRATION,
    [STAT_SPELL_CRITICAL] = SI_STAT_TOOLTIP_SPELL_CRITICAL,
    [STAT_ATTACK_POWER] = SI_STAT_TOOLTIP_ATTACK_POWER,
    [STAT_PHYSICAL_PENETRATION] = SI_STAT_TOOLTIP_PHYSICAL_PENETRATION,
    [STAT_CRITICAL_STRIKE] = SI_STAT_TOOLTIP_CRITICAL_STRIKE,
    [STAT_PHYSICAL_RESIST] = SI_STAT_TOOLTIP_PHYSICAL_RESIST,
    [STAT_SPELL_RESIST] = SI_STAT_TOOLTIP_SPELL_RESIST,
    [STAT_CRITICAL_RESISTANCE] = SI_STAT_TOOLTIP_CRITICAL_RESISTANCE,
    [STAT_POWER] = SI_STAT_TOOLTIP_POWER,
    [STAT_MITIGATION] = SI_STAT_TOOLTIP_MITIGATION,
    [STAT_SPELL_MITIGATION] = SI_STAT_TOOLTIP_SPELL_MITIGATION,
    [STAT_ARMOR_RATING] = SI_STAT_TOOLTIP_ARMOR_RATING,
    [STAT_WEAPON_POWER] = SI_STAT_TOOLTIP_WEAPON_POWER,
}

ZO_StatEntry_Keyboard = ZO_Object:Subclass()

function ZO_StatEntry_Keyboard:New(...)
    local statEntry = ZO_Object.New(self)
    statEntry:Initialize(...)
    return statEntry
end

function ZO_StatEntry_Keyboard:Initialize(control, statType, statObject)
    self.control = control
    self.control.statEntry = self
    self.statType = statType
    self.statObject = statObject
    self.tooltipAnchorSide = RIGHT

    self.control.name:SetText(GetString("SI_DERIVEDSTATS", statType))
    
    local function UpdateStatValue()
        self:UpdateStatValue()
    end
    self.control:RegisterForEvent(EVENT_STATS_UPDATED, UpdateStatValue)
    self.control:AddFilterForEvent(EVENT_STATS_UPDATED, REGISTER_FILTER_UNIT_TAG, "player")
    self.control:SetHandler("OnEffectivelyShown", UpdateStatValue)
end

function ZO_StatEntry_Keyboard:GetPendingStatBonuses()
    if self.statObject then
        return self.statObject:GetPendingStatBonuses(self.statType)
    end
end

function ZO_StatEntry_Keyboard:GetValue()
    return GetPlayerStat(self.statType, STAT_BONUS_OPTION_APPLY_BONUS, STAT_SOFT_CAP_OPTION_APPLY_SOFT_CAP)
end

function ZO_StatEntry_Keyboard:GetDisplayValue()
    local value = self:GetValue()
    local statType = self.statType

    if(statType == STAT_CRITICAL_STRIKE or statType == STAT_SPELL_CRITICAL) then
        local USE_MINIMUM = true
        return zo_strformat(SI_STAT_VALUE_PERCENT, GetCriticalStrikeChance(value, USE_MINIMUM))
    else
        return tostring(value)
    end
end

function ZO_StatEntry_Keyboard:UpdateStatValue()
    if not self.control:IsHidden() then
        local isBattleLeveled = self.statObject and self.statObject:IsPlayerBattleLeveled()
        local value = self:GetValue()
        local displayValue = self:GetDisplayValue()
        local pendingBonusAmount = self:GetPendingStatBonuses()

        if pendingBonusAmount and pendingBonusAmount > 0 then       -- We don't show any attribute stat increases while in battle leveled zones because
            self.control.pendingBonus:SetHidden(isBattleLeveled)    -- it doesn't make any sense based on how battle leveling now works
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
    end
end

function ZO_StatsEntry_OnMouseEnter(control)
    local statEntry = control.statEntry
    if statEntry then
        local statType = statEntry.statType
        local description = STAT_DESCRIPTIONS[statType]
        if description then
            InitializeTooltip(InformationTooltip, control, statEntry.tooltipAnchorSide, -5)

            local value = statEntry:GetValue()
            local displayValue = statEntry:GetDisplayValue()
            local statName = GetString("SI_DERIVEDSTATS", statType)

            InformationTooltip:AddLine(statName, "", ZO_NORMAL_TEXT:UnpackRGBA())
            InformationTooltip:AddLine(zo_strformat(description, displayValue))
        end
    end
end

function ZO_StatsEntry_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end