local ORDERED_EQUIP_TYPES =
{
    EQUIP_SLOT_MAIN_HAND,
    EQUIP_SLOT_OFF_HAND,
    EQUIP_SLOT_POISON,

    EQUIP_SLOT_BACKUP_MAIN,
    EQUIP_SLOT_BACKUP_OFF,
    EQUIP_SLOT_BACKUP_POISON,

    EQUIP_SLOT_HEAD,
    EQUIP_SLOT_CHEST,
    EQUIP_SLOT_SHOULDERS,

    EQUIP_SLOT_WAIST,
    EQUIP_SLOT_HAND,

    EQUIP_SLOT_LEGS,
    EQUIP_SLOT_FEET,

    EQUIP_SLOT_COSTUME,

    EQUIP_SLOT_NECK,
    EQUIP_SLOT_RING1,
    EQUIP_SLOT_RING2,
}

function ZO_Character_EnumerateOrderedEquipSlots()
    return ipairs(ORDERED_EQUIP_TYPES)
end

local EQUIP_SLOT_TO_EQUIP_TYPES =
{
    [EQUIP_SLOT_MAIN_HAND]  = { EQUIP_TYPE_MAIN_HAND, EQUIP_TYPE_ONE_HAND, EQUIP_TYPE_TWO_HAND },
    [EQUIP_SLOT_OFF_HAND]   = { EQUIP_TYPE_OFF_HAND, EQUIP_TYPE_ONE_HAND },
    [EQUIP_SLOT_POISON]     = { EQUIP_TYPE_POISON },

    [EQUIP_SLOT_BACKUP_MAIN]= { EQUIP_TYPE_MAIN_HAND, EQUIP_TYPE_ONE_HAND, EQUIP_TYPE_TWO_HAND },
    [EQUIP_SLOT_BACKUP_OFF] = { EQUIP_TYPE_OFF_HAND, EQUIP_TYPE_ONE_HAND },
    [EQUIP_SLOT_BACKUP_POISON] = { EQUIP_TYPE_POISON },

    [EQUIP_SLOT_HEAD]       = { EQUIP_TYPE_HEAD },
    [EQUIP_SLOT_CHEST]      = { EQUIP_TYPE_CHEST },
    [EQUIP_SLOT_SHOULDERS]  = { EQUIP_TYPE_SHOULDERS},

    [EQUIP_SLOT_WAIST]      = { EQUIP_TYPE_WAIST },
    [EQUIP_SLOT_HAND]       = { EQUIP_TYPE_HAND },

    [EQUIP_SLOT_LEGS]       = { EQUIP_TYPE_LEGS },
    [EQUIP_SLOT_FEET]       = { EQUIP_TYPE_FEET },

    [EQUIP_SLOT_COSTUME]    = { EQUIP_TYPE_COSTUME },

    [EQUIP_SLOT_NECK]       = { EQUIP_TYPE_NECK },
    [EQUIP_SLOT_RING1]      = { EQUIP_TYPE_RING },
    [EQUIP_SLOT_RING2]      = { EQUIP_TYPE_RING },
}

function ZO_Character_GetEquipSlotToEquipTypesTable()
    return EQUIP_SLOT_TO_EQUIP_TYPES
end

function ZO_Character_EnumerateEquipSlotToEquipTypes()
    return pairs(EQUIP_SLOT_TO_EQUIP_TYPES)
end

function ZO_Character_DoesEquipSlotUseEquipType(equipSlot, equipType)
    local equipTypes = EQUIP_SLOT_TO_EQUIP_TYPES[equipSlot]
    if equipTypes then
        for i, usedEquipType in ipairs(equipTypes) do
            if usedEquipType == equipType then
                return true
            end
        end
    end
    return false
end

local EQUIP_SLOT_TO_EQUIP_SLOT_VISUAL_CATEGORY =
{
    [EQUIP_SLOT_MAIN_HAND]  = EQUIP_SLOT_VISUAL_CATEGORY_WEAPONS,
    [EQUIP_SLOT_OFF_HAND]   = EQUIP_SLOT_VISUAL_CATEGORY_WEAPONS,
    [EQUIP_SLOT_POISON]     = EQUIP_SLOT_VISUAL_CATEGORY_WEAPONS,

    [EQUIP_SLOT_BACKUP_MAIN]= EQUIP_SLOT_VISUAL_CATEGORY_WEAPONS,
    [EQUIP_SLOT_BACKUP_OFF] = EQUIP_SLOT_VISUAL_CATEGORY_WEAPONS,
    [EQUIP_SLOT_BACKUP_POISON] = EQUIP_SLOT_VISUAL_CATEGORY_WEAPONS,

    [EQUIP_SLOT_HEAD]       = EQUIP_SLOT_VISUAL_CATEGORY_APPAREL,
    [EQUIP_SLOT_CHEST]      = EQUIP_SLOT_VISUAL_CATEGORY_APPAREL,
    [EQUIP_SLOT_SHOULDERS]  = EQUIP_SLOT_VISUAL_CATEGORY_APPAREL,

    [EQUIP_SLOT_WAIST]      = EQUIP_SLOT_VISUAL_CATEGORY_APPAREL,
    [EQUIP_SLOT_HAND]       = EQUIP_SLOT_VISUAL_CATEGORY_APPAREL,

    [EQUIP_SLOT_LEGS]       = EQUIP_SLOT_VISUAL_CATEGORY_APPAREL,
    [EQUIP_SLOT_FEET]       = EQUIP_SLOT_VISUAL_CATEGORY_APPAREL,

    [EQUIP_SLOT_COSTUME]    = EQUIP_SLOT_VISUAL_CATEGORY_ACCESSORIES,

    [EQUIP_SLOT_NECK]       = EQUIP_SLOT_VISUAL_CATEGORY_ACCESSORIES,
    [EQUIP_SLOT_RING1]      = EQUIP_SLOT_VISUAL_CATEGORY_ACCESSORIES,
    [EQUIP_SLOT_RING2]      = EQUIP_SLOT_VISUAL_CATEGORY_ACCESSORIES,
}

function ZO_Character_GetEquipSlotVisualCategory(equipSlot)
    return EQUIP_SLOT_TO_EQUIP_SLOT_VISUAL_CATEGORY[equipSlot]
end

local SLOT_TEXTURES =
{
    [EQUIP_SLOT_HEAD]       = "EsoUI/Art/CharacterWindow/gearSlot_head.dds",
    [EQUIP_SLOT_NECK]       = "EsoUI/Art/CharacterWindow/gearSlot_neck.dds",
    [EQUIP_SLOT_CHEST]      = "EsoUI/Art/CharacterWindow/gearSlot_chest.dds",
    [EQUIP_SLOT_SHOULDERS]  = "EsoUI/Art/CharacterWindow/gearSlot_shoulders.dds",
    [EQUIP_SLOT_MAIN_HAND]  = "EsoUI/Art/CharacterWindow/gearSlot_mainHand.dds",
    [EQUIP_SLOT_OFF_HAND]   = "EsoUI/Art/CharacterWindow/gearSlot_offHand.dds",
    [EQUIP_SLOT_POISON]     = "EsoUI/Art/CharacterWindow/gearSlot_poison.dds",
    [EQUIP_SLOT_WAIST]      = "EsoUI/Art/CharacterWindow/gearSlot_belt.dds",
    [EQUIP_SLOT_LEGS]       = "EsoUI/Art/CharacterWindow/gearSlot_legs.dds",
    [EQUIP_SLOT_FEET]       = "EsoUI/Art/CharacterWindow/gearSlot_feet.dds",
    [EQUIP_SLOT_COSTUME]    = "EsoUI/Art/CharacterWindow/gearSlot_costume.dds",
    [EQUIP_SLOT_RING1]      = "EsoUI/Art/CharacterWindow/gearSlot_ring.dds",
    [EQUIP_SLOT_RING2]      = "EsoUI/Art/CharacterWindow/gearSlot_ring.dds",
    [EQUIP_SLOT_HAND]       = "EsoUI/Art/CharacterWindow/gearSlot_hands.dds",
    [EQUIP_SLOT_BACKUP_MAIN]= "EsoUI/Art/CharacterWindow/gearSlot_mainHand.dds",
    [EQUIP_SLOT_BACKUP_OFF] = "EsoUI/Art/CharacterWindow/gearSlot_offHand.dds",
    [EQUIP_SLOT_BACKUP_POISON] = "EsoUI/Art/CharacterWindow/gearSlot_poison.dds",
}

function ZO_Character_GetEmptyEquipSlotTexture(equipSlot)
    return SLOT_TEXTURES[equipSlot]
end