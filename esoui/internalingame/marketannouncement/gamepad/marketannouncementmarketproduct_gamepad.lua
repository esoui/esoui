----
-- ZO_MarketAnnouncementMarketProduct_Gamepad
----

ZO_MarketAnnouncementMarketProduct_Gamepad = ZO_MarketAnnouncementMarketProduct_Shared:Subclass()

function ZO_MarketAnnouncementMarketProduct_Gamepad:New(...)
    return ZO_MarketAnnouncementMarketProduct_Shared.New(self, ...)
end

function ZO_MarketAnnouncementMarketProduct_Gamepad:SetIsFocused(isFocused)
    ZO_MarketAnnouncementMarketProduct_Shared.SetIsFocused(self, isFocused)

    local descriptionControl = self:GetDescriptionControl()
    if isFocused then
        descriptionControl:EnableUpdateHandler()
    else
        descriptionControl:DisableUpdateHandler()
    end
end

function ZO_MarketAnnouncementMarketProduct_Gamepad:SetupTextCalloutAnchors()
    ZO_MarketAnnouncementMarketProduct_Shared.SetupTextCalloutAnchors(self)

    self:GetDescriptionControl():SetAnchor(BOTTOMLEFT, self.control, BOTTOMLEFT, ZO_MARKET_ANNOUNCEMENT_MARKET_PRODUCT_INFO_OFFSET_X, -45)
end

-- override of ZO_MarketProductBase:GetEsoPlusIcon()
function ZO_MarketAnnouncementMarketProduct_Gamepad:GetEsoPlusIcon()
    return zo_iconFormatInheritColor("EsoUI/Art/Market/Gamepad/gp_ESOPlus_Chalice_WHITE_64.dds", "100%", "100%")
end