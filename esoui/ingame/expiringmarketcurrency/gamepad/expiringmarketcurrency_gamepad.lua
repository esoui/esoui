ZO_EXPIRING_MARKET_CURRENCY_ROW_GAMEPAD_HEIGHT = 55

local DATA_ENTRY_TYPE_EXPIRING_CURRENCY = 1

ZO_ExpiringMarketCurrency_Gamepad = ZO_DeferredInitializingObject:Subclass()

function ZO_ExpiringMarketCurrency_Gamepad:Initialize(control)
    self.control = control

    local fragment = ZO_FadeSceneFragment:New(control)
    ZO_DeferredInitializingObject.Initialize(self, fragment)
end

function ZO_ExpiringMarketCurrency_Gamepad:OnDeferredInitialize()
    local scrollChild = self.control:GetNamedChild("ContainerScrollChild")
    self.expiringCurrencyContainer = scrollChild:GetNamedChild("List")

    self.expiringCurrencyRowPool = ZO_ControlPool:New("ZO_ExpiringMarketCurrencyRow_Gamepad", self.expiringCurrencyContainer, "ExpiringCurrencyRow")
    self.expiringCurrencyDataEntries = {}

    self.emptyTextLabel = scrollChild:GetNamedChild("EmptyText")

    local function OnCrownsUpdated()
        if self:IsShowing() then
            RequestExpiringMarketCurrencyInfo()
        end
    end
    EVENT_MANAGER:RegisterForEvent("ZO_ExpiringMarketCurrency_Gamepad", EVENT_CROWN_UPDATE, OnCrownsUpdated)

    local function OnExpiringMarketCurrencyStateUpdated(eventId, state)
        if self:IsShowing() and state == EXPIRING_MARKET_CURRENCY_STATE_READY then
            self:LayoutExpiringMarketCurrency()
        end
    end
    EVENT_MANAGER:RegisterForEvent("ZO_ExpiringMarketCurrency_Gamepad", EVENT_EXPIRING_MARKET_CURRENCY_STATE_UPDATED, OnExpiringMarketCurrencyStateUpdated)

    self.nextUpdateTimeSeconds = nil
    local function OnUpdate(control, seconds)
        -- Ensure that refresh only occurs on second boundaries
        if not self.nextUpdateTimeSeconds or seconds > self.nextUpdateTimeSeconds then
            self.nextUpdateTimeSeconds = zo_floor(seconds + ZO_ONE_MINUTE_IN_SECONDS)
            self:LayoutExpiringMarketCurrency()
        end
    end

    self.control:SetHandler("OnUpdate", OnUpdate)
end

function ZO_ExpiringMarketCurrency_Gamepad:OnShowing()
    RequestExpiringMarketCurrencyInfo()

    self:LayoutExpiringMarketCurrency()
end

function ZO_ExpiringMarketCurrency_Gamepad:OnHiding()
    self.expiringCurrencyRowPool:ReleaseAllObjects()
end

function ZO_ExpiringMarketCurrency_Gamepad:LayoutExpiringCurrencyRow(entryData, previousControl)
    local rowControl = self.expiringCurrencyRowPool:AcquireObject()

    local textColor = ZO_SELECTED_TEXT
    if entryData.timeLeftS < EXPIRING_MARKET_CURRENCY_WARNING_THRESHOLD_SECONDS then
        textColor = ZO_ERROR_COLOR
    end

    local expiresAtLabel = rowControl:GetNamedChild("ExpiresAt")
    local formattedTimeLeft = ZO_FormatTimeLongDurationExpiration(entryData.timeLeftS)
    expiresAtLabel:SetText(formattedTimeLeft)
    expiresAtLabel:SetColor(textColor:UnpackRGB())

    local amountLabel = rowControl:GetNamedChild("Amount")
    local formattedCrownAmount = ZO_Currency_FormatKeyboard(CURT_CROWNS, entryData.currencyAmount, ZO_CURRENCY_FORMAT_AMOUNT_ICON, {color = ZO_SELECTED_TEXT})
    amountLabel:SetText(formattedCrownAmount)

    if previousControl then
        rowControl:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, 5)
    else
        rowControl:SetAnchor(TOPLEFT, self.expiringCurrencyContainer, TOPLEFT, 0, 10)
    end
    return rowControl
end

function ZO_ExpiringMarketCurrency_Gamepad:LayoutExpiringMarketCurrency()
    self.expiringCurrencyRowPool:ReleaseAllObjects()
    ZO_ClearNumericallyIndexedTable(self.expiringCurrencyDataEntries)

    local numExpiringMarketCurrencyInfos = GetNumExpiringMarketCurrencyInfos()

    if numExpiringMarketCurrencyInfos == 0 then
        self.expiringCurrencyContainer:SetHidden(true)
        self.emptyTextLabel:SetHidden(false)
        return
    end

    self.expiringCurrencyContainer:SetHidden(false)
    self.emptyTextLabel:SetHidden(true)

    local previousControl = nil
    for i = 1, numExpiringMarketCurrencyInfos do
        local currencyAmount, timeLeftS = GetExpiringMarketCurrencyInfo(i)
        
        local entryData =
        {
            currencyAmount = currencyAmount,
            timeLeftS = timeLeftS,
        }
        table.insert(self.expiringCurrencyDataEntries, entryData)

        local rewardControl = self:LayoutExpiringCurrencyRow(entryData, previousControl)
        previousControl = rewardControl
    end
end

function ZO_ExpiringMarketCurrency_Gamepad:GetNarrationText()
    local narrations = {}
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_EXPIRING_CROWNS_DESCRIPTION_TEXT)))

    if #self.expiringCurrencyDataEntries == 0 then
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_EXPIRING_CROWNS_EMPTY_TEXT)))
    else
        for i, entryData in ipairs(self.expiringCurrencyDataEntries) do
            local formattedNarrationString = zo_strformat(SI_EXPIRING_CROWNS_AMOUNT_NARRATION_FORMAT, entryData.currencyAmount)
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(formattedNarrationString))

            local formattedTimeLeft = ZO_FormatTimeLongDurationExpirationNarration(entryData.timeLeftS)
            formattedNarrationString = zo_strformat(SI_EXPIRING_CROWNS_EXPIRES_AT_NARRATION_FORMAT, formattedTimeLeft)
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(formattedNarrationString))
        end
    end

    return narrations
end

function ZO_ExpiringMarketCurrency_Gamepad.OnControlInitialized(control)
    ZO_EXPIRING_MARKET_CURRENCY_GAMEPAD = ZO_ExpiringMarketCurrency_Gamepad:New(control)
end
