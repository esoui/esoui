--[[
    Standard scrollable combo box ui widget for keyboard screens.
    Uses a custom control definition with the box border, selected item label, and a dropdown button.
    Implemented using a ZO_ScrollList. Anchoring is static and each scrollable combo box manages
    its own dropdown window.
]]--

local DEFAULT_HEIGHT = 250
local DEFAULT_FONT = "ZoFontGame"
local DEFAULT_TEXT_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
local DEFAULT_TEXT_HIGHLIGHT = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_CONTEXT_HIGHLIGHT))

local DEFAULT_ENTRY_ID = 1
local DEFAULT_LAST_ENTRY_ID = 2
ZO_COMBO_BOX_ENTRY_TEMPLATE_HEIGHT = 25
ZO_COMBO_BOX_ENTRY_TEMPLATE_LABEL_PADDING = 8
ZO_SCROLLABLE_COMBO_BOX_LIST_PADDING_Y = 5

ZO_ComboBox = ZO_ComboBox_Base:Subclass()

function ZO_ComboBox:Initialize(control)
    ZO_ComboBox_Base.Initialize(self, control)
    self.m_dropdown = control:GetNamedChild("Dropdown")
    self.m_scroll = self.m_dropdown:GetNamedChild("Scroll")
    self.m_font = DEFAULT_FONT
    self.m_normalColor = DEFAULT_TEXT_COLOR
    self.m_highlightColor = DEFAULT_TEXT_HIGHLIGHT

    self.m_customEntryTemplateInfos = nil
    self.m_nextScrollTypeId = DEFAULT_LAST_ENTRY_ID + 1

    self.m_enableMultiSelect = false
    self.m_maxNumSelections = nil
    self.m_multiSelectItemData = {}

    self.m_containerWidth = control:GetWidth()
    self.m_dropdown:SetWidth(self.m_containerWidth)

    self:SetHeight(DEFAULT_HEIGHT)
    self:SetupScrollList()
end

function ZO_ComboBox:GetEntryTemplateHeightWithSpacing()
    return ZO_COMBO_BOX_ENTRY_TEMPLATE_HEIGHT + self:GetSpacing()
end

function ZO_ComboBox:SetupEntryLabel(labelControl, text)
    labelControl:SetText(text)
    labelControl:SetFont(self.m_font)
    labelControl:SetColor(self.m_normalColor:UnpackRGBA())
    labelControl:SetHorizontalAlignment(self.horizontalAlignment)
end

function ZO_ComboBox:SetupEntryBase(control, data, list)
    control.m_owner = self
    control.m_data = data

    if self:IsItemSelected(data) then
        if not control.m_selectionHighlight then
            control.m_selectionHighlight = CreateControlFromVirtual("$(parent)Selection", control, "ZO_ComboBoxEntry_SelectedHighlight")
        end

        control.m_selectionHighlight:SetHidden(false)
    elseif control.m_selectionHighlight then
        control.m_selectionHighlight:SetHidden(true)
    end
end

function ZO_ComboBox:SetupEntry(control, data, list)
    self:SetupEntryBase(control, data, list)

    control.m_label = control:GetNamedChild("Label")
    self:SetupEntryLabel(control.m_label, data.name)
end

function ZO_ComboBox:SetupScrollList()
    local function SetupScrollableEntry(...)
        self:SetupEntry(...)
    end
    local entryHeightWithSpacing = self:GetEntryTemplateHeightWithSpacing()
    -- To support spacing like regular combo boxes, a separate template needs to be stored for the last entry.
    ZO_ScrollList_AddDataType(self.m_scroll, DEFAULT_ENTRY_ID, "ZO_ComboBoxEntry", entryHeightWithSpacing, SetupScrollableEntry)
    ZO_ScrollList_AddDataType(self.m_scroll, DEFAULT_LAST_ENTRY_ID, "ZO_ComboBoxEntry", ZO_COMBO_BOX_ENTRY_TEMPLATE_HEIGHT, SetupScrollableEntry)

    ZO_ScrollList_EnableHighlight(self.m_scroll, "ZO_TallListHighlight")
end

function ZO_ComboBox:AddCustomEntryTemplate(entryTemplate, entryHeight, setupFunction)
    if not self.m_customEntryTemplateInfos then
        self.m_customEntryTemplateInfos = {}
    end

    local customEntryInfo =
    {
        typeId = self.m_nextScrollTypeId,
        entryHeight = entryHeight,
    }

    self.m_customEntryTemplateInfos[entryTemplate] = customEntryInfo

    local entryHeightWithSpacing = entryHeight + self:GetSpacing()
    ZO_ScrollList_AddDataType(self.m_scroll, self.m_nextScrollTypeId, entryTemplate, entryHeightWithSpacing, setupFunction)
    ZO_ScrollList_AddDataType(self.m_scroll, self.m_nextScrollTypeId + 1, entryTemplate, entryHeight, setupFunction)

    self.m_nextScrollTypeId = self.m_nextScrollTypeId + 2
end

function ZO_ComboBox.SetItemEntryCustomTemplate(itemEntry, template)
    itemEntry.customEntryTemplate = template
end

function ZO_ComboBox:OnGlobalMouseUp(eventCode, button)
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

function ZO_ComboBox:HighlightLabel(labelControl)
    labelControl:SetColor(self.m_highlightColor:UnpackRGBA())
end

function ZO_ComboBox:UnhighlightLabel(labelControl)
    labelControl:SetColor(self.m_normalColor:UnpackRGBA())
end

function ZO_ComboBox:OnMouseEnterEntryBase(control)
    ZO_ScrollList_MouseEnter(self.m_scroll, control)
    if self.onMouseEnterCallback then
        self:onMouseEnterCallback(control)
    end
end

function ZO_ComboBox:OnMouseExitEntryBase(control)
    ZO_ScrollList_MouseExit(self.m_scroll, control)
    if self.onMouseExitCallback then
        self:onMouseExitCallback(control)
    end
end

function ZO_ComboBox:SetSpacing(spacing)
    ZO_ComboBox_Base.SetSpacing(self, spacing)

    local newHeight = self:GetEntryTemplateHeightWithSpacing()
    ZO_ScrollList_UpdateDataTypeHeight(self.m_scroll, DEFAULT_ENTRY_ID, newHeight)

    if self.m_customEntryTemplateInfos then
        for entryTemplate, entryInfo in pairs(self.m_customEntryTemplateInfos) do
            ZO_ScrollList_UpdateDataTypeHeight(self.m_scroll, entryInfo.typeId, entryInfo.entryHeight + self:GetSpacing())
        end
    end
end

function ZO_ComboBox:SetHeight(height)
    self.m_height = height or DEFAULT_HEIGHT
    self.m_dropdown:SetHeight(self.m_height)
    ZO_ScrollList_SetHeight(self.m_scroll, self.m_height)
end

function ZO_ComboBox:IsDropdownVisible()
    return not self.m_dropdown:IsHidden()
end

local function CreateScrollableComboBoxEntry(self, item, index, entryType)
    item.m_index = index
    item.m_owner = self
    local entry = ZO_ScrollList_CreateDataEntry(entryType, item)
    return entry
end

function ZO_ComboBox:AddMenuItems()
    ZO_ScrollList_Clear(self.m_scroll)

    local numItems = #self.m_sortedItems
    local dataList = ZO_ScrollList_GetDataList(self.m_scroll)

    local largestEntryWidth = 0
    local allItemsHeight = 0

    for i = 1, numItems do
        local item = self.m_sortedItems[i]

        local isLastEntry = i == numItems
        local entryHeight = ZO_COMBO_BOX_ENTRY_TEMPLATE_HEIGHT
        local entryType = DEFAULT_ENTRY_ID
        if self.m_customEntryTemplateInfos and item.customEntryTemplate then
            local templateInfo = self.m_customEntryTemplateInfos[item.customEntryTemplate]
            if templateInfo then
                entryType = templateInfo.typeId
                entryHeight = templateInfo.entryHeight
            end
        end

        if isLastEntry then
            entryType = entryType + 1
        else
            entryHeight = entryHeight + self:GetSpacing()
        end

        allItemsHeight = allItemsHeight + entryHeight

        local entry = CreateScrollableComboBoxEntry(self, item, i, entryType)
        table.insert(dataList, entry)

        local fontObject = _G[self.m_font]
        local nameWidth = GetStringWidthScaled(fontObject, item.name, 1, SPACE_INTERFACE)
        if nameWidth > largestEntryWidth then
            largestEntryWidth = nameWidth
        end
    end

    -- using the exact width of the text can leave us with pixel rounding issues
    -- so just add 5 to make sure we don't truncate at certain screen sizes
    largestEntryWidth = largestEntryWidth + 5

    -- Allow the dropdown to automatically widen to fit the widest entry, but
    -- prevent it from getting any skinnier than the container's initial width
    local totalDropDownWidth = largestEntryWidth + ZO_COMBO_BOX_ENTRY_TEMPLATE_LABEL_PADDING * 2 + ZO_SCROLL_BAR_WIDTH
    if totalDropDownWidth > self.m_containerWidth then
        self.m_dropdown:SetWidth(totalDropDownWidth)
    else
        self.m_dropdown:SetWidth(self.m_containerWidth)
    end

    local maxHeight = self.m_height

    allItemsHeight = allItemsHeight + (ZO_SCROLLABLE_COMBO_BOX_LIST_PADDING_Y * 2)

    local desiredHeight = maxHeight
    if allItemsHeight < desiredHeight then
        desiredHeight = allItemsHeight
    end

    self.m_dropdown:SetHeight(desiredHeight)
    ZO_ScrollList_SetHeight(self.m_scroll, desiredHeight)

    ZO_ScrollList_Commit(self.m_scroll)
end

function ZO_ComboBox:ShowDropdownOnMouseUp()
    self.m_dropdown:SetHidden(false)
    self:AddMenuItems()

    self:SetVisible(true)
end

function ZO_ComboBox:SetSelected(index, ignoreCallback)
    local item = self.m_sortedItems[index]
    self:SelectItem(item, ignoreCallback)

    -- multi-select dropdowns will stay open to allow for selecting more entries
    if not self.m_enableMultiSelect then
        self:HideDropdown()
    end
end

function ZO_ComboBox:ShowDropdownInternal()
    -- Just set the global mouse up handler here... we want the combo box to exhibit the same behvaior
    -- as a context menu, which is dismissed when the user clicks outside the menu or on a menu item
    -- (but not in the menu otherwise)
    self.m_dropdown:RegisterForEvent(EVENT_GLOBAL_MOUSE_UP, function(...) self:OnGlobalMouseUp(...) end)
end

function ZO_ComboBox:HideDropdownInternal()
    self.m_dropdown:UnregisterForEvent(EVENT_GLOBAL_MOUSE_UP)
    self.m_dropdown:SetHidden(true)
    self:SetVisible(false)
    if self.onHideDropdownCallback then
        self.onHideDropdownCallback()
    end
end

function ZO_ComboBox:SetHideDropdownCallback(callback)
    self.onHideDropdownCallback = callback
end

function ZO_ComboBox:SetEntryMouseOverCallbacks(onMouseEnterCallback, onMouseExitCallback)
    self.onMouseEnterCallback = onMouseEnterCallback
    self.onMouseExitCallback = onMouseExitCallback
end

function ZO_ComboBox:AddItemToSelected(item)
    if not self.m_enableMultiSelect then
        return
    end

    table.insert(self.m_multiSelectItemData, item)
end

function ZO_ComboBox:RemoveItemFromSelected(item)
    if not self.m_enableMultiSelect then
        return
    end

    for i, itemData in ipairs(self.m_multiSelectItemData) do
        if itemData == item then
            table.remove(self.m_multiSelectItemData, i)
            return
        end
    end
end

function ZO_ComboBox:IsItemSelected(item)
    if not self.m_enableMultiSelect then
        return false
    end

    for i, itemData in ipairs(self.m_multiSelectItemData) do
        if itemData == item then
            return true
        end
    end

    return false
end

function ZO_ComboBox:GetNumSelectedEntries()
    if not self.m_enableMultiSelect then
        return 0
    end

    return #self.m_multiSelectItemData
end

function ZO_ComboBox:ClearAllSelections()
    self.m_multiSelectItemData = {}
    self:RefreshSelectedItemText()
    ZO_ScrollList_RefreshVisible(self.m_scroll)
end

function ZO_ComboBox:SetNoSelectionText(text)
    self.noSelectionText = text or SI_COMBO_BOX_DEFAULT_NO_SELECTION_TEXT
    self:RefreshSelectedItemText()
end

function ZO_ComboBox:SetMultiSelectionTextFormatter(textFormatter)
    self.multiSelectionTextFormatter = textFormatter or SI_COMBO_BOX_DEFAULT_MULTISELECTION_TEXT_FORMATTER
    self:RefreshSelectedItemText()
end

function ZO_ComboBox:EnableMultiSelect(multiSelectionTextFormatter, noSelectionText)
    -- Order matters; we'll wait to set self.m_enableMultiSelect so that we don't needlessly refresh the text when setting it.
    self:SetMultiSelectionTextFormatter(multiSelectionTextFormatter)
    self:SetNoSelectionText(noSelectionText)
    self.m_enableMultiSelect = true
    self:ClearAllSelections()
end

function ZO_ComboBox:DisableMultiSelect()
    self.m_enableMultiSelect = false
    self:ClearItems()
end

-- a maxNumSelections of 0 or nil indicates no limit on selections
function ZO_ComboBox:SetMaxSelections(maxNumSelections)
    if not self.m_enableMultiSelect then
        return false
    end

    if maxNumSelections == 0 then
        maxNumSelections = nil
    end

    -- if the new limit is less than the current limit, clear all the selections
    if maxNumSelections and (self.m_maxNumSelections == nil or maxNumSelections < self.m_maxNumSelections) then
        self:ClearAllSelections()
    end

    self.m_maxNumSelections = maxNumSelections
end

function ZO_ComboBox:SetMaxSelectionsErrorText(errorText)
    self.m_overrideMaxSelectionsErrorText = errorText
end

function ZO_ComboBox:SetOnSelectionBlockedCallback(callback)
    self.onSelectionBlockedCallback = callback
end

function ZO_ComboBox:GetSelectionBlockedErrorText()
    if self.m_overrideMaxSelectionsErrorText then
        return self.m_overrideMaxSelectionsErrorText
    end

    return GetString(SI_COMBO_BOX_MAX_SELECTIONS_REACHED_ALERT)
end

function ZO_ComboBox:RefreshSelectedItemText()
    if not self.m_enableMultiSelect then
        return
    end

    local numSelectedEntries = self:GetNumSelectedEntries()
    if numSelectedEntries > 0 then
        self:SetSelectedItemText(zo_strformat(self.multiSelectionTextFormatter, numSelectedEntries))
    else
        self:SetSelectedItemText(self.noSelectionText)
    end
end

-- Begin ZO_ComboBox_Base overrides

function ZO_ComboBox:GetSelectedItemData()
    if self.m_enableMultiSelect then
        return self.m_multiSelectItemData
    else
        return self.m_selectedItemData
    end
end

function ZO_ComboBox:ClearItems()
    ZO_ComboBox_Base.ClearItems(self)

    self:ClearAllSelections()
end

function ZO_ComboBox:SelectItem(item, ignoreCallback)
    if not self.m_enableMultiSelect then
        ZO_ComboBox_Base.SelectItem(self, item, ignoreCallback)
        return
    end

    if item.enabled == false then
        return
    end

    local newSelectionStatus = not self:IsItemSelected(item)
    if newSelectionStatus then
        if self.m_maxNumSelections == nil or self:GetNumSelectedEntries() < self.m_maxNumSelections then
            self:AddItemToSelected(item)
        else
            if not self.onSelectionBlockedCallback or self.onSelectionBlockedCallback(item) ~= true then
                local alertText = self:GetSelectionBlockedErrorText()
                if ZO_REMOTE_SCENE_CHANGE_ORIGIN == SCENE_MANAGER_MESSAGE_ORIGIN_INTERNAL then
                    RequestAlert(UI_ALERT_CATEGORY_ALERT, SOUNDS.GENERAL_ALERT_ERROR, alertText)
                elseif ZO_REMOTE_SCENE_CHANGE_ORIGIN == SCENE_MANAGER_MESSAGE_ORIGIN_INGAME then
                    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.GENERAL_ALERT_ERROR, alertText)
                end
                return
            end
        end
    else
        self:RemoveItemFromSelected(item)
    end
    PlaySound(SOUNDS.COMBO_CLICK)

    if item.callback and not ignoreCallback then
        item.callback(self, item.name, item)
    end
    self:RefreshSelectedItemText()
    -- refresh the data that was just selected so the selection highlight properly shows/hides
    ZO_ScrollList_RefreshVisible(self.m_scroll, item)
end

-- End ZO_ComboBox_Base overrides

-- Global XML handlers

function ZO_ComboBox_DropdownClicked(control)
    ZO_ComboBox_OpenDropdown(control)
end

function ZO_ComboBox_Entry_OnMouseEnter(control)
    local comboBox = control.m_owner
    if comboBox then
        comboBox:OnMouseEnterEntryBase(control)
        comboBox:HighlightLabel(control.m_label)
    end
end

function ZO_ComboBox_Entry_OnMouseExit(control)
    local comboBox = control.m_owner
    if comboBox then
        comboBox:OnMouseExitEntryBase(control)
        comboBox:UnhighlightLabel(control.m_label)
    end
end

function ZO_ComboBox_Entry_OnSelected(control)
    local comboBox = control.m_owner
    if comboBox then
        comboBox:SetSelected(control.m_data.m_index)
    end
end

--[[
    multiselect combo box ui widget for keyboard screens.
    Uses a custom control definition with the box border, selected item label, and a dropdown button.
    The actual combobox menu is implemented using a ZO_ContextMenu. The anchoring of the menu is managed
    by the combo box, allows for multiple entries to be selected at the same time.
--]]

ZO_MultiSelectComboBox = ZO_ComboBox_Base:Subclass()

function ZO_MultiSelectComboBox:Initialize(container)
    ZO_ComboBox_Base.Initialize(self, container)

    self.m_selectedItemData = {}

    -- Set text to default values. Order matters; self.m_selectedItemData must exist before we call these.
    self:SetMultiSelectionTextFormatter()
    self:SetNoSelectionText()
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
            local normalColor
            local highlightColor
            if item.enabled == false then
                normalColor = item.disabledColor or self.m_disabledColor
                highlightColor = item.disabledColor or self.m_disabledColor
            else
                normalColor = item.normalColor or self.m_normalColor
                highlightColor = item.highlightColor or self.m_highlightColor
            end

            AddMenuItem(item.name, OnMenuItemSelected, MENU_ADD_OPTION_LABEL, self.m_font, normalColor, highlightColor, NO_PADDING_Y, self.horizontalAlignment, needsHighlight, item.onEnter, item.onExit, item.enabled)
        end
    end
end

local OFFSET_Y = 0

local function GlobalMenuClearCallback(comboBox)
    comboBox:HideDropdown()
end

function ZO_MultiSelectComboBox:ShowDropdownInternal()
    ZO_Menu_SetUseUnderlay(true)
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

function ZO_MultiSelectComboBox:HideDropdownInternal()
    ZO_Menu_SetUseUnderlay(false)
    ClearMenu()
    self:SetVisible(false)
    if self.onHideDropdownCallback then
        self.onHideDropdownCallback()
    end
end

function ZO_MultiSelectComboBox:SetHideDropdownCallback(callback)
    self.onHideDropdownCallback = callback
end

function ZO_MultiSelectComboBox:SetNoSelectionText(text)
    self.noSelectionText = text or SI_COMBO_BOX_DEFAULT_NO_SELECTION_TEXT
    self:RefreshSelectedItemText()
end

function ZO_MultiSelectComboBox:SetMultiSelectionTextFormatter(textFormatter)
    self.multiSelectionTextFormatter = textFormatter or SI_COMBO_BOX_DEFAULT_MULTISELECTION_TEXT_FORMATTER
    self:RefreshSelectedItemText()
end

function ZO_MultiSelectComboBox:RefreshSelectedItemText()
    local numSelectedEntries = self:GetNumSelectedEntries()
    if numSelectedEntries > 0 then
        self:SetSelectedItemText(zo_strformat(self.multiSelectionTextFormatter, numSelectedEntries))
    else
        self:SetSelectedItemText(self.noSelectionText)
    end
end

function ZO_MultiSelectComboBox:GetNumSelectedEntries()
    return #self.m_selectedItemData
end

function ZO_MultiSelectComboBox:GetMenuType()
    return MENU_TYPE_MULTISELECT_COMBO_BOX
end

-- Overridden function
function ZO_MultiSelectComboBox:ClearItems()
    ZO_ComboBox_Base.ClearItems(self)
    self.m_selectedItemData = {}
end

-- Overridden function
function ZO_MultiSelectComboBox:SelectItem(item, ignoreCallback)
    if item.enabled == false then
        return
    end

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