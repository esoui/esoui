local FORCE_FULL_DURABILITY = true
local DONT_FORCE_FULL_DURABILITY = false
local NOT_EQUIPPED = false
local NO_CREATOR_NAME = nil
local DONT_SHOW_PLAYER_LOCKED = false
local NO_PREVIEW_VALUE = nil
local NO_ITEM_NAME = nil
local NO_TRADE_BOP_DATA = nil

local ITEM_MYTHIC_BORDER_FILE = "EsoUI/Art/Tooltips/Gamepad/GP_UI-Border_Mythic_64px.dds"
local ITEM_MYTHIC_BORDER_RED_FILE = "EsoUI/Art/Tooltips/Gamepad/GP_UI-Border_Mythic_RED_64px.dds"
local ITEM_MYTHIC_FILE_WIDTH = 512
local ITEM_MYTHIC_FILE_HEIGHT = 64

ZO_ENCHANT_DIFF_ADD = "add"
ZO_ENCHANT_DIFF_REMOVE = "remove"
ZO_ENCHANT_DIFF_NONE = "none"

ZO_ITEM_TOOLTIP_INVENTORY_TITLE_COUNT = "inventory"
ZO_ITEM_TOOLTIP_BANK_TITLE_COUNT = "bank"
ZO_ITEM_TOOLTIP_INVENTORY_AND_BANK_TITLE_COUNT = "inventoryAndBank"
ZO_ITEM_TOOLTIP_CRAFTBAG_TITLE_COUNT = "craftbag"
ZO_ITEM_TOOLTIP_INVENTORY_AND_BANK_AND_CRAFTBAG_TITLE_COUNT = "inventoryAndBankAndCraftbag"
ZO_ITEM_TOOLTIP_HOUSE_BANKS_TITLE_COUNT = "houseBanks"

--Section Generators

function ZO_Tooltip:AddItemTitle(itemLink, name)
    name = name or GetItemLinkName(itemLink)
    local displayQuality = GetItemLinkDisplayQuality(itemLink)
    local qualityStyle = ZO_TooltipStyles_GetItemQualityStyle(displayQuality)
    self:AddLine(zo_strformat(SI_TOOLTIP_ITEM_NAME, name), qualityStyle, self:GetStyle("title"))
end

function ZO_Tooltip:AddTypeSlotUniqueLine(itemLink, itemType, section, text1, text2, text3)
    if not text1 then
        return
    end

    local unique = IsItemLinkUnique(itemLink)
    local uniqueEquipped = IsItemLinkUniqueEquipped(itemLink)

    if unique then
        section:AddLine(GetString(SI_ITEM_FORMAT_STR_UNIQUE))
    elseif uniqueEquipped then
        section:AddLine(GetString(SI_ITEM_FORMAT_STR_UNIQUE_EQUIPPED))
    end

    if GetItemLinkActorCategory(itemLink) == GAMEPLAY_ACTOR_CATEGORY_COMPANION then
        section:AddLine(GetString(SI_ITEM_FORMAT_STR_COMPANION))
    end

    local lineText
    local itemStyle = GetItemLinkItemStyle(itemLink)
    local showInTooltip = GetItemLinkShowItemStyleInTooltip(itemLink)
    if itemType == ITEMTYPE_ARMOR then
        local armorType = GetItemLinkArmorType(itemLink)
        if text2 and armorType ~= ARMORTYPE_NONE then
            if showInTooltip and itemStyle > 0 then
                lineText = zo_strformat(SI_ITEM_FORMAT_STR_TEXT1_TEXT2_ITEMSTYLE, text1, text2, GetItemStyleName(itemStyle))
            else
                lineText = zo_strformat(SI_ITEM_FORMAT_STR_TEXT1_TEXT2, text1, text2)
            end
        end
    elseif text2 then
        if showInTooltip and itemStyle > 0 then
            lineText = zo_strformat(SI_ITEM_FORMAT_STR_TEXT1_TEXT2_ITEMSTYLE, text1, text2, GetItemStyleName(itemStyle))
        elseif text3 then
            lineText = zo_strformat(SI_ITEM_FORMAT_STR_TEXT1_TEXT2_ITEMSTYLE, text1, text2, text3)
        else
            lineText = zo_strformat(SI_ITEM_FORMAT_STR_TEXT1_TEXT2, text1, text2)
        end
    end

    if not lineText then
        lineText = zo_strformat(SI_ITEM_FORMAT_STR_TEXT1, text1)
    end

    section:AddLine(lineText)
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
        local itemTypeText = GetString("SI_ITEMTYPE", itemType)
        local furnitureDataId = GetItemLinkFurnitureDataId(itemLink)
        local categoryId, subcategoryId = GetFurnitureDataCategoryInfo(furnitureDataId)
        local furnitureCategoryText = GetFurnitureCategoryName(categoryId)
        local furnitureSubcategoryText = GetFurnitureCategoryName(subcategoryId)
        if furnitureSubcategoryText == "" then
            furnitureSubcategoryText = nil
        end
        self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, itemTypeText, furnitureCategoryText, furnitureSubcategoryText)
    elseif(itemType ~= ITEMTYPE_NONE and equipType ~= EQUIP_TYPE_INVALID) then
        local weaponType = GetItemLinkWeaponType(itemLink)
        if itemType == ITEMTYPE_ARMOR and weaponType == WEAPONTYPE_NONE then
            local armorType = GetItemLinkArmorType(itemLink)
            self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, GetString("SI_EQUIPTYPE", equipType), GetString("SI_ARMORTYPE", armorType))
        elseif weaponType ~= WEAPONTYPE_NONE then
            self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, GetString("SI_WEAPONTYPE", weaponType), GetString("SI_EQUIPTYPE", equipType))
        elseif itemType == ITEMTYPE_POISON or itemType == ITEMTYPE_DISGUISE then
            self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, specializedItemTypeText)
        end
    elseif(itemType == ITEMTYPE_LURE and IsItemLinkConsumable(itemLink)) then
        self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, GetString(SI_ITEM_SUB_TYPE_BAIT))
    elseif(GetItemLinkBookTitle(itemLink)) then
        local itemTypeText = (specializedItemType ~= SPECIALIZED_ITEMTYPE_NONE) and specializedItemTypeText or GetString(SI_ITEM_SUB_TYPE_BOOK)
        self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, itemTypeText)
    elseif DoesItemLinkStartQuest(itemLink) then
        self:AddTypeSlotUniqueLine(itemLink, itemType, topSection, GetString(SI_ITEM_FORMAT_STR_QUEST_STARTER_ITEM))
    elseif DoesItemLinkFinishQuest(itemLink) then
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
        local isBound = IsItemLinkBound(itemLink)
        if isBound and bindType == BIND_TYPE_ON_PICKUP_BACKPACK then
            boundLabel = GetString(SI_ITEM_FORMAT_STR_BACKPACK_BOUND)
        elseif isBound then
            boundLabel = GetString(SI_ITEM_FORMAT_STR_BOUND)
        elseif bindType ~= BIND_TYPE_NONE and bindType ~= BIND_TYPE_UNSET then
            boundLabel = GetString("SI_BINDTYPE", bindType)
        end
    end

    if showPlayerLocked then
        local lineText
        if boundLabel then
            lineText = zo_iconTextFormat("EsoUI/Art/Tooltips/icon_lock.dds", 24, 24, boundLabel)
        else
            lineText = zo_iconFormat("EsoUI/Art/Tooltips/icon_lock.dds", 24, 24)
        end
        topSubsection:AddLine(lineText, self:GetStyle("bind"))
    elseif boundLabel then
        topSubsection:AddLine(boundLabel, self:GetStyle("bind"))
    end

    -- Item Set Collection pieces
    if IsItemLinkReconstructed(itemLink) then
        topSubsection:AddLine(GetString(SI_ITEM_FORMAT_STR_SET_COLLECTION_PIECE_RECONSTRUCTED), self:GetStyle("itemSetCollection"))
    else
        if IsItemLinkSetCollectionPiece(itemLink) then
            local itemId = GetItemLinkItemId(itemLink)
            if IsItemSetCollectionPieceUnlocked(itemId) then
                topSubsection:AddLine(GetString(SI_ITEM_FORMAT_STR_SET_COLLECTION_PIECE_UNLOCKED), self:GetStyle("itemSetCollection"))
            else
                topSubsection:AddLine(GetString(SI_ITEM_FORMAT_STR_SET_COLLECTION_PIECE_LOCKED), self:GetStyle("itemSetCollection"))
            end
        end
    end

    -- Stolen
    if IsItemLinkStolen(itemLink) then
        topSubsection:AddLine(zo_iconTextFormat("EsoUI/Art/Inventory/inventory_stolenItem_icon.dds", 24, 24, GetString(SI_GAMEPAD_ITEM_STOLEN_LABEL)), self:GetStyle("stolen"))
    end

    --Item counts
    local bagCount, bankCount, craftBagCount, houseBanksCount = GetItemLinkStacks(itemLink)
    if bagCount > 0 then
        topSubsection:AddLine(zo_iconTextFormat("EsoUI/Art/Tooltips/icon_bag.dds", 24, 24, bagCount))
    end

    if bankCount > 0 then
        topSubsection:AddLine(zo_iconTextFormat("EsoUI/Art/Tooltips/icon_bank.dds", 24, 24, bankCount))
    end

    if craftBagCount > 0 then
        topSubsection:AddLine(zo_iconTextFormat("EsoUI/Art/Tooltips/icon_craft_bag.dds", 24, 24, craftBagCount))
    end

    if houseBanksCount > 0 then
        topSubsection:AddLine(zo_iconTextFormat("EsoUI/Art/Tooltips/icon_house_bank.dds", 24, 24, houseBanksCount))
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
                championStatValuePair:SetStat(zo_iconTextFormatNoSpace(ZO_GetGamepadChampionPointsIcon(), 32, 32, GetString(SI_ITEM_FORMAT_STR_CHAMPION)), self:GetStyle("statValuePairStat"))
                local failedStyle = requiredChampionPoints > GetPlayerChampionPointsEarned() and self:GetStyle("failed") or nil
                championStatValuePair:SetValue(requiredChampionPoints, failedStyle, self:GetStyle("statValuePairValue"))
                statsSection:AddStatValuePair(championStatValuePair)
            end
        end
    end

    self:AddSection(statsSection)
end

function ZO_Tooltip:AddItemSetCollectionText(itemLink)
    local itemSetCollectionSection = self:AcquireSection(self:GetStyle("bodySection"))

    -- Collection Status
    if IsItemLinkSetCollectionPiece(itemLink) then
        local itemId = GetItemLinkItemId(itemLink)
        if not IsItemSetCollectionPieceUnlocked(itemId) then
            itemSetCollectionSection:AddLine(ZO_SUCCEEDED_TEXT:Colorize(GetString(SI_ITEM_FORMAT_STR_ADD_SET_COLLECTION_PIECE)), self:GetStyle("bodyDescription"))
        end
    end

    self:AddSection(itemSetCollectionSection)
end

function ZO_Tooltip:AddArmoryBuilds(bagId, slotIndex)
    local armoryBuildList = { GetItemArmoryBuildList(bagId, slotIndex) }
    if #armoryBuildList > 0 then
        local armoryBuildSection = self:AcquireSection(self:GetStyle("bodySection"))
        local buildListString = ZO_SELECTED_TEXT:Colorize(ZO_GenerateCommaSeparatedListWithoutAnd(armoryBuildList))
        armoryBuildSection:AddLine(zo_strformat(SI_ITEM_TOOLTIP_IN_ARMORY_DESCRIPTION, buildListString), self:GetStyle("bodyDescription"))
        self:AddSection(armoryBuildSection)
    end
end

function ZO_Tooltip:AddItemValue(itemLink)
    local statsSection = self:AcquireSection(self:GetStyle("valueStatsSection"))

    --Value
    local CONSIDER_CONDITION = true
    local value = GetItemLinkValue(itemLink, not CONSIDER_CONDITION)
    if value > 0 then
        local valueString = ZO_CommaDelimitNumber(value)
        local effectiveValue = GetItemLinkValue(itemLink, CONSIDER_CONDITION)
        local currencyIcon = ZO_Currency_GetGamepadFormattedCurrencyIcon(CURT_MONEY)
        local lineText
        if effectiveValue ~= value then
            local effectiveValueString = ZO_CommaDelimitNumber(effectiveValue)
            lineText = zo_strformat(SI_GAMEPAD_TOOLTIP_EFFECTIVE_ITEM_VALUE_FORMAT, effectiveValueString, valueString, currencyIcon)
        else
            lineText = zo_strformat(SI_GAMEPAD_TOOLTIP_ITEM_VALUE_FORMAT, valueString, currencyIcon)
        end

        local function GetValueNarration()
            local IS_UPPER = false
            if effectiveValue ~= value then
                --Always use the plural form of the currency name when narrating effective value
                local IS_PLURAL = false
                local currencyName = GetCurrencyName(CURT_MONEY, IS_PLURAL, IS_UPPER)
                return zo_strformat(SI_GAMEPAD_TOOLTIP_EFFECTIVE_ITEM_VALUE_NARRATION_FORMAT, ZO_CommaDelimitNumber(effectiveValue), valueString, currencyName)
            else
                local currencyName = GetCurrencyName(CURT_MONEY, IsCountSingularForm(value), IS_UPPER)
                return zo_strformat(SI_GAMEPAD_TOOLTIP_ITEM_VALUE_NARRATION_FORMAT, valueString, currencyName)
            end
        end
        statsSection:AddLineWithCustomNarration(lineText, GetValueNarration, self:GetStyle("statValuePairValue"))
    end
    self:AddSection(statsSection)
end

local MIN_CONDITION_OR_CHARGE = 0
local MAX_CONDITION = 100
function ZO_Tooltip:AddConditionBar(itemLink, previewConditionToAdd)
    local condition = GetItemLinkCondition(itemLink)
    self:AddConditionOrChargeBar(itemLink, condition, MAX_CONDITION, previewConditionToAdd, SI_GAMEPAD_TOOLTIP_DURABILITY_NARRATION_FORMAT)
end

function ZO_Tooltip:AddEnchantChargeBar(itemLink, forceFullDurability, previewChargeToAdd)
    local maxCharges = GetItemLinkMaxEnchantCharges(itemLink)
    local charges = forceFullDurability and maxCharges or GetItemLinkNumEnchantCharges(itemLink)
    self:AddConditionOrChargeBar(itemLink, charges, maxCharges, previewChargeToAdd, SI_GAMEPAD_TOOLTIP_ENCHANT_CHARGE_NARRATION_FORMAT)
end

function ZO_Tooltip:AddPoisonInfo(itemLink, equipSlot)
    local hasPoison, poisonCount, poisonHeader, poisonItemLink = GetItemPairedPoisonInfo(equipSlot)
    if hasPoison then
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

function ZO_Tooltip:AddConditionOrChargeBar(itemLink, value, maxValue, previewValueToAdd, narrationFormatter)
    local bar
    if previewValueToAdd then
        bar = self:AcquireItemImprovementStatusBar(itemLink, value, maxValue, previewValueToAdd)
    else
        bar = self:AcquireStatusBar(self:GetStyle("conditionOrChargeBar"))
        bar:SetMinMax(MIN_CONDITION_OR_CHARGE, maxValue)
        bar:SetValue(value)
    end

    local function GetStatusBarNarrationText()
        local percentage = (value / maxValue) * 100
        percentage = string.format("%.2f", percentage)
        return zo_strformat(narrationFormatter, percentage)
    end
    local barSection = self:AcquireSection(self:GetStyle("conditionOrChargeBarSection"))
    barSection:AddStatusBar(bar, GetStatusBarNarrationText)
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
    if hasEnchant then
        enchantSection:AddLine(enchantHeader, self:GetStyle("bodyHeader"))

        if enchantDiffMode == ZO_ENCHANT_DIFF_NONE then
            if IsItemAffectedByPairedPoison(equipSlot) then
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
        text = zo_strformat(SI_ITEM_ABILITY_SCALING_CHAMPION_POINTS_RANGE, zo_iconFormat(ZO_GetGamepadChampionPointsIcon(), 40, 40), minLevel, maxLevel)
    else
        text = zo_strformat(SI_ITEM_ABILITY_SCALING_LEVEL_RANGE, minLevel, maxLevel)
    end
    section:AddLine(text, self:GetStyle("bodyDescription"))
end

function ZO_Tooltip:AddOnUseAbility(itemLink)
    local onUseAbilitySection = self:AcquireSection(self:GetStyle("bodySection"))
    local cooldownRemainingSection = self:AcquireSection(self:GetStyle("bodySection"))
    local hasAbility, abilityHeader, abilityDescription, cooldown, hasScaling, minLevel, maxLevel, isChampionPoints, remainingCooldown = GetItemLinkOnUseAbilityInfo(itemLink)
    if hasAbility then
        if abilityHeader ~= "" then
            onUseAbilitySection:AddLine(zo_strformat(SI_ABILITY_TOOLTIP_DESCRIPTION_HEADER, abilityHeader), self:GetStyle("bodyHeader"))
        end
        if abilityDescription ~= "" then
            if cooldown == 0 then
                onUseAbilitySection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_ON_USE, abilityDescription), self:GetStyle("bodyDescription"))
            else
                local cooldownString = ZO_FormatTimeMilliseconds(cooldown, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL_HIDE_ZEROES, TIME_FORMAT_PRECISION_SECONDS)
                onUseAbilitySection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_ON_USE_COOLDOWN, abilityDescription, cooldownString), self:GetStyle("bodyDescription"))
            end

            if hasScaling then
                self:AddItemAbilityScalingRange(onUseAbilitySection, minLevel, maxLevel, isChampionPoints)
            end

            if cooldown > ZO_ONE_MINUTE_IN_MILLISECONDS and remainingCooldown > 0 then
                if remainingCooldown < ZO_ONE_MINUTE_IN_MILLISECONDS then
                    cooldownRemainingSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_ON_USE_REMAINING_COOLDOWN, GetString(SI_STR_TIME_LESS_THAN_MINUTE_SHORT)), self:GetStyle("bodyDescription"))
                else
                    local formattedRemainingCooldown = ZO_FormatTimeMilliseconds(remainingCooldown, TIME_FORMAT_STYLE_SHOW_LARGEST_TWO_UNITS, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
                    cooldownRemainingSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_ON_USE_REMAINING_COOLDOWN, formattedRemainingCooldown), self:GetStyle("bodyDescription"))
                end
            end
        end
    else
        local traitAbilities = {}
        local maxCooldown = 0
        for i = 1, GetMaxTraits() do
            local hasTraitAbility, traitAbilityDescription, traitCooldown, traitHasScaling, traitMinLevel, traitMaxLevel, traitIsChampionPoints = GetItemLinkTraitOnUseAbilityInfo(itemLink, i)
            if hasTraitAbility then
                table.insert(traitAbilities,
                {
                    description = traitAbilityDescription,
                    hasScaling = traitHasScaling,
                    minLevel = traitMinLevel,
                    maxLevel = traitMaxLevel,
                    isChampionPoints = traitIsChampionPoints,
                })
                if traitCooldown > maxCooldown then
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
                    local cooldownString = ZO_FormatTimeMilliseconds(maxCooldown, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL_HIDE_ZEROES, TIME_FORMAT_PRECISION_SECONDS)
                    text = zo_strformat(SI_ITEM_FORMAT_STR_ON_USE_COOLDOWN, traitAbility.description, cooldownString)
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
    self:AddSection(cooldownRemainingSection)
end

function ZO_Tooltip:AddTrait(itemLink, extraData)
    if not (extraData and extraData.hideTrait) then
        local traitType, traitDescription = GetItemLinkTraitInfo(itemLink)
        if traitType ~= ITEM_TRAIT_TYPE_NONE and traitDescription ~= "" then
            local traitName = GetString("SI_ITEMTRAITTYPE", traitType)
            if traitName ~= "" then
                local traitSection = self:AcquireSection(self:GetStyle("bodySection"))
                local traitInformation = GetItemTraitInformationFromItemLink(itemLink)
                local traitInformationIconPath = ZO_GetPlatformTraitInformationIcon(traitInformation)

                local formattedTraitName
                if traitInformationIconPath then
                    formattedTraitName = zo_strformat(SI_ITEM_FORMAT_STR_ITEM_TRAIT_WITH_ICON_HEADER, zo_iconFormat(traitInformationIconPath, 32, 32), traitName)
                else
                    formattedTraitName = zo_strformat(SI_ITEM_FORMAT_STR_ITEM_TRAIT_HEADER, traitName)
                end

                local additionalTooltipStyle
                if extraData and extraData.showTraitAsNew then
                    additionalTooltipStyle = self:GetStyle("succeeded")
                end

                traitSection:AddLine(formattedTraitName, self:GetStyle("bodyHeader"), additionalTooltipStyle)
                traitSection:AddLine(traitDescription, self:GetStyle("bodyDescription"), additionalTooltipStyle)
                self:AddSection(traitSection)
            end
        end
    end
end

function ZO_Tooltip:AddSetRestrictions(itemSetId)
    local hasRestrictions, passesRestrictions, allowedNamesString = GetItemSetClassRestrictions(itemSetId)
    if hasRestrictions then
        local restrictionsSection = self:AcquireSection(self:GetStyle("collectionsRestrictionsSection"))
        local statValuePair = restrictionsSection:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
        statValuePair:SetStat(GetString("SI_COLLECTIBLERESTRICTIONTYPE", COLLECTIBLE_RESTRICTION_TYPE_CLASS), self:GetStyle("statValuePairStat"))
        if passesRestrictions then
            statValuePair:SetValue(allowedNamesString, self:GetStyle("statValuePairValue"))
        else
            statValuePair:SetValue(allowedNamesString, self:GetStyle("failed"), self:GetStyle("statValuePairValue"))
        end
        restrictionsSection:AddStatValuePair(statValuePair)

        if not passesRestrictions then
            restrictionsSection:AddLine(GetString(SI_COLLECTIBLE_TOOLTIP_NOT_USABLE_BY_CHARACTER), self:GetStyle("bodyDescription"), self:GetStyle("failed"))
        end
        self:AddSection(restrictionsSection)
    end
end

function ZO_Tooltip:AddSet(itemLink, equipped)
    local hasSet, setName, numBonuses, numNormalEquipped, maxEquipped, setId, numPerfectedEquipped = GetItemLinkSetInfo(itemLink)
    if hasSet then
        local totalEquipped = zo_min(numNormalEquipped + numPerfectedEquipped, maxEquipped)
        local isPerfectedSet = GetItemSetUnperfectedSetId(setId) > 0
        local setSection = self:AcquireSection(self:GetStyle("bodySection"))
        local setSectionStyle = "bodyHeader"
        local bonusSectionStyle = "activeBonus"
        local itemSetSuppressionType, refId = GetItemSetSuppressionInfo(setId)
        local suppressionName = GetItemSetSuppressionName(setId)
        if setId ~= refId and itemSetSuppressionType ~= ITEM_SET_SUPPRESSION_TYPE_NONE then
            setSectionStyle = "itemSetSuppressedSection"
            bonusSectionStyle = "itemSetSuppressedDescription"
        end
        if isPerfectedSet then
            setSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_PERFECTED_SET_NAME, setName, totalEquipped, maxEquipped, numPerfectedEquipped), self:GetStyle(setSectionStyle))
        else
            setSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_SET_NAME, setName, totalEquipped, maxEquipped), self:GetStyle(setSectionStyle))
        end
        for bonusIndex = 1, numBonuses do
            local numRequired, bonusDescription, isPerfectedBonus = GetItemLinkSetBonusInfo(itemLink, equipped, bonusIndex)
            local numRelevantEquipped = isPerfectedBonus and numPerfectedEquipped or totalEquipped
            if numRelevantEquipped >= numRequired then
                setSection:AddLine(bonusDescription, self:GetStyle(bonusSectionStyle), self:GetStyle("bodyDescription"))
            else
                setSection:AddLine(bonusDescription, self:GetStyle("inactiveBonus"), self:GetStyle("bodyDescription"))
            end
        end

        if setId ~= refId and itemSetSuppressionType ~= ITEM_SET_SUPPRESSION_TYPE_NONE then
            setSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_DISABLED_BY, suppressionName), self:GetStyle(setSectionStyle))
        end
        self:AddSection(setSection)
        self:AddSetRestrictions(setId)
    end
end

function ZO_Tooltip:AddContainerSets(itemLink)
    local numContainerSets = GetItemLinkNumContainerSetIds(itemLink)
    for setIndex = 1, numContainerSets do
        local hasSet, setName, numBonuses, numNormalEquipped, maxEquipped, setId, numPerfectedEquipped = GetItemLinkContainerSetInfo(itemLink, setIndex)
        if hasSet then
            if setIndex > 1 then
                local separatorSection = self:AcquireSection(self:GetStyle("itemSetSeparatorSection"))
                separatorSection:AddTexture(ZO_GAMEPAD_HEADER_DIVIDER_TEXTURE, self:GetStyle("dividerLine"))
                separatorSection:AddLine(GetString(SI_ITEM_FORMAT_STR_SET_OR_SEPARATOR))
                separatorSection:AddTexture(ZO_GAMEPAD_HEADER_DIVIDER_TEXTURE, self:GetStyle("dividerLine"))
                self:AddSection(separatorSection)
            end
            
            local totalEquipped = zo_min(numNormalEquipped + numPerfectedEquipped, maxEquipped)
            local isPerfectedSet = GetItemSetUnperfectedSetId(setId) > 0
            local setSection = self:AcquireSection(self:GetStyle("bodySection"))
            if isPerfectedSet then
                setSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_PERFECTED_SET_NAME, setName, totalEquipped, maxEquipped, numPerfectedEquipped), self:GetStyle("bodyHeader"))
            else
                setSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_SET_NAME, setName, totalEquipped, maxEquipped), self:GetStyle("bodyHeader"))
            end
            for bonusIndex = 1, numBonuses do
                local numRequired, bonusDescription, isPerfectedBonus = GetItemLinkContainerSetBonusInfo(itemLink, setIndex, bonusIndex)
                local numRelevantEquipped = isPerfectedBonus and numPerfectedEquipped or totalEquipped
                if numRelevantEquipped >= numRequired then
                    setSection:AddLine(bonusDescription, self:GetStyle("activeBonus"), self:GetStyle("bodyDescription"))
                else
                    setSection:AddLine(bonusDescription, self:GetStyle("inactiveBonus"), self:GetStyle("bodyDescription"))
                end
            end
            self:AddSection(setSection)
            self:AddSetRestrictions(setId)
        end
    end
end

function ZO_Tooltip:AddPoisonSystemDescription()
    local poisonSystemDescriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
    poisonSystemDescriptionSection:AddLine(GetString(SI_POISON_SYSTEM_INFO), self:GetStyle("flavorText"))
    self:AddSection(poisonSystemDescriptionSection)
end

function ZO_Tooltip:AddFlavorText(itemLink)
    local flavorText = GetItemLinkFlavorText(itemLink)
    if flavorText ~= "" then
        local flavorSection = self:AcquireSection(self:GetStyle("bodySection"))
        flavorSection:AddLine(flavorText, self:GetStyle("flavorText"))
        self:AddSection(flavorSection)
    end
end

function ZO_Tooltip:AddPrioritySellText(itemLink)
    if IsItemLinkPrioritySell(itemLink) then
        local prioritySellSection = self:AcquireSection(self:GetStyle("bodySection"))
        if IsItemLinkStolen(itemLink) then
            prioritySellSection:AddLine(GetString(SI_ITEM_FORMAT_STR_PRIORITY_FENCE), self:GetStyle("prioritySellText"))
        else
            prioritySellSection:AddLine(GetString(SI_ITEM_FORMAT_STR_PRIORITY_SELL), self:GetStyle("prioritySellText"))
        end
        self:AddSection(prioritySellSection)
    end
end

function ZO_Tooltip:GetRequiredCollectibleText(collectibleId)
    if collectibleId ~= 0 then
        -- Will either be an override collectible, the passed in id, or 0 if it cannot be purchased
        local purchasableCollectibleId = GetPurchasableCollectibleIdForCollectible(collectibleId)
        local relevantCollectible = (purchasableCollectibleId == 0) and collectibleId or purchasableCollectibleId
        local collectibleName = GetCollectibleName(relevantCollectible)
        if collectibleName ~= "" then
            local formatterStringId
            local collectibleCategory = GetCollectibleCategoryType(relevantCollectible)
            if collectibleCategory == COLLECTIBLE_CATEGORY_TYPE_CHAPTER then
                formatterStringId = SI_COLLECTIBLE_REQUIRED_TO_USE_ITEM_UPGRADE
            elseif IsCollectiblePurchasable(relevantCollectible) then
                formatterStringId = SI_COLLECTIBLE_REQUIRED_TO_USE_ITEM_CROWN_STORE
            else
                formatterStringId = SI_COLLECTIBLE_REQUIRED_TO_USE_ITEM
            end
            return zo_strformat(formatterStringId, collectibleName, GetCollectibleCategoryNameByCollectibleId(relevantCollectible))
        end
    end

    return ""
end

function ZO_Tooltip:AddItemRequiresCollectibleText(itemLink)
    local collectibleId = GetItemLinkTooltipRequiresCollectibleId(itemLink)
    if collectibleId ~= 0 then
        local text = self:GetRequiredCollectibleText(collectibleId)
        if text ~= "" then
            local section = self:AcquireSection(self:GetStyle("bodySection"))
            local colorStyle = IsCollectibleUnlocked(collectibleId) and self:GetStyle("succeeded") or self:GetStyle("failed")
            section:AddLine(text, self:GetStyle("bodyDescription"), colorStyle)
            self:AddSection(section)
        end
    end
end

function ZO_Tooltip:AddItemCombinationText(itemLink)
    local description = GetItemLinkCombinationDescription(itemLink)
    if description ~= "" then
        local combinationSection = self:AcquireSection(self:GetStyle("bodySection"))
        combinationSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_COMBINATION, description), self:GetStyle("bodyDescription"))
        self:AddSection(combinationSection)
    end
end

function ZO_Tooltip:AddCollectibleOwnedText(itemLink)
    local grantedCollectibleId = GetItemLinkContainerCollectibleId(itemLink)
    if grantedCollectibleId > 0 then
        local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
        local collectibleCategory = GetCollectibleCategoryType(grantedCollectibleId)
        if IsCollectibleOwnedByDefId(grantedCollectibleId) then
            bodySection:AddLine(GetString(SI_ITEM_FORMAT_STR_ALREADY_IN_COLLECTION), self:GetStyle("bodyDescription"))
        elseif collectibleCategory == COLLECTIBLE_CATEGORY_TYPE_COMBINATION_FRAGMENT and not CanCombinationFragmentBeUnlocked(grantedCollectibleId) then
            bodySection:AddLine(GetString(SI_ITEM_FORMAT_STR_ALREADY_OWN_COMBINATION_RESULT), self:GetStyle("bodyDescription"), self:GetStyle("failed"))
        else
            bodySection:AddLine(ZO_SUCCEEDED_TEXT:Colorize(GetString(SI_ITEM_FORMAT_STR_ADD_TO_COLLECTION)), self:GetStyle("bodyDescription"))
        end
        self:AddSection(bodySection)
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
    if levelsDescription ~= "" then
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
                table.sort(itemTagStrings[i])
                itemTagsSection:AddLine(table.concat(itemTagStrings[i], GetString(SI_LIST_COMMA_SEPARATOR)), self:GetStyle("itemTagDescription"))
                self:AddSection(itemTagsSection)
            end
        end
    end
end

--Layout Functions
function ZO_Tooltip:UpdateGamepadBorderDisplay(itemLink)
    -- Self is an internal scroll tooltip control, but the border we want to set is on the
    -- outer container control. That container control has been reference on the tooltip control self.
    -- Set Mythic Border to show or hide depending on if the item is Mythic
    if self.gamepadTooltipContainerBorderControl then
        local borderFile
        local isBorderHidden = GetItemLinkDisplayQuality(itemLink) ~= ITEM_DISPLAY_QUALITY_MYTHIC_OVERRIDE
        if IsItemLinkStolen(itemLink) then
            borderFile = ITEM_MYTHIC_BORDER_RED_FILE
        else
            borderFile = ITEM_MYTHIC_BORDER_FILE
        end
        self.gamepadTooltipContainerBorderControl:SetEdgeTexture(borderFile, ITEM_MYTHIC_FILE_WIDTH, ITEM_MYTHIC_FILE_HEIGHT)
        self.gamepadTooltipContainerBorderControl:SetHidden(isBorderHidden)
    end
end

function ZO_Tooltip:LayoutGenericItem(itemLink, equipped, creatorName, forceFullDurability, previewValueToAdd, itemName, equipSlot, showPlayerLocked, tradeBoPData, extraData)
    self:AddTopSection(itemLink, showPlayerLocked, tradeBoPData)
    self:AddItemTitle(itemLink, itemName)
    self:AddBaseStats(itemLink)
    if DoesItemLinkHaveArmorDecay(itemLink) then
        self:AddConditionBar(itemLink, previewValueToAdd)
    elseif equipped and IsItemAffectedByPairedPoison(equipSlot) then
        self:AddPoisonInfo(itemLink, equipSlot)
    elseif DoesItemLinkHaveEnchantCharges(itemLink) then
        self:AddEnchantChargeBar(itemLink, forceFullDurability, previewValueToAdd)
    end

    self:UpdateGamepadBorderDisplay(itemLink)

    local enchantDiffMode
    if extraData then
        enchantDiffMode = extraData.enchantDiffMode
    end
    self:AddEnchant(itemLink, enchantDiffMode, equipSlot)
    self:AddOnUseAbility(itemLink)
    self:AddTrait(itemLink, extraData)
    if IsItemLinkContainer(itemLink) then
        self:AddContainerSets(itemLink)
    else
        self:AddSet(itemLink, equipped)
    end
    if GetItemLinkItemType(itemLink) == ITEMTYPE_POISON then
        self:AddPoisonSystemDescription()
    end
    self:AddItemCombinationText(itemLink)
    self:AddFlavorText(itemLink)
    self:AddPrioritySellText(itemLink)
    self:AddItemRequiresCollectibleText(itemLink)
    self:AddCollectibleOwnedText(itemLink)
    -- We don't want crafted furniture to show who made it, since it will get cleared once placed in a house
    -- TODO: If we implement saving the creator name, add back in LayoutItemCreator call (ESO-495280)
    local isFurniture = IsItemLinkPlaceableFurniture(itemLink)
    if not isFurniture then
        self:AddCreator(itemLink, creatorName)
    end
    self:AddItemTags(itemLink)
    if isFurniture then
        self:LayoutFurnishingLimitType(itemLink)

        if IsItemLinkConsolidatedSmithingStation(itemLink) then
            self:LayoutConsolidatedStationUnlockProgress(itemLink)
        end
    end
    self:LayoutTradeBoPInfo(tradeBoPData)
    self:AddItemSetCollectionText(itemLink)
    if extraData and extraData.bagId ~= nil and extraData.slotIndex ~= nil then
        self:AddArmoryBuilds(extraData.bagId, extraData.slotIndex)
    end
    self:AddItemValue(itemLink)
    self:AddItemForcedNotDeconstructable(itemLink)
end

function ZO_Tooltip:LayoutVendorTrash(itemLink, itemName, extraData)
    self:AddItemTitle(itemLink, itemName)
    self:AddBaseStats(itemLink)
    self:AddFlavorText(itemLink)
    self:AddPrioritySellText(itemLink)
    self:AddItemTags(itemLink)
    self:AddItemValue(itemLink)
end

function ZO_Tooltip:LayoutBooster(itemLink, itemName, extraData)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)

    local boosterDescriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
    local toDisplayQuality = GetItemLinkDisplayQuality(itemLink)
    local fromDisplayQuality = zo_max(ITEM_DISPLAY_QUALITY_TRASH, toDisplayQuality - 1)
    local toQualityText = GetString("SI_ITEMQUALITY", toDisplayQuality)
    local fromQualityText = GetString("SI_ITEMQUALITY", fromDisplayQuality)
    toQualityText = GetItemQualityColor(toDisplayQuality):Colorize(toQualityText)
    fromQualityText = GetItemQualityColor(fromDisplayQuality):Colorize(fromQualityText)
    boosterDescriptionSection:AddLine(zo_strformat(SI_ENCHANTMENT_BOOSTER_DESCRIPTION, fromQualityText, toQualityText), self:GetStyle("bodyDescription"))
    self:AddSection(boosterDescriptionSection)
    self:AddPrioritySellText(itemLink)
    self:AddItemTags(itemLink)
end

do
    local FORMATTED_CHAMPION_RANK_ICON = zo_iconFormat(ZO_GetGamepadChampionPointsIcon(), 40, 40)
    function ZO_Tooltip:LayoutInlineGlyph(itemLink, itemName)
        self:AddItemTitle(itemLink, itemName)
        self:AddEnchant(itemLink)

        local minLevel, minChampionPoints = GetItemLinkGlyphMinLevels(itemLink)
        if minLevel or minChampionPoints then
            local requirementsSection = self:AcquireSection(self:GetStyle("bodySection"))
            if minChampionPoints then
                requirementsSection:AddLine(zo_strformat(SI_ENCHANTING_GLYPH_REQUIRED_SINGLE_CHAMPION_POINTS_GAMEPAD, FORMATTED_CHAMPION_RANK_ICON, minChampionPoints), self:GetStyle("bodyDescription"))
            else
                requirementsSection:AddLine(zo_strformat(SI_ENCHANTING_GLYPH_REQUIRED_SINGLE_LEVEL, minLevel), self:GetStyle("bodyDescription"))
            end
            self:AddSection(requirementsSection)
        end

        self:AddFlavorText(itemLink)

        self:UpdateGamepadBorderDisplay(itemLink)
    end
end

function ZO_Tooltip:LayoutGlyph(itemLink, creatorName, itemName, tradeBoPData, extraData)
    self:AddTopSection(itemLink, DONT_SHOW_PLAYER_LOCKED, tradeBoPData)
    self:LayoutInlineGlyph(itemLink, itemName)
    self:AddCreator(itemLink, creatorName)
    self:AddPrioritySellText(itemLink)
    self:AddItemTags(itemLink)
    self:LayoutTradeBoPInfo(tradeBoPData)
end

function ZO_Tooltip:LayoutSiege(itemLink, itemName, tradeBoPData, extraData)
    self:AddTopSection(itemLink, DONT_SHOW_PLAYER_LOCKED, tradeBoPData)
    self:AddItemTitle(itemLink, itemName)
    local maxHP = GetItemLinkSiegeMaxHP(itemLink)
    if maxHP > 0 then
        local statsSection = self:AcquireSection(self:GetStyle("statsSection"))
        local statValuePair = statsSection:AcquireStatValuePair()
        statValuePair:SetStat(GetString(SI_SIEGE_TOOLTIP_TOUGHNESS), self:GetStyle("statValuePairStat"))
        statValuePair:SetValue(zo_strformat(SI_SIEGE_TOOLTIP_TOUGHNESS_FORMAT, maxHP), self:GetStyle("statValuePairValue"))
        statsSection:AddStatValuePair(statValuePair)
        self:AddSection(statsSection)
    end
    self:AddFlavorText(itemLink)
    self:AddPrioritySellText(itemLink)
    self:AddItemTags(itemLink)
    self:LayoutTradeBoPInfo(tradeBoPData)
end

function ZO_Tooltip:LayoutTool(itemLink, itemName, tradeBoPData, extraData)
    self:AddTopSection(itemLink, DONT_SHOW_PLAYER_LOCKED, tradeBoPData)
    self:AddItemTitle(itemLink, itemName)
    self:AddBaseStats(itemLink)
    self:AddFlavorText(itemLink)
    self:AddPrioritySellText(itemLink)
    self:AddItemTags(itemLink)
    self:LayoutTradeBoPInfo(tradeBoPData)
    self:AddItemValue(itemLink)
end

function ZO_Tooltip:LayoutSoulGem(itemLink, itemName, extraData)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)
    self:AddBaseStats(itemLink)
    self:AddFlavorText(itemLink)
    self:AddPrioritySellText(itemLink)
    self:AddItemTags(itemLink)
    self:AddItemValue(itemLink)
end

function ZO_Tooltip:LayoutAvARepair(itemLink, itemName, extraData)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)
    self:AddFlavorText(itemLink)
    self:AddPrioritySellText(itemLink)
    self:AddItemTags(itemLink)
end

do
    local function AddDyeSwatchSection(dyeId, section, entryStyle, swatchStyle)
        local entrySection = section:AcquireSection()
        local dyeName, _, _, _, _, r, g, b = GetDyeInfoById(dyeId)
        entrySection:AddColorAndTextSwatch(r, g, b, 1, dyeName, swatchStyle)
        section:AddSection(entrySection)
    end

    function ZO_Tooltip:LayoutDyeStamp(itemLink, itemName, extraData)
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
        self:AddPrioritySellText(itemLink)
        self:AddItemTags(itemLink)

        local dyeStampId = GetItemLinkDyeStampId(itemLink)
        local errorSection = self:AcquireSection(self:GetStyle("bodySection"))
        if not IsCharacterPreviewingAvailable() then
            errorSection:AddLine(GetString(SI_DYE_STAMP_NOT_USABLE_NOW), self:GetStyle("dyeStampError"))
        elseif onUseType == ITEM_USE_TYPE_ITEM_DYE_STAMP then
            local useResult = CanPlayerUseItemDyeStamp(dyeStampId)
            if useResult == DYE_STAMP_USE_RESULT_NO_VALID_ITEMS then
                errorSection:AddLine(GetString(SI_DYE_STAMP_REQUIRES_EQUIPMENT), self:GetStyle("dyeStampError"))
            elseif useResult == DYE_STAMP_USE_RESULT_ITEMS_HAVE_SAME_DYES then
                errorSection:AddLine(GetString(SI_DYE_STAMP_SAME_DYE_DATA), self:GetStyle("dyeStampError"))
            end
        elseif onUseType == ITEM_USE_TYPE_COSTUME_DYE_STAMP then
            local useResult = CanPlayerUseCostumeDyeStamp(dyeStampId)
            if useResult == DYE_STAMP_USE_RESULT_NO_VALID_COLLECTIBLES then
                errorSection:AddLine(GetString(SI_DYE_STAMP_REQUIRES_COLLECTIBLE), self:GetStyle("dyeStampError"))
            elseif useResult == DYE_STAMP_USE_RESULT_COLLECTIBLES_HAVE_SAME_DYES then
                errorSection:AddLine(GetString(SI_DYE_STAMP_SAME_DYE_DATA), self:GetStyle("dyeStampError"))
            elseif useResult == DYE_STAMP_USE_RESULT_COLLECTIBLES_NOT_ACTIVE then
                errorSection:AddLine(GetString(SI_DYE_STAMP_COLLECTIBLES_HIDDEN), self:GetStyle("dyeStampError"))
            end
        end
        self:AddSection(errorSection)
    end
end

function ZO_Tooltip:LayoutMasterWritItem(itemLink, tradeBoPData, extraData)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink)

    local writDescription = self:AcquireSection(self:GetStyle("bodySection"))
    writDescription:AddLine(GenerateMasterWritBaseText(itemLink), self:GetStyle("bodyDescription"))
    self:AddSection(writDescription)

    local rewardDescription = self:AcquireSection(self:GetStyle("bodySection"))
    rewardDescription:AddLine(GenerateMasterWritRewardText(itemLink), self:GetStyle("bodyDescription"))
    self:AddSection(rewardDescription)

    self:AddFlavorText(itemLink)
    self:AddPrioritySellText(itemLink)
    self:AddItemTags(itemLink)
    self:LayoutTradeBoPInfo(tradeBoPData)
end

function ZO_Tooltip:LayoutCraftedAbilityItem(itemLink, itemName, tradeBoPData)
    -- The functions that make this work are only available in ingame.
    -- If we need to support internalingame, we'll need to refactor
    assert(ZO_IsIngameUI(), "CRAFTED_ABILITY item tooltips are not supported in the Crown Store.")
    local isItemUseTypeCraftedAbilityScript = GetItemLinkItemUseType(itemLink) == ITEM_USE_TYPE_CRAFTED_ABILITY
    local craftedAbilityId = isItemUseTypeCraftedAbilityScript and GetItemLinkItemUseReferenceId(itemLink) or 0
    local craftedAbilityData = SCRIBING_DATA_MANAGER:GetCraftedAbilityData(craftedAbilityId)
    
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)

    if internalassert(craftedAbilityData ~= nil, "Trying to layout tooltip for ItemType CRAFTED_ABILITY but could not get CraftedAbilityData from onUseValue") then
        local description = craftedAbilityData:GetDescription()
        if description ~= "" then
            local descriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
            descriptionSection:AddLine(description, self:GetStyle("bodyDescription"))
            self:AddSection(descriptionSection)
        end

        local skillData = craftedAbilityData:GetSkillData()
        if skillData then
            local skillLineData = skillData:GetSkillLineData()
            local onUseInfo = zo_strformat(SI_ITEM_TOOLTIP_CRAFTED_ABILITY_ON_USE_FORMATTER, craftedAbilityData:GetDisplayName(), skillLineData:GetName())
            local onUseSection = self:AcquireSection(self:GetStyle("bodySection"))
            onUseSection:AddLine(onUseInfo, self:GetStyle("bodyDescription"))
            self:AddSection(onUseSection)
        end
    end

    self:AddFlavorText(itemLink)

    if craftedAbilityData and craftedAbilityData:IsUnlocked() then
        local alreadyKnownSection = self:AcquireSection(self:GetStyle("bodySection"))
        alreadyKnownSection:AddLine(GetString(SI_ITEM_TOOLTIP_CRAFTED_ABILITY_ALREADY_KNOWN), self:GetStyle("bodyDescription"))
        self:AddSection(alreadyKnownSection)
    end

    self:AddPrioritySellText(itemLink)
    self:AddItemTags(itemLink)
    self:LayoutTradeBoPInfo(tradeBoPData)
    self:AddItemValue(itemLink)
end

function ZO_Tooltip:LayoutCraftedAbilityScriptItem(itemLink, itemName, tradeBoPData)
    -- The functions that make this work are only available in ingame.
    -- If we need to support internalingame, we'll need to refactor
    assert(ZO_IsIngameUI(), "CRAFTED_ABILITY_SCRIPT item tooltips are not supported in the Crown Store.")
    local isItemUseTypeCraftedAbilityScript = GetItemLinkItemUseType(itemLink) == ITEM_USE_TYPE_CRAFTED_ABILITY_SCRIPT
    local craftedAbilityScriptId = isItemUseTypeCraftedAbilityScript and GetItemLinkItemUseReferenceId(itemLink) or 0
    local craftedAbilityScriptData = SCRIBING_DATA_MANAGER:GetCraftedAbilityScriptData(craftedAbilityScriptId)
    internalassert(craftedAbilityScriptData ~= nil, "Trying to layout tooltip for ItemType CRAFTED_ABILITY_SCRIPT but could not get CraftedAbilityScriptData from onUseValue")
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)

    if craftedAbilityScriptData then
        local description = craftedAbilityScriptData:GetGeneralDescription()
        if description ~= "" then
            local descriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
            descriptionSection:AddLine(description, self:GetStyle("bodyDescription"))
            self:AddSection(descriptionSection)
        end
        
        local slot = GetString("SI_SCRIBINGSLOT_SHORT", craftedAbilityScriptData:GetScribingSlot())
        local onUseInfo = zo_strformat(SI_ITEM_TOOLTIP_CRAFTED_ABILITY_SCRIPT_ON_USE_FORMATTER, craftedAbilityScriptData:GetDisplayName(), slot)
        local onUseSection = self:AcquireSection(self:GetStyle("bodySection"))
        onUseSection:AddLine(onUseInfo, self:GetStyle("bodyDescription"))
        self:AddSection(onUseSection)
    end

    self:AddFlavorText(itemLink)

    if craftedAbilityScriptData and craftedAbilityScriptData:IsUnlocked() then
        local alreadyKnownSection = self:AcquireSection(self:GetStyle("bodySection"))
        alreadyKnownSection:AddLine(GetString(SI_ITEM_TOOLTIP_CRAFTED_ABILITY_SCRIPT_ALREADY_KNOWN), self:GetStyle("bodyDescription"))
        self:AddSection(alreadyKnownSection)
    end

    self:AddPrioritySellText(itemLink)
    self:AddItemTags(itemLink)
    self:LayoutTradeBoPInfo(tradeBoPData)
    self:AddItemValue(itemLink)
end

function ZO_Tooltip:LayoutBook(itemLink, tradeBoPData)
    self:AddTopSection(itemLink, DONT_SHOW_PLAYER_LOCKED, tradeBoPData)
    self:AddItemTitle(itemLink)
    if IsItemLinkBookPartOfCollection(itemLink) then
        local knownSection = self:AcquireSection(self:GetStyle("bodySection"))
        if IsItemLinkBookKnown(itemLink) then
            knownSection:AddLine(GetString(SI_LORE_LIBRARY_IN_LIBRARY), self:GetStyle("bodyDescription"))
        else
            knownSection:AddLine(ZO_SUCCEEDED_TEXT:Colorize(GetString(SI_LORE_LIBRARY_USE_TO_LEARN)), self:GetStyle("bodyDescription"))
        end
        self:AddSection(knownSection)
    end
    self:AddFlavorText(itemLink)
    self:AddPrioritySellText(itemLink)
    self:AddItemTags(itemLink)
    self:LayoutTradeBoPInfo(tradeBoPData)
end

function ZO_Tooltip:LayoutLure(itemLink, itemName, extraData)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)
    self:AddFlavorText(itemLink)
    self:AddPrioritySellText(itemLink)
    self:AddItemTags(itemLink)
end

function ZO_Tooltip:LayoutQuestStartOrFinishItem(itemLink, itemName, extraData)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink)
    self:AddFlavorText(itemLink)
    self:AddPrioritySellText(itemLink)
    self:AddItemTags(itemLink)
end

function ZO_Tooltip:LayoutProvisionerRecipe(itemLink, itemName, tradeBoPData, extraData)
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
        if quality >= requiredQuality then
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
    if IsItemLinkRecipeKnown(itemLink) then
        useToLearnOrKnownSection:AddLine(GetString(SI_RECIPE_ALREADY_KNOWN), self:GetStyle("bodyDescription"))
    else
        useToLearnOrKnownSection:AddLine(ZO_SUCCEEDED_TEXT:Colorize(GetString(SI_USE_TO_LEARN_RECIPE)), self:GetStyle("bodyDescription"))
    end
    self:AddSection(useToLearnOrKnownSection)
    self:AddPrioritySellText(itemLink)
    self:AddItemTags(itemLink)
    self:LayoutTradeBoPInfo(tradeBoPData)
    self:AddItemValue(itemLink)
end

function ZO_Tooltip:LayoutReagent(itemLink, itemName, extraData)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)

    local traitSection
    for i = 1, GetMaxTraits() do
        local known, name = GetItemLinkReagentTraitInfo(itemLink, i)
        if known ~= nil then
            if not traitSection then
                traitSection = self:AcquireSection(self:GetStyle("bodySection"))
                traitSection:AddLine(GetString(SI_CRAFTING_COMPONENT_TOOLTIP_TRAITS), self:GetStyle("bodyHeader"))
            end
            local displayName
            local knownStyle
            local customNarration
            if known then
                displayName = name
                knownStyle = self:GetStyle("traitKnown")
            else
                displayName = GetString(SI_CRAFTING_COMPONENT_TOOLTIP_UNKNOWN_TRAIT)
                knownStyle = self:GetStyle("traitUnknown")
                customNarration = zo_strformat(SI_NUMBERED_LIST_ENTRY, i, GetString(SI_CRAFTING_UNKNOWN_NAME))
            end

            traitSection:AddLineWithCustomNarration(zo_strformat(SI_NUMBERED_LIST_ENTRY, i, displayName), customNarration, knownStyle, self:GetStyle("bodyDescription"))
        end
    end

    if traitSection then
        self:AddSection(traitSection)
    end
    self:AddPrioritySellText(itemLink)
    self:AddItemTags(itemLink)
end

function ZO_Tooltip:LayoutEnchantingRune(itemLink, itemName, extraData)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)

    local known, name = GetItemLinkEnchantingRuneName(itemLink)
    if known ~= nil then
        local translationSection = self:AcquireSection(self:GetStyle("bodySection"))
        translationSection:AddLine(GetString(SI_ENCHANTING_TRANSLATION_HEADER), self:GetStyle("bodyHeader"))
        if known then
            translationSection:AddLine(zo_strformat(SI_ENCHANTING_TRANSLATION_KNOWN, name), self:GetStyle("bodyDescription"))
        else
            translationSection:AddLine(GetString(SI_ENCHANTING_TRANSLATION_UNKNOWN), self:GetStyle("bodyDescription"))
        end
        self:AddSection(translationSection)
    end

    local runeClassification = GetItemLinkEnchantingRuneClassification(itemLink)
    local requiredRank = GetItemLinkRequiredCraftingSkillRank(itemLink)
    if runeClassification == ENCHANTING_RUNE_POTENCY then
        local requiredRankStyle
        if GetNonCombatBonus(NON_COMBAT_BONUS_ENCHANTING_LEVEL) >= requiredRank then
            requiredRankStyle = self:GetStyle("succeeded")
        else
            requiredRankStyle = self:GetStyle("failed")
        end
        local requirementSection = self:AcquireSection(self:GetStyle("bodySection"))
        requirementSection:AddLine(zo_strformat(SI_ENCHANTING_REQUIRES_POTENCY_IMPROVEMENT, requiredRank), requiredRankStyle, self:GetStyle("bodyDescription"))
        self:AddSection(requirementSection)
    elseif runeClassification == ENCHANTING_RUNE_ASPECT then
        local requiredRankStyle
        if GetNonCombatBonus(NON_COMBAT_BONUS_ENCHANTING_RARITY_LEVEL) >= requiredRank then
            requiredRankStyle = self:GetStyle("succeeded")
        else
            requiredRankStyle = self:GetStyle("failed")
        end
        local requirementSection = self:AcquireSection(self:GetStyle("bodySection"))
        requirementSection:AddLine(zo_strformat(SI_ENCHANTING_REQUIRES_ASPECT_IMPROVEMENT, requiredRank), requiredRankStyle, self:GetStyle("bodyDescription"))
        self:AddSection(requirementSection)
    end
end

function ZO_Tooltip:LayoutAlchemyBase(itemLink, itemName, extraData)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)

    local requiredLevel = GetItemLinkRequiredLevel(itemLink)
    local requiredChampionPoints = GetItemLinkRequiredChampionPoints(itemLink)
    local itemType = GetItemLinkItemType(itemLink)
    local itemTypeString = GetString((itemType == ITEMTYPE_POTION_BASE) and SI_ITEM_FORMAT_STR_POTION or SI_ITEM_FORMAT_STR_POISON)

    if requiredLevel > 0 or requiredChampionPoints > 0 then
        local createsSection = self:AcquireSection(self:GetStyle("bodySection"))
        if requiredChampionPoints > 0 then
            createsSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_CREATES_ALCHEMY_ITEM_OF_CHAMPION_POINTS, requiredChampionPoints, itemTypeString), self:GetStyle("bodyDescription"))
        else
            createsSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_CREATES_ALCHEMY_ITEM_OF_LEVEL, requiredLevel, itemTypeString), self:GetStyle("bodyDescription"))
        end
        self:AddSection(createsSection)
    end

    local requirementSection = self:AcquireSection(self:GetStyle("bodySection"))
    local requirementStyle
    local requiredRank = GetItemLinkRequiredCraftingSkillRank(itemLink)
    if GetNonCombatBonus(NON_COMBAT_BONUS_ALCHEMY_LEVEL) >= requiredRank then
        requirementStyle = self:GetStyle("succeeded")
    else
        requirementStyle = self:GetStyle("failed")
    end
    requirementSection:AddLine(zo_strformat(SI_REQUIRES_ALCHEMY_SOLVENT_PURIFICATION, requiredRank), requirementStyle, self:GetStyle("bodyDescription"))
    self:AddSection(requirementSection)
    self:AddPrioritySellText(itemLink)
    self:AddItemTags(itemLink)
end

function ZO_Tooltip:LayoutIngredient(itemLink, itemName, extraData)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)
    self:AddFlavorText(itemLink)
    self:AddPrioritySellText(itemLink)
    self:AddItemTags(itemLink)
end

function ZO_Tooltip:LayoutStyleMaterial(itemLink, itemName, extraData)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)

    local styleSection = self:AcquireSection(self:GetStyle("bodySection"))
    local style = GetItemLinkItemStyle(itemLink)
    local descriptionString = SI_ITEM_FORMAT_STR_STYLE_MATERIAL
    if style == GetUniversalStyleId() then
        descriptionString = SI_ITEM_DESCRIPTION_UNIVERSAL_STYLE
    end
    styleSection:AddLine(zo_strformat(descriptionString, GetItemStyleName(style)), self:GetStyle("bodyDescription"))
    self:AddSection(styleSection)
    self:AddPrioritySellText(itemLink)
    self:AddItemTags(itemLink)

    self:UpdateGamepadBorderDisplay(itemLink)
end

function ZO_Tooltip:LayoutRawBaseMaterial(itemLink, itemName, extraData)
    local refinedItemLink = GetItemLinkRefinedMaterialItemLink(itemLink)
    if(refinedItemLink ~= "") then
        local refinedSection = self:AcquireSection(self:GetStyle("bodySection"))
        local refinedItemName = GetItemLinkName(refinedItemLink)
        local displayQuality = GetItemLinkDisplayQuality(refinedItemLink)
        local qualityColor = GetItemQualityColor(displayQuality)

        local minRawMats = GetSmithingRefinementMinRawMaterial()
        local maxRawMats = GetSmithingRefinementMaxRawMaterial()

        self:AddTopSection(itemLink)
        self:AddItemTitle(itemLink, itemName)

        refinedSection:AddLine(zo_strformat(SI_TOOLTIP_ITEM_FORMAT_REFINES_TO, minRawMats, maxRawMats, qualityColor:Colorize(refinedItemName)), self:GetStyle("bodyDescription"))
        self:AddSection(refinedSection)

        self:AddMaterialLevels(refinedItemLink)
        self:AddPrioritySellText(itemLink)
        self:AddItemTags(itemLink)
    end
end

function ZO_Tooltip:LayoutRawBooster(itemLink, itemName, extraData)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)
    local refinedItemLink = GetItemLinkRefinedMaterialItemLink(itemLink)

    if refinedItemLink ~= "" then
        local boosterDescriptionSection = self:AcquireSection(self:GetStyle("bodySection"))

        local refinedItemName = GetItemLinkName(refinedItemLink)
        local refinedItemDisplayQuality = GetItemLinkDisplayQuality(refinedItemLink)
        local toDisplayQuality = GetItemLinkDisplayQuality(itemLink)
        local fromDisplayQuality = zo_max(ITEM_DISPLAY_QUALITY_TRASH, toDisplayQuality - 1)

        local requiredStackSize = GetRequiredSmithingRefinementStackSize()
        local refinedItemText = GetItemQualityColor(refinedItemDisplayQuality):Colorize(refinedItemName)
        local toQualityText = GetItemQualityColor(toDisplayQuality):Colorize(GetString("SI_ITEMQUALITY", toDisplayQuality))
        local fromQualityText = GetItemQualityColor(fromDisplayQuality):Colorize(GetString("SI_ITEMQUALITY", fromDisplayQuality))

        boosterDescriptionSection:AddLine(zo_strformat(SI_RAW_BOOSTER_DESCRIPTION, requiredStackSize, refinedItemText, fromQualityText, toQualityText), self:GetStyle("bodyDescription"))
        self:AddSection(boosterDescriptionSection)
    end
    self:AddPrioritySellText(itemLink)
    self:AddItemTags(itemLink)
end

function ZO_Tooltip:LayoutRawMaterial(itemLink, itemName, extraData)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)
    self:AddFlavorText(itemLink)
    self:AddPrioritySellText(itemLink)
    self:AddItemTags(itemLink)
end

function ZO_Tooltip:LayoutMaterial(itemLink, itemName, extraData)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)
    self:AddMaterialLevels(itemLink)
    self:AddPrioritySellText(itemLink)
    self:AddItemTags(itemLink)
end

local ITEMTYPE_TRAIT_DESCRIPTIONS = {
    [ITEMTYPE_ARMOR_TRAIT] = SI_ITEM_FORMAT_STR_ARMOR_TRAIT,
    [ITEMTYPE_WEAPON_TRAIT] = SI_ITEM_FORMAT_STR_WEAPON_TRAIT,
    [ITEMTYPE_JEWELRY_TRAIT] = SI_ITEM_FORMAT_STR_JEWELRY_TRAIT,
}
function ZO_Tooltip:LayoutTrait(itemLink, itemName, itemType, extraData)
    self:AddTopSection(itemLink)
    self:AddItemTitle(itemLink, itemName)

    local traitDescriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
    local descriptionId = ITEMTYPE_TRAIT_DESCRIPTIONS[itemType]
    traitDescriptionSection:AddLine(GetString(descriptionId), self:GetStyle("bodyDescription"))
    self:AddSection(traitDescriptionSection)

    self:AddTrait(itemLink, extraData)
    self:AddPrioritySellText(itemLink)
    self:AddItemTags(itemLink)
end

function ZO_Tooltip:LayoutAlchemyPreview(itemLink, itemTypeString, prospectiveAlchemyResult)
    if prospectiveAlchemyResult == PROSPECTIVE_ALCHEMY_RESULT_KNOWN and itemLink and itemLink ~= "" then
        local icon = GetItemLinkIcon(itemLink)
        if self.icon then
            self.icon:SetTexture(icon)
            self.icon:SetHidden(false)
        end

        self:AddTopSection(itemLink)
        self:AddItemTitle(itemLink)
        self:AddBaseStats(itemLink)
        self:AddOnUseAbility(itemLink)

        self:UpdateGamepadBorderDisplay(itemLink)
    else
        if self.icon then
            self.icon:SetHidden(true)
        end
        
        local title, description
        if prospectiveAlchemyResult == PROSPECTIVE_ALCHEMY_RESULT_UNCRAFTABLE then
            title = zo_strformat(SI_ALCHEMY_NO_RESULT, itemTypeString)
            description = GetString(SI_ALCHEMY_NO_EFFECTS)
        else
            title = zo_strformat(SI_ALCHEMY_UNKNOWN_RESULT, itemTypeString)
            description = zo_strformat(SI_ALCHEMY_UNKNOWN_EFFECTS, itemTypeString)
        end

        self:AddLine(title, self:GetStyle("title"))
        local alchemySection = self:AcquireSection(self:GetStyle("bodySection"))
        alchemySection:AddLine(description, self:GetStyle("bodyDescription"))
        self:AddSection(alchemySection)
    end
end

function ZO_Tooltip:LayoutEnchantingCraftingItem(itemLink, icon, creator, extraData)
    if itemLink and itemLink ~= "" then
        if self.icon then
            self.icon:SetTexture(icon)
            self.icon:SetHidden(false)
        end

        self:LayoutGlyph(itemLink, creator, extraData)

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

function ZO_Tooltip:LayoutEnchantingPreview(potencyRuneBagId, potencyRuneSlotIndex, essenceRuneBagId, essenceRuneSlotIndex, aspectRuneBagId, aspectRuneSlotIndex, extraData)
    local _, icon = GetEnchantingResultingItemInfo(potencyRuneBagId, potencyRuneSlotIndex, essenceRuneBagId, essenceRuneSlotIndex, aspectRuneBagId, aspectRuneSlotIndex)
    local itemLink = GetEnchantingResultingItemLink(potencyRuneBagId, potencyRuneSlotIndex, essenceRuneBagId, essenceRuneSlotIndex, aspectRuneBagId, aspectRuneSlotIndex)

    self:LayoutEnchantingCraftingItem(itemLink, icon, extraData)
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
    elseif itemData.entryType == STORE_ENTRY_TYPE_QUEST_ITEM then
        self:LayoutQuestItem(itemData.questItemId)
    elseif itemData.entryType == STORE_ENTRY_TYPE_ANTIQUITY_LEAD then
        self:LayoutAntiquityLead(GetStoreEntryAntiquityId(itemData.slotIndex))
    else
        self:LayoutStoreItemFromLink(itemData.itemLink, itemData.icon)
    end

    local requiredToBuyErrorText = itemData.dataSource.requiredToBuyErrorText
    if requiredToBuyErrorText ~= "" then
        local styleSection = self:AcquireSection(self:GetStyle("bodySection"))
        styleSection:AddLine(requiredToBuyErrorText, self:GetStyle("requirementFail"))
        self:AddSection(styleSection)
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

        self:LayoutItem(itemLink, NOT_EQUIPPED, NO_CREATOR_NAME, FORCE_FULL_DURABILITY)
    end
end

function ZO_Tooltip:LayoutUniversalStyleItem(itemLink)
    self:AddTopSection(itemLink)
    local stackCount = GetCurrentSmithingStyleItemCount(GetUniversalStyleId())
    local itemName = GetItemLinkName(itemLink)
    if stackCount then
        itemName = zo_strformat(SI_GAMEPAD_SMITHING_TOOLTIP_UNIVERSAL_STYLE_ITEM_TITLE, itemName, stackCount)
    end
    self:AddLine(itemName, self:GetStyle("title"))

    local styleSection = self:AcquireSection(self:GetStyle("bodySection"))
    styleSection:AddLine(GetString(SI_CRAFTING_UNIVERSAL_STYLE_ITEM_TOOLTIP), self:GetStyle("bodyDescription"))
    styleSection:AddLine(GetString(SI_CRAFTING_UNIVERSAL_STYLE_ITEM_CROWN_STORE_TOOLTIP), self:GetStyle("bodyDescription"))
    self:AddSection(styleSection)
    self:AddPrioritySellText(itemLink)
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

function ZO_Tooltip:AddItemForcedNotDeconstructable(itemLink)
    local statsSection = self:AcquireSection(self:GetStyle("bodySection"))
    if IsItemLinkForcedNotDeconstructable(itemLink) and not IsItemLinkContainer(itemLink) then
        statsSection:AddLine(GetString(SI_ITEM_FORMAT_STR_FORCED_NOT_DECONSTRUCTIBLE), self:GetStyle("bodyDescription"), self:GetStyle("notDeconstructable"))
    end
    self:AddSection(statsSection)
end

function ZO_Tooltip:SetProvisionerResultItem(recipeListIndex, recipeIndex)
    local _, icon = GetRecipeResultItemInfo(recipeListIndex, recipeIndex)
    local itemLink = GetRecipeResultItemLink(recipeListIndex, recipeIndex)

    if itemLink and itemLink ~= "" then
        if self.icon then
            self.icon:SetTexture(icon)
            self.icon:SetHidden(false)
        end

        self:LayoutItem(itemLink, NOT_EQUIPPED)
    end
end

do
    local LAYOUT_FUNCTIONS =
    {
        [ITEMTYPE_RECIPE] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutProvisionerRecipe(itemLink, itemName, tradeBoPData, extraData) end,

        [ITEMTYPE_BLACKSMITHING_BOOSTER] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutBooster(itemLink, itemName, extraData) end,
        [ITEMTYPE_WOODWORKING_BOOSTER] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutBooster(itemLink, itemName, extraData) end,
        [ITEMTYPE_CLOTHIER_BOOSTER] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutBooster(itemLink, itemName, extraData) end,
        [ITEMTYPE_JEWELRYCRAFTING_BOOSTER] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutBooster(itemLink, itemName, extraData) end,

        [ITEMTYPE_GLYPH_WEAPON] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutGlyph(itemLink, creatorName, itemName, tradeBoPData, extraData) end,
        [ITEMTYPE_GLYPH_ARMOR] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutGlyph(itemLink, creatorName, itemName, tradeBoPData, extraData) end,
        [ITEMTYPE_GLYPH_JEWELRY] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutGlyph(itemLink, creatorName, itemName, tradeBoPData, extraData) end,

        [ITEMTYPE_REAGENT] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutReagent(itemLink, itemName, extraData) end,

        [ITEMTYPE_POTION_BASE] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutAlchemyBase(itemLink, itemName, extraData) end,
        [ITEMTYPE_POISON_BASE] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutAlchemyBase(itemLink, itemName, extraData) end,

        [ITEMTYPE_INGREDIENT] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutIngredient(itemLink, itemName, extraData) end,

        [ITEMTYPE_STYLE_MATERIAL] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutStyleMaterial(itemLink, itemName, extraData) end,

        [ITEMTYPE_BLACKSMITHING_RAW_MATERIAL] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutRawBaseMaterial(itemLink, itemName, extraData) end,
        [ITEMTYPE_CLOTHIER_RAW_MATERIAL] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutRawBaseMaterial(itemLink, itemName, extraData) end,
        [ITEMTYPE_WOODWORKING_RAW_MATERIAL] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutRawBaseMaterial(itemLink, itemName, extraData) end,
        [ITEMTYPE_JEWELRYCRAFTING_RAW_MATERIAL] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutRawBaseMaterial(itemLink, itemName, extraData) end,

        [ITEMTYPE_RAW_MATERIAL] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutRawMaterial(itemLink, itemName, extraData) end,
        [ITEMTYPE_JEWELRYCRAFTING_RAW_BOOSTER] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutRawBooster(itemLink, itemName, extraData) end,
        [ITEMTYPE_JEWELRY_RAW_TRAIT] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutRawMaterial(itemLink, itemName, extraData) end,

        [ITEMTYPE_BLACKSMITHING_MATERIAL] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutMaterial(itemLink, itemName, extraData) end,
        [ITEMTYPE_CLOTHIER_MATERIAL] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutMaterial(itemLink, itemName, extraData) end,
        [ITEMTYPE_WOODWORKING_MATERIAL] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutMaterial(itemLink, itemName, extraData) end,
        [ITEMTYPE_JEWELRYCRAFTING_MATERIAL] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutMaterial(itemLink, itemName, extraData) end,

        [ITEMTYPE_ARMOR_TRAIT] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutTrait(itemLink, itemName, ITEMTYPE_ARMOR_TRAIT, extraData) end,
        [ITEMTYPE_WEAPON_TRAIT] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutTrait(itemLink, itemName, ITEMTYPE_WEAPON_TRAIT, extraData) end,
        [ITEMTYPE_JEWELRY_TRAIT] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutTrait(itemLink, itemName, ITEMTYPE_JEWELRY_TRAIT, extraData) end,

        [ITEMTYPE_SIEGE] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutSiege(itemLink, itemName, tradeBoPData, extraData) end,

        [ITEMTYPE_TOOL] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutTool(itemLink, itemName, tradeBoPData, extraData) end,

        [ITEMTYPE_SOUL_GEM] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutSoulGem(itemLink, itemName, extraData) end,

        [ITEMTYPE_AVA_REPAIR] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutAvARepair(itemLink, itemName, extraData) end,

        [ITEMTYPE_DYE_STAMP] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutDyeStamp(itemLink, itemName, extraData) end,

        [ITEMTYPE_CRAFTED_ABILITY] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutCraftedAbilityItem(itemLink, itemName, tradeBoPData) end,
        [ITEMTYPE_CRAFTED_ABILITY_SCRIPT] = function(self, itemLink, creatorName, itemName, tradeBoPData, extraData) self:LayoutCraftedAbilityScriptItem(itemLink, itemName, tradeBoPData) end,
    }

    --TODO: Get creatorName from itemLink?
    -- extraData is a table of optional parameters or additional information for tooltip layouts that aren't generic or commonly used
    -- AvailableOptions:
    --      enchantDiffMode - Controls the display of enchantment information as being added, removed, or default
    --      showTraitAsNew - Displays the trait information of an item as if it's being added to the item or otherwise new
    --      hideTrait - Show the item as if it had no trait, even if it does
    function ZO_Tooltip:LayoutItem(itemLink, equipped, creatorName, forceFullDurability, previewValueToAdd, itemName, equipSlot, showPlayerLocked, tradeBoPData, extraData)
        local isValidItemLink = itemLink ~= ""
        if isValidItemLink then
            --first do checks that can't be determined from the item type
            if IsItemLinkVendorTrash(itemLink) then
                self:LayoutVendorTrash(itemLink, itemName, extraData)
            elseif DoesItemLinkStartQuest(itemLink) or DoesItemLinkFinishQuest(itemLink) then
                if GetItemLinkItemType(itemLink) == ITEMTYPE_MASTER_WRIT then
                    self:LayoutMasterWritItem(itemLink, tradeBoPData, extraData)
                else
                    self:LayoutQuestStartOrFinishItem(itemLink, itemName, extraData)
                end
            else
                -- now attempt to layout the itemlink by the item type
                local itemType = GetItemLinkItemType(itemLink)
                if IsItemLinkEnchantingRune(itemLink) then
                    self:LayoutEnchantingRune(itemLink, itemName, extraData)
                elseif itemType == ITEMTYPE_LURE and IsItemLinkConsumable(itemLink) then
                    self:LayoutLure(itemLink, itemName, extraData)
                else
                    local layoutFunction = LAYOUT_FUNCTIONS[itemType]
                    if layoutFunction then
                        layoutFunction(self, itemLink, creatorName, itemName, tradeBoPData, extraData)
                    else
                        if IsItemLinkBook(itemLink) then
                            self:LayoutBook(itemLink, tradeBoPData)
                        else -- fallback to our default layout
                            if equipped == NOT_EQUIPPED then
                                equipSlot = EQUIP_SLOT_NONE
                            end
                            self:LayoutGenericItem(itemLink, equipped, creatorName, forceFullDurability, previewValueToAdd, itemName, equipSlot, showPlayerLocked, tradeBoPData, extraData)
                        end
                    end
                end
            end
        end

        return isValidItemLink
    end
end

function ZO_Tooltip:LayoutItemWithStackCount(itemLink, equipped, creatorName, forceFullDurability, previewValueToAdd, customOrBagStackCount, equipSlot, showPlayerLocked, tradeBoPData, extraData)
    local isValidItemLink = itemLink ~= ""
    if isValidItemLink then
        local stackCount
        if customOrBagStackCount == ZO_ITEM_TOOLTIP_INVENTORY_TITLE_COUNT then
            stackCount = GetItemLinkInventoryCount(itemLink, INVENTORY_COUNT_BAG_OPTION_BACKPACK)
        elseif customOrBagStackCount == ZO_ITEM_TOOLTIP_BANK_TITLE_COUNT then
            stackCount = GetItemLinkInventoryCount(itemLink, INVENTORY_COUNT_BAG_OPTION_BANK)
        elseif customOrBagStackCount == ZO_ITEM_TOOLTIP_INVENTORY_AND_BANK_TITLE_COUNT then
            stackCount = GetItemLinkInventoryCount(itemLink, INVENTORY_COUNT_BAG_OPTION_BACKPACK_AND_BANK)
        elseif customOrBagStackCount == ZO_ITEM_TOOLTIP_CRAFTBAG_TITLE_COUNT then
            stackCount = GetItemLinkInventoryCount(itemLink, INVENTORY_COUNT_BAG_OPTION_CRAFT_BAG)
        elseif customOrBagStackCount == ZO_ITEM_TOOLTIP_INVENTORY_AND_BANK_AND_CRAFTBAG_TITLE_COUNT then
            stackCount = GetItemLinkInventoryCount(itemLink, INVENTORY_COUNT_BAG_OPTION_BACKPACK_AND_BANK_AND_CRAFT_BAG)
        elseif customOrBagStackCount == ZO_ITEM_TOOLTIP_HOUSE_BANKS_TITLE_COUNT then
            stackCount = GetItemLinkInventoryCount(itemLink, INVENTORY_COUNT_BAG_OPTION_HOUSE_BANKS)
        else
            stackCount = customOrBagStackCount
        end

        local itemName = GetItemLinkName(itemLink)
        if stackCount and stackCount > 1 then
            itemName = zo_strformat(SI_TOOLTIP_ITEM_NAME_WITH_QUANTITY, itemName, stackCount)
        end
        return self:LayoutItem(itemLink, equipped, creatorName, forceFullDurability, previewValueToAdd, itemName, equipSlot, showPlayerLocked, tradeBoPData, extraData)
    end
end

function ZO_Tooltip:LayoutItemWithStackCountSimple(itemLink, customOrBagStackCount)
    return self:LayoutItemWithStackCount(itemLink, NOT_EQUIPPED, NO_CREATOR_NAME, DONT_FORCE_FULL_DURABILITY, NO_PREVIEW_VALUE, customOrBagStackCount, EQUIP_SLOT_NONE)
end

-- "Specific Layout Functions"

function ZO_Tooltip:LayoutBagItem(bagId, slotIndex, showCombinedCount, extraData)
    local itemLink = GetItemLink(bagId, slotIndex)
    local showPlayerLocked = IsItemPlayerLocked(bagId, slotIndex)
    local equipped = bagId == BAG_WORN
    local equipSlot = equipped and slotIndex or EQUIP_SLOT_NONE
    local stackCount = ZO_ITEM_TOOLTIP_INVENTORY_TITLE_COUNT
    if showCombinedCount then
        stackCount = ZO_ITEM_TOOLTIP_INVENTORY_AND_BANK_AND_CRAFTBAG_TITLE_COUNT
    else
        if bagId == BAG_BANK then
            stackCount = ZO_ITEM_TOOLTIP_BANK_TITLE_COUNT
        elseif bagId == BAG_BACKPACK then
            stackCount = ZO_ITEM_TOOLTIP_INVENTORY_TITLE_COUNT
        elseif bagId == BAG_VIRTUAL then
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

    --We do not want to show armory builds for items in the guild bank or buyback, and it is not possible for items in the other 2 bags to be in builds
    --Therefore, we can skip checking entirely for these bags
    if bagId ~= BAG_GUILDBANK and bagId ~= BAG_BUYBACK and bagId ~= BAG_VIRTUAL and bagId ~= BAG_COMPANION_WORN then
        if not extraData then
            extraData = {}
        end
        extraData.bagId = bagId
        extraData.slotIndex = slotIndex
    end
    return self:LayoutItemWithStackCount(itemLink, equipped, GetItemCreatorName(bagId, slotIndex), DONT_FORCE_FULL_DURABILITY, NO_PREVIEW_VALUE, stackCount, equipSlot, showPlayerLocked, tradeBoPData, extraData)
end

function ZO_LayoutItemLinkEquippedComparison(tooltipType, itemLink, showSecondSlot)
    local equipSlot1, equipSlot2 = GetItemLinkEquippedComparisonEquipSlots(itemLink)
    local showEquipSlot = showSecondSlot and equipSlot2 or equipSlot1
    if showEquipSlot ~= EQUIP_SLOT_NONE then
        local actorCategory = GetItemLinkActorCategory(itemLink)
        local wornBag = GetWornBagForGameplayActorCategory(actorCategory)
        if GAMEPAD_TOOLTIPS:LayoutBagItem(tooltipType, wornBag, showEquipSlot) then
            ZO_InventoryUtils_UpdateTooltipEquippedIndicatorText(tooltipType, showEquipSlot, actorCategory)
            return true
        end
    end
    return false
end

function ZO_LayoutBagItemEquippedComparison(tooltipType, bagId, slotIndex, showSecondSlot)
    local equipSlot1, equipSlot2 = GetItemEquippedComparisonEquipSlots(bagId, slotIndex)
    local showEquipSlot = showSecondSlot and equipSlot2 or equipSlot1
    if showEquipSlot ~= EQUIP_SLOT_NONE then
        local actorCategory = GetItemActorCategory(bagId, slotIndex)
        local wornBag = GetWornBagForGameplayActorCategory(actorCategory)
        if GAMEPAD_TOOLTIPS:LayoutBagItem(tooltipType, wornBag, showEquipSlot) then
            ZO_InventoryUtils_UpdateTooltipEquippedIndicatorText(tooltipType, showEquipSlot, actorCategory)
            return true
        end
    end
    return false
end

function ZO_Tooltip:LayoutTradeItem(who, tradeIndex)
    local itemLink = GetTradeItemLink(who, tradeIndex, LINK_STYLE_DEFAULT)
    local equipped = false
    local _, _, stack, _, creator = GetTradeItemInfo(who, tradeIndex)
    local tradeBoPData
    if IsTradeItemBoPAndTradeable(who, tradeIndex) then
        tradeBoPData =
        {
            timeRemaining = GetTradeItemBoPTimeRemainingSeconds(who, tradeIndex),
            namesString = GetTradeItemBoPTradeableDisplayNamesString(who, tradeIndex),
        }
    end
    return self:LayoutItemWithStackCount(itemLink, equipped, creator, DONT_FORCE_FULL_DURABILITY, NO_PREVIEW_VALUE, stack, EQUIP_SLOT_NONE, DONT_SHOW_PLAYER_LOCKED, tradeBoPData)
end

function ZO_Tooltip:LayoutPendingSmithingItem(patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex)
    local _, _, icon = GetSmithingPatternInfo(patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex)
    local itemLink = GetSmithingPatternResultLink(patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex)

    if itemLink and itemLink ~= "" then
        if self.icon then
            self.icon:SetTexture(icon)
            self.icon:SetHidden(false)
        end

        self:LayoutItem(itemLink, NOT_EQUIPPED)
    end
end

function ZO_Tooltip:LayoutPendingEnchantedItem(itemBagId, itemIndex, enchantmentBagId, enchantmentIndex)
    local itemLink = GetEnchantedItemResultingItemLink(itemBagId, itemIndex, enchantmentBagId, enchantmentIndex)
    local extraData =
    {
        enchantDiffMode = ZO_ENCHANT_DIFF_ADD,
        bagId = itemBagId,
        slotIndex = itemIndex,
    }
    self:LayoutItem(itemLink, NOT_EQUIPPED, NO_CREATOR_NAME, FORCE_FULL_DURABILITY, NO_PREVIEW_VALUE, NO_ITEM_NAME, EQUIP_SLOT_NONE, DONT_SHOW_PLAYER_LOCKED, NO_TRADE_BOP_DATA, extraData)
end

function ZO_Tooltip:LayoutPendingItemChargeOrRepair(itemBagId, itemSlotIndex, improvementKitBagId, improvementKitIndex, improvementFunc)
    local itemLink = GetItemLink(itemBagId, itemSlotIndex)
    local previewValueToAdd = improvementFunc(itemBagId, itemSlotIndex, improvementKitBagId, improvementKitIndex)
    local extraData =
    {
        enchantDiffMode = ZO_ENCHANT_DIFF_ADD,
        bagId = itemBagId,
        slotIndex = itemSlotIndex,
    }
    self:LayoutItem(itemLink, NOT_EQUIPPED, NO_CREATOR_NAME, DONT_FORCE_FULL_DURABILITY, previewValueToAdd, NO_ITEM_NAME, EQUIP_SLOT_NONE, DONT_SHOW_PLAYER_LOCKED, NO_TRADE_BOP_DATA, extraData)
end

function ZO_Tooltip:LayoutPendingItemCharge(itemBagId, itemSlotIndex, improvementKitBagId, improvementKitIndex)
    self:LayoutPendingItemChargeOrRepair(itemBagId, itemSlotIndex, improvementKitBagId, improvementKitIndex, GetAmountSoulGemWouldChargeItem)
end

function ZO_Tooltip:LayoutPendingItemRepair(itemBagId, itemSlotIndex, improvementKitBagId, improvementKitIndex)
    self:LayoutPendingItemChargeOrRepair(itemBagId, itemSlotIndex, improvementKitBagId, improvementKitIndex, GetAmountRepairKitWouldRepairItem)
end

function ZO_Tooltip:LayoutImproveSourceSmithingItem(bagId, slotIndex, narrateAsCurrent)
    --Only include this extra narration if we have added the item for improvement
    if narrateAsCurrent then
        self:AddNarrationLine(GetString(SI_GAMEPAD_SMITHING_IMPROVEMENT_TOOLTIP_CURRENT_ITEM_NARRATION))
    end

    local itemLink = GetItemLink(bagId, slotIndex)
    local showPlayerLocked = IsItemPlayerLocked(bagId, slotIndex)

    local tradeBoPData
    if IsItemBoPAndTradeable(bagId, slotIndex) then
        tradeBoPData =
        {
            timeRemaining = GetItemBoPTimeRemainingSeconds(bagId, slotIndex),
            namesString = GetItemBoPTradeableDisplayNamesString(bagId, slotIndex),
        }
    end

    local extraData =
    {
        bagId = bagId,
        slotIndex = slotIndex,
    }
    return self:LayoutItem(itemLink, NOT_EQUIPPED, GetItemCreatorName(bagId, slotIndex), DONT_FORCE_FULL_DURABILITY, NO_PREVIEW_VALUE, NO_ITEM_NAME, EQUIP_SLOT_NONE, showPlayerLocked, tradeBoPData, extraData)
end

function ZO_Tooltip:LayoutImproveResultSmithingItem(itemToImproveBagId, itemToImproveSlotIndex, craftingSkillType)
    self:AddNarrationLine(GetString(SI_GAMEPAD_SMITHING_IMPROVEMENT_TOOLTIP_UPGRADED_ITEM_NARRATION))
    local _, icon = GetSmithingImprovedItemInfo(itemToImproveBagId, itemToImproveSlotIndex, craftingSkillType)
    local itemLink = GetSmithingImprovedItemLink(itemToImproveBagId, itemToImproveSlotIndex, craftingSkillType)

    if itemLink and itemLink ~= "" then
        if self.icon then
            self.icon:SetTexture(icon)
            self.icon:SetHidden(false)
        end

        local extraData =
        {
            bagId = itemToImproveBagId,
            slotIndex = itemToImproveSlotIndex,
        }
        self:LayoutItem(itemLink, NOT_EQUIPPED, NO_CREATOR_NAME, DONT_FORCE_FULL_DURABILITY, NO_PREVIEW_VALUE, NO_ITEM_NAME, EQUIP_SLOT_NONE, DONT_SHOW_PLAYER_LOCKED, NO_TRADE_BOP_DATA, extraData)
    end

    --Add line for tradeable loss
    if IsItemBoPAndTradeable(itemToImproveBagId, itemToImproveSlotIndex) then
        local section = self:AcquireSection(self:GetStyle("bodySection"))
        section:AddLine(GetString(SI_SMITHING_IMPROVEMENT_TRADE_BOP_WILL_BECOME_UNTRADEABLE), self:GetStyle("bodyDescription"), self:GetStyle("failed"))
        self:AddSection(section)
    end
end

function ZO_Tooltip:LayoutResearchSmithingItem(traitType, traitDescription, traitResearchSourceDescription, traitMaterialSourceDescription)
    if self.icon then
        self.icon:SetHidden(true)
    end

    self:AddLine(traitType, self:GetStyle("title"))
    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    bodySection:AddLine(traitDescription, self:GetStyle("bodyDescription"))
    if traitResearchSourceDescription then
        bodySection:AddLine(zo_strformat(SI_SMITHING_TRAIT_RESEARCH_SOURCE_DESCRIPTION, traitResearchSourceDescription), self:GetStyle("bodyDescription"))
        bodySection:AddLine(zo_strformat(SI_SMITHING_TRAIT_MATERIAL_SOURCE_DESCRIPTION, traitMaterialSourceDescription), self:GetStyle("bodyDescription"))
    end
    self:AddSection(bodySection)
end

function ZO_Tooltip:LayoutQuestItem(questItemId)
    local header = GetString(SI_ITEM_FORMAT_STR_QUEST_ITEM)
    local itemName = GetQuestItemName(questItemId)
    local tooltipText = GetQuestItemTooltipText(questItemId)

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

function ZO_Tooltip:LayoutItemSetCollectionPieceLink(itemLink, hideTrait)
    local extraData = 
    {
        hideTrait = hideTrait,
    }
    return self:LayoutItem(itemLink, NOT_EQUIPPED, NO_CREATOR_NAME, FORCE_FULL_DURABILITY, NO_PREVIEW_VALUE, NO_ITEM_NAME, EQUIP_SLOT_NONE, DONT_SHOW_PLAYER_LOCKED, NO_TRADE_BOP_DATA, extraData)
end

function ZO_Tooltip:LayoutItemSetCollectionSummary()
    for _, topLevelCategoryData in ITEM_SET_COLLECTIONS_DATA_MANAGER:TopLevelItemSetCollectionCategoryIterator(self.categoryFilters) do
        local categoryName = topLevelCategoryData:GetFormattedName()
        local categorySection = self:AcquireSection(self:GetStyle("itemSetCollectionSummaryCategorySection"))
        categorySection:AddLine(categoryName, self:GetStyle("itemSetCollectionSummaryCategoryHeader"))

        local barSection = self:AcquireSection(self:GetStyle("topSection"))
        local statusBar = self:AcquireStatusBar(self:GetStyle("itemSetCollectionSummaryCategoryBar"))
        local MIN_PIECES = 0
        local unlockedPieces, totalPieces = topLevelCategoryData:GetNumUnlockedAndTotalPieces()
        statusBar:SetMinMax(MIN_PIECES, totalPieces)
        statusBar:SetValue(unlockedPieces)
        local function GetStatusBarNarrationText()
            local percentage = (unlockedPieces / totalPieces) * 100
            percentage = string.format("%.2f", percentage)
            return zo_strformat(SI_SCREEN_NARRATION_PERCENT_FORMATTER, percentage)
        end
        barSection:AddStatusBar(statusBar, GetStatusBarNarrationText)

        categorySection:AddSection(barSection)
        self:AddSection(categorySection)
    end
end

function ZO_Tooltip:LayoutItemStatComparison(bagId, slotId, comparisonSlot)
    local statEffects = {}
    local activeMundusStoneBuffIndices = { GetUnitActiveMundusStoneBuffIndices("player") }
    for _, buffIndex in ipairs(activeMundusStoneBuffIndices) do
        local buffName, _, _, buffSlot, _, _, _, _, _, _, abilityId = GetUnitBuffInfo("player", buffIndex)
        local numStatsForAbility = GetAbilityNumDerivedStats(abilityId)
        for i = 1, numStatsForAbility do
            local statType, effectValue = GetAbilityDerivedStatAndEffectByIndex(abilityId, i)
            local statEffect =
            {
                statType = statType,
                effect = effectValue,
            }
            table.insert(statEffects, statEffect)
        end
    end

    local statDeltaLookup = ZO_GetStatDeltaLookupFromItemComparisonReturns(CompareBagItemToCurrentlyEquipped(bagId, slotId, comparisonSlot))
    for _, statGroup in ipairs(ZO_INVENTORY_STAT_GROUPS) do
        local statSection = self:AcquireSection(self:GetStyle("itemComparisonStatSection"))
        for _, stat in ipairs(statGroup) do
            local statName = zo_strformat(SI_STAT_NAME_FORMAT, GetString("SI_DERIVEDSTATS", stat))
            local currentValue = GetPlayerStat(stat)
            local statDelta = statDeltaLookup[stat] or 0
            local valueToShow = currentValue + statDelta

            local isMundusStat = false
            for _, statEffect in ipairs(statEffects) do
                if stat == statEffect.statType then
                    isMundusStat = true
                end
            end

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
                local INHERIT_COLOR = true
                local NO_GRAMMAR = true
                valueToShow = zo_iconTextFormatNoSpaceAlignedRight(icon, 24, 24, valueToShow, INHERIT_COLOR, NO_GRAMMAR)
            end

            if isMundusStat then
                valueToShow = zo_iconTextFormatNoSpace(ZO_STAT_MUNDUS_ICONS[MUNDUS_STONE_INVALID], 24, 24, valueToShow)
            end

            local statValuePair = statSection:AcquireStatValuePair(self:GetStyle("itemComparisonStatValuePair"))
            statValuePair:SetStat(statName, self:GetStyle("statValuePairStat"))
            statValuePair:SetValue(valueToShow, self:GetStyle("itemComparisonStatValuePairValue"), colorStyle)
            statSection:AddStatValuePair(statValuePair)
        end
        self:AddSection(statSection)
    end
end

function ZO_Tooltip:LayoutMundusStatComparison(statEffects)
    if not statEffects then
        return
    end

    for _, statGroup in ipairs(ZO_INVENTORY_STAT_GROUPS) do
        local statSection = self:AcquireSection(self:GetStyle("itemComparisonStatSection"))
        for _, stat in ipairs(statGroup) do
            local statName = zo_strformat(SI_STAT_NAME_FORMAT, GetString("SI_DERIVEDSTATS", stat))
            local currentValue = GetPlayerStat(stat)
            local statDelta = 0
            local valueToShow = currentValue

            local isMundusStat = false
            for _, statEffect in ipairs(statEffects) do
                if stat == statEffect.statType then
                    isMundusStat = true
                    statDelta = statEffect.effect
                end
            end

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
                local INHERIT_COLOR = true
                local NO_GRAMMAR = true
                valueToShow = zo_iconTextFormatNoSpaceAlignedRight(icon, 24, 24, valueToShow, INHERIT_COLOR, NO_GRAMMAR)
            end

            if isMundusStat then
                valueToShow = zo_iconTextFormatNoSpace(ZO_STAT_MUNDUS_ICONS[MUNDUS_STONE_INVALID], 24, 24, valueToShow)
            end

            local statValuePair = statSection:AcquireStatValuePair(self:GetStyle("itemComparisonStatValuePair"))
            statValuePair:SetStat(statName, self:GetStyle("statValuePairStat"))
            statValuePair:SetValue(valueToShow, self:GetStyle("itemComparisonStatValuePairValue"), colorStyle)
            statSection:AddStatValuePair(statValuePair)
        end
        self:AddSection(statSection)
    end
end

do
    local FORMAT_EXTRA_OPTIONS =
    {
        showCap = true,
    }

    function ZO_Tooltip:AddCurrencyLocationSection(mainSection, currencyLocation)
        local IS_PLURAL = false
        local IS_UPPER = false

        local locationSection
        local locationCurrenciesSection
        for currencyType = CURT_ITERATION_BEGIN, CURT_ITERATION_END do
            if CanCurrencyBeStoredInLocation(currencyType, currencyLocation) then
                if not locationCurrenciesSection then
                    locationSection = mainSection:AcquireSection(self:GetStyle("currencyLocationSection"))
                    
                    --Title
                    locationSection:AddLine(GetString("SI_CURRENCYLOCATION", currencyLocation), self:GetStyle("currencyLocationTitle"))

                    --Currencies Section
                    locationCurrenciesSection = locationSection:AcquireSection(self:GetStyle("currencyLocationCurrenciesSection"))
                end
                
                --Currency Count
                local statValuePair = locationCurrenciesSection:AcquireStatValuePair(self:GetStyle("currencyStatValuePair"))
                statValuePair:SetStat(zo_strformat(SI_CURRENCY_NAME_FORMAT, GetCurrencyName(currencyType, IS_PLURAL, IS_UPPER)), self:GetStyle("currencyStatValuePairStat"))
                local amount = GetCurrencyAmount(currencyType, currencyLocation)
                FORMAT_EXTRA_OPTIONS.currencyLocation = currencyLocation
                local valueString = ZO_Currency_FormatGamepad(currencyType, amount, ZO_CURRENCY_FORMAT_WHITE_AMOUNT_ICON, FORMAT_EXTRA_OPTIONS)
                statValuePair:SetValue(valueString, self:GetStyle("currencyStatValuePairValue"))
                locationCurrenciesSection:AddStatValuePair(statValuePair)
            end 
        end

        if locationSection then
            locationSection:AddSection(locationCurrenciesSection)
            mainSection:AddSection(locationSection)
        end
    end

    function ZO_Tooltip:LayoutCurrencies()  
        local currencyMainSection = self:AcquireSection(self:GetStyle("currencyMainSection"))

        self:AddCurrencyLocationSection(currencyMainSection, CURRENCY_LOCATION_CHARACTER)
        self:AddCurrencyLocationSection(currencyMainSection, CURRENCY_LOCATION_ACCOUNT)        
        
        self:AddSection(currencyMainSection)
    end
end

function ZO_Tooltip:LayoutBankCurrencies()
    local bankCurrencyMainSection = self:AcquireSection(self:GetStyle("bankCurrencyMainSection"))
    local IS_PLURAL = false
    local IS_UPPER = false
    for currencyType = CURT_ITERATION_BEGIN, CURT_ITERATION_END do
        if CanCurrencyBeStoredInLocation(currencyType, CURRENCY_LOCATION_BANK) then
            local currencySection = self:AcquireSection(self:GetStyle("bankCurrencySection"))
            local name = GetCurrencyName(currencyType, IS_PLURAL, IS_UPPER)
            local bankedStatValuePair = currencySection:AcquireStatValuePair(self:GetStyle("currencyStatValuePair"))
            local bankedHeader = zo_strformat(SI_GAMEPAD_BANK_CURRENCY_AMOUNT_BANKED_HEADER_FORMAT, name)
            local bankedValueString = zo_strformat(SI_GAMEPAD_TOOLTIP_ITEM_VALUE_FORMAT, ZO_CommaDelimitNumber(GetCurrencyAmount(currencyType, CURRENCY_LOCATION_BANK)), ZO_Currency_GetPlatformFormattedCurrencyIcon(currencyType))
            bankedStatValuePair:SetStat(bankedHeader, self:GetStyle("currencyStatValuePairStat"))
            bankedStatValuePair:SetValue(bankedValueString, self:GetStyle("currencyStatValuePairValue"))
            currencySection:AddStatValuePair(bankedStatValuePair)

            local carriedStatValuePair = currencySection:AcquireStatValuePair(self:GetStyle("currencyStatValuePair"))
            local carriedHeader = zo_strformat(SI_GAMEPAD_BANK_CURRENCY_AMOUNT_CARRIED_HEADER_FORMAT, name)
            local carriedValueString = zo_strformat(SI_GAMEPAD_TOOLTIP_ITEM_VALUE_FORMAT, ZO_CommaDelimitNumber(GetCurrencyAmount(currencyType, GetCurrencyPlayerStoredLocation(currencyType))), ZO_Currency_GetPlatformFormattedCurrencyIcon(currencyType))
            carriedStatValuePair:SetStat(carriedHeader, self:GetStyle("currencyStatValuePairStat"))
            carriedStatValuePair:SetValue(carriedValueString, self:GetStyle("currencyStatValuePairValue"))
            currencySection:AddStatValuePair(carriedStatValuePair)

            bankCurrencyMainSection:AddSection(currencySection)
        end
    end
    self:AddSection(bankCurrencyMainSection)
end

function ZO_Tooltip:LayoutGuildStoreSearchResult(itemLink, customOrBagStackCount, sellerName)
    self:LayoutItemWithStackCountSimple(itemLink, customOrBagStackCount)

    if sellerName then
        local sellerNameSection = self:AcquireSection(self:GetStyle("bodySection"))
        local userFacingSellerName = ZO_FormatUserFacingCharacterOrDisplayName(sellerName)
        sellerNameSection:AddLine(zo_strformat(SI_TRADING_HOUSE_SEARCH_RESULT_SELLER_FORMATTER, userFacingSellerName), self:GetStyle("bodyDescription"))
        self:AddSection(sellerNameSection)
    end
end

function ZO_Tooltip:LayoutUnknownRetraitTrait(traitName, requiredResearchString)
    self:AddLine(traitName, self:GetStyle("title"))

    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    bodySection:AddLine(requiredResearchString, self:GetStyle("bodyDescription"), self:GetStyle("failed"))
    self:AddSection(bodySection)
end

function ZO_Tooltip:LayoutFurnishingLimitType(itemLink)
    local furnishingLimitTypeSection = self:AcquireSection(self:GetStyle("furnishingLimitTypeSection"))
    furnishingLimitTypeSection:AddLine(GetString(SI_TOOLTIP_FURNISHING_LIMIT_TYPE), self:GetStyle("furnishingLimitTypeTitle"))

    local furnishingLimitType = GetItemLinkFurnishingLimitType(itemLink)
    local furnishingLimitName = GetString("SI_HOUSINGFURNISHINGLIMITTYPE", furnishingLimitType)
    furnishingLimitTypeSection:AddLine(furnishingLimitName, self:GetStyle("furnishingLimitTypeDescription"))

    self:AddSection(furnishingLimitTypeSection)
end

function ZO_Tooltip:LayoutConsolidatedStationUnlockProgress(itemLink)
    local unlockProgressSection = self:AcquireSection(self:GetStyle("bodySection"))
    local unlockProgressPair = self:AcquireStatValuePair(self:GetStyle("statValuePair"))
    unlockProgressPair:SetStat(GetString(SI_GAMEPAD_SMITHING_CONSOLIDATED_STATION_TOOLTIP_UNLOCK_PROGRESS_LABEL), self:GetStyle("statValuePairStat"))

    local numUnlockedSets = GetItemLinkNumConsolidatedSmithingStationUnlockedSets(itemLink)
    local numTotalSets = GetNumConsolidatedSmithingSets()
    local progressString = zo_strformat(SI_SMITHING_CONSOLIDATED_STATION_TOOLTIP_UNLOCK_PROGRESS_COUNT_FORMATTER, numUnlockedSets, numTotalSets)
    unlockProgressPair:SetValue(progressString, self:GetStyle("statValuePairValue"))
    unlockProgressSection:AddStatValuePair(unlockProgressPair)

    self:AddSection(unlockProgressSection)
end

function ZO_Tooltip:LayoutGenericItemSet(itemSetId)
    local hasSet, setName, numBonuses = GetItemSetInfo(itemSetId)
    if hasSet then
        local setSection = self:AcquireSection(self:GetStyle("bodySection"))
        setSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_SET_NAME_NO_COUNT, setName), self:GetStyle("bodyHeader"))

        for bonusIndex = 1, numBonuses do
            local _, bonusDescription = GetItemSetBonusInfo(itemSetId, bonusIndex)
            setSection:AddLine(bonusDescription, self:GetStyle("activeBonus"), self:GetStyle("bodyDescription"))
        end
        self:AddSection(setSection)
        self:AddSetRestrictions(itemSetId)
    end
end