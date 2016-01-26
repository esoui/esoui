local GamepadGuildItemsFilter = ZO_GamepadTradingHouse_Filter:Subclass()

function GamepadGuildItemsFilter:New()
    return ZO_GamepadTradingHouse_Filter.New(self)
end

function GamepadGuildItemsFilter:Initialize()
    local function GuildItemSearch()
        TRADING_HOUSE_GAMEPAD:AddGuildSpecificItems()
    end

    self.customSearchFunction = GuildItemSearch
end

-- Overridden
function GamepadGuildItemsFilter:SetHidden(hidden)
end

TRADING_HOUSE_GAMEPAD:RegisterSearchFilter(GamepadGuildItemsFilter, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_GUILD_ITEMS)