ZO_Dialogs_RegisterCustomDialog(
        "CONFIRM_MAIL",
        {
            gamepadInfo =
            {
                dialogType = GAMEPAD_DIALOGS.BASIC,
            },
            title =
            {
                text = SI_CONFIRM_MAIL_TITLE,
            },
            mainText =
            {
                text = SI_CONFIRM_MAIL_TEXT,
            },
            buttons =
            {
                [1] =
                {
                    text = SI_DIALOG_YES,
                    callback =  function(dialog)
                                    ConfirmSendMail(ZO_FormatManualNameEntry(dialog.data.to), dialog.data.subject, dialog.data.body)
                                end,
                },
        
                [2] =
                {
                    text = SI_DIALOG_NO,
                    callback = function(dialog)
                                    CancelSendMail()
                               end,
                }
            }
        }
    )

EVENT_MANAGER:RegisterForEvent("ZoConfirmMail", EVENT_CONFIRM_SEND_MAIL, function(eventCode, to, subject, body, numAttachments, attachedMoney)
    ZO_Dialogs_ReleaseDialog("CONFIRM_MAIL")
    local confirmText
    if numAttachments > 0 and attachedMoney > 0 then
        confirmText = zo_strformat(SI_CONFIRM_MAIL_GOLD_AND_ITEMS, ZO_Currency_FormatPlatform(CURT_MONEY, attachedMoney, ZO_CURRENCY_FORMAT_WHITE_AMOUNT_ICON), numAttachments, ZO_FormatUserFacingDisplayName(to))
    elseif numAttachments > 0 then
        confirmText = zo_strformat(SI_CONFIRM_MAIL_ITEMS, numAttachments, ZO_FormatUserFacingDisplayName(to))
    else
        confirmText = zo_strformat(SI_CONFIRM_MAIL_GOLD, ZO_Currency_FormatPlatform(CURT_MONEY, attachedMoney, ZO_CURRENCY_FORMAT_WHITE_AMOUNT_ICON), ZO_FormatUserFacingDisplayName(to))
    end
    ZO_Dialogs_ShowPlatformDialog("CONFIRM_MAIL", { to = to, subject = subject, body = body }, {mainTextParams = { confirmText }})
end)

-- Delete mail dialog.  Title and mainText change based on types of attachments.
ZO_Dialogs_RegisterCustomDialog("DELETE_MAIL_WITH_ATTACHMENTS",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
            
        title = 
        { 
            text = function(dialog) return dialog.data.title end, 
        },

        mainText = 
        { 
            text = function(dialog) return dialog.data.body end, 
        },

        editBox =
        {
            matchingString = GetString(SI_DELETE_MAIL_CONFIRMATION_TEXT)
        },
        
        noChoiceCallback = function(dialog)
            CancelDeleteMail(dialog.data.mailId)
        end,

        buttons =
        {
            [1] =
            {
                requiresTextInput = true,
                text = SI_MAIL_DELETE,
                callback = function(dialog)
                    local confirmDelete = ZO_Dialogs_GetEditBoxText(dialog)
                    local compareString = GetString(SI_DELETE_MAIL_CONFIRMATION_TEXT)
                    if confirmDelete and confirmDelete == compareString then
                        dialog.data.confirmationCallback(dialog.data.mailId)
                    end
                end,
            },
        
            [2] =
            {
                text = SI_DIALOG_CANCEL,
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialog("DELETE_MAIL_WITH_ATTACHMENTS")
                    CancelDeleteMail(dialog.data.mailId)
                end,
            }
        }
    }
)

-- Gamepad delete mail dialog.  Title and mainText change based on types of attachments.
ZO_Dialogs_RegisterCustomDialog("DELETE_MAIL_WITH_ATTACHMENTS_GAMEPAD",
    {
        blockDialogReleaseOnPress = true,

        canQueue = true,

        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
            allowRightStickPassThrough = true,
        },

        noChoiceCallback = function(dialog)
            CancelDeleteMail(dialog.data.mailId)
        end,

        title = 
        { 
            text = function(dialog) return dialog.data.title end, 
        },

        mainText = 
        { 
            text = function(dialog) return dialog.data.body end, 
        },

        buttons =
        {
            {
                onShowCooldown = 2000,
                keybind = "DIALOG_PRIMARY",
                text = SI_MAIL_DELETE,
                callback = function(dialog)
                    dialog.data.confirmationCallback(dialog.data.mailId)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("DELETE_MAIL_WITH_ATTACHMENTS_GAMEPAD")
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialog("DELETE_MAIL_WITH_ATTACHMENTS_GAMEPAD")
                    CancelDeleteMail(dialog.data.mailId)
                end,
            },
        }
    }
)

EVENT_MANAGER:RegisterForEvent("ZoDeleteMail", EVENT_CONFIRM_DELETE_MAIL, function(eventCode, mailId)
    ZO_Dialogs_ReleaseDialog("DELETE_MAIL_WITH_ATTACHMENTS")
    ZO_Dialogs_ReleaseDialog("DELETE_MAIL_WITH_ATTACHMENTS_GAMEPAD")
    local function OnDeleteMailConfirmed(mailId)
        ConfirmDeleteMail(mailId)
        PlaySound(SOUNDS.MAIL_ITEM_DELETED)
    end
    local dialogTextParams = 
    {
        mainTextParams = { GetString(SI_DELETE_MAIL_CONFIRMATION_TEXT), },
    }

    local numAttachments, attachedGold, codAmount = GetMailAttachmentInfo(mailId)
    local hasAttachments = numAttachments > 0
    local hasAttachedGold = attachedGold > 0
    if not hasAttachments and not hasAttachedGold then
        OnDeleteMailConfirmed(mailId)
    else
        local dialogName = "DELETE_MAIL_WITH_ATTACHMENTS"
        if IsInGamepadPreferredMode() then
            dialogName = "DELETE_MAIL_WITH_ATTACHMENTS_GAMEPAD"
        end
        if hasAttachments and hasAttachedGold then
            local dialogCallbackData = 
            {
                mailId = mailId, 
                title = SI_PROMPT_TITLE_DELETE_MAIL_ATTACHMENTS,
                body = IsInGamepadPreferredMode() and SI_MAIL_CONFIRM_DELETE_ATTACHMENTS_AND_MONEY_GAMEPAD or SI_MAIL_CONFIRM_DELETE_ATTACHMENTS_AND_MONEY,
                confirmationCallback = OnDeleteMailConfirmed,
            }
            ZO_Dialogs_ShowPlatformDialog(dialogName, dialogCallbackData, dialogTextParams)
        elseif hasAttachments then
            local dialogCallbackData = 
            {
                mailId = mailId, 
                title = SI_PROMPT_TITLE_DELETE_MAIL_ATTACHMENTS,
                body = IsInGamepadPreferredMode() and SI_MAIL_CONFIRM_DELETE_ATTACHMENTS_GAMEPAD or SI_MAIL_CONFIRM_DELETE_ATTACHMENTS,
                confirmationCallback = OnDeleteMailConfirmed,
            }
            ZO_Dialogs_ShowPlatformDialog(dialogName, dialogCallbackData, dialogTextParams)
        elseif hasAttachedGold then
            local dialogCallbackData = 
            {
                mailId = mailId, 
                title = SI_PROMPT_TITLE_DELETE_MAIL_MONEY,
                body = IsInGamepadPreferredMode() and SI_MAIL_CONFIRM_DELETE_MONEY_GAMEPAD or SI_MAIL_CONFIRM_DELETE_MONEY,
                confirmationCallback = OnDeleteMailConfirmed,
            }
            ZO_Dialogs_ShowPlatformDialog(dialogName, dialogCallbackData, dialogTextParams)
        end
    end
end)