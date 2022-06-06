ZO_UtilityWheel_Keyboard = ZO_UtilityWheel_Shared:Subclass()

function ZO_UtilityWheel_Keyboard:Initialize(...)
    ZO_UtilityWheel_Shared.Initialize(self, ...)
    ZO_Keybindings_RegisterLabelForBindingUpdate(self.cycleLeftKeybindLabel, "UTILITY_WHEEL_KEYBOARD_CYCLE_LEFT")
    ZO_Keybindings_RegisterLabelForBindingUpdate(self.cycleRightKeybindLabel, "UTILITY_WHEEL_KEYBOARD_CYCLE_RIGHT")
end

function ZO_UtilityWheel_Keyboard:SetupEntryControl(entryControl, data)
    ZO_UtilityWheel_Shared.SetupEntryControl(self, entryControl, data)
    ZO_UtilityWheel_Keyboard_CooldownSetup(entryControl, data.slotNum, self:GetHotbarCategory())
end

function ZO_UtilityWheel_Keyboard_Initialize(control)
    local actionLayers = { "RadialMenu", GetString(SI_KEYBINDINGS_LAYER_UTILITY_WHEEL) }
    UTILITY_WHEEL_KEYBOARD = ZO_UtilityWheel_Keyboard:New(control, "ZO_UtilityWheelMenuEntryTemplate_Keyboard", "DefaultRadialMenuAnimation", "SelectableItemRadialMenuEntryAnimation", actionLayers)
end

function ZO_UtilityWheel_Keyboard_CooldownSetup(control, slotNum, hotbarCategory)
    if control.cooldown then
        local remaining, duration = GetSlotCooldownInfo(slotNum, hotbarCategory)
        local isInCooldown = remaining > 0 and duration > 0
        if isInCooldown then
            control.cooldown:SetVerticalCooldownLeadingEdgeHeight(12)
            control.cooldown:SetFillColor(ZO_SELECTED_TEXT:UnpackRGBA())
            control.cooldown:SetDesaturation(1)
            control.cooldown:SetAlpha(1)
            control.cooldown:SetTexture(GetSlotTexture(slotNum, hotbarCategory))
            local USE_LEADING_EDGE = true
            control.cooldown:StartCooldown(remaining, duration, CD_TYPE_VERTICAL_REVEAL, CD_TIME_TYPE_TIME_UNTIL, USE_LEADING_EDGE)
        else
            control.cooldown:ResetCooldown()
        end
        control.cooldown:SetHidden(not isInCooldown)
    end
end