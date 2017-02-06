ZO_CHROMA_UNDERLAY_ALPHA = .5
local DEAD_EFFECT_COLOR = ZO_ColorDef:New(1, 0, 0, 1)
local QUICKSLOT_READY_COLOR = ZO_ColorDef:New(1, 1, 1, 1)
local ULTIMATE_READY_COLOR = ZO_ColorDef:New(1, 1, 1, 1)
local PLAYER_TO_PLAYER_PROMPT_COLOR = ZO_ColorDef:New(1, 1, 1, 1)

ZO_IngameRzChroma_Effects = ZO_RzChroma_Effects:Subclass()

function ZO_IngameRzChroma_Effects:New(...)
    return ZO_RzChroma_Effects.New(self, ...)
end

function ZO_IngameRzChroma_Effects:Initialize()
    ZO_RzChroma_Effects.Initialize(self)

    local r, g, b = DEAD_EFFECT_COLOR:UnpackRGB()
    self.deathEffects =
    {
        [CHROMA_DEVICE_TYPE_KEYBOARD] = ZO_ChromaCStyleCustomSingleColorFadingEffect:New(CHROMA_DEVICE_TYPE_KEYBOARD, ZO_CHROMA_EFFECT_DRAW_LEVEL.COVER, CHROMA_CUSTOM_EFFECT_GRID_STYLE_FULL, ZO_CHROMA_ANIMATION_TIMER_DATA.DEATH_PULSATE, DEAD_EFFECT_COLOR, CHROMA_BLEND_MODE_NORMAL),
        [CHROMA_DEVICE_TYPE_KEYPAD] = ZO_ChromaCStyleCustomSingleColorFadingEffect:New(CHROMA_DEVICE_TYPE_KEYPAD, ZO_CHROMA_EFFECT_DRAW_LEVEL.COVER, CHROMA_CUSTOM_EFFECT_GRID_STYLE_FULL, ZO_CHROMA_ANIMATION_TIMER_DATA.DEATH_PULSATE, DEAD_EFFECT_COLOR, CHROMA_BLEND_MODE_NORMAL),
        [CHROMA_DEVICE_TYPE_MOUSE] = ZO_ChromaCStyleCustomSingleColorFadingEffect:New(CHROMA_DEVICE_TYPE_MOUSE, ZO_CHROMA_EFFECT_DRAW_LEVEL.COVER, CHROMA_CUSTOM_EFFECT_GRID_STYLE_FULL, ZO_CHROMA_ANIMATION_TIMER_DATA.DEATH_PULSATE, DEAD_EFFECT_COLOR, CHROMA_BLEND_MODE_NORMAL),
        [CHROMA_DEVICE_TYPE_MOUSEPAD] = ZO_ChromaCStyleCustomSingleColorFadingEffect:New(CHROMA_DEVICE_TYPE_MOUSEPAD, ZO_CHROMA_EFFECT_DRAW_LEVEL.COVER, CHROMA_CUSTOM_EFFECT_GRID_STYLE_FULL, ZO_CHROMA_ANIMATION_TIMER_DATA.DEATH_PULSATE, DEAD_EFFECT_COLOR, CHROMA_BLEND_MODE_NORMAL),
        [CHROMA_DEVICE_TYPE_HEADSET] = ZO_ChromaPredefinedEffect:New(CHROMA_DEVICE_TYPE_HEADSET, ZO_CHROMA_EFFECT_DRAW_LEVEL.UNDERLAY_HIGH, ChromaCreateHeadsetBreathingEffect, r, g, b),
    }
    self:SetVisualDataForKeybindAction("UI_SHORTCUT_QUICK_SLOTS", ZO_CHROMA_ANIMATION_TIMER_DATA.QUICKSLOT_ONE_PULSE, QUICKSLOT_READY_COLOR, CHROMA_BLEND_MODE_NORMAL)
    self:SetVisualDataForKeybindAction("ACTION_BUTTON_8", ZO_CHROMA_ANIMATION_TIMER_DATA.ULTIMATE_ONE_PULSE, ULTIMATE_READY_COLOR, CHROMA_BLEND_MODE_NORMAL)
    self:SetVisualDataForKeybindAction("PLAYER_TO_PLAYER_INTERACT_ACCEPT", ZO_CHROMA_ANIMATION_TIMER_DATA.PLAYER_TO_PLAYER_PROMPT_PULSATE, PLAYER_TO_PLAYER_PROMPT_COLOR, CHROMA_BLEND_MODE_NORMAL)
    self:SetVisualDataForKeybindAction("PLAYER_TO_PLAYER_INTERACT_DECLINE", ZO_CHROMA_ANIMATION_TIMER_DATA.PLAYER_TO_PLAYER_PROMPT_PULSATE, PLAYER_TO_PLAYER_PROMPT_COLOR, CHROMA_BLEND_MODE_NORMAL)
    
end

function ZO_IngameRzChroma_Effects:RegisterForEvents()
    ZO_RzChroma_Effects.RegisterForEvents(self)

    local function OnPlayerActivated()
        self:SetAlliance(GetUnitAlliance("player"))
        if IsUnitDead("player") then
            self:AddDeathEffects()
        end

        local ultimateCost, mechanic = GetSlotAbilityCost(ACTION_BAR_ULTIMATE_SLOT_INDEX + 1)
        if mechanic == POWERTYPE_ULTIMATE then
            local currentUltimatePower = GetUnitPower("player", POWERTYPE_ULTIMATE)
            if currentUltimatePower >= ultimateCost then
                ZO_RZCHROMA_EFFECTS:AddKeybindActionEffect("ACTION_BUTTON_8")
            else
                ZO_RZCHROMA_EFFECTS:RemoveKeybindActionEffect("ACTION_BUTTON_8")
            end
        end
    end

    local function OnPlayerDead()
        self:AddDeathEffects()
    end

    local function OnPlayerAlive()
        self:RemoveDeathEffects()
    end

    EVENT_MANAGER:RegisterForEvent("RzChromaManager", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
    EVENT_MANAGER:RegisterForEvent("RzChromaManager", EVENT_PLAYER_DEAD, OnPlayerDead)
    EVENT_MANAGER:RegisterForEvent("RzChromaManager", EVENT_PLAYER_ALIVE, OnPlayerAlive)
end

function ZO_IngameRzChroma_Effects:AddDeathEffects()
    for deviceType, effect in pairs(self.deathEffects) do
        ZO_RZCHROMA_MANAGER:AddEffect(effect)
    end
end

function ZO_IngameRzChroma_Effects:RemoveDeathEffects()
    for deviceType, effect in pairs(self.deathEffects) do
        ZO_RZCHROMA_MANAGER:RemoveEffect(effect)
    end
end

if IsChromaSystemAvailable() then
    ZO_RZCHROMA_EFFECTS = ZO_IngameRzChroma_Effects:New()
end