--[[
    Standard combo box ui widget for keyboard screens.
    Uses a custom control definition with the box border, selected item label, and a dropdown button.
    The actual combobox menu is implemented using a ZO_ContextMenu.  The anchoring of the menu is managed
    by the combo box.
--]]

ZO_ComboBox = ZO_ComboBox_Base:Subclass()

ZO_COMBOBOX_UPDATE_NOW = 1
ZO_COMBOBOX_SUPRESS_UPDATE = 2

function ZO_ComboBox:New(container)
    local comboBox = ZO_ComboBox_Base.New(self, container)
    return comboBox
end

function ZO_ComboBox:AddMenuItems()
    for i = 1, #self.m_sortedItems
    do
        -- The variable item must be defined locally here, otherwise it won't work as an upvalue to the selection helper
        local item = self.m_sortedItems[i]
        AddMenuItem(item.name, function() ZO_ComboBox_Base_ItemSelectedClickHelper(self, item) end, nil, self.m_font, self.m_normalColor, self.m_highlightColor)
    end
end

local OFFSET_Y = 0

local function GlobalMenuClearCallback(comboBox)
    comboBox:HideDropdown()
end

function ZO_ComboBox:ShowDropdownInternal()
    -- Just stealing the menu from anything else that's using it.  That should be correct.
    ClearMenu()
    SetMenuMinimumWidth(self.m_container:GetWidth() - GetMenuPadding() * 2)
    SetMenuSpacing(self.m_spacing)
    
    self:AddMenuItems()
    SetMenuHiddenCallback(function() GlobalMenuClearCallback(self) end)
    ShowMenu(self.m_container, nil, MENU_TYPE_COMBO_BOX)
    AnchorMenu(self.m_container, OFFSET_Y)
    self:SetVisible(true)
end

function ZO_ComboBox:HideDropdownInternal()
    ClearMenu()
    self:SetVisible(false)
end

function ZO_ComboBox_DropdownClicked(container)
    ZO_ComboBox_OpenDropdown(container)
end