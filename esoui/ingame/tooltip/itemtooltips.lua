local FORCE_FULL_DURABILITY = true
local NOT_EQUIPPED = false
ZO_ENCHANT_DIFF_ADD = "add"
ZO_ENCHANT_DIFF_REMOVE = "remove"
ZO_ENCHANT_DIFF_NONE = "none"

ZO_ITEM_TOOLTIP_INVENTORY_TITLE_COUNT = "inventory"
ZO_ITEM_TOOLTIP_BANK_TITLE_COUNT = "bank"
ZO_ITEM_TOOLTIP_INVENTORY_AND_BANK_TITLE_COUNT = "inventoryAndBank"

ZO_ITEM_TOOLTIP_SHOW_INVENTORY_BODY_COUNT = true
ZO_ITEM_TOOLTIP_HIDE_INVENTORY_BODY_COUNT = false
ZO_ITEM_TOOLTIP_SHOW_BANK_BODY_COUNT = true
ZO_ITEM_TOOLTIP_HIDE_BANK_BODY_COUNT = false

--Section Generators

function ZO_Tooltip:AddItemTitle(itemLink, name)
    name = name or GetItemLinkName(itemLink)
    local quality = GetItemLinkQuality(itemLink)
    local qualityStyle = ZO_TooltipStyles_GetItemQualityStyle(quality)
    self:AddLine(zo_strformat(SI_TOOLTIP_ITEM_NAME, name), qualityStyle, self:GetStyle("title"))
end

function ZO_Tooltip:AddTypeSlotUniqueLine(itemLink, itemType, section, text1, text2)
    if(not text1) then
        return
    end
    
    local unique = IsItemLinkUnique(itemLink)
    local uniqueEquipped = IsItemLinkUniqueEquipped(itemLink)
    local formatSuffix
    if(unique) then
        formatSuffix = "_UNIQUE"
    elseif(uniqueEquipped) then
        formatSuffix = "_UNIQUE_EQUIPPED"
    else
        formatSuffix = ""
    end

    local lineText
    if(itemType == ITEMTYPE_ARMOR) then
        local armorType = GetItemLinkArmorType(itemLink)
        if(text2 and armorType ~= ARMORTYPE_NONE) then
            local format = _G["SI_ITEM_FORMAT_STR_TEXT1_ARMOR2"..formatSuffix]
            lineText = zo_strformat(format, text1, text2)
        else
            lineText = zo_strformat(SI_ITEM_FORMAT_STR_BROAD_TYPE, text1)
        end
    else
        if(text2) then
            local format = _G["SI_ITEM_FORMAT_STR_TEXT1_TEXT2"..formatSuffix]
            lineText = zo_strformat(format, text1, text2)
        else
            local format = _G["SI_ITEM_FORMAT_STR_TEXT1"..formatSuffix]
            lineText = zo_strformat(format, text1)
        end
    end

    if(lineText) then
        section:AddLine(lineText)
    end
end

function ZO_Tooltip:AddTopSection(itemLink)
    local topSection = self:AcquireSection(self:GetStyle("topSection"))

    --Item Type Info
    local itemType = GetItemLinkItemType(itemLink)
    local equipType = GetItemLinkEquipType(itemLink)
    if(itemType == ITEMTYPE_SIEGE) then
        local siegeType = GetItemLinkSiegeType(itemLink)
        if(siegeType ~= SIEGE_TYPE_NONE) then
            topSection:AddLine(GetString("SI_SIEGETYPE", siegeType))
        end
    elseif(itemType == ITEMTYPE_COSTUME) then
        self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, GetString("SI_ITEMTYPE", ITEMTYPE_COSTUME))
    elseif(itemType == ITEMTYPE_RECIPE) then
        if(IsItemLinkRecipeKnown(itemLink)) then            
            self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, GetString("SI_ITEMTYPE", ITEMTYPE_RECIPE), GetCraftingSkillName(CRAFTING_TYPE_PROVISIONING))
        else
            self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, GetString(SI_ITEM_FORMAT_STR_UNKNOWN_RECIPE), GetCraftingSkillName(CRAFTING_TYPE_PROVISIONING))
        end
    elseif(itemType ~= ITEMTYPE_NONE and equipType ~= EQUIP_TYPE_INVALID) then
        local weaponType = GetItemLinkWeaponType(itemLink)
        if(itemType == ITEMTYPE_ARMOR and weaponType == WEAPONTYPE_NONE) then
            local armorType = GetItemLinkArmorType(itemLink)
            self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, GetString("SI_EQUIPTYPE", equipType), GetString("SI_ARMORTYPE", armorType))
        elseif(weaponType ~= WEAPONTYPE_NONE) then
            self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, GetString("SI_WEAPONTYPE", weaponType), GetString("SI_EQUIPTYPE", equipType))
        end
    elseif(itemType == ITEMTYPE_LURE and IsItemLinkConsumable(itemLink)) then
        self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, GetString(SI_ITEM_SUB_TYPE_BAIT))
    elseif(GetItemLinkBookTitle(itemLink)) then
        self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, GetString(SI_ITEM_SUB_TYPE_BOOK))
    elseif(DoesItemLinkStartQuest(itemLink) or DoesItemLinkFinishQuest(itemLink)) then
        self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, GetString(SI_ITEM_FORMAT_STR_QUEST_ITEM))
    else
        local craftingSkillType = GetItemLinkCraftingSkillType(itemLink)
        if(craftingSkillType ~= CRAFTING_TYPE_INVALID) then
            local craftingSkillName = GetCraftingSkillName(craftingSkillType)
            local itemTypeText = GetString("SI_ITEMTYPE", itemType)
            self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, itemTypeText, craftingSkillName)
        elseif(itemType ~= ITEMTYPE_NONE) then
            local itemTypeText = GetString("SI_ITEMTYPE", itemType)
            self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, itemTypeText)
        end
    end

    self:AddTopLineToTopSection(topSection, itemLink)

    self:AddSectionEvenIfEmpty(topSection)
end

function ZO_Tooltip:AddTopLineToTopSection(topSection, itemLink)
    local topLine = topSection:AcquireSection(self:GetStyle("topLine"))

    -- Bound
    if(IsItemLinkBound(itemLink)) then
        topLine:AddLine(GetString(SI_ITEM_FORMAT_STR_BOUND))
    else
        local bindType = GetItemLinkBindType(itemLink)
        if(bindType ~= BIND_TYPE_NONE and bindType ~= BIND_TYPE_UNSET) then
            topLine:AddLine(GetString("SI_BINDTYPE", bindType))
        end
    end

    -- Stolen
    if(IsItemLinkStolen(itemLink)) then
        topLine:AddLine(zo_iconTextFormat("EsoUI/Art/Inventory/inventory_stolenItem_icon.dds", 24, 24, GetString(SI_GAMEPAD_ITEM_STOLEN_LABEL)), self:GetStyle("stolen"))
    end

    topSection:AddSectionEvenIfEmpty(topLine)
end

function ZO_Tooltip:AddBaseStats(itemLink, ignoreLevel)
    local statsSection = self:AcquireSection(self:GetStyle("baseStatsSection"))
    local hideItemLevel = ignoreLevel or ShouldHideTooltipRequiredLevel(itemLink)

    --Damage/Armor
    local weaponPower = GetItemLinkWeaponPower(itemLink)
    if(weaponPower > 0) then
        local statValuePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
        statValuePair:SetStat(GetString(SI_ITEM_FORMAT_STR_DAMAGE), self:GetStyle("statValuePairStat"))
        statValuePair:SetValue(weaponPower, self:GetStyle("statValuePairValue"))
        statsSection:AddStatValuePair(statValuePair)
    else
        local CONSIDER_CONDITION = true
        local armorRating = GetItemLinkArmorRating(itemLink, not CONSIDER_CONDITION)
        if(armorRating > 0) then
            local effectiveArmorRating = GetItemLinkArmorRating(itemLink, CONSIDER_CONDITION)
            local valueText
            local damagedStyle
            if(effectiveArmorRating == armorRating) then
                valueText = effectiveArmorRating
                damagedStyle = nil
            else
                valueText = zo_strformat(SI_ITEM_FORMAT_STR_EFFECTIVE_VALUE_OF_MAX, effectiveArmorRating, armorRating)
                damagedStyle = self:GetStyle("degradedStat")
            end

            local statValuePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            statValuePair:SetStat(GetString(SI_ITEM_FORMAT_STR_ARMOR), self:GetStyle("statValuePairStat"))
            statValuePair:SetValue(valueText, damagedStyle, self:GetStyle("statValuePairValue"))
            statsSection:AddStatValuePair(statValuePair)
        end
    end

    --Required Level/Vet Rank
    if(not hideItemLevel) then
        local requiredLevel = GetItemLinkRequiredLevel(itemLink)
        local requiredVeteranRank = GetItemLinkRequiredVeteranRank(itemLink)
        if(requiredLevel > 0 or requiredVeteranRank > 0) then
            local statValuePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            if(requiredVeteranRank > 0) then
                statValuePair:SetStat(GetString(SI_ITEM_FORMAT_STR_RANK), self:GetStyle("statValuePairStat"))
                local failedStyle = requiredVeteranRank > GetUnitVeteranRank("player") and self:GetStyle("failed")
                statValuePair:SetValue(requiredVeteranRank, failedStyle, self:GetStyle("statValuePairValue"))
            else
                statValuePair:SetStat(GetString(SI_ITEM_FORMAT_STR_LEVEL), self:GetStyle("statValuePairStat"))
                local failedStyle = requiredLevel > GetUnitLevel("player") and self:GetStyle("failed")
                statValuePair:SetValue(requiredLevel, failedStyle, self:GetStyle("statValuePairValue"))
            end
            statsSection:AddStatValuePair(statValuePair)
        end
    end

    --Value
    local CONSIDER_CONDITION = true
    local value = GetItemLinkValue(itemLink, not CONSIDER_CONDITION)
    if(value > 0) then
        local statValuePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
        statValuePair:SetStat(GetString(SI_ITEM_FORMAT_STR_VALUE), self:GetStyle("statValuePairStat"))
        local effectiveValue = GetItemLinkValue(itemLink, CONSIDER_CONDITION)
        if(effectiveValue == value) then
            statValuePair:SetValue(value, self:GetStyle("statValuePairValue"))
        else
            statValuePair:SetValue(zo_strformat(SI_ITEM_FORMAT_STR_EFFECTIVE_VALUE_OF_MAX, effectiveValue, value), self:GetStyle("statValuePairValue"))
        end
        statsSection:AddStatValuePair(statValuePair)
    end

    self:AddSection(statsSection)
end

local MIN_CONDITION_OR_CHARGE = 0
local MAX_CONDITION = 100
function ZO_Tooltip:AddConditionBar(itemLink, previewConditionToAdd)
    local condition = GetItemLinkCondition(itemLink)
    self:AddConditionOrChargeBar(itemLink, condition, MAX_CONDITION, previewConditionToAdd)
end

function ZO_Tooltip:AddEnchantChargeBar(itemLink, forceFullDurability, previewChargeToAdd)
    local maxCharges = GetItemLinkMaxEnchantCharges(itemLink)
    local charges = forceFullDurability and maxCharges or GetItemLinkNumEnchantCharges(itemLink)
    self:AddConditionOrChargeBar(itemLink, charges, maxCharges, previewChargeToAdd)
end

function ZO_Tooltip:AddConditionOrChargeBar(itemLink, value, maxValue, previewValueToAdd)
    local bar = nil

    if previewValueToAdd then
        bar = self:AcquireItemImprovementStatusBar(itemLink, value, maxValue, previewValueToAdd)
    else
        bar = self:AcquireStatusBar(self:GetStyle("conditionOrChargeBar"))
        bar:SetMinMax(MIN_CONDITION_OR_CHARGE, maxValue)
        bar:SetValue(value)
    end
    
    local barSection = self:AcquireSection(self:GetStyle("conditionOrChargeBarSection"))
    barSection:AddStatusBar(bar)
    self:AddSection(barSection)
end

function ZO_Tooltip:AcquireItemImprovementStatusBar(itemLink, value, maxValue, valueToAdd)
    local improvementBar = self:AcquireStatusBar(self:GetStyle("itemImprovementConditionOrChargeBar"))
    improvementBar:SetMinMax(MIN_CONDITION_OR_CHARGE, maxValue)

    local newValue = zo_clamp(value + valueToAdd, MIN_CONDITION_OR_CHARGE, maxValue)
    improvementBar:SetValueAndPreviewValue(value, newValue)

    return improvementBar
end

function ZO_Tooltip:AddEnchant(itemLink, enchantDiffMode)
    enchantDiffMode = enchantDiffMode or ZO_ENCHANT_DIFF_NONE
    local enchantSection = self:AcquireSection(self:GetStyle("bodySection"))
    local hasEnchant, enchantHeader, enchantDescription = GetItemLinkEnchantInfo(itemLink)
    if(hasEnchant) then
        enchantSection:AddLine(enchantHeader, self:GetStyle("bodyHeader"))
        
        if enchantDiffMode == ZO_ENCHANT_DIFF_NONE then
            enchantSection:AddLine(enchantDescription, self:GetStyle("bodyDescription"))
        end
    end
    self:AddSection(enchantSection)

    if hasEnchant and enchantDiffMode ~= ZO_ENCHANT_DIFF_NONE then
        local diffColorStyle, icon
        if enchantDiffMode == ZO_ENCHANT_DIFF_ADD then
            diffColorStyle = self:GetStyle("enchantDiffAdd")
            icon = "EsoUI/Art/Buttons/pointsPlus_up.dds"
        elseif enchantDiffMode == ZO_ENCHANT_DIFF_REMOVE then
            diffColorStyle = self:GetStyle("enchantDiffRemove")
            icon = "EsoUI/Art/Buttons/pointsMinus_up.dds"
        else
            -- If this assert is hit, support needs to be added for the additional
            --  enchant diff modes, which do not exist at the time of writing.
            assert(false)
        end

        local enchantmentDescriptionSection = self:AcquireSection(diffColorStyle, self:GetStyle("enchantDiff"))
        local diffSection = self:AcquireSection(self:GetStyle("enchantDiffTextureContainer"))
        diffSection:AddTexture(icon, self:GetStyle("enchantDiffTexture"))
        enchantmentDescriptionSection:AddSection(diffSection)
        enchantmentDescriptionSection:AddLine(enchantDescription, self:GetStyle("bodyDescription"))
        self:AddSection(enchantmentDescriptionSection)
    end
end

function ZO_Tooltip:AddItemAbilityScalingRange(section, minLevel, maxLevel, isVeteranRank)
    local text
    if isVeteranRank then
        text = zo_strformat(SI_ITEM_ABILITY_SCALING_VETERAN_RANK_RANGE, zo_iconFormat(GetGamepadVeteranRankIcon(), 48, 48), minLevel, maxLevel)
    else
        text = zo_strformat(SI_ITEM_ABILITY_SCALING_LEVEL_RANGE, minLevel, maxLevel)
    end
    section:AddLine(text, self:GetStyle("bodyDescription"))
end

function ZO_Tooltip:AddOnUseAbility(itemLink)
    local onUseAbilitySection = self:AcquireSection(self:GetStyle("bodySection"))
    local hasAbility, abilityHeader, abilityDescription, cooldown, hasScaling, minLevel, maxLevel, isVeteranRank = GetItemLinkOnUseAbilityInfo(itemLink)
    if(hasAbility) then
        if(abilityHeader ~= "") then
            onUseAbilitySection:AddLine(zo_strformat(SI_ABILITY_TOOLTIP_DESCRIPTION_HEADER, abilityHeader), self:GetStyle("bodyHeader"))
        end
        if(abilityDescription ~= "") then
            if(cooldown == 0) then
                onUseAbilitySection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_ON_USE, abilityDescription), self:GetStyle("bodyDescription"))
            else
                onUseAbilitySection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_ON_USE_COOLDOWN, abilityDescription, cooldown / 1000), self:GetStyle("bodyDescription"))
            end
            if hasScaling then
                self:AddItemAbilityScalingRange(onUseAbilitySection, minLevel, maxLevel, isVeteranRank)
            end
        end
    else
        local abilities = {}
        local maxCooldown = 0
        for i = 1, GetMaxTraits() do
            local hasTraitAbility, traitAbilityDescription, traitCooldown, traitHasScaling, traitMinLevel, traitMaxLevel, traitIsVeteranRank = GetItemLinkTraitOnUseAbilityInfo(itemLink, i)
            if(hasTraitAbility) then
                table.insert(abilities, traitAbilityDescription)
                if(traitCooldown > maxCooldown) then
                    maxCooldown = traitCooldown
                end
            end
        end

        for i = 1, #abilities do
            local text
            if(i == #abilities) then
                if(maxCooldown == 0) then
                    text = zo_strformat(SI_ITEM_FORMAT_STR_ON_USE, abilities[i])
                else
                    text = zo_strformat(SI_ITEM_FORMAT_STR_ON_USE_COOLDOWN, abilities[i], maxCooldown / 1000)
                end
            else
                text = zo_strformat(SI_ITEM_FORMAT_STR_ON_USE_MULTI_EFFECT, abilities[i])
            end
            onUseAbilitySection:AddLine(text, self:GetStyle("bodyDescription"))

            if traitHasScaling then
                self:AddItemAbilityScalingRange(onUseAbilitySection, traitMinLevel, traitMaxLevel, traitIsVeteranRank)
            end
        end
    end
    self:AddSection(onUseAbilitySection)
end

function ZO_Tooltip:AddTrait(itemLink)
    local traitType, traitDescription, traitSubtype, traitSubtypeName, traitSubtypeDescription = GetItemLinkTraitInfo(itemLink)
    if(traitType ~= ITEM_TRAIT_TYPE_NONE and traitType ~= ITEM_TRAIT_TYPE_SPECIAL_STAT and traitDescription ~= "") then
        local traitName = GetString("SI_ITEMTRAITTYPE", traitType)
        if(traitName ~= "") then
            local traitSection = self:AcquireSection(self:GetStyle("bodySection"))

            traitSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_ITEM_TRAIT_HEADER, traitName), self:GetStyle("bodyHeader"))
            traitSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_ITEM_TRAIT_DESCRIPTION, traitDescription), self:GetStyle("bodyDescription"))
            self:AddSection(traitSection)
        end
    end
    if(traitSubtype ~= 0 and traitSubtypeName ~= "") then
        local traitSubtypeSection = self:AcquireSection(self:GetStyle("bodySection"))

        traitSubtypeSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_ITEM_TRAIT_HEADER, traitSubtypeName), self:GetStyle("bodyHeader"))
        traitSubtypeSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_ITEM_TRAIT_DESCRIPTION, traitSubtypeDescription), self:GetStyle("bodyDescription"))
        self:AddSection(traitSubtypeSection)
    end
end

function ZO_Tooltip:AddSet(itemLink, equipped)
    local hasSet, setName, numBonuses, numEquipped, maxEquipped = GetItemLinkSetInfo(itemLink)
    if(hasSet) then
        local setSection = self:AcquireSection(self:GetStyle("bodySection"))
        setSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_SET_NAME, setName, numEquipped, maxEquipped), self:GetStyle("bodyHeader"))
        for i = 1, numBonuses do
            local numRequired, bonusDescription = GetItemLinkSetBonusInfo(itemLink, equipped, i)
            if(numEquipped >= numRequired) then
                setSection:AddLine(bonusDescription, self:GetStyle("activeBonus"), self:GetStyle("bodyDescription"))
            else
                setSection:AddLine(bonusDescription, self:GetStyle("inactiveBonus"), self:GetStyle("bodyDescription"))
            end
        end
        self:AddSection(setSection)
    end
end

function ZO_Tooltip:AddFlavorText(itemLink)
    local flavorText = GetItemLinkFlavorText(itemLink)
    if(flavorText ~= "") then
        local flavorSection = self:AcquireSection(self:GetStyle("bodySection"))
        flavorSection:AddLine(flavorText, self:GetStyle("flavorText"))
        self:AddSection(flavorSection)
    end
end

function ZO_Tooltip:AddCreator(itemLink, creatorName)
    if creatorName then
        local creatorSection = self:AcquireSection(self:GetStyle("bodySection"))
        if(creatorName ~= "") then
            local itemType = GetItemLinkItemType(itemLink)
            if(itemType == ITEMTYPE_TABARD) then
                creatorSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_TABARD, creatorName), self:GetStyle("bodyDescription"))
            else
                creatorSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_CREATOR, creatorName), self:GetStyle("bodyDescription"))
            end
        else
            if(IsItemLinkCrafted(itemLink)) then
                creatorSection:AddLine(GetString(SI_ITEM_FORMAT_STR_CRAFTED), self:GetStyle("bodyDescription"))
            end
        end
        self:AddSection(creatorSection)
    end
end

function ZO_Tooltip:AddMaterialLevels(itemLink)
    local levelsDescription = GetItemLinkMaterialLevelDescription(itemLink)
    if(levelsDescription ~= "") then
        local levelsSection = self:AcquireSection(self:GetStyle("bodySection"))
        levelsSection:AddLine(levelsDescription, self:GetStyle("bodyDescription"))
        self:AddSection(levelsSection)
    end
end

function ZO_Tooltip:AddItemBagCounts(itemLink, showInventoryCount, showBankCount)
    if IsItemLinkStackable(itemLink) and (showInventoryCount or showBankCount) then
        local bagCountSection = self:AcquireSection(self:GetStyle("bagCountSection"))
        local bagCount, bankCount = GetItemLinkStacks(itemLink)
        
        if showInventoryCount and bagCount > 0 then
            local formattedCount = ZO_SELECTED_TEXT:Colorize(ZO_CommaDelimitNumber(bagCount))
            bagCountSection:AddLine(zo_strformat(SI_TOOLTIP_ITEM_INVENTORY_COUNT, formattedCount))
        end

        if showBankCount and bankCount > 0 then
            local formattedCount = ZO_SELECTED_TEXT:Colorize(ZO_CommaDelimitNumber(bankCount))
            bagCountSection:AddLine(zo_strformat(SI_TOOLTIP_ITEM_BANK_COUNT, formattedCount))
        end

        self:AddSection(bagCountSection)
    end
end

--Layout Functions

function ZO_Tooltip:LayoutGenericItem(itemLink, equipped, creatorName, forceFullDurability, enchantMode, previewValueToAdd, itemName, showInventoryCount, showBankCount)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)
    self:AddBaseStats(itemLink)
    if(DoesItemLinkHaveArmorDecay(itemLink)) then
        self:AddConditionBar(itemLink, previewValueToAdd)
    elseif(DoesItemLinkHaveEnchantCharges(itemLink)) then
        self:AddEnchantChargeBar(itemLink, forceFullDurability, previewValueToAdd)
    end

    self:AddEnchant(itemLink, enchantMode)
    self:AddOnUseAbility(itemLink)
    self:AddTrait(itemLink)
    self:AddSet(itemLink, equipped)
    self:AddFlavorText(itemLink)
    self:AddCreator(itemLink, creatorName)
    self:AddItemBagCounts(itemLink, showInventoryCount, showBankCount)
end

function ZO_Tooltip:LayoutVendorTrash(itemLink, itemName, showInventoryCount, showBankCount)
    self:AddItemTitle(itemLink, itemName)
    self:AddBaseStats(itemLink)
    self:AddFlavorText(itemLink)
    self:AddItemBagCounts(itemLink, showInventoryCount, showBankCount)
end

function ZO_Tooltip:LayoutBooster(itemLink, itemName, showInventoryCount, showBankCount)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)

    local boosterDescriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
    local toQuality = GetItemLinkQuality(itemLink)
    local fromQuality = zo_max(ITEM_QUALITY_TRASH, toQuality - 1)
    local toQualityText = GetString("SI_ITEMQUALITY", toQuality)
    local fromQualityText = GetString("SI_ITEMQUALITY", fromQuality)
    toQualityText = GetItemQualityColor(toQuality):Colorize(toQualityText)
    fromQualityText = GetItemQualityColor(fromQuality):Colorize(fromQualityText)
    boosterDescriptionSection:AddLine(zo_strformat(SI_ENCHANTMENT_BOOSTER_DESCRIPTION, fromQualityText, toQualityText), self:GetStyle("bodyDescription"))
    self:AddSection(boosterDescriptionSection)
    self:AddItemBagCounts(itemLink, showInventoryCount, showBankCount)
end

do
    local FORMATTED_VETERAN_RANK_ICON = zo_iconFormat(GetGamepadVeteranRankIcon(), 48, 48)
    function ZO_Tooltip:LayoutInlineGlyph(itemLink, itemName, showInventoryCount, showBankCount)
        self:AddItemTitle(itemLink, itemName)
        self:AddEnchant(itemLink)

        local minLevel, maxLevel, minVeteranRank, maxVeteranRank = GetItemLinkGlyphMinMaxLevels(itemLink)
        if(minLevel or minVeteranRank) then
            local requirementsSection = self:AcquireSection(self:GetStyle("bodySection"))
            if minVeteranRank then
                if minVeteranRank ~= maxVeteranRank then
                    requirementsSection:AddLine(zo_strformat(SI_ENCHANTING_GLYPH_REQUIRED_VETERAN_RANK_GAMEPAD, FORMATTED_VETERAN_RANK_ICON, minVeteranRank, maxVeteranRank), self:GetStyle("bodyDescription"))
                else
                    requirementsSection:AddLine(zo_strformat(SI_ENCHANTING_GLYPH_REQUIRED_SINGLE_VETERAN_RANK_GAMEPAD, FORMATTED_VETERAN_RANK_ICON, minVeteranRank), self:GetStyle("bodyDescription"))
                end
            else
                if minLevel ~= maxLevel then
                    requirementsSection:AddLine(zo_strformat(SI_ENCHANTING_GLYPH_REQUIRED_LEVEL, minLevel, maxLevel), self:GetStyle("bodyDescription"))
                else
                    requirementsSection:AddLine(zo_strformat(SI_ENCHANTING_GLYPH_REQUIRED_SINGLE_LEVEL, minLevel), self:GetStyle("bodyDescription"))
                end
            end
            self:AddSection(requirementsSection)
        end

        self:AddFlavorText(itemLink)
        self:AddItemBagCounts(itemLink, showInventoryCount, showBankCount)
    end
end

function ZO_Tooltip:LayoutGlyph(itemLink, creatorName, itemName, showInventoryCount, showBankCount)
    self:AddTopSection(itemLink)
    self:LayoutInlineGlyph(itemLink, itemName)
    self:AddCreator(itemLink, creatorName)
    self:AddItemBagCounts(itemLink, showInventoryCount, showBankCount)
end

function ZO_Tooltip:LayoutSiege(itemLink, itemName, showInventoryCount, showBankCount)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)
    local maxHP = GetItemLinkSiegeMaxHP(itemLink)
    if(maxHP > 0) then
        local statsSection = self:AcquireSection(self:GetStyle("statsSection"))
        local statValuePair = statsSection:AcquireStatValuePair()
        statValuePair:SetStat(GetString(SI_SIEGE_TOOLTIP_TOUGHNESS), self:GetStyle("statValuePairStat"))
        statValuePair:SetValue(zo_strformat(SI_SIEGE_TOOLTIP_TOUGHNESS_FORMAT, maxHP), self:GetStyle("statValuePairValue"))
        statsSection:AddStatValuePair(statValuePair)
        self:AddSection(statsSection)
    end
    self:AddFlavorText(itemLink)
    self:AddItemBagCounts(itemLink, showInventoryCount, showBankCount)
end

function ZO_Tooltip:LayoutTool(itemLink, itemName, showInventoryCount, showBankCount)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)
    self:AddBaseStats(itemLink)
    self:AddFlavorText(itemLink)
    self:AddItemBagCounts(itemLink, showInventoryCount, showBankCount)
end

function ZO_Tooltip:LayoutSoulGem(itemLink, itemName, showInventoryCount, showBankCount)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)
    self:AddBaseStats(itemLink)
    self:AddFlavorText(itemLink)
    self:AddItemBagCounts(itemLink, showInventoryCount, showBankCount)
end

function ZO_Tooltip:LayoutAvARepair(itemLink, itemName, showInventoryCount, showBankCount)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)
    self:AddFlavorText(itemLink)
    self:AddItemBagCounts(itemLink, showInventoryCount, showBankCount)
end

function ZO_Tooltip:LayoutBook(itemLink)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink)
    local knownSection = self:AcquireSection(self:GetStyle("bodySection"))
    if(IsItemLinkBookKnown(itemLink)) then
        knownSection:AddLine(GetString(SI_LORE_LIBRARY_IN_LIBRARY), self:GetStyle("bodyDescription"))
    else
        knownSection:AddLine(GetString(SI_LORE_LIBRARY_USE_TO_LEARN), self:GetStyle("bodyDescription"))
    end
    self:AddSection(knownSection)
    self:AddFlavorText(itemLink)
end

function ZO_Tooltip:LayoutLure(itemLink, itemName, showInventoryCount, showBankCount)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)
    self:AddFlavorText(itemLink)
    self:AddItemBagCounts(itemLink, showInventoryCount, showBankCount)
end

function ZO_Tooltip:LayoutQuestStartOrFinishItem(itemLink, itemName, showInventoryCount, showBankCount)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink)
    self:AddFlavorText(itemLink)
    self:AddItemBagCounts(itemLink, showInventoryCount, showBankCount)
end

function ZO_Tooltip:LayoutProvisionerRecipe(itemLink, itemName, showInventoryCount, showBankCount)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)
    local IGNORE_LEVEL = true
    self:AddBaseStats(itemLink, IGNORE_LEVEL)

    local resultItemLink = GetItemLinkRecipeResultItemLink(itemLink)
    if(resultItemLink ~= "") then
        self:AddOnUseAbility(resultItemLink)
    end

    --Ingredients
    local numIngredients = GetItemLinkRecipeNumIngredients(itemLink)
    if(numIngredients > 0) then
        local ingredientsSection = self:AcquireSection(self:GetStyle("bodySection"))
        ingredientsSection:AddLine(GetString(SI_PROVISIONER_INGREDIENTS_HEADER), self:GetStyle("bodyHeader"))
        for i = 1, numIngredients do
            local ingredientName, numOwned = GetItemLinkRecipeIngredientInfo(itemLink, i)
            local hasIngredientStyle
            if(numOwned > 0) then
                hasIngredientStyle = self:GetStyle("hasIngredient")
            else
                hasIngredientStyle = self:GetStyle("doesntHaveIngredient")
            end
            ingredientsSection:AddLine(zo_strformat(SI_NUMBERED_LIST_ENTRY, i, ingredientName), hasIngredientStyle, self:GetStyle("bodyDescription"))
        end
        self:AddSection(ingredientsSection)
    end

    --Requirements
    local requirementsSection = self:AcquireSection(self:GetStyle("bodySection"))
    requirementsSection:AddLine(GetString(SI_PROVISIONER_REQUIREMENTS_HEADER), self:GetStyle("bodyHeader"))

    local requiredRank = GetItemLinkRecipeRankRequirement(itemLink)
    local rank = GetNonCombatBonus(NON_COMBAT_BONUS_PROVISIONING_LEVEL)
    local rankSuccessStyle
    if(rank >= requiredRank) then
        rankSuccessStyle = self:GetStyle("succeeded")
    else
        rankSuccessStyle = self:GetStyle("failed")
    end
    requirementsSection:AddLine(zo_strformat(SI_PROVISIONER_REQUIRES_RECIPE_IMPROVEMENT, requiredRank),  rankSuccessStyle, self:GetStyle("bodyDescription"))
    
    local requiredQuality = GetItemLinkRecipeQualityRequirement(itemLink)
    local quality = GetNonCombatBonus(NON_COMBAT_BONUS_PROVISIONING_RARITY_LEVEL)
    local qualitySuccessStyle
    if(quality >= requiredQuality) then
        qualitySuccessStyle = self:GetStyle("succeeded")
    else
        qualitySuccessStyle = self:GetStyle("failed")
    end
    requirementsSection:AddLine(zo_strformat(SI_PROVISIONER_REQUIRES_RECIPE_QUALITY, requiredQuality),  qualitySuccessStyle, self:GetStyle("bodyDescription"))

    self:AddSection(requirementsSection)

    --Use to learn
    local useToLearnOrKnownSection = self:AcquireSection(self:GetStyle("bodySection"))
    if(IsItemLinkRecipeKnown(itemLink)) then
        useToLearnOrKnownSection:AddLine(GetString(SI_RECIPE_ALREADY_KNOWN), self:GetStyle("bodyDescription"))
    else
        useToLearnOrKnownSection:AddLine(GetString(SI_PROVISIONER_USE_TO_LEARN_RECIPE), self:GetStyle("bodyDescription"))
    end
    self:AddSection(useToLearnOrKnownSection)
    self:AddItemBagCounts(itemLink, showInventoryCount, showBankCount)
end

function ZO_Tooltip:LayoutReagent(itemLink, itemName, showInventoryCount, showBankCount)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)

    local traitSection
    for i = 1, GetMaxTraits() do
        local known, name = GetItemLinkReagentTraitInfo(itemLink, i)
        if(known ~= nil) then
            if(not traitSection) then
                traitSection = self:AcquireSection(self:GetStyle("bodySection"))
                traitSection:AddLine(GetString(SI_CRAFTING_COMPONENT_TOOLTIP_TRAITS), self:GetStyle("bodyHeader"))
            end
            local displayName
            local knownStyle
            if(known) then
                displayName = name
                knownStyle = self:GetStyle("traitKnown")
            else
                displayName = GetString(SI_CRAFTING_COMPONENT_TOOLTIP_UNKNOWN_TRAIT)
                knownStyle = self:GetStyle("traitUnknown")
            end

            traitSection:AddLine(zo_strformat(SI_NUMBERED_LIST_ENTRY, i, displayName), knownStyle, self:GetStyle("bodyDescription")) 
        end
    end

    if(traitSection) then
        self:AddSection(traitSection)
    end
    self:AddItemBagCounts(itemLink, showInventoryCount, showBankCount)
end

function ZO_Tooltip:LayoutEnchantingRune(itemLink, itemName, showInventoryCount, showBankCount)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)

    local known, name = GetItemLinkEnchantingRuneName(itemLink)
    if(known ~= nil) then
        local translationSection = self:AcquireSection(self:GetStyle("bodySection"))
        translationSection:AddLine(GetString(SI_ENCHANTING_TRANSLATION_HEADER), self:GetStyle("bodyHeader"))
        if(known) then
            translationSection:AddLine(zo_strformat(SI_ENCHANTING_TRANSLATION_KNOWN, name), self:GetStyle("bodyDescription"))
        else
            translationSection:AddLine(GetString(SI_ENCHANTING_TRANSLATION_UNKNOWN), self:GetStyle("bodyDescription"))
        end
        self:AddSection(translationSection)
    end

    local runeClassification = GetItemLinkEnchantingRuneClassification(itemLink)
    local requiredRank = GetItemLinkRequiredCraftingSkillRank(itemLink)
    if(runeClassification == ENCHANTING_RUNE_POTENCY) then
        local requiredRankStyle
        if(GetNonCombatBonus(NON_COMBAT_BONUS_ENCHANTING_LEVEL) >= requiredRank) then
            requiredRankStyle = self:GetStyle("succeeded")
        else
            requiredRankStyle = self:GetStyle("failed")
        end
        local requirementSection = self:AcquireSection(self:GetStyle("bodySection"))
        requirementSection:AddLine(zo_strformat(SI_ENCHANTING_REQUIRES_POTENCY_IMPROVEMENT, requiredRank), requiredRankStyle, self:GetStyle("bodyDescription"))
        self:AddSection(requirementSection)
    elseif(runeClassification == ENCHANTING_RUNE_ASPECT) then
        local requiredRankStyle
        if(GetNonCombatBonus(NON_COMBAT_BONUS_ENCHANTING_RARITY_LEVEL) >= requiredRank) then
            requiredRankStyle = self:GetStyle("succeeded")
        else
            requiredRankStyle = self:GetStyle("failed")
        end
        local requirementSection = self:AcquireSection(self:GetStyle("bodySection"))
        requirementSection:AddLine(zo_strformat(SI_ENCHANTING_REQUIRES_ASPECT_IMPROVEMENT, requiredRank), requiredRankStyle, self:GetStyle("bodyDescription"))
        self:AddSection(requirementSection)
    end
    self:AddItemBagCounts(itemLink, showInventoryCount, showBankCount)
end

function ZO_Tooltip:LayoutAlchemyBase(itemLink, itemName, showInventoryCount, showBankCount)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)

    local requiredLevel = GetItemLinkRequiredLevel(itemLink)
    local requiredVeteranRank = GetItemLinkRequiredVeteranRank(itemLink)
    if(requiredLevel > 0 or requiredVeteranRank > 0) then
        local createsSection = self:AcquireSection(self:GetStyle("bodySection"))
        if(requiredVeteranRank > 0) then
            createsSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_CREATES_POTION_OF_VETERAN_RANK, requiredVeteranRank), self:GetStyle("bodyDescription"))
        else
            createsSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_CREATES_POTION_OF_LEVEL, requiredLevel), self:GetStyle("bodyDescription"))
        end
        self:AddSection(createsSection)
    end

    local requirementSection = self:AcquireSection(self:GetStyle("bodySection"))
    local requirementStyle
    local requiredRank = GetItemLinkRequiredCraftingSkillRank(itemLink)
    if(GetNonCombatBonus(NON_COMBAT_BONUS_ALCHEMY_LEVEL) >= requiredRank) then
        requirementStyle = self:GetStyle("succeeded")
    else
        requirementStyle = self:GetStyle("failed")
    end
    requirementSection:AddLine(zo_strformat(SI_REQUIRES_ALCHEMY_SOLVENT_PURIFICATION, requiredRank), requirementStyle, self:GetStyle("bodyDescription"))
    self:AddSection(requirementSection)
    self:AddItemBagCounts(itemLink, showInventoryCount, showBankCount)
end

function ZO_Tooltip:LayoutIngredient(itemLink, itemName, showInventoryCount, showBankCount)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)
    self:AddFlavorText(itemLink)
    self:AddItemBagCounts(itemLink, showInventoryCount, showBankCount)
end

function ZO_Tooltip:LayoutStyleMaterial(itemLink, itemName, showInventoryCount, showBankCount)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)

    local styleSection = self:AcquireSection(self:GetStyle("bodySection"))
    local style = GetItemLinkItemStyle(itemLink)
    styleSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_STYLE_MATERIAL, GetString("SI_ITEMSTYLE", style)), self:GetStyle("bodyDescription"))
    self:AddSection(styleSection)
    self:AddItemBagCounts(itemLink, showInventoryCount, showBankCount)
end

function ZO_Tooltip:LayoutRawMaterial(itemLink, itemName, showInventoryCount, showBankCount)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)

    local refinedItemLink = GetItemLinkRefinedMaterialItemLink(itemLink)
    if(refinedItemLink ~= "") then
        local refinedSection = self:AcquireSection(self:GetStyle("bodySection"))
        local refinedItemName = GetItemLinkName(refinedItemLink)
        local quality = GetItemLinkQuality(refinedItemLink)
        local qualityColor = GetItemQualityColor(quality)

        local minRawMats = GetSmithingRefinementMinRawMaterial()
        local maxRawMats = GetSmithingRefinementMaxRawMaterial()

        refinedSection:AddLine(zo_strformat(SI_TOOLTIP_ITEM_FORMAT_REFINES_TO, minRawMats, maxRawMats, qualityColor:Colorize(refinedItemName)), self:GetStyle("bodyDescription"))
        self:AddSection(refinedSection)

        self:AddMaterialLevels(refinedItemLink)
    end
    self:AddItemBagCounts(itemLink, showInventoryCount, showBankCount)
end

function ZO_Tooltip:LayoutMaterial(itemLink, itemName, showInventoryCount, showBankCount)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)
    self:AddMaterialLevels(itemLink)
    self:AddItemBagCounts(itemLink, showInventoryCount, showBankCount)
end

function ZO_Tooltip:LayoutArmorTrait(itemLink, itemName, showInventoryCount, showBankCount)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)

    local traitDescriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
    traitDescriptionSection:AddLine(GetString(SI_ITEM_FORMAT_STR_ARMOR_TRAIT), self:GetStyle("bodyDescription"))
    self:AddSection(traitDescriptionSection)

    self:AddTrait(itemLink)
    self:AddItemBagCounts(itemLink, showInventoryCount, showBankCount)
end

function ZO_Tooltip:LayoutWeaponTrait(itemLink, itemName, showInventoryCount, showBankCount)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)

    local traitDescriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
    traitDescriptionSection:AddLine(GetString(SI_ITEM_FORMAT_STR_WEAPON_TRAIT), self:GetStyle("bodyDescription"))
    self:AddSection(traitDescriptionSection)

    self:AddTrait(itemLink)
    self:AddItemBagCounts(itemLink, showInventoryCount, showBankCount)
end

function ZO_Tooltip:LayoutAlchemyPreview(solventBagId, solventSlotIndex, reagent1BagId, reagent1SlotIndex, reagent2BagId, reagent2SlotIndex, reagent3BagId, reagent3SlotIndex)
    local _, icon = GetAlchemyResultingItemInfo(solventBagId, solventSlotIndex, reagent1BagId, reagent1SlotIndex, reagent2BagId, reagent2SlotIndex, reagent3BagId, reagent3SlotIndex)
    local itemLink = GetAlchemyResultingItemLink(solventBagId, solventSlotIndex, reagent1BagId, reagent1SlotIndex, reagent2BagId, reagent2SlotIndex, reagent3BagId, reagent3SlotIndex)

    if itemLink and itemLink ~= "" then
        if self.icon then
            self.icon:SetTexture(icon)
            self.icon:SetHidden(false)
        end

        self:AddItemTitle(itemLink)
        self:AddBaseStats(itemLink)
        self:AddOnUseAbility(itemLink)

    else
        if self.icon then
            self.icon:SetHidden(true)
        end
        
        self:AddLine(GetString(SI_ALCHEMY_UNKNOWN_RESULT), self:GetStyle("title"))
        local alchemySection = self:AcquireSection(self:GetStyle("bodySection"))
        alchemySection:AddLine(GetString(SI_ALCHEMY_UNKNOWN_EFFECTS), self:GetStyle("bodyDescription"))
        self:AddSection(alchemySection)
    end
end

function ZO_Tooltip:LayoutEnchantingCraftingItem(itemLink, icon, creator)
    if itemLink and itemLink ~= "" then
        if self.icon then
            self.icon:SetTexture(icon)
            self.icon:SetHidden(false)
        end

        self:LayoutGlyph(itemLink, creator)

    else
        if self.icon then
            self.icon:SetHidden(true)
        end
        
        self:AddLine(GetString(SI_ENCHANTING_UNKNOWN_RESULT), self:GetStyle("title"))
        local enchantingSection = self:AcquireSection(self:GetStyle("bodySection"))
        enchantingSection:AddLine(GetString(SI_ENCHANTING_UNKNOWN_RESULT), self:GetStyle("bodyDescription"))
        self:AddSection(enchantingSection)
    end
end

function ZO_Tooltip:LayoutEnchantingPreview(potencyRuneBagId, potencyRuneSlotIndex, essenceRuneBagId, essenceRuneSlotIndex, aspectRuneBagId, aspectRuneSlotIndex)
    local _, icon, _, _, _, _ = GetEnchantingResultingItemInfo(potencyRuneBagId, potencyRuneSlotIndex, essenceRuneBagId, essenceRuneSlotIndex, aspectRuneBagId, aspectRuneSlotIndex)
    local itemLink = GetEnchantingResultingItemLink(potencyRuneBagId, potencyRuneSlotIndex, essenceRuneBagId, essenceRuneSlotIndex, aspectRuneBagId, aspectRuneSlotIndex)

    self:LayoutEnchantingCraftingItem(itemLink, icon, nil)
end

function ZO_Tooltip:LayoutStoreItemFromLink(itemLink, icon)
    if itemLink and itemLink ~= "" then
        if self.icon then
            self.icon:SetTexture(icon)
            self.icon:SetHidden(false)
        end

        local stackCount = 1 -- currently stores only sell single items not stacks
        self:LayoutItemWithStackCountSimple(itemLink, stackCount, ZO_ITEM_TOOLTIP_SHOW_INVENTORY_BODY_COUNT, ZO_ITEM_TOOLTIP_SHOW_BANK_BODY_COUNT)
    end
end

function ZO_Tooltip:LayoutStoreWindowItem(itemData)
    if itemData.entryType == STORE_ENTRY_TYPE_COLLECTIBLE then
        self:LayoutCollectibleFromLink(itemData.itemLink)
    else
        self:LayoutStoreItemFromLink(itemData.itemLink, itemData.icon)
    end
end

function ZO_Tooltip:LayoutBuyBackItem(itemIndex, icon)
    local itemLink = GetBuybackItemLink(itemIndex)
    self:LayoutStoreItemFromLink(itemLink, icon)
end

function ZO_Tooltip:LayoutQuestRewardItem(rewardIndex, icon)
    local itemLink = GetQuestRewardItemLink(rewardIndex)
    if itemLink and itemLink ~= "" then
        if self.icon then
            self.icon:SetTexture(icon)
            self.icon:SetHidden(false)
        end

        self:LayoutItem(itemLink, NOT_EQUIPPED, nil, FORCE_FULL_DURABILITY)
    end
end

function ZO_Tooltip:SetProvisionerResultItem(recipeListIndex, recipeIndex)
    local _, icon = GetRecipeResultItemInfo(recipeListIndex, recipeIndex)
    local itemLink = GetRecipeResultItemLink(recipeListIndex, recipeIndex)

    if itemLink and itemLink ~= "" then
        if self.icon then
            self.icon:SetTexture(icon)
            self.icon:SetHidden(false)
        end

        self:LayoutItem(itemLink, NOT_EQUIPPED, nil)
    end
end

do
    local LAYOUT_FUNCTIONS =
    {
        [ITEMTYPE_RECIPE] = function(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount) self:LayoutProvisionerRecipe(itemLink, itemName, showInventoryCount, showBankCount) end,

        [ITEMTYPE_BLACKSMITHING_BOOSTER] = function(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount) self:LayoutBooster(itemLink, itemName, showInventoryCount, showBankCount) end,
        [ITEMTYPE_WOODWORKING_BOOSTER] = function(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount) self:LayoutBooster(itemLink, itemName, showInventoryCount, showBankCount) end,
        [ITEMTYPE_CLOTHIER_BOOSTER] = function(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount) self:LayoutBooster(itemLink, itemName, showInventoryCount, showBankCount) end,

        [ITEMTYPE_GLYPH_WEAPON] = function(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount) self:LayoutGlyph(itemLink, creatorName, itemName, showInventoryCount, showBankCount) end,
        [ITEMTYPE_GLYPH_ARMOR] = function(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount) self:LayoutGlyph(itemLink, creatorName, itemName, showInventoryCount, showBankCount) end,
        [ITEMTYPE_GLYPH_JEWELRY] = function(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount) self:LayoutGlyph(itemLink, creatorName, itemName, showInventoryCount, showBankCount) end,

        [ITEMTYPE_REAGENT] = function(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount) self:LayoutReagent(itemLink, itemName, showInventoryCount, showBankCount) end,

        [ITEMTYPE_ALCHEMY_BASE] = function(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount) self:LayoutAlchemyBase(itemLink, itemName, showInventoryCount, showBankCount) end,

        [ITEMTYPE_INGREDIENT] = function(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount) self:LayoutIngredient(itemLink, itemName, showInventoryCount, showBankCount) end,

        [ITEMTYPE_STYLE_MATERIAL] = function(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount) self:LayoutStyleMaterial(itemLink, itemName, showInventoryCount, showBankCount) end,

        [ITEMTYPE_BLACKSMITHING_RAW_MATERIAL] = function(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount) self:LayoutRawMaterial(itemLink, itemName, showInventoryCount, showBankCount) end,
        [ITEMTYPE_CLOTHIER_RAW_MATERIAL] = function(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount) self:LayoutRawMaterial(itemLink, itemName, showInventoryCount, showBankCount) end,
        [ITEMTYPE_WOODWORKING_RAW_MATERIAL] = function(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount) self:LayoutRawMaterial(itemLink, itemName, showInventoryCount, showBankCount) end,

        [ITEMTYPE_BLACKSMITHING_MATERIAL] = function(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount) self:LayoutMaterial(itemLink, itemName, showInventoryCount, showBankCount) end,
        [ITEMTYPE_CLOTHIER_MATERIAL] = function(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount) self:LayoutMaterial(itemLink, itemName, showInventoryCount, showBankCount) end,
        [ITEMTYPE_WOODWORKING_MATERIAL] = function(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount) self:LayoutMaterial(itemLink, itemName, showInventoryCount, showBankCount) end,

        [ITEMTYPE_ARMOR_TRAIT] = function(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount) self:LayoutArmorTrait(itemLink, itemName, showInventoryCount, showBankCount) end,

        [ITEMTYPE_WEAPON_TRAIT] = function(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount) self:LayoutWeaponTrait(itemLink, itemName, showInventoryCount, showBankCount) end,

        [ITEMTYPE_SIEGE] = function(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount) self:LayoutSiege(itemLink, itemName, showInventoryCount, showBankCount) end,

        [ITEMTYPE_TOOL] = function(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount) self:LayoutTool(itemLink, itemName, showInventoryCount, showBankCount) end,

        [ITEMTYPE_SOUL_GEM] = function(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount) self:LayoutSoulGem(itemLink, itemName, showInventoryCount, showBankCount) end,

        [ITEMTYPE_AVA_REPAIR] = function(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount) self:LayoutAvARepair(itemLink, itemName, showInventoryCount, showBankCount) end,
    }

    --TODO: Get creatorName from itemLink?
    --TODO: Pass in some sort of struct for containing all the additional item tooltip parameters
    function ZO_Tooltip:LayoutItem(itemLink, equipped, creatorName, forceFullDurability, enchantMode, previewValueToAdd, itemName, showInventoryCount, showBankCount)
        local isValidItemLink = itemLink ~= ""
        if isValidItemLink then
            --first do checks that can't be determined from the item type
            if(IsItemLinkVendorTrash(itemLink)) then
                self:LayoutVendorTrash(itemLink, itemName, showInventoryCount, showBankCount)
            elseif(DoesItemLinkStartQuest(itemLink) or DoesItemLinkFinishQuest(itemLink)) then
                self:LayoutQuestStartOrFinishItem(itemLink, itemName, showInventoryCount, showBankCount)
            else
                -- now attempt to layout the itemlink by the item type
                local itemType = GetItemLinkItemType(itemLink)
                if(IsItemLinkEnchantingRune(itemLink)) then
                    self:LayoutEnchantingRune(itemLink, itemName, showInventoryCount, showBankCount)
                elseif(itemType == ITEMTYPE_LURE and IsItemLinkConsumable(itemLink)) then
                    self:LayoutLure(itemLink, itemName, showInventoryCount, showBankCount)
                else
                    local layoutFunction = LAYOUT_FUNCTIONS[itemType]
                    if layoutFunction then
                        layoutFunction(self, itemLink, creatorName, itemName, showInventoryCount, showBankCount)
                    else
                        if IsItemLinkBook(itemLink) then
                            self:LayoutBook(itemLink)
                        else -- fallback to our default layout
                            self:LayoutGenericItem(itemLink, equipped, creatorName, forceFullDurability, enchantMode, previewValueToAdd, itemName, showInventoryCount, showBankCount)
                        end
                    end
                end
            end
        end

        return isValidItemLink
    end
end

function ZO_Tooltip:LayoutItemWithStackCount(itemLink, equipped, creatorName, forceFullDurability, enchantMode, previewValueToAdd, customOrBagStackCount, showInventoryCount, showBankCount)
    local isValidItemLink = itemLink ~= ""
    if isValidItemLink then
        local stackCount
        if customOrBagStackCount == ZO_ITEM_TOOLTIP_INVENTORY_TITLE_COUNT then
            local bagCount, bankCount = GetItemLinkStacks(itemLink)
            stackCount = bagCount
        elseif customOrBagStackCount == ZO_ITEM_TOOLTIP_BANK_TITLE_COUNT then
            local bagCount, bankCount = GetItemLinkStacks(itemLink)
            stackCount = bankCount
        elseif customOrBagStackCount == ZO_ITEM_TOOLTIP_INVENTORY_AND_BANK_TITLE_COUNT then
            local bagCount, bankCount = GetItemLinkStacks(itemLink)
            stackCount = bagCount + bankCount
        else
            stackCount = customOrBagStackCount
        end

        local itemName = GetItemLinkName(itemLink)
        if stackCount and stackCount > 1 then
            itemName = zo_strformat(SI_TOOLTIP_ITEM_NAME_WITH_QUANTITY, itemName, stackCount)
        end
        return self:LayoutItem(itemLink, equipped, creatorName, forceFullDurability, enchantMode, previewValueToAdd, itemName, showInventoryCount, showBankCount)
    end
end

do
    local NOT_EQUIPPED = false
    local NO_CREATOR_NAME = nil
    local DONT_FORCE_FULL_DURABILITY = false
    local NO_ENCHANT_MODE = nil
    local NO_PREVIEW_VALUE = nil

    function ZO_Tooltip:LayoutItemWithStackCountSimple(itemLink, customOrBagStackCount, showInventoryCount, showBankCount)
        return self:LayoutItemWithStackCount(itemLink, NOT_EQUIPPED, NO_CREATOR_NAME, DONT_FORCE_FULL_DURABILITY, NO_ENCHANT_MODE, NO_PREVIEW_VALUE, customOrBagStackCount, showInventoryCount, showBankCount)
    end
end

-- "Specific Layout Functions"

function ZO_Tooltip:LayoutBagItem(bagId, slotIndex, enchantMode, showInventoryAndBagCount)
    local itemLink = GetItemLink(bagId, slotIndex)
    local equipped = bagId == BAG_WORN
    local showInventoryCount = ZO_ITEM_TOOLTIP_SHOW_INVENTORY_BODY_COUNT
    local showBankCount = ZO_ITEM_TOOLTIP_SHOW_BANK_BODY_COUNT
    local stackCount = ZO_ITEM_TOOLTIP_INVENTORY_TITLE_COUNT
    if showInventoryAndBagCount then
        stackCount = ZO_ITEM_TOOLTIP_INVENTORY_AND_BANK_TITLE_COUNT
    else
        if bagId == BAG_BANK then
            showBankCount = ZO_ITEM_TOOLTIP_HIDE_BANK_BODY_COUNT
            stackCount = ZO_ITEM_TOOLTIP_BANK_TITLE_COUNT
        elseif bagId == BAG_BACKPACK then
            showInventoryCount = ZO_ITEM_TOOLTIP_HIDE_INVENTORY_BODY_COUNT
            stackCount = ZO_ITEM_TOOLTIP_INVENTORY_TITLE_COUNT
        elseif equipped then
            showInventoryCount = ZO_ITEM_TOOLTIP_HIDE_INVENTORY_BODY_COUNT
            stackCount = 1
        end
    end

    return self:LayoutItemWithStackCount(itemLink, equipped, GetItemCreatorName(bagId, slotIndex), nil, enchantMode, nil, stackCount, showInventoryCount, showBankCount)
end

function ZO_Tooltip:LayoutTradeItem(who, tradeIndex)
    local itemLink = GetTradeItemLink(who, tradeIndex, LINK_STYLE_DEFAULT)
    local equipped = false
    local name, icon, stack, quality, creator, sellPrice, meetsUsageRequirement, equipType, itemStyle = GetTradeItemInfo(who, tradeIndex)
    return self:LayoutItemWithStackCount(itemLink, equipped, creator, nil, nil, nil, stack, ZO_ITEM_TOOLTIP_SHOW_INVENTORY_BODY_COUNT, ZO_ITEM_TOOLTIP_SHOW_BANK_BODY_COUNT)
end

function ZO_Tooltip:LayoutPendingSmithingItem(patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex)
    local _, _, icon = GetSmithingPatternInfo(patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex)
    local itemLink = GetSmithingPatternResultLink(patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex)

    if itemLink and itemLink ~= "" then
        if self.icon then
            self.icon:SetTexture(icon)
            self.icon:SetHidden(false)
        end

        self:LayoutItem(itemLink, NOT_EQUIPPED, nil)
    end
end

function ZO_Tooltip:LayoutPendingEnchantedItem(itemBagId, itemIndex, enchantmentBagId, enchantmentIndex)
    local itemLink = GetEnchantedItemResultingItemLink(itemBagId, itemIndex, enchantmentBagId, enchantmentIndex)
    self:LayoutItem(itemLink, NOT_EQUIPPED, nil, FORCE_FULL_DURABILITY, ZO_ENCHANT_DIFF_ADD)
end

function ZO_Tooltip:LayoutPendingItemChargeOrRepair(itemBagId, itemSlotIndex, improvementKitBagId, improvementKitIndex, improvementFunc, enchantDiffMode)
    local itemLink = GetItemLink(itemBagId, itemSlotIndex)
    local previewValueToAdd = improvementFunc(itemBagId, itemSlotIndex, improvementKitBagId, improvementKitIndex)
    self:LayoutItem(itemLink, NOT_EQUIPPED, nil, nil, ZO_ENCHANT_DIFF_NONE, previewValueToAdd)
end

function ZO_Tooltip:LayoutPendingItemCharge(itemBagId, itemSlotIndex, improvementKitBagId, improvementKitIndex)
    self:LayoutPendingItemChargeOrRepair(itemBagId, itemSlotIndex, improvementKitBagId, improvementKitIndex, GetAmountSoulGemWouldChargeItem)
end

function ZO_Tooltip:LayoutPendingItemRepair(itemBagId, itemSlotIndex, improvementKitBagId, improvementKitIndex)
    self:LayoutPendingItemChargeOrRepair(itemBagId, itemSlotIndex, improvementKitBagId, improvementKitIndex, GetAmountRepairKitWouldRepairItem)
end

function ZO_Tooltip:LayoutImprovedSmithingItem(itemToImproveBagId, itemToImproveSlotIndex, craftingSkillType)
    local _, icon = GetSmithingImprovedItemInfo(itemToImproveBagId, itemToImproveSlotIndex, craftingSkillType)
    local itemLink = GetSmithingImprovedItemLink(itemToImproveBagId, itemToImproveSlotIndex, craftingSkillType)

    if itemLink and itemLink ~= "" then
        if self.icon then
            self.icon:SetTexture(icon)
            self.icon:SetHidden(false)
        end

        self:LayoutItem(itemLink, NOT_EQUIPPED, nil)
    end
end

function ZO_Tooltip:LayoutResearchSmithingItem(traitType, traitDescription)
    if self.icon then
        self.icon:SetHidden(true)
    end

    self:AddLine(traitType, self:GetStyle("title"))
    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    bodySection:AddLine(traitDescription, self:GetStyle("bodyDescription"))
    self:AddSection(bodySection)
end

function ZO_Tooltip:LayoutQuestItem(questItem)
    local header, itemName, tooltipText
    if questItem.lootId then
        header, itemName, tooltipText = GetQuestLootItemTooltipInfo(questItem.lootId)
    elseif questItem.toolIndex then
        header, itemName, tooltipText = GetQuestToolTooltipInfo(questItem.questIndex, questItem.toolIndex)
    else
        header, itemName, tooltipText = GetQuestItemTooltipInfo(questItem.questIndex, questItem.stepIndex, questItem.conditionIndex)
    end

    local topSection = self:AcquireSection(self:GetStyle("topSection"))
    topSection:AddLine(header)
    local topLine = topSection:AcquireSection(self:GetStyle("topLine"))
    topSection:AddSectionEvenIfEmpty(topLine)
    self:AddSectionEvenIfEmpty(topSection)

    local qualityStyle = ZO_TooltipStyles_GetItemQualityStyle(1) --quest items are always white
    self:AddLine(zo_strformat(SI_TOOLTIP_ITEM_NAME, itemName), qualityStyle, self:GetStyle("title"))

    local flavorSection = self:AcquireSection(self:GetStyle("bodySection"))
    flavorSection:AddLine(tooltipText, self:GetStyle("flavorText"))
    self:AddSection(flavorSection)
end

function ZO_Tooltip:LayoutItemStatComparison(bagId, slotId, comparisonSlot)
    local statDeltaLookup = ZO_GetStatDeltaLookupFromItemComparisonReturns(CompareBagItemToCurrentlyEquipped(bagId, slotId, comparisonSlot))
    for _, statGroup in ipairs(ZO_INVENTORY_STAT_GROUPS) do
        local statSection = self:AcquireSection(self:GetStyle("itemComparisonStatSection"))
        for _, stat in ipairs(statGroup) do
            
            local statName = GetString("SI_DERIVEDSTATS", stat)
            local currentValue = GetPlayerStat(stat)
            local statDelta = statDeltaLookup[stat] or 0
            local valueToShow = currentValue + statDelta
            
            if stat == STAT_SPELL_CRITICAL or stat == STAT_CRITICAL_STRIKE then
                local USE_MINIMUM = true
                local newPercent = GetCriticalStrikeChance(valueToShow, USE_MINIMUM)
                valueToShow = zo_strformat(SI_STAT_VALUE_PERCENT, newPercent)
            end

            local colorStyle = self:GetStyle("itemComparisonStatValuePairDefaultColor")
            if statDelta ~= 0 then
                local icon
                if statDelta > 0 then
                    colorStyle = self:GetStyle("succeeded")
                    icon = "EsoUI/Art/Buttons/Gamepad/gp_upArrow.dds"
                else
                    colorStyle = self:GetStyle("failed")
                    icon = "EsoUI/Art/Buttons/Gamepad/gp_downArrow.dds"
                end
                valueToShow = valueToShow .. zo_iconFormatInheritColor(icon, 24, 24)
            end

            local statValuePair = statSection:AcquireStatValuePair(self:GetStyle("itemComparisonStatValuePair"))
            statValuePair:SetStat(statName, self:GetStyle("statValuePairStat"))
            statValuePair:SetValue(valueToShow, self:GetStyle("itemComparisonStatValuePairValue"), colorStyle)
            statSection:AddStatValuePair(statValuePair)
        end
        self:AddSection(statSection)
    end
    
end