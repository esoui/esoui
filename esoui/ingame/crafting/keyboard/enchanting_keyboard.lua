ZO_Enchanting = ZO_SharedEnchanting:Subclass()

function ZO_Enchanting:New(...)
    return ZO_SharedEnchanting.New(self, ...)
end

function ZO_Enchanting:Initialize(control)
    self.slotCreationAnimationName = "enchanting"
    self.mainSceneName = "enchanting"

    ZO_SharedEnchanting.Initialize(self, control)
end

function ZO_Enchanting:InitializeInventory()
    self.inventoryControl = self.control:GetNamedChild("Inventory")
    self.inventory = ZO_EnchantingInventory:New(self, self.inventoryControl)
end

function ZO_Enchanting:InitializeEnchantingScenes()
    ZO_SharedEnchanting.InitializeEnchantingScenes(self)

    local ENCHANTING_STATION_INTERACTION =
    {
        type = "Enchanting Station",
        End = function()
            SCENE_MANAGER:Hide(self.mainSceneName)
        end,
        interactTypes = { INTERACTION_CRAFT },
    }

    ENCHANTING_SCENE = ZO_InteractScene:New(self.mainSceneName, SCENE_MANAGER, ENCHANTING_STATION_INTERACTION)
    ENCHANTING_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:OnModeUpdated()
        elseif newState == SCENE_HIDDEN then
            ZO_InventorySlot_RemoveMouseOverKeybinds()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)

            self.inventory:HandleDirtyEvent()

            CRAFTING_RESULTS:SetCraftingTooltip(nil)
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
            callback = function(tabData)
                self.modeBarLabel:SetText(GetString(name))
                self.enchantingMode = mode
                self:OnModeUpdated()
            end,
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

    ZO_MenuBar_SelectDescriptor(self.modeBar, ENCHANTING_MODE_CREATION)
    ZO_CraftingUtils_ConnectMenuBarToCraftingProcess(self.modeBar)
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
    for _, slot in pairs(self.runeSlots) do
        slot:RegisterCallback("ItemsChanged", function()
            self:OnSlotChanged()
        end)
    end

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

    self.multiCraftSpinner = ZO_MultiCraftSpinner:New(self.runeSlotContainer:GetNamedChild("Spinner"))
    ZO_CraftingUtils_ConnectSpinnerToCraftingProcess(self.multiCraftSpinner)
end

function ZO_Enchanting:InitializeExtractionSlots()
    self.extractionSlotContainer = self.control:GetNamedChild("ExtractionSlotContainer")

    local MULTIPLE_ITEMS_TEXTURE = "EsoUI/Art/Crafting/smithing_multiple_enchantingSlot.dds"
    self.extractionSlot = ZO_EnchantExtractionSlot_Keyboard:New(self, self.extractionSlotContainer:GetNamedChild("ExtractionSlot"), MULTIPLE_ITEMS_TEXTURE, self.inventory)
    self.extractionSlot:RegisterCallback("ItemsChanged", function()
        self:OnSlotChanged()
    end)

    self.extractionSlotAnimation = ZO_CraftingEnchantExtractSlotAnimation:New(self.slotCreationAnimationName, function() return self.enchantingMode == ENCHANTING_MODE_EXTRACTION end)
    self.extractionSlotAnimation:AddSlot(self.extractionSlot)
end

function ZO_Enchanting:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Create/Deconstruct
        {
            name = function()
                if self.enchantingMode == ENCHANTING_MODE_CREATION then
                    local cost = GetCostToCraftEnchantingItem(self:GetAllCraftingBagAndSlots())
                    return ZO_CraftingUtils_GetCostToCraftString(cost)
                elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
                    if self.extractionSlot:HasMultipleItems() then
                        return GetString(SI_CRAFTING_EXTRACT_MULTIPLE)
                    else
                        return GetString(SI_CRAFTING_PERFORM_EXTRACTION)
                    end
                end
            end,
            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                if self.enchantingMode == ENCHANTING_MODE_CREATION then
                    ZO_KeyboardCraftingUtils_RequestCraftingCreate(self, self:GetMultiCraftNumIterations())
                elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
                    if self.extractionSlot:HasOneItem() then
                        self:ExtractSingle()
                    else
                        self:ConfirmExtractAll()
                    end
                end
            end,

            enabled = function()
                if self.enchantingMode == ENCHANTING_MODE_CREATION then
                    return self:ShouldCraftButtonBeEnabled()
                elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
                    return self:ShouldDeconstructButtonBeEnabled()
                end
                return false
            end,
        },

        -- Deconstruct single stack
        {
            name = GetString(SI_ENCHANTING_EXTRACT_FULL_STACK),
            keybind = "UI_SHORTCUT_QUATERNARY",

            callback = function()
                self:ConfirmExtractAll()
            end,

            visible = function() 
                return self:IsExtractable() and self.extractionSlot:HasOneItem() and self.extractionSlot:GetStackCount() > 1
            end,

            enabled = function()
                if self.enchantingMode == ENCHANTING_MODE_CREATION then
                    return self:ShouldCraftButtonBeEnabled()
                elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
                    return self:ShouldDeconstructButtonBeEnabled()
                end
                return false
            end,
        },

        -- Clear selections
        {
            name = GetString(SI_CRAFTING_CLEAR_SELECTIONS),
            keybind = "UI_SHORTCUT_NEGATIVE",

            callback = function() self:ClearSelections() end,

            visible = function() return not ZO_CraftingUtils_IsPerformingCraftProcess() and self:HasSelections() end,
        },
    }

    ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(self.keybindStripDescriptor)
end

function ZO_Enchanting:ResetSelectedTab()
    ZO_MenuBar_SelectDescriptor(self.modeBar, ENCHANTING_MODE_CREATION)
    self:ClearSelections()
end

function ZO_Enchanting:CanShowScene()
    return not IsInGamepadPreferredMode()
end

function ZO_Enchanting:OnModeUpdated()
    if self:IsSceneShowing() then
        local enchantingMode = self.enchantingMode
        self.runeSlotContainer:SetHidden(enchantingMode ~= ENCHANTING_MODE_CREATION)
        self.extractionSlotContainer:SetHidden(enchantingMode ~= ENCHANTING_MODE_EXTRACTION)

        if enchantingMode == ENCHANTING_MODE_EXTRACTION then
            self:ClearSelections()
        end

        if enchantingMode == ENCHANTING_MODE_RECIPES then
            --Make sure we hide the tooltip when going to the Provisioner Scene.
            self.resultTooltip:SetHidden(true)

            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            PROVISIONER:EmbedInCraftingScene()
            self.inventoryControl:SetHidden(true)
        else
            PROVISIONER:RemoveFromCraftingScene()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            self.inventoryControl:SetHidden(false)
            self.inventory:ChangeMode(enchantingMode)
            ClearCursor()
            self:OnSlotChanged()
            self:ResetMultiCraftNumIterations()
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
    if self:IsCraftable() then
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
                    self:AddItemToCraft(bagId, slotIndex)
                end
            end
        elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
            self:AddItemToCraft(bagId, slotIndex)
        end
    end
end

function ZO_Enchanting:UpdateMultiCraft()
    if self.enchantingMode == ENCHANTING_MODE_CREATION then
        self.multiCraftSpinner:SetMinMax(1, self:GetMultiCraftMaxIterations())
        self.multiCraftSpinner:UpdateButtons()
    end
end

function ZO_Enchanting:GetMultiCraftNumIterations()
    return self.multiCraftSpinner:GetValue()
end

function ZO_Enchanting:ResetMultiCraftNumIterations()
    return self.multiCraftSpinner:SetValue(1)
end

ZO_EnchantingInventory = ZO_CraftingInventory:Subclass()

function ZO_EnchantingInventory:New(...)
    return ZO_CraftingInventory.New(self, ...)
end

function ZO_EnchantingInventory:Initialize(owner, control, ...)
    local inventory = ZO_CraftingInventory.Initialize(self, control, ...)
    self.owner = owner
    self.filterType = NO_FILTER

    local SET_HIDDEN = true
    self:SetSortColumnHidden({ statusSortOrder = true, traitInformationSortOrder = true, sellInformationSortOrder = true, }, SET_HIDDEN)
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
        self:SetNoItemLabelText(GetString(SI_ENCHANTING_NO_GLYPHS))
    else
        self.filterType = filterData.descriptor

        if self.filterType == ENCHANTING_RUNE_ASPECT then
            self:SetNoItemLabelText(GetString(SI_ENCHANTING_NO_ASPECT_RUNES))
        elseif self.filterType == ENCHANTING_RUNE_ESSENCE then
            self:SetNoItemLabelText(GetString(SI_ENCHANTING_NO_ESSENCE_RUNES))
        elseif self.filterType == ENCHANTING_RUNE_POTENCY then
            self:SetNoItemLabelText(GetString(SI_ENCHANTING_NO_POTENCY_RUNES))
        else
            self:SetNoItemLabelText(GetString(SI_ENCHANTING_NO_RUNES))
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
    local enchantingMode = self.owner:GetEnchantingMode()
    if enchantingMode == ENCHANTING_MODE_CREATION then
        filterType = self.filterType
    elseif enchantingMode == ENCHANTING_MODE_EXTRACTION then
        filterType = EXTRACTION_FILTER
    end
    local validItemIds = self:EnumerateInventorySlotsAndAddToScrollData(IsEnchantingItem, DoesEnchantingItemPassFilter, filterType, data)
    self.owner:OnInventoryUpdate(validItemIds)

    self:SetNoItemLabelHidden(#data > 0)
end

function ZO_EnchantingInventory:ShowAppropriateSlotDropCallouts(bagId, slotIndex)
    local _, craftingSubItemType, runeType, rankRequirement, rarityRequirement = GetItemCraftingInfo(bagId, slotIndex)
    self.owner:ShowAppropriateSlotDropCallouts(craftingSubItemType, runeType, rankRequirement, rarityRequirement)
end

function ZO_EnchantingInventory:HideAllSlotDropCallouts()
    self.owner:HideAllSlotDropCallouts()
end

ZO_EnchantExtractionSlot_Keyboard = ZO_SharedEnchantExtractionSlot:Subclass()

function ZO_EnchantExtractionSlot_Keyboard:New(...)
    return ZO_SharedEnchantExtractionSlot.New(self, ...)
end

function ZO_EnchantExtractionSlot_Keyboard:ClearDropCalloutTexture()
    self.dropCallout:SetTexture("EsoUI/Art/Crafting/crafting_enchanting_glyphSlot_empty.dds")
end

function ZO_EnchantExtractionSlot_Keyboard:SetBackdrop(bagId, slotIndex)
    local usedInCraftingType, craftingSubItemType, runeType = GetItemCraftingInfo(bagId, slotIndex)

    if craftingSubItemType == ITEMTYPE_GLYPH_WEAPON then
        self.dropCallout:SetTexture("EsoUI/Art/Crafting/crafting_enchanting_glyphSlot_pentagon.dds")
    elseif craftingSubItemType == ITEMTYPE_GLYPH_ARMOR then
        self.dropCallout:SetTexture("EsoUI/Art/Crafting/crafting_enchanting_glyphSlot_shield.dds")
    elseif craftingSubItemType == ITEMTYPE_GLYPH_JEWELRY then
        self.dropCallout:SetTexture("EsoUI/Art/Crafting/crafting_enchanting_glyphSlot_round.dds")
    end
end

function ZO_Enchanting_Initialize(control)
    ENCHANTING = ZO_Enchanting:New(control)
end
