ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCT_WIDTH = 407
ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCT_HEIGHT = 270
ZO_GAMEPAD_MARKET_PRODUCT_TEMPLATE = "ZO_Gamepad_MarketProductTemplate"
ZO_GAMEPAD_MARKET_PRODUCT_BUNDLE_ATTACHMENT_TEMPLATE = "ZO_Gamepad_MarketProductBundleAttachmentTemplate"
ZO_GAMEPAD_MARKET_BLANK_TILE_TEMPLATE = "ZO_Gamepad_MarketBlankTileTemplate"

-- single tiles are 512 x 512
ZO_GAMEPAD_MARKET_INDIVIDUAL_TEXTURE_WIDTH_COORD = ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCT_WIDTH / 512
ZO_GAMEPAD_MARKET_INDIVIDUAL_TEXTURE_HEIGHT_COORD = ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCT_HEIGHT / 512

ZO_GAMEPAD_MARKET_ENTRY_MARKET_PRODUCT = "marketProduct"
ZO_GAMEPAD_MARKET_ENTRY_BLANK_TILE = "blankTile"
ZO_GAMEPAD_MARKET_ENTRY_FREE_TRIAL_TILE = "freeTrialTile"
ZO_GAMEPAD_MARKET_ENTRY_MEMBERSHIP_INFO_TILE = "membershipInfoTile"

--
--[[ Gamepad Market Product ]]--
--

ZO_GamepadMarketProduct = ZO_LargeSingleMarketProduct_Base:Subclass()

function ZO_GamepadMarketProduct:New(...)
    return ZO_LargeSingleMarketProduct_Base.New(self, ...)
end

function ZO_GamepadMarketProduct:Initialize(controlId, parent, controlName)
    local controlTemplate = self:GetTemplate()
    local control = CreateControlFromVirtual(controlName or controlTemplate, parent, controlTemplate, controlId)
    ZO_LargeSingleMarketProduct_Base.Initialize(self, control)

    self.focusData =
    {
        control = self.control,
        highlight = self.control.highlight,
        object = self,
    }
end

-- override of ZO_MarketProductBase:GetEsoPlusIcon()
function ZO_GamepadMarketProduct:GetEsoPlusIcon()
    return zo_iconFormatInheritColor("EsoUI/Art/Market/Gamepad/gp_ESOPlus_Chalice_WHITE_64.dds", "100%", "100%")
end

function ZO_GamepadMarketProduct:GetTemplate()
    return ZO_GAMEPAD_MARKET_PRODUCT_TEMPLATE
end

function ZO_GamepadMarketProduct:UpdateProductStyle()
    ZO_LargeSingleMarketProduct_Base.UpdateProductStyle(self)

     if self:IsPurchaseLocked() then
        self.control.highlightNormal:SetEdgeColor(ZO_MARKET_PRODUCT_PURCHASED_COLOR:UnpackRGB())
    else
        self.control.highlightNormal:SetEdgeColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGB())
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

function ZO_GamepadMarketProduct:GetEntryType()
    return ZO_GAMEPAD_MARKET_ENTRY_MARKET_PRODUCT
end

-- override of ZO_MarketProductBase:AnchorBundledProductsLabel()
function ZO_GamepadMarketProduct:AnchorBundledProductsLabel()
    local control = self.control
    local numBundledProductsLabel = control.numBundledProductsLabel
    numBundledProductsLabel:ClearAnchors()

    local canBePurchased = self:CanBePurchased()
    if canBePurchased then
        if self:HasEsoPlusCost() then
            numBundledProductsLabel:SetAnchor(BOTTOMRIGHT, control.esoPlusDealLabelControl, TOPRIGHT, 0, 5)
        else
            numBundledProductsLabel:SetAnchor(BOTTOMRIGHT, control, BOTTOMRIGHT, -20, -10)
        end
    else
        numBundledProductsLabel:SetAnchor(BOTTOMRIGHT, control.purchaseLabelControl, TOPRIGHT, 0, 5)
    end
end

-- override of ZO_MarketProductBase:AnchorLabelBetweenBundleIndicatorAndCost(label)
function ZO_GamepadMarketProduct:AnchorLabelBetweenBundleIndicatorAndCost(label)
    label:ClearAnchors()

    local control = self.control
    label:SetAnchor(BOTTOMRIGHT, control, BOTTOMRIGHT, -20, -10)

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

function ZO_GamepadMarketProductBundleAttachment:GetMarketProductDisplayState()
    local parentDisplayState = ZO_GetMarketProductDisplayState(self.bundleMarketProductId)
    if parentDisplayState == MARKET_PRODUCT_DISPLAY_STATE_PURCHASED then
        return parentDisplayState
    end

    return ZO_GamepadMarketProduct.GetMarketProductDisplayState(self)
end

function ZO_GamepadMarketProductBundleAttachment:Show(...)
    ZO_GamepadMarketProduct.Show(self, ...)

    local allCollectiblesOwned = self:AreAllCollectiblesUnlocked()

    local control = self.control
    control.purchaseLabelControl:SetHidden(not allCollectiblesOwned)

    if allCollectiblesOwned then
        control.purchaseLabelControl:SetText(GetString("SI_COLLECTIBLEUNLOCKSTATE", COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED))
    end

    -- hide all the price info
    control.cost:SetHidden(true)
    control.previousCost:SetHidden(true)
    control.textCallout:SetHidden(true)
end

-- override of ZO_LargeSingleMarketProduct_Base:LayoutTooltip(tooltip)
function ZO_GamepadMarketProductBundleAttachment:LayoutTooltip(tooltip)
    GAMEPAD_TOOLTIPS:LayoutMarketProduct(tooltip, self:GetId())
end

function ZO_GamepadMarketProductBundleAttachment:SetBundleMarketProductId(bundleMarketProductId)
    self.bundleMarketProductId = bundleMarketProductId
end

function ZO_GamepadMarketProductBundleAttachment:IsPurchaseLocked()
     return ZO_GetMarketProductDisplayState(self.bundleMarketProductId) ~= MARKET_PRODUCT_DISPLAY_STATE_NOT_PURCHASED or ZO_GamepadMarketProduct.IsPurchaseLocked(self)
end

function ZO_GamepadMarketProductBundleAttachment:Reset()
    ZO_GamepadMarketProduct.Reset(self)
    self.bundleMarketProductId = nil
end

--
--[[ Gamepad Market Blank Tile ]]--
--

ZO_GamepadMarketBlankTile = ZO_Object:Subclass()

function ZO_GamepadMarketBlankTile:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_GamepadMarketBlankTile:Initialize(control)
    self.control = control
    self.highlightControl = control:GetNamedChild("Highlight")

    self.focusData =
    {
        control = control,
        highlight = self.highlightControl,
        object = self,
    }
end

function ZO_GamepadMarketBlankTile:GetControl()
    return self.control
end

function ZO_GamepadMarketBlankTile:GetFocusData()
    return self.focusData
end

function ZO_GamepadMarketBlankTile:SetListIndex(listIndex)
    self.listIndex = listIndex
end

function ZO_GamepadMarketBlankTile:GetListIndex()
    return self.listIndex
end

function ZO_GamepadMarketBlankTile:SetIsFocused(isFocused)
    if self.isFocused ~= isFocused then
        self.isFocused = isFocused
    end
end

function ZO_GamepadMarketBlankTile:GetEntryType()
    return ZO_GAMEPAD_MARKET_ENTRY_BLANK_TILE
end

function ZO_GamepadMarketBlankTile:Show()
    self.control:SetHidden(false)
end

function ZO_GamepadMarketBlankTile:Refresh()
    -- nothing to refresh
end

function ZO_GamepadMarketBlankTile:Reset()
    self.control:SetHidden(true)
end

--
--[[ Gamepad Market Generic Tile ]]--
--

ZO_GamepadMarketGenericTile = ZO_Object:Subclass()

function ZO_GamepadMarketGenericTile:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_GamepadMarketGenericTile:Initialize(control)
    self.control = control

    self.focusData =
    {
        control = control,
        highlight = control.highlight,
        object = self,
    }

    self:Reset()
end

function ZO_GamepadMarketGenericTile:GetControl()
    return self.control
end

function ZO_GamepadMarketGenericTile:GetFocusData()
    return self.focusData
end

function ZO_GamepadMarketGenericTile:SetListIndex(listIndex)
    self.listIndex = listIndex
end

function ZO_GamepadMarketGenericTile:GetListIndex()
    return self.listIndex
end

function ZO_GamepadMarketGenericTile:SetIsFocused(isFocused)
    if self.isFocused ~= isFocused then
        self.isFocused = isFocused
        self:UpdateProductStyle()
    end
end

function ZO_GamepadMarketGenericTile:SetEntryType(entryType)
    self.entryType = entryType
end

function ZO_GamepadMarketGenericTile:GetEntryType()
    return self.entryType
end

function ZO_GamepadMarketGenericTile:SetBackground(backgroundTexture)
    self.control.backgroundTexture:SetTexture(backgroundTexture)
end

function ZO_GamepadMarketGenericTile:SetTitle(titleStringOrFunction)
    self.titleStringOrFunction = titleStringOrFunction
end

function ZO_GamepadMarketGenericTile:GetTitle()
    if type(self.titleStringOrFunction) == "function" then
        return self.titleStringOrFunction()
    else
        return self.titleStringOrFunction
    end
end

function ZO_GamepadMarketGenericTile:SetTitleColors(selectedColor, unselectedColor)
    self.titleSelectedColor = selectedColor or self.titleSelectedColor
    self.titleUnselectedColor = unselectedColor or self.titleUnselectedColor
end

function ZO_GamepadMarketGenericTile:SetTitlePurchasedColors(selectedColor, unselectedColor)
    self.titlePurchasedSelectedColor = selectedColor or self.titlePurchasedSelectedColor
    self.titlePurchasedUnselectedColor = unselectedColor or self.titlePurchasedUnselectedColor
end

function ZO_GamepadMarketGenericTile:UpdateTitleLabel()
    local titleLabel = self.control.titleLabel

    if self:IsPurchased() then
        if self.isFocused then
            titleLabel:SetColor(self.titlePurchasedSelectedColor:UnpackRGB())
        else
            titleLabel:SetColor(self.titlePurchasedUnselectedColor:UnpackRGB())
        end
    else
        if self.isFocused then
            titleLabel:SetColor(self.titleSelectedColor:UnpackRGB())
        else
            titleLabel:SetColor(self.titleUnselectedColor:UnpackRGB())
        end
    end

    titleLabel:SetText(self:GetTitle())
end

function ZO_GamepadMarketGenericTile:SetText(textStringOrFunction)
    self.textStringOrFunction = textStringOrFunction
end

function ZO_GamepadMarketGenericTile:GetText()
    if type(self.textStringOrFunction) == "function" then
        return self.textStringOrFunction()
    else
        return self.textStringOrFunction
    end
end

function ZO_GamepadMarketGenericTile:SetTextColors(selectedColor, unselectedColor)
    self.textSelectedColor = selectedColor or self.textSelectedColor
    self.textUnselectedColor = unselectedColor or self.textUnselectedColor
end

function ZO_GamepadMarketGenericTile:SetTextPurchasedColors(selectedColor, unselectedColor)
    self.textPurchasedSelectedColor = selectedColor or self.textPurchasedSelectedColor
    self.textPurchasedUnselectedColor = unselectedColor or self.textPurchasedUnselectedColor
end

function ZO_GamepadMarketGenericTile:UpdateTextLabel()
    local textLabel = self.control.textLabel

    if self:IsPurchased() then
        if self.isFocused then
            textLabel:SetColor(self.textPurchasedSelectedColor:UnpackRGB())
        else
            textLabel:SetColor(self.textPurchasedUnselectedColor:UnpackRGB())
        end
    else
        if self.isFocused then
            textLabel:SetColor(self.textSelectedColor:UnpackRGB())
        else
            textLabel:SetColor(self.textUnselectedColor:UnpackRGB())
        end
    end

    textLabel:SetText(self:GetText())
end

function ZO_GamepadMarketGenericTile:SetPurchaseCheckFunction(purchaseCheckFunction)
    self.purchaseCheckFunction = purchaseCheckFunction
end

function ZO_GamepadMarketGenericTile:IsPurchased()
    if self.purchaseCheckFunction then
        return self.purchaseCheckFunction()
    else
        return false
    end
end

function ZO_GamepadMarketGenericTile:Show()
    self.control:SetHidden(false)
    self:UpdateProductStyle()
end

function ZO_GamepadMarketGenericTile:UpdateProductStyle()
    self:UpdateTitleLabel()
    self:UpdateTextLabel()

    local isPurchased = self:IsPurchased()
    if isPurchased then
        self.control.highlightNormal:SetEdgeColor(ZO_MARKET_PRODUCT_PURCHASED_COLOR:UnpackRGB())
    else
        self.control.highlightNormal:SetEdgeColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGB())
    end

    local backgroundColor = self.isFocused and ZO_MARKET_PRODUCT_BACKGROUND_BRIGHTNESS_COLOR or ZO_MARKET_DIMMED_COLOR
    self.control.backgroundTexture:SetColor(backgroundColor:UnpackRGB())

    local backgroundDesaturation = isPurchased and ZO_MARKET_PRODUCT_PURCHASED_DESATURATION or ZO_MARKET_PRODUCT_NOT_PURCHASED_DESATURATION
    self.control.backgroundTexture:SetDesaturation(backgroundDesaturation)
end

function ZO_GamepadMarketGenericTile:Refresh()
    self:UpdateProductStyle()
end

function ZO_GamepadMarketGenericTile:Reset()
    self.control:SetHidden(true)
    self.entryType = nil
    self.purchaseCheckFunction = nil
    self.titleStringOrFunction = ""
    self.titleSelectedColor = ZO_MARKET_SELECTED_COLOR
    self.titleUnselectedColor = ZO_MARKET_DIMMED_COLOR
    self.titlePurchasedSelectedColor = ZO_MARKET_PRODUCT_PURCHASED_COLOR
    self.titlePurchasedUnselectedColor = ZO_MARKET_PRODUCT_PURCHASED_DIMMED_COLOR

    self.textStringOrFunction = ""
    self.textSelectedColor = ZO_MARKET_SELECTED_COLOR
    self.textUnselectedColor = ZO_MARKET_DIMMED_COLOR
    self.textPurchasedSelectedColor = ZO_MARKET_PRODUCT_PURCHASED_COLOR
    self.textPurchasedUnselectedColor = ZO_MARKET_PRODUCT_PURCHASED_DIMMED_COLOR
end

--
--[[ XML Handlers ]]--
--

function ZO_MarketProductGamepad_OnInitialized(control)
    ZO_MarketProductBase_OnInitialized(control)
    control.highlight = control:GetNamedChild("Highlight")
    control.highlightNormal = control:GetNamedChild("HighlightNormal")
end

function ZO_GamepadMarketGenericTile_OnInitialized(control)
    control.backgroundTexture = control:GetNamedChild("Background")
    control.highlight = control:GetNamedChild("Highlight")
    control.highlightNormal = control:GetNamedChild("HighlightNormal")
    control.titleLabel = control:GetNamedChild("Title")
    control.textLabel = control:GetNamedChild("Text")
end