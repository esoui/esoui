----
-- ZO_MarketAnnouncementMarketProductTile_Gamepad
----

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_MarketAnnouncementMarketProductTile_Gamepad = ZO_Object.MultiSubclass(ZO_ActionTile_Gamepad, ZO_MarketAnnouncementMarketProductTile)

function ZO_MarketAnnouncementMarketProductTile_Gamepad:New(...)
    return ZO_MarketAnnouncementMarketProductTile.New(self, ...)
end

function ZO_MarketAnnouncementMarketProductTile_Gamepad:InitializePlatform()
    ZO_ActionTile_Gamepad.InitializePlatform(self)
end

function ZO_MarketAnnouncementMarketProductTile_Gamepad:Layout(data)
    ZO_MarketAnnouncementMarketProductTile.Layout(self, data)
end

function ZO_MarketAnnouncementMarketProductTile_Gamepad:LayoutPlatform(data)
    -- The Tile_Gamepad version of this function calls SetSelected. The overridden SetSelected in this class expects
    -- the marketProduct to be updated, but that update doesn't happen until after this function is called.
    -- So if SetSelected is called from this function it will set the wrong marketProduct to have focus.
    -- We are overriding this function to avoid that.
end

function ZO_MarketAnnouncementMarketProductTile_Gamepad:SetSelected(isSelected)
    ZO_ActionTile_Gamepad.SetSelected(self, isSelected)

    if self.marketProduct then
        self.marketProduct:SetIsFocused(isSelected)
    end

    if isSelected then
        ZO_GAMEPAD_MARKET_ANNOUNCEMENT:NarrateSelection()
    end
end

-----
-- Global XML Functions
-----

function ZO_MarketAnnouncementMarketProductTile_Gamepad_OnInitialized(control)
    ZO_MarketAnnouncementMarketProduct_Shared_OnInitialized(control)
    ZO_MarketAnnouncementMarketProductTile_Gamepad:New(control)
end