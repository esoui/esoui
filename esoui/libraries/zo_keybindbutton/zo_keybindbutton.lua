ZO_KeybindButtonMixin = {}

function ZO_KeybindButtonMixin:GetKeybind()
    return ZO_Keybindings_ShouldUseGamepadAction(self.alwaysPreferGamepadMode) and self.gamepadPreferredKeybind or self.keybind
end

function ZO_KeybindButtonMixin:GetKeyboardKeybind()
    return self.keybind
end

function ZO_KeybindButtonMixin:GetGamepadKeybind()
    return self.gamepadPreferredKeybind
end

function ZO_KeybindButtonMixin:UpdateEnabledState()
    if self:IsHidden() then
        self.enableStateDirty = true
        return false
    else
        self.nameLabel:SetEnabled(self.enabled)
        local keybindEnabled = self.keybindEnabled and self.enabled
        local keybindColor = keybindEnabled and ZO_SELECTED_TEXT or ZO_DISABLED_TEXT
        self.keyLabel:SetColor(keybindColor:UnpackRGBA())
        self.keyLabel:SetAlpha((self:GetKeybind() or self.customKeyText) and 1 or 0)

        ZO_KeyMarkupLabel_SetEdgeFileColor(self.keyLabel, keybindColor)
        return true
    end
end

function ZO_KeybindButtonMixin:SetEnabled(enabled)
    if enabled ~= self.enabled then
        self.enabled = enabled
        self:UpdateEnabledState()
    end
end

function ZO_KeybindButtonMixin:SetState(buttonState, locked)
    self:SetEnabled(buttonState ~= BSTATE_DISABLED)
end

function ZO_KeybindButtonMixin:SetKeybindEnabled(enabled)
    if enabled ~= self.keybindEnabled then
        self.keybindEnabled = enabled
        self:UpdateEnabledState()
    end
end

function ZO_KeybindButtonMixin:IsEnabled()
    return self.enabled
end

function ZO_KeybindButtonMixin:SetClickSound(clickSound)
    self.clickSound = clickSound
end

function ZO_KeybindButtonMixin:SetText(text, narrationText)
    self.nameText = text
    self.nameTextNarration = narrationText
    self.nameLabel:SetText(self.nameText)
end

function ZO_KeybindButtonMixin:SetCustomKeyText(keyText)
    self.customKeyText = true
    self.keyLabel:SetText(ZO_Keybindings_GenerateTextKeyMarkup(keyText))
    self:UpdateEnabledState()
end

function ZO_KeybindButtonMixin:SetCustomKeyIcon(keyIcon)
    local key = ("|t%f%%:%f%%:%s|t"):format(200, 200, keyIcon)
    self.customKeyText = true
    self.keyLabel:SetText(key)
    self:UpdateEnabledState()
end

function ZO_KeybindButtonMixin:ShowKeyIcon()
    self.keyLabel:SetHidden(false)
end

function ZO_KeybindButtonMixin:HideKeyIcon()
    self.keyLabel:SetHidden(true)
end

function ZO_KeybindButtonMixin:SetupStyle(styleInfo)
    KEYBIND_STRIP:SetupButtonStyle(self, styleInfo or KEYBIND_STRIP:GetStyle())
end

function ZO_KeybindButtonMixin:SetKeybindEnabledInEdit(enabled)
    self.keybindEnabledInEdit = enabled
end

function ZO_KeybindButtonMixin:SetMouseOverEnabled(enabled)
    ZO_SelectableLabel_SetMouseOverEnabled(self.nameLabel, enabled)
end

function ZO_KeybindButtonMixin:SetNormalTextColor(color)
    ZO_SelectableLabel_SetNormalColor(self.nameLabel, color)
end

function ZO_KeybindButtonMixin:SetNameFont(font)
    self.nameLabel:SetFont(font)
end

function ZO_KeybindButtonMixin:SetKeyFont(font)
    self.keyLabel:SetFont(font)
end

function ZO_KeybindButtonMixin:AdjustBindingAnchors(wideSpacing)
    if not self:GetUsingCustomAnchors() then
        self.keyLabel:SetAnchor(RIGHT, self.nameLabel, LEFT, wideSpacing and -15 or 0)
    end
end

function ZO_KeybindButtonMixin:SetUsingCustomAnchors(useCustom)
    self.usingCustomAnchors = useCustom
end

function ZO_KeybindButtonMixin:GetUsingCustomAnchors()
    return self.usingCustomAnchors
end

local function OnKeybindLabelChanged(label, bindingText, key, mod1, mod2, mod3, mod4)
    label.owner:AdjustBindingAnchors(not ZO_Keybindings_ShouldUseIconKeyMarkup(key))
end

function ZO_KeybindButtonMixin:SetKeybind(keybind, showUnbound, gamepadPreferredKeybind, alwaysPreferGamepadMode, showAsHold)
    local hadKeybind = self:GetKeybind() ~= nil

    self.keybind = keybind
    self.gamepadPreferredKeybind = gamepadPreferredKeybind
    self.alwaysPreferGamepadMode = alwaysPreferGamepadMode

    keybind = self:GetKeybind()

    if keybind then
        if hadKeybind then
            ZO_Keybindings_UnregisterLabelForBindingUpdate(self.keyLabel)
        end
        ZO_Keybindings_RegisterLabelForBindingUpdate(self.keyLabel, self.keybind, showUnbound, self.gamepadPreferredKeybind, OnKeybindLabelChanged, alwaysPreferGamepadMode, showAsHold)
    else
        ZO_Keybindings_UnregisterLabelForBindingUpdate(self.keyLabel)
    end
    self:UpdateEnabledState()
end

function ZO_KeybindButtonMixin:SetCallback(callback)
    self.callback = callback
end

function ZO_KeybindButtonMixin:GetKeybindButtonDescriptorReference()
    return self.keybindDescriptorReference
end

--Generate narration data for this keybind button
--If the keybind is not visible, nothing will be returned
function ZO_KeybindButtonMixin:GetKeybindButtonNarrationData()
    local visible = self.keybindDescriptorReference and self.keybindDescriptorReference.visible or true
    if type(visible) == "function" then
        visible = visible()
    end

    if visible then
        local narrationData =
        {
            name = self.nameTextNarration or self.nameText,
            keybindName = ZO_Keybindings_GetHighestPriorityNarrationStringFromAction(self:GetKeybind()) or GetString(SI_ACTION_IS_NOT_BOUND),
            enabled = self.enabled, 
        }
        return narrationData
    end
end

function ZO_KeybindButtonMixin:SetKeybindButtonDescriptor(keybindDescriptor)
    self.keybindDescriptorReference = keybindDescriptor

    if keybindDescriptor.name then
        local name = keybindDescriptor.name
        if type(keybindDescriptor.name) == "function" then
            name = keybindDescriptor.name()
        end
       self:SetText(name)
    end
    
    if keybindDescriptor.keybind then
        self:SetKeybind(keybindDescriptor.keybind)
    end

    if keybindDescriptor.callback then
        self:SetCallback(keybindDescriptor.callback)
    end

    if keybindDescriptor.sound then
        self:SetClickSound(keybindDescriptor.sound)
    end

    if keybindDescriptor.customKeyText then
        self:SetCustomKeyText(keybindDescriptor.customKeyText)
    end

    if keybindDescriptor.customKeyIcon then
        self:SetCustomKeyIcon(keybindDescriptor.customKeyIcon)
    end
end

function ZO_KeybindButtonMixin:OnClicked()
    local visible = self.keybindDescriptorReference and self.keybindDescriptorReference.visible or true
    if type(visible) == "function" then
        visible = visible()
    end

    if visible then
        if self.enabled then
            if self.clickSound then
                if type(self.clickSound) == "function" then
                    PlaySound(self.clickSound())
                else
                    PlaySound(self.clickSound)
                end
            end
            if self.callback then
                self.callback(self)
            end
        else
            PlaySound(SOUNDS.KEYBIND_BUTTON_DISABLED)
        end
    end
end

local g_cooldownButtons = {}

-- Should only be used for Floating Keybind Buttons
-- Otherwise use ZO_KeybindStrip:TriggerCooldown
function ZO_KeybindButtonMixin:SetCooldown(durationMs)
    self.cooldownDurationMs = durationMs
    self.cooldownStartTimeMs = GetFrameTimeMilliseconds()

    --Check for duplicates
    for i, button in ipairs(g_cooldownButtons) do
        if button == self then
            return
        end
    end

    self.baseText = self.nameLabel:GetText()
    table.insert(g_cooldownButtons, self)
end

local g_areKeybindsEnabled
local g_keybindButtons = {}
local g_numDisabledReferences = 0
local function OnUpdate()
    local shouldKeybindsBeEnabled = WINDOW_MANAGER:GetFocusControl() == nil and g_numDisabledReferences == 0
    if shouldKeybindsBeEnabled ~= g_areKeybindsEnabled then
        g_areKeybindsEnabled = shouldKeybindsBeEnabled
        for i = 1, #g_keybindButtons do
            local currentKeybindButton = g_keybindButtons[i]
            if not currentKeybindButton.keybindEnabledInEdit then
                currentKeybindButton:SetKeybindEnabled(shouldKeybindsBeEnabled)
            end
        end
    end

    local currentTimeMs = GetFrameTimeMilliseconds()
    for i = #g_cooldownButtons, 1, -1 do
        local button = g_cooldownButtons[i]
        local timeDifferenceMs = currentTimeMs - button.cooldownStartTimeMs
        local shouldBeEnabled = timeDifferenceMs > button.cooldownDurationMs
        if shouldBeEnabled then
            button:SetText(button.baseText)
            button.cooldownDurationMs = nil
            button.cooldownStartTimeMs = nil
            table.remove(g_cooldownButtons, i)
        else
            local secondsTillEnabled = zo_ceil((button.cooldownStartTimeMs + button.cooldownDurationMs - currentTimeMs) / 1000)
            button:SetText(zo_strformat(SI_BINDING_NAME_COOLDOWN_FORMAT, button.baseText, secondsTillEnabled))
        end
        button:SetEnabled(shouldBeEnabled)
    end
end
EVENT_MANAGER:RegisterForUpdate("KeybindButtonUpdate", 0, OnUpdate)

function ZO_KeybindButtonTemplate_AddGlobalDisableReference()
    g_numDisabledReferences = g_numDisabledReferences + 1
end

function ZO_KeybindButtonTemplate_RemoveGlobalDisableReference()
    g_numDisabledReferences = g_numDisabledReferences - 1
end

function ZO_KeybindButtonTemplate_OnMouseUp(self, button, upInside)
    if upInside and (button == MOUSE_BUTTON_INDEX_LEFT) and self.enabled then
        self:OnClicked()
    end
end

function ZO_KeybindButtonTemplate_OnInitialized(self)
    self.nameLabel = self:GetNamedChild("NameLabel")
    self.keyLabel = self:GetNamedChild("KeyLabel")
    self.keyLabel.owner = self
    self.enabled = true
    self.keybindEnabled = true

    zo_mixin(self, ZO_KeybindButtonMixin)

    self:SetHandler("OnEffectivelyShown", function()
        if self.enableStateDirty then
            self.enableStateDirty = nil
            self:UpdateEnabledState()
        end
    end)

    ZO_KeyMarkupLabel_SetCustomOffsets(self.keyLabel, -5, 5, -2, 3)

    ZO_SelectableLabel_OnInitialized(self.nameLabel)

    table.insert(g_keybindButtons, self)

    self:UpdateEnabledState()
end

function ZO_KeybindButtonTemplate_Setup(self, keybind, callbackFunction, text)
    ZO_KeybindButtonTemplate_OnInitialized(self)
    self:SetKeybind(keybind)
    self:SetText(text)
    self:SetCallback(callbackFunction)
end

ZO_ChromaKeybindButtonMixin = {}

function ZO_ChromaKeybindButtonMixin:SetChromaEnabled(enabled)
    if self.chromaEnabled ~= enabled then
        self.chromaEnabled = enabled
        self:UpdateChromaEffect()
    end
end

function ZO_ChromaKeybindButtonMixin:AddChromaEffect()
    if ZO_RZCHROMA_EFFECTS and self:AreChromaEffectsEnabled() then
        local keybindAction = self:GetKeyboardKeybind()
        if keybindAction then
            ZO_RZCHROMA_EFFECTS:AddKeybindActionEffect(keybindAction)
        end
    end
end

function ZO_ChromaKeybindButtonMixin:RemoveChromaEffect()
    if ZO_RZCHROMA_EFFECTS then
        local keybindAction = self:GetKeyboardKeybind()
        if keybindAction then
            ZO_RZCHROMA_EFFECTS:RemoveKeybindActionEffect(keybindAction)
        end
    end
end

function ZO_ChromaKeybindButtonMixin:UpdateChromaEffect()
    if ZO_RZCHROMA_EFFECTS and not self:IsHidden() then
        local keybindAction = self:GetKeyboardKeybind()
        if keybindAction then
            if self:AreChromaEffectsEnabled() then
                ZO_RZCHROMA_EFFECTS:AddKeybindActionEffect(keybindAction)
            else
                ZO_RZCHROMA_EFFECTS:RemoveKeybindActionEffect(keybindAction)
            end
        end
    end
end

function ZO_ChromaKeybindButtonMixin:SetKeybind(keybind, showUnbound, gamepadPreferredKeybind, alwaysPreferGamepadMode)
    local previousKeybind = self:GetKeyboardKeybind()
    local refreshKeybind = keybind ~= previousKeybind and not self:IsHidden()

    if refreshKeybind then
        self:RemoveChromaEffect()
    end

    ZO_KeybindButtonMixin.SetKeybind(self, keybind, showUnbound, gamepadPreferredKeybind, alwaysPreferGamepadMode)

    if refreshKeybind then
        self:AddChromaEffect()
    end
end

function ZO_ChromaKeybindButtonMixin:UpdateEnabledState()
    if ZO_KeybindButtonMixin.UpdateEnabledState(self) then
        self:UpdateChromaEffect()
    end
end

function ZO_ChromaKeybindButtonMixin:AreChromaEffectsEnabled()
    return self.chromaEnabled and self:IsEnabled()
end

function ZO_ChromaKeybindButtonTemplate_OnInitialized(self)
    ZO_KeybindButtonTemplate_OnInitialized(self)
    zo_mixin(self, ZO_ChromaKeybindButtonMixin)
    self:SetChromaEnabled(true)
end

function ZO_ChromaKeybindButtonTemplate_Setup(self, keybind, callbackFunction, text)
    ZO_ChromaKeybindButtonTemplate_OnInitialized(self)
    self:SetKeybind(keybind)
    self:SetText(text)
    self:SetCallback(callbackFunction)
end

function ZO_KeybindButton_ChromaBehavior_OnEffectivelyShown(self)
    if self.AddChromaEffect then
        self:AddChromaEffect()
    end
end

function ZO_KeybindButton_ChromaBehavior_OnEffectivelyHidden(self)
    if self.RemoveChromaEffect then
        self:RemoveChromaEffect()
    end
end