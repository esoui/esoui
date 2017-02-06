local SHOW_LOGO_DELAY_TIME_MS = 1000

local LOGO_FADE_IN = "logo_fade_in"
local LOGO_WAIT_FOR_BUTTON = "logo_wait_for_button"
local LOGO_FADING_OUT = "logo_fading_out"

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

local PregameInitialScreen_Console = ZO_Object:Subclass()

function PregameInitialScreen_Console:New(control)
    local object = ZO_Object.New(self)
    object:Initialize(control)
    return object
end

function PregameInitialScreen_Console:Initialize(control)
    self.control = control
    self.playIntroAnimation = true
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
                            self.fadeMode = LOGO_FADE_IN
                            if self.playIntroAnimation then
                                zo_callLater(function() self.esoLogoAnimation:PlayFromStart() end, SHOW_LOGO_DELAY_TIME_MS)
                                self.playIntroAnimation = false
                            else
                                self.esoLogoAnimation:PlayInstantlyToEnd()
                            end

                            if IsErrorQueuedFromIngame() then
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

    local esoLogoControl = self.control:GetNamedChild("Logo")
    local pressTextLabel = self.control:GetNamedChild("PressText")

    -- Note: the line of text says "Press <<primary button icon>> To Start" but we're still going to handle other input buttons
    local primaryButtonIconPath = ZO_Keybindings_GetTexturePathForKey(KEY_GAMEPAD_BUTTON_1)
    local primaryButtonIcon = zo_iconFormat(primaryButtonIconPath, 40, 40)
    pressTextLabel:SetText(zo_strformat(SI_CONSOLE_PREGAME_PRESS_BUTTON, primaryButtonIcon))

    self.esoLogoAnimation = GetAnimationManager():CreateTimelineFromVirtual("ZO_PregameInitialScreen_FadeAnimation", esoLogoControl)
    self.pressTextAnimation = GetAnimationManager():CreateTimelineFromVirtual("ZO_PregameInitialScreen_FadeAnimation", pressTextLabel)

    self.esoLogoAnimation:SetHandler("OnStop", function()
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
        if (GetCVar("QuickLaunch") == "1") and (isSuccess == true) then
            --Fast fadeout the logo and get us into game if we're quick launching.
            self.fadeMode = LOGO_FADING_OUT;
            self.esoLogoAnimation:PlayInstantlyToEnd()
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

function PregameInitialScreen_Console:IsReadyToPushStart()
    return self.fadeMode == LOGO_WAIT_FOR_BUTTON
end

function PregameInitialScreen_Console:PlayPressAnyButtonAnimationFromStart()
    if not self:IsShowingVerificationError() then
        self.pressTextAnimation:PlayFromStart()
        self.pressAnyPromptFadingIn = true
        
        -- This will remove all gamepads and assign the gamepad that sends the next input as the primary gamepad.
        -- It must occur before the player can be registered as pressing a key to continue.
        UnlockGamepads()
    end
end

function PregameInitialScreen_Console:ResetScreenState() 
    self:ClearError()

    local KEYBINDS_REMOVED = false
    local KEYBINDS_ADDED = true

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentKeybindStripDescriptor)
    PREGAME_INITIAL_SCREEN_CONSOLE_SCENE:FireCallbacks("ResetScreenState", KEYBINDS_REMOVED)

    self.currentKeybindStripDescriptor = self.pressAnyKeybindsDescriptor
    KEYBIND_STRIP:AddKeybindButtonGroup(self.currentKeybindStripDescriptor)
    PREGAME_INITIAL_SCREEN_CONSOLE_SCENE:FireCallbacks("ResetScreenState", KEYBINDS_ADDED)
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
    if self.continueAllowed then
        --clear out existing errors
        if not self:IsShowingVerificationError() then
            PREGAME_INITIAL_SCREEN_CONSOLE:ClearError()
            self.pressTextAnimation:PlayFromEnd()
        end

        --remove keybindings and message to prevent spamming
        if IsConsoleUI() and GetUIPlatform() ~= UI_PLATFORM_PC then
            PregameSelectProfile()
        else
            self:OnProfileLoginSuccess()
        end
        self.continueAllowed = false
    else
        if self.pressAnyPromptFadingIn then
            self.continueDesired = true
        end
    end
end

function PregameInitialScreen_Console:FinishUp()
    if self.fadeMode == LOGO_WAIT_FOR_BUTTON then
        self.fadeMode = LOGO_FADING_OUT
        PlaySound(SOUNDS.CONSOLE_GAME_ENTER)
        self:Hide()
    end
end

function PregameInitialScreen_Console:RefreshScreen()
    if self.fadeMode == LOGO_WAIT_FOR_BUTTON then
        self:PlayPressAnyButtonAnimationFromStart()
    elseif self.fadeMode == LOGO_FADING_OUT then
        self:PlayPressAnyButtonAnimationFromStart()
        self.fadeMode = LOGO_FADE_IN
        self.esoLogoAnimation:PlayInstantlyToEnd()
    end
end

function PregameInitialScreen_Console:Hide()
    self.esoLogoAnimation:PlayFromEnd()
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
