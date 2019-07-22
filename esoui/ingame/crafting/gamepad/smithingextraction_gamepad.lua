ZO_GamepadSmithingExtraction = ZO_SharedSmithingExtraction:Subclass()

function ZO_GamepadSmithingExtraction:New(...)
    return ZO_SharedSmithingExtraction.New(self, ...)
end

function ZO_GamepadSmithingExtraction:Initialize(panelControl, floatingControl, owner, refinementOnly, scene)
    self.panelControl = panelControl
    self.floatingControl = floatingControl
    local slotContainer = floatingControl:GetNamedChild("SlotContainer")
    ZO_SharedSmithingExtraction.Initialize(self, slotContainer:GetNamedChild("ExtractionSlot"), nil, owner, refinementOnly)

    self.tooltip = floatingControl:GetNamedChild("Tooltip")

    local ADDITIONAL_MOUSEOVER_BINDS = nil
    local DONT_USE_KEYBIND_STRIP = false
    self.itemActions = ZO_ItemSlotActionsController:New(KEYBIND_STRIP_ALIGN_LEFT, ADDITIONAL_MOUSEOVER_BINDS, DONT_USE_KEYBIND_STRIP)

    self:InitializeInventory(refinementOnly)
    self:InitExtractionSlot(scene.name)

    if refinementOnly then
        self:SetFilterType(SMITHING_FILTER_TYPE_RAW_MATERIALS)
    else
        self:SetFilterType(SMITHING_FILTER_TYPE_WEAPONS)
    end

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

    local function AddTabEntry(tabBarEntries, filterType)
        if ZO_CraftingUtils_CanSmithingFilterBeCraftedHere(filterType) then
            local entry = {}
            entry.text = GetString("SI_SMITHINGFILTERTYPE", filterType)
            entry.callback = function()
                if not ZO_CraftingUtils_IsPerformingCraftProcess() then
                    self:SetFilterType(filterType)
                end
            end
            entry.filterType = filterType

            table.insert(tabBarEntries, entry)
        end
    end

    scene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            self.inventory:Activate()

            local tabBarEntries = {}

            if not refinementOnly then
                AddTabEntry(tabBarEntries, SMITHING_FILTER_TYPE_WEAPONS)
                AddTabEntry(tabBarEntries, SMITHING_FILTER_TYPE_ARMOR)
                AddTabEntry(tabBarEntries, SMITHING_FILTER_TYPE_JEWELRY)

                local titleString = ZO_GamepadCraftingUtils_GetLineNameForCraftingType(GetCraftingInteractionType())

                ZO_GamepadCraftingUtils_SetupGenericHeader(self.owner, titleString, tabBarEntries)

                if #tabBarEntries > 1 then
                    ZO_GamepadGenericHeader_Activate(self.owner.header)
                end
            else
                local titleString = GetString(SI_SMITHING_TAB_REFINEMENT)

                ZO_GamepadCraftingUtils_SetupGenericHeader(self.owner, titleString)
            end

            ZO_GamepadCraftingUtils_RefreshGenericHeader(self.owner)

            -- tab bar / screen state fight with each other when switching between apparel only / other stations when sharing a tab bar...kick apparel station to the right filterType
            if #tabBarEntries == 1 then
                self:SetFilterType(tabBarEntries[1].filterType)
            end

            -- used to update extraction slot UI with text / etc., PC does this as well
            self:RemoveItemFromCraft()

            self.owner:SetEnableSkillBar(true)

            GAMEPAD_CRAFTING_RESULTS:SetForceCenterResultsText(true)
            GAMEPAD_CRAFTING_RESULTS:ModifyAnchor(ZO_Anchor:New(RIGHT, GuiRoot, RIGHT, -310, -175))

            self.inventory:HandleDirtyEvent()
        elseif newState == SCENE_HIDDEN then
            self.itemActions:SetInventorySlot(nil)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
            self.inventory:Deactivate()
            self.tooltip.tip:ClearLines()
            self.tooltip:SetHidden(true)
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)

            ZO_GamepadGenericHeader_Deactivate(self.owner.header)

            self.owner:SetEnableSkillBar(false)

            GAMEPAD_CRAFTING_RESULTS:SetForceCenterResultsText(false)
            GAMEPAD_CRAFTING_RESULTS:RestoreAnchor()
        end
    end)

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", function() 
        if SCENE_MANAGER:IsShowing("gamepad_smithing_refine") or SCENE_MANAGER:IsShowing("gamepad_smithing_deconstruct") then
            ZO_GamepadGenericHeader_Deactivate(self.owner.header)
        end
    end)

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", function()
        if SCENE_MANAGER:IsShowing("gamepad_smithing_refine") or SCENE_MANAGER:IsShowing("gamepad_smithing_deconstruct") then
            self:RefreshTooltip()
            ZO_GamepadGenericHeader_Activate(self.owner.header)
        end
    end)
end

function ZO_GamepadSmithingExtraction:SetFilterType(filterType)
    self.inventory.filterType = filterType
    self.inventory:HandleDirtyEvent()
end

function ZO_GamepadSmithingExtraction:SetCraftingType(craftingType, oldCraftingType, isCraftingTypeDifferent)
    self:ClearSelections()
    self.inventory:HandleDirtyEvent()
end

function ZO_GamepadSmithingExtraction:InitializeInventory(refinementOnly)
    local inventory = self.panelControl:GetNamedChild("Inventory")
    self.inventory = ZO_GamepadExtractionInventory:New(self, inventory, refinementOnly, SLOT_TYPE_CRAFTING_COMPONENT)

    self.inventory:SetCustomExtraData(function(bagId, slotIndex, data)
        if self:GetFilterType() == SMITHING_FILTER_TYPE_RAW_MATERIALS then
            -- turn refinement stacks red if they don't have a large enough quantity in them to be refineable
            data.meetsUsageRequirement = data.stackCount >= GetRequiredSmithingRefinementStackSize()
        end
        ZO_GamepadCraftingUtils_SetEntryDataSlotted(data, self.extractionSlot:ContainsBagAndSlot(data.bagId, data.slotIndex))
    end
    )
end

function ZO_GamepadSmithingExtraction:IsCurrentSelected()
    local bagId, slotIndex = self.inventory:CurrentSelectionBagAndSlot()
    return self.extractionSlot:ContainsBagAndSlot(bagId, slotIndex)
end

function ZO_GamepadSmithingExtraction:UpdateSelection()
    for _, data in pairs(self.inventory.list.dataList) do
        ZO_GamepadCraftingUtils_SetEntryDataSlotted(data, self.extractionSlot:ContainsBagAndSlot(data.bagId, data.slotIndex))
    end

    self:RefreshTooltip()

    self.inventory.list:RefreshVisible()

    self:UpdateEmptySlotIcon()
end

function ZO_GamepadSmithingExtraction:UpdateEmptySlotIcon()
    local filterType = self:GetFilterType()
    if filterType then
        self.extractionSlot:SetEmptyTexture(ZO_GamepadCraftingUtils_GetItemSlotTextureFromSmithingFilter(filterType))
    end
    local deconstructionType = self:GetDeconstructionType()
    if deconstructionType then
        self.extractionSlot:SetMultipleItemsTexture(ZO_GamepadCraftingUtils_GetMultipleItemsTextureFromSmithingDeconstructionType(deconstructionType))
    end
    
    -- reanchor slot icon based on special refine "you need 10 of this" text
    local slotBG = self.extractionSlot.control:GetNamedChild("Bg")
    local emptySlotIconControl = self.extractionSlot.control:GetNamedChild("EmptySlotIcon")

    emptySlotIconControl:ClearAnchors()
    if filterType == SMITHING_FILTER_TYPE_RAW_MATERIALS then
        emptySlotIconControl:SetAnchor(TOP, slotBG, TOP, 0, 10)
    else
        emptySlotIconControl:SetAnchor(CENTER, slotBG)
    end
end

function ZO_GamepadSmithingExtraction:RefreshTooltip()
    if self.extractionSlot:HasOneItem() then
        local bagId, slotIndex = self.extractionSlot:GetItemBagAndSlot(1)
        self.tooltip.tip:ClearLines()
        local SHOW_COMBINED_COUNT = true
        self.tooltip.tip:LayoutBagItem(bagId, slotIndex, SHOW_COMBINED_COUNT)
        self.tooltip.icon:SetTexture(GetItemInfo(bagId, slotIndex))
        self.tooltip:SetHidden(false)
    else
        self.tooltip:SetHidden(true)
    end
end

function ZO_GamepadSmithingExtraction:AddItemToCraft(bagId, slotIndex)
    local itemAdded = ZO_SharedSmithingExtraction.AddItemToCraft(self, bagId, slotIndex)
    -- rediscover inventory actions since they have changed
    self.itemActions:SetInventorySlot(self.inventory:CurrentSelection())
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    self:UpdateSelection()

    if itemAdded then
        self:RefreshTooltip()

        ZO_GamepadCraftingUtils_PlaySlotBounceAnimation(self.extractionSlot)
    end
    return itemAdded
end

function ZO_GamepadSmithingExtraction:RemoveItemFromCraft(bagId, slotIndex)
    local itemRemoved = ZO_SharedSmithingExtraction.RemoveItemFromCraft(self, bagId, slotIndex)
    -- rediscover inventory actions since they have changed
    self.itemActions:SetInventorySlot(self.inventory:CurrentSelection())
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    self:UpdateSelection()

    return itemRemoved
end

function ZO_GamepadSmithingExtraction:InitializeKeybindStripDescriptors()
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
            end,
            enabled = function()
                return self:IsCurrentSelected() or self:CanItemBeAddedToCraft(self.inventory:CurrentSelectionBagAndSlot())
            end,
        },

        -- Deconstruct single
        {
            name = function()
                if self:IsInRefineMode() then
                    return GetString(SI_CRAFTING_PERFORM_REFINE)
                else
                    return GetString(SI_CRAFTING_PERFORM_DECONSTRUCT)
                end
            end,
            keybind = "UI_SHORTCUT_SECONDARY",
            gamepadOrder = 1010,
            callback = function()
                self:ExtractSingle()
            end,
            enabled = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess() and self:IsExtractable() and self.extractionSlot:HasOneItem()
            end,
        },

        -- Deconstruct multiple
        {
            name = function()
                if self:IsInRefineMode() then
                    return GetString(SI_CRAFTING_REFINE_MULTIPLE)
                else
                    return GetString(SI_CRAFTING_DECONSTRUCT_MULTIPLE)
                end
             end,
            keybind = "UI_SHORTCUT_QUATERNARY",
            gamepadOrder = 1010,
            callback = function()
                if self.extractionSlot:HasOneItem() then
                    -- extract partial stack
                    local bagId, slotIndex = self.extractionSlot:GetItemBagAndSlot(1)
                    local refineSize = GetRequiredSmithingRefinementStackSize()
                    local maxIterations = zo_min(zo_floor(self.inventory:GetStackCount(bagId, slotIndex) / refineSize), MAX_ITERATIONS_PER_DECONSTRUCTION)
                    local function PerformDeconstructPartial(iterations)
                        self:ExtractPartialStack(iterations * refineSize)
                    end

                    ZO_GamepadCraftingUtils_ShowDeconstructPartialStackDialog(bagId, slotIndex, maxIterations, PerformDeconstructPartial)
                else
                    -- extract all
                    self:ConfirmExtractAll()
                end
            end,
            enabled = function()
                if ZO_CraftingUtils_IsPerformingCraftProcess() or not self:IsExtractable() then
                    return false
                end
                if self.extractionSlot:HasOneItem() then
                    -- there should be at least enough materials to refine twice
                    local bagId, slotIndex = self.extractionSlot:GetItemBagAndSlot(1)
                    return self:IsInRefineMode() and self.inventory:GetStackCount(bagId, slotIndex) >= GetRequiredSmithingRefinementStackSize() * 2
                end
                return true
            end,
        },

        -- Item Options
        {
            name = GetString(SI_GAMEPAD_INVENTORY_ACTION_LIST_KEYBIND),
            keybind = "UI_SHORTCUT_TERTIARY",
            gamepadOrder = 1020,
            callback = function()
                self:ShowItemActions()
            end,
            visible = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess() and self.inventory:CurrentSelection() ~= nil
            end
        },
    }

    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.inventory.list)
    ZO_GamepadCraftingUtils_AddGenericCraftingBackKeybindsToDescriptor(self.keybindStripDescriptor)
    ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(self.keybindStripDescriptor)
end

function ZO_GamepadSmithingExtraction:AddKeybinds()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GamepadSmithingExtraction:RemoveKeybinds()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GamepadSmithingExtraction:ShowItemActions()
    local dialogData = 
    {
        targetData = self.inventory:CurrentSelection(),
        itemActions = self.itemActions,
    }

    ZO_Dialogs_ShowPlatformDialog(ZO_GAMEPAD_INVENTORY_ACTION_DIALOG, dialogData)
end

ZO_GamepadExtractionInventory = ZO_GamepadCraftingInventory:Subclass()

function ZO_GamepadExtractionInventory:New(...)
    return ZO_GamepadCraftingInventory.New(self, ...)
end

local GAMEPAD_CRAFTING_RAW_MATERIAL_SORT =
{
    customSortData = { tiebreaker = "text" },
    text = {},
}

function ZO_GamepadExtractionInventory:Initialize(owner, control, refinementOnly, ...)
    local inventory = ZO_GamepadCraftingInventory.Initialize(self, control, ...)
    self.owner = owner

    if refinementOnly then
        self.filterType = SMITHING_FILTER_TYPE_RAW_MATERIALS
        self:SetOverrideItemSort(function(left, right)
            return ZO_TableOrderingFunction(left, right, "customSortData", GAMEPAD_CRAFTING_RAW_MATERIAL_SORT, ZO_SORT_ORDER_UP)
        end)
    else
        self.filterType = SMITHING_FILTER_TYPE_WEAPONS
        local DEFAULT_SORT = nil
        self:SetOverrideItemSort(DEFAULT_SORT)
    end

    self:SetCustomSort(function(bagId, slotIndex)
                            local traitInformation = GetItemTraitInformation(bagId, slotIndex)
                            return ZO_GetItemTraitInformation_SortOrder(traitInformation)
                       end)

    self:SetCustomBestItemCategoryNameFunction(function(slotData, data)
                                                    if slotData.traitInformation then
                                                        if slotData.traitInformation == ITEM_TRAIT_INFORMATION_ORNATE then
                                                            local traitType = GetItemTrait(slotData.bagId, slotData.slotIndex)
                                                            slotData.bestItemCategoryName = zo_strformat(GetString("SI_ITEMTRAITTYPE", traitType))
                                                        elseif slotData.traitInformation == ITEM_TRAIT_INFORMATION_CAN_BE_RESEARCHED or slotData.traitInformation == ITEM_TRAIT_INFORMATION_RETRAITED then
                                                            slotData.bestItemCategoryName = zo_strformat(GetString("SI_ITEMTRAITINFORMATION", slotData.traitInformation))
                                                        else
                                                            --If it is not ornate or trait related then use no header. We take advantage of the fact that empty string sorts to the top to order this.
                                                            slotData.bestItemCategoryName = ""
                                                        end
                                                    end
                                               end)
end

function ZO_GamepadExtractionInventory:Refresh(data)
    local validItems
    if self.filterType == SMITHING_FILTER_TYPE_RAW_MATERIALS then
        validItems = self:EnumerateInventorySlotsAndAddToScrollData(ZO_SharedSmithingExtraction_IsRefinableItem, ZO_SharedSmithingExtraction_DoesItemPassFilter, self.filterType, data)
    else
        validItems = self:GetIndividualInventorySlotsAndAddToScrollData(ZO_SharedSmithingExtraction_IsExtractableItem, ZO_SharedSmithingExtraction_DoesItemPassFilter, self.filterType, data)
    end
    self.owner:OnInventoryUpdate(validItems, self.filterType)

    -- if we don't have any items to show, make sure out NoItemLabel is updated
    if #data == 0 then
        self:SetNoItemLabelText(GetString("SI_SMITHINGFILTERTYPE_EXTRACTNONE", self.filterType))
    end
end

function ZO_GamepadExtractionInventory:GetCurrentFilterType()
    return self.filterType
end