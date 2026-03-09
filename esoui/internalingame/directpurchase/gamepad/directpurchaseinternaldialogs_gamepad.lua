--------------
-- Tome Purchase Upgrade Dialog
--------------

local PurchaseUpgradeDialog_GetOrCreateBillingInfoEntryData
do
    local billingInfoEntryData
    PurchaseUpgradeDialog_GetOrCreateBillingInfoEntryData = function()
        if billingInfoEntryData then
            return billingInfoEntryData
        end

        billingInfoEntryData = ZO_GamepadEntryData:New()
        billingInfoEntryData.billingInfoEntry = true

        billingInfoEntryData.setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
            billingInfoEntryData.control = control

            local dialog = billingInfoEntryData.dialog
            local dialogData = dialog.data
            control.highlight:SetHidden(not selected)
            local billingInfo = GetBillingInfo()
            control.editBoxControl:SetText(billingInfo)
            control.editBoxControl:SetEditEnabled(false)
            control.editBoxControl:SetMouseEnabled(false)
        end

        return billingInfoEntryData
    end
end

local function PurchaseUpgradeDialog_Setup(dialog, skuData)
    local parametricListEntries = dialog.info.parametricList
    ZO_ClearNumericallyIndexedTable(parametricListEntries)

    local billingInfo, hasBillingAddress = GetBillingInfo()
    local hasBillingInfo = billingInfo ~= "" and hasBillingAddress
    local currentPriceString, _, taxPriceString, totalPriceString, isVatIncluded = skuData:GetPricingInfoWithTaxFormatted()

    if hasBillingInfo then
        local billingInfoEntry =
        {
            header = GetString(SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_BILLING_INFO_LABEL_GAMEPAD),
            headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",
            template = "ZO_DirectPurchaseBillingInfoEditBox_Gamepad",
            entryData = PurchaseUpgradeDialog_GetOrCreateBillingInfoEntryData(),
        }

        table.insert(parametricListEntries, billingInfoEntry)
    end

    local accountURLText = GetURLTextByType(APPROVED_URL_ESO_ACCOUNT_EDIT)
    local accountURLLink = ZO_URL_LINK_COLOR:Colorize(ZO_LinkHandler_CreateURLLink(accountURLText, accountURLText))
    local changePaymentInfoFormatter = hasBillingInfo and SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_CHANGE_BILLING_INFO_GAMEPAD or SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_MISSING_BILLING_INFO_GAMEPAD
    local changePaymentInfoString = zo_strformat(changePaymentInfoFormatter, accountURLLink)
    local nonRefundableString = GetString(SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_NON_REFUNDABLE_WARNING)

    local infoText
    if isVatIncluded then
        local vatString = GetString(SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_VAT_INCLUDED)
        infoText = string.format("%s\n\n%s\n%s", changePaymentInfoString, nonRefundableString, vatString)
    else
        infoText = string.format("%s\n\n%s", changePaymentInfoString, nonRefundableString)
    end

    GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_DIALOG_TOOLTIP, infoText)
    ZO_GenericGamepadDialog_ShowTooltip(dialog)

    local headerStrings = {}

    if hasBillingInfo then
        if not isVatIncluded then
            -- If VAT is included, tax is 0, so subtotal is pointless
            table.insert(headerStrings,
            {
                value = currentPriceString,
                header = GetString(SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_SUBTOTAL_LABEL_GAMEPAD),
            })
            table.insert(headerStrings,
            {
                value = taxPriceString,
                header = GetString(SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_TAX_LABEL_GAMEPAD),
            })
        end
        table.insert(headerStrings,
        {
            value = totalPriceString,
            header = GetString(SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_TOTAL_LABEL_GAMEPAD),
        })
    else
        -- If we don't know billing info, we don't know the tax, so we don't know the total
        table.insert(headerStrings,
        {
            value = currentPriceString,
            header = GetString(SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_SUBTOTAL_LABEL_GAMEPAD),
        })
    end

    local displayData =
    {
        data1 = headerStrings[1],
        data2 = headerStrings[2],
        data3 = headerStrings[3],
    }

    local DONT_LIMIT_NUM_ENTRIES = nil
    dialog:setupFunc(DONT_LIMIT_NUM_ENTRIES, displayData)
end

local function ShowResultDialog(skuId, result)
    -- TODO Direct Purchase: Refactor dialogs to support a universal setup function
    if result == DIRECT_PURCHASE_PURCHASE_SKU_RESULT_SUCCESS then
        -- TODO Direct Purchase: Decouple Tomes from direct purchase
        PlaySound(SOUNDS.TAMRIEL_TOMES_PASS_PURCHASED)
        local FORCE_REFRESH = true
        RefreshBillingAndSkuInfo(FORCE_REFRESH)
    end
    ZO_Dialogs_ShowGamepadDialog("DIRECT_PURCHASE_RESULT", { skuId = skuId, result = result })
end

ZO_Dialogs_RegisterCustomDialog("DIRECT_PURCHASE_CONFIRM_PURCHASE_GAMEPAD",
    {
        setup = PurchaseUpgradeDialog_Setup,
        canQueue = true,
        blockDialogReleaseOnPress = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        title =
        {
            text = GetString(SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_TITLE),
        },
        mainText =
        {
            text = function(dialog)
                return ZO_SELECTED_TEXT:Colorize(dialog.data:GetDisplayName())
            end,
        },
        parametricList = {}, -- we'll generate the entries on setup
        baseNarrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
        buttons =
        {
            --Confirm
            {
                keybind = "DIALOG_PRIMARY",
                text = function()
                    local billingInfo, hasBillingAddress = GetBillingInfo()
                    if billingInfo ~= "" and hasBillingAddress then
                        return GetString(SI_MARKET_CONFIRM_PURCHASE_KEYBIND_TEXT)
                    else
                        return GetString(SI_DIRECT_PURCHASE_REFRESH_KEYBIND_TEXT)
                    end
                end,
                clickSound = SOUNDS.DIALOG_ACCEPT,
                callback = function(dialog)
                    local billingInfo, hasBillingAddress = GetBillingInfo()
                    if billingInfo ~= "" and hasBillingAddress then
                        ZO_Dialogs_ReleaseDialogOnButtonPress("DIRECT_PURCHASE_CONFIRM_PURCHASE_GAMEPAD")
                        local pendingDialogData =
                        {
                            title = GetString(SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_TITLE),
                            mainText = GetString(SI_DIALOG_PROCESSING_PURCHASE),
                            onSetup = function()
                                -- add a delay so the dialog transition is smoother and so the dialog has time to finish setting up
                                if not dialog.data:ConfirmPurchase() then
                                    zo_callLater(function()
                                        ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_PENDING_RESULT_DIALOG")
                                        ShowResultDialog(dialog.data:GetSkuId(), DIRECT_PURCHASE_PURCHASE_SKU_RESULT_ERROR)
                                    end, 500)
                                end
                            end,
                            onTimeout = function()
                                ShowResultDialog(dialog.data:GetSkuId(), DIRECT_PURCHASE_PURCHASE_SKU_RESULT_TIMED_OUT)
                            end,
                            events =
                            {
                                {
                                    event = EVENT_DIRECT_PURCHASE_PURCHASE_SKU_RESULT,
                                    callback = function(_, skuId, result)
                                        ShowResultDialog(skuId, result)
                                    end
                                },
                            }
                        }
                        ZO_Dialogs_ShowGamepadDialog("GAMEPAD_PENDING_RESULT_DIALOG", pendingDialogData)
                    else
                        RefreshBillingAndSkuInfo()
                        zo_callLater(function()
                            PurchaseUpgradeDialog_Setup(dialog, dialog.data)
                            ZO_GenericGamepadDialog_RefreshKeybinds(dialog)
                        end, 1000)
                    end
                end,
            },
            --Back
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_DECLINE,
                callback = function()
                    ZO_Dialogs_ReleaseDialogOnButtonPress("DIRECT_PURCHASE_CONFIRM_PURCHASE_GAMEPAD")
                end
            },
        },
    }
)
