
----------------
--Initialization
----------------

ZO_GamepadFenceComponent = ZO_GamepadStoreListComponent:Subclass()

function ZO_GamepadFenceComponent:New(...)
    return ZO_GamepadStoreListComponent.New(self, ...)
end

function ZO_GamepadFenceComponent:Initialize(mode, title)
    ZO_GamepadStoreListComponent.Initialize(self, STORE_WINDOW_GAMEPAD, mode, title)
    self.mode = mode

    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:RegisterEvents()
            self.list:UpdateList()
            self:RefreshFooter()
            self:ShowFenceBar()
        elseif newState == SCENE_HIDING then
            self:UnregisterEvents()
            self:HideFenceBar()
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
            ZO_Dialogs_ReleaseDialog("CANT_BUYBACK_FROM_FENCE")
        end
    end)
end

function ZO_GamepadFenceComponent:RegisterEvents()
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

    local oldUpdateHandler = self.control:GetHandler("OnUpdate")
    local lastUpdateSeconds = 0
    local function OnUpdate(control, currentFrameTimeSeconds)
        oldUpdateHandler(control, currentFrameTimeSeconds)

        if currentFrameTimeSeconds - lastUpdateSeconds > 1 then
            self:RefreshFooter()
            lastUpdateSeconds = currentFrameTimeSeconds
        end
    end
    self.control:SetHandler("OnUpdate", OnUpdate)
end

function ZO_GamepadFenceComponent:UnregisterEvents()
    self.control:UnregisterForEvent(EVENT_INVENTORY_FULL_UPDATE)
    self.control:UnregisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
end

function ZO_GamepadFenceComponent:InitializeKeybindStrip(forwardText)
    -- sell screen keybind
    self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_LEFT_STICK",
            name = GetString(SI_ITEM_ACTION_STACK_ALL),
            callback = function()
                StackBag(BAG_BACKPACK)
            end
        },
    }

    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.keybindStripDescriptor,
                                                      GAME_NAVIGATION_TYPE_BUTTON,
                                                      function() self:Confirm() end,
                                                      forwardText,
                                                      function() return not self.list:IsEmpty() end)

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor,
                                                    GAME_NAVIGATION_TYPE_BUTTON)

    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.list)

    self.confirmKeybindStripDescriptor = {}

    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.confirmKeybindStripDescriptor,
                                                      GAME_NAVIGATION_TYPE_BUTTON,
                                                      function() self:Confirm() end,
                                                      forwardText
                                                    )

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.confirmKeybindStripDescriptor,
                                                    GAME_NAVIGATION_TYPE_BUTTON,
                                                    function() self:UnselectItem() end)
end

-----------------
--Class Functions
-----------------

function ZO_GamepadFenceComponent:SelectItem(ignoreInvalidCost)
    self.confirmationMode = true
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.confirmKeybindStripDescriptor)
    STORE_WINDOW_GAMEPAD:SetQuantitySpinnerActive(self.confirmationMode, self.list, ignoreInvalidCost)
end

function ZO_GamepadFenceComponent:UnselectItem()
    self.confirmationMode = false
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.confirmKeybindStripDescriptor)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    STORE_WINDOW_GAMEPAD:SetQuantitySpinnerActive(self.confirmationMode, self.list)
end

function ZO_GamepadFenceComponent:SetupEntry(control, data, selected, selectedDuringRebuild, enabled, activated)
    local price = self.confirmationMode and selected and data.sellPrice * STORE_WINDOW_GAMEPAD:GetSpinnerValue() or data.sellPrice
    self:SetupStoreItem(control, data, selected, selectedDuringRebuild, enabled, activated, price, ZO_STORE_FORCE_VALID_PRICE, self.mode)
end

function ZO_GamepadFenceComponent:OnSelectedItemChanged(inventoryData)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
    if inventoryData then
        GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, inventoryData.bagId, inventoryData.slotIndex)
        STORE_WINDOW_GAMEPAD:UpdateRightTooltip(self.list, self.mode)
    end
end

function ZO_GamepadFenceComponent:Confirm()
    --Stubbed, to be overriden
end

function ZO_GamepadFenceComponent:OnSuccess()
    --Stubbed, to be overriden
end

function ZO_GamepadFenceComponent:RefreshFooter()
    --Stubbed, to be overriden
end

function ZO_GamepadFenceComponent:ShowFenceBar()
    --Stubbed, to be overriden
end

function ZO_GamepadFenceComponent:HideFenceBar()
    --Stubbed, to be overriden
end

function ZO_GamepadFenceComponent:ClearFooter()
    local data =
    {
        data1HeaderText = nil,
        data1Text = nil
    }

    GAMEPAD_GENERIC_FOOTER:Refresh(data)
end