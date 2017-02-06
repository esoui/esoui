-- Miscellaneous data
local OBJECTIVE_STATE_ALLIANCE_TO_SOUND_ID =
{
    [OBJECTIVE_CONTROL_EVENT_UNDER_ATTACK] =
    {
        [ALLIANCE_ALDMERI_DOMINION] = SOUNDS.FLAG_ATTACKED_ALLIANCE1,
        [ALLIANCE_EBONHEART_PACT] = SOUNDS.FLAG_ATTACKED_ALLIANCE2,
        [ALLIANCE_DAGGERFALL_COVENANT] = SOUNDS.FLAG_ATTACKED_ALLIANCE3,
    },
    [OBJECTIVE_CONTROL_EVENT_LOST] =
    {
        [ALLIANCE_ALDMERI_DOMINION] = SOUNDS.FLAG_LOST_ALLIANCE1,
        [ALLIANCE_EBONHEART_PACT] = SOUNDS.FLAG_LOST_ALLIANCE2,
        [ALLIANCE_DAGGERFALL_COVENANT] = SOUNDS.FLAG_LOST_ALLIANCE3,
    },
    [OBJECTIVE_CONTROL_EVENT_CAPTURED] =
    {
        [ALLIANCE_ALDMERI_DOMINION] = SOUNDS.FLAG_CAPUTURED_ALLIANCE1,
        [ALLIANCE_EBONHEART_PACT] = SOUNDS.FLAG_CAPUTURED_ALLIANCE2,
        [ALLIANCE_DAGGERFALL_COVENANT] = SOUNDS.FLAG_CAPUTURED_ALLIANCE3,
    },
    [OBJECTIVE_CONTROL_EVENT_ASSAULTED] =
    {
        [ALLIANCE_ALDMERI_DOMINION] = SOUNDS.FLAG_ASSAULTED_ALLIANCE1,
        [ALLIANCE_EBONHEART_PACT] = SOUNDS.FLAG_ASSAULTED_ALLIANCE2,
        [ALLIANCE_DAGGERFALL_COVENANT] = SOUNDS.FLAG_ASSAULTED_ALLIANCE3,
    },
}

local OBJECTIVE_EVENT_DESCRIPTIONS =
{
    [OBJECTIVE_CONTROL_EVENT_UNDER_ATTACK] =            function(objectiveName, keepId, objectiveId, param1, param2)
                                                            local soundId = OBJECTIVE_STATE_ALLIANCE_TO_SOUND_ID[OBJECTIVE_CONTROL_EVENT_UNDER_ATTACK][param1]
                                                            return zo_strformat(GetString(SI_BG_OBJECTIVE_UNDER_ATTACK), objectiveName), soundId
                                                        end,
    [OBJECTIVE_CONTROL_EVENT_CAPTURED] =                function(objectiveName, keepId, objectiveId, param1, param2)
                                                            local capturingAlliance
                                                            local isInBattleground = IsAvAObjectiveInBattleground(keepId, objectiveId, BGQUERY_LOCAL)
                                                            local _, objType, _, _, _ = GetAvAObjectiveInfo(keepId, objectiveId, BGQUERY_LOCAL)
                                                            if(isInBattleground or objType == OBJECTIVE_CAPTURE_AREA) then
                                                                if(not isInBattleground or GetGameType() == GAME_CAPTURE_AREA) then
                                                                    capturingAlliance = param1
                                                                else
                                                                    capturingAlliance = param2
                                                                end
                                                                local soundId = OBJECTIVE_STATE_ALLIANCE_TO_SOUND_ID[OBJECTIVE_CONTROL_EVENT_CAPTURED][capturingAlliance]
                                                                return zo_strformat(GetString(SI_BG_OBJECTIVE_CAPTURED), objectiveName, GetColoredAllianceName(capturingAlliance)), soundId
                                                            end
                                                        end,
    [OBJECTIVE_CONTROL_EVENT_LOST] =                    function(objectiveName, keepId, objectiveId, param1, param2)
                                                            local allianceName = GetColoredAllianceName(param2)
                                                            local soundId = OBJECTIVE_STATE_ALLIANCE_TO_SOUND_ID[OBJECTIVE_CONTROL_EVENT_LOST][param2]
                                                            return zo_strformat(GetString(SI_BG_OBJECTIVE_GAINING_CONTROL), allianceName, objectiveName), soundId
                                                        end,
    [OBJECTIVE_CONTROL_EVENT_ASSAULTED] =               function(objectiveName, keepId, objectiveId, param1, param2)
                                                            local soundId = OBJECTIVE_STATE_ALLIANCE_TO_SOUND_ID[OBJECTIVE_CONTROL_EVENT_ASSAULTED][param2]
                                                            return zo_strformat(GetString(SI_BG_OBJECTIVE_ASSAULTED), objectiveName), soundId
                                                        end,

    -- OBJECTIVE_CONTROL_EVENT_FLAG_TAKEN, OBJECTIVE_CONTROL_EVENT_FLAG_DROPPED, OBJECTIVE_CONTROL_EVENT_FLAG_RETURNED, OBJECTIVE_CONTROL_EVENT_FLAG_RETURNED_BY_TIMER
    -- These messages are incorrectly built and made obsolete by the artifact control state event generated messages.  However, artifact change updates only
    -- come from a special message that may not be getting sent down in a battleground situation.  When battlegrounds are reenabled, we should send this message
    -- on flag events, rather than use what's here, because we don't have enough information to format the message correctly (no player name)
    -- using just the objective control state event
    -- For now, these events types are skipped when they come from AvA
    [OBJECTIVE_CONTROL_EVENT_FLAG_TAKEN] =              function(objectiveName, keepId, objectiveId, param1, param2)
                                                            if(IsAvAObjectiveInBattleground(keepId, objectiveId, BGQUERY_LOCAL)) then
                                                                local holdingAllianceName = GetColoredAllianceName(param2)
                                                                return zo_strformat(GetString(SI_BG_FLAG_TAKEN), holdingAllianceName, objectiveName)
                                                            end
                                                        end,
    [OBJECTIVE_CONTROL_EVENT_FLAG_DROPPED] =            function(objectiveName, keepId, objectiveId, param1, param2)
                                                            if(IsAvAObjectiveInBattleground(keepId, objectiveId, BGQUERY_LOCAL)) then
                                                                local droppingAllianceName = GetColoredAllianceName(param2)
                                                                return zo_strformat(GetString(SI_BG_FLAG_DROPPED), objectiveName, droppingAllianceName)
                                                            end
                                                        end,
    [OBJECTIVE_CONTROL_EVENT_FLAG_RETURNED] =           function(objectiveName, keepId, objectiveId, param1, param2)
                                                            if(IsAvAObjectiveInBattleground(keepId, objectiveId, BGQUERY_LOCAL)) then
                                                                return zo_strformat(GetString(SI_BG_FLAG_RETURNED), objectiveName)
                                                            end
                                                        end,
    [OBJECTIVE_CONTROL_EVENT_FLAG_RETURNED_BY_TIMER] =  function(objectiveName, keepId, objectiveId, param1, param2)
                                                            if(IsAvAObjectiveInBattleground(keepId, objectiveId, BGQUERY_LOCAL)) then
                                                                return zo_strformat(GetString(SI_BG_FLAG_RETURNED), objectiveName)
                                                            end
                                                        end,
}

function GetAvAObjectiveEventDescription(keepId, objectiveId, objectiveName, objectiveType, event, param1, param2)
    local f = OBJECTIVE_EVENT_DESCRIPTIONS[event]
    if(f) then
        return f(objectiveName, keepId, objectiveId, param1, param2)
    end
end

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
                                                            if(campaignId ~= 0) then
                                                                if(keepId ~= 0) then
                                                                    return zo_strformat(SI_CAMPAIGN_ARTIFACT_TAKEN, playerName, allianceName, artifactName, GetKeepName(keepId), GetCampaignName(campaignId))
                                                                else
                                                                    return zo_strformat(SI_CAMPAIGN_ARTIFACT_PICKED_UP, playerName, allianceName, artifactName, GetCampaignName(campaignId))
                                                                end
                                                            else
                                                                if(keepId ~= 0) then
                                                                    return zo_strformat(SI_ARTIFACT_TAKEN, playerName, allianceName, artifactName, GetKeepName(keepId))
                                                                else
                                                                    return zo_strformat(SI_ARTIFACT_PICKED_UP, playerName, allianceName, artifactName)
                                                                end
                                                            end
                                                        end,

    [OBJECTIVE_CONTROL_EVENT_CAPTURED] =                function(artifactName, keepId, playerName, alliance, allianceName, campaignId)
                                                            local soundId = ARTIFACT_STATE_ALLIANCE_TO_SOUND_ID[OBJECTIVE_CONTROL_EVENT_CAPTURED][alliance]

                                                            if(campaignId ~= 0) then
                                                                return zo_strformat(SI_CAMPAIGN_ARTIFACT_CAPTURED, playerName, allianceName, artifactName, GetKeepName(keepId), GetCampaignName(campaignId)), soundId
                                                            else
                                                                return zo_strformat(SI_ARTIFACT_CAPTURED, playerName, allianceName, artifactName, GetKeepName(keepId)), soundId
                                                            end
                                                        end,

    [OBJECTIVE_CONTROL_EVENT_FLAG_RETURNED] =           function(artifactName, keepId, playerName, alliance, allianceName, campaignId)
                                                            if(campaignId ~= 0) then
                                                                return zo_strformat(SI_CAMPAIGN_ARTIFACT_RETURNED, playerName, allianceName, artifactName, GetKeepName(keepId), GetCampaignName(campaignId))
                                                            else
                                                                return zo_strformat(SI_ARTIFACT_RETURNED, playerName, allianceName, artifactName, GetKeepName(keepId))
                                                            end
                                                        end,

    [OBJECTIVE_CONTROL_EVENT_FLAG_RETURNED_BY_TIMER] =  function(artifactName, keepId, playerName, alliance, allianceName, campaignId)
                                                            if(campaignId ~= 0) then
                                                                return zo_strformat(SI_CAMPAIGN_ARTIFACT_RETURNED_BY_TIMER, artifactName, GetKeepName(keepId), GetCampaignName(campaignId))
                                                            else
                                                                return zo_strformat(SI_ARTIFACT_RETURNED_BY_TIMER, artifactName, GetKeepName(keepId))
                                                            end
                                                        end,

    [OBJECTIVE_CONTROL_EVENT_FLAG_DROPPED] =            function(artifactName, keepId, playerName, alliance, allianceName, campaignId)
                                                            if(campaignId ~= 0) then
                                                                return zo_strformat(SI_CAMPAIGN_ARTIFACT_DROPPED, playerName, allianceName, artifactName, GetCampaignName(campaignId))
                                                            else
                                                                return zo_strformat(SI_ARTIFACT_DROPPED, playerName, allianceName, artifactName)
                                                            end
                                                        end,
}

function GetAvAArtifactEventDescription(artifactName, keepId, playerName, playerAlliance, event, campaignId)
    local f = ARTIFACT_EVENT_DESCRIPTIONS[event]
    if(f) then
        return f(artifactName, keepId, playerName, playerAlliance, GetColoredAllianceName(playerAlliance), campaignId)
    end
end

function GetKeepOwnershipChangedEventDescription(campaignId, keepId, oldOwner, newOwner)
    if(campaignId ~= 0) then
        return zo_strformat(SI_CAMPAIGN_KEEP_CAPTURED, GetColoredAllianceName(newOwner), GetKeepName(keepId), GetColoredAllianceName(oldOwner), GetCampaignName(campaignId))
    else
        return zo_strformat(SI_KEEP_CAPTURED, GetColoredAllianceName(newOwner), GetKeepName(keepId), GetColoredAllianceName(oldOwner))
    end
end

function GetGateStateChangedDescription(keepId, open)
    if(open) then
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
    if(abdication) then
        return zo_strformat(SI_CAMPAIGN_ABDICATE_EMPEROR, GetCampaignName(campaignId), userFacingName, GetColoredAllianceName(playerAlliance)), SOUNDS.EMPEROR_ABDICATED
    else
        return zo_strformat(SI_CAMPAIGN_DEPOSE_EMPEROR, GetCampaignName(campaignId), userFacingName, GetColoredAllianceName(playerAlliance)), DEPOSED_SOUND[playerAlliance]
    end
end

local IMPERIAL_CITY_GAINED_SOUND =
{
    [ALLIANCE_ALDMERI_DOMINION] = SOUNDS.IMPERIAL_CITY_ACCESS_GAINED_ALDMERI,
    [ALLIANCE_EBONHEART_PACT] = SOUNDS.IMPERIAL_CITY_ACCESS_GAINED_EBONHEART,
    [ALLIANCE_DAGGERFALL_COVENANT] = SOUNDS.IMPERIAL_CITY_ACCESS_GAINED_DAGGERFALL,
}

local IMPERIAL_CITY_LOST_SOUND =
{
    [ALLIANCE_ALDMERI_DOMINION] = SOUNDS.IMPERIAL_CITY_LOST_SOUND_ALDMERI,
    [ALLIANCE_EBONHEART_PACT] = SOUNDS.IMPERIAL_CITY_LOST_SOUND_EBONHEART,
    [ALLIANCE_DAGGERFALL_COVENANT] = SOUNDS.IMPERIAL_CITY_LOST_SOUND_DAGGERFALL,
}

function GetImperialCityAccessGainedEventDescription(campaignId, alliance)
        return zo_strformat(SI_IMPERIAL_CITY_ACCESS_GAINED, GetCampaignName(campaignId), GetColoredAllianceName(alliance)), IMPERIAL_CITY_GAINED_SOUND[alliance]
end

function GetImperialCityAccessLostEventDescription(campaignId, alliance)
        return zo_strformat(SI_IMPERIAL_CITY_ACCESS_LOST, GetCampaignName(campaignId), GetColoredAllianceName(alliance)), IMPERIAL_CITY_LOST_SOUND[alliance]
end

-- TODO: real sounds
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

local CSH = { }

local function GetRelevantBarParams(level, previousExperience, currentExperience, championPoints)
    local championXpToNextPoint
    if CanUnitGainChampionPoints("player") then
        championXpToNextPoint = GetNumChampionXPInChampionPoint(championPoints)
    end  
    if(championXpToNextPoint ~= nil and currentExperience > previousExperience) then
        return CENTER_SCREEN_ANNOUNCE:CreateBarParams(PPB_CP, championPoints, previousExperience, currentExperience)
    else
        local levelSize
        if(level) then
            levelSize = GetNumExperiencePointsInLevel(level)
        end
        if(levelSize ~= nil and currentExperience >  previousExperience) then
            return CENTER_SCREEN_ANNOUNCE:CreateBarParams(PPB_XP, level, previousExperience, currentExperience)
        end
    end
end

CSH[EVENT_QUEST_ADDED] = function(journalIndex, questName, objectiveName)
    local questType = GetJournalQuestType(journalIndex)
    local instanceDisplayType = GetJournalInstanceDisplayType(journalIndex)
    local questJournalObject = SYSTEMS:GetObject("questJournal")
    local iconTexture = questJournalObject:GetIconTexture(questType, instanceDisplayType)
    local formattedString
    if iconTexture then
        formattedString = zo_strformat(SI_NOTIFYTEXT_QUEST_ACCEPT_WITH_ICON, zo_iconFormat(iconTexture, "75%", "75%"), questName)
    else
        formattedString = zo_strformat(SI_NOTIFYTEXT_QUEST_ACCEPT, questName)
    end
    return CSA_EVENT_LARGE_TEXT, SOUNDS.QUEST_ACCEPTED, formattedString
end

CSH[EVENT_QUEST_COMPLETE] = function(questName, level, previousExperience, currentExperience, championPoints, questType, instanceDisplayType)
    local barParams = GetRelevantBarParams(level, previousExperience, currentExperience, championPoints)

    local questJournalObject = SYSTEMS:GetObject("questJournal")
    local iconTexture = questJournalObject:GetIconTexture(questType, instanceDisplayType)
    local formattedString
    if iconTexture then
        formattedString = zo_strformat(SI_NOTIFYTEXT_QUEST_COMPLETE_WITH_ICON, zo_iconFormat(iconTexture, "75%", "75%"), questName)
    else
        formattedString = zo_strformat(SI_NOTIFYTEXT_QUEST_COMPLETE, questName)
    end
    return CSA_EVENT_LARGE_TEXT, SOUNDS.QUEST_COMPLETED, formattedString, nil, nil, nil, nil, barParams
end

CSH[EVENT_OBJECTIVE_COMPLETED] = function(zoneIndex, poiIndex, level, previousExperience, currentExperience, championPoints) 
    local barParams = GetRelevantBarParams(level, previousExperience, currentExperience, championPoints)
    local name, _, _, finishedDescription = GetPOIInfo(zoneIndex, poiIndex)
    return CSA_EVENT_COMBINED_TEXT, SOUNDS.OBJECTIVE_COMPLETED, zo_strformat(SI_NOTIFYTEXT_OBJECTIVE_COMPLETE, name), finishedDescription, nil, nil, nil, barParams
end

CSH[EVENT_QUEST_CONDITION_COUNTER_CHANGED] = function(journalIndex, questName, conditionText, conditionType, currConditionVal, newConditionVal, conditionMax, isFailCondition, stepOverrideText, isPushed, isComplete, isConditionComplete, isStepHidden)
    if(isStepHidden or (isPushed and isComplete) or (currConditionVal >= newConditionVal)) then
        return
    end

    local sound
    if(newConditionVal ~= currConditionVal and not isFailCondition) then
        if(isConditionComplete) then
            sound = SOUNDS.QUEST_OBJECTIVE_COMPLETE
        else
            sound = SOUNDS.QUEST_OBJECTIVE_INCREMENT
        end
    end

    if isConditionComplete and conditionType == QUEST_CONDITION_TYPE_GIVE_ITEM then
        return CSA_EVENT_SMALL_TEXT, sound, zo_strformat(SI_TRACKED_QUEST_STEP_DONE, conditionText)
    end

    if stepOverrideText == "" then
        if isFailCondition then
            if conditionMax > 1 then
                return CSA_EVENT_SMALL_TEXT, sound, zo_strformat(SI_ALERTTEXT_QUEST_CONDITION_FAIL, conditionText, newConditionVal, conditionMax)
            else
                return CSA_EVENT_SMALL_TEXT, sound, zo_strformat(SI_ALERTTEXT_QUEST_CONDITION_FAIL_NO_COUNT, conditionText)
            end
        else
            if conditionMax > 1 and newConditionVal < conditionMax then
                return CSA_EVENT_SMALL_TEXT, sound, zo_strformat(SI_ALERTTEXT_QUEST_CONDITION_UPDATE, conditionText, newConditionVal, conditionMax)
            else
                return CSA_EVENT_SMALL_TEXT, sound, zo_strformat(SI_ALERTTEXT_QUEST_CONDITION_UPDATE_NO_COUNT, conditionText)
            end
        end
    else
        if isFailCondition then
            return CSA_EVENT_SMALL_TEXT, sound, zo_strformat(SI_ALERTTEXT_QUEST_CONDITION_FAIL_NO_COUNT, stepOverrideText)
        else
            return CSA_EVENT_SMALL_TEXT, sound, zo_strformat(SI_ALERTTEXT_QUEST_CONDITION_UPDATE_NO_COUNT, stepOverrideText)
        end
    end
end

CSH[EVENT_QUEST_OPTIONAL_STEP_ADVANCED] = function(text)
    if(text ~= "") then
        return CSA_EVENT_SMALL_TEXT, SOUNDS.QUEST_OBJECTIVE_COMPLETE, zo_strformat(SI_ALERTTEXT_QUEST_CONDITION_UPDATE_NO_COUNT, text)
    end
end

CSH[EVENT_ACHIEVEMENT_AWARDED] = function(name, points, id)
    local icon = select(4, GetAchievementInfo(id))
    return CSA_EVENT_COMBINED_TEXT, SOUNDS.ACHIEVEMENT_AWARDED, GetString(SI_ACHIEVEMENT_AWARDED_CENTER_SCREEN), zo_strformat(name), icon, "EsoUI/Art/Achievements/achievements_iconBG.dds"
end

CSH[EVENT_BROADCAST] = function(message)
    return CSA_EVENT_SMALL_TEXT, SOUNDS.MESSAGE_BROADCAST, string.format("|cffff00%s|r", message) -- TODO: Proper colorization
end

CSH[EVENT_DISCOVERY_EXPERIENCE] = function(subzoneName, level, previousExperience, currentExperience, championPoints)
    if(not INTERACT_WINDOW:IsShowingInteraction()) then
        local barParams
        if currentExperience > previousExperience then
            barParams = GetRelevantBarParams(level, previousExperience, currentExperience, championPoints)
        end
        return CSA_EVENT_LARGE_TEXT, SOUNDS.OBJECTIVE_DISCOVERED, zo_strformat(SI_SUBZONE_NOTIFICATION_DISCOVER, subzoneName), nil, nil, nil, nil, barParams
    end
end

CSH[EVENT_POI_DISCOVERED] = function(zoneIndex, poiIndex)
    local name, _, startDescription = GetPOIInfo(zoneIndex, poiIndex)
    return CSA_EVENT_COMBINED_TEXT, SOUNDS.OBJECTIVE_ACCEPTED, zo_strformat(SI_NOTIFYTEXT_OBJECTIVE_DISCOVERED, name), startDescription
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

CSH[EVENT_EXPERIENCE_GAIN] = function(reason, level, previousExperience, currentExperience, championPoints)
    if(XP_GAIN_SHOW_REASONS[reason]) then
        local barParams = GetRelevantBarParams(level, previousExperience, currentExperience, championPoints)
        if(barParams) then
            local sound = XP_GAIN_SHOW_SOUNDS[reason]
            barParams:SetSound(sound)
            CENTER_SCREEN_ANNOUNCE:AddMessage(EVENT_EXPERIENCE_GAIN, CSA_EVENT_NO_TEXT, nil, nil, nil, nil, nil, nil, barParams)
        end
    end

    local levelSize = GetNumExperiencePointsInLevel(level)
    if levelSize ~= nil and currentExperience >= levelSize then
        local barParams = CENTER_SCREEN_ANNOUNCE:CreateBarParams(PPB_XP, level + 1, currentExperience - levelSize, currentExperience - levelSize)
        barParams:SetShowNoGain(true)
        CENTER_SCREEN_ANNOUNCE:AddMessage(EVENT_EXPERIENCE_GAIN, CSA_EVENT_LARGE_TEXT, SOUNDS.LEVEL_UP, GetString(SI_LEVEL_UP_NOTIFICATION), nil, nil, nil, nil, barParams)
    end
end

local function GetCurrentChampionPointsBarParams()
    local championPoints = GetPlayerChampionPointsEarned()
    local currentChampionXP = GetPlayerChampionXP()
    local barParams = CENTER_SCREEN_ANNOUNCE:CreateBarParams(PPB_CP, championPoints, currentChampionXP, currentChampionXP)
    barParams:SetShowNoGain(true)
    return barParams
end

local function GetEnlightenedGainedAnnouncement()
    local barParams = GetCurrentChampionPointsBarParams()
    local headerText = zo_strformat(SI_ENLIGHTENED_STATE_GAINED_HEADER)
    return CSA_EVENT_COMBINED_TEXT, SOUNDS.ENLIGHTENED_STATE_GAINED, headerText, GetString(SI_ENLIGHTENED_STATE_GAINED_DESCRIPTION), nil, nil, nil, barParams
end

CSH[EVENT_ENLIGHTENED_STATE_GAINED] = function()
    if IsEnlightenedAvailableForCharacter() then
        return GetEnlightenedGainedAnnouncement()
    end
end

CSH[EVENT_ENLIGHTENED_STATE_LOST] = function()
    if IsEnlightenedAvailableForCharacter() then
        local barParams = GetCurrentChampionPointsBarParams()
        local headerText = zo_strformat(SI_ENLIGHTENED_STATE_LOST_HEADER)
        return CSA_EVENT_LARGE_TEXT, SOUNDS.ENLIGHTENED_STATE_LOST, headerText, nil, nil, nil, nil, barParams
    end
end

local firstActivation = true
CSH[EVENT_PLAYER_ACTIVATED] = function()
    if firstActivation then
        firstActivation = false

        if IsEnlightenedAvailableForCharacter() and GetEnlightenedPool() > 0 then
            return GetEnlightenedGainedAnnouncement()
        end
    end
end

CSH[EVENT_SKILL_RANK_UPDATE] = function(skillType, lineIndex, rank)
    -- crafting skill updates get deferred if they're increased while crafting animations are in progress
    -- ZO_Skills_TieSkillInfoHeaderToCraftingSkill handles triggering the deferred center screen announce in that case
    if skillType ~= SKILL_TYPE_RACIAL and (skillType ~= SKILL_TYPE_TRADESKILL or not ZO_CraftingUtils_IsPerformingCraftProcess()) then
        local lineName = GetSkillLineInfo(skillType, lineIndex)
        return CSA_EVENT_LARGE_TEXT, SOUNDS.SKILL_LINE_LEVELED_UP, zo_strformat(SI_SKILL_RANK_UP, lineName, rank)
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

CSH[EVENT_SKILL_XP_UPDATE] = function(skillType, skillIndex, reason, rank, previousXP, currentXP)
    if((skillType == SKILL_TYPE_GUILD and GUILD_SKILL_SHOW_REASONS[reason]) or reason == PROGRESS_REASON_JUSTICE_SKILL_EVENT) then
        local barType = PLAYER_PROGRESS_BAR:GetBarType(PPB_CLASS_SKILL, skillType, skillIndex)
        local rankStartXP, nextRankStartXP = GetSkillLineRankXPExtents(skillType, skillIndex, rank)
        local sound = GUILD_SKILL_SHOW_SOUNDS[reason]
        local barParams = CENTER_SCREEN_ANNOUNCE:CreateBarParams(barType, rank, previousXP - rankStartXP, currentXP - rankStartXP, sound)
        return CSA_EVENT_NO_TEXT, nil, nil, nil, nil, nil, nil, barParams
    end
end

CSH[EVENT_ABILITY_PROGRESSION_RANK_UPDATE] = function(progressionIndex, rank, maxRank, morph)
    local _, _, _, atMorph = GetAbilityProgressionXPInfo(progressionIndex)
    local name = GetAbilityProgressionAbilityInfo(progressionIndex, morph, rank)

    if(atMorph) then
        return CSA_EVENT_LARGE_TEXT, SOUNDS.ABILITY_MORPH_AVAILABLE, zo_strformat(SI_MORPH_AVAILABLE_ANNOUNCEMENT, name)
    else
        return CSA_EVENT_SMALL_TEXT, SOUNDS.ABILITY_RANK_UP, zo_strformat(SI_ABILITY_RANK_UP, name, rank)
    end
end

CSH[EVENT_SKILL_POINTS_CHANGED] = function(oldPoints, newPoints, oldPartialPoints, newPartialPoints)
    if oldPartialPoints ~= newPartialPoints then
        local smallString
        if newPartialPoints == 0 then
            if newPoints <= oldPoints then
                return
            end
            smallString = zo_strformat(SI_SKILL_POINT_GAINED, newPoints - oldPoints)
        else
            smallString = zo_strformat(SI_SKYSHARD_GAINED_POINTS, newPartialPoints, NUM_PARTIAL_SKILL_POINTS_FOR_FULL)
        end

        return CSA_EVENT_COMBINED_TEXT, SOUNDS.SKYSHARD_GAINED, GetString(SI_SKYSHARD_GAINED), smallString
    elseif newPoints > oldPoints then
        return CSA_EVENT_COMBINED_TEXT, SOUNDS.SKILL_GAINED, zo_strformat(SI_SKILL_POINT_GAINED, newPoints - oldPoints)
    end
end

CSH[EVENT_SKILL_LINE_ADDED] = function(skillType, lineIndex)
    local lineName = GetSkillLineInfo(skillType, lineIndex)
    return CSA_EVENT_SMALL_TEXT, SOUNDS.SKILL_LINE_ADDED, zo_strformat(SI_SKILL_LINE_ADDED, lineName)
end

CSH[EVENT_LORE_BOOK_LEARNED] = function(categoryIndex, collectionIndex, bookIndex, guildReputationIndex, isMaxRank)
    if(guildReputationIndex == 0 or isMaxRank) then
        -- We only want to fire this event if a player is not part of the guild or if they've reached max level in the guild.
        -- Otherwise, the _SKILL_EXPERIENCE version of this event will send a center screen message instead.
        local hidden = select(5, GetLoreCollectionInfo(categoryIndex, collectionIndex))
        if(not hidden) then
            return CSA_EVENT_LARGE_TEXT, SOUNDS.BOOK_ACQUIRED, GetString(SI_LORE_LIBRARY_ANNOUNCE_BOOK_LEARNED)
        end
    end
end

CSH[EVENT_LORE_BOOK_LEARNED_SKILL_EXPERIENCE] = function(categoryIndex, collectionIndex, bookIndex, guildReputationIndex, skillType, skillIndex, rank, previousXP, currentXP)
    if(guildReputationIndex > 0) then
        local barType = PLAYER_PROGRESS_BAR:GetBarType(PPB_CLASS_SKILL, skillType, skillIndex)
        local rankStartXP, nextRankStartXP = GetSkillLineRankXPExtents(skillType, skillIndex, rank)
        local barParams = CENTER_SCREEN_ANNOUNCE:CreateBarParams(barType, rank, previousXP - rankStartXP, currentXP - rankStartXP)
        return CSA_EVENT_LARGE_TEXT, SOUNDS.BOOK_ACQUIRED, GetString(SI_LORE_LIBRARY_ANNOUNCE_BOOK_LEARNED), nil, nil, nil, nil, barParams
    end
end

CSH[EVENT_LORE_COLLECTION_COMPLETED] = function(categoryIndex, collectionIndex, bookIndex, guildReputationIndex, isMaxRank)
    if(guildReputationIndex == 0 or isMaxRank) then
        -- Only fire this message if we're not part of the guild or at max level within the guild.
        local collectionName, description, numKnownBooks, totalBooks, hidden = GetLoreCollectionInfo(categoryIndex, collectionIndex)
        if(not hidden) then
            return CSA_EVENT_COMBINED_TEXT, SOUNDS.BOOK_COLLECTION_COMPLETED, GetString(SI_LORE_LIBRARY_COLLECTION_COMPLETED_LARGE), zo_strformat(SI_LORE_LIBRARY_COLLECTION_COMPLETED_SMALL, collectionName)
        end
    end
end

CSH[EVENT_LORE_COLLECTION_COMPLETED_SKILL_EXPERIENCE] = function(categoryIndex, collectionIndex, guildReputationIndex, skillType, skillIndex, rank, previousXP, currentXP)
    if(guildReputationIndex > 0) then
        local collectionName, description, numKnownBooks, totalBooks, hidden = GetLoreCollectionInfo(categoryIndex, collectionIndex)
        if(not hidden) then
            local barType = PLAYER_PROGRESS_BAR:GetBarType(PPB_CLASS_SKILL, skillType, skillIndex)
            local rankStartXP, nextRankStartXP = GetSkillLineRankXPExtents(skillType, skillIndex, rank)
            local barParams = CENTER_SCREEN_ANNOUNCE:CreateBarParams(barType, rank, previousXP - rankStartXP, currentXP - rankStartXP)
            return CSA_EVENT_COMBINED_TEXT, SOUNDS.BOOK_COLLECTION_COMPLETED, GetString(SI_LORE_LIBRARY_COLLECTION_COMPLETED_LARGE), zo_strformat(SI_LORE_LIBRARY_COLLECTION_COMPLETED_SMALL, collectionName), nil, nil, nil, barParams
        end
    end        
end

CSH[EVENT_PLEDGE_OF_MARA_RESULT] = function(result, characterName, displayName)
    if(result == PLEDGE_OF_MARA_RESULT_PLEDGED) then
        return CSA_EVENT_COMBINED_TEXT, nil, GetString(SI_RITUAL_OF_MARA_COMPLETION_ANNOUNCE_LARGE), zo_strformat(SI_RITUAL_OF_MARA_COMPLETION_ANNOUNCE_SMALL, ZO_FormatUserFacingDisplayName(displayName), characterName)
    end
end

CSH[EVENT_MEDAL_AWARDED] = function(name, icon, condition)
    return CSA_EVENT_COMBINED_TEXT, SOUNDS.MEDAL_AWARDED, zo_strformat(SI_MEDAL_NOTIFIER_MESSAGE, name), condition -- todo: icon?
end

CSH[EVENT_OBJECTIVE_CONTROL_STATE] = function(keepId, objectiveId, bgContext, objectiveName, objectiveType, event, state, param1, param2)
    --[[
    if(IsPlayerInAvAWorld()) then
        if objectiveType ~= OBJECTIVE_ARTIFACT_OFFENSIVE and objectiveType ~= OBJECTIVE_ARTIFACT_DEFENSIVE then
            local description, soundId = GetAvAObjectiveEventDescription(keepId, objectiveId, objectiveName, objectiveType, event, param1, param2)
            return CSA_EVENT_SMALL_TEXT, soundId, description
        end
    end
    --]]
end

CSH[EVENT_ARTIFACT_CONTROL_STATE] = function(artifactName, keepId, characterName, playerAlliance, controlEvent, controlState, campaignId, displayName)
    local nameToShow = IsInGamepadPreferredMode() and ZO_FormatUserFacingDisplayName(displayName) or characterName
    local description, soundId = GetAvAArtifactEventDescription(artifactName, keepId, nameToShow, playerAlliance, controlEvent, campaignId)
    return CSA_EVENT_SMALL_TEXT, soundId, description
end

CSH[EVENT_KEEP_GATE_STATE_CHANGED] = function(keepId, open)
    local description, soundId = GetGateStateChangedDescription(keepId, open)
    return CSA_EVENT_SMALL_TEXT, soundId, description
end

CSH[EVENT_KEEP_OWNERSHIP_CHANGED_NOTIFICATION] = function(campaignId, keepId, oldOwner, newOwner)
    --[[
    local description = GetKeepOwnershipChangedEventDescription(campaignId, keepId, oldOwner, newOwner)
    return CSA_EVENT_SMALL_TEXT, SOUNDS.AVA_KEEP_CAPTURED, description
    --]]
end

CSH[EVENT_CORONATE_EMPEROR_NOTIFICATION] = function(campaignId, playerCharacterName, playerAlliance, playerDisplayName)
    local description, soundId = GetCoronateEmperorEventDescription(campaignId, playerCharacterName, playerAlliance, playerDisplayName)
    return CSA_EVENT_SMALL_TEXT, soundId, description, nil, nil, nil, nil, nil, 5000
end

CSH[EVENT_DEPOSE_EMPEROR_NOTIFICATION] = function(campaignId, playerCharacterName, playerAlliance, abdication, playerDisplayName)
    local description, soundId = GetDeposeEmperorEventDescription(campaignId, playerCharacterName, playerAlliance, abdication, playerDisplayName)
    return CSA_EVENT_SMALL_TEXT, soundId, description, nil, nil, nil, nil, nil, 5000
end

CSH[EVENT_IMPERIAL_CITY_ACCESS_GAINED_NOTIFICATION] = function(campaignId, alliance)
    local description, soundId = GetImperialCityAccessGainedEventDescription(campaignId, alliance)
    return CSA_EVENT_SMALL_TEXT, soundId, description
end

CSH[EVENT_IMPERIAL_CITY_ACCESS_LOST_NOTIFICATION] = function(campaignId, alliance)
    local description, soundId = GetImperialCityAccessLostEventDescription(campaignId, alliance)
    return CSA_EVENT_SMALL_TEXT, soundId, description
end

CSH[EVENT_REVENGE_KILL] = function(killedCharacterName, killedDisplayName)
    if(IsPlayerInAvAWorld()) then
        local killedName = IsInGamepadPreferredMode() and ZO_FormatUserFacingDisplayName(killedDisplayName) or killedCharacterName
        local description = zo_strformat(SI_REVENGE_KILL, killedName)
        local soundId = nil -- needs sound?
        return CSA_EVENT_SMALL_TEXT, soundId, description
    end
end

CSH[EVENT_AVENGE_KILL] = function(avengedCharacterName, killedCharacterName, avengedDisplayName, killedDisplayName)
    if(IsPlayerInAvAWorld()) then
        local avengedName = avengedCharacterName
        local killedName = killedCharacterName
        if IsInGamepadPreferredMode() then
            avengedName = ZO_FormatUserFacingDisplayName(avengedDisplayName)
            killedName = ZO_FormatUserFacingDisplayName(killedDisplayName)
        end
        local description = zo_strformat(SI_AVENGE_KILL, avengedName, killedName)
        local soundId = nil -- needs sound?
        return CSA_EVENT_SMALL_TEXT, soundId, description
    end
end

--[[
CSH[EVENT_GUILD_CLAIM_KEEP_CAMPAIGN_NOTIFICATION] = function(campaignId, keepId, guildName, playerName)
    local description, soundId = GetClaimKeepCampaignEventDescription(campaignId, keepId, guildName, playerName)
    return CSA_EVENT_SMALL_TEXT, soundId, description
end

CSH[EVENT_GUILD_RELEASE_KEEP_CAMPAIGN_NOTIFICATION] = function(campaignId, keepId, guildName, playerName)
    local description, soundId = GetReleaseKeepCampaignEventDescription(campaignId, keepId, guildName, playerName)
    return CSA_EVENT_SMALL_TEXT, soundId, description
end

CSH[EVENT_GUILD_LOST_KEEP_CAMPAIGN_NOTIFICATION] = function(campaignId, keepId, guildName)
    local description, soundId = GetLostKeepCampaignEventDescription(campaignId, keepId, guildName)
    return CSA_EVENT_SMALL_TEXT, soundId, description
end]]--

CSH[EVENT_DISPLAY_ANNOUNCEMENT] = function(title, description)
    if(title ~= "" and description ~= "") then
        return CSA_EVENT_COMBINED_TEXT, SOUNDS.DISPLAY_ANNOUNCEMENT, title, description
    elseif(title ~= "") then
        return CSA_EVENT_LARGE_TEXT, SOUNDS.DISPLAY_ANNOUNCEMENT, title
    elseif(description ~= "") then
        return CSA_EVENT_SMALL_TEXT, SOUNDS.DISPLAY_ANNOUNCEMENT, description
    end
end

CSH[EVENT_RAID_TRIAL_STARTED] = function(raidName, isWeekly)
    return CSA_EVENT_COMBINED_TEXT, SOUNDS.RAID_TRIAL_STARTED, zo_strformat(SI_TRIAL_STARTED, raidName)
end

do
    local TRIAL_COMPLETE_LIFESPAN_MS = 10000
    CSH[EVENT_RAID_TRIAL_COMPLETE] = function(raidName, score, totalTime)
        local wasUnderTargetTime = GetRaidDuration() <= GetRaidTargetTime()
        local formattedTime = ZO_FormatTimeMilliseconds(totalTime, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_SECONDS)
        local vitalityBonus = GetCurrentRaidLifeScoreBonus()
        local currentCount = GetRaidReviveCountersRemaining()
        local maxCount = GetCurrentRaidStartingReviveCounters()
        return CSA_EVENT_RAID_COMPLETE_TEXT, SOUNDS.RAID_TRIAL_COMPLETED, zo_strformat(SI_TRIAL_COMPLETED_LARGE, raidName), { score, formattedTime, wasUnderTargetTime, vitalityBonus, zo_strformat(SI_REVIVE_COUNTER_REVIVES_USED, currentCount, maxCount) }, nil, nil, nil, nil, TRIAL_COMPLETE_LIFESPAN_MS
    end
end

CSH[EVENT_RAID_TRIAL_FAILED] = function(raidName, score)
    return CSA_EVENT_LARGE_TEXT, SOUNDS.RAID_TRIAL_FAILED, zo_strformat(SI_TRIAL_FAILED, raidName)
end

CSH[EVENT_RAID_TRIAL_NEW_BEST_SCORE] = function(raidName, score, isWeekly)
    return CSA_EVENT_SMALL_TEXT, SOUNDS.RAID_TRIAL_NEW_BEST, zo_strformat(isWeekly and SI_TRIAL_NEW_BEST_SCORE_WEEKLY or SI_TRIAL_NEW_BEST_SCORE_LIFETIME, raidName)
end

CSH[EVENT_RAID_REVIVE_COUNTER_UPDATE] = function(currentCount, countDelta)
-- TODO: revisit this once there is a way to properly handle this in client/server code
    if not IsRaidInProgress() then
        return
    end
    if countDelta < 0 then
        return CSA_EVENT_LARGE_TEXT, SOUNDS.RAID_TRIAL_COUNTER_UPDATE, zo_strformat(SI_REVIVE_COUNTER_UPDATED_LARGE, "EsoUI/Art/Trials/VitalityDepletion.dds")
    end
end

do
    local COLLECTIBLE_EMERGENCY_BACKGROUND = "EsoUI/Art/Guild/guildRanks_iconFrame_selected.dds"


    local function AddCollectibleMessage(collectibleName, iconFile, categoryName, subcategoryName)
        local titleText = GetString(SI_COLLECTIONS_UPDATED_ANNOUNCEMENT_TITLE)

        local displayedCategory = subcategoryName and subcategoryName or categoryName

        local bodyText = zo_strformat(SI_COLLECTIONS_UPDATED_ANNOUNCEMENT_BODY, collectibleName, displayedCategory)
        CENTER_SCREEN_ANNOUNCE:AddMessage(EVENT_COLLECTIBLE_UPDATED, CSA_EVENT_COMBINED_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED, titleText, bodyText, iconFile, COLLECTIBLE_EMERGENCY_BACKGROUND)
    end

    CSH[EVENT_COLLECTIBLE_UPDATED] = function(collectibleId, justUnlocked)
        if not justUnlocked then
            return
        end
        local collectibleName, _, iconFile = GetCollectibleInfo(collectibleId)
        local isPlaceholder = IsCollectiblePlaceholder(collectibleId)
        if not isPlaceholder then
            local categoryIndex, subcategoryIndex = GetCategoryInfoFromCollectibleId(collectibleId)

            local categoryName = GetCollectibleCategoryInfo(categoryIndex)
            local subcategoryName = subcategoryIndex and GetCollectibleSubCategoryInfo(categoryIndex, subcategoryIndex) or nil

            AddCollectibleMessage(collectibleName, iconFile, categoryName, subcategoryName)
        end
    end
end

CSH[EVENT_COLLECTIBLES_UPDATED] = function(numJustUnlocked)
    if numJustUnlocked > 0 then
        return CSA_EVENT_COMBINED_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED, GetString(SI_COLLECTIONS_UPDATED_ANNOUNCEMENT_TITLE), zo_strformat(SI_COLLECTIBLES_UPDATED_ANNOUNCEMENT_BODY, numJustUnlocked)
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

    CSH[EVENT_RAID_TRIAL_SCORE_UPDATE] = function(scoreType, scoreAmount, totalScore)
        local reasonAssets = TRIAL_SCORE_REASON_TO_ASSETS[scoreType]
        if reasonAssets then
            return CSA_EVENT_LARGE_TEXT,
                reasonAssets.soundId,
                zo_strformat(SI_TRIAL_SCORE_UPDATED_LARGE, reasonAssets.icon, scoreAmount)
        end
    end
end

do
    local CHAMPION_UNLOCKED_LIFESPAN_MS = 12000
    CSH[EVENT_CHAMPION_LEVEL_ACHIEVED] = function(wasChampionSystemUnlocked)
        local barParams
        local formattedIcon = zo_iconFormat(GetChampionPointsIcon(), "100%", "100%")
        if wasChampionSystemUnlocked then
            local championPoints = GetPlayerChampionPointsEarned()
            local currentChampionXP = GetPlayerChampionXP()
            barParams = CENTER_SCREEN_ANNOUNCE:CreateBarParams(PPB_CP, championPoints, currentChampionXP, currentChampionXP)
            barParams:SetShowNoGain(true)
            return  CSA_EVENT_LARGE_TEXT, SOUNDS.CHAMPION_POINT_GAINED, zo_strformat(SI_CHAMPION_ANNOUNCEMENT_UNLOCKED, formattedIcon), nil, nil, nil, nil, barParams
        else
            local totalChampionPoints = GetPlayerChampionPointsEarned()
            local championXPGained = 0;
            for i = 0, (totalChampionPoints - 1) do
                championXPGained = championXPGained + GetNumChampionXPInChampionPoint(i)
            end
            barParams =  CENTER_SCREEN_ANNOUNCE:CreateBarParams(PPB_CP, 0, 0, championXPGained)
            return  CSA_EVENT_LARGE_TEXT, SOUNDS.CHAMPION_POINT_GAINED, zo_strformat(SI_CHAMPION_ANNOUNCEMENT_UNLOCKED, formattedIcon), nil, nil, nil, nil, barParams, CHAMPION_UNLOCKED_LIFESPAN_MS
        end
    end
end

CSH[EVENT_CHAMPION_POINT_GAINED] = function(pointDelta)
    -- adding one so that we are starting from the first gained point instead of the starting champion points
    local endingPoints = GetPlayerChampionPointsEarned()
    local startingPoints = endingPoints - pointDelta + 1
    local championPointsByType = { 0, 0, 0 }

    while startingPoints <= endingPoints do
        local pointType = GetChampionPointAttributeForRank(startingPoints)
        championPointsByType[pointType] = championPointsByType[pointType] + 1
        startingPoints = startingPoints + 1
    end

    local secondLine = ""
    for pointType,amount in pairs(championPointsByType) do
        if amount > 0 then
            local icon = GetChampionPointAttributeHUDIcon(pointType)
            local constellationGroupName = ZO_Champion_GetUnformattedConstellationGroupNameFromAttribute(pointType)
            secondLine = secondLine .. zo_strformat(SI_CHAMPION_POINT_TYPE, amount, icon, constellationGroupName) .. "\n"
        end
    end

    return CSA_EVENT_COMBINED_TEXT, SOUNDS.CHAMPION_POINT_GAINED, zo_strformat(SI_CHAMPION_POINT_EARNED, pointDelta), secondLine, nil, nil, nil, nil, nil, CSA_OPTION_SUPPRESS_ICON_FRAME
end

CSH[EVENT_INVENTORY_BAG_CAPACITY_CHANGED] = function(previousCapacity, currentCapacity, previousUpgrade, currentUpgrade)
    if previousCapacity > 0 and previousCapacity ~= currentCapacity and previousUpgrade ~= currentUpgrade then
        return CSA_EVENT_COMBINED_TEXT, nil, GetString(SI_INVENTORY_BAG_UPGRADE_ANOUNCEMENT_TITLE), zo_strformat(SI_INVENTORY_BAG_UPGRADE_ANOUNCEMENT_DESCRIPTION, previousCapacity, currentCapacity)
    end
end

CSH[EVENT_INVENTORY_BANK_CAPACITY_CHANGED] = function(previousCapacity, currentCapacity, previousUpgrade, currentUpgrade)
    if previousCapacity > 0 and previousCapacity ~= currentCapacity and previousUpgrade ~= currentUpgrade then
        return CSA_EVENT_COMBINED_TEXT, nil, GetString(SI_INVENTORY_BANK_UPGRADE_ANOUNCEMENT_TITLE), zo_strformat(SI_INVENTORY_BANK_UPGRADE_ANOUNCEMENT_DESCRIPTION, previousCapacity, currentCapacity)
    end
end

CSH[EVENT_ATTRIBUTE_FORCE_RESPEC] = function(note)
    return CSA_EVENT_COMBINED_TEXT, nil, GetString(SI_ATTRIBUTE_FORCE_RESPEC_TITLE), zo_strformat(SI_ATTRIBUTE_FORCE_RESPEC_PROMPT, note)
end

CSH[EVENT_SKILL_FORCE_RESPEC] = function(note)
    return CSA_EVENT_COMBINED_TEXT, nil, GetString(SI_SKILLS_FORCE_RESPEC_TITLE), zo_strformat(SI_SKILLS_FORCE_RESPEC_PROMPT, note)
end

CSH[EVENT_ACTIVITY_FINDER_ACTIVITY_COMPLETE] = function()
    return CSA_EVENT_LARGE_TEXT, SOUNDS.LFG_COMPLETE_ANNOUNCEMENT, GetString(SI_ACTIVITY_FINDER_ACTIVITY_COMPLETE_ANNOUNCEMENT_TEXT)
end

do
    local QUEUE_IMMEDIATELY = true
    local SHOW_IMMEDIATELY = true
    CSH[EVENT_DUEL_COUNTDOWN] = function(startTimeMS)
        local startSoundPlayed = false
        local function CountdownTextFunction()
            local timeLeftMS = startTimeMS - GetFrameTimeMilliseconds()
            local secondsRemaining = math.ceil(timeLeftMS / 1000)
            -- make sure we never show the number 0 or less
            if secondsRemaining <= 0 then 
                secondsRemaining = 1 
            end
            if timeLeftMS <= 500 then
                -- play the duel start sound near the actual start of the duel
                if not startSoundPlayed then
                    PlaySound(SOUNDS.DUEL_START)
                    startSoundPlayed = true
                end
            end
            return zo_strformat(SI_DUELING_COUNTDOWN_CSA, secondsRemaining)
        end
        local displayTime = startTimeMS - GetFrameTimeMilliseconds()
        return CSA_EVENT_LARGE_TEXT, nil, CountdownTextFunction, nil, nil, nil, nil, nil, displayTime, nil, QUEUE_IMMEDIATELY, SHOW_IMMEDIATELY
    end
end

do
    local DUEL_BOUNDARY_WARNING_LIFESPAN_MS = 2000
    local DUEL_BOUNDARY_WARNING_UPDATE_TIME_MS = 2100
    local lastEventTime = 0
    local function CheckBoundary()
        if IsNearDuelBoundary() then
			CENTER_SCREEN_ANNOUNCE:AddMessage(EVENT_DUEL_NEAR_BOUNDARY, CSA_EVENT_SMALL_TEXT, SOUNDS.DUEL_BOUNDARY_WARNING, GetString(SI_DUELING_NEAR_BOUNDARY_CSA), nil, nil, nil, nil, nil, DUEL_BOUNDARY_WARNING_LIFESPAN_MS)
		end
    end

    CSH[EVENT_DUEL_NEAR_BOUNDARY] = function(isInWarningArea)
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

CSH[EVENT_DUEL_FINISHED] = function(result, wasLocalPlayersResult, opponentCharacterName, opponentDisplayName)
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

    local SHOW_IMMEDIATELY = true
    local QUEUE_IMMEDIATELY = true
    local REINSERT_STOMPED_MESSAGE = false
    return CSA_EVENT_LARGE_TEXT, resultSound, resultString, nil, nil, nil, nil, nil, nil, nil, QUEUE_IMMEDIATELY, SHOW_IMMEDIATELY, REINSERT_STOMPED_MESSAGE
end

function ZO_CenterScreenAnnounce_GetHandlers()
    return CSH
end

function ZO_CenterScreenAnnounce_GetHandler(eventId)
    return CSH[eventId]
end

function ZO_CenterScreenAnnounce_InitializePriorities()
    -- Lower-priority events
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_MEDAL_AWARDED)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_PLEDGE_OF_MARA_RESULT)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_ACHIEVEMENT_AWARDED)
    --ZO_CenterScreenAnnounce_SetEventPriority(EVENT_OBJECTIVE_CONTROL_STATE)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_ARTIFACT_CONTROL_STATE)
    --ZO_CenterScreenAnnounce_SetEventPriority(EVENT_KEEP_GATE_STATE_CHANGED)
    --ZO_CenterScreenAnnounce_SetEventPriority(EVENT_KEEP_OWNERSHIP_CHANGED_NOTIFICATION)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_CORONATE_EMPEROR_NOTIFICATION)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_DEPOSE_EMPEROR_NOTIFICATION)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_IMPERIAL_CITY_ACCESS_GAINED_NOTIFICATION)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_IMPERIAL_CITY_ACCESS_LOST_NOTIFICATION)
    --ZO_CenterScreenAnnounce_SetEventPriority(EVENT_GUILD_LOST_KEEP_CAMPAIGN_NOTIFICATION)
    --ZO_CenterScreenAnnounce_SetEventPriority(EVENT_GUILD_RELEASE_KEEP_CAMPAIGN_NOTIFICATION)
    --ZO_CenterScreenAnnounce_SetEventPriority(EVENT_GUILD_CLAIM_KEEP_CAMPAIGN_NOTIFICATION)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_REVENGE_KILL)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_AVENGE_KILL)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_ABILITY_PROGRESSION_RANK_UPDATE)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_SKILL_LINE_ADDED)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_SKILL_RANK_UPDATE)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_SKILL_XP_UPDATE)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_LORE_COLLECTION_COMPLETED)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_LORE_COLLECTION_COMPLETED_SKILL_EXPERIENCE)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_LORE_BOOK_LEARNED)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_LORE_BOOK_LEARNED_SKILL_EXPERIENCE)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_SKILL_POINTS_CHANGED)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_RAID_TRIAL_NEW_BEST_SCORE)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_RAID_TRIAL_COMPLETE)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_RAID_TRIAL_FAILED)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_RAID_TRIAL_SCORE_UPDATE)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_RAID_TRIAL_STARTED)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_DISCOVERY_EXPERIENCE)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_CHAMPION_POINT_GAINED)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_LEVEL_UPDATE)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_CHAMPION_LEVEL_ACHIEVED)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_EXPERIENCE_GAIN)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_OBJECTIVE_COMPLETED)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_DISPLAY_ANNOUNCEMENT)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_QUEST_COMPLETE)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_QUEST_OPTIONAL_STEP_ADVANCED)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_QUEST_CONDITION_COUNTER_CHANGED)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_QUEST_ADDED)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_POI_DISCOVERED)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_JUSTICE_NOW_KOS)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_JUSTICE_NO_LONGER_KOS)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_BROADCAST)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_COLLECTIBLE_UPDATED)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_COLLECTIBLES_UPDATED)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_RIDING_SKILL_IMPROVEMENT)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_DUEL_FINISHED)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_DUEL_NEAR_BOUNDARY)
    ZO_CenterScreenAnnounce_SetEventPriority(EVENT_DUEL_COUNTDOWN)

    -- Higher-priority events

    -- Miscellaneous event handlers
    local function OnQuestRemoved(eventId, isCompleted, journalIndex, questName, zoneIndex, poiIndex)
        if not isCompleted then
            PlaySound(SOUNDS.QUEST_ABANDONED)
        end
    end

    -- Quest Advancement displays all the "appropriate" conditions that the player needs to do to advance the current step
    local function OnQuestAdvanced(eventId, questIndex, questName, isPushed, isComplete, mainStepChanged)
        if(not mainStepChanged) then return end

        local announceObject = CENTER_SCREEN_ANNOUNCE
        local sound = SOUNDS.QUEST_OBJECTIVE_STARTED

        for stepIndex = QUEST_MAIN_STEP_INDEX, GetJournalQuestNumSteps(questIndex) do
            local _, visibility, stepType, stepOverrideText, conditionCount = GetJournalQuestStepInfo(questIndex, stepIndex)

            if((visibility == nil) or (visibility == QUEST_STEP_VISIBILITY_OPTIONAL)) then
                if(stepOverrideText ~= "") then
                    announceObject:AddMessage(eventId, CSA_EVENT_SMALL_TEXT, sound, stepOverrideText)
                    sound = nil -- no longer needed, we played it once
                else
                    for conditionIndex = 1, conditionCount do
                        local conditionText, curCount, maxCount, isFailCondition, isConditionComplete, _, isVisible  = GetJournalQuestConditionInfo(questIndex, stepIndex, conditionIndex)

                        if(not (isFailCondition or isConditionComplete) and isVisible) then
                            announceObject:AddMessage(eventId, CSA_EVENT_SMALL_TEXT, sound, conditionText)
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
--      updateTimeDelaySeconds: The time delay from when an event that is marked as queueable is recieved to when the event enters into the regular event queue.
--                              The system will restart the time after each new event is recieved
--      updateParameters:       A table of parameter positions that should be overwritten with the latest data from the newest event recieved.
--                              The position is derived from the parameters in the event callback function defined in the CSH table for the same event. 
--      conditionParameters:    A table of parameter positions that should be unique amoung any given number of eventIds. For example, if you kill a monster that gives
--                              exp and guild rep, they will both come down as skill xp update events, but their skilltype and skillindex values are different, so they should be added the to system independently
--                              and not added together for updating

local CSQH = {}

do
    local PARAMETER_SKILL_TYPE          = 1
    local PARAMETER_SKILL_INDEX         = 2
    local PARAMETER_CURRENT_CAPACITY    = 2
    local PARAMETER_CURRENT_UPGRADE     = 4
    local PARAMETER_CURRENT_XP          = 6

    local LONG_UPDATE_INTERVAL_SECONDS = 2.5
    local EXTRA_LONG_UPDATE_INTERVAL_SECONDS = 3.1

    CSQH[EVENT_SKILL_XP_UPDATE] =
    {
        updateTimeDelaySeconds = LONG_UPDATE_INTERVAL_SECONDS,
        updateParameters = {PARAMETER_CURRENT_XP},
        conditionParameters = {PARAMETER_SKILL_TYPE, PARAMETER_SKILL_INDEX}
    }

    CSQH[EVENT_RAID_REVIVE_COUNTER_UPDATE] =
    {
        updateTimeDelaySeconds = LONG_UPDATE_INTERVAL_SECONDS,
    }

    CSQH[EVENT_INVENTORY_BAG_CAPACITY_CHANGED] =
    {
        updateTimeDelaySeconds = EXTRA_LONG_UPDATE_INTERVAL_SECONDS,
        updateParameters = {PARAMETER_CURRENT_CAPACITY, PARAMETER_CURRENT_UPGRADE}
    }

    CSQH[EVENT_INVENTORY_BANK_CAPACITY_CHANGED] =
    {
        updateTimeDelaySeconds = EXTRA_LONG_UPDATE_INTERVAL_SECONDS,
        updateParameters = {PARAMETER_CURRENT_CAPACITY, PARAMETER_CURRENT_UPGRADE}
    }
end

function ZO_CenterScreenAnnounce_GetQueueableHandlers()
    return CSQH
end

function ZO_CenterScreenAnnounce_GetQueueableHandler(eventId)
    return CSQH[eventId]
end