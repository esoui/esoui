
ZO_FishFillet_Gamepad = ZO_FishFillet_Shared:Subclass()

function ZO_FishFillet_Gamepad:Initialize(panelControl, floatingControl, owner, scene)
    self.panelControl = panelControl
    self.floatingControl = floatingControl
    local slotContainer = floatingControl:GetNamedChild("SlotContainer")
    self.slotContainer = slotContainer
    local NO_LABEL = nil
    ZO_FishFillet_Shared.Initialize(self, slotContainer:GetNamedChild("FilletSlot"), NO_LABEL, owner)

    self.tooltip = floatingControl:GetNamedChild("Tooltip")
    local tooltipNarrationInfo =
    {
        canNarrate = function()
            return not self.tooltip:IsHidden()
        end,
        tooltipNarrationFunction = function()
            return self.tooltip.tip:GetNarrationText()
        end,
    }
    GAMEPAD_TOOLTIPS:RegisterCustomTooltipNarration(tooltipNarrationInfo)

    local ADDITIONAL_MOUSEOVER_BINDS = nil
    local DONT_USE_KEYBIND_STRIP = false
    self.itemActions = ZO_ItemSlotActionsController:New(KEYBIND_STRIP_ALIGN_LEFT, ADDITIONAL_MOUSEOVER_BINDS, DONT_USE_KEYBIND_STRIP)

    self:InitializeInventory(scene)
    self:InitFilletSlot(scene.name)

    self:SetFilterType(PROVISIONER_SPECIAL_INGREDIENT_TYPE_FILLET)

    self:InitializeKeybindStripDescriptors()

    self.inventory.list:SetOnSelectedDataChangedCallback(function(list, selectedData)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        self.itemActions:SetInventorySlot(selectedData)
        if selectedData and selectedData.bagId and selectedData.slotIndex then
            local SHOW_COMBINED_COUNT = true
            GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, selectedData.bagId, selectedData.slotIndex, SHOW_COMBINED_COUNT)
        else
            GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
        end
    end)

    scene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            self.inventory:Activate()

            TriggerTutorial(TUTORIAL_TRIGGER_FILLETING_OPENED)

            -- used to update fillet slot UI with text / etc., PC does this as well
            self:RemoveItemFromCraft()

            ZO_GamepadCraftingUtils_SetupGenericHeader(GAMEPAD_PROVISIONER, GetString(SI_GAMEPAD_PROVISIONING_TAB_FILLET))
            ZO_GamepadCraftingUtils_RefreshGenericHeader(GAMEPAD_PROVISIONER)

            self.inventory:HandleDirtyEvent()
        elseif newState == SCENE_SHOWN then
            GAMEPAD_CRAFTING_RESULTS:SetForceCenterResultsText(true)
            GAMEPAD_CRAFTING_RESULTS:ModifyAnchor(ZO_Anchor:New(RIGHT, GuiRoot, RIGHT, -310, -175))
        elseif newState == SCENE_HIDING then
            GAMEPAD_CRAFTING_RESULTS:SetForceCenterResultsText(false)
            GAMEPAD_CRAFTING_RESULTS:RestoreAnchor()
        elseif newState == SCENE_HIDDEN then
            self.itemActions:SetInventorySlot(nil)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
            self.inventory:Deactivate()
            self.tooltip.tip:ClearLines()
            self.tooltip:SetHidden(true)
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
            ZO_GamepadGenericHeader_Deactivate(self.owner.header)
        end
    end)

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", function()
        if SCENE_MANAGER:IsShowing("gamepad_provisioner_fillet") then
            ZO_GamepadGenericHeader_Deactivate(self.owner.header)
        end
    end)

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", function()
        if SCENE_MANAGER:IsShowing("gamepad_provisioner_fillet") then
            self:RefreshTooltip()
            ZO_GamepadGenericHeader_Activate(self.owner.header)
        end
    end)
end

function ZO_FishFillet_Gamepad:Activate()
    self.inventory:Activate()
    self.filletSlot.control:SetHidden(false)
end

function ZO_FishFillet_Gamepad:Deactivate()
    self.inventory:Deactivate()
    self.filletSlot.control:SetHidden(true)
end

function ZO_FishFillet_Gamepad:SetFilterType(filterType)
    self.inventory.filterType = filterType
    self.inventory:HandleDirtyEvent()
end

-- TODO Fillet: Evaluate the usage of this function across crafting screens and the need for it's parameters.
function ZO_FishFillet_Gamepad:SetCraftingType(craftingType, oldCraftingType, isCraftingTypeDifferent)
    self:ClearSelections()
    self.inventory:HandleDirtyEvent()
end

function ZO_FishFillet_Gamepad:InitFilletSlot(sceneName)
    ZO_FishFillet_Shared.InitFilletSlot(self, sceneName)
    local tooltipNarrationInfo =
    {
        canNarrate = function()
            --If this fixed tooltip is showing, no need to narrate this, as it will be redundant information
            return SCENE_MANAGER:IsShowing(sceneName) and self.tooltip:IsHidden()
        end,
        tooltipNarrationFunction = function()
            return self.filletSlot:GetNarrationText()
        end,
    }
    GAMEPAD_TOOLTIPS:RegisterCustomTooltipNarration(tooltipNarrationInfo)

    self.filletSlot.control:SetHidden(true)
end

function ZO_FishFillet_Gamepad:InitializeInventory(scene)
    local inventory = self.panelControl:GetNamedChild("Inventory")
    self.inventory = ZO_FilletInventory_Gamepad:New(self, inventory, SLOT_TYPE_CRAFTING_COMPONENT)

    self.inventory:SetCustomExtraData(function(bagId, slotIndex, data)
        ZO_GamepadCraftingUtils_SetEntryDataSlotted(data, self.filletSlot:ContainsBagAndSlot(data.bagId, data.slotIndex))
    end)

    local narrationInfo =
    {
        canNarrate = function()
            return scene:IsShowing()
        end,
        headerNarrationFunction = function()
            return ZO_GamepadGenericHeader_GetNarrationText(self.owner.header, self.owner.headerData)
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterParametricList(self.inventory.list, narrationInfo)
end

function ZO_FishFillet_Gamepad:IsCurrentSelected()
    local bagId, slotIndex = self.inventory:CurrentSelectionBagAndSlot()
    return self.filletSlot:ContainsBagAndSlot(bagId, slotIndex)
end

function ZO_FishFillet_Gamepad:UpdateSelection()
    for _, data in pairs(self.inventory.list.dataList) do
        ZO_GamepadCraftingUtils_SetEntryDataSlotted(data, self.filletSlot:ContainsBagAndSlot(data.bagId, data.slotIndex))
    end

    self:RefreshTooltip()

    self.inventory.list:RefreshVisible()

    self:UpdateEmptySlotIcon()
end

function ZO_FishFillet_Gamepad:UpdateEmptySlotIcon()
    self.filletSlot:SetEmptyTexture("EsoUI/Art/Crafting/Gamepad/gp_fillet_emptySlot.dds")
    self.filletSlot:SetMultipleItemsTexture("EsoUI/Art/Crafting/Gamepad/gp_fillet_multiple_emptySlot.dds")

    -- reanchor slot icon based on special refine "you need 10 of this" text
    local slotBG = self.filletSlot.control:GetNamedChild("Bg")
    local emptySlotIconControl = self.filletSlot.control:GetNamedChild("EmptySlotIcon")

    emptySlotIconControl:ClearAnchors()
    emptySlotIconControl:SetAnchor(CENTER, slotBG)
end

function ZO_FishFillet_Gamepad:RefreshTooltip()
    if self.filletSlot:HasOneItem() then
        local bagId, slotIndex = self.filletSlot:GetItemBagAndSlot(1)
        self.tooltip.tip:ClearLines()
        local SHOW_COMBINED_COUNT = true
        self.tooltip.tip:LayoutBagItem(bagId, slotIndex, SHOW_COMBINED_COUNT)
        self.tooltip.icon:SetTexture(GetItemInfo(bagId, slotIndex))
        self.tooltip:SetHidden(false)
    else
        self.tooltip:SetHidden(true)
    end
end

function ZO_FishFillet_Gamepad:AddItemToCraft(bagId, slotIndex)
    local itemAdded = ZO_FishFillet_Shared.AddItemToCraft(self, bagId, slotIndex)
    -- rediscover inventory actions since they have changed
    self.itemActions:SetInventorySlot(self.inventory:CurrentSelection())
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    self:UpdateSelection()

    if itemAdded then
        self:RefreshTooltip()

        ZO_GamepadCraftingUtils_PlaySlotBounceAnimation(self.filletSlot)
    end
    return itemAdded
end

function ZO_FishFillet_Gamepad:RemoveItemFromCraft(bagId, slotIndex)
    local itemRemoved = ZO_FishFillet_Shared.RemoveItemFromCraft(self, bagId, slotIndex)
    -- rediscover inventory actions since they have changed
    self.itemActions:SetInventorySlot(self.inventory:CurrentSelection())
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    self:UpdateSelection()

    return itemRemoved
end

function ZO_FishFillet_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select / remove
        {
            name = function()
                if self:IsCurrentSelected() then
                    return GetString(SI_ITEM_ACTION_REMOVE_FROM_CRAFT)
                else
                    return GetString(SI_ITEM_ACTION_ADD_TO_CRAFT)
                end
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function()
                if ZO_CraftingUtils_IsPerformingCraftProcess() then
                    return false
                end
                local bagId, slotIndex = self.inventory:CurrentSelectionBagAndSlot()
                return bagId ~= nil and slotIndex ~= nil
            end,
            callback = function()
                if self:IsCurrentSelected() then
                    self:RemoveItemFromCraft(self.inventory:CurrentSelectionBagAndSlot())
                else
                    self:AddItemToCraft(self.inventory:CurrentSelectionBagAndSlot())
                end
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
                SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.inventory.list)
            end,
            enabled = function()
                return self:IsCurrentSelected() or self:CanItemBeAddedToCraft(self.inventory:CurrentSelectionBagAndSlot())
            end,
        },

        -- Deconstruct single
        {
            name = GetString("SI_DECONSTRUCTACTIONNAME", DECONSTRUCT_ACTION_NAME_FILLET),
            keybind = "UI_SHORTCUT_SECONDARY",
            gamepadOrder = 1010,
            callback = function()
                self:ConfirmFilletAll()
            end,
            enabled = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess() and self:IsFilletable() and self.filletSlot:HasOneItem()
            end,
        },

        -- Deconstruct multiple
        {
            name = GetString("SI_DECONSTRUCTACTIONNAME_PERFORMMULTIPLE", DECONSTRUCT_ACTION_NAME_FILLET),
            keybind = "UI_SHORTCUT_QUATERNARY",
            gamepadOrder = 1010,
            callback = function()
                if self.filletSlot:HasOneItem() then
                    -- extract partial stack
                    local bagId, slotIndex = self.filletSlot:GetItemBagAndSlot(1)
                    local maxIterations = zo_min(self.inventory:GetStackCount(bagId, slotIndex), MAX_ITERATIONS_PER_DECONSTRUCTION)
                    local function PerformDeconstructPartial(iterations)
                        self:FilletPartialStack(iterations)
                    end

                    ZO_GamepadCraftingUtils_ShowDeconstructPartialStackDialog(bagId, slotIndex, maxIterations, PerformDeconstructPartial, DECONSTRUCT_ACTION_NAME_REFINE)
                else
                    -- extract all
                    self:ConfirmFilletAll()
                end
            end,
            enabled = function()
                if ZO_CraftingUtils_IsPerformingCraftProcess() or not self:IsFilletable() then
                    return false
                end
                if self.filletSlot:HasOneItem() then
                    -- there should be at least enough fish to fillet twice
                    local bagId, slotIndex = self.filletSlot:GetItemBagAndSlot(1)
                    return self.inventory:GetStackCount(bagId, slotIndex) >= 1
                end
                return true
            end,
        },

        -- Item Options
        {
            name = GetString(SI_GAMEPAD_CRAFTING_OPTIONS),
            keybind = "UI_SHORTCUT_TERTIARY",
            gamepadOrder = 1020,
            callback = function()
                self:ShowOptionsMenu()
            end,
            visible = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess() and (self.inventory:CurrentSelection() ~= nil)
            end,
        },
    }

    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.inventory.list)
    ZO_GamepadCraftingUtils_AddGenericCraftingBackKeybindsToDescriptor(self.keybindStripDescriptor)
    ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(self.keybindStripDescriptor)
end

function ZO_FishFillet_Gamepad:AddKeybinds()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_FishFillet_Gamepad:RemoveKeybinds()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_FishFillet_Gamepad:ShowOptionsMenu()
    local dialogData =
    {
        targetData = self.inventory:CurrentSelection(),
        itemActions = self.itemActions,
        finishedCallback =  function()
            local targetData = self.inventory.list:GetTargetData()
            if targetData then
                GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, targetData.bagId, targetData.slotIndex, SHOW_COMBINED_COUNT)
            else
                GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
            end
        end
    }
    if not self.craftingOptionsDialogGamepad then
        self.craftingOptionsDialogGamepad = ZO_CraftingOptionsDialogGamepad:New()
    end
    self.craftingOptionsDialogGamepad:ShowOptionsDialog(dialogData)
end

--------------------------
-- Fillet Inventory --
--------------------------
ZO_FilletInventory_Gamepad = ZO_GamepadCraftingInventory:Subclass()

function ZO_FilletInventory_Gamepad:New(...)
    return ZO_GamepadCraftingInventory.New(self, ...)
end

local GAMEPAD_CRAFTING_FILLET_SORT =
{
    customSortData = { tiebreaker = "text" },
    text = {},
}

function ZO_FilletInventory_Gamepad:Initialize(owner, control, ...)
    local inventory = ZO_GamepadCraftingInventory.Initialize(self, control, ...)
    self.owner = owner

    self.filterType = PROVISIONER_SPECIAL_INGREDIENT_TYPE_FILLET
    self:SetOverrideItemSort(function(left, right)
        return ZO_TableOrderingFunction(left, right, "customSortData", GAMEPAD_CRAFTING_FILLET_SORT, ZO_SORT_ORDER_UP)
    end)
end

function ZO_FilletInventory_Gamepad:Refresh(data)
    local validItems
    local NO_FILTER_FUNCTION = nil
    validItems = self:EnumerateInventorySlotsAndAddToScrollData(ZO_FishFillet_Shared_IsFilletableItem, NO_FILTER_FUNCTION, self.filterType, data)

    self.owner:OnInventoryUpdate(validItems, self.filterType)

    -- if we don't have any items to show, make sure our NoItemLabel is updated
    if #data == 0 then
        self:SetNoItemLabelText(GetString("SI_PROVISIONERSPECIALINGREDIENTTYPE_EXTRACTNONE", self.filterType))
    end
end

function ZO_FilletInventory_Gamepad:GetCurrentFilterType()
    return self.filterType
end