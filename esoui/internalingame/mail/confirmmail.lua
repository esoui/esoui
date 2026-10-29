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
        canQueue = true,

        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
            allowRightStickPassThrough = true,
        },
            
        title = 
        { 
            text = function(dialog) return dialog.data.title end, 
        },

        mainText = 
        { 
            text = function(dialog) return dialog.data.body end, 
        },

        verifyConfirmationInfo =
        {
            onShowCooldown = 2000,
            matchingString = GetString(SI_DELETE_MAIL_CONFIRMATION_TEXT),
        },
        
        noChoiceCallback = function(dialog)
            CancelDeleteMail(dialog.data.mailId)
        end,

        buttons =
        {
            {
                requiresConfirmationVerification = true,
                text = SI_MAIL_DELETE,
                callback = function(dialog)
                    dialog.data.confirmationCallback(dialog.data.mailId)
                end,
            },
        
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

EVENT_MANAGER:RegisterForEvent("ZoDeleteMail", EVENT_CONFIRM_DELETE_MAIL, function(eventCode, mailId)
    ZO_Dialogs_ReleaseDialog("DELETE_MAIL_WITH_ATTACHMENTS")
    local function OnDeleteMailConfirmed(mailId)
        ConfirmDeleteMail(mailId)
        PlaySound(SOUNDS.MAIL_ITEM_DELETED)
    end

    local numAttachments, attachedGold, codAmount = GetMailAttachmentInfo(mailId)
    local hasAttachments = numAttachments > 0
    local hasAttachedGold = attachedGold > 0
    if not hasAttachments and not hasAttachedGold then
        OnDeleteMailConfirmed(mailId)
    else
        local dialogName = "DELETE_MAIL_WITH_ATTACHMENTS"
        if hasAttachments and hasAttachedGold then
            local dialogCallbackData = 
            {
                mailId = mailId, 
                title = SI_PROMPT_TITLE_DELETE_MAIL_ATTACHMENTS,
                body = SI_MAIL_CONFIRM_DELETE_ATTACHMENTS_AND_MONEY,
                confirmationCallback = OnDeleteMailConfirmed,
            }
            ZO_Dialogs_ShowPlatformDialog(dialogName, dialogCallbackData)
        elseif hasAttachments then
            local dialogCallbackData = 
            {
                mailId = mailId, 
                title = SI_PROMPT_TITLE_DELETE_MAIL_ATTACHMENTS,
                body = SI_MAIL_CONFIRM_DELETE_ATTACHMENTS,
                confirmationCallback = OnDeleteMailConfirmed,
            }
            ZO_Dialogs_ShowPlatformDialog(dialogName, dialogCallbackData)
        elseif hasAttachedGold then
            local dialogCallbackData = 
            {
                mailId = mailId, 
                title = SI_PROMPT_TITLE_DELETE_MAIL_MONEY,
                body = SI_MAIL_CONFIRM_DELETE_MONEY,
                confirmationCallback = OnDeleteMailConfirmed,
            }
            ZO_Dialogs_ShowPlatformDialog(dialogName, dialogCallbackData)
        end
    end
end)