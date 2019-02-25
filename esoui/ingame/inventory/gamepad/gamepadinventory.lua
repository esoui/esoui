ZO_GamepadInventory = ZO_Gamepad_ParametricList_Screen:Subclass()

ZO_GAMEPAD_INVENTORY_SCENE_NAME = "gamepad_inventory_root"

ZO_GAMEPAD_CONFIRM_DESTROY_DIALOG = "GAMEPAD_CONFIRM_DESTROY_ITEM_PROMPT"
ZO_GAMEPAD_SPLIT_STACK_DIALOG = "GAMEPAD_SPLIT_STACK"

local CATEGORY_ITEM_ACTION_MODE = 1
local ITEM_LIST_ACTION_MODE = 2
local CRAFT_BAG_ACTION_MODE = 3

local INVENTORY_TAB_INDEX = 1
local CRAFT_BAG_TAB_INDEX = 2

local INVENTORY_CATEGORY_LIST = "categoryList"
local INVENTORY_ITEM_LIST = "itemList"
local INVENTORY_CRAFT_BAG_LIST = "craftBagList"

local BLOCK_TABBAR_CALLBACK = true

--[[ Public  API ]]--
function ZO_GamepadInventory:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_GamepadInventory:Initialize(control)
    GAMEPAD_INVENTORY_ROOT_SCENE = ZO_Scene:New(ZO_GAMEPAD_INVENTORY_SCENE_NAME, SCENE_MANAGER)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_CREATE, false, GAMEPAD_INVENTORY_ROOT_SCENE)

    -- need this earlier than deferred init so trade can split stacks before inventory is possibly viewed
    self:InitializeSplitStackDialog()

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

    self.trySetClearNewFlagCallback =   function(callId)
                                            self:TrySetClearNewFlag(callId)
                                        end

    local function RefreshVisualLayer()
        if self.scene:IsShowing() then
            if self.actionMode == CATEGORY_ITEM_ACTION_MODE then
                self:RefreshCategoryList()
            end
        end
    end

    control:RegisterForEvent(EVENT_CANCEL_MOUSE_REQUEST_DESTROY_ITEM, OnCancelDestroyItemRequest)
    control:RegisterForEvent(EVENT_VISUAL_LAYER_CHANGED, RefreshVisualLayer)
    control:SetHandler("OnUpdate", OnUpdate)
end

function ZO_GamepadInventory:OnDeferredInitialize()
    local SAVED_VAR_DEFAULTS =
    {
        useStatComparisonTooltip = true,
    }
    self.savedVars = ZO_SavedVars:NewAccountWide("ZO_Ingame_SavedVariables", 2, "GamepadInventory", SAVED_VAR_DEFAULTS)

    self:SetListsUseTriggerKeybinds(true)

    -- setup our lists
    self:InitializeCategoryList()
    self:InitializeItemList()
    self:InitializeCraftBagList()

    self:InitializeHeader()

    self:InitializeKeybindStrip()

    self:InitializeConfirmDestroyDialog()

    self:InitializeItemActions()

    local function RefreshCurrencies()
        if not self.control:IsHidden() then
            self:RefreshHeader(BLOCK_TABBAR_CALLBACK)
            --Refresh the currency tooltip if it is open.
            if self.currentlySelectedData.isCurrencyEntry then
                self:UpdateCategoryLeftTooltip(self.currentlySelectedData)
            end
        end
    end

    self.control:RegisterForEvent(EVENT_CURRENCY_UPDATE, RefreshCurrencies)
    self.control:RegisterForEvent(EVENT_CURRENCY_CAPS_CHANGED, RefreshCurrencies)

    local function RefreshSelectedData()
        if not self.control:IsHidden() then
            self:SetSelectedInventoryData(self.currentlySelectedData)
        end
    end

    self.control:RegisterForEvent(EVENT_PLAYER_DEAD, RefreshSelectedData)
    self.control:RegisterForEvent(EVENT_PLAYER_REINCARNATED, RefreshSelectedData)

    local function OnInventoryUpdated(bagId)
        self:MarkDirty()
        local currentList = self:GetCurrentList()
        if self.scene:IsShowing() then
            -- we only want to update immediately if we are in the gamepad inventory scene
            if currentList == self.categoryList then
                self:RefreshCategoryList()
            elseif currentList == self.itemList then
                if self.selectedItemFilterType == ITEMFILTERTYPE_JEWELRY or self.selectedItemFilterType == ITEMFILTERTYPE_ARMOR or self.selectedItemFilterType == ITEMFILTERTYPE_WEAPONS then
                    KEYBIND_STRIP:UpdateKeybindButton(self.toggleCompareModeKeybindStripDescriptor)
                end
            end
            RefreshSelectedData() --dialog will refresh selected when it hides, so only do it if it's not showing
            self:RefreshHeader(BLOCK_TABBAR_CALLBACK)
        end
    end

    SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", OnInventoryUpdated)
    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", OnInventoryUpdated)

    SHARED_INVENTORY:RegisterCallback("FullQuestUpdate", OnInventoryUpdated)
    SHARED_INVENTORY:RegisterCallback("SingleQuestUpdate", OnInventoryUpdated)

    self:SwitchActiveList(INVENTORY_CATEGORY_LIST)
    ZO_GamepadGenericHeader_SetActiveTabIndex(self.header, INVENTORY_TAB_INDEX)
end

-- override of ZO_Gamepad_ParametricList_Screen:OnStateChanged
function ZO_GamepadInventory:OnStateChanged(oldState, newState)
    if newState == SCENE_SHOWING then
        self:PerformDeferredInitialize()

        --figure out which list to land on
        local listToActivate = self.previousListType or INVENTORY_CATEGORY_LIST
        -- We normally do not want to enter the gamepad inventory on the item list
        -- the exception is if we are coming back to the inventory, like from looting a container
        if listToActivate == INVENTORY_ITEM_LIST and not SCENE_MANAGER:WasSceneOnStack(ZO_GAMEPAD_INVENTORY_SCENE_NAME) then
            listToActivate = INVENTORY_CATEGORY_LIST
        end

        -- switching the active list will handle activating/refreshing header, keybinds, etc.
        self:SwitchActiveList(listToActivate)

        ZO_InventorySlot_SetUpdateCallback(function() self:RefreshItemActions() end)
    elseif newState == SCENE_HIDING then
        ZO_InventorySlot_SetUpdateCallback(nil)
        self:Deactivate()
        self:DeactivateHeader()
    elseif newState == SCENE_HIDDEN then
        --clear the currentListType so we can refresh it when we re-enter
        self:SwitchActiveList(nil)

        self.listWaitingOnDestroyRequest = nil
        self:TryClearNewStatusOnHidden()

        self:ClearActiveKeybinds()
        ZO_SavePlayerConsoleProfile()
    end
end

function ZO_GamepadInventory:OnUpdate(currentFrameTimeSeconds)
    --if no currentFrameTimeSeconds a manual update was called from outside the update loop.
    if not currentFrameTimeSeconds or (self.nextUpdateTimeSeconds and (currentFrameTimeSeconds >= self.nextUpdateTimeSeconds)) then
        self.nextUpdateTimeSeconds = nil

        if self.actionMode == ITEM_LIST_ACTION_MODE then
            self:RefreshItemList()
            -- it's possible we removed the last item from this list
            -- so we want to switch back to the category list
            if self.itemList:IsEmpty() then
                self:SwitchActiveList(INVENTORY_CATEGORY_LIST)
            else
                -- don't refresh item actions if we are switching back to the category view
                -- otherwise we get keybindstrip errors (Item actions will try to add an "A" keybind
                -- and we already have an "A" keybind)
                self:UpdateRightTooltip()
                self:RefreshItemActions()
            end
        elseif self.actionMode == CRAFT_BAG_ACTION_MODE then
            self:RefreshCraftBagList()
            self:RefreshItemActions()
        else -- CATEGORY_ITEM_ACTION_MODE
            self:UpdateCategoryLeftTooltip(self.categoryList:GetTargetData())
        end
    end

    if self.updateItemActions then
        self.updateItemActions = nil
        if not ZO_Dialogs_IsShowing(ZO_GAMEPAD_INVENTORY_ACTION_DIALOG) then
            -- don't refresh item actions if we are in the category view
            -- otherwise we get a keybind conflict
            if self.actionMode ~= CATEGORY_ITEM_ACTION_MODE then
                self:RefreshItemActions()
            end
        end
    end
end

do
    local GAMEPAD_INVENTORY_UPDATE_DELAY_S = .01

    function ZO_GamepadInventory:MarkDirty()
        if not self.nextUpdateTimeSeconds then
            self.nextUpdateTimeSeconds = GetFrameTimeSeconds() + GAMEPAD_INVENTORY_UPDATE_DELAY_S
        end
    end
end

function ZO_GamepadInventory:OnInventoryShown()
    TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_OPENED)

    if GetUnitLevel("player") >= GetWeaponSwapUnlockedLevel() then
        TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_OPENED_AND_WEAPON_SETS_AVAILABLE)
    end
    if AreAnyItemsStolen(INVENTORY_BACKPACK) then
        TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_OPENED_AND_STOLEN_ITEMS_PRESENT)
    end
end

function ZO_GamepadInventory:SwitchActiveList(listDescriptor)
    if listDescriptor == self.currentListType then return end

    self.previousListType = self.currentListType
    self.currentListType = listDescriptor

    -- TODO: Better way to handle this?
    if self.previousListType == INVENTORY_ITEM_LIST then
        KEYBIND_STRIP:RemoveKeybindButton(self.quickslotAssignKeybindStripDescriptor)
        KEYBIND_STRIP:RemoveKeybindButton(self.toggleCompareModeKeybindStripDescriptor)

        self.listWaitingOnDestroyRequest = nil
        self:TryClearNewStatusOnHidden()
        ZO_SavePlayerConsoleProfile()
    end

    GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:Reset(GAMEPAD_RIGHT_TOOLTIP)

    -- if our scene isn't showing we shouldn't actually switch the lists
    -- we'll rely on the scene showing to set the list
    if self.scene:IsShowing() then
        if listDescriptor == INVENTORY_CATEGORY_LIST then
            self:OnInventoryShown()

            self:RefreshCategoryList()
            self:SetCurrentList(self.categoryList)

            self:SetActiveKeybinds(self.categoryListKeybindStripDescriptor)

            self:SetSelectedItemUniqueId(self:GenerateItemSlotData(self.categoryList:GetTargetData()))
            self.actionMode = CATEGORY_ITEM_ACTION_MODE
            self:RefreshHeader()
            self:ActivateHeader()
        elseif listDescriptor == INVENTORY_ITEM_LIST then
            self:SetActiveKeybinds(self.itemFilterKeybindStripDescriptor)

            self:RefreshItemList()
            self:SetCurrentList(self.itemList)

            if self.selectedItemFilterType == ITEMFILTERTYPE_QUICKSLOT then
                KEYBIND_STRIP:AddKeybindButton(self.quickslotAssignKeybindStripDescriptor)
                TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_OPENED_AND_QUICKSLOTS_AVAILABLE)
            elseif self.selectedItemFilterType == ITEMFILTERTYPE_QUEST then
                KEYBIND_STRIP:AddKeybindButton(self.quickslotAssignKeybindStripDescriptor)
            elseif self.selectedItemFilterType == ITEMFILTERTYPE_JEWELRY or self.selectedItemFilterType == ITEMFILTERTYPE_ARMOR or self.selectedItemFilterType == ITEMFILTERTYPE_WEAPONS then
                KEYBIND_STRIP:AddKeybindButton(self.toggleCompareModeKeybindStripDescriptor)
            end

            self:SetSelectedItemUniqueId(self.itemList:GetTargetData())
            self.actionMode = ITEM_LIST_ACTION_MODE
            self:RefreshItemActions()
            self:UpdateRightTooltip()
            self:RefreshHeader(BLOCK_TABBAR_CALLBACK)
            self:DeactivateHeader()
        elseif listDescriptor == INVENTORY_CRAFT_BAG_LIST then
            self:SetActiveKeybinds(self.craftBagKeybindStripDescriptor)

            self:RefreshCraftBagList()
            self:SetCurrentList(self.craftBagList)

            self:SetSelectedItemUniqueId(self.craftBagList:GetTargetData())
            self.actionMode = CRAFT_BAG_ACTION_MODE
            self:RefreshItemActions()
            self:RefreshHeader()
            self:ActivateHeader()
            self:LayoutCraftBagTooltip(GAMEPAD_RIGHT_TOOLTIP)

            TriggerTutorial(TUTORIAL_TRIGGER_CRAFT_BAG_OPENED)
        end

        self:RefreshActiveKeybinds()
    else
        self.actionMode = nil
    end
end

-------------
-- Dialogs --
-------------

function ZO_GamepadInventory:InitializeConfirmDestroyDialog()
    local function ReleaseDialog(destroyItem)
        RespondToDestroyRequest(destroyItem == true)
        ZO_Dialogs_ReleaseDialogOnButtonPress(ZO_GAMEPAD_CONFIRM_DESTROY_DIALOG)
    end

    ZO_Dialogs_RegisterCustomDialog(ZO_GAMEPAD_CONFIRM_DESTROY_DIALOG,
    {
        blockDialogReleaseOnPress = true,

        canQueue = true,

        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.BASIC,
            allowRightStickPassThrough = true,
        },

        setup = function(dialog)
            self.destroyConfirmText = nil
            dialog:setupFunc()
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
    ZO_Dialogs_RegisterCustomDialog(ZO_GAMEPAD_SPLIT_STACK_DIALOG,
    {
        canQueue = true,

        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.ITEM_SLIDER,
        },

        setup = function(dialog, data)
            dialog:setupFunc()
        end,

        title =
        {
            text = SI_GAMEPAD_INVENTORY_SPLIT_STACK_TITLE,
        },

        mainText = 
        {
            text = SI_GAMEPAD_INVENTORY_SPLIT_STACK_PROMPT,
        },

        OnSliderValueChanged =  function(dialog, sliderControl, value)
                                    dialog.sliderValue1:SetText(dialog.data.stackSize - value)
                                    dialog.sliderValue2:SetText(value)
                                end,

        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_DIALOG_CANCEL),
            },
            {
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_GAMEPAD_SELECT_OPTION),
                callback = function(dialog)
                    local dialogData = dialog.data
                    local quantity = ZO_GenericGamepadItemSliderDialogTemplate_GetSliderValue(dialog)
                    PickupInventoryItem(dialogData.bagId, dialogData.slotIndex, quantity)
                    TryPlaceInventoryItemInEmptySlot(dialogData.bagId)
                end,
            },
        }
    })
end

function ZO_GamepadInventory:OnActionsDialogFinished()
    if self.scene:IsShowing() then
        -- make sure to wipe out the keybinds added by actions
        self:SetActiveKeybinds(self.currentKeybindDescriptor)
        --restore the selected inventory item
        if self.actionMode == CATEGORY_ITEM_ACTION_MODE then
            --if we refresh item actions we will get a keybind conflict
            local currentList = self:GetCurrentList()
            if currentList then
                local targetData = currentList:GetTargetData()
                if currentList == self.categoryList then
                    targetData = self:GenerateItemSlotData(targetData)
                end
                self:SetSelectedItemUniqueId(targetData)
            end
        else
            self:RefreshItemActions()
        end
        --refresh so keybinds react to newly selected item
        self:RefreshActiveKeybinds()

        self:OnUpdate()
        if self.actionMode == CATEGORY_ITEM_ACTION_MODE then
            self:RefreshCategoryList()
        end
    end
end

--------------
-- Keybinds --
--------------

function ZO_GamepadInventory:InitializeKeybindStrip()
    self.categoryListKeybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            order = -500,
            callback = function() self:Select() end,
            visible = function() return not self.categoryList:IsEmpty() and not self.currentlySelectedData.isCurrencyEntry end,
        },
        {
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
            name = GetString(SI_ITEM_ACTION_STACK_ALL),
            keybind = "UI_SHORTCUT_LEFT_STICK",
            order = 1500,
            disabledDuringSceneHiding = true,
            callback = function()
                StackBag(BAG_BACKPACK)
            end,
        },
        {  
            name = GetString(SI_ITEM_ACTION_STOW_MATERIALS),
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            order = 2000,
            disabledDuringSceneHiding = true,
            visible = function()
                          return IsESOPlusSubscriber() and CanAnyItemsBeStoredInCraftBag(BAG_BACKPACK)
                      end,
            callback = function()
                ZO_Inventory_TryStowAllMaterials()
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.categoryListKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)

    self.itemFilterKeybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
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
            name = GetString(SI_ITEM_ACTION_STACK_ALL),
            keybind = "UI_SHORTCUT_LEFT_STICK",
            order = 1500,
            disabledDuringSceneHiding = true,
            callback = function()
                StackBag(BAG_BACKPACK)
            end,
        },
        {
            name = GetString(SI_ITEM_ACTION_DESTROY),
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            order = 2000,
            disabledDuringSceneHiding = true,

            visible = function()
                local targetData = self.itemList:GetTargetData()
                return self.selectedItemUniqueId ~= nil and targetData ~= nil and ZO_InventorySlot_CanDestroyItem(targetData)
            end,

            callback = function()
                local targetData = self.itemList:GetTargetData()
                if ZO_InventorySlot_CanDestroyItem(targetData) and ZO_InventorySlot_InitiateDestroyItem(targetData) then
                    self.itemList:Deactivate()
                    self.listWaitingOnDestroyRequest = self.itemList
                end
            end
        }
    }

    local function ItemListBackFunction()
        self:SwitchActiveList(INVENTORY_CATEGORY_LIST)
        PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
    end
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.itemFilterKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, ItemListBackFunction)

    self.quickslotAssignKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        name = GetString(SI_GAMEPAD_ITEM_ACTION_QUICKSLOT_ASSIGN),
        keybind = "UI_SHORTCUT_SECONDARY",
        order = -500,
        visible = function()
            local targetData = self.itemList:GetTargetData()
            if targetData and ZO_InventorySlot_CanQuickslotItem(targetData) then
                return true
            end
        end,
        callback = function()
            self:ShowQuickslot()
        end,
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

    self.craftBagKeybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
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
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.craftBagKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

function ZO_GamepadInventory:RemoveKeybinds()
    if self.currentKeybindDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentKeybindDescriptor)
    end
end

function ZO_GamepadInventory:AddKeybinds()
    if self.currentKeybindDescriptor then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.currentKeybindDescriptor)
    end
end

function ZO_GamepadInventory:SetActiveKeybinds(keybindDescriptor)
    self:ClearSelectedInventoryData() --clear all the bindings from the action list

    self:RemoveKeybinds()

    self.currentKeybindDescriptor = keybindDescriptor

    self:AddKeybinds()
end

function ZO_GamepadInventory:ClearActiveKeybinds()
    self:SetActiveKeybinds(nil)
end

function ZO_GamepadInventory:RefreshActiveKeybinds()
    if self.currentKeybindDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentKeybindDescriptor)
    end
end

function ZO_GamepadInventory:InitializeItemActions()
    self.itemActions = ZO_ItemSlotActionsController:New(KEYBIND_STRIP_ALIGN_LEFT)
end

-- Calling this function will add keybinds to the strip, likely using the primary key
-- The primary key will conflict with the category keybind descriptor if added
function ZO_GamepadInventory:RefreshItemActions()
    local targetData
    local actionMode = self.actionMode
    if actionMode == ITEM_LIST_ACTION_MODE then
        targetData = self.itemList:GetTargetData()
    elseif actionMode == CRAFT_BAG_ACTION_MODE then
        targetData = self.craftBagList:GetTargetData()
    else -- CATEGORY_ITEM_ACTION_MODE
        targetData = self:GenerateItemSlotData(self.categoryList:GetTargetData())
    end

    self:SetSelectedInventoryData(targetData)

    if targetData and targetData.IsOnCooldown and targetData:IsOnCooldown() then
        --If there is an item selected and it has a cooldown, let the refresh function get called until it is no longer in cooldown
        self.updateItemActions = true
    end
end

-----------------------------
-- Selected Inventory Data --
-----------------------------

function ZO_GamepadInventory:SetSelectedItemUniqueId(selectedData)
    if selectedData then
        self.selectedItemUniqueId = selectedData.uniqueId
    else
        self.selectedItemUniqueId = nil
    end
end

function ZO_GamepadInventory:SetSelectedInventoryData(inventoryData)
    -- the action dialog will trigger a refresh when it's finished so no need to refresh now
    -- this also prevents issues where we get 2 single slot updates while showing but only refresh for the first one
    if ZO_Dialogs_IsShowing(ZO_GAMEPAD_INVENTORY_ACTION_DIALOG) then
        if inventoryData then
            if self.selectedItemUniqueId and CompareId64s(inventoryData.uniqueId, self.selectedItemUniqueId) ~= 0 then
                ZO_Dialogs_ReleaseDialog(ZO_GAMEPAD_INVENTORY_ACTION_DIALOG) -- The previously selected item no longer exists, back out of the command list
            end
        elseif self.currentListType == INVENTORY_CATEGORY_LIST then
            ZO_Dialogs_ReleaseDialog(ZO_GAMEPAD_INVENTORY_ACTION_DIALOG) -- The equipped item was deleted from the category list, back out of command list
        elseif self.selectedItemUniqueId then
            ZO_Dialogs_ReleaseDialog(ZO_GAMEPAD_INVENTORY_ACTION_DIALOG) -- The previously selected filter is empty
        end
    end

    self:SetSelectedItemUniqueId(inventoryData)
    self.itemActions:SetInventorySlot(inventoryData)

end

function ZO_GamepadInventory:ClearSelectedInventoryData()
    self:SetSelectedItemUniqueId(nil)

    self.itemActions:SetInventorySlot(nil)
end

-------------------
-- Category List --
-------------------

function ZO_GamepadInventory:UpdateCategoryLeftTooltip(selectedData)
    if not selectedData then return end

    if selectedData.equipSlot and GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, BAG_WORN, selectedData.equipSlot) then
        local isHidden, highestPriorityVisualLayerThatIsShowing = WouldEquipmentBeHidden(selectedData.equipSlot or EQUIP_SLOT_NONE)
        
        if isHidden then
            GAMEPAD_TOOLTIPS:SetStatusLabelText(GAMEPAD_LEFT_TOOLTIP, GetString(SI_GAMEPAD_EQUIPPED_ITEM_HEADER), nil, ZO_SELECTED_TEXT:Colorize(GetHiddenByStringForVisualLayer(highestPriorityVisualLayerThatIsShowing)))
        else
            GAMEPAD_TOOLTIPS:SetStatusLabelText(GAMEPAD_LEFT_TOOLTIP, GetString(SI_GAMEPAD_EQUIPPED_ITEM_HEADER))
        end
    elseif selectedData.isCurrencyEntry then
        local statText = ""
        local valueText = GetString(SI_INVENTORY_CURRENCIES)
        GAMEPAD_TOOLTIPS:SetStatusLabelText(GAMEPAD_LEFT_TOOLTIP, statText, valueText)
        GAMEPAD_TOOLTIPS:LayoutCurrencies(GAMEPAD_LEFT_TOOLTIP)
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
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.categoryListKeybindStripDescriptor)
    end

    self.categoryList:SetOnTargetDataChangedCallback(OnTargetCategoryChanged)
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

function ZO_GamepadInventory:AddFilteredBackpackCategoryIfPopulated(filterType, iconFile)
    local isListEmpty = self:IsItemListEmpty(nil, filterType)
    if not isListEmpty then
        local name = GetString("SI_ITEMFILTERTYPE", filterType)
        local hasAnyNewItems = SHARED_INVENTORY:AreAnyItemsNew(ZO_InventoryUtils_DoesNewItemMatchFilterType, filterType, BAG_BACKPACK)
        local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, hasAnyNewItems)
        data.filterType = filterType
        data:SetIconTintOnSelection(true)
        self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", data)
    end
end

function ZO_GamepadInventory:RefreshCategoryList()
    self.categoryList:Clear()

    -- Currencies
    do
        local name = GetString(SI_INVENTORY_CURRENCIES)
        local iconFile = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_currencies.dds"
        local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, false)
        data.isCurrencyEntry = true
        data:SetIconTintOnSelection(true)
        self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", data)
    end

    -- Supplies
    -- Supplies is a catch all category for non-equipment items that don't fall into one of the specific categories below
    -- If a new filtered category is added make sure to modify ZO_InventoryUtils_DoesNewItemMatchSupplies to match
    -- otherwise items will show up in both the categories
    do
        local isListEmpty = self:IsItemListEmpty()
        if not isListEmpty then
            local name = GetString(SI_INVENTORY_SUPPLIES)
            local iconFile = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_all.dds"
            local hasAnyNewItems = SHARED_INVENTORY:AreAnyItemsNew(ZO_InventoryUtils_DoesNewItemMatchSupplies, nil, BAG_BACKPACK)
            local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, hasAnyNewItems)
            data:SetIconTintOnSelection(true)
            self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", data)
        end
    end

    -- Materials
    self:AddFilteredBackpackCategoryIfPopulated(ITEMFILTERTYPE_CRAFTING, "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_materials.dds")

    -- Consumables
    self:AddFilteredBackpackCategoryIfPopulated(ITEMFILTERTYPE_QUICKSLOT, "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_quickslot.dds")

    -- Furnishing
    self:AddFilteredBackpackCategoryIfPopulated(ITEMFILTERTYPE_FURNISHING, "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_furnishings.dds")

    -- Quest Items
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
    local headersUsed = {}
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

            local function DoesNewItemMatchEquipSlot(itemData)
                return ZO_Character_DoesEquipSlotUseEquipType(equipSlot, itemData.equipType)
            end

            local hasAnyNewItems = SHARED_INVENTORY:AreAnyItemsNew(DoesNewItemMatchEquipSlot, nil, BAG_BACKPACK)
            
            local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, hasAnyNewItems)
            data:SetMaxIconAlpha(offhandTransparency)
            data.equipSlot = equipSlot
            data.filterType = (GetItemFilterTypeInfo(BAG_WORN, equipSlot)) -- first filter only

            if (equipSlot == EQUIP_SLOT_POISON or equipSlot == EQUIP_SLOT_BACKUP_POISON) then
                data.stackCount = select(2, GetItemInfo(BAG_WORN, equipSlot))
            end

            --Headers for Equipment Visual Categories (Weapons, Apparel, Accessories): display header for the first equip slot of a category to be visible 
            local visualCategory = ZO_Character_GetEquipSlotVisualCategory(equipSlot)
            if headersUsed[visualCategory] == nil then
                self.categoryList:AddEntry("ZO_GamepadItemEntryTemplateWithHeader", data)
                data:SetHeader(GetString("SI_EQUIPSLOTVISUALCATEGORY", visualCategory))

                headersUsed[visualCategory] = true
            --No Header Needed
            else
                self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", data)
            end
        end
    end

    self.categoryList:Commit()
end

---------------
-- Item List --
---------------

function ZO_GamepadInventory:UpdateItemLeftTooltip(selectedData)
    if selectedData then
        GAMEPAD_TOOLTIPS:ResetScrollTooltipToTop(GAMEPAD_RIGHT_TOOLTIP)
        if ZO_InventoryUtils_DoesNewItemMatchFilterType(selectedData, ITEMFILTERTYPE_QUEST) then
            if selectedData.toolIndex then
                GAMEPAD_TOOLTIPS:LayoutQuestItem(GAMEPAD_LEFT_TOOLTIP, GetQuestToolQuestItemId(selectedData.questIndex, selectedData.toolIndex))
            else
                GAMEPAD_TOOLTIPS:LayoutQuestItem(GAMEPAD_LEFT_TOOLTIP, GetQuestConditionQuestItemId(selectedData.questIndex, selectedData.stepIndex, selectedData.conditionIndex))
            end
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

function ZO_GamepadInventory:InitializeItemList()
    self.itemList = self:AddList("Items", SetupItemList)

    self.itemList:SetOnSelectedDataChangedCallback(function(list, selectedData)
        self.currentlySelectedData = selectedData
        self:UpdateItemLeftTooltip(selectedData)

        self:SetSelectedInventoryData(selectedData)
        self:PrepareNextClearNewStatus(selectedData)
        self.itemList:RefreshVisible()
        self:UpdateRightTooltip()
        self:RefreshActiveKeybinds()
    end)
end

local DEFAULT_GAMEPAD_ITEM_SORT =
{
    bestItemCategoryName = { tiebreaker = "name" },
    name = { tiebreaker = "requiredLevel" },
    requiredLevel = { tiebreaker = "requiredChampionPoints", isNumeric = true },
    requiredChampionPoints = { tiebreaker = "iconFile", isNumeric = true },
    iconFile = { tiebreaker = "uniqueId" },
    uniqueId = { isId64 = true },
}

function ZO_GamepadInventory_DefaultItemSortComparator(left, right)
    return ZO_TableOrderingFunction(left, right, "bestItemCategoryName", DEFAULT_GAMEPAD_ITEM_SORT, ZO_SORT_ORDER_UP)
end

local GAMEPAD_QUEST_ITEM_SORT =
{
    bestItemCategoryName = { tiebreaker = "name" },
    name = {},
}

function ZO_GamepadInventory_QuestItemSortComparator(left, right)
    return ZO_TableOrderingFunction(left, right, "bestItemCategoryName", GAMEPAD_QUEST_ITEM_SORT, ZO_SORT_ORDER_UP)
end

local function GetBestItemCategoryDescription(itemData)
    if itemData.itemType == ITEMTYPE_FURNISHING then
        local furnitureDataId = GetItemFurnitureDataId(itemData.bagId, itemData.slotIndex)
        if furnitureDataId ~= 0 then
            local categoryId, subcategoryId = GetFurnitureDataCategoryInfo(furnitureDataId)
            if categoryId then
                local categoryName = GetFurnitureCategoryInfo(categoryId)
                if categoryName ~= "" then
                    return categoryName
                end
            end
        end
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

    return ZO_InventoryUtils_Gamepad_GetBestItemCategoryDescription(itemData)
end

local function GetBestQuestItemCategoryDescription(questItemData)
    local questItemCategory = GAMEPAD_QUEST_ITEM_CATEGORY_NOT_SLOTTABLE
    if CanQuickslotQuestItemById(questItemData.questItemId) then
        questItemCategory = GAMEPAD_QUEST_ITEM_CATEGORY_SLOTTABLE
    end

    return GetString("SI_GAMEPADQUESTITEMCATEGORY", questItemCategory)
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

    local targetCategoryData = self.categoryList:GetTargetData()
    local filteredEquipSlot = targetCategoryData.equipSlot
    local nonEquipableFilterType = targetCategoryData.filterType
    local filteredDataTable

    local isQuestItemFilter = nonEquipableFilterType == ITEMFILTERTYPE_QUEST
    --special case for quest items
    if isQuestItemFilter then
        filteredDataTable = {}
        local questCache = SHARED_INVENTORY:GenerateFullQuestCache()
        for _, questItems in pairs(questCache) do
            for _, questItem in pairs(questItems) do
                table.insert(filteredDataTable, questItem)
                questItem.bestItemCategoryName = zo_strformat(SI_INVENTORY_HEADER, GetBestQuestItemCategoryDescription(questItem))
            end
        end
        table.sort(filteredDataTable, ZO_GamepadInventory_QuestItemSortComparator)
    else
        local comparator = GetItemDataFilterComparator(filteredEquipSlot, nonEquipableFilterType)

        filteredDataTable = SHARED_INVENTORY:GenerateFullSlotData(comparator, BAG_BACKPACK, BAG_WORN)
        for _, itemData in pairs(filteredDataTable) do
            itemData.bestItemCategoryName = zo_strformat(SI_INVENTORY_HEADER, GetBestItemCategoryDescription(itemData))
        end
        table.sort(filteredDataTable, ZO_GamepadInventory_DefaultItemSortComparator)
    end

    local lastBestItemCategoryName
    for i, itemData in ipairs(filteredDataTable) do
        local nextItemData = filteredDataTable[i + 1]

        local entryData = ZO_GamepadEntryData:New(itemData.name, itemData.iconFile)
        entryData:InitializeInventoryVisualData(itemData)

        if itemData.bagId == BAG_WORN then
            entryData.isEquippedInCurrentCategory = itemData.slotIndex == filteredEquipSlot
            entryData.isEquippedInAnotherCategory = itemData.slotIndex ~= filteredEquipSlot

            entryData.isHiddenByWardrobe = WouldEquipmentBeHidden(itemData.slotIndex or EQUIP_SLOT_NONE)
        elseif isQuestItemFilter then
            local slotIndex = FindActionSlotMatchingSimpleAction(ACTION_TYPE_QUEST_ITEM, itemData.questItemId)
            entryData.isEquippedInCurrentCategory = slotIndex ~= nil
        else
            local slotIndex = FindActionSlotMatchingItem(itemData.bagId, itemData.slotIndex)
            entryData.isEquippedInCurrentCategory = slotIndex ~= nil
        end

        local remaining, duration
        if isQuestItemFilter then
            if itemData.toolIndex then
                remaining, duration = GetQuestToolCooldownInfo(itemData.questIndex, itemData.toolIndex)
            elseif itemData.stepIndex and itemData.conditionIndex then
                remaining, duration = GetQuestItemCooldownInfo(itemData.questIndex, itemData.stepIndex, itemData.conditionIndex)
            end

            ZO_InventorySlot_SetType(entryData, SLOT_TYPE_QUEST_ITEM)
        else
            remaining, duration = GetItemCooldownInfo(itemData.bagId, itemData.slotIndex)

            ZO_InventorySlot_SetType(entryData, SLOT_TYPE_GAMEPAD_INVENTORY_ITEM)
        end
        if remaining > 0 and duration > 0 then
            entryData:SetCooldown(remaining, duration)
        end

        entryData:SetIgnoreTraitInformation(true)

        if itemData.bestItemCategoryName ~= lastBestItemCategoryName then
            lastBestItemCategoryName = itemData.bestItemCategoryName

            entryData:SetHeader(lastBestItemCategoryName)
            self.itemList:AddEntry("ZO_GamepadItemSubEntryTemplateWithHeader", entryData)
        else
            self.itemList:AddEntry("ZO_GamepadItemSubEntryTemplate", entryData)
        end
    end

    self.itemList:Commit()
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

--------------------
-- Craft Bag List --
--------------------

function ZO_GamepadInventory:InitializeCraftBagList()
    local function OnSelectedDataCallback(list, selectedData)
        self.currentlySelectedData = selectedData
        self:UpdateItemLeftTooltip(selectedData)

        local currentList = self:GetCurrentList()
        if currentList == self.craftBagList or ZO_Dialogs_IsShowing(ZO_GAMEPAD_INVENTORY_ACTION_DIALOG) then
            self:SetSelectedInventoryData(selectedData)
            self.craftBagList:RefreshVisible()
        end
    end

    local SETUP_LIST_LOCALLY = true
    local DONT_USE_TRIGGERS = false -- the parametric list screen will take care of the triggers
    self.craftBagList = self:AddList("CraftBag", SETUP_LIST_LOCALLY, ZO_GamepadInventoryList, BAG_VIRTUAL, SLOT_TYPE_CRAFT_BAG_ITEM, OnSelectedDataCallback, nil, nil, nil, DONT_USE_TRIGGERS)
    self.craftBagList:SetNoItemText(GetString(SI_INVENTORY_ERROR_CRAFT_BAG_EMPTY))
end

function ZO_GamepadInventory:RefreshCraftBagList()
    self.craftBagList:RefreshList()
end

function ZO_GamepadInventory:LayoutCraftBagTooltip()
    local title
    local description
    if HasCraftBagAccess() then
        title = GetString(SI_ESO_PLUS_STATUS_UNLOCKED)
        description = GetString(SI_CRAFT_BAG_STATUS_ESO_PLUS_UNLOCKED_DESCRIPTION)
    else
        title =  GetString(SI_ESO_PLUS_STATUS_LOCKED)
        description = GetString(SI_CRAFT_BAG_STATUS_LOCKED_DESCRIPTION)
    end

    GAMEPAD_TOOLTIPS:LayoutTitleAndMultiSectionDescriptionTooltip(GAMEPAD_RIGHT_TOOLTIP, title, description)
end

------------
-- Header --
------------

function ZO_GamepadInventory:RefreshHeader(blockCallback)
    local currentList = self:GetCurrentList()
    local headerData
    if currentList == self.craftBagList then
        headerData = self.craftBagHeaderData
    elseif currentList == self.categoryList then
        headerData = self.categoryHeaderData
    else
        headerData = self.itemListHeaderData
    end

    ZO_GamepadGenericHeader_Refresh(self.header, headerData, blockCallback)
end

local function UpdateGold(control)
    ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER), ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
    return true
end

local function UpdateCapacityString()
    return zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK))
end

function ZO_GamepadInventory:InitializeHeader()
    local function UpdateTitleText()
        return self.categoryList:GetTargetData().text
    end

    local tabBarEntries =
        {
            {
                text = GetString(SI_GAMEPAD_INVENTORY_CATEGORY_HEADER),
                callback = function()
                    self:SwitchActiveList(INVENTORY_CATEGORY_LIST)
                end,
            },
            {
                text = GetString(SI_GAMEPAD_INVENTORY_CRAFT_BAG_HEADER),
                callback = function()
                    self:SwitchActiveList(INVENTORY_CRAFT_BAG_LIST)
                end,
            },
        }

    self.categoryHeaderData = {
        tabBarEntries = tabBarEntries,

        data1HeaderText = GetString(SI_GAMEPAD_INVENTORY_AVAILABLE_FUNDS),
        data1Text = UpdateGold,

        data2HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
        data2Text = UpdateCapacityString,
    }

    self.craftBagHeaderData = {
        tabBarEntries = tabBarEntries,

        data1HeaderText = GetString(SI_GAMEPAD_INVENTORY_AVAILABLE_FUNDS),
        data1Text = UpdateGold,
    }

    self.itemListHeaderData = {
        titleText = UpdateTitleText,

        data1HeaderText = GetString(SI_GAMEPAD_INVENTORY_AVAILABLE_FUNDS),
        data1Text = UpdateGold,

        data2HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
        data2Text = UpdateCapacityString,
    }

    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_CREATE)
end

function ZO_GamepadInventory:TryEquipItem(inventorySlot)
    if self.selectedEquipSlot then
        local sourceBag, sourceSlot = ZO_Inventory_GetBagAndIndex(inventorySlot)
        local function DoEquip()
            RequestMoveItem(sourceBag, sourceSlot, BAG_WORN, self.selectedEquipSlot, 1)
        end

        if ZO_InventorySlot_WillItemBecomeBoundOnEquip(sourceBag, sourceSlot) then
            local itemQuality = select(8, GetItemInfo(sourceBag, sourceSlot))
            local itemQualityColor = GetItemQualityColor(itemQuality)
            ZO_Dialogs_ShowPlatformDialog("CONFIRM_EQUIP_ITEM", {onAcceptCallback = DoEquip}, {mainTextParams = {itemQualityColor:Colorize(GetItemName(sourceBag, sourceSlot))}})
        else
            DoEquip()
        end
    end
end

function ZO_GamepadInventory:ActivateHeader()
    ZO_GamepadGenericHeader_Activate(self.header)
end

function ZO_GamepadInventory:DeactivateHeader()
    ZO_GamepadGenericHeader_Deactivate(self.header)
end

-------------------
-- New Status --
-------------------

local TIME_NEW_PERSISTS_WHILE_SELECTED_MS = 200

function ZO_GamepadInventory:MarkSelectedItemAsNotNew()
    if self:IsClearNewItemActuallyNew() then
        self.clearNewStatusOnSelectionChanged = true
    end
end

function ZO_GamepadInventory:TryClearNewStatus()
    if self.clearNewStatusOnSelectionChanged then
        self.clearNewStatusOnSelectionChanged = false
        SHARED_INVENTORY:ClearNewStatus(self.clearNewStatusBagId, self.clearNewStatusSlotIndex)
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
    self:SwitchActiveList(INVENTORY_ITEM_LIST)
    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
end

function ZO_GamepadInventory:ShowQuickslot()
    local targetData = self.itemList:GetTargetData()
    if targetData then
        if ZO_InventoryUtils_DoesNewItemMatchFilterType(targetData, ITEMFILTERTYPE_QUEST) then
            local questItemId
            if targetData.toolIndex then
                questItemId = GetQuestToolQuestItemId(targetData.questIndex, targetData.toolIndex)
            else
                questItemId = GetQuestConditionQuestItemId(targetData.questIndex, targetData.stepIndex, targetData.conditionIndex)
            end
            GAMEPAD_QUICKSLOT:SetQuestItemToQuickslot(questItemId)
        else
            GAMEPAD_QUICKSLOT:SetItemToQuickslot(targetData.bagId, targetData.slotIndex)
        end
        SCENE_MANAGER:Push("gamepad_quickslot")
    end
end

function ZO_GamepadInventory:ShowActions()
    --if taking action on an item, it is no longer new
    self:MarkSelectedItemAsNotNew()
    self:RemoveKeybinds()
    self:RefreshItemActions()
    local dialogData =
    {
        finishedCallback = function() self:OnActionsDialogFinished() end,
        itemActions = self.itemActions
    }
    ZO_Dialogs_ShowPlatformDialog(ZO_GAMEPAD_INVENTORY_ACTION_DIALOG, dialogData)
    self:TryClearNewStatus()
    self:GetCurrentList():RefreshVisible()
end

function ZO_GamepadInventory_OnInitialize(control)
    GAMEPAD_INVENTORY = ZO_GamepadInventory:New(control)
end
