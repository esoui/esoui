local TOTAL_DOWNLOAD_PERCENT = 100

local SCENE_TABLE =
{
    GAME_STARTUP_MAIN_GAMEPAD_SCENE,
}


local DownloadBar_Gamepad = ZO_CallbackObject:Subclass()

function DownloadBar_Gamepad:New(control)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(control)
    return object
end

function DownloadBar_Gamepad:Initialize(control)
    self.control = control

    self.bar = control:GetNamedChild("BarContainer")
    self.label = control:GetNamedChild("PercentLabel")
    self:UpdateDownloadPercent(0)
    GAMEPAD_DOWNLOAD_BAR_FRAGMENT = ZO_FadeSceneFragment:New(ZO_DownloadBar_Gamepad)

    -- Now determine if this needs to be shown
    if(IsGateInstalled("BaseGame")) then
        self.completed = true
    else
        self.completed = false
        for i,scene in ipairs(SCENE_TABLE) do
            scene:AddFragment(GAMEPAD_DOWNLOAD_BAR_FRAGMENT)
        end
    end
end

function DownloadBar_Gamepad:Update()
    if(not self.completed) then
        local progress = GetInstallationProgress()
        if(progress) then
            self:UpdateDownloadPercent(progress)
        end
    end
end

function DownloadBar_Gamepad:UpdateDownloadPercent(downloadPercent)
    if(downloadPercent >= TOTAL_DOWNLOAD_PERCENT and IsGateInstalled("BaseGame")) then
        self.completed = true
        for i,scene in ipairs(SCENE_TABLE) do
            scene:RemoveFragment(GAMEPAD_DOWNLOAD_BAR_FRAGMENT)
        end
        self:FireCallbacks("DownloadComplete")
    else
        self.currentDownload = downloadPercent
        ZO_StatusBar_SmoothTransition(self.bar, downloadPercent, TOTAL_DOWNLOAD_PERCENT)
        self.label:SetText(downloadPercent .."%")
    end
end

function DownloadBar_Gamepad_Initialize(self)
    GAMEPAD_DOWNLOAD_BAR = DownloadBar_Gamepad:New(self)
end

function DownloadBar_Gamepad_Update(self)
    GAMEPAD_DOWNLOAD_BAR:Update()    
end