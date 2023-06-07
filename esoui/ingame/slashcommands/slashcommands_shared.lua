SLASH_COMMANDS = {}

local function OutputSystemMessage(messageOrFormatter, ...)
    CHAT_ROUTER:AddSystemMessage(string.format(messageOrFormatter or "", ...))
end

if AreUserAddOnsSupported() or IsInternalBuild() then
    SLASH_COMMANDS[GetString(SI_SLASH_SCRIPT)] = function (txt)
        local f = assert(zo_loadstring(txt))
        f()
    end

    SLASH_COMMANDS[GetString(SI_SLASH_CHATLOG)] = function(txt)
        SetChatLogEnabled(not IsChatLogEnabled())

        if IsChatLogEnabled() then
            CHAT_ROUTER:AddSystemMessage(GetString(SI_CHAT_LOG_ENABLED))
        else
            CHAT_ROUTER:AddSystemMessage(GetString(SI_CHAT_LOG_DISABLED))
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
        CHAT_ROUTER:AddSystemMessage(line)
    end

    SLASH_COMMANDS[GetString(SI_SLASH_ENCOUNTER_LOG)] = function(args)
        if args == "format" then
            CHAT_ROUTER:AddSystemMessage(string.format("Encounter log version |cffffff%u|r documentation:", GetEncounterLogVersion()))
            CHAT_ROUTER:AddSystemMessage("All lines begin with the time in MS since logging began and the line type.")
            CHAT_ROUTER:AddSystemMessage("<unitState> refers to the following fields for a unit: unitId, health/max, magicka/max, stamina/max, ultimate/max, werewolf/max, shield, map NX, map NY, headingRadians.")
            CHAT_ROUTER:AddSystemMessage("<targetUnitState> is replaced with an asterisk if the source and target are the same.")
            CHAT_ROUTER:AddSystemMessage("<equipmentInfo> refers to the following fields for a piece of equipment: slot, id, isCP, level, trait, displayQuality, setId, enchantType, isEnchantCP, enchantLevel, enchantQuality.")
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
            PrintLineTypeInfo("EFFECT_INFO", "abilityId", "effectType", "statusEffectType", "effectBarDisplayBehaviour", "grantsSynergyAbilityId:optional")
            PrintLineTypeInfo("MAP_INFO", "id", "name", "texturePath")
            PrintLineTypeInfo("ZONE_INFO", "id", "name", "dungeonDifficulty")
            PrintLineTypeInfo("TRIAL_INIT", "id", "inProgress", "completed", "startTimeMS", "durationMS", "success", "finalScore")
            PrintLineTypeInfo("BEGIN_TRIAL", "id", "startTimeMS")
            PrintLineTypeInfo("END_TRIAL", "id", "durationMS", "success", "finalScore", "finalVitalityBonus")
        elseif args == "verbose" then
            if IsEncounterLogVerboseFormat() then
                CHAT_ROUTER:AddSystemMessage("Encounter log set to normal format.")
                SetEncounterLogVerboseFormat(false)
            else
                CHAT_ROUTER:AddSystemMessage("Encounter log set to verbose format.")
                SetEncounterLogVerboseFormat(true)
            end
        elseif args == "inline" then
            if IsEncounterLogAbilityInfoInline() then
                CHAT_ROUTER:AddSystemMessage("Encounter log ability info set to separate format.")
                SetEncounterLogAbilityInfoInline(false)
            else
                CHAT_ROUTER:AddSystemMessage("Encounter log ability info set to inline format.")
                SetEncounterLogAbilityInfoInline(true)
            end
        elseif args == "" then
            if IsEncounterLogEnabled() then
                CHAT_ROUTER:AddSystemMessage(GetString(SI_ENCOUNTER_LOG_DISABLED_ALERT))
                SetEncounterLogEnabled(false)
            else
                CHAT_ROUTER:AddSystemMessage(GetString(SI_ENCOUNTER_LOG_ENABLED_ALERT))
                SetEncounterLogEnabled(true)
            end
        else
            CHAT_ROUTER:AddSystemMessage("Options are:")
            CHAT_ROUTER:AddSystemMessage("|cffffffformat|r - print the format of each line type.")
            CHAT_ROUTER:AddSystemMessage("|cffffffverbose|r - toggle between the normal line format and a verbose format that names each field.")
            CHAT_ROUTER:AddSystemMessage("|cffffffinline|r - toggle between ability infomation being inline and in its own line.")
            CHAT_ROUTER:AddSystemMessage("|cffffff<nothing>|r - toggle the encounter log.")
        end
    end
end

SLASH_COMMANDS[GetString(SI_SLASH_GROUP_INVITE)] = function(txt)
    if txt == "" then
        CHAT_ROUTER:AddSystemMessage(zo_strformat(SI_GROUP_INVITE_REQUEST_EMPTY_MESSAGE, ZO_GetPlatformAccountLabel()))
    else
        GroupInviteByName(txt)
        CHAT_ROUTER:AddSystemMessage(zo_strformat(GetString("SI_GROUPINVITERESPONSE", GROUP_INVITE_RESPONSE_INVITED), txt))
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
    CHAT_ROUTER:AddSystemMessage(zo_strformat(SI_CHAT_MESSAGE_PLAYED_TIME, GetRawUnitName("player"), playedTime))
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
        HELP_CUSTOMER_SERVICE_ASK_FOR_HELP_KEYBOARD:OpenAskForHelp(CUSTOMER_SERVICE_ASK_FOR_HELP_IMPACT_REPORT_PLAYER, CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_CATEGORY_BAD_ACTIONS)
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

do
    local RANDOM_ROLL_COMMAND = GetString(SI_SLASH_ROLL)
    local RANDOM_ROLL_COMMAND_FORMATTED = string.format("|c88d8ff%s", RANDOM_ROLL_COMMAND)
    local RANDOM_ROLL_COMMAND_HELP_HINT = zo_strformat(SI_RANDOM_ROLL_HELP_HINT, string.format("%s ?|r", RANDOM_ROLL_COMMAND_FORMATTED))
    local RANDOM_ROLL_TEXTURE = zo_iconFormat("EsoUI/Art/Miscellaneous/roll_dice.dds")

    local g_savedVars = nil
    local function SetupSavedVars()
        local savedVarsDefaults = 
        {
            helpHintShown = nil,
        }
        local SAVED_VARS_VERSION = 1
        g_savedVars = ZO_SavedVars:NewAccountWide("ZO_Ingame_SavedVariables", SAVED_VARS_VERSION, "RandomRollCommand", savedVarsDefaults)
    end

    local function OutputCommandHelpHint()
        if g_savedVars and not g_savedVars.helpHintShown then
            CHAT_ROUTER:AddSystemMessage(RANDOM_ROLL_COMMAND_HELP_HINT)
            g_savedVars.helpHintShown = true
        end
    end

    function ZO_RandomRollCommand(args)
        if args then
            args = string.lower(args)
        else
            args = ""
        end

        if args == "?" then
            local characterNameParam = GetCharacterNameById(StringToId64(GetCurrentCharacterId()))
            CHAT_ROUTER:AddSystemMessage(GetString(SI_RANDOM_ROLL_HELP_HEADER))
            OutputSystemMessage("%s|r", RANDOM_ROLL_COMMAND_FORMATTED)
            OutputSystemMessage(" %s %s", RANDOM_ROLL_TEXTURE, zo_strformat(SI_RANDOM_ROLL_RANGE_RESULT, characterNameParam, ZO_SELECTED_TEXT:Colorize("44"), ZO_SELECTED_TEXT:Colorize("1"), ZO_SELECTED_TEXT:Colorize("100")))
            OutputSystemMessage("%s 50|r", RANDOM_ROLL_COMMAND_FORMATTED)
            OutputSystemMessage(" %s %s", RANDOM_ROLL_TEXTURE, zo_strformat(SI_RANDOM_ROLL_RANGE_RESULT, characterNameParam, ZO_SELECTED_TEXT:Colorize("39"), ZO_SELECTED_TEXT:Colorize("1"), ZO_SELECTED_TEXT:Colorize("50")))
            OutputSystemMessage("%s 2-12|r", RANDOM_ROLL_COMMAND_FORMATTED)
            OutputSystemMessage(" %s %s", RANDOM_ROLL_TEXTURE, zo_strformat(SI_RANDOM_ROLL_RANGE_RESULT, characterNameParam, ZO_SELECTED_TEXT:Colorize("7"), ZO_SELECTED_TEXT:Colorize("2"), ZO_SELECTED_TEXT:Colorize("12")))
            return
        end

        OutputCommandHelpHint()

        local result = nil
        if string.find(args, "d") then
            -- Match any of the following patterns and disregard ancillary whitespace:
            --  #d
            --  #d#
            --  #d#-#
            --  #d#+#

            local numRolls, maxRoll, modifier = zo_strmatch(args, "(%d*)%s*d%s*(%d*)%s*([+-]?%d*)")
            numRolls = tonumber(numRolls) or 1
            maxRoll = tonumber(maxRoll) or 6
            modifier = tonumber(modifier) or 0

            -- Underflow and overflow conditions must be checked prior to invoking the API.
            if numRolls > RANDOM_ROLL_MAX_NUM_ROLLS then
                result = RANDOM_ROLL_RESULT_INVALID_NUM_ROLLS
            elseif maxRoll < 1 or maxRoll > RANDOM_ROLL_MAX_RESULT or
                modifier < RANDOM_ROLL_MIN_RESULT or modifier > RANDOM_ROLL_MAX_RESULT then
                result = RANDOM_ROLL_RESULT_INVALID_RESULT
            else
                result = RandomDiceRoll(maxRoll, numRolls, modifier)
            end
        else
            -- Match any of the following patterns and disregard ancillary whitespace:
            --  #
            --  # #
            --  #-#

            local minValue, maxValue = zo_strmatch(args, "(%d*)%s*%-*%s*(%d*)")
            minValue = tonumber(minValue)
            maxValue = tonumber(maxValue)

            if not maxValue then
                -- Either zero or one arguments were received; assume the argument, if specified, is the maximum value.
                maxValue = minValue or 100
                minValue = 1 -- Default to a minimum value of 1.
            elseif not minValue then
                -- Only a maximum argument was received; default to a minimum value of 1.
                minValue = 1
            end

            if minValue < 1 or maxValue < 1 or minValue > RANDOM_ROLL_MAX_RESULT or maxValue > RANDOM_ROLL_MAX_RESULT then
                -- Check domain conditions prior to invoking the API.
                result = RANDOM_ROLL_RESULT_INVALID_RESULT
            else
                result = RandomRangeRoll(minValue, maxValue)
            end
        end

        if result ~= RANDOM_ROLL_RESULT_SUCCESS then
            CHAT_ROUTER:AddSystemMessage(GetString("SI_RANDOMROLLRESULT", result))
            OutputCommandHelpHint()
        end

        return result
    end

    SLASH_COMMANDS[RANDOM_ROLL_COMMAND] = ZO_RandomRollCommand

    local function OnRandomDiceRoll(_, displayName, characterName, maxValue, numRolls, modifier, rollResult)
        local playerName = ZO_GetPrimaryPlayerName(displayName, characterName)
        local maxValueParam = ZO_SELECTED_TEXT:Colorize(maxValue)
        local numRollsParam = ZO_SELECTED_TEXT:Colorize(numRolls)
        local rollResultParam = ZO_SELECTED_TEXT:Colorize(rollResult)

        local message
        if modifier ~= 0 then
            local modifierParam = ZO_SELECTED_TEXT:Colorize(string.format("%s%d", modifier > 0 and "+" or "-", zo_abs(modifier)))
            message = zo_strformat(SI_RANDOM_ROLL_DICE_WITH_MODIFIER_RESULT, playerName, rollResultParam, numRollsParam, maxValueParam, modifierParam)
        else
            message = zo_strformat(SI_RANDOM_ROLL_DICE_RESULT, playerName, rollResultParam, numRollsParam, maxValueParam)
        end

        OutputSystemMessage("%s %s", RANDOM_ROLL_TEXTURE, message)
    end

    local function OnRandomRangeRoll(_, displayName, characterName, minValue, maxValue, rollResult)
        local playerName = ZO_GetPrimaryPlayerName(displayName, characterName)
        local minValueParam = ZO_SELECTED_TEXT:Colorize(minValue)
        local maxValueParam = ZO_SELECTED_TEXT:Colorize(maxValue)
        local rollResultParam = ZO_SELECTED_TEXT:Colorize(rollResult)
        local message = zo_strformat(SI_RANDOM_ROLL_RANGE_RESULT, playerName, rollResultParam, minValueParam, maxValueParam)
        OutputSystemMessage("%s %s", RANDOM_ROLL_TEXTURE, message)
    end

    local function OnAddOnLoaded(_, addonName)
        if addonName == "ZO_Ingame" then
            EVENT_MANAGER:UnregisterForEvent("ZO_RandomRoll", EVENT_ADD_ON_LOADED)
            EVENT_MANAGER:RegisterForEvent("ZO_RandomRoll", EVENT_RANDOM_DICE_ROLL, OnRandomDiceRoll)
            EVENT_MANAGER:RegisterForEvent("ZO_RandomRoll", EVENT_RANDOM_RANGE_ROLL, OnRandomRangeRoll)
            SetupSavedVars()
        end
    end

    EVENT_MANAGER:RegisterForEvent("ZO_RandomRoll", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
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

CHAT_ROUTER:AddCommandPrefix('/', DoCommand)