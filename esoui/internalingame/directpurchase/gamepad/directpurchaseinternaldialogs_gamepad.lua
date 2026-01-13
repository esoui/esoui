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

local function PurchaseUpgradeDialog_Setup(dialog, data)
    local parametricListEntries = dialog.info.parametricList
    ZO_ClearNumericallyIndexedTable(parametricListEntries)

    local billingInfoEntry =
    {
        header = GetString(SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_BILLING_INFO_LABEL_GAMEPAD),
        headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",
        template = "ZO_DirectPurchaseBillingInfoEditBox_Gamepad",
        entryData = PurchaseUpgradeDialog_GetOrCreateBillingInfoEntryData(),
    }

    table.insert(parametricListEntries, billingInfoEntry)

    local accountURLText = GetURLTextByType(APPROVED_URL_ESO_ACCOUNT_EDIT)
    local accountURLLink = ZO_URL_LINK_COLOR:Colorize(ZO_LinkHandler_CreateURLLink(accountURLText, accountURLText))
    local changePaymentInfoString = zo_strformat(SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_CHANGE_BILLING_INFO_GAMEPAD, accountURLLink)
    local nonRefundableString = GetString(SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_NON_REFUNDABLE_WARNING)
    local infoText = string.format("%s\n\n%s", changePaymentInfoString, nonRefundableString)

    GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_DIALOG_TOOLTIP, infoText)
    ZO_GenericGamepadDialog_ShowTooltip(dialog)

    local skuId = data.skuId
    local currentPrice, basePrice, taxPrice, totalPrice, currency = GetSkuPricingInfoWithTax(skuId)
    -- TODO Tamriel Tomes: Better pricing display?
    local currentPriceString = string.format("%.2f %s", currentPrice, currency)
    local taxAmountString = string.format("%.2f %s", taxPrice, currency)
    local totalAmountString = string.format("%.2f %s", totalPrice, currency)

    local displayData =
    {
        data1 =
        {
            value = currentPriceString,
            header = GetString(SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_SUBTOTAL_LABEL_GAMEPAD),
        },
        data2 =
        {
            value = taxAmountString,
            header = GetString(SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_TAX_LABEL_GAMEPAD),
        },
        data3 =
        {
            value = totalAmountString,
            header = GetString(SI_DIRECT_PURCHASE_CONFIRM_PURCHASE_TOTAL_LABEL_GAMEPAD),
        },
    }

    local DONT_LIMIT_NUM_ENTRIES = nil
    dialog:setupFunc(DONT_LIMIT_NUM_ENTRIES, displayData)
end

ZO_Dialogs_RegisterCustomDialog("DIRECT_PURCHASE_CONFIRM_PURCHASE_GAMEPAD",
    {
        setup = PurchaseUpgradeDialog_Setup,
        canQueue = true,
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
                local skuId = dialog.data.skuId
                return ZO_SELECTED_TEXT:Colorize(GetSkuDisplayName(skuId))
            end,
        },
        parametricList = {}, -- we'll generate the entries on setup
        baseNarrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
        buttons =
        {
            --Confirm
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_DIALOG_CONFIRM,
                clickSound = SOUNDS.DIALOG_ACCEPT,
                enabled = function(dialog)
                    return true
                end,
                callback = function(dialog)
                    ConfirmPurchaseSku(dialog.data.skuId)
                end,
            },
            --Back
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_DECLINE,
            },
        },
    }
)
