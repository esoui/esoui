--
--[[ Market Content Fragment ]]--
--

ZO_MarketContentFragment_Keyboard = ZO_SimpleSceneFragment:Subclass()

function ZO_MarketContentFragment_Keyboard:New(...)
    local fragment = ZO_SimpleSceneFragment.New(self, ...)
    fragment:Initialize(...)
    return fragment
end

function ZO_MarketContentFragment_Keyboard:Initialize(owner, control, marketProductIconPool)
    self.owner = owner
    self.control = control
    self.contentHeader = control:GetNamedChild("ContentHeader")
    self.cost = control:GetNamedChild("Cost")

    self.marketProductIconPool = ZO_MetaPool:New(marketProductIconPool)

    self.productGridListControl = control:GetNamedChild("ProductList")
    self.productGridList = ZO_GridScrollList_Keyboard:New(self.productGridListControl)

    local function MarketProductEntrySetup(entryControl, data)
        if not entryControl.marketProduct then
            entryControl.marketProduct = ZO_MarketProductIndividual:New(entryControl, self.marketProductIconPool, owner)
        end

        entryControl.marketProduct:ShowAsChild(data.productData, data.parentMarketProductId)
    end

    local function MarketProductBundleEntrySetup(entryControl, data)
        if not entryControl.marketProduct then
            entryControl.marketProduct = ZO_MarketProductBundle:New(entryControl, self.marketProductIconPool, owner)
        end

        entryControl.marketProduct:ShowAsChild(data.productData, data.parentMarketProductId)
    end

    local function MarketProductEntryReset(entryControl)
        ZO_ObjectPool_DefaultResetControl(entryControl)
        entryControl.marketProduct:Reset()
    end

    local HIDE_CALLBACK = nil
    local CENTER_ENTRIES = true
    local HEADER_HEIGHT = 50
    local ROW_PADDING = 10
    self.productGridList:AddEntryTemplate("ZO_MarketProduct_Keyboard", ZO_MARKET_PRODUCT_WIDTH, ZO_MARKET_PRODUCT_HEIGHT, MarketProductEntrySetup, HIDE_CALLBACK, MarketProductEntryReset, ZO_MARKET_PRODUCT_COLUMN_PADDING, ROW_PADDING, CENTER_ENTRIES)
    self.productGridList:AddEntryTemplate("ZO_MarketProductBundle_Keyboard", ZO_MARKET_PRODUCT_BUNDLE_WIDTH, ZO_MARKET_PRODUCT_HEIGHT, MarketProductBundleEntrySetup, HIDE_CALLBACK, MarketProductEntryReset, ZO_MARKET_PRODUCT_COLUMN_PADDING, ROW_PADDING, CENTER_ENTRIES)
    self.productGridList:AddHeaderTemplate("ZO_Market_GroupLabel", HEADER_HEIGHT, ZO_DefaultGridHeaderSetup)
    self.productGridList:SetHeaderPrePadding(30)

    self.marketProducts = {}

    self:RegisterCallback("StateChange", function(...) self:OnStateChange(...) end)
end

function ZO_MarketContentFragment_Keyboard:OnStateChange(oldState, newState)
    if newState == SCENE_FRAGMENT_HIDDEN then
        self.marketProductData = nil
    end
end

function ZO_MarketContentFragment_Keyboard:ShowMarketProductContents(marketProductData)
    self.productGridList:ClearGridList()
    ZO_ClearNumericallyIndexedTable(self.marketProducts)

    self.marketProductData = marketProductData

    self.contentHeader:SetText(zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, marketProductData:GetDisplayName()))

    local marketCurrencyType, cost, costAfterDiscount, discountPercent, esoPlusCost = marketProductData:GetMarketProductPricingByPresentation()
    local currencyString = ZO_Currency_FormatKeyboard(GetCurrencyTypeFromMarketCurrencyType(marketCurrencyType), costAfterDiscount, ZO_CURRENCY_FORMAT_AMOUNT_ICON)
    self.cost:SetText(currencyString)

    local numChildren = marketProductData:GetNumChildren()
    if numChildren > 0 then
        local parentMarketProductId = marketProductData:GetId()
        for childIndex = 1, numChildren do
            local childMarketProductId = marketProductData:GetChildMarketProductId(childIndex)
            local childProductData = ZO_MarketProductData:New(childMarketProductId, ZO_INVALID_PRESENTATION_INDEX)

            local isBundle = childProductData:IsBundle()
            local templateName = isBundle and "ZO_MarketProductBundle_Keyboard" or "ZO_MarketProduct_Keyboard"

            local productInfo =
            {
                templateName = templateName,
                productData = childProductData,
                parentMarketProductId = parentMarketProductId,
                gridHeaderTemplate = "ZO_Market_GroupLabel",
                -- for sorting
                name = childProductData:GetDisplayName(),
                isBundle = isBundle,
                stackCount = childProductData:GetStackCount(),
            }
            table.insert(self.marketProducts, productInfo)
        end

        table.sort(self.marketProducts, function(entry1, entry2)
            return self.owner:CompareMarketProducts(entry1, entry2)
        end)
    end

    for index, productInfo in ipairs(self.marketProducts) do
        self.productGridList:AddEntry(productInfo, productInfo.templateName)
    end

    self.productGridList:CommitGridList()
end

function ZO_MarketContentFragment_Keyboard:RefreshProducts()
    local ALL_ENTRIES = nil
    local function RefreshMarketProduct(control, data)
        if control.marketProduct then
            control.marketProduct:RefreshAsChild()
        end
    end
    self.productGridList:RefreshGridListEntryData(ALL_ENTRIES, RefreshMarketProduct)
end

function ZO_MarketContentFragment_Keyboard:GetMarketProductData()
    return self.marketProductData
end

function ZO_MarketContentFragment_Keyboard:CanPurchase()
    if self.marketProductData then
        return self.marketProductData:CanBePurchased()
    else
        return false
    end
end

function ZO_MarketContentFragment_Keyboard:CanGift()
    if self.marketProductData then
        return self.marketProductData:IsGiftable()
    else
        return false
    end
end