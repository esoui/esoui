ZO_BUY_SUBSCRIPTION_URL_TYPE = { urlType = APPROVED_URL_ESO_ACCOUNT_SUBSCRIPTION }
ZO_BUY_SUBSCRIPTION_FRONT_FACING_ADDRESS = {mainTextParams = { GetString(SI_ESO_PLUS_SUBSCRIPTION_LINK_TEXT), GetString(SI_URL_APPLICATION_WEB) }}
ZO_BUY_CROWNS_URL_TYPE = {urlType = APPROVED_URL_ESO_ACCOUNT_STORE}
ZO_BUY_CROWNS_FRONT_FACING_ADDRESS = {mainTextParams = {GetString(SI_MARKET_INSUFFICIENT_FUNDS_LINK_TEXT), GetString(SI_URL_APPLICATION_WEB)}}

function ZO_MarketDialogs_Shared_OpenURLByType(dialog)
    OpenURLByType(dialog.data.urlType)
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
                            local houseId = GetMarketProductHouseId(dialog.data.marketProductId)
                            RequestJumpToHouse(houseId)
                            ShowRemoteBaseScene()
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
