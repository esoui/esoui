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

ZO_NO_MARKET_SUBCATEGORY = nil

--
--[[ Market Shared ]]--
--

ZO_Market_Shared = ZO_InitializingObject:Subclass()

function ZO_Market_Shared:Initialize(control, sceneName)
    self.control = control
    self.sceneName = sceneName

    -- Special buckets to contain MarketProducts in lieu of a Category/Subcategory
    self.featuredProducts = {}
    self.limitedTimedOfferProducts = {}
    self.dlcProducts = {}
    self.marketProducts = {} -- An "All" bucket

    self.searchResults = {}
    self.searchString = ""
    self.isSearching = false

    self.currentSlotPreviews = {}

    self:CreateMarketScene()
    self:RegisterSceneStateChangeCallback()
    self:InitializeCategories()
    self:InitializeMarketList()
    self:InitializeKeybindDescriptors()
    self:InitializeFilters()

    ZO_DIALOG_SYNC_OBJECT:SetHandler("OnShown", function()
        if self:IsShowing() then
            self:OnDialogShowing()
            self:RemoveActionLayerForDialog()
        end
    end, self.sceneName)

    ZO_DIALOG_SYNC_OBJECT:SetHandler("OnHidden", function()
        if self:IsShowing() then
            self:RestoreActionLayerForDialog()
            self:OnDialogHidden()
        end
    end, self.sceneName)

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
    OpenMarket(self:GetDisplayGroup())
    SetSecureRenderModeEnabled(true)

    -- ensure that we are in the correct state
    local marketState = GetMarketState(self:GetDisplayGroup())
    if self.marketState ~= marketState then
        self:UpdateMarket(marketState)
    elseif marketState == MARKET_STATE_OPEN then
        self:UpdateCurrentCategory()
    end
end

function ZO_Market_Shared:OnEndInteraction()
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
    if displayGroup == self:GetDisplayGroup() then
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
    if displayGroup == self:GetDisplayGroup() then
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
        elseif self.currentCategoryData.type == ZO_MARKET_CATEGORY_TYPE_CHAPTER_UPGRADE then
            self:RefreshChapterUpgradePage()
        else
            self:RefreshProducts()
        end
    end
end

function ZO_Market_Shared:OnCollectiblesUnlockStateChanged()
    self:UpdateCurrentCategory()
end

function ZO_Market_Shared:OnShowMarketProduct(marketProductId)
    internalassert(marketProductId ~= 0, "OnShowMarketProduct called with market product id: 0")

    local useCrownStore = IsInGamepadPreferredMode() -- The Crown Store handles requests for all Gamepad products.
    useCrownStore = useCrownStore or
        (DoesAnyMarketProductPresentationMatchFilter(marketProductId, MARKET_PRODUCT_FILTER_TYPE_COST_CROWNS) or
         DoesAnyMarketProductPresentationMatchFilter(marketProductId, MARKET_PRODUCT_FILTER_TYPE_COST_CROWN_GEMS))

    if useCrownStore then
        -- The Crown Store processes requests for both Keyboard Crown and Crown Gem products and all Gamepad products.
        SCENE_MANAGER:Show("show_market")
        self:RequestShowMarketProduct(marketProductId)
    elseif DoesAnyMarketProductPresentationMatchFilter(marketProductId, MARKET_PRODUCT_FILTER_TYPE_COST_ENDEAVOR_SEALS) then
        -- Keyboard Seals of Endeavor Store products.
        SCENE_MANAGER:Show(ENDEAVOR_SEAL_STORE_KEYBOARD.sceneName)
        ENDEAVOR_SEAL_STORE_KEYBOARD:RequestShowMarketProduct(marketProductId)
    else
        -- If we couldn't figure out where to go, just fall back to opening the crown store
        -- This can happen if we haven't fully initialized crown store data, meaning that DoesAnyMarketProductPresentationMatchFilter may not be able to give us the right answer
        -- If the market product is listed for seals of endeavor only, this will fail to navigate to it, but should work in all other cases
        SCENE_MANAGER:Show("show_market")
        self:RequestShowMarketProduct(marketProductId)
    end
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
    self.marketState = marketState or GetMarketState(self:GetDisplayGroup())

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
    self:ClearAllCurrentSlotPreviews()
    self:RefreshActions()
end

function ZO_Market_Shared:IsMarketEmpty()
    return self.isMarketEmpty
end

function ZO_Market_Shared:SetIsMarketEmpty(empty)
    self.isMarketEmpty = empty
end

function ZO_Market_Shared:OnMarketOpen()
    self:SetIsMarketEmpty(false)
    self:BuildCategories()

    if self:IsMarketEmpty() then
        self:ShowMarket(false)
        self:OnMarketLocked()
    else
        self:ShowMarket(true)
    end
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
            isRewardEntry = { tiebreaker = "isBundle", tieBreakerSortOrder = ZO_SORT_ORDER_DOWN },
            isBundle = { tiebreaker = "isValidForPlayer", tieBreakerSortOrder = ZO_SORT_ORDER_DOWN },
            isValidForPlayer = { tiebreaker = "headerName", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
            headerName = { tiebreaker = "name", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
            name = { tiebreaker = "stackCount", tieBreakerSortOrder = ZO_SORT_ORDER_DOWN },
            stackCount = { isNumeric = true },
        }

    function ZO_Market_Shared.CompareBundleMarketProducts(entry1, entry2)
        return ZO_TableOrderingFunction(entry1, entry2, "isRewardEntry", MARKET_PRODUCT_SORT_KEYS, ZO_SORT_ORDER_UP)
    end
end

function ZO_Market_Shared:HasNewFeaturedMarketProducts()
    local REQUIRED_FILTER_TYPES = MARKET_PRODUCT_FILTER_TYPE_FEATURED + MARKET_PRODUCT_FILTER_TYPE_NEW
    return DoesFilteredMarketProductExist(self:GetDisplayGroup(), REQUIRED_FILTER_TYPES, self.featuredMarketProductFiltersMask)
end

function ZO_Market_Shared:DoesFeaturedMarketProductExist()
    return DoesFilteredMarketProductExist(self:GetDisplayGroup(), MARKET_PRODUCT_FILTER_TYPE_FEATURED, self.featuredMarketProductFiltersMask)
end

function ZO_Market_Shared:GetFeaturedProductPresentations()
    local products = {}
    local displayGroup = self:GetDisplayGroup()
    local NO_PRODUCT_ID = nil
    local NO_ALL_FILTER_TYPE = nil
    for productId, presentationIndex in ZO_GetNextFilteredMarketProductIterFunction(displayGroup, MARKET_PRODUCT_FILTER_TYPE_FEATURED, self.featuredMarketProductFiltersMask) do
        local productData = ZO_MarketProductData:New(productId, presentationIndex)
        table.insert(products, productData)
    end

    return products
end

-- filterTypeList is an array of MARKET_PRODUCT_FILTER_TYPE flag combinations
function ZO_Market_Shared:DoesMarketProductMatchAnyFilter(id, presentationIndex, filterTypeList)
    if filterTypeList and #filterTypeList > 0 then
        for _, filterType in ipairs(filterTypeList) do
            if DoesMarketProductMatchFilter(id, presentationIndex, filterType) then
                return true
            end
        end
        return false
    else
        local NO_FILTER = 0
        return DoesMarketProductMatchFilter(id, presentationIndex, NO_FILTER)
    end
end

function ZO_Market_Shared:DoesCategoryContainFilteredProducts(displayGroup, topLevelIndex, categoryIndex, filterTypeList)
    if filterTypeList and #filterTypeList > 0 then
        for _, filterType in ipairs(filterTypeList) do
            if DoesMarketProductCategoryContainFilteredProducts(displayGroup, topLevelIndex, categoryIndex, filterType) then
                return true
            end
        end
        return false
    else
        local NO_FILTER = 0
        return DoesMarketProductCategoryContainFilteredProducts(displayGroup, topLevelIndex, categoryIndex, NO_FILTER)
    end
end

function ZO_Market_Shared:DoesCategoryOrSubcategoriesContainFilteredProducts(displayGroup, topLevelIndex, categoryIndex, filterTypeList)
    if filterTypeList and #filterTypeList > 0 then
        for _, filterType in ipairs(filterTypeList) do
            if DoesMarketProductCategoryOrSubcategoriesContainFilteredProducts(displayGroup, topLevelIndex, categoryIndex, filterType) then
                return true
            end
        end
        return false
    else
        local NO_FILTER = 0
        return DoesMarketProductCategoryOrSubcategoriesContainFilteredProducts(displayGroup, topLevelIndex, categoryIndex, NO_FILTER)
    end
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
                    local displayQuality = GetMarketProductDisplayQuality(productId)
                    local productInfo =
                        {
                            productId = productId,
                            name = GetMarketProductDisplayName(productId),
                            stackCount = GetMarketProductStackCount(productId),
                            displayQuality = displayQuality,
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

    if numChildren == 0 then
        return marketProducts
    end

    for childIndex = 1, numChildren do
        local childMarketProductId = GetMarketProductChildId(marketProductId, childIndex)
        local productType = GetMarketProductType(childMarketProductId)
        local productName = GetMarketProductDisplayName(childMarketProductId)
        local productStackCount = GetMarketProductStackCount(childMarketProductId)
        local productDisplayQuality = GetMarketProductDisplayQuality(childMarketProductId)
        local productRewardListId = GetMarketProductItemRewardListId(childMarketProductId)

        if productRewardListId == 0 then
            local isBundle = false
            local isValidForPlayer = true
            if productType == MARKET_PRODUCT_TYPE_BUNDLE then
                isBundle = true
            elseif productType == MARKET_PRODUCT_TYPE_COLLECTIBLE then
                local collectibleId = GetMarketProductCollectibleId(childMarketProductId)
                isValidForPlayer = IsCollectibleValidForPlayer(collectibleId)
            end

            -- Add a MarketProduct row.
            local productInfo =
            {
                displayQuality = productDisplayQuality,
                headerName = "",
                isBundle = isBundle,
                isRewardEntry = false,
                isValidForPlayer = isValidForPlayer,
                name = productName,
                productId = childMarketProductId,
                stackCount = productStackCount,
            }
            table.insert(marketProducts, productInfo)
        else
            -- GetAllRewardInfoForRewardList returns a table containing new ZO_Reward instances.
            local rewardInfoList = REWARDS_MANAGER:GetAllRewardInfoForRewardList(productRewardListId)
            local headerColor = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, productDisplayQuality))

            for _, rewardInfo in ipairs(rewardInfoList) do
                -- Add a RewardInfo row for each reward in this reward container.
                rewardInfo:SetDisplayFlags(REWARD_DISPLAY_FLAGS_FROM_CROWN_STORE_CONTAINER)
                rewardInfo.headerColor = headerColor
                rewardInfo.headerName = productName
                rewardInfo.isBundle = false
                rewardInfo.isRewardEntry = true
                rewardInfo.name = rewardInfo:GetFormattedName()
                rewardInfo.productId = childMarketProductId
                rewardInfo.stackCount = productStackCount

                if rewardInfo:GetRewardType() == REWARD_ENTRY_TYPE_COLLECTIBLE then
                    local collectibleId = GetCollectibleRewardCollectibleId(rewardInfo:GetRewardId())
                    rewardInfo.isValidForPlayer = IsCollectibleValidForPlayer(collectibleId)
                else
                    rewardInfo.isValidForPlayer = true
                end

                table.insert(marketProducts, rewardInfo)
            end
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
        elseif marketProductData:GetFurnitureDataId() ~= 0 and CanPlaceMarketProductInCurrentHouse(marketProductData:GetId()) then
            local furniturePlacementInfo =
            {
                buttonText = GetString(SI_MARKET_PLACE_IN_HOUSE_KEYBIND_LABEL),
                transactionCompleteText = GetString(SI_MARKET_PURCHASE_SUCCESS_TEXT),
                GoToUseProductLocation = function()
                    HousingEditorCreateFurnitureForPlacementFromMarketProduct(marketProductData:GetId())
                    SCENE_MANAGER:RequestShowLeaderBaseScene()
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
    local isPreviewToggleable = false

    local marketProduct = self.selectedMarketProduct
    if marketProduct ~= nil then -- User is hovering over a MarketProduct
        canPreview = marketProduct:HasPreview() and IsCharacterPreviewingAvailable()

        if isPreviewing and marketProduct:IsActivelyPreviewing() then
            isActivePreview = true
        end

        local collectibleType = select(4, GetMarketProductCollectibleInfo(marketProduct.productData:GetId()))
        isPreviewToggleable = collectibleType == COLLECTIBLE_CATEGORY_TYPE_OUTFIT_STYLE
    end

    return isPreviewing, canPreview, isActivePreview, isPreviewToggleable
end

function ZO_Market_Shared:IsReadyToPreview()
    local _, canPreview, isActivePreview, isPreviewToggleable = self:GetPreviewState()
    return canPreview and (not isActivePreview or isPreviewToggleable)
end

function ZO_Market_Shared:TriggerCrownGemTutorial()
    if self.marketState == MARKET_STATE_OPEN then
        TUTORIAL_MANAGER:ShowTutorial(TUTORIAL_TRIGGER_CROWN_CRATE_UI_OPENED)
    end
end

function ZO_Market_Shared:OnShowing()
    if self.queuedSearchString then
        self:RequestShowMarketWithSearchString(self.queuedSearchString)
    end
end

function ZO_Market_Shared:OnShown()
    if self.marketState == MARKET_STATE_OPEN then
        ZO_MARKET_MANAGER:SetActiveMarket(self)

        if self.marketOpenedTutorialTriggerType then
            TUTORIAL_MANAGER:ShowTutorial(self.marketOpenedTutorialTriggerType)
        else
            TUTORIAL_MANAGER:ShowTutorial(TUTORIAL_TRIGGER_MARKET_OPENED)
        end
    end
end

function ZO_Market_Shared:OnHiding()
    ZO_MARKET_MANAGER:OnActiveMarketHidden(self)

    self:EndCurrentPreview()
end

function ZO_Market_Shared:OnHidden()
    self:ClearQueuedCategoryId()
    self:ClearQueuedCategoryIndices()
    self:ClearQueuedMarketProductId()
end

function ZO_Market_Shared:ClearLabeledGroups()
    ZO_ClearNumericallyIndexedTable(self.featuredProducts)
    ZO_ClearNumericallyIndexedTable(self.limitedTimedOfferProducts)
    ZO_ClearNumericallyIndexedTable(self.dlcProducts)
    ZO_ClearNumericallyIndexedTable(self.marketProducts)
end

do
    function ZO_Market_Shared:GetCategoryDataForMarketProduct(productId)
        local displayGroup = self:GetDisplayGroup()
        for categoryIndex = 1, GetNumMarketProductCategories(displayGroup) do
            local _, numSubCategories, numMarketProducts = GetMarketProductCategoryInfo(displayGroup, categoryIndex)
            for marketProductIndex = 1, numMarketProducts do
                local id = GetMarketProductPresentationIds(displayGroup, categoryIndex, ZO_NO_MARKET_SUBCATEGORY, marketProductIndex)
                if id == productId then
                    return self:GetCategoryData(categoryIndex, ZO_NO_MARKET_SUBCATEGORY)
                end
            end
            for subcategoryIndex = 1, numSubCategories do
                local _, numSubCategoryMarketProducts = GetMarketProductSubCategoryInfo(displayGroup, categoryIndex, subcategoryIndex)
                for marketProductIndex = 1, numSubCategoryMarketProducts do
                    local id = GetMarketProductPresentationIds(displayGroup, categoryIndex, subcategoryIndex, marketProductIndex)
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
    self.queuedMarketProductId = marketProductId ~= 0 and marketProductId or nil
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

do
    local MAIN_WEAPONS =
    {
        [OUTFIT_SLOT_WEAPON_MAIN_HAND] = true,
        [OUTFIT_SLOT_WEAPON_OFF_HAND] = true,
        [OUTFIT_SLOT_WEAPON_TWO_HANDED] = true,
        [OUTFIT_SLOT_WEAPON_STAFF] = true,
        [OUTFIT_SLOT_WEAPON_BOW] = true,
        [OUTFIT_SLOT_SHIELD] = true,
    }

    local BACKUP_WEAPONS =
    {
        [OUTFIT_SLOT_WEAPON_MAIN_HAND_BACKUP] = true,
        [OUTFIT_SLOT_WEAPON_OFF_HAND_BACKUP] = true,
        [OUTFIT_SLOT_WEAPON_TWO_HANDED_BACKUP] = true,
        [OUTFIT_SLOT_WEAPON_STAFF_BACKUP] = true,
        [OUTFIT_SLOT_WEAPON_BOW_BACKUP] = true,
        [OUTFIT_SLOT_SHIELD_BACKUP] = true,
    }

    local function IsWeaponOutfitSlotActive(outfitSlot)
        local activeWeaponPair = GetActiveWeaponPairInfo()
        if activeWeaponPair == ACTIVE_WEAPON_PAIR_MAIN then
            return MAIN_WEAPONS[outfitSlot]
        else
            return BACKUP_WEAPONS[outfitSlot]
        end
    end

    local function GetPreferredOutfitSlotForStyle(collectibleData)
        if collectibleData.clearAction then
            return collectibleData.preferredOutfitSlot
        else
            local eligibleSlots = { GetEligibleOutfitSlotsForCollectible(collectibleData:GetId()) }
            if collectibleData:IsArmorStyle() then
                return eligibleSlots[1]
            else
                for _, outfitSlot in ipairs(eligibleSlots) do
                    if IsWeaponOutfitSlotActive(outfitSlot) then
                        return outfitSlot
                    end
                end
            end
        end
        return nil
    end

    function ZO_Market_Shared:IsPreviewingOutfitStyle(collectibleData)
        local preferredOutfitSlot = GetPreferredOutfitSlotForStyle(collectibleData)

        if preferredOutfitSlot then
            local currentPreviewDataForSlot = self.currentSlotPreviews[preferredOutfitSlot]
            local collectibleId = collectibleData.clearAction and 0 or collectibleData:GetId()
            if currentPreviewDataForSlot and currentPreviewDataForSlot.collectibleId == collectibleId then
                return true
            end
        end
        return false
    end

    function ZO_Market_Shared:PreviewOutfitStyle(collectibleId)
        local collectibleData = ZO_CollectibleData_Base:New()
        collectibleData:SetId(collectibleId)
        local preferredOutfitSlot = GetPreferredOutfitSlotForStyle(collectibleData)

        if preferredOutfitSlot and IsCharacterPreviewingAvailable() then
            if self:IsPreviewingOutfitStyle(collectibleData) then
                ClearOutfitSlotPreviewElementFromPreviewCollection(preferredOutfitSlot)
                ApplyChangesToPreviewCollectionShown()
                self.currentSlotPreviews[preferredOutfitSlot] = nil
                return
            end

            local DEFAULT_ITEM_MATERIAL_INDEX = 1
            AddOutfitSlotPreviewElementToPreviewCollection(preferredOutfitSlot, collectibleId, DEFAULT_ITEM_MATERIAL_INDEX)
            ApplyChangesToPreviewCollectionShown()
            self.currentSlotPreviews[preferredOutfitSlot] =
            {
                collectibleId = collectibleId,
            }
        end
    end

    function ZO_Market_Shared:HasAnyCurrentSlotPreviews()
        return NonContiguousCount(self.currentSlotPreviews) > 0
    end


    function ZO_Market_Shared:ClearAllCurrentSlotPreviews()
        for outfitSlot, _ in pairs(self.currentSlotPreviews) do
            ClearOutfitSlotPreviewElementFromPreviewCollection(outfitSlot)
        end
        ApplyChangesToPreviewCollectionShown()
        ZO_ClearTable(self.currentSlotPreviews)
    end
end

function ZO_Market_Shared.PreviewReward(previewObject, rewardId)
    local QUANTITY = 1
    local rewardInfo = REWARDS_MANAGER:GetInfoForReward(rewardId, QUANTITY)
    if not rewardInfo then
        return false
    end

    local previewInEmptyWorld = rewardInfo:GetRewardType() == REWARD_TYPE_ITEM
    previewObject:SetPreviewInEmptyWorld(previewInEmptyWorld)
    previewObject:PreviewReward(rewardId)
    return true
end

function ZO_Market_Shared:GetDisplayGroup()
    return self.displayGroup
end

function ZO_Market_Shared:SetDisplayGroup(displayGroup)
    self.displayGroup = displayGroup
end

--[[ Functions to be overridden ]]--

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

function ZO_Market_Shared:OnDialogShowing()
end

function ZO_Market_Shared:OnDialogHidden()
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

function ZO_Market_Shared:RefreshChapterUpgradePage()
    -- To be overridden
end

function ZO_Market_Shared:RemoveActionLayerForDialog()
    local actionLayerName = GetString(SI_KEYBINDINGS_LAYER_USER_INTERFACE_SHORTCUTS)
    if IsActionLayerActiveByName(actionLayerName) then
        RemoveActionLayerByName(actionLayerName)
        self.restoreActionLayerWhenDialogHides = true
    end
end

function ZO_Market_Shared:RestoreActionLayerForDialog()
    if self.restoreActionLayerWhenDialogHides then
        PushActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_USER_INTERFACE_SHORTCUTS))
        self.restoreActionLayerWhenDialogHides = nil
    end
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

--[[Search]]--
--------------
function ZO_Market_Shared:SearchStart(searchString)
    if searchString ~= self.searchString then
        self.searchString = searchString
        self.searchTaskId = StartMarketProductSearch(self:GetDisplayGroup(), searchString)
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

    local searchResults = self.searchResults
    local numResults = GetNumMarketProductSearchResults()
    for resultIndex = 1, numResults do
        local categoryIndex, subcategoryIndex, productIndex = GetMarketProductSearchResult(resultIndex)
        if self:ShouldAddSearchResult(categoryIndex, subcategoryIndex, productIndex) then
            local categoryResults = searchResults[categoryIndex]
            if not categoryResults then
                categoryResults = {}
                searchResults[categoryIndex] = categoryResults
            end

            local effectiveSubcategory = subcategoryIndex or "root"
            local subcategoryResults = categoryResults[effectiveSubcategory]
            if not subcategoryResults then
                subcategoryResults = {}
                categoryResults[effectiveSubcategory] = subcategoryResults
            end

            subcategoryResults[productIndex] = true
        end
    end
end

function ZO_Market_Shared:ShouldAddSearchResult(categoryIndex, subcategoryIndex, productIndex)
    return true
end

function ZO_GetNextFilteredMarketProductIterFunction(displayGroup, matchAllFilterTypes, matchAnyFilterTypes)
    return function(_, lastProductId)
        return GetNextFilteredMarketProduct(lastProductId, displayGroup, matchAllFilterTypes, matchAnyFilterTypes)
    end
end

function ZO_ReturnToHousingEditorBrowseMode()
    zo_callLater(function()
        local mode = GetHousingEditorMode()
        if mode ~= HOUSING_EDITOR_MODE_BROWSE then
            -- Reopen the Housing Editor Browse menu.
            HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_SELECTION)
            HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_BROWSE)
        end
    end, 500)
end