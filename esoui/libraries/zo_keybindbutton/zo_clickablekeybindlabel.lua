ZO_ClickableKeybindLabelMixin = {}

function ZO_ClickableKeybindLabelMixin:GetKeybind()
    return ZO_Keybindings_ShouldUseGamepadAction(self.alwaysPreferGamepadMode) and self.gamepadPreferredKeybind or self.keybind
end

function ZO_ClickableKeybindLabelMixin:GetKeyboardKeybind()
    return self.keybind
end

function ZO_ClickableKeybindLabelMixin:GetGamepadKeybind()
    return self.gamepadPreferredKeybind
end

function ZO_ClickableKeybindLabelMixin:UpdateEnabledState()
    if self:IsHidden() then
        self.enableStateDirty = true
    else
        local keybindEnabled = self.keybindEnabled and self.enabled
        local keybindColor = keybindEnabled and ZO_SELECTED_TEXT or ZO_DISABLED_TEXT
        self:SetColor(keybindColor:UnpackRGBA())
        self:SetAlpha((self:GetKeybind() or self.customKeyText) and 1 or 0)

        ZO_KeyMarkupLabel_SetEdgeFileColor(self, keybindColor)

        if self.updateRegisteredKeybindCallback then
            self.updateRegisteredKeybindCallback()
        end
    end
end

function ZO_ClickableKeybindLabelMixin:SetEnabled(enabled)
    if enabled ~= self.enabled then
        self.enabled = enabled
        self:UpdateEnabledState()
    end
end

function ZO_ClickableKeybindLabelMixin:IsEnabled()
    return self.enabled
end

function ZO_ClickableKeybindLabelMixin:SetKeybindEnabled(enabled)
    if enabled ~= self.keybindEnabled then
        self.keybindEnabled = enabled
        self:UpdateEnabledState()
    end
end

function ZO_ClickableKeybindLabelMixin:SetClickSound(clickSound)
    self.clickSound = clickSound
end

function ZO_ClickableKeybindLabelMixin:SetCustomKeyText(keyText)
    self.customKeyText = true
    self:SetText(ZO_Keybindings_GenerateTextKeyMarkup(keyText))
    self:UpdateEnabledState()
end

function ZO_ClickableKeybindLabelMixin:SetCustomKeyIcon(keyIcon)
    local key = ("|t%f%%:%f%%:%s|t"):format(200, 200, keyIcon)
    self.customKeyText = true
    self:SetText(key)
    self:UpdateEnabledState()
end

function ZO_ClickableKeybindLabelMixin:SetKeybindEnabledInEdit(enabled)
    self.keybindEnabledInEdit = enabled
end

-- options is a table of various options for displaying the keybind
--      alwaysPreferGamepadMode - if true we will always show a gamepad keybind
--      showUnbound - if false will hide the keybind if it's unbound
--      showAsHold - if true will show the keybind as a hold
--      scalePercent - overrides the default scale percent of the keybind icon
function ZO_ClickableKeybindLabelMixin:SetKeybind(keybind, gamepadPreferredKeybind, options)
    local hadKeybind = self:GetKeybind() ~= nil

    self.keybind = keybind
    self.gamepadPreferredKeybind = gamepadPreferredKeybind
    self.alwaysPreferGamepadMode = options and options.alwaysPreferGamepadMode or nil

    keybind = self:GetKeybind()

    if keybind then
        if hadKeybind then
            ZO_Keybindings_UnregisterLabelForBindingUpdate(self)
        end
        local NO_ON_CHANGE_CALLBACK = nil
        local showUnbound = nil
        local showAsHold = nil
        local scalePercent = nil
        if options then
            showUnbound = options.showUnbound
            showAsHold = options.showAsHold
            scalePercent = options.scalePercent
        end

        local function UseDisabledIcon()
            return not self:IsEnabled()
        end

        ZO_Keybindings_RegisterLabelForBindingUpdate(self, self.keybind, showUnbound, self.gamepadPreferredKeybind, NO_ON_CHANGE_CALLBACK, alwaysPreferGamepadMode, showAsHold, scalePercent, UseDisabledIcon)
    else
        ZO_Keybindings_UnregisterLabelForBindingUpdate(self)
    end
    self:UpdateEnabledState()
end

function ZO_ClickableKeybindLabelMixin:SetCallback(callback)
    self.callback = callback
end

function ZO_ClickableKeybindLabelMixin:GetKeybindButtonDescriptorReference()
    return self.keybindDescriptorReference
end

function ZO_ClickableKeybindLabelMixin:SetKeybindButtonDescriptor(keybindDescriptor)
    self.keybindDescriptorReference = keybindDescriptor
    
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

function ZO_ClickableKeybindLabelMixin:OnClicked()
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

local g_areKeybindsEnabled
local g_keybindLabels = {}
local g_numDisabledReferences = 0
local function OnUpdate()
    local shouldKeybindsBeEnabled = WINDOW_MANAGER:GetFocusControl() == nil and g_numDisabledReferences == 0
    if shouldKeybindsBeEnabled ~= g_areKeybindsEnabled then
        g_areKeybindsEnabled = shouldKeybindsBeEnabled
        for i, keybindButton in ipairs(g_keybindLabels) do
            if not keybindButton.keybindEnabledInEdit then
                keybindButton:SetKeybindEnabled(shouldKeybindsBeEnabled)
            end
        end
    end
end

EVENT_MANAGER:RegisterForUpdate("ClickableKeybindLabelUpdate", 0, OnUpdate)

function ZO_ClickableKeybindLabelTemplate_AddGlobalDisableReference()
    g_numDisabledReferences = g_numDisabledReferences + 1
end

function ZO_ClickableKeybindLabelTemplate_RemoveGlobalDisableReference()
    g_numDisabledReferences = g_numDisabledReferences - 1
end

function ZO_ClickableKeybindLabelTemplate_OnMouseUp(self, button, upInside)
    if upInside and (button == MOUSE_BUTTON_INDEX_LEFT) and self.enabled then
        self:OnClicked()
    end
end

function ZO_ClickableKeybindLabelTemplate_OnInitialized(self)
    self.enabled = true
    self.keybindEnabled = true

    zo_mixin(self, ZO_ClickableKeybindLabelMixin)

    self:SetHandler("OnEffectivelyShown", function()
        if self.enableStateDirty then
            self.enableStateDirty = nil
            self:UpdateEnabledState()
        end
    end)

    ZO_KeyMarkupLabel_SetCustomOffsets(self, -5, 5, -2, 3)

    table.insert(g_keybindLabels, self)

    self:UpdateEnabledState()
end

function ZO_ClickableKeybindLabelTemplate_Setup(self, keybind, callbackFunction, text)
    ZO_ClickableKeybindLabelTemplate_OnInitialized(self)
    self:SetKeybind(keybind)
    self:SetCallback(callbackFunction)
end