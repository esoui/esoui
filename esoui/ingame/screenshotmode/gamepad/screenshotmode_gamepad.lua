ZO_ScreenshotMode_Gamepad = ZO_Object:Subclass()

local HIDE_DURATION_S = 3
local FADE_DURATION_S = 1.5

function ZO_ScreenshotMode_Gamepad:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_ScreenshotMode_Gamepad:Initialize(control)
    self.control = control

    self.exitButton = control:GetNamedChild("ExitButton")
    ApplyTemplateToControl(self.exitButton, "ZO_KeybindButton_Gamepad_Template")
    self.exitButton:SetText(GetString(SI_DIALOG_EXIT))
    self.exitButton:SetKeybind("SCREENSHOT_MODE_EXIT")

    GAMEPAD_SCREENSHOT_MODE_SCENE = ZO_Scene:New("gamepadScreenshotMode", SCENE_MANAGER)
    GAMEPAD_SCREENSHOT_MODE_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self.hideKeybindsAtS = GetGameTimeSeconds() + HIDE_DURATION_S
        elseif newState == SCENE_HIDDEN then
            SetGuiHidden("ingame", false)
            self.control:SetAlpha(1)
        end
    end)

    control:SetHandler("OnUpdate", function(_, timeS)
        if self.hideKeybindsAtS then
            if timeS >= self.hideKeybindsAtS then
                self.hideKeybindsAtS = nil
                SetGuiHidden("ingame", true)
            else
                local timeUntilHideS = self.hideKeybindsAtS - timeS
                if timeUntilHideS < FADE_DURATION_S then
                    self.control:SetAlpha(timeUntilHideS / FADE_DURATION_S)
                end
            end
        end
    end)

    self.fragment = ZO_SimpleSceneFragment:New(control)
    GAMEPAD_SCREENSHOT_MODE_SCENE:AddFragment(self.fragment)
end

function ZO_ScreenshotMode_Gamepad:Show()
    if SCENE_MANAGER:SetInUIMode(false) then
        SCENE_MANAGER:SetHUDScene("gamepadScreenshotMode")
    end
end

function ZO_ScreenshotMode_Gamepad:ExitKeybind()
    if not self.hideKeybindsAtS then
        SetGuiHidden("ingame", false)
        self.hideKeybindsAtS = GetGameTimeSeconds() + HIDE_DURATION_S
        self.control:SetAlpha(1)
    else
        SCENE_MANAGER:RestoreHUDScene()
    end
end

function ZO_ScreenshotMode_Gamepad:ShowUIKeybind()
    if not self.hideKeybindsAtS then
        SetGuiHidden("ingame", false)
    end
    self.hideKeybindsAtS = GetGameTimeSeconds() + HIDE_DURATION_S
    self.control:SetAlpha(1)
end

function ZO_ScreenshotMode_GamepadTopLevel_OnInitialized(self)
    SCREENSHOT_MODE_GAMEPAD = ZO_ScreenshotMode_Gamepad:New(self)
end