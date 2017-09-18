DEFAULT_INVENTORY_FILTER_DIVIDER_TOP_OFFSET_Y = 105

do
    local function UpdateInventorySlots(infoBar)
        local slotsLabel = infoBar:GetNamedChild("FreeSlots")
        local numUsedSlots, numSlots = PLAYER_INVENTORY:GetNumSlots(INVENTORY_BACKPACK)
        if numUsedSlots < numSlots then
            slotsLabel:SetText(zo_strformat(SI_INVENTORY_BACKPACK_REMAINING_SPACES, numUsedSlots, numSlots))
        else
            slotsLabel:SetText(zo_strformat(SI_INVENTORY_BACKPACK_COMPLETELY_FULL, numUsedSlots, numSlots))
        end
    end

    local function InventoryInfoBar_ConnectStandardBar_Common(infoBar, currencyType, currencyLocation, currencyOptions, updateInventorySlotFnc, bagType)
        if infoBar.isConnected then return end

        -- setup the currency label, which will manage its own dirty state
        ZO_SharedInventory_ConnectPlayerCurrencyLabel(infoBar:GetNamedChild("Money"), currencyType, currencyLocation, currencyOptions)

        -- Setup handling for slot counts changing
        local slotsDirty = true

        local function OnInventoryUpdated()
            if infoBar:IsHidden() then
                slotsDirty = true
            else
                updateInventorySlotFnc(infoBar, bagType)
                slotsDirty = false
            end
        end

        if bagType == BAG_GUILDBANK then
            infoBar:RegisterForEvent(EVENT_GUILD_BANK_ITEM_ADDED, OnInventoryUpdated)
            infoBar:RegisterForEvent(EVENT_GUILD_BANK_ITEM_REMOVED, OnInventoryUpdated)
            infoBar:RegisterForEvent(EVENT_GUILD_BANK_UPDATED_QUANTITY, OnInventoryUpdated)
            infoBar:RegisterForEvent(EVENT_GUILD_BANK_ITEMS_READY, OnInventoryUpdated)
        else
            infoBar:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, OnInventoryUpdated)
            infoBar:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventoryUpdated)
        end

        local function CleanDirty()
            if slotsDirty then
                slotsDirty = false
                updateInventorySlotFnc(infoBar, bagType)
            end
        end

        infoBar:SetHandler("OnEffectivelyShown", CleanDirty)

        if not infoBar:IsHidden() then
            CleanDirty()
        end

        infoBar.isConnected = true
    end

    function ZO_InventoryInfoBar_ConnectStandardBar(infoBar)
        InventoryInfoBar_ConnectStandardBar_Common(infoBar, CURT_MONEY, CURRENCY_LOCATION_CHARACTER, ZO_KEYBOARD_CURRENCY_OPTIONS, UpdateInventorySlots, BAG_BACKPACK)
    end
end
