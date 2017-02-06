---------------------------
-- Individual Log Record --
---------------------------

ZO_DPSLog = ZO_Object:Subclass()

function ZO_DPSLog:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_DPSLog:Initialize(unitId, unitName)
    self.unitId = unitId
    self.unitName = unitName
    self:Reset()
end

function ZO_DPSLog:HandleCombatEvent(hitValue)
    self.lastHitReceivedTimeS = GetFrameTimeSeconds()
    self.damageTaken = self.damageTaken + hitValue
end

function ZO_DPSLog:OutputResults()
    local timeSpentTakingDamage = self:GetTimeSpentTakingDamage()
    local dps = self:GetDPS()
    CHAT_SYSTEM:AddMessage(zo_strformat(SI_TARGET_DUMMY_DPS_RESULT_FORMAT, dps, ZO_FormatTimeAsDecimalWhenBelowThreshold(timeSpentTakingDamage), self.unitName))
end

function ZO_DPSLog:Reset()
    self.startTimeS = GetFrameTimeSeconds()
    self.lastHitReceivedTimeS = nil
    self.damageTaken = 0
end

function ZO_DPSLog:GetDamageTaken()
    return self.damageTaken
end

do
    local MIN_TIME_S = 1

    function ZO_DPSLog:GetTimeSpentTakingDamage()
        if self.startTimeS and self.lastHitReceivedTimeS then
            return zo_max(self.lastHitReceivedTimeS - self.startTimeS, MIN_TIME_S)
        end

        return 0
    end
end

function ZO_DPSLog:GetDPS()
    local timeSpentTakingDamage = self:GetTimeSpentTakingDamage()
    if timeSpentTakingDamage > 0 then
        return self.damageTaken / timeSpentTakingDamage
    end
    return 0
end

-------------------------------------
-- Target Dummy Log Manager Object --
-------------------------------------

ZO_TargetDummyLog_Manager = ZO_Object:Subclass()

function ZO_TargetDummyLog_Manager:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_TargetDummyLog_Manager:Initialize()
    self.logObjects = {}
    self:RegisterEvents()
end

function ZO_TargetDummyLog_Manager:RegisterEvents()
    local function OnCombatEvent(eventCode, ...)
        self:HandleCombatEvent(...)
    end

    local function OnCombatStateChange(eventCode, inCombat)
        self:OnCombatStateChange(inCombat)
    end

    local function OnPlayerActivated()
        local inCombat = IsUnitInCombat("player")
        self:OnCombatStateChange(inCombat)
    end
    EVENT_MANAGER:RegisterForEvent("TargetDummyLog", EVENT_COMBAT_EVENT, OnCombatEvent)
    EVENT_MANAGER:AddFilterForEvent("TargetDummyLog", EVENT_COMBAT_EVENT, REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_TARGET_DUMMY)
    EVENT_MANAGER:RegisterForEvent("TargetDummyLog", EVENT_PLAYER_COMBAT_STATE, OnCombatStateChange)
    EVENT_MANAGER:RegisterForEvent("TargetDummyLog", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
end

function ZO_TargetDummyLog_Manager:HandleCombatEvent(actionResult, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, shouldLog, sourceUnitId, targetUnitId, abilityId)
    local isFromMe = sourceType == COMBAT_UNIT_TYPE_PLAYER or sourceType == COMBAT_UNIT_TYPE_PLAYER_PET
    local isDPSEvent = hitValue > 0 and powerType > POWERTYPE_INVALID
    if isFromMe and isDPSEvent then
        local logObject = self.logObjects[targetUnitId]
        if not logObject then
            logObject = ZO_DPSLog:New(targetUnitId, targetName)
            self.logObjects[targetUnitId] = logObject
        end

        logObject:HandleCombatEvent(hitValue)
    end
end

function ZO_TargetDummyLog_Manager:OnCombatStateChange(inCombat)
    if self.inCombat ~= inCombat then
        self.inCombat = inCombat

        if not inCombat then
            ZO_ClearTableWithCallback(self.logObjects, ZO_DPSLog.OutputResults)
        end
    end
end

ZO_TARGET_DUMMY_LOGS = ZO_TargetDummyLog_Manager:New()