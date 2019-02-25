-- The ESO_Dialogs table will store the information for all the dialogs in the game
-- Some dialogs are defined here, and others are definied in InGameDialogs.lua

ESO_Dialogs["DELETE_SELECTED_CHARACTER"] = 
{
    title =
    {
        text = SI_PROMPT_TITLE_DELETE_SELECTED_CHARACTER,
    },
    mainText = 
    {
        text = SI_DELETE_CHARACTER_DIALOG_TEXT,
        align = TEXT_ALIGN_LEFT,
    },
    editBox =
    {
        matchingString = GetString(SI_DELETE_CHARACTER_CONFIRMATION_TEXT)
    },
    mustChoose = true,
    buttons =
    {
        [1] =
        {
            requiresTextInput = true,
            text = SI_DELETE_CHARACTER_CONFIRMATION_BUTTON,
            callback =  function(dialog)
                            TrySaveCharacterListOrder()
                            DeleteCharacter(dialog.data.characterId)
                            ZO_CharacterSelectDelete:SetState(BSTATE_NORMAL, false)
                            ZO_CharacterSelect_FlagAsDeleting(dialog.data.characterId, true)
                        end
        },
        
        [2] =
        {
            text = SI_DIALOG_CANCEL,
            callback =  function(dialog)
                            ZO_CharacterSelectDelete:SetState(BSTATE_NORMAL, false)
                        end
        }
    }
}

ESO_Dialogs["CONNECTING_TO_REALM"] = 
{
    title =
    {
        text = SI_PROMPT_TITLE_CONNECTING_TO_REALM,
    },
    mainText = 
    {
        text = SI_CONNECTING_TO_REALM,
        align = TEXT_ALIGN_CENTER,
    },
    modal = false,
    mustChoose = true,
    showLoadingIcon = true,
    buttons =
    {
        [1] =
        {
            text =      SI_DIALOG_CANCEL,
            keybind =   false,
            callback =  function(dialog)
                            CancelLogin()
                            PregameStateManager_SetState("AccountLogin")
                        end
        }
    }
}

ESO_Dialogs["SERVER_UNAVAILABLE"] = 
{
    title =
    {
        text = SI_PROMPT_TITLE_SERVER_UNAVAILABLE,
    },
    mainText = 
    {
        text = SI_SELECTED_SERVER_X_IS_UNAVAILABLE,
        align = TEXT_ALIGN_LEFT,
    },
    buttons =
    {
        [1] =
        {
            text = SI_OK,
            keybind = "DIALOG_NEGATIVE",
            clickSound = SOUNDS.DIALOG_ACCEPT,
        }
    }
}

ESO_Dialogs["REQUESTING_CHARACTER_LOAD"] = 
{
    title =
    {
        text = SI_DIALOG_TITLE_LOGGING_IN,
    },
    mainText = 
    {
        text = SI_CHARACTER_LOAD_REQUESTED,
        align = TEXT_ALIGN_CENTER,
    },
    mustChoose = true,
    showLoadingIcon = true,
}

ESO_Dialogs["REQUESTING_WORLD_LIST"] = 
{
    title =
    {
        text = SI_DIALOG_TITLE_LOGGING_IN,
    },
    mainText = 
    {
        text = SI_WORLD_LIST_REQUESTED,
        align = TEXT_ALIGN_CENTER,
    },
    showLoadingIcon = true,
    buttons =
    {
        [1] =
        {
            text =      SI_DIALOG_CANCEL,
            keybind =   false,
            callback =  function(dialog)
                            PregameStateManager_SetState("AccountLogin")
                        end
        }
    }
}

do
    local g_deleteCharacterShowDeleteScreen = false
    ESO_Dialogs["DELETE_SELECTED_CHARACTER_GAMEPAD"] = 
    {
        mustChoose = true,
        offsetScrollIndictorForArrow = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_DELETE_CHARACTER_DIALOG_GAMEPAD_TITLE,
        },
        mainText = 
        {
            text = SI_DELETE_CHARACTER_DIALOG_GAMEPAD_TEXT
        },
        buttons =
        {
            [1] =
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_DELETE_CHARACTER_DIALOG_GAMEPAD_CONTINUE,
                callback = function()
                    g_deleteCharacterShowDeleteScreen = true
                end,
                visible = function()
                    return GetNumCharacterDeletesRemaining() > 0
                end,
            },
            [2] =
            {
                keybind =   "DIALOG_NEGATIVE",
                text =      SI_CHARACTER_SELECT_GAMEPAD_DELETE_CANCEL,
            }
        },

        setup = function()
            g_deleteCharacterShowDeleteScreen = false
        end,

        finishedCallback = function(dialog)
            if g_deleteCharacterShowDeleteScreen then
                ZO_CharacterSelect_Gamepad_ShowDeleteScreen()
            else
                PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
                ZO_CharacterSelect_Gamepad_ReturnToCharacterList()
                ZO_CharacterSelect_Gamepad_RefreshKeybindStrip(dialog.data.keybindDescriptor)
            end
        end,
    }
end

ESO_Dialogs["DELETE_SELECTED_CHARACTER_NO_DELETES_LEFT_GAMEPAD"] = 
    {
        mustChoose = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_DELETE_CHARACTER_DISABLED_GAMEPAD_TITLE,
        },
        mainText = 
        {
            text = SI_DELETE_CHARACTER_DISABLED_GAMEPAD_TEXT
        },
        buttons =
        {
            [1] =
            {
                text = SI_OK,
                keybind = "DIALOG_PRIMARY",
                clickSound = SOUNDS.DIALOG_ACCEPT,
            }
        },

        finishedCallback = function(dialog)
            PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
            ZO_CharacterSelect_Gamepad_ReturnToCharacterList()
            ZO_CharacterSelect_Gamepad_RefreshKeybindStrip(dialog.data.keybindDescriptor)
        end,
    }

ESO_Dialogs["CHARACTER_SELECT_DELETING"] =
{
    mustChoose = true,
    setup = function(dialog, data)
        dialog:setupFunc()
        TrySaveCharacterListOrder()
        DeleteCharacter(data.characterId)
    end,
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.COOLDOWN,
    },
    title =
    {
        text = SI_DELETE_CHARACTER_GAMEPAD_DELETING,
    },
    mainText = 
    {
        text = "",
    },
    loading = 
    {
        text = GetString(SI_DELETE_CHARACTER_GAMEPAD_DELETING_CHARACTER),
    },

    finishedCallback = function(dialog)
        if dialog.isGamepad then
            -- Destroy the existing character list...then request a new one and the server will tell us which state to drop into.
            -- NOTE: This is actually passed the character id, but we're going to let the server handle the empty list case for now.
            RequestCharacterList()
        end
    end
}

ESO_Dialogs["CHARACTER_SELECT_LOGIN"] = 
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
        text = SI_CHARACTER_SELECT_GAMEPAD_LOGIN,
    },
    mainText = 
    {
        text = "",
    },
    loading = 
    {
        text = GetString(SI_CHARACTER_SELECT_GAMEPAD_LOGIN_TEXT),
    },
}

ESO_Dialogs["CHARACTER_CREATE_CREATING"] = 
{
    canQueue = true,
    mustChoose = true,
    setup = function(dialog)
        dialog:setupFunc()
    end,
    updateFn =  function(dialog, currentTime)
                    if dialog.isGamepad and not ZO_CharacterCreate_Gamepad_IsCreating() then
                        if dialog.fragment:GetState() == SCENE_FRAGMENT_SHOWN then -- ReleaseDialog only works correctly if the dialog is actually shown
                            ZO_Dialogs_ReleaseDialog("CHARACTER_CREATE_CREATING")
                        end
                    end
                end,

    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.COOLDOWN,
    },
    title =
    {
        text = SI_CREATE_CHARACTER_GAMEPAD_CREATING,
    },
    mainText = 
    {
        text = "",
    },
    loading = 
    {
        text = GetString(SI_CREATE_CHARACTER_GAMEPAD_CREATING_CHARACTER),
    },
}

ESO_Dialogs["CHARACTER_CREATE_FAILED_REASON"] = 
{
    canQueue = true,
    mustChoose = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_PROMPT_TITLE_ERROR,
    },
    mainText = 
    {
        text = SI_ERROR_REASON,
        align = TEXT_ALIGN_CENTER,
    },
    buttons =
    {
        [1] =
        {
            text = SI_OK,
            keybind = "DIALOG_NEGATIVE",
            clickSound = SOUNDS.DIALOG_ACCEPT,
        }
    },
    finishedCallback = function(dialog)
        if dialog.isGamepad then
            ZO_CharacterCreate_Gamepad_ShowFinishScreen()
        end
    end
}

ESO_Dialogs["SERVER_LOCKED"] = 
{
    title =
    {
        text = SI_DIALOG_TITLE_SERVER_LOCKED,
    },
    mainText = 
    {
        text = SI_SERVER_LOCKED,
        align = TEXT_ALIGN_LEFT,
    },
    mustChoose = true,
    buttons =
    {        
        [1] =
        {
            text = SI_DIALOG_CANCEL,
        }
    }
}

ESO_Dialogs["LOGIN_TIMEOUT"] = 
{
    title =
    {
        text = SI_DIALOG_TITLE_LOGIN_ERROR,
    },
    mainText = 
    {
        text = SI_LOGIN_TIME_OUT,
        align = TEXT_ALIGN_LEFT,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_TRY_AGAIN,
            keybind = "DIALOG_NEGATIVE",
            clickSound = SOUNDS.DIALOG_ACCEPT,
            callback =  function(dialog)
                            PregameStateManager_ReenterLoginState()
                        end
        }
    }
}

ESO_Dialogs["LOGIN_REQUESTED"] = 
{
    canQueue = true,
    title =
    {
        text = SI_DIALOG_TITLE_LOGGING_IN,
    },
    mainText = 
    {
        text = SI_LOGIN_REQUESTED,
        align = TEXT_ALIGN_CENTER,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_DIALOG_CANCEL,
            keybind =   false,
            callback =  function(dialog)
                            CancelLogin()
                            PregameStateManager_ReenterLoginState()
                        end
        }
    },
    showLoadingIcon = true,
    updateFn =  function(dialog, currentTime)
                    if(dialog.data.endTime == nil) then
                        dialog.data.endTime = currentTime + dialog.data.loginTimeMax
                        PregameStateManager_ClearError()
                    end
                    
                    if(currentTime > dialog.data.endTime) then
                        CancelLogin()
                        ZO_Dialogs_ReleaseAllDialogs()
                        ZO_Dialogs_ShowDialog("LOGIN_TIMEOUT")
                    end
                end,
}

ESO_Dialogs["LOGIN_QUEUED"] = 
{
    title =
    {
        text = SI_PROMPT_TITLE_SERVER_FULL,
    },
    mainText = 
    {
        text = SI_LOGIN_QUEUE_TEXT,
        timer = 1,
        verboseTimer = false,
        align = TEXT_ALIGN_LEFT,
    },
    modal = false,
    mustChoose = true, -- no inadvertent keypresses should close this!
    showLoadingIcon = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 5, 5),
    buttons =
    {
        [1] =
        {
            text =      SI_LOGIN_QUEUE_CANCEL_TEXT,
            keybind =   false,
            callback =  function(dialog)
                            CancelLogin()
                            PregameStateManager_SetState("AccountLogin")
                        end,
        }
    },
}

ESO_Dialogs["BAD_LOGIN"] = 
{
    title =
    {
        text = SI_DIALOG_TITLE_LOGIN_ERROR,
    },
    mainText = 
    {
        text = SI_BAD_LOGIN,
        align = TEXT_ALIGN_LEFT,
    },
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_BUTTON_VIEW_ACCOUNT_PAGE,
            keybind = "DIALOG_TERTIARY",
            clickSound = SOUNDS.DIALOG_ACCEPT,
            callback =  function(dialog)
                            ConfirmOpenURL(dialog.data.accountPageURL)
                            PregameStateManager_ReenterLoginState()
                        end
        },
        [2] =
        {
            text =      SI_DIALOG_EXIT,
            keybind =   "DIALOG_NEGATIVE",
            clickSound = SOUNDS.DIALOG_ACCEPT,
            callback =  function(dialog)
                            PregameStateManager_ReenterLoginState()
                        end
        }
    }
}

ESO_Dialogs["BAD_LOGIN_PAYMENT_EXPIRED"] =
{
    title =
    {
        text = SI_DIALOG_TITLE_PAYMENT_EXPIRED,
    },
    mainText = 
    {
        text = SI_DIALOG_TEXT_PAYMENT_EXPIRED,
        align = TEXT_ALIGN_LEFT,
    },
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_BUTTON_VIEW_ACCOUNT_PAGE,
            keybind = "DIALOG_TERTIARY",
            clickSound = SOUNDS.DIALOG_ACCEPT,
            callback =  function(dialog)
                            ConfirmOpenURL(dialog.data.accountPageURL)
                            PregameStateManager_ReenterLoginState()
                        end
        },
        [2] =
        {
            text = SI_DIALOG_EXIT,
            keybind = "DIALOG_NEGATIVE",
            clickSound = SOUNDS.DIALOG_ACCEPT,
            callback =  function(dialog)
                            PregameStateManager_ReenterLoginState()
                        end
        },
    }
}

ESO_Dialogs["AUTHENTICATION_SERVER_DOWN"] = 
{
    title =
    {
        text = SI_DIALOG_TITLE_SERVER_UNAVAILABLE,
    },
    mainText = 
    {
        text = SI_AUTHENTICATION_SERVER_DOWN,
        align = TEXT_ALIGN_LEFT,
    },
    buttons =
    {
        [1] =
        {
            text = SI_TRY_AGAIN,
            keybind = "DIALOG_NEGATIVE",
            clickSound = SOUNDS.DIALOG_ACCEPT,
            callback =  function(dialog)
                            PregameStateManager_ReenterLoginState()
                        end
        }
    }
}

ESO_Dialogs["HANDLE_ERROR"] = 
{
    title =
    {
        text = SI_PROMPT_TITLE_ERROR,
    },
    mainText = 
    {
        text = SI_ERROR_REASON,
        align = TEXT_ALIGN_LEFT,
    },
    buttons =
    {
        [1] =
        {
            text = SI_OK,
            keybind = "DIALOG_NEGATIVE",
            clickSound = SOUNDS.DIALOG_ACCEPT,
        }
    }
}

ESO_Dialogs["HANDLE_ERROR_WITH_HELP"] = 
{
    title =
    {
        text = SI_PROMPT_TITLE_ERROR,
    },
    mainText = 
    {
        text = SI_ERROR_REASON,
        align = TEXT_ALIGN_LEFT,
    },
    buttons =
    {
        [1] =
        {
            text = SI_ERROR_DIALOG_HELP,
            keybind = "DIALOG_TERTIARY",
            callback =  function(dialog)
                            ConfirmOpenURL(dialog.data.url)
                        end,
        },
        [2] =
        {
            text = SI_OK,
            keybind = "DIALOG_NEGATIVE",
            clickSound = SOUNDS.DIALOG_ACCEPT,
        }
    }
}

ESO_Dialogs["CONFIRM_OPEN_URL"] =
{
    canQueue = true,
    title =
    {
        text = SI_CONFIRM_OPEN_URL_TITLE,
    },
    mainText =
    {
        text = SI_CONFIRM_OPEN_URL_TEXT,
    },
    buttons =
    {
        [1] =
        {
            text = SI_URL_DIALOG_OPEN,
            callback =  function(dialog)
                            ConfirmOpenURL(dialog.data.url)
                        end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    }
}

ESO_Dialogs["SERVER_DOWN_FOR_MAINTENANCE"] =
{
    title =
    {
        text = SI_SERVER_MAINTENANCE_DIALOG_TITLE,
    },
    mainText =
    {
        text = SI_SERVER_MAINTENANCE_DIALOG_TEXT,
    },
    buttons =
    {
        [1] =
        {
            text = SI_OK,
            callback =  function(dialog)
                            PregameStateManager_ReenterLoginState()
                        end
        },
    }
}

local otpTextParams = {}

local function UpdateOTPDuration(dialog)
    local timeLeft = dialog.data.otpExpirationMs - GetFrameTimeMilliseconds()
    if timeLeft >= 0 then
        ZO_ClearNumericallyIndexedTable(otpTextParams)
        table.insert(otpTextParams, timeLeft)
        if dialog.data.otpReason == LOGIN_STATUS_OTP_PENDING then
            table.insert(otpTextParams, 1, GetString(SI_OTP_DIALOG_SUBMIT))
        end
        ZO_Dialogs_UpdateDialogMainText(dialog, nil, otpTextParams)
    else
        ZO_Dialogs_ReleaseDialog(dialog)
        PregameStateManager_ReenterLoginState()
    end
end

local otpButtons = {
        [1] =
        {
            requiresTextInput = true,
            text = SI_OTP_DIALOG_SUBMIT,
            callback =  function(dialog)
                            SendOneTimePassword(ZO_Dialogs_GetEditBoxText(dialog))
                            PregameStateManager_ShowLoginRequested() -- The verification might take a little to get back from the server, show this dialog immediately.
                        end
        },
        
        [2] =
        {
            text = SI_OTP_DIALOG_CANCEL,
            keybind = false,
            callback =  function(dialog)
                            PregameStateManager_ReenterLoginState()
                        end
        }
}

ESO_Dialogs["PROVIDE_OTP_INITIAL"] = 
{
    title =
    {
        text = SI_OTP_DIALOG_TITLE,
    },
    mainText = 
    {
        text = SI_PROVIDE_OTP_INITIAL_DIALOG_TEXT,
        timer = 2,
        align = TEXT_ALIGN_LEFT,
    },
    editBox = {},
    mustChoose = true,
    buttons = otpButtons,
    updateFn = UpdateOTPDuration
}

ESO_Dialogs["PROVIDE_OTP_SUBSEQUENT"] = 
{
    title =
    {
        text = SI_OTP_DIALOG_TITLE,
    },
    mainText = 
    {
        text = SI_PROVIDE_OTP_SUBSEQUENT_DIALOG_TEXT,
        timer = 1,
        align = TEXT_ALIGN_LEFT,
    },
    editBox = {},
    mustChoose = true,
    buttons = otpButtons,
    updateFn = UpdateOTPDuration
}

ESO_Dialogs["BAD_CLIENT_VERSION"] = 
{
    title =
    {
        text = SI_BAD_CLIENT_VERSION_TITLE,
    },
    mainText = 
    {
        text = SI_BAD_CLIENT_VERSION_TEXT,
        align = TEXT_ALIGN_LEFT,
    },
    mustChoose = true,
    buttons =
    {
        [1] =
        {
            text = SI_OK,
            callback =  function(dialog)
                            PregameQuit()
                        end
        },
    }
}

-- Dialogs for create/link account flow on PC --

ESO_Dialogs["LINKED_LOGIN_KEYBOARD"] =
{
    canQueue = true,
    title =
    {
        text = SI_DIALOG_TITLE_LOGGING_IN,
    },
    mainText = 
    {
        text = SI_LOGIN_REQUESTED,
        align = TEXT_ALIGN_CENTER,
    },
    mustChoose = true,
    showLoadingIcon = true,
    -- Can't cancel this login...happens automatically from the create/link account flow on PC
}

ESO_Dialogs["CREATING_ACCOUNT_KEYBOARD"] =
{
    canQueue = true,
    title =
    {
        text = SI_KEYBOARD_CREATEACCOUNT_DIALOG_HEADER,
    },
    mainText =
    {
        text = SI_CREATEACCOUNT_CREATING_ACCOUNT,
        align = TEXT_ALIGN_CENTER,
    },
    mustChoose = true,
    showLoadingIcon = true,
    -- Must be cleared from an event
}

ESO_Dialogs["CREATE_ACCOUNT_SUCCESS_KEYBOARD"] =
{
    canQueue = true,
    title =
    {
        text = SI_KEYBOARD_CREATEACCOUNT_ACCOUNT_CREATED_DIALOG_HEADER,
    },
    mainText =
    {
        text = SI_KEYBOARD_CREATEACCOUNT_SUCCESS_DIALOG_BODY_FORMAT,
    },
    noChoiceCallback = function()
            LOGIN_MANAGER_KEYBOARD:AttemptLinkedLogin()
        end,
    buttons =
    {
        {
            text = SI_DIALOG_CLOSE,
            keybind = "DIALOG_NEGATIVE",
            callback = function()
                    LOGIN_MANAGER_KEYBOARD:AttemptLinkedLogin()
                end,
        },
    },
}

ESO_Dialogs["CREATE_ACCOUNT_ERROR_KEYBOARD"] =
{
    canQueue = true,
    title =
    {
        text = SI_CREATEACCOUNT_ERROR_HEADER,
    },
    mainText =
    {
        text = SI_CREATEACCOUNT_FAILURE_MESSAGE,
    },
    buttons =
    {
        {
            text = SI_OK,
            keybind = "DIALOG_NEGATIVE",
        },
    },
}

ESO_Dialogs["LINKING_ACCOUNTS_KEYBOARD"] =
{
    canQueue = true,
    title =
    {
        text = SI_KEYBOARD_LINKACCOUNT_DIALOG_HEADER,
    },
    mainText =
    {
        text = SI_LINKACCOUNT_LINKING_ACCOUNT,
        align = TEXT_ALIGN_CENTER,
    },
    mustChoose = true,
    showLoadingIcon = true,
    -- Must be cleared from an event
}

ESO_Dialogs["LINKING_ACCOUNTS_SUCCESS_KEYBOARD"] =
{
    canQueue = true,
    title =
    {
        text = SI_KEYBOARD_LINKACCOUNT_ACCOUNTS_LINKED_DIALOG_HEADER,
    },
    mainText =
    {
        text = function()
            local serviceType = GetPlatformServiceType()
            local accountTypeName = GetString("SI_PLATFORMSERVICETYPE", serviceType)
            return zo_strformat(GetString(SI_KEYBOARD_LINKACCOUNT_ACCOUNTS_LINKED_DIALOG_BODY_FORMAT), accountTypeName)
        end,
    },
    noChoiceCallback = function()
            LOGIN_MANAGER_KEYBOARD:AttemptLinkedLogin()
        end,
    buttons =
    {
        {
            text = SI_DIALOG_CLOSE,
            keybind = "DIALOG_NEGATIVE",
            callback = function()
                    LOGIN_MANAGER_KEYBOARD:AttemptLinkedLogin()
                end,
        },
    },
}

ESO_Dialogs["LINKING_ACCOUNTS_ERROR_KEYBOARD"] =
{
    canQueue = true,
    title =
    {
        text = SI_LINKACCOUNT_ERROR_HEADER,
    },
    mainText =
    {
        text = SI_LINKACCOUNT_FAILURE_MESSAGE,
    },
    buttons =
    {
        {
            text = SI_OK,
            keybind = "DIALOG_NEGATIVE",
        },
    }, 
}

ESO_Dialogs["LINKED_LOGIN_ERROR_KEYBOARD"] =
{
    canQueue = true,
    title =
    {
        text = SI_DIALOG_TITLE_LOGIN_ERROR,
    },
    mainText=
    {
        text = SI_KEYBOARD_LINKED_LOGIN_ERROR_MESSAGE,
    },
    buttons =
    {
        {
            text = SI_DIALOG_CLOSE,
            keybind = "DIALOG_NEGATIVE",
        }
    }
}

-- Character Rename Dialogs

ESO_Dialogs["CHARACTER_SELECT_CHARACTER_RENAMING"] =
{
    canQueue = true,
    mustChoose = true,
    setup = function(dialog, data)
        dialog:setupFunc()
    end,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.COOLDOWN,
    },
    title =
    {
        text = SI_RENAME_CHARACTER_RENAMING_DIALOG_HEADER,
    },
    mainText =
    {
        text = function()
            if not IsInGamepadPreferredMode() then
                return GetString(SI_RENAME_CHARACTER_RENAMING_DIALOG_BODY)
            else
                return ""
            end
        end,
        align = TEXT_ALIGN_CENTER,
    },
    loading = 
    {
        text = GetString(SI_RENAME_CHARACTER_RENAMING_DIALOG_BODY),
    },
    showLoadingIcon = true,
    -- This dialog isn't cleared by the user, but from an event
    -- The current events that close this dialog are EVENT_CHARACTER_RENAME_RESULT
}

ESO_Dialogs["CHARACTER_SELECT_RENAME_CHARACTER_ERROR"] =
{
    canQueue = true,
    mustChoose = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title = 
    {
        text = SI_SERVICES_DIALOG_HEADER_FORMAT,
    },
    mainText = 
    {
        text = SI_SERVICES_DIALOG_BODY_FORMAT,
    },
    buttons = 
    {
        {
            text = SI_RENAME_CHARACTER_BACK_KEYBIND,
            keybind = "DIALOG_NEGATIVE",
            callback = function(dialog)
                            if dialog.data and dialog.data.callback then
                                dialog.data.callback()
                            end
                        end,
        },
    },
}

ESO_Dialogs["CHARACTER_SELECT_RENAME_CHARACTER_SUCCESS"] =
{
    canQueue = true,
    mustChoose = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title = 
    {
        text = SI_RENAME_CHARACTER_SUCCESS_HEADER,
    },
    mainText = 
    {
        text = SI_RENAME_CHARACTER_SUCCESS_BODY,
    },
    buttons = 
    {
        {
            text = function()
                if IsInGamepadPreferredMode() then
                    return GetString(SI_RENAME_CHARACTER_BACK_KEYBIND)
                else
                    return GetString(SI_DIALOG_CLOSE)
                end
            end,
            keybind = "DIALOG_NEGATIVE",
            callback = function(dialog)
                if dialog.data and dialog.data.callback then
                    dialog.data.callback()
                end
            end,
        },
    },
}

-- Service Dialogs

ESO_Dialogs["INELIGIBLE_SERVICE"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title = 
    {
        text = SI_SERVICE_ERROR_DIALOG_CHARACTER_INELIGIBLE_HEADER,
    },
    mainText = 
    {
        text = SI_SERVICE_ERROR_DIALOG_CHARACTER_INELIGIBLE_BODY,
    },
    buttons = 
    {
        {
            text = SI_DIALOG_CLOSE,
            keybind = "DIALOG_NEGATIVE",
        },
    },
}

-- Character Edit Dialogs

ESO_Dialogs["CHARACTER_CREATE_CONFIRM_SAVE_CHANGES"] =
{
    canQueue = true,
    mustChoose = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_CHARACTER_EDIT_CONFIRM_CHANGES_TITLE,
    },
    mainText = 
    {
        text = SI_CHARACTER_EDIT_CONFIRM_CHANGES_BODY,
    },
    buttons =
    {
        {
            text = SI_SAVE,
            keybind = "DIALOG_PRIMARY",
            callback =  function(dialog)
                            local tokenType = dialog.data.tokenType
                            CharacterEditSaveCharacterChanges(tokenType)
                            ZO_Dialogs_ShowDialog("CHARACTER_CREATE_SAVING_CHANGES")
                        end,
        },

        {
            text = SI_DIALOG_CANCEL,
            keybind = "DIALOG_NEGATIVE",
            callback =  function(dialog)
                            -- do nothing
                        end,
        },
    }
}

ESO_Dialogs["CHARACTER_CREATE_SAVING_CHANGES"] =
{
    canQueue = true,
    mustChoose = true,
    setup = function(dialog, data)
        dialog:setupFunc()
    end,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.COOLDOWN,
    },
    title =
    {
        text = SI_CHARACTER_EDIT_SAVING_CHANGES_TITLE,
    },
    mainText =
    {
        text = function()
            if not IsInGamepadPreferredMode() then
                return GetString(SI_CHARACTER_EDIT_SAVING_CHANGES_BODY)
            else
                return ""
            end
        end,
        align = TEXT_ALIGN_CENTER,
    },
    loading = 
    {
        text = GetString(SI_CHARACTER_EDIT_SAVING_CHANGES_BODY),
    },
    showLoadingIcon = true,
    -- This dialog isn't cleared by the user, but from an event
    -- The current events that close this dialog are EVENT_CHARACTER_EDIT_SUCCEEDED, EVENT_CHARACTER_EDIT_FAILED
}

ESO_Dialogs["CHARACTER_CREATE_SAVE_ERROR"] =
{
    canQueue = true,
    mustChoose = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title = 
    {
        text = SI_CHARACTER_EDIT_SAVE_ERROR_TITLE,
    },
    mainText = 
    {
        text = SI_SERVICES_DIALOG_BODY_FORMAT,
    },
    buttons = 
    {
        {
            text = SI_RENAME_CHARACTER_BACK_KEYBIND,
            keybind = "DIALOG_NEGATIVE",
            callback = function(dialog)
                            --just close
                        end,
        },
    },
}

ESO_Dialogs["CHARACTER_CREATE_SAVE_SUCCESS"] =
{
    canQueue = true,
    mustChoose = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title = 
    {
        text = SI_CHARACTER_EDIT_SAVE_SUCCESS_TITLE,
    },
    mainText = 
    {
        text = SI_CHARACTER_EDIT_SAVE_SUCCESS_BODY,
    },
    buttons = 
    {
        {
            text = function()
                if IsInGamepadPreferredMode() then
                    return GetString(SI_RENAME_CHARACTER_BACK_KEYBIND)
                else
                    return GetString(SI_DIALOG_CLOSE)
                end
            end,
            keybind = "DIALOG_NEGATIVE",
            callback = function(dialog)
                PregameStateManager_SetState("CharacterSelect_FromIngame")
            end,
        },
    },
}

ESO_Dialogs["CHARACTER_CREATE_CONFIRM_REVERT_CHANGES"] =
{
    canQueue = true,
    mustChoose = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_CHARACTER_EDIT_REVERT_CHANGES_TITLE,
    },
    mainText = 
    {
        text = SI_CHARACTER_EDIT_REVERT_CHANGES_BODY,
    },
    buttons =
    {
        {
            text = SI_DIALOG_YES,
            keybind = "DIALOG_PRIMARY",
            callback =  function(dialog)
                            PregameStateManager_SetState(dialog.data.newState)
                        end,
        },

        {
            text = SI_DIALOG_NO,
            keybind = "DIALOG_NEGATIVE",
            callback =  function(dialog)
                            -- do nothing
                        end,
        },
    }
}

ESO_Dialogs["CHAPTER_UPGRADE_CONTINUE"] = 
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    canQueue = true,

    title =
    {
        text = SI_CHAPTER_UPGRADE_CONTINUE_DIALOG_TITLE
    },

    mainText =
    {
        text = function()
            local platformServiceType = GetPlatformServiceType()
            local upgradeMethodsStringId = ZO_PLATFORM_ALLOWS_CHAPTER_CODE_ENTRY[platformServiceType] and SI_CHAPTER_UPGRADE_CONTINUE_DIALOG_BODY_UPGRADE_OR_CODE or SI_CHAPTER_UPGRADE_CONTINUE_DIALOG_BODY_UPGRADE_ONLY
            local chapterUpgradeId = GetCurrentChapterUpgradeId()
            local chapterCollectibleId = GetChapterCollectibleId(chapterUpgradeId)
            local chapterCollectibleName = GetCollectibleName(chapterCollectibleId)
            return zo_strformat(SI_CHAPTER_UPGRADE_CONTINUE_DIALOG_BODY_FORMAT, GetString(upgradeMethodsStringId), ZO_GetPlatformStoreName(), chapterCollectibleName)
        end,
    },

    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_CONFIRM,
            callback = function(dialog)
                            if dialog.data then
                                dialog.data.continue = true
                            end
                        end,
        },

        [2] =
        {
            text = SI_DIALOG_CANCEL,
            callback = function(dialog)
                            if dialog.data then
                                dialog.data.continue = false
                            end
                        end,
        },
    },
    finishedCallback = function(dialog)
        if dialog.data and dialog.data.finishedCallback then
            dialog.data.finishedCallback(dialog)
        end
    end,
}

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
            callback =  function(dialog)
                            PregameStateManager_AdvanceState()
                        end,
        },

        {
            text = SI_CONSOLE_LEGAL_BUTTON_DISAGREE,
            keybind = "DIALOG_NEGATIVE",
            callback =  function(dialog)
                            -- do nothing
                        end,
        },
    }
}