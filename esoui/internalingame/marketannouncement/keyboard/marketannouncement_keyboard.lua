----
-- MarketAnnouncementMarketProduct_Keyboard
----

local MarketAnnouncementMarketProduct_Keyboard = ZO_MarketAnnouncementMarketProduct_Base:Subclass()

function MarketAnnouncementMarketProduct_Keyboard:New(...)
    return ZO_MarketAnnouncementMarketProduct_Base.New(self, ...)
end

local KEYBOARD_CURRENCY_ICON_SIZE = 24
function MarketAnnouncementMarketProduct_Keyboard:Initialize(...)
    ZO_MarketAnnouncementMarketProduct_Base.Initialize(self, ...)
    self:SetTextCalloutYOffset(0)
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