------------------
-- Guild Finder --
------------------

ZO_GUILD_RECRUITMENT_EDITBOX_GAMEPAD_WIDTH = ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_COLUMN_WIDTH * 2
ZO_GUILD_RECRUITMENT_EDITBOX_GAMEPAD_HEADER_HEIGHT = 24
ZO_GUILD_RECRUITMENT_EDITBOX_GAMEPAD_HEADLINE_HEIGHT = 150
ZO_GUILD_RECRUITMENT_EDITBOX_GAMEPAD_DESCRIPTION_HEIGHT = 550
ZO_GUILD_RECRUITMENT_NUMERIC_EDITBOX_GAMEPAD_WIDTH = ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_COLUMN_WIDTH - 20
ZO_GUILD_RECRUITMENT_NUMERIC_EDITBOX_GAMEPAD_HEIGHT = 67


ZO_GUILD_RECRUITMENT_NUMERIC_EDITBOX_GAMEPAD_ENTRY_HEIGHT = ZO_GUILD_RECRUITMENT_NUMERIC_EDITBOX_GAMEPAD_HEIGHT + ZO_GUILD_RECRUITMENT_EDITBOX_GAMEPAD_HEADER_HEIGHT

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_GuildRecruitment_EditBoxTile_Gamepad = ZO_Object.MultiSubclass(ZO_Tile_Gamepad, ZO_ActivationTile)

function ZO_GuildRecruitment_EditBoxTile_Gamepad:New(...)
    return ZO_ActivationTile.New(self, ...)
end

function ZO_GuildRecruitment_EditBoxTile_Gamepad:Initialize(...)
    ZO_ActivationTile.Initialize(self, ...)

    self.edit = self.control:GetNamedChild("BackdropEdit")
    self.selectorControl = self.control:GetNamedChild("SelectorBox")

    local function OnTextEditFocusLost()
        ZO_GamepadEditBox_FocusLost(self.edit)

        if self.onFocusLostFunction then
            self.onFocusLostFunction(self.edit)
        end

        if self.deactivateCallback then
            self.deactivateCallback()
        end
    end

    local function OnTextEditTextChanged()
        if self.onEditFunction then
            local value = self.edit:GetText()
            self.onEditFunction(self.attribute, tonumber(value) or value)
        end
    end

    self.edit:SetHandler("OnFocusLost", OnTextEditFocusLost)
    self.edit:SetHandler("OnTextChanged", OnTextEditTextChanged)
end

function ZO_GuildRecruitment_EditBoxTile_Gamepad:OnSelectionChanged()
    ZO_Tile_Gamepad.OnSelectionChanged(self)

    self.selectorControl:SetHidden(not self:IsSelected())
end

function ZO_GuildRecruitment_EditBoxTile_Gamepad:Activate()
    self.edit:TakeFocus()
end

function ZO_GuildRecruitment_EditBoxTile_Gamepad:Layout(data)
    ZO_ActivationTile.Layout(self, data)

    self.data = data
    self.titleLabel:SetText(data.headerText)

    self.attribute = data.attribute
    self.edit:SetDefaultText(data.defaultText)
    self.onEditFunction = data.onEditCallback
    self.onFocusLostFunction = data.onFocusLostCallback
    if data.currentValue and data.currentValue ~= self.edit:GetText() then
        self.edit:SetText(data.currentValue)
    end

    self.control:SetDimensions(data.dimensionsX, data.dimensionsY)
end

function ZO_GuildRecruitment_EditBoxTile_Gamepad:GetNarrationText()
    return ZO_FormatEditBoxNarrationText(self.edit, self.data.headerText)
end

-- XML functions
----------------

function ZO_GuildRecruitment_EditBoxTile_Gamepad_OnInitialized(control)
    ZO_GuildRecruitment_EditBoxTile_Gamepad:New(control)
end