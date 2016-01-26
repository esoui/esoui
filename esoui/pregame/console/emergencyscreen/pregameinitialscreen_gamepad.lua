local PregameInitialScreen_Console = ZO_Object:Subclass()

local ESO_FADE_IN = "eso_fade_in"
local ESO_FADE_OUT = "eso_fade_out"
local ESO_SHOW_TIME = 1500 --ms
local ESO_DELAY_TIME = 1000 --ms
local OUROBOROS_FADE_IN = "ouroboros_fade_in"
local OUROBOROS_WAIT_FOR_BUTTON = "ouroboros_wait_for_button"
local OUROBOROS_FADING_OUT = "ouroboros_fading_out"

local STARTUP_BUTTONS = 
{
    "UI_SHORTCUT_PRIMARY",
    "UI_SHORTCUT_SECONDARY",
    "UI_SHORTCUT_TERTIARY",
    "UI_SHORTCUT_NEGATIVE",
    "UI_SHORTCUT_RIGHT_SHOULDER",
    "UI_SHORTCUT_LEFT_SHOULDER",
    "UI_SHORTCUT_RIGHT_TRIGGER",
    "UI_SHORTCUT_LEFT_TRIGGER",
    "UI_SHORTCUT_RIGHT_STICK",
    "UI_SHORTCUT_LEFT_STICK",
    "UI_SHORTCUT_START",
    "UI_SHORTCUT_BACK",
}

local VERIFICATION_STATE =
{
    NONE = 1,
    OFFER = 2,
}

function PregameInitialScreen_Console:New(control)
    local object = ZO_Object.New(self)
    object:Initialize(control)
    return object
end

function PregameInitialScreen_Console:Initialize(control)
    self.control = control
    self.playAnimations = true
    self.verificationState = VERIFICATION_STATE.NONE

    local pregameInitialScreen_Console_Fragment = ZO_FadeSceneFragment:New(control)
    PREGAME_INITIAL_SCREEN_CONSOLE_SCENE = ZO_Scene:New("PregameInitialScreen_Gamepad", SCENE_MANAGER)
    PREGAME_INITIAL_SCREEN_CONSOLE_SCENE:AddFragment(pregameInitialScreen_Console_Fragment)

    PREGAME_INITIAL_SCREEN_CONSOLE_SCENE:RegisterCallback("StateChange", function(oldState, newState)
                        if newState == SCENE_SHOWING then
                            ZO_ControllerDisconnect_DismissPopup()
                            self:PerformDeferredInitialization()
                            KEYBIND_STRIP:RemoveDefaultExit()
                            self.currentKeybindStripDescriptor = self:IsShowingVerificationError() and self.verifyEmailKeybindsDescriptor or self.pressAnyKeybindsDescriptor
                            KEYBIND_STRIP:AddKeybindButtonGroup(self.currentKeybindStripDescriptor)
                        elseif newState == SCENE_SHOWN then
                            DisableShareFeatures()
                            if self.playAnimations then
                                self.fadeMode = ESO_FADE_IN
                                zo_callLater(function() self.esoLogoAnimation:PlayFromStart() end, ESO_DELAY_TIME)
                                self.playAnimations = false
                            else
                                self.fadeMode = OUROBOROS_FADE_IN
                                self.ouroborosAnimation:PlayInstantlyToEnd()
                            end

                            if(IsErrorQueuedFromIngame()) then
                                ZO_Gamepad_DisplayServerDisconnectedError()
                            end

                        elseif newState == SCENE_HIDDEN then
                            self:ClearError()
                            PregameStateManager_ClearError()
                            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentKeybindStripDescriptor)
                            KEYBIND_STRIP:RestoreDefaultExit()
                        end
                    end)
end

function PregameInitialScreen_Console:PerformDeferredInitialization()
    if self.initialized then return end
    self.initialized = true

    self.errorBox = self.control:GetNamedChild("ErrorBox")
    self.errorBoxContainer = self.errorBox:GetNamedChild("Container")
    self.errorTitle = self.errorBoxContainer:GetNamedChild("ErrorTitle")
    self.errorMessage = self.errorBoxContainer:GetNamedChild("ErrorMessage")

    local ouroboros = self.control:GetNamedChild("Ouroboros")
    local pressText = self.control:GetNamedChild("PressText")
    local esoLogo = self.control:GetNamedChild("Logo")

    -- Note: the line of text says "Press <<primary button icon>> To Start" but we're still going to handle other input buttons
    local primaryButtonIconPath = ZO_Keybindings_GetTexturePathForKey(KEY_GAMEPAD_BUTTON_1)
    local primaryButtonIcon = zo_iconFormat(primaryButtonIconPath, 40, 40)
    pressText:SetText(zo_strformat(SI_CONSOLE_PREGAME_PRESS_BUTTON, primaryButtonIcon))

    self.ouroborosAnimation = GetAnimationManager():CreateTimelineFromVirtual("ZO_PregameInitialScreen_FadeAnimation", ouroboros)
    self.pressTextAnimation = GetAnimationManager():CreateTimelineFromVirtual("ZO_PregameInitialScreen_FadeAnimation", pressText)
    self.esoLogoAnimation = GetAnimationManager():CreateTimelineFromVirtual("ZO_PregameInitialScreen_FadeAnimation", esoLogo)

    self.esoLogoAnimation:SetHandler("OnStop", function()
                                    if self.fadeMode == ESO_FADE_OUT then
                                        self.fadeMode = OUROBOROS_FADE_IN
                                        self.ouroborosAnimation:PlayFromStart()
                                    elseif self.fadeMode == ESO_FADE_IN then
                                        self.fadeMode = ESO_FADE_OUT
                                        zo_callLater(function() self.esoLogoAnimation:PlayFromEnd() end, ESO_SHOW_TIME)
                                    end
                                end)

    self.ouroborosAnimation:SetHandler("OnStop", function()
                                    if self.fadeMode == OUROBOROS_FADE_IN then
                                        self.fadeMode = OUROBOROS_WAIT_FOR_BUTTON
                                        self:PlayPressAnyButtonAnimationFromStart()
                                    elseif self.fadeMode == OUROBOROS_FADING_OUT then
                                        PregameStateManager_AdvanceState()
                                    end
                                end)

    self.pressTextAnimation:SetHandler("OnStop", function()
                                                    if(self.pressAnyPromptFadingIn) then
                                                        UnlockGamepads()	
                                                        self.continueAllowed = true
                                                        self.pressAnyPromptFadingIn = false
                                                    end
                                                end)

    self:SetupStartupButtons()

    local function ProfileLoginResult(eventCode, isSuccess, profileError)
        if SCENE_MANAGER:IsShowing("PregameInitialScreen_Gamepad") then
			if isSuccess == true then
				self:OnProfileLoginSuccess()
			else
				self:RefreshScreen()
			end
		end
    end
    
    local function ShowVerificationAlertDialog(eventCode, isSuccess)
        if isSuccess then
            self:SetupError(GetString(SI_CONSOLE_RESEND_VERIFY_EMAIL_SUCCEEDED_TITLE), GetString(SI_CONSOLE_RESEND_VERIFY_EMAIL_SUCCEEDED_TEXT))
        else
            self:SetupError(GetString(SI_CONSOLE_RESEND_VERIFY_EMAIL_FAILED_TITLE), GetString(SI_CONSOLE_RESEND_VERIFY_EMAIL_FAILED_TEXT))
        end
    end

    if(IsConsoleUI()) then
        EVENT_MANAGER:RegisterForEvent("PregameInitialScreen", EVENT_PROFILE_LOGIN_RESULT, ProfileLoginResult)
        EVENT_MANAGER:RegisterForEvent("PregameInitialScreen", EVENT_RESEND_VERIFICATION_EMAIL_RESULT, ShowVerificationAlertDialog)
    end
end

function PregameInitialScreen_Console:IsReadyToPushStart()
    return self.fadeMode == OUROBOROS_WAIT_FOR_BUTTON
end

function PregameInitialScreen_Console:PlayPressAnyButtonAnimationFromStart()
    if not self:IsShowingVerificationError() then
        self.pressTextAnimation:PlayFromStart()
        self.pressAnyPromptFadingIn = true
    end
end

function PregameInitialScreen_Console:ResetScreenState() 
    self:ClearError()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentKeybindStripDescriptor)
    self.currentKeybindStripDescriptor = self.pressAnyKeybindsDescriptor
    KEYBIND_STRIP:AddKeybindButtonGroup(self.currentKeybindStripDescriptor)
    self:PlayPressAnyButtonAnimationFromStart()
end

function PregameInitialScreen_Console:SetupStartupButtons()
    self.pressAnyKeybindsDescriptor = {}

    for i, button in ipairs(STARTUP_BUTTONS) do
        local descriptor = 
        {
            keybind = button,
            callback = function() self:ContinueFunction() end,
            ethereal = true,
        }
        table.insert(self.pressAnyKeybindsDescriptor, descriptor)
    end

    self.verifyEmailKeybindsDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        --Resend
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = GetString(SI_CONSOLE_RESEND_VERIFY_EMAIL_KEYBIND),
            callback =  function()
                            PregameAttemptResendVerificationEmail()
                            self:ResetScreenState()
                        end,
            visible = function() return self.verificationState == VERIFICATION_STATE.OFFER end
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.verifyEmailKeybindsDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:ResetScreenState() end)
end

function PregameInitialScreen_Console:OnProfileLoginSuccess()	
    self:FinishUp()
end

function PregameInitialScreen_Console:ContinueFunction()
    if(self.continueAllowed)  then
        --clear out existing errors
        if not self:IsShowingVerificationError() then
            PREGAME_INITIAL_SCREEN_CONSOLE:ClearError()
            self.pressTextAnimation:PlayFromEnd()
        end

        --remove keybindings and message to prevent spamming
        if(IsConsoleUI() and GetUIPlatform() ~= UI_PLATFORM_PC) then
            PregameSelectProfile()
        else
            self:OnProfileLoginSuccess()
        end
        self.continueAllowed = false
    end
end

function PregameInitialScreen_Console:FinishUp()
    if self.fadeMode == OUROBOROS_WAIT_FOR_BUTTON then
        self.fadeMode = OUROBOROS_FADING_OUT
        PlaySound(SOUNDS.CONSOLE_GAME_ENTER)
        self:Hide()
    end
end

function PregameInitialScreen_Console:RefreshScreen()
    if(self.fadeMode == OUROBOROS_WAIT_FOR_BUTTON) then
        self:PlayPressAnyButtonAnimationFromStart()
    elseif(self.fadeMode == OUROBOROS_FADING_OUT) then
        self:PlayPressAnyButtonAnimationFromStart()
        self.fadeMode = OUROBOROS_FADE_IN
        self.ouroborosAnimation:PlayInstantlyToEnd()
    end
end

function PregameInitialScreen_Console:Hide()
    self.esoLogoAnimation:PlayInstantlyToStart()
    self.ouroborosAnimation:PlayFromEnd()
end

function PregameInitialScreen_Console:ClearError()
    self.verificationState = VERIFICATION_STATE.NONE
    self.errorBox:SetHidden(true)
end

function PregameInitialScreen_Console:ShowError(errorTitle, errorMessage)
    self:PerformDeferredInitialization()
    self:RefreshScreen()

    self:SetupError(errorTitle, errorMessage)
    PregameStateManager_SetState("AccountLogin")
end

function PregameInitialScreen_Console:SetupError(errorTitle, errorMessage)
    self.errorTitle:SetText(errorTitle)
    self.errorMessage:SetText(errorMessage)
    self.errorBox:SetHidden(false)

    local messageOffsetY = select(6, self.errorMessage:GetAnchor(1))
    self.errorBoxContainer:SetHeight(self.errorTitle:GetTextHeight() + self.errorMessage:GetTextHeight() + messageOffsetY)
end

function PregameInitialScreen_Console:ShowEmailVerificationError(dialogTitle, dialogText)
    self.verificationState = VERIFICATION_STATE.OFFER
    self:ShowError(dialogTitle, dialogText)
end

function PregameInitialScreen_Console:IsShowingVerificationError()
    return self.verificationState ~= VERIFICATION_STATE.NONE
end

function PregameInitialScreen_Gamepad_Initialize(self)
    PREGAME_INITIAL_SCREEN_CONSOLE = PregameInitialScreen_Console:New(self)
end
