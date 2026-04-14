function ZO_Tooltip:LayoutVeterancyPerkTooltip(veterancyPerkData)
    if veterancyPerkData then
        local veterancyRankPerkRewardData = veterancyPerkData:GetVeterancyRankPerkRewardData()
        local perkSlotSection = self:AcquireSection(self:GetStyle("bodyHeader"))
        local slotFlags = veterancyRankPerkRewardData:GetSlotFlags()
        for slot in ZO_FlagHelpers.FlagIterator(VENGEANCE_PERK_SLOT_RED, VENGEANCE_PERK_SLOT_BLUE) do
            if ZO_FlagHelpers.MaskHasFlag(slotFlags, slot) then
                local perkSlotText = ZO_VENGEANCE_MANAGER:GetPerkColorBySlot(slot):Colorize(zo_strformat(SI_CAMPAIGN_VENGEANCE_PERKS_SLOT, ZO_VENGEANCE_MANAGER:GetPerkSlotName(slot)))
                perkSlotSection:AddLine(perkSlotText)
            end
        end
        self:AddSection(perkSlotSection)

        local titleTextSection = self:AcquireSection(self:GetStyle("title"))
        titleTextSection:AddLine(veterancyPerkData:GetFormattedName())
        self:AddSection(titleTextSection)

        local descriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
        descriptionSection:AddLine(GetVengeancePerkTooltipText(veterancyPerkData:GetRewardId()), self:GetStyle("bodyDescription"))
        self:AddSection(descriptionSection)
    end
end