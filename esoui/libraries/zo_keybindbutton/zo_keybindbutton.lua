local ZO_KeybindButtonMixin = {}

function ZO_KeybindButtonMixin:GetKeybind()
    return (IsInGamepadPreferredMode() or self.alwaysPreferGamepadMode) and self.gamepadPreferredKeybind or self.keybind
end

function ZO_KeybindButtonMixin:GetKeyboardKeybind()
    return self.keybind
end

function ZO_KeybindButtonMixin:GetGamepadKeybind()
    return self.gamepadPreferredKeybind
end

function ZO_KeybindButtonMixin:UpdateEnabledState()
    self.nameLabel:SetEnabled(self.enabled)
    local keybindEnabled = self.keybindEnabled and self.enabled
    local keybindColor = keybindEnabled and ZO_SELECTED_TEXT or ZO_DISABLED_TEXT
    self.keyLabel:SetColor(keybindColor:UnpackRGBA())
    self.keyLabel:SetAlpha((self:GetKeybind() or self.customKeyText) and 1 or 0)

    ZO_KeyMarkupLabel_SetEdgeFileColor(self.keyLabel, keybindColor)
end

function ZO_KeybindButtonMixin:SetEnabled(enabled)
    if(enabled ~= self.enabled) then
        self.enabled = enabled
        self:UpdateEnabledState()
    end
end

function ZO_KeybindButtonMixin:SetState(buttonState, locked)
    self:SetEnabled(buttonState ~= BSTATE_DISABLED)
end

function ZO_KeybindButtonMixin:SetKeybindEnabled(enabled)
    if(enabled ~= self.keybindEnabled) then
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

function ZO_KeybindButtonMixin:SetText(text)
    self.nameLabel:SetText(text)
end

function ZO_KeybindButtonMixin:SetCustomKeyText(keyText)
    self.customKeyText = true
    self.keyLabel:SetText(ZO_Keybindings_GenerateKeyMarkup(keyText))
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
    if(not self:GetUsingCustomAnchors()) then
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
    label.owner:AdjustBindingAnchors(not ZO_Keybindings_HasTexturePathForKey(key))
end

function ZO_KeybindButtonMixin:SetKeybind(keybind, showUnbound, gamepadPreferredKeybind, alwaysPreferGamepadMode)
    local hadKeybind = self:GetKeybind() ~= nil

    self.keybind = keybind
    self.gamepadPreferredKeybind = gamepadPreferredKeybind
    self.alwaysPreferGamepadMode = alwaysPreferGamepadMode

    keybind = self:GetKeybind()

    if keybind then
        if hadKeybind then
            ZO_Keybindings_UnregisterLabelForBindingUpdate(self.keyLabel)
        end
        ZO_Keybindings_RegisterLabelForBindingUpdate(self.keyLabel, self.keybind, showUnbound, self.gamepadPreferredKeybind, OnKeybindLabelChanged, alwaysPreferGamepadMode)
    else
        ZO_Keybindings_UnregisterLabelForBindingUpdate(self.keyLabel)
    end
    self:UpdateEnabledState()
end

function ZO_KeybindButtonMixin:SetCallback(callback)
    self.callback = callback
end

function ZO_KeybindButtonMixin:OnClicked()
    if(self.enabled) then
        if(self.clickSound) then
            PlaySound(self.clickSound)
        end
        if(self.callback) then
            self.callback(self)
        end
    else
        PlaySound(SOUNDS.KEYBIND_BUTTON_DISABLED)
    end
end

function ZO_KeybindButtonTemplate_OnMouseUp(self, button, upInside)
    if(upInside and (button == MOUSE_BUTTON_INDEX_LEFT) and self.enabled) then
        self:OnClicked()
    end
end

local g_areKeybindsEnabled
local g_keybindButtons = {}
local g_numDisabledReferences = 0
local function OnUpdate()
    local shouldKeybindsBeEnabled = WINDOW_MANAGER:GetFocusControl() == nil and g_numDisabledReferences == 0
    if(shouldKeybindsBeEnabled ~= g_areKeybindsEnabled) then
        g_areKeybindsEnabled = shouldKeybindsBeEnabled
        for i = 1, #g_keybindButtons do
            if(not g_keybindButtons[i].keybindEnabledInEdit) then
                g_keybindButtons[i]:SetKeybindEnabled(shouldKeybindsBeEnabled)
            end
        end
    end
end
EVENT_MANAGER:RegisterForUpdate("KeybindButtonUpdate", 0, OnUpdate)

function ZO_KeybindButtonTemplate_AddGlobalDisableReference()
    g_numDisabledReferences = g_numDisabledReferences + 1
end

function ZO_KeybindButtonTemplate_RemoveGlobalDisableReference()
    g_numDisabledReferences = g_numDisabledReferences - 1
end


function ZO_KeybindButtonTemplate_OnInitialized(self)
    self.nameLabel = self:GetNamedChild("NameLabel")
    self.keyLabel = self:GetNamedChild("KeyLabel")
    self.keyLabel.owner = self
    self.enabled = true
    self.keybindEnabled = true

    zo_mixin(self, ZO_KeybindButtonMixin)

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
