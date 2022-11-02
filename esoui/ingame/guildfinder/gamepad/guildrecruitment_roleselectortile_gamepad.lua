------------------
-- Guild Finder --
------------------

ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_ROLE_SELECTOR_INDENT_X = ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_INDENT_X
ZO_GUILD_RECRUITMENT_ROLE_SELECTOR_GAMEPAD_WIDTH = ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_COLUMN_WIDTH
ZO_GUILD_RECRUITMENT_ROLE_SELECTOR_GAMEPAD_HEIGHT = 105
ZO_GUILD_RECRUITMENT_ROLE_GAMEPAD_WIDTH = 74
ZO_GUILD_RECRUITMENT_ROLE_END_GAMEPAD_WIDTH = 212

ZO_GuildRecruitment_RoleSelectorTile_Gamepad = ZO_Object.MultiSubclass(ZO_Tile_Gamepad, ZO_Tile)

function ZO_GuildRecruitment_RoleSelectorTile_Gamepad:New(...)
    return ZO_Tile.New(self, ...)
end

function ZO_GuildRecruitment_RoleSelectorTile_Gamepad:Initialize(...)
    ZO_Tile.Initialize(self, ...)

    self.titleLabel = self.control:GetNamedChild("Title")
    self.roleControl = self.control:GetNamedChild("Role")

    self.isChecked = false
end

function ZO_GuildRecruitment_RoleSelectorTile_Gamepad:Layout(data)
    ZO_Tile.Layout(self, data)

    self.onSelectionCallback = data.onSelectionCallback
    self.data = data
    if data.currentValues and data.currentValues[data.role] then
        self.isChecked = data.currentValues[data.role]
    end
    self:UpdateCheckedState()

    self.titleLabel:SetText(data.headerText)
end

-- Overridden Function
function ZO_GuildRecruitment_RoleSelectorTile_Gamepad:SetSelected(isSelected)
    ZO_Tile_Gamepad.SetSelected(self, isSelected)

    self.roleControl.selectedFrame:SetHidden(not isSelected)
end

function ZO_GuildRecruitment_RoleSelectorTile_Gamepad:OnRoleToggle()
    if not self:CanToggleRoleOff() then
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, GetString(SI_GUILD_RECRUITMENT_MUST_SELECT_ROLE_ALERT))
    else
        PlaySound(SOUNDS.GAMEPAD_GUILD_FINDER_TOGGLE_ROLE)

        self.isChecked = not self.isChecked
        self.data.currentValues[self.data.role] = self.isChecked

        if self.onSelectionCallback then
            self.onSelectionCallback(self.data.role, self.isChecked)
        end

        self:UpdateCheckedState()
    end
end

function ZO_GuildRecruitment_RoleSelectorTile_Gamepad:CanToggleRoleOff()
    local hasOtherRoleToggled = false
    for role, value in pairs(self.data.currentValues) do
        local currentValue = value
        if role == self.data.role then
            currentValue = not self.isChecked
        end
        hasOtherRoleToggled = hasOtherRoleToggled or currentValue
    end

    return hasOtherRoleToggled
end

function ZO_GuildRecruitment_RoleSelectorTile_Gamepad:UpdateCheckedState()
    local data = ZO_GAMEPAD_LFG_OPTION_INFO[self.data.role]
    self.roleControl.icon:SetTexture(self.isChecked and data.iconDown or data.iconUp)
    self.roleControl.pressedFrame:SetHidden(not self.isChecked)
end

function ZO_GuildRecruitment_RoleSelectorTile_Gamepad:GetNarrationText()
    --We have to manually specify the header text here as data.headerText is only set for the first role
    local headerText = GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_ROLES)
    return ZO_FormatToggleNarrationText(GetString("SI_LFGROLE", self.data.role), self.isChecked, headerText)
end

-- XML functions
----------------

function ZO_GuildRecruitment_RoleSelectorTile_Gamepad_OnInitialized(control)
    ZO_GuildRecruitment_RoleSelectorTile_Gamepad:New(control)
end