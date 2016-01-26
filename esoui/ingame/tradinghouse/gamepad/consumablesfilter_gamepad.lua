local GamepadConsumablesFilter = ZO_GamepadCategoryFilter:Subclass()

function GamepadConsumablesFilter:New()
    return ZO_GamepadCategoryFilter.New(self, "Consumables", ZO_TRADING_HOUSE_FILTER_CONSUMABLES_TYPE_DATA)
end

TRADING_HOUSE_GAMEPAD:RegisterSearchFilter(GamepadConsumablesFilter, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_FOOD_AND_POTIONS)