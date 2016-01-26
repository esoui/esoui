function GetFinalGuildRankTextureSmall(guildId, rankIndex)
    local iconIndex = GetGuildRankIconIndex(guildId, rankIndex)
    return GetGuildRankSmallIcon(iconIndex)
end

function GetFinalGuildRankTextureLarge(guildId, rankIndex)
    local iconIndex = GetGuildRankIconIndex(guildId, rankIndex)
    return GetGuildRankLargeIcon(iconIndex)
end

function GetFinalGuildRankHighlight(guildId, rankIndex)
    local iconIndex = GetGuildRankIconIndex(guildId, rankIndex)
    return GetGuildRankListHighlightIcon(iconIndex)
end

function GetFinalGuildRankTextureListDown(guildId, rankIndex)
    local iconIndex = GetGuildRankIconIndex(guildId, rankIndex)
    return GetGuildRankListDownIcon(iconIndex)
end

function GetFinalGuildRankTextureListUp(guildId, rankIndex)
    local iconIndex = GetGuildRankIconIndex(guildId, rankIndex)
    return GetGuildRankListUpIcon(iconIndex)
end

function GetDefaultGuildRankName(guildId, rankIndex)
    local rankId = GetGuildRankId(guildId, rankIndex)
    return GetString("SI_GUILDRANKS", rankId)
end

function GetFinalGuildRankName(guildId, rankIndex)
    local customName = GetGuildRankCustomName(guildId, rankIndex)
    if(customName ~= "") then
        return customName
    else
        return GetDefaultGuildRankName(guildId, rankIndex)
    end
end