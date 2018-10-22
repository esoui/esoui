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

    self:GetDescriptionControl():SetAnchor(BOTTOMLEFT, self.control, BOTTOMLEFT, ZO_MARKET_ANNOUNCEMENT_MARKET_PRODUCT_INFO_OFFSET_X, -95)
end

function ZO_MarketAnnouncementMarketProduct_Keyboard:Initialize(...)
    ZO_MarketAnnouncementMarketProduct_Shared.Initialize(self, ...)
    self:SetTextCalloutYOffset(0)
end

-- override of ZO_MarketProductBase:GetEsoPlusIcon()
function ZO_MarketAnnouncementMarketProduct_Keyboard:GetEsoPlusIcon()
    return zo_iconFormatInheritColor("EsoUI/Art/Market/Keyboard/ESOPlus_Chalice_WHITE_64.dds", "100%", "100%")
end

function ZO_MarketAnnouncementMarketProduct_Keyboard:Reset()
    ZO_MarketAnnouncementMarketProduct_Shared.Reset(self)
    self:PlayHighlightAnimationToBeginning()
end

do
    local g_highlightAnimationProvider = ZO_ReversibleAnimationProvider:New("ZO_KeyboardMarketProductHighlightAnimation")
    function ZO_MarketAnnouncementMarketProduct_Keyboard:SetHighlightHidden(hidden)
        if hidden then
            g_highlightAnimationProvider:PlayBackward(self.control.highlight)
        else
            g_highlightAnimationProvider:PlayForward(self.control.highlight)
        end
    end

    function ZO_MarketAnnouncementMarketProduct_Keyboard:PlayHighlightAnimationToBeginning()
        local ANIMATE_INSTANTLY = true
        g_highlightAnimationProvider:PlayBackward(self.control.highlight, ANIMATE_INSTANTLY)
    end
end

function ZO_MarketAnnouncementMarketProduct_Keyboard_OnInitialized(control)
    ZO_MarketAnnouncementMarketProduct_Shared_OnInitialized(control)
    control.highlight = control:GetNamedChild("Highlight")
end