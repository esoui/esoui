ZO_ArmorFilter_Shared = ZO_Object:Subclass()

function ZO_ArmorFilter_Shared:ApplyCategoryFilterToSearch(search, subType)
    if(self.m_mode == "normal") then
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_ARMOR, self.m_armorType)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_EQUIP, subType)
    elseif(self.m_mode == "shield") then
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_EQUIP, EQUIP_TYPE_OFF_HAND)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_WEAPON, WEAPONTYPE_SHIELD)
    elseif(self.m_mode == "accessory") then
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_EQUIP, subType)
    end
end