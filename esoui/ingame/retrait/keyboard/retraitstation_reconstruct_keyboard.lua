ZO_RECONSTRUCTION_ITEM_NAME_OFFSET_X = ZO_ITEM_SET_COLLECTION_PIECE_TILE_KEYBOARD_ICON_DIMENSIONS * 0.5

ZO_RECONSTRUCTION_IMPROVEMENT_BAR_TEXTURES =
{
    [ITEM_FUNCTIONAL_QUALITY_NORMAL] = "EsoUI/Art/Crafting/reconstruction_temper_normal.dds",
    [ITEM_FUNCTIONAL_QUALITY_MAGIC] = "EsoUI/Art/Crafting/reconstruction_temper_fine.dds",
    [ITEM_FUNCTIONAL_QUALITY_ARCANE] = "EsoUI/Art/Crafting/reconstruction_temper_superior.dds",
    [ITEM_FUNCTIONAL_QUALITY_ARTIFACT] = "EsoUI/Art/Crafting/reconstruction_temper_epic.dds",
    [ITEM_FUNCTIONAL_QUALITY_LEGENDARY] = "EsoUI/Art/Crafting/reconstruction_temper_legendary.dds",
}

ZO_RECONSTRUCTION_DISABLED_IMPROVEMENT_BAR_TEXTURES =
{
    [ITEM_FUNCTIONAL_QUALITY_NORMAL] = "EsoUI/Art/Crafting/reconstruction_temperDisabled_normal.dds",
    [ITEM_FUNCTIONAL_QUALITY_MAGIC] = "EsoUI/Art/Crafting/reconstruction_temperDisabled_fine.dds",
    [ITEM_FUNCTIONAL_QUALITY_ARCANE] = "EsoUI/Art/Crafting/reconstruction_temperDisabled_superior.dds",
    [ITEM_FUNCTIONAL_QUALITY_ARTIFACT] = "EsoUI/Art/Crafting/reconstruction_temperDisabled_epic.dds",
    [ITEM_FUNCTIONAL_QUALITY_LEGENDARY] = "EsoUI/Art/Crafting/reconstruction_temperDisabled_legendary.dds",
}

local NUM_RECONSTRUCT_COST_ENTRIES = 5

ZO_RetraitStation_Reconstruct_Keyboard = ZO_InitializingObject:Subclass()

function ZO_RetraitStation_Reconstruct_Keyboard:Initialize(control, owner)
    self.control = control
    self.owner = owner
    SYSTEMS:RegisterKeyboardObject("reconstruct", self)

    self.fragment = ZO_SimpleSceneFragment:New(control)
    RETRAIT_STATION_RECONSTRUCT_FRAGMENT = self.fragment
    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_HIDING then
            self:OnHiding()
        end
    end)

    self.isCraftInProgress = false
    self.isCurrencyValid = false
    self.isQualityValid = false
    self.isTraitValid = false
    self.itemSetPieceData = ZO_ItemSetCollectionReconstructionPieceData:New()
    self:InitializeOptionsPanel()
    self:InitializeTraitList()
    self:InitializeImprovementList()
    self:InitializeCostList()
    self:InitializeKeybindStripDescriptors()
    self:InitializeEvents()

    self.previewTooltip = self.reconstructOptions:GetNamedChild("PreviewTooltip")
end

function ZO_RetraitStation_Reconstruct_Keyboard:InitializeEvents()
    ZO_RETRAIT_STATION_MANAGER:RegisterCallback("OnRetraitDirtyEvent", function(...) self:HandleDirtyEvent(...) end)

    local function OnCraftStarted()
        self.isCraftInProgress = true
    end

    local function OnCraftStopped()
        self.isCraftInProgress = false

        if self:IsOptionsModeShowing() then
            self:ShowSelectionMode()
        end
    end

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", OnCraftStarted)
    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", OnCraftStopped)
end

function ZO_RetraitStation_Reconstruct_Keyboard:InitializeOptionsPanel()
    self.reconstructOptions = self.control:GetNamedChild("Options")
    self.reconstructItemIconTexture = self.reconstructOptions:GetNamedChild("HeadingItemIcon")
    self.reconstructItemNameLabel = self.reconstructOptions:GetNamedChild("HeadingItemName")
    self.reconstructOptionsFragment = ZO_SimpleSceneFragment:New(self.reconstructOptions)

    self.reconstructBackLabel = self.reconstructOptions:GetNamedChild("BackContainerBackLabel")
    self.reconstructBackLabel.enabled = true
    self.reconstructBackLabel.allowIconScaling = false
    self.reconstructBackLabel.OnMouseUp = function()
        self:ShowSelectionMode()
    end
end

function ZO_RetraitStation_Reconstruct_Keyboard:InitializeTraitList()
    local listContainer = self.reconstructOptions:GetNamedChild("TraitList")

    local function SetupFunction(control, data, selected, selectedDuringRebuild, enabled)
        if not self:IsOptionsModeShowing() then
            return
        end

        self:SetupSharedSlot(control, SLOT_TYPE_SMITHING_TRAIT, listContainer, self.traitList)
        ZO_ItemSlot_SetAlwaysShowStackCount(control, false)

        local NO_STACK_COUNT = 0
        ZO_ItemSlot_SetupSlot(control, NO_STACK_COUNT, data.icon, data.traitKnown, not enabled)

        if selected then
            local isJewelry = self.itemSetPieceData:GetTradeskillType() == CRAFTING_TYPE_JEWELRYCRAFTING
            local extraInfoLabel = listContainer.extraInfoLabel
            
            if data.traitKnown or (isJewelry and data.traitType == ITEM_TRAIT_TYPE_NONE) then
                extraInfoLabel:SetHidden(true)
                self.isTraitUsable = USABILITY_TYPE_USABLE
            else
                extraInfoLabel:SetHidden(false)
                self.isTraitUsable = USABILITY_TYPE_VALID_BUT_MISSING_REQUIREMENT
            end

            listContainer.selectedLabel:SetText(data.name)
        end
    end

    local function EqualityFunction(leftData, rightData)
        return leftData.type == rightData.type and leftData.name == rightData.name
    end

    local function OnHorizonalScrollListShown(...)
        self:OnHorizonalScrollListShown(...)
    end

    local function OnHorizonalScrollListCleared(...)
        self:OnHorizonalScrollListCleared(...)
    end

    local BASE_NUM_ITEMS_IN_LIST = 5
    self.traitList = ZO_HorizontalScrollList:New(listContainer.listControl, "ZO_SmithingListSlot", BASE_NUM_ITEMS_IN_LIST, SetupFunction, EqualityFunction, OnHorizonalScrollListShown, OnHorizonalScrollListCleared)

    local MIN_SCALE = 0.6
    local MAX_SCALE = 1.1
    self.traitList:SetScaleExtents(MIN_SCALE, MAX_SCALE)

    self.traitList:SetOnSelectedDataChangedCallback(function(selectedData, oldData, selectedDuringRebuild)
        self:SetSelectedTraitType(selectedData.traitType, selectedData.traitKnown)
    end)

    ZO_CraftingUtils_ConnectHorizontalScrollListToCraftingProcess(self.traitList)
end

function ZO_RetraitStation_Reconstruct_Keyboard:InitializeImprovementList()
    self.reconstructImprovement = self.reconstructOptions:GetNamedChild("ImprovementList")
    self.reconstructImprovementTierControls = self.reconstructImprovement:GetNamedChild("Tiers")
    self.reconstructImprovementTiers = {}

    for quality = ITEM_FUNCTIONAL_QUALITY_NORMAL, ITEM_FUNCTIONAL_QUALITY_LEGENDARY do
        local qualityTextureName = string.format("QualityTexture%d", quality)

        local qualityTexture = self.reconstructImprovementTierControls:GetNamedChild(qualityTextureName)
        qualityTexture:SetHandler("OnMouseDown", function(...) self:OnImprovementQualityMouseDown(...) end)
        qualityTexture:SetHandler("OnMouseEnter", function(...) self:OnImprovementQualityMouseEnter(...) end)
        qualityTexture:SetHandler("OnMouseExit", function(...) self:OnImprovementQualityMouseExit(...) end)

        local mouseOverGlowTexture = qualityTexture:GetNamedChild("MouseOverGlowTexture")
        mouseOverGlowTexture.alphaAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ReconstructItemQualityAlphaAnimation", mouseOverGlowTexture)

        local selectionGlowTexture = qualityTexture:GetNamedChild("SelectionGlowTexture")
        selectionGlowTexture.alphaAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ReconstructItemQualityAlphaAnimation", selectionGlowTexture)

        local qualityLabel = qualityTexture:GetNamedChild("QualityLabel")
        qualityLabel:SetText(GetString("SI_ITEMQUALITY", quality))

        local reagentTexture = qualityTexture:GetNamedChild("ReagentTexture")
        reagentTexture.scaleAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ReconstructItemQualityScaleAnimation", reagentTexture)

        local quantityLabel = reagentTexture:GetNamedChild("QuantityLabel")

        local tierData =
        {
            isDisabled = false,
            isMouseOver = false,
            isSelected = false,
            mouseOverGlowTexture = mouseOverGlowTexture,
            quality = quality,
            qualityLabel = qualityLabel,
            qualityLabelColors = {ZO_DEFAULT_TEXT, GetDimItemQualityColor(quality), GetItemQualityColor(quality)},
            qualityTexture = qualityTexture,
            quantityLabel = quantityLabel,
            reagentTexture = reagentTexture,
            selectionGlowTexture = selectionGlowTexture,
        }
        self.reconstructImprovementTiers[quality] = tierData
        qualityTexture.tierData = tierData
    end

    local function RefreshState()
        if self:IsOptionsModeShowing() then
            self:RefreshImprovementList()
        end
    end

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", RefreshState)
    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", RefreshState)
end

function ZO_RetraitStation_Reconstruct_Keyboard:InitializeCostList()
    self.costContainer = self.reconstructOptions:GetNamedChild("CostListContainer")
    self.costEntries = { }

    local currentRow
    for entryIndex = 1, NUM_RECONSTRUCT_COST_ENTRIES do
        local isNewRow = entryIndex % 2 == 1
        if isNewRow then
            local rowName = string.format("%sRow%d", self.costContainer:GetName(), math.ceil(entryIndex / 2))
            local newRow = WINDOW_MANAGER:CreateControl(rowName, self.costContainer, CT_CONTROL)
            newRow:SetResizeToFitDescendents(true)

            if currentRow then
                newRow:SetAnchor(TOPLEFT, currentRow, BOTTOMLEFT, 0, 15)
                newRow:SetAnchor(TOPRIGHT, currentRow, BOTTOMRIGHT, 0, 15)
            else
                newRow:SetAnchor(TOPLEFT, self.costContainer)
                newRow:SetAnchor(TOPRIGHT, self.costContainer)
            end
            currentRow = newRow
        end

        local newEntry = WINDOW_MANAGER:CreateControlFromVirtual(currentRow:GetName(), currentRow, "ZO_ReconstructionCostLineItem", entryIndex)
        table.insert(self.costEntries, newEntry)
        if isNewRow then
            newEntry:SetAnchor(TOPLEFT)
            newEntry:SetAnchor(TOPRIGHT, currentRow, TOP)
        else
            newEntry:SetAnchor(TOPLEFT, currentRow, TOP, 10)
            newEntry:SetAnchor(TOPRIGHT)
        end
    end
end

function ZO_RetraitStation_Reconstruct_Keyboard:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Perform craft
        {
            name = GetString(SI_RETRAIT_STATION_PERFORM_RECONSTRUCT),

            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                ZO_Dialogs_ShowDialog("CONFIRM_ITEM_RECONSTRUCTION", self.itemSetPieceData)
            end,

            visible = function()
                return self:IsOptionsModeShowing()
            end,

            enabled = function()
                return self:IsReconstructionEnabled()
            end
        },

        -- Exit or Back
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,

            name = function()
                if self:IsOptionsModeShowing() then
                    return GetString(SI_ITEM_RECONSTRUCTION_BACK)
                else
                    return GetString(SI_ITEM_RECONSTRUCTION_EXIT)
                end
            end,

            keybind = "UI_SHORTCUT_EXIT",

            callback = function()
                if self:IsOptionsModeShowing() then
                    self:ShowSelectionMode()
                else
                    SCENE_MANAGER:ShowBaseScene()
                end
            end,
        },
    }

    ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(self.keybindStripDescriptor)
end

function ZO_RetraitStation_Reconstruct_Keyboard:GetKeybindDescriptor()
    return self.keybindStripDescriptor
end

function ZO_RetraitStation_Reconstruct_Keyboard:UpdateKeybinds()
    self.owner:UpdateKeybinds()
end

function ZO_RetraitStation_Reconstruct_Keyboard:IsShowing()
    return self.fragment:IsShowing()
end

function ZO_RetraitStation_Reconstruct_Keyboard:UpdateResultTooltip()
    self.previewTooltip:ClearLines()
    local SHOW_TRAIT = false
    self.previewTooltip:SetItemSetCollectionPieceLink(self.itemSetPieceData:GetItemLink(), SHOW_TRAIT)
    self:UpdateKeybinds()
end

function ZO_RetraitStation_Reconstruct_Keyboard:SelectItemSetPieceData(data)
    self.itemSetPieceData:Copy(data)
    self:SetSelectedQuality(self:GetMinimumQuality())
    self:ShowOptionsMode()
end

function ZO_RetraitStation_Reconstruct_Keyboard:HandleDirtyEvent()
    self.dirty = true
    if self:IsOptionsModeShowing() then
        self:Refresh()
    end
end

function ZO_RetraitStation_Reconstruct_Keyboard:HideAllModes()
    self.previewTooltip:SetHidden(true)
    SCENE_MANAGER:RemoveFragment(TREE_UNDERLAY_FRAGMENT)
    SCENE_MANAGER:RemoveFragment(self.reconstructOptionsFragment)
    SCENE_MANAGER:RemoveFragment(ITEM_SETS_BOOK_FRAGMENT)
end

function ZO_RetraitStation_Reconstruct_Keyboard:ShowSelectionMode()
    self:HideAllModes()
    SCENE_MANAGER:AddFragment(TREE_UNDERLAY_FRAGMENT)
    SCENE_MANAGER:AddFragment(ITEM_SETS_BOOK_FRAGMENT)

    self:HandleDirtyEvent()
    self:UpdateKeybinds()
end

function ZO_RetraitStation_Reconstruct_Keyboard:ShowOptionsMode()
    self:HideAllModes()
    self:ResetOptions()
    SCENE_MANAGER:AddFragment(TREE_UNDERLAY_FRAGMENT)
    SCENE_MANAGER:AddFragment(self.reconstructOptionsFragment)
    self:InitializeCraftingResults()

    local SKIP_ANIMATIONS = true
    self:Refresh(SKIP_ANIMATIONS)
    self:RefreshBaseItem()
    self:UpdateKeybinds()
end

function ZO_RetraitStation_Reconstruct_Keyboard:IsOptionsModeShowing()
    return self.reconstructOptionsFragment:IsShowing()
end 

function ZO_RetraitStation_Reconstruct_Keyboard:IsSelectionModeShowing()
    return self:IsShowing() and ITEM_SETS_BOOK_FRAGMENT:IsShowing()
end

function ZO_RetraitStation_Reconstruct_Keyboard:IsReconstructionEnabled()
    return not self.isCraftInProgress and self.isCurrencyValid and self.isQualityValid and self.isTraitValid
end

function ZO_RetraitStation_Reconstruct_Keyboard:ResetOptions()
    for _, tierData in pairs(self.reconstructImprovementTiers) do
        tierData.isDisabled = false
        tierData.isMouseOver = false
        tierData.isSelected = false
    end
end

function ZO_RetraitStation_Reconstruct_Keyboard:InitializeCraftingResults()
    CRAFTING_RESULTS:SetCraftingTooltip(self.previewTooltip)
    -- Reconstruction operations cannot fail for any reason other than pre-validation checks, so the failure argument here is irrelevant.
    CRAFTING_RESULTS:SetTooltipAnimationSounds(SOUNDS.RETRAITING_RETRAIT_TOOLTIP_GLOW_SUCCESS, SOUNDS.BLACKSMITH_IMPROVE_TOOLTIP_GLOW_FAIL)
    self.previewTooltip:SetHidden(false)
end

function ZO_RetraitStation_Reconstruct_Keyboard:RequestReconstruction()
    local pieceId = self.itemSetPieceData:GetId()
    local traitType = self.itemSetPieceData:GetOverrideTraitType()
    local quality = self:GetSelectedQuality()
    local currencyType = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetReconstructionCurrencyOptionType(1)

    return RequestItemReconstruction(pieceId, traitType, quality, currencyType)
end

function ZO_RetraitStation_Reconstruct_Keyboard:SetSelectedTraitType(traitType, traitKnown)
    self.isTraitValid = traitKnown
    self.itemSetPieceData:SetOverrideTraitType(traitType)
    self:UpdateResultTooltip()
end

function ZO_RetraitStation_Reconstruct_Keyboard:GetMinimumQuality()
    return self.itemSetPieceData:GetMinimumFunctionalQuality()
end

function ZO_RetraitStation_Reconstruct_Keyboard:GetSelectedQuality()
    return self.itemSetPieceData:GetUpgradeFunctionalQuality() or self:GetMinimumQuality()
end

function ZO_RetraitStation_Reconstruct_Keyboard:SetSelectedQuality(quality)
    local functionalQuality = math.max(quality, self:GetMinimumQuality())
    self.itemSetPieceData:SetUpgradeFunctionalQuality(functionalQuality)
end

function ZO_RetraitStation_Reconstruct_Keyboard:ClearSelectedQuality()
    self:SetSelectedQuality(self:GetMinimumQuality())
end

function ZO_RetraitStation_Reconstruct_Keyboard:GetItemSetPieceTraits()
    local pieceId = self.itemSetPieceData:GetId()
    local pieceTraitType = self.itemSetPieceData:GetTraitCategory()
    local pieceTraits = {}
    local allTraits = ZO_CraftingUtils_GetSmithingTraitItemInfo()

    for _, traitData in ipairs(allTraits) do
        local traitType = GetItemTraitTypeCategory(traitData.type)
        local hasNoTrait = traitType == ITEM_TRAIT_TYPE_NONE

        if pieceTraitType == traitType or hasNoTrait then
            traitData.traitType = traitType
            traitData.traitKnown = IsTraitKnownForItem(pieceId, traitData.type) or hasNoTrait
            table.insert(pieceTraits, traitData)
        end
    end

    return pieceTraits
end

function ZO_RetraitStation_Reconstruct_Keyboard:SetupSharedSlot(control, slotType, listContainer, list)
    ZO_InventorySlot_SetType(control, slotType)
end

function ZO_RetraitStation_Reconstruct_Keyboard:RefreshBaseItem()
    self.reconstructItemIconTexture:SetTexture(self.itemSetPieceData:GetIcon())
    local qualityColor
    if self.itemSetPieceData:GetDisplayQuality() == ITEM_DISPLAY_QUALITY_MYTHIC_OVERRIDE then
        qualityColor = GetItemQualityColor(ITEM_DISPLAY_QUALITY_MYTHIC_OVERRIDE)
    else
        qualityColor = GetItemQualityColor(self:GetSelectedQuality())
    end
    self.reconstructItemNameLabel:SetText(qualityColor:Colorize(self.itemSetPieceData:GetFormattedName()))
end

function ZO_RetraitStation_Reconstruct_Keyboard:Refresh(skipAnimations)
    self:RefreshTraitList()
    self:RefreshImprovementList(skipAnimations)
    self:RefreshCostList()
    self:UpdateResultTooltip()
    self.dirty = false
end

function ZO_RetraitStation_Reconstruct_Keyboard:RefreshTraitList()
    local traitListData = self:GetItemSetPieceTraits()
    if not traitListData then
        return
    end

    self.traitList:Clear()

    local isJewelry = self.itemSetPieceData:GetTradeskillType() == CRAFTING_TYPE_JEWELRYCRAFTING
    for _, traitData in ipairs(traitListData) do
        if isJewelry or traitData.type ~= ITEM_TRAIT_TYPE_NONE then
            local traitName
            if traitData.type == ITEM_TRAIT_TYPE_NONE then
                traitName = GetString(SI_ITEM_RECONSTRUCTION_DEFAULT_TRAIT)
            else
                traitName = GetString("SI_ITEMTRAITTYPE", traitData.type)
            end

            local entryData =
            {
                traitIndex = traitData.index,
                traitType = traitData.type,
                traitKnown = traitData.traitKnown,
                icon = traitData.icon,
                name = traitName,
            }
            self.traitList:AddEntry(entryData)
        end
    end

    self.traitList:Commit()
end

function ZO_RetraitStation_Reconstruct_Keyboard:RefreshImprovementList(skipAnimations)
    local selectedQuality = self:GetSelectedQuality()
    self:SetSelectedQuality(selectedQuality)
    local minimumQuality = self:GetMinimumQuality()
    local tradeskillType = self.itemSetPieceData:GetTradeskillType()
    local OVERRIDE_QUALITY = ITEM_FUNCTIONAL_QUALITY_LEGENDARY
    local currencyOptions, materialCosts = self.itemSetPieceData:GetCostInfo(OVERRIDE_QUALITY)
    local isCrafting = ZO_CraftingUtils_IsPerformingCraftProcess()

    for quality = ITEM_FUNCTIONAL_QUALITY_NORMAL, ITEM_FUNCTIONAL_QUALITY_LEGENDARY do
        local tierData = self.reconstructImprovementTiers[quality]
        tierData.isDisabled = not isCrafting and (quality < minimumQuality or self.itemSetPieceData:GetDisplayQuality() == ITEM_DISPLAY_QUALITY_MYTHIC_OVERRIDE)
        tierData.isSelected = not tierData.isDisabled and quality <= selectedQuality

        if quality ~= ITEM_FUNCTIONAL_QUALITY_NORMAL then
            local reagentName, reagentIcon, reagentStack = GetSmithingImprovementItemInfo(tradeskillType, quality - 1)
            tierData.reagentTexture:SetTexture(reagentIcon)
            tierData.reagentTexture:SetHidden(false)
            local disableReagent = tierData.isDisabled or quality == minimumQuality

            if disableReagent then
                tierData.reagentTexture:SetDesaturation(1)
            else
                tierData.reagentTexture:SetDesaturation(0)
            end

            if disableReagent or tierData.isSelected or tierData.isMouseOver then
                tierData.reagentTexture:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_WEIGHT_RGB, 1)
            else
                tierData.reagentTexture:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_WEIGHT_RGB, 0.65)
            end

            local scaleAnimation = tierData.reagentTexture.scaleAnimation
            if not disableReagent and (tierData.isMouseOver or tierData.isSelected) then
                if skipAnimations == true then
                    scaleAnimation:PlayInstantlyToEnd()
                else
                    scaleAnimation:PlayForward()
                end
            else
                if skipAnimations == true then
                    scaleAnimation:PlayInstantlyToStart()
                else
                    scaleAnimation:PlayBackward()
                end
            end
        end

        if tierData.isDisabled then
            tierData.reagentLink = nil
            tierData.quantityLabel:SetHidden(true)
            tierData.qualityLabel:SetColor(tierData.qualityLabelColors[1]:UnpackRGBA())
            tierData.qualityTexture:SetTexture(ZO_RECONSTRUCTION_DISABLED_IMPROVEMENT_BAR_TEXTURES[quality])
            tierData.qualityTexture:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_WEIGHT_RGB, 1)
            tierData.qualityTexture:SetDesaturation(1)
            tierData.mouseOverGlowTexture.alphaAnimation:PlayInstantlyToStart()
            tierData.selectionGlowTexture.alphaAnimation:PlayInstantlyToStart()
        else
            local materialCost
            for _, cost in ipairs(materialCosts) do
                if cost.toFunctionalQuality == quality then
                    materialCost = cost
                    break
                end
            end

            local reagentsRequired = ""
            local reagentLink
            if materialCost then
                reagentLink = materialCost.reagentItemLink
                reagentsRequired = materialCost.reagentsRequired
                if materialCost.reagentsRequired > materialCost.reagentsAvailable then
                    reagentsRequired = ZO_ERROR_COLOR:Colorize(reagentsRequired)
                end
            end
            tierData.reagentLink = reagentLink
            tierData.quantityLabel:SetText(reagentsRequired)
            tierData.quantityLabel:SetHidden(false)

            tierData.qualityTexture:SetTexture(ZO_RECONSTRUCTION_IMPROVEMENT_BAR_TEXTURES[quality])
            tierData.qualityTexture:SetDesaturation(0)

            local mouseOverAnimation = tierData.mouseOverGlowTexture.alphaAnimation
            if tierData.isMouseOver then
                if skipAnimations == true then
                    mouseOverAnimation:PlayInstantlyToEnd()
                else
                    mouseOverAnimation:PlayForward()
                end
            else
                if skipAnimations == true then
                    mouseOverAnimation:PlayInstantlyToStart()
                else
                    mouseOverAnimation:PlayBackward()
                end
            end

            local selectionAnimation = tierData.selectionGlowTexture.alphaAnimation
            if tierData.isSelected then
                if skipAnimations == true then
                    selectionAnimation:PlayInstantlyToEnd()
                else
                    selectionAnimation:PlayForward()
                end
            else
                if skipAnimations == true then
                    selectionAnimation:PlayInstantlyToStart()
                else
                    selectionAnimation:PlayBackward()
                end
            end

            if tierData.isMouseOver or tierData.isSelected then
                tierData.qualityLabel:SetColor(tierData.qualityLabelColors[3]:UnpackRGBA())
                tierData.qualityTexture:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_WEIGHT_RGB, 1)
            else
                tierData.qualityLabel:SetColor(tierData.qualityLabelColors[2]:UnpackRGBA())
                tierData.qualityTexture:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_WEIGHT_RGB, 0.5)
            end
        end
    end
end

function ZO_RetraitStation_Reconstruct_Keyboard:OnShowing()
    KEYBIND_STRIP:RemoveDefaultExit()
    ITEM_SET_COLLECTIONS_BOOK_KEYBOARD:MarkCategoryContentDirty("Visible") -- Reconstruct shows labels, non-reconstruct shows progress bars
    self:ShowSelectionMode()
end

function ZO_RetraitStation_Reconstruct_Keyboard:OnHiding()
    CRAFTING_RESULTS:SetCraftingTooltip(nil)

    self:HideAllModes()
    KEYBIND_STRIP:RestoreDefaultExit()
    ITEM_SET_COLLECTIONS_BOOK_KEYBOARD:MarkCategoryContentDirty("Visible") -- Reconstruct shows labels, non-reconstruct shows progress bars
end

function ZO_RetraitStation_Reconstruct_Keyboard:OnReconstructResult(result)
    self:HandleDirtyEvent()
end

function ZO_RetraitStation_Reconstruct_Keyboard:OnHorizonalScrollListShown(list)
    local listContainer = list:GetControl():GetParent()
    listContainer.selectedLabel:SetHidden(false)
end

function ZO_RetraitStation_Reconstruct_Keyboard:OnHorizonalScrollListCleared(list)
    local listContainer = list:GetControl():GetParent()
    listContainer.selectedLabel:SetHidden(true)
    listContainer.extraInfoLabel:SetHidden(true)
end

function ZO_RetraitStation_Reconstruct_Keyboard:OnImprovementQualityMouseDown(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT and not control.tierData.isDisabled and not self.isCraftInProgress then
        if self:GetSelectedQuality() == control.tierData.quality then
            self:ClearSelectedQuality()
        else
            self:SetSelectedQuality(control.tierData.quality)
        end
        self:Refresh()
    end
end

function ZO_RetraitStation_Reconstruct_Keyboard:OnImprovementQualityMouseEnter(control)
    if self.isCraftInProgress then
        return
    end

    local tierData = control.tierData
    tierData.isMouseOver = not tierData.isDisabled
    self:Refresh()

    if tierData.reagentLink and not tierData.isDisabled then
        InitializeTooltip(InformationTooltip, control, TOP, 0, 40)
        InformationTooltip:ClearLines()
        InformationTooltip:SetLink(tierData.reagentLink)
    end
end

function ZO_RetraitStation_Reconstruct_Keyboard:OnImprovementQualityMouseExit(control)
    control.tierData.isMouseOver = false
    self:Refresh()
    ClearTooltip(InformationTooltip)
end

function ZO_RetraitStation_Reconstruct_Keyboard:SetupCostLine(control, icon, name, quantity, insufficientQuantity)
    local nameLabel = control:GetNamedChild("NameLabel")
    nameLabel:SetText(name)

    local iconTexture = control:GetNamedChild("IconTexture")
    iconTexture:SetTexture(icon)

    local quantityLabel = iconTexture:GetNamedChild("QuantityLabel")
    quantityLabel:SetText(quantity)
    if insufficientQuantity then
        quantityLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
    else
        quantityLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
    end

    control:SetHidden(false)
end

function ZO_RetraitStation_Reconstruct_Keyboard:RefreshCostList()
    local currencyOptions, materialCosts = self.itemSetPieceData:GetCostInfo()

    -- TODO: Add support for multiple currencies as future proofing.
    local currencyOption = currencyOptions[1]
    local currencyCostEntry = self.costEntries[1]
    self.isCurrencyValid = currencyOption.currencyRequired <= currencyOption.currencyAvailable
    self:SetupCostLine(currencyCostEntry, currencyOption.currencyIcon, currencyOption.currencyName, currencyOption.currencyRequired, not self.isCurrencyValid)

    self.isQualityValid = true
    for costEntryIndex = 2, #self.costEntries do
        local costEntry = self.costEntries[costEntryIndex]
        local materialCostIndex = costEntryIndex - 1
        local materialCost = materialCosts[materialCostIndex]

        if materialCost then
            self:SetupCostLine(costEntry, materialCost.reagentIcon, materialCost.reagentItemLink, materialCost.reagentsRequired, materialCost.reagentsRequired > materialCost.reagentsAvailable)
            costEntry:SetHidden(false)

            if materialCost.reagentsRequired > materialCost.reagentsAvailable then
                self.isQualityValid = false
            end
        else
            costEntry:SetHidden(true)
        end
    end
end