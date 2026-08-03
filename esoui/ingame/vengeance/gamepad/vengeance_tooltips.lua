function ZO_Tooltip:LayoutLoadoutStatComparison(selectedLoadoutData)
    if not selectedLoadoutData then
        return
    end

    local equippedLoadoutData = ZO_VENGEANCE_MANAGER:GetEquippedLoadoutData()
    if not equippedLoadoutData then
        return
    end

    for _, statGroup in ipairs(ZO_INVENTORY_STAT_GROUPS) do
        local statSection = self:AcquireSection(self:GetStyle("itemComparisonStatSection"))
        for _, statType in ipairs(statGroup) do
            local statName = zo_strformat(SI_STAT_NAME_FORMAT, GetString("SI_DERIVEDSTATS", statType))
            local equippedValue = equippedLoadoutData:GetDerivedStatValueByStatType(statType)
            local selectedValue = selectedLoadoutData:GetDerivedStatValueByStatType(statType)
            local statDelta = selectedValue - equippedValue
            local valueToShow = selectedValue

            if statType == STAT_SPELL_CRITICAL or statType == STAT_CRITICAL_STRIKE then
                local newPercent = GetCriticalStrikeChance(valueToShow)
                valueToShow = zo_strformat(SI_STAT_VALUE_PERCENT, newPercent)
            end

            local colorStyle = self:GetStyle("itemComparisonStatValuePairDefaultColor")
            if statDelta ~= 0 then
                local icon
                if statDelta > 0 then
                    colorStyle = self:GetStyle("succeeded")
                    icon = "EsoUI/Art/Buttons/Gamepad/gp_upArrow.dds"
                else
                    colorStyle = self:GetStyle("failed")
                    icon = "EsoUI/Art/Buttons/Gamepad/gp_downArrow.dds"
                end
                local INHERIT_COLOR = true
                local NO_GRAMMAR = true
                valueToShow = zo_iconTextFormatNoSpaceAlignedRight(icon, 24, 24, valueToShow, INHERIT_COLOR, NO_GRAMMAR)
            end

            local statValuePair = statSection:AcquireStatValuePair(self:GetStyle("itemComparisonStatValuePair"))
            statValuePair:SetStat(statName, self:GetStyle("statValuePairStat"))
            statValuePair:SetValue(valueToShow, self:GetStyle("itemComparisonStatValuePairValue"), colorStyle)
            statSection:AddStatValuePair(statValuePair)
        end
        self:AddSection(statSection)
    end
end

function ZO_Tooltip:LayoutPerkTooltip(perkData, slot)
    if perkData and slot then
        local perkSlotSection = self:AcquireSection(self:GetStyle("bodyHeader"))
        local perkSlotText = ZO_VENGEANCE_MANAGER:GetPerkColorBySlot(slot):Colorize(zo_strformat(SI_CAMPAIGN_VENGEANCE_PERKS_SLOT, ZO_VENGEANCE_MANAGER:GetPerkSlotName(perkData:GetSlot())))
        perkSlotSection:AddLine(perkSlotText)
        self:AddSection(perkSlotSection)

        local titleTextSection = self:AcquireSection(self:GetStyle("title"))
        titleTextSection:AddLine(perkData:GetFormattedName())
        self:AddSection(titleTextSection)

        local descriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
        descriptionSection:AddLine(perkData:GetTooltipText(), self:GetStyle("bodyDescription"))
        self:AddSection(descriptionSection)

        local isDisabled, reason = perkData:IsPerkDisabled()
        if isDisabled then
            local errorSection = self:AcquireSection(self:GetStyle("bodySection"))
            local errorText
            if reason == VENGEANCE_ACTION_RESULT_PERK_LOCKED then
                errorText = zo_strformat(GetString("SI_VENGEANCEACTIONRESULT", reason), perkData:GetRankRequirement())
            else
                errorText = GetString("SI_VENGEANCEACTIONRESULT", reason)
            end
            errorSection:AddLine(errorText, self:GetStyle("requirementFail"))
            self:AddSection(errorSection)
        end
    end
end