ZO_HUD_EDITOR_KEYBOARD_INFO_BOX_INTERACTABLE_ELEMENT_LEVEL = 15

------------------------
-- ZO_HUDEditor_Keyboard
------------------------
local NO_SUBKEY = nil

--TODO Custom HUD: Does this actually need to be a callback object?
ZO_HUDEditor_Keyboard = ZO_InitializingCallbackObject:Subclass()

--TODO Custom HUD: Find a way to suppress pop up dialogs (like queue dialogs) while this screen is up
function ZO_HUDEditor_Keyboard:Initialize(control)
    self.control = control
    self.infoBox = control:GetNamedChild("InfoBox")
    self.infoBoxCustomOptionsContainer = self.infoBox:GetNamedChild("CustomOptions")
    self.infoBoxSelector = self.infoBox:GetNamedChild("HeaderSelector")
    self.infoBoxSelectorDropdown = ZO_ComboBox_ObjectFromContainer(self.infoBoxSelector)

    local infoBoxCoordinates = self.infoBox:GetNamedChild("Coordinates")
    self.infoBoxXCoordsEditBox = infoBoxCoordinates:GetNamedChild("XCoordsBackdropEdit")
    self.infoBoxYCoordsEditBox = infoBoxCoordinates:GetNamedChild("YCoordsBackdropEdit")

    self.infoBoxXCoordsEditBox:SetHandler("OnFocusLost", function() self:ApplyInfoBoxValues() end)
    self.infoBoxYCoordsEditBox:SetHandler("OnFocusLost", function() self:ApplyInfoBoxValues() end)

    self.elementControls = {}
    self.infoBoxCustomOptionControls = {}

    HUD_EDITOR_SCENE_KEYBOARD = ZO_Scene:New("hud_editor_keyboard", SCENE_MANAGER)
    HUD_EDITOR_SCENE_KEYBOARD:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_SHOWN then
            self:OnShown()
        elseif newState == SCENE_HIDING then
            self:OnHiding()
        elseif newState == SCENE_HIDDEN then
            self:OnHidden()
        end
    end)

    SYSTEMS:RegisterKeyboardRootScene("hudEditor", HUD_EDITOR_SCENE_KEYBOARD)
    SYSTEMS:RegisterGamepadRootScene("hudEditor", HUD_EDITOR_SCENE_KEYBOARD) -- TODO Custom HUD: Gamepad screen

    self:InitializeControlPools()

    self.control:SetHandler("OnMouseUp", function(_, button, upInside)
        if button == MOUSE_BUTTON_INDEX_LEFT and upInside then
            self:DeselectElements()
        end
    end)

    HUD_MANAGER:RegisterCallback("PropagateSettings", function() self:RefreshAllElements() end)
    HUD_MANAGER:RegisterCallback("RebuildAllElements", function() self:RebuildAllElements() end)
end

function ZO_HUDEditor_Keyboard:OnShowing()
    self.control:SetHidden(false)
    if ZO_ChatWindow then
        self.oldChatWindowTier = ZO_ChatWindow:GetDrawTier()
        self.oldChatWindowLevel = ZO_ChatWindow:GetDrawLevel()
        ZO_ChatWindow:SetDrawTier(DT_HIGH)
        ZO_ChatWindow:SetDrawLevel(1)
    end
    self:PopulateElementControls()
    HUD_MANAGER:OnEditorShowing()
end

function ZO_HUDEditor_Keyboard:OnShown()
    TriggerTutorial(TUTORIAL_TRIGGER_HUD_EDITOR_OPENED)
end

function ZO_HUDEditor_Keyboard:OnHiding()
    HUD_MANAGER:OnEditorHiding()

    self.control:SetHidden(true)
    self.customizableElementControlPool:ReleaseAllObjects()
    ZO_ClearNumericallyIndexedTable(self.elementControls)
    self:SetSelectedElement(nil)
end

function ZO_HUDEditor_Keyboard:OnHidden()
    if ZO_ChatWindow then
        ZO_ChatWindow:SetDrawTier(self.oldChatWindowTier)
        ZO_ChatWindow:SetDrawLevel(self.oldChatWindowLevel)
    end
end

function ZO_HUDEditor_Keyboard:IsShowing()
    return HUD_EDITOR_SCENE_KEYBOARD:IsShowing()
end

function ZO_HUDEditor_Keyboard:RefreshAllElements()
    if self:IsShowing() then
        for _, elementControl in ipairs(self.elementControls) do
            elementControl.object:RefreshAnchors()
        end
        self:RefreshInfoBox()
    end
end

function ZO_HUDEditor_Keyboard:RebuildAllElements()
    if self:IsShowing() and not self.isRebuilding then
        self.isRebuilding = true

        local previousSelectedElement = self:GetSelectedElement()
        local previousSelectedElementData = nil
        if previousSelectedElement then
            previousSelectedElementData = previousSelectedElement:GetElementData()
        end
        self.customizableElementControlPool:ReleaseAllObjects()
        self:SetSelectedElement(nil)

        self:PopulateElementControls(previousSelectedElementData)

        self.isRebuilding = false
    end
end

function ZO_HUDEditor_Keyboard:PopulateElementControls(dataToSelect)
    ZO_ClearNumericallyIndexedTable(self.elementControls)
    local iterator = IsInGamepadPreferredMode() and HUD_MANAGER.GamepadElementIterator or HUD_MANAGER.KeyboardElementIterator
    local objectToSelect = nil

    for _, elementData in iterator(HUD_MANAGER, { ZO_HUDManager_Element.IsValid }) do
        local element = self.customizableElementControlPool:AcquireObject()
        element.object:AssignElementData(elementData)
        table.insert(self.elementControls, element)
        if elementData == dataToSelect then
            objectToSelect = element.object
        end
    end

    --Sort the element controls alphabetically
    table.sort(self.elementControls, function(left, right)
        local leftData = left.object:GetElementData()
        local rightData = right.object:GetElementData()

        return leftData:GetDisplayName() < rightData:GetDisplayName()
    end)

    --Attempt to reselect the previously selected object if it was found
    if objectToSelect then
        objectToSelect:Select()
    end
end

function ZO_HUDEditor_Keyboard:DeselectElements()
    for _, element in ipairs(self.elementControls) do
        element.object:Deselect()
    end
end

function ZO_HUDEditor_Keyboard:SetSelectedElement(element)
    self.selectedElement = element
    self:RefreshInfoBox()
end

function ZO_HUDEditor_Keyboard:GetSelectedElement()
    return self.selectedElement
end

do
    local function OnElementSelectorDropdownEntryMouseEnter(control)
        control.m_data.object:OnMouseEnter()
    end

    local function OnElementSelectorDropdownEntryMouseExit(control)
        control.m_data.object:OnMouseExit()
    end

    function ZO_HUDEditor_Keyboard:RefreshInfoBox()
        self.infoBoxCheckButtonControlPool:ReleaseAllObjects()
        self.infoBoxDropdownControlPool:ReleaseAllObjects()
        ZO_ClearNumericallyIndexedTable(self.infoBoxCustomOptionControls)
        ZO_Dialogs_ReleaseAllDialogsOfName("HUD_EDITOR_RESET_ALL_POSITIONS_CONFIRMATION")

        local selectedElement = self:GetSelectedElement()
        if selectedElement then
            --Populate the element selector dropdown
            self.infoBoxSelectorDropdown:ClearItems()
            local selectedEntry = nil
            for _, element in ipairs(self.elementControls) do
                local elementName = element.object:GetElementData():GetDisplayName()
                local elementEntry = self.infoBoxSelectorDropdown:CreateItemEntry(elementName, function(comboBox, entryText, entry) entry.object:Select() end)
                elementEntry.object = element.object
                if selectedElement  == elementEntry.object then
                    selectedEntry = elementEntry
                end
                self.infoBoxSelectorDropdown:SetItemOnEnter(elementEntry, OnElementSelectorDropdownEntryMouseEnter)
                self.infoBoxSelectorDropdown:SetItemOnExit(elementEntry, OnElementSelectorDropdownEntryMouseExit)

                self.infoBoxSelectorDropdown:AddItem(elementEntry, ZO_COMBOBOX_SUPPRESS_UPDATE)
            end
        
            --Make sure the selected entry in the dropdown matches the currently selected element
            local IGNORE_CALLBACK = true
            if selectedEntry then
                self.infoBoxSelectorDropdown:SelectItem(selectedEntry, IGNORE_CALLBACK)
            else
                --In theory there should always be a selected entry, but have this as a fallback just in case
                self.infoBoxSelectorDropdown:SelectFirstItem()
            end

            local PRE_CHECKS_PADDING = 5
            local POST_CHECKS_PADDING = 8

            --Layout any custom options the selected element might have
            local customOptions = selectedElement:GetCustomOptions()
            if customOptions then
                local previousCustomOption
                for _, optionData in ipairs(customOptions) do
                    if ZO_EvalDefaultTrue(optionData.isValid, selectedElement) then
                        if optionData.type == ZO_HUD_EDITOR_OPTION_TYPES.BOOLEAN then
                            local checkButton = self.infoBoxCheckButtonControlPool:AcquireObject()
                            checkButton.optionData = optionData
                            ZO_CheckButton_SetLabelText(checkButton, optionData.name)
                            ZO_CheckButton_SetCheckState(checkButton, selectedElement:GetCustomOptionValue(optionData.key))

                            if previousCustomOption then
                                local extraPadding = previousCustomOption.isCheck and 0 or PRE_CHECKS_PADDING
                                checkButton:SetAnchor(TOPLEFT, previousCustomOption, BOTTOMLEFT, 0, 10 + extraPadding)
                            else
                                checkButton:SetAnchor(TOPLEFT, nil, nil, 0, 0)
                            end

                            local enabled = ZO_EvalDefaultTrue(optionData.enabled)
                            ZO_CheckButton_SetEnableState(checkButton, enabled)

                            if optionData.tooltipText then
                                ZO_CheckButton_SetTooltipEnabledState(checkButton, true)
                                ZO_CheckButton_SetTooltipText(checkButton, optionData.tooltipText)
                            else
                                ZO_CheckButton_SetTooltipEnabledState(checkButton, false)
                            end

                            ZO_CheckButton_SetToggleFunction(checkButton, function(button, checked)
                                self:ApplyInfoBoxValues(selectedElement)
                                --TODO Custom HUD: Add something to option data to specify if we need a rebuild or not
                                self:RebuildAllElements()
                            end)

                            previousCustomOption = checkButton
                            table.insert(self.infoBoxCustomOptionControls, checkButton)
                        elseif optionData.type == ZO_HUD_EDITOR_OPTION_TYPES.MULTI_SELECT_DROPDOWN then
                            local dropdownControl = self.infoBoxDropdownControlPool:AcquireObject()
                            local dropdown = ZO_ComboBox_ObjectFromContainer(dropdownControl:GetNamedChild("ComboBox"))
                            dropdownControl:GetNamedChild("Name"):SetText(optionData.name)
                            dropdownControl.optionData = optionData

                            if previousCustomOption then
                                local extraPadding = previousCustomOption.isCheck and POST_CHECKS_PADDING or 0
                                dropdownControl:SetAnchor(TOPLEFT, previousCustomOption, BOTTOMLEFT, 0, 10 + extraPadding)
                            else
                                dropdownControl:SetAnchor(TOPLEFT, nil, nil, 0, 0)
                            end

                            dropdown:EnableMultiSelect()
                            dropdown:SetSortsItems(true)
                            dropdown:SetNoSelectionText(GetString(SI_HUD_EDITOR_CUSTOM_OPTION_MULTI_SELECT_NO_SELECTION_TEXT))
                            dropdown:SetMultiSelectionTextFormatter(SI_HUD_EDITOR_CUSTOM_OPTION_MULTI_SELECT_FORMATTER)
                            dropdown:ClearItems()

                            --Populate the dropdown with the option data values
                            for _, valueData in ipairs(optionData.values) do
                                if ZO_EvalDefaultTrue(valueData.isValid, selectedElement) then
                                    local displayName = ZO_Eval(valueData.displayName)
                                    local valueEntry = dropdown:CreateItemEntry(displayName)
                                    valueEntry.data = valueData

                                    dropdown:AddItem(valueEntry, ZO_COMBOBOX_SUPPRESS_UPDATE)
                                    if selectedElement:GetCustomOptionValue(optionData.key, valueData.key) then
                                        dropdown:SelectItem(valueEntry, IGNORE_CALLBACK)
                                    end
                                end
                            end

                            dropdown:UpdateItems()

                            local function OnDropdownHidden()
                                self:ApplyInfoBoxValues(selectedElement)
                                --TODO Custom HUD: Add something to option data to specify if we need a rebuild or not
                                self:RebuildAllElements()
                            end
                            dropdown:SetHideDropdownCallback(OnDropdownHidden)

                            previousCustomOption = dropdownControl
                            table.insert(self.infoBoxCustomOptionControls, dropdownControl)
                        elseif optionData.type == ZO_HUD_EDITOR_OPTION_TYPES.ENUM then
                            local dropdownControl = self.infoBoxDropdownControlPool:AcquireObject()
                            local dropdown = ZO_ComboBox_ObjectFromContainer(dropdownControl:GetNamedChild("ComboBox"))
                            dropdownControl:GetNamedChild("Name"):SetText(optionData.name)
                            dropdownControl.optionData = optionData

                            if previousCustomOption then
                                local extraPadding = previousCustomOption.isCheck and POST_CHECKS_PADDING or 0
                                dropdownControl:SetAnchor(TOPLEFT, previousCustomOption, BOTTOMLEFT, 0, 10 + extraPadding)
                            else
                                dropdownControl:SetAnchor(TOPLEFT, nil, nil, 0, 0)
                            end

                            dropdown:DisableMultiSelect()
                            dropdown:ClearItems()
                            dropdown:SetSortsItems(false)

                            --Populate the dropdown with the option data values
                            for i, value in ipairs(optionData.values) do
                                local displayName = GetString(optionData.valueStringPrefix, value)
                                local valueEntry = dropdown:CreateItemEntry(displayName)
                                valueEntry.value = value
                                if optionData.valueTooltips then
                                    valueEntry.tooltip = optionData.valueTooltips[i]
                                end
                                dropdown:AddItem(valueEntry, ZO_COMBOBOX_SUPPRESS_UPDATE)
                                if selectedElement:GetCustomOptionValue(optionData.key) == value then
                                    dropdown:SelectItem(valueEntry, IGNORE_CALLBACK)
                                end
                            end

                            dropdown:UpdateItems()

                            local function OnDropdownHidden()
                                self:ApplyInfoBoxValues(selectedElement)
                                --TODO Custom HUD: Add something to option data to specify if we need a rebuild or not
                                self:RebuildAllElements()
                            end
                            dropdown:SetHideDropdownCallback(OnDropdownHidden)

                            local selectedItemData = dropdown:GetSelectedItemData()
                            if selectedItemData.tooltip and selectedItemData.tooltip ~= "" then
                                dropdownControl.warningIcon:SetHidden(false)
                            else
                                dropdownControl.warningIcon:SetHidden(true)
                            end

                            previousCustomOption = dropdownControl
                            table.insert(self.infoBoxCustomOptionControls, dropdownControl)
                        end
                    end
                end
            end

            local offsetX, offsetY = selectedElement:GetRoundedOffsetsFromTopLeft()
            self.infoBoxXCoordsEditBox:SetText(offsetX)
            self.infoBoxYCoordsEditBox:SetText(offsetY)

            --Hide the info box while the selected element is actively being dragged
            self.infoBox:SetHidden(selectedElement:IsDragging())
        else
            self.infoBox:SetHidden(true)
        end
    end
end

function ZO_HUDEditor_Keyboard:SelectNext()
    local selectedElement = self:GetSelectedElement()
    if selectedElement then
        local selectedIndex = ZO_IndexOfElementInNumericallyIndexedTable(self.elementControls, selectedElement:GetControl())
        local nextElementIndex = selectedIndex + 1
        if nextElementIndex <= #self.elementControls then
            self.elementControls[nextElementIndex].object:Select()
        else
            self.elementControls[1].object:Select()
        end
    end
end

function ZO_HUDEditor_Keyboard:SelectNextMouseOver()
    local selectedElement = self:GetSelectedElement()
    if selectedElement then
        local selectedIndex = ZO_IndexOfElementInNumericallyIndexedTable(self.elementControls, selectedElement:GetControl())
        local nextElementIndex = selectedIndex + 1
        local cursorPositionX, cursorPositionY = GetUIMousePosition()
        for i = selectedIndex + 1, #self.elementControls do
            local control = self.elementControls[i]
            if control:IsPointInside(cursorPositionX, cursorPositionY) then
                control.object:Select()
                return true
            end
        end

        for i = 1, selectedIndex - 1 do
            local control = self.elementControls[i]
            if control:IsPointInside(cursorPositionX, cursorPositionY) then
                control.object:Select()
                return true
            end
        end

        return false
    end
end

function ZO_HUDEditor_Keyboard:SelectPrevious()
    local selectedElement = self:GetSelectedElement()
    if selectedElement then
        local selectedIndex = ZO_IndexOfElementInNumericallyIndexedTable(self.elementControls, selectedElement:GetControl())
        local previousElementIndex = selectedIndex - 1
        if previousElementIndex > 0 then
            self.elementControls[previousElementIndex].object:Select()
        else
            self.elementControls[#self.elementControls].object:Select()
        end
    end
end

function ZO_HUDEditor_Keyboard:ResetSelectedToDefault()
    local selectedElement = self:GetSelectedElement()
    selectedElement:ResetToDefault()
    self:RefreshInfoBox()
end

function ZO_HUDEditor_Keyboard:ResetAllToDefault()
    --TODO Custom HUD: Determine if we need this logic or if we're just gonna split the keyboard and gamepad editors completely
    local iterator = IsInGamepadPreferredMode() and HUD_MANAGER.GamepadElementIterator or HUD_MANAGER.KeyboardElementIterator
    for _, elementData in iterator(HUD_MANAGER) do
        elementData:ResetToDefaultAnchor()
    end
    self:RefreshAllElements()
end

function ZO_HUDEditor_Keyboard:ApplyInfoBoxValues(overrideElement)
    local selectedElement = overrideElement or self:GetSelectedElement()
    if selectedElement and selectedElement:IsValid() then
        local offsetX = tonumber(self.infoBoxXCoordsEditBox:GetText())
        local offsetY = tonumber(self.infoBoxYCoordsEditBox:GetText())
        selectedElement:SetPositionFromTopLeft(offsetX, offsetY)

        for _, optionControl in ipairs(self.infoBoxCustomOptionControls) do
            local optionData = optionControl.optionData
            if optionData then
                local optionType = optionData.type
                if optionType == ZO_HUD_EDITOR_OPTION_TYPES.BOOLEAN then
                    selectedElement:SetCustomOptionValue(optionData.key, NO_SUBKEY, ZO_CheckButton_IsChecked(optionControl))
                elseif optionType == ZO_HUD_EDITOR_OPTION_TYPES.MULTI_SELECT_DROPDOWN then
                    local dropdown = ZO_ComboBox_ObjectFromContainer(optionControl:GetNamedChild("ComboBox"))
                    for _, item in ipairs(dropdown:GetItems()) do
                        selectedElement:SetCustomOptionValue(optionData.key, item.data.key, dropdown:IsItemSelected(item))
                    end
                elseif optionType == ZO_HUD_EDITOR_OPTION_TYPES.ENUM then
                    local dropdown = ZO_ComboBox_ObjectFromContainer(optionControl:GetNamedChild("ComboBox"))
                    local selectedItemData = dropdown:GetSelectedItemData()
                    selectedElement:SetCustomOptionValue(optionData.key, NO_SUBKEY, selectedItemData.value)
                end
            end
        end

        self:RefreshInfoBox()
    end
end

function ZO_HUDEditor_Keyboard:InitializeControlPools()
    self.customizableElementControlPool = ZO_ControlPool:New("ZO_CustomizableHUDElement_Keyboard", self.control, "HUDElement")
    self.customizableElementControlPool:SetCustomResetBehavior(function(control)
        control.object:Reset()
    end)

    self.infoBoxCheckButtonControlPool = ZO_ControlPool:New("ZO_HUDInfoBoxCheckButton_Keyboard", self.infoBoxCustomOptionsContainer, "CheckButton")
    self.infoBoxCheckButtonControlPool:SetCustomFactoryBehavior(function(control)
        control.isCheck = true
    end)
    self.infoBoxCheckButtonControlPool:SetCustomResetBehavior(function(control)
        control:SetHidden(true)
        control:ClearAnchors()
        control.optionData = nil
    end)

    local function InfoBoxDropdownOnMouseEnter(control)
        if control.optionData and control.optionData.tooltipText then
            InitializeTooltip(InformationTooltip, control, RIGHT, -5, 0, LEFT)
            SetTooltipText(InformationTooltip, control.optionData.tooltipText)
        end
    end

    local function InfoBoxDropdownOnMouseExit(control)
        ClearTooltip(InformationTooltip)
    end

    local function InfoBoxWarningIconOnMouseEnter(control)
        local dropdown = ZO_ComboBox_ObjectFromContainer(control:GetNamedSibling("ComboBox"))
        local selectedItemData = dropdown:GetSelectedItemData()

        if selectedItemData and selectedItemData.tooltip and selectedItemData.tooltip ~= "" then
            InitializeTooltip(InformationTooltip, control, RIGHT, -5, 0, LEFT)
            SetTooltipText(InformationTooltip, selectedItemData.tooltip)
        end
    end

    local function InfoBoxWarningIconOnMouseExit(control)
        ClearTooltip(InformationTooltip)
    end

    self.infoBoxDropdownControlPool = ZO_ControlPool:New("ZO_HUDInfoBoxDropdown_Keyboard", self.infoBoxCustomOptionsContainer, "Dropdown")
    self.infoBoxDropdownControlPool:SetCustomFactoryBehavior(function(control)
        control:SetHandler("OnMouseEnter", InfoBoxDropdownOnMouseEnter)
        control:SetHandler("OnMouseExit", InfoBoxDropdownOnMouseExit)

        control.warningIcon = control:GetNamedChild("WarningIcon")
        control.warningIcon:SetHandler("OnMouseEnter", InfoBoxWarningIconOnMouseEnter)
        control.warningIcon:SetHandler("OnMouseExit", InfoBoxWarningIconOnMouseExit)
    end)

    self.infoBoxDropdownControlPool:SetCustomResetBehavior(function(control)
        local dropdown = ZO_ComboBox_ObjectFromContainer(control:GetNamedChild("ComboBox"))
        dropdown:DisableMultiSelect()
        control:SetHidden(true)
        control:ClearAnchors()
        control.optionData = nil
        control.warningIcon:SetHidden(true)
    end)
end

function ZO_HUDEditor_Keyboard.OnControlInitialized(control)
    HUD_EDITOR_KEYBOARD = ZO_HUDEditor_Keyboard:New(control)
end

-----------------------------
-- ZO_HUDEditorElement_Keyboard
-----------------------------

ZO_HUD_EDITOR_ELEMENT_COLORS_KEYBOARD =
{
    selected =
    {
        edge = ZO_ColorDef:New("2002FF"),
        centerNormal = ZO_ColorDef:New("202002FF"),
        centerHover = ZO_ColorDef:New("502002FF"),
        font = ZO_WHITE,
    },
    unselected =
    {
        edge = ZO_ColorDef:New("02E1FF"),
        centerNormal = ZO_ColorDef:New("2002E1FF"),
        centerHover = ZO_ColorDef:New("5002E1FF"),
        font = ZO_ColorDef:New("02E1FF")
    }
}

--TODO Custom HUD: Figure out how much of this can be shared with gamepad
ZO_HUDEditorElement_Keyboard = ZO_InitializingCallbackObject:Subclass()

function ZO_HUDEditorElement_Keyboard:Initialize(control)
    control.object = self
    self.control = control
    self.nameControl = control:GetNamedChild("Name")
    self.selected = false
end

function ZO_HUDEditorElement_Keyboard:AssignElementData(data)
    self.elementData = data
    self.refControl = self.elementData:GetControl()

    self.control:SetDrawLevel(self.elementData:GetDrawLevel())

    self:RefreshAnchors()
    self.refControl:SetHandler("OnRectChanged", function()
        if not self.control:IsHidden() then
            self:RefreshAnchors()
        end
    end)

    self.nameControl:SetText(self.elementData:GetDisplayName())
end

function ZO_HUDEditorElement_Keyboard:GetElementData()
    return self.elementData
end

function ZO_HUDEditorElement_Keyboard:GetControl()
    return self.control
end

function ZO_HUDEditorElement_Keyboard:RefreshAnchors()
    self.control:ClearAnchors()

    local primaryAnchorPoint, refOffsetX, refOffsetY, refWidth, refHeight = self.elementData:GetConvertedRefControlAnchorInfo()
    self.primaryAnchorPoint = primaryAnchorPoint
    self.control:SetAnchor(primaryAnchorPoint, nil, nil, refOffsetX, refOffsetY)
    self.control:SetDimensions(refWidth, refHeight)
end

function ZO_HUDEditorElement_Keyboard:RefreshColors()
    local colors = self.selected and ZO_HUD_EDITOR_ELEMENT_COLORS_KEYBOARD.selected or ZO_HUD_EDITOR_ELEMENT_COLORS_KEYBOARD.unselected

    self.control:SetEdgeColor(colors.edge:UnpackRGBA())
    self.nameControl:SetColor(colors.font:UnpackRGBA())
    -- TODO Custom HUD: When we implement the gamepad HUD editor, we'll want to start by sharing this constant
    -- And then evaluate to see if we want different constants
    local forceNameHidden = self.nameControl:GetWidth() <= 50

    if self.mouseOver then
        self.nameControl:SetHidden(forceNameHidden)
        self.control:SetCenterColor(colors.centerHover:UnpackRGBA())
    else
        self.nameControl:SetHidden(forceNameHidden or not self.selected)
        self.control:SetCenterColor(colors.centerNormal:UnpackRGBA())
    end
end

function ZO_HUDEditorElement_Keyboard:ApplyChanges()
    local offsetX, offsetY = ZO_GetControlPointOffsetFromGuiRoot(self.control, self.primaryAnchorPoint)
    self.elementData:ApplyOffset(offsetX, offsetY)
end

function ZO_HUDEditorElement_Keyboard:GetRoundedOffsetsFromTopLeft()
    return zo_round(self.control:GetLeft()), zo_round(self.control:GetTop())
end

function ZO_HUDEditorElement_Keyboard:SetPositionFromTopLeft(offsetX, offsetY)
    self.control:ClearAnchors()
    self.control:SetAnchor(TOPLEFT, nil, nil, offsetX, offsetY)
    self:ApplyChanges()
end

function ZO_HUDEditorElement_Keyboard:SetCustomOptionValue(key, subKey, value)
    self.elementData:SetCustomOptionValue(key, subKey, value)
end

function ZO_HUDEditorElement_Keyboard:GetCustomOptionValue(key, subKey)
    return self.elementData:GetCustomOptionValue(key, subKey)
end


function ZO_HUDEditorElement_Keyboard:Deselect()
    self.selected = false
    --Return the element to its normal draw level when deselected
    self.control:SetDrawLevel(self.elementData:GetDrawLevel())
    self:RefreshColors()
    if HUD_EDITOR_KEYBOARD:GetSelectedElement() == self then
        HUD_EDITOR_KEYBOARD:SetSelectedElement(nil)
    end
end

function ZO_HUDEditorElement_Keyboard:Select()
    --Order matters. Deselect elements before setting self.selected and refreshing the colors
    HUD_EDITOR_KEYBOARD:DeselectElements()
    self.selected = true
    --Make it so the currently selected element is drawn above other elements
    self.control:SetDrawLevel(ZO_HUD_EDITOR_ELEMENT_DRAW_LEVELS.SELECTED)
    HUD_EDITOR_KEYBOARD:SetSelectedElement(self)
    self:RefreshColors()
end

function ZO_HUDEditorElement_Keyboard:IsSelected()
    return self.selected
end

function ZO_HUDEditorElement_Keyboard:IsValid()
    return self.elementData ~= nil
end

function ZO_HUDEditorElement_Keyboard:IsDragging()
    return self.dragging
end

function ZO_HUDEditorElement_Keyboard:GetCustomOptions()
    return self.elementData:GetCustomOptions()
end

function ZO_HUDEditorElement_Keyboard:Reset()
    self.elementData = nil
    self.selected = false
    self.mouseOver = false
    self.primaryAnchorPoint = nil
    self.refControl:SetHandler("OnRectChanged", nil)
    self.refControl = nil
    self.control:SetHidden(true)
    self.nameControl:SetHidden(true)
    self.control:ClearAnchors()

    self:RefreshColors()
end

function ZO_HUDEditorElement_Keyboard:ResetToDefault()
    self.elementData:ResetToDefaultAnchor()
    self:RefreshAnchors()
end

function ZO_HUDEditorElement_Keyboard:OnMouseEnter(control)
    self.mouseOver = true
    self:RefreshColors()
end

function ZO_HUDEditorElement_Keyboard:OnMouseExit(control)
    self.mouseOver = false
    self:RefreshColors()
end

function ZO_HUDEditorElement_Keyboard:OnMouseUp(control, button, upInside)
    --If there is no element data then the element is not currently active
    if self.elementData then
        if button == MOUSE_BUTTON_INDEX_LEFT then
            if upInside and not self.dragging then
                if not (self.selected and HUD_EDITOR_KEYBOARD:SelectNextMouseOver()) then
                    self:Select()
                end
            end

            --If we just finished dragging, apply the changes
            if self.dragging then
                self:ApplyChanges()
            end

            self.dragging = false
            self.control:StopMovingOrResizing()
            self.control:SetMovable(false)
            HUD_EDITOR_KEYBOARD:RefreshInfoBox()
        end
    end
end

function ZO_HUDEditorElement_Keyboard:OnDragStart(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        self.control:SetMovable(true)
        self.control:StartMoving()
        self.dragging = true
        self:Select()
    end
end