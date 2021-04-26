ZO_EndeavorSealStore_Keyboard = ZO_Market_Keyboard:Subclass()

function ZO_EndeavorSealStore_Keyboard:New(...)
    return ZO_Market_Keyboard.New(self, ...)
end

function ZO_EndeavorSealStore_Keyboard:Initialize(control, sceneName)
    ZO_Market_Keyboard.Initialize(self, control, sceneName)

    self.marketOpenedTutorialTriggerType = TUTORIAL_TRIGGER_SEAL_MARKET_OPENED
    self:SetDisplayGroup(MARKET_DISPLAY_GROUP_CROWN_STORE)
    self:SetFeaturedMarketProductFiltersMask(MARKET_PRODUCT_FILTER_TYPE_COST_ENDEAVOR_SEALS)
    self:SetMarketProductFilterTypes({MARKET_PRODUCT_FILTER_TYPE_COST_ENDEAVOR_SEALS})
    self:SetNewMarketProductFilterTypes({MARKET_PRODUCT_FILTER_TYPE_NEW + MARKET_PRODUCT_FILTER_TYPE_COST_ENDEAVOR_SEALS})
    self:SetShownCurrencyTypeBalances(MKCT_ENDEAVOR_SEALS)
end

function ZO_EndeavorSealStore_Keyboard:GetCategoryMarketProductPresentations(categoryIndex, marketProductPresentations)
    local displayGroup = self:GetDisplayGroup()
    local numSubcategories, numMarketProducts = select(2, GetMarketProductCategoryInfo(displayGroup, categoryIndex))
    if not self:HasValidSearchString() or self.searchResults[categoryIndex]["root"] then
        local NO_SUBCATEGORY = nil
        self:GetMarketProductPresentations(categoryIndex, NO_SUBCATEGORY, numMarketProducts, marketProductPresentations)
    end

    for subcategoryIndex = 1, numSubcategories do
        if self:DoesCategoryContainFilteredProducts(displayGroup, categoryIndex, subcategoryIndex, self.marketProductFilterTypes) then
            local numSubcategoryMarketProducts = select(2, GetMarketProductSubCategoryInfo(displayGroup, categoryIndex, subcategoryIndex))
            self:GetMarketProductPresentations(categoryIndex, subcategoryIndex, numSubcategoryMarketProducts, marketProductPresentations)
        end
    end
end

-- Begin ZO_Market_Keyboard overrides

function ZO_EndeavorSealStore_Keyboard:AddTopLevelCategories()
    self:ClearMarketProducts()

    local shownCategories = false
    if not self:HasValidSearchString() then
        local displayGroup = self:GetDisplayGroup()

        -- featured items category
        if self:DoesFeaturedMarketProductExist() then
            local normalIcon = "esoui/art/treeicons/achievements_indexicon_summary_up.dds"
            local pressedIcon = "esoui/art/treeicons/achievements_indexicon_summary_down.dds"
            local mouseoverIcon = "esoui/art/treeicons/achievements_indexicon_summary_over.dds"
            local NO_SUBCATEGORY = 0
            self:AddCustomTopLevelCategory(ZO_MARKET_FEATURED_CATEGORY_INDEX, GetString(SI_MARKET_FEATURED_CATEGORY), NO_SUBCATEGORY, normalIcon, pressedIcon, mouseoverIcon, ZO_MARKET_CATEGORY_TYPE_FEATURED, function()
                return self:HasNewFeaturedMarketProducts()
            end)
            shownCategories = true
        end

        local numCategories = GetNumMarketProductCategories(displayGroup)
        local NO_SUBCATEGORY = nil
        for categoryIndex = 1, numCategories do
            if self:DoesCategoryOrSubcategoriesContainFilteredProducts(displayGroup, categoryIndex, NO_SUBCATEGORY, self.marketProductFilterTypes) then
                local name, numSubCategories, numMarketProducts, normalIcon, pressedIcon, mouseoverIcon = GetMarketProductCategoryInfo(displayGroup, categoryIndex)
                self:AddMarketProductTopLevelCategory(categoryIndex, name, numSubCategories, normalIcon, pressedIcon, mouseoverIcon, ZO_MARKET_CATEGORY_TYPE_NONE, function()
                    return self:DoesCategoryOrSubcategoriesContainFilteredProducts(displayGroup, categoryIndex, NO_SUBCATEGORY, self.newMarketProductFilterTypes)
                end)
                shownCategories = true
            end
        end
    else
        for categoryIndex, data in pairs(self.searchResults) do
            local name, numSubCategories, numMarketProducts, normalIcon, pressedIcon, mouseoverIcon = GetMarketProductCategoryInfo(displayGroup, categoryIndex)
            self:AddMarketProductTopLevelCategory(categoryIndex, name, numSubCategories, normalIcon, pressedIcon, mouseoverIcon, ZO_MARKET_CATEGORY_TYPE_NONE, function()
                return self:DoesCategoryOrSubcategoriesContainFilteredProducts(displayGroup, categoryIndex, NO_SUBCATEGORY, self.newMarketProductFilterTypes)
            end)
            shownCategories = true
        end
    end

    self:SetIsMarketEmpty(not shownCategories)
end

-- End ZO_Market_Keyboard overrides

--
--[[ XML Handlers ]]--
--

function ZO_EndeavorSealStore_Keyboard_OnInitialize(control)
    ENDEAVOR_SEAL_STORE_KEYBOARD = ZO_EndeavorSealStore_Keyboard:New(control, "endeavorSealStoreSceneKeyboard")
end