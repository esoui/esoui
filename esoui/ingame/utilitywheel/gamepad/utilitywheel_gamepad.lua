ZO_UtilityWheel_Gamepad = ZO_UtilityWheel_Shared:Subclass()

local USE_LEADING_EDGE = true
local COOLDOWN_DESATURATION = 1
local COOLDOWN_ALPHA = 1
local DONT_PRESERVE_PREVIOUS_COOLDOWN = false

function ZO_UtilityWheel_Gamepad:Initialize(...)
    ZO_UtilityWheel_Shared.Initialize(self, ...)
    ZO_Keybindings_RegisterLabelForBindingUpdate(self.cycleLeftKeybindLabel, "UTILITY_WHEEL_GAMEPAD_CYCLE_LEFT")
    ZO_Keybindings_RegisterLabelForBindingUpdate(self.cycleRightKeybindLabel, "UTILITY_WHEEL_GAMEPAD_CYCLE_RIGHT")
end

function ZO_UtilityWheel_Gamepad:SetupEntryControl(entryControl, data)
    ZO_UtilityWheel_Shared.SetupEntryControl(self, entryControl, data)
    ZO_GamepadUtilityWheelCooldownSetup(entryControl, data.slotNum, self:GetHotbarCategory())
end

function ZO_GamepadUtilityWheelCooldownSetup(control, slotNum, hotbarCategory)
    local remaining, duration = GetSlotCooldownInfo(slotNum, hotbarCategory)
    control.cooldown:SetVerticalCooldownLeadingEdgeHeight(4)
    control.cooldown:SetTexture(GetSlotTexture(slotNum, hotbarCategory))
    control.cooldown:SetFillColor(ZO_SELECTED_TEXT:UnpackRGBA())
    ZO_SharedGamepadEntry_Cooldown(control, remaining, duration, CD_TYPE_VERTICAL_REVEAL, CD_TIME_TYPE_TIME_UNTIL, USE_LEADING_EDGE, COOLDOWN_DESATURATION, COOLDOWN_ALPHA, DONT_PRESERVE_PREVIOUS_COOLDOWN)
end

function ZO_UtilityWheel_Gamepad_Initialize(control)
    local actionLayers = { "RadialMenu", GetString(SI_KEYBINDINGS_LAYER_UTILITY_WHEEL) }
    UTILITY_WHEEL_GAMEPAD = ZO_UtilityWheel_Gamepad:New(control, "ZO_UtilityWheelMenuEntryTemplate_Gamepad", "DefaultRadialMenuAnimation", "SelectableItemRadialMenuEntryAnimation", actionLayers)
end