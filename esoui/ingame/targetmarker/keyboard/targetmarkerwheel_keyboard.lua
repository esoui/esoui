ZO_TargetMarkerWheel_Keyboard = ZO_TargetMarkerWheel_Shared:Subclass()

function ZO_TargetMarkerWheel_Keyboard_Initialize(control)
    TARGET_MARKER_WHEEL_KEYBOARD = ZO_TargetMarkerWheel_Keyboard:New(control, "ZO_TargetMarkerWheelMenuEntryTemplate_Keyboard", "DefaultRadialMenuAnimation", "SelectableItemRadialMenuEntryAnimation")
end