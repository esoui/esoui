
local consolePregameStates =
{
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
}

PregameStateManager_AddGamepadStates(consolePregameStates)

local function OnProfileLoginResult(event, isSuccess, profileError)
    --Don't return to IIS if we're on Server Select and NO_PROFILE was returned because they probably cancelled the selection
    if isSuccess == false and not (profileError == PROFILE_LOGIN_ERROR_NO_PROFILE and SCENE_MANAGER:IsShowing("GameStartup")) then
        local errorStringFormat = GetString("SI_PROFILELOGINERROR", profileError)

        if errorStringFormat == "" then
            errorStringFormat = GetString("SI_PROFILELOGINERROR", PROFILE_LOGIN_ERROR_UNKNOWN_ERROR)
        end

        local errorString = zo_strformat(errorStringFormat, GetURLTextByType(APPROVED_URL_ESO_HELP))

        PREGAME_INITIAL_SCREEN_GAMEPAD:ShowError(GetString(SI_PROFILE_LOAD_FAILED_TITLE), errorString)
    end
end

local function PregameStateManager_Initialize()
    EVENT_MANAGER:RegisterForEvent("PregameStateManager", EVENT_PROFILE_LOGIN_RESULT, OnProfileLoginResult)
end

PregameStateManager_Initialize()
