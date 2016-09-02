function ZO_Pregame_MustPlayVideos()
    return GetCVar("HasPlayedPregameVideo") == "0"
end

function ZO_Pregame_AllowVideosToPlay()
    return GetCVar("SkipPregameVideos") == "0"
end

ZO_PREGAME_CHARACTER_COUNT = 0
ZO_PREGAME_FIRED_CHARACTER_CONSTRUCTION_READY = false
ZO_PREGAME_CHARACTER_LIST_RECEIVED = false
ZO_PREGAME_HAD_GLOBAL_ERROR = false
ZO_PREGAME_IS_CHARACTER_CREATE_INTRO_PLAYING = false
ZO_PREGAME_IS_CHARACTER_SELECT_CINEMATIC_PLAYING = false

local QUEUE_VIDEO = false

local currentState = nil
local previousState = nil

local loadingUpdates = false

function Pregame_ShowScene(sceneName)
    SCENE_MANAGER:Show(sceneName)
    ZO_Dialogs_ReleaseAllDialogsExcept("HANDLE_ERROR", "HANDLE_ERROR_WITH_HELP")
end

function PregameStateManager_UpdateRealmName()
    local worldName = GetWorldName()

    if worldName == "" then
        worldName = "Unknown Realm"
    end

    -- Not permanently removed, I think we'll want this info...just waiting for Marc to understand that...
    -- ZO_CharacterSelectRealmName:SetText(worldName)
end

function AttemptQuickLaunch()
    if GetCVar("QuickLaunch") == "1" then
        local acctName = GetCVar("AccountName")
        local acctPwd = GetCVar("AccountPassword")

        if acctName ~= "" and acctPwd ~= "" then
            PregameLogin(acctName, acctPwd)
        end
    end
end

function AttemptToFireCharacterConstructionReady()
    if not ZO_PREGAME_FIRED_CHARACTER_CONSTRUCTION_READY and IsPregameCharacterConstructionReady() and ZO_PREGAME_CHARACTER_LIST_RECEIVED then
        ZO_PREGAME_FIRED_CHARACTER_CONSTRUCTION_READY = true
        CALLBACK_MANAGER:FireCallbacks("OnCharacterConstructionReady")
    end
end

local PregameStates =
{
    ["CharacterSelect_FromIngame"] =
    {
        OnEnter = function()
            -- Let the character list receipt determine the state to go to.
            RequestCharacterList()
        end,

        OnExit = function()
        end
    },

    ["CharacterSelect_PlayCinematic"] =
    {
        ShouldAdvance = function()
            return false
        end,

        OnEnter = function()
            if not ZO_PREGAME_IS_CHARACTER_SELECT_CINEMATIC_PLAYING then
                ZO_PREGAME_IS_CHARACTER_SELECT_CINEMATIC_PLAYING = true
                SetVideoCancelAllOnCancelAny(true)
                ZO_PlayVideoAndAdvance("Video/Opening_Cinematic_$(officialLanguage).bik", QUEUE_VIDEO, VIDEO_SKIP_MODE_REQUIRE_CONFIRMATION_FOR_SKIP)
                if IsInGamepadPreferredMode() then
                    --Stops extra button presses from modifying the options scene, like restoring options defaults or logging out
                    GAMEPAD_OPTIONS:SetGamepadOptionsInputBlocked(true);
                end
            end
        end,

        GetStateTransitionData = function()
            return "CharacterSelect_FromCinematic"
        end,

        OnExit = function()
        end,
    },

    ["CharacterSelect_FromCinematic"] =
    {
        OnEnter = function(allowAnimation)
            ZO_PREGAME_IS_CHARACTER_SELECT_CINEMATIC_PLAYING = false
            if IsInGamepadPreferredMode() then
                GAMEPAD_OPTIONS:SetGamepadOptionsInputBlocked(false)
            end
        end,
        
        OnExit = function()
        end
    },
    
    ["CharacterCreate_PlayIntro"] =
    {
        ShouldAdvance = function()
            return false
        end,

        OnEnter = function()
            SetVideoCancelAllOnCancelAny(true)
            ZO_PlayVideoAndAdvance("Video/Opening_Cinematic_$(officialLanguage).bik", QUEUE_VIDEO, VIDEO_SKIP_MODE_REQUIRE_CONFIRMATION_FOR_SKIP)
            ZO_PREGAME_IS_CHARACTER_CREATE_INTRO_PLAYING = true
            ZO_CharacterCreate_PrepareFadeFromMovie()
            SCENE_MANAGER:ShowBaseScene()
        end,

        GetStateTransitionData = function()
            return "CharacterCreate_FromIntro"
        end,

        OnExit = function()
            if(ZO_PREGAME_HAD_GLOBAL_ERROR) then
                ZO_CharacterCreate_AbortMovieFade()
            else
                ZO_CharacterCreate_FadeFromMovie()
            end
        end,
    },

    ["CharacterCreate_FromIntro"] =
    {
        OnEnter = function(allowAnimation)
            -- Empty state, allow the completion of the movie transition or loading to reset the character creation state.
        end,

        OnExit = function()
        end
    },

    ["CharacterCreate"] =
    {
        OnEnter = function(allowAnimation)
            ZO_CHARACTERCREATE_MANAGER:SetCharacterMode(CHARACTER_MODE_CREATION)
            local characterCreate = SYSTEMS:GetObject(ZO_CHARACTER_CREATE_SYSTEM_NAME)
            characterCreate:Reset()
            characterCreate:InitializeForCharacterCreate()

            if IsInGamepadPreferredMode() then
                Pregame_ShowScene("gamepadCharacterCreate")
            else
                Pregame_ShowScene("gameMenuCharacterCreate")
                -- PEGI update currently only needs to be shown on PC
                if DoesPlatformRequirePregamePEGI() and not HasAgreedToPEGI() then
                    ZO_Dialogs_ShowDialog("PEGI_COUNTRY_SELECT")
                end
            end
        end,

        OnExit = function()
            ZO_Dialogs_ReleaseDialog("CHARACTER_CREATE_CREATING")
            SetCharacterCameraZoomAmount(-1) -- zoom all the way out when leaving this state
        end
    },

    ["CharacterCreate_Barbershop"] =
    {
        OnEnter = function(allowAnimation)
            if IsInGamepadPreferredMode() then
                Pregame_ShowScene("gamepadCharacterCreate")
            else
                Pregame_ShowScene("gameMenuCharacterCreate")
            end
        end,

        OnExit = function()
            ZO_Dialogs_ReleaseDialog("CHARACTER_CREATE_CREATING")
            SetCharacterCameraZoomAmount(-1) -- zoom all the way out when leaving this state
        end
    },

    ["BeginLoadingIntoWorld"] =
    {
        OnEnter = function()
            if (IsInGamepadPreferredMode() or IsConsoleUI()) then  -- TODO integrate this with PC gamepad
                ZO_CharacterSelect_Gamepad_ShowLoginScreen()
            else
                SCENE_MANAGER:ShowBaseScene()
                ZO_Dialogs_ShowDialog("REQUESTING_CHARACTER_LOAD")
            end
        end,

        OnExit = function()
        end
    },

    ["ScreenAdjust"] =
    {
        ShouldAdvance = function()
            return not IsConsoleUI()
        end,

        OnEnter = function()
            SCENE_MANAGER:Show("screenAdjust")
        end,

        OnExit = function()
        end,

        GetStateTransitionData = function()
            return "GammaAdjust"
        end,
    },

    ["ScreenAdjustIntro"] =
    {
        ShouldAdvance = function()
            return not IsConsoleUI() or GetCVar("PregameScreenAdjustEnabled") ~= "1"
        end,

        OnEnter = function()
            SCENE_MANAGER:Show("screenAdjustIntro")
            SetCVar("PregameScreenAdjustEnabled", "false")
        end,

        OnExit = function()
        end,

        GetStateTransitionData = function()
            return "GammaAdjust"
        end,
    },

    ["GammaAdjust"] =
    {
        ShouldAdvance = function()
            return not ZO_GammaAdjust_NeedsFirstSetup()
        end,

        OnEnter = function()
            SCENE_MANAGER:Show("gammaAdjust")
        end,

        OnExit = function()
            SetCVar("PregameGammaCheckEnabled", "false")
        end,

        GetStateTransitionData = function()
            if IsConsoleUI() or not DoesPlatformSelectServer() then
                return "ShowEULA"
            else
                return "ServerSelectIntro"
            end
        end,
    },

    ["PlayIntroMovies"] =
    {
        ShouldAdvance = function()
            return not(ZO_Pregame_MustPlayVideos() or ZO_Pregame_AllowVideosToPlay())
        end,

        OnEnter = function()
            -- If you haven't played the videos, you can't skip them until they finish...
            local skipMode
            
            if(IsConsoleUI()) then
                skipMode = VIDEO_SKIP_MODE_ALLOW_SKIP
            else
                skipMode = ZO_Pregame_MustPlayVideos() and VIDEO_SKIP_MODE_NO_SKIP or VIDEO_SKIP_MODE_ALLOW_SKIP
            end
            
            -- TODO: Determine if these videos need localization or subtitles...
            SetVideoCancelAllOnCancelAny(false)

            PlayVideo("Video/Bethesda_logo.bik", QUEUE_VIDEO, skipMode)

            ZO_PlayVideoAndAdvance("Video/ZOS_logo.bik", QUEUE_VIDEO, skipMode)
        end,

        GetStateTransitionData = function()
            return "ShowHavokSplashScreen"
        end,

        OnExit = function()
        end,
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
            return "ScreenAdjustIntro"
        end,

        OnExit = function()
        end,
    },

    ["ShowHavokSplashScreen"] =
    {
        ShouldAdvance = function()
            return not(ZO_Pregame_MustPlayVideos() or ZO_Pregame_AllowVideosToPlay())
        end,

        OnEnter = function()
            SCENE_MANAGER:Show("havokSplash")
        end,

        GetStateTransitionData = function()
            return "ShowDMMVideo"
        end,

        OnExit = function()
        end,
    },

    ["ShowDMMVideo"] =
    {
        ShouldAdvance = function()
            local serviceType = GetPlatformServiceType()
            return not(serviceType == PLATFORM_SERVICE_TYPE_DMM and (ZO_Pregame_MustPlayVideos() or ZO_Pregame_AllowVideosToPlay()))
        end,

        OnEnter = function()
            local skipMode = ZO_Pregame_MustPlayVideos() and VIDEO_SKIP_MODE_NO_SKIP or VIDEO_SKIP_MODE_ALLOW_SKIP
            ZO_PlayVideoAndAdvance("Video/jp_DMM_logo.bik", QUEUE_VIDEO, skipMode)
        end,

        GetStateTransitionData = function()
            return "ShowLegalSplashScreen"
        end,

        OnExit = function()
        end,
    },

    ["Disconnect"] =
    {
        OnEnter = function()
            SetCVar("QuickLaunch", "0")
            PregameDisconnect()
        end,

        OnExit = function ()
        end,
    }
}

function PregameStateManager_AddStates(externalStates)
    for key, value in pairs(externalStates) do
        PregameStates[key] = value
    end
end

function PregameStateManager_SetState(stateName, ...)
    local newPregameState = PregameStates[stateName]
    local stateArgs = { ... }

    -- Because GetTransitionData returns the next state as the first argument, insert state name into this table.
    -- The actual arguments passed to OnEnter will be adjusted to account for it.
    table.insert(stateArgs, 1, stateName)

    if(newPregameState) then
        if(currentState) then
            PregameStates[currentState].OnExit()
        end

        previousState = currentState

        local foundState = false
        while(not foundState) do
            currentState = stateName
            local shouldAdvance = (newPregameState.ShouldAdvance == nil) or newPregameState.ShouldAdvance()
            if(shouldAdvance) then
                if(newPregameState and newPregameState.GetStateTransitionData) then
                    stateArgs = { newPregameState.GetStateTransitionData() }
                    stateName = stateArgs[1]
                    newPregameState = PregameStates[stateName]
                else
                    foundState = true
                end
            else
                foundState = true
            end
        end

        newPregameState.OnEnter(select(2, unpack(stateArgs)))
        CALLBACK_MANAGER:FireCallbacks("OnPregameEnterState", currentState)
    end
end

function PregameStateManager_ReenterLoginState()
    if(PregameStateManager_GetCurrentState() == "AccountLogin") then
        CALLBACK_MANAGER:FireCallbacks("OnPregameEnterState", "AccountLogin")
    else
        PregameStateManager_SetState("AccountLogin")
    end
end

function PregameStateManager_AdvanceState()
    local currentStateData = PregameStates[currentState]
    if(currentStateData and currentStateData.GetStateTransitionData) then
        PregameStateManager_SetState(currentStateData.GetStateTransitionData())
    else
        -- If there are no transition data, then we're not going anywhere...we'll be locked in the current state.
        -- Do not call this if you're not on a state with transition data
        assert(false)
    end
end

-- this will only advance the state if we are currently in the state passed in
function PregameStateManager_AdvanceStateFromState(state)
    if(currentState == state) then
        PregameStateManager_AdvanceState()
    end
end

function PregameStateManager_GetCurrentState()
    return currentState
end

function PregameStateManager_GetPreviousState()
    return previousState
end

local function OnCharacterListReceived(eventCode, characterCount, maxCharacters, mostRecentlyPlayedCharacterId)
    ZO_PREGAME_CHARACTER_LIST_RECEIVED = true
    local previousCharacterCount = ZO_PREGAME_CHARACTER_COUNT or 0
    ZO_PREGAME_CHARACTER_COUNT = characterCount

    -- This causes other systems to figure out what state to drop in to
    CALLBACK_MANAGER:FireCallbacks("PregameCharacterListReceived", characterCount, previousCharacterCount)

    -- if this hasn't been fired yet, then fire it (could have been a reload or coming from in-game)
    AttemptToFireCharacterConstructionReady()
end

-- Debugging utility...you must be at character select already to use this.
local function SetupUIReloadAfterLogin()
    g_careAboutLoading = false
    RequestCharacterList()

    return "CharacterSelect"
    -- Return an invalid state, allow the character list receipt to figure out what state to advance to
end

local initialStateOverrideFn --= SetupUIReloadAfterLogin -- normally this is nil, it can be set to a custom function to allow the reload to drop into a desired state

function UnregisterForLoadingUpdates()
    if loadingUpdates then
        EVENT_MANAGER:UnregisterForEvent("PregameStateManager", EVENT_AREA_LOAD_STARTED)
        EVENT_MANAGER:UnregisterForEvent("PregameStateManager", EVENT_SUBSYSTEM_LOAD_COMPLETE)
        loadingUpdates = false
    end
end

local function OnAreaLoadStarted()
    ZO_Dialogs_ReleaseAllDialogs(true)
end

function IsInCharacterCreateIntroState()
    return PregameStateManager_GetCurrentState() == "CharacterCreate_PlayIntro"
end

function IsInCharacterSelectCinematicState()
    return PregameStateManager_GetCurrentState() == "CharacterSelect_PlayCinematic"
end

function IsInCharacterCreateState()
    return PregameStateManager_GetCurrentState() == "CharacterCreate"
end

local function OnCharacterSelected(eventCode, characterId)
    PregameStateManager_SetState("BeginLoadingIntoWorld")
end

function PregameIsFullyLoaded()
    return GetNumLoadedSubsystems() == GetNumTotalSubsystemsToLoad()
end

function AttemptToAdvancePastCharacterCreateIntro()
    if(IsInCharacterCreateIntroState()) then
        if(PregameIsFullyLoaded() and ZO_PREGAME_IS_CHARACTER_CREATE_INTRO_PLAYING == false) then
            PregameStateManager_AdvanceState()
        end
    end
end

function AttemptToAdvancePastCharacterSelectCinematic()
    if (IsInCharacterSelectCinematicState()) then
        if (PregameIsFullyLoaded() and ZO_PREGAME_IS_CHARACTER_SELECT_CINEMATIC_PLAYING == false) then
            PregameStateManager_AdvanceState()
        end
    end
end

local function OnSubsystemLoadComplete(eventId, subSystem)
    if(subSystem == LOADING_SYSTEM_GAME_DATA or subSystem == LOADING_SYSTEM_SHARED_CHARACTER_OBJECT) then
        AttemptToFireCharacterConstructionReady()
    end

    if(PregameIsFullyLoaded()) then
        if(IsInCharacterCreateIntroState()) then
            AttemptToAdvancePastCharacterCreateIntro()
        end

        CALLBACK_MANAGER:FireCallbacks("PregameFullyLoaded")
        UnregisterForLoadingUpdates()
    end
end

function RegisterForLoadingUpdates()
    if not loadingUpdates then
        EVENT_MANAGER:RegisterForEvent("PregameStateManager", EVENT_AREA_LOAD_STARTED, OnAreaLoadStarted)
        EVENT_MANAGER:RegisterForEvent("PregameStateManager", EVENT_SUBSYSTEM_LOAD_COMPLETE, OnSubsystemLoadComplete)
        loadingUpdates = true
    end
end

--
-- This can only be called from pregame, because of the way that the SetGuiHidden function is exposed.
--
local function ShowGui(eventCode, guiName, desiredState)
    local hidePregame = (guiName ~= "pregame")
    SetGuiHidden("pregame", hidePregame)
    SetGuiHidden("app", not hidePregame)

    if(guiName == "pregame") then
        if(initialStateOverrideFn) then
            desiredState = initialStateOverrideFn()
        end

        if(desiredState and (desiredState ~= "")) then
            PregameStateManager_SetState(desiredState, true)
        end
    end
end

function PregameStateManager_PlayCharacter(charId, loadOption)
    if(type(loadOption) == "string") then
        PregameStateManager_SetState(loadOption)
    else --We will need to revisit this once the tutorial gate is integrated into the build
        CALLBACK_MANAGER:FireCallbacks("OnCharacterLoadRequested")
        SelectCharacterForPlay(charId, loadOption)
    end
end

function PregameStateManager_ClearError()
    ZO_PREGAME_HAD_GLOBAL_ERROR = false
end

EVENT_MANAGER:RegisterForEvent("PregameStateManager", EVENT_CHARACTER_LIST_RECEIVED, OnCharacterListReceived)
EVENT_MANAGER:RegisterForEvent("PregameStateManager", EVENT_SHOW_GUI, ShowGui)
EVENT_MANAGER:RegisterForEvent("PregameStateManager", EVENT_CHARACTER_SELECTED_FOR_PLAY, OnCharacterSelected)
