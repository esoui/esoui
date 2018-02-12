local LevelUpRewardsManager = ZO_CallbackObject:Subclass()

function LevelUpRewardsManager:New(...)
    local obj = ZO_CallbackObject.New(self)
    obj:Initialize(...)
    return obj
end

function LevelUpRewardsManager:Initialize()
    self:RegisterForEvents()
end

function LevelUpRewardsManager:RegisterForEvents()
    EVENT_MANAGER:RegisterForEvent("LevelUpRewardsManager", EVENT_LEVEL_UP_REWARD_UPDATED, function(eventCode) self:OnLevelUpRewardsUpdated() end)
    EVENT_MANAGER:RegisterForEvent("LevelUpRewardsManager", EVENT_LEVEL_UP_REWARD_CHOICE_UPDATED, function(eventCode) self:OnLevelUpRewardsChoiceUpdated() end)
    local function OnPlayerActivated()
        self:UpdatePendingLevelUpRewards()
    end
    EVENT_MANAGER:RegisterForEvent("LevelUpRewardsManager", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
end

function LevelUpRewardsManager:OnLevelUpRewardsUpdated()
    self:UpdatePendingLevelUpRewards()

    self:FireCallbacks("OnLevelUpRewardsUpdated")
end

function LevelUpRewardsManager:OnLevelUpRewardsChoiceUpdated()
    for index, entryInfo in ipairs(self.pendingLevelUpRewards) do
        if entryInfo.choices then
            for choiceIndex, choiceEntryInfo in ipairs(entryInfo.choices) do
                choiceEntryInfo.isSelectedChoice = IsLevelUpRewardChoiceSelected(entryInfo.entryIndex, choiceIndex)
            end
        end
    end

    self:FireCallbacks("OnLevelUpRewardsChoiceUpdated")
end

function LevelUpRewardsManager:UpdatePendingLevelUpRewards()
    self.pendingRewardLevel = GetPendingLevelUpRewardLevel()
    if self.pendingRewardLevel then
        self.pendingRewardId = GetLevelUpRewardId(self.pendingRewardLevel)
        self.pendingLevelUpRewards = self:GetRewardEntryInfoForReward(self.pendingRewardId)
        self:GetAdditionalUnlocksForLevel(self.pendingRewardLevel, self.pendingLevelUpRewards)
        table.sort(self.pendingLevelUpRewards, function(...) return self:SortRewardEntries(...) end)
    else
        self.pendingRewardId = nil
        self.pendingLevelUpRewards = nil
    end

    self.upcomingRewardLevel = GetUpcomingLevelUpRewardLevel()
    if self.upcomingRewardLevel then
        self.upcomingRewardId = GetLevelUpRewardId(self.upcomingRewardLevel)
        self.upcomingLevelUpRewards = self:GetRewardEntryInfoForReward(self.upcomingRewardId)
        self:GetAdditionalUnlocksForLevel(self.upcomingRewardLevel, self.upcomingLevelUpRewards)
        table.sort(self.upcomingLevelUpRewards, function(...) return self:SortRewardEntries(...) end)
    else
        self.upcomingRewardId = nil
        self.upcomingLevelUpRewards = nil
    end

    local nextMilestoneRewardLevel = GetNextLevelUpRewardMilestoneLevel()
    if nextMilestoneRewardLevel and nextMilestoneRewardLevel ~= self.upcomingRewardLevel then
        self.upcomingMilestoneRewardLevel = nextMilestoneRewardLevel
        self.upcomingMilestoneRewardId = GetLevelUpRewardId(self.upcomingMilestoneRewardLevel)
        self.upcomingMilestoneLevelUpRewards = self:GetRewardEntryInfoForReward(self.upcomingMilestoneRewardId)
        self:GetAdditionalUnlocksForLevel(self.upcomingMilestoneRewardLevel, self.upcomingMilestoneLevelUpRewards)
        table.sort(self.upcomingMilestoneLevelUpRewards, function(...) return self:SortRewardEntries(...) end)
    else
        self.upcomingMilestoneRewardLevel = nil
        self.upcomingMilestoneRewardId = nil
        self.upcomingMilestoneLevelUpRewards = nil
    end
end

function LevelUpRewardsManager:GetPendingRewardLevel()
    return self.pendingRewardLevel
end

function LevelUpRewardsManager:GetPendingRewardId()
    return self.pendingRewardId
end

function LevelUpRewardsManager:GetPendingLevelUpRewards()
    return self.pendingLevelUpRewards
end

function LevelUpRewardsManager:GetUpcomingRewardLevel()
    return self.upcomingRewardLevel
end

function LevelUpRewardsManager:GetUpcomingRewardId()
    return self.upcomingRewardId
end

function LevelUpRewardsManager:GetUpcomingLevelUpRewards()
    return self.upcomingLevelUpRewards
end

function LevelUpRewardsManager:GetUpcomingMilestoneRewardLevel()
    return self.upcomingMilestoneRewardLevel
end

function LevelUpRewardsManager:GetUpcomingMilestoneRewardId()
    return self.upcomingMilestoneRewardId
end

function LevelUpRewardsManager:GetUpcomingMilestoneLevelUpRewards()
    return self.upcomingMilestoneLevelUpRewards
end

function LevelUpRewardsManager:GetRewardEntryInfoForReward(rewardId, parentChoice)
    local rewardEntryInfo = {}
    local numRewardEntries = GetNumRewardEntries(rewardId)

    for entryIndex = 1, numRewardEntries do
        local entryType = GetRewardEntryType(rewardId, entryIndex)
        local entryInfo
        if entryType == REWARD_ENTRY_TYPE_ADD_CURRENCY then
            entryInfo = self:GetCurrencyEntryInfo(rewardId, entryIndex, parentChoice)
        elseif entryType == REWARD_ENTRY_TYPE_COLLECTIBLE then
            entryInfo = self:GetCollectibleEntryInfo(rewardId, entryIndex, parentChoice)
        elseif entryType == REWARD_ENTRY_TYPE_ITEM then
            entryInfo = self:GetItemEntryInfo(rewardId, entryIndex, parentChoice)
        elseif entryType == REWARD_ENTRY_TYPE_LOOT_CRATE then
            entryInfo = self:GetCrownCrateEntryInfo(rewardId, entryIndex, parentChoice)
        elseif entryType == REWARD_ENTRY_TYPE_CHOICE then
            entryInfo = self:GetChoiceEntryInfo(rewardId, entryIndex, parentChoice)
        elseif entryType == REWARD_ENTRY_TYPE_INSTANT_UNLOCK then
            entryInfo = self:GetInstantUnlockEntryInfo(rewardId, entryIndex, parentChoice)
        end

        if entryInfo then
            entryInfo.rewardType = entryType
            entryInfo.validationFunction = function() return IsLevelUpRewardValidForPlayer(rewardId, entryIndex) end
            if parentChoice then
                entryInfo.isSelectedChoice = IsLevelUpRewardChoiceSelected(parentChoice.entryIndex, entryIndex)
            end
            table.insert(rewardEntryInfo, entryInfo)
        end
    end
    return rewardEntryInfo
end

function LevelUpRewardsManager:GetCurrencyEntryInfo(rewardId, entryIndex, parentChoice)
    local currencyType, amount = GetAddCurrencyRewardEntryInfo(rewardId, entryIndex)
    local IS_PLURAL = false
    local IS_UPPER = false
    local formattedName = GetCurrencyName(currencyType, IS_PLURAL, IS_LOWER)
    local formattedNameWithStackKeyboard = zo_strformat(SI_LOOT_CURRENCY_FORMAT, ZO_Currency_FormatKeyboard(currencyType, amount, ZO_CURRENCY_FORMAT_AMOUNT_NAME))
    local formattedNameWithStackGamepad = zo_strformat(SI_LOOT_CURRENCY_FORMAT, ZO_Currency_FormatGamepad(currencyType, amount, ZO_CURRENCY_FORMAT_AMOUNT_NAME))
    local icon = IsInGamepadPreferredMode() and GetCurrencyLootGamepadIcon(currencyType) or GetCurrencyLootKeyboardIcon(currencyType)
    local currencyInfo =
    {
        rewardId = rewardId,
        entryIndex = entryIndex,
        parentChoice = parentChoice,
        formattedName = formattedName,
        formattedNameWithStackKeyboard = formattedNameWithStackKeyboard,
        formattedNameWithStackGamepad = formattedNameWithStackGamepad,
        stackCount = amount,
        quality = ITEM_QUALITY_NORMAL,
        icon = icon,
        currencyType = currencyType,
    }
    return currencyInfo
end

function LevelUpRewardsManager:GetCollectibleEntryInfo(rewardId, entryIndex, parentChoice)
    local collectibleId = GetCollectibleRewardEntryCollectibleId(rewardId, entryIndex)
    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
    if collectibleData then
        local collectibleInfo =
        {
            rewardId = rewardId,
            entryIndex = entryIndex,
            parentChoice = parentChoice,
            formattedName = collectibleData:GetFormattedName(),
            stackCount = 1,
            quality = ITEM_QUALITY_NORMAL,
            icon = collectibleData:GetIcon(),
        }
        return collectibleInfo
    end

    return nil
end

function LevelUpRewardsManager:GetItemEntryInfo(rewardId, entryIndex, parentChoice)
    local itemLink = GetItemRewardEntryItemLink(rewardId, entryIndex)
    local displayName = GetItemLinkName(itemLink)
    local itemQuality = GetItemLinkQuality(itemLink)
    local icon = GetItemLinkIcon(itemLink)
    local stackCount = GetItemRewardEntryStackCount(rewardId, entryIndex)
    local equipType = GetItemLinkEquipType(itemLink)
    local equipSlot = ZO_InventoryUtils_GetEquipSlotForEquipType(equipType)

    local itemInfo =
    {
        rewardId = rewardId,
        entryIndex = entryIndex,
        parentChoice = parentChoice,
        formattedName = zo_strformat(SI_TOOLTIP_ITEM_NAME, displayName),
        formattedNameWithStack = zo_strformat(SI_LEVEL_UP_REWARDS_FORMAT_REWARD_WITH_AMOUNT, displayName, ZO_SELECTED_TEXT:Colorize(stackCount)),
        stackCount = stackCount,
        quality = itemQuality,
        icon = icon,
        equipSlot = equipSlot,
    }
    return itemInfo
end

function LevelUpRewardsManager:GetCrownCrateEntryInfo(rewardId, entryIndex, parentChoice)
    local crateId = GetCrownCrateRewardEntryCrateId(rewardId, entryIndex)
    local quantity = GetCrownCrateRewardEntryAmount(rewardId, entryIndex)
    local icon = GetCrownCrateIcon(crateId)

    local displayName = GetCrownCrateName(crateId)
    local formattedDisplayName = zo_strformat(SI_TOOLTIP_ITEM_NAME, displayName)
    local formattedNameWithStack = zo_strformat(SI_LEVEL_UP_REWARDS_FORMAT_REWARD_WITH_AMOUNT, displayName, ZO_SELECTED_TEXT:Colorize(quantity))
    local crateInfo =
    {
        rewardId = rewardId,
        entryIndex = entryIndex,
        parentChoice = parentChoice,
        formattedName = formattedDisplayName,
        formattedNameWithStack = formattedNameWithStack,
        stackCount = quantity,
        quality = ITEM_QUALITY_NORMAL,
        icon = icon,
    }
    return crateInfo
end

function LevelUpRewardsManager:GetChoiceEntryInfo(rewardId, entryIndex, parentChoice)
    local choiceRewardId = GetChoiceRewardEntryLinkedRewardId(rewardId, entryIndex)

    local choiceInfo =
    {
        rewardId = rewardId,
        entryIndex = entryIndex,
        parentChoice = parentChoice,
        formattedName = GetChoiceRewardEntryDisplayName(rewardId, entryIndex),
        icon = GetChoiceRewardEntryIcon(rewardId, entryIndex),
    }

    local choices = self:GetRewardEntryInfoForReward(choiceRewardId, choiceInfo)
    table.sort(choices, function(...) return self:SortRewardEntries(...) end)
    choiceInfo.choices = choices

    return choiceInfo
end

function LevelUpRewardsManager:GetInstantUnlockEntryInfo(rewardId, entryIndex, parentChoice)
    local instantUnlockId = GetInstantUnlockRewardEntryInstantUnlockId(rewardId, entryIndex)
    local icon = GetInstantUnlockRewardIcon(instantUnlockId)
    local displayName = GetInstantUnlockRewardDisplayName(instantUnlockId)
    local instantUnlockInfo =
    {
        rewardId = rewardId,
        entryIndex = entryIndex,
        parentChoice = parentChoice,
        formattedName = displayName,
        stackCount = 1,
        quality = ITEM_QUALITY_NORMAL,
        icon = icon,
    }
    return instantUnlockInfo
end

function LevelUpRewardsManager:SortRewardEntries(data1, data2)
    -- entries with choices sort to the end
    local data1Choices = data1.choices
    local data2Choices = data2.choices

    if data1Choices ~= nil and data2Choices ~= nil then
        if #data1Choices ~= #data2Choices then
            return #data1Choices < #data2Choices
        end
    elseif data1Choices ~= data2Choices then
        return data1Choices == nil
    end

    if data1.isAdditionalUnlock ~= data2.isAdditionalUnlock then
        return not data1.isAdditionalUnlock
    elseif data1.isAdditionalUnlock then
        return data1.formattedName < data2.formattedName
    end

    return data1.entryIndex < data2.entryIndex
end

function LevelUpRewardsManager:GetAdditionalUnlocksForLevel(level, rewardInfoTable)
    local additionalUnlocks = rewardInfoTable or {}
    local numAdditionalUnlocks = GetNumAdditionalLevelUpUnlocks(level)

    for index = 1, numAdditionalUnlocks do
        local formattedDisplayName = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetAdditionalLevelUpUnlockDisplayName(level, index))
        local unlockInfo =
        {
            formattedName = formattedDisplayName,
            gamepadIcon = GetAdditionalLevelUpUnlockGamepadIcon(level, index),
            keyboardIcon = GetAdditionalLevelUpUnlockKeyboardIcon(level, index),
            description = GetAdditionalLevelUpUnlockDescription(level, index),
            isAdditionalUnlock = true,
        }
        table.insert(additionalUnlocks, unlockInfo)
    end

    return additionalUnlocks
end

function LevelUpRewardsManager:GetPlatformAttributePointIcon()
    if IsInGamepadPreferredMode() then
        return "EsoUI/Art/LevelUpRewards/gamepad/levelup_gp_attribute_32.dds"
    else
        return "EsoUI/Art/LevelUpRewards/levelup_attribute_64.dds"
    end
end

function LevelUpRewardsManager:GetPlatformSkillPointIcon()
    if IsInGamepadPreferredMode() then
        return "EsoUI/Art/LevelUpRewards/gamepad/levelup_gp_skillpt_32.dds"
    else
        return "EsoUI/Art/LevelUpRewards/levelup_skillpt_64.dds"
    end
end

function LevelUpRewardsManager:GetAttributePointEntryInfo(attributePoints)
    local attributePointInfo =
    {
        formattedName = zo_strformat(SI_LEVEL_UP_REWARDS_ATTRIBUTE_POINTS_ENTRY_FORMATTER, ZO_SELECTED_TEXT:Colorize(attributePoints)),
        icon = self:GetPlatformAttributePointIcon(),
        isAttributePoint = true,
    }

    return attributePointInfo
end

function LevelUpRewardsManager:GetSkillPointEntryInfo(skillPoints)
    local skillPointInfo =
    {
        formattedName = zo_strformat(SI_LEVEL_UP_REWARDS_SKILL_POINTS_ENTRY_FORMATTER, ZO_SELECTED_TEXT:Colorize(skillPoints)),
        icon = self:GetPlatformSkillPointIcon(),
        isSkillPoint = true,
    }

    return skillPointInfo
end

function LevelUpRewardsManager:GetPlatformIconFromRewardData(rewardData)
    local icon = rewardData.icon
    if icon == nil then
        if IsInGamepadPreferredMode() then
            icon = rewardData.gamepadIcon
        else
            icon = rewardData.keyboardIcon
        end
    end

    return icon
end

function LevelUpRewardsManager:GetPlatformFormattedNameFromRewardData(rewardData)
    local name = rewardData.formattedName
    if name == nil then
        if IsInGamepadPreferredMode() then
            name = rewardData.formattedNameGamepad
        else
            name = rewardData.formattedNameKeyboard
        end
    end

    return name
end

function LevelUpRewardsManager:GetPlatformFormattedStackNameFromRewardData(rewardData)
    local name = rewardData.formattedNameWithStack
    if name == nil then
        if IsInGamepadPreferredMode() then
            name = rewardData.formattedNameWithStackGamepad
        else
            name = rewardData.formattedNameWithStackKeyboard
        end
    end

    return name
end

function LevelUpRewardsManager:GetPendingRewardNameFromRewardData(rewardData)
    local name = self:GetPlatformFormattedNameFromRewardData(rewardData)
    if not IsInGamepadPreferredMode() then
        if rewardData.rewardType and rewardData.rewardType == REWARD_ENTRY_TYPE_ADD_CURRENCY then
            name = self:GetPlatformFormattedStackNameFromRewardData(rewardData)
        end
    end
    return name
end

function LevelUpRewardsManager:GetUpcomingRewardNameFromRewardData(rewardData)
    local name = self:GetPlatformFormattedStackNameFromRewardData(rewardData)

    if name == nil then
        name = self:GetPlatformFormattedNameFromRewardData(rewardData)
    end
    return name
end

do
    local QuickBendEasing = ZO_GenerateCubicBezierEase(0.38, 0.21, 0.75, 0.24)
    local LateBendEasing = ZO_GenerateCubicBezierEase(0.38, 0.21, 0.84, 0.24)
    local sparkStartColorGenerator = ZO_WeightedChoiceGenerator:New(
        {0.7, 0.7, 0.4}, 0.1,
        {0.8, 0.3, 0.3}, 0.3,
        {1.0, 1.0, 0.0}, 0.3,
        {1.0, 0.5, 0.0}, 0.3)
        
    function LevelUpRewardsManager:CreateArtAreaParticleSystem(artControl)
        local halfArtWidth = artControl:GetWidth() * 0.5
        local artHeight = artControl:GetHeight()
        local halfArtHeight = artHeight * 0.5
        local particleSystem = ZO_ControlParticleSystem:New(ZO_BentArcParticle_Control)
        particleSystem:SetParentControl(artControl)
        particleSystem:SetParticleParameter("Texture", "EsoUI/Art/PregameAnimatedBackground/ember.dds")
        particleSystem:SetParticleParameter("BentArcElevationStartRadians", ZO_UniformRangeGenerator:New(0.3 * math.pi, 0.7 *math.pi))
        particleSystem:SetParticleParameter("BentArcElevationChangeRadians", ZO_UniformRangeGenerator:New(-0.8, 0.8))
        particleSystem:SetParticleParameter("BentArcAzimuthStartRadians", 0)
        particleSystem:SetParticleParameter("BentArcAzimuthChangeRadians", 0)
        particleSystem:SetParticleParameter("BentArcFinalMagnitude", artHeight * 1.3)
        particleSystem:SetParticleParameter("Size", 8)
        particleSystem:SetParticleParameter("StartScale", ZO_UniformRangeGenerator:New(1.1, 1.4))
        particleSystem:SetParticleParameter("EndScale", ZO_UniformRangeGenerator:New(0.7, 1))
        particleSystem:SetParticleParameter("DurationS", 0.8)
        particleSystem:SetParticleParameter("StartAlpha", 0.4)
        particleSystem:SetParticleParameter("EndAlpha", 0.0)
        particleSystem:SetParticleParameter("StartColorR", "StartColorG", "StartColorB", sparkStartColorGenerator)
        particleSystem:SetParticleParameter("EndColorR", 0.6)
        particleSystem:SetParticleParameter("EndColorG", 0.6)
        particleSystem:SetParticleParameter("EndColorB", 1)
        particleSystem:SetParticleParameter("BentArcBendEasing", ZO_WeightedChoiceGenerator:New(QuickBendEasing, 0.4, LateBendEasing, 0.6))
        particleSystem:SetParticleParameter("StartOffsetX", "EndOffsetX", ZO_UniformRangeGenerator:New(-halfArtWidth, halfArtWidth, -halfArtWidth, halfArtWidth))
        particleSystem:SetParticleParameter("StartOffsetY", halfArtHeight)
        particleSystem:SetParticleParameter("EndOffsetY", halfArtHeight)
        particleSystem:SetParticleParameter("BlendMode", TEX_BLEND_MODE_ADD)
        return particleSystem
    end
end

function LevelUpRewardsManager:IsRewardDataValidForPlayer(rewardData)
    if rewardData.validationFunction then
        return rewardData.validationFunction() == true
    else
        return true
    end
end

ZO_LEVEL_UP_REWARDS_MANAGER = LevelUpRewardsManager:New()
