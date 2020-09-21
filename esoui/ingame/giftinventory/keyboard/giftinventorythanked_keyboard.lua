ZO_GiftInventoryThanked_Keyboard = ZO_GiftInventoryCategory_Keyboard:Subclass()

function ZO_GiftInventorySent_Keyboard:New(...)
    return ZO_GiftInventoryCategory_Keyboard.New(self, ...)
end

function ZO_GiftInventoryThanked_Keyboard:Initialize(control)
    ZO_GiftInventoryCategory_Keyboard.Initialize(self, control, "thanked")
    
    local THANKED_TYPE = 1
    self:AddSupportedGiftState(GIFT_STATE_THANKED, THANKED_TYPE, "ZO_GiftInventoryThanked_Keyboard_Row", 52, function(control, data) self:SetupThanked(control, data) end)

    self.sortHeaderGroup:SelectHeaderByKey("seen")
    self:SetSortFunction(function(leftEntry, rightEntry) return ZO_GiftInventory_Manager.CompareSent(leftEntry.data, rightEntry.data, self.currentSortKey, self.currentSortOrder) end)

    self:SetEmptyText(GetString(SI_GIFT_INVENTORY_NO_SENT_GIFTS))

    self:SetKeybindStripDescriptor({
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        -- Delete gift
        {
            name = GetString(SI_GIFT_INVENTORY_DELETE_KEYBIND),
            keybind = "UI_SHORTCUT_NEGATIVE",
            visible = function()
                return self.mouseOverRow ~= nil
            end,
            callback = function()
                local gift = ZO_ScrollList_GetData(self.mouseOverRow)
                if gift then
                    gift:View()
                    ZO_Dialogs_ShowDialog("CONFIRM_DELETE_GIFT_KEYBOARD", gift)
                end
            end,
        },

        -- View gift
        {
            name = GetString(SI_GIFT_INVENTORY_VIEW_KEYBIND),
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function()
                if self.mouseOverRow then
                    local gift = ZO_ScrollList_GetData(self.mouseOverRow)
                    return gift:GetNote() ~= ""
                end
                return false
            end,
            callback = function()
                self:ViewGift()
            end,
        },
    })
end

function ZO_GiftInventoryThanked_Keyboard:SetupThanked(control, gift)
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

    local expiresLabel = control:GetNamedChild("Expires")
    expiresLabel:SetText(ZO_FormatCountdownTimer(gift:GetSecondsUntilExpiration()))

    local noteButton = control:GetNamedChild("Note")
    noteButton:SetHidden(gift:GetNote() == "")
end

function ZO_GiftInventoryThanked_Keyboard:ViewGift()
    if self.mouseOverRow then
        local gift = ZO_ScrollList_GetData(self.mouseOverRow)
        if gift:GetNote() ~= "" then
            GIFT_INVENTORY_VIEW_KEYBOARD:SetupAndShowGift(gift)
        end
    end
end

-- Begin Global XML Functions --

function ZO_GiftInventoryThanked_Keyboard_Row_OnMouseEnter(self)
    GIFT_INVENTORY_THANKED_KEYBOARD:Row_OnMouseEnter(self)
end

function ZO_GiftInventoryThanked_Keyboard_Row_OnMouseExit(self)
    GIFT_INVENTORY_THANKED_KEYBOARD:Row_OnMouseExit(self)
end

function ZO_GiftInventoryThanked_Keyboard_Row_OnMouseUp(self, button, upInside)
    GIFT_INVENTORY_THANKED_KEYBOARD:Row_OnMouseUp(self, button, upInside)
end

function ZO_GiftInventoryThanked_Keyboard_Row_OnMouseDoubleClick(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        GIFT_INVENTORY_THANKED_KEYBOARD:ViewGift()
    end
end

function ZO_GiftInventoryThanked_Keyboard_OnInitialized(self)
    GIFT_INVENTORY_THANKED_KEYBOARD = ZO_GiftInventoryThanked_Keyboard:New(self)
end

-- End Global XML Functions --