local GuildItemsFilter = ZO_TradingHouseFilter:Subclass()

function GuildItemsFilter:New()
    return ZO_TradingHouseFilter.New(self)
end

function GuildItemsFilter:Initialize()
    local function GuildItemSearch()
        TRADING_HOUSE:AddGuildSpecificItems()
    end

    self.customSearchFunction = GuildItemSearch
end

TRADING_HOUSE:RegisterSearchFilter(GuildItemsFilter, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_GUILD_ITEMS)