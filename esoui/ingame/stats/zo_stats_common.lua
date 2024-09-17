-------------------
-- General Stats --
-------------------

STAT_TYPES =
{
    [ATTRIBUTE_HEALTH] = STAT_HEALTH_MAX,
    [ATTRIBUTE_MAGICKA] = STAT_MAGICKA_MAX,
    [ATTRIBUTE_STAMINA] = STAT_STAMINA_MAX,
}

ZO_STAT_TOOLTIP_DESCRIPTIONS = 
{
    [STAT_HEALTH_MAX] = SI_STAT_TOOLTIP_HEALTH_MAX,
    [STAT_HEALTH_REGEN_IDLE] = SI_STAT_TOOLTIP_HEALTH_REGENERATION_IDLE,
    [STAT_HEALTH_REGEN_COMBAT] = SI_STAT_TOOLTIP_HEALTH_REGENERATION_COMBAT,
    [STAT_MAGICKA_MAX] = SI_STAT_TOOLTIP_MAGICKA_MAX,
    [STAT_MAGICKA_REGEN_IDLE] = SI_STAT_TOOLTIP_MAGICKA_REGENERATION_IDLE,
    [STAT_MAGICKA_REGEN_COMBAT] = SI_STAT_TOOLTIP_MAGICKA_REGENERATION_COMBAT,
    [STAT_STAMINA_MAX] = SI_STAT_TOOLTIP_STAMINA_MAX,
    [STAT_STAMINA_REGEN_IDLE] = SI_STAT_TOOLTIP_STAMINA_REGENERATION_IDLE,
    [STAT_STAMINA_REGEN_COMBAT] = SI_STAT_TOOLTIP_STAMINA_REGENERATION_COMBAT,
    [STAT_SPELL_POWER] = SI_STAT_TOOLTIP_SPELL_POWER,
    [STAT_SPELL_PENETRATION] = SI_STAT_TOOLTIP_SPELL_PENETRATION,
    [STAT_SPELL_CRITICAL] = SI_STAT_TOOLTIP_SPELL_CRITICAL,
    [STAT_ATTACK_POWER] = SI_STAT_TOOLTIP_ATTACK_POWER,
    [STAT_PHYSICAL_PENETRATION] = SI_STAT_TOOLTIP_PHYSICAL_PENETRATION,
    [STAT_CRITICAL_STRIKE] = SI_STAT_TOOLTIP_CRITICAL_STRIKE,
    [STAT_PHYSICAL_RESIST] = SI_STAT_TOOLTIP_PHYSICAL_RESIST,
    [STAT_SPELL_RESIST] = SI_STAT_TOOLTIP_SPELL_RESIST,
    [STAT_CRITICAL_RESISTANCE] = SI_STAT_TOOLTIP_CRITICAL_RESISTANCE,
    [STAT_POWER] = SI_STAT_TOOLTIP_POWER,
    [STAT_MITIGATION] = SI_STAT_TOOLTIP_MITIGATION,
    [STAT_SPELL_MITIGATION] = SI_STAT_TOOLTIP_SPELL_MITIGATION,
    [STAT_ARMOR_RATING] = SI_STAT_TOOLTIP_ARMOR_RATING,
    [STAT_WEAPON_AND_SPELL_DAMAGE] = SI_STAT_TOOLTIP_WEAPON_POWER,
}

ZO_STATS_REFRESH_TIME_SECONDS = 2

function ZO_GetNextActiveArtificialEffectIdIter(state, lastActiveEffectId)
    return GetNextActiveArtificialEffectId(lastActiveEffectId)
end

-- respec attribute interaction info
ZO_ATTRIBUTE_RESPEC_INTERACT_INFO =
{
    type = "Attribute Respec Shrine",
    OnInteractSwitch = function()
        internalassert(false, "OnInteractSwitch is being called.")
        SCENE_MANAGER:ShowBaseScene()
    end,
    interactTypes = { INTERACTION_ATTRIBUTE_RESPEC },
}

------------------
-- Stats Common --
------------------

ZO_Stats_Common = ZO_InitializingCallbackObject:Subclass()

function ZO_Stats_Common:Initialize(control)
    self.control = control

    self.availablePoints = 0
    self.statBonuses = {}

    self.attributePointAllocationMode = ATTRIBUTE_POINT_ALLOCATION_MODE_PURCHASE_ONLY
    self.attributeRespecPaymentType = RESPEC_PAYMENT_TYPE_GOLD

    self.control:RegisterForEvent(EVENT_START_ATTRIBUTE_RESPEC, function(_, ...) self:OnStartAttributeRespec(...) end)
end

function ZO_Stats_Common:GetAttributePointAllocationMode()
    return self.attributePointAllocationMode
end

function ZO_Stats_Common:SetAttributePointAllocationMode(attributePointAllocationMode)
    if attributePointAllocationMode ~= self.attributePointAllocationMode then
        local oldAttributePointAllocationMode = self.attributePointAllocationMode
        self.attributePointAllocationMode = attributePointAllocationMode
        self:FireCallbacks("AttributePointAllocationModeChanged", attributePointAllocationMode, oldAttributePointAllocationMode)
    end
end

function ZO_Stats_Common:GetAttributeRespecPaymentType()
    return self.attributeRespecPaymentType
end

function ZO_Stats_Common:SetAttributeRespecPaymentType(attributeRespecPaymentType)
    if attributeRespecPaymentType ~= self.attributeRespecPaymentType then
        local oldAttributeRespecPaymentType = self.attributeRespecPaymentType
        self.attributeRespecPaymentType = attributeRespecPaymentType
        self:FireCallbacks("AttributeRespecPaymentTypeChanged", attributeRespecPaymentType, oldAttributeRespecPaymentType)
    end
end

function ZO_Stats_Common:DoesAttributePointAllocationModeAllowDecrease()
    return self.attributePointAllocationMode ~= ATTRIBUTE_POINT_ALLOCATION_MODE_PURCHASE_ONLY
end

function ZO_Stats_Common:DoesAttributePointAllocationModeBatchSave()
    return self.attributePointAllocationMode ~= ATTRIBUTE_POINT_ALLOCATION_MODE_PURCHASE_ONLY
end

function ZO_Stats_Common:IsPaymentTypeScroll()
    return self.attributeRespecPaymentType == RESPEC_PAYMENT_TYPE_RESPEC_SCROLL
end

function ZO_Stats_Common:OnStartAttributeRespec(allocationMode, paymentType)
    self:SetAttributeRespecPaymentType(paymentType)
    self:SetAttributePointAllocationMode(allocationMode)
    if IsInGamepadPreferredMode() then
        SCENE_MANAGER:Push("gamepad_stats_root")
        GAMEPAD_STATS:SelectAttributes()
    else
        SCENE_MANAGER:Push("stats")
    end
end

function ZO_Stats_Common:GetAvailablePoints()
    return self.availablePoints
end

function ZO_Stats_Common:SetAvailablePoints(points)
    self.availablePoints = points

    self:OnSetAvailablePoints()
end

function ZO_Stats_Common:OnSetAvailablePoints()
    -- To be overridden.
end

function ZO_Stats_Common:SpendAvailablePoints(points)
    self:SetAvailablePoints(self:GetAvailablePoints() - points)
end

function ZO_Stats_Common:GetTotalSpendablePoints()
    return GetAttributeUnspentPoints()
end

function ZO_Stats_Common:SetPendingStatBonuses(statType, pendingBonus)
    self.statBonuses[statType] = pendingBonus
end

function ZO_Stats_Common:UpdatePendingStatBonuses(statType, pendingBonus)
    self:SetPendingStatBonuses(statType, pendingBonus)
end

function ZO_Stats_Common:GetPendingStatBonuses(statType)
    return self.statBonuses[statType]
end

function ZO_Stats_Common:GetDropdownTitleIndex(dropdown)
    local currentTitleIndex = GetCurrentTitleIndex()
    if currentTitleIndex == nil then
        return 1
    end
    local function IsItemCurrentTitle(item)
        return item.titleInfo and item.titleInfo.index == currentTitleIndex
    end
    return dropdown:GetIndexByEval(IsItemCurrentTitle)
end

function ZO_Stats_Common:UpdateTitleDropdownSelection(dropdown)
    local dropdownTitleIndex = self:GetDropdownTitleIndex(dropdown)
    if dropdownTitleIndex then
        dropdown:SelectItemByIndex(dropdownTitleIndex, ZO_COMBOBOX_SUPPRESS_UPDATE)
    else
        dropdown:SelectItemByIndex(1, ZO_COMBOBOX_SUPPRESS_UPDATE)
    end
end

function ZO_Stats_Common:UpdateTitleDropdownTitles(dropdown)
    dropdown:ClearItems()
     -- First add the none item into the start of the dropdown list 
    dropdown:AddItem(dropdown:CreateItemEntry(GetString(SI_STATS_NO_TITLE), function() SelectTitle(nil) end), ZO_COMBOBOX_SUPPRESS_UPDATE)

    local sortedTitles = TITLE_MANAGER:GetSortedTitles(dropdown.m_sortType, dropdown.m_sortOrder)
    for _, titleInfo in ipairs(sortedTitles) do
        local titleName = titleInfo.name

        if titleInfo.isNew then
            titleName = zo_iconTextFormat("EsoUI/Art/Inventory/newItem_icon.dds", "100%", "100%", titleName)
        end

        local titleListItem = dropdown:CreateItemEntry(zo_strformat(titleName, GetRawUnitName("player")), function() SelectTitle(titleInfo.index) end)
        titleListItem.titleInfo = titleInfo
        dropdown:AddItem(titleListItem, ZO_COMBOBOX_SUPPRESS_UPDATE)
    end 

    dropdown:UpdateItems()

    self:UpdateTitleDropdownSelection(dropdown)
end

function ZO_Stats_Common:IsPlayerBattleLeveled()
    return IsUnitChampionBattleLeveled("player") or IsUnitBattleLeveled("player")
end

function ZO_Stats_Common:GetEquipmentBonusInfo()
    return self.equipmentBonus.value, self.equipmentBonus.lowestEquipSlot
end

do
    --to break ties for the player's lowest scoring piece of equipment and show the most important piece
    local COMBAT_EQUIP_SLOT_IMPORTANCE =
    {
        [EQUIP_SLOT_MAIN_HAND]      = 12,
        [EQUIP_SLOT_BACKUP_MAIN]    = 12,
        [EQUIP_SLOT_OFF_HAND]       = 11,
        [EQUIP_SLOT_BACKUP_OFF]     = 11,
        [EQUIP_SLOT_CHEST]          = 10,
        [EQUIP_SLOT_LEGS]           = 9,
        [EQUIP_SLOT_HEAD]           = 8,
        [EQUIP_SLOT_SHOULDERS]      = 7,
        [EQUIP_SLOT_FEET]           = 6,
        [EQUIP_SLOT_HAND]           = 5,
        [EQUIP_SLOT_WAIST]          = 4,
        [EQUIP_SLOT_NECK]           = 3,
        [EQUIP_SLOT_RING1]          = 2,
        [EQUIP_SLOT_RING2]          = 1,
    }

    local EQUIPMENT_BONUS_FILLED_TEXTURE = "EsoUI/Art/CharacterWindow/equipmentBonusIcon_full.dds"
    local EQUIPMENT_BONUS_EMPTY_TEXTURE = "EsoUI/Art/CharacterWindow/equipmentBonusIcon_empty.dds"
    local EQUIPMENT_BONUS_GOLD_TEXTURE = "EsoUI/Art/CharacterWindow/equipmentBonusIcon_full_gold.dds"

    function ZO_Stats_Common:RefreshEquipmentBonus()
        --calculate total combat equipment bonus rating
        local totalEquipmentBonusRating = 0
        local lowestEquipmentBonusRating
        local lowestEquipSlot
        
        --check if our active weapon is two-handed (for special consideration in weighting weapon equipment bonus value and showing lowest piece in tooltips)
        local heldWeaponPair = GetHeldWeaponPair()
        local mainHandSlot = heldWeaponPair == ACTIVE_WEAPON_PAIR_BACKUP and EQUIP_SLOT_BACKUP_MAIN or EQUIP_SLOT_MAIN_HAND
        local equipType = select(6, GetItemInfo(BAG_WORN, mainHandSlot))
        local isUsingTwoHanded = equipType == EQUIP_TYPE_TWO_HAND

        for equipSlot = EQUIP_SLOT_ITERATION_BEGIN, EQUIP_SLOT_ITERATION_END do
            -- filter out an "non-combat" slots as well as the inactive weapon pair
            if IsActiveCombatRelatedEquipmentSlot(equipSlot) then
                local considerSlotForOverallRating = true
                --don't consider off hand weapon slots if player is wielding a two-handed weapon
                if equipSlot == EQUIP_SLOT_OFF_HAND or equipSlot == EQUIP_SLOT_BACKUP_OFF then
                    if isUsingTwoHanded then
                        considerSlotForOverallRating = false
                    end
                end

                if considerSlotForOverallRating then
                    local equipmentBonusRating = GetEquipmentBonusRating(BAG_WORN, equipSlot)

                    if not lowestEquipmentBonusRating or equipmentBonusRating < lowestEquipmentBonusRating then
                        lowestEquipmentBonusRating = equipmentBonusRating
                        lowestEquipSlot = equipSlot
                    elseif equipmentBonusRating == lowestEquipmentBonusRating and COMBAT_EQUIP_SLOT_IMPORTANCE[equipSlot] > COMBAT_EQUIP_SLOT_IMPORTANCE[lowestEquipSlot] then
                        lowestEquipSlot = equipSlot
                    end

                    --weight two-handed weapons twice so that they count double in the total
                    --this is to compensate for their empty off hand weapon slot, so they aren't penalized for 2H weapons in the total
                    if equipSlot == EQUIP_SLOT_MAIN_HAND or equipSlot == EQUIP_SLOT_BACKUP_MAIN then
                        if isUsingTwoHanded then
                            equipmentBonusRating = equipmentBonusRating * 2
                        end
                    end

                    totalEquipmentBonusRating = totalEquipmentBonusRating + equipmentBonusRating
                end
                -- else don't add the bonus rating to the total because we aren't considering it
            end
        end

        --set equipment bonus
        local averageEquipmentBonusRating = totalEquipmentBonusRating / NUM_COMBAT_RELATED_EQUIP_SLOTS
        local playerLevel = GetUnitLevel("player")
        local playerChampionPoints = GetUnitChampionPoints("player")
        local averageRelativeEquipmentBonusRating = GetUnitEquipmentBonusRatingRelativeToLevel("player", averageEquipmentBonusRating)
        local equipmentBonus = EQUIPMENT_BONUS_ITERATION_BEGIN
        for thresholdNumber = EQUIPMENT_BONUS_ITERATION_END, EQUIPMENT_BONUS_ITERATION_BEGIN, -1 do
            local thresholdValue = GetEquipmentBonusThreshold(playerLevel, playerChampionPoints, thresholdNumber)
            if averageRelativeEquipmentBonusRating >= thresholdValue then
                equipmentBonus = thresholdNumber
                break
            end
        end

        self.equipmentBonus.value = equipmentBonus
        self.equipmentBonus.lowestEquipSlot = lowestEquipSlot

        --setup icons
        self.equipmentBonus.iconPool:ReleaseAllObjects()

        local lastIcon
        --we setup 2 fewer icons than the number of EQUIPMENT_BONUS levels: the lowest equipment bonus level is all empty icons, and the highest adds a bonus icon separately
        for iconNumber = EQUIPMENT_BONUS_ITERATION_BEGIN, EQUIPMENT_BONUS_ITERATION_END - 2 do 
            local equipmentBonusIconControl = self.equipmentBonus.iconPool:AcquireObject()
            local equipmentBonusIconTexture
            if iconNumber < self.equipmentBonus.value then
                equipmentBonusIconTexture = self.equipmentBonus.value == EQUIPMENT_BONUS_EXTRAORDINARY and EQUIPMENT_BONUS_GOLD_TEXTURE or EQUIPMENT_BONUS_FILLED_TEXTURE
            else
                equipmentBonusIconTexture = EQUIPMENT_BONUS_EMPTY_TEXTURE
            end
            equipmentBonusIconControl:SetTexture(equipmentBonusIconTexture)

            if lastIcon then
                equipmentBonusIconControl:SetAnchor(BOTTOMLEFT, lastIcon, BOTTOMRIGHT, 4, 0)
            else
                 equipmentBonusIconControl:SetAnchor(BOTTOMLEFT)
            end
            lastIcon = equipmentBonusIconControl
        end

        --add bonus icon if at the highest level
        if self.equipmentBonus.value == EQUIPMENT_BONUS_MAX_VALUE then
            local equipmentBonusIconControl = self.equipmentBonus.iconPool:AcquireObject()
            equipmentBonusIconControl:SetTexture(EQUIPMENT_BONUS_GOLD_TEXTURE)
            equipmentBonusIconControl:SetAnchor(BOTTOMLEFT, lastIcon, BOTTOMRIGHT, 4, 0)
        end
    end
end

function ZO_StatsRidingSkillIcon_Initialize(control, trainingType)
    control.trainingType = trainingType
    control:GetNamedChild("Icon"):SetTexture(STABLE_TRAINING_TEXTURES[trainingType])
end
-----------------------
-- Attribute Spinner --
-----------------------

ZO_AttributeSpinner_Shared = ZO_Object:Subclass()

function ZO_AttributeSpinner_Shared:New(attributeControl, attributeType, attributeManager, valueChangedCallback)
    local attributeSpinner = ZO_Object.New(self)

    attributeSpinner.attributeControl = attributeControl
    
    attributeSpinner.points = 0
    attributeSpinner.addedPoints = 0
    attributeSpinner.attributeManager = attributeManager
    attributeSpinner:SetValueChangedCallback(valueChangedCallback)
    attributeSpinner:SetAttributeType(attributeType)

    return attributeSpinner
end

function ZO_AttributeSpinner_Shared:SetSpinner(spinner)
    self.pointsSpinner = spinner
    self.pointsSpinner:RegisterCallback("OnValueChanged", function(points) self:OnValueChanged(points) end)
end

function ZO_AttributeSpinner_Shared:Reinitialize(attributeType, addedPoints, valueChangedCallback)
    self:SetValueChangedCallback(valueChangedCallback)
    self:SetAttributeType(attributeType)

    self.points = GetAttributeSpentPoints(self.attributeType)

    self:SetAddedPoints(addedPoints, true)
    self:RefreshSpinnerMax()

    self.pointsSpinner:SetValue(self.points + addedPoints)
end

function ZO_AttributeSpinner_Shared:SetValueChangedCallback(fn)
    self.valueChangedCallback = fn
end

function ZO_AttributeSpinner_Shared:SetAttributeType(attributeType)
    self.attributeType = attributeType
    self.perPoint = GetAttributeDerivedStatPerPointValue(attributeType, STAT_TYPES[attributeType])
end

function ZO_AttributeSpinner_Shared:OnValueChanged(points)
    self:SetAddedPointsByTotalPoints(points)

    if self.valueChangedCallback ~= nil then
        self.valueChangedCallback(self.points, self.addedPoints)
    end

    self:RefreshSpinnerMax()
end

function ZO_AttributeSpinner_Shared:RefreshSpinnerMax()
    local minPoints = self.points
    if self.attributeManager.DoesAttributePointAllocationModeBatchSave and self.attributeManager:DoesAttributePointAllocationModeBatchSave() then
        minPoints = 0
    end
    self.pointsSpinner:SetMinMax(minPoints, self.points + self.addedPoints + self.attributeManager:GetAvailablePoints())
end

function ZO_AttributeSpinner_Shared:RefreshPoints()
    self.points = GetAttributeSpentPoints(self.attributeType)
    self:RefreshSpinnerMax()
    self.pointsSpinner:SetValue(self.points)
end

function ZO_AttributeSpinner_Shared:ResetAddedPoints()
    self.addedPoints = 0
    self:RefreshPoints()
end

function ZO_AttributeSpinner_Shared:GetPoints()
    return self.points
end

function ZO_AttributeSpinner_Shared:GetAllocatedPoints()
    return self.addedPoints
end

function ZO_AttributeSpinner_Shared:SetAddedPointsByTotalPoints(totalPoints)
    self:SetAddedPoints(totalPoints - self.points)
end

function ZO_AttributeSpinner_Shared:SetAddedPoints(points, force)
    if not self.attributeManager.DoesAttributePointAllocationModeBatchSave or not self.attributeManager:DoesAttributePointAllocationModeBatchSave() then
        points = zo_max(points, 0)
    end

    local diff = points - self.addedPoints
    local availablePoints = self.attributeManager:GetAvailablePoints()

    if force then
        diff = 0
    elseif diff > availablePoints then
        diff = availablePoints
        points = diff + self.addedPoints
    end

    self.addedPoints = points

    if diff ~= 0 then
        self.attributeManager:SpendAvailablePoints(diff)
    end
    self.attributeManager:UpdatePendingStatBonuses(STAT_TYPES[self.attributeType], self.perPoint * self.addedPoints)
end

function ZO_AttributeSpinner_Shared:SetButtonsHidden(hidden)
    self.pointsSpinner:SetButtonsHidden(hidden)
end
