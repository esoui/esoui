ZO_TradingHouseSearchCategoryFeature_Shared = ZO_Object:Subclass()

function ZO_TradingHouseSearchCategoryFeature_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_TradingHouseSearchCategoryFeature_Shared:Initialize(...)
    -- override me
end

function ZO_TradingHouseSearchCategoryFeature_Shared:SelectCategoryParams(categoryParams, subcategoryKey)
    assert(false, "override me")
end

function ZO_TradingHouseSearchCategoryFeature_Shared:GetCategoryParams()
    assert(false, "override me")
end

function ZO_TradingHouseSearchCategoryFeature_Shared:GetSubcategoryKey()
    assert(false, "override me")
end

function ZO_TradingHouseSearchCategoryFeature_Shared:GetFeatureForKey(featureKey)
    assert(false, "override me")
end

function ZO_TradingHouseSearchCategoryFeature_Shared:SelectCategory(categoryKey, subcategoryKey)
    local categoryParams = ZO_TRADING_HOUSE_CATEGORY_KEY_TO_PARAMS[categoryKey]
    self:SelectCategoryParams(categoryParams, subcategoryKey)
end

function ZO_TradingHouseSearchCategoryFeature_Shared:ApplyToSearch(search)
    local categoryParams = self:GetCategoryParams()
    if categoryParams then
        local applyToSearch = categoryParams:GetApplyToSearchCallback()
        local subcategoryIndex = categoryParams:GetSubcategoryIndexForKey(self:GetSubcategoryKey())
        local subcategoryValue = subcategoryIndex and categoryParams:GetSubcategoryValue(subcategoryIndex)
        applyToSearch(search, subcategoryValue)

        for _, featureKey in categoryParams:FeatureKeyIterator() do
            local feature = self:GetFeatureForKey(featureKey)
            feature:ApplyToSearch(search)
        end
    end
end

function ZO_TradingHouseSearchCategoryFeature_Shared:ResetSearch()
    for _, featureObject in pairs(self.featureKeyToFeatureObjectMap) do
        featureObject:ResetSearch()
    end
    self:SelectCategory("AllItems")
end

function ZO_TradingHouseSearchCategoryFeature_Shared:SaveToTable(searchTable)
    local categoryParams = self:GetCategoryParams()

    if categoryParams then
        searchTable["SearchCategory"] = categoryParams:GetKey()
        searchTable["SearchSubcategory"] = self:GetSubcategoryKey()

        for _, featureKey in categoryParams:FeatureKeyIterator() do
            local feature = self:GetFeatureForKey(featureKey)
            feature:SaveToTable(searchTable)
        end
    end
end

function ZO_TradingHouseSearchCategoryFeature_Shared:LoadFromTable(searchTable)
    if searchTable["SearchCategory"] then
        self:SelectCategory(searchTable["SearchCategory"], searchTable["SearchSubcategory"])
        local categoryParams = self:GetCategoryParams()
        if categoryParams then
            for _, featureKey in categoryParams:FeatureKeyIterator() do
                local feature = self:GetFeatureForKey(featureKey)
                feature:LoadFromTable(searchTable)
            end
        end
    end
end

function ZO_TradingHouseSearchCategoryFeature_Shared:GetCategoryDescriptionFromTable(searchTable)
    if searchTable["SearchCategory"] then
        local categoryParams = ZO_TRADING_HOUSE_CATEGORY_KEY_TO_PARAMS[searchTable["SearchCategory"]]
        if categoryParams then
            local categoryStrings = {}

            -- skip header if the category is an 'all X' category, these tend to be redundant, eg. 'all weapons' for 'weapons'
            if not categoryParams:IsAllItemsCategory() then
                table.insert(categoryStrings, GetString("SI_TRADINGHOUSECATEGORYHEADER", categoryParams:GetHeader()))
            end

            table.insert(categoryStrings, categoryParams:GetFormattedName())

            -- skip missing or the initial 'all' subcategories, these don't add qualifying info to the description
            local subcategoryIndex = categoryParams:GetSubcategoryIndexForKey(searchTable["SearchSubcategory"])
            if subcategoryIndex and subcategoryIndex ~= 1 then
                table.insert(categoryStrings, categoryParams:GetSubcategoryName(subcategoryIndex))
            end

            return ZO_GenerateCommaSeparatedListWithoutAnd(categoryStrings)
        end
    end
    return nil
end

function ZO_TradingHouseSearchCategoryFeature_Shared:AddContextualFeatureDescriptionsFromTable(searchTable, featureDescriptions)
    if searchTable["SearchCategory"] then
        local categoryParams = ZO_TRADING_HOUSE_CATEGORY_KEY_TO_PARAMS[searchTable["SearchCategory"]]
        if categoryParams then
            local categoryDescription = self:GetCategoryDescriptionFromTable(searchTable)
            table.insert(featureDescriptions, {name = GetString("SI_TRADINGHOUSEFEATURECATEGORY", TRADING_HOUSE_FEATURE_CATEGORY_ITEM_CATEGORY), description = categoryDescription})

            for _, featureKey in categoryParams:FeatureKeyIterator() do
                local feature = self:GetFeatureForKey(featureKey)
                local description = feature:GetDescriptionFromTable(searchTable)
                if description then
                    table.insert(featureDescriptions, {name = feature:GetDisplayName(), description = description})
                end
            end
        end
    end
end

function ZO_TradingHouseSearchCategoryFeature_Shared:LoadFromItem(itemLink)
    local matchedCategory = false
    for _, categoryParams in ipairs(ZO_TRADING_HOUSE_CATEGORY_PARAMS_LIST) do
        local containsItem, subcategoryKey = categoryParams:ContainsItem(itemLink)
        if containsItem then
            --if we didn't match a specific subcategory use the first subcategory (the all subcategory)
            if subcategoryKey == nil then
                subcategoryKey = categoryParams:GetSubcategoryKey(1)
            end
            self:SelectCategoryParams(categoryParams, subcategoryKey)
            matchedCategory = true
            break
        end
    end
    if not matchedCategory then
        self:SelectCategory("AllItems")
    end

    local categoryParams = self:GetCategoryParams()
    for _, featureKey in categoryParams:FeatureKeyIterator() do
        local feature = self:GetFeatureForKey(featureKey)
        feature:LoadFromItem(itemLink)
    end
end

ZO_TradingHouseCategory_Params = ZO_Object:Subclass()

function ZO_TradingHouseCategory_Params:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_TradingHouseCategory_Params:Initialize(key)
    self.key = key
    self.subcategories = {}
    self.subcategoryIndexForKey = {}
    self.featureKeys = {}
end

function ZO_TradingHouseCategory_Params:GetKey()
    return self.key
end

function ZO_TradingHouseCategory_Params:SetName(categoryName)
    internalassert(categoryName and categoryName ~= "")
    self.name = categoryName
end

function ZO_TradingHouseCategory_Params:GetFormattedName()
    return ZO_CachedStrFormat(SI_TRADING_HOUSE_BROWSE_CATEGORY_FORMATTER, self.name)
end

function ZO_TradingHouseCategory_Params:SetHeader(header)
    self.header = header
end

function ZO_TradingHouseCategory_Params:GetHeader()
    return self.header
end

function ZO_TradingHouseCategory_Params:SetIsAllItemsCategory(isAllItemsCategory)
    self.isAllItemsCategory = isAllItemsCategory
end

function ZO_TradingHouseCategory_Params:IsAllItemsCategory()
    return self.isAllItemsCategory
end

function ZO_TradingHouseCategory_Params:SetApplyToSearchCallback(applyToSearchCallback)
    self.applyToSearchCallback = applyToSearchCallback
end

function ZO_TradingHouseCategory_Params:GetApplyToSearchCallback()
    return self.applyToSearchCallback
end

function ZO_TradingHouseCategory_Params:SetContainsItemCallback(containsItemCallback)
    self.containsItemCallback = containsItemCallback
end

function ZO_TradingHouseCategory_Params:ContainsItem(itemLink)
    if self.containsItemCallback then
        return self.containsItemCallback(itemLink)
    else
        return false
    end
end

function ZO_TradingHouseCategory_Params:AddSubcategory(subcategoryKey, subcategoryName, subcategoryIcons, subcategoryValue)
    local index = #self.subcategories + 1
    self.subcategories[index] =
    {
        key = subcategoryKey,
        name = subcategoryName,
        icons = subcategoryIcons,
        value = subcategoryValue,
    }
    self.subcategoryIndexForKey[subcategoryKey] = index
end

function ZO_TradingHouseCategory_Params:GetNumSubcategories()
    return #self.subcategories
end

function ZO_TradingHouseCategory_Params:GetSubcategoryKey(subcategoryIndex)
    return self.subcategories[subcategoryIndex].key
end

function ZO_TradingHouseCategory_Params:GetSubcategoryName(subcategoryIndex)
    return self.subcategories[subcategoryIndex].name
end

function ZO_TradingHouseCategory_Params:GetSubcategoryIcons(subcategoryIndex)
    return self.subcategories[subcategoryIndex].icons
end

function ZO_TradingHouseCategory_Params:GetSubcategoryValue(subcategoryIndex)
    return self.subcategories[subcategoryIndex].value
end

function ZO_TradingHouseCategory_Params:AddFeatureKeys(...)
    for i = 1, select('#', ...) do
        local featureKey = select(i, ...)
        table.insert(self.featureKeys, featureKey)
    end
end

function ZO_TradingHouseCategory_Params:FeatureKeyIterator()
    return ipairs(self.featureKeys)
end

function ZO_TradingHouseCategory_Params:FeatureKeyReverseIterator()
    return ZO_NumericallyIndexedTableReverseIterator(self.featureKeys)
end

function ZO_TradingHouseCategory_Params:GetSubcategoryIndexForKey(subcategoryKey)
    return self.subcategoryIndexForKey[subcategoryKey]
end

-----------------------------
-- Search Category Helpers --
-----------------------------

ZO_TRADING_HOUSE_CATEGORY_PARAMS_LIST = {}
ZO_TRADING_HOUSE_CATEGORY_KEY_TO_PARAMS = {}
local function AddCategory(key)
    internalassert(ZO_TRADING_HOUSE_CATEGORY_KEY_TO_PARAMS[key] == nil)
    local categoryParams = ZO_TradingHouseCategory_Params:New(key)
    table.insert(ZO_TRADING_HOUSE_CATEGORY_PARAMS_LIST, categoryParams)
    ZO_TRADING_HOUSE_CATEGORY_KEY_TO_PARAMS[key] = categoryParams
    return categoryParams
end

local function AddAllSubcategory(params, allItemsString, value)
    allItemsString = allItemsString or GetString(SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ALL)
    params:AddSubcategory("AllSubcategories", allItemsString, ZO_ItemFilterUtils.GetItemTypeDisplayCategoryFilterIcons(ITEM_TYPE_DISPLAY_CATEGORY_ALL), value)
end

local function AddEnumSubcategories(categoryParams, subcategoryParams)
    local enumStringPrefix = subcategoryParams.enumStringPrefix
    local enumKeyPrefix = subcategoryParams.enumKeyPrefix
    local allItemsString = subcategoryParams.allItemsString
    local iconsForEnumValue = subcategoryParams.iconsForEnumValue
    local enumValues = subcategoryParams.enumValues
    local keyOverrideForEnumValue = subcategoryParams.keyOverrideForEnumValue or {}

    -- If there is only one enum value, make it look like an all tab
    if #enumValues == 1 then
        AddAllSubcategory(categoryParams, allItemsString, enumValues[1])
        return
    end

    local allValues = {}
    for _, enumValue in ipairs(enumValues) do
        table.insert(allValues, enumValue)
    end

    AddAllSubcategory(categoryParams, allItemsString, allValues)

    for _, enumValue in ipairs(enumValues) do
        local key = keyOverrideForEnumValue[enumValue] or string.format("%s%d", enumKeyPrefix, enumValue)
        categoryParams:AddSubcategory(key, GetString(enumStringPrefix, enumValue), iconsForEnumValue[enumValue], enumValue)
    end
end

local AddAllItemsCategory
do
    local function ApplyAllItemsToSearch(search)
        -- No filters
    end

    function AddAllItemsCategory()
        local categoryParams = AddCategory("AllItems")
        categoryParams:SetName(GetString("SI_TRADINGHOUSECATEGORYHEADER_ALLCATEGORIES", TRADING_HOUSE_CATEGORY_HEADER_ALL_ITEMS))
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_ALL_ITEMS)
        categoryParams:SetIsAllItemsCategory(true)

        categoryParams:SetApplyToSearchCallback(ApplyAllItemsToSearch)
        -- no features
        AddAllSubcategory(categoryParams, GetString(SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ALL))
    end
end

local AddAllWeaponsCategory
local AddWeaponCategory
do
    internalassert(EQUIPMENT_FILTER_TYPE_MAX_VALUE == 11, "Update weapons in trading house")
    internalassert(WEAPONTYPE_MAX_VALUE == 15, "Update weapons in trading house")
    local ICONS_FOR_WEAPON_TYPE =
    {
        [WEAPONTYPE_AXE] = ZO_ItemFilterUtils.GetWeaponTypeFilterIcons(WEAPONTYPE_AXE),
        [WEAPONTYPE_HAMMER] = ZO_ItemFilterUtils.GetWeaponTypeFilterIcons(WEAPONTYPE_HAMMER),
        [WEAPONTYPE_SWORD] = ZO_ItemFilterUtils.GetWeaponTypeFilterIcons(WEAPONTYPE_SWORD),
        [WEAPONTYPE_DAGGER] = ZO_ItemFilterUtils.GetWeaponTypeFilterIcons(WEAPONTYPE_DAGGER),
        [WEAPONTYPE_TWO_HANDED_AXE] = ZO_ItemFilterUtils.GetWeaponTypeFilterIcons(WEAPONTYPE_TWO_HANDED_AXE),
        [WEAPONTYPE_TWO_HANDED_HAMMER] = ZO_ItemFilterUtils.GetWeaponTypeFilterIcons(WEAPONTYPE_TWO_HANDED_HAMMER),
        [WEAPONTYPE_TWO_HANDED_SWORD] = ZO_ItemFilterUtils.GetWeaponTypeFilterIcons(WEAPONTYPE_TWO_HANDED_SWORD),
        [WEAPONTYPE_FIRE_STAFF] = ZO_ItemFilterUtils.GetWeaponTypeFilterIcons(WEAPONTYPE_FIRE_STAFF),
        [WEAPONTYPE_FROST_STAFF] = ZO_ItemFilterUtils.GetWeaponTypeFilterIcons(WEAPONTYPE_FROST_STAFF),
        [WEAPONTYPE_LIGHTNING_STAFF] = ZO_ItemFilterUtils.GetWeaponTypeFilterIcons(WEAPONTYPE_LIGHTNING_STAFF),
        -- WEAPONTYPE_BOW and WEAPONTYPE_HEALING_STAFF do not have subcategories, so they do not need subcategory icons
    }

    local EVERY_VALID_WEAPON_TYPE = ZO_ItemFilterUtils.GetAllWeaponTypesInEquipmentFilterTypes()

    local function ApplyAllWeaponsToSearch(search)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_ITEM, ITEMTYPE_WEAPON)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_WEAPON, EVERY_VALID_WEAPON_TYPE)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_GAMEPLAY_ACTOR_CATEGORY, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
    end

    local function ApplyWeaponToSearch(search, weaponType)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_ITEM, ITEMTYPE_WEAPON)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_WEAPON, weaponType)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_GAMEPLAY_ACTOR_CATEGORY, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
    end

    function AddAllWeaponsCategory(equipmentFilterType)
        local categoryParams = AddCategory("AllWeapons")
        categoryParams:SetName(GetString("SI_TRADINGHOUSECATEGORYHEADER_ALLCATEGORIES", TRADING_HOUSE_CATEGORY_HEADER_WEAPONS))
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_WEAPONS)
        categoryParams:SetIsAllItemsCategory(true)

        categoryParams:SetApplyToSearchCallback(ApplyAllWeaponsToSearch)
        categoryParams:AddFeatureKeys("LevelRange", "WeaponTraits", "WeaponEnchantments")
        AddAllSubcategory(categoryParams)
    end

    function AddWeaponCategory(equipmentFilterType)
        local weaponTypes = ZO_ItemFilterUtils.GetWeaponTypesByEquipmentFilterType(equipmentFilterType)

        local categoryParams = AddCategory(string.format("Weapons%d", equipmentFilterType))
        categoryParams:SetName(GetString("SI_EQUIPMENTFILTERTYPE", equipmentFilterType))
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_WEAPONS)

        local SUBCATEGORY_ENUM_KEY_PREFIX = "WeaponType"
        categoryParams:SetApplyToSearchCallback(ApplyWeaponToSearch)
        categoryParams:SetContainsItemCallback(function(itemLink)
            local actorCategory = GetItemLinkActorCategory(itemLink)
            if actorCategory == GAMEPLAY_ACTOR_CATEGORY_PLAYER then
                local weaponType = GetItemLinkWeaponType(itemLink)
                for _, searchWeaponType in ipairs(weaponTypes) do
                    if weaponType == searchWeaponType then
                        return true, SUBCATEGORY_ENUM_KEY_PREFIX .. weaponType
                    end
                end
            end
            return false
        end)
        categoryParams:AddFeatureKeys("LevelRange", "WeaponTraits", "WeaponEnchantments")
        AddEnumSubcategories(categoryParams,
        {
            enumKeyPrefix = SUBCATEGORY_ENUM_KEY_PREFIX,
            enumStringPrefix = "SI_WEAPONTYPE",
            allItemsString = GetString(SI_TRADING_HOUSE_BROWSE_ALL_WEAPON_TYPES),
            iconsForEnumValue = ICONS_FOR_WEAPON_TYPE,
            enumValues = weaponTypes,
        })
    end
end

local AddAllApparelCategory, AddArmorCategory, AddShieldCategory
do
    internalassert(ARMORTYPE_MAX_VALUE == 3, "Do you need to update the trading house?")
    local ICONS_FOR_ARMOR_EQUIP_TYPE =
    {
        [EQUIP_TYPE_CHEST] = ZO_ItemFilterUtils.GetEquipTypeFilterIcons(EQUIP_TYPE_CHEST),
        [EQUIP_TYPE_FEET] = ZO_ItemFilterUtils.GetEquipTypeFilterIcons(EQUIP_TYPE_FEET),
        [EQUIP_TYPE_HAND] = ZO_ItemFilterUtils.GetEquipTypeFilterIcons(EQUIP_TYPE_HAND),
        [EQUIP_TYPE_HEAD] = ZO_ItemFilterUtils.GetEquipTypeFilterIcons(EQUIP_TYPE_HEAD),
        [EQUIP_TYPE_LEGS] = ZO_ItemFilterUtils.GetEquipTypeFilterIcons(EQUIP_TYPE_LEGS),
        [EQUIP_TYPE_SHOULDERS] = ZO_ItemFilterUtils.GetEquipTypeFilterIcons(EQUIP_TYPE_SHOULDERS),
        [EQUIP_TYPE_WAIST] = ZO_ItemFilterUtils.GetEquipTypeFilterIcons(EQUIP_TYPE_WAIST),
    }

    local ARMOR_EQUIP_TYPES =
    {
        EQUIP_TYPE_CHEST,
        EQUIP_TYPE_FEET,
        EQUIP_TYPE_HAND,
        EQUIP_TYPE_HEAD,
        EQUIP_TYPE_LEGS,
        EQUIP_TYPE_SHOULDERS,
        EQUIP_TYPE_WAIST,
    }

    -- So this is a bit clever: Each piece of apparel has a slot it can be equipped to, so we enumerate those.
    -- then we also need to catch shields, so we specify that the weapon type must either be SHIELD or NONE (which is the value all non-weapons have)
    -- This catches normal armor, and shields.
    local ALL_APPAREL_EQUIP_TYPES = { EQUIP_TYPE_OFF_HAND }
    ZO_CombineNumericallyIndexedTables(ALL_APPAREL_EQUIP_TYPES, ARMOR_EQUIP_TYPES)

    local ALL_APPAREL_WEAPON_TYPES =
    {
        WEAPON_TYPE_NONE,
        WEAPON_TYPE_SHIELD
    }

    local function ApplyAllApparelToSearch(search)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_EQUIP, ALL_APPAREL_EQUIP_TYPES)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_WEAPON, ALL_APPAREL_WEAPON_TYPES)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_GAMEPLAY_ACTOR_CATEGORY, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
    end

    function AddAllApparelCategory()
        local categoryParams = AddCategory("AllApparel")

        categoryParams:SetName(GetString("SI_TRADINGHOUSECATEGORYHEADER_ALLCATEGORIES", TRADING_HOUSE_CATEGORY_HEADER_APPAREL))
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_APPAREL)
        categoryParams:SetIsAllItemsCategory(true)

        categoryParams:SetApplyToSearchCallback(ApplyAllApparelToSearch)
        categoryParams:AddFeatureKeys("LevelRange", "ArmorTraits", "ArmorEnchantments")
        AddAllSubcategory(categoryParams)
    end

    function AddArmorCategory(armorType)
        local function ApplyArmorToSearch(search, subcategoryValue)
            search:SetFilter(TRADING_HOUSE_FILTER_TYPE_ITEM, ITEMTYPE_ARMOR)
            search:SetFilter(TRADING_HOUSE_FILTER_TYPE_ARMOR, armorType)
            search:SetFilter(TRADING_HOUSE_FILTER_TYPE_EQUIP, subcategoryValue)
            search:SetFilter(TRADING_HOUSE_FILTER_TYPE_GAMEPLAY_ACTOR_CATEGORY, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
        end

        local categoryParams = AddCategory(string.format("Armor%d", armorType))

        categoryParams:SetName(GetString("SI_ARMORTYPE_TRADINGHOUSECATEGORY", armorType))
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_APPAREL)

        local SUBCATEGORY_ENUM_KEY_PREFIX = "EquipType"
        categoryParams:SetApplyToSearchCallback(ApplyArmorToSearch)
        categoryParams:SetContainsItemCallback(function(itemLink)
            local actorCategory = GetItemLinkActorCategory(itemLink)
            if actorCategory == GAMEPLAY_ACTOR_CATEGORY_PLAYER then
                if armorType == GetItemLinkArmorType(itemLink) then
                    local equipType = GetItemLinkEquipType(itemLink)
                    for _, searchEquipType in ipairs(ARMOR_EQUIP_TYPES) do
                        if searchEquipType == equipType then
                            return true, SUBCATEGORY_ENUM_KEY_PREFIX..equipType
                        end
                    end
                end
            end
            return false
        end)
        categoryParams:AddFeatureKeys("LevelRange", "ArmorTraits", "ArmorEnchantments")
        AddEnumSubcategories(categoryParams,
        {
            enumKeyPrefix = SUBCATEGORY_ENUM_KEY_PREFIX,
            enumStringPrefix = "SI_EQUIPTYPE",
            allItemsString = GetString(SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ALL_WORN_ARMOR_TYPES),
            iconsForEnumValue = ICONS_FOR_ARMOR_EQUIP_TYPE,
            enumValues = ARMOR_EQUIP_TYPES,
        })
    end

    local function ApplyShieldToSearch(search)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_WEAPON, WEAPONTYPE_SHIELD)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_GAMEPLAY_ACTOR_CATEGORY, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
    end

    function AddShieldCategory()
        local categoryParams = AddCategory("Shield")

        categoryParams:SetName(GetString(SI_TRADING_HOUSE_BROWSE_ARMOR_TYPE_SHIELD))
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_APPAREL)

        categoryParams:SetApplyToSearchCallback(ApplyShieldToSearch)
        categoryParams:SetContainsItemCallback(function(itemLink)
            local actorCategory = GetItemLinkActorCategory(itemLink)
            if actorCategory == GAMEPLAY_ACTOR_CATEGORY_PLAYER then
                return GetItemLinkWeaponType(itemLink) == WEAPONTYPE_SHIELD
            end
            return false
        end)
        categoryParams:AddFeatureKeys("LevelRange", "ArmorTraits", "ArmorEnchantments")
        AddAllSubcategory(categoryParams)
    end
end

local AddJewelryCategory
do
    local ICONS_FOR_JEWELRY_EQUIP_TYPE = 
    {
        [EQUIP_TYPE_NECK] = ZO_ItemFilterUtils.GetEquipTypeFilterIcons(EQUIP_TYPE_NECK),
        [EQUIP_TYPE_RING] = ZO_ItemFilterUtils.GetEquipTypeFilterIcons(EQUIP_TYPE_RING),
    }

    local JEWELRY_EQUIP_TYPES =
    {
        EQUIP_TYPE_NECK,
        EQUIP_TYPE_RING,
    }

    local function ApplyJewelryToSearch(search, subcategoryValue)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_ITEM, ITEMTYPE_ARMOR)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_EQUIP, subcategoryValue)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_GAMEPLAY_ACTOR_CATEGORY, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
    end

    function AddJewelryCategory()
        local categoryParams = AddCategory("Jewelry")

        categoryParams:SetName(GetString("SI_TRADINGHOUSECATEGORYHEADER", TRADING_HOUSE_CATEGORY_HEADER_JEWELRY))
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_JEWELRY)
        categoryParams:SetIsAllItemsCategory(true)

        local SUBCATEGORY_ENUM_KEY_PREFIX = "EquipType"
        categoryParams:SetApplyToSearchCallback(ApplyJewelryToSearch)
        categoryParams:SetContainsItemCallback(function(itemLink)
            local actorCategory = GetItemLinkActorCategory(itemLink)
            if actorCategory == GAMEPLAY_ACTOR_CATEGORY_PLAYER then
                local equipType = GetItemLinkEquipType(itemLink)
                for _, searchEquipType in ipairs(JEWELRY_EQUIP_TYPES) do
                    if equipType == searchEquipType then
                        return true, SUBCATEGORY_ENUM_KEY_PREFIX..equipType
                    end
                end
            end
            return false
        end)
        categoryParams:AddFeatureKeys("LevelRange", "JewelryTraits", "JewelryEnchantments")
        AddEnumSubcategories(categoryParams,
        {
            enumKeyPrefix = SUBCATEGORY_ENUM_KEY_PREFIX,
            enumStringPrefix = "SI_EQUIPTYPE",
            allItemsString = GetString(SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ALL_WORN_ARMOR_TYPES),
            iconsForEnumValue = ICONS_FOR_JEWELRY_EQUIP_TYPE,
            enumValues = JEWELRY_EQUIP_TYPES,
        })
    end
end

local AddAllConsumablesCategory, AddConsumableCategory, AddRecipeCategory
do
    local g_allConsumableItemTypes = {}
    local function AddItemTypeToAllConsumables(itemType)
        if not ZO_IsElementInNumericallyIndexedTable(g_allConsumableItemTypes, itemType) then
            table.insert(g_allConsumableItemTypes, itemType)
        end
    end

    local function ApplyAllConsumablesToSearch(search)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_ITEM, g_allConsumableItemTypes)
    end

    function AddAllConsumablesCategory()
        local categoryParams = AddCategory("AllConsumables")

        categoryParams:SetName(GetString("SI_TRADINGHOUSECATEGORYHEADER_ALLCATEGORIES", TRADING_HOUSE_CATEGORY_HEADER_CONSUMABLES))
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_CONSUMABLES)
        categoryParams:SetIsAllItemsCategory(true)

        categoryParams:SetApplyToSearchCallback(ApplyAllConsumablesToSearch)
        categoryParams:AddFeatureKeys("LevelRange")
        AddAllSubcategory(categoryParams)
    end

    local SPECIALIZED_ITEM_TYPES_FOR_CONSUMABLE_ITEM_TYPE = 
    {
        [ITEMTYPE_RACIAL_STYLE_MOTIF] =
        {
            SPECIALIZED_ITEMTYPE_RACIAL_STYLE_MOTIF_CHAPTER,
            SPECIALIZED_ITEMTYPE_RACIAL_STYLE_MOTIF_BOOK,
        },
        [ITEMTYPE_MASTER_WRIT] =
        {
            SPECIALIZED_ITEMTYPE_MASTER_WRIT,
            SPECIALIZED_ITEMTYPE_HOLIDAY_WRIT,
        },
    }

    internalassert(PROVISIONER_SPECIAL_INGREDIENT_TYPE_MAX_VALUE == 4, "Update trading house recipe categories")
    local SPECIALIZED_ITEM_TYPES_FOR_SPECIAL_INGREDIENT_TYPE = 
    {
        [PROVISIONER_SPECIAL_INGREDIENT_TYPE_SPICES] =
        {
            SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_FOOD,
        },
        [PROVISIONER_SPECIAL_INGREDIENT_TYPE_FLAVORING] =
        {
            SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_DRINK,
        },
        [PROVISIONER_SPECIAL_INGREDIENT_TYPE_FURNISHING] =
        {
            SPECIALIZED_ITEMTYPE_RECIPE_BLACKSMITHING_DIAGRAM_FURNISHING,
            SPECIALIZED_ITEMTYPE_RECIPE_CLOTHIER_PATTERN_FURNISHING,
            SPECIALIZED_ITEMTYPE_RECIPE_ENCHANTING_SCHEMATIC_FURNISHING,
            SPECIALIZED_ITEMTYPE_RECIPE_ALCHEMY_FORMULA_FURNISHING,
            SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_DESIGN_FURNISHING,
            SPECIALIZED_ITEMTYPE_RECIPE_WOODWORKING_BLUEPRINT_FURNISHING,
            SPECIALIZED_ITEMTYPE_RECIPE_JEWELRYCRAFTING_SKETCH_FURNISHING,
        },
    }

    local FEATURES_FOR_CONSUMABLE_ITEM_TYPE = 
    {
        [ITEMTYPE_FOOD] = { "LevelRange" },
        [ITEMTYPE_DRINK] = { "LevelRange" },
        [ITEMTYPE_POTION] = { "LevelRange" },
        [ITEMTYPE_POISON] = { "LevelRange" },
    }

    local ICONS_FOR_CONSUMABLE_SPECIALIZED_ITEM_TYPE =
    {
        [SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_FOOD] = ZO_ItemFilterUtils.GetSpecializedItemTypeFilterIcons(SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_FOOD),
        [SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_DRINK] = ZO_ItemFilterUtils.GetSpecializedItemTypeFilterIcons(SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_DRINK),
        [SPECIALIZED_ITEMTYPE_RECIPE_BLACKSMITHING_DIAGRAM_FURNISHING] = ZO_ItemFilterUtils.GetSpecializedItemTypeFilterIcons(SPECIALIZED_ITEMTYPE_RECIPE_BLACKSMITHING_DIAGRAM_FURNISHING),
        [SPECIALIZED_ITEMTYPE_RECIPE_CLOTHIER_PATTERN_FURNISHING] = ZO_ItemFilterUtils.GetSpecializedItemTypeFilterIcons(SPECIALIZED_ITEMTYPE_RECIPE_CLOTHIER_PATTERN_FURNISHING),
        [SPECIALIZED_ITEMTYPE_RECIPE_ENCHANTING_SCHEMATIC_FURNISHING] = ZO_ItemFilterUtils.GetSpecializedItemTypeFilterIcons(SPECIALIZED_ITEMTYPE_RECIPE_ENCHANTING_SCHEMATIC_FURNISHING),
        [SPECIALIZED_ITEMTYPE_RECIPE_ALCHEMY_FORMULA_FURNISHING] = ZO_ItemFilterUtils.GetSpecializedItemTypeFilterIcons(SPECIALIZED_ITEMTYPE_RECIPE_ALCHEMY_FORMULA_FURNISHING),
        [SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_DESIGN_FURNISHING] = ZO_ItemFilterUtils.GetSpecializedItemTypeFilterIcons(SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_DESIGN_FURNISHING),
        [SPECIALIZED_ITEMTYPE_RECIPE_WOODWORKING_BLUEPRINT_FURNISHING] = ZO_ItemFilterUtils.GetSpecializedItemTypeFilterIcons(SPECIALIZED_ITEMTYPE_RECIPE_WOODWORKING_BLUEPRINT_FURNISHING),
        [SPECIALIZED_ITEMTYPE_RECIPE_JEWELRYCRAFTING_SKETCH_FURNISHING] = ZO_ItemFilterUtils.GetSpecializedItemTypeFilterIcons(SPECIALIZED_ITEMTYPE_RECIPE_JEWELRYCRAFTING_SKETCH_FURNISHING),
        [SPECIALIZED_ITEMTYPE_RACIAL_STYLE_MOTIF_CHAPTER] = ZO_ItemFilterUtils.GetSpecializedItemTypeFilterIcons(SPECIALIZED_ITEMTYPE_RACIAL_STYLE_MOTIF_CHAPTER),
        [SPECIALIZED_ITEMTYPE_RACIAL_STYLE_MOTIF_BOOK] = ZO_ItemFilterUtils.GetSpecializedItemTypeFilterIcons(SPECIALIZED_ITEMTYPE_RACIAL_STYLE_MOTIF_BOOK),
        [SPECIALIZED_ITEMTYPE_MASTER_WRIT] = ZO_ItemFilterUtils.GetSpecializedItemTypeFilterIcons(SPECIALIZED_ITEMTYPE_MASTER_WRIT),
        [SPECIALIZED_ITEMTYPE_HOLIDAY_WRIT] = ZO_ItemFilterUtils.GetSpecializedItemTypeFilterIcons(SPECIALIZED_ITEMTYPE_HOLIDAY_WRIT),
    }

    function AddConsumableCategory(mainItemType, ...)
        local allItemTypes = {mainItemType, ...}
        local specializedItemTypes = SPECIALIZED_ITEM_TYPES_FOR_CONSUMABLE_ITEM_TYPE[mainItemType]
        local features = FEATURES_FOR_CONSUMABLE_ITEM_TYPE[mainItemType]
        local function ApplyConsumableToSearch(search, specializedItemType)
            if specializedItemType then
                search:SetFilter(TRADING_HOUSE_FILTER_TYPE_SPECIALIZED_ITEM, specializedItemType)
            else
                search:SetFilter(TRADING_HOUSE_FILTER_TYPE_ITEM, allItemTypes)
            end
        end
        local categoryParams = AddCategory(string.format("Consumable%d", mainItemType))

        categoryParams:SetName(GetString("SI_ITEMTYPE", mainItemType))
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_CONSUMABLES)

        local SUBCATEGORY_ENUM_KEY_PREFIX = "SpecializedItemType"
        categoryParams:SetApplyToSearchCallback(ApplyConsumableToSearch)
        categoryParams:SetContainsItemCallback(function(itemLink)
            local itemLinkItemType, itemLinkSpecializedItemType = GetItemLinkItemType(itemLink)
            if itemLinkItemType == itemType then
                if specializedItemTypes then
                    return true, SUBCATEGORY_ENUM_KEY_PREFIX..itemLinkSpecializedItemType
                else
                    return true
                end
            else
                return false
            end
        end)

        if features then
            categoryParams:AddFeatureKeys(unpack(features))
        end

        if specializedItemTypes == nil then
            AddAllSubcategory(categoryParams)
        else
            AddEnumSubcategories(categoryParams,
            {
                enumKeyPrefix = SUBCATEGORY_ENUM_KEY_PREFIX,
                enumStringPrefix = "SI_SPECIALIZEDITEMTYPE",
                allItemsString = GetString(SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ALL_RECIPE_TYPES),
                iconsForEnumValue = ICONS_FOR_CONSUMABLE_SPECIALIZED_ITEM_TYPE,
                enumValues = specializedItemTypes,
            })
        end

        for _, itemType in ipairs(allItemTypes) do
            AddItemTypeToAllConsumables(itemType)
        end
    end

    function AddRecipeCategory(specialIngredientType)
        local specializedItemTypes = SPECIALIZED_ITEM_TYPES_FOR_SPECIAL_INGREDIENT_TYPE[specialIngredientType]
        local categoryParams = AddCategory(string.format("ConsumableRecipe%d", specialIngredientType))

        categoryParams:SetName(GetString("SI_PROVISIONERSPECIALINGREDIENTTYPE_TRADINGHOUSERECIPECATEGORY", specialIngredientType))
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_CONSUMABLES)

        local SUBCATEGORY_ENUM_KEY_PREFIX = "SpecializedItemType"
        categoryParams:SetApplyToSearchCallback(function(search, specializedItemType)
            search:SetFilter(TRADING_HOUSE_FILTER_TYPE_SPECIALIZED_ITEM, specializedItemType)
        end)
        categoryParams:SetContainsItemCallback(function(itemLink)
            local itemLinkItemType, itemLinkSpecializedItemType = GetItemLinkItemType(itemLink)
            if ZO_IsElementInNumericallyIndexedTable(specializedItemTypes, itemLinkSpecializedItemType) then
                return true, SUBCATEGORY_ENUM_KEY_PREFIX..itemLinkSpecializedItemType
            end
            return false
        end)

        -- no features

        AddEnumSubcategories(categoryParams,
        {
            enumKeyPrefix = SUBCATEGORY_ENUM_KEY_PREFIX,
            enumStringPrefix = "SI_SPECIALIZEDITEMTYPE",
            allItemsString = GetString(SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ALL_RECIPE_TYPES),
            iconsForEnumValue = ICONS_FOR_CONSUMABLE_SPECIALIZED_ITEM_TYPE,
            enumValues = specializedItemTypes,
        })

        -- All recipes are consumables, even though we are only registering a subset of recipes per category.
        -- this will be called more than once, but that's okay because we deduplicate inside of AddItemTypeToAllConsumables().
        AddItemTypeToAllConsumables(ITEMTYPE_RECIPE)
    end
end

local AddAllMaterialsCategory
local AddTradeMaterialCategory
local AddProvisioningIngredientCategory
local AddStyleMaterialCategory
local AddTraitMaterialCategory
local AddFurnishingMaterialCategory
do
    local g_allMaterialItemTypes = {}
    local function AddItemTypeToAllMaterials(itemType)
        table.insert(g_allMaterialItemTypes, itemType)
    end

    local function ApplyAllMaterialsToSearch(search)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_ITEM, g_allMaterialItemTypes)
    end

    function AddAllMaterialsCategory()
        local categoryParams = AddCategory("AllMaterials")

        categoryParams:SetName(GetString("SI_TRADINGHOUSECATEGORYHEADER_ALLCATEGORIES", TRADING_HOUSE_CATEGORY_HEADER_MATERIALS))
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_MATERIALS)
        categoryParams:SetIsAllItemsCategory(true)

        categoryParams:SetApplyToSearchCallback(ApplyAllMaterialsToSearch)
        -- No features
        AddAllSubcategory(categoryParams)
    end

    internalassert(CRAFTING_TYPE_MAX_VALUE == 7, "Add new tradeskill to trading house")
    local ICONS_FOR_TRADESKILL_ITEM_TYPES =
    {
        [ITEMTYPE_BLACKSMITHING_RAW_MATERIAL] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_BLACKSMITHING_RAW_MATERIAL),
        [ITEMTYPE_BLACKSMITHING_MATERIAL] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_BLACKSMITHING_MATERIAL),
        [ITEMTYPE_BLACKSMITHING_BOOSTER] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_BLACKSMITHING_BOOSTER),
        [ITEMTYPE_CLOTHIER_RAW_MATERIAL] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_CLOTHIER_RAW_MATERIAL),
        [ITEMTYPE_CLOTHIER_MATERIAL] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_CLOTHIER_MATERIAL),
        [ITEMTYPE_CLOTHIER_BOOSTER] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_CLOTHIER_BOOSTER),
        [ITEMTYPE_WOODWORKING_RAW_MATERIAL] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_WOODWORKING_RAW_MATERIAL),
        [ITEMTYPE_WOODWORKING_MATERIAL] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_WOODWORKING_MATERIAL),
        [ITEMTYPE_WOODWORKING_BOOSTER] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_WOODWORKING_BOOSTER),
        [ITEMTYPE_JEWELRYCRAFTING_RAW_MATERIAL] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_JEWELRYCRAFTING_RAW_MATERIAL),
        [ITEMTYPE_JEWELRYCRAFTING_MATERIAL] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_JEWELRYCRAFTING_MATERIAL),
        [ITEMTYPE_JEWELRYCRAFTING_RAW_BOOSTER] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_JEWELRYCRAFTING_RAW_BOOSTER),
        [ITEMTYPE_JEWELRYCRAFTING_BOOSTER] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_JEWELRYCRAFTING_BOOSTER),
        [ITEMTYPE_ENCHANTING_RUNE_POTENCY] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_ENCHANTING_RUNE_POTENCY),
        [ITEMTYPE_ENCHANTING_RUNE_ASPECT] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_ENCHANTING_RUNE_ASPECT),
        [ITEMTYPE_ENCHANTING_RUNE_ESSENCE] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_ENCHANTING_RUNE_ESSENCE),
        [ITEMTYPE_POTION_BASE] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_POTION_BASE),
        [ITEMTYPE_POISON_BASE] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_POISON_BASE),
        [ITEMTYPE_REAGENT] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_REAGENT),
        [ITEMTYPE_RAW_MATERIAL] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_RAW_MATERIAL),
        [ITEMTYPE_STYLE_MATERIAL] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_STYLE_MATERIAL),
        [ITEMTYPE_WEAPON_TRAIT] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_WEAPON_TRAIT),
        [ITEMTYPE_ARMOR_TRAIT] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_ARMOR_TRAIT),
        [ITEMTYPE_JEWELRY_RAW_TRAIT] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_JEWELRY_RAW_TRAIT),
        [ITEMTYPE_JEWELRY_TRAIT] = ZO_ItemFilterUtils.GetItemTypeFilterIcons(ITEMTYPE_JEWELRY_TRAIT),
    }

    -- Used to make material item types "behave" as the same itemtype, to stay selected when browsing through materials, etc.
    local KEY_OVERRIDE_FOR_TRADESKILL_ITEM_TYPE =
    {
        [ITEMTYPE_BLACKSMITHING_RAW_MATERIAL] = "RawMaterial",
        [ITEMTYPE_BLACKSMITHING_MATERIAL] = "Material",
        [ITEMTYPE_BLACKSMITHING_BOOSTER] = "Booster",

        [ITEMTYPE_CLOTHIER_RAW_MATERIAL] = "RawMaterial",
        [ITEMTYPE_CLOTHIER_MATERIAL] = "Material",
        [ITEMTYPE_CLOTHIER_BOOSTER] = "Booster",

        [ITEMTYPE_WOODWORKING_RAW_MATERIAL] = "RawMaterial",
        [ITEMTYPE_WOODWORKING_MATERIAL] = "Material",
        [ITEMTYPE_WOODWORKING_BOOSTER] = "Booster",

        [ITEMTYPE_JEWELRYCRAFTING_RAW_MATERIAL] = "RawMaterial",
        [ITEMTYPE_JEWELRYCRAFTING_MATERIAL] = "Material",
        [ITEMTYPE_JEWELRYCRAFTING_BOOSTER] = "Booster",

        [ITEMTYPE_RAW_MATERIAL] = "RawMaterial",
        [ITEMTYPE_STYLE_MATERIAL] = "Material",
    }

    local function ApplyMaterialToSearch(search, itemType)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_ITEM, itemType)
    end

    function AddTradeMaterialCategory(tradeskillType)
        local tradeskillName = GetCraftingSkillName(tradeskillType)
        local itemTypes = ZO_ItemFilterUtils.GetItemTypesByCraftingType(tradeskillType)

        local categoryParams = AddCategory(string.format("TradeMaterial%d", tradeskillType))

        categoryParams:SetName(tradeskillName)
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_MATERIALS)

        local SUBCATEGORY_ENUM_KEY_PREFIX = "ItemType"
        categoryParams:SetApplyToSearchCallback(ApplyMaterialToSearch)
        categoryParams:SetContainsItemCallback(function(itemLink)
            local itemType = GetItemLinkItemType(itemLink)
            for _, searchItemType in ipairs(itemTypes) do
                if itemType == searchItemType then
                    return true, KEY_OVERRIDE_FOR_TRADESKILL_ITEM_TYPE[itemType]
                end
            end
            return false
        end)
        -- No features
        AddEnumSubcategories(categoryParams,
        {
            enumKeyPrefix = SUBCATEGORY_ENUM_KEY_PREFIX,
            enumStringPrefix = "SI_ITEMTYPE",
            allItemsString = GetString(SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ALL_MATERIALS),
            iconsForEnumValue = ICONS_FOR_TRADESKILL_ITEM_TYPES,
            enumValues = itemTypes,
            keyOverrideForEnumValue = KEY_OVERRIDE_FOR_TRADESKILL_ITEM_TYPE,
        })

        for _, itemType in ipairs(itemTypes) do
            AddItemTypeToAllMaterials(itemType)
        end
    end

    local PROVISIONING_INGREDIENT_SUBCATEGORIES =
    {
        {
            name = GetString(SI_TRADING_HOUSE_BROWSE_PROVISIONING_FOOD_INGREDIENTS),
            value = ZO_ItemFilterUtils.GetSpecializedItemTypesByItemTypeDisplayCategory(ITEM_TYPE_DISPLAY_CATEGORY_FOOD_INGREDIENT),
            icons = ZO_ItemFilterUtils.GetItemTypeDisplayCategoryFilterIcons(ITEM_TYPE_DISPLAY_CATEGORY_FOOD_INGREDIENT),
        },
        {
            name = GetString(SI_TRADING_HOUSE_BROWSE_PROVISIONING_DRINK_INGREDIENTS),
            value = ZO_ItemFilterUtils.GetSpecializedItemTypesByItemTypeDisplayCategory(ITEM_TYPE_DISPLAY_CATEGORY_DRINK_INGREDIENT),
            icons = ZO_ItemFilterUtils.GetItemTypeDisplayCategoryFilterIcons(ITEM_TYPE_DISPLAY_CATEGORY_DRINK_INGREDIENT),
        },
        {
            name = GetString(SI_TRADING_HOUSE_BROWSE_PROVISIONING_RARE_INGREDIENTS),
            value =
            {
                SPECIALIZED_ITEMTYPE_INGREDIENT_RARE,
            },
            icons = ZO_ItemFilterUtils.GetSpecializedItemTypeFilterIcons(SPECIALIZED_ITEMTYPE_INGREDIENT_RARE),
        },
    }

    local function ApplyProvisioningIngredientToSearch(search, specializedItemType)
        if specializedItemType then
            search:SetFilter(TRADING_HOUSE_FILTER_TYPE_SPECIALIZED_ITEM, specializedItemType)
        else
            search:SetFilter(TRADING_HOUSE_FILTER_TYPE_ITEM, ITEMTYPE_INGREDIENT)
        end
    end

    function AddProvisioningIngredientCategory()
        local tradeskillName = GetCraftingSkillName(CRAFTING_TYPE_PROVISIONING)

        local categoryParams = AddCategory(string.format("TradeMaterial%d", CRAFTING_TYPE_PROVISIONING))

        categoryParams:SetName(tradeskillName)
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_MATERIALS)

        local SUBCATEGORY_KEY_PREFIX = "ProvisioningIngredient"
        categoryParams:SetApplyToSearchCallback(ApplyProvisioningIngredientToSearch)
        categoryParams:SetContainsItemCallback(function(itemLink)
            local itemLinkItemType, itemLinkSpecializedItemType = GetItemLinkItemType(itemLink)
            if itemLinkItemType == ITEMTYPE_INGREDIENT then
                for subcategoryIndex, subcategoryData in ipairs(PROVISIONING_INGREDIENT_SUBCATEGORIES) do
                    for _, specializedItemType in ipairs(subcategoryData.value) do
                        if itemLinkSpecializedItemType == specializedItemType then
                            return true, SUBCATEGORY_KEY_PREFIX..subcategoryIndex
                        end
                    end
                end
                return true
            else
                return false
            end
        end)
        -- No features
        AddAllSubcategory(categoryParams, GetString(SI_TRADING_HOUSE_BROWSE_PROVISIONING_ALL_INGREDIENTS))

        for subcategoryIndex, subcategoryData in ipairs(PROVISIONING_INGREDIENT_SUBCATEGORIES) do
            local key = SUBCATEGORY_KEY_PREFIX..subcategoryIndex
            categoryParams:AddSubcategory(key, subcategoryData.name, subcategoryData.icons, subcategoryData.value)
        end


        AddItemTypeToAllMaterials(ITEMTYPE_INGREDIENT)
    end

    local STYLE_MATERIAL_TYPES =
    {
        ITEMTYPE_RAW_MATERIAL,
        ITEMTYPE_STYLE_MATERIAL,
    }

    function AddStyleMaterialCategory()
        local categoryParams = AddCategory("StyleMaterial")

        categoryParams:SetName(GetString("SI_ITEMTYPE", ITEMTYPE_STYLE_MATERIAL))
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_MATERIALS)

        local SUBCATEGORY_ENUM_KEY_PREFIX = "ItemType"
        categoryParams:SetApplyToSearchCallback(ApplyMaterialToSearch)
        categoryParams:SetContainsItemCallback(function(itemLink)
            local itemLinkItemType = GetItemLinkItemType(itemLink)
            for _, itemType in ipairs(STYLE_MATERIAL_TYPES) do
                if itemLinkItemType == itemType then
                    return true, SUBCATEGORY_ENUM_KEY_PREFIX..itemType
                end
            end
            return false
        end)
        -- No features
        AddEnumSubcategories(categoryParams,
        {
            enumKeyPrefix = SUBCATEGORY_ENUM_KEY_PREFIX,
            enumStringPrefix = "SI_ITEMTYPE",
            allItemsString = GetString(SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ALL_MATERIALS),
            iconsForEnumValue = ICONS_FOR_TRADESKILL_ITEM_TYPES,
            enumValues = STYLE_MATERIAL_TYPES,
        })

        for _, itemType in ipairs(STYLE_MATERIAL_TYPES) do
            AddItemTypeToAllMaterials(itemType)
        end
    end

    local TRAIT_MATERIAL_TYPES =
    {
        ITEMTYPE_WEAPON_TRAIT,
        ITEMTYPE_ARMOR_TRAIT,
        ITEMTYPE_JEWELRY_RAW_TRAIT,
        ITEMTYPE_JEWELRY_TRAIT,
    }

    function AddTraitMaterialCategory()
        local categoryParams = AddCategory("TraitMaterial")

        categoryParams:SetName(GetString(SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_TRAIT_MATERIAL))
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_MATERIALS)

        local SUBCATEGORY_ENUM_KEY_PREFIX = "ItemType"
        categoryParams:SetApplyToSearchCallback(ApplyMaterialToSearch)
        categoryParams:SetContainsItemCallback(function(itemLink)
            local itemType = GetItemLinkItemType(itemLink)
            for _, searchItemType in ipairs(TRAIT_MATERIAL_TYPES) do
                if itemType == searchItemType then
                    return true, SUBCATEGORY_ENUM_KEY_PREFIX..itemType
                end
            end
            return false
        end)
        -- No features
        AddEnumSubcategories(categoryParams,
        {
            enumKeyPrefix = SUBCATEGORY_ENUM_KEY_PREFIX,
            enumStringPrefix = "SI_ITEMTYPE",
            allItemsString = GetString(SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ALL_MATERIALS),
            iconsForEnumValue = ICONS_FOR_TRADESKILL_ITEM_TYPES,
            enumValues = TRAIT_MATERIAL_TYPES,
        })

        for _, itemType in ipairs(TRAIT_MATERIAL_TYPES) do
            AddItemTypeToAllMaterials(itemType)
        end
    end

    local function ApplyFurnishingMaterialToSearch(search)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_ITEM, ITEMTYPE_FURNISHING_MATERIAL)
    end

    function AddFurnishingMaterialCategory()
        local categoryParams = AddCategory("FurnishingMaterial")

        categoryParams:SetName(GetString("SI_ITEMTYPE", ITEMTYPE_FURNISHING_MATERIAL))
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_MATERIALS)

        categoryParams:SetApplyToSearchCallback(ApplyFurnishingMaterialToSearch)
        categoryParams:SetContainsItemCallback(function(itemLink)
            return GetItemLinkItemType(itemLink) == ITEMTYPE_FURNISHING_MATERIAL
        end)
        -- No features
        AddAllSubcategory(categoryParams)

        AddItemTypeToAllMaterials(ITEMTYPE_FURNISHING_MATERIAL)
    end
end

local AddAllGlyphsCategory, AddGlyphCategory
do
    local function ApplyAllGlyphsToSearch(search)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_ITEM, {ITEMTYPE_GLYPH_WEAPON, ITEMTYPE_GLYPH_ARMOR, ITEMTYPE_GLYPH_JEWELRY})
    end

    function AddAllGlyphsCategory(glyphItemType)
        local categoryParams = AddCategory("AllGlyphs")

        categoryParams:SetName(GetString("SI_TRADINGHOUSECATEGORYHEADER_ALLCATEGORIES", TRADING_HOUSE_CATEGORY_HEADER_GLYPHS))
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_GLYPHS)
        categoryParams:SetIsAllItemsCategory(true)

        categoryParams:SetApplyToSearchCallback(ApplyAllGlyphsToSearch)
        categoryParams:AddFeatureKeys("GlyphLevelRange")
        AddAllSubcategory(categoryParams)
    end

    local GLYPH_TYPE_TO_FEATURE =
    {
        [ITEMTYPE_GLYPH_WEAPON] = "WeaponEnchantments",
        [ITEMTYPE_GLYPH_ARMOR] = "ArmorEnchantments",
        [ITEMTYPE_GLYPH_JEWELRY] = "JewelryEnchantments",
    }

    function AddGlyphCategory(glyphItemType)
        local function ApplyGlyphToSearch(search)
            search:SetFilter(TRADING_HOUSE_FILTER_TYPE_ITEM, glyphItemType)
        end

        local categoryParams = AddCategory(string.format("Glyph%d", glyphItemType))

        categoryParams:SetName(GetString("SI_ITEMTYPE", glyphItemType))
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_GLYPHS)

        categoryParams:SetApplyToSearchCallback(ApplyGlyphToSearch)
        categoryParams:SetContainsItemCallback(function(itemLink)
            return GetItemLinkItemType(itemLink) == glyphItemType
        end)
        categoryParams:AddFeatureKeys("GlyphLevelRange", internalassert(GLYPH_TYPE_TO_FEATURE[glyphItemType]))
        AddAllSubcategory(categoryParams)
    end
end

local AddAllFurnishingsCategory, AddFurnishingCategory
do
    local g_allFurnishingSpecializedItemTypes = {}
    local function AddSpecializedItemTypeToAllFurnishings(specializedItemType)
        table.insert(g_allFurnishingSpecializedItemTypes, specializedItemType)
    end

    local function ApplyAllFurnishingsToSearch(search)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_SPECIALIZED_ITEM, g_allFurnishingSpecializedItemTypes)
    end

    function AddAllFurnishingsCategory()
        local categoryParams = AddCategory("AllFurnishings")

        categoryParams:SetName(GetString("SI_TRADINGHOUSECATEGORYHEADER_ALLCATEGORIES", TRADING_HOUSE_CATEGORY_HEADER_FURNISHINGS))
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_FURNISHINGS)
        categoryParams:SetIsAllItemsCategory(true)

        categoryParams:SetApplyToSearchCallback(ApplyAllFurnishingsToSearch)
        -- No features
        AddAllSubcategory(categoryParams)
    end

    function AddFurnishingCategory(...)
        local specializedItemTypes = {...}
        local function ApplyFurnitureToSearch(search)
            search:SetFilter(TRADING_HOUSE_FILTER_TYPE_SPECIALIZED_ITEM, specializedItemTypes)
        end
        local PRIMARY_ITEM_INDEX = 1
        local primarySpecializedItemType = specializedItemTypes[PRIMARY_ITEM_INDEX]

        local categoryParams = AddCategory(string.format("Furnishing%d", primarySpecializedItemType))

        if primarySpecializedItemType == SPECIALIZED_ITEMTYPE_FURNISHING_ORNAMENTAL then
            categoryParams:SetName(GetString(SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ORNAMENTAL_FURNISHINGS))
        else
            categoryParams:SetName(GetString("SI_SPECIALIZEDITEMTYPE", primarySpecializedItemType))
        end
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_FURNISHINGS)

        categoryParams:SetApplyToSearchCallback(ApplyFurnitureToSearch)
        categoryParams:SetContainsItemCallback(function(itemLink)
            local _, specializedItemType = GetItemLinkItemType(itemLink)
            for _, searchSpecializedItemType in ipairs(specializedItemTypes) do
                if specializedItemType == searchSpecializedItemType then
                    return true
                end
            end
            return false
        end)
        -- No features
        AddAllSubcategory(categoryParams)

        for _, specializedItemType in ipairs(specializedItemTypes) do
            AddSpecializedItemTypeToAllFurnishings(specializedItemType)
        end
    end
end

local AddAllCompanionEquipmentCategory, AddCompanionEquipmentCategory
do
    local COMPANION_EQUIPMENT_DISPLAY_CATEGORY_LIST =
    {
        ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS,
        ITEM_TYPE_DISPLAY_CATEGORY_ARMOR,
        ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY,
    }
    local iconsForCompanionEquipmentType = {}
    local enumValuesForCompanionEquipmentType = {}

    for _, displayCategory in ipairs(COMPANION_EQUIPMENT_DISPLAY_CATEGORY_LIST) do
        iconsForCompanionEquipmentType[displayCategory] = {}
        enumValuesForCompanionEquipmentType[displayCategory] = {}

        local equipmentFilterTypeSubcategories = ZO_ItemFilterUtils.GetSubCategoryTypesByDisplayCategoryType(displayCategory)
        for _, equipmentFilterType in pairs(equipmentFilterTypeSubcategories) do
            if equipmentFilterType ~= EQUIPMENT_FILTER_TYPE_NONE then
                local displayInfo = ZO_ItemFilterUtils.GetEquipmentFilterTypeFilterDisplayInfo(equipmentFilterType)
                iconsForCompanionEquipmentType[displayCategory][equipmentFilterType] = displayInfo.icons
                table.insert(enumValuesForCompanionEquipmentType[displayCategory], equipmentFilterType)
            end
        end
    end

    local EVERY_VALID_WEAPON_TYPE = ZO_ItemFilterUtils.GetAllWeaponTypesInEquipmentFilterTypes()

    local function ApplyAllCompanionEquipmentToSearch(search, subcategoryValue)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_ITEM, { ITEMTYPE_WEAPON, ITEMTYPE_ARMOR, ITEMTYPE_JEWELRY })
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_GAMEPLAY_ACTOR_CATEGORY, GAMEPLAY_ACTOR_CATEGORY_COMPANION)
    end

    function AddAllCompanionEquipmentCategory()
        local categoryParams = AddCategory("AllCompanionEquipment")

        categoryParams:SetName(GetString("SI_TRADINGHOUSECATEGORYHEADER_ALLCATEGORIES", TRADING_HOUSE_CATEGORY_HEADER_COMPANION_EQUIPMENT))
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_COMPANION_EQUIPMENT)
        categoryParams:SetIsAllItemsCategory(true)

        categoryParams:SetApplyToSearchCallback(ApplyAllCompanionEquipmentToSearch)
        AddAllSubcategory(categoryParams)
    end

    function AddCompanionEquipmentCategory(companionEquipmentDisplayCategory)
        local function ApplyCompanionEquipmentWeaponsToSearch(search, subFilterType)
            local weaponTypes = {}
            if type(subFilterType) == "table" then
                -- subFilterType being a table indicates this is the all option so just get every related weapon type
                weaponTypes = EVERY_VALID_WEAPON_TYPE
            else
                weaponTypes = ZO_ItemFilterUtils.GetWeaponTypesByEquipmentFilterType(subFilterType)
            end

            search:SetFilter(TRADING_HOUSE_FILTER_TYPE_ITEM, ITEMTYPE_WEAPON)
            search:SetFilter(TRADING_HOUSE_FILTER_TYPE_WEAPON, weaponTypes)
            search:SetFilter(TRADING_HOUSE_FILTER_TYPE_GAMEPLAY_ACTOR_CATEGORY, GAMEPLAY_ACTOR_CATEGORY_COMPANION)
        end

        local function ApplyCompanionEquipmentArmorToSearch(search, subFilterType)
            if type(subFilterType) == "table" then
                -- subFilterType being a table indicates this is the all option so just get every related armor type
                local ARMOR_EQUIP_TYPES =
                {
                    EQUIP_TYPE_CHEST,
                    EQUIP_TYPE_FEET,
                    EQUIP_TYPE_HAND,
                    EQUIP_TYPE_HEAD,
                    EQUIP_TYPE_LEGS,
                    EQUIP_TYPE_SHOULDERS,
                    EQUIP_TYPE_WAIST,
                }

                -- So this is a bit clever: Each piece of apparel has a slot it can be equipped to, so we enumerate those.
                -- then we also need to catch shields, so we specify that the weapon type must either be SHIELD or NONE (which is the value all non-weapons have)
                -- This catches normal armor, and shields.
                local ALL_APPAREL_EQUIP_TYPES = { EQUIP_TYPE_OFF_HAND }
                ZO_CombineNumericallyIndexedTables(ALL_APPAREL_EQUIP_TYPES, ARMOR_EQUIP_TYPES)

                local ALL_APPAREL_WEAPON_TYPES =
                {
                    WEAPON_TYPE_NONE,
                    WEAPON_TYPE_SHIELD
                }
                search:SetFilter(TRADING_HOUSE_FILTER_TYPE_EQUIP, ALL_APPAREL_EQUIP_TYPES)
                search:SetFilter(TRADING_HOUSE_FILTER_TYPE_WEAPON, ALL_APPAREL_WEAPON_TYPES)
            else
                local armorType = ZO_ItemFilterUtils.GetArmorTypesByEquipmentFilterType(subFilterType)
                if armorType then
                    search:SetFilter(TRADING_HOUSE_FILTER_TYPE_ARMOR, armorType)
                elseif subFilterType == EQUIPMENT_FILTER_TYPE_SHIELD then
                    search:SetFilter(TRADING_HOUSE_FILTER_TYPE_WEAPON, WEAPONTYPE_SHIELD)
                end
            end
            search:SetFilter(TRADING_HOUSE_FILTER_TYPE_GAMEPLAY_ACTOR_CATEGORY, GAMEPLAY_ACTOR_CATEGORY_COMPANION)
        end

        local function ApplyCompanionEquipmentJewelryToSearch(search, subFilterType)
            local jewelryTypes = {}
            if type(subFilterType) == "table" then
                search:SetFilter(TRADING_HOUSE_FILTER_TYPE_EQUIP, { EQUIP_TYPE_NECK, EQUIP_TYPE_RING })
            else
                if subFilterType == EQUIPMENT_FILTER_TYPE_NECK then
                    search:SetFilter(TRADING_HOUSE_FILTER_TYPE_EQUIP, EQUIP_TYPE_NECK)
                elseif subFilterType == EQUIPMENT_FILTER_TYPE_RING then
                    search:SetFilter(TRADING_HOUSE_FILTER_TYPE_EQUIP, EQUIP_TYPE_RING)
                end
            end
            search:SetFilter(TRADING_HOUSE_FILTER_TYPE_GAMEPLAY_ACTOR_CATEGORY, GAMEPLAY_ACTOR_CATEGORY_COMPANION)
        end

        local APPLY_TO_SEARCH_FUNCTIONS =
        {
            [ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS] = ApplyCompanionEquipmentWeaponsToSearch,
            [ITEM_TYPE_DISPLAY_CATEGORY_ARMOR] = ApplyCompanionEquipmentArmorToSearch,
            [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY] = ApplyCompanionEquipmentJewelryToSearch,
        }

        local FEATURE_KEYS =
        {
            [ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS] = "CompanionWeaponTraits",
            [ITEM_TYPE_DISPLAY_CATEGORY_ARMOR] = "CompanionArmorTraits",
            [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY] = "CompanionJewelryTraits",
        }

        local categoryParams = AddCategory(string.format("Companion%d", companionEquipmentDisplayCategory))

        categoryParams:SetName(GetString("SI_ITEMTYPEDISPLAYCATEGORY", companionEquipmentDisplayCategory))
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_COMPANION_EQUIPMENT)

        categoryParams:SetApplyToSearchCallback(APPLY_TO_SEARCH_FUNCTIONS[companionEquipmentDisplayCategory])
        categoryParams:SetContainsItemCallback(function(itemLink)
            local actorCategory = GetItemLinkActorCategory(itemLink)
            if actorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION then
                local linkItemType = GetItemLinkItemType(itemLink)
                local itemTypeList = ZO_ItemFilterUtils.GetSubCategoryTypesByDisplayCategoryType(companionEquipmentDisplayCategory)
                for _, itemType in ipairs(itemTypeList) do
                    if linkItemType == itemType then
                        return true
                    end
                end
            end
            return false
        end)

        categoryParams:AddFeatureKeys(FEATURE_KEYS[companionEquipmentDisplayCategory])

        AddEnumSubcategories(categoryParams,
        {
            enumKeyPrefix = "equipmentFilterType",
            enumStringPrefix = "SI_EQUIPMENTFILTERTYPE",
            allItemsString = GetString(SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ALL),
            iconsForEnumValue = iconsForCompanionEquipmentType[companionEquipmentDisplayCategory],
            enumValues = enumValuesForCompanionEquipmentType[companionEquipmentDisplayCategory],
        })
    end
end

local function AddMiscCategory(itemType)
    local function ApplyItemTypeToSearch(search)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_ITEM, itemType)
    end

    local categoryParams = AddCategory(string.format("Misc%d", itemType))

    categoryParams:SetName(GetString("SI_ITEMTYPE", itemType))
    categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_MISC)

    categoryParams:SetApplyToSearchCallback(ApplyItemTypeToSearch)
    categoryParams:SetContainsItemCallback(function(itemLink)
        return GetItemLinkItemType(itemLink) == itemType
    end)
    -- no features
    AddAllSubcategory(categoryParams)
end

local AddTrophyCategory
do
    local TROPHY_SUBCATEGORIES =
    {
        {
            name = GetString("SI_SPECIALIZEDITEMTYPE", SPECIALIZED_ITEMTYPE_TROPHY_TREASURE_MAP),
            value = { SPECIALIZED_ITEMTYPE_TROPHY_TREASURE_MAP },
            icons = ZO_ItemFilterUtils.GetSpecializedItemTypeFilterIcons(SPECIALIZED_ITEMTYPE_TROPHY_TREASURE_MAP),
        },
        {
            name = GetString("SI_SPECIALIZEDITEMTYPE", SPECIALIZED_ITEMTYPE_TROPHY_RECIPE_FRAGMENT),
            value = { SPECIALIZED_ITEMTYPE_TROPHY_RECIPE_FRAGMENT },
            icons = ZO_ItemFilterUtils.GetSpecializedItemTypeFilterIcons(SPECIALIZED_ITEMTYPE_TROPHY_RECIPE_FRAGMENT),
        },
        {
            name = GetString("SI_SPECIALIZEDITEMTYPE", SPECIALIZED_ITEMTYPE_TROPHY_SCROLL),
            value = { SPECIALIZED_ITEMTYPE_TROPHY_SCROLL },
            icons = ZO_ItemFilterUtils.GetSpecializedItemTypeFilterIcons(SPECIALIZED_ITEMTYPE_TROPHY_SCROLL),
        },
        {
            name = GetString("SI_SPECIALIZEDITEMTYPE", SPECIALIZED_ITEMTYPE_TROPHY_RUNEBOX_FRAGMENT),
            value = { SPECIALIZED_ITEMTYPE_TROPHY_RUNEBOX_FRAGMENT },
            icons = ZO_ItemFilterUtils.GetSpecializedItemTypeFilterIcons(SPECIALIZED_ITEMTYPE_TROPHY_RUNEBOX_FRAGMENT),
        },
        {
            name = GetString(SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_OTHER_TROPHY_TYPES),
            value =
            {
                SPECIALIZED_ITEMTYPE_TROPHY_SURVEY_REPORT,
                SPECIALIZED_ITEMTYPE_TROPHY_KEY_FRAGMENT,
                SPECIALIZED_ITEMTYPE_TROPHY_MUSEUM_PIECE,
                SPECIALIZED_ITEMTYPE_TROPHY_SCROLL,
                SPECIALIZED_ITEMTYPE_TROPHY_MATERIAL_UPGRADER,
                SPECIALIZED_ITEMTYPE_TROPHY_KEY,
                SPECIALIZED_ITEMTYPE_TROPHY_COLLECTIBLE_FRAGMENT,
                SPECIALIZED_ITEMTYPE_TROPHY_UPGRADE_FRAGMENT,
                SPECIALIZED_ITEMTYPE_TROPHY_DUNGEON_BUFF_INGREDIENT,
                SPECIALIZED_ITEMTYPE_TROPHY_TRIBUTE_CLUE,
            },
            icons = ZO_ItemFilterUtils.GetItemTypeDisplayCategoryFilterIcons(ITEM_TYPE_DISPLAY_CATEGORY_TROPHY),
        },
    }

    -- There are some items in the game that are itemtype trophy, but have a
    -- specialized itemtype outside of this category. these should be filtered
    -- elsewhere, so instead of filtering by itemtype we need to filter by all
    -- specialized itemtypes
    local ALL_TROPHY_SPECIALIZED_ITEMTYPES = {}
    for _, subcategoryData in ipairs(TROPHY_SUBCATEGORIES) do
        ZO_CombineNumericallyIndexedTables(ALL_TROPHY_SPECIALIZED_ITEMTYPES, subcategoryData.value)
    end

    local function ApplyTrophyToSearch(search, subcategoryValue)
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_SPECIALIZED_ITEM, subcategoryValue)
    end

    local SUBCATEGORY_KEY_PREFIX = "TrophySubcategory"
    local function IsItemLinkTrophy(itemLink)
        local _, itemLinkSpecializedItemType = GetItemLinkItemType(itemLink)
        for subcategoryIndex, subcategoryData in ipairs(TROPHY_SUBCATEGORIES) do
            if ZO_IsElementInNumericallyIndexedTable(subcategoryData.value, itemLinkSpecializedItemType) then
                return true, SUBCATEGORY_KEY_PREFIX..subcategoryIndex
            end
        end
        return false
    end

    function AddTrophyCategory()
        local categoryParams = AddCategory("Trophy")

        categoryParams:SetName(GetString("SI_ITEMTYPE", ITEMTYPE_TROPHY))
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_MISC)

        categoryParams:SetApplyToSearchCallback(ApplyTrophyToSearch)
        categoryParams:SetContainsItemCallback(IsItemLinkTrophy)
        -- No features
        AddAllSubcategory(categoryParams, GetString(SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ALL_TROPHY_TYPES), ALL_TROPHY_SPECIALIZED_ITEMTYPES)

        for subcategoryIndex, subcategoryData in ipairs(TROPHY_SUBCATEGORIES) do
            local key = SUBCATEGORY_KEY_PREFIX..subcategoryIndex
            categoryParams:AddSubcategory(key, subcategoryData.name, subcategoryData.icons, subcategoryData.value)
        end
    end
end

local AddGuildTabardCategory
do
    local function ApplyTabardToSearch(search)
        -- The only guild specific items are tabards, and tabards can't be posted to the normal trading house.
        search:SetShouldShowGuildSpecificItems(true)
    end

    function AddGuildTabardCategory()
        local categoryParams = AddCategory("Tabards")

        categoryParams:SetName(GetString("SI_ITEMTYPE", ITEMTYPE_TABARD))
        categoryParams:SetHeader(TRADING_HOUSE_CATEGORY_HEADER_MISC)

        categoryParams:SetApplyToSearchCallback(ApplyTabardToSearch)
        -- no features
        AddAllSubcategory(categoryParams)
    end
end


-----------------------
-- Search Categories --
-----------------------

--[[
    This is a list of search categories in the order they will appear in the UI.
    When adding a new category, create an AddXCategory function and add it to this list, making sure that it's in the same group as the other categories of its header.
    Any item that could be sold on the trading house should be categorized.
]]--

internalassert(ITEMTYPE_MAX_VALUE == 71, "Do you need to update the trading house with your new itemtype?")
internalassert(SPECIALIZED_ITEMTYPE_MAX_VALUE == 3150, "Do you need to update the trading house with your new specialized itemtype?")
internalassert(EQUIP_TYPE_MAX_VALUE == 15, "Do you need to update the trading house with your new equip type?")

-- All Items
AddAllItemsCategory()

-- Weapon
AddAllWeaponsCategory()
AddWeaponCategory(EQUIPMENT_FILTER_TYPE_ONE_HANDED)
AddWeaponCategory(EQUIPMENT_FILTER_TYPE_TWO_HANDED)
AddWeaponCategory(EQUIPMENT_FILTER_TYPE_BOW)
AddWeaponCategory(EQUIPMENT_FILTER_TYPE_DESTRO_STAFF)
AddWeaponCategory(EQUIPMENT_FILTER_TYPE_RESTO_STAFF)

-- Apparel
AddAllApparelCategory()
AddArmorCategory(ARMORTYPE_LIGHT)
AddArmorCategory(ARMORTYPE_MEDIUM)
AddArmorCategory(ARMORTYPE_HEAVY)
AddShieldCategory()

-- Jewelry
AddJewelryCategory()

-- Consumables
AddAllConsumablesCategory()
AddConsumableCategory(ITEMTYPE_FOOD)
AddRecipeCategory(PROVISIONER_SPECIAL_INGREDIENT_TYPE_SPICES)
AddConsumableCategory(ITEMTYPE_DRINK)
AddRecipeCategory(PROVISIONER_SPECIAL_INGREDIENT_TYPE_FLAVORING)
AddConsumableCategory(ITEMTYPE_POTION)
AddConsumableCategory(ITEMTYPE_POISON)
AddConsumableCategory(ITEMTYPE_RACIAL_STYLE_MOTIF)
AddRecipeCategory(PROVISIONER_SPECIAL_INGREDIENT_TYPE_FURNISHING)
AddConsumableCategory(ITEMTYPE_MASTER_WRIT)
AddConsumableCategory(ITEMTYPE_CONTAINER, ITEMTYPE_CONTAINER_CURRENCY)
AddConsumableCategory(ITEMTYPE_AVA_REPAIR)

-- Materials
AddAllMaterialsCategory()
AddTradeMaterialCategory(CRAFTING_TYPE_BLACKSMITHING)
AddTradeMaterialCategory(CRAFTING_TYPE_CLOTHIER)
AddTradeMaterialCategory(CRAFTING_TYPE_WOODWORKING)
AddTradeMaterialCategory(CRAFTING_TYPE_JEWELRYCRAFTING)
AddTradeMaterialCategory(CRAFTING_TYPE_ALCHEMY)
AddTradeMaterialCategory(CRAFTING_TYPE_ENCHANTING)
AddProvisioningIngredientCategory()
AddStyleMaterialCategory()
AddTraitMaterialCategory()
AddFurnishingMaterialCategory()

-- Glyphs
AddAllGlyphsCategory()
AddGlyphCategory(ITEMTYPE_GLYPH_WEAPON)
AddGlyphCategory(ITEMTYPE_GLYPH_ARMOR)
AddGlyphCategory(ITEMTYPE_GLYPH_JEWELRY)

-- Furnishings
AddAllFurnishingsCategory()
AddFurnishingCategory(SPECIALIZED_ITEMTYPE_FURNISHING_CRAFTING_STATION, SPECIALIZED_ITEMTYPE_FURNISHING_ATTUNABLE_STATION)
AddFurnishingCategory(SPECIALIZED_ITEMTYPE_FURNISHING_TARGET_DUMMY)
AddFurnishingCategory(SPECIALIZED_ITEMTYPE_FURNISHING_LIGHT)
AddFurnishingCategory(SPECIALIZED_ITEMTYPE_FURNISHING_SEATING)
AddFurnishingCategory(SPECIALIZED_ITEMTYPE_FURNISHING_ORNAMENTAL)

-- Companion Equipment
AddAllCompanionEquipmentCategory()
AddCompanionEquipmentCategory(ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS)
AddCompanionEquipmentCategory(ITEM_TYPE_DISPLAY_CATEGORY_ARMOR)
AddCompanionEquipmentCategory(ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY)

-- Misc
-- Misc does not have an "all" category
AddMiscCategory(ITEMTYPE_SOUL_GEM)
AddMiscCategory(ITEMTYPE_LURE)
AddMiscCategory(ITEMTYPE_TOOL)
AddMiscCategory(ITEMTYPE_SIEGE)
AddTrophyCategory()
AddGuildTabardCategory()
