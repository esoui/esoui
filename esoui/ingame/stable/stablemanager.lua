STABLE_TRAINING_TEXTURES =
{
    [RIDING_TRAIN_SPEED] = "EsoUI/Art/Mounts/ridingSkill_speed.dds",
    [RIDING_TRAIN_STAMINA] = "EsoUI/Art/Mounts/ridingSkill_stamina.dds",
    [RIDING_TRAIN_CARRYING_CAPACITY] = "EsoUI/Art/Mounts/ridingSkill_capacity.dds",
}

STABLE_TRAINING_TEXTURES_GAMEPAD =
{
    [RIDING_TRAIN_SPEED] = "EsoUI/Art/Mounts/Gamepad/gp_ridingSkill_speed.dds",
    [RIDING_TRAIN_STAMINA] = "EsoUI/Art/Mounts/Gamepad/gp_ridingSkill_stamina.dds",
    [RIDING_TRAIN_CARRYING_CAPACITY] = "EsoUI/Art/Mounts/Gamepad/gp_ridingSkill_capacity.dds",
}

STABLE_TRAINING_SOUNDS =
{
    [RIDING_TRAIN_SPEED] = SOUNDS.STABLE_FEED_SPEED,
    [RIDING_TRAIN_STAMINA] = SOUNDS.STABLE_FEED_STAMINA,
    [RIDING_TRAIN_CARRYING_CAPACITY] = SOUNDS.STABLE_FEED_CARRY,
}


----------------
--Initialization
----------------

ZO_Stable_Manager = ZO_CallbackObject:Subclass()

function ZO_Stable_Manager:New(...)
    local singleton = ZO_CallbackObject.New(self)
    singleton:Initialize(...)
    return singleton
end

function ZO_Stable_Manager:Initialize(control)
    self:RegisterForEvents()
    self.trainingCost = GetTrainingCost()
    self.currentMoney = GetCarriedCurrencyAmount(CURT_MONEY)
    self:UpdateStats()
    self.ridingSkillAnnoucementInfo = {}
end

function ZO_Stable_Manager:RegisterForEvents()
    local function InteractStart()
        self:UpdateStats()
        self:FireCallbacks("StableInteractStart")
    end

    local function ActiveMountChanged()
        if not IsInTutorialZone() then
            TriggerTutorial(TUTORIAL_TRIGGER_MOUNT_SET)
        end
        self:FireCallbacks("ActiveMountChanged")
    end

    EVENT_MANAGER:RegisterForEvent("ZO_Stable_Manager", EVENT_STABLE_INTERACT_START, InteractStart)
    EVENT_MANAGER:RegisterForEvent("ZO_Stable_Manager", EVENT_STABLE_INTERACT_END, function(eventCode) self:FireCallbacks("StableInteractEnd") end)
    EVENT_MANAGER:RegisterForEvent("ZO_Stable_Manager", EVENT_ACTIVE_MOUNT_CHANGED, ActiveMountChanged)

    local function UpdateStats()
        self:UpdateStats()
        self:FireCallbacks("StableMountInfoUpdated")
    end
    EVENT_MANAGER:RegisterForEvent("ZO_Stable_Manager", EVENT_MOUNT_INFO_UPDATED, UpdateStats)

    local function RidingSkillImprovement(_, ...)
        self:ProcessRidingSkillAnnouncement(...)
    end
    EVENT_MANAGER:RegisterForEvent("ZO_Stable_Manager", EVENT_RIDING_SKILL_IMPROVEMENT, RidingSkillImprovement)

    local function UpdateMoney()
        self.currentMoney = GetCarriedCurrencyAmount(CURT_MONEY)
        self:FireCallbacks("StableMoneyUpdate")
    end
    EVENT_MANAGER:RegisterForEvent("ZO_Stable_Manager", EVENT_MONEY_UPDATE, UpdateMoney)

    EVENT_MANAGER:RegisterForUpdate("ZO_Stable_Manager", 100, function(...) self:OnUpdate(...) end)
end

function ZO_Stable_Manager:UpdateStats()
    local inventoryBonus, maxInventoryBonus, staminaBonus, maxStaminaBonus, speedBonus, maxSpeedBonus = GetRidingStats()
    self.stats =
    {
        [RIDING_TRAIN_SPEED] = {speedBonus, maxSpeedBonus},
        [RIDING_TRAIN_STAMINA] = {staminaBonus, maxStaminaBonus},
        [RIDING_TRAIN_CARRYING_CAPACITY] = {inventoryBonus, maxInventoryBonus},
    }
    self.ridingSkillMaxedOut = (inventoryBonus == maxInventoryBonus) and (staminaBonus == maxStaminaBonus) and (speedBonus == maxSpeedBonus)
end

local TIMER_DURATION_MS = 2000
function ZO_Stable_Manager:ProcessRidingSkillAnnouncement(ridingSkill, previous, current, source)
    if source == RIDING_TRAIN_SOURCE_ITEM then
        local currentSkillInfo = self.ridingSkillAnnoucementInfo[ridingSkill]
        if currentSkillInfo == nil then
            currentSkillInfo = 
            {
                start = previous,
            }
            self.ridingSkillAnnoucementInfo[ridingSkill] = currentSkillInfo
        end
        currentSkillInfo.timerMS = GetGameTimeMilliseconds() + TIMER_DURATION_MS
        currentSkillInfo.stop = current
    end
end

function ZO_Stable_Manager:ShowRidingSkillAnnouncement(ridingSkill, start, stop)
    local skillImprovementText = zo_strformat(SI_RIDING_SKILL_ANNOUCEMENT_SKILL_INCREASE, GetString("SI_RIDINGTRAINTYPE", ridingSkill), start, stop)
    CENTER_SCREEN_ANNOUNCE:AddMessage(EVENT_RIDING_SKILL_IMPROVEMENT, CSA_EVENT_COMBINED_TEXT, STABLE_TRAINING_SOUNDS[ridingSkill], GetString(SI_RIDING_SKILL_ANNOUCEMENT_BANNER), skillImprovementText)
end

function ZO_Stable_Manager:OnUpdate(timeMS)
    for skillType, info in pairs(self.ridingSkillAnnoucementInfo) do
        if timeMS > info.timerMS then
            self.ridingSkillAnnoucementInfo[skillType] = nil
            self:ShowRidingSkillAnnouncement(skillType, info.start, info.stop)
        end
    end
end

function ZO_Stable_Manager:CanAffordTraining()
    return self.trainingCost > 0 and self.currentMoney >= self.trainingCost
end

local STAT_BONUS_INDEX = 1
local MAX_STAT_BONUS_INDEX = 2
function ZO_Stable_Manager:GetStats(trainingType)
    if trainingType then
        return self.stats[trainingType][STAT_BONUS_INDEX], self.stats[trainingType][MAX_STAT_BONUS_INDEX]
    else
        local speed, speedMax = self:GetStats(RIDING_TRAIN_SPEED)
        local stamina, staminaMax = self:GetStats(RIDING_TRAIN_STAMINA)
        local carry, carryMax = self:GetStats(RIDING_TRAIN_CARRYING_CAPACITY)
        return speed, speedMax, stamina, staminaMax, carry, carryMax
    end
end

function ZO_Stable_Manager:IsRidingSkillMaxedOut()
    return self.ridingSkillMaxedOut
end

STABLE_MANAGER = ZO_Stable_Manager:New()