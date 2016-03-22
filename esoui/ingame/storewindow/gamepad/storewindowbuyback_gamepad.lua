ZO_GamepadStoreBuyback = ZO_GamepadStoreListComponent:Subclass()

function ZO_GamepadStoreBuyback:New(...)
    return ZO_GamepadStoreListComponent.New(self, ...)
end

function ZO_GamepadStoreBuyback:Initialize(scene)
    ZO_GamepadStoreListComponent.Initialize(self, scene, ZO_MODE_STORE_BUY_BACK, GetString(SI_STORE_MODE_BUY_BACK))

    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:RegisterEvents()
            self.list:UpdateList()
        elseif newState == SCENE_HIDING then
            self:UnregisterEvents()
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
        end
	end)

    self:InitializeKeybindStrip()
    self:CreateModeData(SI_STORE_MODE_BUY_BACK, ZO_MODE_STORE_BUY_BACK, "EsoUI/Art/Vendor/vendor_tabIcon_buyBack_up.dds", fragment, self.keybindStripDescriptor)
    self.list:SetNoItemText(GetString(SI_GAMEPAD_NO_BUYBACK_ITEMS))
end

function ZO_GamepadStoreBuyback:RegisterEvents()
    local OnCurrencyChanged = function()
	    self.list:RefreshVisible()
	end

    self.control:RegisterForEvent(EVENT_MONEY_UPDATE, OnCurrencyChanged)
    self.control:RegisterForEvent(EVENT_ALLIANCE_POINT_UPDATE, OnCurrencyChanged)

    local OnBuyBackUpdated = function()
	    self.list:UpdateList()
    end

	self.control:RegisterForEvent(EVENT_UPDATE_BUYBACK, OnBuyBackUpdated)
end

function ZO_GamepadStoreBuyback:UnregisterEvents()
    self.control:UnregisterForEvent(EVENT_MONEY_UPDATE)
    self.control:UnregisterForEvent(EVENT_ALLIANCE_POINT_UPDATE)
	self.control:UnregisterForEvent(EVENT_UPDATE_BUYBACK)
end

function ZO_GamepadStoreBuyback:InitializeKeybindStrip()
    -- Buy-Back screen keybind
	self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
		STORE_WINDOW_GAMEPAD:GetRepairAllKeybind(),
    }
    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.keybindStripDescriptor,
                                                      GAME_NAVIGATION_TYPE_BUTTON,
                                                      function() self:ConfirmBuyBack() end,
                                                      GetString(SI_ITEM_ACTION_BUYBACK),
                                                      function() return GetNumBuybackItems() > 0 end,
													  function() return self:CanBuyBack() end
												    )
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)

	ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.list)
end

function ZO_GamepadStoreBuyback:ConfirmBuyBack()
    local selectedItem = self.list:GetTargetData()
    BuybackItem(selectedItem.slotIndex)
end

function ZO_GamepadStoreBuyback:CanBuyBack()
    local selectedData = self.list:GetTargetData()
    return STORE_WINDOW_GAMEPAD:CanAffordAndCanCarry(selectedData) -- returns enabled, disabledAlertText
end

function ZO_GamepadStoreBuyback:SetupEntry(control, data, selected, selectedDuringRebuild, enabled, activated)
    self:SetupStoreItem(control, data, selected, selectedDuringRebuild, enabled, activated, data.sellPrice, not ZO_STORE_FORCE_VALID_PRICE, ZO_MODE_STORE_BUY_BACK)
end

function ZO_GamepadStoreBuyback:OnSelectedItemChanged(buyBackData)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
    if buyBackData then
        GAMEPAD_TOOLTIPS:LayoutBuyBackItem(GAMEPAD_LEFT_TOOLTIP, buyBackData.slotIndex, buyBackData.icon)
        STORE_WINDOW_GAMEPAD:UpdateRightTooltip(self.list, ZO_MODE_STORE_BUY_BACK)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end
