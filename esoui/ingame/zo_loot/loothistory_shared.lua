LOOT_ENTRY_TYPE_EXPERIENCE = 1
LOOT_ENTRY_TYPE_CROWN_GEMS = 2
LOOT_ENTRY_TYPE_MONEY = 3
LOOT_ENTRY_TYPE_ITEM = 4
LOOT_ENTRY_TYPE_COLLECTIBLE = 5

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

        local USE_LOWERCASE_NUMBER_SUFFIXES = false
        control.stackCountLabel:SetText(ZO_AbbreviateNumber(data.stackCount, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES))
        control.stackCountLabel:SetHidden(data.stackCount <= 1)

        local hideCraftBagIcons = not data.isCraftBagItem
        control.craftBagIcon:SetHidden(hideCraftBagIcons)
        control.craftBagHighlight:SetHidden(hideCraftBagIcons)
    end

    local function AreEntriesEqual(entry1, entry2)
        -- entry1 and entry2 are tables of one item
        local data1 = entry1[1]
        local data2 = entry2[1]
        local data1EntryType = data1.entryType
        local data2EntryType = data2.entryType
        if data1EntryType ~= data2EntryType then
            return false
        end

        if data1.entryType == LOOT_ENTRY_TYPE_MONEY then
            return data1.moneyType == data2.moneyType
        elseif data1.entryType == LOOT_ENTRY_TYPE_ITEM then
            return data1.itemId == data2.itemId and data1.quality == data2.quality
        elseif data1.entryType == LOOT_ENTRY_TYPE_COLLECTIBLE then
            return data1.collectibleId == data2.collectibleId
        else
            return true
        end
    end

    --setup for a control when another control has been found to be equal to it
    local function EqualitySetup(fadingControlBuffer, currentEntry, newEntry)
        local currentEntryData = currentEntry.lines[1]
        local newEntryData = newEntry.lines[1]
        local control = currentEntryData.control

        currentEntryData.stackCount = currentEntryData.stackCount + newEntryData.stackCount
        if control and control.stackCountLabel then
            control.stackCountLabel:SetText(ZO_AbbreviateNumber(currentEntryData.stackCount, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES))
            control.stackCountLabel:SetHidden(false) -- guaranteed to always show because we had at least 1 and we are adding at least 1
            ZO_CraftingResults_Base_PlayPulse(control.stackCountLabel)
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
    if lootEntry.isPersistent then
        self.lootStreamPersistent:AddEntry(self.entryTemplate, lootEntry)
    else
        self.lootStream:AddEntry(self.entryTemplate, lootEntry)
    end
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

do
    local CONTAINER_SHOW_TIME_MS = 3600
    local PERSISTENT_CONTAINER_SHOW_TIME_MS = 7000

    function ZO_LootHistory_Shared:GetContainerShowTime()
        return CONTAINER_SHOW_TIME_MS
    end

    function ZO_LootHistory_Shared:GetPersistentContainerShowTime()
        return PERSISTENT_CONTAINER_SHOW_TIME_MS
    end
end

-- event handlers

do
    local MONEY_TEXT = {
        [CURT_MONEY] = GetString(SI_CURRENCY_GOLD),
        [CURT_ALLIANCE_POINTS] = GetString(SI_CURRENCY_ALLIANCE_POINTS),
        [CURT_TELVAR_STONES] = GetString(SI_CURRENCY_TELVAR_STONES),
        [CURT_WRIT_VOUCHERS] = GetString(SI_CURRENCY_WRIT_VOUCHERS),
    }

    local MONEY_ICONS = {
        [CURT_MONEY] = LOOT_MONEY_ICON,
        [CURT_ALLIANCE_POINTS] = LOOT_ALLIANCE_POINT_ICON,
        [CURT_TELVAR_STONES] = LOOT_TELVAR_STONE_ICON,
        [CURT_WRIT_VOUCHERS] = LOOT_WRIT_VOUCHER_ICON,
    }

    local MONEY_BACKGROUND_COLORS = {
        [CURT_MONEY] = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_CURRENCY, CURRENCY_COLOR_GOLD)),
        [CURT_ALLIANCE_POINTS] = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_CURRENCY, CURRENCY_COLOR_ALLIANCE_POINTS)),
        [CURT_TELVAR_STONES] = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_CURRENCY, CURRENCY_COLOR_TELVAR_STONES)),
        [CURT_WRIT_VOUCHERS] = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_CURRENCY, CURRENCY_COLOR_WRIT_VOUCHERS)),
    }

    function ZO_LootHistory_Shared:AddMoneyEntry(moneyAdded, moneyType)
        local lootData = {
                            text = MONEY_TEXT[moneyType],
                            icon = MONEY_ICONS[moneyType],
                            stackCount = moneyAdded,
                            color = ZO_SELECTED_TEXT,
                            moneyType = moneyType,
                            entryType = LOOT_ENTRY_TYPE_MONEY
                        }
        local lootEntry = self:CreateLootEntry(lootData)
        lootEntry.isPersistent = true
        self:InsertOrQueue(lootEntry)
    end

    function ZO_LootHistory_Shared:AddXpEntry(xpAdded)
        local lootData = {
                            text = GetString(SI_LOOT_HISTORY_EXPERIENCE_GAIN),
                            icon = LOOT_EXPERIENCE_ICON,
                            stackCount = xpAdded,
                            color = ZO_SELECTED_TEXT,
                            entryType = LOOT_ENTRY_TYPE_EXPERIENCE
                        }
        local lootEntry = self:CreateLootEntry(lootData)
        lootEntry.isPersistent = true
        self:InsertOrQueue(lootEntry)
    end

    function ZO_LootHistory_Shared:AddGemEntry(gemsAdded)
        local lootData = {
                            text = GetString(SI_LOOT_HISTORY_CROWN_GEMS_GAIN),
                            icon = LOOT_GEMS_ICON,
                            stackCount = gemsAdded,
                            color = ZO_SELECTED_TEXT,
                            entryType = LOOT_ENTRY_TYPE_CROWN_GEMS
                        }
        local lootEntry = self:CreateLootEntry(lootData)
        lootEntry.isPersistent = true
        self:InsertOrQueue(lootEntry)
    end
end

function ZO_LootHistory_Shared:OnNewItemReceived(itemLinkOrName, stackCount, itemSound, lootType, questItemIcon, itemId, isVirtual)
    if not self.hidden or self:CanShowItemsInHistory() then
        local itemName
        local icon
        local color
        local quality

        -- we already handle collectibles as collectibles, 
        -- but if we get them as something like a quest reward, they need to be funneled properly
        if lootType == LOOT_TYPE_COLLECTIBLE then
            local collectibleId = GetCollectibleIdFromLink(itemLinkOrName)
            self:OnNewCollectibleReceived(collectibleId)
            return
        end

        if lootType == LOOT_TYPE_QUEST_ITEM then
            itemName = itemLinkOrName --quest items don't support item linking, this just returns their name.
            icon = questItemIcon
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
                            itemId = itemId,
                            quality = quality,
                            isCraftBagItem = isVirtual,
                            entryType = LOOT_ENTRY_TYPE_ITEM,
                        }

        local lootEntry = self:CreateLootEntry(lootData)
        self:InsertOrQueue(lootEntry)
    end
end

function ZO_LootHistory_Shared:OnNewCollectibleReceived(collectibleId)
    if not self.hidden or self:CanShowItemsInHistory() then
        local name, _, icon = GetCollectibleInfo(collectibleId)

        local QUALITY_NORMAL = 1
        local lootData = {
                            text = zo_strformat(SI_TOOLTIP_ITEM_NAME, name),
                            icon = icon,
                            stackCount = 1,
                            color = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, QUALITY_NORMAL)),
                            collectibleId = collectibleId,
                            entryType = LOOT_ENTRY_TYPE_COLLECTIBLE
                        }

        local lootEntry = self:CreateLootEntry(lootData)
        self:InsertOrQueue(lootEntry)
    end
end

function ZO_LootHistory_Shared:OnGoldUpdate(newGold, oldGold, reason)
    if reason == CURRENCY_CHANGE_REASON_LOOT or reason == CURRENCY_CHANGE_REASON_KILL or reason == CURRENCY_CHANGE_REASON_LOOT_STOLEN or reason == CURRENCY_CHANGE_REASON_QUESTREWARD then
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

function ZO_LootHistory_Shared:OnWritVoucherUpdate(newWritVouchers, oldWritVouchers, reason)
    if reason == CURRENCY_CHANGE_REASON_LOOT or reason == CURRENCY_CHANGE_REASON_QUESTREWARD then
        local writVouchersAdded = newWritVouchers - oldWritVouchers
        if writVouchersAdded > 0 then
            self:AddMoneyEntry(writVouchersAdded, CURT_WRIT_VOUCHERS)
        end
    end
end

function ZO_LootHistory_Shared:OnExperienceGainUpdate(reason, level, previousExperience, currentExperience)
    local difference = currentExperience - previousExperience
    self:AddXpEntry(difference)
end

function ZO_LootHistory_Shared:OnCrownGemUpdate(totalGems, gemDifference)
    if gemDifference > 0 then
        self:AddGemEntry(gemDifference)
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

function ZO_LootHistory_Shared:CanShowItemsInHistory()
    return false -- default value
end


-- global functions

function ZO_LootHistory_Shared_OnInitialized(control)
    control.icon = control:GetNamedChild("Icon")
    control.stackCountLabel = control.icon:GetNamedChild("StackCount")
    control.label = control:GetNamedChild("Label")
    control.background = control:GetNamedChild("Bg")
    control.craftBagIcon = control.icon:GetNamedChild("CraftBagIcon")
    control.craftBagHighlight = control.background:GetNamedChild("CraftBagHighlight")
end
