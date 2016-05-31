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

    local function UpdateSlots_Gamepad(infoBar, bagType)
        local slotsLabel = infoBar:GetNamedChild("FreeSlots")

        local numUsedSlots = GetNumBagUsedSlots(bagType)
        local numSlots = GetBagSize(bagType)

        if numUsedSlots < numSlots then
            slotsLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        else
            slotsLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
        end

        slotsLabel:SetText(zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, numUsedSlots, numSlots))
    end

    local function InventoryInfoBar_ConnectStandardBar_Common(infoBar, options, updateInventorySlotFnc, currencyConnectFnc, bagType)
        if infoBar.isConnected then return end

        local slotsDirty = true

        local function OnInventoryUpdated()
            if infoBar:IsHidden() then
                slotsDirty = true
            else
                updateInventorySlotFnc(infoBar, bagType)
                slotsDirty = false
            end
        end

        currencyConnectFnc(infoBar:GetNamedChild("Money"), options)

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
        InventoryInfoBar_ConnectStandardBar_Common(infoBar, ZO_KEYBOARD_CARRIED_CURRENCY_OPTIONS, UpdateInventorySlots, ZO_SharedInventory_ConnectPlayerCurrencyLabel, BAG_BACKPACK)
    end

    function ZO_InventoryInfoBar_Gamepad_ConnectStandardBar(infoBar)
        InventoryInfoBar_ConnectStandardBar_Common(infoBar, ZO_GAMEPAD_CURRENCY_OPTIONS, UpdateSlots_Gamepad, ZO_SharedInventory_ConnectPlayerCurrencyLabel, BAG_BACKPACK)
    end

    function ZO_InventoryInfoBar_Gamepad_ConnectBankBar(infoBar)
        InventoryInfoBar_ConnectStandardBar_Common(infoBar, ZO_GAMEPAD_CURRENCY_OPTIONS, UpdateSlots_Gamepad, ZO_SharedInventory_ConnectBankedCurrencyLabel, BAG_BANK)
    end

    function ZO_InventoryInfoBar_Gamepad_ConnectGuildBankBar(infoBar)
        InventoryInfoBar_ConnectStandardBar_Common(infoBar, ZO_GAMEPAD_CURRENCY_OPTIONS, UpdateSlots_Gamepad, ZO_SharedInventory_ConnectGuildBankedCurrencyLabel, BAG_GUILDBANK)
    end
end