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

function ZO_MarketAnnouncementMarketProductTile:Layout(data)
    ZO_Tile.Layout(self, data)

    local marketProduct = data.marketProduct
    if not marketProduct.control or marketProduct.control ~= self.control or self.marketProduct:GetId() ~= marketProduct:GetId() then
        self.marketProduct = marketProduct
        marketProduct:SetControl(self.control)
        marketProduct:Show()
        marketProduct:SetIsFocused(data.isSelected)

        data.setOnInteractCallback = function(...) marketProduct:SetOnInteractWithScrollCallback(...) end
    end
end

function ZO_MarketAnnouncementMarketProductTile:OnHelpSelected()
    if self.marketProduct then
        local helpCategoryIndex, helpIndex = GetMarketAnnouncementHelpLinkIndices(self.marketProduct:GetId())
        RequestShowSpecificHelp(helpCategoryIndex, helpIndex)
    end
end