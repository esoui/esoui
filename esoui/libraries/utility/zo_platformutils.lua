function ZO_FormatUserFacingDisplayName(name)
    return IsConsoleUI() and UndecorateDisplayName(name) or name
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
        userFacingName = displayName ~= "" and ZO_FormatUserFacingDisplayName(displayName) or characterName
    else
        -- Prioritize the character name in the keyboard UI.
        userFacingName = characterName ~= "" and characterName or ZO_FormatUserFacingDisplayName(displayName)
    end

    return userFacingName
end

function ZO_SavePlayerConsoleProfile()
    if IsConsoleUI() and SavePlayerConsoleProfile ~= nil then
        SavePlayerConsoleProfile()
    end
end