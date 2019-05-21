ZO_LARGE_SINGLE_MARKET_PRODUCT_WIDTH = 407
ZO_LARGE_SINGLE_MARKET_PRODUCT_HEIGHT = 270

ZO_LARGE_SINGLE_MARKET_PRODUCT_CONTENT_TOP_INSET_Y = 11
ZO_LARGE_SINGLE_MARKET_PRODUCT_CONTENT_INSET_X = 25
ZO_LARGE_SINGLE_MARKET_PRODUCT_CONTENT_BOTTOM_INSET_Y = -20

ZO_MARKET_PRODUCT_PURCHASED_DESATURATION = 1
ZO_MARKET_PRODUCT_NOT_PURCHASED_DESATURATION = 0

--
--[[ ZO_LargeSingleMarketProduct_Base ]]--
--

ZO_LargeSingleMarketProduct_Base = ZO_MarketProductBase:Subclass()

function ZO_LargeSingleMarketProduct_Base:New(...)
    return ZO_MarketProductBase.New(self, ...)
end

function ZO_LargeSingleMarketProduct_Base:Initialize(...)
    ZO_MarketProductBase.Initialize(self, ...)
    self:SetTextCalloutYOffset(4)
end

-- Used for explicity show/hide without re-laying out the data via :Show
function ZO_LargeSingleMarketProduct_Base:SetHidden(hidden)
    self.control:SetHidden(hidden)
end

-- override of ZO_MarketProductBase:GetBackground()
function ZO_LargeSingleMarketProduct_Base:GetBackground()
    return GetMarketProductGamepadBackground(self:GetId())
end

function ZO_LargeSingleMarketProduct_Base:SetTitle(title)
    local formattedTitle
    local stackCount = self:GetStackCount()
    if stackCount > 1 then
        formattedTitle = zo_strformat(SI_TOOLTIP_ITEM_NAME_WITH_QUANTITY, title, stackCount)
    else
        formattedTitle = zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, title)
    end

    self.control.title:SetText(formattedTitle)
end

function ZO_LargeSingleMarketProduct_Base:Show(...)
    ZO_MarketProductBase.Show(self, ...)
    self:UpdateProductStyle()
end

function ZO_LargeSingleMarketProduct_Base:SetIsFocused(isFocused)
    if self.isFocused ~= isFocused then
        self.isFocused = isFocused
        self:UpdateProductStyle()
    end
end

-- override of ZO_MarketProductBase:IsFocused()
function ZO_LargeSingleMarketProduct_Base:IsFocused()
    return self.isFocused
end

function ZO_LargeSingleMarketProduct_Base:Reset()
    ZO_MarketProductBase.Reset(self)
end

function ZO_LargeSingleMarketProduct_Base:LayoutTooltip(tooltip)
    GAMEPAD_TOOLTIPS:LayoutMarketProductListing(tooltip, self:GetId(), self:GetPresentationIndex())
end

-- Update Product style is called during show, product refresh, and on selection changed.
-- Effectively Dims, Brightens and Desaturates products according to focus and product state
function ZO_LargeSingleMarketProduct_Base:UpdateProductStyle()
    local control = self.control
    local isFocused = self:IsFocused()
    local isPurchaseLocked = self:IsPurchaseLocked()
    local displayState = self.displayState

    ZO_MarketClasses_Shared_ApplyTextColorToLabelByState(control.title, isFocused, displayState)

    -- only update the purchased label if we are showing it (which should be if we are purchase locked)
    if isPurchaseLocked then
        ZO_MarketClasses_Shared_ApplyTextColorToLabelByState(control.purchaseLabelControl, isFocused, displayState)
    elseif self:HasEsoPlusCost() then
        ZO_MarketClasses_Shared_ApplyEsoPlusColorToLabelByState(control.esoPlusDealLabelControl, isFocused, displayState)
    end

    ZO_MarketClasses_Shared_ApplyTextColorToLabelByState(control.cost, isFocused, displayState)

    ZO_MarketClasses_Shared_ApplyEsoPlusColorToLabelByState(control.esoPlusCost, isFocused, displayState)

    local textCalloutBackgroundColor
    local textCalloutTextColor
    if self:IsLimitedTimeProduct() then
        textCalloutBackgroundColor = ZO_BLACK
        textCalloutTextColor = isFocused and ZO_MARKET_PRODUCT_ON_SALE_COLOR or ZO_MARKET_PRODUCT_ON_SALE_DIMMED_COLOR
    elseif self:IsOnSale() then
        textCalloutBackgroundColor = isFocused and ZO_MARKET_PRODUCT_ON_SALE_COLOR or ZO_MARKET_PRODUCT_ON_SALE_DIMMED_COLOR
        textCalloutTextColor = isFocused and ZO_MARKET_PRODUCT_BACKGROUND_BRIGHTNESS_COLOR or ZO_MARKET_DIMMED_COLOR
    elseif self.productData:IsNew() then
        textCalloutBackgroundColor = isFocused and ZO_MARKET_PRODUCT_NEW_COLOR or ZO_MARKET_PRODUCT_NEW_DIMMED_COLOR
        textCalloutTextColor = isFocused and ZO_MARKET_PRODUCT_BACKGROUND_BRIGHTNESS_COLOR or ZO_MARKET_DIMMED_COLOR
    end

    self:ApplyCalloutColor(textCalloutBackgroundColor, textCalloutTextColor)

    local backgroundColor = isFocused and ZO_MARKET_PRODUCT_BACKGROUND_BRIGHTNESS_COLOR or ZO_MARKET_DIMMED_COLOR
    control.background:SetColor(backgroundColor:UnpackRGB())
    control.background:SetDesaturation(self:GetBackgroundDesaturation(isPurchaseLocked))

    local previousCostColor = isFocused and ZO_DEFAULT_TEXT or ZO_DISABLED_TEXT
    control.previousCost:SetColor(previousCostColor:UnpackRGB())
end