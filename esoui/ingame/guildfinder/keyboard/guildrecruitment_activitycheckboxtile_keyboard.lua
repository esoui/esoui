------------------
-- Guild Finder --
------------------

ZO_GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD_CHECKBOX_HEIGHT = 28
ZO_GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD_CHECKBOX_END_HEIGHT = 33

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_GuildRecruitment_ActivityCheckboxTile_Keyboard = ZO_Object.MultiSubclass(ZO_Tile_Keyboard, ZO_GuildRecruitment_ActivityCheckboxTile)

function ZO_GuildRecruitment_ActivityCheckboxTile_Keyboard:New(...)
    return ZO_GuildRecruitment_ActivityCheckboxTile.New(self, ...)
end

function ZO_GuildRecruitment_ActivityCheckboxTile_Keyboard:PostInitializePlatform()
    ZO_Tile_Keyboard.PostInitializePlatform(self)

    self.checkButton = self.control:GetNamedChild("Check")
end

function ZO_GuildRecruitment_ActivityCheckboxTile_Keyboard:Layout(data)
    ZO_GuildRecruitment_ActivityCheckboxTile.Layout(self, data)

    local function OnCheckboxToggled()
        self.data.isChecked = ZO_CheckButton_IsChecked(self.checkButton)
        SetGuildRecruitmentActivityValue(self.data.guildId, self.data.value, self.data.isChecked)
        if data.onToggleFunction then
            data.onToggleFunction(self.data.value, self.data.isChecked)
        end
    end

    ZO_CheckButton_SetCheckState(self.checkButton, self.data.isChecked)
    ZO_CheckButton_SetLabelText(self.checkButton, data.text)
    ZO_CheckButton_SetToggleFunction(self.checkButton, OnCheckboxToggled)

    if data.isDisabled then
        ZO_CheckButton_Disable(self.checkButton)
    else
        ZO_CheckButton_Enable(self.checkButton)
    end
end

-- XML functions
----------------

function ZO_GuildRecruitment_ActivityCheckboxTile_Keyboard_OnInitialized(control)
    ZO_GuildRecruitment_ActivityCheckboxTile_Keyboard:New(control)
end