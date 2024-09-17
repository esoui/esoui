-- Miscellaneous data
local ARTIFACT_STATE_ALLIANCE_TO_SOUND_ID =
{
    [OBJECTIVE_CONTROL_EVENT_CAPTURED] =
    {
        [ALLIANCE_ALDMERI_DOMINION] = SOUNDS.ELDER_SCROLL_CAPTURED_BY_ALDMERI,
        [ALLIANCE_EBONHEART_PACT] = SOUNDS.ELDER_SCROLL_CAPTURED_BY_EBONHEART,
        [ALLIANCE_DAGGERFALL_COVENANT] = SOUNDS.ELDER_SCROLL_CAPTURED_BY_DAGGERFALL,
    },
}

local ARTIFACT_EVENT_DESCRIPTIONS =
{
    [OBJECTIVE_CONTROL_EVENT_FLAG_TAKEN] =              function(artifactName, keepId, playerName, alliance, allianceName, campaignId)
                                                            if campaignId ~= 0 then
                                                                if keepId ~= 0 then
                                                                    return zo_strformat(SI_CAMPAIGN_ARTIFACT_TAKEN, playerName, allianceName, artifactName, GetKeepName(keepId), GetCampaignName(campaignId))
                                                                else
                                                                    return zo_strformat(SI_CAMPAIGN_ARTIFACT_PICKED_UP, playerName, allianceName, artifactName, GetCampaignName(campaignId))
                                                                end
                                                            else
                                                                if keepId ~= 0 then
                                                                    return zo_strformat(SI_ARTIFACT_TAKEN, playerName, allianceName, artifactName, GetKeepName(keepId))
                                                                else
                                                                    return zo_strformat(SI_ARTIFACT_PICKED_UP, playerName, allianceName, artifactName)
                                                                end
                                                            end
                                                        end,

    [OBJECTIVE_CONTROL_EVENT_CAPTURED] =                function(artifactName, keepId, playerName, alliance, allianceName, campaignId)
                                                            local soundId = ARTIFACT_STATE_ALLIANCE_TO_SOUND_ID[OBJECTIVE_CONTROL_EVENT_CAPTURED][alliance]

                                                            if campaignId ~= 0 then
                                                                return zo_strformat(SI_CAMPAIGN_ARTIFACT_CAPTURED, playerName, allianceName, artifactName, GetKeepName(keepId), GetCampaignName(campaignId)), soundId
                                                            else
                                                                return zo_strformat(SI_ARTIFACT_CAPTURED, playerName, allianceName, artifactName, GetKeepName(keepId)), soundId
                                                            end
                                                        end,

    [OBJECTIVE_CONTROL_EVENT_FLAG_RETURNED] =           function(artifactName, keepId, playerName, alliance, allianceName, campaignId)
                                                            if campaignId ~= 0 then
                                                                return zo_strformat(SI_CAMPAIGN_ARTIFACT_RETURNED, playerName, allianceName, artifactName, GetKeepName(keepId), GetCampaignName(campaignId))
                                                            else
                                                                return zo_strformat(SI_ARTIFACT_RETURNED, playerName, allianceName, artifactName, GetKeepName(keepId))
                                                            end
                                                        end,

    [OBJECTIVE_CONTROL_EVENT_FLAG_RETURNED_BY_TIMER] =  function(artifactName, keepId, playerName, alliance, allianceName, campaignId)
                                                            if campaignId ~= 0 then
                                                                return zo_strformat(SI_CAMPAIGN_ARTIFACT_RETURNED_BY_TIMER, artifactName, GetKeepName(keepId), GetCampaignName(campaignId))
                                                            else
                                                                return zo_strformat(SI_ARTIFACT_RETURNED_BY_TIMER, artifactName, GetKeepName(keepId))
                                                            end
                                                        end,

    [OBJECTIVE_CONTROL_EVENT_FLAG_DROPPED] =            function(artifactName, keepId, playerName, alliance, allianceName, campaignId)
                                                            if campaignId ~= 0 then
                                                                return zo_strformat(SI_CAMPAIGN_ARTIFACT_DROPPED, playerName, allianceName, artifactName, GetCampaignName(campaignId))
                                                            else
                                                                return zo_strformat(SI_ARTIFACT_DROPPED, playerName, allianceName, artifactName)
                                                            end
                                                        end,
}

function GetAvAArtifactEventDescription(artifactName, keepId, playerName, playerAlliance, event, campaignId)
    local eventHandler = ARTIFACT_EVENT_DESCRIPTIONS[event]
    if eventHandler then
        return eventHandler(artifactName, keepId, playerName, playerAlliance, GetColoredAllianceName(playerAlliance), campaignId)
    end
end

function GetKeepOwnershipChangedEventDescription(campaignId, keepId, oldOwner, newOwner)
    if campaignId ~= 0 then
        return zo_strformat(SI_CAMPAIGN_KEEP_CAPTURED, GetColoredAllianceName(newOwner), GetKeepName(keepId), GetColoredAllianceName(oldOwner), GetCampaignName(campaignId))
    else
        return zo_strformat(SI_KEEP_CAPTURED, GetColoredAllianceName(newOwner), GetKeepName(keepId), GetColoredAllianceName(oldOwner))
    end
end

function GetGateStateChangedDescription(keepId, open)
    if open then
        return zo_strformat(SI_KEEP_CHANGE_GATE_OPENED, GetKeepName(keepId)), SOUNDS.AVA_GATE_OPENED
    else
        return zo_strformat(SI_KEEP_CHANGE_GATE_CLOSED, GetKeepName(keepId)), SOUNDS.AVA_GATE_CLOSED
    end
end

local CORONATION_SOUND =
{
    [ALLIANCE_ALDMERI_DOMINION] = SOUNDS.EMPEROR_CORONATED_ALDMERI,
    [ALLIANCE_EBONHEART_PACT] = SOUNDS.EMPEROR_CORONATED_EBONHEART,
    [ALLIANCE_DAGGERFALL_COVENANT] = SOUNDS.EMPEROR_CORONATED_DAGGERFALL,
}

local DEPOSED_SOUND =
{
    [ALLIANCE_ALDMERI_DOMINION] = SOUNDS.EMPEROR_DEPOSED_ALDMERI,
    [ALLIANCE_EBONHEART_PACT] = SOUNDS.EMPEROR_DEPOSED_EBONHEART,
    [ALLIANCE_DAGGERFALL_COVENANT] = SOUNDS.EMPEROR_DEPOSED_DAGGERFALL,
}

function GetCoronateEmperorEventDescription(campaignId, playerCharacterName, playerAlliance, playerDisplayName)
    local userFacingName = IsInGamepadPreferredMode() and ZO_FormatUserFacingDisplayName(playerDisplayName) or playerCharacterName
    return zo_strformat(SI_CAMPAIGN_CORONATE_EMPEROR, GetCampaignName(campaignId), userFacingName, GetColoredAllianceName(playerAlliance)), CORONATION_SOUND[playerAlliance]
end

function GetDeposeEmperorEventDescription(campaignId, playerCharacterName, playerAlliance, abdication, playerDisplayName)
    local userFacingName = IsInGamepadPreferredMode() and ZO_FormatUserFacingDisplayName(playerDisplayName) or playerCharacterName
    if abdication then
        return zo_strformat(SI_CAMPAIGN_ABDICATE_EMPEROR, GetCampaignName(campaignId), userFacingName, GetColoredAllianceName(playerAlliance)), SOUNDS.EMPEROR_ABDICATED
    else
        return zo_strformat(SI_CAMPAIGN_DEPOSE_EMPEROR, GetCampaignName(campaignId), userFacingName, GetColoredAllianceName(playerAlliance)), DEPOSED_SOUND[playerAlliance]
    end
end

function GetClaimKeepCampaignEventDescription(campaignId, keepId, guildName, playerName)
    return zo_strformat(SI_CAMPAIGN_CLAIM_KEEP_EVENT, GetCampaignName(campaignId), GetKeepName(keepId), guildName, playerName), SOUNDS.GUILD_KEEP_CLAIMED
end

function GetReleaseKeepCampaignEventDescription(campaignId, keepId, guildName, playerName)
    return zo_strformat(SI_CAMPAIGN_RELEASE_KEEP_EVENT, GetCampaignName(campaignId), GetKeepName(keepId), guildName, playerName), SOUNDS.GUILD_KEEP_RELEASED
end

function GetLostKeepCampaignEventDescription(campaignId, keepId, guildName)
    return zo_strformat(SI_CAMPAIGN_LOST_KEEP_EVENT, GetCampaignName(campaignId), GetKeepName(keepId), guildName), SOUNDS.GUILD_KEEP_LOST
end

-- Return format is
--  Category - The alert category to send the alert to
--  SoundId - An optional sound id to play along with the message
--  Message - The message to alert (either a string or a function that returns a string that will be called every frame)
--  (Optional) Message2 - For combined text, the secondary text to display (either a string or a function that returns a string that will be called every frame)
--  (Optional) icon - An icon to be displayed with the announcement
--  (Optional) expiringCallback - A callback to be called when the announcement has begun fading out
--  (optional) bar params
--  (optional) lifespan of the message to be on the screen in milliseconds
--
-- NOTE: If a later optional return is used, the previous optional returns must be used as well (even if they return nil)
-- If Category or Message is nil, then nothing will be shown. Simply not returning anything tells the system to not do anything.

local CENTER_SCREEN_EVENT_HANDLERS = { }

-- TODO: Remove progress bar validation logic
-- We're trying to track down info for ESO-558876

local function ValidateProgressBarParams(barParams)
    local barType = barParams:GetParams()
    if not (barType and PLAYER_PROGRESS_BAR:GetBarTypeInfoByBarType(barType)) then
        local INVALID_VALUE = -1
        internalassert(false, string.format("CSAH Bad Bar Params; barType: %d. Triggering Event: %d.", barType or INVALID_VALUE, barParams:GetTriggeringEvent() or INVALID_VALUE))
    end
end

local function GetRelevantBarParams(level, previousExperience, currentExperience, championPoints, triggeringEvent)
    local championXpToNextPoint
    if CanUnitGainChampionPoints("player") then
        championXpToNextPoint = GetNumChampionXPInChampionPoint(championPoints)
    end  
    if(championXpToNextPoint ~= nil and currentExperience > previousExperience) then
        local barParams = CENTER_SCREEN_ANNOUNCE:CreateBarParams(PPB_CP, championPoints, previousExperience, currentExperience)
        barParams:SetTriggeringEvent(triggeringEvent)
        return barParams
    else
        local levelSize = GetNumExperiencePointsInLevel(level)
        if(levelSize ~= nil and currentExperience >  previousExperience) then
            local barParams = CENTER_SCREEN_ANNOUNCE:CreateBarParams(PPB_XP, level, previousExperience, currentExperience)
            barParams:SetTriggeringEvent(triggeringEvent)
            return barParams
        end
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_QUEST_ADDED] = function(journalIndex, questName, objectiveName)
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.QUEST_ACCEPTED)
    local questType = GetJournalQuestType(journalIndex)
    local zoneDisplayType = GetJournalQuestZoneDisplayType(journalIndex)
    local questJournalObject = SYSTEMS:GetObject("questJournal")
    local iconTexture = questJournalObject:GetIconTexture(questType, zoneDisplayType)
    if iconTexture then
        messageParams:SetText(zo_strformat(SI_NOTIFYTEXT_QUEST_ACCEPT_WITH_ICON, zo_iconFormat(iconTexture, "75%", "75%"), questName))
    else
        messageParams:SetText(zo_strformat(SI_NOTIFYTEXT_QUEST_ACCEPT, questName))
    end
    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_ADDED)
    return messageParams
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_QUEST_COMPLETE] = function(questName, level, previousExperience, currentExperience, championPoints, questType, zoneDisplayType)
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.QUEST_COMPLETED)

    local questJournalObject = SYSTEMS:GetObject("questJournal")
    local iconTexture = questJournalObject:GetIconTexture(questType, zoneDisplayType)
    if iconTexture then
        messageParams:SetText(zo_strformat(SI_NOTIFYTEXT_QUEST_COMPLETE_WITH_ICON, zo_iconFormat(iconTexture, "75%", "75%"), questName))
    else
        messageParams:SetText(zo_strformat(SI_NOTIFYTEXT_QUEST_COMPLETE, questName))
    end
    messageParams:SetBarParams(GetRelevantBarParams(level, previousExperience, currentExperience, championPoints, EVENT_QUEST_COMPLETE))
    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_COMPLETED)
    return messageParams
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_OBJECTIVE_COMPLETED] = function(zoneIndex, poiIndex, level, previousExperience, currentExperience, championPoints) 
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.OBJECTIVE_COMPLETED)
    local name, _, _, finishedDescription = GetPOIInfo(zoneIndex, poiIndex)
    messageParams:SetBarParams(GetRelevantBarParams(level, previousExperience, currentExperience, championPoints, EVENT_OBJECTIVE_COMPLETED))
    messageParams:SetText(zo_strformat(SI_NOTIFYTEXT_OBJECTIVE_COMPLETE, name), finishedDescription)
    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_OBJECTIVE_COMPLETED)
    return messageParams
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_QUEST_CONDITION_COUNTER_CHANGED] = function(journalIndex, questName, conditionText, conditionType, currConditionVal, newConditionVal, conditionMax, isFailCondition, stepOverrideText, isPushed, isComplete, isConditionComplete, isStepHidden, isConditionCompleteChanged)
    if isStepHidden or (isPushed and isComplete) or (currConditionVal >= newConditionVal) then
        return
    end

    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SMALL_TEXT)
    if newConditionVal ~= currConditionVal and not isFailCondition then
        messageParams:SetSound(isConditionComplete and SOUNDS.QUEST_OBJECTIVE_COMPLETE or SOUNDS.QUEST_OBJECTIVE_INCREMENT)
    end

    if isConditionComplete and conditionType == QUEST_CONDITION_TYPE_GIVE_ITEM then
         messageParams:SetText(zo_strformat(SI_TRACKED_QUEST_STEP_DONE, conditionText))
    elseif stepOverrideText == "" then
        if isFailCondition then
            if conditionMax > 1 then
                messageParams:SetText(zo_strformat(SI_ALERTTEXT_QUEST_CONDITION_FAIL, conditionText, newConditionVal, conditionMax))
            else
               messageParams:SetText(zo_strformat(SI_ALERTTEXT_QUEST_CONDITION_FAIL_NO_COUNT, conditionText))
            end
        else
            if conditionMax > 1 and newConditionVal < conditionMax then
                messageParams:SetText(zo_strformat(SI_ALERTTEXT_QUEST_CONDITION_UPDATE, conditionText, newConditionVal, conditionMax))
            else
                messageParams:SetText(zo_strformat(SI_ALERTTEXT_QUEST_CONDITION_UPDATE_NO_COUNT, conditionText))
            end
        end
    else
        if isFailCondition then
            messageParams:SetText(zo_strformat(SI_ALERTTEXT_QUEST_CONDITION_FAIL_NO_COUNT, stepOverrideText))
        else
            messageParams:SetText(zo_strformat(SI_ALERTTEXT_QUEST_CONDITION_UPDATE_NO_COUNT, stepOverrideText))
        end
    end

    if isConditionComplete then
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_CONDITION_COMPLETED)
    else
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_PROGRESSION_CHANGED)
    end

    return messageParams
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_QUEST_OPTIONAL_STEP_ADVANCED] = function(text)
    if text ~= "" then
        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SMALL_TEXT, SOUNDS.QUEST_OBJECTIVE_COMPLETE)
        messageParams:SetText(zo_strformat(SI_ALERTTEXT_QUEST_CONDITION_UPDATE_NO_COUNT, text))
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_PROGRESSION_CHANGED)
        return messageParams
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_ACHIEVEMENT_AWARDED] = function(name, points, id)
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.ACHIEVEMENT_AWARDED)
    local icon = select(4, GetAchievementInfo(id))
    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_ACHIEVEMENT_AWARDED)
    messageParams:SetText(GetString(SI_ACHIEVEMENT_AWARDED_CENTER_SCREEN), zo_strformat(name))
    messageParams:SetIconData(icon, "EsoUI/Art/Achievements/achievements_iconBG.dds")
    return messageParams
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_BROADCAST] = function(message)
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SMALL_TEXT, SOUNDS.MESSAGE_BROADCAST)
    messageParams:SetText(string.format("|cffff00%s|r", message))
    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_SYSTEM_BROADCAST)
    return messageParams
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_FIXED_BROADCAST] = function(broadcastType, arg1)
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SMALL_TEXT, SOUNDS.MESSAGE_BROADCAST)
    messageParams:SetText(string.format("|cffff00%s|r", zo_strformat(GetString("SI_BROADCASTTYPE", broadcastType), arg1)))
    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_SYSTEM_BROADCAST)
    return messageParams
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_DISCOVERY_EXPERIENCE] = function(subzoneName, level, previousExperience, currentExperience, championPoints)
    if not INTERACT_WINDOW:IsShowingInteraction() then
        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.OBJECTIVE_DISCOVERED)
        if currentExperience > previousExperience then
            messageParams:SetBarParams(GetRelevantBarParams(level, previousExperience, currentExperience, championPoints, EVENT_DISCOVERY_EXPERIENCE))
        end
        messageParams:SetText(zo_strformat(SI_SUBZONE_NOTIFICATION_DISCOVER, subzoneName))
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_DISCOVERY_EXPERIENCE)
        return messageParams
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_POI_DISCOVERED] = function(zoneIndex, poiIndex)
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.OBJECTIVE_ACCEPTED)
    local name, _, startDescription = GetPOIInfo(zoneIndex, poiIndex)
    messageParams:SetText(zo_strformat(SI_NOTIFYTEXT_OBJECTIVE_DISCOVERED, name), startDescription)
    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_POI_DISCOVERED)
    return messageParams
end

local XP_GAIN_SHOW_REASONS =
{
    [PROGRESS_REASON_PVP_EMPEROR] = true,
    [PROGRESS_REASON_DUNGEON_CHALLENGE] = true,
    [PROGRESS_REASON_OVERLAND_BOSS_KILL] = true,
    [PROGRESS_REASON_SCRIPTED_EVENT] = true,
    [PROGRESS_REASON_LOCK_PICK] = true,
    [PROGRESS_REASON_LFG_REWARD] = true,
}

local XP_GAIN_SHOW_SOUNDS =
{
    [PROGRESS_REASON_OVERLAND_BOSS_KILL] = SOUNDS.OVERLAND_BOSS_KILL,
    [PROGRESS_REASON_LOCK_PICK] = SOUNDS.LOCKPICKING_SUCCESS_CELEBRATION,
}

CENTER_SCREEN_EVENT_HANDLERS[EVENT_EXPERIENCE_GAIN] = function(reason, level, previousExperience, currentExperience, championPoints)
    if XP_GAIN_SHOW_REASONS[reason] then
        local barParams = GetRelevantBarParams(level, previousExperience, currentExperience, championPoints, EVENT_EXPERIENCE_GAIN)
        if barParams then
            local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_NO_TEXT)
            local sound = XP_GAIN_SHOW_SOUNDS[reason]
            barParams:SetSound(sound)
            ValidateProgressBarParams(barParams)
            messageParams:SetBarParams(barParams)
            messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_EXPERIENCE_GAIN)
            return messageParams
        end
    end

    local levelSize = GetNumExperiencePointsInLevel(level)
    if levelSize ~= nil and currentExperience >= levelSize then
        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.LEVEL_UP)
        local barParams = CENTER_SCREEN_ANNOUNCE:CreateBarParams(PPB_XP, level + 1, currentExperience - levelSize, currentExperience - levelSize)
        barParams:SetShowNoGain(true)
        barParams:SetTriggeringEvent(EVENT_EXPERIENCE_GAIN)
        messageParams:SetText(GetString(SI_LEVEL_UP_NOTIFICATION))
        ValidateProgressBarParams(barParams)
        messageParams:SetBarParams(barParams)
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_LEVEL_GAIN)
        return messageParams
    end
end

local COMPANION_NAME_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_UNIT_REACTION_COLOR, UNIT_REACTION_COLOR_COMPANION))
CENTER_SCREEN_EVENT_HANDLERS[EVENT_COMPANION_EXPERIENCE_GAIN] = function(companionId, previousLevel, previousExperience, currentExperience)
    local currentLevel = GetActiveCompanionLevelForExperiencePoints(currentExperience, previousLevel)
    if currentLevel > previousLevel then
        local secondaryTextLines = {}
        local collectibleIcon = GetCollectibleIcon(GetCompanionCollectibleId(companionId))
        table.insert(secondaryTextLines, zo_strformat(SI_COMPANION_LEVEL_UP_NAME_CSA, zo_iconFormat(collectibleIcon, "100%", "100%"), COMPANION_NAME_COLOR:Colorize(GetCompanionName(companionId))))
        local previousNumSlots = GetCompanionNumSlotsUnlockedForLevel(previousLevel)
        local currentNumSlots = GetCompanionNumSlotsUnlockedForLevel(currentLevel)
        if currentNumSlots > previousNumSlots then
            table.insert(secondaryTextLines, GetString(SI_COMPANION_ACTION_SLOT_UNLOCKED_NOTIFICATION))
        end

        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.LEVEL_UP)
        messageParams:SetText(GetString(SI_COMPANION_LEVEL_UP_NOTIFICATION), table.concat(secondaryTextLines, "\n"))
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_LEVEL_GAIN)
        return messageParams
    end
end

local function GetCurrentChampionPointsBarParams(triggeringEvent)
    local championPoints = GetPlayerChampionPointsEarned()
    local currentChampionXP = GetPlayerChampionXP()
    local barParams = CENTER_SCREEN_ANNOUNCE:CreateBarParams(PPB_CP, championPoints, currentChampionXP, currentChampionXP)
    barParams:SetShowNoGain(true)
    barParams:SetTriggeringEvent(triggeringEvent)
    return barParams
end

local function GetEnlightenedGainedAnnouncement(triggeringEvent)
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.ENLIGHTENED_STATE_GAINED)
    local barParams = GetCurrentChampionPointsBarParams(triggeringEvent)
    messageParams:SetText(zo_strformat(SI_ENLIGHTENED_STATE_GAINED_HEADER), zo_strformat(SI_ENLIGHTENED_STATE_GAINED_DESCRIPTION))
    ValidateProgressBarParams(barParams)
    messageParams:SetBarParams(barParams)
    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_ENLIGHTENMENT_GAINED)
    return messageParams
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_ENLIGHTENED_STATE_GAINED] = function()
    if IsEnlightenedAvailableForCharacter() then
        return GetEnlightenedGainedAnnouncement(EVENT_ENLIGHTENED_STATE_GAINED)
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_ENLIGHTENED_STATE_LOST] = function()
    if IsEnlightenedAvailableForCharacter() then
        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.ENLIGHTENED_STATE_LOST)
        local barParams = GetCurrentChampionPointsBarParams(EVENT_ENLIGHTENED_STATE_LOST)
        ValidateProgressBarParams(barParams)
        messageParams:SetBarParams(barParams)
        messageParams:SetText(zo_strformat(SI_ENLIGHTENED_STATE_LOST_HEADER))
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_ENLIGHTENMENT_LOST)
        return messageParams
    end
end

local firstActivation = true
CENTER_SCREEN_EVENT_HANDLERS[EVENT_PLAYER_ACTIVATED] = function()
    if firstActivation then
        firstActivation = false

        if IsEnlightenedAvailableForCharacter() and GetEnlightenedPool() > 0 then
            return GetEnlightenedGainedAnnouncement(EVENT_PLAYER_ACTIVATED)
        end
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_SKILL_RANK_UPDATE] = function(skillType, skillLineIndex, rank)
    -- crafting skill updates get deferred if they're increased while crafting animations are in progress
    -- ZO_Skills_TieSkillInfoHeaderToCraftingSkill handles triggering the deferred center screen announce in that case
    if skillType ~= SKILL_TYPE_RACIAL and (skillType ~= SKILL_TYPE_TRADESKILL or not ZO_CraftingUtils_IsPerformingCraftProcess()) then
        local skillLineData = SKILLS_DATA_MANAGER:GetSkillLineDataByIndices(skillType, skillLineIndex)
        if skillLineData and skillLineData:IsAvailable() then
            local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.SKILL_LINE_LEVELED_UP)
            messageParams:SetText(zo_strformat(SI_SKILL_RANK_UP, skillLineData:GetName(), rank))
            messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_SKILL_RANK_UPDATE)
            return messageParams
        end
    end
end

local GUILD_SKILL_SHOW_REASONS =
{
    [PROGRESS_REASON_DARK_ANCHOR_CLOSED] = true,
    [PROGRESS_REASON_DARK_FISSURE_CLOSED] = true,
    [PROGRESS_REASON_BOSS_KILL] = true,
}

local GUILD_SKILL_SHOW_SOUNDS =
{
    [PROGRESS_REASON_DARK_ANCHOR_CLOSED] = SOUNDS.SKILL_XP_DARK_ANCHOR_CLOSED,
    [PROGRESS_REASON_DARK_FISSURE_CLOSED] = SOUNDS.SKILL_XP_DARK_FISSURE_CLOSED,
    [PROGRESS_REASON_BOSS_KILL] = SOUNDS.SKILL_XP_BOSS_KILLED,
}

CENTER_SCREEN_EVENT_HANDLERS[EVENT_SKILL_XP_UPDATE] = function(skillType, skillLineIndex, reason, rank, previousXP, currentXP)
    if (skillType == SKILL_TYPE_GUILD and GUILD_SKILL_SHOW_REASONS[reason]) or reason == PROGRESS_REASON_JUSTICE_SKILL_EVENT then
        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_NO_TEXT)
        local barType = PLAYER_PROGRESS_BAR:GetBarType(PPB_CLASS_SKILL, skillType, skillLineIndex)
        local rankStartXP, nextRankStartXP = GetSkillLineRankXPExtents(skillType, skillLineIndex, rank)
        local sound = GUILD_SKILL_SHOW_SOUNDS[reason]
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_SKILL_XP_UPDATE)
        if rankStartXP ~= nil then
            local barParams = CENTER_SCREEN_ANNOUNCE:CreateBarParams(barType, rank, previousXP - rankStartXP, currentXP - rankStartXP)
            barParams:SetTriggeringEvent(EVENT_SKILL_XP_UPDATE)
            ValidateProgressBarParams(barParams)
            messageParams:SetBarParams(barParams)
        else
            internalassert(false, string.format("No Rank Start XP %d %d %d %d %d %d", skillType, skillLineIndex, reason, rank, previousXP, currentXP))
        end
        return messageParams
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_ABILITY_PROGRESSION_RANK_UPDATE] = function(progressionIndex, rank, maxRank, morph)
    local _, _, _, atMorph = GetAbilityProgressionXPInfo(progressionIndex)
    local name = GetAbilityProgressionAbilityInfo(progressionIndex, morph, rank)

    if atMorph then
        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.ABILITY_MORPH_AVAILABLE)
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_ABILITY_PROGRESSION_RANK_MORPH)
        messageParams:SetText(zo_strformat(SI_MORPH_AVAILABLE_ANNOUNCEMENT, name))
        return messageParams 
    else
        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SMALL_TEXT, SOUNDS.ABILITY_RANK_UP)
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_ABILITY_PROGRESSION_RANK_UPDATE)
        messageParams:SetText(zo_strformat(SI_ABILITY_RANK_UP, name, rank))
        return messageParams
    end
end

local SUPPRESS_SKILL_POINT_CSA_REASONS =
{
    [SKILL_POINT_CHANGE_REASON_IGNORE] = true,
    [SKILL_POINT_CHANGE_REASON_SKILL_RESPEC] = true,
    [SKILL_POINT_CHANGE_REASON_SKILL_RESET] = true,
}

CENTER_SCREEN_EVENT_HANDLERS[EVENT_SKILL_POINTS_CHANGED] = function(oldPoints, newPoints, oldPartialPoints, newPartialPoints, changeReason)
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)

    local numSkillPointsGained = newPoints - oldPoints
    -- check if the skill point change was due to skyshards
    if oldPartialPoints ~= newPartialPoints or changeReason == SKILL_POINT_CHANGE_REASON_SKYSHARD_INSTANT_UNLOCK then
        if numSkillPointsGained < 0 then
            return
        end

        local numSkyshardsGained = (newPoints * NUM_PARTIAL_SKILL_POINTS_FOR_FULL + newPartialPoints) - (oldPoints * NUM_PARTIAL_SKILL_POINTS_FOR_FULL + oldPartialPoints)

        messageParams:SetSound(SOUNDS.SKYSHARD_GAINED)
        local largeText = zo_strformat(SI_SKYSHARD_GAINED, numSkyshardsGained)

        -- if only the partial points changed, message out the new count of skyshard pieces
        if newPoints == oldPoints then
            messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_SKILL_POINTS_PARTIAL_GAINED)
            messageParams:SetText(largeText, zo_strformat(SI_SKYSHARD_GAINED_POINTS, newPartialPoints, NUM_PARTIAL_SKILL_POINTS_FOR_FULL))
        else
            local messageText
            -- if there are no leftover skyshard pieces, don't include them in the message
            if newPartialPoints == 0 then
                messageText = zo_strformat(SI_SKILL_POINT_GAINED, numSkillPointsGained)
            else
                messageText = zo_strformat(SI_SKILL_POINT_AND_SKYSHARD_PIECES_GAINED, numSkillPointsGained, newPartialPoints, NUM_PARTIAL_SKILL_POINTS_FOR_FULL)
            end

            messageParams:SetText(largeText, messageText)
            messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_SKILL_POINTS_GAINED)
        end

        return messageParams
    elseif numSkillPointsGained > 0 then
        if not SUPPRESS_SKILL_POINT_CSA_REASONS[changeReason] then
            messageParams:SetSound(SOUNDS.SKILL_GAINED)
            messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_SKILL_POINTS_GAINED)
            messageParams:SetText(zo_strformat(SI_SKILL_POINT_GAINED, numSkillPointsGained))
            return messageParams
        end
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_LORE_BOOK_LEARNED_SKILL_EXPERIENCE] = function(categoryIndex, collectionIndex, bookIndex, guildReputationIndex, skillType, skillLineIndex, rank, previousXP, currentXP)
    if guildReputationIndex > 0 then
        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.BOOK_ACQUIRED)
        local barType = PLAYER_PROGRESS_BAR:GetBarType(PPB_CLASS_SKILL, skillType, skillLineIndex)
        local rankStartXP, nextRankStartXP = GetSkillLineRankXPExtents(skillType, skillLineIndex, rank)
        local barParams = CENTER_SCREEN_ANNOUNCE:CreateBarParams(barType, rank, previousXP - rankStartXP, currentXP - rankStartXP)
        barParams:SetTriggeringEvent(EVENT_LORE_BOOK_LEARNED_SKILL_EXPERIENCE)
        ValidateProgressBarParams(barParams)
        messageParams:SetBarParams(barParams)
        messageParams:SetText(GetString(SI_LORE_LIBRARY_ANNOUNCE_BOOK_LEARNED))
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_LORE_BOOK_LEARNED_SKILL_EXPERIENCE)
        return messageParams
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_LORE_COLLECTION_COMPLETED] = function(categoryIndex, collectionIndex, bookIndex, guildReputationIndex, isMaxRank)
    if guildReputationIndex == 0 or isMaxRank then
        -- Only fire this message if we're not part of the guild or at max level within the guild.
        local collectionName, description, numKnownBooks, totalBooks, hidden = GetLoreCollectionInfo(categoryIndex, collectionIndex)
        if not hidden then
            local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.BOOK_COLLECTION_COMPLETED)
            messageParams:SetText(GetString(SI_LORE_LIBRARY_COLLECTION_COMPLETED_LARGE), zo_strformat(SI_LORE_LIBRARY_COLLECTION_COMPLETED_SMALL, collectionName))
            messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_LORE_COLLECTION_COMPLETED)
            return messageParams
        end
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_LORE_COLLECTION_COMPLETED_SKILL_EXPERIENCE] = function(categoryIndex, collectionIndex, guildReputationIndex, skillType, skillLineIndex, rank, previousXP, currentXP)
    if guildReputationIndex > 0 then
        local collectionName, description, numKnownBooks, totalBooks, hidden = GetLoreCollectionInfo(categoryIndex, collectionIndex)
        if not hidden then
            local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.BOOK_COLLECTION_COMPLETED)
            local barType = PLAYER_PROGRESS_BAR:GetBarType(PPB_CLASS_SKILL, skillType, skillLineIndex)
            local rankStartXP, nextRankStartXP = GetSkillLineRankXPExtents(skillType, skillLineIndex, rank)
            local barParams = CENTER_SCREEN_ANNOUNCE:CreateBarParams(barType, rank, previousXP - rankStartXP, currentXP - rankStartXP)
            barParams:SetTriggeringEvent(EVENT_LORE_COLLECTION_COMPLETED_SKILL_EXPERIENCE)
            ValidateProgressBarParams(barParams)
            messageParams:SetBarParams(barParams)
            messageParams:SetText(GetString(SI_LORE_LIBRARY_COLLECTION_COMPLETED_LARGE), zo_strformat(SI_LORE_LIBRARY_COLLECTION_COMPLETED_SMALL, collectionName))
            messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_LORE_COLLECTION_COMPLETED_SKILL_EXPERIENCE)
            return messageParams
        end
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_PLEDGE_OF_MARA_RESULT] = function(result, characterName, displayName)
    if result == PLEDGE_OF_MARA_RESULT_PLEDGED then
        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_PLEDGE_OF_MARA_RESULT)
        messageParams:SetText(GetString(SI_RITUAL_OF_MARA_COMPLETION_ANNOUNCE_LARGE), zo_strformat(SI_RITUAL_OF_MARA_COMPLETION_ANNOUNCE_SMALL, ZO_FormatUserFacingDisplayName(displayName), characterName))
        return messageParams
    end
end

local function CreatePvPMessageParams(sound, description, CSAType, lifespan)
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_MAJOR_TEXT, sound)
    messageParams:SetText(description)
    messageParams:SetCSAType(CSAType)
    if lifespan then
        messageParams:SetLifespanMS(lifespan)
    end
    return messageParams
end

local function CreateAvAMessageParams(sound, description, CSAType, lifespan)
    local messageParams = CreatePvPMessageParams(sound, description, CSAType, lifespan)
    messageParams:MarkIsAvAEvent()
    return messageParams
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_ARTIFACT_CONTROL_STATE] = function(artifactName, keepId, characterName, playerAlliance, controlEvent, controlState, campaignId, displayName)
    local nameToShow = IsInGamepadPreferredMode() and ZO_FormatUserFacingDisplayName(displayName) or characterName
    local description, soundId = GetAvAArtifactEventDescription(artifactName, keepId, nameToShow, playerAlliance, controlEvent, campaignId)
    return CreateAvAMessageParams(soundId, description, CENTER_SCREEN_ANNOUNCE_TYPE_ARTIFACT_CONTROL_STATE)
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_DAEDRIC_ARTIFACT_OBJECTIVE_SPAWNED_BUT_NOT_REVEALED] = function(daedricArtifactId)
    local daedricArtifactName = GetDaedricArtifactDisplayName(daedricArtifactId)
    local description = zo_strformat(SI_DAEDRIC_ARTIFACT_SPAWNED, daedricArtifactName)
    return CreateAvAMessageParams(SOUNDS.DAEDRIC_ARTIFACT_SPAWNED, description, CENTER_SCREEN_ANNOUNCE_TYPE_DAEDRIC_ARTIFACT_OBJECTIVE_STATE_CHANGED)
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_DAEDRIC_ARTIFACT_OBJECTIVE_STATE_CHANGED] = function(objectiveKeepId, objectiveObjectiveId, battlegroundContext, objectiveControlEvent, objectiveControlState, holderAlliance, lastHolderAlliance, pinType, daedricArtifactId, lastObjectiveControlState)
    if lastObjectiveControlState == OBJECTIVE_CONTROL_STATE_UNKNOWN and objectiveControlState ~= OBJECTIVE_CONTROL_STATE_UNKNOWN then
        -- Revealed (UNKNOWN -> !UNKNOWN)
        local daedricArtifactName = GetDaedricArtifactDisplayName(daedricArtifactId)
        local description = zo_strformat(SI_DAEDRIC_ARTIFACT_REVEALED, daedricArtifactName)
        return CreateAvAMessageParams(SOUNDS.DAEDRIC_ARTIFACT_REVEALED, description, CENTER_SCREEN_ANNOUNCE_TYPE_DAEDRIC_ARTIFACT_OBJECTIVE_STATE_CHANGED)
    elseif lastObjectiveControlState ~= OBJECTIVE_CONTROL_STATE_UNKNOWN and objectiveControlState == OBJECTIVE_CONTROL_STATE_UNKNOWN then
        -- Despawned (!UNKNOWN -> UNKNOWN)
        local daedricArtifactName = GetDaedricArtifactDisplayName(daedricArtifactId)
        local description = zo_strformat(SI_DAEDRIC_ARTIFACT_DESPAWNED, daedricArtifactName)
        return CreateAvAMessageParams(SOUNDS.DAEDRIC_ARTIFACT_DESPAWNED, description, CENTER_SCREEN_ANNOUNCE_TYPE_DAEDRIC_ARTIFACT_OBJECTIVE_STATE_CHANGED)
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_KEEP_GATE_STATE_CHANGED] = function(keepId, open)
    local description, soundId = GetGateStateChangedDescription(keepId, open)
    return CreateAvAMessageParams(soundId, description, CENTER_SCREEN_ANNOUNCE_TYPE_KEEP_GATE_CHANGED)
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_CORONATE_EMPEROR_NOTIFICATION] = function(campaignId, playerCharacterName, playerAlliance, playerDisplayName)
    local description, soundId = GetCoronateEmperorEventDescription(campaignId, playerCharacterName, playerAlliance, playerDisplayName)
    return CreateAvAMessageParams(soundId, description, CENTER_SCREEN_ANNOUNCE_TYPE_CORONATE_EMPEROR, 5000)
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_DEPOSE_EMPEROR_NOTIFICATION] = function(campaignId, playerCharacterName, playerAlliance, abdication, playerDisplayName)
    local description, soundId = GetDeposeEmperorEventDescription(campaignId, playerCharacterName, playerAlliance, abdication, playerDisplayName)
    return CreateAvAMessageParams(soundId, description, CENTER_SCREEN_ANNOUNCE_TYPE_DEPOSE_EMPEROR, 5000)
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_REVENGE_KILL] = function(killedCharacterName, killedDisplayName)
    if IsPlayerInAvAWorld() then
        local killedName = IsInGamepadPreferredMode() and ZO_FormatUserFacingDisplayName(killedDisplayName) or killedCharacterName
        local description = zo_strformat(SI_REVENGE_KILL, killedName)
        local soundId = nil
        return CreateAvAMessageParams(soundId, description, CENTER_SCREEN_ANNOUNCE_TYPE_REVENGE_KILL)
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_AVENGE_KILL] = function(avengedCharacterName, killedCharacterName, avengedDisplayName, killedDisplayName)
    if IsPlayerInAvAWorld() then
        local avengedName = avengedCharacterName
        local killedName = killedCharacterName
        if IsInGamepadPreferredMode() then
            avengedName = ZO_FormatUserFacingDisplayName(avengedDisplayName)
            killedName = ZO_FormatUserFacingDisplayName(killedDisplayName)
        end
        local description = zo_strformat(SI_AVENGE_KILL, avengedName, killedName)
        local soundId = nil
        return CreateAvAMessageParams(soundId, description, CENTER_SCREEN_ANNOUNCE_TYPE_AVENGE_KILL)
    end
end

-- Begin Battleground Event Handlers --

local function ShouldShowBattlegroundObjectiveCSA(objectiveKeepId, objectiveId, battlegroundContext)
    return IsBattlegroundObjective(objectiveKeepId, objectiveId, battlegroundContext) and GetCurrentBattlegroundState() == BATTLEGROUND_STATE_RUNNING
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_CAPTURE_AREA_STATE_CHANGED] = function(objectiveKeepId, objectiveId, battlegroundContext, objectiveName, objectiveControlEvent, objectiveControlState, owningAlliance, pinType)
    if ShouldShowBattlegroundObjectiveCSA(objectiveKeepId, objectiveId, BGQUERY_LOCAL)  then
        if objectiveControlEvent == OBJECTIVE_CONTROL_EVENT_CAPTURED then
            local text, soundId
            --150% because the icon textures contain a good bit of empty space
            local captureAreaIcon = zo_iconFormat(ZO_MapPin.GetStaticPinTexture(pinType), "150%", "150%")
            if owningAlliance == GetUnitBattlegroundTeam("player") then
                text = zo_strformat(SI_BATTLEGROUND_CAPTURE_AREA_CAPTURED, GetColoredBattlegroundYourTeamText(owningAlliance), captureAreaIcon)
                soundId = SOUNDS.BATTLEGROUND_CAPTURE_AREA_CAPTURED_OWN_TEAM
            else
                text = zo_strformat(SI_BATTLEGROUND_CAPTURE_AREA_CAPTURED, GetColoredBattlegroundEnemyTeamText(owningAlliance), captureAreaIcon)
                soundId = SOUNDS.BATTLEGROUND_CAPTURE_AREA_CAPTURED_OTHER_TEAM
            end
            return CreatePvPMessageParams(soundId, text, CENTER_SCREEN_ANNOUNCE_TYPE_BATTLEGROUND_OBJECTIVE)
        end
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_CAPTURE_AREA_SPAWNED] = function(objectiveKeepId, objectiveId, battlegroundContext, pinType, hasMoved)
    if ShouldShowBattlegroundObjectiveCSA(objectiveKeepId, objectiveId, BGQUERY_LOCAL)  then
        local text, soundId
        --150% because the icon textures contain a good bit of empty space
        local captureAreaIcon = zo_iconFormat(ZO_MapPin.GetStaticPinTexture(pinType), "150%", "150%")
        if hasMoved then
            text = zo_strformat(SI_BATTLEGROUND_CAPTURE_AREA_MOVED, captureAreaIcon)
            soundId = SOUNDS.BATTLEGROUND_CAPTURE_AREA_MOVED
        else
            text = zo_strformat(SI_BATTLEGROUND_CAPTURE_AREA_SPAWNED, captureAreaIcon)
            soundId = SOUNDS.BATTLEGROUND_CAPTURE_AREA_SPAWNED
        end
        return CreatePvPMessageParams(soundId, text, CENTER_SCREEN_ANNOUNCE_TYPE_BATTLEGROUND_OBJECTIVE)
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_CAPTURE_FLAG_STATE_CHANGED] = function(objectiveKeepId, objectiveId, battlegroundContext, objectiveName, objectiveControlEvent, objectiveControlState, originalOwnerAlliance, holderAlliance, lastHolderAlliance, pinType)
    if ShouldShowBattlegroundObjectiveCSA(objectiveKeepId, objectiveId, BGQUERY_LOCAL) then
        --150% because the icon textures contain a good bit of empty space
        local flagIcon = zo_iconFormat(ZO_MapPin.GetStaticPinTexture(pinType), "150%", "150%")
        if objectiveControlEvent == OBJECTIVE_CONTROL_EVENT_FLAG_TAKEN then
            local text, soundId
            if holderAlliance == GetUnitBattlegroundTeam("player") then
                text = zo_strformat(SI_BATTLEGROUND_FLAG_PICKED_UP, GetColoredBattlegroundYourTeamText(holderAlliance), flagIcon)
                soundId = SOUNDS.BATTLEGROUND_CAPTURE_FLAG_TAKEN_OWN_TEAM
            else
                text = zo_strformat(SI_BATTLEGROUND_FLAG_PICKED_UP, GetColoredBattlegroundEnemyTeamText(holderAlliance), flagIcon)
                soundId = SOUNDS.BATTLEGROUND_CAPTURE_FLAG_TAKEN_OTHER_TEAM
            end
            return CreatePvPMessageParams(soundId, text, CENTER_SCREEN_ANNOUNCE_TYPE_BATTLEGROUND_OBJECTIVE)
        elseif objectiveControlEvent == OBJECTIVE_CONTROL_EVENT_FLAG_DROPPED then
            local text, soundId
            if lastHolderAlliance == GetUnitBattlegroundTeam("player") then
                text = zo_strformat(SI_BATTLEGROUND_FLAG_DROPPED, GetColoredBattlegroundYourTeamText(lastHolderAlliance), flagIcon)
                soundId = SOUNDS.BATTLEGROUND_CAPTURE_FLAG_DROPPED_OWN_TEAM
            else
                text = zo_strformat(SI_BATTLEGROUND_FLAG_DROPPED, GetColoredBattlegroundEnemyTeamText(lastHolderAlliance), flagIcon)
                soundId = SOUNDS.BATTLEGROUND_CAPTURE_FLAG_DROPPED_OTHER_TEAM
            end
            return CreatePvPMessageParams(soundId, text, CENTER_SCREEN_ANNOUNCE_TYPE_BATTLEGROUND_OBJECTIVE)
        elseif objectiveControlEvent == OBJECTIVE_CONTROL_EVENT_FLAG_RETURNED or objectiveControlEvent == OBJECTIVE_CONTROL_EVENT_FLAG_RETURNED_BY_TIMER then
            return CreatePvPMessageParams(SOUNDS.BATTLEGROUND_CAPTURE_FLAG_RETURNED, zo_strformat(SI_BATTLEGROUND_FLAG_RETURNED, flagIcon), CENTER_SCREEN_ANNOUNCE_TYPE_BATTLEGROUND_OBJECTIVE)
        elseif objectiveControlEvent == OBJECTIVE_CONTROL_EVENT_CAPTURED then
            local text, soundId
            if lastHolderAlliance == GetUnitBattlegroundTeam("player") then
                text = zo_strformat(SI_BATTLEGROUND_FLAG_CAPTURED, GetColoredBattlegroundYourTeamText(lastHolderAlliance), flagIcon)
                soundId = SOUNDS.BATTLEGROUND_CAPTURE_FLAG_CAPTURED_BY_OWN_TEAM
            else
                text = zo_strformat(SI_BATTLEGROUND_FLAG_CAPTURED, GetColoredBattlegroundEnemyTeamText(lastHolderAlliance), flagIcon)
                soundId = SOUNDS.BATTLEGROUND_CAPTURE_FLAG_CAPTURED_BY_OTHER_TEAM
            end
            return CreatePvPMessageParams(soundId, text, CENTER_SCREEN_ANNOUNCE_TYPE_BATTLEGROUND_OBJECTIVE)
        end
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_MURDERBALL_STATE_CHANGED] = function(objectiveKeepId, objectiveId, battlegroundContext, objectiveName, objectiveControlEvent, objectiveControlState, holderAlliance, lastHolderAlliance, holderRawCharacterName, holderDisplayName, lastHolderRawCharacterName, lastHolderDisplayName, pinType)
    if ShouldShowBattlegroundObjectiveCSA(objectiveKeepId, objectiveId, BGQUERY_LOCAL) then
        --150% because the icon textures contain a good bit of empty space
        local murderballIcon = zo_iconFormat(ZO_MapPin.GetStaticPinTexture(pinType), "150%", "150%")
        if objectiveControlEvent == OBJECTIVE_CONTROL_EVENT_FLAG_TAKEN then
            local text, soundId
            if holderAlliance == GetUnitBattlegroundTeam("player") then
                text = zo_strformat(SI_BATTLEGROUND_MURDERBALL_PICKED_UP, GetColoredBattlegroundYourTeamText(holderAlliance), murderballIcon)
                soundId = SOUNDS.BATTLEGROUND_MURDERBALL_TAKEN_OWN_TEAM
            else
                text = zo_strformat(SI_BATTLEGROUND_MURDERBALL_PICKED_UP, GetColoredBattlegroundEnemyTeamText(holderAlliance), murderballIcon)
                soundId = SOUNDS.BATTLEGROUND_MURDERBALL_TAKEN_OTHER_TEAM
            end
            return CreatePvPMessageParams(soundId, text, CENTER_SCREEN_ANNOUNCE_TYPE_BATTLEGROUND_OBJECTIVE)
        elseif objectiveControlEvent == OBJECTIVE_CONTROL_EVENT_FLAG_DROPPED then
            local text, soundId
            if lastHolderAlliance == GetUnitBattlegroundTeam("player") then
                text = zo_strformat(SI_BATTLEGROUND_MURDERBALL_DROPPED, GetColoredBattlegroundYourTeamText(lastHolderAlliance), murderballIcon)
                soundId = SOUNDS.BATTLEGROUND_MURDERBALL_DROPPED_OWN_TEAM
            else
                text = zo_strformat(SI_BATTLEGROUND_MURDERBALL_DROPPED, GetColoredBattlegroundEnemyTeamText(lastHolderAlliance), murderballIcon)
                soundId = SOUNDS.BATTLEGROUND_MURDERBALL_DROPPED_OTHER_TEAM
            end
            return CreatePvPMessageParams(soundId, text, CENTER_SCREEN_ANNOUNCE_TYPE_BATTLEGROUND_OBJECTIVE)
        elseif objectiveControlEvent == OBJECTIVE_CONTROL_EVENT_FLAG_RETURNED or objectiveControlEvent == OBJECTIVE_CONTROL_EVENT_FLAG_RETURNED_BY_TIMER then
            return CreatePvPMessageParams(SOUNDS.BATTLEGROUND_MURDERBALL_RETURNED, zo_strformat(SI_BATTLEGROUND_FLAG_RETURNED, murderballIcon), CENTER_SCREEN_ANNOUNCE_TYPE_BATTLEGROUND_OBJECTIVE)
        end
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_BATTLEGROUND_KILL] = function(killedPlayerCharacterName, killedPlayerDisplayName, killedPlayerBattlegroundAlliance, killingPlayerCharacterName, killingPlayerDisplayName, killingPlayerBattlegroundAlliance,  battlegroundKillType)
    local gameType = GetCurrentBattlegroundGameType()
    if gameType == BATTLEGROUND_GAME_TYPE_DEATHMATCH then
        local format = GetString("SI_BATTLEGROUNDKILLTYPE", battlegroundKillType)
        local killedPlayerName = ZO_GetPrimaryPlayerName(killedPlayerDisplayName, killedPlayerCharacterName)
        local coloredKilledPlayerName = GetBattlegroundTeamColor(killedPlayerBattlegroundAlliance):Colorize(killedPlayerName)
    
        if battlegroundKillType == BATTLEGROUND_KILL_TYPE_KILLING_BLOW or battlegroundKillType == BATTLEGROUND_KILL_TYPE_ASSIST then
            local you = GetBattlegroundTeamColor(killingPlayerBattlegroundAlliance):Colorize(GetString(SI_BATTLEGROUND_YOU))
            local sound
            if battlegroundKillType == BATTLEGROUND_KILL_TYPE_KILLING_BLOW then
                sound = SOUNDS.BATTLEGROUND_KILL_KILLING_BLOW
            else
                sound = SOUNDS.BATTLEGROUND_KILL_ASSIST
            end
            return CreatePvPMessageParams(sound, zo_strformat(format, you, coloredKilledPlayerName), CENTER_SCREEN_ANNOUNCE_TYPE_BATTLEGROUND_OBJECTIVE)
        elseif battlegroundKillType == BATTLEGROUND_KILL_TYPE_KILLED_BY_MY_TEAM then
            return CreatePvPMessageParams(SOUNDS.BATTLEGROUND_KILL_KILLED_BY_MY_TEAM, zo_strformat(format, GetColoredBattlegroundYourTeamText(killingPlayerBattlegroundAlliance), coloredKilledPlayerName), CENTER_SCREEN_ANNOUNCE_TYPE_BATTLEGROUND_OBJECTIVE)
        elseif battlegroundKillType == BATTLEGROUND_KILL_TYPE_STOLEN_BY_ENEMY_TEAM then
            return CreatePvPMessageParams(SOUNDS.BATTLEGROUND_KILL_STOLEN_BY_ENEMY_TEAM, zo_strformat(format, GetColoredBattlegroundEnemyTeamText(killingPlayerBattlegroundAlliance), coloredKilledPlayerName), CENTER_SCREEN_ANNOUNCE_TYPE_BATTLEGROUND_OBJECTIVE)
        end
    end
end

-- End Battleground Event Handlers --

local g_previousEndlessDungeonProgression = {0, 0, 0} -- Stage, Cycle, Arc

local function GetEndlessDungeonProgressMessageParams()
    local stage, cycle, arc = ENDLESS_DUNGEON_MANAGER:GetProgression()
    local previousStage, previousCycle, previousArc = unpack(g_previousEndlessDungeonProgression)
    if stage == 1 and cycle == 1 and arc == 1 then
        -- Force the initial CSA to roll over from all 0s to all 1s.
        previousStage, previousCycle, previousArc = 0, 0, 0
    end

    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_ROLLING_METER_PROGRESS_TEXT)
    local stageIcon, cycleIcon, arcIcon = ZO_EndlessDungeonManager.GetProgressionIcons()
    local stageNarration, cycleNarration, arcNarration = ZO_EndlessDungeonManager.GetProgressionNarrationDescriptions(stage, cycle, arc)
    local progressData =
    {
        {
            iconTexture = arcIcon,
            narrationDescription = arcNarration,
            initialValue = previousArc,
            finalValue = arc,
        },
        {
            iconTexture = cycleIcon,
            narrationDescription = cycleNarration,
            initialValue = previousCycle,
            finalValue = cycle,
        },
        {
            iconTexture = stageIcon,
            narrationDescription = stageNarration,
            initialValue = previousStage,
            finalValue = stage,
        },
    }
    messageParams:SetRollingMeterProgressData(progressData)

    -- Update the previous progression values.
    g_previousEndlessDungeonProgression[1] = stage
    g_previousEndlessDungeonProgression[2] = cycle
    g_previousEndlessDungeonProgression[3] = arc

    return messageParams
end

local function RefreshEndlessDungeonProgressionState()
    local stage, cycle, arc = ENDLESS_DUNGEON_MANAGER:GetProgression()
    g_previousEndlessDungeonProgression[1] = stage
    g_previousEndlessDungeonProgression[2] = cycle
    g_previousEndlessDungeonProgression[3] = arc
end

ENDLESS_DUNGEON_MANAGER:RegisterCallback("StateChanged", RefreshEndlessDungeonProgressionState)

local function UpdateEndlessDungeonTrackers()
    ENDLESS_DUNGEON_HUD_TRACKER:UpdateProgress()
    ENDLESS_DUNGEON_BUFF_TRACKER_GAMEPAD:UpdateProgress()
    if ENDLESS_DUNGEON_BUFF_TRACKER_KEYBOARD then
        ENDLESS_DUNGEON_BUFF_TRACKER_KEYBOARD:UpdateProgress()
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_DISPLAY_ANNOUNCEMENT] = function(primaryText, secondaryText, icon, soundId, lifespanMS, category)
    soundId = soundId == "" and SOUNDS.DISPLAY_ANNOUNCEMENT or soundId

    local messageParams
    if category == CSA_CATEGORY_ENDLESS_DUNGEON_STAGE_STARTED_TEXT then
        -- Endless Dungeon Progression CSA special case
        messageParams = GetEndlessDungeonProgressMessageParams()
        if not messageParams then
            -- The progression did not change; this should never happen.
            return
        end
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_ENDLESS_DUNGEON_PROGRESS)
        messageParams:SetOnDisplayCallback(UpdateEndlessDungeonTrackers)
    else
        -- Standard Display Announcement
        messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(category, soundId)
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_DISPLAY_ANNOUNCEMENT)
    end

    if soundId then
        messageParams:SetSound(soundId)
    end

    if icon ~= ZO_NO_TEXTURE_FILE then
        messageParams:SetIconData(icon)
    end

    if lifespanMS > 0 then
        messageParams:SetLifespanMS(lifespanMS)
    end

    -- Sanitize text.
    if primaryText == "" then
        primaryText = nil
    end
    if secondaryText == "" then
        secondaryText = nil
    end

    messageParams:SetText(primaryText, secondaryText)
    return messageParams
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_RAID_TRIAL_STARTED] = function(raidName, isWeekly)
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.RAID_TRIAL_STARTED)
    messageParams:SetText(zo_strformat(SI_TRIAL_STARTED, raidName))
    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_RAID_TRIAL)
    return messageParams
end

do
    local TRIAL_COMPLETE_LIFESPAN_MS = 10000
    CENTER_SCREEN_EVENT_HANDLERS[EVENT_RAID_TRIAL_COMPLETE] = function(raidName, score, totalTime)
        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_RAID_COMPLETE_TEXT, SOUNDS.RAID_TRIAL_COMPLETED)
        local wasUnderTargetTime = GetRaidDuration() <= GetRaidTargetTime()
        local formattedTime = ZO_FormatTimeMilliseconds(totalTime, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_SECONDS)
        local vitalityBonus = GetCurrentRaidLifeScoreBonus()
        local currentCount = GetRaidReviveCountersRemaining()
        local maxCount = GetCurrentRaidStartingReviveCounters()

        messageParams:SetEndOfRaidData({ score, formattedTime, wasUnderTargetTime, vitalityBonus, zo_strformat(SI_REVIVE_COUNTER_REVIVES_USED, currentCount, maxCount) })
        messageParams:SetText(zo_strformat(SI_TRIAL_COMPLETED_LARGE, raidName))
        messageParams:SetLifespanMS(TRIAL_COMPLETE_LIFESPAN_MS)
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_RAID_TRIAL)
        return messageParams
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_RAID_TRIAL_FAILED] = function(raidName, score)
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.RAID_TRIAL_FAILED)
    messageParams:SetText(zo_strformat(SI_TRIAL_FAILED, raidName))
    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_RAID_TRIAL)
    return messageParams
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_RAID_TRIAL_NEW_BEST_SCORE] = function(raidName, score, isWeekly)
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SMALL_TEXT, SOUNDS.RAID_TRIAL_NEW_BEST)
    messageParams:SetText(zo_strformat(isWeekly and SI_TRIAL_NEW_BEST_SCORE_WEEKLY or SI_TRIAL_NEW_BEST_SCORE_LIFETIME, raidName))
    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_RAID_TRIAL)
    return messageParams
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_RAID_REVIVE_COUNTER_UPDATE] = function(currentCount, countDelta)
-- TODO: revisit this once there is a way to properly handle this in client/server code
    if not IsRaidInProgress() then
        return
    end
    if countDelta < 0 then
        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.RAID_TRIAL_COUNTER_UPDATE)
        messageParams:SetText(zo_strformat(SI_REVIVE_COUNTER_UPDATED_LARGE, "EsoUI/Art/Trials/VitalityDepletion.dds"))
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_RAID_TRIAL)
        return messageParams
    end
end

do
    local TRIAL_SCORE_REASON_TO_ASSETS =
    {
        [RAID_POINT_REASON_KILL_MINIBOSS]           = { icon = "EsoUI/Art/Trials/trialPoints_normal.dds", soundId = SOUNDS.RAID_TRIAL_SCORE_ADDED_NORMAL },
        [RAID_POINT_REASON_KILL_BOSS]               = { icon = "EsoUI/Art/Trials/trialPoints_veryHigh.dds", soundId = SOUNDS.RAID_TRIAL_SCORE_ADDED_VERY_HIGH },

        [RAID_POINT_REASON_BONUS_ACTIVITY_LOW]      = { icon = "EsoUI/Art/Trials/trialPoints_veryLow.dds", soundId = SOUNDS.RAID_TRIAL_SCORE_ADDED_VERY_LOW },
        [RAID_POINT_REASON_BONUS_ACTIVITY_MEDIUM]   = { icon = "EsoUI/Art/Trials/trialPoints_low.dds", soundId = SOUNDS.RAID_TRIAL_SCORE_ADDED_LOW },
        [RAID_POINT_REASON_BONUS_ACTIVITY_HIGH]     = { icon = "EsoUI/Art/Trials/trialPoints_high.dds", soundId = SOUNDS.RAID_TRIAL_SCORE_ADDED_HIGH },

        [RAID_POINT_REASON_SOLO_ARENA_PICKUP_ONE]   = { icon = "EsoUI/Art/Trials/trialPoints_veryLow.dds", soundId = SOUNDS.RAID_TRIAL_SCORE_ADDED_VERY_LOW },
        [RAID_POINT_REASON_SOLO_ARENA_PICKUP_TWO]   = { icon = "EsoUI/Art/Trials/trialPoints_low.dds", soundId = SOUNDS.RAID_TRIAL_SCORE_ADDED_LOW },
        [RAID_POINT_REASON_SOLO_ARENA_PICKUP_THREE] = { icon = "EsoUI/Art/Trials/trialPoints_normal.dds", soundId = SOUNDS.RAID_TRIAL_SCORE_ADDED_NORMAL },
        [RAID_POINT_REASON_SOLO_ARENA_PICKUP_FOUR]  = { icon = "EsoUI/Art/Trials/trialPoints_high.dds", soundId = SOUNDS.RAID_TRIAL_SCORE_ADDED_HIGH },
        [RAID_POINT_REASON_SOLO_ARENA_COMPLETE]     = { icon = "EsoUI/Art/Trials/trialPoints_veryHigh.dds", soundId = SOUNDS.RAID_TRIAL_SCORE_ADDED_VERY_HIGH },
    }

    CENTER_SCREEN_EVENT_HANDLERS[EVENT_RAID_TRIAL_SCORE_UPDATE] = function(scoreUpdateReason, scoreAmount, totalScore)
        local reasonAssets = TRIAL_SCORE_REASON_TO_ASSETS[scoreUpdateReason]
        if reasonAssets then
            local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, reasonAssets.soundId)
            messageParams:SetText(zo_strformat(SI_TRIAL_SCORE_UPDATED_LARGE, reasonAssets.icon, scoreAmount))
            messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_RAID_TRIAL)
            return messageParams
        end
    end
end

do
    local CHAMPION_UNLOCKED_LIFESPAN_MS = 12000
    CENTER_SCREEN_EVENT_HANDLERS[EVENT_CHAMPION_LEVEL_ACHIEVED] = function(wasChampionSystemUnlocked)
        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.CHAMPION_POINT_GAINED)
        local formattedIcon = zo_iconFormat(ZO_GetChampionPointsIcon(), "100%", "100%")
        messageParams:SetText(zo_strformat(SI_CHAMPION_ANNOUNCEMENT_UNLOCKED, formattedIcon))
        if wasChampionSystemUnlocked then
            local championPoints = GetPlayerChampionPointsEarned()
            local currentChampionXP = GetPlayerChampionXP()
            local barParams = CENTER_SCREEN_ANNOUNCE:CreateBarParams(PPB_CP, championPoints, currentChampionXP, currentChampionXP)
            barParams:SetTriggeringEvent(EVENT_CHAMPION_LEVEL_ACHIEVED)
            barParams:SetShowNoGain(true)
            ValidateProgressBarParams(barParams)
            messageParams:SetBarParams(barParams)
        else
            local totalChampionPoints = GetPlayerChampionPointsEarned()
            local championXPGained = 0;
            for i = 0, (totalChampionPoints - 1) do
                championXPGained = championXPGained + GetNumChampionXPInChampionPoint(i)
            end
            local barParams = CENTER_SCREEN_ANNOUNCE:CreateBarParams(PPB_CP, 0, 0, championXPGained)
            barParams:SetTriggeringEvent(EVENT_CHAMPION_LEVEL_ACHIEVED)
            ValidateProgressBarParams(barParams)
            messageParams:SetBarParams(barParams)
            messageParams:SetLifespanMS(CHAMPION_UNLOCKED_LIFESPAN_MS)
        end
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_CHAMPION_LEVEL_ACHIEVED)
        return messageParams
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_CHAMPION_POINT_GAINED] = function(pointDelta)
    -- adding one so that we are starting from the first gained point instead of the starting champion points
    local endingPoints = GetPlayerChampionPointsEarned()
    local startingPoints = endingPoints - pointDelta + 1
    local championPointsByType = 
    {
        [CHAMPION_DISCIPLINE_TYPE_WORLD] = 0,
        [CHAMPION_DISCIPLINE_TYPE_COMBAT] = 0,
        [CHAMPION_DISCIPLINE_TYPE_CONDITIONING] = 0,
    }

    while startingPoints <= endingPoints do
        local pointType = GetChampionPointPoolForRank(startingPoints)
        championPointsByType[pointType] = championPointsByType[pointType] + 1
        startingPoints = startingPoints + 1
    end

    local pointsLines = {}
    for pointType, amount in pairs(championPointsByType) do
        if amount > 0 then
            local disciplineData = CHAMPION_DATA_MANAGER:FindChampionDisciplineDataByType(pointType)
            local icon = disciplineData:GetHUDIcon()
            local disciplineName = disciplineData:GetRawName()
            table.insert(pointsLines, zo_strformat(SI_CHAMPION_POINT_TYPE, amount, icon, disciplineName))
        end
    end
    local secondLine = table.concat(pointsLines, "\n")
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.CHAMPION_POINT_GAINED)
    messageParams:SetText(zo_strformat(SI_CHAMPION_POINT_EARNED, pointDelta), secondLine)
    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_CHAMPION_POINT_GAINED)
    messageParams:MarkSuppressIconFrame()

    return messageParams
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_INVENTORY_BAG_CAPACITY_CHANGED] = function(previousCapacity, currentCapacity, previousUpgrade, currentUpgrade)
    if previousCapacity > 0 and previousCapacity ~= currentCapacity and previousUpgrade ~= currentUpgrade then
        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
        messageParams:SetText(GetString(SI_INVENTORY_BAG_UPGRADE_ANOUNCEMENT_TITLE), zo_strformat(SI_INVENTORY_BAG_UPGRADE_ANOUNCEMENT_DESCRIPTION, previousCapacity, currentCapacity))
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_BAG_CAPACITY_CHANGED)
        return messageParams
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_INVENTORY_BANK_CAPACITY_CHANGED] = function(previousCapacity, currentCapacity, previousUpgrade, currentUpgrade)
    if previousCapacity > 0 and previousCapacity ~= currentCapacity and previousUpgrade ~= currentUpgrade then
        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
        messageParams:SetText(GetString(SI_INVENTORY_BANK_UPGRADE_ANOUNCEMENT_TITLE), zo_strformat(SI_INVENTORY_BANK_UPGRADE_ANOUNCEMENT_DESCRIPTION, previousCapacity, currentCapacity))
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_BANK_CAPACITY_CHANGED)
        return messageParams
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_FORCE_RESPEC] = function(respecType)
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
    messageParams:SetText(GetString("SI_RESPECTYPE_POINTSRESETTITLE", respecType), GetString("SI_RESPECTYPE", respecType))
    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_FORCE_RESPEC)
    return messageParams
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_CRAFTED_ABILITY_RESET] = function(craftedAbilityId, totalNumReset, isLastReset)
    local RESET_GROUPING_THRESHOLD = 5
    if totalNumReset < RESET_GROUPING_THRESHOLD then
        local craftedAbilityData = SCRIBING_DATA_MANAGER:GetCraftedAbilityData(craftedAbilityId)
        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
        messageParams:SetText(GetString(SI_CRAFTED_ABILITY_RESET_ANNOUNCE_TITLE), craftedAbilityData:GetFormattedNameWithSkillLine())
        -- Treat these the same way we treat force respec
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_FORCE_RESPEC)
        messageParams:SetIconData(craftedAbilityData:GetIcon())
        messageParams:MarkSuppressIconFrame()
        return messageParams
    elseif isLastReset then
        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
        messageParams:SetText(GetString(SI_CRAFTED_ABILITIES_RESET_ANNOUNCE_TITLE), zo_strformat(SI_CRAFTED_ABILITIES_RESET_ANNOUNCE_BODY, totalNumReset))
        -- Treat these the same way we treat force respec
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_FORCE_RESPEC)
        return messageParams
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_ACTIVITY_FINDER_ACTIVITY_COMPLETE] = function()
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.LFG_COMPLETE_ANNOUNCEMENT)
    messageParams:SetText(GetString(SI_ACTIVITY_FINDER_ACTIVITY_COMPLETE_ANNOUNCEMENT_TEXT))
    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_ACTIVITY_COMPLETE)
    return messageParams
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_TRIBUTE_CLUB_RANK_CHANGED] = function(newClubRank)
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.TRIBUTE_RANK_CHANGE)
    messageParams:SetText(GetString(SI_TRIBUTE_CLUB_RANK_CHANGE_ANNOUNCEMENT_TITLE), zo_strformat(SI_TRIBUTE_CLUB_RANK_CHANGE_ANNOUNCEMENT_CONTENT, newClubRank + 1))
    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_TRIBUTE_CLUB_RANK_CHANGED)
    return messageParams
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_DUEL_COUNTDOWN] = function(startTimeMS)
    local displayTime = startTimeMS - GetFrameTimeMilliseconds()
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_COUNTDOWN_TEXT, SOUNDS.DUEL_START)
    messageParams:SetLifespanMS(displayTime)
    messageParams:SetIconData("EsoUI/Art/HUD/HUD_Countdown_Badge_Dueling.dds")
    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COUNTDOWN)
    return messageParams
end

do
    local DUEL_BOUNDARY_WARNING_LIFESPAN_MS = 2000
    local DUEL_BOUNDARY_WARNING_UPDATE_TIME_MS = 2100
    local lastEventTime = 0
    local function CheckBoundary()
        if IsNearDuelBoundary() then
            local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SMALL_TEXT, SOUNDS.DUEL_BOUNDARY_WARNING)
            messageParams:SetText(GetString(SI_DUELING_NEAR_BOUNDARY_CSA))
            messageParams:SetLifespanMS(DUEL_BOUNDARY_WARNING_LIFESPAN_MS)
            messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_DUEL_NEAR_BOUNDARY)
            CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
        end
    end

    CENTER_SCREEN_EVENT_HANDLERS[EVENT_DUEL_NEAR_BOUNDARY] = function(isInWarningArea)
        if isInWarningArea then
            local nowEventTime = GetFrameTimeMilliseconds()
            EVENT_MANAGER:RegisterForUpdate("EVENT_DUEL_NEAR_BOUNDARY", DUEL_BOUNDARY_WARNING_UPDATE_TIME_MS, CheckBoundary)
            if nowEventTime > lastEventTime + DUEL_BOUNDARY_WARNING_UPDATE_TIME_MS then
                lastEventTime = nowEventTime
                CheckBoundary()
            end
        else
            EVENT_MANAGER:UnregisterForUpdate("EVENT_DUEL_NEAR_BOUNDARY")
        end
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_DUEL_FINISHED] = function(result, wasLocalPlayersResult, opponentCharacterName, opponentDisplayName)
    local resultString = GetString("SI_DUELRESULT", result)
    local userFacingName
    if wasLocalPlayersResult then
        local playerDisplayName = GetDisplayName()
        local playerCharacterName = GetUnitName("player")
        userFacingName = ZO_GetPrimaryPlayerNameWithSecondary(playerDisplayName, playerCharacterName)
    else
        userFacingName = ZO_GetPrimaryPlayerNameWithSecondary(opponentDisplayName, opponentCharacterName)
    end
    resultString = zo_strformat(resultString, userFacingName)

    local localPlayerWonDuel = (result == DUEL_RESULT_WON and wasLocalPlayersResult) or 
                                (result == DUEL_RESULT_FORFEIT and not wasLocalPlayersResult)
    local localPlayerForfeitDuel = (result == DUEL_RESULT_FORFEIT and wasLocalPlayersResult)
    local resultSound = nil
    if localPlayerWonDuel then
        resultSound = SOUNDS.DUEL_WON
    elseif localPlayerForfeitDuel then
        resultSound = SOUNDS.DUEL_FORFEIT
    end

    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, resultSound)
    messageParams:SetText(resultString)
    messageParams:MarkShowImmediately()
    messageParams:MarkQueueImmediately()
    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_DUEL_FINISHED)

    return messageParams
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_RIDING_SKILL_IMPROVEMENT] = function(ridingSkill, previous, current, source)
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
    messageParams:SetText(GetString(SI_RIDING_SKILL_ANNOUCEMENT_BANNER), zo_strformat(SI_RIDING_SKILL_ANNOUCEMENT_SKILL_INCREASE, GetString("SI_RIDINGTRAINTYPE", ridingSkill), previous, current))
    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_RIDING_SKILL_IMPROVEMENT)
    return messageParams
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_ESO_PLUS_FREE_TRIAL_STATUS_CHANGED] = function(hasFreeTrial)
    local text
    local soundId
    if hasFreeTrial then
        text = GetString(SI_ESO_PLUS_FREE_TRIAL_STARTED)
        soundId = SOUNDS.ESO_PLUS_TRIAL_STARTED
    else
        text = GetString(SI_ESO_PLUS_FREE_TRIAL_ENDED)
        soundId = SOUNDS.ESO_PLUS_TRIAL_ENDED
    end
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, soundId)
    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_ESO_PLUS_SUBSCRIPTION_CHANGED)
    messageParams:SetText(text)
    return messageParams
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_OUTFIT_CHANGE_RESPONSE] = function(result, actorCategory, outfitIndex)
    if result == APPLY_OUTFIT_CHANGES_RESULT_SUCCESS then
        local outfitManipulator = ZO_OUTFIT_MANAGER:GetOutfitManipulator(actorCategory, outfitIndex)
        if outfitManipulator then
            local outfitName = outfitManipulator:GetOutfitName()
            local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.OUTFIT_CHANGES_APPLIED)
            messageParams:SetText(zo_strformat(GetString("SI_APPLYOUTFITCHANGESRESULT", result), outfitName))
            messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_OUTFIT_CHANGES_APPLIED)
            return messageParams
        end
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_DAILY_LOGIN_REWARDS_CLAIMED] = function()
    local rewardId, quantity = GetDailyLoginRewardInfoForCurrentMonth(GetDailyLoginNumRewardsClaimedInMonth())
    local claimedDailyLoginReward = REWARDS_MANAGER:GetInfoForDailyLoginReward(rewardId, quantity)
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.DAILY_LOGIN_REWARDS_CLAIM_ANNOUNCEMENT)
    local secondaryText = claimedDailyLoginReward:GetQuantity() > 1 and claimedDailyLoginReward:GetFormattedNameWithStack() or claimedDailyLoginReward:GetFormattedName()
    messageParams:SetText(GetString(SI_DAILY_LOGIN_REWARDS_CLAIMED_ANNOUNCEMENT), secondaryText)
    messageParams:SetIconData(claimedDailyLoginReward:GetPlatformLootIcon())
    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_DAILY_LOGIN_REWARD_CLAIMED)
    return messageParams
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_ANTIQUITY_LEAD_ACQUIRED] = function(antiquityId)
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
    local antiquityData = ANTIQUITY_DATA_MANAGER:GetAntiquityData(antiquityId)
    local secondaryText = zo_strformat(SI_ANTIQUITY_LEAD_ACQUIRED_TEXT, antiquityData:GetColorizedName())
    messageParams:SetText(GetString(SI_ANTIQUITY_LEAD_ACQUIRED_TITLE), secondaryText)
    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_ANTIQUITY_LEAD_ACQUIRED)
    return messageParams
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_ANTIQUITY_DIGGING_READY_TO_PLAY] = function()
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
    messageParams:SetText(GetString(SI_ANTIQUITIES_DIGGING_ANNOUNCEMENT_BEGIN_TITLE), GetString(SI_ANTIQUITIES_DIGGING_ANNOUNCEMENT_BEGIN_TEXT))
    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_ANTIQUITY_DIGGING_GAME_UPDATE)
    return messageParams
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_ANTIQUITY_DIGGING_ANTIQUITY_UNEARTHED] = function()
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
    local antiquityId = GetDigSpotAntiquityId()
    --If the game is over then the end of game summary will handle showing this info
    if not IsDiggingGameOver() then
        local antiquityData = ANTIQUITY_DATA_MANAGER:GetAntiquityData(antiquityId)
        if antiquityData then
            local title = zo_strformat(SI_ANTIQUITIES_DIGGING_ANNOUNCEMENT_ANTIQUITY_UNEARTHED_TITLE, antiquityData:GetColorizedName())
            messageParams:SetText(title, GetString(SI_ANTIQUITIES_DIGGING_ANNOUNCEMENT_ANTIQUITY_UNEARTHED_TEXT))
            messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_ANTIQUITY_DIGGING_GAME_UPDATE)
            return messageParams
        end
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_ANTIQUITY_DIGGING_BONUS_LOOT_UNEARTHED] = function()
    if not IsDiggingGameOver() then
        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
        messageParams:SetText(GetString(SI_ANTIQUITIES_DIGGING_ANNOUNCEMENT_BONUS_LOOT_TITLE))
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_ANTIQUITY_DIGGING_GAME_UPDATE)
        return messageParams
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_ANTIQUITY_SCRYING_RESULT] = function(result)
    --The map handles the case where you improved and unlocked more goals than before
    if result == ANTIQUITY_SCRYING_RESULT_NO_PROGRESS or result == ANTIQUITY_SCRYING_RESULT_NO_ADDITIONAL_PROGRESS then
        local antiquityId = GetScryingCurrentAntiquityId()
        local antiquityData = ANTIQUITY_DATA_MANAGER:GetAntiquityData(antiquityId)
        if antiquityData then
            local numGoalsAchieved = antiquityData:GetNumGoalsAchieved()
            local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SCRYING_PROGRESS_TEXT)
            messageParams:SetText(GetString("SI_ANTIQUITYSCRYINGRESULT", result))
            messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_ANTIQUITY_SCRYING_RESULT)
            messageParams:SetScryingProgressData(numGoalsAchieved, numGoalsAchieved, antiquityData:GetTotalNumGoals())
            return messageParams
        end
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_TIMED_ACTIVITY_PROGRESS_UPDATED] = function(timedActivityIndex, previousProgress, currentProgress, complete)
    if complete then
        local activityData = ZO_TimedActivityData:New(timedActivityIndex)
        if activityData then
            local activityName = activityData:GetName()
            if activityName ~= "" then
                local activityType = activityData:GetType()
                local activityTypeName = GetString("SI_TIMEDACTIVITYTYPE", activityType)
                local activityCompletionType = zo_strformat(SI_TIMED_ACTIVITY_COMPLETED_CSA, activityTypeName)

                local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.ENDEAVOR_COMPLETED)
                messageParams:SetText(activityCompletionType, activityName)
                return messageParams
            end
        end
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_TIMED_ACTIVITY_TYPE_PROGRESS_UPDATED] = function(activityType, previousNumComplete, currentNumComplete, complete)
    if complete then
        local activityTypeName = GetString("SI_TIMEDACTIVITYTYPE", activityType)
        local _, maxNumActivities = TIMED_ACTIVITIES_MANAGER:GetTimedActivityTypeLimitInfo(activityType)
        local messageTitle = zo_strformat(SI_TIMED_ACTIVITY_TYPE_COMPLETED_CSA, currentNumComplete, maxNumActivities, activityTypeName)
        local messageSubheading = GetString("SI_TIMEDACTIVITYTYPE_FOLLOWUPHINT", activityType)

        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
        messageParams:SetText(messageTitle, messageSubheading)
        return messageParams
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_ACHIEVEMENTS_COMPLETED_ON_UPGRADE_TO_ACCOUNT_WIDE] = function(numCompletedAchievement)
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
    local messageTitle = zo_strformat(SI_ACHIEVEMENT_ON_UPGRADE_TITLE, numCompletedAchievement)
    local messageSubheading = GetString(SI_ACHIEVEMENT_ON_UPGRADE_TEXT)
    messageParams:SetText(messageTitle, messageSubheading)
    return messageParams
end

local TRIBUTE_GAME_FLOW_STATE_CHANGE_MESSAGE_LIFESPAN_MS = 3000
CENTER_SCREEN_EVENT_HANDLERS[EVENT_TRIBUTE_GAME_FLOW_STATE_CHANGE] = function(gameFlowState)
    if gameFlowState == TRIBUTE_GAME_FLOW_STATE_PATRON_DRAFT then
        if not DoesTributeSkipPatronDrafting() then
            local firstPick, playerType = GetTributePlayerInfo(GetActiveTributePlayerPerspective())
            firstPick = playerType ~= TRIBUTE_PLAYER_TYPE_NPC and ZO_FormatUserFacingDisplayName(firstPick) or firstPick
            local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
            messageParams:SetText(GetString(SI_TRIBUTE_DRAFTING_PHASE_ANNOUNCEMENT_TITLE), ZO_NORMAL_TEXT:Colorize(zo_strformat(SI_TRIBUTE_DRAFTING_PHASE_ANNOUNCEMENT_BODY, firstPick)))
            messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_TRIBUTE_GAME_STATE_CHANGED)
            messageParams:SetLifespanMS(TRIBUTE_GAME_FLOW_STATE_CHANGE_MESSAGE_LIFESPAN_MS)
            messageParams:MarkShowBackground()
            return messageParams
        end
    elseif gameFlowState == TRIBUTE_GAME_FLOW_STATE_PLAYING then
        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
        local firstPlay, playerType = GetTributePlayerInfo(GetActiveTributePlayerPerspective())
        firstPlay = playerType ~= TRIBUTE_PLAYER_TYPE_NPC and ZO_FormatUserFacingDisplayName(firstPlay) or firstPlay
        messageParams:SetText(GetString(SI_TRIBUTE_PLAYING_PHASE_ANNOUNCEMENT_TITLE), ZO_NORMAL_TEXT:Colorize(zo_strformat(SI_TRIBUTE_PLAYING_PHASE_ANNOUNCEMENT_BODY, firstPlay)))
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_TRIBUTE_GAME_STATE_CHANGED)
        messageParams:SetLifespanMS(TRIBUTE_GAME_FLOW_STATE_CHANGE_MESSAGE_LIFESPAN_MS)
        messageParams:MarkShowBackground()
        return messageParams
    end
end

local TRIBUTE_OPPONENT_PRESTIGE_MESSAGE_LIFESPAN_MS = 2000
local TRIBUTE_TURN_STARTED_MESSAGE_LIFESPAN_MS = 1600
CENTER_SCREEN_EVENT_HANDLERS[EVENT_TRIBUTE_PLAYER_TURN_STARTED] = function(isLocalPlayer)
    if isLocalPlayer then
        local showBeginTurn = true
        local opponentPrestige = GetTributePlayerPerspectiveResource(TRIBUTE_PLAYER_PERSPECTIVE_OPPONENT, TRIBUTE_RESOURCE_PRESTIGE)
        --If the opponent has at least the amount of prestige required to win then they are close to a prestige victory
        if opponentPrestige >= GetTributePrestigeRequiredToWin() then
            local prestigeMessageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.TRIBUTE_TURN_START_OPPONENT_PRESTIGE_VICTORY_NEAR)
            local opponentName, playerType = GetTributePlayerInfo(TRIBUTE_PLAYER_PERSPECTIVE_OPPONENT)
            opponentName = playerType ~= TRIBUTE_PLAYER_TYPE_NPC and ZO_FormatUserFacingDisplayName(opponentName) or opponentName
            local messageTitle = zo_strformat(SI_TRIBUTE_OPPONENT_PRESTIGE_ANNOUNCEMENT_TITLE, opponentName, opponentPrestige)
            prestigeMessageParams:SetText(messageTitle, ZO_NORMAL_TEXT:Colorize(GetString(SI_TRIBUTE_OPPONENT_PRESTIGE_ANNOUNCEMENT_BODY)))
            prestigeMessageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_TRIBUTE_GAME_STATE_CHANGED)
            prestigeMessageParams:MarkShowBackground()
            prestigeMessageParams:SetLifespanMS(TRIBUTE_OPPONENT_PRESTIGE_MESSAGE_LIFESPAN_MS)
            CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(prestigeMessageParams)
            showBeginTurn = false
        end

        local messageSubheading = nil
        local sound = SOUNDS.TRIBUTE_TURN_START
        local opponentFavorCount = GetNumPatronsFavoringPlayerPerspective(TRIBUTE_PLAYER_PERSPECTIVE_OPPONENT)
        -- Is the opponent 1 favor away from victory (ignoring neutral Patron)?
        if opponentFavorCount == (TRIBUTE_PATRON_DRAFT_ID_MAX_VALUE - 1) then
            local localPlayerFavorCount = GetNumPatronsFavoringPlayerPerspective(TRIBUTE_PLAYER_PERSPECTIVE_SELF)
            -- If the local player doesn't have favor with the last Patron, the opponent is 1 action away from victory
            if localPlayerFavorCount == 0 then
                local opponentName, playerType = GetTributePlayerInfo(TRIBUTE_PLAYER_PERSPECTIVE_OPPONENT)
                opponentName = playerType ~= TRIBUTE_PLAYER_TYPE_NPC and ZO_FormatUserFacingDisplayName(opponentName) or opponentName
                messageSubheading = ZO_NORMAL_TEXT:Colorize(zo_strformat(SI_TRIBUTE_OPPONENT_FAVOR_ANNOUNCEMENT_BODY, opponentName))
                sound = SOUNDS.TRIBUTE_TURN_START_OPPONENT_PENULTIMATE_FAVOR
                --When the opponent is close to both a prestige and patron victory, we want to show both CSAs, so set this back to true
                showBeginTurn = true
            end
        end

        --If we are showing the prestige CSA, only show the begin turn CSA if we also need to display the patron victory message
        if showBeginTurn then
            local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, sound)
            messageParams:SetText(GetString(SI_TRIBUTE_TURN_START_ANNOUNCEMENT_TITLE), messageSubheading)
            messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_TRIBUTE_GAME_STATE_CHANGED)
            messageParams:SetLifespanMS(TRIBUTE_TURN_STARTED_MESSAGE_LIFESPAN_MS)
            messageParams:MarkShowBackground()
            return messageParams
        end
    end
end

CENTER_SCREEN_EVENT_HANDLERS[EVENT_CONSOLIDATED_STATION_SETS_UPDATED] = function(craftingStationFurnitureId)
    if HOUSING_EDITOR_STATE:IsLocalPlayerHouseOwner() then
        local function GetNextDirtyUnlockedSetIdIter(_, previousSetId)
            return GetNextDirtyUnlockedConsolidatedSmithingItemSetId(previousSetId)
        end

        local unlockedSetIds = {}
        for setId in GetNextDirtyUnlockedSetIdIter do
            table.insert(unlockedSetIds, setId)
        end

        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.CONSOLIDATED_SMITHING_SET_ADDED)
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_CONSOLIDATED_STATION_SETS_UPDATED)
        local stationIcon = select(2, GetPlacedHousingFurnitureInfo(craftingStationFurnitureId))
        messageParams:SetIconData(stationIcon)
        local messageTitle = GetString(SI_SMITHING_CONSOLIDATED_STATION_SETS_UPDATED_ANNOUNCEMENT_TITLE)
        local numUnlockedSetIds = #unlockedSetIds
        if numUnlockedSetIds == 1 then
            local setName = GetItemSetName(unlockedSetIds[1])
            local messageSubheading = zo_strformat(SI_SMITHING_CONSOLIDATED_STATION_SETS_UPDATED_SINGLE_SET_MESSAGE, setName)
            messageParams:SetText(messageTitle, messageSubheading)
            return messageParams
        elseif numUnlockedSetIds > 1 then
            local messageSubheading = zo_strformat(SI_SMITHING_CONSOLIDATED_STATION_SETS_UPDATED_MULTI_SET_MESSAGE, numUnlockedSetIds)
            messageParams:SetText(messageTitle, messageSubheading)
            return messageParams
        end
    end
end

function ZO_CenterScreenAnnounce_GetEventHandlers()
    return CENTER_SCREEN_EVENT_HANDLERS
end

function ZO_CenterScreenAnnounce_GetEventHandler(eventId)
    return CENTER_SCREEN_EVENT_HANDLERS[eventId]
end

function ZO_CenterScreenAnnounce_InitializePriorities()
    -- Lower-priority events
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_PLEDGE_OF_MARA_RESULT)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_ACHIEVEMENT_AWARDED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_ARTIFACT_CONTROL_STATE)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_DAEDRIC_ARTIFACT_OBJECTIVE_STATE_CHANGED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_CORONATE_EMPEROR)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_DEPOSE_EMPEROR)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_REVENGE_KILL)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_AVENGE_KILL)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_ABILITY_PROGRESSION_RANK_UPDATE)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_SKILL_LINE_ADDED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_SKILL_RANK_UPDATE)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_SKILL_XP_UPDATE)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_LORE_COLLECTION_COMPLETED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_LORE_COLLECTION_COMPLETED_SKILL_EXPERIENCE)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_LORE_BOOK_LEARNED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_LORE_BOOK_LEARNED_SKILL_EXPERIENCE)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_ABILITY_PROGRESSION_RANK_MORPH)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_SKILL_POINTS_PARTIAL_GAINED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_SKILL_POINTS_GAINED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_RAID_TRIAL)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_DISCOVERY_EXPERIENCE)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_CHAMPION_POINT_GAINED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_CHAMPION_LEVEL_ACHIEVED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_EXPERIENCE_GAIN)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_OBJECTIVE_COMPLETED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_DISPLAY_ANNOUNCEMENT)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_COMPLETED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_PROGRESSION_CHANGED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_CONDITION_COMPLETED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_ADDED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_ANTIQUITY_DIG_SITES_UPDATED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_ANTIQUITY_SCRYING_RESULT)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_POI_DISCOVERED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_JUSTICE_INFAMY_CHANGED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_JUSTICE_NOW_KOS)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_JUSTICE_NO_LONGER_KOS)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_SINGLE_TRIBUTE_CARD_UPDATED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_SINGLE_COLLECTIBLE_UPDATED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_CONSOLIDATED_STATION_SETS_UPDATED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_RIDING_SKILL_IMPROVEMENT)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_BATTLEGROUND_OBJECTIVE)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_BATTLEGROUND_NEARING_VICTORY)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_BATTLEGROUND_MINUTE_WARNING)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_BATTLEGROUND_ROUND_STARTING)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_SYSTEM_BROADCAST)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_LEVEL_GAIN)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_TIMED_ACTIVITY_COMPLETED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_ACTIVITY_COMPLETE)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_DUEL_FINISHED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_DUEL_NEAR_BOUNDARY)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_DUEL_COUNTDOWN)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_TRIBUTE_GAME_STATE_CHANGED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_ENDLESS_DUNGEON_BUFF_ADDED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_ENDLESS_DUNGEON_ATTEMPTS_REMAINING_CHANGED)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_ENDLESS_DUNGEON_PROGRESS)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_FORCE_RESPEC)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_COUNTDOWN)
    ZO_CenterScreenAnnounce_SetPriority(CENTER_SCREEN_ANNOUNCE_TYPE_CRAFTING_RESULTS)
    -- Higher-priority events

    -- Miscellaneous event handlers
    local function OnQuestRemoved(eventId, isCompleted, journalIndex, questName, zoneIndex, poiIndex)
        if not isCompleted then
            PlaySound(SOUNDS.QUEST_ABANDONED)
        end
    end

    -- Quest Advancement displays all the "appropriate" conditions that the player needs to do to advance the current step
    local function OnQuestAdvanced(eventId, questIndex, questName, isPushed, isComplete, mainStepChanged, doesConditionHideAnnouncements)
        if not mainStepChanged or doesConditionHideAnnouncements then
            return
        end

        local announceObject = CENTER_SCREEN_ANNOUNCE
        local sound = SOUNDS.QUEST_OBJECTIVE_STARTED

        for stepIndex = QUEST_MAIN_STEP_INDEX, GetJournalQuestNumSteps(questIndex) do
            local _, visibility, stepType, stepOverrideText, conditionCount = GetJournalQuestStepInfo(questIndex, stepIndex)

            if visibility == nil or visibility == QUEST_STEP_VISIBILITY_OPTIONAL then
                if stepOverrideText ~= "" then
                    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SMALL_TEXT, sound)
                    messageParams:SetText(stepOverrideText)
                    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_PROGRESSION_CHANGED)
                    announceObject:AddMessageWithParams(messageParams)
                    sound = nil -- no longer needed, we played it once
                else
                    for conditionIndex = 1, conditionCount do
                        local conditionText, curCount, maxCount, isFailCondition, isConditionComplete, _, isVisible  = GetJournalQuestConditionInfo(questIndex, stepIndex, conditionIndex)

                        if not (isFailCondition or isConditionComplete) and isVisible then
                            local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SMALL_TEXT, sound)
                            messageParams:SetText(conditionText)
                            messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_PROGRESSION_CHANGED)
                            announceObject:AddMessageWithParams(messageParams)
                            sound = nil -- no longer needed, we played it once
                        end
                    end
                end
            end
        end
    end

    local function OnQuestAdded(eventId, questIndex)
        OnQuestAdvanced(EVENT_QUEST_ADVANCED, questIndex, nil, nil, nil, true)
    end

    EVENT_MANAGER:RegisterForEvent("CSA_MiscellaneousHandlers", EVENT_QUEST_REMOVED, OnQuestRemoved)
    EVENT_MANAGER:RegisterForEvent("CSA_MiscellaneousHandlers", EVENT_QUEST_ADVANCED, OnQuestAdvanced)
    EVENT_MANAGER:RegisterForEvent("CSA_MiscellaneousHandlers", EVENT_QUEST_ADDED, OnQuestAdded)
end

-- Center Screen Queueable Handlers
-- Usage: Whenever there is an event type that occurs multiple times within a short timeframe
-- add another table entry with data to help facilitate the combining of the multiple events into a single call
--      updateTimeDelaySeconds: The time delay from when an event that is marked as queueable is received to when the event enters into the regular event queue.
--                              The system will restart the time after each new event is received
--      updateParameters:       A table of parameter positions that should be overwritten with the latest data from the newest event received.
--                              The position is derived from the parameters in the event callback function defined in the CENTER_SCREEN_EVENT_HANDLERS table for the same event. 
--      conditionParameters:    A table of parameter positions that should be unique amoung any given number of eventIds. For example, if you kill a monster that gives
--                              exp and guild rep, they will both come down as skill xp update events, but their skilltype and skillindex values are different, so they should be added the to system independently
--                              and not added together for updating

local CENTER_SCREEN_QUEUEABLE_EVENT_HANDLERS = {}

do
    local PARAMETER_RIDING_SKILL_TYPE       = 1
    local PARAMETER_CURRENT_RIDING_SKILL    = 3
    local PARAMETER_RIDING_SKILL_SOURCE     = 4

    local PARAMETER_SKILL_TYPE              = 1
    local PARAMETER_SKILL_INDEX             = 2
    local PARAMETER_CURRENT_XP              = 6

    local PARAMETER_CURRENT_CAPACITY        = 2
    local PARAMETER_CURRENT_UPGRADE         = 4

    local MEDIUM_UPDATE_INTERVAL_SECONDS = 2
    local LONG_UPDATE_INTERVAL_SECONDS = 2.5
    local EXTRA_LONG_UPDATE_INTERVAL_SECONDS = 3.1

    CENTER_SCREEN_QUEUEABLE_EVENT_HANDLERS[EVENT_SKILL_XP_UPDATE] =
    {
        updateTimeDelaySeconds = LONG_UPDATE_INTERVAL_SECONDS,
        updateParameters = { PARAMETER_CURRENT_XP },
        conditionParameters = { PARAMETER_SKILL_TYPE, PARAMETER_SKILL_INDEX }
    }

    CENTER_SCREEN_QUEUEABLE_EVENT_HANDLERS[EVENT_RAID_REVIVE_COUNTER_UPDATE] =
    {
        updateTimeDelaySeconds = LONG_UPDATE_INTERVAL_SECONDS,
    }

    CENTER_SCREEN_QUEUEABLE_EVENT_HANDLERS[EVENT_INVENTORY_BAG_CAPACITY_CHANGED] =
    {
        updateTimeDelaySeconds = EXTRA_LONG_UPDATE_INTERVAL_SECONDS,
        updateParameters = { PARAMETER_CURRENT_CAPACITY, PARAMETER_CURRENT_UPGRADE }
    }

    CENTER_SCREEN_QUEUEABLE_EVENT_HANDLERS[EVENT_INVENTORY_BANK_CAPACITY_CHANGED] =
    {
        updateTimeDelaySeconds = EXTRA_LONG_UPDATE_INTERVAL_SECONDS,
        updateParameters = { PARAMETER_CURRENT_CAPACITY, PARAMETER_CURRENT_UPGRADE }
    }

    CENTER_SCREEN_QUEUEABLE_EVENT_HANDLERS[EVENT_RIDING_SKILL_IMPROVEMENT] =
    {
        updateTimeDelaySeconds = MEDIUM_UPDATE_INTERVAL_SECONDS,
        updateParameters = { PARAMETER_CURRENT_RIDING_SKILL },
        conditionParameters = { PARAMETER_RIDING_SKILL_TYPE, PARAMETER_RIDING_SKILL_SOURCE }
    }
end

function ZO_CenterScreenAnnounce_GetQueueableEventHandlers()
    return CENTER_SCREEN_QUEUEABLE_EVENT_HANDLERS
end

function ZO_CenterScreenAnnounce_GetQueueableHandler(eventId)
    return CENTER_SCREEN_QUEUEABLE_EVENT_HANDLERS[eventId]
end

-- Center Screen Callback Handlers
-- Usage: When we want to register with a callback object instead of an event

local COLLECTIBLE_EMERGENCY_BACKGROUND = "EsoUI/Art/Guild/guildRanks_iconFrame_selected.dds"
local MAX_INDIVIDUAL_CSAS = 4

local CENTER_SCREEN_CALLBACK_HANDLERS = 
{
    {
        callbackManager = ZO_COLLECTIBLE_DATA_MANAGER,
        callbackRegistration = "OnCollectionUpdated",
        callbackFunction = function(collectionUpdateType, collectiblesByUnlockState)
            if collectionUpdateType == ZO_COLLECTION_UPDATE_TYPE.UNLOCK_STATE_CHANGED then
                local nowOwnedCollectibles = collectiblesByUnlockState[COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED]
                if nowOwnedCollectibles then
                    if IsNewCharacterNotificationSuppressionActive() then
                        -- The player has just created a new character; suppress these updates.
                        return
                    end

                    if #nowOwnedCollectibles > MAX_INDIVIDUAL_COLLECTIBLE_UPDATES then
                        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
                        messageParams:SetText(GetString(SI_COLLECTIONS_UPDATED_ANNOUNCEMENT_TITLE), zo_strformat(SI_COLLECTIBLES_UPDATED_ANNOUNCEMENT_BODY, #nowOwnedCollectibles))
                        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
                        return messageParams
                    else
                        local messageParamsObjects = {}
                        for _, collectibleData in ipairs(nowOwnedCollectibles) do
                            local collectibleName = collectibleData:GetName()
                            local icon = collectibleData:GetIcon()
                            local categoryData = collectibleData:GetCategoryData()
                            local categoryName = categoryData:GetName()

                            local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
                            messageParams:SetText(GetString(SI_COLLECTIONS_UPDATED_ANNOUNCEMENT_TITLE), zo_strformat(SI_COLLECTIONS_UPDATED_ANNOUNCEMENT_BODY, collectibleName, categoryName))
                            messageParams:SetIconData(icon, COLLECTIBLE_EMERGENCY_BACKGROUND)
                            messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_SINGLE_COLLECTIBLE_UPDATED)
                            table.insert(messageParamsObjects, messageParams)
                        end
                        return unpack(messageParamsObjects)
                    end
                end
            end
        end,
    },

    {
        callbackManager = SKILLS_DATA_MANAGER,
        callbackRegistration = "SkillLineAdded",
        callbackFunction = function(skillLineData)
            if skillLineData:IsAvailable() then
                local skillTypeData = skillLineData:GetSkillTypeData()
                local announceIcon = zo_iconFormat(skillTypeData:GetAnnounceIcon(), 32, 32)
                local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SMALL_TEXT, SOUNDS.SKILL_LINE_ADDED)
                messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_SKILL_LINE_ADDED)
                messageParams:SetText(zo_strformat(SI_SKILL_LINE_ADDED, announceIcon, skillLineData:GetName()))
                return messageParams
            end
        end,
    },

    {
        callbackManager = COMPANION_SKILLS_DATA_MANAGER,
        callbackRegistration = "SkillLineAdded",
        callbackFunction = function(skillLineData)
            if skillLineData:IsAvailable() then
                local skillTypeData = skillLineData:GetSkillTypeData()
                local announceIcon = zo_iconFormat(skillTypeData:GetAnnounceIcon(), 32, 32)
                local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SMALL_TEXT, SOUNDS.SKILL_LINE_ADDED)
                messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COMPANION_SKILL_LINE_ADDED)
                messageParams:SetText(zo_strformat(SI_COMPANION_SKILL_LINE_ADDED, announceIcon, skillLineData:GetName()))
                return messageParams
            end
        end,
    },

    {
        callbackManager = COMPANION_SKILLS_DATA_MANAGER,
        callbackRegistration = "CompanionSkillUpdateStatusChanged",
        callbackFunction = function(companionSkillData)
            if companionSkillData:HasUpdatedStatus() and companionSkillData:IsPurchased() and companionSkillData:IsActive() then
                local progressionData = companionSkillData:GetPointAllocatorProgressionData()

                local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COMPANION_ACTIVE_SKILL_UNLOCKED)
                messageParams:SetText(GetString(SI_COMPANION_ACTIVE_SKILL_UNLOCKED_CSA), progressionData:GetFormattedName())
                messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COMPANION_ACTIVE_SKILL_UNLOCKED)
                messageParams:SetIconData(progressionData:GetIcon())
                return messageParams
            end
        end,
    },

    {
        callbackManager = ANTIQUITY_DATA_MANAGER,
        callbackRegistration = "SingleAntiquityDigSitesUpdated",
        callbackFunction = function(antiquityData)
            local lastNumGoalsAchieved = antiquityData:GetLastNumGoalsAchieved()
            local numGoalsAchieved = antiquityData:GetNumGoalsAchieved()
            -- Only trigger for forward progress
            if numGoalsAchieved > 0 and numGoalsAchieved > lastNumGoalsAchieved then
                local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SCRYING_PROGRESS_TEXT, SOUNDS.SCRYING_PROGRESS_ADDED)
                messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_ANTIQUITY_DIG_SITES_UPDATED)
                messageParams:SetText(GetString(SI_ANTIQUITIES_SCRYING_PROGRESS_UPDATED_HEADER), antiquityData:GetColorizedFormattedName())
                messageParams:SetScryingProgressData(lastNumGoalsAchieved, numGoalsAchieved, antiquityData:GetTotalNumGoals())
                return messageParams
            end
        end,
    },

    {
        callbackManager = ITEM_SET_COLLECTIONS_DATA_MANAGER,
        callbackRegistration = "SlotsJustUnlocked",
        callbackFunction = function(slotsJustUnlocked)
            if #slotsJustUnlocked > MAX_INDIVIDUAL_CSAS then
                local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
                messageParams:SetText(GetString(SI_ITEM_SET_COLLECTIONS_UPDATED_ANNOUNCEMENT_TITLE), zo_strformat(SI_ITEM_SET_COLLECTIONS_UPDATED_ANNOUNCEMENT_BODY, #slotsJustUnlocked))
                messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
                return messageParams
            else
                local messageParamsObjects = {}
                for _, slotJustUnlocked in ipairs(slotsJustUnlocked) do
                    local itemSetCollectionData = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetItemSetCollectionData(slotJustUnlocked.itemSetId)
                    local itemSetCollectionPieceData = itemSetCollectionData:GetPieceDataBySlot(slotJustUnlocked.slot)

                    local pieceName = itemSetCollectionPieceData:GetRawName()
                    local icon = itemSetCollectionPieceData:GetIcon()

                    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
                    messageParams:SetText(GetString(SI_ITEM_SET_COLLECTIONS_UPDATED_ANNOUNCEMENT_TITLE), zo_strformat(SI_ITEM_SET_COLLECTION_UPDATED_ANNOUNCEMENT_BODY, pieceName))
                    messageParams:SetIconData(icon, COLLECTIBLE_EMERGENCY_BACKGROUND)
                    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_SINGLE_COLLECTIBLE_UPDATED)
                    table.insert(messageParamsObjects, messageParams)
                end
                return unpack(messageParamsObjects)
            end
        end,
    },

    {
        callbackManager = TRIBUTE_DATA_MANAGER,
        callbackRegistration = "ProgressionUpgradeStatusChanged",
        callbackFunction = function(patronId, changedProgressions, refreshReason)
            if refreshReason == ZO_TRIBUTE_PATRON_PROGRESSION_REFRESH_REASON.DATA_CHANGED then
                local messageParamsObjects = {}
                for _, progressionData in ipairs(changedProgressions) do
                    if progressionData:HasUpgrade() then
                        local baseCardData = ZO_TributeCardData:New(patronId, progressionData:GetBaseCardId())
                        local upgradeCardData = ZO_TributeCardData:New(patronId, progressionData:GetUpgradeCardId())
                        local patronName = progressionData:GetPatronData():GetFormattedColorizedName()

                        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
                        messageParams:SetText(zo_strformat(GetString(SI_TRIBUTE_CARD_UPGRADED_ANNOUNCEMENT_TITLE), patronName), zo_strformat(SI_TRIBUTE_CARD_UPGRADED_ANNOUNCEMENT_BODY, baseCardData:GetColorizedName(), upgradeCardData:GetColorizedName()))
                        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_SINGLE_TRIBUTE_CARD_UPDATED)
                        table.insert(messageParamsObjects, messageParams)
                    end
                end
                if #messageParamsObjects > 0 then
                    TriggerTutorial(TUTORIAL_TRIGGER_TRIBUTE_CARD_UPGRADED)
                end
                return unpack(messageParamsObjects)
            end
        end,
    },

    {
        callbackManager = ENDLESS_DUNGEON_MANAGER,
        callbackRegistration = "AttemptsRemainingChanged",
        callbackFunction = function(attemptsRemaining, previousAttemptsRemaining)
            if attemptsRemaining <= 0 or previousAttemptsRemaining <= 0 or attemptsRemaining == previousAttemptsRemaining then
                -- Suppress the CSA when no attempts remain (as it is no longer relevant)
                -- or when there were no attempts remaining previously (initialization).
                return nil
            end
            local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
            local titleText
            if attemptsRemaining > previousAttemptsRemaining then
                titleText = GetString(SI_ENDLESS_DUNGEON_ATTEMPTS_REMAINING_INCREASED_ANNOUNCEMENT_TITLE)
            else
                titleText = GetString(SI_ENDLESS_DUNGEON_ATTEMPTS_REMAINING_DECREASED_ANNOUNCEMENT_TITLE)
                messageParams:SetSound(SOUNDS.ENDLESS_DUNGEON_ATTEMPTS_REMAINING_DECREMENT) -- Audio specifically for losing an attempt.
            end
            local subtitleText = zo_strformat(GetString(SI_ENDLESS_DUNGEON_ATTEMPTS_REMAINING_CHANGED_ANNOUNCEMENT_SUBTITLE), attemptsRemaining)

            messageParams:SetText(titleText, subtitleText)
            messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_ENDLESS_DUNGEON_ATTEMPTS_REMAINING_CHANGED)

            return messageParams
        end,
    },

    {
        callbackManager = ENDLESS_DUNGEON_MANAGER,
        callbackRegistration = "BuffStackCountChanged",
        callbackFunction = function(buffType, abilityId, stackCount, previousStackCount, suppressCSA)
            if suppressCSA or stackCount == 0 or previousStackCount > stackCount then
                -- Suppress the CSA when buff stacks drop off.
                return nil
            end

            local buffTypeString = GetString("SI_ENDLESSDUNGEONBUFFTYPE", buffType)
            local titleText = ZO_CachedStrFormat(SI_ENDLESS_DUNGEON_BUFF_ADDED_ANNOUNCEMENT_TITLE_FORMATTER, buffTypeString)
            local subtitleText = ZO_CachedStrFormat(SI_ABILITY_NAME, GetAbilityName(abilityId))
            local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_ANIMATED_CONTROL)
            messageParams:SetText(titleText, subtitleText)
            messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_ENDLESS_DUNGEON_BUFF_ADDED)
            messageParams:SetCustomAnimationTimeline(CENTER_SCREEN_ANNOUNCE:GetEndlessDungeonBuffAddedAnimationTimeline(), function(csaControl)
                local startBeneathControl = csaControl
                local endCenteredOnControl = not ZO_EndDunHUDTrackerContainerShowBuffTracker:IsHidden() and ZO_EndDunHUDTrackerContainerShowBuffTracker or nil
                ZO_CenterScreenEndlessDungeonBuffAdded_Setup(abilityId, startBeneathControl, endCenteredOnControl)

                -- Play the audio cue associated with this type of Endless Dungeon buff.
                local abilityBuffType, isAvatarVision = GetAbilityEndlessDungeonBuffType(abilityId)
                if abilityBuffType == ENDLESS_DUNGEON_BUFF_TYPE_VERSE then
                    PlaySound(SOUNDS.ENDLESS_DUNGEON_BUFF_ACQUIRE_VERSE)
                elseif abilityBuffType == ENDLESS_DUNGEON_BUFF_TYPE_VISION then
                    if isAvatarVision then
                        PlaySound(SOUNDS.ENDLESS_DUNGEON_BUFF_ACQUIRE_AVATAR_VISION)
                    else
                        PlaySound(SOUNDS.ENDLESS_DUNGEON_BUFF_ACQUIRE_VISION)
                    end
                end
            end)
            return messageParams
        end,
    },

    {
        callbackManager = SCRIBING_DATA_MANAGER,
        callbackRegistration = "CraftedAbilityLockStateChanged",
        callbackFunction = function(craftedAbilityData, isUnlocked, isFromInit)
            if isUnlocked and not isFromInit then
                local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.CRAFTED_ABILITY_UNLOCKED)
                -- Treat these the same way we treat collectibles
                messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_SINGLE_COLLECTIBLE_UPDATED)
                messageParams:SetText(GetString(SI_CRAFTED_ABILITY_UNLOCKED_ANNOUNCE_TITLE), craftedAbilityData:GetFormattedNameWithSkillLine())
                messageParams:SetIconData(craftedAbilityData:GetIcon())
                messageParams:MarkSuppressIconFrame()
                return messageParams
            end
        end,
    },

    {
        callbackManager = SCRIBING_DATA_MANAGER,
        callbackRegistration = "CraftedAbilityScriptLockStateChanged",
        callbackFunction = function(craftedAbilityScriptData, isUnlocked)
            if isUnlocked then
                local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.CRAFTED_ABILITY_SCRIPT_UNLOCKED)
                -- Treat these the same way we treat collectibles
                messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_SINGLE_COLLECTIBLE_UPDATED)
                messageParams:SetText(GetString(SI_CRAFTED_ABILITY_SCRIPT_UNLOCKED_ANNOUNCE_TITLE), craftedAbilityScriptData:GetFormattedNameWithSlot())
                messageParams:SetIconData(craftedAbilityScriptData:GetIcon())
                messageParams:MarkSuppressIconFrame()
                return messageParams
            end
        end,
    },

    {
        callbackManager = ZO_DYEING_MANAGER, 
        callbackRegistration = "UpdateDyeData", 
        callbackFunction = function(newUnlockedDyes)
             if #newUnlockedDyes > MAX_INDIVIDUAL_CSAS then
                --Handles mutiple unlocked dyes
                local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
                -- Treat these the same way we treat achievement
                messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_ACHIEVEMENT_AWARDED)
                messageParams:SetText(zo_strformat(SI_DYE_UNLOCKED_ANNOUNCE_TITLE, #newUnlockedDyes))
                return messageParams
            else
                local messageParamsObjects = {}
                for _, newUnlockedDye in ipairs(newUnlockedDyes) do
                    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
                    -- Treat these the same way we treat achievement
                    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_ACHIEVEMENT_AWARDED)
                    local NUM_UNLOCKED_DYES = 1
                    messageParams:SetText(zo_strformat(SI_DYE_UNLOCKED_ANNOUNCE_TITLE, NUM_UNLOCKED_DYES), newUnlockedDye.dyeName)
                    local iconColor = 
                    {
                        r = newUnlockedDye.r,
                        g = newUnlockedDye.g,
                        b = newUnlockedDye.b, 
                        a = 1,
                    }
                    local NO_ICON_BG = nil
                    messageParams:SetIconData("EsoUI/Art/Miscellaneous/centerscreen_floating_center.dds", NO_ICON_BG, iconColor)
                    table.insert(messageParamsObjects, messageParams)
                end
                return unpack(messageParamsObjects)  
            end
        end
    },

    {
        callbackManager = TITLE_MANAGER, 
        callbackRegistration = "UpdateTitlesData", 
        callbackFunction = function(newUnlockedTitles)
            if newUnlockedTitles then
                if #newUnlockedTitles > MAX_INDIVIDUAL_CSAS then
                    -- Handles mutiple unlocked titles
                    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
                    -- Treat these the same way we treat achievement
                    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_ACHIEVEMENT_AWARDED)
                    messageParams:SetText(zo_strformat(SI_TITLE_UNLOCKED_ANNOUNCE_TITLE, #newUnlockedTitles))
                    return messageParams
                else
                    local messageParamsObjects = {}
                    for _, newUnlockedTitle in ipairs(newUnlockedTitles) do
                        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
                        -- Treat these the same way we treat achievement
                        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_ACHIEVEMENT_AWARDED)
                        local NUM_UNLOCKED_TITLES = 1
                        messageParams:SetText(zo_strformat(SI_TITLE_UNLOCKED_ANNOUNCE_TITLE, NUM_UNLOCKED_TITLES), newUnlockedTitle.name)
                        table.insert(messageParamsObjects, messageParams)
                    end
                    return unpack(messageParamsObjects)  
                end
            end
        end
    },

    {
        callbackManager = PROMOTIONAL_EVENT_MANAGER, 
        callbackRegistration = "RewardsClaimed", 
        callbackFunction = function(campaignData, rewards)
            local campaignName = campaignData:GetDisplayName()
            if #rewards > MAX_INDIVIDUAL_CSAS then
                -- Handles mutiple claimed rewards
                local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
                messageParams:SetText(zo_strformat(SI_PROMOTIONAL_EVENT_REWARDS_CLAIMED_ANNOUNCEMENT, #rewards))
                messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_PROMOTIONAL_EVENT_REWARD_CLAIMED)
                return messageParams
            else
                local messageParamsObjects = {}
                for _, reward in ipairs(rewards) do
                    local claimedReward = reward.rewardableEventData:GetRewardData()
                    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
                    local secondaryText = claimedReward:GetQuantity() > 1 and claimedReward:GetFormattedNameWithStack() or claimedReward:GetFormattedName()
                    messageParams:SetText(GetString(SI_PROMOTIONAL_EVENT_REWARD_CLAIMED_ANNOUNCEMENT), secondaryText)
                    messageParams:SetIconData(claimedReward:GetPlatformLootIcon())
                    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_PROMOTIONAL_EVENT_REWARD_CLAIMED)
                    table.insert(messageParamsObjects, messageParams)
                end
                return unpack(messageParamsObjects) 
            end
        end
    },
}

function ZO_CenterScreenAnnounce_GetCallbackHandlers()
    return CENTER_SCREEN_CALLBACK_HANDLERS
end