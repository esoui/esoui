ZO_Dialogs_RegisterCustomDialog(
        "CONFIRM_UNSAFE_URL",
        {
            gamepadInfo =
            {
                dialogType = GAMEPAD_DIALOGS.BASIC,
            },
            title =
            {
                text = SI_CONFIRM_UNSAFE_URL_TITLE,
            },
            mainText =
            {
                text = SI_CONFIRM_UNSAFE_URL_TEXT,
            },
            buttons =
            {
                [1] =
                {
                    text = SI_DIALOG_YES,
                    callback =  function(dialog)
                                    ConfirmOpenURL(dialog.data.URL)
                                end,
                },
        
                [2] =
                {
                    text = SI_DIALOG_NO,
                }
            }
        }
    )

EVENT_MANAGER:RegisterForEvent("ZoConfirmURL", EVENT_CONFIRM_UNSAFE_URL, function(eventCode, URL)
    ZO_Dialogs_ReleaseDialog("CONFIRM_UNSAFE_URL")
    ZO_Dialogs_ShowPlatformDialog("CONFIRM_UNSAFE_URL", { URL = URL }, {mainTextParams = { URL }})
end)