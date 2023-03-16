-- ItemSetsBook (Reconstruct) --

ZO_RetraitStation_Reconstruct_Gamepad = ZO_ItemSetsBook_Gamepad_Base:Subclass()

function ZO_RetraitStation_Reconstruct_Gamepad:New(...)
    return ZO_ItemSetsBook_Gamepad_Base.New(self, ...)
end

function ZO_RetraitStation_Reconstruct_Gamepad:Initialize(control, scene)
    ZO_ItemSetsBook_Gamepad_Base.Initialize(self, control, scene)

    GAMEPAD_RECONSTRUCT_FRAGMENT = self:GetFragment()
    self:GetFragment():RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_HIDING then
            self:HideReconstructOptions()
            -- Clear the result tooltip as well as any associated Crafting Result that may still be in progress.
            self.resultTooltip.tip:ClearLines()
            GAMEPAD_CRAFTING_RESULTS:SetCraftingTooltip(nil)
        end
    end)
    self.costContainer = self.control:GetNamedChild("Cost")
    self.costFragment = ZO_FadeSceneFragment:New(self.costContainer)

    self.optionsModeHidden = true
    self.itemSetPieceData = ZO_ItemSetCollectionReconstructionPieceData:New()
    self.optionsPanel = self.control:GetNamedChild("Options")
    self.traitListContainer = self.optionsPanel:GetNamedChild("TraitList")
    self.qualityListContainer = self.optionsPanel:GetNamedChild("QualityList")
    self.itemHeader = self.optionsPanel:GetNamedChild("Header")
    self.itemIcon = self.itemHeader:GetNamedChild("Icon")
    self.itemName = self.itemHeader:GetNamedChild("Label")
    self.resultTooltip = self.control:GetNamedChild("ResultTooltip")

    --Register the result tooltip for narration
    local tooltipNarrationInfo = 
    {
        canNarrate = function()
            return not self.resultTooltip:IsHidden()
        end,
        tooltipNarrationFunction = function()
            return self.resultTooltip.tip:GetNarrationText()
        end,
    }
    GAMEPAD_TOOLTIPS:RegisterCustomTooltipNarration(tooltipNarrationInfo)

    --Register the cost for narration
    local costTooltipNarrationInfo =
    {
        canNarrate = function()
            return self.costFragment:IsShowing()
        end,
        tooltipNarrationFunction = function()
            local narrations = {}
            --Get the header narration
            table.insert(narrations, GetString(SI_ITEM_RECONSTRUCTION_TOTAL_COST))

            --Get the currency cost narration
            local currencyCosts, materialCosts = self.itemSetPieceData:GetCostInfo()
            local currencyCost = currencyCosts[1]
            if currencyCost then
                table.insert(narrations, ZO_Currency_FormatGamepad(currencyCost.currencyType, currencyCost.currencyRequired, ZO_CURRENCY_FORMAT_AMOUNT_NAME))
            end

            --Get the required materials narrations
            for index, materialCost in ipairs(materialCosts) do
                local itemName = GetItemLinkName(materialCost.reagentItemLink)
                local stackCount = materialCost.reagentsRequired
                table.insert(narrations, zo_strformat(SI_GAMEPAD_RECONSTRUCT_REQUIRED_ITEM_NARRATION_FORMATTER, stackCount, itemName))
            end

            return narrations
        end,
    }
    GAMEPAD_TOOLTIPS:RegisterCustomTooltipNarration(costTooltipNarrationInfo)

    self.materialContainer = self.costContainer:GetNamedChild("SummaryMaterials")
    self.materialPool = ZO_ControlPool:New("ZO_GamepadDisplayEntryTemplateLowercase34", self.materialContainer)

    local function OnCraftStarted()
        self.isCraftInProgress = true
    end

    local function OnCraftStopped()
        self.isCraftInProgress = false
        if self:IsOptionsModeShowing() then
            self:ShowItemSetsBook()
        end
    end

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", OnCraftStarted)
    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", OnCraftStopped)
end

function ZO_RetraitStation_Reconstruct_Gamepad:OnHorizonalScrollListCleared(list)
    local listContainer = list:GetControl():GetParent()
    listContainer.selectedLabel:SetHidden(true)
    listContainer.extraInfoLabel:SetHidden(true)
end

function ZO_RetraitStation_Reconstruct_Gamepad:InitializeTraitList(scrollListClass, listSlotTemplate, validationFont)
    local listContainer = self.traitListContainer
    listContainer.titleLabel:SetText(GetString(SI_SMITHING_HEADER_TRAIT))

    local function SetupFunction(control, data, selected, selectedDuringRebuild, enabled)
        self:SetupSharedSlot(control, SLOT_TYPE_SMITHING_TRAIT, listContainer, self.traitList)
        local DO_NOT_SHOW_STACK_COUNT = false
        ZO_ItemSlot_SetAlwaysShowStackCount(control, DO_NOT_SHOW_STACK_COUNT)

        local EMPTY_STACK_COUNT = 0
        ZO_ItemSlot_SetupSlot(control, EMPTY_STACK_COUNT, data.icon, data.traitKnown, not enabled)

        if selected then
            listContainer.extraInfoLabel:SetHidden(data.traitKnown)
            listContainer.selectedLabel:SetText(data.localizedName)
            listContainer.selectedLabel:SetHidden(false)
        end
    end

    local function EqualityFunction(leftData, rightData)
        return leftData.name == rightData.name
    end

    local function OnHorizonalScrollListCleared(...)
        self:OnHorizonalScrollListCleared(...)
    end

    local BASE_NUM_ITEMS_IN_LIST = 5
    self.traitList = scrollListClass:New(listContainer.listControl, listSlotTemplate, BASE_NUM_ITEMS_IN_LIST, SetupFunction, EqualityFunction, OnHorizonalScrollListShown, OnHorizonalScrollListCleared)
    local MIN_SCALE = 0.6
    local MAX_SCALE = 1.1
    self.traitList:SetScaleExtents(MIN_SCALE, MAX_SCALE)
    self.traitList:SetOnSelectedDataChangedCallback(function(selectedData, oldData, selectedDuringRebuild)
        self.isTraitValid = selectedData.traitKnown
        self.itemSetPieceData:SetOverrideTraitType(selectedData.type)
        self:RefreshResultTooltip()
        --Do not try to narrate if a craft is in progress, as the screen will close once it's done
        if not self.isCraftInProgress then
            SCREEN_NARRATION_MANAGER:QueueFocus(self.focus)
        end
    end)

    ZO_CraftingUtils_ConnectHorizontalScrollListToCraftingProcess(self.traitList)
end

function ZO_RetraitStation_Reconstruct_Gamepad:InitializeQualityList(scrollListClass, listSlotTemplate, validationFont)
    local listContainer = self.qualityListContainer
    listContainer.titleLabel:SetText(GetString(SI_GAMEPAD_SMITHING_IMPROVEMENT_REAGENT_TITLE))

    local function SetupFunction(control, data, selected, selectedDuringRebuild, enabled)
        self:SetupSharedSlot(control, SLOT_TYPE_SMITHING_BOOSTER, listContainer, self.qualityList)
        local DO_NOT_SHOW_STACK_COUNT = false
        ZO_ItemSlot_SetAlwaysShowStackCount(control, DO_NOT_SHOW_STACK_COUNT)

        control.qualityIndex = data.qualityIndex
        control.qualityType = data.qualityType
        local EMPTY_STACK_COUNT = 0
        ZO_ItemSlot_SetupSlot(control, EMPTY_STACK_COUNT, data.icon, data.valid, not enabled)

        if selected then
            if data.extraInfo then
                listContainer.extraInfoLabel:SetText(data.extraInfo)
                listContainer.extraInfoLabel:SetHidden(false)
            else
                listContainer.extraInfoLabel:SetHidden(true) 
            end

            listContainer.selectedLabel:SetText(data.description)
            listContainer.selectedLabel:SetHidden(false)
        end
    end

    local function EqualityFunction(leftData, rightData)
        return leftData.name == rightData.name
    end

    local function OnHorizonalScrollListCleared(...)
        self:OnHorizonalScrollListCleared(...)
    end

    local BASE_NUM_ITEMS_IN_LIST = 5
    self.qualityList = scrollListClass:New(listContainer.listControl, listSlotTemplate, BASE_NUM_ITEMS_IN_LIST, SetupFunction, EqualityFunction, OnHorizonalScrollListShown, OnHorizonalScrollListCleared)
    local MIN_SCALE = 0.6
    local MAX_SCALE = 1.1
    self.qualityList:SetScaleExtents(MIN_SCALE, MAX_SCALE)
    self.qualityList:SetOnSelectedDataChangedCallback(function(selectedData, oldData, selectedDuringRebuild)
        self.itemSetPieceData:SetUpgradeFunctionalQuality(selectedData.quality)
        self:RefreshResultTooltip()
        self:RefreshCostSummary()
        --Do not try to narrate if a craft is in progress, as the screen will close once it's done
        if not self.isCraftInProgress then
            SCREEN_NARRATION_MANAGER:QueueFocus(self.focus)
        end
    end)

    ZO_CraftingUtils_ConnectHorizontalScrollListToCraftingProcess(self.qualityList)
end

function ZO_RetraitStation_Reconstruct_Gamepad:InitializeFragmentGroups()
    self.costFragmentGroup =
    {
        GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT,
        self.costFragment,
    }
end

function ZO_RetraitStation_Reconstruct_Gamepad:SetupSharedSlot(control, slotType, listContainer, list)
    ZO_InventorySlot_SetType(control, slotType)

    control.customTooltipAnchor = CustomTooltipAnchor
    ZO_InventorySlot_HandleInventoryUpdate(control)
end

function ZO_RetraitStation_Reconstruct_Gamepad:HideReconstructOptions()
    self.optionsModeHidden = true

    SCENE_MANAGER:RemoveFragmentGroup(self.costFragmentGroup)
    self.focus:Deactivate()
    self.optionsPanel:SetHidden(true)
    self.resultTooltip:SetHidden(true)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.reconstructKeybindStripDescriptor)
    self:RefreshHeader()
end

function ZO_RetraitStation_Reconstruct_Gamepad:RefreshItemData()
    self.itemIcon:SetTexture(self.itemSetPieceData:GetIcon())
    self.currentItemName = self.itemSetPieceData:GetFormattedColorizedName()
    self.itemName:SetText(self.currentItemName)
end

function ZO_RetraitStation_Reconstruct_Gamepad:RefreshTraitList()
    self.traitList:Clear()

    local allTraits = ZO_CraftingUtils_GetSmithingTraitItemInfo()
    local pieceId = self.itemSetPieceData:GetId()
    local pieceTraitCategory = self.itemSetPieceData:GetTraitCategory()
    -- Order matters:
    local craftingType = self.itemSetPieceData:GetTradeskillType()
    local isJewelry = craftingType == CRAFTING_TYPE_JEWELRYCRAFTING

    for _, traitData in ipairs(allTraits) do
        local traitCategory = GetItemTraitTypeCategory(traitData.type)
        local hasNoTrait = traitCategory == ITEM_TRAIT_TYPE_NONE

        if pieceTraitCategory == traitCategory or (isJewelry and hasNoTrait) then
            traitData.traitKnown = IsTraitKnownForItem(pieceId, traitData.type) or (isJewelry and hasNoTrait)
            if hasNoTrait then
                traitData.localizedName = GetString(SI_ITEM_RECONSTRUCTION_DEFAULT_TRAIT)
            else
                traitData.localizedName = GetString("SI_ITEMTRAITTYPE", traitData.type)
            end

            self.traitList:AddEntry(traitData)
        end
    end

    self.traitList:Commit()
end

function ZO_RetraitStation_Reconstruct_Gamepad:RefreshQualityList()
    self.qualityList:Clear()

    local minimumUpgradeQuality = self.itemSetPieceData:GetMinimumFunctionalQuality()
    if minimumUpgradeQuality == ITEM_FUNCTIONAL_QUALITY_LEGENDARY or self.itemSetPieceData:GetDisplayQuality() == ITEM_DISPLAY_QUALITY_MYTHIC_OVERRIDE then
        self.qualityListContainer:SetHidden(true)
        return
    end

    local craftingType = self.itemSetPieceData:GetTradeskillType()
    local sufficientPrecursorReagents = true
    for functionalQuality = minimumUpgradeQuality, ITEM_FUNCTIONAL_QUALITY_LEGENDARY do
        local reagentQualityColor = GetItemQualityColor(functionalQuality)
        local reagentName, reagentIcon, reagentsAvailable, reagentsRequired, reagentDescription
        if functionalQuality == minimumUpgradeQuality then
            reagentsAvailable = 0
            reagentsRequired = 0
            -- This name is only for comparison purposes and is not visible in the UI.
            reagentName = "Default Quality"
            reagentIcon = "EsoUI/Art/Crafting/crafting_smithing_noTrait.dds"
            reagentDescription = reagentQualityColor:Colorize(zo_strformat(SI_GAMEPAD_SMITHING_IMPROVEMENT_NO_REAGENT, GetString("SI_ITEMQUALITY", functionalQuality)))
        else
            local upgradeFromFunctionalQuality = functionalQuality - 1
            reagentName, reagentIcon, reagentsAvailable = GetSmithingImprovementItemInfo(craftingType, upgradeFromFunctionalQuality)
            reagentsRequired = GetSmithingGuaranteedImprovementItemAmount(craftingType, upgradeFromFunctionalQuality)
            reagentDescription = reagentQualityColor:Colorize(zo_strformat(SI_GAMEPAD_SMITHING_IMPROVEMENT_REAGENT_SELECTION, GetString("SI_ITEMQUALITY", functionalQuality), reagentsRequired, reagentName))
        end

        local valid = true
        local extraInfo = nil
        if not sufficientPrecursorReagents then
            extraInfo = GetString(SI_SMITHING_MATERIAL_REQUIRED_PREVIOUS_QUALITY)
            valid = false
        elseif reagentsAvailable < reagentsRequired then
            extraInfo = zo_strformat(SI_SMITHING_MATERIAL_REQUIRED, reagentsRequired, reagentName)
            valid = false
            sufficientPrecursorReagents = false
        end

        self.qualityList:AddEntry({
            valid = valid,
            quality = functionalQuality,
            quantity = reagentsRequired,
            available = reagentsAvailable,
            color = reagentQualityColor,
            icon = reagentIcon,
            name = reagentName,
            description = reagentDescription,
            extraInfo = extraInfo,
        })
    end

    self.qualityList:Commit()
    self.qualityListContainer:SetHidden(false)
end

function ZO_RetraitStation_Reconstruct_Gamepad:InitializeFocusItems()
    self.focus = ZO_GamepadFocus:New(self.optionsPanel)

    local function ActivateFocus(focus, data)
        focus:Activate()
        local ACTIVE = true
        self:UpdateBorderHighlight(focus, ACTIVE)
        SCREEN_NARRATION_MANAGER:QueueFocus(self.focus)
    end

    local function DeactivateFocus(focus, data)
        focus:Deactivate()
        local INACTIVE = false
        self:UpdateBorderHighlight(focus, INACTIVE)
    end

    local function UpgradeVisibility()
        local minimumUpgradeQuality = self.itemSetPieceData:GetMinimumFunctionalQuality()
        return minimumUpgradeQuality < ITEM_FUNCTIONAL_QUALITY_LEGENDARY and self.itemSetPieceData:GetDisplayQuality() ~= ITEM_DISPLAY_QUALITY_MYTHIC_OVERRIDE
    end

    local function GetHeaderNarrationText()
        return { ZO_GamepadGenericHeader_GetNarrationText(self.header, self.headerData), SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.currentItemName) }
    end

    self.focusEntryData =
    {
        -- Trait selection
        {
            activate = ActivateFocus,
            deactivate = DeactivateFocus,
            control = self.traitList,
            narrationText = function()
                local narrations = {}
                local data = self.traitList.selectedData
                --Generate the narration for the selected value
                table.insert(narrations, ZO_FormatSpinnerNarrationText(GetString(SI_SMITHING_HEADER_TRAIT), data.localizedName))
                local traitCategory = GetItemTraitTypeCategory(data.type)
                --Only narrate the extra info if the trait type is not none
                if traitCategory ~= ITEM_TRAIT_TYPE_NONE then
                    if not data.traitKnown then
                        table.insert(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_SMITHING_TRAIT_MUST_BE_RESEARCHED)))
                    end
                end
                return narrations
            end,
            additionalInputNarrationFunction = function()
                local narrationFunction = self.traitList:GetAdditionalInputNarrationFunction()
                return narrationFunction()
            end,
            headerNarrationFunction = GetHeaderNarrationText,
        },
        -- Upgrade selection
        {
            activate = ActivateFocus,
            deactivate = DeactivateFocus,
            control = self.qualityList,
            visible = UpgradeVisibility,
            narrationText = function()
                local narrations = {}
                local data = self.qualityList.selectedData
                --Generate the narration for the selected value
                table.insert(narrations, ZO_FormatSpinnerNarrationText(GetString(SI_GAMEPAD_SMITHING_IMPROVEMENT_REAGENT_TITLE), data.description))
                --Generate the narration for any extra info
                table.insert(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(data.extraInfo))
                return narrations
            end,
            additionalInputNarrationFunction = function()
                local narrationFunction = self.qualityList:GetAdditionalInputNarrationFunction()
                return narrationFunction()
            end,
            headerNarrationFunction = GetHeaderNarrationText,
        },
    }

    --Re-narrate the current focus upon closing dialogs
    CALLBACK_MANAGER:RegisterCallback("AllDialogsHidden", function()
        --Do not try to narrate if a craft is in progress, as the screen will close once it's done
        if self.focus:IsActive() and not self.isCraftInProgress then
            local NARRATE_HEADER = true
            SCREEN_NARRATION_MANAGER:QueueFocus(self.focus, NARRATE_HEADER)
        end
    end)

    self:RefreshFocusItems()
end

function ZO_RetraitStation_Reconstruct_Gamepad:RefreshFocusItems(focusIndex)
    self.focus:RemoveAllEntries()

    for _, focusEntry in ipairs(self.focusEntryData) do
        if focusEntry.visible ~= false and (type(focusEntry.visible) ~= "function" or focusEntry.visible()) then
            self.focus:AddEntry(focusEntry)
        end
    end

    local FIRST_INDEX = 1
    self.focus:SetFocusByIndex(focusIndex or FIRST_INDEX)
end

function ZO_RetraitStation_Reconstruct_Gamepad:SetupCostLine(control, icon, name, quantity, insufficientQuantity)
    control:GetNamedChild("Label"):SetText(name)

    -- Order matters:
    local iconTexture = control:GetNamedChild("Icon")
    iconTexture:SetTexture(icon)
    local stackCountLabel = iconTexture:GetNamedChild("StackCount")
    stackCountLabel:SetText(quantity)

    if insufficientQuantity then
        stackCountLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
    else
        stackCountLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
    end

    control:SetHidden(false)
end

function ZO_RetraitStation_Reconstruct_Gamepad:RefreshCostSummary()
    local currencyOptions, materialCosts = self.itemSetPieceData:GetCostInfo()
    local summaryContainer = self.costContainer:GetNamedChild("Summary")

    -- TODO: Add support for multiple currencies as future proofing.
    local currencyOption = currencyOptions[1]
    local insufficientCurrency = currencyOption.currencyRequired > currencyOption.currencyAvailable
    self:SetupCostLine(summaryContainer:GetNamedChild("Currency"), currencyOption.currencyIcon, currencyOption.currencyName, currencyOption.currencyRequired, insufficientCurrency)

    if #materialCosts == 0 then
        self.materialContainer:SetHidden(true)
    else
        self.materialPool:ReleaseAllObjects()

        local previousControl
        for _, materialCost in ipairs(materialCosts) do
            local materialControl = self.materialPool:AcquireObject()
            self:SetupCostLine(materialControl, materialCost.reagentIcon, materialCost.reagentItemLink, materialCost.reagentsRequired, materialCost.reagentsRequired > materialCost.reagentsAvailable)

            -- Order matters:
            if previousControl then
                materialControl:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT)
                materialControl:SetAnchor(TOPRIGHT, previousControl, BOTTOMRIGHT)
            else
                materialControl:SetAnchor(TOPLEFT, self.materialContainer)
                materialControl:SetAnchor(TOPRIGHT, self.materialContainer)
            end
            previousControl = materialControl
        end
        
        self.materialContainer:SetHidden(false)
    end
end

function ZO_RetraitStation_Reconstruct_Gamepad:RefreshOptionsMode()
    self:RefreshHeader()
    self:RefreshItemData()
    self:RefreshTraitList()
    self:RefreshQualityList()
    self:RefreshFocusItems()
    self:RefreshCostSummary()
    self:RefreshResultTooltip()
end

function ZO_RetraitStation_Reconstruct_Gamepad:UpdateBorderHighlight(focus, active)
    local focusControlParent = focus:GetControl():GetParent()
    focusControlParent.inactiveBG:SetHidden(active)
    focusControlParent.activeBG:SetHidden(not active)
end

function ZO_RetraitStation_Reconstruct_Gamepad:RefreshResultTooltip()
    self.resultTooltip.tip:ClearLines()

    if self.itemSetPieceData and self:IsOptionsModeShowing() then
        local SHOW_TRAIT = false
        self.resultTooltip.tip:LayoutItemSetCollectionPieceLink(self.itemSetPieceData:GetItemLink(), SHOW_TRAIT)
        self.resultTooltip.icon:SetTexture(self.itemSetPieceData:GetIcon())
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.reconstructKeybindStripDescriptor)
end

function ZO_RetraitStation_Reconstruct_Gamepad:RequestReconstruction()
    local pieceId = self.itemSetPieceData:GetId()
    local traitType = self.itemSetPieceData:GetOverrideTraitType()
    local quality = self.itemSetPieceData:GetUpgradeFunctionalQuality() or self.itemSetPieceData:GetMinimumFunctionalQuality()
    local currencyType = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetReconstructionCurrencyOptionType(1)

    return RequestItemReconstruction(pieceId, traitType, quality, currencyType)
end

function ZO_RetraitStation_Reconstruct_Gamepad:IsReconstructionEnabled()
    if self.isCraftInProgress then
        return false
    end

    if not self.isTraitValid then
        return false
    end

    local currencyCosts, materialCosts = self.itemSetPieceData:GetCostInfo()
    for _, materialCost in ipairs(materialCosts) do
        if materialCost.reagentsRequired > materialCost.reagentsAvailable then
            return false
        end
    end

    for _, currencyCost in pairs(currencyCosts) do
        if currencyCost.currencyRequired <= currencyCost.currencyAvailable then
            return true
        end
    end

    return false
end

function ZO_RetraitStation_Reconstruct_Gamepad:ShowItemSetsBook()
    self:HideReconstructOptions()
    self:ShowListDescriptor(self.subcategoryListDescriptor)
    self:UpdateGridPanelVisibility()
    self:EnterGridList()
end

-- Begin ZO_ItemSetsBook_Gamepad_Base Overrides --

function ZO_RetraitStation_Reconstruct_Gamepad:InitializeKeybindStripDescriptors()
    ZO_ItemSetsBook_Gamepad_Base.InitializeKeybindStripDescriptors(self)

    self.reconstructKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Perform reconstruction
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = GetString(SI_RETRAIT_STATION_PERFORM_RECONSTRUCT),
            callback = function()
                ZO_Dialogs_ShowGamepadDialog("GAMEPAD_CONFIRM_ITEM_RECONSTRUCTION", {itemSetPieceData = self.itemSetPieceData})
            end,
            visible = function()
                return self:IsOptionsModeShowing()
            end,
            enabled = function()
                return self:IsReconstructionEnabled()
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.reconstructKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        self:ShowItemSetsBook()
    end)

    ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(self.reconstructKeybindStripDescriptor)
end

-- End ZO_ItemSetsBook_Gamepad_Base Overrides --

-- Begin ZO_ItemSetsBook_Shared Overrides --

function ZO_RetraitStation_Reconstruct_Gamepad:RefreshHeader()
    if self:IsOptionsModeShowing() then
        self.headerData.titleText = GetString(SI_RETRAIT_STATION_RECONSTRUCT_MODE)
        ZO_GamepadGenericHeader_RefreshData(self.header, self.headerData)
    else
        ZO_ItemSetsBook_Gamepad_Base.RefreshHeader(self)
    end
end

function ZO_RetraitStation_Reconstruct_Gamepad:GetSceneName()
    return "reconstruct_gamepad"
end

function ZO_RetraitStation_Reconstruct_Gamepad:IsReconstructing()
    return true
end

function ZO_RetraitStation_Reconstruct_Gamepad:IsOptionsModeShowing()
    return not self.optionsModeHidden
end

function ZO_RetraitStation_Reconstruct_Gamepad:CanReconstruct()
    local selectedData = self.gridListPanelList:GetSelectedData()
    if selectedData and not selectedData.isEmptyCell then
        return selectedData:IsUnlocked()
    end
    return false
end

function ZO_RetraitStation_Reconstruct_Gamepad:ShowReconstructOptions()
    if self:CanReconstruct() then
        self.optionsModeHidden = false

        local selectedData = self.gridListPanelList:GetSelectedData()
        self.itemSetPieceData:Copy(selectedData)
        self.isTraitValid = false
        self:ExitGridList()
        self:HideCurrentListDescriptor()

        -- Order matters:
        self:RefreshOptionsMode()
        self:UpdateGridPanelVisibility()

        self.focus:Activate()
        self.optionsPanel:SetHidden(false)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.reconstructKeybindStripDescriptor)

        GAMEPAD_CRAFTING_RESULTS:SetCraftingTooltip(self.resultTooltip)
        -- Reconstruction operations cannot fail for any reason other than pre-validation checks, so the failure argument here is irrelevant.
        GAMEPAD_CRAFTING_RESULTS:SetTooltipAnimationSounds(SOUNDS.RETRAITING_RETRAIT_TOOLTIP_GLOW_SUCCESS, SOUNDS.BLACKSMITH_IMPROVE_TOOLTIP_GLOW_FAIL)
        self.resultTooltip:SetHidden(false)

        SCENE_MANAGER:AddFragmentGroup(self.costFragmentGroup)
        local NARRATE_HEADER = true
        SCREEN_NARRATION_MANAGER:QueueFocus(self.focus, NARRATE_HEADER)
    end
end

-- End ZO_ItemSetsBook_Shared Overrides --

-- Begin ZO_Gamepad_ParametricList_Screen Overrides --

function ZO_RetraitStation_Reconstruct_Gamepad:OnDeferredInitialize()
    ZO_Gamepad_ParametricList_Screen.OnDeferredInitialize(self)

    local LIST_CLASS = ZO_SmithingHorizontalScrollList_Gamepad
    local SLOT_TEMPLATE = "ZO_GamepadSmithingListSlot"
    local VALIDATION_FONT = "ZoFontGamepadCondensed34"
    self:InitializeTraitList(LIST_CLASS, SLOT_TEMPLATE, VALIDATION_FONT)
    self:InitializeQualityList(LIST_CLASS, SLOT_TEMPLATE, VALIDATION_FONT)
    self:InitializeFocusItems()
    self:InitializeFragmentGroups()
end

-- End ZO_Gamepad_ParametricList_Screen Overrides --