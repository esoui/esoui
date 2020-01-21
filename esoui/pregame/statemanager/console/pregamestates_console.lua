
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
    EVENT_MANAGER:RegisterForEvent("PregameStateManager", EVENT_PROFILE_LOGIN_RESULT, OnProfileLoginResult)
end

PregameStateManager_Initialize()
