ZO_GamepadTradingHouse_TraitFilters = ZO_GamepadTradingHouse_ModFilter:Subclass()

function ZO_GamepadTradingHouse_TraitFilters:New()
    return ZO_GamepadTradingHouse_ModFilter.New(self, "GuildStoreBrowseTraitFilter", ZO_TRADING_HOUSE_FILTER_TRAIT_TYPE_DATA, TRADING_HOUSE_FILTER_TYPE_TRAIT)
end