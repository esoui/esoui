ZO_MARKET_PRODUCT_WIDTH = 302
ZO_MARKET_PRODUCT_COLUMN_PADDING = 10
ZO_MARKET_PRODUCT_BUNDLE_WIDTH = 2 * ZO_MARKET_PRODUCT_WIDTH + ZO_MARKET_PRODUCT_COLUMN_PADDING
ZO_MARKET_PRODUCT_HEIGHT = 200
ZO_MARKET_PRODUCT_INSET = 20

--account for the fade that we add to the sides of the callout
ZO_MARKET_PRODUCT_CALLOUT_X_OFFSET = 5

ZO_MARKET_DEFAULT_BACKGROUND_COLOR = ZO_ColorDef:New(1, 1, 1)
ZO_MARKET_MOUSE_OVER_BACKGROUND_COLOR = ZO_ColorDef:New(.8, .8, .8)
ZO_MARKET_PURCHASED_BACKGROUND_COLOR = ZO_ColorDef:New(.6, .6, .6)

local ICON_PADDING = 6 -- amount of x and y padding to give icons in frames

--
--[[ Keyboard MarketProduct ]]--
--

local KeyboardMarketProduct = ZO_MarketProductBase:Subclass()

function KeyboardMarketProduct:New(...)
    return ZO_MarketProductBase.New(self, ...)
end

function KeyboardMarketProduct:Initialize(controlId, controlTemplate, parent, iconPool, owner, name, ...)
    local control = CreateControlFromVirtual(name or controlTemplate, parent, controlTemplate, controlId)
    ZO_MarketProductBase.Initialize(self, control, owner, ...)
    self.iconPool = ZO_MetaPool:New(iconPool)
end

function KeyboardMarketProduct:LayoutBackground(background)
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

function KeyboardMarketProduct:LayoutCostAndText(description, cost, discountPercent, discountedCost, isNew)
    ZO_MarketProductBase.LayoutCostAndText(self, description, cost, discountPercent, discountedCost, isNew)

    self.cost:ClearAnchors()
    self.textCallout:ClearAnchors()

    local onSale = cost > discountedCost
    if onSale then
        self.cost:SetAnchor(BOTTOMLEFT, self.previousCost, BOTTOMRIGHT, 10)
        self.textCallout:SetAnchor(BOTTOMLEFT, self.previousCost, TOPLEFT, ZO_MARKET_PRODUCT_CALLOUT_X_OFFSET - 2, -7) -- x offset to account for strikethrough
    else
        self.cost:SetAnchor(BOTTOMLEFT, self.control, BOTTOMLEFT, 10, -10)
        self.textCallout:SetAnchor(BOTTOMLEFT, self.cost, TOPLEFT, ZO_MARKET_PRODUCT_CALLOUT_X_OFFSET, -7)
    end

    local textCalloutBackgroundColor
    local textCalloutTextColor
    if onSale then
        textCalloutBackgroundColor = ZO_MARKET_PRODUCT_ON_SALE_COLOR
        textCalloutTextColor = ZO_SELECTED_TEXT
    elseif isNew then
        textCalloutBackgroundColor = ZO_MARKET_PRODUCT_NEW_COLOR
        textCalloutTextColor = ZO_SELECTED_TEXT
    elseif self:GetTimeLeftInSeconds() > 0 then
        textCalloutBackgroundColor = ZO_BLACK
        textCalloutTextColor = ZO_MARKET_PRODUCT_ON_SALE_COLOR
    end

    if textCalloutBackgroundColor then
        self:SetCalloutColor(textCalloutBackgroundColor)
        self.textCallout:SetColor(textCalloutTextColor:UnpackRGB())
    end
end

function KeyboardMarketProduct:Purchase()
    PlaySound(SOUNDS.MARKET_PURCHASE_SELECTED)
    local expectedPurchaseResult = CouldPurchaseMarketProduct(self.marketProductId)
    if expectedPurchaseResult == MARKET_PURCHASE_RESULT_NOT_ENOUGH_VC then
        ZO_Dialogs_ShowDialog("MARKET_INSUFFICIENT_CROWNS_WITH_LINK", ZO_BUY_CROWNS_URL, ZO_BUY_CROWNS_FRONT_FACING_ADDRESS)
    else
        if expectedPurchaseResult == MARKET_PURCHASE_RESULT_NOT_ENOUGH_ROOM then
            ZO_Dialogs_ShowDialog("MARKET_INVENTORY_FULL", nil, { mainTextParams = { GetSpaceNeededToPurchaseMarketProduct(self.marketProductId) } })
        elseif expectedPurchaseResult == MARKET_PURCHASE_RESULT_ALREADY_UNLOCKED_BACKPACK_UPGRADES or expectedPurchaseResult == MARKET_PURCHASE_RESULT_ALREADY_UNLOCKED_BANK_UPGRADES then
            ZO_Dialogs_ShowDialog("MARKET_UNABLE_TO_PURCHASE", nil, { mainTextParams = { GetString("SI_MARKETPURCHASABLERESULT", expectedPurchaseResult) } })
        elseif self:HasSubscriptionUnlockedAttachments() then
            local name = self:GetMarketProductInfo()
            ZO_Dialogs_ShowDialog("MARKET_PARTS_UNLOCKED", {marketProductId = self.marketProductId}, {titleParams = {name}, mainTextParams = {ZO_SELECTED_TEXT:Colorize(name)}})
        elseif self:HasBeenPartiallyPurchased() then
            ZO_Dialogs_ShowDialog("MARKET_BUNDLE_PARTS_OWNED", {marketProductId = self.marketProductId})
        else
            ZO_Dialogs_ShowDialog("MARKET_PURCHASE_CONFIRMATION", {marketProductId = self.marketProductId})
        end
    end
end

function KeyboardMarketProduct:Reset()
    ZO_MarketProductBase.Reset(self)
    self.iconPool:ReleaseAllObjects()
end

function KeyboardMarketProduct:Refresh()
    -- need to release the icons before we refresh, because Show() will grab a new icon
    self.iconPool:ReleaseAllObjects()
    ZO_MarketProductBase.Refresh(self)
end

function KeyboardMarketProduct:InitializeMarketProductIcon(attachmentIndex, attachmentType, purchased)
    local marketProductIcon = self.iconPool:AcquireObject()
    marketProductIcon:Show(self, attachmentIndex, attachmentType, purchased)
    return marketProductIcon
end

-- MarketProduct mouse functions

function KeyboardMarketProduct:OnMouseEnter(activeIcon)
    self.activeMarketProductIcon = activeIcon
    self:SetHighlightHidden(self:IsPurchaseLocked())

    if self.hasBackground and not self:IsPurchaseLocked() then
        self.background:SetColor(ZO_MARKET_MOUSE_OVER_BACKGROUND_COLOR:UnpackRGB())
    end

    self:DisplayTooltip(activeIcon)
end

function KeyboardMarketProduct:OnMouseExit()
    self.activeMarketProductIcon = nil
    self:SetHighlightHidden(true)

    if self.hasBackground and not self:IsPurchaseLocked() then
        self.background:SetColor(ZO_MARKET_DEFAULT_BACKGROUND_COLOR:UnpackRGB())
    end

    self:ClearTooltip()
end

function KeyboardMarketProduct:OnClicked(button)
    if(button == MOUSE_BUTTON_INDEX_LEFT) then
        if self.owner:IsReadyToPreview() then
            self:Preview()
        end
    elseif(button == MOUSE_BUTTON_INDEX_RIGHT) then
        ClearMenu()

        if not self:IsPurchaseLocked() then
            local function PurchaseCallback()
                self:Purchase()
            end
            if self:IsBundle() then
                AddMenuItem(GetString(SI_MARKET_ACTION_PURCHASE_BUNDLE), PurchaseCallback)
            else
                AddMenuItem(GetString(SI_MARKET_ACTION_PURCHASE), PurchaseCallback)
            end
        end

        if self:HasPreview() then
            if self:IsPreviewingActiveCollectible() then
                AddMenuItem(GetString(SI_MARKET_ACTION_END_PREVIEW), function() self:EndPreview() end)
            elseif IsCharacterPreviewingAvailable() then
                AddMenuItem(GetString(SI_MARKET_ACTION_PREVIEW), function() self:Preview() end)
            end
        end

        ShowMenu(self.control)
    end
end

function KeyboardMarketProduct:OnDoubleClicked(button)
    if(button == MOUSE_BUTTON_INDEX_LEFT) then
        if not self:IsPurchaseLocked() then
            self:Purchase()
        end
    end
end

function KeyboardMarketProduct:DisplayTooltip(activeIcon)
    if activeIcon then
        if activeIcon.attachmentType == MARKET_ATTACHMENT_COLLECTIBLE then
            local collectibleId = GetMarketProductCollectibleInfo(self:GetId(), activeIcon.attachmentIndex)
            InitializeTooltip(ItemTooltip, activeIcon.control, RIGHT, -15, 0, LEFT)
            ItemTooltip:SetCollectible(collectibleId, DONT_SHOW_COLLECTIBLE_NICKNAME, DONT_SHOW_COLLECTIBLE_HINT)
        elseif activeIcon.attachmentType == MARKET_ATTACHMENT_ITEM then
            InitializeTooltip(ItemTooltip, activeIcon.control, RIGHT, -15, 0, LEFT)
            ItemTooltip:SetMarketItem(self:GetId(), activeIcon.attachmentIndex)
        end
    end
end

function KeyboardMarketProduct:ClearTooltip()
    ClearTooltip(ItemTooltip)
end

function KeyboardMarketProduct:GetBackground()
    return GetMarketProductKeyboardBackground(self:GetId())
end

--
--[[ MarketProductBundle ]]--
--

ZO_MarketProductBundle = KeyboardMarketProduct:Subclass()

function ZO_MarketProductBundle:New(...)
    return KeyboardMarketProduct.New(self, ...)
end

function ZO_MarketProductBundle:Initialize(controlId, parent, iconPool, owner)
    KeyboardMarketProduct.Initialize(self, controlId, "ZO_MarketProductBundle", parent, iconPool, owner)
    self.description = self.control:GetNamedChild("Description")
end

function ZO_MarketProductBundle:PerformLayout(description, cost, discountedCost, discountPercent, icon, background, isNew, isFeatured)
    local iconControls = self:CreateIconControlTable(self:IsPurchaseLocked())
    self:LayoutIcons(iconControls)

    self:LayoutDescription(description)
end

local BUNDLE_ICON_SIZE = 64
function ZO_MarketProductBundle:CreateIconControlTable(purchased)
    local iconControls = {}
    for i = 1, self:GetNumAttachedItems() do
        local marketProductIcon = self:InitializeMarketProductIcon(i, MARKET_ATTACHMENT_ITEM, purchased)
        marketProductIcon:SetDimensions(BUNDLE_ICON_SIZE)
        marketProductIcon:SetFrameHidden(false)

        table.insert(iconControls, marketProductIcon:GetControl())
    end

    for i = 1, self:GetNumAttachedCollectibles() do
        local marketProductIcon = self:InitializeMarketProductIcon(i, MARKET_ATTACHMENT_COLLECTIBLE, purchased)
        marketProductIcon:SetDimensions(BUNDLE_ICON_SIZE)
        marketProductIcon:SetFrameHidden(false)

        table.insert(iconControls, marketProductIcon:GetControl())
    end

    return iconControls
end

local BUNDLE_ROW_PADDING = 5
local BUNDLE_COLUMN_PADDING = 5
local NUM_BUNDLE_ROWS = 2
function ZO_MarketProductBundle:LayoutIcons(iconControls)
    local numControls = #iconControls
    local topRowControls
    local bottomRowControls
    if numControls == 2 then
        topRowControls = iconControls
        bottomRowControls = {}
    else
        topRowControls = {}
        bottomRowControls = {}

        local numTopRow = zo_ceil(#iconControls / NUM_BUNDLE_ROWS)
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
            control:SetAnchor(TOPRIGHT, nil, nil, -20, 20)
            previousRowControl = control
        else
            control:SetAnchor(TOPRIGHT, previousControl, TOPLEFT, -BUNDLE_COLUMN_PADDING, 0)
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
                control:SetAnchor(TOPRIGHT, previousRowControl, BOTTOM, 0, BUNDLE_ROW_PADDING)
            else
                control:SetAnchor(TOPRIGHT, previousRowControl, BOTTOMRIGHT, 0, BUNDLE_ROW_PADDING)
            end
            firstInRow = false
        else
            control:SetAnchor(TOPRIGHT, previousControl, TOPLEFT, -BUNDLE_COLUMN_PADDING, 0)
        end

        previousControl = control
    end
end

function ZO_MarketProductBundle:LayoutDescription(description)
    self.description:SetText(zo_strformat(description))
    ZO_MarketClasses_Shared_ApplyTextColorToLabel(self.description, not self:IsPurchaseLocked(), ZO_NORMAL_TEXT, ZO_DEFAULT_TEXT)
    self.description:SetHidden(true)
end

function ZO_MarketProductBundle:IsPreviewingActiveCollectible()
    if self:IsActiveIconCollectible() then
        return self:IsPreviewingCollectible(self.activeMarketProductIcon.attachmentIndex)
    else
        return false
    end
end

function ZO_MarketProductBundle:HasPreview()
    return self:IsActiveIconCollectible() and self:CanPreviewCollectible(self.activeMarketProductIcon:GetAttachmentIndex())
end

function ZO_MarketProductBundle:Preview()
    if self:IsActiveIconCollectible() then
        self:PreviewCollectible(self.activeMarketProductIcon.attachmentIndex)
    end
end

function ZO_MarketProductBundle:IsBundle()
    return true
end

function ZO_MarketProductBundle:OnMouseEnter(activeIcon)
    KeyboardMarketProduct.OnMouseEnter(self, activeIcon)
    self.description:SetHidden(false)
end

function ZO_MarketProductBundle:OnMouseExit()
    KeyboardMarketProduct.OnMouseExit(self)
    self.description:SetHidden(true)
end


--
--[[ MarketProductIndividual ]]--
--

ZO_MarketProductIndividual = KeyboardMarketProduct:Subclass()

function ZO_MarketProductIndividual:New(...)
    return KeyboardMarketProduct.New(self, ...)
end

function ZO_MarketProductIndividual:Initialize(controlId, parent, iconPool, owner)
    KeyboardMarketProduct.Initialize(self, controlId, "ZO_MarketProduct", parent, iconPool, owner)
end

local SINGLE_ICON_SIZE = 64
function ZO_MarketProductIndividual:PerformLayout(description, cost, discountedCost, discountPercent, icon, background, isNew, isFeatured)
    --safeguard against empty MarketProducts
    if self:GetNumAttachments() == 1 then
        local attachmentType = self:GetNumAttachedCollectibles() == 1 and MARKET_ATTACHMENT_COLLECTIBLE or MARKET_ATTACHMENT_ITEM
        local marketProductIcon = self:InitializeMarketProductIcon(1, attachmentType, self:IsPurchaseLocked())
        marketProductIcon:SetDimensions(SINGLE_ICON_SIZE)

        --only show the icon if we have no background or it's an item that has a stack
        local showIcon = background == ZO_NO_TEXTURE_FILE or marketProductIcon.hasStack
        marketProductIcon:SetHidden(not showIcon)

        -- only show the frame when the icon is being showed on top of a background
        local showFrame = background ~= ZO_NO_TEXTURE_FILE and showIcon
        marketProductIcon:SetFrameHidden(not showFrame)

        self.productIcon = marketProductIcon

        local iconControl = marketProductIcon:GetControl()
        iconControl:ClearAnchors()
        iconControl:SetAnchor(TOPRIGHT, nil, nil, -20, 20)
    end
end

function ZO_MarketProductIndividual:IsPreviewingActiveCollectible()
    return self:IsPreviewingCollectible(1)
end

function ZO_MarketProductIndividual:HasPreview()
    return self:GetNumAttachedCollectibles() == 1 and self:CanPreviewCollectible(1)
end

function ZO_MarketProductIndividual:Preview()
    self:PreviewCollectible(1)
    MARKET:SetCanBeginPreview(false, GetFrameTimeSeconds())
end

function ZO_MarketProductIndividual:IsBundle()
    return false
end

function ZO_MarketProductIndividual:Reset()
    KeyboardMarketProduct.Reset(self)
    self.productIcon = nil
end

function ZO_MarketProductIndividual:OnMouseEnter(activeIcon)
    KeyboardMarketProduct.OnMouseEnter(self, self.productIcon)
end

function ZO_MarketProductIndividual:DisplayTooltip(activeIcon)
    InitializeTooltip(ItemTooltip, self.control, RIGHT, -15, 0, LEFT)
    local productId = self:GetId()
    if activeIcon then
        if activeIcon.attachmentType == MARKET_ATTACHMENT_COLLECTIBLE then
            local collectibleId = GetMarketProductCollectibleInfo(productId, 1)
            ItemTooltip:SetCollectible(collectibleId, DONT_SHOW_COLLECTIBLE_NICKNAME, DONT_SHOW_COLLECTIBLE_HINT)
        elseif activeIcon.attachmentType == MARKET_ATTACHMENT_ITEM then
            ItemTooltip:SetMarketItem(productId, 1)
        end
    else
        ItemTooltip:SetMarketProductInstantUnlock(productId)
    end
end

--
--[[ MarketProductIcon ]]--
--

MARKET_ATTACHMENT_NONE = 0
MARKET_ATTACHMENT_ITEM = 1
MARKET_ATTACHMENT_COLLECTIBLE = 2

ZO_MarketProductIcon = ZO_Object:Subclass()

function ZO_MarketProductIcon:New(...)
    local marketProductIcon = ZO_Object.New(self)
    marketProductIcon:Initialize(...)
    return marketProductIcon
end

local SURFACE_SELECTED_INDEX = 2
function ZO_MarketProductIcon:Initialize(controlId, parent)
    local TEMPLATE_NAME = "ZO_MarketProductIcon"
    local control = CreateControlFromVirtual(TEMPLATE_NAME, parent, TEMPLATE_NAME, controlId)
    control.marketProductIcon = self
    self.control = control
    self.icon = control:GetNamedChild("Icon")
    self.frame = control:GetNamedChild("Frame")
    self.frame:SetSurfaceHidden(SURFACE_SELECTED_INDEX, true)
    self.stackCount = self.icon:GetNamedChild("StackCount")
    self.hasStack = false
end

function ZO_MarketProductIcon:Show(marketProduct, attachmentIndex, attachmentType, bundlePurchased)
    self.control:SetParent(marketProduct.control)
    self.marketProduct = marketProduct
    self.attachmentIndex = attachmentIndex
    self.attachmentType = attachmentType

    self.hasStack = false

    local marketProductId = marketProduct:GetId()
    if attachmentType == MARKET_ATTACHMENT_ITEM then
        local itemId, iconFile, name, itemQuality, requiredLevel, itemCount = GetMarketProductItemInfo(marketProductId, attachmentIndex)
        self.icon:SetTexture(iconFile)

        if itemCount > 1 then
            self.hasStack = true
            self.stackCount:SetText(itemCount)
        end
    elseif attachmentType == MARKET_ATTACHMENT_COLLECTIBLE then
        local collectibleId, iconFile = GetMarketProductCollectibleInfo(marketProductId, attachmentIndex)
        -- even if a bundle isn't marked as purchased, a collectible may still be unlocked/purchased unlike items
        if not bundlePurchased then
            bundlePurchased = IsCollectibleOwnedByDefId(collectibleId)
        end
        self.icon:SetTexture(iconFile)
    end

    local iconSaturation = marketProduct:GetBackgroundSaturation(bundlePurchased)
    self.icon:SetDesaturation(iconSaturation)

    self.control:SetHidden(false)
    self.stackCount:SetHidden(not self.hasStack)
end

function ZO_MarketProductIcon:GetControl()
    return self.control
end

function ZO_MarketProductIcon:GetMarketProduct()
    return self.marketProduct
end

function ZO_MarketProductIcon:GetAttachmentIndex()
    return self.attachmentIndex
end

function ZO_MarketProductIcon:Reset()
    self.control:SetHidden(true)
end

function ZO_MarketProductIcon:SetDimensions(length)
    self.control:SetDimensions(length, length)
    local paddedLength = length - ICON_PADDING
    self.icon:SetDimensions(paddedLength, paddedLength)
end

function ZO_MarketProductIcon:SetIcon(icon)
    self.icon:SetTexture(icon)
end

function ZO_MarketProductIcon:IsCollectible()
    return self.attachmentType == MARKET_ATTACHMENT_COLLECTIBLE
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

-- ZO_MarketProductIcon mouse functions

local DONT_SHOW_COLLECTIBLE_NICKNAME = false
local DONT_SHOW_COLLECTIBLE_HINT = false
function ZO_MarketProductIcon:OnMouseEnter()
    self.marketProduct:OnMouseEnter(self)
end

function ZO_MarketProductIcon:OnMouseExit()
    self.marketProduct:OnMouseExit()
end

function ZO_MarketProductIcon:OnClicked(button)
    if(button == MOUSE_BUTTON_INDEX_LEFT) then
        self.marketProduct:OnClicked(button)
    elseif(button == MOUSE_BUTTON_INDEX_RIGHT) then
        ClearMenu()
        local marketProduct = self.marketProduct

        if not marketProduct:IsPurchaseLocked() then
            if marketProduct:IsBundle() then
                AddMenuItem(GetString(SI_MARKET_ACTION_PURCHASE_BUNDLE), function() marketProduct:Purchase() end)
            else
                AddMenuItem(GetString(SI_MARKET_ACTION_PURCHASE), function() marketProduct:Purchase() end)
            end
        end

        if self.attachmentType == MARKET_ATTACHMENT_COLLECTIBLE then
            if marketProduct:IsPreviewingCollectible(self.attachmentIndex) then
                AddMenuItem(GetString(SI_MARKET_ACTION_END_PREVIEW), function() marketProduct:EndPreview() end)
            elseif marketProduct:CanPreviewCollectible(self.attachmentIndex) and IsCharacterPreviewingAvailable() then
                AddMenuItem(GetString(SI_MARKET_ACTION_PREVIEW), function() marketProduct:PreviewCollectible(self.attachmentIndex) end)
            end
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

function ZO_MarketProductIcon_OnMouseEnter(control)
    local marketProductIcon = control.marketProductIcon
    marketProductIcon:OnMouseEnter()
    MARKET:MarketProductSelected(marketProductIcon:GetMarketProduct())
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
