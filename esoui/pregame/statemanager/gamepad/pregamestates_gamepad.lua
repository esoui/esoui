local pregameStates =
{
    ["AccountLoginEntryPoint"] =
    {
        ShouldAdvance = function()
            return true
        end,

        OnEnter = function()
            -- do nothing
        end,

        OnExit = function()
            -- do nothing
        end,

        GetStateTransitionData = function()
            return "WaitForGuiRender"
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
            if DoesPlatformSupportDisablingShareFeatures() then
                -- re-enabled when the character list is loaded
                DisableShareFeatures()
            end
            PregamePrepareForProfile()
            PregameLogout()

            ZO_PREGAME_FIRED_CHARACTER_CONSTRUCTION_READY = false
            ZO_PREGAME_CHARACTER_LIST_RECEIVED = false
            ZO_PREGAME_CHARACTER_COUNT = 0

            --If we're quick launching, then just register a profile login event that sets the LastPlatform and advances the state.
            if GetCVar("QuickLaunch") == "1" then
                EVENT_MANAGER:RegisterForEvent("PregameInitialScreen", EVENT_PROFILE_LOGIN_RESULT, function(eventCode, isSuccess, profileError)
                    EVENT_MANAGER:UnregisterForEvent("PregameInitialScreen", EVENT_PROFILE_LOGIN_RESULT)

                    if isSuccess then
                        local lastPlatformName = GetCVar("LastPlatform")
                        if lastPlatformName ~= nil then
                            for platformIndex = 1, GetNumPlatforms() do
                                local platformName = GetPlatformInfo(platformIndex)
                                if platformName == lastPlatformName then
                                    SetSelectedPlatform(platformIndex)
                                end
                            end
                        end

                        SetCVar("IsServerSelected", "true")
                        SetCVar("SelectedServer", CONSOLE_SERVER_NORTH_AMERICA)
                        PregameStateManager_AdvanceState()
                    end
                end)

                if ZO_IsConsolePlatform() then
                    PregameSelectProfile()
                else
                    AttemptQuickLaunch()
                    SCENE_MANAGER:Show("PregameInitialScreen_Gamepad")
                end
            else
                if IsConsoleUI() then
                    -- ESO-404970: reset overscan, gamma, and audio settings
                    -- to default to handle the situation where a player loads
                    -- between console profiles, which should have different
                    -- user settings. For the IIS, we want to behave in an
                    -- "agnostic" way and avoid settings leaking through both sides
                    SetOverscanOffsets(0, 0, 0, 0)
                    SetCVar("GAMMA_ADJUSTMENT", 100)
                    ResetToDefaultSettings(SETTING_TYPE_AUDIO)
                end

                SetCurrentVideoPlaybackVolume(1.0, 4.0)

                SCENE_MANAGER:Show("PregameInitialScreen_Gamepad")
            end
            StartPregameMusic()
        end,

        OnExit = function()
            -- Do nothing
        end,

        GetStateTransitionData = function()
            return "InitialGameStartup"
        end,
    },

    ["InitialGameStartup"] =
    {
        ShouldAdvance = function()
            return GetCVar("IsServerSelected") == "1"
        end,

        OnEnter = function()
            SCENE_MANAGER:Show("InitialGameStartup")
        end,

        OnExit = function()
            -- Do nothing
        end,

        GetStateTransitionData = function()
            return "GameStartup"
        end,
    },

    ["GameStartup"] =
    {
        ShouldAdvance = function()
            return GetCVar("QuickLaunch") == "1"
        end,

        OnEnter = function(psnFreeTrialEnded)
            GAME_STARTUP_GAMEPAD:SetPsnFreeTrialEnded(psnFreeTrialEnded)
            SCENE_MANAGER:Show("GameStartup")
        end,
        
        OnExit = function()
            -- Do nothing
        end,

        GetStateTransitionData = function()
            if IsConsoleUI() then
                return "FirstTimeAccessibilitySettings"
            else
                return "ShowEULA"
            end
        end,
    },

    ["ShowEULA"] =
    {
        ShouldAdvance = function()
            return not LEGAL_AGREEMENT_SCREEN_GAMEPAD:ShouldShowEULA()
        end,

        OnEnter = function()
            LEGAL_AGREEMENT_SCREEN_GAMEPAD:ShowEULA()
        end,

        OnExit = function()
            -- Do nothing
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
            --Smoke video audio fade out to prevent audio clicking on console due to load time hitches
            --4 seconds seems to be a good fade out time for here
            if IsConsoleUI() then
                SetCurrentVideoPlaybackVolume(0.0, 4.0)
            end
            
            if (ZO_IsPCUI() or ZO_IsForceConsoleFlow()) and not IsUsingLinkedLogin() then
                -- login using the username/password the user provides
                function Login()
                    local username = GAME_STARTUP_GAMEPAD:GetEnteredUserName()
                    local password = GAME_STARTUP_GAMEPAD:GetEnteredPassword()
                    PregameLogin(username, password)
                end

                CREATE_LINK_LOADING_SCREEN_GAMEPAD:Show("AccountLogin", Login, GetString(SI_GAMEPAD_PREGAME_LOADING))
            else
                CREATE_LINK_LOADING_SCREEN_GAMEPAD:Show("AccountLogin", PregameBeginLinkedLogin, GetString(SI_GAMEPAD_PREGAME_LOADING))
            end
        end,

        OnExit = function()
            -- Do nothing
        end,

        GetStateTransitionData = function()
            return "WorldSelect"
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
            local enteredEmail = CREATE_ACCOUNT_GAMEPAD:GetEnteredEmail()
            local shouldRevieveNews = CREATE_ACCOUNT_GAMEPAD:ShouldReceiveNewsEmail()
            local countryCode = CREATE_ACCOUNT_GAMEPAD:GetCountryCode()
            local enteredAccountName = CREATE_ACCOUNT_GAMEPAD:GetEnteredAccountName()
            return "CreateAccountLoading", enteredEmail, shouldRevieveNews, countryCode, enteredAccountName
        end,
    },

    ["CreateAccountLoading"] =
    {
        ShouldAdvance = function()
            return false
        end,

        OnEnter = function(email, emailSignup, country, requestedAccountName)
            local function CreateAccount()
                PregameSetAccountCreationInfo(email, emailSignup, country, requestedAccountName)
                PregameCreateAccount()
            end

            CREATE_LINK_LOADING_SCREEN_GAMEPAD:Show("AccountLogin", CreateAccount, GetString(SI_CREATEACCOUNT_CREATING_ACCOUNT))
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
            return "ConfirmLinkAccount", LINK_ACCOUNT_GAMEPAD:GetEnteredUserName(), LINK_ACCOUNT_GAMEPAD:GetEnteredPassword()
        end,
    },

    ["LinkAccountActivation"] =
    {
        ShouldAdvance = function()
            return false
        end,

        OnEnter = function()
            SCENE_MANAGER:Show("LinkAccount_Activation_Gamepad")
        end,

        OnExit = function()
        end,

        GetStateTransitionData = function()
            return "LinkAccountFinished"
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
                if ZO_IsForceConsoleFlow() then
                    PregameStateManager_AdvanceState()
                else
                    PregameLinkAccount(username, password)
                end
            end

            CREATE_LINK_LOADING_SCREEN_GAMEPAD:Show("AccountLogin", LinkAccount, GetString(SI_LINKACCOUNT_LINKING_ACCOUNT))
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

        OnEnter = function()
            SCENE_MANAGER:Show("LinkAccountScreen_Gamepad_Final")
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
            -- Do nothing
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
            -- Do nothing
        end,

        GetStateTransitionData = function()
            return "WaitForGameDataLoaded"
        end,
    },

    ["CharacterSelect"] =
    {
        OnEnter = function()
            if SCENE_MANAGER:IsShowing("gamepadCharacterSelect") then
                -- If the scene is already showing when trying to enter character select it probably means we were
                -- disconnected form the server after selecting a character.
                ZO_Dialogs_ReleaseAllDialogsExcept("HANDLE_ERROR", "HANDLE_ERROR_WITH_HELP")
                local ACTIVATE_VIEWPORT = true
                ZO_CharacterSelect_Gamepad_ReturnToCharacterList(ACTIVATE_VIEWPORT)
            else
                if DoesPlatformRequirePregamePEGI() and not HasAgreedToPEGI() then
                    ZO_Dialogs_ShowGamepadDialog("PEGI_COUNTRY_SELECT_GAMEPAD")
                else
                    Pregame_ShowScene("gamepadCharacterSelect")
                end
            end
        end,

        OnExit = function()
            TrySaveCharacterListOrder()
        end
    },

}

PregameStateManager_AddGamepadStates(pregameStates)
