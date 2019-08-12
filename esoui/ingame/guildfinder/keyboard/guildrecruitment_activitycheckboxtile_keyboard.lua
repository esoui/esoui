------------------
-- Guild Finder --
------------------

ZO_GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD_CHECKBOX_HEIGHT = 28
ZO_GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD_CHECKBOX_END_HEIGHT = 33

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_GuildRecruitment_ActivityCheckboxTile_Keyboard = ZO_Object.MultiSubclass(ZO_Tile_Keyboard, ZO_Tile)

function ZO_GuildRecruitment_ActivityCheckboxTile_Keyboard:New(...)
    return ZO_Tile.New(self, ...)
end

function ZO_GuildRecruitment_ActivityCheckboxTile_Keyboard:PostInitializePlatform()
    ZO_Tile_Keyboard.PostInitializePlatform(self)

    self.checkButton = self.control:GetNamedChild("Check")
end

function ZO_GuildRecruitment_ActivityCheckboxTile_Keyboard:Layout(data)
    ZO_Tile.Layout(self, data)

    self.data = data

    local isChecked = self:GetIsChecked()

    local function OnCheckboxToggled()
        isChecked = ZO_CheckButton_IsChecked(self.checkButton)
        if data.onToggleFunction then
            data.onToggleFunction(self.data.value, isChecked)
        end
    end

    ZO_CheckButton_SetCheckState(self.checkButton, isChecked)
    ZO_CheckButton_SetLabelText(self.checkButton, data.text)
    ZO_CheckButton_SetToggleFunction(self.checkButton, OnCheckboxToggled)

    if self:GetIsDisabled() then
        ZO_CheckButton_Disable(self.checkButton)
    else
        ZO_CheckButton_Enable(self.checkButton)
    end
end

function ZO_GuildRecruitment_ActivityCheckboxTile_Keyboard:GetIsChecked()
    if type(self.data.isChecked) == "function" then
        return self.data.isChecked()
    end
    return self.data.isChecked
end

function ZO_GuildRecruitment_ActivityCheckboxTile_Keyboard:GetIsDisabled()
    if type(self.data.isDisabled) == "function" then
        return self.data.isDisabled()
    end
    return self.data.isDisabled
end

-- XML functions
----------------

function ZO_GuildRecruitment_ActivityCheckboxTile_Keyboard_OnInitialized(control)
    ZO_GuildRecruitment_ActivityCheckboxTile_Keyboard:New(control)
end