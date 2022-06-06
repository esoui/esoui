local Help_Manager = ZO_InitializingCallbackObject:Subclass()

function Help_Manager:Initialize()
    self.isHelpOverlayVisible = false

    EVENT_MANAGER:RegisterForEvent("Help_Manager", EVENT_HELP_OVERLAY_VISIBILITY_CHANGED, function(_, isVisible)
        if self.isHelpOverlayVisible ~= isVisible then
            self.isHelpOverlayVisible = isVisible
            self:FireCallbacks("OverlayVisibilityChanged", isVisible)
        end
    end)
end

function Help_Manager:IsHelpOverlayVisible()
    return self.isHelpOverlayVisible
end

HELP_MANAGER = Help_Manager:New()