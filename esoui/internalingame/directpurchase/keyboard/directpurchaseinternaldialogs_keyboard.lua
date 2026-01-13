--------------
-- Tome Purchase Upgrade Dialog
--------------

local function PurchaseUpgradeDialog_Setup(dialog, data)
    local skuId = data.skuId
    local skuName = GetSkuDisplayName(skuId)
    dialog.skuNameLabel:SetText(skuName)

    local currentPrice, basePrice, taxPrice, totalPrice, currency = GetSkuPricingInfoWithTax(skuId)

    -- TODO Tamriel Tomes: Better pricing display?
    local currentPriceString = string.format("%.2f %s", currentPrice, currency)
    local subtotalAmountLabel = dialog.subtotalContainer.value
    subtotalAmountLabel:SetText(currentPriceString)

    local taxAmountString = string.format("%.2f %s", taxPrice, currency)
    local taxContainerAmountLabel = dialog.taxContainer.value
    taxContainerAmountLabel:SetText(taxAmountString)

    local totalAmountString = string.format("%.2f %s", totalPrice, currency)
    local totalContainerAmountLabel = dialog.totalContainer.value
    totalContainerAmountLabel:SetText(totalAmountString)

    local billingInfo = GetBillingInfo()
    local billingInfoEditBox = dialog.billingInfoContainer.editBox
    billingInfoEditBox:SetText(billingInfo)
    billingInfoEditBox:SetEditEnabled(false)

    local accountURLText = GetURLTextByType(APPROVED_URL_ESO_ACCOUNT_EDIT)
    local accountURLLink = ZO_URL_LINK_COLOR:Colorize(ZO_LinkHandler_CreateURLLink(accountURLText, GetString(SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_CHANGE_BILLING_INFO_URL_TEXT)))
    local changePaymentInfoString = zo_strformat(SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_CHANGE_BILLING_INFO_KEYBOARD, accountURLLink)
    local nonRefundableString = GetString(SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_NON_REFUNDABLE_WARNING)
    local infoText = string.format("%s\n\n%s", changePaymentInfoString, nonRefundableString)
    dialog.infoLabel:SetText(infoText)
end

function ZO_DirectPurchaseConfirmPurchaseDialog_Keyboard_OnInitialized(control)
    control.skuNameLabel = control:GetNamedChild("SkuName")
    control.subtotalContainer = control:GetNamedChild("SubtotalContainer")
    control.taxContainer = control:GetNamedChild("TaxContainer")
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
                    control = control:GetNamedChild("Confirm"),
                    text = SI_MARKET_CONFIRM_PURCHASE_KEYBIND_TEXT,
                    callback = function(dialog)
                         ConfirmPurchaseSku(dialog.data.skuId)
                    end,
                },

                {
                    control = control:GetNamedChild("Cancel"),
                    text = SI_DIALOG_DECLINE,
                },
            },
        }
    )
end
