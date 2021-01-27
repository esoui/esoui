ZO_ESO_PLUS_OFFERS_SCROLL_AREA_WIDTH = 596
ZO_EsoPlusOffers_Keyboard = ZO_Market_Keyboard:Subclass()

function ZO_EsoPlusOffers_Keyboard:New(...)
    return ZO_Market_Keyboard.New(self, ...)
end

function ZO_EsoPlusOffers_Keyboard:Initialize(control, sceneName)
    ZO_Market_Keyboard.Initialize(self, control, sceneName)

    self:InitializeEsoPlusCategory()
end

function ZO_EsoPlusOffers_Keyboard:InitializeEsoPlusCategory()
    -- ESO Plus category controls
    local subscriptionControl = self.contentsControl:GetNamedChild("SubscriptionPage")
    self.subscriptionPage = subscriptionControl

    self.subscriptionStatusLabel = subscriptionControl:GetNamedChild("MembershipInfoStatus")
    self.subscriptionMembershipBanner = subscriptionControl:GetNamedChild("MembershipInfoBanner")

    local scrollContainer = subscriptionControl:GetNamedChild("ScrollContainer")
    local subscriptionScrollChild = scrollContainer:GetNamedChild("ScrollChild")
    self.subscriptionOverviewLabel = subscriptionScrollChild:GetNamedChild("Overview")
    self.subscriptionBenefitsLineContainer = subscriptionScrollChild:GetNamedChild("BenefitsLineContainer")

    self.scrollContainer = scrollContainer
    self.subscriptionScrollControl = scrollContainer:GetNamedChild("Scroll")
    self.subscriptionSubscribeButton = subscriptionControl:GetNamedChild("SubscribeButton")
    self.subscriptionFreeTrialButton = subscriptionControl:GetNamedChild("FreeTrialButton")

    self.subscriptionBenefitLinePool = ZO_ControlPool:New("ZO_Market_SubscriptionBenefitLine", subscriptionControl)

    local function SetupSubscriptionBenefitLine(benefitLine)
        benefitLine.iconTexture = benefitLine:GetNamedChild("Icon")
        benefitLine.headerLabel = benefitLine:GetNamedChild("HeaderText")
        benefitLine.lineLabel = benefitLine:GetNamedChild("LineText")
    end
    self.subscriptionBenefitLinePool:SetCustomFactoryBehavior(SetupSubscriptionBenefitLine)
end

-- Begin ZO_Market_Keyboard overrides

function ZO_EsoPlusOffers_Keyboard:AddTopLevelCategories()
    local noActiveSearch = not self:HasValidSearchString()
    if noActiveSearch then
        -- ESO Plus Membership category
        local showNewOnEsoPlusCategoryFunction = function()
            local showNewOnEsoPlusCategory = false
            ZO_MARKET_MANAGER:UpdateFreeTrialProduct()
            if ZO_MARKET_MANAGER:ShouldShowFreeTrial() then
                local freeTrialIsNew = ZO_MARKET_MANAGER:GetFreeTrialProductData():IsNew()
                showNewOnEsoPlusCategory = freeTrialIsNew
            end

            return showNewOnEsoPlusCategory
        end

        local normalIcon = "esoui/art/treeicons/store_indexIcon_ESOPlus_up.dds"
        local pressedIcon = "esoui/art/treeicons/store_indexIcon_ESOPlus_down.dds"
        local mouseoverIcon = "esoui/art/treeicons/store_indexIcon_ESOPlus_over.dds"
        local NO_SUBCATEGORIES = 0
        self:AddCustomTopLevelCategory(ZO_MARKET_ESO_PLUS_CATEGORY_INDEX, GetString(SI_MARKET_ESO_PLUS_MEMBERSHIP_CATEGORY), NO_SUBCATEGORIES, normalIcon, pressedIcon, mouseoverIcon, ZO_MARKET_CATEGORY_TYPE_ESO_PLUS, showNewOnEsoPlusCategoryFunction)
    end

    -- ESO Plus offers + subcategories

    local esoPlusOfferSubcategories = {}
    local hasAnyNewEsoPlusProducts = false
    local numMarketCategories = GetNumMarketProductCategories(MARKET_DISPLAY_GROUP_CROWN_STORE)
    for categoryIndex = 1, numMarketCategories do
        if self:DoesCategoryOrSubcategoriesContainEsoPlusMarketProducts(categoryIndex) then
            local containsNewMarketProducts = DoesMarketProductCategoryOrSubcategoriesContainNewEsoPlusMarketProducts(MARKET_DISPLAY_GROUP_CROWN_STORE, categoryIndex)
            hasAnyNewEsoPlusProducts = hasAnyNewEsoPlusProducts or containsNewMarketProducts
            local categoryInfo =
            {
                categoryIndex = categoryIndex,
                containsNewMarketProducts = containsNewMarketProducts,
            }
            table.insert(esoPlusOfferSubcategories, categoryInfo)
        end
    end

    local numEsoPlusOfferSubcategories = #esoPlusOfferSubcategories
    if numEsoPlusOfferSubcategories > 0 then
        local offersNormalIcon = "esoui/art/treeicons/store_indexicon_promotion_up.dds"
        local offersPressedIcon = "esoui/art/treeicons/store_indexIcon_promotion_down.dds"
        local offersMouseoverIcon = "esoui/art/treeicons/store_indexIcon_promotion_over.dds"
        local esoPlusOffersNode = self:AddCustomTopLevelCategory(ZO_MARKET_ESO_PLUS_OFFERS_CATEGORY_INDEX, GetString(SI_MARKET_ESO_PLUS_OFFERS_CATEGORY), numEsoPlusOfferSubcategories, offersNormalIcon, offersPressedIcon, offersMouseoverIcon, ZO_MARKET_CATEGORY_TYPE_ESO_PLUS_OFFERS, hasAnyNewEsoPlusProducts)

        -- Special all subcategory
        if noActiveSearch then
            local NO_CATEGORY_INDEX = nil
            self:AddCustomSubcategory(esoPlusOffersNode, NO_CATEGORY_INDEX, GetString(SI_MARKET_ESO_PLUS_OFFERS_ALL_SUBCATEGORY), ZO_MARKET_CATEGORY_TYPE_ESO_PLUS_OFFERS, hasAnyNewEsoPlusProducts)
        end

        -- subcategories
        for index, categoryInfo in ipairs(esoPlusOfferSubcategories) do
            local categoryIndex = categoryInfo.categoryIndex
            local categoryName = GetMarketProductCategoryInfo(MARKET_DISPLAY_GROUP_CROWN_STORE, categoryIndex)
            self:AddCustomSubcategory(esoPlusOffersNode, categoryIndex, categoryName, ZO_MARKET_CATEGORY_TYPE_ESO_PLUS_OFFERS, categoryInfo.containsNewMarketProducts)
        end
    end
end

function ZO_EsoPlusOffers_Keyboard:DisplayCategory(data)
    if data.type == ZO_MARKET_CATEGORY_TYPE_ESO_PLUS then
        self:DisplayEsoPlusOffer()
    elseif data.type == ZO_MARKET_CATEGORY_TYPE_ESO_PLUS_OFFERS then
        self:BuildEsoPlusMarketProductList(data)
    else
        ZO_Market_Keyboard.DisplayCategory(self, data)
    end
end

function ZO_EsoPlusOffers_Keyboard:DisplayEsoPlusOffer()
    self:ClearMarketProducts()
    self.subscriptionBenefitLinePool:ReleaseAllObjects()

    self.subscriptionPage:SetHidden(false)
    self.categoryFilter:SetHidden(true)
    self.categoryFilterLabel:SetHidden(true)

    local overview, image = GetMarketSubscriptionKeyboardInfo()
    self.subscriptionOverviewLabel:SetText(overview)
    self.subscriptionMembershipBanner:SetTexture(image)

    local numLines = GetNumKeyboardMarketSubscriptionBenefitLines()
    local controlToAnchorTo = self.subscriptionBenefitsLineContainer
    for i = 1, numLines do
        local lineText, headerText, icon = GetKeyboardMarketSubscriptionBenefitLineInfo(i)
        local benefitLine = self.subscriptionBenefitLinePool:AcquireObject()
        benefitLine.iconTexture:SetTexture(icon)
        benefitLine.headerLabel:SetText(headerText)
        benefitLine.lineLabel:SetText(lineText)
        benefitLine:ClearAnchors()
        if i == 1 then
            benefitLine:SetAnchor(TOPLEFT, controlToAnchorTo, TOPLEFT, 0, 0)
            benefitLine:SetAnchor(TOPRIGHT, controlToAnchorTo, TOPRIGHT, 0, 0)
        else
            benefitLine:SetAnchor(TOPLEFT, controlToAnchorTo, BOTTOMLEFT, 0, 18)
            benefitLine:SetAnchor(TOPRIGHT, controlToAnchorTo, BOTTOMRIGHT, 0, 18)
        end
        benefitLine:SetParent(self.subscriptionBenefitsLineContainer)
        controlToAnchorTo = benefitLine
    end

    local statusText, generateTextFunction = ZO_MARKET_MANAGER:GetEsoPlusStatusText()

    self.subscriptionStatusLabel:SetText(statusText)
    if generateTextFunction then
        self.subscriptionStatusLabel:SetHandler("OnUpdate", function(control) control:SetText(generateTextFunction()) end)
    else
        self.subscriptionStatusLabel:SetHandler("OnUpdate", nil)
    end

    ZO_MARKET_MANAGER:UpdateFreeTrialProduct()
    local shouldShowFreeTrial = ZO_MARKET_MANAGER:ShouldShowFreeTrial()

    self.subscriptionFreeTrialButton:SetHidden(not shouldShowFreeTrial)

    local hideSubscriptionButton = IsESOPlusSubscriber() and not IsOnESOPlusFreeTrial()
    self.subscriptionSubscribeButton:SetHidden(hideSubscriptionButton)

    self.subscriptionSubscribeButton:ClearAnchors()
    if shouldShowFreeTrial then
        self.subscriptionSubscribeButton:SetAnchor(TOP, self.subscriptionScrollControl, BOTTOM, 120, 30)
    else
        self.subscriptionSubscribeButton:SetAnchor(TOP, self.subscriptionScrollControl, BOTTOM, 0, 30)
    end

    self.subscriptionScrollControl:ClearAnchors()
    if hideSubscriptionButton then
        self.subscriptionScrollControl:SetAnchor(TOPLEFT, self.subscriptionMembershipBanner, BOTTOMLEFT, 40, 10)
        self.subscriptionScrollControl:SetAnchor(BOTTOMRIGHT, self.scrollContainer, BOTTOMRIGHT, -16, 0)
    else
        self.subscriptionScrollControl:SetAnchor(TOPLEFT, self.subscriptionMembershipBanner, BOTTOMLEFT, 40, 10)
        self.subscriptionScrollControl:SetAnchor(BOTTOMRIGHT, self.scrollContainer, BOTTOMRIGHT, -16, -58)
    end

    ZO_Scroll_OnExtentsChanged(self.subscriptionPage)
end

function ZO_EsoPlusOffers_Keyboard:HideCustomTopLevelCategories()
    self.subscriptionPage:SetHidden(true)
end

function ZO_EsoPlusOffers_Keyboard:ShouldAddMarketProductPresentation(id, presentationIndex)
    local marketCurrencyType, cost, costAfterDiscount, discountPercent, esoPlusCost = GetMarketProductPricingByPresentation(id, presentationIndex)
    return esoPlusCost ~= nil
end

function ZO_EsoPlusOffers_Keyboard:ShouldAddSearchResult(categoryIndex, subcategoryIndex, productIndex)
    -- if we wouldn't add it to our view normally, don't add it to our search results
    if DoesMarketProductCategoryOrSubcategoriesContainEsoPlusMarketProducts(MARKET_DISPLAY_GROUP_CROWN_STORE, categoryIndex, subcategoryIndex) then
        local id, presentationIndex = GetMarketProductPresentationIds(MARKET_DISPLAY_GROUP_CROWN_STORE, categoryIndex, subcategoryIndex, productIndex)
        return self:ShouldAddMarketProductPresentation(id, presentationIndex)
    end

    return false
end

-- This function will append the ZO_MarketProductData it finds to the marketProductPresentations table as its output if it's not a duplicate
function ZO_EsoPlusOffers_Keyboard:GetMarketProductPresentations(categoryIndex, subcategoryIndex, index, marketProductPresentations)
    if index >= 1 then
        if self:HasValidSearchString() then
            if NonContiguousCount(self.searchResults) == 0 then
                return
            end

            local effectiveSubcategoryIndex = subcategoryIndex or "root"
            if not self.searchResults[categoryIndex][effectiveSubcategoryIndex][index] then
                index = index - 1
                return self:GetMarketProductPresentations(categoryIndex, subcategoryIndex, index, marketProductPresentations)
            end
        end

        local id, presentationIndex = GetMarketProductPresentationIds(MARKET_DISPLAY_GROUP_CROWN_STORE, categoryIndex, subcategoryIndex, index)
        if self:ShouldAddMarketProductPresentation(id, presentationIndex) then
            if not self.marketProductPresentationsIdMap[id] then
                local productData = ZO_MarketProductData:New(id, presentationIndex)
                table.insert(marketProductPresentations, productData)
                self.marketProductPresentationsIdMap[id] = true
            end
        end

        index = index - 1
        return self:GetMarketProductPresentations(categoryIndex, subcategoryIndex, index, marketProductPresentations)
    end
end

-- End ZO_Market_Keyboard overrides

function ZO_EsoPlusOffers_Keyboard:BuildEsoPlusMarketProductList(data)
    local marketProductPresentations = {}
    local disableLTOGrouping = false
    local categoryIndex = data.categoryIndex
    self.marketProductPresentationsIdMap = {}
    if categoryIndex then
        self:GetCategoryMarketProductPresentations(categoryIndex, marketProductPresentations)
        disableLTOGrouping = IsLTODisabledForMarketProductCategory(MARKET_DISPLAY_GROUP_CROWN_STORE, categoryIndex)
    else -- no category index means this is the all subcategory
        local numMarketCategories = GetNumMarketProductCategories(MARKET_DISPLAY_GROUP_CROWN_STORE)
        for marketCategoryIndex = 1, numMarketCategories do
            if self:DoesCategoryOrSubcategoriesContainEsoPlusMarketProducts(marketCategoryIndex) then
                self:GetCategoryMarketProductPresentations(marketCategoryIndex, marketProductPresentations)
            end
        end
    end

    self:LayoutMarketProducts(marketProductPresentations, disableLTOGrouping)
end

function ZO_EsoPlusOffers_Keyboard:GetCategoryMarketProductPresentations(categoryIndex, marketProductPresentations)
    local numSubcategories, numMarketProducts = select(2, GetMarketProductCategoryInfo(MARKET_DISPLAY_GROUP_CROWN_STORE, categoryIndex))
    if not self:HasValidSearchString() or self.searchResults[categoryIndex]["root"] then
        local NO_SUBCATEGORY_INDEX = nil
        self:GetMarketProductPresentations(categoryIndex, NO_SUBCATEGORY_INDEX, numMarketProducts, marketProductPresentations)
    end

    for subcategoryIndex = 1, numSubcategories do
        if self:DoesCategoryOrSubcategoriesContainEsoPlusMarketProducts(categoryIndex, subcategoryIndex) then
            local numSubcategoryMarketProducts = select(2, GetMarketProductSubCategoryInfo(MARKET_DISPLAY_GROUP_CROWN_STORE, categoryIndex, subcategoryIndex))
            self:GetMarketProductPresentations(categoryIndex, subcategoryIndex, numSubcategoryMarketProducts, marketProductPresentations)
        end
    end
end

function ZO_EsoPlusOffers_Keyboard:DoesCategoryOrSubcategoriesContainEsoPlusMarketProducts(categoryIndex, subcategoryIndex)
    if DoesMarketProductCategoryOrSubcategoriesContainEsoPlusMarketProducts(MARKET_DISPLAY_GROUP_CROWN_STORE, categoryIndex, subcategoryIndex) then
        if self:HasValidSearchString() then
            local categoryResults = self.searchResults[categoryIndex]
            if categoryResults ~= nil then
                if subcategoryIndex then
                    local subcategoryResults = categoryResults[subcategoryIndex]
                    return subcategoryResults ~= nil
                else
                    return true
                end
            else
                return false
            end
        else
            return true
        end
    else
        return false
    end
end

--
--[[ XML Handlers ]]--
--

function ZO_EsoPlusOffers_Keyboard_OnInitialize(control)
    ESO_PLUS_OFFERS_KEYBOARD = ZO_EsoPlusOffers_Keyboard:New(control, "esoPlusOffersSceneKeyboard")
end