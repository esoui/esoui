
local consolePregameStates =
{
    ["CreateLinkAccount"] =
    {
        ShouldAdvance = function()
            return false
        end,

        OnEnter = function()
            SCENE_MANAGER:Show("CreateLinkAccountScreen_Gamepad")
        end,

        OnExit = function()
        end,

        GetStateTransitionData = function()
            return "NoCreateLinkAccountLoading"
        end,
    },

    ["LegalAgreements"] =
    {
        ShouldAdvance = function()
            return false
        end,

        OnEnter = function()
            LEGAL_AGREEMENT_SCREEN_GAMEPAD:ShowConsoleFetchedDocs()
        end,

        OnExit = function()
        end,

        GetStateTransitionData = function()
            return "AcceptLegalDocs"
        end,
    },

    ["AcceptLegalDocs"] =
    {
        ShouldAdvance = function()
            return false
        end,

        OnEnter = function()
            CREATE_LINK_LOADING_SCREEN_GAMEPAD:Show("AccountLogin", AcceptLegalDocs, GetString(SI_GAMEPAD_PREGAME_LOADING))
        end,

        OnExit = function()
        end,

        GetStateTransitionData = function()
            return "NoCreateLinkAccountLoading"
        end,
    },

    ["CreateAccountSetup"] =
    {
        ShouldAdvance = function()
            return false
        end,

        OnEnter = function()
            CREATE_LINK_LOADING_SCREEN_GAMEPAD:Show("CreateLinkAccount", LoadCountryData, GetString(SI_GAMEPAD_PREGAME_LOADING))
        end,

        OnExit = function()
        end,

        GetStateTransitionData = function()
            return "CreateAccount"
        end,
    },

    ["CreateAccount"] =
    {
        ShouldAdvance = function()
            return false
        end,

        OnEnter = function()
            SCENE_MANAGER:Show("CreateAccount_Gamepad")
        end,

        OnExit = function()
        end,

        GetStateTransitionData = function()
            return "CreateAccountLoading", CREATE_ACCOUNT_GAMEPAD.enteredEmail, CREATE_ACCOUNT_GAMEPAD.ageValid, CREATE_ACCOUNT_GAMEPAD.emailSignup, CREATE_ACCOUNT_GAMEPAD.countryCode
        end,
    },

    ["CreateAccountLoading"] =
    {
        ShouldAdvance = function()
            return false
        end,

        OnEnter = function(email, ageValid, emailSignup, country)
            local function CreateAccount()
                PregameSetAccountCreationInfo(email, ageValid, emailSignup, country)
                PregameCreateAccount()
            end

            CREATE_LINK_LOADING_SCREEN_GAMEPAD:Show("AccountLogin", CreateAccount, GetString(SI_CREATEACCOUNT_CREATING_ACCOUNT), CREATE_ACCOUNT_BACKGROUND_FRAGMENT, CREATE_ACCOUNT_IMAGES_FRAGMENT_CONSOLE)
            WORLD_SELECT_GAMEPAD:SetImagesFragment(CREATE_ACCOUNT_IMAGES_FRAGMENT_CONSOLE)
            WORLD_SELECT_GAMEPAD:SetBackgroundFragment(CREATE_ACCOUNT_BACKGROUND_FRAGMENT)
        end,

        OnExit = function()
        end,

        GetStateTransitionData = function()
            return "CreateAccountFinished"
        end,
    },
    
    ["CreateAccountFinished"] = 
    {
        ShouldAdvance = function()
            return false
        end,

        OnEnter = function(username, password)
            SCENE_MANAGER:Show("CreateAccount_Gamepad_Final")
        end,

        OnExit = function()
        end,

        GetStateTransitionData = function()
            return "NoCreateLinkAccountLoading"
        end,
    },

    ["LinkAccount"] =
    {
        ShouldAdvance = function()
            return false
        end,

        OnEnter = function()
            SCENE_MANAGER:Show("LinkAccount_Gamepad")
        end,

        OnExit = function()
        end,

        GetStateTransitionData = function()
            return "ConfirmLinkAccount", LINK_ACCOUNT_GAMEPAD.username, LINK_ACCOUNT_GAMEPAD.password
        end,
    },

    ["ConfirmLinkAccount"] =
    {
        ShouldAdvance = function()
            return false
        end,

        OnEnter = function(username, password)
            CONFIRM_LINK_ACCOUNT_SCREEN_GAMEPAD:Show(username, password)
        end,

        OnExit = function()
        end,

        GetStateTransitionData = function()
            local username, password = CONFIRM_LINK_ACCOUNT_SCREEN_GAMEPAD:GetUsernamePassword()
            return "LinkAccountLoading", username, password
        end,
    },

    ["LinkAccountLoading"] =
    {
        ShouldAdvance = function()
            return false
        end,

        OnEnter = function(username, password)
            local function LinkAccount()
                if ZO_IsForceConsoleOrHeronFlow() then
                    PregameStateManager_AdvanceState()
                else
                    PregameLinkAccount(username, password)
                end
            end

            CREATE_LINK_LOADING_SCREEN_GAMEPAD:Show("AccountLogin", LinkAccount, GetString(SI_LINKACCOUNT_LINKING_ACCOUNT), LINK_ACCOUNT_BACKGROUND_FRAGMENT, LINK_ACCOUNT_IMAGES_FRAGMENT_CONSOLE)
            WORLD_SELECT_GAMEPAD:SetImagesFragment(LINK_ACCOUNT_IMAGES_FRAGMENT_CONSOLE)
            WORLD_SELECT_GAMEPAD:SetBackgroundFragment(LINK_ACCOUNT_BACKGROUND_FRAGMENT)
        end,

        OnExit = function()
        end,

        GetStateTransitionData = function()
            return "LinkAccountFinished"
        end,
    },

    ["LinkAccountFinished"] = 
    {
        ShouldAdvance = function()
            return false
        end,

        OnEnter = function(username, password)
            SCENE_MANAGER:Show("LinkAccountScreen_Gamepad_Final")
        end,

        OnExit = function()
        end,

        GetStateTransitionData = function()
            return "NoCreateLinkAccountLoading"
        end,
    },
}

PregameStateManager_AddGamepadStates(consolePregameStates)

--This will probably need to be more robust (similar to non console PregameStates) as more pregame comes online
local function OnVideoPlaybackComplete()
    EVENT_MANAGER:UnregisterForEvent("PregameStateManager", EVENT_VIDEO_PLAYBACK_COMPLETE)
    EVENT_MANAGER:UnregisterForEvent("PregameStateManager", EVENT_VIDEO_PLAYBACK_ERROR)

    if not ZO_PREGAME_HAD_GLOBAL_ERROR then
        if ZO_PREGAME_IS_CHAPTER_OPENING_CINEMATIC_PLAYING then
            ZO_PREGAME_IS_CHAPTER_OPENING_CINEMATIC_PLAYING = false
            AttemptToAdvancePastChapterOpeningCinematic()
        elseif ZO_PREGAME_IS_CHARACTER_SELECT_CINEMATIC_PLAYING then
            ZO_PREGAME_IS_CHARACTER_SELECT_CINEMATIC_PLAYING = false
            AttemptToAdvancePastCharacterSelectCinematic()
        else
            if not IsInCharacterCreateState() then
                PregameStateManager_AdvanceState()
            end
        end
    else
        -- error cases just reset the flags
        ZO_PREGAME_IS_CHAPTER_OPENING_CINEMATIC_PLAYING = false
        ZO_PREGAME_IS_CHARACTER_SELECT_CINEMATIC_PLAYING = false
    end
end

function ZO_PlayVideoAndAdvance(...)
    EVENT_MANAGER:RegisterForEvent("PregameStateManager", EVENT_VIDEO_PLAYBACK_COMPLETE, OnVideoPlaybackComplete)
    EVENT_MANAGER:RegisterForEvent("PregameStateManager", EVENT_VIDEO_PLAYBACK_ERROR, OnVideoPlaybackComplete)
    PlayVideo(...)
end

function ZO_Gamepad_DisplayServerDisconnectedError()
    if not IsErrorQueuedFromIngame() then
        return
    end

    local logoutError, globalErrorCode = GetErrorQueuedFromIngame()

    ZO_PREGAME_HAD_GLOBAL_ERROR = true

    local errorString
    local errorStringFormat

    if logoutError ~= nil and logoutError ~= LOGOUT_ERROR_UNKNOWN_ERROR then
        errorStringFormat = GetString("SI_LOGOUTERROR", logoutError)

        if errorStringFormat ~= ""  then
            errorString = zo_strformat(errorStringFormat, GetGameURL())
        end
    elseif globalErrorCode ~= nil and globalErrorCode ~= GLOBAL_ERROR_CODE_NO_ERROR then
        -- if the error code is not in LogoutReason then it is probably in the GlobalErrorCode enum 
        errorStringFormat = GetString("SI_GLOBALERRORCODE", globalErrorCode)

        if errorStringFormat ~= ""  then
            errorString = zo_strformat(errorStringFormat, globalErrorCode)
        end
    end

    if errorString == nil or errorString == "" then
        errorString = zo_strformat(SI_UNEXPECTED_ERROR, GetString(SI_HELP_URL))
    end

    PREGAME_INITIAL_SCREEN_GAMEPAD:ShowError(nil, errorString)
end

local function OnServerDisconnectError(eventCode)
    if IsErrorQueuedFromIngame() then
        ZO_Gamepad_DisplayServerDisconnectedError()

        local FORCE = true
        ZO_Dialogs_ReleaseAllDialogs(FORCE)
    end
end

local function OnProfileLoginResult(event, isSuccess, profileError)
    --Don't return to IIS if we're on Server Select and NO_PROFILE was returned because they probably cancelled the selection
    if isSuccess == false and not (profileError == PROFILE_LOGIN_ERROR_NO_PROFILE and SCENE_MANAGER:IsShowing("GameStartup"))  then
        local errorString
        local errorStringFormat = GetString("SI_PROFILELOGINERROR", profileError)

        if errorStringFormat == ""  then
            errorStringFormat = GetString("SI_PROFILELOGINERROR", PROFILE_LOGIN_ERROR_UNKNOWN_ERROR)
        end

        errorString = zo_strformat(errorStringFormat, GetString(SI_HELP_URL))

        PREGAME_INITIAL_SCREEN_GAMEPAD:ShowError(GetString(SI_PROFILE_LOAD_FAILED_TITLE), errorString)
    end
end

local function PregameStateManager_Initialize()
    EVENT_MANAGER:RegisterForEvent("PregameStateManager", EVENT_DISCONNECTED_FROM_SERVER, OnServerDisconnectError)
    EVENT_MANAGER:RegisterForEvent("PregameStateManager", EVENT_PROFILE_LOGIN_RESULT, OnProfileLoginResult)
end

PregameStateManager_Initialize()
