function ZO_Keybindings_DoesKeyMatchAnyModifiers(modifierKeyToMatch, mod1, mod2, mod3, mod4)
    return mod1 == modifierKeyToMatch 
        or mod2 == modifierKeyToMatch 
        or mod3 == modifierKeyToMatch
        or mod4 == modifierKeyToMatch
end

local function DoesKeyBindMatchInput(keyId, mod1, mod2, mod3, mod4, key, ctrl, alt, shift, command)
    local bindingCtrl = ZO_Keybindings_DoesKeyMatchAnyModifiers(KEY_CTRL, mod1, mod2, mod3, mod4)
    local bindingAlt = ZO_Keybindings_DoesKeyMatchAnyModifiers(KEY_ALT, mod1, mod2, mod3, mod4)
    local bindingShift = ZO_Keybindings_DoesKeyMatchAnyModifiers(KEY_SHIFT, mod1, mod2, mod3, mod4)
    local bindingCommand = ZO_Keybindings_DoesKeyMatchAnyModifiers(KEY_COMMAND, mod1, mod2, mod3, mod4)

    if key == KEY_CTRL and ctrl then ctrl = false end
    if key == KEY_ALT and alt then alt = false end
    if key == KEY_SHIFT and shift then shift = false end
    if key == KEY_COMMAND and command then command = false end

    return keyId == key and bindingCtrl == ctrl and bindingAlt == alt and bindingShift == shift and bindingCommand == command
end

--[[
    This function performs binding matching based on key inputs.
    The checks are a little convoluted:
    1. Base keys need to match
    2. mod1, 2, 3 and 4 come in in some arbitrary order, so they have to get mapped properly to match the arguments that are passed to OnKeyDown
    3. If the base keypress is a modifier key, the appropriate modifier needs to be turned off for this keypress; because bindings like Ctrl+Ctrl make no sense.
--]]

function ZO_Keybindings_DoesActionMatchInput(actionName, key, ctrl, alt, shift, command)
    local layerIndex, categoryIndex, actionIndex = GetActionIndicesFromName(actionName)
    if layerIndex then
        local keyId1, mod1, mod2, mod3, mod4 = GetActionBindingInfo(layerIndex, categoryIndex, actionIndex, 1)
        local keyId2, mod21, mod22, mod23, mod24 = GetActionBindingInfo(layerIndex, categoryIndex, actionIndex, 2)
        return DoesKeyBindMatchInput(keyId1, mod1, mod2, mod3, mod4, key, ctrl, alt, shift, command) 
            or DoesKeyBindMatchInput(keyId2, mod21, mod22, mod23, mod24, key, ctrl, alt, shift, command)
    end
    return false
end

function ZO_Keybindings_GetTexturePathForKey(keyCode, disabled)
    if disabled == nil then
        disabled = false
    end
    local mouseIcon, mouseWidth, mouseHeight = GetMouseIconPathForKeyCode(keyCode)
    if mouseIcon then
        return mouseIcon, mouseWidth, mouseHeight
    end
    local keyboardIcon, keyboardWidth, keyboardHeight = GetKeyboardIconPathForKeyCode(keyCode, disabled)
    if keyboardIcon then
        return keyboardIcon, keyboardWidth, keyboardHeight
    end
    return GetGamepadIconPathForKeyCode(keyCode, disabled)
end

KEYBIND_TEXT_OPTIONS_ABBREVIATED_NAME = 1
KEYBIND_TEXT_OPTIONS_FULL_NAME = 2
KEYBIND_TEXT_OPTIONS_FULL_NAME_SEPARATE_MODS = 3

KEYBIND_TEXTURE_OPTIONS_NONE = 1
KEYBIND_TEXTURE_OPTIONS_EMBED_MARKUP = 2

function ZO_Keybindings_ShouldUseTextKeyMarkup(key)
    return IsKeyCodeKeyboardKey(key)
end

function ZO_Keybindings_GenerateTextKeyMarkup(name)
    return ("|u25%%:25%%:key:%s|u"):format(name)
end

--Gamepad and mouse keys use icons instead of text (with the exception of mouse button 4 and 5)
function ZO_Keybindings_ShouldUseIconKeyMarkup(key)
    return (IsKeyCodeMouseKey(key) and not (key == KEY_MOUSE_4 or key == KEY_MOUSE_5)) or IsKeyCodeGamepadKey(key) or IsKeyCodeArrowKey(key)
end

function ZO_Keybindings_GenerateIconKeyMarkup(key, scalePercent, useDisabledIcon)
    local scale = scalePercent or 100
    local useDisabledIconString = useDisabledIcon and ":disabled" or ""
    return ("|k%.1f%%:%s%s|k"):format(scale, key, useDisabledIconString)
end

do
    local keyNameTable = {}
    local DEFAULT_SCALE_PERCENT = 180

    local function GetKeyOrTexture(keyCode, textureOptions, scalePercent, useDisabledIcon)
        if textureOptions == KEYBIND_TEXTURE_OPTIONS_EMBED_MARKUP then
            if ZO_Keybindings_ShouldUseIconKeyMarkup(keyCode) then
                return ZO_Keybindings_GenerateIconKeyMarkup(keyCode, scalePercent or DEFAULT_SCALE_PERCENT, useDisabledIcon)
            end
            return ZO_Keybindings_GenerateTextKeyMarkup(GetKeyName(keyCode))
        else
            return GetKeyName(keyCode)
        end
    end

    local function TranslateNarrationKeys(key, mod1, mod2, mod3, mod4)
        if key ~= KEY_INVALID then
            ZO_ClearNumericallyIndexedTable(keyNameTable)

            if mod1 ~= KEY_INVALID then table.insert(keyNameTable, GetKeyNarrationText(mod1)) end
            if mod2 ~= KEY_INVALID then table.insert(keyNameTable, GetKeyNarrationText(mod2)) end
            if mod3 ~= KEY_INVALID then table.insert(keyNameTable, GetKeyNarrationText(mod3)) end
            if mod4 ~= KEY_INVALID then table.insert(keyNameTable, GetKeyNarrationText(mod4)) end

            table.insert(keyNameTable, GetKeyNarrationText(key))

            return table.concat(keyNameTable, "-")
        end
    
        return GetString(SI_ACTION_IS_NOT_BOUND)
    end

    local function TranslateKeys(key, mod1, mod2, mod3, mod4, textOptions, textureOptions, scalePercent, useDisabledIcon)
        if key ~= KEY_INVALID then
            ZO_ClearNumericallyIndexedTable(keyNameTable)

            textOptions = textOptions or KEYBIND_TEXT_OPTIONS_ABBREVIATED_NAME
            textureOptions = textureOptions or KEYBIND_TEXTURE_OPTIONS_NONE

            if mod1 ~= KEY_INVALID then table.insert(keyNameTable, GetKeyOrTexture(mod1, textureOptions, scalePercent, useDisabledIcon)) end
            if mod2 ~= KEY_INVALID then table.insert(keyNameTable, GetKeyOrTexture(mod2, textureOptions, scalePercent, useDisabledIcon)) end
            if mod3 ~= KEY_INVALID then table.insert(keyNameTable, GetKeyOrTexture(mod3, textureOptions, scalePercent, useDisabledIcon)) end
            if mod4 ~= KEY_INVALID then table.insert(keyNameTable, GetKeyOrTexture(mod4, textureOptions, scalePercent, useDisabledIcon)) end

            if textOptions == KEYBIND_TEXT_OPTIONS_ABBREVIATED_NAME and #keyNameTable > 0 then
                table.insert(keyNameTable, textureOptions == KEYBIND_TEXTURE_OPTIONS_NONE and "-" or " - ")
            end

            table.insert(keyNameTable, GetKeyOrTexture(key, textureOptions, scalePercent, useDisabledIcon))

            if textOptions == KEYBIND_TEXT_OPTIONS_FULL_NAME_SEPARATE_MODS then
                return unpack(keyNameTable, 1, 4)
            elseif textOptions == KEYBIND_TEXT_OPTIONS_FULL_NAME then
                return table.concat(keyNameTable, textureOptions == KEYBIND_TEXTURE_OPTIONS_NONE and "-" or " - ")
            else
                return table.concat(keyNameTable)
            end
        end
    
        return GetString(SI_ACTION_IS_NOT_BOUND)
    end

    function ZO_Keybindings_GetBindingStringFromKeys(key, mod1, mod2, mod3, mod4, textOptions, textureOptions, textureWidthPercent, textureHeightPercent, useDisabledIcon)
        return TranslateKeys(key, mod1, mod2, mod3, mod4, textOptions, textureOptions, textureWidthPercent, useDisabledIcon)
    end

    function ZO_Keybindings_GetNarrationStringFromKeys(key, mod1, mod2, mod3, mod4)
        return TranslateNarrationKeys(key, mod1, mod2, mod3, mod4)
    end

    function ZO_Keybindings_GetBindingStringFromAction(actionName, textOptions, textureOptions, bindingIndex, textureWidthPercent, textureHeightPercent, useDisabledIcon)
        local layerIndex, categoryIndex, actionIndex = GetActionIndicesFromName(actionName)
        if layerIndex then
            local key, mod1, mod2, mod3, mod4 = GetActionBindingInfo(layerIndex, categoryIndex, actionIndex, bindingIndex or 1)
            return ZO_Keybindings_GetBindingStringFromKeys(key, mod1, mod2, mod3, mod4, textOptions, textureOptions, textureWidthPercent, textureHeightPercent, useDisabledIcon)
        end
        return ""
    end

    function ZO_Keybindings_GetNarrationStringFromAction(actionName, bindingIndex)
        local layerIndex, categoryIndex, actionIndex = GetActionIndicesFromName(actionName)
        if layerIndex then
            local key, mod1, mod2, mod3, mod4 = GetActionBindingInfo(layerIndex, categoryIndex, actionIndex, bindingIndex or 1)
            return TranslateNarrationKeys(key, mod1, mod2, mod3, mod4)
        end
        return ""
    end

    -- Doesn't return the GetString(SI_ACTION_IS_NOT_BOUND) automatically, just nil if theres no binds
    function ZO_Keybindings_GetHighestPriorityBindingStringFromAction(actionName, textOptions, textureOptions, alwaysPreferGamepadMode, showAsHold, scalePercent, useDisabledIcon)
        local preferredKeybindType = ZO_Keybindings_GetPreferredKeyType(alwaysPreferGamepadMode)
        local key, mod1, mod2, mod3, mod4 = GetHighestPriorityActionBindingInfoFromNameAndInputDevice(actionName, preferredKeybindType)

        if key == KEY_INVALID then
            return nil
        end

        if showAsHold then
            local holdKey = ConvertKeyPressToHold(key)
            if holdKey ~= KEY_INVALID then
                key = holdKey
            end
        end
        return ZO_Keybindings_GetBindingStringFromKeys(key, mod1, mod2, mod3, mod4, textOptions, textureOptions, scalePercent, scalePercent, useDisabledIcon), key, mod1, mod2, mod3, mod4
    end


    -- Doesn't return the GetString(SI_ACTION_IS_NOT_BOUND) automatically, just nil if theres no binds
    --TODO XAR: Determine if we need alwaysPreferGamepadMode and showAsHold
    function ZO_Keybindings_GetHighestPriorityNarrationStringFromAction(actionName, alwaysPreferGamepadMode, showAsHold)
        local preferredKeybindType = ZO_Keybindings_GetPreferredKeyType(alwaysPreferGamepadMode)
        local key, mod1, mod2, mod3, mod4 = GetHighestPriorityActionBindingInfoFromNameAndInputDevice(actionName, preferredKeybindType)

        if key == KEY_INVALID then
            return nil
        end

        if showAsHold then
            local holdKey = ConvertKeyPressToHold(key)
            if holdKey ~= KEY_INVALID then
                key = holdKey
            end
        end
        return TranslateNarrationKeys(key, mod1, mod2, mod3, mod4)
    end
end

local function RegisterLabelForBindingUpdate(label, actionName, showUnbound, gamepadActionName, onBindingUpdateCallback, alwaysPreferGamepadMode, showAsHold, scalePercent, useDisabledIcon)
    local function UpdateRegisteredKeybind()
        local disableIcon = useDisabledIcon
        if type(useDisabledIcon) == "function" then
            disableIcon = useDisabledIcon()
        end

        local bindingText, key, mod1, mod2, mod3, mod4
        if gamepadActionName and ZO_Keybindings_ShouldUseGamepadAction(alwaysPreferGamepadMode) then
            bindingText, key, mod1, mod2, mod3, mod4 = ZO_Keybindings_GetHighestPriorityBindingStringFromAction(gamepadActionName, KEYBIND_TEXT_OPTIONS_FULL_NAME, KEYBIND_TEXTURE_OPTIONS_EMBED_MARKUP, alwaysPreferGamepadMode, showAsHold, scalePercent, disableIcon)
        end

        if not bindingText or #bindingText == 0 then
            bindingText, key, mod1, mod2, mod3, mod4 = ZO_Keybindings_GetHighestPriorityBindingStringFromAction(actionName, KEYBIND_TEXT_OPTIONS_FULL_NAME, KEYBIND_TEXTURE_OPTIONS_EMBED_MARKUP, alwaysPreferGamepadMode, showAsHold, scalePercent, disableIcon)
        end

        if showUnbound or showUnbound == nil then
            bindingText = bindingText or ZO_Keybindings_GenerateTextKeyMarkup(GetString(SI_ACTION_IS_NOT_BOUND))
        else
            label:SetHidden(bindingText == nil)
            bindingText = bindingText or ""
        end

        if onBindingUpdateCallback then
            onBindingUpdateCallback(label, bindingText, key, mod1, mod2, mod3, mod4)
        end
    end

    local function TryUpdateRegisteredKeybind(eventCode, layerIndex, categoryIndex, actionIndex)
        if actionName == GetActionInfo(layerIndex, categoryIndex, actionIndex) then
            UpdateRegisteredKeybind()
        end
    end

    label:RegisterForEvent(EVENT_KEYBINDING_SET, TryUpdateRegisteredKeybind)
    label:RegisterForEvent(EVENT_KEYBINDING_CLEARED, TryUpdateRegisteredKeybind)
    label:RegisterForEvent(EVENT_KEYBINDINGS_LOADED, UpdateRegisteredKeybind)
    label:RegisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, UpdateRegisteredKeybind)
    label:RegisterForEvent(EVENT_INPUT_TYPE_CHANGED, UpdateRegisteredKeybind)
    label:RegisterForEvent(EVENT_KEYBIND_DISPLAY_MODE_CHANGED, UpdateRegisteredKeybind)

    label.updateRegisteredKeybindCallback = UpdateRegisteredKeybind

    UpdateRegisteredKeybind()
end

function ZO_Keybindings_RegisterLabelForBindingUpdate(label, actionName, showUnbound, gamepadActionName, onChangedCallback, alwaysPreferGamepadMode, showAsHold, scalePercent, useDisabledIcon)
    local function OnKeybindUpdate(label, bindingText, key, mod1, mod2, mod3, mod4)
        label:SetText(bindingText)
        if onChangedCallback then
            onChangedCallback(label, bindingText, key, mod1, mod2, mod3, mod4)
        end
    end
    RegisterLabelForBindingUpdate(label, actionName, showUnbound, gamepadActionName, OnKeybindUpdate, alwaysPreferGamepadMode, showAsHold, scalePercent, useDisabledIcon)
end

--This function is identical to the more general ZO_Keybdinging_RegisterLabelForBindingUpdate with the exception that it does
--not call SetText for the case that the keybind is embedded in a larger line of text. In such a case, it's up to whatever is
--handling that line to call SetText appropriately.
function ZO_Keybindings_RegisterLabelForInLineBindingUpdate(label, actionName, showUnbound, gamepadActionName, onChangedCallback, alwaysPreferGamepadMode, showAsHold, scalePercent, useDisabledIcon)
    local function OnKeybindUpdate(label, bindingText, key, mod1, mod2, mod3, mod4)
        if onChangedCallback then
            onChangedCallback(label, bindingText, key, mod1, mod2, mod3, mod4)
        end
    end
    RegisterLabelForBindingUpdate(label, actionName, showUnbound, gamepadActionName, OnKeybindUpdate, alwaysPreferGamepadMode, showAsHold, scalePercent, useDisabledIcon)
end

function ZO_Keybindings_UnregisterLabelForBindingUpdate(label)
    label:UnregisterForEvent(EVENT_KEYBINDING_SET)
    label:UnregisterForEvent(EVENT_KEYBINDING_CLEARED)
    label:UnregisterForEvent(EVENT_KEYBINDINGS_LOADED)
    label:UnregisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED)
    label:UnregisterForEvent(EVENT_INPUT_TYPE_CHANGED)
    label:UnregisterForEvent(EVENT_KEYBIND_DISPLAY_MODE_CHANGED)

    label.updateRegisteredKeybindCallback = nil
end

function ZO_Keybinding_GetGamepadActionName(actionName)
    local localizedGamepadActionName = GetString(_G["SI_BINDING_NAME_GAMEPAD_"..actionName])
    
    if localizedGamepadActionName ~= "" then
        return localizedGamepadActionName
    else
        local localizedActionName = GetString(_G["SI_BINDING_NAME_"..actionName])
        return localizedActionName
    end
end

function ZO_Keybindings_ShouldUseGamepadAction(alwaysPreferGamepadMode)
    return alwaysPreferGamepadMode or IsInGamepadPreferredMode()
end


function ZO_Keybindings_ShouldShowGamepadKeybind(alwaysPreferGamepadMode)
    if alwaysPreferGamepadMode then
        return true
    end

    if IsInGamepadPreferredMode() then
        local keybindDisplayMode = tonumber(GetSetting(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_KEYBIND_DISPLAY_MODE))
        if keybindDisplayMode == KEYBIND_DISPLAY_MODE_ALWAYS_KEYBOARD then
            return false
        elseif keybindDisplayMode == KEYBIND_DISPLAY_MODE_ALWAYS_GAMEPAD then
            return true
        else -- keybindDisplayMode == KEYBIND_DISPLAY_MODE_AUTOMATIC
            if AreKeyboardBindingsSupportedInGamepadUI() then
                return WasLastInputGamepad()
            else
                return true
            end
        end
    end

    return false
end

function ZO_Keybindings_GetPreferredKeyType(alwaysPreferGamepadMode)
    if alwaysPreferGamepadMode then
        return PREFERRED_INPUT_DEVICE_TYPE_GAMEPAD
    end

    if IsInGamepadPreferredMode() then
        local keybindDisplayMode = tonumber(GetSetting(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_KEYBIND_DISPLAY_MODE))
        if keybindDisplayMode == KEYBIND_DISPLAY_MODE_ALWAYS_KEYBOARD then
            return PREFERRED_INPUT_DEVICE_TYPE_KEYBOARD
        elseif keybindDisplayMode == KEYBIND_DISPLAY_MODE_ALWAYS_GAMEPAD then
            return PREFERRED_INPUT_DEVICE_TYPE_GAMEPAD
        else -- keybindDisplayMode == KEYBIND_DISPLAY_MODE_AUTOMATIC
            if AreKeyboardBindingsSupportedInGamepadUI() then
                if WasLastInputGamepad() then
                    return PREFERRED_INPUT_DEVICE_TYPE_GAMEPAD
                else
                    return PREFERRED_INPUT_DEVICE_TYPE_KEYBOARD
                end
            else
                return PREFERRED_INPUT_DEVICE_TYPE_GAMEPAD
            end
        end
    end

    return PREFERRED_INPUT_DEVICE_TYPE_KEYBOARD_OR_MOUSE
end
