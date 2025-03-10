ZO_LOOT_HISTORY_NAME = "ZO_LootHistory"

--
--[[ LootHistory_Manager ]]--
--

-- TODO: change into a callback object so that we don't have to keep using systems for the callback functions
local LootHistory_Manager = ZO_Object:Subclass()

function LootHistory_Manager:New(...)
    local lootHistory = ZO_Object.New(self)
    lootHistory:Initialize(...)
    return lootHistory
end

local function CanAddLootEntry()
    return tonumber(GetSetting(SETTING_TYPE_LOOT,LOOT_SETTING_LOOT_HISTORY)) == 1
end

function LootHistory_Manager:Initialize()
    local function OnNewItemReceived(...)
        if CanAddLootEntry() then
            SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnNewItemReceived(...)
        end
    end

    local function OnNewCollectibleReceived(notificationId, collectibleId)
        if CanAddLootEntry() then
            SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnNewCollectibleReceived(collectibleId)
        end
    end

    local function OnCurrencyUpdate(currencyType, currencyLocation, newAmount, oldAmount, reason, reasonInfo)
        if CanAddLootEntry() then
            SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnCurrencyUpdate(currencyType, currencyLocation, newAmount, oldAmount, reason, reasonInfo)
        end

        if reason == CURRENCY_CHANGE_REASON_DEFENSIVE_KEEP_REWARD or reason == CURRENCY_CHANGE_REASON_OFFENSIVE_KEEP_REWARD then
            if CanAddLootEntry() then
                SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnKeepTickAwarded(reasonInfo, reason)
            end
        end
    end

    local function OnPendingCurrencyRewardCached(currencyType, currencyLocation, delta, reason, reasonInfo)
        local newAmount = delta
        local oldAmount = 0
        OnCurrencyUpdate(currencyType, currencyLocation, newAmount, oldAmount, reason, reasonInfo)
    end

    -- reason, level (unused), previousExperience, currentExperience
    local function OnExperienceGainUpdate(...)
        if CanAddLootEntry() then
            SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnExperienceGainUpdate(...)
        end
    end

    local function OnPendingExperienceRewardCached(reason, amount)
        local UNUSED_LEVEL = nil
        local previousExperience = 0
        local currentExperience = amount
        OnExperienceGainUpdate(reason, UNUSED_LEVEL, previousExperience, currentExperience)
    end

    local function OnMedalAwarded(...)
        if CanAddLootEntry() then
            SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnMedalAwarded(...)
        end
    end

    local function OnBattlegroundStateChanged(oldState, newState)
        if CanAddLootEntry() then
            if newState == BATTLEGROUND_STATE_FINISHED then
                SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnBattlegroundEnteredPostGame()
            end
        end
    end

    local function OnInventorySlotUpdate(bagId, slotId, isNewItem, itemSound, inventoryUpdateReason, stackCountChange, _, _, _, bonusDropSource)
        -- This includes any inventory item update, only display if the item was new
        if isNewItem and stackCountChange > 0 then
            local itemLink = GetItemLink(bagId, slotId)

            -- cover the case where we got an inventory item update but then the item got whisked away somewhere else
            -- before we had a chance to get the info out of it
            if itemLink ~= nil and itemLink ~= "" then
                local lootType = LOOT_TYPE_ITEM
                local itemId = GetItemInstanceId(bagId, slotId)
                local isVirtual = bagId == BAG_VIRTUAL
                local isStolen = IsItemStolen(bagId, slotId)
                local NO_QUEST_ITEM_ICON = nil
                OnNewItemReceived(itemLink, stackCountChange, itemSound, lootType, NO_QUEST_ITEM_ICON, itemId, isVirtual, isStolen, bonusDropSource)
            end
        end
    end

    local function OnQuestToolUpdate(questIndex, questName, countDelta, questItemIcon, questItemId, questItemName)
        if countDelta > 0 then
            local NO_ITEM_SOUND = nil
            local IS_NOT_VIRTUAL = false
            local IS_NOT_STOLEN = false
            OnNewItemReceived(questItemName, countDelta, NO_ITEM_SOUND, LOOT_TYPE_QUEST_ITEM, questItemIcon, questItemId, IS_NOT_VIRTUAL, IS_NOT_STOLEN, BONUS_DROP_SOURCE_NONE)
        end
    end

    local function OnSkillExperienceUpdated(...)
        if CanAddLootEntry() then
            SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnSkillExperienceUpdated(...)
        end
    end

    local function OnCrownCrateQuantityUpdate(lootCrateId, newCount, oldCount)
        if CanAddLootEntry() then
            SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnCrownCrateQuantityUpdated(lootCrateId, oldCount, newCount)
        end
    end

    local function OnAntiquityLeadAcquired(antiquityId)
        if CanAddLootEntry() then
            SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnAntiquityLeadAcquired(antiquityId)
        end
    end

    local function OnCompanionExperienceGainUpdate(...)
        if CanAddLootEntry() then
            SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnCompanionExperienceGainUpdate(...)
        end
    end

    local function OnCompanionRapportUpdate(...)
        if CanAddLootEntry() then
            SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnCompanionRapportUpdate(...)
        end
    end

    local function OnTributeProgressionUpgradeStatusChanged(...)
        if CanAddLootEntry() then
            SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnTributeProgressionUpgradeStatusChanged(...)
        end
    end

    EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, function(eventId, ...) OnInventorySlotUpdate(...) end)
    EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_CURRENCY_UPDATE, function(eventId, ...) OnCurrencyUpdate(...) end)
    EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_PENDING_CURRENCY_REWARD_CACHED, function(eventId, ...) OnPendingCurrencyRewardCached(...) end)
    EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_EXPERIENCE_GAIN, function(eventId, ...) OnExperienceGainUpdate(...) end)
    EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_PENDING_EXPERIENCE_REWARD_CACHED, function(eventId, ...) OnPendingExperienceRewardCached(...) end)
    EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_QUEST_TOOL_UPDATED, function(eventId, ...) OnQuestToolUpdate(...) end)
    EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_MEDAL_AWARDED, function(eventId, ...) OnMedalAwarded(...) end)
    EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_BATTLEGROUND_STATE_CHANGED, function(eventId, ...) OnBattlegroundStateChanged(...) end)
    EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_CROWN_CRATE_QUANTITY_UPDATE, function(eventId, ...) OnCrownCrateQuantityUpdate(...) end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleNotificationNew", function(...) OnNewCollectibleReceived(...) end)
    EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_SKILL_XP_UPDATE, function(eventId, ...) OnSkillExperienceUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_ANTIQUITY_LEAD_ACQUIRED, function(eventId, ...) OnAntiquityLeadAcquired(...) end)
    EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_COMPANION_EXPERIENCE_GAIN, function(eventId, ...) OnCompanionExperienceGainUpdate(...) end)
    EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_COMPANION_RAPPORT_UPDATE, function(eventId, ...) OnCompanionRapportUpdate(...) end)
    TRIBUTE_DATA_MANAGER:RegisterCallback("ProgressionUpgradeStatusChanged", function(...) OnTributeProgressionUpgradeStatusChanged(...) end)
end

ZO_LOOT_HISTORY_MANAGER = LootHistory_Manager:New()
