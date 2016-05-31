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
