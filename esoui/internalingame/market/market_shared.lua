ZO_MARKET_NAME = "Market"
ZO_MARKET_PREVIEW_WAIT_TIME_MS = 500
ZO_MARKET_DISPLAY_LOADING_DELAY_MS = 500

--
--[[ Market Singleton ]]--
--

local Market_Singleton = ZO_Object:Subclass()

function Market_Singleton:New(...)
    local market = ZO_Object.New(self)
    market:Initialize(...)
    return market
end

function Market_Singleton:Initialize()
    self:ResetOpenMarketSource()
    self:InitializeEvents()
end

function Market_Singleton:InitializeEvents()
    local function OnMarketStateUpdated(...)
        SYSTEMS:GetObject(ZO_MARKET_NAME):OnMarketStateUpdated(...)
    end

    local function OnMarketCurrencyUpdated(...)
        SYSTEMS:GetObject(ZO_MARKET_NAME):OnMarketCurrencyUpdated(...)
    end

    local function OnMarketPurchaseResult(...)
        SYSTEMS:GetObject(ZO_MARKET_NAME):OnMarketPurchaseResult(...)
    end

    local function OnMarketSearchResultsReady()
        SYSTEMS:GetObject(ZO_MARKET_NAME):OnMarketSearchResultsReady()
    end

    local function OnMarketCollectibleUpdated(_, justUnlocked)
        SYSTEMS:GetObject(ZO_MARKET_NAME):OnCollectibleUpdated(justUnlocked)
    end

    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_MARKET_STATE_UPDATED, function(eventId, ...) OnMarketStateUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_MARKET_CURRENCY_UPDATE, function(eventId, ...) OnMarketCurrencyUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_MARKET_PURCHASE_RESULT, function(eventId, ...) OnMarketPurchaseResult(...) end)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_MARKET_PRODUCT_SEARCH_RESULTS_READY, function() OnMarketSearchResultsReady() end)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_COLLECTIBLE_UPDATED, function(eventId, ...) OnMarketCollectibleUpdated(...) end)
end

function Market_Singleton:SetOpenMarketSource(source)
    self.marketOpenSource = source
end

function Market_Singleton:ResetOpenMarketSource()
    self:SetOpenMarketSource(MARKET_OPEN_OPERATION_DIRECT)
end

function Market_Singleton:RequestOpenMarket()
    OpenMarket(self.marketOpenSource)
    self:ResetOpenMarketSource()
end

ZO_MARKET_SINGLETON = Market_Singleton:New()

--
--[[ Market Shared ]]--
--

ZO_Market_Shared = ZO_Object:Subclass()

function ZO_Market_Shared:New(...)
    local market = ZO_Object.New(self)
    market:Initialize(...)
    return market
end

function ZO_Market_Shared:Initialize()
    -- clean up any preview that may have been left over
    self:EndCurrentPreview()
    self.featuredProducts = {}
    self.newProducts = {}
    self.onSaleProducts = {}
    self.marketProducts = {} -- products not contained in a labeled group such as Featured products, new products, on sale products, limited time products, or a subcategory
    self.searchResults = {}
    self.searchString = ""
    self:CreateMarketScene()
    self:RegisterSceneStateChangeCallback()
    self:InitializeCategories()
    self:InitializeMarketList()
    self:InitializeKeybindDescriptors()
    self:InitializeFilters()
    self:InitializeLabeledGroups()
    self:UpdateMarket()
    self:UpdateCurrencyBalance(GetMarketCurrency())
    self.control:RegisterForEvent(EVENT_TUTORIAL_HIDDEN, function()
        if self.currentTutorial then
            self.currentTutorial = nil
            self:RestoreActionLayerForTutorial()
            self:OnTutorialHidden()
        end
    end)
end

do
    -- Search stride is the number of elements between products.
    -- This is because C++ returns products as category​Index, subcategory​Index, productIndex
    local SEARCH_DATA_STRIDE = 3
    function ZO_Market_Shared:UpdateSearchResults(...)
        ZO_ClearTable(self.searchResults)

        for i = 1, select("#", ...), SEARCH_DATA_STRIDE do
            local categoryIndex, subcategoryIndex, productIndex = select(i, ...)
            if not self.searchResults[categoryIndex] then
                self.searchResults[categoryIndex] = {}
            end

            local effectiveSubCategory = subcategoryIndex or "root"
            if not self.searchResults[categoryIndex][effectiveSubCategory] then
                self.searchResults[categoryIndex][effectiveSubCategory] = {}
            end

            self.searchResults[categoryIndex][effectiveSubCategory][productIndex] = true
        end
    end
end

function ZO_Market_Shared:OnInitialInteraction()
        ZO_MARKET_SINGLETON:RequestOpenMarket()
        SetSecureRenderModeEnabled(true)

        -- ensure that we are in the correct state
        if self.marketState ~= GetMarketState() then
            self:UpdateMarket()
        elseif self.marketState == MARKET_STATE_OPEN then
            self:UpdateCurrentCategory()
        end
end

function ZO_Market_Shared:OnEndInteraction()
    self.currentTutorial = nil
    SetSecureRenderModeEnabled(false)
    EndItemPreview()
end

function ZO_Market_Shared:OnStateChanged(oldState, newState)
    if newState == SCENE_SHOWING then
        self:OnInitialInteraction()
        self:OnShowing()
    elseif newState == SCENE_SHOWN then
        self:OnShown()
    elseif newState == SCENE_HIDING then
        self:OnHiding()
    elseif newState == SCENE_HIDDEN then
        self:OnHidden()
        self:OnEndInteraction()
    end
end

function ZO_Market_Shared:RegisterSceneStateChangeCallback()
    self.marketScene:RegisterCallback("StateChange", function(...) self:OnStateChanged(...) end)
end

function ZO_Market_Shared:ResetCategoryData()
    self.currentCategoryData = nil
end

function ZO_Market_Shared:OnMarketStateUpdated(marketState)
    self:ResetCategoryData()
    self:UpdateMarket()
end

-- difference is the difference in crowns for this update. For instance, new crowns purchased will show a positive difference.
-- TO DO: this will be used once live updates to crowns are supported during the game.
function ZO_Market_Shared:OnMarketCurrencyUpdated(currentCurrency, difference)
    self:UpdateCurrencyBalance(currentCurrency)
end

function ZO_Market_Shared:OnMarketPurchaseResult()
    self:UpdateCurrentCategory()
end

function ZO_Market_Shared:OnMarketSearchResultsReady()
    self:UpdateSearchResults(GetMarketProductSearchResults())
    self:UpdateMarket()
end

function ZO_Market_Shared:UpdateCurrentCategory()
    if self.currentCategoryData then
        self:RefreshProducts()
    end
end

function ZO_Market_Shared:OnCollectibleUpdated(justUnlocked)
    if justUnlocked then
        self:UpdateCurrentCategory()
    end
end

function ZO_Market_Shared:UpdateMarket()
    self.marketState = GetMarketState()
    if self.marketState == MARKET_STATE_OPEN then
        self:OnMarketOpen()
    elseif self.marketState == MARKET_STATE_UNKNOWN then
        self:OnMarketLoading()
    else -- MARKET_STATE_LOCKED
        self:OnMarketLocked()
    end

    self:OnMarketUpdate()
end

function ZO_Market_Shared:GetState()
    return self.marketState
end

function ZO_Market_Shared:SetMarketScene(scene)
    self.marketScene = scene
end

function ZO_Market_Shared:BeginPreview()
    self.selectedMarketProduct:Preview()
end 

function ZO_Market_Shared:EndCurrentPreview()
    EndCurrentItemPreview()
    self:RefreshActions()
end

function ZO_Market_Shared:OnMarketOpen()
    self:BuildCategories()
    self:ShowMarket(true)
end

function ZO_Market_Shared:OnCategorySelected(data)
    EndCurrentItemPreview()
    self:ClearLabeledGroups()
    
    self.currentCategoryData = data
    
    if data.featured then
        self:BuildFeaturedMarketProductList(data)
    else
        self:BuildMarketProductList(data)
    end

    self:RefreshActions()
end

function ZO_Market_Shared:AddKeybinds()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptors)
end

function ZO_Market_Shared:RemoveKeybinds()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptors)
end

function ZO_Market_Shared:RefreshKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptors)
end

do
    local MARKET_PRODUCT_SORT_KEYS =
        {
            isBundle = { tiebreaker = "name", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
            name = {},
        }

    function ZO_Market_Shared:CompareMarketProducts(entry1, entry2)
        return ZO_TableOrderingFunction(entry1, entry2, "isBundle", MARKET_PRODUCT_SORT_KEYS, ZO_SORT_ORDER_DOWN)
    end
end

do
    local function GetFeaturedProductIds(index, ...)
        if index >= 1 then
            local id = GetFeaturedMarketProductId(index)
            index = index - 1
            return GetFeaturedProductIds(index, id, ...)
        end
        return ...
    end

    function ZO_Market_Shared:BuildFeaturedMarketProductList()
        local numFeaturedMarketProducts = GetNumFeaturedMarketProducts()
        
        self:LayoutMarketProducts(GetFeaturedProductIds(numFeaturedMarketProducts))
    end
end

function ZO_Market_Shared:GetCategoryIndices(data, parentData)
    if parentData then
        return parentData.categoryIndex, data.categoryIndex
    end

    return data.categoryIndex
end

function ZO_Market_Shared:BuildMarketProductList(data)
    local parentData = data.parentData
    local categoryIndex, subCategoryIndex = self:GetCategoryIndices(data, parentData)

    local numMarketProducts
    if subCategoryIndex then
        numMarketProducts = select(2, GetMarketProductSubCategoryInfo(categoryIndex, subCategoryIndex))
    else
        numMarketProducts = select(3, GetMarketProductCategoryInfo(categoryIndex))
    end

    self:LayoutMarketProducts(self:GetMarketProductIds(categoryIndex, subCategoryIndex, numMarketProducts))
end

function ZO_Market_Shared:GetPreviewState()
    local isPreviewing = IsCurrentlyPreviewing()
    local canPreview = false
    local isActivePreview = false

    local marketProduct = self.selectedMarketProduct
    if marketProduct ~= nil then -- User is hovering over a MarketProduct
        canPreview = marketProduct:HasPreview() and IsCharacterPreviewingAvailable()

        if isPreviewing and marketProduct:IsPreviewingActiveCollectible() then
            isActivePreview = true
        end
    end

    return isPreviewing, canPreview, isActivePreview
end

function ZO_Market_Shared:IsReadyToPreview()
    local _, canPreview, isActivePreview = self:GetPreviewState()
    return canPreview and not isActivePreview
end

function ZO_Market_Shared:ShouldAddMarketProduct(filterType, id)
    if(filterType == MARKET_FILTER_VIEW_ALL) then return true end

    local purchaseState = GetMarketProductPurchaseState(id)
    if purchaseState == MARKET_PRODUCT_PURCHASE_STATE_NOT_PURCHASED then
        return filterType == MARKET_FILTER_VIEW_NOT_PURCHASED
    else
        return filterType == MARKET_FILTER_VIEW_PURCHASED
    end
end

function ZO_Market_Shared:ShowTutorial(tutorial)
    local tutorialId = GetTutorialId(tutorial)
    if CanTutorialBeSeen(tutorialId) and (not HasSeenTutorial(tutorialId)) then
        self.currentTutorial = tutorial
        self:OnTutorialShowing()
        self:RemoveActionLayerForTutorial()
        TriggerTutorial(tutorial)
    end
end

function ZO_Market_Shared:OnShowing()
    self:UpdateCurrencyBalance(GetMarketCurrency())
end

function ZO_Market_Shared:OnShown()
    if self.marketState == MARKET_STATE_OPEN then
        self:ShowTutorial(TUTORIAL_TRIGGER_MARKET_OPENED)
    end
end

function ZO_Market_Shared:OnHiding()
    --clear the current tutorial when hiding so we don't push an extra action layer
    self.currentTutorial = nil
end

function ZO_Market_Shared:InitializeLabeledGroups()
    self.labeledGroups = {}
    self.labeledGroupLabelPool = ZO_ControlPool:New(self:GetLabeledGroupLabelTemplate(), self.control)
end

function ZO_Market_Shared:AddLabel(labeledGroupName, parentControl, yPadding)
    local labeledGroupLabel = self.labeledGroupLabelPool:AcquireObject()
    labeledGroupLabel:SetText(labeledGroupName)
    labeledGroupLabel:SetParent(parentControl)
    labeledGroupLabel:ClearAnchors()
    labeledGroupLabel:SetAnchor(BOTTOMLEFT, parentControl, TOPLEFT, 0, yPadding)
end

function ZO_Market_Shared:ClearLabeledGroups()
    ZO_ClearNumericallyIndexedTable(self.labeledGroups)
    self.labeledGroupLabelPool:ReleaseAllObjects()
    ZO_ClearNumericallyIndexedTable(self.featuredProducts)
    ZO_ClearNumericallyIndexedTable(self.newProducts)
    ZO_ClearNumericallyIndexedTable(self.onSaleProducts)
    ZO_ClearNumericallyIndexedTable(self.marketProducts)
end

function ZO_Market_Shared:AddLabeledGroupTable(labeledGroupName, labeledGroupTable)
    table.sort(labeledGroupTable, function(entry1, entry2) 
        return self:CompareMarketProducts(entry1, entry2) 
    end)
    
    local numProducts = 0
    for _, marketProductInfo in ipairs(labeledGroupTable) do
        if not marketProductInfo.product:IsBlank() then
            numProducts = numProducts + 1
        end
    end
    
    table.insert(self.labeledGroups, { name = labeledGroupName, table = labeledGroupTable, numProducts = numProducts })
end

function ZO_Market_Shared:GetCurrentLabeledGroupData()
    return self.labeledGroups[#self.labeledGroups]
end

function ZO_Market_Shared:GetCurrentLabeledGroupNumProducts()
    return self:GetCurrentLabeledGroupData().numProducts
end

function ZO_Market_Shared:GetCurrentLabeledGroupName()
    return self:GetCurrentLabeledGroupData().name
end

function ZO_Market_Shared:GetCurrentLabeledGroupProducts()
    return self:GetCurrentLabeledGroupData().table
end

function ZO_Market_Shared:AddProductToLabeledGroupTable(labeledGroupTable, productName, product)
    local productInfo = {
                            product = product,
                            control = product:GetControl(),
                            name = productName,
                            isBundle = product:IsBundle()
                        }
    table.insert(labeledGroupTable, productInfo)
end

--[[ Functions to be overridden ]]--

function ZO_Market_Shared:OnHidden()
end

function ZO_Market_Shared:UpdateCurrencyBalance(currency)
end

function ZO_Market_Shared:InitializeKeybindDescriptors()
end

function ZO_Market_Shared:InitializeCategories()
end

function ZO_Market_Shared:InitializeMarketList()
end

function ZO_Market_Shared:InitializeFilters()
end

function ZO_Market_Shared:CreateMarketScene()
end

function ZO_Market_Shared:BuildCategories()
end

function ZO_Market_Shared:ShowMarket(show)
end

function ZO_Market_Shared:OnMarketUpdate()
end

function ZO_Market_Shared:OnMarketLoading()
end

function ZO_Market_Shared:OnMarketLocked()
end

function ZO_Market_Shared:RefreshVisibleCategoryFilter()
end

function ZO_Market_Shared:RefreshProducts()
end

function ZO_Market_Shared:OnTutorialShowing()
end

function ZO_Market_Shared:OnTutorialHidden()
end

function ZO_Market_Shared:RemoveActionLayerForTutorial()
    assert(false) -- must be overridden
end
function ZO_Market_Shared:RestoreActionLayerForTutorial()
    assert(false) -- must be overridden
end

function ZO_Market_Shared:GetMarketProductIds(categoryIndex, subCategoryIndex, index, ...)
    assert(false) -- must be overridden
end

function ZO_Market_Shared:GetLabeledGroupLabelTemplate()
    assert(false) -- must be overriden
end

function ZO_Market_Shared:RefreshActions()
    self:RefreshKeybinds() -- default behavior
end

--[[Search]]--
--------------
function ZO_Market_Shared:SearchStart(searchString)
    self.searchString = searchString
    StartMarketProductSearch(searchString)
end