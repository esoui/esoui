local DownloadBar_Gamepad = ZO_InitializingObject:Subclass()

function DownloadBar_Gamepad:Initialize(control)
    self.control = control

    self.bar = control:GetNamedChild("BarContainer")
    self.label = control:GetNamedChild("PercentLabel")

    self.sceneFragment = ZO_FadeSceneFragment:New(control)
    GAMEPAD_DOWNLOAD_BAR_FRAGMENT = self.sceneFragment
end

function DownloadBar_Gamepad:Update()
    local TOTAL_DOWNLOAD_PERCENTAGE = 100
    local downloadPercentage = zo_clamp(GetInstallationProgress(), 0, TOTAL_DOWNLOAD_PERCENTAGE)
    ZO_StatusBar_SmoothTransition(self.bar, downloadPercentage, TOTAL_DOWNLOAD_PERCENTAGE)
    self.label:SetText(ZO_FastFormatDecimalNumber(string.format("%.2f%%", downloadPercentage)))
end

function DownloadBar_Gamepad_Initialize(self)
    GAMEPAD_DOWNLOAD_BAR = DownloadBar_Gamepad:New(self)
end