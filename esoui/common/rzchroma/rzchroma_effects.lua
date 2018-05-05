ZO_CHROMA_UNDERLAY_ALPHA = .5
ZO_CHROMA_ACTIVE_KEY_COLOR = ZO_ColorDef:New(1, 1, 1, 1)

local FALLBACK_CANVAS_COLOR = ZO_ColorDef:New(0.773, 0.761, 0.62, ZO_CHROMA_UNDERLAY_ALPHA)
local FALLBACK_KEYBIND_VISUAL_DATA = 
{
    animationTimerData = ZO_CHROMA_ANIMATION_TIMER_DATA.KEYBIND_PROMPT_PULSATE,
    color = ZO_CHROMA_ACTIVE_KEY_COLOR,
    blendMode = CHROMA_BLEND_MODE_NORMAL,
    level = ZO_CHROMA_EFFECT_DRAW_LEVEL.ACTIVE_KEY_UI,
}

ZO_RzChroma_Effects = ZO_Object:Subclass()

function ZO_RzChroma_Effects:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_RzChroma_Effects:CreateAllianceEffects(getColorFunction)
    local allianceEffects = {}
    for alliance = ALLIANCE_MIN_VALUE, ALLIANCE_MAX_VALUE do
        local allianceColor
        if alliance == ALLIANCE_NONE then
            allianceColor = FALLBACK_CANVAS_COLOR
        else
            allianceColor = getColorFunction(alliance):Clone()
            allianceColor:SetAlpha(ZO_CHROMA_UNDERLAY_ALPHA)
        end
        local r, g, b = allianceColor:UnpackRGB()
        local NO_ANIMATION_TIMER = nil
        allianceEffects[alliance] =
        {
            [CHROMA_DEVICE_TYPE_KEYBOARD] = ZO_ChromaCStyleCustomSingleColorEffect:New(CHROMA_DEVICE_TYPE_KEYBOARD, ZO_CHROMA_EFFECT_DRAW_LEVEL.FALLBACK, CHROMA_CUSTOM_EFFECT_GRID_STYLE_FULL, NO_ANIMATION_TIMER, allianceColor, CHROMA_BLEND_MODE_NORMAL),
            [CHROMA_DEVICE_TYPE_KEYPAD] = ZO_ChromaCStyleCustomSingleColorEffect:New(CHROMA_DEVICE_TYPE_KEYPAD, ZO_CHROMA_EFFECT_DRAW_LEVEL.FALLBACK, CHROMA_CUSTOM_EFFECT_GRID_STYLE_FULL, NO_ANIMATION_TIMER, allianceColor, CHROMA_BLEND_MODE_NORMAL),
            [CHROMA_DEVICE_TYPE_MOUSE] = ZO_ChromaCStyleCustomSingleColorEffect:New(CHROMA_DEVICE_TYPE_MOUSE, ZO_CHROMA_EFFECT_DRAW_LEVEL.FALLBACK, CHROMA_CUSTOM_EFFECT_GRID_STYLE_FULL, NO_ANIMATION_TIMER, allianceColor, CHROMA_BLEND_MODE_NORMAL),
            [CHROMA_DEVICE_TYPE_MOUSEPAD] = ZO_ChromaCStyleCustomSingleColorEffect:New(CHROMA_DEVICE_TYPE_MOUSEPAD, ZO_CHROMA_EFFECT_DRAW_LEVEL.FALLBACK, CHROMA_CUSTOM_EFFECT_GRID_STYLE_FULL, NO_ANIMATION_TIMER, allianceColor, CHROMA_BLEND_MODE_NORMAL),
            [CHROMA_DEVICE_TYPE_HEADSET] = ZO_ChromaPredefinedEffect:New(CHROMA_DEVICE_TYPE_HEADSET, ZO_CHROMA_EFFECT_DRAW_LEVEL.FALLBACK, ChromaCreateHeadsetStaticEffect, r, g, b),
        }
    end
    return allianceEffects
end

function ZO_RzChroma_Effects:Initialize()
    self:RegisterForEvents()

    ChromaDeleteAllCustomEffectIds()

    self.allianceEffects = self:CreateAllianceEffects(GetAllianceColor)
    self.battlegroundAllianceEffects = self:CreateAllianceEffects(GetBattlegroundAllianceColor)

    self.keybindActionVisualData = { }
    self.keybindActionEffects = { }

    self:SetAlliance(ALLIANCE_NONE)
end

function ZO_RzChroma_Effects:RegisterForEvents()
    --To be overriden
end

function ZO_RzChroma_Effects:GetAllianceEffects(alliance, inBattleground)
    local container
    if inBattleground then
        container = self.battlegroundAllianceEffects
    else
        container = self.allianceEffects
    end
    return container[alliance]
end

function ZO_RzChroma_Effects:SetAlliance(alliance, inBattleground)
    if inBattleground == nil then
        inBattleground = false
    end

    if self.activeAlliance ~= alliance or self.inBattleground ~= inBattleground then
        local previousActiveAllianceEffects = self:GetAllianceEffects(self.activeAlliance, self.inBattleground)
        local newActiveAllianceEffects = self:GetAllianceEffects(alliance, inBattleground)
        for deviceType, newEffect in pairs(newActiveAllianceEffects) do
            if self.activeAlliance then
                local previousEffect = previousActiveAllianceEffects[deviceType]
                ZO_RZCHROMA_MANAGER:RemoveEffect(previousEffect)
            end

            local newEffect = newActiveAllianceEffects[deviceType]
            ZO_RZCHROMA_MANAGER:AddEffect(newEffect)
        end
        self.activeAlliance = alliance
        self.inBattleground = inBattleground
    end
end

function ZO_RzChroma_Effects:SetVisualDataForKeybindAction(actionName, animationTimerData, color, blendMode, level)
    self.keybindActionVisualData[actionName] = { animationTimerData = animationTimerData, color = color, blendMode = blendMode, level = level }
end

function ZO_RzChroma_Effects:AddKeybindActionEffect(actionName)
    self:RemoveKeybindActionEffect(actionName)

    local row, column = ZO_ChromaGetCustomEffectCoordinatesForAction(actionName)
    if row and column then
        local visualData = self.keybindActionVisualData[actionName] or FALLBACK_KEYBIND_VISUAL_DATA
        local effect = ZO_ChromaCStyleCustomSingleColorFadingEffect:New(CHROMA_DEVICE_TYPE_KEYBOARD, visualData.level, CHROMA_CUSTOM_EFFECT_GRID_STYLE_STATIC_CELLS, visualData.animationTimerData, visualData.color, visualData.blendMode)
        effect:SetCellActive(row, column, true)
        effect:SetDeleteEffectCallback(function() self:RemoveKeybindActionEffect(actionName) end)
        self.keybindActionEffects[actionName] = effect
        ZO_RZCHROMA_MANAGER:AddEffect(effect)
    end
end

function ZO_RzChroma_Effects:RemoveKeybindActionEffect(actionName)
    local effect = self.keybindActionEffects[actionName]
    if effect then
        ChromaDeleteCustomEffectById(effect:GetEffectId())
        ZO_RZCHROMA_MANAGER:RemoveEffect(effect)
        self.keybindActionEffects[actionName] = nil
    end
end

function ZO_ChromaGetCustomEffectCoordinatesForAction(actionName)
    local layerIndex, categoryIndex, actionIndex = GetActionIndicesFromName(actionName)
    for bindingIndex = 1, GetMaxBindingsPerAction() do
        local guiKey, mod1, mod2, mod3, mod4 = GetActionBindingInfo(layerIndex, categoryIndex, actionIndex, bindingIndex)
        if guiKey ~= KEY_INVALID then                  
            -- Get the first non-gamepad, non-choord key
            if not IsKeyCodeGamepadKey(guiKey) and not IsKeyCodeChordKey(guiKey) then
                local chromaKey = GetChromaKeyboardKeyByZoGuiKey(guiKey)
                if chromaKey ~= CHROMA_KEYBOARD_KEY_INVALID then
                    return GetChromaKeyboardCellByChromaKeyboardKey(chromaKey)
                end
            end
        end
    end
end