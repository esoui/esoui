ZO_BUY_SUBSCRIPTION_URL_TYPE = { urlType = APPROVED_URL_ESO_ACCOUNT_SUBSCRIPTION }
ZO_BUY_SUBSCRIPTION_FRONT_FACING_ADDRESS = {mainTextParams = { GetString(SI_ESO_PLUS_SUBSCRIPTION_LINK_TEXT), GetString(SI_URL_APPLICATION_WEB) }}
ZO_BUY_CROWNS_URL_TYPE = {urlType = APPROVED_URL_ESO_ACCOUNT_STORE}
ZO_BUY_CROWNS_FRONT_FACING_ADDRESS = {mainTextParams = {GetString(SI_MARKET_INSUFFICIENT_FUNDS_LINK_TEXT), GetString(SI_URL_APPLICATION_WEB)}}

function ZO_MarketDialogs_Shared_OpenURLByType(dialog)
    OpenURLByType(dialog.data.urlType)
end

function ZO_MarketDialogs_Shared_OpenGiftingLockedHelp(dialog)
    local helpCategory, helpIndex = GetGiftingAccountLockedHelpIndices()
    RequestShowSpecificHelp(helpCategory, helpIndex)
end

function ZO_MarketDialogs_Shared_UpdateGiftingGracePeriodTimer(dialog)
    local data = dialog.data
    local gracePeriodTimeLeftS = GetGiftingGracePeriodTime()
    -- update every second
    if data.gracePeriodTimeLeftS == nil or data.gracePeriodTimeLeftS ~= gracePeriodTimeLeftS then
        data.gracePeriodTimeLeftS = gracePeriodTimeLeftS
        local timeLeftString = ZO_FormatTime(gracePeriodTimeLeftS, TIME_FORMAT_STYLE_SHOW_LARGEST_TWO_UNITS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
        ZO_Dialogs_UpdateDialogMainText(dialog, nil, {timeLeftString})
    end
end

function ZO_MarketDialogs_Shared_ShouldRestartGiftFlow(giftResult)
    return giftResult == MARKET_PURCHASE_RESULT_CANNOT_GIFT_TO_PLAYER or giftResult == MARKET_PURCHASE_RESULT_CANNOT_GIFT_RECIPIENT_NOT_FOUND
end

function ZO_MarketDialogs_Shared_GetEsoPlusSavingsString(productData)
    if IsEligibleForEsoPlusPricing() then
        local marketCurrencyType, cost, costAfterDiscount, discountPercent, esoPlusCost = productData:GetMarketProductPricingByPresentation()
        if esoPlusCost ~= nil and costAfterDiscount ~= nil then
            local currencyType = ZO_Currency_MarketCurrencyToUICurrency(marketCurrencyType)
            local esoPlusSavings = costAfterDiscount - esoPlusCost
            if esoPlusSavings > 0 then
                local currencyString = zo_strformat(SI_NUMBER_FORMAT, ZO_Currency_FormatKeyboard(currencyType, esoPlusSavings, ZO_CURRENCY_FORMAT_AMOUNT_ICON))
                return zo_strformat(SI_MARKET_PURCHASE_SUCCESS_ESO_PLUS_SAVINGS_TEXT, currencyString)
            end
        end
    end

    return nil
end

do
    local TEXTURE_SCALE_PERCENT = 100
    function ZO_MarketDialogs_Shared_GetPreviewHouseDialogMainTextParams(marketProductId)
        local keybindString
        local key, mod1, mod2, mod3, mod4 = GetIngameHighestPriorityActionBindingInfoFromName("SHOW_HOUSING_PANEL", IsInGamepadPreferredMode())
        if key ~= KEY_INVALID then
            keybindString = ZO_Keybindings_GetBindingStringFromKeys(key, mod1, mod2, mod3, mod4, KEYBIND_TEXT_OPTIONS_FULL_NAME, KEYBIND_TEXTURE_OPTIONS_EMBED_MARKUP, TEXTURE_SCALE_PERCENT, TEXTURE_SCALE_PERCENT)
        else
            keybindString = ZO_Keybindings_GenerateKeyMarkup(GetString(SI_ACTION_IS_NOT_BOUND))
        end

        -- The display name of a MarketProductCollectible is the name of the collectible
        local houseName = GetMarketProductDisplayName(marketProductId)
        houseName = ZO_SELECTED_TEXT:Colorize(houseName)

        return {houseName, keybindString}
    end
end

ESO_Dialogs["CROWN_STORE_PREVIEW_HOUSE"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_MARKET_PREVIEW_HOUSE_TITLE
    },
    mainText =
    {
        text = SI_MARKET_PREVIEW_HOUSE_TEXT
    },
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_CONFIRM,
            callback =  function(dialog)
                            local houseId = dialog.data.marketProductData:GetHouseId()
                            RequestJumpToHouse(houseId)
                            SCENE_MANAGER:RequestShowLeaderBaseScene()
                        end,
            keybind = "DIALOG_PRIMARY",
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
            keybind = "DIALOG_NEGATIVE",
        },
    },
}
