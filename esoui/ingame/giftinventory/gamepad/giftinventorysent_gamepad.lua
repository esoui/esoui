ZO_GiftInventorySent_Gamepad = ZO_GiftInventoryCategory_Gamepad:Subclass()

function ZO_GiftInventorySent_Gamepad:New(...)
    return ZO_GiftInventoryCategory_Gamepad.New(self, ...)
end

function ZO_GiftInventorySent_Gamepad:Initialize(control)
    ZO_GiftInventoryCategory_Gamepad.Initialize(self, control)

    self:SetNoItemText(GetString(SI_GIFT_INVENTORY_NO_SENT_GIFTS))

    self:AddSupportedGiftState(GIFT_STATE_SENT, "ZO_GamepadMenuEntryTemplate")
    self:AddSupportedGiftState(GIFT_STATE_THANKED, "ZO_GamepadGiftWithNoteEntryTemplate", ZO_GiftInventoryCategory_Gamepad.GiftWithNoteSetupFunction)

    local function SortFunction(leftEntry, rightEntry)
        return ZO_GiftInventory_Manager.CompareSent(leftEntry.gift, rightEntry.gift, "state", ZO_SORT_ORDER_UP)
    end
    self:SetGiftSortFunction(SortFunction)

    table.insert(self.keybindStripDescriptor,
    {
        -- View thanked gift
        name = GetString(SI_GIFT_INVENTORY_VIEW_KEYBIND),
        keybind = "UI_SHORTCUT_PRIMARY",
        visible = function()
            local targetData = self:GetTargetData()
            if targetData then
                local gift = targetData.gift
                return gift:IsState(GIFT_STATE_THANKED) and gift:GetNote() ~= ""
            end
            return false
        end,
        callback = function()
            GIFT_INVENTORY_VIEW_GAMEPAD:SetupAndShowGift(self:GetTargetData().gift)
        end,
    })

    table.insert(self.keybindStripDescriptor,
    {
        -- Delete thanked gift
        name = GetString(SI_GIFT_INVENTORY_DELETE_KEYBIND),
        keybind = "UI_SHORTCUT_RIGHT_STICK",
        visible = function()
            local targetData = self:GetTargetData()
            if targetData then
                local gift = targetData.gift
                return gift:IsState(GIFT_STATE_THANKED)
            end
            return false
        end,
        callback = function()
            local gift = self:GetTargetData().gift
            gift:View()
            ZO_Dialogs_ShowGamepadDialog("CONFIRM_DELETE_GIFT_GAMEPAD", { gift = gift })
        end,
    })
end

function ZO_GiftInventorySent_Gamepad:CreateGiftEntryData(gift)
    local formattedGiftName = gift:GetFormattedName()
    local icon = gift:GetIcon()
    local entryData = ZO_GamepadEntryData:New(formattedGiftName, icon)
    entryData:SetIconTintOnSelection(true)
    entryData:SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
    entryData:SetStackCount(gift:GetStackCount())
    entryData.gift = gift

    local header
    if gift:GetState() == GIFT_STATE_SENT then
        header = GetString(SI_GIFT_INVENTORY_UNCLAIMED_GIFTS_HEADER)
    elseif gift:GetState() == GIFT_STATE_THANKED then
        header = GetString(SI_GIFT_INVENTORY_CLAIMED_GIFTS_HEADER)
    end

    local userFacingDisplayName = gift:GetUserFacingPlayerName()
    local formattedPlayerName = zo_strformat(SI_GAMEPAD_GIFT_INVENTORY_TO_FORMATTER, userFacingDisplayName)
    entryData:AddSubLabel(formattedPlayerName)

    local formattedTimeLeft = ZO_FormatCountdownTimer(gift:GetSecondsUntilExpiration())
    local expiresInString = zo_strformat(SI_GAMEPAD_GIFT_INVENTORY_EXPIRES_FORMATTER, formattedTimeLeft)
    entryData:AddSubLabel(expiresInString)

    entryData.suggestedHeader = header

    return entryData
end
