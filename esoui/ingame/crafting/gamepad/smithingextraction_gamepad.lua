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

    if refinementOnly then
        self.mode = ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_RAW_MATERIALS
    else
        self.mode = ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_WEAPONS
    end

    self:InitializeInventory(refinementOnly)
    self:InitExtractionSlot(scene.name)

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

            local tabBarEntries = {}

            if not refinementOnly then
                self:AddEntry(GetString("SI_EQUIPSLOTVISUALCATEGORY", EQUIP_SLOT_VISUAL_CATEGORY_WEAPONS), ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_WEAPONS, CanSmithingWeaponPatternsBeCraftedHere(), tabBarEntries)
                self:AddEntry(GetString("SI_EQUIPSLOTVISUALCATEGORY", EQUIP_SLOT_VISUAL_CATEGORY_APPAREL), ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_ARMOR, CanSmithingApparelPatternsBeCraftedHere(), tabBarEntries)

                local titleString = ZO_GamepadCraftingUtils_GetLineNameForCraftingType(GetCraftingInteractionType())

                ZO_GamepadCraftingUtils_SetupGenericHeader(self.owner, titleString, tabBarEntries)

                if #tabBarEntries > 1 then
                    ZO_GamepadGenericHeader_Activate(self.owner.header)
                end
            else
                local titleString = GetString(SI_SMITHING_TAB_REFINMENT)

                ZO_GamepadCraftingUtils_SetupGenericHeader(self.owner, titleString)
            end

            ZO_GamepadCraftingUtils_RefreshGenericHeader(self.owner)

            -- tab bar / screen state fight with each other when switching between apparel only / other stations when sharing a tab bar...kick apparel station to the right mode
            if #tabBarEntries == 1 then
                self:ChangeMode(tabBarEntries[1].mode)
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

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", function()
        if SCENE_MANAGER:IsShowing("gamepad_smithing_refine") or SCENE_MANAGER:IsShowing("gamepad_smithing_deconstruct") then
            if not self.extractionSlot:HasItem() then
                self.tooltip:SetHidden(true)
            end
            self:UpdateSelection()
        end
    end)
end

function ZO_GamepadSmithingExtraction:ChangeMode(mode)
    self.mode = mode
    self.inventory.filterType = mode

    self.inventory:HandleDirtyEvent()
    -- used to update extraction slot UI with text / etc., PC does this as well
    -- note that on gamepad this gives a possibly unwanted side effect of losing the active item when switching filters
    self:RemoveItemFromCraft()
end

function ZO_GamepadSmithingExtraction:AddEntry(name, mode, allowed, tabBarEntries)
    if allowed then
        local entry = {}
        entry.text = name
        entry.callback = function()
            if not ZO_CraftingUtils_IsPerformingCraftProcess() then
                self:ChangeMode(mode)
            end
        end
        entry.mode = mode

        table.insert(tabBarEntries, entry)
    end
end

function ZO_GamepadSmithingExtraction:SetCraftingType(craftingType, oldCraftingType, isCraftingTypeDifferent)
    self.extractionSlot:SetItem(nil)
    self.canExtract = false

    self.inventory:HandleDirtyEvent()
end

function ZO_GamepadSmithingExtraction:InitializeInventory(refinementOnly)
    local inventory = self.panelControl:GetNamedChild("Inventory")
    self.inventory = ZO_GamepadExtractionInventory:New(self, inventory, refinementOnly, SLOT_TYPE_CRAFTING_COMPONENT)

    -- turn refinement stacks red if they don't have a large enough quantity in them to be refineable
    self.inventory:SetCustomExtraData(function(bagId, slotIndex, data)
        if self.mode == ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_RAW_MATERIALS then
            data.meetsUsageRequirement = data.stackCount >= GetRequiredSmithingRefinementStackSize()
        end
    end
    )
end

function ZO_GamepadSmithingExtraction:IsCurrentSelected()
    if self.extractionSlot:HasItem() then
        local bagId, slotIndex = self.extractionSlot:GetBagAndSlot()
        local selectedBagId, selectedSlotIndex = self.inventory:CurrentSelectionBagAndSlot()
        return bagId == selectedBagId and slotIndex == selectedSlotIndex
    end
end

function ZO_GamepadSmithingExtraction:UpdateSelection()
    local bagId, slotIndex = self.extractionSlot:GetBagAndSlot()
    for _, data in pairs(self.inventory.list.dataList) do
        if data.bagId == bagId and data.slotIndex == slotIndex then
            data.isEquippedInCurrentCategory = true

            self.tooltip.tip:ClearLines()
            self.tooltip.tip:LayoutBagItem(bagId, slotIndex)
            self.tooltip.icon:SetTexture(GetItemInfo(bagId, slotIndex))
        else
            data.isEquippedInCurrentCategory = false
        end
    end

    self.inventory.list:RefreshVisible()

    self:UpdateEmptySlotIcon()
end

do
    local MODE_TO_ICON_MAP = {
        [ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_ARMOR] = "EsoUI/Art/Crafting/Gamepad/gp_smithing_apparelSlot.dds",
        [ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_WEAPONS] = "EsoUI/Art/Crafting/Gamepad/gp_smithing_weaponSlot.dds",
        [ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_RAW_MATERIALS] = "EsoUI/Art/Crafting/Gamepad/gp_smithing_refine_emptySlot.dds",
    }

    function ZO_GamepadSmithingExtraction:UpdateEmptySlotIcon()
        if not self.extractionSlot:HasItem() then
            local slotBG = self.extractionSlot.control:GetNamedChild("Bg")
            local emptySlotIconControl = self.extractionSlot.control:GetNamedChild("EmptySlotIcon")
            local iconPath = MODE_TO_ICON_MAP[self.mode]
            
            -- emptySlotIcon stores an icon path, not the control itself
            self.extractionSlot.emptySlotIcon = iconPath
            emptySlotIconControl:SetTexture(iconPath)
            self.extractionSlot:ShowEmptySlotIcon(true)

            -- reanchor slot icon based on special refine "you need 10 of this" text
            emptySlotIconControl:ClearAnchors()

            local newAnchor = nil
            if self.mode == ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_RAW_MATERIALS then
                newAnchor = ZO_Anchor:New(TOP, slotBG, TOP, 0, 10)
            else
                newAnchor = ZO_Anchor:New(CENTER, slotBG)
            end

            newAnchor:AddToControl(emptySlotIconControl)
        end
    end
end

function ZO_GamepadSmithingExtraction:AddItemToCraft(bagId, slotIndex)
    ZO_SharedSmithingExtraction.AddItemToCraft(self, bagId, slotIndex)
    -- rediscover inventory actions since they have changed
    self.itemActions:SetInventorySlot(self.inventory:CurrentSelection())
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    self:UpdateSelection()

    if bagId and slotIndex then
        self.tooltip.tip:ClearLines()
        local SHOW_COMBINED_COUNT = true
        self.tooltip.tip:LayoutBagItem(bagId, slotIndex, SHOW_COMBINED_COUNT)
        self.tooltip.icon:SetTexture(GetItemInfo(bagId, slotIndex))
        self.tooltip:SetHidden(false)

        ZO_GamepadCraftingUtils_PlaySlotBounceAnimation(self.extractionSlot)
    end
end

function ZO_GamepadSmithingExtraction:RemoveItemFromCraft()
    ZO_SharedSmithingExtraction.RemoveItemFromCraft(self)
    -- rediscover inventory actions since they have changed
    self.itemActions:SetInventorySlot(self.inventory:CurrentSelection())
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    self:UpdateSelection()

    self.tooltip:SetHidden(true)
end

function ZO_GamepadSmithingExtraction:ConfirmRefineOrDestroy()
    self.itemActions:SetInventorySlot(nil)
    self:Extract()
end

function ZO_GamepadSmithingExtraction:HasEnoughToRefine()
    if self.mode == ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_RAW_MATERIALS then
        local bagId, slotIndex = self.extractionSlot:GetBagAndSlot()
        return ZO_SharedSmithingExtraction_DoesItemMeetRefinementStackRequirement(bagId, slotIndex, self.extractionSlot:GetStackCount())
    else
        return true
    end
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
            visible =   function()
                            if ZO_CraftingUtils_IsPerformingCraftProcess() then
                                return false
                            end
                            local bagId, slotIndex = self.inventory:CurrentSelectionBagAndSlot()
                            return bagId ~= nil and slotIndex ~= nil
                        end,
            callback = function()
                if self:IsCurrentSelected() then
                    self:RemoveItemFromCraft()
                else
                    self:AddItemToCraft(self.inventory:CurrentSelectionBagAndSlot())
                end
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
            end,
        },

        -- Perform craft
        {
            name = function()
                if self.mode == ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_ARMOR then
                    return GetString(SI_SMITHING_TAB_DECONSTRUCTION)
                elseif self.mode == ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_WEAPONS then
                    return GetString(SI_SMITHING_TAB_DECONSTRUCTION)
                elseif self.mode == ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_RAW_MATERIALS then
                    return GetString(SI_SMITHING_TAB_REFINMENT)
                end
            end,
            keybind = "UI_SHORTCUT_SECONDARY",
        
            callback = function() self:ConfirmRefineOrDestroy() end,

            enabled = function() return not ZO_CraftingUtils_IsPerformingCraftProcess() and self:HasEnoughToRefine() and self:HasSelections() end,
        },

        -- Item Options
        {
            name = GetString(SI_GAMEPAD_INVENTORY_ACTION_LIST_KEYBIND),
            keybind = "UI_SHORTCUT_TERTIARY",
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
    self:RemoveKeybinds()

    local function OnActionsFinishedCallback()
        self:AddKeybinds()
    end

    local dialogData = 
    {
        targetData = self.inventory:CurrentSelection(),
        finishedCallback = OnActionsFinishedCallback,
        itemActions = self.itemActions,
    }

    ZO_Dialogs_ShowPlatformDialog(ZO_GAMEPAD_INVENTORY_ACTION_DIALOG, dialogData)
end

ZO_GamepadExtractionInventory = ZO_GamepadCraftingInventory:Subclass()

function ZO_GamepadExtractionInventory:New(...)
    return ZO_GamepadCraftingInventory.New(self, ...)
end

function ZO_GamepadExtractionInventory:Initialize(owner, control, refinementOnly, ...)
    local inventory = ZO_GamepadCraftingInventory.Initialize(self, control, ...)
    self.owner = owner

    if refinementOnly then
        self.filterType = ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_RAW_MATERIALS
    else
        self.filterType = ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_WEAPONS
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
    if self.filterType == ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_RAW_MATERIALS then
        validItems = self:EnumerateInventorySlotsAndAddToScrollData(ZO_SharedSmithingExtraction_IsRefinableItem, ZO_SharedSmithingExtraction_DoesItemPassFilter, self.filterType, data)
    else
        validItems = self:GetIndividualInventorySlotsAndAddToScrollData(ZO_SharedSmithingExtraction_IsExtractableItem, ZO_SharedSmithingExtraction_DoesItemPassFilter, self.filterType, data)
    end
    self.owner:OnInventoryUpdate(validItems, self.filterType)

    -- if we don't have any items to show, make sure out NoItemLabel is updated
    if #data == 0 then
        if self.filterType == ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_ARMOR then
            self:SetNoItemLabelText(GetString(SI_SMITHING_EXTRACTION_NO_ARMOR))
        elseif self.filterType == ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_WEAPONS then
            self:SetNoItemLabelText(GetString(SI_SMITHING_EXTRACTION_NO_WEAPONS))
        elseif self.filterType == ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_RAW_MATERIALS then
            self:SetNoItemLabelText(GetString(SI_SMITHING_EXTRACTION_NO_MATERIALS))
        end
    end
end

function ZO_GamepadExtractionInventory:GetCurrentFilterType()
    return self.filterType
end