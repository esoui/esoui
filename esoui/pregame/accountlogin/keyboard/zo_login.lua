local g_announcementRequestTime
local ANNOUNCEMENTS_UPDATE_INTERVAL = 60

local function ResizeLoginControls()
    ZO_ReanchorControlForLeftSidePanel(ZO_LoginBGMunge)
end

local function OnAnnouncementsResult(eventCode, success)
    local message
    if(success) then
        message = GetAnnouncementMessage()
    else
        message = GetString(SI_LOGIN_ANNOUNCEMENTS_FAILURE)
    end

    if(message == "") then
        ZO_LoginAnnouncements:SetHidden(true)
    else
        ZO_LoginAnnouncements:SetHidden(false)
        ZO_LoginAnnouncementsText:SetText(message)
    end
end

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

local function InitializeTrustedSettingsBar(bar)
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
        
        ZO_LoginRememberAccount:SetHidden(trustedSetting == 0)
        if(trustedSetting == 0) then
            SetCVar("RememberAccountName", 0) -- only turn this off if the machine becomes untrusted...but the user always needs to re-enable it.
            ZO_CheckButton_SetCheckState(ZO_LoginRememberAccountButton, false)
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

function ZO_Login_BeginSlideShow()
    local slideShow = ZO_CrossfadeBG_GetObject(ZO_PregameSlideShowCrossfade)
    slideShow:PlaySlideShow(20000,  "esoui/art/loadingscreens/LoadScreen_Wrothgar_01.dds",
                                    "esoui/art/loadingscreens/LoadScreen_Ayleid_04.dds",
                                    "esoui/art/loadingscreens/Loadscreen_Bankorai_01.dds",
                                    "esoui/art/loadingscreens/LoadScreen_BleakRock_01.dds",
                                    "esoui/art/loadingscreens/LoadScreen_Cyrodiil_01.dds",
                                    "esoui/art/loadingscreens/LoadScreen_Dwemer_01.dds",
                                    "esoui/art/loadingscreens/LoadScreen_Glenumbra_01.dds",
                                    "esoui/art/loadingscreens/Loadscreen_HelRaCitadel_01.dds",
                                    "esoui/art/loadingscreens/LoadScreen_Outlaw_Refuge_Nedic_01.dds",
                                    "esoui/art/loadingscreens/LoadScreen_Stonefalls_01.dds")
end

function ZO_Login_StopSlideShow()
    local slideShow = ZO_CrossfadeBG_GetObject(ZO_PregameSlideShowCrossfade)
    slideShow:StopSlideShow()
end

function ZO_Login_OnUpdate(self, time)
    if(g_announcementRequestTime == nil or time > g_announcementRequestTime) then
        g_announcementRequestTime = time + ANNOUNCEMENTS_UPDATE_INTERVAL
        RequestAnnouncements()
    end
end

function ZO_Login_SetupCheckButton(self, cvarName)
    ZO_CheckButton_SetCheckState(self, GetCVar(cvarName))

    ZO_CheckButton_SetToggleFunction(self,  function()
                                                local bState = self:GetState()
                                                if(bState == BSTATE_PRESSED) then
                                                    SetCVar(cvarName, "1")
                                                else
                                                    SetCVar(cvarName, "0")
                                                end
                                            end)
end

local function GetEditControlStates()
    local accountEmpty = ZO_LoginAccountNameEdit:GetText() == ""
    local passwordEmpty = ZO_LoginPasswordEdit:GetText() == ""

    return accountEmpty, passwordEmpty
end

local inMaintenanceMode = false

local function UpdateLoginButtonState()
    local accountEmpty, passwordEmpty = GetEditControlStates()
    ZO_LoginLogin:SetEnabled(not inMaintenanceMode and not (accountEmpty or passwordEmpty))
end

local function InitializeLoginButtonState(stateName)
    if(stateName == nil or stateName == "AccountLogin") then
        local accountEmpty = GetEditControlStates()

        if(not ZO_Dialogs_IsShowingDialog()) then
            if(not accountEmpty) then
                ZO_LoginPasswordEdit:TakeFocus()
            else
                ZO_LoginAccountNameEdit:TakeFocus()
            end
        end

        UpdateLoginButtonState()
    end
end

local function DisableLoginUntil(timeToEnable)
    inMaintenanceMode = true
    ZO_LoginLogin:SetEnabled(false)
    ZO_LoginLoginDisabledTimer:SetHidden(false)

    local nextTimerUpdate = GetFrameTimeMilliseconds()
    
    local function EnableCheck()
        local now = GetFrameTimeMilliseconds()

        if(now >= timeToEnable) then
            inMaintenanceMode = false
            UpdateLoginButtonState()
            ZO_LoginLogin:SetHandler("OnUpdate", nil)
            ZO_LoginLoginDisabledTimer:SetHidden(true)
            ZO_LoginLoginDisabledTimer:SetText("")
        elseif(now >= nextTimerUpdate) then
            local timer
            timer, nextTimerUpdate = ZO_FormatTimeMilliseconds((timeToEnable - now), TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
            ZO_LoginLoginDisabledTimer:SetText(zo_strformat(SI_SERVER_MAINTENANCE_LOGIN_BUTTON_TIMER, timer))
        end
    end

    ZO_LoginLogin:SetHandler("OnUpdate", EnableCheck)
end

local function OnEnterMaintenanceMode(eventId, requeryTime)
    DisableLoginUntil(requeryTime)
    ZO_Dialogs_ReleaseAllDialogs(true)
    ZO_Dialogs_ShowDialog("SERVER_DOWN_FOR_MAINTENANCE")
end

function ZO_Login_InitializeCredentialEditBoxes(pullAccountNameFromCVar)
    if(pullAccountNameFromCVar == nil or pullAccountNameFromCVar == true) then
        if(GetCVar("RememberAccountName") == "1") then
            ZO_LoginAccountNameEdit:SetText(GetCVar("AccountName"))
        else
            ZO_LoginAccountNameEdit:SetText("")
        end
    end

    ZO_LoginPasswordEdit:SetText("")
end

function ZO_Login_DoLogin(accountEdit, passwordEdit)
    PregameLogin(accountEdit:GetText(), passwordEdit:GetText())
    local pullAccountNameFromCVar = false
    ZO_Login_InitializeCredentialEditBoxes(pullAccountNameFromCVar)
end

function ZO_Login_TrustedSettingsOnMouseEnter(self)
    ZO_MenuBarButtonTemplate_OnMouseEnter(self)
    InitializeTooltip(InformationTooltip, self, BOTTOM, 0, -10)
    SetTooltipText(InformationTooltip, ZO_MenuBarButtonTemplate_GetData(self).tooltipText)
end

function ZO_Login_TrustedSettingsOnMouseExit(self)
    ClearTooltip(InformationTooltip)
    ZO_MenuBarButtonTemplate_OnMouseExit(self)
end

function ZO_Login_Initialize()
    ZO_LoginAccountNameEdit:SetMaxInputChars(MAX_EMAIL_LENGTH)
    ZO_LoginPasswordEdit:SetMaxInputChars(MAX_PASSWORD_LENGTH)
    ZO_Login_InitializeCredentialEditBoxes()
    ZO_PreHookHandler(ZO_LoginPasswordEdit, "OnTextChanged", UpdateLoginButtonState)
    ZO_PreHookHandler(ZO_LoginAccountNameEdit, "OnTextChanged", UpdateLoginButtonState)
    InitializeTrustedSettingsBar(ZO_LoginTrustedSettingsBar)

    local briefVersion, fullVersion = GetESOVersionString()
    ZO_LoginBGGameVersionLabel:SetText(zo_strformat(SI_VERSION, briefVersion))
    ZO_LoginBGGameVersionLabel.fullVersion = fullVersion

    EVENT_MANAGER:RegisterForEvent("Login", EVENT_SCREEN_RESIZED, ResizeLoginControls)
    EVENT_MANAGER:RegisterForEvent("Login", EVENT_ANNOUNCEMENTS_RESULT, OnAnnouncementsResult)
    EVENT_MANAGER:RegisterForEvent("Login", EVENT_SERVER_IN_MAINTENANCE_MODE, OnEnterMaintenanceMode)

    CALLBACK_MANAGER:RegisterCallback("AllDialogsHidden", InitializeLoginButtonState)
    LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_CLICKED_EVENT, OnLinkClicked)

    LOGIN_FRAGMENT = ZO_FadeSceneFragment:New(ZO_Login)
    LOGIN_BG_FRAGMENT = ZO_FadeSceneFragment:New(ZO_LoginBG)
    PREGAME_SLIDE_SHOW_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_PregameSlideShow)

    LOGIN_FRAGMENT:RegisterCallback("StateChange",  function(oldState, newState)
                                                        if(newState == SCENE_FRAGMENT_SHOWN) then
                                                            InitializeLoginButtonState()
                                                        end
                                                    end) 

    ResizeLoginControls()
end

function ZO_Login_RebuildRequiredAccountLabel()
    local label = ZO_LoginBGAcctRequired
    local _, _, _, _, _, _, _, url = GetPlatformInfo(GetSelectedPlatformIndex())
    local linkText = GetString(SI_LOGIN_ACCOUNT_REQUIRED_ESO)
    local link = ZO_LinkHandler_CreateURLLink(url, linkText)
    local message = zo_strformat(SI_LOGIN_ACCOUNT_REQUIRED, link)
    label:SetText(message)
end

function ZO_Login_RequiredAccountOnOnInitialized()
    ZO_Login_RebuildRequiredAccountLabel()
end