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

function ZO_MarketProductBase:Initialize(control, owner)
    self.owner = owner
    self.marketProductId = 0
    self.variation = 1
    self.activeMarketProductIcon = nil

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

function ZO_MarketProductBase:GetMarketProductInfo()
    return GetMarketProductInfo(self.marketProductId)
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

function ZO_MarketProductBase:GetProductType()
    return GetMarketProductType(self.marketProductId)
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
    function ZO_MarketProductBase:LayoutCostAndText(description, cost, discountPercent, discountedCost, isNew)
        local canPurchase = not self:IsPurchaseLocked()
        local hideCallouts = true
        local isFree = cost == 0 or discountedCost == 0
        self.isFree = isFree

        if canPurchase then
             -- callouts for new and on sale
            local onSale = discountPercent > 0

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

            -- setup the cost
            if onSale and not isFree then
                self.previousCost:SetText(ZO_CommaDelimitNumber(cost))
            end

            if not isFree then
                self.previousCost:SetHidden(not onSale)
                self.previousCostStrikethrough:SetHidden(not onSale)
                self.cost:SetText(zo_strformat(SI_MARKET_LABEL_CURRENCY_FORMAT_NO_ICON, ZO_CommaDelimitNumber(discountedCost)))
            else
                self.previousCost:SetHidden(true)
                self.previousCostStrikethrough:SetHidden(true)
                self.purchaseLabelControl:SetText(GetString(SI_MARKET_FREE_LABEL))
                ZO_MarketClasses_Shared_ApplyTextColorToLabelByState(self.purchaseLabelControl, FOCUSED, self.purchaseState)
            end

            self.purchaseLabelControl:SetHidden(not isFree)
            self.cost:SetHidden(isFree)
        else
            self.previousCost:SetHidden(true)
            if self.purchaseState == MARKET_PRODUCT_PURCHASE_STATE_INSTANT_UNLOCK_COMPLETE then
                local errorStringId = GetMarketProductCompleteErrorStringId(self.marketProductId)
                self.purchaseLabelControl:SetText(GetErrorString(errorStringId))
            elseif self.purchaseState == MARKET_PRODUCT_PURCHASE_STATE_INSTANT_UNLOCK_INELIGIBLE then
                self.purchaseLabelControl:SetText(GetString(SI_MARKET_INSTANT_UNLOCK_INELIGIBLE_LABEL))
            else
                self.purchaseLabelControl:SetText(GetString(SI_MARKET_PURCHASED_LABEL))
            end
            ZO_MarketClasses_Shared_ApplyTextColorToLabelByState(self.purchaseLabelControl, FOCUSED, self.purchaseState)

            self.purchaseLabelControl:SetHidden(false)
            self.cost:SetHidden(true)
        end

        self.textCallout:SetHidden(hideCallouts)

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

function ZO_MarketProductBase:SetId(marketProductId)
    self.marketProductId = marketProductId
end

function ZO_MarketProductBase:Show(marketProductId)
    if marketProductId ~= nil then
        self:SetId(marketProductId)
    end

    self.purchaseState = self:GetPurchaseState()

    local name, description, cost, discountedCost, discountPercent, icon, isNew, isFeatured = self:GetMarketProductInfo()
    local background = self:GetBackground()

    self.name = name
    self:SetTitle(name)
    
    --PerformLayout will handle running the name through grammar, in case it needs to get applied to a more complicated paramaterized string somewhere
    self:PerformLayout(description, cost, discountedCost, discountPercent, icon, background, isNew, isFeatured)

    self:LayoutCostAndText(description, cost, discountPercent, discountedCost, isNew)

    self:LayoutBackground(background)

    self.control:SetHidden(false)
end


function ZO_MarketProductBase:GetControl()
    return self.control
end

function ZO_MarketProductBase:Reset()
    self.control:SetHidden(true)
    self:SetHighlightHidden(true)
    self.textCallout:SetHidden(true)
    self.activeMarketProductIcon = nil
    self.marketProductId = 0
end

function ZO_MarketProductBase:Refresh()
    local productId = self:GetId()
    if productId > 0 then
        self:Show(productId)
    end
end

function ZO_MarketProductBase:SetHighlightHidden(hidden)
    if self.highlight then
        self.highlight:SetHidden(false) -- let alpha take care of the actual hiding

        if not self.highlightAnimation then
            self.highlightAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("MarketProductHighlightAnimation", self.highlight)
        end

        if(hidden) then
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

function ZO_MarketProductBase:HasActiveIcon()
    return self.activeMarketProductIcon ~= nil
end

function ZO_MarketProductBase:SetTitle(title)
    self.title:SetText(zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, title))
end

-- MarketProduct Preview functions

function ZO_MarketProductBase:HasPreview()
    return CanPreviewMarketProduct(self.marketProductId)
end

function ZO_MarketProductBase:Preview()
    PreviewMarketProduct(self.marketProductId, self.variation)
    self.owner:RefreshActions()
    PlaySound(SOUNDS.MARKET_PREVIEW_SELECTED)
end

function ZO_MarketProductBase:EndPreview()
    EndCurrentMarketPreview()
    self.owner:RefreshActions()
end

function ZO_MarketProductBase:GetPreviewVariationDisplayName()
    local previewVariationDisplayName = GetMarketProductPreviewVariationDisplayName(self.marketProductId, self.variation)

    if previewVariationDisplayName == "" then
        return self.variation
    else
        return previewVariationDisplayName
    end
end

function ZO_MarketProductBase:GetNumPreviewVariations()
    return GetNumMarketProductPreviewVariations(self.marketProductId)
end

function ZO_MarketProductBase:PreviewNextVariation()
    if self:HasPreview() and self:GetNumPreviewVariations() > 0 then
        self.variation = self.variation + 1

        if self.variation > self:GetNumPreviewVariations() then
            self.variation = 1
        end

        self:Preview()
    end
end

function ZO_MarketProductBase:PreviewPreviousVariation()
    if self:HasPreview() and self:GetNumPreviewVariations() > 0 then
        self.variation = self.variation - 1
        
        if self.variation < 1 then
            self.variation = self:GetNumPreviewVariations()
        end

        self:Preview()
    end
end

-- virtual functions

function ZO_MarketProductBase:Purchase()
    -- to be overridden
end

function ZO_MarketProductBase:PerformLayout(name, description, cost, discountedCost, discountPercent, icon, background, isNew, isFeatured)
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