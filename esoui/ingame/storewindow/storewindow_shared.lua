-- Globals
ZO_MODE_STORE_BUY              = 1
ZO_MODE_STORE_BUY_BACK         = 2
ZO_MODE_STORE_SELL             = 3
ZO_MODE_STORE_REPAIR           = 4
ZO_MODE_STORE_SELL_STOLEN      = 5
ZO_MODE_STORE_LAUNDER          = 6
ZO_MODE_STORE_STABLE           = 7

ZO_STORE_WINDOW_MODE_NORMAL = 1
ZO_STORE_WINDOW_MODE_STABLE = 2

STORE_INTERACTION =
{
    type = "Store",
    interactTypes = { INTERACTION_VENDOR, INTERACTION_STABLE },
}

-- Shared object
ZO_SharedStoreManager = ZO_Object:Subclass()

function ZO_SharedStoreManager:InitializeStore()
    self.storeUsesMoney, self.storeUsesAP, self.storeUsesTelvarStones, self.storeUsesWritVouchers = GetStoreCurrencyTypes()
end

function ZO_SharedStoreManager:RefreshCurrency()
    self.currentMoney = GetCarriedCurrencyAmount(CURT_MONEY)
    self.currentAP = GetCarriedCurrencyAmount(CURT_ALLIANCE_POINTS)
    self.currentTelvarStones = GetCarriedCurrencyAmount(CURT_TELVAR_STONES)
    self.currentWritVouchers = GetCarriedCurrencyAmount(CURT_WRIT_VOUCHERS)
end

-- Shared global functions
function ZO_StoreManager_GetStoreItems()
    local items = {}
    local usedFilterTypes = {}

    for entryIndex = 1, GetNumStoreItems() do
        local icon, name, stack, price, sellPrice, meetsRequirementsToBuy, meetsRequirementsToEquip, quality, questNameColor, currencyType1, currencyQuantity1,
            currencyType2, currencyQuantity2, entryType = GetStoreEntryInfo(entryIndex)

        if stack > 0 then
            local itemData =
            {
                entryType = entryType,
                slotIndex = entryIndex,
                icon = icon,
                name = name,
                stack = stack,
                price = price,
                sellPrice = sellPrice,
                meetsRequirementsToBuy = meetsRequirementsToBuy,
                meetsRequirementsToEquip = meetsRequirementsToEquip,
                quality = quality,
                questNameColor = questNameColor,
                currencyType1 = currencyType1,
                currencyQuantity1 = currencyQuantity1,
                currencyType2 = currencyType2,
                currencyQuantity2 = currencyQuantity2,
                stackBuyPrice = stack * price,
                stackBuyPriceCurrency1 = stack * currencyQuantity1,
                stackBuyPriceCurrency2 = stack * currencyQuantity2,
                filterData = { GetStoreEntryTypeInfo(entryIndex) },
                statValue = GetStoreEntryStatValue(entryIndex),
                isUnique = IsItemLinkUnique(GetStoreItemLink(entryIndex)),
            }

            items[#items + 1] = itemData
            for i = 1, #itemData.filterData do
                usedFilterTypes[itemData.filterData[i]] = true
            end
        end
    end

    return items, usedFilterTypes
end

function ZO_StoreManager_GetStoreFilterTypes()
    local usedFilterTypes = {}
    for entryIndex = 1, GetNumStoreItems() do
        local filterData = { GetStoreEntryTypeInfo(entryIndex) }
        for i = 1, #filterData do
            usedFilterTypes[filterData[i]] = true
        end
    end
    return usedFilterTypes
end

local CURRENCY_TYPE_TO_SOUND_ID =
{
    [CURT_TELVAR_STONES] = SOUNDS.TELVAR_TRANSACT,
    [CURT_ALLIANCE_POINTS] = SOUNDS.ALLIANCE_POINT_TRANSACT,
    [CURT_WRIT_VOUCHERS] = SOUNDS.WRIT_VOUCHER_TRANSACT,
}

local function PlayItemAcquisitionSound(eventId, itemSoundCategory, specialCurrencyType1, specialCurrencyType2)
    --As of right now there are no stores that use both special currency types and it doesn't make sense
    --to play two currency transact sounds at once, so we only only keying off type1 for now.
    local soundId = CURRENCY_TYPE_TO_SOUND_ID[specialCurrencyType1]
    if soundId then
        PlaySound(soundId)
    else
        PlaySound(SOUNDS.ITEM_MONEY_CHANGED)
    end
end

function ZO_StoreManager_OnPurchased(eventId, entryName, entryType, entryQuantity, money, specialCurrencyType1, specialCurrencyInfo1, specialCurrencyQuantity1, specialCurrencyType2, specialCurrencyInfo2, specialCurrencyQuantity2, itemSoundCategory)
    PlayItemAcquisitionSound(eventId, itemSoundCategory, specialCurrencyType1, specialCurrencyType2)
end
