--[[
    Base class for combo box ui widgets.
    Subclasses are responsible for the look of the combo box.
--]]

ZO_ComboBox_Base = ZO_Object:Subclass()

ZO_COMBOBOX_UPDATE_NOW = 1
ZO_COMBOBOX_SUPRESS_UPDATE = 2

function ZO_ComboBox_Base:ShowDropdownInternal()
    -- this is meant to be overridden by a subclass it's called when the combo dropdown is to be shown
    -- this function should populate the list using the entries in m_sortedItems and make the dropdown visible
end

function ZO_ComboBox_Base:HideDropdownInternal()
    -- this is meant to be overridden by a subclass 
    -- this function should clear the list and hide the dropdown
end

function ZO_ComboBox_Base:OnClearItems()
    -- this can optionally be overriden by a subclass and is called when the contents of a combo box are cleared
end

function ZO_ComboBox_Base:OnItemAdded()
    -- this can optionally be overriden by a subclass and is called when a new entry is added to the combo box
end

function ZO_ComboBox_Base:New(...)
    local comboBox = ZO_Object.New(self)
    comboBox:Initialize(...)
    return comboBox
end

function ZO_ComboBox_Base:Initialize(container)
    self.m_container = container
    self.m_selectedItemText = GetControl(container, "SelectedItemText")
	self.m_selectedItemData = nil
    self.m_openDropdown = GetControl(container, "OpenDropdown")
    self.m_selectedColor = { GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED) }
    container.m_comboBox = self
    
    self.m_sortOrder = ZO_SORT_ORDER_UP
    self.m_sortType = ZO_SORT_BY_NAME
    self.m_sortsItems = true
    self.m_sortedItems = {}
    self.m_isDropdownVisible = false
    self.m_font = nil
    self.m_preshowDropdownFn = nil
    self.m_spacing = 0
    
    self.m_name = container:GetName()
end

function ZO_ComboBox_Base:GetContainer()
    return self.m_container
end

function ZO_ComboBox_Base:SetPreshowDropdownCallback(fn)
    -- Called right before the menu is shown.
    self.m_preshowDropdownFn = fn
end

function ZO_ComboBox_Base:SetFont(font)
    self:SetSelectedItemFont(font)
    self:SetDropdownFont(font)
end

function ZO_ComboBox_Base:SetDropdownFont(font)
    self.m_font = font
end

function ZO_ComboBox_Base:SetSelectedItemFont(font)
    self.m_selectedItemText:SetFont(font)
end

function ZO_ComboBox_Base:SetSpacing(spacing)
    self.m_spacing = spacing
end

function ZO_ComboBox_Base:SetSelectedColor(color, colorG, colorB, colorA)
	if type(color) == "table" then
        color, colorG, colorB, colorA = color:UnpackRGBA()
	end

    self.m_selectedColor = { color, colorG, colorB, colorA }
    self.m_selectedItemText:SetColor(color, colorG, colorB, colorA)
end

function ZO_ComboBox_Base:SetNormalColor(color, colorG, colorB, colorA)
    self.m_normalColor = ZO_ColorDef:New(color, colorG, colorB, colorA)
end

function ZO_ComboBox_Base:SetHighlightedColor(color, colorG, colorB, colorA)
    self.m_highlightColor = ZO_ColorDef:New(color, colorG, colorB, colorA)
end

function ZO_ComboBox_Base:SetSelectedItemTextColor(selected)
    if selected then
        self.m_selectedItemText:SetColor(self.m_highlightColor:UnpackRGB())
    else
        self.m_selectedItemText:SetColor(self.m_normalColor:UnpackRGB())
    end
end

function ZO_ComboBox_Base:SetSortsItems(sortsItems)
    self.m_sortsItems = sortsItems
end

function ZO_ComboBox_Base:SetSortOrder(sortOrder, sortType)
    self.m_sortOrder = sortOrder or ZO_SORT_ORDER_UP
    self.m_sortType = sortType or ZO_SORT_BY_NAME
    self:UpdateItems()
end

function ZO_ComboBox_Base:IsDropdownVisible()
    return self.m_isDropdownVisible
end

function ZO_ComboBox_Base:SetVisible(visible)
    self.m_isDropdownVisible = visible
end

function ZO_ComboBox_Base:CreateItemEntry(name, callback)
    return { name = name, callback = callback }
end

function ZO_ComboBox_Base:AddItem(itemEntry, updateOptions)
    table.insert(self.m_sortedItems, itemEntry)
    
    if(updateOptions ~= ZO_COMBOBOX_SUPRESS_UPDATE) then
        self:UpdateItems()
    end

    self:OnItemAdded()
end

function ZO_ComboBox_Base:ShowDropdown()    
    -- Let the caller know that this is about to be shown...
    if self.m_preshowDropdownFn then
        self.m_preshowDropdownFn(self)
    end
    self:ShowDropdownInternal()
end

function ZO_ComboBox_Base:HideDropdown()
    self:HideDropdownInternal()
end

function ZO_ComboBox_Base:ClearItems()
    ZO_ComboBox_HideDropdown(self:GetContainer())
    ZO_ClearNumericallyIndexedTable(self.m_sortedItems)
    self:SetSelectedItemText("")
	self.m_selectedItemData = nil
    self:OnClearItems()
end

function ZO_ComboBox_Base:GetItems()
    return self.m_sortedItems
end

function ZO_ComboBox_Base:GetNumItems()
    return #self.m_sortedItems
end

function ZO_ComboBox_Base:AddItems(items)
    for k, v in pairs(items) do
        self:AddItem(v, ZO_COMBOBOX_SUPRESS_UPDATE)
    end
    
    self:UpdateItems()
end

local function ComboBoxSortHelper(item1, item2, comboBoxObject)
    return ZO_TableOrderingFunction(item1, item2, "name", comboBoxObject.m_sortType, comboBoxObject.m_sortOrder)
end

function ZO_ComboBox_Base:UpdateItems()
    if self.m_sortOrder and self.m_sortsItems then
        table.sort(self.m_sortedItems, function(item1, item2) return ComboBoxSortHelper(item1, item2, self) end)
    end
    
    if self:IsDropdownVisible() then
        self:ShowDropdown()
    end
end

--This is used if selection of an entry should go through some other avenue to determine the correct display text (e.g.: Chat System)
function ZO_ComboBox_Base:SetDontSetSelectedTextOnSelection(dontSetSelectedTextOnSelection)
    self.dontSetSelectedTextOnSelection = dontSetSelectedTextOnSelection
end

function ZO_ComboBox_Base:SetSelectedItemText(itemText)
    if(self.m_selectedItemText) then
        self.m_selectedItemText:SetText(itemText)
    end
end

--Maintain this for addons, but use the better named SetSelectedItemText
function ZO_ComboBox_Base:SetSelectedItem(itemText)
    self:SetSelectedItemText(itemText)
end

function ZO_ComboBox_Base:ItemSelectedClickHelper(item, ignoreCallback)
    local oldItem = self.m_selectedItemData
    if self.dontSetSelectedTextOnSelection ~= true then
        self:SetSelectedItemText(item.name)
    end
    self.m_selectedItemData = item

    if(item.callback and not ignoreCallback) then
        local selectionChanged = (oldItem ~= item)
        if not selectionChanged and oldItem and item then
            selectionChanged = item.name ~= oldItem.name
        end
        item.callback(self, item.name, item, selectionChanged, oldItem)
    end
end

--Maintain for addons
function ZO_ComboBox_Base_ItemSelectedClickHelper(comboBox, item, ignoreCallback)
    comboBox:ItemSelectedClickHelper(item, ignoreCallback)
end

function ZO_ComboBox_Base:SelectItem(item, ignoreCallback)
    if item then
        self:ItemSelectedClickHelper(item, ignoreCallback)
    end
end

function ZO_ComboBox_Base:SelectItemByIndex(index, ignoreCallback)
    self:SelectItem(self.m_sortedItems[index], ignoreCallback)
end

function ZO_ComboBox_Base:SelectFirstItem(ignoreCallback)
    self:SelectItemByIndex(1, ignoreCallback)
end

function ZO_ComboBox_Base:SetSelectedItemByEval(eval, ignoreCallback)
    for i, item in ipairs(self.m_sortedItems) do
        if eval(item) then
            self:SelectItemByIndex(i, ignoreCallback)
            return true
        end
    end
    return false
end

function ZO_ComboBox_Base:GetSelectedItem()
    return self.m_selectedItemText:GetText()
end

function ZO_ComboBox_Base:GetSelectedItemData()
    return self.m_selectedItemData
end

function ZO_ComboBox_Base:EnumerateEntries(functor)
    for index, data in ipairs(self.m_sortedItems) do
        if(functor(index, data)) then
            break -- once the enumeration is complete, returning true means stop enumerating
        end
    end
end

local OFFSET_Y = 0

local function GlobalMenuClearCallback(comboBox)
    comboBox:HideDropdown()
end

function ZO_ComboBox_Base:GetSelectedTextColor(enabledState)
    if(enabledState) then
        return unpack(self.m_selectedColor)
    else
        return GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED)
    end
end

function ZO_ComboBox_Base:SetEnabled(enabled)
    self.m_container:SetMouseEnabled(enabled)
    self.m_openDropdown:SetEnabled(enabled)
    self.m_selectedItemText:SetColor(self:GetSelectedTextColor(enabled))

    if(self:IsDropdownVisible()) then
        self:HideDropdown()
    end
end

function ZO_ComboBox_Base:GetControl()
    return self.m_container
end

function ZO_ComboBox_Base:SetHorizontalAlignment(alignment)
    self.horizontalAlignment = alignment
    self.m_selectedItemText:SetHorizontalAlignment(alignment)
end

--[[
    Utilities to obtain the combo box from the container.
--]]

local function GetComboBoxFromDropdownButton(button)
    return button:GetParent().m_comboBox
end

function ZO_ComboBox_ObjectFromContainer(container)
    return container.m_comboBox
end

function ZO_ComboBox_OpenDropdown(container)
    local comboBox = ZO_ComboBox_ObjectFromContainer(container)
    
    if not comboBox:IsDropdownVisible() then
        comboBox:ShowDropdown()
    end
end

function ZO_ComboBox_HideDropdown(container)
    local comboBox = ZO_ComboBox_ObjectFromContainer(container)
    
    if(comboBox and comboBox:IsDropdownVisible()) then
        comboBox:HideDropdown()
    end
end

function ZO_ComboBox_Enable(container)
    ZO_ComboBox_ObjectFromContainer(container):SetEnabled(true)
end

function ZO_ComboBox_Disable(container)
    ZO_ComboBox_ObjectFromContainer(container):SetEnabled(false)
end