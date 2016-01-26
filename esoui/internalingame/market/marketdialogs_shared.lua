ZO_BUY_CROWNS_URL = {url = GetString(SI_MARKET_INSUFFICIENT_FUNDS_LINK)}
ZO_BUY_CROWNS_FRONT_FACING_ADDRESS = {mainTextParams = {GetString(SI_MARKET_INSUFFICIENT_FUNDS_LINK_TEXT), GetString(SI_URL_APPLICATION_WEB)}}

function ZO_MarketDialogs_Shared_OpenURL(dialog)
    ConfirmOpenURL(dialog.data.url)
end