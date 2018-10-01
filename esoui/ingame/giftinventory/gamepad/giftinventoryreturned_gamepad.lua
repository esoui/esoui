ZO_GiftInventoryReturned_Gamepad = ZO_GiftInventoryCategory_Gamepad:Subclass()

function ZO_GiftInventoryReturned_Gamepad:New(...)
    return ZO_GiftInventoryCategory_Gamepad.New(self, ...)
end

function ZO_GiftInventoryReturned_Gamepad:Initialize(control)
    ZO_GiftInventoryCategory_Gamepad.Initialize(self, control)

    self:SetNoItemText(GetString(SI_GIFT_INVENTORY_NO_RETURNED_GIFTS))

    self:AddSupportedGiftState(GIFT_STATE_RETURNED, "ZO_GamepadGiftWithNoteEntryTemplate", ZO_GiftInventoryCategory_Gamepad.GiftWithNoteSetupFunction)

    table.insert(self.keybindStripDescriptor,
    {
        -- Send
        name = GetString(SI_GIFT_INVENTORY_SEND_KEYBIND),
        keybind = "UI_SHORTCUT_PRIMARY",
        visible = function()
            local targetData = self:GetTargetData()
            return targetData ~= nil
        end,
        callback = function()
            local targetData = self:GetTargetData()
            targetData.gift:View()
            targetData.gift:RequestResendGift()
            GIFT_INVENTORY_GAMEPAD:OnRequestResendGift()
        end,
    })
end

-- begin ZO_GiftInventoryCategory_Gamepad overrides

function ZO_GiftInventoryReturned_Gamepad:CreateGiftEntryData(gift)
    local formattedGiftName = gift:GetFormattedName()
    local icon = gift:GetIcon()
    local entryData = ZO_GamepadEntryData:New(formattedGiftName, icon)
    entryData:SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
    entryData:SetIconTintOnSelection(true)
    entryData:SetStackCount(gift:GetStackCount())
    local formattedPlayerName = zo_strformat(SI_GAMEPAD_GIFT_INVENTORY_FROM_FORMATTER, gift:GetUserFacingPlayerName())
    entryData:AddSubLabel(formattedPlayerName)
    entryData.gift = gift

    return entryData
end

function ZO_GiftInventoryReturned_Gamepad:UpdateTooltip()
    local selectedData = self:GetSelectedData()
    if selectedData and self.shouldShowTooltip then
        local gift = selectedData.gift
        GAMEPAD_TOOLTIPS:LayoutReturnedGift(GAMEPAD_LEFT_TOOLTIP, gift:GetName(), gift:GetUserFacingPlayerName(), gift:GetNote())
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    end
end

-- end ZO_GiftInventoryCategory_Gamepad overrides
