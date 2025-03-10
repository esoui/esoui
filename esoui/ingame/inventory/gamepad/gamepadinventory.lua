
ZO_GAMEPAD_INVENTORY_SCENE_NAME = "gamepad_inventory_root"

ZO_GAMEPAD_CONFIRM_DESTROY_DIALOG = "GAMEPAD_CONFIRM_DESTROY_ITEM_PROMPT"
ZO_GAMEPAD_CONFIRM_DESTROY_ARMORY_ITEM_DIALOG = "GAMEPAD_CONFIRM_DESTROY_ARMORY_ITEM_PROMPT"
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
ZO_GamepadInventory = ZO_Gamepad_ParametricList_BagsSearch_Screen:Subclass()

function ZO_GamepadInventory:Initialize(control)
    GAMEPAD_INVENTORY_ROOT_SCENE = ZO_Scene:New(ZO_GAMEPAD_INVENTORY_SCENE_NAME, SCENE_MANAGER)
    ZO_Gamepad_ParametricList_BagsSearch_Screen.Initialize(self, "playerInventoryTextSearch", control, ZO_GAMEPAD_HEADER_TABBAR_CREATE, false, GAMEPAD_INVENTORY_ROOT_SCENE)

    -- need this earlier than deferred init so trade can split stacks before inventory is possibly viewed
    self:InitializeSplitStackDialog()
    self:InitializeConfirmDestroyDialog()
    self:InitializeConfirmDestroyArmoryItemDialog()

    local function OnCancelDestroyItemRequest()
        if self.listWaitingOnDestroyRequest then
            self.listWaitingOnDestroyRequest:Activate()
            self.listWaitingOnDestroyRequest = nil
        end
        ZO_Dialogs_ReleaseDialog(ZO_GAMEPAD_CONFIRM_DESTROY_DIALOG)
    end

    local function OnUpdate(updateControl, currentFrameTimeSeconds)
        if self.scene:IsShowing() then
            self:OnUpdate(currentFrameTimeSeconds)
        end
    end

    self.trySetClearNewFlagCallback = function(callId)
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

    -- Initialize needed bags
    SHARED_INVENTORY:GetOrCreateBagCache(BAG_BACKPACK)
    SHARED_INVENTORY:GetOrCreateBagCache(BAG_WORN)
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

    self:InitializeItemActions()

    local function RefreshCurrencies()
        if not self.control:IsHidden() then
            self:RefreshHeader(BLOCK_TABBAR_CALLBACK)
            --Refresh the currency tooltip if it is open.
            if self.currentlySelectedData.isCurrencyEntry then
                self:UpdateCategoryLeftTooltip(self.currentlySelectedData)
                self:UpdateRightTooltip()
            end
        end
    end

    self.control:RegisterForEvent(EVENT_CURRENCY_UPDATE, RefreshCurrencies)
    self.control:RegisterForEvent(EVENT_CURRENCY_CAPS_CHANGED, RefreshCurrencies)

    local function RefreshSelectedData()
        if not self.control:IsHidden() and self:GetCurrentList() and self:GetCurrentList():IsActive() then
            self:SetSelectedInventoryData(self.currentlySelectedData)
        end
    end

    self.control:RegisterForEvent(EVENT_PLAYER_DEAD, RefreshSelectedData)
    self.control:RegisterForEvent(EVENT_PLAYER_REINCARNATED, RefreshSelectedData)

    local function OnInventoryUpdated(bagId, slotIndex, previousSlotData, isLastUpdateForMessage)
        self:MarkDirty()
        if self.scene:IsShowing() then
            -- we only want to update immediately if we are in the gamepad inventory scene
            local currentList = self:GetCurrentList()
            if currentList == self.categoryList then
                self:RefreshCategoryList()
            elseif currentList == self.itemList then
                if self.selectedItemFilterType == ITEMFILTERTYPE_JEWELRY or self.selectedItemFilterType == ITEMFILTERTYPE_ARMOR or self.selectedItemFilterType == ITEMFILTERTYPE_WEAPONS then
                    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
                end
            end
            RefreshSelectedData() --dialog will refresh selected when it hides, so only do it if it's not showing
            self:RefreshHeader(BLOCK_TABBAR_CALLBACK)
            self:MarkDirtyByBagId(bagId, not isLastUpdateForMessage)
        end
    end

    SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", OnInventoryUpdated)
    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", OnInventoryUpdated)

    SHARED_INVENTORY:RegisterCallback("FullQuestUpdate", OnInventoryUpdated)
    SHARED_INVENTORY:RegisterCallback("SingleQuestUpdate", OnInventoryUpdated)

    self.onRefreshActionsCallback = function()
        if self.itemList and self.itemList:IsActive() then
            SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.itemList)
        end
    end

    local SELECT_DEFAULT_ENTRY = true
    self:SwitchActiveList(INVENTORY_CATEGORY_LIST, SELECT_DEFAULT_ENTRY)
    ZO_GamepadGenericHeader_SetActiveTabIndex(self.header, INVENTORY_TAB_INDEX)
end

-- override of ZO_Gamepad_ParametricList_Screen:OnStateChanged
function ZO_GamepadInventory:OnStateChanged(oldState, newState)
    if newState == SCENE_SHOWING then
        self:PerformDeferredInitialize()

        self:ActivateTextSearch()

        ITEM_PREVIEW_GAMEPAD:RegisterCallback("RefreshActions", self.onRefreshActionsCallback)

        --figure out which list to land on
        local listToActivate = self.previousListType or INVENTORY_CATEGORY_LIST
        -- We normally do not want to enter the gamepad inventory on the item list
        -- the exception is if we are coming back to the inventory, like from looting a container
        if listToActivate == INVENTORY_ITEM_LIST and not SCENE_MANAGER:WasSceneOnStack(ZO_GAMEPAD_INVENTORY_SCENE_NAME) then
            listToActivate = INVENTORY_CATEGORY_LIST
        end

        -- switching the active list will handle activating/refreshing header, keybinds, etc.
        local SELECT_DEFAULT_ENTRY = true
        self:SwitchActiveList(listToActivate, SELECT_DEFAULT_ENTRY)

        self.currentPreviewBagId = nil
        self.currentPreviewSlotIndex = nil

        ZO_InventorySlot_SetUpdateCallback(function() self:RefreshItemActions() end)
    elseif newState == SCENE_HIDING then
        ZO_InventorySlot_SetUpdateCallback(nil)
        self:Deactivate()
        self:DeactivateHeader()
        self:ClearActiveKeybinds()
        self:OnHiding()

        --clear the currentListType so we can refresh it when we re-enter
        self:SwitchActiveList(nil)
    elseif newState == SCENE_HIDDEN then
        self.listWaitingOnDestroyRequest = nil
        self:TryClearNewStatusOnHidden()

        ITEM_PREVIEW_GAMEPAD:UnregisterCallback("RefreshActions", self.onRefreshActionsCallback)

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
            self:UpdateRightTooltip()
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

    if HasFishInBag(INVENTORY_BACKPACK) then
        TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_OPENED_AND_FISH_PRESENT)
    end
end

function ZO_GamepadInventory:OnUpdateSearchResults()
    self:RefreshCategoryList()
    self:RefreshItemList()
    self:RefreshCraftBagList()
end

function ZO_GamepadInventory:SwitchActiveList(listDescriptor, selectDefaultEntry)
    if listDescriptor == self.currentListType then
        return
    end

    -- Needed here for on hide as well as changing tabs
    if self:IsHeaderActive() then
        self:RequestLeaveHeader()
    end

    self.previousListType = self.currentListType
    self.currentListType = listDescriptor

    if self.previousListType == INVENTORY_ITEM_LIST then
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

            --ESO-714374: Order matters as we need to set the current list to CategoryList before we refresh it and need to activate the keybinds last to avoid duplicate keybinds.
            self:SetCurrentList(self.categoryList)
            self:RefreshCategoryList(selectDefaultEntry)

            -- For the case where the previous list didn't have any selectible items which would allow the header to be exited we need to attempt
            -- to exit the header again if there are items in the new list (which there will be in this case as Category List has Currency)
            -- so that we can ensure that the header and main list will not be active at the same time, which would cause a keybind conflict
            if self:IsHeaderActive() then
                self:RequestLeaveHeader()
            end

            self:SetActiveKeybinds(self.categoryListKeybindStripDescriptor)

            self:SetSelectedItemUniqueId(self:GenerateItemSlotData(self.categoryList:GetTargetData()))
            self.actionMode = CATEGORY_ITEM_ACTION_MODE
            self:RefreshHeader()
            self:ActivateHeader()
        elseif listDescriptor == INVENTORY_ITEM_LIST then
            self:SetActiveKeybinds(self.itemFilterKeybindStripDescriptor)

            self:RefreshItemList(selectDefaultEntry)
            self:SetCurrentList(self.itemList)

            if self.selectedItemFilterType == ITEMFILTERTYPE_QUICKSLOT then
                TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_OPENED_AND_QUICKSLOTS_AVAILABLE)
            end

            self:SetSelectedItemUniqueId(self.itemList:GetTargetData())
            self.actionMode = ITEM_LIST_ACTION_MODE
            self:RefreshItemActions()
            self:UpdateItemLeftTooltip(self.itemList:GetTargetData())
            self:UpdateRightTooltip()
            self:RefreshHeader(BLOCK_TABBAR_CALLBACK)
            self:DeactivateHeader()
        elseif listDescriptor == INVENTORY_CRAFT_BAG_LIST then
            self:SetActiveKeybinds(self.craftBagKeybindStripDescriptor)

            self:SetCurrentList(self.craftBagList)

            self:RefreshHeader()
            self:ActivateHeader()

            local TRIGGER_CALLBACK = true
            self:RefreshCraftBagList(TRIGGER_CALLBACK)

            self:SetSelectedItemUniqueId(self.craftBagList:GetTargetData())
            self.actionMode = CRAFT_BAG_ACTION_MODE
            self:RefreshItemActions()

            self:LayoutCraftBagTooltip(GAMEPAD_RIGHT_TOOLTIP)

            TriggerTutorial(TUTORIAL_TRIGGER_CRAFT_BAG_OPENED)
        end

        self:RefreshKeybinds()
    else
        self:DeactivateTextSearch()
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

        gamepadInfo =
        {
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

function ZO_GamepadInventory:InitializeConfirmDestroyArmoryItemDialog()
    local function ReleaseDialog(destroyItem)
        RespondToDestroyRequest(destroyItem == true)
        ZO_Dialogs_ReleaseDialogOnButtonPress(ZO_GAMEPAD_CONFIRM_DESTROY_ARMORY_ITEM_DIALOG)
    end

    ZO_Dialogs_RegisterCustomDialog(ZO_GAMEPAD_CONFIRM_DESTROY_ARMORY_ITEM_DIALOG,
    {
        blockDialogReleaseOnPress = true,

        canQueue = true,

        gamepadInfo =
        {
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
            text = SI_DIALOG_DESTROY_ARMORY_ITEM_TITLE,
        },

        mainText =
        {
            text = SI_GAMEPAD_ARMORY_CONFIRM_DESTROY_ITEM_BODY,
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

        gamepadInfo =
        {
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

        narrationText = function(dialog, itemName)
            --The stack on the right
            local stack2 = dialog.slider:GetValue()
            --The stack on the left
            local stack1 = dialog.data.stackSize - stack2
            return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_GAMEPAD_INVENTORY_SPLIT_STACK_NARRATION_FORMATTER, itemName, stack1, stack2))
        end,

        additionalInputNarrationFunction = function()
            return ZO_GetHorizontalDirectionalInputNarrationData(GetString(SI_GAMEPAD_INVENTORY_SPLIT_STACK_LEFT_NARRATION), GetString(SI_GAMEPAD_INVENTORY_SPLIT_STACK_RIGHT_NARRATION))
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
        self:SetActiveKeybinds(self.keybindStripDescriptor)
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
        self:RefreshKeybinds()

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
            callback = function()
                self:Select()
            end,
            visible = function()
                return (not self.categoryList:IsEmpty()) and self.currentlySelectedData and
                       not (self.currentlySelectedData.isCurrencyEntry or self.currentlySelectedData.isMundusEntry)
            end,
        },
        {
            name = function()
                local targetCategoryData = self.categoryList:GetTargetData()
                if targetCategoryData and targetCategoryData.isMundusEntry then
                    return GetString(SI_STATS_MUNDUS_INFO_BUTTON)
                else
                    return GetString(SI_GAMEPAD_INVENTORY_EQUIPPED_MORE_ACTIONS)
                end
            end,
            keybind = "UI_SHORTCUT_TERTIARY",
            order = 1000,
            visible = function()
                local targetCategoryData = self.categoryList:GetTargetData()
                if targetCategoryData and targetCategoryData.isMundusEntry then
                    if targetCategoryData.data and not targetCategoryData.data.buffIndex then
                        return true
                    end
                    return false
                end
                return self.selectedItemUniqueId ~= nil
            end,
            callback = function()
                local targetCategoryData = self.categoryList:GetTargetData()
                if targetCategoryData and targetCategoryData.isMundusEntry then
                    local helpCategoryIndex, helpIndex = GetMundusStoneHelpIndices()
                    HELP_TUTORIALS_ENTRIES_GAMEPAD:Show(helpCategoryIndex, helpIndex)
                else
                    self:ShowActions()
                end
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

    local function IsQuickSlotEnabled()
        return self.selectedItemFilterType == ITEMFILTERTYPE_QUICKSLOT or self.selectedItemFilterType == ITEMFILTERTYPE_QUEST
    end

    local function IsCompareModeEnabled()
        return self.selectedItemFilterType == ITEMFILTERTYPE_JEWELRY or self.selectedItemFilterType == ITEMFILTERTYPE_ARMOR or self.selectedItemFilterType == ITEMFILTERTYPE_WEAPONS
    end

    self.itemFilterKeybindStripDescriptor =
    {
        {
            alignment = function()
                if IsQuickSlotEnabled() then
                    return KEYBIND_STRIP_ALIGN_LEFT
                elseif IsCompareModeEnabled() then
                    return KEYBIND_STRIP_ALIGN_RIGHT
                end
            end,
            name = function()
                if IsQuickSlotEnabled() then
                    return GetString(SI_GAMEPAD_ITEM_ACTION_QUICKSLOT_ASSIGN)
                elseif IsCompareModeEnabled() then
                    return GetString(SI_GAMEPAD_INVENTORY_TOGGLE_ITEM_COMPARE_MODE)
                end
            end,
            keybind = "UI_SHORTCUT_SECONDARY",
            order = function()
                if IsQuickSlotEnabled() then
                    return -500
                end
            end,
            visible = function()
                if IsQuickSlotEnabled() then
                    local targetData = self.itemList:GetTargetData()
                    if targetData and ZO_InventorySlot_CanQuickslotItem(targetData) then
                        return true
                    end
                elseif IsCompareModeEnabled() then
                    local targetCategoryData = self.categoryList:GetTargetData()
                    if targetCategoryData then
                        local equipSlotHasItem = GetWornItemInfo(BAG_WORN, targetCategoryData.equipSlot)
                        return equipSlotHasItem
                    end
                end
            end,
            callback = function()
                if IsQuickSlotEnabled() then
                    self:ShowQuickslot()
                elseif IsCompareModeEnabled() then
                    self.savedVars.useStatComparisonTooltip = not self.savedVars.useStatComparisonTooltip
                    self:UpdateRightTooltip()
                    --Re-narrate when the stat comparison tooltip is toggled
                    SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.itemList)
                end
            end,
        },
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = GetString(SI_GAMEPAD_INVENTORY_ACTION_LIST_KEYBIND),
            keybind = "UI_SHORTCUT_TERTIARY",
            order = 1000,
            visible = function()
                if self.selectedItemUniqueId ~= nil then
                    return true
                end

                local inventorySlot = self.itemList:GetTargetData()
                if inventorySlot ~= nil and inventorySlot.dataSource ~= nil and inventorySlot.dataSource.questIndex ~= nil and inventorySlot.dataSource.questIndex > 0 then
                    return self.selectedItemFilterType == ITEMFILTERTYPE_QUEST
                end

                return false
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
        },
        {
            name =  function()
                if IsCurrentlyPreviewing() then
                    return GetString(SI_PREVIEW_CLEAR_INVENTORY_PREVIEW)
                else
                    return GetString(SI_CRAFTING_ENTER_PREVIEW_MODE)
                end
            end,
            keybind = "UI_SHORTCUT_QUATERNARY",
            order = 2500,
            disabledDuringSceneHiding = true,
            visible =   function()
                if not IsCurrentlyPreviewing() then
                    local targetData = self.itemList:GetTargetData()
                    return self:CanEntryDataBePreviewed(targetData) and IsCharacterPreviewingAvailable()
                end

                return true
            end,
            callback =  function()
                if IsCurrentlyPreviewing() then
                    self:EndPreview()
                else
                    local targetData = self.itemList:GetTargetData()
                    if targetData ~= nil then
                        self:PreviewInventoryItem(targetData.bagId, targetData.slotIndex)
                    end
                end
                self:RefreshKeybinds()
                SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.itemList)
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.itemFilterKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:OnBackButtonClicked() end)

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

function ZO_GamepadInventory:OnBackButtonClicked()
   if self.currentListType == INVENTORY_ITEM_LIST or self.itemList:IsActive() then
        self:SwitchActiveList(INVENTORY_CATEGORY_LIST)
        PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
        self:EndPreview()
    else
        ZO_Gamepad_ParametricList_BagsSearch_Screen.OnBackButtonClicked(self)
    end
end

function ZO_GamepadInventory:RemoveKeybinds()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_GamepadInventory:AddKeybinds()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_GamepadInventory:SetActiveKeybinds(keybindDescriptor)
    self:ClearSelectedInventoryData() --clear all the bindings from the action list

    self:RemoveKeybinds()

    self.keybindStripDescriptor = keybindDescriptor

    self:AddKeybinds()
end

function ZO_GamepadInventory:ClearActiveKeybinds()
    self:SetActiveKeybinds(nil)
end

function ZO_GamepadInventory:OnTargetChanged(list, targetData, oldTargetData)
    if IsCurrentlyPreviewing() then
        if self:CanEntryDataBePreviewed(targetData) then
            self:PreviewInventoryItem(targetData.bagId, targetData.slotIndex)
        end
    end
end

function ZO_GamepadInventory:RefreshKeybinds()
    ZO_Gamepad_ParametricList_Screen.RefreshKeybinds(self)

    if self:GetCurrentList() and not self:GetCurrentList():IsActive() then
        self:SetSelectedInventoryData(nil)
    end
end

function ZO_GamepadInventory:RequestLeaveHeader()
    ZO_Gamepad_ParametricList_BagsSearch_Screen.RequestLeaveHeader(self)

    local targetData
    local actionMode = self.actionMode
    if actionMode == ITEM_LIST_ACTION_MODE then
        targetData = self.itemList:GetTargetData()

        if self:GetCurrentList() and self:GetCurrentList():IsActive() then
            self:SetSelectedInventoryData(targetData)
        end
    elseif actionMode == CRAFT_BAG_ACTION_MODE then
        targetData = self.craftBagList:GetTargetData()

        if self:GetCurrentList() and self:GetCurrentList():IsActive() then
            self:SetSelectedInventoryData(targetData)
        end
    else -- CATEGORY_ITEM_ACTION_MODE
        targetData = self:GenerateItemSlotData(self.categoryList:GetTargetData())
        self:UpdateCategoryLeftTooltip(self.currentlySelectedData)
        self:UpdateRightTooltip()
    end

    self:SetSelectedItemUniqueId(targetData)
    self:RefreshKeybinds()
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

    if self:GetCurrentList() and self:GetCurrentList():IsActive() then
        self:SetSelectedInventoryData(targetData)
    end

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
        local isHidden, highestPriorityVisualLayerThatIsShowing = WouldEquipmentBeHidden(selectedData.equipSlot or EQUIP_SLOT_NONE, GAMEPLAY_ACTOR_CATEGORY_PLAYER)

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
    elseif selectedData.isMundusEntry then
        GAMEPAD_TOOLTIPS:ClearStatusLabel(GAMEPAD_LEFT_TOOLTIP)
        GAMEPAD_TOOLTIPS:LayoutMundusTooltip(GAMEPAD_LEFT_TOOLTIP, selectedData.data)
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    end
end

function ZO_GamepadInventory.AreCategoryListEntriesEqual(entry1, entry2)
    return entry1 == entry2 or entry1.text == entry2.text
end

function ZO_GamepadInventory:InitializeCategoryList()
    local function SetupCategoryList(list)
        list:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, ZO_GamepadInventory.AreCategoryListEntriesEqual)
        list:AddDataTemplateWithHeader("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, ZO_GamepadInventory.AreCategoryListEntriesEqual, "ZO_GamepadMenuEntryHeaderTemplate")
        list:SetReselectBehavior(ZO_PARAMETRIC_SCROLL_LIST_RESELECT_BEHAVIOR.MATCH_OR_RESET_TO_DEFAULT)
    end

    self.categoryList = self:AddList("Category", SetupCategoryList)
    self.categoryList:SetNoItemText(GetString(SI_GAMEPAD_INVENTORY_EMPTY))

    --Match the tooltip to the selected data because it looks nicer
    local function OnSelectedCategoryChanged(list, selectedData)
        self:UpdateCategoryLeftTooltip(selectedData)
        self:UpdateRightTooltip()
    end

    self.categoryList:SetOnSelectedDataChangedCallback(OnSelectedCategoryChanged)

    --Match the functionality to the target data
    local function OnTargetCategoryChanged(list, targetData, oldTargetData)
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
    return  categoryType == GAMEPAD_WEAPON_CATEGORY_TWO_HANDED_MELEE or
            categoryType == GAMEPAD_WEAPON_CATEGORY_DESTRUCTION_STAFF or
            categoryType == GAMEPAD_WEAPON_CATEGORY_RESTORATION_STAFF or
            categoryType == GAMEPAD_WEAPON_CATEGORY_TWO_HANDED_BOW
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

function ZO_GamepadInventory:GetQuestItemDataFilterComparator(questItemId)
    return self:IsDataInSearchTextResults(ZO_QUEST_ITEMS_FILTER_BAG, questItemId)
end

function ZO_GamepadInventory:RefreshCategoryList(selectDefaultEntry, forceUpdate)
    if self.currentListType == INVENTORY_CATEGORY_LIST or self.categoryList:IsActive() or forceUpdate then
        self.categoryList:Clear()

        --Mundus Entries
        self.mundusEntries = {}
        local activeMundusStoneBuffIndices = { GetUnitActiveMundusStoneBuffIndices("player") }
        local numActiveMundusStoneBuffs = #activeMundusStoneBuffIndices
        local numMundusSlots = GetNumAvailableMundusStoneSlots()
        local isPlayerAtMundusWarningLevel = GetUnitLevel("player") >= GetMundusWarningLevel()
        for i = 1, numMundusSlots do
            local mundusEntry = nil
            if numActiveMundusStoneBuffs >= i then
                local buffName, _, _, buffSlot, _, _, _, _, _, _, abilityId = GetUnitBuffInfo("player", activeMundusStoneBuffIndices[i])
                local mundusStoneIndex = GetAbilityMundusStoneType(abilityId)
                mundusEntry = ZO_GamepadEntryData:New(zo_strformat(SI_STATS_MUNDUS_FORMATTER, buffName), ZO_STAT_MUNDUS_ICONS[mundusStoneIndex])
                mundusEntry.data =
                {
                    name = buffName,
                    description = GetAbilityEffectDescription(buffSlot),
                    buffIndex = activeMundusStoneBuffIndices[i],
                    statEffects = {},
                }
                local numStatsForAbility = GetAbilityNumDerivedStats(abilityId)
                for i = 1, numStatsForAbility do
                    local statType, effectValue = GetAbilityDerivedStatAndEffectByIndex(abilityId, i)
                    local statEffect =
                    {
                        statType = statType,
                        effect = effectValue,
                    }
                    table.insert(mundusEntry.data.statEffects, statEffect)
                end
                self.mundusAdvancedStats = {}
                local numAdvancedStatsForAbility = GetAbilityNumAdvancedStats(abilityId)
                for i = 1, numAdvancedStatsForAbility do
                    local statType, statFormat, effectValue = GetAbilityAdvancedStatAndEffectByIndex(abilityId, i)
                    local statEffect =
                    {
                        statType = statType,
                        format = statFormat,
                        value = effectValue,
                    }
                    table.insert(self.mundusAdvancedStats, statEffect)
                end
            elseif numMundusSlots >= i then
                mundusEntry =  ZO_GamepadEntryData:New(GetString("SI_MUNDUSSTONE", MUNDUS_STONE_INVALID), ZO_STAT_MUNDUS_ICONS[MUNDUS_STONE_INVALID])
                mundusEntry.data =
                {
                    name = GetString(SI_STATS_MUNDUS_NONE_TOOLTIP_TITLE),
                    description = GetString(SI_STATS_MUNDUS_NONE_TOOLTIP_DESCRIPTION),
                }
                if isPlayerAtMundusWarningLevel then
                    mundusEntry:SetNameColors(ZO_ERROR_COLOR, ZO_ERROR_COLOR)
                    mundusEntry:SetIconTint(ZO_ERROR_COLOR, ZO_ERROR_COLOR)
                else
                    local USE_DEFAULT_COLORS = nil
                    mundusEntry:SetNameColors(USE_DEFAULT_COLORS, USE_DEFAULT_COLORS)
                    mundusEntry:SetIconTint(USE_DEFAULT_COLORS, USE_DEFAULT_COLORS)
                end
            end
            if mundusEntry then
                mundusEntry.isMundusEntry = true
                if i == 1 then
                    mundusEntry:SetHeader(GetString(SI_STATS_MUNDUS_TITLE))
                    self.categoryList:AddEntry("ZO_GamepadItemEntryTemplateWithHeader", mundusEntry)
                else
                    self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", mundusEntry)
                end
            end
        end

        -- Currencies
        do
            local name = GetString(SI_INVENTORY_CURRENCIES)
            local iconFile = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_currencies.dds"
            local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, false)
            data.isCurrencyEntry = true
            data:SetIconTintOnSelection(true)
            self.categoryList:AddEntry("ZO_GamepadItemEntryTemplateWithHeader", data)
            data:SetHeader(GetString(SI_GAMEPAD_INVENTORY_PACK_CATEGORY_HEADER))
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

        -- Companion Items
        self:AddFilteredBackpackCategoryIfPopulated(ITEMFILTERTYPE_COMPANION, "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_companionItems.dds")

        -- Quest Items
        do
            local questCache = SHARED_INVENTORY:GenerateFullQuestCache()
            local textSearchFilteredQuestCache = {}
            for _, questItems in pairs(questCache) do
                for _, questItem in pairs(questItems) do
                    if self:GetQuestItemDataFilterComparator(questItem.questItemId) then
                        table.insert(textSearchFilteredQuestCache, questCache)
                    end
                end
            end

            if next(textSearchFilteredQuestCache) then
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
        for _, equipSlot in ZO_Character_EnumerateOrderedEquipSlots() do
            local locked = IsLockedWeaponSlot(equipSlot)
            local isListEmpty = self:IsItemListEmpty(equipSlot, nil)
            if not locked and not isListEmpty then
                local name = zo_strformat(SI_CHARACTER_EQUIP_SLOT_FORMAT, GetString("SI_EQUIPSLOT", equipSlot))
                local slotHasItem, iconFile  = GetWornItemInfo(BAG_WORN, equipSlot)
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
                    -- ESO-752569: Companion items use the same equip slots, but they're categorized as "supplies" (see above), so we need to filter them out here.
                    return ZO_Character_DoesEquipSlotUseEquipType(equipSlot, itemData.equipType) and itemData.actorCategory ~= GAMEPLAY_ACTOR_CATEGORY_COMPANION
                end

                local hasAnyNewItems = SHARED_INVENTORY:AreAnyItemsNew(DoesNewItemMatchEquipSlot, nil, BAG_BACKPACK)

                local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, hasAnyNewItems)
                data:SetMaxIconAlpha(offhandTransparency)
                data.equipSlot = equipSlot
                data.filterType = GetItemFilterTypeInfo(BAG_WORN, equipSlot) -- first filter only

                if equipSlot == EQUIP_SLOT_POISON or equipSlot == EQUIP_SLOT_BACKUP_POISON then
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

        -- Order matters:
        self.categoryList:SetDefaultSelectedIndex(numMundusSlots + 1)
        self.categoryList:Commit()
    end
end

---------------
-- Item List --
---------------

function ZO_GamepadInventory:OnEnterHeader()
    ZO_Gamepad_ParametricList_BagsSearch_Screen.OnEnterHeader(self)

    self:UpdateItemLeftTooltip(nil)
end

function ZO_GamepadInventory:OnLeaveHeader()
    ZO_Gamepad_ParametricList_BagsSearch_Screen.OnLeaveHeader(self)

    if self.currentlySelectedData and self.currentlySelectedData.isCurrencyEntry then
        self:UpdateCategoryLeftTooltip(self.currentlySelectedData)
        self:UpdateRightTooltip()
    else
        self:UpdateItemLeftTooltip(self.currentlySelectedData)
    end
end

function ZO_GamepadInventory:UpdateItemLeftTooltip(selectedData)
    if selectedData and not self:IsHeaderActive() then
        GAMEPAD_TOOLTIPS:ResetScrollTooltipToTop(GAMEPAD_RIGHT_TOOLTIP)
        if selectedData.filterData then
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
        else
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        end
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
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

    local function OnSelectedDataChangedCallback(list, selectedData)
        self.currentlySelectedData = selectedData
        self:UpdateItemLeftTooltip(selectedData)

        if self:GetCurrentList() and self:GetCurrentList():IsActive() then
            self:SetSelectedInventoryData(selectedData)
        end
        self:PrepareNextClearNewStatus(selectedData)
        self.itemList:RefreshVisible()
        self:UpdateRightTooltip()
        self:RefreshKeybinds()
    end

    self.itemList:SetOnSelectedDataChangedCallback(OnSelectedDataChangedCallback)
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
            local categoryId = GetFurnitureDataCategoryInfo(furnitureDataId)
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

function ZO_GamepadInventory:GetItemDataFilterComparator(filteredEquipSlot, nonEquipableFilterType)
    return function(itemData)
        if not self:IsDataInSearchTextResults(itemData.bagId, itemData.slotIndex) then
            return false
        end

        if itemData.actorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION then
            return nonEquipableFilterType == ITEMFILTERTYPE_COMPANION
        end

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
    local comparator = self:GetItemDataFilterComparator(filteredEquipSlot, nonEquipableFilterType)
    return SHARED_INVENTORY:IsFilteredSlotDataEmpty(comparator, BAG_BACKPACK, BAG_WORN)
end

function ZO_GamepadInventory:GetNumSlots(bag)
    return GetNumBagUsedSlots(bag), GetBagSize(bag)
end

do
    local function GetItemNarrationText(entryData, entryControl)
        local narrations = {}

        ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl))

        if IsCurrentlyPreviewing() then
            -- Generate the standard parametric list entry narration
            if ITEM_PREVIEW_GAMEPAD.currentPreviewTypeObject then
                local bagId = ITEM_PREVIEW_GAMEPAD.currentPreviewTypeObject.bag
                local slotIndex = ITEM_PREVIEW_GAMEPAD.currentPreviewTypeObject.slot
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetItemName(bagId, slotIndex)))
                ZO_AppendNarration(narrations, ITEM_PREVIEW_GAMEPAD:GetPreviewSpinnerNarrationText())
            end
        end

        return narrations
    end

    function ZO_GamepadInventory:RefreshItemList(selectDefaultEntry)
        if self.currentListType == INVENTORY_ITEM_LIST or self.itemList:IsActive() then
            -- Order matters:
            local targetCategoryData = self.categoryList:GetTargetData()
            self.itemList:Clear()

            if self.categoryList:IsEmpty() then
                return
            end

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
                        if self:GetQuestItemDataFilterComparator(questItem.questItemId) then
                            table.insert(filteredDataTable, questItem)
                            questItem.bestItemCategoryName = zo_strformat(SI_INVENTORY_HEADER, GetBestQuestItemCategoryDescription(questItem))
                        end
                    end
                end
                table.sort(filteredDataTable, ZO_GamepadInventory_QuestItemSortComparator)
            else
                local comparator = self:GetItemDataFilterComparator(filteredEquipSlot, nonEquipableFilterType)

                filteredDataTable = SHARED_INVENTORY:GenerateFullSlotData(comparator, BAG_BACKPACK, BAG_WORN)
                for _, itemData in pairs(filteredDataTable) do
                    itemData.bestItemCategoryName = zo_strformat(SI_INVENTORY_HEADER, GetBestItemCategoryDescription(itemData))
                end
                table.sort(filteredDataTable, ZO_GamepadInventory_DefaultItemSortComparator)
            end

            local lastBestItemCategoryName
            for _, itemData in ipairs(filteredDataTable) do
                local entryData = ZO_GamepadEntryData:New(itemData.name, itemData.iconFile)
                entryData:InitializeInventoryVisualData(itemData)

                if itemData.bagId == BAG_WORN then
                    entryData.isEquippedInCurrentCategory = itemData.slotIndex == filteredEquipSlot
                    entryData.isEquippedInAnotherCategory = itemData.slotIndex ~= filteredEquipSlot

                    entryData.isHiddenByWardrobe = WouldEquipmentBeHidden(itemData.slotIndex or EQUIP_SLOT_NONE, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
                elseif isQuestItemFilter then
                    local slotIndex = FindActionSlotMatchingSimpleAction(ACTION_TYPE_QUEST_ITEM, itemData.questItemId, HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
                    entryData.isEquippedInCurrentCategory = slotIndex ~= nil
                else
                    local slotIndex = FindActionSlotMatchingItem(itemData.bagId, itemData.slotIndex, HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
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

                entryData.narrationText = GetItemNarrationText
            end

            -- ESO-785986: ItemList keybinds depend on self.selectedItemFilterType
            -- which is set by CategoryList being updated when the ItemList is refreshed
            local DONT_SELECT_DEFAULT = nil
            local FORCE_UPDATE = true
            self:RefreshCategoryList(DONT_SELECT_DEFAULT, FORCE_UPDATE)

            -- ESO-871103: Must refresh the category list first so that self.currentlySelectData
            -- remains data in itemList rather than being set to the selected data in category list
            self.itemList:Commit()
            self:UpdateItemLeftTooltip(self.currentlySelectedData)

            if not ZO_GamepadInventory.AreCategoryListEntriesEqual(targetCategoryData, self.categoryList:GetTargetData()) then
                -- The category has changed; clear the item list and switch to the category list.
                self.itemList:Clear()
                local DO_NOT_SELECT_DEFAULT_ENTRY = false
                self:SwitchActiveList(INVENTORY_CATEGORY_LIST, DO_NOT_SELECT_DEFAULT_ENTRY)
            end
        end
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

--------------------
-- Craft Bag List --
--------------------

function ZO_GamepadInventory:InitializeCraftBagList()
    local function OnSelectedDataChangedCallback(list, selectedData)
        self.currentlySelectedData = selectedData
        self:UpdateItemLeftTooltip(selectedData)

        local currentList = self:GetCurrentList()
        if (currentList == self.craftBagList and self.craftBagList:IsActive()) or ZO_Dialogs_IsShowing(ZO_GAMEPAD_INVENTORY_ACTION_DIALOG) then
            self:SetSelectedInventoryData(selectedData)
            self.craftBagList:RefreshVisible()
        end

        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.craftBagKeybindStripDescriptor)
    end

    local function OnRefreshList(list)
        if list:GetNumItems() == 0 then
            self:RequestEnterHeader()
        else
            self:RequestLeaveHeader()
        end
    end

    local SETUP_LIST_LOCALLY = true
    local DONT_USE_TRIGGERS = false -- the parametric list screen will take care of the triggers
    self.craftBagList = self:AddList("CraftBag", SETUP_LIST_LOCALLY, ZO_GamepadInventoryList, BAG_VIRTUAL, SLOT_TYPE_CRAFT_BAG_ITEM, OnSelectedDataChangedCallback, nil, nil, nil, DONT_USE_TRIGGERS)
    self.craftBagList:SetOnRefreshListCallback(OnRefreshList)
    self.craftBagList:SetNoItemText(GetString(SI_INVENTORY_ERROR_CRAFT_BAG_EMPTY))
    self.craftBagList:SetSearchContext("playerInventoryTextSearch")
end

function ZO_GamepadInventory:RefreshCraftBagList(shouldTriggerRefreshListCallback)
    if self.currentListType == INVENTORY_CRAFT_BAG_LIST or self.craftBagList:IsActive() then
        self.craftBagList:RefreshList(shouldTriggerRefreshListCallback)

        if self.craftBagList:GetNumItems() == 0 then
            if ZO_TextSearchManager.CanFilterByText(TEXT_SEARCH_MANAGER:GetSearchText(self.craftBagList:GetSearchContext())) then
                self.craftBagList:SetNoItemText(GetString(SI_INVENTORY_ERROR_FILTER_EMPTY))
            else
                self.craftBagList:SetNoItemText(GetString(SI_INVENTORY_ERROR_CRAFT_BAG_EMPTY))
            end
            self:RequestEnterHeader()
        end
    end
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

    self.headerData = headerData
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

    local SELECT_DEFAULT_ENTRY = true
    local tabBarEntries =
    {
        {
            text = GetString(SI_GAMEPAD_INVENTORY_CATEGORY_HEADER),
            callback = function()
                self:SwitchActiveList(INVENTORY_CATEGORY_LIST, SELECT_DEFAULT_ENTRY)
            end,
        },
        {
            text = GetString(SI_GAMEPAD_INVENTORY_CRAFT_BAG_HEADER),
            callback = function()
                self:SwitchActiveList(INVENTORY_CRAFT_BAG_LIST, SELECT_DEFAULT_ENTRY)
            end,
        },
    }

    self.categoryHeaderData =
    {
        tabBarEntries = tabBarEntries,

        data1HeaderText = GetString(SI_GAMEPAD_INVENTORY_AVAILABLE_FUNDS),
        data1Text = UpdateGold,
        data1TextNarration = ZO_Currency_GetPlayerCarriedGoldNarration,

        data2HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
        data2Text = UpdateCapacityString,
    }

    self.craftBagHeaderData =
    {
        tabBarEntries = tabBarEntries,

        data1HeaderText = GetString(SI_GAMEPAD_INVENTORY_AVAILABLE_FUNDS),
        data1Text = UpdateGold,
        data1TextNarration = ZO_Currency_GetPlayerCarriedGoldNarration,
    }

    self.itemListHeaderData =
    {
        titleText = UpdateTitleText,

        data1HeaderText = GetString(SI_GAMEPAD_INVENTORY_AVAILABLE_FUNDS),
        data1Text = UpdateGold,
        data1TextNarration = ZO_Currency_GetPlayerCarriedGoldNarration,

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
            local itemDisplayQuality = GetItemDisplayQuality(sourceBag, sourceSlot)
            local itemDisplayQualityColor = GetItemQualityColor(itemDisplayQuality)
            ZO_Dialogs_ShowPlatformDialog("CONFIRM_EQUIP_ITEM", { onAcceptCallback = DoEquip }, { mainTextParams = { itemDisplayQualityColor:Colorize(GetItemName(sourceBag, sourceSlot)) } })
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
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    local targetCategoryData = self.categoryList:GetTargetData()
    if targetCategoryData then
        local selectedItemData = self.currentlySelectedData
        if targetCategoryData.equipSlot then
            local equipSlotHasItem = GetWornItemInfo(BAG_WORN, targetCategoryData.equipSlot)
            if selectedItemData and (not equipSlotHasItem or self.savedVars.useStatComparisonTooltip) then
                GAMEPAD_TOOLTIPS:LayoutItemStatComparison(GAMEPAD_RIGHT_TOOLTIP, selectedItemData.bagId, selectedItemData.slotIndex, targetCategoryData.equipSlot)
                GAMEPAD_TOOLTIPS:SetStatusLabelText(GAMEPAD_RIGHT_TOOLTIP, GetString(SI_GAMEPAD_INVENTORY_ITEM_COMPARE_TOOLTIP_TITLE))
            elseif GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_RIGHT_TOOLTIP, BAG_WORN, targetCategoryData.equipSlot) then
                self:UpdateTooltipEquippedIndicatorText(GAMEPAD_RIGHT_TOOLTIP, targetCategoryData.equipSlot)
            end
        elseif selectedItemData and targetCategoryData.filterType == ITEMFILTERTYPE_COMPANION then
            ZO_LayoutBagItemEquippedComparison(GAMEPAD_RIGHT_TOOLTIP, selectedItemData.bagId, selectedItemData.slotIndex)
        elseif targetCategoryData.isMundusEntry then
            GAMEPAD_TOOLTIPS:SetStatusLabelText(GAMEPAD_RIGHT_TOOLTIP, GetString(SI_GAMEPAD_INVENTORY_ITEM_COMPARE_TOOLTIP_TITLE))
            GAMEPAD_TOOLTIPS:LayoutMundusStatComparison(GAMEPAD_RIGHT_TOOLTIP, targetCategoryData.data.statEffects)
        end
    end
end

function ZO_GamepadInventory:UpdateTooltipEquippedIndicatorText(tooltipType, equipSlot)
    ZO_InventoryUtils_UpdateTooltipEquippedIndicatorText(tooltipType, equipSlot, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
end

function ZO_GamepadInventory:Select()
    local SELECT_DEFAULT_ENTRY = true
    self:SwitchActiveList(INVENTORY_ITEM_LIST, SELECT_DEFAULT_ENTRY)
    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
end

function ZO_GamepadInventory:ShowQuickslot()
    local targetData = self.itemList:GetTargetData()
    local useAccessibleWheel = GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_ACCESSIBLE_QUICKWHEELS)
    if targetData then
        if ZO_InventoryUtils_DoesNewItemMatchFilterType(targetData, ITEMFILTERTYPE_QUEST) then
            local questItemId
            if targetData.toolIndex then
                questItemId = GetQuestToolQuestItemId(targetData.questIndex, targetData.toolIndex)
            else
                questItemId = GetQuestConditionQuestItemId(targetData.questIndex, targetData.stepIndex, targetData.conditionIndex)
            end

            if useAccessibleWheel then
                ACCESSIBLE_ASSIGNABLE_UTILITY_WHEEL_GAMEPAD:SetPendingSimpleAction(ACTION_TYPE_QUEST_ITEM, questItemId)
            else
                GAMEPAD_QUICKSLOT:SetQuestItemToQuickslot(questItemId)
            end
        else
            if useAccessibleWheel then
                ACCESSIBLE_ASSIGNABLE_UTILITY_WHEEL_GAMEPAD:SetPendingItem(targetData.bagId, targetData.slotIndex)
            else
                GAMEPAD_QUICKSLOT:SetItemToQuickslot(targetData.bagId, targetData.slotIndex)
            end
        end

        if useAccessibleWheel then
            ACCESSIBLE_ASSIGNABLE_UTILITY_WHEEL_GAMEPAD:Show({ HOTBAR_CATEGORY_QUICKSLOT_WHEEL })
        else
            SCENE_MANAGER:Push("gamepad_quickslot")
        end
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

function ZO_GamepadInventory:CanEntryDataBePreviewed(data)
    if data then
        if data.slotType == SLOT_TYPE_QUEST_ITEM then
            return false
        end

        local itemActorCategory = GetItemActorCategory(data.bagId, data.slotIndex)
        if itemActorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION and GetInteractionType() ~= INTERACTION_COMPANION_MENU then
            return false
        end
        return CanInventoryItemBePreviewed(data.bagId, data.slotIndex)
    end

    return false
end

function ZO_GamepadInventory:PreviewInventoryItem(bagId, slotIndex)
    if self.currentPreviewBagId ~= bagId or self.currentPreviewSlotIndex ~= slotIndex then
        self.currentPreviewBagId = bagId
        self.currentPreviewSlotIndex = slotIndex

        SYSTEMS:GetObject("itemPreview"):ClearPreviewCollection()
        SYSTEMS:GetObject("itemPreview"):PreviewInventoryItem(bagId, slotIndex)
    end
end

function ZO_GamepadInventory:EndPreview()
    self.currentPreviewBagId = nil
    self.currentPreviewSlotIndex = nil

    SYSTEMS:GetObject("itemPreview"):ClearPreviewCollection()
    ApplyChangesToPreviewCollectionShown()
end

function ZO_GamepadInventory_OnInitialize(control)
    GAMEPAD_INVENTORY = ZO_GamepadInventory:New(control)
end
