do
    local NO_CATEGORY_NAME = nil
    local NO_NICKNAME = nil
    local BLANK_HINT = ""
    local HIDE_VISUAL_LAYER_INFO = false
    local NO_COOLDOWN = nil
    local HIDE_BLOCK_REASON = false
    local NOT_EQUIPPED = false
    local NO_CREATOR_NAME = nil
    local FORCE_FULL_DURABILITY = true
    local NO_PREVIEW_VALUE = nil

    function ZO_Tooltip:LayoutRewardEntry(rewardId, entryIndex)
        local entryType = GetRewardEntryType(rewardId, entryIndex)
        -- For some market product types we can just use other tooltip layouts
        if entryType == REWARD_ENTRY_TYPE_COLLECTIBLE then
            local collectibleId = GetCollectibleRewardEntryCollectibleId(rewardId, entryIndex)
            local name, description, icon, _, _, isPurchasable, _, categoryType, hint, isPlaceholder = GetCollectibleInfo(collectibleId)
            self:LayoutCollectible(collectibleId, NO_CATEGORY_NAME, name, NO_NICKNAME, isPurchasable, description, BLANK_HINT, isPlaceholder, categoryType, HIDE_VISUAL_LAYER_INFO, NO_COOLDOWN, HIDE_BLOCK_REASON)
            return
        elseif entryType == REWARD_ENTRY_TYPE_ITEM then
            local stackCount = GetItemRewardEntryStackCount(rewardId, entryIndex)
            local itemLink = GetItemRewardEntryItemLink(rewardId, entryIndex)
            self:LayoutItemWithStackCount(itemLink, NOT_EQUIPPED, NO_CREATOR_NAME, FORCE_FULL_DURABILITY, NO_PREVIEW_VALUE, stackCount, EQUIP_SLOT_NONE)
            return
        elseif entryType == REWARD_ENTRY_TYPE_LOOT_CRATE then
            local crateId = GetCrownCrateRewardEntryCrateId(rewardId, entryIndex)
            local quantity = GetCrownCrateRewardEntryAmount(rewardId, entryIndex)
            self:LayoutCrownCrate(crateId, quantity)
            return
        elseif entryType == REWARD_ENTRY_TYPE_ADD_CURRENCY then
            local currencyType, amount = GetAddCurrencyRewardEntryInfo(rewardId, entryIndex)
            self:LayoutCurrency(currencyType, amount)
            return
        elseif entryType == REWARD_ENTRY_TYPE_INSTANT_UNLOCK then
            local instantUnlockId = GetInstantUnlockRewardEntryInstantUnlockId(rewardId, entryIndex)
            self:LayoutInstantUnlock(instantUnlockId)
            return
        end
    end
end
