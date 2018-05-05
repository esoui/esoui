
function ZO_SocialList_GetRowColors(data, selected)
    local textColor = data.online and ZO_SECOND_CONTRAST_TEXT or ZO_DISABLED_TEXT
    local iconColor = data.online and ZO_DEFAULT_ENABLED_COLOR or ZO_DISABLED_TEXT
    if(selected) then
        textColor = ZO_SELECTED_TEXT
        iconColor = ZO_SELECTED_TEXT
    end

    return textColor, iconColor
end

function ZO_SocialList_ColorRow(control, data, displayNameTextColor, iconColor, otherTextColor)
    local displayName = GetControl(control, "DisplayName")
    displayName:SetColor(displayNameTextColor:UnpackRGBA())

    if data.hasCharacter then
        local character = GetControl(control, "CharacterName")
        if character then
            character:SetColor(otherTextColor:UnpackRGBA())
        end

        local zone = GetControl(control, "Zone")
        zone:SetColor(otherTextColor:UnpackRGBA())        
        
        local champion = GetControl(control, "Champion")
        champion:SetColor(iconColor:UnpackRGBA())

        local level = GetControl(control, "Level")
        level:SetColor(otherTextColor:UnpackRGBA())

        local alliance = GetControl(control, "AllianceIcon")
        alliance:SetColor(iconColor:UnpackRGBA())

        local class = GetControl(control, "ClassIcon")
        class:SetColor(iconColor:UnpackRGBA())
    end
end

function ZO_SocialList_SetUpOnlineData(data, online, secsSinceLogoff)
    data.online = online
    data.secsSinceLogoff = online and -1 or secsSinceLogoff
    data.normalizedLogoffSort = online and -1 or ZO_NormalizeSecondsPositive(secsSinceLogoff)
    data.timeStamp = online and 0 or GetFrameTimeSeconds()
end

local KEYBOARD_FUNCTIONS =
{
    playerStatusIcon = GetPlayerStatusIcon,
    championPointsIcon = GetChampionPointsIconSmall,
    allianceIcon = GetAllianceSymbolIcon,
    classIcon = GetClassIcon,
}

local GAMEPAD_FUNCTIONS = 
{
    playerStatusIcon = GetGamepadPlayerStatusIcon,
    championPointsIcon = GetGamepadChampionPointsIcon,
    allianceIcon = GetLargeAllianceSymbolIcon,
    classIcon = GetGamepadClassIcon,
}

function ZO_SocialList_SharedSocialSetup(control, data, selected)
    local textureFunctions = IsInGamepadPreferredMode() and GAMEPAD_FUNCTIONS or KEYBOARD_FUNCTIONS

    local displayName = GetControl(control, "DisplayName")
    local characterName = GetControl(control, "CharacterName")
    local status = GetControl(control, "StatusIcon")
    local zone = GetControl(control, "Zone")
    local class = GetControl(control, "ClassIcon")
    local alliance = GetControl(control, "AllianceIcon")
    local level = GetControl(control, "Level")
    local champion = GetControl(control, "Champion")

    if displayName then
        displayName:SetText(ZO_FormatUserFacingDisplayName(data.displayName))
    end

    if status then
        status:SetTexture(textureFunctions.playerStatusIcon(data.status))
    end

    local hideCharacterFields = not data.hasCharacter or (zo_strlen(data.characterName) <= 0)
    if characterName then
        if not hideCharacterFields then
            characterName:SetText(ZO_FormatUserFacingCharacterName(data.characterName))
        else
            characterName:SetText("")
        end
    end
    zone:SetHidden(hideCharacterFields)
    class:SetHidden(hideCharacterFields)
    if alliance then
        alliance:SetHidden(hideCharacterFields)
    end
    level:SetHidden(hideCharacterFields)
    champion:SetHidden(hideCharacterFields)

    if data.hasCharacter then
        zone:SetText(data.formattedZone)

        level:SetText(GetLevelOrChampionPointsStringNoIcon(data.level, data.championPoints))

        if data.championPoints and data.championPoints > 0 then
            champion:SetTexture(textureFunctions.championPointsIcon())
        else
            champion:SetHidden(true)
        end

        if alliance then
            local allianceTexture = textureFunctions.allianceIcon(data.alliance)
            if allianceTexture then
                alliance:SetTexture(allianceTexture)
            else
                alliance:SetHidden(true)
            end
        end

        local classTexture = textureFunctions.classIcon(data.class)
        if classTexture  then
            class:SetTexture(classTexture)
        else
            class:SetHidden(true)
        end
    end
end