do
    local CHAMPION_CAP = GetMaxSpendableChampionPointsInAttribute() * 3
    function ZO_GetLevelOrChampionPointsStringNoIcon(level, championPoints)
        if championPoints and championPoints > 0 then
            if championPoints > CHAMPION_CAP then
                return tostring(CHAMPION_CAP)
            else
                return tostring(championPoints)
            end
        elseif level and level > 0 then
            return tostring(level)
        else
            return ""
        end
    end
end

function ZO_GetLevelOrChampionPointsNarrationString(level, championPoints)
    local levelString = ZO_GetLevelOrChampionPointsStringNoIcon(level, championPoints)
    if levelString ~= "" then
        if championPoints and championPoints > 0 then
            levelString = zo_strformat(SI_SCREEN_NARRATION_CHAMPION_LEVEL_FORMATTER, levelString)
        end
        return levelString
    end

    return ""
end

function ZO_GetChampionIconMarkupString(iconSize)
    if iconSize then
        local championIcon
        if IsInGamepadPreferredMode() then
            championIcon = ZO_GetGamepadChampionPointsIcon()
        else
            championIcon = ZO_GetChampionPointsIconSmall()
        end

        return zo_iconFormat(championIcon, iconSize, iconSize)
    end
end

function ZO_GetChampionIconMarkupStringInheritColor(iconSize)
    if iconSize then
        local championIcon
        if IsInGamepadPreferredMode() then
            championIcon = ZO_GetGamepadChampionPointsIcon()
        else
            championIcon = ZO_GetChampionPointsIconSmall()
        end

        return zo_iconFormatInheritColor(championIcon, iconSize, iconSize)
    end
end

function ZO_GetLevelOrChampionPointsString(level, championPoints, iconSize)
    local iconString = ""
    
    if championPoints and championPoints > 0 and iconSize then
        iconString = ZO_GetChampionIconMarkupString(iconSize)
    end
    
    return string.format("%s%s", iconString, ZO_GetLevelOrChampionPointsStringNoIcon(level, championPoints))
end

function ZO_GetLevelOrChampionPointsRangeString(minLevel, maxLevel, isChampionPoints, iconSize)
    local iconString = ""
    
    if isChampionPoints and iconSize then
        iconString = ZO_GetChampionIconMarkupString(iconSize)
    end

    return string.format("%s%s-%s", iconString, minLevel, maxLevel)
end
