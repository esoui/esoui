ZO_Synergy = ZO_Object:Subclass()

function ZO_Synergy:New(control)
    local synergy = ZO_Object.New(self)
    synergy:Initialize(control)
    return synergy
end

local KEYBOARD_CONSTANTS =
{
    FONT = "ZoInteractionPrompt",
    TEMPLATE = "ZO_KeybindButton_Keyboard_Template",
    OFFSET_Y = ZO_COMMON_INFO_DEFAULT_KEYBOARD_BOTTOM_OFFSET_Y,
    FRAME_TEXTURE = "EsoUI/Art/ActionBar/abilityFrame64_up.dds"
}

local GAMEPAD_CONSTANTS =
{
    FONT = "ZoFontGamepad42",
    TEMPLATE = "ZO_KeybindButton_Gamepad_Template",
    OFFSET_Y = ZO_COMMON_INFO_DEFAULT_GAMEPAD_BOTTOM_OFFSET_Y,
    FRAME_TEXTURE = "EsoUI/Art/ActionBar/Gamepad/gp_abilityFrame64.dds"
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
    self.action = self.container:GetNamedChild("Action")
    self.icon = self.container:GetNamedChild("Icon")
    self.frame = self.icon:GetNamedChild("Frame")
    self.key = self.container:GetNamedChild("Key")

    ZO_PlatformStyle:New(function(constants) self:ApplyTextStyle(constants) end, KEYBOARD_CONSTANTS, GAMEPAD_CONSTANTS)
end

function ZO_Synergy:ApplyTextStyle(constants)
    self.frame:SetTexture(constants.FRAME_TEXTURE)
    self.action:SetFont(constants.FONT)
    ApplyTemplateToControl(self.key, constants.TEMPLATE)
    self.container:ClearAnchors()
    self.container:SetAnchor(BOTTOM, nil, BOTTOM, 0, constants.OFFSET_Y)
end

function ZO_Synergy:OnSynergyAbilityChanged()
    local synergyName, iconFilename = GetSynergyInfo()

    if synergyName and iconFilename then
        if self.lastSynergyName ~= synergyName then
            PlaySound(SOUNDS.ABILITY_SYNERGY_READY)

            self.action:SetText(zo_strformat(SI_USE_SYNERGY, synergyName))
        end
        
        self.icon:SetTexture(iconFilename)

        SHARED_INFORMATION_AREA:SetHidden(self, false)
    else
        SHARED_INFORMATION_AREA:SetHidden(self, true)
    end

    self.lastSynergyName = synergyName
end

function ZO_Synergy:SetHidden(hidden)
    self.control:SetHidden(hidden)
end

function ZO_Synergy:IsVisible()
    return not SHARED_INFORMATION_AREA:IsHidden(self)
end

function ZO_Synergy_OnInitialized(control)
    SYNERGY = ZO_Synergy:New(control)
end