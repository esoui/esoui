ZO_LOOT_HISTORY_NAME = "ZO_LootHistory"

--
--[[ LootHistory_Singleton ]]--
--

local LootHistory_Singleton = ZO_Object:Subclass()

function LootHistory_Singleton:New(...)
    local lootHistory = ZO_Object.New(self)
    lootHistory:Initialize(...)
    return lootHistory
end

local function CanAddLootEntry()
    return tonumber(GetSetting(SETTING_TYPE_LOOT,LOOT_SETTING_LOOT_HISTORY)) == 1 
end

function LootHistory_Singleton:Initialize()
    local function OnLootReceived(...)
        if CanAddLootEntry() then
            SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnLootReceived(...)
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

    EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_LOOT_RECEIVED, function(eventId, ...) OnLootReceived(...) end)
    EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_MONEY_UPDATE, function(eventId, ...) OnGoldUpdate(...) end)
    EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_JUSTICE_GOLD_PICKPOCKETED, function(eventId, ...) OnGoldPickpocket(...) end)
    EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_ALLIANCE_POINT_UPDATE, function(eventId, ...) OnAlliancePointUpdate(...) end)
    EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_TELVAR_STONE_UPDATE, function(eventId, ...) OnTelvarStoneUpdate(...) end)
end

ZO_LOOT_HISTOY_SINGLETON = LootHistory_Singleton:New()

--
--[[ ZO_LootHistory_Shared ]]--
--

ZO_LootHistory_Shared = ZO_Object:Subclass()

function ZO_LootHistory_Shared:New(...)
    local history = ZO_Object.New(self)
    history:Initialize(...)
    return history
end

function ZO_LootHistory_Shared:Initialize(control)
    self:InitializeFragment()
    self:SetEntryTemplate()
    self:InitializeFadingControlBuffer(control)

    self.fadeAnim = ZO_AlphaAnimation:New(control)
    self.fadeAnim:SetMinMaxAlpha(0.0, 1.0)

    self.lootQueue = {}
end

do
    local function LootSetupFunction(control, data)
        control.label:SetText(data.text)
        control.label:SetColor(data.color:UnpackRGBA())

        control.icon:SetTexture(data.icon)

        control.background:SetColor(data.backgroundColor:UnpackRGBA())

        control.stackCountLabel:SetText(data.stackCount)
        control.stackCountLabel:SetHidden(data.stackCount <= 1)
    end

    local function AreEntriesEqual(entry1, entry2)
        -- entry1 and entry2 are tables of one item
        local data1 = entry1[1]
        local data2 = entry2[1]
        if data1.moneyType then
            return data1.moneyType == data2.moneyType
        elseif data1.itemId then
            return data1.itemId == data2.itemId and data1.quality == data2.quality
        else
            return false
        end
    end

    --setup for a control when another control has been found to be equal to it
    local function EqualitySetup(fadingControlBuffer, currentEntry, newEntry)
        local currentEntryData = currentEntry.lines[1]
        local newEntryData = newEntry.lines[1]
        local control = currentEntryData.control

        currentEntryData.stackCount = currentEntryData.stackCount + newEntryData.stackCount
        if control and control.stackCountLabel then
            control.stackCountLabel:SetText(currentEntryData.stackCount)
            control.stackCountLabel:SetHidden(false) -- guaranteed to always show because we had at least 1 and we are adding at least 1
            ZO_CraftingResults_Base_PlayPulse(control.stackCountLabel) -- TODO: Is this the animation we really want?
        end
    end

    function ZO_LootHistory_Shared:CreateFadingStationaryControlBuffer(control, fadeLabelAnimationName, fadeIconAnimationName, fadeContainerAnimation, anchor, maxEntries, containerShowTime, containerType)
        lootStream = ZO_FadingStationaryControlBuffer:New(control, maxEntries, fadeLabelAnimationName,  fadeIconAnimationName, fadeContainerAnimation, anchor, containerType)
        lootStream:AddTemplate(self.entryTemplate, {setup = LootSetupFunction, equalityCheck = AreEntriesEqual, equalitySetup = EqualitySetup })
        lootStream:SetContainerShowTime(containerShowTime or 5000)

        return lootStream
    end
end

-- loot stream and queue functions

function ZO_LootHistory_Shared:CreateLootEntry(lootData)
    local lootEntry = {
            lines = { lootData, }
        }
    return lootEntry
end

function ZO_LootHistory_Shared:AddLootEntry(lootEntry)
    self.lootStream:AddEntry(self.entryTemplate, lootEntry)
end

function ZO_LootHistory_Shared:QueueLootEntry(lootEntry)
    table.insert(self.lootQueue, lootEntry)
end

function ZO_LootHistory_Shared:InsertOrQueue(lootEntry)
    if self.hidden then
        self:QueueLootEntry(lootEntry)
    else
        self:AddLootEntry(lootEntry)
    end
end

function ZO_LootHistory_Shared:DisplayLootQueue()
    if self.hidden then
        for i, lootEntry in ipairs(self.lootQueue) do
            self:AddLootEntry(lootEntry)
            self.lootQueue[i] = nil
        end

        self.hidden = false
    end
end

function ZO_LootHistory_Shared:HideLootQueue()
    if not self.hidden then
        self.lootStream:FadeAll()
        self.hidden = true
    end
end

-- event handlers

do
    local MONEY_TEXT = {
        [CURT_MONEY] = GetString(SI_CURRENCY_GOLD),
        [CURT_ALLIANCE_POINTS] = GetString(SI_CURRENCY_ALLIANCE_POINTS),
        [CURT_TELVAR_STONES] = GetString(SI_CURRENCY_TELVAR_STONES),
    }

    local MONEY_ICONS = {
        [CURT_MONEY] = LOOT_MONEY_ICON,
        [CURT_ALLIANCE_POINTS] = LOOT_ALLIANCE_POINT_ICON,
        [CURT_TELVAR_STONES] = LOOT_TELVAR_STONE_ICON,
    }

    local MONEY_BACKGROUND_COLORS = {
        [CURT_MONEY] = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_CURRENCY, CURRENCY_COLOR_GOLD)),
        [CURT_ALLIANCE_POINTS] = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_CURRENCY, CURRENCY_COLOR_ALLIANCE_POINTS)),
        [CURT_TELVAR_STONES] = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_CURRENCY, CURRENCY_COLOR_TELVAR_STONES)),
    }

    function ZO_LootHistory_Shared:AddMoneyEntry(moneyAdded, moneyType)
        local lootData = {
                            text = MONEY_TEXT[moneyType],
                            icon = MONEY_ICONS[moneyType],
                            stackCount = moneyAdded,
                            color = ZO_SELECTED_TEXT,
                            backgroundColor = MONEY_BACKGROUND_COLORS[moneyType],
                            moneyType = moneyType
                        }
        local lootEntry = self:CreateLootEntry(lootData)
        self:InsertOrQueue(lootEntry)
    end
end

function ZO_LootHistory_Shared:OnLootReceived(receivedBy, itemLinkOrName, stackCount, itemSound, lootType, lootedBySelf, isPickpocketLoot, questItemIcon, itemId)
    if lootedBySelf then
        local itemName
        local icon
        local color
        local quality

        if lootType == LOOT_TYPE_QUEST_ITEM then
            itemName = itemLinkOrName --quest items don't support item linking, this just returns their name.
            icon = questItemIcon
            color = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_TOOLTIP, ITEM_TOOLTIP_COLOR_QUEST_ITEM_NAME))
        elseif lootType == LOOT_TYPE_COLLECTIBLE then
            local collectibleId = GetCollectibleIdFromLink(itemLinkOrName)
            local name, description, collectibleIcon = GetCollectibleInfo(collectibleId)
            itemName = name
            icon = collectibleIcon
            color = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_TOOLTIP, ITEM_TOOLTIP_COLOR_QUEST_ITEM_NAME))
        else
            itemName = GetItemLinkName(itemLinkOrName)
            icon = GetItemLinkInfo(itemLinkOrName)
            quality = GetItemLinkQuality(itemLinkOrName)
            color = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality))
        end

        local lootData = {
                            text = zo_strformat(SI_TOOLTIP_ITEM_NAME, itemName),
                            icon = icon,
                            stackCount = stackCount,
                            color = color,
                            backgroundColor = color,
                            itemId = itemId,
                            quality = quality,
                        }

        local lootEntry = self:CreateLootEntry(lootData)
        self:InsertOrQueue(lootEntry)
    end
end

function ZO_LootHistory_Shared:OnGoldUpdate(newGold, oldGold, reason)
    if reason == CURRENCY_CHANGE_REASON_LOOT or reason == CURRENCY_CHANGE_REASON_LOOT_STOLEN or reason == CURRENCY_CHANGE_REASON_QUESTREWARD then
        local goldAdded = newGold - oldGold
        self:AddMoneyEntry(goldAdded, CURT_MONEY)
    end
end

function ZO_LootHistory_Shared:OnGoldPickpocket(goldAmount)
    self:AddMoneyEntry(goldAmount, CURT_MONEY)
end

function ZO_LootHistory_Shared:OnAlliancePointUpdate(currentAlliancePoints, playSound, difference)
    if difference > 0 then
        self:AddMoneyEntry(difference, CURT_ALLIANCE_POINTS)
    end
end

function ZO_LootHistory_Shared:OnTelvarStoneUpdate(newTelvarStones, oldTelvarStones, reason)
    if reason == CURRENCY_CHANGE_REASON_LOOT or reason == CURRENCY_CHANGE_REASON_PVP_KILL_TRANSFER then
        local tvStonesAdded = newTelvarStones - oldTelvarStones
        if tvStonesAdded > 0 then
            self:AddMoneyEntry(tvStonesAdded, CURT_TELVAR_STONES)
        end
    end
end

-- functions to be overridden

function ZO_LootHistory_Shared:SetEntryTemplate()
    assert(false)
end

function ZO_LootHistory_Shared:InitializeFragment()
end

function ZO_LootHistory_Shared:InitializeFadingControlBuffer(control)
end

-- global functions

function ZO_LootHistory_Shared_OnInitialized(control)
    control.icon = control:GetNamedChild("Icon")
    control.stackCountLabel = control.icon:GetNamedChild("StackCount")
    control.label = control:GetNamedChild("Label")
    control.background = control:GetNamedChild("Bg")
end
