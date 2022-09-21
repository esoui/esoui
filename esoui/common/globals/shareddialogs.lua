ESO_Dialogs["OPTIONS_RESET_TO_DEFAULTS"] = 
{
    mustChoose = true,
    title =
    {
        text = SI_OPTIONS_RESET_TITLE,
    },
    mainText = 
    {
        text =  SI_OPTIONS_RESET_PROMPT,
    },
    buttons =
    {
        [1] =
        {
            text = SI_OPTIONS_RESET,
            callback =  function(dialog)
                            SYSTEMS:GetKeyboardObject("options"):LoadAllDefaults()
                        end
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    }
}

ESO_Dialogs["GAMEPAD_OPTIONS_RESET_TO_DEFAULTS"] = 
{
    mustChoose = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_OPTIONS_RESET_TITLE,
    },
    mainText = 
    {
        text =  function() 
                    if SCENE_MANAGER:IsShowing("gamepad_options_root") then
                        return SI_OPTIONS_RESET_ALL_PROMPT
                    else
                        return SI_OPTIONS_RESET_PROMPT
                    end
                end,
    },
    buttons =
    {
        [1] =
        {
            text = SI_OPTIONS_RESET,
            callback =  function(dialog)
                            SYSTEMS:GetGamepadObject("options"):LoadAllDefaults()
                        end
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    }
}

ESO_Dialogs["WAIT_FOR_CONSOLE_NAME_VALIDATION"] = 
{
    setup = function(dialog)
        dialog:setupFunc()
    end,
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.COOLDOWN,
    },
    mustChoose = true,
    title =
    {
        text = SI_GAMEPAD_CONSOLE_WAIT_FOR_NAME_VALIDATION_TITLE,
    },
    loading = 
    {
        text = GetString(SI_GAMEPAD_CONSOLE_WAIT_FOR_NAME_VALIDATION_TEXT),
    },
    buttons =
    {
    }
}

ESO_Dialogs["CONFIRM_OPEN_URL_BY_TYPE"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    canQueue = true,
    title =
    {
        text = SI_CONFIRM_OPEN_URL_TITLE,
    },
    mainText =
    {
        text = function(dialog)
            if ShouldOpenURLTypeInOverlay(dialog.data.urlType) then
                return SI_CONFIRM_OPEN_STEAM_STORE
            else
                return SI_CONFIRM_OPEN_URL_TEXT
            end
        end,
    },
    buttons =
    {
        [1] =
        {
            text = SI_URL_DIALOG_OPEN,
            callback = function(dialog)
                OpenURLByType(dialog.data.urlType)
                dialog.data.confirmed = true
            end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    },
    finishedCallback = function(dialog)
        if dialog.data.finishedCallback then
            dialog.data.finishedCallback(dialog)
        end
    end,
}

ESO_Dialogs["SHOW_REDEEM_CODE"] = 
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_ENTER_CODE_DIALOG_TITLE,
    },

    mainText =
    {
        text = SI_OPEN_ENTER_CODE_PAGE,
    },

    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_LOG_OUT_ENTER_CODE,
            callback = function(dialog)
                OpenURLByType(APPROVED_URL_ESO_ACCOUNT)
            end,
        },

        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["SHOW_REDEEM_CODE_CONSOLE"] = 
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = SI_ENTER_CODE_DIALOG_TITLE,
    },

    mainText =
    {
        text = SI_ENTER_CODE_DIALOG_BODY,
    },

    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_LOG_OUT_ENTER_CODE,
            callback = function(dialog)
                if IsConsoleUI() then
                    ShowConsoleRedeemCodeUI()
                else -- It's intended that Heron do this as well
                    OpenURLByType(APPROVED_URL_ESO_ACCOUNT)
                end
            end,
        },

        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["GAMERCARD_UNAVAILABLE"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title = 
    {
        text = ZO_IsPlaystationPlatform() and SI_GAMEPAD_PSN_PROFILE_UNAVAILABLE_DIALOG_TITLE or SI_GAMEPAD_GAMERCARD_UNAVAILABLE_DIALOG_TITLE,
    },
    mainText =
    {
        text = ZO_IsPlaystationPlatform() and SI_GAMEPAD_PSN_PROFILE_UNAVAILABLE_DIALOG_BODY or SI_GAMEPAD_GAMERCARD_UNAVAILABLE_DIALOG_BODY,
    },
    buttons =
    {
        {
            text = SI_OK,
        }
    }
}