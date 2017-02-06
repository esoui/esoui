local GAMEPAD_WAIT_FOR_PREGAME_FULLY_LOADED_SCENE = ZO_Scene:New("gamepadWaitForPregameFullyLoaded", SCENE_MANAGER)

local consolePregameStates =
{
    ["WaitForPregameFullyLoaded"] =
    {
        ShouldAdvance = function()
            return PregameIsFullyLoaded()
        end,

        OnEnter = function()
            RegisterForLoadingUpdates()
            PregameStateManager_UpdateRealmName()
            SuppressWorldList()
            Pregame_ShowScene("gamepadWaitForPregameFullyLoaded")
        end,
        
        OnExit = function()
        end,

        GetStateTransitionData = function()
            return "CharacterSelect"
        end
    },
    
    ["CharacterSelect"] =
    {
        OnEnter = function()
            Pregame_ShowScene("gamepadCharacterSelect")
        end,

        OnExit = function()
        end
    },

    ["ShowLegalSplashScreen"] =
    {
        ShouldAdvance = function()
            return not(ZO_Pregame_MustPlayVideos() or ZO_Pregame_AllowVideosToPlay())
        end,

        OnEnter = function()
            SCENE_MANAGER:Show("logoSplash")
        end,

        GetStateTransitionData = function()
            return "WaitForGuiRender"
        end,

        OnExit = function()
        end,
    },

    ["WaitForGuiRender"] =
    {
        ShouldAdvance = function()
            return IsGuiShaderLoaded()
        end,

        OnEnter = function()
            EVENT_MANAGER:RegisterForUpdate("PregameWaitForGuiRender", 0, function()
                if IsGuiShaderLoaded() then
                    PregameStateManager_AdvanceState()
                end
            end)
        end,

        OnExit = function()
            EVENT_MANAGER:UnregisterForUpdate("PregameWaitForGuiRender")
        end,

        GetStateTransitionData = function()
            return "AccountLogin"
        end
    },

    ["AccountLogin"] =
    {
        ShouldAdvance = function()
            return false
        end,

        OnEnter = function()
            PregamePrepareForProfile()
            PregameLogout()
            
            ZO_PREGAME_FIRED_CHARACTER_CONSTRUCTION_READY = false
            ZO_PREGAME_CHARACTER_LIST_RECEIVED = false
            ZO_PREGAME_CHARACTER_COUNT = 0

            --If we're quick launching, then just register a profile login event that sets the LastPlatform and advances the state.
            if (GetCVar("QuickLaunch") == "1") then
                EVENT_MANAGER:RegisterForEvent("PregameInitialScreen", EVENT_PROFILE_LOGIN_RESULT, function(eventCode, isSuccess, profileError)
					EVENT_MANAGER:UnregisterForEvent("PregameInitialScreen", EVENT_PROFILE_LOGIN_RESULT)

                    if (isSuccess) then
                        local lastPlat = GetCVar("LastPlatform")
                        if lastPlat ~= nil then
                            for platformIndex = 1, GetNumPlatforms() do
                                local platformName = GetPlatformInfo(platformIndex)            
                                if platformName == lastPlat then
                                    SetSelectedPlatform(platformIndex)
                                end
                            end
                        end

                        SetCVar("IsServerSelected", "true")
                        SetCVar("SelectedServer", CONSOLE_SERVER_NORTH_AMERICA)
                        PregameStateManager_AdvanceState()
                    end
                end)

                PregameSelectProfile()
            else
                CREATE_LINK_LOADING_SCREEN_GAMEPAD:SetImagesFragment(nil) -- Remove any previously set fragment.
                CREATE_LINK_LOADING_SCREEN_GAMEPAD:SetBackgroundFragment(PREGAME_ANIMATED_BACKGROUND_FRAGMENT)
                WORLD_SELECT_GAMEPAD:SetImagesFragment(nil) -- Remove any previously set fragment.
                WORLD_SELECT_GAMEPAD:SetBackgroundFragment(PREGAME_ANIMATED_BACKGROUND_FRAGMENT)

                -- Reset screen overscan/gamma and audio settings
                SetOverscanOffsets(0, 0, 0, 0)
                SetCVar("GAMMA_ADJUSTMENT", 100)
                ResetToDefaultSettings(SETTING_TYPE_AUDIO)

                SetCurrentVideoPlaybackVolume(1.0, 4.0)

                SCENE_MANAGER:Show("PregameInitialScreen_Gamepad")
            end
        end,

        OnExit = function()
        end,

        GetStateTransitionData = function()
            return "InitialGameStartup"
        end,
    },

    ["InitialGameStartup"] =
    {
        ShouldAdvance = function()
            return not IsConsoleUI() or GetCVar("IsServerSelected") == "1"
        end,

        OnEnter = function()
            SCENE_MANAGER:Show("InitialGameStartup")
        end,

        OnExit = function()
        end,

        GetStateTransitionData = function()
            return "GameStartup"
        end,
    },

    ["GameStartup"] =
    {
        ShouldAdvance = function()
            return (GetCVar("QuickLaunch") == "1")
        end,

        OnEnter = function(mustPurchaseGame)
            GAME_STARTUP_GAMEPAD:SetMustPurchaseGame(mustPurchaseGame)
            SCENE_MANAGER:Show("GameStartup")
        end,

        GetStateTransitionData = function()
            return "ScreenAdjustIntro"
        end,

        OnExit = function()
        end,
    },

    ["ShowEULA"] =
    {
        ShouldAdvance = function()
            -- TODO: Add checks for other legal agreements, if needed.
            return ZO_HasAgreedToEULA()
        end,

        OnEnter = function()
            LEGAL_AGREEMENT_SCREEN_CONSOLE:ShowEULA()
            SCENE_MANAGER:Show("LegalAgreementsScreen_Gamepad")
        end,

        OnExit = function()
        end,

        GetStateTransitionData = function()
            return "NoCreateLinkAccountLoading"
        end,
    },

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

    ["NoCreateLinkAccountLoading"] =
    {
        ShouldAdvance = function()
            return false
        end,

        OnEnter = function()
            local platform = GetUIPlatform()
            
            --Smoke video audio fade out to prevent audio clicking on console due to load time hitches
            --4 seconds seems to be a good fade out time for here
            if platform == UI_PLATFORM_PS4 or platform == UI_PLATFORM_XBOX then
                SetCurrentVideoPlaybackVolume(0.0, 4.0)
            end
            
            if(IsConsoleUI() and platform == UI_PLATFORM_PC) then
                -- should only ever hit this on internal builds testing with PC
                CREATE_LINK_LOADING_SCREEN_GAMEPAD:Show("AccountLogin", ZO_PCBypassConsoleLogin, GetString(SI_CONSOLE_PREGAME_LOADING))
            else
                CREATE_LINK_LOADING_SCREEN_GAMEPAD:Show("AccountLogin", PregameBeginLinkedLogin, GetString(SI_CONSOLE_PREGAME_LOADING))
            end
        end,

        OnExit = function()
        end,

        GetStateTransitionData = function()
            return "WorldSelect"
        end,
    },

    ["LegalAgreements"] =
    {
        ShouldAdvance = function()
            return false
        end,

        OnEnter = function()
            LEGAL_AGREEMENT_SCREEN_CONSOLE:ShowFetchedDocs()
            SCENE_MANAGER:Show("LegalAgreementsScreen_Gamepad")
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
            CREATE_LINK_LOADING_SCREEN_GAMEPAD:Show("AccountLogin", AcceptLegalDocs, GetString(SI_CONSOLE_PREGAME_LOADING))
        end,

        OnExit = function()
        end,

        GetStateTransitionData = function()
            return "NoCreateLinkAccountLoading"
        end,
    },

    ["WorldSelect"] =
    {
        ShouldAdvance = function()
            return false
        end,

        OnEnter = function()
            SCENE_MANAGER:Show("WorldSelect_Gamepad")
        end,

        OnExit = function()
        end,

        GetStateTransitionData = function()
            local worldIndex, worldName = WORLD_SELECT_GAMEPAD:GetSelectedWorldInformation()
            return "WorldConnectLoading", worldIndex, worldName
        end,
    },

    ["WorldConnectLoading"] =
    {
        ShouldAdvance = function()
            return false
        end,

        OnEnter = function(worldIndex, worldName)
            local function LocalSelectWorld()
                SelectWorld(worldIndex)
            end

            CREATE_LINK_LOADING_SCREEN_GAMEPAD:Show("AccountLogin", LocalSelectWorld, zo_strformat(SI_CONNECTING_TO_REALM, worldName))
        end,

        OnExit = function()
        end,

        GetStateTransitionData = function()
            return "WaitForPregameFullyLoaded"
        end,
    },

    ["CreateAccountSetup"] =
    {
        ShouldAdvance = function()
            return false
        end,

        OnEnter = function()
            CREATE_LINK_LOADING_SCREEN_GAMEPAD:Show("CreateLinkAccount", LoadCountryData, GetString(SI_CONSOLE_PREGAME_LOADING))
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
                if(IsConsoleUI() and GetUIPlatform() ~= UI_PLATFORM_PC) then
                    PregameLinkAccount(username, password)
                else
                    PregameStateManager_AdvanceState()
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

PregameStateManager_AddStates(consolePregameStates)

--This will probably need to be more robust (similar to non console PregameStates) as more pregame comes online
local function OnVideoPlaybackComplete()
    EVENT_MANAGER:UnregisterForEvent("PregameStateManager", EVENT_VIDEO_PLAYBACK_COMPLETE)

    if(not ZO_PREGAME_HAD_GLOBAL_ERROR) then
        if(ZO_PREGAME_IS_CHARACTER_CREATE_INTRO_PLAYING) then
            ZO_PREGAME_IS_CHARACTER_CREATE_INTRO_PLAYING = false
            AttemptToAdvancePastCharacterCreateIntro()
        elseif (ZO_PREGAME_IS_CHARACTER_SELECT_CINEMATIC_PLAYING) then
            ZO_PREGAME_IS_CHARACTER_SELECT_CINEMATIC_PLAYING = false
            AttemptToAdvancePastCharacterSelectCinematic()
        else
            if(not IsInCharacterCreateState()) then
                PregameStateManager_AdvanceState()
            end
        end
    else
        -- error cases just reset the flags
        ZO_PREGAME_IS_CHARACTER_CREATE_INTRO_PLAYING = false
        ZO_PREGAME_IS_CHARACTER_SELECT_CINEMATIC_PLAYING = false
    end
end

function ZO_PlayVideoAndAdvance(...)
    EVENT_MANAGER:RegisterForEvent("PregameStateManager", EVENT_VIDEO_PLAYBACK_COMPLETE, OnVideoPlaybackComplete)
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

    if(errorString == "") then
        errorString = zo_strformat(SI_UNEXPECTED_ERROR, GetString(SI_HELP_URL))
    end

    PREGAME_INITIAL_SCREEN_CONSOLE:ShowError(nil, errorString)
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

        PREGAME_INITIAL_SCREEN_CONSOLE:ShowError(GetString(SI_PROFILE_LOAD_FAILED_TITLE), errorString)
    end
end

local function OnPregameFullyLoaded()
    PregameStateManager_AdvanceStateFromState("WaitForPregameFullyLoaded")
end

local function PregameStateManager_Initialize()
    EVENT_MANAGER:RegisterForEvent("PregameStateManager", EVENT_DISCONNECTED_FROM_SERVER, OnServerDisconnectError)
    EVENT_MANAGER:RegisterForEvent("PregameStateManager", EVENT_PROFILE_LOGIN_RESULT, OnProfileLoginResult)

    CALLBACK_MANAGER:RegisterCallback("PregameFullyLoaded", OnPregameFullyLoaded)
end

PregameStateManager_Initialize()
