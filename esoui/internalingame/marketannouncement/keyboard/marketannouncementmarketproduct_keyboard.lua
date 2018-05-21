----
-- ZO_MarketAnnouncementMarketProduct_Keyboard
----

ZO_MARKET_ANNOUNCEMENT_MARKET_PRODUCT_INFO_WIDTH_WITH_SCROLLBAR = ZO_MARKET_ANNOUNCEMENT_MARKET_PRODUCT_INFO_WIDTH - 16

ZO_MarketAnnouncementMarketProduct_Keyboard = ZO_MarketAnnouncementMarketProduct_Shared:Subclass()

function ZO_MarketAnnouncementMarketProduct_Keyboard:New(...)
    return ZO_MarketAnnouncementMarketProduct_Shared.New(self, ...)
end

function ZO_MarketAnnouncementMarketProduct_Keyboard:SetupTextCalloutAnchors()
    ZO_MarketAnnouncementMarketProduct_Shared.SetupTextCalloutAnchors(self)

    self.description:SetAnchor(BOTTOMLEFT, self.control, BOTTOMLEFT, ZO_MARKET_ANNOUNCEMENT_MARKET_PRODUCT_INFO_OFFSET_X, -95)
end

function ZO_MarketAnnouncementMarketProduct_Keyboard:Initialize(...)
    ZO_MarketAnnouncementMarketProduct_Shared.Initialize(self, ...)
    self:SetTextCalloutYOffset(0)
end
