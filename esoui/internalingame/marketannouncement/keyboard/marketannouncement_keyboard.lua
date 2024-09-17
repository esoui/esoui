----
-- ZO_MarketAnnouncement_Keyboard
----

local ZO_MarketAnnouncement_Keyboard = ZO_MarketAnnouncement_Shared:Subclass()

function ZO_MarketAnnouncement_Keyboard:New(...)
    return ZO_MarketAnnouncement_Shared.New(self, ...)
end

function ZO_MarketAnnouncement_Keyboard:Initialize(control)
    -- This data must be setup before parent initialize is called
    self.actionTileControlByType =
    {
        [ZO_ACTION_TILE_TYPE.EVENT_ANNOUNCEMENT] = "ZO_EventAnnouncementTile_Keyboard_Control",
        [ZO_ACTION_TILE_TYPE.DAILY_REWARDS] = "ZO_DailyRewardsTile_Keyboard_Control",
        [ZO_ACTION_TILE_TYPE.ZONE_STORIES] = "ZO_ZoneStoriesTile_Keyboard_Control",
        [ZO_ACTION_TILE_TYPE.PROMOTIONAL_EVENT] = "ZO_PromotionalEventTile_KB",
    }

    local conditionFunction = function() return not IsInGamepadPreferredMode() end
    ZO_MarketAnnouncement_Shared.Initialize(self, control, conditionFunction)

    local AUTO_SCROLL = true
    self.carousel = ZO_MarketProductCarousel_Keyboard:New(self.carouselControl, "ZO_MarketAnnouncementMarketProductTile_Keyboard_Control", AUTO_SCROLL)
    self.productDescriptionBackground = self.controlContainer:GetNamedChild("ProductBG")
end

function ZO_MarketAnnouncement_Keyboard:InitializeKeybindButtons()
    ZO_MarketAnnouncement_Shared.InitializeKeybindButtons(self)

    self.closeButton:SetupStyle(KEYBIND_STRIP_STANDARD_STYLE)
end

function ZO_MarketAnnouncement_Keyboard:OnShowing()
    ZO_MarketAnnouncement_Shared.OnShowing(self)
end

function ZO_MarketAnnouncement_Keyboard:CreateMarketProduct()
    return ZO_MarketAnnouncementMarketProduct_Keyboard:New()
end

-- Global XML functions

function ZO_MarketAnnouncement_Keyboard_OnInitialize(control)
    ZO_KEYBOARD_MARKET_ANNOUNCEMENT = ZO_MarketAnnouncement_Keyboard:New(control)
    SYSTEMS:RegisterKeyboardObject("marketAnnouncement", ZO_KEYBOARD_MARKET_ANNOUNCEMENT)
end

function ZO_MarketAnnouncement_Keyboard_OnOpenCrownStore()
    ZO_KEYBOARD_MARKET_ANNOUNCEMENT:OnMarketAnnouncementViewCrownStoreKeybind()
end