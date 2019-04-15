------------------
-- Guild Finder --
------------------

ZO_GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD_COMBOBOX_WIDTH = ZO_GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD_COLUMN_WIDTH - 20
ZO_GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD_COMBOBOX_HEIGHT = 60
ZO_GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD_COLUMN_LONG_WIDTH = ZO_GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD_COMBOBOX_WIDTH * 2 - 20
ZO_GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD_COMBOBOX_TALL_HEIGHT = ZO_GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD_COMBOBOX_HEIGHT + 10

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_GuildRecruitment_AttributeSelectionTile_Keyboard = ZO_Object.MultiSubclass(ZO_Tile_Keyboard, ZO_Tile)

function ZO_GuildRecruitment_AttributeSelectionTile_Keyboard:New(...)
    return ZO_Tile.New(self, ...)
end

function ZO_GuildRecruitment_AttributeSelectionTile_Keyboard:Initialize(...)
    ZO_Tile.Initialize(self, ...)

    self.titleLabel = self.control:GetNamedChild("Title")

    local comboBoxControl = self.control:GetNamedChild("ComboBox")
    local comboBox = ZO_ComboBox_ObjectFromContainer(comboBoxControl)
    comboBox:SetSortsItems(false)
    comboBox:SetFont("ZoFontWinT1")
    comboBox:SetSpacing(4)
    self.comboBox = comboBox
end

function ZO_GuildRecruitment_AttributeSelectionTile_Keyboard:Layout(attributeData)
    ZO_Tile.Layout(self, attributeData)

    self.attribute = attributeData.attribute
    self.titleLabel:SetText(attributeData.headerText)

    local function OnComboBoxSelection(comboBox, selectedDataName, selectedData, selectionChanged, oldData)
        if attributeData.onSelectionCallback then
            attributeData.onSelectionCallback(self.attribute, selectedData.value, oldData and oldData.value)
        end
    end

    if attributeData.isTimeSelection then
        ZO_PopulateHoursSinceMidnightPerHourComboBox(self.comboBox, OnComboBoxSelection, attributeData.currentValue)
    else
        GUILD_RECRUITMENT_MANAGER.PopulateDropdown(self.comboBox, attributeData.iterBegin, attributeData.iterEnd, attributeData.stringPrefix, OnComboBoxSelection, attributeData, attributeData.omittedIndex)
    end
end

-- XML functions
----------------

function ZO_GuildRecruitment_AttributeSelectionTile_Keyboard_OnInitialized(control)
    ZO_GuildRecruitment_AttributeSelectionTile_Keyboard:New(control)
end