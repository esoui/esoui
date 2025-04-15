ZO_Gamepad_ParametricList_Header = ZO_InitializingCallbackObject:Subclass()

ZO_Gamepad_ParametricList_Header:MUST_IMPLEMENT("GetNarrationText")

function ZO_Gamepad_ParametricList_Header:Initialize(control)
    self.control = control

    self.headerHighlight = self.control:GetNamedChild("Highlight")

    self.active = false
    self.enabled = true
end

function ZO_Gamepad_ParametricList_Header:SetCustomNarrationKey(key)
    self.customNarrationKey = key
end

function ZO_Gamepad_ParametricList_Header:RegisterNarrationInfo(narrationInfo)
    SCREEN_NARRATION_MANAGER:RegisterCustomObject(self.customNarrationKey, narrationInfo)
end

function ZO_Gamepad_ParametricList_Header:IsActive()
    return self.active
end

function ZO_Gamepad_ParametricList_Header:Activate()
    self.active = true
    self:Update()
    SCREEN_NARRATION_MANAGER:QueueCustomEntry(self.customNarrationKey)
    self:FireCallbacks("FocusActivated")
end

function ZO_Gamepad_ParametricList_Header:Deactivate()
    self.active = false
    self:Update()
    self:FireCallbacks("FocusDeactivated")
end

function ZO_Gamepad_ParametricList_Header:Update()
    self.headerHighlight:SetHidden(not self.active)
end

function ZO_Gamepad_ParametricList_Header:IsActive()
    return self.active
end