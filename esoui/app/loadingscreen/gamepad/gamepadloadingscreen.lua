local LoadingScreen_Gamepad = {}

function LoadingScreen_Gamepad:InitializeAnimations()
    self.spinnerFadeAnimation = GetAnimationManager():CreateTimelineFromVirtual("SpinnerFadeAnimation")
    self.spinnerFadeAnimation:GetAnimation(1):SetAnimatedControl(GamepadLoadingScreenBg)
    self.spinnerFadeAnimation:GetAnimation(2):SetAnimatedControl(GamepadLoadingScreenSpinner)

    self.animations = GetAnimationManager():CreateTimelineFromVirtual("GamepadLoadingCompleteAnimation")
    self.animations:GetAnimation(1):SetAnimatedControl(GamepadLoadingScreenArt)
    self.animations:GetAnimation(2):SetAnimatedControl(GamepadLoadingScreenTopMunge)
    self.animations:GetAnimation(3):SetAnimatedControl(GamepadLoadingScreenBottomMunge)
    self.animations:GetAnimation(4):SetAnimatedControl(GamepadLoadingScreenBottomMungeZoneInfoContainer)
    self.animations:GetAnimation(5):SetAnimatedControl(GamepadLoadingScreenZoneDescription)
    self.animations:GetAnimation(6):SetAnimatedControl(GamepadLoadingScreenDescriptionBg)
    self.animations.control = self

    self.longLoadAnimation = GetAnimationManager():CreateTimelineFromVirtual("LongLoadingAnimation")
    self.longLoadAnimation:GetAnimation(1):SetAnimatedControl(GamepadLoadingScreenTopMungeLongLoadMessage)
    self.longLoadAnimation:GetAnimation(2):SetAnimatedControl(GamepadLoadingScreenTopMungeLongLoadMessage)
    self.longLoadAnimation.control = GamepadLoadingScreenTopMungeLongLoadMessage

    local function OnLongLoadAnimationStop(timeline, completed)
        timeline.control:SetAlpha(0)
    end

    self.longLoadAnimation:SetHandler("OnStop", OnLongLoadAnimationStop)
end

function LoadingScreen_Gamepad:GetSystemName()
    return "GamepadLoadingScreen"
end

function LoadingScreen_Gamepad:OnLongLoadTime(event)
    if(not self:IsHidden()) then
        self.longLoadAnimation:PlayFromStart()
    end
end

function LoadingScreen_Gamepad:OnShown()
    self.longLoadAnimation:Stop()
    GamepadLoadingScreenTopMungeLongLoadMessage:SetAlpha(0)
end

function LoadingScreen_Gamepad:OnHidden()
    self.longLoadAnimation:Stop()
    CheckForControllerDisconnect()

    local platform = GetUIPlatform()
    if platform == UI_PLATFORM_PS4 or platform == UI_PLATFORM_XBOX then
        StopLongLoadTimer()
    end
end

function LoadingScreen_Gamepad:IsPreferredScreen()
    return IsInGamepadPreferredMode()
end

function ZO_InitGamepadLoadScreen(control)
    zo_mixin(control, LoadingScreen_Base, LoadingScreen_Gamepad)
    control:Initialize()

    EVENT_MANAGER:RegisterForEvent("LoadingScreen", EVENT_LOAD_RUNNING_LONG, function(...) control:OnLongLoadTime(...) end)
    control:SetHandler("OnShow", function(...) control:OnShown() end);
    control:SetHandler("OnHide", function(...) control:OnHidden() end);
end