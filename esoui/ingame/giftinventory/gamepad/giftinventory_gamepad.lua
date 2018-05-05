ZO_GiftInventory_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

local ZO_GAMEPAD_GIFT_INVENTORY_TAB = {
    RECEIVED = 1,
    SENT = 2,
    RETURNED = 3,
}

function ZO_GiftInventory_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_GiftInventory_Gamepad:Initialize(control)
    ZO_GAMEPAD_GIFT_INVENTORY_SCENE = ZO_Scene:New("giftInventoryGamepad", SCENE_MANAGER)
    local DONT_ACTIVATE_ON_SHOW = false
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_CREATE, DONT_ACTIVATE_ON_SHOW, ZO_GAMEPAD_GIFT_INVENTORY_SCENE)

    ZO_GAMEPAD_GIFT_INVENTORY_FRAGMENT = ZO_SimpleSceneFragment:New(control)
    ZO_GAMEPAD_GIFT_INVENTORY_FRAGMENT:SetHideOnSceneHidden(true)
    self.scene:AddFragment(ZO_GAMEPAD_GIFT_INVENTORY_FRAGMENT)

    self:SetListsUseTriggerKeybinds(true)

    local CUSTOM_LIST_SETUP = true
    self.receivedList = self:AddList("Received", CUSTOM_LIST_SETUP, ZO_GiftInventoryReceived_Gamepad)
    self.sentList = self:AddList("Sent", CUSTOM_LIST_SETUP, ZO_GiftInventorySent_Gamepad)
    self.returnedList = self:AddList("Returned", CUSTOM_LIST_SETUP, ZO_GiftInventoryReturned_Gamepad)

    GIFT_INVENTORY_MANAGER:RegisterCallback("GiftActionResult", function(...) self:OnGiftActionResult(...) end)
    SYSTEMS:RegisterGamepadRootScene("giftInventory", ZO_GAMEPAD_GIFT_INVENTORY_SCENE)
end

function ZO_GiftInventory_Gamepad:SetupHeader()
    local tabBarEntries =
    {
        {
            text = GetString(SI_GIFT_INVENTORY_RECEIVED_GIFTS_HEADER),
            callback = function()
                self:SwitchActiveList(self.receivedList)
            end,
        },
        {
            text = GetString(SI_GIFT_INVENTORY_SENT_GIFTS_HEADER),
            callback = function()
                self:SwitchActiveList(self.sentList)
            end,
        },
        {
            text = GetString(SI_GIFT_INVENTORY_RETURNED_GIFTS_HEADER),
            callback = function()
                self:SwitchActiveList(self.returnedList)
            end,
        },
    }

    self.headerData =
    {
        tabBarEntries = tabBarEntries,
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_GiftInventory_Gamepad:SetSelectedCategoryByGiftState(giftState)
    local listIndex
    if giftState == GIFT_STATE_RECEIVED then 
        listIndex = ZO_GAMEPAD_GIFT_INVENTORY_TAB.RECEIVED
    elseif giftState == GIFT_STATE_THANKED or giftState == GIFT_STATE_SENT then
        listIndex = ZO_GAMEPAD_GIFT_INVENTORY_TAB.SENT
    elseif giftState == GIFT_STATE_RETURNED then
        listIndex = ZO_GAMEPAD_GIFT_INVENTORY_TAB.RETURNED
    end

    if listIndex then
        if self.scene:GetState() == SCENE_SHOWN then
            ZO_GamepadGenericHeader_SetActiveTabIndex(self.header, listIndex)
        else
            self.requestedListIndexSelection = listIndex
        end
    end
end

-- begin ZO_Gamepad_ParametricList_Screen overrides

function ZO_GiftInventory_Gamepad:OnDeferredInitialize()
    self:SetupHeader()
end

function ZO_GiftInventory_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor(),
    }
end

function ZO_GiftInventory_Gamepad:PerformUpdate()
    self.dirty = false
end

function ZO_GiftInventory_Gamepad:OnShowing()
    ZO_GamepadGenericHeader_Activate(self.header)

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    if self.requestedListIndexSelection then
        ZO_GamepadGenericHeader_SetActiveTabIndex(self.header, self.requestedListIndexSelection)
        self.requestedListIndexSelection = nil
    end

    TriggerTutorial(TUTORIAL_TRIGGER_GIFT_INVENTORY_OPENED)
end

function ZO_GiftInventory_Gamepad:OnHiding()
    ZO_GamepadGenericHeader_Deactivate(self.header)

    self:RemoveCurrentListKeybinds()

    self.waitingOnResendResult = false
end

function ZO_GiftInventory_Gamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    -- need to update list keybinds on selection changed since rebuilding the list won't trigger a target change
    self:RefreshCurrentListKeybinds()
end

function ZO_GiftInventory_Gamepad:OnTargetChanged(list, targetData, oldTargetData, reachedTarget, targetSelectedIndex)
    self:RefreshCurrentListKeybinds()
end

-- end ZO_Gamepad_ParametricList_Screen overrides

function ZO_GiftInventory_Gamepad:SwitchActiveList(list)
    self:RemoveCurrentListKeybinds()

    local currentList = self:GetCurrentList()
    if currentList then
        currentList:HideTooltip()
    end

    self:SetCurrentList(list)
    self.currentListKeybinds = list:GetKeybinds()

    self:AddCurrentListKeybinds()
    list:ShowTooltip()
end

function ZO_GiftInventory_Gamepad:AddCurrentListKeybinds()
    if self.currentListKeybinds then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.currentListKeybinds)
    end
end

function ZO_GiftInventory_Gamepad:RemoveCurrentListKeybinds()
    if self.currentListKeybinds then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentListKeybinds)
    end
end

function ZO_GiftInventory_Gamepad:RefreshCurrentListKeybinds()
    if self.currentListKeybinds then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentListKeybinds)
    end
end

function ZO_GiftInventory_Gamepad:OnRequestResendGift()
    local currentList = self:GetCurrentList()
    if currentList then
        currentList:HideTooltip()
    end
    self:DeactivateCurrentList()

    self:RemoveCurrentListKeybinds()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)

    self.waitingOnResendResult = true
end

function ZO_GiftInventory_Gamepad:OnGiftResendComplete()
    self:ActivateCurrentList()
    local currentList = self:GetCurrentList()
    if currentList then
        currentList:ShowTooltip()
    end

    self:AddCurrentListKeybinds()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

    self.waitingOnResendResult = false
end

function ZO_GiftInventory_Gamepad:OnGiftActionResult(giftAction, result, giftId)
    if self.scene:IsShowing() then
        if self.waitingOnResendResult and giftAction == GIFT_ACTION_RESEND and result == GIFT_ACTION_RESULT_FINISHED then
            self:OnGiftResendComplete()
        end
    end
end

-- Global XML functions

function ZO_GiftInventory_Gamepad_Initialize(control)
    GIFT_INVENTORY_GAMEPAD = ZO_GiftInventory_Gamepad:New(control)
end
