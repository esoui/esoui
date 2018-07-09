
local function Vibrate(duration, coarseMotor, fineMotor, leftTriggerMotor, rightTriggerMotor, foundInfo, debugSourceInfo)
    if IsInGamepadPreferredMode() and foundInfo then
        SetGamepadVibration(duration, coarseMotor, fineMotor, leftTriggerMotor, rightTriggerMotor, debugSourceInfo)
    end
end

local function GetVibrationFromEventInfo(actionResult, sourceType, targetType)
    -- WARNING! If you change this function, please update the event filter in c++ also, or remove
    --          the filter (REGISTER_FILTER_VIBRATION_FILTER) below.
    local actionType = nil
    --player doing stuff to people
    if sourceType == COMBAT_UNIT_TYPE_PLAYER then    
        if actionResult == ACTION_RESULT_DIED or         --player killed someone (self included ie falling damage)
         actionResult == ACTION_RESULT_DIED_XP or 
         actionResult == ACTION_RESULT_KILLING_BLOW then        
            actionType = GAMEPAD_VIBRATION_TRIGGER_KILLED
        end
    end

    --people doing stuff to player
    if targetType == COMBAT_UNIT_TYPE_PLAYER and sourceType ~= COMBAT_UNIT_TYPE_PLAYER then 
        if actionResult == ACTION_RESULT_DIED or                --player died
         actionResult == ACTION_RESULT_DIED_XP or 
         actionResult == ACTION_RESULT_KILLING_BLOW then
            actionType = GAMEPAD_VIBRATION_TRIGGER_DIED
        elseif actionResult == ACTION_RESULT_STUNNED then       --player got stunned
            actionType = GAMEPAD_VIBRATION_TRIGGER_STUNNED
        elseif actionResult == ACTION_RESULT_KNOCKBACK then     --player got knockedback
            actionType = GAMEPAD_VIBRATION_TRIGGER_KNOCKED_BACK
        elseif actionResult == ACTION_RESULT_STAGGERED then     --player got staggered
            actionType = GAMEPAD_VIBRATION_TRIGGER_STAGGERED
        end
    end

    return actionType;
end

local function OnCombatEvent(event, 
                        actionResult, 
                        isError, 
                        abilityName, 
                        abilityGraphic, 
                        abilityActionSlotType, 
                        sourceName, 
                        sourceType, 
                        targetName, 
                        targetType, 
                        hitValue, 
                        powerType, 
                        damageType, 
                        shouldLog)
                        
    local actionType = GetVibrationFromEventInfo(actionResult, sourceType, targetType)

    if actionType ~= nil then
        Vibrate(GetVibrationInfoFromTrigger(actionType))
    end
end

local function OnHighFallEvent()
    Vibrate(GetVibrationInfoFromTrigger(GAMEPAD_VIBRATION_TRIGGER_FALL_DAMAGE_HIGH))
end

local function OnLowFallEvent()
    Vibrate(GetVibrationInfoFromTrigger(GAMEPAD_VIBRATION_TRIGGER_FALL_DAMAGE_LOW))
end

local FOUND_INFO = true
local function OnVibrationEvent(eventId, duration, coarseMotor, fineMotor, leftTriggerMotor, rightTriggerMotor, debugSourceInfo)
    Vibrate(duration, coarseMotor, fineMotor, leftTriggerMotor, rightTriggerMotor, FOUND_INFO, debugSourceInfo)
end

EVENT_MANAGER:RegisterForEvent("Vibration", EVENT_VIBRATION, OnVibrationEvent)
EVENT_MANAGER:RegisterForEvent("Vibration", EVENT_COMBAT_EVENT, OnCombatEvent)
EVENT_MANAGER:AddFilterForEvent("Vibration", EVENT_COMBAT_EVENT, REGISTER_FILTER_VIBRATION_FILTER, 0)
EVENT_MANAGER:RegisterForEvent("Vibration", EVENT_HIGH_FALL_DAMAGE, OnHighFallEvent)
EVENT_MANAGER:RegisterForEvent("Vibration", EVENT_LOW_FALL_DAMAGE, OnLowFallEvent)
