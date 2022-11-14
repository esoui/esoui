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
    elseif GetPlatformServiceType() == PLATFORM_SERVICE_TYPE_HERON then
        -- A temporary solution until Stadia goes away next update.
        -- This will just redirect to the generic confirm url dialog
        ShowPlatformESOCrownPacksUI()
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
            if GetPlatformServiceType() == PLATFORM_SERVICE_TYPE_HERON then
                return SI_OPEN_STORE_TO_BUY_PLUS_TEXT_HERON
            else
                return zo_strformat(SI_OPEN_STORE_TO_BUY_PLUS_TEXT, ZO_GetPlatformStoreName())
            end
        end,
    },
    buttons =
    {
        {
            text = function()
                if GetPlatformServiceType() == PLATFORM_SERVICE_TYPE_HERON then
                    return GetString(SI_START_HERON_PURCHASE_FLOW)
                else
                    return zo_strformat(SI_OPEN_FIRST_PARTY_STORE_KEYBIND, ZO_GetPlatformStoreName())
                end
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
    if DoesPlatformStoreUseExternalLinks() then
        ZO_PlatformOpenApprovedURL(APPROVED_URL_ESO_ACCOUNT_SUBSCRIPTION, ZO_GetPlatformStoreName(), GetString(SI_URL_APPLICATION_WEB))
    elseif GetPlatformServiceType() == PLATFORM_SERVICE_TYPE_HERON then
        -- A temporary solution until Stadia goes away next update.
        -- This will just redirect to the generic confirm url dialog
        ShowPlatformESOPlusSubscriptionUI()
    else
        ZO_Dialogs_ShowPlatformDialog("BUY_ESO_PLUS_FROM_PLATFORM_STORE")
    end
end

-- Chapter upgrade/prepurchase
ESO_Dialogs["CHAPTER_UPGRADE_STORE"] = 
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    canQueue = true,

    title =
    {
        text = function(dialog)
            return dialog.data.isPreRelease and SI_CHAPTER_PREPURCHASE_DIALOG_TITLE or SI_CHAPTER_UPGRADE_DIALOG_TITLE
        end,
    },

    mainText =
    {
        text = function(dialog)
            if dialog.data.isPreRelease then
                if GetPlatformServiceType() == PLATFORM_SERVICE_TYPE_STEAM then
                    return SI_OPEN_CHAPTER_PREPURCHASE_STEAM
                elseif GetPlatformServiceType() == PLATFORM_SERVICE_TYPE_HERON then
                    return SI_OPEN_CHAPTER_PREPURCHASE_HERON
                elseif DoesPlatformStoreUseExternalLinks() then
                    return zo_strformat(SI_OPEN_CHAPTER_PREPURCHASE_WEB, ZO_GetPlatformStoreName())
                else
                    return zo_strformat(SI_OPEN_CHAPTER_PREPURCHASE, ZO_GetPlatformStoreName())
                end
            else
                local mainText
                if GetPlatformServiceType() == PLATFORM_SERVICE_TYPE_STEAM then
                    mainText = GetString(SI_OPEN_CHAPTER_UPGRADE_STEAM)
                elseif GetPlatformServiceType() == PLATFORM_SERVICE_TYPE_HERON then
                    mainText = GetString(SI_OPEN_CHAPTER_UPGRADE_HERON)
                elseif DoesPlatformStoreUseExternalLinks() then
                    mainText = zo_strformat(SI_OPEN_CHAPTER_UPGRADE_WEB, ZO_GetPlatformStoreName())
                else
                    mainText = zo_strformat(SI_OPEN_CHAPTER_UPGRADE, ZO_GetPlatformStoreName())
                end

                if dialog.data.showLogoutWarning then
                    mainText = string.format("%s\n\n%s", mainText, ZO_ORANGE:Colorize(GetString(SI_OPEN_CHAPTER_UPGRADE_LOG_OUT_WARNING)))
                end

                return mainText
            end
        end,
    },

    buttons =
    {
        {
            text = function()
                if GetPlatformServiceType() == PLATFORM_SERVICE_TYPE_HERON then
                    return GetString(SI_START_HERON_PURCHASE_FLOW)
                else
                    return GetString(SI_DIALOG_UPGRADE)
                end
            end,
            callback = function(dialog)
                if DoesPlatformStoreUseExternalLinks() then
                    OpenChapterUpgradeURL(dialog.data.chapterId, dialog.data.isCollectorsEdition, dialog.data.chapterUpgradeSource)
                else
                    ShowPlatformESOChapterUpgradeUI(dialog.data.chapterId, dialog.data.isCollectorsEdition, dialog.data.chapterUpgradeSource)
                end
            end,
        },
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

function ZO_ShowChapterUpgradePlatformDialog(isCollectorsEdition, chapterUpgradeSource, showLogoutWarning)
    local data =
    {
        chapterId = GetCurrentChapterUpgradeId(),
        isPreRelease = false,
        isCollectorsEdition = isCollectorsEdition,
        chapterUpgradeSource = chapterUpgradeSource,
        showLogoutWarning = showLogoutWarning,
    }
    ZO_Dialogs_ShowPlatformDialog("CHAPTER_UPGRADE_STORE", data)
end

function ZO_ShowChapterPrepurchasePlatformDialog(chapterId, isCollectorsEdition, chapterUpgradeSource)
    local data =
    {
        chapterId = chapterId,
        isPreRelease = true,
        isCollectorsEdition = isCollectorsEdition,
        chapterUpgradeSource = chapterUpgradeSource,
    }
    ZO_Dialogs_ShowPlatformDialog("CHAPTER_UPGRADE_STORE", data)
end
