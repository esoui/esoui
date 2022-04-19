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
            if not DoesPlatformSelectServer() then
                return "ShowEULA"
            else
                return "ServerSelectIntro"
            end
        end,
    },

    ["CharacterSelect"] =
    {
        OnEnter = function()
            Pregame_ShowScene("gameMenuCharacterSelect")
            if DoesPlatformRequirePregamePEGI() and not HasAgreedToPEGI() then
                ZO_Dialogs_ShowDialog("PEGI_COUNTRY_SELECT")
            end
        end,

        OnExit = function()
            TrySaveCharacterListOrder()
        end
    },

    ["ShowEULA"] =
    {
        ShouldAdvance = function()
            return not ZO_ShouldShowEULAScreen()
        end,

        OnEnter = function()
            SCENE_MANAGER:Show("eula")
        end,

        OnExit = function()
        end,

        GetStateTransitionData = function()
            return "AccountLogin"
        end,
    },

    ["AccountLogin"] =
    {
        OnEnter = function(allowAnimation)
            if DoesPlatformSupportDisablingShareFeatures() then
                -- re-enabled when the character list is loaded
                DisableShareFeatures()
            end
            LOGIN_KEYBOARD:InitializeCredentialEditBoxes()
            PregameLogout()
            RegisterForLoadingUpdates()

            if ZO_PREGAME_HAD_GLOBAL_ERROR then
                AbortVideoPlayback()
            end

            ZO_PREGAME_FIRED_CHARACTER_CONSTRUCTION_READY = false
            ZO_PREGAME_CHARACTER_LIST_RECEIVED = false
            ZO_PREGAME_CHARACTER_COUNT = 0

            Pregame_ShowScene("gameMenuPregame")

            if IsErrorQueuedFromIngame() then
                ZO_Pregame_DisplayServerDisconnectedError()
            end

            AttemptQuickLaunch()
        end,

        OnExit = function()
        end
    },

    ["WorldSelect_Requested"] =
    {
        OnEnter = function()
            ZO_Dialogs_ShowDialog("REQUESTING_WORLD_LIST")
            RequestWorldList()
        end,

        OnExit = function()
        end
    },

    ["WorldSelect_ShowList"] =
    {
        OnEnter = function()
            ZO_WorldSelect_SetSelectionEnabled(true)
            Pregame_ShowScene("worldSelect")
        end,

        OnExit = function()
        end
    },

    ["ServerSelectIntro"] =
    {
        ShouldAdvance = function()
            return GetCVar("IsServerSelected") == "1"
        end,

        OnEnter = function()
            SCENE_MANAGER:ShowBaseScene()
            ZO_Dialogs_ShowDialog("SERVER_SELECT_DIALOG", { onSelectedCallback = function()
                SetCVar("IsServerSelected", "1")
                PregameStateManager_AdvanceStateFromState("ServerSelectIntro")
            end })
        end,

        OnExit = function()
        end,

        GetStateTransitionData = function()
            return "ShowEULA"
        end
    },
}

PregameStateManager_AddKeyboardStates(pregameStates)

--[[
Various PC-only functions.
]]--

local function OnServerLocked()
    ZO_Dialogs_ShowDialog("SERVER_LOCKED")
end

local function OnWorldListReceived()
    if PregameStateManager_GetCurrentState() == "WorldSelect_Requested" then
        PregameStateManager_SetState("WorldSelect_ShowList")
    end
end

local errorCodeToStateChange =
{
    [GLOBAL_ERROR_CODE_LOBBY_WORLD_PERMISSIONS] = "CharacterSelect_FromIngame",
    [GLOBAL_ERROR_CODE_LOBBY_CHARACTER_LOCKED] = "CharacterSelect_FromIngame",
    [GLOBAL_ERROR_CODE_LOBBY_CHARACTER_RENAME_NEEDED] = "CharacterSelect_FromIngame",
    [GLOBAL_ERROR_CODE_LOBBY_TRANSFER_FAILED] = "CharacterSelect_FromIngame",
    [GLOBAL_ERROR_CODE_DBW_TRANSFER_FAILED_0] = "CharacterSelect_FromIngame",
    [GLOBAL_ERROR_CODE_DBW_TRANSFER_FAILED_1] = "CharacterSelect_FromIngame",
    [GLOBAL_ERROR_CODE_DBW_TRANSFER_FAILED_2] = "CharacterSelect_FromIngame",
    [GLOBAL_ERROR_CODE_DBW_TRANSFER_FAILED_3] = "CharacterSelect_FromIngame",
    [GLOBAL_ERROR_CODE_DBW_TRANSFER_FAILED_4] = "CharacterSelect_FromIngame",
    [GLOBAL_ERROR_CODE_DBW_TRANSFER_FAILED_5] = "CharacterSelect_FromIngame",
    [GLOBAL_ERROR_CODE_LOBBY_CHAR_STILL_IN_GAME] = "CharacterSelect_FromIngame",
}

local function GlobalError(eventCode, errorCode, helpLinkURL, ...)
    if IsInGamepadPreferredMode() then
        -- TODO: we should harmonize this implementation of global errors, and the gamepad implementation in CreateLinkLoadingScreen_Gamepad
        return
    end
    ZO_PREGAME_HAD_GLOBAL_ERROR = true

    local errorString, errorStringFormat

    if errorCode ~= nil then
        errorStringFormat = GetString("SI_GLOBALERRORCODE", errorCode)

        if errorStringFormat ~= "" then
            if select("#", ...) > 0 then
                errorString = zo_strformat(errorStringFormat, ...)
            else
                errorString = errorStringFormat
            end
        end
    end

    if not errorString or errorString == "" then
        errorString = GetString(SI_UNKNOWN_ERROR)
    end

    if errorCodeToStateChange[errorCode] then
        PregameStateManager_SetState(errorCodeToStateChange[errorCode])
    else
        PregameStateManager_ReenterLoginState()
    end

    local force = true
    ZO_Dialogs_ReleaseAllDialogs(force)
    if helpLinkURL then
        ZO_Dialogs_ShowDialog("HANDLE_ERROR_WITH_HELP", {url = helpLinkURL}, {mainTextParams = {errorString}})
    else
        ZO_Dialogs_ShowDialog("HANDLE_ERROR", nil, {mainTextParams = {errorString}})
    end
end

local LOGIN_REQUEST_TIME_MAX = 60
function PregameStateManager_ShowLoginRequested()
    ZO_Dialogs_ShowDialog("LOGIN_REQUESTED", {loginTimeMax = LOGIN_REQUEST_TIME_MAX})
end

--[[
    Initialization and Event Registration
]]--

local function PregameStateManager_Initialize()
    EVENT_MANAGER:RegisterForEvent("PregameStateManager", EVENT_SERVER_LOCKED,                      OnServerLocked)
    EVENT_MANAGER:RegisterForEvent("PregameStateManager", EVENT_WORLD_LIST_RECEIVED,                OnWorldListReceived)
    EVENT_MANAGER:RegisterForEvent("PregameStateManager", EVENT_GLOBAL_ERROR,                       GlobalError)

    local function OnPregameUILoaded(eventId, addOnName)
        if addOnName == "ZO_Pregame" then
            RegisterForLoadingUpdates()
            EVENT_MANAGER:UnregisterForEvent("PregameStateManager", EVENT_ADD_ON_LOADED)
        end
    end

    EVENT_MANAGER:RegisterForEvent("PregameStateManager", EVENT_ADD_ON_LOADED, OnPregameUILoaded)
end

PregameStateManager_Initialize()
