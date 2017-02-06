ZO_SharedEnchanting = ZO_Object:Subclass()

function ZO_SharedEnchanting:New(...)
    local enchanting = ZO_Object.New(self)
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
    return SCENE_MANAGER:IsShowing("enchanting") or SCENE_MANAGER:IsShowing("gamepad_enchanting_mode") or SCENE_MANAGER:IsShowing("gamepad_enchanting_creation") or SCENE_MANAGER:IsShowing("gamepad_enchanting_extraction")
end

function ZO_Enchanting_GetVisibleEnchanting()
    if SCENE_MANAGER:IsShowing("enchanting") then
        return ENCHANTING
    else
        return GAMEPAD_ENCHANTING
    end
end

function ZO_Enchanting_IsInCreationMode()
    if SCENE_MANAGER:IsShowing("enchanting") and ENCHANTING:GetEnchantingMode() == ENCHANTING_MODE_CREATION then
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

end

function ZO_SharedEnchanting:InitializeInventory()
end

function ZO_SharedEnchanting:InitializeModes()
end

function ZO_SharedEnchanting:InitializeEnchantingScenes()
end

function ZO_SharedEnchanting:InitializeCreationSlots()
    self.runeSlotContainer = self.control:GetNamedChild("RuneSlotContainer")
    self.runeSlots = {
        [ENCHANTING_RUNE_POTENCY] = ZO_SharedEnchantRuneSlot:New(self,
            self.runeSlotContainer:GetNamedChild("PotencyRune"),
            "EsoUI/Art/Crafting/crafting_runestone03_slot.dds",
            "EsoUI/Art/Crafting/crafting_runestone03_drag.dds",
            "EsoUI/Art/Crafting/crafting_runestone03_negative.dds",
            SOUNDS.ENCHANTING_POTENCY_RUNE_PLACED,
            SOUNDS.ENCHANTING_POTENCY_RUNE_REMOVED,
            ENCHANTING_RUNE_POTENCY,
            self.inventory
        ),

        [ENCHANTING_RUNE_ESSENCE] = ZO_SharedEnchantRuneSlot:New(self,
            self.runeSlotContainer:GetNamedChild("EssenceRune"),
            "EsoUI/Art/Crafting/crafting_runestone02_slot.dds",
            "EsoUI/Art/Crafting/crafting_runestone02_drag.dds",
            "EsoUI/Art/Crafting/crafting_runestone02_negative.dds",
            SOUNDS.ENCHANTING_ESSENCE_RUNE_PLACED,
            SOUNDS.ENCHANTING_ESSENCE_RUNE_REMOVED,
            ENCHANTING_RUNE_ESSENCE,
            self.inventory
        ),
        [ENCHANTING_RUNE_ASPECT] = ZO_SharedEnchantRuneSlot:New(self,
            self.runeSlotContainer:GetNamedChild("AspectRune"),
            "EsoUI/Art/Crafting/crafting_runestone01_slot.dds",
            "EsoUI/Art/Crafting/crafting_runestone01_drag.dds",
            "EsoUI/Art/Crafting/crafting_runestone01_negative.dds",
            SOUNDS.ENCHANTING_ASPECT_RUNE_PLACED,
            SOUNDS.ENCHANTING_ASPECT_RUNE_REMOVED,
            ENCHANTING_RUNE_ASPECT,
            self.inventory
         ),
    }

    self.control:RegisterForEvent(EVENT_NON_COMBAT_BONUS_CHANGED, function(eventCode, nonCombatBonusType)
        if nonCombatBonusType == NON_COMBAT_BONUS_ENCHANTING_LEVEL or nonCombatBonusType == NON_COMBAT_BONUS_ENCHANTING_RARITY_LEVEL then
            self.inventory:HandleDirtyEvent()
        elseif nonCombatBonusType == NON_COMBAT_BONUS_ENCHANTING_CRAFT_PERCENT_DISCOUNT then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end)
    
    self.resultTooltip = self.control:GetNamedChild("Tooltip")
    if IsChatSystemAvailableForCurrentPlatform() then
        local function OnTooltipMouseUp(control, button, upInside)
            if upInside and button == MOUSE_BUTTON_INDEX_RIGHT then
                local link = ZO_LinkHandler_CreateChatLink(GetEnchantingResultingItemLink, self:GetAllCraftingBagAndSlots())
                if link ~= "" then
                    ClearMenu()

                    local function AddLink()
                        ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, link))
                    end

                    AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), AddLink)
                    
                    ShowMenu(self)
                end
            end
        end

        self.resultTooltip:SetHandler("OnMouseUp", OnTooltipMouseUp)
        self.resultTooltip:GetNamedChild("Icon"):SetHandler("OnMouseUp", OnTooltipMouseUp)
    end

    self.creationSlotAnimation = ZO_SharedEnchantingSlotAnimation:New(self.slotCreationAnimationName, function() return self.enchantingMode == ENCHANTING_MODE_CREATION end)
    self.creationSlotAnimation:AddSlot(self.runeSlots[ENCHANTING_RUNE_POTENCY])
    self.creationSlotAnimation:AddSlot(self.runeSlots[ENCHANTING_RUNE_ESSENCE])
    self.creationSlotAnimation:AddSlot(self.runeSlots[ENCHANTING_RUNE_ASPECT])
end

function ZO_SharedEnchanting:InitializeExtractionSlots()
    self.extractionSlotContainer = self.control:GetNamedChild("ExtractionSlotContainer")

    self.extractionSlot = ZO_SharedEnchantExtractionSlot:New(self, self.extractionSlotContainer:GetNamedChild("ExtractionSlot"), self.inventory)

    -- TODO: replace with extraction assets when they're made
    self.extractionSlotAnimation = ZO_CraftingEnchantExtractSlotAnimation:New("enchanting", function() return self.enchantingMode == ENCHANTING_MODE_EXTRACTION end)
    self.extractionSlotAnimation:AddSlot(self.extractionSlot)
end

function ZO_SharedEnchanting:InitializeKeybindStripDescriptors()
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
        self.extractionSlot:SetItem(nil)
        self.extractionSlot.dropCallout:SetTexture("EsoUI/Art/Crafting/crafting_enchanting_glyphSlot_empty.dds")
    end
    self:OnSlotChanged()
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
        return self.extractionSlot:HasItem()
    end
end

function ZO_SharedEnchanting:IsCurrentSelected()
    if self.enchantingMode == ENCHANTING_MODE_CREATION then
        for i, slot in ipairs(self.runeSlots) do
            if slot:HasItem() then
                local bagId, slotIndex = slot:GetBagAndSlot()
                local selectedBagId, selectedSlotIndex = self.inventory:CurrentSelectionBagAndSlot()
                if bagId == selectedBagId and slotIndex == selectedSlotIndex then
                    return true
                end
            end
        end
        return false
    elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
        if self.extractionSlot:HasItem() then
            local bagId, slotIndex = self.extractionSlot:GetBagAndSlot()
            local selectedBagId, selectedSlotIndex = self.inventory:CurrentSelectionBagAndSlot()
            return bagId == selectedBagId and slotIndex == selectedSlotIndex
        end
    end
end

function ZO_SharedEnchanting:IsCraftable()
    if self.enchantingMode == ENCHANTING_MODE_CREATION then
        for i, slot in ipairs(self.runeSlots) do
            if not slot:HasItem() then
                return false
            end
        end
        return true
    elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
        return self.extractionSlot:HasItem()
    end
end

function ZO_SharedEnchanting:Create()
    if self.enchantingMode == ENCHANTING_MODE_CREATION then
        local rune1BagId, rune1SlotIndex, rune2BagId, rune2SlotIndex, rune3BagId, rune3SlotIndex = self:GetAllCraftingBagAndSlots()
        self.potencySound, self.potencyLength = GetRunestoneSoundInfo(rune1BagId, rune1SlotIndex)
        self.essenceSound, self.essenceLength = GetRunestoneSoundInfo(rune2BagId, rune2SlotIndex)
        self.aspectSound, self.aspectLength = GetRunestoneSoundInfo(rune3BagId, rune3SlotIndex)

        CraftEnchantingItem(rune1BagId, rune1SlotIndex, rune2BagId, rune2SlotIndex, rune3BagId, rune3SlotIndex)
    elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
        ExtractEnchantingItem(self.extractionSlot:GetBagAndSlot())
        self.extractionSlot:ClearDropCalloutTexture()
    end
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
    self.inventory:HandleVisibleDirtyEvent()
end

function ZO_SharedEnchanting:UpdateTooltip()
    if self.enchantingMode == ENCHANTING_MODE_CREATION and self:IsCraftable() then
        self.resultTooltip:SetHidden(false)

        self.resultTooltip:ClearLines()
        self.resultTooltip:SetPendingEnchantingItem(self:GetAllCraftingBagAndSlots())
    elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION and self:IsCraftable() then
        self.resultTooltip:SetHidden(false)

        self.resultTooltip:ClearLines()
        self.resultTooltip:SetBagItem(self.extractionSlot:GetBagAndSlot())
    else
        self.resultTooltip:SetHidden(true)
    end
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
    if usedInCraftingType == CRAFTING_TYPE_ENCHANTING then
        if self.enchantingMode == ENCHANTING_MODE_CREATION then
            local itemId = GetItemInstanceId(bagId, slotIndex)
            local slot = self.runeSlots[runeType]
            if slot:IsItemId(itemId) then
                return true
            end
        elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
            local itemId = GetItemInstanceId(bagId, slotIndex)
            if self.extractionSlot:IsItemId(itemId) then
                return true
            end
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
end

function ZO_SharedEnchanting:AddItemToCraft(bagId, slotIndex)
    if not IsPerformingCraftProcess() then
        local usedInCraftingType, _, runeType, rankRequirement, rarityRequirement = GetItemCraftingInfo(bagId, slotIndex)
        if usedInCraftingType == CRAFTING_TYPE_ENCHANTING then
            if self.enchantingMode == ENCHANTING_MODE_CREATION then
                if DoesRunePassRequirements(runeType, rankRequirement, rarityRequirement) then
                    self:SetRuneSlotItem(runeType, bagId, slotIndex)
                end
            elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
                self:SetExtractionSlotItem(bagId, slotIndex)
            end
        end
    end
end

function ZO_SharedEnchanting:RemoveItemFromCraft(bagId, slotIndex)
    if not IsPerformingCraftProcess() then
        local usedInCraftingType, _, runeType, rankRequirement, rarityRequirement = GetItemCraftingInfo(bagId, slotIndex)
        if usedInCraftingType == CRAFTING_TYPE_ENCHANTING then
            if self.enchantingMode == ENCHANTING_MODE_CREATION then
                self:SetRuneSlotItem(runeType, nil)
            elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
                self:SetExtractionSlotItem(nil)
            end
        end
    end
end

function ZO_SharedEnchanting:SetRuneSlotItem(runeType, bagId, slotIndex)
    self.runeSlots[runeType]:SetItem(bagId, slotIndex)

    self:OnSlotChanged()
end

function ZO_SharedEnchanting:SetExtractionSlotItem(bagId, slotIndex)
    self.extractionSlot:SetItem(bagId, slotIndex)

    self:OnSlotChanged()
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
    local changed = false
    for i, slot in ipairs(self.runeSlots) do
        if not slot:ValidateItemId(validItemIds) then
            changed = true
        end
    end
    if not self.extractionSlot:ValidateItemId(validItemIds) then
        changed = true
    end
    if changed then
        self:OnSlotChanged()
    else
        self:UpdateTooltip()
    end
end

function ZO_SharedEnchanting:IsSlotted(bagId, slotIndex)
    if self.enchantingMode == ENCHANTING_MODE_CREATION then
        for i, slot in ipairs(self.runeSlots) do
            if slot:IsBagAndSlot(bagId, slotIndex) then
                return true
            end
        end
    elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
        return self.extractionSlot:IsBagAndSlot(bagId, slotIndex)
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

ZO_SharedEnchantExtractionSlot = ZO_CraftingSlotBase:Subclass()

function ZO_SharedEnchantExtractionSlot:New(...)
    return ZO_CraftingSlotBase.New(self, ...)
end

function ZO_SharedEnchantExtractionSlot:Initialize(owner, control, craftingInventory)
    ZO_CraftingSlotBase.Initialize(self, owner, control, SLOT_TYPE_PENDING_CRAFTING_COMPONENT, "", craftingInventory)

    self.dropCallout:SetDimensions(128, 128)
    self.dropCallout:SetHidden(false)
    self:ClearDropCalloutTexture()
end

function ZO_SharedEnchantExtractionSlot:ClearDropCalloutTexture()
    self.dropCallout:SetTexture("EsoUI/Art/Crafting/crafting_enchanting_glyphSlot_empty.dds")
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

function ZO_SharedEnchantExtractionSlot:SetItem(bagId, slotIndex)
    local oldItemInstanceId = self:GetItemId()

    ZO_CraftingSlotBase.SetItem(self, bagId, slotIndex)

    local usedInCraftingType, craftingSubItemType, runeType = GetItemCraftingInfo(self.bagId, self.slotIndex)
    local placeSound, removeSound = GetSoundsForGlyphType(craftingSubItemType)

    if self:HasItem() then
        self.dropCallout:SetHidden(true)
        if oldItemInstanceId ~= self:GetItemId() then
            PlaySound(placeSound)
        end
        self.pendingRemoveSound = removeSound
    else
        self.dropCallout:SetHidden(false)
        if self.pendingRemoveSound then
            PlaySound(self.pendingRemoveSound)
            self.pendingRemoveSound = nil
        end
    end

    if self.nameLabel then
        if bagId and slotIndex then
            self.nameLabel:SetHidden(false)
            self.nameLabel:SetText(zo_strformat(ZO_GetSpecializedItemTypeTextBySlot(bagId, slotIndex)))
        else
            self.nameLabel:SetHidden(true)
        end
    end
end

function ZO_SharedEnchantExtractionSlot:ShowDropCallout()
    -- no drop callout behavior
end

function ZO_SharedEnchantExtractionSlot:HideDropCallout()
    -- no drop callout behavior
end

function ZO_SharedEnchantExtractionSlot:SetBackdrop(bagId, slotIndex)
    local usedInCraftingType, craftingSubItemType, runeType = GetItemCraftingInfo(bagId, slotIndex)

    if craftingSubItemType == ITEMTYPE_GLYPH_WEAPON then
        self.dropCallout:SetTexture("EsoUI/Art/Crafting/crafting_enchanting_glyphSlot_pentagon.dds")
    elseif craftingSubItemType == ITEMTYPE_GLYPH_ARMOR then
        self.dropCallout:SetTexture("EsoUI/Art/Crafting/crafting_enchanting_glyphSlot_shield.dds")
    elseif craftingSubItemType == ITEMTYPE_GLYPH_JEWELRY then
        self.dropCallout:SetTexture("EsoUI/Art/Crafting/crafting_enchanting_glyphSlot_round.dds")
    end
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

