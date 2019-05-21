--------------------------------------
-- Role Multi Selector
--------------------------------------

-- TODO: When we move this over PreferredRoles.lua could potentially inherit from this class.

ZO_RoleMultiSelector = ZO_Object:Subclass()

function ZO_RoleMultiSelector:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_RoleMultiSelector:Initialize(control)
    self.control = control
    control.selector = self

    local titleControl = control:GetNamedChild("Title")
    if titleControl then
        titleControl:SetText(zo_strformat(SI_GUILD_RECRUITMENT_GUILD_LISTING_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_ROLES)))
    end

    self:InitializeRoles()
end

function ZO_RoleMultiSelector:InitializeRoles()
    self.roleButtons =
    {
        [LFG_ROLE_DPS] = self.control:GetNamedChild("ButtonsDPS"),
        [LFG_ROLE_HEAL] = self.control:GetNamedChild("ButtonsHeal"),
        [LFG_ROLE_TANK] = self.control:GetNamedChild("ButtonsTank"),
    }
end

function ZO_RoleMultiSelector:SetToggleFunction(toggleFunction)
    for _, button in pairs(self.roleButtons) do
        ZO_CheckButton_SetToggleFunction(button, toggleFunction)
    end
end

function ZO_RoleMultiSelector_GetObjectFromControl(control)
    return control.selector
end

---- XML Functions ----

function ZO_RoleMultiSelectorButton_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
    local r, g, b = ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB()
    InformationTooltip:AddLine(GetString("SI_LFGROLE", control.role), "", r, g, b)
    InformationTooltip:AddLine(control.tooltipString, "", r, g, b)
    InformationTooltip:AddLine(GetString(SI_GROUP_PREFERRED_ROLE_DESCRIPTION), "", r, g, b)

    local currentState = control:GetState()
    if currentState == BSTATE_DISABLED or currentState == BSTATE_DISABLED_PRESSED then
        InformationTooltip:AddLine(GetString(SI_GROUP_LIST_PANEL_DISABLED_ROLE_TOOLTIP), "", ZO_ColorDef:New("ff0000"):UnpackRGB())
    end
end

function ZO_RoleMultiSelectorButton_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

do
    local ROLE_NAME_LOOKUP =
    {
        [LFG_ROLE_TANK] = "tank",
        [LFG_ROLE_HEAL] = "healer",
        [LFG_ROLE_DPS] = "dps",
    }

    local TOOLTIP_STRING_LOOKUP =
    {
        [LFG_ROLE_TANK] = GetString(SI_GROUP_PREFERRED_ROLE_TANK_TOOLTIP),
        [LFG_ROLE_HEAL] = GetString(SI_GROUP_PREFERRED_ROLE_HEAL_TOOLTIP),
        [LFG_ROLE_DPS] = GetString(SI_GROUP_PREFERRED_ROLE_DPS_TOOLTIP),
    }

    function ZO_RoleMultiSelectorButton_OnInitialized(control, role)
        local roleName = ROLE_NAME_LOOKUP[role]
        control:SetNormalTexture(string.format("EsoUI/Art/LFG/LFG_%s_up_64.dds", roleName))
        control:SetPressedTexture(string.format("EsoUI/Art/LFG/LFG_%s_down_64.dds", roleName))
        control:SetMouseOverTexture(string.format("EsoUI/Art/LFG/LFG_%s_over_64.dds", roleName))
        control:SetPressedMouseOverTexture(string.format("EsoUI/Art/LFG/LFG_%s_down_over_64.dds", roleName))
        control:SetDisabledTexture(string.format("EsoUI/Art/LFG/LFG_%s_disabled_64.dds", roleName))
        control:SetDisabledPressedTexture(string.format("EsoUI/Art/LFG/LFG_%s_down_disabled_64.dds", roleName))
        control.role = role
        control.tooltipString = TOOLTIP_STRING_LOOKUP[role]
    end
end