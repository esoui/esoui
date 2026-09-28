ZO_Synergy = ZO_InitializingObject:Subclass()

local KEYBOARD_CONSTANTS =
{
    FONT = "ZoInteractionPrompt",
    TEMPLATE = "ZO_KeybindButton_Keyboard_Template",
    OFFSET_Y = ZO_COMMON_INFO_DEFAULT_KEYBOARD_BOTTOM_OFFSET_Y,
    FRAME_TEXTURE = "EsoUI/Art/ActionBar/abilityFrame64_up.dds",
    HUD_ELEMENT_REF_MIN_WIDTH = 300,
}

local GAMEPAD_CONSTANTS =
{
    FONT = "ZoFontGamepad42",
    TEMPLATE = "ZO_KeybindButton_Gamepad_Template",
    OFFSET_Y = ZO_COMMON_INFO_DEFAULT_GAMEPAD_BOTTOM_OFFSET_Y,
    FRAME_TEXTURE = "EsoUI/Art/ActionBar/Gamepad/gp_abilityFrame64.dds",
    HUD_ELEMENT_REF_MIN_WIDTH = 330,
}

function ZO_Synergy:Initialize(control)
    self.control = control

    local function OnSynergyAbilityChanged()
        self:OnSynergyAbilityChanged()
    end

    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnSynergyAbilityChanged)
    self.control:RegisterForEvent(EVENT_SYNERGY_ABILITY_CHANGED, OnSynergyAbilityChanged)

    SHARED_INFORMATION_AREA:AddSynergy(self)

    if IsPlayerActivated() then
        self:OnSynergyAbilityChanged()
    end

    self.container = self.control:GetNamedChild("Container")
    self.hudElementRef = self.container:GetNamedChild("HUDElementRef")
    self.action = self.container:GetNamedChild("Action")
    self.icon = self.container:GetNamedChild("Icon")
    self.frame = self.icon:GetNamedChild("Frame")
    self.key = self.container:GetNamedChild("Key")

    ZO_PlatformStyle:New(function(constants) self:ApplyTextStyle(constants) end, KEYBOARD_CONSTANTS, GAMEPAD_CONSTANTS)
    
    local KEYBOARD_CONFIG =
    {
        defaultAnchor = ZO_Anchor:New(BOTTOM, nil, BOTTOM, 0, KEYBOARD_CONSTANTS.OFFSET_Y)
    }
    local GAMEPAD_CONFIG =
    {
        defaultAnchor = ZO_Anchor:New(BOTTOM, nil, BOTTOM, 0, GAMEPAD_CONSTANTS.OFFSET_Y)
    }
    local elementName = GetString(SI_HUD_EDITOR_SYNERGY)
    HUD_MANAGER:RegisterKeyboardElement(self.container, elementName, KEYBOARD_CONFIG)
    HUD_MANAGER:RegisterGamepadElement(self.container, elementName, GAMEPAD_CONFIG)
end

function ZO_Synergy:ApplyTextStyle(constants)
    self.frame:SetTexture(constants.FRAME_TEXTURE)
    self.action:SetFont(constants.FONT)
    self.hudElementRef:SetDimensionConstraints(constants.HUD_ELEMENT_REF_MIN_WIDTH, 0, 0, 0)
    ApplyTemplateToControl(self.key, constants.TEMPLATE)
    self.container:SetAnchorOffsets(0, constants.OFFSET_Y)
end

function ZO_Synergy:OnSynergyAbilityChanged()
    local hasSynergy, synergyName, iconFilename, prompt = GetCurrentSynergyInfo()

    if hasSynergy then
        if self.lastSynergyName ~= synergyName then
            PlaySound(SOUNDS.ABILITY_SYNERGY_READY)

            if prompt == "" then
                prompt = zo_strformat(SI_USE_SYNERGY, synergyName)
            end
            self.action:SetText(prompt)
            self.lastSynergyName = synergyName
        end
        
        self.icon:SetTexture(iconFilename)

        SHARED_INFORMATION_AREA:SetHidden(self, false)
    else
        SHARED_INFORMATION_AREA:SetHidden(self, true)
        self.lastSynergyName = nil
    end
end

function ZO_Synergy:SetHidden(hidden)
    self.control:SetHidden(hidden)
end

function ZO_Synergy:IsVisible()
    return not SHARED_INFORMATION_AREA:IsHidden(self) and not SHARED_INFORMATION_AREA:IsSuppressed()
end

function ZO_Synergy_OnInitialized(control)
    SYNERGY = ZO_Synergy:New(control)
end