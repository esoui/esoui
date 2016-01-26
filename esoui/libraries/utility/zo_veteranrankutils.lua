function GetLevelOrVeteranRankStringNoIcon(level, veteranRank)
    if veteranRank and veteranRank > 0 then
        return tostring(veteranRank)
    elseif level and level > 0 then
        return tostring(level)
    else
        return ""
    end
end

function GetVeteranIconMarkupString(iconSize)
    if iconSize then
        return zo_iconFormat(GetVeteranRankIcon(), iconSize, iconSize)
    end
end

function GetLevelOrVeteranRankString(level, veteranRank, iconSize)
    local iconString = ""
    
    if veteranRank and veteranRank > 0 and iconSize then
        iconString = iconString..GetVeteranIconMarkupString(iconSize)
    end
    
    return iconString..GetLevelOrVeteranRankStringNoIcon(level, veteranRank)
end
    
