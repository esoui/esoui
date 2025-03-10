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
        local equipSlotHasItem = GetWornItemInfo(BAG_WORN, lowestEquipSlot)
        local lowestEquipItemText
        if equipSlotHasItem then
            local lowestEquipItemLink = GetItemLink(BAG_WORN, lowestEquipSlot)
            lowestEquipItemText = GetItemLinkName(lowestEquipItemLink)
            local displayQuality = GetItemLinkDisplayQuality(lowestEquipItemLink)
            local qualityColor = GetItemQualityColor(displayQuality)
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

function ZO_Tooltip:LayoutAttributeTooltip(statType, mundusEffectName)
    local statDescription = ZO_STAT_TOOLTIP_DESCRIPTIONS[statType]
    if statDescription then
        local headerSection = self:AcquireSection(self:GetStyle("title"))
        headerSection:AddLine(zo_strformat(SI_STAT_NAME_FORMAT, GetString("SI_DERIVEDSTATS", statType)))
        self:AddSection(headerSection)

        local bodySection = self:AcquireSection(self:GetStyle("attributeBody"))
        bodySection:AddLine(zo_strformat(statDescription, GetPlayerStat(statType)))
        self:AddSection(bodySection)
    end
    if mundusEffectName then
        local mundusSection = self:AcquireSection(self:GetStyle("attributeBody"))
        mundusSection:AddLine(zo_strformat(SI_STAT_GAMEPAD_MUNDUS_TOOLTIP_FORMATTER, ZO_SELECTED_TEXT:Colorize(mundusEffectName)))
        self:AddSection(mundusSection)
    end
end

function ZO_Tooltip:LayoutAdvancedAttributeTooltip(statData)
    --First, add the name of the stat
    local headerSection = self:AcquireSection(self:GetStyle("title"))
    headerSection:AddLine(zo_strformat(SI_STAT_NAME_FORMAT, statData.displayName))
    self:AddSection(headerSection)

    --If we have a description, add it
    if statData.description then
        local bodySection = self:AcquireSection(self:GetStyle("attributeBody"))
        bodySection:AddLine(zo_strformat(statData.description))
        self:AddSection(bodySection)
    end

    --If we need to show a flat value at the bottom of the tooltip, do that
    if statData.flatValue then
        local bodySection = self:AcquireSection(self:GetStyle("attributeBody"))
        local flatValueText = ZO_WHITE:Colorize(statData.flatValue)
        bodySection:AddLine(zo_strformat(SI_STAT_RATING_TOOLTIP_FORMAT, statData.displayName, flatValueText))
        self:AddSection(bodySection)
    end
end

function ZO_Tooltip:LayoutMundusTooltip(mundusData)
    local equipStatusText
    if mundusData.buffIndex then
        equipStatusText = GetString(SI_ITEM_FORMAT_STR_EQUIPPED)
    else
        equipStatusText = GetString(SI_ITEM_FORMAT_STR_NOT_EQUIPPED)
        if GetUnitLevel("player") >= GetMundusWarningLevel() then
            equipStatusText = ZO_ERROR_COLOR:Colorize(equipStatusText)
        end
    end
    local topSection = self:AcquireSection(self:GetStyle("topSection"))
    topSection:AddLine(equipStatusText, self:GetStyle("bind"))
    self:AddSection(topSection)

    if mundusData.name then
        local headerSection = self:AcquireSection(self:GetStyle("title"))
        headerSection:AddLine(zo_strformat(SI_STATS_MUNDUS_FORMATTER, mundusData.name))
        self:AddSection(headerSection)
    end

    if mundusData.description then
        local bodySection = self:AcquireSection(self:GetStyle("attributeBody"))
        bodySection:AddLine(zo_strformat(mundusData.description))
        self:AddSection(bodySection)
    end
end