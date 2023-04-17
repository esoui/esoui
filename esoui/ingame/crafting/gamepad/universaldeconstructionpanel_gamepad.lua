local FILTER_INCLUDE_BANKED = 1
local FILTER_CRAFTING_TYPES = 2

ZO_UniversalDeconstructionPanel_Gamepad = ZO_UniversalDeconstructionPanel_Shared:Subclass()

function ZO_UniversalDeconstructionPanel_Gamepad:Initialize(panelControl, floatingControl, universalDeconstructionParent, isRefinementOnly, scene)
    self.isRefinementOnly = isRefinementOnly
    self.panelControl = panelControl
    self.floatingControl = floatingControl
    self.tooltip = floatingControl:GetNamedChild("Tooltip")
    --Register the tooltip for narration
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
    local slotContainer = floatingControl:GetNamedChild("SlotContainer")
    self.slotContainer = slotContainer
    ZO_UniversalDeconstructionPanel_Shared.Initialize(self, panelControl, universalDeconstructionParent, slotContainer:GetNamedChild("ExtractionSlot"), nil)

    self.tabBarEntries = {}
    for _, filterData in ZO_NumericallyIndexedTableReverseIterator(ZO_UNIVERSAL_DECONSTRUCTION_FILTER_TYPES) do
        local entry =
        {
            filterType = filterData.filter,
            text = filterData.displayName,
            disabled = filterData.enabled == false,
            callback = function()
                if not ZO_CraftingUtils_IsPerformingCraftProcess() then
                    self:SetFilterType(filterData.filter, filterData)
                    --Re-narrate on tab change
                    local NARRATE_HEADER = true
                    SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.inventory.list, NARRATE_HEADER)
                end
            end,
        }
        table.insert(self.tabBarEntries, entry)
    end

    local ADDITIONAL_MOUSEOVER_BINDS = nil
    local DONT_USE_KEYBIND_STRIP = false
    self.itemActions = ZO_ItemSlotActionsController:New(KEYBIND_STRIP_ALIGN_LEFT, ADDITIONAL_MOUSEOVER_BINDS, DONT_USE_KEYBIND_STRIP)

    self:InitializeFilters()
    self:InitializeInventory(isRefinementOnly)
    self:InitExtractionSlot(scene.name)

    local function OnAddOnLoaded(event, name)
        if name == "ZO_Ingame" then
            self:SetupSavedVars()
            panelControl:UnregisterForEvent(EVENT_ADD_ON_LOADED)
        end
    end
    panelControl:RegisterForEvent(EVENT_ADD_ON_LOADED, OnAddOnLoaded)

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

    self.slotContainer:ClearAnchors()
    self.slotContainer:SetAnchor(BOTTOM, GuiRoot, BOTTOMLEFT, ZO_GAMEPAD_PANEL_FLOATING_CENTER_QUADRANT_1_2_SHOWN, ZO_GAMEPAD_CRAFTING_UTILS_FLOATING_BOTTOM_OFFSET)

    scene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWN then
            TriggerTutorial(TUTORIAL_TRIGGER_UNIVERSAL_DECONSTRUCTION_OPENED)
            self:RefreshFilter()
        elseif newState == SCENE_SHOWING then
            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

            self:RefreshAccessibleCraftingTypeFilters()
            self.inventory:Activate()

            ZO_GamepadCraftingUtils_SetupGenericHeader(self.universalDeconstructionParent, nil, self.tabBarEntries)
            ZO_GamepadCraftingUtils_RefreshGenericHeader(self.universalDeconstructionParent)
            ZO_GamepadGenericHeader_Activate(self.universalDeconstructionParent.header)

            self:RemoveItemFromCraft()
            self.universalDeconstructionParent:SetEnableSkillBar(true)

            self:ClearSelections()
            self.inventory:HandleDirtyEvent()
            self.inventory:PerformFullRefresh()

            GAMEPAD_CRAFTING_RESULTS:SetForceCenterResultsText(true)
            GAMEPAD_CRAFTING_RESULTS:ModifyAnchor(ZO_Anchor:New(RIGHT, GuiRoot, RIGHT, -310, -175))
        elseif newState == SCENE_HIDDEN then
            self.itemActions:SetInventorySlot(nil)
            ZO_InventorySlot_RemoveMouseOverKeybinds()

            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()

            self.inventory:Deactivate()
            self.tooltip.tip:ClearLines()
            self.tooltip:SetHidden(true)

            self:ClearSelections()
            self.inventory:HandleDirtyEvent()

            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
            ZO_GamepadGenericHeader_Deactivate(self.universalDeconstructionParent.header)
            self.universalDeconstructionParent:SetEnableSkillBar(false)

            GAMEPAD_CRAFTING_RESULTS:SetForceCenterResultsText(false)
            GAMEPAD_CRAFTING_RESULTS:RestoreAnchor()
        end
    end)

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", function() 
        if SCENE_MANAGER:IsShowing("universalDeconstructionSceneGamepad") then
            ZO_GamepadGenericHeader_Deactivate(self.universalDeconstructionParent.header)
        end
    end)

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", function()
        if SCENE_MANAGER:IsShowing("universalDeconstructionSceneGamepad") then
            self:RefreshTooltip()
            ZO_GamepadGenericHeader_Activate(self.universalDeconstructionParent.header)
        end
    end)
end

function ZO_UniversalDeconstructionPanel_Gamepad:InitializeInventory()
    local inventoryControl = self.panelControl:GetNamedChild("Inventory")
    self.inventory = ZO_UniversalDeconstructionInventory_Gamepad:New(self, inventoryControl, SLOT_TYPE_GAMEPAD_INVENTORY_ITEM)
    self.inventory:SetCustomExtraData(function(bagId, slotIndex, data)
        ZO_GamepadCraftingUtils_SetEntryDataSlotted(data, self.extractionSlot:ContainsBagAndSlot(data.bagId, data.slotIndex))
        ZO_GamepadCraftingUtils_AddOverridesEntryData(data)
    end)

    --Register the list for narration
    local narrationInfo =
    {
        canNarrate = function()
            return SCENE_MANAGER:IsShowing("universalDeconstructionSceneGamepad")
        end,
        headerNarrationFunction = function()
            return ZO_GamepadGenericHeader_GetNarrationText(self.universalDeconstructionParent.header, self.universalDeconstructionParent.headerData)
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterParametricList(self.inventory.list, narrationInfo)
end

function ZO_UniversalDeconstructionPanel_Gamepad:InitExtractionSlot(sceneName)
    ZO_UniversalDeconstructionPanel_Shared.InitExtractionSlot(self, sceneName)
    --Register the extraction slot for narration
    local tooltipNarrationInfo = 
    {
        canNarrate = function()
            --If the fixed tooltip is showing, no need to narrate this, as it will be redundant information
            return SCENE_MANAGER:IsShowing(sceneName) and self.tooltip:IsHidden()
        end,
        tooltipNarrationFunction = function()
            return self.extractionSlot:GetNarrationText()
        end,
    }
    GAMEPAD_TOOLTIPS:RegisterCustomTooltipNarration(tooltipNarrationInfo)
end

function ZO_UniversalDeconstructionPanel_Gamepad:InitializeFilters()
    self.craftingTypeFilterEntries = ZO_MultiSelection_ComboBox_Data_Gamepad:New()
    for _, craftingType in ipairs(ZO_UNIVERSAL_DECONSTRUCTION_CRAFTING_TYPES) do
        local entry = ZO_ComboBox_Base:CreateItemEntry(GetString("SI_TRADESKILLTYPE", craftingType))
        entry.craftingType = craftingType

        if craftingType == CRAFTING_TYPE_JEWELRYCRAFTING then
            entry.onEnter = function(control, data)
                local tooltipText = ZO_GetJewelryCraftingLockedMessage()
                if tooltipText then
                    GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_TOOLTIP, tooltipText)
                end
            end

            entry.onExit = function(control, data)
                local label = GetString(SI_SMITHING_DECONSTRUCTION_CRAFTING_TYPES_LABEL)
                local description = GetString(SI_SMITHING_DECONSTRUCTION_CRAFTING_TYPES_DESCRIPTION)
                GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, label, description)
            end
        end

        self.craftingTypeFilterEntries:AddItem(entry)
    end
    self:RefreshAccessibleCraftingTypeFilters()

    self.filters =
    {
        [FILTER_INCLUDE_BANKED] =
        {
            header = GetString(SI_GAMEPAD_SMITHING_FILTERS),
            filterName = GetString(SI_CRAFTING_INCLUDE_BANKED),
            filterTooltip = GetString(SI_CRAFTING_INCLUDE_BANKED_TOOLTIP),
            checked = false,
        },
        [FILTER_CRAFTING_TYPES] =
        {
            dropdownData = self.craftingTypeFilterEntries,
            filterName = GetString(SI_SMITHING_DECONSTRUCTION_CRAFTING_TYPES_LABEL),
            filterTooltip = GetString(SI_SMITHING_DECONSTRUCTION_CRAFTING_TYPES_DESCRIPTION),
            multiSelection = true,
            multiSelectionTextFormatter = SI_SMITHING_DECONSTRUCTION_CRAFTING_TYPES_DROPDOWN_TEXT,
            noSelectionText = GetString(SI_SMITHING_DECONSTRUCTION_CRAFTING_TYPES_DROPDOWN_TEXT_DEFAULT),
            sorted = true,
        },
    }
end

function ZO_UniversalDeconstructionPanel_Gamepad:RefreshAccessibleCraftingTypeFilters()
    local craftingTypeItems = self.craftingTypeFilterEntries:GetAllItems()
    for _, craftingTypeItem in ipairs(craftingTypeItems) do
        local enabled = not (craftingTypeItem.craftingType == CRAFTING_TYPE_JEWELRYCRAFTING and not ZO_IsJewelryCraftingEnabled())
        self.craftingTypeFilterEntries:SetItemEnabled(craftingTypeItem, enabled)
    end
end

function ZO_UniversalDeconstructionPanel_Gamepad:SetFilterType(filterType, filterData)
    local visible = not self.control:IsHidden()
    if visible then
        GAMEPAD_TOOLTIPS:Clear(GAMEPAD_LEFT_TOOLTIP)
    end

    self.currentFilterData = filterData
    self.inventory.filterType = filterType
    self.inventory:HandleDirtyEvent()

    if filterData and visible then
        local tooltipText = filterData.tooltipText
        if type(tooltipText) == "function" then
            tooltipText = tooltipText()
        end

        if tooltipText then
            GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_TOOLTIP, tooltipText)
        end

        local currentTab = self.currentFilterData
        local craftingTypes = self:GetSelectedCraftingTypeFilters() or {}
        local includeBankedItems = self:GetIncludeBankedItems()
        self:FireCallbacks("OnFilterChanged", currentTab, craftingTypes, includeBankedItems)
    end
end

function ZO_UniversalDeconstructionPanel_Gamepad:RefreshFilter()
    if self.currentFilterData then
        self:SetFilterType(self.currentFilterData.filter, self.currentFilterData)
    end
end

function ZO_UniversalDeconstructionPanel_Gamepad:SetCraftingType(craftingType, oldCraftingType, isCraftingTypeDifferent)
    self:ClearSelections()
    self.inventory:HandleDirtyEvent()
end

function ZO_UniversalDeconstructionPanel_Gamepad:IsCurrentSelected()
    local bagId, slotIndex = self.inventory:CurrentSelectionBagAndSlot()
    return self.extractionSlot:ContainsBagAndSlot(bagId, slotIndex)
end

function ZO_UniversalDeconstructionPanel_Gamepad:UpdateSelection()
    for _, data in pairs(self.inventory.list.dataList) do
        ZO_GamepadCraftingUtils_SetEntryDataSlotted(data, self.extractionSlot:ContainsBagAndSlot(data.bagId, data.slotIndex))
        ZO_GamepadCraftingUtils_AddOverridesEntryData(data)
    end

    self:RefreshTooltip()
    self.inventory.list:RefreshVisible()
    self:UpdateEmptySlotIcon()
end

function ZO_UniversalDeconstructionPanel_Gamepad:UpdateEmptySlotIcon()
    local emptyTexture, multipleItemsTexture = self:GetExtractionSlotTextures()
    self.extractionSlot:SetEmptyTexture(emptyTexture)
    self.extractionSlot:SetMultipleItemsTexture(multipleItemsTexture)

    local slotBG = self.extractionSlot.control:GetNamedChild("Bg")
    local emptySlotIconControl = self.extractionSlot.control:GetNamedChild("EmptySlotIcon")
    emptySlotIconControl:ClearAnchors()
    emptySlotIconControl:SetAnchor(CENTER, slotBG)
end

function ZO_UniversalDeconstructionPanel_Gamepad:RefreshTooltip()
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

function ZO_UniversalDeconstructionPanel_Gamepad:AddItemToCraft(bagId, slotIndex)
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

function ZO_UniversalDeconstructionPanel_Gamepad:RemoveItemFromCraft(bagId, slotIndex)
    local itemRemoved = ZO_SharedSmithingExtraction.RemoveItemFromCraft(self, bagId, slotIndex)
    -- rediscover inventory actions since they have changed
    self.itemActions:SetInventorySlot(self.inventory:CurrentSelection())
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    self:UpdateSelection()

    return itemRemoved
end

function ZO_UniversalDeconstructionPanel_Gamepad:InitializeKeybindStripDescriptors()
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
                --Re-narrate when adding or removing items
                SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.inventory.list)
            end,
            enabled = function()
                return self:IsCurrentSelected() or self:CanItemBeAddedToCraft(self.inventory:CurrentSelectionBagAndSlot())
            end,
        },

        -- Deconstruct single
        {
            name = function()
                return GetString("SI_DECONSTRUCTACTIONNAME", DECONSTRUCT_ACTION_NAME_DECONSTRUCT)
            end,
            keybind = "UI_SHORTCUT_SECONDARY",
            gamepadOrder = 1010,
            callback = function()
                -- Use this function to ensure the extraction is evaluated for being part of an armory build.
                self:ConfirmExtractAll()
            end,
            enabled = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess() and self:IsExtractable() and self.extractionSlot:HasOneItem()
            end,
        },

        -- Deconstruct multiple
        {
            name = function()
                return GetString("SI_DECONSTRUCTACTIONNAME_PERFORMMULTIPLE", DECONSTRUCT_ACTION_NAME_DECONSTRUCT)
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

                    ZO_GamepadCraftingUtils_ShowDeconstructPartialStackDialog(bagId, slotIndex, maxIterations, PerformDeconstructPartial, DECONSTRUCT_ACTION_NAME_REFINE)
                else
                    -- extract all
                    self:ConfirmExtractAll()
                end
            end,
            enabled = function()
                if ZO_CraftingUtils_IsPerformingCraftProcess() or not self:IsExtractable() then
                    return false
                end
                return not self.extractionSlot:HasOneItem()
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
                return not ZO_CraftingUtils_IsPerformingCraftProcess()
            end,
        },
    }

    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.inventory.list)
    ZO_GamepadCraftingUtils_AddGenericCraftingBackKeybindsToDescriptor(self.keybindStripDescriptor)
    ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(self.keybindStripDescriptor)
end

function ZO_UniversalDeconstructionPanel_Gamepad:AddKeybinds()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_UniversalDeconstructionPanel_Gamepad:RemoveKeybinds()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

-- Required by ZO_SharedSmithingExtraction
function ZO_UniversalDeconstructionPanel_Gamepad:IsInRefineMode()
    return false
end

function ZO_UniversalDeconstructionPanel_Gamepad:GetIncludeBankedItems()
    return self.savedVars.includeBankedItemsChecked
end

function ZO_UniversalDeconstructionPanel_Gamepad:GetSelectedCraftingTypeFilters()
    local selectedCraftingTypes = {}
    local craftingTypeItems = self.craftingTypeFilterEntries:GetSelectedItems()
    for _, craftingTypeItem in ipairs(craftingTypeItems) do
        selectedCraftingTypes[craftingTypeItem.craftingType] = true
    end
    return selectedCraftingTypes
end

function ZO_UniversalDeconstructionPanel_Gamepad:SetupSavedVars()
    local defaults =
    {
        craftingTypes = {},
        includeBankedItemsChecked = true,
    }
    self.savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 1, "GamepadSmithingExtraction", defaults)

    self.filters[FILTER_INCLUDE_BANKED].checked = self.savedVars.includeBankedItemsChecked

    local savedCraftingTypes = self.savedVars.craftingTypes
    if not savedCraftingTypes then
        savedCraftingTypes = {}
        self.savedVars.craftingTypes = savedCraftingTypes
    end

    local craftingTypeItems = self.craftingTypeFilterEntries:GetAllItems()
    for _, craftingTypeItem in ipairs(craftingTypeItems) do
        local craftingType = craftingTypeItem.craftingType
        local selected = false
        if savedCraftingTypes[craftingType] then
            if craftingType ~= CRAFTING_TYPE_JEWELRYCRAFTING or ZO_IsJewelryCraftingEnabled() then
                selected = true
            end
        end
        self.craftingTypeFilterEntries:SetItemSelected(craftingTypeItem, selected)
    end
end

function ZO_UniversalDeconstructionPanel_Gamepad:ShowOptionsMenu()
    local dialogData = 
    {
        targetData = self.inventory:CurrentSelection(),
        itemActions = self.itemActions,
        finishedCallback = function(dialog)
            local dropdowns = dialog.dropdowns
            if dropdowns then
                for _, dropdown in pairs(dropdowns) do
                    dropdown:Deactivate()
                end
                dialog.dropdowns = nil
            end

            local targetData = self.inventory.list:GetTargetData()
            if targetData then
                GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, targetData.bagId, targetData.slotIndex, SHOW_COMBINED_COUNT)
            else
                GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
            end
            self:SaveFilters()
        end,
    }
    dialogData.filters = self.filters

    if not self.craftingOptionsDialogGamepad then
        self.craftingOptionsDialogGamepad = ZO_CraftingOptionsDialogGamepad:New()
    end

    self.craftingOptionsDialogGamepad:ShowOptionsDialog(dialogData)
end

function ZO_UniversalDeconstructionPanel_Gamepad:SaveFilters()
    local savedVars = self.savedVars
    savedVars.includeBankedItemsChecked = self.filters[FILTER_INCLUDE_BANKED].checked
    savedVars.craftingTypes = self:GetSelectedCraftingTypeFilters()

    self:RefreshFilter()
    ZO_SavePlayerConsoleProfile()
end

ZO_UniversalDeconstructionInventory_Gamepad = ZO_GamepadCraftingInventory:Subclass()

function ZO_UniversalDeconstructionInventory_Gamepad:Initialize(universalDeconstructionPanel, control, ...)
    ZO_GamepadCraftingInventory.Initialize(self, control, ...)
    self.universalDeconstructionPanel = universalDeconstructionPanel
    self.filterType = SMITHING_FILTER_TYPE_WEAPONS
    self:SetNoItemLabelText(GetString(SI_SMITHING_DECONSTRUCTION_NO_MATCHING_ITEMS))

    local DEFAULT_SORT = nil
    self:SetOverrideItemSort(DEFAULT_SORT)

    local function GetTraitSortComparison(bagId, slotIndex)
        local traitInformation = GetItemTraitInformation(bagId, slotIndex)
        return ZO_GetItemTraitInformation_SortOrder(traitInformation)
    end
    self:SetCustomSort(GetTraitSortComparison)

    local glyphCategoryName = GetString("SI_ITEMTYPEDISPLAYCATEGORY", ITEM_TYPE_DISPLAY_CATEGORY_GLYPH)
    local itemTypeCategoryNames =
    {
        [ITEMTYPE_GLYPH_ARMOR] = glyphCategoryName,
        [ITEMTYPE_GLYPH_JEWELRY] = glyphCategoryName,
        [ITEMTYPE_GLYPH_WEAPON] = glyphCategoryName,
    }
    local itemFilterTypeCategoryNames =
    {
        [ITEMFILTERTYPE_ARMOR] = GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_ARMOR),
        [ITEMFILTERTYPE_JEWELRY] = GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_JEWELRY),
        [ITEMFILTERTYPE_WEAPONS] = GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_WEAPONS),
    }

    local function GetCategoryName(slotData)
        slotData.bestItemCategoryName = itemTypeCategoryNames[slotData.itemType]
        if slotData.bestItemCategoryName then
            return
        end

        if slotData.filterData then
            for _, itemFilterType in ipairs(slotData.filterData) do
                slotData.bestItemCategoryName = itemFilterTypeCategoryNames[itemFilterType]
                if slotData.bestItemCategoryName then
                    return
                end
            end
        end

        slotData.bestItemCategoryName = ""
    end
    self:SetCustomBestItemCategoryNameFunction(GetCategoryName)
end

function ZO_UniversalDeconstructionInventory_Gamepad:IsHidden()
    return self.control:IsHidden()
end

function ZO_UniversalDeconstructionInventory_Gamepad:Refresh(data)
    local craftingTypes = self.universalDeconstructionPanel:GetSelectedCraftingTypeFilters()
    local isDeconstructableFunction = function(...)
        return ZO_UniversalDeconstructionPanel_Shared.IsDeconstructableItem(..., craftingTypes)
    end

    local DONT_USE_WORN_BAG = false
    local excludeBanked = not self.universalDeconstructionPanel:GetIncludeBankedItems()
    local validItems = self:GetIndividualInventorySlotsAndAddToScrollData(isDeconstructableFunction, ZO_UniversalDeconstructionPanel_Shared.DoesItemPassFilter, self.filterType, data, DONT_USE_WORN_BAG, excludeBanked)
    self.universalDeconstructionPanel:OnInventoryUpdate(validItems, self.filterType)
end

function ZO_UniversalDeconstructionInventory_Gamepad:GetCurrentFilter()
    return self.universalDeconstructionPanel.currentFilterData or ZO_GetUniversalDeconstructionFilterType("all")
end

function ZO_UniversalDeconstructionInventory_Gamepad:GetCurrentFilterType()
    return self.filterType
end