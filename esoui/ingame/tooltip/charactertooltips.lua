function ZO_Tooltip:LayoutEquipmentBonusTooltip(equipmentBonus, lowestEquipSlot)
    local headerSection = self:AcquireSection(self:GetStyle("title"))
    headerSection:AddLine(GetString(SI_STATS_EQUIPMENT_BONUS))
    self:AddSection(headerSection)

    local generalTipSection = self:AcquireSection(self:GetStyle("attributeBody"))
    generalTipSection:AddLine(GetString(SI_STATS_EQUIPMENT_BONUS_GENERAL_TOOLTIP))
    self:AddSection(generalTipSection)

    local bonusValueSection = self:AcquireSection(self:GetStyle("attributeBody"))
    bonusValueSection:AddLine(GetString("SI_EQUIPMENTBONUS",  equipmentBonus), self:GetStyle("equipmentBonusValue"))
    self:AddSection(bonusValueSection)

    if equipmentBonus < EQUIPMENT_BONUS_SUPERIOR then
        local lowestPieceSection = self:AcquireSection(self:GetStyle("attributeBody"))
        local equipSlotHasItem = select(2, GetEquippedItemInfo(lowestEquipSlot))
        local lowestEquipItemText
        if equipSlotHasItem then
            local lowestEquipItemLink = GetItemLink(BAG_WORN, lowestEquipSlot)
            lowestEquipItemText = GetItemLinkName(lowestEquipItemLink)
            local quality = GetItemLinkQuality(lowestEquipItemLink)
            local qualityColor = GetItemQualityColor(quality)
            lowestEquipItemText = qualityColor:Colorize(lowestEquipItemText)
        else
            lowestEquipItemText = zo_strformat(SI_STATS_EQUIPMENT_BONUS_TOOLTIP_EMPTY_SLOT, GetString("SI_EQUIPSLOT", lowestEquipSlot))
            lowestEquipItemText = ZO_ERROR_COLOR:Colorize(lowestEquipItemText)
        end
        lowestPieceSection:AddLine(GetString(SI_STAT_GAMEPAD_EQUIPMENT_BONUS_LOWEST_PIECE), self:GetStyle("equipmentBonusLowestPieceHeader"))
        lowestPieceSection:AddLine(zo_strformat(SI_LINK_FORMAT_ITEM_NAME, lowestEquipItemText), self:GetStyle("equipmentBonusLowestPieceValue"))
        self:AddSection(lowestPieceSection)
    end
end

function ZO_Tooltip:LayoutAttributeTooltip(statType)
    local statDescription = ZO_STAT_TOOLTIP_DESCRIPTIONS[statType]
    if statDescription then
        local headerSection = self:AcquireSection(self:GetStyle("title"))
        headerSection:AddLine(GetString("SI_DERIVEDSTATS", statType))
        self:AddSection(headerSection)

        local bodySection = self:AcquireSection(self:GetStyle("attributeBody"))
        bodySection:AddLine(zo_strformat(statDescription, GetPlayerStat(statType)))
        self:AddSection(bodySection)
    end
end