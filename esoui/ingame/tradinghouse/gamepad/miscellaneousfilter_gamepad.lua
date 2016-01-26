local GamepadMiscellaneousFilter = ZO_GamepadCategoryFilter:Subclass()

function GamepadMiscellaneousFilter:New()
    return ZO_GamepadCategoryFilter.New(self, "Miscellaneous", ZO_TRADING_HOUSE_FILTER_MISC_TYPE_DATA)
end

TRADING_HOUSE_GAMEPAD:RegisterSearchFilter(GamepadMiscellaneousFilter, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_OTHER)