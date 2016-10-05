INFAMY_METER_WIDTH = 256
INFAMY_METER_HEIGHT = 128
INFAMY_METER_KEYBOARD_BAR_OFFSET_X = 14
INFAMY_METER_KEYBOARD_BAR_OFFSET_Y = 15
INFAMY_METER_GAMEPAD_BAR_OFFSET = 10

local INFAMY_METER_UPDATE_DELAY_SECONDS = 1

 -- Forces the bar to be at least 3% full, in order to make it visible even at one or two bounty
local MIN_BAR_PERCENTAGE = 0.03

local UPDATE_TYPE_TICK = 0
local UPDATE_TYPE_EVENT = 1

local INFAMY_METER_SLOW_FADE_TIME = 1400 -- in milliseconds
local INFAMY_METER_SLOW_FADE_DELAY = 600 -- in milliseconds
local INFAMY_METER_FADE_TIME = 200 -- in milliseconds

local CENTER_ICON_STATE_DAGGER_GREY = 1
local CENTER_ICON_STATE_DAGGER_RED = 2
local CENTER_ICON_STATE_EYE = 3

local GREY_DAGGER_ICON = "EsoUI/Art/HUD/infamy_dagger-grey.dds" 
local RED_DAGGER_ICON = "EsoUI/Art/HUD/infamy_dagger-red.dds" 
local DAGGER_ICON_CUTOUT = "EsoUI/Art/HUD/infamy_dagger-cutout.dds" 
local RED_EYE_ICON = "EsoUI/Art/HUD/trespassing_eye-red.dds" 
local EYE_ICON_CUTOUT = "EsoUI/Art/HUD/trespassing_eye-cutout.dds" 

local ZO_HUDInfamyMeter = ZO_Object:Subclass()

function ZO_HUDInfamyMeter:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_HUDInfamyMeter:UpdateInfamyMeterState(infamy, bounty, isKOS, isTrespassing)
    self.infamyMeterState["infamy"] = infamy or GetInfamy()
    self.infamyMeterState["bounty"] = bounty or GetBounty()

    if isKOS ~= nil then
        self.infamyMeterState["isKOS"] = isKOS
    else
        self.infamyMeterState["isKOS"] = IsKillOnSight()
    end

    if isTrespassing ~= nil then
        self.infamyMeterState["isTrespassing"] = isTrespassing
    else
        self.infamyMeterState["isTrespassing"] = IsTrespassing()
    end
end

function ZO_HUDInfamyMeter:GetOldInfamyMeterState() 
    return self.infamyMeterState["infamy"], self.infamyMeterState["bounty"], self.infamyMeterState["isKOS"], self.infamyMeterState["isTrespassing"]
end

function ZO_HUDInfamyMeter:Initialize(control) 
    -- Initialize state
    self.nextUpdateTime = 0
    self.hiddenExternalRequest = false
    self.meterTotal = GetInfamyMeterSize()

    self.infamyMeterState = {}
    self:UpdateInfamyMeterState(0, 0, false, false)

    self.isInGamepadMode = IsInGamepadPreferredMode()

    self.currencyOptions = 
    {
        showTooltips = true,
        customTooltip = SI_STATS_BOUNTY_LABEL,
        font = self.isInGamepadMode and "ZoFontGamepadHeaderDataValue" or "ZoFontGameLargeBold",
        overrideTexture = self.isInGamepadMode and "EsoUI/Art/currency/gamepad/gp_gold.dds" or nil,
        iconSide = RIGHT,
        isGamepad = self.isInGamepadMode
    }   

    -- Set up controls
    ApplyTemplateToControl(control, self.isInGamepadMode and "ZO_HUDInfamyMeter_GamepadTemplate" or "ZO_HUDInfamyMeter_KeyboardTemplate")
    self.control = control
    self.meterFrame = control:GetNamedChild("Frame")
    self.infamyBar = control:GetNamedChild("InfamyBar")
    self.bountyBar = control:GetNamedChild("BountyBar")
    self.centerIconAnimatingTexture = control:GetNamedChild("CenterIconAnimatingTexture")
    self.centerIconPersistentTexture = control:GetNamedChild("CenterIconPersistentTexture")
    self.bountyLabel = control:GetNamedChild("BountyDisplay")

    -- Set up fade in/out animations
    self.fadeAnim = ZO_AlphaAnimation:New(control)
    self.fadeAnim:SetMinMaxAlpha(0.0, 1.0)

    -- Initialize bar states and animations
    self.infamyBar.easeAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_HUDInfamyMeterEasing")
    self.infamyBar.startPercent = 0
    self.infamyBar.endPercent = self.infamyMeterState["infamy"] / self.meterTotal

    self.bountyBar.easeAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_HUDInfamyMeterEasing")
    self.bountyBar.startPercent = 0
    self.bountyBar.endPercent = self.infamyMeterState["bounty"] / self.meterTotal

    -- Initialize Center Icon and its animations
    self.centerIconCutoutInAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_HUDInfamyMeterCenterIconCutoutIn")
    self.centerIconCutoutInAnimation:GetAnimation(1):SetAnimatedControl(self.centerIconAnimatingTexture)
    self.centerIconCutoutInAnimation:GetAnimation(2):SetAnimatedControl(self.centerIconAnimatingTexture)
    self.centerIconCutoutInAnimation:GetAnimation(3):SetAnimatedControl(self.centerIconAnimatingTexture)
    self.centerIconCutoutInAnimation:GetAnimation(4):SetAnimatedControl(self.centerIconPersistentTexture)

    self.centerIconScaleOutAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_HUDInfamyMeterCenterIconScaleOut")
    self.centerIconScaleOutAnimation:GetAnimation(1):SetAnimatedControl(self.centerIconAnimatingTexture)
    self.centerIconScaleOutAnimation:GetAnimation(2):SetAnimatedControl(self.centerIconAnimatingTexture)
    self.centerIconScaleOutAnimation:GetAnimation(3):SetAnimatedControl(self.centerIconPersistentTexture)

    -- Register for events
    control:RegisterForEvent(EVENT_JUSTICE_INFAMY_UPDATED, function()
        if self:ShouldProcessUpdateEvent() then
            self:OnInfamyUpdated(UPDATE_TYPE_EVENT) 
        end
    end)

    control:RegisterForEvent(EVENT_LEVEL_UPDATE, function()
        if self:ShouldProcessUpdateEvent() then
            self:OnInfamyUpdated(UPDATE_TYPE_EVENT) 
        end
    end)

    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function() 
        local infamy = GetInfamy()
        if IsInJusticeEnabledZone() then
            if self:ShouldProcessUpdateEvent() then
                self:OnInfamyUpdated(UPDATE_TYPE_EVENT) 
            end
        else
            self.control:SetHidden(true)
        end
    end)
end

function ZO_HUDInfamyMeter:ShouldProcessUpdateEvent()
    local infamy = GetInfamy()
    local isKOS = IsKillOnSight()
    local isTrespassing = IsTrespassing()
    return IsInJusticeEnabledZone() 
           and not self.hiddenExternalRequest 
           and ((infamy ~= 0 and infamy ~= self.infamyMeterState["infamy"]) or isTrespassing ~= self.infamyMeterState["isTrespassing"])
end

function ZO_HUDInfamyMeter:Update(time)
    if self.nextUpdateTime <= time and not self.hiddenExternalRequest and IsInJusticeEnabledZone() then
        self.nextUpdateTime = time + INFAMY_METER_UPDATE_DELAY_SECONDS
        self:OnInfamyUpdated(UPDATE_TYPE_TICK)
    end
end

function ZO_HUDInfamyMeter:OnInfamyUpdated(updateType)
    local oldInfamy, oldBounty, wasKOS, wasTrespassing = self:GetOldInfamyMeterState()
    self:UpdateInfamyMeterState()

    local gamepadModeSwitchUpdate = IsInGamepadPreferredMode() ~= self.isInGamepadMode

    if oldInfamy ~= self.infamyMeterState["infamy"] or updateType == UPDATE_TYPE_EVENT or gamepadModeSwitchUpdate then
        -- Update frame and bars if we're switching between PC and console mode
        if IsInGamepadPreferredMode() and not self.isInGamepadMode then
            self.currencyOptions.font = "ZoFontGamepadHeaderDataValue"
            self.currencyOptions.isGamepad = true
            ApplyTemplateToControl(self.control, "ZO_HUDInfamyMeter_GamepadTemplate")
            self.isInGamepadMode = true
        elseif not IsInGamepadPreferredMode() and self.isInGamepadMode then
            self.currencyOptions.font = "ZoFontGameLargeBold"
            self.currencyOptions.isGamepad = false
            self.currencyOptions.iconSize = nil
            ApplyTemplateToControl(self.control, "ZO_HUDInfamyMeter_KeyboardTemplate")
            self.isInGamepadMode = false
        end

        -- Hide or show meter
        if self.infamyMeterState["infamy"] == 0 then
            self.fadeAnim:FadeOut(INFAMY_METER_SLOW_FADE_DELAY, INFAMY_METER_SLOW_FADE_TIME, ZO_ALPHA_ANIMATION_OPTION_FORCE_ALPHA, function() self.control:SetHidden(true) end)
        else
            self.control:SetHidden(false)
            self.fadeAnim:FadeIn(0, INFAMY_METER_FADE_TIME, ZO_ALPHA_ANIMATION_OPTION_USE_CURRENT_ALPHA)
        end

        -- Update bars
        self:UpdateBar(self.infamyBar, self.infamyMeterState["infamy"], updateType)
        self:UpdateBar(self.bountyBar, self.infamyMeterState["bounty"], updateType)

        -- Update trespassing/KOS icon
        self:AnimateCenterIcon(wasKOS, wasTrespassing)

        -- Update label
        ZO_CurrencyControl_SetSimpleCurrency(self.bountyLabel, CURT_MONEY, GetFullBountyPayoffAmount(), self.currencyOptions, CURRENCY_SHOW_ALL, true) 

        -- Fire center-screen announcement if we updated below a threshold
        local infamyLevel = GetInfamyLevel(self.infamyMeterState["infamy"])
        local oldInfamyLevel = GetInfamyLevel(oldInfamy)

        -- Fire CSA
        if self.infamyMeterState.isTrespassing ~= wasTrespassing then
            local sound, primaryMessage, secondaryMessage
            if wasTrespassing then
                sound = SOUNDS.JUSTICE_NO_LONGER_KOS
                primaryMessage = zo_strformat(SI_JUSTICE_NO_LONGER_TRESPASSING_PRIMARY)
                secondaryMessage = zo_strformat(SI_JUSTICE_NO_LONGER_TRESPASSING_SECONDARY)

                if self.infamyMeterState.bounty > 0 then
                    TriggerTutorial(TUTORIAL_TRIGGER_TRESPASS_SUBZONE_EXITED_WITH_BOUNTY)
                end
            else
            	TriggerTutorial(TUTORIAL_TRIGGER_TRESPASS_SUBZONE_ENTERED)
                sound = SOUNDS.JUSTICE_NOW_KOS
                primaryMessage = zo_strformat(SI_JUSTICE_NOW_TRESPASSING_PRIMARY)
                secondaryMessage = zo_strformat(SI_JUSTICE_NOW_TRESPASSING_SECONDARY)
            end

            CENTER_SCREEN_ANNOUNCE:AddMessage(EVENT_JUSTICE_INFAMY_UPDATED, CSA_EVENT_COMBINED_TEXT, sound, primaryMessage, secondaryMessage)

        elseif infamyLevel ~= oldInfamyLevel then 
            local sound, primaryMessage, secondaryMessage, icon
            if oldInfamyLevel == INFAMY_THRESHOLD_FUGITIVE then
                sound = SOUNDS.JUSTICE_NO_LONGER_KOS
                primaryMessage = zo_strformat(SI_JUSTICE_INFAMY_LEVEL_CHANGED, GetString("SI_INFAMYTHRESHOLDSTYPE", infamyLevel))
                secondaryMessage = zo_strformat(SI_JUSTICE_NO_LONGER_KOS)
                icon = "EsoUI/Art/Stats/infamy_KOS_icon-Notification.dds"
            elseif infamyLevel == INFAMY_THRESHOLD_FUGITIVE then
                TriggerTutorial(TUTORIAL_TRIGGER_FUGITIVE_REACHED)
                sound = SOUNDS.JUSTICE_NOW_KOS
                primaryMessage = zo_strformat(SI_JUSTICE_NOW_FUGITIVE)
                secondaryMessage = zo_strformat(SI_JUSTICE_NOW_KOS)
                icon = "EsoUI/Art/Stats/infamy_KOS_icon-Notification.dds"
            else
                if infamyLevel == INFAMY_THRESHOLD_DISREPUTABLE then
                    TriggerTutorial(TUTORIAL_TRIGGER_DISREPUTABLE_REACHED)
                elseif infamyLevel == INFAMY_THRESHOLD_NOTORIOUS then
                    TriggerTutorial(TUTORIAL_TRIGGER_NOTORIOUS_REACHED)
                end

                primaryMessage = zo_strformat(SI_JUSTICE_INFAMY_LEVEL_CHANGED, GetString("SI_INFAMYTHRESHOLDSTYPE", infamyLevel))
                sound = SOUNDS.JUSTICE_STATE_CHANGED
            end

            CENTER_SCREEN_ANNOUNCE:AddMessage(
                EVENT_JUSTICE_INFAMY_UPDATED, 
                CSA_EVENT_COMBINED_TEXT, 
                sound, 
                primaryMessage, 
                secondaryMessage,
                icon,
                nil, nil, nil, nil, -- Use defaults for these
                CSA_OPTION_SUPPRESS_ICON_FRAME
            )
        end
    end
end

function ZO_HUDInfamyMeter:AnimateCenterIcon(wasKOS, wasTrespassing)
    if self.infamyMeterState["isTrespassing"] then
        if not wasTrespassing then
            self.centerIconAnimatingTexture:SetTexture(EYE_ICON_CUTOUT)
            self.centerIconPersistentTexture:SetTexture(RED_EYE_ICON)
            self.centerIconPersistentTexture:SetAlpha(0)
            self.centerIconCutoutInAnimation:PlayFromStart()
        end
    elseif self.infamyMeterState["isKOS"] then
        if wasTrespassing then
            self.centerIconAnimatingTexture:SetTexture(RED_EYE_ICON)
            self.centerIconPersistentTexture:SetTexture(RED_DAGGER_ICON)
            self.centerIconScaleOutAnimation:PlayFromStart()
        elseif not wasKOS then
            self.centerIconAnimatingTexture:SetTexture(DAGGER_ICON_CUTOUT)
            self.centerIconPersistentTexture:SetTexture(RED_DAGGER_ICON)
            self.centerIconPersistentTexture:SetAlpha(0)
            self.centerIconCutoutInAnimation:PlayFromStart()
        end
    else
        if wasTrespassing or wasKOS then
            self.centerIconAnimatingTexture:SetTexture(self.centerIconPersistentTexture:GetTextureFileName())
            self.centerIconPersistentTexture:SetTexture(GREY_DAGGER_ICON)
            self.centerIconScaleOutAnimation:PlayFromStart()
        end
    end
end

function ZO_HUDInfamyMeter:UpdateBar(bar, newValue, updateType)
    if not bar.easeAnimation:IsPlaying() or updateType == UPDATE_TYPE_EVENT then 
        -- Update Values
        bar.startPercent = bar.endPercent
        bar.endPercent = newValue / self.meterTotal

        -- Manually set bar to its start percentage
        -- (we do this in case the bar has become out-of-date since it was last animated, for example by being hidden or paused)
        self:SetBarValue(bar, bar.startPercent)

        -- Start the animation
        bar.easeAnimation:PlayFromStart() 
    end
end

function ZO_HUDInfamyMeter:AnimateMeter(progress)
    local infamyFillPercentage = zo_min((progress * (self.infamyBar.endPercent - self.infamyBar.startPercent)) + self.infamyBar.startPercent, 1)
    local bountyFillPercentage = zo_min((progress * (self.bountyBar.endPercent - self.bountyBar.startPercent)) + self.bountyBar.startPercent, 1)
    local infamyMinPercentage = self.infamyMeterState["infamy"] ~= 0 and MIN_BAR_PERCENTAGE or 0
    local bountyMinPercentage = self.infamyMeterState["bounty"] ~= 0 and MIN_BAR_PERCENTAGE or 0
    self:SetBarValue(self.infamyBar, zo_max(infamyFillPercentage, infamyMinPercentage))
    self:SetBarValue(self.bountyBar, zo_max(bountyFillPercentage, bountyMinPercentage))
end

function ZO_HUDInfamyMeter:SetBarValue(bar, percentFilled)
    bar:StartFixedCooldown(percentFilled, CD_TYPE_RADIAL, CD_TIME_TYPE_TIME_REMAINING, NO_LEADING_EDGE) -- CD_TIME_TYPE_TIME_REMAINING causes clockwise scroll
end

function ZO_HUDInfamyMeter:RequestHidden(hidden)    
    if hidden ~= self.hiddenExternalRequest then
        if hidden then
            self.fadeAnim:FadeOut(0, INFAMY_METER_FADE_TIME, ZO_ALPHA_ANIMATION_OPTION_USE_CURRENT_ALPHA, function() self.control:SetHidden(true) end)
        elseif IsInJusticeEnabledZone() and (GetInfamy() ~= 0 or self.infamyMeterState["infamy"] ~= 0) then
            self.control:SetHidden(false)
            self.fadeAnim:FadeIn(0, INFAMY_METER_FADE_TIME, ZO_ALPHA_ANIMATION_OPTION_USE_CURRENT_ALPHA)
        end
    end

    self.hiddenExternalRequest = hidden
end

function ZO_HUDInfamyMeter_Initialize(control)
    HUD_INFAMY_METER = ZO_HUDInfamyMeter:New(control)
end

function ZO_HUDInfamyMeter_Update(time)
    HUD_INFAMY_METER:Update(time)
end

function ZO_HUDInfamyMeter_AnimateMeter(progress)
    if HUD_INFAMY_METER then 
        HUD_INFAMY_METER:AnimateMeter(progress)
    end
end