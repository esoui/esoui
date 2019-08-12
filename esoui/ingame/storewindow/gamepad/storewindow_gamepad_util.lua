local STORE_ITEM_HEADER_DEFAULT_PADDING = 60
local STABLE_ITEM_POST_PADDING = 20

local STORE_WEAPON_GROUP = 1
local STORE_HEAVY_ARMOR_GROUP = 2
local STORE_MEDIUM_ARMOR_GROUP = 3
local STORE_LIGHT_ARMOR_GROUP = 4
local STORE_JEWELRY_GROUP = 5
local STORE_SUPPLIES_GROUP = 6
local STORE_MATERIALS_GROUP = 7
local STORE_QUICKSLOTS_GROUP = 8
local STORE_COLLECTIBLE_GROUP = 9
local STORE_QUEST_ITEMS_GROUP = 10
local STORE_OTHER_GROUP = 11

-------------------
--Utility functions
-------------------


local function GetItemStoreGroup(itemData)
    if itemData.entryType == STORE_ENTRY_TYPE_COLLECTIBLE then
        return STORE_COLLECTIBLE_GROUP
    elseif itemData.entryType == STORE_ENTRY_TYPE_QUEST_ITEM then
        return STORE_QUEST_ITEMS_GROUP
    elseif itemData.equipType == EQUIP_TYPE_RING or itemData.equipType== EQUIP_TYPE_NECK then
        return STORE_JEWELRY_GROUP
    elseif itemData.itemType == ITEMTYPE_WEAPON or itemData.displayFilter == ITEMFILTERTYPE_WEAPONS then
        return STORE_WEAPON_GROUP
    elseif itemData.itemType == ITEMTYPE_ARMOR or itemData.displayFilter == ITEMFILTERTYPE_ARMOR then
        local armorType
        if itemData.bagId and itemData.slotIndex then
            armorType = GetItemArmorType(itemData.bagId, itemData.slotIndex)
        else
            armorType = GetItemLinkArmorType(itemData.itemLink)
        end

        if armorType == ARMORTYPE_HEAVY then
            return STORE_HEAVY_ARMOR_GROUP
        elseif armorType == ARMORTYPE_MEDIUM then
            return STORE_MEDIUM_ARMOR_GROUP
        elseif armorType == ARMORTYPE_LIGHT then
            return STORE_LIGHT_ARMOR_GROUP
        end
    elseif ZO_InventoryUtils_DoesNewItemMatchSupplies(itemData) then
        return STORE_SUPPLIES_GROUP
    elseif ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, ITEMFILTERTYPE_CRAFTING) then
        return STORE_MATERIALS_GROUP
    elseif ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, ITEMFILTERTYPE_QUICKSLOT) then
        return STORE_QUICKSLOTS_GROUP
    end

    return STORE_OTHER_GROUP
end

local function GetBestItemCategoryDescription(itemData)
    if itemData.storeGroup == STORE_COLLECTIBLE_GROUP then
        local collectibleCategory = GetCollectibleCategoryTypeFromLink(itemData.itemLink)
        return GetString("SI_COLLECTIBLECATEGORYTYPE", collectibleCategory)
    elseif itemData.storeGroup == STORE_QUEST_ITEMS_GROUP then
        return GetString(SI_ITEM_FORMAT_STR_QUEST_ITEM)
    else
        return ZO_InventoryUtils_Gamepad_GetBestItemCategoryDescription(itemData)
    end
end

local function GetBestSellItemCategoryDescription(itemData)
    local traitType = GetItemTrait(itemData.bagId, itemData.slotIndex)
    if traitType == ITEM_TRAIT_TYPE_WEAPON_ORNATE or traitType == ITEM_TRAIT_TYPE_ARMOR_ORNATE or traitType == ITEM_TRAIT_TYPE_JEWELRY_ORNATE then
        return GetString("SI_ITEMTRAITTYPE", traitType)
    else
        return GetBestItemCategoryDescription(itemData)
    end
end

local DEFAULT_SORT_KEYS =
{
    bestGamepadItemCategoryName = { tiebreaker = "name" },
    name = { tiebreaker = "requiredLevel" },
    requiredLevel = { tiebreaker = "requiredChampionPoints", isNumeric = true },
    requiredChampionPoints = { tiebreaker = "iconFile", isNumeric = true },
    iconFile = { tiebreaker = "uniqueId" },
    uniqueId = { isId64 = true },
    customSortOrder = { tiebreaker = "bestGamepadItemCategoryName", isNumeric = true },
}

local function ItemSortFunc(data1, data2)
     return ZO_TableOrderingFunction(data1, data2, "bestGamepadItemCategoryName", DEFAULT_SORT_KEYS, ZO_SORT_ORDER_UP)
end

local function SellSortFunc(data1, data2)
     return ZO_TableOrderingFunction(data1, data2, "customSortOrder", DEFAULT_SORT_KEYS, ZO_SORT_ORDER_UP)
end

local BUY_ITEMS_SORT_KEYS =
{
    bestGamepadItemCategoryName = { tiebreaker = "name" },
    name = { tiebreaker = "meetsRequirementsToBuy" },
    meetsRequirementsToBuy = { tiebreaker = "meetsRequirementsToEquip", isNumeric = true },
    meetsRequirementsToEquip = { tiebreaker = "icon", isNumeric = true },
    icon = { tiebreaker = "slotIndex" },
    slotIndex = { isId64 = true },
}

local BUY_ITEMS_SORT_KEYS_VALUE =
{
    bestGamepadItemCategoryName = { tiebreaker = "stackBuyPrice" },
    stackBuyPrice = { tiebreaker = "stackBuyPriceCurrency1" , isNumeric = true},
    stackBuyPriceCurrency1 = { tiebreaker = "stackBuyPriceCurrency2", isNumeric = true },
    stackBuyPriceCurrency2 = { tiebreaker = "name", isNumeric = true },
    name = { tiebreaker = "meetsRequirementsToBuy" },
    meetsRequirementsToBuy = { tiebreaker = "meetsRequirementsToEquip", isNumeric = true },
    meetsRequirementsToEquip = { tiebreaker = "icon", isNumeric = true },
    icon = { tiebreaker = "slotIndex" },
    slotIndex = { isId64 = true },
}

local function BuySortFunc(data1, data2)
    local keys = BUY_ITEMS_SORT_KEYS
    local defaultSortField = GetStoreDefaultSortField()
    if defaultSortField == STORE_DEFAULT_SORT_FIELD_VALUE then
        keys = BUY_ITEMS_SORT_KEYS_VALUE
    end
    return ZO_TableOrderingFunction(data1, data2, "bestGamepadItemCategoryName", keys, ZO_SORT_ORDER_UP)
end

local BUYBACK_ITEMS_SORT_KEYS =
{
    bestGamepadItemCategoryName = { tiebreaker = "name" },
    name = { tiebreaker = "meetsRequirementsToBuy" },
    meetsRequirementsToBuy = { tiebreaker = "meetsRequirementsToEquip", isNumeric = true },
    meetsRequirementsToEquip = { tiebreaker = "icon", isNumeric = true },
    icon = { tiebreaker = "slotIndex" },
    slotIndex = { isId64 = true },
}

local function BuybackSortFunc(data1, data2)
     return ZO_TableOrderingFunction(data1, data2, "bestGamepadItemCategoryName", BUYBACK_ITEMS_SORT_KEYS, ZO_SORT_ORDER_UP)
end

local REPAIR_ITEMS_SORT_KEYS =
{
    name = { tiebreaker = "repairCost" },
    repairCost = { tiebreaker = "condition", isNumeric = true },
    condition = { tiebreaker = "quality", isNumeric = true },
    quality = { tiebreaker = "stackCount" },
    stackCount = { tiebreaker = "slotIndex" },
    slotIndex = { isId64 = true },
}

local function RepairSortFunc(data1, data2)
     return ZO_TableOrderingFunction(data1, data2, "name", REPAIR_ITEMS_SORT_KEYS, ZO_SORT_ORDER_UP)
end

local function GetBuyItems()
    local items = ZO_StoreManager_GetStoreItems()

    --- Gamepad versions have extra data / differently named values in templates
    for i, itemData in ipairs(items) do
        itemData.pressedIcon = itemData.icon
        itemData.stackCount = itemData.stack
        itemData.sellPrice = itemData.price
        if itemData.sellPrice == 0 then
            itemData.sellPrice = itemData.stackBuyPriceCurrency1
        end
        itemData.selectedNameColor = ZO_SELECTED_TEXT
        itemData.unselectedNameColor = ZO_DISABLED_TEXT
        itemData.name = zo_strformat(SI_TOOLTIP_ITEM_NAME, itemData.name)

        itemData.itemLink = GetStoreItemLink(itemData.slotIndex)
        itemData.itemType = GetItemLinkItemType(itemData.itemLink)
        itemData.equipType = GetItemLinkEquipType(itemData.itemLink)

        itemData.storeGroup = GetItemStoreGroup(itemData)
        itemData.bestGamepadItemCategoryName = GetBestItemCategoryDescription(itemData)
        if not itemData.meetsRequirementsToBuy and (itemData.buyStoreFailure == STORE_FAILURE_ALREADY_HAVE_COLLECTIBLE or itemData.buyStoreFailure == STORE_FAILURE_AWARDS_ALREADY_OWNED_COLLECTIBLE) then
            itemData.locked = true
        end
    end

    return items
end

local function GetSellItems()
    local items = SHARED_INVENTORY:GenerateFullSlotData(nil, BAG_WORN, BAG_BACKPACK)
    local unequippedItems = {}

    --- Setup sort filter
    for i, itemData in ipairs(items) do
        if itemData.bagId ~= BAG_WORN and not itemData.stolen and not itemData.isPlayerLocked then
            itemData.isEquipped = false
            itemData.meetsRequirementsToBuy = true
            itemData.meetsRequirementsToEquip = itemData.meetsUsageRequirements

            itemData.storeGroup = GetItemStoreGroup(itemData)
            itemData.bestGamepadItemCategoryName = GetBestSellItemCategoryDescription(itemData)
            itemData.customSortOrder = itemData.sellInformationSortOrder
            table.insert(unequippedItems, itemData)
        end
    end

    return unequippedItems
end

local function GetBuybackItems()

    local items = {}
    for entryIndex = 1, GetNumBuybackItems() do
        local icon, name, stackCount, price, quality, meetsRequirementsToEquip  = GetBuybackItemInfo(entryIndex)
        if(stackCount > 0) then
            local itemLink = GetBuybackItemLink(entryIndex)
            local itemType = GetItemLinkItemType(itemLink)
            local equipType = GetItemLinkEquipType(itemLink)
            local traitInformation = GetItemTraitInformationFromItemLink(itemLink)
            local sellInformation = GetItemLinkSellInformation(itemLink)
            local totalPrice = price * stackCount
            local buybackData =
            {
                slotIndex = entryIndex,
                icon = icon,
                name = zo_strformat(SI_TOOLTIP_ITEM_NAME, name),
                stackCount = stackCount,
                price = price,
                sellPrice = totalPrice,
                quality = quality,
                meetsRequirementsToBuy = true,
                meetsRequirementsToEquip = meetsRequirementsToEquip,
                stackBuyPrice = totalPrice,
                itemLink = itemLink,
                itemType = itemType,
                equipType = equipType,
                filterData = { GetItemLinkFilterTypeInfo(itemLink) },
                traitInformation = traitInformation,
                itemTrait = GetItemLinkTraitInfo(itemLink),
                traitInformationSortOrder = ZO_GetItemTraitInformation_SortOrder(traitInformation),
                sellInformation = sellInformation,
                sellInformationSortOrder = ZO_GetItemSellInformationCustomSortOrder(sellInformation),
            }
            buybackData.storeGroup = GetItemStoreGroup(buybackData)
            buybackData.bestGamepadItemCategoryName = GetBestItemCategoryDescription(buybackData)

            table.insert(items, buybackData)
        end
    end

    return items
end

local function GatherDamagedEquipmentFromBag(bagId, itemTable)
    local bagSlots = GetBagSize(bagId)
    for slotIndex=0, bagSlots - 1 do
        local condition = GetItemCondition(bagId, slotIndex)
        if condition < 100 and not IsItemStolen(bagId, slotIndex) then
            local _, stackCount = GetItemInfo(bagId, slotIndex)
            if stackCount > 0 then
                local repairCost = GetItemRepairCost(bagId, slotIndex)
                if repairCost > 0 then
                    local damagedItem = SHARED_INVENTORY:GenerateSingleSlotData(bagId, slotIndex)
                    damagedItem.condition = condition
                    damagedItem.repairCost = repairCost
                    damagedItem.invalidPrice = repairCost > GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)
                    damagedItem.isEquippedInCurrentCategory = damagedItem.bagId == BAG_WORN
                    damagedItem.storeGroup = GetItemStoreGroup(damagedItem)
                    damagedItem.bestGamepadItemCategoryName = GetBestItemCategoryDescription(damagedItem)
                    table.insert(itemTable, damagedItem)
                end
            end
        end
    end
end

local function GetRepairItems()
    local items = {}

    GatherDamagedEquipmentFromBag(BAG_WORN, items)
    GatherDamagedEquipmentFromBag(BAG_BACKPACK, items)

    return items
end

-- optFilterFunction is an optional additional check to make when gathering all the stolen items
-- ... are bag ids to get items from
local function GetStolenItems(optFilterFunction, ...)
    local function IsStolenItem(itemData)
        local isStolen = itemData.stolen

        if optFilterFunction then
            return isStolen and optFilterFunction(itemData)
        else
            return isStolen
        end
    end

    local items = SHARED_INVENTORY:GenerateFullSlotData(IsStolenItem, ...)
    local unequippedItems = {}

    --- Setup sort filter
    for i, itemData in ipairs(items) do
        itemData.isEquipped = false
        itemData.meetsRequirementsToBuy = true
        itemData.meetsRequirementsToEquip = itemData.meetsUsageRequirements
        itemData.storeGroup = GetItemStoreGroup(itemData)
        itemData.bestGamepadItemCategoryName = GetBestItemCategoryDescription(itemData)
        table.insert(unequippedItems, itemData)
    end

    return unequippedItems
end

local function GetStolenSellItems()
    -- can't sell stolen things from BAG_WORN so just check BACKPACK
    return GetStolenItems(IsItemStolenAndSellable, BAG_BACKPACK)
end

local function GetLaunderItems()
    local NO_ADDED_FILTER = nil
    return GetStolenItems(NO_ADDED_FILTER, BAG_WORN, BAG_BACKPACK)
end

local TRAIN_ORDER = { RIDING_TRAIN_SPEED, RIDING_TRAIN_STAMINA, RIDING_TRAIN_CARRYING_CAPACITY }
local function GetStableItems()
    local items = {}
    
    local timeUntilCanBeTrained = GetTimeUntilCanBeTrained()
    local canBeTrained = timeUntilCanBeTrained == 0 and STABLE_MANAGER:CanAffordTraining()
    local header = GetString(SI_STATS_RIDING_SKILL)
    for i = 1, #TRAIN_ORDER do
        local trainingType = TRAIN_ORDER[i]
        local bonus, maxBonus = STABLE_MANAGER:GetStats(trainingType)

        local extraData = 
        {
            trainingType = trainingType,
            bonus = bonus,
            maxBonus = maxBonus,
            isSkillTrainable = canBeTrained and (bonus < maxBonus),
        }

        local itemData = 
        {
            name = GetString("SI_RIDINGTRAINTYPE", trainingType),
            iconFile = STABLE_TRAINING_TEXTURES_GAMEPAD[trainingType],
            bestGamepadItemCategoryName = header,
            ignoreStoreVisualInit = true,
            data = extraData
        }

        table.insert(items, itemData)
    end

    return items, 0, STABLE_ITEM_POST_PADDING
end

--When using the ItemSortFunc, you'll want to ensure that your updateFunc provides an itemData.bestGamepadItemCategoryName
--Typically bestGamepadItemCategoryName is acquired like so:
--e.g.: itemData.storeGroup = GetItemStoreGroup(itemData, IS_STORE_ITEM)
--      itemData.bestGamepadItemCategoryName = GetBestItemCategoryDescription(itemData)
local MODE_TO_UPDATE_FUNC = {
        [ZO_MODE_STORE_BUY] =          {updateFunc = GetBuyItems,           sortFunc = BuySortFunc},
        [ZO_MODE_STORE_BUY_BACK] =     {updateFunc = GetBuybackItems,       sortFunc = BuybackSortFunc},
        [ZO_MODE_STORE_SELL] =         {updateFunc = GetSellItems,          sortFunc = SellSortFunc},
        [ZO_MODE_STORE_REPAIR] =       {updateFunc = GetRepairItems,        sortFunc = RepairSortFunc},
        [ZO_MODE_STORE_SELL_STOLEN] =  {updateFunc = GetStolenSellItems,    sortFunc = ItemSortFunc},
        [ZO_MODE_STORE_LAUNDER] =      {updateFunc = GetLaunderItems,       sortFunc = ItemSortFunc},
        [ZO_MODE_STORE_STABLE] =       {updateFunc = GetStableItems},
    }

ZO_GamepadStoreList = ZO_GamepadVerticalParametricScrollList:Subclass()

function ZO_GamepadStoreList:New(control, mode, setupFunction, overrideTemplate, overrideHeaderTemplateSetupFunction)
    local object = ZO_GamepadVerticalParametricScrollList.New(self, control)
    object:SetMode(mode, setupFunction, overrideTemplate, overrideHeaderTemplateSetupFunction)
    return object
end

local function VendorEntryHeaderTemplateSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    control:SetText(data.bestGamepadItemCategoryName)
end

function ZO_GamepadStoreList:SetMode(mode, setupFunction, overrideTemplate, overrideHeaderTemplateSetupFunction)
    self.storeMode = mode
    self.updateFunc = MODE_TO_UPDATE_FUNC[mode].updateFunc
    self.sortFunc = MODE_TO_UPDATE_FUNC[mode].sortFunc
    self.template = overrideTemplate or "ZO_GamepadPricedVendorItemEntryTemplate"
    local headerTemplateSetupFunction = overrideHeaderTemplateSetupFunction or VendorEntryHeaderTemplateSetup

    self:AddDataTemplate(self.template, setupFunction, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self:AddDataTemplateWithHeader(self.template, setupFunction, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate", headerTemplateSetupFunction)
end

function ZO_GamepadStoreList:AddItems(items, prePaddingOverride, postPaddingOverride)
    local currentBestCategoryName = nil

    for i, itemData in ipairs(items) do
        local nextItemData = items[i + 1]
        local isNextEntryAHeader = nextItemData and nextItemData.bestGamepadItemCategoryName ~= itemData.bestGamepadItemCategoryName
        local postPadding = postPaddingOverride or (isNextEntryAHeader and STORE_ITEM_HEADER_DEFAULT_PADDING)

        local entry = ZO_GamepadEntryData:New(itemData.name, itemData.iconFile)
        
        --This is only used by stables
        local stableTrainingData = itemData.data
        if stableTrainingData then
            entry.trainingData = stableTrainingData
            local MIN_BONUS = 0
            entry:SetBarValues(MIN_BONUS, stableTrainingData.maxBonus, stableTrainingData.bonus)
            entry:SetShowBarEvenWhenUnselected(true)
        end
        
        if not itemData.ignoreStoreVisualInit then
            entry:InitializeStoreVisualData(itemData)
        end

        if itemData.locked then
            entry.enabled = false
        end
        if itemData.bestGamepadItemCategoryName and itemData.bestGamepadItemCategoryName ~= currentBestCategoryName then
            currentBestCategoryName = itemData.bestGamepadItemCategoryName
            entry:SetHeader(currentBestCategoryName)
            self:AddEntryWithHeader(self.template, entry)
        else
            self:AddEntry(self.template, entry)
        end
    end
    
    self:Commit()
end

function ZO_GamepadStoreList:UpdateList()
    self:Clear()
    local items, prePaddingOverride, postPaddingOverride = self.updateFunc()
    if self.sortFunc then
        table.sort(items, self.sortFunc)
    end
    self:AddItems(items)
end