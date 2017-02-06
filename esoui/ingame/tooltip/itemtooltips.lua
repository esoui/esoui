local FORCE_FULL_DURABILITY = true
local NOT_EQUIPPED = false
local DONT_SHOW_PLAYER_LOCKED = false

ZO_ENCHANT_DIFF_ADD = "add"
ZO_ENCHANT_DIFF_REMOVE = "remove"
ZO_ENCHANT_DIFF_NONE = "none"

ZO_ITEM_TOOLTIP_INVENTORY_TITLE_COUNT = "inventory"
ZO_ITEM_TOOLTIP_BANK_TITLE_COUNT = "bank"
ZO_ITEM_TOOLTIP_INVENTORY_AND_BANK_TITLE_COUNT = "inventoryAndBank"
ZO_ITEM_TOOLTIP_CRAFTBAG_TITLE_COUNT = "craftbag"
ZO_ITEM_TOOLTIP_INVENTORY_AND_BANK_AND_CRAFTBAG_TITLE_COUNT = "inventoryAndBankAndCraftbag"

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

function ZO_Tooltip:AddTopSection(itemLink, showPlayerLocked, tradeBoPData)
    local topSection = self:AcquireSection(self:GetStyle("topSection"))

    --Item Type Info
    local itemType, specializedItemType = GetItemLinkItemType(itemLink)
    local specializedItemTypeText = ZO_GetSpecializedItemTypeText(itemType, specializedItemType)
    local equipType = GetItemLinkEquipType(itemLink)
    if(itemType == ITEMTYPE_SIEGE) then
        local siegeType = GetItemLinkSiegeType(itemLink)
        if(siegeType ~= SIEGE_TYPE_NONE) then
            topSection:AddLine(GetString("SI_SIEGETYPE", siegeType))
        end
    elseif(itemType == ITEMTYPE_COSTUME) then
        self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, specializedItemTypeText)
    elseif(itemType == ITEMTYPE_RECIPE) then
        local craftingSkillType = GetItemLinkRecipeCraftingSkillType(itemLink)
        if IsItemLinkRecipeKnown(itemLink) then
            self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, specializedItemTypeText, GetCraftingSkillName(craftingSkillType))
        else
            self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, GetString(SI_ITEM_FORMAT_STR_UNKNOWN_RECIPE), GetCraftingSkillName(craftingSkillType))
        end
    elseif itemType == ITEMTYPE_FURNISHING then
        local furnitureDataId = GetItemLinkFurnitureDataId(itemLink)
        local categoryId, subcategoryId = GetFurnitureDataCategoryInfo(furnitureDataId)
        self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, specializedItemTypeText, GetFurnitureCategoryName(categoryId))
    elseif(itemType ~= ITEMTYPE_NONE and equipType ~= EQUIP_TYPE_INVALID) then
        local weaponType = GetItemLinkWeaponType(itemLink)
        if itemType == ITEMTYPE_ARMOR and weaponType == WEAPONTYPE_NONE then
            local armorType = GetItemLinkArmorType(itemLink)
            self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, GetString("SI_EQUIPTYPE", equipType), GetString("SI_ARMORTYPE", armorType))
        elseif weaponType ~= WEAPONTYPE_NONE then
            self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, GetString("SI_WEAPONTYPE", weaponType), GetString("SI_EQUIPTYPE", equipType))
        elseif itemType == ITEMTYPE_POISON then
            self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, specializedItemTypeText)
        end
    elseif(itemType == ITEMTYPE_LURE and IsItemLinkConsumable(itemLink)) then
        self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, GetString(SI_ITEM_SUB_TYPE_BAIT))
    elseif(GetItemLinkBookTitle(itemLink)) then
        local itemTypeText = (specializedItemType ~= SPECIALIZED_ITEMTYPE_NONE) and specializedItemTypeText or GetString(SI_ITEM_SUB_TYPE_BOOK)
        self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, itemTypeText)
    elseif(DoesItemLinkStartQuest(itemLink) or DoesItemLinkFinishQuest(itemLink)) then
        self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, GetString(SI_ITEM_FORMAT_STR_QUEST_ITEM))
    else
        local craftingSkillType = GetItemLinkCraftingSkillType(itemLink)
        if(craftingSkillType ~= CRAFTING_TYPE_INVALID) then
            local craftingSkillName = GetCraftingSkillName(craftingSkillType)
            self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, specializedItemTypeText, craftingSkillName)
        elseif(itemType ~= ITEMTYPE_NONE) then
            self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, specializedItemTypeText)
        end
    end

    self:AddTopLinesToTopSection(topSection, itemLink, showPlayerLocked, tradeBoPData)

    self:AddSectionEvenIfEmpty(topSection)
end

function ZO_Tooltip:AddTopLinesToTopSection(topSection, itemLink, showPlayerLocked, tradeBoPData)
    local topSubsection = topSection:AcquireSection(self:GetStyle("topSubsectionItemDetails"))
    
    -- Bound and/or Player Locked
    local boundLabel
    if tradeBoPData then
        boundLabel = zo_iconFormat(ZO_TRADE_BOP_ICON, 24, 24)
    else
        local bindType = GetItemLinkBindType(itemLink)
        if IsItemLinkBound(itemLink) then
            boundLabel = GetString(SI_ITEM_FORMAT_STR_BOUND)
        elseif bindType ~= BIND_TYPE_NONE and bindType ~= BIND_TYPE_UNSET then
            boundLabel = GetString("SI_BINDTYPE", bindType)
        end
    end

    if showPlayerLocked then
        topSubsection:AddLine(zo_iconTextFormat("EsoUI/Art/Tooltips/icon_lock.dds", 24, 24, boundLabel), self:GetStyle("bind"))
    elseif boundLabel then
        topSubsection:AddLine(boundLabel, self:GetStyle("bind"))
    end

    -- Stolen
    if IsItemLinkStolen(itemLink) then
        topSubsection:AddLine(zo_iconTextFormat("EsoUI/Art/Inventory/inventory_stolenItem_icon.dds", 24, 24, GetString(SI_GAMEPAD_ITEM_STOLEN_LABEL)), self:GetStyle("stolen"))
    end

    --Item counts
    local bagCount, bankCount, craftBagCount = GetItemLinkStacks(itemLink)
    if bagCount > 0 then
        topSubsection:AddLine(zo_iconTextFormat("EsoUI/Art/Tooltips/icon_bag.dds", 24, 24, bagCount))
    end

    if bankCount > 0 then
        topSubsection:AddLine(zo_iconTextFormat("EsoUI/Art/Tooltips/icon_bank.dds", 24, 24, bankCount))
    end

    if craftBagCount > 0 then
        topSubsection:AddLine(zo_iconTextFormat("EsoUI/Art/Tooltips/icon_craft_bag.dds", 24, 24, craftBagCount))
    end

    topSection:AddSectionEvenIfEmpty(topSubsection)
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

    --Required Level/Champ Rank
    if(not hideItemLevel) then
        local requiredLevel = GetItemLinkRequiredLevel(itemLink)
        local requiredChampionPoints = GetItemLinkRequiredChampionPoints(itemLink)
        if(requiredLevel > 0 or requiredChampionPoints > 0) then
            if requiredLevel > 0 then
                local levelStatValuePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
                levelStatValuePair:SetStat(GetString(SI_ITEM_FORMAT_STR_LEVEL), self:GetStyle("statValuePairStat"))
                local failedStyle = requiredLevel > GetUnitLevel("player") and self:GetStyle("failed") or nil
                levelStatValuePair:SetValue(requiredLevel, failedStyle, self:GetStyle("statValuePairValue"))
                statsSection:AddStatValuePair(levelStatValuePair)
            end
            if requiredChampionPoints > 0 then
                local championStatValuePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
                championStatValuePair:SetStat(zo_iconTextFormatNoSpace(GetGamepadChampionPointsIcon(), 32, 32, GetString(SI_ITEM_FORMAT_STR_CHAMPION)), self:GetStyle("statValuePairStat"))
                local failedStyle = requiredChampionPoints > GetPlayerChampionPointsEarned() and self:GetStyle("failed") or nil
                championStatValuePair:SetValue(requiredChampionPoints, failedStyle, self:GetStyle("statValuePairValue"))
                statsSection:AddStatValuePair(championStatValuePair)
            end
        end
    end

    self:AddSection(statsSection)
end

do
    local VALUE_ICON_FORMAT = zo_iconFormat("EsoUI/Art/currency/gamepad/gp_gold.dds", "32", "32")

    function ZO_Tooltip:AddItemValue(itemLink, ignoreLevel)
        local statsSection = self:AcquireSection(self:GetStyle("valueStatsSection"))
        local hideItemLevel = ignoreLevel or ShouldHideTooltipRequiredLevel(itemLink)

        --Value
        local CONSIDER_CONDITION = true
        local value = GetItemLinkValue(itemLink, not CONSIDER_CONDITION)
        if(value > 0) then
            local effectiveValue = GetItemLinkValue(itemLink, CONSIDER_CONDITION)
            local finalValue = value
            if(effectiveValue ~= value) then
                finalValue = zo_strformat(SI_ITEM_FORMAT_STR_EFFECTIVE_VALUE_OF_MAX, effectiveValue, value)
            end
            local valueString = zo_strformat(SI_GAMEPAD_TOOLTIP_ITEM_VALUE_FORMAT, finalValue, VALUE_ICON_FORMAT)
            statsSection:AddLine(valueString, self:GetStyle("statValuePairValue"))
        end
        self:AddSection(statsSection)
    end
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

function ZO_Tooltip:AddPoisonInfo(itemLink, equipSlot)
    local hasPoison, poisonCount, poisonHeader, poisonItemLink = GetItemPairedPoisonInfo(equipSlot)
    if(hasPoison) then
        --Poison Count
        local poisonCountSection = self:AcquireSection(self:GetStyle("poisonCountSection"))
        local poisonCountString = zo_iconTextFormatNoSpace("EsoUI/Art/Tooltips/icon_poison.dds", 40, 40, poisonCount)
        poisonCountSection:AddLine(poisonCountString, self:GetStyle("poisonCount"))
        self:AddSection(poisonCountSection)

        --Poison Name
        local equippedPoisonSection = self:AcquireSection(self:GetStyle("equippedPoisonSection"))
        equippedPoisonSection:AddLine(poisonHeader, self:GetStyle("bodyHeader"))
        self:AddSection(equippedPoisonSection)

        --Poison Ability
        self:AddOnUseAbility(poisonItemLink)
    end
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

function ZO_Tooltip:AddEnchant(itemLink, enchantDiffMode, equipSlot)
    enchantDiffMode = enchantDiffMode or ZO_ENCHANT_DIFF_NONE
    local enchantSection = self:AcquireSection(self:GetStyle("bodySection"))
    local hasEnchant, enchantHeader, enchantDescription = GetItemLinkEnchantInfo(itemLink)
    if(hasEnchant) then
        enchantSection:AddLine(enchantHeader, self:GetStyle("bodyHeader"))
        
        if enchantDiffMode == ZO_ENCHANT_DIFF_NONE then
            if (IsItemAffectedByPairedPoison(equipSlot)) then
                local suppressedStyle = self:GetStyle("suppressedAbility")
                enchantSection:AddLine(GetString(SI_TOOLTIP_ENCHANT_SUPPRESSED_BY_POISON), suppressedStyle, self:GetStyle("bodyDescription"))
            else
                enchantSection:AddLine(enchantDescription, self:GetStyle("bodyDescription"))
            end
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

function ZO_Tooltip:AddItemAbilityScalingRange(section, minLevel, maxLevel, isChampionPoints)
    local text
    if isChampionPoints then
        text = zo_strformat(SI_ITEM_ABILITY_SCALING_CHAMPION_POINTS_RANGE, zo_iconFormat(GetGamepadChampionPointsIcon(), 40, 40), minLevel, maxLevel)
    else
        text = zo_strformat(SI_ITEM_ABILITY_SCALING_LEVEL_RANGE, minLevel, maxLevel)
    end
    section:AddLine(text, self:GetStyle("bodyDescription"))
end

function ZO_Tooltip:AddOnUseAbility(itemLink)
    local onUseAbilitySection = self:AcquireSection(self:GetStyle("bodySection"))
    local hasAbility, abilityHeader, abilityDescription, cooldown, hasScaling, minLevel, maxLevel, isChampionPoints = GetItemLinkOnUseAbilityInfo(itemLink)
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
                self:AddItemAbilityScalingRange(onUseAbilitySection, minLevel, maxLevel, isChampionPoints)
            end
        end
    else
        local traitAbilities = {}
        local maxCooldown = 0
        for i = 1, GetMaxTraits() do
            local hasTraitAbility, traitAbilityDescription, traitCooldown, traitHasScaling, traitMinLevel, traitMaxLevel, traitIsChampionPoints = GetItemLinkTraitOnUseAbilityInfo(itemLink, i)
            if(hasTraitAbility) then
                table.insert(traitAbilities, 
                {
                    description = traitAbilityDescription,
                    hasScaling = traitHasScaling,
                    minLevel = traitMinLevel,
                    maxLevel = traitMaxLevel,
                    isChampionPoints = traitIsChampionPoints,
                })
                if(traitCooldown > maxCooldown) then
                    maxCooldown = traitCooldown
                end
            end
        end

        for i, traitAbility in ipairs(traitAbilities) do
            local text
            if i == #traitAbilities then
                if maxCooldown == 0 then
                    text = zo_strformat(SI_ITEM_FORMAT_STR_ON_USE, traitAbility.description)
                else
                    text = zo_strformat(SI_ITEM_FORMAT_STR_ON_USE_COOLDOWN, traitAbility.description, maxCooldown / 1000)
                end
            else
                text = zo_strformat(SI_ITEM_FORMAT_STR_ON_USE_MULTI_EFFECT, traitAbility.description)
            end
            onUseAbilitySection:AddLine(text, self:GetStyle("bodyDescription"))
        end

        --We assume that if multiple trait abilities have scaling, they all have the same scaling
        for _, traitAbility in ipairs(traitAbilities) do
            if traitAbility.hasScaling then
                self:AddItemAbilityScalingRange(onUseAbilitySection, traitAbility.minLevel, traitAbility.maxLevel, traitAbility.isChampionPoints)
                break
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

function ZO_Tooltip:AddPoisonSystemDescription()
    local poisonSystemDescriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
    poisonSystemDescriptionSection:AddLine(GetString(SI_POISON_SYSTEM_INFO), self:GetStyle("flavorText"))
    self:AddSection(poisonSystemDescriptionSection)
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

function ZO_Tooltip:AddItemTags(itemLink)
    local numItemTags = GetItemLinkNumItemTags(itemLink)
    if numItemTags > 0 then
        local itemTagStrings = {}

        -- Build a map of tag category -> table of tags in that category
        for i = 1, numItemTags do
            local itemTagDescription, itemTagCategory = GetItemLinkItemTagInfo(itemLink, i)
            if itemTagDescription ~= "" then
                if not itemTagStrings[itemTagCategory] then
                    itemTagStrings[itemTagCategory] = {}
                end
                table.insert(itemTagStrings[itemTagCategory], zo_strformat(SI_TOOLTIP_ITEM_TAG_FORMATER, itemTagDescription)) 
            end
        end

        -- Iterate through categories, and build a section for each category with tags in it
        for i = TAG_CATEGORY_MIN_VALUE, TAG_CATEGORY_MAX_VALUE do
            if itemTagStrings[i] then
                local itemTagsSection = self:AcquireSection(self:GetStyle("itemTagsSection"))
                local categoryName = GetString("SI_ITEMTAGCATEGORY", i)
                if categoryName ~= "" then
                    itemTagsSection:AddLine(categoryName, self:GetStyle("itemTagTitle"))
                end
                itemTagsSection:AddLine(table.concat(itemTagStrings[i], GetString(SI_LIST_COMMA_SEPARATOR)), self:GetStyle("itemTagDescription"))
                self:AddSection(itemTagsSection)
            end
        end
    end
end

--Layout Functions

function ZO_Tooltip:LayoutGenericItem(itemLink, equipped, creatorName, forceFullDurability, enchantMode, previewValueToAdd, itemName, equipSlot, showPlayerLocked, tradeBoPData)
    self:AddTopSection(itemLink, showPlayerLocked, tradeBoPData)
    self:AddItemTitle(itemLink, itemName)
    self:AddBaseStats(itemLink)
    if(DoesItemLinkHaveArmorDecay(itemLink)) then
        self:AddConditionBar(itemLink, previewValueToAdd)
    elseif(equipped and IsItemAffectedByPairedPoison(equipSlot)) then
        self:AddPoisonInfo(itemLink, equipSlot)
    elseif(DoesItemLinkHaveEnchantCharges(itemLink)) then
        self:AddEnchantChargeBar(itemLink, forceFullDurability, previewValueToAdd)
    end

    self:AddEnchant(itemLink, enchantMode, equipSlot)
    self:AddOnUseAbility(itemLink)
    self:AddTrait(itemLink)
    self:AddSet(itemLink, equipped)
    if GetItemLinkItemType(itemLink) == ITEMTYPE_POISON then
        self:AddPoisonSystemDescription()
    end
    self:AddFlavorText(itemLink)
    -- We don't want crafted furniture to show who made it, since it will get cleared once placed in a house
    -- TODO: If we implement saving the creator name, add back in LayoutItemCreator call (ESO-495280)
    if not IsItemLinkPlaceableFurniture(itemLink) then
        self:AddCreator(itemLink, creatorName)
    end
    self:AddItemTags(itemLink)
    self:LayoutTradeBoPInfo(tradeBoPData)
    self:AddItemValue(itemLink)
end

function ZO_Tooltip:LayoutVendorTrash(itemLink, itemName)
    self:AddItemTitle(itemLink, itemName)
    self:AddBaseStats(itemLink)
    self:AddFlavorText(itemLink)
    self:AddItemTags(itemLink)
    self:AddItemValue(itemLink)
end

function ZO_Tooltip:LayoutBooster(itemLink, itemName)
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
    self:AddItemTags(itemLink)
end

do
    local FORMATTED_CHAMPION_RANK_ICON = zo_iconFormat(GetGamepadChampionPointsIcon(), 40, 40)
    function ZO_Tooltip:LayoutInlineGlyph(itemLink, itemName)
        self:AddItemTitle(itemLink, itemName)
        self:AddEnchant(itemLink)

        local minLevel, minChampionPoints = GetItemLinkGlyphMinLevels(itemLink)
        if(minLevel or minChampionPoints) then
            local requirementsSection = self:AcquireSection(self:GetStyle("bodySection"))
            if minChampionPoints then
                requirementsSection:AddLine(zo_strformat(SI_ENCHANTING_GLYPH_REQUIRED_SINGLE_CHAMPION_POINTS_GAMEPAD, FORMATTED_CHAMPION_RANK_ICON, minChampionPoints), self:GetStyle("bodyDescription"))
            else
                requirementsSection:AddLine(zo_strformat(SI_ENCHANTING_GLYPH_REQUIRED_SINGLE_LEVEL, minLevel), self:GetStyle("bodyDescription"))
            end
            self:AddSection(requirementsSection)
        end

        self:AddFlavorText(itemLink)
    end
end

function ZO_Tooltip:LayoutGlyph(itemLink, creatorName, itemName, tradeBoPData)
    self:AddTopSection(itemLink, DONT_SHOW_PLAYER_LOCKED, tradeBoPData)
    self:LayoutInlineGlyph(itemLink, itemName)
    self:AddCreator(itemLink, creatorName)
    self:AddItemTags(itemLink)
    self:LayoutTradeBoPInfo(tradeBoPData)
end

function ZO_Tooltip:LayoutSiege(itemLink, itemName, tradeBoPData)
    self:AddTopSection(itemLink, DONT_SHOW_PLAYER_LOCKED, tradeBoPData)
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
    self:AddItemTags(itemLink)
    self:LayoutTradeBoPInfo(tradeBoPData)
end

function ZO_Tooltip:LayoutTool(itemLink, itemName, tradeBoPData)
    self:AddTopSection(itemLink, DONT_SHOW_PLAYER_LOCKED, tradeBoPData)
    self:AddItemTitle(itemLink, itemName)
    self:AddBaseStats(itemLink)
    self:AddFlavorText(itemLink)
    self:AddItemTags(itemLink)
    self:LayoutTradeBoPInfo(tradeBoPData)
    self:AddItemValue(itemLink)
end

function ZO_Tooltip:LayoutSoulGem(itemLink, itemName)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)
    self:AddBaseStats(itemLink)
    self:AddFlavorText(itemLink)
    self:AddItemTags(itemLink)
    self:AddItemValue(itemLink)
end

function ZO_Tooltip:LayoutAvARepair(itemLink, itemName)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)
    self:AddFlavorText(itemLink)
    self:AddItemTags(itemLink)
end

do
    local function AddDyeSwatchSection(dyeId, section, entryStyle, swatchStyle)
        local entrySection = section:AcquireSection()
        local dyeName, known, rarity, hueCategory, achievementId, r, g, b = GetDyeInfoById(dyeId)
        entrySection:AddColorAndTextSwatch(r, g, b, 1, dyeName, swatchStyle)
        section:AddSection(entrySection)
    end

    function ZO_Tooltip:LayoutDyeStamp(itemLink, itemName)
        self:AddTopSection(itemLink)
        self:AddItemTitle(itemLink, itemName)
        local onUseType = GetItemLinkItemUseType(itemLink)
        local descriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
        if onUseType == ITEM_USE_TYPE_ITEM_DYE_STAMP then
            descriptionSection:AddLine(GetString(SI_DYE_STAMP_ITEM_DESCRIPTION), self:GetStyle("bodyDescription"))
        elseif onUseType == ITEM_USE_TYPE_COSTUME_DYE_STAMP then
            descriptionSection:AddLine(GetString(SI_DYE_STAMP_COSTUME_DESCRIPTION), self:GetStyle("bodyDescription"))
        end
        self:AddSection(descriptionSection)

        -- list of dyes in stamp
        local primaryDefId, secondaryDefId, accentDefId = GetItemLinkDyeIds(itemLink)
        local dyesSection = self:AcquireSection(self:GetStyle("dyesSection"))
        local swatchStyle = self:GetStyle("dyeSwatchStyle")
        local entryStyle = self:GetStyle("dyeSwatchEntrySection")

        AddDyeSwatchSection(primaryDefId, dyesSection, entryStyle, swatchStyle)
        AddDyeSwatchSection(secondaryDefId, dyesSection, entryStyle, swatchStyle)
        AddDyeSwatchSection(accentDefId, dyesSection, entryStyle, swatchStyle)

        self:AddSection(dyesSection)

        self:AddFlavorText(itemLink)
        self:AddItemTags(itemLink)

        local dyeStampId = GetItemLinkDyeStampId(itemLink)
        local errorSection = self:AcquireSection(self:GetStyle("bodySection"))
        if not IsCharacterPreviewingAvailable() then
            errorSection:AddLine(GetString(SI_DYE_STAMP_NOT_USABLE_NOW), self:GetStyle("dyeStampError"))
        elseif onUseType == ITEM_USE_TYPE_ITEM_DYE_STAMP then
            local useResult = CanPlayerUseItemDyeStamp(dyeStampId)
            if useResult == DYE_STAMP_USE_RESULT_NO_ACTIVE_ITEMS then
                errorSection:AddLine(GetString(SI_DYE_STAMP_REQUIRES_EQUIPMENT), self:GetStyle("dyeStampError"))
            elseif useResult == DYE_STAMP_USE_RESULT_NO_VALID_ITEMS then
                errorSection:AddLine(GetString(SI_DYE_STAMP_SAME_DYE_DATA), self:GetStyle("dyeStampError"))
            end
        elseif onUseType == ITEM_USE_TYPE_COSTUME_DYE_STAMP then
            local useResult = CanPlayerUseCostumeDyeStamp(dyeStampId)
            if useResult == DYE_STAMP_USE_RESULT_NO_ACTIVE_COLLECTIBLES then
                errorSection:AddLine(GetString(SI_DYE_STAMP_REQUIRES_COLLECTIBLE), self:GetStyle("dyeStampError"))
            elseif useResult == DYE_STAMP_USE_RESULT_NO_VALID_COLLECTIBLES then
                errorSection:AddLine(GetString(SI_DYE_STAMP_SAME_DYE_DATA), self:GetStyle("dyeStampError"))
            end
        end
        self:AddSection(errorSection)
    end
end

function ZO_Tooltip:LayoutMasterWritItem(itemLink, tradeBoPData)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink)

    local writDescription = self:AcquireSection(self:GetStyle("bodySection"))
    writDescription:AddLine(GenerateMasterWritBaseText(itemLink), self:GetStyle("bodyDescription"))
    self:AddSection(writDescription)

    local rewardDescription = self:AcquireSection(self:GetStyle("bodySection"))
    rewardDescription:AddLine(GenerateMasterWritRewardText(itemLink), self:GetStyle("bodyDescription"))
    self:AddSection(rewardDescription)

    self:AddFlavorText(itemLink)
    self:AddItemTags(itemLink)
    self:LayoutTradeBoPInfo(tradeBoPData)
end

function ZO_Tooltip:LayoutBook(itemLink, tradeBoPData)
    self:AddTopSection(itemLink, DONT_SHOW_PLAYER_LOCKED, tradeBoPData)
    self:AddItemTitle(itemLink)
    local knownSection = self:AcquireSection(self:GetStyle("bodySection"))
    if(IsItemLinkBookKnown(itemLink)) then
        knownSection:AddLine(GetString(SI_LORE_LIBRARY_IN_LIBRARY), self:GetStyle("bodyDescription"))
    else
        knownSection:AddLine(GetString(SI_LORE_LIBRARY_USE_TO_LEARN), self:GetStyle("bodyDescription"))
    end
    self:AddSection(knownSection)
    self:AddFlavorText(itemLink)
    self:AddItemTags(itemLink)
    self:LayoutTradeBoPInfo(tradeBoPData)
end

function ZO_Tooltip:LayoutLure(itemLink, itemName)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)
    self:AddFlavorText(itemLink)
    self:AddItemTags(itemLink)
end

function ZO_Tooltip:LayoutQuestStartOrFinishItem(itemLink, itemName)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink)
    self:AddFlavorText(itemLink)
    self:AddItemTags(itemLink)
end

function ZO_Tooltip:LayoutProvisionerRecipe(itemLink, itemName, tradeBoPData)
    self:AddTopSection(itemLink, DONT_SHOW_PLAYER_LOCKED, tradeBoPData)
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
            local ingredientName, numOwned, numRequired = GetItemLinkRecipeIngredientInfo(itemLink, i)
            local hasIngredientStyle
            if numOwned >= numRequired then
                hasIngredientStyle = self:GetStyle("hasIngredient")
            else
                hasIngredientStyle = self:GetStyle("doesntHaveIngredient")
            end
            local ingredientNameWithRequiredQuantity = zo_strformat(SI_RECIPE_INGREDIENT_WITH_COUNT, ingredientName, numRequired)
            ingredientsSection:AddLine(zo_strformat(SI_NUMBERED_LIST_ENTRY, i, ingredientNameWithRequiredQuantity), hasIngredientStyle, self:GetStyle("bodyDescription"))
        end
        self:AddSection(ingredientsSection)
    end

    --Requirements
    local requirementsSection = self:AcquireSection(self:GetStyle("bodySection"))
    requirementsSection:AddLine(GetString(SI_PROVISIONER_REQUIREMENTS_HEADER), self:GetStyle("bodyHeader"))

    for tradeskillIndex = 1, GetItemLinkRecipeNumTradeskillRequirements(itemLink) do
        local tradeskill, levelReq = GetItemLinkRecipeTradeskillRequirement(itemLink, tradeskillIndex)
        local level = GetNonCombatBonus(GetNonCombatBonusLevelTypeForTradeskillType(tradeskill))
        local rankSuccessStyle
        if level < levelReq then
            rankSuccessStyle = self:GetStyle("failed")
        else
            rankSuccessStyle = self:GetStyle("succeeded")
        end

        local levelPassiveAbilityId = GetTradeskillLevelPassiveAbilityId(tradeskill)
        local levelPassiveAbilityName = GetAbilityName(levelPassiveAbilityId)            
        requirementsSection:AddLine(zo_strformat(SI_RECIPE_REQUIRES_LEVEL_PASSIVE, levelPassiveAbilityName, levelReq),  rankSuccessStyle, self:GetStyle("bodyDescription"))
    end
    
    local requiredQuality = GetItemLinkRecipeQualityRequirement(itemLink)
    if requiredQuality > 0 then
        local quality = GetNonCombatBonus(NON_COMBAT_BONUS_PROVISIONING_RARITY_LEVEL)
        local qualitySuccessStyle
        if(quality >= requiredQuality) then
            qualitySuccessStyle = self:GetStyle("succeeded")
        else
            qualitySuccessStyle = self:GetStyle("failed")
        end
        --Only exclusively provisioning system recipes have a quality requirement
        requirementsSection:AddLine(zo_strformat(SI_PROVISIONER_REQUIRES_RECIPE_QUALITY, requiredQuality),  qualitySuccessStyle, self:GetStyle("bodyDescription"))
    end

    self:AddSection(requirementsSection)

    --Use to learn
    local useToLearnOrKnownSection = self:AcquireSection(self:GetStyle("bodySection"))
    if(IsItemLinkRecipeKnown(itemLink)) then
        useToLearnOrKnownSection:AddLine(GetString(SI_RECIPE_ALREADY_KNOWN), self:GetStyle("bodyDescription"))
    else
        useToLearnOrKnownSection:AddLine(GetString(SI_GAMEPAD_PROVISIONER_USE_TO_LEARN_RECIPE), self:GetStyle("bodyDescription"))
    end
    self:AddSection(useToLearnOrKnownSection)
    self:AddItemTags(itemLink)
    self:LayoutTradeBoPInfo(tradeBoPData)
    self:AddItemValue(itemLink)
end

function ZO_Tooltip:LayoutReagent(itemLink, itemName)
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
    self:AddItemTags(itemLink)
end

function ZO_Tooltip:LayoutEnchantingRune(itemLink, itemName)
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
end

function ZO_Tooltip:LayoutAlchemyBase(itemLink, itemName)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)

    local requiredLevel = GetItemLinkRequiredLevel(itemLink)
    local requiredChampionPoints = GetItemLinkRequiredChampionPoints(itemLink)
    local itemType = GetItemLinkItemType(itemLink)
    local itemTypeString = GetString((itemType == ITEMTYPE_POTION_BASE) and SI_ITEM_FORMAT_STR_POTION or SI_ITEM_FORMAT_STR_POISON)

    if(requiredLevel > 0 or requiredChampionPoints > 0) then
        local createsSection = self:AcquireSection(self:GetStyle("bodySection"))
        if(requiredChampionPoints > 0) then
            createsSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_CREATES_ALCHEMY_ITEM_OF_CHAMPION_POINTS, requiredChampionPoints, itemTypeString), self:GetStyle("bodyDescription"))
        else
            createsSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_CREATES_ALCHEMY_ITEM_OF_LEVEL, requiredLevel, itemTypeString), self:GetStyle("bodyDescription"))
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
    self:AddItemTags(itemLink)
end

function ZO_Tooltip:LayoutIngredient(itemLink, itemName)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)
    self:AddFlavorText(itemLink)
    self:AddItemTags(itemLink)
end

function ZO_Tooltip:LayoutStyleMaterial(itemLink, itemName)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)

    local styleSection = self:AcquireSection(self:GetStyle("bodySection"))
    local style = GetItemLinkItemStyle(itemLink)
    local descriptionString = SI_ITEM_FORMAT_STR_STYLE_MATERIAL
    if style == ITEMSTYLE_UNIVERSAL then
        descriptionString = SI_ITEM_DESCRIPTION_UNIVERSAL_STYLE
    end
    styleSection:AddLine(zo_strformat(descriptionString, GetString("SI_ITEMSTYLE", style)), self:GetStyle("bodyDescription"))
    self:AddSection(styleSection)
    self:AddItemTags(itemLink)
end

function ZO_Tooltip:LayoutRawMaterial(itemLink, itemName)
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
    self:AddItemTags(itemLink)
end

function ZO_Tooltip:LayoutMaterial(itemLink, itemName)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)
    self:AddMaterialLevels(itemLink)
    self:AddItemTags(itemLink)
end

function ZO_Tooltip:LayoutArmorTrait(itemLink, itemName)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)

    local traitDescriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
    traitDescriptionSection:AddLine(GetString(SI_ITEM_FORMAT_STR_ARMOR_TRAIT), self:GetStyle("bodyDescription"))
    self:AddSection(traitDescriptionSection)

    self:AddTrait(itemLink)
    self:AddItemTags(itemLink)
end

function ZO_Tooltip:LayoutWeaponTrait(itemLink, itemName)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)

    local traitDescriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
    traitDescriptionSection:AddLine(GetString(SI_ITEM_FORMAT_STR_WEAPON_TRAIT), self:GetStyle("bodyDescription"))
    self:AddSection(traitDescriptionSection)

    self:AddTrait(itemLink)
    self:AddItemTags(itemLink)
end

function ZO_Tooltip:LayoutAlchemyPreview(solventBagId, solventSlotIndex, reagent1BagId, reagent1SlotIndex, reagent2BagId, reagent2SlotIndex, reagent3BagId, reagent3SlotIndex)
    local _, icon = GetAlchemyResultingItemInfo(solventBagId, solventSlotIndex, reagent1BagId, reagent1SlotIndex, reagent2BagId, reagent2SlotIndex, reagent3BagId, reagent3SlotIndex)
    local itemLink = GetAlchemyResultingItemLink(solventBagId, solventSlotIndex, reagent1BagId, reagent1SlotIndex, reagent2BagId, reagent2SlotIndex, reagent3BagId, reagent3SlotIndex)

    if itemLink and itemLink ~= "" then
        if self.icon then
            self.icon:SetTexture(icon)
            self.icon:SetHidden(false)
        end

        self:AddTopSection(itemLink)
        self:AddItemTitle(itemLink)
        self:AddBaseStats(itemLink)
        self:AddOnUseAbility(itemLink)
    else
        if self.icon then
            self.icon:SetHidden(true)
        end
        
        local solventType = GetItemType(solventBagId, solventSlotIndex)
        local itemTypeString = GetString(solventType == ITEMTYPE_POTION_BASE and SI_ITEM_FORMAT_STR_POTION or SI_ITEM_FORMAT_STR_POISON)

        self:AddLine(zo_strformat(SI_ALCHEMY_UNKNOWN_RESULT, itemTypeString), self:GetStyle("title"))
        local alchemySection = self:AcquireSection(self:GetStyle("bodySection"))
        alchemySection:AddLine(zo_strformat(SI_ALCHEMY_UNKNOWN_EFFECTS, itemTypeString), self:GetStyle("bodyDescription"))
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
        self:LayoutItemWithStackCountSimple(itemLink, stackCount)
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

function ZO_Tooltip:LayoutUniversalStyleItem(itemLink)
    self:AddTopSection(itemLink)
    local stackCount = GetCurrentSmithingStyleItemCount(ZO_ADJUSTED_UNIVERSAL_STYLE_ITEM_INDEX)
    local itemName = GetItemLinkName(itemLink)
    if stackCount then
        itemName = zo_strformat(SI_GAMEPAD_SMITHING_TOOLTIP_UNIVERSAL_STYLE_ITEM_TITLE, itemName, stackCount)
    end
    self:AddLine(itemName, self:GetStyle("title"))

    local styleSection = self:AcquireSection(self:GetStyle("bodySection"))
    local style = GetItemLinkItemStyle(itemLink)
    styleSection:AddLine(GetString(SI_CRAFTING_UNIVERSAL_STYLE_ITEM_TOOLTIP), self:GetStyle("bodyDescription"))
    styleSection:AddLine(GetString(SI_CRAFTING_UNIVERSAL_STYLE_ITEM_CROWN_STORE_TOOLTIP), self:GetStyle("bodyDescription"))
    self:AddSection(styleSection)
    self:AddItemTags(itemLink)
end

function ZO_Tooltip:LayoutTradeBoPInfo(tradeBoPData)
    if tradeBoPData then
        local timeRemaining = tradeBoPData.timeRemaining
        local tradeBoPSection = self:AcquireSection(self:GetStyle("bodySection"), self:GetStyle("itemTradeBoPSection"))

        local formattedTimeRemaining
        if timeRemaining > ZO_ONE_MINUTE_IN_SECONDS then
            formattedTimeRemaining = zo_round(timeRemaining / ZO_ONE_MINUTE_IN_SECONDS) * ZO_ONE_MINUTE_IN_SECONDS
            formattedTimeRemaining = ZO_FormatTime(formattedTimeRemaining, TIME_FORMAT_STYLE_DESCRIPTIVE_SHORT, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
        else
            formattedTimeRemaining = GetString(SI_STR_TIME_LESS_THAN_MINUTE)
        end

        local statValuePairTimer = tradeBoPSection:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
        statValuePairTimer:SetStat(GetString(SI_ITEM_FORMAT_STR_TRADE_BOP_TIMER_HEADER), self:GetStyle("statValuePairStat"), self:GetStyle("itemTradeBoPHeader"))
        statValuePairTimer:SetValue(formattedTimeRemaining, self:GetStyle("statValuePairValue"))
        tradeBoPSection:AddStatValuePair(statValuePairTimer)

        tradeBoPSection:AddLine(GetString(SI_ITEM_FORMAT_STR_TRADE_BOP_PLAYERS_HEADER), self:GetStyle("statValuePairStat"), self:GetStyle("itemTradeBoPHeader"))
        tradeBoPSection:AddLine(tradeBoPData.namesString, self:GetStyle("statValuePairValue"), self:GetStyle("fullWidth"))

        self:AddSection(tradeBoPSection)
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
        [ITEMTYPE_RECIPE] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutProvisionerRecipe(itemLink, itemName, tradeBoPData) end,

        [ITEMTYPE_BLACKSMITHING_BOOSTER] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutBooster(itemLink, itemName) end,
        [ITEMTYPE_WOODWORKING_BOOSTER] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutBooster(itemLink, itemName) end,
        [ITEMTYPE_CLOTHIER_BOOSTER] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutBooster(itemLink, itemName) end,

        [ITEMTYPE_GLYPH_WEAPON] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutGlyph(itemLink, creatorName, itemName, tradeBoPData) end,
        [ITEMTYPE_GLYPH_ARMOR] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutGlyph(itemLink, creatorName, itemName, tradeBoPData) end,
        [ITEMTYPE_GLYPH_JEWELRY] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutGlyph(itemLink, creatorName, itemName, tradeBoPData) end,

        [ITEMTYPE_REAGENT] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutReagent(itemLink, itemName) end,

        [ITEMTYPE_POTION_BASE] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutAlchemyBase(itemLink, itemName) end,
        [ITEMTYPE_POISON_BASE] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutAlchemyBase(itemLink, itemName) end,

        [ITEMTYPE_INGREDIENT] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutIngredient(itemLink, itemName) end,

        [ITEMTYPE_STYLE_MATERIAL] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutStyleMaterial(itemLink, itemName) end,

        [ITEMTYPE_BLACKSMITHING_RAW_MATERIAL] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutRawMaterial(itemLink, itemName) end,
        [ITEMTYPE_CLOTHIER_RAW_MATERIAL] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutRawMaterial(itemLink, itemName) end,
        [ITEMTYPE_WOODWORKING_RAW_MATERIAL] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutRawMaterial(itemLink, itemName) end,

        [ITEMTYPE_BLACKSMITHING_MATERIAL] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutMaterial(itemLink, itemName) end,
        [ITEMTYPE_CLOTHIER_MATERIAL] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutMaterial(itemLink, itemName) end,
        [ITEMTYPE_WOODWORKING_MATERIAL] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutMaterial(itemLink, itemName) end,

        [ITEMTYPE_ARMOR_TRAIT] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutArmorTrait(itemLink, itemName) end,

        [ITEMTYPE_WEAPON_TRAIT] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutWeaponTrait(itemLink, itemName) end,

        [ITEMTYPE_SIEGE] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutSiege(itemLink, itemName, tradeBoPData) end,

        [ITEMTYPE_TOOL] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutTool(itemLink, itemName, tradeBoPData) end,

        [ITEMTYPE_SOUL_GEM] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutSoulGem(itemLink, itemName) end,

        [ITEMTYPE_AVA_REPAIR] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutAvARepair(itemLink, itemName) end,

        [ITEMTYPE_DYE_STAMP] = function(self, itemLink, creatorName, itemName, tradeBoPData) self:LayoutDyeStamp(itemLink, itemName) end,
    }

    --TODO: Get creatorName from itemLink?
    --TODO: Pass in some sort of struct for containing all the additional item tooltip parameters
    function ZO_Tooltip:LayoutItem(itemLink, equipped, creatorName, forceFullDurability, enchantMode, previewValueToAdd, itemName, equipSlot, showPlayerLocked, tradeBoPData)
        local isValidItemLink = itemLink ~= ""
        if isValidItemLink then
            --first do checks that can't be determined from the item type
            if(IsItemLinkVendorTrash(itemLink)) then
                self:LayoutVendorTrash(itemLink, itemName)
            elseif(DoesItemLinkStartQuest(itemLink) or DoesItemLinkFinishQuest(itemLink)) then
                if GetItemLinkItemType(itemLink) == ITEMTYPE_MASTER_WRIT then
                    self:LayoutMasterWritItem(itemLink, tradeBoPData)
                else
                    self:LayoutQuestStartOrFinishItem(itemLink, itemName)
                end
            else
                -- now attempt to layout the itemlink by the item type
                local itemType = GetItemLinkItemType(itemLink)
                if(IsItemLinkEnchantingRune(itemLink)) then
                    self:LayoutEnchantingRune(itemLink, itemName)
                elseif(itemType == ITEMTYPE_LURE and IsItemLinkConsumable(itemLink)) then
                    self:LayoutLure(itemLink, itemName)
                else
                    local layoutFunction = LAYOUT_FUNCTIONS[itemType]
                    if layoutFunction then
                        layoutFunction(self, itemLink, creatorName, itemName, tradeBoPData)
                    else
                        if IsItemLinkBook(itemLink) then
                            self:LayoutBook(itemLink, tradeBoPData)
                        else -- fallback to our default layout
                            if equipped == NOT_EQUIPPED then
                                equipSlot = EQUIP_SLOT_NONE
                            end
                            self:LayoutGenericItem(itemLink, equipped, creatorName, forceFullDurability, enchantMode, previewValueToAdd, itemName, equipSlot, showPlayerLocked, tradeBoPData)
                        end
                    end
                end
            end
        end

        return isValidItemLink
    end
end

function ZO_Tooltip:LayoutItemWithStackCount(itemLink, equipped, creatorName, forceFullDurability, enchantMode, previewValueToAdd, customOrBagStackCount, equipSlot, showPlayerLocked, tradeBoPData)
    local isValidItemLink = itemLink ~= ""
    if isValidItemLink then
        local stackCount
        local bagCount, bankCount, craftBagCount = GetItemLinkStacks(itemLink)
        if customOrBagStackCount == ZO_ITEM_TOOLTIP_INVENTORY_TITLE_COUNT then
            stackCount = bagCount
        elseif customOrBagStackCount == ZO_ITEM_TOOLTIP_BANK_TITLE_COUNT then
            stackCount = bankCount
        elseif customOrBagStackCount == ZO_ITEM_TOOLTIP_INVENTORY_AND_BANK_TITLE_COUNT then
            stackCount = bagCount + bankCount
        elseif customOrBagStackCount == ZO_ITEM_TOOLTIP_CRAFTBAG_TITLE_COUNT then
            stackCount = craftBagCount
        elseif customOrBagStackCount == ZO_ITEM_TOOLTIP_INVENTORY_AND_BANK_AND_CRAFTBAG_TITLE_COUNT then
            stackCount = bagCount + bankCount + craftBagCount
        else
            stackCount = customOrBagStackCount
        end

        local itemName = GetItemLinkName(itemLink)
        if stackCount and stackCount > 1 then
            itemName = zo_strformat(SI_TOOLTIP_ITEM_NAME_WITH_QUANTITY, itemName, stackCount)
        end
        return self:LayoutItem(itemLink, equipped, creatorName, forceFullDurability, enchantMode, previewValueToAdd, itemName, equipSlot, showPlayerLocked, tradeBoPData)
    end
end

do
    local NOT_EQUIPPED = false
    local NO_CREATOR_NAME = nil
    local DONT_FORCE_FULL_DURABILITY = false
    local NO_ENCHANT_MODE = nil
    local NO_PREVIEW_VALUE = nil

    function ZO_Tooltip:LayoutItemWithStackCountSimple(itemLink, customOrBagStackCount)
        return self:LayoutItemWithStackCount(itemLink, NOT_EQUIPPED, NO_CREATOR_NAME, DONT_FORCE_FULL_DURABILITY, NO_ENCHANT_MODE, NO_PREVIEW_VALUE, customOrBagStackCount, EQUIP_SLOT_NONE)
    end
end

-- "Specific Layout Functions"

function ZO_Tooltip:LayoutBagItem(bagId, slotIndex, enchantMode, showCombinedCount)
    local itemLink = GetItemLink(bagId, slotIndex)
    local showPlayerLocked = IsItemPlayerLocked(bagId, slotIndex)
    local equipped = bagId == BAG_WORN
    local equipSlot = equipped and slotIndex or EQUIP_SLOT_NONE
    local showCraftBagCount = ZO_ITEM_TOOLTIP_SHOW_CRAFTBAG_BODY_COUNT
    local stackCount = ZO_ITEM_TOOLTIP_INVENTORY_TITLE_COUNT
    if showCombinedCount then
        stackCount = ZO_ITEM_TOOLTIP_INVENTORY_AND_BANK_AND_CRAFTBAG_TITLE_COUNT
    else
        if bagId == BAG_BANK then
            stackCount = ZO_ITEM_TOOLTIP_BANK_TITLE_COUNT
        elseif bagId == BAG_BACKPACK then
            stackCount = ZO_ITEM_TOOLTIP_INVENTORY_TITLE_COUNT
        elseif bagId == BAG_VIRTUAL then
            showBankCount = ZO_ITEM_TOOLTIP_HIDE_BANK_BODY_COUNT
            showCraftBagCount = ZO_ITEM_TOOLTIP_HIDE_CRAFTBAG_BODY_COUNT
            stackCount = ZO_ITEM_TOOLTIP_CRAFTBAG_TITLE_COUNT
        elseif equipped then
            if slotIndex == EQUIP_SLOT_POISON or slotIndex == EQUIP_SLOT_BACKUP_POISON then
                stackCount = select(2, GetItemInfo(BAG_WORN, slotIndex))
            else
                stackCount = 1
            end
        end
    end

    local tradeBoPData
    if IsItemBoPAndTradeable(bagId, slotIndex) then
        tradeBoPData =
        {
            timeRemaining = GetItemBoPTimeRemainingSeconds(bagId, slotIndex),
            namesString = GetItemBoPTradeableDisplayNamesString(bagId, slotIndex),
        }
    end
    return self:LayoutItemWithStackCount(itemLink, equipped, GetItemCreatorName(bagId, slotIndex), nil, enchantMode, nil, stackCount, equipSlot, showPlayerLocked, tradeBoPData)
end

function ZO_Tooltip:LayoutTradeItem(who, tradeIndex)
    local itemLink = GetTradeItemLink(who, tradeIndex, LINK_STYLE_DEFAULT)
    local equipped = false
    local name, icon, stack, quality, creator, sellPrice, meetsUsageRequirement, equipType, itemStyle = GetTradeItemInfo(who, tradeIndex)
    local tradeBoPData
    if IsTradeItemBoPAndTradeable(who, tradeIndex) then
        tradeBoPData =
        {
            timeRemaining = GetTradeItemBoPTimeRemainingSeconds(who, tradeIndex),
            namesString = GetTradeItemBoPTradeableDisplayNamesString(who, tradeIndex),
        }
    end
    return self:LayoutItemWithStackCount(itemLink, equipped, creator, nil, nil, nil, stack, EQUIP_SLOT_NONE, DONT_SHOW_PLAYER_LOCKED, tradeBoPData)
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
    local topSubsection = topSection:AcquireSection(self:GetStyle("topSubsection"))
    topSection:AddSectionEvenIfEmpty(topSubsection)
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
                local newPercent = GetCriticalStrikeChance(valueToShow)
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

function ZO_Tooltip:LayoutCurrencies()
    local currencySection = self:AcquireSection(self:GetStyle("currencySection"))
    for type, info in pairs(ZO_CURRENCY_INFO_TABLE) do
        local statValuePair = currencySection:AcquireStatValuePair(self:GetStyle("currencyStatValuePair"))
        statValuePair:SetStat(info.name, self:GetStyle("currencyStatValuePairStat"))
        local valueString = zo_strformat(SI_GAMEPAD_TOOLTIP_ITEM_VALUE_FORMAT, ZO_CommaDelimitNumber(GetCarriedCurrencyAmount(type)), ZO_Currency_GetPlatformFormattedCurrencyIcon(type))
        statValuePair:SetValue(valueString, self:GetStyle("currencyStatValuePairValue"))
        currencySection:AddStatValuePair(statValuePair)
    end
    self:AddSection(currencySection)
end