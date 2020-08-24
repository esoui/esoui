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
    return (IsKeyCodeMouseKey(key) and not (key == KEY_MOUSE_4 or key == KEY_MOUSE_5)) or IsKeyCodeGamepadKey(key)
end

function ZO_Keybindings_GenerateIconKeyMarkup(key, scalePercent)
    return ("|k%.1f%%:%s|k"):format(scalePercent or 100, key)
end

do
    local keyNameTable = {}
    local EXPECTED_ICON_SIZE = 64
    local DEFAULT_SCALE_PERCENT = 180

    local function GetKeyOrTexture(keyCode, textureOptions, scalePercent)
        if textureOptions == KEYBIND_TEXTURE_OPTIONS_EMBED_MARKUP then
            if ZO_Keybindings_ShouldUseIconKeyMarkup(keyCode) then
                return ZO_Keybindings_GenerateIconKeyMarkup(keyCode, scalePercent or DEFAULT_SCALE_PERCENT)
            end
            return ZO_Keybindings_GenerateTextKeyMarkup(GetKeyName(keyCode))
        else
            return GetKeyName(keyCode)
        end
    end

    local function TranslateKeys(key, mod1, mod2, mod3, mod4, textOptions, textureOptions, textureWidthPercent, textureHeightPercent)
        if key ~= KEY_INVALID then
            ZO_ClearNumericallyIndexedTable(keyNameTable)

            textOptions = textOptions or KEYBIND_TEXT_OPTIONS_ABBREVIATED_NAME
            textureOptions = textureOptions or KEYBIND_TEXTURE_OPTIONS_NONE

            if mod1 ~= KEY_INVALID then table.insert(keyNameTable, GetKeyOrTexture(mod1, textureOptions, textureWidthPercent, textureHeightPercent)) end
            if mod2 ~= KEY_INVALID then table.insert(keyNameTable, GetKeyOrTexture(mod2, textureOptions, textureWidthPercent, textureHeightPercent)) end
            if mod3 ~= KEY_INVALID then table.insert(keyNameTable, GetKeyOrTexture(mod3, textureOptions, textureWidthPercent, textureHeightPercent)) end
            if mod4 ~= KEY_INVALID then table.insert(keyNameTable, GetKeyOrTexture(mod4, textureOptions, textureWidthPercent, textureHeightPercent)) end

            if textOptions == KEYBIND_TEXT_OPTIONS_ABBREVIATED_NAME and #keyNameTable > 0 then
                table.insert(keyNameTable, textureOptions == KEYBIND_TEXTURE_OPTIONS_NONE and "-" or " - ")
            end

            table.insert(keyNameTable, GetKeyOrTexture(key, textureOptions, textureWidthPercent, textureHeightPercent))

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

    function ZO_Keybindings_GetBindingStringFromKeys(key, mod1, mod2, mod3, mod4, textOptions, textureOptions, textureWidthPercent, textureHeightPercent)
        return TranslateKeys(key, mod1, mod2, mod3, mod4, textOptions, textureOptions, textureWidthPercent, textureHeightPercent)
    end

    function ZO_Keybindings_GetBindingStringFromAction(actionName, textOptions, textureOptions, bindingIndex, textureWidthPercent, textureHeightPercent)
        local layerIndex, categoryIndex, actionIndex = GetActionIndicesFromName(actionName)
        if layerIndex then
            local key, mod1, mod2, mod3, mod4 = GetActionBindingInfo(layerIndex, categoryIndex, actionIndex, bindingIndex or 1)
            return ZO_Keybindings_GetBindingStringFromKeys(key, mod1, mod2, mod3, mod4, textOptions, textureOptions, textureWidthPercent, textureHeightPercent)
        end
        return ""
    end

    -- Doesn't return the GetString(SI_ACTION_IS_NOT_BOUND) automatically, just nil if theres no binds
    function ZO_Keybindings_GetHighestPriorityBindingStringFromAction(actionName, textOptions, textureOptions, alwaysPreferGamepadMode, showAsHold)
        local preferGamepadMode
        if alwaysPreferGamepadMode == nil then
            preferGamepadMode = IsInGamepadPreferredMode()
        else
            preferGamepadMode = alwaysPreferGamepadMode
        end
        local key, mod1, mod2, mod3, mod4 = GetHighestPriorityActionBindingInfoFromName(actionName, preferGamepadMode)
        if key ~= KEY_INVALID then
            if showAsHold then
                local holdKey = ConvertKeyPressToHold(key)
                if holdKey ~= KEY_INVALID then
                    key = holdKey
                end
            end
            return ZO_Keybindings_GetBindingStringFromKeys(key, mod1, mod2, mod3, mod4, textOptions, textureOptions), key, mod1, mod2, mod3, mod4
        end

        return nil
    end
end

function ZO_Keybindings_RegisterLabelForBindingUpdate(label, actionName, showUnbound, gamepadActionName, onChangedCallback, alwaysPreferGamepadMode, showAsHold)
    local function UpdateRegisteredKeybind()
        local bindingText, key, mod1, mod2, mod3, mod4
        if gamepadActionName and (alwaysPreferGamepadMode or IsInGamepadPreferredMode()) then
            bindingText, key, mod1, mod2, mod3, mod4 = ZO_Keybindings_GetHighestPriorityBindingStringFromAction(gamepadActionName, KEYBIND_TEXT_OPTIONS_FULL_NAME, KEYBIND_TEXTURE_OPTIONS_EMBED_MARKUP, alwaysPreferGamepadMode, showAsHold)
        end

        if not bindingText or #bindingText == 0 then
            bindingText, key, mod1, mod2, mod3, mod4 = ZO_Keybindings_GetHighestPriorityBindingStringFromAction(actionName, KEYBIND_TEXT_OPTIONS_FULL_NAME, KEYBIND_TEXTURE_OPTIONS_EMBED_MARKUP, alwaysPreferGamepadMode, showAsHold)
        end

        if showUnbound or showUnbound == nil then
            bindingText = bindingText or ZO_Keybindings_GenerateTextKeyMarkup(GetString(SI_ACTION_IS_NOT_BOUND))
        else
            label:SetHidden(bindingText == nil)
            bindingText = bindingText or ""
        end

        label:SetText(bindingText)
        if onChangedCallback then
            onChangedCallback(label, bindingText, key, mod1, mod2, mod3, mod4)
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

    UpdateRegisteredKeybind()
end

function ZO_Keybindings_UnregisterLabelForBindingUpdate(label)
    label:UnregisterForEvent(EVENT_KEYBINDING_SET)
    label:UnregisterForEvent(EVENT_KEYBINDING_CLEARED)
    label:UnregisterForEvent(EVENT_KEYBINDINGS_LOADED)
    label:UnregisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED)
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