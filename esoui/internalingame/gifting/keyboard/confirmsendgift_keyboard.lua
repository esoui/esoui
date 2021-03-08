function ZO_ConfirmSendGiftDialog_Keyboard_OnInitialized(self)
    -- Name edit
    local function UpdateSendRestrictions(nameEditControl)
        local sendButton = self:GetNamedChild("Send")
        local recipientDisplayName = nameEditControl:GetText()
        local result, errorText = IsGiftRecipientNameValid(recipientDisplayName)
        local sendButtonState, sendButtonStateLocked = BSTATE_NORMAL, false
        if result ~= GIFT_ACTION_RESULT_SUCCESS then
            sendButtonState, sendButtonStateLocked = BSTATE_DISABLED, true
            if result ~= GIFT_ACTION_RESULT_RECIPIENT_EMPTY then
                errorText = zo_strformat(GetString("SI_GIFTBOXACTIONRESULT", result), recipientDisplayName)
            end
        end
        sendButton:SetState(sendButtonState, sendButtonStateLocked)

        if errorText then
            InitializeTooltip(InformationTooltip, nameEditControl, RIGHT, -35, 0)
            SetTooltipText(InformationTooltip, errorText, ZO_ERROR_COLOR:UnpackRGB())
        else
            ClearTooltip(InformationTooltip)
        end
    end

    local nameEdit = self:GetNamedChild("NameEdit")
    ZO_PreHookHandler(nameEdit, "OnTextChanged", function(editControl)
        UpdateSendRestrictions(editControl)
    end)

    ZO_AutoComplete:New(nameEdit, { AUTO_COMPLETE_FLAG_FRIEND, AUTO_COMPLETE_FLAG_GUILD }, nil, AUTO_COMPLETION_ONLINE_OR_OFFLINE, 5, AUTO_COMPLETION_AUTOMATIC_MODE)

    -- Note edit
    local noteEditBox = self:GetNamedChild("NoteEdit")
    local randomNoteButton = self:GetNamedChild("NoteRandomText"):GetNamedChild("Button")
    randomNoteButton:SetText(zo_iconFormat("EsoUI/Art/Market/Keyboard/giftMessageIcon_up.dds", "100%", "100%"))
    randomNoteButton:SetHandler("OnClicked", function()
        noteEditBox:SetText(GetRandomGiftSendNoteText())
    end)

    ZO_Dialogs_RegisterCustomDialog("CONFIRM_SEND_GIFT_KEYBOARD",
    {
        title =
        {
            text = SI_CONFIRM_SEND_GIFT_TITLE,
        },
      
        customControl = self,
        setup = function(dialog, data)
            local marketProductId = GetGiftMarketProductId(data.giftId)
            local name, description, icon = GetMarketProductInfo(marketProductId)
            local giftIconTexture = dialog:GetNamedChild("GiftIcon")
            giftIconTexture:SetTexture(icon)
            local giftTextContainer = dialog:GetNamedChild("GiftText")
            local color = GetItemQualityColor(GetMarketProductDisplayQuality(marketProductId))
            local houseId = GetMarketProductHouseId(marketProductId)
            if houseId > 0 then
                local houseCollectibleId = GetCollectibleIdForHouse(houseId)
                local houseDisplayName = GetCollectibleName(houseCollectibleId)
                giftTextContainer:GetNamedChild("GiftName"):SetText(zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, color:Colorize(houseDisplayName)))
                giftTextContainer:GetNamedChild("GiftDetail"):SetText(zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, color:Colorize(GetMarketProductDisplayName(marketProductId))))
            else
                local marketProductData = ZO_MarketProductData:New(marketProductId)
                local stackCount = marketProductData:GetStackCount()
                if stackCount > 1 then
                    giftTextContainer:GetNamedChild("GiftName"):SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME_WITH_QUANTITY, color:Colorize(GetMarketProductDisplayName(marketProductId)), stackCount))
                else
                    giftTextContainer:GetNamedChild("GiftName"):SetText(zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, color:Colorize(GetMarketProductDisplayName(marketProductId))))
                end
                giftTextContainer:GetNamedChild("GiftDetail"):SetText("")
            end

            UpdateSendRestrictions(dialog:GetNamedChild("NameEdit"))

            if not data.isRestart then
                dialog:GetNamedChild("NoteEdit"):SetText("")
            end
        end,

        canQueue = true,
        buttons =
        {
            -- Cancel Button
            {
                control = self:GetNamedChild("Cancel"),
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_DIALOG_CANCEL),
                callback = function(dialog)
                    FinishResendingGift(dialog.data.giftId)
                end,
            },

            -- Send Button
            {
                control = self:GetNamedChild("Send"),
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_GIFT_INVENTORY_SEND_KEYBIND),
                callback = function(dialog)
                    local recipientDisplayName = dialog:GetNamedChild("NameEdit"):GetText()
                    local noteText = dialog:GetNamedChild("NoteEdit"):GetText()
                    local data = dialog.data
                    -- We lose this giftId's data after a successful send, so we need to store this marketProductId for later
                    local marketProductId = GetGiftMarketProductId(data.giftId)

                    local sendingData =
                    {
                        giftId = data.giftId,
                        marketProductId = marketProductId,
                        recipientDisplayName = recipientDisplayName,
                    }
                    ZO_Dialogs_ShowDialog("GIFT_SENDING_KEYBOARD", sendingData)
                    ResendGift(data.giftId, noteText, recipientDisplayName)
                end,
            },
        },

        noChoiceCallback = function(dialog)
            FinishResendingGift(dialog.data.giftId)
        end,

        finishedCallback = function()
            ClearTooltipImmediately(InformationTooltip)
        end
    })

    EVENT_MANAGER:RegisterForEvent("ZoConfirmSendGiftKeyboard", EVENT_CONFIRM_SEND_GIFT, function(eventCode, giftId)
        if not IsInGamepadPreferredMode() then
            ZO_Dialogs_ShowDialog("CONFIRM_SEND_GIFT_KEYBOARD", { giftId = giftId }, {mainTextParams = { }})
        end
    end)
end

local LOADING_DELAY_MS = 500
local SHOW_LOADING_ICON = true
local HIDE_LOADING_ICON = false

local GIFTING_STATE_DELAY = 1
local GIFTING_STATE_WAITING = 2
local GIFTING_STATE_RESULT = 3

local function OnGiftSendingUpdate(dialog, currentTimeInSeconds)
    local timeInMilliseconds = currentTimeInSeconds * 1000
    local data = dialog.data
    local result = data.result

    if data.loadingDelayTimeMS == nil then
        data.loadingDelayTimeMS = timeInMilliseconds + LOADING_DELAY_MS
    end

    local itemName = GetMarketProductDisplayName(data.marketProductId)
    local color = GetItemQualityColor(GetMarketProductDisplayQuality(data.marketProductId))
    local houseId = GetMarketProductHouseId(data.marketProductId)
    if houseId > 0 then
        local houseCollectibleId = GetCollectibleIdForHouse(houseId)
        local houseDisplayName = GetCollectibleName(houseCollectibleId)
        itemName = zo_strformat(SI_MARKET_PRODUCT_HOUSE_NAME_GRAMMARLESS_FORMATTER, houseDisplayName, itemName)
    end

    if result ~= nil and data.currentState ~= GIFTING_STATE_RESULT then
        data.currentState = GIFTING_STATE_RESULT

        local titleText, mainText
        if result == GIFT_ACTION_RESULT_SUCCESS then
            titleText = GetString(SI_TRANSACTION_COMPLETE_TITLE)

            local stackCount = GetMarketProductStackCount(data.marketProductId)
            if stackCount > 1 then
                mainText = zo_strformat(SI_GIFT_SENT_TEXT_WITH_QUANTITY, color:Colorize(itemName), stackCount, ZO_SELECTED_TEXT:Colorize(data.recipientDisplayName))
            else
                mainText = zo_strformat(SI_GIFT_SENT_TEXT, color:Colorize(itemName), ZO_SELECTED_TEXT:Colorize(data.recipientDisplayName))
            end
        else
            titleText = GetString(SI_TRANSACTION_FAILED_TITLE)
            mainText = GetString("SI_GIFTBOXACTIONRESULT", result)
        end

        local confirmText
        if ZO_ConfirmSendGift_Shared_ShouldRestartGiftFlow(data.result) then
            confirmText = GetString(SI_GIFT_SENDING_RESTART_KEYBIND_LABEL)
        else
            confirmText = GetString(SI_GIFT_SENDING_BACK_KEYBIND_LABEL)
        end

        ZO_Dialogs_UpdateDialogTitleText(dialog, { text = titleText })
        ZO_Dialogs_UpdateDialogMainText(dialog, { text = mainText, align = TEXT_ALIGN_CENTER })

        local confirmButtonControl = dialog:GetNamedChild("Confirm")
        confirmButtonControl:SetText(confirmText)
        confirmButtonControl:SetHidden(false)

        ZO_Dialogs_SetDialogLoadingIcon(dialog:GetNamedChild("Loading"), dialog:GetNamedChild("Text"), HIDE_LOADING_ICON)
    elseif data.currentState == GIFTING_STATE_DELAY and timeInMilliseconds > data.loadingDelayTimeMS then
        -- Only present the waiting state after a fixed delay, to avoid very short transitions between waiting and result
        data.currentState = GIFTING_STATE_WAITING

        ZO_Dialogs_UpdateDialogMainText(dialog, { text = zo_strformat(SI_GIFT_SENDING_TEXT, color:Colorize(itemName)), TEXT_ALIGN_CENTER })
        ZO_Dialogs_SetDialogLoadingIcon(dialog:GetNamedChild("Loading"), dialog:GetNamedChild("Text"), SHOW_LOADING_ICON)
    end
end

local function OnGiftActionResult(data, action, result, giftId)
    if internalassert(giftId == data.giftId) then
        data.result = result
        EVENT_MANAGER:UnregisterForEvent("ZO_GiftSendingDialog_Keyboard_OnGiftActionResult", EVENT_GIFT_ACTION_RESULT)
    end

    if result == GIFT_ACTION_RESULT_COLLECTIBLE_PARTIALLY_OWNED then
        local marketProductData = ZO_MarketProductData:New(data.marketProductId)
        local displayName = marketProductData:GetDisplayName()
        local dialogParams =
        {
            titleParams = { displayName },
        }
        ZO_Dialogs_ReleaseAllDialogsOfName("GIFT_SENDING_KEYBOARD")
        ZO_Dialogs_ShowDialog("RESEND_GIFT_PARTIALLY_OWNED_KEYBOARD", data, dialogParams)
    end
end

local function GiftSendingDialogSetup(dialog, data)
    data.result = nil
    data.loadingDelayTimeMS = nil
    data.currentState = GIFTING_STATE_DELAY
    EVENT_MANAGER:RegisterForEvent("ZO_GiftSendingDialog_Keyboard_OnGiftActionResult", EVENT_GIFT_ACTION_RESULT, function(eventId, ...) OnGiftActionResult(data, ...) end)

    dialog:GetNamedChild("Confirm"):SetHidden(true)
end

function ZO_GiftSendingDialog_Keyboard_OnInitialized(self)
    ZO_Dialogs_RegisterCustomDialog("GIFT_SENDING_KEYBOARD",
    {
        customControl = self,
        setup = GiftSendingDialogSetup,
        updateFn = OnGiftSendingUpdate,
        title =
        {
            text = SI_GIFT_SENDING_TITLE,
        },
        mainText =
        {
            text = "",
            align = TEXT_ALIGN_CENTER,
        },
        canQueue = true,
        mustChoose = true,
        modal = false,
        buttons =
        {
            {
                control = self:GetNamedChild("Confirm"),
                text = SI_GIFT_SENDING_BACK_KEYBIND_LABEL,
                keybind = "DIALOG_PRIMARY",
                callback = function(dialog)
                     local data = dialog.data
                     if ZO_ConfirmSendGift_Shared_ShouldRestartGiftFlow(data.result) then
                         ZO_Dialogs_ShowDialog("CONFIRM_SEND_GIFT_KEYBOARD", {giftId = data.giftId})
                         return
                     end
                 end,
            },
        },
    }
    )
end