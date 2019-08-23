ZO_SharedSmithingCreation = ZO_CraftingCreateScreenBase:Subclass()

function ZO_SharedSmithingCreation:New(...)
    local smithingCreation = ZO_CraftingCreateScreenBase.New(self)
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
    elseif craftingType == CRAFTING_TYPE_JEWELRYCRAFTING then
        return GetNonCombatBonus(NON_COMBAT_BONUS_JEWELRYCRAFTING_LEVEL)
    end
end

function ZO_SharedSmithingCreation:Initialize(control, owner)
    self.control = control
    self.owner = owner

    local function DirtyAllLists()
        self:DirtyAllLists()
    end
    self.control:RegisterForEvent(EVENT_SMITHING_TRAIT_RESEARCH_COMPLETED, DirtyAllLists)

    -- This refresh group is relatively new to the creation screen, and many
    -- things that could be considered refresh groups aren't reflected here yet.
    -- When possible, please consider organizing the existing refresh behaviors
    -- into a hierarchy that can then be added as a refresh group.
    self.refreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_PER_FRAME)
    self.refreshGroup:AddDirtyState("AllLists", function()
        self:RefreshAllListsLayer()
    end)
    self.refreshGroup:AddDirtyState("Result", function()
        self:RefreshResultLayer()
    end)
    self.refreshGroup:SetActive(function()
        return ZO_Smithing_IsSceneShowing() and self.owner:IsCreating()
    end)
end

function ZO_SharedSmithingCreation:SetCraftingType(craftingType, oldCraftingType, isCraftingTypeDifferent)
    if isCraftingTypeDifferent or not self.typeFilter then
        self:RefreshAvailableFilters()
    end
end

function ZO_SharedSmithingCreation:DirtyAllLists()
    self.refreshGroup:MarkDirty("AllLists")
end

function ZO_SharedSmithingCreation:RefreshAllListsLayer()
    if self.typeFilter then
        self.performingFullRefresh = true

        self:RefreshPatternList()
        local patternData = self.patternList:GetSelectedData()
        self:RefreshMaterialList(patternData)
        self:RefreshStyleList() -- requires a valid pattern and material selection
        self:RefreshTraitList(patternData)

        self:RefreshResultLayer()

        self.performingFullRefresh = false
    end

    self:OnRefreshAllLists()

    -- Special case on full refreshes, the style/material list depends on the pattern list, but the pattern list is also dependent on knowing if there's any valid styles/materials for a given pattern
    -- If there are no valid styles, there's no way for us to select a valid pattern icon for any pattern, so we'll clear them all out.
    -- because there may be valid materials for some patterns and not for others, that is handled as part of the normal RefreshPatternList().
    -- This is outside of the performingFullRefresh loop to force a second refresh in this situation.
    local hasValidStyle = self:ShouldIgnoreStyleItems() or self.styleList:GetSelectedData()
    if not hasValidStyle then
        self.patternList:Clear()
        self.patternList:Commit()
    end
end

function ZO_SharedSmithingCreation:OnRefreshAllLists()
    --No base implementation
end

function ZO_SharedSmithingCreation:DirtyResult()
    self.refreshGroup:MarkDirty("Result")
end

function ZO_SharedSmithingCreation:RefreshResultLayer()
    self:RefreshTooltip()
    self:RefreshMultiCraft()
    self:UpdateKeybindStrip()
end

local CRAFTING_TYPE_TO_TOOLTIP_SOUND =
{
    [CRAFTING_TYPE_BLACKSMITHING] = SOUNDS.BLACKSMITH_CREATE_TOOLTIP_GLOW,
    [CRAFTING_TYPE_CLOTHIER] = SOUNDS.CLOTHIER_CREATE_TOOLTIP_GLOW,
    [CRAFTING_TYPE_WOODWORKING] = SOUNDS.WOODWORKER_CREATE_TOOLTIP_GLOW,
    [CRAFTING_TYPE_JEWELRYCRAFTING] = SOUNDS.JEWELRYCRAFTER_CREATE_TOOLTIP_GLOW,
}

function ZO_SharedSmithingCreation:GetCreateTooltipSound()
    local craftingType = GetCraftingInteractionType()
    return CRAFTING_TYPE_TO_TOOLTIP_SOUND[craftingType]
end

function ZO_SharedSmithingCreation:RefreshVisiblePatterns()
    self.patternList:RefreshVisible()
end

local USABILITY_TYPE_INVALID = 0
local USABILITY_TYPE_USABLE = 1
local USABILITY_TYPE_VALID_BUT_MISSING_REQUIREMENT = 2
local USABILITY_TYPE_VALID_BUT_MISSING_ITEM = 3

function ZO_SharedSmithingCreation:GetSelectedPatternIndex()
    return self.patternList:GetSelectedData() and self.patternList:GetSelectedData().patternIndex
end

function ZO_SharedSmithingCreation:GetSelectedMaterialIndex()
    return self.materialList:GetSelectedData() and self.materialList:GetSelectedData().materialIndex
end

function ZO_SharedSmithingCreation:GetMaterialQuantity(materialData)
    --The list memory is where we store what combination index had last been selected on each material type. If there is no memory, we use the first index.
    local combinationIndex = self:GetLastListSelection(self:GetMaterialListMemoryKey(materialData.materialIndex)) or 1
    if combinationIndex <= #materialData.combinations then
        return materialData.combinations[combinationIndex].stack
    else
        return 0
    end
end

function ZO_SharedSmithingCreation:GetSelectedMaterialQuantity()
    local selectedData = self.materialList:GetSelectedData()
    if selectedData then
        return self:GetMaterialQuantity(selectedData)
    end
    return 0
end

function ZO_SharedSmithingCreation:GetSelectedItemStyleId()
    return self.styleList:GetSelectedData() and self.styleList:GetSelectedData().itemStyleId
end

function ZO_SharedSmithingCreation:GetSelectedTraitIndex()
    return self.traitList:GetSelectedData() and self.traitList:GetSelectedData().traitIndex
end

function ZO_SharedSmithingCreation:GetIsUsingUniversalStyleItem()
    return self.savedVars.useUniversalStyleItemChecked
end

function ZO_SharedSmithingCreation:ShouldIgnoreStyleItems()
    return DoesSmithingTypeIgnoreStyleItems(GetCraftingInteractionType())
end

-- Returns all parameters needed for the final CraftSmithingItem() call
-- Overrides ZO_CraftingCreateScreenBase
function ZO_SharedSmithingCreation:GetAllCraftingParameters(numIterations)
    return self:GetSelectedPatternIndex(),
           self:GetSelectedMaterialIndex(), self:GetSelectedMaterialQuantity(),
           self:GetSelectedItemStyleId(), self:GetSelectedTraitIndex(),
           self:GetIsUsingUniversalStyleItem(), numIterations
end

-- Returns all parameters needed to correctly simulate a single iteration of a craft.
function ZO_SharedSmithingCreation:GetCraftingParametersWithoutIterations()
    return self:GetSelectedPatternIndex(),
           self:GetSelectedMaterialIndex(), self:GetSelectedMaterialQuantity(),
           self:GetSelectedItemStyleId(), self:GetSelectedTraitIndex(),
           self:GetIsUsingUniversalStyleItem()
end

-- Returns parameters necessary to correctly predict the resulting item
function ZO_SharedSmithingCreation:GetResultCraftingParameters()
    return self:GetSelectedPatternIndex(),
           self:GetSelectedMaterialIndex(), self:GetSelectedMaterialQuantity(),
           self:GetSelectedItemStyleId(), self:GetSelectedTraitIndex()
end

function ZO_SharedSmithingCreation:OnSelectedPatternChanged(patternData, selectedDuringRebuild)
    if self:IsInvalidMode() then return end

    if not self.performingFullRefresh then
        self.performingFullRefresh = true

        if not selectedDuringRebuild then
            local oldStyle = self:GetSelectedItemStyleId()
            self:RefreshStyleList()
            local newStyle = self:GetSelectedItemStyleId()
            if newStyle ~= oldStyle then
                self.styleList:RefreshVisible()
                self.patternList:RefreshVisible()
            end
            self:RefreshMaterialList(patternData)
            self:RefreshTraitList(patternData)
        end
        self.materialList:RefreshVisible()

        self:RefreshResultLayer()

        self.performingFullRefresh = false
    end
end

function ZO_SharedSmithingCreation:SelectValidKnowledgeIndices()
    local patternIndex = self:GetSelectedPatternIndex()
    local itemStyleId = self:GetSelectedItemStyleId()

    if itemStyleId and patternIndex then
        if not IsSmithingStyleKnown(itemStyleId, patternIndex) then
            itemStyleId = GetFirstKnownItemStyleId(patternIndex)
            if itemStyleId then
                self.styleList:SetSelectedDataIndex(itemStyleId)
                self.styleList:RefreshVisible()
            end
            return
        end
    end

    for nextPatternIndex = 1, GetNumSmithingPatterns() do
        itemStyleId = GetFirstKnownItemStyleId(nextPatternIndex)
        if itemStyleId then
            self.patternList:SetSelectedDataIndex(nextPatternIndex)
            self.styleList:SetSelectedDataIndex(itemStyleId)
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
    self:DirtyAllLists()
    if useUniversalStyleItemChecked then
        TriggerTutorial(TUTORIAL_TRIGGER_UNIVERSAL_STYLE_ITEM)
    end
end

function ZO_SharedSmithingCreation:ChangeTypeFilter(filterData)
    self.typeFilter = filterData.descriptor
    self:DirtyAllLists()
end

local MIN_SCALE = .6
local MAX_SCALE = 1.1
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

local MEMORY_TYPE_MATERIAL = 1
local MEMORY_TYPE_STYLE = 2
local MEMORY_TYPE_FIRST_MATERIAL_LEVEL = 100

function ZO_SharedSmithingCreation:GetListSelectionMemory()
    if not self.smithingSelectionMemory then
        self.smithingSelectionMemory = {}
    end
    return self.smithingSelectionMemory
end

function ZO_SharedSmithingCreation:GetMaterialListMemoryKey(materialIndex)
    return MEMORY_TYPE_FIRST_MATERIAL_LEVEL + materialIndex
end

function ZO_SharedSmithingCreation:GetLastListSelection(key)
    local memory = self:GetListSelectionMemory()
    return memory[key]
end

function ZO_SharedSmithingCreation:SetLastListSelection(key, data)
    local memory = self:GetListSelectionMemory()
    memory[key] = data
end

function ZO_SharedSmithingCreation:InitializePatternList(scrollListClass, listSlotTemplate)
    local listContainer = self.control:GetNamedChild("PatternList")
    listContainer.titleLabel:SetText(GetString(SI_SMITHING_HEADER_ITEM))

    local function SetupFunction(control, data, selected, selectedDuringRebuild, enabled)
        if self:IsInvalidMode() then return end

        local patternIndex = data.patternIndex
        local materialOverride = self:GetSelectedMaterialIndex()
        local materialQuantityOverride = select(3, GetSmithingPatternMaterialItemInfo(patternIndex, materialOverride))
        local styleOverride = self:GetSelectedItemStyleId()
        local traitOverride = self.traitList:GetSelectedData() and self.traitList:GetSelectedData().traitType

        local _, _, icon, _, _, _, _ = GetSmithingPatternInfo(patternIndex, materialOverride, materialQuantityOverride, styleOverride, traitOverride)
        local meetsTraitRequirement = data.numTraitsRequired <= data.numTraitsKnown

        ZO_ItemSlot_SetupSlot(control, 1, icon, meetsTraitRequirement, not enabled)

        if selected then
            listContainer.selectedLabel:SetText(zo_strformat(SI_SMITHING_SELECTED_PATTERN, data.patternName))
            if data.numTraitsRequired > 0 then
                self:SetLabelHidden(listContainer.extraInfoLabel, false)
                if not meetsTraitRequirement then
                    listContainer.extraInfoLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
                    listContainer.extraInfoLabel:SetText(zo_strformat(SI_SMITHING_SET_NOT_ENOUGH_TRAITS_ERROR, data.numTraitsRequired - data.numTraitsKnown))
                else
                    listContainer.extraInfoLabel:SetText(zo_strformat(SI_SMITHING_SET_ENOUGH_TRAITS, data.numTraitsRequired))
                    listContainer.extraInfoLabel:SetColor(ZO_SUCCEEDED_TEXT:UnpackRGBA())
                end
            else
                self:SetLabelHidden(listContainer.extraInfoLabel, true)
            end

            self.isPatternUsable = meetsTraitRequirement and USABILITY_TYPE_USABLE or USABILITY_TYPE_VALID_BUT_MISSING_REQUIREMENT
        end
    end

    local function EqualityFunction(leftData, rightData)
        return leftData.craftingType == rightData.craftingType and leftData.patternIndex == rightData.patternIndex
    end

    local function OnHorizonalScrollListCleared(...)
        self:OnHorizonalScrollListCleared(...)
    end

    self.patternList = scrollListClass:New(listContainer.listControl, listSlotTemplate, BASE_NUM_ITEMS_IN_LIST, SetupFunction, EqualityFunction, OnHorizonalScrollListShown, OnHorizonalScrollListCleared)
    self.patternList:SetOnSelectedDataChangedCallback(function(selectedData, oldData, selectedDuringRebuild)
        self:OnSelectedPatternChanged(selectedData, selectedDuringRebuild)
    end)

    self.patternList:SetScaleExtents(MIN_SCALE, MAX_SCALE)

    ZO_CraftingUtils_ConnectHorizontalScrollListToCraftingProcess(self.patternList)
end

function ZO_SharedSmithingCreation:GetMaterialInformation(data)
    local stackCount = GetCurrentSmithingMaterialItemCount(data.patternIndex, data.materialIndex)
    local currentSelectedQuantity = self:GetMaterialQuantity(data)
    local currentRank = GetCurrentCraftingLevel()
    local meetsRankRequirement = currentRank >= data.rankRequirement
    local hasAboveMin = stackCount >= data.min
    local hasEnoughInInventory = stackCount >= currentSelectedQuantity
    local usable = meetsRankRequirement and hasAboveMin and hasEnoughInInventory

    return stackCount, currentSelectedQuantity, currentRank, meetsRankRequirement, hasAboveMin, hasEnoughInInventory, usable
end

function ZO_SharedSmithingCreation:InitializeMaterialList(scrollListClass, spinnerClass, listSlotTemplate, championPointRangeIconsInheritColor, colorMaterialNameWhite)
    local listContainer = self.control:GetNamedChild("MaterialList")

    --Quantity Spinner
    -------------------------

    local spinnerControl = listContainer:GetNamedChild("Spinner")

    do
        --Create two worst case pieces of text and then size the spinner to fit the worst of them
        local spinnerDisplayLabel = spinnerControl:GetNamedChild("Display")
        local maxLevelText = zo_strformat(SI_SMITHING_CREATED_LEVEL, 100)
        local spinnerLevelTextWidthPixels = spinnerDisplayLabel:GetStringWidth(maxLevelText)

        --GetStringWidth doesn't handle markup so we compute the texture markup size here and pass in empty string to the format
        local maxCPText = zo_strformat(SI_SMITHING_CREATED_CHAMPION_POINTS, "",  1000)
        local CHAMPION_TEXTURE_WIDTH_PERCENT = 100
        local championTextureWidthPixels = spinnerDisplayLabel:GetFontHeight() * (CHAMPION_TEXTURE_WIDTH_PERCENT / 100) * GetUIGlobalScale()
        local spinnerCPTextWidthPixels = spinnerDisplayLabel:GetStringWidth(maxCPText)
        spinnerCPTextWidthPixels = spinnerCPTextWidthPixels + championTextureWidthPixels

        local spinnerValueTextWidthPixels = zo_max(spinnerLevelTextWidthPixels, spinnerCPTextWidthPixels)
        local spinnerValueTextWidthUI = spinnerValueTextWidthPixels / GetUIGlobalScale()
        local spinnerIncreaseButton = spinnerControl:GetNamedChild("Increase")
        local spinnerIncreaseButtonWidth = spinnerIncreaseButton:GetWidth()
        local PADDING_WIDTH_UI = 10
        local spinnerWidthUI = spinnerValueTextWidthUI + spinnerIncreaseButtonWidth * 2 + PADDING_WIDTH_UI * 2
        spinnerControl:SetWidth(spinnerWidthUI)
    end

    self.materialQuantitySpinner = spinnerClass:New(spinnerControl)
    self.materialQuantitySpinner:SetValue(1)

    local function MaterialQuantitySpinner_OnValueChanged(value)
        local materialData = self.materialList:GetSelectedData()

        --Store the last selected combination index (level) for this material
        self:SetLastListSelection(self:GetMaterialListMemoryKey(materialData.materialIndex), value)

        local stackCount, currentSelectedQuality, currentRank, meetsRankRequirement, hasAboveMin, hasEnoughInInventory, usable = self:GetMaterialInformation(materialData)
        local combination = materialData.combinations[value]

        if not meetsRankRequirement then
            local craftingRankAbilityId = GetTradeskillLevelPassiveAbilityId(GetCraftingInteractionType())
            local craftingRankAbilityName = GetAbilityName(craftingRankAbilityId)

            listContainer.extraInfoLabel:SetText(zo_strformat(SI_SMITHING_RANK_TOO_LOW, craftingRankAbilityName, materialData.rankRequirement))
            listContainer.extraInfoLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
        else
            local text
            if combination.stack > 1 then
                if usable then
                    text = zo_strformat(SI_SMITHING_MATERIAL_REQUIRED_PLURAL, ZO_WHITE:Colorize(combination.stack), materialData.name)
                else
                    text = zo_strformat(SI_SMITHING_MATERIAL_REQUIRED_PLURAL, combination.stack, materialData.name)
                end
            else
                if usable then
                    text = zo_strformat(SI_SMITHING_MATERIAL_REQUIRED_SINGULAR, ZO_WHITE:Colorize(combination.stack), materialData.name)
                else
                    text = zo_strformat(SI_SMITHING_MATERIAL_REQUIRED_SINGULAR, combination.stack, materialData.name)
                end
            end
            listContainer.extraInfoLabel:SetText(text)

            if usable then
                listContainer.extraInfoLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
            else
                listContainer.extraInfoLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
            end
        end

        if not meetsRankRequirement then
            self.isMaterialUsable = USABILITY_TYPE_VALID_BUT_MISSING_REQUIREMENT
        elseif not (hasAboveMin and hasEnoughInInventory) then
            self.isMaterialUsable = USABILITY_TYPE_VALID_BUT_MISSING_ITEM
        else
            self.isMaterialUsable = USABILITY_TYPE_USABLE
        end

        --Needs to be refreshed when the material changes and also when the selected material's combination (level) changes
        local stackCountLabel = self.selectedMaterialControl:GetNamedChild("StackCount")
        if usable then
            stackCountLabel:SetColor(ZO_WHITE:UnpackRGBA())
        else
            stackCountLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
        end

        self:OnResultParametersChanged()
    end

    self.materialQuantitySpinner:RegisterCallback("OnValueChanged", MaterialQuantitySpinner_OnValueChanged)

    self.materialQuantitySpinner:SetValueFormatFunction(function(value)
        if self.materialList then
            local data = self.materialList:GetSelectedData()
            if data then
                local stackCount, currentSelectedQuality, currentRank, meetsRankRequirement, hasAboveMin, hasEnoughInInventory, usable = self:GetMaterialInformation(data)
                local combination = data.combinations[value]
                if combination.isChampionPoint then
                    if meetsRankRequirement then
                        return zo_strformat(SI_SMITHING_CREATED_CHAMPION_POINTS, GetChampionIconMarkupString("100%"), ZO_WHITE:Colorize(combination.createsItemOfLevel))
                    else
                        return ZO_ERROR_COLOR:Colorize(zo_strformat(SI_SMITHING_CREATED_CHAMPION_POINTS, GetChampionIconMarkupStringInheritColor("100%"), combination.createsItemOfLevel))
                    end
                else
                    if meetsRankRequirement then
                        return zo_strformat(SI_SMITHING_CREATED_LEVEL, ZO_WHITE:Colorize(combination.createsItemOfLevel))
                    else
                        return ZO_ERROR_COLOR:Colorize(zo_strformat(SI_SMITHING_CREATED_LEVEL, combination.createsItemOfLevel))
                    end
                end
            end
        end
    end)

    ZO_CraftingUtils_ConnectSpinnerToCraftingProcess(self.materialQuantitySpinner)

    --Material List

    listContainer.titleLabel:SetText(GetString(SI_SMITHING_HEADER_MATERIAL))

    local function SetupFunction(control, data, selected, selectedDuringRebuild, enabled)
        if self:IsInvalidMode() then return end

        SetupSharedSlot(control, SLOT_TYPE_SMITHING_MATERIAL, listContainer, self.materialList)

        control.patternIndex = data.patternIndex
        control.materialIndex = data.materialIndex

        local stackCount, currentSelectedQuantity, currentRank, meetsRankRequirement, hasAboveMin, hasEnoughInInventory, usable = self:GetMaterialInformation(data)
        ZO_ItemSlot_SetupSlot(control, stackCount, data.icon, meetsRankRequirement, not enabled)
        ZO_ItemSlot_SetAlwaysShowStackCount(control, true)

        --Needs to be refreshed when the material changes and also when the selected material's combination (level) changes
        local stackCountLabel = control:GetNamedChild("StackCount")
        if usable then
            stackCountLabel:SetColor(ZO_WHITE:UnpackRGBA())
        else
            stackCountLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
        end

        if selected then
            self.selectedMaterialControl = control
            self:SetLastListSelection(MEMORY_TYPE_MATERIAL, data)

            self.isMaterialUsable = usable and USABILITY_TYPE_USABLE or USABILITY_TYPE_VALID_BUT_MISSING_REQUIREMENT

            local selectedLabelText
            local materialNameText = colorMaterialNameWhite and ZO_WHITE:Colorize(data.name) or data.name
            if data.isChampionPoint then
                local championPointIcon = championPointRangeIconsInheritColor and GetChampionIconMarkupStringInheritColor("100%") or GetChampionIconMarkupString("100%")
                selectedLabelText = zo_strformat(SI_SMITHING_MATERIAL_CHAMPION_POINT_RANGE, materialNameText, championPointIcon, data.minCreatesItemOfLevel, championPointIcon, data.maxCreatesItemOfLevel)
            else
                selectedLabelText = zo_strformat(SI_SMITHING_MATERIAL_LEVEL_RANGE, materialNameText, data.minCreatesItemOfLevel, data.maxCreatesItemOfLevel)
            end
            listContainer.selectedLabel:SetText(selectedLabelText)

            self:SetLabelHidden(listContainer.extraInfoLabel, false)

            -- using SetMinMax() will constrain any existing values to the new range, so that needs to happen _after_ we pull up the last value; otherwise we might overwrite that last value with a garbage value
            local selectedLastCombinationIndex = self:GetLastListSelection(self:GetMaterialListMemoryKey(data.materialIndex)) or 1
            self.materialQuantitySpinner:SetMinMax(1, #data.combinations)
            self.materialQuantitySpinner:SetValue(selectedLastCombinationIndex)

            --The spinner value changed logic and value format function both depend on the selected material as well. So we have to cause them to update whenever the selected material changes.
            MaterialQuantitySpinner_OnValueChanged(self.materialQuantitySpinner:GetValue())
            self.materialQuantitySpinner:UpdateDisplay()

            if not selectedDuringRebuild then
                if not self.performingFullRefresh then
                    self:RefreshVisiblePatterns()
                end
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

    self.materialList = scrollListClass:New(listContainer.listControl, listSlotTemplate, BASE_NUM_ITEMS_IN_LIST, SetupFunction, EqualityFunction, OnMaterialHorizonalScrollListShown, OnMaterialHorizonalScrollListCleared)
    self.materialList:SetNoItemText(GetString(SI_SMITHING_NO_MATERIALS_FOUND))
    self.materialList:SetScaleExtents(MIN_SCALE, MAX_SCALE)

    ZO_CraftingUtils_ConnectHorizontalScrollListToCraftingProcess(self.materialList)
end

function ZO_SharedSmithingCreation:InitializeStyleList(scrollListClass, styleUnknownFont, notEnoughInInventoryFont, listSlotTemplate)
    local listContainer = self.control:GetNamedChild("StyleList")
    listContainer.titleLabel:SetText(GetString(SI_SMITHING_HEADER_STYLE))

    local function SetupFunction(control, data, selected, selectedDuringRebuild, enabled)
        if self:IsInvalidMode() then return end

        SetupSharedSlot(control, SLOT_TYPE_SMITHING_STYLE, listContainer, self.styleList)
        ZO_ItemSlot_SetAlwaysShowStackCount(control, true)

        control.itemStyleId = data.itemStyleId
        local usesUniversalStyleItem = self:GetIsUsingUniversalStyleItem()
        local stackCount = GetCurrentSmithingStyleItemCount(data.itemStyleId)
        local hasEnoughInInventory = stackCount > 0
        local universalStyleItemCount = GetCurrentSmithingStyleItemCount(GetUniversalStyleId())
        local isStyleKnown = IsSmithingStyleKnown(data.itemStyleId, self:GetSelectedPatternIndex())
        ZO_ItemSlot_SetupSlot(control, stackCount, data.icon, isStyleKnown, not enabled)
        local stackCountLabel = GetControl(control, "StackCount")
        stackCountLabel:SetHidden(usesUniversalStyleItem)

        if selected then
            local hasStyleMaterial = (stackCount > 0 and not usesUniversalStyleItem) or (usesUniversalStyleItem and universalStyleItemCount > 0)
            local usable = hasStyleMaterial and isStyleKnown

            local extraInfoLabel = listContainer.extraInfoLabel
            self:SetLabelHidden(extraInfoLabel, false)

            if not isStyleKnown then
                extraInfoLabel:SetText(GetString(SI_SMITHING_UNKNOWN_STYLE))
                extraInfoLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
            else
                local text
                local name
                if usesUniversalStyleItem then
                    name = GetString(SI_SMITHING_UNIVERSAL_STYLE_ITEM_NAME)
                else
                    name = data.name
                end
                if usable then
                    text = zo_strformat(SI_SMITHING_MATERIAL_REQUIRED_SINGULAR, ZO_WHITE:Colorize("1"), name)
                    extraInfoLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
                else
                    text = zo_strformat(SI_SMITHING_MATERIAL_REQUIRED_SINGULAR, "1", name)
                    extraInfoLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
                end
                extraInfoLabel:SetText(text)
            end

            if not isStyleKnown then
                self.isStyleUsable = USABILITY_TYPE_VALID_BUT_MISSING_REQUIREMENT
            elseif not hasStyleMaterial then
                self.isStyleUsable = USABILITY_TYPE_VALID_BUT_MISSING_ITEM
            else
                self.isStyleUsable = USABILITY_TYPE_USABLE
            end

            if not data.localizedName then
                if data.itemStyleId == 0 then
                    data.localizedName = GetString(SI_CRAFTING_INVALID_ITEM_STYLE)
                else
                    if usesUniversalStyleItem then
                        data.localizedName = self:GetPlatformFormattedTextString(SI_CRAFTING_UNIVERSAL_STYLE_DESCRIPTION, GetItemStyleName(data.itemStyleId))
                    else
                        data.localizedName = self:GetPlatformFormattedTextString(SI_SMITHING_STYLE_DESCRIPTION, data.name, GetItemStyleName(data.itemStyleId))
                    end
                end
            end

            listContainer.selectedLabel:SetText(data.localizedName)

            self:SetLastListSelection(MEMORY_TYPE_STYLE, data.itemStyleId)

            if not selectedDuringRebuild and not self.performingFullRefresh then
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

    self.styleList = scrollListClass:New(listContainer.listControl, listSlotTemplate, BASE_NUM_ITEMS_IN_LIST, SetupFunction, EqualityFunction, OnHorizonalScrollListShown, OnHorizonalScrollListCleared)
    self.styleList:SetNoItemText(GetString(SI_SMITHING_NO_STYLE_FOUND))
    self.styleList:SetScaleExtents(MIN_SCALE, MAX_SCALE)

    self.styleList:SetOnSelectedDataChangedCallback(function(selectedData, oldData, selectedDuringRebuild)
        self:OnResultParametersChanged()
        self:OnStyleChanged(selectedData)
    end)

    ZO_CraftingUtils_ConnectHorizontalScrollListToCraftingProcess(self.styleList)
end

function ZO_SharedSmithingCreation:OnStyleChanged(selectedData)
    -- no additional functionality needed at the shared level
end

function ZO_SharedSmithingCreation:InitializeTraitList(scrollListClass, traitUnknownFont, notEnoughInInventoryFont, listSlotTemplate)
    local listContainer = self.control:GetNamedChild("TraitList")
    listContainer.titleLabel:SetText(GetString(SI_SMITHING_HEADER_TRAIT))
    listContainer.extraInfoLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())

    local function SetupFunction(control, data, selected, selectedDuringRebuild, enabled)
        if self:IsInvalidMode() then return end

        SetupSharedSlot(control, SLOT_TYPE_SMITHING_TRAIT, listContainer, self.traitList)
        ZO_ItemSlot_SetAlwaysShowStackCount(control, data.traitType ~= ITEM_TRAIT_TYPE_NONE)

        control.traitIndex = data.traitIndex
        control.traitType = data.traitType
        local stackCount = GetCurrentSmithingTraitItemCount(data.traitIndex)
        local hasEnoughInInventory = stackCount > 0
        local patternIndex = self:GetSelectedPatternIndex()
        local isTraitKnown = patternIndex ~= nil and IsSmithingTraitKnownForPattern(patternIndex, data.traitType)
        ZO_ItemSlot_SetupSlot(control, stackCount, data.icon, isTraitKnown, not enabled)

        if selected then
            local usable = data.traitType == ITEM_TRAIT_TYPE_NONE or (hasEnoughInInventory and isTraitKnown)
            local extraInfoLabel = listContainer.extraInfoLabel

            if data.traitType == ITEM_TRAIT_TYPE_NONE then
                self:SetLabelHidden(extraInfoLabel, true)
            else
                self:SetLabelHidden(extraInfoLabel, false)
                if not isTraitKnown then
                    extraInfoLabel:SetText(GetString(SI_SMITHING_TRAIT_MUST_BE_RESEARCHED))
                    extraInfoLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
                else
                    local text
                    if usable then
                        text = zo_strformat(SI_SMITHING_MATERIAL_REQUIRED_SINGULAR, ZO_WHITE:Colorize("1"), data.name)
                        extraInfoLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
                    else
                        text = zo_strformat(SI_SMITHING_MATERIAL_REQUIRED_SINGULAR, "1", data.name)
                        extraInfoLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
                    end
                    extraInfoLabel:SetText(text)
                end
            end

            if usable then
                self.isTraitUsable = USABILITY_TYPE_USABLE
            elseif not isTraitKnown then
                self.isTraitUsable = USABILITY_TYPE_VALID_BUT_MISSING_REQUIREMENT
            elseif not hasEnoughInInventory then
                self.isTraitUsable = USABILITY_TYPE_VALID_BUT_MISSING_ITEM
            else
                self.isTraitUsable = USABILITY_TYPE_INVALID
            end

            if not data.localizedName then
                if data.traitType == ITEM_TRAIT_TYPE_NONE then
                    data.localizedName = GetString("SI_ITEMTRAITTYPE", data.traitType)
                else
                    data.localizedName = self:GetPlatformFormattedTextString(SI_SMITHING_TRAIT_DESCRIPTION, data.name, GetString("SI_ITEMTRAITTYPE", data.traitType))
                end
            end

            listContainer.selectedLabel:SetText(data.localizedName)

            if not selectedDuringRebuild and not self.performingFullRefresh then
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

    self.traitList = scrollListClass:New(listContainer.listControl, listSlotTemplate, BASE_NUM_ITEMS_IN_LIST, SetupFunction, EqualityFunction, OnHorizonalScrollListShown, OnHorizonalScrollListCleared)
    self.traitList:SetScaleExtents(MIN_SCALE, MAX_SCALE)

    self.traitList:SetOnSelectedDataChangedCallback(function(selectedData, oldData, selectedDuringRebuild)
        self:OnResultParametersChanged()
    end)

    ZO_CraftingUtils_ConnectHorizontalScrollListToCraftingProcess(self.traitList)
end

local function IsSetPattern(patternData)
    return patternData.numTraitsRequired ~= 0
end

function ZO_SharedSmithingCreation:DoesPatternPassFilter(patternData)
    -- pattern filter needs to match current filter
    if ZO_CraftingUtils_GetItemFilterFromSmithingFilter(self.typeFilter) ~= patternData.resultingItemFilterType then
        return false
    end

    -- filter out set patterns
    if ZO_CraftingUtils_IsBaseSmithingFilter(self.typeFilter) then
        if IsSetPattern(patternData) then
            return false
        end
    else
        if not IsSetPattern(patternData) then
            return false
        end
    end

    if self.savedVars.haveKnowledgeChecked then
        if patternData.numTraitsKnown < patternData.numTraitsRequired then
            return false
        end
    end

    if self.savedVars.haveKnowledgeChecked or self.savedVars.haveMaterialChecked then
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
        if numMaterials > 0 then
            local patternData = { craftingType = GetCraftingInteractionType(), patternIndex = patternIndex, patternName = patternName, baseName = baseName, numTraitsRequired = numTraitsRequired, numTraitsKnown = numTraitsKnown, resultingItemFilterType = resultingItemFilterType }
            if self:DoesPatternPassFilter(patternData) then
                self.patternList:AddEntry(patternData)
            end
        end
    end

    self.patternList:Commit()
end

function ZO_SharedSmithingCreation:RefreshPatternList()
    self:CreatePatternList()

    self.patternList:SetNoItemText(GetString("SI_SMITHINGFILTERTYPE_CREATENOPATTERNS", self.typeFilter))
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
        local name, icon, stack, sellPrice, meetsUsageRequirement, equipType, itemStyle, quality, itemInstanceId, rankRequirement, createsItemOfLevel, isChampionPoint = GetSmithingPatternMaterialItemInfo(patternIndex, materialIndex)
        if instanceFilter[itemInstanceId] then
            local existingData = instanceFilter[itemInstanceId]
            existingData.min = zo_min(existingData.min, stack)
            existingData.minCreatesItemOfLevel = zo_min(existingData.minCreatesItemOfLevel, createsItemOfLevel)
            existingData.max = zo_max(existingData.max, stack)
            existingData.maxCreatesItemOfLevel = zo_max(existingData.maxCreatesItemOfLevel, createsItemOfLevel)
            table.insert(existingData.combinations,
            {
                stack = stack,
                createsItemOfLevel = createsItemOfLevel,
                isChampionPoint = isChampionPoint,
            })
        else
            --This data format assumes that a single material does not span from normal levels into champion ranks
            local data =
            {
                craftingType = GetCraftingInteractionType(),
                patternIndex = patternIndex,
                materialIndex = materialIndex,
                name = name,
                icon = icon,
                quality = quality,
                rankRequirement = rankRequirement,
                min = stack,
                max = stack,
                minCreatesItemOfLevel = createsItemOfLevel,
                maxCreatesItemOfLevel = createsItemOfLevel,
                isChampionPoint = isChampionPoint,
                combinations =
                {
                    {
                        stack = stack,
                        createsItemOfLevel = createsItemOfLevel,
                        isChampionPoint = isChampionPoint,
                    }
                }
            }
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
    local oldSelectedMaterial = self:GetLastListSelection(MEMORY_TYPE_MATERIAL)

    self.materialList:Clear()

    if patternData then
        patternData.materialData = patternData.materialData or self:GenerateMaterialDataForPattern(patternData.patternIndex)

        for itemInstanceId, data in pairs(patternData.materialData) do
            self.materialList:AddEntry(data)
        end
    end

    self.materialList:Commit()

    local initialListIndex = 0
    if oldSelectedMaterial then
        local index = self.materialList:FindIndexFromData(oldSelectedMaterial, function(oldData, newData)
            return oldData.isChampionPoint == newData.isChampionPoint and oldData.minCreatesItemOfLevel == newData.minCreatesItemOfLevel
        end)

        if index then
            initialListIndex = index
        end
    end
    local ALLOW_EVEN_IF_DISABLED = true
    local SKIP_ANIMATION = true
    self.materialList:SetSelectedIndex(initialListIndex, ALLOW_EVEN_IF_DISABLED, SKIP_ANIMATION)
end

function ZO_SharedSmithingCreation:DoesStylePassFilter(itemStyleId, alwaysHideIfLocked)
    if self:ShouldIgnoreStyleItems() then
        internalassert(false)
        return false -- always fail, if you don't have use style items you shouldn't be running this code
    end

    if self.savedVars.haveKnowledgeChecked or alwaysHideIfLocked then
        if not IsSmithingStyleKnown(itemStyleId, self:GetSelectedPatternIndex()) then
            return false
        end
    end

    if self.savedVars.haveMaterialChecked then
        if GetCurrentSmithingStyleItemCount(itemStyleId) == 0 and not self:GetIsUsingUniversalStyleItem() then
            return false
        end
    end

    if itemStyleId == GetUniversalStyleId() then
        return false
    end

    local patternData = self.patternList:GetSelectedData()

    if patternData then
        patternData.materialData = patternData.materialData or self:GenerateMaterialDataForPattern(patternData.patternIndex)

        if #patternData.materialData == 0 then
            return false
        end

        if not CanSmithingStyleBeUsedOnPattern(itemStyleId, self:GetSelectedPatternIndex(), patternData.materialData[1].materialIndex, patternData.materialData[1].min) then
            return false
        end
    end

    return true
end

local STYLE_LIST_USI_BG_STANDARD_ALPHA = 0.35
local STYLE_LIST_USI_BG_LOW_ALPHA = 0.21
function ZO_SharedSmithingCreation:RefreshStyleList()
    local lastItemStyleId = self:GetLastListSelection(MEMORY_TYPE_STYLE)

    self.styleList:Clear()

    if not self:ShouldIgnoreStyleItems() then
        local craftingInteractionType = GetCraftingInteractionType()
        for itemStyleIndex = 1, GetNumValidItemStyles() do
            local validItemStyleId = GetValidItemStyleId(itemStyleIndex)
            if validItemStyleId > 0 then
                local styleItemLink = GetItemStyleMaterialLink(validItemStyleId)
                local alwaysHideIfLocked = GetItemStyleInfo(validItemStyleId)
                local name = GetItemLinkName(styleItemLink)
                local icon, sellPrice, meetsUsageRequirement = GetItemLinkInfo(styleItemLink)
                if meetsUsageRequirement and self:DoesStylePassFilter(validItemStyleId, alwaysHideIfLocked) then
                    self.styleList:AddEntry({ craftingType = craftingInteractionType, itemStyleId = validItemStyleId, name = name, icon = icon })
                end
            end
        end
    end

    self.styleList:Commit()

    local initialListIndex = 0
    if lastItemStyleId then
        local index = self.styleList:FindIndexFromData(lastItemStyleId, function(oldStyleItemId, newStyleData)
            return oldStyleItemId == newStyleData.itemStyleId
        end)

        if index then
            initialListIndex = index
        end
    end
    local ALLOW_EVEN_IF_DISABLED = true
    local SKIP_ANIMATION = true
    self.styleList:SetSelectedIndex(initialListIndex, ALLOW_EVEN_IF_DISABLED, SKIP_ANIMATION)

    local styleListControl = self.control:GetNamedChild("StyleList")
    if self:GetIsUsingUniversalStyleItem() then
        local universalItemBg = styleListControl.universalItemBg
        universalItemBg:SetHidden(false)
        if GetCurrentSmithingStyleItemCount(GetUniversalStyleId()) == 0 then
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

function ZO_SharedSmithingCreation:DoesTraitPassFilter(traitIndex, traitType, craftingType, typeFilter, patternIndex)
    if ZO_CraftingUtils_GetSmithingFilterFromTrait(traitType) ~= ZO_CraftingUtils_GetBaseSmithingFilter(typeFilter) then
        return false
    end

    if self.savedVars.haveKnowledgeChecked then
        if patternIndex == nil or not IsSmithingTraitKnownForPattern(patternIndex, traitType) then
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

function ZO_SharedSmithingCreation:RefreshTraitList(patternData)
    local patternIndex = nil
    if patternData then
        patternIndex = patternData.patternIndex
    end

    self.traitList:Clear()

    local traitItems = ZO_CraftingUtils_GetSmithingTraitItemInfo()
    for _, traitItemInfo in ipairs(traitItems) do
        local craftingType = GetCraftingInteractionType()
        if traitItemInfo.type == ITEM_TRAIT_TYPE_NONE then
            self.traitList:AddEntry({
                craftingType = craftingType,
                traitIndex = traitItemInfo.index,
                traitType = traitItemInfo.type,
                icon = "EsoUI/Art/Crafting/crafting_smithing_noTrait.dds",
            })
        elseif self:DoesTraitPassFilter(traitItemInfo.index, traitItemInfo.type, craftingType, self.typeFilter, patternIndex) then
            self.traitList:AddEntry({
                craftingType = craftingType,
                traitIndex = traitItemInfo.index,
                traitType = traitItemInfo.type,
                icon = traitItemInfo.icon,
                name = traitItemInfo.name,
                quality = traitItemInfo.quality,
            })
        end
    end

    self.traitList:Commit()
end

function ZO_SharedSmithingCreation:OnResultParametersChanged()
    self:DirtyResult()
end

function ZO_SharedSmithingCreation:RefreshTooltip()
    if self:AreSelectionsValid() then
        self.resultTooltip:SetHidden(false)
        self.resultTooltip:ClearLines()
        self:SetupResultTooltip(self:GetResultCraftingParameters())
    else
        self.resultTooltip:SetHidden(true)
    end
end

function ZO_SharedSmithingCreation:GetPatternUsability()
    if self:GetSelectedPatternIndex() then
        return self.isPatternUsable
    end
    return USABILITY_TYPE_INVALID
end

function ZO_SharedSmithingCreation:GetMaterialUsability()
    if self:GetSelectedMaterialIndex() then
        return self.isMaterialUsable
    end
    return USABILITY_TYPE_INVALID
end

function ZO_SharedSmithingCreation:GetStyleUsability()
    if self:ShouldIgnoreStyleItems() then
        return USABILITY_TYPE_USABLE
    end
    if self:GetSelectedItemStyleId() then
        return self.isStyleUsable
    end
    return USABILITY_TYPE_INVALID
end

function ZO_SharedSmithingCreation:GetTraitUsability()
    if self:GetSelectedTraitIndex() then
        return self.isTraitUsable
    end
    return USABILITY_TYPE_INVALID
end

function ZO_SharedSmithingCreation:AreSelectionsValid()
    return self:GetPatternUsability() ~= USABILITY_TYPE_INVALID and self:GetMaterialUsability() ~= USABILITY_TYPE_INVALID and self:GetStyleUsability() ~= USABILITY_TYPE_INVALID and self:GetTraitUsability() ~= USABILITY_TYPE_INVALID
end

-- Overrides ZO_CraftingCreateScreenBase
function ZO_SharedSmithingCreation:IsCraftable()
    return self:GetPatternUsability() == USABILITY_TYPE_USABLE and self:GetMaterialUsability() == USABILITY_TYPE_USABLE and self:GetStyleUsability() and self:GetTraitUsability() == USABILITY_TYPE_USABLE
end

function ZO_SharedSmithingCreation:IsCraftingNonSetItemAtSetStation()
    return CanSmithingSetPatternsBeCraftedHere() and not IsSetPattern(self.patternList:GetSelectedData())
end

function ZO_SharedSmithingCreation:ShouldCraftButtonBeEnabled()
    if ZO_CraftingUtils_IsPerformingCraftProcess() then
        return false
    end

    local patternUsability = self:GetPatternUsability()
    if patternUsability == USABILITY_TYPE_INVALID then
        return false, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_INVALID_PATTERN)
    elseif patternUsability == USABILITY_TYPE_VALID_BUT_MISSING_REQUIREMENT then
        return false, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_FAIL_PATTERN_REQUIREMENTS)
    end

    local materialUsability = self:GetMaterialUsability()
    if materialUsability == USABILITY_TYPE_INVALID then
        return false, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_INVALID_MATERIAL)
    elseif materialUsability == USABILITY_TYPE_VALID_BUT_MISSING_REQUIREMENT then
        return false, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_FAIL_MATERIAL_REQUIREMENTS)
    elseif materialUsability == USABILITY_TYPE_VALID_BUT_MISSING_ITEM then
        return false, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_NEEDS_SMITHING_MATERIAL)
    end

    local styleUsability = self:GetStyleUsability()
    if styleUsability == USABILITY_TYPE_INVALID then
        return false, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_INVALID_STYLE_MATERIAL)
    elseif styleUsability == USABILITY_TYPE_VALID_BUT_MISSING_REQUIREMENT then
        return false, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_MUST_LEARN_STYLE)
    elseif styleUsability == USABILITY_TYPE_VALID_BUT_MISSING_ITEM then
        return false, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_NEEDS_STYLE_MATERIAL)
    end

    local traitUsability = self:GetTraitUsability()
    if traitUsability == USABILITY_TYPE_INVALID then
        return false, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_INVALID_TRAIT_MATERIAL)
    elseif traitUsability == USABILITY_TYPE_VALID_BUT_MISSING_REQUIREMENT then
        return false, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_MUST_LEARN_TRAIT)
    elseif traitUsability == USABILITY_TYPE_VALID_BUT_MISSING_ITEM then
        return false, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_NEEDS_TRAIT_MATERIAL)
    end

    local numIterations, craftingResult = GetMaxIterationsPossibleForSmithingItem(self:GetCraftingParametersWithoutIterations())
    return numIterations ~= 0, GetString("SI_TRADESKILLRESULT", craftingResult)
end

-- Overrides ZO_CraftingCreateScreenBase
function ZO_SharedSmithingCreation:Create(numIterations)
    if self:IsCraftingNonSetItemAtSetStation() then
        local craftingParams = {self:GetAllCraftingParameters(numIterations)}
        local resultItemLink = GetSmithingPatternResultLink(self:GetResultCraftingParameters())
        ZO_Dialogs_ShowPlatformDialog("CONFIRM_CREATE_NONSET_ITEM", {craftingParams = craftingParams}, {mainTextParams = {resultItemLink}})
    else
        CraftSmithingItem(self:GetAllCraftingParameters(numIterations))
    end
end

function ZO_SharedSmithingCreation:GetUniversalStyleItemLink()
    return GetItemStyleMaterialLink(GetUniversalStyleId())
end

function ZO_SharedSmithingCreation:TriggerUSITutorial()
    if self:ShouldIgnoreStyleItems() then
        return
    end
    local universalStyleItemCount = GetCurrentSmithingStyleItemCount(GetUniversalStyleId())
    if universalStyleItemCount > 0 then
        TriggerTutorial(TUTORIAL_TRIGGER_UNIVERSAL_STYLE_ITEM)
    end
end

function ZO_SharedSmithingCreation:GetMultiCraftMaxIterations()
    -- throw away second argument
    local numIterations = GetMaxIterationsPossibleForSmithingItem(self:GetCraftingParametersWithoutIterations())
    return numIterations
end

function ZO_SharedSmithingCreation:GetResultItemLink()
    return GetSmithingPatternResultLink(self:GetResultCraftingParameters())
end

function ZO_SharedSmithingCreation:GetMultiCraftNumResults(numIterations)
    return numIterations -- each iteration creates one item
end

function ZO_SharedSmithingCreation:RefreshMultiCraft()
    -- Should be overidden
end

function ZO_SharedSmithingCreation:UpdateKeybindStrip()
    -- Should be overidden
end