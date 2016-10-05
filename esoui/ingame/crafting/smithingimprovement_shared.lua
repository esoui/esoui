-- Shared globals

ZO_SMITHING_IMPROVEMENT_SHARED_FILTER_TYPE_ARMOR = 1
ZO_SMITHING_IMPROVEMENT_SHARED_FILTER_TYPE_WEAPONS = 2

-- Shared object class

ZO_SharedSmithingImprovement = ZO_Object:Subclass()

function ZO_SharedSmithingImprovement:New(...)
    local smithingImprovement = ZO_Object.New(self)
    smithingImprovement:Initialize(...)
    return smithingImprovement
end

function ZO_SharedSmithingImprovement:Initialize(listControl, boosterContainerControl, resultTooltipControl, owner)
    self.owner = owner

    self.listControl = listControl
	self.resultTooltip = resultTooltipControl
    self.boosterContainer = boosterContainerControl

	self:InitializeSlots()
    self:InitializeRows()

    self:HandleDirtyEvent()
end

function ZO_SharedSmithingImprovement:InitializeRows()
    self.rows = {}

    self.boosterHeaderLabel = self.boosterContainer:GetNamedChild("Header")

    local currentAnchor = ZO_Anchor:New(TOPLEFT, self.boosterContainer)

    local function InitializeRow(row, from, to)
        row.fromLabel = self.boosterContainer:GetNamedChild(from)
        row.toLabel = self.boosterContainer:GetNamedChild(to)

        row.fadeAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("SmithingImprovementBoosterFade", row)

        row.iconTexture = row:GetNamedChild("Icon")
        row.stackLabel = row.iconTexture:GetNamedChild("StackCount")
        return row
    end

    self.rows = {
        InitializeRow(self.boosterContainer:GetNamedChild("NormalToFine"), "Normal", "Fine"),
        InitializeRow(self.boosterContainer:GetNamedChild("FineToSuperior"), "Fine", "Superior"),
        InitializeRow(self.boosterContainer:GetNamedChild("SuperiorToEpic"), "Superior", "Epic"),
        InitializeRow(self.boosterContainer:GetNamedChild("EpicToLegendary"), "Epic", "Legendary"),
    }

    for i, row in ipairs(self.rows) do
        row.index = i
    end

    local function InitializeQualityLabel(label, quality)
        label:SetText(GetString("SI_ITEMQUALITY", quality))
        label:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality))
        label.fadeAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("SmithingImprovementBoosterFade", label)
    end

    InitializeQualityLabel(self.boosterContainer:GetNamedChild("Normal"), ITEM_QUALITY_NORMAL)
    InitializeQualityLabel(self.boosterContainer:GetNamedChild("Fine"), ITEM_QUALITY_MAGIC)
    InitializeQualityLabel(self.boosterContainer:GetNamedChild("Superior"), ITEM_QUALITY_ARCANE)
    InitializeQualityLabel(self.boosterContainer:GetNamedChild("Epic"), ITEM_QUALITY_ARTIFACT)
    InitializeQualityLabel(self.boosterContainer:GetNamedChild("Legendary"), ITEM_QUALITY_LEGENDARY)
end

function ZO_SharedSmithingImprovement:HandleDirtyEvent()
    if self.listControl:IsHidden() then
        self.dirty = true
    else
        self:Refresh()
    end
end

function ZO_SharedSmithingImprovement:SetCraftingType(craftingType, oldCraftingType, isCraftingTypeDifferent)
    if isCraftingTypeDifferent then
        local chartString = ZO_SharedSmithingImprovement_GetBoosterChartStringForCraftingType(craftingType)
        self.boosterHeaderLabel:SetText(chartString)
    end

    self.improvementSlot:SetItem(nil)
    self.inventory:HandleDirtyEvent()
end

function ZO_SharedSmithingImprovement:Refresh()
    self.dirty = false

    for i, row in ipairs(self.rows) do
        local reagentName, icon, stack, _, _, _, _, quality = GetSmithingImprovementItemInfo(GetCraftingInteractionType(), i)
        row.reagentName = reagentName
        row.currentStack = stack
        row.quality = quality
        row.icon = icon

        row.stackLabel:SetText(stack)
        if stack == 0 then
            row.stackLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
        else
            row.stackLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        end
        row.iconTexture:SetTexture(icon)
    end
end

function ZO_SharedSmithingImprovement:GetBoosterRowForQuality(quality)
    for i, row in ipairs(self.rows) do
        if row.quality - 1 == quality then
            return row
        end
    end
end

function ZO_SharedSmithingImprovement:OnInventoryUpdate(validItemIds)
    self.improvementSlot:ValidateItemId(validItemIds)
    self:OnSlotChanged()
end

function ZO_SharedSmithingImprovement:ShowAppropriateSlotDropCallouts()
    self.improvementSlot:ShowDropCallout()
end

function ZO_SharedSmithingImprovement:HideAllSlotDropCallouts()
    self.improvementSlot:HideDropCallout()
end

function ZO_SharedSmithingImprovement:FindMaxBoostersToApply()
    local numBoostersToApply = 0
    local itemToImproveBagId, itemToImproveSlotIndex, craftingType = self:GetCurrentImprovementParams()

    repeat
        numBoostersToApply = numBoostersToApply + 1
        local chance = GetSmithingImprovementChance(itemToImproveBagId, itemToImproveSlotIndex, numBoostersToApply, craftingType)
    until chance >= 100.0 or numBoostersToApply == 1000

    return numBoostersToApply
end

function ZO_SharedSmithingImprovement:GetRowForSelection()
    if self.improvementSlot:HasItem() then
        local quality = select(8, GetItemInfo(self.improvementSlot:GetBagAndSlot()))
        return self:GetBoosterRowForQuality(quality)
    end
end

function ZO_SharedSmithingImprovement:GetCurrentImprovementParams()
    if self.improvementSlot:HasItem() then
        local bagId, slotIndex = self.improvementSlot:GetBagAndSlot()
        return bagId, slotIndex, GetCraftingInteractionType()
    end
end

function ZO_SharedSmithingImprovement:RefreshImprovementChance()
    if self.improvementSlot:HasItem() and self.currentQuality then
        local itemToImproveBagId, itemToImproveSlotIndex, craftingType = self:GetCurrentImprovementParams()
        local numBoostersToApply = self:GetNumBoostersToApply()
        local chance = GetSmithingImprovementChance(itemToImproveBagId, itemToImproveSlotIndex, numBoostersToApply, craftingType)

        self.improvementChanceLabel:SetText(zo_strformat(SI_SMITHING_IMPROVE_CHANCE_FORMAT, chance))

        local row = self:GetBoosterRowForQuality(self.currentQuality)
        self.canImprove = numBoostersToApply <= row.currentStack
    end

    self.owner:OnImprovementSlotChanged()
end

function ZO_SharedSmithingImprovement:GetNumBoostersToApply()
    return self.spinner:GetValue()
end

function ZO_SharedSmithingImprovement:IsItemAlreadySlottedToCraft(bagId, slotIndex)
    return self.improvementSlot:IsItemId(GetItemInstanceId(bagId, slotIndex))
end

function ZO_SharedSmithingImprovement:CanItemBeAddedToCraft(bagId, slotIndex)
    return true -- currently no requirements to meet before being able to improve
end

function ZO_SharedSmithingImprovement:AddItemToCraft(bagId, slotIndex)
    self:SetImprovementSlotItem(bagId, slotIndex)
end

function ZO_SharedSmithingImprovement:RemoveItemFromCraft(bagId, slotIndex)
    self:ClearSelections()
end

function ZO_SharedSmithingImprovement:SetImprovementSlotItem(bagId, slotIndex)
    self.improvementSlot:SetItem(bagId, slotIndex)

    self:OnSlotChanged()
end

function ZO_SharedSmithingImprovement:OnFilterChanged(filterType)
	if self.awaitingLabel then
		if filterType == ZO_SMITHING_IMPROVEMENT_SHARED_FILTER_TYPE_ARMOR then
			self.awaitingLabel:SetText(GetString(SI_SMITHING_IMPROVE_AWAITING_ARMOR))
		elseif filterType == ZO_SMITHING_IMPROVEMENT_SHARED_FILTER_TYPE_WEAPONS then
			self.awaitingLabel:SetText(GetString(SI_SMITHING_IMPROVE_AWAITING_WEAPON))
		end
	end

    self.improvementSlot:OnFilterChanged(filterType)
end

function ZO_SharedSmithingImprovement:IsImprovable()
    return self.canImprove
end

function ZO_SharedSmithingImprovement:HasSelections()
    return self.improvementSlot:HasItem()
end

function ZO_SharedSmithingImprovement:ClearSelections()
    self:SetImprovementSlotItem(nil)
end

function ZO_SharedSmithingImprovement:IsSlotted(bagId, slotIndex)
    return self.improvementSlot:IsBagAndSlot(bagId, slotIndex)
end

function ZO_SharedSmithingImprovement:SharedImprove(dialogName)
	if IsPerformingCraftProcess() then
        -- Handle edge case where player hits R and E at the same time.
        return
    end

    local itemToImproveBagId, itemToImproveSlotIndex, craftingType = self:GetCurrentImprovementParams()
    local numBoostersToApply = self:GetNumBoostersToApply()

    local chance = GetSmithingImprovementChance(itemToImproveBagId, itemToImproveSlotIndex, numBoostersToApply, craftingType)
    local improveItemLink = GetItemLink(itemToImproveBagId, itemToImproveSlotIndex)
    local boosterName = GetSmithingImprovementItemLink(craftingType, self:GetBoosterRowForQuality(self.currentQuality).index)

    local function ShowImprovementDialog()
        ZO_Dialogs_ShowPlatformDialog(dialogName, { bagId = itemToImproveBagId, slotIndex = itemToImproveSlotIndex, boostersToApply = numBoostersToApply }, {mainTextParams = { chance, improveItemLink, numBoostersToApply, boosterName}})
    end

	if IsItemBoPAndTradeable(itemToImproveBagId, itemToImproveSlotIndex) then
        ZO_Dialogs_ShowPlatformDialog("CONFIRM_MODIFY_TRADE_BOP", {onAcceptCallback = ShowImprovementDialog}, {mainTextParams={GetItemName(itemToImproveBagId, itemToImproveSlotIndex)}})
    else
        ShowImprovementDialog()
    end
end

-- Crafting slot

ZO_SmithingImprovementSlot = ZO_CraftingSlotBase:Subclass()

function ZO_SmithingImprovementSlot:New(...)
    return ZO_CraftingSlotBase.New(self, ...)
end

function ZO_SmithingImprovementSlot:Initialize(owner, control, slotType, craftingInventory)
    ZO_CraftingSlotBase.Initialize(self, owner, control, slotType, "", craftingInventory)

    self.nameLabel = control:GetNamedChild("Name")
end

function ZO_SmithingImprovementSlot:SetItem(bagId, slotIndex)
    local hadItem = self:HasItem()
    local oldItemInstanceId = self:GetItemId()

    self:SetupItem(bagId, slotIndex)

    if self:HasItem() then
        if oldItemInstanceId ~= self:GetItemId() then
            self.owner.spinner:SetValue(1)
            PlaySound(SOUNDS.SMITHING_ITEM_TO_IMPROVE_PLACED)
        end
    elseif hadItem then
        PlaySound(SOUNDS.SMITHING_ITEM_TO_IMPROVE_REMOVED)
    end

    if self.nameLabel then
        if self:HasItem() then
            self.nameLabel:SetHidden(false)
            self.nameLabel:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(bagId, slotIndex)))

            local quality = select(8, GetItemInfo(bagId, slotIndex))
            self.nameLabel:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality))
        else
            self.nameLabel:SetHidden(true)
        end
    end
end

function ZO_SmithingImprovementSlot:OnFilterChanged(filterType)
    if filterType == ZO_SMITHING_IMPROVEMENT_SHARED_FILTER_TYPE_ARMOR then
        self:SetEmptyTexture("EsoUI/Art/Crafting/smithing_armorSlot.dds")
    elseif filterType == ZO_SMITHING_IMPROVEMENT_SHARED_FILTER_TYPE_WEAPONS then
        self:SetEmptyTexture("EsoUI/Art/Crafting/smithing_weaponSlot.dds")
    end
end

function ZO_SmithingImprovementSlot:ShowDropCallout()
    self.dropCallout:SetHidden(false)
    self.dropCallout:SetTexture("EsoUI/Art/Crafting/crafting_alchemy_goodSlot.dds")
end

-- Shared helper functions (formerly local to the PC version)

function ZO_SharedSmithingImprovement_GetBoosterChartStringForCraftingType(craftingType)
    if craftingType == CRAFTING_TYPE_BLACKSMITHING then
        return GetString(SI_SMITHING_BLACKSMITH_BOOSTER_CHART)
    elseif craftingType == CRAFTING_TYPE_CLOTHIER then
        return GetString(SI_SMITHING_CLOTHIER_BOOSTER_CHART)
    elseif craftingType == CRAFTING_TYPE_WOODWORKING then
        return GetString(SI_SMITHING_WOODWORKING_BOOSTER_CHART)
    end
end

function ZO_SharedSmithingImprovement_GetImprovementTooltipSounds()
    local craftingType = GetCraftingInteractionType()
    if craftingType == CRAFTING_TYPE_BLACKSMITHING then
        return SOUNDS.BLACKSMITH_IMPROVE_TOOLTIP_GLOW_SUCCESS, SOUNDS.BLACKSMITH_IMPROVE_TOOLTIP_GLOW_FAIL
    elseif craftingType == CRAFTING_TYPE_CLOTHIER then
        return SOUNDS.CLOTHIER_IMPROVE_TOOLTIP_GLOW_SUCCESS, SOUNDS.CLOTHIER_IMPROVE_TOOLTIP_GLOW_FAIL
    elseif craftingType == CRAFTING_TYPE_WOODWORKING then
        return SOUNDS.WOODWORKER_IMPROVE_TOOLTIP_GLOW_SUCCESS, SOUNDS.WOODWORKER_IMPROVE_TOOLTIP_GLOW_FAIL
    end
end

function ZO_SharedSmithingImprovement_CanItemBeImproved(bagId, slotIndex)
    return CanItemBeSmithingImproved(bagId, slotIndex, GetCraftingInteractionType())
end

function ZO_SharedSmithingImprovement_GetPrimaryFilterType(...)
    for i = 1, select("#", ...) do
        local filterType = select(i, ...)
        if filterType == ITEMFILTERTYPE_WEAPONS then
            return ZO_SMITHING_IMPROVEMENT_SHARED_FILTER_TYPE_WEAPONS
        elseif filterType == ITEMFILTERTYPE_ARMOR then 
            return ZO_SMITHING_IMPROVEMENT_SHARED_FILTER_TYPE_ARMOR
        end
    end
end

function ZO_SharedSmithingImprovement_DoesItemPassFilter(bagId, slotIndex, filterType)
    return ZO_SharedSmithingImprovement_GetPrimaryFilterType(GetItemFilterTypeInfo(bagId, slotIndex)) == filterType and not IsItemPlayerLocked(bagId, slotIndex)
end