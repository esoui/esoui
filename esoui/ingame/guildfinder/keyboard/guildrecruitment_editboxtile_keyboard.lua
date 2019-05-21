------------------
-- Guild Finder --
------------------

ZO_GUILD_RECRUITMENT_NUMERIC_EDITBOX_KEYBOARD_WIDTH = 100
ZO_GUILD_RECRUITMENT_NUMERIC_EDITBOX_KEYBOARD_HEIGHT = 36
ZO_GUILD_RECRUITMENT_NUMERIC_EDITBOX_KEYBOARD_ENTRY_HEIGHT = ZO_GUILD_RECRUITMENT_NUMERIC_EDITBOX_KEYBOARD_HEIGHT + ZO_GUILD_RECRUITMENT_EDITBOX_KEYBOARD_HEADER_HEIGHT

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_GuildRecruitment_EditBoxTile_Keyboard = ZO_Object.MultiSubclass(ZO_Tile_Keyboard, ZO_Tile)

function ZO_GuildRecruitment_EditBoxTile_Keyboard:New(...)
    return ZO_Tile.New(self, ...)
end

function ZO_GuildRecruitment_EditBoxTile_Keyboard:Initialize(...)
    ZO_Tile.Initialize(self, ...)

    self.titleLabel = self.control:GetNamedChild("Title")
    self.edit = self.control:GetNamedChild("BackdropEdit")

    local function OnTextEditFocusLost(...)
        if self.edit:GetText() == "" and self.defaultValue ~= nil then
            self.edit:SetText(self.defaultValue)
        end

        if self.onFocusLostFunction then
            self.onFocusLostFunction(self.edit)
        end
    end

    local function OnTextChanged(...)
        self:OnTextChanged(...)
    end

    self.edit:SetHandler("OnFocusLost", OnTextEditFocusLost)
    self.edit:SetHandler("OnTextChanged", OnTextChanged)
end

function ZO_GuildRecruitment_EditBoxTile_Keyboard:OnTextChanged()
    if self.onEditFunction then
        local value = self.edit:GetText()
        self.onEditFunction(self.attribute, tonumber(value) or value)
    end
end

function ZO_GuildRecruitment_EditBoxTile_Keyboard:Layout(data)
    ZO_Tile.Layout(self, data)

    self.attribute = data.attribute
    self.defaultValue = data.defaultValue
    self.onEditFunction = data.onEditCallback
    self.onFocusLostFunction = data.onFocusLostCallback
    self.titleLabel:SetText(data.headerText)

    if data.currentValue then
        self.edit:SetText(data.currentValue)
    end

    self.control:SetDimensions(data.dimensionsX, data.dimensionsY)
end

-- XML functions
----------------

function ZO_GuildRecruitment_EditBoxTile_Keyboard_OnInitialized(control)
    ZO_GuildRecruitment_EditBoxTile_Keyboard:New(control)
end