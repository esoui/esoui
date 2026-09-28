--------------
-- Tome Purchase Upgrade Dialog
--------------

local function PurchaseUpgradeDialog_Setup(dialog, skuData)
    local skuName = skuData:GetDisplayName()
    dialog.skuNameLabel:SetText(skuName)

    local billingInfo, hasBillingAddress = GetBillingInfo()
    local hasBillingInfo = billingInfo ~= "" and hasBillingAddress
    dialog.canConfirmPurchase = hasBillingInfo
    local currentPriceString, _, taxPriceString, totalPriceString, isVatIncluded = skuData:GetPricingInfoWithTaxFormatted()

    local subtotalAmountLabel = dialog.subtotalContainer.value
    subtotalAmountLabel:SetText(currentPriceString)

    local taxContainerAmountLabel = dialog.taxContainer.value
    taxContainerAmountLabel:SetText(taxPriceString)

    local totalContainerAmountLabel = dialog.totalContainer.value
    totalContainerAmountLabel:SetText(totalPriceString)

    local accountURLText = GetURLTextByType(APPROVED_URL_ESO_ACCOUNT_EDIT)
    local accountURLLink = ZO_URL_LINK_COLOR:Colorize(ZO_LinkHandler_CreateURLLink(accountURLText, GetString(SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_CHANGE_BILLING_INFO_URL_TEXT)))
    local changePaymentInfoFormatter = hasBillingInfo and SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_CHANGE_BILLING_INFO_KEYBOARD or SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_MISSING_BILLING_INFO_KEYBOARD
    local changePaymentInfoString = zo_strformat(changePaymentInfoFormatter, accountURLLink)
    local nonRefundableString = GetString(SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_NON_REFUNDABLE_WARNING)
    local infoText
    if isVatIncluded then
        local vatString = GetString(SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_VAT_INCLUDED)
        infoText = string.format("%s\n\n%s\n%s", changePaymentInfoString, nonRefundableString, vatString)
    else
        infoText = string.format("%s\n\n%s", changePaymentInfoString, nonRefundableString)
    end
    dialog.infoLabel:SetText(infoText)

    if hasBillingInfo then
        dialog.totalContainer:SetHidden(false)
        dialog.billingInfoContainer:SetHidden(false)

        if isVatIncluded then
            -- If VAT is included, tax is 0, so subtotal is pointless
            dialog.subtotalContainer:SetHidden(true)
            dialog.taxContainer:SetHidden(true)
            dialog.totalDivider:SetHidden(true)
            dialog.totalContainer:SetAnchor(TOPLEFT, dialog.subtotalContainer)
            dialog.totalContainer:SetAnchor(TOPRIGHT, dialog.subtotalContainer)
        else
            dialog.subtotalContainer:SetHidden(false)
            dialog.taxContainer:SetHidden(false)
            dialog.totalDivider:SetHidden(false)
            dialog.totalContainer:SetAnchor(TOPLEFT, dialog.totalDivider, BOTTOMLEFT, 0, 4)
            dialog.totalContainer:SetAnchor(TOPRIGHT, dialog.totalDivider, BOTTOMRIGHT, 0, 4)
        end
        dialog.infoLabel:SetAnchor(TOPLEFT, dialog.billingInfoContainer, BOTTOMLEFT, 0, 10)
        dialog.infoLabel:SetAnchor(TOPRIGHT, dialog.billingInfoContainer, BOTTOMRIGHT, 0, 10)

        local billingInfoEditBox = dialog.billingInfoContainer.editBox
        billingInfoEditBox:SetText(billingInfo)
        billingInfoEditBox:SetEditEnabled(false)
    else
        -- If we don't know billing info, we don't know the tax, so we don't know the total
        dialog.subtotalContainer:SetHidden(false)
        dialog.taxContainer:SetHidden(true)
        dialog.totalDivider:SetHidden(true)
        dialog.totalContainer:SetHidden(true)
        dialog.billingInfoContainer:SetHidden(true)
        dialog.infoLabel:SetAnchor(TOPLEFT, dialog.subtotalContainer, BOTTOMLEFT, 0, 10)
        dialog.infoLabel:SetAnchor(TOPRIGHT, dialog.subtotalContainer, BOTTOMRIGHT, 0, 10)
    end

    -- Make sure to update the keybinds since this setup function will run after the initial setup of the buttons
    ZO_Dialogs_UpdateButtonVisibilityAndEnabledState(dialog)
    ZO_Dialogs_RefreshButtonTexts(dialog)
end

local function ShowResultDialog(skuId, result)
    -- TODO Direct Purchase: Refactor dialogs to support a universal setup function
    if result == DIRECT_PURCHASE_PURCHASE_SKU_RESULT_SUCCESS then
        -- TODO Direct Purchase: Decouple Tomes from direct purchase
        PlaySound(SOUNDS.TAMRIEL_TOMES_PASS_PURCHASED)
        local FORCE_REFRESH = true
        RefreshBillingAndSkuInfo(FORCE_REFRESH)
    end
    ZO_Dialogs_ShowDialog("DIRECT_PURCHASE_RESULT", { skuId = skuId, result = result })
end

function ZO_DirectPurchaseConfirmPurchaseDialog_Keyboard_OnInitialized(control)
    control.skuNameLabel = control:GetNamedChild("SkuName")
    control.subtotalContainer = control:GetNamedChild("SubtotalContainer")
    control.taxContainer = control:GetNamedChild("TaxContainer")
    control.totalDivider = control:GetNamedChild("TotalDivider")
    control.totalContainer = control:GetNamedChild("TotalContainer")
    control.billingInfoContainer = control:GetNamedChild("BillingInfo")
    control.infoLabel = control:GetNamedChild("Info")

    local function OnLinkClicked(link, button, text, color, linkType, ...)
        if not control:IsHidden() and linkType == URL_LINK_TYPE then
            local data =
            {
                urlType = APPROVED_URL_ESO_ACCOUNT_EDIT,
                finishedCallback = function()
                    ZO_Dialogs_ShowDialog("DIRECT_PURCHASE_CONFIRM_PURCHASE_KEYBOARD", control.data)
                end,
            }
            local textParams =
            {
                mainTextParams =
                {
                    GetURLTextByType(APPROVED_URL_ESO_ACCOUNT_EDIT),
                    GetString(SI_URL_APPLICATION_WEB),
                }
            }
            ZO_Dialogs_ShowDialog("CONFIRM_OPEN_URL_BY_TYPE", data, textParams)
            ZO_Dialogs_ReleaseDialog("DIRECT_PURCHASE_CONFIRM_PURCHASE_KEYBOARD")
            return true
        end

        return false
    end
    LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_MOUSE_UP_EVENT, OnLinkClicked)

    ZO_Dialogs_RegisterCustomDialog("DIRECT_PURCHASE_CONFIRM_PURCHASE_KEYBOARD",
    {
        customControl = control,
        setup = PurchaseUpgradeDialog_Setup,
        title =
        {
            text = GetString(SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_TITLE),
        },
        canQueue = true,
        buttons =
        {
            {
                noReleaseOnClick = true,
                control = control:GetNamedChild("Confirm"),
                text = function(dialog)
                    return dialog.canConfirmPurchase
                        and GetString(SI_MARKET_CONFIRM_PURCHASE_KEYBIND_TEXT)
                        or GetString(SI_DIRECT_PURCHASE_REFRESH_KEYBIND_TEXT)
                end,
                callback = function(dialog)
                    if dialog.canConfirmPurchase then
                        ZO_Dialogs_ReleaseDialog("DIRECT_PURCHASE_CONFIRM_PURCHASE_KEYBOARD")
                        local pendingDialogData =
                        {
                            title = GetString(SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_TITLE),
                            mainText = GetString(SI_DIALOG_PROCESSING_PURCHASE),
                            onSetup = function()
                                -- add a delay so the dialog transition is smoother and so the dialog has time to finish setting up
                                if not dialog.data:ConfirmPurchase() then
                                    zo_callLater(function()
                                        if ZO_Dialogs_IsShowing("DIRECT_PURCHASE_CONFIRM_PURCHASE_KEYBOARD") then
                                            ZO_Dialogs_ReleaseDialogOnButtonPress("KEYBOARD_PENDING_RESULT_DIALOG")
                                            ShowResultDialog(dialog.data:GetSkuId(), DIRECT_PURCHASE_PURCHASE_SKU_RESULT_ERROR)
                                        end
                                    end, 1000)
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
                        ZO_Dialogs_ShowDialog("KEYBOARD_PENDING_RESULT_DIALOG", pendingDialogData)
                    else
                        RefreshBillingAndSkuInfo()
                        dialog.refreshBillingCallId = zo_callLater(function()
                            dialog.refreshBillingCallId = nil
                            -- ESO-954424 - If you close the dialog right before the later time procs, it can still be considered showing during the hide animation.
                            -- Really only a problem for gamepad (keyboard doesn't animate), but I want to keep the two consistent.
                            if ZO_Dialogs_IsDialogShowingAndNotHiding("DIRECT_PURCHASE_CONFIRM_PURCHASE_KEYBOARD") then
                                PurchaseUpgradeDialog_Setup(dialog, dialog.data)
                                ZO_Dialogs_UpdateButtonVisibilityAndEnabledState(dialog)
                                ZO_Dialogs_RefreshButtonTexts(dialog)
                            end
                        end, 1000)
                        ZO_Dialogs_UpdateButtonVisibilityAndEnabledState(dialog)
                    end
                end,
                enabled = function(dialog)
                    return dialog.refreshBillingCallId == nil
                end,
            },

            {
                control = control:GetNamedChild("Cancel"),
                text = SI_DIALOG_DECLINE,
            },
        },
    })
end

do
    local SUPPRESSION_DIALOG_NAMES =
    {
        "DIRECT_PURCHASE_RESULT",
        "DIRECT_PURCHASE_CONFIRM_PURCHASE_KEYBOARD",
        "KEYBOARD_PENDING_RESULT_DIALOG",
    }

    local function OnDirectPurchasePurchaseSkuResult(skuId, result)
        if IsInGamepadPreferredMode() then
            return
        end

        for _, dialogName in ipairs(SUPPRESSION_DIALOG_NAMES) do
            if ZO_Dialogs_IsShowing(dialogName) then
                return
            end
        end

        -- Show the Result dialog (Keyboard) if none of the suppression dialogs are currently showing.
        ShowResultDialog(skuId, result)
    end

    DIRECT_PURCHASE_MANAGER:RegisterCallback("PurchaseSkuResult", OnDirectPurchasePurchaseSkuResult)
end