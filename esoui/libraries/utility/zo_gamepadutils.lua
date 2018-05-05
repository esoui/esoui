GAMEPAD_INCLUDE_DEADZONE = true
GAMEPAD_EXCLUDE_DEADZONE = false

local g_defaultEaseFunction = ZO_EaseInCubic

function ZO_Gamepad_GetLeftStickEasedX()
    return g_defaultEaseFunction(GetGamepadLeftStickX(GAMEPAD_INCLUDE_DEADZONE))
end

function ZO_Gamepad_GetLeftStickEasedY()
    return g_defaultEaseFunction(GetGamepadLeftStickY(GAMEPAD_INCLUDE_DEADZONE))
end

function ZO_Gamepad_GetRightStickEasedX()
    return g_defaultEaseFunction(GetGamepadRightStickX(GAMEPAD_INCLUDE_DEADZONE))
end

function ZO_Gamepad_GetRightStickEasedY()
    return g_defaultEaseFunction(GetGamepadRightStickY(GAMEPAD_INCLUDE_DEADZONE))
end

local function DefaultIsDataHeader(data)
    return data.isHeader or data.header
end

function ZO_Gamepad_CreateListTriggerKeybindDescriptors(list, optionalHeaderComparator)
    local leftTrigger = {
        --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
        name = function()
            local list = list --need a local copy so the original isn't overwritten on subsequent calls
            if type(list) == "function" then
                list = list()
            end
            local listControl = list:GetControl()
			if listControl then
				return listControl:GetName()
			end
        end,
        keybind = "UI_SHORTCUT_LEFT_TRIGGER",
        ethereal = true,

        callback = function()
            local list = list --need a local copy so the original isn't overwritten on subsequent calls
            if type(list) == "function" then
                list = list()
            end
            if list:IsActive() and not list:IsEmpty() and not list:SetPreviousSelectedDataByEval(optionalHeaderComparator or DefaultIsDataHeader, ZO_PARAMETRIC_MOVEMENT_TYPES.JUMP_PREVIOUS) then
                list:SetFirstIndexSelected(ZO_PARAMETRIC_MOVEMENT_TYPES.JUMP_PREVIOUS)
            end
        end,
    }

    local rightTrigger = {
        --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
        name = function()
            local list = list --need a local copy so the original isn't overwritten on subsequent calls
            if type(list) == "function" then
                list = list()
            end
            local listControl = list:GetControl()
			if listControl then
				return listControl:GetName()
			end
        end,

        keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
        ethereal = true,

        callback = function()
            local list = list --need a local copy so the original isn't overwritten on subsequent calls
            if type(list) == "function" then
                list = list()
            end
            if list:IsActive() and not list:IsEmpty() and not list:SetNextSelectedDataByEval(optionalHeaderComparator or DefaultIsDataHeader, ZO_PARAMETRIC_MOVEMENT_TYPES.JUMP_NEXT) then
                list:SetLastIndexSelected(ZO_PARAMETRIC_MOVEMENT_TYPES.JUMP_NEXT)
            end
        end,
    }

    return leftTrigger, rightTrigger
end

function ZO_Gamepad_AddListTriggerKeybindDescriptors(descriptor, list, optionalHeaderComparator)
    local leftTrigger, rightTrigger = ZO_Gamepad_CreateListTriggerKeybindDescriptors(list, optionalHeaderComparator)

    table.insert(descriptor, leftTrigger)
	table.insert(descriptor, rightTrigger)
end

GAME_NAVIGATION_TYPE_STICK = 1
GAME_NAVIGATION_TYPE_BUTTON = 2
GAME_NAVIGATION_TYPE_BOTH = 3

function ZO_Gamepad_AddForwardNavigationKeybindDescriptors(descriptor, navigationType, callback, name, visible, enabled, sound)
    if navigationType == GAME_NAVIGATION_TYPE_STICK or navigationType == GAME_NAVIGATION_TYPE_BOTH then
        descriptor[#descriptor + 1] = {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = name or GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_INPUT_RIGHT",
            ethereal = true,
            visible = visible,
            callback = callback,
            sound = sound,
			enabled = enabled,
        }
    end

    if navigationType == GAME_NAVIGATION_TYPE_BUTTON or navigationType == GAME_NAVIGATION_TYPE_BOTH then
        descriptor[#descriptor + 1] = {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = name or GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            order = -500,
            callback = callback,
            visible = visible,
            sound = sound,
			enabled = enabled,
        }
    end
end

function ZO_Gamepad_AddForwardNavigationKeybindDescriptorsWithSound(descriptor, navigationType, callback, name, visible, enabled)
    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(descriptor, navigationType, callback, name, visible, enabled, SOUNDS.GAMEPAD_MENU_FORWARD)
end

local function DefaultBack()
    SCENE_MANAGER:HideCurrentScene()
end

function ZO_Gamepad_AddBackNavigationKeybindDescriptors(descriptor, navigationType, callback, name, sound)
    if navigationType == GAME_NAVIGATION_TYPE_STICK or navigationType == GAME_NAVIGATION_TYPE_BOTH then
        descriptor[#descriptor + 1] = {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = name or GetString(SI_GAMEPAD_BACK_OPTION),
            keybind = "UI_SHORTCUT_INPUT_LEFT",
            ethereal = true,
            sound = sound,
            callback = callback or DefaultBack,
        }
    end

    if navigationType == GAME_NAVIGATION_TYPE_BUTTON or navigationType == GAME_NAVIGATION_TYPE_BOTH then
        descriptor[#descriptor + 1] = {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = name or GetString(SI_GAMEPAD_BACK_OPTION),
            keybind = "UI_SHORTCUT_NEGATIVE",
            visible = IsInGamepadPreferredMode,
            order = -1500,
            sound = sound,
            callback = callback or DefaultBack,
        }
    end
end

function ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(descriptor, navigationType, callback, name)
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(descriptor, navigationType, callback, name, SOUNDS.GAMEPAD_MENU_BACK)
end

local ALPHABET_TABLE = { "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" }
function ZO_Gamepad_TempVirtualKeyboardGenRandomString(prefix, totalLength)
    totalLength = totalLength or (string.len(prefix) + 7)

    local result = prefix .. "-"
    local prevChar = nil

    while(string.len(result) < totalLength) do
        local char = ALPHABET_TABLE[math.random(1, #ALPHABET_TABLE)]
        if(char ~= prevChar) then -- prevent the violation state of multiple instances of the same char.
            result = result .. char
            prevChar = char
        end
    end
    return result
end