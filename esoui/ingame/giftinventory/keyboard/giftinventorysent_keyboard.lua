ZO_GiftInventorySent_Keyboard = ZO_GiftInventoryCategory_Keyboard:Subclass()

function ZO_GiftInventorySent_Keyboard:New(...)
    return ZO_GiftInventoryCategory_Keyboard.New(self, ...)
end

function ZO_GiftInventorySent_Keyboard:Initialize(control)
    ZO_GiftInventoryCategory_Keyboard.Initialize(self, control, "sent")
    
    local SENT_TYPE = 1
    self:AddSupportedGiftState(GIFT_STATE_SENT, SENT_TYPE, "ZO_GiftInventorySent_Keyboard_Row", 52, function(control, data) self:SetupSent(control, data) end)

    self.sortHeaderGroup:SelectHeaderByKey("expirationTimeStampS")
    self:SetSortFunction(function(leftEntry, rightEntry) return ZO_GiftInventory_Manager.CompareSent(leftEntry.data, rightEntry.data, self.currentSortKey, self.currentSortOrder) end)

    self:SetEmptyText(GetString(SI_GIFT_INVENTORY_NO_SENT_GIFTS))
end

function ZO_GiftInventorySent_Keyboard:SetupSent(control, gift)
    self:SetupRow(control, gift)

    local iconTexture = control:GetNamedChild("Icon")
    iconTexture:SetTexture(gift:GetIcon())

    self:SetupStackCount(control, gift)

    local nameLabel = control:GetNamedChild("Name")
    -- Override default ZO_SortFilterList default color with quality color for name
    nameLabel.normalColor = gift:GetQualityColor()
    nameLabel.selectedColor = gift:GetQualityColor()
    nameLabel:SetText(gift:GetFormattedName())

    local recipientNameLabel = control:GetNamedChild("RecipientName")
    recipientNameLabel:SetText(gift:GetUserFacingPlayerName())

    local expiresLabel = control:GetNamedChild("Expires")
    expiresLabel:SetText(ZO_FormatCountdownTimer(gift:GetSecondsUntilExpiration()))
end

function ZO_GiftInventorySent_Keyboard_Row_OnMouseEnter(self)
    GIFT_INVENTORY_SENT_KEYBOARD:Row_OnMouseEnter(self)
end

function ZO_GiftInventorySent_Keyboard_Row_OnMouseExit(self)
    GIFT_INVENTORY_SENT_KEYBOARD:Row_OnMouseExit(self)
end

function ZO_GiftInventorySent_Keyboard_Row_OnMouseUp(self, button, upInside)
    GIFT_INVENTORY_SENT_KEYBOARD:Row_OnMouseUp(self, button, upInside)
end

function ZO_GiftInventorySent_Keyboard_OnInitialized(self)
    GIFT_INVENTORY_SENT_KEYBOARD = ZO_GiftInventorySent_Keyboard:New(self)
end