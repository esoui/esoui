ZO_VENGEANCE_PERK_EMPTY_ICONS =
{
    [VENGEANCE_PERK_SLOT_RED] = "EsoUI/Art/Vengeance/perk_empty_slot.dds",
    [VENGEANCE_PERK_SLOT_YELLOW] = "EsoUI/Art/Vengeance/perk_empty_slot.dds",
    [VENGEANCE_PERK_SLOT_BLUE] = "EsoUI/Art/Vengeance/perk_empty_slot.dds",
}

ZO_VENGEANCE_PERK_ICON_BORDER =
{
    [VENGEANCE_PERK_SLOT_RED] = "EsoUI/Art/Vengeance/red_perk_border.dds",
    [VENGEANCE_PERK_SLOT_YELLOW] = "EsoUI/Art/Vengeance/yellow_perk_border.dds",
    [VENGEANCE_PERK_SLOT_BLUE] = "EsoUI/Art/Vengeance/blue_perk_border.dds",
}

ZO_VENGEANCE_PERK_ICON_BACKGROUND =
{
    [VENGEANCE_PERK_SLOT_RED] = "EsoUI/Art/Vengeance/perk_background_red.dds",
    [VENGEANCE_PERK_SLOT_YELLOW] = "EsoUI/Art/Vengeance/perk_background_yellow.dds",
    [VENGEANCE_PERK_SLOT_BLUE] = "EsoUI/Art/Vengeance/perk_background_blue.dds",
}

ZO_VENGEANCE_PERK_COLORS =
{
    [VENGEANCE_PERK_SLOT_RED] = GetAllianceColor(ALLIANCE_EBONHEART_PACT),
    [VENGEANCE_PERK_SLOT_YELLOW] = GetAllianceColor(ALLIANCE_ALDMERI_DOMINION),
    [VENGEANCE_PERK_SLOT_BLUE] = GetAllianceColor(ALLIANCE_DAGGERFALL_COVENANT),
}

ZO_VENGEANCE_SCREEN_GAMEPAD_INDEX =
{
    LOADOUTS = 1,
    PERKS = 2,
}

ZO_VENGEANCE_BAG_SELL_ENABLED = false

-----------------------------
-- Vengeance Loadout
-----------------------------

ZO_VengeanceLoadoutData = ZO_InitializingObject:Subclass()

function ZO_VengeanceLoadoutData:Initialize(index)
    self.index = index
    self.positiveImportantStats = {}
    self.negativeImportantStats = {}
    self.primaryActionBar = ZO_VengeanceLoadoutSkillsData:New(index, HOTBAR_CATEGORY_PRIMARY)
    self.backupActionBar = ZO_VengeanceLoadoutSkillsData:New(index, HOTBAR_CATEGORY_BACKUP)
    self.derivedStatsData = {}

    self:RefreshDerivedStats()
end

function ZO_VengeanceLoadoutData:GetLoadoutIndex()
    return self.index
end

function ZO_VengeanceLoadoutData:GetName()
    return GetVengeanceRoleNameAtIndex(self.index)
end

function ZO_VengeanceLoadoutData:GetIcon()
    return GetVengeanceRoleIconAtIndex(self.index)
end

function ZO_VengeanceLoadoutData:IsEquipped()
    return IsLoadoutRoleEquippedAtIndex(self.index)
end

function ZO_VengeanceLoadoutData:GetNumImportantDerivedStats()
    return GetNumberOfImportantDerivedStatDisplaysForRoleAtIndex(self.index)
end

function ZO_VengeanceLoadoutData:GetImportantDerivedStatStringByIndex(statIndex)
    local statType, oldValue, newValue, displayType = GetImportantDerivedStatDisplayInfoForRoleAtIndex(self.index, statIndex)
    local diffValue = newValue - oldValue
    local valueStringFormatter = nil
    if displayType == DERIVED_STAT_DISPLAY_PERCENT then
        if diffValue > 0 then
            valueStringFormatter = SI_CAMPAIGN_VENGEANCE_POSITIVE_STAT_VALUE_PERCENT
        else
            valueStringFormatter = SI_CAMPAIGN_VENGEANCE_NEGATIVE_STAT_VALUE_PERCENT
        end
    else
        if diffValue > 0 then
            valueStringFormatter = SI_CAMPAIGN_VENGEANCE_POSITIVE_STAT_VALUE_FLAT
        else
            valueStringFormatter = SI_CAMPAIGN_VENGEANCE_NEGATIVE_STAT_VALUE_FLAT
        end
    end
    local valueString = tostring(diffValue)
    local formattedString = zo_strformat(valueStringFormatter, valueString, GetString("SI_DERIVEDSTATS", statType))
    if diffValue > 0 then
        return ZO_SUCCEEDED_TEXT:Colorize(formattedString), diffValue
    elseif diffValue == 0 then
        return ZO_SELECTED_TEXT:Colorize(formattedString), diffValue
    else
        return ZO_ERROR_COLOR:Colorize(formattedString), diffValue
    end
end

function ZO_VengeanceLoadoutData:GetNumImportantMiscStats()
    return GetNumberOfImportantMiscStatDisplaysForRoleAtIndex(self.index)
end

function ZO_VengeanceLoadoutData:GetImportantMiscStatStringByIndex(statIndex)
    local statType, oldValue, newValue, displayType = GetImportantMiscStatDisplayInfoForRoleAtIndex(self.index, statIndex)
    local diffValue = newValue - oldValue
    local valueStringFormatter = nil
    if displayType == DERIVED_STAT_DISPLAY_PERCENT then
        if diffValue > 0 then
            valueStringFormatter = SI_CAMPAIGN_VENGEANCE_POSITIVE_STAT_VALUE_PERCENT
        else
            valueStringFormatter = SI_CAMPAIGN_VENGEANCE_NEGATIVE_STAT_VALUE_PERCENT
        end
    else
        if diffValue > 0 then
            valueStringFormatter = SI_CAMPAIGN_VENGEANCE_POSITIVE_STAT_VALUE_FLAT
        else
            valueStringFormatter = SI_CAMPAIGN_VENGEANCE_NEGATIVE_STAT_VALUE_FLAT
        end
    end
    local valueString = tostring(diffValue)
    local formattedString = zo_strformat(valueStringFormatter, valueString, GetString("SI_VENGEANCEMISCSTAT", statType))
    if diffValue > 0 then
        return ZO_SUCCEEDED_TEXT:Colorize(formattedString), diffValue
    elseif diffValue == 0 then
        return ZO_SELECTED_TEXT:Colorize(formattedString), diffValue
    else
        return ZO_ERROR_COLOR:Colorize(formattedString), diffValue
    end
end

function ZO_VengeanceLoadoutData:RefreshImportantStats()
    ZO_ClearTable(self.positiveImportantStats)
    ZO_ClearTable(self.negativeImportantStats)
    local numDerivedStats = self:GetNumImportantDerivedStats()
    for i = 1, numDerivedStats do
        local statText, diffValue = self:GetImportantDerivedStatStringByIndex(i)
        if diffValue > 0 then
            table.insert(self.positiveImportantStats, statText)
        elseif diffValue < 0 then
            table.insert(self.negativeImportantStats, statText)
        end
    end

    local numMiscStats = self:GetNumImportantMiscStats()
    for i = 1, numMiscStats do
        local statText, diffValue = self:GetImportantMiscStatStringByIndex(i)
        if diffValue > 0 then
            table.insert(self.positiveImportantStats, statText)
        elseif diffValue < 0 then
            table.insert(self.negativeImportantStats, statText)
        end
    end
end

function ZO_VengeanceLoadoutData:GetPositiveImportantStats()
    return self.positiveImportantStats
end

function ZO_VengeanceLoadoutData:GetNegativeImportantStats()
    return self.negativeImportantStats
end

function ZO_VengeanceLoadoutData:RefreshDerivedStats()
    ZO_ClearTable(self.derivedStatsData)
    for groupIndex, statGroup in ipairs(ZO_INVENTORY_STAT_GROUPS) do
        for _, statType in ipairs(statGroup) do
            self.derivedStatsData[statType] = GetDerivedStatValueForRoleAtIndex(statType, self.index)
        end
    end
end

function ZO_VengeanceLoadoutData:GetDerivedStatValueByStatType(statType)
    return self.derivedStatsData[statType]
end

function ZO_VengeanceLoadoutData:GetPerkDataBySlot(slot)
    local perkGlobalIndex = GetIndexOfPerkInSlotForRole(slot, self.index)
    return ZO_VENGEANCE_MANAGER:GetPerkByIndex(perkGlobalIndex)
end

function ZO_VengeanceLoadoutData:GetPerkIconBySlot(slot)
    local perkData = self:GetPerkDataBySlot(slot)
    if perkData then
        return perkData:GetIcon()
    else
        return ZO_VENGEANCE_MANAGER:GetEmptyPerkIconBySlot(slot)
    end
end

function ZO_VengeanceLoadoutData:GetPerkNameBySlot(slot)
    local perkData = self:GetPerkDataBySlot(slot)
    if perkData then
        return perkData:GetName()
    else
        return ZO_VENGEANCE_MANAGER:GetEmptyPerkName()
    end
end

function ZO_VengeanceLoadoutData:GetPrimaryActionBarData()
    return self.primaryActionBar
end

function ZO_VengeanceLoadoutData:GetBackupActionBarData()
    return self.backupActionBar
end

-----------------------------
-- Vengeance Loadout Skills
-----------------------------

ZO_VengeanceLoadoutSkillsData = ZO_InitializingObject:MultiSubclass(ZO_SkillsActionBarData)

function ZO_VengeanceLoadoutSkillsData:Initialize(loadoutIndex, hotbarCategory)
    self.loadoutIndex = loadoutIndex
    self.hotbarCategory = hotbarCategory
end

function ZO_VengeanceLoadoutSkillsData:GetSlottedAbilityId(slotIndex, hotbarCategory)
    if hotbarCategory == nil then
        hotbarCategory = self.hotbarCategory
    end
    return GetAbilityIdForHotbarSlotAtIndex(self.loadoutIndex, hotbarCategory, slotIndex)
end

-----------------------------
-- Vengeance Perk
-----------------------------

ZO_VengeancePerkData = ZO_InitializingObject:Subclass()

function ZO_VengeancePerkData:Initialize(slot, slotIndex)
    self.index = GetPerkIndexForSlotAtSlotIndex(slot, slotIndex)
    self.slot = slot
    self.slotIndex = slotIndex
end

function ZO_VengeancePerkData:GetPerkIndex()
    return self.index
end

function ZO_VengeancePerkData:GetSlot()
    return self.slot
end

function ZO_VengeancePerkData:GetSlotIndex()
    return self.slotIndex
end

function ZO_VengeancePerkData:GetName()
    return GetVengeancePerkNameAtIndex(self.index)
end

function ZO_VengeancePerkData:GetIcon()
    return GetVengeancePerkIconAtIndex(self.index)
end

function ZO_VengeancePerkData:GetBorderTexture()
    return ZO_VENGEANCE_MANAGER:GetPerkBorderTextureByIndex(self.index)
end

function ZO_VengeancePerkData:GetBackgroundTexture()
    return ZO_VENGEANCE_MANAGER:GetPerkBackgroundTextureByIndex(self.index)
end

function ZO_VengeancePerkData:GetTooltipText()
    return GetVengeancePerkTooltipTextAtIndex(self.index)
end

function ZO_VengeancePerkData:CanEquipPerk()
    local canEquipResult = CanPerkBeSlottedInSlotForRole(self.index, self.slot)
    return canEquipResult == VENGEANCE_ACTION_RESULT_SUCCESS
        or canEquipResult == VENGEANCE_ACTION_RESULT_PERK_ALREADY_EQUIPPED, canEquipResult
end

function ZO_VengeancePerkData:IsPerkEquipped()
    return ZO_VENGEANCE_MANAGER:IsEquippedPerk(self)
end

function ZO_VengeancePerkData:IsPerkDisabled()
    local result = CanPerkBeSlottedInSlotForRole(self.index, self.slot)
    local isDisabled = false
    local reason = VENGEANCE_ACTION_RESULT_SUCCESS
    if result == VENGEANCE_ACTION_RESULT_PERK_DISABLED then
        isDisabled = true
        reason = VENGEANCE_ACTION_RESULT_PERK_DISABLED
    elseif ZO_VENGEANCE_MANAGER:IsPerkEquippedInDifferentSlot(self) then
        -- Don't check this reason from the client as it doesn't reflect local uncommitted changes
        isDisabled = true
        reason = VENGEANCE_ACTION_RESULT_PERK_ALREADY_EQUIPPED
    end
    return isDisabled, reason
end

-----------------------------
-- Vengeance Manager
-----------------------------

ZO_Vengeance_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_Vengeance_Manager:Initialize()
    self.initialized = false
    self.loadoutData = {}
    self.perksData = {}
    self.perkSlots =
    {
        VENGEANCE_PERK_SLOT_RED,
        VENGEANCE_PERK_SLOT_YELLOW,
        VENGEANCE_PERK_SLOT_BLUE,
    }
    self.perkDataByIndex = {}
    self.equippedPerks = {}
    self:ResetPerks()

    local function OnVengeanceLoadoutRoleChanged()
        self:RefreshLoadoutDataImportantStats()
        self:RefreshEquippedLoadoutData()
        self:FireCallbacks("VengeanceLoadoutRoleChanged")
        PlaySound(SOUNDS.VENGEANCE_LOADOUT_EQUIPPED)
    end

    local function OnVengeanceLoadoutPerksChanged()
        self:RefreshPerkData()
        if self.equippedLoadout then
            self.equippedLoadout:RefreshDerivedStats()
        end
    end

    EVENT_MANAGER:RegisterForEvent("VengeanceManager", EVENT_PLAYER_ACTIVATED, function() self:RefreshPerkData() end)
    EVENT_MANAGER:RegisterForEvent("VengeanceManager", EVENT_VENGEANCE_LOADOUT_ROLE_UPDATED, OnVengeanceLoadoutRoleChanged)
    EVENT_MANAGER:RegisterForEvent("VengeanceManager", EVENT_VENGEANCE_PERKS_UPDATED, OnVengeanceLoadoutPerksChanged)
end

function ZO_Vengeance_Manager:PerformDeferredInitialization()
    if not self.initialized and IsCurrentCampaignVengeanceRuleset() then
        self.initialized = true
        self:RefreshLoadoutData()
        self:RefreshPerkData()
        self:RefreshLoadoutDataImportantStats()
        self:RefreshEquippedLoadoutData()
    end
end

function ZO_Vengeance_Manager:RefreshLoadoutData()
    local numLoadouts = GetNumberOfVengeanceRolesAvailableToPlayer()
    ZO_ClearTable(self.loadoutData)
    for i = 1, numLoadouts do
        local loadout = ZO_VengeanceLoadoutData:New(i)
        table.insert(self.loadoutData, loadout)
    end
end

function ZO_Vengeance_Manager:RefreshLoadoutDataImportantStats()
    for i, loadout in ipairs(self.loadoutData) do
        loadout:RefreshImportantStats()
    end
end

function ZO_Vengeance_Manager:RefreshEquippedLoadoutData()
    for i, loadout in ipairs(self.loadoutData) do
        if loadout:IsEquipped() then
            self.equippedLoadout = loadout
            break
        end
    end
end

function ZO_Vengeance_Manager:GetEquippedLoadoutData()
    self:PerformDeferredInitialization()
    return self.equippedLoadout
end

function ZO_Vengeance_Manager:IsLoadoutIndexKeybindVisible(loadoutIndex)
    local canEquipResult = CanLoadoutRoleBeEquippedByIndex(loadoutIndex)
    return canEquipResult == VENGEANCE_ACTION_RESULT_SUCCESS
        or canEquipResult == VENGEANCE_ACTION_RESULT_ROLE_SWAP_ON_COOLDOWN
        or canEquipResult == VENGEANCE_ACTION_RESULT_INVALID_SUBZONE
end

function ZO_Vengeance_Manager:LoadoutDataIterator(filterFunctions)
    self:PerformDeferredInitialization()
    return ZO_FilteredNumericallyIndexedTableIterator(self.loadoutData, filterFunctions)
end

function ZO_Vengeance_Manager:GetLoadoutDataByIndex(index)
    return self.loadoutData[index]
end

function ZO_Vengeance_Manager:RefreshPerkData()
    ZO_ClearTable(self.perksData)
    ZO_ClearTable(self.perkDataByIndex)
    for _, slot in ipairs(self.perkSlots) do
        local numSlotPerks = GetNumberOfPerksAvailableToLoadoutRoleDefInSlot(slot)
        local equippedSlotPerkIndex = GetIndexOfPerkInSlotForRole(slot)
        self:ClearEquippedPerkBySlot(slot)
        for i = 1, numSlotPerks do
            local perkData = ZO_VengeancePerkData:New(slot, i)
            table.insert(self.perksData, perkData)
            local perkIndex = perkData:GetPerkIndex()

            if not self.perkDataByIndex[perkIndex] then
                self.perkDataByIndex[perkIndex] = { perkData }
            else
                table.insert(self.perkDataByIndex[perkIndex], perkData)
            end

            if perkIndex == equippedSlotPerkIndex then
                local SUPPRESS_AUDIO = true
                self:SetEquippedPerk(perkData, SUPPRESS_AUDIO)
            end
        end
    end
end

function ZO_Vengeance_Manager:PerkDataIterator(filterFunctions)
    self:PerformDeferredInitialization()
    return ZO_FilteredNumericallyIndexedTableIterator(self.perksData, filterFunctions)
end

function ZO_Vengeance_Manager:GetPerkByIndex(index, slot)
    if self.perkDataByIndex[index] then
        for i, perkData in ipairs(self.perkDataByIndex[index]) do
            if not slot or slot == perkData:GetSlot() then
                return perkData
            end
        end
    end
    return nil
end

function ZO_Vengeance_Manager:SetEquippedPerk(perkData, suppressAudio)
    if not self:IsPerkEquippedInDifferentSlot(perkData) then
        self.equippedPerks[perkData:GetSlot()] = perkData:GetSlotIndex()
        self:FireCallbacks("OnPerkSelectionChanged")
        if not suppressAudio then
            PlaySound(SOUNDS.VENGEANCE_PERK_EQUIPPED)
        end
    end
end

function ZO_Vengeance_Manager:GetEquippedPerkIndexBySlot(slot)
    return GetPerkIndexForSlotAtSlotIndex(slot, self.equippedPerks[slot])
end

function ZO_Vengeance_Manager:GetEquippedPerkDataBySlot(slot)
    local perkIndex = self:GetEquippedPerkIndexBySlot(slot)
    return self:GetPerkByIndex(perkIndex)
end

function ZO_Vengeance_Manager:IsPerkEquippedInDifferentSlot(perkData)
    for slot, slotIndex in pairs(self.equippedPerks) do
        local equippedPerkData = self:GetEquippedPerkDataBySlot(slot)
        if equippedPerkData and perkData:GetSlot() ~= slot and perkData:GetPerkIndex() == equippedPerkData:GetPerkIndex() then
            return true
        end
    end
    return false
end

function ZO_Vengeance_Manager:ClearEquippedPerkBySlot(slot)
    self.equippedPerks[slot] = MAX_PERKS_AVAILABLE_PER_LOADOUT + 1
    self:FireCallbacks("OnPerkSelectionChanged")
end

function ZO_Vengeance_Manager:ResetPerks()
    for i, slot in ipairs(self.perkSlots) do
        self:ClearEquippedPerkBySlot(slot)
    end
end

function ZO_Vengeance_Manager:ClearEquippedPerk(perkData)
    self:ClearEquippedPerkBySlot(perkData:GetSlot())
    PlaySound(SOUNDS.VENGEANCE_PERK_UNEQUIPPED)
end

function ZO_Vengeance_Manager:IsEquippedPerk(perkData)
    if perkData then
        return self.equippedPerks[perkData:GetSlot()] == perkData:GetSlotIndex()
    end
    return false
end

function ZO_Vengeance_Manager:GetEmptyPerkIconBySlot(slot)
    return ZO_VENGEANCE_PERK_EMPTY_ICONS[slot]
end

function ZO_Vengeance_Manager:GetEmptyPerkName()
    return GetString(SI_CAMPAIGN_VENGEANCE_NO_SELECTED_PERK)
end

function ZO_Vengeance_Manager:GetPerkColorBySlot(slot)
    return ZO_VENGEANCE_PERK_COLORS[slot]
end

function ZO_Vengeance_Manager:GetPerkBorderBySlot(slot)
    return ZO_VENGEANCE_PERK_ICON_BORDER[slot]
end

function ZO_Vengeance_Manager:GetPerkBackgroundBySlot(slot)
    return ZO_VENGEANCE_PERK_ICON_BACKGROUND[slot]
end

function ZO_Vengeance_Manager:GetPerkBorderTextureByIndex(index)
    local perkSlot =
    {
        [VENGEANCE_PERK_SLOT_RED] = false,
        [VENGEANCE_PERK_SLOT_YELLOW] = false,
        [VENGEANCE_PERK_SLOT_BLUE] = false,
    }
    if self.perkDataByIndex[index] then
        for i, perkData in ipairs(self.perkDataByIndex[index]) do
            perkSlot[perkData:GetSlot()] = true
        end
    end

    if perkSlot[VENGEANCE_PERK_SLOT_RED]
        and perkSlot[VENGEANCE_PERK_SLOT_YELLOW]
        and perkSlot[VENGEANCE_PERK_SLOT_BLUE] then
        return "EsoUI/Art/Vengeance/red_yellow_blue_perk_border.dds"
    elseif perkSlot[VENGEANCE_PERK_SLOT_RED]
        and perkSlot[VENGEANCE_PERK_SLOT_YELLOW] then
        return "EsoUI/Art/Vengeance/red_yellow_perk_border.dds"
    elseif perkSlot[VENGEANCE_PERK_SLOT_RED]
        and perkSlot[VENGEANCE_PERK_SLOT_BLUE] then
        return "EsoUI/Art/Vengeance/red_blue_perk_border.dds"
    elseif perkSlot[VENGEANCE_PERK_SLOT_YELLOW]
        and perkSlot[VENGEANCE_PERK_SLOT_BLUE] then
        return "EsoUI/Art/Vengeance/yellow_blue_perk_border.dds"
    elseif perkSlot[VENGEANCE_PERK_SLOT_RED] then
        return self:GetPerkBorderBySlot(VENGEANCE_PERK_SLOT_RED)
    elseif perkSlot[VENGEANCE_PERK_SLOT_YELLOW] then
        return self:GetPerkBorderBySlot(VENGEANCE_PERK_SLOT_YELLOW)
    elseif perkSlot[VENGEANCE_PERK_SLOT_BLUE] then
        return self:GetPerkBorderBySlot(VENGEANCE_PERK_SLOT_BLUE)
    end
end

function ZO_Vengeance_Manager:GetPerkBackgroundTextureByIndex(index)
    local perkSlot =
    {
        [VENGEANCE_PERK_SLOT_RED] = false,
        [VENGEANCE_PERK_SLOT_YELLOW] = false,
        [VENGEANCE_PERK_SLOT_BLUE] = false,
    }
    if self.perkDataByIndex[index] then
        for i, perkData in ipairs(self.perkDataByIndex[index]) do
            perkSlot[perkData:GetSlot()] = true
        end
    end

    if perkSlot[VENGEANCE_PERK_SLOT_RED]
        and perkSlot[VENGEANCE_PERK_SLOT_YELLOW]
        and perkSlot[VENGEANCE_PERK_SLOT_BLUE] then
        return "EsoUI/Art/Vengeance/perk_background_omni.dds"
    elseif perkSlot[VENGEANCE_PERK_SLOT_RED]
        and perkSlot[VENGEANCE_PERK_SLOT_YELLOW] then
        return "EsoUI/Art/Vengeance/perk_background_orange.dds"
    elseif perkSlot[VENGEANCE_PERK_SLOT_RED]
        and perkSlot[VENGEANCE_PERK_SLOT_BLUE] then
        return "EsoUI/Art/Vengeance/perk_background_purple.dds"
    elseif perkSlot[VENGEANCE_PERK_SLOT_YELLOW]
        and perkSlot[VENGEANCE_PERK_SLOT_BLUE] then
        return "EsoUI/Art/Vengeance/perk_background_green.dds"
    elseif perkSlot[VENGEANCE_PERK_SLOT_RED] then
        return self:GetPerkBackgroundBySlot(VENGEANCE_PERK_SLOT_RED)
    elseif perkSlot[VENGEANCE_PERK_SLOT_YELLOW] then
        return self:GetPerkBackgroundBySlot(VENGEANCE_PERK_SLOT_YELLOW)
    elseif perkSlot[VENGEANCE_PERK_SLOT_BLUE] then
        return self:GetPerkBackgroundBySlot(VENGEANCE_PERK_SLOT_BLUE)
    end
end

function ZO_Vengeance_Manager:GetPerkSlotName(slot)
    return GetString("SI_VENGEANCEPERKSLOTFLAGS", slot)
end

function ZO_Vengeance_Manager:ApplyEquippedPerks()
    local redEquippedIndex = self:GetEquippedPerkIndexBySlot(VENGEANCE_PERK_SLOT_RED)
    local yellowEquippedIndex = self:GetEquippedPerkIndexBySlot(VENGEANCE_PERK_SLOT_YELLOW)
    local blueEquippedIndex = self:GetEquippedPerkIndexBySlot(VENGEANCE_PERK_SLOT_BLUE)
    local result = RequestSetPerkSelectionForRoleByIndex(redEquippedIndex, yellowEquippedIndex, blueEquippedIndex)
    if result == VENGEANCE_ACTION_RESULT_SUCCESS then
        self:ResetPerks()
    end
end

function ZO_Vengeance_Manager:IsEquippedLoadoutEditableForCurrentZone()
    if not IsCurrentCampaignVengeanceRuleset() then
        return false
    end
    local loadoutData = self:GetEquippedLoadoutData()
    -- When entering vengeance this can be called after the campaign has
    -- been set to vengeance but before loadouts have been initialized.
    if loadoutData then
        local canEquipResult = CanLoadoutRoleBeEquippedByIndex(loadoutData:GetLoadoutIndex())
        return canEquipResult ~= VENGEANCE_ACTION_RESULT_INVALID_SUBZONE
    end
    return false
end

ZO_VENGEANCE_MANAGER = ZO_Vengeance_Manager:New()