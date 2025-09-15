ZO_GamepadStoreSellVengeance = ZO_GamepadStoreSell:Subclass()

function ZO_GamepadStoreSellVengeance:Initialize(scene)
    ZO_GamepadStoreListComponent.Initialize(self, scene, ZO_MODE_STORE_SELL_VENGEANCE, GetString(SI_STORE_MODE_SELL_VENGEANCE))

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
    self:CreateModeData(SI_STORE_MODE_SELL_VENGEANCE, ZO_MODE_STORE_SELL_VENGEANCE, "EsoUI/Art/Vendor/vendor_tabIcon_sellVengeance_up.dds", self.fragment, self.keybindStripDescriptor)
    self.list:SetNoItemText(GetString(SI_GAMEPAD_NO_SELL_ITEMS))
end

function ZO_GamepadStoreSellVengeance:InitializeKeybindStrip()
    local repairAllKeybind = STORE_WINDOW_GAMEPAD:GetRepairAllKeybind()
    local stackBagKeybind =
    {
        keybind = "UI_SHORTCUT_LEFT_STICK",
        name = GetString(SI_ITEM_ACTION_STACK_ALL),
        callback = function()
            StackBag(BAG_VENGEANCE)
        end
    }

    -- sell screen keybind
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
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

function ZO_GamepadStoreSell:SetupEntry(control, data, selected, selectedDuringRebuild, enabled, activated)
    local price = self.confirmationMode and selected and data.sellPrice * STORE_WINDOW_GAMEPAD:GetSpinnerValue() or data.sellPrice
    self:SetupStoreItem(control, data, selected, selectedDuringRebuild, enabled, activated, price, ZO_STORE_FORCE_VALID_PRICE, ZO_MODE_STORE_SELL_VENGEANCE)
end