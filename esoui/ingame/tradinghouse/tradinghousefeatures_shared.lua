----------------------
-- Dropdown Feature --
----------------------

ZO_TradingHouseDropDownFeature_Shared = ZO_Object:Subclass()

function ZO_TradingHouseDropDownFeature_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_TradingHouseDropDownFeature_Shared:Initialize(featureParams)
    self.featureParams = featureParams
end

function ZO_TradingHouseDropDownFeature_Shared:GetSelectedChoiceIndex()
    assert(false, "override me")
end

function ZO_TradingHouseDropDownFeature_Shared:SelectChoice(newChoiceIndex)
    assert(false, "override me")
end

function ZO_TradingHouseDropDownFeature_Shared:ResetSearch()
    local FIRST_CHOICE = 1
    self:SelectChoice(FIRST_CHOICE)
end

function ZO_TradingHouseDropDownFeature_Shared:ApplyToSearch(search)
    local selectedChoiceIndex = self:GetSelectedChoiceIndex()
    if selectedChoiceIndex then
        local applyToSearchCallback = self.featureParams:GetApplyToSearchCallback()
        local choiceValue = self.featureParams:GetChoiceValue(selectedChoiceIndex)
        applyToSearchCallback(search, choiceValue)
    end
end

function ZO_TradingHouseDropDownFeature_Shared:SaveToTable(searchTable)
    searchTable[self.featureParams:GetKey()] = self:GetSelectedChoiceIndex()
end

function ZO_TradingHouseDropDownFeature_Shared:LoadFromTable(searchTable)
    local savedChoiceIndex = searchTable[self.featureParams:GetKey()]
    if type(savedChoiceIndex) == 'number' then
        self:SelectChoice(savedChoiceIndex)
    end
end

function ZO_TradingHouseDropDownFeature_Shared:GetDisplayName()
    return self.featureParams:GetDisplayName()
end

function ZO_TradingHouseDropDownFeature_Shared:GetDescriptionFromTable(searchTable)
    local savedChoiceIndex = searchTable[self.featureParams:GetKey()]
    if type(savedChoiceIndex) == 'number' and savedChoiceIndex ~= 1 then
        return self.featureParams:GetChoiceDisplayName(savedChoiceIndex)
    end
    return nil
end

function ZO_TradingHouseDropDownFeature_Shared:LoadFromItem(itemLink)
    local choiceIndex = self.featureParams:GetChoiceIndexFromItem(itemLink)
    if choiceIndex then
        self:SelectChoice(choiceIndex)
    else
        self:SelectChoice(1)
    end
end

ZO_TradingHouseDropDownFeature_Params = ZO_Object:Subclass()

function ZO_TradingHouseDropDownFeature_Params:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_TradingHouseDropDownFeature_Params:Initialize(key)
    self.key = key
    self.choices = {}
end

function ZO_TradingHouseDropDownFeature_Params:GetKey()
    return self.key
end

function ZO_TradingHouseDropDownFeature_Params:SetDisplayName(displayName)
    self.displayName = displayName
end

function ZO_TradingHouseDropDownFeature_Params:GetDisplayName()
    return internalassert(self.displayName)
end

function ZO_TradingHouseDropDownFeature_Params:SetApplyToSearchCallback(applyToSearchCallback)
    self.applyToSearchCallback = applyToSearchCallback
end

function ZO_TradingHouseDropDownFeature_Params:GetApplyToSearchCallback()
    return self.applyToSearchCallback
end

function ZO_TradingHouseDropDownFeature_Params:SetGetValueFromItemCallback(getValueFromItemCallback)
    self.getValueFromItemCallback = getValueFromItemCallback
end

function ZO_TradingHouseDropDownFeature_Params:GetChoiceIndexFromItem(itemLink)
    if self.getValueFromItemCallback then
        local value = self.getValueFromItemCallback(itemLink)
        if value then
            for i, choiceData in ipairs(self.choices) do
                if choiceData.value == value then
                    return i
                end
            end
        end
    end
    return nil
end

function ZO_TradingHouseDropDownFeature_Params:AddChoice(displayName, valueOrNil)
    table.insert(self.choices, { displayName = displayName, value = valueOrNil })
end

function ZO_TradingHouseDropDownFeature_Params:GetNumChoices()
    return #self.choices
end

function ZO_TradingHouseDropDownFeature_Params:GetChoiceDisplayName(choiceIndex)
    return self.choices[choiceIndex].displayName
end

function ZO_TradingHouseDropDownFeature_Params:GetChoiceValue(choiceIndex)
    return self.choices[choiceIndex].value
end

-------------------------
-- Level Range Feature --
-------------------------

ZO_TradingHouseLevelRangeFeature_Shared = ZO_Object:Subclass()

function ZO_TradingHouseLevelRangeFeature_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_TradingHouseLevelRangeFeature_Shared:Initialize(featureKey, applyToSearchCallback)
    self.featureKey = featureKey
    self.applyToSearchCallback = applyToSearchCallback
end

function ZO_TradingHouseLevelRangeFeature_Shared:GetLevelRange()
    assert(false, "override me")
end

function ZO_TradingHouseLevelRangeFeature_Shared:SetLevelRange(minLevel, maxLevel, isChampionRank)
    assert(false, "override me")
end

function ZO_TradingHouseLevelRangeFeature_Shared:ResetSearch()
    local NO_MIN_LEVEL, NO_MAX_LEVEL, NOT_CHAMPION_RANK = nil, nil, false
    self:SetLevelRange(NO_MIN_LEVEL, NO_MAX_LEVEL, NOT_CHAMPION_RANK)
end

function ZO_TradingHouseLevelRangeFeature_Shared:ApplyToSearch(search)
    -- different types of items interpret the level range provided differently
    local minLevel, maxLevel, isChampionRank = self:GetLevelRange()
    self.applyToSearchCallback(search, minLevel, maxLevel, isChampionRank)
end

function ZO_TradingHouseLevelRangeFeature_Shared:SaveToTable(searchTable)
    local minLevel, maxLevel, isChampionRank = self:GetLevelRange()
    searchTable[self.featureKey] = {minLevel, maxLevel, isChampionRank}
end

function ZO_TradingHouseLevelRangeFeature_Shared:LoadFromTable(searchTable)
    local savedLevelRange = searchTable[self.featureKey]
    if type(savedLevelRange) == 'table' then
        local minLevel, maxLevel, isChampionRank = unpack(savedLevelRange, 1, 3)
        self:SetLevelRange(minLevel, maxLevel, isChampionRank)
    end
end

function ZO_TradingHouseLevelRangeFeature_Shared:GetDisplayName()
    return GetString("SI_TRADINGHOUSEFEATURECATEGORY", TRADING_HOUSE_FEATURE_CATEGORY_LEVEL_RANGE)
end

function ZO_TradingHouseLevelRangeFeature_Shared:GetDescriptionFromTable(searchTable)
    local savedLevelRange = searchTable[self.featureKey]
    if type(savedLevelRange) == 'table' then
        local minLevel, maxLevel, isChampionRank = unpack(savedLevelRange, 1, 3)
        if minLevel or maxLevel then
            minLevel = minLevel or 0
            maxLevel = maxLevel or (isChampionRank and GetChampionPointsPlayerProgressionCap() or GetMaxLevel())

            local ICON_SIZE = "100%"
            if minLevel == maxLevel then
                local exactLevel, exactChampionPoints = 0, 0
                if isChampionRank then
                    exactChampionPoints = minLevel
                else
                    exactLevel = minLevel
                end
                return ZO_GetLevelOrChampionPointsString(exactLevel, exactChampionPoints, ICON_SIZE)
            else
                return ZO_GetLevelOrChampionPointsRangeString(minLevel, maxLevel, isChampionRank, ICON_SIZE)
            end
        end
    end
    return nil
end

function ZO_TradingHouseLevelRangeFeature_Shared:LoadFromItem(itemLink)
    --This feature will not be set from an item link
end

-------------------------
-- Price Range Feature --
-------------------------

ZO_TradingHousePriceRangeFeature_Shared = ZO_Object:Subclass()

function ZO_TradingHousePriceRangeFeature_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_TradingHousePriceRangeFeature_Shared:Initialize()
    -- Can be overriden
end

function ZO_TradingHousePriceRangeFeature_Shared:GetPriceRange()
    assert(false, "override me")
end

function ZO_TradingHousePriceRangeFeature_Shared:SetPriceRange(minPrice, maxPrice)
    assert(false, "override me")
end

function ZO_TradingHousePriceRangeFeature_Shared:ResetSearch()
    local NO_MIN_PRICE, NO_MAX_PRICE  = nil, nil
    self:SetPriceRange(NO_MIN_PRICE, NO_MAX_PRICE)
end

function ZO_TradingHousePriceRangeFeature_Shared:ApplyToSearch(search)
    local minPrice, maxPrice  = self:GetPriceRange()
    if minPrice or maxPrice then
        search:SetFilterRange(TRADING_HOUSE_FILTER_TYPE_PRICE, minPrice, maxPrice)
    end
end

function ZO_TradingHousePriceRangeFeature_Shared:SaveToTable(searchTable)
    local minPrice, maxPrice = self:GetPriceRange()
    searchTable["PriceRange"] = {minPrice, maxPrice}
end

function ZO_TradingHousePriceRangeFeature_Shared:LoadFromTable(searchTable)
    local savedPriceRange = searchTable["PriceRange"]
    if type(savedPriceRange) == 'table' then
        local minPrice, maxPrice = unpack(savedPriceRange, 1, 2)
        self:SetPriceRange(minPrice, maxPrice)
    end
end

function ZO_TradingHousePriceRangeFeature_Shared:GetDisplayName()
    return GetString("SI_TRADINGHOUSEFEATURECATEGORY", TRADING_HOUSE_FEATURE_CATEGORY_PRICE_RANGE)
end

function ZO_TradingHousePriceRangeFeature_Shared:GetDescriptionFromTable(searchTable)
    local savedPriceRange = searchTable["PriceRange"]
    if type(savedPriceRange) == 'table' then
        local minPrice, maxPrice = unpack(savedPriceRange, 1, 2)
        if minPrice or maxPrice then
            minPrice = minPrice or MIN_TRADING_HOUSE_POST_PRICE
            maxPrice = maxPrice or MAX_PLAYER_CURRENCY
            local minPriceString = ZO_Currency_FormatPlatform(CURT_MONEY, minPrice, ZO_CURRENCY_FORMAT_AMOUNT_ICON)
            local maxPriceString = ZO_Currency_FormatPlatform(CURT_MONEY, maxPrice, ZO_CURRENCY_FORMAT_AMOUNT_ICON)
            if minPrice == maxPrice then
                return minPriceString
            else
                -- delay using zo_strformat until this is combined with other descriptions
                return string.format("%s-%s", minPriceString, maxPriceString)
            end
        end
    end
    return nil
end

function ZO_TradingHousePriceRangeFeature_Shared:LoadFromItem(itemLink)
    --This feature will not be set from an item link
end

------------------
-- Feature Data --
------------------

ZO_TRADING_HOUSE_FEATURE_TYPE_DROPDOWN = 1
ZO_TRADING_HOUSE_FEATURE_TYPE_LEVELRANGE = 2
ZO_TRADING_HOUSE_FEATURE_TYPE_SEARCHCATEGORY = 3
ZO_TRADING_HOUSE_FEATURE_TYPE_PRICERANGE = 4
ZO_TRADING_HOUSE_FEATURE_TYPE_NAMESEARCH = 5

ZO_TRADING_HOUSE_FEATURE_TYPES = {}

ZO_TRADING_HOUSE_DROPDOWN_FEATURE_PARAMS = {}
local function CreateDropDownFeatureParams(key)
    local params = ZO_TradingHouseDropDownFeature_Params:New(key)
    ZO_TRADING_HOUSE_FEATURE_TYPES[key] = ZO_TRADING_HOUSE_FEATURE_TYPE_DROPDOWN
    ZO_TRADING_HOUSE_DROPDOWN_FEATURE_PARAMS[key] = params
    return params
end

ZO_TRADING_HOUSE_LEVELRANGE_FEATURE_CALLBACKS = {}
local function CreateLevelRangeType(key, applyToSearchCallback)
    ZO_TRADING_HOUSE_FEATURE_TYPES[key] = ZO_TRADING_HOUSE_FEATURE_TYPE_LEVELRANGE
    ZO_TRADING_HOUSE_LEVELRANGE_FEATURE_CALLBACKS[key] = applyToSearchCallback
end

ZO_TRADING_HOUSE_FEATURE_TYPES["SearchCategory"] = ZO_TRADING_HOUSE_FEATURE_TYPE_SEARCHCATEGORY
ZO_TRADING_HOUSE_FEATURE_TYPES["PriceRange"] = ZO_TRADING_HOUSE_FEATURE_TYPE_PRICERANGE
ZO_TRADING_HOUSE_FEATURE_TYPES["NameSearch"] = ZO_TRADING_HOUSE_FEATURE_TYPE_NAMESEARCH

local function AddEnumSearcher(params, tradeFilterType, getValueFromItemCallback)
    params:SetApplyToSearchCallback(function(search, value)
        search:SetFilter(tradeFilterType, value)
    end)
    params:SetGetValueFromItemCallback(getValueFromItemCallback)
end

local function AddEnumChoices(params, enumStringPrefix, allChoicesName, enumValues)
    local NO_VALUE = nil
    params:AddChoice(allChoicesName, NO_VALUE)

    for _, enumValue in ipairs(enumValues) do
        params:AddChoice(GetString(enumStringPrefix, enumValue), enumValue)
    end
end

-- Traits
do
    internalassert(ITEM_TRAIT_TYPE_MAX_VALUE == 60, "Update when any new trait type is made")
    local allTraitsString = GetString(SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ALL_TRAIT_TYPES)

    local weaponTraitParams = CreateDropDownFeatureParams("WeaponTraits")
    weaponTraitParams:SetDisplayName(GetString("SI_TRADINGHOUSEFEATURECATEGORY", TRADING_HOUSE_FEATURE_CATEGORY_TRAIT))
    AddEnumSearcher(weaponTraitParams, TRADING_HOUSE_FILTER_TYPE_TRAIT, GetItemLinkTraitType)
    AddEnumChoices(weaponTraitParams, "SI_ITEMTRAITTYPE", allTraitsString, {
        ITEM_TRAIT_TYPE_WEAPON_ORNATE,
        ITEM_TRAIT_TYPE_WEAPON_INTRICATE,
        ITEM_TRAIT_TYPE_WEAPON_POWERED,
        ITEM_TRAIT_TYPE_WEAPON_CHARGED,
        ITEM_TRAIT_TYPE_WEAPON_PRECISE,
        ITEM_TRAIT_TYPE_WEAPON_INFUSED,
        ITEM_TRAIT_TYPE_WEAPON_DEFENDING,
        ITEM_TRAIT_TYPE_WEAPON_TRAINING,
        ITEM_TRAIT_TYPE_WEAPON_SHARPENED,
        ITEM_TRAIT_TYPE_WEAPON_DECISIVE,
        ITEM_TRAIT_TYPE_WEAPON_NIRNHONED,
        ITEM_TRAIT_TYPE_NONE,
    })

    local companionWeaponTraitParams = CreateDropDownFeatureParams("CompanionWeaponTraits")
    companionWeaponTraitParams:SetDisplayName(GetString("SI_TRADINGHOUSEFEATURECATEGORY", TRADING_HOUSE_FEATURE_CATEGORY_TRAIT))
    AddEnumSearcher(companionWeaponTraitParams, TRADING_HOUSE_FILTER_TYPE_TRAIT, GetItemLinkTraitType)
    AddEnumChoices(companionWeaponTraitParams, "SI_ITEMTRAITTYPE", allTraitsString, {
        ITEM_TRAIT_TYPE_WEAPON_QUICKENED,
        ITEM_TRAIT_TYPE_WEAPON_PROLIFIC,
        ITEM_TRAIT_TYPE_WEAPON_FOCUSED,
        ITEM_TRAIT_TYPE_WEAPON_SHATTERING,
        ITEM_TRAIT_TYPE_WEAPON_AGGRESSIVE,
        ITEM_TRAIT_TYPE_WEAPON_SOOTHING,
        ITEM_TRAIT_TYPE_WEAPON_AUGMENTED,
        ITEM_TRAIT_TYPE_WEAPON_BOLSTERED,
        ITEM_TRAIT_TYPE_WEAPON_VIGOROUS,
        ITEM_TRAIT_TYPE_NONE,
    })

    local armorTraitParams = CreateDropDownFeatureParams("ArmorTraits")
    armorTraitParams:SetDisplayName(GetString("SI_TRADINGHOUSEFEATURECATEGORY", TRADING_HOUSE_FEATURE_CATEGORY_TRAIT))
    AddEnumSearcher(armorTraitParams, TRADING_HOUSE_FILTER_TYPE_TRAIT, GetItemLinkTraitType)
    AddEnumChoices(armorTraitParams, "SI_ITEMTRAITTYPE", allTraitsString, {
        ITEM_TRAIT_TYPE_ARMOR_ORNATE,
        ITEM_TRAIT_TYPE_ARMOR_INTRICATE,
        ITEM_TRAIT_TYPE_ARMOR_STURDY,
        ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE,
        ITEM_TRAIT_TYPE_ARMOR_REINFORCED,
        ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED,
        ITEM_TRAIT_TYPE_ARMOR_TRAINING,
        ITEM_TRAIT_TYPE_ARMOR_INFUSED,
        ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS,
        ITEM_TRAIT_TYPE_ARMOR_DIVINES,
        ITEM_TRAIT_TYPE_ARMOR_NIRNHONED,
        ITEM_TRAIT_TYPE_NONE,
    })

    local companionArmorTraitParams = CreateDropDownFeatureParams("CompanionArmorTraits")
    companionArmorTraitParams:SetDisplayName(GetString("SI_TRADINGHOUSEFEATURECATEGORY", TRADING_HOUSE_FEATURE_CATEGORY_TRAIT))
    AddEnumSearcher(companionArmorTraitParams, TRADING_HOUSE_FILTER_TYPE_TRAIT, GetItemLinkTraitType)
    AddEnumChoices(companionArmorTraitParams, "SI_ITEMTRAITTYPE", allTraitsString, {
        ITEM_TRAIT_TYPE_ARMOR_QUICKENED,
        ITEM_TRAIT_TYPE_ARMOR_PROLIFIC,
        ITEM_TRAIT_TYPE_ARMOR_FOCUSED,
        ITEM_TRAIT_TYPE_ARMOR_SHATTERING,
        ITEM_TRAIT_TYPE_ARMOR_AGGRESSIVE,
        ITEM_TRAIT_TYPE_ARMOR_SOOTHING,
        ITEM_TRAIT_TYPE_ARMOR_AUGMENTED,
        ITEM_TRAIT_TYPE_ARMOR_BOLSTERED,
        ITEM_TRAIT_TYPE_ARMOR_VIGOROUS,
        ITEM_TRAIT_TYPE_NONE,
    })

    local jewelryTraitParams = CreateDropDownFeatureParams("JewelryTraits")
    jewelryTraitParams:SetDisplayName(GetString("SI_TRADINGHOUSEFEATURECATEGORY", TRADING_HOUSE_FEATURE_CATEGORY_TRAIT))
    AddEnumSearcher(jewelryTraitParams, TRADING_HOUSE_FILTER_TYPE_TRAIT, GetItemLinkTraitType)
    AddEnumChoices(jewelryTraitParams, "SI_ITEMTRAITTYPE", allTraitsString, {
        ITEM_TRAIT_TYPE_JEWELRY_ORNATE,
        ITEM_TRAIT_TYPE_JEWELRY_INTRICATE,
        ITEM_TRAIT_TYPE_JEWELRY_ARCANE,
        ITEM_TRAIT_TYPE_JEWELRY_HEALTHY,
        ITEM_TRAIT_TYPE_JEWELRY_ROBUST,
        ITEM_TRAIT_TYPE_JEWELRY_TRIUNE,
        ITEM_TRAIT_TYPE_JEWELRY_INFUSED,
        ITEM_TRAIT_TYPE_JEWELRY_PROTECTIVE,
        ITEM_TRAIT_TYPE_JEWELRY_SWIFT,
        ITEM_TRAIT_TYPE_JEWELRY_HARMONY,
        ITEM_TRAIT_TYPE_JEWELRY_BLOODTHIRSTY,
        ITEM_TRAIT_TYPE_NONE,
    })

    local companionJewelryTraitParams = CreateDropDownFeatureParams("CompanionJewelryTraits")
    companionJewelryTraitParams:SetDisplayName(GetString("SI_TRADINGHOUSEFEATURECATEGORY", TRADING_HOUSE_FEATURE_CATEGORY_TRAIT))
    AddEnumSearcher(companionJewelryTraitParams, TRADING_HOUSE_FILTER_TYPE_TRAIT, GetItemLinkTraitType)
    AddEnumChoices(companionJewelryTraitParams, "SI_ITEMTRAITTYPE", allTraitsString, {
        ITEM_TRAIT_TYPE_JEWELRY_QUICKENED,
        ITEM_TRAIT_TYPE_JEWELRY_PROLIFIC,
        ITEM_TRAIT_TYPE_JEWELRY_FOCUSED,
        ITEM_TRAIT_TYPE_JEWELRY_SHATTERING,
        ITEM_TRAIT_TYPE_JEWELRY_AGGRESSIVE,
        ITEM_TRAIT_TYPE_JEWELRY_SOOTHING,
        ITEM_TRAIT_TYPE_JEWELRY_AUGMENTED,
        ITEM_TRAIT_TYPE_JEWELRY_BOLSTERED,
        ITEM_TRAIT_TYPE_JEWELRY_VIGOROUS,
        ITEM_TRAIT_TYPE_NONE,
    })
end

-- Enchantments
do
    local function CompareEnchantChoices(left, right)
        -- none should be last
        if left.value == ENCHANTMENT_SEARCH_CATEGORY_NONE or right.value == ENCHANTMENT_SEARCH_CATEGORY_NONE then
            return right.value == ENCHANTMENT_SEARCH_CATEGORY_NONE
        end

        return ZO_TableOrderingFunction(left, right, "name", ZO_SORT_BY_NAME, ZO_SORT_ORDER_UP)
    end

    local function AddEnchantChoices(params, glyphItemType)
        local NO_FILTER = nil
        params:AddChoice(GetString(SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ALL_ENCHANTMENT_TYPES), NO_FILTER)

        local enchantmentCategories = {GetEnchantmentSearchCategories(glyphItemType)}

        local enchantmentChoices = {}
        for _, enchantmentSearchCategory in ipairs(enchantmentCategories) do
            table.insert(enchantmentChoices, { name = GetString("SI_ENCHANTMENTSEARCHCATEGORYTYPE", enchantmentSearchCategory), value = enchantmentSearchCategory })
        end
        table.sort(enchantmentChoices, CompareEnchantChoices)

        for _, choice in ipairs(enchantmentChoices) do
            params:AddChoice(choice.name, choice.value)
        end
    end

    local function GetItemLinkEnchantSearchCategory(itemLink)
        local enchantId = GetItemLinkFinalEnchantId(itemLink)
        return GetEnchantSearchCategoryType(enchantId)
    end

    local weaponEnchantmentParams = CreateDropDownFeatureParams("WeaponEnchantments")
    weaponEnchantmentParams:SetDisplayName(GetString("SI_TRADINGHOUSEFEATURECATEGORY", TRADING_HOUSE_FEATURE_CATEGORY_ENCHANTMENT))
    AddEnumSearcher(weaponEnchantmentParams, TRADING_HOUSE_FILTER_TYPE_ENCHANTMENT, GetItemLinkEnchantSearchCategory)
    AddEnchantChoices(weaponEnchantmentParams, ITEMTYPE_GLYPH_WEAPON)

    local armorEnchantmentParams = CreateDropDownFeatureParams("ArmorEnchantments")
    armorEnchantmentParams:SetDisplayName(GetString("SI_TRADINGHOUSEFEATURECATEGORY", TRADING_HOUSE_FEATURE_CATEGORY_ENCHANTMENT))
    AddEnumSearcher(armorEnchantmentParams, TRADING_HOUSE_FILTER_TYPE_ENCHANTMENT, GetItemLinkEnchantSearchCategory)
    AddEnchantChoices(armorEnchantmentParams, ITEMTYPE_GLYPH_ARMOR)

    local jewelryEnchantmentParams = CreateDropDownFeatureParams("JewelryEnchantments")
    jewelryEnchantmentParams:SetDisplayName(GetString("SI_TRADINGHOUSEFEATURECATEGORY", TRADING_HOUSE_FEATURE_CATEGORY_ENCHANTMENT))
    AddEnumSearcher(jewelryEnchantmentParams, TRADING_HOUSE_FILTER_TYPE_ENCHANTMENT, GetItemLinkEnchantSearchCategory)
    AddEnchantChoices(jewelryEnchantmentParams, ITEMTYPE_GLYPH_JEWELRY)
end

-- Quality
do
    local QUALITY_VALUES =
    {
        ITEM_DISPLAY_QUALITY_NORMAL, 
        ITEM_DISPLAY_QUALITY_MAGIC,
        ITEM_DISPLAY_QUALITY_ARCANE,
        ITEM_DISPLAY_QUALITY_ARTIFACT,
        ITEM_DISPLAY_QUALITY_LEGENDARY,
    }

    local function AddColorizedQualityChoices(params)
        local trashColor = GetItemQualityColor(ITEM_DISPLAY_QUALITY_TRASH)
        local anyQualityString = trashColor:Colorize(GetString(SI_TRADING_HOUSE_BROWSE_QUALITY_ANY))
        local ANY_VALUE = nil
        params:AddChoice(anyQualityString, ANY_VALUE)

        for _, displayQuality in ipairs(QUALITY_VALUES) do
            local color = GetItemQualityColor(displayQuality)
            local qualityString = color:Colorize(GetString("SI_ITEMQUALITY", displayQuality))
            params:AddChoice(qualityString, displayQuality)
        end
    end

    local qualityParams = CreateDropDownFeatureParams("Quality")
    qualityParams:SetDisplayName(GetString("SI_TRADINGHOUSEFEATURECATEGORY", TRADING_HOUSE_FEATURE_CATEGORY_QUALITY))
    AddEnumSearcher(qualityParams, TRADING_HOUSE_FILTER_TYPE_QUALITY, GetItemLinkDisplayQuality)
    AddColorizedQualityChoices(qualityParams)
end

-- Level Range
do
    local function ApplyRequiredLevelToSearch(search, minLevel, maxLevel, isChampionRank)
        if minLevel or maxLevel then
            local filterType = isChampionRank and TRADING_HOUSE_FILTER_TYPE_CHAMPION_POINTS or TRADING_HOUSE_FILTER_TYPE_LEVEL
            search:SetFilterRange(filterType, minLevel, maxLevel)
        end
    end
    CreateLevelRangeType("LevelRange", ApplyRequiredLevelToSearch)

    local function ApplyGlyphLevelToSearch(search, minLevel, maxLevel, isChampionRank)
        if minLevel or maxLevel then
            minLevel, maxLevel = ConvertItemGlyphTierRangeToRequiredLevelRange(isChampionRank, minLevel, maxLevel)
            local filterType = isChampionRank and TRADING_HOUSE_FILTER_TYPE_CHAMPION_POINTS or TRADING_HOUSE_FILTER_TYPE_LEVEL
            search:SetFilterRange(filterType, minLevel, maxLevel)
        end
    end
    CreateLevelRangeType("GlyphLevelRange", ApplyGlyphLevelToSearch)
end
