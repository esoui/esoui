local LOGO_FADE_IN = "logo_fade_in"
local LOGO_WAIT_FOR_BUTTON = "logo_wait_for_button"
local LOGO_FADING_OUT = "logo_fading_out"

local STARTUP_BUTTONS =
{
    "UI_SHORTCUT_PRIMARY",
    "UI_SHORTCUT_SECONDARY",
    "UI_SHORTCUT_TERTIARY",
    "UI_SHORTCUT_QUATERNARY",
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

local PregameInitialScreen_Gamepad = ZO_InitializingObject:Subclass()

function PregameInitialScreen_Gamepad:Initialize(control)
    self.control = control
    self.verificationState = VERIFICATION_STATE.NONE

    local PregameInitialScreen_Gamepad_Fragment = ZO_FadeSceneFragment:New(control)
    PREGAME_INITIAL_SCREEN_GAMEPAD_SCENE = ZO_Scene:New("PregameInitialScreen_Gamepad", SCENE_MANAGER)
    PREGAME_INITIAL_SCREEN_GAMEPAD_SCENE:AddFragment(PregameInitialScreen_Gamepad_Fragment)

    PREGAME_INITIAL_SCREEN_GAMEPAD_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            ZO_ControllerDisconnect_DismissPopup()
            self:PerformDeferredInitialization()

            -- Reset fade in animations
            self.fadeMode = nil
            self.esoAnimatedBackgroundAnimation:PlayInstantlyToStart()
            self.pressTextAnimation:PlayInstantlyToStart()
            self.pressAnyPromptFadingIn = false

            KEYBIND_STRIP:RemoveDefaultExit()
            self.currentKeybindStripDescriptor = self.pressAnyKeybindsDescriptor
            if self:IsShowingVerificationError() then
                self.currentKeybindStripDescriptor = self.verifyEmailKeybindsDescriptor
            end
            KEYBIND_STRIP:AddKeybindButtonGroup(self.currentKeybindStripDescriptor)
        elseif newState == SCENE_SHOWN then
            self.fadeMode = LOGO_FADE_IN
            self.esoAnimatedBackgroundAnimation:PlayFromStart()

            if IsErrorQueuedFromIngame() then
                ZO_Pregame_DisplayServerDisconnectedError()
            end
        elseif newState == SCENE_HIDDEN then
            self:ClearError()
            PregameStateManager_ClearError()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentKeybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
            self.continueDesired = false
            self.continueAllowed = false

            -- It's possible to switch from the gamepad UI to the keyboard UI while esoAnimatedBackgroundAnimation
            -- is still playing. The OnStop handler of the animation may then attempt to advance the state, which
            -- will fail when we are in the keyboard UI. To prevent the OnStop handler from doing anything, we
            -- clear fadeMode.
            self.fadeMode = nil
            self.esoAnimatedBackgroundAnimation:Stop()

            -- Similar to esoAnimatedBackgroundAnimation, we'll stop this animation if it's playing and prevent
            -- it from carrying out any unwanted actions.
            self.pressAnyPromptFadingIn = false
            self.pressTextAnimation:Stop()
        end
    end)
end

function PregameInitialScreen_Gamepad:PerformDeferredInitialization()
    if self.initialized then return end
    self.initialized = true

    self.errorBox = self.control:GetNamedChild("ErrorBox")
    self.errorBoxContainer = self.errorBox:GetNamedChild("Container")
    self.errorTitle = self.errorBoxContainer:GetNamedChild("ErrorTitle")
    self.errorMessage = self.errorBoxContainer:GetNamedChild("ErrorMessage")

    local esoLogoControl = self.control:GetNamedChild("Logo")
    local pressTextLabel = self.control:GetNamedChild("PressText")

    -- Note: the line of text says "Press <<primary button icon>> To Start" but we're still going to handle other input buttons
    local function customTextFunction(label, bindingText)
        label:SetText(zo_strformat(SI_GAMEPAD_PREGAME_PRESS_BUTTON, bindingText))
    end

    local SHOW_UNBOUND = true
    local DEFAULT_GAMEPAD_ACTION_NAME = nil
    local DONT_ALWAYS_PREFER_GAMEPAD = false
    local DONT_SHOW_AS_HOLD = false
    local scalePercent = 110
    ZO_Keybindings_RegisterLabelForInLineBindingUpdate(pressTextLabel, "UI_SHORTCUT_PRIMARY", SHOW_UNBOUND, DEFAULT_GAMEPAD_ACTION_NAME, customTextFunction, DONT_ALWAYS_PREFER_GAMEPAD, DONT_SHOW_AS_HOLD, scalePercent)

    self.esoAnimatedBackgroundAnimation = GetAnimationManager():CreateTimelineFromVirtual("ZO_PregameInitialScreen_AnimatedBackgroundAnimation", esoLogoControl)
    self.pressTextAnimation = GetAnimationManager():CreateTimelineFromVirtual("ZO_PregameInitialScreen_PressTextFadeAnimation", pressTextLabel)

    self.esoAnimatedBackgroundAnimation:SetHandler("OnStop", function()
        if self.fadeMode == LOGO_FADE_IN then
            self.fadeMode = LOGO_WAIT_FOR_BUTTON
            self:PlayPressAnyButtonAnimationFromStart()
        elseif self.fadeMode == LOGO_FADING_OUT then
            PregameStateManager_AdvanceState()
        end
    end)

    self.pressTextAnimation:SetHandler("OnStop", function()
        if self.pressAnyPromptFadingIn then
            self.continueAllowed = true

            if self.continueDesired then
                self:ContinueFunction()
            end

            self.pressAnyPromptFadingIn = false
            self.continueDesired = false
        end
    end)

    self:SetupStartupButtons()

    local function ProfileLoginResult(eventCode, isSuccess, profileError)
        if GetCVar("QuickLaunch") == "1" and isSuccess == true then
            --Fast fadeout the logo and get us into game if we're quick launching.
            self.fadeMode = LOGO_FADING_OUT;
            self.esoAnimatedBackgroundAnimation:PlayInstantlyToEnd()
        else
            if SCENE_MANAGER:IsShowing("PregameInitialScreen_Gamepad") then
                if isSuccess == true then
                    self:OnProfileLoginSuccess()
                else
                    self:RefreshScreen()
                end
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

    if IsConsoleUI() then
        EVENT_MANAGER:RegisterForEvent("PregameInitialScreen", EVENT_PROFILE_LOGIN_RESULT, ProfileLoginResult)
        EVENT_MANAGER:RegisterForEvent("PregameInitialScreen", EVENT_RESEND_VERIFICATION_EMAIL_RESULT, ShowVerificationAlertDialog)
    end
end

function PregameInitialScreen_Gamepad:IsReadyToPushStart()
    return self.fadeMode == LOGO_WAIT_FOR_BUTTON
end

function PregameInitialScreen_Gamepad:PlayPressAnyButtonAnimationFromStart()
    if not self:IsShowingVerificationError() then
        self.pressTextAnimation:PlayFromStart()
        self.pressAnyPromptFadingIn = true

        -- This will remove all gamepads and assign the gamepad that sends the next input as the primary gamepad.
        -- It must occur before the player can be registered as pressing a key to continue.
        UnlockGamepads()
    end
end

function PregameInitialScreen_Gamepad:ResetScreenState()
    self:ClearError()

    local KEYBINDS_REMOVED = false
    local KEYBINDS_ADDED = true

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentKeybindStripDescriptor)
    PREGAME_INITIAL_SCREEN_GAMEPAD_SCENE:FireCallbacks("ResetScreenState", KEYBINDS_REMOVED)

    self.currentKeybindStripDescriptor = self.pressAnyKeybindsDescriptor
    KEYBIND_STRIP:AddKeybindButtonGroup(self.currentKeybindStripDescriptor)
    PREGAME_INITIAL_SCREEN_GAMEPAD_SCENE:FireCallbacks("ResetScreenState", KEYBINDS_ADDED)
    self:PlayPressAnyButtonAnimationFromStart()
end

function PregameInitialScreen_Gamepad:SetupStartupButtons()
    self.pressAnyKeybindsDescriptor = {}

    for i, button in ipairs(STARTUP_BUTTONS) do
        local descriptor =
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Initial Screen Startup Button",
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
            callback = function()
                PregameAttemptResendVerificationEmail()
                self:ResetScreenState()
            end,
            visible = function()
                return self.verificationState == VERIFICATION_STATE.OFFER
            end
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.verifyEmailKeybindsDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:ResetScreenState() end)
end

function PregameInitialScreen_Gamepad:OnProfileLoginSuccess()
    self:FinishUp()
end

function PregameInitialScreen_Gamepad:ContinueFunction()
    if self.continueAllowed then
        WriteToInterfaceLog(string.format("PregameInitialScreen_Gamepad:ContinueFunction Continue allowed. Fade mode: %s", self.fadeMode or "nil"))
        --clear out existing errors
        if not self:IsShowingVerificationError() then
            PREGAME_INITIAL_SCREEN_GAMEPAD:ClearError()
            self.pressTextAnimation:PlayFromEnd()
        end

        if IsConsoleUI() and not ZO_IsForceConsoleFlow() then
            if not PregameHasProfileSelected() then
                WriteToInterfaceLog(string.format("PregameInitialScreen_Gamepad:ContinueFunction Selecting profile"))
                PregameSelectProfile()
            else
                -- If we already have a profile selected, we won't get an event callback from calling PregameSelectProfile
                -- but we also don't need to wait and can just proceed
                WriteToInterfaceLog(string.format("PregameInitialScreen_Gamepad:ContinueFunction Profile already selected"))
                self:OnProfileLoginSuccess()
            end
        else
            self:OnProfileLoginSuccess()
        end
        self.continueAllowed = false
        self.continueDesired = false
    else
        WriteToInterfaceLog(string.format("PregameInitialScreen_Gamepad:ContinueFunction Unable to continue at this time. Fade mode: %s", self.fadeMode or "nil"))
        if self.pressAnyPromptFadingIn then
            self.continueDesired = true
        end
    end
end

function PregameInitialScreen_Gamepad:FinishUp()
    WriteToInterfaceLog(string.format("PregameInitialScreen_Gamepad:FinishUp Is ready to push start: %s", self:IsReadyToPushStart() and "true" or "false"))
    if self:IsReadyToPushStart() then
        self.fadeMode = LOGO_FADING_OUT
        PlaySound(SOUNDS.CONSOLE_GAME_ENTER)
        self:Hide()
    end
end

function PregameInitialScreen_Gamepad:RefreshScreen()
    WriteToInterfaceLog(string.format("PregameInitialScreen_Gamepad:RefreshScreen Fade mode: %s", self.fadeMode or "nil"))
    if self.fadeMode == LOGO_WAIT_FOR_BUTTON then
        self:PlayPressAnyButtonAnimationFromStart()
    elseif self.fadeMode == LOGO_FADING_OUT then
        self.pressTextAnimation:PlayInstantlyToStart()
        self.pressAnyPromptFadingIn = false
        self.fadeMode = LOGO_FADE_IN
        self.esoAnimatedBackgroundAnimation:PlayInstantlyToEnd()
    end
end

function PregameInitialScreen_Gamepad:Hide()
    self.esoAnimatedBackgroundAnimation:PlayFromEnd()
end

function PregameInitialScreen_Gamepad:ClearError()
    self.verificationState = VERIFICATION_STATE.NONE
    self.errorBox:SetHidden(true)
end

function PregameInitialScreen_Gamepad:ShowError(errorTitle, errorMessage)
    WriteToInterfaceLog(string.format("PregameInitialScreen_Gamepad:ShowError ErrorMessage: %s Fade mode: %s", errorMessage or "nil", self.fadeMode or "nil"))
    self:PerformDeferredInitialization()
    self:RefreshScreen()

    self:SetupError(errorTitle, errorMessage)
    PregameStateManager_SetState("AccountLogin")
end

function PregameInitialScreen_Gamepad:SetupError(errorTitle, errorMessage)
    self.errorTitle:SetText(errorTitle)
    self.errorMessage:SetText(errorMessage)
    self.errorBox:SetHidden(false)

    local messageOffsetY = select(6, self.errorMessage:GetAnchor(1))
    self.errorBoxContainer:SetHeight(self.errorTitle:GetTextHeight() + self.errorMessage:GetTextHeight() + messageOffsetY)
end

function PregameInitialScreen_Gamepad:ShowEmailVerificationError(dialogTitle, dialogText)
    self.verificationState = VERIFICATION_STATE.OFFER
    self:ShowError(dialogTitle, dialogText)
end

function PregameInitialScreen_Gamepad:IsShowingVerificationError()
    return self.verificationState ~= VERIFICATION_STATE.NONE
end

function PregameInitialScreen_Gamepad_Initialize(self)
    PREGAME_INITIAL_SCREEN_GAMEPAD = PregameInitialScreen_Gamepad:New(self)
end
