TELVAR_METER_WIDTH = 256
TELVAR_METER_HEIGHT = 128
TELVAR_METER_KEYBOARD_BAR_OFFSET_X = 14
TELVAR_METER_KEYBOARD_BAR_OFFSET_Y = 18
TELVAR_METER_GAMEPAD_BAR_OFFSET_X = -9
TELVAR_METER_GAMEPAD_BAR_OFFSET_Y = 15

local ZO_HUDTelvarMeter = ZO_Object:Subclass()

function ZO_HUDTelvarMeter:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_HUDTelvarMeter:Initialize(control)
    -- Initialize state
    self.hiddenReasons = ZO_HiddenReasons:New()
    self.telvarStoneThreshold = GetTelvarStoneMultiplierThresholdIndex()
    
    -- Set up controls
    self.alertBorder = ZO_HUDTelvarAlertBorder
    self.telvarDisplayControl = control:GetNamedChild("TelvarDisplay")
    self.meterTelvarMultiplierControl = control:GetNamedChild("Multiplier")
    self.meterFrameControl = control:GetNamedChild("Frame")
    self.meterBarControl = control:GetNamedChild("Bar")
    self.meterOverlayControl = control:GetNamedChild("Overlay")
    self.meterBarFill = self.meterBarControl:GetNamedChild("Fill")
    self.meterBarHighlight = self.meterBarControl:GetNamedChild("Highlight")
    self.multiplierContainer = control:GetNamedChild("MultiplierContainer")
    self.multiplierLabel = self.multiplierContainer:GetNamedChild("MultiplierLabel")
    self.multiplierWholePart = self.multiplierContainer:GetNamedChild("WholePart")
    self.multiplierFractionalPart = self.multiplierContainer:GetNamedChild("FractionalPart")
    self.control = control

    -- Set up platform styles
    self.keyboardStyle = 
    { 
        template = "ZO_HUDTelvarMeter_KeyboardTemplate" ,
        currencyOptions = 
        {
            showTooltips = true,
            customTooltip = SI_CURRENCYTYPE3,
            isGamepad = false,
            font = "ZoFontGameLargeBold",
            iconSide = RIGHT,
        },
    }
    self.gamepadStyle = 
    { 
        template = "ZO_HUDTelvarMeter_GamepadTemplate",
        currencyOptions = 
        {
            showTooltips = false,
            isGamepad = true,
            font = "ZoFontGamepadHeaderDataValue",
            iconSide = RIGHT,
        },
    }
    ZO_PlatformStyle:New(function(...) self:UpdatePlatformStyle(...) end, self.keyboardStyle, self.gamepadStyle)

    -- Initialize alert border animation
    self.alertBorder.pulseAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_HUDTelvarAlertBorderAnimation", self.alertBorder)

    -- Initialize overlay animation
    self.meterOverlayControl.fadeAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_HUDTelvarMeterOverlayFade", self.meterOverlayControl)

    -- Initialize label animation
    self.multiplierContainer.bounceAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_HUDTelvarMeterMultiplierBounce", self.multiplierContainer)

    -- Initialize bar states and animations
    self.meterBarControl.easeAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_HUDTelvarMeterEasing")
    self.meterBarControl.startPercent = self:CalculateMeterFillPercentage()
    self.meterBarControl.endPercent = self.meterBarControl.startPercent

    -- Initialize edge animation

    -- Register for events
    control:RegisterForEvent(EVENT_TELVAR_STONE_UPDATE, function(...) self:OnTelvarStonesUpdated(...) end)

    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function()
        if DoesCurrentZoneHaveTelvarStoneBehavior() then
            TriggerTutorial(TUTORIAL_TRIGGER_TELVAR_ZONE_ENTERED)
            self:SetHiddenForReason("disabledInZone", false)
        else
            self:SetHiddenForReason("disabledInZone", true)
        end
    end)

    -- Do our initial update
    self:SetBarValue(self.meterBarControl.startPercent)
    self:OnTelvarStonesUpdated()
end

function ZO_HUDTelvarMeter:SetHiddenForReason(reason, hidden)
    self.hiddenReasons:SetHiddenForReason(reason, hidden)
    self.control:SetHidden(self.hiddenReasons:IsHidden())
end

function ZO_HUDTelvarMeter:OnTelvarStonesUpdated(event, newTelvarStones, oldTelvarStones, reason)
    if reason == CURRENCY_CHANGE_REASON_LOOT or reason == CURRENCY_CHANGE_REASON_PVP_KILL_TRANSFER and newTelvarStones > oldTelvarStones then
        PlaySound(SOUNDS.TELVAR_GAINED)
    end

    if(DoesCurrentZoneHaveTelvarStoneBehavior()) then
        ZO_CurrencyControl_SetSimpleCurrency(self.telvarDisplayControl, CURT_TELVAR_STONES, GetCurrencyAmount(CURT_TELVAR_STONES, CURRENCY_LOCATION_CHARACTER), IsInGamepadPreferredMode() and self.gamepadStyle.currencyOptions or self.keyboardStyle.currencyOptions, CURRENCY_SHOW_ALL) 

        self:UpdateMeterBar()
        self:UpdateMultiplier()
    end
end

function ZO_HUDTelvarMeter:UpdateMeterBar()
    if IsMaxTelvarStoneMultiplierThreshold(self.telvarStoneThreshold) then
        self.meterBarControl:SetHidden(true)
        self.meterBarHighlight:SetHidden(true)
        self.meterOverlayControl:SetAlpha(1)
        self.multiplierLabel:SetColor(ZO_BLACK:UnpackRGBA())
        self.multiplierWholePart:SetColor(ZO_BLACK:UnpackRGBA())
        self.multiplierFractionalPart:SetColor(ZO_BLACK:UnpackRGBA())
    else
        self.meterBarControl:SetHidden(false)
        self.meterBarHighlight:SetHidden(false)
        self.meterOverlayControl:SetAlpha(0)
        self.multiplierLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        self.multiplierWholePart:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        self.multiplierFractionalPart:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
    end

    local percentageToNextThreshold = self:CalculateMeterFillPercentage()

    -- Update bar values
    self.meterBarControl.startPercent = self.meterBarControl.endPercent
    self.meterBarControl.endPercent = zo_min(percentageToNextThreshold, 1.0)

    -- Start the bar animation
    self.meterBarControl.easeAnimation:PlayFromStart() 
end

function ZO_HUDTelvarMeter:UpdateMultiplier()
    local multiplier = GetTelvarStoneMultiplier(self.telvarStoneThreshold)
    local wholePart = zo_floor(multiplier)
    local fractionalPart = zo_round(zo_mod(multiplier, 1.0)*100) -- This strips the fractional part away and formats it as a two-digit whole number. The decimal place is added in the string formatting.
    self.multiplierWholePart:SetText(zo_strformat(SI_TELVAR_HUD_MULTIPLIER_VALUE_WHOLE, wholePart))
    self.multiplierFractionalPart:SetText(zo_strformat(SI_TELVAR_HUD_MULTIPLIER_VALUE_FRACTION, string.format("%02d", fractionalPart)))
end

function ZO_HUDTelvarMeter:AnimateMeter(progress)
    local fillPercentage = zo_min((progress * (self.meterBarControl.endPercent - self.meterBarControl.startPercent)) + self.meterBarControl.startPercent, 1)
    self:SetBarValue(fillPercentage)
end

function ZO_HUDTelvarMeter:SetBarValue(percentFilled)
    self.meterBarFill:StartFixedCooldown(percentFilled, CD_TYPE_RADIAL, CD_TIME_TYPE_TIME_REMAINING, NO_LEADING_EDGE) -- CD_TIME_TYPE_TIME_REMAINING causes clockwise scroll
    self.meterBarHighlight:StartFixedCooldown(percentFilled, CD_TYPE_RADIAL, CD_TIME_TYPE_TIME_REMAINING, NO_LEADING_EDGE)
end

function ZO_HUDTelvarMeter:UpdatePlatformStyle(styleTable)
    ApplyTemplateToControl(self.control, styleTable.template)
    ZO_CurrencyControl_SetSimpleCurrency(self.telvarDisplayControl, CURT_TELVAR_STONES, GetCurrencyAmount(CURT_TELVAR_STONES, CURRENCY_LOCATION_CHARACTER), styleTable.currencyOptions, CURRENCY_SHOW_ALL) 

    local isMaxThreshold = IsMaxTelvarStoneMultiplierThreshold(self.telvarStoneThreshold)
    self.meterBarControl:SetHidden(isMaxThreshold)
    self.meterOverlayControl:SetAlpha(isMaxThreshold and 1 or 0)
end

function ZO_HUDTelvarMeter:OnMeterAnimationComplete()
    -- Determine whether or not we need to animate again
    local newThresholdIndex = GetTelvarStoneMultiplierThresholdIndex()

    if self.telvarStoneThreshold and newThresholdIndex and self.telvarStoneThreshold ~= newThresholdIndex then
        TriggerTutorial(TUTORIAL_TRIGGER_TELVAR_THRESHOLD_CROSSED)
        if self.telvarStoneThreshold < newThresholdIndex then
            -- We've crossed to a higher multiplier threshold.   
            self.telvarStoneThreshold = self.telvarStoneThreshold + 1
            self.alertBorder.pulseAnimation:PlayFromStart()

            if IsMaxTelvarStoneMultiplierThreshold(self.telvarStoneThreshold) then
                self.meterBarControl.endPercent = 1 
                PlaySound(SOUNDS.TELVAR_MULTIPLIERMAX)
            else
                self.meterBarControl.endPercent = 0
                PlaySound(SOUNDS.TELVAR_MULTIPLIERUP)
                self.meterOverlayControl.fadeAnimation:PlayFromStart()
            end
        elseif self.telvarStoneThreshold > newThresholdIndex then
            -- We've crossed to a lower multiplier threshold.
            self.telvarStoneThreshold = self.telvarStoneThreshold - 1
            self.meterBarControl.endPercent = 1
        end

        -- Animate the meter
        self.multiplierContainer.bounceAnimation:PlayFromStart()
        self:UpdateMeterBar()
        self:UpdateMultiplier()
    end
end

function ZO_HUDTelvarMeter:CalculateMeterFillPercentage()
    if IsMaxTelvarStoneMultiplierThreshold(self.telvarStoneThreshold) then
        return 1
    elseif self.telvarStoneThreshold then -- Protect against self.telvarStoneThreshold being nil.
        local currentThresholdAmount = GetTelvarStoneThresholdAmount(self.telvarStoneThreshold)
        local nextThresholdAmount = GetTelvarStoneThresholdAmount(self.telvarStoneThreshold + 1)
        local result = (GetCurrencyAmount(CURT_TELVAR_STONES, CURRENCY_LOCATION_CHARACTER) - currentThresholdAmount) / (nextThresholdAmount - currentThresholdAmount)
        return zo_max(result, 0)    
    else
        return 0
    end
end


function ZO_HUDTelvarMeter_Initialize(control)
    HUD_TELVAR_METER = ZO_HUDTelvarMeter:New(control)
end

function ZO_HUDTelvarMeter_UpdateMeterToAnimationProgress(progress)
    if HUD_TELVAR_METER then
        HUD_TELVAR_METER:AnimateMeter(progress)
    end
end

function ZO_HUDTelvarMeter_OnMeterAnimationComplete(animation)
    HUD_TELVAR_METER:OnMeterAnimationComplete()
end