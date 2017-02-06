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

do
    local IGNORED_LOOT_TYPES =
    {
        [LOOT_TYPE_ITEM] = true,
        [LOOT_TYPE_QUEST_ITEM] = true,
        [LOOT_TYPE_COLLECTIBLE] = true,
    }

    function LootHistory_Manager:Initialize()
        local function OnNewItemReceived(...)
            if CanAddLootEntry() then
                SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnNewItemReceived(...)
            end
        end

        local function OnNewCollectibleReceived(collectibleId)
            if CanAddLootEntry() then
                SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnNewCollectibleReceived(collectibleId)
            end
        end

        local function OnGoldUpdate(...)
            if CanAddLootEntry() then
                SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnGoldUpdate(...)
            end
        end

        local function OnGoldPickpocket(...)
            if CanAddLootEntry() then
                SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnGoldPickpocket(...)
            end
        end

        local function OnAlliancePointUpdate(...)
            if CanAddLootEntry() then
                SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnAlliancePointUpdate(...)
            end
        end

        local function OnTelvarStoneUpdate(...)
            if CanAddLootEntry() then
                SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnTelvarStoneUpdate(...)
            end
        end

	    local function OnWritVoucherUpdate(...)
            if CanAddLootEntry() then
                SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnWritVoucherUpdate(...)
            end
        end

        local function OnExperienceGainUpdate(...)
            if CanAddLootEntry() then
                SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnExperienceGainUpdate(...)
            end
        end

        local function OnCrownGemUpdate(...)
            if CanAddLootEntry() then
                SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnCrownGemUpdate(...)
            end
        end

        local function OnInventorySlotUpdate(bagId, slotId, isNewItem, itemSound, inventoryUpdateReason, stackCountChange)
            -- This includes any inventory item update, only display if the item was new
            if isNewItem and stackCountChange > 0 then
                local itemLink = GetItemLink(bagId, slotId)

                -- cover the case where we got an inventory item update but then the item got whisked away somewhere else
                -- before we had a chance to get the info out of it
                if itemLink ~= nil and itemLink ~= "" then
                    local lootType = LOOT_TYPE_ITEM
                    local itemId = GetItemInstanceId(bagId, slotId)
                    local isVirtual = bagId == BAG_VIRTUAL
                    OnNewItemReceived(itemLink, stackCountChange, itemSound, lootType, nil, itemId, isVirtual)
                end
            end
        end

        local IS_NOT_VIRTUAL = false

        local function OnLootReceived(receivedBy, itemLinkOrName, stackCount, itemSound, lootType, lootedBySelf, isPickpocketLoot, questItemIcon, itemId)
            -- This includes any loot event, only display if this was the player's loot and wasn't an inventory item
            -- OnInventorySlotUpdate() must be used for Inventory Items so that we know what bag they went into
            -- we also are going to handle quest items through the QuestToolUpdated event
            if lootedBySelf and not IGNORED_LOOT_TYPES[lootType] then
                OnNewItemReceived(itemLinkOrName, stackCount, itemSound, lootType, questItemIcon, itemId, IS_NOT_VIRTUAL)
            end
        end

        local function OnQuestToolUpdate(questIndex, questName, countDelta, questItemIcon, questItemId, questItemName)
            if countDelta > 0 then
                OnNewItemReceived(questItemName, countDelta, nil, LOOT_TYPE_QUEST_ITEM, questItemIcon, questItemId, IS_NOT_VIRTUAL)
            end
        end
    
        EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, function(eventId, ...) OnInventorySlotUpdate(...) end)
        EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_LOOT_RECEIVED, function(eventId, ...) OnLootReceived(...) end)
        EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_MONEY_UPDATE, function(eventId, ...) OnGoldUpdate(...) end)
        EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_JUSTICE_GOLD_PICKPOCKETED, function(eventId, ...) OnGoldPickpocket(...) end)
        EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_ALLIANCE_POINT_UPDATE, function(eventId, ...) OnAlliancePointUpdate(...) end)
        EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_TELVAR_STONE_UPDATE, function(eventId, ...) OnTelvarStoneUpdate(...) end)
	    EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_WRIT_VOUCHER_UPDATE, function(eventId, ...) OnWritVoucherUpdate(...) end)
        EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_EXPERIENCE_GAIN, function(eventId, ...) OnExperienceGainUpdate(...) end)
        EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_QUEST_TOOL_UPDATED, function(eventId, ...) OnQuestToolUpdate(...) end)
        EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_COLLECTIBLE_NOTIFICATION_NEW, function(eventId, ...) OnNewCollectibleReceived(...) end)
        EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_CROWN_GEM_UPDATE, function(eventId, ...) OnCrownGemUpdate(...) end)
    end
end

ZO_LOOT_HISTORY_MANAGER = LootHistory_Manager:New()
