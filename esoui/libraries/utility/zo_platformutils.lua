local CHARACTER_NAME_ICON = "EsoUI/Art/Miscellaneous/Gamepad/gp_charNameIcon.dds"
local KEYBOARD_UI_ICON_SIZE = 24
local GAMEPAD_UI_ICON_SIZE = 32

function ZO_FormatUserFacingDisplayName(name)
    return IsConsoleUI() and UndecorateDisplayName(name) or name
end

function ZO_FormatUserFacingCharacterName(name)
    local iconSize = IsInGamepadPreferredMode() and GAMEPAD_UI_ICON_SIZE or KEYBOARD_UI_ICON_SIZE
	return zo_iconTextFormat(CHARACTER_NAME_ICON, iconSize, iconSize, name)
end

function ZO_FormatUserFacingCharacterOrDisplayName(characterOrDisplayName)
    return IsDecoratedDisplayName(characterOrDisplayName) and ZO_FormatUserFacingDisplayName(characterOrDisplayName) or ZO_FormatUserFacingCharacterName(characterOrDisplayName)
end

function ZO_FormatManualNameEntry(name)
    return IsConsoleUI() and DecorateDisplayName(name) or name
end

function ZO_GetPlatformAccountLabel()
    return GetString("SI_PLATFORMACCOUNTLABEL", GetUIPlatform())
end

function ZO_GetPlatformUserFacingName(characterName, displayName)
    local userFacingName

    if IsInGamepadPreferredMode() then
        -- Prioritize the userID if using the gamepad UI, but fallback to character name on PC for cases where
        -- we have the character name but not the userID
        userFacingName = displayName ~= "" and ZO_FormatUserFacingDisplayName(displayName) or ZO_FormatUserFacingCharacterName(characterName)
    else
        -- Prioritize the character name in the keyboard UI.
        userFacingName = characterName ~= "" and ZO_FormatUserFacingCharacterName(characterName) or ZO_FormatUserFacingDisplayName(displayName)
    end

    return userFacingName
end

function ZO_SavePlayerConsoleProfile()
    if IsConsoleUI() and SavePlayerConsoleProfile ~= nil then
        SavePlayerConsoleProfile()
    end
end