local LoadingScreen_Gamepad = {}

local function IsScreenNarrationEnabled()
    return GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_SCREEN_NARRATION)
end

function LoadingScreen_Gamepad:InitializeAnimations()
    self.spinnerFadeAnimation = GetAnimationManager():CreateTimelineFromVirtual("SpinnerFadeAnimation", GamepadLoadingScreenSpinner)

    self.animations = GetAnimationManager():CreateTimelineFromVirtual("GamepadLoadingCompleteAnimation")
    self.animations:GetAnimation(1):SetAnimatedControl(GamepadLoadingScreenArt)
    self.animations:GetAnimation(2):SetAnimatedControl(GamepadLoadingScreenTopMunge)
    self.animations:GetAnimation(3):SetAnimatedControl(GamepadLoadingScreenBottomMunge)
    self.animations:GetAnimation(4):SetAnimatedControl(GamepadLoadingScreenBottomMungeZoneInfoContainer)
    self.animations:GetAnimation(5):SetAnimatedControl(GamepadLoadingScreenZoneDescription)
    self.animations:GetAnimation(6):SetAnimatedControl(GamepadLoadingScreenDescriptionBg)
    self.animations.control = self
    self.animations:SetHandler("OnStop", function(timeline) self:LoadingCompleteAnimation_OnStop(timeline) end)

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
    if not self:IsHidden() then
        self.longLoadAnimation:PlayFromStart()
    end
end

function LoadingScreen_Gamepad:OnShown()
    self.longLoadAnimation:Stop()
    if IsScreenNarrationEnabled() and self.isNarrationDirty then
        --First, clear out any in progress narration
        ClearAllNarrationQueues()

        --Add the narration for the loading text
        AddPendingNarrationText(GetString(SI_SCREEN_NARRATION_LOADING_NARRATION))

        --If there is a zone name visible, narrate it
        if not self.zoneName:IsHidden() then
            if self.zoneNameText and self.zoneNameText ~= "" then
                AddPendingNarrationText(self.zoneNameText)
            end
        end

        --If there is an instance type visible, narrate it
        if not self.instanceType:IsHidden() then
            if self.instanceTypeText and self.instanceTypeText ~= "" then
                AddPendingNarrationText(self.instanceTypeText)
            end
        end

        --If there is a zone description visible, narrate it
        if not self.zoneDescription:IsHidden() then
            if self.zoneDescriptionText and self.zoneDescriptionText ~= "" then
                AddPendingNarrationText(self.zoneDescriptionText)
            end
        end

        RequestReadPendingNarrationTextToClient(NARRATION_TYPE_UI_SCREEN)
    end
    self.isNarrationDirty = false
    GamepadLoadingScreenTopMungeLongLoadMessage:SetAlpha(0)
end

function LoadingScreen_Gamepad:OnHidden()
    self.longLoadAnimation:Stop()
    CheckForControllerDisconnect()
    if not self.dontClearNarration then
        --Clear out any in progress narration from the loading screen when we finish
        ClearNarrationQueue(NARRATION_TYPE_UI_SCREEN)
    end

    if IsConsoleUI() then
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