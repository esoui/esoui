--[[
    Base class for combo box ui widgets.
    Subclasses are responsible for the look of the combo box.
--]]

ZO_ComboBox_Base = ZO_InitializingObject:Subclass()

ZO_COMBOBOX_UPDATE_NOW = 1
ZO_COMBOBOX_SUPPRESS_UPDATE = 2

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

function ZO_ComboBox_Base:Initialize(control)
    self.m_container = control
    self.m_selectedItemText = control:GetNamedChild("SelectedItemText")
    self.m_selectedItemData = nil
    self.m_openDropdown = control:GetNamedChild("OpenDropdown")
    self.m_selectedColor = { GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED) }
    self.m_disabledColor = ZO_ERROR_COLOR
    self.m_sortOrder = ZO_SORT_ORDER_UP
    self.m_sortType = ZO_SORT_BY_NAME
    self.m_sortsItems = true
    self.m_sortedItems = {}
    self.m_isDropdownVisible = false
    self.m_font = nil
    self.m_preshowDropdownFn = nil
    self.m_spacing = 0
    self.m_name = control:GetName()
    self.horizontalAlignment = TEXT_ALIGN_LEFT
    control.m_comboBox = self
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

function ZO_ComboBox_Base:GetDropdownFont()
    return self.m_font
end

function ZO_ComboBox_Base:GetDropdownFontObject()
    return _G[self.m_font]
end

function ZO_ComboBox_Base:SetSelectedItemFont(font)
    self.m_selectedItemText:SetFont(font)
end

function ZO_ComboBox_Base:SetSpacing(spacing)
    self.m_spacing = spacing
end

function ZO_ComboBox_Base:GetSpacing()
    return self.m_spacing
end

function ZO_ComboBox_Base:SetSelectedColor(color, colorG, colorB, colorA)
    if type(color) == "table" then
        color, colorG, colorB, colorA = color:UnpackRGBA()
    end

    self.m_selectedColor = { color, colorG, colorB, colorA }
    self.m_selectedItemText:SetColor(color, colorG, colorB, colorA)
end

function ZO_ComboBox_Base:SetDisabledColor(color, colorG, colorB, colorA)
    self.m_disabledColor = ZO_ColorDef:New(color, colorG, colorB, colorA)
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

function ZO_ComboBox_Base:CreateItemEntry(name, callback, enabled)
    local isEnabled = enabled
    if isEnabled == nil then
        -- Evaluate nil to be equivalent to true for backwards compatibility.
        isEnabled = true
    end

    local itemEntry =
    {
        name = name,
        callback = callback,
        enabled = isEnabled,
    }
    return itemEntry
end

function ZO_ComboBox_Base:AddItem(itemEntry, updateOptions)
    table.insert(self.m_sortedItems, itemEntry)
    
    if updateOptions ~= ZO_COMBOBOX_SUPPRESS_UPDATE then
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
    if self:IsDropdownVisible() then
        self:HideDropdownInternal()
    end
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
        self:AddItem(v, ZO_COMBOBOX_SUPPRESS_UPDATE)
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
    if self.m_selectedItemText then
        self.m_selectedItemText:SetText(itemText)
        self.currentSelectedItemText = itemText
    end
end

--Maintain this for addons, but use the better named SetSelectedItemText
function ZO_ComboBox_Base:SetSelectedItem(itemText)
    self:SetSelectedItemText(itemText)
end

function ZO_ComboBox_Base:ItemSelectedClickHelper(item, ignoreCallback)
    if item.enabled == false then
        return false
    end

    local oldItem = self.m_selectedItemData
    if self.dontSetSelectedTextOnSelection ~= true then
        self:SetSelectedItemText(item.name)
    end
    self.m_selectedItemData = item

    if item.callback and not ignoreCallback then
        local selectionChanged = (oldItem ~= item)
        if not selectionChanged and oldItem and item then
            selectionChanged = item.name ~= oldItem.name
        end
        item.callback(self, item.name, item, selectionChanged, oldItem)
    end

    return true
end

--Maintain for addons
function ZO_ComboBox_Base_ItemSelectedClickHelper(comboBox, item, ignoreCallback)
    return comboBox:ItemSelectedClickHelper(item, ignoreCallback)
end

function ZO_ComboBox_Base:SelectItem(item, ignoreCallback)
    if item then
        return self:ItemSelectedClickHelper(item, ignoreCallback)
    end
end

function ZO_ComboBox_Base:SelectItemByIndex(index, ignoreCallback)
    return self:SelectItem(self.m_sortedItems[index], ignoreCallback)
end

function ZO_ComboBox_Base:SelectFirstItem(ignoreCallback)
    return self:SelectItemByIndex(1, ignoreCallback)
end

function ZO_ComboBox_Base:GetIndexByEval(eval)
    for i, item in ipairs(self.m_sortedItems) do
        if eval(item) then
            return i
        end
    end
    return nil
end

function ZO_ComboBox_Base:SetSelectedItemByEval(eval, ignoreCallback)
    local index = self:GetIndexByEval(eval)
    if index then
        return self:SelectItemByIndex(index, ignoreCallback)
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
        if functor(index, data) then
            break -- once the enumeration is complete, returning true means stop enumerating
        end
    end
end

function ZO_ComboBox_Base:GetSelectedTextColor(enabledState)
    if enabledState then
        return unpack(self.m_selectedColor)
    else
        return GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED)
    end
end

function ZO_ComboBox_Base:GetItemNormalColor(item)
    if item.enabled == false then
        return item.m_disabledColor or self.m_disabledColor
    end
    return item.m_normalColor or self.m_normalColor
end

function ZO_ComboBox_Base:GetItemHighlightColor(item)
    if item.enabled == false then
        return item.m_disabledColor or self.m_disabledColor
    end
    return item.m_highlightColor or self.m_highlightColor
end

function ZO_ComboBox_Base:SetEnabled(enabled)
    self.m_container:SetMouseEnabled(enabled)
    self.m_openDropdown:SetEnabled(enabled)
    self.m_selectedItemText:SetColor(self:GetSelectedTextColor(enabled))

    self:HideDropdown()
end

function ZO_ComboBox_Base:SetItemEnabled(item, enabled)
    local isEnabled = enabled
    if isEnabled == nil then
        -- Evaluate nil to be equivalent to true for backwards compatibility.
        isEnabled = true
    end
    item.enabled = isEnabled
end

function ZO_ComboBox_Base:SetItemOnEnter(item, handler)
    item.onEnter = handler
end

function ZO_ComboBox_Base:SetItemOnExit(item, handler)
    item.onExit = handler
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

    if comboBox then
        comboBox:HideDropdown()
    end
end

function ZO_ComboBox_Enable(container)
    ZO_ComboBox_ObjectFromContainer(container):SetEnabled(true)
end

function ZO_ComboBox_Disable(container)
    ZO_ComboBox_ObjectFromContainer(container):SetEnabled(false)
end