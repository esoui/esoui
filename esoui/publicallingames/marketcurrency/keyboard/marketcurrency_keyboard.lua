ZO_MARKET_CURRENCY_BUTTON_TYPE_NONE = 0
ZO_MARKET_CURRENCY_BUTTON_TYPE_BUY_CROWNS = 1
ZO_MARKET_CURRENCY_BUTTON_TYPE_OPEN_ENDEAVORS = 2

ZO_MarketCurrency_Keyboard = ZO_MarketCurrency_Shared:Subclass()

function ZO_MarketCurrency_Keyboard:Initialize(control)
    ZO_MarketCurrency_Shared.Initialize(self, control)

    MARKET_CURRENCY_KEYBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)
end

function ZO_MarketCurrency_Keyboard:InitializeControls()
    self.container = self.control:GetNamedChild("Container")
    self.buyCrownsButton = self.container:GetNamedChild("BuyCrowns")
    self.endeavorsButton = self.container:GetNamedChild("Endeavors")

    self.currencyControls = {}
    for index, data in ipairs(self.marketCurrencyTypes) do
        local marketCurrencyType = data.marketCurrencyType
        local control = CreateControlFromVirtual("$(parent)Currency"..tostring(index), self.container, "ZO_MarketCurrencyLabel_Keyboard")
        self.currencyControls[marketCurrencyType] = control

        local controlLabel = control:GetNamedChild("Label")
        controlLabel:SetText(ZO_Currency_GetAmountLabel(data.currencyType))
        local TOTAL_CURRENCY_LABEL_WIDTH = 250
        control:GetNamedChild("Amount"):SetWidth(TOTAL_CURRENCY_LABEL_WIDTH - controlLabel:GetWidth())

        control:SetHandler("OnMouseEnter", function(...) self:OnCurrencyLabelMouseEnter(data.tooltip, ...) end, "tooltip")
        control:SetHandler("OnMouseExit", function(...) self:OnCurrencyLabelMouseExit(...) end, "tooltip")
        control:SetHandler("OnEffectivelyShown", function() self:OnMarketCurrencyUpdated(marketCurrencyType) end)
    end
end

function ZO_MarketCurrency_Keyboard:ShowMarketCurrencyButtonType(buttonType)
    self.buyCrownsButton:SetHidden(buttonType ~= ZO_MARKET_CURRENCY_BUTTON_TYPE_BUY_CROWNS)
    self.endeavorsButton:SetHidden(buttonType ~= ZO_MARKET_CURRENCY_BUTTON_TYPE_OPEN_ENDEAVORS)
end

function ZO_MarketCurrency_Keyboard:OnMarketCurrencyTypeVisibilityUpdated()
    local previousControl
    for _, data in ipairs(self.marketCurrencyTypes) do
        local control = self.currencyControls[data.marketCurrencyType]
        local visible = self:IsMarketCurrencyTypeVisible(data.marketCurrencyType)
        if visible then
            if previousControl then
                control:SetAnchor(BOTTOM, previousControl, TOP, 0, -5)
            else
                control:SetAnchor(BOTTOM, self.buyCrownsButton, TOP, 20, -20)
            end
            previousControl = control
        end

        control:SetHidden(not visible)
    end
end

function ZO_MarketCurrency_Keyboard:OnMarketCurrencyUpdated(marketCurrencyType)
    local control = self.currencyControls[marketCurrencyType]
    if not control:IsControlHidden() then
        local currencyData = self.marketCurrencyTypeMap[marketCurrencyType]
        local currencyAmount = GetPlayerMarketCurrency(marketCurrencyType)
        local currencyString = ZO_Currency_FormatKeyboard(currencyData.currencyType, currencyAmount, ZO_CURRENCY_FORMAT_AMOUNT_ICON)
        control:GetNamedChild("Amount"):SetText(currencyString)
    end
end

function ZO_MarketCurrency_Keyboard:OnCurrencyLabelMouseEnter(tooltip, control)
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, -2)
    SetTooltipText(InformationTooltip, tooltip)
end

function ZO_MarketCurrency_Keyboard:OnCurrencyLabelMouseExit(control)
    ClearTooltip(InformationTooltip)
end

-- XML Handlers

function ZO_MarketCurrency_Keyboard_OnInitialized(control)
    MARKET_CURRENCY_KEYBOARD = ZO_MarketCurrency_Keyboard:New(control)
end

function ZO_MarketCurrencyBuyCrowns_OnClicked(...)
    ZO_ShowBuyCrownsPlatformDialog()
end