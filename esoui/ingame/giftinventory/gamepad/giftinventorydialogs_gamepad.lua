local function CreateGiftMessageEntryData()
    local giftMessageEntryData = ZO_GamepadEntryData:New()
    giftMessageEntryData.messageEntry = true

    giftMessageEntryData.textChangedCallback = function(control)
        giftMessageEntryData.dialog.data.giftMessage = control:GetText()
    end

    giftMessageEntryData.setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
        control.highlight:SetHidden(not selected)

        control.editBoxControl.textChangedCallback = data.textChangedCallback
        control.editBoxControl:SetDefaultText(GetString(SI_GIFT_INVENTORY_REQUEST_GIFT_MESSAGE_TEXT))
        control.editBoxControl:SetMaxInputChars(GIFT_NOTE_MAX_LENGTH)
        control.editBoxControl:SetText(giftMessageEntryData.dialog.data.giftMessage)
    end

    giftMessageEntryData.narrationText = ZO_GetDefaultParametricListEditBoxNarrationText

    return giftMessageEntryData
end

local function CreateConfirmationEntryData()
    local confirmationEntryData = ZO_GamepadEntryData:New(GetString(SI_DIALOG_ACCEPT))
    confirmationEntryData.confirmEntry = true

    confirmationEntryData.setup = ZO_SharedGamepadEntry_OnSetup

    return confirmationEntryData
end

-- Claim Gift

do
    local parametricDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
    ZO_Dialogs_RegisterCustomDialog("CONFIRM_CLAIM_GIFT_GAMEPAD",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        setup = function(dialog)
            dialog:setupFunc()

            local giftData = dialog.data.gift
            if giftData then
                local claimQuantity = giftData:GetClaimQuantity()
                if claimQuantity ~= giftData:GetQuantity() then
                    GAMEPAD_TOOLTIPS:LayoutPartialClaimGiftData(GAMEPAD_LEFT_DIALOG_TOOLTIP, giftData)
                end
            end
        end,
        title =
        {
            text = SI_CONFIRM_CLAIM_GIFT_TITLE,
        },
        mainText =
        {
            text =  function(dialog)
                        return zo_strformat(SI_CONFIRM_CLAIM_GIFT_NOTE_ENTRY_HEADER, ZO_WHITE:Colorize(dialog.data.gift:GetUserFacingPlayerName()))
                    end,
        },
        blockDialogReleaseOnPress = true, -- We'll handle Dialog Releases ourselves since we don't want DIALOG_PRIMARY to release the dialog on press.
        canQueue = true,
        parametricList =
        {
            -- Thank You message
            {
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem_Multiline",
                entryData = CreateGiftMessageEntryData(),
            },

            -- Confirm
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                entryData = CreateConfirmationEntryData(),
            },
        },
       
        buttons =
        {
            -- Cancel Button
            {
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_DIALOG_CANCEL),
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("CONFIRM_CLAIM_GIFT_GAMEPAD")
                end,
            },

            -- Select Button (used for entering name)
            {
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_GAMEPAD_SELECT_OPTION),
                enabled = function(dialog)
                    if ZO_IsConsolePlatform() then
                        local targetData = dialog.entryList:GetTargetData()
                        if targetData.messageEntry then
                            if IsConsoleCommunicationRestricted() then
                                return false, GetString(SI_CONSOLE_COMMUNICATION_PERMISSION_ERROR_GLOBALLY_RESTRICTED)
                            end
                        end
                    end
                    return true
                end,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    local targetControl = dialog.entryList:GetTargetControl()
                    if targetData.messageEntry and targetControl then
                        targetControl.editBoxControl:TakeFocus()
                    elseif targetData.confirmEntry then
                        local note = dialog.data.giftMessage
                        dialog.data.gift:TakeGift(note)
                    end
                end,
                clickSound = SOUNDS.GIFT_INVENTORY_ACTION_CLAIM,
            },
            -- Random note
            {
                keybind = "DIALOG_SECONDARY",
                text = SI_GAMEPAD_GENERATE_RANDOM_NOTE,
                visible = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    return targetData.messageEntry == true
                end,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    local targetControl = dialog.entryList:GetTargetControl()
                    if targetData.messageEntry and targetControl then
                        targetControl.editBoxControl:SetText(GetRandomGiftThankYouNoteText())
                        SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                    end
                end,
            },
        },

        noChoiceCallback = function(dialog)
            ZO_Dialogs_ReleaseDialogOnButtonPress("CONFIRM_CLAIM_GIFT_GAMEPAD")
        end,

        onHidingCallback = function(dialog)
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_DIALOG_TOOLTIP)
        end
    })
end

-- Return Gift

do
    local parametricDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
    ZO_Dialogs_RegisterCustomDialog("CONFIRM_RETURN_GIFT_GAMEPAD",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        setup = function(dialog)
                    dialog:setupFunc()
                end,
        title =
        {
            text = SI_CONFIRM_RETURN_GIFT_TITLE,
        },
        blockDialogReleaseOnPress = true, -- We'll handle Dialog Releases ourselves since we don't want DIALOG_PRIMARY to release the dialog on press.
        parametricList =
        {
            -- Return message
            {
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem_Multiline",
                entryData = CreateGiftMessageEntryData(),
            },

            -- Confirm
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                entryData = CreateConfirmationEntryData(),
            },
        },
       
        buttons =
        {
            -- Cancel Button
            {
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_DIALOG_CANCEL),
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("CONFIRM_RETURN_GIFT_GAMEPAD")
                end,
            },

            -- Select Button (used for entering name)
            {
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_GAMEPAD_SELECT_OPTION),
                enabled = function(dialog)
                    if ZO_IsConsolePlatform() then
                        local targetData = dialog.entryList:GetTargetData()
                        if targetData.messageEntry then
                            if IsConsoleCommunicationRestricted() then
                                return false, GetString(SI_CONSOLE_COMMUNICATION_PERMISSION_ERROR_GLOBALLY_RESTRICTED)
                            end
                        end
                    end
                    return true
                end,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    local targetControl = dialog.entryList:GetTargetControl()
                    if targetData.messageEntry and targetControl then
                        targetControl.editBoxControl:TakeFocus()
                    elseif targetData.confirmEntry then
                        local note = dialog.data.giftMessage
                        dialog.data.gift:ReturnGift(note)
                    end
                end,
            },
        },

        noChoiceCallback = function(dialog)
            ZO_Dialogs_ReleaseDialogOnButtonPress("CONFIRM_RETURN_GIFT_GAMEPAD")
        end,
    })
end

-- Delete Gift

ZO_Dialogs_RegisterCustomDialog("CONFIRM_DELETE_GIFT_GAMEPAD",
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
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
                local gift = dialog.data.gift
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

ZO_Dialogs_RegisterCustomDialog("CLAIM_GIFT_NOTICE_GAMEPAD",
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
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
            keybind = "DIALOG_PRIMARY",
            text = GetString(SI_CLAIM_GIFT_NOTICE_CONTINUE_KEYBIND),
            callback = function(dialog)
                ZO_Dialogs_ShowGamepadDialog("CONFIRM_CLAIM_GIFT_GAMEPAD", { gift = dialog.data.gift })
            end,
        },

        -- Cancel Button
        {
            keybind = "DIALOG_NEGATIVE",
            text = GetString(SI_DIALOG_CANCEL),
        },

        -- More Info Button
        {
            keybind = "DIALOG_TERTIARY",
            text = GetString(SI_CLAIM_GIFT_NOTICE_MORE_INFO_KEYBIND),
            visible = function(dialog)
                return dialog.data.helpCategoryIndex ~= nil
            end,
            callback = function(dialog)
                local data = dialog.data
                HELP_TUTORIALS_ENTRIES_GAMEPAD:Push(data.helpCategoryIndex, data.helpIndex)
            end,
        },
    },
})
