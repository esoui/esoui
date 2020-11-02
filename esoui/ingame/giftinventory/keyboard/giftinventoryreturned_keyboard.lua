ZO_GiftInventoryReturned_Keyboard = ZO_GiftInventoryCategory_Keyboard:Subclass()

function ZO_GiftInventoryReturned_Keyboard:New(...)
    return ZO_GiftInventoryCategory_Keyboard.New(self, ...)
end

function ZO_GiftInventoryReturned_Keyboard:Initialize(control)
    ZO_GiftInventoryCategory_Keyboard.Initialize(self, control, "returned")
    
    local RETURNED_TYPE = 1
    self:AddSupportedGiftState(GIFT_STATE_RETURNED, RETURNED_TYPE, "ZO_GiftInventoryReturned_Keyboard_Row", 52, function(control, data) self:SetupReturned(control, data) end)

    self.sortHeaderGroup:SelectHeaderByKey("seen")
    self:SetSortFunction(function(leftEntry, rightEntry) return ZO_GiftInventory_Manager.CompareReturned(leftEntry.data, rightEntry.data, self.currentSortKey, self.currentSortOrder) end)

    self:SetEmptyText(GetString(SI_GIFT_INVENTORY_NO_RETURNED_GIFTS))

    self:SetKeybindStripDescriptor({
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        -- Send
        {
            name = GetString(SI_GIFT_INVENTORY_SEND_KEYBIND),
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function()
                return self.mouseOverRow ~= nil
            end,
            callback = function()
                self:RequestResendGift()
            end,
        },
    })
end

function ZO_GiftInventoryReturned_Keyboard:SetupReturned(control, gift)
    self:SetupRow(control, gift)

    local newTexture = control:GetNamedChild("New")
    newTexture:SetHidden(gift:HasBeenSeen())

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

    local noteButton = control:GetNamedChild("Note")
    noteButton:SetHidden(gift:GetNote() == "")
end

function ZO_GiftInventoryReturned_Keyboard:RequestResendGift()
    if self.mouseOverRow then
        local gift = ZO_ScrollList_GetData(self.mouseOverRow)
        gift:RequestResendGift()
    end
end

-- Begin Global XML Functions --

function ZO_GiftInventoryReturned_Keyboard_Row_OnMouseEnter(control)
    GIFT_INVENTORY_RETURNED_KEYBOARD:Row_OnMouseEnter(control)
end

function ZO_GiftInventoryReturned_Keyboard_Row_OnMouseExit(control)
    GIFT_INVENTORY_RETURNED_KEYBOARD:Row_OnMouseExit(control)
end

function ZO_GiftInventoryReturned_Keyboard_Row_OnMouseUp(control, button, upInside)
    GIFT_INVENTORY_RETURNED_KEYBOARD:Row_OnMouseUp(control, button, upInside)
end

function ZO_GiftInventoryReturned_Keyboard_Row_OnMouseDoubleClick(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        GIFT_INVENTORY_RETURNED_KEYBOARD:RequestResendGift()
    end
end

function ZO_GiftInventoryReturned_Keyboard_OnInitialized(control)
    GIFT_INVENTORY_RETURNED_KEYBOARD = ZO_GiftInventoryReturned_Keyboard:New(control)
end

-- End Global XML Functions --