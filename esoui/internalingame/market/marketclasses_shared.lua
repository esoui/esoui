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

--account for the fade that we add to the sides of the callout
ZO_MARKET_PRODUCT_CALLOUT_X_OFFSET = 5

ZO_MARKET_PRODUCT_HIGHLIGHT_ANIMATION_DURATION_MS = 255

do
    local MARKET_PRODUCT_COLOR_MAP_UNFOCUSED =
    {
        [MARKET_PRODUCT_DISPLAY_STATE_NOT_PURCHASED] = ZO_MARKET_DIMMED_COLOR,
        [MARKET_PRODUCT_DISPLAY_STATE_PURCHASED] = ZO_MARKET_PRODUCT_PURCHASED_DIMMED_COLOR,
        [MARKET_PRODUCT_DISPLAY_STATE_INELIGIBLE] = ZO_MARKET_PRODUCT_INELIGIBLE_DIMMED_COLOR,
    }

    local MARKET_PRODUCT_COLOR_MAP_FOCUSED =
    {
        [MARKET_PRODUCT_DISPLAY_STATE_NOT_PURCHASED] = ZO_MARKET_SELECTED_COLOR,
        [MARKET_PRODUCT_DISPLAY_STATE_PURCHASED] = ZO_MARKET_PRODUCT_PURCHASED_COLOR,
        [MARKET_PRODUCT_DISPLAY_STATE_INELIGIBLE] = ZO_MARKET_PRODUCT_INELIGIBLE_COLOR,
    }

    function ZO_MarketClasses_Shared_ApplyTextColorToLabelByState(label, isFocused, displayState)
        local colorLookup = isFocused and MARKET_PRODUCT_COLOR_MAP_FOCUSED or MARKET_PRODUCT_COLOR_MAP_UNFOCUSED
        local color = colorLookup[displayState]
        label:SetColor(color:UnpackRGB())
    end
end

do
    local UNFOCUSED_COLOR_MAP =
    {
        [MARKET_PRODUCT_DISPLAY_STATE_NOT_PURCHASED] = ZO_MARKET_PRODUCT_ESO_PLUS_DIMMED_COLOR,
        [MARKET_PRODUCT_DISPLAY_STATE_PURCHASED] = ZO_MARKET_PRODUCT_ESO_PLUS_PURCHASED_DIMMED_COLOR,
        [MARKET_PRODUCT_DISPLAY_STATE_INELIGIBLE] = ZO_MARKET_PRODUCT_ESO_PLUS_PURCHASED_DIMMED_COLOR,
    }

    local FOCUSED_COLOR_MAP =
    {
        [MARKET_PRODUCT_DISPLAY_STATE_NOT_PURCHASED] = ZO_MARKET_PRODUCT_ESO_PLUS_COLOR,
        [MARKET_PRODUCT_DISPLAY_STATE_PURCHASED] = ZO_MARKET_PRODUCT_ESO_PLUS_PURCHASED_COLOR,
        [MARKET_PRODUCT_DISPLAY_STATE_INELIGIBLE] = ZO_MARKET_PRODUCT_ESO_PLUS_PURCHASED_COLOR,
    }

    function ZO_MarketClasses_Shared_ApplyEsoPlusColorToLabelByState(label, isFocused, displayState)
        local colorLookup = isFocused and FOCUSED_COLOR_MAP or UNFOCUSED_COLOR_MAP
        local color = colorLookup[displayState]
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

function ZO_MarketProductBase:Initialize(control)
    self.textCalloutYOffset = 0
    self.control = control
end

function ZO_MarketProductBase:SetTextCalloutYOffset(yOffset)
    self.textCalloutYOffset = yOffset
end

function ZO_MarketProductBase:SetControl(control)
    self.control = control
end

function ZO_MarketProductBase:GetControl()
    return self.control
end

function ZO_MarketProductBase:SetMarketProductData(marketProductData)
    self.productData = marketProductData
end

function ZO_MarketProductBase:GetMarketProductData()
    return self.productData
end

function ZO_MarketProductBase:SetParent(parentControl)
    self.control:SetParent(parentControl)
end

function ZO_MarketProductBase:GetId()
    return self.productData:GetId()
end

function ZO_MarketProductBase:GetPresentationIndex()
    return self.productData:GetPresentationIndex()
end

function ZO_MarketProductBase:HasValidPresentationIndex()
    return self.productData:HasValidPresentationIndex()
end

function ZO_MarketProductBase:GetMarketProductDisplayName()
    return self.productData:GetDisplayName()
end

function ZO_MarketProductBase:GetMarketProductPricingByPresentation()
    return self.productData:GetMarketProductPricingByPresentation()
end

function ZO_MarketProductBase:GetMarketProductType()
    return self.productData:GetMarketProductType()
end

function ZO_MarketProductBase:GetNumChildren()
    return self.productData:GetNumChildren()
end

function ZO_MarketProductBase:GetChildMarketProductId(childIndex)
    return self.productData:GetChildMarketProductId(childIndex)
end

function ZO_MarketProductBase:GetStackCount()
    return self.productData:GetStackCount()
end

function ZO_MarketProductBase:GetHidesChildProducts()
    return self.productData:GetHidesChildProducts()
end

function ZO_MarketProductBase:IsGiftable()
    return self.productData:IsGiftable()
end

function ZO_MarketProductBase:GetMarketProductDisplayState()
    -- may be overridden by child classes that require additional logic
    return self.productData:GetMarketProductDisplayState()
end

function ZO_MarketProductBase:IsPurchaseLocked()
    return self.displayState ~= MARKET_PRODUCT_DISPLAY_STATE_NOT_PURCHASED
end

function ZO_MarketProductBase:CanBePurchased()
    return not (self:IsPurchaseLocked() or self:IsHouseCollectible() or self:IsPromo())
end

function ZO_MarketProductBase:IsBundle()
    return self.productData:IsBundle()
end

function ZO_MarketProductBase:IsPromo()
    return self.productData:IsPromo()
end

function ZO_MarketProductBase:IsHouseCollectible()
    return self.productData:IsHouseCollectible()
end

function ZO_MarketProductBase:HasBeenPartiallyPurchased()
    return self.productData:HasBeenPartiallyPurchased()
end

function ZO_MarketProductBase:HasSubscriptionUnlockedAttachments()
    return self.productData:HasSubscriptionUnlockedAttachments()
end

function ZO_MarketProductBase:AreAllCollectiblesUnlocked()
    return self.productData:AreAllCollectiblesUnlocked()
end

function ZO_MarketProductBase:IsLimitedTimeProduct()
    return self.productData:IsLimitedTimeProduct()
end

function ZO_MarketProductBase:GetBackgroundDesaturation(isPurchased)
    return isPurchased and ZO_MARKET_PRODUCT_PURCHASED_DESATURATION or ZO_MARKET_PRODUCT_NOT_PURCHASED_DESATURATION
end

function ZO_MarketProductBase:LayoutCostAndText()
    -- setup the callouts for new, on sale, and LTO
    self:SetupCalloutsDisplay()

    -- layout the price labels
    self:SetupPricingDisplay()

    local control = self.control
    control.cost:ClearAnchors()
    control.textCallout:ClearAnchors()
    control.esoPlusCost:ClearAnchors()

    local hasNormalCost = self:HasCost()
    if hasNormalCost then
        if self:IsOnSale() and not self:IsFree() then
            control.cost:SetAnchor(BOTTOMLEFT, control.previousCost, BOTTOMRIGHT, 10)
            control.textCallout:SetAnchor(BOTTOMLEFT, control.previousCost, TOPLEFT, ZO_MARKET_PRODUCT_CALLOUT_X_OFFSET - 2, self.textCalloutYOffset) -- x offset to account for strikethrough
        else
            control.cost:SetAnchor(BOTTOMLEFT, control, BOTTOMLEFT, 10, -10)
            control.textCallout:SetAnchor(BOTTOMLEFT, control.cost, TOPLEFT, ZO_MARKET_PRODUCT_CALLOUT_X_OFFSET, self.textCalloutYOffset)
        end
    else
        -- if we don't have a normal cost, then we need to anchor the callout to the ESO Plus cost
        -- there should never be a case where a market product has neither a normal cost nor an ESO Plus cost (because then it would be unpurchasable)
        control.textCallout:SetAnchor(BOTTOMLEFT, control.esoPlusCost, TOPLEFT, ZO_MARKET_PRODUCT_CALLOUT_X_OFFSET, self.textCalloutYOffset)
    end

    local hasEsoPlusCost = self:HasEsoPlusCost()
    if hasEsoPlusCost then
        if hasNormalCost then
            control.esoPlusCost:SetAnchor(BOTTOMLEFT, control.cost, BOTTOMRIGHT, 10)
        else
            control.esoPlusCost:SetAnchor(BOTTOMLEFT, control, BOTTOMLEFT, 10, -10)
        end
    end

    self:SetupBundleDisplay()

    self:SetupPurchaseLabelDisplay()
    self:SetupEsoPlusDealLabelDisplay()

    ZO_MarketClasses_Shared_ApplyTextColorToLabelByState(control.title, self:IsFocused(), self.displayState)
end

function ZO_MarketProductBase:ShouldShowCallouts()
    local purchaseable = self.displayState == MARKET_PRODUCT_DISPLAY_STATE_NOT_PURCHASED
    local purchasedAndNew = self.productData:IsNew() and not (purchaseable or self:IsLimitedTimeProduct() or self:IsOnSale())
    return self:IsPromo() or not purchasedAndNew
end

function ZO_MarketProductBase:GetMarketProductListingsForHouseTemplate(houseTemplateId, displayGroup)
    return { GetActiveMarketProductListingsForHouseTemplate(houseTemplateId, displayGroup) }
end

function ZO_MarketProductBase:GetDefaultHouseTemplatePricingInfo()
    return ZO_MarketProduct_GetDefaultHousingTemplatePricingInfo(self:GetId(), function(...) return self:GetMarketProductListingsForHouseTemplate(...) end)
end

function ZO_MarketProductBase:SetupCalloutsDisplay()
    local hideCallouts = true

    -- setup the callouts for new, on sale, and LTO
    if self:ShouldShowCallouts() then
        local calloutUpdateHandler = nil
        if self:IsLimitedTimeProduct() then
            hideCallouts = false
            self:UpdateLTORemainingTimeCalloutText()
            calloutUpdateHandler = function() self:UpdateLTORemainingTimeCalloutText() end
        elseif self:IsOnSale() then
            hideCallouts = false
            local onSaleMarketProductId = self.defaultHouseTemplateMarketProductId or self:GetId()
            self:UpdateSaleRemainingTimeCalloutText(self.discountPercent, onSaleMarketProductId)
            if GetMarketProductSaleTimeLeftInSeconds(onSaleMarketProductId) > 0 then
                calloutUpdateHandler = function() self:UpdateSaleRemainingTimeCalloutText(self.discountPercent, onSaleMarketProductId) end
            end
        elseif self.productData:IsNew() then
            hideCallouts = false
            self.control.textCallout:SetText(GetString(SI_MARKET_TILE_CALLOUT_NEW))
            self.control.textCallout:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        end

        self.control.textCallout:SetHandler("OnUpdate", calloutUpdateHandler)
    end

    self.control.textCallout:SetHidden(hideCallouts)
end

do
    local TEXT_CALLOUT_BACKGROUND_ALPHA = 0.9
    function ZO_MarketProductBase:ApplyCalloutColor(textCalloutBackgroundColor, textCalloutTextColor)
        if textCalloutBackgroundColor then
            local r, g, b = textCalloutBackgroundColor:UnpackRGB()
            self.control.leftCalloutBackground:SetColor(r, g, b, TEXT_CALLOUT_BACKGROUND_ALPHA)
            self.control.rightCalloutBackground:SetColor(r, g, b, TEXT_CALLOUT_BACKGROUND_ALPHA)
            self.control.centerCalloutBackground:SetColor(r, g, b, TEXT_CALLOUT_BACKGROUND_ALPHA)
            self.control.textCallout:SetColor(textCalloutTextColor:UnpackRGB())
        end
    end
end

function ZO_MarketProductBase:SetupPricingDisplay()
    local control = self.control
    if self:HasCost() then
        -- layout the previous cost
        if self:IsOnSale() and not self:IsFree() then
            local formattedAmount = zo_strformat(SI_NUMBER_FORMAT, ZO_CommaDelimitNumber(self.cost))
            local strikethroughAmountString = zo_strikethroughTextFormat(formattedAmount)
            control.previousCost:SetText(strikethroughAmountString)
            control.previousCost:SetHidden(false)
        else
            control.previousCost:SetHidden(true)
        end

        -- layout the current cost
        if not self:IsFree() then
            local priceFormat = "%s %s"
            if self.hasMultiplePriceOptions then
                priceFormat = "%s+ %s"
            end

            local INHERIT_ICON_COLOR = true
            local CURRENCY_ICON_SIZE = "100%"
            local currencyIcon = ZO_Currency_GetPlatformFormattedCurrencyIcon(ZO_Currency_MarketCurrencyToUICurrency(self.currencyType), CURRENCY_ICON_SIZE, INHERIT_ICON_COLOR)
            local currencyString = string.format(priceFormat, zo_strformat(SI_NUMBER_FORMAT, ZO_CommaDelimitNumber(self.costAfterDiscount)), currencyIcon)
            control.cost:SetText(currencyString)
        else
            control.cost:SetText(GetString(SI_MARKET_FREE_LABEL))
        end

        ZO_MarketClasses_Shared_ApplyTextColorToLabelByState(control.cost, self:IsFocused(), self.displayState)
        control.cost:SetHidden(self:IsPromo())
    else
        control.cost:SetHidden(true)
        control.previousCost:SetHidden(true)
    end

    if self:HasEsoPlusCost() then
        control.esoPlusCost:SetHidden(false)

        if not self:IsFreeForEsoPlus() then
            local INHERIT_ICON_COLOR = true
            local CURRENCY_ICON_SIZE = "100%"
            local currencyIcon = ZO_Currency_GetPlatformFormattedCurrencyIcon(ZO_Currency_MarketCurrencyToUICurrency(self.currencyType), CURRENCY_ICON_SIZE, INHERIT_ICON_COLOR)

            -- the keyboard Crown Gem icon is purple, so we shouldn't try to recolor it with gold colors
            if self.currencyType == MKCT_CROWN_GEMS and not IsInGamepadPreferredMode() then
                local iconColor = self:CanBePurchased() and ZO_MARKET_SELECTED_COLOR or ZO_MARKET_PRODUCT_PURCHASED_COLOR
                currencyIcon = iconColor:Colorize(currencyIcon)
            end

            local currencyString = string.format("%s %s", zo_strformat(SI_NUMBER_FORMAT, ZO_CommaDelimitNumber(self.esoPlusCost)), currencyIcon)
            control.esoPlusCost:SetText(currencyString)
        else
            control.esoPlusCost:SetText(GetString(SI_MARKET_FREE_LABEL))
        end

        ZO_MarketClasses_Shared_ApplyEsoPlusColorToLabelByState(control.esoPlusCost, self:IsFocused(), self.displayState)
    else
        control.esoPlusCost:SetHidden(true)
    end
end

function ZO_MarketProductBase:SetupPurchaseLabelDisplay()
    local purchaseLabelControl = self.control.purchaseLabelControl
    local canBePurchased = self:CanBePurchased()
    if not canBePurchased then
        local purchasedString
        if self:IsPromo() then
            purchasedString = ""
        elseif self.displayState == MARKET_PRODUCT_DISPLAY_STATE_NOT_PURCHASED and self:IsHouseCollectible() then
            purchasedString = ""
        elseif self.displayState == MARKET_PRODUCT_DISPLAY_STATE_INELIGIBLE then
            purchasedString = GetString(SI_MARKET_PURCHASE_REQUIREMENT_INELIGIBLE_LABEL)
        else -- MARKET_PRODUCT_DISPLAY_STATE_PURCHASED
            if self.productData:GetMarketProductType() == MARKET_PRODUCT_TYPE_INSTANT_UNLOCK then
                local errorStringId = GetMarketProductCompleteErrorStringId(self:GetId())
                purchasedString = GetErrorString(errorStringId)
            else
                purchasedString = GetString(SI_MARKET_PURCHASED_LABEL)
            end
        end

        purchaseLabelControl:SetText(purchasedString)
        ZO_MarketClasses_Shared_ApplyTextColorToLabelByState(purchaseLabelControl, self:IsFocused(), self.displayState)

        self:AnchorPurchaseLabel()
    end

    purchaseLabelControl:SetHidden(canBePurchased)
end

function ZO_MarketProductBase:AnchorPurchaseLabel()
    self:AnchorLabelBetweenBundleIndicatorAndCost(self.control.purchaseLabelControl)
end

function ZO_MarketProductBase:AnchorLabelBetweenBundleIndicatorAndCost(label)
    -- anchor the purchase control to the bottom right of the tile
    -- if this is a bundle, account for the bundle indicators in the bottom right
    label:ClearAnchors()

    local control = self.control
    if self:IsBundle() then
        if self.productData:GetNumBundledProducts() > 1 then
            label:SetAnchor(BOTTOMRIGHT, control.bundledProductsItemsLabel, BOTTOMLEFT, -10, 0)
        else
            label:SetAnchor(BOTTOMRIGHT, control.numBundledProductsLabel, BOTTOMRIGHT, 0, -2)
        end
    else
        label:SetAnchor(BOTTOMRIGHT, control, BOTTOMRIGHT, -10, -10)
    end

    -- anchor the left side to the right-most cost label
    if self:HasEsoPlusCost() then
        label:SetAnchor(BOTTOMLEFT, control.esoPlusCost, BOTTOMRIGHT, 10, 0, ANCHOR_CONSTRAINS_X)
    elseif self:HasCost() then
        label:SetAnchor(BOTTOMLEFT, control.cost, BOTTOMRIGHT, 10, 0, ANCHOR_CONSTRAINS_X)
    else
        -- we shouldn't hit this case
        label:SetAnchor(BOTTOMLEFT, control, BOTTOMLEFT, 10, 0, ANCHOR_CONSTRAINS_X)
    end
end

function ZO_MarketProductBase:SetupEsoPlusDealLabelDisplay()
    local esoPlusDealLabelControl = self.control.esoPlusDealLabelControl
    local shouldShowDealLabel = self:CanBePurchased() and self:HasEsoPlusCost()
    if shouldShowDealLabel then
        local formattedIcon = self:GetEsoPlusIcon()
        local text
        if self:HasCost() then
            text = GetString(SI_MARKET_ESO_PLUS_DEAL_LABEL)
        else
            text = GetString(SI_MARKET_ESO_PLUS_EXCLUSIVE_LABEL)
        end
        local esoPlusDealString = string.format("%s%s", formattedIcon, text)
        esoPlusDealLabelControl:SetText(esoPlusDealString)
        ZO_MarketClasses_Shared_ApplyEsoPlusColorToLabelByState(esoPlusDealLabelControl, self:IsFocused(), self.displayState)

        self:AnchorEsoPlusDealLabel()
    end

    esoPlusDealLabelControl:SetHidden(not shouldShowDealLabel)
end

function ZO_MarketProductBase:AnchorEsoPlusDealLabel()
    self:AnchorLabelBetweenBundleIndicatorAndCost(self.control.esoPlusDealLabelControl)
end

function ZO_MarketProductBase:SetupBundleDisplay()
    local isBundle = self:IsBundle()
    if isBundle then
        local numBundledProducts = self.productData:GetNumBundledProducts()
        self.control.numBundledProductsLabel:SetText(numBundledProducts)
        -- hide the label if the result is 0 or 1 (which means either an empty bundle or what should be a single product...)
        local hideBundledProductsLabel = numBundledProducts <= 1
        self.control.numBundledProductsLabel:SetHidden(hideBundledProductsLabel)

        self:AnchorBundledProductsLabel()
    else
        self.control.numBundledProductsLabel:SetHidden(true)
    end

    self.control.bundleIndicator:SetHidden(not isBundle)
end

function ZO_MarketProductBase:AnchorBundledProductsLabel()
    -- optional override
end

function ZO_MarketProductBase:UpdateLTORemainingTimeCalloutText()
    local remainingTime = self.productData:GetLTOTimeLeftInSeconds()
    -- if there is no time left remaining then the MarketProduct is not limited time
    -- because when a limited time product reaches 0 it is removed from the store
    if remainingTime > 0 then
        if remainingTime >= ZO_ONE_DAY_IN_SECONDS then
            self.control.textCallout:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
            self.control.textCallout:SetText(zo_strformat(SI_TIME_DURATION_LEFT, ZO_FormatTime(remainingTime, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS)))
        else
            self.control.textCallout:SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
            self.control.textCallout:SetText(zo_strformat(SI_TIME_DURATION_LEFT, ZO_FormatTimeLargestTwo(remainingTime, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL)))
        end
    end
end

function ZO_MarketProductBase:UpdateSaleRemainingTimeCalloutText(discountPercent, marketProductId)
    local discountPercentText = zo_strformat(SI_MARKET_DISCOUNT_PRICE_PERCENT_FORMAT, discountPercent)
    local remainingTime = GetMarketProductSaleTimeLeftInSeconds(marketProductId)
    -- if there is no time left remaining then the MarketProduct is not limited time
    -- because when a limited time product reaches 0 it is removed from the store
    if remainingTime > 0 and remainingTime <= ZO_ONE_MONTH_IN_SECONDS then
        local remainingTimeText
        if remainingTime >= ZO_ONE_DAY_IN_SECONDS then
            self.control.textCallout:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
            remainingTimeText = ZO_FormatTime(remainingTime, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS)
        else
            self.control.textCallout:SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
            remainingTimeText = ZO_FormatTimeLargestTwo(remainingTime, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL)
        end
        local calloutText = string.format("%s %s", discountPercentText, remainingTimeText)
        self.control.textCallout:SetText(calloutText)
    else
        self.control.textCallout:SetText(discountPercentText)
    end
end

function ZO_MarketProductBase:Show(marketProductData)
    -- this is currently a safeguard for the announcement tiles which set their
    -- product data up ahead of time and don't pass in data on show
    if marketProductData then
        self.productData = marketProductData
    end

    self:UpdatingPricingInformation()

    self.displayState = self:GetMarketProductDisplayState()

    local name = self.productData:GetDisplayName()
    self:SetTitle(name)

    self:PerformLayout()

    self:LayoutCostAndText()

    self:LayoutBackground()

    self.control:SetHidden(false)
end

function ZO_MarketProductBase:LayoutBackground()
    local background = self:GetBackground()
    self.control.background:SetTexture(background)
    self.hasBackground = background ~= ZO_NO_TEXTURE_FILE
    self.control.background:SetHidden(not self.hasBackground)
end

function ZO_MarketProductBase:UpdatingPricingInformation()
    local currencyType, cost, costAfterDiscount, discountPercent, esoPlusCost = self:GetMarketProductPricingByPresentation()
    if self:IsHouseCollectible() then
        local houseCurrencyType, houseCost, houseCostAfterDiscount, houseDiscountPercent, houseEsoPlusCost, defaultHouseTemplateMarketProductId, hasMultiplePriceOptions = self:GetDefaultHouseTemplatePricingInfo()
        if houseCurrencyType ~= MKCT_NONE then
            currencyType = houseCurrencyType
            cost = houseCost
            costAfterDiscount = houseCostAfterDiscount
            discountPercent = houseDiscountPercent
            esoPlusCost = houseEsoPlusCost
            self.hasMultiplePriceOptions = hasMultiplePriceOptions
            self.defaultHouseTemplateMarketProductId = defaultHouseTemplateMarketProductId
        else
            self.hasMultiplePriceOptions = false
            self.defaultHouseTemplateMarketProductId = nil
        end
    else
        self.hasMultiplePriceOptions = false
        self.defaultHouseTemplateMarketProductId = nil
    end

    self.currencyType = currencyType
    self.cost = cost
    self.costAfterDiscount = costAfterDiscount
    self.discountPercent = discountPercent
    self.esoPlusCost = esoPlusCost
end

function ZO_MarketProductBase:HasCost()
    return self.cost ~= nil
end

function ZO_MarketProductBase:HasEsoPlusCost()
    return self.esoPlusCost ~= nil
end

function ZO_MarketProductBase:IsFree()
    return self:HasCost() and self.costAfterDiscount == 0 or false
end

function ZO_MarketProductBase:IsOnSale()
    return self.discountPercent > 0 and not self:IsPromo()
end

function ZO_MarketProductBase:IsFreeForEsoPlus()
    return self:HasEsoPlusCost() and self.esoPlusCost == 0 or false
end

function ZO_MarketProductBase:ClearPricingInformation()
    self.currencyType = MKCT_NONE
    self.cost = nil
    self.costAfterDiscount = nil
    self.discountPercent = 0
    self.esoPlusCost = nil
    self.hasMultiplePriceOptions = false
    self.defaultHouseTemplateMarketProductId = nil
end

function ZO_MarketProductBase:Reset()
    self.control:SetHidden(true)
    self.control.textCallout:SetHidden(true)
    -- Clear the background's texture so that it can be cleared at zero references
    self.control.background:SetTexture("")
    self.productData = nil
    self:ClearPricingInformation()
end

function ZO_MarketProductBase:Refresh()
    self:Show(self.productData)
end

function ZO_MarketProductBase:SetTitle(title)
    self.control.title:SetText(zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, title))
end

-- MarketProduct Preview functions

function ZO_MarketProductBase:GetMarketProductPreviewType()
    return self.productData:GetMarketProductPreviewType()
end

function ZO_MarketProductBase:HasPreview()
    --Houses are special because as far as C is concerned they aren't previewable, but Lua allows for a roundabout preview with jumping to the house
    return CanPreviewMarketProduct(self:GetId()) or self:GetMarketProductPreviewType() == ZO_MARKET_PREVIEW_TYPE_HOUSE
end

function ZO_MarketProductBase:GetNumPreviewVariations()
    return self.productData:GetNumPreviewVariations()
end

-- functions to be overridden

function ZO_MarketProductBase:IsFocused()
    -- optional overridde, default behavior
    return true
end

function ZO_MarketProductBase:PerformLayout()
    -- to be overridden
end

function ZO_MarketProductBase:GetBackground()
    -- to be overridden, default behavior
    return nil
end

function ZO_MarketProductBase:GetEsoPlusIcon()
    -- to be overridden, default behavior
    return nil
end

function ZO_MarketProduct_IsHouseCollectible(marketProductId)
    if GetMarketProductType(marketProductId) == MARKET_PRODUCT_TYPE_COLLECTIBLE then
        local collectibleType = select(4, GetMarketProductCollectibleInfo(marketProductId))
        if collectibleType == COLLECTIBLE_CATEGORY_TYPE_HOUSE then
            return true
        end
    end

    return false
end

-- global functions

function ZO_MarketProduct_GetDefaultHousingTemplatePricingInfo(marketProductId, getMarketProductListingsCallback)
    local houseCurrencyType = MKCT_NONE
    local houseCost = nil
    local houseCostAfterDiscount = nil
    local houseDiscountPercent = 0
    local houseEsoPlusCost = nil
    local defaultHouseTemplateMarketProductId = nil
    local hasMultiplePriceOptions = false
    if ZO_MarketProduct_IsHouseCollectible(marketProductId) then
        local marketProductHouseId = GetMarketProductHouseId(marketProductId)

        -- Iterate through all known house template defs and verify they have an equivalent market product.
        -- Only those with market products will be considered in determining the number of pricing options.
        local numHouseTemplates = GetNumHouseTemplatesForHouse(marketProductHouseId)
        local numEnabledTemplates = 0
        for index = 1, numHouseTemplates do
            local houseTemplateId = GetHouseTemplateIdByIndexForHouse(marketProductHouseId, index)
            local marketProductListings = getMarketProductListingsCallback(houseTemplateId, MARKET_DISPLAY_GROUP_CROWN_STORE)
            if #marketProductListings > 0 then
                numEnabledTemplates = numEnabledTemplates + 1
            end
        end

        hasMultiplePriceOptions = numEnabledTemplates > 1

        local defaultHouseTemplateId = GetDefaultHouseTemplateIdForHouse(marketProductHouseId)
        local defaultMarketProductListings = getMarketProductListingsCallback(defaultHouseTemplateId, MARKET_DISPLAY_GROUP_CROWN_STORE)
        -- There could be multiple listings per template, such as one for each currency type or for each category it should appear in,
        -- or just multiple market products for the same template
        local PRODUCT_LISTINGS_FOR_HOUSE_TEMPLATE_STRIDE = 2
        for i = 1, #defaultMarketProductListings, PRODUCT_LISTINGS_FOR_HOUSE_TEMPLATE_STRIDE do
            local houseTemplateMarketProductId = defaultMarketProductListings[i]
            local presentationIndex = defaultMarketProductListings[i + 1]

            local currencyType, cost, costAfterDiscount, discountPercent, esoPlusCost = GetMarketProductPricingByPresentation(houseTemplateMarketProductId, presentationIndex)

            if not houseCostAfterDiscount or costAfterDiscount < houseCostAfterDiscount then
                houseCurrencyType = currencyType
                houseCost = cost
                houseCostAfterDiscount = costAfterDiscount
                houseDiscountPercent = discountPercent
                houseEsoPlusCost = esoPlusCost
                defaultHouseTemplateMarketProductId = houseTemplateMarketProductId
            end
        end
    end

    return houseCurrencyType, houseCost, houseCostAfterDiscount, houseDiscountPercent, houseEsoPlusCost, defaultHouseTemplateMarketProductId, hasMultiplePriceOptions
end

--
--[[ XML Handlers ]]--
--

function ZO_MarketProductBase_OnInitialized(control)
    control.title = control:GetNamedChild("Title")
    control.background = control:GetNamedChild("Background")
    control.cost = control:GetNamedChild("Cost")
    control.previousCost = control:GetNamedChild("PreviousCost")
    control.esoPlusCost = control:GetNamedChild("EsoPlusCost")
    control.purchaseLabelControl = control:GetNamedChild("Purchased")
    control.esoPlusDealLabelControl = control:GetNamedChild("EsoPlusDeal")
    control.textCallout = control:GetNamedChild("TextCallout")
    control.textCalloutBackground = control.textCallout:GetNamedChild("Background")
    if control.textCalloutBackground then
        control.leftCalloutBackground = control.textCalloutBackground:GetNamedChild("Left")
        control.rightCalloutBackground = control.textCalloutBackground:GetNamedChild("Right")
        control.centerCalloutBackground = control.textCalloutBackground:GetNamedChild("Center")
    end
    control.numBundledProductsLabel = control:GetNamedChild("BundledProducts")
    control.bundledProductsItemsLabel = control:GetNamedChild("BundledProductsLabel")
    control.bundleIndicator = control:GetNamedChild("BundleIndicator")
end