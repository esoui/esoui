local ARROW_REGENERATION_TEMPLATE = "ZO_ArrowRegeneration"

ZO_UnitVisualizer_ArrowRegenerationModule = ZO_UnitAttributeVisualizerModuleBase:Subclass()

function ZO_UnitVisualizer_ArrowRegenerationModule:New(...)
    return ZO_UnitAttributeVisualizerModuleBase.New(self, ...)
end

local g_numModulesCreated = 0
local g_numArrowsCreated = 0
function ZO_UnitVisualizer_ArrowRegenerationModule:Initialize()
    local function OnArrowAnimationStopped(timeline)
        if timeline.hasControlOfBar then
            self:GetOwner():NotifyEndingControlOf(timeline.bar)
            timeline.hasControlOfBar = false
        end
        self.arrowPool:ReleaseObject(timeline.key)
    end

    local function CreateArrow()
        g_numArrowsCreated = g_numArrowsCreated + 1
        local arrow = CreateControlFromVirtual(ARROW_REGENERATION_TEMPLATE, GuiRoot, ARROW_REGENERATION_TEMPLATE, g_numArrowsCreated)
        arrow.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ArrowRegenerationAnimation", arrow)
        arrow.animation:SetHandler("OnStop", OnArrowAnimationStopped)
        return arrow
    end

    local function ResetArrow(arrow)
        arrow:SetHidden(true)
        arrow:SetParent(nil)
        arrow:ClearAnchors()
    end

    self.arrowPool = ZO_ObjectPool:New(CreateArrow, ResetArrow)
end

function ZO_UnitVisualizer_ArrowRegenerationModule:GetInitialStatValue(stat, attribute, powerType)
    return self:GetInitialValueAndMarkMostRecent(ATTRIBUTE_VISUAL_INCREASED_REGEN_POWER, stat, attribute, powerType)
         + self:GetInitialValueAndMarkMostRecent(ATTRIBUTE_VISUAL_DECREASED_REGEN_POWER, stat, attribute, powerType)
end

function ZO_UnitVisualizer_ArrowRegenerationModule:OnAdded(healthBarControl, magickaBarControl, staminaBarControl)
    self.barControls =
    {
        [STAT_HEALTH_REGEN_COMBAT] = healthBarControl,
        [STAT_MAGICKA_REGEN_COMBAT] = magickaBarControl,
        [STAT_STAMINA_REGEN_COMBAT] = staminaBarControl,
    }

    if IsPlayerActivated() then
        self:InitializeBarValues()
    end

    EVENT_MANAGER:RegisterForEvent("ZO_UnitVisualizer_ArrowRegenerationModule" .. self:GetModuleId(), EVENT_PLAYER_ACTIVATED, function() self:InitializeBarValues() end)
end

function ZO_UnitVisualizer_ArrowRegenerationModule:InitializeBarValues()
    if not self.barInfo then
        EVENT_MANAGER:RegisterForUpdate("ZO_UnitVisualizer_ArrowRegenerationModule" .. self:GetModuleId(), 85, function() self:Pulse() end)
    end

    local healthBarControl = self.barControls[STAT_HEALTH_REGEN_COMBAT]
    local magickaBarControl = self.barControls[STAT_MAGICKA_REGEN_COMBAT]
    local staminaBarControl = self.barControls[STAT_STAMINA_REGEN_COMBAT]

    self.barInfo =
    {
        [STAT_HEALTH_REGEN_COMBAT] = healthBarControl and { value = self:GetInitialStatValue(STAT_HEALTH_REGEN_COMBAT, ATTRIBUTE_HEALTH, POWERTYPE_HEALTH), arrowsRemaining = 0, tickDelay = 1 } or nil,
        [STAT_MAGICKA_REGEN_COMBAT] = magickaBarControl and { value = self:GetInitialStatValue(STAT_MAGICKA_REGEN_COMBAT, ATTRIBUTE_MAGICKA, POWERTYPE_MAGICKA), arrowsRemaining = 0, tickDelay = 0 } or nil,
        [STAT_STAMINA_REGEN_COMBAT] = staminaBarControl and { value = self:GetInitialStatValue(STAT_STAMINA_REGEN_COMBAT, ATTRIBUTE_STAMINA, POWERTYPE_STAMINA), arrowsRemaining = 0, tickDelay = 0 } or nil,
    }
end

function ZO_UnitVisualizer_ArrowRegenerationModule:OnUnitChanged()
    self:InitializeBarValues()
end

function ZO_UnitVisualizer_ArrowRegenerationModule:IsUnitVisualRelevant(visualType, stat, attribute, powerType)
    if visualType == ATTRIBUTE_VISUAL_INCREASED_REGEN_POWER or visualType == ATTRIBUTE_VISUAL_DECREASED_REGEN_POWER then
        return self.barInfo 
           and self.barInfo[stat] ~= nil
    end
    return false
end

function ZO_UnitVisualizer_ArrowRegenerationModule:OnUnitAttributeVisualAdded(visualType, stat, attribute, powerType, value)
    local lastValue = self.barInfo[stat].value
    self.barInfo[stat].value = lastValue + value
    self:OnValueChanged(self.barInfo[stat], self.barControls[stat], lastValue, stat)
end

function ZO_UnitVisualizer_ArrowRegenerationModule:OnUnitAttributeVisualUpdated(visualType, stat, attribute, powerType, oldValue, newValue)
    local lastValue = self.barInfo[stat].value
    self.barInfo[stat].value = lastValue + (newValue - oldValue)
    self:OnValueChanged(self.barInfo[stat], self.barControls[stat], lastValue, stat)
end

function ZO_UnitVisualizer_ArrowRegenerationModule:OnUnitAttributeVisualRemoved(visualType, stat, attribute, powerType, value)
    local lastValue = self.barInfo[stat].value
    self.barInfo[stat].value = lastValue - value
    self:OnValueChanged(self.barInfo[stat], self.barControls[stat], lastValue, stat)
end

function ZO_UnitVisualizer_ArrowRegenerationModule:PlaySound(stat, increasing, hadOppositeEffect, noEffects)
    if hadOppositeEffect then
        if increasing then
            self.owner:PlaySoundFromStat(stat, STAT_STATE_DECREASE_LOST)
        else
            self.owner:PlaySoundFromStat(stat, STAT_STATE_INCREASE_LOST)
        end
    end

    if not noEffects then
        if increasing then
            self.owner:PlaySoundFromStat(stat, STAT_STATE_INCREASE_GAINED)
            TriggerTutorial(TUTORIAL_TRIGGER_COMBAT_STATUS_EFFECT)
        else
            self.owner:PlaySoundFromStat(stat, STAT_STATE_DECREASE_GAINED)
            TriggerTutorial(TUTORIAL_TRIGGER_COMBAT_STATUS_EFFECT)
        end
    end
end

function ZO_UnitVisualizer_ArrowRegenerationModule:OnValueChanged(info, bar, oldValue, stat)
    if info.value < 0 and oldValue >= 0 then
        info.takeControl = true
        local DECREASING = false
        self:PlaySound(stat, DECREASING, oldValue ~= 0)
    elseif info.value > 0 and oldValue <= 0 then
        info.takeControl = true
        local INCREASING = true
        self:PlaySound(stat, INCREASING, oldValue ~= 0)
    elseif info.value == 0 and oldValue ~= 0 then
        local HAD_OPPOSITE_EFFECT = true
        local NO_EFFECTS = true
        self:PlaySound(stat, oldValue < 0, HAD_OPPOSITE_EFFECT, NO_EFFECTS)
    end
end

local MAX_ARROWS = 3
local NUM_TICKS_PER_MAJOR = MAX_ARROWS * 4

function ZO_UnitVisualizer_ArrowRegenerationModule:Pulse()
    self.ticks = (self.ticks or 0) + 1
    local isMajorTick = self.ticks % NUM_TICKS_PER_MAJOR == 0

    for stat, bar in pairs(self.barControls) do
        local info = self.barInfo[stat]
        if isMajorTick then
            if info.value ~= 0 and info.arrowsRemaining == 0 then
                self:PlayArrow(bar, stat, info.value, info.takeControl)
                info.takeControl = false
                info.currentTickDelay = info.tickDelay

                info.arrowsRemaining = self:GetNumArrowsByStat(stat, info.value) - 1
                if info.arrowsRemaining > 0 then
                    info.lastValue = info.value
                end
            end
        elseif info.arrowsRemaining > 0 then
            if info.currentTickDelay == 0 then
                self:PlayArrow(bar, stat, info.lastValue)
                info.arrowsRemaining = info.arrowsRemaining - 1
                info.currentTickDelay = info.tickDelay
            else
                info.currentTickDelay = info.currentTickDelay - 1
            end
        end
    end
end

local STAT_TO_COMBAT_MECHANIC = {
    [STAT_HEALTH_REGEN_COMBAT] = POWERTYPE_HEALTH,
    [STAT_MAGICKA_REGEN_COMBAT] = POWERTYPE_MAGICKA,
    [STAT_STAMINA_REGEN_COMBAT] = POWERTYPE_STAMINA,
}

function ZO_UnitVisualizer_ArrowRegenerationModule:GetNumArrowsByStat(stat, value)
    local _, maxPower = GetUnitPower("player", STAT_TO_COMBAT_MECHANIC[stat])
    local percentRegen = zo_abs(value) / maxPower
    return zo_clamp(zo_round(percentRegen * 20), 1, MAX_ARROWS)
end

function ZO_UnitVisualizer_ArrowRegenerationModule:AcquireArrow(bar)
    local arrow, key = self.arrowPool:AcquireObject()
    ApplyTemplateToControl(arrow, ZO_GetPlatformTemplate(ARROW_REGENERATION_TEMPLATE))
    arrow.animation.key = key
    arrow.animation.bar = bar
    arrow:SetHidden(false)
    arrow:SetParent(bar)

    return arrow
end

local OFFSET_Y = 1
local END_X_PADDING = 3
local ARROW_TEXTURE_WIDTH = 16

function ZO_UnitVisualizer_ArrowRegenerationModule:PlayLeftArrow(bar, forward, widthModifier, takeControl)
    local width = bar:GetWidth() * widthModifier
    local offsetX = width - ARROW_TEXTURE_WIDTH

    local arrow = self:AcquireArrow(bar)
    arrow:SetAnchor(LEFT, bar, LEFT, offsetX, OFFSET_Y)
    arrow.animation:GetFirstAnimation():SetTranslateDeltas(-offsetX - END_X_PADDING, 0)

    if forward then
        arrow:SetTextureCoords(0, 1, 0, 1)
        arrow.animation:PlayFromStart()
    else
        arrow:SetTextureCoords(1, 0, 0, 1)
        arrow.animation:PlayFromEnd()
    end

    if takeControl then
        self:GetOwner():NotifyTakingControlOf(bar)
        arrow.animation.hasControlOfBar = true
    end
end

function ZO_UnitVisualizer_ArrowRegenerationModule:PlayRightArrow(bar, forward, widthModifier, takeControl)
    local width = bar:GetWidth() * widthModifier
    local offsetX = width - ARROW_TEXTURE_WIDTH

    local arrow = self:AcquireArrow(bar)
    arrow:SetAnchor(RIGHT, bar, RIGHT, -offsetX, OFFSET_Y)
    arrow.animation:GetFirstAnimation():SetTranslateDeltas(offsetX - END_X_PADDING, 0)

    if forward then
        arrow:SetTextureCoords(1, 0, 0, 1)
        arrow.animation:PlayFromStart()
    else
        arrow:SetTextureCoords(0, 1, 0, 1)
        arrow.animation:PlayFromEnd()
    end

    if takeControl then
        self:GetOwner():NotifyTakingControlOf(bar)
        arrow.animation.hasControlOfBar = true
    end
end

function ZO_UnitVisualizer_ArrowRegenerationModule:PlayArrow(bar, stat, value, takeControl)
    local forward = value > 0
    if stat == STAT_HEALTH_REGEN_COMBAT then
        self:PlayLeftArrow(bar, forward, .5, takeControl)
        self:PlayRightArrow(bar, forward, .5, takeControl)
    else
        if stat == STAT_MAGICKA_REGEN_COMBAT then
            self:PlayLeftArrow(bar, forward, 1.0, takeControl)
        elseif stat == STAT_STAMINA_REGEN_COMBAT then
            self:PlayRightArrow(bar, forward, 1.0, takeControl)
        end
    end
end

function ZO_UnitVisualizer_ArrowRegenerationModule:ApplyPlatformStyle()
    local activeArrows = self.arrowPool:GetActiveObjects()

    for _, control in pairs(activeArrows) do
        ApplyTemplateToControl(control, ZO_GetPlatformTemplate(ARROW_REGENERATION_TEMPLATE))
    end
end