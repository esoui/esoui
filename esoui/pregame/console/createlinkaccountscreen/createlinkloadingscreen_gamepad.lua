-- Main class.
local ZO_CreateLinkLoading_Gamepad = ZO_Object:Subclass()

function ZO_CreateLinkLoading_Gamepad:New(control)
    local object = ZO_Object.New(self)
    object:Initialize(control)
    return object
end

function ZO_CreateLinkLoading_Gamepad:Initialize(control)
    self.control = control
    self.registeredEvents = {}

    local createLinkLoadingScreen_Gamepad_Fragment = ZO_FadeSceneFragment:New(self.control)
    CREATE_LINK_LOADING_SCREEN_GAMEPAD_SCENE = ZO_Scene:New("CreateLinkLoadingScreen_Gamepad", SCENE_MANAGER)
    CREATE_LINK_LOADING_SCREEN_GAMEPAD_SCENE:AddFragment(createLinkLoadingScreen_Gamepad_Fragment)

    self.previousState = "AccountLogin"

    local StateChanged = function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:PerformDeferredInitialize()

            self:RegisterEvents()

            self:ResetQueuedBoxVisibility()

            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

            self.loginFunction()
            
        elseif newState == SCENE_HIDDEN then
            self:UnregisterEvents()

            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
        end
    end

    CREATE_LINK_LOADING_SCREEN_GAMEPAD_SCENE:RegisterCallback("StateChange", StateChanged)
end

function ZO_CreateLinkLoading_Gamepad:PerformDeferredInitialize()
    if self.initialized then return end
    self.initialized = true

    local baseControl = self.control:GetNamedChild("Container"):GetNamedChild("Base")

    self.queuedBox = baseControl:GetNamedChild("Queued")
    self.queuedLabel = self.queuedBox:GetNamedChild("Text")
    self.queuedStatusBar = self.queuedBox:GetNamedChild("StatusBar")

    self.loadingBox = baseControl:GetNamedChild("Loading")
    self.loadingText = self.loadingBox:GetNamedChild("Text")

    self:InitKeybindingDescriptor()
end

function ZO_CreateLinkLoading_Gamepad:InitKeybindingDescriptor()
    self.keybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function()
                PlaySound(SOUNDS.DIALOG_DECLINE)
                if self.previousState == "AccountLogin" then
                    CancelLogin()
                end
                PregameStateManager_SetState(self.previousState)
            end),
    }
end

local function OnSuccess()
    PregameStateManager_AdvanceState()
end

local function OnLoggedIn()
    RequestWorldList()
end

local function OnWorldListReceived()
    PregameStateManager_AdvanceState()
end

local function OnNoLink()
    PregameStateManager_SetState("CreateLinkAccount")
end

do
    local loginQueuedScene
    local currentLoginQueueWaitTime
    local lastQueuePosition

    local function GetLoginQueueApproximateWaitTime(waitTime, queuePosition)
        -- if our position increases, the ETA we have "locked" is no longer valid
        if (not currentLoginQueueWaitTime) or (queuePosition > lastQueuePosition) then
            currentLoginQueueWaitTime = zo_max(waitTime * 1000, 1000) -- minimum wait time is that last second...
            lastQueuePosition = queuePosition
        else
            currentLoginQueueWaitTime = zo_min(currentLoginQueueWaitTime, zo_max(waitTime * 1000, 1000))
        end

        return currentLoginQueueWaitTime
    end

    function ZO_CreateLinkLoading_Gamepad:OnQueued(eventCode, waitTime, queuePosition)
        waitTime = GetLoginQueueApproximateWaitTime(waitTime, queuePosition)

        self.loadingBox:SetHidden(true)
        self.queuedBox:SetHidden(false)
        self.queuedLabel:SetText(zo_strformat(SI_LOGIN_QUEUE_TEXT, ZO_FormatTimeMilliseconds(waitTime, TIME_FORMAT_STYLE_DESCRIPTIVE)))
        self.queuedStatusBar:SetMinMax(0, zo_max(lastQueuePosition, 1))
        self.queuedStatusBar:SetValue(lastQueuePosition - queuePosition)
    end

    function ZO_CreateLinkLoading_Gamepad:ResetQueuedBoxVisibility()
        self.loadingBox:SetHidden(false)
        self.queuedBox:SetHidden(true)
    end
end

local function OnCreateAccountFailure(eventId, failureReason)
    PREGAME_INITIAL_SCREEN_CONSOLE:ShowError(GetString(SI_CONSOLE_ERROR_GENERIC), zo_strformat(SI_CREATEACCOUNT_FAILURE_MESSAGE, failureReason))
end

local function OnLinkAccountFailure(eventId, failureReason)
    PREGAME_INITIAL_SCREEN_CONSOLE:ShowError(GetString(SI_CONSOLE_ERROR_GENERIC), zo_strformat(SI_LINKACCOUNT_FAILURE_MESSAGE, failureReason))
end

local function OnServerMaintenance(eventID, requeryTime)
    PREGAME_INITIAL_SCREEN_CONSOLE:ShowError(GetString(SI_SERVER_MAINTENANCE_DIALOG_TITLE), GetString(SI_SERVER_MAINTENANCE_DIALOG_TEXT))
end

local function OnAuthenticationDown()
    PREGAME_INITIAL_SCREEN_CONSOLE:ShowError(GetString(SI_DIALOG_TITLE_SERVER_UNAVAILABLE), GetString(SI_AUTHENTICATION_SERVER_DOWN))
end

local function OnServerLocked()
    PREGAME_INITIAL_SCREEN_CONSOLE:ShowError(GetString(SI_DIALOG_TITLE_SERVER_LOCKED), GetString(SI_SERVER_LOCKED))
end

local function OnInvalidCredentials(eventId, errorCode, accountPageURL)
    PREGAME_INITIAL_SCREEN_CONSOLE:ShowError(GetString(SI_CONSOLE_ERROR_GENERIC), GetString(SI_BAD_LOGIN))
end

local function OnPaymentExpired(eventId, errorCode, accountPageURL)
    PREGAME_INITIAL_SCREEN_CONSOLE:ShowError(GetString(SI_DIALOG_TITLE_PAYMENT_EXPIRED), GetString(SI_DIALOG_TEXT_PAYMENT_EXPIRED))
end

local function OnBadClientVersion()
    PREGAME_INITIAL_SCREEN_CONSOLE:ShowError(GetString(SI_BAD_CLIENT_VERSION_TITLE), GetString(SI_BAD_CLIENT_VERSION_TEXT))
end

local function OnGlobalError(eventID, errorCode, helpLinkURL, errorText)
    ZO_PREGAME_HAD_GLOBAL_ERROR = true

    local errorString, errorStringFormat

    if(errorCode ~= nil) then
        errorStringFormat = GetString("SI_GLOBALERRORCODE", errorCode)
    end

    if(errorStringFormat ~= "") then
        errorString = zo_strformat(errorStringFormat, errorText, GetString(SI_HELP_URL))
    else
        errorString = zo_strformat(SI_UNKNOWN_ERROR, GetString(SI_HELP_URL))
    end

    PREGAME_INITIAL_SCREEN_CONSOLE:ShowError(GetString(SI_PROMPT_TITLE_ERROR), errorString)
end

local function OnOTPPending(eventID, otpReason, otpType, otpDurationInSeconds)
    -- TODO: Is this a case that needs to be handled properly on console (and thus needs to be designed), or is this
    --  show a dialog good enough as its only needed for PC testing?
    PREGAME_INITIAL_SCREEN_CONSOLE:ShowError(GetString(SI_OTP_DIALOG_TITLE), GetString(SI_PROVIDE_OTP_INITIAL_DIALOG_TEXT))
end

local function OnCreateLinkLoadingError(eventId, loginError, linkingError, debugInfo)
    local dialogTitle = ""
    local dialogText = ""

    if loginError == LOGIN_AUTH_ERROR_SERVER_PSN_FREE_TRIAL_END then
        local MUST_PURCHASE_GAME = true
        PregameStateManager_SetState("GameStartup", MUST_PURCHASE_GAME)
        return
    end

    if(loginError ~= LOGIN_AUTH_ERROR_NO_ERROR) then
        dialogTitle = GetString(SI_LOGIN_DIALOG_TITLE_LOGIN_FAILED)
        dialogText = GetString("SI_LOGINAUTHERROR", loginError)
    elseif(linkingError ~= ACCOUNT_CREATE_LINK_ERROR_NO_ERROR) then
        dialogTitle = GetString(SI_LOGIN_DIALOG_TITLE_LINK_FAILED)
        dialogText = GetString("SI_ACCOUNTCREATELINKERROR", linkingError)
    end
    
    if(loginError == LOGIN_AUTH_ERROR_ACCOUNT_NOT_VERIFIED or loginError == LOGIN_AUTH_ERROR_GAME_ACCOUNT_NOT_VERIFIED or linkingError == ACCOUNT_CREATE_LINK_ERROR_ACCOUNT_NOT_VERIFIED) then
        PREGAME_INITIAL_SCREEN_CONSOLE:ShowEmailVerificationError(dialogTitle, dialogText)
        return
    end

    if(dialogText == "") then
        -- generic error message
        dialogTitle = GetString(SI_LOGIN_DIALOG_TITLE_LOGIN_FAILED)
        dialogText = GetString(SI_UNEXPECTED_ERROR)
    end

    if not LINK_ACCOUNT_GAMEPAD:IsAccountValidForLinking(linkingError) then
        LINK_ACCOUNT_GAMEPAD:ClearCredentials()
    end

    local errorString = zo_strformat(dialogText, GetString(SI_HELP_URL))
    -- debugInfo will be empty in public, non-debug builds
    PREGAME_INITIAL_SCREEN_CONSOLE:ShowError(dialogTitle, errorString .. debugInfo)
end

function ZO_CreateLinkLoading_Gamepad:RegisterForEvent(eventId, callback)
    table.insert(self.registeredEvents, eventId)
    self.control:RegisterForEvent(eventId, callback)
end

function ZO_CreateLinkLoading_Gamepad:RegisterEvents()
    -- "Success" Cases
    self:RegisterForEvent(EVENT_LOGIN_SUCCESSFUL, OnLoggedIn)
    self:RegisterForEvent(EVENT_WORLD_LIST_RECEIVED, OnWorldListReceived)
    self:RegisterForEvent(EVENT_ACCOUNT_LINK_SUCCESSFUL, OnSuccess)
    self:RegisterForEvent(EVENT_ACCOUNT_CREATE_SUCCESSFUL, OnSuccess)

    self:RegisterForEvent(EVENT_PROFILE_NOT_LINKED, OnNoLink)

    self:RegisterForEvent(EVENT_LOGIN_QUEUED, function(...) self:OnQueued(...) end)

    self:RegisterForEvent(EVENT_COUNTRY_DATA_LOADED, function() 
                                                        CREATE_ACCOUNT_GAMEPAD:PerformDeferredInitialize() 
                                                        PregameStateManager_AdvanceState()
                                                     end)
    -- NOTE: Overflow is not handled here as, according to the console
    --   services guys, it is not supported on console.

    -- Error Cases
    -- TODO: Any additional error cases that should be handled?
    self:RegisterForEvent(EVENT_GLOBAL_ERROR, OnGlobalError)

    self:RegisterForEvent(EVENT_SERVER_IN_MAINTENANCE_MODE, OnServerMaintenance)
    self:RegisterForEvent(EVENT_LOGIN_FAILED_AUTHENTICATION_DOWN, OnAuthenticationDown)

    self:RegisterForEvent(EVENT_SERVER_LOCKED, OnServerLocked)
    self:RegisterForEvent(EVENT_LOGIN_FAILED_INVALID_CREDENTIALS, OnInvalidCredentials)
    self:RegisterForEvent(EVENT_LOGIN_OTP_PENDING, OnOTPPending)

    self:RegisterForEvent(EVENT_BAD_CLIENT_VERSION, OnBadClientVersion)

    self:RegisterForEvent(EVENT_CREATE_LINK_LOADING_ERROR, OnCreateLinkLoadingError)

    -- Misc.
    RegisterForLoadingUpdates()
end

function ZO_CreateLinkLoading_Gamepad:UnregisterEvents()
    for i=1, #self.registeredEvents do
        local eventId = self.registeredEvents[i]
        self.control:UnregisterForEvent(eventId)
    end

    self.registeredEvents = {}
end

function ZO_CreateLinkLoading_Gamepad:SetImagesFragment(fragment)
    if fragment == self.imagesFragment then return end

    if self.imagesFragment then
        CREATE_LINK_LOADING_SCREEN_GAMEPAD_SCENE:RemoveFragment(self.imagesFragment)
    end
    if fragment then
        CREATE_LINK_LOADING_SCREEN_GAMEPAD_SCENE:AddFragment(fragment)
    end
    self.imagesFragment = fragment
end

function ZO_CreateLinkLoading_Gamepad:SetBackgroundFragment(fragment)
    if fragment == self.backgroundFragment then return end

    if self.backgroundFragment then
        CREATE_LINK_LOADING_SCREEN_GAMEPAD_SCENE:RemoveFragment(self.backgroundFragment)
    end
    if fragment then
        CREATE_LINK_LOADING_SCREEN_GAMEPAD_SCENE:AddFragment(fragment)
    end
    self.backgroundFragment = fragment
end

function ZO_CreateLinkLoading_Gamepad:Show(previousState, loginFunction, loadingText, backgroundFragment, imagesFragment)
    self:PerformDeferredInitialize()

    self.previousState = previousState
    self.loginFunction = loginFunction
    self.loadingText:SetText(loadingText)

    if backgroundFragment then
        self:SetBackgroundFragment(backgroundFragment)
    end
    if imagesFragment then
        self:SetImagesFragment(imagesFragment)
    end

    SCENE_MANAGER:Show("CreateLinkLoadingScreen_Gamepad")
end

function CreateLinkLoadingScreen_Gamepad_Initialize(self)
    CREATE_LINK_LOADING_SCREEN_GAMEPAD = ZO_CreateLinkLoading_Gamepad:New(self)
end
