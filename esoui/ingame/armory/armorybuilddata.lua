
-- Armory Build Data --
ZO_ArmoryBuildData = ZO_InitializingObject:Subclass()

function ZO_ArmoryBuildData:Initialize(buildIndex)
    self.buildIndex = buildIndex
end

function ZO_ArmoryBuildData:GetBuildIndex()
    return self.buildIndex
end

function ZO_ArmoryBuildData:SetName(buildName)
    if buildName ~= self:GetName() then
        SetArmoryBuildName(self.buildIndex, buildName)
    end
end

function ZO_ArmoryBuildData:GetName()
    local buildName = GetArmoryBuildName(self.buildIndex)
    if buildName == "" then
        return ZO_CachedStrFormat(SI_ARMORY_BUILD_DEFAULT_NAME_FORMATTER, self.buildIndex)
    else
        return buildName
    end
end

function ZO_ArmoryBuildData:GetIcon()
    return ZO_ARMORY_MANAGER:GetBuildIcon(self:GetIconIndex())
end

function ZO_ArmoryBuildData:SetIconIndex(iconIndex)
    SetArmoryBuildIconIndex(self.buildIndex, iconIndex)
end

function ZO_ArmoryBuildData:GetIconIndex()
    return GetArmoryBuildIconIndex(self.buildIndex)
end

function ZO_ArmoryBuildData:GetAttributeSpentPoints(attributeType)
    return GetArmoryBuildAttributeSpentPoints(self.buildIndex, attributeType)
end

function ZO_ArmoryBuildData:GetSkillsTotalSpentPoints()
    return GetArmoryBuildSkillsTotalSpentPoints(self.buildIndex)
end

function ZO_ArmoryBuildData:GetChampionSpentPointsByDiscipline(disciplineId)
    return GetArmoryBuildChampionSpentPointsByDiscipline(self.buildIndex, disciplineId)
end

function ZO_ArmoryBuildData:GetChampionTotalSpentPoints()
    local totalSpentPoints = 0
    for i = 1, GetNumChampionDisciplines() do
        local disciplineId = GetChampionDisciplineId(i)
        totalSpentPoints = totalSpentPoints + self:GetChampionSpentPointsByDiscipline(disciplineId)
    end
    return totalSpentPoints
end

function ZO_ArmoryBuildData:GetSlottedChampionSkillId(slotIndex)
    return GetArmoryBuildSlotBoundId(self.buildIndex, slotIndex, HOTBAR_CATEGORY_CHAMPION)
end

function ZO_ArmoryBuildData:GetSlottedAbilityId(slotIndex, hotbarCategory)
    return GetArmoryBuildSlotBoundId(self.buildIndex, slotIndex, hotbarCategory)
end

function ZO_ArmoryBuildData:GetEquippedOutfitName()
    local equippedOutfitIndex = GetArmoryBuildEquippedOutfitIndex(self.buildIndex)
    if equippedOutfitIndex then
        local outfitManipulator = ZO_OUTFIT_MANAGER:GetOutfitManipulator(GAMEPLAY_ACTOR_CATEGORY_PLAYER, equippedOutfitIndex)
        if outfitManipulator then
            return outfitManipulator:GetOutfitName()
        else
            return GetString(SI_NO_OUTFIT_EQUIP_ENTRY)
        end
    else
        return GetString(SI_NO_OUTFIT_EQUIP_ENTRY)
    end
end

function ZO_ArmoryBuildData:GetCurseType()
    return GetArmoryBuildCurseType(self.buildIndex)
end

function ZO_ArmoryBuildData:GetPrimaryMundusStone()
    return GetArmoryBuildPrimaryMundusStone(self.buildIndex)
end

function ZO_ArmoryBuildData:GetSecondaryMundusStone()
    return GetArmoryBuildSecondaryMundusStone(self.buildIndex)
end

function ZO_ArmoryBuildData:GetEquippedMundusStoneNames()
    local primaryMundus = GetArmoryBuildPrimaryMundusStone(self.buildIndex)
    local secondaryMundus = GetArmoryBuildSecondaryMundusStone(self.buildIndex)
    if primaryMundus == MUNDUS_STONE_INVALID or secondaryMundus == MUNDUS_STONE_INVALID then
        --We will never have a secondary mundus stone if the primary mundus stone is invalid, so we can just return the primary mundus if either are invalid
        return { GetString("SI_MUNDUSSTONE", primaryMundus) }
    else
        return { GetString("SI_MUNDUSSTONE", primaryMundus), GetString("SI_MUNDUSSTONE", secondaryMundus) }
    end
end

do
    local INACCESSIBLE_BAGS =
    {
        [BAG_BANK] = true,
        [BAG_HOUSE_BANK_ONE] = true,
        [BAG_HOUSE_BANK_TWO] = true,
        [BAG_HOUSE_BANK_THREE] = true,
        [BAG_HOUSE_BANK_FOUR] = true,
        [BAG_HOUSE_BANK_FIVE] = true,
        [BAG_HOUSE_BANK_SIX] = true,
        [BAG_HOUSE_BANK_SEVEN] = true,
        [BAG_HOUSE_BANK_EIGHT] = true,
        [BAG_HOUSE_BANK_NINE] = true,
        [BAG_HOUSE_BANK_TEN] = true,
    }

    function ZO_ArmoryBuildData:GetEquipSlotInfo(equipSlot)
        local slotState, bagId, slotIndex = GetArmoryBuildEquipSlotInfo(self.buildIndex, equipSlot)
        --If the bag is inaccessible from the armory, pretend it is missing
        if slotState == ARMORY_BUILD_EQUIP_SLOT_STATE_VALID and INACCESSIBLE_BAGS[bagId] then
            slotState = ARMORY_BUILD_EQUIP_SLOT_STATE_INACCESSIBLE
        end
        return slotState, bagId, slotIndex
    end
end

function ZO_ArmoryBuildData:GetEquipSlotItemLinkInfo(equipSlot)
    local slotState, bagId, slotIndex = self:GetEquipSlotInfo(equipSlot)
    if slotState == ARMORY_BUILD_EQUIP_SLOT_STATE_VALID then
        return slotState, GetItemLink(bagId, slotIndex)
    else
        return slotState, ""
    end
end