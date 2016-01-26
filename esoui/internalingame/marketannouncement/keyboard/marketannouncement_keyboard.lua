----
-- MarketAnnouncementMarketProduct_Keyboard
----

local MarketAnnouncementMarketProduct_Keyboard = ZO_MarketAnnouncementMarketProduct_Base:Subclass()

function MarketAnnouncementMarketProduct_Keyboard:New(...)
    return ZO_MarketAnnouncementMarketProduct_Base.New(self, ...)
end

function MarketAnnouncementMarketProduct_Keyboard:Initialize(...)
    ZO_MarketAnnouncementMarketProduct_Base.Initialize(self, ...)
end

-- overwrite to change anchoring
function MarketAnnouncementMarketProduct_Keyboard:LayoutCostAndText(description, cost, discountPercent, discountedCost, isNew)
    ZO_MarketProductBase.LayoutCostAndText(self, description, cost, discountPercent, discountedCost, isNew)

    self.cost:ClearAnchors()
    self.textCallout:ClearAnchors()
    
    if cost > discountedCost then
        self.cost:SetAnchor(BOTTOMLEFT, self.previousCost, BOTTOMRIGHT, 10)
        self.textCallout:SetAnchor(BOTTOMLEFT, self.previousCost, TOPLEFT, ZO_LARGE_SINGLE_MARKET_PRODUCT_CALLOUT_X_OFFSET - 2, 0) -- x offset to account for strikethrough
    else
        self.cost:SetAnchor(BOTTOMLEFT, self.control, BOTTOMLEFT, ZO_LARGE_SINGLE_MARKET_PRODUCT_CONTENT_X_INSET, ZO_LARGE_SINGLE_MARKET_PRODUCT_CONTENT_BOTTOM_INSET_Y)
        self.textCallout:SetAnchor(BOTTOMLEFT, self.cost, TOPLEFT, ZO_LARGE_SINGLE_MARKET_PRODUCT_CALLOUT_X_OFFSET, 0)
    end
end

----
-- MarketAnnouncement_Keyboard
----

local MarketAnnouncement_Keyboard = ZO_MarketAnnouncement_Base:Subclass()

function MarketAnnouncement_Keyboard:New(...)
    return ZO_MarketAnnouncement_Base.New(self, ...)
end

function MarketAnnouncement_Keyboard:Initialize(control)
    local conditionFunction = function() return not IsInGamepadPreferredMode() end
    ZO_MarketAnnouncement_Base.Initialize(self, control, conditionFunction)
    self.carousel = ZO_MarketProductCarousel:New(self.carouselControl, "ZO_MarketAnnouncement_MarketProductTemplate_Keyboard")
    self.productDescriptionBackground = self.controlContainer:GetNamedChild("ProductBG")
end

function MarketAnnouncement_Keyboard:InitializeKeybindButtons()
    ZO_MarketAnnouncement_Base.InitializeKeybindButtons(self)

    self.crownStoreButton:SetupStyle(KEYBIND_STRIP_STANDARD_STYLE)
    self.closeButton:SetupStyle(KEYBIND_STRIP_STANDARD_STYLE)
end

function MarketAnnouncement_Keyboard:CreateMarketProduct(productId)
    local marketProduct = MarketAnnouncementMarketProduct_Keyboard:New()
    marketProduct:SetId(productId)
    return marketProduct
end

--global XML functions

function ZO_MarketAnnouncement_Keyboard_OnInitialize(control)
    ZO_KEYBOARD_MARKET_ANNOUNCEMENT = MarketAnnouncement_Keyboard:New(control)
    SYSTEMS:RegisterKeyboardObject("marketAnnouncement", ZO_KEYBOARD_MARKET_ANNOUNCEMENT)
end