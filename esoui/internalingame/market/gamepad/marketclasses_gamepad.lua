ZO_GAMEPAD_MARKET_BUNDLE_PRODUCT_WIDTH = 620
ZO_GAMEPAD_MARKET_BUNDLE_PRODUCT_HEIGHT = 270
ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCT_WIDTH = 407
ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCT_HEIGHT = 270
ZO_GAMEPAD_MARKET_PRODUCT_TEMPLATE = "ZO_Gamepad_MarketProductTemplate"
ZO_GAMEPAD_MARKET_PRODUCT_BUNDLE_ATTACHMENT_TEMPLATE = "ZO_Gamepad_MarketProductBundleAttachmentTemplate"
ZO_GAMEPAD_MARKET_PRODUCT_BUNDLE_ITEM_ATTACHMENT_TEMPLATE = "ZO_Gamepad_MarketProductBundleItemAttachmentTemplate"
ZO_GAMEPAD_MARKET_PRODUCT_BUNDLE_COLLECTIBLE_ATTACHMENT_TEMPLATE = "ZO_Gamepad_MarketProductBundleCollectibleAttachmentTemplate"
ZO_GAMEPAD_MARKET_BLANK_TILE_TEMPLATE = "ZO_Gamepad_MarketBlankTileTemplate"

ZO_GAMEPAD_MARKET_PRODUCT_RENDER_SIZE_STANDARD = 0
ZO_GAMEPAD_MARKET_PRODUCT_RENDER_SIZE_WIDE = 1

local SINGLE_ITEM_COUNT = 1

--
--[[ Gamepad Market Product ]]--
--

ZO_GamepadMarketProduct = ZO_LargeSingleMarketProduct_Base:Subclass()

function ZO_GamepadMarketProduct:New(...)
    return ZO_LargeSingleMarketProduct_Base.New(self, ...)
end

function ZO_GamepadMarketProduct:Initialize(controlId, parent, owner, controlName)
    local controlTemplate = self:GetTemplate()
    local control = CreateControlFromVirtual(controlName or controlTemplate, parent, controlTemplate, controlId)
    ZO_LargeSingleMarketProduct_Base.Initialize(self, control, owner)

    self.renderSize = ZO_GAMEPAD_MARKET_PRODUCT_RENDER_SIZE_STANDARD
end

function ZO_GamepadMarketProduct:InitializeControls(control)
    ZO_LargeSingleMarketProduct_Base.InitializeControls(self, control)
    self.focusData =
    {
        control = self.control,
        highlight = self.control:GetNamedChild("Highlight"),
        marketProduct = self,
        isBlank = self:IsBlank()
    }
end

function ZO_GamepadMarketProduct:GetTemplate()
    return ZO_GAMEPAD_MARKET_PRODUCT_TEMPLATE
end

do
    -- wide tiles are 1024 x 512
    local BUNDLE_TEXTURE_WIDTH_COORD = ZO_GAMEPAD_MARKET_BUNDLE_PRODUCT_WIDTH / 1024
    local BUNDLE_TEXTURE_HEIGHT_COORD = ZO_GAMEPAD_MARKET_BUNDLE_PRODUCT_HEIGHT / 512
    
    -- single tiles are 512 x 512
    local INDIVIDUAL_TEXTURE_WIDTH_COORD = ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCT_WIDTH / 512
    local INDIVIDUAL_TEXTURE_HEIGHT_COORD = ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCT_HEIGHT / 512

    function ZO_GamepadMarketProduct:LayoutBackground(background)
        self.background:SetTexture(background)
        
        local coordRight, coordBottom
        if self.renderSize == ZO_GAMEPAD_MARKET_PRODUCT_RENDER_SIZE_STANDARD then
            coordRight = INDIVIDUAL_TEXTURE_WIDTH_COORD
            coordBottom = INDIVIDUAL_TEXTURE_HEIGHT_COORD
        elseif self.renderSize == ZO_GAMEPAD_MARKET_PRODUCT_RENDER_SIZE_WIDE then
            coordRight = BUNDLE_TEXTURE_WIDTH_COORD
            coordBottom = BUNDLE_TEXTURE_HEIGHT_COORD
        end
        
        self.background:SetTextureCoords(0, coordRight, 0, coordBottom)
        self.background:SetHidden(background == ZO_NO_TEXTURE_FILE)
    end
end

function ZO_GamepadMarketProduct:GetFocusData()
    return self.focusData
end

function ZO_GamepadMarketProduct:HasPreview()
    if not self:IsBundle() then -- Can't preview bundles from top level in gamepad version
        return self:GetNumAttachedCollectibles() == 1 and self:CanPreviewCollectible(1)
    else
        return false
    end
end

function ZO_GamepadMarketProduct:Preview()
     if not self:IsBundle() then -- Can't preview bundles from top level in gamepad version
        self:PreviewCollectible(1)
    end
end

function ZO_GamepadMarketProduct:SetListIndex(listIndex)
    self.listIndex = listIndex
end

function ZO_GamepadMarketProduct:GetListIndex()
    return self.listIndex
end

-- Changing the render size switches the background being used for the tile
-- This allows us to change backgrounds without re-calling Show()
function ZO_GamepadMarketProduct:SetRenderSize(renderSize)
    if renderSize ~= self.renderSize then
        self.renderSize = renderSize
        self:LayoutBackground(self:GetBackground())
    end
end

-- Used for cycling through preview items in the preview screen
function ZO_GamepadMarketProduct:SetPreviewIndex(previewIndex)
    self.previewIndex = previewIndex
end

function ZO_GamepadMarketProduct:GetPreviewIndex()
    return self.previewIndex
end

function ZO_GamepadMarketProduct:GetProductForSell()
    return self
end

function ZO_GamepadMarketProduct:GetBackground()
    local productId = self:GetId()
    if self.renderSize == ZO_GAMEPAD_MARKET_PRODUCT_RENDER_SIZE_STANDARD then
        return GetMarketProductGamepadBackground(productId)
    else
        return GetMarketProductGamepadWideBackground(productId)
    end
end

--
--[[ Gamepad Market Product Bundle Attachment ]]--
--

ZO_GamepadMarketProductBundleAttachment = ZO_GamepadMarketProduct:Subclass()

function ZO_GamepadMarketProductBundleAttachment:New(...)
    return ZO_GamepadMarketProduct.New(self, ...)
end

function ZO_GamepadMarketProductBundleAttachment:GetTemplate()
    return ZO_GAMEPAD_MARKET_PRODUCT_BUNDLE_ATTACHMENT_TEMPLATE
end

function ZO_GamepadMarketProductBundleAttachment:Refresh()
    self:UpdateProductStyle()
end

function ZO_GamepadMarketProductBundleAttachment:HasPreview()
    return false
end

function ZO_GamepadMarketProductBundleAttachment:SetBundle(bundle)
    self.bundle = bundle
end

function ZO_GamepadMarketProductBundleAttachment:IsPurchaseLocked()
     return self.bundle:IsPurchaseLocked()
end

function ZO_GamepadMarketProductBundleAttachment:GetProductForSell()
    return self.bundle
end

function ZO_GamepadMarketProductBundleAttachment:IsBundle()
    return false
end

function ZO_GamepadMarketProductBundleAttachment:IsBundleAttachment()
    return true
end

function ZO_GamepadMarketProductBundleAttachment:Reset()
    ZO_MarketProductBase.Reset(self)
    self.bundle = nil
end

function ZO_GamepadMarketProductBundleAttachment:LayoutTooltip(tooltip)
    assert(false) -- must be overridden
end


--
--[[ Gamepad Market Product Bundle Item Atachment ]]--
--

ZO_GamepadMarketProductBundleItemAttachment = ZO_GamepadMarketProductBundleAttachment:Subclass()

function ZO_GamepadMarketProductBundleItemAttachment:New(...)
    return ZO_GamepadMarketProductBundleAttachment.New(self, ...)
end

function ZO_GamepadMarketProductBundleItemAttachment:GetTemplate()
    return ZO_GAMEPAD_MARKET_PRODUCT_BUNDLE_ITEM_ATTACHMENT_TEMPLATE
end

function ZO_GamepadMarketProductBundleItemAttachment:ShowAsBundleItem(marketProductId, iconFile, name, itemQuality, requiredLevel, itemCount, itemLink, attachmentIndex, background)
    self.marketProductId = marketProductId
    self.itemLink = itemLink
    self.attachmentIndex = attachmentIndex
    self.isCollectible = false
    self.purchaseState = MARKET_PRODUCT_PURCHASE_STATE_NOT_PURCHASED
    self.name = name
    self:SetTitle(name)
    self.purchaseLabelControl:SetHidden(true)
    self.previousCostStrikethrough:SetHidden(true)
    self.textCallout:SetHidden(true)
    self:LayoutBackground(background)
    self:UpdateProductStyle()
    self.control:SetHidden(false)
end

function ZO_GamepadMarketProductBundleItemAttachment:GetAttachmentIndex()
    return self.attachmentIndex
end

function ZO_GamepadMarketProductBundleItemAttachment:Reset()
    ZO_GamepadMarketProductBundleAttachment.Reset(self)
    self.itemLink = nil
end

function ZO_GamepadMarketProductBundleItemAttachment:GetBackground()
    return GetMarketProductItemGamepadBackground(self.bundle:GetId(), self.attachmentIndex)
end

function ZO_GamepadMarketProductBundleItemAttachment:LayoutTooltip(tooltip)
    local stackCount = self:GetStackCount()
    GAMEPAD_TOOLTIPS:LayoutItemWithStackCount(tooltip, self.itemLink, stackCount, ZO_ITEM_TOOLTIP_HIDE_INVENTORY_BODY_COUNT, ZO_ITEM_TOOLTIP_HIDE_BANK_BODY_COUNT)
end

function ZO_GamepadMarketProductBundleItemAttachment:GetStackCount()
    return select(6, GetMarketProductItemInfo(self.bundle:GetId(), self.attachmentIndex))
end

--
--[[ Gamepad Market Product Bundle Collectible Attachment ]]--
--

ZO_GamepadMarketProductBundleCollectibleAttachment = ZO_GamepadMarketProductBundleAttachment:Subclass()

function ZO_GamepadMarketProductBundleCollectibleAttachment:New(...)
    return ZO_GamepadMarketProductBundleAttachment.New(self, ...)
end

function ZO_GamepadMarketProductBundleCollectibleAttachment:GetTemplate()
    return ZO_GAMEPAD_MARKET_PRODUCT_BUNDLE_COLLECTIBLE_ATTACHMENT_TEMPLATE
end

function ZO_GamepadMarketProductBundleCollectibleAttachment:ShowAsBundleCollectible(marketProductId, iconFile, name, unlocked, tooltipLayoutArgs, collectibleIndex, background)
    self.isCollectible = true
    self.tooltipLayoutArgs = tooltipLayoutArgs
    self.marketProductId = marketProductId
    self.collectibleIndex = collectibleIndex
    self.name = name
    self:SetTitle(name)
    self.purchaseState = unlocked and MARKET_PRODUCT_PURCHASE_STATE_PURCHASED or MARKET_PRODUCT_PURCHASE_STATE_NOT_PURCHASED
    self.purchaseLabelControl:SetHidden(not unlocked)
    
    if unlocked then
        self.purchaseLabelControl:SetText(GetString("SI_COLLECTIBLEUNLOCKSTATE", COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED))
    end

    ZO_MarketClasses_Shared_ApplyTextColorToLabel(self.purchaseLabelControl, unlocked, ZO_DEFAULT_TEXT, ZO_SELECTED_TEXT)
    self.previousCostStrikethrough:SetHidden(true)
    self.textCallout:SetHidden(true)
    self:LayoutBackground(background)
    self:UpdateProductStyle()
    self.control:SetHidden(false)
end

do
    LAYOUT_UNLOCKED_ARG_INDEX = 4
    function ZO_GamepadMarketProductBundleCollectibleAttachment:Refresh()
        ZO_GamepadMarketProductBundleAttachment.Refresh(self)
        local collectibleId, _, _, _, _, owned = GetMarketProductCollectibleInfo(self.bundle:GetId(), self.collectibleIndex)
        local unlockState = GetCollectibleUnlockStateById(collectibleId)

        self.purchaseLabelControl:SetHidden(not owned)
        self.tooltipLayoutArgs[LAYOUT_UNLOCKED_ARG_INDEX] = unlockState

        if owned then
            self.purchaseLabelControl:SetText(GetString("SI_COLLECTIBLEUNLOCKSTATE", COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED))
        end
    end
end


function ZO_GamepadMarketProductBundleCollectibleAttachment:GetCollectibleIndex()
    return self.collectibleIndex
end

function ZO_GamepadMarketProductBundleCollectibleAttachment:HasPreview()
    return self.bundle:CanPreviewCollectible(self.collectibleIndex)
end

function ZO_GamepadMarketProductBundleCollectibleAttachment:Preview()
    self.bundle:PreviewCollectible(self.collectibleIndex)
end

function ZO_GamepadMarketProductBundleCollectibleAttachment:Reset()
    ZO_GamepadMarketProductBundleAttachment.Reset(self)
    self.tooltipLayoutArgs = nil
end

function ZO_GamepadMarketProductBundleCollectibleAttachment:GetBackground()
    return GetMarketProductCollectibleGamepadBackground(self.bundle:GetId(), self.collectibleIndex)
end

function ZO_GamepadMarketProductBundleCollectibleAttachment:LayoutTooltip(tooltip)
    GAMEPAD_TOOLTIPS:LayoutCollectible(tooltip, unpack(self.tooltipLayoutArgs))
end

function ZO_GamepadMarketProductBundleCollectibleAttachment:GetStackCount()
    return SINGLE_ITEM_COUNT
end

--
--[[ Gamepad Market Blank Product ]]--
--

ZO_GamepadMarketBlankProduct = ZO_Object.MultiSubclass(ZO_MarketBlankProductBase, ZO_GamepadMarketProduct)

function ZO_GamepadMarketBlankProduct:New(...)
    return ZO_GamepadMarketProduct.New(self, ...)
end

function ZO_GamepadMarketBlankProduct:Initialize(...)
    ZO_GamepadMarketProduct.Initialize(self, ...)
end

function ZO_GamepadMarketBlankProduct:InitializeControls(control)
    ZO_GamepadMarketProduct.InitializeControls(self, control)
end

function ZO_MarketBlankProductBase:LayoutBackground()
end

function ZO_MarketBlankProductBase:UpdateProductStyle()
end

function ZO_GamepadMarketBlankProduct:GetTemplate()
    return ZO_GAMEPAD_MARKET_BLANK_TILE_TEMPLATE
end