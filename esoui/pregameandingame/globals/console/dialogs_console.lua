ESO_Dialogs["REQUESTING_ACCOUNT_DATA"] = 
{
    canQueue = true,
    mustChoose = true,
    setup = function(dialog)
        dialog:setupFunc()
    end,

    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.COOLDOWN,
    },
    title =
    {
        text = GetString("SI_SETTINGSYSTEMPANEL", SETTING_PANEL_ACCOUNT),
    },
    mainText = 
    {
        text = "",
    },
    loading = 
    {
        text = GetString(SI_INTERFACE_OPTIONS_DEFERRED_LOADING_TEXT),
    },
}