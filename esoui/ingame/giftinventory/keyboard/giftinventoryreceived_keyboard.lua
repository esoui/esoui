ZO_GiftInventoryReceived_Keyboard = ZO_GiftInventoryCategory_Keyboard:Subclass()

function ZO_GiftInventoryReceived_Keyboard:New(...)
    return ZO_GiftInventoryCategory_Keyboard.New(self, ...)
end

function ZO_GiftInventoryReceived_Keyboard:Initialize(control)
    ZO_GiftInventoryCategory_Keyboard.Initialize(self, control, "received")
    
    local RECEIVED_TYPE = 1
    self:AddSupportedGiftState(GIFT_STATE_RECEIVED, RECEIVED_TYPE, "ZO_GiftInventoryReceived_Keyboard_Row", 52, function(control, data) self:SetupReceived(control, data) end)

    self.sortHeaderGroup:SelectHeaderByKey("seen")
    self:SetSortFunction(function(leftEntry, rightEntry) return ZO_GiftInventory_Manager.CompareReceived(leftEntry.data, rightEntry.data, self.currentSortKey, self.currentSortOrder) end)

    self:SetEmptyText(GetString(SI_GIFT_INVENTORY_NO_RECEIVED_GIFTS))

    self:SetKeybindStripDescriptor({
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        -- Open Gift Claim
        {
            name = GetString(SI_GIFT_INVENTORY_OPEN_KEYBIND),
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function()
                return self.mouseOverRow ~= nil
            end,
            callback = function()
                self:OpenGift()
            end,
        }
    })
end

function ZO_GiftInventoryReceived_Keyboard:SetupReceived(control, gift)
    self:SetupRow(control, gift)

    local newTexture = control:GetNamedChild("New")
    newTexture:SetHidden(gift:HasBeenSeen())

    local iconTexture = control:GetNamedChild("Icon")
    iconTexture:SetTexture(gift:GetGiftBoxIcon())

    local senderNameLabel = control:GetNamedChild("SenderName")
    senderNameLabel:SetText(gift:GetUserFacingPlayerName())

    local expiresLabel = control:GetNamedChild("Expires")
    expiresLabel:SetText(ZO_FormatCountdownTimer(gift:GetSecondsUntilExpiration()))
end

function ZO_GiftInventoryReceived_Keyboard:OpenGift()
    if self.mouseOverRow then
        local gift = ZO_ScrollList_GetData(self.mouseOverRow)
        GIFT_INVENTORY_VIEW_KEYBOARD:SetupAndShowGift(gift)
    end
end

-- Begin Global XML Functions --

function ZO_GiftInventoryReceived_Keyboard_Row_OnMouseEnter(control)
    GIFT_INVENTORY_RECEIVED_KEYBOARD:Row_OnMouseEnter(control)
end

function ZO_GiftInventoryReceived_Keyboard_Row_OnMouseExit(control)
    GIFT_INVENTORY_RECEIVED_KEYBOARD:Row_OnMouseExit(control)
end

function ZO_GiftInventoryReceived_Keyboard_Row_OnMouseUp(control, button, upInside)
    GIFT_INVENTORY_RECEIVED_KEYBOARD:Row_OnMouseUp(control, button, upInside)
end

function ZO_GiftInventoryReceived_Keyboard_Row_OnMouseDoubleClick(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        GIFT_INVENTORY_RECEIVED_KEYBOARD:OpenGift()
    end
end

function ZO_GiftInventoryReceived_Keyboard_OnInitialized(control)
    GIFT_INVENTORY_RECEIVED_KEYBOARD = ZO_GiftInventoryReceived_Keyboard:New(control)
end

-- End Global XML Functions --