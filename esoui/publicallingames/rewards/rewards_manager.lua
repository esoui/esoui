-- TODO: One day I'd like to fold LFGReward into the RewardDef system. This is a stop gap solution.
-- This will allow us to eaily define unique custom reward types that won't collide with the REWARD_ENTRY_TYPE enum values
ZO_REWARD_CUSTOM_ENTRY_TYPE =
{
    LFG_ACTIVITY = { 1 },
}

ZO_RewardData = ZO_InitializingObject:Subclass()

function ZO_RewardData:Initialize(rewardId, parentChoice)
    self.rewardId = rewardId
    self.parentChoice = parentChoice
end

function ZO_RewardData:SetQuantity(quantity)
    self.quantity = quantity
end

function ZO_RewardData:SetAbbreviatedQuantity(abbreviatedQuantity)
    self.abbreviatedQuantity = abbreviatedQuantity
end

function ZO_RewardData:SetIcon(icon, gamepadIcon)
    self.icon = icon
    self.gamepadIcon = gamepadIcon
end

function ZO_RewardData:SetLootIcon(icon, gamepadIcon)
    self.lootIcon = icon
    self.gamepadLootIcon = gamepadIcon
end

function ZO_RewardData:SetFormattedName(formattedName)
    self.formattedName = formattedName
end

function ZO_RewardData:SetRawName(rawName)
    self.rawName = rawName
end    

function ZO_RewardData:SetFormattedNameWithStack(keyboardName, gamepadName)
    self.formattedNameWithStackKeyboard = keyboardName
    self.formattedNameWithStackGamepad = gamepadName
end

function ZO_RewardData:SetChoiceIndex(choiceIndex)
    self.choiceIndex = choiceIndex
end

function ZO_RewardData:SetItemLink(itemLink)
    self.itemLink = itemLink
end

function ZO_RewardData:SetItemFunctionalQuality(itemFunctionalQuality)
    self.functionalQuality = itemFunctionalQuality
end

function ZO_RewardData:SetItemDisplayQuality(itemDisplayQuality)
    self.displayQuality = itemDisplayQuality
    -- self.quality is deprecated, included here for addon backwards compatibility
    self.quality = itemDisplayQuality
end

function ZO_RewardData:SetCurrencyInfo(currencyType)
    self.currencyType = currencyType
end

function ZO_RewardData:SetEquipSlot(equipSlot)
    self.equipSlot = equipSlot
end

function ZO_RewardData:SetSkillLineId(skillLineId)
    self.skillLineId = skillLineId
end

function ZO_RewardData:SetChoices(rewardChoices)
    self.choices = rewardChoices
end

function ZO_RewardData:SetRewardType(rewardType)
    self.rewardType = rewardType
end

function ZO_RewardData:SetValidationFunction(validationFunction)
    self.validationFunction = validationFunction
end

function ZO_RewardData:SetIsSelectedChoice(isSelectedChoice)
    if self:GetParentChoice() then
        self.isSelectedChoice = isSelectedChoice
    end
end

function ZO_RewardData:SetColor(colorDef)
    self.colorDef = colorDef
end

function ZO_RewardData:SetAnnouncementBackground(announcementBackground)
    self.announcementBackground = announcementBackground
end

function ZO_RewardData:GetEquipSlot()
    return self.equipSlot
end

function ZO_RewardData:GetCurrencyType()
    return self.currencyType
end

function ZO_RewardData:GetItemLink()
    return self.itemLink
end

function ZO_RewardData:GetItemFunctionalQuality()
    -- self.quality is deprecated, included here for addon backwards compatibility
    return self.functionalQuality or self.quality or ITEM_FUNCTIONAL_QUALITY_NORMAL
end

function ZO_RewardData:GetItemDisplayQuality()
    -- self.quality is deprecated, included here for addon backwards compatibility
    return self.displayQuality or self.quality or ITEM_DISPLAY_QUALITY_NORMAL
end

function ZO_RewardData:GetSkillLineId()
    return self.skillLineId
end

function ZO_RewardData:GetKeyboardIcon()
    return self.icon
end

function ZO_RewardData:GetGamepadIcon()
    -- if no gamepadIcon is used, icon is used for both
    return self.gamepadIcon or self.icon
end

function ZO_RewardData:GetPlatformIcon()
    if IsInGamepadPreferredMode() then
        return self:GetGamepadIcon()
    else
        return self:GetKeyboardIcon()
    end
end

function ZO_RewardData:GetKeyboardLootIcon()
    return self.lootIcon or self:GetKeyboardIcon()
end

function ZO_RewardData:GetGamepadLootIcon()
    -- If no gamepadLootIcon is used, lootIcon is used for both.
    -- If neither exist we fall back to regular non-loot icon behavior
    return self.gamepadLootIcon or self.lootIcon or self:GetGamepadIcon()
end

function ZO_RewardData:GetPlatformLootIcon()
    if IsInGamepadPreferredMode() then
        return self:GetGamepadLootIcon()
    else
        return self:GetKeyboardLootIcon()
    end
end

function ZO_RewardData:GetQuantity()
    return self.quantity or 1
end

function ZO_RewardData:GetAbbreviatedQuantity()
    return self.abbreviatedQuantity or self:GetQuantity()
end

function ZO_RewardData:GetRewardId()
    return self.rewardId
end

function ZO_RewardData:GetParentChoice()
    return self.parentChoice
end

function ZO_RewardData:GetRawName()
    return self.rawName
end

function ZO_RewardData:GetFormattedName()
    return self.formattedName
end

function ZO_RewardData:GetFormattedNameWithStack()
    return self.formattedNameWithStackKeyboard
end

function ZO_RewardData:GetFormattedNameWithStackGamepad()
    -- if there is no gamepad name, the keyboard name is used for both
    return self.formattedNameWithStackGamepad or self.formattedNameWithStackKeyboard
end

function ZO_RewardData:GetChoices()
    return self.choices
end

function ZO_RewardData:GetRewardType()
    return self.rewardType
end

function ZO_RewardData:GetColor()
    return self.colorDef
end

function ZO_RewardData:IsValidReward()
    return not self.validationFunction or self.validationFunction() == true
end

function ZO_RewardData:GetAnnouncementBackground()
    return self.announcementBackground
end

function ZO_RewardData:SetDisplayFlags(displayFlags)
    self.displayFlags = displayFlags
end

function ZO_RewardData:GetDisplayFlags()
    return self.displayFlags
end

---------------------
-- Rewards Manager
---------------------

ZO_RewardsManager = ZO_CallbackObject:Subclass()

function ZO_RewardsManager:New(...)
    local rewards = ZO_CallbackObject.New(self)
    rewards:Initialize(...)
    return rewards
end

function ZO_RewardsManager:Initialize()
    
end

do
    local PARENT_CHOICE = nil
    local VALIDATION_FUNCTION = nil
    local SELECTED_CHOICE_FUNCTION = nil
    function ZO_RewardsManager:GetInfoForDailyLoginReward(rewardId, quantity)
        return self:GetInfoForReward(rewardId, quantity, PARENT_CHOICE, VALIDATION_FUNCTION, SELECTED_CHOICE_FUNCTION)
    end
end

function ZO_RewardsManager:GetAllRewardInfoForRewardList(rewardListId, parentChoice, validationFunction, isSelectedChoiceFunction)
    local rewardListInfo = {}
    local numRewards = GetNumRewardListEntries(rewardListId)

    for rewardIndex = 1, numRewards do
        local rewardId, entryType, quantity = GetRewardListEntryInfo(rewardListId, rewardIndex)
        local rewardData = self:GetInfoForReward(rewardId, quantity, parentChoice, validationFunction, isSelectedChoiceFunction)

        if rewardData then
            rewardData:SetChoiceIndex(rewardIndex)
            table.insert(rewardListInfo, rewardData)
        end
    end
    return rewardListInfo
end

function ZO_RewardsManager:DoesRewardListContainMailItems(rewardListId)
    local numRewards = GetNumRewardListEntries(rewardListId)

    for rewardIndex = 1, numRewards do
        local rewardId, entryType = GetRewardListEntryInfo(rewardListId, rewardIndex)
        if entryType == REWARD_ENTRY_TYPE_MAIL_ITEM then
            return true
        end
    end
    return false
end

function ZO_RewardsManager:GetInfoForReward(rewardId, quantity, parentChoice, validationFunction, isSelectedChoiceFunction)
    local entryType = GetRewardType(rewardId)
    local rewardData
    if entryType == REWARD_ENTRY_TYPE_ADD_CURRENCY then
        rewardData = self:GetCurrencyEntryInfo(rewardId, quantity, parentChoice)
    elseif entryType == REWARD_ENTRY_TYPE_COLLECTIBLE then
        rewardData = self:GetCollectibleEntryInfo(rewardId, parentChoice)
    elseif entryType == REWARD_ENTRY_TYPE_ITEM then
        rewardData = self:GetItemEntryInfo(rewardId, quantity, parentChoice)
    elseif entryType == REWARD_ENTRY_TYPE_LOOT_CRATE then
        rewardData = self:GetCrownCrateEntryInfo(rewardId, quantity, parentChoice)
    elseif entryType == REWARD_ENTRY_TYPE_CHOICE then
        rewardData = self:GetChoiceEntryInfo(rewardId, parentChoice, validationFunction, isSelectedChoiceFunction)
    elseif entryType == REWARD_ENTRY_TYPE_INSTANT_UNLOCK then
        rewardData = self:GetInstantUnlockEntryInfo(rewardId, parentChoice)
    elseif entryType == REWARD_ENTRY_TYPE_EXPERIENCE then
        rewardData = self:GetExperienceEntryInfo(rewardId, quantity, parentChoice)
    elseif entryType == REWARD_ENTRY_TYPE_SKILL_LINE_EXPERIENCE then
        rewardData = self:GetSkillLineExperienceEntryInfo(rewardId, quantity, parentChoice)
    elseif entryType == REWARD_ENTRY_TYPE_TRIBUTE_CARD_UPGRADE then
        rewardData = self:GetTributeCardUpgradeEntryInfo(rewardId, parentChoice)
    end

    if rewardData then
        rewardData:SetRewardType(entryType)
        if validationFunction then
            rewardData:SetValidationFunction(function() return validationFunction(rewardId) end)
        end

        if parentChoice then
            rewardData:SetIsSelectedChoice(isSelectedChoiceFunction and isSelectedChoiceFunction(parentChoice.rewardId, rewardData.rewardId))
        end
    end
    return rewardData
end

function ZO_RewardsManager:GetChoiceEntryInfo(rewardId, parentChoice, validationFunction, isSelectedChoiceFunction)
    local choiceListId = GetChoiceRewardListId(rewardId)

    local rewardData = ZO_RewardData:New(rewardId, parentChoice)
    local rawName = GetChoiceRewardDisplayName(rewardId)
    -- There doesn't seem to be any special formatting done for "Choice rewards," so the raw name and formatted name are the same in this instance.
    rewardData:SetRawName(rawName)
    rewardData:SetFormattedName(rawName)
    rewardData:SetIcon(GetChoiceRewardIcon(rewardId))
    rewardData:SetAnnouncementBackground(GetRewardAnnouncementBackgroundFileIndex(rewardId))

    local choices = self:GetAllRewardInfoForRewardList(choiceListId, rewardData, validationFunction, isSelectedChoiceFunction)
    table.sort(choices, function(...) return self:SortChoiceRewardEntries(...) end)
    rewardData:SetChoices(choices)

    return rewardData
end

function ZO_RewardsManager:GetCurrencyEntryInfo(rewardId, quantity, parentChoice)
    local currencyType = GetAddCurrencyRewardInfo(rewardId)
    local IS_PLURAL = false
    local IS_UPPER = false
    local rawName = GetCurrencyName(currencyType, IS_PLURAL, IS_UPPER)
    local formattedName = zo_strformat(SI_CURRENCY_NAME_FORMAT, rawName)
    local formattedNameWithStackKeyboard = zo_strformat(SI_CURRENCY_NAME_FORMAT, ZO_Currency_FormatKeyboard(currencyType, quantity, ZO_CURRENCY_FORMAT_AMOUNT_NAME))
    local formattedNameWithStackGamepad = zo_strformat(SI_CURRENCY_NAME_FORMAT, ZO_Currency_FormatGamepad(currencyType, quantity, ZO_CURRENCY_FORMAT_AMOUNT_NAME))
    local abbreviatedQuantity = ZO_AbbreviateAndLocalizeNumber(quantity, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES)

    local rewardData = ZO_RewardData:New(rewardId, parentChoice)
    rewardData:SetRawName(rawName)
    rewardData:SetFormattedName(formattedName)
    rewardData:SetIcon(GetCurrencyKeyboardIcon(currencyType), GetCurrencyGamepadIcon(currencyType))
    rewardData:SetLootIcon(GetCurrencyLootKeyboardIcon(currencyType), GetCurrencyLootGamepadIcon(currencyType))
    rewardData:SetFormattedNameWithStack(formattedNameWithStackKeyboard, formattedNameWithStackGamepad)
    rewardData:SetQuantity(quantity)
    rewardData:SetAbbreviatedQuantity(abbreviatedQuantity)
    rewardData:SetCurrencyInfo(currencyType)
    rewardData:SetAnnouncementBackground(GetRewardAnnouncementBackgroundFileIndex(rewardId))

    return rewardData
end

function ZO_RewardsManager:GetItemEntryInfo(rewardId, quantity, parentChoice)
    local itemLink = GetItemRewardItemLink(rewardId, quantity)
    local displayName = GetItemLinkName(itemLink)
    local itemFunctionalQuality = GetItemLinkFunctionalQuality(itemLink)
    local itemDisplayQuality = GetItemLinkDisplayQuality(itemLink)
    local icon = GetItemLinkIcon(itemLink)
    local equipType = GetItemLinkEquipType(itemLink)
    local equipSlot = GetItemLinkComparisonEquipSlots(equipType)

    local rewardData = ZO_RewardData:New(rewardId, parentChoice)
    rewardData:SetItemLink(itemLink)
    rewardData:SetFormattedName(zo_strformat(SI_TOOLTIP_ITEM_NAME, displayName))
    rewardData:SetIcon(icon)
    rewardData:SetItemFunctionalQuality(itemFunctionalQuality)
    rewardData:SetItemDisplayQuality(itemDisplayQuality)
    rewardData:SetEquipSlot(equipSlot)
    rewardData:SetQuantity(quantity)
    rewardData:SetRawName(displayName)
    rewardData:SetFormattedNameWithStack(zo_strformat(SI_REWARDS_FORMAT_REWARD_WITH_AMOUNT, displayName, ZO_SELECTED_TEXT:Colorize(quantity)))
    rewardData:SetAnnouncementBackground(GetRewardAnnouncementBackgroundFileIndex(rewardId))

    return rewardData
end

function ZO_RewardsManager:GetCrownCrateEntryInfo(rewardId, quantity, parentChoice)
    local crateId = GetCrownCrateRewardCrateId(rewardId)
    local icon = GetCrownCrateIcon(crateId)

    local displayName = GetCrownCrateName(crateId)
    local formattedDisplayName = zo_strformat(SI_TOOLTIP_ITEM_NAME, displayName)
    local formattedNameWithStack = zo_strformat(SI_REWARDS_FORMAT_REWARD_WITH_AMOUNT, displayName, ZO_SELECTED_TEXT:Colorize(quantity))
    
    local rewardData = ZO_RewardData:New(rewardId, parentChoice)
    rewardData:SetRawName(displayName)
    rewardData:SetFormattedName(formattedDisplayName)
    rewardData:SetFormattedNameWithStack(formattedNameWithStack)
    rewardData:SetIcon(icon)
    rewardData:SetQuantity(quantity)
    rewardData:SetAnnouncementBackground(GetRewardAnnouncementBackgroundFileIndex(rewardId))

    return rewardData
end

function ZO_RewardsManager:GetInstantUnlockEntryInfo(rewardId, parentChoice)
    local instantUnlockId = GetInstantUnlockRewardInstantUnlockId(rewardId)
    local icon = GetInstantUnlockRewardIcon(instantUnlockId)
    local displayName = GetInstantUnlockRewardDisplayName(instantUnlockId)
    local formattedDisplayName = zo_strformat(SI_TOOLTIP_ITEM_NAME, displayName)
    
    local rewardData = ZO_RewardData:New(rewardId, parentChoice)
    rewardData:SetRawName(displayName)
    rewardData:SetFormattedName(formattedDisplayName)
    rewardData:SetIcon(icon)
    rewardData:SetAnnouncementBackground(GetRewardAnnouncementBackgroundFileIndex(rewardId))
    
    return rewardData
end

function ZO_RewardsManager:GetExperienceEntryInfo(rewardId, quantity, parentChoice)
    local displayName = GetString(SI_REWARDS_EXPERIENCE)
    local abbreviatedQuantity = ZO_AbbreviateAndLocalizeNumber(quantity, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES)
    local commaDelimitedQuantity = ZO_FastFormatDecimalNumber(ZO_CommaDelimitNumber(quantity))
    local formattedNameWithStack = zo_strformat(SI_REWARDS_FORMAT_REWARD_WITH_AMOUNT, displayName, ZO_SELECTED_TEXT:Colorize(commaDelimitedQuantity))

    local rewardData = ZO_RewardData:New(rewardId, parentChoice)
    rewardData:SetRawName(displayName)
    rewardData:SetFormattedName(displayName)
    rewardData:SetFormattedNameWithStack(formattedNameWithStack)
    rewardData:SetIcon("EsoUI/Art/Icons/Icon_Experience.dds")
    rewardData:SetQuantity(quantity)
    rewardData:SetAbbreviatedQuantity(abbreviatedQuantity)
    rewardData:SetAnnouncementBackground(GetRewardAnnouncementBackgroundFileIndex(rewardId))
    
    return rewardData
end

function ZO_RewardsManager:GetSkillLineExperienceEntryInfo(rewardId, quantity, parentChoice)
    local skillLineId = GetSkillLineExperienceRewardSkillLineId(rewardId)
    local icon = GetSkillLineDetailedIconById(skillLineId)
    local displayName = GetSkillLineNameById(skillLineId)
    local formattedDisplayName = zo_strformat(SI_REWARDS_FORMAT_SKILL_LINE_EXPERIENCE, displayName)
    local abbreviatedQuantity = ZO_AbbreviateAndLocalizeNumber(quantity, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES)
    local commaDelimitedQuantity = ZO_FastFormatDecimalNumber(ZO_CommaDelimitNumber(quantity))
    local formattedNameWithStack = zo_strformat(SI_REWARDS_FORMAT_SKILL_LINE_EXPERIENCE_WITH_AMOUNT, displayName, ZO_SELECTED_TEXT:Colorize(commaDelimitedQuantity))

    local rewardData = ZO_RewardData:New(rewardId, parentChoice)
    rewardData:SetSkillLineId(skillLineId)
    rewardData:SetRawName(displayName)
    rewardData:SetFormattedName(formattedDisplayName)
    rewardData:SetFormattedNameWithStack(formattedNameWithStack)
    rewardData:SetIcon(icon)
    rewardData:SetQuantity(quantity)
    rewardData:SetAbbreviatedQuantity(abbreviatedQuantity)
    rewardData:SetAnnouncementBackground(GetRewardAnnouncementBackgroundFileIndex(rewardId))

    return rewardData
end

function ZO_RewardsManager:GetTributeCardUpgradeEntryInfo(rewardId, parentChoice)
    local patronId, cardIndex = GetTributeCardUpgradeRewardTributeCardUpgradeInfo(rewardId)
    local patronData = TRIBUTE_DATA_MANAGER:GetTributePatronData(patronId)
    local baseCardId, upgradeCardId = patronData:GetDockCardInfoByIndex(cardIndex)
    local upgradeCardData = ZO_TributeCardData:New(patronId, upgradeCardId)
    local portraitIcon = upgradeCardData:GetPortraitIcon()

    local rewardData = ZO_RewardData:New(rewardId, parentChoice)
    rewardData:SetRawName(upgradeCardData:GetName())
    rewardData:SetFormattedName(upgradeCardData:GetFormattedName())
    rewardData:SetItemDisplayQuality(upgradeCardData:GetRarity())
    rewardData:SetIcon(portraitIcon)

    return rewardData
end

-- Helper function to make LFGActivityRewardUIData play nice with other rewards
function ZO_RewardsManager:GetAllRewardInfoForLFGActivityRewardUIData(lfgRewardUIDataId)
    local rewardListInfo = {}
    local numNodes = GetNumLFGActivityRewardUINodes(lfgRewardUIDataId)
    for nodeIndex = 1, numNodes do
        local rewardData = self:GetLFGActivityRewardUINodeInfo(lfgRewardUIDataId, nodeIndex)
        table.insert(rewardListInfo, rewardData)
    end
    return rewardListInfo
end

-- Helper function to make LFGActivityRewardUIData play nice with other rewards
function ZO_RewardsManager:GetLFGActivityRewardUINodeInfo(lfgRewardUIDataId, nodeIndex)
    local displayName, icon, r, g, b = GetLFGActivityRewardUINodeInfo(lfgRewardUIDataId, nodeIndex)
    local formattedDisplayName = zo_strformat(SI_ACTIVITY_FINDER_REWARD_NAME_FORMAT, displayName)

    local rewardData = ZO_RewardData:New(lfgRewardUIDataId)
    rewardData:SetRawName(displayName)
    rewardData:SetFormattedName(formattedDisplayName)
    rewardData:SetColor(ZO_ColorDef:New(r, g, b))
    rewardData:SetIcon(icon)
    rewardData:SetRewardType(ZO_REWARD_CUSTOM_ENTRY_TYPE.LFG_ACTIVITY)

    return rewardData
end

function ZO_RewardsManager:SortChoiceRewardEntries(data1, data2)
    return data1.choiceIndex < data2.choiceIndex
end

function ZO_RewardsManager:GetCollectibleEntryInfo(rewardId, parentChoice)
    assert(false) -- must be implemented on specific gui version of this manager
end

function ZO_RewardsManager:GetRewardContextualTypeString(rewardId, parentChoice)
    local entryType = GetRewardType(rewardId)
    -- COLLECTIBLE is implemented on specific gui version of this manager
    if entryType == REWARD_ENTRY_TYPE_ADD_CURRENCY then
        local currencyType = GetAddCurrencyRewardInfo(rewardId)
        local IS_PLURAL = false
        local IS_UPPER = false
        return GetCurrencyName(currencyType, IS_PLURAL, IS_UPPER)
    elseif entryType == REWARD_ENTRY_TYPE_ITEM then
        local QUANTITY = 1
        local itemLink = GetItemRewardItemLink(rewardId, QUANTITY)
        local itemType, specializedItemType = GetItemLinkItemType(itemLink)
        if itemType ~= ITEMTYPE_NONE then
            local equipType = GetItemLinkEquipType(itemLink)
            if equipType ~= EQUIP_TYPE_INVALID then
                return GetString("SI_EQUIPTYPE", equipType)
            else
                return ZO_GetSpecializedItemTypeText(itemType, specializedItemType)
            end
        end
    end

    return nil
end

------------------
-- XML Functions
------------------

function ZO_Rewards_Shared_OnMouseEnter(control, anchorPoint, anchorPointRelativeTo, anchorOffsetX, anchorOffsetY)
    local rewardData = control.GetRewardData and control.GetRewardData() or control.data
    if rewardData then
        local rewardType = rewardData:GetRewardType()
        if rewardType and rewardType ~= REWARD_ENTRY_TYPE_CHOICE then
            anchorPoint = anchorPoint or LEFT
            anchorPointRelativeTo = anchorPointRelativeTo or RIGHT
            anchorOffsetX = anchorOffsetX or 0
            anchorOffsetY = anchorOffsetY or 0
            local rewardId = rewardData:GetRewardId()
            local quantity = rewardData:GetQuantity()
            local displayFlags = rewardData:GetDisplayFlags()
            InitializeTooltip(ItemTooltip, control, anchorPoint, anchorOffsetX, anchorOffsetY, anchorPointRelativeTo)
            ItemTooltip:SetReward(rewardId, quantity, displayFlags)
            ItemTooltip:HideComparativeTooltips()
            if rewardType == REWARD_ENTRY_TYPE_ITEM then
                local USE_RELATIVE_ANCHORS = true
                ItemTooltip:ShowComparativeTooltips()
                if ZO_PlayShowAnimationOnComparisonTooltip then
                    -- These tooltip animations are not available for internal ingame.
                    ZO_PlayShowAnimationOnComparisonTooltip(ComparativeTooltip1)
                    ZO_PlayShowAnimationOnComparisonTooltip(ComparativeTooltip2)
                end
                ZO_Tooltips_SetupDynamicTooltipAnchors(ItemTooltip, control, ComparativeTooltip1, ComparativeTooltip2, USE_RELATIVE_ANCHORS)
            end
        end
    end
end

function ZO_Rewards_Shared_OnMouseExit(control)
    ClearTooltip(ItemTooltip)
    ItemTooltip:HideComparativeTooltips()
end