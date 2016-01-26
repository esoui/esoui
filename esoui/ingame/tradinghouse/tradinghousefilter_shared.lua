ZO_RANGE_COMBO_INDEX_MIN_VALUE = 1
ZO_RANGE_COMBO_INDEX_MAX_VALUE = 2
ZO_RANGE_COMBO_INDEX_TEXT = 3

function ZO_TradingHouse_SortComboBoxEntries(entryData, sortType, sortOrder, anchorFirstEntry, anchorLastEntry)
    local firstEntry = entryData[1][ZO_RANGE_COMBO_INDEX_TEXT]
    local lastEntry = entryData[#entryData][ZO_RANGE_COMBO_INDEX_TEXT]

    local function DataSortHelper(item1, item2)
	    local name1 = item1[ZO_RANGE_COMBO_INDEX_TEXT]
	    local name2 = item2[ZO_RANGE_COMBO_INDEX_TEXT]

	    if anchorFirstEntry then
		    if name1 == firstEntry then
			    return true
		    elseif name2 == firstEntry then
			    return false
		    end
	    end

	    if anchorLastEntry then
		    if name1 == lastEntry then
			    return false
		    elseif name2 == lastEntry then
			    return true
		    end
	    end

	    return (name1 < name2)
    end

    -- Sort the entries, while ensuring that the anchored entries remain where they are.
    table.sort(entryData, function(item1, item2) return DataSortHelper(item1, item2) end)
end

----------------------
-- Armor Filter Data
----------------------

local ARMOR_EQUIP_TYPE_DATA =
{
    { 
        { EQUIP_TYPE_HEAD, EQUIP_TYPE_CHEST, EQUIP_TYPE_SHOULDERS, EQUIP_TYPE_WAIST, EQUIP_TYPE_LEGS, EQUIP_TYPE_FEET, EQUIP_TYPE_HAND }, 
        nil, 
        SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ALL_WORN_ARMOR_TYPES
    },
    { EQUIP_TYPE_CHEST, nil, GetString("SI_EQUIPTYPE", EQUIP_TYPE_CHEST) },
    { EQUIP_TYPE_FEET, nil, GetString("SI_EQUIPTYPE", EQUIP_TYPE_FEET) },
    { EQUIP_TYPE_HAND, nil, GetString("SI_EQUIPTYPE", EQUIP_TYPE_HAND) },
    { EQUIP_TYPE_HEAD, nil, GetString("SI_EQUIPTYPE", EQUIP_TYPE_HEAD) },
    { EQUIP_TYPE_LEGS, nil, GetString("SI_EQUIPTYPE", EQUIP_TYPE_LEGS) },
    { EQUIP_TYPE_SHOULDERS, nil, GetString("SI_EQUIPTYPE", EQUIP_TYPE_SHOULDERS) },
    { EQUIP_TYPE_WAIST, nil, GetString("SI_EQUIPTYPE", EQUIP_TYPE_WAIST) },
}

local ARMOR_ACCESSORY_DATA =
{
    { { EQUIP_TYPE_COSTUME, EQUIP_TYPE_NECK, EQUIP_TYPE_RING }, nil, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ALL_ACCESSORIES },
    { EQUIP_TYPE_COSTUME, nil, GetString("SI_EQUIPTYPE", EQUIP_TYPE_COSTUME) },
    { EQUIP_TYPE_NECK, nil, GetString("SI_EQUIPTYPE", EQUIP_TYPE_NECK) },
    { EQUIP_TYPE_RING, nil, GetString("SI_EQUIPTYPE", EQUIP_TYPE_RING) },
}

function ZO_TradingHouseFilter_GenerateArmorTypeData(SetGenericArmorSearch)
    local function SetupLightArmorSearch()
        SetGenericArmorSearch("normal", "armor", ITEMTYPE_GLYPH_ARMOR, ARMORTYPE_LIGHT)
    end

    local function SetupMediumArmorSearch()
        SetGenericArmorSearch("normal", "armor", ITEMTYPE_GLYPH_ARMOR, ARMORTYPE_MEDIUM)
    end

    local function SetupHeavyArmorSearch()
        SetGenericArmorSearch("normal", "armor", ITEMTYPE_GLYPH_ARMOR, ARMORTYPE_HEAVY)
    end

    local function SetupShieldSearch()
        SetGenericArmorSearch("shield", "armor", ITEMTYPE_GLYPH_ARMOR)
    end

    local function SetupAccessorySearch()
        SetGenericArmorSearch("accessory", "jewelry", ITEMTYPE_GLYPH_JEWELRY) -- costumes don't really have traits...come up with a way to make those a unique search?
    end

    return {
        { SetupLightArmorSearch, ARMOR_EQUIP_TYPE_DATA, SI_TRADING_HOUSE_BROWSE_ARMOR_TYPE_LIGHT },
        { SetupMediumArmorSearch, ARMOR_EQUIP_TYPE_DATA, SI_TRADING_HOUSE_BROWSE_ARMOR_TYPE_MEDIUM },
        { SetupHeavyArmorSearch, ARMOR_EQUIP_TYPE_DATA, SI_TRADING_HOUSE_BROWSE_ARMOR_TYPE_HEAVY },
        { SetupShieldSearch, nil, SI_TRADING_HOUSE_BROWSE_ARMOR_TYPE_SHIELD }, 
        { SetupAccessorySearch, ARMOR_ACCESSORY_DATA, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ACCESSORY },
    }
end

---------------------------
-- Consumables Filter Data
---------------------------

ZO_TRADING_HOUSE_FILTER_CONSUMABLES_TYPE_DATA =
{
    { { ITEMTYPE_FOOD, ITEMTYPE_DRINK, ITEMTYPE_POTION, }, nil, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ALL_CONSUMABLES },
    { ITEMTYPE_FOOD, nil, GetString("SI_ITEMTYPE", ITEMTYPE_FOOD) },
    { ITEMTYPE_DRINK, nil, GetString("SI_ITEMTYPE", ITEMTYPE_DRINK) },
    { ITEMTYPE_POTION, nil, GetString("SI_ITEMTYPE", ITEMTYPE_POTION) },
}

---------------------------
-- Crafting Filter Data
---------------------------

local BLACKSMITHING_SEARCH =
{
    { ITEMTYPE_RACIAL_STYLE_MOTIF, nil, GetString("SI_ITEMTYPE", ITEMTYPE_RACIAL_STYLE_MOTIF) },
    { ITEMTYPE_STYLE_MATERIAL, nil, GetString("SI_ITEMTYPE", ITEMTYPE_STYLE_MATERIAL) },
    { ITEMTYPE_ARMOR_TRAIT, "armor", GetString("SI_ITEMTYPE", ITEMTYPE_ARMOR_TRAIT) },
    { ITEMTYPE_WEAPON_TRAIT, "weapon", GetString("SI_ITEMTYPE", ITEMTYPE_WEAPON_TRAIT) },
    { {ITEMTYPE_BLACKSMITHING_RAW_MATERIAL, ITEMTYPE_RAW_MATERIAL,}, nil, GetString("SI_ITEMTYPE", ITEMTYPE_BLACKSMITHING_RAW_MATERIAL) },
    { ITEMTYPE_BLACKSMITHING_MATERIAL, nil, GetString("SI_ITEMTYPE", ITEMTYPE_BLACKSMITHING_MATERIAL) },
    { ITEMTYPE_BLACKSMITHING_BOOSTER, nil, GetString("SI_ITEMTYPE", ITEMTYPE_BLACKSMITHING_BOOSTER) },
}

local CLOTHING_SEARCH =
{
    { ITEMTYPE_RACIAL_STYLE_MOTIF, nil, GetString("SI_ITEMTYPE", ITEMTYPE_RACIAL_STYLE_MOTIF) },
    { ITEMTYPE_STYLE_MATERIAL, nil, GetString("SI_ITEMTYPE", ITEMTYPE_STYLE_MATERIAL) },
    { ITEMTYPE_ARMOR_TRAIT, "armor", GetString("SI_ITEMTYPE", ITEMTYPE_ARMOR_TRAIT) }, -- NOTE: No weapons in clothing...so no weapon trait materials
    { {ITEMTYPE_CLOTHIER_RAW_MATERIAL, ITEMTYPE_RAW_MATERIAL,}, nil, GetString("SI_ITEMTYPE", ITEMTYPE_CLOTHIER_RAW_MATERIAL) },
    { ITEMTYPE_CLOTHIER_MATERIAL, nil, GetString("SI_ITEMTYPE", ITEMTYPE_CLOTHIER_MATERIAL) },
    { ITEMTYPE_CLOTHIER_BOOSTER, nil, GetString("SI_ITEMTYPE", ITEMTYPE_CLOTHIER_BOOSTER) },
}

local WOODWORKING_SEARCH =
{
    { ITEMTYPE_RACIAL_STYLE_MOTIF, nil, GetString("SI_ITEMTYPE", ITEMTYPE_RACIAL_STYLE_MOTIF) },
    { ITEMTYPE_STYLE_MATERIAL, nil, GetString("SI_ITEMTYPE", ITEMTYPE_STYLE_MATERIAL) },
    { ITEMTYPE_ARMOR_TRAIT, "armor", GetString("SI_ITEMTYPE", ITEMTYPE_ARMOR_TRAIT) },
    { ITEMTYPE_WEAPON_TRAIT, "weapon", GetString("SI_ITEMTYPE", ITEMTYPE_WEAPON_TRAIT) },
    { {ITEMTYPE_WOODWORKING_RAW_MATERIAL, ITEMTYPE_RAW_MATERIAL,}, nil, GetString("SI_ITEMTYPE", ITEMTYPE_WOODWORKING_RAW_MATERIAL) },
    { ITEMTYPE_WOODWORKING_MATERIAL, nil, GetString("SI_ITEMTYPE", ITEMTYPE_WOODWORKING_MATERIAL) },
    { ITEMTYPE_WOODWORKING_BOOSTER, nil, GetString("SI_ITEMTYPE", ITEMTYPE_WOODWORKING_BOOSTER) },
}

local ENCHANTING_SEARCH =
{
    -- TODO: Needs some more back-end support to be able to look for aspect, essence, and potency runes
    { ITEMTYPE_ENCHANTING_RUNE_ASPECT, nil, GetString("SI_ITEMTYPE", ITEMTYPE_ENCHANTING_RUNE_ASPECT) },
    { ITEMTYPE_ENCHANTING_RUNE_ESSENCE, nil, GetString("SI_ITEMTYPE", ITEMTYPE_ENCHANTING_RUNE_ESSENCE) },
    { ITEMTYPE_ENCHANTING_RUNE_POTENCY, nil, GetString("SI_ITEMTYPE", ITEMTYPE_ENCHANTING_RUNE_POTENCY) },
}

local ALCHEMY_SEARCH =
{
    { ITEMTYPE_ALCHEMY_BASE, nil, GetString("SI_ITEMTYPE", ITEMTYPE_ALCHEMY_BASE) },
    { ITEMTYPE_REAGENT, nil, GetString("SI_ITEMTYPE", ITEMTYPE_REAGENT) },
}

local PROVISIONING_SEARCH =
{
    { ITEMTYPE_INGREDIENT, nil, GetString("SI_ITEMTYPE", ITEMTYPE_INGREDIENT) }, -- TODO: Needs back-end support for provisioning ingredient sub-types
    { ITEMTYPE_RECIPE, nil, GetString("SI_ITEMTYPE", ITEMTYPE_RECIPE) },
}

ZO_TRADING_HOUSE_FILTER_CRAFTING_SEARCHES =
{
    { BLACKSMITHING_SEARCH,  nil, GetCraftingSkillName(CRAFTING_TYPE_BLACKSMITHING) },
    { CLOTHING_SEARCH,       nil, GetCraftingSkillName(CRAFTING_TYPE_CLOTHIER) },
    { WOODWORKING_SEARCH,    nil, GetCraftingSkillName(CRAFTING_TYPE_WOODWORKING) },
    { ENCHANTING_SEARCH,     nil, GetCraftingSkillName(CRAFTING_TYPE_ENCHANTING) }, 
    { ALCHEMY_SEARCH,        nil, GetCraftingSkillName(CRAFTING_TYPE_ALCHEMY) },
    { PROVISIONING_SEARCH,   nil, GetCraftingSkillName(CRAFTING_TYPE_PROVISIONING) },
}

local CRAFTING_SKILL_NAME_INDEX = 3

local function InitializeCraftingFilterData()
    table.sort(ZO_TRADING_HOUSE_FILTER_CRAFTING_SEARCHES, function(entry1, entry2) return entry1[CRAFTING_SKILL_NAME_INDEX] < entry2[CRAFTING_SKILL_NAME_INDEX] end)
end

function ZO_TradingHouseFilter_Shared_GetCraftingSearches()
    return ZO_TRADING_HOUSE_FILTER_CRAFTING_SEARCHES
end

---------------------------
-- Enchantment Filter Data
---------------------------

local WEAPON_ENCHANTMENT_DATA = {}
local ARMOR_ENCHANTMENT_DATA = {}
local JEWELRY_ENCHANTMENT_DATA = {}
ZO_TRADING_HOUSE_FILTER_ENCHANTMENT_TYPE_DATA = {}

local ENCHANTMENT_INIT_DATA =
{
	{ ITEMTYPE_GLYPH_WEAPON, WEAPON_ENCHANTMENT_DATA },
	{ ITEMTYPE_GLYPH_ARMOR, ARMOR_ENCHANTMENT_DATA },
	{ ITEMTYPE_GLYPH_JEWELRY, JEWELRY_ENCHANTMENT_DATA },
}

local function PopulateEnchantmentFilterTableFromCategories(entryData, categories)
	local foundData = false

	if (categories ~= nil) then
		for _, v in pairs(categories) do
			table.insert(entryData, {v, nil, GetString("SI_ENCHANTMENTSEARCHCATEGORYTYPE", v)})
			foundData = true
		end
	end

	return foundData
end

local function InitializeEnchantmentFilterData()
    -- Populate the search categories dynamically.
    for _, v in pairs(ENCHANTMENT_INIT_DATA) do
	    local itemType = v[1]
	    local data = v[2]

	    -- Make sure the 'any' entry is at the beginning.
	    table.insert(data, { nil, nil, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ALL_ENCHANTMENT_TYPES })

	    ZO_TRADING_HOUSE_FILTER_ENCHANTMENT_TYPE_DATA[itemType] = nil
	    if (PopulateEnchantmentFilterTableFromCategories(data, { GetEnchantmentSearchCategories(itemType) })) then
		    -- Make sure the 'other' entry is at the end.
		    table.insert(data, { ENCHANTMENT_SEARCH_CATEGORY_OTHER, nil, GetString("SI_ENCHANTMENTSEARCHCATEGORYTYPE", ENCHANTMENT_SEARCH_CATEGORY_OTHER) })

		    ZO_TRADING_HOUSE_FILTER_ENCHANTMENT_TYPE_DATA[itemType] = data
	    end
    end

    local ANCHOR_FIRST_ENCHANTMENT_FILTER_ENTRY = true
    local ANCHOR_LAST_ENCHANTMENT_FILTER_ENTRY = true

    -- Sort the enchantment filter tables, ensuring that the first and last entries of each table remain anchored ('any' and 'other' filters).
    for _, v in pairs(ZO_TRADING_HOUSE_FILTER_ENCHANTMENT_TYPE_DATA) do
	    ZO_TradingHouse_SortComboBoxEntries(v, ZO_SORT_BY_NAME, ZO_SORT_ORDER_UP, ANCHOR_FIRST_ENCHANTMENT_FILTER_ENTRY, ANCHOR_LAST_ENCHANTMENT_FILTER_ENTRY)
    end
end

----------------------
-- Gem Filter Data
----------------------

ZO_TRADING_HOUSE_FILTER_GEM_TYPE_DATA =
{
    { ITEMTYPE_SOUL_GEM, nil, GetString("SI_ITEMTYPE", ITEMTYPE_SOUL_GEM) },
    { ITEMTYPE_GLYPH_ARMOR, nil, GetString("SI_ITEMTYPE", ITEMTYPE_GLYPH_ARMOR) },
    { ITEMTYPE_GLYPH_WEAPON, nil, GetString("SI_ITEMTYPE", ITEMTYPE_GLYPH_WEAPON) },
    { ITEMTYPE_GLYPH_JEWELRY, nil, GetString("SI_ITEMTYPE", ITEMTYPE_GLYPH_JEWELRY) },
}

local GEM_HAS_ENCHANTMENTS =
{
	[ITEMTYPE_SOUL_GEM] = false,
	[ITEMTYPE_GLYPH_ARMOR] = true,
	[ITEMTYPE_GLYPH_WEAPON] = true,
	[ITEMTYPE_GLYPH_JEWELRY] = true,
}

function ZO_TradingHouseFilter_Shared_GetGemHasEnchantments(enchantmentType)
    return GEM_HAS_ENCHANTMENTS[enchantmentType]
end

------------------------------
-- Miscellaneous Filter Data
------------------------------

ZO_TRADING_HOUSE_FILTER_MISC_TYPE_DATA =
{
    { ITEMTYPE_LURE, nil, GetString(SI_ITEM_SUB_TYPE_BAIT) },
    { ITEMTYPE_TOOL, nil, GetString("SI_ITEMTYPE", ITEMTYPE_TOOL) },
    { ITEMTYPE_SIEGE, nil, GetString("SI_ITEMTYPE", ITEMTYPE_SIEGE) },
    { ITEMTYPE_TROPHY, nil, GetString("SI_ITEMTYPE", ITEMTYPE_TROPHY) },
}
-----------------------
-- Traits Filter Data
-----------------------

-- Note: All entries except the first ('any') will be sorted on init (see ZO_TradingHouse_TraitFilters:Initialize()).
local ARMOR_TRAIT_DATA =
{
    { nil, nil, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ALL_TRAIT_TYPES }, -- NOTE: Searching for all traits simply involves not setting any specific trait filter
    { ITEM_TRAIT_TYPE_ARMOR_STURDY, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_ARMOR_STURDY) }, 
    { ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE)}, 
    { ITEM_TRAIT_TYPE_ARMOR_REINFORCED, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_ARMOR_REINFORCED)}, 
    { ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED)}, 
    { ITEM_TRAIT_TYPE_ARMOR_TRAINING, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_ARMOR_TRAINING)}, 
    { ITEM_TRAIT_TYPE_ARMOR_INFUSED, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_ARMOR_INFUSED)}, 
    { ITEM_TRAIT_TYPE_ARMOR_EXPLORATION, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_ARMOR_EXPLORATION)}, 
    { ITEM_TRAIT_TYPE_ARMOR_DIVINES, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_ARMOR_DIVINES)}, 
    { ITEM_TRAIT_TYPE_ARMOR_ORNATE, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_ARMOR_ORNATE)}, 
    { ITEM_TRAIT_TYPE_ARMOR_INTRICATE, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_ARMOR_INTRICATE)}, 
    { ITEM_TRAIT_TYPE_ARMOR_NIRNHONED, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_ARMOR_NIRNHONED)}, 
}

-- Note: All entries except the first ('any') will be sorted on init (see ZO_TradingHouse_TraitFilters:Initialize()).
local WEAPON_TRAIT_DATA =
{
    { nil, nil, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ALL_TRAIT_TYPES }, 
    { ITEM_TRAIT_TYPE_WEAPON_POWERED, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_WEAPON_POWERED) }, 
    { ITEM_TRAIT_TYPE_WEAPON_CHARGED, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_WEAPON_CHARGED)}, 
    { ITEM_TRAIT_TYPE_WEAPON_PRECISE, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_WEAPON_PRECISE)}, 
    { ITEM_TRAIT_TYPE_WEAPON_INFUSED, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_WEAPON_INFUSED)}, 
    { ITEM_TRAIT_TYPE_WEAPON_DEFENDING, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_WEAPON_DEFENDING)}, 
    { ITEM_TRAIT_TYPE_WEAPON_TRAINING, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_WEAPON_TRAINING)}, 
    { ITEM_TRAIT_TYPE_WEAPON_SHARPENED, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_WEAPON_SHARPENED)}, 
    { ITEM_TRAIT_TYPE_WEAPON_WEIGHTED, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_WEAPON_WEIGHTED)}, 
    { ITEM_TRAIT_TYPE_WEAPON_ORNATE, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_WEAPON_ORNATE)}, 
    { ITEM_TRAIT_TYPE_WEAPON_INTRICATE, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_WEAPON_INTRICATE)},
    { ITEM_TRAIT_TYPE_WEAPON_NIRNHONED, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_WEAPON_NIRNHONED)},
}

-- Note: All entries except the first ('any') will be sorted on init (see ZO_TradingHouse_TraitFilters:Initialize()).
local JEWELRY_TRAIT_DATA =
{
    { nil, nil, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ALL_TRAIT_TYPES }, 
    { ITEM_TRAIT_TYPE_JEWELRY_HEALTHY, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_JEWELRY_HEALTHY) },
    { ITEM_TRAIT_TYPE_JEWELRY_ARCANE, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_JEWELRY_ARCANE) },
    { ITEM_TRAIT_TYPE_JEWELRY_ROBUST, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_JEWELRY_ROBUST) },
    { ITEM_TRAIT_TYPE_JEWELRY_ORNATE, nil, GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_JEWELRY_ORNATE) },
}

ZO_TRADING_HOUSE_FILTER_TRAIT_TYPE_DATA =
{
    ["armor"] = ARMOR_TRAIT_DATA,
    ["weapon"] = WEAPON_TRAIT_DATA,
    ["jewelry"] = JEWELRY_TRAIT_DATA,
}

local function InitializeTraitFilterData()
    local ANCHOR_FIRST_TRAIT_FILTER_ENTRY = true
    local DONT_ANCHOR_LAST_TRAIT_FILTER_ENTRY = false

    -- Sort the trait filter tables, ensuring that the first entry of each table remains anchored ('any' filter).
    for _, v in pairs(ZO_TRADING_HOUSE_FILTER_TRAIT_TYPE_DATA) do
	    ZO_TradingHouse_SortComboBoxEntries(v, ZO_SORT_BY_NAME, ZO_SORT_ORDER_UP, ANCHOR_FIRST_TRAIT_FILTER_ENTRY, DONT_ANCHOR_LAST_TRAIT_FILTER_ENTRY)
    end
end

----------------------
-- Weapon Filter Data
----------------------

local ONE_HANDED_WEAPON_DATA =
{
    { { WEAPONTYPE_AXE, WEAPONTYPE_HAMMER, WEAPONTYPE_SWORD, WEAPONTYPE_DAGGER }, nil, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ALL_ONE_HANDED_WEAPONS },
    { WEAPONTYPE_AXE, nil, GetString("SI_WEAPONTYPE", WEAPONTYPE_AXE) },
    { WEAPONTYPE_HAMMER, nil, GetString("SI_WEAPONTYPE", WEAPONTYPE_HAMMER) },
    { WEAPONTYPE_SWORD, nil, GetString("SI_WEAPONTYPE", WEAPONTYPE_SWORD) },
    { WEAPONTYPE_DAGGER, nil, GetString("SI_WEAPONTYPE", WEAPONTYPE_DAGGER) },
}

local TWO_HANDED_WEAPON_DATA =
{
    { 
        { 
            WEAPONTYPE_TWO_HANDED_AXE, WEAPONTYPE_TWO_HANDED_SWORD, WEAPONTYPE_TWO_HANDED_HAMMER, WEAPONTYPE_BOW, WEAPONTYPE_HEALING_STAFF, 
            WEAPONTYPE_FIRE_STAFF, WEAPONTYPE_FROST_STAFF, WEAPONTYPE_LIGHTNING_STAFF,
        }, 
        nil,
        SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ALL_TWO_HANDED_WEAPONS
    },
    { WEAPONTYPE_TWO_HANDED_AXE, nil, GetString("SI_WEAPONTYPE", WEAPONTYPE_TWO_HANDED_AXE) },
    { WEAPONTYPE_TWO_HANDED_SWORD, nil, GetString("SI_WEAPONTYPE", WEAPONTYPE_TWO_HANDED_SWORD) },
    { WEAPONTYPE_TWO_HANDED_HAMMER, nil, GetString("SI_WEAPONTYPE", WEAPONTYPE_TWO_HANDED_HAMMER) },
    { WEAPONTYPE_BOW, nil, GetString("SI_WEAPONTYPE", WEAPONTYPE_BOW) },
    { WEAPONTYPE_HEALING_STAFF, nil, GetString("SI_WEAPONTYPE", WEAPONTYPE_HEALING_STAFF) },
    { WEAPONTYPE_FIRE_STAFF, nil, GetString("SI_WEAPONTYPE", WEAPONTYPE_FIRE_STAFF) },
    { WEAPONTYPE_FROST_STAFF, nil, GetString("SI_WEAPONTYPE", WEAPONTYPE_FROST_STAFF) },
    { WEAPONTYPE_LIGHTNING_STAFF, nil, GetString("SI_WEAPONTYPE", WEAPONTYPE_LIGHTNING_STAFF) },
}

ZO_TRADING_HOUSE_FILTER_WEAPON_TYPE_DATA =
{
    { EQUIP_TYPE_ONE_HAND, ONE_HANDED_WEAPON_DATA, GetString("SI_EQUIPTYPE", EQUIP_TYPE_ONE_HAND) },
    { EQUIP_TYPE_TWO_HAND, TWO_HANDED_WEAPON_DATA, GetString("SI_EQUIPTYPE", EQUIP_TYPE_TWO_HAND) },
}

function ZO_TradingHouseFilter_Shared_InitializeData()
    InitializeCraftingFilterData()
    InitializeEnchantmentFilterData()
    InitializeTraitFilterData()
end