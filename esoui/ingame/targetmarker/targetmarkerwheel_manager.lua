--Target Marker Wheel Manager
ZO_TargetMarkerWheel_Manager = ZO_InitializingObject:Subclass()

function ZO_TargetMarkerWheel_Manager:Initialize()
    EVENT_MANAGER:RegisterForEvent("TargetMarkerWheelManager", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function()
        local CLEAR_SELECTION = true
        self:StopInteraction(CLEAR_SELECTION)
    end)
end

function ZO_TargetMarkerWheel_Manager:StartInteraction()
    self.gamepad = IsInGamepadPreferredMode()
    if self.gamepad then
        return TARGET_MARKER_WHEEL_GAMEPAD:StartInteraction()
    else
        return TARGET_MARKER_WHEEL_KEYBOARD:StartInteraction()
    end
end

function ZO_TargetMarkerWheel_Manager:StopInteraction(clearSelection)
    if self.gamepad then
        return TARGET_MARKER_WHEEL_GAMEPAD:StopInteraction(clearSelection)
    else
        return TARGET_MARKER_WHEEL_KEYBOARD:StopInteraction(clearSelection)
    end
end

function ZO_TargetMarkerWheel_Manager:IsInteracting()
    --If self.gamepad has never been set, it is impossible for us to be interacting
    if self.gamepad == nil then
        return false
    end

    if self.gamepad then
        return TARGET_MARKER_WHEEL_GAMEPAD:IsInteracting()
    else
        return TARGET_MARKER_WHEEL_KEYBOARD:IsInteracting()
    end
end

TARGET_MARKERS = ZO_TargetMarkerWheel_Manager:New()