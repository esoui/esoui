--
-- KeybindingsManager
--

local KeybindingsManager = ZO_InitializingObject:Subclass()
local KeybindsScrollList

function KeybindingsManager:Initialize(control)
    self.control = control
    self.chordingAlwaysEnabled = false

    self.currentKeyboardLayoutLabel = control:GetNamedChild("CurrentKeyboardLayout")
    self.currentBindingsSavedLabel = control:GetNamedChild("CurrentBindingsSaved")

    self:InitializeList()

    self.refreshGroups = ZO_Refresh:New()
    self.refreshGroups:AddRefreshGroup("KeybindingsList",
    {
        RefreshAll = function()
            self:RefreshList()
        end,
        IsShown = function() return KEYBINDINGS_FRAGMENT:IsShowing() end,
    })

    local maxCustomBinds = GetMaxNumSavedKeybindings()

    local function RefreshList()
        self.refreshGroups:RefreshAll("KeybindingsList")
        -- If we're showing we want to update immediately
        -- refresh group will determine if showing using IsShown above
        self.refreshGroups:UpdateRefreshGroups()

        local currentNumSavedBindings = GetNumSavedKeybindings()
        self.currentBindingsSavedLabel:SetText(zo_strformat(SI_KEYBINDINGS_CURRENT_SAVED_BIND_COUNT, currentNumSavedBindings, maxCustomBinds))

        local color = ZO_NORMAL_TEXT
        if currentNumSavedBindings >= maxCustomBinds then
            color = ZO_ERROR_COLOR
        end
        self.currentBindingsSavedLabel:SetColor(color:UnpackRGBA())
    end

    KEYBINDINGS_MANAGER:RegisterCallback("OnKeybindingSet", RefreshList)
    KEYBINDINGS_MANAGER:RegisterCallback("OnKeybindingCleared", RefreshList)
    KEYBINDINGS_MANAGER:RegisterCallback("OnKeybindingsLoaded", RefreshList)
    control:RegisterForEvent(EVENT_MOST_RECENT_GAMEPAD_TYPE_CHANGED, RefreshList)

    local function UpdateCurrentKeyboardLayout(currentKeyboardLayout)
        self.currentKeyboardLayoutLabel:SetText(zo_strformat(SI_KEYBIND_CURRENT_KEYBOARD_LAYOUT, currentKeyboardLayout))
    end

    KEYBINDINGS_MANAGER:RegisterCallback("OnInputLanguageChanged", UpdateCurrentKeyboardLayout)

    UpdateCurrentKeyboardLayout(GetKeyboardLayout())

    KEYBINDINGS_FRAGMENT = ZO_FadeSceneFragment:New(control)

    local function OnStateChanged(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            PushActionLayerByName("KeybindWindow")
            self.refreshGroups:UpdateRefreshGroups()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            RemoveActionLayerByName("KeybindWindow")
        end
    end
    KEYBINDINGS_FRAGMENT:RegisterCallback("StateChange", OnStateChanged)
end

function KeybindingsManager:InitializeList()
    self.list = KeybindsScrollList:New(self.control, self)
end

function KeybindingsManager:RefreshList()
    self.list:RefreshData()
end

function KeybindingsManager:SetChordingAlwaysEnabled(alwaysEnabled)
    self.chordingAlwaysEnabled = alwaysEnabled
end

function KeybindingsManager:IsChordingAlwaysEnabled()
    return self.chordingAlwaysEnabled
end

--
-- BindKeyDialog
--

local BindKeyDialog = ZO_InitializingObject:Subclass()

function BindKeyDialog:Initialize(control)
    control.owner = self
    self.control = control
    ZO_Dialogs_RegisterCustomDialog("BINDINGS", {
        customControl = function() return control end,
        setup = function(dialog, ...) self:SetupDialog(...) end,
        finishedCallback = function() self:OnDialogFinished() end,
        title =
        {
            text = SI_KEYBINDINGS_BINDINGS,
        },
        buttons =
        {
            {
                control = control.bindButton,
                text = SI_KEYBINDINGS_BIND_BUTTON,
                keybind = false,
                callback = function(dialog)
                    self:OnBindClicked()
                end,
            },

            {
                control = control.unbindButton,
                text = SI_KEYBINDINGS_UNBIND_BUTTON,
                keybind = false,
                callback = function(dialog)
                    self:OnUnbindClicked()
                end,
            },

            {
                control = control.setDefaultButton,
                text = SI_KEYBINDINGS_DEFAULT_BUTTON,
                keybind = false,
                noReleaseOnClick = true,
                callback = function(dialog)
                    self:OnDefaultClicked()
                end,
            },

            {
                control = control.cancelButton,
                text = SI_DIALOG_CANCEL,
                keybind = false,
            },
        }
    })
    BlockAutomaticInputModeChange(false) -- call to avoid a situation where this value is "stuck" after a /reloadui
end

function BindKeyDialog:OnBindClicked()
    if self:HasValidKeyToBind() then
        BindKeyToAction(self.layerIndex, self.categoryIndex, self.actionIndex, self.bindingIndex, self:GetCurrentKeys())
    else
        -- Allow for the Bind button to unbind the key if we set the current key to unbound using the Set Default button
        UnbindKeyFromAction(self.layerIndex, self.categoryIndex, self.actionIndex, self.bindingIndex)
    end
end

function BindKeyDialog:OnUnbindClicked()
    UnbindKeyFromAction(self.layerIndex, self.categoryIndex, self.actionIndex, self.bindingIndex)
end

function BindKeyDialog:OnDefaultClicked()
    self:SetCurrentKeys(self.defaultKey, self.defaultCtrl, self.defaultAlt, self.defaultShift, self.defaultCommand)
end

function BindKeyDialog:SetupDialog(data)
    self.layerIndex = data.layerIndex
    self.categoryIndex = data.categoryIndex
    self.actionIndex = data.actionIndex
    self.bindingIndex = data.bindingIndex
    
    local bindingSlotText = KEYBINDINGS_MANAGER:GetBindTypeTextFromIndex(self.bindingIndex)
    self.control.instructionsLabel:SetText(zo_strformat(SI_KEYBINDINGS_PRESS_A_KEY_OR_CLICK, ZO_SELECTED_TEXT:Colorize(bindingSlotText), ZO_SELECTED_TEXT:Colorize(data.localizedActionName)))

    local key, mod1, mod2, mod3, mod4 = GetActionBindingInfo(self.layerIndex, self.categoryIndex, self.actionIndex, self.bindingIndex)

    local ctrl = ZO_Keybindings_DoesKeyMatchAnyModifiers(KEY_CTRL, mod1, mod2, mod3, mod4)
    local alt = ZO_Keybindings_DoesKeyMatchAnyModifiers(KEY_ALT, mod1, mod2, mod3, mod4)
    local shift = ZO_Keybindings_DoesKeyMatchAnyModifiers(KEY_SHIFT, mod1, mod2, mod3, mod4)
    local command = ZO_Keybindings_DoesKeyMatchAnyModifiers(KEY_COMMAND, mod1, mod2, mod3, mod4)

    self.existingKey = key
    self.existingMod1 = mod1
    self.existingMod2 = mod2
    self.existingMod3 = mod3
    self.existingMod4 = mod4

    -- Get default before calling SetCurrentKeys so that UpdateCurrentKeyLabel has the correct info when called
    self.defaultKey, self.defaultMod1, self.defaultMod2, self.defaultMod3, self.defaultMod4 = GetActionDefaultBindingInfo(self.layerIndex, self.categoryIndex, self.actionIndex, self.bindingIndex)
    self.defaultCtrl = ZO_Keybindings_DoesKeyMatchAnyModifiers(KEY_CTRL, self.defaultMod1, self.defaultMod2, self.defaultMod3, self.defaultMod4)
    self.defaultAlt = ZO_Keybindings_DoesKeyMatchAnyModifiers(KEY_ALT, self.defaultMod1, self.defaultMod2, self.defaultMod3, self.defaultMod4)
    self.defaultShift = ZO_Keybindings_DoesKeyMatchAnyModifiers(KEY_SHIFT, self.defaultMod1, self.defaultMod2, self.defaultMod3, self.defaultMod4)
    self.defaultCommand = ZO_Keybindings_DoesKeyMatchAnyModifiers(KEY_COMMAND, self.defaultMod1, self.defaultMod2, self.defaultMod3, self.defaultMod4)

    local maxCustomBinds = GetMaxNumSavedKeybindings()
    local currentNumSavedBindings = GetNumSavedKeybindings()

    local expectedNumChangedBindingsWhenUnbound = KEYBINDINGS_MANAGER:GetNumChangedSavedKeybindingsIfUnbound(self.layerIndex, self.categoryIndex, self.actionIndex, self.bindingIndex)
    self.willUnbindExceedLimit = currentNumSavedBindings + expectedNumChangedBindingsWhenUnbound > maxCustomBinds

    local canBeUnbound = self:HasValidKeyToBind() and not self.willUnbindExceedLimit
    self.control.unbindButton:SetEnabled(canBeUnbound)

    self:SetCurrentKeys(key, ctrl, alt, shift, command)

    self.numMouseButtonsDown = 0
    self.numKeysDown = 0

    self.allowChording = KEYBINDING_MANAGER:IsChordingAlwaysEnabled() or ctrl or alt or shift or command
                             or self.defaultCtrl or self.defaultAlt or self.defaultShift or self.defaultCommand

    BlockAutomaticInputModeChange(true)
end

function BindKeyDialog:OnDialogFinished()
    BlockAutomaticInputModeChange(false)
end

function BindKeyDialog:OnMouseDown(button, ctrl, alt, shift, command)
    local mouseButtonAsKeyCode = ConvertMouseButtonToKeyCode(button)

    self.numMouseButtonsDown = self.numMouseButtonsDown + 1

    if mouseButtonAsKeyCode == KEY_MOUSE_LEFTRIGHT then
        self.forcedLmbRmb = true
        self:SetCurrentKeys(KEY_MOUSE_LEFTRIGHT, ctrl, alt, shift, command)
    elseif not self.forcedLmbRmb then
        self:SetCurrentKeys(mouseButtonAsKeyCode, ctrl, alt, shift, command)
    end
end

function BindKeyDialog:OnMouseUp(button, ctrl, alt, shift, command)
    local mouseButtonAsKeyCode = ConvertMouseButtonToKeyCode(button)
    self.numMouseButtonsDown = self.numMouseButtonsDown - 1

    if self.numMouseButtonsDown == 0 and mouseButtonAsKeyCode ~= KEY_MOUSE_LEFTRIGHT then
        self.forcedLmbRmb = false
    end
end

function BindKeyDialog:OnMouseWheel(delta, ctrl, alt, shift, command)
    local mouseWheelAsKey = delta < 0 and KEY_MOUSEWHEEL_DOWN or KEY_MOUSEWHEEL_UP
    self:SetCurrentKeys(mouseWheelAsKey, ctrl, alt, shift, command)
end

function BindKeyDialog:OnKeyDown(key, ctrl, alt, shift, command)
    if KEYBINDINGS_MANAGER:IsBindableKey(key) then
        self.numKeysDown = self.numKeysDown + 1

        if IsKeyCodeChordKey(key) then
            self.forcedComboKey = key
            self:SetCurrentKeys(key, ctrl, alt, shift, command)
        elseif not self.forcedComboKey then
            self:SetCurrentKeys(key, ctrl, alt, shift, command)
        end
    end
end

function BindKeyDialog:OnKeyUp(key, ctrl, alt, shift, command)
    if KEYBINDINGS_MANAGER:IsBindableKey(key) then
        self.numKeysDown = self.numKeysDown - 1

        if self.numKeysDown == 0 and self.forcedComboKey ~= key then
            self.forcedComboKey = nil
        end
    end
end

local function SetModifier(key, modifier, isSet)
    if isSet then
        if key == modifier then
            return KEY_INVALID
        end
        return modifier
    end
    return KEY_INVALID
end

function BindKeyDialog:SetCurrentKeys(key, ctrl, alt, shift, command)
    self.currentKey = key

    if self.allowChording then
        self.currentCtrl = SetModifier(key, KEY_CTRL, ctrl)
        self.currentAlt = SetModifier(key, KEY_ALT, alt)
        self.currentShift = SetModifier(key, KEY_SHIFT, shift)
        self.currentCommand = SetModifier(key, KEY_COMMAND, command)
    else
        self.currentCtrl = KEY_INVALID
        self.currentAlt = KEY_INVALID
        self.currentShift = KEY_INVALID
        self.currentCommand = KEY_INVALID
    end

    self:UpdateCurrentKeyLabel() 
end

function BindKeyDialog:ClearCurrentKeys()
    local NO_MODIFIER = false
    self:SetCurrentKeys(KEY_INVALID, NO_MODIFIER, NO_MODIFIER, NO_MODIFIER, NO_MODIFIER)
end

function BindKeyDialog:GetCurrentKeys()
    return self.currentKey, self.currentCtrl, self.currentAlt, self.currentShift, self.currentCommand
end

function BindKeyDialog:HasValidKeyToBind()
    return self.currentKey ~= KEY_INVALID
end

function BindKeyDialog:UpdateCurrentKeyLabel()
    local control = self.control

    -- clear the text so the dialog resizes appropriately
    control.overwriteWarning1:SetText("")
    control.overwriteWarning2:SetText("")

    local key, mod1, mod2, mod3, mod4 = self:GetCurrentKeys()

    local isCurrentKeyDefault = key == self.defaultKey and mod1 == self.defaultMod1 and mod2 == self.defaultMod2 and mod3 == self.defaultMod3 and mod4 == self.defaultMod4
    control.setDefaultButton:SetEnabled(not isCurrentKeyDefault)

    local expectedNumChangedBindings = KEYBINDINGS_MANAGER:GetNumChangedSavedKeybindings(self.layerIndex, self.categoryIndex, self.actionIndex, self.bindingIndex, key, mod1, mod2, mod3, mod4)

    local maxCustomBinds = GetMaxNumSavedKeybindings()
    local currentNumSavedBindings = GetNumSavedKeybindings()

    local willBindExceedLimit = (currentNumSavedBindings + expectedNumChangedBindings) > maxCustomBinds
    local isCurrentKeySameAsExisting = key == self.existingKey and mod1 == self.existingMod1 and mod2 == self.existingMod2 and mod3 == self.existingMod3 and mod4 == self.existingMod4
    local enableBindButton = not (willBindExceedLimit or isCurrentKeySameAsExisting)

    control.bindButton:SetEnabled(enableBindButton)

    if self:HasValidKeyToBind() then
        control.currentBindLabel:SetHidden(false)
        local bindingString = ZO_Keybindings_GetBindingStringFromKeys(key, mod1, mod2, mod3, mod4, KEYBIND_TEXT_OPTIONS_FULL_NAME, KEYBIND_TEXTURE_OPTIONS_EMBED_MARKUP)
        if ZO_Keybindings_ShouldUseIconKeyMarkup(key) then
            control.currentBindLabel:SetFont("ZoFontHeader4")
        else
            control.currentBindLabel:SetFont("ZoFontCallout")
        end
        control.currentBindLabel:SetText(bindingString)

        local showSaveLimitWarning = willBindExceedLimit or (isCurrentKeyDefault and self.willUnbindExceedLimit)

        local categoryIndex, actionIndex, bindingIndex = GetBindingIndicesFromKeys(self.layerIndex, key, mod1, mod2, mod3, mod4)
        if categoryIndex and actionIndex and bindingIndex and (self.categoryIndex ~= categoryIndex or self.actionIndex ~= actionIndex) then
            control.overwriteWarning1:SetHidden(false)

            local actionName, isRebindable, isHidden = GetActionInfo(self.layerIndex, categoryIndex, actionIndex)
            local localizedActionName = GetString(_G["SI_BINDING_NAME_"..actionName])

            if isRebindable then
                if showSaveLimitWarning then
                    control.overwriteWarning1:SetText(ZO_ERROR_COLOR:Colorize(GetString(SI_KEYBINDINGS_WOULD_EXCEED_SAVE_LIMIT)))
                else
                    local bindingSlotText = KEYBINDINGS_MANAGER:GetBindTypeTextFromIndex(bindingIndex)
                    control.overwriteWarning1:SetText(zo_strformat(SI_KEYBINDINGS_ALREADY_BOUND, ZO_SELECTED_TEXT:Colorize(bindingSlotText), ZO_SELECTED_TEXT:Colorize(localizedActionName)))
                    control.overwriteWarning2:SetText(zo_strformat(SI_KEYBINDINGS_WOULD_UNBIND, ZO_SELECTED_TEXT:Colorize(localizedActionName)))
                    control.overwriteWarning2:SetHidden(false)
                end
            else
                control.overwriteWarning1:SetText(zo_strformat(SI_KEYBINDINGS_CANNOT_BIND_TO, ZO_SELECTED_TEXT:Colorize(localizedActionName)))
                control.overwriteWarning2:SetHidden(true)
                control.bindButton:SetEnabled(false)
            end
        else
            if showSaveLimitWarning then
                control.overwriteWarning1:SetHidden(false)
                control.overwriteWarning1:SetText(ZO_ERROR_COLOR:Colorize(GetString(SI_KEYBINDINGS_WOULD_EXCEED_SAVE_LIMIT)))
            else
                control.overwriteWarning1:SetHidden(true)
            end
            control.overwriteWarning2:SetHidden(true)
        end
    else
        control.currentBindLabel:SetHidden(true)
        control.overwriteWarning1:SetHidden(true)
        control.overwriteWarning2:SetHidden(true)
    end
end

function ZO_BindKeyDialog_OnInitialized(control)
    BIND_KEY_DIALOG = BindKeyDialog:New(control)
end

--
-- KeybindsScrollList
--

KeybindsScrollList = ZO_SortFilterList:Subclass()
local LAYER_DATA_TYPE = 1
local CATEGORY_DATA_TYPE = 2
local KEYBIND_DATA_TYPE = 3

function KeybindsScrollList:New(...)
    return ZO_SortFilterList.New(self, ...)
end

local function SetBindingButtonData(button, data, bindingIndex)
    local ICON_SIZE_PERCENT = 150
    local bindingText = ZO_Keybindings_GetBindingStringFromAction(data.actionName, KEYBIND_TEXT_OPTIONS_FULL_NAME, KEYBIND_TEXTURE_OPTIONS_EMBED_MARKUP, bindingIndex, ICON_SIZE_PERCENT, ICON_SIZE_PERCENT)

    button:SetText(bindingText)

    if data.isRebindable then
        button:SetState(BSTATE_NORMAL, false)
    else
        button:SetState(BSTATE_DISABLED, true)
    end

    local isDefault = IsCurrentBindingDefault(data.actionName, bindingIndex)
    local indicatorLabel = button:GetNamedChild("Indicator")
    indicatorLabel:SetHidden(isDefault)
end

function KeybindsScrollList:Initialize(control, owner)
    ZO_SortFilterList.Initialize(self, control)
    self.owner = owner

    local function SetUpLayerHeaderEntry(control, data)
        control:SetText(data.layerName)
    end

    local function SetUpCategoryHeaderEntry(control, data)
        control:SetText(data.categoryName)
    end

    local function SetUpRowEntry(control, data)
        control.data = data

        control.actionLabel:SetText(data.localizedActionName)

        for i, bindingButton in ipairs(control.bindingButtons) do
            SetBindingButtonData(bindingButton, data, i)
        end

        ZO_SortFilterList.SetupRow(self, control, data)
    end

    ZO_ScrollList_AddDataType(self.list, LAYER_DATA_TYPE, "ZO_KeybindingListLayerHeader", 60, SetUpLayerHeaderEntry)
    ZO_ScrollList_AddDataType(self.list, CATEGORY_DATA_TYPE, "ZO_KeybindingListCategoryHeader", 48, SetUpCategoryHeaderEntry)
    ZO_ScrollList_AddDataType(self.list, KEYBIND_DATA_TYPE, "ZO_KeybindingListRow", 36, SetUpRowEntry)
end

function KeybindsScrollList:SortScrollList()
    -- no sorting, use the order defined in xml
end

function KeybindsScrollList:BuildMasterList()
    self.masterList = {}
    local masterList = self.masterList

    local keybindData = KEYBINDINGS_MANAGER:GetKeybindData()

    for _, layerData in ipairs(keybindData) do
        masterList[#masterList + 1] = ZO_ScrollList_CreateDataEntry(LAYER_DATA_TYPE, layerData)
        for _, categoryData in ipairs(layerData.categories) do
            if categoryData.categoryName ~= "" then
                masterList[#masterList + 1] = ZO_ScrollList_CreateDataEntry(CATEGORY_DATA_TYPE, categoryData)
            end
            for _, action in ipairs(categoryData.actions) do
                masterList[#masterList + 1] = ZO_ScrollList_CreateDataEntry(KEYBIND_DATA_TYPE, action)
            end
        end
    end

end

function KeybindsScrollList:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ScrollList_Clear(self.list)

    for i, data in ipairs(self.masterList) do
        scrollData[#scrollData + 1] = data
    end
end

----
-- Global XML Function
----

function ZO_KeybindingListButton_OnClicked(control)
    local actionData = control:GetParent().data:GetDataSource()
    local dialogData = ZO_ShallowTableCopy(actionData)
    dialogData.bindingIndex = control.bindingIndex
    ZO_Dialogs_ShowDialog("BINDINGS", dialogData)
end

function ZO_Keybindings_OnInitialize(control)
    KEYBINDING_MANAGER = KeybindingsManager:New(control)
end