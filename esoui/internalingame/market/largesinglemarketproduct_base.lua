ZO_LARGE_SINGLE_MARKET_PRODUCT_WIDTH = 407
ZO_LARGE_SINGLE_MARKET_PRODUCT_HEIGHT = 270

ZO_LARGE_SINGLE_MARKET_PRODUCT_CONTENT_TOP_INSET_Y = 11
ZO_LARGE_SINGLE_MARKET_PRODUCT_CONTENT_X_INSET = 25
ZO_LARGE_SINGLE_MARKET_PRODUCT_CONTENT_BOTTOM_INSET_Y = -20

--account for the fade that we add to the sides of the callout
ZO_LARGE_SINGLE_MARKET_PRODUCT_CALLOUT_X_OFFSET = 5

--
--[[ ZO_LargeSingleMarketProduct_Base ]]--
--

ZO_LargeSingleMarketProduct_Base = ZO_MarketProductBase:Subclass()

function ZO_LargeSingleMarketProduct_Base:New(...)
    return ZO_MarketProductBase.New(self, ...)
end

function ZO_LargeSingleMarketProduct_Base:Initialize(...)
    ZO_MarketProductBase.Initialize(self, ...)
end

function ZO_LargeSingleMarketProduct_Base:InitializeControls(control)
    ZO_MarketProductBase.InitializeControls(self, control)
    self.normalBorder = self.control:GetNamedChild("HighlightNormal")
    self:SetTextCalloutYOffset(4)
end

do
    -- tile backgrounds are 512x512
    local TEXTURE_WIDTH_COORD = ZO_LARGE_SINGLE_MARKET_PRODUCT_WIDTH / 512
    local TEXTURE_HEIGHT_COORD = ZO_LARGE_SINGLE_MARKET_PRODUCT_HEIGHT / 512

    function ZO_LargeSingleMarketProduct_Base:LayoutBackground(background)
        self.background:SetTexture(background)
        self.background:SetTextureCoords(0, TEXTURE_WIDTH_COORD, 0, TEXTURE_HEIGHT_COORD)
        self.background:SetHidden(background == ZO_NO_TEXTURE_FILE)
    end
end

function ZO_LargeSingleMarketProduct_Base:PerformLayout(description, icon, background, isNew, isFeatured)
    self.description = description
end

-- Used for explicity show/hide without re-laying out the data via :Show
function ZO_LargeSingleMarketProduct_Base:SetHidden(hidden)
    self.control:SetHidden(hidden)
end

function ZO_LargeSingleMarketProduct_Base:GetBackground()
    return GetMarketProductGamepadBackground(self.marketProductId)
end

function ZO_LargeSingleMarketProduct_Base:SetTitle(title)
    local formattedTitle = zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, title)
    local stackCount = self:GetStackCount()
    if stackCount > 1 then
        formattedTitle = zo_strformat(SI_TOOLTIP_ITEM_NAME_WITH_QUANTITY, formattedTitle, stackCount)
    end

    self.title:SetText(formattedTitle)
end

do
    local NO_CATEGORY_NAME = nil
    local NO_NICKNAME = nil
    local IS_PURCHASEABLE = true
    local BLANK_HINT = ""
    local HIDE_VISUAL_LAYER_INFO = false
    local NO_COOLDOWN = nil
    local HIDE_BLOCK_REASON = false
    function ZO_LargeSingleMarketProduct_Base:Show(...)
        ZO_MarketProductBase.Show(self, ...)
        self:UpdateProductStyle()

        local productType = self:GetProductType()
        if productType == MARKET_PRODUCT_TYPE_COLLECTIBLE then
            local collectibleId, _, name, type, description, owned, isPlaceholder = GetMarketProductCollectibleInfo(self:GetId())
            self.tooltipLayoutArgs = { collectibleId, NO_CATEGORY_NAME, name, NO_NICKNAME, IS_PURCHASEABLE, description, BLANK_HINT, isPlaceholder, HIDE_VISUAL_LAYER_INFO, NO_COOLDOWN, HIDE_BLOCK_REASON}
        elseif productType == MARKET_PRODUCT_TYPE_ITEM then
            self.itemLink = GetMarketProductItemLink(self:GetId())
        end
    end
end

function ZO_LargeSingleMarketProduct_Base:SetIsFocused(isFocused)
    if self.isFocused ~= isFocused then
        self.isFocused = isFocused
        self:UpdateProductStyle()
    end
end

function ZO_LargeSingleMarketProduct_Base:Reset()
    ZO_MarketProductBase.Reset(self)
    self.itemLink = nil
    self.layoutArgs = nil
end

function ZO_LargeSingleMarketProduct_Base:LayoutTooltip(tooltip)
    local productType = self:GetProductType()
    if productType == MARKET_PRODUCT_TYPE_COLLECTIBLE then
        GAMEPAD_TOOLTIPS:LayoutCollectible(tooltip, unpack(self.tooltipLayoutArgs))
    elseif productType == MARKET_PRODUCT_TYPE_ITEM then
        local stackCount = self:GetStackCount()
        GAMEPAD_TOOLTIPS:LayoutItemWithStackCountSimple(tooltip, self.itemLink, stackCount)
    else
        GAMEPAD_TOOLTIPS:LayoutMarketProduct(tooltip, self:GetId())
    end
end

-- Update Product style is called during show, product refresh, and on selection changed.
-- Effectively Dims, Brightens and Desaturates products according to focus and product state
function ZO_LargeSingleMarketProduct_Base:UpdateProductStyle()
    local isFocused = self.isFocused
    local isPurchaseLocked = self:IsPurchaseLocked()
    local focusedState = isFocused and MARKET_PRODUCT_FOCUS_STATE_FOCUSED or MARKET_PRODUCT_FOCUS_STATE_UNFOCUSED
    local purchaseState = self.purchaseState

    ZO_MarketClasses_Shared_ApplyTextColorToLabelByState(self.title, isFocused, purchaseState)

    if isPurchaseLocked or self.isFree then
        ZO_MarketClasses_Shared_ApplyTextColorToLabelByState(self.purchaseLabelControl, isFocused, purchaseState)
        self.normalBorder:SetEdgeColor(ZO_MARKET_PRODUCT_PURCHASED_COLOR:UnpackRGB())
    else
        ZO_MarketClasses_Shared_ApplyTextColorToLabelByState(self.cost, isFocused, purchaseState)
        self.normalBorder:SetEdgeColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGB())
    end

    local textCalloutBackgroundColor
    local textCalloutTextColor
    if self:IsLimitedTimeProduct() then
        textCalloutBackgroundColor = ZO_BLACK
        textCalloutTextColor = isFocused and ZO_MARKET_PRODUCT_ON_SALE_COLOR or ZO_MARKET_PRODUCT_ON_SALE_DIMMED_COLOR
    elseif self.onSale then
        textCalloutBackgroundColor = isFocused and ZO_MARKET_PRODUCT_ON_SALE_COLOR or ZO_MARKET_PRODUCT_ON_SALE_DIMMED_COLOR
        textCalloutTextColor = isFocused and ZO_MARKET_PRODUCT_BACKGROUND_BRIGHTNESS_COLOR or ZO_MARKET_DIMMED_COLOR
    elseif self.isNew then
        textCalloutBackgroundColor = isFocused and ZO_MARKET_PRODUCT_NEW_COLOR or ZO_MARKET_PRODUCT_NEW_DIMMED_COLOR
        textCalloutTextColor = isFocused and ZO_MARKET_PRODUCT_BACKGROUND_BRIGHTNESS_COLOR or ZO_MARKET_DIMMED_COLOR
    end

    if textCalloutBackgroundColor then
        self:SetCalloutColor(textCalloutBackgroundColor)
        self.textCallout:SetColor(textCalloutTextColor:UnpackRGB())
    end

    local backgroundColor = isFocused and ZO_MARKET_PRODUCT_BACKGROUND_BRIGHTNESS_COLOR or ZO_MARKET_DIMMED_COLOR
    self.background:SetColor(backgroundColor:UnpackRGB())
    self.background:SetDesaturation(self:GetBackgroundSaturation(isPurchaseLocked))

    local previousCostColor = isFocused and ZO_DEFAULT_TEXT or ZO_DISABLED_TEXT
    self.previousCost:SetColor(previousCostColor:UnpackRGB())
    self.previousCostStrikethrough:SetColor(previousCostColor:UnpackRGB())
end