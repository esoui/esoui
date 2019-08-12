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
            self:SetVendorBlurActive(true)
            self:UpdatePreview(self.list:GetSelectedData())
        elseif newState == SCENE_HIDING then
            self:UnregisterEvents()
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
            self:UpdatePreview(nil)
            if ITEM_PREVIEW_GAMEPAD:IsInteractionCameraPreviewEnabled() then
                self:TogglePreviewMode()
            end
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
        repairAllKeybind,
        {
            name = function()
                        if not ITEM_PREVIEW_GAMEPAD:IsInteractionCameraPreviewEnabled() then
                            return GetString(SI_CRAFTING_ENTER_PREVIEW_MODE)
                        else
                            return GetString(SI_CRAFTING_EXIT_PREVIEW_MODE)
                        end
            end,
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            alignment = KEYBIND_STRIP_ALIGN_LEFT,

            callback = function()
                self:TogglePreviewMode()
            end,
            visible = function()
                -- if we are previewing something, we can end it regardless of our selection
                local isCurrentlyPreviewing = ITEM_PREVIEW_GAMEPAD:IsInteractionCameraPreviewEnabled()
                if isCurrentlyPreviewing then
                    return true
                end

                local targetData = self.list:GetTargetData()
                if targetData then
                    return self:CanPreviewStoreEntry(targetData)
                else
                    return false
                end
            end,
        },
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
            if not ZO_Currency_TryShowThresholdDialog(selectedData.slotIndex, quantity, selectedData.dataSource) then
                BuyStoreItem(selectedData.slotIndex, quantity)
            end
            self:UnselectBuyItem()
        end
    else
        local maxItems = GetStoreEntryMaxBuyable(selectedData.slotIndex)
        if maxItems > 1 then
            self:SelectBuyItem()
            STORE_WINDOW_GAMEPAD:SetupSpinner(zo_max(GetStoreEntryMaxBuyable(selectedData.slotIndex), 1), 1, selectedData.sellPrice, selectedData.currencyType1 or CURT_MONEY)
        elseif maxItems == 1 then
            if not ZO_Currency_TryShowThresholdDialog(selectedData.slotIndex, maxItems, selectedData.dataSource) then
                BuyStoreItem(selectedData.slotIndex, 1)
            end
        end
    end
end

function ZO_GamepadStoreBuy:CanBuy()
    local selectedData = self.list:GetTargetData()
    if selectedData then
        if not selectedData.dataSource.meetsRequirementsToBuy then
            return false, selectedData.dataSource.requiredToBuyErrorText
        end

        local enabled, disabledAlertText = STORE_WINDOW_GAMEPAD:CanAfford(selectedData)
        if not enabled then
            return false, disabledAlertText
        end

        if selectedData.entryType ~= STORE_ENTRY_TYPE_COLLECTIBLE then
            enabled, disabledAlertText = STORE_WINDOW_GAMEPAD:CanCarry(selectedData)
            if not enabled then
                return false, disabledAlertText
            end
        end

        return true
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
    end
    self:UpdatePreview(buyData)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GamepadStoreBuy:SetVendorBlurActive(shouldActivateVendorBlur)
    if shouldActivateVendorBlur then
        SCENE_MANAGER:AddFragment(FRAME_TARGET_BLUR_QUADRANT_3_GAMEPAD_FRAGMENT)
    else
        -- As is the case with other item preview fragments, we want to override the
        -- hideOnSceneHidden behavior the blur fragment normally has, but only
        -- when toggling preview on/off. if we are hiding the scene normally, we
        -- should continue using hideOnSceneHidden. More info in ZO_ItemPreview_Shared:SetInteractionCameraPreviewEnabled().
        ITEM_PREVIEW_GAMEPAD:RemoveFragmentImmediately(FRAME_TARGET_BLUR_QUADRANT_3_GAMEPAD_FRAGMENT)
    end
end

function ZO_GamepadStoreBuy:UpdatePreview(selectedData)
    if ITEM_PREVIEW_GAMEPAD:IsInteractionCameraPreviewEnabled() then
        if self:CanPreviewStoreEntry(selectedData) then
            local storeEntryIndex = ZO_Inventory_GetSlotIndex(selectedData)
            ZO_StoreManager_DoPreviewAction(ZO_STORE_MANAGER_PREVIEW_ACTION_EXECUTE, storeEntryIndex)
        else
            self:SetVendorBlurActive(false)
            ITEM_PREVIEW_GAMEPAD:SetInteractionCameraPreviewEnabled(false, FRAME_TARGET_STORE_GAMEPAD_FRAGMENT, FRAME_PLAYER_ON_SCENE_HIDDEN_FRAGMENT, GAMEPAD_NAV_QUADRANT_3_4_ITEM_PREVIEW_OPTIONS_FRAGMENT)
        end
    end
end

function ZO_GamepadStoreBuy:TogglePreviewMode()
    local willPreviewBeDisabled = ITEM_PREVIEW_GAMEPAD:IsInteractionCameraPreviewEnabled()
    self:SetVendorBlurActive(willPreviewBeDisabled)
    ITEM_PREVIEW_GAMEPAD:ToggleInteractionCameraPreview(FRAME_TARGET_STORE_GAMEPAD_FRAGMENT, FRAME_PLAYER_ON_SCENE_HIDDEN_FRAGMENT, GAMEPAD_NAV_QUADRANT_3_4_ITEM_PREVIEW_OPTIONS_FRAGMENT)

    local targetData = self.list:GetTargetData()
    self:UpdatePreview(targetData)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GamepadStoreBuy:CanPreviewStoreEntry(data)
    if data then
        local storeEntryIndex = ZO_Inventory_GetSlotIndex(data)
        return ZO_StoreManager_DoPreviewAction(ZO_STORE_MANAGER_PREVIEW_ACTION_VALIDATE, storeEntryIndex)
    end

    return false
end
