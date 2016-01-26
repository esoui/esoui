ZO_GamepadFenceLaunder = ZO_GamepadFenceComponent:Subclass()

function ZO_GamepadFenceLaunder:New(...)
    return ZO_GamepadFenceComponent.New(self, ...)
end

function ZO_GamepadFenceLaunder:Initialize()
    ZO_GamepadFenceComponent.Initialize(self, ZO_MODE_STORE_LAUNDER, GetString(SI_FENCE_LAUNDER_TAB))

    self:InitializeKeybindStrip(GetString(SI_ITEM_ACTION_LAUNDER))
    self:CreateModeData(SI_FENCE_LAUNDER_TAB, self.mode, "EsoUI/Art/Vendor/vendor_tabIcon_fence_up.dds", fragment, self.keybindStripDescriptor)
    self.list:SetNoItemText(GetString(SI_GAMEPAD_NO_STOLEN_ITEMS_LAUNDER))
end

function ZO_GamepadFenceLaunder:Confirm()
    local totalLaunders, laundersUsed = GetFenceLaunderTransactionInfo()
    local remainingLaunders = zo_max(totalLaunders - laundersUsed, 0)

    if remainingLaunders == 0 then
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, GetString("SI_ITEMLAUNDERRESULT", ITEM_LAUNDER_RESULT_AT_LIMIT))
        return
    end

    local targetData = self.list:GetTargetData()
    local bag, index = ZO_Inventory_GetBagAndIndex(targetData)

    if self.confirmationMode then
        local quantity = STORE_WINDOW_GAMEPAD:GetSpinnerValue()
        if quantity > 0 then
            LaunderItem(bag, index, quantity)
            self:UnselectItem()
        end
    else
        if targetData.stackCount > 1 then
            self:SelectItem()
            local spinnerMax = zo_min(targetData.stackCount, remainingLaunders)
            STORE_WINDOW_GAMEPAD:SetupSpinner(spinnerMax, spinnerMax, targetData.launderPrice, targetData.currencyType1)
        else
            LaunderItem(bag, index, 1)
        end
    end
end

function ZO_GamepadFenceLaunder:SetupEntry(control, data, selected, selectedDuringRebuild, enabled, activated)
    local price = self.confirmationMode and selected and data.launderPrice * STORE_WINDOW_GAMEPAD:GetSpinnerValue() or data.launderPrice
    self:SetupStoreItem(control, data, selected, selectedDuringRebuild, enabled, activated, price, not ZO_STORE_FORCE_VALID_PRICE, self.mode)
end

function ZO_GamepadFenceLaunder:OnSuccess()
    if not self.control:IsControlHidden() then
        PlaySound(SOUNDS.ITEM_MONEY_CHANGED)
        PlaySound(SOUNDS.FENCE_ITEM_LAUNDERED)
        STORE_WINDOW_GAMEPAD:RefreshHeaderData()
    end
end

function ZO_GamepadFenceLaunder_Initialize()
    FENCE_LAUNDER_GAMEPAD = ZO_GamepadFenceLaunder:New()
    STORE_WINDOW_GAMEPAD:AddComponent(FENCE_LAUNDER_GAMEPAD)
end