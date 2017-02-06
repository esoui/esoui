ZO_CHROMA_UNDERLAY_ALPHA = .5
local FALLBACK_CANVAS_COLOR = ZO_ColorDef:New(0.773, 0.761, 0.62, ZO_CHROMA_UNDERLAY_ALPHA)

ZO_RzChroma_Effects = ZO_Object:Subclass()

function ZO_RzChroma_Effects:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_RzChroma_Effects:Initialize()
    self:RegisterForEvents()

    ChromaDeleteAllCustomEffectIds()

    self.allianceEffects = { }

    for alliance = ALLIANCE_NONE, ALLIANCE_DAGGERFALL_COVENANT do
        local allianceColor
        if alliance == ALLIANCE_NONE then
            allianceColor = FALLBACK_CANVAS_COLOR
        else
            allianceColor = GetAllianceColor(alliance):Clone()
            allianceColor:SetAlpha(ZO_CHROMA_UNDERLAY_ALPHA)
        end
        local r, g, b = allianceColor:UnpackRGB()
        local NO_ANIMATION_TIMER = nil
        self.allianceEffects[alliance] =
        {
            [CHROMA_DEVICE_TYPE_KEYBOARD] = ZO_ChromaCStyleCustomSingleColorEffect:New(CHROMA_DEVICE_TYPE_KEYBOARD, ZO_CHROMA_EFFECT_DRAW_LEVEL.FALLBACK, CHROMA_CUSTOM_EFFECT_GRID_STYLE_FULL, NO_ANIMATION_TIMER, allianceColor, CHROMA_BLEND_MODE_NORMAL),
            [CHROMA_DEVICE_TYPE_KEYPAD] = ZO_ChromaCStyleCustomSingleColorEffect:New(CHROMA_DEVICE_TYPE_KEYPAD, ZO_CHROMA_EFFECT_DRAW_LEVEL.FALLBACK, CHROMA_CUSTOM_EFFECT_GRID_STYLE_FULL, NO_ANIMATION_TIMER, allianceColor, CHROMA_BLEND_MODE_NORMAL),
            [CHROMA_DEVICE_TYPE_MOUSE] = ZO_ChromaCStyleCustomSingleColorEffect:New(CHROMA_DEVICE_TYPE_MOUSE, ZO_CHROMA_EFFECT_DRAW_LEVEL.FALLBACK, CHROMA_CUSTOM_EFFECT_GRID_STYLE_FULL, NO_ANIMATION_TIMER, allianceColor, CHROMA_BLEND_MODE_NORMAL),
            [CHROMA_DEVICE_TYPE_MOUSEPAD] = ZO_ChromaCStyleCustomSingleColorEffect:New(CHROMA_DEVICE_TYPE_MOUSEPAD, ZO_CHROMA_EFFECT_DRAW_LEVEL.FALLBACK, CHROMA_CUSTOM_EFFECT_GRID_STYLE_FULL, NO_ANIMATION_TIMER, allianceColor, CHROMA_BLEND_MODE_NORMAL),
            [CHROMA_DEVICE_TYPE_HEADSET] = ZO_ChromaPredefinedEffect:New(CHROMA_DEVICE_TYPE_HEADSET, ZO_CHROMA_EFFECT_DRAW_LEVEL.FALLBACK, ChromaCreateHeadsetStaticEffect, r, g, b),
        }
    end

    self.keybindActionVisualData = { }
    self.keybindActionEffects = { }

    self:SetAlliance(ALLIANCE_NONE)
end

function ZO_RzChroma_Effects:RegisterForEvents()
    --To be overriden
end

function ZO_RzChroma_Effects:SetAlliance(alliance)
    if self.activeAlliance ~= alliance then
        local previousActiveAllianceEffects = self.allianceEffects[self.activeAlliance]
        local newActiveAllianceEffects = self.allianceEffects[alliance]
        for deviceType, newEffect in pairs(newActiveAllianceEffects) do
            if self.activeAlliance then
                local previousEffect = previousActiveAllianceEffects[deviceType]
                ZO_RZCHROMA_MANAGER:RemoveEffect(previousEffect)
            end

            local newEffect = newActiveAllianceEffects[deviceType]
            ZO_RZCHROMA_MANAGER:AddEffect(newEffect)
        end
        self.activeAlliance = alliance
    end
end

function ZO_RzChroma_Effects:SetVisualDataForKeybindAction(actionName, animationTimerData, color, blendMode)
    self.keybindActionVisualData[actionName] = { animationTimerData = animationTimerData, color = color, blendMode = blendMode }
end

function ZO_RzChroma_Effects:AddKeybindActionEffect(actionName)
    self:RemoveKeybindActionEffect(actionName)

    local row, column = ZO_ChromaGetCustomEffectCoordinatesForAction(actionName)
    if row and column then
        local visualData = self.keybindActionVisualData[actionName]
        if visualData then
            local effect = ZO_ChromaCStyleCustomSingleColorFadingEffect:New(CHROMA_DEVICE_TYPE_KEYBOARD, ZO_CHROMA_EFFECT_DRAW_LEVEL.ACTIVE_KEY, CHROMA_CUSTOM_EFFECT_GRID_STYLE_STATIC, visualData.animationTimerData, visualData.color, visualData.blendMode)
            effect:SetCellActive(row, column, true)
            effect:SetDeleteEffectCallback(function() self:RemoveKeybindActionEffect(actionName) end)
            self.keybindActionEffects[actionName] = effect
            ZO_RZCHROMA_MANAGER:AddEffect(effect)
        end
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