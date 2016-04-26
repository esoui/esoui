local PAB_TEMPLATES = {
    [POWERTYPE_MAGICKA] = {
        background = {
            Left = "ZO_PlayerAttributeBgLeftArrow",
            Right = "ZO_PlayerAttributeBgRight",
            Center = "ZO_PlayerAttributeBgCenter",
        },
        frame = {
            Left = "ZO_PlayerAttributeFrameLeftArrow",
            Right = "ZO_PlayerAttributeFrameRight",
            Center = "ZO_PlayerAttributeFrameCenter",
        },
        warner = {
            texture = "ZO_PlayerAttributeMagickaWarnerTexture",
            Left = "ZO_PlayerAttributeWarnerLeftArrow",
            Right = "ZO_PlayerAttributeWarnerRight",
            Center = "ZO_PlayerAttributeWarnerCenter",
        },
        anchors = {
            "ZO_PlayerAttributeBarAnchorLeft",
        },
    },
    [POWERTYPE_HEALTH] = {
        background = {
            Left = "ZO_PlayerAttributeBgLeftArrow",
            Right = "ZO_PlayerAttributeBgRightArrow",
            Center = "ZO_PlayerAttributeBgCenter",
            small = "ZO_PlayerAttributeBgSmallCenter",
        },
        frame = {
            Left = "ZO_PlayerAttributeFrameLeftArrow",
            Right = "ZO_PlayerAttributeFrameRightArrow",
            Center = "ZO_PlayerAttributeFrameCenter",
            small = "ZO_PlayerAttributeFrameSmallCenter",
        },
        warner = {
            texture = "ZO_PlayerAttributeHealthWarnerTexture",
            Left = "ZO_PlayerAttributeWarnerLeftArrow",
            Right = "ZO_PlayerAttributeWarnerRightArrow",
            Center = "ZO_PlayerAttributeWarnerCenter",
        },
        anchors = {
            "ZO_PlayerAttributeHealthBarAnchorLeft",
            "ZO_PlayerAttributeHealthBarAnchorRight",
        },
        smallAnchors = {
            "ZO_PlayerAttributeHealthBarSmallAnchorLeft",
            "ZO_PlayerAttributeHealthBarSmallAnchorRight",
        },
    },
    [POWERTYPE_STAMINA] = {
        background = {
            Left = "ZO_PlayerAttributeBgLeft",
            Right = "ZO_PlayerAttributeBgRightArrow",
            Center = "ZO_PlayerAttributeBgCenter",
        },
        frame = {
            Left = "ZO_PlayerAttributeFrameLeft",
            Right = "ZO_PlayerAttributeFrameRightArrow",
            Center = "ZO_PlayerAttributeFrameCenter",
        },
        warner = {
            texture = "ZO_PlayerAttributeStaminaWarnerTexture",
            Left = "ZO_PlayerAttributeWarnerLeft",
            Right = "ZO_PlayerAttributeWarnerRightArrow",
            Center = "ZO_PlayerAttributeWarnerCenter",
        },
        anchors = {
            "ZO_PlayerAttributeBarAnchorRight",
        },
    },
    [POWERTYPE_WEREWOLF] = {
        background = {
            small = "ZO_PlayerAttributeBgSmallLeft",
        },
        frame = {
            small = "ZO_PlayerAttributeFrameSmallLeft",
        },
        smallAnchors = {
            "ZO_PlayerAttributeSmallAnchorLeft",
        },
    },
    [POWERTYPE_MOUNT_STAMINA] = {
        background = {
            small = "ZO_PlayerAttributeBgSmallRight",
        },
        frame = {
            small = "ZO_PlayerAttributeFrameSmallRight",
        },
        smallAnchors = {
            "ZO_PlayerAttributeSmallAnchorRight",
        },
    },

    statusBar = "ZO_PlayerAttributeStatusBar",
    statusBarGloss = "ZO_PlayerAttributeStatusBarGloss",
    statusBarSmall = "ZO_PlayerAttributeStatusBarSmall",
    statusBarGlossSmall = "ZO_PlayerAttributeStatusBarGlossSmall",
	resourceNumbersLabel = "ZO_PlayerAttributeResourceNumbers",

}

--Attribute Bar
-------------------

local DELAY_BEFORE_FADING = 1500
local ZO_PlayerAttributeBar = ZO_Object:Subclass()

function ZO_PlayerAttributeBar:New(control, barControls, powerType, unitOverride, secondPriorityUnitTag)
	self.control = control

    local bar = ZO_Object.New(self)
    bar.control = control
    bar.barControls = barControls
    bar.powerType = powerType
    bar.unitTag = unitOverride or "player"
    bar.secondPriorityUnitTag = secondPriorityUnitTag
    bar.current = 0
    bar.max = 0
    bar.effectiveMax = 0
    bar.timeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("PlayerAttributeBarAnimation", control)
    bar.fadeOutDelay = 0
    bar.textEnabled = false
    bar.forcedVisibleReferences = 0
    bar:SetTextEnabled(ZO_PlayerAttributeBar.IsTextEnabled())
    bar:RefreshColor()   
    bar:UpdateStatusBar()

    control.playerAttributeBarObject = bar

    control:RegisterForEvent(EVENT_INTERFACE_SETTING_CHANGED, function(_, settingType, settingId) bar:OnInterfaceSettingChanged(settingType, settingId) end)
    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function() bar:OnPlayerActivated() end)
    
    control:RegisterForEvent(EVENT_POWER_UPDATE, function(_, unitTag, powerPoolIndex, powerType, current, max, effectiveMax) bar:OnPowerUpdate(unitTag, powerPoolIndex, powerType, current, max, effectiveMax) end)
    control:AddFilterForEvent(EVENT_POWER_UPDATE, REGISTER_FILTER_POWER_TYPE, powerType)

    if unitOverride or secondPriorityUnitTag then
        control:RegisterForEvent(EVENT_UNIT_CREATED, function(_, unitTag) if self:IsUnitTag(unitTag) then self:UpdateStatusBar() end end)
    end

    EVENT_MANAGER:RegisterForUpdate(control:GetName() .. "FadeUpdate", DELAY_BEFORE_FADING, function() bar:UpdateContextualFading() end)

    return bar
end

function ZO_PlayerAttributeBar:GetEffectiveUnitTag()
    if self.secondPriorityUnitTag then
        if not DoesUnitExist(self.unitTag) and DoesUnitExist(self.secondPriorityUnitTag) then
            return self.secondPriorityUnitTag
        end
    end
    return self.unitTag
end

function ZO_PlayerAttributeBar:IsUnitTag(unitTag)
    return self:GetEffectiveUnitTag() == unitTag
end

function ZO_PlayerAttributeBar:RefreshColor()
    local powerType = self.powerType
    local gradient = ZO_POWER_BAR_GRADIENT_COLORS[powerType]
    for i, control in ipairs(self.barControls) do
        ZO_StatusBar_SetGradientColor(control, gradient)
        control:SetFadeOutLossColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_POWER_FADE_OUT, powerType))
        control:SetFadeOutGainColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_POWER_FADE_IN, powerType))
    end
end

function ZO_PlayerAttributeBar:UpdateStatusBar(current, max, effectiveMax)
    if self.externalVisibilityRequirement and not self.externalVisibilityRequirement() then
        return false
    end

    local forceInit = false

    if(current == nil or max == nil or effectiveMax == nil) then        
        current, max, effectiveMax = GetUnitPower(self:GetEffectiveUnitTag(), self.powerType)

        forceInit = true
    end

    if self.current == current and self.max == max and self.effectiveMax == effectiveMax then
        return
    end

    self.current = current
    self.max = max
    self.effectiveMax = effectiveMax

    local barMax = max
    local barCurrent = current
    if #self.barControls > 1 then
        barMax = barMax / 2
        barCurrent = barCurrent / 2
    end

    for _, control in pairs(self.barControls) do
        ZO_StatusBar_SmoothTransition(control, barCurrent, barMax, forceInit)
    end

    if not forceInit then
        self:ResetFadeOutDelay()
    end
    self:UpdateContextualFading()

    if(self.textEnabled) then
        self.label:SetText(zo_strformat(SI_UNIT_FRAME_BARVALUE, current, max))
    end

	self:UpdateResourceNumbersLabel(current, effectiveMax)
end

function ZO_PlayerAttributeBar:ResetFadeOutDelay()
    self.fadeOutDelay = GetFrameTimeMilliseconds() + DELAY_BEFORE_FADING
end

local EXCLUDE_LINK_CHECK = true

function ZO_PlayerAttributeBar:ShouldContextuallyShow(excludeLinkCheck)
    if self.externalVisibilityRequirement and not self.externalVisibilityRequirement() then
        return false
    end
    if self.max == 0 then
        return false
    end
    if self.forceVisible then
        return true
    end
    if ((self.current < self.effectiveMax) and (self.current ~= 0)) then
        return true
    end
    if not self.IsPlayerFrameFadingEnabled() then
        return true
    end
    if self.fadeOutDelay > GetFrameTimeMilliseconds() then
        return true
    end
    if self.linkedVisibility and not excludeLinkCheck then
        return self.linkedVisibility:ShouldContextuallyShow(EXCLUDE_LINK_CHECK)
    end
    return false
end

function ZO_PlayerAttributeBar:LinkVisibility(otherAttributeBar)
    otherAttributeBar.linkedVisibility = self
    self.linkedVisibility = otherAttributeBar

    otherAttributeBar:UpdateContextualFading()
    self:UpdateContextualFading()
end

function ZO_PlayerAttributeBar:SetExternalVisibilityRequirement(externalVisibilityRequirement)
    self.externalVisibilityRequirement = externalVisibilityRequirement
end

function ZO_PlayerAttributeBar.IsTextEnabled()
    return GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_ALWAYS_SHOW_STATUS_TEXT)
end

function ZO_PlayerAttributeBar.IsPlayerFrameFadingEnabled()
    return GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_FADE_PLAYER_BARS)
end

function ZO_PlayerAttributeBar:UpdateContextualFading()
    local shouldContextuallyShow = self:ShouldContextuallyShow()
    if shouldContextuallyShow ~= self.isContextuallyShown then
        if shouldContextuallyShow then
            self.timeline:PlayForward()
        else
            self.timeline:PlayBackward()
        end
        self.isContextuallyShown = shouldContextuallyShow
        if self.linkedVisibility then
            self.linkedVisibility:UpdateContextualFading()
        end
		self:UpdateResourceNumbersLabel(self.current, self.effectiveMax)
    end
end

function ZO_PlayerAttributeBar:AddForcedVisibleReference()
    self.forcedVisibleReferences = self.forcedVisibleReferences + 1
    self:ResetFadeOutDelay()
    self:SetForceVisible(self.forcedVisibleReferences ~= 0)
end

function ZO_PlayerAttributeBar:RemoveForcedVisibleReference()
    self.forcedVisibleReferences = self.forcedVisibleReferences - 1
    self:ResetFadeOutDelay()
    self:SetForceVisible(self.forcedVisibleReferences ~= 0)
end

function ZO_PlayerAttributeBar:SetForceVisible(forceVisible)
    if self.forceVisible ~= forceVisible then
        self.forceVisible = forceVisible
        self:UpdateContextualFading()
    end
end

function ZO_PlayerAttributeBar:SetTextEnabled(enabled)
    if(self.textEnabled ~= enabled) then
        self.textEnabled = enabled
        if(enabled) then
            if(not self.label) then
                self.label = CreateControlFromVirtual("$(parent)Label", self.control, "ZO_PlayerAttributeBarText")
            end
            self.label:SetHidden(false)
            self:UpdateStatusBar()
        else
            if(self.label) then
                self.label:SetHidden(true)
            end
        end
    end
end

function ZO_PlayerAttributeBar:UpdateResourceNumbersLabel(current, maximum)
	if self.control.resourceNumbersLabel then
		self.control.resourceNumbersLabel:SetText(ZO_FormatResourceBarCurrentAndMax(current, maximum))
	end
end

--Events

function ZO_PlayerAttributeBar:OnPowerUpdate(unitTag, powerPoolIndex, powerType, current, max, effectiveMax)
    if((current ~= self.current or max ~= self.max or effectiveMax ~= self.effectiveMax) and self:IsUnitTag(unitTag)) then
        self:UpdateStatusBar(current, max, effectiveMax)
    end
end

function ZO_PlayerAttributeBar:OnPlayerActivated()
    self:UpdateStatusBar()
end

function ZO_PlayerAttributeBar:OnInterfaceSettingChanged(settingType, settingId)
    if settingType == SETTING_TYPE_UI then
        if settingId == UI_SETTING_FADE_PLAYER_BARS then
            self:UpdateContextualFading()
        elseif settingId == UI_SETTING_ALWAYS_SHOW_STATUS_TEXT then
            self:SetTextEnabled(self.IsTextEnabled())
        end
    end
end

--Attribute Bar Group
-----------------------

local NUM_BARS = 3
local NORMAL_WIDTH = 237
local EXPANDED_WIDTH = 323
local SHRUNK_WIDTH = 141

local BAR_OFFSET_FROM_SCREEN_EDGE = 502
local MIN_BAR_AREA_WIDTH = (EXPANDED_WIDTH + 15) * NUM_BARS
local MAX_BAR_AREA_WIDTH = 1600

local ZO_PlayerAttributeBars = ZO_Object:Subclass()

local PLAYER_ATTRIBUTE_VISUALIZER_SOUNDS = 
{
    [STAT_HEALTH_MAX] = 
    {
        [ATTRIBUTE_BAR_STATE_NORMAL]    = SOUNDS.UAV_MAX_HEALTH_NORMAL,
        [ATTRIBUTE_BAR_STATE_EXPANDED]  = SOUNDS.UAV_MAX_HEALTH_INCREASED,
        [ATTRIBUTE_BAR_STATE_SHRUNK]    = SOUNDS.UAV_MAX_HEALTH_DECREASED,
    },
    [STAT_MAGICKA_MAX] = 
    {
        [ATTRIBUTE_BAR_STATE_NORMAL]    = SOUNDS.UAV_MAX_MAGICKA_NORMAL,
        [ATTRIBUTE_BAR_STATE_EXPANDED]  = SOUNDS.UAV_MAX_MAGICKA_INCREASED,
        [ATTRIBUTE_BAR_STATE_SHRUNK]    = SOUNDS.UAV_MAX_MAGICKA_DECREASED,
    },
    [STAT_STAMINA_MAX] = 
    {
        [ATTRIBUTE_BAR_STATE_NORMAL]    = SOUNDS.UAV_MAX_STAMINA_NORMAL,
        [ATTRIBUTE_BAR_STATE_EXPANDED]  = SOUNDS.UAV_MAX_STAMINA_INCREASED,
        [ATTRIBUTE_BAR_STATE_SHRUNK]    = SOUNDS.UAV_MAX_STAMINA_DECREASED,
    },
    [STAT_HEALTH_REGEN_COMBAT] = 
    {
        [STAT_STATE_INCREASE_GAINED]    = SOUNDS.UAV_INCREASED_HEALTH_REGEN_ADDED,
        [STAT_STATE_INCREASE_LOST]      = SOUNDS.UAV_INCREASED_HEALTH_REGEN_LOST,
        [STAT_STATE_DECREASE_GAINED]    = SOUNDS.UAV_DECREASED_HEALTH_REGEN_ADDED,
        [STAT_STATE_DECREASE_LOST]      = SOUNDS.UAV_DECREASED_HEALTH_REGEN_LOST,
    },
    [STAT_MAGICKA_REGEN_COMBAT] = 
    {
        [STAT_STATE_INCREASE_GAINED]    = SOUNDS.UAV_INCREASED_MAGICKA_REGEN_ADDED,
        [STAT_STATE_INCREASE_LOST]      = SOUNDS.UAV_INCREASED_MAGICKA_REGEN_LOST,
        [STAT_STATE_DECREASE_GAINED]    = SOUNDS.UAV_DECREASED_MAGICKA_REGEN_ADDED,
        [STAT_STATE_DECREASE_LOST]      = SOUNDS.UAV_DECREASED_MAGICKA_REGEN_LOST,
    },
    [STAT_STAMINA_REGEN_COMBAT] = 
    {
        [STAT_STATE_INCREASE_GAINED]    = SOUNDS.UAV_INCREASED_STAMINA_REGEN_ADDED,
        [STAT_STATE_INCREASE_LOST]      = SOUNDS.UAV_INCREASED_STAMINA_REGEN_LOST,
        [STAT_STATE_DECREASE_GAINED]    = SOUNDS.UAV_DECREASED_STAMINA_REGEN_ADDED,
        [STAT_STATE_DECREASE_LOST]      = SOUNDS.UAV_DECREASED_STAMINA_REGEN_LOST,
    },
    [STAT_ARMOR_RATING] = 
    {
        [STAT_STATE_INCREASE_GAINED]    = SOUNDS.UAV_INCREASED_ARMOR_ADDED,
        [STAT_STATE_INCREASE_LOST]      = SOUNDS.UAV_INCREASED_ARMOR_LOST,
        [STAT_STATE_DECREASE_GAINED]    = SOUNDS.UAV_DECREASED_ARMOR_ADDED,
        [STAT_STATE_DECREASE_LOST]      = SOUNDS.UAV_DECREASED_ARMOR_LOST,
    },
    [STAT_POWER] = 
    {
        [STAT_STATE_INCREASE_GAINED]    = SOUNDS.UAV_INCREASED_POWER_ADDED,
        [STAT_STATE_INCREASE_LOST]      = SOUNDS.UAV_INCREASED_POWER_LOST,
        [STAT_STATE_DECREASE_GAINED]    = SOUNDS.UAV_DECREASED_POWER_ADDED,
        [STAT_STATE_DECREASE_LOST]      = SOUNDS.UAV_DECREASED_POWER_LOST,
    },
    [STAT_MITIGATION] =
    {
        [STAT_STATE_IMMUNITY_GAINED]    = SOUNDS.UAV_IMMUNITY_ADDED,
        [STAT_STATE_IMMUNITY_LOST]      = SOUNDS.UAV_IMMUNITY_LOST,
        [STAT_STATE_SHIELD_GAINED]      = SOUNDS.UAV_DAMAGE_SHIELD_ADDED,
        [STAT_STATE_SHIELD_LOST]        = SOUNDS.UAV_DAMAGE_SHIELD_LOST,
        [STAT_STATE_POSSESSION_APPLIED] = SOUNDS.UAV_POSSESSION_APPLIED,
        [STAT_STATE_POSSESSION_REMOVED] = SOUNDS.UAV_POSSESSION_REMOVED,
    },
}

function ZO_PlayerAttributeBars:New(control)
    local barGroup = ZO_Object.New(self)
    barGroup.control = control

    barGroup.forceVisible = false
    
    local bars = {}

    local healthControl = GetControl(control, "Health")
    local healthBarControls = {GetControl(healthControl, "BarLeft"), GetControl(healthControl, "BarRight")}
    healthControl.barControls = healthBarControls
	healthControl.resourceNumbersLabel = GetControl(healthControl, "ResourceNumbers")
    local healthAttributeBar = ZO_PlayerAttributeBar:New(healthControl, healthBarControls, POWERTYPE_HEALTH)
    table.insert(bars, healthAttributeBar)
    healthControl.warner = ZO_HealthWarner:New(healthControl)

    local siegeHealthControl = GetControl(control, "SiegeHealth")
    local siegeHealthBarControls = {GetControl(siegeHealthControl, "BarLeft"), GetControl(siegeHealthControl, "BarRight")}
    siegeHealthControl.barControls = siegeHealthBarControls
    local siegeHealthAttributeBar = ZO_PlayerAttributeBar:New(siegeHealthControl, siegeHealthBarControls, POWERTYPE_HEALTH, "controlledsiege", "escortedram")
    table.insert(bars, siegeHealthAttributeBar)

    local function UpdateSiegeHealthBar() 
        siegeHealthAttributeBar:UpdateStatusBar() 
    end
    control:RegisterForEvent(EVENT_BEGIN_SIEGE_CONTROL, UpdateSiegeHealthBar)
    control:RegisterForEvent(EVENT_END_SIEGE_CONTROL, UpdateSiegeHealthBar)
    control:RegisterForEvent(EVENT_LEAVE_RAM_ESCORT, UpdateSiegeHealthBar)

    siegeHealthAttributeBar:SetExternalVisibilityRequirement(function() return IsGameCameraSiegeControlled() or IsPlayerEscortingRam() end)
    healthAttributeBar:LinkVisibility(siegeHealthAttributeBar)

    local magickaControl = GetControl(control, "Magicka")
    local magickaBarControls = {GetControl(magickaControl, "Bar")}
    magickaControl.barControls = magickaBarControls
	magickaControl.resourceNumbersLabel = GetControl(magickaControl, "ResourceNumbers")
    local magickaAttributeBar = ZO_PlayerAttributeBar:New(magickaControl, magickaBarControls, POWERTYPE_MAGICKA)
    table.insert(bars, magickaAttributeBar)
    magickaControl.warner = ZO_ResourceWarner:New(magickaControl, POWERTYPE_MAGICKA)

    local werewolfControl = GetControl(control, "Werewolf")
    local werewolfBarControls = {GetControl(werewolfControl, "Bar")}
    werewolfControl.barControls = werewolfBarControls
    local werewolfAttributeBar = ZO_PlayerAttributeBar:New(werewolfControl, werewolfBarControls, POWERTYPE_WEREWOLF)
    table.insert(bars, werewolfAttributeBar)

    control:RegisterForEvent(EVENT_WEREWOLF_STATE_CHANGED, function() werewolfAttributeBar:UpdateContextualFading() end)
    werewolfAttributeBar:SetExternalVisibilityRequirement(IsWerewolf)
    magickaAttributeBar:LinkVisibility(werewolfAttributeBar)

    local staminaControl = GetControl(control, "Stamina")
    local staminaBarControls = {GetControl(staminaControl, "Bar")}
    staminaControl.barControls = staminaBarControls
	staminaControl.resourceNumbersLabel = GetControl(staminaControl, "ResourceNumbers")
    local staminaAttributeBar = ZO_PlayerAttributeBar:New(staminaControl, staminaBarControls, POWERTYPE_STAMINA)
    table.insert(bars, staminaAttributeBar)
    staminaControl.warner = ZO_ResourceWarner:New(staminaControl, POWERTYPE_STAMINA)

    local mountStaminaControl = GetControl(control, "MountStamina")
    local mountStaminaBarControls = {GetControl(mountStaminaControl, "Bar")}
    mountStaminaControl.barControls = mountStaminaBarControls
    local mountStaminaAttributeBar = ZO_PlayerAttributeBar:New(mountStaminaControl, mountStaminaBarControls, POWERTYPE_MOUNT_STAMINA)
    table.insert(bars, mountStaminaAttributeBar)

    mountStaminaAttributeBar:SetExternalVisibilityRequirement(IsMounted)
    control:RegisterForEvent(EVENT_MOUNTED_STATE_CHANGED, function() mountStaminaAttributeBar:UpdateContextualFading() end)
    staminaAttributeBar:LinkVisibility(mountStaminaAttributeBar)

    barGroup.bars = bars

    control:RegisterForEvent(EVENT_SCREEN_RESIZED, function() barGroup:OnScreenResized() end)

    local function OnExternalControlCountChanged(bar, change, count)
        if change > 0 then
            bar.playerAttributeBarObject:AddForcedVisibleReference()
        else
            bar.playerAttributeBarObject:RemoveForcedVisibleReference()
        end
    end

    barGroup.forceShow = false

    barGroup.attributeVisualizer = ZO_UnitAttributeVisualizer:New("player", PLAYER_ATTRIBUTE_VISUALIZER_SOUNDS, healthControl, magickaControl, staminaControl, OnExternalControlCountChanged)
    barGroup.attributeVisualizer:AddModule(ZO_UnitVisualizer_ArrowRegenerationModule:New())
    barGroup.attributeVisualizer:AddModule(ZO_UnitVisualizer_ShrinkExpandModule:New(NORMAL_WIDTH, EXPANDED_WIDTH, SHRUNK_WIDTH))

    local armorDamageLayoutInfo =
    {
        type = "Arrow",
        increasedArmorBgContainerTemplate = "ZO_IncreasedArmorBgContainerArrow",
        increasedArmorFrameContainerTemplate = "ZO_IncreasedArmorFrameContainerArrow",
        decreasedArmorOverlayContainerTemplate = "ZO_DecreasedArmorOverlayContainerArrow",
        increasedPowerGlowTemplate = "ZO_IncreasedPowerGlowArrow",

        increasedArmorOffsets = 
        {
            shared = 
            {
                top = -9,
                bottom = 9,
                left = -8,
                right = 8,
            },
        }
    }
    barGroup.attributeVisualizer:AddModule(ZO_UnitVisualizer_ArmorDamage:New(armorDamageLayoutInfo))

    local unwaveringLayoutInfo =
    {
        overlayContainerTemplate = "ZO_UnwaveringOverlayContainerArrow",
        overlayOffsets = 
        {
            keyboard = 
            {
                top = 3,
                bottom = -3,
                left = 3,
                right = -3,
            },
            gamepad = 
            {
                top = 3,
                bottom = -2,
                left = 4,
                right = -4,
            },
        }

    }
    barGroup.attributeVisualizer:AddModule(ZO_UnitVisualizer_UnwaveringModule:New(unwaveringLayoutInfo))

    local possessionLayoutInfo =
    {
        type = "Arrow",
        overlayContainerTemplate = "ZO_PossessionOverlayContainerArrow",
        overlayLeftOffset = 3,
        overlayTopOffset = 3,
        overlayRightOffset = -3,
        overlayBottomOffset = -3,
        possessionHaloGlowTemplate = "ZO_PossessionHaloGlowArrow",
    }
    barGroup.attributeVisualizer:AddModule(ZO_UnitVisualizer_PossessionModule:New(possessionLayoutInfo))

    local powerShieldLayoutInfo =
    {
        barLeftOverlayTemplate = "ZO_PowerShieldBarLeftOverlayArrow",
        barRightOverlayTemplate = "ZO_PowerShieldBarRightOverlayArrow",
    }
    barGroup.attributeVisualizer:AddModule(ZO_UnitVisualizer_PowerShieldModule:New(powerShieldLayoutInfo))
    
    barGroup:ResizeToFitScreen()

    PLAYER_ATTRIBUTE_BARS_FRAGMENT = ZO_HUDFadeSceneFragment:New(control)

    barGroup:ApplyStyle() -- Setup initial visual style based on current mode.
    control:RegisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() barGroup:OnGamepadPreferredModeChanged() end)

    return barGroup
end

local CHILD_DIRECTIONS = { "Left", "Right", "Center" }

function ZO_PlayerAttributeBars:ApplyStyle()
    ApplyTemplateToControl(self.control, ZO_GetPlatformTemplate("ZO_PlayerAttribute"))

    for _, bar in pairs(self.bars) do
        local powerTypeTemplates = PAB_TEMPLATES[bar.powerType]
        local backgroundTemplates = powerTypeTemplates.background
        local frameTemplates = powerTypeTemplates.frame

        local warnerControl = bar.control:GetNamedChild("Warner")
        local bgControl = bar.control:GetNamedChild("BgContainer")

        if warnerControl then
            local warnerTemplates = powerTypeTemplates.warner

            for _, direction in pairs(CHILD_DIRECTIONS) do
                local bgChild = bgControl:GetNamedChild("Bg" .. direction)
                ApplyTemplateToControl(bgChild, ZO_GetPlatformTemplate(backgroundTemplates[direction]))

                local frameControl = bar.control:GetNamedChild("Frame" .. direction)
                ApplyTemplateToControl(frameControl, ZO_GetPlatformTemplate(frameTemplates[direction]))

                local warnerChild = warnerControl:GetNamedChild(direction)
                ApplyTemplateToControl(warnerChild, ZO_GetPlatformTemplate(warnerTemplates.texture))
                ApplyTemplateToControl(warnerChild, ZO_GetPlatformTemplate(warnerTemplates[direction]))
            end

            for i, subBar in pairs(bar.barControls) do
                ApplyTemplateToControl(subBar, ZO_GetPlatformTemplate(PAB_TEMPLATES.statusBar))

                local gloss = subBar:GetNamedChild("Gloss")
                ApplyTemplateToControl(gloss, ZO_GetPlatformTemplate(PAB_TEMPLATES.statusBarGloss))

                local anchorTemplates = powerTypeTemplates.anchors
                if anchorTemplates then
                    subBar:ClearAnchors()
                    ApplyTemplateToControl(subBar, ZO_GetPlatformTemplate(anchorTemplates[i]))
                else
                    ApplyTemplateToControl(subBar, ZO_GetPlatformTemplate(PAB_TEMPLATES.anchor))
                end
            end
        else
            ApplyTemplateToControl(bgControl, ZO_GetPlatformTemplate(backgroundTemplates.small))

            local frame = bar.control:GetNamedChild("Frame")
            ApplyTemplateToControl(frame, ZO_GetPlatformTemplate(frameTemplates.small))

            for i, subBar in pairs(bar.barControls) do
                ApplyTemplateToControl(subBar, ZO_GetPlatformTemplate(PAB_TEMPLATES.statusBarSmall))

                local gloss = subBar:GetNamedChild("Gloss")
                ApplyTemplateToControl(gloss, ZO_GetPlatformTemplate(PAB_TEMPLATES.statusBarGlossSmall))

                local anchorTemplates = powerTypeTemplates.smallAnchors
                if anchorTemplates then
                    subBar:ClearAnchors()
                    ApplyTemplateToControl(subBar, ZO_GetPlatformTemplate(anchorTemplates[i]))
                end
            end
        end

		local resourceNumbersLabel = bar.control:GetNamedChild("ResourceNumbers")
		if resourceNumbersLabel then
			ApplyTemplateToControl(resourceNumbersLabel, ZO_GetPlatformTemplate(PAB_TEMPLATES.resourceNumbersLabel))
		end
    end
end

function ZO_PlayerAttributeBars:OnGamepadPreferredModeChanged()
    self:ApplyStyle()
    self.attributeVisualizer:ApplyPlatformStyle()
end

function ZO_PlayerAttributeBars:ForceShow(forceShow)
    if self.forceShow ~= forceShow then
        self.forceShow = forceShow
        for i = 1, #self.bars do
            if forceShow then
                self.bars[i]:AddForcedVisibleReference()
            else
                self.bars[i]:RemoveForcedVisibleReference()
            end
        end
    end
end

function ZO_PlayerAttributeBars:ResizeToFitScreen()
    local screenWidth, screenHeight = GuiRoot:GetDimensions()
    local barAreaWidth = screenWidth - BAR_OFFSET_FROM_SCREEN_EDGE * 2
    barAreaWidth = zo_clamp(barAreaWidth, MIN_BAR_AREA_WIDTH, MAX_BAR_AREA_WIDTH)
    self.control:SetWidth(barAreaWidth)
end

--Events
function ZO_PlayerAttributeBars:OnScreenResized()
    self:ResizeToFitScreen()
end

--XML

function ZO_PlayerAttribute_OnInitialized(self)
    PLAYER_ATTRIBUTE_BARS = ZO_PlayerAttributeBars:New(self)
end