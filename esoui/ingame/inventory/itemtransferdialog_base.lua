ZO_ItemTransferDialog_Base = ZO_Object:Subclass()

function ZO_ItemTransferDialog_Base:New(...)
    local dialog = ZO_Object.New(self)
    dialog:Initialize(...)
    return dialog
end

function ZO_ItemTransferDialog_Base:Initialize()
end

function ZO_ItemTransferDialog_Base:GetTransferMaximum()
    if self.bag ~= nil then
        local stackSize, maxStackSize = GetSlotStackSize(self.bag, self.slotIndex)
        if stackSize >= maxStackSize then
            stackSize = maxStackSize
        end
        return stackSize
    else
        return 1
    end
end

function ZO_ItemTransferDialog_Base:StartTransfer(bag, slotIndex, targetBag)
    self.bag = bag
    self.slotIndex = slotIndex
    self.targetBag = targetBag
    self:ShowDialog()
end

function ZO_ItemTransferDialog_Base:Transfer(quantity)
    if quantity > 0 then
        PickupInventoryItem(self.bag, self.slotIndex, quantity)
        if self.targetBag ~= BAG_VIRTUAL then
            TryPlaceInventoryItemInEmptySlot(self.targetBag)
        else
            PlaceInInventory(BAG_VIRTUAL, 0)
        end
    end
end

function ZO_ItemTransferDialog_Base:ShowDialog()
    assert(false) -- must be overridden (or else we have no funcitonality)
end
