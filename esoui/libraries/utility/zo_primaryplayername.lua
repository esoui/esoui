function ZO_GetPrimaryPlayerNamePreference()
    local setting = UI_SETTING_PRIMARY_PLAYER_NAME_PC
    if ZO_IsConsoleOrGameCoreUI() then
        setting = UI_SETTING_PRIMARY_PLAYER_NAME_CONSOLE
    end

    return tonumber(GetSetting(SETTING_TYPE_UI, setting))
end

function ZO_GetPrimarySecondaryAndTertiaryPlayerNames(crossplayDisplayName, characterName, platformDisplayName, dontUseFormatting)
    local primaryName = nil
    local secondaryName = nil
    local tertiaryName = nil

    local formattedCharacterName = dontUseFormatting and characterName or ZO_FormatUserFacingCharacterName(characterName)
    local formattedPlatformDisplayName = nil
    local hasPlatformDisplayName = platformDisplayName and platformDisplayName ~= ""
    if hasPlatformDisplayName then
        formattedPlatformDisplayName = dontUseFormatting and platformDisplayName or ZO_FormatPlatformDisplayName(platformDisplayName)
    end

    local namePreference = ZO_GetPrimaryPlayerNamePreference()
    if namePreference == PRIMARY_PLAYER_NAME_SETTING_PREFER_CROSSPLAY then
        primaryName = crossplayDisplayName
        if hasPlatformDisplayName then
            secondaryName = formattedPlatformDisplayName
            tertiaryName = formattedCharacterName
        else
            secondaryName = formattedCharacterName
        end
    elseif namePreference == PRIMARY_PLAYER_NAME_SETTING_PREFER_PLATFORM then
        if hasPlatformDisplayName then






            primaryName = formattedPlatformDisplayName
            secondaryName = formattedCharacterName

        else
            primaryName = crossplayDisplayName
            secondaryName = formattedCharacterName
        end
    elseif namePreference == PRIMARY_PLAYER_NAME_SETTING_PREFER_CHARACTER then
        primaryName = formattedCharacterName
        if hasPlatformDisplayName then





            secondaryName = formattedPlatformDisplayName

        else
            secondaryName = crossplayDisplayName
        end
    end

    return primaryName, secondaryName, tertiaryName
end

function ZO_GetPrimarySecondaryAndTertiaryPlayerNamesForUnitTag(unitTag, dontUseFormatting)
    local crossplayDisplayName = GetUnitDisplayName(unitTag)
    local characterName = GetUnitName(unitTag)
    local platformDisplayName = GetUnitPlatformDisplayName(unitTag)
    return ZO_GetPrimarySecondaryAndTertiaryPlayerNames(crossplayDisplayName, characterName, platformDisplayName, dontUseFormatting)
end

function ZO_TryGetPlatformDisplayNameForUnitTag(unitTag, dontUseFormatting)
    local platformDisplayName = GetUnitPlatformDisplayName(unitTag)
    if platformDisplayName == "" then
        -- if a unit doesn't have a PlatformDisplayName fall back to the CrossplayDisplayName/DisplayName
        return GetUnitDisplayName(unitTag)
    end

    return dontUseFormatting and platformDisplayName or ZO_FormatPlatformDisplayName(platformDisplayName)
end

function ZO_GetPrimaryPlayerNameFromUnitTag(unitTag, dontUseFormatting)
    local namePreference = ZO_GetPrimaryPlayerNamePreference()
    if namePreference == PRIMARY_PLAYER_NAME_SETTING_PREFER_CROSSPLAY then
        return GetUnitDisplayName(unitTag)
    elseif namePreference == PRIMARY_PLAYER_NAME_SETTING_PREFER_PLATFORM then
        return ZO_TryGetPlatformDisplayNameForUnitTag(unitTag, dontUseFormatting)
    elseif namePreference == PRIMARY_PLAYER_NAME_SETTING_PREFER_CHARACTER then
        local characterName = GetUnitName(unitTag)
        return ZO_FormatUserFacingCharacterName(characterName)
    end
end

function ZO_GetSecondaryPlayerNameFromUnitTag(unitTag, dontUseFormatting)
    local namePreference = ZO_GetPrimaryPlayerNamePreference()
    if namePreference == PRIMARY_PLAYER_NAME_SETTING_PREFER_CHARACTER then
        return ZO_TryGetPlatformDisplayNameForUnitTag(unitTag, dontUseFormatting)
    end

    local characterName = GetUnitName(unitTag)
    return ZO_FormatUserFacingCharacterName(characterName)
end

function ZO_GetSecondaryPlayerNameWithTitleFromUnitTag(unitTag)
    local name = ZO_GetSecondaryPlayerNameFromUnitTag(unitTag)
    local title = GetUnitTitle(unitTag)
    if title ~= "" then
        return zo_strformat(SI_PLAYER_NAME_WITH_TITLE_FORMAT, name, title)
    end
    return name
end

function ZO_GetSecondaryPlayerNameWithTertiaryAndTitleFromUnitTag(unitTag)
    local primaryName, secondaryName, tertiaryName = ZO_GetPrimarySecondaryAndTertiaryPlayerNamesForUnitTag(unitTag)
    if tertiaryName ~= nil then
        local title = GetUnitTitle(unitTag)
        if title ~= "" then
            return zo_strformat(SI_TARGET_PLAYER_SECONDARY_AND_TERTIARY_NAME_WITH_TITLE_FORMAT, secondaryName, tertiaryName, title)
        end
        return zo_strformat(SI_TARGET_PLAYER_SECONDARY_AND_TERTIARY_NAME_FORMAT, secondaryName, tertiaryName)
    end

    return ZO_GetSecondaryPlayerNameWithTitleFromUnitTag(unitTag)
end

function ZO_TryGetPlatformDisplayName(crossplayDisplayName, platformDisplayName, dontUseFormatting)
    if platformDisplayName == nil or platformDisplayName == "" then
        -- if we don't have a PlatformDisplayName fall back to the CrossplayDisplayName/DisplayName




        return dontUseFormatting and crossplayDisplayName or ZO_FormatUserFacingDisplayName(crossplayDisplayName)

    end

    return dontUseFormatting and platformDisplayName or ZO_FormatPlatformDisplayName(platformDisplayName)
end

function ZO_GetPrimaryPlayerName(crossplayDisplayName, characterName, platformDisplayName, dontUseFormatting)
    local namePreference = ZO_GetPrimaryPlayerNamePreference()
    if namePreference == PRIMARY_PLAYER_NAME_SETTING_PREFER_CROSSPLAY then
        return crossplayDisplayName
    elseif namePreference == PRIMARY_PLAYER_NAME_SETTING_PREFER_PLATFORM then
        return ZO_TryGetPlatformDisplayName(crossplayDisplayName, platformDisplayName, dontUseFormatting)
    elseif namePreference == PRIMARY_PLAYER_NAME_SETTING_PREFER_CHARACTER then
        return dontUseFormatting and characterName or ZO_FormatUserFacingCharacterName(characterName)
    end
end

function ZO_GetSecondaryPlayerName(crossplayDisplayName, characterName, platformDisplayName, dontUseFormatting)
    local namePreference = ZO_GetPrimaryPlayerNamePreference()
    if namePreference == PRIMARY_PLAYER_NAME_SETTING_PREFER_CHARACTER then
        return ZO_TryGetPlatformDisplayName(crossplayDisplayName, platformDisplayName, dontUseFormatting)
    end

    return dontUseFormatting and characterName or ZO_FormatUserFacingCharacterName(characterName)
end

function ZO_GetPrimaryPlayerNameWithSecondary(crossplayDisplayName, characterName, platformDisplayName)
    local primaryName = ZO_GetPrimaryPlayerName(crossplayDisplayName, characterName, platformDisplayName)
    local secondaryName = ZO_GetSecondaryPlayerName(crossplayDisplayName, characterName, platformDisplayName)
    return zo_strformat(SI_PLAYER_PRIMARY_AND_SECONDARY_NAME_FORMAT, primaryName, secondaryName)
end

function ZO_GetPrimaryPlayerNameWithSecondaryFromUnitTag(unitTag)
    local crossplayDisplayName = GetUnitDisplayName(unitTag)
    local characterName = GetUnitName(unitTag)
    local platformDisplayName = GetUnitPlatformDisplayName(unitTag)
    return ZO_GetPrimaryPlayerNameWithSecondary(crossplayDisplayName, characterName, platformDisplayName)
end

function ZO_GetPrimaryPlayerNameWithSecondaryAndTertiary(crossplayDisplayName, characterName, platformDisplayName)
    local primaryName, secondaryName, tertiaryName = ZO_GetPrimarySecondaryAndTertiaryPlayerNames(crossplayDisplayName, characterName, platformDisplayName)

    if tertiaryName == nil then
        return zo_strformat(SI_PLAYER_PRIMARY_AND_SECONDARY_NAME_FORMAT, primaryName, secondaryName)
    end

    return zo_strformat(SI_PLAYER_PRIMARY_SECONDARY_AND_TERTIARY_NAME_FORMAT, primaryName, secondaryName, tertiaryName)
end

function ZO_GetPrimaryPlayerNameWithSecondaryAndTertiaryFromUnitTag(unitTag)
    local crossplayDisplayName = GetUnitDisplayName(unitTag)
    local characterName = GetUnitName(unitTag)
    local platformDisplayName = GetUnitPlatformDisplayName(unitTag)
    return ZO_GetPrimaryPlayerNameWithSecondaryAndTertiary(crossplayDisplayName, characterName, platformDisplayName)
end

-- TODO Crossplay: move away from using this function
function ZO_ShouldPreferUserId()
    return ZO_GetPrimaryPlayerNamePreference() ~= PRIMARY_PLAYER_NAME_SETTING_PREFER_CHARACTER
end

-- TODO Crossplay: Update or reimplement
function ZO_GetPrimaryPlayerNameHeader()
    if ZO_ShouldPreferUserId() then
        return ZO_GetPlatformAccountLabel()
    else
        return GetString(SI_SOCIAL_LIST_PANEL_HEADER_CHARACTER)
    end
end