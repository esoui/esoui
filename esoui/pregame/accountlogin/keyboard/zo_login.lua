local ANNOUNCEMENTS_UPDATE_INTERVAL = 60
local ANNOUNCEMENTS_START_SCROLL_TIME = 10
local ANNOUNCEMENTS_TICKER_VELOCITY = 0.05

local function RequestOpenURL(url, text)
    local urlApplication = SI_URL_APPLICATION_WEB
    if url:find("mailto:", 1, true) then
        urlApplication = SI_URL_APPLICATION_MAIL
    end
    ZO_Dialogs_ShowDialog("CONFIRM_OPEN_URL", {url = url}, {mainTextParams = {text, GetString(urlApplication)}})
end

local function OnLinkClicked(link, button, text, color, linkType, ...)
    if not ZO_PEGI_IsDeclineNotificationShowing() and linkType == URL_LINK_TYPE then
        local url = table.concat({...}, ':')
        if IsHeronUI() then
            ConfirmOpenURL(url)
        else
            RequestOpenURL(url, text)
        end
        return true
    end
end

-- Controls the pregame background
local PregameBackground_Keyboard = ZO_Object:Subclass()

function PregameBackground_Keyboard:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function PregameBackground_Keyboard:Initialize(control)
    self.control = control
    self.background = control:GetNamedChild("Background")

    ZO_ResizeControlForBestScreenFit(self.background)

    PREGAME_BACKGROUND_FRAGMENT = ZO_SimpleSceneFragment:New(control)
end

function ZO_PregameBackground_Keyboard_Initialize(control)
    PREGAME_BACKGROUND_KEYBOARD = PregameBackground_Keyboard:New(control)
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

    LOGIN_BG_FRAGMENT = ZO_FadeSceneFragment:New(control)
end

function ZO_LoginBG_Initialize(control)
    LOGIN_BG_KEYBOARD = LoginBG_Keyboard:New(control)
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
    self.helpButton = self.credentialsContainer:GetNamedChild("Help")
    self.trustedSettingsBar = self.credentialsContainer:GetNamedChild("TrustedSettingsBar")
    self.rememberAccount = self.credentialsContainer:GetNamedChild("RememberAccount")
    self.rememberAccountButton = self.rememberAccount:GetNamedChild("Button")
    self.rememberAccountText = self.rememberAccount:GetNamedChild("Text")
    self.password = self.credentialsContainer:GetNamedChild("Password")
    self.capsLockWarning = self.credentialsContainer:GetNamedChild("CapsLockWarning")
    self.loginButton = control:GetNamedChild("Login")
    self.loginButtonDisabledTimer = self.loginButton:GetNamedChild("DisabledTimer")
    self.announcements = control:GetNamedChild("Announcements")
    self.announcementsScroll = self.announcements:GetNamedChild("TickerScroll")
    self.announcementsLabel = self.announcementsScroll:GetNamedChild("Text")
    self.serverAlert = control:GetNamedChild("ServerAlert")
    self.serverAlertLabel = self.serverAlert:GetNamedChild("Text")
    self.serverAlertImage = self.serverAlert:GetNamedChild("AlertImage")
    self.relaunchGameLabel = control:GetNamedChild("RelaunchGameLabel")

    self.accountNameEdit = ZO_EditBox:New(self.accountName)
    self.passwordEdit = ZO_EditBox:New(self.password)
    self.accountNameEdit:SetEmptyText(GetString(SI_ACCOUNT_NAME))
    self.passwordEdit:SetEmptyText(GetString(SI_PASSWORD))
    self:InitializeCredentialEditBoxes()

    self.passwordEdit:GetEditControl():SetHandler("OnTextChanged", function() self:UpdateLoginButtonState() end, "ZO_Login")
    self.accountNameEdit:GetEditControl():SetHandler("OnTextChanged", function() self:UpdateLoginButtonState() end, "ZO_Login")
    self:InitializeTrustedSettingsBar(self.trustedSettingsBar)
    self.capsLockWarning:SetHidden(not IsCapsLockOn())

    self.credentialsContainer:SetHidden(requiresAccountLinking)
    self:ReanchorLoginButton()

    self.startTickerTimeS = math.huge
    self.translateAnimationTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ScrollAnnouncementTickerAnimation", self.announcementsLabel)
    self.fadeInAnimationTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ScrollAnnouncementFadeInAnimation", self.announcementsLabel)

    local function OnMouseEnterHelp(label)
        InitializeTooltip(InformationTooltip, label, BOTTOM, 0, -10, TOP)
        SetTooltipText(InformationTooltip, GetString(SI_LOGIN_HELP_TOOLTIP))
    end

    local function OnMouseExitHelp()
        ClearTooltip(InformationTooltip)
    end

    local function OnClickedHelp()
        local requiresAccountLinking = IsUsingLinkedLogin()
        if not requiresAccountLinking then
            local url = select(5, GetPlatformInfo(GetSelectedPlatformIndex()))
            local text = GetString(SI_LOGIN_ACCOUNT_REQUIRED_ESO)
            RequestOpenURL(url, text)
        end
    end

    control:SetHandler("OnUpdate", function(control, timeSeconds) self:OnUpdate(control, timeSeconds) end)

    self.helpButton:SetHandler("OnMouseEnter", OnMouseEnterHelp)
    self.helpButton:SetHandler("OnMouseExit", OnMouseExitHelp)
    self.helpButton:SetHandler("OnClicked", OnClickedHelp)

    local function OnAnnouncementsResult(eventCode, success)
        local message = success and GetAnnouncementMessage() or GetString(SI_LOGIN_ANNOUNCEMENTS_FAILURE)

        if message == "" then
            self.announcements:SetHidden(true)
        else
            self.announcements:SetHidden(false)
            self.announcementsText = message
            self.announcementsLabel:SetText(message)
        end

        local serverAlertMessage = success and GetServerAlertMessage()
        if serverAlertMessage and serverAlertMessage ~= "" then
            self.serverAlert:SetHidden(false)
            self.serverAlertImage:SetTexture("EsoUI/Art/Login/login_icon_yield.dds")
            self.serverAlertLabel:SetFont("ZoFontGameBold")
            self.serverAlertLabel:SetText(serverAlertMessage)
        else
            local serverNoticeMessage = success and GetServerNoticeMessage()
            if serverNoticeMessage and serverNoticeMessage ~= "" then
                self.serverAlert:SetHidden(false)
                self.serverAlertImage:SetTexture("EsoUI/Art/Login/login_icon_info.dds")
                self.serverAlertLabel:SetFont("ZoFontGame")
                self.serverAlertLabel:SetText(serverNoticeMessage)
            else
                self.serverAlert:SetHidden(true)
            end
        end

        if IsUsingLinkedLogin() then
            self.shouldShowServerAlert = not self.serverAlert:IsHidden()
            self.serverAlert:SetHidden(true)
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
                                                        if newState == SCENE_FRAGMENT_SHOWN then
                                                            self:InitializeLoginButtonState()
                                                            self:AttemptAutomaticLogin()
                                                            if ZO_RZCHROMA_EFFECTS then
                                                                ZO_RZCHROMA_EFFECTS:SetAlliance(ALLIANCE_NONE)
                                                            end
                                                            self.startTickerTimeS = GetFrameTimeSeconds() + ANNOUNCEMENTS_START_SCROLL_TIME
                                                        end
                                                    end)

    local dialogControl = ZO_Login_Announcement_Dialog_Keyboard
    local announcementDialogInfo =
    {
        customControl = dialogControl,
        canQueue = true,
        title =
        {
            text = SI_LOGIN_ANNOUNCEMENTS_TITLE
        },
        setup = function(dialog)
            local textControl = dialog:GetNamedChild("ContainerText")
            textControl:SetText(self.announcementsText)
        end,
        buttons =
        {
            {
                control = dialogControl:GetNamedChild("Close"),
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CLOSE,
            },
        }
    }

    ZO_Dialogs_RegisterCustomDialog("Announcement_Dialog", announcementDialogInfo)

    local OnLinkClicked = function(link, button, text, color, linkType, ...)
        if ZO_Dialogs_IsShowing("Announcement_Dialog") then
            -- Need to release the Announcement dialog so that the CONFIRM_OPEN_URL dialog will be shown
            ZO_Dialogs_ReleaseDialog("Announcement_Dialog")
            self.isShowingLinkConfirmation = true
            return true
        end
    end

    local OnAllDialogsHidden = function()
        if self.isShowingLinkConfirmation then
            ZO_Dialogs_ShowDialog("Announcement_Dialog")
            self.isShowingLinkConfirmation = false
        end
    end

    LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_CLICKED_EVENT, OnLinkClicked)
    CALLBACK_MANAGER:RegisterCallback("AllDialogsHidden", OnAllDialogsHidden)

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

function Login_Keyboard:SetLoginButtonHidden(isHidden)
    return self.loginButton:SetHidden(isHidden)
end

function Login_Keyboard:OnUpdate(control, timeSeconds)
    if self.announcementRequestTime == nil or timeSeconds > self.announcementRequestTime then
        self.announcementRequestTime = timeSeconds + ANNOUNCEMENTS_UPDATE_INTERVAL
        RequestAnnouncements()
    end

    if self.startTickerTimeS <= timeSeconds then
        local textWidth = self.announcementsLabel:GetTextWidth()
        if textWidth > self.announcementsScroll:GetWidth() then
            local translateAnimation = self.translateAnimationTimeline:GetAnimation(1)
            translateAnimation:SetTranslateOffsets(0, 0, -textWidth, 0)
            translateAnimation:SetDuration(textWidth / ANNOUNCEMENTS_TICKER_VELOCITY)
            translateAnimation:SetHandler("OnStop", function()
                if not self.hasDoneTranslateStop then
                    self.hasDoneTranslateStop = true
                    self.startTickerTimeS = math.huge
                    self.translateAnimationTimeline:PlayInstantlyToStart()

                    local fadeInAnimation = self.fadeInAnimationTimeline:GetAnimation(1)
                    fadeInAnimation:SetHandler("OnStop", function()
                        self.startTickerTimeS = GetFrameTimeSeconds() + ANNOUNCEMENTS_START_SCROLL_TIME
                    end)
                    self.fadeInAnimationTimeline:PlayFromStart()
                end
            end)

            self.translateAnimationTimeline:PlayFromStart()
            self.hasDoneTranslateStop = nil
            self.startTickerTimeS = math.huge
        end
    end
end

function Login_Keyboard:InitializeTrustedSettingsBar(bar)
    local menuBarData =
    {
        initialButtonAnchorPoint = RIGHT,
        buttonTemplate = "ZO_LoginTrustedSettingsButton",
        normalSize = 32,
        downSize = 40,
        buttonPadding = 0,
        animationDuration = 180,
    }

    ZO_MenuBar_SetData(bar, menuBarData)

    local function UpdateTrustedSetting(tabData)
        local trustedSetting = tabData.descriptor == "trustedMachine" and 1 or 0
        SetCVar("IsTrustedMachine", trustedSetting)

        self.rememberAccount:SetHidden(trustedSetting == 0)
        if trustedSetting == 0 then
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

    if tonumber(isTrusted) == 1 then
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
    if stateName == nil or stateName == "AccountLogin" then
        local accountEmpty = self:GetEditControlStates()

        if not ZO_Dialogs_IsShowingDialog() then
            if not accountEmpty then
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

        if now >= timeToEnable then
            self.inMaintenanceMode = false
            self:UpdateLoginButtonState()
            self.loginButton:SetHandler("OnUpdate", nil)
            self.loginButtonDisabledTimer:SetHidden(true)
            self.loginButtonDisabledTimer:SetText("")
        elseif now >= nextTimerUpdate then
            local timer
            timer, nextTimerUpdate = ZO_FormatTimeMilliseconds((timeToEnable - now), TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
            self.loginButtonDisabledTimer:SetText(zo_strformat(SI_SERVER_MAINTENANCE_LOGIN_BUTTON_TIMER, timer))
        end
    end

    self.loginButton:SetHandler("OnUpdate", EnableCheck)
end

function Login_Keyboard:InitializeCredentialEditBoxes(pullAccountNameFromCVar)
    if pullAccountNameFromCVar == nil or pullAccountNameFromCVar == true then
        if GetCVar("RememberAccountName") == "1" then
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
    if state == BSTATE_NORMAL then
        self.passwordEdit:LoseFocus()
        self:DoLogin()
    end
end

function Login_Keyboard:AttemptAutomaticLogin()
    -- Only attempt an automatic login on first showing the Login screen
    if ShouldAttemptAutoLogin() and not ZO_PREGAME_HAD_GLOBAL_ERROR then
        self:DoLogin()
    end
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
    self.mustRelaunchGame = true
    self:ReanchorLoginButton()
end

function Login_Keyboard:ReanchorLoginButton()
    if IsUsingLinkedLogin() then
        --Credentials is hidden, so move to be more centered in the available space
        self.loginButton:ClearAnchors()
        if self.mustRelaunchGame then
            self.loginButton:SetAnchor(TOP, self.relaunchGameLabel, BOTTOM, 0, 100)
        else
            self.loginButton:SetAnchor(CENTER, self.credentialsContainer, CENTER, 0, -50)
        end
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

function ZO_Login_Announcemnt_OnMouseUp()
    if not ZO_Dialogs_IsShowingDialog() then
        ZO_Dialogs_ShowDialog("Announcement_Dialog")
    end
end

function ZO_Login_SetupCheckButton(control, cvarName, labelText)
    ZO_CheckButton_SetLabelText(control, labelText)
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