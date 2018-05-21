ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCT_WIDTH = 407
ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCT_HEIGHT = 270
ZO_GAMEPAD_MARKET_PRODUCT_TEMPLATE = "ZO_Gamepad_MarketProductTemplate"
ZO_GAMEPAD_MARKET_PRODUCT_BUNDLE_ATTACHMENT_TEMPLATE = "ZO_Gamepad_MarketProductBundleAttachmentTemplate"
ZO_GAMEPAD_MARKET_BLANK_TILE_TEMPLATE = "ZO_Gamepad_MarketBlankTileTemplate"

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
end

function ZO_GamepadMarketProduct:InitializeControls(control)
    ZO_LargeSingleMarketProduct_Base.InitializeControls(self, control)

    self.normalBorder = self.control:GetNamedChild("HighlightNormal")
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
    -- single tiles are 512 x 512
    local INDIVIDUAL_TEXTURE_WIDTH_COORD = ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCT_WIDTH / 512
    local INDIVIDUAL_TEXTURE_HEIGHT_COORD = ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCT_HEIGHT / 512

    function ZO_GamepadMarketProduct:LayoutBackground(background)
        self.background:SetTexture(background)
        
        self.background:SetTextureCoords(0, INDIVIDUAL_TEXTURE_WIDTH_COORD, 0, INDIVIDUAL_TEXTURE_HEIGHT_COORD)
        self.background:SetHidden(background == ZO_NO_TEXTURE_FILE)
    end
end

function ZO_GamepadMarketProduct:UpdateProductStyle()
    ZO_LargeSingleMarketProduct_Base.UpdateProductStyle(self)

     if self:IsPurchaseLocked() or self.isFree then
        self.normalBorder:SetEdgeColor(ZO_MARKET_PRODUCT_PURCHASED_COLOR:UnpackRGB())
    else
        self.normalBorder:SetEdgeColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGB())
    end
end

function ZO_GamepadMarketProduct:GetFocusData()
    return self.focusData
end

function ZO_GamepadMarketProduct:SetListIndex(listIndex)
    self.listIndex = listIndex
end

function ZO_GamepadMarketProduct:GetListIndex()
    return self.listIndex
end

-- Used for cycling through preview items in the preview screen
function ZO_GamepadMarketProduct:SetPreviewIndex(previewIndex)
    self.previewIndex = previewIndex
end

function ZO_GamepadMarketProduct:GetPreviewIndex()
    return self.previewIndex
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

function ZO_GamepadMarketProductBundleAttachment:GetPurchaseState()
    local parentPurchaseState = GetMarketProductPurchaseState(self.bundleMarketProductId)
    if parentPurchaseState == MARKET_PRODUCT_PURCHASE_STATE_PURCHASED then
        return parentPurchaseState
    end

    return ZO_GamepadMarketProduct.GetPurchaseState(self)
end

function ZO_GamepadMarketProductBundleAttachment:Show(...)
    ZO_GamepadMarketProduct.Show(self, ...)

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

function ZO_GamepadMarketProductBundleAttachment:SetBundleMarketProductId(bundleMarketProductId)
    self.bundleMarketProductId = bundleMarketProductId
end

function ZO_GamepadMarketProductBundleAttachment:IsPurchaseLocked()
     return GetMarketProductPurchaseState(self.bundleMarketProductId) ~= MARKET_PRODUCT_PURCHASE_STATE_NOT_PURCHASED or ZO_GamepadMarketProduct.IsPurchaseLocked(self)
end

function ZO_GamepadMarketProductBundleAttachment:Reset()
    ZO_GamepadMarketProduct.Reset(self)
    self.bundleMarketProductId = nil
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