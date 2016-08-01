ZO_SharedSmithingCreation = ZO_Object:Subclass()

function ZO_SharedSmithingCreation:New(...)
    local smithingCreation = ZO_Object.New(self)
    smithingCreation:Initialize(...)
    return smithingCreation
end

local function GetCurrentCraftingLevel()
    local craftingType = GetCraftingInteractionType()
    if craftingType == CRAFTING_TYPE_BLACKSMITHING then
        return GetNonCombatBonus(NON_COMBAT_BONUS_BLACKSMITHING_LEVEL)
    elseif craftingType == CRAFTING_TYPE_CLOTHIER then
        return GetNonCombatBonus(NON_COMBAT_BONUS_CLOTHIER_LEVEL)
    elseif craftingType == CRAFTING_TYPE_WOODWORKING then
        return GetNonCombatBonus(NON_COMBAT_BONUS_WOODWORKING_LEVEL)
    end
end

function ZO_SharedSmithingCreation:Initialize(control, owner)
    self.control = control
    self.owner = owner

    local function HandleDirtyEvent()
        self:HandleDirtyEvent()
    end

    self.control:RegisterForEvent(EVENT_FINISHED_SMITHING_TRAIT_RESEARCH, HandleDirtyEvent)

    self.dirty = true

    control:SetHandler("OnUpdate", function() self:OnUpdate() end)
end

function ZO_SharedSmithingCreation:OnUpdate()
    if self.tooltipDirty then
        self:UpdateTooltipInternal()
        self.tooltipDirty = false
    end
end

function ZO_SharedSmithingCreation:SetCraftingType(craftingType, oldCraftingType, isCraftingTypeDifferent)
    if isCraftingTypeDifferent or not self.typeFilter then
        self.selectedMaterialCountCache = {}
        self:RefreshAvailableFilters()
    end
end

function ZO_SharedSmithingCreation:HandleDirtyEvent()
    if not self.performingFullRefresh then
        if self.control:IsHidden() then
            self.dirty = true
        else
            self:RefreshAllLists()
        end
    end
end

local CRAFTING_TYPE_TO_TOOLTIP_SOUND =
{
    [CRAFTING_TYPE_BLACKSMITHING] = SOUNDS.BLACKSMITH_CREATE_TOOLTIP_GLOW,
    [CRAFTING_TYPE_CLOTHIER] = SOUNDS.CLOTHIER_CREATE_TOOLTIP_GLOW,
    [CRAFTING_TYPE_WOODWORKING] = SOUNDS.WOODWORKER_CREATE_TOOLTIP_GLOW
}

function ZO_SharedSmithingCreation:GetCreateTooltipSound()
    local craftingType = GetCraftingInteractionType()
    return CRAFTING_TYPE_TO_TOOLTIP_SOUND[craftingType]
end

function ZO_SharedSmithingCreation:RefreshVisiblePatterns()
    if not self.performingFullRefresh then
        self.patternList:RefreshVisible()
    end
end

function ZO_SharedSmithingCreation:RefreshAllLists()
    if self.typeFilter then
        self.dirty = false
        self.performingFullRefresh = true

        self:RefreshStyleList()

        self:RefreshPatternList()

        self:RefreshTraitList()

        self.performingFullRefresh = false

        self:OnSelectedPatternChanged(self.patternList:GetSelectedData())
    end

    self:OnRefreshAllLists()

    -- Special case on full refreshes, the style list depends on the pattern list, but the pattern list is also dependent on knowing if there's any valid styles.
    -- If there are no valid styles then none of the patterns can be selected, so clear it out.
    if not self.styleList:GetSelectedData() then
        self.patternList:Clear()
        self.patternList:Commit()
    end
end

function ZO_SharedSmithingCreation:OnRefreshAllLists()
    --No base implementation
end

local USABILITY_TYPE_INVALID = nil
local USABILITY_TYPE_USABLE = true
local USABILITY_TYPE_VALID_BUT_MISSING_REQUIREMENT = false

function ZO_SharedSmithingCreation:GetSelectedPatternIndex()
    return self.patternList:GetSelectedData() and self.patternList:GetSelectedData().patternIndex
end

function ZO_SharedSmithingCreation:GetSelectedMaterialIndex()
    return self.materialList:GetSelectedData() and self.materialList:GetSelectedData().materialIndex
end

function ZO_SharedSmithingCreation:GetSelectedMaterialQuantity()
    local selectedData = self.materialList:GetSelectedData()
    if selectedData then
        return self:GetMaterialQuantity(selectedData.patternIndex, selectedData.materialIndex) or 0
    end
    return 0
end

function ZO_SharedSmithingCreation:GetSelectedStyleIndex()
    return self.styleList:GetSelectedData() and self.styleList:GetSelectedData().styleIndex
end

function ZO_SharedSmithingCreation:GetSelectedTraitIndex()
    return self.traitList:GetSelectedData() and self.traitList:GetSelectedData().traitIndex
end

function ZO_SharedSmithingCreation:GetIsUsingUniversalStyleItem()
    return self.savedVars.useUniversalStyleItemChecked
end

function ZO_SharedSmithingCreation:GetAllCraftingParameters()
    return self:GetSelectedPatternIndex(), self:GetSelectedMaterialIndex(), 
           self:GetSelectedMaterialQuantity(), self:GetSelectedStyleIndex(), self:GetSelectedTraitIndex(), self:GetIsUsingUniversalStyleItem()
end

function ZO_SharedSmithingCreation:GetAllNonTraitCraftingParameters()
    return self:GetSelectedPatternIndex(), self:GetSelectedMaterialIndex(), 
           self:GetSelectedMaterialQuantity(), self:GetSelectedStyleIndex()
end

function ZO_SharedSmithingCreation:OnSelectedPatternChanged(patternData, selectedDuringRebuild)
    if self:IsInvalidMode() then return end

    if not self.performingFullRefresh then
        self.performingFullRefresh = true
        
        if not selectedDuringRebuild then
			local oldStyle = self:GetSelectedStyleIndex()
			self:RefreshStyleList()
			local newStyle = self:GetSelectedStyleIndex()
			if newStyle ~= oldStyle then
				self.styleList:RefreshVisible()
				self.patternList:RefreshVisible()
			end
            self:RefreshMaterialList(patternData)
            self:RefreshTraitList()
        end
        self.materialList:RefreshVisible()

        if self.keybindStripDescriptor then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        else
            self.owner:OnSelectedPatternChanged()
        end

        self:UpdateTooltip()

        self.performingFullRefresh = false
    end
end

function ZO_SharedSmithingCreation:SelectValidKnowledgeIndices()
	local patternIndex = self:GetSelectedPatternIndex()
	local styleIndex = self:GetSelectedStyleIndex()

	if styleIndex and patternIndex then
		if not IsSmithingStyleKnown(styleIndex, patternIndex) then 
			styleIndex = GetFirstKnownStyleIndex(patternIndex)
			self.styleList:SetSelectedDataIndex(styleIndex)
			self.styleList:RefreshVisible()
			return
		end
	end

	for patternIndex = 1, GetNumSmithingPatterns() do
		styleIndex = GetFirstKnownStyleIndex(patternIndex)
		if styleIndex then
			self.patternList:SetSelectedDataIndex(patternIndex)
			self.styleList:SetSelectedDataIndex(styleIndex)
			self.styleList:RefreshVisible()
			return
		end
	end
end

function ZO_SharedSmithingCreation:OnFilterChanged(haveMaterialsChecked, haveKnowledgeChecked, useUniversalStyleItemChecked)
    self.savedVars.haveMaterialChecked = haveMaterialsChecked
	local hadKnowledgeChecked = self.savedVars.haveKnowledgeChecked
    self.savedVars.haveKnowledgeChecked = haveKnowledgeChecked
	if not hadKnowledgeChecked and self.savedVars.haveKnowledgeChecked then
		self:SelectValidKnowledgeIndices()
	end
    self.savedVars.useUniversalStyleItemChecked = useUniversalStyleItemChecked
    self:HandleDirtyEvent()
    if useUniversalStyleItemChecked then
        TriggerTutorial(TUTORIAL_TRIGGER_UNIVERSAL_STYLE_ITEM)
    end
end

ZO_SMITHING_CREATION_FILTER_TYPE_WEAPONS = 1
ZO_SMITHING_CREATION_FILTER_TYPE_ARMOR = 2
ZO_SMITHING_CREATION_FILTER_TYPE_SET_WEAPONS = 3
ZO_SMITHING_CREATION_FILTER_TYPE_SET_ARMOR = 4

function ZO_SharedSmithingCreation:ChangeTypeFilter(filterData)
    self.typeFilter = filterData.descriptor
    self:HandleDirtyEvent()
end

local MIN_SCALE = .6
local MAX_SCALE = 1.0
local BASE_NUM_ITEMS_IN_LIST = 5

local function CustomTooltipAnchor(tooltip, button)
    local centerX, centerY = button:GetCenter()
    local parentCenterX, parentCenterY = button:GetParent():GetCenter()
    tooltip:SetOwner(button:GetParent(), BOTTOM, centerX - parentCenterX, centerY - parentCenterY)
end

local function SetupSharedSlot(control, slotType, listContainer, list)
    ZO_InventorySlot_SetType(control, slotType)

    control.customTooltipAnchor = CustomTooltipAnchor

    control.isMoving = list:IsMoving()
    if not control.isMoving then
        ZO_InventorySlot_HandleInventoryUpdate(control)
    end
end

local function SetHighlightColor(highlightTexture, usable)
    if highlightTexture then
        if usable then
            highlightTexture:SetColor(1, 1, 1, highlightTexture:GetAlpha())
        else
            highlightTexture:SetColor(1, 0, 0, highlightTexture:GetAlpha())
        end
    end
end

local function OnHorizonalScrollListShown(list)
    local listContainer = list:GetControl():GetParent() 
    listContainer.selectedLabel:SetHidden(false)
end

function ZO_SharedSmithingCreation:OnHorizonalScrollListCleared(list)
    local listContainer = list:GetControl():GetParent() 
    listContainer.selectedLabel:SetHidden(true)
    self:SetLabelHidden(listContainer.extraInfoLabel, true)
end

function ZO_SharedSmithingCreation:IsInvalidMode()
    local type = GetCraftingInteractionType()
    return (type == CRAFTING_TYPE_INVALID) or (self.owner.mode ~= SMITHING_MODE_CREATION)
end

function ZO_SharedSmithingCreation:InitializePatternList(scrollListControl, listSlotTemplate)
    local listContainer = self.control:GetNamedChild("PatternList")
    listContainer.titleLabel:SetText(GetString(SI_SMITHING_HEADER_ITEM))

    local function SetupFunction(control, data, selected, selectedDuringRebuild, enabled)
        if self:IsInvalidMode() then return end

        local patternIndex = data.patternIndex
        local materialOverride = self:GetSelectedMaterialIndex()
        local materialQuantityOverride = select(3, GetSmithingPatternMaterialItemInfo(patternIndex, materialOverride))
        local styleOverride = self.styleList:GetSelectedData() and self.styleList:GetSelectedData().itemStyle
        local traitOverride = self.traitList:GetSelectedData() and self.traitList:GetSelectedData().traitType

        local _, _, icon, _, _, _, _ = GetSmithingPatternInfo(patternIndex, materialOverride, materialQuantityOverride, styleOverride, traitOverride)
		local styleIndex = self:GetSelectedStyleIndex()
		if not styleIndex then styleIndex = 2 end -- this is actually the default for this, not 0 or 1
        local isStyleKnown = IsSmithingStyleKnown(styleIndex, patternIndex)
        local meetsTraitRequirement = data.numTraitsRequired <= data.numTraitsKnown 
        local usable = meetsTraitRequirement and isStyleKnown

        ZO_ItemSlot_SetupSlot(control, 1, icon, usable, not enabled)

        if selected then
            if data.numTraitsRequired > 0 then
                listContainer.selectedLabel:SetText(self:GetPlatformFormattedTextString(SI_SMITHING_SELECTED_PATTERN, data.patternName, data.numTraitsRequired))
            else
                listContainer.selectedLabel:SetText(zo_strformat(SI_SMITHING_SELECTED_PATTERN_NO_TRAITS, data.patternName))
            end

            SetHighlightColor(highlightTexture, usable)

            self.isPatternUsable = usable and USABILITY_TYPE_USABLE or USABILITY_TYPE_VALID_BUT_MISSING_REQUIREMENT
        end
    end

    local function EqualityFunction(leftData, rightData)
        return leftData.craftingType == rightData.craftingType and leftData.patternIndex == rightData.patternIndex
    end

    local function OnHorizonalScrollListCleared(...)
        self:OnHorizonalScrollListCleared(...)
    end

    self.patternList = scrollListControl:New(listContainer.listControl, listSlotTemplate, BASE_NUM_ITEMS_IN_LIST, SetupFunction, EqualityFunction, OnHorizonalScrollListShown, OnHorizonalScrollListCleared)
	self.patternList:SetOnSelectedDataChangedCallback(function(selectedData, oldData, selectedDuringRebuild)
        self:OnSelectedPatternChanged(selectedData, selectedDuringRebuild)
    end)

    local highlightTexture = listContainer.highlightTexture
    self.patternList:SetSelectionHighlightInfo(highlightTexture, highlightTexture and highlightTexture.pulseAnimation)
    self.patternList:SetScaleExtents(MIN_SCALE, MAX_SCALE)

    ZO_CraftingUtils_ConnectHorizontalScrollListToCraftingProcess(self.patternList)
end

local function GetRankTooLowString()
    local craftingType = GetCraftingInteractionType()
    if craftingType == CRAFTING_TYPE_BLACKSMITHING then
        return SI_SMITHING_RANK_TOO_LOW_BLACKSMITHING
    elseif craftingType == CRAFTING_TYPE_CLOTHIER then
        return SI_SMITHING_RANK_TOO_LOW_CLOTHIER
    elseif craftingType == CRAFTING_TYPE_WOODWORKING then
        return SI_SMITHING_RANK_TOO_LOW_WOODWORKING
    end
end

function ZO_SharedSmithingCreation:GetMaterialInformation(data)
	local stackCount = GetCurrentSmithingMaterialItemCount(data.patternIndex, data.materialIndex)
	local currentSelectedQuantity = self:GetMaterialQuantity(data.patternIndex, data.materialIndex)
	local currentRank = GetCurrentCraftingLevel()
	local meetsRankRequirement = currentRank >= data.rankRequirement
	local hasAboveMin = stackCount >= data.min
	local hasEnoughInInventory = currentSelectedQuantity <= stackCount and self.materialQuantitySpinner:GetValue() <= stackCount
	local usable = meetsRankRequirement and hasAboveMin and hasEnoughInInventory

	return stackCount, currentSelectedQuantity, currentRank, meetsRankRequirement, hasAboveMin, hasEnoughInInventory, usable
end

function ZO_SharedSmithingCreation:InitializeMaterialList(scrollListControl, spinnerControl, hideSpinnerWhenRankRequirementNotMet, listSlotTemplate)
    local listContainer = self.control:GetNamedChild("MaterialList")
    local highlightTexture = listContainer.highlightTexture
    listContainer.titleLabel:SetText(GetString(SI_SMITHING_HEADER_MATERIAL))

    self.materialQuantitySpinner = spinnerControl:New(listContainer:GetNamedChild("Spinner"))
    self.materialQuantitySpinner:RegisterCallback("OnValueChanged", function(value)
        if not self.performingFullRefresh then
            self:AdjustCurrentMaterialQuantityForAllPatterns(value)
        end

		local data = self.materialList:GetSelectedData()
		local stackCount, currentSelectedQuality, currentRank, meetsRankRequirement, hasAboveMin, hasEnoughInInventory, usable = self:GetMaterialInformation(data)

		self.isMaterialUsable = usable and USABILITY_TYPE_USABLE or USABILITY_TYPE_VALID_BUT_MISSING_REQUIREMENT
		ZO_ItemSlot_SetupSlot(self.selectedMaterialControl, stackCount, data.icon, usable)

		self:UpdateTooltip()

		self.owner:OnSelectedPatternChanged()
		KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end)

    ZO_CraftingUtils_ConnectSpinnerToCraftingProcess(self.materialQuantitySpinner)

    local function SetupFunction(control, data, selected, selectedDuringRebuild, enabled)
        if self:IsInvalidMode() then return end

        SetupSharedSlot(control, SLOT_TYPE_SMITHING_MATERIAL, listContainer, self.materialList)

        control.patternIndex = data.patternIndex
        control.materialIndex = data.materialIndex

        ZO_ItemSlot_SetAlwaysShowStackCount(control, true, data.min)

		local stackCount, currentSelectedQuantity, currentRank, meetsRankRequirement, hasAboveMin, hasEnoughInInventory, usable = self:GetMaterialInformation(data)

        ZO_ItemSlot_SetupSlot(control, stackCount, data.icon, usable, not enabled)

        if selected then
			self.selectedMaterialControl = control

            SetHighlightColor(highlightTexture, usable)

            local function ShowHideSpinnerIfNeeded(hidden)
                if hideSpinnerWhenRankRequirementNotMet then
                    self.materialQuantitySpinner:GetControl():SetHidden(hidden)
                end
            end

            if usable then
                self:SetLabelHidden(listContainer.extraInfoLabel, true)
                ShowHideSpinnerIfNeeded(false)
            else
                if not meetsRankRequirement then
                    self:SetLabelHidden(listContainer.extraInfoLabel, false)
                    listContainer.extraInfoLabel:SetText(zo_strformat(GetRankTooLowString(), data.rankRequirement))
                    ShowHideSpinnerIfNeeded(true)
                else
                    self:SetLabelHidden(listContainer.extraInfoLabel, true)
                    ShowHideSpinnerIfNeeded(false)
                end
            end

            self.isMaterialUsable = usable and USABILITY_TYPE_USABLE or USABILITY_TYPE_VALID_BUT_MISSING_REQUIREMENT
            
            self.materialQuantitySpinner:SetValidValuesFunction(function(startingPoint, step)
                return GetSmithingPatternNextMaterialQuantity(data.patternIndex, data.materialIndex, startingPoint, step)
            end)
            self.materialQuantitySpinner:SetMinMax(data.min, data.max)
            self.materialQuantitySpinner:SetSoftMax(stackCount)
            self.materialQuantitySpinner:SetValue(currentSelectedQuantity)

            listContainer.selectedLabel:SetText(self:GetPlatformFormattedTextString(SI_SMITHING_MATERIAL_QUANTITY, data.name, data.min, data.max))

            if not selectedDuringRebuild then
                self:RefreshVisiblePatterns()
                self:RefreshStyleList()
            end
        end
    end

    local function EqualityFunction(leftData, rightData)
        return leftData.craftingType == rightData.craftingType and leftData.name == rightData.name
    end

    local function OnMaterialHorizonalScrollListShown(list)
        OnHorizonalScrollListShown(list)
        self.materialQuantitySpinner:GetControl():SetHidden(false)
    end

    local function OnMaterialHorizonalScrollListCleared(list)
        self:OnHorizonalScrollListCleared(list)
        self.materialQuantitySpinner:GetControl():SetHidden(true)
    end

    self.materialList = scrollListControl:New(listContainer.listControl, listSlotTemplate, BASE_NUM_ITEMS_IN_LIST, SetupFunction, EqualityFunction, OnMaterialHorizonalScrollListShown, OnMaterialHorizonalScrollListCleared)
    self.materialList:SetNoItemText(GetString(SI_SMITHING_NO_MATERIALS_FOUND))

    self.materialList:SetSelectionHighlightInfo(highlightTexture, highlightTexture and highlightTexture.pulseAnimation)
    self.materialList:SetScaleExtents(MIN_SCALE, MAX_SCALE)

    ZO_CraftingUtils_ConnectHorizontalScrollListToCraftingProcess(self.materialList)
end

function ZO_SharedSmithingCreation:InitializeStyleList(scrollListControl, styleUnknownFont, notEnoughInInventoryFont, listSlotTemplate)
    local listContainer = self.control:GetNamedChild("StyleList")
    local highlightTexture = listContainer.highlightTexture
    listContainer.titleLabel:SetText(GetString(SI_SMITHING_HEADER_STYLE))

    local function SetupFunction(control, data, selected, selectedDuringRebuild, enabled)
        if self:IsInvalidMode() then return end

        SetupSharedSlot(control, SLOT_TYPE_SMITHING_STYLE, listContainer, self.styleList)
        ZO_ItemSlot_SetAlwaysShowStackCount(control, true)

        control.styleIndex = data.styleIndex
        local usesUniversalStyleItem = self:GetIsUsingUniversalStyleItem()
        local stackCount = GetCurrentSmithingStyleItemCount(data.styleIndex)
        local hasEnoughInInventory = stackCount > 0
        local universalStyleItemCount = GetCurrentSmithingStyleItemCount(ZO_ADJUSTED_UNIVERSAL_STYLE_ITEM_INDEX)
        local isStyleKnown = IsSmithingStyleKnown(data.styleIndex, self:GetSelectedPatternIndex())
        local usable = ((stackCount > 0 and not usesUniversalStyleItem) or (usesUniversalStyleItem and universalStyleItemCount > 0)) and isStyleKnown
        ZO_ItemSlot_SetupSlot(control, stackCount, data.icon, usable, not enabled)
        local stackCountLabel = GetControl(control, "StackCount")
        stackCountLabel:SetHidden(usesUniversalStyleItem)

        if selected then
            SetHighlightColor(highlightTexture, usable)

            self:SetLabelHidden(listContainer.extraInfoLabel, true)
            if not usable then
                if not isStyleKnown then
                    self:SetLabelHidden(listContainer.extraInfoLabel, false)
                    listContainer.extraInfoLabel:SetText(GetString(SI_SMITHING_UNKNOWN_STYLE))
                elseif not hasEnoughInInventory then
                    -- do nothing, already hidden above
                end
            end

            local universalStyleItemCount = GetCurrentSmithingStyleItemCount(ZO_ADJUSTED_UNIVERSAL_STYLE_ITEM_INDEX)
            self.isStyleUsable = usable and USABILITY_TYPE_USABLE or USABILITY_TYPE_VALID_BUT_MISSING_REQUIREMENT

            if not data.localizedName then
                if data.itemStyle == ITEMSTYLE_NONE then
                    data.localizedName = GetString("SI_ITEMSTYLE", data.itemStyle)
                else
                    if usesUniversalStyleItem then
                        data.localizedName = self:GetPlatformFormattedTextString(SI_CRAFTING_UNIVERSAL_STYLE_DESCRIPTION, GetString("SI_ITEMSTYLE", data.itemStyle))
                    else
                        data.localizedName = self:GetPlatformFormattedTextString(SI_SMITHING_STYLE_DESCRIPTION, data.name, GetString("SI_ITEMSTYLE", data.itemStyle))
                    end
                end
            end
            
            listContainer.selectedLabel:SetText(data.localizedName)

            if not selectedDuringRebuild then
                self:RefreshVisiblePatterns()
            end
        end
    end

    local function EqualityFunction(leftData, rightData)
        return leftData.craftingType == rightData.craftingType and leftData.name == rightData.name
    end

    local function OnHorizonalScrollListCleared(...)
        self:OnHorizonalScrollListCleared(...)
    end

    self.styleList = scrollListControl:New(listContainer.listControl, listSlotTemplate, BASE_NUM_ITEMS_IN_LIST, SetupFunction, EqualityFunction, OnHorizonalScrollListShown, OnHorizonalScrollListCleared)
    self.styleList:SetNoItemText(GetString(SI_SMITHING_NO_STYLE_FOUND))

    self.styleList:SetSelectionHighlightInfo(highlightTexture, highlightTexture and highlightTexture.pulseAnimation)
    self.styleList:SetScaleExtents(MIN_SCALE, MAX_SCALE)

    self.styleList:SetOnSelectedDataChangedCallback(function(selectedData, oldData, selectedDuringRebuild)
        self:UpdateTooltip()
        self.owner:OnSelectedStyleChanged()
        self:OnStyleChanged(selectedData)
    end)

    ZO_CraftingUtils_ConnectHorizontalScrollListToCraftingProcess(self.styleList)
end

function ZO_SharedSmithingCreation:OnStyleChanged(selectedData)
    -- no additional functionality needed at the shared level
end

function ZO_SharedSmithingCreation:InitializeTraitList(scrollListControl, traitUnknownFont, notEnoughInInventoryFont, listSlotTemplate)
    local listContainer = self.control:GetNamedChild("TraitList")
    local highlightTexture = listContainer.highlightTexture
    listContainer.titleLabel:SetText(GetString(SI_SMITHING_HEADER_TRAIT))

    local function SetupFunction(control, data, selected, selectedDuringRebuild, enabled)
        if self:IsInvalidMode() then return end

        SetupSharedSlot(control, SLOT_TYPE_SMITHING_TRAIT, listContainer, self.traitList)
        ZO_ItemSlot_SetAlwaysShowStackCount(control, data.traitType ~= ITEM_TRAIT_TYPE_NONE)

        control.traitIndex = data.traitIndex
        control.traitType = data.traitType
        local stackCount = GetCurrentSmithingTraitItemCount(data.traitIndex)
        local hasEnoughInInventory = stackCount > 0
        local isTraitKnown = false
        if self:IsCraftableWithoutTrait() then
            local patternIndex, materialIndex, materialQty, styleIndex = self:GetAllNonTraitCraftingParameters()
            isTraitKnown = IsSmithingTraitKnownForResult(patternIndex, materialIndex, materialQty, styleIndex, data.traitIndex)
        end
        local usable = data.traitType == ITEM_TRAIT_TYPE_NONE or (hasEnoughInInventory and isTraitKnown)

        ZO_ItemSlot_SetupSlot(control, stackCount, data.icon, usable, not enabled)

        if selected then
            SetHighlightColor(highlightTexture, usable)
            
            self:SetLabelHidden(listContainer.extraInfoLabel, usable or data.traitType == ITEM_TRAIT_TYPE_NONE)
            if usable then
                self.isTraitUsable = USABILITY_TYPE_USABLE
            else
                self.isTraitUsable = USABILITY_TYPE_VALID_BUT_MISSING_REQUIREMENT
                if not isTraitKnown then
                    listContainer.extraInfoLabel:SetText(GetString(SI_SMITHING_TRAIT_MUST_BE_RESEARCHED))
                elseif not hasEnoughInInventory then
                    self:SetLabelHidden(listContainer.extraInfoLabel, true)
                end
            end

            if not data.localizedName then
                if data.traitType == ITEM_TRAIT_TYPE_NONE then
                    data.localizedName = GetString("SI_ITEMTRAITTYPE", data.traitType)
                else
                    data.localizedName = self:GetPlatformFormattedTextString(SI_SMITHING_TRAIT_DESCRIPTION, data.name, GetString("SI_ITEMTRAITTYPE", data.traitType))
                end
            end
            
            listContainer.selectedLabel:SetText(data.localizedName)

            if not selectedDuringRebuild then
                self:RefreshVisiblePatterns()
            end
        end
    end

    local function EqualityFunction(leftData, rightData)
        return leftData.craftingType == rightData.craftingType and leftData.name == rightData.name
    end

    local function OnHorizonalScrollListCleared(...)
        self:OnHorizonalScrollListCleared(...)
    end

    self.traitList = scrollListControl:New(listContainer.listControl, listSlotTemplate, BASE_NUM_ITEMS_IN_LIST, SetupFunction, EqualityFunction, OnHorizonalScrollListShown, OnHorizonalScrollListCleared)

    self.traitList:SetSelectionHighlightInfo(highlightTexture, highlightTexture and highlightTexture.pulseAnimation)
    self.traitList:SetScaleExtents(MIN_SCALE, MAX_SCALE)

    self.traitList:SetOnSelectedDataChangedCallback(function(selectedData, oldData, selectedDuringRebuild)
        self:UpdateTooltip()
        self.owner:OnSelectedTraitChanged()
    end)

    ZO_CraftingUtils_ConnectHorizontalScrollListToCraftingProcess(self.traitList)
end

function ZO_SharedSmithingCreation:DoesPatternPassFilter(patternData)
    if patternData.resultingItemFilterType == ITEMFILTERTYPE_WEAPONS then
        if self.typeFilter == ZO_SMITHING_CREATION_FILTER_TYPE_WEAPONS then
            if patternData.numTraitsRequired ~= 0 then
                return false
            end
        elseif self.typeFilter == ZO_SMITHING_CREATION_FILTER_TYPE_SET_WEAPONS then
            if patternData.numTraitsRequired == 0 then
                return false
            end
        else
            return false
        end
    elseif patternData.resultingItemFilterType == ITEMFILTERTYPE_ARMOR then
        if self.typeFilter == ZO_SMITHING_CREATION_FILTER_TYPE_ARMOR  then
            if patternData.numTraitsRequired ~= 0 then
                return false
            end
        elseif self.typeFilter == ZO_SMITHING_CREATION_FILTER_TYPE_SET_ARMOR then
            if patternData.numTraitsRequired == 0 then
                return false
            end
        else
            return false
        end
    end
    
    if self.savedVars.haveKnowledgeChecked then
        if patternData.numTraitsKnown < patternData.numTraitsRequired then
            return false
        end

        patternData.materialData = patternData.materialData or self:GenerateMaterialDataForPattern(patternData.patternIndex)

        if #patternData.materialData == 0 then
            return false
        end
    end

    if self.savedVars.haveMaterialChecked then
        patternData.materialData = patternData.materialData or self:GenerateMaterialDataForPattern(patternData.patternIndex)

        if #patternData.materialData == 0 then
            return false
        end
    end

    return true
end

function ZO_SharedSmithingCreation:CreatePatternList()
	self.patternList:Clear()

    for patternIndex = 1, GetNumSmithingPatterns() do
        local patternName, baseName, _, numMaterials, numTraitsRequired, numTraitsKnown, resultingItemFilterType = GetSmithingPatternInfo(patternIndex)
		local styleKnown = IsSmithingStyleKnown(self:GetSelectedStyleIndex(), patternIndex)
        if numMaterials > 0 then
            local data = { craftingType = GetCraftingInteractionType(), patternIndex = patternIndex, patternName = patternName, baseName = baseName, numTraitsRequired = numTraitsRequired, numTraitsKnown = numTraitsKnown, resultingItemFilterType = resultingItemFilterType, styleKnown = styleKnown }
            if self:DoesPatternPassFilter(data) then
                self.patternList:AddEntry(data)
            end
        end
    end

	self.patternList:Commit()
end

function ZO_SharedSmithingCreation:RefreshPatternList()
    self:CreatePatternList()

    if self.typeFilter == ZO_SMITHING_CREATION_FILTER_TYPE_WEAPONS or self.typeFilter == ZO_SMITHING_CREATION_FILTER_TYPE_SET_WEAPONS then
        self.patternList:SetNoItemText(GetString(SI_SMITHING_NO_WEAPONS_FOUND))
    elseif self.typeFilter == ZO_SMITHING_CREATION_FILTER_TYPE_ARMOR or self.typeFilter == ZO_SMITHING_CREATION_FILTER_TYPE_SET_ARMOR then
        self.patternList:SetNoItemText(GetString(SI_SMITHING_NO_ARMOR_FOUND))
    end
end

function ZO_SharedSmithingCreation:DoesMaterialPassFilter(data)
    if self.savedVars.haveKnowledgeChecked then
        if GetCurrentCraftingLevel() < data.rankRequirement then
            return false
        end
    end

    if self.savedVars.haveMaterialChecked then
        if GetCurrentSmithingMaterialItemCount(data.patternIndex, data.materialIndex) < data.min then
            return false
        end
    end

    return true
end

function ZO_SharedSmithingCreation:GenerateMaterialDataForPattern(patternIndex)
    local instanceFilter = {}
    local _, _, _, numMaterials = GetSmithingPatternInfo(patternIndex)
    for materialIndex = 1, numMaterials do
        local name, icon, stack, sellPrice, meetsUsageRequirement, equipType, itemStyle, quality, itemInstanceId, rankRequirement = GetSmithingPatternMaterialItemInfo(patternIndex, materialIndex)
        if instanceFilter[itemInstanceId] then
            local existingData = instanceFilter[itemInstanceId]
            existingData.min = zo_min(existingData.min, stack)
            if not self:GetMaterialQuantity(patternIndex, materialIndex) then
                self:SetMaterialQuantity(patternIndex, materialIndex, existingData.min)
            end
            existingData.max = zo_max(existingData.max, stack)
        else
            local data = { craftingType = GetCraftingInteractionType(), patternIndex = patternIndex, materialIndex = materialIndex, name = name, icon = icon, quality = quality, rankRequirement = rankRequirement, min = stack, max = stack }
            if not self:GetMaterialQuantity(patternIndex, materialIndex) then
                self:SetMaterialQuantity(patternIndex, materialIndex, stack)
            end
            instanceFilter[itemInstanceId] = data
            instanceFilter[#instanceFilter + 1] = data
        end
    end

    local materialData = {}
    for i, data in ipairs(instanceFilter) do
        if self:DoesMaterialPassFilter(data) then
            materialData[#materialData + 1] = data
        end
    end

    return materialData
end

function ZO_SharedSmithingCreation:RefreshMaterialList(patternData)
    local oldSelectedData = self.materialList:GetSelectedData()
    local oldArmorType = nil
    local newArmorType = nil

    if (oldSelectedData) then
        oldArmorType = GetSmithingPatternArmorType(oldSelectedData.patternIndex)
    end

    self.materialList:Clear()

    if patternData then
        newArmorType = GetSmithingPatternArmorType(patternData.patternIndex)
        patternData.materialData = patternData.materialData or self:GenerateMaterialDataForPattern(patternData.patternIndex)

        for itemInstanceId, data in pairs(patternData.materialData) do
            self.materialList:AddEntry(data)
        end
    end

    self.materialList:Commit()

    if (oldArmorType and newArmorType) and (oldArmorType ~= newArmorType) then
        local index = self.materialList:FindIndexFromData(oldSelectedData, function(oldData, newData) return (oldData.rankRequirement == newData.rankRequirement) end)
        if (index) then
            self.materialList:SetSelectedIndex(index)
        end
    end
end

function ZO_SharedSmithingCreation:DoesStylePassFilter(styleIndex, alwaysHideIfLocked)
    if self.savedVars.haveKnowledgeChecked or alwaysHideIfLocked then
        if not IsSmithingStyleKnown(styleIndex, self:GetSelectedPatternIndex()) then
            return false
        end
    end

    if self.savedVars.haveMaterialChecked then
        if GetCurrentSmithingStyleItemCount(styleIndex) == 0 and not self:GetIsUsingUniversalStyleItem() then
            return false
        end
    end

    if styleIndex == ZO_ADJUSTED_UNIVERSAL_STYLE_ITEM_INDEX then
        return false
    end

    local patternData = self.patternList:GetSelectedData()

    if patternData then
        patternData.materialData = patternData.materialData or self:GenerateMaterialDataForPattern(patternData.patternIndex)

        if #patternData.materialData == 0 then
            return false
        end

        if not CanSmithingStyleBeUsedOnPattern(styleIndex, self:GetSelectedPatternIndex(), patternData.materialData[1].materialIndex, patternData.materialData[1].min) then
            return false
        end
    end

    return true
end

local STYLE_LIST_USI_BG_STANDARD_ALPHA = 0.35
local STYLE_LIST_USI_BG_LOW_ALPHA = 0.21
function ZO_SharedSmithingCreation:RefreshStyleList()
    self.styleList:Clear()

    for styleIndex = 1, GetNumSmithingStyleItems() do
        local name, icon, sellPrice, meetsUsageRequirement, itemStyle, quality, alwaysHideIfLocked = GetSmithingStyleItemInfo(styleIndex)
        if meetsUsageRequirement and self:DoesStylePassFilter(styleIndex, alwaysHideIfLocked) then
            self.styleList:AddEntry({ craftingType = GetCraftingInteractionType(), styleIndex = styleIndex, name = name, itemStyle = itemStyle, icon = icon, quality = quality })
        end
    end

    self.styleList:Commit()

    local styleListControl = self.control:GetNamedChild("StyleList")
    if self:GetIsUsingUniversalStyleItem() then
        local universalItemBg = styleListControl.universalItemBg
        universalItemBg:SetHidden(false)
        if GetCurrentSmithingStyleItemCount(ZO_ADJUSTED_UNIVERSAL_STYLE_ITEM_INDEX) == 0 then
            universalItemBg:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
            universalItemBg:SetAlpha(STYLE_LIST_USI_BG_LOW_ALPHA)
        else
            universalItemBg:SetColor(ZO_COLOR_UNIVERSAL_ITEM:UnpackRGBA())
            universalItemBg:SetAlpha(STYLE_LIST_USI_BG_STANDARD_ALPHA)
        end
    else
        styleListControl.universalItemBg:SetHidden(true)
    end
end

function ZO_SharedSmithingCreation:DoesTraitPassFilter(traitIndex, traitType)
    assert(self.typeFilter)
    if ZO_CraftingUtils_IsTraitAppliedToWeapons(traitType) then
        if self.typeFilter == ZO_SMITHING_CREATION_FILTER_TYPE_ARMOR or self.typeFilter == ZO_SMITHING_CREATION_FILTER_TYPE_SET_ARMOR then
            return false
        end
    elseif ZO_CraftingUtils_IsTraitAppliedToArmor(traitType) then
        if self.typeFilter == ZO_SMITHING_CREATION_FILTER_TYPE_WEAPONS or self.typeFilter == ZO_SMITHING_CREATION_FILTER_TYPE_SET_WEAPONS then
            return false
        end
    end

    if self.savedVars.haveKnowledgeChecked then
        if not self:IsCraftableWithoutTrait() then
            return false
        end

        local patternIndex, materialIndex, materialQty, styleIndex = self:GetAllNonTraitCraftingParameters()
        if not IsSmithingTraitKnownForResult(patternIndex, materialIndex, materialQty, styleIndex, traitIndex) then
            return false
        end
    end

    if self.savedVars.haveMaterialChecked then
        if GetCurrentSmithingTraitItemCount(traitIndex) == 0 then
            return false
        end
    end

    return true
end

function ZO_SharedSmithingCreation:RefreshTraitList()
    self.traitList:Clear()

    for traitIndex = 1, GetNumSmithingTraitItems() do
        local traitType, name, icon, sellPrice, meetsUsageRequirement, itemStyle, quality = GetSmithingTraitItemInfo(traitIndex)
        if traitType then
            if traitType == ITEM_TRAIT_TYPE_NONE then
                self.traitList:AddEntry({ craftingType = GetCraftingInteractionType(), traitIndex = traitIndex, traitType = traitType, icon = "EsoUI/Art/Crafting/crafting_smithing_noTrait.dds" })
            elseif self:DoesTraitPassFilter(traitIndex, traitType) then
                self.traitList:AddEntry({ craftingType = GetCraftingInteractionType(), traitIndex = traitIndex, name = name, traitType = traitType, icon = icon, quality = quality })
            end
        end
    end

    self.traitList:Commit()
end

function ZO_SharedSmithingCreation:UpdateTooltip()
    self.tooltipDirty = true
end

function ZO_SharedSmithingCreation:UpdateTooltipInternal()
    if self:AreSelectionsValid() then
        self.resultTooltip:SetHidden(false)
        self.resultTooltip:ClearLines()
        self:SetupResultTooltip(self:GetAllCraftingParameters())
    else
        self.resultTooltip:SetHidden(true)
    end
end

function ZO_SharedSmithingCreation:AdjustCurrentMaterialQuantityForAllPatterns(updatedQuantity)
    local selectedData = self.materialList:GetSelectedData()
    if selectedData then
        local selectedDataMaterialIndex = selectedData.materialIndex -- keep track of the material to update
        local patternCount = #self.patternList.list
        for patternListIndex = 1, patternCount do
            local minQuantity = updatedQuantity
            local maxQuantity = updatedQuantity

            -- before updating the material quantity, do a safety check against the min and max for the material
            local patternData = self.patternList.list[patternListIndex]
            local patternIndex = patternData.patternIndex
            local currentPatternMaterialData = patternData.materialData or self:GenerateMaterialDataForPattern(patternIndex)
            if currentPatternMaterialData then
                local materialCount = #currentPatternMaterialData
                for materialListIndex = 1, materialCount do
                    local currentMaterialData = currentPatternMaterialData[materialListIndex]
                    if currentMaterialData.materialIndex == selectedDataMaterialIndex then
                        minQuantity = currentMaterialData.min
                        maxQuantity = currentMaterialData.max
                        break
                    end
                end
            end

            -- safe update based on material min and max
            if self:GetMaterialQuantity(patternIndex, selectedDataMaterialIndex) and updatedQuantity >= minQuantity and updatedQuantity <= maxQuantity then
                --then get a valid quantity for this pattern and material closest to the updatedQuantity
                local validQuantity = GetSmithingPatternNextMaterialQuantity(patternIndex, selectedDataMaterialIndex, updatedQuantity, 0)
                self:SetMaterialQuantity(patternIndex, selectedDataMaterialIndex, validQuantity)
            end
        end
    end
end

function ZO_SharedSmithingCreation:SetMaterialQuantity(patternIndex, materialIndex, quantity)
    if not self.selectedMaterialCountCache then 
		self.selectedMaterialCountCache = {}
	end
	
	if not self.selectedMaterialCountCache[patternIndex] then
        self.selectedMaterialCountCache[patternIndex] = {}
    end

    self.selectedMaterialCountCache[patternIndex][materialIndex] = quantity
end

function ZO_SharedSmithingCreation:GetMaterialQuantity(patternIndex, materialIndex)
    if self.selectedMaterialCountCache and self.selectedMaterialCountCache[patternIndex] then
        return self.selectedMaterialCountCache[patternIndex][materialIndex]
    end
	return nil
end

function ZO_SharedSmithingCreation:AreSelectionsValid()
    if self:GetSelectedPatternIndex() and self:GetSelectedMaterialIndex() and self:GetSelectedMaterialQuantity() > 0 and self:GetSelectedStyleIndex() and self:GetSelectedTraitIndex() then
        return self.isPatternUsable ~= USABILITY_TYPE_INVALID and self.isMaterialUsable ~= USABILITY_TYPE_INVALID and self.isStyleUsable ~= USABILITY_TYPE_INVALID and self.isTraitUsable ~= USABILITY_TYPE_INVALID
    end
    return false
end

function ZO_SharedSmithingCreation:IsCraftable()
    if self:GetSelectedPatternIndex() and self:GetSelectedMaterialIndex() and self:GetSelectedMaterialQuantity() > 0 and self:GetSelectedStyleIndex() and self:GetSelectedTraitIndex() then
        return self.isPatternUsable and self.isMaterialUsable and self.isStyleUsable and self.isTraitUsable
    end
    return false
end

function ZO_SharedSmithingCreation:IsCraftableWithoutTrait()
    if self:GetSelectedPatternIndex() and self:GetSelectedMaterialIndex() and self:GetSelectedMaterialQuantity() > 0 and self:GetSelectedStyleIndex() then
        return self.isStyleUsable ~= USABILITY_TYPE_INVALID
    end
    return false
end

function ZO_SharedSmithingCreation:Create()
    CraftSmithingItem(self:GetAllCraftingParameters())
end

function ZO_SharedSmithingCreation:GetUniversalStyleItemLink()
    return GetSmithingStyleItemLink(ZO_ADJUSTED_UNIVERSAL_STYLE_ITEM_INDEX)
end

function ZO_SharedSmithingCreation:TriggerUSITutorial()
    local universalStyleItemCount = GetCurrentSmithingStyleItemCount(ZO_ADJUSTED_UNIVERSAL_STYLE_ITEM_INDEX)
    if universalStyleItemCount > 0 then
        TriggerTutorial(TUTORIAL_TRIGGER_UNIVERSAL_STYLE_ITEM)
    end
end