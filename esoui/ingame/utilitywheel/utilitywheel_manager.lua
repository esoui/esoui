--Utility Wheel Manager
ZO_UtilityWheel_Manager = ZO_InitializingObject:Subclass()

function ZO_UtilityWheel_Manager:Initialize()
    EVENT_MANAGER:RegisterForEvent("UtilityWheelManager", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function()
        local CLEAR_SELECTION = true
        self:StopInteraction(CLEAR_SELECTION) 
    end)
end

function ZO_UtilityWheel_Manager:StartInteraction()
    self.gamepad = IsInGamepadPreferredMode()
    if self.gamepad then
        return UTILITY_WHEEL_GAMEPAD:StartInteraction()
    else
        return UTILITY_WHEEL_KEYBOARD:StartInteraction()
    end
end

function ZO_UtilityWheel_Manager:StopInteraction(clearSelection)
    if self.gamepad then
        return UTILITY_WHEEL_GAMEPAD:StopInteraction(clearSelection)
    else
        return UTILITY_WHEEL_KEYBOARD:StopInteraction(clearSelection)
    end
end

function ZO_UtilityWheel_Manager:IsInteracting()
    --If self.gamepad has never been set, it is impossible for us to be interacting
    if self.gamepad == nil then
        return false
    end

    if self.gamepad then
        return UTILITY_WHEEL_GAMEPAD:IsInteracting()
    else
        return UTILITY_WHEEL_KEYBOARD:IsInteracting()
    end
end

function ZO_UtilityWheel_Manager:CycleLeft()
    if self.gamepad then
        return UTILITY_WHEEL_GAMEPAD:CycleLeft()
    else
        return UTILITY_WHEEL_KEYBOARD:CycleLeft()
    end
end

function ZO_UtilityWheel_Manager:CycleRight()
    if self.gamepad then
        return UTILITY_WHEEL_GAMEPAD:CycleRight()
    else
        return UTILITY_WHEEL_KEYBOARD:CycleRight()
    end
end

UTILITY_WHEEL_MANAGER = ZO_UtilityWheel_Manager:New()