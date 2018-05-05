ZO_GiftInventoryReceived_Gamepad = ZO_GiftInventoryCategory_Gamepad:Subclass()

function ZO_GiftInventoryReceived_Gamepad:New(...)
    return ZO_GiftInventoryCategory_Gamepad.New(self, ...)
end

function ZO_GiftInventoryReceived_Gamepad:Initialize(control)
    ZO_GiftInventoryCategory_Gamepad.Initialize(self, control)

    self:SetNoItemText(GetString(SI_GIFT_INVENTORY_NO_RECEIVED_GIFTS))

    local function SetupReceivedGift(control, data, selected, selectedDuringRebuild, enabled, activated)
        data:SetNew(not data.gift:HasBeenSeen())
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    end
    self:AddSupportedGiftState(GIFT_STATE_RECEIVED, "ZO_GamepadNewMenuEntryTemplate", SetupReceivedGift)

    local function SortFunction(leftEntry, rightEntry)
        return ZO_GiftInventory_Manager.CompareReceived(leftEntry.gift, rightEntry.gift, "seen", ZO_SORT_ORDER_UP)
    end
    self:SetGiftSortFunction(SortFunction)

    table.insert(self.keybindStripDescriptor,
    {
        -- Open Gift Claim
        name = GetString(SI_GIFT_INVENTORY_OPEN_KEYBIND),
        keybind = "UI_SHORTCUT_PRIMARY",
        visible = function()
            return self:GetTargetData() ~= nil
        end,
        callback = function()
            GIFT_INVENTORY_VIEW_GAMEPAD:SetupAndShowGift(self:GetTargetData().gift)
        end,
    })
end

function ZO_GiftInventoryReceived_Gamepad:CreateGiftEntryData(gift)
    local formattedPlayerName = zo_strformat(SI_GAMEPAD_GIFT_INVENTORY_SENDER_FORMATTER, gift:GetUserFacingPlayerName())
    local entryData = ZO_GamepadEntryData:New(formattedPlayerName, gift:GetGiftBoxIcon())
    entryData:SetModifyTextType(MODIFY_TEXT_TYPE_NONE)

    local formattedTimeLeft = ZO_FormatCountdownTimer(gift:GetSecondsUntilExpiration())
    local expiresInString = zo_strformat(SI_GAMEPAD_GIFT_INVENTORY_EXPIRES_FORMATTER, formattedTimeLeft)
    entryData:AddSubLabel(expiresInString)
    entryData:SetIconTintOnSelection(true)
    entryData.gift = gift

    return entryData
end
