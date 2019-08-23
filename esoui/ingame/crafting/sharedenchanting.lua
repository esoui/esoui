ZO_SharedEnchanting = ZO_CraftingCreateScreenBase:Subclass()

function ZO_SharedEnchanting:New(...)
    local enchanting = ZO_CraftingCreateScreenBase.New(self)
    enchanting:Initialize(...)
    return enchanting
end

ENCHANTING_MODE_NONE = 0
ENCHANTING_MODE_CREATION = 1
ENCHANTING_MODE_EXTRACTION = 2
ENCHANTING_MODE_RECIPES = 3

NO_FILTER = -1
EXTRACTION_FILTER = -2

function ZO_Enchanting_IsSceneShowing()
    if ENCHANTING and ENCHANTING:CanShowScene() then
        return ENCHANTING:IsSceneShowing()
    elseif GAMEPAD_ENCHANTING:CanShowScene() then
        return GAMEPAD_ENCHANTING:IsSceneShowing()
    end
    return false
end

function ZO_Enchanting_GetVisibleEnchanting()
    if ENCHANTING and ENCHANTING:IsSceneShowing() then
        return ENCHANTING
    else
        return GAMEPAD_ENCHANTING
    end
end

function ZO_Enchanting_IsInCreationMode()
    if ENCHANTING and ENCHANTING:IsSceneShowing() and ENCHANTING:GetEnchantingMode() == ENCHANTING_MODE_CREATION then
        return true
    elseif SCENE_MANAGER:IsShowing("gamepad_enchanting_creation") then
        return true
    end

    return false
end

function ZO_SharedEnchanting:Initialize(control)
    self.control = control
    self.skillInfo = self.control:GetNamedChild("SkillInfo")

    self:InitializeInventory()

    self:InitializeCreationSlots()
    self:InitializeExtractionSlots()
    self:InitializeKeybindStripDescriptors()
    self:InitializeModes()

    ZO_Skills_TieSkillInfoHeaderToCraftingSkill(self.skillInfo, CRAFTING_TYPE_ENCHANTING)

    self:InitializeEnchantingScenes()

    assert(self.mainSceneName, "Inheriting Enchanting class requires a mainSceneName")
end

function ZO_SharedEnchanting:InitializeInventory()
    -- override me
end

function ZO_SharedEnchanting:InitializeModes()
    -- override me
end

function ZO_SharedEnchanting:InitializeEnchantingScenes()
    self.control:RegisterForEvent(EVENT_CRAFTING_STATION_INTERACT, function(eventCode, craftingType, isCraftingSameAsPrevious)
    if craftingType == CRAFTING_TYPE_ENCHANTING then
            if not isCraftingSameAsPrevious then
                self:ResetSelectedTab()
            end
            if self:CanShowScene() then
                SCENE_MANAGER:Show(self.mainSceneName)
            end
        end
    end)

    self.control:RegisterForEvent(EVENT_END_CRAFTING_STATION_INTERACT, function(eventCode, craftingType)
        if craftingType == CRAFTING_TYPE_ENCHANTING then
            SCENE_MANAGER:Hide(self.mainSceneName)
        end
    end)
end

function ZO_SharedEnchanting:InitializeCreationSlots()
    -- override me
end

function ZO_SharedEnchanting:InitializeExtractionSlots()
    assert(false) -- override in derived classes
end

function ZO_SharedEnchanting:InitializeKeybindStripDescriptors()
end

function ZO_SharedEnchanting:ResetSelectedTab()
    -- To be overridden
end

function ZO_SharedEnchanting:CanShowScene()
    -- To be overridden
    assert(false, "CanShowScene must be overridden")
end

function ZO_SharedEnchanting:IsSceneShowing()
    return SCENE_MANAGER:IsShowing(self.mainSceneName)
end

function ZO_SharedEnchanting:GetEnchantingMode()
    return self.enchantingMode
end

function ZO_SharedEnchanting:GetLastRunestoneSoundParams()
    return self.potencySound, self.potencyLength, self.essenceSound, self.essenceLength, self.aspectSound, self.aspectLength
end

function ZO_SharedEnchanting:ClearSelections()
    if self.enchantingMode == ENCHANTING_MODE_CREATION then
        for i, slot in ipairs(self.runeSlots) do
            slot:SetItem(nil)
        end
    elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
        self.extractionSlot:ClearItems()
        self.extractionSlot.dropCallout:SetTexture("EsoUI/Art/Crafting/crafting_enchanting_glyphSlot_empty.dds")
    end
end

function ZO_SharedEnchanting:HasSelections()
    if self.enchantingMode == ENCHANTING_MODE_CREATION then
        for i, slot in ipairs(self.runeSlots) do
            if slot:HasItem() then
                return true
            end
        end
        return false
    elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
        return self.extractionSlot:HasItems()
    end
end

function ZO_SharedEnchanting:IsCurrentSelected()
    local selectedBagId, selectedSlotIndex = self.inventory:CurrentSelectionBagAndSlot()
    if self.enchantingMode == ENCHANTING_MODE_CREATION then
        for i, slot in ipairs(self.runeSlots) do
            if slot:IsBagAndSlot(selectedBagId, selectedSlotIndex) then
                return true
            end
        end
        return false
    elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
        return self.extractionSlot:ContainsBagAndSlot(selectedBagId, selectedSlotIndex)
    end
end

-- Overrides ZO_CraftingCreateScreenBase
function ZO_SharedEnchanting:IsCraftable()
    if self.enchantingMode == ENCHANTING_MODE_CREATION then
        for i, slot in ipairs(self.runeSlots) do
            if not slot:HasItem() then
                return false
            end
        end
        return true
    end

    return false
end

function ZO_SharedEnchanting:ShouldCraftButtonBeEnabled()
    if ZO_CraftingUtils_IsPerformingCraftProcess() then
        return false
    end
    if self.enchantingMode == ENCHANTING_MODE_CREATION then
        local maxIterations, craftingResult = GetMaxIterationsPossibleForEnchantingItem(self:GetAllCraftingBagAndSlots())
        return maxIterations ~= 0, GetString("SI_TRADESKILLRESULT", craftingResult)
    end
    return false
end

function ZO_SharedEnchanting:ShouldDeconstructButtonBeEnabled()
    if ZO_CraftingUtils_IsPerformingCraftProcess() then
        return false
    end
    if self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
        return self:IsExtractable()
    end
    return false
end

-- Overrides ZO_CraftingCreateScreenBase
function ZO_SharedEnchanting:Create(numIterations)
    if self.enchantingMode == ENCHANTING_MODE_CREATION then
        local rune1BagId, rune1SlotIndex, rune2BagId, rune2SlotIndex, rune3BagId, rune3SlotIndex = self:GetAllCraftingBagAndSlots()
        self.potencySound, self.potencyLength = GetRunestoneSoundInfo(rune1BagId, rune1SlotIndex)
        self.essenceSound, self.essenceLength = GetRunestoneSoundInfo(rune2BagId, rune2SlotIndex)
        self.aspectSound, self.aspectLength = GetRunestoneSoundInfo(rune3BagId, rune3SlotIndex)

        CraftEnchantingItem(self:GetAllCraftingParameters(numIterations))
    end
end

function ZO_SharedEnchanting:GetAllCraftingParameters(numIterations)
    local rune1BagId, rune1SlotIndex = self.runeSlots[ENCHANTING_RUNE_POTENCY]:GetBagAndSlot()
    local rune2BagId, rune2SlotIndex = self.runeSlots[ENCHANTING_RUNE_ESSENCE]:GetBagAndSlot()
    local rune3BagId, rune3SlotIndex = self.runeSlots[ENCHANTING_RUNE_ASPECT]:GetBagAndSlot()
    return rune1BagId, rune1SlotIndex, rune2BagId, rune2SlotIndex, rune3BagId, rune3SlotIndex, numIterations
end

function ZO_SharedEnchanting:IsExtractable()
    return self.enchantingMode == ENCHANTING_MODE_EXTRACTION and self.extractionSlot:HasItems()
end

function ZO_SharedEnchanting:ExtractSingle()
    if self.enchantingMode == ENCHANTING_MODE_EXTRACTION and self.extractionSlot:HasOneItem() then
        PrepareDeconstructMessage()
        local bagId, slotIndex = self.extractionSlot:GetItemBagAndSlot(1)
        if AddItemToDeconstructMessage(bagId, slotIndex, 1) then
            SendDeconstructMessage()
        end

        self.extractionSlot:ClearDropCalloutTexture()
    end
end

function ZO_SharedEnchanting:ExtractPartialStack(quantity)
    if self.enchantingMode == ENCHANTING_MODE_EXTRACTION and self.extractionSlot:HasOneItem() then
        PrepareDeconstructMessage()

        local bagId, slotIndex = self.extractionSlot:GetItemBagAndSlot(1)
        if ZO_CraftingUtils_AddVirtualStackToDeconstructMessageAsRealStacks(bagId, slotIndex, quantity) then
            SendDeconstructMessage()
        end

        self.extractionSlot:ClearDropCalloutTexture()
    end
end

do
    local function CompareExtractingItems(left, right)
        return left.quantity < right.quantity
    end

    function ZO_SharedEnchanting:ExtractAll()
        if self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
            PrepareDeconstructMessage()

            local sortedItems = {}
            for index = 1, self.extractionSlot:GetNumItems() do
                local bagId, slotIndex = self.extractionSlot:GetItemBagAndSlot(index)
                local quantity = self.inventory:GetStackCount(bagId, slotIndex)
                table.insert(sortedItems, {bagId = bagId, slotIndex = slotIndex, quantity = quantity})
            end
            table.sort(sortedItems, CompareExtractingItems)

            local addedAllItems = true
            for _, item in ipairs(sortedItems) do
                if not ZO_CraftingUtils_AddVirtualStackToDeconstructMessageAsRealStacks(item.bagId, item.slotIndex, item.quantity) then
                    addedAllItems = false
                    break
                end
            end

            -- We send the final message, even if not all items are added to
            -- replicate the behavior we have in refining, where slotting a stack that
            -- is too large will give you a "best-effort" result.
            if not addedAllItems then
                QueueCraftingErrorAfterResultReceived(CRAFTING_RESULT_TOO_MANY_CRAFTING_INPUTS)
            end
            SendDeconstructMessage()

            self.extractionSlot:ClearDropCalloutTexture()
        end
    end
end

function ZO_SharedEnchanting:ConfirmExtractAll()
    local function PerformExtract()
        self:ExtractAll() 
    end
    ZO_Dialogs_ShowPlatformDialog("CONFIRM_DECONSTRUCT_MULTIPLE_ITEMS", {deconstructFn = PerformExtract}, {mainTextParams = {ZO_CommaDelimitNumber(self.extractionSlot:GetStackCount())}})
end

function ZO_SharedEnchanting:GetAllCraftingBagAndSlots()
    local rune1BagId, rune1SlotIndex = self.runeSlots[ENCHANTING_RUNE_POTENCY]:GetBagAndSlot()
    local rune2BagId, rune2SlotIndex = self.runeSlots[ENCHANTING_RUNE_ESSENCE]:GetBagAndSlot()
    local rune3BagId, rune3SlotIndex = self.runeSlots[ENCHANTING_RUNE_ASPECT]:GetBagAndSlot()
    return rune1BagId, rune1SlotIndex, rune2BagId, rune2SlotIndex, rune3BagId, rune3SlotIndex
end

function ZO_SharedEnchanting:OnMouseEnterCraftingComponent(bagId, slotIndex)
    if self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
        self.extractionSlot:SetBackdrop(bagId, slotIndex)
    end
end

function ZO_SharedEnchanting:OnMouseExitCraftingComponent()
    if self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
        self.extractionSlot:ClearDropCalloutTexture()
    end
end

function ZO_SharedEnchanting:OnSlotChanged()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    self:UpdateTooltip()
    self:UpdateMultiCraft()
    self.inventory:HandleVisibleDirtyEvent()
end

function ZO_SharedEnchanting:GetMultiCraftMaxIterations()
    if not self:IsCraftable() then
        return 0
    end

    local maxIterations = GetMaxIterationsPossibleForEnchantingItem(self:GetAllCraftingBagAndSlots())

    -- If a player doesn't already know all the runes they are using, they will
    -- need to craft with them at least once to learn what the final glyph will
    -- be. Let's restrict them to single crafts until they've done that.
    if maxIterations > 1 and not AreAllEnchantingRunesKnown(self:GetAllCraftingBagAndSlots()) then
        return 1
    end

    return maxIterations
end

function ZO_SharedEnchanting:GetResultItemLink()
    return GetEnchantingResultingItemLink(self:GetAllCraftingBagAndSlots())
end

function ZO_SharedEnchanting:GetMultiCraftNumResults(numIterations)
    return numIterations -- each iteration creates one item
end

function ZO_SharedEnchanting:UpdateMultiCraft()
    -- override me
end

function ZO_SharedEnchanting:UpdateTooltip()
    -- override me
end

function DoesRunePassRequirements(runeType, rankRequirement, rarityRequirement)
    if runeType == ENCHANTING_RUNE_POTENCY then
        return rankRequirement <= GetNonCombatBonus(NON_COMBAT_BONUS_ENCHANTING_LEVEL)
    elseif runeType == ENCHANTING_RUNE_ASPECT then
        return rarityRequirement <= GetNonCombatBonus(NON_COMBAT_BONUS_ENCHANTING_RARITY_LEVEL)
    end
    return true
end

function ZO_SharedEnchanting:IsItemAlreadySlottedToCraft(bagId, slotIndex)
    local usedInCraftingType, _, runeType, rankRequirement, rarityRequirement = GetItemCraftingInfo(bagId, slotIndex)
    local itemId = GetItemInstanceId(bagId, slotIndex)
    if usedInCraftingType == CRAFTING_TYPE_ENCHANTING then
        if self.enchantingMode == ENCHANTING_MODE_CREATION then
            local slot = self.runeSlots[runeType]
            if slot:IsItemId(itemId) then
                return true
            end
        elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
           return self.extractionSlot:ContainsItemId(itemId)
        end
    end
    return false
end

function ZO_SharedEnchanting:CanItemBeAddedToCraft(bagId, slotIndex)
    local usedInCraftingType, _, runeType, rankRequirement, rarityRequirement = GetItemCraftingInfo(bagId, slotIndex)
    if usedInCraftingType == CRAFTING_TYPE_ENCHANTING then
        if self.enchantingMode == ENCHANTING_MODE_CREATION then
            if DoesRunePassRequirements(runeType, rankRequirement, rarityRequirement) then
                return true
            end
        elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
            return true
        end
    end
    return false
end

function ZO_SharedEnchanting:AddItemToCraft(bagId, slotIndex)
    if not ZO_CraftingUtils_IsPerformingCraftProcess() and self:CanItemBeAddedToCraft(bagId, slotIndex) then
        if self.enchantingMode == ENCHANTING_MODE_CREATION then
            local _, _, runeType, _, _ = GetItemCraftingInfo(bagId, slotIndex)
            self.runeSlots[runeType]:SetItem(bagId, slotIndex)
            return self.runeSlots[runeType]
        elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
            if self.extractionSlot:GetNumItems() >= MAX_ITEM_SLOTS_PER_DECONSTRUCTION then
                ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_TOO_MANY_CRAFTING_INPUTS))
            else
                self.extractionSlot:AddItem(bagId, slotIndex)
                return self.extractionSlot
            end
        end
    end
end

function ZO_SharedEnchanting:RemoveItemFromCraft(bagId, slotIndex)
    if not ZO_CraftingUtils_IsPerformingCraftProcess() then
        local usedInCraftingType, _, runeType, rankRequirement, rarityRequirement = GetItemCraftingInfo(bagId, slotIndex)
        if usedInCraftingType == CRAFTING_TYPE_ENCHANTING then
            if self.enchantingMode == ENCHANTING_MODE_CREATION then
                self.runeSlots[runeType]:SetItem(nil, nil)
            elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
                self.extractionSlot:RemoveItem(bagId, slotIndex)
            end
        end
    end
end

function ZO_SharedEnchanting:ShowAppropriateSlotDropCallouts(craftingSubItemType, runeType, rankRequirement, rarityRequirement)
    for i, slot in ipairs(self.runeSlots) do
        slot:ShowDropCallout(runeType == slot:GetRuneType() and DoesRunePassRequirements(runeType, rankRequirement, rarityRequirement))
    end 

    self.extractionSlot:ShowDropCallout(craftingSubItemType == ITEMTYPE_GLYPH_WEAPON or craftingSubItemType == ITEMTYPE_GLYPH_ARMOR or craftingSubItemType == ITEMTYPE_GLYPH_JEWELRY)
end

function ZO_SharedEnchanting:HideAllSlotDropCallouts()
    for i, slot in ipairs(self.runeSlots) do
        slot:HideDropCallout()
    end

    self.extractionSlot:HideDropCallout()
end

function ZO_SharedEnchanting:OnInventoryUpdate(validItemIds)
    for i, slot in ipairs(self.runeSlots) do
        slot:ValidateItemId(validItemIds)
    end
    self.extractionSlot:ValidateItemId(validItemIds)

    self:UpdateTooltip()
    self:UpdateMultiCraft()
end

function ZO_SharedEnchanting:IsSlotted(bagId, slotIndex)
    if self.enchantingMode == ENCHANTING_MODE_CREATION then
        for i, slot in ipairs(self.runeSlots) do
            if slot:IsBagAndSlot(bagId, slotIndex) then
                return true
            end
        end
    elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
        return self.extractionSlot:ContainsBagAndSlot(bagId, slotIndex)
    end
    return false
end

ZO_SharedEnchantRuneSlot = ZO_CraftingSlotBase:Subclass()

function ZO_SharedEnchantRuneSlot:New(...)
    return ZO_CraftingSlotBase.New(self, ...)
end

function ZO_SharedEnchantRuneSlot:Initialize(owner, control, emptyTexture, dropCalloutTexturePositive, dropCalloutTextureNegative, placeSound, removeSound, runeType, craftingInventory, emptySlotIcon)
    ZO_CraftingSlotBase.Initialize(self, owner, control, SLOT_TYPE_PENDING_CRAFTING_COMPONENT, emptyTexture, craftingInventory, emptySlotIcon)

    self.nameLabel = control:GetNamedChild("Name")

    self.dropCalloutTexturePositive = dropCalloutTexturePositive
    self.dropCalloutTextureNegative = dropCalloutTextureNegative

    self.placeSound = placeSound
    self.pendingRemoveSound = removeSound

    self.runeType = runeType
end

function ZO_SharedEnchantRuneSlot:SetItem(bagId, slotIndex)
    local hadItem = self:HasItem()
    local oldItemInstanceId = self:GetItemId()

    self:SetupItem(bagId, slotIndex)

    if self:HasItem() then
        if oldItemInstanceId ~= self:GetItemId() then
            PlaySound(self.placeSound)
        end
    elseif hadItem then
        PlaySound(self.pendingRemoveSound)
    end

    if self.nameLabel then
        if bagId and slotIndex then
            self.nameLabel:SetHidden(false)
            self.nameLabel:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(bagId, slotIndex)))
        else
            self.nameLabel:SetHidden(true)
        end
    end
end

function ZO_SharedEnchantRuneSlot:ShowDropCallout(isCorrectType)
    self.dropCallout:SetHidden(false)
    self.dropCallout:SetTexture(isCorrectType and self.dropCalloutTexturePositive or self.dropCalloutTextureNegative)
end

function ZO_SharedEnchantRuneSlot:GetRuneType()
    return self.runeType
end

ZO_SharedEnchantExtractionSlot = ZO_CraftingMultiSlotBase:Subclass()

function ZO_SharedEnchantExtractionSlot:New(...)
    return ZO_CraftingMultiSlotBase.New(self, ...)
end

function ZO_SharedEnchantExtractionSlot:Initialize(owner, control, multipleItemsTexture, craftingInventory, useEmptySlotIcon)
    self.nameLabel = control:GetNamedChild("Name")

    local NO_EMPTY_TEXTURE = ""
    ZO_CraftingMultiSlotBase.Initialize(self, owner, control, SLOT_TYPE_PENDING_CRAFTING_COMPONENT, NO_EMPTY_TEXTURE, multipleItemsTexture, craftingInventory, useEmptySlotIcon and NO_EMPTY_TEXTURE or nil)

    self.dropCallout:SetDimensions(128, 128)
    self.dropCallout:SetHidden(false)
    self:ClearDropCalloutTexture()
end

function ZO_SharedEnchantExtractionSlot:ClearDropCalloutTexture()
    -- should be overridden
end

local function GetSoundsForGlyphType(craftingSubItemType)
    if craftingSubItemType == ITEMTYPE_GLYPH_WEAPON then
        return SOUNDS.ENCHANTING_WEAPON_GLYPH_PLACED, SOUNDS.ENCHANTING_WEAPON_GLYPH_REMOVED
    elseif craftingSubItemType == ITEMTYPE_GLYPH_ARMOR then
        return SOUNDS.ENCHANTING_ARMOR_GLYPH_PLACED, SOUNDS.ENCHANTING_ARMOR_GLYPH_REMOVED
    elseif craftingSubItemType == ITEMTYPE_GLYPH_JEWELRY then
        return SOUNDS.ENCHANTING_JEWELRY_GLYPH_PLACED, SOUNDS.ENCHANTING_JEWELRY_GLYPH_REMOVED
    end
end

function ZO_SharedEnchantExtractionSlot:RemoveItem(bagId, slotIndex)
    if ZO_CraftingMultiSlotBase.RemoveItem(self, bagId, slotIndex) then
        local _, craftingSubItemType, _ = GetItemCraftingInfo(bagId, slotIndex)
        local _, removeSound = GetSoundsForGlyphType(craftingSubItemType)
        PlaySound(removeSound)
        return true
    end
    return false
end

function ZO_SharedEnchantExtractionSlot:AddItem(bagId, slotIndex)
    if ZO_CraftingMultiSlotBase.AddItem(self, bagId, slotIndex) then
        local _, craftingSubItemType, _ = GetItemCraftingInfo(bagId, slotIndex)
        local placeSound, _ = GetSoundsForGlyphType(craftingSubItemType)
        PlaySound(placeSound)
        return true
    end
    return false
end

function ZO_SharedEnchantExtractionSlot:ClearItems()
    if ZO_CraftingMultiSlotBase.ClearItems(self) then
        PlaySound(SOUNDS.ENCHANTING_GENERIC_GLYPH_REMOVED)
        return true
    end
    return false
end

function ZO_SharedEnchantExtractionSlot:Refresh()
    ZO_CraftingMultiSlotBase.Refresh(self)
    if self:HasItems() then
        self.dropCallout:SetHidden(true)
    else
        self.dropCallout:SetHidden(false)
    end

    if self:HasOneItem() then
        local bagId, slotIndex = self:GetItemBagAndSlot(1)
        self.nameLabel:SetText(zo_strformat(ZO_GetSpecializedItemTypeTextBySlot(bagId, slotIndex)))
    elseif self:HasMultipleItems() then
        self.nameLabel:SetText(zo_strformat(SI_CRAFTING_SLOT_MULTIPLE_SELECTED, ZO_CommaDelimitNumber(self:GetStackCount())))
    else
        self.nameLabel:SetText(GetString(SI_ENCHANTING_SELECT_ITEMS_TO_EXTRACT))
    end
end

function ZO_SharedEnchantExtractionSlot:ShowDropCallout()
    -- no drop callout behavior
end

function ZO_SharedEnchantExtractionSlot:HideDropCallout()
    -- no drop callout behavior
end

function ZO_SharedEnchantExtractionSlot:SetBackdrop(bagId, slotIndex)
    -- should be overridden
end

ZO_SharedEnchantingSlotAnimation = ZO_CraftingCreateSlotAnimation:Subclass()

function ZO_SharedEnchantingSlotAnimation:New(...)
    return ZO_CraftingCreateSlotAnimation.New(self, ...)
end

function ZO_SharedEnchantingSlotAnimation:Initialize(...)
    ZO_CraftingCreateSlotAnimation.Initialize(self, ...)
end

function ZO_SharedEnchantingSlotAnimation:GetAnimationOffset(slot)
    return select(2, GetRunestoneSoundInfo(slot:GetBagAndSlot()))
end

function ZO_SharedEnchantingSlotAnimation:GetLockInSound(slot)
    -- there's a special sound player in CraftingResults.lua for enchanting
    return nil
end
