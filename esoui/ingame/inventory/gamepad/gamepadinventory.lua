ZO_GamepadInventory = ZO_Gamepad_ParametricList_Screen:Subclass()

ZO_GAMEPAD_CONFIRM_DESTROY_DIALOG = "GAMEPAD_CONFIRM_DESTROY_ITEM_PROMPT"
ZO_GAMEPAD_SPLIT_STACK_DIALOG = "GAMEPAD_SPLIT_STACK"

local CATEGORY_ITEM_ACTION_MODE = 1
local ITEM_LIST_ACTION_MODE = 2

--[[ Public  API ]]--
function ZO_GamepadInventory:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_GamepadInventory:SetSelectedItemUniqueId(selectedData)
    if selectedData then
        self.selectedItemUniqueId = selectedData.uniqueId
    else
        self.selectedItemUniqueId = nil
    end
end

function ZO_GamepadInventory:Initialize(control)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)

    -- need this earlier than deferred init so trade can split stacks before inventory is possibly viewed
    self:InitializeSplitStackDialog()

    local function OnInventoryShown()
        TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_OPENED)
        local numUsedSlots, numMaxSlots = self:GetNumSlots(BAG_BACKPACK) 
        if numUsedSlots == numMaxSlots then
            TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_OPENED_AND_FULL)
        end
        if GetUnitLevel("player") >= GetWeaponSwapUnlockedLevel() then
            TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_OPENED_AND_WEAPON_SETS_AVAILABLE)
        end  
        if AreAnyItemsStolen(INVENTORY_BACKPACK) then
            TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_OPENED_AND_STOLEN_ITEMS_PRESENT)
        end
    end

    GAMEPAD_INVENTORY_ROOT_SCENE = ZO_Scene:New("gamepad_inventory_root", SCENE_MANAGER)
    GAMEPAD_INVENTORY_ROOT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:PerformDeferredInitialization()
            self:RefreshCategoryList()
            self:SetSelectedInventoryData(nil)

            self:SetSelectedItemUniqueId(self:GenerateItemSlotData(self.categoryList:GetTargetData()))
            self.actionMode = CATEGORY_ITEM_ACTION_MODE
            
            self:SetCurrentList(self.categoryList)

            KEYBIND_STRIP:AddKeybindButtonGroup(self.rootKeybindDescriptor)
            ZO_InventorySlot_SetUpdateCallback(function() self:RefreshItemActionList() end)
            self:RefreshHeader()

        elseif(newState == SCENE_SHOWN) then
            OnInventoryShown()

        elseif newState == SCENE_HIDING then
            ZO_InventorySlot_SetUpdateCallback(nil)
            self:DisableCurrentList()

        elseif newState == SCENE_HIDDEN then
            self:SetSelectedInventoryData(nil)
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.rootKeybindDescriptor)
        end
    end)

    GAMEPAD_INVENTORY_ITEM_FILTER_SCENE = ZO_Scene:New("gamepad_inventory_item_filter", SCENE_MANAGER)
    GAMEPAD_INVENTORY_ITEM_FILTER_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self.actionMode = ITEM_LIST_ACTION_MODE
            self:RefreshItemList()
            self:SetSelectedItemUniqueId(self.itemList:GetTargetData())
            if self.itemList:IsEmpty() then
                return -- bail in case refreshing the list caused the scene to hide.
            end

            self:SetCurrentList(self.itemList)

            if self.selectedItemFilterType == ITEMFILTERTYPE_QUICKSLOT then
                KEYBIND_STRIP:AddKeybindButton(self.quickslotKeybindDescriptor)
                TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_OPENED_AND_QUICKSLOTS_AVAILABLE)
            elseif self.selectedItemFilterType == ITEMFILTERTYPE_ARMOR or self.selectedItemFilterType == ITEMFILTERTYPE_WEAPONS then
                KEYBIND_STRIP:AddKeybindButton(self.toggleCompareModeKeybindStripDescriptor)
            end

            self:UpdateRightTooltip()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.itemFilterKeybindStripDescriptor)
            ZO_InventorySlot_SetUpdateCallback(function() self:RefreshItemActionList() end)
            self:RefreshHeader()
            self:RefreshItemActionList()
        
        elseif newState == SCENE_HIDING then
            ZO_InventorySlot_SetUpdateCallback(nil)
            self:DisableCurrentList()
            self.listWaitingOnDestroyRequest = nil

        elseif newState == SCENE_HIDDEN then
            self:SetSelectedInventoryData(nil)

            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.itemFilterKeybindStripDescriptor)
            KEYBIND_STRIP:RemoveKeybindButton(self.quickslotKeybindDescriptor)
            KEYBIND_STRIP:RemoveKeybindButton(self.toggleCompareModeKeybindStripDescriptor)

            if SCENE_MANAGER:IsShowingNext("gamepad_inventory_item_actions") then
                --if taking action on an item, it is no longer new
                self.clearNewStatusOnSelectionChanged = true
            else
                GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
                GAMEPAD_TOOLTIPS:Reset(GAMEPAD_RIGHT_TOOLTIP)
            end
            self:TryClearNewStatusOnHidden()
            ZO_SavePlayerConsoleProfile()
        end
    end)

    GAMEPAD_INVENTORY_ITEM_ACTIONS_SCENE = ZO_Scene:New("gamepad_inventory_item_actions", SCENE_MANAGER)
    GAMEPAD_INVENTORY_ITEM_ACTIONS_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:RefreshItemActionList()

            if self.actionMode == ITEM_LIST_ACTION_MODE then
                self:UpdateItemLeftTooltip(self.currentlySelectedData)
            else
                self:UpdateCategoryLeftTooltip(self.currentlySelectedData)
            end

            self:SetCurrentList(self.itemActionList)

            KEYBIND_STRIP:AddKeybindButtonGroup(self.itemActionsKeybindStripDescriptor)
            ZO_InventorySlot_SetUpdateCallback(function() self:RefreshItemActionList() end)

        elseif newState == SCENE_HIDING then
            ZO_InventorySlot_SetUpdateCallback(nil)
            self:DisableCurrentList()

        elseif newState == SCENE_HIDDEN then
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_RIGHT_TOOLTIP)

            self:SetSelectedInventoryData(nil)

            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.itemActionsKeybindStripDescriptor)
        end
    end)

    local function OnCancelDestroyItemRequest()
        if self.listWaitingOnDestroyRequest then
            self.listWaitingOnDestroyRequest:Activate()
            self.listWaitingOnDestroyRequest = nil
        end
        ZO_Dialogs_ReleaseDialog(ZO_GAMEPAD_CONFIRM_DESTROY_DIALOG)
    end

    local function OnUpdate(updateControl, currentFrameTimeSeconds)
       self:OnUpdate(currentFrameTimeSeconds)
    end

    self.trySetClearNewFlagCallback = function(callId)
        self:TrySetClearNewFlag(callId)
    end

    control:RegisterForEvent(EVENT_CANCEL_MOUSE_REQUEST_DESTROY_ITEM, OnCancelDestroyItemRequest)
    control:SetHandler("OnUpdate", OnUpdate)
end

function ZO_GamepadInventory:OnUpdate(currentFrameTimeSeconds)
    --if no currentFrameTimeSeconds a manual update was called from outside the update loop.
    if not currentFrameTimeSeconds or (self.nextUpdateTimeSeconds and (currentFrameTimeSeconds >= self.nextUpdateTimeSeconds)) then
        self.nextUpdateTimeSeconds = nil

        if self.actionMode == ITEM_LIST_ACTION_MODE then
            self:RefreshItemList()
            self:UpdateRightTooltip()
        else
            self:UpdateCategoryLeftTooltip(self.categoryList:GetTargetData())
        end

        if SCENE_MANAGER:IsShowing("gamepad_inventory_item_actions") then
            self:RefreshItemActionList()
        end

        if SCENE_MANAGER:IsShowing("gamepad_inventory_item_filter") then
            self:RefreshItemActionList()
        end
    end
end

do
    local GAMEPAD_INVENTORY_UPDATE_DELAY = .01

    function ZO_GamepadInventory:MarkDirty()
        if(not self.nextUpdateTimeSeconds) then
            self.nextUpdateTimeSeconds = GetFrameTimeSeconds() + GAMEPAD_INVENTORY_UPDATE_DELAY
        end
    end
end

function ZO_GamepadInventory:PerformDeferredInitialization()
    if self.itemFilterKeybindStripDescriptor then return end
    
    local SAVED_VAR_DEFAULTS = 
    {
        useStatComparisonTooltip = true,
    }
    self.savedVars = ZO_SavedVars:NewAccountWide("ZO_Ingame_SavedVariables", 2, "GamepadInventory", SAVED_VAR_DEFAULTS)
    
    self:InitializeCategoryList()
    self:InitializeItemList()
    self:InitializeItemActionList()
    self:InitializeHeader()
    self:InitializeItemActions()
    self:InitializeKeybindStrip()
    self:InitializeConfirmDestroyDialog()
end

-------------
-- Dialogs --
-------------

function ZO_GamepadInventory:InitializeConfirmDestroyDialog()
    local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.BASIC)

    local confirmString = zo_strupper(GetString(SI_DESTROY_ITEM_CONFIRMATION))

    local function ReleaseDialog(destroyItem)
        RespondToDestroyRequest(destroyItem == true)
        ZO_Dialogs_ReleaseDialogOnButtonPress(ZO_GAMEPAD_CONFIRM_DESTROY_DIALOG)
    end

    ZO_Dialogs_RegisterCustomDialog(ZO_GAMEPAD_CONFIRM_DESTROY_DIALOG,
    {
        blockDialogReleaseOnPress = true, 

        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.BASIC,
            allowRightStickPassThrough = true,
        },

        setup = function()
            self.destroyConfirmText = nil
            dialog.setupFunc(dialog)
        end,

        noChoiceCallback = function(dialog)
            RespondToDestroyRequest(false)
        end,

        title =
        {
            text = SI_PROMPT_TITLE_DESTROY_ITEM_PROMPT,
        },

        mainText = 
        {
            text = SI_DESTROY_ITEM_PROMPT,
        },
      
        buttons =
        {
            {
                onShowCooldown = 2000,
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_YES),
                callback = function()
                    ReleaseDialog(true)
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_NO),
                callback = function()
                    ReleaseDialog()
                end,
            },
        }
    })
end

function ZO_GamepadInventory:InitializeSplitStackDialog()
    local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)

    local function SetupDialog(stackControl, data)
        local itemIcon, _, _, _, _, _, _, quality = GetItemInfo(dialog.data.bagId, dialog.data.slotIndex)
        local stackSize = GetSlotStackSize(dialog.data.bagId, dialog.data.slotIndex)
        data.itemIcon = itemIcon
        data.quality = quality
        data.stackSize = stackSize
        dialog.setupFunc(dialog)
    end

    local function UpdateStackSizes(control)
        local value2 = control.slider:GetValue()
        local value1 = dialog.data.stackSize - value2
        control.sliderValue1:SetText(value1)
        control.sliderValue2:SetText(value2)
    end

    ZO_Dialogs_RegisterCustomDialog(ZO_GAMEPAD_SPLIT_STACK_DIALOG,
    {
        blockDirectionalInput = true,

        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },

        setup = SetupDialog,

        title =
        {
            text = SI_GAMEPAD_INVENTORY_SPLIT_STACK_TITLE,
        },

        mainText = 
        {
            text = SI_GAMEPAD_INVENTORY_SPLIT_STACK_PROMPT,
        },

        parametricList =
        {
            {
                template = "ZO_GamepadSliderItem",

                templateData = {
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        local iconFile = dialog.data.itemIcon

                        if iconFile == nil or iconFile == "" then
                            control.icon1:SetHidden(true)
                            control.icon2:SetHidden(true)
                        else
                            control.icon1:SetTexture(iconFile)
                            control.icon2:SetTexture(iconFile)
                            control.icon1:SetHidden(false)
                            control.icon2:SetHidden(false)
                        end

                        control.slider:SetMinMax(1, dialog.data.stackSize - 1)
                        control.slider:SetValue(zo_floor(dialog.data.stackSize / 2))
                        control.slider:SetValueStep(1)
                        control.slider.valueChangedCallback = function() UpdateStackSizes(control) end
                        if selected then
                            control.slider:Activate()
                            self.splitStackSlider = control.slider
                            UpdateStackSizes(control)
                        else
                            control.slider:Deactivate()
                        end
                    end,
                },
            },
        },
       
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_DIALOG_CANCEL),
            },

            {
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_GAMEPAD_SELECT_OPTION),
                callback = function()
                    PickupInventoryItem(dialog.data.bagId, dialog.data.slotIndex, self.splitStackSlider:GetValue())
                    TryPlaceInventoryItemInEmptySlot(dialog.data.bagId)
                    SCENE_MANAGER:HideCurrentScene()
                end,
            },
        }
    })
end

function ZO_GamepadInventory:InitializeKeybindStrip()
    self.rootKeybindDescriptor = 
    {
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = GetString(SI_GAMEPAD_INVENTORY_EQUIPPED_MORE_ACTIONS),
            keybind = "UI_SHORTCUT_TERTIARY",
            order = 1000,
            visible = function()
                return self.selectedItemUniqueId ~= nil
            end,

            callback = function()
                self:ShowActions()
            end,
        },
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = GetString(SI_ITEM_ACTION_STACK_ALL),
            keybind = "UI_SHORTCUT_LEFT_STICK",
            order = 1500,
            disabledDuringSceneHiding = true,
            callback = function()
                StackBag(BAG_BACKPACK)
            end,
        },
    }
    
    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.rootKeybindDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:Select() end, nil, function() return not self.categoryList:IsEmpty() end)
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.rootKeybindDescriptor, GAME_NAVIGATION_TYPE_BUTTON)

    self.itemFilterKeybindStripDescriptor = 
    {
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = GetString(SI_GAMEPAD_INVENTORY_ACTION_LIST_KEYBIND),
            keybind = "UI_SHORTCUT_TERTIARY",
            order = 1000,
            visible = function()
                return self.selectedItemUniqueId ~= nil
            end,

            callback = function()
                self:ShowActions()
            end,
        },
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = GetString(SI_ITEM_ACTION_STACK_ALL),
            keybind = "UI_SHORTCUT_LEFT_STICK",
            order = 1500,
            disabledDuringSceneHiding = true,
            callback = function()
                StackBag(BAG_BACKPACK)
            end,
        },
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = GetString(SI_ITEM_ACTION_DESTROY),
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            order = 2000,
            disabledDuringSceneHiding = true,

            visible = function()
                return self.selectedItemUniqueId ~= nil
            end,

            callback = function()
                local targetData = self.itemList:GetTargetData()
                if(ZO_InventorySlot_CanDestroyItem(targetData) and ZO_InventorySlot_InitiateDestroyItem(targetData)) then
                    self.itemList:Deactivate()
                    self.listWaitingOnDestroyRequest = self.itemList
                end
            end,
        }
    }

    self.toggleCompareModeKeybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,
        name = GetString(SI_GAMEPAD_INVENTORY_TOGGLE_ITEM_COMPARE_MODE),
        keybind = "UI_SHORTCUT_SECONDARY",
        visible = function()
            local targetCategoryData = self.categoryList:GetTargetData()
            if targetCategoryData then
                local equipSlotHasItem = select(2, GetEquippedItemInfo(targetCategoryData.equipSlot))
                return equipSlotHasItem
            end
        end,
        callback = function()
            self.savedVars.useStatComparisonTooltip = not self.savedVars.useStatComparisonTooltip
            self:UpdateRightTooltip()
        end,
    }

    self.quickslotKeybindDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        name = GetString(SI_GAMEPAD_ITEM_ACTION_QUICKSLOT_ASSIGN),
        keybind = "UI_SHORTCUT_SECONDARY",
        order = -500,
        callback = function() self:ShowQuickslot() end,
    }

    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.itemFilterKeybindStripDescriptor, self.itemList)
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.itemFilterKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)

    self.itemActionsKeybindStripDescriptor = {}
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.itemActionsKeybindStripDescriptor, self.itemActionList)
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.itemActionsKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)

    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.rootKeybindDescriptor, self.categoryList)
end

function ZO_GamepadInventory:SetSelectedInventoryData(inventoryData)
    if SCENE_MANAGER:IsShowing("gamepad_inventory_item_actions") then
        if inventoryData then
            if self.selectedItemUniqueId and CompareId64s(inventoryData.uniqueId, self.selectedItemUniqueId) ~= 0 then
                SCENE_MANAGER:HideCurrentScene() -- The previously selected item no longer exists, back out of the command list
            end
        elseif inventoryData == nil and (SCENE_MANAGER:GetPreviousSceneName() == "gamepad_inventory_root") then
            SCENE_MANAGER:HideCurrentScene() -- The equipped item was deleted from the category list, back out of command list
        else
            if self.selectedItemUniqueId then
                SCENE_MANAGER:PopScenes(2) -- The previously selected filter is empty, back out two scenes
            end
        end
    end

    if(inventoryData) then
        self.selectedItemUniqueId = inventoryData.uniqueId
    else
        self.selectedItemUniqueId = nil
    end

    self.itemActions:SetInventorySlot(inventoryData)
end

function ZO_GamepadInventory:UpdateCategoryLeftTooltip(selectedData)
    if not selectedData then return end

    if selectedData.equipSlot and GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, BAG_WORN, selectedData.equipSlot) then
        GAMEPAD_TOOLTIPS:SetStatusLabelText(GAMEPAD_LEFT_TOOLTIP, GetString(SI_GAMEPAD_EQUIPPED_ITEM_HEADER))
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    end
end

local function SetupCategoryList(list)
    list:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)    
    list:AddDataTemplateWithHeader("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
end

function ZO_GamepadInventory:InitializeCategoryList()
    self.categoryList = self:AddList("Category", SetupCategoryList)
    self.categoryList:SetNoItemText(GetString(SI_GAMEPAD_INVENTORY_EMPTY))

    --Match the tooltip to the selected data because it looks nicer
    local function OnSelectedCategoryChanged(list, selectedData)
        self:UpdateCategoryLeftTooltip(selectedData)
    end

    self.categoryList:SetOnSelectedDataChangedCallback(OnSelectedCategoryChanged)

    --Match the functionality to the target data
    local function OnTargetCategoryChanged(list, targetData)
        if targetData then 
            self.selectedEquipSlot = targetData.equipSlot
            self:SetSelectedItemUniqueId(self:GenerateItemSlotData(targetData))
            self.selectedItemFilterType = targetData.filterType
        else
            self:SetSelectedItemUniqueId(nil)
        end

        self.currentlySelectedData = targetData
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.rootKeybindDescriptor)
    end

    self.categoryList:SetOnTargetDataChangedCallback(OnTargetCategoryChanged)
end

function ZO_GamepadInventory:UpdateItemLeftTooltip(selectedData)
    if selectedData then
        GAMEPAD_TOOLTIPS:ResetScrollTooltipToTop(GAMEPAD_RIGHT_TOOLTIP)
        if ZO_InventoryUtils_DoesNewItemMatchFilterType(selectedData, ITEMFILTERTYPE_QUEST) then
            GAMEPAD_TOOLTIPS:LayoutQuestItem(GAMEPAD_LEFT_TOOLTIP, selectedData)
        else
            GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, selectedData.bagId, selectedData.slotIndex)
        end
        if selectedData.isEquippedInCurrentCategory or selectedData.isEquippedInAnotherCategory or selectedData.equipSlot then
            local slotIndex = selectedData.bagId == BAG_WORN and selectedData.slotIndex or nil --equipped quickslottables slotIndex is not the same as slot index's in BAG_WORN
            self:UpdateTooltipEquippedIndicatorText(GAMEPAD_LEFT_TOOLTIP, slotIndex)
        else
            GAMEPAD_TOOLTIPS:ClearStatusLabel(GAMEPAD_LEFT_TOOLTIP)
        end
    end
end

local function MenuEntryTemplateEquality(left, right)
    return left.uniqueId == right.uniqueId
end

local function SetupItemList(list)
    list:AddDataTemplate("ZO_GamepadItemSubEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, MenuEntryTemplateEquality)
    list:AddDataTemplateWithHeader("ZO_GamepadItemSubEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, MenuEntryTemplateEquality, "ZO_GamepadMenuEntryHeaderTemplate")
end

local TIME_NEW_PERSISTS_WHILE_SELECTED_MS = 200

function ZO_GamepadInventory:MarkSelectedItemAsNotNew()
    if self:IsClearNewItemActuallyNew() then
        self.clearNewStatusOnSelectionChanged = true
    end
end

function ZO_GamepadInventory:TryClearNewStatusOnHidden()
    self:TryClearNewStatus()
    self.clearNewStatusCallId = nil
    self.clearNewStatusBagId = nil
    self.clearNewStatusSlotIndex = nil
    self.clearNewStatusUniqueId = nil
end

function ZO_GamepadInventory:PrepareNextClearNewStatus(selectedData)
    self:TryClearNewStatus()
    if selectedData then
        self.clearNewStatusBagId = selectedData.bagId
        self.clearNewStatusSlotIndex = selectedData.slotIndex
        self.clearNewStatusUniqueId = selectedData.uniqueId
        self.clearNewStatusCallId = zo_callLater(self.trySetClearNewFlagCallback, TIME_NEW_PERSISTS_WHILE_SELECTED_MS)
    end
end

function ZO_GamepadInventory:InitializeItemList()
    self.itemList = self:AddList("Items", SetupItemList)

    self.itemList:SetOnSelectedDataChangedCallback(function(list, selectedData)
        self.currentlySelectedData = selectedData
        self:UpdateItemLeftTooltip(selectedData)

        if SCENE_MANAGER:IsShowing("gamepad_inventory_item_filter") or SCENE_MANAGER:IsShowing("gamepad_inventory_item_actions") then
            if self.actionMode == ITEM_LIST_ACTION_MODE then
                self:SetSelectedInventoryData(selectedData)
            end
            self:PrepareNextClearNewStatus(selectedData)
            self.itemList:RefreshVisible()
            self:UpdateRightTooltip()
        end
    end)

    local function OnInventoryUpdated(bagId)
        self:MarkDirty()

        if SCENE_MANAGER:IsShowing("gamepad_inventory_item_actions") then
            self:OnUpdate() --don't wait for next update loop in case item was destroyed and scene/keybinds need immediate update
        end

        if SCENE_MANAGER:IsShowing("gamepad_inventory_root") then
            self:RefreshCategoryList()
        end

        if SCENE_MANAGER:IsShowing("gamepad_inventory_item_filter") then
            KEYBIND_STRIP:UpdateKeybindButton(self.toggleCompareModeKeybindStripDescriptor)
        end
    end

    SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", OnInventoryUpdated)
    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", OnInventoryUpdated)

    SHARED_INVENTORY:RegisterCallback("FullQuestUpdate", OnInventoryUpdated)
    SHARED_INVENTORY:RegisterCallback("SingleQuestUpdate", OnInventoryUpdated)
end



function ZO_GamepadInventory:InitializeItemActionList()
    local function ActionEquality(left, right)
        local actions = self.itemActions:GetActions()
        return actions:GetRawActionName(left.action) == actions:GetRawActionName(right.action)
    end

    local function SetupItemActionList(list)
        list:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, ActionEquality)
    end

    self.itemActionList = self:AddList("ItemActions", SetupItemActionList)

    self.itemActionList:SetOnSelectedDataChangedCallback(function(list, selectedData)
        if SCENE_MANAGER:IsShowing("gamepad_inventory_item_actions") then
            self.itemActions:SetSelectedAction(selectedData and selectedData.action)
        end       
    end)
end

function ZO_GamepadInventory:RefreshHeader()
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

local function UpdateAlliancePoints(control)
    ZO_CurrencyControl_SetSimpleCurrency(control, CURT_ALLIANCE_POINTS, GetCarriedCurrencyAmount(CURT_ALLIANCE_POINTS), ZO_GAMEPAD_CURRENCY_OPTIONS)
    return true
end

local function UpdateTelvarStones(control)
    ZO_CurrencyControl_SetSimpleCurrency(control, CURT_TELVAR_STONES, GetCarriedCurrencyAmount(CURT_TELVAR_STONES), ZO_GAMEPAD_CURRENCY_OPTIONS)
    return true
end

local function UpdateGold(control)
    ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, GetCarriedCurrencyAmount(CURT_MONEY), ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
    return true
end

local function UpdateCapacityString()
    return zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK))
end

function ZO_GamepadInventory:InitializeHeader()
    local function UpdateTitleText()
        if self.actionMode == CATEGORY_ITEM_ACTION_MODE then
            return GetString(SI_GAMEPAD_INVENTORY_CATEGORY_HEADER)
        elseif self.actionMode == ITEM_LIST_ACTION_MODE then
            return self.categoryList:GetTargetData().text
        end
        return nil
    end

    local function RefreshHeader()
        if not self.control:IsHidden() then
            self:RefreshHeader()
        end
    end

    self.headerData = {
        data1HeaderText = GetString(SI_GAMEPAD_INVENTORY_AVAILABLE_FUNDS),
        data1Text = UpdateGold,

        data2HeaderText = GetString(SI_GAMEPAD_INVENTORY_ALLIANCE_POINTS),
        data2Text = UpdateAlliancePoints,

        data3HeaderText = GetString(SI_GAMEPAD_INVENTORY_TELVAR_STONES),
        data3Text = UpdateTelvarStones,

        data4HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
        data4Text = UpdateCapacityString,

        titleText = UpdateTitleText,
    }

    self:RefreshHeader()

    local function RefreshSelectedData()
        if not self.control:IsHidden() then
            self:SetSelectedInventoryData(self.currentlySelectedData)
        end
    end

    local function RefreshHeaderAndSelectedData()
        self:RefreshHeader()
        RefreshSelectedData()
    end

    self.control:RegisterForEvent(EVENT_MONEY_UPDATE, RefreshHeader)
    self.control:RegisterForEvent(EVENT_ALLIANCE_POINT_UPDATE, RefreshHeader)
    self.control:RegisterForEvent(EVENT_TELVAR_STONE_UPDATE, RefreshHeader)
    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, RefreshHeaderAndSelectedData)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, RefreshHeaderAndSelectedData)
    self.control:RegisterForEvent(EVENT_PLAYER_DEAD, RefreshSelectedData)
    self.control:RegisterForEvent(EVENT_PLAYER_REINCARNATED, RefreshSelectedData)
end

function ZO_GamepadInventory:TryEquipItem(inventorySlot)
    if(self.selectedEquipSlot) then    
        local sourceBag, sourceSlot = ZO_Inventory_GetBagAndIndex(inventorySlot)
        RequestMoveItem(sourceBag, sourceSlot, BAG_WORN, self.selectedEquipSlot, 1)
    end
end

function ZO_GamepadInventory:TryClearNewStatus()
    if self.clearNewStatusOnSelectionChanged then
        self.clearNewStatusOnSelectionChanged = false
        SHARED_INVENTORY:ClearNewStatus(self.clearNewStatusBagId, self.clearNewStatusSlotIndex)
    end
end

function ZO_GamepadInventory:IsClearNewItemActuallyNew()
    return self.clearNewStatusBagId and
        SHARED_INVENTORY:IsItemNew(self.clearNewStatusBagId, self.clearNewStatusSlotIndex) and
        SHARED_INVENTORY:GetItemUniqueId(self.clearNewStatusBagId, self.clearNewStatusSlotIndex) == self.clearNewStatusUniqueId
end

function ZO_GamepadInventory:TrySetClearNewFlag(callId)
    if self.clearNewStatusCallId == callId and self:IsClearNewItemActuallyNew() then  
            self.clearNewStatusOnSelectionChanged = true
    end
end

local function GetCategoryTypeFromWeaponType(bagId, slotIndex)
    local weaponType = GetItemWeaponType(bagId, slotIndex)
    if weaponType == WEAPONTYPE_AXE or weaponType == WEAPONTYPE_HAMMER or weaponType == WEAPONTYPE_SWORD or weaponType == WEAPONTYPE_DAGGER then
        return GAMEPAD_WEAPON_CATEGORY_ONE_HANDED_MELEE
    elseif weaponType == WEAPONTYPE_TWO_HANDED_SWORD or weaponType == WEAPONTYPE_TWO_HANDED_AXE or weaponType == WEAPONTYPE_TWO_HANDED_HAMMER then
        return GAMEPAD_WEAPON_CATEGORY_TWO_HANDED_MELEE
    elseif weaponType == WEAPONTYPE_FIRE_STAFF or weaponType == WEAPONTYPE_FROST_STAFF or weaponType == WEAPONTYPE_LIGHTNING_STAFF then
        return GAMEPAD_WEAPON_CATEGORY_DESTRUCTION_STAFF
    elseif weaponType == WEAPONTYPE_HEALING_STAFF then
        return GAMEPAD_WEAPON_CATEGORY_RESTORATION_STAFF
    elseif weaponType == WEAPONTYPE_BOW then
        return GAMEPAD_WEAPON_CATEGORY_TWO_HANDED_BOW
    elseif weaponType ~= WEAPONTYPE_NONE then
        return GAMEPAD_WEAPON_CATEGORY_UNCATEGORIZED
    end
end

local function IsTwoHandedWeaponCategory(categoryType)
    return (categoryType == GAMEPAD_WEAPON_CATEGORY_TWO_HANDED_MELEE or
            categoryType == GAMEPAD_WEAPON_CATEGORY_DESTRUCTION_STAFF or
            categoryType == GAMEPAD_WEAPON_CATEGORY_RESTORATION_STAFF or
            categoryType == GAMEPAD_WEAPON_CATEGORY_TWO_HANDED_BOW)
end

function ZO_GamepadInventory:RefreshCategoryList()
    self.categoryList:Clear()

    do
        local isListEmpty = self:IsItemListEmpty(nil, nil)
        if not isListEmpty then
            local name = GetString(SI_INVENTORY_SUPPLIES)
            local iconFile = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_all.dds"
            local hasAnyNewItems = SHARED_INVENTORY:AreAnyItemsNew(ZO_InventoryUtils_DoesNewItemMatchSupplies, nil, BAG_BACKPACK)
            local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, hasAnyNewItems)
            data:SetIconTintOnSelection(true)
            self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", data)
        end
    end

    do
        local isListEmpty = self:IsItemListEmpty(nil, ITEMFILTERTYPE_CRAFTING)
        if not isListEmpty then
            local name = GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_CRAFTING)
            local iconFile = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_materials.dds"
            local hasAnyNewItems = SHARED_INVENTORY:AreAnyItemsNew(ZO_InventoryUtils_DoesNewItemMatchFilterType, ITEMFILTERTYPE_CRAFTING, BAG_BACKPACK)
            local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, hasAnyNewItems)
            data.filterType = ITEMFILTERTYPE_CRAFTING
            data:SetIconTintOnSelection(true)
            self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", data)
        end
    end

    do
        local isListEmpty = self:IsItemListEmpty(nil, ITEMFILTERTYPE_QUICKSLOT)
        if not isListEmpty then
            local name = GetString(SI_GAMEPAD_INVENTORY_CONSUMABLES)
            local iconFile = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_quickslot.dds"
            local hasAnyNewItems = SHARED_INVENTORY:AreAnyItemsNew(ZO_InventoryUtils_DoesNewItemMatchFilterType, ITEMFILTERTYPE_QUICKSLOT, BAG_BACKPACK)
            local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, hasAnyNewItems)
            data.filterType = ITEMFILTERTYPE_QUICKSLOT
            data:SetIconTintOnSelection(true)
            self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", data)
        end
    end

    do
        local questCache = SHARED_INVENTORY:GenerateFullQuestCache()
        if next(questCache) then
            local name = GetString(SI_GAMEPAD_INVENTORY_QUEST_ITEMS)
            local iconFile = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_quest.dds"
            local data = ZO_GamepadEntryData:New(name, iconFile)
            data.filterType = ITEMFILTERTYPE_QUEST
            data:SetIconTintOnSelection(true)
            self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", data)            
        end
    end

    local twoHandIconFile
    local firstEntry = true
    for i, equipSlot in ZO_Character_EnumerateOrderedEquipSlots() do
        local locked = IsLockedWeaponSlot(equipSlot)
        local isListEmpty = self:IsItemListEmpty(equipSlot, nil)
        if not locked and not isListEmpty then
            local name = zo_strformat(SI_CHARACTER_EQUIP_SLOT_FORMAT, GetString("SI_EQUIPSLOT", equipSlot))
            local iconFile, slotHasItem = GetEquippedItemInfo(equipSlot)
            if not slotHasItem then
                iconFile = nil
            end

            --special case where a two handed weapon icon shows up in offhand slot at lower opacity
            local weaponCategoryType = GetCategoryTypeFromWeaponType(BAG_WORN, equipSlot)
            if iconFile 
                and (equipSlot == EQUIP_SLOT_MAIN_HAND or equipSlot == EQUIP_SLOT_BACKUP_MAIN) 
                and IsTwoHandedWeaponCategory(weaponCategoryType) then
                twoHandIconFile = iconFile
            end

            local offhandTransparency
            if twoHandIconFile and (equipSlot == EQUIP_SLOT_OFF_HAND or equipSlot == EQUIP_SLOT_BACKUP_OFF) then
                iconFile = twoHandIconFile
                twoHandIconFile = nil
                offhandTransparency = 0.5
            end
            ----
            local function DoesNewItemMatchEquipSlot(itemData)
                return ZO_Character_DoesEquipSlotUseEquipType(equipSlot, itemData.equipType)
            end

            local hasAnyNewItems = SHARED_INVENTORY:AreAnyItemsNew(DoesNewItemMatchEquipSlot, nil, BAG_BACKPACK)
            
            local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, hasAnyNewItems)
            data:SetMaxIconAlpha(offhandTransparency)
            data.equipSlot = equipSlot
            data.filterType = weaponCategoryType ~= nil and ITEMFILTERTYPE_WEAPONS or ITEMFILTERTYPE_ARMOR

            if firstEntry then
                self.categoryList:AddEntry("ZO_GamepadItemEntryTemplateWithHeader", data)
                data:SetHeader(GetString(SI_GAMEPAD_INVENTORY_EQUIPMENT_HEADER))
                firstEntry = false
            else
                self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", data)
            end
        end
    end

    self.categoryList:Commit()
end

local DEFAULT_GAMEPAD_ITEM_SORT =
{
    bestItemCategoryName = { tiebreaker = "name" },
    name = { tiebreaker = "requiredLevel" },
    requiredLevel = { tiebreaker = "requiredVeterankRank", isNumeric = true },
    requiredVeterankRank = { tiebreaker = "iconFile", isNumeric = true },
    iconFile = { tiebreaker = "uniqueId" },
    uniqueId = { isId64 = true },
}

function ZO_GamepadInventory_DefaultItemSortComparator(left, right)
    return ZO_TableOrderingFunction(left, right, "bestItemCategoryName", DEFAULT_GAMEPAD_ITEM_SORT, ZO_SORT_ORDER_UP)
end

local function GetBestItemCategoryDescription(itemData)
    if itemData.equipType == EQUIP_TYPE_INVALID then
        return GetString("SI_ITEMTYPE", itemData.itemType)
    end

    local categoryType = GetCategoryTypeFromWeaponType(itemData.bagId, itemData.slotIndex)
    if categoryType ==  GAMEPAD_WEAPON_CATEGORY_UNCATEGORIZED then
        local weaponType = GetItemWeaponType(itemData.bagId, itemData.slotIndex)
        return GetString("SI_WEAPONTYPE", weaponType)
    elseif categoryType then
        return GetString("SI_GAMEPADWEAPONCATEGORY", categoryType)
    end

    local armorType = GetItemArmorType(itemData.bagId, itemData.slotIndex)
    if armorType ~= ARMORTYPE_NONE then
        return GetString("SI_ARMORTYPE", armorType)
    end

    return GetString("SI_ITEMTYPE", itemData.itemType)
end

local function GetItemDataFilterComparator(filteredEquipSlot, nonEquipableFilterType)
    return function(itemData)
        if filteredEquipSlot then
            return ZO_Character_DoesEquipSlotUseEquipType(filteredEquipSlot, itemData.equipType)
        end

        if nonEquipableFilterType then
            return ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, nonEquipableFilterType)
        end
        
        return ZO_InventoryUtils_DoesNewItemMatchSupplies(itemData)
    end
end

function ZO_GamepadInventory:IsItemListEmpty(filteredEquipSlot, nonEquipableFilterType)
    local comparator = GetItemDataFilterComparator(filteredEquipSlot, nonEquipableFilterType)
    return SHARED_INVENTORY:IsFilteredSlotDataEmpty(comparator, BAG_BACKPACK, BAG_WORN)
end

function ZO_GamepadInventory:GetNumSlots(bag)
    return GetNumBagUsedSlots(bag), GetBagSize(bag)
end

function ZO_GamepadInventory:RefreshItemList()
    self.itemList:Clear()
    if self.categoryList:IsEmpty() then return end

    local filteredEquipSlot = self.categoryList:GetTargetData().equipSlot
    local nonEquipableFilterType = self.categoryList:GetTargetData().filterType
    local filteredDataTable

    local isQuestItem = nonEquipableFilterType == ITEMFILTERTYPE_QUEST
    --special case for quest items
    if isQuestItem then
        filteredDataTable = {}
        local questCache = SHARED_INVENTORY:GenerateFullQuestCache()
        for _, questItems in pairs(questCache) do
            for _, questItem in pairs(questItems) do            
                ZO_InventorySlot_SetType(questItem, SLOT_TYPE_QUEST_ITEM)
                table.insert(filteredDataTable, questItem)
            end         
        end
    else
        local comparator = GetItemDataFilterComparator(filteredEquipSlot, nonEquipableFilterType)

        filteredDataTable = SHARED_INVENTORY:GenerateFullSlotData(comparator, BAG_BACKPACK, BAG_WORN)
        for _, itemData in pairs(filteredDataTable) do
            itemData.bestItemCategoryName = zo_strformat(SI_INVENTORY_HEADER, GetBestItemCategoryDescription(itemData))
            if itemData.bagId == BAG_WORN then
                itemData.isEquippedInCurrentCategory = false
                itemData.isEquippedInAnotherCategory = false
                if itemData.slotIndex == filteredEquipSlot then
                    itemData.isEquippedInCurrentCategory = true
                else
                    itemData.isEquippedInAnotherCategory = true
                end
            else
                local slotIndex = GetItemCurrentActionBarSlot(itemData.bagId, itemData.slotIndex)
                itemData.isEquippedInCurrentCategory = slotIndex and true or nil
            end
            ZO_InventorySlot_SetType(itemData, SLOT_TYPE_GAMEPAD_INVENTORY_ITEM)
        end
    end
    table.sort(filteredDataTable, ZO_GamepadInventory_DefaultItemSortComparator)

    local lastBestItemCategoryName
    for i, itemData in ipairs(filteredDataTable) do
        local nextItemData = filteredDataTable[i + 1]

        local data = ZO_GamepadEntryData:New(itemData.name, itemData.iconFile)
        data:InitializeInventoryVisualData(itemData)

        local remaining, duration
        if isQuestItem then 
            remaining, duration = GetQuestToolCooldownInfo(itemData.questIndex, itemData.toolIndex)
        else
            remaining, duration = GetItemCooldownInfo(itemData.bagId, itemData.slotIndex)
        end
        if remaining > 0 and duration > 0 then
            data:SetCooldown(remaining, duration)
        end

        if itemData.bestItemCategoryName ~= lastBestItemCategoryName then
            lastBestItemCategoryName = itemData.bestItemCategoryName
            
            data:SetHeader(lastBestItemCategoryName)
            self.itemList:AddEntry("ZO_GamepadItemSubEntryTemplateWithHeader", data)
        else
            self.itemList:AddEntry("ZO_GamepadItemSubEntryTemplate", data)
        end
    end

    self.itemList:Commit()

    if self.itemList:IsEmpty() then
        SCENE_MANAGER:Hide("gamepad_inventory_item_filter")
    end
end

function ZO_GamepadInventory:GenerateItemSlotData(item)
    if not item then return nil end
    if not item.equipSlot then return nil end

    local slotData = SHARED_INVENTORY:GenerateSingleSlotData(BAG_WORN, item.equipSlot)

    if not slotData then
        return nil
    end

    ZO_InventorySlot_SetType(slotData, SLOT_TYPE_GAMEPAD_INVENTORY_ITEM)
    return slotData
end

function ZO_GamepadInventory:RefreshItemActionList()
    self.itemActionList:Clear()

    local targetData = self.actionMode == ITEM_LIST_ACTION_MODE and self.itemList:GetTargetData() or self:GenerateItemSlotData(self.categoryList:GetTargetData())    
    self:SetSelectedInventoryData(targetData)

    local actions = self.itemActions:GetSlotActions()
    local numActions = actions:GetNumSlotActions()

    for i = 1, numActions do
        local action = actions:GetSlotAction(i)
        local data = ZO_GamepadEntryData:New(actions:GetRawActionName(action))
        data.action = action
        self.itemActionList:AddEntry("ZO_GamepadItemEntryTemplate", data)
    end

    self.itemActionList:Commit()

    if targetData and numActions == 0 then
        --If there is an item selected and it has no actions it may be on cooldown so refresh until its cooldown is up.
        self:MarkDirty()
    end
end

function ZO_GamepadInventory:InitializeItemActions()
    self.itemActions = ZO_ItemSlotActionsController:New(KEYBIND_STRIP_ALIGN_LEFT)
end

function ZO_GamepadInventory:UpdateRightTooltip()
    local targetCategoryData = self.categoryList:GetTargetData()
    if targetCategoryData and targetCategoryData.equipSlot then
        local selectedItemData = self.currentlySelectedData
        local equipSlotHasItem = select(2, GetEquippedItemInfo(targetCategoryData.equipSlot))
        if selectedItemData and (not equipSlotHasItem or self.savedVars.useStatComparisonTooltip) then
            GAMEPAD_TOOLTIPS:LayoutItemStatComparison(GAMEPAD_RIGHT_TOOLTIP, selectedItemData.bagId, selectedItemData.slotIndex, targetCategoryData.equipSlot)
            GAMEPAD_TOOLTIPS:SetStatusLabelText(GAMEPAD_RIGHT_TOOLTIP, GetString(SI_GAMEPAD_INVENTORY_ITEM_COMPARE_TOOLTIP_TITLE))
        elseif GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_RIGHT_TOOLTIP, BAG_WORN, targetCategoryData.equipSlot) then
            self:UpdateTooltipEquippedIndicatorText(GAMEPAD_RIGHT_TOOLTIP, targetCategoryData.equipSlot)
        end
    else
        GAMEPAD_TOOLTIPS:ClearStatusLabel(GAMEPAD_RIGHT_TOOLTIP)
    end
end

function ZO_GamepadInventory:UpdateTooltipEquippedIndicatorText(tooltipType, equipSlot)
    ZO_InventoryUtils_UpdateTooltipEquippedIndicatorText(tooltipType, equipSlot)
end

function ZO_GamepadInventory:Select()
    self:DisableCurrentList()
    SCENE_MANAGER:Push("gamepad_inventory_item_filter")
end

function ZO_GamepadInventory:ShowQuickslot()
    local targetData = self.itemList:GetTargetData()
    if targetData then
        GAMEPAD_QUICKSLOT:SetItemToQuickslot(targetData.bagId, targetData.slotIndex)
        SCENE_MANAGER:Push("gamepad_quickslot")
    end
end

function ZO_GamepadInventory:ShowActions()
    SCENE_MANAGER:Push("gamepad_inventory_item_actions")
end

function ZO_GamepadInventory_OnInitialize(control)
    GAMEPAD_INVENTORY = ZO_GamepadInventory:New(control)
end
