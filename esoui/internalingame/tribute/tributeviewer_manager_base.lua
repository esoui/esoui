-------------------------------
-- Tribute Viewer Manager Base
-------------------------------

ZO_TributeViewer_Manager_Base = ZO_InitializingCallbackObject:Subclass()

function ZO_TributeViewer_Manager_Base:Initialize()
    self:RegisterForEvents(self:GetSystemName())
end

function ZO_TributeViewer_Manager_Base:RegisterForEvents(systemName)
    EVENT_MANAGER:RegisterForEvent(systemName, EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() self:OnGamepadPreferredModeChanged() end)
end

function ZO_TributeViewer_Manager_Base:FireActivationStateChanged()
    self:FireCallbacks("ActivationStateChanged", self, self:IsActive())
end

--Functions that must be implemented by a child class
ZO_TributeViewer_Manager_Base.GetSystemName = ZO_TributeViewer_Manager_Base:MUST_IMPLEMENT()
ZO_TributeViewer_Manager_Base.OnGamepadPreferredModeChanged = ZO_TributeViewer_Manager_Base:MUST_IMPLEMENT()
ZO_TributeViewer_Manager_Base.IsViewingBoard = ZO_TributeViewer_Manager_Base:MUST_IMPLEMENT()
ZO_TributeViewer_Manager_Base.IsActive = ZO_TributeViewer_Manager_Base:MUST_IMPLEMENT()
ZO_TributeViewer_Manager_Base.IsKeybindStripVisible = ZO_TributeViewer_Manager_Base:MUST_IMPLEMENT()
ZO_TributeViewer_Manager_Base.RequestClose = ZO_TributeViewer_Manager_Base:MUST_IMPLEMENT()