local ZO_QuickslotRadialManager_Gamepad = ZO_QuickslotRadialManager:Subclass()

local USE_LEADING_EDGE = true
local COOLDOWN_DESATURATION = 1
local COOLDOWN_ALPHA = 1
local DONT_PRESERVE_PREVIOUS_COOLDOWN = false

function ZO_GamepadQuickslotCooldownSetup(control, slotNum)
    local remaining, duration = GetSlotCooldownInfo(slotNum)
    control.cooldown:SetVerticalCooldownLeadingEdgeHeight(4)
    control.cooldown:SetTexture(GetSlotTexture(slotNum))
    control.cooldown:SetFillColor(ZO_SELECTED_TEXT:UnpackRGBA())
    ZO_SharedGamepadEntry_Cooldown(control, remaining, duration, CD_TYPE_VERTICAL_REVEAL, CD_TIME_TYPE_TIME_UNTIL, USE_LEADING_EDGE, COOLDOWN_DESATURATION, COOLDOWN_ALPHA, DONT_PRESERVE_PREVIOUS_COOLDOWN)
end

function ZO_QuickslotRadialManager_Gamepad:SetupEntryControl(entryControl, slotNum)
    ZO_QuickslotRadialManager.SetupEntryControl(self, entryControl, slotNum)

    ZO_GamepadQuickslotCooldownSetup(entryControl, slotNum)
end

function ZO_QuickslotRadial_Gamepad_Initialize(control)
    QUICKSLOT_RADIAL_GAMEPAD = ZO_QuickslotRadialManager_Gamepad:New(control, "ZO_GamepadSelectableItemRadialMenuEntryTemplate", "DefaultRadialMenuAnimation", "SelectableItemRadialMenuEntryAnimation")
end