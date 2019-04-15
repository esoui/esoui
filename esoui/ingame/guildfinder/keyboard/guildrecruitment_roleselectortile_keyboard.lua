------------------
-- Guild Finder --
------------------

ZO_GUILD_RECRUITMENT_ROLESELECTOR_KEYBOARD_WIDTH = ZO_GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD_COLUMN_WIDTH
ZO_GUILD_RECRUITMENT_ROLESELECTOR_KEYBOARD_HEIGHT = 80
ZO_GUILD_RECRUITMENT_ROLE_KEYBOARD_WIDTH = 58
ZO_GUILD_RECRUITMENT_ROLE_END_KEYBOARD_WIDTH = 184

ZO_GuildRecruitment_RoleSelectorTile_Keyboard = ZO_Object.MultiSubclass(ZO_Tile_Keyboard, ZO_Tile)

function ZO_GuildRecruitment_RoleSelectorTile_Keyboard:New(...)
    return ZO_Tile.New(self, ...)
end

function ZO_GuildRecruitment_RoleSelectorTile_Keyboard:Initialize(...)
    ZO_Tile.Initialize(self, ...)

    self.titleText = self.control:GetNamedChild("Title")
    self.roleControl = self.control:GetNamedChild("Role")

    self.roleControl.CanToggleOff = function() return self:CanToggleRoleOff() end
end

function ZO_GuildRecruitment_RoleSelectorTile_Keyboard:Layout(data)
    ZO_Tile.Layout(self, data)

    self.data = data
    self:SetupRole(data.role)
    self.titleText:SetText(data.headerText)
    ZO_CheckButton_SetToggleFunction(self.roleControl, data.onSelectionCallback)

    if data.currentValues and data.currentValues[data.role] then
        ZO_CheckButton_SetChecked(self.roleControl)
    else
        ZO_CheckButton_SetUnchecked(self.roleControl)
    end
end

function ZO_GuildRecruitment_RoleSelectorTile_Keyboard:CanToggleRoleOff()
    local hasOtherRoleToggled = false
    for role, value in pairs(self.data.currentValues) do
        local currentValue = value
        if role == self.data.role then
            currentValue = not ZO_CheckButton_IsChecked(self.roleControl)
        end
        hasOtherRoleToggled = hasOtherRoleToggled or currentValue
    end

    return hasOtherRoleToggled
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

    function ZO_GuildRecruitment_RoleSelectorTile_Keyboard:SetupRole(role)
        local roleName = ROLE_NAME_LOOKUP[role]
        local roleControl = self.roleControl
        roleControl:SetNormalTexture(string.format("EsoUI/Art/LFG/LFG_%s_up_64.dds", roleName))
        roleControl:SetPressedTexture(string.format("EsoUI/Art/LFG/LFG_%s_down_64.dds", roleName))
        roleControl:SetMouseOverTexture(string.format("EsoUI/Art/LFG/LFG_%s_over_64.dds", roleName))
        roleControl:SetPressedMouseOverTexture(string.format("EsoUI/Art/LFG/LFG_%s_down_over_64.dds", roleName))
        roleControl:SetDisabledTexture(string.format("EsoUI/Art/LFG/LFG_%s_disabled_64.dds", roleName))
        roleControl:SetDisabledPressedTexture(string.format("EsoUI/Art/LFG/LFG_%s_down_disabled_64.dds", roleName))
        roleControl.role = role
        roleControl.tooltipString = TOOLTIP_STRING_LOOKUP[role]
    end
end

-- XML functions
----------------

function ZO_GuildRecruitment_RoleSelectorTile_Keyboard_OnInitialized(control)
    ZO_GuildRecruitment_RoleSelectorTile_Keyboard:New(control)
end

function ZO_GuildRecruitment_RoleSelectorTile_Keyboard_OnClicked(self, button)
    if ZO_CheckButton_IsChecked(self) and not self.CanToggleOff() then
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, GetString(SI_GUILD_RECRUITMENT_MUST_SELECT_ROLE_ALERT))
    else
        ZO_CheckButton_OnClicked(self, button)
    end
end