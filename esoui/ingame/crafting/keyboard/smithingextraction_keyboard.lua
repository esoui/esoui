ZO_SmithingExtraction = ZO_SharedSmithingExtraction:Subclass()

function ZO_SmithingExtraction:New(...)
    return ZO_SharedSmithingExtraction.New(self, ...)
end

function ZO_SmithingExtraction:Initialize(control, owner, isRefinementOnly)
    local slotContainer = control:GetNamedChild("SlotContainer")
    self.control = control
    ZO_SharedSmithingExtraction.Initialize(self, slotContainer:GetNamedChild("ExtractionSlot"), slotContainer:GetNamedChild("ExtractLabel"), owner, isRefinementOnly)

    self.inventory = ZO_SmithingExtractionInventory:New(self, self.control:GetNamedChild("Inventory"), isRefinementOnly)
    self:InitExtractionSlot("smithing")

    if not isRefinementOnly then
        self.includeBankedItemsCheckbox = self.inventory.control:GetNamedChild("IncludeBanked")
        self:InitializeFilters()
        local function OnAddOnLoaded(event, name)
            if name == "ZO_Ingame" then
                self:SetupSavedVars()
                self.control:UnregisterForEvent(EVENT_ADD_ON_LOADED)
            end
        end
        self.control:RegisterForEvent(EVENT_ADD_ON_LOADED, OnAddOnLoaded)
    end
end

function ZO_SmithingExtraction:InitializeFilters()
    local function OnFilterChanged()
        self:OnFilterChanged(ZO_CheckButton_IsChecked(self.includeBankedItemsCheckbox))
    end

    ZO_CheckButton_SetToggleFunction(self.includeBankedItemsCheckbox, OnFilterChanged)
    ZO_CheckButton_SetLabelText(self.includeBankedItemsCheckbox, GetString(SI_CRAFTING_INCLUDE_BANKED))
    
    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", function() 
        ZO_CheckButton_SetCheckState(self.includeBankedItemsCheckbox, self.savedVars.includeBankedItemsChecked)
    end)

    --This needs to happen AFTER the above CraftingAnimationsStarted callback is registered, so the disabled state doesn't get clobbered by setting the check state for the button
    ZO_CraftingUtils_ConnectCheckBoxToCraftingProcess(self.includeBankedItemsCheckbox)
end

function ZO_SmithingExtraction:SetupSavedVars()
    local defaults =
    {
        includeBankedItemsChecked = true,
    }
    self.savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 1, "SmithingExtraction", defaults)
    ZO_CheckButton_SetCheckState(self.includeBankedItemsCheckbox, self.savedVars.includeBankedItemsChecked)
end

function ZO_SmithingExtraction_IncludeBankedItemsOnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, -10)
    SetTooltipText(InformationTooltip, GetString(SI_CRAFTING_INCLUDE_BANKED_TOOLTIP))
end

function ZO_SmithingExtraction_FilterOnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_SmithingExtraction:SetCraftingType(craftingType, oldCraftingType, isCraftingTypeDifferent)
    self:ClearSelections()
    if isCraftingTypeDifferent then
        self.inventory:SetActiveFilterByDescriptor(nil)
    end
    self.inventory:HandleDirtyEvent()
end

function ZO_SmithingExtraction:SetHidden(hidden)
    self.control:SetHidden(hidden)
    self.inventory:HandleDirtyEvent()
end

function ZO_SmithingExtraction:OnFilterChanged()
    ZO_SharedSmithingExtraction.OnFilterChanged(self)

    local filterType = self:GetFilterType()
    if filterType then
        self.extractionSlot:SetEmptyTexture(ZO_CraftingUtils_GetItemSlotTextureFromSmithingFilter(filterType))
    end
    local deconstructionType = self:GetDeconstructionType()
    if deconstructionType then
        self.extractionSlot:SetMultipleItemsTexture(ZO_CraftingUtils_GetMultipleItemsTextureFromSmithingDeconstructionType(deconstructionType))
    end

	if not self:IsInRefineMode() then
		local includeBankedItemsChecked = ZO_CheckButton_IsChecked(self.includeBankedItemsCheckbox)
		if self.savedVars.includeBankedItemsChecked ~= includeBankedItemsChecked then
			self.savedVars.includeBankedItemsChecked = includeBankedItemsChecked
			self.inventory:PerformFullRefresh()
		end
	end
end

ZO_SmithingRefinement = ZO_SmithingExtraction:Subclass()

function ZO_SmithingRefinement:New(...)
    return ZO_SmithingExtraction.New(self, ...)
end

function ZO_SmithingRefinement:Initialize(control, owner)
    local REFINEMENT_ONLY = true
    ZO_SmithingExtraction.Initialize(self, control, owner, REFINEMENT_ONLY)

    self.multiRefineSpinner = ZO_MultiCraftSpinner:New(control:GetNamedChild("SlotContainerSpinner"))

    -- connect refine spinner to crafting process
    local function UpdateMultiRefineSpinner()
        if not self.control:IsHidden() then
            self:UpdateMultiRefine()
        end
    end
    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", UpdateMultiRefineSpinner)
    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", UpdateMultiRefineSpinner)
end

function ZO_SmithingRefinement:ConfirmRefine()
    if self:IsMultiExtract() then
        self:ConfirmExtractAll()
    else
        local iterations = self.multiRefineSpinner:GetValue()
        self:ExtractPartialStack(iterations * GetRequiredSmithingRefinementStackSize())
    end
end

function ZO_SmithingRefinement:UpdateMultiRefine()
    local shouldEnableSpinner = true
    local NO_OVERRIDE = nil
    if self.extractionSlot:HasOneItem() then
        local bagId, slotIndex = self.extractionSlot:GetItemBagAndSlot(1)

        local refineSize = GetRequiredSmithingRefinementStackSize()
        local maxIterations = zo_min(zo_floor(self.inventory:GetStackCount(bagId, slotIndex) / refineSize), MAX_ITERATIONS_PER_DECONSTRUCTION)

        self.multiRefineSpinner:SetDisplayTextOverride(NO_OVERRIDE)
        self.multiRefineSpinner:SetMinMax(1, maxIterations)
    elseif self.extractionSlot:HasMultipleItems() then
        self.multiRefineSpinner:SetDisplayTextOverride(GetString(SI_CRAFTING_QUANTITY_ALL))
        shouldEnableSpinner = false
    else
        self.multiRefineSpinner:SetDisplayTextOverride(NO_OVERRIDE)
        self.multiRefineSpinner:SetMinMax(0, 0)
    end

    if ZO_CraftingUtils_IsPerformingCraftProcess() then
        shouldEnableSpinner = false
    end
    self.multiRefineSpinner:SetEnabled(shouldEnableSpinner)
    self.multiRefineSpinner:UpdateButtons()
end

function ZO_SmithingRefinement:SetRefineIterationsToMax()
    if self.extractionSlot:HasOneItem() then
        self.multiRefineSpinner:SetValue(self.multiRefineSpinner:GetMax())
    end
end

function ZO_SmithingRefinement:OnSlotChanged()
    ZO_SmithingExtraction.OnSlotChanged(self)
    self:UpdateMultiRefine()
    self:SetRefineIterationsToMax()
end

function ZO_SmithingRefinement:OnInventoryUpdate(validItems, filterType)
    ZO_SmithingExtraction.OnInventoryUpdate(self, validItems, filterType)
    self:UpdateMultiRefine()
end

ZO_SmithingExtractionInventory = ZO_CraftingInventory:Subclass()

function ZO_SmithingExtractionInventory:New(...)
    return ZO_CraftingInventory.New(self, ...)
end

function ZO_SmithingExtractionInventory:Initialize(owner, control, isRefinementOnly, ...)
    ZO_CraftingInventory.Initialize(self, control, ...)

    self.owner = owner

    if isRefinementOnly then
        self:SetFilters{
            self:CreateNewTabFilterData(SMITHING_FILTER_TYPE_RAW_MATERIALS, GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_RAW_MATERIALS), "EsoUI/Art/Inventory/inventory_tabIcon_crafting_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_crafting_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_crafting_over.dds", "EsoUI/Art/Inventory/inventory_tabIcon_crafting_disabled.dds"),
        }

        self:SetSortColumnHidden({ statusSortOrder = true, traitInformationSortOrder = true, sellInformationSortOrder = true }, true)

        self.sortOrder = ZO_SORT_ORDER_UP
        self.sortKey = "name"
    else
        self:SetFilters{
            self:CreateNewTabFilterData(SMITHING_FILTER_TYPE_JEWELRY, GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_JEWELRY), "EsoUI/Art/Crafting/jewelry_tabIcon_icon_up.dds", "EsoUI/Art/Crafting/jewelry_tabIcon_down.dds", "EsoUI/Art/Crafting/jewelry_tabIcon_icon_over.dds", "EsoUI/Art/Inventory/inventory_tabIcon_jewelry_disabled.dds", CanSmithingJewelryPatternsBeCraftedHere),
            self:CreateNewTabFilterData(SMITHING_FILTER_TYPE_ARMOR, GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_ARMOR), "EsoUI/Art/Inventory/inventory_tabIcon_armor_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_over.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_disabled.dds", CanSmithingApparelPatternsBeCraftedHere),
            self:CreateNewTabFilterData(SMITHING_FILTER_TYPE_WEAPONS, GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_WEAPONS), "EsoUI/Art/Inventory/inventory_tabIcon_weapons_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_over.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_disabled.dds", CanSmithingWeaponPatternsBeCraftedHere),
        }

        self:SetSortColumnHidden({ sellInformationSortOrder = true }, true)

        self.sortOrder = ZO_SORT_ORDER_UP
        self.sortKey = "traitInformationSortOrder"
    end

    self.sortHeaders:SelectHeaderByKey(self.sortKey, ZO_SortHeaderGroup.SUPPRESS_CALLBACKS, not ZO_SortHeaderGroup.FORCE_RESELECT, self.sortOrder)
end

function ZO_SmithingExtractionInventory:AddListDataTypes()
    local defaultSetup = self:GetDefaultTemplateSetupFunction()

    local function RowSetup(rowControl, data)
        local inventorySlot = rowControl:GetNamedChild("Button")
        local questPin = rowControl:GetNamedChild("QuestPin")
        ZO_ItemSlot_SetAlwaysShowStackCount(inventorySlot, false, self.filterType == SMITHING_FILTER_TYPE_RAW_MATERIALS and GetRequiredSmithingRefinementStackSize())

        defaultSetup(rowControl, data)

        if self.filterType == SMITHING_FILTER_TYPE_RAW_MATERIALS then
            local isQuestItem = self.owner:CanRefineToQuestItem(data.bagId, data.slotIndex)
            questPin:SetHidden(not isQuestItem)
            ZO_ItemSlot_SetupUsableAndLockedColor(inventorySlot, data.stackCount >= GetRequiredSmithingRefinementStackSize())
        else
            questPin:SetHidden(true)
        end
    end

    ZO_ScrollList_AddDataType(self.list, self:GetScrollDataType(), "ZO_CraftingInventoryComponentRow", 52, RowSetup, nil, nil, ZO_InventorySlot_OnPoolReset)
end

function ZO_SmithingExtractionInventory:IsLocked(bagId, slotIndex)
    return ZO_CraftingInventory.IsLocked(self, bagId, slotIndex) or self.owner:IsSlotted(bagId, slotIndex) or IsItemPlayerLocked(bagId, slotIndex)
end

function ZO_SmithingExtractionInventory:ChangeFilter(filterData)
    ZO_CraftingInventory.ChangeFilter(self, filterData)

    self.filterType = filterData.descriptor

    self:SetNoItemLabelText(GetString("SI_SMITHINGFILTERTYPE_EXTRACTNONE", self.filterType))

    self.owner:OnFilterChanged()
    self:HandleDirtyEvent()
end

function ZO_SmithingExtractionInventory:GetCurrentFilterType()
    return self.filterType
end

function ZO_SmithingExtractionInventory:Refresh(data)
    local validItems
    if self.filterType == SMITHING_FILTER_TYPE_RAW_MATERIALS then
        validItems = self:EnumerateInventorySlotsAndAddToScrollData(ZO_SharedSmithingExtraction_IsRefinableItem, ZO_SharedSmithingExtraction_DoesItemPassFilter, self.filterType, data)
    else
        local DONT_USE_WORN_BAG = false
        local excludeBanked = not self.owner.savedVars.includeBankedItemsChecked
        validItems = self:GetIndividualInventorySlotsAndAddToScrollData(ZO_SharedSmithingExtraction_IsExtractableItem, ZO_SharedSmithingExtraction_DoesItemPassFilter, self.filterType, data, DONT_USE_WORN_BAG, excludeBanked)
    end
    self.owner:OnInventoryUpdate(validItems, self.filterType)

    self:SetNoItemLabelHidden(#data > 0)
end

function ZO_SmithingExtractionInventory:ShowAppropriateSlotDropCallouts(bagId, slotIndex)
    self.owner:ShowAppropriateSlotDropCallouts()
end

function ZO_SmithingExtractionInventory:HideAllSlotDropCallouts()
    self.owner:HideAllSlotDropCallouts()
end