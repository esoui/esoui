ZO_UniversalDeconstructionPanel_Keyboard = ZO_UniversalDeconstructionPanel_Shared:Subclass()

function ZO_UniversalDeconstructionPanel_Keyboard:Initialize(control, parentObject)
    self.slotContainer = control:GetNamedChild("SlotContainer")
    self.extractSlot = self.slotContainer:GetNamedChild("ExtractionSlot")
    self.extractLabel = self.slotContainer:GetNamedChild("ExtractLabel")
    self.extractLabel:SetText(GetString(SI_SMITHING_DECONSTRUCT_EQUIPMENT))
    ZO_UniversalDeconstructionPanel_Shared.Initialize(self, control, parentObject, self.extractSlot, self.extractLabel)

    self.inventory = ZO_UniversalDeconstructionInventory_Keyboard:New(self.control:GetNamedChild("Inventory"), self)
    self:InitExtractionSlot("universalDeconstructionSceneKeyboard")

    self.includeBankedItemsCheckbox = self.inventory.control:GetNamedChild("IncludeBanked")
    self.craftingTypeFilters = self.inventory.control:GetNamedChild("CraftingTypes")
    self:InitializeFilters()

    local function OnAddOnLoaded(event, name)
        if name == "ZO_Ingame" then
            self:SetupSavedVars()
            self:RefreshAccessibleCraftingTypeFilters()
            self.control:UnregisterForEvent(EVENT_ADD_ON_LOADED)
        end
    end

    self.control:RegisterForEvent(EVENT_ADD_ON_LOADED, OnAddOnLoaded)
end

function ZO_UniversalDeconstructionPanel_Keyboard:InitializeFilters()
    local function OnFilterChanged()
        self:OnFilterChanged()
    end

    -- Initialize the Include Banked Items checkbox.
    ZO_CheckButton_SetToggleFunction(self.includeBankedItemsCheckbox, OnFilterChanged)
    ZO_CheckButton_SetLabelText(self.includeBankedItemsCheckbox, GetString(SI_CRAFTING_INCLUDE_BANKED))

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", function() 
        ZO_CheckButton_SetCheckState(self.includeBankedItemsCheckbox, self.savedVars.includeBankedItemsChecked)
    end)

    -- Initialize the Crafting Types multiselect combobox.
    local dropdown = ZO_ComboBox_ObjectFromContainer(self.craftingTypeFilters)
    self.craftingTypeFiltersDropdown = dropdown
    dropdown:SetHideDropdownCallback(OnFilterChanged)
    dropdown:SetNoSelectionText(GetString(SI_SMITHING_DECONSTRUCTION_CRAFTING_TYPES_DROPDOWN_TEXT_DEFAULT))
    dropdown:SetMultiSelectionTextFormatter(SI_SMITHING_DECONSTRUCTION_CRAFTING_TYPES_DROPDOWN_TEXT)
    dropdown:SetSortsItems(true)

    for _, craftingType in ipairs(ZO_UNIVERSAL_DECONSTRUCTION_CRAFTING_TYPES) do
        local entry = dropdown:CreateItemEntry(GetString("SI_TRADESKILLTYPE", craftingType))
        entry.filterType = craftingType
        dropdown:AddItem(entry)
    end

    --This needs to happen AFTER the above CraftingAnimationsStarted callback is registered, so the disabled state doesn't get clobbered by setting the check state for the button
    ZO_CraftingUtils_ConnectCheckBoxToCraftingProcess(self.includeBankedItemsCheckbox)
    ZO_CraftingUtils_ConnectComboBoxToCraftingProcess(self.craftingTypeFiltersDropdown)
end

function ZO_UniversalDeconstructionPanel_Keyboard:RefreshAccessibleCraftingTypeFilters()
    local dropdown = self.craftingTypeFiltersDropdown
    local items = dropdown:GetItems()
    local jewelryCraftingItem = nil

    for index, item in ipairs(items) do
        if item.filterType == CRAFTING_TYPE_JEWELRYCRAFTING then
            jewelryCraftingItem = item
            break
        end
    end

    if jewelryCraftingItem then
        if ZO_IsJewelryCraftingEnabled() then
            self.craftingTypeFiltersDropdown:SetItemEnabled(jewelryCraftingItem, true)
            self.craftingTypeFiltersDropdown:SetItemOnEnter(jewelryCraftingItem, nil)
            self.craftingTypeFiltersDropdown:SetItemOnExit(jewelryCraftingItem, nil)
        else
            self.craftingTypeFiltersDropdown:SetItemEnabled(jewelryCraftingItem, false)

            local tooltipText = nil
            local jewelryCraftingCollectibleData = ZO_GetJewelryCraftingCollectibleData()
            if jewelryCraftingCollectibleData then
                local jewelryCraftingTradeskillName = GetString("SI_TRADESKILLTYPE", CRAFTING_TYPE_JEWELRYCRAFTING)
                tooltipText = ZO_ERROR_COLOR:Colorize(zo_strformat(SI_SMITHING_CRAFTING_TYPE_LOCKED, jewelryCraftingCollectibleData:GetFormattedName(), jewelryCraftingTradeskillName))
            end

            local function OnCraftingTypeFilterDropdownEnter(control)
                local offsetX = control:GetParent():GetLeft() - control:GetLeft() - 5
                InitializeTooltip(InformationTooltip, control, RIGHT, offsetX, 0, LEFT)
                InformationTooltip:AddLine(tooltipText)
            end
            self.craftingTypeFiltersDropdown:SetItemOnEnter(jewelryCraftingItem, OnCraftingTypeFilterDropdownEnter)

            local function OnCraftingTypeFilterDropdownExit(control)
                ClearTooltip(InformationTooltip)
            end
            self.craftingTypeFiltersDropdown:SetItemOnExit(jewelryCraftingItem, OnCraftingTypeFilterDropdownExit)

            local selectedCraftingTypeFilters = self:GetSavedCraftingTypeFilters()
            if selectedCraftingTypeFilters and selectedCraftingTypeFilters[CRAFTING_TYPE_JEWELRYCRAFTING] then
                selectedCraftingTypeFilters[CRAFTING_TYPE_JEWELRYCRAFTING] = nil
                dropdown:RemoveItemFromSelected(jewelryCraftingItem)
                dropdown:RefreshSelectedItemText()
            end
        end
    end
end

function ZO_UniversalDeconstructionPanel_Keyboard:SetupSavedVars()
    local defaults =
    {
        craftingTypeFilters = {},
        includeBankedItemsChecked = true,
    }
    self.savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 2, "UniversalDeconstruction", defaults)

    ZO_CheckButton_SetCheckState(self.includeBankedItemsCheckbox, self:GetSavedIncludeBankedItemsFilter())

    local selectedCraftingTypeFilters = self:GetSavedCraftingTypeFilters()
    if not ZO_IsTableEmpty(selectedCraftingTypeFilters) then
        local craftingTypeFiltersDropdown = self.craftingTypeFiltersDropdown
        local IGNORE_CALLBACKS = true
        for _, item in ipairs(craftingTypeFiltersDropdown:GetItems()) do
            if selectedCraftingTypeFilters[item.filterType] then
                craftingTypeFiltersDropdown:SelectItem(item, IGNORE_CALLBACKS)
            end
        end
    end
end

function ZO_UniversalDeconstructionPanel_Keyboard:GetSavedIncludeBankedItemsFilter()
    return self.savedVars.includeBankedItemsChecked
end

function ZO_UniversalDeconstructionPanel_Keyboard:GetSavedCraftingTypeFilters()
    return self.savedVars.craftingTypeFilters
end

function ZO_UniversalDeconstructionPanel_Keyboard:GetSelectedCraftingTypeFilters()
    local craftingTypeFiltersDropdown = self.craftingTypeFiltersDropdown
    local selectedFilterTypes = {}
    for _, item in ipairs(craftingTypeFiltersDropdown:GetItems()) do
        if craftingTypeFiltersDropdown:IsItemSelected(item) then
            selectedFilterTypes[item.filterType] = true
        end
    end
    return selectedFilterTypes
end

function ZO_UniversalDeconstructionPanel_Keyboard:OnShown()
    self:ClearSelections()
    self:RefreshAccessibleCraftingTypeFilters()

    self.inventory:HandleDirtyEvent()
    self.inventory:PerformFullRefresh()
end

function ZO_UniversalDeconstructionPanel_Keyboard:OnFilterChanged()
	local includeBankedItemsChecked = ZO_CheckButton_IsChecked(self.includeBankedItemsCheckbox)
	if self.savedVars.includeBankedItemsChecked ~= includeBankedItemsChecked then
		self.savedVars.includeBankedItemsChecked = includeBankedItemsChecked
	end

    local craftingTypeFilters = self:GetSelectedCraftingTypeFilters()
    self.savedVars.craftingTypeFilters = craftingTypeFilters

    local currentTab = self.inventory:GetCurrentFilter()
    if not craftingTypeFilters then
        craftingTypeFilters = {}
    end
    self:FireCallbacks("OnFilterChanged", currentTab, craftingTypeFilters, includeBankedItemsChecked)

    self.inventory:PerformFullRefresh()
end

ZO_UniversalDeconstructionInventory_Keyboard = ZO_CraftingInventory:Subclass()

function ZO_UniversalDeconstructionInventory_Keyboard:Initialize(control, universalDeconstructionPanel, ...)
    ZO_CraftingInventory.Initialize(self, control, ...)
    self.universalDeconstructionPanel = universalDeconstructionPanel

    local tabFilters = {}
    for _, filterData in ipairs(ZO_UNIVERSAL_DECONSTRUCTION_FILTER_TYPES) do
        local tabFilterData = self:CreateNewTabFilterData(filterData.filter, filterData.displayName, filterData.iconUp, filterData.iconDown, filterData.iconOver, filterData.iconDisabled)
        tabFilterData.filter = filterData
        tabFilterData.enabled = filterData.enabled
        if filterData.tooltipText then
            -- Only override the tooltip text if specified.
            tabFilterData.tooltipText = filterData.tooltipText
        end
        table.insert(tabFilters, tabFilterData)
    end

    self:SetFilters(tabFilters)
    self:SetSortColumnHidden({sellInformationSortOrder = true}, true)
    self:SetNoItemLabelText(GetString(SI_SMITHING_DECONSTRUCTION_NO_MATCHING_ITEMS))

    self.sortOrder = ZO_SORT_ORDER_UP
    self.sortKey = "traitInformationSortOrder"
    self.sortHeaders:SelectHeaderByKey(self.sortKey, ZO_SortHeaderGroup.SUPPRESS_CALLBACKS, not ZO_SortHeaderGroup.FORCE_RESELECT, self.sortOrder)
end

function ZO_UniversalDeconstructionInventory_Keyboard:IsHidden()
    return self.control:IsHidden()
end

function ZO_UniversalDeconstructionInventory_Keyboard:AddListDataTypes()
    local rowSetupFunction = self:GetDefaultTemplateSetupFunction()

    local function RowSetup(rowControl, data)
        local inventorySlot = rowControl:GetNamedChild("Button")
        ZO_ItemSlot_SetAlwaysShowStackCount(inventorySlot, false)
        rowSetupFunction(rowControl, data)
    end

    ZO_ScrollList_AddDataType(self.list, self:GetScrollDataType(), "ZO_CraftingInventoryComponentRow", 52, RowSetup, nil, nil, ZO_InventorySlot_OnPoolReset)
end

function ZO_UniversalDeconstructionInventory_Keyboard:IsLocked(bagId, slotIndex)
    return ZO_CraftingInventory.IsLocked(self, bagId, slotIndex) or self.universalDeconstructionPanel:IsSlotted(bagId, slotIndex) or IsItemPlayerLocked(bagId, slotIndex)
end

function ZO_UniversalDeconstructionInventory_Keyboard:ChangeFilter(filterData)
    ZO_CraftingInventory.ChangeFilter(self, filterData)

    self.filter = filterData.filter
    self.filterType = filterData.descriptor
    self.universalDeconstructionPanel:OnFilterChanged()
    self:HandleDirtyEvent()
end

function ZO_UniversalDeconstructionInventory_Keyboard:GetCurrentFilter()
    return self.filter or ZO_GetUniversalDeconstructionFilterType("all")
end

function ZO_UniversalDeconstructionInventory_Keyboard:GetCurrentFilterType()
    return self.filterType
end

function ZO_UniversalDeconstructionInventory_Keyboard:Refresh(data)
    local craftingTypes = self.universalDeconstructionPanel:GetSavedCraftingTypeFilters()
    local isDeconstructableFunction = function(...)
        return ZO_UniversalDeconstructionPanel_Shared.IsDeconstructableItem(..., craftingTypes)
    end

    local DONT_USE_WORN_BAG = false
    local excludeBanked = not self.universalDeconstructionPanel:GetSavedIncludeBankedItemsFilter()
    local validItems = self:GetIndividualInventorySlotsAndAddToScrollData(isDeconstructableFunction, ZO_UniversalDeconstructionPanel_Shared.DoesItemPassFilter, self.filterType, data, DONT_USE_WORN_BAG, excludeBanked)
    self.universalDeconstructionPanel:OnInventoryUpdate(validItems, self.filterType)
    self:SetNoItemLabelHidden(#data > 0)
end

function ZO_UniversalDeconstructionInventory_Keyboard:ShowAppropriateSlotDropCallouts(bagId, slotIndex)
    self.universalDeconstructionPanel:ShowAppropriateSlotDropCallouts()
end

function ZO_UniversalDeconstructionInventory_Keyboard:HideAllSlotDropCallouts()
    self.universalDeconstructionPanel:HideAllSlotDropCallouts()
end