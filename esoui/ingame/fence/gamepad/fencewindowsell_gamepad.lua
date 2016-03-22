ZO_GamepadFenceSell = ZO_GamepadFenceComponent:Subclass()

function ZO_GamepadFenceSell:New(...)
    return ZO_GamepadFenceComponent.New(self, ...)
end

function ZO_GamepadFenceSell:Initialize()
    ZO_GamepadFenceComponent.Initialize(self, ZO_MODE_STORE_SELL_STOLEN, GetString(SI_STORE_MODE_SELL))

    self:InitializeKeybindStrip(GetString(SI_ITEM_ACTION_SELL))
    self:CreateModeData(SI_STORE_MODE_SELL, self.mode, "EsoUI/Art/Vendor/vendor_tabIcon_sell_up.dds", fragment, self.keybindStripDescriptor)
    self.list:SetNoItemText(GetString(SI_GAMEPAD_NO_STOLEN_ITEMS_SELL))
end

function ZO_GamepadFenceSell:GetRemainingSells()
    local totalSells, sellsUsed = GetFenceSellTransactionInfo()
    return zo_max(totalSells - sellsUsed, 0)
end

do
    local IGNORE_INVALID_COST = true
    function ZO_GamepadFenceSell:Confirm()
        local remainingSells = self:GetRemainingSells()

        if remainingSells == 0 then
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, GetString("SI_STOREFAILURE", STORE_FAILURE_AT_FENCE_LIMIT))
            return
        end

        local targetData = self.list:GetTargetData()
        local itemData = {}
        itemData.bag, itemData.slot = ZO_Inventory_GetBagAndIndex(targetData)
        itemData.itemName = targetData.text
        itemData.quality = select(8, GetItemInfo(itemData.bag, itemData.slot))
        itemData.stackCount = targetData.stackCount

        if self.confirmationMode then
            itemData.stackCount = STORE_WINDOW_GAMEPAD:GetSpinnerValue()
            if itemData.stackCount > 0 then
                if itemData.quality >= ITEM_QUALITY_ARCANE then
                    ZO_Dialogs_ShowGamepadDialog("CANT_BUYBACK_FROM_FENCE", itemData)
                else
                    SellInventoryItem(itemData.bag, itemData.slot, itemData.stackCount)
                end
                self:UnselectItem()
            end
        else
            if itemData.stackCount > 1 then
                self:SelectItem(IGNORE_INVALID_COST)
                local spinnerMax = zo_min(itemData.stackCount, remainingSells)
                local calcSellPrice = GetItemSellValueWithBonuses(itemData.bag, itemData.slot)
                STORE_WINDOW_GAMEPAD:SetupSpinner(spinnerMax, spinnerMax, calcSellPrice, targetData.currencyType1)
            else
                if itemData.quality >= ITEM_QUALITY_ARCANE then
                    ZO_Dialogs_ShowGamepadDialog("CANT_BUYBACK_FROM_FENCE", itemData)
                else
                    SellInventoryItem(itemData.bag, itemData.slot, 1)
                end
            end
        end
    end
end

function ZO_GamepadFenceSell:RefreshFooter()
    self:ClearFooter()

    local data = {}
    local hagglingSkillLevel = FENCE_MANAGER:GetHagglingBonus()
    if hagglingSkillLevel > 0 then
        data.data1HeaderText = GetString(SI_GAMEPAD_FENCE_HAGGLING_SKILL_NAME)
        data.data1Text = zo_strformat(SI_GAMEPAD_FENCE_HAGGLING_BONUS, hagglingSkillLevel)
        data.data1Color = ZO_CURRENCY_HIGHLIGHT_TEXT
    end

    if self:GetRemainingSells() == 0 then
        local footerLabel = GetString(SI_FENCE_SELL_LIMIT_RESET)
        local resetTimeSeconds = select(3, GetFenceSellTransactionInfo())
        local footerValue = ZO_FormatTimeMilliseconds(resetTimeSeconds * 1000, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)

        if hagglingSkillLevel > 0 then
            data.data2HeaderText = footerLabel
            data.data2Text = footerValue
        else
            data.data1HeaderText = footerLabel
            data.data1Text = footerValue
        end
    end
    
    GAMEPAD_GENERIC_FOOTER:Refresh(data)
end

function ZO_GamepadFenceSell:SetupEntry(control, data, selected, selectedDuringRebuild, enabled, activated)
    local calcSellPrice = GetItemSellValueWithBonuses(data.bagId, data.slotIndex)
    if self.confirmationMode and selected then
        calcSellPrice = calcSellPrice * STORE_WINDOW_GAMEPAD:GetSpinnerValue()
    end
    self:SetupStoreItem(control, data, selected, selectedDuringRebuild, enabled, activated, calcSellPrice, ZO_STORE_FORCE_VALID_PRICE, self.mode)
end

function ZO_GamepadFenceSell_Initialize()
    FENCE_SELL_GAMEPAD = ZO_GamepadFenceSell:New()
    STORE_WINDOW_GAMEPAD:AddComponent(FENCE_SELL_GAMEPAD)
end

function ZO_GamepadFenceSell:GetCurrencyOptions()
    return ZO_GAMEPAD_FENCE_CURRENCY_OPTIONS
end