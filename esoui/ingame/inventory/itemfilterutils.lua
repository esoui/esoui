-- Setup Display Data (Icons)
local ITEM_TYPE_DISPLAY_CATEGORY_ICONS =
{
    [ITEM_TYPE_DISPLAY_CATEGORY_ALL] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_all_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_all_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_all_over.dds",
        disabled = "EsoUI/Art/Inventory/inventory_tabIcon_all_disabled.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_weapons_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_weapons_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_weapons_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_ARMOR] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_armor_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_armor_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_armor_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY] =
    {
        up = "EsoUI/Art/Crafting/jewelry_tabIcon_icon_up.dds",
        down = "EsoUI/Art/Crafting/jewelry_tabIcon_down.dds",
        over = "EsoUI/Art/Crafting/jewelry_tabIcon_icon_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_consumables_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_consumables_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_consumables_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_crafting_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_crafting_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_crafting_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING] =
    {
        up = "EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_up.dds",
        down = "EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_down.dds",
        over = "EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_COMPANION] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_companion_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_companion_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_companion_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_misc_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_misc_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_misc_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_QUEST] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_quest_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_quest_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_quest_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_JUNK] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_junk_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_junk_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_junk_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_BLACKSMITHING] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_blacksmithing_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_blacksmithing_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_blacksmithing_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_CLOTHING] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_clothing_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_clothing_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_clothing_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_WOODWORKING] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_woodworking_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_woodworking_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_woodworking_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_jewelrycrafting_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_jewelrycrafting_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_jewelrycrafting_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_ALCHEMY] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_alchemy_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_alchemy_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_alchemy_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_ENCHANTING] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_enchanting_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_enchanting_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_enchanting_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_PROVISIONING] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_provisioning_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_provisioning_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_provisioning_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MATERIAL] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_styleMaterial_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_styleMaterial_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_styleMaterial_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_TRAIT_ITEM] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_itemTrait_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_itemTrait_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_itemTrait_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_FOOD] =
    {
        up = "EsoUI/Art/Crafting/provisioner_indexIcon_meat_up.dds",
        down = "EsoUI/Art/Crafting/provisioner_indexIcon_meat_down.dds",
        over = "EsoUI/Art/Crafting/provisioner_indexIcon_meat_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_DRINK] =
    {
        up = "EsoUI/Art/Crafting/provisioner_indexIcon_beer_up.dds",
        down = "EsoUI/Art/Crafting/provisioner_indexIcon_beer_down.dds",
        over = "EsoUI/Art/Crafting/provisioner_indexIcon_beer_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_RECIPE] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_recipe_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_recipe_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_recipe_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_POTION] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Potions_Potionsolvent_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Potions_Potionsolvent_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Potions_Potionsolvent_Over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_POISON] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Potions_Poisonsolvent_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Potions_Poisonsolvent_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Potions_Poisonsolvent_Over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MOTIF] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Racial_Style_Motif_Book_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Racial_Style_Motif_Book_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Racial_Style_Motif_Book_Over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_MASTER_WRIT] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Master_Writ_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Master_Writ_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Master_Writ_Over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_CONTAINER] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_container_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_container_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_container_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_REPAIR_ITEM] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_repair_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_repair_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_repair_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_CROWN_ITEM] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_crown_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_crown_Down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_crown_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_APPEARANCE] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_appearance_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_appearance_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_appearance_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_GLYPH] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Glyphs_Trio_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Glyphs_Trio_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Glyphs_Trio_Over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_SOUL_GEM] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_soulgem_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_soulgem_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_soulgem_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_SIEGE] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_siege_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_siege_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_siege_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_TOOL] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_tool_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_tool_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_tool_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_TROPHY] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_trophy_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_trophy_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_trophy_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_LURE] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_bait_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_bait_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_bait_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_TRASH] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_trash_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_trash_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_trash_over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_FOOD_INGREDIENT] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Provisioning_Food_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Provisioning_Food_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Provisioning_Food_Over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_DRINK_INGREDIENT] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Provisioning_Drink_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Provisioning_Drink_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Provisioning_Drink_Over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_RARE_INGREDIENT] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Provisioning_Rare_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Provisioning_Rare_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Provisioning_Rare_Over.dds",
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING_MATERIAL] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_furnishing_material_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_furnishing_material_Down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_furnishing_material_Over.dds",
    },
}

local EQUIPMENT_FILTER_TYPE_ICONS =
{
    [EQUIPMENT_FILTER_TYPE_NONE] = ITEM_TYPE_DISPLAY_CATEGORY_ICONS[ITEM_TYPE_DISPLAY_CATEGORY_ALL],
    [EQUIPMENT_FILTER_TYPE_LIGHT] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_armorLight_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_armorLight_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_armorLight_over.dds",
    },
    [EQUIPMENT_FILTER_TYPE_MEDIUM] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_armorMedium_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_armorMedium_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_armorMedium_over.dds",
    },
    [EQUIPMENT_FILTER_TYPE_HEAVY] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_armorHeavy_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_armorHeavy_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_armorHeavy_over.dds",
    },
    [EQUIPMENT_FILTER_TYPE_ONE_HANDED] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_1handed_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_1handed_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_1handed_over.dds",
    },
    [EQUIPMENT_FILTER_TYPE_TWO_HANDED] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_2handed_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_2handed_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_2handed_over.dds",
    },
    [EQUIPMENT_FILTER_TYPE_BOW] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_bow_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_bow_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_bow_over.dds",
    },
    [EQUIPMENT_FILTER_TYPE_DESTRO_STAFF] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_damageStaff_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_damageStaff_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_damageStaff_over.dds",
    },
    [EQUIPMENT_FILTER_TYPE_RESTO_STAFF] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_healStaff_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_healStaff_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_healStaff_over.dds",
    },
    [EQUIPMENT_FILTER_TYPE_SHIELD] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_shield_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_shield_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_shield_over.dds",
    },
    [EQUIPMENT_FILTER_TYPE_NECK] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Accessories_Necklace_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Accessories_Necklace_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Accessories_Necklace_Over.dds",
    },
    [EQUIPMENT_FILTER_TYPE_RING] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Accessories_Ring_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Accessories_Ring_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Accessories_Ring_Over.dds",
    },
}

local WEAPONTYPE_ICONS =
{
    [WEAPONTYPE_AXE] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_1h_Axe_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_1h_Axe_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_1h_Axe_Over.dds",
    },
    [WEAPONTYPE_HAMMER] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_1h_Mace_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_1h_Mace_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_1h_Mace_Over.dds",
    },
    [WEAPONTYPE_SWORD] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_1h_Sword_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_1h_Sword_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_1h_Sword_Over.dds",
    },
    [WEAPONTYPE_DAGGER] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_1h_Dagger_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_1h_Dagger_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_1h_Dagger_Over.dds",
    },
    [WEAPONTYPE_TWO_HANDED_AXE] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_2h_Axe_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_2h_Axe_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_2h_Axe_Over.dds",
    },
    [WEAPONTYPE_TWO_HANDED_HAMMER] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_2h_Mace_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_2h_Mace_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_2h_Mace_Over.dds",
    },
    [WEAPONTYPE_TWO_HANDED_SWORD] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_2h_Sword_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_2h_Sword_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_2h_Sword_Over.dds",
    },
    [WEAPONTYPE_FIRE_STAFF] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_Staff_Flame_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_Staff_Flame_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_Staff_Flame_Over.dds",
    },
    [WEAPONTYPE_FROST_STAFF] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_Staff_Frost_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_Staff_Frost_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_Staff_Frost_Over.dds",
    },
    [WEAPONTYPE_LIGHTNING_STAFF] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_Staff_Lightning_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_Staff_Lightning_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Weapons_Staff_Lightning_Over.dds",
    },
    [WEAPONTYPE_SHIELD] = EQUIPMENT_FILTER_TYPE_ICONS[EQUIPMENT_FILTER_TYPE_SHIELD],
}

local EQUIPTYPE_ICONS =
{
    [EQUIP_TYPE_CHEST] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Chest_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Chest_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Chest_Over.dds",
    },
    [EQUIP_TYPE_FEET] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Feet_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Feet_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Feet_Over.dds",
    },
    [EQUIP_TYPE_HAND] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Hands_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Hands_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Hands_Over.dds",
    },
    [EQUIP_TYPE_HEAD] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Head_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Head_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Head_Over.dds",
    },
    [EQUIP_TYPE_LEGS] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Legs_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Legs_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Legs_Over.dds",
    },
    [EQUIP_TYPE_SHOULDERS] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Shoulders_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Shoulders_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Shoulders_Over.dds",
    },
    [EQUIP_TYPE_WAIST] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Waist_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Waist_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Waist_Over.dds",
    },
    [EQUIP_TYPE_NECK] = EQUIPMENT_FILTER_TYPE_ICONS[EQUIPMENT_FILTER_TYPE_NECK],
    [EQUIP_TYPE_RING] = EQUIPMENT_FILTER_TYPE_ICONS[EQUIPMENT_FILTER_TYPE_RING],
}

local ITEMTYPE_ICONS =
{
    [ITEMTYPE_NONE] = ITEM_TYPE_DISPLAY_CATEGORY_ICONS[ITEM_TYPE_DISPLAY_CATEGORY_ALL],
    [ITEMTYPE_FURNISHING_MATERIAL] = ITEM_TYPE_DISPLAY_CATEGORY_ICONS[ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING_MATERIAL],
    [ITEMTYPE_BLACKSMITHING_RAW_MATERIAL] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Blacksmithing_Rawmats_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Blacksmithing_Rawmats_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Blacksmithing_Rawmats_Over.dds",
    },
    [ITEMTYPE_BLACKSMITHING_MATERIAL] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Blacksmithing_Mats_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Blacksmithing_Mats_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Blacksmithing_Mats_Over.dds",
    },
    [ITEMTYPE_BLACKSMITHING_BOOSTER] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Blacksmithing_Temper_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Blacksmithing_Temper_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Blacksmithing_Temper_Over.dds",
    },
    [ITEMTYPE_CLOTHIER_RAW_MATERIAL] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Tailoring_Rawmats_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Tailoring_Rawmats_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Tailoring_Rawmats_Over.dds",
    },
    [ITEMTYPE_CLOTHIER_MATERIAL] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Tailoring_Mats_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Tailoring_Mats_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Tailoring_Mats_Over.dds",
    },
    [ITEMTYPE_CLOTHIER_BOOSTER] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Tailoring_Tannin_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Tailoring_Tannin_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Tailoring_Tannin_Over.dds",
    },
    [ITEMTYPE_WOODWORKING_RAW_MATERIAL] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Woodworking_Rawmats_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Woodworking_Rawmats_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Woodworking_Rawmats_Over.dds",
    },
    [ITEMTYPE_WOODWORKING_MATERIAL] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Woodworking_Mats_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Woodworking_Mats_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Woodworking_Mats_Over.dds",
    },
    [ITEMTYPE_WOODWORKING_BOOSTER] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Woodworking_Resin_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Woodworking_Resin_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Woodworking_Resin_Over.dds",
    },
    [ITEMTYPE_JEWELRYCRAFTING_RAW_MATERIAL] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Jewelrymaking_Rawmats_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Jewelrymaking_Rawmats_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Jewelrymaking_Rawmats_Over.dds",
    },
    [ITEMTYPE_JEWELRYCRAFTING_MATERIAL] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Jewelrymaking_Mats_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Jewelrymaking_Mats_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Jewelrymaking_Mats_Over.dds",
    },
    [ITEMTYPE_JEWELRYCRAFTING_RAW_BOOSTER] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Jewelrymaking_Rawplating_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Jewelrymaking_Rawplating_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Jewelrymaking_Rawplating_Over.dds",
    },
    [ITEMTYPE_JEWELRYCRAFTING_BOOSTER] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Jewelrymaking_Plating_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Jewelrymaking_Plating_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Jewelrymaking_Plating_Over.dds",
    },
    [ITEMTYPE_ENCHANTING_RUNE_POTENCY] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Enchanting_Potency_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Enchanting_Potency_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Enchanting_Potency_Over.dds",
    },
    [ITEMTYPE_ENCHANTING_RUNE_ASPECT] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Enchanting_Aspect_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Enchanting_Aspect_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Enchanting_Aspect_Over.dds",
    },
    [ITEMTYPE_ENCHANTING_RUNE_ESSENCE] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Enchanting_Essence_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Enchanting_Essence_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Enchanting_Essence_Over.dds",
    },
    [ITEMTYPE_POTION_BASE] = ITEM_TYPE_DISPLAY_CATEGORY_ICONS[ITEM_TYPE_DISPLAY_CATEGORY_POTION],
    [ITEMTYPE_POISON_BASE] = ITEM_TYPE_DISPLAY_CATEGORY_ICONS[ITEM_TYPE_DISPLAY_CATEGORY_POISON],
    [ITEMTYPE_REAGENT] =
    {
        up = "EsoUI/Art/Crafting/alchemy_tabIcon_reagent_up.dds",
        down = "EsoUI/Art/Crafting/alchemy_tabIcon_reagent_down.dds",
        over = "EsoUI/Art/Crafting/alchemy_tabIcon_reagent_over.dds",
    },
    [ITEMTYPE_RAW_MATERIAL] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Style_RawMats_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Style_RawMats_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Style_RawMats_Over.dds",
    },
    [ITEMTYPE_STYLE_MATERIAL] = ITEM_TYPE_DISPLAY_CATEGORY_ICONS[ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MATERIAL],
    [ITEMTYPE_WEAPON_TRAIT] = ITEM_TYPE_DISPLAY_CATEGORY_ICONS[ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS],
    [ITEMTYPE_ARMOR_TRAIT] = ITEM_TYPE_DISPLAY_CATEGORY_ICONS[ITEM_TYPE_DISPLAY_CATEGORY_ARMOR],
    [ITEMTYPE_JEWELRY_RAW_TRAIT] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Style_RawMats_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Style_RawMats_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Style_RawMats_Over.dds",
    },
    [ITEMTYPE_JEWELRY_TRAIT] = ITEM_TYPE_DISPLAY_CATEGORY_ICONS[ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY],
}

local SPECIALIZED_ITEM_TYPE_ICONS =
{
    [SPECIALIZED_ITEMTYPE_NONE] = ITEM_TYPE_DISPLAY_CATEGORY_ICONS[ITEM_TYPE_DISPLAY_CATEGORY_ALL],
    [SPECIALIZED_ITEMTYPE_INGREDIENT_RARE] = ITEM_TYPE_DISPLAY_CATEGORY_ICONS[ITEM_TYPE_DISPLAY_CATEGORY_RARE_INGREDIENT],
    [SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_FOOD] =
    {
        up = "EsoUI/Art/Crafting/provisioner_indexIcon_meat_up.dds",
        down = "EsoUI/Art/Crafting/provisioner_indexIcon_meat_down.dds",
        over = "EsoUI/Art/Crafting/provisioner_indexIcon_meat_over.dds",
    },
    [SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_DRINK] =
    {
        up = "EsoUI/Art/Crafting/provisioner_indexIcon_beer_up.dds",
        down = "EsoUI/Art/Crafting/provisioner_indexIcon_beer_down.dds",
        over = "EsoUI/Art/Crafting/provisioner_indexIcon_beer_over.dds",
    },
    [SPECIALIZED_ITEMTYPE_RECIPE_BLACKSMITHING_DIAGRAM_FURNISHING] =
    {
        up = "EsoUI/Art/Crafting/diagrams_tabIcon_up.dds",
        down = "EsoUI/Art/Crafting/diagrams_tabIcon_down.dds",
        over = "EsoUI/Art/Crafting/diagrams_tabIcon_over.dds",
    },
    [SPECIALIZED_ITEMTYPE_RECIPE_CLOTHIER_PATTERN_FURNISHING] =
    {
        up = "EsoUI/Art/Crafting/patterns_tabIcon_up.dds",
        down = "EsoUI/Art/Crafting/patterns_tabIcon_down.dds",
        over = "EsoUI/Art/Crafting/patterns_tabIcon_over.dds",
    },
    [SPECIALIZED_ITEMTYPE_RECIPE_ENCHANTING_SCHEMATIC_FURNISHING] =
    {
        up = "EsoUI/Art/Crafting/schematics_tabIcon_up.dds",
        down = "EsoUI/Art/Crafting/schematics_tabIcon_down.dds",
        over = "EsoUI/Art/Crafting/schematics_tabIcon_over.dds",
    },
    [SPECIALIZED_ITEMTYPE_RECIPE_ALCHEMY_FORMULA_FURNISHING] =
    {
        up = "EsoUI/Art/Crafting/formulae_tabIcon_up.dds",
        down = "EsoUI/Art/Crafting/formulae_tabIcon_down.dds",
        over = "EsoUI/Art/Crafting/formulae_tabIcon_over.dds",
    },
    [SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_DESIGN_FURNISHING] =
    {
        up = "EsoUI/Art/Crafting/designs_tabIcon_up.dds",
        down = "EsoUI/Art/Crafting/designs_tabIcon_down.dds",
        over = "EsoUI/Art/Crafting/designs_tabIcon_over.dds",
    },
    [SPECIALIZED_ITEMTYPE_RECIPE_WOODWORKING_BLUEPRINT_FURNISHING] =
    {
        up = "EsoUI/Art/Crafting/blueprints_tabIcon_up.dds",
        down = "EsoUI/Art/Crafting/blueprints_tabIcon_down.dds",
        over = "EsoUI/Art/Crafting/blueprints_tabIcon_over.dds",
    },
    [SPECIALIZED_ITEMTYPE_RECIPE_JEWELRYCRAFTING_SKETCH_FURNISHING] =
    {
        up = "EsoUI/Art/Crafting/sketches_tabIcon_up.dds",
        down = "EsoUI/Art/Crafting/sketches_tabIcon_down.dds",
        over = "EsoUI/Art/Crafting/sketches_tabIcon_over.dds",
    },
    [SPECIALIZED_ITEMTYPE_RACIAL_STYLE_MOTIF_CHAPTER] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Racial_Style_Motif_Chapter_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Racial_Style_Motif_Chapter_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Racial_Style_Motif_Chapter_Over.dds",
    },
    [SPECIALIZED_ITEMTYPE_RACIAL_STYLE_MOTIF_BOOK] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Racial_Style_Motif_Book_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Racial_Style_Motif_Book_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Racial_Style_Motif_Book_Over.dds",
    },
    [SPECIALIZED_ITEMTYPE_MASTER_WRIT] = ITEM_TYPE_DISPLAY_CATEGORY_ICONS[ITEM_TYPE_DISPLAY_CATEGORY_MASTER_WRIT],
    [SPECIALIZED_ITEMTYPE_HOLIDAY_WRIT] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Holiday_Writ_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Holiday_Writ_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Holiday_Writ_Over.dds",
    },
    [SPECIALIZED_ITEMTYPE_FURNISHING_ORNAMENTAL] = ITEM_TYPE_DISPLAY_CATEGORY_ICONS[ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS],
    [SPECIALIZED_ITEMTYPE_FURNISHING_LIGHT] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_furnishing_lighting_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_furnishing_lighting_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_furnishing_lighting_over.dds",
    },
    [SPECIALIZED_ITEMTYPE_FURNISHING_SEATING] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_furnishing_seating_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_furnishing_seating_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_furnishing_seating_over.dds",
    },
    [SPECIALIZED_ITEMTYPE_FURNISHING_CRAFTING_STATION] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_furnishing_craftStation_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_furnishing_craftStation_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_furnishing_craftStation_over.dds",
    },
    [SPECIALIZED_ITEMTYPE_FURNISHING_TARGET_DUMMY] =
    {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_furnishing_targetDummy_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_furnishing_targetDummy_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_furnishing_targetDummy_over.dds",
    },
    [SPECIALIZED_ITEMTYPE_TROPHY_TREASURE_MAP] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Trophy_Treasure_Map_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Trophy_Treasure_Map_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Trophy_Treasure_Map_Over.dds",
    },
    [SPECIALIZED_ITEMTYPE_TROPHY_RECIPE_FRAGMENT] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Trophy_Recipe_Fragment_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Trophy_Recipe_Fragment_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Trophy_Recipe_Fragment_Over.dds",
    },
    [SPECIALIZED_ITEMTYPE_TROPHY_SCROLL] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Trophy_Scroll_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Trophy_Scroll_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Trophy_Scroll_Over.dds",
    },
    [SPECIALIZED_ITEMTYPE_TROPHY_RUNEBOX_FRAGMENT] =
    {
        up = "EsoUI/Art/TradingHouse/Tradinghouse_Trophy_Runebox_Fragment_Up.dds",
        down = "EsoUI/Art/TradingHouse/Tradinghouse_Trophy_Runebox_Fragment_Down.dds",
        over = "EsoUI/Art/TradingHouse/Tradinghouse_Trophy_Runebox_Fragment_Over.dds",
    },
}

-- Setup Types Tables
local ITEM_TYPE_DISPLAY_CATEGORY_ITEMTYPES =
{
    [ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS] =
    {
        ITEMTYPE_WEAPON,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_ARMOR] =
    {
        ITEMTYPE_ARMOR,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_COMPANION] =
    {
        ITEM_TYPE_DISPLAY_CATEGORY_ALL,
        ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS,
        ITEM_TYPE_DISPLAY_CATEGORY_ARMOR,
        ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE] =
    {
        ITEMTYPE_FOOD,
        ITEMTYPE_DRINK,
        ITEMTYPE_RECIPE,
        ITEMTYPE_POTION,
        ITEMTYPE_POISON,
        ITEMTYPE_RACIAL_STYLE_MOTIF,
        ITEMTYPE_MASTER_WRIT,
        ITEMTYPE_CONTAINER,
        ITEMTYPE_TOOL,
        ITEMTYPE_AVA_REPAIR,
        ITEMTYPE_FISH,
        ITEMTYPE_CROWN_ITEM,
        ITEMTYPE_DYE_STAMP,
        ITEMTYPE_MASTER_WRIT,
        ITEMTYPE_RECALL_STONE,
        ITEMTYPE_CONTAINER_CURRENCY,
        ITEMTYPE_GROUP_REPAIR,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING] =
    {
        ITEM_TYPE_DISPLAY_CATEGORY_BLACKSMITHING,
        ITEM_TYPE_DISPLAY_CATEGORY_CLOTHING,
        ITEM_TYPE_DISPLAY_CATEGORY_WOODWORKING,
        ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING,
        ITEM_TYPE_DISPLAY_CATEGORY_ALCHEMY,
        ITEM_TYPE_DISPLAY_CATEGORY_ENCHANTING,
        ITEM_TYPE_DISPLAY_CATEGORY_PROVISIONING,
        ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MATERIAL,
        ITEM_TYPE_DISPLAY_CATEGORY_TRAIT_ITEM,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_BLACKSMITHING] =
    {
        ITEMTYPE_BLACKSMITHING_RAW_MATERIAL,
        ITEMTYPE_BLACKSMITHING_MATERIAL,
        ITEMTYPE_BLACKSMITHING_BOOSTER,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_CLOTHING] =
    {
        ITEMTYPE_CLOTHIER_RAW_MATERIAL,
        ITEMTYPE_CLOTHIER_MATERIAL,
        ITEMTYPE_CLOTHIER_BOOSTER,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_WOODWORKING] =
    {
        ITEMTYPE_WOODWORKING_RAW_MATERIAL,
        ITEMTYPE_WOODWORKING_MATERIAL,
        ITEMTYPE_WOODWORKING_BOOSTER,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING] =
    {
        ITEMTYPE_JEWELRYCRAFTING_RAW_MATERIAL,
        ITEMTYPE_JEWELRYCRAFTING_MATERIAL,
        ITEMTYPE_JEWELRYCRAFTING_RAW_BOOSTER,
        ITEMTYPE_JEWELRYCRAFTING_BOOSTER,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_ALCHEMY] =
    {
        ITEMTYPE_REAGENT,
        ITEMTYPE_POTION_BASE,
        ITEMTYPE_POISON_BASE,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_ENCHANTING] =
    {
        ITEMTYPE_ENCHANTING_RUNE_ASPECT,
        ITEMTYPE_ENCHANTING_RUNE_POTENCY,
        ITEMTYPE_ENCHANTING_RUNE_ESSENCE,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_PROVISIONING] =
    {
        ITEMTYPE_INGREDIENT,
        ITEMTYPE_SPICE,
        ITEMTYPE_FLAVORING,
        ITEMTYPE_LURE,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MATERIAL] =
    {
        ITEMTYPE_STYLE_MATERIAL,
        ITEMTYPE_RAW_MATERIAL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_TRAIT_ITEM] =
    {
        ITEMTYPE_ARMOR_TRAIT,
        ITEMTYPE_WEAPON_TRAIT,
        ITEMTYPE_JEWELRY_RAW_TRAIT,
        ITEMTYPE_JEWELRY_TRAIT,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_FOOD] =
    {
        ITEMTYPE_FOOD,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_DRINK] =
    {
        ITEMTYPE_DRINK,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_RECIPE] =
    {
        ITEMTYPE_RECIPE,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_POTION] =
    {
        ITEMTYPE_POTION,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_POISON] =
    {
        ITEMTYPE_POISON,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MOTIF] =
    {
        ITEMTYPE_RACIAL_STYLE_MOTIF,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_MASTER_WRIT] =
    {
        ITEMTYPE_MASTER_WRIT,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_CONTAINER] =
    {
        ITEMTYPE_CONTAINER,
        ITEMTYPE_CONTAINER_CURRENCY,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_REPAIR_ITEM] =
    {
        ITEMTYPE_TOOL,
        ITEMTYPE_AVA_REPAIR,
        ITEMTYPE_CROWN_REPAIR,
        ITEMTYPE_GROUP_REPAIR,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_CROWN_ITEM] =
    {
        ITEMTYPE_CROWN_REPAIR,
        ITEMTYPE_CROWN_ITEM,
        ITEMTYPE_DYE_STAMP,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS] =
    {
        ITEMTYPE_FISH,
        ITEMTYPE_RECALL_STONE,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_APPEARANCE] =
    {
        ITEMTYPE_COSTUME,
        ITEMTYPE_DISGUISE,
        ITEMTYPE_TABARD
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_GLYPH] =
    {
        ITEMTYPE_GLYPH_WEAPON,
        ITEMTYPE_GLYPH_ARMOR,
        ITEMTYPE_GLYPH_JEWELRY,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_SOUL_GEM] =
    {
        ITEMTYPE_SOUL_GEM,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_SIEGE] =
    {
        ITEMTYPE_SIEGE,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_TOOL] =
    {
        ITEMTYPE_LOCKPICK,
        ITEMTYPE_TOOL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_TROPHY] =
    {
        ITEMTYPE_TROPHY,
        ITEMTYPE_COLLECTIBLE,
        ITEMTYPE_TREASURE,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_LURE] =
    {
        ITEMTYPE_LURE,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_TRASH] =
    {
        ITEMTYPE_TRASH,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING_MATERIAL] =
    {
        ITEMTYPE_FURNISHING_MATERIAL,
    },
}

local ITEM_TYPE_DISPLAY_CATEGORY_SPECIALIZED_ITEM_TYPES =
{
    [ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING] =
    {
        SPECIALIZED_ITEMTYPE_FURNISHING_ORNAMENTAL,
        SPECIALIZED_ITEMTYPE_FURNISHING_LIGHT,
        SPECIALIZED_ITEMTYPE_FURNISHING_SEATING,
        SPECIALIZED_ITEMTYPE_FURNISHING_CRAFTING_STATION,
        SPECIALIZED_ITEMTYPE_FURNISHING_TARGET_DUMMY,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_FOOD_INGREDIENT] =
    {
        SPECIALIZED_ITEMTYPE_INGREDIENT_MEAT,
        SPECIALIZED_ITEMTYPE_INGREDIENT_VEGETABLE,
        SPECIALIZED_ITEMTYPE_INGREDIENT_FRUIT,
        SPECIALIZED_ITEMTYPE_INGREDIENT_FOOD_ADDITIVE,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_DRINK_INGREDIENT] =
    {
        SPECIALIZED_ITEMTYPE_INGREDIENT_ALCOHOL,
        SPECIALIZED_ITEMTYPE_INGREDIENT_TEA,
        SPECIALIZED_ITEMTYPE_INGREDIENT_TONIC,
        SPECIALIZED_ITEMTYPE_INGREDIENT_DRINK_ADDITIVE,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_RARE_INGREDIENT] =
    {
        SPECIALIZED_ITEMTYPE_INGREDIENT_RARE,
    },
}

local CRAFTING_TYPE_ITEM_TYPE_DISPLAY_CATEGORY =
{
    [CRAFTING_TYPE_BLACKSMITHING] = ITEM_TYPE_DISPLAY_CATEGORY_BLACKSMITHING,
    [CRAFTING_TYPE_CLOTHIER] = ITEM_TYPE_DISPLAY_CATEGORY_CLOTHING,
    [CRAFTING_TYPE_WOODWORKING] = ITEM_TYPE_DISPLAY_CATEGORY_WOODWORKING,
    [CRAFTING_TYPE_JEWELRYCRAFTING] = ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING,
    [CRAFTING_TYPE_ALCHEMY] = ITEM_TYPE_DISPLAY_CATEGORY_ALCHEMY,
    [CRAFTING_TYPE_ENCHANTING] = ITEM_TYPE_DISPLAY_CATEGORY_ENCHANTING,
    [CRAFTING_TYPE_PROVISIONING] = ITEM_TYPE_DISPLAY_CATEGORY_PROVISIONING,
}

local GAMEPAD_ITEM_CATEGORY_ITEM_TYPE_DISPLAY_CATEGORY =
{
    [GAMEPAD_ITEM_CATEGORY_BLACKSMITH] = ITEM_TYPE_DISPLAY_CATEGORY_BLACKSMITHING,
    [GAMEPAD_ITEM_CATEGORY_CLOTHIER] = ITEM_TYPE_DISPLAY_CATEGORY_CLOTHING,
    [GAMEPAD_ITEM_CATEGORY_WOODWORKING] = ITEM_TYPE_DISPLAY_CATEGORY_WOODWORKING,
    [GAMEPAD_ITEM_CATEGORY_JEWELRYCRAFTING] = ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING,
    [GAMEPAD_ITEM_CATEGORY_ALCHEMY] = ITEM_TYPE_DISPLAY_CATEGORY_ALCHEMY,
    [GAMEPAD_ITEM_CATEGORY_ENCHANTING] = ITEM_TYPE_DISPLAY_CATEGORY_ENCHANTING,
    [GAMEPAD_ITEM_CATEGORY_TRAIT_ITEM] = ITEM_TYPE_DISPLAY_CATEGORY_TRAIT_ITEM,
}

local EQUIPMENT_FILTER_TYPE_WEAPONTYPES =
{
    [EQUIPMENT_FILTER_TYPE_ONE_HANDED] =
    {
        WEAPONTYPE_AXE,
        WEAPONTYPE_HAMMER,
        WEAPONTYPE_SWORD,
        WEAPONTYPE_DAGGER,
    },
    [EQUIPMENT_FILTER_TYPE_TWO_HANDED] =
    {
        WEAPONTYPE_TWO_HANDED_AXE,
        WEAPONTYPE_TWO_HANDED_HAMMER,
        WEAPONTYPE_TWO_HANDED_SWORD,
    },
    [EQUIPMENT_FILTER_TYPE_BOW] =
    {
        WEAPONTYPE_BOW,
    },
    [EQUIPMENT_FILTER_TYPE_DESTRO_STAFF] =
    {
        WEAPONTYPE_FIRE_STAFF,
        WEAPONTYPE_FROST_STAFF,
        WEAPONTYPE_LIGHTNING_STAFF,
    },
    [EQUIPMENT_FILTER_TYPE_RESTO_STAFF] =
    {
        WEAPONTYPE_HEALING_STAFF,
    },
}

local EQUIPMENT_FILTER_TYPE_ARMORTYPES =
{
    [EQUIPMENT_FILTER_TYPE_LIGHT] = ARMORTYPE_LIGHT,
    [EQUIPMENT_FILTER_TYPE_MEDIUM] = ARMORTYPE_MEDIUM,
    [EQUIPMENT_FILTER_TYPE_HEAVY] = ARMORTYPE_HEAVY,
}

local ITEM_TYPE_DISPLAY_CATEGORY_ITEMFILTERTYPE =
{
    [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = ITEMFILTERTYPE_ALL,
    [ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS] = ITEMFILTERTYPE_WEAPONS,
    [ITEM_TYPE_DISPLAY_CATEGORY_ARMOR] = ITEMFILTERTYPE_ARMOR,
    [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY] = ITEMFILTERTYPE_JEWELRY,
    [ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE] = ITEMFILTERTYPE_CONSUMABLE,
    [ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING] = ITEMFILTERTYPE_CRAFTING,
    [ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING] = ITEMFILTERTYPE_FURNISHING,
    [ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS] = ITEMFILTERTYPE_MISCELLANEOUS,
    [ITEM_TYPE_DISPLAY_CATEGORY_QUEST] = ITEMFILTERTYPE_QUEST,
    [ITEM_TYPE_DISPLAY_CATEGORY_JUNK] = ITEMFILTERTYPE_JUNK,
    [ITEM_TYPE_DISPLAY_CATEGORY_BLACKSMITHING] = ITEMFILTERTYPE_BLACKSMITHING,
    [ITEM_TYPE_DISPLAY_CATEGORY_CLOTHING] = ITEMFILTERTYPE_CLOTHING,
    [ITEM_TYPE_DISPLAY_CATEGORY_WOODWORKING] = ITEMFILTERTYPE_WOODWORKING,
    [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING] = ITEMFILTERTYPE_JEWELRYCRAFTING,
    [ITEM_TYPE_DISPLAY_CATEGORY_ALCHEMY] = ITEMFILTERTYPE_ALCHEMY,
    [ITEM_TYPE_DISPLAY_CATEGORY_ENCHANTING] = ITEMFILTERTYPE_ENCHANTING,
    [ITEM_TYPE_DISPLAY_CATEGORY_PROVISIONING] = ITEMFILTERTYPE_PROVISIONING,
    [ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MATERIAL] = ITEMFILTERTYPE_STYLE_MATERIALS,
    [ITEM_TYPE_DISPLAY_CATEGORY_TRAIT_ITEM] = ITEMFILTERTYPE_TRAIT_ITEMS,
}

local TRADING_HOUSE_CATEGORY_ITEM_TYPE_DISPLAY_CATEGORY =
{
    [TRADING_HOUSE_CATEGORY_HEADER_ALL_ITEMS] = ITEM_TYPE_DISPLAY_CATEGORY_ALL,
    [TRADING_HOUSE_CATEGORY_HEADER_WEAPONS] = ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS,
    [TRADING_HOUSE_CATEGORY_HEADER_APPAREL] = ITEM_TYPE_DISPLAY_CATEGORY_ARMOR,
    [TRADING_HOUSE_CATEGORY_HEADER_JEWELRY] = ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY,
    [TRADING_HOUSE_CATEGORY_HEADER_CONSUMABLES] = ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE,
    [TRADING_HOUSE_CATEGORY_HEADER_MATERIALS] = ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING,
    [TRADING_HOUSE_CATEGORY_HEADER_GLYPHS] = ITEM_TYPE_DISPLAY_CATEGORY_GLYPH,
    [TRADING_HOUSE_CATEGORY_HEADER_FURNISHINGS] = ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING,
    [TRADING_HOUSE_CATEGORY_HEADER_MISC] = ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS,
    [TRADING_HOUSE_CATEGORY_HEADER_COMPANION_EQUIPMENT] = ITEM_TYPE_DISPLAY_CATEGORY_COMPANION,
}

local FILTER_INFO_TYPE_ITEM_TYPE_DISPLAY_CATEGORY = 1
local FILTER_INFO_TYPE_EQUIPMENT_FILTER_TYPE = 2
local FILTER_INFO_TYPE_ITEM_TYPE = 3
local FILTER_INFO_TYPE_CONSUMABLE_TYPE = 4
local FILTER_INFO_TYPE_SPECIALIZED_ITEM_TYPE = 5
local FILTER_INFO_TYPE_MISCELLANEOUS_TYPE = 6
local FILTER_INFO_TYPE_PROVISIONING_TYPE = 7

local ITEM_TYPE_DISPLAY_CATEGORY_FILTER_INFO_TYPE =
{
    [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = FILTER_INFO_TYPE_ITEM_TYPE_DISPLAY_CATEGORY,
    [ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS] = FILTER_INFO_TYPE_EQUIPMENT_FILTER_TYPE,
    [ITEM_TYPE_DISPLAY_CATEGORY_ARMOR] = FILTER_INFO_TYPE_EQUIPMENT_FILTER_TYPE,
    [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY] = FILTER_INFO_TYPE_EQUIPMENT_FILTER_TYPE,
    [ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE] = FILTER_INFO_TYPE_CONSUMABLE_TYPE,
    [ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING] = FILTER_INFO_TYPE_ITEM_TYPE_DISPLAY_CATEGORY,
    [ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING] = FILTER_INFO_TYPE_SPECIALIZED_ITEM_TYPE,
    [ITEM_TYPE_DISPLAY_CATEGORY_COMPANION] = FILTER_INFO_TYPE_ITEM_TYPE_DISPLAY_CATEGORY,
    [ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS] = FILTER_INFO_TYPE_MISCELLANEOUS_TYPE,
    [ITEM_TYPE_DISPLAY_CATEGORY_QUEST] = FILTER_INFO_TYPE_ITEM_TYPE_DISPLAY_CATEGORY,
    [ITEM_TYPE_DISPLAY_CATEGORY_JUNK] = FILTER_INFO_TYPE_ITEM_TYPE_DISPLAY_CATEGORY,
    [ITEM_TYPE_DISPLAY_CATEGORY_BLACKSMITHING] = FILTER_INFO_TYPE_ITEM_TYPE,
    [ITEM_TYPE_DISPLAY_CATEGORY_CLOTHING] = FILTER_INFO_TYPE_ITEM_TYPE,
    [ITEM_TYPE_DISPLAY_CATEGORY_WOODWORKING] = FILTER_INFO_TYPE_ITEM_TYPE,
    [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING] = FILTER_INFO_TYPE_ITEM_TYPE,
    [ITEM_TYPE_DISPLAY_CATEGORY_ALCHEMY] = FILTER_INFO_TYPE_ITEM_TYPE,
    [ITEM_TYPE_DISPLAY_CATEGORY_ENCHANTING] = FILTER_INFO_TYPE_ITEM_TYPE,
    [ITEM_TYPE_DISPLAY_CATEGORY_PROVISIONING] = FILTER_INFO_TYPE_PROVISIONING_TYPE,
    [ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MATERIAL] = FILTER_INFO_TYPE_ITEM_TYPE,
    [ITEM_TYPE_DISPLAY_CATEGORY_TRAIT_ITEM] = FILTER_INFO_TYPE_ITEM_TYPE,
}

local ITEM_TYPE_DISPLAY_CATEGORY_SUBCATEGORY_TYPES =
{
    [ITEM_TYPE_DISPLAY_CATEGORY_ALL] =
    {
        ITEM_TYPE_DISPLAY_CATEGORY_ALL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS] =
    {
        EQUIPMENT_FILTER_TYPE_NONE,
        EQUIPMENT_FILTER_TYPE_ONE_HANDED,
        EQUIPMENT_FILTER_TYPE_TWO_HANDED,
        EQUIPMENT_FILTER_TYPE_BOW,
        EQUIPMENT_FILTER_TYPE_DESTRO_STAFF,
        EQUIPMENT_FILTER_TYPE_RESTO_STAFF,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_ARMOR] =
    {
        EQUIPMENT_FILTER_TYPE_NONE,
        EQUIPMENT_FILTER_TYPE_LIGHT,
        EQUIPMENT_FILTER_TYPE_MEDIUM,
        EQUIPMENT_FILTER_TYPE_HEAVY,
        EQUIPMENT_FILTER_TYPE_SHIELD,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY] =
    {
        EQUIPMENT_FILTER_TYPE_NONE,
        EQUIPMENT_FILTER_TYPE_NECK,
        EQUIPMENT_FILTER_TYPE_RING,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE] =
    {
        ITEM_TYPE_DISPLAY_CATEGORY_ALL,
        ITEM_TYPE_DISPLAY_CATEGORY_FOOD,
        ITEM_TYPE_DISPLAY_CATEGORY_DRINK,
        ITEM_TYPE_DISPLAY_CATEGORY_RECIPE,
        ITEM_TYPE_DISPLAY_CATEGORY_POTION,
        ITEM_TYPE_DISPLAY_CATEGORY_POISON,
        ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MOTIF,
        ITEM_TYPE_DISPLAY_CATEGORY_MASTER_WRIT,
        ITEM_TYPE_DISPLAY_CATEGORY_CONTAINER,
        ITEM_TYPE_DISPLAY_CATEGORY_REPAIR_ITEM,
        ITEM_TYPE_DISPLAY_CATEGORY_CROWN_ITEM,
        ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING] =
    {
        ITEM_TYPE_DISPLAY_CATEGORY_ALL,
        ITEM_TYPE_DISPLAY_CATEGORY_BLACKSMITHING,
        ITEM_TYPE_DISPLAY_CATEGORY_CLOTHING,
        ITEM_TYPE_DISPLAY_CATEGORY_WOODWORKING,
        ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING,
        ITEM_TYPE_DISPLAY_CATEGORY_ALCHEMY,
        ITEM_TYPE_DISPLAY_CATEGORY_ENCHANTING,
        ITEM_TYPE_DISPLAY_CATEGORY_PROVISIONING,
        ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MATERIAL,
        ITEM_TYPE_DISPLAY_CATEGORY_TRAIT_ITEM,
        ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING_MATERIAL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING] =
    {
        SPECIALIZED_ITEMTYPE_NONE,
        SPECIALIZED_ITEMTYPE_FURNISHING_ORNAMENTAL,
        SPECIALIZED_ITEMTYPE_FURNISHING_LIGHT,
        SPECIALIZED_ITEMTYPE_FURNISHING_SEATING,
        SPECIALIZED_ITEMTYPE_FURNISHING_CRAFTING_STATION,
        SPECIALIZED_ITEMTYPE_FURNISHING_TARGET_DUMMY,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_COMPANION] =
    {
        ITEM_TYPE_DISPLAY_CATEGORY_ALL,
        ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS,
        ITEM_TYPE_DISPLAY_CATEGORY_ARMOR,
        ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS] =
    {
        ITEM_TYPE_DISPLAY_CATEGORY_ALL,
        ITEM_TYPE_DISPLAY_CATEGORY_APPEARANCE,
        ITEM_TYPE_DISPLAY_CATEGORY_GLYPH,
        ITEM_TYPE_DISPLAY_CATEGORY_SOUL_GEM,
        ITEM_TYPE_DISPLAY_CATEGORY_SIEGE,
        ITEM_TYPE_DISPLAY_CATEGORY_TOOL,
        ITEM_TYPE_DISPLAY_CATEGORY_TROPHY,
        ITEM_TYPE_DISPLAY_CATEGORY_LURE,
        ITEM_TYPE_DISPLAY_CATEGORY_TRASH,
        ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_QUEST] =
    {
        ITEM_TYPE_DISPLAY_CATEGORY_ALL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_JUNK] =
    {
        ITEM_TYPE_DISPLAY_CATEGORY_ALL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_BLACKSMITHING] =
    {
        ITEMTYPE_NONE,
        ITEMTYPE_BLACKSMITHING_RAW_MATERIAL,
        ITEMTYPE_BLACKSMITHING_MATERIAL,
        ITEMTYPE_BLACKSMITHING_BOOSTER,
        ITEMTYPE_FURNISHING_MATERIAL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_CLOTHING] =
    {
        ITEMTYPE_NONE,
        ITEMTYPE_CLOTHIER_RAW_MATERIAL,
        ITEMTYPE_CLOTHIER_MATERIAL,
        ITEMTYPE_CLOTHIER_BOOSTER,
        ITEMTYPE_FURNISHING_MATERIAL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_WOODWORKING] =
    {
        ITEMTYPE_NONE,
        ITEMTYPE_WOODWORKING_RAW_MATERIAL,
        ITEMTYPE_WOODWORKING_MATERIAL,
        ITEMTYPE_WOODWORKING_BOOSTER,
        ITEMTYPE_FURNISHING_MATERIAL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING] =
    {
        ITEMTYPE_NONE,
        ITEMTYPE_JEWELRYCRAFTING_RAW_MATERIAL,
        ITEMTYPE_JEWELRYCRAFTING_MATERIAL,
        ITEMTYPE_JEWELRYCRAFTING_RAW_BOOSTER,
        ITEMTYPE_JEWELRYCRAFTING_BOOSTER,
        ITEMTYPE_FURNISHING_MATERIAL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_ALCHEMY] =
    {
        ITEMTYPE_NONE,
        ITEMTYPE_REAGENT,
        ITEMTYPE_POTION_BASE,
        ITEMTYPE_POISON_BASE,
        ITEMTYPE_FURNISHING_MATERIAL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_ENCHANTING] =
    {
        ITEMTYPE_NONE,
        ITEMTYPE_ENCHANTING_RUNE_ASPECT,
        ITEMTYPE_ENCHANTING_RUNE_POTENCY,
        ITEMTYPE_ENCHANTING_RUNE_ESSENCE,
        ITEMTYPE_FURNISHING_MATERIAL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_PROVISIONING] =
    {
        ITEM_TYPE_DISPLAY_CATEGORY_ALL,
        ITEM_TYPE_DISPLAY_CATEGORY_FOOD_INGREDIENT,
        ITEM_TYPE_DISPLAY_CATEGORY_DRINK_INGREDIENT,
        ITEM_TYPE_DISPLAY_CATEGORY_RARE_INGREDIENT,
        ITEM_TYPE_DISPLAY_CATEGORY_LURE,
        ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING_MATERIAL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MATERIAL] =
    {
        ITEMTYPE_NONE,
        ITEMTYPE_STYLE_MATERIAL,
        ITEMTYPE_RAW_MATERIAL,
        ITEMTYPE_FURNISHING_MATERIAL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_TRAIT_ITEM] =
    {
        ITEMTYPE_NONE,
        ITEMTYPE_ARMOR_TRAIT,
        ITEMTYPE_WEAPON_TRAIT,
        ITEMTYPE_JEWELRY_RAW_TRAIT,
        ITEMTYPE_JEWELRY_TRAIT,
        ITEMTYPE_FURNISHING_MATERIAL,
    }
}

-- Text Search Types
ZO_TEXT_SEARCH_TYPE_INVENTORY = 1
ZO_TEXT_SEARCH_TYPE_QUEST_ITEM = 2
ZO_TEXT_SEARCH_TYPE_QUEST_TOOL = 3
ZO_TEXT_SEARCH_TYPE_COLLECTIBLE = 4

-- Text Search Attributes
ZO_TEXT_SEARCH_CACHE_DATA = true

--
-- ZO_ItemFilterUtils
--
ZO_ItemFilterUtils = ZO_Object:Subclass()

-- Text Search Functions

local function GetInventoryItemInformationForTextSearch(bagId, slotIndex)
    local name = GetItemName(bagId, slotIndex)
    name = name:lower()

    local _, _, _, _, _, equipType, itemStyle = GetItemInfo(bagId, slotIndex)

    return name, equipType, itemStyle
end

do
    local EQUIP_TYPE_NAMES = {}
    local ITEM_STYLE_NAME = {}
    function ZO_ItemFilterUtils.TextSearchProcessInventoryItem(stringSearch, data, searchTerm, cache)
        local name, equipType, itemStyle = stringSearch:GetFromCache(data, cache, GetInventoryItemInformationForTextSearch, data.bagId, data.slotIndex)

        if zo_plainstrfind(name, searchTerm) then
            return true
        end

        if equipType ~= EQUIP_TYPE_INVALID then
            local equipTypeName = EQUIP_TYPE_NAMES[equipType]
            if not equipTypeName then
                equipTypeName = GetString("SI_EQUIPTYPE", equipType):lower()
                EQUIP_TYPE_NAMES[equipType] = equipTypeName
            end
            if zo_plainstrfind(equipTypeName, searchTerm) then
                return true
            end
        end

        if itemStyle ~= 0 then
            local itemStyleName = ITEM_STYLE_NAME[itemStyle]
            if not itemStyleName then
                itemStyleName = zo_strlower(GetItemStyleName(itemStyle))
                ITEM_STYLE_NAME[itemStyle] = itemStyleName
            end
            if zo_plainstrfind(itemStyleName, searchTerm) then
                return true
            end
        end

        return false
    end
end

local function GetQuestItemInformationForTextSearch(questIndex, stepIndex, conditionIndex)
    local _, _, name = GetQuestItemInfo(questIndex, stepIndex, conditionIndex)
    return name:lower()
end

function ZO_ItemFilterUtils.TextSearchProcessQuestItem(stringSearch, data, searchTerm, cache)
    local name = stringSearch:GetFromCache(data, cache, GetQuestItemInformationForTextSearch, data.questIndex, data.stepIndex, data.conditionIndex)
    return zo_plainstrfind(name, searchTerm)
end

local function GetQuestToolInformationForTextSearch(questIndex, toolIndex)
    local _, _, _, name = GetQuestToolInfo(questIndex, toolIndex)
    return name:lower()
end

function ZO_ItemFilterUtils.TextSearchProcessQuestTool(stringSearch, data, searchTerm, cache)
    local name = stringSearch:GetFromCache(data, cache, GetQuestToolInformationForTextSearch, data.questIndex, data.toolIndex)
    return zo_plainstrfind(name, searchTerm)
end

local function GetCollectibleInformationForTextSearch(collectibleId)
    local name = GetCollectibleInfo(collectibleId)
    return name:lower()
end

function ZO_ItemFilterUtils.TextSearchProcessCollectible(stringSearch, data, searchTerm, cache)
    local name = stringSearch:GetFromCache(data, cache, GetCollectibleInformationForTextSearch, data.collectibleId)
    return zo_plainstrfind(name, searchTerm)
end

-- Type List Getter Functions

function ZO_ItemFilterUtils.GetSearchFilterData(itemTypeDisplayCategory, subCategory)
    local itemTypeDisplayCategoryFilterInfoType = ITEM_TYPE_DISPLAY_CATEGORY_FILTER_INFO_TYPE[itemTypeDisplayCategory]
    local itemTypeDisplayCategorySubCategories = ITEM_TYPE_DISPLAY_CATEGORY_SUBCATEGORY_TYPES[itemTypeDisplayCategory]

    if ZO_IsElementInNumericallyIndexedTable(itemTypeDisplayCategorySubCategories, subCategory) then
        if itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_ITEM_TYPE_DISPLAY_CATEGORY
            or itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_PROVISIONING_TYPE
            or itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_MISCELLANEOUS_TYPE
            or itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_CONSUMABLE_TYPE then
            return ZO_ItemFilterUtils.GetItemTypeDisplayCategoryFilterDisplayInfo(subCategory)
        elseif itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_EQUIPMENT_FILTER_TYPE then
            return ZO_ItemFilterUtils.GetEquipmentFilterTypeFilterDisplayInfo(subCategory)
        elseif itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_ITEM_TYPE then
            return ZO_ItemFilterUtils.GetItemTypeFilterDisplayInfo(subCategory)
        elseif itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_SPECIALIZED_ITEM_TYPE then
            return ZO_ItemFilterUtils.GetSpecializedItemTypeFilterDisplayInfo(subCategory)
        end
    end
end

function ZO_ItemFilterUtils.GetItemTypeDisplayCategoryByItemFilterType(itemFilterType)
    for itemTypeDisplayCategory, itemFilterTypeValue in pairs(ITEM_TYPE_DISPLAY_CATEGORY_ITEMFILTERTYPE) do
        if itemFilterTypeValue == itemFilterType then
            return itemTypeDisplayCategory
        end
    end
end

function ZO_ItemFilterUtils.GetItemTypesByCraftingType(craftingType)
    local itemTypeDisplayCategory = CRAFTING_TYPE_ITEM_TYPE_DISPLAY_CATEGORY[craftingType]
    return ITEM_TYPE_DISPLAY_CATEGORY_ITEMTYPES[itemTypeDisplayCategory]
end

function ZO_ItemFilterUtils.GetSubCategoryTypesByDisplayCategoryType(displayCategoryType)
    return ITEM_TYPE_DISPLAY_CATEGORY_SUBCATEGORY_TYPES[displayCategoryType]
end

function ZO_ItemFilterUtils.GetWeaponTypesByEquipmentFilterType(equipmentFilterType)
    return EQUIPMENT_FILTER_TYPE_WEAPONTYPES[equipmentFilterType]
end

function ZO_ItemFilterUtils.GetArmorTypesByEquipmentFilterType(equipmentFilterType)
    return EQUIPMENT_FILTER_TYPE_ARMORTYPES[equipmentFilterType]
end

function ZO_ItemFilterUtils.GetAllWeaponTypesInEquipmentFilterTypes()
    local allWeaponTypes = {}
    for _, weaponTypeList in pairs(EQUIPMENT_FILTER_TYPE_WEAPONTYPES) do
        for _, weaponType in ipairs(weaponTypeList) do
            table.insert(allWeaponTypes, weaponType)
        end
    end

    return allWeaponTypes
end

function ZO_ItemFilterUtils.GetSpecializedItemTypesByItemTypeDisplayCategory(itemTypeDisplayCategory)
    return ITEM_TYPE_DISPLAY_CATEGORY_SPECIALIZED_ITEM_TYPES[itemTypeDisplayCategory]
end

-- Icon Getter Functions
function ZO_ItemFilterUtils.GetItemTypeDisplayCategoryFilterIcons(itemTypeDisplayCategory)
    return ITEM_TYPE_DISPLAY_CATEGORY_ICONS[itemTypeDisplayCategory]
end

function ZO_ItemFilterUtils.GetItemTypeFilterIcons(itemType)
    return ITEMTYPE_ICONS[itemType]
end

function ZO_ItemFilterUtils.GetWeaponTypeFilterIcons(weaponType)
    return WEAPONTYPE_ICONS[weaponType]
end

function ZO_ItemFilterUtils.GetEquipTypeFilterIcons(equipType)
    return EQUIPTYPE_ICONS[equipType]
end

function ZO_ItemFilterUtils.GetSpecializedItemTypeFilterIcons(specializedItemType)
    return SPECIALIZED_ITEM_TYPE_ICONS[specializedItemType]
end

function ZO_ItemFilterUtils.GetTradingHouseCategoryHeaderIcons(tradingHouseCategoryHeader)
    local itemTypeDisplayCategory = TRADING_HOUSE_CATEGORY_ITEM_TYPE_DISPLAY_CATEGORY[tradingHouseCategoryHeader]
    return ITEM_TYPE_DISPLAY_CATEGORY_ICONS[itemTypeDisplayCategory]
end

ZO_QUEST_ITEMS_HIDDEN_COLUMNS =
{
    ["traitInformationSortOrder"] = true,
    ["sellInformationSortOrder"] = true,
    ["statusSortOrder"] = true,
    ["stackSellPrice"] = true,
}

do
    local TYPICAL_HIDDEN_COLUMNS =
    {
        ["traitInformationSortOrder"] = true,
        ["sellInformationSortOrder"] = true,
    }

    local GEAR_HIDDEN_COLUMNS =
    {
        ["traitInformationSortOrder"] = function() return GetInteractionType() == INTERACTION_VENDOR end,
        ["sellInformationSortOrder"] = function() return GetInteractionType() ~= INTERACTION_VENDOR end,
    }

    local ITEM_TYPE_DISPLAY_CATEGORY_GEAR =
    {
        [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = true,
        [ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS] = true,
        [ITEM_TYPE_DISPLAY_CATEGORY_ARMOR] = true,
        [ITEM_TYPE_DISPLAY_CATEGORY_JUNK] = true,
        [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY] = true,
    }

    function ZO_ItemFilterUtils.GetItemTypeDisplayCategoryFilterDisplayInfo(itemTypeDisplayCategory)
        local hideColumnTable
        if itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_QUEST then
            hideColumnTable = ZO_QUEST_ITEMS_HIDDEN_COLUMNS
        elseif ITEM_TYPE_DISPLAY_CATEGORY_GEAR[itemTypeDisplayCategory] then
            hideColumnTable = GEAR_HIDDEN_COLUMNS
        else
            hideColumnTable = TYPICAL_HIDDEN_COLUMNS
        end

        return {
            filterType = itemTypeDisplayCategory,
            filterString = GetString("SI_ITEMTYPEDISPLAYCATEGORY", itemTypeDisplayCategory),
            hideColumnTable = hideColumnTable,
            icons = ITEM_TYPE_DISPLAY_CATEGORY_ICONS[itemTypeDisplayCategory]
        }
    end

    function ZO_ItemFilterUtils.GetEquipmentFilterTypeFilterDisplayInfo(equipmentFilterTypeFilter)
        local filterString = GetString("SI_EQUIPMENTFILTERTYPE", equipmentFilterTypeFilter)

        if filterString == "" then
            filterString = GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_ALL)
        end

        return {
            filterType = equipmentFilterTypeFilter,
            filterString = filterString,
            hideColumnTable = TYPICAL_HIDDEN_COLUMNS,
            icons = EQUIPMENT_FILTER_TYPE_ICONS[equipmentFilterTypeFilter]
        }
    end

    function ZO_ItemFilterUtils.GetItemTypeFilterDisplayInfo(itemTypeFilter)
        local filterString = GetString("SI_ITEMTYPE", itemTypeFilter)

        if filterString == "" or itemTypeFilter == ITEMTYPE_NONE then
            filterString = GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_ALL)
        end

        return {
            filterType = itemTypeFilter,
            filterString = filterString,
            hideColumnTable = TYPICAL_HIDDEN_COLUMNS,
            icons = ITEMTYPE_ICONS[itemTypeFilter]
        }
    end

    function ZO_ItemFilterUtils.GetSpecializedItemTypeFilterDisplayInfo(specializedItemType)
        local filterString
        if specializedItemType == SPECIALIZED_ITEMTYPE_FURNISHING_ORNAMENTAL then
            filterString = GetString(SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ORNAMENTAL_FURNISHINGS)
        else
            filterString = GetString("SI_SPECIALIZEDITEMTYPE", specializedItemType)

            if filterString == "" then
                filterString = GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_ALL)
            end
        end

        return {
            filterType = specializedItemType,
            filterString = filterString,
            hideColumnTable = TYPICAL_HIDDEN_COLUMNS,
            icons = SPECIALIZED_ITEM_TYPE_ICONS[specializedItemType]
        }
    end
end

function ZO_ItemFilterUtils.IsSlotInItemTypeDisplayCategoryAndSubcategory(slot, itemTypeDisplayCategory, itemTypeSubCategory)
    if itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_ALL then
        return true
    end

    if itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_COMPANION then
        return ZO_ItemFilterUtils.IsSlotFilterDataInItemTypeDisplayCategory(slot, itemTypeSubCategory)
    elseif slot.actorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION then
        return false
    end

    if not ZO_ItemFilterUtils.IsSlotFilterDataInItemTypeDisplayCategory(slot, itemTypeDisplayCategory) then
        return false
    end

    local itemTypeDisplayCategoryFilterInfoType = ITEM_TYPE_DISPLAY_CATEGORY_FILTER_INFO_TYPE[itemTypeDisplayCategory]

    if itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_ITEM_TYPE_DISPLAY_CATEGORY then
        return ZO_ItemFilterUtils.IsSlotInItemTypeDisplayCategory(slot, itemTypeSubCategory)
    elseif itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_EQUIPMENT_FILTER_TYPE then
        return ZO_ItemFilterUtils.IsSlotInEquipmentFilterType(slot, itemTypeSubCategory)
    elseif itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_ITEM_TYPE then
        return ZO_ItemFilterUtils.IsSlotInItemType(slot, itemTypeSubCategory)
    elseif itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_CONSUMABLE_TYPE then
        return ZO_ItemFilterUtils.IsSlotInConsumableSubcategory(slot, itemTypeSubCategory)
    elseif itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_SPECIALIZED_ITEM_TYPE then
        return ZO_ItemFilterUtils.IsSlotInSpecializedItemType(slot, itemTypeDisplayCategory, itemTypeSubCategory)
    elseif itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_MISCELLANEOUS_TYPE then
        return ZO_ItemFilterUtils.IsSlotInMiscellaneousSubcategory(slot, itemTypeSubCategory)
    elseif itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_PROVISIONING_TYPE then
        return ZO_ItemFilterUtils.IsSlotInProvisioningSubcategory(slot, itemTypeSubCategory)
    end
end

function ZO_ItemFilterUtils.IsCompanionSlotInItemTypeDisplayCategoryAndSubcategory(slot, itemTypeDisplayCategory, itemTypeSubCategory)
    if itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_ALL then
        return true
    end

    if slot.actorCategory ~= GAMEPLAY_ACTOR_CATEGORY_COMPANION then
        return false
    end

    if not ZO_ItemFilterUtils.IsSlotFilterDataInItemTypeDisplayCategory(slot, itemTypeDisplayCategory) then
        return false
    end

    local itemTypeDisplayCategoryFilterInfoType = ITEM_TYPE_DISPLAY_CATEGORY_FILTER_INFO_TYPE[itemTypeDisplayCategory]

    if itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_ITEM_TYPE_DISPLAY_CATEGORY then
        return ZO_ItemFilterUtils.IsSlotInItemTypeDisplayCategory(slot, itemTypeSubCategory)
    elseif itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_EQUIPMENT_FILTER_TYPE then
        return ZO_ItemFilterUtils.IsSlotInEquipmentFilterType(slot, itemTypeSubCategory)
    elseif itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_ITEM_TYPE then
        return ZO_ItemFilterUtils.IsSlotInItemType(slot, itemTypeSubCategory)
    elseif itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_CONSUMABLE_TYPE then
        return ZO_ItemFilterUtils.IsSlotInConsumableSubcategory(slot, itemTypeSubCategory)
    elseif itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_SPECIALIZED_ITEM_TYPE then
        return ZO_ItemFilterUtils.IsSlotInSpecializedItemType(slot, itemTypeDisplayCategory, itemTypeSubCategory)
    elseif itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_MISCELLANEOUS_TYPE then
        return ZO_ItemFilterUtils.IsSlotInMiscellaneousSubcategory(slot, itemTypeSubCategory)
    elseif itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_PROVISIONING_TYPE then
        return ZO_ItemFilterUtils.IsSlotInProvisioningSubcategory(slot, itemTypeSubCategory)
    end
end

function ZO_ItemFilterUtils.IsItemLinkInItemTypeDisplayCategoryAndSubcategory(itemLink, itemTypeDisplayCategory, itemTypeSubCategory)
    if itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_ALL then
        return true
    end

    if not ZO_ItemFilterUtils.IsItemLinkFilterDataInItemTypeDisplayCategory(itemLink, itemTypeDisplayCategory) then
        return false
    end

    local itemTypeDisplayCategoryFilterInfoType = ITEM_TYPE_DISPLAY_CATEGORY_FILTER_INFO_TYPE[itemTypeDisplayCategory]

    if itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_ITEM_TYPE_DISPLAY_CATEGORY then
        return ZO_ItemFilterUtils.IsItemLinkInItemTypeDisplayCategory(itemLink, itemTypeSubCategory)
    elseif itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_EQUIPMENT_FILTER_TYPE then
        return ZO_ItemFilterUtils.IsItemLinkInEquipmentFilterType(itemLink, itemTypeSubCategory)
    elseif itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_ITEM_TYPE then
        return ZO_ItemFilterUtils.IsItemLinkInItemType(itemLink, itemTypeSubCategory)
    elseif itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_CONSUMABLE_TYPE then
        return ZO_ItemFilterUtils.IsItemLinkInConsumableSubcategory(itemLink, itemTypeSubCategory)
    elseif itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_SPECIALIZED_ITEM_TYPE then
        return ZO_ItemFilterUtils.IsItemLinkInSpecializedItemType(itemLink, itemTypeDisplayCategory, itemTypeSubCategory)
    elseif itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_MISCELLANEOUS_TYPE then
        return ZO_ItemFilterUtils.IsItemLinkInMiscellaneousSubcategory(itemLink, itemTypeSubCategory)
    elseif itemTypeDisplayCategoryFilterInfoType == FILTER_INFO_TYPE_PROVISIONING_TYPE then
        return ZO_ItemFilterUtils.IsItemLinkInProvisioningSubcategory(itemLink, itemTypeSubCategory)
    end
end

function ZO_ItemFilterUtils.IsSlotFilterDataInItemTypeDisplayCategory(slot, itemTypeDisplayCategory)
    if slot.isJunk then
        return itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_JUNK
    end

    if itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_COMPANION then
        return slot.actorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION
    end

    return ZO_ItemFilterUtils.IsFilterDataInItemTypeDisplayCategory(slot.filterData, itemTypeDisplayCategory)
end

function ZO_ItemFilterUtils.IsItemLinkFilterDataInItemTypeDisplayCategory(itemLink, itemTypeDisplayCategory)
    local filterData = { GetItemLinkFilterTypeInfo(itemLink) }
    return ZO_ItemFilterUtils.IsFilterDataInItemTypeDisplayCategory(filterData, itemTypeDisplayCategory)
end

function ZO_ItemFilterUtils.IsFilterDataInItemTypeDisplayCategory(filterData, itemTypeDisplayCategory)
    if itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_ALL then
        return true
    end

    local filter = ITEM_TYPE_DISPLAY_CATEGORY_ITEMFILTERTYPE[itemTypeDisplayCategory]
    if ZO_IsElementInNumericallyIndexedTable(filterData, filter) then
        return true
    end

    return false
end

-- Returns true if slot is not an equipment filter type
function ZO_ItemFilterUtils.IsSlotInEquipmentFilterType(slot, equipmentFilterType)
    if equipmentFilterType == EQUIPMENT_FILTER_TYPE_NONE then
        return true
    end

    return equipmentFilterType == GetItemEquipmentFilterType(slot.bagId, slot.slotIndex)
end

function ZO_ItemFilterUtils.GetItemTypesByItemTypeDisplayCategory(itemTypeDisplayCategory)
    return ITEM_TYPE_DISPLAY_CATEGORY_ITEMTYPES[itemTypeDisplayCategory]
end

function ZO_ItemFilterUtils.IsSlotInItemTypeDisplayCategory(slot, itemTypeDisplayCategory)
    if itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_ALL then
        return true
    end

    local itemType = GetItemType(slot.bagId, slot.slotIndex)
    local itemTypes = ITEM_TYPE_DISPLAY_CATEGORY_ITEMTYPES[itemTypeDisplayCategory]

    if itemTypes and ZO_IsElementInNumericallyIndexedTable(itemTypes, itemType) then
        return true
    end

    return false
end

function ZO_ItemFilterUtils.IsItemLinkInItemTypeDisplayCategory(itemLink, itemTypeDisplayCategory)
    if itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_ALL then
        return true
    end

    local itemType = GetItemLinkItemType(itemLink)
    local itemTypes = ITEM_TYPE_DISPLAY_CATEGORY_ITEMTYPES[itemTypeDisplayCategory]

    if itemTypes and ZO_IsElementInNumericallyIndexedTable(itemTypes, itemType) then
        return true
    end

    return false
end

-- Returns true if slot is not a consumable type
function ZO_ItemFilterUtils.IsSlotInConsumableSubcategory(slot, itemTypeDisplayCategory)
    if itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_ALL then
        return true
    end

    local itemType = GetItemType(slot.bagId, slot.slotIndex)
    local itemTypes = ITEM_TYPE_DISPLAY_CATEGORY_ITEMTYPES[itemTypeDisplayCategory]

    if ZO_IsElementInNumericallyIndexedTable(itemTypes, itemType) then
        return true
    end

    if itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_CROWN_ITEM then
        local isCrownStoreItem = IsItemFromCrownStore(slot.bagId, slot.slotIndex)
        local isCrownCrateItem = IsItemFromCrownCrate(slot.bagId, slot.slotIndex)
        return isCrownStoreItem or isCrownCrateItem
    elseif itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS then
        local consumableTypes = ITEM_TYPE_DISPLAY_CATEGORY_SUBCATEGORY_TYPES[ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE]
        for consumableItemTypeDisplayCategoryIndex, consumableItemTypeDisplayCategory in pairs(consumableTypes) do
            local consumableItemTypes = ITEM_TYPE_DISPLAY_CATEGORY_ITEMTYPES[consumableItemTypeDisplayCategory]
            if consumableItemTypes and ZO_IsElementInNumericallyIndexedTable(consumableItemTypes, itemType) then
                return false
            end
        end

        return true
    end

    return false
end

function ZO_ItemFilterUtils.IsItemLinkInConsumableSubcategory(itemLink, itemTypeDisplayCategory)
    if itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_ALL then
        return true
    end

    local itemType = GetItemLinkItemType(itemLink)
    local itemTypes = ITEM_TYPE_DISPLAY_CATEGORY_ITEMTYPES[itemTypeDisplayCategory]

    if ZO_IsElementInNumericallyIndexedTable(itemTypes, itemType) then
        return true
    end

    if itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_CROWN_ITEM then
        local isCrownStoreItem = IsItemLinkFromCrownStore(itemLink)
        local isCrownCrateItem = IsItemLinkFromCrownCrate(itemLink)
        return isCrownStoreItem or isCrownCrateItem
    elseif itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS then
        local consumableTypes = ITEM_TYPE_DISPLAY_CATEGORY_SUBCATEGORY_TYPES[ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE]
        for consumableItemTypeDisplayCategoryIndex, consumableItemTypeDisplayCategory in pairs(consumableTypes) do
            local consumableItemTypes = ITEM_TYPE_DISPLAY_CATEGORY_ITEMTYPES[consumableItemTypeDisplayCategory]
            if consumableItemTypes and ZO_IsElementInNumericallyIndexedTable(consumableItemTypes, itemType) then
                return false
            end
        end

        return true
    end

    return false
end

-- Returns true if slot is of the type passed in
function ZO_ItemFilterUtils.IsSlotInItemType(slot, itemType)
    if itemType == ITEMTYPE_NONE then
        return true
    end

    return itemType == GetItemType(slot.bagId, slot.slotIndex)
end

-- Returns true if slot is not a specialized item type
function ZO_ItemFilterUtils.IsSlotInSpecializedItemType(slot, itemTypeDisplayCategory, specializedItemTypeFilter)
    if itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_ALL then
        return true
    end

    local _, specializedItemType = GetItemType(slot.bagId, slot.slotIndex)
    local specializedItemTypes = ITEM_TYPE_DISPLAY_CATEGORY_SPECIALIZED_ITEM_TYPES[itemTypeDisplayCategory]

    if specializedItemTypes and ZO_IsElementInNumericallyIndexedTable(specializedItemTypes, specializedItemType) then
        return specializedItemTypeFilter == specializedItemType or specializedItemTypeFilter == SPECIALIZED_ITEMTYPE_NONE
    end

    return false
end

function ZO_ItemFilterUtils.IsItemLinkInSpecializedItemType(itemLink, itemTypeDisplayCategory, specializedItemTypeFilter)
    if itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_ALL then
        return true
    end

    local _, specializedItemType = GetItemLinkItemType(itemLink)
    local specializedItemTypes = ITEM_TYPE_DISPLAY_CATEGORY_SPECIALIZED_ITEM_TYPES[itemTypeDisplayCategory]

    if specializedItemTypes and ZO_IsElementInNumericallyIndexedTable(specializedItemTypes, specializedItemType) then
        return specializedItemTypeFilter == specializedItemType or specializedItemTypeFilter == SPECIALIZED_ITEMTYPE_NONE
    end

    return false
end

function ZO_ItemFilterUtils.IsSlotInMiscellaneousSubcategory(slot, itemTypeDisplayCategory)
    if itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_ALL then
        return true
    end

    local itemType = GetItemType(slot.bagId, slot.slotIndex)
    local itemTypes = ITEM_TYPE_DISPLAY_CATEGORY_ITEMTYPES[itemTypeDisplayCategory]

    if ZO_IsElementInNumericallyIndexedTable(itemTypes, itemType) then
        return true
    end

    if itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS then
        local miscTypes = ITEM_TYPE_DISPLAY_CATEGORY_SUBCATEGORY_TYPES[ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS]
        for miscItemTypeDisplayCategoryIndex, miscItemTypeDisplayCategory in pairs(miscTypes) do
            local miscItemTypes = ITEM_TYPE_DISPLAY_CATEGORY_ITEMTYPES[miscItemTypeDisplayCategory]
            if miscItemTypes and ZO_IsElementInNumericallyIndexedTable(miscItemTypes, itemType) then
                return false
            end
        end

        return true
    end

    return false
end

function ZO_ItemFilterUtils.IsItemLinkInMiscellaneousSubcategory(itemLink, itemTypeDisplayCategory)
    if itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_ALL then
        return true
    end

    local itemType = GetItemLinkItemType(itemLink)
    local itemTypes = ITEM_TYPE_DISPLAY_CATEGORY_ITEMTYPES[itemTypeDisplayCategory]

    if ZO_IsElementInNumericallyIndexedTable(itemTypes, itemType) then
        return true
    end

    if itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS then
        local miscTypes = ITEM_TYPE_DISPLAY_CATEGORY_SUBCATEGORY_TYPES[ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS]
        for miscItemTypeDisplayCategoryIndex, miscItemTypeDisplayCategory in pairs(miscTypes) do
            local miscItemTypes = ITEM_TYPE_DISPLAY_CATEGORY_ITEMTYPES[miscItemTypeDisplayCategory]
            if miscItemTypes and ZO_IsElementInNumericallyIndexedTable(miscItemTypes, itemType) then
                return false
            end
        end

        return true
    end

    return false
end

-- Returns true if slot is not a crafting type
function ZO_ItemFilterUtils.IsSlotInProvisioningSubcategory(slot, itemTypeDisplayCategory)
    if itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_ALL then
        return true
    end

    local itemType, specializedItemType = GetItemType(slot.bagId, slot.slotIndex)
    local itemTypeDisplayCategoryItemTypes = ITEM_TYPE_DISPLAY_CATEGORY_ITEMTYPES[itemTypeDisplayCategory]
    local itemTypeDisplayCategorySpecializedItemTypes = ITEM_TYPE_DISPLAY_CATEGORY_SPECIALIZED_ITEM_TYPES[itemTypeDisplayCategory]

    if itemTypeDisplayCategoryItemTypes then
        return ZO_IsElementInNumericallyIndexedTable(itemTypeDisplayCategoryItemTypes, itemType)
    elseif itemTypeDisplayCategorySpecializedItemTypes then
        return ZO_IsElementInNumericallyIndexedTable(itemTypeDisplayCategorySpecializedItemTypes, specializedItemType)
    end

    return false
end

function ZO_ItemFilterUtils.IsItemLinkInProvisioningSubcategory(itemLink, itemTypeDisplayCategory)
    if itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_ALL then
        return true
    end

    local itemType, specializedItemType = GetItemLinkItemType(itemLink)
    local itemTypeDisplayCategoryItemTypes = ITEM_TYPE_DISPLAY_CATEGORY_ITEMTYPES[itemTypeDisplayCategory]
    local itemTypeDisplayCategorySpecializedItemTypes = ITEM_TYPE_DISPLAY_CATEGORY_SPECIALIZED_ITEM_TYPES[itemTypeDisplayCategory]

    if itemTypeDisplayCategoryItemTypes then
        return ZO_IsElementInNumericallyIndexedTable(itemTypeDisplayCategoryItemTypes, itemType)
    elseif itemTypeDisplayCategorySpecializedItemTypes then
        return ZO_IsElementInNumericallyIndexedTable(itemTypeDisplayCategorySpecializedItemTypes, specializedItemType)
    end

    return false
end

ITEM_FILTER_UTILS = ZO_ItemFilterUtils:New()
