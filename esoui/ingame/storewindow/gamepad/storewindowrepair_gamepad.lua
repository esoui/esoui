ZO_GamepadStoreRepair = ZO_GamepadStoreListComponent:Subclass()

function ZO_GamepadStoreRepair:New(...)
    return ZO_GamepadStoreListComponent.New(self, ...)
end

function ZO_GamepadStoreRepair:Initialize(scene)
    ZO_GamepadStoreListComponent.Initialize(self, scene, ZO_MODE_STORE_REPAIR, GetString(SI_STORE_MODE_REPAIR))

    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
	    if newState == SCENE_SHOWING then
            self:RegisterEvents()
			self.list:UpdateList()
        elseif newState == SCENE_HIDING then
            self:UnregisterEvents()
		end
	end)

    self:InitializeKeybindStrip()
    self:CreateModeData(SI_STORE_MODE_REPAIR, ZO_MODE_STORE_REPAIR, "EsoUI/Art/Vendor/vendor_tabIcon_repair_up.dds", fragment, self.keybindStripDescriptor)
    self.list:SetNoItemText(GetString(SI_GAMEPAD_NO_DAMAGED_ITEMS))
end

function ZO_GamepadStoreRepair:RegisterEvents()
    local OnInventoryUpdated = function(eventId, bagId, slotId, isNewItem, soundCategory, reason)
        if reason == INVENTORY_UPDATE_REASON_DURABILITY_CHANGE then
			self.list:UpdateList()
			KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end

    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, OnInventoryUpdated)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventoryUpdated)

    local OnCurrencyChanged = function()
	    self.list:RefreshVisible()
	end

    self.control:RegisterForEvent(EVENT_MONEY_UPDATE, OnCurrencyChanged)
    self.control:RegisterForEvent(EVENT_ALLIANCE_POINT_UPDATE, OnCurrencyChanged)
end

function ZO_GamepadStoreRepair:UnregisterEvents()
    self.control:UnregisterForEvent(EVENT_INVENTORY_FULL_UPDATE)
    self.control:UnregisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
    self.control:UnregisterForEvent(EVENT_MONEY_UPDATE)
    self.control:UnregisterForEvent(EVENT_ALLIANCE_POINT_UPDATE)
end

function ZO_GamepadStoreRepair:InitializeKeybindStrip()
    -- Repair screen keybind
    self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        STORE_WINDOW_GAMEPAD:GetRepairAllKeybind()
    }

    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.keybindStripDescriptor,
                                                    GAME_NAVIGATION_TYPE_BUTTON,
                                                    function() self:ConfirmRepair() end,
                                                    GetString(SI_ITEM_ACTION_REPAIR),
                                                    function() return #self.list.dataList > 0 end,
                                                    function() return self:CanRepair() end)

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)

    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.list)
end

function ZO_GamepadStoreRepair:CanRepair()
    local selectedItem = self.list:GetTargetData()
    local cost = selectedItem.repairCost
    if cost <= GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER) then
        return true
    else
        return false, GetString("SI_ITEMREPAIRREASON", ITEM_REPAIR_CANT_AFFORD_REPAIR) -- "You can't afford to repair this item"
    end
end

function ZO_GamepadStoreRepair:ConfirmRepair()
    local selectedItem = self.list:GetTargetData() --All items in this list are damaged
    local bagId = selectedItem.bagId
    local slotIndex = selectedItem.slotIndex
    RepairItem(bagId, slotIndex)
    PlaySound(SOUNDS.INVENTORY_ITEM_REPAIR)
end

function ZO_GamepadStoreRepair:SetupEntry(control, data, selected, selectedDuringRebuild, enabled, activated)
    self:SetupStoreItem(control, data, selected, selectedDuringRebuild, enabled, activated, data.repairCost, not ZO_STORE_FORCE_VALID_PRICE, ZO_MODE_STORE_REPAIR)

	local conditionControl = control:GetNamedChild("Condition")
	if conditionControl then
		conditionControl:SetHidden(false)
		conditionControl:SetText(zo_strformat(SI_ITEM_CONDITION_PERCENT, data.condition))
	end
end

function ZO_GamepadStoreRepair:OnSelectedItemChanged(inventoryData)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
    if inventoryData then
        GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, inventoryData.bagId, inventoryData.slotIndex)
    end
end

function ZO_GamepadStoreRepair:GetNumRepairItems()
    return #self.list.dataList
end
