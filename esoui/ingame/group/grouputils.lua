local function CompleteGroupInvite(characterOrDisplayName, sentFromChat, displayInvitedMessage)
    local isLeader = IsUnitGroupLeader("player")
    local groupSize = GetGroupSize()
    
    if isLeader and groupSize == SMALL_GROUP_SIZE_THRESHOLD then
        ZO_Dialogs_ShowPlatformDialog("LARGE_GROUP_INVITE_WARNING", characterOrDisplayName, { mainTextParams = { SMALL_GROUP_SIZE_THRESHOLD } })
    else
        GroupInviteByName(characterOrDisplayName)

        ZO_Menu_SetLastCommandWasFromMenu(not sentFromChat)
        if displayInvitedMessage then
            ZO_Alert(ALERT, nil, zo_strformat(GetString("SI_GROUPINVITERESPONSE", GROUP_INVITE_RESPONSE_INVITED), ZO_FormatUserFacingDisplayName(characterOrDisplayName)))
        end
    end
end

function TryGroupInviteByName(characterOrDisplayName, sentFromChat, displayInvitedMessage)
    if IsPlayerInGroup(characterOrDisplayName) then
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, SI_GROUP_ALERT_INVITE_PLAYER_ALREADY_MEMBER)
        return
    end

    local isLeader = IsUnitGroupLeader("player")
    local groupSize = GetGroupSize()

    if not isLeader and groupSize > 0 then
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, GetString("SI_GROUPINVITERESPONSE", GROUP_INVITE_RESPONSE_ONLY_LEADER_CAN_INVITE))
        return
    end

    if IsConsoleUI() then
        local displayName = characterOrDisplayName

        local function GroupInviteCallback(success)
            if success then
                CompleteGroupInvite(displayName, sentFromChat, displayInvitedMessage)
            end
        end

        ZO_ConsoleAttemptInteractOrError(GroupInviteCallback, displayName, ZO_PLAYER_CONSOLE_INFO_REQUEST_DONT_BLOCK, ZO_CONSOLE_CAN_COMMUNICATE_ERROR_ALERT, ZO_ID_REQUEST_TYPE_DISPLAY_NAME, displayName)
    else
        if IsIgnored(characterOrDisplayName) then
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, SI_GROUP_ALERT_INVITE_PLAYER_BLOCKED)
            return
        end

        CompleteGroupInvite(characterOrDisplayName, sentFromChat, displayInvitedMessage)
    end    
end

function ZO_ConvertToDungeonDifficulty(isVeteranDifficulty)
    if isVeteranDifficulty then
        return DUNGEON_DIFFICULTY_VETERAN
    else
        return DUNGEON_DIFFICULTY_NORMAL
    end
end

function ZO_ConvertToIsVeteranDifficulty(dungeonDifficulty)
    return dungeonDifficulty == DUNGEON_DIFFICULTY_VETERAN
end

function ZO_GetGroupDungeonDifficulty()
    return ZO_ConvertToDungeonDifficulty(IsGroupUsingVeteranDifficulty())
end

function ZO_GetPlayerDungeonDifficulty()
    return ZO_ConvertToDungeonDifficulty(IsUnitUsingVeteranDifficulty("player"))
end

function ZO_GetEffectiveDungeonDifficulty()
    if IsUnitGrouped("player") then
        return ZO_GetGroupDungeonDifficulty()
    else
        return ZO_GetPlayerDungeonDifficulty()
    end
end