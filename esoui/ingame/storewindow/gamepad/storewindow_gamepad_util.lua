local STORE_ITEM_HEADER_DEFAULT_PADDING = 60
local STORE_ITEM_HEADER_SELECTED_DEFAULT_PADDING = 0
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
local STORE_OTHER_GROUP = 10

local groupCategoryDictionary = {
    [STORE_WEAPON_GROUP] = GAMEPAD_ITEM_CATEGORY_WEAPONS,
    [STORE_HEAVY_ARMOR_GROUP] = GAMEPAD_ITEM_CATEGORY_HEAVY_ARMOR,
    [STORE_MEDIUM_ARMOR_GROUP] = GAMEPAD_ITEM_CATEGORY_MEDIUM_ARMOR,
    [STORE_LIGHT_ARMOR_GROUP] = GAMEPAD_ITEM_CATEGORY_LIGHT_ARMOR,
    [STORE_JEWELRY_GROUP] = GAMEPAD_ITEM_CATEGORY_JEWELRY
}

-------------------
--Utility functions
-------------------


local function GetItemStoreGroup(itemData)
    if itemData.entryType == STORE_ENTRY_TYPE_COLLECTIBLE then
        return STORE_COLLECTIBLE_GROUP
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
    else
        return ZO_InventoryUtils_Gamepad_GetBestItemCategoryDescription(itemData)
    end
end

local defaultSortKeys =
{
    bestGamepadItemCategoryName = { tiebreaker = "name" },
    name = { tiebreaker = "requiredLevel" },
    requiredLevel = { tiebreaker = "requiredChampionPoints", isNumeric = true },
    requiredChampionPoints = { tiebreaker = "iconFile", isNumeric = true },
    iconFile = { tiebreaker = "uniqueId" },
    uniqueId = { isId64 = true },
}

local function ItemSortFunc(data1, data2)
     return ZO_TableOrderingFunction(data1, data2, "bestGamepadItemCategoryName", defaultSortKeys, ZO_SORT_ORDER_UP)
end

local BagSortKeys = 
{
    name = { },
    bagId = { tiebreaker = "name", isNumeric = true },
}

local function BagItemSortFunc(item1, item2)
    return ZO_TableOrderingFunction(item1, item2, "bagId", BagSortKeys, ZO_SORT_ORDER_UP)
end

local function GetItemFilterName(filterTable)
    local displayFilter = ITEMFILTERTYPE_MISCELLANEOUS
    for j,filter in ipairs(filterTable) do
        if filter >= ITEMFILTERTYPE_WEAPONS and filter <= ITEMFILTERTYPE_MISCELLANEOUS then
            displayFilter = filter
            break
        end
    end

    return displayFilter
end

local function GetBuyItems()
    local items, usedFilterTypes = ZO_StoreManager_GetStoreItems()

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
        if itemData.entryType == STORE_ENTRY_TYPE_COLLECTIBLE then
            itemData.locked = select(2, GetStoreCollectibleInfo(itemData.slotIndex))
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
            itemData.bestGamepadItemCategoryName = GetBestItemCategoryDescription(itemData)
            table.insert(unequippedItems, itemData)
        end
    end

    return unequippedItems
end

local function GetBuybackItems()
    local bagId = BAG_BUYBACK

    local items = {}
    for entryIndex = 1, GetNumBuybackItems() do
        local icon, name, stackCount, price, quality, meetsRequirementsToEquip  = GetBuybackItemInfo(entryIndex)
        if(stackCount > 0) then
            local itemLink = GetBuybackItemLink(entryIndex)
            local itemType = GetItemLinkItemType(itemLink)
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
                bagId = bagId,
                itemLink = itemLink,
                itemType = itemType,
                filterData = { GetItemFilterTypeInfo(bagId, entryIndex) },
            }
            buybackData.storeGroup = GetItemStoreGroup(buybackData)
            buybackData.bestGamepadItemCategoryName = GetBestItemCategoryDescription(buybackData)

            table.insert(items, buybackData)
        end
    end

    return items
end

local function GatherDamagedEquipmentFromBag(bagId, itemTable)
    local slotType = SLOT_TYPE_REPAIR
    local bagSlots = GetBagSize(bagId)
    for slotIndex=0, bagSlots - 1 do
        local condition = GetItemCondition(bagId, slotIndex)
        if condition < 100 and not IsItemStolen(bagId, slotIndex) then
            local icon, stackCount, _, _, _, _, _, quality = GetItemInfo(bagId, slotIndex)
            if stackCount > 0 then
                local repairCost = GetItemRepairCost(bagId, slotIndex)
                if repairCost > 0 then
                    local damagedItem = SHARED_INVENTORY:GenerateSingleSlotData(bagId, slotIndex)
                    damagedItem.condition = condition
                    damagedItem.repairCost = repairCost
                    damagedItem.invalidPrice = repairCost > GetCarriedCurrencyAmount(CURT_MONEY)
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

local function IsStolenItemSellable(itemData)
    return itemData.sellPrice > 0
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
--When using the BagItemSortFunc you'll want to ensure that your updateFunc does *NOT* provide an itemData.bestGamepadItemCategoryName
--Typically bestGamepadItemCategoryName is acquired like so:
--e.g.: itemData.storeGroup = GetItemStoreGroup(itemData, IS_STORE_ITEM)
--      itemData.bestGamepadItemCategoryName = GetBestItemCategoryDescription(itemData)
local MODE_TO_UPDATE_FUNC = {
        [ZO_MODE_STORE_BUY] =          {updateFunc = GetBuyItems,           sortFunc = ItemSortFunc},
        [ZO_MODE_STORE_BUY_BACK] =     {updateFunc = GetBuybackItems,       sortFunc = ItemSortFunc},
        [ZO_MODE_STORE_SELL] =         {updateFunc = GetSellItems,          sortFunc = ItemSortFunc},
        [ZO_MODE_STORE_REPAIR] =       {updateFunc = GetRepairItems,        sortFunc = ItemSortFunc},
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
        entry.data = itemData.data
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