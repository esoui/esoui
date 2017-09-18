ZO_MARKET_NAME = "Market"
ZO_MARKET_DISPLAY_LOADING_DELAY_MS = 500

ZO_MARKET_CATEGORY_TYPE_NONE = "none"
ZO_MARKET_CATEGORY_TYPE_FEATURED = "featured"
ZO_MARKET_CATEGORY_TYPE_ESO_PLUS = "esoPlus"

ZO_MARKET_FEATURED_CATEGORY_INDEX = 0
ZO_MARKET_ESO_PLUS_CATEGORY_INDEX = -1

ZO_MARKET_PREVIEW_TYPE_PREVIEWABLE = 0
ZO_MARKET_PREVIEW_TYPE_BUNDLE = 1
ZO_MARKET_PREVIEW_TYPE_CROWN_CRATE = 2
ZO_MARKET_PREVIEW_TYPE_BUNDLE_HIDES_CHILDREN = 3
ZO_MARKET_PREVIEW_TYPE_HOUSE = 4

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
    self:InitializeEvents()
    self:InitializePlatformErrors()
end

function Market_Singleton:InitializeEvents()
    local function OnMarketStateUpdated(eventId, displayGroup, marketState, ...)
        -- if we are locked/updating we need to inform both UIs that we need to refresh categories
        -- because otherwise only the active UI will refresh and the other will get into a bad state
        if displayGroup == MARKET_DISPLAY_GROUP_CROWN_STORE and (marketState == MARKET_STATE_LOCKED or marketState == MARKET_STATE_UPDATING) then
            -- keyboard market won't exist on consoles
            local keyboardMarket = SYSTEMS:GetKeyboardObject(ZO_MARKET_NAME)
            if keyboardMarket then
                keyboardMarket:FlagMarketCategoriesForRefresh()
            end

            local gamepadMarket = SYSTEMS:GetGamepadObject(ZO_MARKET_NAME)
            if gamepadMarket then
                gamepadMarket:FlagMarketCategoriesForRefresh()
            end
        end

        SYSTEMS:GetObject(ZO_MARKET_NAME):OnMarketStateUpdated(displayGroup, marketState, ...)
    end

    local function OnMarketPurchaseResult(eventId, ...)
        SYSTEMS:GetObject(ZO_MARKET_NAME):OnMarketPurchaseResult(...)
    end

    local function OnMarketSearchResultsReady(eventId)
        SYSTEMS:GetObject(ZO_MARKET_NAME):OnMarketSearchResultsReady()
    end

    local function OnMarketCollectibleUpdated(eventId, _, justUnlocked)
        SYSTEMS:GetObject(ZO_MARKET_NAME):OnCollectibleUpdated(justUnlocked)
    end

    local function OnMarketCollectiblesUpdated(eventId, numJustUnlocked)
        SYSTEMS:GetObject(ZO_MARKET_NAME):OnCollectiblesUpdated(numJustUnlocked)
    end

    local function OnShowMarketProduct(eventId, ...)
        SYSTEMS:GetObject(ZO_MARKET_NAME):OnShowMarketProduct(...)
    end

    local function OnShowMarketAndSearch(eventId, ...)
        SYSTEMS:GetObject(ZO_MARKET_NAME):OnShowMarketAndSearch(...)
    end

    local function OnRequestPurchaseMarketProduct(eventId, ...)
        SYSTEMS:GetObject(ZO_MARKET_NAME):OnRequestPurchaseMarketProduct(...)
    end

    local function OnShowBuyCrownsDialog(eventId)
        SYSTEMS:GetObject(ZO_MARKET_NAME):OnShowBuyCrownsDialog()
    end

    local function OnShowEsoPlusPage(eventId)
        SYSTEMS:GetObject(ZO_MARKET_NAME):OnShowEsoPlusPage()
    end

    local function OnEsoPlusSubscriptionStatusChanged(eventId)
        SYSTEMS:GetObject(ZO_MARKET_NAME):OnEsoPlusSubscriptionStatusChanged()
    end

    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_MARKET_STATE_UPDATED, OnMarketStateUpdated)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_MARKET_PURCHASE_RESULT, OnMarketPurchaseResult)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_MARKET_PRODUCT_SEARCH_RESULTS_READY, OnMarketSearchResultsReady)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_COLLECTIBLE_UPDATED, OnMarketCollectibleUpdated)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_COLLECTIBLES_UPDATED, OnMarketCollectibleUpdated)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_MARKET_SHOW_MARKET_PRODUCT, OnShowMarketProduct)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_MARKET_SHOW_MARKET_AND_SEARCH, OnShowMarketAndSearch)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_MARKET_REQUEST_PURCHASE_MARKET_PRODUCT, OnRequestPurchaseMarketProduct)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_MARKET_SHOW_BUY_CROWNS_DIALOG, OnShowBuyCrownsDialog)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_MARKET_SHOW_ESO_PLUS_PAGE, OnShowEsoPlusPage)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_ESO_PLUS_FREE_TRIAL_STATUS_CHANGED, OnEsoPlusSubscriptionStatusChanged)
end

function Market_Singleton:RequestOpenMarket()
    OpenMarket(MARKET_DISPLAY_GROUP_CROWN_STORE)
end

function Market_Singleton:InitializePlatformErrors()
    local consoleStoreName
    local platformServiceType = GetPlatformServiceType()

    if platformServiceType == PLATFORM_SERVICE_TYPE_PSN then
        consoleStoreName = GetString(SI_GAMEPAD_MARKET_PLAYSTATION_STORE)
    elseif platformServiceType == PLATFORM_SERVICE_TYPE_XBL then
        consoleStoreName = GetString(SI_GAMEPAD_MARKET_XBOX_STORE)
    elseif platformServiceType == PLATFORM_SERVICE_TYPE_STEAM then
        self.insufficientFundsMainText = zo_strformat(SI_MARKET_INSUFFICIENT_FUNDS_TEXT_STEAM, ZO_Currency_GetPlatformFormattedCurrencyIcon(CURT_CROWNS))
    else -- _ZOS and _DMM
        self.insufficientFundsMainText = zo_strformat(SI_MARKET_INSUFFICIENT_FUNDS_TEXT_WITH_LINK, ZO_Currency_GetPlatformFormattedCurrencyIcon(CURT_CROWNS), GetString(SI_MARKET_INSUFFICIENT_FUNDS_LINK_TEXT))
    end

    if consoleStoreName then -- PS4/XBox insufficient crowns and buy crowns dialog data
        self.insufficientFundsMainText = zo_strformat(SI_GAMEPAD_MARKET_INSUFFICIENT_FUNDS_TEXT_CONSOLE_LABEL, ZO_Currency_GetPlatformFormattedCurrencyIcon(CURT_CROWNS), consoleStoreName)
    end
end

function Market_Singleton:GetMarketProductPurchaseErrorInfo(marketProductId, presentationIndex)
    local expectedPurchaseResult = CouldPurchaseMarketProduct(marketProductId, presentationIndex)

    local name = GetMarketProductDisplayName(marketProductId)
    local mainText = ""
    local errorStrings = {}
    local promptBuyCrowns = false
    local allowContinue = true

    if DoesMarketProductHaveSubscriptionUnlockedAttachments(marketProductId) then
        table.insert(errorStrings, zo_strformat(SI_MARKET_BUNDLE_PARTS_UNLOCKED_TEXT, name))
    end

    if IsMarketProductPartiallyPurchased(marketProductId) then
        table.insert(errorStrings, GetString(SI_MARKET_BUNDLE_PARTS_OWNED_TEXT))
    end

    if expectedPurchaseResult == MARKET_PURCHASE_RESULT_ALREADY_COMPLETED_INSTANT_UNLOCK then
        allowContinue = false
        table.insert(errorStrings, zo_strformat(SI_MARKET_UNABLE_TO_PURCHASE_TEXT, GetString("SI_MARKETPURCHASABLERESULT", expectedPurchaseResult)))
    elseif expectedPurchaseResult == MARKET_PURCHASE_RESULT_NOT_ENOUGH_VC then
        allowContinue = false
        promptBuyCrowns = true
        table.insert(errorStrings, self.insufficientFundsMainText)
    elseif expectedPurchaseResult == MARKET_PURCHASE_RESULT_NOT_ENOUGH_CROWN_GEMS then
        allowContinue = false
        table.insert(errorStrings, zo_strformat(SI_MARKET_UNABLE_TO_PURCHASE_TEXT, GetString("SI_MARKETPURCHASABLERESULT", expectedPurchaseResult)))
    elseif expectedPurchaseResult == MARKET_PURCHASE_RESULT_NOT_ENOUGH_ROOM then
        local slotsRequired = GetSpaceNeededToPurchaseMarketProduct(marketProductId)
        allowContinue = false
        table.insert(errorStrings, zo_strformat(SI_MARKET_INVENTORY_FULL_TEXT, slotsRequired))
    end

    for i = 1, #errorStrings do
        if i == 1 then
            mainText = errorStrings[i]
        else
            mainText = mainText .. "\n\n" .. errorStrings[i]
        end
    end

    local dialogParams = { 
                            titleParams = { name }, 
                            mainTextParams = { mainText }
                         }
    local hasErrors = #errorStrings > 0

    return hasErrors, dialogParams, promptBuyCrowns, allowContinue
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

    -- Special buckets to contain MarketProducts in lieu of a Category/Subcategory
    -- If you add a new bucket, make sure to update all the places that used them
    -- such as GamepadMarket:GetCurrentCategoryMarketProductInfoById or Market:GetMarketProductInfo
    self.featuredProducts = {}
    self.limitedTimedOfferProducts = {}
    self.dlcProducts = {}
    self.marketProducts = {} -- An "All" bucket

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
    self:UpdateMarketCurrencies()
    self.control:RegisterForEvent(EVENT_TUTORIAL_HIDDEN, function()
        if self.currentTutorial then
            self.currentTutorial = nil
            self:RestoreActionLayerForTutorial()
            self:OnTutorialHidden()
        end
    end)
    self.refreshCategories = false
end

function ZO_Market_Shared:OnInitialInteraction()
    ZO_MARKET_SINGLETON:RequestOpenMarket()
    SetSecureRenderModeEnabled(true)

    -- ensure that we are in the correct state
    if self.marketState ~= GetMarketState(MARKET_DISPLAY_GROUP_CROWN_STORE) then
        self:UpdateMarket()
    elseif self.marketState == MARKET_STATE_OPEN then
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

function ZO_Market_Shared:ResetCategoryData()
    self.currentCategoryData = nil
end

function ZO_Market_Shared:OnMarketStateUpdated(displayGroup, marketState)
    if displayGroup == MARKET_DISPLAY_GROUP_CROWN_STORE then
        self:ResetCategoryData()
        self:UpdateMarket(marketState)
    end
end

function ZO_Market_Shared:OnMarketPurchaseResult()
    self:UpdateCurrentCategory()
end

function ZO_Market_Shared:OnMarketSearchResultsReady()
    self:UpdateSearchResults()
    self:UpdateMarket()
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

function ZO_Market_Shared:OnCollectibleUpdated(justUnlocked)
    if justUnlocked then
        self:UpdateCurrentCategory()
    end
end

function ZO_Market_Shared:OnCollectiblesUpdated(numJustUnlocked)
    if numJustUnlocked > 0 then
        self:UpdateCurrentCategory()
    end
end

function ZO_Market_Shared:OnShowMarketProduct(marketProductId)
    SCENE_MANAGER:Show("show_market")
    self:RequestShowMarketProduct(marketProductId)
end

function ZO_Market_Shared:OnShowMarketAndSearch(marketProductSearchString)
    SCENE_MANAGER:Show("show_market")
    self:RequestShowMarketWithSearchString(marketProductSearchString)
end

function ZO_Market_Shared:OnRequestPurchaseMarketProduct(marketProductId, presentationIndex)
    self:PurchaseMarketProduct(marketProductId, presentationIndex)
end

function ZO_Market_Shared:OnShowEsoPlusPage()
    SCENE_MANAGER:Show("show_market")
    self:RequestShowCategory(ZO_MARKET_ESO_PLUS_CATEGORY_INDEX)
end

function ZO_Market_Shared:OnEsoPlusSubscriptionStatusChanged()
    self:UpdateCurrentCategory()
end

function ZO_Market_Shared:OnShowBuyCrownsDialog()
    -- To be overridden
end

function ZO_Market_Shared:RequestShowMarket(openSource, openBehavior, targetMarketProductId)
    SetOpenMarketSource(openSource)
    if openBehavior == OPEN_MARKET_BEHAVIOR_NAVIGATE_TO_PRODUCT or openBehavior == OPEN_MARKET_BEHAVIOR_NAVIGATE_TO_OTHER_PRODUCT then
        self:OnShowMarketProduct(targetMarketProductId)
    elseif openBehavior == OPEN_MARKET_BEHAVIOR_SHOW_FEATURED_CATEGORY then
        SCENE_MANAGER:Show("show_market")
        self:RequestShowCategory(ZO_MARKET_FEATURED_CATEGORY_INDEX)
    elseif openBehavior == OPEN_MARKET_BEHAVIOR_SHOW_ESO_PLUS_CATEGORY then
        self:OnShowEsoPlusPage()
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
    
    if data.type == ZO_MARKET_CATEGORY_TYPE_FEATURED then
        self:BuildFeaturedMarketProductList()
    elseif data.type == ZO_MARKET_CATEGORY_TYPE_ESO_PLUS then
        self:DisplayEsoPlusOffer()
    else
        self:BuildMarketProductList(data)
    end

    self:RefreshActions()
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

do
    -- ... is a list of tables containing product ids and presentationIndexes
    local function GetFeaturedProductIds(index, ...)
        if index >= 1 then
            local presentationInfo =
                {
                    id = GetFeaturedMarketProductId(index),
                    presentationIndex = ZO_FEATURED_PRESENTATION_INDEX,
                }
            index = index - 1
            return GetFeaturedProductIds(index, presentationInfo, ...)
        end
        return ...
    end

    function ZO_Market_Shared:BuildFeaturedMarketProductList()
        local numFeaturedMarketProducts = GetNumFeaturedMarketProducts()
        local marketProductPresentations = { GetFeaturedProductIds(numFeaturedMarketProducts) }
        self:LayoutMarketProducts(marketProductPresentations)
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
        GoToUseProductLocation = Logout,
    }

    local CROWN_CRATE =
    {
        buttonText = GetString(SI_MARKET_OPEN_CROWN_CRATES_KEYBIND_LABEL),
        transactionCompleteText = GetString(SI_MARKET_PURCHASE_SUCCESS_TEXT_WITH_QUANTITY),
        visible = CanInteractWithCrownCratesSystem,
        enabled = function()
            local isAllowed, errorStringId = IsPlayerAllowedToOpenCrownCrates()
            --Internal ingame doesn't have access to ZO_Alert
            return isAllowed
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

    function ZO_Market_Shared.GetUseProductInfo(marketProductId)
        if DoesMarketProductContainServiceToken(marketProductId) then
            return SERVICE_TOKEN
        elseif GetCurrentZoneHouseId() ~= 0 and GetMarketProductFurnitureDataId(marketProductId) ~= 0
            and HasAnyEditingPermissionsForCurrentHouse() and GetHousingEditorMode() ~= HOUSING_EDITOR_MODE_DISABLED then
            local furniturePlacementInfo =
            {
                buttonText = GetString(SI_MARKET_PLACE_IN_HOUSE_KEYBIND_LABEL),
                transactionCompleteText = GetString(SI_MARKET_PURCHASE_SUCCESS_TEXT),
                GoToUseProductLocation = function()
                    if HousingEditorCreateFurnitureForPlacementFromMarketProduct(marketProductId) then
                        ShowRemoteBaseScene()
                    end
                end,
            }
            return furniturePlacementInfo
        else
            local marketProductType = GetMarketProductType(marketProductId)
            if marketProductType == MARKET_PRODUCT_TYPE_CROWN_CRATE then
                return CROWN_CRATE
            elseif marketProductType == MARKET_PRODUCT_TYPE_HOUSING then
                local marketProductHouseId = GetMarketProductHouseId(marketProductId)
                local houseInfo =
                {
                    buttonText = GetString(SI_MARKET_TRAVEL_TO_HOUSE_KEYBIND_LABEL),
                    transactionCompleteText = GetString(SI_MARKET_PURCHASE_SUCCESS_TEXT),
                    GoToUseProductLocation = function()
                        RequestJumpToHouse(marketProductHouseId)
                        ShowRemoteBaseScene()
                    end,
                }

                return houseInfo
            elseif marketProductType == MARKET_PRODUCT_TYPE_INSTANT_UNLOCK then
                local instantUnlockType = GetMarketProductInstantUnlockType(marketProductId)
                if instantUnlockType == MARKET_INSTANT_UNLOCK_ESO_PLUS then
                    return ESO_PLUS
                end
            end
        end
    end

    function ZO_Market_Shared.HasUseProductInfo(marketProductId)
        return ZO_Market_Shared.GetUseProductInfo(marketProductId) ~= nil
    end

    function ZO_Market_Shared.GoToUseProductLocation(marketProductId)
        local useProductInfo = ZO_Market_Shared.GetUseProductInfo(marketProductId)
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

function ZO_Market_Shared:BuildMarketProductList(data)
    local parentData = data.parentData
    local categoryIndex, subCategoryIndex = self:GetCategoryIndices(data, parentData)

    local finalSubcategoryIndex = subCategoryIndex
    if data.isFakedSubcategory then
        finalSubcategoryIndex = nil
    end

    local numMarketProducts
    if finalSubcategoryIndex then
        numMarketProducts = select(2, GetMarketProductSubCategoryInfo(MARKET_DISPLAY_GROUP_CROWN_STORE, categoryIndex, subCategoryIndex))
    else
        numMarketProducts = select(3, GetMarketProductCategoryInfo(MARKET_DISPLAY_GROUP_CROWN_STORE, categoryIndex))
    end

    local marketProductPresentations = {self:GetMarketProductIds(categoryIndex, finalSubcategoryIndex, numMarketProducts)}
    local disableLTOGrouping = IsLTODisabledForMarketProductCategory(MARKET_DISPLAY_GROUP_CROWN_STORE, categoryIndex, finalSubcategoryIndex)
    self:LayoutMarketProducts(marketProductPresentations, disableLTOGrouping)
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
    self:UpdateMarketCurrencies()
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
    ZO_ClearNumericallyIndexedTable(self.limitedTimedOfferProducts)
    ZO_ClearNumericallyIndexedTable(self.dlcProducts)
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
                            isBundle = product:IsBundle(),
                            stackCount = product:GetStackCount(),
                        }
    table.insert(labeledGroupTable, productInfo)
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
    if self.queuedMarketProductId then
        self:RequestShowMarketProduct(self.queuedMarketProductId)
    end

    if self.queuedSearchString then
        self:DisplayQueuedMarketProductsBySearchString()
    end
end

function ZO_Market_Shared:UpdateMarketCurrencies()
    self:UpdateCrownBalance(GetPlayerCrowns())
    self:UpdateCrownGemBalance(GetPlayerCrownGems())
end

function ZO_Market_Shared:UpdateFreeTrialProduct()
    self.hasFreeTrialProduct = false
    -- check if there is an active eso plus product, but only grab the first one
    self.freeTrialMarketProductId, self.freeTrialPresentationIndex = GetActiveMarketProductListingsForEsoPlus(MARKET_DISPLAY_GROUP_CROWN_STORE)
    if self.freeTrialMarketProductId ~= nil and self.freeTrialMarketProductId > 0 then
        local costAfterDiscount = select(4, GetMarketProductPricingByPresentation(self.freeTrialMarketProductId, self.freeTrialPresentationIndex))
        self.hasFreeTrialProduct = costAfterDiscount == 0
    end

    self.shouldShowFreeTrial = not IsESOPlusSubscriber() and self.hasFreeTrialProduct
end

do
    local freeTrialColor = GetItemQualityColor(ITEM_QUALITY_LEGENDARY)
    local function UpdateEsoPlusFreeTrialStatusText(productId)
        local remainingTime = GetMarketProductTimeLeftInSeconds(productId)
        local formattedRemainingTime = ZO_FormatTimeLargestTwo(remainingTime, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL)
        local statusText = zo_strformat(SI_MARKET_SUBSCRIPTION_PAGE_SUBSCRIPTION_STATUS_FREE_TRIAL, formattedRemainingTime)
        return freeTrialColor:Colorize(statusText)
    end

    function ZO_Market_Shared:GetEsoPlusStatusText()
        local statusText
        local generateTextFunction
        if  IsOnESOPlusFreeTrial() then
            generateTextFunction = function() return UpdateEsoPlusFreeTrialStatusText(self.freeTrialMarketProductId) end
            statusText = generateTextFunction()
        elseif IsESOPlusSubscriber() then
            statusText = SI_MARKET_SUBSCRIPTION_PAGE_SUBSCRIPTION_STATUS_ACTIVE
            generateTextFunction = nil
        else
            statusText = SI_MARKET_SUBSCRIPTION_PAGE_SUBSCRIPTION_STATUS_NOT_ACTIVE
            generateTextFunction = nil
        end

        return statusText, generateTextFunction
    end
end

function ZO_Market_Shared.GetMarketProductPreviewType(marketProduct)
    if marketProduct then
        if marketProduct:IsBundle() then
            if marketProduct:GetHidesChildProducts() then
                return ZO_MARKET_PREVIEW_TYPE_BUNDLE_HIDES_CHILDREN
            else
                return ZO_MARKET_PREVIEW_TYPE_BUNDLE
            end
        else
            local productType = marketProduct:GetMarketProductType()
            if productType == MARKET_PRODUCT_TYPE_CROWN_CRATE then
                return ZO_MARKET_PREVIEW_TYPE_CROWN_CRATE
            elseif marketProduct:IsHouseCollectible() and marketProduct:GetPurchaseState() == MARKET_PRODUCT_PURCHASE_STATE_NOT_PURCHASED then
                return ZO_MARKET_PREVIEW_TYPE_HOUSE
            else
                return ZO_MARKET_PREVIEW_TYPE_PREVIEWABLE
            end
        end
    else
        return ZO_MARKET_PREVIEW_TYPE_PREVIEWABLE
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

function ZO_Market_Shared:LayoutMarketProducts(marketProductPresentations, disableLTOGrouping)
end

function ZO_Market_Shared:RefreshVisibleCategoryFilter()
end

function ZO_Market_Shared:RefreshProducts()
end

function ZO_Market_Shared:OnTutorialShowing()
end

function ZO_Market_Shared:OnTutorialHidden()
end

function ZO_Market_Shared:DisplayEsoPlusOffer()
end

function ZO_Market_Shared:GetCategoryData(targetId)
end

function ZO_Market_Shared:RequestShowMarketWithSearchString(searchString)
end

function ZO_Market_Shared:ResetSearch()
end

function ZO_Market_Shared:PurchaseMarketProduct(marketProductId, presentationIndex)
end

function ZO_Market_Shared:RefreshEsoPlusPage()
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

function ZO_Market_Shared:RequestShowMarketProduct(id)
    assert(false)
end

function ZO_Market_Shared:RequestShowCategory(categoryIndex)
    assert(false)
end

function ZO_Market_Shared:CanPreviewMarketProductPreviewType(previewType)
    return true
end

--[[Search]]--
--------------
function ZO_Market_Shared:SearchStart(searchString)
    if searchString ~= self.searchString then
        self.searchString = searchString
        StartMarketProductSearch(MARKET_DISPLAY_GROUP_CROWN_STORE, searchString)
    end
end

function ZO_Market_Shared:HasValidSearchString()
    return zo_strlen(self.searchString) > 1
end

function ZO_Market_Shared:UpdateSearchResults()
    ZO_ClearTable(self.searchResults)

    local numResults = GetNumMarketProductSearchResults()
    for i = 1, numResults do
        local categoryIndex, subcategoryIndex, productIndex = GetMarketProductSearchResult(i)
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