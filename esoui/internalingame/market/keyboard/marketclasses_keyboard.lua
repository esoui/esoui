ZO_MARKET_PRODUCT_WIDTH = 302
ZO_MARKET_PRODUCT_COLUMN_PADDING = 10
ZO_MARKET_PRODUCT_BUNDLE_WIDTH = 2 * ZO_MARKET_PRODUCT_WIDTH + ZO_MARKET_PRODUCT_COLUMN_PADDING
ZO_MARKET_PRODUCT_HEIGHT = 200
ZO_MARKET_PRODUCT_INSET = 20

ZO_MARKET_DEFAULT_BACKGROUND_COLOR = ZO_ColorDef:New(1, 1, 1)
ZO_MARKET_MOUSE_OVER_BACKGROUND_COLOR = ZO_ColorDef:New(.8, .8, .8)
ZO_MARKET_PURCHASED_BACKGROUND_COLOR = ZO_ColorDef:New(.6, .6, .6)

--
--[[ Keyboard MarketProduct ]]--
--

local MarketProduct_Keyboard = ZO_MarketProductBase:Subclass()

function MarketProduct_Keyboard:New(...)
    return ZO_MarketProductBase.New(self, ...)
end

do
    local TITLE_FONTS =
    {
        {
            font = "ZoFontHeader3",
            lineLimit = 3,
        },
        {
            font = "ZoFontHeader2",
            lineLimit = 4,
        },
        {
            font = "ZoFontHeader",
            lineLimit = 4,
        },
        {
            font = "ZoFontWinH5",
            lineLimit = 5,
        },
    }

    function MarketProduct_Keyboard:Initialize(controlId, controlTemplate, parent, iconPool, owner, name, ...)
        local control = CreateControlFromVirtual(name or controlTemplate, parent, controlTemplate, controlId)
        ZO_MarketProductBase.Initialize(self, control, owner, ...)

        self.giftButton = control:GetNamedChild("Gift")
        self.iconPool = ZO_MetaPool:New(iconPool)
        self.activeMarketProductIcon = nil
        self:SetTextCalloutYOffset(-7)
        ZO_FontAdjustingWrapLabel_OnInitialized(self.title, TITLE_FONTS, TEXT_WRAP_MODE_ELLIPSIS)
    end
end

function MarketProduct_Keyboard:LayoutBackground(background)
    local isAvailable = not self:IsPurchaseLocked()
    local backgroundSaturation = self:GetBackgroundSaturation(self:IsPurchaseLocked())
    local backgroundColor = isAvailable and ZO_MARKET_DEFAULT_BACKGROUND_COLOR or ZO_MARKET_PURCHASED_BACKGROUND_COLOR
    local hasBackground = background ~= ZO_NO_TEXTURE_FILE
    if hasBackground then
        self.background:SetDesaturation(backgroundSaturation)
        self.background:SetColor(backgroundColor:UnpackRGB())
        self.background:SetTexture(background)
    end

    self.background:SetHidden(not hasBackground)

    self.hasBackground = hasBackground
end

function MarketProduct_Keyboard:SetupCalloutsDisplay(discountPercent, isNew)
    ZO_MarketProductBase.SetupCalloutsDisplay(self, discountPercent, isNew)

    local textCalloutBackgroundColor
    local textCalloutTextColor
    if self:IsLimitedTimeProduct() then
        textCalloutBackgroundColor = ZO_BLACK
        textCalloutTextColor = ZO_MARKET_PRODUCT_ON_SALE_COLOR
    elseif self.onSale then
        textCalloutBackgroundColor = ZO_MARKET_PRODUCT_ON_SALE_COLOR
        textCalloutTextColor = ZO_SELECTED_TEXT
    elseif self.isNew then
        textCalloutBackgroundColor = ZO_MARKET_PRODUCT_NEW_COLOR
        textCalloutTextColor = ZO_SELECTED_TEXT
    end

    self:ApplyCalloutColor(textCalloutBackgroundColor, textCalloutTextColor)
end

function MarketProduct_Keyboard:Purchase()
    MARKET:PurchaseMarketProduct(self.marketProductId, self:GetPresentationIndex())
end

function MarketProduct_Keyboard:Gift()
    MARKET:GiftMarketProduct(self.marketProductId, self:GetPresentationIndex())
end

function MarketProduct_Keyboard:Reset()
    ZO_MarketProductBase.Reset(self)
    self.iconPool:ReleaseAllObjects()
    self.parentMarketProductId = nil
    self.giftButton:SetHidden(true)
end

function MarketProduct_Keyboard:Refresh()
    -- need to release the icons before we refresh, because Show() will grab a new icon
    self.iconPool:ReleaseAllObjects()
    self.activeMarketProductIcon = nil

    -- make sure to refresh the mouse over state for the tile as well
    local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()
    local isMousedOver = false
    if mouseOverControl and mouseOverControl == self.control then
        isMousedOver = true
    end

    local ANIMATE_INSTANTLY = true
    if isMousedOver then
        self:OnMouseExit(ANIMATE_INSTANTLY)
    end

    ZO_MarketProductBase.Refresh(self)

    if isMousedOver then
        self:OnMouseEnter(ANIMATE_INSTANTLY)
    end
end

function MarketProduct_Keyboard:RefreshAsChild()
    -- need to release the icons before we refresh, because Show() will grab a new icon
    self.iconPool:ReleaseAllObjects()
    self.activeMarketProductIcon = nil
    local productId = self:GetId()
    if productId > 0 then
        -- make sure to refresh the mouse over state for the tile as well
        local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()
        local isMousedOver = false
        if mouseOverControl and mouseOverControl == self.control then
            isMousedOver = true
        end

        local ANIMATE_INSTANTLY = true
        if isMousedOver then
            self:OnMouseExit(ANIMATE_INSTANTLY)
        end

        self:ShowAsChild(productId, self.parentMarketProductId)

        if isMousedOver then
            self:OnMouseEnter(ANIMATE_INSTANTLY)
        end
    end
end

function MarketProduct_Keyboard:InitializeMarketProductIcon(marketProductId, purchased)
    local marketProductIcon = self.iconPool:AcquireObject()
    marketProductIcon:Show(self, marketProductId, purchased)
    return marketProductIcon
end

function MarketProduct_Keyboard:EndPreview()
    self.owner:EndCurrentPreview()
end

function MarketProduct_Keyboard:HasActiveIcon()
    return self.activeMarketProductIcon ~= nil
end

-- MarketProduct mouse functions
function MarketProduct_Keyboard:OnIconMouseEnter(activeIcon)
    self.activeMarketProductIcon = activeIcon
    -- call the normal on mouse enter because entering the icon
    -- means the mouse has already left the MarketProduct_Keyboard
    self:OnMouseEnter()
end

do
    local g_fadeInAnimationProvider = ZO_ReversibleAnimationProvider:New("ZO_KeyboardMarketProductFadeInAnimation")
    local g_fadeOutAnimationProvider = ZO_ReversibleAnimationProvider:New("ZO_KeyboardMarketProductFadeOutAnimation")

    function MarketProduct_Keyboard:OnMouseEnter(animateInstantly)
        if not self:IsPurchaseLocked() then
            self:SetHighlightHidden(false)
        end

        if self.hasBackground and not self:IsPurchaseLocked() then
            self.background:SetColor(ZO_MARKET_MOUSE_OVER_BACKGROUND_COLOR:UnpackRGB())
        end

        local marketProductId
        if self:HasActiveIcon() then
            marketProductId = self.activeMarketProductIcon:GetMarketProductId()
        else
            marketProductId = self.marketProductId
        end

        self:DisplayTooltip(self.control, marketProductId)

        if self:IsGiftable() then
            if not self.purchaseLabelControl:IsHidden() then
                g_fadeOutAnimationProvider:PlayForward(self.purchaseLabelControl, animateInstantly)
            end

            if not self.bundledProductsItemsLabel:IsHidden() then
                g_fadeOutAnimationProvider:PlayForward(self.bundledProductsItemsLabel, animateInstantly)
            end

            if not self.numBundledProductsLabel:IsHidden() then
                g_fadeOutAnimationProvider:PlayForward(self.numBundledProductsLabel, animateInstantly)
            end

            self.giftButton:SetHidden(false)
            g_fadeInAnimationProvider:PlayForward(self.giftButton, animateInstantly)
        end
    end

    function MarketProduct_Keyboard:OnMouseExit(animateInstantly)
        self.activeMarketProductIcon = nil
        if not self:IsPurchaseLocked() then
            self:SetHighlightHidden(true)
        end

        if self.hasBackground and not self:IsPurchaseLocked() then
            self.background:SetColor(ZO_MARKET_DEFAULT_BACKGROUND_COLOR:UnpackRGB())
        end

        self:ClearTooltip()

        if self:IsGiftable() then
            local shouldShowPurchaseLabel = not self:CanBePurchased()
            if shouldShowPurchaseLabel then
                g_fadeOutAnimationProvider:PlayBackward(self.purchaseLabelControl, animateInstantly)
            end

            if self:IsBundle() then
                g_fadeOutAnimationProvider:PlayBackward(self.bundledProductsItemsLabel, animateInstantly)
            end

            local hideBundledProductsLabel = not self:IsBundle() or GetMarketProductNumBundledProducts(self.marketProductId) <= 1
            if not hideBundledProductsLabel then
                g_fadeOutAnimationProvider:PlayBackward(self.numBundledProductsLabel, animateInstantly)
            end

            g_fadeInAnimationProvider:PlayBackward(self.giftButton, animateInstantly)
        end
    end
end

function MarketProduct_Keyboard:OnClicked(button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        -- We don't use CanPreviewMarketProductPreviewType here because we don't want clicking on bundles to actually preview, lest we wouldn't be able to double click
        if self.owner:IsReadyToPreview() then
            self:Preview()
        end
    elseif button == MOUSE_BUTTON_INDEX_RIGHT then
        ClearMenu()

        if self:HasValidPresentationIndex() and self:CanBePurchased() then
            local function PurchaseCallback() self:Purchase() end
            if self:IsBundle() then
                AddMenuItem(GetString(SI_MARKET_ACTION_PURCHASE_BUNDLE), PurchaseCallback)
            else
                AddMenuItem(GetString(SI_MARKET_ACTION_PURCHASE), PurchaseCallback)
            end
        end

        if self:HasValidPresentationIndex() and self:IsGiftable() then
            local function GiftCallback() self:Gift() end
            if self:IsBundle() then
                AddMenuItem(GetString(SI_MARKET_GIFT_BUNDLE_KEYBIND_TEXT), GiftCallback)
            else
                AddMenuItem(GetString(SI_MARKET_GIFT_KEYBIND_TEXT), GiftCallback)
            end
        end

        local previewType = self.owner.GetMarketProductPreviewType(self)
        local canPreview = self.owner:CanPreviewMarketProductPreviewType(previewType)
        if canPreview then
            local function PreviewFunction() self:Preview() end
            if previewType == ZO_MARKET_PREVIEW_TYPE_BUNDLE or previewType == ZO_MARKET_PREVIEW_TYPE_BUNDLE_HIDES_CHILDREN then
                AddMenuItem(GetString(SI_MARKET_BUNDLE_DETAILS_KEYBIND_TEXT), PreviewFunction)
            else -- ZO_MARKET_PREVIEW_TYPE_CROWN_CRATE, ZO_MARKET_PREVIEW_TYPE_PREVIEWABLE
                AddMenuItem(GetString(SI_MARKET_ACTION_PREVIEW), PreviewFunction)
            end
        elseif self:IsActivelyPreviewing() then
            AddMenuItem(GetString(SI_MARKET_ACTION_END_PREVIEW), function() self:EndPreview() end)
        end

        ShowMenu(self.control)
    end
end

function MarketProduct_Keyboard:OnDoubleClicked(button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        if self:CanBePurchased() and self:HasValidPresentationIndex() then
            self:Purchase()
        end
    end
end

function MarketProduct_Keyboard:DisplayTooltip(anchorControl, productId)
    InitializeTooltip(ItemTooltip, anchorControl, RIGHT, -15, 0, LEFT)
    ItemTooltip:SetMarketProduct(productId)
end

function MarketProduct_Keyboard:ClearTooltip()
    ClearTooltip(ItemTooltip)
end

function MarketProduct_Keyboard:GetBackground()
    return GetMarketProductKeyboardBackground(self:GetId())
end

function MarketProduct_Keyboard:IsActivelyPreviewing()
    -- To Be Overridden
end

function MarketProduct_Keyboard:GetPurchaseState()
    if self.parentMarketProductId then
        local parentPurchaseState = GetMarketProductPurchaseState(self.parentMarketProductId)
        if parentPurchaseState == MARKET_PRODUCT_PURCHASE_STATE_PURCHASED then
            return parentPurchaseState
        end
    end

    return ZO_MarketProductBase.GetPurchaseState(self)
end

function MarketProduct_Keyboard:ShowAsChild(marketProductId, parentMarketProductId)
    self.parentMarketProductId = parentMarketProductId
    self:Show(marketProductId, ZO_INVALID_PRESENTATION_INDEX)

    local allCollectiblesOwned = self:AreAllCollectiblesUnlocked()

    self.purchaseLabelControl:SetHidden(not allCollectiblesOwned)

    if allCollectiblesOwned then
        self.purchaseLabelControl:SetText(GetString("SI_COLLECTIBLEUNLOCKSTATE", COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED))
    end

    -- hide all the price info
    self.cost:SetHidden(true)
    self.previousCost:SetHidden(true)
    self.textCallout:SetHidden(true)
end

local ROW_PADDING = 5
local COLUMN_PADDING = 5
local NUM_ROWS = 2
function MarketProduct_Keyboard:LayoutIcons(iconControls)
    local numControls = #iconControls
    local topRowControls
    local bottomRowControls
    if numControls == 2 then
        topRowControls = iconControls
        bottomRowControls = {}
    else
        topRowControls = {}
        bottomRowControls = {}

        local numTopRow = zo_ceil(#iconControls / NUM_ROWS)
        for index, control in ipairs(iconControls) do
            if index <= numTopRow then
                table.insert(topRowControls, control)
            else
                table.insert(bottomRowControls, control)
            end
        end
    end

    local previousControl
    local previousRowControl
    for index, control in ipairs(topRowControls) do
        control:ClearAnchors()

        if index == 1 then
            control:SetAnchor(TOPRIGHT, nil, nil, -10, 20)
            previousRowControl = control
        else
            control:SetAnchor(TOPRIGHT, previousControl, TOPLEFT, -COLUMN_PADDING, 0)
        end

        previousControl = control
    end

    previousControl = nil
    for index, control in ipairs(bottomRowControls) do
        control:ClearAnchors()

        if index == 1 then
            -- offset the bottom row if we have fewer items in the bottom row
            local rowIsSmaller = #topRowControls - #bottomRowControls >= 1
            if rowIsSmaller then
                control:SetAnchor(TOPRIGHT, previousRowControl, BOTTOM, 0, ROW_PADDING)
            else
                control:SetAnchor(TOPRIGHT, previousRowControl, BOTTOMRIGHT, 0, ROW_PADDING)
            end
        else
            control:SetAnchor(TOPRIGHT, previousControl, TOPLEFT, -COLUMN_PADDING, 0)
        end

        previousControl = control
    end
end

--
--[[ ZO_MarketProductBundle ]]--
--

ZO_MarketProductBundle = MarketProduct_Keyboard:Subclass()

function ZO_MarketProductBundle:New(...)
    return MarketProduct_Keyboard.New(self, ...)
end

function ZO_MarketProductBundle:Initialize(controlId, parent, iconPool, owner)
    MarketProduct_Keyboard.Initialize(self, controlId, "ZO_MarketProductBundle_Keyboard", parent, iconPool, owner)
end

function ZO_MarketProductBundle:PerformLayout(background)
    local iconControls = self:CreateChildIconControlTable(self:IsPurchaseLocked())
    self:LayoutIcons(iconControls)
end

local MAX_VISIBLE_ICONS = 8
function ZO_MarketProductBundle:CreateChildIconControlTable(purchased)
    local iconControls = {}
    local numChildren = self:GetNumChildren()

    self.variations = {}

    if not self:GetHidesChildProducts() and numChildren <= MAX_VISIBLE_ICONS then
        for childIndex = 1, numChildren do
            local childMarketProductId = self:GetChildMarketProductId(childIndex)
            local marketProductIcon = self:InitializeMarketProductIcon(childMarketProductId, purchased)
            marketProductIcon:SetFrameHidden(false)

            table.insert(iconControls, marketProductIcon:GetControl())
            self.variations[childMarketProductId] = 1
        end

        -- Sort the child tiles alphabetically
        table.sort(iconControls, function(a,b)
                                        return a.marketProductIcon:GetDisplayName() < b.marketProductIcon:GetDisplayName()
                                    end)
    end

    return iconControls
end

function ZO_MarketProductBundle:IsActivelyPreviewing()
    if self:HasActiveIcon() then
        return IsPreviewingMarketProduct(self.activeMarketProductIcon:GetMarketProductId())
    end

    return false
end

function ZO_MarketProductBundle:HasPreview()
    if self:HasActiveIcon() then
        return CanPreviewMarketProduct(self.activeMarketProductIcon:GetMarketProductId())
    end
end

function ZO_MarketProductBundle:Preview(icon)
    local activeIcon = icon or self.activeMarketProductIcon
    -- make sure we have a valid icon to preview
    if activeIcon then
        local attachmentId = activeIcon:GetMarketProductId()
        if CanPreviewMarketProduct(attachmentId) then
            self.owner:PreviewMarketProduct(attachmentId)
        end
    else
        if self:GetHidesChildProducts() then
            self.owner:ShowBundleContentsAsList(self)
        else
            self.owner:ShowBundleContents(self)
        end
    end
end

--
--[[ MarketProductIndividual ]]--
--

ZO_MarketProductIndividual = MarketProduct_Keyboard:Subclass()

function ZO_MarketProductIndividual:New(...)
    return MarketProduct_Keyboard.New(self, ...)
end

function ZO_MarketProductIndividual:Initialize(controlId, parent, iconPool, owner)
    MarketProduct_Keyboard.Initialize(self, controlId, "ZO_MarketProduct_Keyboard", parent, iconPool, owner)
end

function ZO_MarketProductIndividual:PerformLayout(background)
    local iconControls = {}
    local productType = self:GetProductType()
    if productType ~= MARKET_PRODUCT_TYPE_NONE then
        local marketProductIcon = self:InitializeMarketProductIcon(self.marketProductId, self:IsPurchaseLocked())

        --only show the icon if we have no background or it's an item that has a stack
        local showIcon = background == ZO_NO_TEXTURE_FILE or marketProductIcon.hasStack
        marketProductIcon:SetHidden(not showIcon)

        -- only show the frame when the icon is being shown on top of a background
        local showFrame = background ~= ZO_NO_TEXTURE_FILE and showIcon
        marketProductIcon:SetFrameHidden(not showFrame)

        local iconControl = marketProductIcon:GetControl()
        iconControls = { iconControl }
    end

    self:LayoutIcons(iconControls)
end

function ZO_MarketProductIndividual:IsActivelyPreviewing()
    return IsPreviewingMarketProduct(self.marketProductId)
end

function ZO_MarketProductIndividual:Preview()
    local previewType = self.owner.GetMarketProductPreviewType(self)
    if previewType == ZO_MARKET_PREVIEW_TYPE_BUNDLE then
        self.owner:ShowBundleContents(self)
    elseif previewType == ZO_MARKET_PREVIEW_TYPE_CROWN_CRATE then
        self.owner:ShowCrownCrateContents(self)
    elseif previewType == ZO_MARKET_PREVIEW_TYPE_BUNDLE_HIDES_CHILDREN then
        self.owner:ShowBundleContentsAsList(self)
    elseif previewType == ZO_MARKET_PREVIEW_TYPE_HOUSE then
        self.owner:ShowHousePreviewDialog(self)
    else -- ZO_MARKET_PREVIEW_TYPE_PREVIEWABLE
        self.owner:PreviewMarketProduct(self:GetId())
    end
end

function ZO_MarketProductIndividual:Reset()
    MarketProduct_Keyboard.Reset(self)
    self.productIcon = nil
end

--
--[[ MarketProductIcon ]]--
--

ZO_MarketProductIcon = ZO_Object:Subclass()

function ZO_MarketProductIcon:New(...)
    local marketProductIcon = ZO_Object.New(self)
    marketProductIcon:Initialize(...)
    return marketProductIcon
end

local SURFACE_SELECTED_INDEX = 2
function ZO_MarketProductIcon:Initialize(controlId, parent)
    local TEMPLATE_NAME = "ZO_MarketProductIconTemplate_Keyboard"
    local control = CreateControlFromVirtual(TEMPLATE_NAME, parent, TEMPLATE_NAME, controlId)
    control.marketProductIcon = self
    self.control = control
    self.icon = control:GetNamedChild("Icon")
    self.frame = control:GetNamedChild("Frame")
    self.frame:SetSurfaceHidden(SURFACE_SELECTED_INDEX, true)
    self.stackCount = self.icon:GetNamedChild("StackCount")
    self.hasStack = false
end

function ZO_MarketProductIcon:Show(marketProduct, marketProductId, showAsPurchased)
    self.control:SetParent(marketProduct.control)
    self.parentMarketProduct = marketProduct
    self.marketProductId = marketProductId

    self.hasStack = false
    self.displayName = GetMarketProductDisplayName(marketProductId)

    local productType = GetMarketProductType(marketProductId)
    if productType == MARKET_PRODUCT_TYPE_COLLECTIBLE then
        local collectibleId = GetMarketProductCollectibleId(marketProductId)
        -- even if a bundle isn't marked as purchased, a collectible may still be unlocked/purchased unlike items
        if not showAsPurchased then
            showAsPurchased = IsCollectibleOwnedByDefId(collectibleId)
        end
    elseif productType == MARKET_PRODUCT_TYPE_BUNDLE then
        if not showAsPurchased then
            showAsPurchased = CouldAcquireMarketProduct(marketProductId) == MARKET_PURCHASE_RESULT_COLLECTIBLE_ALREADY
        end
    end

    local stackCount = GetMarketProductStackCount(marketProductId)
    if stackCount > 1 then
        self.hasStack = true
        self.stackCount:SetText(stackCount)
    end

    local iconFile = GetMarketProductIcon(marketProductId)
    self.icon:SetTexture(iconFile)

    local iconSaturation = marketProduct:GetBackgroundSaturation(showAsPurchased)
    self.icon:SetDesaturation(iconSaturation)

    self.control:SetHidden(false)
    self.stackCount:SetHidden(not self.hasStack)
end

function ZO_MarketProductIcon:GetControl()
    return self.control
end

function ZO_MarketProductIcon:GetParentMarketProduct()
    return self.parentMarketProduct
end

function ZO_MarketProductIcon:GetMarketProductId()
    return self.marketProductId
end

function ZO_MarketProductIcon:Reset()
    self.control:SetHidden(true)
end

function ZO_MarketProductIcon:SetActive(isActive)
    self.frame:SetSurfaceHidden(SURFACE_SELECTED_INDEX, not isActive)
end

function ZO_MarketProductIcon:SetFrameHidden(isHidden)
    self.frame:SetHidden(isHidden)
end

function ZO_MarketProductIcon:SetHidden(isHidden)
    self.control:SetHidden(isHidden)
end

function ZO_MarketProductIcon:GetDisplayName()
    return self.displayName
end

-- ZO_MarketProductIcon mouse functions

function ZO_MarketProductIcon:OnMouseEnter()
    self.parentMarketProduct:OnIconMouseEnter(self)
end

function ZO_MarketProductIcon:OnMouseExit()
    self.parentMarketProduct:OnMouseExit()
end

function ZO_MarketProductIcon:OnClicked(button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        self.parentMarketProduct:OnClicked(button)
    elseif button == MOUSE_BUTTON_INDEX_RIGHT then
        ClearMenu()
        local marketProduct = self.parentMarketProduct

        if marketProduct:HasValidPresentationIndex() and marketProduct:CanBePurchased() then
            local function PurchaseCallback() marketProduct:Purchase() end
            if marketProduct:IsBundle() then
                AddMenuItem(GetString(SI_MARKET_ACTION_PURCHASE_BUNDLE), PurchaseCallback)
            else
                AddMenuItem(GetString(SI_MARKET_ACTION_PURCHASE), PurchaseCallback)
            end
        end

        if marketProduct:HasValidPresentationIndex() and marketProduct:IsGiftable() then
            local function GiftCallback() marketProduct:Gift() end
            if marketProduct:IsBundle() then
                AddMenuItem(GetString(SI_MARKET_GIFT_BUNDLE_KEYBIND_TEXT), GiftCallback)
            else
                AddMenuItem(GetString(SI_MARKET_GIFT_KEYBIND_TEXT), GiftCallback)
            end
        end

        if IsPreviewingMarketProduct(self.marketProductId) then
            AddMenuItem(GetString(SI_MARKET_ACTION_END_PREVIEW), function() marketProduct:EndPreview() end)
        elseif CanPreviewMarketProduct(self.marketProductId) and IsCharacterPreviewingAvailable() then
            AddMenuItem(GetString(SI_MARKET_ACTION_PREVIEW), function() marketProduct:Preview(self) end)
        end

        ShowMenu(self.control)
    end
end

--
--[[ XML Handlers ]]--
--

function ZO_MarketProduct_OnMouseEnter(control)
    local marketProduct = control.marketProduct
    marketProduct:OnMouseEnter()
    MARKET:MarketProductSelected(marketProduct)
end

function ZO_MarketProduct_OnMouseExit(control)
    local marketProduct = control.marketProduct
    marketProduct:OnMouseExit()
    MARKET:MarketProductSelected(nil)
end

function ZO_MarketProductGiftButton_OnMouseEnter(control)
    ZO_MarketProduct_OnMouseEnter(control)
    WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
end

function ZO_MarketProductGiftButton_OnMouseExit(control)
    ZO_MarketProduct_OnMouseExit(control)
end

function ZO_KeyboardMarketProduct_OnGiftClicked(control)
    local marketProduct = control.marketProduct
    marketProduct:Gift()
end

function ZO_MarketProductIcon_OnMouseEnter(control)
    local marketProductIcon = control.marketProductIcon
    marketProductIcon:OnMouseEnter()
    MARKET:MarketProductSelected(marketProductIcon:GetParentMarketProduct())
end

function ZO_MarketProductIcon_OnMouseExit(control)
    local marketProductIcon = control.marketProductIcon
    marketProductIcon:OnMouseExit()
    MARKET:MarketProductSelected(nil)
end

do
    local TEXTURE_WIDTH = 256
    local TEXTURE_HEIGHT = 256

    local FRAME_WIDTH = 64
    local FRAME_HEIGHT = 64

    local FRAME_SLICE_WIDTH = 64
    local FRAME_SLICE_HEIGHT = 64

    local FRAME_PADDING_X = (FRAME_SLICE_WIDTH - FRAME_WIDTH)
    local FRAME_PADDING_Y = (FRAME_SLICE_HEIGHT - FRAME_HEIGHT)

    local FRAME_WIDTH_TEX_COORD = FRAME_WIDTH / TEXTURE_WIDTH
    local FRAME_HEIGHT_TEX_COORD = FRAME_HEIGHT / TEXTURE_HEIGHT

    local FRAME_PADDING_X_TEX_COORD = FRAME_PADDING_X / TEXTURE_WIDTH
    local FRAME_PADDING_Y_TEX_COORD = FRAME_PADDING_Y / TEXTURE_HEIGHT

    local FRAME_START_TEXCOORD_X = 0.0 + FRAME_PADDING_X_TEX_COORD * .5
    local FRAME_START_TEXCOORD_Y = 0.0 + FRAME_PADDING_Y_TEX_COORD * .5

    local FRAME_NUM_COLS = 4
    local FRAME_NUM_ROWS = 2

    local SURFACE_FRAME_INDEX = 3
    local function PickRandomFrame(self)
        local col = zo_random(FRAME_NUM_COLS)
        local row = zo_random(FRAME_NUM_ROWS)

        local left = FRAME_START_TEXCOORD_X + (col - 1) * (FRAME_WIDTH_TEX_COORD + FRAME_PADDING_X_TEX_COORD)
        local right = left + FRAME_WIDTH_TEX_COORD 

        local top = FRAME_START_TEXCOORD_Y + (row - 1) * (FRAME_HEIGHT_TEX_COORD + FRAME_PADDING_Y_TEX_COORD)
        local bottom = top + FRAME_HEIGHT_TEX_COORD
        self:SetTextureCoords(SURFACE_FRAME_INDEX, left, right, top, bottom)
    end

    function ZO_MarketProductIcon_StyleFrame_OnInitialized(self)
        PickRandomFrame(self)
    end
end
