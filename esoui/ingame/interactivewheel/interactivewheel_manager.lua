ZO_INTERACTIVE_WHEEL_TYPE_UTILITY = 1
ZO_INTERACTIVE_WHEEL_TYPE_FISHING = 2
ZO_INTERACTIVE_WHEEL_TYPE_TARGET_MARKER = 3

--Interactive Wheel Manager
ZO_InteractiveWheel_Manager = ZO_InitializingObject:Subclass()

function ZO_InteractiveWheel_Manager:Initialize()
    EVENT_MANAGER:RegisterForEvent("InteractiveWheelManager", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function()
        self:CancelCurrentInteraction()
    end)

    EVENT_MANAGER:RegisterForEvent("InteractiveWheelManager", EVENT_GUI_UNLOADING, function()
        self:CancelCurrentInteraction()
    end)

    self.beginHotkeyHolds = {}
end

function ZO_InteractiveWheel_Manager:GetPreferredWheel(interactiveWheelType)
    if interactiveWheelType == ZO_INTERACTIVE_WHEEL_TYPE_UTILITY then
        return self.gamepad and UTILITY_WHEEL_GAMEPAD or UTILITY_WHEEL_KEYBOARD
    elseif interactiveWheelType == ZO_INTERACTIVE_WHEEL_TYPE_FISHING then
        return self.gamepad and FISHING_GAMEPAD or FISHING_KEYBOARD
    elseif interactiveWheelType == ZO_INTERACTIVE_WHEEL_TYPE_TARGET_MARKER then
        return self.gamepad and TARGET_MARKER_WHEEL_GAMEPAD or TARGET_MARKER_WHEEL_KEYBOARD
    else
        internalassert(false, "Invalid interactive wheel type")
    end
end

function ZO_InteractiveWheel_Manager:StartInteraction(interactiveWheelType)
    --Order matters, set this first
    self.gamepad = IsInGamepadPreferredMode()

    local wheel = self:GetPreferredWheel(interactiveWheelType)
    local interactionStarted = wheel:StartInteraction()
    if interactionStarted then
        --If we're starting a new interaction, stop any interactions already happening
        if self.currentWheelType then
            local CLEAR_SELECTION = true
            self:StopInteraction(self.currentWheelType, CLEAR_SELECTION)
        end
        self.currentWheelType = interactiveWheelType
    end

    return interactionStarted
end

function ZO_InteractiveWheel_Manager:StopInteraction(interactiveWheelType, clearSelection)
    self.currentWheelType = nil
    ZO_ClearTable(self.beginHotkeyHolds)
    local wheel = self:GetPreferredWheel(interactiveWheelType)
    return wheel:StopInteraction(clearSelection)
end

function ZO_InteractiveWheel_Manager:HandleUpAction(interactiveWheelType)
    --Treat the up action differently for togglable wheels
    if ZO_AreTogglableWheelsEnabled() then
        --Cancel the interaction if we get here before the wheel is done coming up
        if self.currentWheelType == interactiveWheelType and not self:IsInteracting(interactiveWheelType) then
            return self:StopInteraction(interactiveWheelType)
        end

        --If the wheel is already up, we do not want to close it by releasing the hold, so just do nothing and treat the bind as handled
        return true
    else
        return self:StopInteraction(interactiveWheelType)
    end
end

--Cancels the current interaction if there is one
function ZO_InteractiveWheel_Manager:CancelCurrentInteraction()
    if self.currentWheelType then
        --Since we're cancelling, we don't want to retain our selection
        local CLEAR_SELECTION = true
        return self:StopInteraction(self.currentWheelType, CLEAR_SELECTION)
    else
        return false
    end
end

function ZO_InteractiveWheel_Manager:HandleHotkeyDownAction(ordinalIndex)
    if self.currentWheelType then
        local wheel = self:GetPreferredWheel(self.currentWheelType)
        if wheel:SelectOrdinalIndex(ordinalIndex) then
            self.beginHotkeyHolds[ordinalIndex] = GetFrameTimeMilliseconds()
            return true
        end
    end

    return false
end

do
    local TIME_TO_HOLD_KEY_MS = 250
    function ZO_InteractiveWheel_Manager:HandleHotkeyUpAction(ordinalIndex)
        local beginHold = self.beginHotkeyHolds[ordinalIndex]
        if beginHold then
            self.beginHotkeyHolds[ordinalIndex] = nil
            --If we were not holding the hotkey long enough to leave the wheel open, we need to close it
            if GetFrameTimeMilliseconds() < beginHold + TIME_TO_HOLD_KEY_MS then
                local wheel = self:GetPreferredWheel(self.currentWheelType)
                --Re-select the correct ordinal entry here in case it happened to change after we initially pressed the keybind
                if wheel:SelectOrdinalIndex(ordinalIndex) then
                    return self:StopInteraction(self.currentWheelType)
                end
            end
        end

        return false
    end
end

function ZO_InteractiveWheel_Manager:IsInteracting(interactiveWheelType)
    --If self.gamepad has never been set, it is impossible for us to be interacting
    if self.gamepad == nil then
        return false
    end

    if interactiveWheelType then
        local wheel = self:GetPreferredWheel(interactiveWheelType)
        return wheel:IsInteracting()
    elseif self.currentWheelType then
        --If no interactive wheel type was specified just use whatever the current wheel type is
        local wheel = self:GetPreferredWheel(self.currentWheelType)
        return wheel:IsInteracting()
    else
        return false
    end
end

--Currently only supports ZO_INTERACTIVE_WHEEL_TYPE_UTILITY
function ZO_InteractiveWheel_Manager:CycleLeft(interactiveWheelType)
    --Only allow cycling if the wheel in question is already visible
    if interactiveWheelType == self.currentWheelType then
        local wheel = self:GetPreferredWheel(interactiveWheelType)
        return wheel:CycleLeft()
    end

    return false
end

--Currently only supports ZO_INTERACTIVE_WHEEL_TYPE_UTILITY
function ZO_InteractiveWheel_Manager:CycleRight(interactiveWheelType)
    --Only allow cycling if the wheel in question is already visible
    if interactiveWheelType == self.currentWheelType then
        local wheel = self:GetPreferredWheel(interactiveWheelType)
        return wheel:CycleRight()
    end

    return false
end

INTERACTIVE_WHEEL_MANAGER = ZO_InteractiveWheel_Manager:New()