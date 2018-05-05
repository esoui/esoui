local LoginManager_Keyboard = ZO_Object:Subclass()

function LoginManager_Keyboard:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function LoginManager_Keyboard:Initialize()
    self.showCreateLinkAccountFragment = false  -- Always assume we show the regular login screen first

    if IsUsingLinkedLogin() then
        EVENT_MANAGER:RegisterForEvent("LoginManager", EVENT_CREATE_LINK_LOADING_ERROR, function(...) self:OnCreateLinkLoadingError(...) end)
        EVENT_MANAGER:RegisterForEvent("LoginManager", EVENT_LOGIN_SUCCESSFUL, function(...) self:OnLoginSuccessful(...) end)
        EVENT_MANAGER:RegisterForEvent("LoginManager", EVENT_ACCOUNT_LINK_SUCCESSFUL, function(...) self:OnCreateLinkAccountSuccessful(...) end)
        EVENT_MANAGER:RegisterForEvent("LoginManager", EVENT_ACCOUNT_CREATE_SUCCESSFUL, function(...) self:OnCreateLinkAccountSuccessful(...) end)
        EVENT_MANAGER:RegisterForEvent("LoginManager", EVENT_PROFILE_NOT_LINKED, function(...) self:OnProfileNotLinked(...) end)
    end
end

function LoginManager_Keyboard:ShowRelevantLoginFragment()
    -- Show the create/link account fragment if the following conditions are met:
    --  1. If we require a linked login for the current client version
    --  2. If we have not yet established a link between accounts
    --  3. If we didn't encounter an error trying to establish the link (or the Login button was pressed again after that)

    if IsUsingLinkedLogin() and self.showCreateLinkAccountFragment then
        self.currentFragment = CREATE_LINK_ACCOUNT_FRAGMENT
    else
        self.currentFragment = LOGIN_FRAGMENT
    end

    SCENE_MANAGER:AddFragment(self.currentFragment)
end

function LoginManager_Keyboard:HideShowingLoginFragment()
    if self.currentFragment then
        SCENE_MANAGER:RemoveFragment(self.currentFragment)
    end
end

function LoginManager_Keyboard:IsShowingCreateLinkAccountFragment()
    return self.showCreateLinkAccountFragment
end

function LoginManager_Keyboard:SwitchToLoginFragment()
    if self.showCreateLinkAccountFragment then
        self.currentFragment = LOGIN_FRAGMENT
        SCENE_MANAGER:RemoveFragment(CREATE_LINK_ACCOUNT_FRAGMENT)
        SCENE_MANAGER:AddFragment(LOGIN_FRAGMENT)
        self.showCreateLinkAccountFragment = false
    end
end

function LoginManager_Keyboard:SwitchToCreateLinkAccountFragment()
    if not self.showCreateLinkAccountFragment then
        self.currentFragment = CREATE_LINK_ACCOUNT_FRAGMENT
        SCENE_MANAGER:RemoveFragment(LOGIN_FRAGMENT)
        SCENE_MANAGER:AddFragment(CREATE_LINK_ACCOUNT_FRAGMENT)
        self.showCreateLinkAccountFragment = true
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
    ZO_Dialogs_ShowDialog("CREATING_ACCOUNT_KEYBOARD")
    PregameSetAccountCreationInfo(email, ageValid, emailSignup, country, requestedAccountName)
    PregameCreateAccount()
end

function LoginManager_Keyboard:AttemptAccountLink(username, password)
    self.isLinking = true
    ZO_Dialogs_ShowDialog("LINKING_ACCOUNTS_KEYBOARD")
    PregameLinkAccount(username, password)
end

function LoginManager_Keyboard:OnCreateLinkAccountSuccessful()
    ZO_Dialogs_ReleaseDialog(self.isLinking and "LINKING_ACCOUNTS_KEYBOARD" or "CREATING_ACCOUNT_KEYBOARD")

    local textParams
    if not self.isLinking then
        textParams = { mainTextParams = { 
                                            GetString(SI_CREATEACCOUNT_SUCCESS_HEADER),
                                            GetString(SI_CREATEACCOUNT_SUCCESS_NOTE_1),
                                            GetString(SI_CREATEACCOUNT_SUCCESS_NOTE_2),
                                            GetString(SI_CREATEACCOUNT_SUCCESS_NOTE_3),
                                        }
                     }
    end

    ZO_Dialogs_ShowDialog(self.isLinking and "LINKING_ACCOUNTS_SUCCESS_KEYBOARD" or "CREATE_ACCOUNT_SUCCESS_KEYBOARD", nil, textParams)
    self.isLinking = nil
end

function LoginManager_Keyboard:OnCreateLinkLoadingError(eventId, loginError, linkingError, debugInfo)
    ZO_Dialogs_ReleaseDialog("LINKED_LOGIN_KEYBOARD")

    local dialogName
    local dialogText
    
    if loginError ~= LOGIN_AUTH_ERROR_NO_ERROR then
        if loginError == LOGIN_AUTH_ERROR_ACCOUNT_NOT_LINKED then
            -- User needs to create a link.
            self:OnProfileNotLinked()
        else
            dialogName = "LINKED_LOGIN_ERROR_KEYBOARD"
            dialogText = GetString("SI_LOGINAUTHERROR", loginError)

            if loginError == LOGIN_AUTH_ERROR_MISSING_DMM_TOKEN or loginError == LOGIN_AUTH_ERROR_BAD_DMM_TOKEN then
                -- If the issue was with the token, kinda have to restart, since that's supplied from the launcher
                self.mustRelaunch = true
                LOGIN_KEYBOARD:ShowRelaunchGameLabel()
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
            dialogText = zo_strformat(SI_LINKACCOUNT_ALREADY_LINKED_ERROR_FORMAT, accountTypeName)
        else
            dialogText = GetString("SI_ACCOUNTCREATELINKERROR", linkingError)
        end
        
        CREATE_LINK_ACCOUNT_KEYBOARD:GetPasswordEdit():Clear()

        -- We need to switch back to the login fragment to refresh session ID, or else the player won't be able to finish
        -- creating or linking an account
        self:SwitchToLoginFragment()
    end

    if dialogName then
        if dialogText == nil or dialogText == "" then
            dialogText = zo_strformat(SI_UNEXPECTED_ERROR, GetString(SI_HELP_URL))
        end

        local dialogData = nil
        local textParams = { mainTextParams = { dialogText .. debugInfo }}

        ZO_Dialogs_ShowDialog(dialogName, dialogData, textParams)
    end

    self.isLinking = nil
end

function LoginManager_Keyboard:OnProfileNotLinked()
    ZO_Dialogs_ReleaseDialog("LINKED_LOGIN_KEYBOARD")
    self:SwitchToCreateLinkAccountFragment()
end

function LoginManager_Keyboard:OnLoginSuccessful()
    self:SwitchToLoginFragment()
end

LOGIN_MANAGER_KEYBOARD = LoginManager_Keyboard:New()