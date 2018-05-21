----
-- ZO_MarketAnnouncementMarketProduct_Gamepad
----

ZO_MarketAnnouncementMarketProduct_Gamepad = ZO_MarketAnnouncementMarketProduct_Shared:Subclass()

function ZO_MarketAnnouncementMarketProduct_Gamepad:New(...)
    return ZO_MarketAnnouncementMarketProduct_Shared.New(self, ...)
end

function ZO_MarketAnnouncementMarketProduct_Gamepad:SetIsFocused(isFocused)
    ZO_MarketAnnouncementMarketProduct_Shared.SetIsFocused(self, isFocused)
    
    if isFocused then
        self.description:EnableUpdateHandler()
    else
        self.description:DisableUpdateHandler()
    end
end

function ZO_MarketAnnouncementMarketProduct_Gamepad:SetupTextCalloutAnchors()
    ZO_MarketAnnouncementMarketProduct_Shared.SetupTextCalloutAnchors(self)

    self.description:SetAnchor(BOTTOMLEFT, self.control, BOTTOMLEFT, ZO_MARKET_ANNOUNCEMENT_MARKET_PRODUCT_INFO_OFFSET_X, -45)
end