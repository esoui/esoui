------------------
-- Guild Finder --
------------------

ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_CHECKBOX_HEIGHT = 50

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_GuildRecruitment_ActivityCheckboxTile_Gamepad = ZO_Object.MultiSubclass(ZO_Tile_Gamepad, ZO_GuildRecruitment_ActivityCheckboxTile)

function ZO_GuildRecruitment_ActivityCheckboxTile_Gamepad:New(...)
    return ZO_GuildRecruitment_ActivityCheckboxTile.New(self, ...)
end

function ZO_GuildRecruitment_ActivityCheckboxTile_Gamepad:PostInitializePlatform()
    ZO_Tile_Gamepad.PostInitializePlatform(self)

    self.titleLabel = self.control:GetNamedChild("Title")
    self.iconControl = self.control:GetNamedChild("Icon")
    self.selectorControl = self.control:GetNamedChild("SelectorBox")
end

function ZO_GuildRecruitment_ActivityCheckboxTile_Gamepad:OnSelectionChanged()
    ZO_Tile_Gamepad.OnSelectionChanged(self)

    self:UpdateVisualDisplay()
end

function ZO_GuildRecruitment_ActivityCheckboxTile_Gamepad:Layout(data)
    ZO_GuildRecruitment_ActivityCheckboxTile.Layout(self, data)

    self.titleLabel:SetText(data.text)
    self.onToggleFunction = data.onToggleFunction

    self:UpdateVisualDisplay()
end

function ZO_GuildRecruitment_ActivityCheckboxTile_Gamepad:OnCheckboxToggle()
    if not self.data.isDisabled then
        PlaySound(SOUNDS.GAMEPAD_GUILD_FINDER_TOGGLE_ACTIVITY)

        self.data.isChecked = not self.data.isChecked

        SetGuildRecruitmentActivityValue(self.data.guildId, self.data.value, self.data.isChecked)

        if self.onToggleFunction then
            self.onToggleFunction(self.data.value, self.data.isChecked)
        end

        self:UpdateVisualDisplay()
    end
end

function ZO_GuildRecruitment_ActivityCheckboxTile_Gamepad:UpdateVisualDisplay()
    local color
    if self:IsSelected() then
        if self.data.isChecked then
            if self.data.isDisabled then
                color = ZO_GUILD_FINDER_GAMEPAD_COLORS.SELECTED_ACTIVE_DISABLED
            else
                color = ZO_GUILD_FINDER_GAMEPAD_COLORS.SELECTED_ACTIVE
            end
        else
            color = ZO_GUILD_FINDER_GAMEPAD_COLORS.SELECTED_INACTIVE
        end
    else
        if self.data.isChecked then
            if self.data.isDisabled then
                color = ZO_GUILD_FINDER_GAMEPAD_COLORS.UNSELECTED_ACTIVE_DISABLED
            else
                color = ZO_GUILD_FINDER_GAMEPAD_COLORS.UNSELECTED_ACTIVE
            end
        else
            color = ZO_GUILD_FINDER_GAMEPAD_COLORS.UNSELECTED_INACTIVE
        end
    end

    self.titleLabel:SetColor(color:UnpackRGB())
    self.selectorControl:SetHidden(not self:IsSelected())
    self.iconControl:SetHidden(not self.data.isChecked)
end

-- XML functions
----------------

function ZO_GuildRecruitment_ActivityCheckboxTile_Gamepad_OnInitialized(control)
    ZO_GuildRecruitment_ActivityCheckboxTile_Gamepad:New(control)
end