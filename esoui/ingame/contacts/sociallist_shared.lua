
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

    if(data.hasCharacter) then
        local zone = GetControl(control, "Zone")
        zone:SetColor(otherTextColor:UnpackRGBA())        
        
        local veteran = GetControl(control, "Veteran")
        veteran:SetColor(iconColor:UnpackRGBA())

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
    veteranRankIcon = GetVeteranRankIcon,
    allianceIcon = GetAllianceSymbolIcon,
    classIcon = GetClassIcon,
}

local GAMEPAD_FUNCTIONS = 
{
    playerStatusIcon = GetGamepadPlayerStatusIcon,
    veteranRankIcon = GetGamepadVeteranRankIcon,
    allianceIcon = GetLargeAllianceSymbolIcon,
    classIcon = GetGamepadClassIcon,
}

function ZO_SocialList_SharedSocialSetup(control, data, selected)
    local textureFunctions = IsInGamepadPreferredMode() and GAMEPAD_FUNCTIONS or KEYBOARD_FUNCTIONS

    local displayName = GetControl(control, "DisplayName")
    local status = GetControl(control, "StatusIcon")
    local zone = GetControl(control, "Zone")
    local class = GetControl(control, "ClassIcon")
    local alliance = GetControl(control, "AllianceIcon")
    local level = GetControl(control, "Level")
    local veteran = GetControl(control, "Veteran")

    if displayName then
        displayName:SetText(ZO_FormatUserFacingDisplayName(data.displayName))
    end

    if status then
        status:SetTexture(textureFunctions.playerStatusIcon(data.status))
    end

    local hideCharacterFields = not data.hasCharacter or (zo_strlen(data.characterName) <= 0)
    zone:SetHidden(hideCharacterFields)
    class:SetHidden(hideCharacterFields)
    if alliance then
        alliance:SetHidden(hideCharacterFields)
    end
    level:SetHidden(hideCharacterFields)
    veteran:SetHidden(hideCharacterFields)

    if(data.hasCharacter) then
        zone:SetText(data.formattedZone)

        level:SetText(GetLevelOrVeteranRankStringNoIcon(data.level, data.veteranRank))

        if data.veteranRank and data.veteranRank > 0 then
            veteran:SetTexture(textureFunctions.veteranRankIcon())
        else
            veteran:SetHidden(true)
        end

        if alliance then
            local allianceTexture = textureFunctions.allianceIcon(data.alliance)
            if(allianceTexture) then
                alliance:SetTexture(allianceTexture)
            else
                alliance:SetHidden(true)
            end
        end

        local classTexture = textureFunctions.classIcon(data.class)
        if(classTexture) then
            class:SetTexture(classTexture)
        else
            class:SetHidden(true)
        end
    end
end