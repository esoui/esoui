ZO_GamepadStoreBuy = ZO_GamepadStoreListComponent:Subclass()

function ZO_GamepadStoreBuy:New(...)
    return ZO_GamepadStoreListComponent.New(self, ...)
end

function ZO_GamepadStoreBuy:Initialize(scene)
    ZO_GamepadStoreListComponent.Initialize(self, scene, ZO_MODE_STORE_BUY, GetString(SI_STORE_MODE_BUY))

    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:RegisterEvents()
            self.list:UpdateList()
			STORE_WINDOW_GAMEPAD:UpdateRightTooltip(self.list, ZO_MODE_STORE_BUY)
        elseif newState == SCENE_HIDING then
            self:UnregisterEvents()
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
        end
	end)
    
    self:InitializeKeybindStrip()
    self:CreateModeData(SI_STORE_MODE_BUY, ZO_MODE_STORE_BUY, "EsoUI/Art/Vendor/vendor_tabIcon_buy_up.dds", fragment, self.keybindStripDescriptor)
end

function ZO_GamepadStoreBuy:RegisterEvents()
    local function OnCurrencyChanged()
	    self.list:RefreshVisible()
	end

    local function OnInventoryFullUpdate()
        self.list:UpdateList()
    end

    local function OnInventorySingleSlotUpdate(_, _, _, _, _, updateReason)
        if updateReason == INVENTORY_UPDATE_REASON_DEFAULT then
            self.list:UpdateList()
        end
    end

    local function OnBuySuccess(eventCode, name, type)
        if type == STORE_ENTRY_TYPE_COLLECTIBLE then
            self.list:UpdateList()
        end
    end

    self.control:RegisterForEvent(EVENT_MONEY_UPDATE, OnCurrencyChanged)
    self.control:RegisterForEvent(EVENT_ALLIANCE_POINT_UPDATE, OnCurrencyChanged)
    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, OnInventoryFullUpdate)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventorySingleSlotUpdate)
    self.control:RegisterForEvent(EVENT_BUY_RECEIPT, OnBuySuccess)
end

function ZO_GamepadStoreBuy:UnregisterEvents()
    self.control:UnregisterForEvent(EVENT_MONEY_UPDATE)
    self.control:UnregisterForEvent(EVENT_ALLIANCE_POINT_UPDATE)
    self.control:UnregisterForEvent(EVENT_INVENTORY_FULL_UPDATE)
    self.control:UnregisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
    self.control:UnregisterForEvent(EVENT_BUY_RECEIPT)
end

function ZO_GamepadStoreBuy:InitializeKeybindStrip()
    local repairAllKeybind = STORE_WINDOW_GAMEPAD:GetRepairAllKeybind()

    	-- Buy screen keybind
	self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
		repairAllKeybind
    }

    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.keybindStripDescriptor,
                                                      GAME_NAVIGATION_TYPE_BUTTON,
                                                      function() self:ConfirmBuy() end,
                                                      GetString(SI_ITEM_ACTION_BUY),
													  nil,
                                                      function() return self:CanBuy() end
												    )

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor,
													GAME_NAVIGATION_TYPE_BUTTON)

	ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.list)

	self.confirmKeybindStripDescriptor = {}

	ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.confirmKeybindStripDescriptor,
                                                      GAME_NAVIGATION_TYPE_BUTTON,
                                                      function() self:ConfirmBuy() end,
                                                      GetString(SI_ITEM_ACTION_BUY),
													  nil,
                                                      function() return self:CanBuy() end
												    )

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.confirmKeybindStripDescriptor,
													GAME_NAVIGATION_TYPE_BUTTON,
													function() self:UnselectBuyItem() end,
													nil)
end

function ZO_GamepadStoreBuy:ConfirmBuy()
    local selectedData = self.list:GetTargetData()
    if self.confirmationMode then
		local quantity = STORE_WINDOW_GAMEPAD:GetSpinnerValue()
		if quantity > 0 then
			BuyStoreItem(selectedData.slotIndex, quantity)
			self:UnselectBuyItem()
		end
	else
		local maxItems = GetStoreEntryMaxBuyable(selectedData.slotIndex)
		if maxItems > 1 then
			self:SelectBuyItem()
            STORE_WINDOW_GAMEPAD:SetupSpinner(zo_max(GetStoreEntryMaxBuyable(selectedData.slotIndex), 1), 1, selectedData.sellPrice, selectedData.currencyType1 or CURT_MONEY)
		elseif maxItems == 1 then
			BuyStoreItem(selectedData.slotIndex, 1)
		end
	end
end

function ZO_GamepadStoreBuy:CanBuy()
	local selectedData = self.list:GetTargetData()
    if selectedData then
        if selectedData.entryType == STORE_ENTRY_TYPE_COLLECTIBLE then
            local collectibleId = GetCollectibleIdFromLink(selectedData.itemLink)
            if IsCollectibleUnlocked(collectibleId) then
                return false, GetString("SI_STOREFAILURE", STORE_FAILURE_ALREADY_HAVE_COLLECTIBLE) -- "You already have that collectible"
            end
            return true --Always allow the purchase of collectibles, regardless of bag space
        end
        return STORE_WINDOW_GAMEPAD:CanAffordAndCanCarry(selectedData) -- returns enabled, disabledAlertText
    else
        return false
    end
end

function ZO_GamepadStoreBuy:SelectBuyItem()
	self.confirmationMode = true
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.confirmKeybindStripDescriptor)
	STORE_WINDOW_GAMEPAD:SetQuantitySpinnerActive(self.confirmationMode, self.list)
end

function ZO_GamepadStoreBuy:UnselectBuyItem()
	self.confirmationMode = false
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.confirmKeybindStripDescriptor)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
	STORE_WINDOW_GAMEPAD:SetQuantitySpinnerActive(self.confirmationMode, self.list)
end

function ZO_GamepadStoreBuy:SetupEntry(control, data, selected, selectedDuringRebuild, enabled, activated)
	local price = self.confirmationMode and selected and data.sellPrice * STORE_WINDOW_GAMEPAD:GetSpinnerValue() or data.sellPrice
	self:SetupStoreItem(control, data, selected, selectedDuringRebuild, enabled, activated, price, not ZO_STORE_FORCE_VALID_PRICE, ZO_MODE_STORE_BUY)
end

function ZO_GamepadStoreBuy:OnSelectedItemChanged(buyData)
    if buyData then
	    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
        GAMEPAD_TOOLTIPS:LayoutStoreWindowItem(GAMEPAD_LEFT_TOOLTIP, buyData)
        STORE_WINDOW_GAMEPAD:UpdateRightTooltip(self.list, ZO_MODE_STORE_BUY)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end
