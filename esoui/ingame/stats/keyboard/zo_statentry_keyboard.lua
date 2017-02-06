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
    return GetPlayerStat(self.statType, STAT_BONUS_OPTION_APPLY_BONUS, STAT_SOFT_CAP_OPTION_APPLY_SOFT_CAP)
end

function ZO_StatEntry_Keyboard:GetDisplayValue(targetValue)
    local value = targetValue or self:GetValue()
    local statType = self.statType

    if(statType == STAT_CRITICAL_STRIKE or statType == STAT_SPELL_CRITICAL) then
        return zo_strformat(SI_STAT_VALUE_PERCENT, GetCriticalStrikeChance(value))
    else
        return tostring(value)
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
    end
end

function ZO_StatEntry_Keyboard:ShowComparisonValue(statDelta)
    if statDelta and statDelta ~= 0 then
        local comparisonStatValue = self:GetValue() + statDelta
        local color
        local icon
        if statDelta > 0 then
            color = ZO_SUCCEEDED_TEXT
            icon = "EsoUI/Art/Buttons/Gamepad/gp_upArrow.dds"
        else
            color = ZO_ERROR_COLOR
            icon = "EsoUI/Art/Buttons/Gamepad/gp_downArrow.dds"
        end

        comparisonValueString = zo_iconFormatInheritColor(icon, 24, 24) .. self:GetDisplayValue(comparisonStatValue)
        comparisonValueString = color:Colorize(comparisonValueString)

        self.control.value:SetHidden(true)
        self.control.comparisonValue:SetHidden(false)
        self.control.comparisonValue:SetText(comparisonValueString)
    end
end

function ZO_StatEntry_Keyboard:HideComparisonValue()
    if not self.control.comparisonValue:IsHidden() then
        self.control.comparisonValue:SetText("")
        self.control.comparisonValue:SetHidden(true)
        self.control.value:SetHidden(false)
    end
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
            local statName = GetString("SI_DERIVEDSTATS", statType)

            InformationTooltip:AddLine(statName, "", ZO_NORMAL_TEXT:UnpackRGBA())
            InformationTooltip:AddLine(zo_strformat(description, displayValue))
        end
    end
end

function ZO_StatsEntry_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end