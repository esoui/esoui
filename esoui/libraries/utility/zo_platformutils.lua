

function ZO_FormatUserFacingDisplayName(name)
    return IsConsoleUI() and UndecorateDisplayName(name) or name
end

do
    local CHARACTER_NAME_ICON = "EsoUI/Art/Miscellaneous/Gamepad/gp_charNameIcon.dds"
    local CHARACTER_NAME_ICON_SIZE = "70%"

    function ZO_FormatUserFacingCharacterName(name)
        if name ~= "" then
            if IsInGamepadPreferredMode()then
                return zo_iconTextFormat(CHARACTER_NAME_ICON, CHARACTER_NAME_ICON_SIZE, CHARACTER_NAME_ICON_SIZE, name)
            else
                return name
            end
        else
            return ""
        end
    end
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

function ZO_GetPlatformStoreName()
    return GetString("SI_PLATFORMSTORELABEL", GetPlatformServiceType())
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

function ZO_GetInviteInstructions()
    local instructions 
    if IsConsoleUI() then
        local platform = ZO_GetPlatformAccountLabel()
        instructions = zo_strformat(SI_REQUEST_DISPLAY_NAME_INSTRUCTIONS, platform)
    else
        instructions = GetString(SI_REQUEST_NAME_INSTRUCTIONS)
    end
    return instructions
end

function ZO_PlatformIgnorePlayer(displayName, idRequestType, ...)
    if not IsIgnored(displayName) then
        if not IsConsoleUI() then
            AddIgnore(displayName)
        else
            if not idRequestType or idRequestType == ZO_ID_REQUEST_TYPE_DISPLAY_NAME then
                ZO_ShowConsoleIgnoreDialog(displayName)
            else
                ZO_ShowConsoleIgnoreDialogFromDisplayNameOrFallback(displayName, idRequestType, ...)
            end
        end
    end
end
