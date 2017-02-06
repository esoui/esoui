ZO_GAMEPAD_COMBO_BOX_FONT = "ZoFontGamepad27"
ZO_GAMEPAD_COMBO_BOX_HIGHLIGHTED_FONT = "ZoFontGamepad36"
ZO_GAMEPAD_COMBO_BOX_PADDING = 16

-------------------------------------------------------------------------------
-- ZO_ComboBox_Gamepad
-------------------------------------------------------------------------------

ZO_ComboBox_Gamepad = ZO_ComboBox_Base:Subclass()

function ZO_ComboBox_Gamepad:New(...)
    local object = ZO_ComboBox_Base.New(self, ...)
    return object
end

function ZO_ComboBox_Gamepad:Initialize(control)
    ZO_ComboBox_Base.Initialize(self, control)

    control.comboBoxObject = self

    self:InitializeKeybindStripDescriptors()
    self.m_active = false

    self.m_dropdown = GAMEPAD_COMBO_BOX_DROPDOWN
    self.m_focus = ZO_GamepadFocus:New(control)

    self.m_highlightedIndex = 1

    self.m_highlightColor = ZO_SELECTED_TEXT
    self.m_normalColor = ZO_DISABLED_TEXT
    
    self.m_font = ZO_GAMEPAD_COMBO_BOX_FONT
    self.m_highlightFont = ZO_GAMEPAD_COMBO_BOX_HIGHLIGHTED_FONT
    self.m_itemTemplate = "ZO_ComboBox_Item_Gamepad"

end

function ZO_ComboBox_Gamepad:ShowDropdownInternal()
    self:ClearMenuItems()

    self.m_dropdown:SetPadding(self.m_padding)

    self:AddMenuItems()

    self.m_container:SetHidden(true)
    self.m_dropdown:Show()
    self:SetVisible(true)
    self:HighlightSelectedItem()
end

function ZO_ComboBox_Gamepad:HideDropdownInternal()
    self:ClearMenuItems()
    self:SetVisible(false)
    
    self.m_container:SetHidden(false)
    self.m_dropdown:Hide()
    self:SetActive(false)
end

function ZO_ComboBox_Gamepad:OnClearItems()
    self.m_highlightedIndex = nil
end

function ZO_ComboBox_Gamepad:OnItemAdded()
    if not self.m_highlightedIndex then
        self.m_highlightedIndex = 1
    end
end

function ZO_ComboBox_Gamepad:GetNormalColor(item)
    local itemColor = item.m_normalColor or self.m_normalColor
    return itemColor
end

function ZO_ComboBox_Gamepad:GetHighlightColor(item)
    local itemColor = item.m_highlightColor or self.m_highlightColor
    return itemColor
end

function ZO_ComboBox_Gamepad:SetItemTemplate(template)
    self.m_itemTemplate = template
end

function ZO_ComboBox_Gamepad:GetHeight()
    if(self.m_selectedItemText) then
        return self.m_selectedItemText:GetTextHeight()
    end
    return self.m_container:GetHeight()
end

function ZO_ComboBox_Gamepad:AddMenuItems()
    for i = 1, #self.m_sortedItems do
        -- The variable item must be defined locally here, otherwise it won't work as an upvalue to the selection helper
        local item = self.m_sortedItems[i]
        local control = self.m_dropdown:AddItem(item)
        
        control.nameControl = control:GetNamedChild("Name")
        control.nameControl:SetText(item.name)
        control.nameControl:SetColor(self:GetNormalColor(item):UnpackRGBA())
        ApplyTemplateToControl(control, self.m_itemTemplate)

        control.nameControl:SetFont(self.m_highlightFont) -- Use the highlighted font for sizing purposes
        control.nameControl:SetWidth(self.m_container:GetWidth())
        local height = control.nameControl:GetTextHeight()
        control:SetHeight(height)
        self.m_dropdown:AddHeight(height)

        if self.m_font then
            control.nameControl:SetFont(self.m_font)
        end
        
        local focusEntry = {
            control = control,
            data = item,
            activate = function(control, data) self:OnItemSelected(control, data) end,
            deactivate = function(control, data) self:OnItemDeselected(control, data) end,
        }
        self.m_focus:AddEntry(focusEntry)
    end

    self.m_dropdown:AnchorToControl(self.m_container, 0)
end

function ZO_ComboBox_Gamepad:OnItemSelected(control, data)
    control.nameControl:SetColor(self:GetHighlightColor(data):UnpackRGBA())
    control.nameControl:SetFont(self.m_highlightFont)
    self:UpdateAnchors(control) 
end

function ZO_ComboBox_Gamepad:OnItemDeselected(control, data)
    control.nameControl:SetColor(self:GetNormalColor(data):UnpackRGBA())
    control.nameControl:SetFont(self.m_font)
end

function ZO_ComboBox_Gamepad:ClearMenuItems()
   self.m_focus:RemoveAllEntries()
   self.m_dropdown:Clear()
end

function ZO_ComboBox_Gamepad:SetActive(active)
    if self.m_active ~= active then
        self.m_active = active

        if self.m_active then
            self.m_focus:Activate()
            self.m_keybindState = KEYBIND_STRIP:PushKeybindGroupState()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor, self.m_keybindState)
        else
            self.m_focus:Deactivate()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor, self.m_keybindState)
            KEYBIND_STRIP:PopKeybindGroupState()
            
            if self.deactivatedCallback and not self.blockDeactivatedCallback then
               self.deactivatedCallback(self.deactivatedCallbackArgs)
            end
        end
    end
end

function ZO_ComboBox_Gamepad:HighlightSelectedItem()
    self:SetHighlightedItem(self.m_highlightedIndex)
end

function ZO_ComboBox_Gamepad:SelectHighlightedItem()
    local focusItem = self.m_focus:GetFocusItem()
    local focusIndex = self.m_focus:GetFocus()
    if focusIndex then
        self.m_highlightedIndex = focusIndex -- This needs to come before self:SelectItem() otherwise self.m_focus:GetFocus() always returns nil
    end

    if focusItem then
        self:SelectItem(focusItem.data)
        PlaySound(SOUNDS.DEFAULT_CLICK)
    end
   
    self:Deactivate()
end

function ZO_ComboBox_Gamepad:SelectItemByIndex(index, ignoreCallback)
    self.m_highlightedIndex = index
    ZO_ComboBox_Base.SelectItemByIndex(self, index, ignoreCallback)
end

function ZO_ComboBox_Gamepad:SetHighlightedItem(highlightIndex, reselectIndex)
    self.m_focus:SetFocusByIndex(highlightIndex, reselectIndex)
end

function ZO_ComboBox_Gamepad:TrySelectItemByData(itemData)
    for i, data in ipairs(self.m_sortedItems) do
        if data.name == itemData.name then
            self:SelectItemByIndex(i)
            return true
        end
    end
    return false
end

do
    local INCLUDE_SAVED_INDEX = true
    function ZO_ComboBox_Gamepad:GetHighlightedIndex()
        return self.m_focus:GetFocus(INCLUDE_SAVED_INDEX)
    end
end

function ZO_ComboBox_Gamepad:Activate()
    self:SetActive(true)
    ZO_ComboBox_OpenDropdown(self:GetContainer())
    PlaySound(SOUNDS.COMBO_CLICK)
end

function ZO_ComboBox_Gamepad:Deactivate(blockCallback)
    self.blockDeactivatedCallback = blockCallback
    ZO_ComboBox_HideDropdown(self:GetContainer())
    self.blockDeactivatedCallback = false
end

function ZO_ComboBox_Gamepad:IsActive()
    return self.m_active
end

function ZO_ComboBox_Gamepad:SetDeactivatedCallback(callback, args)
    self.deactivatedCallbackArgs = args
    self.deactivatedCallback = callback
end

function ZO_ComboBox_Gamepad:SetKeybindAlignment(alignment)
    self.keybindStripDescriptor.alignment = alignment
end

function ZO_ComboBox_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        
        -- since we can now have combo boxes in dialogs and in normal ui elements
        -- we want to make sure our combo box is listening for the proper keybinds
        -- based on whether or not a dialog is active
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            callback = function()
               self:Deactivate()
            end,
            visible = function() return not ZO_Dialogs_IsShowingDialog() end
        },

        {
            keybind = "DIALOG_NEGATIVE",
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            callback = function()
               self:Deactivate()
            end,
            visible = ZO_Dialogs_IsShowingDialog
        },

        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            callback = function()
                self:SelectHighlightedItem()
            end,
            visible = function() return not ZO_Dialogs_IsShowingDialog() end
        },

        {
            keybind = "DIALOG_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            callback = function()
                self:SelectHighlightedItem()
            end,
            visible = ZO_Dialogs_IsShowingDialog
        },
    }
end

function ZO_ComboBox_Gamepad:UpdateAnchors(selectedControl)
    -- The control box will always be centered on the original dropdown location
    local topItem = self.m_focus:GetItem(1)
    local topControl = topItem.control
    local offset = topControl:GetTop() - selectedControl:GetTop()

    self.m_dropdown:AnchorToControl(self.m_container, offset)
end

-------------------------------------------------------------------------------
-- ZO_GamepadComboBoxDropdown
-------------------------------------------------------------------------------

-- ZO_ComboBox_Gamepad_Dropdown is a singleton that is used by the current dropdown to display a list

ZO_GamepadComboBoxDropdown = ZO_Object:Subclass()

function ZO_GamepadComboBoxDropdown:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_GamepadComboBoxDropdown:Initialize(control)
    self.dropdownControl = control
    self.scrollControl = control:GetNamedChild("Scroll")
    self.backgroundControl = control:GetNamedChild("Background")
    self.templateName = "ZO_ComboBox_Item_Gamepad"
    self.pool = ZO_ControlPool:New(self.templateName, self.scrollControl, self.templateName)
    self.lastControlAdded = nil
    self.height = 0
    self.padding = 0
    self.borderPadding = ZO_GAMEPAD_COMBO_BOX_PADDING
    self.minY = 70
    local function RefreshMaxY()
        self.maxY = GuiRoot:GetHeight() + ZO_GAMEPAD_QUADRANT_BOTTOM_OFFSET
    end
    RefreshMaxY()
    EVENT_MANAGER:RegisterForEvent("GamepadComboBoxDropdown", EVENT_SCREEN_RESIZED, RefreshMaxY)
end

function ZO_GamepadComboBoxDropdown:SetPadding(padding)
    self.padding = padding
end

function ZO_GamepadComboBoxDropdown:Show()
    self.dropdownControl:SetHidden(false)
end

function ZO_GamepadComboBoxDropdown:Hide()
    self.dropdownControl:SetHidden(true)
end

function ZO_GamepadComboBoxDropdown:AnchorToControl(control, offsetY)
    local controlTop = control:GetTop()
    local dropDownTop = controlTop + offsetY - self.borderPadding 
    local dropDownBottom = controlTop + offsetY + self.height + self.borderPadding

    local topYDelta = 0
    if dropDownTop < self.minY then
        topYDelta = (self.minY - dropDownTop)
    end

    local bottomYDelta = 0
    if dropDownBottom > self.maxY then
        bottomYDelta = (dropDownBottom - self.maxY)
    end

    self.dropdownControl:SetAnchor(TOPLEFT, control, TOPLEFT, 0, offsetY)
    self.dropdownControl:SetDimensions(control:GetWidth(), self.height)

    local backgroundOffsetYTop = -self.borderPadding + topYDelta
    local backgroundOffsetBottomTop = self.borderPadding - bottomYDelta

    self.scrollControl:SetAnchor(TOPLEFT, self.dropdownControl, TOPLEFT, -ZO_GAMEPAD_COMBO_BOX_PADDING, backgroundOffsetYTop)
    self.scrollControl:SetAnchor(BOTTOMRIGHT, self.dropdownControl, BOTTOMRIGHT, ZO_GAMEPAD_COMBO_BOX_PADDING, backgroundOffsetBottomTop)

    self.backgroundControl:SetAnchor(TOPLEFT, self.dropdownControl, TOPLEFT, -ZO_GAMEPAD_COMBO_BOX_PADDING, backgroundOffsetYTop)
    self.backgroundControl:SetAnchor(BOTTOMRIGHT, self.dropdownControl, BOTTOMRIGHT, ZO_GAMEPAD_COMBO_BOX_PADDING, backgroundOffsetBottomTop)
end

function ZO_GamepadComboBoxDropdown:AcquireControl(item, relativeControl)
    local padding = self.padding

    local templateName = self.templateName
    local control, key = self.pool:AcquireObject()

    control:SetAnchor(RIGHT, self.m_container, RIGHT, 0, padding)

    if relativeControl then
        control:SetAnchor(TOPLEFT, relativeControl, BOTTOMLEFT, 0, padding)
    else
        control:SetAnchor(TOPLEFT, self.dropdownControl, TOPLEFT, 0, padding)
    end

    control.key = key
    control.item = item

    return control
end

function ZO_GamepadComboBoxDropdown:AddHeight(height)
    self.height = self.height + height
end

function ZO_GamepadComboBoxDropdown:AddItem(data)
    local control = self:AcquireControl(data, self.lastControlAdded)
    self.lastControlAdded = control
    return control
end

function ZO_GamepadComboBoxDropdown:Clear()
    self.pool:ReleaseAllObjects()
    self.lastControlAdded = nil
    self.height = 0
end

-- This is a control used by all gamepad combo boxes to display the dropdown
function ZO_ComboBox_Gamepad_Dropdowm_Initialize(control)
    GAMEPAD_COMBO_BOX_DROPDOWN = ZO_GamepadComboBoxDropdown:New(control)
end