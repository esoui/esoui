local ANNOUNCEMENTS_UPDATE_INTERVAL = 60

local function RequestOpenURL(url, text)
    local urlApplication = SI_URL_APPLICATION_WEB
    if url:find("mailto:", 1, true) then
        urlApplication = SI_URL_APPLICATION_MAIL
    end
    ZO_Dialogs_ShowDialog("CONFIRM_OPEN_URL", {url = url}, {mainTextParams = {text, GetString(urlApplication)}})
end

local function OnLinkClicked(link, button, text, color, linkType, ...)
    if not ZO_PEGI_IsDeclineNotificationShowing() and linkType == URL_LINK_TYPE then
        RequestOpenURL(zo_strjoin(':', ...), text)
        return true
    end
end

-- Controls the pregame slideshow
local PregameSlideShow_Keyboard = ZO_Object:Subclass()

function PregameSlideShow_Keyboard:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function PregameSlideShow_Keyboard:Initialize(control)
    self.control = control
    self.crossfade = control:GetNamedChild("Crossfade")

    PREGAME_SLIDE_SHOW_FRAGMENT = ZO_SimpleSceneFragment:New(control)
end

function PregameSlideShow_Keyboard:BeginSlideShow()
    local numLoadingScreens = GetNumLoadingScreens()
    local texturesTable = {}
    local slideShow = ZO_CrossfadeBG_GetObject(self.crossfade)
    for i = 1, numLoadingScreens do
        local assetId = GetLoadingScreenTexture(i)
        table.insert(texturesTable, assetId)
    end
    slideShow:PlaySlideShow(20000, unpack(texturesTable))
end

function PregameSlideShow_Keyboard:StopSlideShow()
    local slideShow = ZO_CrossfadeBG_GetObject(self.crossfade)
    slideShow:StopSlideShow()
end

function ZO_PregameSlideShow_Initialize(control)
    PREGAME_SLIDESHOW_KEYBOARD = PregameSlideShow_Keyboard:New(control)
end

-- Controls the background during the login process, as well as the game version label
local LoginBG_Keyboard = ZO_Object:Subclass()

function LoginBG_Keyboard:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function LoginBG_Keyboard:Initialize(control)
    self.control = control

    self.gameVersionLabel = control:GetNamedChild("GameVersionLabel")
    self.accountRequired = control:GetNamedChild("AcctRequired")

    local briefVersion = GetESOVersionString()
    local fullVersion = GetESOFullVersionString()
    self.gameVersionLabel:SetText(zo_strformat(SI_VERSION, briefVersion))
    self.fullVersion = fullVersion

    self:RebuildRequiredAccountLabel()
    
    LOGIN_BG_FRAGMENT = ZO_FadeSceneFragment:New(control)
end

function LoginBG_Keyboard:GetFullVersion()
    return self.fullVersion
end

function LoginBG_Keyboard:RebuildRequiredAccountLabel()
    local requiresAccountLinking = IsUsingLinkedLogin()
    if not requiresAccountLinking then
        local url = select(5, GetPlatformInfo(GetSelectedPlatformIndex()))
        local linkText = GetString(SI_LOGIN_ACCOUNT_REQUIRED_ESO)
        local link = ZO_LinkHandler_CreateURLLink(url, linkText)
        local message = zo_strformat(SI_LOGIN_ACCOUNT_REQUIRED, link)
        self.accountRequired:SetText(message)
    end

    self.accountRequired:SetHidden(requiresAccountLinking)
end

function ZO_LoginBG_Initialize(control)
    LOGIN_BG_KEYBOARD = LoginBG_Keyboard:New(control)
end

function ZO_LoginBG_GameVersionLabel_OnMouseEnter(label)
    InitializeTooltip(InformationTooltip, label, BOTTOMLEFT, 0, -10, TOPLEFT)
    SetTooltipText(InformationTooltip, zo_strformat(SI_VERSION, LOGIN_BG_KEYBOARD:GetFullVersion()))
end

function ZO_LoginBG_GameVersionLabel_OnMouseExit()
    ClearTooltip(InformationTooltip)
end

-- Handles login related functionality (all regions)
local Login_Keyboard = ZO_LoginBase_Keyboard:Subclass()

function Login_Keyboard:New(...)
    return ZO_LoginBase_Keyboard.New(self, ...)
end

function Login_Keyboard:Initialize(control)
    ZO_LoginBase_Keyboard.Initialize(self, control)

    local requiresAccountLinking = IsUsingLinkedLogin()

    self.credentialsContainer = control:GetNamedChild("Credentials")
    self.accountName = self.credentialsContainer:GetNamedChild("AccountName")
    self.accountNameEdit = self.accountName:GetNamedChild("Edit")
    self.trustedSettingsBar = self.credentialsContainer:GetNamedChild("TrustedSettingsBar")
    self.rememberAccount = self.credentialsContainer:GetNamedChild("RememberAccount")
    self.rememberAccountButton = self.rememberAccount:GetNamedChild("Button")
    self.rememberAccountText = self.rememberAccount:GetNamedChild("Text")
    self.password = self.credentialsContainer:GetNamedChild("Password")
    self.passwordEdit = self.password:GetNamedChild("Edit")
    self.capsLockWarning = self.credentialsContainer:GetNamedChild("CapsLockWarning")
    self.loginButton = control:GetNamedChild("Login")
    self.loginButtonDisabledTimer = self.loginButton:GetNamedChild("DisabledTimer")
    self.announcements = control:GetNamedChild("Announcements")
    self.announcementsText = self.announcements:GetNamedChild("Text")
    self.relaunchGameLabel = control:GetNamedChild("RelaunchGameLabel")

    self.accountNameEdit:SetMaxInputChars(MAX_EMAIL_LENGTH)
    self.passwordEdit:SetMaxInputChars(MAX_PASSWORD_LENGTH)
    self:InitializeCredentialEditBoxes()

    ZO_PreHookHandler(self.passwordEdit, "OnTextChanged", function() self:UpdateLoginButtonState() end)
    ZO_PreHookHandler(self.accountNameEdit, "OnTextChanged", function() self:UpdateLoginButtonState() end)
    self:InitializeTrustedSettingsBar(self.trustedSettingsBar)
    self.capsLockWarning:SetHidden(not IsCapsLockOn())

    self.credentialsContainer:SetHidden(requiresAccountLinking)
    self:ReanchorLoginButton()
    self:ReanchorAnnouncements()

    control:SetHandler("OnUpdate", function(control, timeSeconds) self:OnUpdate(control, timeSeconds) end)

    self.attemptAutomaticLogin = requiresAccountLinking

    local function OnAnnouncementsResult(eventCode, success)
        local message = success and GetAnnouncementMessage() or GetString(SI_LOGIN_ANNOUNCEMENTS_FAILURE)

        if(message == "") then
            self.announcements:SetHidden(true)
        else
            self.announcements:SetHidden(false)
            self.announcementsText:SetText(message)
        end
    end

    local function OnEnterMaintenanceMode(eventCode, requeryTime)
        self:DisableLoginUntil(requeryTime)
        ZO_Dialogs_ReleaseAllDialogs(true)
        ZO_Dialogs_ShowDialog("SERVER_DOWN_FOR_MAINTENANCE")
    end

    local function UpdateForCaps(capsLockIsOn)
        self.capsLockWarning:SetHidden(not capsLockIsOn)
    end

    EVENT_MANAGER:RegisterForEvent("Login", EVENT_SCREEN_RESIZED, function() self:ResizeControls() end)
    EVENT_MANAGER:RegisterForEvent("Login", EVENT_ANNOUNCEMENTS_RESULT, OnAnnouncementsResult)
    EVENT_MANAGER:RegisterForEvent("Login", EVENT_SERVER_IN_MAINTENANCE_MODE, OnEnterMaintenanceMode)

    self.capsLockWarning:RegisterForEvent(EVENT_CAPS_LOCK_STATE_CHANGED, function(eventCode, capsLockIsOn) UpdateForCaps(capsLockIsOn) end)

    CALLBACK_MANAGER:RegisterCallback("AllDialogsHidden", function() self:InitializeLoginButtonState() end)
    LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_CLICKED_EVENT, OnLinkClicked)

    LOGIN_FRAGMENT = ZO_FadeSceneFragment:New(control)
    LOGIN_FRAGMENT:RegisterCallback("StateChange",  function(oldState, newState)
                                                        if(newState == SCENE_FRAGMENT_SHOWN) then
                                                            self:InitializeLoginButtonState()
                                                            self:AttemptAutomaticLogin()
                                                        end
                                                    end)

    local lastPlatformName = GetCVar("LastPlatform")
    for platformIndex = 0, GetNumPlatforms() do
        local platformName = GetPlatformInfo(platformIndex)
        if platformName ~= "" and platformName == lastPlatformName then
            SetSelectedPlatform(platformIndex)
            break
        end
    end
end

function Login_Keyboard:GetControl()
    return self.control
end

function Login_Keyboard:OnUpdate(control, timeSeconds)
    if(self.announcementRequestTime == nil or timeSeconds > self.announcementRequestTime) then
        self.announcementRequestTime = timeSeconds + ANNOUNCEMENTS_UPDATE_INTERVAL
        RequestAnnouncements()
    end
end

function Login_Keyboard:InitializeTrustedSettingsBar(bar)
    local menuBarData =
    {
        initialButtonAnchorPoint = RIGHT, 
        buttonTemplate = "ZO_LoginTrustedSettingsButton", 
        normalSize = 51,
        downSize = 64,
        buttonPadding = -15,
        animationDuration = 180,
    }

    ZO_MenuBar_SetData(bar, menuBarData)

    local function UpdateTrustedSetting(tabData)
        local trustedSetting = (tabData.descriptor == "trustedMachine") and 1 or 0
        SetCVar("IsTrustedMachine", trustedSetting)
        
        self.rememberAccount:SetHidden(trustedSetting == 0)
        if(trustedSetting == 0) then
            SetCVar("RememberAccountName", 0) -- only turn this off if the machine becomes untrusted...but the user always needs to re-enable it.
            ZO_CheckButton_SetCheckState(self.rememberAccountButton, false)
        end
    end

    local trustedFilter =
    {
        tooltipText = GetString(SI_TRUSTED_MACHINE_BUTTON_TOOLTIP),
        descriptor = "trustedMachine",
        normal = "EsoUI/Art/Login/authentication_trusted_up.dds", 
        pressed = "EsoUI/Art/Login/authentication_trusted_down.dds",
        highlight = "EsoUI/Art/Login/authentication_trusted_over.dds",
        callback = UpdateTrustedSetting,
    }

    local untrustedFilter =
    {
        tooltipText = GetString(SI_UNTRUSTED_MACHINE_BUTTON_TOOLTIP),
        descriptor = "untrustedMachine",
        normal = "EsoUI/Art/Login/authentication_public_up.dds", 
        pressed = "EsoUI/Art/Login/authentication_public_down.dds",
        highlight = "EsoUI/Art/Login/authentication_public_over.dds",
        callback = UpdateTrustedSetting,
    }

    ZO_MenuBar_AddButton(bar, untrustedFilter)
    ZO_MenuBar_AddButton(bar, trustedFilter)

    local isTrusted = GetCVar("IsTrustedMachine")

    if(tonumber(isTrusted) == 1) then
        ZO_MenuBar_SelectDescriptor(bar, "trustedMachine")
    else
        ZO_MenuBar_SelectDescriptor(bar, "untrustedMachine")
    end
end

function Login_Keyboard:GetEditControlStates()
    local accountEmpty = self.accountNameEdit:GetText() == ""
    local passwordEmpty = self.passwordEdit:GetText() == ""

    return accountEmpty, passwordEmpty
end

function Login_Keyboard:UpdateLoginButtonState()
    local loginReady = true

    if self.inMaintenanceMode then
        loginReady = false
    elseif IsUsingLinkedLogin() then
        loginReady = LOGIN_MANAGER_KEYBOARD:IsLoginPossible()
    else
        local accountEmpty, passwordEmpty = self:GetEditControlStates()
        loginReady = not (accountEmpty or passwordEmpty)
    end

    self.loginButton:SetEnabled(loginReady)
end

function Login_Keyboard:InitializeLoginButtonState(stateName)
    if(stateName == nil or stateName == "AccountLogin") then
        local accountEmpty = self:GetEditControlStates()

        if(not ZO_Dialogs_IsShowingDialog()) then
            if(not accountEmpty) then
                self.passwordEdit:TakeFocus()
            else
                self.accountNameEdit:TakeFocus()
            end
        end

        self:UpdateLoginButtonState()
    end
end

function Login_Keyboard:DisableLoginUntil(timeToEnable)
    self.inMaintenanceMode = true
    self.loginButton:SetEnabled(false)
    self.loginButtonDisabledTimer:SetHidden(false)

    local nextTimerUpdate = GetFrameTimeMilliseconds()
    
    local function EnableCheck()
        local now = GetFrameTimeMilliseconds()

        if(now >= timeToEnable) then
            self.inMaintenanceMode = false
            self:UpdateLoginButtonState()
            self.loginButton:SetHandler("OnUpdate", nil)
            self.loginButtonDisabledTimer:SetHidden(true)
            self.loginButtonDisabledTimer:SetText("")
        elseif(now >= nextTimerUpdate) then
            local timer
            timer, nextTimerUpdate = ZO_FormatTimeMilliseconds((timeToEnable - now), TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
            self.loginButtonDisabledTimer:SetText(zo_strformat(SI_SERVER_MAINTENANCE_LOGIN_BUTTON_TIMER, timer))
        end
    end

    self.loginButton:SetHandler("OnUpdate", EnableCheck)
end

function Login_Keyboard:InitializeCredentialEditBoxes(pullAccountNameFromCVar)
    if(pullAccountNameFromCVar == nil or pullAccountNameFromCVar == true) then
        if(GetCVar("RememberAccountName") == "1") then
            self.accountNameEdit:SetText(GetCVar("AccountName"))
        else
            self.accountNameEdit:SetText("")
        end
    end

    self.passwordEdit:SetText("")
end

function Login_Keyboard:GetAccountNameEdit()
    return self.accountNameEdit
end

function Login_Keyboard:GetPasswordEdit()
    return self.passwordEdit
end

function Login_Keyboard:AttemptLoginFromPasswordEdit()
    local state = self.loginButton:GetState()
    if(state == BSTATE_NORMAL) then
        self.passwordEdit:LoseFocus()
        self:DoLogin()
    end
end

function Login_Keyboard:AttemptAutomaticLogin()
    -- Only attempt an automatic login on first showing the Login screen
    if self.attemptAutomaticLogin then
        if not ZO_PREGAME_HAD_GLOBAL_ERROR then
            self:DoLogin()
        end
        self:ClearAttemptAutomaticLogin()
    end
end

function Login_Keyboard:ClearAttemptAutomaticLogin()
    self.attemptAutomaticLogin = false
end

function Login_Keyboard:DoLogin()
    if IsUsingLinkedLogin() then
        LOGIN_MANAGER_KEYBOARD:AttemptLinkedLogin()
    else
        PregameLogin(self.accountNameEdit:GetText(), self.passwordEdit:GetText())
        local DONT_PULL_ACCOUNT_NAME_FROM_CVAR = false
        self:InitializeCredentialEditBoxes(DONT_PULL_ACCOUNT_NAME_FROM_CVAR)
    end
    self.loginButton:SetState(BSTATE_DISABLED, true)
end

function Login_Keyboard:ShowRelaunchGameLabel()
    self:UpdateLoginButtonState()
    self.relaunchGameLabel:SetHidden(false)
end

function Login_Keyboard:ReanchorLoginButton()
    if IsUsingLinkedLogin() then
        -- Since the credentials container is hidden when using linked login, reanchor the login button to the 
        -- 'relaunch client' label 
        local isValid, point, _, relPoint, offsetX, offsetY = self.loginButton:GetAnchor(0)
        self.loginButton:ClearAnchors()

        self.loginButton:SetAnchor(point, self.relaunchGameLabel, relPoint, offsetX, offsetY)
    end
end

function Login_Keyboard:ReanchorAnnouncements()
    if IsUsingLinkedLogin() then
        local isValid0, point0, _, relPoint0, offsetX0, offsetY0 = self.announcements:GetAnchor(0)
        local isValid1, point1, _, relPoint1, offsetX1, offsetY1 = self.announcements:GetAnchor(1)
        self.announcements:ClearAnchors()
        
        self.announcements:SetAnchor(point0, self.relaunchGameLabel, relPoint0, offsetX0, offsetY0)
        self.announcements:SetAnchor(point1, self.relaunchGameLabel, relPoint1, offsetX1, offsetY1)
    end
end

-- XML Handlers --

function ZO_Login_Initialize(control)
    LOGIN_KEYBOARD = Login_Keyboard:New(control)
end

function ZO_Login_PasswordEdit_TakeFocus()
    LOGIN_KEYBOARD:GetPasswordEdit():TakeFocus()
end

function ZO_Login_AccountNameEdit_TakeFocus()
    LOGIN_KEYBOARD:GetAccountNameEdit():TakeFocus()
end

function ZO_Login_AttemptLoginFromPasswordEdit()
    LOGIN_KEYBOARD:AttemptLoginFromPasswordEdit()
end

function ZO_Login_LoginButton_OnClicked()
    LOGIN_KEYBOARD:DoLogin()
end

function ZO_Login_SetupCheckButton(control, cvarName)
    ZO_CheckButton_SetCheckState(control, GetCVar(cvarName))

    ZO_CheckButton_SetToggleFunction(control,  function()
                                                local bState = control:GetState()
                                                if(bState == BSTATE_PRESSED) then
                                                    SetCVar(cvarName, "1")
                                                else
                                                    SetCVar(cvarName, "0")
                                                end
                                            end)
end

function ZO_Login_TrustedSettings_OnMouseEnter(control)
    ZO_MenuBarButtonTemplate_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, -10)
    SetTooltipText(InformationTooltip, ZO_MenuBarButtonTemplate_GetData(control).tooltipText)
end

function ZO_Login_TrustedSettings_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
    ZO_MenuBarButtonTemplate_OnMouseExit(control)
end