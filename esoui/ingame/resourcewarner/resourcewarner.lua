--Resource Warner
--------------------

local RESOURCE_WARNER_FLASH_TIME  = 300
local RESOURCE_WARNER_NUM_FLASHES = 3

ZO_ResourceWarner = ZO_Object:Subclass()

function ZO_ResourceWarner:New(...)
    local warner = ZO_Object.New(self)
    warner:Initialize(...)
    return warner
end

function ZO_ResourceWarner:Initialize(parent, powerType)
    self.warning = GetControl(parent, "Warner")

    self.warnAnimation = ZO_AlphaAnimation:New(self.warning)
    self.powerType = powerType
    self.statusBar = parent
    self.paused = false
    self.currentPower = 0

    self.warning:RegisterForEvent(EVENT_COMBAT_EVENT, function(eventCode, ...) self:OnCombatEvent(...) end)
    self.warning:AddFilterForEvent(EVENT_COMBAT_EVENT, REGISTER_FILTER_POWER_TYPE, powerType, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_INSUFFICIENT_RESOURCE)
    self.warning:RegisterForEvent(EVENT_POWER_UPDATE, function(_, unitTag, powerIndex, powerType, currentPower, maxPower) self:OnPowerUpdate(powerType, currentPower, maxPower) end)
    self.warning:AddFilterForEvent(EVENT_POWER_UPDATE, REGISTER_FILTER_POWER_TYPE, powerType, REGISTER_FILTER_UNIT_TAG, "player")
end

function ZO_ResourceWarner:SetPaused(paused)
    if self.paused ~= paused then
        self.paused = paused
        if paused and self.warnAnimation:IsPlaying() then
            self.warnAnimation:Stop()
        end
    end
end

function ZO_ResourceWarner:OnCombatEvent(result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log)
    if not self.paused then
        if not self.warnAnimation:IsPlaying() then
            self.warnAnimation:PingPong(0, 1, RESOURCE_WARNER_FLASH_TIME, RESOURCE_WARNER_NUM_FLASHES)
        else
            --Reset the animation by making it do RESOURCE_WARNER_NUM_FLASHES after this point
            local remainingLoops = self.warnAnimation:GetPlaybackLoopsRemaining()
            local newLoops = RESOURCE_WARNER_NUM_FLASHES
            --If we're on the backswing of the ping pong we need to do one addition loop to make sure it ends in the alpha down state, otherwise it stops at full alpha
            if remainingLoops % 2 == 0 then
                newLoops = newLoops + 1
            end
            self.warnAnimation:SetPlaybackLoopCount(newLoops)
        end
    end
end

function ZO_ResourceWarner:OnPowerUpdate(powerType, currentPower, maxPower)
    if not self.paused then
        if currentPower == 0 and self.currentPower > 0 and not self.warnAnimation:IsPlaying() then
            self.warnAnimation:PingPong(0, 1, RESOURCE_WARNER_FLASH_TIME, RESOURCE_WARNER_NUM_FLASHES)
        end
        self.currentPower = currentPower
    end
end

--Health Warner
---------------

local HEALTH_ALPHA_PULSE_THRESHOLD = 0.25

ZO_HealthWarner = ZO_Object:Subclass()

function ZO_HealthWarner:New(...)
    local warner = ZO_Object.New(self)
    warner:Initialize(...)
    return warner
end

function ZO_HealthWarner:Initialize(parent)
    local function OnPowerUpdate(_, unitTag, powerIndex, powerType, health, maxHealth)
        self:OnHealthUpdate(health, maxHealth)
    end
    local function OnPlayerActivated()
        local current, max = GetUnitPower("player", POWERTYPE_HEALTH)
        self:OnHealthUpdate(current, max)
    end

    self.warning = GetControl(parent, "Warner")

    self.warnAnimation = ZO_AlphaAnimation:New(self.warning)
    self.statusBar = parent
    self.paused = false

    self.warning:RegisterForEvent(EVENT_POWER_UPDATE, OnPowerUpdate)
    self.warning:AddFilterForEvent(EVENT_POWER_UPDATE, REGISTER_FILTER_POWER_TYPE, POWERTYPE_HEALTH, REGISTER_FILTER_UNIT_TAG, "player")
    self.warning:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
end

function ZO_HealthWarner:SetPaused(paused)
    if self.paused ~= paused then
        self.paused = paused
        if paused then
            if self.warnAnimation:IsPlaying() then
                self.warnAnimation:Stop()
            end
        else
            local current, max = GetUnitPower("player", POWERTYPE_HEALTH)
            self.warning:SetAlpha(0)
            self:UpdateAlphaPulse(current / max)
        end
    end
end

function ZO_HealthWarner:UpdateAlphaPulse(healthPerc)
    if healthPerc <= HEALTH_ALPHA_PULSE_THRESHOLD then
        if not self.warnAnimation:IsPlaying() then
            self.warnAnimation:PingPong(0, 1, RESOURCE_WARNER_FLASH_TIME)
        end
    else
        if self.warnAnimation:IsPlaying() then
            self.warnAnimation:Stop()
            self.warning:SetAlpha(0)
        end
    end
end

function ZO_HealthWarner:OnHealthUpdate(health, maxHealth)
    if not self.paused then
        local healthPerc = health / maxHealth
        self:UpdateAlphaPulse(healthPerc)
    end
end
