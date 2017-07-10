ZO_MarketCurrency_Shared = ZO_Object:Subclass()

function ZO_MarketCurrency_Shared:New(...)
    local marketCurrency = ZO_Object.New(self)
    marketCurrency:Initialize(...)
    return marketCurrency
end

function ZO_MarketCurrency_Shared:Initialize(control)
    self.control = control

    control:RegisterForEvent(EVENT_CROWN_UPDATE, function(eventId, ...) self:OnCrownsUpdated(...) end)
    control:RegisterForEvent(EVENT_CROWN_GEM_UPDATE, function(eventId, ...) self:OnCrownGemsUpdated(...) end)

    self:InitializeControls()

    self:OnCrownsUpdated(GetPlayerCrowns())
    self:OnCrownGemsUpdated(GetPlayerCrownGems())
end

function ZO_MarketCurrency_Shared:InitializeControls()
    -- To be overridden
end

-- difference is the difference in crowns for this update. For instance, new crowns purchased will show a positive difference.
function ZO_MarketCurrency_Shared:OnCrownsUpdated(currentCurrency, difference)
    -- To be overridden
end

function ZO_MarketCurrency_Shared:OnCrownGemsUpdated(currentCurrency, difference)
    -- To be overridden
end