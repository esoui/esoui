ALCHEMY_TRAIT_STRIDE = 5

ZO_ALCHEMY_MODE_CREATION = 1
ZO_ALCHEMY_MODE_RECIPES = 2

local REQUIRED_SLOTTED_REAGENTS = 2

function ZO_Alchemy_DoesAlchemyItemPassFilter(bagId, slotIndex, filterType)
    if filterType == nil then
        return true
    end

    local _, craftingSubItemType = GetItemCraftingInfo(bagId, slotIndex)

    if type(filterType) == "function" then
        return filterType(craftingSubItemType)
    end

    return filterType == craftingSubItemType
end

function ZO_Alchemy_GetTraitInfo(traitIndex, ...)
    return select(traitIndex * ALCHEMY_TRAIT_STRIDE - (ALCHEMY_TRAIT_STRIDE - 1), ...)
end

function ZO_Alchemy_IsAlchemyItem(bagId, slotIndex)
    local usedInCraftingType, craftingSubItemType = GetItemCraftingInfo(bagId, slotIndex)
    if usedInCraftingType == CRAFTING_TYPE_ALCHEMY then
        return craftingSubItemType == ITEMTYPE_REAGENT or IsAlchemySolvent(craftingSubItemType)
    end
end

function ZO_Alchemy_IsThirdAlchemySlotUnlocked()
    return GetNonCombatBonus(NON_COMBAT_BONUS_ALCHEMY_THIRD_SLOT) ~= 0
end

ZO_SharedAlchemy = ZO_CraftingCreateScreenBase:Subclass()

function ZO_SharedAlchemy:New(...)
    local alchemy = ZO_CraftingCreateScreenBase.New(self)
    alchemy:Initialize(...)
    return alchemy
end

ZO_SharedAlchemy.initializedEvents = false

function ZO_SharedAlchemy:Initialize(control)
    self.control = control
    self.skillInfo = self.control:GetNamedChild("SkillInfo")

    self:InitializeInventory()
    self:InitializeTooltip()
    self:InitializeSlots()
    self:InitializeSharedEvents()

    self.alchemyStationInteraction =
    {
        type = "Alchemy Station",
        End = function()
            SCENE_MANAGER:ShowBaseScene()
        end,
        interactTypes = { INTERACTION_CRAFT },
    }

    ZO_Skills_TieSkillInfoHeaderToCraftingSkill(self.skillInfo, CRAFTING_TYPE_ALCHEMY)

    self:InitializeScenes()

    local function OnCraftCompleted()
        if not self.control:IsHidden() then
            self:UpdateTooltip()
            self:UpdateMultiCraft()
        end
    end

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", OnCraftCompleted)
end

function ZO_SharedAlchemy:InitializeSharedEvents()
    if not ZO_SharedAlchemy.initializedEvents then
        ZO_SharedAlchemy.initializedEvents = true
    
        EVENT_MANAGER:RegisterForEvent("ZO_SharedAlchemy", EVENT_CRAFTING_STATION_INTERACT, function(eventCode, craftingType, isCraftingSameAsPrevious)
            if craftingType == CRAFTING_TYPE_ALCHEMY then
                if not isCraftingSameAsPrevious then
                    self:ResetSelectedTab()
                end
                SYSTEMS:ShowScene("alchemy")
            end
        end)

        EVENT_MANAGER:RegisterForEvent("ZO_SharedAlchemy", EVENT_END_CRAFTING_STATION_INTERACT, function(eventCode, craftingType)
            if craftingType == CRAFTING_TYPE_ALCHEMY then
                SYSTEMS:HideScene("alchemy")
            end
        end)
    end
end

function ZO_SharedAlchemy:InitializeInventory()
    -- Should be overridden
end

function ZO_SharedAlchemy:InitializeTooltip()
    -- Should be overridden
end

function ZO_SharedAlchemy:InitializeKeybindStripDescriptors()
    -- Should be overridden
end

function ZO_SharedAlchemy:InitializeScenes()
    -- Should be overridden
end

function ZO_SharedAlchemy:UpdateTooltip()
    -- Should be overridden
end

function ZO_SharedAlchemy:UpdateTooltipLayout()
    -- Should be overridden
end

function ZO_SharedAlchemy:InitializeSlots()
    -- Should be overridden
end

function ZO_SharedAlchemy:UpdateThirdAlchemySlot()
    -- Should be overridden
end

function ZO_SharedAlchemy:ResetSelectedTab()
    -- Should be overridden
end

-- Overrides ZO_CraftingCreateScreenBase
function ZO_SharedAlchemy:GetMultiCraftMaxIterations()
    if not self:IsCraftable() then
        return 0
    end

    local maxIterations = GetMaxIterationsPossibleForAlchemyItem(self:GetAllCraftingBagAndSlots())
    if maxIterations > 1 then
        -- If a player doesn't already know all the traits that would go into the
        -- final effect of this alchemy item, they will need to craft with them at
        -- least once to learn what the final result will be. Let's restrict them to
        -- single crafts until they've done that.
        local _, prospectiveAlchemyResult = GetAlchemyResultingItemLink(self:GetAllCraftingBagAndSlots())
        if prospectiveAlchemyResult ~= PROSPECTIVE_ALCHEMY_RESULT_KNOWN then
            return 1
        end

        -- The player may be using a reagent that could have no effect on the final
        -- craft. For the same reason we prevent multicrafting unknown potions, lets
        -- prevent multicrafting here too
        if self:DoesAnyReagentHaveNoKnownTraits() then
            return 1
        end
    end

    return maxIterations
end

function ZO_SharedAlchemy:GetResultItemLink()
    return GetAlchemyResultingItemLink(self:GetAllCraftingBagAndSlots())
end

function ZO_SharedAlchemy:GetMultiCraftNumResults(numIterations)
    local solventBagId, solventSlotIndex = self.solventSlot:GetBagAndSlot()
    return GetAlchemyResultQuantity(solventBagId, solventSlotIndex, numIterations)
end

function ZO_SharedAlchemy:UpdateMultiCraft()
    -- Should be overidden
end

function ZO_SharedAlchemy:CanItemBeAddedToCraft(bagId, slotIndex)
    local usedInCraftingType, craftingSubItemType, rankRequirement = GetItemCraftingInfo(bagId, slotIndex)
    if usedInCraftingType == CRAFTING_TYPE_ALCHEMY then
        if IsAlchemySolvent(craftingSubItemType) and rankRequirement <= GetNonCombatBonus(NON_COMBAT_BONUS_ALCHEMY_LEVEL) then
            return true
        elseif craftingSubItemType == ITEMTYPE_REAGENT then
            return true
        end
    end
    return false
end

function ZO_SharedAlchemy:CreateInteractScene(name)
    return ZO_InteractScene:New(name, SCENE_MANAGER, self.alchemyStationInteraction)
end

function ZO_SharedAlchemy:IsItemAlreadySlottedToCraft(bagId, slotIndex)
    local itemId = GetItemInstanceId(bagId, slotIndex)
    if self.solventSlot:IsItemId(itemId) then
        return true
    else
        for i, slot in ipairs(self.reagentSlots) do
            if slot:IsItemId(itemId) then
                return true
            end
        end
    end
    return false
end

function ZO_SharedAlchemy:AddItemToCraft(bagId, slotIndex)
    local usedInCraftingType, craftingSubItemType, rankRequirement = GetItemCraftingInfo(bagId, slotIndex)
    if usedInCraftingType == CRAFTING_TYPE_ALCHEMY then
        if IsAlchemySolvent(craftingSubItemType) and rankRequirement <= GetNonCombatBonus(NON_COMBAT_BONUS_ALCHEMY_LEVEL) then
            self:SetSolventItem(bagId, slotIndex)
        elseif craftingSubItemType == ITEMTYPE_REAGENT and not self:FindAlreadySlottedReagent(bagId, slotIndex) then
            self:SetReagentItem(nil, bagId, slotIndex)
        end
    end
end

function ZO_SharedAlchemy:RemoveItemFromCraft(bagId, slotIndex)
    local itemId = GetItemInstanceId(bagId, slotIndex)
    if self.solventSlot:IsItemId(itemId) then
        self:SetSolventItem(nil)
    else
        for i, slot in ipairs(self.reagentSlots) do
            if slot:IsItemId(itemId) then
                self:SetReagentItem(i, nil)
                break
            end
        end
    end
end

function ZO_SharedAlchemy:SetSolventItem(bagId, slotIndex)
    self.solventSlot:SetItem(bagId, slotIndex)
end

function ZO_SharedAlchemy:FindNextSlotToInsertReagent()
    for i, slot in ipairs(self.reagentSlots) do
        if not slot:HasItem() and slot:MeetsUsabilityRequirement() then
            return i
        end
    end

    local reagentSlots = ZO_Alchemy_IsThirdAlchemySlotUnlocked() and 3 or 2
    return self.lastReagentIndexAdded % reagentSlots + 1
end

function ZO_SharedAlchemy:SetReagentItem(reagentSlot, bagId, slotIndex)
    if reagentSlot == nil then
        reagentSlot = self:FindNextSlotToInsertReagent()
    end

    self.reagentSlots[reagentSlot]:SetItem(bagId, slotIndex)
    self.lastReagentIndexAdded = reagentSlot
end

local function AddTraitCounts(traitCounts, cancellingTraitCounts, ...)
    for i = 1, NUM_ALCHEMY_TRAITS_PER_REAGENT do
        local traitName, _, _, cancellingTraitName = ZO_Alchemy_GetTraitInfo(i, ...)
        if traitName then
            traitCounts[traitName] = (traitCounts[traitName] or 0) + 1
        end
        if cancellingTraitName then
            cancellingTraitCounts[cancellingTraitName] = (cancellingTraitCounts[cancellingTraitName] or 0) + 1
        end
    end
end

function ZO_SharedAlchemy:UpdateReagentTraits()
    self.matchingTraits = {}
    self.cancelledTraits = {}

    local addedTraitCounts = {}
    local cancellingTraitCounts = {}
    for i, slot in ipairs(self.reagentSlots) do
        if slot:HasItem() then
            local bagId, slotIndex = slot:GetBagAndSlot()
            AddTraitCounts(addedTraitCounts, cancellingTraitCounts, GetAlchemyItemTraits(bagId, slotIndex))
        end
    end

    for traitName, addCount in pairs(addedTraitCounts) do
        if addCount > 1 then
            self.matchingTraits[traitName] = true
        end

        local cancellCount = cancellingTraitCounts[traitName] or 0
        if(cancellCount > 0) then
            self.cancelledTraits[traitName] = true
        end
    end

    for i, slot in ipairs(self.reagentSlots) do
        slot:UpdateTraits()
    end
end

function ZO_SharedAlchemy:HasTraitMatch(traitName)
    return self.matchingTraits and self.matchingTraits[traitName]
end

function ZO_SharedAlchemy:HasTraitCancelled(traitName)
    return self.cancelledTraits and self.cancelledTraits[traitName]
end

function ZO_SharedAlchemy:DoesAnyReagentHaveNoKnownTraits()
    for i, slot in ipairs(self.reagentSlots) do
        if slot:HasItem() then
            local bagId, slotIndex = slot:GetBagAndSlot()
            local noKnownTraits = true
            for traitIndex = 1, NUM_ALCHEMY_TRAITS_PER_REAGENT do
                if IsAlchemyItemTraitKnown(bagId, slotIndex, traitIndex) then
                    noKnownTraits = false
                    break
                end
            end
            if noKnownTraits then
                return true
            end
        end
    end
    return false
end

function  ZO_SharedAlchemy:SetupTraitIcon(textureControl, name, icon, matchIcon, conflictIcon, unknownTexture)
    if self:HasTraitCancelled(name) and conflictIcon then
        textureControl:SetTexture(conflictIcon)
        textureControl:SetAlpha(1)    
    elseif self:HasTraitMatch(name) and matchIcon then
        textureControl:SetTexture(matchIcon)
        textureControl:SetAlpha(1)
    elseif icon then
        textureControl:SetTexture(icon)
        textureControl:SetAlpha(.5)
    else
        textureControl:SetTexture(unknownTexture)
        textureControl:SetAlpha(1)
    end
end

function ZO_SharedAlchemy:FindAlreadySlottedReagent(bagId, slotIndex)
    local itemId = GetItemInstanceId(bagId, slotIndex)
    for i, slot in ipairs(self.reagentSlots) do
        if slot:IsItemId(itemId) then
            return i
        end
    end
    return nil
end

function ZO_SharedAlchemy:ShowAppropriateSlotDropCallouts(craftingSubItemType, rankRequirement)
    self.solventSlot:ShowDropCallout(IsAlchemySolvent(craftingSubItemType) and rankRequirement <= GetNonCombatBonus(NON_COMBAT_BONUS_ALCHEMY_LEVEL))
    for i, slot in ipairs(self.reagentSlots) do
        slot:ShowDropCallout(craftingSubItemType == ITEMTYPE_REAGENT)
    end
end

function ZO_SharedAlchemy:HideAllSlotDropCallouts()
    self.solventSlot:HideDropCallout()
    for i, slot in ipairs(self.reagentSlots) do
        slot:HideDropCallout()
    end
end

function ZO_SharedAlchemy:OnInventoryUpdate(validItemIds)
    local changed = false
    self.solventSlot:ValidateItemId(validItemIds)
    for i, slot in ipairs(self.reagentSlots) do
        slot:ValidateItemId(validItemIds)
    end

    self:UpdateMultiCraft()
    self:UpdateReagentTraits()
end

function ZO_SharedAlchemy:IsSlotted(bagId, slotIndex)
    if self.solventSlot:IsBagAndSlot(bagId, slotIndex) then
        return true
    end
    for i, slot in ipairs(self.reagentSlots) do
        if slot:IsBagAndSlot(bagId, slotIndex) then
            return true
        end
    end
    return false
end

function ZO_SharedAlchemy:ClearSelections(suppressSound, ignoreUsabilityRequirement)
    local NO_BAG = nil
    local NO_INDEX = nil
    self.solventSlot:SetItem(NO_BAG, NO_INDEX, suppressSound, ignoreUsabilityRequirement)

    for i, slot in ipairs(self.reagentSlots) do
        slot:SetItem(NO_BAG, NO_INDEX, suppressSound, ignoreUsabilityRequirement)
    end
end

function ZO_SharedAlchemy:HasSelections()
    if self.solventSlot:HasItem() then
        return true
    end
    for i, slot in ipairs(self.reagentSlots) do
        if slot:HasItem() then
            return true
        end
    end
    return false
end

-- Overrides ZO_CraftingCreateScreenBase
function ZO_SharedAlchemy:IsCraftable()
    if self.solventSlot:HasItem() then
        local numSlotsWithItems = 0
        for i, slot in ipairs(self.reagentSlots) do
            if slot:HasItem() and slot:MeetsUsabilityRequirement() then
                numSlotsWithItems = numSlotsWithItems + 1
                if numSlotsWithItems >= REQUIRED_SLOTTED_REAGENTS then
                    return true
                end
            end
        end
    end
    return false
end

function ZO_SharedAlchemy:ShouldCraftButtonBeEnabled()
    if ZO_CraftingUtils_IsPerformingCraftProcess() then
        return false
    end

    if not self.solventSlot:HasItem() then
        return false, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_INVALID_BASE)
    end

    local numSlotsWithItems = 0
    for i, slot in ipairs(self.reagentSlots) do
        if slot:HasItem() and slot:MeetsUsabilityRequirement() then
            numSlotsWithItems = numSlotsWithItems + 1
        end
    end

    if numSlotsWithItems < REQUIRED_SLOTTED_REAGENTS then
        return false, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_TOO_FEW_REAGENTS)
    end

    local _, prospectiveAlchemyResult = GetAlchemyResultingItemLink(self:GetAllCraftingBagAndSlots())
    if prospectiveAlchemyResult == PROSPECTIVE_ALCHEMY_RESULT_UNCRAFTABLE then
        -- allow invalid crafts, even if there isn't inventory space for it
        return true
    end

    local maxIterations, craftingResult = GetMaxIterationsPossibleForAlchemyItem(self:GetAllCraftingBagAndSlots())
    return maxIterations ~= 0, GetString("SI_TRADESKILLRESULT", craftingResult)
end

-- Overrides ZO_CraftingCreateScreenBase
function ZO_SharedAlchemy:Create(numIterations)
    CraftAlchemyItem(self:GetAllCraftingParameters(numIterations))
end

local function CollapseBagAndSlots(bagId, slotIndex, ...)
    if select("#", ...) > 0 then
        if bagId and slotIndex then
            return bagId, slotIndex, CollapseBagAndSlots(...)
        end
        return CollapseBagAndSlots(...)
    end
    if bagId and slotIndex then
        return bagId, slotIndex
    end
end

function ZO_SharedAlchemy:GetAllCraftingBagAndSlots()
    local solventBagId, solventSlotIndex = self.solventSlot:GetBagAndSlot()
    local reagent1BagId, reagent1SlotIndex = self.reagentSlots[1]:GetBagAndSlot()
    local reagent2BagId, reagent2SlotIndex = self.reagentSlots[2]:GetBagAndSlot()
    local reagent3BagId, reagent3SlotIndex = nil, nil
    if #self.reagentSlots >= 3 then
        reagent3BagId, reagent3SlotIndex = self.reagentSlots[3]:GetBagAndSlot()
    end
    local bagId1, slotIndex1, bagId2, slotIndex2, bagId3, slotIndex3 = CollapseBagAndSlots(reagent1BagId, reagent1SlotIndex, reagent2BagId, reagent2SlotIndex, reagent3BagId, reagent3SlotIndex)
    return solventBagId, solventSlotIndex, bagId1, slotIndex1, bagId2, slotIndex2, bagId3, slotIndex3
end

-- Overrides ZO_CraftingCreateScreenBase
function ZO_SharedAlchemy:GetAllCraftingParameters(numIterations)
    -- Tricky behavior here: since bag/slot 3 can be nil, you _cannot_ put these crafting parameters into a table safely.
    local solventBagId, solventSlotIndex = self.solventSlot:GetBagAndSlot()
    local reagent1BagId, reagent1SlotIndex = self.reagentSlots[1]:GetBagAndSlot()
    local reagent2BagId, reagent2SlotIndex = self.reagentSlots[2]:GetBagAndSlot()
    local reagent3BagId, reagent3SlotIndex = nil, nil
    if #self.reagentSlots >= 3 then
        reagent3BagId, reagent3SlotIndex = self.reagentSlots[3]:GetBagAndSlot()
    end
    local bagId1, slotIndex1, bagId2, slotIndex2, bagId3, slotIndex3 = CollapseBagAndSlots(reagent1BagId, reagent1SlotIndex, reagent2BagId, reagent2SlotIndex, reagent3BagId, reagent3SlotIndex)
    return solventBagId, solventSlotIndex, bagId1, slotIndex1, bagId2, slotIndex2, bagId3, slotIndex3, numIterations
end

function ZO_SharedAlchemy:OnSolventSlotted(bagId, slotIndex)
    local _, craftingSubItemType = GetItemCraftingInfo(bagId, slotIndex)
    if craftingSubItemType == ITEMTYPE_POISON_BASE then
        TriggerTutorial(TUTORIAL_TRIGGER_ALCHEMY_STATION_OIL_SLOTTED)
    end
end

function ZO_SharedAlchemy:OnSlotChanged(bagId, slotIndex)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    self:UpdateTooltip()
    self:UpdateMultiCraft()
    self.inventory:HandleVisibleDirtyEvent()
end

function ZO_SharedAlchemy:FindReagentSlotIndexBySlotControl(slotControl)
    for i, slot in ipairs(self.reagentSlots) do
        if slot:IsSlotControl(slotControl) then
            return i
        end
    end
end

--
-- ZO_AlchemySlot
--

ZO_AlchemySlot = ZO_CraftingSlotBase:Subclass()

function ZO_AlchemySlot:New(...)
    return ZO_CraftingSlotBase.New(self, ...)
end

function ZO_AlchemySlot:Initialize(owner, control, emptyTexture, placeSound, removeSound, usabilityPredicate, craftingInventory, emptySlotIcon)
    ZO_CraftingSlotBase.Initialize(self, owner, control, SLOT_TYPE_PENDING_CRAFTING_COMPONENT, emptyTexture, craftingInventory, emptySlotIcon)

    self.createsLevelLabel = self.control:GetNamedChild("CreatesLevel")

    self.placeSound = placeSound
    self.removeSound = removeSound

    self.usabilityPredicate = usabilityPredicate

    self.dropCallout:SetDrawLayer(DL_BACKGROUND)
    self:UpdateTraits()
end

function ZO_AlchemySlot:ShouldBeVisible()
    return self:MeetsUsabilityRequirement()
end

function ZO_AlchemySlot:ShowDropCallout(isCorrectType)
    self.dropCallout:SetHidden(false)

    if isCorrectType then
        self.dropCallout:SetTexture("EsoUI/Art/Crafting/crafting_alchemy_goodSlot.dds")
    else
        self.dropCallout:SetTexture("EsoUI/Art/Crafting/crafting_alchemy_badSlot.dds")
    end
end

function ZO_AlchemySlot:SetItem(bagId, slotIndex, suppressSound, ignoreUsabilityRequirement)
    if not ignoreUsabilityRequirement then
        if not self:MeetsUsabilityRequirement() then
            return
        end
    end

    self:SetupItem(bagId, slotIndex)

    if self:HasItem() then
        if not suppressSound then
            PlaySound(self.placeSound)
        end
    else
        if not suppressSound then
            PlaySound(self.removeSound)
        end
    end
end

function ZO_AlchemySlot:Refresh()
    ZO_CraftingSlotBase.Refresh(self)
    if self:HasItem() then
        if self.createsLevelLabel then
            local bagId, slotIndex = self:GetBagAndSlot()
            local craftingSubItemType, _, resultingItemLevel, requiredChampionPoints = select(2, GetItemCraftingInfo(bagId, slotIndex))
            local itemTypeString = GetString((craftingSubItemType == ITEMTYPE_POTION_BASE) and SI_ITEM_FORMAT_STR_POTION or SI_ITEM_FORMAT_STR_POISON)

            if requiredChampionPoints and requiredChampionPoints > 0 then
                self.createsLevelLabel:SetText(zo_strformat(SI_ALCHEMY_CREATES_ITEM_OF_CHAMPION_POINTS, requiredChampionPoints, itemTypeString))
            else
                self.createsLevelLabel:SetText(zo_strformat(SI_ALCHEMY_CREATES_ITEM_OF_LEVEL, resultingItemLevel, itemTypeString))
            end
            self.createsLevelLabel:SetHidden(false)
        end
        self:ShowSlotTraits(true)
    else
        if self.createsLevelLabel then
            self.createsLevelLabel:SetHidden(true)
        end
        self:ShowSlotTraits(false)
    end
end

function ZO_AlchemySlot:UpdateTraits()
    if self:HasItem() then
        self:SetTraits(GetAlchemyItemTraits(self:GetBagAndSlot()))
    else
        self:ClearTraits()
    end
end

function ZO_AlchemySlot:GetUnknownTraitTexture()
    return  "EsoUI/Art/Crafting/crafting_alchemy_trait_slot.dds"
end

function ZO_AlchemySlot:SetTraits(...)
    if self.control.traits then
        local unknownTraitTexture = self:GetUnknownTraitTexture()
        for i, traitTexture in ipairs(self.control.traits) do
            local traitName, traitIcon, traitMatchIcon, _, traitConflictIcon = ZO_Alchemy_GetTraitInfo(i, ...)
            traitTexture.traitName = traitName
            self.owner:SetupTraitIcon(traitTexture, traitName, traitIcon, traitMatchIcon, traitConflictIcon, unknownTraitTexture)
        end
    end
end

function ZO_AlchemySlot:ClearTraits()
    if self.control.traits then
        local unknownTraitTexture = self:GetUnknownTraitTexture()
        for i, traitTexture in ipairs(self.control.traits) do
            traitTexture.traitName = nil
            traitTexture:SetTexture(unknownTraitTexture)
            traitTexture:SetAlpha(1)
        end
    end
end

function ZO_AlchemySlot:MeetsUsabilityRequirement()
    return self.usabilityPredicate == nil or self.usabilityPredicate()
end

function ZO_AlchemySlot:ShowSlotTraits(showTraits)
    if self.emptySlotIcon and self.control.traits then
        for i, trait in ipairs(self.control.traits) do
            trait:SetHidden(not showTraits)
        end
    end
end