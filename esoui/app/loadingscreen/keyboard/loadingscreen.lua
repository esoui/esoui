local LoadingScreen_Keyboard = {}

function LoadingScreen_Keyboard:InitializeAnimations()
    local topMunge = self:GetNamedChild("TopMunge")
    local bottomMunge = self:GetNamedChild("BottomMunge")

    self.spinnerFadeAnimation = GetAnimationManager():CreateTimelineFromVirtual("SpinnerFadeAnimation", self.spinner)
    self.animations = GetAnimationManager():CreateTimelineFromVirtual("LoadingCompleteAnimation")
    self.animations:GetAnimation(1):SetAnimatedControl(self.art)
    self.animations:GetAnimation(2):SetAnimatedControl(topMunge)
    self.animations:GetAnimation(3):SetAnimatedControl(topMunge)
    self.animations:GetAnimation(4):SetAnimatedControl(bottomMunge)
    self.animations:GetAnimation(5):SetAnimatedControl(bottomMunge)
    self.animations:GetAnimation(6):SetAnimatedControl(self.difficultyLabel)
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