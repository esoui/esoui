ZO_GamepadStoreSell = ZO_GamepadStoreListComponent:Subclass()

function ZO_GamepadStoreSell:New(...)
    return ZO_GamepadStoreListComponent.New(self, ...)
end

function ZO_GamepadStoreSell:Initialize(scene)
    ZO_GamepadStoreListComponent.Initialize(self, scene, ZO_MODE_STORE_SELL, GetString(SI_STORE_MODE_SELL))

    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:RegisterEvents()
            self.list:UpdateList()
        elseif newState == SCENE_HIDING then
            self:UnregisterEvents()
            GAMEPAD_INVENTORY:TryClearNewStatusOnHidden()
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
        end
    end)

    self:InitializeKeybindStrip()
    self:CreateModeData(SI_STORE_MODE_SELL, ZO_MODE_STORE_SELL, "EsoUI/Art/Vendor/vendor_tabIcon_sell_up.dds", fragment, self.keybindStripDescriptor)
    self.list:SetNoItemText(GetString(SI_GAMEPAD_NO_SELL_ITEMS))
end

function ZO_GamepadStoreSell:RegisterEvents()
    local function OnInventoryFullUpdate()
        self.list:UpdateList()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end

    local function OnInventorySingleSlotUpdate(eventId, bagId, slotId, isNewItem, itemSoundCategory, updateReason)
        if updateReason == INVENTORY_UPDATE_REASON_DEFAULT then
            self.list:UpdateList()
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end

    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, OnInventoryFullUpdate)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventorySingleSlotUpdate)
end

function ZO_GamepadStoreSell:UnregisterEvents()
    self.control:UnregisterForEvent(EVENT_INVENTORY_FULL_UPDATE)
    self.control:UnregisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
end

function ZO_GamepadStoreSell:InitializeKeybindStrip()
    local repairAllKeybind = STORE_WINDOW_GAMEPAD:GetRepairAllKeybind()
    local stackBagKeybind = 
    {
        keybind = "UI_SHORTCUT_LEFT_STICK",
        name = GetString(SI_ITEM_ACTION_STACK_ALL),
        callback = function()
            StackBag(BAG_BACKPACK)
        end
    }

    -- sell screen keybind
    self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        repairAllKeybind,
        stackBagKeybind,
    }

    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.keybindStripDescriptor,
                                                      GAME_NAVIGATION_TYPE_BUTTON,
                                                      function() self:ConfirmSell() end,
                                                      GetString(SI_ITEM_ACTION_SELL),
                                                      function() return #self.list.dataList > 0 end,
                                                      function() return self:CanSell() end
                                                    )

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor,
                                                    GAME_NAVIGATION_TYPE_BUTTON)

    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.list)

    self.confirmKeybindStripDescriptor = {}

    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.confirmKeybindStripDescriptor,
                                                      GAME_NAVIGATION_TYPE_BUTTON,
                                                      function() self:ConfirmSell() end,
                                                      GetString(SI_ITEM_ACTION_SELL)
                                                    )

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.confirmKeybindStripDescriptor,
                                                    GAME_NAVIGATION_TYPE_BUTTON,
                                                    function() self:UnselectSellItem() end,
                                                    nil)
end

function ZO_GamepadStoreSell:CanSell()
    if GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER) ~= GetMaxPossibleCurrency(CURT_MONEY, CURRENCY_LOCATION_CHARACTER) then
        return true
    else
        return false, GetString("SI_STOREFAILURE", STORE_FAILURE_SELL_FAILED_MONEY_CAP) -- "You cannot sell items when you are at the gold cap"
    end
end

function ZO_GamepadStoreSell:ConfirmSell()
    local selectedData = self.list:GetTargetData()
    local bag, index = ZO_Inventory_GetBagAndIndex(selectedData)

    if self.confirmationMode then
        local quantity = STORE_WINDOW_GAMEPAD:GetSpinnerValue()
        if quantity > 0 then
            SellInventoryItem(bag, index, quantity)
            self:UnselectSellItem()
        end
    else
        if selectedData.stackCount > 1 then
            self:SelectSellItem()
            STORE_WINDOW_GAMEPAD:SetupSpinner(selectedData.stackCount, selectedData.stackCount, selectedData.sellPrice, selectedData.currencyType1 or CURT_MONEY)
        else
            SellInventoryItem(bag, index, 1)
        end
    end
end

do
    local IGNORE_INVALID_COST = true
    function ZO_GamepadStoreSell:SelectSellItem()
        self.confirmationMode = true
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.confirmKeybindStripDescriptor)
        STORE_WINDOW_GAMEPAD:SetQuantitySpinnerActive(self.confirmationMode, self.list, IGNORE_INVALID_COST)
    end
end

function ZO_GamepadStoreSell:UnselectSellItem()
    self.confirmationMode = false
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.confirmKeybindStripDescriptor)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    STORE_WINDOW_GAMEPAD:SetQuantitySpinnerActive(self.confirmationMode, self.list)
end

function ZO_GamepadStoreSell:SetupEntry(control, data, selected, selectedDuringRebuild, enabled, activated)
    local price = self.confirmationMode and selected and data.sellPrice * STORE_WINDOW_GAMEPAD:GetSpinnerValue() or data.sellPrice
    self:SetupStoreItem(control, data, selected, selectedDuringRebuild, enabled, activated, price, ZO_STORE_FORCE_VALID_PRICE, ZO_MODE_STORE_SELL)
end

function ZO_GamepadStoreSell:OnSelectedItemChanged(inventoryData)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
    if inventoryData then
        GAMEPAD_INVENTORY:PrepareNextClearNewStatus(inventoryData)
        self.list:RefreshVisible()
        GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, inventoryData.bagId, inventoryData.slotIndex)
    end
end