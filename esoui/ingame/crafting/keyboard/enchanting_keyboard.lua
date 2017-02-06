ZO_Enchanting = ZO_SharedEnchanting:Subclass()

function ZO_Enchanting:New(...)
    return ZO_SharedEnchanting.New(self, ...)
end

function ZO_Enchanting:Initialize(control)
    self.slotCreationAnimationName = "enchanting"

    ZO_SharedEnchanting.Initialize(self, control)
end

function ZO_Enchanting:InitializeInventory()
    self.inventoryControl = self.control:GetNamedChild("Inventory")
    self.inventory = ZO_EnchantingInventory:New(self, self.inventoryControl)
end

function ZO_Enchanting:InitializeEnchantingScenes()
    local ENCHANTING_STATION_INTERACTION =
    {
        type = "Enchanting Station",
        End = function()
            SCENE_MANAGER:Hide("enchanting")
        end,
        interactTypes = { INTERACTION_CRAFT },
    }

    ENCHANTING_SCENE = ZO_InteractScene:New("enchanting", SCENE_MANAGER, ENCHANTING_STATION_INTERACTION)
    ENCHANTING_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

            if self.enchantingMode then
                local oldEnchantMode = self.enchantingMode
                self.enchantingMode = nil
                self:SetEnchantingMode(oldEnchantMode)
            else
                ZO_MenuBar_SelectDescriptor(self.modeBar, ENCHANTING_MODE_CREATION)
            end
        elseif newState == SCENE_HIDDEN then
            ZO_InventorySlot_RemoveMouseOverKeybinds()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)

            self.inventory:HandleDirtyEvent()

            CRAFTING_RESULTS:SetCraftingTooltip(nil)
        end
    end)

    self.control:RegisterForEvent(EVENT_CRAFTING_STATION_INTERACT, function(eventCode, craftingType)
        if craftingType == CRAFTING_TYPE_ENCHANTING and not IsInGamepadPreferredMode() then
            SCENE_MANAGER:Show("enchanting")
        end
    end)

    self.control:RegisterForEvent(EVENT_END_CRAFTING_STATION_INTERACT, function(eventCode, craftingType)
        if craftingType == CRAFTING_TYPE_ENCHANTING then
            SCENE_MANAGER:ShowBaseScene()
        end
    end)
end


function ZO_Enchanting:InitializeModes()
    local function CreateButtonData(name, mode, normal, pressed, highlight, disabled)
        return {
            activeTabText = name,
            categoryName = name,

            descriptor = mode,
            normal = normal,
            pressed = pressed,
            highlight = highlight,
            disabled = disabled,
            callback = function(tabData) self.modeBarLabel:SetText(GetString(name)) self:SetEnchantingMode(mode) end,
        }
    end

    self.modeBar = self.control:GetNamedChild("ModeMenuBar")
    self.modeBarLabel = self.modeBar:GetNamedChild("Label")

    local creationTab = CreateButtonData(
        SI_ENCHANTING_CREATION, 
        ENCHANTING_MODE_CREATION, 
        "EsoUI/Art/Crafting/smithing_tabIcon_creation_up.dds", 
        "EsoUI/Art/Crafting/smithing_tabIcon_creation_down.dds", 
        "EsoUI/Art/Crafting/smithing_tabIcon_creation_over.dds",
        "EsoUI/Art/Crafting/smithing_tabIcon_creation_disabled.dds"
    )
    ZO_MenuBar_AddButton(self.modeBar, creationTab)

    local extractionTab = CreateButtonData(
        SI_ENCHANTING_EXTRACTION, 
        ENCHANTING_MODE_EXTRACTION, 
        "EsoUI/Art/Crafting/enchantment_tabIcon_deconstruction_up.dds", 
        "EsoUI/Art/Crafting/enchantment_tabIcon_deconstruction_down.dds", 
        "EsoUI/Art/Crafting/enchantment_tabIcon_deconstruction_over.dds",
        "EsoUI/Art/Crafting/enchantment_tabIcon_deconstruction_disabled.dds"
    )
    ZO_MenuBar_AddButton(self.modeBar, extractionTab)

    local recipeCraftingSystem = GetTradeskillRecipeCraftingSystem(CRAFTING_TYPE_ENCHANTING)
    local recipeCraftingSystemNameStringId = _G["SI_RECIPECRAFTINGSYSTEM"..recipeCraftingSystem]
    local recipeTab = CreateButtonData(
        recipeCraftingSystemNameStringId,
        ENCHANTING_MODE_RECIPES,
        GetKeyboardRecipeCraftingSystemButtonTextures(recipeCraftingSystem))
    ZO_MenuBar_AddButton(self.modeBar, recipeTab)

    ZO_CraftingUtils_ConnectMenuBarToCraftingProcess(self.modeBar)
end

function ZO_Enchanting:InitializeExtractionSlots()
    self.extractionSlotContainer = self.control:GetNamedChild("ExtractionSlotContainer")

    self.extractionSlot = ZO_SharedEnchantExtractionSlot:New(self, self.extractionSlotContainer:GetNamedChild("ExtractionSlot"), self.inventory)

    -- TODO: replace with extraction assets when they're made
    self.extractionSlotAnimation = ZO_CraftingEnchantExtractSlotAnimation:New("enchanting", function() return self.enchantingMode == ENCHANTING_MODE_EXTRACTION end)
    self.extractionSlotAnimation:AddSlot(self.extractionSlot)
end

function ZO_Enchanting:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Clear selections
        {
            name = GetString(SI_CRAFTING_CLEAR_SELECTIONS),
            keybind = "UI_SHORTCUT_NEGATIVE",
        
            callback = function() self:ClearSelections() end,

            visible = function() return not ZO_CraftingUtils_IsPerformingCraftProcess() and self:HasSelections() end,
        },

        -- Perform craft
        {
            name = function()
                if self.enchantingMode == ENCHANTING_MODE_CREATION then
                    local cost = GetCostToCraftEnchantingItem(self:GetAllCraftingBagAndSlots())
                    return ZO_CraftingUtils_GetCostToCraftString(cost)
                elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
                    return GetString(SI_CRAFTING_PERFORM_EXTRACTION)
                end
            end,
            keybind = "UI_SHORTCUT_SECONDARY",
        
            callback = function() self:Create() end,

            visible = function() return not ZO_CraftingUtils_IsPerformingCraftProcess() and self:IsCraftable() end,
        },
    }

    ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(self.keybindStripDescriptor)
end

function ZO_Enchanting:SetEnchantingMode(enchantingMode)
    if self.enchantingMode ~= enchantingMode then
        local oldEnchantingMode = self.enchantingMode
        self.enchantingMode = enchantingMode

        self.runeSlotContainer:SetHidden(enchantingMode ~= ENCHANTING_MODE_CREATION)
        self.extractionSlotContainer:SetHidden(enchantingMode ~= ENCHANTING_MODE_EXTRACTION)

        if enchantingMode == ENCHANTING_MODE_RECIPES then
            --Make sure we hide the tooltip when going to the Provisioner Scene.
            self.resultTooltip:SetHidden(true)

            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            PROVISIONER:EmbedInCraftingScene()
            self.inventoryControl:SetHidden(true)
        else
            if oldEnchantingMode == ENCHANTING_MODE_RECIPES then
                PROVISIONER:RemoveFromCraftingScene()
                KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            end
            self.inventoryControl:SetHidden(false)
            self.inventory:ChangeMode(enchantingMode)
            ClearCursor()
            self:OnSlotChanged()
        end

        -- This block of code must be done second so the tooltip animation and sounds are reset correctly
        -- when switching back from the provisioning scene
        if enchantingMode == ENCHANTING_MODE_CREATION then
            CRAFTING_RESULTS:SetCraftingTooltip(self.resultTooltip)
            CRAFTING_RESULTS:SetTooltipAnimationSounds(SOUNDS.ENCHANTING_CREATE_TOOLTIP_GLOW)
            TriggerTutorial(TUTORIAL_TRIGGER_ENCHANTING_CREATION_OPENED)
        elseif enchantingMode == ENCHANTING_MODE_EXTRACTION then
            CRAFTING_RESULTS:SetCraftingTooltip(nil)
            CRAFTING_RESULTS:SetTooltipAnimationSounds(nil)
            TriggerTutorial(TUTORIAL_TRIGGER_ENCHANTING_EXTRACTION_OPENED)
        end
    end
end

function ZO_Enchanting:UpdateTooltip()
    if self.enchantingMode == ENCHANTING_MODE_CREATION and self:IsCraftable() then
        self.resultTooltip:SetHidden(false)

        self.resultTooltip:ClearLines()
        self.resultTooltip:SetPendingEnchantingItem(self:GetAllCraftingBagAndSlots())
    else
        self.resultTooltip:SetHidden(true)
    end
end

function ZO_Enchanting:OnItemReceiveDrag(slotControl, bagId, slotIndex)
    local usedInCraftingType, _, runeType, rankRequirement, rarityRequirement = GetItemCraftingInfo(bagId, slotIndex)
    if usedInCraftingType == CRAFTING_TYPE_ENCHANTING then
        if self.enchantingMode == ENCHANTING_MODE_CREATION then
            if DoesRunePassRequirements(runeType, rankRequirement, rarityRequirement) then
                local slot = self.runeSlots[runeType]
                if slot:IsSlotControl(slotControl) then
                    if slot:HasItem() then
                        PickupInventoryItem(slot:GetBagAndSlot())
                    end
                    self:SetRuneSlotItem(runeType, bagId, slotIndex)
                end
            end
        elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
            if self.extractionSlot:HasItem() then
                PickupInventoryItem(self.extractionSlot:GetBagAndSlot())
            end
            self:SetExtractionSlotItem(bagId, slotIndex)
        end
    end
end

ZO_EnchantingInventory = ZO_CraftingInventory:Subclass()

function ZO_EnchantingInventory:New(...)
    return ZO_CraftingInventory.New(self, ...)
end

function ZO_EnchantingInventory:Initialize(owner, control, ...)
    local inventory = ZO_CraftingInventory.Initialize(self, control, ...)
    self.owner = owner
    self.noRunesLabel = control:GetNamedChild("NoRunesLabel")
    self.filterType = NO_FILTER
end


function ZO_EnchantingInventory:ChangeMode(enchantingMode)
    if enchantingMode == ENCHANTING_MODE_CREATION then
        self:SetFilters{
            self:CreateNewTabFilterData(ENCHANTING_RUNE_ASPECT, GetString("SI_ENCHANTINGRUNECLASSIFICATION", ENCHANTING_RUNE_ASPECT), "EsoUI/Art/Crafting/enchantment_tabIcon_aspect_up.dds", "EsoUI/Art/Crafting/enchantment_tabIcon_aspect_down.dds", "EsoUI/Art/Crafting/enchantment_tabIcon_aspect_over.dds", "EsoUI/Art/Crafting/enchantment_tabIcon_aspect_disabled.dds"),
            self:CreateNewTabFilterData(ENCHANTING_RUNE_ESSENCE, GetString("SI_ENCHANTINGRUNECLASSIFICATION", ENCHANTING_RUNE_ESSENCE), "EsoUI/Art/Crafting/enchantment_tabIcon_essence_up.dds", "EsoUI/Art/Crafting/enchantment_tabIcon_essence_down.dds", "EsoUI/Art/Crafting/enchantment_tabIcon_essence_over.dds", "EsoUI/Art/Crafting/enchantment_tabIcon_essence_disabled.dds"),
            self:CreateNewTabFilterData(ENCHANTING_RUNE_POTENCY, GetString("SI_ENCHANTINGRUNECLASSIFICATION", ENCHANTING_RUNE_POTENCY), "EsoUI/Art/Crafting/enchantment_tabIcon_potency_up.dds", "EsoUI/Art/Crafting/enchantment_tabIcon_potency_down.dds", "EsoUI/Art/Crafting/enchantment_tabIcon_potency_over.dds", "EsoUI/Art/Crafting/enchantment_tabIcon_potency_disabled.dds"),
            self:CreateNewTabFilterData(NO_FILTER, GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_ALL), "EsoUI/Art/Inventory/inventory_tabIcon_all_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_all_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_all_over.dds", "EsoUI/Art/Inventory/inventory_tabIcon_all_disabled.dds"),
        }
        self:SetActiveFilterByDescriptor(self.filterType)
    elseif enchantingMode == ENCHANTING_MODE_EXTRACTION then
        self:SetFilters{
            self:CreateNewTabFilterData(NO_FILTER, GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_ALL), "EsoUI/Art/Inventory/inventory_tabIcon_all_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_all_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_all_over.dds", "EsoUI/Art/Inventory/inventory_tabIcon_all_disabled.dds"),
        }
        self:SetActiveFilterByDescriptor(NO_FILTER)
    end
end

function ZO_EnchantingInventory:ChangeFilter(filterData)
    ZO_CraftingInventory.ChangeFilter(self, filterData)

    if self.owner:GetEnchantingMode() == ENCHANTING_MODE_EXTRACTION then
        self.noRunesLabel:SetText(GetString(SI_ENCHANTING_NO_GLYPHS))
    else
        self.filterType = filterData.descriptor

        if self.filterType == ENCHANTING_RUNE_ASPECT then
            self.noRunesLabel:SetText(GetString(SI_ENCHANTING_NO_ASPECT_RUNES))
        elseif self.filterType == ENCHANTING_RUNE_ESSENCE then
            self.noRunesLabel:SetText(GetString(SI_ENCHANTING_NO_ESSENCE_RUNES))
        elseif self.filterType == ENCHANTING_RUNE_POTENCY then
            self.noRunesLabel:SetText(GetString(SI_ENCHANTING_NO_POTENCY_RUNES))
        else
            self.noRunesLabel:SetText(GetString(SI_ENCHANTING_NO_RUNES))
        end
    end

    self:HandleDirtyEvent()
end

function ZO_EnchantingInventory:IsLocked(bagId, slotIndex)
    return ZO_CraftingInventory.IsLocked(self, bagId, slotIndex) or self.owner:IsSlotted(bagId, slotIndex)
end

local function IsEnchantingItem(bagId, slotIndex)
    local usedInCraftingType, craftingSubItemType, runeType = GetItemCraftingInfo(bagId, slotIndex)

    if usedInCraftingType == CRAFTING_TYPE_ENCHANTING then
        if runeType == ENCHANTING_RUNE_ASPECT or runeType == ENCHANTING_RUNE_ESSENCE or runeType == ENCHANTING_RUNE_POTENCY then
            return true
        end
        if craftingSubItemType == ITEMTYPE_GLYPH_WEAPON or craftingSubItemType == ITEMTYPE_GLYPH_ARMOR or craftingSubItemType == ITEMTYPE_GLYPH_JEWELRY then
            return true
        end
    end

    return false
end

local function DoesEnchantingItemPassFilter(bagId, slotIndex, filterType)
    local usedInCraftingType, craftingSubItemType, runeType = GetItemCraftingInfo(bagId, slotIndex)

    if filterType == EXTRACTION_FILTER then
        return craftingSubItemType == ITEMTYPE_GLYPH_WEAPON or craftingSubItemType == ITEMTYPE_GLYPH_ARMOR or craftingSubItemType == ITEMTYPE_GLYPH_JEWELRY
    elseif filterType == NO_FILTER or filterType == runeType then
        return runeType == ENCHANTING_RUNE_ASPECT or runeType == ENCHANTING_RUNE_ESSENCE or runeType == ENCHANTING_RUNE_POTENCY
    end

    return false
end

function ZO_EnchantingInventory:Refresh(data)
    local filterType
    if self.owner:GetEnchantingMode() == ENCHANTING_MODE_CREATION then
        filterType = self.filterType
    else
        filterType = EXTRACTION_FILTER
    end
    local validItemIds = self:EnumerateInventorySlotsAndAddToScrollData(IsEnchantingItem, DoesEnchantingItemPassFilter, filterType, data)
    self.owner:OnInventoryUpdate(validItemIds)

    self.noRunesLabel:SetHidden(#data > 0)
end

function ZO_EnchantingInventory:ShowAppropriateSlotDropCallouts(bagId, slotIndex)
    local _, craftingSubItemType, runeType, rankRequirement, rarityRequirement = GetItemCraftingInfo(bagId, slotIndex)
    self.owner:ShowAppropriateSlotDropCallouts(craftingSubItemType, runeType, rankRequirement, rarityRequirement)
end

function ZO_EnchantingInventory:HideAllSlotDropCallouts()
    self.owner:HideAllSlotDropCallouts()
end


function ZO_Enchanting_Initialize(control)
    ENCHANTING = ZO_Enchanting:New(control)
end
