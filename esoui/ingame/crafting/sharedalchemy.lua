ALCHEMY_TRAIT_STRIDE = 5

ZO_ALCHEMY_MODE_CREATION = 1
ZO_ALCHEMY_MODE_RECIPES = 2

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

function ZO_Alchemy_IsSceneShowing()
    return SYSTEMS:IsShowing("alchemy")
end

ZO_SharedAlchemy = ZO_Object:Subclass()

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
        end
    end

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", OnCraftCompleted)
end

function ZO_SharedAlchemy:InitializeSharedEvents()
    if not ZO_SharedAlchemy.initializedEvents then
        ZO_SharedAlchemy.initializedEvents = true
    
        EVENT_MANAGER:RegisterForEvent("ZO_SharedAlchemy", EVENT_CRAFTING_STATION_INTERACT, function(eventCode, craftingType)
            if craftingType == CRAFTING_TYPE_ALCHEMY then
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

-- Gets the horizontal offset for reagent slots
function ZO_SharedAlchemy:GetReagentSlotOffset(thirdSlotUnlocked)
    -- Should be overriden for screen-specific spacing
end

function ZO_SharedAlchemy:UpdateTooltipLayout()
    -- Should be overridden
end

function ZO_SharedAlchemy:InitializeSlots()
    local slotContainer = self.control:GetNamedChild("SlotContainer")
    self.solventSlot = ZO_AlchemyReagentSlot:New(self, slotContainer:GetNamedChild("SolventSlot"), "EsoUI/Art/Crafting/alchemy_emptySlot_solvent.dds", SOUNDS.ALCHEMY_SOLVENT_PLACED, SOUNDS.ALCHEMY_SOLVENT_REMOVED, nil, self.inventory)

    local reagentTexture = "EsoUI/Art/Crafting/alchemy_emptySlot_reagent.dds"
    self.reagentSlots = {
        ZO_AlchemyReagentSlot:New(self, slotContainer:GetNamedChild("ReagentSlot1"), reagentTexture, SOUNDS.ALCHEMY_REAGENT_PLACED, SOUNDS.ALCHEMY_REAGENT_REMOVED, nil, self.inventory),
        ZO_AlchemyReagentSlot:New(self, slotContainer:GetNamedChild("ReagentSlot2"), reagentTexture, SOUNDS.ALCHEMY_REAGENT_PLACED, SOUNDS.ALCHEMY_REAGENT_REMOVED, nil, self.inventory),
        ZO_AlchemyReagentSlot:New(self, slotContainer:GetNamedChild("ReagentSlot3"), reagentTexture, SOUNDS.ALCHEMY_REAGENT_PLACED, SOUNDS.ALCHEMY_REAGENT_REMOVED, ZO_Alchemy_IsThirdAlchemySlotUnlocked, self.inventory),
    }

    local reagentsLabel = slotContainer:GetNamedChild("ReagentsLabel")

    self.slotAnimation = ZO_CraftingCreateSlotAnimation:New(self.sceneName)

    self.control:RegisterForEvent(EVENT_NON_COMBAT_BONUS_CHANGED, function(eventCode, nonCombatBonusType)
        if nonCombatBonusType == NON_COMBAT_BONUS_ALCHEMY_THIRD_SLOT then
            self:UpdateThirdAlchemySlot()
        elseif nonCombatBonusType == NON_COMBAT_BONUS_ALCHEMY_LEVEL then
            self.inventory:HandleDirtyEvent()
        end
    end)

    self:UpdateThirdAlchemySlot()
end

function ZO_SharedAlchemy:UpdateThirdAlchemySlot()
    local SUPPRESS_SOUND = true
    local IGNORE_REQUIREMENTS = true
    self:ClearSelections(SUPPRESS_SOUND, IGNORE_REQUIREMENTS)

    local slotContainer = self.control:GetNamedChild("SlotContainer")
    local reagentsLabel = slotContainer:GetNamedChild("ReagentsLabel")
    local thirdSlotUnlocked = ZO_Alchemy_IsThirdAlchemySlotUnlocked()
    local slotOffset = self:GetReagentSlotOffset(thirdSlotUnlocked)

    self.slotAnimation:Clear()
    for i, slot in ipairs(self.reagentSlots) do
        slot:GetControl():ClearAnchors()
    end

    self.slotAnimation:AddSlot(self.solventSlot)
    self.slotAnimation:AddSlot(self.reagentSlots[1])
    self.slotAnimation:AddSlot(self.reagentSlots[2])

    if thirdSlotUnlocked then
        local secondSlotControl = self.reagentSlots[2]:GetControl()
        secondSlotControl:SetAnchor(TOP, reagentsLabel, BOTTOM, 0, 20)

        self.reagentSlots[1]:GetControl():SetAnchor(RIGHT, secondSlotControl, LEFT, -slotOffset, 0)
        self.reagentSlots[3]:GetControl():SetAnchor(LEFT, secondSlotControl, RIGHT, slotOffset, 0)

        self.slotAnimation:AddSlot(self.reagentSlots[3])
    else
        self.reagentSlots[1]:GetControl():SetAnchor(TOPRIGHT, reagentsLabel, BOTTOM, -slotOffset, 20)
        self.reagentSlots[2]:GetControl():SetAnchor(TOPLEFT, reagentsLabel, BOTTOM, slotOffset, 20)
    end
    self.reagentSlots[3]:SetHidden(not thirdSlotUnlocked)
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
    
    local _, craftingSubItemType = GetItemCraftingInfo(bagId, slotIndex)
    if(craftingSubItemType == ITEMTYPE_POISON_BASE) then
        TriggerTutorial(TUTORIAL_TRIGGER_ALCHEMY_STATION_OIL_SLOTTED)
    end

    self:OnSlotChanged()
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
    self:OnReagentSlotChanged()
    self:OnSlotChanged()
end

local function AddTraitCounts(traitCounts, cancellingTraitCounts, ...)
    local numTraits = select("#", ...) / ALCHEMY_TRAIT_STRIDE
    for i = 1, numTraits do
        local traitName, _, _, cancellingTraitName = ZO_Alchemy_GetTraitInfo(i, ...)
        if traitName then
            traitCounts[traitName] = (traitCounts[traitName] or 0) + 1
        end
        if cancellingTraitName then
            cancellingTraitCounts[cancellingTraitName] = (cancellingTraitCounts[cancellingTraitName] or 0) + 1
        end
    end
end

function ZO_SharedAlchemy:OnReagentSlotChanged()
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
    if not self.solventSlot:ValidateItemId(validItemIds) then
        changed = true
    end
    for i, slot in ipairs(self.reagentSlots) do
        if not slot:ValidateItemId(validItemIds) then
            changed = true
        end
    end
    if changed then
        self:OnSlotChanged()
    end
    self:OnReagentSlotChanged()
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

    self:OnReagentSlotChanged()
    self:OnSlotChanged()
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

function ZO_SharedAlchemy:IsCraftable()
    if self.solventSlot:HasItem() then
        local numSlotsWithItems = 0
        local REQUIRED_SLOTTED_REAGENTS = 2
        for i, slot in ipairs(self.reagentSlots) do
            if slot:HasItem() and slot:MeetsUsabilityRequirement() then
                numSlotsWithItems = numSlotsWithItems + 1
                if numSlotsWithItems >= REQUIRED_SLOTTED_REAGENTS then
                    return true
                end
            end
        end
    end
end

function ZO_SharedAlchemy:Create()
    CraftAlchemyItem(self:GetAllCraftingBagAndSlots())
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

function ZO_SharedAlchemy:OnSlotChanged()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    self:UpdateTooltip()
    self.inventory:HandleVisibleDirtyEvent()
end

function ZO_SharedAlchemy:FindReagentSlotIndexBySlotControl(slotControl)
    for i, slot in ipairs(self.reagentSlots) do
        if slot:IsSlotControl(slotControl) then
            return i
        end
    end
end

function ZO_SharedAlchemy:UpdateTooltip()
    -- if we are in recipe mode then we shouldn't show the alchemy tooltip
    if self:IsCraftable() and self.mode ~= ZO_ALCHEMY_MODE_RECIPES then
        self.tooltip:SetHidden(false)
        self.tooltip:ClearLines()
        self:UpdateTooltipLayout()
    else
        self.tooltip:SetHidden(true)
    end
end

--
-- ZO_AlchemyReagentSlot
--

ZO_AlchemyReagentSlot = ZO_CraftingSlotBase:Subclass()

function ZO_AlchemyReagentSlot:New(...)
    return ZO_CraftingSlotBase.New(self, ...)
end

function ZO_AlchemyReagentSlot:Initialize(owner, control, emptyTexture, placeSound, removeSound, usabilityPredicate, craftingInventory, emptySlotIcon)
    ZO_CraftingSlotBase.Initialize(self, owner, control, SLOT_TYPE_PENDING_CRAFTING_COMPONENT, emptyTexture, craftingInventory, emptySlotIcon)

    self.createsLevelLabel = self.control:GetNamedChild("CreatesLevel")

    self.placeSound = placeSound
    self.removeSound = removeSound

    self.usabilityPredicate = usabilityPredicate

    self.dropCallout:SetDrawLayer(DL_BACKGROUND)
end


function ZO_AlchemyReagentSlot:ShowDropCallout(isCorrectType)
    self.dropCallout:SetHidden(false)

    if isCorrectType then
        self.dropCallout:SetTexture("EsoUI/Art/Crafting/crafting_alchemy_goodSlot.dds")
    else
        self.dropCallout:SetTexture("EsoUI/Art/Crafting/crafting_alchemy_badSlot.dds")
    end
end

function ZO_AlchemyReagentSlot:ValidateItemId(validItemIds)
    if self.bagId and self.slotIndex then
        -- An item might have been used up in a physical stack
        if validItemIds[self.itemInstanceId] then
            -- An item still exists in a physical stack, but might not exist in the virtual stack any more, update the indices
            local itemInfo = validItemIds[self.itemInstanceId]
            if self:IsBagAndSlot(itemInfo.bag, itemInfo.index) then
                self:SetupItem(itemInfo.bag, itemInfo.index)
            else
                self:SetItem(itemInfo.bag, itemInfo.index)
            end

            self:OnPassedValidation()
            return true
        else
            -- Item doesn't exist in a physical stack
            local SUPPRESS_SOUND = true
            self:SetItem(nil, nil, SUPPRESS_SOUND)
            self:OnFailedValidation()
            return false
        end
    end
    return true
end

function ZO_AlchemyReagentSlot:SetItem(bagId, slotIndex, suppressSound, ignoreUsabilityRequirement)
    if not ignoreUsabilityRequirement then
        if not self:MeetsUsabilityRequirement() then
            return
        end
    end

    self:SetupItem(bagId, slotIndex)

    if self:HasItem() then
        if self.createsLevelLabel then
            local craftingSubItemType, _, resultingItemLevel, championRequiredLevel = select(2, GetItemCraftingInfo(bagId, slotIndex))
            local itemTypeString = GetString((craftingSubItemType == ITEMTYPE_POTION_BASE) and SI_ITEM_FORMAT_STR_POTION or SI_ITEM_FORMAT_STR_POISON)

            if championRequiredLevel and championRequiredLevel > 0 then
                self.createsLevelLabel:SetText(zo_strformat(SI_ALCHEMY_CREATES_ITEM_OF_CHAMPION_POINTS, championRequiredLevel, itemTypeString))
            else
                self.createsLevelLabel:SetText(zo_strformat(SI_ALCHEMY_CREATES_ITEM_OF_LEVEL, resultingItemLevel, itemTypeString))
            end
            self.createsLevelLabel:SetHidden(false)
        end

        if not suppressSound then
            PlaySound(self.placeSound)
        end

        self:ShowSlotTraits(true)
    else
        if self.createsLevelLabel then
            self.createsLevelLabel:SetHidden(true)
        end

        if not suppressSound then
            PlaySound(self.removeSound)
        end

        self:ShowSlotTraits(false)
    end
end

function ZO_AlchemyReagentSlot:UpdateTraits()
    if self:MeetsUsabilityRequirement() then
        if self.bagId and self.slotIndex then
            self:SetTraits(nil, GetAlchemyItemTraits(self.bagId, self.slotIndex))
        else
            self:ClearTraits()
        end
    end
end

function ZO_AlchemyReagentSlot:SetTraits(unknownTraitTexture, ...)
    if self.control.traits then
        local numTraits = select("#", ...) / ALCHEMY_TRAIT_STRIDE
        for i, traitTexture in ipairs(self.control.traits) do
            if i > numTraits then
                traitTexture:SetTexture(unknownTraitTexture or "EsoUI/Art/Crafting/crafting_alchemy_trait_slot.dds")
            else
                local traitName, traitIcon, traitMatchIcon, _, traitConflictIcon = ZO_Alchemy_GetTraitInfo(i, ...)
                traitTexture.traitName = traitName
                self.owner:SetupTraitIcon(traitTexture, traitName, traitIcon, traitMatchIcon, traitConflictIcon, unknownTraitTexture or "EsoUI/Art/Crafting/crafting_alchemy_trait_slot.dds")
            end
        end
    end
end

function ZO_AlchemyReagentSlot:ClearTraits(unknownTraitTexture)
    if self.control.traits then
        for i, traitTexture in ipairs(self.control.traits) do
            traitTexture.traitName = nil
            traitTexture:SetTexture(unknownTraitTexture or "EsoUI/Art/Crafting/crafting_alchemy_trait_slot.dds")
            traitTexture:SetAlpha(1)
        end
    end
end

function ZO_AlchemyReagentSlot:MeetsUsabilityRequirement()
    return self.usabilityPredicate == nil or self.usabilityPredicate()
end

function ZO_AlchemyReagentSlot:ShowSlotTraits(showTraits)
    if self.emptySlotIcon and self.control.traits then
        for i, trait in ipairs(self.control.traits) do
            trait:SetHidden(not showTraits)
        end
    end
end