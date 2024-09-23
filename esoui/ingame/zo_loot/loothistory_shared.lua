LOOT_ENTRY_TYPE_EXPERIENCE = 1
LOOT_ENTRY_TYPE_CURRENCY = 2
LOOT_ENTRY_TYPE_ITEM = 3
LOOT_ENTRY_TYPE_COLLECTIBLE = 4
LOOT_ENTRY_TYPE_MEDAL = 5
LOOT_ENTRY_TYPE_SCORE = 6
LOOT_ENTRY_TYPE_SKILL_EXPERIENCE = 7
LOOT_ENTRY_TYPE_CROWN_CRATE = 8
LOOT_ENTRY_TYPE_KEEP_REWARD = 9
LOOT_ENTRY_TYPE_ANTIQUITY_LEAD = 10
LOOT_ENTRY_TYPE_COMPANION_EXPERIENCE = 11
LOOT_ENTRY_TYPE_COMPANION_RAPPORT = 12
LOOT_ENTRY_TYPE_TRIBUTE_CARD_UPGRADE = 13

LOOT_EXPERIENCE_ICON = "EsoUI/Art/Icons/Icon_Experience.dds"
LOOT_LEADERBOARD_SCORE_ICON = "EsoUI/Art/Icons/Battleground_Score.dds"
LOOT_TRIBUTE_CARD_UPGRADE_ICON = "EsoUI/Art/HUD/lootHistory_icon_tributeUpgrade.dds"

LOOT_RAPPORT_INCREASE_ICON_FORMATTER = "EsoUI/Art/HUD/lootHistory_icon_rapportIncrease_%d.dds"
LOOT_RAPPORT_DECREASE_ICON_FORMATTER = "EsoUI/Art/HUD/lootHistory_icon_rapportDecrease_%d.dds"
internalassert(RAPPORT_ADJUSTMENT_AMOUNT_ITERATION_END == 7, "New RAPPORT_ADJUSTMENT_AMOUNT added, new rapport increase and decrease icons will need to be created.")

ZO_LOOT_HISTORY_DISPLAY_TYPE_CRAFT_BAG = "craftBag"
ZO_LOOT_HISTORY_DISPLAY_TYPE_STOLEN = "stolen"
ZO_LOOT_HISTORY_DISPLAY_TYPE_COLLECTIONS = "collections"
ZO_LOOT_HISTORY_DISPLAY_TYPE_ANTIQUITIES = "antiquities"
ZO_LOOT_HISTORY_DISPLAY_TYPE_CROWN_CRATE = "crownCrate"

local USE_LOWERCASE_NUMBER_SUFFIXES = false

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
    local function SetupEntryText(control, data)
        local text = data.text
        if type(text) == "function" then
            text = text(data)
        end
        control.label:SetText(text)
    end

    local function SetupIconOverlayText(control, data)
        local overlayText = ZO_LootHistory_Shared.GetIconOverlayTextFromData(data)
        control.iconOverlayText:SetText(overlayText)

        local showOverlayText = ZO_LootHistory_Shared.GetShowIconOverlayTextFromData(data)
        control.iconOverlayText:SetHidden(not showOverlayText)
    end

    local function LootSetupFunction(control, data)
        SetupEntryText(control, data)
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

        if data.backgroundColor then
            control.background:SetColor(data.backgroundColor:UnpackRGB())
        else
            control.background:SetColor(ZO_BLACK:UnpackRGB())
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

        -- Currently, the only use for this function is to confirm whether we can merge existing loot stream entries (in ZO_FadingStationaryControlBuffer:TryConcatWithExistingEntry)
        -- If ever this changes and this equality function is used elsewhere, please re-evaluate whether this early out is appropriate.
        if data1.statusIcon ~= data2.statusIcon then
            return false
        end

        if data1EntryType == LOOT_ENTRY_TYPE_CURRENCY then
            return data1.currencyType == data2.currencyType
        elseif data1EntryType == LOOT_ENTRY_TYPE_ITEM then
            -- dataX.quality is deprecated, included here for addon backwards compatibility
            return data1.itemId == data2.itemId and data1.displayQuality == data2.displayQuality and data1.isStolen == data2.isStolen and  data1.quality == data2.quality
        elseif data1EntryType == LOOT_ENTRY_TYPE_COLLECTIBLE then
            return data1.collectibleId == data2.collectibleId
        elseif data1EntryType == LOOT_ENTRY_TYPE_MEDAL then
            return false -- Medals are always on their own line
        elseif data1EntryType == LOOT_ENTRY_TYPE_SCORE then
            return false -- scores are always on their own line (also expecting to only be showing one of these at a time)
        elseif data1EntryType == LOOT_ENTRY_TYPE_SKILL_EXPERIENCE then
            return data1.skillLineData == data2.skillLineData
        elseif data1EntryType == LOOT_ENTRY_TYPE_CROWN_CRATE then
            return data1.lootCrateId == data2.lootCrateId
        elseif data1EntryType == LOOT_ENTRY_TYPE_KEEP_REWARD then
            return false -- special info, cannot be merged
        elseif data1EntryType == LOOT_ENTRY_TYPE_ANTIQUITY_LEAD then
            return false -- leads don't stack
        elseif data1EntryType == LOOT_ENTRY_TYPE_COMPANION_EXPERIENCE then
            return data1.companionId == data2.companionId
        elseif data1EntryType == LOOT_ENTRY_TYPE_COMPANION_RAPPORT then
            return false --Rapport updates are always on their own line
        elseif data1EntryType == LOOT_ENTRY_TYPE_TRIBUTE_CARD_UPGRADE then
            return false -- Tribute card upgrades don't stack
        else
            return true
        end
    end

    --setup for a control when another control has been found to be equal to it
    local function EqualitySetup(fadingControlBuffer, currentEntry, newEntry)
        local currentEntryData = currentEntry.lines[1]
        local newEntryData = newEntry.lines[1]
        local control = currentEntryData.control
        
        if currentEntryData.entryType == LOOT_ENTRY_TYPE_COMPANION_EXPERIENCE then
            currentEntryData.gainedXp = currentEntryData.gainedXp + newEntryData.gainedXp
            local formattedXpAdded = ZO_AbbreviateAndLocalizeNumber(currentEntryData.gainedXp, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES)
            currentEntryData.text = zo_strformat(SI_LOOT_HISTORY_COMPANION_EXPERIENCE_GAIN_FORMATTER, formattedXpAdded, currentEntryData.companionName)
            if control then
                SetupEntryText(control, currentEntryData)
                ZO_CraftingResults_Base_PlayPulse(control.icon)
            end
        elseif currentEntryData.entryType ~= LOOT_ENTRY_TYPE_MEDAL and currentEntryData.entryType ~= LOOT_ENTRY_TYPE_SCORE then
            currentEntryData.stackCount = currentEntryData.stackCount + newEntryData.stackCount
            if control and control.iconOverlayText then
                SetupEntryText(control, currentEntryData)
                SetupIconOverlayText(control, currentEntryData)

                ZO_CraftingResults_Base_PlayPulse(control.iconOverlayText)
            end
        end
    end

    function ZO_LootHistory_Shared:CreateFadingStationaryControlBuffer(control, fadeLabelAnimationName, fadeIconAnimationName, fadeContainerAnimation, anchor, maxEntries, containerShowTime, containerType)
        local lootStream = ZO_FadingStationaryControlBuffer:New(control, maxEntries, fadeLabelAnimationName, fadeIconAnimationName, fadeContainerAnimation, anchor, containerType)
        lootStream:AddTemplate(self.entryTemplate, {setup = LootSetupFunction, equalityCheck = AreEntriesEqual, equalitySetup = EqualitySetup })
        lootStream:SetContainerShowTime(containerShowTime or 5000)

        return lootStream
    end
end

-- loot stream and queue functions

function ZO_LootHistory_Shared:CreateLootEntry(lootData)
    local lootEntry =
    {
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
        self.lootStream:Resume()
        self.lootStreamPersistent:Resume()
        self.hidden = false
    end
end

function ZO_LootHistory_Shared:HideLootQueue()
    if not self.hidden then
        self.hidden = true
        self.lootStream:Pause()
        self.lootStreamPersistent:Pause()
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
    local FORMAT_EXTRA_OPTIONS =
    {
        showCap = true,
    }
    local IS_UPPER = false

    function ZO_LootHistory_Shared:AddCurrencyEntry(currencyAdded, currencyType, currencyLocation)
        local icon = IsInGamepadPreferredMode() and GetCurrencyLootGamepadIcon(currencyType) or GetCurrencyLootKeyboardIcon(currencyType)

        local function GetCurrencyString(lootData)
            local currencyAdded = lootData.stackCount
            local formattedCurrencyString = GetCurrencyName(currencyType, IsCountSingularForm(currencyAdded), IS_UPPER)
            if IsCurrencyCapped(currencyType, currencyLocation) then
                FORMAT_EXTRA_OPTIONS.currencyLocation = currencyLocation
                local currencyAmount = GetCurrencyAmount(currencyType, currencyLocation)
                formattedCurrencyString = string.format("%s %s", formattedCurrencyString, ZO_Currency_FormatPlatform(currencyType, currencyAmount, ZO_CURRENCY_FORMAT_PARENTHETICAL_AMOUNT, FORMAT_EXTRA_OPTIONS))
            end

            return zo_strformat(SI_CURRENCY_NAME_FORMAT, formattedCurrencyString)
        end

        local lootData =
        {
            text = GetCurrencyString,
            icon = icon,
            stackCount = currencyAdded,
            color = currencyType == CURT_EVENT_TICKETS and ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, ITEM_DISPLAY_QUALITY_LEGENDARY)) or ZO_SELECTED_TEXT,
            currencyType = currencyType,
            entryType = LOOT_ENTRY_TYPE_CURRENCY,
            iconOverlayText = ZO_LootHistory_Shared.GetStackCountStringFromData,
            showIconOverlayText = ZO_LootHistory_Shared.ShouldShowStackCountStringFromData
        }
        local lootEntry = self:CreateLootEntry(lootData)
        lootEntry.isPersistent = true
        self:InsertOrQueue(lootEntry)
    end
end

function ZO_LootHistory_Shared:AddXpEntry(xpAdded)
    local lootData =
    {
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

function ZO_LootHistory_Shared:AddMedalEntry(medalId, name, icon, value)
    local lootData =
    {
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
    local lootData =
    {
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

function ZO_LootHistory_Shared:AddSkillEntry(skillLineData, skillXpAdded)
    local lootData =
    {
        skillLineData = skillLineData,
        text = skillLineData:GetFormattedName(),
        icon = skillLineData:GetAnnounceIcon(),
        stackCount = skillXpAdded,
        color = ZO_SELECTED_TEXT,
        entryType = LOOT_ENTRY_TYPE_SKILL_EXPERIENCE,
        iconOverlayText = ZO_LootHistory_Shared.GetStackCountStringFromData,
        showIconOverlayText = ZO_LootHistory_Shared.ShouldShowStackCountStringFromData
    }
    local lootEntry = self:CreateLootEntry(lootData)
    lootEntry.isPersistent = true
    self:InsertOrQueue(lootEntry)
end

function ZO_LootHistory_Shared:AddCrownCrateEntry(lootCrateId, numCrates)
    if self:CanShowItemsInHistory() then
        local crownCrateName = GetCrownCrateName(lootCrateId)
        local crateIcon = GetCrownCrateIcon(lootCrateId)
        local lootData =
        {
            text = zo_strformat(SI_CROWN_CRATE_PACK_NAME, crownCrateName),
            icon = crateIcon,
            stackCount = numCrates,
            lootCrateId = lootCrateId,
            color = ZO_SELECTED_TEXT,
            entryType = LOOT_ENTRY_TYPE_CROWN_CRATE,
            statusIcon = self:GetStatusIcon(ZO_LOOT_HISTORY_DISPLAY_TYPE_CROWN_CRATE),
            highlight = self:GetHighlight(ZO_LOOT_HISTORY_DISPLAY_TYPE_CROWN_CRATE),
            iconOverlayText = ZO_LootHistory_Shared.GetStackCountStringFromData,
            showIconOverlayText = ZO_LootHistory_Shared.ShouldShowStackCountStringFromData
        }
        local lootEntry = self:CreateLootEntry(lootData)
        self:InsertOrQueue(lootEntry)
    end
end

function ZO_LootHistory_Shared:AddKeepTickEntry(keepId, reason)
    if self:CanShowItemsInHistory() then
        local keepName = GetKeepName(keepId)
        local entryIcon = ZO_GetAllianceKeepRewardIcon(GetUnitAlliance("player"))
        local textId = reason == CURRENCY_CHANGE_REASON_DEFENSIVE_KEEP_REWARD and SI_LOOT_HISTORY_KEEP_REWARD_DEFENSE_TITLE or SI_LOOT_HISTORY_KEEP_REWARD_OFFENSE_TITLE
        local lootData =
        {
            text = zo_strformat(textId, keepName),
            icon = entryIcon,
            color = ZO_SELECTED_TEXT,
            entryType = LOOT_ENTRY_TYPE_KEEP_REWARD,
            showIconOverlayText = false
        }
        local lootEntry = self:CreateLootEntry(lootData)
        self:InsertOrQueue(lootEntry)
    end
end

function ZO_LootHistory_Shared:AddAntiquityLeadEntry(antiquityId)
    if self:CanShowItemsInHistory() then
        local antiquityData = ANTIQUITY_DATA_MANAGER:GetAntiquityData(antiquityId)
        local lootData =
        {
            text = zo_strformat(SI_ANTIQUITY_LEAD_NAME_FORMATTER, antiquityData:GetName()),
            icon = GetAntiquityLeadIcon(),
            color = GetAntiquityQualityColor(antiquityData:GetQuality()),
            statusIcon = self:GetStatusIcon(ZO_LOOT_HISTORY_DISPLAY_TYPE_ANTIQUITIES),
            highlight = self:GetHighlight(ZO_LOOT_HISTORY_DISPLAY_TYPE_ANTIQUITIES),
            entryType = LOOT_ENTRY_TYPE_ANTIQUITY_LEAD,
            showIconOverlayText = false
        }
        local lootEntry = self:CreateLootEntry(lootData)
        self:InsertOrQueue(lootEntry)
    end
end

do
    local COMPANION_NAME_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_UNIT_REACTION_COLOR, UNIT_REACTION_COLOR_COMPANION))
    function ZO_LootHistory_Shared:AddCompanionXpEntry(companionId, xpAdded)
        local collectibleId = GetCompanionCollectibleId(companionId)
        local formattedXpAdded = ZO_AbbreviateAndLocalizeNumber(xpAdded, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES)
        local colorizedCompanionName = COMPANION_NAME_COLOR:Colorize(GetCompanionName(companionId))
        local lootData =
        {
            text = zo_strformat(SI_LOOT_HISTORY_COMPANION_EXPERIENCE_GAIN_FORMATTER, formattedXpAdded, colorizedCompanionName),
            icon = GetCollectibleIcon(collectibleId),
            stackCount = 1,
            color = ZO_SELECTED_TEXT,
            companionId = companionId,
            companionName = colorizedCompanionName,
            gainedXp = xpAdded,
            entryType = LOOT_ENTRY_TYPE_COMPANION_EXPERIENCE,
            iconOverlayText = ZO_LootHistory_Shared.GetStackCountStringFromData,
            showIconOverlayText = ZO_LootHistory_Shared.ShouldShowStackCountStringFromData
        }
        local lootEntry = self:CreateLootEntry(lootData)
        lootEntry.isPersistent = true
        self:InsertOrQueue(lootEntry)
    end

    local RAPPORT_INCREASE_BACKGROUND_COLOR = ZO_ColorDef:New("102d0b")
    local RAPPORT_DECREASE_BACKGROUND_COLOR = ZO_ColorDef:New("3f0a0a")
    function ZO_LootHistory_Shared:AddCompanionRapportEntry(companionId, isIncrease, adjustmentAmountType)
        local rapportFormatter = isIncrease and SI_LOOT_HISTORY_COMPANION_RAPPORT_GAIN_FORMATTER or SI_LOOT_HISTORY_COMPANION_RAPPORT_LOSS_FORMATTER
        local colorizedCompanionName = COMPANION_NAME_COLOR:Colorize(GetCompanionName(companionId))
        local iconFormatter = isIncrease and LOOT_RAPPORT_INCREASE_ICON_FORMATTER or LOOT_RAPPORT_DECREASE_ICON_FORMATTER
        local lootData =
        {
            text = zo_strformat(rapportFormatter, colorizedCompanionName),
            icon = string.format(iconFormatter, adjustmentAmountType),
            color = ZO_SELECTED_TEXT,
            backgroundColor = isIncrease and RAPPORT_INCREASE_BACKGROUND_COLOR or RAPPORT_DECREASE_BACKGROUND_COLOR,
            companionId = companionId,
            companionName = colorizedCompanionName,
            entryType = LOOT_ENTRY_TYPE_COMPANION_RAPPORT,
            showIconOverlayText = false,
        }
        local lootEntry = self:CreateLootEntry(lootData)
        lootEntry.isPersistent = true
        self:InsertOrQueue(lootEntry)
    end
end

function ZO_LootHistory_Shared:AddTributeCardUpgradeEntry(cardData)
    if self:CanShowItemsInHistory() then
        local lootData =
        {
            text = cardData:GetColorizedFormattedName(),
            icon = LOOT_TRIBUTE_CARD_UPGRADE_ICON,
            color = GetItemQualityColor(cardData:GetRarity()),
            entryType = LOOT_ENTRY_TYPE_TRIBUTE_CARD_UPGRADE,
            showIconOverlayText = false,
        }
        local lootEntry = self:CreateLootEntry(lootData)
        self:InsertOrQueue(lootEntry)
    end
end

function ZO_LootHistory_Shared:OnNewItemReceived(itemLinkOrName, stackCount, itemSound, lootType, questItemIcon, itemId, isVirtual, isStolen, bonusDropSource)
    if self:CanShowItemsInHistory() then
        local itemName
        local icon
        local color
        local displayQuality

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
            displayQuality = GetItemLinkDisplayQuality(itemLinkOrName)
            color = GetItemQualityColor(displayQuality)
        end

        local statusIcon = self:GetBonusDropSourceIcon(bonusDropSource)
        if not statusIcon then
            if isVirtual then
                statusIcon = self:GetCraftBagIcon()
            elseif isStolen then
                statusIcon = self:GetStolenIcon()
            end
        end

        local highlight = nil
        if isVirtual then
            highlight = self:GetCraftBagHighlight()
        elseif isStolen then
            highlight = self:GetStolenHighlight()
        end

        local lootData =
        {
            text = zo_strformat(SI_TOOLTIP_ITEM_NAME, itemName),
            icon = icon,
            stackCount = stackCount,
            color = color,
            itemId = itemId,
            displayQuality = displayQuality,
            -- quality is deprecated, included here for addon backwards compatibility
            quality = displayQuality,
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
    if self:CanShowItemsInHistory() then
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
        local lootData =
        {
            text = collectibleData:GetFormattedName(),
            icon = collectibleData:GetIcon(),
            stackCount = 1,
            color = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, ITEM_DISPLAY_QUALITY_NORMAL)),
            collectibleId = collectibleId,
            statusIcon = self:GetStatusIcon(ZO_LOOT_HISTORY_DISPLAY_TYPE_COLLECTIONS),
            highlight = self:GetHighlight(ZO_LOOT_HISTORY_DISPLAY_TYPE_COLLECTIONS),
            entryType = LOOT_ENTRY_TYPE_COLLECTIBLE,
            iconOverlayText = ZO_LootHistory_Shared.GetStackCountStringFromData,
            showIconOverlayText = ZO_LootHistory_Shared.ShouldShowStackCountStringFromData
        }

        local lootEntry = self:CreateLootEntry(lootData)
        self:InsertOrQueue(lootEntry)
    end
end

function ZO_LootHistory_Shared:OnCurrencyUpdate(currencyType, currencyLocation, newAmount, oldAmount, reason)
    if ShouldShowCurrencyInLootHistory(currencyType) then
        if (currencyLocation == CURRENCY_LOCATION_CHARACTER or currencyLocation == CURRENCY_LOCATION_ACCOUNT) and reason ~= CURRENCY_CHANGE_REASON_PLAYER_INIT and newAmount > oldAmount then
            self:AddCurrencyEntry(newAmount - oldAmount, currencyType, currencyLocation)
        end
    end
end

function ZO_LootHistory_Shared:OnExperienceGainUpdate(reason, level, previousExperience, currentExperience)
    local difference = currentExperience - previousExperience
    self:AddXpEntry(difference)
end

function ZO_LootHistory_Shared:OnMedalAwarded(medalId, name, icon, value)
    self:AddMedalEntry(medalId, name, icon, value)
end

function ZO_LootHistory_Shared:OnBattlegroundEnteredPostGame()
    local playerIndex = GetScoreboardLocalPlayerEntryIndex()
    self:AddScoreEntry(GetScoreboardEntryScoreByType(playerIndex, SCORE_TRACKER_TYPE_SCORE))
end

function ZO_LootHistory_Shared:OnKeepTickAwarded(keepId, reason)
    self:AddKeepTickEntry(keepId, reason)
end

do
    local ALLOWED_SKILL_TYPES = 
    {
        [SKILL_TYPE_GUILD] = true
    }

    function ZO_LootHistory_Shared:OnSkillExperienceUpdated(skillType, skillLineIndex, reason, rank, previousXP, currentXP)
        local differenceXP = currentXP - previousXP
        if differenceXP > 0 and ALLOWED_SKILL_TYPES[skillType] then
            local skillLineData = SKILLS_DATA_MANAGER:GetSkillLineDataByIndices(skillType, skillLineIndex)
            self:AddSkillEntry(skillLineData, differenceXP)
        end
    end
end

function ZO_LootHistory_Shared:OnCrownCrateQuantityUpdated(lootCrateId, oldCount, newCount)
    local delta = newCount - oldCount
    if delta > 0 then
        self:AddCrownCrateEntry(lootCrateId, delta)
    end
end

function ZO_LootHistory_Shared:OnAntiquityLeadAcquired(antiquityId)
    self:AddAntiquityLeadEntry(antiquityId)
end

function ZO_LootHistory_Shared:OnCompanionExperienceGainUpdate(companionId, level, previousXP, currentXP)
    local gainedXP = currentXP - previousXP
    if gainedXP > 0 then
        self:AddCompanionXpEntry(companionId, gainedXP)
    end
end

function ZO_LootHistory_Shared:OnCompanionRapportUpdate(companionId, previousRapport, currentRapport, adjustmentAmountType)
    if currentRapport ~= previousRapport then
        self:AddCompanionRapportEntry(companionId, currentRapport > previousRapport, adjustmentAmountType)
    end
end

function ZO_LootHistory_Shared:OnTributeProgressionUpgradeStatusChanged(patronId, changedProgressions, refreshReason)
    if refreshReason == ZO_TRIBUTE_PATRON_PROGRESSION_REFRESH_REASON.DATA_CHANGED then
        for _, progressionData in ipairs(changedProgressions) do
            if progressionData:HasUpgrade() then
                local upgradeCardData = ZO_TributeCardData:New(patronId, progressionData:GetUpgradeCardId())
                self:AddTributeCardUpgradeEntry(upgradeCardData)
            end
        end
    end
end

do
    function ZO_LootHistory_Shared.GetStackCountStringFromData(data)
        return ZO_AbbreviateAndLocalizeNumber(data.stackCount, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES)
    end

    function ZO_LootHistory_Shared.GetValueStringFromData(data)
        return ZO_AbbreviateAndLocalizeNumber(data.value, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES)
    end
end

function ZO_LootHistory_Shared.ShouldShowStackCountStringFromData(data)
    if data.entryType == LOOT_ENTRY_TYPE_CURRENCY then
        return data.stackCount > 0
    else
        return data.stackCount > 1
    end
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

ZO_LootHistory_Shared.GetBonusDropSourceIcon = ZO_LootHistory_Shared:MUST_IMPLEMENT()
ZO_LootHistory_Shared.GetHighlight = ZO_LootHistory_Shared:MUST_IMPLEMENT()
ZO_LootHistory_Shared.GetStatusIcon = ZO_LootHistory_Shared:MUST_IMPLEMENT()
ZO_LootHistory_Shared.InitializeFadingControlBuffer = ZO_LootHistory_Shared:MUST_IMPLEMENT()
ZO_LootHistory_Shared.InitializeFragment = ZO_LootHistory_Shared:MUST_IMPLEMENT()
ZO_LootHistory_Shared.SetEntryTemplate = ZO_LootHistory_Shared:MUST_IMPLEMENT()

function ZO_LootHistory_Shared:CanShowItemsInHistory()
    return false -- default value
end

-- legacy functions

function ZO_LootHistory_Shared:GetCraftBagIcon()
    return self:GetStatusIcon(ZO_LOOT_HISTORY_DISPLAY_TYPE_CRAFT_BAG)
end

function ZO_LootHistory_Shared:GetStolenIcon()
    return self:GetStatusIcon(ZO_LOOT_HISTORY_DISPLAY_TYPE_STOLEN)
end

function ZO_LootHistory_Shared:GetCraftBagHighlight()
    return self:GetHighlight(ZO_LOOT_HISTORY_DISPLAY_TYPE_CRAFT_BAG)
end

function ZO_LootHistory_Shared:GetStolenHighlight()
    return self:GetHighlight(ZO_LOOT_HISTORY_DISPLAY_TYPE_STOLEN)
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
