ZO_MAIL_EMPTY_SLOT_TEXTURE = "EsoUI/Art/Mail/mail_attachment_empty.dds"
local g_pendingAttachments = nil
local g_pendingGold = nil

function ZO_MailSendShared_AddAttachedItem(attachSlot, slot)
    local bagId, slotIndex, icon, stack = GetQueuedItemAttachmentInfo(attachSlot)
	local soundCategory = GetItemSoundCategory(bagId, slotIndex)

	PlayItemSound(soundCategory, ITEM_SOUND_ACTION_EQUIP)
    
    slot.bagId = bagId
    slot.slotIndex = slotIndex
    slot:SetHidden(false)
    ZO_Inventory_SetupSlot(slot, stack, icon)
    ZO_InventorySlot_HandleInventoryUpdate(slot)
end

function ZO_MailSendShared_RemoveAttachedItem(attachSlot, slot)
    local soundCategory = GetItemSoundCategory(slot.bagId, slot.slotIndex)
	PlayItemSound(soundCategory, ITEM_SOUND_ACTION_UNEQUIP)
    
    slot:SetHidden(true)    
    ZO_Inventory_BindSlot(slot, SLOT_TYPE_MAIL_QUEUED_ATTACHMENT, attachSlot)
    ZO_Inventory_SetupSlot(slot, 0, ZO_MAIL_EMPTY_SLOT_TEXTURE)
    
    ZO_InventorySlot_HandleInventoryUpdate(slot)
end

function ZO_MailSendShared_SavePendingMail()
    if(g_pendingAttachments == nil) then
        g_pendingAttachments = {}
        for i = 1, MAIL_MAX_ATTACHED_ITEMS do
            local bagId, slotIndex, icon, stack = GetQueuedItemAttachmentInfo(i)
            if(stack > 0) then
                g_pendingAttachments[i] = {
                    bagId = bagId,
                    slotIndex = slotIndex,
                    itemInstanceId = GetItemInstanceId(bagId, slotIndex),
                    stackSize = stack, 
                    icon = icon
                }
                RemoveQueuedItemAttachment(i)
            end
        end
        g_pendingGold = GetQueuedMoneyAttachment()
    end
end

function ZO_MailSendShared_RestorePendingMail(manager)
    if(g_pendingAttachments) then
        for attachmentSlot, pendingAttachment in pairs(g_pendingAttachments) do
            local sameItemInSlot = GetItemInstanceId(pendingAttachment.bagId, pendingAttachment.slotIndex) == pendingAttachment.itemInstanceId
            local sameStackSize = GetSlotStackSize(pendingAttachment.bagId, pendingAttachment.slotIndex) == pendingAttachment.stackSize
            if(sameItemInSlot and sameStackSize) then
                QueueItemAttachment(pendingAttachment.bagId, pendingAttachment.slotIndex, attachmentSlot)
            else
                manager.pendingMailChanged = true
            end
        end
        if(g_pendingGold ~= GetQueuedMoneyAttachment()) then
            manager.pendingMailChanged = true
        end
        g_pendingAttachments = nil
        g_pendingGold = nil
    end
end
