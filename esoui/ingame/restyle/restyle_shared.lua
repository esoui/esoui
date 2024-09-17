-----------------------------
-- Global Helper Functions --
-----------------------------

ZO_RESTYLE_DEFAULT_SET_INDEX = 1

ZO_RESTYLE_TEXTURE_LEVEL_EQUIPPED = 2
ZO_RESTYLE_TEXTURE_LEVEL_DRAG_CALLOUT =  3
ZO_RESTYLE_TEXTURE_LEVEL_PENDING_LOOP = 4
ZO_RESTYLE_TEXTURE_LEVEL_ICON = 6
ZO_RESTYLE_TEXTURE_LEVEL_STATUS = 8

do
    local STACK_COUNT = 1

    function ZO_Restyle_SetupSlotControl(control, restyleSlotData)
        local icon = restyleSlotData:GetIcon()
        if icon == ZO_NO_TEXTURE_FILE then
            icon = ZO_Restyle_GetEmptySlotTexture(restyleSlotData)
        end

        local actorCategory = ZO_OUTFIT_MANAGER.GetActorCategoryByRestyleMode(restyleSlotData:GetRestyleMode())
        local bagId = GetWornBagForGameplayActorCategory(actorCategory)

        if restyleSlotData:IsEquipment() then
            ZO_Inventory_BindSlot(control, SLOT_TYPE_DYEABLE_EQUIPMENT, restyleSlotData:GetRestyleSlotType(), bagId)
        end

        control.restyleSlotData = restyleSlotData

        control.iconTexture:SetTexture(icon)
    end
end

do
    local RESTYLE_SLOT_TEXTURES =
    {
        [RESTYLE_MODE_EQUIPMENT] =
        {
            [EQUIP_SLOT_HEAD] = "EsoUI/Art/CharacterWindow/gearSlot_head.dds",
            [EQUIP_SLOT_CHEST] = "EsoUI/Art/CharacterWindow/gearSlot_chest.dds",
            [EQUIP_SLOT_SHOULDERS] = "EsoUI/Art/CharacterWindow/gearSlot_shoulders.dds",
            [EQUIP_SLOT_OFF_HAND] = "EsoUI/Art/CharacterWindow/gearSlot_offHand.dds",
            [EQUIP_SLOT_WAIST] = "EsoUI/Art/CharacterWindow/gearSlot_belt.dds",
            [EQUIP_SLOT_LEGS] = "EsoUI/Art/CharacterWindow/gearSlot_legs.dds",
            [EQUIP_SLOT_FEET] = "EsoUI/Art/CharacterWindow/gearSlot_feet.dds",
            [EQUIP_SLOT_HAND] = "EsoUI/Art/CharacterWindow/gearSlot_hands.dds",
            [EQUIP_SLOT_BACKUP_OFF] = "EsoUI/Art/CharacterWindow/gearSlot_offHand.dds",
        },
        [RESTYLE_MODE_COLLECTIBLE] =
        {
            [COLLECTIBLE_CATEGORY_TYPE_COSTUME] = "EsoUI/Art/Dye/dye_costume.dds",
            [COLLECTIBLE_CATEGORY_TYPE_HAT] = "EsoUI/Art/Dye/dye_hat.dds",
        },
        [RESTYLE_MODE_OUTFIT] =
        {
            [OUTFIT_SLOT_HEAD] = "EsoUI/Art/CharacterWindow/gearSlot_head.dds",
            [OUTFIT_SLOT_CHEST] = "EsoUI/Art/CharacterWindow/gearSlot_chest.dds",
            [OUTFIT_SLOT_SHOULDERS] = "EsoUI/Art/CharacterWindow/gearSlot_shoulders.dds",
            [OUTFIT_SLOT_WAIST] = "EsoUI/Art/CharacterWindow/gearSlot_belt.dds",
            [OUTFIT_SLOT_LEGS] = "EsoUI/Art/CharacterWindow/gearSlot_legs.dds",
            [OUTFIT_SLOT_FEET] = "EsoUI/Art/CharacterWindow/gearSlot_feet.dds",
            [OUTFIT_SLOT_HANDS] = "EsoUI/Art/CharacterWindow/gearSlot_hands.dds",
            [OUTFIT_SLOT_WEAPON_MAIN_HAND] = "EsoUI/Art/Dye/outfitSlot_mainHand.dds",
            [OUTFIT_SLOT_WEAPON_OFF_HAND] = "EsoUI/Art/Dye/outfitSlot_offHand.dds",
            [OUTFIT_SLOT_WEAPON_TWO_HANDED] = "EsoUI/Art/Dye/outfitSlot_twoHanded.dds",
            [OUTFIT_SLOT_WEAPON_STAFF] = "EsoUI/Art/Dye/outfitSlot_staff.dds",
            [OUTFIT_SLOT_WEAPON_BOW] = "EsoUI/Art/Dye/outfitSlot_bow.dds",
            [OUTFIT_SLOT_SHIELD] = "EsoUI/Art/Dye/outfitSlot_shield.dds",
            [OUTFIT_SLOT_WEAPON_MAIN_HAND_BACKUP] = "EsoUI/Art/Dye/outfitSlot_mainHand.dds",
            [OUTFIT_SLOT_WEAPON_OFF_HAND_BACKUP] = "EsoUI/Art/Dye/outfitSlot_offHand.dds",
            [OUTFIT_SLOT_WEAPON_TWO_HANDED_BACKUP] = "EsoUI/Art/Dye/outfitSlot_twoHanded.dds",
            [OUTFIT_SLOT_WEAPON_STAFF_BACKUP] = "EsoUI/Art/Dye/outfitSlot_staff.dds",
            [OUTFIT_SLOT_WEAPON_BOW_BACKUP] = "EsoUI/Art/Dye/outfitSlot_bow.dds",
            [OUTFIT_SLOT_SHIELD_BACKUP] = "EsoUI/Art/Dye/outfitSlot_shield.dds",
        },
        [RESTYLE_MODE_COMPANION_EQUIPMENT] =
        {
            [EQUIP_SLOT_HEAD] = "EsoUI/Art/CharacterWindow/gearSlot_head.dds",
            [EQUIP_SLOT_CHEST] = "EsoUI/Art/CharacterWindow/gearSlot_chest.dds",
            [EQUIP_SLOT_SHOULDERS] = "EsoUI/Art/CharacterWindow/gearSlot_shoulders.dds",
            [EQUIP_SLOT_OFF_HAND] = "EsoUI/Art/CharacterWindow/gearSlot_offHand.dds",
            [EQUIP_SLOT_WAIST] = "EsoUI/Art/CharacterWindow/gearSlot_belt.dds",
            [EQUIP_SLOT_LEGS] = "EsoUI/Art/CharacterWindow/gearSlot_legs.dds",
            [EQUIP_SLOT_FEET] = "EsoUI/Art/CharacterWindow/gearSlot_feet.dds",
            [EQUIP_SLOT_HAND] = "EsoUI/Art/CharacterWindow/gearSlot_hands.dds",
        },
        [RESTYLE_MODE_COMPANION_COLLECTIBLE] =
        {
            [COLLECTIBLE_CATEGORY_TYPE_COSTUME] = "EsoUI/Art/Dye/dye_costume.dds",
        },
        [RESTYLE_MODE_COMPANION_OUTFIT] =
        {
            [OUTFIT_SLOT_HEAD] = "EsoUI/Art/CharacterWindow/gearSlot_head.dds",
            [OUTFIT_SLOT_CHEST] = "EsoUI/Art/CharacterWindow/gearSlot_chest.dds",
            [OUTFIT_SLOT_SHOULDERS] = "EsoUI/Art/CharacterWindow/gearSlot_shoulders.dds",
            [OUTFIT_SLOT_WAIST] = "EsoUI/Art/CharacterWindow/gearSlot_belt.dds",
            [OUTFIT_SLOT_LEGS] = "EsoUI/Art/CharacterWindow/gearSlot_legs.dds",
            [OUTFIT_SLOT_FEET] = "EsoUI/Art/CharacterWindow/gearSlot_feet.dds",
            [OUTFIT_SLOT_HANDS] = "EsoUI/Art/CharacterWindow/gearSlot_hands.dds",
            [OUTFIT_SLOT_WEAPON_MAIN_HAND] = "EsoUI/Art/Dye/outfitSlot_mainHand.dds",
            [OUTFIT_SLOT_WEAPON_OFF_HAND] = "EsoUI/Art/Dye/outfitSlot_offHand.dds",
            [OUTFIT_SLOT_WEAPON_TWO_HANDED] = "EsoUI/Art/Dye/outfitSlot_twoHanded.dds",
            [OUTFIT_SLOT_WEAPON_STAFF] = "EsoUI/Art/Dye/outfitSlot_staff.dds",
            [OUTFIT_SLOT_WEAPON_BOW] = "EsoUI/Art/Dye/outfitSlot_bow.dds",
            [OUTFIT_SLOT_SHIELD] = "EsoUI/Art/Dye/outfitSlot_shield.dds",
        },
    }

    function ZO_Restyle_GetEmptySlotTexture(restyleSlotData)
        local restyleMode = restyleSlotData:GetRestyleMode()
        if RESTYLE_SLOT_TEXTURES[restyleMode] then
            return RESTYLE_SLOT_TEXTURES[restyleMode][restyleSlotData:GetRestyleSlotType()]
        end
    end
end

do
    local OUTFIT_SLOT_CLEAR_TEXTURES = 
    {
        [OUTFIT_SLOT_HEAD] = "EsoUI/Art/Restyle/gearSlot_head_remove.dds",
        [OUTFIT_SLOT_CHEST] = "EsoUI/Art/Restyle/gearSlot_chest_remove.dds",
        [OUTFIT_SLOT_SHOULDERS] = "EsoUI/Art/Restyle/gearSlot_shoulders_remove.dds",
        [OUTFIT_SLOT_WAIST] = "EsoUI/Art/Restyle/gearSlot_belt_remove.dds",
        [OUTFIT_SLOT_LEGS] = "EsoUI/Art/Restyle/gearSlot_legs_remove.dds",
        [OUTFIT_SLOT_FEET] = "EsoUI/Art/Restyle/gearSlot_feet_remove.dds",
        [OUTFIT_SLOT_HANDS] = "EsoUI/Art/Restyle/gearSlot_hands_remove.dds",
        [OUTFIT_SLOT_WEAPON_MAIN_HAND] = "EsoUI/Art/Restyle/outfitSlot_mainHand_remove.dds",
        [OUTFIT_SLOT_WEAPON_OFF_HAND] = "EsoUI/Art/Restyle/outfitSlot_OffHand_remove.dds",
        [OUTFIT_SLOT_WEAPON_TWO_HANDED] = "EsoUI/Art/Restyle/outfitSlot_twoHanded_remove.dds",
        [OUTFIT_SLOT_WEAPON_STAFF] = "EsoUI/Art/Restyle/outfitSlot_staff_remove.dds",
        [OUTFIT_SLOT_WEAPON_BOW] = "EsoUI/Art/Restyle/outfitSlot_bow_remove.dds",
        [OUTFIT_SLOT_SHIELD] = "EsoUI/Art/Restyle/gearSlot_offHand_remove.dds",
        [OUTFIT_SLOT_WEAPON_MAIN_HAND_BACKUP] = "EsoUI/Art/Restyle/outfitSlot_mainHand_remove.dds",
        [OUTFIT_SLOT_WEAPON_OFF_HAND_BACKUP] = "EsoUI/Art/Restyle/outfitSlot_OffHand_remove.dds",
        [OUTFIT_SLOT_WEAPON_TWO_HANDED_BACKUP] = "EsoUI/Art/Restyle/outfitSlot_twoHanded_remove.dds",
        [OUTFIT_SLOT_WEAPON_STAFF_BACKUP] = "EsoUI/Art/Restyle/outfitSlot_staff_remove.dds",
        [OUTFIT_SLOT_WEAPON_BOW_BACKUP] = "EsoUI/Art/Restyle/outfitSlot_bow_remove.dds",
        [OUTFIT_SLOT_SHIELD_BACKUP] = "EsoUI/Art/Restyle/gearSlot_offHand_remove.dds",
    }

    function ZO_Restyle_GetOutfitSlotClearTexture(outfitSlot)
        return OUTFIT_SLOT_CLEAR_TEXTURES[outfitSlot]
    end
end

function ZO_Restyle_GetActiveOffhandEquipSlotType()
    local activeWeaponPair = GetActiveWeaponPairInfo()
    if activeWeaponPair == ACTIVE_WEAPON_PAIR_BACKUP then
        return EQUIP_SLOT_BACKUP_OFF
    end

    return EQUIP_SLOT_OFF_HAND
end

function ZO_Restyle_GetOppositeOffHandEquipSlotType()
    local activeWeaponPair = GetActiveWeaponPairInfo()
    if activeWeaponPair == ACTIVE_WEAPON_PAIR_MAIN then
        return EQUIP_SLOT_BACKUP_OFF
    end

    return EQUIP_SLOT_OFF_HAND
end

function ZO_RestyleCanApplyChanges()
    return GetInteractionType() == INTERACTION_DYE_STATION
end

----------------------------------------
-- Restyle Slot Data Struct Interface --
----------------------------------------

--This allows us to pass the slot data around easily and call the LuaToC apis without needing so many params
--These object should do nothing more complicated than allow a throughway to APIs for a given set of slot parameters

ZO_RestyleSlotData = ZO_InitializingObject:Subclass()

function ZO_RestyleSlotData:Copy(other)
    local object = ZO_Object.New(self)
    object:Initialize(other:GetRestyleMode(), other:GetRestyleSetIndex(), other:GetRestyleSlotType())
    return object
end

function ZO_RestyleSlotData:Initialize(restyleMode, restyleSetIndex, restyleSlotType)
    self.restyleMode = restyleMode
    self.restyleSetIndex = restyleSetIndex
    self.restyleSlotType = restyleSlotType
    self.sortOrder = 0
end

function ZO_RestyleSlotData:GetSortOrder()
    return self.sortOrder
end

function ZO_RestyleSlotData:SetSortOrder(sortOrder)
    self.sortOrder = sortOrder
end

function ZO_RestyleSlotData:GetRestyleMode()
    return self.restyleMode
end

function ZO_RestyleSlotData:SetRestyleMode(restyleMode)
    self.restyleMode = restyleMode
end

function ZO_RestyleSlotData:GetRestyleSetIndex()
    return self.restyleSetIndex
end

function ZO_RestyleSlotData:SetRestyleSetIndex(restyleSetIndex)
    self.restyleSetIndex = restyleSetIndex
end

function ZO_RestyleSlotData:GetRestyleSlotType()
    return self.restyleSlotType
end

function ZO_RestyleSlotData:SetRestyleSlotType(restyleSlotType)
    self.restyleSlotType = restyleSlotType
end

function ZO_RestyleSlotData:GetData()
    return self.restyleMode, self.restyleSetIndex, self.restyleSlotType
end

function ZO_RestyleSlotData:GetId()
    return GetRestyleSlotId(self.restyleMode, self.restyleSetIndex, self.restyleSlotType)
end

function ZO_RestyleSlotData:GetIcon()
    local iconFile = GetRestyleSlotIcon(self.restyleMode, self.restyleSetIndex, self.restyleSlotType)
    if iconFile == ZO_NO_TEXTURE_FILE then
        iconFile = ZO_Restyle_GetEmptySlotTexture(self)
    end
    return iconFile
end

function ZO_RestyleSlotData:IsDataDyeable()
    return IsRestyleSlotDataDyeable(self.restyleMode, self.restyleSetIndex, self.restyleSlotType)
end

function ZO_RestyleSlotData:AreDyeChannelsDyeable()
    if self:IsOutfitSlot() then
        local outfitSlotManipulator = ZO_OUTFIT_MANAGER:GetOutfitSlotManipulatorFromRestyleSlotData(self)
        local collectibleId = outfitSlotManipulator:GetPendingCollectibleId()
        return AreDyeChannelsDyeableForOutfitSlotData(outfitSlotManipulator.owner:GetActorCategory(), self.restyleSlotType, collectibleId)
    else
        return AreRestyleSlotDyeChannelsDyeable(self.restyleMode, self.restyleSetIndex, self.restyleSlotType)
    end
end

function ZO_RestyleSlotData:GetDyeData()
    return GetRestyleSlotDyeData(self.restyleMode, self.restyleSetIndex, self.restyleSlotType)
end

function ZO_RestyleSlotData:GetCurrentDyes()
    return GetRestyleSlotCurrentDyes(self.restyleMode, self.restyleSetIndex, self.restyleSlotType)
end

function ZO_RestyleSlotData:GetPendingDyes()
    return GetPendingSlotDyes(self.restyleMode, self.restyleSetIndex, self.restyleSlotType)
end

function ZO_RestyleSlotData:SetPendingDyes(primaryDyeId, secondaryDyeId, accentDyeId)
    local dyeableChannels = { self:AreDyeChannelsDyeable() }
    local currentDyes = { self:GetCurrentDyes() }
    local desiredDyes = { primaryDyeId, secondaryDyeId, accentDyeId }
    for channel, dyeable in ipairs(dyeableChannels) do
        if not dyeable then
            desiredDyes[channel] = currentDyes[channel]
        end
    end
    SetPendingSlotDyes(self.restyleMode, self.restyleSetIndex, self.restyleSlotType, unpack(desiredDyes))
    ApplyChangesToPreviewCollectionShown(PREVIEW_OPTION_DONT_UNSHEATHE_IF_WIELDING)
end

function ZO_RestyleSlotData:CleanPendingDyes()
    local dyeableChannels = { self:AreDyeChannelsDyeable() }
    local currentDyes = { self:GetCurrentDyes() }
    local pendingDyes = { self:GetPendingDyes() }
    local isDirty = false
    for channel, dyeable in ipairs(dyeableChannels) do
        if not dyeable and currentDyes[channel] ~= pendingDyes[channel] then
            pendingDyes[channel] = currentDyes[channel]
            isDirty = true
        end
    end
    if isDirty then
        SetPendingSlotDyes(self.restyleMode, self.restyleSetIndex, self.restyleSlotType, unpack(pendingDyes))
    end
end

function ZO_RestyleSlotData:AreTherePendingDyeChanges()
    local currentDyes = { self:GetCurrentDyes() }
    local pendingDyes = { self:GetPendingDyes() }
    for i, currentDye in ipairs(currentDyes) do
        if currentDye ~= pendingDyes[i] then
            return true
        end
    end

    return false
end

function ZO_RestyleSlotData:GetDyeChannelChangedStates()
    local currentDyes = { self:GetCurrentDyes() }
    local pendingDyes = { self:GetPendingDyes() }
    local changedChannels = {}
    for i, currentDye in ipairs(currentDyes) do
        table.insert(changedChannels, currentDye ~= pendingDyes[i])
    end

    return changedChannels
end

function ZO_RestyleSlotData:ShouldBeHidden()
    local restyleSlotType = self.restyleSlotType
    if self:IsOutfitSlot() then
        if ZO_OUTFIT_MANAGER:IsOutfitSlotWeapon(restyleSlotType) then
            local actorCategory = ZO_OUTFIT_MANAGER.GetActorCategoryByRestyleMode(self.restyleMode)
            return not ZO_OUTFIT_MANAGER:IsWeaponOutfitSlotCurrentlyEquipped(restyleSlotType, actorCategory)
        end
    end
    return false
end

function ZO_RestyleSlotData:IsEquipment()
    return self.restyleMode == RESTYLE_MODE_EQUIPMENT or self.restyleMode == RESTYLE_MODE_COMPANION_EQUIPMENT
end

function ZO_RestyleSlotData:IsCollectible()
    return self.restyleMode == RESTYLE_MODE_COLLECTIBLE or self.restyleMode == RESTYLE_MODE_COMPANION_COLLECTIBLE
end

function ZO_RestyleSlotData:IsOutfitSlot()
    return self.restyleMode == RESTYLE_MODE_OUTFIT or self.restyleMode == RESTYLE_MODE_COMPANION_OUTFIT
end

function ZO_RestyleSlotData:IsOutfitStyle()
    if self:IsOutfitSlot() then
        return ZO_OUTFIT_MANAGER:IsOutfitSlotWeapon(self.restyleSlotType) or ZO_OUTFIT_MANAGER:IsOutfitSlotArmor(self.restyleSlotType)
    end
    return false
end

function ZO_RestyleSlotData:GetCurrentCollectibleData()
    if self:IsOutfitSlot() then
        local outfitSlotManipulator = ZO_OUTFIT_MANAGER:GetOutfitSlotManipulatorFromRestyleSlotData(self)
        local collectibleId = outfitSlotManipulator:GetCurrentCollectibleId()
        return ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
    elseif self:IsCollectible() then
        return ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(self:GetId())
    end
end

function ZO_RestyleSlotData:GetPendingCollectibleData()
    if self:IsOutfitSlot() then
        local outfitSlotManipulator = ZO_OUTFIT_MANAGER:GetOutfitSlotManipulatorFromRestyleSlotData(self)
        local collectibleId = outfitSlotManipulator:GetPendingCollectibleId()
        return ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
    elseif self:IsCollectible() then
        return ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(self:GetId())
    end
end

function ZO_RestyleSlotData:GetCollectibleCategoryData()
    if self:IsOutfitSlot() then
        local categoryId = GetOutfitSlotDataCollectibleCategoryId(self.restyleSlotType)
        return ZO_COLLECTIBLE_DATA_MANAGER:GetCategoryDataById(categoryId)
    elseif self:IsCollectible() then
        local collectibleId = self:GetId()
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
        return collectibleData and collectibleData:GetCategoryData()
    end
end

function ZO_RestyleSlotData:GetClearIcon()
    if self:IsOutfitSlot() then
        return ZO_Restyle_GetOutfitSlotClearTexture(self.restyleSlotType)
    end
    return nil
end

function ZO_RestyleSlotData:Equals(other)
    return self.restyleMode == other:GetRestyleMode() and self.restyleSetIndex == other:GetRestyleSetIndex() and self.restyleSlotType == other:GetRestyleSlotType()
end

do
    local RESTYLE_SLOT_TYPE_STRING_PREFIXES =
    {
        [RESTYLE_MODE_EQUIPMENT] = "SI_EQUIPSLOT",
        [RESTYLE_MODE_COLLECTIBLE] = "SI_COLLECTIBLECATEGORYTYPE",
        [RESTYLE_MODE_OUTFIT] = "SI_OUTFITSLOT",
        [RESTYLE_MODE_COMPANION_EQUIPMENT] = "SI_EQUIPSLOT",
        [RESTYLE_MODE_COMPANION_COLLECTIBLE] = "SI_COLLECTIBLECATEGORYTYPE",
        [RESTYLE_MODE_COMPANION_OUTFIT] = "SI_OUTFITSLOT",
    }

    function ZO_RestyleSlotData:GetDefaultDescriptor()
        return GetString(RESTYLE_SLOT_TYPE_STRING_PREFIXES[self:GetRestyleMode()], self:GetRestyleSlotType())
    end
end