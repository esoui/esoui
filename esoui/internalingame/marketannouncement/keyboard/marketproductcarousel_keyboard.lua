--
-- ZO_MarketProductCarousel_Keyboard
--

ZO_MarketProductCarousel_Keyboard = ZO_MarketProductCarousel_Shared:Subclass()

function ZO_MarketProductCarousel_Keyboard:New(...)
    return ZO_MarketProductCarousel_Shared.New(self, ...)
end

function ZO_MarketProductCarousel_Keyboard:Initialize(...)
    ZO_MarketProductCarousel_Shared.Initialize(self, ...)

    self.selectionIndicator:SetButtonControlName("MarketProduct_Indicator_Keyboard")
    self:SetOnControlClicked(function(clickedControl, button, upInside) clickedControl.object:OnMouseUp() end) 
end

function ZO_MarketProductCarousel_Keyboard:ResetScrollToTop()
    local data = self:GetSelectedData()
    local marketProduct = data and data.marketProduct
    if marketProduct and marketProduct.description then
        ZO_Scroll_ResetToTop(marketProduct.description)
    end
end