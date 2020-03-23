----
-- ZO_MarketAnnouncementMarketProductTile_Keyboard
----

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_MarketAnnouncementMarketProductTile_Keyboard = ZO_Object.MultiSubclass(ZO_ActionTile_Keyboard, ZO_MarketAnnouncementMarketProductTile)

function ZO_MarketAnnouncementMarketProductTile_Keyboard:New(...)
    return ZO_MarketAnnouncementMarketProductTile.New(self, ...)
end

function ZO_MarketAnnouncementMarketProductTile_Keyboard:Initialize(...)
    return ZO_MarketAnnouncementMarketProductTile.Initialize(self, ...)
end

-- Begin ZO_MarketAnnouncementMarketProductTile Overrides --

function ZO_MarketAnnouncementMarketProductTile_Keyboard:AddMouseOverElement(element)
    self.mouseInputGroup:Add(element, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
end

function ZO_MarketAnnouncementMarketProductTile_Keyboard:Layout(data)
    local initializingMarketProduct = not self.marketProduct or not self.marketProduct.control
    local oldMarketProductId = self.marketProduct and self.marketProduct:GetId()

    ZO_MarketAnnouncementMarketProductTile.Layout(self, data)

    local marketProduct = data.marketProduct
    if initializingMarketProduct or marketProduct.control ~= self.control or oldMarketProductId ~= marketProduct:GetId() then
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

    if initializingMarketProduct then
        self.control.object:SetActionCallback(function() ZO_KEYBOARD_MARKET_ANNOUNCEMENT:OnMarketAnnouncementViewCrownStoreKeybind() end)

        if self.marketProduct then
            local descriptionControl = self.marketProduct:GetDescriptionControl()
            if descriptionControl then
                self.mouseInputGroup:Add(descriptionControl, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
                self.mouseInputGroup:Add(descriptionControl.scroll, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
                self.mouseInputGroup:Add(descriptionControl.scrollbar, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
                self.mouseInputGroup:Add(descriptionControl.scrollUpButton, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
                self.mouseInputGroup:Add(descriptionControl.scrollDownButton, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
            end
        end
    end

    -- we call layout when setting up the tile to be shown, so make sure the help button is reset to being hidden
    -- until we choose to show it on mouse over
    self.helpButton:SetHidden(true)
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
        local hasHelpLink = false
        if self.marketProduct then
            isPromo = self.marketProduct:IsPromo()
            local helpCategoryIndex, helpIndex = GetMarketAnnouncementHelpLinkIndices(self.marketProduct:GetId())
            hasHelpLink = helpCategoryIndex and helpIndex
        end

        self.numBundledProductsLabel:SetHidden((isMousedOver and isPromo) or self.numBundledProductsLabel:IsHidden())

        if isMousedOver and isPromo and hasHelpLink then
            self.helpButton:SetHidden(false)
            g_fadeInAnimationProvider:PlayForward(self.helpButton)
        else
            g_fadeInAnimationProvider:PlayBackward(self.helpButton)
        end
    end
end

function ZO_MarketAnnouncementMarketProductTile_Keyboard:SetHighlightHidden(hidden, instant)
    ZO_MarketAnnouncementMarketProductTile.SetHighlightHidden(self, hidden, instant)

    if self.marketProduct then
        self.marketProduct:SetHighlightHidden(hidden)
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
    ZO_MarketAnnouncementMarketProduct_Keyboard_OnInitialized(control)
    ZO_MarketAnnouncementMarketProductTile_Keyboard:New(control)
end