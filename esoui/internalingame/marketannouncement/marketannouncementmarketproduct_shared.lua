ZO_MARKET_ANNOUNCEMENT_MARKET_PRODUCT_WIDTH = 1024
ZO_MARKET_ANNOUNCEMENT_MARKET_PRODUCT_HEIGHT = 512

ZO_MARKET_ANNOUNCEMENT_MARKET_PRODUCT_INFO_WIDTH = 350
ZO_MARKET_ANNOUNCEMENT_MARKET_PRODUCT_INFO_OFFSET_X = 20

local DESCRIPTION_TEXT_COLORS = {
    SELECTED_TEXT_COLOR = ZO_NORMAL_TEXT,
    UNSELECTED_TEXT_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_GAMEPAD_CATEGORY_HEADER))
}

----
-- ZO_MarketAnnouncementMarketProduct_Shared
----

ZO_MarketAnnouncementMarketProduct_Shared = ZO_LargeSingleMarketProduct_Base:Subclass()

function ZO_MarketAnnouncementMarketProduct_Shared:New(...)
    return ZO_LargeSingleMarketProduct_Base.New(self, ...)
end

function ZO_MarketAnnouncementMarketProduct_Shared:InitializeControls(control)
    ZO_LargeSingleMarketProduct_Base.InitializeControls(self, control)

    self.type = self.control:GetNamedChild("Type")
    self.description = self.control:GetNamedChild("ProductDescription")
    local scrollChild = self.description:GetNamedChild("ScrollChild")
    self.descriptionText = scrollChild:GetNamedChild("ProductDescriptionText")
end

function ZO_MarketAnnouncementMarketProduct_Shared:Show(...)
    ZO_LargeSingleMarketProduct_Base.Show(self, ...)

    self.descriptionText:SetText(zo_strformat(SI_MARKET_PRODUCT_DESCRIPTION_FORMATTER, self:GetMarketProductDescription()))
end

do
    -- Allow text to retain it's original size
    local TEXTURE_WIDTH_COORD = 1
    local TEXTURE_HEIGHT_COORD = 1

    function ZO_MarketAnnouncementMarketProduct_Shared:LayoutBackground(background)
        self.background:SetTexture(background)
        self.background:SetTextureCoords(0, TEXTURE_WIDTH_COORD, 0, TEXTURE_HEIGHT_COORD)
    end
end

function ZO_MarketAnnouncementMarketProduct_Shared:SetOnInteractWithScrollCallback(onInteractWithScrollCallback)
    self.onInteractWithScrollCallback = onInteractWithScrollCallback
end

function ZO_MarketAnnouncementMarketProduct_Shared:CallOnInteractWithScrollCallback()
    if self.onInteractWithScrollCallback then
        self.onInteractWithScrollCallback()
    end
end

function ZO_MarketAnnouncementMarketProduct_Shared:UpdateProductStyle()
    ZO_LargeSingleMarketProduct_Base.UpdateProductStyle(self)

    local isFocused = self.isFocused
    if isFocused then
        self.descriptionText:SetColor(DESCRIPTION_TEXT_COLORS.SELECTED_TEXT_COLOR:UnpackRGB())
        self.type:SetColor(DESCRIPTION_TEXT_COLORS.SELECTED_TEXT_COLOR:UnpackRGB())
    else
        self.descriptionText:SetColor(DESCRIPTION_TEXT_COLORS.UNSELECTED_TEXT_COLOR:UnpackRGB())
        self.type:SetColor(DESCRIPTION_TEXT_COLORS.UNSELECTED_TEXT_COLOR:UnpackRGB())
    end
end

function ZO_MarketAnnouncementMarketProduct_Shared:GetBackground()
    return GetMarketProductAnnouncementBackground(self.marketProductId)
end

-- Market Announcements only show tiles in an available state, never as purchased or a "fail" condition
function ZO_MarketAnnouncementMarketProduct_Shared:IsPurchaseLocked()
    return false
end

function ZO_MarketAnnouncementMarketProduct_Shared:GetPurchaseState()
    return MARKET_PRODUCT_PURCHASE_STATE_NOT_PURCHASED
end

function ZO_MarketAnnouncementMarketProduct_Shared:GetMarketProductListingsForHouseTemplate(houseTemplateId, displayGroup)
    return { GetActiveAnnouncementMarketProductListingsForHouseTemplate(houseTemplateId) }
end

function ZO_MarketAnnouncementMarketProduct_Shared:LayoutCostAndText(description, currencyType, cost, hasDiscount, costAfterDiscount, discountPercent, isNew)
    self:SetIsFree(cost, costAfterDiscount)

    self:SetupCalloutsDisplay(discountPercent, isNew)

    -- layout the price labels
    self:SetupPricingDisplay(currencyType, cost, costAfterDiscount)

    self:SetupPurchaseLabelDisplay()

    self:SetupTextCalloutAnchors()

    self:SetupBundleDisplay()

    local FOCUSED = true
    ZO_MarketClasses_Shared_ApplyTextColorToLabelByState(self.title, FOCUSED, self.purchaseState)
end

function ZO_MarketAnnouncementMarketProduct_Shared:SetupPurchaseLabelDisplay()
    ZO_MarketProductBase.SetupPurchaseLabelDisplay(self)

   self.purchaseLabelControl:SetHidden(self:CanBePurchased() or self:IsPromo())
end

function ZO_MarketAnnouncementMarketProduct_Shared:SetupTextCalloutAnchors()
    self.previousCost:ClearAnchors()
    self.cost:ClearAnchors()
    self.purchaseLabelControl:ClearAnchors()
    self.description:ClearAnchors()

    -- Call IsControlHidden instead of IsHidden because our parent control is likely hidden currently
    -- and we need to set the anchors based on whether the purchase label will be showing when we show the parent
    local showingPurchaseLabel = not self.purchaseLabelControl:IsControlHidden()

    local VERTICAL_SPACING = 5
    if showingPurchaseLabel then
        if self.textCallout:IsControlHidden() then
            self.purchaseLabelControl:SetAnchor(TOPLEFT, self.title, BOTTOMLEFT, ZO_MARKET_PRODUCT_CALLOUT_X_OFFSET, VERTICAL_SPACING)
            self.description:SetAnchor(TOPLEFT, self.purchaseLabelControl, BOTTOMLEFT)
        else
            self.purchaseLabelControl:SetAnchor(TOPLEFT, self.textCallout, BOTTOMLEFT)
            self.description:SetAnchor(TOPLEFT, self.purchaseLabelControl, BOTTOMLEFT, 0, VERTICAL_SPACING)
        end
    elseif self.onSale and not self.isFree then
        self.previousCost:SetAnchor(TOPLEFT, self.textCallout, BOTTOMLEFT)
        self.cost:SetAnchor(LEFT, self.previousCost, RIGHT, 10)
        self.description:SetAnchor(TOPLEFT, self.previousCost, BOTTOMLEFT)
    elseif self.textCallout:IsControlHidden() then
        if self.cost:IsControlHidden() then
            self.description:SetAnchor(TOPLEFT, self.title, BOTTOMLEFT, ZO_MARKET_PRODUCT_CALLOUT_X_OFFSET, VERTICAL_SPACING) 
        else
            self.cost:SetAnchor(TOPLEFT, self.title, BOTTOMLEFT, ZO_MARKET_PRODUCT_CALLOUT_X_OFFSET, VERTICAL_SPACING) 
            self.description:SetAnchor(TOPLEFT, self.cost, BOTTOMLEFT)
        end
    else
        self.cost:SetAnchor(TOPLEFT, self.textCallout, BOTTOMLEFT)  
        self.description:SetAnchor(TOPLEFT, self.cost, BOTTOMLEFT)
    end
end