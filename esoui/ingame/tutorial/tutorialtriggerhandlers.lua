--TUTORIAL_TRIGGER

local TutorialTriggerHandlers = {
    [EVENT_FAST_TRAVEL_NETWORK_UPDATED] = function()
        if GetNumFastTravelNodes() == 2 then
            return TUTORIAL_TRIGGER_TWO_FAST_TRAVEL_NODES
        end
    end,

    [EVENT_ALLIANCE_POINT_UPDATE] = function(alliancePoints, _, difference)
        if alliancePoints > 0 and difference > 0 then
            return TUTORIAL_TRIGGER_EARNED_ALLIANCE_POINTS
        end
    end,    
    
    [EVENT_MISSING_LURE] = function()
        return TUTORIAL_TRIGGER_ATTEMPTED_TO_FISH_WITHOUT_BAIT
    end,

    [EVENT_LEVEL_UPDATE] = function(unit, level)
        if unit == "player" then 
            if level >= GetWeaponSwapUnlockedLevel() then
                return TUTORIAL_TRIGGER_WEAPON_SWAPPING_UNLOCKED
            end
        end
    end,

    [EVENT_SKILL_POINTS_CHANGED] = function(oldPoints, newPoints, oldPartialPoints, newPartialPoints)
        if oldPartialPoints ~= newPartialPoints then
            return TUTORIAL_TRIGGER_SKYSHARDS_DISCOVERED
        end
    end,

    [EVENT_POI_DISCOVERED] = function(zoneIndex, poiIndex)
        local poiType = GetPOIType(zoneIndex, poiIndex)
        if poiType == POI_TYPE_GROUP_DUNGEON or poiType == POI_TYPE_PUBLIC_DUNGEON then
            return TUTORIAL_TRIGGER_DISCOVERED_GROUP_DUNGEON
        end
    end,

    [EVENT_CAPTURE_AREA_STATUS] = function()
        return TUTORIAL_TRIGGER_ENTERED_OBJECTIVE_CAPTURE_AREA
    end,

    [EVENT_QUEST_ADDED] = function(questIndex)
        if GetJournalQuestRepeatType(questIndex) == QUEST_REPEAT_DAILY then
            return TUTORIAL_TRIGGER_DAILY_QUEST_ADDED
        end
    end,

    [EVENT_RAID_TRIAL_STARTED] = function()
        return TUTORIAL_TRIGGER_RAID_TRIAL_STARTED
    end,

    [EVENT_RAID_TRIAL_COMPLETE] = function()
        return TUTORIAL_TRIGGER_RAID_TRIAL_COMPLETED
    end,

    [EVENT_RAID_TRIAL_FAILED] = function()
        return TUTORIAL_TRIGGER_RAID_TRIAL_FAILED
    end,

    [EVENT_ENLIGHTENED_STATE_GAINED] = function()
        if IsEnlightenedAvailableForCharacter() then
            return TUTORIAL_TRIGGER_ENLIGHTENED_STATE_GAINED
        end
    end,

    [EVENT_ENLIGHTENED_STATE_LOST] = function()
        if IsEnlightenedAvailableForCharacter() then
            return TUTORIAL_TRIGGER_ENLIGHTENED_STATE_LOST
        end
    end,

    [EVENT_PLAYER_ACTIVATED] = function()
        if IsEnlightenedAvailableForCharacter() and GetEnlightenedPool() > 0 then
            TriggerTutorial(TUTORIAL_TRIGGER_ENLIGHTENED_STATE_GAINED)
        end

        if DoesCurrentZoneAllowScalingByLevel() then
           TriggerTutorial(TUTORIAL_TRIGGER_SCALEABLE_REGION_ENTERED)
        end

        if DoesCurrentZoneAllowBattleLevelScaling() then
            if IsUnitChampionBattleLeveled("player") then
                TriggerTutorial(TUTORIAL_TRIGGER_BATTLE_LEVEL_ZONE_ENTERED_VETERAN)
            elseif IsUnitBattleLeveled("player") then
                TriggerTutorial(TUTORIAL_TRIGGER_BATTLE_LEVEL_ZONE_ENTERED)
            end
        end

        if IsInOutlawZone() then
            TriggerTutorial(TUTORIAL_TRIGGER_REFUGE_ENTERED)
        end
    end,

    [EVENT_JUSTICE_LIVESTOCK_SLAIN] = function()
        return TUTORIAL_TRIGGER_LIVESTOCK_SLAIN
    end,

    [EVENT_MOUNTED_STATE_CHANGED] = function(isMounted)
        if isMounted then
            return TUTORIAL_TRIGGER_MOUNTED
        end
    end,
}

function ZO_Tutorial_GetTriggerHandlers()
    return TutorialTriggerHandlers
end