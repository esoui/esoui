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

do
    --Padding is handled using SetSpacing
    local NO_PADDING_Y = 0

    function ZO_ComboBox:AddMenuItems()
        for i = 1, #self.m_sortedItems do
            -- The variable item must be defined locally here, otherwise it won't work as an upvalue to the selection helper
            local item = self.m_sortedItems[i]
            AddMenuItem(item.name, function() self:ItemSelectedClickHelper(item) end, MENU_ADD_OPTION_LABEL, self.m_font, self.m_normalColor, self.m_highlightColor, NO_PADDING_Y, self.horizontalAlignment)
        end
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
    ShowMenu(self.m_container, nil, self:GetMenuType())
    AnchorMenu(self.m_container, OFFSET_Y)
    self:SetVisible(true)
end

function ZO_ComboBox:HideDropdownInternal()
    ClearMenu()
    self:SetVisible(false)
    if self.onHideDropdownCallback then
        self.onHideDropdownCallback()
    end
end

function ZO_ComboBox_DropdownClicked(container)
    ZO_ComboBox_OpenDropdown(container)
end

function ZO_ComboBox:GetMenuType()
    return MENU_TYPE_COMBO_BOX
end

function ZO_ComboBox:SetHideDropdownCallback(callback)
    self.onHideDropdownCallback = callback
end

--[[
    Scrollable combo box ui widget for keyboard screens.

    Implemented using a ZO_ScrollList, and intended to be used for combo boxes that are expected to contain a
    lot of data (more data than what could be reasonably be managed in a context menu). Anchoring is static and
    each scrollable combo box manages its own dropdown window.
]]--

local DEFAULT_HEIGHT = 250
local DEFAULT_FONT = "ZoFontGame"
local DEFAULT_TEXT_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
local DEFAULT_TEXT_HIGHLIGHT = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_CONTEXT_HIGHLIGHT))

local ENTRY_ID = 1
local LAST_ENTRY_ID = 2
local SCROLLABLE_ENTRY_TEMPLATE = "ZO_ScrollableComboBoxItem"
ZO_SCROLLABLE_ENTRY_TEMPLATE_HEIGHT = 25
ZO_SCROLLABLE_COMBO_BOX_LIST_PADDING_Y = 5

ZO_ScrollableComboBox = ZO_ComboBox:Subclass()

function ZO_ScrollableComboBox:New(container)
    return ZO_ComboBox.New(self, container)
end

function ZO_ScrollableComboBox:Initialize(container)
    ZO_ComboBox.Initialize(self, container)
    self.m_dropdown = container:GetNamedChild("Dropdown")
    self.m_scroll = self.m_dropdown:GetNamedChild("Scroll")

    self.m_font = DEFAULT_FONT
    self.m_normalColor = DEFAULT_TEXT_COLOR
    self.m_highlightColor = DEFAULT_TEXT_HIGHLIGHT

    self:SetHeight(DEFAULT_HEIGHT)

    self:SetupScrollList()
end

function ZO_ScrollableComboBox:GetEntryTemplateHeightWithSpacing()
    return ZO_SCROLLABLE_ENTRY_TEMPLATE_HEIGHT + self.m_spacing
end

local function SetupScrollableEntry(control, data, list)
    control.m_owner = data.m_owner
    control.m_data = data
    control.m_label = control:GetNamedChild("Label")

    control.m_label:SetText(data.name)
    control.m_label:SetFont(control.m_owner.m_font)
    control.m_label:SetColor(control.m_owner.m_normalColor:UnpackRGBA())
end

function ZO_ScrollableComboBox:SetupScrollList()
    local entryHeight = self:GetEntryTemplateHeightWithSpacing()
    -- To support spacing like regular combo boxes, a separate template needs to be stored for the last entry.
    ZO_ScrollList_AddDataType(self.m_scroll, ENTRY_ID, SCROLLABLE_ENTRY_TEMPLATE, entryHeight, SetupScrollableEntry)
    ZO_ScrollList_AddDataType(self.m_scroll, LAST_ENTRY_ID, SCROLLABLE_ENTRY_TEMPLATE, entryHeight, SetupScrollableEntry)

    ZO_ScrollList_EnableSelection(self.m_scroll, "ZO_TallListSelectedHighlight")
    ZO_ScrollList_EnableHighlight(self.m_scroll, "ZO_TallListHighlight")
end

function ZO_ScrollableComboBox:OnGlobalMouseUp(eventCode, button)
    if self:IsDropdownVisible() then
        if button == MOUSE_BUTTON_INDEX_LEFT and not MouseIsOver(self.m_dropdown) then
            self:HideDropdown()
        end
    else
        if self.m_container:IsHidden() then
            self:HideDropdown()
        else
            -- If shown in ShowDropdownInternal, the global mouseup will fire and immediately dismiss the combo box. We need to
            -- delay showing it until the first one fires. 
            self:ShowDropdownOnMouseUp()
        end
    end
end

function ZO_ScrollableComboBox:SetSpacing(spacing)
    ZO_ComboBox.SetSpacing(self, spacing)

    local newHeight = self:GetEntryTemplateHeightWithSpacing()
    ZO_ScrollList_UpdateDataTypeHeight(self.m_scroll, ENTRY_ID, newHeight)
end

function ZO_ScrollableComboBox:SetHeight(height)
    self.m_height = height or DEFAULT_HEIGHT
    self.m_dropdown:SetHeight(self.m_height)
    ZO_ScrollList_SetHeight(self.m_scroll, self.m_height)
end

function ZO_ScrollableComboBox:IsDropdownVisible()
    return not self.m_dropdown:IsHidden()
end

local function CreateScrollableComboBoxEntry(self, item, index, isLast)
    item.m_index = index
    item.m_owner = self
    local entryType = isLast and LAST_ENTRY_ID or ENTRY_ID
    local entry = ZO_ScrollList_CreateDataEntry(entryType, item)

    return entry
end

function ZO_ScrollableComboBox:AddMenuItems()
    ZO_ScrollList_Clear(self.m_scroll)

    local numItems = #self.m_sortedItems
    local dataList = ZO_ScrollList_GetDataList(self.m_scroll)

    for i = 1, numItems do
        local item = self.m_sortedItems[i]
        local entry = CreateScrollableComboBoxEntry(self, item, i, i == numItems)
        table.insert(dataList, entry)
    end

    local maxHeight = self.m_height
    -- get the height of all the entries we are going to show
    -- the last entry uses a separate entry template that does not include the spacing in its height
    local allItemsHeight = self:GetEntryTemplateHeightWithSpacing() * (numItems - 1) + ZO_SCROLLABLE_ENTRY_TEMPLATE_HEIGHT + (ZO_SCROLLABLE_COMBO_BOX_LIST_PADDING_Y * 2)

    local desiredHeight = maxHeight
    if allItemsHeight < desiredHeight then
        desiredHeight = allItemsHeight
    end

    self.m_dropdown:SetHeight(desiredHeight)
    ZO_ScrollList_SetHeight(self.m_scroll, desiredHeight)

    ZO_ScrollList_Commit(self.m_scroll)
end

function ZO_ScrollableComboBox:ShowDropdownOnMouseUp()
    self.m_dropdown:SetHidden(false)
    self:AddMenuItems()
    
    self:SetVisible(true)
end

function ZO_ScrollableComboBox:SetSelected(index)
    self:ItemSelectedClickHelper(self.m_sortedItems[index])
    self:HideDropdown()
end

function ZO_ScrollableComboBox:ShowDropdownInternal()
    -- Just set the global mouse up handler here...we want the scrollable combo box to exhibit the same behvaior
    -- as a regular combo box that uses the context menus, which are dismissed when the user clicks outside
    -- the menu or on a menu item (but not in the menu otherwise)
    self.m_dropdown:RegisterForEvent(EVENT_GLOBAL_MOUSE_UP, function(...) self:OnGlobalMouseUp(...) end)
end

function ZO_ScrollableComboBox:HideDropdownInternal()
    self.m_dropdown:UnregisterForEvent(EVENT_GLOBAL_MOUSE_UP)
    self.m_dropdown:SetHidden(true)
    self:SetVisible(false)
    if self.onHideDropdownCallback then
        self.onHideDropdownCallback()
    end
end

function ZO_ScrollableComboBox_Entry_OnMouseEnter(entry)
    if entry.m_owner then
        ZO_ScrollList_MouseEnter(entry.m_owner.m_scroll, entry)
        entry.m_label:SetColor(entry.m_owner.m_highlightColor:UnpackRGBA())
    end
end

function ZO_ScrollableComboBox_Entry_OnMouseExit(entry)
    if entry.m_owner then
        ZO_ScrollList_MouseExit(entry.m_owner.m_scroll, entry)
        entry.m_label:SetColor(entry.m_owner.m_normalColor:UnpackRGBA())
    end
end

function ZO_ScrollableComboBox_Entry_OnSelected(entry)
    if entry.m_owner then
        entry.m_owner:SetSelected(entry.m_data.m_index)
    end
end

--[[
    multiselect combo box ui widget for keyboard screens.
    Similar to the standard combo box, this object allows for multiple entries to be selected
    at the same time. 
--]]

ZO_MultiSelectComboBox = ZO_ComboBox:Subclass()

function ZO_MultiSelectComboBox:New(container)
    return ZO_ComboBox.New(self, container)
end

function ZO_MultiSelectComboBox:Initialize(container)
    ZO_ComboBox.Initialize(self, container)

    self.m_selectedItemData = {}
end

do
    --Padding is handled using SetSpacing
    local NO_PADDING_Y = 0

    -- Overridden function
    function ZO_MultiSelectComboBox:AddMenuItems()
        for i, item in ipairs(self.m_sortedItems) do
            local function OnMenuItemSelected()
                self:SelectItem(item)
            end
            local needsHighlight = self:IsItemSelected(item)
            AddMenuItem(item.name, OnMenuItemSelected, MENU_ADD_OPTION_LABEL, self.m_font, self.m_normalColor, self.m_highlightColor, NO_PADDING_Y, self.horizontalAlignment, needsHighlight)
        end
    end
end

function ZO_MultiSelectComboBox:SetNoSelectionText(text)
    self.noSelectionText = text
    self:RefreshSelectedItemText()
end

function ZO_MultiSelectComboBox:SetMultiSelectionTextFormatter(textFormatter)
    self.multiSelectionTextFormatter = textFormatter
    self:RefreshSelectedItemText()
end

function ZO_MultiSelectComboBox:RefreshSelectedItemText()
    local numSelectedEntries = self:GetNumSelectedEntries()
    if numSelectedEntries > 0 then
        if self.multiSelectionTextFormatter then
            self:SetSelectedItemText(zo_strformat(self.multiSelectionTextFormatter, numSelectedEntries))
        else
            internalassert(false) -- need to define the formatter
        end
    elseif self.noSelectionText then
        self:SetSelectedItemText(self.noSelectionText)
    else
        internalassert(false) -- need to define the no selection text
    end
end

function ZO_MultiSelectComboBox:GetNumSelectedEntries()
    return #self.m_selectedItemData
end

-- Overridden function
function ZO_MultiSelectComboBox:GetMenuType()
    return MENU_TYPE_MULTISELECT_COMBO_BOX
end

-- Overridden function
function ZO_MultiSelectComboBox:ClearItems()
    ZO_ComboBox.ClearItems(self)
    self.m_selectedItemData = {}
end

-- Overridden function
function ZO_MultiSelectComboBox:SelectItem(item, ignoreCallback)
    local newSelectionStatus = not self:IsItemSelected(item)
    if newSelectionStatus then
        self:AddItemToSelected(item)
    else
        self:RemoveItemFromSelected(item)
    end
    PlaySound(SOUNDS.COMBO_CLICK)

    if item.callback and not ignoreCallback then
        item.callback(self, item.name, item)
    end
    self:RefreshSelectedItemText()
end

-- Overridden function
function ZO_MultiSelectComboBox:ShowDropdownInternal()
    ZO_Menu_SetUseUnderlay(true)
    ZO_ComboBox.ShowDropdownInternal(self)
end

-- Overridden function
function ZO_MultiSelectComboBox:HideDropdownInternal()
    ZO_Menu_SetUseUnderlay(false)
    ZO_ComboBox.HideDropdownInternal(self)
end

function ZO_MultiSelectComboBox:AddItemToSelected(item)
    table.insert(self.m_selectedItemData, item)
end

function ZO_MultiSelectComboBox:RemoveItemFromSelected(item)
    for i, itemData in ipairs(self.m_selectedItemData) do
        if itemData == item then
            table.remove(self.m_selectedItemData, i)
            return
        end
    end
end

function ZO_MultiSelectComboBox:IsItemSelected(item)
    for i, itemData in ipairs(self.m_selectedItemData) do
        if itemData == item then
            return true
        end
    end

    return false
end

function ZO_MultiSelectComboBox:ClearAllSelections()
    self.m_selectedItemData = {}
    self:RefreshSelectedItemText()
end