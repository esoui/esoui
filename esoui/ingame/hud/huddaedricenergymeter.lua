-- Asset Dimensions
ZO_HUD_KEYBOARD_DAEDRIC_ENERGY_METER_FRAME_WIDTH = 256
ZO_HUD_KEYBOARD_DAEDRIC_ENERGY_METER_FRAME_HEIGHT = 128

ZO_HUD_GAMEPAD_DAEDRIC_ENERGY_METER_FRAME_WIDTH = 256 
ZO_HUD_GAMEPAD_DAEDRIC_ENERGY_METER_FRAME_HEIGHT = 128

ZO_HUD_KEYBOARD_DAEDRIC_ENERGY_METER_BAR_WIDTH = 124
ZO_HUD_KEYBOARD_DAEDRIC_ENERGY_METER_BAR_HEIGHT = 18
ZO_HUD_KEYBOARD_DAEDRIC_ENERGY_METER_BAR_RIGHT_COORD = ZO_HUD_KEYBOARD_DAEDRIC_ENERGY_METER_BAR_WIDTH / 128
ZO_HUD_KEYBOARD_DAEDRIC_ENERGY_METER_BAR_BOTTOM_COORD = ZO_HUD_KEYBOARD_DAEDRIC_ENERGY_METER_BAR_HEIGHT / 32

ZO_HUD_KEYBOARD_DAEDRIC_ENERGY_METER_BAR_EDGE_WIDTH = 8
ZO_HUD_KEYBOARD_DAEDRIC_ENERGY_METER_BAR_EDGE_RIGHT_COORD = ZO_HUD_KEYBOARD_DAEDRIC_ENERGY_METER_BAR_EDGE_WIDTH / 16
ZO_HUD_KEYBOARD_DAEDRIC_ENERGY_METER_BAR_EDGE_BOTTOM_COORD = ZO_HUD_KEYBOARD_DAEDRIC_ENERGY_METER_BAR_HEIGHT / 32

ZO_HUD_KEYBOARD_DAEDRIC_ENERGY_METER_BAR_FULL_WIDTH = ZO_HUD_KEYBOARD_DAEDRIC_ENERGY_METER_BAR_WIDTH + ZO_HUD_KEYBOARD_DAEDRIC_ENERGY_METER_BAR_EDGE_WIDTH

ZO_HUD_GAMEPAD_DAEDRIC_ENERGY_METER_BAR_WIDTH = 128
ZO_HUD_GAMEPAD_DAEDRIC_ENERGY_METER_BAR_HEIGHT = 20
ZO_HUD_GAMEPAD_DAEDRIC_ENERGY_METER_BAR_RIGHT_COORD = ZO_HUD_GAMEPAD_DAEDRIC_ENERGY_METER_BAR_WIDTH / 128
ZO_HUD_GAMEPAD_DAEDRIC_ENERGY_METER_BAR_BOTTOM_COORD = ZO_HUD_GAMEPAD_DAEDRIC_ENERGY_METER_BAR_HEIGHT / 32

ZO_HUD_GAMEPAD_DAEDRIC_ENERGY_METER_BAR_EDGE_WIDTH = 11
ZO_HUD_GAMEPAD_DAEDRIC_ENERGY_METER_BAR_EDGE_RIGHT_COORD = ZO_HUD_GAMEPAD_DAEDRIC_ENERGY_METER_BAR_EDGE_WIDTH / 16 
ZO_HUD_GAMEPAD_DAEDRIC_ENERGY_METER_BAR_EDGE_BOTTOM_COORD = ZO_HUD_GAMEPAD_DAEDRIC_ENERGY_METER_BAR_HEIGHT / 32

ZO_HUD_GAMEPAD_DAEDRIC_ENERGY_METER_BAR_FULL_WIDTH = ZO_HUD_GAMEPAD_DAEDRIC_ENERGY_METER_BAR_WIDTH + ZO_HUD_GAMEPAD_DAEDRIC_ENERGY_METER_BAR_EDGE_WIDTH

ZO_HUD_DAEDRIC_ENERGY_METER_LAYER_SIZE = 128

ZO_HUD_DAEDRIC_ENERGY_METER_HAMMER_SIZE = 128
ZO_HUD_DAEDRIC_ENERGY_METER_HAMMER_CELLS = 16
ZO_HUD_DAEDRIC_ENERGY_METER_HAMMER_RIGHT_COORD = (ZO_HUD_DAEDRIC_ENERGY_METER_HAMMER_SIZE * ZO_HUD_DAEDRIC_ENERGY_METER_HAMMER_CELLS) / 2048
-- End dimensions

local ENERGY_WARNING_THRESHOLD = .2

---------------------------
-- Base Weapon Animation --
---------------------------

local ZO_HUDDaedricEnergyMeter_BaseAnimation = ZO_Object:Subclass()

function ZO_HUDDaedricEnergyMeter_BaseAnimation:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_HUDDaedricEnergyMeter_BaseAnimation:Initialize(weaponControl)
    -- Override me
end

function ZO_HUDDaedricEnergyMeter_BaseAnimation:Show()
    -- Override me
end

function ZO_HUDDaedricEnergyMeter_BaseAnimation:Hide()
    -- Override me
end

function ZO_HUDDaedricEnergyMeter_BaseAnimation:PlayEnergyBurstAnimation()
    -- Override me
end

function ZO_HUDDaedricEnergyMeter_BaseAnimation:PlayUltimateUsedAnimation()
    -- Override me
end

function ZO_HUDDaedricEnergyMeter_BaseAnimation:OnEnergyValueChanged(currentEnergy, maxEnergy)
    -- Override me
end

---------------------------
-- No Weapon Animation --
---------------------------

local ZO_HUDDaedricEnergyMeter_NoAnimation = ZO_HUDDaedricEnergyMeter_BaseAnimation:Subclass()

function ZO_HUDDaedricEnergyMeter_NoAnimation:New(...)
    return ZO_HUDDaedricEnergyMeter_BaseAnimation.New(self, ...)
end

----------------
-- Volendrung --
----------------

local ZO_HUDDaedricEnergyMeter_VolendrungAnimation = ZO_HUDDaedricEnergyMeter_BaseAnimation:Subclass()

function ZO_HUDDaedricEnergyMeter_VolendrungAnimation:New(...)
    return ZO_HUDDaedricEnergyMeter_BaseAnimation.New(self, ...)
end

function ZO_HUDDaedricEnergyMeter_VolendrungAnimation:Initialize(weaponControl)
    self.control = weaponControl

    -- Idle
    self.hammerEmptyTexture = weaponControl:GetNamedChild("Empty")
    self.hammerIdleTexture = weaponControl:GetNamedChild("Idle")
    self.hammerIdleLoop = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_HUDDaedricEnergyMeter_HammerIdle", self.hammerIdleTexture)

    -- Burst
    self.hammerGlowRotateAnim = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_HUDDaedricEnergyMeter_RotateOnce", weaponControl:GetNamedChild("Glow"))
    self.hammerGlowFadeAnim = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_HUDDaedricEnergyMeter_Fade", weaponControl:GetNamedChild("Glow"))
    self.hammerBurstFadeAnim = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_HUDDaedricEnergyMeter_Fade", weaponControl:GetNamedChild("Burst1"))

    -- Ultimate used
    self.hammerUltimateFadeAnim = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_HUDDaedricEnergyMeter_Fade", weaponControl:GetNamedChild("Burst2"))
end

function ZO_HUDDaedricEnergyMeter_VolendrungAnimation:Show()
    self.control:SetHidden(false)
    self.hammerIdleLoop:PlayFromStart()
end

function ZO_HUDDaedricEnergyMeter_VolendrungAnimation:Hide()
    self.control:SetHidden(true)
    self.hammerIdleLoop:Stop()
end

function ZO_HUDDaedricEnergyMeter_VolendrungAnimation:PlayEnergyBurstAnimation()
    if not self.hammerBurstFadeAnim:IsPlaying() then
        self.hammerGlowRotateAnim:PlayFromStart()
        self.hammerGlowFadeAnim:PlayFromStart()
        self.hammerBurstFadeAnim:PlayFromStart()
    end
end

function ZO_HUDDaedricEnergyMeter_VolendrungAnimation:PlayUltimateUsedAnimation()
    if not self.hammerUltimateFadeAnim:IsPlaying() then
        self.hammerGlowRotateAnim:PlayFromStart()
        self.hammerGlowFadeAnim:PlayFromStart()
        self.hammerUltimateFadeAnim:PlayFromStart()
    end
end

function ZO_HUDDaedricEnergyMeter_VolendrungAnimation:OnEnergyValueChanged(currentEnergy, maxEnergy)
    if maxEnergy == 0 then
        return
    end
    local normalizedEnergy = currentEnergy / maxEnergy

    -- after hitting warning threshold, hide idle animation and show the empty texture underneath
    self.hammerEmptyTexture:SetHidden(normalizedEnergy > ENERGY_WARNING_THRESHOLD)
    local alpha = zo_clampedPercentBetween(0, ENERGY_WARNING_THRESHOLD, normalizedEnergy)
    self.hammerIdleTexture:SetAlpha(alpha)
end

--------------------------
-- Daedric Energy Meter --
--------------------------

local ZO_HUDDaedricEnergyMeter = ZO_CallbackObject:Subclass()

function ZO_HUDDaedricEnergyMeter:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_HUDDaedricEnergyMeter:Initialize(control)
    -- Initialize state
    self.hiddenReasons = ZO_HiddenReasons:New()
    
    -- Set up controls
    self.control = control
    self.barControl = control:GetNamedChild("Bar")

    self.barFadeAnim = ZO_AlphaAnimation:New(control)
    self.barFadeAnim:SetMinMaxAlpha(0, 1)

    self.warningLoop = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_HUDDaedricEnergyMeter_Warn", control:GetNamedChild("Overlay"))
    self.isWarningActive = false

    local arrow = self.control:GetNamedChild("ArrowRegeneration")
    arrow.burstAnim = ANIMATION_MANAGER:CreateTimelineFromVirtual("ArrowRegenerationAnimation", arrow)
    self.arrow = arrow

    -- Weapon animations
    internalassert(DAEDRIC_ARTIFACT_VISUAL_TYPE_MAX_VALUE == 1, "Make new weapon animation for visual type")
    self.animationsForArtifactVisualType =
    {
        [DAEDRIC_ARTIFACT_VISUAL_TYPE_NONE] = ZO_HUDDaedricEnergyMeter_NoAnimation:New(),
        [DAEDRIC_ARTIFACT_VISUAL_TYPE_VOLENDRUNG] = ZO_HUDDaedricEnergyMeter_VolendrungAnimation:New(control:GetNamedChild("WeaponVolendrung")),
    }
    self.activeWeapon = self.animationsForArtifactVisualType[DAEDRIC_ARTIFACT_VISUAL_TYPE_NONE] 

    -- Set up platform styles
    local ARROW_OFFSET_Y = 1
    local ARROW_END_X_PADDING = 3
    local ARROW_TEXTURE_WIDTH = 16
    self.keyboardStyle = 
    { 
        template = "ZO_HUDDaedricEnergyMeter_KeyboardTemplate",
        arrowTemplate = "ZO_ArrowRegeneration_Keyboard_Template",
        setupArrowCallback = function(barControl, arrow)
            -- animate from right to left
            local startOffsetX = barControl:GetWidth() - ARROW_TEXTURE_WIDTH
            arrow:ClearAnchors()

            arrow:SetAnchor(LEFT, barControl, LEFT, startOffsetX, ARROW_OFFSET_Y)
            arrow.burstAnim:GetFirstAnimation():SetTranslateDeltas(-startOffsetX - ARROW_END_X_PADDING, 0)
            arrow:SetTextureCoords(0, 1, 0, 1)
        end,
    }
    self.gamepadStyle = 
    { 
        template = "ZO_HUDDaedricEnergyMeter_GamepadTemplate",
        arrowTemplate = "ZO_ArrowRegeneration_Gamepad_Template",
        setupArrowCallback = function(barControl, arrow)
            -- animate from left to right
            local startOffsetX = barControl:GetWidth() - ARROW_TEXTURE_WIDTH
            arrow:ClearAnchors()

            arrow:SetAnchor(RIGHT, barControl, RIGHT, -startOffsetX, ARROW_OFFSET_Y)
            arrow.burstAnim:GetFirstAnimation():SetTranslateDeltas(startOffsetX - ARROW_END_X_PADDING, 0)
            arrow:SetTextureCoords(1, 0, 0, 1)
        end,
    }
    local function ApplyPlatformStyle(styleTable)
        ApplyTemplateToControl(self.control, styleTable.template)
        ApplyTemplateToControl(self.arrow, styleTable.arrowTemplate)

        if self.arrow.burstAnim:IsPlaying() then
            self.arrow.burstAnim:PlayInstantlyToStart()
        end
        styleTable.setupArrowCallback(self.barControl, self.arrow)
    end
    self.platformStyle = ZO_PlatformStyle:New(ApplyPlatformStyle, self.keyboardStyle, self.gamepadStyle)

    -- Events
    local function OnPowerUpdate(_, unitTag, powerPoolIndex, powerType, current, max, effectiveMax)
        self:UpdateEnergyValues(current, max)
    end
    control:RegisterForEvent(EVENT_POWER_UPDATE, OnPowerUpdate)
    control:AddFilterForEvent(EVENT_POWER_UPDATE, REGISTER_FILTER_POWER_TYPE, COMBAT_MECHANIC_FLAGS_DAEDRIC)

    local function OnActiveDaedricArtifactChanged()
        self:UpdateVisibility()
    end
    control:RegisterForEvent(EVENT_ACTIVE_DAEDRIC_ARTIFACT_CHANGED, OnActiveDaedricArtifactChanged)

    local function OnPlayerActivated()
        self:UpdateVisibility()
    end
    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

    local function OnBarValueChanged(_, currentEnergy)
        local _, maxEnergy = self.barControl:GetMinMax()
        self.activeWeapon:OnEnergyValueChanged(currentEnergy, maxEnergy)
    end
    self.barControl:SetHandler("OnValueChanged", OnBarValueChanged)

    -- Do our initial update
    self:UpdateVisibility()
end

function ZO_HUDDaedricEnergyMeter:UpdateVisibility()
    local SHOULD_FADE_OUT = true
    self:SetHiddenForReason("daedricArtifactInactive", GetLocalPlayerDaedricArtifactId() == nil, SHOULD_FADE_OUT)
end

do
    -- values match player attribute bars
    local SHOW_FADE_DELAY_MS = 0
    local SHOW_FADE_DURATION_MS = 500
    local HIDE_FADE_DELAY_MS = 1500
    local HIDE_FADE_DURATION_MS = 500
    function ZO_HUDDaedricEnergyMeter:SetHiddenForReason(reason, hidden, shouldFadeOut)
        self.hiddenReasons:SetHiddenForReason(reason, hidden)

        if self.hiddenReasons:IsHidden() then
            if shouldFadeOut then
                self.barFadeAnim:FadeOut(HIDE_FADE_DELAY_MS, HIDE_FADE_DURATION_MS, ZO_ALPHA_ANIMATION_OPTION_USE_CURRENT_ALPHA, function()
                    self.control:SetHidden(true)
                    self:OnHidden()
                end)
            else
                self.control:SetHidden(true)
                self:OnHidden()
            end
        else
            self.barFadeAnim:FadeIn(SHOW_FADE_DELAY_MS, SHOW_FADE_DURATION_MS, ZO_ALPHA_ANIMATION_OPTION_USE_CURRENT_ALPHA)
            self.control:SetHidden(false)
            self:OnShowing()
        end
    end

    function ZO_HUDDaedricEnergyMeter:IsHidden()
        return self.hiddenReasons:IsHidden()
    end

    function ZO_HUDDaedricEnergyMeter:OnHidden()
        self.activeWeapon:Hide()
        self.control:UnregisterForEvent(EVENT_ACTION_SLOT_ABILITY_USED)
        local HIDDEN = true
        self:FireCallbacks("VisibilityChanged", HIDDEN)
    end

    function ZO_HUDDaedricEnergyMeter:OnShowing()
        -- set active weapon
        self.activeWeapon:Hide()

        local daedricArtifactId = internalassert(GetLocalPlayerDaedricArtifactId())
        local visualType = GetDaedricArtifactVisualType(daedricArtifactId)
        self.activeWeapon = self.animationsForArtifactVisualType[visualType] 

        self.activeWeapon:Show()

        -- set initial values
        local currentEnergy, maxEnergy = GetUnitPower("player", COMBAT_MECHANIC_FLAGS_DAEDRIC)
        local INSTANT = true
        self:UpdateEnergyValues(currentEnergy, maxEnergy, INSTANT)
        self.control:RegisterForEvent(EVENT_ACTION_SLOT_ABILITY_USED, function(_, actionSlotIndex)
            if actionSlotIndex == ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 then
                self.activeWeapon:PlayUltimateUsedAnimation()
            end
        end)

        local NOT_HIDDEN = false
        self:FireCallbacks("VisibilityChanged", NOT_HIDDEN)
    end
end

function ZO_HUDDaedricEnergyMeter:UpdateEnergyValues(currentEnergy, maxEnergy, instant)
    if instant then
        ZO_StatusBar_SmoothTransition(self.barControl, currentEnergy, maxEnergy, instant)
        return
    end

    local oldCurrentEnergy = self.barControl:GetValue()
    ZO_StatusBar_SmoothTransition(self.barControl, currentEnergy, maxEnergy)

    if currentEnergy > oldCurrentEnergy then
        PlaySound(SOUNDS.DAEDRIC_ENERGY_BURST)
        self.activeWeapon:PlayEnergyBurstAnimation()
        if not self.arrow.burstAnim:IsPlaying() then
            self.arrow.burstAnim:PlayFromStart()
        end
    end

    -- Warning animation
    local shouldActivateWarning = (maxEnergy == 0 or (currentEnergy / maxEnergy) < ENERGY_WARNING_THRESHOLD)
    if shouldActivateWarning and not self.isWarningActive then
        PlaySound(SOUNDS.DAEDRIC_ENERGY_LOW)
        self.warningLoop:SetPlaybackLoopsRemaining(LOOP_INDEFINITELY)
        self.warningLoop:PlayForward()
        self.isWarningActive = true
    elseif not shouldActivateWarning and self.isWarningActive then
        -- stop gracefully
        self.warningLoop:SetPlaybackLoopsRemaining(0)
        self.isWarningActive = false
    end
end

function ZO_HUDDaedricEnergyMeter_Initialize(control)
    HUD_DAEDRIC_ENERGY_METER = ZO_HUDDaedricEnergyMeter:New(control)
end
