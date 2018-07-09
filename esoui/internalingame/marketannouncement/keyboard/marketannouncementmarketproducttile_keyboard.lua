----
-- ZO_MarketAnnouncementMarketProductTile_Keyboard
----

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_MarketAnnouncementMarketProductTile_Keyboard = ZO_Object.MultiSubclass(ZO_ActionTile_Keyboard, ZO_MarketAnnouncementMarketProductTile)

function ZO_MarketAnnouncementMarketProductTile_Keyboard:New(...)
    return ZO_MarketAnnouncementMarketProductTile.New(self, ...)
end

-- Begin ZO_MarketAnnouncementMarketProductTile Overrides --

function ZO_MarketAnnouncementMarketProductTile:AddMouseOverElement(element)
    self.mouseInputGroup:Add(element, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
end

function ZO_MarketAnnouncementMarketProductTile_Keyboard:Layout(marketProduct, selected)
    local initializingMarketProduct = not self.marketProduct or not self.marketProduct.control

    ZO_MarketAnnouncementMarketProductTile.Layout(self, marketProduct, selected)

    if initializingMarketProduct then
        self.control.object:SetActionCallback(function() ZO_KEYBOARD_MARKET_ANNOUNCEMENT:OnMarketAnnouncementViewCrownStoreKeybind() end)

        if self.marketProduct and self.marketProduct.description then
            self.mouseInputGroup:Add(self.marketProduct.description, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
            self.mouseInputGroup:Add(self.marketProduct.description.scroll, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
            self.mouseInputGroup:Add(self.marketProduct.description.scrollbar, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
            self.mouseInputGroup:Add(self.marketProduct.description.scrollUpButton, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
            self.mouseInputGroup:Add(self.marketProduct.description.scrollDownButton, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
        end
    end
end

-- End ZO_MarketAnnouncementMarketProductTile Overrides --

-- Begin ZO_ActionTile_Keyboard Overrides --

function ZO_MarketAnnouncementMarketProductTile_Keyboard:InitializePlatform()
    ZO_ActionTile_Keyboard.InitializePlatform(self)

    -- Function called on OnUpdate will force the button to remain highlighted if whole tile is highlighted
    local function SetActionButtonHighlight()
        self.actionButton:SetShowingHighlight(not self:IsHighlightHidden())
    end

    self.control:SetHandler("OnUpdate", SetActionButtonHighlight)
end

function ZO_MarketAnnouncementMarketProductTile_Keyboard:PostInitializePlatform()
    ZO_ActionTile_Keyboard.PostInitializePlatform(self)

    self.numBundledProductsLabel = self.control:GetNamedChild("BundledProducts")
    self.helpButton = self.container:GetNamedChild("Help")

    local onClick = function()
        self:OnHelpSelected()
    end

    self.helpButton:SetHandler("OnClicked", onClick)

    self.mouseInputGroup = ZO_MouseInputGroup:New(self.control)
    self.mouseInputGroup:Add(self.actionButton, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
    self.mouseInputGroup:Add(self.helpButton, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
end

function ZO_MarketAnnouncementMarketProductTile_Keyboard:OnMouseEnter()
    ZO_ActionTile_Keyboard.OnMouseEnter(self)
    self.isMousedOver = true

    self.actionButton:SetShowingHighlight(self.isMousedOver)
    self:UpdateHelpVisibility(self.isMousedOver)
end

function ZO_MarketAnnouncementMarketProductTile_Keyboard:OnMouseExit()
    ZO_ActionTile_Keyboard.OnMouseExit(self)
    self.isMousedOver = false

    self.actionButton:SetShowingHighlight(self.isMousedOver)
    
    if self.marketProduct then
        self.marketProduct:SetupBundleDisplay()
    end

    self:UpdateHelpVisibility(self.isMousedOver)
end

do
    local g_fadeInAnimationProvider = ZO_ReversibleAnimationProvider:New("ZO_KeyboardMarketProductFadeInAnimation")

    function ZO_MarketAnnouncementMarketProductTile_Keyboard:UpdateHelpVisibility(isMousedOver)
        local isPromo = false
        if self.marketProduct then
            isPromo = self.marketProduct:IsPromo()
        end

        self.numBundledProductsLabel:SetHidden((isMousedOver and isPromo) or self.numBundledProductsLabel:IsHidden())

        if not isMousedOver or not isPromo then
            g_fadeInAnimationProvider:PlayBackward(self.helpButton)
        else
            g_fadeInAnimationProvider:PlayForward(self.helpButton)
        end
    end
end

-- End ZO_ActionTile_Keyboard Overrides --

function ZO_MarketAnnouncementMarketProductTile_Keyboard:OnMouseUp(button, upInside)
    if self.actionCallback and self:IsActionAvailable() then
        self.actionCallback()
    end
end

-----
-- Global XML Functions
-----

function ZO_MarketAnnouncementMarketProductTile_Keyboard_OnInitialized(control)
    ZO_MarketAnnouncementMarketProductTile_Keyboard:New(control)
end