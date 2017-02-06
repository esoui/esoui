ZO_TRADE_BOP_ICON = "EsoUI/Art/Inventory/inventory_Tradable_icon.dds"

ZO_SharedInventoryManager = ZO_CallbackObject:Subclass()

function ZO_SharedInventoryManager:New(...)
    local sharedInventoryManager = ZO_CallbackObject.New(self)
    sharedInventoryManager:Initialize(...)
    return sharedInventoryManager
end

function ZO_SharedInventoryManager:Initialize()
    local namespace = tostring(self)
    local function OnInventoryItemDestroyed(eventCode, itemSoundCategory)
        PlayItemSound(itemSoundCategory, ITEM_SOUND_ACTION_DESTROY)
    end
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_INVENTORY_ITEM_DESTROYED, OnInventoryItemDestroyed)

    local function OnInventoryItemUsed(eventCode, itemSoundCategory)
        PlayItemSound(itemSoundCategory, ITEM_SOUND_ACTION_USE)
    end
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_INVENTORY_ITEM_USED, OnInventoryItemUsed)

    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_OPEN_FENCE, function() 
        self:RefreshInventory(BAG_BACKPACK) 
        self:RefreshInventory(BAG_WORN)
    end)

    self.bagCache = {}
    self.questCache = {}

    self.refresh = ZO_Refresh:New()

    self.refresh:AddRefreshGroup("inventory",
    {
        RefreshAll = function()
            self:RefreshInventory(BAG_BACKPACK)
            self:RefreshInventory(BAG_WORN)
            self:RefreshInventory(BAG_VIRTUAL)
            -- with the addition of Craft Bags the bank bag could be modified by the automatic transfer
            -- of bank contents to the Craft Bag on joining a region
            self:RefreshInventory(BAG_BANK)
        end,
        RefreshSingle = function(...)
            self:RefreshSingleSlot(...)
        end,
    })

    self.refresh:AddRefreshGroup("guild_bank",
    {
        RefreshAll = function()
            self:RefreshInventory(BAG_GUILDBANK)
        end,
    })

    self.refresh:AddRefreshGroup("quest_inventory",
    {
        RefreshAll = function()
            self:RefreshAllQuests()
        end,
        RefreshSingle = function(questIndex)
            self:RefreshSingleQuest(questIndex)
        end,
    })

    local function OnFullInventoryUpdated()
        self.refresh:RefreshAll("inventory")
        self.refresh:UpdateRefreshGroups()
    end

    local function OnInventorySlotUpdated(eventCode, bagId, slotIndex, isNewItem, itemSoundCategory, updateReason)
        if updateReason == INVENTORY_UPDATE_REASON_DURABILITY_CHANGE then
            local newCondition = GetItemCondition(bagId, slotIndex)
            if newCondition == 100 then
                self:FireCallbacks("ItemRepaired", bagId, slotIndex)
            end
        end

        local previousSlotData = self:GetOrCreateBagCache(bagId)[slotIndex]
        --Since the inventory can update the existing slot table to a new item we need to make a copy of the old data
        if previousSlotData then
            previousSlotData = ZO_ShallowTableCopy(previousSlotData)
        end

        self.refresh:RefreshSingle("inventory", bagId, slotIndex, isNewItem, itemSoundCategory, updateReason)
        self.refresh:UpdateRefreshGroups()

        if bagId == BAG_BACKPACK or bagId == BAG_VIRTUAL then
            if isNewItem and GetCraftingInteractionType() == CRAFTING_TYPE_INVALID and not SYSTEMS:IsShowing("crownCrate") then
                PlayItemSound(itemSoundCategory, ITEM_SOUND_ACTION_ACQUIRE)
            end
        elseif GetInteractionType() == INTERACTION_BANK and bagId == BAG_BANK then
            PlayItemSound(itemSoundCategory, ITEM_SOUND_ACTION_SLOT)
        end

        if bagId == BAG_WORN and eventCode == EVENT_INVENTORY_SINGLE_SLOT_UPDATE then
            local _, slotHasItem = GetEquippedItemInfo(slotIndex)

            if updateReason == INVENTORY_UPDATE_REASON_DEFAULT then
                if slotHasItem then
                    PlayItemSound(itemSoundCategory, ITEM_SOUND_ACTION_EQUIP)
                else
                    PlayItemSound(itemSoundCategory, ITEM_SOUND_ACTION_UNEQUIP)
                end
            end

            if updateReason == INVENTORY_UPDATE_REASON_DURABILITY_CHANGE then 
                local effectivenessReduced = IsArmorEffectivenessReduced(bagId, slotIndex)
                if effectivenessReduced then 
                    TriggerTutorial(TUTORIAL_TRIGGER_DAMAGED_EQUIPMENT_REDUCING_EFFECTIVENESS)
                end
            end
        end

        self:FireCallbacks("SingleSlotInventoryUpdate", bagId, slotIndex, previousSlotData)
    end

    local function OnGuildBankUpdated()
        self.refresh:RefreshAll("guild_bank")
        self:FireCallbacks("FullInventoryUpdate", BAG_GUILDBANK)
    end

    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_INVENTORY_FULL_UPDATE, OnFullInventoryUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventorySlotUpdated)


    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_OPEN_GUILD_BANK, OnGuildBankUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_CLOSE_GUILD_BANK, OnGuildBankUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_GUILD_BANK_SELECTED, OnGuildBankUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_GUILD_BANK_DESELECTED, OnGuildBankUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_GUILD_BANK_ITEMS_READY, OnGuildBankUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_GUILD_BANK_OPEN_ERROR, OnGuildBankUpdated)

    local function OnGuildBankInventorySlotUpdated(eventCode, slotIndex)
        local previousSlotData = self:GetOrCreateBagCache(BAG_GUILDBANK)[slotIndex]
        self.refresh:RefreshSingle("inventory", BAG_GUILDBANK, slotIndex)
        self.refresh:UpdateRefreshGroups()
        self:FireCallbacks("SingleSlotInventoryUpdate", BAG_GUILDBANK, slotIndex, previousSlotData)
    end

    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_GUILD_BANK_ITEM_ADDED, OnGuildBankInventorySlotUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_GUILD_BANK_ITEM_REMOVED, OnGuildBankInventorySlotUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_GUILD_BANK_UPDATED_QUANTITY, OnGuildBankInventorySlotUpdated)

    local function OnFullQuestInventoryUpdated()
        self.refresh:RefreshAll("quest_inventory")
        self.refresh:UpdateRefreshGroups()
    end 

    local function OnSingleQuestUpdated(eventCode, journalIndex)
        self.refresh:RefreshSingle("quest_inventory", journalIndex)
        self.refresh:UpdateRefreshGroups()
    end

    local function OnQuestRemoved(eventId, isCompleted, journalIndex, questName, zoneIndex, poiIndex)
        self.refresh:RefreshSingle("quest_inventory", journalIndex)
        self.refresh:UpdateRefreshGroups()
    end

    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_QUEST_LIST_UPDATED, OnFullQuestInventoryUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_QUEST_CONDITION_COUNTER_CHANGED, OnSingleQuestUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_QUEST_TOOL_UPDATED, OnSingleQuestUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_QUEST_ADDED, OnSingleQuestUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_QUEST_ADVANCED, OnSingleQuestUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_QUEST_REMOVED, OnQuestRemoved)

    local function OnMoneyUpdated(eventCode, newMoney, oldMoney, reason)
        local wasInitialize = (reason == CURRENCY_CHANGE_REASON_PLAYER_INIT)
        local wasItemPurchased = (reason == CURRENCY_CHANGE_REASON_VENDOR) and (newMoney < oldMoney)

        if(not (wasItemPurchased or wasInitialize)) then
            PlaySound(SOUNDS.ITEM_MONEY_CHANGED)
        end
    end

    local function OnTelvarStonesUpdated(eventCode, newTelvarStones, oldTelvarStones, changeReason)
        local isExcludedReason = changeReason == CURRENCY_CHANGE_REASON_PLAYER_INIT or
                                 changeReason == CURRENCY_CHANGE_REASON_LOOT or
                                 changeReason == CURRENCY_CHANGE_REASON_PVP_KILL_TRANSFER or
                                 changeReason == CURRENCY_CHANGE_REASON_DEATH or
                                 changeReason == CURRENCY_CHANGE_REASON_BANK_FEE or
                                 (changeReason == CURRENCY_CHANGE_REASON_VENDOR and newTelvarStones < oldTelvarStones)
            
        if(not isExcludedReason) then
            PlaySound(SOUNDS.TELVAR_TRANSACT)
        end
    end

    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_MONEY_UPDATE, OnMoneyUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_TELVAR_STONE_UPDATE, OnTelvarStonesUpdated)

    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_PLAYER_ACTIVATED, OnFullInventoryUpdated)

    self:PerformFullUpdateOnQuestCache()
end

function ZO_SharedInventoryManager:RefreshInventory(bagId)
    if self:HasBagCache(bagId) then
        self:PerformFullUpdateOnBagCache(bagId)
        self:FireCallbacks("FullInventoryUpdate", bagId)
    end
end

function ZO_SharedInventoryManager:RefreshSingleSlot(bagId, slotIndex, isNewItem, itemSoundCategory, updateReason)
    if self:HasBagCache(bagId) then
        local bagCache = self:GetBagCache(bagId)
        self:HandleSlotCreationOrUpdate(bagCache, bagId, slotIndex, isNewItem)
    end 
end

-- where ... are bag ids to combined into a single data table
function ZO_SharedInventoryManager:GenerateFullSlotData(optFilterFunction, ...)
    self.refresh:UpdateRefreshGroups()

    local filteredItems = {}
    for i = 1, select("#", ...) do
        local bagId = select(i, ...)
        local bagCache = self:GetOrCreateBagCache(bagId)

        for slotIndex, itemData in pairs(bagCache) do
            if not optFilterFunction or optFilterFunction(itemData) then
                filteredItems[#filteredItems + 1] = itemData
            end
        end
    end

    return filteredItems
end

function ZO_SharedInventoryManager:GenerateSingleSlotData(bagId, slotIndex)
    self.refresh:UpdateRefreshGroups()

    local bagCache = self:GetOrCreateBagCache(bagId)
    if bagCache[slotIndex] then
        return bagCache[slotIndex]
    end
end

function ZO_SharedInventoryManager:IsFilteredSlotDataEmpty(optFilterFunction, ...)
    self.refresh:UpdateRefreshGroups()

    local numBagIds = select("#", ...)
    for i = 1, numBagIds do
        local bagId = select(i, ...)
        local bagCache = self:GetOrCreateBagCache(bagId)

        for slotIndex, itemData in pairs(bagCache) do
            if not optFilterFunction or optFilterFunction(itemData) then
                return false
            end
        end
    end

    return true
end

--Quest Items
function ZO_SharedInventoryManager:RefreshAllQuests()
    self:PerformFullUpdateOnQuestCache()
    self:FireCallbacks("FullQuestUpdate")
end

function ZO_SharedInventoryManager:RefreshSingleQuest(questIndex)
    self:PerformSingleUpdateOnQuestCache(questIndex)
    self:FireCallbacks("SingleQuestUpdate", questIndex)
end

function ZO_SharedInventoryManager:GenerateSingleQuestCache(questIndex)
    self.refresh:UpdateRefreshGroups()

    local singleQuestCache = self:GetOrCreateQuestCache(questIndex)
    if singleQuestCache then
        return singleQuestCache
    end
end

function ZO_SharedInventoryManager:GenerateFullQuestCache()
    self.refresh:UpdateRefreshGroups()
    
    for questIndex = 1, MAX_JOURNAL_QUESTS do
        self:GetOrCreateQuestCache(questIndex)
    end
    return self.questCache
end

-- Helper functions for new items
function ZO_SharedInventoryManager:AreAnyItemsNew(optFilterFunction, currentFilter, ...)
    self.refresh:UpdateRefreshGroups()

    for i = 1, select("#", ...) do
        local bagId = select(i, ...)
        local bagCache = self:GetOrCreateBagCache(bagId)

        for slotIndex, itemData in pairs(bagCache) do
            if itemData.brandNew and (not optFilterFunction or optFilterFunction(itemData, currentFilter)) then
                return true
            end
        end
    end

    return false
end

function ZO_SharedInventoryManager:ClearNewStatus(bagId, slotIndex)
    local slotData = self:GenerateSingleSlotData(bagId, slotIndex)
    if slotData then
        slotData.age = 0
        slotData.brandNew = nil
        self:RefreshStatusSortOrder(slotData)
    end
end

function ZO_SharedInventoryManager:IsItemNew(bagId, slotIndex)
    local slotData = self:GenerateSingleSlotData(bagId, slotIndex)
    if slotData then
        return slotData.brandNew
    end
    return false
end 

function ZO_SharedInventoryManager:GetItemUniqueId(bagId, slotIndex)
    local slotData = self:GenerateSingleSlotData(bagId, slotIndex)
    if slotData then
        return slotData.uniqueId
    end
end

--[[ Shared Guild Bank functions ]]--

function ZO_SharedInventory_SelectAccessibleGuildBank(lastSuccessfulGuildBankId)
    local validId
    local numGuilds = GetNumGuilds()
    for i = 1, numGuilds do
        local guildId = GetGuildId(i)
        local bankPermission = DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_BANK_DEPOSIT) or DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_BANK_WITHDRAW) or DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_BANK_WITHDRAW_GOLD)
        if(bankPermission) then
            if(lastSuccessfulGuildBankId == guildId) then
                SelectGuildBank(guildId)
                return
            elseif(validId == nil) then
                validId = guildId
            end            
        end
    end

    if(validId) then
        SelectGuildBank(validId)
    elseif(numGuilds > 0) then
        SelectGuildBank(GetGuildId(1))
    end
end

--[[ Private API ]]--
function ZO_SharedInventoryManager:GetOrCreateBagCache(bagId)
    if not self.bagCache[bagId] then
        self.bagCache[bagId] = {}
        self:PerformFullUpdateOnBagCache(bagId)
    end

    return self.bagCache[bagId]
end

function ZO_SharedInventoryManager:HasBagCache(bagId)
    return self.bagCache[bagId] ~= nil
end

function ZO_SharedInventoryManager:GetBagCache(bagId)
    return self.bagCache[bagId]
end

function ZO_SharedInventoryManager:PerformFullUpdateOnBagCache(bagId)
    local bagCache = self:GetBagCache(bagId)
    ZO_ClearTable(bagCache)

    local slotIndex = ZO_GetNextBagSlotIndex(bagId)
    while slotIndex do
        self:HandleSlotCreationOrUpdate(bagCache, bagId, slotIndex)
        slotIndex = ZO_GetNextBagSlotIndex(bagId, slotIndex)
    end
end

local SHARED_INVENTORY_SLOT_RESULT_REMOVED = 1
local SHARED_INVENTORY_SLOT_RESULT_ADDED = 2
local SHARED_INVENTORY_SLOT_RESULT_UPDATED = 3
local SHARED_INVENTORY_SLOT_RESULT_NO_CHANGE = 4
local SHARED_INVENTORY_SLOT_RESULT_REMOVE_AND_ADD = 5

function ZO_SharedInventoryManager:HandleSlotCreationOrUpdate(bagCache, bagId, slotIndex, isNewItem)
    local existingSlotData = bagCache[slotIndex]
    local slotData, result = self:CreateOrUpdateSlotData(existingSlotData, bagId, slotIndex, isNewItem)
    bagCache[slotIndex] = slotData

    if result == SHARED_INVENTORY_SLOT_RESULT_REMOVED then
        self:FireCallbacks("SlotRemoved", bagId, slotIndex, existingSlotData)
    elseif result == SHARED_INVENTORY_SLOT_RESULT_ADDED then
        self:FireCallbacks("SlotAdded", bagId, slotIndex, slotData)
    elseif result == SHARED_INVENTORY_SLOT_RESULT_UPDATED then
        self:FireCallbacks("SlotUpdated", bagId, slotIndex, slotData)
    elseif result == SHARED_INVENTORY_SLOT_RESULT_REMOVE_AND_ADD then
        self:FireCallbacks("SlotRemoved", bagId, slotIndex, existingSlotData)
        self:FireCallbacks("SlotAdded", bagId, slotIndex, slotData)
    end
end

function ZO_SharedInventoryManager:ComputeDynamicStatusMask(...)
    local value = 0
    local currentBitValue = 1
    for i = 1, select("#", ...) do
        if select(i, ...) then
            value = value + currentBitValue
        end
        currentBitValue = currentBitValue * 2
    end
    return value
end

function ZO_SharedInventoryManager:RefreshStatusSortOrder(slotData)
    slotData.statusSortOrder = self:ComputeDynamicStatusMask(slotData.isPlayerLocked, slotData.isGemmable, slotData.stolen, slotData.isBoPTradeable, slotData.brandNew)
end

function ZO_SharedInventoryManager:CreateOrUpdateSlotData(existingSlotData, bagId, slotIndex, isNewItem)
    local icon, stackCount, sellPrice, meetsUsageRequirement, locked, equipType, _, quality = GetItemInfo(bagId, slotIndex)
    local launderPrice = GetItemLaunderPrice(bagId, slotIndex)

    local hadItemInSlotBefore = false
    local wasSameItemInSlotBefore = false
    local hasItemInSlotNow = (stackCount > 0)
    local newItemInstanceId = hasItemInSlotNow and GetItemInstanceId(bagId, slotIndex) or nil

    local slot = existingSlotData

    if not slot then
        if hasItemInSlotNow then
            slot = {}
        end
    else
        hadItemInSlotBefore = slot.stackCount > 0
        wasSameItemInSlotBefore = hadItemInSlotBefore and hasItemInSlotNow and slot.itemInstanceId == newItemInstanceId
    end

    if not hasItemInSlotNow then
        if hadItemInSlotBefore then
            return nil, SHARED_INVENTORY_SLOT_RESULT_REMOVED
        end
        return nil, SHARED_INVENTORY_SLOT_RESULT_NO_CHANGE
    end

    local rawNameBefore = slot.rawName;
    slot.rawName = GetItemName(bagId, slotIndex)
    if rawNameBefore ~= slot.rawName then
        slot.name = zo_strformat(SI_TOOLTIP_ITEM_NAME, slot.rawName)
    end
    slot.requiredLevel = GetItemRequiredLevel(bagId, slotIndex)

    if not wasSameItemInSlotBefore then
        slot.itemType, slot.specializedItemType = GetItemType(bagId, slotIndex)
        slot.uniqueId = GetItemUniqueId(bagId, slotIndex)
    end
    
    slot.iconFile = icon
    slot.stackCount = stackCount
    slot.sellPrice = sellPrice
    slot.launderPrice = launderPrice
    slot.stackSellPrice = stackCount * sellPrice
    slot.stackLaunderPrice = stackCount * launderPrice
    slot.bagId = bagId
    slot.slotIndex = slotIndex
    slot.meetsUsageRequirement = meetsUsageRequirement or (bagId == BAG_WORN) --Items flagged equipped unique can only have one equipped, which means once they are
    slot.locked = locked                                                      --equipped they are no longer equippable, but we don't want to color these items red
    slot.quality = quality                                                    --in GamepadInventory once they are equipped, because that doesn't make any sense.
    slot.equipType = equipType
    slot.isPlayerLocked = IsItemPlayerLocked(bagId, slotIndex)
    slot.isBoPTradeable = IsItemBoPAndTradeable(bagId, slotIndex)
    slot.isJunk = IsItemJunk(bagId, slotIndex)
    slot.statValue = GetItemStatValue(bagId, slotIndex) or 0
    slot.itemInstanceId = newItemInstanceId
    slot.brandNew = isNewItem
    slot.stolen = IsItemStolen(bagId, slotIndex)
    slot.filterData = { GetItemFilterTypeInfo(bagId, slotIndex) }
    slot.condition = GetItemCondition(bagId, slotIndex)
    slot.isPlaceableFurniture = IsItemPlaceableFurniture(bagId, slotIndex)

    local isFromCrownCrate = IsItemFromCrownCrate(bagId, slotIndex)
    slot.isGemmable = false
    slot.requiredPerGemConversion = nil
    slot.gemsAwardedPerConversion = nil
    if isFromCrownCrate then
        local requiredPerGemConversion, gemsAwardedPerConversion = GetNumCrownGemsFromItemManualGemification(bagId, slotIndex)
        if requiredPerGemConversion > 0 and gemsAwardedPerConversion > 0 then
            slot.requiredPerGemConversion = requiredPerGemConversion
            slot.gemsAwardedPerConversion = gemsAwardedPerConversion
            slot.isGemmable = true
        end
    end

    slot.isFromCrownStore = IsItemFromCrownStore(bagId, slotIndex)

    if wasSameItemInSlotBefore and slot.age ~= 0 then
        -- don't modify the age, keep it the same relative sort - for now?
    elseif isNewItem then
        slot.age = GetFrameTimeSeconds()
    else
        slot.age = 0
    end

    self:RefreshStatusSortOrder(slot)

    if hadItemInSlotBefore then
        if isNewItem then
            return slot, SHARED_INVENTORY_SLOT_RESULT_REMOVE_AND_ADD
        else
            return slot, SHARED_INVENTORY_SLOT_RESULT_UPDATED
        end
    end

    return slot, SHARED_INVENTORY_SLOT_RESULT_ADDED
end

--Quest Items Private API--
function ZO_SharedInventoryManager:GetOrCreateQuestCache(questIndex)
    if not self.questCache[questIndex] then
        self:PerformSingleUpdateOnQuestCache(questIndex)
    end

    return self.questCache[questIndex]
end

function ZO_SharedInventoryManager:PerformFullUpdateOnQuestCache()
    ZO_ClearTable(self.questCache)
    for questIndex = 1, MAX_JOURNAL_QUESTS do
        self:PerformSingleUpdateOnQuestCache(questIndex)
    end
end

function ZO_SharedInventoryManager:PerformSingleUpdateOnQuestCache(questIndex)
    self.questCache[questIndex] = nil

    if(IsValidQuestIndex(questIndex)) then
        -- First update all the tools for the quest...
        for toolIndex = 1, GetQuestToolCount(questIndex) do
            local icon, stack, _, name, questItemId = GetQuestToolInfo(questIndex, toolIndex)
            self:CreateQuestData(icon, stack, questIndex, toolIndex, QUEST_MAIN_STEP_INDEX, nil, name, questItemId, SEARCH_TYPE_QUEST_TOOL)
        end

        -- Then update all the collectable items...
        for stepIndex = QUEST_MAIN_STEP_INDEX, GetJournalQuestNumSteps(questIndex) do
            for conditionIndex = 1, GetJournalQuestNumConditions(questIndex, stepIndex) do
                local icon, stack, name, questItemId = GetQuestItemInfo(questIndex, stepIndex, conditionIndex)
                self:CreateQuestData(icon, stack, questIndex, nil, stepIndex, conditionIndex, name, questItemId, SEARCH_TYPE_QUEST_ITEM)
            end
        end
    end
end

function ZO_SharedInventoryManager:CreateQuestData(iconFile, stackCount, questIndex, toolIndex, stepIndex, conditionIndex, name, questItemId, searchType)
    if(stackCount > 0) then
        local questCache = self.questCache

        --store all tools and items in a subtable under the questIndex for faster access
        if(not questCache[questIndex]) then
            questCache[questIndex] = {}
        end

        local questItems = questCache[questIndex]

        local questItem =
        {
            name            = zo_strformat(SI_TOOLTIP_ITEM_NAME, name),
            iconFile        = iconFile,
            stackCount      = stackCount,
            questIndex      = questIndex,
            toolIndex       = toolIndex,
            stepIndex       = stepIndex,
            conditionIndex  = conditionIndex,
            sellPrice       = 0,
            stackSellPrice  = 0,
            filterData      = { ITEMFILTERTYPE_QUEST },
            questItemId        = questItemId,
            age             = 0, -- 0 for now, probably need to come up with a way to make these appear new when appropriate.  maybe diffing what was there before with what's being added?
        }

        questItems[questItemId] = questItem
    end
end

SHARED_INVENTORY = ZO_SharedInventoryManager:New()

do
    local function UpdateMoney(currencyLabel, currencyOptions)
        ZO_CurrencyControl_SetSimpleCurrency(currencyLabel, CURT_MONEY, GetCarriedCurrencyAmount(CURT_MONEY), currencyOptions)
    end

    local function UpdateAlliancePoints(alliancePointsLabel, alliancePointsOptions)
        ZO_CurrencyControl_SetSimpleCurrency(alliancePointsLabel, CURT_ALLIANCE_POINTS, GetAlliancePoints(), alliancePointsOptions)
    end

    local function UpdateBankedMoney(currencyLabel, currencyOptions)
        ZO_CurrencyControl_SetSimpleCurrency(currencyLabel, CURT_MONEY, GetBankedMoney(), currencyOptions)
    end

    local function UpdateGuildBankedMoney(currencyLabel, currencyOptions)
        ZO_CurrencyControl_SetSimpleCurrency(currencyLabel, CURT_MONEY, GetGuildBankedMoney(), currencyOptions)
    end

    local function ConnectPlayerLabel(label, options, event, updateFnc)
        local dirty = true

        label:RegisterForEvent(event, function() 
            if label:IsHidden() then
                dirty = true
            else
                updateFnc(label, options)
                dirty = false
            end 
        end)

        local function CleanDirty()
            if dirty then
                dirty = false
                updateFnc(label, options)
            end
        end

        label:SetHandler("OnEffectivelyShown", CleanDirty)

        if not label:IsHidden() then
            CleanDirty()
        end
    end

    function ZO_SharedInventory_ConnectPlayerCurrencyLabel(currencyLabel, currencyOptions)
        ConnectPlayerLabel(currencyLabel, currencyOptions, EVENT_MONEY_UPDATE, UpdateMoney)
    end

    function ZO_SharedInventory_ConnectPlayerAlliancePointsLabel(alliancePointsLabel, alliancePointsOptions)
        ConnectPlayerLabel(alliancePointsLabel, alliancePointsOptions, EVENT_ALLIANCE_POINT_UPDATE, UpdateAlliancePoints)
    end

    function ZO_SharedInventory_ConnectBankedCurrencyLabel(currencyLabel, currencyOptions)
        ConnectPlayerLabel(currencyLabel, currencyOptions, EVENT_BANKED_MONEY_UPDATE, UpdateBankedMoney)
    end

    function ZO_SharedInventory_ConnectGuildBankedCurrencyLabel(currencyLabel, currencyOptions)
        ConnectPlayerLabel(currencyLabel, currencyOptions, EVENT_GUILD_BANKED_MONEY_UPDATE, UpdateGuildBankedMoney)
    end
end

-- Globals --

ZO_INVENTORY_STAT_GROUPS =
{
    {
        STAT_MAGICKA_MAX,
        STAT_MAGICKA_REGEN_COMBAT,
        STAT_HEALTH_MAX,
        STAT_HEALTH_REGEN_COMBAT,
        STAT_STAMINA_MAX,
        STAT_STAMINA_REGEN_COMBAT,
    },
    {
        STAT_SPELL_POWER,
        STAT_SPELL_CRITICAL,
        STAT_POWER,
        STAT_CRITICAL_STRIKE,
    },
    {
        STAT_SPELL_RESIST,
        STAT_PHYSICAL_RESIST,
        STAT_CRITICAL_RESISTANCE,
    },
}

--Used to take the variable returns from CompareBagItemToCurrentlyEquipped or CompareItemLinkToCurrentlyEquipped
-- and put them in a hash table for more covenient lookups
function ZO_GetStatDeltaLookupFromItemComparisonReturns(...)
    local statDeltaLookup = {}
    for i = 1, select("#", ...), 2 do
        local changedStat = select(i, ...)
        local changeAmount = select(i + 1, ...)
        statDeltaLookup[changedStat] = changeAmount
    end
    return statDeltaLookup
end

local EQUIP_SLOTS = 
{
    EQUIP_SLOT_HEAD,
    EQUIP_SLOT_NECK,
    EQUIP_SLOT_CHEST,
    EQUIP_SLOT_SHOULDERS,
    EQUIP_SLOT_MAIN_HAND,
    EQUIP_SLOT_OFF_HAND,
    EQUIP_SLOT_WAIST,
    EQUIP_SLOT_LEGS,
    EQUIP_SLOT_FEET,
    EQUIP_SLOT_COSTUME,
    EQUIP_SLOT_RING1,
    EQUIP_SLOT_RING2,
    EQUIP_SLOT_HAND,
    EQUIP_SLOT_BACKUP_MAIN,
    EQUIP_SLOT_BACKUP_OFF,
}

function ZO_Inventory_EnumerateEquipSlots(f)
    for _, slotId in ipairs(EQUIP_SLOTS) do
        local result = f(slotId)
        if(result ~= nil) then
            return result
        end
    end
end

function ZO_Inventory_TryStowAllMaterials()
    local backpackSlots = SHARED_INVENTORY:GetBagCache(BAG_BACKPACK)
    if backpackSlots then
        local hadGemmableMaterial = false
        for slotIndex, slotData in pairs(backpackSlots) do
            if slotData.isGemmable and not slotData.stolen and CanItemBeVirtual(BAG_BACKPACK, slotIndex) then
                hadGemmableMaterial = true
                break
            end
        end

        if hadGemmableMaterial then
            ZO_Dialogs_ShowPlatformDialog("CONFIRM_STOW_ALL_GEMIFIABLE")
        else
            StowAllVirtualItems()
        end
    end
end