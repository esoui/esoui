ZO_ForceConsoleWarning = ZO_InitializingObject:Subclass()

function ZO_ForceConsoleWarning:Initialize(control)
    self.control = control

    FORCE_CONSOLE_WARNING_FRAGMENT = ZO_HUDFadeSceneFragment:New(control)
end

function ZO_ForceConsoleWarning.OnControlInitialized(control)
    FORCE_CONSOLE_WARNING = ZO_ForceConsoleWarning:New(control)
end