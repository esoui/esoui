ZO_MarketCurrency_Shared = ZO_InitializingObject:Subclass()

function ZO_MarketCurrency_Shared:Initialize(control)
    self.control = control

    local IS_PLURAL = false
    local IS_UPPER = false
    -- List order determines display order. Note: All currency types default to visible.
    self.marketCurrencyTypes =
    {
        {
            marketCurrencyType = MKCT_CROWNS,
            tooltip = zo_strformat(SI_MARKET_CURRENCY_TOOLTIP, GetCurrencyName(CURT_CROWNS, IS_PLURAL, IS_UPPER)),
        },
        {
            marketCurrencyType = MKCT_CROWN_GEMS,
            tooltip = zo_strformat(SI_MARKET_CURRENCY_TOOLTIP, GetCurrencyName(CURT_CROWN_GEMS, IS_PLURAL, IS_UPPER)),
        },
        {
            marketCurrencyType = MKCT_ENDEAVOR_SEALS,
            tooltip = zo_strformat(SI_MARKET_CURRENCY_TOOLTIP, GetCurrencyName(CURT_ENDEAVOR_SEALS, IS_PLURAL, IS_UPPER)),
        },
    }
    internalassert(MKCT_MAX_VALUE == MKCT_ENDEAVOR_SEALS, "New market currency types must be configured.")

    self.marketCurrencyTypeMap = {}
    for _, data in ipairs(self.marketCurrencyTypes) do
        data.currencyType = GetCurrencyTypeFromMarketCurrencyType(data.marketCurrencyType)
        self.marketCurrencyTypeMap[data.marketCurrencyType] = data
    end

    -- Order matters
    self:InitializeControls()
    self:InitializeEventHandlers()

    -- Currency layout initialization
    self:OnMarketCurrencyTypeVisibilityUpdated()
end

function ZO_MarketCurrency_Shared:InitializeControls()
    -- To be overridden
end

function ZO_MarketCurrency_Shared:InitializeEventHandlers()
    local function OnCurrencyUpdate(_, currencyType)
        local marketCurrencyType = GetMarketCurrencyTypeFromCurrencyType(currencyType)
        if self.marketCurrencyTypeMap[marketCurrencyType] then
            self:OnMarketCurrencyUpdated(marketCurrencyType)
        end
    end

    self.control:RegisterForEvent(EVENT_CURRENCY_UPDATE, OnCurrencyUpdate)
end

function ZO_MarketCurrency_Shared:SetVisibleMarketCurrencyTypes(marketCurrencyTypes)
    local visibleMarketCurrencyTypes = {}
    if marketCurrencyTypes then
        for _, marketCurrencyType in ipairs(marketCurrencyTypes) do
            visibleMarketCurrencyTypes[marketCurrencyType] = true
        end
    end

    for marketCurrencyType, data in pairs(self.marketCurrencyTypeMap) do
        data.visible = visibleMarketCurrencyTypes[marketCurrencyType] == true
    end

    self:OnMarketCurrencyTypeVisibilityUpdated()
end

function ZO_MarketCurrency_Shared:IsMarketCurrencyTypeVisible(marketCurrencyType)
    -- The default is true, so nil is interpreted as true
    return self.marketCurrencyTypeMap[marketCurrencyType].visible ~= false
end

function ZO_MarketCurrency_Shared:OnMarketCurrencyTypeVisibilityUpdated()
    -- To be overriden
end

function ZO_MarketCurrency_Shared:OnMarketCurrencyUpdated(currencyType)
    -- To be overridden
end