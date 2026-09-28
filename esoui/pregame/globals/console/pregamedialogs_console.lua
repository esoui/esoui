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
