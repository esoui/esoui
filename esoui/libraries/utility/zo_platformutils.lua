

function ZO_FormatUserFacingDisplayName(name)
    return IsConsoleUI() and UndecorateDisplayName(name) or name
end

do
    local CHARACTER_NAME_ICON = "EsoUI/Art/Miscellaneous/Gamepad/gp_charNameIcon.dds"
    local CHARACTER_NAME_ICON_SIZE = "70%"

    function ZO_FormatUserFacingCharacterName(name)
        if name ~= "" then
            if IsInGamepadPreferredMode() then
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

internalassert(UI_PLATFORM_MAX_VALUE == ACCOUNT_LABEL_MAX_VALUE, "There should be a platform account label for every platform")
function ZO_GetPlatformAccountLabel()
    return GetString("SI_PLATFORMACCOUNTLABEL", GetUIPlatform())
end

internalassert(PLATFORM_STORE_LABEL_MAX_VALUE == PLATFORM_SERVICE_TYPE_MAX_VALUE, "There should be a platform store label for every platform service")
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

function ZO_PlatformOpenApprovedURL(approvedUrlType, linkText, externalApplicationText)
    ZO_Dialogs_ShowPlatformDialog("CONFIRM_OPEN_URL_BY_TYPE", { urlType = approvedUrlType }, { mainTextParams = { linkText, externalApplicationText } })
end

do
    internalassert(UI_PLATFORM_MAX_VALUE == 4, "Do these functions still do what they say they do?")

    function ZO_IsPCUI()
        return not IsConsoleUI()
    end

    function ZO_IsConsoleUI()
        return IsConsoleUI()
    end

    function ZO_IsWindowsUI()
        return ZO_IsPCUI() and not IsMacUI()
    end

    function ZO_IsPlaystationPlatform()
        local platform = GetUIPlatform()
        return platform == UI_PLATFORM_PS4 or platform == UI_PLATFORM_PS5
    end

    function ZO_IsConsolePlatform()
        local platform = GetUIPlatform()
        return ZO_IsPlaystationPlatform() or platform == UI_PLATFORM_XBOX
    end

    function ZO_IsForceConsoleFlow()
        if IsConsoleUI() then
            return GetUIPlatform() == UI_PLATFORM_PC
        end
        return false
    end
end

function ZO_IsIngameUI()
    return IsInUI("ingame")
end

function ZO_IsPregameUI()
    return IsInUI("pregame")
end

function ZO_IsInternalIngameUI()
    return IsInUI("internal_ingame")
end

function ZO_GetGamerCardStringId()
    return ZO_IsPlaystationPlatform() and SI_PLAYER_TO_PLAYER_VIEW_PSN_PROFILE or SI_PLAYER_TO_PLAYER_VIEW_GAMER_CARD
end