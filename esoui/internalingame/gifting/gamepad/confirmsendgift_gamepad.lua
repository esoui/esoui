
do
    local parametricDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)

    local dialogInfo =
    {
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },

        setup = function(dialog)
            dialog:setupFunc()
        end,

        blockDialogReleaseOnPress = true, -- We'll handle Dialog Releases ourselves since we don't want DIALOG_PRIMARY to release the dialog on press.
        canQueue = true,

        title =
        {
            text = SI_CONFIRM_SEND_GIFT_TITLE,
        },
        mainText =
        {
            text = SI_MARKET_PRODUCT_NAME_FORMATTER,
        },
        parametricList =
        {
            -- recipient name edit box
            {
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem",
                templateData = {
                    recipientNameEntry = true,
                    textChangedCallback = function(control)
                        local displayName = control:GetText()
                        if parametricDialog.data.recipientDisplayName ~= displayName then
                            parametricDialog.data.recipientDisplayName = displayName
                            ZO_GenericParametricListGamepadDialogTemplate_RefreshVisibleEntries(parametricDialog)
                        end
                    end,

                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.highlight:SetHidden(not selected)

                        control.editBoxControl.textChangedCallback = data.textChangedCallback

                        local platform = ZO_GetPlatformAccountLabel()
                        local instructions = zo_strformat(SI_REQUEST_DISPLAY_NAME_INSTRUCTIONS, platform)
                        ZO_EditDefaultText_Initialize(control.editBoxControl, instructions)
                        if parametricDialog.data.recipientDisplayName then
                            control.editBoxControl:SetText(parametricDialog.data.recipientDisplayName)
                        end
                    end,
                },
            },

            -- gift message
            {
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem_Multiline",
                templateData = {
                    messageEntry = true,
                    textChangedCallback = function(control)
                        local giftMessage = control:GetText()
                        parametricDialog.data.giftMessage = giftMessage
                    end,
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.highlight:SetHidden(not selected)

                        control.editBoxControl.textChangedCallback = data.textChangedCallback

                        ZO_EditDefaultText_Initialize(control.editBoxControl, GetString(SI_GIFT_INVENTORY_REQUEST_GIFT_MESSAGE_TEXT))
                        control.editBoxControl:SetMaxInputChars(GIFT_NOTE_MAX_LENGTH)
                        control.editBoxControl:SetText(parametricDialog.data.giftMessage)
                    end,
                },
            },

            -- Confirm
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                templateData = {
                    confirmEntry = true,
                    text = GetString(SI_DIALOG_ACCEPT),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                },
                icon = ZO_GAMEPAD_SUBMIT_ENTRY_ICON,
            },
        },
       
        buttons =
        {
            -- Cancel Button
            {
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_DIALOG_CANCEL),
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("CONFIRM_SEND_GIFT_GAMEPAD")
                    FinishResendingGift(dialog.data.giftId)
                end,
            },

            -- Select Button (used for entering name)
            {
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_GAMEPAD_SELECT_OPTION),
                enabled = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData.messageEntry then
                        local platform = GetUIPlatform()
                        if platform == UI_PLATFORM_PS4 or platform == UI_PLATFORM_XBOX then
                            if IsConsoleCommunicationRestricted() then
                                return false, GetString(SI_CONSOLE_COMMUNICATION_PERMISSION_ERROR_GLOBALLY_RESTRICTED)
                            end
                        end
                    elseif targetData.confirmEntry then
                        local recipientDisplayName = dialog.data.recipientDisplayName
                        local result = IsGiftRecipientNameValid(recipientDisplayName)
                        if result == GIFT_ACTION_RESULT_SUCCESS then
                            return true
                        else
                            local errorText = zo_strformat(GetString("SI_GIFTBOXACTIONRESULT", result), recipientDisplayName)
                            return false, errorText
                        end
                    end

                    return true
                end,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    local targetControl = dialog.entryList:GetTargetControl()
                    if targetData.messageEntry and targetControl then
                        targetControl.editBoxControl:TakeFocus()
                    elseif targetData.recipientNameEntry and targetControl then                        
                        local platform = GetUIPlatform()
                        if platform == UI_PLATFORM_PS4 then
                            --On PS4 the primary action opens the first party dialog to get a playstation id since it can select any player on PS4
                            local function OnUserChosen(hasResult, displayName, consoleId)
                                if hasResult then
                                    targetControl.editBoxControl:SetText(displayName)
                                end
                            end
                            local INCLUDE_ONLINE_FRIENDS = true
                            local INCLUDE_OFFLINE_FRIENDS = true
                            PLAYER_CONSOLE_INFO_REQUEST_MANAGER:RequestIdFromUserListDialog(OnUserChosen, GetString(SI_GAMEPAD_CONSOLE_SELECT_FOR_SEND_GIFT), INCLUDE_ONLINE_FRIENDS, INCLUDE_OFFLINE_FRIENDS)
                        else
                            --Otherwise (PC, Xbox) the primary action is to input the name by keyboard
                            targetControl.editBoxControl:TakeFocus()
                        end
                    elseif targetData.confirmEntry then
                        --TODO: If you're ignoring them then warn here

                        ZO_Dialogs_ReleaseDialogOnButtonPress("CONFIRM_SEND_GIFT_GAMEPAD")

                        local data = dialog.data
                        local marketProductId = GetGiftMarketProductId(data.giftId)

                        local sendingData = {
                            giftId = data.giftId,
                            itemName = data.itemName,
                            stackCount = GetMarketProductStackCount(marketProductId),
                            recipientDisplayName = data.recipientDisplayName,
                            giftMessage = data.giftMessage,
                        }

                        ZO_Dialogs_ShowGamepadDialog("GIFT_SENDING_GAMEPAD", sendingData)
                    end
                end,
            },
            --Xbox Choose Friend/Random note
            {
                keybind = "DIALOG_SECONDARY",
                text = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData.recipientNameEntry then
                        return GetString(SI_GAMEPAD_CONSOLE_CHOOSE_FRIEND)
                    elseif targetData.messageEntry then
                        return GetString(SI_GAMEPAD_GENERATE_RANDOM_NOTE)
                    end
                end,
                visible = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    local isXbox = GetUIPlatform() == UI_PLATFORM_XBOX
                    return (isXbox and targetData.recipientNameEntry and GetNumberConsoleFriends() > 0) or targetData.messageEntry
                end,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    local targetControl = dialog.entryList:GetTargetControl()
                    if targetData.recipientNameEntry and targetControl then
                        local function OnUserChosen(hasResult, displayName, consoleId)
                            if hasResult then
                                targetControl.editBoxControl:SetText(displayName)
                            end
                        end
                        local INCLUDE_ONLINE_FRIENDS = true
                        local INCLUDE_OFFLINE_FRIENDS = true
                        PLAYER_CONSOLE_INFO_REQUEST_MANAGER:RequestIdFromUserListDialog(OnUserChosen, GetString(SI_GAMEPAD_CONSOLE_SELECT_FOR_SEND_GIFT), INCLUDE_ONLINE_FRIENDS, INCLUDE_OFFLINE_FRIENDS)
                    elseif targetData.messageEntry and targetControl then
                        targetControl.editBoxControl:SetText(GetRandomGiftSendNoteText())
                    end
                end,
            },
        },
        

        noChoiceCallback = function(dialog)
            ZO_Dialogs_ReleaseDialogOnButtonPress("CONFIRM_SEND_GIFT_GAMEPAD")
            FinishResendingGift(dialog.data.giftId)
        end,
    }

    ZO_Dialogs_RegisterCustomDialog("CONFIRM_SEND_GIFT_GAMEPAD", dialogInfo)
end

EVENT_MANAGER:RegisterForEvent("ZoConfirmSendGiftGamepad", EVENT_CONFIRM_SEND_GIFT, function(eventCode, giftId)
    if IsInGamepadPreferredMode() then
        local marketProductId = GetGiftMarketProductId(giftId)
        local color = GetItemQualityColor(GetMarketProductDisplayQuality(marketProductId))
        local colorizedName = color:Colorize(GetMarketProductDisplayName(marketProductId))
        ZO_Dialogs_ShowGamepadDialog("CONFIRM_SEND_GIFT_GAMEPAD", { giftId = giftId, itemName = colorizedName }, { mainTextParams = { colorizedName } })
    end
end)

do
    local LOADING_DELAY_MS = 500
    local function OnGiftActionResult(data, action, result, giftId)
        if internalassert(giftId == data.giftId) then
            EVENT_MANAGER:UnregisterForEvent("GAMEPAD_GIFT_SENDING", EVENT_GIFT_ACTION_RESULT)

            -- To prevent a jarring transition when switching, we're going to delay the release of the dialog.
            -- This means we guarantee the loading dialog will be around for at least LOADING_DELAY_MS
            zo_callLater(function()
                local sendResultData = {
                    sendResult = result,
                    giftId = giftId,
                    recipientDisplayName = data.recipientDisplayName,
                }
                ZO_Dialogs_ReleaseDialogOnButtonPress("GIFT_SENDING_GAMEPAD")
                if result == GIFT_ACTION_RESULT_SUCCESS then
                    sendResultData.itemName = data.itemName
                    sendResultData.stackCount = data.stackCount
                    ZO_Dialogs_ShowGamepadDialog("GIFT_SENT_SUCCESS_GAMEPAD", sendResultData)
                else
                    sendResultData.giftMessage = data.giftMessage
                    ZO_Dialogs_ShowGamepadDialog("GIFT_SENDING_FAILED_GAMEPAD", sendResultData)
                end
            end, LOADING_DELAY_MS)
        end
    end

    local function GiftSendingDialogSetup(dialog, data)
        dialog:setupFunc()

        ResendGift(data.giftId, data.giftMessage, data.recipientDisplayName)
        EVENT_MANAGER:RegisterForEvent("GAMEPAD_GIFT_SENDING", EVENT_GIFT_ACTION_RESULT, function(eventId, ...) OnGiftActionResult(dialog.data, ...) end)
    end

    ZO_Dialogs_RegisterCustomDialog("GIFT_SENDING_GAMEPAD",
    {
        setup = GiftSendingDialogSetup,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.COOLDOWN,
        },
        title =
        {
            text = SI_GIFT_SENDING_TITLE,
        },
        mainText =
        {
            text = "",
        },
        loading = 
        {
            text =  function(dialog)
                local data = dialog.data
                if data.stackCount > 1 then
                    return zo_strformat(SI_GIFT_SENDING_TEXT_WITH_QUANTITY, data.itemName, data.stackCount)
                else
                    return zo_strformat(SI_GIFT_SENDING_TEXT, data.itemName)
                end
            end,
        },
        canQueue = true,
        mustChoose = true,
    })

    ZO_Dialogs_RegisterCustomDialog("GIFT_SENT_SUCCESS_GAMEPAD",
    {
        setup = function(dialog)
            dialog.setupFunc(dialog, dialog.data)
        end,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_TRANSACTION_COMPLETE_TITLE,
        },
        mainText =
        {
            text = function(dialog)
                local data = dialog.data
                if data.stackCount > 1 then
                    return zo_strformat(SI_GIFT_SENT_TEXT_WITH_QUANTITY, data.itemName, data.stackCount, ZO_SELECTED_TEXT:Colorize(data.recipientDisplayName))
                else
                    return zo_strformat(SI_GIFT_SENT_TEXT, data.itemName, ZO_SELECTED_TEXT:Colorize(data.recipientDisplayName))
                end
            end
        },
        canQueue = true,
        mustChoose = true,
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_GIFT_SENDING_BACK_KEYBIND_LABEL,
                callback = function(dialog)
                    FinishResendingGift(dialog.data.giftId)
                end,
            }
        },
    })

    ZO_Dialogs_RegisterCustomDialog("GIFT_SENDING_FAILED_GAMEPAD",
    {
        setup = function(dialog)
            dialog:setupFunc(dialog.data)
        end,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_TRANSACTION_FAILED_TITLE,
        },
        mainText =
        {
            text = function(dialog)
                return GetString("SI_GIFTBOXACTIONRESULT", dialog.data.sendResult)
            end
        },
        canQueue = true,
        mustChoose = true,
        buttons = {
            {
                text = function(dialog)
                    if ZO_ConfirmSendGift_Shared_ShouldRestartGiftFlow(dialog.data.sendResult) then
                        return GetString(SI_GIFT_SENDING_RESTART_KEYBIND_LABEL)
                    else
                        return GetString(SI_GIFT_SENDING_BACK_KEYBIND_LABEL)
                    end
                end,
                callback = function(dialog)
                    if ZO_ConfirmSendGift_Shared_ShouldRestartGiftFlow(dialog.data.sendResult) then
                        local resultData =
                        {
                            giftId = dialog.data.giftId,
                            giftMessage = dialog.data.giftMessage,
                            recipientDisplayName = dialog.data.recipientDisplayName,
                        }
                        ZO_Dialogs_ShowGamepadDialog("CONFIRM_SEND_GIFT_GAMEPAD", resultData)
                    else
                        FinishResendingGift(dialog.data.giftId)
                    end
                end,
                keybind = "DIALOG_NEGATIVE"
            }
        },
    })
end
