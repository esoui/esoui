ESO_Dialogs["LEGAL_AGREEMENT_UPDATED_ACKNOWLEDGE"] =
{
    mustChoose = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    mainText = 
    {
        text = SI_CONSOLE_LEGAL_AGREEMENT_UPDATED_ACKNOWLEDGE_DIALOG_BODY,
    },
    buttons =
    {
        {
            text = SI_CONSOLE_LEGAL_BUTTON_AGREE,
            keybind = "DIALOG_PRIMARY",
            callback = function(dialog)
                PregameStateManager_AdvanceState()
            end,
        },

        {
            text = SI_CONSOLE_LEGAL_BUTTON_DISAGREE,
            keybind = "DIALOG_NEGATIVE",
            callback = function(dialog)
                PREGAME_INITIAL_SCREEN_GAMEPAD:ShowError(GetString(SI_LEGAL_DECLINE_HEADER), GetString(SI_LEGAL_DECLINE_PROMPT))
            end,
        },
    }
}

ESO_Dialogs["FREE_TRIAL_INACTIVE"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_FREE_TRIAL_PURCHASE_DIALOG_HEADER,
    },
    mainText =
    {
        text = SI_FREE_TRIAL_PURCHASE_DIALOG_BODY,
    },
    noChoiceCallback = function()
        ZO_Disconnect()
    end,
    buttons =
    {
        {
            text = SI_FREE_TRIAL_PURCHASE_KEYBIND,
            keybind = "DIALOG_PRIMARY",
            callback = function()
               ShowPlatformESOGameClientUI()
               ZO_Disconnect()
            end,
        },
        {
            text = SI_GAMEPAD_BACK_OPTION,
            keybind = "DIALOG_NEGATIVE",
            callback = function()
                ZO_Disconnect()
            end,
        },
    },
}
