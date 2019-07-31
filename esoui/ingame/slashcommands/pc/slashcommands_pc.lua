local function DoLogout()
	Logout()
end

SLASH_COMMANDS[GetString(SI_SLASH_LOGOUT)] = function (txt)
    DoLogout()
end

SLASH_COMMANDS[GetString(SI_SLASH_CAMP)] = function (txt)
	DoLogout()
end

SLASH_COMMANDS[GetString(SI_SLASH_QUIT)] = function (txt)
	Quit()
end

SLASH_COMMANDS[GetString(SI_SLASH_FPS)] = function(txt)
    if GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_FRAMERATE) then
        SetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_FRAMERATE, "false")
    else
        SetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_FRAMERATE, "true")
    end
end

SLASH_COMMANDS[GetString(SI_SLASH_LATENCY)] = function(txt)
    if GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_LATENCY) then
        SetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_LATENCY, "false")
    else
        SetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_LATENCY, "true")
    end
end

SLASH_COMMANDS[GetString(SI_SLASH_STUCK)] = function(txt)
	if IsInGamepadPreferredMode() then
		ShowGamepadHelpScreen()
	else
		HELP_CUSTOMER_SUPPORT_KEYBOARD:OpenScreen(HELP_CUSTOMER_SERVICE_CHARACTER_STUCK_KEYBOARD_FRAGMENT)
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