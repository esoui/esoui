ZO_ActiveCombatTip = ZO_InitializingObject:Subclass()

local FADE_OUT_TIME = 750
local FADE_IN_TIME = 250

local MIN_TIME_BETWEEN_MESSAGES = 5000

function ZO_ActiveCombatTip:Initialize(control)
    self.control = control
    self.tip = control:GetNamedChild("Tip")
    self.tipText = self.tip:GetNamedChild("TipText")
    self.icon = self.tip:GetNamedChild("Icon")

    self.supressionTime = 0

    self.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ActiveCombatTipAnimation", self.tip)
    self.animation:SetHandler("OnStop", function(timeline) 
        if timeline:GetProgress() == 1.0 and not timeline:IsPlayingBackward() then 
            SHARED_INFORMATION_AREA:SetHidden(self.tip, true)
            self.activeCombatTipId = nil
        end 
    end)

    control:RegisterForEvent(EVENT_DISPLAY_ACTIVE_COMBAT_TIP, function(eventCode, ...) self:OnDisplayActiveCombatTip(...) end)
    control:RegisterForEvent(EVENT_REMOVE_ACTIVE_COMBAT_TIP, function(eventCode, ...) self:OnRemoveActiveCombatTip(...) end)

    local KEYBOARD_CONFIG =
    {
        defaultAnchor = ZO_Anchor:New(BOTTOM, nil, BOTTOM, 0, ZO_COMMON_INFO_DEFAULT_KEYBOARD_BOTTOM_OFFSET_Y)
    }
    local GAMEPAD_CONFIG =
    {
        defaultAnchor = ZO_Anchor:New(BOTTOM, nil, BOTTOM, 0, ZO_COMMON_INFO_DEFAULT_GAMEPAD_BOTTOM_OFFSET_Y)
    }

    local SETTING_ID = 0 -- ACTs don't have a variable for the setting id, it's just 0
    local OPTIONS =
    {
        {
            type = ZO_HUD_EDITOR_OPTION_TYPES.ENUM,
            name = GetString(SI_HUD_EDITOR_CUSTOM_OPTION_VISIBLE),
            tooltipText = GetString(SI_INTERFACE_OPTIONS_ACT_SETTING_LABEL_TOOLTIP),
            key = "Visible",
            valueStringPrefix = "SI_ACTIVECOMBATTIPSETTING",
            values = { ACT_SETTING_OFF, ACT_SETTING_AUTO, ACT_SETTING_ALWAYS, },
            defaultValue = function()
                return tonumber(GetSetting(SETTING_TYPE_ACTIVE_COMBAT_TIP, SETTING_ID))
            end,
            dontSave = true,
            callback = function(element, subKey, oldValue, value)
                if value ~= oldValue then
                    SetSetting(SETTING_TYPE_ACTIVE_COMBAT_TIP, SETTING_ID, tostring(value))
                end
            end,
        },
    }

    local DISPLAY_NAME = GetString(SI_INTERFACE_OPTIONS_ACT_SETTING_LABEL)
    HUD_MANAGER:RegisterKeyboardElement(self.tip, DISPLAY_NAME, KEYBOARD_CONFIG, OPTIONS)
    HUD_MANAGER:RegisterGamepadElement(self.tip, DISPLAY_NAME, GAMEPAD_CONFIG, OPTIONS)

    self:ApplyStyle() -- Setup initial visual style based on current mode.
    control:RegisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() self:OnGamepadPreferredModeChanged() end)

    SHARED_INFORMATION_AREA:AddActiveCombatTips(self.tip)
end

function ZO_ActiveCombatTip:ApplyStyle()
    ApplyTemplateToControl(self.control, ZO_GetPlatformTemplate("ZO_ActiveCombatTips"))
end

function ZO_ActiveCombatTip:OnGamepadPreferredModeChanged()
    self:ApplyStyle()
    self:RefreshTip()
end

function ZO_ActiveCombatTip:IsInSupression()
    return self.supressionTime > GetFrameTimeMilliseconds()
end

function ZO_ActiveCombatTip:RefreshTip()
    local activeCombatTipId = self.activeCombatTipId
    if not activeCombatTipId then
        return
    end

    local name, tipText, iconPath = GetActiveCombatTipInfo(activeCombatTipId)
    self.tipText:SetText(tipText)
    self.tipText:ClearAnchors()

    if iconPath ~= "" then
        self.icon:SetHidden(false)
        self.icon:SetTexture(iconPath)

        self.tipText:SetAnchor(LEFT, self.icon, RIGHT, 5, 0)
    else
        self.icon:SetHidden(true)
        self.tipText:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)
    end
end

function ZO_ActiveCombatTip:OnDisplayActiveCombatTip(activeCombatTipId)
    if not self.activeCombatTipId and not self:IsInSupression() then
        SHARED_INFORMATION_AREA:SetHidden(self.tip, false)
        self.animation:PlayFromEnd()
        self.activeCombatTipId = activeCombatTipId

        self:RefreshTip()

        self.tip.activeCombatTipId = activeCombatTipId

        PlaySound(SOUNDS.ACTIVE_COMBAT_TIP_SHOWN)
    end
end

local SoundsForReason = {
    [ACTIVE_COMBAT_TIP_RESULT_SUCCESS] = SOUNDS.ACTIVE_COMBAT_TIP_SUCCESS,
    [ACTIVE_COMBAT_TIP_RESULT_FAILURE] =  SOUNDS.ACTIVE_COMBAT_TIP_FAILS,
    [ACTIVE_COMBAT_TIP_RESULT_NO_ACTION] =  nil,
}

function ZO_ActiveCombatTip:OnRemoveActiveCombatTip(activeCombatTipId, reason)
    if self.activeCombatTipId == activeCombatTipId then
        self.animation:PlayFromStart()
        self.supressionTime = MIN_TIME_BETWEEN_MESSAGES + GetFrameTimeMilliseconds()
        
        if SoundsForReason[reason] then
            PlaySound(SoundsForReason[reason])
        end
    end
end

function ZO_ActiveCombatTips_Initialize(control)
    ACTIVE_COMBAT_TIP_SYSTEM = ZO_ActiveCombatTip:New(control)
end

