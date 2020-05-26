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
            return "ScreenAdjustIntro"
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
            
            if ZO_IsForceConsoleOrHeronFlow() then
                -- login using the username/password in user settings
                CREATE_LINK_LOADING_SCREEN_GAMEPAD:Show("AccountLogin", ZO_FakeConsoleOrHeronLogin, GetString(SI_GAMEPAD_PREGAME_LOADING))
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
            Pregame_ShowScene("gamepadCharacterSelect")
        end,

        OnExit = function()
            TrySaveCharacterListOrder()
        end
    },

}

PregameStateManager_AddGamepadStates(pregameStates)
