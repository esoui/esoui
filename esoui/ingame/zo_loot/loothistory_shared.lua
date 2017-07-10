LOOT_ENTRY_TYPE_EXPERIENCE = 1
LOOT_ENTRY_TYPE_CROWN_GEMS = 2
LOOT_ENTRY_TYPE_MONEY = 3
LOOT_ENTRY_TYPE_ITEM = 4
LOOT_ENTRY_TYPE_COLLECTIBLE = 5
LOOT_ENTRY_TYPE_MEDAL = 6
LOOT_ENTRY_TYPE_SCORE = 7
LOOT_ENTRY_TYPE_SKILL_EXPERIENCE = 8

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

    local function SetupIconOverlayText(control, data)
        local overlayText = ZO_LootHistory_Shared.GetIconOverlayTextFromData(data)
        control.iconOverlayText:SetText(overlayText)

        local showOverlayText = ZO_LootHistory_Shared.GetShowIconOverlayTextFromData(data)
        control.iconOverlayText:SetHidden(not showOverlayText)
    end

    local function LootSetupFunction(control, data)
        control.label:SetText(data.text)
        control.label:SetColor(data.color:UnpackRGBA())

        control.icon:SetTexture(data.icon)

        SetupIconOverlayText(control, data)

        if data.statusIcon then
            control.statusIcon:SetTexture(data.statusIcon)
            control.statusIcon:SetHidden(false)
        else
            control.statusIcon:SetHidden(true)
        end

        if data.highlight then
            control.backgroundHighlight:SetTexture(data.highlight)
            control.backgroundHighlight:SetHidden(false)
        else
            control.backgroundHighlight:SetHidden(true)
        end
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

        if data1EntryType == LOOT_ENTRY_TYPE_MONEY then
            return data1.moneyType == data2.moneyType
        elseif data1EntryType == LOOT_ENTRY_TYPE_ITEM then
            return data1.itemId == data2.itemId and data1.quality == data2.quality and data1.isStolen == data2.isStolen
        elseif data1EntryType == LOOT_ENTRY_TYPE_COLLECTIBLE then
            return data1.collectibleId == data2.collectibleId
        elseif data1EntryType == LOOT_ENTRY_TYPE_MEDAL then
            return false -- Medals are always on their own line
        elseif data1EntryType == LOOT_ENTRY_TYPE_SCORE then
            return false -- scores are always on their own line (also expecting to only be showing one of these at a time)
        elseif data1EntryType == LOOT_ENTRY_TYPE_SKILL_EXPERIENCE then
            return data1.skillType == data2.skillType and data1.skillIndex == data2.skillIndex
        else
            return true
        end
    end

    --setup for a control when another control has been found to be equal to it
    local function EqualitySetup(fadingControlBuffer, currentEntry, newEntry)
        local currentEntryData = currentEntry.lines[1]
        local newEntryData = newEntry.lines[1]
        local control = currentEntryData.control

        if currentEntryData.entryType ~= LOOT_ENTRY_TYPE_MEDAL and currentEntryData.entryType ~= LOOT_ENTRY_TYPE_SCORE then
            currentEntryData.stackCount = currentEntryData.stackCount + newEntryData.stackCount
            if control and control.iconOverlayText then
                SetupIconOverlayText(control, currentEntryData)
                ZO_CraftingResults_Base_PlayPulse(control.iconOverlayText)
            end
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

    function ZO_LootHistory_Shared:AddMoneyEntry(moneyAdded, moneyType)
        local lootData = {
                            text = MONEY_TEXT[moneyType],
                            icon = MONEY_ICONS[moneyType],
                            stackCount = moneyAdded,
                            color = ZO_SELECTED_TEXT,
                            moneyType = moneyType,
                            entryType = LOOT_ENTRY_TYPE_MONEY,
                            iconOverlayText = ZO_LootHistory_Shared.GetStackCountStringFromData,
                            showIconOverlayText = ZO_LootHistory_Shared.ShouldShowStackCountStringFromData
                        }
        local lootEntry = self:CreateLootEntry(lootData)
        lootEntry.isPersistent = true
        self:InsertOrQueue(lootEntry)
    end
end

function ZO_LootHistory_Shared:AddXpEntry(xpAdded)
    local lootData = {
                        text = GetString(SI_LOOT_HISTORY_EXPERIENCE_GAIN),
                        icon = LOOT_EXPERIENCE_ICON,
                        stackCount = xpAdded,
                        color = ZO_SELECTED_TEXT,
                        entryType = LOOT_ENTRY_TYPE_EXPERIENCE,
                        iconOverlayText = ZO_LootHistory_Shared.GetStackCountStringFromData,
                        showIconOverlayText = ZO_LootHistory_Shared.ShouldShowStackCountStringFromData
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
                        entryType = LOOT_ENTRY_TYPE_CROWN_GEMS,
                        iconOverlayText = ZO_LootHistory_Shared.GetStackCountStringFromData,
                        showIconOverlayText = ZO_LootHistory_Shared.ShouldShowStackCountStringFromData
                    }
    local lootEntry = self:CreateLootEntry(lootData)
    lootEntry.isPersistent = true
    self:InsertOrQueue(lootEntry)
end

function ZO_LootHistory_Shared:AddMedalEntry(medalId, name, icon, value)
    local lootData = {
                        text = zo_strformat(SI_LOOT_HISTORY_MEDAL_NAME_FORMATTER, name),
                        icon = icon,
                        value = value,
                        color = ZO_SELECTED_TEXT,
                        entryType = LOOT_ENTRY_TYPE_MEDAL,
                        iconOverlayText = ZO_LootHistory_Shared.GetMedalValueStringFromData,
                        showIconOverlayText = ZO_LootHistory_Shared.ShouldShowMedalValueStringFromData
                    }
    local lootEntry = self:CreateLootEntry(lootData)
    self:InsertOrQueue(lootEntry)
end

function ZO_LootHistory_Shared:AddScoreEntry(score)
    local lootData = {
                        text = GetString(SI_LOOT_HISTORY_LEADERBOARD_SCORE),
                        icon = LOOT_LEADERBOARD_SCORE_ICON,
                        value = score,
                        color = ZO_SELECTED_TEXT,
                        entryType = LOOT_ENTRY_TYPE_SCORE,
                        iconOverlayText = ZO_LootHistory_Shared.GetValueStringFromData,
                        showIconOverlayText = true
                    }
    local lootEntry = self:CreateLootEntry(lootData)
    lootEntry.isPersistent = true
    self:InsertOrQueue(lootEntry)
end

function ZO_LootHistory_Shared:AddSkillEntry(skillType, skillIndex, skillXpAdded)
    local skillName = GetSkillLineInfo(skillType, skillIndex)
    local announcementIcon = GetSkillLineAnnouncementIcon(skillType, skillIndex)
    local lootData = {
                        text = skillName,
                        icon = announcementIcon,
                        stackCount = skillXpAdded,
                        color = ZO_SELECTED_TEXT,
                        skillType = skillType,
                        skillIndex = skillIndex,
                        entryType = LOOT_ENTRY_TYPE_SKILL_EXPERIENCE,
                        iconOverlayText = ZO_LootHistory_Shared.GetStackCountStringFromData,
                        showIconOverlayText = ZO_LootHistory_Shared.ShouldShowStackCountStringFromData
                    }
    local lootEntry = self:CreateLootEntry(lootData)
    lootEntry.isPersistent = true
    self:InsertOrQueue(lootEntry)
end

function ZO_LootHistory_Shared:OnNewItemReceived(itemLinkOrName, stackCount, itemSound, lootType, questItemIcon, itemId, isVirtual, isStolen)
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

        local statusIcon
        local highlight
        if isVirtual then
            statusIcon = self:GetCraftBagIcon()
            highlight = self:GetCraftBagHighlight()
        elseif isStolen then
            statusIcon = self:GetStolenIcon()
            highlight = self:GetStolenHighlight()
        end

        local lootData = {
                            text = zo_strformat(SI_TOOLTIP_ITEM_NAME, itemName),
                            icon = icon,
                            stackCount = stackCount,
                            color = color,
                            itemId = itemId,
                            quality = quality,
                            isCraftBagItem = isVirtual,
                            isStolen = isStolen,
                            statusIcon = statusIcon,
                            highlight = highlight,
                            entryType = LOOT_ENTRY_TYPE_ITEM,
                            iconOverlayText = ZO_LootHistory_Shared.GetStackCountStringFromData,
                            showIconOverlayText = ZO_LootHistory_Shared.ShouldShowStackCountStringFromData
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
                            entryType = LOOT_ENTRY_TYPE_COLLECTIBLE,
                            iconOverlayText = ZO_LootHistory_Shared.GetStackCountStringFromData,
                            showIconOverlayText = ZO_LootHistory_Shared.ShouldShowStackCountStringFromData
                        }

        local lootEntry = self:CreateLootEntry(lootData)
        self:InsertOrQueue(lootEntry)
    end
end

function ZO_LootHistory_Shared:OnGoldUpdate(newGold, oldGold, reason)
    -- pickpocket is handled by OnGoldPickpocket
    if reason ~= CURRENCY_CHANGE_REASON_PICKPOCKET and reason ~= CURRENCY_CHANGE_REASON_PLAYER_INIT then
        local goldAdded = newGold - oldGold
        if goldAdded > 0 then
            self:AddMoneyEntry(goldAdded, CURT_MONEY)
        end
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
    if reason ~= CURRENCY_CHANGE_REASON_PLAYER_INIT then
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

function ZO_LootHistory_Shared:OnMedalAwarded(medalId, name, icon, value)
    self:AddMedalEntry(medalId, name, icon, value)
end

function ZO_LootHistory_Shared:OnBattlegroundScoreboardUpdated()
    local playerIndex = GetScoreboardPlayerEntryIndex()
    self:AddScoreEntry(GetScoreboardEntryScoreByType(playerIndex, SCORE_TRACKER_TYPE_SCORE))
end

do
    local ALLOWED_SKILL_TYPES = 
    {
        [SKILL_TYPE_GUILD] = true
    }

    function ZO_LootHistory_Shared:OnSkillExperienceUpdated(skillType, skillIndex, reason, rank, previousXP, currentXP)
        local delta = currentXP - previousXP
        if delta > 0 and ALLOWED_SKILL_TYPES[skillType] then
            self:AddSkillEntry(skillType, skillIndex, delta)
        end
    end
end

do
    local USE_LOWERCASE_NUMBER_SUFFIXES = false
    function ZO_LootHistory_Shared.GetStackCountStringFromData(data)
        return ZO_AbbreviateNumber(data.stackCount, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES)
    end

    function ZO_LootHistory_Shared.GetValueStringFromData(data)
        return ZO_AbbreviateNumber(data.value, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES)
    end
end

function ZO_LootHistory_Shared.ShouldShowStackCountStringFromData(data)
    return data.stackCount > 1
end

function ZO_LootHistory_Shared.GetMedalValueStringFromData(data)
    return zo_strformat(SI_LOOT_HISTORY_MEDAL_VALUE_FORMATTER, data.value)
end

function ZO_LootHistory_Shared.ShouldShowMedalValueStringFromData(data)
    return data.value > 0
end

function ZO_LootHistory_Shared.GetIconOverlayTextFromData(data)
    local overlayText = data.iconOverlayText
    if type(overlayText) == "function" then
        overlayText = overlayText(data)
    end
    return overlayText
end

function ZO_LootHistory_Shared.GetShowIconOverlayTextFromData(data)
    local showOverlayText = data.showIconOverlayText
    if type(showOverlayText) == "function" then
        showOverlayText = showOverlayText(data)
    end
    return showOverlayText
end

-- functions to be overridden

function ZO_LootHistory_Shared:SetEntryTemplate()
    assert(false)
end

function ZO_LootHistory_Shared:InitializeFragment()
    -- To be overridden
end

function ZO_LootHistory_Shared:InitializeFadingControlBuffer(control)
    -- To be overridden
end

function ZO_LootHistory_Shared:CanShowItemsInHistory()
    return false -- default value
end

function ZO_LootHistory_Shared:GetCraftBagIcon()
    -- To be overridden
end

function ZO_LootHistory_Shared:GetStolenIcon()
    -- To be overridden
end

function ZO_LootHistory_Shared:GetCraftBagHighlight()
    -- To be overridden
end

function ZO_LootHistory_Shared:GetStolenHighlight()
    -- To be overridden
end

-- global functions

function ZO_LootHistory_Shared_OnInitialized(control)
    control.icon = control:GetNamedChild("Icon")
    control.iconOverlayText = control.icon:GetNamedChild("OverlayText")
    control.label = control:GetNamedChild("Label")
    control.background = control:GetNamedChild("Bg")
    control.statusIcon = control.icon:GetNamedChild("StatusIcon")
    control.backgroundHighlight = control.background:GetNamedChild("Highlight")
end
