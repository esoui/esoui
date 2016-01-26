ZO_GamepadTradingHouse_EnchantmentFilters = ZO_GamepadTradingHouse_ModFilter:Subclass()

function ZO_GamepadTradingHouse_EnchantmentFilters:New()
    return ZO_GamepadTradingHouse_ModFilter.New(self, "GuildStoreBrowseEnchantmentFilter", ZO_TRADING_HOUSE_FILTER_ENCHANTMENT_TYPE_DATA, TRADING_HOUSE_FILTER_TYPE_ENCHANTMENT)
end