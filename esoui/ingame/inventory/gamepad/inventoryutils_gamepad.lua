local function GetCategoryFromItemType(itemType)
    -- Alchemy
    if      ITEMTYPE_REAGENT == itemType or 
            ITEMTYPE_POTION_BASE == itemType or
            ITEMTYPE_POISON_BASE == itemType then
        return GAMEPAD_ITEM_CATEGORY_ALCHEMY

    -- Bait
    elseif  ITEMTYPE_LURE == itemType then
        return GAMEPAD_ITEM_CATEGORY_BAIT

    -- Blacksmith
    elseif  ITEMTYPE_BLACKSMITHING_RAW_MATERIAL == itemType or 
            ITEMTYPE_BLACKSMITHING_MATERIAL == itemType or 
            ITEMTYPE_BLACKSMITHING_BOOSTER == itemType then
        return GAMEPAD_ITEM_CATEGORY_BLACKSMITH

    -- Clothier
    elseif  ITEMTYPE_CLOTHIER_RAW_MATERIAL == itemType or 
            ITEMTYPE_CLOTHIER_MATERIAL == itemType or 
            ITEMTYPE_CLOTHIER_BOOSTER == itemType then
        return GAMEPAD_ITEM_CATEGORY_CLOTHIER

    -- Consumable
    elseif  ITEMTYPE_DRINK == itemType or 
            ITEMTYPE_FOOD == itemType or 
            ITEMTYPE_RECIPE == itemType then
        return GAMEPAD_ITEM_CATEGORY_CONSUMABLE

    -- Constume
    elseif  ITEMTYPE_COSTUME == itemType then
        return GAMEPAD_ITEM_CATEGORY_COSTUME

    -- Enchanting
    elseif  ITEMTYPE_ENCHANTING_RUNE_POTENCY == itemType or 
            ITEMTYPE_ENCHANTING_RUNE_ASPECT == itemType or 
            ITEMTYPE_ENCHANTING_RUNE_ESSENCE == itemType then
        return GAMEPAD_ITEM_CATEGORY_ENCHANTING

    -- Glyphs
    elseif  ITEMTYPE_GLYPH_WEAPON == itemType or 
            ITEMTYPE_GLYPH_ARMOR == itemType or 
            ITEMTYPE_GLYPH_JEWELRY == itemType then
        return GAMEPAD_ITEM_CATEGORY_GLYPHS

    -- Potion
    elseif  ITEMTYPE_POTION == itemType then
        return GAMEPAD_ITEM_CATEGORY_POTION

    -- Provisioning
    elseif  ITEMTYPE_INGREDIENT == itemType or 
            ITEMTYPE_ADDITIVE == itemType or 
            ITEMTYPE_SPICE == itemType or 
            ITEMTYPE_FLAVORING == itemType then
        return GAMEPAD_ITEM_CATEGORY_PROVISIONING

    -- Siege
    elseif  ITEMTYPE_SIEGE == itemType or
            ITEMTYPE_AVA_REPAIR == itemType then
        return GAMEPAD_ITEM_CATEGORY_SIEGE

    -- Spellcrafting
    elseif  ITEMTYPE_SPELLCRAFTING_TABLET == itemType then
        return GAMEPAD_ITEM_CATEGORY_SPELLCRAFTING

    -- Style Material
    elseif  ITEMTYPE_RACIAL_STYLE_MOTIF == itemType or
            ITEMTYPE_STYLE_MATERIAL == itemType then
        return GAMEPAD_ITEM_CATEGORY_STYLE_MATERIAL

    -- Soul Gem
    elseif  ITEMTYPE_SOUL_GEM == itemType then
        return GAMEPAD_ITEM_CATEGORY_SOUL_GEM

    -- Tool
    elseif  ITEMTYPE_LOCKPICK == itemType or
            ITEMTYPE_TOOL == itemType then
        return GAMEPAD_ITEM_CATEGORY_TOOL
    
    -- Trait Gem
    elseif  ITEMTYPE_ARMOR_TRAIT == itemType or 
            ITEMTYPE_WEAPON_TRAIT == itemType then
        return GAMEPAD_ITEM_CATEGORY_TRAIT_GEM

    -- Trophy
    elseif  ITEMTYPE_TROPHY == itemType then
        return GAMEPAD_ITEM_CATEGORY_TROPHY

    -- Woodworking
    elseif  ITEMTYPE_WOODWORKING_RAW_MATERIAL == itemType or 
            ITEMTYPE_WOODWORKING_MATERIAL == itemType or 
            ITEMTYPE_WOODWORKING_BOOSTER == itemType then
        return GAMEPAD_ITEM_CATEGORY_WOODWORKING
    end
end

local function GetCategoryFromWeapon(itemData)
    local weaponType
    if itemData.bagId and itemData.slotIndex then
        weaponType = GetItemWeaponType(itemData.bagId, itemData.slotIndex)
    else
        weaponType = GetItemLinkWeaponType(itemData.itemLink)
    end

    -- Axe
    if WEAPONTYPE_AXE == weaponType or WEAPONTYPE_TWO_HANDED_AXE == weaponType then
        return GAMEPAD_ITEM_CATEGORY_AXE

    -- Bow
    elseif WEAPONTYPE_BOW == weaponType then
        return GAMEPAD_ITEM_CATEGORY_BOW

    -- Dagger
    elseif WEAPONTYPE_DAGGER == weaponType then
        return GAMEPAD_ITEM_CATEGORY_DAGGER

    -- Hammer
    elseif WEAPONTYPE_HAMMER == weaponType or WEAPONTYPE_TWO_HANDED_HAMMER == weaponType then
        return GAMEPAD_ITEM_CATEGORY_HAMMER

    -- Shield
    elseif WEAPONTYPE_SHIELD == weaponType then
        return GAMEPAD_ITEM_CATEGORY_SHIELD

    -- Staff
    elseif WEAPONTYPE_HEALING_STAFF == weaponType or WEAPONTYPE_FIRE_STAFF == weaponType or
           WEAPONTYPE_FROST_STAFF == weaponType or WEAPONTYPE_LIGHTNING_STAFF == weaponType then
        return GAMEPAD_ITEM_CATEGORY_STAFF

    -- Sword
    elseif weaponType == WEAPONTYPE_SWORD or weaponType == WEAPONTYPE_TWO_HANDED_SWORD then
        return GAMEPAD_ITEM_CATEGORY_SWORD
    end
end

local function GetCategoryFromArmor(itemData)
    local equipType = itemData.equipType

    -- Chest
    if      EQUIP_TYPE_CHEST == equipType then
        return GAMEPAD_ITEM_CATEGORY_CHEST

    -- Feet
    elseif  EQUIP_TYPE_FEET == equipType then
        return GAMEPAD_ITEM_CATEGORY_FEET

    -- Hand
    elseif  EQUIP_TYPE_HAND == equipType then
        return GAMEPAD_ITEM_CATEGORY_HANDS

    -- Head
    elseif  EQUIP_TYPE_HEAD == equipType then
        return GAMEPAD_ITEM_CATEGORY_HEAD

    -- Legs
    elseif  EQUIP_TYPE_LEGS == equipType then
        return GAMEPAD_ITEM_CATEGORY_LEGS

    -- Ring
    elseif  EQUIP_TYPE_RING == equipType then
        return GAMEPAD_ITEM_CATEGORY_RING

    -- Shoulders
    elseif  EQUIP_TYPE_SHOULDERS == equipType then
        return GAMEPAD_ITEM_CATEGORY_SHOULDERS

    -- Waist
    elseif  EQUIP_TYPE_WAIST == equipType then
        return GAMEPAD_ITEM_CATEGORY_WAIST
    end
end

function ZO_InventoryUtils_Gamepad_GetBestItemCategoryDescription(itemData)
    local category = nil 

    if itemData.equipType == EQUIP_TYPE_RING then
        category = GAMEPAD_ITEM_CATEGORY_RING
    elseif itemData.itemType == ITEMTYPE_WEAPON then
        category = GetCategoryFromWeapon(itemData)
    elseif itemData.itemType == ITEMTYPE_ARMOR then
        category = GetCategoryFromArmor(itemData)
    else
        category = GetCategoryFromItemType(itemData.itemType)
    end

    if category then
        return GetString("SI_GAMEPADITEMCATEGORY", category)
    end

    return zo_strformat(SI_INVENTORY_HEADER, GetString("SI_ITEMTYPE", itemData.itemType))
 end

 --helper comparators
function ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, currentFilter)
    if not currentFilter then return true end

    for i, filter in ipairs(itemData.filterData) do
        if filter == currentFilter then
            return true
        end
    end
    return false
end

function ZO_InventoryUtils_DoesNewItemMatchSupplies(itemData)
    return itemData.equipType == EQUIP_TYPE_INVALID
            and not ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, ITEMFILTERTYPE_QUICKSLOT)
            and not ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, ITEMFILTERTYPE_CRAFTING)
            and not ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, ITEMFILTERTYPE_FURNISHING)
end

function ZO_InventoryUtils_UpdateTooltipEquippedIndicatorText(tooltipType, equipSlot)
	local isHidden, highestPriorityVisualLayerThatIsShowing = WouldEquipmentBeHidden(equipSlot or EQUIP_SLOT_NONE)
	local equipSlotText = ""

    if equipSlot == EQUIP_SLOT_MAIN_HAND then
        equipSlotText = GetString(SI_GAMEPAD_EQUIPPED_MAIN_HAND_ITEM_HEADER)
    elseif equipSlot == EQUIP_SLOT_BACKUP_MAIN then
        equipSlotText = GetString(SI_GAMEPAD_EQUIPPED_BACKUP_MAIN_ITEM_HEADER)
    elseif equipSlot == EQUIP_SLOT_OFF_HAND then
        equipSlotText = GetString(SI_GAMEPAD_EQUIPPED_OFF_HAND_ITEM_HEADER)
    elseif equipSlot == EQUIP_SLOT_BACKUP_OFF then
        equipSlotText = GetString(SI_GAMEPAD_EQUIPPED_BACKUP_OFF_ITEM_HEADER)
	end

	if isHidden then
		GAMEPAD_TOOLTIPS:SetStatusLabelText(tooltipType, GetString(SI_GAMEPAD_EQUIPPED_ITEM_HEADER), equipSlotText, ZO_SELECTED_TEXT:Colorize(GetHiddenByStringForVisualLayer(highestPriorityVisualLayerThatIsShowing)))
	else
		GAMEPAD_TOOLTIPS:SetStatusLabelText(tooltipType, GetString(SI_GAMEPAD_EQUIPPED_ITEM_HEADER), equipSlotText)
	end
end

function ZO_InventoryUtils_GetEquipSlotForEquipType(equipType)
    local equipSlot = nil

    for i, testSlot in ZO_Character_EnumerateOrderedEquipSlots() do
        local locked = IsLockedWeaponSlot(testSlot)
        local isEquipped = HasItemInSlot(BAG_WORN, testSlot)
	    local isCorrectSlot = ZO_Character_DoesEquipSlotUseEquipType(testSlot, equipType)
        if not locked and isEquipped and isCorrectSlot then
		    equipSlot = testSlot
		    break
	    end
    end

    return equipSlot
end