--Gamepad Store Component
---------------------------

ZO_GamepadStoreComponent = ZO_Object:Subclass()

function ZO_GamepadStoreComponent:New(...)
    local component = ZO_Object.New(self)
    component:Initialize(...)
    return component
end

function ZO_GamepadStoreComponent:Initialize(control, storeMode, tabText)
    self.control = control
    self.storeMode = storeMode
    self.tabText = tabText
end

function ZO_GamepadStoreComponent:Refresh()

end

function ZO_GamepadStoreComponent:GetTabText()
    return self.tabText
end

function ZO_GamepadStoreComponent:Show()
    SCENE_MANAGER:AddFragment(self.fragment)
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_GamepadStoreComponent:Hide()
    SCENE_MANAGER:RemoveFragment(self.fragment)
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_GamepadStoreComponent:GetStoreMode()
    return self.storeMode
end

function ZO_GamepadStoreComponent:GetModeData()
    return self.modeData
end

function ZO_GamepadStoreComponent:CreateModeData(name, mode, icon, fragment, keybind)
    self.modeData = {
        text = GetString(name),
        mode = mode,
        iconFile = icon,
        fragment = fragment,
        keybind = keybind,
    }
end

--Gamepad Store List Component
----------------------------------

ZO_STORE_FORCE_VALID_PRICE = true

ZO_GamepadStoreListComponent = ZO_GamepadStoreComponent:Subclass()

function ZO_GamepadStoreListComponent:New(...)
    return ZO_GamepadStoreComponent.New(self, ...)
end

function ZO_GamepadStoreListComponent:Initialize(scene, storeMode, tabText, overrideTemplate, overrideHeaderTemplateSetupFunction)
    self.list = self:CreateItemList(scene, storeMode, overrideTemplate, overrideHeaderTemplateSetupFunction)
    self.list:UpdateList()
    local control = self.list:GetControl()
    ZO_GamepadStoreComponent.Initialize(self, control, storeMode, tabText)
end

function ZO_GamepadStoreListComponent:Refresh()
    self.list:UpdateList()
end

function ZO_GamepadStoreListComponent:SetupEntry(control, data, selected, selectedDuringRebuild, enabled, activated)

end

function ZO_GamepadStoreListComponent:SetupStoreItem(control, data, selected, selectedDuringRebuild, enabled, activated, price, forceValid, mode)
    data:SetIgnoreTraitInformation(ZO_StoreManager_IsInventoryStoreMode(mode) == false)

    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    control:SetHidden(selected and self.confirmationMode)

    -- Default to CURT_MONEY
    local useDefaultCurrency = (not data.currencyType1) or (data.currencyType1 == CURT_NONE)
    local currencyType = CURT_MONEY

    if not useDefaultCurrency then
        currencyType = data.currencyType1
    end

    self:SetupPrice(control, price, forceValid, mode, currencyType)
end

function ZO_GamepadStoreListComponent:SetupPrice(control, price, forceValid, mode, currencyType)
    local options = self:GetCurrencyOptions()
    local playerStoredLocation = GetCurrencyPlayerStoredLocation(currencyType)
    local invalidPrice = not forceValid and price > GetCurrencyAmount(currencyType, playerStoredLocation) or false
    local priceControl = control:GetNamedChild("Price")

    ZO_CurrencyControl_SetSimpleCurrency(priceControl, currencyType, price, options, CURRENCY_SHOW_ALL, invalidPrice)
end

function ZO_GamepadStoreListComponent:OnSelectedItemChanged(data)

end

function ZO_GamepadStoreListComponent:CreateItemList(scene, storeMode, overrideTemplate, overrideHeaderTemplateSetupFunction)
    local setupFunction = function(...) self:SetupEntry(...) end
    local listName = string.format("StoreMode%d", storeMode)

    local SETUP_LIST_LOCALLY = true
    local list = scene:AddList(listName, SETUP_LIST_LOCALLY)
    self.fragment = scene:GetListFragment(listName)
    ZO_GamepadStoreList.SetMode(list, storeMode, setupFunction, overrideTemplate, overrideHeaderTemplateSetupFunction)
    list.AddItems = ZO_GamepadStoreList.AddItems
    list.UpdateList = ZO_GamepadStoreList.UpdateList

    list:SetOnSelectedDataChangedCallback(function(list, selectedData)
        if list:IsActive() then
            self:OnSelectedItemChanged(selectedData)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentKeybindButton)
        end
    end)

    local OnEffectivelyShown = function()
        list:Activate()
        self:OnSelectedItemChanged(list:GetTargetData())
    end

    local OnEffectivelyHidden = function()
        self:OnExitUnselectItem()
        list:Deactivate()
    end

    list:GetControl():SetHandler("OnEffectivelyShown", OnEffectivelyShown)
    list:GetControl():SetHandler("OnEffectivelyHidden", OnEffectivelyHidden)

    return list
end

function ZO_GamepadStoreListComponent:OnExitUnselectItem()
    if self.confirmationMode then
        self.confirmationMode = false
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.confirmKeybindStripDescriptor)
        STORE_WINDOW_GAMEPAD:SetQuantitySpinnerActive(self.confirmationMode, self.list)
    end
end

function ZO_GamepadStoreListComponent:GetCurrencyOptions()
    return ZO_GAMEPAD_CURRENCY_OPTIONS
end