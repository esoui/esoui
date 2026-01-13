ZO_GildbarStore_Keyboard = ZO_Market_Keyboard:Subclass()

function ZO_GildbarStore_Keyboard:New(...)
    return ZO_Market_Keyboard.New(self, ...)
end

function ZO_GildbarStore_Keyboard:Initialize(control, sceneName)
    ZO_Market_Keyboard.Initialize(self, control, sceneName)

    self.marketOpenedTutorialTriggerType = TUTORIAL_TRIGGER_TRADE_BAR_STORE_OPENED
    self:SetDisplayGroup(MARKET_DISPLAY_GROUP_CROWN_STORE)
    self:SetMarketCurrencyButtonType(ZO_MARKET_CURRENCY_BUTTON_TYPE_OPEN_TAMRIEL_TOMES)
    self:SetFeaturedMarketProductFiltersMask(MARKET_PRODUCT_FILTER_TYPE_COST_TRADE_BARS)
    self:SetMarketProductFilterTypes({MARKET_PRODUCT_FILTER_TYPE_COST_TRADE_BARS})
    self:SetNewMarketProductFilterTypes({MARKET_PRODUCT_FILTER_TYPE_NEW + MARKET_PRODUCT_FILTER_TYPE_COST_TRADE_BARS})
    self:SetShownCurrencyTypeBalances(MKCT_TRADE_BARS)
end

function ZO_GildbarStore_Keyboard:GetCategoryMarketProductPresentations(categoryIndex, marketProductPresentations)
    local displayGroup = self:GetDisplayGroup()
    local numSubcategories, numMarketProducts = select(2, GetMarketProductCategoryInfo(displayGroup, categoryIndex))
    if not self:HasValidSearchString() or self.searchResults[categoryIndex]["root"] then
        self:GetMarketProductPresentations(categoryIndex, ZO_NO_MARKET_SUBCATEGORY, numMarketProducts, marketProductPresentations)
    end

    for subcategoryIndex = 1, numSubcategories do
        if self:DoesCategoryContainFilteredProducts(displayGroup, categoryIndex, subcategoryIndex, self.marketProductFilterTypes) then
            local numSubcategoryMarketProducts = select(2, GetMarketProductSubCategoryInfo(displayGroup, categoryIndex, subcategoryIndex))
            self:GetMarketProductPresentations(categoryIndex, subcategoryIndex, numSubcategoryMarketProducts, marketProductPresentations)
        end
    end
end

-- Begin ZO_Market_Keyboard overrides

function ZO_GildbarStore_Keyboard:GetMarketLockedText()
    return GetString(SI_GOLD_COAST_BAZAAR_LOCKED_TEXT)
end

function ZO_GildbarStore_Keyboard:AddTopLevelCategories()
    self:ClearMarketProducts()

    local displayGroup = self:GetDisplayGroup()
    local isEmpty = true
    if not self:HasValidSearchString() then
        -- featured items category
        if self:DoesFeaturedMarketProductExist() then
            local normalIcon = "esoui/art/treeicons/achievements_indexicon_summary_up.dds"
            local pressedIcon = "esoui/art/treeicons/achievements_indexicon_summary_down.dds"
            local mouseoverIcon = "esoui/art/treeicons/achievements_indexicon_summary_over.dds"
            local NO_SUBCATEGORIES = 0
            self:AddCustomTopLevelCategory(ZO_MARKET_FEATURED_CATEGORY_INDEX, GetString(SI_MARKET_FEATURED_CATEGORY), NO_SUBCATEGORIES, normalIcon, pressedIcon, mouseoverIcon, ZO_MARKET_CATEGORY_TYPE_FEATURED, function()
                return self:HasNewFeaturedMarketProducts()
            end)

            isEmpty = false
        end

        local numCategories = GetNumMarketProductCategories(displayGroup)
        for categoryIndex = 1, numCategories do
            if self:DoesCategoryOrSubcategoriesContainFilteredProducts(displayGroup, categoryIndex, ZO_NO_MARKET_SUBCATEGORY, self.marketProductFilterTypes) then
                local name, numSubCategories, numMarketProducts, normalIcon, pressedIcon, mouseoverIcon = GetMarketProductCategoryInfo(displayGroup, categoryIndex)
                if self:AddMarketProductTopLevelCategory(categoryIndex, name, numSubCategories, normalIcon, pressedIcon, mouseoverIcon, ZO_MARKET_CATEGORY_TYPE_NONE, function()
                    return self:DoesCategoryOrSubcategoriesContainFilteredProducts(displayGroup, categoryIndex, ZO_NO_MARKET_SUBCATEGORY, self.newMarketProductFilterTypes)
                end) then
                    isEmpty = false
                end
            end
        end
    else
        for categoryIndex, data in pairs(self.searchResults) do
            local name, numSubCategories, numMarketProducts, normalIcon, pressedIcon, mouseoverIcon = GetMarketProductCategoryInfo(displayGroup, categoryIndex)
            self:AddMarketProductTopLevelCategory(categoryIndex, name, numSubCategories, normalIcon, pressedIcon, mouseoverIcon, ZO_MARKET_CATEGORY_TYPE_NONE, function()
                return self:DoesCategoryOrSubcategoriesContainFilteredProducts(displayGroup, categoryIndex, ZO_NO_MARKET_SUBCATEGORY, self.newMarketProductFilterTypes)
            end)
        end

        isEmpty = false
    end

    self:SetIsMarketEmpty(isEmpty)
end

-- End ZO_Market_Keyboard overrides

--
--[[ XML Handlers ]]--
--

function ZO_GildbarStore_Keyboard.OnControlInitialized(control)
    GILDBAR_STORE_KEYBOARD = ZO_GildbarStore_Keyboard:New(control, "gildbarStoreSceneKeyboard")
end