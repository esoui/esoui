SLASH_COMMANDS = {}

if not IsConsoleUI() or IsInternalBuild() then
    SLASH_COMMANDS[GetString(SI_SLASH_SCRIPT)] = function (txt)
        local f = assert(zo_loadstring(txt))
        f()
    end
end

if not IsConsoleUI() then
    SLASH_COMMANDS[GetString(SI_SLASH_CHATLOG)] = function(txt)
        SetChatLogEnabled(not IsChatLogEnabled())

        if(IsChatLogEnabled()) then
            CHAT_SYSTEM:AddMessage(GetString(SI_CHAT_LOG_ENABLED))
        else
            CHAT_SYSTEM:AddMessage(GetString(SI_CHAT_LOG_DISABLED))
        end
    end
end


SLASH_COMMANDS[GetString(SI_SLASH_GROUP_INVITE)] = function(txt)
    GroupInviteByName(txt)
    CHAT_SYSTEM:AddMessage(zo_strformat(GetString("SI_GROUPINVITERESPONSE", GROUP_INVITE_RESPONSE_INVITED), txt))
    ZO_Menu_SetLastCommandWasFromMenu(false)
end

SLASH_COMMANDS[GetString(SI_SLASH_JUMP_TO_LEADER)] = function(txt)
    JumpToGroupLeader(txt)
end

SLASH_COMMANDS[GetString(SI_SLASH_JUMP_TO_GROUP_MEMBER)] = function(txt)
    JumpToGroupMember(txt)
end

SLASH_COMMANDS[GetString(SI_SLASH_JUMP_TO_FRIEND)] = function(txt)
    JumpToFriend(txt)
end

SLASH_COMMANDS[GetString(SI_SLASH_JUMP_TO_GUILD_MEMBER)] = function(txt)
    JumpToGuildMember(txt)
end

SLASH_COMMANDS[GetString(SI_SLASH_RELOADUI)] = function(txt)
    ReloadUI("ingame")
end

SLASH_COMMANDS[GetString(SI_SLASH_PLAYED_TIME)] = function(args)
    local playedTime = ZO_FormatTime(GetSecondsPlayed(), TIME_FORMAT_STYLE_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS)
    CHAT_SYSTEM:AddMessage(zo_strformat(SI_CHAT_MESSAGE_PLAYED_TIME, GetRawUnitName("player"), playedTime))
end

SLASH_COMMANDS[GetString(SI_SLASH_READY_CHECK)] = ZO_SendReadyCheck

SLASH_COMMANDS[GetString(SI_SLASH_DUEL_INVITE)] = function(txt)
    ChallengeTargetToDuel(txt)
end

function DoCommand(text)
    local command, arguments = zo_strmatch(text, "^(/%S+)%s?(.*)")

    ZO_Menu_SetLastCommandWasFromMenu(false)

    command = zo_strlower(command or "")

    local fn = SLASH_COMMANDS[command]
    
    if(fn)
    then
        fn(arguments or "")
    else
		if IsInternalBuild() then
			ExecuteChatCommand(text)
		else
			ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, SI_ERROR_INVALID_COMMAND)
		end
    end
end

function ShowGamepadHelpScreen()
    SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", "helpRootGamepad")
end

CHAT_SYSTEM:AddCommandPrefix('/', DoCommand)