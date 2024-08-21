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
    self.m_font = DEFAULT_FONT
    self.m_normalColor = DEFAULT_TEXT_COLOR
    self.m_highlightColor = DEFAULT_TEXT_HIGHLIGHT

    self.m_customEntryTemplateInfos = nil

    self.m_enableMultiSelect = false
    self.m_maxNumSelections = nil
    self.m_multiSelectItemData = {}

    self.m_containerWidth = control:GetWidth()

    self:SetHeight(DEFAULT_HEIGHT)

    self:SetDropdownObject(ZO_COMBO_BOX_DROPDOWN_KEYBOARD)

    local function OnEffectivelyHidden()
        self:HideDropdown()
    end
    control:SetHandler("OnEffectivelyHidden", OnEffectivelyHidden)
end

function ZO_ComboBox:AddCustomEntryTemplate(entryTemplate, entryHeight, setupFunction)
    if not self.m_customEntryTemplateInfos then
        self.m_customEntryTemplateInfos = {}
    end

    local customEntryInfo =
    {
        entryTemplate = entryTemplate,
        entryHeight = entryHeight,
        setupFunction = setupFunction,
    }

    self.m_customEntryTemplateInfos[entryTemplate] = customEntryInfo

    self.m_dropdownObject:AddCustomEntryTemplate(entryTemplate, entryHeight, setupFunction)
end

function ZO_ComboBox.SetItemEntryCustomTemplate(itemEntry, entryTemplate)
    itemEntry.customEntryTemplate = entryTemplate
end

function ZO_ComboBox:SetDropdownObject(dropdownObject)
    self.m_dropdownObject = dropdownObject

    if self.m_customEntryTemplateInfos then
        for entryTemplate, entryInfo in pairs(self.m_customEntryTemplateInfos) do
            self.m_dropdownObject:AddCustomEntryTemplate(entryInfo.entryTemplate, entryInfo.entryHeight, entryInfo.setupFunction)
        end
    end

    -- Adding these members for backwards compatibility, since a lot of old addons referenced them directly, 
    -- though we don't need them anymore
    self.m_dropdown = dropdownObject.control
    self.m_scroll = dropdownObject.scrollControl
end

function ZO_ComboBox:OnGlobalMouseUp(eventCode, button)
    if self:IsDropdownVisible() then
        if button == MOUSE_BUTTON_INDEX_LEFT and not self.m_dropdownObject:IsMouseOverControl() then
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

function ZO_ComboBox:HighlightLabel(labelControl, data)
    local color = self:GetItemHighlightColor(data)
    labelControl:SetColor(color:UnpackRGBA())
end

function ZO_ComboBox:UnhighlightLabel(labelControl, data)
    local color = self:GetItemNormalColor(data)
    labelControl:SetColor(color:UnpackRGBA())
end

function ZO_ComboBox:OnMouseEnterEntryBase(control)
    if self.onMouseEnterCallback then
        self:onMouseEnterCallback(control)
    end
end

function ZO_ComboBox:OnMouseExitEntryBase(control)
    if self.onMouseExitCallback then
        self:onMouseExitCallback(control)
    end
end

function ZO_ComboBox:SetSpacing(spacing)
    ZO_ComboBox_Base.SetSpacing(self, spacing)
end

function ZO_ComboBox:SetHeight(height)
    self.m_height = height or DEFAULT_HEIGHT
end

function ZO_ComboBox:IsDropdownVisible()
    return self.m_dropdownObject:IsOwnedByComboBox(self) and not self.m_dropdownObject:IsHidden()
end

function ZO_ComboBox:AddMenuItems()
    self.m_dropdownObject:Show(self, self.m_sortedItems, self.m_containerWidth, self.m_height, self:GetSpacing())
end

function ZO_ComboBox:ShowDropdownOnMouseUp()
    if self:IsEnabled() then
        self.m_dropdownObject:SetHidden(false)
        self:AddMenuItems()

        self:SetVisible(true)
    else
        --If we get here, that means the dropdown was disabled after the request to show it was made, so just cancel showing entirely
        self.m_container:UnregisterForEvent(EVENT_GLOBAL_MOUSE_UP)
    end
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
    self.m_container:RegisterForEvent(EVENT_GLOBAL_MOUSE_UP, function(...) self:OnGlobalMouseUp(...) end)
end

function ZO_ComboBox:HideDropdownInternal()
    self.m_container:UnregisterForEvent(EVENT_GLOBAL_MOUSE_UP)
    if self.m_dropdownObject:IsOwnedByComboBox(self) then
        self.m_dropdownObject:SetHidden(true)
    end
    self:SetVisible(false)
    if self.onHideDropdownCallback then
        self.onHideDropdownCallback()
    end
end

function ZO_ComboBox:SetHideDropdownCallback(callback)
    self.onHideDropdownCallback = callback
end

function ZO_ComboBox:SetMouseOverCallbacks(onMouseEnterCallback, onMouseExitCallback)
    self.m_container:SetHandler("OnMouseEnter", onMouseEnterCallback)
    self.m_container:SetHandler("OnMouseExit", onMouseExitCallback)
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
    if self.m_dropdownObject:IsOwnedByComboBox(self) then
        self.m_dropdownObject:Refresh()
    end
end

function ZO_ComboBox:SetNoSelectionText(text)
    self.noSelectionText = text or GetString(SI_COMBO_BOX_DEFAULT_NO_SELECTION_TEXT)
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

function ZO_ComboBox:SetEnabled(enabled)
    self.m_container:SetMouseEnabled(enabled)
    self.m_openDropdown:SetEnabled(enabled)
    self.m_selectedItemText:SetColor(self:GetSelectedTextColor(enabled))

    self:HideDropdown()
end

function ZO_ComboBox:IsEnabled()
    return self.m_openDropdown:GetState() ~= BSTATE_DISABLED
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
        return ZO_ComboBox_Base.SelectItem(self, item, ignoreCallback)
    end

    if item.enabled == false then
        return false
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
                return false
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
    if self.m_dropdownObject:IsOwnedByComboBox(self) then
        self.m_dropdownObject:Refresh(item)
    end

    return true
end

-- End ZO_ComboBox_Base overrides

-------
-- Combo Box Dropdown
-------

ZO_ComboBoxDropdown_Keyboard = ZO_InitializingObject:Subclass()

function ZO_ComboBoxDropdown_Keyboard:Initialize(control)
    self.control = control

    self.scrollControl = control:GetNamedChild("Scroll")

    self.spacing = 0
    self.nextScrollTypeId = DEFAULT_LAST_ENTRY_ID + 1

    self.owner = nil

    self:SetupScrollList()
end

function ZO_ComboBoxDropdown_Keyboard:SetupEntryLabel(labelControl, data)
    labelControl:SetText(data.name)
    labelControl:SetFont(self.owner:GetDropdownFont())
    local color = self.owner:GetItemNormalColor(data)
    labelControl:SetColor(color:UnpackRGBA())
    labelControl:SetHorizontalAlignment(self.horizontalAlignment)
end

function ZO_ComboBoxDropdown_Keyboard:SetupEntryBase(control, data, list)
    control.m_owner = self.owner
    control.m_data = data
    control.m_dropdownObject = self

    if self.owner:IsItemSelected(data:GetDataSource()) then
        if not control.m_selectionHighlight then
            control.m_selectionHighlight = CreateControlFromVirtual("$(parent)Selection", control, "ZO_ComboBoxEntry_SelectedHighlight")
        end

        control.m_selectionHighlight:SetHidden(false)
    elseif control.m_selectionHighlight then
        control.m_selectionHighlight:SetHidden(true)
    end
end

function ZO_ComboBoxDropdown_Keyboard:SetupEntry(control, data, list)
    self:SetupEntryBase(control, data, list)

    control.m_label = control:GetNamedChild("Label")
    self:SetupEntryLabel(control.m_label, data)
end

function ZO_ComboBoxDropdown_Keyboard:SetupScrollList()
    local function SetupScrollableEntry(...)
        self:SetupEntry(...)
    end
    local entryHeightWithSpacing = ZO_COMBO_BOX_ENTRY_TEMPLATE_HEIGHT + self.spacing
    -- To support spacing like regular combo boxes, a separate template needs to be stored for the last entry.
    ZO_ScrollList_AddDataType(self.scrollControl, DEFAULT_ENTRY_ID, "ZO_ComboBoxEntry", entryHeightWithSpacing, SetupScrollableEntry)
    ZO_ScrollList_AddDataType(self.scrollControl, DEFAULT_LAST_ENTRY_ID, "ZO_ComboBoxEntry", ZO_COMBO_BOX_ENTRY_TEMPLATE_HEIGHT, SetupScrollableEntry)

    ZO_ScrollList_EnableHighlight(self.scrollControl, "ZO_TallListHighlight")
end

function ZO_ComboBoxDropdown_Keyboard:AddCustomEntryTemplate(entryTemplate, entryHeight, setupFunction)
    if not self.customEntryTemplateInfos then
        self.customEntryTemplateInfos = {}
    end

    if self.customEntryTemplateInfos[entryTemplate] ~= nil then
        -- we have already added this template
        return
    end

    local customEntryInfo =
    {
        typeId = self.nextScrollTypeId,
        entryHeight = entryHeight,
    }

    self.customEntryTemplateInfos[entryTemplate] = customEntryInfo

    local entryHeightWithSpacing = entryHeight + self.spacing
    ZO_ScrollList_AddDataType(self.scrollControl, self.nextScrollTypeId, entryTemplate, entryHeightWithSpacing, setupFunction)
    ZO_ScrollList_AddDataType(self.scrollControl, self.nextScrollTypeId + 1, entryTemplate, entryHeight, setupFunction)

    self.nextScrollTypeId = self.nextScrollTypeId + 2
end

function ZO_ComboBoxDropdown_Keyboard:SetSpacing(spacing)
    self.spacing = spacing

    local newHeight = ZO_COMBO_BOX_ENTRY_TEMPLATE_HEIGHT + self.spacing
    ZO_ScrollList_UpdateDataTypeHeight(self.scrollControl, DEFAULT_ENTRY_ID, newHeight)

    if self.customEntryTemplateInfos then
        for entryTemplate, entryInfo in pairs(self.customEntryTemplateInfos) do
            ZO_ScrollList_UpdateDataTypeHeight(self.scrollControl, entryInfo.typeId, entryInfo.entryHeight + self.spacing)
        end
    end
end

function ZO_ComboBoxDropdown_Keyboard:Refresh(item)
    local entryData = nil
    if item then
        local dataList = ZO_ScrollList_GetDataList(self.scrollControl)
        for i, data in ipairs(dataList) do
            if data:GetDataSource() == item then
                entryData = data
                break
            end
        end
    end

    ZO_ScrollList_RefreshVisible(self.scrollControl, entryData)
end

function ZO_ComboBoxDropdown_Keyboard:CreateScrollableEntry(item, index, entryType)
    local entryData = ZO_EntryData:New(item)
    entryData.m_index = index
    entryData.m_owner = self.owner
    entryData.m_dropdownObject = self
    entryData:SetupAsScrollListDataEntry(entryType)
    return entryData
end

function ZO_ComboBoxDropdown_Keyboard:Show(comboBox, itemTable, minWidth, maxHeight, spacing)
    self.owner = comboBox

    local parentControl = comboBox:GetContainer()
    self.control:ClearAnchors()
    self.control:SetAnchor(TOPLEFT, parentControl, BOTTOMLEFT)

    ZO_ScrollList_Clear(self.scrollControl)

    self:SetSpacing(spacing)

    local numItems = #itemTable
    local dataList = ZO_ScrollList_GetDataList(self.scrollControl)

    local largestEntryWidth = 0
    local allItemsHeight = 0

    for i = 1, numItems do
        local item = itemTable[i]

        local isLastEntry = i == numItems
        local entryHeight = ZO_COMBO_BOX_ENTRY_TEMPLATE_HEIGHT
        local entryType = DEFAULT_ENTRY_ID
        if self.customEntryTemplateInfos and item.customEntryTemplate then
            local templateInfo = self.customEntryTemplateInfos[item.customEntryTemplate]
            if templateInfo then
                entryType = templateInfo.typeId
                entryHeight = templateInfo.entryHeight
            end
        end

        if isLastEntry then
            entryType = entryType + 1
        else
            entryHeight = entryHeight + self.spacing
        end

        allItemsHeight = allItemsHeight + entryHeight

        local entry = self:CreateScrollableEntry(item, i, entryType)
        table.insert(dataList, entry)

        local fontObject = self.owner:GetDropdownFontObject()
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
    local totalDropDownWidth = largestEntryWidth + (ZO_COMBO_BOX_ENTRY_TEMPLATE_LABEL_PADDING * 2) + ZO_SCROLL_BAR_WIDTH
    if totalDropDownWidth > minWidth then
        self.control:SetWidth(totalDropDownWidth)
    else
        self.control:SetWidth(minWidth)
    end

    -- Add padding one more time to account for potential pixel rounding issues that could cause the scroll bar to appear unnecessarily.
    allItemsHeight = allItemsHeight + (ZO_SCROLLABLE_COMBO_BOX_LIST_PADDING_Y * 2) + ZO_SCROLLABLE_COMBO_BOX_LIST_PADDING_Y

    local desiredHeight = maxHeight
    if allItemsHeight < desiredHeight then
        desiredHeight = allItemsHeight
    end

    self.control:SetHeight(desiredHeight)
    ZO_ScrollList_SetHeight(self.scrollControl, desiredHeight)

    ZO_ScrollList_Commit(self.scrollControl)
end

function ZO_ComboBoxDropdown_Keyboard:IsOwnedByComboBox(comboBox)
    return self.owner == comboBox
end

function ZO_ComboBoxDropdown_Keyboard:IsHidden()
    local isHidden = self.control:IsHidden()
    return isHidden
end

function ZO_ComboBoxDropdown_Keyboard:SetHidden(isHidden)
    self.control:SetHidden(isHidden)

    ZO_ScrollList_Clear(self.scrollControl)
    ZO_ScrollList_Commit(self.scrollControl)
end

function ZO_ComboBoxDropdown_Keyboard:IsMouseOverControl()
    return MouseIsOver(self.control)
end

function ZO_ComboBoxDropdown_Keyboard:OnMouseEnterEntry(control)
    ZO_ScrollList_MouseEnter(self.scrollControl, control)

    if self.owner then
        self.owner:OnMouseEnterEntryBase(control)
        local data = control.m_data
        self.owner:HighlightLabel(control.m_label, data)
        if data.onEnter then
            data.onEnter(control)
        end
    end
end

function ZO_ComboBoxDropdown_Keyboard:OnMouseExitEntry(control)
    ZO_ScrollList_MouseExit(self.scrollControl, control)

    if self.owner then
        self.owner:OnMouseExitEntryBase(control)
        local data = control.m_data
        self.owner:UnhighlightLabel(control.m_label, data)
        if data.onExit then
            data.onExit(control)
        end
    end
end

function ZO_ComboBoxDropdown_Keyboard:OnEntrySelected(control)
    if self.owner then
        self.owner:SetSelected(control.m_data.m_index)
    end
end

function ZO_ComboBoxDropdown_Keyboard.OnClicked(control, button, upInside)
    if button == MOUSE_BUTTON_INDEX_LEFT and upInside then
        ZO_ComboBox_OpenDropdown(control)
        PlaySound(SOUNDS.COMBO_CLICK)
    end
end

function ZO_ComboBoxDropdown_Keyboard.OnEntryMouseEnter(control)
    local dropdown = control.m_dropdownObject
    if dropdown then
        dropdown:OnMouseEnterEntry(control)
    end
end

function ZO_ComboBoxDropdown_Keyboard.OnEntryMouseExit(control)
    local dropdown = control.m_dropdownObject
    if dropdown then
        dropdown:OnMouseExitEntry(control)
    end
end

function ZO_ComboBoxDropdown_Keyboard.OnEntryMouseUp(control, button, upInside)
    if button == MOUSE_BUTTON_INDEX_LEFT and upInside then
        local dropdown = control.m_dropdownObject
        if dropdown then
            dropdown:OnEntrySelected(control)
        end
    end
end

function ZO_ComboBoxDropdown_Keyboard.InitializeFromControl(control)
    local dropdownObject = ZO_ComboBoxDropdown_Keyboard:New(control)
    control.object = dropdownObject
end