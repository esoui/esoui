-- Main class.
local ZO_CreateLinkLoading_Gamepad = ZO_InitializingObject:Subclass()

function ZO_CreateLinkLoading_Gamepad:Initialize(control)
    self.control = control
    self.registeredEvents = {}

    local createLinkLoadingScreen_Gamepad_Fragment = ZO_FadeSceneFragment:New(self.control)
    CREATE_LINK_LOADING_SCREEN_GAMEPAD_SCENE = ZO_Scene:New("CreateLinkLoadingScreen_Gamepad", SCENE_MANAGER)
    CREATE_LINK_LOADING_SCREEN_GAMEPAD_SCENE:AddFragment(createLinkLoadingScreen_Gamepad_Fragment)

    self.previousState = "AccountLogin"

    local function StateChanged(oldState, newState)
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

    self:InitializeOtpDialog()
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

-- There's a window between when EVENT_WORLD_SELECTED and EVENT_LOGIN_SUCCESSFUL are sent where 
-- the user could attempt to cancel Login but fail to.  That leads to undesirable results in the
-- interface in Loading or Character Select.
-- Prevent this by disabling the Back/Cancel button during that window.
function ZO_CreateLinkLoading_Gamepad:OnWorldSelected(eventFlags, worldName)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

local function OnServerMaintenance(eventID, requeryTime)
    PREGAME_INITIAL_SCREEN_GAMEPAD:ShowError(GetString(SI_SERVER_MAINTENANCE_DIALOG_TITLE), GetString(SI_SERVER_MAINTENANCE_DIALOG_TEXT))
end

local function OnServerLocked()
    PREGAME_INITIAL_SCREEN_GAMEPAD:ShowError(GetString(SI_DIALOG_TITLE_SERVER_LOCKED), GetString(SI_SERVER_LOCKED))
end

local function OnInvalidCredentials(eventId, errorCode, accountPageURL)
    local titleStringId, descriptionString
    if errorCode == AUTHENTICATION_ERROR_ACCOUNT_BANNED then
        titleStringId = SI_LOGIN_DIALOG_TITLE_ACCOUNT_BANNED
        local url = GetURLTextByType(APPROVED_URL_ESO_HELP)
        descriptionString = zo_strformat(GetString("SI_LOGINAUTHERROR", LOGIN_AUTH_ERROR_ACCOUNT_BANNED), url)
    elseif errorCode == AUTHENTICATION_ERROR_ACCOUNT_SUSPENDED then
        titleStringId = SI_LOGIN_DIALOG_TITLE_ACCOUNT_SUSPENDED
        local url = GetURLTextByType(APPROVED_URL_ESO_HELP)
        descriptionString = zo_strformat(GetString("SI_LOGINAUTHERROR", LOGIN_AUTH_ERROR_ACCOUNT_SUSPENDED), url)
    else
        titleStringId = SI_GAMEPAD_GENERIC_LOGIN_ERROR
        descriptionString = GetString((GetPlatformServiceType() == PLATFORM_SERVICE_TYPE_ZOS) and SI_BAD_LOGIN_ZOS or SI_BAD_LOGIN_FIRST_PARTY)
    end
    PREGAME_INITIAL_SCREEN_GAMEPAD:ShowError(GetString(titleStringId), descriptionString)
end

local function OnBadClientVersion()
    PREGAME_INITIAL_SCREEN_GAMEPAD:ShowError(GetString(SI_BAD_CLIENT_VERSION_TITLE), GetString(SI_BAD_CLIENT_VERSION_TEXT))
end

local function OnGlobalError(eventID, errorCode, helpLinkURL, errorText)
    ZO_PREGAME_HAD_GLOBAL_ERROR = true

    local errorString, errorStringFormat

    if errorCode ~= nil then
        errorStringFormat = GetString("SI_GLOBALERRORCODE", errorCode)
    end

    if errorStringFormat ~= "" then
        errorString = zo_strformat(errorStringFormat, errorText, GetURLTextByType(APPROVED_URL_ESO_HELP))
    else
        errorString = zo_strformat(SI_UNKNOWN_ERROR, GetURLTextByType(APPROVED_URL_ESO_HELP))
    end

    PREGAME_INITIAL_SCREEN_GAMEPAD:ShowError(GetString(SI_PROMPT_TITLE_ERROR), errorString)
end

local function OnOTPPending(eventID, otpReason, otpType, otpDurationInSeconds)
    local otpDurationMs = otpDurationInSeconds * 1000
    local otpExpirationMs = GetFrameTimeMilliseconds() + otpDurationMs

    ZO_Dialogs_ReleaseAllDialogs(true)
    ZO_Dialogs_ShowGamepadDialog("PROVIDE_OTP_INITIAL_GAMEPAD", { otpExpirationMs = otpExpirationMs, otpReason = otpReason })
end

local function OnCreateLinkLoadingError(eventId, loginError, linkingError, debugInfo)
    local dialogTitle = ""
    local errorString = ""
    local formattedErrorString

    if loginError == LOGIN_AUTH_ERROR_SERVER_PSN_FREE_TRIAL_END then
        local PSN_FREE_TRIAL_END = true
        PregameStateManager_SetState("GameStartup", PSN_FREE_TRIAL_END)
        return
    end

    if loginError ~= LOGIN_AUTH_ERROR_NO_ERROR then
        if loginError == LOGIN_AUTH_ERROR_ACCOUNT_BANNED or loginError == LOGIN_AUTH_ERROR_GAME_ACCOUNT_BANNED then
            dialogTitle = GetString(SI_LOGIN_DIALOG_TITLE_ACCOUNT_BANNED)
        elseif loginError == LOGIN_AUTH_ERROR_ACCOUNT_SUSPENDED or loginError == LOGIN_AUTH_ERROR_GAME_ACCOUNT_SUSPENDED then
            dialogTitle = GetString(SI_LOGIN_DIALOG_TITLE_ACCOUNT_SUSPENDED)
        else
            dialogTitle = GetString(SI_LOGIN_DIALOG_TITLE_LOGIN_FAILED)
        end
        errorString = GetString("SI_LOGINAUTHERROR", loginError)
    elseif linkingError ~= ACCOUNT_CREATE_LINK_ERROR_NO_ERROR then
        dialogTitle = GetString(SI_LOGIN_DIALOG_TITLE_LINK_FAILED)
        if linkingError == ACCOUNT_CREATE_LINK_ERROR_EXTERNAL_REFERENCE_ALREADY_USED or linkingError == ACCOUNT_CREATE_LINK_ERROR_USER_ALREADY_LINKED then
            local serviceType = GetPlatformServiceType()
            local accountTypeName = GetString("SI_PLATFORMSERVICETYPE", serviceType)
            errorString = GetString(SI_LINKACCOUNT_ALREADY_LINKED_ERROR_FORMAT)
            formattedErrorString = zo_strformat(errorString, accountTypeName)
        else
            errorString = GetString("SI_ACCOUNTCREATELINKERROR", linkingError)
        end
    end

    if errorString == "" then
        -- generic error message
        dialogTitle = GetString(SI_LOGIN_DIALOG_TITLE_LOGIN_FAILED)
        errorString = GetString(SI_UNEXPECTED_ERROR)
    end

    if formattedErrorString == nil then
        formattedErrorString = zo_strformat(errorString, GetURLTextByType(APPROVED_URL_ESO_HELP))
    end

    if loginError == LOGIN_AUTH_ERROR_ACCOUNT_NOT_VERIFIED or loginError == LOGIN_AUTH_ERROR_GAME_ACCOUNT_NOT_VERIFIED or linkingError == ACCOUNT_CREATE_LINK_ERROR_ACCOUNT_NOT_VERIFIED then
        PREGAME_INITIAL_SCREEN_GAMEPAD:ShowEmailVerificationError(dialogTitle, formattedErrorString)
        return
    end

    if not LINK_ACCOUNT_GAMEPAD:IsAccountValidForLinking(linkingError) then
        LINK_ACCOUNT_GAMEPAD:ClearCredentials()
    end

    -- debugInfo will be empty in public, non-debug builds
    PREGAME_INITIAL_SCREEN_GAMEPAD:ShowError(dialogTitle, formattedErrorString .. debugInfo)
end

function ZO_CreateLinkLoading_Gamepad:RegisterForEvent(eventId, callback)
    table.insert(self.registeredEvents, eventId)
    self.control:RegisterForEvent(eventId, callback)
end

function ZO_CreateLinkLoading_Gamepad:RegisterEvents()
    -- "Success" Cases
    self:RegisterForEvent(EVENT_LOGIN_SUCCESSFUL, OnLoggedIn)
    self:RegisterForEvent(EVENT_WORLD_SELECTED,  function(...) self:OnWorldSelected(...) end)
    self:RegisterForEvent(EVENT_WORLD_LIST_RECEIVED, OnWorldListReceived)
    self:RegisterForEvent(EVENT_ACCOUNT_LINK_SUCCESSFUL, OnSuccess)

    self:RegisterForEvent(EVENT_PROFILE_NOT_LINKED, OnNoLink)

    self:RegisterForEvent(EVENT_LOGIN_QUEUED, function(...) self:OnQueued(...) end)

    -- NOTE: Overflow is not handled here as, according to the console
    --   services guys, it is not supported on console.

    -- Error Cases
    -- TODO: Any additional error cases that should be handled?
    self:RegisterForEvent(EVENT_GLOBAL_ERROR, OnGlobalError)

    self:RegisterForEvent(EVENT_SERVER_IN_MAINTENANCE_MODE, OnServerMaintenance)

    self:RegisterForEvent(EVENT_SERVER_LOCKED, OnServerLocked)
    self:RegisterForEvent(EVENT_LOGIN_FAILED_INVALID_CREDENTIALS, OnInvalidCredentials)
    self:RegisterForEvent(EVENT_LOGIN_OTP_PENDING, OnOTPPending)

    self:RegisterForEvent(EVENT_BAD_CLIENT_VERSION, OnBadClientVersion)

    self:RegisterForEvent(EVENT_CREATE_LINK_LOADING_ERROR, OnCreateLinkLoadingError)

    -- Misc.
    RegisterForLoadingUpdates()
end

function ZO_CreateLinkLoading_Gamepad:UnregisterEvents()
    for i, eventId in ipairs(self.registeredEvents) do
        self.control:UnregisterForEvent(eventId)
    end

    self.registeredEvents = {}
end

function ZO_CreateLinkLoading_Gamepad:Show(previousState, loginFunction, loadingText)
    self:PerformDeferredInitialize()

    self.previousState = previousState
    self.loginFunction = loginFunction
    self.loadingText:SetText(loadingText)

    SCENE_MANAGER:Show("CreateLinkLoadingScreen_Gamepad")
end

function ZO_CreateLinkLoading_Gamepad:InitializeOtpDialog()
    local dialogName = "PROVIDE_OTP_INITIAL_GAMEPAD"
    local parametricDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)

    local oneTimePasswordText = ""

    -- OTP entry
    local otpEntryData = ZO_GamepadEntryData:New()
    otpEntryData.isEditControl = true

    otpEntryData.textChangedCallback = function(control)
        oneTimePasswordText = control:GetText()
    end

    otpEntryData.setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
        control.highlight:SetHidden(not selected)

        control.editBoxControl.textChangedCallback = data.textChangedCallback
        control.editBoxControl:SetMaxInputChars(32) -- 32 is oversized, but gives wiggle-room
        control.editBoxControl:SetText(oneTimePasswordText)
    end

    -- Submit entry
    local submitEntryData = ZO_GamepadEntryData:New(GetString(SI_OTP_DIALOG_SUBMIT))
    submitEntryData.isSubmit = true

    submitEntryData.setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
        local isValid = oneTimePasswordText ~= ""
        data.disabled = not isValid
        data:SetEnabled(isValid)

        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, isValid, active)
    end

    ZO_Dialogs_RegisterCustomDialog(dialogName,
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        canQueue = true,
        mustChoose = true,
        setup = function(dialog)
            oneTimePasswordText = ""
            ZO_GenericGamepadDialog_ShowTooltip(dialog)
            dialog:setupFunc()
        end,
        title =
        {
            text = SI_OTP_DIALOG_TITLE,
        },
        parametricList =
        {
            {
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem",
                entryData = otpEntryData,
            },
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                entryData = submitEntryData,
            },
        },
        updateFn = function(dialog)
            local dialogData = parametricDialog.data
            local timeLeftMs = dialogData.otpExpirationMs - GetFrameTimeMilliseconds()
            if timeLeftMs >= 0 then
                local timeLeftString = ZO_FormatTimeMilliseconds(timeLeftMs, TIME_FORMAT_STYLE_DESCRIPTIVE_SHORT_SHOW_ZERO_SECS)

                local instructionText
                if dialogData.otpReason ~= LOGIN_STATUS_OTP_FAILED then
                    instructionText = zo_strformat(SI_PROVIDE_OTP_INITIAL_DIALOG_TEXT_GAMEPAD, timeLeftString)
                else
                    instructionText = zo_strformat(SI_PROVIDE_OTP_SUBSEQUENT_DIALOG_TEXT, timeLeftString)
                end

                GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_DIALOG_TOOLTIP, instructionText)
            else
                ZO_Dialogs_ReleaseDialog(dialog)
                PregameStateManager_ReenterLoginState()
            end
        end,

        blockDialogReleaseOnPress = true,
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    local targetControl = dialog.entryList:GetTargetControl()
                    if targetData.isEditControl and targetControl then
                        targetControl.editBoxControl:TakeFocus()
                    elseif targetData.isSubmit then
                        if oneTimePasswordText ~= "" then
                            ZO_Dialogs_ReleaseDialogOnButtonPress(dialogName)
                            SendOneTimePassword(oneTimePasswordText)
                        end
                    end
                end,
                enabled = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()

                    if targetData.isEditControl then
                        return true
                    elseif targetData.isSubmit then
                        return oneTimePasswordText ~= ""
                    end

                    return false
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress(dialogName)
                    PregameStateManager_ReenterLoginState()
                end,
            },
        },
    })
end

-- XML Handlers --

function ZO_CreateLinkLoadingScreen_Gamepad_Initialize(self)
    CREATE_LINK_LOADING_SCREEN_GAMEPAD = ZO_CreateLinkLoading_Gamepad:New(self)
end
