------------------
-- Guild Finder --
------------------

ZO_GUILD_RECRUITMENT_EDITBOX_KEYBOARD_WIDTH = ZO_GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD_COLUMN_WIDTH * 2
ZO_GUILD_RECRUITMENT_EDITBOX_KEYBOARD_HEADER_HEIGHT = 24
ZO_GUILD_RECRUITMENT_EDITBOX_KEYBOARD_HEADLINE_HEIGHT = 100
ZO_GUILD_RECRUITMENT_EDITBOX_KEYBOARD_DESCRIPTION_HEIGHT = 200

ZO_GUILD_RECRUITMENT_EDITBOX_KEYBOARD_HEADLINE_ENTRY_HEIGHT = ZO_GUILD_RECRUITMENT_EDITBOX_KEYBOARD_HEADLINE_HEIGHT + ZO_GUILD_RECRUITMENT_EDITBOX_KEYBOARD_HEADER_HEIGHT
ZO_GUILD_RECRUITMENT_EDITBOX_KEYBOARD_DESCRIPTION_ENTRY_HEIGHT = ZO_GUILD_RECRUITMENT_EDITBOX_KEYBOARD_DESCRIPTION_HEIGHT + ZO_GUILD_RECRUITMENT_EDITBOX_KEYBOARD_HEADER_HEIGHT

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_GuildRecruitment_MultilineEditBoxTile_Keyboard = ZO_Object.MultiSubclass(ZO_Tile_Keyboard, ZO_Tile)

function ZO_GuildRecruitment_MultilineEditBoxTile_Keyboard:New(...)
    return ZO_Tile.New(self, ...)
end

function ZO_GuildRecruitment_MultilineEditBoxTile_Keyboard:Initialize(...)
    ZO_Tile.Initialize(self, ...)

    self.titleLabel = self.control:GetNamedChild("Title")
    self.editBox = ZO_ScrollingSavingEditBox:New(self.control:GetNamedChild("EditText"))
end

function ZO_GuildRecruitment_MultilineEditBoxTile_Keyboard:Layout(data)
    ZO_Tile.Layout(self, data)

    self.attribute = data.attribute
    self.titleLabel:SetText(data.headerText)

    self.editBox:SetShouldEscapeNonColorMarkup(data.stripMarkup)
    self.editBox:SetDefaultText(data.defaultText)
    self.editBox:SetEmptyText(data.emptyText)
    self.editBox:RegisterCallback("Save", function(text) data.onEditCallback(self.attribute, text) end)

    if self.hiddenWhileEditing then
        local IS_EDITING = true
        local FORCE_UPDATE = true
        self.editBox:SetEditing(IS_EDITING, FORCE_UPDATE)
    end

    if data.currentValue then
        self.editBox:SetText(data.currentValue, self.hiddenWhileEditing)
    end

    self.control:SetDimensions(data.dimensionsX, data.dimensionsY)
    self.hiddenWhileEditing = false
end

function ZO_GuildRecruitment_MultilineEditBoxTile_Keyboard:IsEditing()
    return self.editBox:IsEditing()
end

function ZO_GuildRecruitment_MultilineEditBoxTile_Keyboard:GetEditBoxText()
    return self.editBox:GetText()
end

function ZO_GuildRecruitment_MultilineEditBoxTile_Keyboard:SetControlHidden()
    self.hiddenWhileEditing = self.editBox:IsEditing()
end

-- XML functions
----------------

function ZO_GuildRecruitment_MultilineEditBoxTile_Keyboard_OnInitialized(control)
    ZO_GuildRecruitment_MultilineEditBoxTile_Keyboard:New(control)
end