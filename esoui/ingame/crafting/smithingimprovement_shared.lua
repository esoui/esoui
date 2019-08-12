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
    self:InitializeBoosterRows()

    self:HandleDirtyEvent()
end

function ZO_SharedSmithingImprovement:InitializeBoosterRows()
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

function ZO_SharedSmithingImprovement:RefreshBoosterRows()
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
    if ZO_CraftingUtils_IsPerformingCraftProcess() then
        -- Don't update improvement panel until the animation is complete: ESO-556307
        return
    end
    self.dirty = false

    self:OnSlotChanged()
end

function ZO_SharedSmithingImprovement:OnSlotChanged()
    self:RefreshBoosterRows(self)
    self.currentQuality = nil

    local hasItem = self.improvementSlot:HasItem()
    if hasItem then
        local row = self:GetRowForSelection()
        if row then
            local maxBoosters = self:FindMaxBoostersToApply()
            self.spinner:SetMinMax(1, maxBoosters)
            self.spinner:SetValue(maxBoosters)
            self.spinner:SetSoftMax(row.currentStack)

            self.currentQuality = row.quality - 1 -- need the "from" quality

            self.boosterSlot.craftingType = GetCraftingInteractionType()
            self.boosterSlot.index = row.index

            ZO_ItemSlot_SetupSlot(self.boosterSlot, row.currentStack, row.icon)
            self:RefreshImprovementChance()
        else
            self:ClearSelections()
            return
        end
    else
        self.canImprove = false

        self.improvementChanceLabel:SetText(GetString(SI_SMITHING_IMPROVE_CHANCE_HEADER))
        self:ClearBoosterRowHighlight()

        self.owner:OnImprovementSlotChanged()
    end

    self.boosterSlot:SetHidden(not hasItem)

    if hasItem then
        self.resultTooltip:SetHidden(false)
        self:SetupResultTooltip(self:GetCurrentImprovementParams())
    else
        self.resultTooltip:SetHidden(true)
    end
end

function ZO_SharedSmithingImprovement:GetBoosterRowForQuality(quality)
    for i, row in ipairs(self.rows) do
        if row.quality - 1 == quality then
            return row
        end
    end
end

function ZO_SharedSmithingImprovement:OnInventoryUpdate(validItems)
    self.improvementSlot:ValidateSlottedItem(validItems)
    self:Refresh()
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

        chance = zo_roundToNearest(chance, .1)

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
end

function ZO_SharedSmithingImprovement:OnFilterChanged(filterType)
    if self.awaitingLabel then
        self.awaitingLabel:SetText(GetString("SI_SMITHINGFILTERTYPE_IMPROVEAWAITING", filterType))
    end
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

function ZO_SharedSmithingImprovement:Improve()
    if ZO_CraftingUtils_IsPerformingCraftProcess() then
        -- Handle edge case where player hits R and E at the same time.
        return
    end

    local itemToImproveBagId, itemToImproveSlotIndex, craftingType = self:GetCurrentImprovementParams()
    local numBoostersToApply = self:GetNumBoostersToApply()

    local isItemLocked = IsItemPlayerLocked(itemToImproveBagId, itemToImproveSlotIndex)

    local chance = GetSmithingImprovementChance(itemToImproveBagId, itemToImproveSlotIndex, numBoostersToApply, craftingType)
    if isItemLocked and chance < 100 then
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, GetString(SI_CRAFTING_ALERT_CANT_IMPROVE_LOCKED_ITEM))
        return
    end

    local improveItemLink = GetItemLink(itemToImproveBagId, itemToImproveSlotIndex)
    local dialogName = "CONFIRM_IMPROVE_ITEM"
    if isItemLocked then
        if IsInGamepadPreferredMode() then
            dialogName = "GAMEPAD_CONFIRM_IMPROVE_LOCKED_ITEM"
        else
            dialogName = "CONFIRM_IMPROVE_LOCKED_ITEM"
        end
    end

    local function ShowImprovementDialog()
        ZO_Dialogs_ShowPlatformDialog(dialogName, { bagId = itemToImproveBagId, slotIndex = itemToImproveSlotIndex, boostersToApply = numBoostersToApply, chance = chance, }, {mainTextParams = { chance, improveItemLink, GetString(SI_PERFORM_ACTION_CONFIRMATION)}})
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
            PlaySound(SOUNDS.SMITHING_ITEM_TO_IMPROVE_PLACED)
        end
    elseif hadItem then
        PlaySound(SOUNDS.SMITHING_ITEM_TO_IMPROVE_REMOVED)
    end
end

function ZO_SmithingImprovementSlot:Refresh()
    ZO_CraftingSlotBase.Refresh(self)

    if self.nameLabel then
        if self:HasItem() then
            self.nameLabel:SetHidden(false)
            self.nameLabel:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(self:GetBagAndSlot())))

            local quality = select(8, GetItemInfo(self:GetBagAndSlot()))
            self.nameLabel:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality))
        else
            self.nameLabel:SetHidden(true)
        end
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
    elseif craftingType == CRAFTING_TYPE_JEWELRYCRAFTING then
        return GetString(SI_SMITHING_JEWELRYCRAFTING_BOOSTER_CHART)
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
    elseif craftingType == CRAFTING_TYPE_JEWELRYCRAFTING then
        return SOUNDS.JEWELRYCRAFTER_IMPROVE_TOOLTIP_GLOW_SUCCESS, SOUNDS.JEWELRYCRAFTER_IMPROVE_TOOLTIP_GLOW_FAIL
    end
end

function ZO_SharedSmithingImprovement_CanItemBeImproved(itemData)
    return CanItemBeSmithingImproved(itemData.bagId, itemData.slotIndex, GetCraftingInteractionType())
end

function ZO_SharedSmithingImprovement_DoesItemPassFilter(bagId, slotIndex, filterType)
    return ZO_CraftingUtils_GetSmithingFilterFromItem(bagId, slotIndex) == filterType
end