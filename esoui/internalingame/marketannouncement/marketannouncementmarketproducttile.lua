----
-- ZO_MarketAnnouncementMarketProductTile
----

------
-- Functions usable by class that are implemented by fellow inheriting class off of a MarketAnnouncementMarketProductTile_Keyboard or a MarketAnnouncementMarketProductTile_Gamepad
-- (DO NOT IMPLEMENT THESE FUNCTIONS IN THIS CLASS)
--    SetActionText
--    SetActionCallback
------

ZO_MarketAnnouncementMarketProductTile = ZO_ActionTile:Subclass()

function ZO_MarketAnnouncementMarketProductTile:PostInitialize()
    ZO_ActionTile.PostInitialize(self)

    ZO_Scroll_SetOnInteractWithScrollbarCallback(self.control:GetNamedChild("ProductDescription"), function() self:OnInteractWithScroll() end)
end

function ZO_MarketAnnouncementMarketProductTile:OnInteractWithScroll()
    local marketProduct = self.marketProduct
    if marketProduct then
        marketProduct:CallOnInteractWithScrollCallback()
    end
end

function ZO_MarketAnnouncementMarketProductTile:Layout(marketProduct, selected)
    ZO_Tile.Layout(self, marketProduct, selected)

    if not marketProduct.control or marketProduct.control ~= self.control then
        self.marketProduct = marketProduct
        marketProduct:InitializeControls(self.control)
        marketProduct:Show()
        marketProduct:SetIsFocused(selected)

        local keybindStringId
        local marketProductId = marketProduct:GetId()
        local openBehavior = GetMarketProductOpenMarketBehavior(marketProductId)
        if openBehavior == OPEN_MARKET_BEHAVIOR_SHOW_CHAPTER_UPGRADE then
            keybindStringId = SI_MARKET_ANNOUNCEMENT_VIEW_CHAPTER_UPGRADE
        else
            keybindStringId = SI_MARKET_ANNOUNCEMENT_VIEW_CROWN_STORE
        end
        self.control.object:SetActionText(GetString(keybindStringId))
    end
end

function ZO_MarketAnnouncementMarketProductTile:SetHighlightHidden(hidden, instant)
    ZO_ActionTile.SetHighlightHidden(self, hidden, instant)

    if self.marketProduct then
        self.marketProduct:SetHighlightHidden(hidden)
    end
end