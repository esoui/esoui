--
--[[ ZO_CrownStore_Keyboard ]]--
--

ZO_CrownStore_Keyboard = ZO_Market_Keyboard:Subclass()

function ZO_CrownStore_Keyboard:New(...)
    return ZO_Market_Keyboard.New(self, ...)
end

function ZO_CrownStore_Keyboard:Initialize(control, sceneName)
    ZO_Market_Keyboard.Initialize(self, control, sceneName)

    self:SetDisplayGroup(MARKET_DISPLAY_GROUP_CROWN_STORE)
    self:SetFeaturedMarketProductFiltersMask(MARKET_PRODUCT_FILTER_TYPE_COST_CROWNS + MARKET_PRODUCT_FILTER_TYPE_COST_CROWN_GEMS)
    local filterTypes =
    {
        MARKET_PRODUCT_FILTER_TYPE_COST_CROWNS,
        MARKET_PRODUCT_FILTER_TYPE_COST_CROWN_GEMS,
    }
    self:SetMarketProductFilterTypes(filterTypes)
    local newFilterTypes =
    {
        MARKET_PRODUCT_FILTER_TYPE_NEW + MARKET_PRODUCT_FILTER_TYPE_COST_CROWNS,
        MARKET_PRODUCT_FILTER_TYPE_NEW + MARKET_PRODUCT_FILTER_TYPE_COST_CROWN_GEMS,
    }
    self:SetNewMarketProductFilterTypes(newFilterTypes)
    self:SetShownCurrencyTypeBalances(MKCT_CROWNS, MKCT_CROWN_GEMS)
end

-- Begin ZO_Market_Keyboard overrides

function ZO_CrownStore_Keyboard:AddTopLevelCategories()
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

        for i = 1, GetNumMarketProductCategories(displayGroup) do
            local name, numSubCategories, numMarketProducts, normalIcon, pressedIcon, mouseoverIcon = GetMarketProductCategoryInfo(displayGroup, i)
            if self:AddMarketProductTopLevelCategory(i, name, numSubCategories, normalIcon, pressedIcon, mouseoverIcon, ZO_MARKET_CATEGORY_TYPE_NONE, function()
                return self:DoesCategoryOrSubcategoriesContainFilteredProducts(displayGroup, i, ZO_NO_MARKET_SUBCATEGORY, self.newMarketProductFilterTypes)
            end) then
                isEmpty = false
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

function ZO_CrownStore_Keyboard:HideCustomTopLevelCategories()
    -- Optional Override
end

function ZO_CrownStore_Keyboard:CreateMarketScene()
    ZO_Market_Keyboard.CreateMarketScene(self)
    SYSTEMS:RegisterKeyboardRootScene(ZO_MARKET_NAME, self.marketScene)
end

-- End ZO_Market_Keyboard overrides

--
--[[ XML Handlers ]]--
--

function ZO_CrownStore_Keyboard_OnInitialize(control)
    MARKET = ZO_CrownStore_Keyboard:New(control, "market")
    SYSTEMS:RegisterKeyboardObject(ZO_MARKET_NAME, MARKET)
end