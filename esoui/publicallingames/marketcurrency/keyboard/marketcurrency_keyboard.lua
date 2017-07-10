ZO_MarketCurrency_Keyboard = ZO_MarketCurrency_Shared:Subclass()

function ZO_MarketCurrency_Keyboard:New(...)
    return ZO_MarketCurrency_Shared.New(self,...)
end

function ZO_MarketCurrency_Keyboard:Initialize(control)
    ZO_MarketCurrency_Shared.Initialize(self, control)
    
    MARKET_CURRENCY_KEYBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)
end

function ZO_MarketCurrency_Keyboard:InitializeControls()
    local currencyContainer = self.control:GetNamedChild("Container")
    self.crownsContainer = currencyContainer:GetNamedChild("Crowns")
    self.crownsCurrencyLabel = self.crownsContainer:GetNamedChild("CurrencyValue")

    local crownsContainerWidth = self.crownsContainer:GetWidth()
    local crownsNameWidth = self.crownsContainer:GetNamedChild("CurrencyName"):GetWidth()
    self.crownsCurrencyLabel:SetWidth(crownsContainerWidth - crownsNameWidth)

    self.gemsContainer = currencyContainer:GetNamedChild("Gems")
    self.gemsCurrencyLabel = self.gemsContainer:GetNamedChild("CurrencyValue")

    local gemsContainerWidth = self.gemsContainer:GetWidth()
    local gemsNameWidth = self.gemsContainer:GetNamedChild("CurrencyName"):GetWidth()
    self.gemsCurrencyLabel:SetWidth(gemsContainerWidth - gemsNameWidth)
end

do
    local CURRENCY_ICON_SIZE = "100%"

    function ZO_MarketCurrency_Keyboard:OnCrownsUpdated(currentCurrency, difference)
        local crownsIcon = ZO_Currency_GetPlatformFormattedCurrencyIcon(ZO_Currency_MarketCurrencyToUICurrency(MKCT_CROWNS), CURRENCY_ICON_SIZE)
        local currencyString = zo_strformat(SI_CURRENCY_AMOUNT_WITH_ICON, ZO_CommaDelimitNumber(currentCurrency), crownsIcon)
        self.crownsCurrencyLabel:SetText(currencyString)
    end

    function ZO_MarketCurrency_Keyboard:OnCrownGemsUpdated(currentCurrency, difference)
        local gemsIcon = ZO_Currency_GetPlatformFormattedCurrencyIcon(ZO_Currency_MarketCurrencyToUICurrency(MKCT_CROWN_GEMS), CURRENCY_ICON_SIZE)
        local currencyString = zo_strformat(SI_CURRENCY_AMOUNT_WITH_ICON, ZO_CommaDelimitNumber(currentCurrency), gemsIcon)
        self.gemsCurrencyLabel:SetText(currencyString)
    end
end

function ZO_MarketCurrency_Keyboard:OnMouseEnterCurrencyLabel(control, currencyType)
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, -2)

    local currencyTooltip
    if currencyType == MKCT_CROWNS then
        currencyTooltip = GetString(SI_MARKET_CROWNS_TOOLTIP)
    elseif currencyType == MKCT_CROWN_GEMS then
        currencyTooltip = GetString(SI_MARKET_CROWN_GEMS_TOOLTIP)
    end

    SetTooltipText(InformationTooltip, currencyTooltip)
end

function ZO_MarketCurrency_Keyboard:OnMouseExitCurrencyLabel(control)
    ClearTooltip(InformationTooltip)
end

function ZO_MarketCurrency_Keyboard:SetBuyCrownsCallback(callback)
    self.customBuyCrownsCallback = callback
end

function ZO_MarketCurrency_Keyboard:OnBuyCrownsClicked(control)
    if self.customBuyCrownsCallback then
        self.customBuyCrownsCallback()
    else
        ShowBuyCrownsDialog()
    end
end

-- XML Handlers

function ZO_MarketCurrency_Keyboard_OnInitialized(control)
    MARKET_CURRENCY_KEYBOARD = ZO_MarketCurrency_Keyboard:New(control)
end

function ZO_MarketCurrency_OnMouseEnter(...)
    MARKET_CURRENCY_KEYBOARD:OnMouseEnterCurrencyLabel(...)
end

function ZO_MarketCurrency_OnMouseExit(...)
   MARKET_CURRENCY_KEYBOARD:OnMouseExitCurrencyLabel(...)
end

function ZO_MarketCurrencyBuyCrowns_OnClicked(...)
    MARKET_CURRENCY_KEYBOARD:OnBuyCrownsClicked(...)
end
