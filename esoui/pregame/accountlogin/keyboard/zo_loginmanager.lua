local LoginManager_Keyboard = ZO_Object:Subclass()

function LoginManager_Keyboard:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function LoginManager_Keyboard:Initialize()
    self.showCreateLinkAccountFragment = false  -- Always assume we show the regular login screen first

    local function FilterMethodCallback(method)
        return function(_, ...)
            if self:IsLoginSceneShowing() or ZO_Dialogs_IsShowing("LOGIN_QUEUED") then
                -- calling self.method(self) is the same as calling self:method()
                return method(self, ...)
            end
        end
    end

    if IsUsingLinkedLogin() then
        EVENT_MANAGER:RegisterForEvent("LoginManager", EVENT_CREATE_LINK_LOADING_ERROR, FilterMethodCallback(self.OnCreateLinkLoadingError))
        EVENT_MANAGER:RegisterForEvent("LoginManager", EVENT_ACCOUNT_LINK_SUCCESSFUL, FilterMethodCallback(self.OnCreateLinkAccountSuccessful))
        EVENT_MANAGER:RegisterForEvent("LoginManager", EVENT_PROFILE_NOT_LINKED, FilterMethodCallback(self.OnProfileNotLinked))
    end

    EVENT_MANAGER:RegisterForEvent("LoginManager", EVENT_LOGIN_FAILED_INVALID_CREDENTIALS, FilterMethodCallback(self.OnBadLogin))
    EVENT_MANAGER:RegisterForEvent("LoginManager", EVENT_LOGIN_SUCCESSFUL, FilterMethodCallback(self.OnLoginSuccessful))
    EVENT_MANAGER:RegisterForEvent("LoginManager", EVENT_LOGIN_QUEUED, FilterMethodCallback(self.OnLoginQueued))
    EVENT_MANAGER:RegisterForEvent("LoginManager", EVENT_LOGIN_OVERFLOW_MODE_PROMPT, FilterMethodCallback(self.OnOverflowModeWaiting))
    EVENT_MANAGER:RegisterForEvent("LoginManager", EVENT_LOGIN_REQUESTED, FilterMethodCallback(self.OnLoginRequested))
    EVENT_MANAGER:RegisterForEvent("LoginManager", EVENT_LOGIN_OTP_PENDING, FilterMethodCallback(self.OnOTPPending))
    EVENT_MANAGER:RegisterForEvent("LoginManager", EVENT_BAD_CLIENT_VERSION, FilterMethodCallback(self.OnBadClientVersion))
end

function LoginManager_Keyboard:GetRelevantLoginFragment()
    -- Show the create/link account fragment if the following conditions are met:
    --  1. If we require a linked login for the current client version
    --  2. If we have not yet established a link between accounts
    --  3. If we didn't encounter an error trying to establish the link (or the Login button was pressed again after that)

    if IsUsingLinkedLogin() and self.showCreateLinkAccountFragment then
        self.currentFragment = CREATE_LINK_ACCOUNT_FRAGMENT
    else
        self.currentFragment = LOGIN_FRAGMENT
    end

    return self.currentFragment
end

function LoginManager_Keyboard:HideShowingLoginFragment()
    if self.currentFragment then
        SCENE_MANAGER:RemoveFragment(self.currentFragment)
    end
end

function LoginManager_Keyboard:IsShowingCreateLinkAccountFragment()
    return self.showCreateLinkAccountFragment
end

function LoginManager_Keyboard:IsLoginSceneShowing()
    return GAME_MENU_PREGAME_KEYBOARD:IsLoginSceneShowing()
end

function LoginManager_Keyboard:SwitchToLoginFragment()
    if self.showCreateLinkAccountFragment then
        self.currentFragment = LOGIN_FRAGMENT
        GAME_MENU_PREGAME_KEYBOARD:GetScene():RemoveFragment(CREATE_LINK_ACCOUNT_FRAGMENT)
        GAME_MENU_PREGAME_KEYBOARD:GetScene():AddFragment(LOGIN_FRAGMENT)
        self.showCreateLinkAccountFragment = false
        LOGIN_KEYBOARD:SetLoginControlsHidden(false)
    end
end

function LoginManager_Keyboard:SwitchToCreateLinkAccountFragment()
    if not self.showCreateLinkAccountFragment then
        self.currentFragment = CREATE_LINK_ACCOUNT_FRAGMENT
        GAME_MENU_PREGAME_KEYBOARD:GetScene():RemoveFragment(LOGIN_FRAGMENT)
        GAME_MENU_PREGAME_KEYBOARD:GetScene():AddFragment(CREATE_LINK_ACCOUNT_FRAGMENT)
        self.showCreateLinkAccountFragment = true
        LOGIN_KEYBOARD:SetLoginControlsHidden(true)
    end
end

function LoginManager_Keyboard:IsLoginPossible()
    return not IsUsingLinkedLogin() or not self.mustRelaunch
end

function LoginManager_Keyboard:AttemptLinkedLogin()
    -- Attempts to log in with credentials supplied to the client by the launcher.
    ZO_Dialogs_ShowDialog("LINKED_LOGIN_KEYBOARD")
    PregameBeginLinkedLogin()
end

function LoginManager_Keyboard:AttemptCreateAccount(email, ageValid, emailSignup, country, requestedAccountName)
    self.isLinking = nil
    ZO_Dialogs_ShowDialog("CREATING_ACCOUNT_KEYBOARD")
    PregameSetAccountCreationInfo(email, ageValid, emailSignup, country, requestedAccountName)
    PregameCreateAccount()
end

function LoginManager_Keyboard:AttemptAccountLink(username, password)
    self.isLinking = true
    ZO_Dialogs_ShowDialog("LINKING_ACCOUNTS_KEYBOARD")
    PregameLinkAccount(username, password)
end

function LoginManager_Keyboard:RequestAccountActivationCode()
    self.isLinking = true
    RequestLinkAccountActivationCode()
end

function LoginManager_Keyboard:OnCreateLinkAccountSuccessful()
    ZO_Dialogs_ReleaseDialog(self.isLinking and "LINKING_ACCOUNTS_KEYBOARD" or "CREATING_ACCOUNT_KEYBOARD")

    local textParams
    if not self.isLinking then
        local note3 = GetPlatformServiceType() == PLATFORM_SERVICE_TYPE_DMM and SI_CREATEACCOUNT_SUCCESS_NOTE_3_DMM or SI_CREATEACCOUNT_SUCCESS_NOTE_3
        textParams = { mainTextParams = {
                                            GetString(SI_CREATEACCOUNT_SUCCESS_HEADER),
                                            GetString(SI_CREATEACCOUNT_SUCCESS_NOTE_1),
                                            GetString(SI_CREATEACCOUNT_SUCCESS_NOTE_2),
                                            GetString(note3),
                                        }
                     }
    end

    ZO_Dialogs_ShowDialog(self.isLinking and "LINKING_ACCOUNTS_SUCCESS_KEYBOARD" or "CREATE_ACCOUNT_SUCCESS_KEYBOARD", nil, textParams)
    self.isLinking = nil
end

function LoginManager_Keyboard:OnCreateLinkLoadingError(loginError, linkingError, debugInfo)
    ZO_Dialogs_ReleaseDialog("LINKED_LOGIN_KEYBOARD")

    local dialogName
    local errorString
    local formattedErrorString
    local dialogData = nil

    if loginError ~= LOGIN_AUTH_ERROR_NO_ERROR then
        if loginError == LOGIN_AUTH_ERROR_ACCOUNT_NOT_LINKED then
            -- User needs to create a link.
            self:OnProfileNotLinked()
        else
            dialogName = "LINKED_LOGIN_ERROR_KEYBOARD"
            errorString = GetString("SI_LOGINAUTHERROR", loginError)

            if loginError == LOGIN_AUTH_ERROR_MISSING_DMM_TOKEN or loginError == LOGIN_AUTH_ERROR_BAD_DMM_TOKEN then
                -- If the issue was with the token, kinda have to restart, since that's supplied from the launcher
                self.mustRelaunch = true
                LOGIN_KEYBOARD:ShowRelaunchGameLabel()
             elseif loginError == LOGIN_AUTH_ERROR_ACCOUNT_NOT_VERIFIED or loginError == LOGIN_AUTH_ERROR_GAME_ACCOUNT_NOT_VERIFIED then
                dialogData =
                {
                    showResendVerificationEmail = true,
                }
            end

            -- In any case, show the normal login fragment so that the user can attempt to manually login again if a
            -- relaunch isn't necessary.
            self:SwitchToLoginFragment()
        end
    elseif linkingError ~= ACCOUNT_CREATE_LINK_ERROR_NO_ERROR then
        ZO_Dialogs_ReleaseDialog(self.isLinking and "LINKING_ACCOUNTS_KEYBOARD" or "CREATING_ACCOUNT_KEYBOARD")

        dialogName = self.isLinking and "LINKING_ACCOUNTS_ERROR_KEYBOARD" or "CREATE_ACCOUNT_ERROR_KEYBOARD"
        if linkingError == ACCOUNT_CREATE_LINK_ERROR_EXTERNAL_REFERENCE_ALREADY_USED or linkingError == ACCOUNT_CREATE_LINK_ERROR_USER_ALREADY_LINKED then
            local serviceType = GetPlatformServiceType()
            local accountTypeName = GetString("SI_PLATFORMSERVICETYPE", serviceType)
            errorString = GetString(SI_LINKACCOUNT_ALREADY_LINKED_ERROR_FORMAT)
            formattedErrorString = zo_strformat(errorString, accountTypeName)
        else
            errorString = GetString("SI_ACCOUNTCREATELINKERROR", linkingError)
        end

        CREATE_LINK_ACCOUNT_KEYBOARD:GetPasswordEdit():Clear()

        -- We need to switch back to the login fragment to refresh session ID, or else the player won't be able to finish
        -- creating or linking an account
        self:SwitchToLoginFragment()
    end

    if dialogName then
        if errorString == nil or errorString == "" then
            errorString = GetString(SI_UNEXPECTED_ERROR)
        end

        if formattedErrorString == nil then
            formattedErrorString = zo_strformat(errorString, GetURLTextByType(APPROVED_URL_ESO_HELP))
        end

        local textParams = { mainTextParams = { formattedErrorString .. debugInfo }}

        ZO_Dialogs_ShowDialog(dialogName, dialogData, textParams)
    end

    self.isLinking = nil
end

function LoginManager_Keyboard:OnProfileNotLinked()
    ZO_Dialogs_ReleaseDialog("LINKED_LOGIN_KEYBOARD")
    self:SwitchToCreateLinkAccountFragment()
end

function LoginManager_Keyboard:OnLoginSuccessful()
    if IsUsingLinkedLogin() then
        self:SwitchToLoginFragment()
    end
    if PregameStateManager_GetCurrentState() == "AccountLogin" then
        PregameStateManager_SetState("WorldSelect_Requested")
    end
end

local loginQueuedScene
local currentLoginQueueWaitTime
local lastQueuePosition

local function GetLoginQueueApproximateWaitTime(waitTime, queuePosition)
    -- if our position increases, the ETA we have "locked" is no longer valid
    if not currentLoginQueueWaitTime or queuePosition > lastQueuePosition then
        currentLoginQueueWaitTime = zo_max(waitTime * 1000, 1000) -- minimum wait time is that last second...
    else
        currentLoginQueueWaitTime = zo_min(currentLoginQueueWaitTime, zo_max(waitTime * 1000, 1000))
    end
    lastQueuePosition = queuePosition

    return currentLoginQueueWaitTime
end

function LoginManager_Keyboard:OnLoginQueued(waitTime, queuePosition)
    if not loginQueuedScene then
        loginQueuedScene = ZO_Scene:New("loginQueuedScene", SCENE_MANAGER)
        loginQueuedScene:AddFragment(PREGAME_BACKGROUND_FRAGMENT)
    end

    SCENE_MANAGER:Show("loginQueuedScene")

    waitTime = GetLoginQueueApproximateWaitTime(waitTime, queuePosition)

    if ZO_Dialogs_IsShowing("LOGIN_QUEUED") then
        ZO_Dialogs_UpdateDialogMainText(ZO_Dialogs_FindDialog("LOGIN_QUEUED"), nil, { waitTime, queuePosition })
    else
        ZO_Dialogs_ReleaseAllDialogs(true)
        ZO_Dialogs_ShowDialog("LOGIN_QUEUED", nil, { mainTextParams = { waitTime, queuePosition } })
    end
end

function LoginManager_Keyboard:OnOverflowModeWaiting(mainServerETASeconds, queuePosition)
    local waitTime = GetLoginQueueApproximateWaitTime(mainServerETASeconds, queuePosition)
    ZO_Dialogs_ReleaseAllDialogs(true)
    ZO_Dialogs_ShowDialog("PROVIDE_OVERFLOW_RESPONSE", {waitTime = waitTime})
end

function LoginManager_Keyboard:OnBadClientVersion()
    ZO_Dialogs_ReleaseAllDialogs(true)
    ZO_Dialogs_ShowDialog("BAD_CLIENT_VERSION")
end

function LoginManager_Keyboard:OnLoginRequested()
    PregameStateManager_ShowLoginRequested()
end

function LoginManager_Keyboard:OnBadLogin(errorCode, accountPageURL)
    ZO_Dialogs_ReleaseDialog("LOGIN_REQUESTED")

    if errorCode == AUTHENTICATION_ERROR_PAYMENT_EXPIRED then
        ZO_Dialogs_ShowDialog("BAD_LOGIN_PAYMENT_EXPIRED", {accountPageURL = accountPageURL})
    else
        ZO_Dialogs_ShowDialog("BAD_LOGIN", {accountPageURL = accountPageURL})
    end
end

function LoginManager_Keyboard:OnOTPPending(otpReason, otpType, otpDurationInSeconds)
    local otpDurationMs = otpDurationInSeconds * 1000
    local otpExpirationMs = GetFrameTimeMilliseconds() + otpDurationMs
    local dialogName, textParams
    if otpReason == LOGIN_STATUS_OTP_PENDING then
        dialogName = "PROVIDE_OTP_INITIAL"
        textParams = { GetString(SI_OTP_DIALOG_SUBMIT), otpDurationMs }
    elseif otpReason == LOGIN_STATUS_OTP_FAILED then
        dialogName = "PROVIDE_OTP_SUBSEQUENT"
        textParams = { otpDurationMs }
    end
    ZO_Dialogs_ReleaseAllDialogs(true)
    ZO_Dialogs_ShowDialog(dialogName, { otpExpirationMs = otpExpirationMs, otpReason = otpReason }, {mainTextParams = textParams})
end

LOGIN_MANAGER_KEYBOARD = LoginManager_Keyboard:New()