-- layers for the various elements on the market product tiles
-- controls are layered to ensure correct display order
-- Background layer
ZO_MARKET_TILE_BACKGROUND_LEVEL =   1
ZO_MARKET_TILE_OVERLAY_LEVEL =      9

-- Text/Content layer
ZO_MARKET_TILE_BORDER_LEVEL =       10
ZO_MARKET_TILE_TEXT_LEVEL =         11
ZO_MARKET_TILE_ABOVE_TEXT_LEVEL =   12

-- Top layer
ZO_MARKET_TILE_HIGHLIGHT_LEVEL =    20
-- icons should be on top of the highlight
ZO_MARKET_TILE_ICON_FRAME_LEVEL =   21
ZO_MARKET_TILE_ICON_IMAGE_LEVEL =   22

ZO_MARKET_PRODUCT_PURCHASED_DESATURATION = 1
ZO_MARKET_PRODUCT_NOT_PURCHASED_DESATURATION = 0

ZO_FEATURED_PRESENTATION_INDEX = nil
ZO_INVALID_PRESENTATION_INDEX = -1

do
    local function GetTextColor(enabled, normalColor, disabledColor)
        if enabled then
            return (normalColor or ZO_NORMAL_TEXT):UnpackRGBA()
        end
        return (disabledColor or ZO_DEFAULT_TEXT):UnpackRGBA()
    end

    function ZO_MarketClasses_Shared_ApplyTextColorToLabel(label, ...)
        label:SetColor(GetTextColor(...))
    end
end

do
    local MARKET_PRODUCT_COLOR_MAP_UNFOCUSED =
    {
            [MARKET_PRODUCT_PURCHASE_STATE_NOT_PURCHASED] = ZO_MARKET_DIMMED_COLOR,
            [MARKET_PRODUCT_PURCHASE_STATE_PURCHASED] = ZO_MARKET_PRODUCT_PURCHASED_DIMMED_COLOR,
            [MARKET_PRODUCT_PURCHASE_STATE_INSTANT_UNLOCK_COMPLETE] = ZO_MARKET_PRODUCT_PURCHASED_DIMMED_COLOR,
            [MARKET_PRODUCT_PURCHASE_STATE_INSTANT_UNLOCK_INELIGIBLE] = ZO_MARKET_PRODUCT_INELIGIBLE_DIMMED_COLOR,
    }

    local MARKET_PRODUCT_COLOR_MAP_FOCUSED =
    {
        [MARKET_PRODUCT_PURCHASE_STATE_NOT_PURCHASED] = ZO_MARKET_SELECTED_COLOR,
        [MARKET_PRODUCT_PURCHASE_STATE_PURCHASED] = ZO_MARKET_PRODUCT_PURCHASED_COLOR,
        [MARKET_PRODUCT_PURCHASE_STATE_INSTANT_UNLOCK_COMPLETE] = ZO_MARKET_PRODUCT_PURCHASED_COLOR,
        [MARKET_PRODUCT_PURCHASE_STATE_INSTANT_UNLOCK_INELIGIBLE] = ZO_MARKET_PRODUCT_INELIGIBLE_COLOR,
    }

    function ZO_MarketClasses_Shared_ApplyTextColorToLabelByState(label, isFocused, purchaseState)
        local colorLookup = isFocused and MARKET_PRODUCT_COLOR_MAP_FOCUSED or MARKET_PRODUCT_COLOR_MAP_UNFOCUSED
        local color = colorLookup[purchaseState]
        label:SetColor(color:UnpackRGB())
    end
end

--
--[[ MarketProductBase ]]--
--

ZO_MarketProductBase = ZO_Object:Subclass()

function ZO_MarketProductBase:New(...)
    local marketProduct = ZO_Object.New(self)
    marketProduct:Initialize(...)
    return marketProduct
end

local DEFAULT_CURRENCY_ICON_SIZE = 32
function ZO_MarketProductBase:Initialize(control, owner)
    self.owner = owner
    self.marketProductId = 0
    self.variation = 1
    self.textCalloutYOffset = 0

    if control then
        self:InitializeControls(control)
    end
end

function ZO_MarketProductBase:InitializeControls(control)
    control.marketProduct = self
    self.control = control
    self.title = control:GetNamedChild("Title")
    self.background = control:GetNamedChild("Background")
    self.highlight = control:GetNamedChild("Highlight")
    self.cost = control:GetNamedChild("Cost")
    self.previousCost = control:GetNamedChild("PreviousCost")
    if self.previousCost then
        self.previousCostStrikethrough = self.previousCost:GetNamedChild("Strikethrough")
    end
    self.purchaseLabelControl = control:GetNamedChild("Purchased")
    self.textCallout = control:GetNamedChild("TextCallout")
    self.textCalloutBackground = self.control:GetNamedChild("TextCalloutBackground")
    if self.textCalloutBackground then
        self.leftCalloutBackground = self.textCalloutBackground:GetNamedChild("Left")
        self.rightCalloutBackground = self.textCalloutBackground:GetNamedChild("Right")
        self.centerCalloutBackground = self.textCalloutBackground:GetNamedChild("Center")
    end
    self.bundledProductsLabel = control:GetNamedChild("BundledProducts")
    self.bundleIndicator = control:GetNamedChild("BundleIndicator")
end

function ZO_MarketProductBase:GetId()
    return self.marketProductId
end

function ZO_MarketProductBase:SetId(marketProductId)
    self.marketProductId = marketProductId
end

function ZO_MarketProductBase:GetMarketProductInfo()
    return GetMarketProductInfo(self.marketProductId)
end

function ZO_MarketProductBase:GetMarketProductDisplayName()
    return GetMarketProductDisplayName(self.marketProductId)
end

function ZO_MarketProductBase:GetMarketProductDescription()
    return GetMarketProductDescription(self.marketProductId)
end

function ZO_MarketProductBase:GetMarketProductPricingByPresentation()
    return GetMarketProductPricingByPresentation(self.marketProductId, self.presentationIndex)
end

function ZO_MarketProductBase:GetMarketProductType()
    return GetMarketProductType(self.marketProductId)
end

function ZO_MarketProductBase:GetNumChildren()
    return GetMarketProductNumChildren(self.marketProductId)
end

function ZO_MarketProductBase:GetChildMarketProductId(childIndex)
    return GetMarketProductChildId(self.marketProductId, childIndex)
end

function ZO_MarketProductBase:GetNumAttachedCollectibles()
    return GetMarketProductNumCollectibles(self.marketProductId)
end

function ZO_MarketProductBase:GetNumAttachedItems()
    return GetMarketProductNumItems(self.marketProductId)
end

function ZO_MarketProductBase:GetStackCount()
    return GetMarketProductStackCount(self.marketProductId)
end

function ZO_MarketProductBase:GetProductType()
    return GetMarketProductType(self.marketProductId)
end

function ZO_MarketProductBase:GetHidesChildProducts()
    if self:IsBundle() then
        return GetMarketProductBundleHidesChildProducts(self:GetId())
    end

    return false
end

function ZO_MarketProductBase:GetMarketProductCrownCrateId()
    return GetMarketProductCrownCrateId(self:GetId())
end

function ZO_MarketProductBase:GetTimeLeftInSeconds()
    return GetMarketProductTimeLeftInSeconds(self.marketProductId)
end

function ZO_MarketProductBase:GetPurchaseState()
    return GetMarketProductPurchaseState(self.marketProductId)
end

function ZO_MarketProductBase:IsPurchaseLocked()
    return self.purchaseState ~= MARKET_PRODUCT_PURCHASE_STATE_NOT_PURCHASED
end

function ZO_MarketProductBase:CanBePurchased()
    return not (self:IsPurchaseLocked() or self:IsHouseCollectible())
end

function ZO_MarketProductBase:IsHouseCollectible()
    if self:GetMarketProductType() == MARKET_PRODUCT_TYPE_COLLECTIBLE then
        local collectibleType = select(4, GetMarketProductCollectibleInfo(self:GetId()))
        if collectibleType == COLLECTIBLE_CATEGORY_TYPE_HOUSE then
            return true
        end
    end

    return false
end

function ZO_MarketProductBase:HasBeenPartiallyPurchased()
    return IsMarketProductPartiallyPurchased(self.marketProductId)
end

function ZO_MarketProductBase:HasSubscriptionUnlockedAttachments()
    return DoesMarketProductHaveSubscriptionUnlockedAttachments(self.marketProductId)
end

function ZO_MarketProductBase:GetBackgroundSaturation(isPurchased)
    return isPurchased and ZO_MARKET_PRODUCT_PURCHASED_DESATURATION or ZO_MARKET_PRODUCT_NOT_PURCHASED_DESATURATION
end

function ZO_MarketProductBase:IsLimitedTimeProduct()
    local remainingTime = self:GetTimeLeftInSeconds()
    return remainingTime > 0 and remainingTime <= ZO_ONE_MONTH_IN_SECONDS
end

function ZO_MarketProductBase:SetTextCalloutYOffset(yOffset)
    self.textCalloutYOffset = yOffset
end

do
    local TEXT_CALLOUT_BACKGROUND_ALPHA = 0.9
    function ZO_MarketProductBase:SetCalloutColor(calloutColor)
        local r, g, b = calloutColor:UnpackRGB()

        self.leftCalloutBackground:SetColor(r, g, b, TEXT_CALLOUT_BACKGROUND_ALPHA)
        self.rightCalloutBackground:SetColor(r, g, b, TEXT_CALLOUT_BACKGROUND_ALPHA)
        self.centerCalloutBackground:SetColor(r, g, b, TEXT_CALLOUT_BACKGROUND_ALPHA)
    end
end

do
    local NEW_STRING = GetString(SI_MARKET_TILE_CALLOUT_NEW)
    local FOCUSED = true
    local INHERIT_ICON_COLOR = true
    local CURRENCY_ICON_SIZE = "100%"
    function ZO_MarketProductBase:LayoutCostAndText(description, currencyType, cost, hasDiscount, costAfterDiscount, discountPercent, isNew)
        local hideCallouts = true
        local isFree = cost == 0 or costAfterDiscount == 0
        self.isFree = isFree

        local canBePurchased = self:CanBePurchased()
        local isHouseCollectible = self:IsHouseCollectible()

        -- setup the callouts for new, on sale, and LTO
        if canBePurchased or (isHouseCollectible and self.purchaseState == MARKET_PRODUCT_PURCHASE_STATE_NOT_PURCHASED) then
            local onSale = discountPercent > 0 and not isHouseCollectible

            local calloutUpdateHandler
            -- only show limited time callouts if there is actually a limited amount of time left and it's 1 month or less
            if self:IsLimitedTimeProduct() then
                hideCallouts = false
                self:UpdateRemainingTimeCalloutText()
                calloutUpdateHandler = function() self:UpdateRemainingTimeCalloutText() end
            elseif onSale then
                hideCallouts = false
                self.textCallout:SetText(zo_strformat(SI_MARKET_DISCOUNT_PRICE_PERCENT_FORMAT, discountPercent))
                calloutUpdateHandler = nil
                self.textCallout:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
            elseif isNew then
                hideCallouts = false
                self.textCallout:SetText(NEW_STRING)
                calloutUpdateHandler = nil
                self.textCallout:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
            end

            self.textCallout:SetHandler("OnUpdate", calloutUpdateHandler)

            self.onSale = onSale
            self.isNew = isNew
        end

        self.textCallout:SetHidden(hideCallouts)

        -- layout the price labels
        if canBePurchased then
            -- setup the cost
            if self.onSale and not isFree then
                self.previousCost:SetText(ZO_CommaDelimitNumber(cost))
            end

            if not isFree then
                self.previousCost:SetHidden(not self.onSale)
                self.previousCostStrikethrough:SetHidden(not self.onSale)
                local currencyIcon = ZO_Currency_GetPlatformFormattedCurrencyIcon(ZO_Currency_MarketCurrencyToUICurrency(currencyType), CURRENCY_ICON_SIZE, INHERIT_ICON_COLOR)
                local currencyString = zo_strformat(SI_CURRENCY_AMOUNT_WITH_ICON, ZO_CommaDelimitNumber(costAfterDiscount), currencyIcon)
                self.cost:SetText(currencyString)
            else
                self.previousCost:SetHidden(true)
                self.previousCostStrikethrough:SetHidden(true)
                self.purchaseLabelControl:SetText(GetString(SI_MARKET_FREE_LABEL))
                ZO_MarketClasses_Shared_ApplyTextColorToLabelByState(self.purchaseLabelControl, FOCUSED, self.purchaseState)
            end

            self.purchaseLabelControl:SetHidden(not isFree)
            self.cost:SetHidden(isFree)
        else
            if self.purchaseState == MARKET_PRODUCT_PURCHASE_STATE_NOT_PURCHASED and isHouseCollectible then
                self.purchaseLabelControl:SetText(GetString(SI_MARKET_PREVIEW_KEYBIND_TEXT))
            elseif self.purchaseState == MARKET_PRODUCT_PURCHASE_STATE_INSTANT_UNLOCK_COMPLETE then
                local errorStringId = GetMarketProductCompleteErrorStringId(self.marketProductId)
                self.purchaseLabelControl:SetText(GetErrorString(errorStringId))
            elseif self.purchaseState == MARKET_PRODUCT_PURCHASE_STATE_INSTANT_UNLOCK_INELIGIBLE then
                self.purchaseLabelControl:SetText(GetString(SI_MARKET_INSTANT_UNLOCK_INELIGIBLE_LABEL))
            else
                self.purchaseLabelControl:SetText(GetString(SI_MARKET_PURCHASED_LABEL))
            end
            ZO_MarketClasses_Shared_ApplyTextColorToLabelByState(self.purchaseLabelControl, FOCUSED, self.purchaseState)

            self.purchaseLabelControl:SetHidden(false)
            self.previousCost:SetHidden(true)
            self.cost:SetHidden(true)
        end

        self.cost:ClearAnchors()
        self.textCallout:ClearAnchors()

        -- Call IsControlHidden instead of IsHidden because our parent control is likely hidden currently
        -- and we need to set the anchors based on whether the purchase label will be showing when we show the parent
        local showingPurchaseLabel = not self.purchaseLabelControl:IsControlHidden()

        if showingPurchaseLabel then
            self.textCallout:SetAnchor(BOTTOMLEFT, self.purchaseLabelControl, TOPLEFT, ZO_LARGE_SINGLE_MARKET_PRODUCT_CALLOUT_X_OFFSET, self.textCalloutYOffset)
        elseif self.onSale then
            self.cost:SetAnchor(BOTTOMLEFT, self.previousCost, BOTTOMRIGHT, 10)
            self.textCallout:SetAnchor(BOTTOMLEFT, self.previousCost, TOPLEFT, ZO_MARKET_PRODUCT_CALLOUT_X_OFFSET - 2, self.textCalloutYOffset) -- x offset to account for strikethrough
        else
            self.cost:SetAnchor(BOTTOMLEFT, self.control, BOTTOMLEFT, 10, -10)
            self.textCallout:SetAnchor(BOTTOMLEFT, self.cost, TOPLEFT, ZO_MARKET_PRODUCT_CALLOUT_X_OFFSET, self.textCalloutYOffset)
        end

        local isBundle = self:IsBundle()
        if isBundle then
            local numBundledProducts = GetMarketProductNumBundledProducts(self.marketProductId)
            self.bundledProductsLabel:SetText(numBundledProducts)
            -- hide the label if the result is 0 or 1 (which means either an empty bundle or what should be a single product...)
            if numBundledProducts > 1 then
                self.bundledProductsLabel:SetHidden(false)
            else
                self.bundledProductsLabel:SetHidden(true)
            end
        else
            self.bundledProductsLabel:SetHidden(true)
        end

        self.bundleIndicator:SetHidden(not isBundle)

        ZO_MarketClasses_Shared_ApplyTextColorToLabelByState(self.title, FOCUSED, self.purchaseState)
    end
end

function ZO_MarketProductBase:UpdateRemainingTimeCalloutText()
    local remainingTime = self:GetTimeLeftInSeconds()
    -- if there is no time left remaining then the MarketProduct is not limited time
    -- because when a limited time product reaches 0 it is removed form the store
    if remainingTime > 0 then
        if remainingTime >= ZO_ONE_DAY_IN_SECONDS then
            self.textCallout:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
            self.textCallout:SetText(zo_strformat(SI_TIME_DURATION_LEFT, ZO_FormatTime(remainingTime, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS)))
        else
            self.textCallout:SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
            self.textCallout:SetText(zo_strformat(SI_TIME_DURATION_LEFT, ZO_FormatTimeLargestTwo(remainingTime, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL)))
        end
    end
end

function ZO_MarketProductBase:GetPresentationIndex()
    return self.presentationIndex
end

function ZO_MarketProductBase:HasValidPresentationIndex()
    return self.presentationIndex ~= ZO_INVALID_PRESENTATION_INDEX
end

function ZO_MarketProductBase:Show(marketProductId, presentationIndex)
    if marketProductId ~= nil then
        self:SetId(marketProductId)
    end

    self.presentationIndex = presentationIndex

    self.purchaseState = self:GetPurchaseState()

    local name, description, icon, isNew, isFeatured = self:GetMarketProductInfo()
    local background = self:GetBackground()

    self.name = name
    self:SetTitle(name)

    self:PerformLayout(description, icon, background, isNew, isFeatured)

    local currencyType, cost, hasDiscount, costAfterDiscount, discountPercent = self:GetMarketProductPricingByPresentation()
    self:LayoutCostAndText(description, currencyType, cost, hasDiscount, costAfterDiscount, discountPercent, isNew)

    self:LayoutBackground(background)

    self.control:SetHidden(false)
end

function ZO_MarketProductBase:GetControl()
    return self.control
end

function ZO_MarketProductBase:SetParent(parentControl)
    self.control:SetParent(parentControl)
end

function ZO_MarketProductBase:Reset()
    self.control:SetHidden(true)
    self:SetHighlightHidden(true)
    self.textCallout:SetHidden(true)
    self.marketProductId = 0
    self.onSale = false
    self.isNew = false
end

function ZO_MarketProductBase:Refresh()
    local productId = self:GetId()
    if productId > 0 then
        self:Show(productId, self:GetPresentationIndex())
    end
end

function ZO_MarketProductBase:SetHighlightHidden(hidden)
    if self.highlight then
        self.highlight:SetHidden(false) -- let alpha take care of the actual hiding

        if not self.highlightAnimation then
            self.highlightAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("MarketProductHighlightAnimation", self.highlight)
        end

        if hidden then
            self.highlightAnimation:PlayBackward()
        else
            self.highlightAnimation:PlayForward()
        end
    end
end

function ZO_MarketProductBase:PlayHighlightAnimationToEnd()
    if self.highlightAnimation then
        self.highlightAnimation:PlayInstantlyToEnd()
    end
end

function ZO_MarketProductBase:SetTitle(title)
    self.title:SetText(zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, title))
end

-- MarketProduct Preview functions

function ZO_MarketProductBase:HasPreview()
    --Houses are special because as far as C is concerned they aren't previewable, but Lua allows for a roundabout preview with jumping to the house
    return CanPreviewMarketProduct(self.marketProductId) or ZO_Market_Shared.GetMarketProductPreviewType(self) == ZO_MARKET_PREVIEW_TYPE_HOUSE
end

function ZO_MarketProductBase:EndPreview()
    EndCurrentMarketPreview()
    self.owner:RefreshActions()
end

function ZO_MarketProductBase:GetNumPreviewVariations()
    return GetNumMarketProductPreviewVariations(self.marketProductId)
end

-- virtual functions

function ZO_MarketProductBase:Purchase()
    -- to be overridden
end

function ZO_MarketProductBase:PerformLayout(name, description, icon, background, isNew, isFeatured)
    -- to be overridden
end

function ZO_MarketProductBase:IsBundle()
    return GetMarketProductType(self.marketProductId) == MARKET_PRODUCT_TYPE_BUNDLE
end

function ZO_MarketProductBase:IsBlank()
    -- to be overridden, default behavior
    return false
end

function ZO_MarketProductBase:LayoutBackground(background)
    -- to be overridden
end

function ZO_MarketProductBase:GetBackground()
    assert(false) -- must be overriden
end

--
--[[ MarketBlankProductBase ]]--
--

-- Used to fill the market grid with blank entries, which could be potentially selectable

ZO_MarketBlankProductBase = ZO_MarketProductBase:Subclass()

function ZO_MarketBlankProductBase:New(...)
    return ZO_MarketProductBase.New(self, ...)
end

function ZO_MarketBlankProductBase:IsBlank()
    return true
end

function ZO_MarketBlankProductBase:HasPreview()
    return false
end

function ZO_MarketBlankProductBase:GetBackground()
    return nil -- Blank tiles have no background
end

function ZO_MarketBlankProductBase:Show()
    self.control:SetHidden(false)
end