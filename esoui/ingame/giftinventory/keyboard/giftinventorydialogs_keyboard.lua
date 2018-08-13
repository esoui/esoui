-- Claim Gift

function ZO_ConfirmClaimGiftDialog_Keyboard_OnInitialized(self)

    local noteEdit = self:GetNamedChild("NoteEdit")
    local randomNoteButton = self:GetNamedChild("NoteRandomText"):GetNamedChild("Button")
    randomNoteButton:SetText(zo_iconFormat("EsoUI/Art/Market/Keyboard/giftMessageIcon_up.dds", "100%", "100%"))
    randomNoteButton:SetHandler("OnClicked", function()
        noteEdit:SetText(GetRandomGiftThankYouNoteText())
    end)

    ZO_Dialogs_RegisterCustomDialog("CONFIRM_CLAIM_GIFT_KEYBOARD",
    {
        canQueue = true,
        title =
        {
            text = SI_CONFIRM_CLAIM_GIFT_TITLE,
        },
      
        customControl = self,
        setup = function(dialog, gift)
            local noteHeaderLabel = dialog:GetNamedChild("NoteHeader")
            noteHeaderLabel:SetText(zo_strformat(SI_CONFIRM_CLAIM_GIFT_NOTE_ENTRY_HEADER, ZO_WHITE:Colorize(gift:GetUserFacingPlayerName())))
            dialog:GetNamedChild("NoteEdit"):SetText("")
        end,

        buttons =
        {
            -- Cancel Button
            {
                control = self:GetNamedChild("Cancel"),
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_DIALOG_CANCEL),
            },

            -- Confirm Button
            {
                control = self:GetNamedChild("Confirm"),
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_DIALOG_CONFIRM),
                callback = function(dialog)
                    local noteText = dialog:GetNamedChild("NoteEdit"):GetText()
                    dialog.data:TakeGift(noteText)
                end,
                clickSound = SOUNDS.GIFT_INVENTORY_ACTION_CLAIM,
            },
        },
    })
end

-- Return Gift

function ZO_ConfirmReturnGiftDialog_Keyboard_OnInitialized(self)

    -- We don't have prewritten notes for returning gifts
    self:GetNamedChild("NoteRandomText"):SetHidden(true)

    ZO_Dialogs_RegisterCustomDialog("CONFIRM_RETURN_GIFT_KEYBOARD",
    {
        title =
        {
            text = SI_CONFIRM_RETURN_GIFT_TITLE,
        },
      
        customControl = self,
        setup = function(dialog, gift)
            dialog:GetNamedChild("NoteEdit"):SetText("")
        end,

        buttons =
        {
            -- Cancel Button
            {
                control = self:GetNamedChild("Cancel"),
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_DIALOG_CANCEL),
            },

            -- Confirm Button
            {
                control = self:GetNamedChild("Confirm"),
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_DIALOG_CONFIRM),
                callback = function(dialog)
                    local noteText = dialog:GetNamedChild("NoteEdit"):GetText()
                    dialog.data:ReturnGift(noteText)
                end,
            },
        },
    })
end

-- Delete Gift

ZO_Dialogs_RegisterCustomDialog("CONFIRM_DELETE_GIFT_KEYBOARD",
{
    title =
    {
        text = SI_CONFIRM_DELETE_GIFT_TITLE,
    },

    mainText =
    {
        text = SI_CONFIRM_DELETE_GIFT_PROMPT,
    },
      
    buttons =
    {
        -- Confirm Button
        {
            keybind = "DIALOG_PRIMARY",
            text = GetString(SI_DIALOG_CONFIRM),
            callback = function(dialog)
                local gift = dialog.data
                gift:DeleteGift()
            end,
        },

        -- Cancel Button
        {
            keybind = "DIALOG_NEGATIVE",
            text = GetString(SI_DIALOG_CANCEL),
        },
    },
})

-- Claim Gift Notice
function ZO_GiftClaimNoticeDialog_Keyboard_OnInitialized(control)
    local helpButton = control:GetNamedChild("HelpButton")
    ZO_Dialogs_RegisterCustomDialog("CLAIM_GIFT_NOTICE_KEYBOARD",
    {
        customControl = control,
        setup = function(dialog)
            local data = dialog.data
            helpButton:SetHidden(data.helpCategoryIndex == nil)
            helpButton:SetHandler("OnClicked", function()
                HELP:ShowSpecificHelp(data.helpCategoryIndex, data.helpIndex)
                ZO_Dialogs_ReleaseDialog(dialog)
            end)
        end,
        title =
        {
            text = SI_MARKET_PRODUCT_NAME_FORMATTER,
        },
        mainText =
        {
            text = SI_CLAIM_GIFT_NOTICE_BODY_FORMATTER,
        },
        buttons =
        {
            -- Continue Button
            {
                control = control:GetNamedChild("Continue"),
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_CLAIM_GIFT_NOTICE_CONTINUE_KEYBIND),
                callback = function(dialog)
                    ZO_Dialogs_ShowDialog("CONFIRM_CLAIM_GIFT_KEYBOARD", dialog.data.gift)
                end,
            },

            -- Cancel Button
            {
                control = control:GetNamedChild("Cancel"),
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_DIALOG_CANCEL),
            }
        },
    })
end
