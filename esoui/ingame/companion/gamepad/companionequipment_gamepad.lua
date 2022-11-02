local CATEGORY_ITEM_ACTION_MODE = 1
local ITEM_LIST_ACTION_MODE = 2

local INVENTORY_CATEGORY_LIST = "categoryList"
local INVENTORY_ITEM_LIST = "itemList"

-----------------------------
-- Companion Equipment
-----------------------------
ZO_CompanionEquipment_Gamepad = ZO_Gamepad_ParametricList_BagsSearch_Screen:Subclass()

function ZO_CompanionEquipment_Gamepad:Initialize(control)
    COMPANION_EQUIPMENT_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control)

    COMPANION_EQUIPMENT_GAMEPAD_SCENE = ZO_InteractScene:New("companionEquipmentGamepad", SCENE_MANAGER, ZO_COMPANION_MANAGER:GetInteraction())
    COMPANION_EQUIPMENT_GAMEPAD_SCENE:AddFragment(COMPANION_EQUIPMENT_GAMEPAD_FRAGMENT)

    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_BagsSearch_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, COMPANION_EQUIPMENT_GAMEPAD_SCENE)

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

    self:SetTextSearchContext("companionEquipmentTextSearch")

    -- Initialize needed bags
    SHARED_INVENTORY:GetOrCreateBagCache(BAG_BACKPACK)
    SHARED_INVENTORY:GetOrCreateBagCache(BAG_COMPANION_WORN)
end

function ZO_CompanionEquipment_Gamepad:OnDeferredInitialize()
    -- setup our lists
    self:InitializeCategoryList()
    self:InitializeItemList()
    self:SetListsUseTriggerKeybinds(true)

    self:InitializeHeader()

    self:InitializeKeybindStrip()

    self:InitializeItemActions()

    local function RefreshSelectedData()
        if not self.control:IsHidden() and self:GetCurrentList() and self:GetCurrentList():IsActive() then
            self:SetSelectedInventoryData(self.currentlySelectedData)
        end
    end

    local function OnInventoryUpdated(bagId, slotIndex, previousSlotData, isLastUpdateForMessage)
        self:MarkDirty()
        if self.scene:IsShowing() then
            -- we only want to update immediately if we are in the gamepad companion equipment scene
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

    local SELECT_DEFAULT_ENTRY = true
    self:SwitchActiveList(INVENTORY_CATEGORY_LIST, SELECT_DEFAULT_ENTRY)
end

function ZO_CompanionEquipment_Gamepad:InitializeItemList()
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

-- override of ZO_Gamepad_ParametricList_Screen:OnStateChanged
function ZO_CompanionEquipment_Gamepad:OnStateChanged(oldState, newState)
    if newState == SCENE_SHOWING then
        self:PerformDeferredInitialize()

        self:ActivateTextSearch()

        --figure out which list to land on
        local listToActivate = self.previousListType or INVENTORY_CATEGORY_LIST
        -- We normally do not want to enter the gamepad companion equipment on the item list
        -- the exception is if we are coming back to the companion equipment, like from looting a container
        if listToActivate == INVENTORY_ITEM_LIST and not SCENE_MANAGER:WasSceneOnStack(self.scene:GetName()) then
            listToActivate = INVENTORY_CATEGORY_LIST
        end

        -- switching the active list will handle activating/refreshing header, keybinds, etc.
        local SELECT_DEFAULT_ENTRY = true
        self:SwitchActiveList(listToActivate, SELECT_DEFAULT_ENTRY)

        self.currentPreviewBagId = nil
        self.currentPreviewSlotIndex = nil

        ZO_InventorySlot_SetUpdateCallback(function() self:RefreshItemActions() end)
    elseif newState == SCENE_SHOWN then
        if self.categoryList:GetNumItems() == 0 then
            self:RequestEnterHeader()
        else
            if not self.categoryList:IsActive() then
                self.categoryList:Activate()
            end
        end
    elseif newState == SCENE_HIDING then
        ZO_InventorySlot_SetUpdateCallback(nil)
        self:Deactivate()
        self:DeactivateHeader()
        self:ClearActiveKeybinds()
        self:OnHiding()
    elseif newState == SCENE_HIDDEN then
        --clear the currentListType so we can refresh it when we re-enter
        self:SwitchActiveList(nil)

        self:TryClearNewStatusOnHidden()
    end
end

function ZO_CompanionEquipment_Gamepad:OnUpdate(currentFrameTimeSeconds)
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
    local GAMEPAD_INVENTORY_UPDATE_DELAY_S = 0.01

    function ZO_CompanionEquipment_Gamepad:MarkDirty()
        if not self.nextUpdateTimeSeconds then
            self.nextUpdateTimeSeconds = GetFrameTimeSeconds() + GAMEPAD_INVENTORY_UPDATE_DELAY_S
        end
    end
end

function ZO_CompanionEquipment_Gamepad:OnUpdatedSearchResults()
    self:RefreshCategoryList()
    self:RefreshItemList()
end

function ZO_CompanionEquipment_Gamepad:SwitchActiveList(listDescriptor, selectDefaultEntry)
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
        self:TryClearNewStatusOnHidden()
    end

    GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:Reset(GAMEPAD_RIGHT_TOOLTIP)

    -- if our scene isn't showing we shouldn't actually switch the lists
    -- we'll rely on the scene showing to set the list
    if self.scene:IsShowing() then
        if listDescriptor == INVENTORY_CATEGORY_LIST then
            self:SetActiveKeybinds(self.categoryListKeybindStripDescriptor)

            self:RefreshCategoryList(selectDefaultEntry)
            self:SetCurrentList(self.categoryList)

            self:SetSelectedItemUniqueId(self:GenerateItemSlotData(self.categoryList:GetTargetData()))
            self.actionMode = CATEGORY_ITEM_ACTION_MODE
            self:RefreshHeader()
            self:ActivateHeader()
        elseif listDescriptor == INVENTORY_ITEM_LIST then
            self:SetActiveKeybinds(self.itemFilterKeybindStripDescriptor)

            self:RefreshItemList(selectDefaultEntry)
            self:SetCurrentList(self.itemList)

            self:SetSelectedItemUniqueId(self.itemList:GetTargetData())
            self.actionMode = ITEM_LIST_ACTION_MODE
            self:RefreshItemActions()
            self:UpdateRightTooltip()
            self:RefreshHeader(BLOCK_TABBAR_CALLBACK)
            self:DeactivateHeader()
        end

        self:RefreshKeybinds()
    else
        self:DeactivateTextSearch()
        self.actionMode = nil
    end
end

function ZO_CompanionEquipment_Gamepad:OnActionsDialogFinished()
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

function ZO_CompanionEquipment_Gamepad:InitializeKeybindStrip()
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
                return not self.categoryList:IsEmpty() and self.currentlySelectedData
            end,
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
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.categoryListKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)

    local function IsCompareModeEnabled()
        return self.selectedItemFilterType == ITEMFILTERTYPE_JEWELRY or self.selectedItemFilterType == ITEMFILTERTYPE_ARMOR or self.selectedItemFilterType == ITEMFILTERTYPE_WEAPONS
    end

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
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.itemFilterKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:OnBackButtonClicked() end)
end

function ZO_CompanionEquipment_Gamepad:OnBackButtonClicked()
   if self.currentListType == INVENTORY_ITEM_LIST or self.itemList:IsActive() then
        self:SwitchActiveList(INVENTORY_CATEGORY_LIST)
        PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
        self:EndPreview()
    else
        ZO_Gamepad_ParametricList_BagsSearch_Screen.OnBackButtonClicked(self)
    end
end

function ZO_CompanionEquipment_Gamepad:RemoveKeybinds()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_CompanionEquipment_Gamepad:AddKeybinds()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_CompanionEquipment_Gamepad:SetActiveKeybinds(keybindDescriptor)
    self:ClearSelectedInventoryData() --clear all the bindings from the action list

    self:RemoveKeybinds()

    self.keybindStripDescriptor = keybindDescriptor

    self:AddKeybinds()
end

function ZO_CompanionEquipment_Gamepad:ClearActiveKeybinds()
    self:SetActiveKeybinds(nil)
end

function ZO_CompanionEquipment_Gamepad:OnTargetChanged(list, targetData, oldTargetData)
    if IsCurrentlyPreviewing() then
        if targetData and CanInventoryItemBePreviewed(targetData.bagId, targetData.slotIndex) then
            self:PreviewInventoryItem(targetData.bagId, targetData.slotIndex)
        end
    end
end

function ZO_CompanionEquipment_Gamepad:RefreshKeybinds()
    ZO_Gamepad_ParametricList_BagsSearch_Screen.RefreshKeybinds(self)

    if self:GetCurrentList() and not self:GetCurrentList():IsActive() then
        self:SetSelectedInventoryData(nil)
    end
end 

function ZO_CompanionEquipment_Gamepad:RequestLeaveHeader()
    ZO_Gamepad_ParametricList_BagsSearch_Screen.RequestLeaveHeader(self)

    local targetData
    local actionMode = self.actionMode
    if actionMode == ITEM_LIST_ACTION_MODE then
        targetData = self.itemList:GetTargetData()

        if self:GetCurrentList() and self:GetCurrentList():IsActive() then
            self:SetSelectedInventoryData(targetData)
        end
    else -- CATEGORY_ITEM_ACTION_MODE
        targetData = self:GenerateItemSlotData(self.categoryList:GetTargetData())
    end

    self:SetSelectedItemUniqueId(targetData)
    self:RefreshKeybinds()
end

function ZO_CompanionEquipment_Gamepad:InitializeItemActions()
    self.itemActions = ZO_ItemSlotActionsController:New(KEYBIND_STRIP_ALIGN_LEFT)
end

-- Calling this function will add keybinds to the strip, likely using the primary key
-- The primary key will conflict with the category keybind descriptor if added
function ZO_CompanionEquipment_Gamepad:RefreshItemActions()
    local targetData
    local actionMode = self.actionMode
    if actionMode == ITEM_LIST_ACTION_MODE then
        targetData = self.itemList:GetTargetData()
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

function ZO_CompanionEquipment_Gamepad:SetSelectedItemUniqueId(selectedData)
    if selectedData then
        self.selectedItemUniqueId = selectedData.uniqueId
    else
        self.selectedItemUniqueId = nil
    end
end

function ZO_CompanionEquipment_Gamepad:SetSelectedInventoryData(inventoryData)
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

function ZO_CompanionEquipment_Gamepad:ClearSelectedInventoryData()
    self:SetSelectedItemUniqueId(nil)

    self.itemActions:SetInventorySlot(nil)
end

-------------------
-- Category List --
-------------------

function ZO_CompanionEquipment_Gamepad:UpdateCategoryLeftTooltip(selectedData)
    if not selectedData then return end

    if selectedData.equipSlot and GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, BAG_COMPANION_WORN, selectedData.equipSlot) then
        local isHidden, highestPriorityVisualLayerThatIsShowing = WouldEquipmentBeHidden(selectedData.equipSlot or EQUIP_SLOT_NONE, GAMEPLAY_ACTOR_CATEGORY_COMPANION)

        if isHidden then
            GAMEPAD_TOOLTIPS:SetStatusLabelText(GAMEPAD_LEFT_TOOLTIP, GetString(SI_GAMEPAD_EQUIPPED_ITEM_HEADER), nil, ZO_SELECTED_TEXT:Colorize(GetHiddenByStringForVisualLayer(highestPriorityVisualLayerThatIsShowing)))
        else
            GAMEPAD_TOOLTIPS:SetStatusLabelText(GAMEPAD_LEFT_TOOLTIP, GetString(SI_GAMEPAD_EQUIPPED_ITEM_HEADER))
        end
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    end
end

function ZO_CompanionEquipment_Gamepad:InitializeCategoryList()
    local function SetupCategoryList(list)
        list:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        list:AddDataTemplateWithHeader("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
    end

    self.categoryList = self:AddList("Category", SetupCategoryList)
    self.categoryList:SetNoItemText(GetString(SI_GAMEPAD_INVENTORY_EMPTY))

    --Match the tooltip to the selected data because it looks nicer
    local function OnSelectedCategoryChanged(list, selectedData)
        self:UpdateCategoryLeftTooltip(selectedData)
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

function ZO_CompanionEquipment_Gamepad:AddFilteredBackpackCategoryIfPopulated(filterType, iconFile)
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

function ZO_CompanionEquipment_Gamepad:RefreshCategoryList(selectDefaultEntry)
    if self.currentListType == INVENTORY_CATEGORY_LIST or self.categoryList:IsActive() then
        self.categoryList:Clear()

        local twoHandIconFile
        local headersUsed = {}
        for _, equipSlot in ZO_Character_EnumerateOrderedEquipSlots(BAG_COMPANION_WORN) do
            local locked = IsLockedWeaponSlot(equipSlot)
            local isListEmpty = self:IsItemListEmpty(equipSlot, nil)
            if not locked and not isListEmpty then
                local name = zo_strformat(SI_CHARACTER_EQUIP_SLOT_FORMAT, GetString("SI_EQUIPSLOT", equipSlot))
                local slotHasItem, iconFile = GetWornItemInfo(BAG_COMPANION_WORN, equipSlot)
                if not slotHasItem then
                    iconFile = nil
                end

                --special case where a two handed weapon icon shows up in offhand slot at lower opacity
                local weaponCategoryType = GetCategoryTypeFromWeaponType(BAG_COMPANION_WORN, equipSlot)
                if iconFile
                    and equipSlot == EQUIP_SLOT_MAIN_HAND
                    and IsTwoHandedWeaponCategory(weaponCategoryType) then
                    twoHandIconFile = iconFile
                end

                local offhandTransparency
                if twoHandIconFile and equipSlot == EQUIP_SLOT_OFF_HAND then
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
                data.filterType = GetItemFilterTypeInfo(BAG_COMPANION_WORN, equipSlot) -- first filter only

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
end

---------------
-- Item List --
---------------

function ZO_CompanionEquipment_Gamepad:UpdateItemLeftTooltip(selectedData)
    if selectedData then
        GAMEPAD_TOOLTIPS:ResetScrollTooltipToTop(GAMEPAD_RIGHT_TOOLTIP)
        if selectedData.filterData then
            GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, selectedData.bagId, selectedData.slotIndex)

            if selectedData.isEquippedInCurrentCategory or selectedData.isEquippedInAnotherCategory or selectedData.equipSlot then
                local slotIndex = selectedData.bagId == BAG_COMPANION_WORN and selectedData.slotIndex or nil --equipped quickslottables slotIndex is not the same as slot index's in BAG_COMPANION_WORN
                self:UpdateTooltipEquippedIndicatorText(GAMEPAD_LEFT_TOOLTIP, slotIndex)
            else
                GAMEPAD_TOOLTIPS:ClearStatusLabel(GAMEPAD_LEFT_TOOLTIP)
            end
        else
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        end
    end
end

local function MenuEntryTemplateEquality(left, right)
    return left.uniqueId == right.uniqueId
end

function ZO_CompanionEquipment_Gamepad:InitializeItemList()
    local function SetupItemList(list)
        list:AddDataTemplate("ZO_GamepadItemSubEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, MenuEntryTemplateEquality)
        list:AddDataTemplateWithHeader("ZO_GamepadItemSubEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, MenuEntryTemplateEquality, "ZO_GamepadMenuEntryHeaderTemplate")
    end

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

local function GetBestItemCategoryDescription(itemData)
    local categoryType = GetCategoryTypeFromWeaponType(itemData.bagId, itemData.slotIndex)
    if categoryType == GAMEPAD_WEAPON_CATEGORY_UNCATEGORIZED then
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

function ZO_CompanionEquipment_Gamepad:GetItemDataFilterComparator(filteredEquipSlot, nonEquipableFilterType)
    return function(itemData)
        if not self:IsSlotInSearchTextResults(itemData.bagId, itemData.slotIndex) then
            return false
        end

        if itemData.actorCategory ~= GAMEPLAY_ACTOR_CATEGORY_COMPANION then
            return false
        end

        if filteredEquipSlot then
            return ZO_Character_DoesEquipSlotUseEquipType(filteredEquipSlot, itemData.equipType)
        end
    end
end

function ZO_CompanionEquipment_Gamepad:IsItemListEmpty(filteredEquipSlot, nonEquipableFilterType)
    local comparator = self:GetItemDataFilterComparator(filteredEquipSlot, nonEquipableFilterType)
    return SHARED_INVENTORY:IsFilteredSlotDataEmpty(comparator, BAG_BACKPACK, BAG_COMPANION_WORN)
end

function ZO_CompanionEquipment_Gamepad:GetNumSlots(bag)
    return GetNumBagUsedSlots(bag), GetBagSize(bag)
end

function ZO_CompanionEquipment_Gamepad:RefreshItemList(selectDefaultEntry)
    if self.currentListType == INVENTORY_ITEM_LIST or self.itemList:IsActive() then
        self.itemList:Clear()

        if self.categoryList:IsEmpty() then
            return
        end

        local targetCategoryData = self.categoryList:GetTargetData()
        local filteredEquipSlot = targetCategoryData.equipSlot
        local nonEquipableFilterType = targetCategoryData.filterType
        local filteredDataTable
        local comparator = self:GetItemDataFilterComparator(filteredEquipSlot, nonEquipableFilterType)

        filteredDataTable = SHARED_INVENTORY:GenerateFullSlotData(comparator, BAG_BACKPACK, BAG_COMPANION_WORN)
        for _, itemData in pairs(filteredDataTable) do
            itemData.bestItemCategoryName = zo_strformat(SI_INVENTORY_HEADER, GetBestItemCategoryDescription(itemData))
        end
        table.sort(filteredDataTable, ZO_GamepadInventory_DefaultItemSortComparator)

        local lastBestItemCategoryName
        for _, itemData in ipairs(filteredDataTable) do
            local entryData = ZO_GamepadEntryData:New(itemData.name, itemData.iconFile)
            entryData:InitializeInventoryVisualData(itemData)

            if itemData.bagId == BAG_COMPANION_WORN then
                entryData.isEquippedInCurrentCategory = itemData.slotIndex == filteredEquipSlot
                entryData.isEquippedInAnotherCategory = itemData.slotIndex ~= filteredEquipSlot

                entryData.isHiddenByWardrobe = WouldEquipmentBeHidden(itemData.slotIndex or EQUIP_SLOT_NONE, GAMEPLAY_ACTOR_CATEGORY_COMPANION)
            end

            local remaining, duration = GetItemCooldownInfo(itemData.bagId, itemData.slotIndex)
            ZO_InventorySlot_SetType(entryData, SLOT_TYPE_GAMEPAD_INVENTORY_ITEM)
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
end

function ZO_CompanionEquipment_Gamepad:GenerateItemSlotData(item)
    if not item then return nil end
    if not item.equipSlot then return nil end

    local slotData = SHARED_INVENTORY:GenerateSingleSlotData(BAG_COMPANION_WORN, item.equipSlot)

    if not slotData then
        return nil
    end

    ZO_InventorySlot_SetType(slotData, SLOT_TYPE_GAMEPAD_INVENTORY_ITEM)
    return slotData
end

------------
-- Header --
------------

function ZO_CompanionEquipment_Gamepad:RefreshHeader(blockCallback)
    local currentList = self:GetCurrentList()
    local headerData
    if currentList == self.categoryList then
        headerData = self.categoryHeaderData
    else
        headerData = self.itemListHeaderData
    end

    self.headerData = headerData
    ZO_GamepadGenericHeader_Refresh(self.header, headerData, blockCallback)
end

local function UpdateCapacityString()
    return zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK))
end

function ZO_CompanionEquipment_Gamepad:InitializeHeader()
    local function UpdateTitleText()
        return self.categoryList:GetTargetData().text
    end

    local SELECT_DEFAULT_ENTRY = true
    local tabBarEntries =
    {
        {
            text = GetString(SI_COMPANION_MENU_EQUIPMENT_TITLE),
            callback = function()
                self:SwitchActiveList(INVENTORY_CATEGORY_LIST, SELECT_DEFAULT_ENTRY)
            end,
        },
    }

    self.categoryHeaderData =
    {
        tabBarEntries = tabBarEntries,

        data1HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
        data1Text = UpdateCapacityString,
    }

    self.itemListHeaderData =
    {
        titleText = UpdateTitleText,

        data1HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
        data1Text = UpdateCapacityString,
    }

    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_CREATE)
end

function ZO_CompanionEquipment_Gamepad:TryEquipItem(inventorySlot)
    if self.selectedEquipSlot then
        local sourceBag, sourceSlot = ZO_Inventory_GetBagAndIndex(inventorySlot)
        local function DoEquip()
            RequestMoveItem(sourceBag, sourceSlot, BAG_COMPANION_WORN, self.selectedEquipSlot, 1)
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

function ZO_CompanionEquipment_Gamepad:ActivateHeader()
    ZO_GamepadGenericHeader_Activate(self.header)
end

function ZO_CompanionEquipment_Gamepad:DeactivateHeader()
    ZO_GamepadGenericHeader_Deactivate(self.header)
end

-------------------
-- New Status --
-------------------

local TIME_NEW_PERSISTS_WHILE_SELECTED_MS = 200

function ZO_CompanionEquipment_Gamepad:MarkSelectedItemAsNotNew()
    if self:IsClearNewItemActuallyNew() then
        self.clearNewStatusOnSelectionChanged = true
    end
end

function ZO_CompanionEquipment_Gamepad:TryClearNewStatus()
    if self.clearNewStatusOnSelectionChanged then
        self.clearNewStatusOnSelectionChanged = false
        SHARED_INVENTORY:ClearNewStatus(self.clearNewStatusBagId, self.clearNewStatusSlotIndex)
    end
end

function ZO_CompanionEquipment_Gamepad:TryClearNewStatusOnHidden()
    self:TryClearNewStatus()
    self.clearNewStatusCallId = nil
    self.clearNewStatusBagId = nil
    self.clearNewStatusSlotIndex = nil
    self.clearNewStatusUniqueId = nil
end

function ZO_CompanionEquipment_Gamepad:PrepareNextClearNewStatus(selectedData)
    self:TryClearNewStatus()
    if selectedData then
        self.clearNewStatusBagId = selectedData.bagId
        self.clearNewStatusSlotIndex = selectedData.slotIndex
        self.clearNewStatusUniqueId = selectedData.uniqueId
        self.clearNewStatusCallId = zo_callLater(self.trySetClearNewFlagCallback, TIME_NEW_PERSISTS_WHILE_SELECTED_MS)
    end
end

function ZO_CompanionEquipment_Gamepad:IsClearNewItemActuallyNew()
    return self.clearNewStatusBagId and
        SHARED_INVENTORY:IsItemNew(self.clearNewStatusBagId, self.clearNewStatusSlotIndex) and
        SHARED_INVENTORY:GetItemUniqueId(self.clearNewStatusBagId, self.clearNewStatusSlotIndex) == self.clearNewStatusUniqueId
end

function ZO_CompanionEquipment_Gamepad:TrySetClearNewFlag(callId)
    if self.clearNewStatusCallId == callId and self:IsClearNewItemActuallyNew() then
        self.clearNewStatusOnSelectionChanged = true
    end
end

function ZO_CompanionEquipment_Gamepad:UpdateRightTooltip()
    local targetCategoryData = self.categoryList:GetTargetData()
    if targetCategoryData and targetCategoryData.equipSlot then
        local selectedItemData = self.currentlySelectedData
        local equipSlotHasItem = GetWornItemInfo(BAG_COMPANION_WORN, targetCategoryData.equipSlot)
        if GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_RIGHT_TOOLTIP, BAG_COMPANION_WORN, targetCategoryData.equipSlot) then
            self:UpdateTooltipEquippedIndicatorText(GAMEPAD_RIGHT_TOOLTIP, targetCategoryData.equipSlot)
        end
    else
        GAMEPAD_TOOLTIPS:ClearStatusLabel(GAMEPAD_RIGHT_TOOLTIP)
    end
end

function ZO_CompanionEquipment_Gamepad:UpdateTooltipEquippedIndicatorText(tooltipType, equipSlot)
    ZO_InventoryUtils_UpdateTooltipEquippedIndicatorText(tooltipType, equipSlot, GAMEPLAY_ACTOR_CATEGORY_COMPANION)
end

function ZO_CompanionEquipment_Gamepad:Select()
    local SELECT_DEFAULT_ENTRY = true
    self:SwitchActiveList(INVENTORY_ITEM_LIST, SELECT_DEFAULT_ENTRY)
    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
end

function ZO_CompanionEquipment_Gamepad:ShowActions()
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

function ZO_CompanionEquipment_Gamepad:PreviewInventoryItem(bagId, slotIndex)
    if self.currentPreviewBagId ~= bagId or self.currentPreviewSlotIndex ~= slotIndex then
        self.currentPreviewBagId = bagId
        self.currentPreviewSlotIndex = slotIndex

        SYSTEMS:GetObject("itemPreview"):ClearPreviewCollection()
        SYSTEMS:GetObject("itemPreview"):PreviewInventoryItem(bagId, slotIndex)
    end
end

function ZO_CompanionEquipment_Gamepad:EndPreview()
    self.currentPreviewBagId = nil
    self.currentPreviewSlotIndex = nil

    SYSTEMS:GetObject("itemPreview"):ClearPreviewCollection()
    ApplyChangesToPreviewCollectionShown()
end

-----------------------------
-- Global XML Functions
-----------------------------

function ZO_CompanionEquipment_Gamepad_OnInitialize(control)
    COMPANION_EQUIPMENT_GAMEPAD = ZO_CompanionEquipment_Gamepad:New(control)
end