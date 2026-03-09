ZO_Dialogs_RegisterCustomDialog("DIRECT_PURCHASE_RESULT",
{
    canQueue = true,

    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = function(dialog)
            if dialog.data.result == DIRECT_PURCHASE_PURCHASE_SKU_RESULT_SUCCESS then
                return GetString(SI_TRANSACTION_COMPLETE_TITLE)
            end
            return GetString(SI_TRANSACTION_FAILED_TITLE)
        end,
    },

    mainText =
    {
        text = function(dialog)
            local result = dialog.data.result
            if result == DIRECT_PURCHASE_PURCHASE_SKU_RESULT_SUCCESS then
                local skuData = ZO_DirectPurchaseSkuData:New(dialog.data.skuId)
                return zo_strformat(SI_TRANSACTION_COMPLETE_PRODUCT_NAME_BODY, ZO_WHITE:Colorize(skuData:GetDisplayName()))
            end
            return GetString("SI_DIRECTPURCHASEPURCHASESKURESULT", result)
        end,
    },

    buttons =
    {
        {
            keybind = "DIALOG_PRIMARY",
            gamepadPreferredKeybind = "DIALOG_NEGATIVE",
            text = SI_DIALOG_BACK,
        },
    },
})
