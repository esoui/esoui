CURRENCY_INPUT = nil
ZO_CurrencyInputObject = ZO_Object:Subclass()

function ZO_CurrencyInputObject:New(...)
    local currencyInput = ZO_Object.New(self)
    currencyInput:Initialize(...)
    return currencyInput
end

function ZO_CurrencyInputObject:Initialize(control, pulseAnimTemplate)
    self.control = control
    self.currencyField = control:GetNamedChild("Amount")
    self.maxCurrency = nil
    self.mouseRefCount = 0
    self:Reset()

    local bg = control:GetNamedChild("BG")
    self.pulseTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual(pulseAnimTemplate, control:GetNamedChild("BG"))
    self.badInputTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("CurrencyInputBadInput", control:GetNamedChild("BG"))

    self.badInputTimeline:SetHandler("OnPlay", function() bg:SetAlpha(1) self.pulseTimeline:Stop() end)
    self.badInputTimeline:SetHandler("OnStop", function() self.pulseTimeline:PlayFromStart(1000) end)

    self.globalMouseDownHandler =   function(eventCode, button, ctrl, alt, shift)
                                        if(button == MOUSE_BUTTON_INDEX_LEFT and not MouseIsOver(self.control)) then
                                            self:DecrementRefCount()
                                        end
                                    end
end

function ZO_CurrencyInputObject:Reset()
    self:SetCurrencyAmount(0, "update")
end

function ZO_CurrencyInputObject:SetUsePlayerCurrencyAsMax(usePlayerCurrencyAsMax)
    self.usePlayerCurrencyAsMax = usePlayerCurrencyAsMax
end

function ZO_CurrencyInputObject:IsUsingPlayerCurrencyAsMax()
    return self.usePlayerCurrencyAsMax
end

function ZO_CurrencyInputObject:SetMaxCurrency(maxCurrency)
    self:SetUsePlayerCurrencyAsMax(false)
    self.maxCurrency = maxCurrency
    if self.maxCurrency and self:GetTotalCurrency() > self.maxCurrency then
        self:SetCurrencyAmount(self.maxCurrency, "update")
    end
end

function ZO_CurrencyInputObject:GetMaxCurrency()
    if(self:IsUsingPlayerCurrencyAsMax()) then
        return GetCurrencyAmount(self.currencyType, CURRENCY_LOCATION_CHARACTER)
    elseif(self.maxCurrency) then
        return self.maxCurrency
    end

    return MAX_PLAYER_CURRENCY --May need an enum for this if we pick a different max for other currency types.
end

function ZO_CurrencyInputObject:GetTotalCurrency()
     return self.currencyAmount
end

function ZO_CurrencyInputObject:GetTotalCurrencyAsText()
    return self.currencyField:GetText()
end

function ZO_CurrencyInputObject:DoCallback(eventType)
    if(self.callback) then
        self:callback(self.currencyAmount, eventType)
    end
end

local CURRENCY_INPUT_CURRENCY_OPTIONS =
{
    showTooltips = false,
    font = "ZoFontWinT1",
}

function ZO_CurrencyInputObject:SetCurrencyAmount(currency, eventType)
    if self.currencyAmount ~= currency or self.currencyTypeChanged then
        self.currencyAmount = zo_min(currency, self:GetMaxCurrency())
        ZO_CurrencyControl_SetSimpleCurrency(self.currencyField, self.currencyType, self.currencyAmount, CURRENCY_INPUT_CURRENCY_OPTIONS, CURRENCY_SHOW_ALL)
    end

    self:DoCallback(eventType or "update")
end

local CONFIRM_ENTRY = -1
local CANCEL_ENTRY = -2
local BACKSPACE_ENTRY = -3
local CLEAR_ENTRY = -4

local keyMapping =
{
    [KEY_0] = 0,
    [KEY_1] = 1,
    [KEY_2] = 2,
    [KEY_3] = 3,
    [KEY_4] = 4,
    [KEY_5] = 5,
    [KEY_6] = 6,
    [KEY_7] = 7,
    [KEY_8] = 8,
    [KEY_9] = 9,
    [KEY_NUMPAD0] = 0,
    [KEY_NUMPAD1] = 1,
    [KEY_NUMPAD2] = 2,
    [KEY_NUMPAD3] = 3,
    [KEY_NUMPAD4] = 4,
    [KEY_NUMPAD5] = 5,
    [KEY_NUMPAD6] = 6,
    [KEY_NUMPAD7] = 7,
    [KEY_NUMPAD8] = 8,
    [KEY_NUMPAD9] = 9,
    [KEY_NUMPAD_ENTER] = CONFIRM_ENTRY,
    [KEY_ENTER] = CONFIRM_ENTRY,
    [KEY_ESCAPE] = CANCEL_ENTRY,
    [KEY_BACKSPACE] = BACKSPACE_ENTRY,
    [KEY_DELETE] = CLEAR_ENTRY,
}

function ZO_CurrencyInputObject:OnKeyDown(key, ctrl, alt, shift)
    local keyValue = keyMapping[key]
    if(keyValue ~= nil) then
        local currency = self.currencyAmount
        local eventType = "update"
        local hideAfterEvent = false

        if(keyValue >= 0) then
            if(self.resetAmountOnKeyInput) then
                currency = 0
            end

            currency = (currency * 10) + keyValue

            -- Don't allow users to enter more currency than they have, just reset to what the control used to have
            if (self.maxCurrency and self.maxCurrency < currency) or (self:IsUsingPlayerCurrencyAsMax() and GetCurrencyAmount(self.currencyType, CURRENCY_LOCATION_CHARACTER) < currency) then
                self.badInputTimeline:PlayFromStart()
                currency = self.currencyAmount
            end
        else
            if(keyValue == CONFIRM_ENTRY) then
                eventType = "confirm"
                hideAfterEvent = true
            elseif(keyValue == CANCEL_ENTRY) then
                eventType = "cancel"
                hideAfterEvent = true
            elseif(keyValue == BACKSPACE_ENTRY) then
                if currency == 0 then
                    self.badInputTimeline:PlayFromStart()
                else
                    currency = zo_floor(currency / 10)
                end
            elseif(keyValue == CLEAR_ENTRY) then
                currency = 0 -- just clear and update, do not cancel
            end            
        end

        -- No matter what, at this point the user has typed something, go ahead and prevent future inputs
        -- from resetting anything
        self.resetAmountOnKeyInput = false

        self:SetCurrencyAmount(currency, eventType)

        if(hideAfterEvent) then
            self:Hide()
        end
    else
        self.badInputTimeline:PlayFromStart()
    end
end

function ZO_CurrencyInputObject:Show(callback, playerCurrencyAsMaxOrMaxCurrency, initialCurrencyAmount, currencyType, anchorTo, offsetX, offsetY)
    self.mouseRefCount = 1 -- assume it's always shown because of mouse input for now
    self.resetAmountOnKeyInput = true
    self.currencyTypeChanged = self.currencyType ~= currencyType
    self.currencyType = currencyType

    local control = self.control
    if(control:IsHidden() == false) then return end

    control:SetHidden(false)
    control:RegisterForEvent(EVENT_GLOBAL_MOUSE_DOWN, self.globalMouseDownHandler)

    if(anchorTo) then
        control:ClearAnchors()
        control:SetAnchorFill(anchorTo)

        local inputField = self.currencyField
        inputField:ClearAnchors()
        inputField:SetAnchor(LEFT)
        inputField:SetAnchor(RIGHT, nil, RIGHT, offsetX, offsetY)
    end

    self.callback = callback
    self:SetPlayerCurrencyAsMaxOrMaxCurrency(playerCurrencyAsMaxOrMaxCurrency)
    self:SetCurrencyAmount(initialCurrencyAmount or self:GetTotalCurrency(), "update")
    self.pulseTimeline:PlayFromStart()

    if not self.isHoldingDisabledReference then
        self.isHoldingDisabledReference = true
        ZO_KeybindButtonTemplate_AddGlobalDisableReference()
    end
end

function ZO_CurrencyInputObject:SetPlayerCurrencyAsMaxOrMaxCurrency(playerCurrencyAsMaxOrMaxCurrency)
    if(type(playerCurrencyAsMaxOrMaxCurrency) == "number") then
        self:SetMaxCurrency(playerCurrencyAsMaxOrMaxCurrency)
    else
        self:SetUsePlayerCurrencyAsMax(playerCurrencyAsMaxOrMaxCurrency)
    end
end


function ZO_CurrencyInputObject:SetContext(context)
    self.context = context
end

function ZO_CurrencyInputObject:GetContext()
    return self.context
end

function ZO_CurrencyInputObject:IsHidden()
    return self.control:IsHidden()
end

function ZO_CurrencyInputObject:Hide()
    self.callback = nil
    self.control:SetHidden(true)
    self.control:UnregisterForEvent(EVENT_GLOBAL_MOUSE_DOWN)
    self:SetMaxCurrency(nil)
    self:SetContext(nil)
    self:Reset() -- make sure callback is cleared before this, otherwise it gets called with an "update" event.    
    self.mouseRefCount = 0
    self.pulseTimeline:Stop()

    if self.isHoldingDisabledReference then
        self.isHoldingDisabledReference = false
        ZO_KeybindButtonTemplate_RemoveGlobalDisableReference()
    end
end

function ZO_CurrencyInputObject:Confirm()
    self:DoCallback("confirm")
    self:Hide()
end

function ZO_CurrencyInputObject:Cancel()
    self:DoCallback("cancel")
    self:Hide()
end

function ZO_CurrencyInputObject:DecrementRefCount()
    self.mouseRefCount = self.mouseRefCount - 1
    if(self.mouseRefCount <= 0) then
        self:Confirm()
    end
end


--Default Currency Input Field

local function ClampSetCurrency(self, currencyAmount)
    local max = currencyAmount
    local min = self.currencyMin or 0

    if(self.currencyMax) then
        max = self.currencyMax
    elseif(self.usePlayerCurrencyAsMax) then
        max = GetCurrencyAmount(self.currencyType, CURRENCY_LOCATION_CHARACTER)
    end

    return zo_clamp(currencyAmount, min, max)
end

function ZO_DefaultCurrencyInputField_Initialize(self, onCurrencyChanged, currencyType)
    self.currencyControl = GetControl(self, "Amount")
    self.usePlayerCurrencyAsMax = false
    self.currentCurrencyAmount = 0

    --before updating currencyType unregister any potential currency update events
    currencyType = currencyType or CURT_MONEY -- gross check because currencyType defaults to money for backwards compat
    if self.currencyType and self.currencyType ~= currencyType then
        if(self.onCurrencyUpdate) then
            self:UnregisterForEvent(EVENT_CURRENCY_UPDATE)
        end
    end
    
    ZO_DefaultCurrencyInputField_SetCurrencyType(self, currencyType)

    self.OnCurrencyChanged = function(currencyInput, currencyAmount, eventType)
        currencyAmount = ClampSetCurrency(self, currencyAmount)
        if(eventType == "confirm") then
            if onCurrencyChanged then
                onCurrencyChanged(currencyInput, currencyAmount)
            end
            self.currentCurrencyAmount = currencyAmount
            self.currencyControl:SetHidden(false)
        elseif(eventType == "cancel") then
            self.currencyControl:SetHidden(false)
        end
        ZO_CurrencyControl_SetSimpleCurrency(self.currencyControl, self.currencyType, currencyAmount)
    end

    self:SetHandler("OnEffectivelyHidden", function(control)
        CURRENCY_INPUT:Hide()
    end)

    self.OnBeginInput = function()
        self.currencyControl:SetHidden(true)
        CURRENCY_INPUT:Show(self.OnCurrencyChanged, self.currencyMax or self.usePlayerCurrencyAsMax, self.currentCurrencyAmount or 0, self.currencyType, self, 20)
    end
end

local function RefreshCurrencyForPlayerLimit(self)
    local playerCurrency = GetCurrencyAmount(self.currencyType, CURRENCY_LOCATION_CHARACTER)
    if(self.currentCurrencyAmount > playerCurrency) then
        ZO_DefaultCurrencyInputField_SetCurrencyAmount(self, playerCurrency)
    end
end

function ZO_DefaultCurrencyInputField_SetUsePlayerCurrencyAsMax(self, usePlayerCurrencyAsMax)
    if(self.usePlayerCurrencyAsMax ~= usePlayerCurrencyAsMax) then
        self.usePlayerCurrencyAsMax = usePlayerCurrencyAsMax
        if(self.usePlayerCurrencyAsMax) then
            self.currencyMax = nil
            RefreshCurrencyForPlayerLimit(self)
            if(self.onCurrencyUpdate == nil) then
                self.onCurrencyUpdate = function() RefreshCurrencyForPlayerLimit(self) end
            end
            self:RegisterForEvent(EVENT_CURRENCY_UPDATE, function(eventId, currencyType) if currencyType == self.currencyType then self.onCurrencyUpdate() end end) 
        else
            if(self.onCurrencyUpdate) then
                self:UnregisterForEvent(EVENT_CURRENCY_UPDATE)
            end
        end
    end
end

function ZO_DefaultCurrencyInputField_SetCurrencyMax(self, currencyMax)
    ZO_DefaultCurrencyInputField_SetUsePlayerCurrencyAsMax(self, false)
    self.currencyMax = currencyMax
    ZO_DefaultCurrencyInputField_SetCurrencyAmount(self, self.currentCurrencyAmount)
    if not CURRENCY_INPUT:IsHidden() then
        CURRENCY_INPUT:SetPlayerCurrencyAsMaxOrMaxCurrency(self.currencyMax)
    end
end

function ZO_DefaultCurrencyInputField_SetCurrencyMin(self, currencyMin)
    self.currencyMin = currencyMin
    ZO_DefaultCurrencyInputField_SetCurrencyAmount(self, self.currentCurrencyAmount)
end

function ZO_DefaultCurrencyInputField_SetCurrencyAmount(self, currencyAmount)
    currencyAmount = ClampSetCurrency(self, currencyAmount)

    if currencyAmount ~= self.currentCurrencyAmount then
        self.OnCurrencyChanged(nil, currencyAmount, "confirm")
    end
end

function ZO_DefaultCurrencyInputField_SetCurrencyType(self, currencyType)
    self.currencyType = currencyType or CURT_MONEY
    ZO_CurrencyControl_SetSimpleCurrency(self.currencyControl, self.currencyType, 0)
end

function ZO_DefaultCurrencyInputField_GetCurrency(self)
    return self.currentCurrencyAmount
end
