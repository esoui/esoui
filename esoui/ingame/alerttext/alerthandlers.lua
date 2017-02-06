local playerName = GetRawUnitName("player")
local currentGroupLeaderRawName = GetRawUnitName(GetGroupLeaderUnitTag())
local currentGroupLeaderDisplayName = GetUnitDisplayName(GetGroupLeaderUnitTag())

local ERROR = UI_ALERT_CATEGORY_ERROR
local ALERT = UI_ALERT_CATEGORY_ALERT

local CombatEventToSoundId =
{
    [ACTION_RESULT_ABILITY_ON_COOLDOWN] = SOUNDS.ABILITY_NOT_READY,
    [ACTION_RESULT_TARGET_OUT_OF_RANGE] = SOUNDS.ABILITY_TARGET_OUT_OF_RANGE,
	[ACTION_RESULT_TARGET_NOT_IN_VIEW] = SOUNDS.ABILITY_TARGET_OUT_OF_LOS,
    [ACTION_RESULT_CANT_SEE_TARGET] = SOUNDS.ABILITY_TARGET_OUT_OF_LOS,
	[ACTION_RESULT_IMMUNE] = SOUNDS.ABILITY_TARGET_IMMUNE,
    [ACTION_RESULT_SILENCED] = SOUNDS.ABILITY_CASTER_SILENCED,
    [ACTION_RESULT_STUNNED] = SOUNDS.ABILITY_CASTER_STUNNED,
	[ACTION_RESULT_BUSY] = SOUNDS.ABILITY_CASTER_BUSY,
    [ACTION_RESULT_BAD_TARGET] = SOUNDS.ABILITY_TARGET_BAD_TARGET,
    [ACTION_RESULT_TARGET_DEAD] = SOUNDS.ABILITY_TARGET_DEAD,
    [ACTION_RESULT_CASTER_DEAD] = SOUNDS.ABILITY_CASTER_DEAD,
    [ACTION_RESULT_INSUFFICIENT_RESOURCE] =
    {
        [POWERTYPE_STAMINA] = SOUNDS.ABILITY_NOT_ENOUGH_STAMINA,
        [POWERTYPE_MAGICKA] = SOUNDS.ABILITY_NOT_ENOUGH_MAGICKA,
        [POWERTYPE_HEALTH] = SOUNDS.ABILITY_NOT_ENOUGH_HEALTH,
        [POWERTYPE_ULTIMATE] = SOUNDS.ABILITY_NOT_ENOUGH_ULTIMATE,
    },
    [ACTION_RESULT_FAILED] = SOUNDS.ABILITY_FAILED,
    [ACTION_RESULT_IN_COMBAT] = SOUNDS.ABILITY_FAILED_IN_COMBAT,
    [ACTION_RESULT_FAILED_REQUIREMENTS] = SOUNDS.ABILITY_FAILED_REQUIREMENTS,
    [ACTION_RESULT_FEARED] = SOUNDS.ABILITY_CASTER_FEARED,
    [ACTION_RESULT_DISORIENTED] = SOUNDS.ABILITY_CASTER_DISORIENTED,
    [ACTION_RESULT_TARGET_TOO_CLOSE] = SOUNDS.ABILITY_TARGET_TOO_CLOSE,
    [ACTION_RESULT_WRONG_WEAPON] = SOUNDS.ABILITY_WRONG_WEAPON,
    [ACTION_RESULT_TARGET_NOT_PVP_FLAGGED] = SOUNDS.ABILITY_TARGET_NOT_PVP_FLAGGED,
    [ACTION_RESULT_PACIFIED] = SOUNDS.ABILITY_CASTER_PACIFIED,
    [ACTION_RESULT_LEVITATED] = SOUNDS.ABILITY_CASTER_LEVITATED,
    [ACTION_RESULT_REINCARNATING] = SOUNDS.NONE,
    [ACTION_RESULT_RECALLING] = SOUNDS.ABILITY_NOT_READY,
    [ACTION_RESULT_NO_WEAPONS_TO_SWAP_TO] = SOUNDS.ABILITY_WEAPON_SWAP_FAIL,
    [ACTION_RESULT_CANT_SWAP_WHILE_CHANGING_GEAR] = SOUNDS.ABILITY_WEAPON_SWAP_FAIL,
    [ACTION_RESULT_MOUNTED] = SOUNDS.ABILITY_NOT_READY,
    [ACTION_RESULT_INVALID_JUSTICE_TARGET] = SOUNDS.ABILITY_INVALID_JUSTICE_TARGET,
    [ACTION_RESULT_NOT_ENOUGH_INVENTORY_SPACE] = SOUNDS.NEGATIVE_CLICK,
    [ACTION_RESULT_IN_HIDEYHOLE] = SOUNDS.ABILITY_CASTER_STUNNED,
}

local ExperienceReasonToSoundId =
{
    [PROGRESS_REASON_OVERLAND_BOSS_KILL] = SOUNDS.OVERLAND_BOSS_KILL,
    [PROGRESS_REASON_SCRIPTED_EVENT] = SOUNDS.SCRIPTED_EVENT_COMPLETION,
}

local TrialEventMappings = 
{
    [TRIAL_RESTRICTION_CANNOT_USE_GUILDS] = true,
}

local GroupElectionResultToSoundId =
{
    [GROUP_ELECTION_RESULT_ELECTION_WON] = SOUNDS.GROUP_ELECTION_RESULT_WON,
    [GROUP_ELECTION_RESULT_ELECTION_LOST] = SOUNDS.GROUP_ELECTION_RESULT_LOST,
    [GROUP_ELECTION_RESULT_ABANDONED] = SOUNDS.GROUP_ELECTION_RESULT_LOST,
}

ZO_GroupElectionResultToAlertTextOverrides =
{
    [GROUP_ELECTION_RESULT_ELECTION_WON] =
    {
        [ZO_GROUP_ELECTION_DESCRIPTORS.READY_CHECK] = GetString(SI_GROUP_ELECTION_READY_CHECK_PASSED),
    },
    [GROUP_ELECTION_RESULT_ELECTION_LOST] =
    {
        [ZO_GROUP_ELECTION_DESCRIPTORS.READY_CHECK] = GetString(SI_GROUP_ELECTION_READY_CHECK_FAILED),
    },
}

ZO_GroupElectionDescriptorToRequestAlertText =
{
    [ZO_GROUP_ELECTION_DESCRIPTORS.NONE] = GetString(SI_GROUP_ELECTION_REQUESTED),
    [ZO_GROUP_ELECTION_DESCRIPTORS.READY_CHECK] = GetString(SI_GROUP_ELECTION_READY_CHECK_REQUESTED),
}
--Return format is
--  Category - The alert category to send the alert to
--  Message - The message to alert
--  SoundId (Optional) - An optional sound id to play along with the message

--If Category or Message is nil, then nothing will be shown. Simply not returning anything tells the system to not do anything.

local AlertHandlers = {
    [EVENT_COMBAT_EVENT] = function(result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log)
        if playerName == sourceName then
            local soundId = CombatEventToSoundId[result]
            if type(soundId) == "table" then
                soundId = soundId[powerType]
            end
            local message = GetString("SI_ACTIONRESULT", result)

            if(log and message ~= "") then
                return ERROR, zo_strformat(message), soundId
            elseif(soundId ~= nil) then
                return ERROR, nil, soundId
            end
        end
    end,

    [EVENT_EXPERIENCE_UPDATE] = function(unitTag, exp, maxExp, reason)
        if(unitTag == "player") then
            local soundId = ExperienceReasonToSoundId[reason]
            if(soundId) then
                return ALERT, nil, soundId
            end
        end
    end,

    [EVENT_REQUIREMENTS_FAIL] = function(errorStringId)
        local message = GetErrorString(errorStringId)
        if(message ~= "") then
            return ERROR, message, SOUNDS.GENERAL_FAILED_REQUIREMENTS
        end
    end,

    [EVENT_ABILITY_REQUIREMENTS_FAIL] = function(errorStringId)
        local message = GetErrorString(errorStringId)
        if(message ~= "") then
            return ERROR, message, SOUNDS.ABILITY_FAILED_REQUIREMENTS
        end
    end,

    [EVENT_UI_ERROR] = function(stringId)
        return ERROR, GetString(stringId), SOUNDS.GENERAL_ALERT_ERROR
    end,
    
    [EVENT_ITEM_ON_COOLDOWN] = function()
        return ERROR, GetString(SI_ITEM_FORMAT_STR_ON_COOLDOWN), SOUNDS.ITEM_ON_COOLDOWN
    end,

    [EVENT_COLLECTIBLE_USE_RESULT] = function(result, isAttemptingActivation)
        if result == COLLECTIBLE_USAGE_BLOCK_REASON_NOT_BLOCKED then
            local sound = isAttemptingActivation and SOUNDS.COLLECTIBLE_ACTIVATED or SOUNDS.COLLECTIBLE_DEACTIVATED
            PlaySound(sound)
        else
            local sound = (result == COLLECTIBLE_USAGE_BLOCK_REASON_ON_COOLDOWN) and SOUNDS.COLLECTIBLE_ON_COOLDOWN or SOUNDS.GENERAL_ALERT_ERROR
            return ERROR, zo_strformat(GetString("SI_COLLECTIBLEUSAGEBLOCKREASON", result)), sound
        end
    end,

    [EVENT_SOCIAL_ERROR] = function(error)
        if(error ~= SOCIAL_RESULT_NO_ERROR and not IsSocialErrorIgnoreResponse(error)) then
            if(ShouldShowSocialErrorInAlert(error)) then
                return ERROR, zo_strformat(GetString("SI_SOCIALACTIONRESULT", error)), SOUNDS.GENERAL_ALERT_ERROR
            end
        end
    end,

    [EVENT_SIEGE_CREATION_FAILED_CLOSEST_DOOR_ALREADY_HAS_RAM] = function()
        return ERROR, GetString(SI_SIEGE_CREATION_FAILED_CLOSEST_DOOR_ALREADY_HAS_RAM), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_SIEGE_CREATION_FAILED_NO_VALID_DOOR] = function()
        return ERROR, GetString(SI_SIEGE_CREATION_FAILED_NO_VALID_DOOR), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_SIEGE_PACK_FAILED_INVENTORY_FULL] = function()
        return ERROR, GetString(SI_INVENTORY_ERROR_INVENTORY_FULL), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_SIEGE_PACK_FAILED_NOT_CREATOR] = function()
        return ERROR, GetString(SI_SIEGE_PACK_FAILED_NOT_CREATOR), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_SIEGE_BUSY] = function(siegeName)
        return ERROR, zo_strformat(SI_SIEGE_BUSY, siegeName), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_SIEGE_FIRE_FAILED_COOLDOWN] = function()
        return ERROR, GetString(SI_SIEGE_FIRE_FAILED_COOLDOWN)
    end,

    [EVENT_SIEGE_FIRE_FAILED_RETARGETING] = function()
        return ERROR, GetString(SI_SIEGE_FIRE_FAILED_RETARGETING)
    end,

    [EVENT_SIEGE_CONTROL_ANOTHER_PLAYER] = function(siegeName)
        return ERROR, zo_strformat(SI_SIEGE_CONTROL_ANOTHER_PLAYER, siegeName)
    end,

    [EVENT_CANNOT_DO_THAT_WHILE_DEAD] = function()
        return ERROR, GetString(SI_CANNOT_DO_THAT_WHILE_DEAD), SOUNDS.GENERAL_ALERT_ERROR
    end,

	[EVENT_CANNOT_CROUCH_WHILE_CARRYING_ARTIFACT] = function(artifactName)
		return ERROR, zo_strformat(GetString(SI_CANNOT_CROUCH_WHILE_CARRYING_ARTIFACT), artifactName), SOUNDS.GENERAL_ALERT_ERROR
	end,

    [EVENT_NOT_ENOUGH_MONEY] = function()
        return ERROR, GetString(SI_NOT_ENOUGH_MONEY), SOUNDS.PLAYER_ACTION_INSUFFICIENT_GOLD
    end,

    [EVENT_TRADE_FAILED] = function(reason)
        return ERROR, GetString("SI_TRADEACTIONRESULT", reason), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_TRADE_ITEM_ADD_FAILED] = function(reason, itemName)
        return ERROR, zo_strformat(GetString("SI_TRADEACTIONRESULT", reason), itemName), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_TRADE_ELEVATION_FAILED] = function(reason, itemName)
        return ERROR, zo_strformat(GetString("SI_TRADEACTIONRESULT", reason), itemName), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_SLOT_IS_LOCKED_FAILURE] = function()
        return ERROR, GetString(SI_ERROR_ITEM_LOCKED), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_MAIL_SEND_FAILED] = function(reason)
        if reason ~= MAIL_SEND_RESULT_CANCELED then
            return ERROR, zo_strformat(SI_MAIL_SEND_FAIL, GetString("SI_SENDMAILRESULT", reason)), SOUNDS.GENERAL_ALERT_ERROR
        end
    end,

    [EVENT_RESURRECT_RESULT] = function(targetCharacterName, reason, targetDisplayName)
        if reason ~= RESURRECT_RESULT_SUCCESS then
            local nameToShow = ZO_GetPrimaryPlayerName(targetDisplayName, targetCharacterName)
            if reason ~= RESURRECT_RESULT_DECLINED then
                return ERROR, zo_strformat(GetString("SI_RESURRECTRESULT", reason), nameToShow), SOUNDS.GENERAL_ALERT_ERROR
            else
                return ALERT, zo_strformat(GetString("SI_RESURRECTRESULT", reason), nameToShow)
            end
        end
    end,

	[EVENT_SOUL_GEM_ITEM_CHARGE_FAILURE] = function(reason)
		return ERROR, GetString("SI_SOULGEMITEMCHARGINGREASON", reason)
	end,

	[EVENT_ITEM_REPAIR_FAILURE] = function(reason)
		return ERROR, GetString("SI_ITEMREPAIRREASON", reason)
	end,

	[EVENT_MOUNT_FAILURE] = function(reason, arg1)
		return ERROR, zo_strformat(GetString("SI_MOUNTFAILUREREASON", reason), arg1), SOUNDS.GENERAL_ALERT_ERROR
	end,

    [EVENT_STORE_FAILURE] = function(reason)
        return ERROR, GetString("SI_STOREFAILURE", reason), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_HOT_BAR_RESULT] = function(reason)
        return ERROR, GetString("SI_HOTBARRESULT", reason), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_ABILITY_PROGRESSION_RESULT] = function(reason)
        return ERROR, GetString("SI_ABILITYPROGRESSIONRESULT", reason)
    end,

    [EVENT_INTERACT_BUSY] = function()
        return ERROR, GetString(SI_INTERACT_BUSY), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_LORE_BOOK_ALREADY_KNOWN] = function(bookTitle)
        return ERROR, zo_strformat(SI_LORE_LIBRARY_ALREADY_KNOW_BOOK, bookTitle)
    end,

    [EVENT_INTERACTABLE_LOCKED] = function(interactableName)
        return ERROR, zo_strformat(SI_LOCKPICK_NO_KEY_AND_NO_LOCK_PICKS, interactableName), SOUNDS.LOCKPICKING_NO_LOCKPICKS
    end,

    [EVENT_INTERACTABLE_IMPOSSIBLE_TO_PICK] = function(interactableName)
        return ERROR, zo_strformat(SI_LOCKPICK_IMPOSSIBLE_LOCK, interactableName), SOUNDS.LOCKPICKING_NO_LOCKPICKS
    end,

    [EVENT_MISSING_LURE] = function()
        return ERROR, GetString(SI_MISSING_LURE_OR_BAIT), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_CANNOT_FISH_WHILE_SWIMMING] = function()
        return ERROR, GetString(SI_CANNOT_FISH_WHILE_SWIMMING), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_GROUP_INVITE_RESPONSE] = function(characterName, response, displayName)
        if(response ~= GROUP_INVITE_RESPONSE_ACCEPTED and response ~= GROUP_INVITE_RESPONSE_CONSIDERING_OTHER and response ~= GROUP_INVITE_RESPONSE_IGNORED) then
            if(ShouldShowGroupErrorInAlert(response)) then
                local nameToUse = ZO_GetPrimaryPlayerName(displayName, characterName)
                if nameToUse == "" then
                    nameToUse = ZO_GetSecondaryPlayerName(displayName, characterName)
                end

                local alertMessage = nameToUse ~= "" and zo_strformat(GetString("SI_GROUPINVITERESPONSE", response), nameToUse) or GetString(SI_PLAYER_BUSY)

                return ALERT, alertMessage, SOUNDS.GENERAL_ALERT_ERROR
            end
        end
    end,

    [EVENT_GROUP_INVITE_ACCEPT_RESPONSE_TIMEOUT] = function()
        return ERROR, GetString("SI_GROUPINVITERESPONSE", GROUP_INVITE_RESPONSE_GENERIC_JOIN_FAILURE), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_GROUP_NOTIFICATION_MESSAGE] = function(groupMessageCode)
        if groupMessageCode == GROUP_MSG_YOU_ARE_NOT_IN_A_GROUP then
            return ERROR, GetString(SI_GROUP_NOTIFICATION_YOU_ARE_NOT_IN_A_GROUP), SOUNDS.GENERAL_ALERT_ERROR
        elseif groupMessageCode == GROUP_MSG_YOU_ARE_NOT_THE_LEADER then
            return ERROR, GetString(SI_GROUP_NOTIFICATION_YOU_ARE_NOT_THE_LEADER), SOUNDS.GENERAL_ALERT_ERROR
        elseif groupMessageCode == GROUP_MSG_INVALID_MEMBER then
            return ERROR, GetString(SI_GROUP_NOTIFICATION_GROUP_MSG_INVALID_MEMBER), SOUNDS.GENERAL_ALERT_ERROR
        end
    end,

    [EVENT_GROUP_UPDATE] = function()
        currentGroupLeaderRawName = ""
        currentGroupLeaderDisplayName = ""
    end,

    [EVENT_GROUP_MEMBER_LEFT] = function(characterName, reason, isLocalPlayer, isLeader, displayName, actionRequiredVote)
        local message = nil
        local sound = nil
        
        local primaryNameToShow = ZO_GetPrimaryPlayerName(displayName, characterName)
        local secondaryNameToShow = ZO_GetSecondaryPlayerName(displayName, characterName)
        local hasValidNames = primaryNameToShow ~= "" and secondaryNameToShow ~= ""
        local useDefaultReasonText = false
        if reason == GROUP_LEAVE_REASON_DISBAND then
            if isLeader and not isLocalPlayer then
                useDefaultReasonText = true
            end

            sound = SOUNDS.GROUP_DISBAND
        elseif reason == GROUP_LEAVE_REASON_KICKED then
            if actionRequiredVote then
                if isLocalPlayer then
                    message = SI_GROUP_ELECTION_KICK_PLAYER_PASSED
                elseif hasValidNames then
                    message = zo_strformat(SI_GROUP_ELECTION_KICK_MEMBER_PASSED, primaryNameToShow, secondaryNameToShow)
                end
            else
                if isLocalPlayer then
                    message = zo_strformat(SI_GROUP_NOTIFICATION_GROUP_SELF_KICKED)
                else
                    useDefaultReasonText = true
                end
            end

            sound = SOUNDS.GROUP_KICK
        elseif reason == GROUP_LEAVE_REASON_VOLUNTARY then
            if not isLocalPlayer then
                useDefaultReasonText = true
            end

            sound = SOUNDS.GROUP_LEAVE
        elseif reason == GROUP_LEAVE_REASON_DESTROYED then
            --do nothing, we don't want to show additional alerts for this case
        end

        if useDefaultReasonText and hasValidNames then
            message = zo_strformat(GetString("SI_GROUPLEAVEREASON", reason), primaryNameToShow, secondaryNameToShow)
        end

        if isLocalPlayer then
            currentGroupLeaderRawName = ""
            currentGroupLeaderDisplayName = ""
        end

        return ALERT, message, sound
    end,

    -- This event only fires if the characterId of the leader has changed (it's a new leader)
    [EVENT_LEADER_UPDATE] = function(leaderTag)
        local leaderRawName = GetRawUnitName(leaderTag)
        local showAlert = leaderRawName ~= "" and currentGroupLeaderRawName ~= ""
        currentGroupLeaderRawName = leaderRawName
        currentGroupLeaderDisplayName = GetUnitDisplayName(leaderTag)

        local leaderNameToShow = ZO_GetPrimaryPlayerName(currentGroupLeaderDisplayName, currentGroupLeaderRawName)

        if showAlert then
            return ALERT, zo_strformat(SI_GROUP_NOTIFICATION_GROUP_LEADER_CHANGED, leaderNameToShow), SOUNDS.GROUP_PROMOTE
        end
    end,

    [EVENT_GROUPING_TOOLS_LFG_JOINED] = function(locationName)
        return ALERT, zo_strformat(SI_GROUPING_TOOLS_ALERT_LFG_JOINED, locationName), nil
    end,

    [EVENT_ACTIVITY_QUEUE_RESULT] = function(result)
        if result ~= ACTIVITY_QUEUE_RESULT_SUCCESS then
            return ERROR, GetString("SI_ACTIVITYQUEUERESULT", result), SOUNDS.GENERAL_ALERT_ERROR
        end
    end,

    [EVENT_COLLECTIBLE_RENAME_ERROR] = function(errorReason)
        return ERROR, GetString("SI_NAMINGERROR", errorReason), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_COLLECTIBLE_SET_IN_WATER_ALERT] = function()
        return ALERT, GetString(SI_COLLECTIONS_SET_IN_WATER_ALERT)
    end,

    [EVENT_TRADE_INVITE_FAILED] = function(errorReason, inviteeCharacterName, inviteeDisplayName)
        if errorReason == TRADE_ACTION_RESULT_IGNORING_YOU then
            ZO_AlertEvent(EVENT_TRADE_INVITE_WAITING, inviteeCharacterName, inviteeDisplayName)
        else
            return ALERT, GetString("SI_TRADEACTIONRESULT", errorReason), SOUNDS.GENERAL_ALERT_ERROR
        end
    end,

    [EVENT_TRADE_INVITE_CONSIDERING] = function(inviterCharacterName, inviterDisplayName)
        local name = ZO_GetPrimaryPlayerName(inviterDisplayName, inviterCharacterName)
        return ALERT, zo_strformat(SI_TRADE_INVITE, name)
    end,

    [EVENT_TRADE_INVITE_WAITING] = function(inviteeCharacterName, inviteeDisplayName)
        local name = ZO_GetPrimaryPlayerName(inviteeDisplayName, inviteeCharacterName)
        return ALERT, zo_strformat(SI_TRADE_INVITE_CONFIRM, name)
    end,

    [EVENT_TRADE_INVITE_DECLINED] = function()
        return ALERT, GetString(SI_TRADE_INVITE_DECLINE), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_TRADE_INVITE_CANCELED] = function()
        return ALERT, GetString(SI_TRADE_CANCEL_INVITE), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_TRADE_CANCELED] = function()
        return ALERT, GetString(SI_TRADE_CANCELED), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_TRADE_FAILED] = function()
        return ALERT, GetString(SI_TRADE_FAILED), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_TRADE_SUCCEEDED] = function()
        return ALERT, GetString(SI_TRADE_COMPLETE)
    end,

    [EVENT_DISCOVERY_EXPERIENCE] = function(subzoneName, level, previousExperience, currentExperience, rank, previousPoints, currentPoints)
        if(INTERACT_WINDOW:IsShowingInteraction()) then
            return ALERT, zo_strformat(SI_SUBZONE_NOTIFICATION_DISCOVER_WHILE_IN_CONVERSATION, subzoneName), SOUNDS.OBJECTIVE_DISCOVERED
        end
    end,

    [EVENT_TRADING_HOUSE_ERROR] =   function(errorCode)
                                        if(errorCode == TRADING_HOUSE_RESULT_CANT_SELL_FOR_OVER_MAX_AMOUNT) then
                                            return ERROR, zo_strformat(GetString("SI_TRADINGHOUSERESULT", errorCode), MAX_PLAYER_MONEY), SOUNDS.GENERAL_ALERT_ERROR
                                        else
                                            return ERROR, GetString("SI_TRADINGHOUSERESULT", errorCode), SOUNDS.GENERAL_ALERT_ERROR
                                        end
                                    end,

    [EVENT_GUILD_BANK_OPEN_ERROR] = function(errorCode)
        return ERROR, GetString("SI_GUILDBANKRESULT", errorCode), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_GUILD_BANK_TRANSFER_ERROR] = function(errorCode)
        local text = GetString("SI_GUILDBANKRESULT", errorCode)
        if(errorCode == GUILD_BANK_GUILD_TOO_SMALL) then
            local numMembers = GetNumGuildMembersRequiredForPrivilege(GUILD_PRIVILEGE_BANK_DEPOSIT)
            text = zo_strformat(text, numMembers)
        end

        return ERROR, text, SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_GUILD_KIOSK_ERROR] = function(errorCode)
        local text = GetString("SI_GUILDKIOSKRESULT", errorCode)
        if(errorCode == GUILD_KIOSK_GUILD_TOO_SMALL) then
            local numMembers = GetNumGuildMembersRequiredForPrivilege(GUILD_PRIVILEGE_TRADING_HOUSE)
            text = zo_strformat(text, numMembers)
        end

        return ERROR, text, SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_GUILD_SELF_LEFT_GUILD] = function(guildId, guildName)
		if(ShouldDisplaySelfKickedFromGuildAlert(guildId)) then
			return ALERT, zo_strformat(SI_GUILD_SELF_KICKED_FROM_GUILD, guildName), SOUNDS.GENERAL_ALERT_ERROR
		end
		
        return ALERT, nil, SOUNDS.GUILD_SELF_LEFT
    end,

    [EVENT_PLEDGE_OF_MARA_RESULT] = function(result, characterName, displayName)
        if(result ~= PLEDGE_OF_MARA_RESULT_PLEDGED and result ~= PLEDGE_OF_MARA_RESULT_BEGIN_PLEDGE) then
            local userFacingDisplayName = ZO_GetPrimaryPlayerName(displayName, characterName)
            return ERROR, zo_strformat(GetString("SI_PLEDGEOFMARARESULT", result), userFacingDisplayName), SOUNDS.GENERAL_ALERT_ERROR
        end
    end,

	[EVENT_TRAIT_LEARNED] = function(itemName, traitName)
        if not SYSTEMS:IsShowing("alchemy") then
            return ALERT, zo_strformat(SI_NEW_TRAIT_UNLOCKED, itemName, traitName)
        end
    end,

    [EVENT_STYLE_LEARNED] = function(styleIndex, chapterIndex, isDefaultRacialStyle)
        if not isDefaultRacialStyle then
            local itemStyle = select(5, GetSmithingStyleItemInfo(styleIndex))
		    if chapterIndex == ITEM_STYLE_CHAPTER_ALL then
			    return ALERT, zo_strformat(SI_NEW_STYLE_LEARNED, GetString("SI_ITEMSTYLE", itemStyle))
	        else
			    return ALERT, zo_strformat(SI_NEW_STYLE_CHAPTER_LEARNED, GetString("SI_ITEMSTYLE", itemStyle), GetString("SI_ITEMSTYLECHAPTER", chapterIndex))
		    end
        end
    end,

    [EVENT_SMITHING_TRAIT_RESEARCH_COMPLETED] = function(craftingSkillType, researchLineIndex, traitIndex)
        local researchLineName = GetSmithingResearchLineInfo(craftingSkillType, researchLineIndex)
        local traitType = GetSmithingResearchLineTraitInfo(craftingSkillType, researchLineIndex, traitIndex)
        return ALERT, zo_strformat(SI_FINISHED_SMITHING_TRAIT_RESEARCH, GetString("SI_ITEMTRAITTYPE", traitType), researchLineName), SOUNDS.SMITHING_FINISH_RESEARCH
    end,

    [EVENT_RECIPE_LEARNED] = function(recipeListIndex, recipeIndex)
        local _, name = GetRecipeInfo(recipeListIndex, recipeIndex)
        return ALERT, zo_strformat(SI_NEW_RECIPE_LEARNED, name), SOUNDS.RECIPE_LEARNED
    end,

    [EVENT_PLAYER_ACTIVATED] = function()
        if DoesCurrentZoneAllowScalingByLevel() and IsUnitGrouped("player") then
            local isChampionBattleLeveled = IsUnitChampionBattleLeveled("player")
            if isChampionBattleLeveled then
                local level = GetUnitChampionBattleLevel("player")
                return ALERT, zo_strformat(SI_ENTERED_SCALED_ZONE, level)
            end
        end
    end,

    [EVENT_ZONE_CHANGED] = function(zoneName, subzoneName)
         if(subzoneName ~= "") then
            return ALERT, zo_strformat(SI_ALERTTEXT_LOCATION_FORMAT, subzoneName)
        elseif(zoneName ~= "") then
            return ALERT, zo_strformat(SI_ALERTTEXT_LOCATION_FORMAT, zoneName)
        end
    end,

    [EVENT_GROUP_VETERAN_DIFFICULTY_CHANGED] = function(isVeteranDifficulty)
        if isVeteranDifficulty then
            return ALERT, GetString(SI_DUNGEON_DIFFICULTY_CHANGED_TO_VETERAN), SOUNDS.DUNGEON_DIFFICULTY_VETERAN
        else
            return ALERT, GetString(SI_DUNGEON_DIFFICULTY_CHANGED_TO_NORMAL), SOUNDS.DUNGEON_DIFFICULTY_NORMAL
        end
    end,

    [EVENT_LOGOUT_DISALLOWED] = function(quitGame)
        if(not quitGame) then
            return ERROR, GetString(SI_LOGOUT_DISALLOWED), SOUNDS.GENERAL_ALERT_ERROR
        end
    end,

    [EVENT_JUSTICE_BEING_ARRESTED] = function(quitGame)
        local logOutDialogOpen = ZO_Dialogs_FindDialog("LOG_OUT")
        ZO_Dialogs_ReleaseAllDialogs(true)   
        if(logOutDialogOpen or quitGame) then
            return ERROR, GetString(SI_JUSTICE_LOGOUT_DISALLOWED), SOUNDS.GENERAL_ALERT_ERROR
        end         
    end,

    [EVENT_JUMP_FAILED] = function(result)
        if result ~= JUMP_RESULT_JUMP_FAILED_ZONE_COLLECTIBLE then -- this result is handled in a dialog
            return ALERT, GetString("SI_JUMPRESULT", result)
        end
    end,

    [EVENT_RECIPE_ALREADY_KNOWN] = function(result)
        return ALERT, GetString(SI_RECIPE_ALREADY_KNOWN), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_SCREENSHOT_SAVED] = function(directory, filename)
        return ALERT, zo_strformat(SI_SCREENSHOT_SAVED, directory)
    end,

    [EVENT_INVENTORY_IS_FULL] = function(numSlotsRequested, numSlotsFree)
        if numSlotsRequested == 1 then
            TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_FULL)
            return ERROR, GetString(SI_INVENTORY_ERROR_INVENTORY_FULL), SOUNDS.GENERAL_ALERT_ERROR
        else
            return ERROR, zo_strformat(SI_INVENTORY_ERROR_INSUFFICIENT_SPACE, numSlotsRequested - numSlotsFree), SOUNDS.GENERAL_ALERT_ERROR
        end
    end,

    [EVENT_BANK_IS_FULL] = function()
        return ERROR, GetString(SI_INVENTORY_ERROR_BANK_FULL), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_QUEST_LOG_IS_FULL] = function()
        return ERROR, GetString(SI_ERROR_QUEST_LOG_FULL), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_MOUSE_REQUEST_DESTROY_ITEM_FAILED] = function(bagId, slotIndex, itemCount, name, reason)
        local reasonString = GetString("SI_MOUSEDESTROYITEMFAILEDREASON", reason)
        if reasonString ~= "" then
            return ERROR, reasonString, SOUNDS.GENERAL_ALERT_ERROR
        end
    end,

    [EVENT_PLAYER_DEAD] = function()
        local isAVADeath, isBattleGroundDeath = select(6, GetDeathInfo())
		local isDuelingDeath = IsDuelingDeath()
        if(not (isAVADeath or isBattleGroundDeath or isDuelingDeath)) then
            return ALERT, GetString(SI_DEATH_DURABILITY_ANNOUNCEMENT)
        end
    end,

    [EVENT_INPUT_LANGUAGE_CHANGED] = function()
        return ALERT, zo_strformat(SI_ALERT_INPUT_LANGUAGE_CHANGE, GetKeyboardLayout()), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_CAMPAIGN_ASSIGNMENT_RESULT] = function(result)
        local resultString = GetString("SI_CAMPAIGNREASSIGNMENTERRORREASON", result)
        if resultString ~= "" then
            return ERROR, resultString, SOUNDS.GENERAL_ALERT_ERROR
        end
    end,

    [EVENT_CAMPAIGN_UNASSIGNMENT_RESULT] = function(result)
        local resultString = GetString("SI_UNASSIGNCAMPAIGNRESULT", result)
        if resultString ~= "" then
            return ERROR, zo_strformat(resultString), SOUNDS.GENERAL_ALERT_ERROR
        end
    end,

    [EVENT_QUEUE_FOR_CAMPAIGN_RESPONSE] = function(response)
        local responseString = GetString("SI_QUEUEFORCAMPAIGNRESPONSETYPE", response)
        if responseString ~= "" then
            return ERROR, responseString, SOUNDS.GENERAL_ALERT_ERROR
        end
    end,

    [EVENT_JUSTICE_BOUNTY_PAYOFF_AMOUNT_UPDATED] = function(oldBounty, newBounty)
        if (newBounty > oldBounty) then
            TriggerTutorial(TUTORIAL_TRIGGER_BOUNTY_ADDED)
            return ALERT, zo_strformat(SI_JUSTICE_BOUNTY_ADDED, newBounty - oldBounty)
        elseif (newBounty == 0 and oldBounty ~= 0) then
            return ALERT, zo_strformat(SI_JUSTICE_BOUNTY_CLEARED)
        else
            return ALERT, zo_strformat(SI_JUSTICE_BOUNTY_SET, newBounty)
        end
    end,

    [EVENT_JUSTICE_GOLD_REMOVED] = function(goldAmount)
        PlaySound(SOUNDS.JUSTICE_GOLD_REMOVED)
    end,

    [EVENT_JUSTICE_STOLEN_ITEMS_REMOVED] = function()
        PlaySound(SOUNDS.JUSTICE_ITEM_REMOVED)
    end,

    [EVENT_JUSTICE_GOLD_PICKPOCKETED] = function(goldAmount)
        return ALERT, zo_strformat(SI_JUSTICE_GOLD_PICKPOCKETED, goldAmount)
    end,

    [EVENT_JUSTICE_PICKPOCKET_FAILED] = function()
        return ALERT, zo_strformat(SI_JUSTICE_PICKPOCKET_FAILED), SOUNDS.JUSTICE_PICKPOCKET_FAILED
    end,

    [EVENT_LOOT_RECEIVED] = function(receivedBy, itemName, quantity, itemSound, lootType, receivedBySelf, isPickpocketLoot)
        if(receivedBySelf and isPickpocketLoot) then
             return ALERT, zo_strformat(SI_JUSTICE_ITEM_PICKPOCKETED, GetItemLinkName(itemName), quantity)
        end
    end,

    [EVENT_DYE_STAMP_USE_FAIL] = function(reason)
        if reason ~= DYE_STAMP_USE_RESULT_NONE then
            return ALERT, GetString("SI_DYESTAMPUSERESULT", reason)
        end
    end,

    [EVENT_SAVE_GUILD_RANKS_RESPONSE] = function(guildId, result)
        if result ~= SOCIAL_RESULT_NO_ERROR then
            return ERROR, GetString("SI_SOCIALACTIONRESULT", result), SOUNDS.GENERAL_ALERT_ERROR
        end
    end,

    [EVENT_PICKPOCKET_TOO_FAR] = function()
        return ERROR, GetString(SI_PICKPOCKET_TOO_FAR), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_PICKPOCKET_OUT_OF_POSITION] = function()
        return ERROR, GetString(SI_PICKPOCKET_OUT_OF_POSITION), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_PICKPOCKET_ON_COOLDOWN] = function()
        return ERROR, GetString(SI_PICKPOCKET_ON_COOLDOWN), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_PICKPOCKET_SUSPICIOUS] = function()
        return ERROR, GetString(SI_PICKPOCKET_SUSPICIOUS), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_JUSTICE_NPC_SHUNNING] = function()
        return ERROR, GetString(SI_JUSTICE_NPC_SHUNNING), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_TRIAL_FEATURE_RESTRICTED] = function(restrictionType)
        if TrialEventMappings[restrictionType] then
            return ERROR, GetString("SI_TRIALACCOUNTRESTRICTIONTYPE", restrictionType)
        end
    end,

    [EVENT_STUCK_ERROR_ON_COOLDOWN] = function()
        local cooldownText = ZO_FormatTime(GetStuckCooldown(), TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
        local cooldownRemainingText = ZO_FormatTimeMilliseconds(GetTimeUntilStuckAvailable(), TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
        return ERROR, zo_strformat(SI_STUCK_ERROR_ON_COOLDOWN, cooldownText, cooldownRemainingText)
    end,

    [EVENT_STUCK_ERROR_ALREADY_IN_PROGRESS] = function()
        return ERROR, GetString(SI_STUCK_ERROR_ALREADY_IN_PROGRESS)
    end,

    [EVENT_STUCK_ERROR_IN_COMBAT] = function()
        return ERROR, GetString(SI_STUCK_ERROR_IN_COMBAT)
    end,

    [EVENT_STUCK_ERROR_INVALID_LOCATION] = function()
        return ERROR, GetString(SI_INVALID_STUCK_LOCATION)
    end,

    [EVENT_STUCK_CANCELED] = function()
        return ERROR, GetString(SI_GAMEPAD_HELP_UNSTUCK_ERROR_IN_COMBAT), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_RIDING_SKILL_IMPROVEMENT] = function(ridingSkill, previous, current, source)
        if source == RIDING_TRAIN_SOURCE_ITEM then
            local text = zo_strformat(SI_RIDING_SKILL_IMPROVEMENT_ALERT, GetString("SI_RIDINGTRAINTYPE", ridingSkill))
            return ALERT, text
        end
    end,

    [EVENT_QUICK_REPORT_TICKET_SENT] = function()
        return ALERT, GetString(SI_QUICK_REPORT_TICKET_SENT)
    end,

    [EVENT_QUICK_REPORT_ALREADY_REPORTED] = function()
        return ERROR, GetString(SI_QUICK_REPORT_ALREADY_REPORTED), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_DISPLAY_ALERT] = function(alertText, soundId)
        if soundId == "" then
            soundId = nil
        end
        return ALERT, alertText, soundId
    end,

    [EVENT_TUTORIALS_RESET] = function()
        return ALERT, GetString(SI_TUTORIALS_RESET)
    end,

    [EVENT_GROUP_ELECTION_FAILED] = function(failureType, descriptor)
        if failureType ~= GROUP_ELECTION_FAILURE_NONE then
            return ERROR, GetString("SI_GROUPELECTIONFAILURE", failureType), SOUNDS.GENERAL_ALERT_ERROR
        end
    end,

    [EVENT_GROUP_ELECTION_RESULT] = function(resultType, descriptor)
        if resultType ~= GROUP_ELECTION_RESULT_IN_PROGRESS and resultType ~= GROUP_ELECTION_RESULT_NOT_APPLICABLE then
            resultType = ZO_GetSimplifiedGroupElectionResultType(resultType)
            local alertText

            --Try to find override messages based on the descriptor
            local alertTextOverrideLookup = ZO_GroupElectionResultToAlertTextOverrides[resultType]
            if alertTextOverrideLookup then
                alertText = alertTextOverrideLookup[descriptor]
            end

            --No override found
            if not alertText then
                local electionType, _, _, targetUnitTag = GetGroupElectionInfo()
                if electionType == GROUP_ELECTION_TYPE_KICK_MEMBER then
                    if resultType == GROUP_ELECTION_RESULT_ELECTION_LOST then
                        local primaryName = ZO_GetPrimaryPlayerNameFromUnitTag(targetUnitTag)
                        local secondaryName = ZO_GetSecondaryPlayerNameFromUnitTag(targetUnitTag)
                        alertText = zo_strformat(SI_GROUP_ELECTION_KICK_MEMBER_FAILED, primaryName, secondaryName)
                    else
                        --Successful kicks are handled in the GROUP_MEMBER_LEFT alert
                        return
                    end
                end
            end

            --No specific behavior found, so just do the generic alert for the result
            if not alertText then
                alertText = GetString("SI_GROUPELECTIONRESULT", resultType)
            end

            if alertText ~= "" then
                if type(alertText) == "function" then
                    alertText = alertText()
                end
                return ALERT, alertText, GroupElectionResultToSoundId[resultType]
            end
        end
    end,

    [EVENT_GROUP_ELECTION_REQUESTED] = function(descriptor)
        local alertText
        if descriptor then
            alertText = ZO_GroupElectionDescriptorToRequestAlertText[descriptor]
        end

        if not alertText then
            alertText = ZO_GroupElectionDescriptorToRequestAlertText[ZO_GROUP_ELECTION_DESCRIPTORS.NONE]
        end

        return ALERT, alertText, SOUNDS.GROUP_ELECTION_REQUESTED
    end,

    [EVENT_DUEL_INVITE_FAILED] = function(reason, targetCharacterName, targetDisplayName)
        local userFacingName = ZO_GetPrimaryPlayerNameWithSecondary(targetDisplayName, targetCharacterName)
        if userFacingName then
            return ERROR, zo_strformat(GetString("SI_DUELINVITEFAILREASON", reason), userFacingName), SOUNDS.GENERAL_ALERT_ERROR
        else
            return ERROR, GetString("SI_DUELINVITEFAILREASON", reason), SOUNDS.GENERAL_ALERT_ERROR
        end
    end,

    [EVENT_DUEL_INVITE_RECEIVED] = function(inviterCharacterName, inviterDisplayName)
        local userFacingName = ZO_GetPrimaryPlayerName(inviterDisplayName, inviterCharacterName)
        return ALERT, zo_strformat(SI_DUEL_INVITE_RECEIVED, userFacingName)
    end,

    [EVENT_DUEL_INVITE_SENT] = function(inviteeCharacterName, inviteeDisplayName)
        local userFacingName = ZO_GetPrimaryPlayerName(inviteeDisplayName, inviteeCharacterName)
        return ALERT, zo_strformat(SI_DUEL_INVITE_SENT, userFacingName)
    end,

    [EVENT_DUEL_INVITE_ACCEPTED] = function()
        return ALERT, GetString(SI_DUEL_INVITE_ACCEPTED), SOUNDS.DUEL_ACCEPTED
    end,

    [EVENT_DUEL_INVITE_DECLINED] = function()
        return ALERT, GetString(SI_DUEL_INVITE_DECLINED), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_DUEL_INVITE_CANCELED] = function()
        return ALERT, GetString(SI_DUEL_INVITE_CANCELED), SOUNDS.GENERAL_ALERT_ERROR
    end,

    [EVENT_CROWN_CRATE_OPEN_RESPONSE] = function(crownCrateId, openResponse)
        if openResponse ~= LOOT_CRATE_OPEN_RESPONSE_SUCCESS then
            local errorText = GetString("SI_LOOTCRATEOPENRESPONSE", openResponse)
            if openResponse == LOOT_CRATE_OPEN_RESPONSE_FAIL_NO_INVENTORY_SPACE then
                local requiredSlots = GetInventorySpaceRequiredToOpenCrownCrate(crownCrateId)
                local freeSlots = GetNumBagFreeSlots(BAG_BACKPACK)
                errorText = zo_strformat(errorText, requiredSlots - freeSlots)
            end
            return ERROR, errorText, SOUNDS.GENERAL_ALERT_ERROR
        end
	end,

    [EVENT_GROUPING_TOOLS_READY_CHECK_CANCELLED] = function(reason)
        if reason ~= LFG_READY_CHECK_CANCEL_REASON_NOT_IN_READY_CHECK then
            return ALERT, GetString("SI_LFGREADYCHECKCANCELREASON", reason)
        end
    end,

    [EVENT_STACKED_ALL_ITEMS_IN_BAG] = function()
        return ALERT, GetString(SI_STACK_ALL_ITEMS_ALERT)
    end,

	[EVENT_ACTION_SLOT_ABILITY_USED_WRONG_WEAPON] = function(weaponConfigType)
		return ALERT, zo_strformat(SI_ERROR_WRONG_WEAPON_EQUIPPED_FOR_SKILL, GetString("SI_WEAPONCONFIGTYPE", weaponConfigType))
	end,

	[EVENT_HOUSING_ADD_PERMISSIONS_FAILED] = function(userGroup, attemptedName)
        if userGroup == HOUSE_PERMISSION_USER_GROUP_INDIVIDUAL then
		    return ALERT, zo_strformat(SI_HOUSING_ADD_PERMISSIONS_FAILED_INDIVIDUAL, ZO_FormatUserFacingDisplayName(attemptedName))
        elseif userGroup == HOUSE_PERMISSION_USER_GROUP_GUILD then
            return ALERT, zo_strformat(SI_HOUSING_ADD_PERMISSIONS_FAILED_GUILD, attemptedName)
        end
	end,

	[EVENT_HOUSING_ADD_PERMISSIONS_CANT_ADD_SELF] = function()
        return ALERT, GetString(SI_HOUSING_ADD_PERMISSIONS_CANT_ADD_SELF)
	end,

	[EVENT_HOUSING_LOAD_PERMISSIONS_RESULT] = function(loadResult)
        return ALERT, GetString("SI_HOUSINGLOADPERMISSIONSRESULT", loadResult)
	end,

    [EVENT_HOUSING_EDITOR_REQUEST_RESULT] = function(result)
        if result ~= HOUSING_REQUEST_RESULT_SUCCESS then
            return ALERT, GetString("SI_HOUSINGREQUESTRESULT", result)
        end
    end,
}

function ZO_AlertText_GetHandlers()
    return AlertHandlers
end

if not playerName then
    local function OnUnitCreated(eventCode, tag)
        if tag == "player" then
            playerName = GetRawUnitName(unitTag)
        end
    end
    EVENT_MANAGER:RegisterForEvent("AlertHandlers_ON_UNIT_CREATED", EVENT_UNIT_CREATED, OnUnitCreated)
end

function ShouldShowSocialErrorInAlert(error)
	return ZO_Menu_WasLastCommandFromMenu() or (error ~= SOCIAL_RESULT_ACCOUNT_NOT_FOUND and error ~= SOCIAL_RESULT_CHARACTER_NOT_FOUND)
end

function IsSocialErrorIgnoreResponse(error)
    return error == SOCIAL_RESULT_ACCOUNT_IGNORING_YOU
end

function ShouldShowGroupErrorInAlert(error)
	return ZO_Menu_WasLastCommandFromMenu() or (error ~= GROUP_INVITE_RESPONSE_PLAYER_NOT_FOUND)
end

function IsGroupErrorIgnoreResponse(error)
    return error == GROUP_INVITE_RESPONSE_IGNORED
end