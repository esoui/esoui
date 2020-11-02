ZO_MarketCurrency_Gamepad = ZO_Object.MultiSubclass(ZO_MarketCurrency_Shared, ZO_CallbackObject)

local MARKET_BUY_CROWNS_BUTTON =
{
    alignment = KEYBIND_STRIP_ALIGN_RIGHT,
    gamepadOrder = 1,
    name = GetString(SI_MARKET_BUY_CROWNS),
    keybind = "UI_SHORTCUT_SECONDARY",
    callback = ZO_ShowBuyCrownsPlatformDialog,
}

function ZO_MarketCurrency_Gamepad:New(...)
    local marketCurrency = ZO_CallbackObject.New(self)
    marketCurrency:Initialize(...)
    return marketCurrency
end

function ZO_MarketCurrency_Gamepad:Initialize(control)
    ZO_MarketCurrency_Shared.Initialize(self, control)

    MARKET_CURRENCY_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control)
end

function ZO_MarketCurrency_Gamepad:InitializeControls()
    self.crownAmountControl = self.control:GetNamedChild("CrownsAmount")
    self.gemAmountControl = self.control:GetNamedChild("GemsAmount")
end

function ZO_MarketCurrency_Gamepad:GetBuyCrownsKeybind(keybind)
    local keybindInfo = ZO_ShallowTableCopy(MARKET_BUY_CROWNS_BUTTON)
    if keybind then
        keybindInfo.keybind = keybind
    end
    return keybindInfo
end

function ZO_MarketCurrency_Gamepad:Show()
    self.control:SetHidden(false)
end

function ZO_MarketCurrency_Gamepad:Hide()
    self.control:SetHidden(true)
end

function ZO_MarketCurrency_Gamepad:OnCrownsUpdated(currentCurrency, difference)
    local crownAmount = ZO_Currency_FormatGamepad(CURT_CROWNS, currentCurrency, ZO_CURRENCY_FORMAT_AMOUNT_ICON)
    self.crownAmountControl:SetText(crownAmount)
    self:FireCallbacks("OnCurrencyUpdated")
end

function ZO_MarketCurrency_Gamepad:OnCrownGemsUpdated(currentCurrency, difference, reason)
    local gemAmount = ZO_Currency_FormatGamepad(CURT_CROWN_GEMS, currentCurrency, ZO_CURRENCY_FORMAT_AMOUNT_ICON)
    self.gemAmountControl:SetText(gemAmount)
    self:FireCallbacks("OnCurrencyUpdated")
end

function ZO_MarketCurrency_Gamepad:ModifyKeybindStripStyleForCurrency(originalStyle)
    local style = ZO_ShallowTableCopy(originalStyle)
    style.rightAnchorRelativeToControl = self.control
    style.rightAnchorRelativePoint = LEFT
    style.rightAnchorOffset = 0
    return style
end

function ZO_MarketCurrency_Gamepad_OnInitialized(control)
    MARKET_CURRENCY_GAMEPAD = ZO_MarketCurrency_Gamepad:New(control)
end