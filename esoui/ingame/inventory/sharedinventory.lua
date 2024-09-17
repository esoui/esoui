ZO_TRADE_BOP_ICON = "EsoUI/Art/Inventory/inventory_Tradable_icon.dds"
ZO_IN_ARMORY_BUILD_ICON = "EsoUI/Art/Armory/buildItem_icon.dds"

ZO_SharedInventoryManager = ZO_InitializingCallbackObject:Subclass()

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

    local function OnItemCombinationResult(_, itemCombinationResult)
        if itemCombinationResult == ITEM_COMBINATION_RESULT_SUCCESS then
            -- Combinations play an animation on success, hide UI so the player can see it
            SCENE_MANAGER:SetInUIMode(false)
        end
    end
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_ITEM_COMBINATION_RESULT, OnItemCombinationResult)

    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_OPEN_FENCE, function()
        self:RefreshInventory(BAG_BACKPACK)
        self:RefreshInventory(BAG_WORN)
        self.backpackRefreshedWithFenceData = true
    end)

    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_CLOSE_STORE, function()
        if self.backpackRefreshedWithFenceData then
            self:RefreshInventory(BAG_BACKPACK)
            self:RefreshInventory(BAG_WORN)
            self.backpackRefreshedWithFenceData = nil
        end
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
            self:RefreshInventory(BAG_SUBSCRIBER_BANK)
            for bag = BAG_HOUSE_BANK_ONE, BAG_HOUSE_BANK_TEN do
                self:RefreshInventory(bag)
            end
            self:RefreshInventory(BAG_COMPANION_WORN)
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

    local function OnInventorySlotUpdated(eventCode, bagId, slotIndex, isNewItem, itemSoundCategory, updateReason, stackCountChangeAmount, repairedByCharacterName, repairedByDisplayName, isLastUpdateForMessage)
        if updateReason == INVENTORY_UPDATE_REASON_DURABILITY_CHANGE then
            local newCondition = GetItemCondition(bagId, slotIndex)
            if newCondition == 100 then
                self:FireCallbacks("ItemRepaired", bagId, slotIndex)
            end
        end

        local previousSlotData = self:GetPreviousSlotDataInternal(bagId, slotIndex)

        self.refresh:RefreshSingle("inventory", bagId, slotIndex, isNewItem, itemSoundCategory, updateReason, isLastUpdateForMessage)

        -- ESO-718084: Mark the search as dirty if the slot update includes a change in stack count to handle the refreshing the search when a stack of items is split while being searched on.
        if stackCountChangeAmount ~= 0 then
            local shouldSuppressSearch = (not isLastUpdateForMessage) or IsInGamepadPreferredMode()
            TEXT_SEARCH_MANAGER:MarkDirtyByFilterTargetAndPrimaryKey(BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, bagId, shouldSuppressSearch)
        end

        if bagId == BAG_BACKPACK or bagId == BAG_VIRTUAL then
            if isNewItem and GetCraftingInteractionType() == CRAFTING_TYPE_INVALID and not SYSTEMS:IsShowing("crownCrate") then
                PlayItemSound(itemSoundCategory, ITEM_SOUND_ACTION_ACQUIRE)
            end
        elseif GetInteractionType() == INTERACTION_BANK and bagId == BAG_BANK then
            PlayItemSound(itemSoundCategory, ITEM_SOUND_ACTION_SLOT)
        end

        if updateReason == INVENTORY_UPDATE_REASON_DEFAULT and (bagId == BAG_WORN or (bagId == BAG_COMPANION_WORN and HasActiveCompanion())) then
            local slotHasItem = GetWornItemInfo(bagId, slotIndex)
            if slotHasItem then
                PlayItemSound(itemSoundCategory, ITEM_SOUND_ACTION_EQUIP)
            else
                PlayItemSound(itemSoundCategory, ITEM_SOUND_ACTION_UNEQUIP)
            end
        elseif updateReason == INVENTORY_UPDATE_REASON_DURABILITY_CHANGE and bagId == BAG_WORN then
            local effectivenessReduced = IsArmorEffectivenessReduced(bagId, slotIndex)
            if effectivenessReduced then
                TriggerTutorial(TUTORIAL_TRIGGER_DAMAGED_EQUIPMENT_REDUCING_EFFECTIVENESS)
            end
        end

        self:FireCallbacks("SingleSlotInventoryUpdate", bagId, slotIndex, previousSlotData, isLastUpdateForMessage)
    end

    local function RefreshInventoryOnGuildChange()
        self:RefreshInventory(BAG_BACKPACK)
        self:RefreshInventory(BAG_WORN)
    end

    local function OnGuildBankUpdated()
        self.refresh:RefreshAll("guild_bank")
        self:FireCallbacks("FullInventoryUpdate", BAG_GUILDBANK)
    end

    local function RefreshInventoryOnBuildSaveResponse(eventCode, result, buildIndex)
        if result == ARMORY_BUILD_SAVE_RESULT_SUCCESS then
            self.refresh:RefreshAll("inventory")
        end
    end

    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_INVENTORY_FULL_UPDATE, OnFullInventoryUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventorySlotUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_GUILD_SELF_JOINED_GUILD, RefreshInventoryOnGuildChange)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_GUILD_SELF_LEFT_GUILD, RefreshInventoryOnGuildChange)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_ARMORY_BUILD_SAVE_RESPONSE, RefreshInventoryOnBuildSaveResponse)

    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_OPEN_GUILD_BANK, OnGuildBankUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_CLOSE_GUILD_BANK, OnGuildBankUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_GUILD_BANK_SELECTED, OnGuildBankUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_GUILD_BANK_DESELECTED, OnGuildBankUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_GUILD_BANK_ITEMS_READY, OnGuildBankUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_GUILD_BANK_OPEN_ERROR, OnGuildBankUpdated)

    local function OnGuildBankInventorySlotUpdated(eventCode, slotIndex, updatedByLocalPlayer, itemSoundCategory, isLastUpdateForMessage)
        local previousSlotData = self:GetPreviousSlotDataInternal(BAG_GUILDBANK, slotIndex)
        local NO_UPDATE_REASON = nil
        local NOT_NEW_ITEM = nil
        self.refresh:RefreshSingle("inventory", BAG_GUILDBANK, slotIndex, NOT_NEW_ITEM, itemSoundCategory, NO_UPDATE_REASON, isLastUpdateForMessage)

        if isLastUpdateForMessage then
            self.refresh:UpdateRefreshGroups()
        end

        if updatedByLocalPlayer and GetInteractionType() == INTERACTION_GUILDBANK then
            PlayItemSound(itemSoundCategory, ITEM_SOUND_ACTION_SLOT)
        end

        self:FireCallbacks("SingleSlotInventoryUpdate", BAG_GUILDBANK, slotIndex, previousSlotData, isLastUpdateForMessage)
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
        local wasInitialize = reason == CURRENCY_CHANGE_REASON_PLAYER_INIT
        local wasItemPurchased = reason == CURRENCY_CHANGE_REASON_VENDOR and newMoney < oldMoney

        if not (wasItemPurchased or wasInitialize) then
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

        if not isExcludedReason then
            PlaySound(SOUNDS.TELVAR_TRANSACT)
        end
    end

    local function OnEventTicketUpdated(eventCode, newEventTickets, difference, changeReason)
        if changeReason == CURRENCY_CHANGE_REASON_LOOT and difference > 0 then
            PlaySound(SOUNDS.EVENT_TICKET_ACQUIRE)
        end
    end

    local function OnEndlessDungeonCurrencyUpdated(newAmount, oldAmount, changeReason)
        if changeReason == CURRENCY_CHANGE_REASON_LOOT and newAmount > oldAmount then
            PlaySound(SOUNDS.ARCHIVAL_FORTUNES_ACQUIRE)
        end
    end

    local function OnImperialFragmentCurrencyUpdated(newAmount, oldAmount, changeReason)
        if changeReason == CURRENCY_CHANGE_REASON_LOOT and newAmount > oldAmount then
            PlaySound(SOUNDS.IMPERIAL_FRAGMENT_ACQUIRE)
        end
    end

    local function OnCurrencyUpdated(_, currencyType, currencyLocation, newAmount, oldAmount, changeReason)
        if currencyType == CURT_ARCHIVAL_FORTUNES then
            OnEndlessDungeonCurrencyUpdated(newAmount, oldAmount, changeReason)
        elseif currencyType == CURT_IMPERIAL_FRAGMENT then
            OnImperialFragmentCurrencyUpdated(newAmount, oldAmount, changeReason)
        end
        internalassert(CURT_MAX_VALUE == 13, "Check if new currency requires unique acquire sound hook or other behavior")
        -- TODO: Consider moving other above function calls here to register for less functions, investigate if any issues would arise
    end


    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_MONEY_UPDATE, OnMoneyUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_TELVAR_STONE_UPDATE, OnTelvarStonesUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_EVENT_TICKET_UPDATE, OnEventTicketUpdated)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_CURRENCY_UPDATE, OnCurrencyUpdated)

    local function OnSmithingTraitResearch()
        self:RefreshAllTraitInformation()
    end

    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_SMITHING_TRAIT_RESEARCH_CANCELED, OnSmithingTraitResearch)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_SMITHING_TRAIT_RESEARCH_STARTED, OnSmithingTraitResearch)

    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_PLAYER_ACTIVATED, OnFullInventoryUpdated)

    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_NON_COMBAT_BONUS_CHANGED, function(event, nonCombatBonusType)
        if nonCombatBonusType == NON_COMBAT_BONUS_MERCHANT_HAGGLING then
            OnFullInventoryUpdated()
        end
    end)

    local inventoryFilterTargetDescriptor =
    {
        [BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT] =
        {
            searchFilterList =
            {
                BACKGROUND_LIST_FILTER_TYPE_NAME,
            },
            primaryKeys =
            {
                BAG_WORN,
                BAG_BACKPACK,
                BAG_VIRTUAL,
            }
        },
        [BACKGROUND_LIST_FILTER_TARGET_QUEST_ITEM_ID] =
        {
            searchFilterList =
            {
                BACKGROUND_LIST_FILTER_TYPE_NAME,
            },
            primaryKeys = ZO_FilterTargetDescriptor_GetQuestItemIdList,
        },
    }
    TEXT_SEARCH_MANAGER:SetupContextTextSearch("playerInventoryTextSearch", inventoryFilterTargetDescriptor)

    self:RegisterForConfirmUseItemEvents(namespace)

    self:PerformFullUpdateOnQuestCache()
end

function ZO_SharedInventoryManager:RegisterForConfirmUseItemEvents(namespace)
    local function AcceptEvolutionCallback()
        RespondToConfirmUseInventoryItemRequest(true)
    end

    local function DeclineEvolutionCallback()
        RespondToConfirmUseInventoryItemRequest(false)
    end

    local function OnRequestConfirmUseItem(eventCode, bag, slot)
        local onUseType = GetItemUseType(bag, slot)
        if onUseType == ITEM_USE_TYPE_COMBINATION then
            local combinationId = GetItemCombinationId(bag, slot)
            if GetCombinationNumNonFragmentCollectibleComponents(combinationId) > 0 then
                ZO_CombinationPromptManager_ShowAppropriateCombinationPrompt(baseCollectibleId, combinationId, AcceptEvolutionCallback, DeclineEvolutionCallback)
                return
            end
        end

        -- right now only items that evolve collectibles need confirmation
        -- so if it's not one of those, automatically accept using the item
        RespondToConfirmUseInventoryItemRequest(true)
    end

    local function OnCancelConfirmUseItem()
        ZO_CombinationPromptManager_ClearAllCombinationPrompts()
    end

    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_REQUEST_CONFIRM_USE_ITEM, OnRequestConfirmUseItem)
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_CANCEL_REQUEST_CONFIRM_USE_ITEM, OnCancelConfirmUseItem)
end

function ZO_SharedInventoryManager:RefreshInventory(bagId)
    if self:HasBagCache(bagId) then
        self:PerformFullUpdateOnBagCache(bagId)
    end
end

function ZO_SharedInventoryManager:RefreshSingleSlot(bagId, slotIndex, isNewItem, itemSoundCategory, updateReason, isLastUpdateForMessage)
    if self:HasBagCache(bagId) then
        local bagCache = self:GetBagCache(bagId)
        self:HandleSlotCreationOrUpdate(bagCache, bagId, slotIndex, isNewItem, isLastUpdateForMessage)
    end 
end

-- where ... are bag ids to combined into a single data table
function ZO_SharedInventoryManager:GenerateFullSlotData(optFilterFunction, ...)
    self.refresh:UpdateRefreshGroups()

    local filteredItems = {}
    for i = 1, select("#", ...) do
        local bagId = select(i, ...)
        local bagCache = self:GetOrCreateBagCache(bagId)

        for _, itemData in pairs(bagCache) do
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

        for _, itemData in pairs(bagCache) do
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

-- Trait Information Update
function ZO_SharedInventoryManager:RefreshAllTraitInformation()
    -- Refresh all bags where weapons and armor can reside
    self:RefreshBagTraitInformation(BAG_BACKPACK)
    self:RefreshBagTraitInformation(BAG_WORN)
    self:RefreshBagTraitInformation(BAG_BANK)
    self:RefreshBagTraitInformation(BAG_SUBSCRIBER_BANK)
end

function ZO_SharedInventoryManager:RefreshBagTraitInformation(bagId)
    if self:HasBagCache(bagId) then
        local bagCache = self:GetBagCache(bagId)

        for slotIndex in ZO_IterateBagSlots(bagId) do
            local existingData = bagCache[slotIndex]
            if existingData then
                local newItemTraitInformation = GetItemTraitInformation(bagId, slotIndex)
                local newItemSellInformation = GetItemSellInformation(bagId, slotIndex)
                if existingData.traitInformation ~= newItemTraitInformation or existingData.sellInformation ~= newItemSellInformation then
                    local previousSlotData = self:GetPreviousSlotDataInternal(bagId, slotIndex)
                    existingData.traitInformation = newItemTraitInformation
                    existingData.traitInformationSortOrder = ZO_GetItemTraitInformation_SortOrder(existingData.traitInformation)
                    existingData.sellInformation = newItemSellInformation
                    existingData.sellInformationSortOrder = ZO_GetItemSellInformationCustomSortOrder(existingData.sellInformation)
                    self:FireCallbacks("SingleSlotInventoryUpdate", bagId, slotIndex, previousSlotData)
                end
            end
        end
    end
end

-- Helper functions for new items
function ZO_SharedInventoryManager:AreAnyItemsNew(optFilterFunction, currentFilter, ...)
    self.refresh:UpdateRefreshGroups()

    for i = 1, select("#", ...) do
        local bagId = select(i, ...)
        local bagCache = self:GetOrCreateBagCache(bagId)

        for _, itemData in pairs(bagCache) do
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

function ZO_SharedInventoryManager:GetHouseBankingBagName(bankingBag)
    local interactName = GetUnitName("interact")
    local collectibleId = GetCollectibleForHouseBankBag(bankingBag)
    local nickname
    if collectibleId ~= 0 then
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
        if collectibleData then
            nickname = collectibleData:GetNickname()
        end
    end

    return interactName, nickname
end

--[[ Shared Guild Bank functions ]]--

function ZO_SharedInventory_SelectAccessibleGuildBank(lastSuccessfulGuildBankId)
    local validId
    local numGuilds = GetNumGuilds()
    for i = 1, numGuilds do
        local guildId = GetGuildId(i)
        if(lastSuccessfulGuildBankId == guildId) then
            SelectGuildBank(guildId)
            return
        elseif(validId == nil) then
            validId = guildId
        end
    end

    if validId then
        SelectGuildBank(validId)
    elseif numGuilds > 0 then
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

    for slotIndex in ZO_IterateBagSlots(bagId) do
        local NOT_NEW_ITEM = false
        local IS_LAST_UPDATE = true
        self:HandleSlotCreationOrUpdate(bagCache, bagId, slotIndex, NOT_NEW_ITEM, IS_LAST_UPDATE)
    end

    self:FireCallbacks("FullInventoryUpdate", bagId)
end

local SHARED_INVENTORY_SLOT_RESULT_REMOVED = 1
local SHARED_INVENTORY_SLOT_RESULT_ADDED = 2
local SHARED_INVENTORY_SLOT_RESULT_UPDATED = 3
local SHARED_INVENTORY_SLOT_RESULT_NO_CHANGE = 4
local SHARED_INVENTORY_SLOT_RESULT_REMOVE_AND_ADD = 5

function ZO_SharedInventoryManager:HandleSlotCreationOrUpdate(bagCache, bagId, slotIndex, isNewItem, isLastUpdateForMessage)
    local existingSlotData = bagCache[slotIndex]
    local slotData, result = self:CreateOrUpdateSlotData(existingSlotData, bagId, slotIndex, isNewItem)
    bagCache[slotIndex] = slotData

    local suppressItemUpdate = not isLastUpdateForMessage
    if result == SHARED_INVENTORY_SLOT_RESULT_REMOVED then
        self:FireCallbacks("SlotRemoved", bagId, slotIndex, existingSlotData, suppressItemUpdate)
    elseif result == SHARED_INVENTORY_SLOT_RESULT_ADDED then
        self:FireCallbacks("SlotAdded", bagId, slotIndex, slotData, suppressItemUpdate)
    elseif result == SHARED_INVENTORY_SLOT_RESULT_UPDATED then
        self:FireCallbacks("SlotUpdated", bagId, slotIndex, slotData, suppressItemUpdate)
    elseif result == SHARED_INVENTORY_SLOT_RESULT_REMOVE_AND_ADD then
        self:FireCallbacks("SlotRemoved", bagId, slotIndex, existingSlotData, suppressItemUpdate)
        self:FireCallbacks("SlotAdded", bagId, slotIndex, slotData, suppressItemUpdate)
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
    slotData.statusSortOrder = self:ComputeDynamicStatusMask(slotData.isPlayerLocked, slotData.isGemmable, slotData.stolen, slotData.isBoPTradeable, slotData.isInArmory, slotData.brandNew, slotData.bagId == BAG_WORN)
end

function ZO_SharedInventoryManager:CreateOrUpdateSlotData(existingSlotData, bagId, slotIndex, isNewItem)
    local icon, stackCount, sellPrice, meetsUsageRequirement, locked, equipType, _, functionalQuality, displayQuality = GetItemInfo(bagId, slotIndex)
    local launderPrice = GetItemLaunderPrice(bagId, slotIndex)

    local hadItemInSlotBefore = false
    local wasSameItemInSlotBefore = false
    local hasItemInSlotNow = stackCount > 0
    local newUniqueId = hasItemInSlotNow and GetItemUniqueId(bagId, slotIndex) or nil

    local slot = existingSlotData

    if not slot then
        if hasItemInSlotNow then
            slot = {}
        end
    else
        hadItemInSlotBefore = slot.stackCount > 0
        wasSameItemInSlotBefore = hadItemInSlotBefore and hasItemInSlotNow and slot.uniqueId == newUniqueId
    end

    if not hasItemInSlotNow then
        if hadItemInSlotBefore then
            return nil, SHARED_INVENTORY_SLOT_RESULT_REMOVED
        end
        return nil, SHARED_INVENTORY_SLOT_RESULT_NO_CHANGE
    end

    local rawNameBefore = slot.rawName
    slot.rawName = GetItemName(bagId, slotIndex)
    if rawNameBefore ~= slot.rawName then
        slot.name = zo_strformat(SI_TOOLTIP_ITEM_NAME, slot.rawName)
    end
    slot.requiredLevel = GetItemRequiredLevel(bagId, slotIndex)
    slot.requiredChampionPoints = GetItemRequiredChampionPoints(bagId, slotIndex)

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
    -- Items flagged equipped unique can only have one equipped, which means once they are
    -- equipped they are no longer equippable, but we don't want to color these items red
    -- in GamepadInventory once they are equipped, because that doesn't make any sense.
    slot.meetsUsageRequirement = meetsUsageRequirement or (bagId == BAG_WORN)
    slot.locked = locked
    slot.functionalQuality = functionalQuality
    slot.displayQuality = displayQuality
    -- slot.quality is deprecated, included here for addon backwards compatibility
    slot.quality = displayQuality
    slot.equipType = equipType
    slot.isPlayerLocked = IsItemPlayerLocked(bagId, slotIndex)
    slot.isBoPTradeable = IsItemBoPAndTradeable(bagId, slotIndex)
    slot.isJunk = IsItemJunk(bagId, slotIndex)
    slot.statValue = GetItemStatValue(bagId, slotIndex) or 0
    slot.itemInstanceId = GetItemInstanceId(bagId, slotIndex) or nil
    slot.brandNew = isNewItem
    slot.stolen = IsItemStolen(bagId, slotIndex)
    slot.filterData = { GetItemFilterTypeInfo(bagId, slotIndex) }
    slot.condition = GetItemCondition(bagId, slotIndex)
    slot.isPlaceableFurniture = IsItemPlaceableFurniture(bagId, slotIndex)
    slot.traitInformation = GetItemTraitInformation(bagId, slotIndex)
    slot.traitInformationSortOrder = ZO_GetItemTraitInformation_SortOrder(slot.traitInformation)
    slot.sellInformation = GetItemSellInformation(bagId, slotIndex)
    slot.sellInformationSortOrder = ZO_GetItemSellInformationCustomSortOrder(slot.sellInformation)
    slot.actorCategory = GetItemActorCategory(bagId, slotIndex)
    --Don't bother checking for guild bank or buyback because we don't care in those cases
    --In the case of the craft bag or companion worn bag, it isn't possible for a build item to live there, so we can just immediately infer false
    if bagId == BAG_GUILDBANK or bagId == BAG_BUYBACK or bagId == BAG_VIRTUAL or bagId == BAG_COMPANION_WORN then
        slot.isInArmory = false
    else
        slot.isInArmory = IsItemInArmory(bagId, slotIndex)
    end

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
        -- Age is only set to 0 before this point from ClearNewStatus, so if brandNew is false
        -- but age isn't 0, something has tried to set brandNew to false without calling ClearNewStatus,
        -- so we can still rely on it actually being new.
        slot.brandNew = true
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
            self:CreateQuestData(icon, stack, questIndex, toolIndex, QUEST_MAIN_STEP_INDEX, nil, name, questItemId)
        end

        -- Then update all the collectable items...
        for stepIndex = QUEST_MAIN_STEP_INDEX, GetJournalQuestNumSteps(questIndex) do
            for conditionIndex = 1, GetJournalQuestNumConditions(questIndex, stepIndex) do
                local icon, stack, name, questItemId = GetQuestItemInfo(questIndex, stepIndex, conditionIndex)
                self:CreateQuestData(icon, stack, questIndex, nil, stepIndex, conditionIndex, name, questItemId)
            end
        end
    end
end

function ZO_SharedInventoryManager:CreateQuestData(iconFile, stackCount, questIndex, toolIndex, stepIndex, conditionIndex, name, questItemId)
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
            questItemId     = questItemId,
            age             = 0, -- 0 for now, probably need to come up with a way to make these appear new when appropriate.  maybe diffing what was there before with what's being added?
        }

        if CanQuickslotQuestItemById(questItemId) then
            table.insert(questItem.filterData, ITEMFILTERTYPE_QUEST_QUICKSLOT)
        end

        questItems[questItemId] = questItem
    end
end

SHARED_INVENTORY = ZO_SharedInventoryManager:New()

do
    local SHOW_ALL = true
    local HAS_ENOUGH = false
    function ZO_SharedInventory_ConnectPlayerCurrencyLabel(label, currencyType, currencyLocation, currencyOptions, showCap)
        local dirty = true

        local displayOptions = {}

        if showCap and IsCurrencyCapped(currencyType, currencyLocation) then
            displayOptions.currencyCapAmount = GetMaxPossibleCurrency(currencyType, currencyLocation)
        end

        label:RegisterForEvent(EVENT_CURRENCY_UPDATE, function(eventId, eventCurrencyType, eventCurrencyLocation, newAmount, oldAmount, reason)
            if eventCurrencyType == currencyType and eventCurrencyLocation == currencyLocation then
                if label:IsHidden() then
                    dirty = true
                else
                    dirty = false
                    ZO_CurrencyControl_SetSimpleCurrency(label, currencyType, newAmount, currencyOptions, SHOW_ALL, HAS_ENOUGH, displayOptions)
                end
            end
        end)

        local function CleanDirty()
            if dirty then
                dirty = false
                ZO_CurrencyControl_SetSimpleCurrency(label, currencyType, GetCurrencyAmount(currencyType, currencyLocation), currencyOptions, SHOW_ALL, HAS_ENOUGH, displayOptions)
            end
        end

        label:SetHandler("OnEffectivelyShown", CleanDirty)

        if not label:IsHidden() then
            CleanDirty()
        end
    end
end

-- Internal Use Only
function ZO_SharedInventoryManager:GetPreviousSlotDataInternal(bagId, slotIndex)
    local bagCache = self:GetBagCache(bagId)
    if bagCache then
        local previousSlotData = bagCache[slotIndex]
        --Since the inventory can update the existing slot table to a new item we need to make a copy of the old data
        if previousSlotData then
            previousSlotData = ZO_ShallowTableCopy(previousSlotData)
        end
        return previousSlotData
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
        STAT_SPELL_PENETRATION,
        STAT_POWER,
        STAT_CRITICAL_STRIKE,
        STAT_PHYSICAL_PENETRATION,
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

do
    -- if this triggers, need to add new trait information to this arbitrary sort order
    internalassert(ITEM_TRAIT_INFORMATION_MAX_VALUE == 5)

    local ITEM_TRAIT_INFORMATION_SORT_ORDER =
    {
        [ITEM_TRAIT_INFORMATION_INTRICATE] = 0,
        [ITEM_TRAIT_INFORMATION_NONE] = 1,
        [ITEM_TRAIT_INFORMATION_CAN_BE_RESEARCHED] = 2,
        [ITEM_TRAIT_INFORMATION_RETRAITED] = 3,
        [ITEM_TRAIT_INFORMATION_RECONSTRUCTED] = 4,
        [ITEM_TRAIT_INFORMATION_ORNATE] = 5,
    }

    function ZO_GetItemTraitInformation_SortOrder(traitInfo)
        return ITEM_TRAIT_INFORMATION_SORT_ORDER[traitInfo]
    end
end

do
    -- if this triggers, need to add new sell information to this arbitrary sort order
    internalassert(ITEM_SELL_INFORMATION_MAX_VALUE == 5)

    local ITEM_SELL_INFORMATION_SORT_ORDER =
    {
        [ITEM_SELL_INFORMATION_PRIORITY_SELL] = 0,
        [ITEM_SELL_INFORMATION_NONE] = 1,
        [ITEM_SELL_INFORMATION_CAN_BE_RESEARCHED] = 2,
        [ITEM_SELL_INFORMATION_INTRICATE] = 3,
        [ITEM_SELL_INFORMATION_RECONSTRUCTED] = 4,
        [ITEM_SELL_INFORMATION_CANNOT_SELL] = 5,
    }

    function ZO_GetItemSellInformationCustomSortOrder(sellInformation)
        return ITEM_SELL_INFORMATION_SORT_ORDER[sellInformation]
    end
end