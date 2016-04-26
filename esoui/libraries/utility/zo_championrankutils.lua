function GetLevelOrChampionPointsStringNoIcon(level, championPoints)
    if championPoints and championPoints > 0 then
        return tostring(championPoints)
    elseif level and level > 0 then
        return tostring(level)
    else
        return ""
    end
end

function GetChampionIconMarkupString(iconSize)
    if iconSize then
        return zo_iconFormat(GetChampionPointsIcon(), iconSize, iconSize)
    end
end

function GetLevelOrChampionPointsString(level, championPoints, iconSize)
    local iconString = ""
    
    if championPoints and championPoints > 0 and iconSize then
        iconString = iconString..GetChampionIconMarkupString(iconSize)
    end
    
    return iconString.GetLevelOrChampionPointsStringNoIcon(level, championPoints)
end
    
