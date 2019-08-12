function ZO_GetNextBagSlotIndex(bagId, slotIndex)
    if bagId == BAG_GUILDBANK then
        return GetNextGuildBankSlotId(slotIndex)
    elseif bagId == BAG_VIRTUAL then
        return GetNextVirtualBagSlotId(slotIndex)
    else
        if slotIndex == nil then
            return 0
        end

        local bagSlots = GetBagSize(bagId)
        if slotIndex < (bagSlots - 1) then
            return slotIndex + 1
        else
            return nil
        end
    end
end

do
    -- reminder, iterator functions take `state, index` and return `index, ...`
    local function GetNextSlotForGuildBank(_, slotIndex)
        return GetNextGuildBankSlotId(slotIndex)
    end

    local function GetNextSlotForVirtualBag(_, slotIndex)
        return GetNextVirtualBagSlotId(slotIndex)
    end

    local function GetNextSlotForSizedBag(lastSlotIndex, slotIndex)
        if slotIndex < lastSlotIndex then
            return slotIndex + 1
        else
            return nil
        end
    end

    -- reminder: this iterator factory returns `iterator, state, initialIndex`
    function ZO_IterateBagSlots(bagId)
        if bagId == BAG_GUILDBANK then
            return GetNextSlotForGuildBank, nil, nil
        elseif bagId == BAG_VIRTUAL then
            return GetNextSlotForVirtualBag, nil, nil
        else
            local lastSlotIndex = GetBagSize(bagId) - 1
            return GetNextSlotForSizedBag, lastSlotIndex, -1 -- start at -1, so the first iteration is 0
        end
    end
end
