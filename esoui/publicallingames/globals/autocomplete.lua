local g_currentPlayerName
local g_currentPlayerUserId

function ZO_AutoComplete.IncludeOrExcludeResult(results, result, include)
    if result ~= g_currentPlayerName and result ~= g_currentPlayerUserId then
        local lowerResult = zo_strlower(result)
        if include then
            results[lowerResult] = result
        else
            results[lowerResult] = nil
        end
    end
end

AUTO_COMPLETE_FLAG_FRIEND = ZO_AutoComplete.AddFlag(function(results, input, onlineOnly, include)
    for i = 1, GetNumFriends() do
        local displayName, _, playerStatus = GetFriendInfo(i)
        if not onlineOnly or playerStatus ~= PLAYER_STATUS_OFFLINE then
            --No @ symbols and no character names on console
            ZO_AutoComplete.IncludeOrExcludeResult(results, ZO_FormatUserFacingDisplayName(displayName), include)

            if not IsConsoleUI() then
                local hasCharacter, characterName = GetFriendCharacterInfo(i)
                if hasCharacter then
                    ZO_AutoComplete.IncludeOrExcludeResult(results, zo_strformat("<<1>>", characterName), include)
                end
            end
        end
    end
end)

AUTO_COMPLETE_FLAG_GUILD = ZO_AutoComplete.AddFlag(function(results, input, onlineOnly, include)
    for i = 1, GetNumGuilds() do
        local guildId = GetGuildId(i)
        local numMembers = GetNumGuildMembers(guildId)
        for memberIndex = 1, numMembers do
            local displayName, _, _, playerStatus = GetGuildMemberInfo(guildId, memberIndex)
            if not onlineOnly or playerStatus ~= PLAYER_STATUS_OFFLINE then
                --No @ symbols and no character names on console
                ZO_AutoComplete.IncludeOrExcludeResult(results, ZO_FormatUserFacingDisplayName(displayName), include)

                if not IsConsoleUI() then
                    local hasCharacter, characterName = GetGuildMemberCharacterInfo()
                    if hasCharacter then
                        ZO_AutoComplete.IncludeOrExcludeResult(results, zo_strformat("<<1>>", characterName), include)
                    end
                end
            end
        end
    end
end)

local function OnPlayerActivated()
    g_currentPlayerName = GetUnitName("player")
    g_currentPlayerUserId = GetDisplayName()
    EVENT_MANAGER:UnregisterForEvent("AutoCompleteAllIngames", EVENT_PLAYER_ACTIVATED)
end

EVENT_MANAGER:RegisterForEvent("AutoCompleteAllIngames", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
