ZO_TargetMarkerWheel_Gamepad = ZO_TargetMarkerWheel_Shared:Subclass()

function ZO_TargetMarkerWheel_Gamepad_Initialize(control)
    TARGET_MARKER_WHEEL_GAMEPAD = ZO_TargetMarkerWheel_Gamepad:New(control, "ZO_TargetMarkerWheelMenuEntryTemplate_Gamepad", "DefaultRadialMenuAnimation", "SelectableItemRadialMenuEntryAnimation")
end