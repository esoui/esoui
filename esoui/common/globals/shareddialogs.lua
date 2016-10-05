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
                            SYSTEMS:GetKeyboardObject("options"):LoadDefaults()
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
                            SYSTEMS:GetGamepadObject("options"):LoadDefaults()
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
            callback =  function(dialog)
                            OpenURLByType(dialog.data.urlType)
                        end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    }
}