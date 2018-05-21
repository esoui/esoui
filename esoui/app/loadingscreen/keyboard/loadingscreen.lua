local LoadingScreen_Keyboard = {}

function LoadingScreen_Keyboard:InitializeAnimations()
    self.spinnerFadeAnimation = GetAnimationManager():CreateTimelineFromVirtual("SpinnerFadeAnimation", LoadingScreenSpinner)

    self.animations = GetAnimationManager():CreateTimelineFromVirtual("LoadingCompleteAnimation")
    self.animations:GetAnimation(1):SetAnimatedControl(LoadingScreenArt)
    self.animations:GetAnimation(2):SetAnimatedControl(LoadingScreenTopMunge)
    self.animations:GetAnimation(3):SetAnimatedControl(LoadingScreenTopMunge)
    self.animations:GetAnimation(4):SetAnimatedControl(LoadingScreenBottomMunge)
    self.animations:GetAnimation(5):SetAnimatedControl(LoadingScreenBottomMunge)
    self.animations.control = self
    self.animations:SetHandler("OnStop", function(timeline) self:LoadingCompleteAnimation_OnStop(timeline) end)
end

function LoadingScreen_Keyboard:IsPreferredScreen()
    return not IsInGamepadPreferredMode()
end

function LoadingScreen_Keyboard:GetSystemName()
    return "LoadingScreen"
end

function ZO_InitKeyboardLoadScreen(control)
    zo_mixin(control, LoadingScreen_Base, LoadingScreen_Keyboard)
    control:Initialize(control)
end