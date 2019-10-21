SLASH_COMMANDS = {}

if AreUserAddOnsSupported() or IsInternalBuild() then
    SLASH_COMMANDS[GetString(SI_SLASH_SCRIPT)] = function (txt)
        local f = assert(zo_loadstring(txt))
        f()
    end

    SLASH_COMMANDS[GetString(SI_SLASH_CHATLOG)] = function(txt)
        SetChatLogEnabled(not IsChatLogEnabled())

        if IsChatLogEnabled() then
            CHAT_SYSTEM:AddMessage(GetString(SI_CHAT_LOG_ENABLED))
        else
            CHAT_SYSTEM:AddMessage(GetString(SI_CHAT_LOG_DISABLED))
        end
    end

    local function PrintLineTypeInfo(lineType, ...)
        local line = string.format("|cffffff%s|r", lineType)
        local numFields = select("#", ...)
        if numFields > 0 then
            line = line .. " - "
            for i = 1, numFields do
                if i > 1 then
                    line = line .. ", "
                end

                local field = select(i, ...)
                line = line .. field
            end
        end
        CHAT_SYSTEM:AddMessage(line)
    end

    SLASH_COMMANDS[GetString(SI_SLASH_ENCOUNTER_LOG)] = function(args)
        if args == "format" then
            CHAT_SYSTEM:AddMessage(string.format("Encounter log version |cffffff%u|r documentation:", GetEncounterLogVersion()))
            CHAT_SYSTEM:AddMessage("All lines begin with the time in MS since logging began and the line type.")
            CHAT_SYSTEM:AddMessage("<unitState> refers to the following fields for a unit: unitId, health/max, magicka/max, stamina/max, ultimate/max, werewolf/max, shield, map NX, map NY, headingRadians.")
            CHAT_SYSTEM:AddMessage("<targetUnitState> is replaced with an asterisk if the source and target are the same.")
            CHAT_SYSTEM:AddMessage("<equipmentInfo> refers to the following fields for a piece of equipment: slot, id, isCP, level, trait, quality, setId, enchantType, isEnchantCP, enchantLevel, enchantQuality.")
            PrintLineTypeInfo("BEGIN_LOG", "timeSinceEpochMS", "logVersion", "realmName", "language", "gameVersion")
            PrintLineTypeInfo("END_LOG")
            PrintLineTypeInfo("BEGIN_COMBAT")
            PrintLineTypeInfo("END_COMBAT")
            PrintLineTypeInfo("PLAYER_INFO", "unitId", "[longTermEffectAbilityId,...]", "[longTermEffectStackCounts,...]", "[<equipmentInfo>,...]", "[primaryAbilityId,...]", "[backupAbilityId,...]")
            PrintLineTypeInfo("BEGIN_CAST", "durationMS", "channeled", "castTrackId", "abilityId", "<sourceUnitState>", "<targetUnitState>")
            PrintLineTypeInfo("END_CAST", "endReason", "castTrackId", "interruptingAbilityId:optional", "interruptingUnitId:optional")
            PrintLineTypeInfo("COMBAT_EVENT", "actionResult", "damageType", "powerType", "hitValue", "overflow", "castTrackId", "abilityId", "<sourceUnitState>", "<targetUnitState>")
            PrintLineTypeInfo("HEALTH_REGEN", "effectiveRegen", "<unitState>")
            PrintLineTypeInfo("UNIT_ADDED", "unitId", "unitType", "isLocalPlayer", "playerPerSessionId", "monsterId", "isBoss", "classId", "raceId", "name", "displayName", "characterId", "level", "championPoints", "ownerUnitId", "reaction", "isGroupedWithLocalPlayer")
            PrintLineTypeInfo("UNIT_CHANGED", "unitId", "classId", "raceId", "name", "displayName", "characterId", "level", "championPoints", "ownerUnitId", "reaction", "isGroupedWithLocalPlayer")
            PrintLineTypeInfo("UNIT_REMOVED", "unitId")
            PrintLineTypeInfo("EFFECT_CHANGED", "changeType", "stackCount", "castTrackId", "abilityId", "<sourceUnitState>", "<targetUnitState>", "playerInitiatedRemoveCastTrackId:optional")
            PrintLineTypeInfo("ABILITY_INFO", "abilityId", "name", "iconPath", "interruptible", "blockable")
            PrintLineTypeInfo("EFFECT_INFO", "abilityId", "effectType", "statusEffectType", "noEffectBar", "grantsSynergyAbilityId:optional")
            PrintLineTypeInfo("MAP_INFO", "id", "name", "texturePath")
            PrintLineTypeInfo("ZONE_INFO", "id", "name", "dungeonDifficulty")
            PrintLineTypeInfo("TRIAL_INIT", "id", "inProgress", "completed", "startTimeMS", "durationMS", "success", "finalScore")
            PrintLineTypeInfo("BEGIN_TRIAL", "id", "startTimeMS")
            PrintLineTypeInfo("END_TRIAL", "id", "durationMS", "success", "finalScore", "finalVitalityBonus")
        elseif args == "verbose" then
            if IsEncounterLogVerboseFormat() then
                CHAT_SYSTEM:AddMessage("Encounter log set to normal format.")
                SetEncounterLogVerboseFormat(false)
            else
                CHAT_SYSTEM:AddMessage("Encounter log set to verbose format.")
                SetEncounterLogVerboseFormat(true)
            end
        elseif args == "inline" then
            if IsEncounterLogAbilityInfoInline() then
                CHAT_SYSTEM:AddMessage("Encounter log ability info set to separate format.")
                SetEncounterLogAbilityInfoInline(false)
            else
                CHAT_SYSTEM:AddMessage("Encounter log ability info set to inline format.")
                SetEncounterLogAbilityInfoInline(true)
            end
        elseif args == "" then
            if IsEncounterLogEnabled() then
                CHAT_SYSTEM:AddMessage(GetString(SI_ENCOUNTER_LOG_DISABLED_ALERT))
                SetEncounterLogEnabled(false)
            else
                CHAT_SYSTEM:AddMessage(GetString(SI_ENCOUNTER_LOG_ENABLED_ALERT))
                SetEncounterLogEnabled(true)
            end
        else
            CHAT_SYSTEM:AddMessage("Options are:")
            CHAT_SYSTEM:AddMessage("|cffffffformat|r - print the format of each line type.")
            CHAT_SYSTEM:AddMessage("|cffffffverbose|r - toggle between the normal line format and a verbose format that names each field.")
            CHAT_SYSTEM:AddMessage("|cffffffinline|r - toggle between ability infomation being inline and in its own line.")
            CHAT_SYSTEM:AddMessage("|cffffff<nothing>|r - toggle the encounter log.")
        end
    end
end

SLASH_COMMANDS[GetString(SI_SLASH_GROUP_INVITE)] = function(txt)
    if txt == "" then
        CHAT_SYSTEM:AddMessage(zo_strformat(SI_GROUP_INVITE_REQUEST_EMPTY_MESSAGE, ZO_GetPlatformAccountLabel()))
    else
        GroupInviteByName(txt)
        CHAT_SYSTEM:AddMessage(zo_strformat(GetString("SI_GROUPINVITERESPONSE", GROUP_INVITE_RESPONSE_INVITED), txt))
        ZO_Menu_SetLastCommandWasFromMenu(false)
    end
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

SLASH_COMMANDS[GetString(SI_SLASH_LOGOUT)] = function (txt)
    Logout()
end

SLASH_COMMANDS[GetString(SI_SLASH_CAMP)] = function (txt)
    Logout()
end

local function ShowGamepadHelpScreen()
    SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", "helpRootGamepad")
end

SLASH_COMMANDS[GetString(SI_SLASH_STUCK)] = function(txt)
    if IsInGamepadPreferredMode() then
        ShowGamepadHelpScreen()
    else
        HELP_CUSTOMER_SUPPORT_KEYBOARD:OpenScreen(HELP_CUSTOMER_SERVICE_CHARACTER_STUCK_KEYBOARD_FRAGMENT)
    end
end

SLASH_COMMANDS[GetString(SI_SLASH_REPORT_HELP)] = function(args)
    if IsInGamepadPreferredMode() then
        ShowGamepadHelpScreen()
    else
        HELP_CUSTOMER_SERVICE_ASK_FOR_HELP_KEYBOARD:OpenAskForHelp()
    end
end

SLASH_COMMANDS[GetString(SI_SLASH_REPORT_CHAT)] = function(args)
    if IsInGamepadPreferredMode() then
        ShowGamepadHelpScreen()
    else
        HELP_CUSTOMER_SERVICE_ASK_FOR_HELP_KEYBOARD:OpenAskForHelp(CUSTOMER_SERVICE_ASK_FOR_HELP_CATEGORY_REPORT_PLAYER, CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_HARASSMENT)
    end
end

if IsSubmitFeedbackSupported() then
    SLASH_COMMANDS[GetString(SI_SLASH_REPORT_BUG)] = function(args)
        if IsInGamepadPreferredMode() then
            ShowGamepadHelpScreen()
        else
            HELP_CUSTOMER_SUPPORT_KEYBOARD:OpenScreen(HELP_CUSTOMER_SERVICE_SUBMIT_FEEDBACK_KEYBOARD_FRAGMENT)
        end
    end

    SLASH_COMMANDS[GetString(SI_SLASH_REPORT_FEEDBACK)] = function(args)
        if IsInGamepadPreferredMode() then
            ShowGamepadHelpScreen()
        else
            HELP_CUSTOMER_SUPPORT_KEYBOARD:OpenScreen(HELP_CUSTOMER_SERVICE_SUBMIT_FEEDBACK_KEYBOARD_FRAGMENT)
            HELP_CUSTOMER_SERVICE_SUBMIT_FEEDBACK_KEYBOARD:ClearFields()
        end
    end
end


function DoCommand(text)
    local command, arguments = zo_strmatch(text, "^(/%S+)%s?(.*)")

    ZO_Menu_SetLastCommandWasFromMenu(false)

    command = zo_strlower(command or "")

    local fn = SLASH_COMMANDS[command]
    
    if fn then
        fn(arguments or "")
    else
        if IsInternalBuild() then
            ExecuteChatCommand(text)
        else
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, SI_ERROR_INVALID_COMMAND)
        end
    end
end

CHAT_SYSTEM:AddCommandPrefix('/', DoCommand)