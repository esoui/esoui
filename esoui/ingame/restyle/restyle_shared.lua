-----------------------------
-- Global Helper Functions --
-----------------------------

ZO_RESTYLE_DEFAULT_SET_INDEX = 1

ZO_RESTYLE_SLOT_TYPE_STRING_PREFIXES =
{
    [RESTYLE_MODE_EQUIPMENT] = "SI_EQUIPSLOT",
    [RESTYLE_MODE_COLLECTIBLE] = "SI_COLLECTIBLECATEGORYTYPE",
}

function ZO_GetRestyleSlotTypeDefaultDescriptor(restyleSlotData)
    return GetString(ZO_RESTYLE_SLOT_TYPE_STRING_PREFIXES[restyleSlotData:GetRestyleMode()], restyleSlotData:GetRestyleSlotType())
end

do
    local STACK_COUNT = 1

    function ZO_Restyle_SetupSlotControl(control, restyleSlotData)
        local icon = restyleSlotData:GetIcon()
        if icon == ZO_NO_TEXTURE_FILE then
            icon = ZO_Restyle_GetEmptySlotTexture(restyleSlotData)
        end

        if restyleSlotData:IsEquipment() then
            ZO_Inventory_BindSlot(control, SLOT_TYPE_DYEABLE_EQUIPMENT, restyleSlotData:GetRestyleSlotType(), BAG_WORN)
        end

        control.restyleSlotData = restyleSlotData

        ZO_ItemSlot_SetupSlot(control, STACK_COUNT, icon)
    end
end

ZO_RESTYLE_SLOT_TEXTURES =
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
}

function ZO_Restyle_GetEmptySlotTexture(restyleSlotData)
    local restyleMode = restyleSlotData:GetRestyleMode()
    if ZO_RESTYLE_SLOT_TEXTURES[restyleMode] then
        return ZO_RESTYLE_SLOT_TEXTURES[restyleMode][restyleSlotData:GetRestyleSlotType()]
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

----------------------------------------
-- Restyle Slot Data Struct Interface --
----------------------------------------

--This allows us to pass the slot data around easily and call the LuaToC apis without needing so many params
--These object should do nothing more complicated than allow a throughway to APIs for a given set of slot parameters

ZO_RestyleSlotData = ZO_Object:Subclass()

function ZO_RestyleSlotData:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

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
    return GetRestyleSlotIcon(self.restyleMode, self.restyleSetIndex, self.restyleSlotType)
end

function ZO_RestyleSlotData:IsDataDyeable()
    return IsRestyleSlotDataDyeable(self.restyleMode, self.restyleSetIndex, self.restyleSlotType)
end

function ZO_RestyleSlotData:AreDyeChannelsDyeable()
    return AreRestyleSlotDyeChannelsDyeable(self.restyleMode, self.restyleSetIndex, self.restyleSlotType)
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
    SetPendingSlotDyes(self.restyleMode, self.restyleSetIndex, self.restyleSlotType, primaryDyeId, secondaryDyeId, accentDyeId)
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

function ZO_RestyleSlotData:ShouldBeHidden()
    if self:IsEquipment() then
        local restyleSlotType = self.restyleSlotType
        local activeOffhandEquipSlot = ZO_Restyle_GetActiveOffhandEquipSlotType()
        local isOffHand = restyleSlotType == EQUIP_SLOT_OFF_HAND or restyleSlotType == EQUIP_SLOT_BACKUP_OFF
        return isOffhand and activeOffhandEquipSlot ~= restyleSlotType
    end
    return false
end

function ZO_RestyleSlotData:IsEquipment()
    return self.restyleMode == RESTYLE_MODE_EQUIPMENT
end

function ZO_RestyleSlotData:IsCollectible()
    return self.restyleMode == RESTYLE_MODE_COLLECTIBLE
end