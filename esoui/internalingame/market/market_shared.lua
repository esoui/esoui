ZO_MARKET_NAME = "Market"
ZO_MARKET_DISPLAY_LOADING_DELAY_MS = 500

ZO_MARKET_CATEGORY_TYPE_NONE = "none"
ZO_MARKET_CATEGORY_TYPE_FEATURED = "featured"
ZO_MARKET_CATEGORY_TYPE_ESO_PLUS = "esoPlus"
ZO_MARKET_CATEGORY_TYPE_CHAPTER_UPGRADE = "chapterUpgrade"
ZO_MARKET_CATEGORY_TYPE_ESO_PLUS_OFFERS = "esoPlusOffers"

ZO_MARKET_FEATURED_CATEGORY_INDEX = 0
ZO_MARKET_ESO_PLUS_CATEGORY_INDEX = -1
ZO_MARKET_CHAPTER_UPGRADE_CATEGORY_INDEX = -2
ZO_MARKET_ESO_PLUS_OFFERS_CATEGORY_INDEX = -3

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
    -- Special buckets to contain MarketProducts in lieu of a Category/Subcategory
    self.featuredProducts = {}
    self.limitedTimedOfferProducts = {}
    self.dlcProducts = {}
    self.marketProducts = {} -- An "All" bucket

    self.searchResults = {}
    self.searchString = ""
    self.isSearching = false

    self:CreateMarketScene()
    self:RegisterSceneStateChangeCallback()
    self:InitializeCategories()
    self:InitializeMarketList()
    self:InitializeKeybindDescriptors()
    self:InitializeFilters()
    self.control:RegisterForEvent(EVENT_TUTORIAL_HIDDEN, function()
        if self.currentTutorial then
            self.currentTutorial = nil
            self:RestoreActionLayerForTutorial()
            self:OnTutorialHidden()
        end
    end)
    self.refreshCategories = false

    self:RegisterForMarketSingletonCallbacks()
end

function ZO_Market_Shared:RegisterForMarketSingletonCallbacks()
    -- events we need to react to even if we are hiding
    ZO_MARKET_MANAGER:RegisterCallback("OnMarketStateUpdated", function(...) self:OnMarketStateUpdated(...) end)
    ZO_MARKET_MANAGER:RegisterCallback("OnMarketProductAvailabilityUpdated", function(...) self:OnMarketProductAvailabilityUpdated(...) end)
    ZO_MARKET_MANAGER:RegisterCallback("OnMarketSearchResultsReady", function(...) self:OnMarketSearchResultsReady(...) end)
    ZO_MARKET_MANAGER:RegisterCallback("OnMarketSearchResultsCanceled", function(...) self:OnMarketSearchResultsCanceled(...) end)

    -- events we only need to react to if we're showing
    ZO_MARKET_MANAGER:RegisterCallback("OnMarketPurchaseResult", function(...) if self:IsShowing() then self:OnMarketPurchaseResult(...) end end)
    ZO_MARKET_MANAGER:RegisterCallback("OnCollectiblesUnlockStateChanged", function(...) if self:IsShowing() then self:OnCollectiblesUnlockStateChanged(...) end end)
    ZO_MARKET_MANAGER:RegisterCallback("OnEsoPlusSubscriptionStatusChanged", function(...) if self:IsShowing() then self:OnEsoPlusSubscriptionStatusChanged(...) end end)
end

function ZO_Market_Shared:OnInitialInteraction()
    ZO_MARKET_MANAGER:RequestOpenMarket()
    SetSecureRenderModeEnabled(true)

    -- ensure that we are in the correct state
    local marketState = GetMarketState(MARKET_DISPLAY_GROUP_CROWN_STORE)
    if self.marketState ~= marketState then
        self:UpdateMarket(marketState)
    elseif marketState == MARKET_STATE_OPEN then
        self:UpdateCurrentCategory()
    end
end

function ZO_Market_Shared:OnEndInteraction()
    self.currentTutorial = nil
    self:ResetSearch()
    SetSecureRenderModeEnabled(false)
    OnMarketClose()
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

function ZO_Market_Shared:IsShowing()
    return self.marketScene:IsShowing()
end

function ZO_Market_Shared:ResetCategoryData()
    self.currentCategoryData = nil
end

function ZO_Market_Shared:OnMarketStateUpdated(displayGroup, marketState)
    if displayGroup == MARKET_DISPLAY_GROUP_CROWN_STORE then
        if marketState == MARKET_STATE_LOCKED or marketState == MARKET_STATE_UPDATING then
            self:FlagMarketCategoriesForRefresh()
        end

        if self:IsShowing() then
            self:ResetCategoryData()
            self:UpdateMarket(marketState)
        end
    end
end

function ZO_Market_Shared:OnMarketProductAvailabilityUpdated(displayGroup)
    if displayGroup == MARKET_DISPLAY_GROUP_CROWN_STORE then
        if self:IsShowing() then
            self:BuildCategories()
        else
            self:FlagMarketCategoriesForRefresh()
        end
    end
end

function ZO_Market_Shared:OnMarketPurchaseResult()
    self:UpdateCurrentCategory()
end

function ZO_Market_Shared:OnMarketSearchResultsReady(taskId)
    self.isSearching = false

    if taskId == self.searchTaskId and self:IsShowing() then
        self:UpdateSearchResults()
        self:UpdateMarket()
    else
        -- someone else performed a search or the search completed after we hid
        self:ClearSearchResults()
        self.refreshCategories = true
    end
end

function ZO_Market_Shared:OnMarketSearchResultsCanceled(taskId)
    if taskId == self.searchTaskId then
        self.isSearching = false
        self:ClearSearchResults()
        if self:IsShowing() then
            self:UpdateMarket()
        else
            self.refreshCategories = true
        end
    end
end

function ZO_Market_Shared:UpdateCurrentCategory()
    if self.currentCategoryData then
        if self.currentCategoryData.categoryIndex == ZO_MARKET_ESO_PLUS_CATEGORY_INDEX then
            self:RefreshEsoPlusPage()
        else
            self:RefreshProducts()
        end
    end
end

function ZO_Market_Shared:OnCollectiblesUnlockStateChanged()
    self:UpdateCurrentCategory()
end

function ZO_Market_Shared:OnShowMarketProduct(marketProductId)
    SCENE_MANAGER:Show("show_market")
    self:RequestShowMarketProduct(marketProductId)
end

function ZO_Market_Shared:OnShowMarketAndSearch(marketProductSearchString)
    SCENE_MANAGER:Show("show_market")
    self:RequestShowMarketWithSearchString(marketProductSearchString)
end

function ZO_Market_Shared:OnRequestPurchaseMarketProduct(marketProductId, presentationIndex, isGift)
    local marketProductData = ZO_MarketProductData:New(marketProductId, presentationIndex)
    if isGift then
        self:GiftMarketProduct(marketProductData)
    else
        self:PurchaseMarketProduct(marketProductData)
    end
end

function ZO_Market_Shared:OnShowFeaturedCategory()
    SCENE_MANAGER:Show("show_market")
    self:RequestShowCategory(ZO_MARKET_FEATURED_CATEGORY_INDEX)
end

function ZO_Market_Shared:OnShowEsoPlusPage()
    if IsInGamepadPreferredMode() then
        SCENE_MANAGER:Show("show_market")
    else
        SCENE_MANAGER:Show("show_esoPlus")
    end
    self:RequestShowCategory(ZO_MARKET_ESO_PLUS_CATEGORY_INDEX)
end

function ZO_Market_Shared:OnShowChapterUpgrade(chapterUpgradeId)
    SCENE_MANAGER:Show("show_market")
    self:RequestShowCategory(ZO_MARKET_CHAPTER_UPGRADE_CATEGORY_INDEX, chapterUpgradeId) -- the subcategory id for the chapter is the chapterUpdradeId
end

function ZO_Market_Shared:OnShowMarketProductCategory(marketProductCategoryId)
    SCENE_MANAGER:Show("show_market")
    self:RequestShowCategoryById(marketProductCategoryId)
end

function ZO_Market_Shared:OnEsoPlusSubscriptionStatusChanged()
    self:UpdateCurrentCategory()
end

function ZO_Market_Shared:OnShowBuyCrownsDialog()
    -- To be overridden
end

function ZO_Market_Shared:RequestShowMarket(openSource, openBehavior, additionalData)
    SetOpenMarketSource(openSource)
    if openBehavior == OPEN_MARKET_BEHAVIOR_NAVIGATE_TO_PRODUCT or openBehavior == OPEN_MARKET_BEHAVIOR_NAVIGATE_TO_OTHER_PRODUCT then
        self:OnShowMarketProduct(additionalData)
    elseif openBehavior == OPEN_MARKET_BEHAVIOR_SHOW_FEATURED_CATEGORY then
        self:OnShowFeaturedCategory()
    elseif openBehavior == OPEN_MARKET_BEHAVIOR_SHOW_ESO_PLUS_CATEGORY then
        self:OnShowEsoPlusPage()
    elseif openBehavior == OPEN_MARKET_BEHAVIOR_SHOW_CHAPTER_UPGRADE then
        self:OnShowChapterUpgrade(additionalData)
    elseif openBehavior == OPEN_MARKET_BEHAVIOR_SHOW_MARKET_PRODUCT_CATEGORY then
        self:OnShowMarketProductCategory(additionalData)
    end
end

function ZO_Market_Shared:UpdateMarket(marketState)
    self.marketState = marketState or GetMarketState(MARKET_DISPLAY_GROUP_CROWN_STORE)

    if self.marketState == MARKET_STATE_OPEN then
        self:OnMarketOpen()
    elseif self.marketState == MARKET_STATE_UNKNOWN or self.marketState == MARKET_STATE_UPDATING then
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

function ZO_Market_Shared:EndCurrentPreview()
    EndCurrentMarketPreview()
    self:RefreshActions()
end

function ZO_Market_Shared:OnMarketOpen()
    self:BuildCategories()
    self:ShowMarket(true)
end

function ZO_Market_Shared:OnCategorySelected(data)
    self:EndCurrentPreview()
    self:ClearLabeledGroups()

    self.currentCategoryData = data

    self:DisplayCategory(data)

    self:RefreshActions()
end

function ZO_Market_Shared:DisplayCategory(data)
    if data.type == ZO_MARKET_CATEGORY_TYPE_FEATURED then
        self:BuildFeaturedMarketProductList()
    elseif data.type == ZO_MARKET_CATEGORY_TYPE_NONE then
        self:BuildMarketProductList(data)
    end
end

function ZO_Market_Shared:FlagMarketCategoriesForRefresh()
    self.refreshCategories = true
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
            name = { tiebreaker = "stackCount", tieBreakerSortOrder = ZO_SORT_ORDER_DOWN },
            stackCount = {},
        }

    function ZO_Market_Shared:CompareMarketProducts(entry1, entry2)
        return ZO_TableOrderingFunction(entry1, entry2, "isBundle", MARKET_PRODUCT_SORT_KEYS, ZO_SORT_ORDER_DOWN)
    end
end

do
    local MARKET_PRODUCT_SORT_KEYS =
        {
            tierOrdering = { tiebreaker = "name", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
            name = { tiebreaker = "stackCount", tieBreakerSortOrder = ZO_SORT_ORDER_DOWN },
            stackCount = {},
        }

    function ZO_Market_Shared.CompareCrateMarketProducts(entry1, entry2)
        return ZO_TableOrderingFunction(entry1, entry2, "tierOrdering", MARKET_PRODUCT_SORT_KEYS, ZO_SORT_ORDER_DOWN)
    end
end

do
    local MARKET_PRODUCT_SORT_KEYS =
        {
            isBundle = { tiebreaker = "isValidForPlayer", tieBreakerSortOrder = ZO_SORT_ORDER_DOWN },
            isValidForPlayer = { tiebreaker = "name", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
            name = { tiebreaker = "stackCount", tieBreakerSortOrder = ZO_SORT_ORDER_DOWN },
            stackCount = {},
        }

    function ZO_Market_Shared.CompareBundleMarketProducts(entry1, entry2)
        return ZO_TableOrderingFunction(entry1, entry2, "isBundle", MARKET_PRODUCT_SORT_KEYS, ZO_SORT_ORDER_DOWN)
    end
end

-- ... is a list of MarketProductData
function ZO_Market_Shared:GetFeaturedProductPresentations(index, ...)
    if index >= 1 then
        local id = GetFeaturedMarketProductId(index)
        local productData = ZO_MarketProductData:New(id, ZO_FEATURED_PRESENTATION_INDEX)
        index = index - 1
        return self:GetFeaturedProductPresentations(index, productData, ...)
    end
    return ...
end

do
    local addedMarketProductsMapping = {}
    function ZO_Market_Shared.GetCrownCrateContentsProductInfo(marketProductId)
        ZO_ClearTable(addedMarketProductsMapping)
        local marketProducts = {}

        local crateId = GetMarketProductCrownCrateId(marketProductId)

        local crateTierIds = { GetCrownCrateTierIds(crateId) }
        for tierIndex, tierId in ipairs(crateTierIds) do
            local tierOrdering = GetCrownCrateTierOrdering(tierId)
            local tierDisplayName = GetCrownCrateTierDisplayName(tierId)
            local tierDisplayNameColor = nil
            if tierDisplayName == "" then
                tierDisplayName = nil
            else
                -- color only matters if we have a header to show
                tierDisplayNameColor = ZO_ColorDef:New(GetCrownCrateTierDisplayNameColor(tierId))
            end
            local numProducts = GetNumMarketProductsInCrownCrateTier(tierId)
            for productIndex = 1, numProducts do
                local productId = GetMarketProductIdFromCrownCrateTier(tierId, productIndex)
                if not addedMarketProductsMapping[productId] then
                    local productInfo =
                        {
                            productId = productId,
                            name = GetMarketProductDisplayName(productId),
                            stackCount = GetMarketProductStackCount(productId),
                            quality = GetMarketProductQuality(productId),
                            tierId = tierId,
                            tierOrdering = tierOrdering,
                            headerName = tierDisplayName,
                            headerColor = tierDisplayNameColor,
                        }
                    table.insert(marketProducts, productInfo)
                    addedMarketProductsMapping[productId] = true
                end
            end
        end

        return marketProducts
    end
end

function ZO_Market_Shared.GetMarketProductBundleChildProductInfo(marketProductId)
    local marketProducts = {}

    local numChildren = GetMarketProductNumChildren(marketProductId)
    if numChildren > 0 then
        for childIndex = 1, numChildren do
            local childMarketProductId = GetMarketProductChildId(marketProductId, childIndex)

            local productType = GetMarketProductType(childMarketProductId)
            local isBundle = productType == MARKET_PRODUCT_TYPE_BUNDLE
            local isValidForPlayer = true
            if productType == MARKET_PRODUCT_TYPE_COLLECTIBLE then
                local collectibleId = GetMarketProductCollectibleId(childMarketProductId)
                isValidForPlayer = IsCollectibleValidForPlayer(collectibleId)
            end

            local productInfo = {
                            productId = childMarketProductId,
                            name = GetMarketProductDisplayName(childMarketProductId),
                            stackCount = GetMarketProductStackCount(childMarketProductId),
                            isBundle = isBundle,
                            isValidForPlayer = isValidForPlayer,
                            quality = GetMarketProductQuality(childMarketProductId),
                        }
            table.insert(marketProducts, productInfo)
        end
    end

    return marketProducts
end

do
    local SERVICE_TOKEN =
    {
        buttonText = GetString(SI_MARKET_LOG_OUT_TO_CHARACTER_SELECT_KEYBIND_LABEL),
        transactionCompleteText = GetString(SI_MARKET_PURCHASE_SUCCESS_TEXT_WITH_TOKEN_USAGE),
        GoToUseProductLocation = function()
            SCENE_MANAGER:RequestShowLeaderBaseScene()
            Logout()
        end,
    }

    local CROWN_CRATE =
    {
        buttonText = GetString(SI_MARKET_OPEN_CROWN_CRATES_KEYBIND_LABEL),
        transactionCompleteText = GetString(SI_MARKET_PURCHASE_SUCCESS_TEXT_WITH_QUANTITY),
        visible = CanInteractWithCrownCratesSystem,
        enabled = function()
            local isAllowed, errorStringId = IsPlayerAllowedToOpenCrownCrates()
            return isAllowed, GetString(errorStringId)
        end,
        GoToUseProductLocation = function()
            if IsInGamepadPreferredMode() then
                SCENE_MANAGER:Show("crownCrateGamepad")
            else
                SCENE_MANAGER:Show("crownCrateKeyboard")
            end
        end,
    }

    local ESO_PLUS =
    {
        transactionCompleteTitleText = GetString(SI_MARKET_PURCHASE_FREE_TRIAL_SUCCESS_TITLE_TEXT),
        transactionCompleteText = GetString(SI_MARKET_PURCHASE_FREE_TRIAL_SUCCESS_TEXT),
        visible = function() return false end,
    }

    function ZO_Market_Shared.GetUseProductInfo(marketProductData)
        if marketProductData:ContainsServiceToken() then
            return SERVICE_TOKEN
        elseif GetCurrentZoneHouseId() ~= 0 and marketProductData:GetFurnitureDataId() ~= 0
            and HasAnyEditingPermissionsForCurrentHouse() and GetHousingEditorMode() ~= HOUSING_EDITOR_MODE_DISABLED then
            local furniturePlacementInfo =
            {
                buttonText = GetString(SI_MARKET_PLACE_IN_HOUSE_KEYBIND_LABEL),
                transactionCompleteText = GetString(SI_MARKET_PURCHASE_SUCCESS_TEXT),
                GoToUseProductLocation = function()
                    if HousingEditorCreateFurnitureForPlacementFromMarketProduct(marketProductData:GetId()) then
                        SCENE_MANAGER:RequestShowLeaderBaseScene()
                    end
                end,
            }
            return furniturePlacementInfo
        else
            local marketProductType = marketProductData:GetMarketProductType()
            if marketProductType == MARKET_PRODUCT_TYPE_CROWN_CRATE then
                return CROWN_CRATE
            elseif marketProductType == MARKET_PRODUCT_TYPE_HOUSING then
                local marketProductHouseId = marketProductData:GetHouseId()
                local houseInfo =
                {
                    buttonText = GetString(SI_MARKET_TRAVEL_TO_HOUSE_KEYBIND_LABEL),
                    transactionCompleteText = GetString(SI_MARKET_PURCHASE_SUCCESS_TEXT),
                    GoToUseProductLocation = function()
                        RequestJumpToHouse(marketProductHouseId)
                        SCENE_MANAGER:RequestShowLeaderBaseScene()
                    end,
                }

                return houseInfo
            elseif marketProductType == MARKET_PRODUCT_TYPE_INSTANT_UNLOCK then
                local instantUnlockType = marketProductData:GetInstantUnlockType()
                if instantUnlockType == INSTANT_UNLOCK_ESO_PLUS then
                    return ESO_PLUS
                end
            end
        end
    end

    function ZO_Market_Shared.HasUseProductInfo(marketProductData)
        return ZO_Market_Shared.GetUseProductInfo(marketProductData) ~= nil
    end

    function ZO_Market_Shared.GoToUseProductLocation(marketProductData)
        local useProductInfo = ZO_Market_Shared.GetUseProductInfo(marketProductData)
        if useProductInfo then
            useProductInfo.GoToUseProductLocation()
        end
    end
end

function ZO_Market_Shared:GetCategoryIndices(data, parentData)
    if parentData then
        return parentData.categoryIndex, data.categoryIndex
    end

    return data.categoryIndex
end

function ZO_Market_Shared:GetPreviewState()
    local isPreviewing = IsCurrentlyPreviewing()
    local canPreview = false
    local isActivePreview = false

    local marketProduct = self.selectedMarketProduct
    if marketProduct ~= nil then -- User is hovering over a MarketProduct
        canPreview = marketProduct:HasPreview() and IsCharacterPreviewingAvailable()

        if isPreviewing and marketProduct:IsActivelyPreviewing() then
            isActivePreview = true
        end
    end

    return isPreviewing, canPreview, isActivePreview
end

function ZO_Market_Shared:IsReadyToPreview()
    local _, canPreview, isActivePreview = self:GetPreviewState()
    return canPreview and not isActivePreview
end

function ZO_Market_Shared:TriggerCrownGemTutorial()
    if self.marketState == MARKET_STATE_OPEN then
        self:ShowTutorial(TUTORIAL_TRIGGER_CROWN_CRATE_UI_OPENED)
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
    self:UpdateMarketCurrencies()

    if self.queuedSearchString then
        self:RequestShowMarketWithSearchString(self.queuedSearchString)
    end
end

function ZO_Market_Shared:OnShown()
    if self.marketState == MARKET_STATE_OPEN then
        self:ShowTutorial(TUTORIAL_TRIGGER_MARKET_OPENED)
    end
end

function ZO_Market_Shared:OnHiding()
    --clear the current tutorial when hiding so we don't push an extra action layer
    self.currentTutorial = nil

    self:EndCurrentPreview()
end

function ZO_Market_Shared:ClearLabeledGroups()
    ZO_ClearNumericallyIndexedTable(self.featuredProducts)
    ZO_ClearNumericallyIndexedTable(self.limitedTimedOfferProducts)
    ZO_ClearNumericallyIndexedTable(self.dlcProducts)
    ZO_ClearNumericallyIndexedTable(self.marketProducts)
end

do
    local NO_SUBCATEGORY = nil
    function ZO_Market_Shared:GetCategoryDataForMarketProduct(productId)
        for categoryIndex = 1, GetNumMarketProductCategories(MARKET_DISPLAY_GROUP_CROWN_STORE) do
            local _, numSubCategories, numMarketProducts = GetMarketProductCategoryInfo(MARKET_DISPLAY_GROUP_CROWN_STORE, categoryIndex)
            for marketProductIndex = 1, numMarketProducts do
                local id = GetMarketProductPresentationIds(MARKET_DISPLAY_GROUP_CROWN_STORE, categoryIndex, NO_SUBCATEGORY, marketProductIndex)
                if id == productId then
                    return self:GetCategoryData(categoryIndex, NO_SUBCATEGORY)
                end
            end
            for subcategoryIndex = 1, numSubCategories do
                local _, numSubCategoryMarketProducts = GetMarketProductSubCategoryInfo(MARKET_DISPLAY_GROUP_CROWN_STORE, categoryIndex, subcategoryIndex)
                for marketProductIndex = 1, numSubCategoryMarketProducts do
                    local id = GetMarketProductPresentationIds(MARKET_DISPLAY_GROUP_CROWN_STORE, categoryIndex, subcategoryIndex, marketProductIndex)
                    if id == productId then
                        return self:GetCategoryData(categoryIndex, subcategoryIndex)
                    end
                end
            end
        end
    end
end

function ZO_Market_Shared:ShowMarket(show)
    self:ProcessQueuedNavigation()

    if self.queuedSearchString then
        self:RequestShowMarketWithSearchString(self.queuedSearchString)
    end
end

function ZO_Market_Shared:SetQueuedMarketProductId(marketProductId)
    self.queuedMarketProductId = marketProductId
end

function ZO_Market_Shared:ClearQueuedMarketProductId()
    self:SetQueuedMarketProductId(nil)
end

function ZO_Market_Shared:GetQueuedMarketProductId()
    return self.queuedMarketProductId
end

function ZO_Market_Shared:GetQueuedCategoryIndices()
    return self.queuedCategoryIndex, self.queuedSubcategoryIndex
end

function ZO_Market_Shared:SetQueuedCategoryIndices(categoryIndex, subcategoryIndex)
    self.queuedCategoryIndex = categoryIndex
    self.queuedSubcategoryIndex = subcategoryIndex
end

function ZO_Market_Shared:ClearQueuedCategoryIndices()
    self:SetQueuedCategoryIndices(nil, nil)
end

function ZO_Market_Shared:SetQueuedCategoryId(categoryId)
    self.queuedCategoryId = categoryId
end

function ZO_Market_Shared:ClearQueuedCategoryId()
    self:SetQueuedCategoryId(nil)
end

function ZO_Market_Shared:ProcessQueuedNavigation()
    if self.queuedCategoryId then
        self:RequestShowCategoryById(self.queuedCategoryId)
        self:ClearQueuedCategoryIndices()
    elseif self.queuedCategoryIndex then
        self:RequestShowCategory(self.queuedCategoryIndex, self.queuedSubcategoryIndex)
        -- A request to go to a specific category overrides a request to go to a specific Market Product
        self:ClearQueuedMarketProductId()
    elseif self.queuedMarketProductId then
        self:RequestShowMarketProduct(self.queuedMarketProductId)
    end
end

function ZO_Market_Shared:UpdateMarketCurrencies()
    self:UpdateCrownBalance(GetPlayerCrowns())
    self:UpdateCrownGemBalance(GetPlayerCrownGems())
end

function ZO_Market_Shared.PreviewMarketProduct(previewObject, marketProductId)
    local previewInEmptyWorld = false
    local furnitureId = GetMarketProductFurnitureDataId(marketProductId)
    if furnitureId ~= 0 then
        local productType = GetMarketProductType(marketProductId)
        previewInEmptyWorld = productType == MARKET_PRODUCT_TYPE_ITEM
    end

    previewObject:SetPreviewInEmptyWorld(previewInEmptyWorld)
    previewObject:PreviewMarketProduct(marketProductId)
end

--[[ Functions to be overridden ]]--

function ZO_Market_Shared:OnHidden()
end

function ZO_Market_Shared:UpdateCrownBalance(amount)
end

function ZO_Market_Shared:UpdateCrownGemBalance(amount)
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

function ZO_Market_Shared:GetCategoryData(targetId)
end

function ZO_Market_Shared:RequestShowMarketWithSearchString(searchString)
end

function ZO_Market_Shared:ResetSearch()
end

function ZO_Market_Shared:PurchaseMarketProduct(marketProductData)
end

function ZO_Market_Shared:GiftMarketProduct(marketProductData)
end

function ZO_Market_Shared:BuildFeaturedMarketProductList()
    assert(false) -- must be overridden
end

function ZO_Market_Shared:BuildMarketProductList(data)
    assert(false) -- must be overridden
end

function ZO_Market_Shared:RefreshEsoPlusPage()
end

function ZO_Market_Shared:RemoveActionLayerForTutorial()
    assert(false) -- must be overridden
end
function ZO_Market_Shared:RestoreActionLayerForTutorial()
    assert(false) -- must be overridden
end

function ZO_Market_Shared:RefreshActions()
    self:RefreshKeybinds() -- default behavior
end

function ZO_Market_Shared:RequestShowMarketProduct(id)
    assert(false) -- must be overridden
end

function ZO_Market_Shared:RequestShowCategory(categoryIndex, subcategoryIndex)
    assert(false) -- must be overridden
end

function ZO_Market_Shared:RequestShowCategoryById(categoryId)
    assert(false) -- must be overridden
end

function ZO_Market_Shared:CanPreviewMarketProductPreviewType(previewType)
    return true
end

--[[Search]]--
--------------
function ZO_Market_Shared:SearchStart(searchString)
    if searchString ~= self.searchString then
        self.searchString = searchString
        self.searchTaskId = StartMarketProductSearch(MARKET_DISPLAY_GROUP_CROWN_STORE, searchString)
        self.isSearching = self.searchTaskId ~= nil
        if not self.isSearching then
            -- the search never started (probably because we use too short of a search string)
            self:OnMarketSearchResultsCanceled(self.searchTaskId)
        end
    end
end

function ZO_Market_Shared:HasValidSearchString()
    return zo_strlen(self.searchString) > 1
end

function ZO_Market_Shared:IsSearching()
    return self.isSearching
end

function ZO_Market_Shared:ClearSearchResults()
    ZO_ClearTable(self.searchResults)
end

function ZO_Market_Shared:UpdateSearchResults()
    self:ClearSearchResults()

    local numResults = GetNumMarketProductSearchResults()
    for i = 1, numResults do
        local categoryIndex, subcategoryIndex, productIndex = GetMarketProductSearchResult(i)
        if self:ShouldAddSearchResult(categoryIndex, subcategoryIndex, productIndex) then
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

function ZO_Market_Shared:ShouldAddSearchResult(categoryIndex, subcategoryIndex, productIndex)
    return true
end