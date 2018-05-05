----
-- ZO_MarketAnnouncementMarketProductTile_Gamepad
----

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_MarketAnnouncementMarketProductTile_Gamepad = ZO_Object.MultiSubclass(ZO_ActionTile_Gamepad, ZO_MarketAnnouncementMarketProductTile)

function ZO_MarketAnnouncementMarketProductTile_Gamepad:New(...)
    return ZO_MarketAnnouncementMarketProductTile.New(self, ...)
end

function ZO_MarketAnnouncementMarketProductTile_Gamepad:Layout(marketProduct, selected)
    ZO_MarketAnnouncementMarketProductTile.Layout(self, marketProduct, selected)

    local tile = self.control.object
    tile:SetActionCallback(function() ZO_GAMEPAD_MARKET_ANNOUNCEMENT:OnMarketAnnouncementViewCrownStoreKeybind() end)
    tile:SetSelected(selected)
end

function ZO_MarketAnnouncementMarketProductTile_Gamepad:SetSelected(isSelected)
    ZO_ActionTile_Gamepad.SetSelected(self, isSelected)

    if self.marketProduct then
        self.marketProduct:SetIsFocused(isSelected)
    end
end

-----
-- Global XML Functions
-----

function ZO_MarketAnnouncementMarketProductTile_Gamepad_OnInitialized(control)
    ZO_MarketAnnouncementMarketProductTile_Gamepad:New(control)
end