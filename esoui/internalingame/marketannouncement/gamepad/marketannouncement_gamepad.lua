--
-- MarketProductCarousel_Gamepad
--

local MarketProductCarousel_Gamepad = ZO_MarketProductCarousel:Subclass()

function MarketProductCarousel_Gamepad:New(...)
    return ZO_MarketProductCarousel.New(self, ...)
end

function MarketProductCarousel_Gamepad:Initialize(...)
    ZO_MarketProductCarousel.Initialize(self, ...)
    self.leftArrow.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_MarketAnnouncement_ArrowScaleAnimation_Gamepad", self.leftArrow)
    self.rightArrow.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_MarketAnnouncement_ArrowScaleAnimation_Gamepad", self.rightArrow)

    self.leftArrow.downAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_MarketAnnouncement_ArrowDownScaleAnimation_Gamepad", self.leftArrow)
    self.rightArrow.downAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_MarketAnnouncement_ArrowDownScaleAnimation_Gamepad", self.rightArrow)
end

-- overrides to handle gamepad arrow animations
do
    local function EndArrowAnimationIfDisabled(control)
        local currentState = control:GetState()
        if currentState == BSTATE_DISABLED or currentState == BSTATE_DISABLED_PRESSED then
            if control.animation then
                control.animation:PlayInstantlyToStart()
            end
        end
    end

    function MarketProductCarousel_Gamepad:UpdateArrows()
        ZO_HorizontalScrollList_Gamepad.UpdateArrows(self)

        EndArrowAnimationIfDisabled(self.leftArrow)
        EndArrowAnimationIfDisabled(self.rightArrow)
    end

    function MarketProductCarousel_Gamepad:UpdateAnchors(...)
        ZO_HorizontalScrollList.UpdateAnchors(self, ...)

        EndArrowAnimationIfDisabled(self.leftArrow)
        EndArrowAnimationIfDisabled(self.rightArrow)
    end
end

----
-- MarketAnnouncement_Gamepad
----

local MarketAnnouncement_Gamepad = ZO_MarketAnnouncement_Base:Subclass()

function MarketAnnouncement_Gamepad:New(...)
    return ZO_MarketAnnouncement_Base.New(self, ...)
end

function MarketAnnouncement_Gamepad:Initialize(control)
    ZO_MarketAnnouncement_Base.Initialize(self, control, IsInGamepadPreferredMode)
    self.carousel = MarketProductCarousel_Gamepad:New(self.carouselControl, "ZO_MarketAnnouncement_MarketProductTemplate_Gamepad")
end

function MarketAnnouncement_Gamepad:InitializeKeybindButtons()
    ZO_MarketAnnouncement_Base.InitializeKeybindButtons(self)

    self.crownStoreButton:SetupStyle(KEYBIND_STRIP_GAMEPAD_STYLE)
    self.closeButton:SetupStyle(KEYBIND_STRIP_GAMEPAD_STYLE)
end

function MarketAnnouncement_Gamepad:CreateMarketProduct(productId)
    local marketProduct = ZO_MarketAnnouncementMarketProduct_Base:New()
    marketProduct:SetId(productId)
    return marketProduct
end

--global XML functions

function ZO_MarketAnnouncement_Gamepad_OnInitialize(control)
    ZO_GAMEPAD_MARKET_ANNOUNCEMENT = MarketAnnouncement_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject("marketAnnouncement", ZO_GAMEPAD_MARKET_ANNOUNCEMENT)
end

function ZO_MarketAnnouncement_Gamepad_PlayArrowAnimation(control, animation, playForward)
    local currentState = control:GetState()
    if not (currentState == BSTATE_DISABLED or currentState == BSTATE_DISABLED_PRESSED) then
        if playForward then
            animation:PlayForward()
        else
            animation:PlayBackward()
        end
    end
end