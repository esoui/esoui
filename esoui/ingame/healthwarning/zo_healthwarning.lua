local HEALTH_WARNING_PERCENTAGES =
{
    [HEALTH_WARNING_STAGE_1] = 0,
    [HEALTH_WARNING_STAGE_2] = 0.3,
    [HEALTH_WARNING_STAGE_3] = 0.15,
    [HEALTH_WARNING_FLASH_1] = 0.5,
    [HEALTH_WARNING_FLASH_2] = 0.4,
}

local FLASH_TIME_OUT_SECONDS =
{
    [HEALTH_WARNING_FLASH_1] = 0.3,
    [HEALTH_WARNING_FLASH_2] = 0.3,
}

local IS_HEALTH_FLASH =
{
    [HEALTH_WARNING_FLASH_1] = true,
    [HEALTH_WARNING_FLASH_2] = true,
}

local currentHealthPercent = 0

local function ShouldFlash(healthPercent, flashPercent)
    local healthWasAboveFlash = currentHealthPercent > flashPercent
    local healthIsNowBelowFlash = healthPercent <= flashPercent
    return healthWasAboveFlash and healthIsNowBelowFlash
end

local function GetWarningStage(healthPercent)
    if(healthPercent <= HEALTH_WARNING_PERCENTAGES[HEALTH_WARNING_STAGE_3])
    then
        return HEALTH_WARNING_STAGE_3
    elseif(healthPercent <= HEALTH_WARNING_PERCENTAGES[HEALTH_WARNING_STAGE_2])
    then
        return HEALTH_WARNING_STAGE_2
    elseif(healthPercent <= HEALTH_WARNING_PERCENTAGES[HEALTH_WARNING_STAGE_1])
    then
        return HEALTH_WARNING_STAGE_1
    elseif(ShouldFlash(healthPercent, HEALTH_WARNING_PERCENTAGES[HEALTH_WARNING_FLASH_2]))
    then
        return HEALTH_WARNING_FLASH_2
    elseif(ShouldFlash(healthPercent, HEALTH_WARNING_PERCENTAGES[HEALTH_WARNING_FLASH_1]))
    then
        return HEALTH_WARNING_FLASH_1
    else
        return HEALTH_WARNING_NONE
    end
end

local function ShowWarningForHealthPercent(healthPercent)
    local warningStage = GetWarningStage(healthPercent)

    if(IS_HEALTH_FLASH[warningStage])
    then
        FlashHealthWarningStage(warningStage, FLASH_TIME_OUT_SECONDS[warningStage] * 1000)
    else
        SetHealthWarningStage(warningStage)
    end
end

local function PlayerDead()
    ClearHealthWarnings()
end

local function OnPowerUpdate(evt, tag, powerIndex, powerType, health, maxHealth)
    if IsUnitDead("player") then
        PlayerDead()
        return
    end

    local healthPercent = 0
    if(maxHealth and maxHealth > 0)
    then
        healthPercent = health / maxHealth
    end

    ShowWarningForHealthPercent(healthPercent)
    currentHealthPercent = healthPercent
end

local function UpdateHealthWarning()
    local health, maxHealth = GetUnitPower("player", POWERTYPE_HEALTH)

    if(maxHealth and maxHealth > 0)
    then
        currentHealthPercent = health / maxHealth
    else
        currentHealthPercent = 0
    end

    ShowWarningForHealthPercent(currentHealthPercent)
end


EVENT_MANAGER:RegisterForEvent("ZO_HealthWarning", EVENT_PLAYER_DEAD, PlayerDead)
EVENT_MANAGER:RegisterForEvent("ZO_HealthWarning", EVENT_PLAYER_ALIVE, UpdateHealthWarning)
EVENT_MANAGER:RegisterForEvent("ZO_HealthWarning", EVENT_POWER_UPDATE, OnPowerUpdate)
EVENT_MANAGER:AddFilterForEvent("ZO_HealthWarning", EVENT_POWER_UPDATE, REGISTER_FILTER_POWER_TYPE, POWERTYPE_HEALTH)
EVENT_MANAGER:AddFilterForEvent("ZO_HealthWarning", EVENT_POWER_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")

UpdateHealthWarning()

