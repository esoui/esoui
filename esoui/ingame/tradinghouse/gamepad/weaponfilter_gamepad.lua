local GamepadWeaponFilter = ZO_CategorySubtypeFilter:Subclass()

function GamepadWeaponFilter:New()
    return ZO_CategorySubtypeFilter.New(self, "Weapon", ZO_TRADING_HOUSE_FILTER_WEAPON_TYPE_DATA, "weapon", ITEMTYPE_GLYPH_WEAPON)
end

function GamepadWeaponFilter:ApplyToSearch(search)
    search:SetFilter(TRADING_HOUSE_FILTER_TYPE_EQUIP, self.categoryType)
    search:SetFilter(TRADING_HOUSE_FILTER_TYPE_WEAPON, self.m_FilterSubType)
    ZO_GamepadTradingHouse_Filter.ApplyToSearch(self, search)
end

TRADING_HOUSE_GAMEPAD:RegisterSearchFilter(GamepadWeaponFilter, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_WEAPON)