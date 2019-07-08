------------------
-- Guild Finder --
------------------

ZO_GUILD_RANK_PERMISSON_CHECKBOX_KEYBOARD_WIDTH = 280
ZO_GUILD_RANK_PERMISSON_CHECKBOX_KEYBOARD_HEIGHT = 24

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_GuildRank_PermissionCheckboxTile_Keyboard = ZO_Object.MultiSubclass(ZO_Tile_Keyboard, ZO_Tile)

function ZO_GuildRank_PermissionCheckboxTile_Keyboard:New(...)
    return ZO_Tile.New(self, ...)
end

function ZO_GuildRank_PermissionCheckboxTile_Keyboard:PostInitializePlatform()
    ZO_Tile_Keyboard.PostInitializePlatform(self)

    self.checkButton = self.control:GetNamedChild("Check")
    self.rankIconControl = self.control:GetNamedChild("Icon")
end

function ZO_GuildRank_PermissionCheckboxTile_Keyboard:Layout(data)
    ZO_Tile.Layout(self, data)

    self.data = data

    local permission = self.data.value
    local isChecked = self:GetIsChecked()
    local mousedOverRank = self:GetMousedOverRank()
    if mousedOverRank then
        local hasRankPermission = mousedOverRank:IsPermissionSet(permission)
        if hasRankPermission then
            self.rankIconControl:SetHidden(false)
            self.rankIconControl:SetTexture(GetGuildRankSmallIcon(mousedOverRank.iconIndex))
        else
            self.rankIconControl:SetHidden(true)
        end
    else
        self.rankIconControl:SetHidden(true)
    end

    local function OnCheckboxToggled()
        local isCheckboxChecked = ZO_CheckButton_IsChecked(self.checkButton)

        if data.onToggleFunction then
            data.onToggleFunction(permission, isCheckboxChecked)
        end
    end

    ZO_CheckButton_SetCheckState(self.checkButton, isChecked)
    ZO_CheckButton_SetLabelText(self.checkButton, data.text)
    ZO_CheckButton_SetTooltipText(self.checkButton, ZO_GuildRanks_Shared.GetToolTipInfoForPermission(permission))
    ZO_CheckButton_SetToggleFunction(self.checkButton, OnCheckboxToggled)

    if self:GetIsDisabled() then
        ZO_CheckButton_Disable(self.checkButton)
    else
        ZO_CheckButton_Enable(self.checkButton)
    end
end

function ZO_GuildRank_PermissionCheckboxTile_Keyboard:GetIsChecked()
    if type(self.data.isChecked) == "function" then
        return self.data.isChecked()
    end
    return self.data.isChecked
end

function ZO_GuildRank_PermissionCheckboxTile_Keyboard:GetIsDisabled()
    if type(self.data.isDisabled) == "function" then
        return self.data.isDisabled()
    end
    return self.data.isDisabled
end

function ZO_GuildRank_PermissionCheckboxTile_Keyboard:GetMousedOverRank()
    if type(self.data.mousedOverRank) == "function" then
        return self.data.mousedOverRank()
    end
    return self.data.mousedOverRank
end

-- XML functions
----------------

function ZO_GuildRank_PermissionCheckboxTile_Keyboard_OnInitialized(control)
    ZO_GuildRank_PermissionCheckboxTile_Keyboard:New(control)
end