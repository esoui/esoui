-- Buy Crowns
ZO_Dialogs_RegisterCustomDialog("BUY_CROWNS_FROM_PLATFORM_STORE",
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_OPEN_STORE_TO_BUY_CROWNS_TITLE,
    },
    mainText =
    {
        text = SI_OPEN_STORE_BUY_CROWNS_TEXT,
    },
    buttons =
    {
        {
            text = function()
                return zo_strformat(SI_OPEN_FIRST_PARTY_STORE_KEYBIND, ZO_GetPlatformStoreName())
            end,
            callback = function(dialog)
                ShowPlatformESOCrownPacksUI()
            end
        },
        {
            text = SI_DIALOG_EXIT,
        },
    },
})

function ZO_ShowBuyCrownsPlatformUI()
    OnMarketPurchaseMoreCrowns()
    if DoesPlatformStoreUseExternalLinks() then
        OpenURLByType(APPROVED_URL_ESO_ACCOUNT_STORE)
    else
        ShowPlatformESOCrownPacksUI()
    end
end

function ZO_ShowBuyCrownsPlatformDialog()
    OnMarketPurchaseMoreCrowns()
    if DoesPlatformStoreUseExternalLinks() then 
        ZO_PlatformOpenApprovedURL(APPROVED_URL_ESO_ACCOUNT_STORE, ZO_GetPlatformStoreName(), GetString(SI_URL_APPLICATION_WEB))
    else
        ZO_Dialogs_ShowPlatformDialog("BUY_CROWNS_FROM_PLATFORM_STORE", nil, { mainTextParams = { ZO_Currency_FormatKeyboard(CURT_CROWNS, NO_AMOUNT, ZO_CURRENCY_FORMAT_PLURAL_NAME_ICON), ZO_GetPlatformStoreName() } })
    end
end

-- Buy ESO plus
ESO_Dialogs["BUY_ESO_PLUS_FROM_PLATFORM_STORE"] =
{
    mustChoose = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_OPEN_STORE_TO_BUY_PLUS_TITLE,
    },
    mainText =
    {
        text = function()
            return zo_strformat(SI_OPEN_STORE_TO_BUY_PLUS_TEXT, ZO_GetPlatformStoreName())
        end,
    },
    buttons =
    {
        {
            text = function()
                return zo_strformat(SI_OPEN_FIRST_PARTY_STORE_KEYBIND, ZO_GetPlatformStoreName())
            end,
            callback =  function(dialog)
                ShowPlatformESOPlusSubscriptionUI()
            end
        },
        {
            text = SI_DIALOG_EXIT,
        },
    }
}

function ZO_ShowBuySubscriptionPlatformDialog()
    -- When buying crowns we want to rely on DoesPlatformStoreUseExternalLinks() returning true for Epic, but in this
    -- case where we are buying a subscription we want Epic to use the ESO store.
    if DoesPlatformStoreUseExternalLinks() then
        local linkText = ZO_GetPlatformStoreName()
        if GetPlatformServiceType() == PLATFORM_SERVICE_TYPE_EPIC then
            linkText = GetString("SI_PLATFORMSTORELABEL", PLATFORM_STORE_LABEL_ZOS)
        end
        ZO_PlatformOpenApprovedURL(APPROVED_URL_ESO_ACCOUNT_SUBSCRIPTION, linkText, GetString(SI_URL_APPLICATION_WEB))
    else
        ZO_Dialogs_ShowPlatformDialog("BUY_ESO_PLUS_FROM_PLATFORM_STORE")
    end
end
