-- Abandon scrying progress dialog

ZO_Dialogs_RegisterCustomDialog("CONFIRM_ABANDON_ANTIQUITY_SCRYING_PROGRESS",
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_ANTIQUITY_CONFIRM_ABANDON_SCRYING_PROGRESS_TITLE,
    },
    mainText =
    {
        text = SI_ANTIQUITY_CONFIRM_ABANDON_SCRYING_PROGRESS_PROMPT,
    },
    buttons =
    {
        -- Confirm Button
        {
            keybind = "DIALOG_PRIMARY",
            text = GetString(SI_DIALOG_CONFIRM),
            callback = function(dialog)
                local data = dialog.data
                local antiquityId = data.antiquityId
                RequestAbandonAntiquity(antiquityId)
            end,
        },

        -- Cancel Button
        {
            keybind = "DIALOG_NEGATIVE",
            text = GetString(SI_DIALOG_CANCEL),
        },
    },
})
