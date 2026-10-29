local LoadingScreen_Gamepad = {}

local function IsScreenNarrationEnabled()
    return GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_SCREEN_NARRATION)
end

function LoadingScreen_Gamepad:InitializeAnimations()
    local topMunge = self:GetNamedChild("TopMunge")
    local bottomMunge = self:GetNamedChild("BottomMunge")
    local zoneInfoContainer = self:GetNamedChild("ZoneInfoContainer")

    self.spinnerFadeAnimation = GetAnimationManager():CreateTimelineFromVirtual("SpinnerFadeAnimation", self.spinner)

    self.animations = GetAnimationManager():CreateTimelineFromVirtual("GamepadLoadingCompleteAnimation")
    self.animations:GetAnimation(1):SetAnimatedControl(self.art)
    self.animations:GetAnimation(2):SetAnimatedControl(topMunge)
    self.animations:GetAnimation(3):SetAnimatedControl(bottomMunge)
    self.animations:GetAnimation(4):SetAnimatedControl(zoneInfoContainer)
    self.animations:GetAnimation(5):SetAnimatedControl(self.zoneDescription)
    self.animations:GetAnimation(6):SetAnimatedControl(self.descriptionBg)
    self.animations:GetAnimation(7):SetAnimatedControl(self.difficultyLabel)
    self.animations.control = self
    self.animations:SetHandler("OnStop", function(timeline) self:LoadingCompleteAnimation_OnStop(timeline) end)

    self.longLoadAnimation = GetAnimationManager():CreateTimelineFromVirtual("LongLoadingAnimation")
    local longLoadMessage = topMunge:GetNamedChild("LongLoadMessage")
    self.longLoadAnimation:GetAnimation(1):SetAnimatedControl(longLoadMessage)
    self.longLoadAnimation:GetAnimation(2):SetAnimatedControl(longLoadMessage)
    self.longLoadAnimation.control = longLoadMessage

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
        if IsScreenNarrationEnabled() then
            --Add the narration for the long load text
            AddPendingNarrationText(GetString(SI_LONG_LOAD_TIME))
            RequestReadPendingNarrationTextToClient(NARRATION_TYPE_UI_SCREEN)
        end
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
    self.longLoadAnimation.control:SetAlpha(0)
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