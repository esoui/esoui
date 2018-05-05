USE_INTERNAL_FORMAT = true

function ZO_ShouldPreferUserId()
    local setting = IsInGamepadPreferredMode() and UI_SETTING_PRIMARY_PLAYER_NAME_GAMEPAD or UI_SETTING_PRIMARY_PLAYER_NAME_KEYBOARD
    return tonumber(GetSetting(SETTING_TYPE_UI, setting)) == PRIMARY_PLAYER_NAME_SETTING_PREFER_USERID
end

function ZO_GetPrimaryPlayerNameFromUnitTag(unitTag, useInternalFormat)
    if ZO_ShouldPreferUserId() then
        local displayName = GetUnitDisplayName(unitTag)
        return useInternalFormat and displayName or ZO_FormatUserFacingDisplayName(displayName)
    else
		local characterName = GetUnitName(unitTag)
        return useInternalFormat and characterName or ZO_FormatUserFacingCharacterName(characterName);
    end 
end

function ZO_GetSecondaryPlayerNameFromUnitTag(unitTag, useInternalFormat)
    if not ZO_ShouldPreferUserId() then
        local displayName = GetUnitDisplayName(unitTag)
        return useInternalFormat and displayName or ZO_FormatUserFacingDisplayName(displayName)
    else
        local characterName = GetUnitName(unitTag)
        return useInternalFormat and characterName or ZO_FormatUserFacingCharacterName(characterName);
    end 
end

function ZO_GetPrimaryPlayerName(displayName, characterName, useInternalFormat)
    if ZO_ShouldPreferUserId() then
        return useInternalFormat and displayName or ZO_FormatUserFacingDisplayName(displayName)
    else
		return useInternalFormat and characterName or ZO_FormatUserFacingCharacterName(characterName)
    end
end

function ZO_GetSecondaryPlayerName(displayName, characterName, useInternalFormat)
    if not ZO_ShouldPreferUserId() then
        return useInternalFormat and displayName or ZO_FormatUserFacingDisplayName(displayName)
    else
		return useInternalFormat and characterName or ZO_FormatUserFacingCharacterName(characterName)
    end
end

function ZO_GetSecondaryPlayerNameWithTitleFromUnitTag(unitTag)
    local name = ZO_GetSecondaryPlayerNameFromUnitTag(unitTag)
    local title = GetUnitTitle(unitTag)
    if title ~= "" then
        return zo_strformat(SI_PLAYER_NAME_WITH_TITLE_FORMAT, name, title)
    else
        return name
    end
end

function ZO_GetPrimaryPlayerNameWithSecondary(displayName, characterName)
    local primaryName = ZO_GetPrimaryPlayerName(displayName, characterName)
    local secondaryName = ZO_GetSecondaryPlayerName(displayName, characterName)
    return zo_strformat(SI_PLAYER_PRIMARY_AND_SECONDARY_NAME_FORMAT, primaryName, secondaryName)
end

function ZO_GetPrimaryPlayerNameHeader()
    if ZO_ShouldPreferUserId() then
        return ZO_GetPlatformAccountLabel()
    else
        return GetString(SI_SOCIAL_LIST_PANEL_HEADER_CHARACTER)
    end
end